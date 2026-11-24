<?php


afterEach(fn () => limpiarProyectosDePrueba());

function congreso(array $cambios = []): array
{
    return array_merge(['tipo' => 2, 'titulo' => 'Ponencia de prueba', 'nombre' => 'Congreso de Prueba', 'tipo_congreso' => 'Nacional',
        'fecha_inicio' => '2027-03-10', 'fecha_fin' => '2027-03-12', 'lugar' => 'Guaranda', 'pais' => 'Ecuador',
        'editorial' => 'Editorial UEB', 'participacion' => 'Ponencia'], $cambios);
}

it('trg_congreso_bi rechaza un congreso anterior al inicio del proyecto (SS15)', function () {
    $p = proyectoDePrueba();

    $this->post("/proyectos/{$p->id_proyecto}/productos", congreso(['fecha_inicio' => '2026-10-01', 'fecha_fin' => '2026-10-02']))
        ->assertSessionHasErrors(['bd' => 'Transaccion revertida: El congreso no puede iniciar antes que el proyecto de investigación (SS15).']);

    expect(negocio()->table('productos')->where('id_proyecto', $p->id_proyecto)->count())->toBe(0);
});

it('trg_resumen_producto_ins mantiene el total de productos', function () {
    $p = proyectoDePrueba();

    $this->post("/proyectos/{$p->id_proyecto}/productos", congreso())->assertSessionHasNoErrors();
    $this->post("/proyectos/{$p->id_proyecto}/productos", ['tipo' => 3, 'titulo' => 'Libro de prueba', 'nombre' => 'Libro de prueba',
        'editorial' => 'Editorial UEB', 'isbn' => '978-9942-11-111-1', 'fecha_publicacion' => '2027-06-01'])->assertSessionHasNoErrors();

    expect(negocio()->table('resumen_proyecto')->where('id_proyecto', $p->id_proyecto)->value('total_productos'))->toBe(2);
});

it('trg_validar_participacion rechaza periodos solapados (SS1)', function () {
    $p = proyectoDePrueba();
    $ip = $p->id_investigador_principal;

    $this->post("/proyectos/{$p->id_proyecto}/equipo", ['miembros' => [[
        'id_profesor' => $ip, 'cargo' => 'Investigador', 'fecha_inicio' => '2027-02-01', 'resolucion_ingreso' => 'RCU-T'],
    ]])->assertSessionHasErrors(['bd' => 'El periodo se solapa con otra participación del profesor en el proyecto (SS1).']);
});

it('trg_auditoria_proyecto_upd registra a la persona que cerró el proyecto', function () {
    $p = proyectoDePrueba();

    $this->actingAs(usuarioCon('admin', 'patricio.lara'))
        ->post("/proyectos/{$p->id_proyecto}/cierre", ['resolucion_cierre' => 'RCU-CIERRE-T'])
        ->assertSessionHasNoErrors();

    $fila = negocio()->table('auditoria_proyecto')->where('id_proyecto', $p->id_proyecto)->orderByDesc('id_auditoria')->first();
    expect($fila->datos_nuevos)->toContain('cierre=RCU-CIERRE-T')
        ->and($fila->usuario)->toStartWith('patricio.lara (app: svc_admin@');
});

it('trg_proyecto_bu impide cambiar el investigador principal', function () {
    $p = proyectoDePrueba();

    expect(fn () => negocio()->table('proyecto_investigacion')->where('id_proyecto', $p->id_proyecto)->update(['id_investigador_principal' => 3]))
        ->toThrow(\Illuminate\Database\QueryException::class, 'nunca varía');
});
