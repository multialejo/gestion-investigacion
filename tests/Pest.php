<?php

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Tests\TestCase;

/*
| RefreshDatabase solo afecta a la conexión por defecto de las pruebas
| (esquema `testing`, tablas de Laravel). El esquema del negocio
| (gestion_investigacion) se carga con ../db/recargar.sh y NO se borra:
| sus SP, triggers y roles son justamente lo que se prueba.
*/
pest()->extend(TestCase::class)
    ->use(RefreshDatabase::class)
    ->in('Feature');

/** Crea un usuario de la aplicación con un rol (y, si se indica, su persona en el negocio). */
function usuarioCon(string $rol, ?string $dbUsuario = null): User
{
    return User::factory()->create(['rol' => $rol, 'db_usuario' => $dbUsuario]);
}

/** Consulta el esquema del negocio con la cuenta de administración. */
function negocio(): \Illuminate\Database\Connection
{
    return DB::connection('rol_admin');
}

/** Datos válidos para registrar un proyecto de prueba (acrónimo único con prefijo PT). */
function datosProyecto(array $cambios = []): array
{
    $sufijo = Str::upper(Str::random(6));

    return array_merge([
        'nombre_proyecto' => "Proyecto de prueba {$sufijo}",
        'acronimo' => "PT{$sufijo}",
        'presupuesto' => 15000,
        'programa' => 'Fondo Concursable UEB 2026',
        'descripcion' => 'Creado por la suite automatizada.',
        'inicio_pro' => '2027-01-04',
        'fin_pro' => '2027-12-20',
        'resolucion' => 'RCU-PRUEBA-01',
        'id_investigador_principal' => idDoctorDisponible(),
    ], $cambios);
}

/** Un doctor con menos de 2 proyectos activos (regla de trg_validar_participacion). */
function idDoctorDisponible(): int
{
    return (int) negocio()->table('profesores')->where('tipo', 'doctor')
        ->whereRaw('fn_proyectos_activos(id_profesor) < 2')->value('id_profesor');
}

/** Registra un proyecto por la interfaz web como secretaría y devuelve su fila. */
function proyectoDePrueba(array $cambios = []): object
{
    $datos = datosProyecto($cambios);
    test()->actingAs(usuarioCon('secretaria', 'monica.cardenas'))->post('/proyectos', $datos);

    return negocio()->table('proyecto_investigacion')->where('acronimo', $datos['acronimo'])->first();
}

/** Borra los proyectos creados por las pruebas (ON DELETE CASCADE limpia el resto). */
function limpiarProyectosDePrueba(): void
{
    negocio()->table('proyecto_investigacion')->where('acronimo', 'like', 'PT%')->delete();
}
