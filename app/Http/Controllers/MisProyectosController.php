<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * Profesor y estudiante solo tienen permiso sobre sus vistas personales; la
 * vista filtra por fn_usuario_app() (= @app_usuario fijado por el middleware).
 * El controlador no añade ningún WHERE: el filtrado lo hace la BD.
 */
class MisProyectosController extends Controller
{
    public function __invoke(Request $request)
    {
        $secciones = $request->user()->rol === 'profesor'
            ? ['Mis proyectos' => 'vw_docente_mis_proyectos', 'Mi equipo' => 'vw_docente_mi_equipo', 'Mis publicaciones' => 'vw_docente_mis_publicaciones']
            : ['Mis proyectos' => 'vw_estudiante_mis_proyectos'];

        $datos = collect($secciones)->map(fn ($vista) => ['vista' => $vista, 'filas' => DB::table($vista)->get()]);

        return view('mis-proyectos', ['secciones' => $datos]);
    }
}
