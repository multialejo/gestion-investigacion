<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    public function __invoke(Request $request)
    {
        $conexion = DB::selectOne('SELECT CURRENT_USER() AS cuenta, CURRENT_ROLE() AS rol, @app_usuario AS persona');

        return view('dashboard', ['usuario' => $request->user(), 'conexion' => $conexion]);
    }
}
