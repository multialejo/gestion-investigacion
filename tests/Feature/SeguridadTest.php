<?php

use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\DB;

describe('Primera capa: autenticación y autorización de Laravel', function () {
    it('envía a los invitados al login', function (string $ruta) {
        $this->get($ruta)->assertRedirect('/login');
    })->with(['/proyectos', '/proyectos/1', '/reportes', '/auditoria', '/mis-proyectos']);

    it('rechaza una contraseña incorrecta', function () {
        $u = usuarioCon('secretaria');
        $this->post('/login', ['email' => $u->email, 'password' => 'incorrecta'])->assertSessionHasErrors('email');
        $this->assertGuest();
    });

    it('bloquea el login tras 5 intentos fallidos (throttle)', function () {
        $u = usuarioCon('secretaria');
        foreach (range(1, 5) as $i) {
            $this->post('/login', ['email' => $u->email, 'password' => "mala{$i}"]);
        }
        $this->post('/login', ['email' => $u->email, 'password' => 'password'])
            ->assertSessionHasErrors('email'); // aun con la contraseña correcta
        $this->assertGuest();
    });

    it('no permite el registro público', function () {
        $this->get('/register')->assertNotFound();
    });

    it('aplica la matriz de acceso por rol', function (string $rol, array $permitidas, array $prohibidas) {
        $this->actingAs(usuarioCon($rol, $rol === 'profesor' ? 'carlos.villacres' : null));
        foreach ($permitidas as $ruta) {
            $this->get($ruta)->assertOk();
        }
        foreach ($prohibidas as $ruta) {
            $this->get($ruta)->assertForbidden();
        }
    })->with([
        'secretaría' => ['secretaria', ['/proyectos', '/proyectos/nuevo'], ['/reportes', '/auditoria', '/mis-proyectos']],
        'coordinador' => ['coordinador', ['/proyectos', '/reportes', '/reportes/cm2'], ['/proyectos/nuevo', '/auditoria']],
        'director' => ['director', ['/reportes', '/auditoria'], ['/proyectos/nuevo', '/mis-proyectos']],
        'profesor' => ['profesor', ['/mis-proyectos'], ['/proyectos', '/proyectos/nuevo', '/reportes', '/auditoria']],
    ]);

    it('no deja a un coordinador registrar proyectos aunque envíe el POST', function () {
        $this->actingAs(usuarioCon('coordinador'))->post('/proyectos', datosProyecto())->assertForbidden();
    });
});

describe('Segunda capa: permisos de MariaDB por cuenta de servicio', function () {
    it('cada conexión de rol entra con su cuenta y su rol', function (string $conexion, string $cuenta, string $rol) {
        $fila = DB::connection($conexion)->selectOne('SELECT CURRENT_USER() u, CURRENT_ROLE() r');
        expect($fila->u)->toBe($cuenta)->and($fila->r)->toBe($rol);
    })->with([
        ['rol_secretaria', 'svc_secretaria@%', 'rol_secretaria'],
        ['rol_profesor', 'svc_profesor@%', 'rol_profesor'],
        ['rol_director', 'svc_director@%', 'rol_director_inv'],
    ]);

    it('MariaDB niega al profesor leer o modificar tablas directamente', function () {
        expect(fn () => DB::connection('rol_profesor')->table('proyecto_investigacion')->count())
            ->toThrow(QueryException::class, 'SELECT command denied');
        expect(fn () => DB::connection('rol_profesor')->table('proyecto_investigacion')->where('id_proyecto', 1)->delete())
            ->toThrow(QueryException::class, 'DELETE command denied');
    });

    it('MariaDB niega a la secretaría modificar proyectos fuera de los procedimientos', function () {
        expect(fn () => DB::connection('rol_secretaria')->table('proyecto_investigacion')->where('id_proyecto', 1)->update(['presupuesto' => 1]))
            ->toThrow(QueryException::class, 'UPDATE command denied');
    });

    it('MariaDB niega al coordinador ejecutar procedimientos de escritura', function () {
        expect(fn () => DB::connection('rol_coordinador')->select('CALL sp_control_prorroga_transaccional(1, ?)', ['2027-02-01']))
            ->toThrow(QueryException::class, 'execute command denied');
    });

    it('la misma vista devuelve datos distintos según la persona (@app_usuario)', function () {
        $misProyectos = function (string $persona) {
            $this->actingAs(usuarioCon('profesor', $persona));

            return $this->get('/mis-proyectos')->assertOk()->viewData('secciones')['Mis proyectos']['filas']->pluck('acronimo')->all();
        };
        expect($misProyectos('carlos.villacres'))->toContain('PLATINV')->not->toContain('SATCLIMA');
        expect($misProyectos('maria.gavilanes'))->toContain('SATCLIMA')->not->toContain('PLATINV');
    });
});
