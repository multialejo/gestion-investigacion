<?php

namespace App\Http\Controllers;

use Illuminate\Support\Facades\DB;

/** Tablas que llenan los procedimientos y triggers; solo lectura (rol_director_inv). */
class AuditoriaController extends Controller
{
    public function __invoke()
    {
        return view('auditoria.index', [
            'operaciones' => DB::table('auditoria_operaciones')->orderByDesc('id_auditoria')->limit(25)->get(),
            'proyectos' => DB::table('auditoria_proyecto')->orderByDesc('id_auditoria')->limit(15)->get(),
            'historial' => DB::table('historial_participacion')->orderByDesc('id_historial')->limit(15)->get(),
        ]);
    }
}
