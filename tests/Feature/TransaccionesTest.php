<?php

use App\Database\Procedimientos\ControlProrroga;
use App\Facades\Procedimientos;
use App\Models\Participacion;
use Illuminate\Support\Facades\DB;

afterEach(fn () => limpiarProyectosDePrueba());

/** Profesor que desarrolla la línea indicada y aún puede entrar a un proyecto. */
function candidato(): object
{
    return negocio()->table('profesores')
        ->whereRaw('fn_proyectos_activos(id_profesor) < 2')
        ->whereExists(fn ($q) => $q->from('linea_profesor')->whereColumn('linea_profesor.id_profesor', 'profesores.id_profesor'))
        ->orderBy('id_profesor', 'desc')->first();
}

it('DB::transaction revierte todo el lote si un trigger rechaza una fila (SS10)', function () {
    $p = proyectoDePrueba();
    $miembro = candidato();

    $this->post("/proyectos/{$p->id_proyecto}/equipo", [
        'miembros' => [['id_profesor' => $miembro->id_profesor, 'cargo' => 'Investigador', 'fecha_inicio' => '2027-02-01', 'resolucion_ingreso' => 'RCU-T']],
        'lineas' => [7], // LI-07: no la desarrolla nadie del proyecto
    ])->assertSessionHasErrors(['bd' => 'Ningún profesor del proyecto desarrolla esa línea de investigación (SS10).']);

    // La participación era válida, pero el ROLLBACK la deshizo junto con la línea.
    expect(negocio()->table('proyecto_profesor')->where('id_proyecto', $p->id_proyecto)->count())->toBe(1);
    expect(negocio()->table('proyecto_linea')->where('id_proyecto', $p->id_proyecto)->count())->toBe(0);
});

it('DB::transaction confirma el lote completo cuando todas las filas son válidas', function () {
    $p = proyectoDePrueba();
    $miembro = candidato();
    $linea = negocio()->table('linea_profesor')->where('id_profesor', $miembro->id_profesor)->value('id_linea');

    $this->post("/proyectos/{$p->id_proyecto}/equipo", [
        'miembros' => [['id_profesor' => $miembro->id_profesor, 'cargo' => 'Investigador', 'fecha_inicio' => '2027-02-01', 'resolucion_ingreso' => 'RCU-T']],
        'lineas' => [$linea],
    ])->assertSessionHasNoErrors();

    expect(negocio()->table('proyecto_profesor')->where('id_proyecto', $p->id_proyecto)->count())->toBe(2);
    expect(negocio()->table('proyecto_linea')->where('id_proyecto', $p->id_proyecto)->count())->toBe(1);
});

it('el SP transaccional deshace sus propios INSERT cuando falla a mitad (ROLLBACK interno)', function () {
    $p = proyectoDePrueba();
    $productosAntes = negocio()->table('productos')->count();
    DB::setDefaultConnection('rol_secretaria');

    // Patente con un país de 81 caracteres: el SP inserta en productos y luego
    // falla en sp_aux_id_pais (parámetro VARCHAR(80) → 1406, SQLSTATE 22001).
    // Su EXIT HANDLER FOR SQLEXCEPTION hace ROLLBACK y registra FALLIDO.
    expect(fn () => Procedimientos::llamar('sp_registrar_producto_transaccional',
        [$p->id_proyecto, 4, 'Patente T', 'Patente T', null, 'REG-T', str_repeat('X', 81), 'SOL-T', null, '2027-05-05', null]))
        ->toThrow(\App\Exceptions\ReglaDeNegocioException::class, 'Transaccion revertida');

    expect(negocio()->table('productos')->count())->toBe($productosAntes);
    expect(negocio()->table('auditoria_operaciones')->orderByDesc('id_auditoria')->value('resultado'))->toStartWith('FALLIDO');
});

it('un SP transaccional dentro de DB::transaction confirma implícitamente la transacción exterior', function () {
    $p = proyectoDePrueba();
    $miembro = candidato();
    DB::setDefaultConnection('rol_admin');

    try {
        DB::transaction(function () use ($p, $miembro) {
            Participacion::create(['id_proyecto' => $p->id_proyecto, 'id_profesor' => $miembro->id_profesor,
                'fecha_inicio' => '2027-02-01', 'cargo' => 'Investigador', 'resolucion_ingreso' => 'RCU-T']);
            Procedimientos::ejecutar(new ControlProrroga($p->id_proyecto, '2030-01-01')); // falla (> 3 meses)
        });
    } catch (\App\Exceptions\ReglaDeNegocioException) {
    }

    // Documenta el hallazgo: la fila sobrevive al ROLLBACK de Laravel.
    expect(negocio()->table('proyecto_profesor')->where('id_proyecto', $p->id_proyecto)->count())->toBe(2);
});
