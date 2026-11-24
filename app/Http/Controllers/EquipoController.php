<?php

namespace App\Http\Controllers;

use App\Models\Participacion;
use App\Models\Proyecto;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * Transacción GESTIONADA POR LA APLICACIÓN: varias filas en proyecto_profesor
 * y proyecto_linea forman un solo lote. Si un trigger rechaza cualquiera
 * (trg_validar_participacion, trg_proyecto_linea_bi), DB::transaction() hace
 * ROLLBACK de todo el lote y relanza la excepción.
 *
 * No se usa para los sp_*_transaccional: su START TRANSACTION interno
 * confirmaría implícitamente la transacción exterior.
 */
class EquipoController extends Controller
{
    public function store(Request $request, Proyecto $proyecto)
    {
        $this->authorize('modificar', $proyecto);

        $datos = $request->validate([
            'miembros' => ['array'],
            'miembros.*.id_profesor' => ['nullable', 'integer', 'distinct'],
            'miembros.*.cargo' => ['required_with:miembros.*.id_profesor', 'in:Investigador,Director subrogante'],
            'miembros.*.fecha_inicio' => ['required_with:miembros.*.id_profesor', 'nullable', 'date'],
            'miembros.*.resolucion_ingreso' => ['required_with:miembros.*.id_profesor', 'nullable', 'string', 'max:50'],
            'lineas' => ['array'],
            'lineas.*' => ['integer'],
        ]);

        $miembros = collect($datos['miembros'] ?? [])->filter(fn ($m) => filled($m['id_profesor'] ?? null));
        $lineas = collect($datos['lineas'] ?? []);

        if ($miembros->isEmpty() && $lineas->isEmpty()) {
            return back()->withErrors(['lote' => 'Seleccione al menos un profesor o una línea.']);
        }

        DB::transaction(function () use ($proyecto, $miembros, $lineas) {
            foreach ($miembros as $m) {
                Participacion::create($m + ['id_proyecto' => $proyecto->id_proyecto]);
            }
            foreach ($lineas as $idLinea) {
                DB::table('proyecto_linea')->insert(['id_proyecto' => $proyecto->id_proyecto, 'id_linea' => $idLinea]);
            }
        });

        return back()->with('status', "Se guardaron {$miembros->count()} integrante(s) del equipo y {$lineas->count()} línea(s) de investigación.");
    }
}
