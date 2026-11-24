<?php

namespace App\Http\Controllers;

use App\Database\Procedimientos\Reporte;
use App\Facades\Procedimientos;
use App\Models\Proyecto;
use Illuminate\Http\Request;

class ReporteController extends Controller
{
    public function index()
    {
        return view('reportes.index', ['catalogo' => Reporte::CATALOGO]);
    }

    public function show(Request $request, string $codigo)
    {
        abort_unless(isset(Reporte::CATALOGO[$codigo]), 404);
        [$sp, $titulo, $parametros] = Reporte::CATALOGO[$codigo];

        $argumentos = $request->validate([
            'id_proyecto' => ['nullable', 'integer'],
            'dias_aviso' => ['nullable', 'integer', 'min:1', 'max:365'],
        ]) + ['id_proyecto' => Proyecto::min('id_proyecto'), 'dias_aviso' => 60];

        $filas = Procedimientos::ejecutar(new Reporte($codigo, $argumentos));

        return view('reportes.show', [
            'codigo' => $codigo, 'sp' => $sp, 'titulo' => $titulo, 'parametros' => $parametros,
            'argumentos' => $argumentos, 'filas' => $filas,
            'proyectos' => array_key_exists('id_proyecto', $parametros) ? Proyecto::orderBy('acronimo')->pluck('acronimo', 'id_proyecto') : collect(),
        ]);
    }
}
