<?php

namespace App\Http\Controllers;

use App\Database\Procedimientos\CambioDirector;
use App\Database\Procedimientos\ControlProrroga;
use App\Database\Procedimientos\ControlResponsables;
use App\Database\Procedimientos\DesvincularCierre;
use App\Database\Procedimientos\RegistrarProyecto;
use App\Facades\Procedimientos;
use App\Http\Requests\RegistrarProyectoRequest;
use App\Models\LineaInvestigacion;
use App\Models\Profesor;
use App\Models\Programa;
use App\Models\Proyecto;
use App\Productos\FabricaEstrategiaProducto;
use Illuminate\Http\Request;

class ProyectoController extends Controller
{
    public function index()
    {
        $this->authorize('viewAny', Proyecto::class);

        $proyectos = Proyecto::with(['investigadorPrincipal', 'programa', 'resumen'])
            ->orderByDesc('id_proyecto')
            ->paginate(10);

        return view('proyectos.index', compact('proyectos'));
    }

    public function show(Proyecto $proyecto)
    {
        $this->authorize('view', $proyecto);

        $proyecto->load(['investigadorPrincipal', 'programa', 'resumen', 'lineas',
            'participaciones' => fn ($q) => $q->with('profesor')->orderBy('fecha_inicio'),
            'productos' => fn ($q) => $q->with('tipo')->orderBy('num_secuencia')]);

        return view('proyectos.show', [
            'proyecto' => $proyecto,
            'profesores' => Profesor::orderBy('apellidos')->get(),
            'lineas' => LineaInvestigacion::orderBy('codigo')->get(),
            'estrategias' => FabricaEstrategiaProducto::todas(),
        ]);
    }

    public function create()
    {
        $this->authorize('create', Proyecto::class);

        return view('proyectos.create', [
            'profesores' => Profesor::orderBy('apellidos')->get(), // incluye no doctores: el SP los rechaza
            'programas' => Programa::orderBy('nombre_programa')->pluck('nombre_programa'),
        ]);
    }

    /** Escritura SOLO por procedimiento almacenado (transacción dentro de la BD). */
    public function store(RegistrarProyectoRequest $request)
    {
        Procedimientos::ejecutar(new RegistrarProyecto($request->validated()));

        $proyecto = Proyecto::where('acronimo', $request->acronimo)->firstOrFail();

        return redirect()->route('proyectos.show', $proyecto)
            ->with('status', "Proyecto {$proyecto->acronimo} registrado correctamente.");
    }

    public function prorroga(Request $request, Proyecto $proyecto)
    {
        $this->authorize('modificar', $proyecto);
        $datos = $request->validate(['nueva_fecha_fin' => ['required', 'date']]);

        Procedimientos::ejecutar(new ControlProrroga($proyecto->id_proyecto, $datos['nueva_fecha_fin']));

        return back()->with('status', 'Prórroga registrada correctamente.');
    }

    public function cambioDirector(Request $request, Proyecto $proyecto)
    {
        $this->authorize('modificar', $proyecto);
        $datos = $this->validarRelevo($request, $proyecto, 'Director');

        Procedimientos::ejecutar(new CambioDirector($proyecto->id_proyecto, $datos));

        return back()->with('status', 'Cambio de director registrado correctamente.');
    }

    public function relevo(Request $request, Proyecto $proyecto)
    {
        $this->authorize('modificar', $proyecto);
        $datos = $this->validarRelevo($request, $proyecto, 'Director');

        Procedimientos::ejecutar(new ControlResponsables($proyecto->id_proyecto, $datos));

        return back()->with('status', 'Relevo registrado: el subrogante asume la dirección del proyecto.');
    }

    /** Rol admin: actualización con Eloquent → dispara trg_auditoria_proyecto_upd. */
    public function registrarCierre(Request $request, Proyecto $proyecto)
    {
        $this->authorize('registrarCierre', $proyecto);
        $datos = $request->validate(['resolucion_cierre' => ['required', 'string', 'max:50']]);

        $proyecto->update(['resolucion_consejo_uni_cierre' => $datos['resolucion_cierre']]);

        return back()->with('status', 'Cierre del proyecto registrado (puede consultarlo en Auditoría).');
    }

    public function desvincular(Proyecto $proyecto)
    {
        $this->authorize('desvincular', $proyecto);

        Procedimientos::ejecutar(new DesvincularCierre($proyecto->id_proyecto));

        return back()->with('status', 'Personal desvinculado correctamente.');
    }

    private function validarRelevo(Request $request, Proyecto $proyecto, string $cargo): array
    {
        $datos = $request->validate([
            'id_entrante' => ['required', 'integer'],
            'resolucion_salida' => ['required', 'string', 'max:50'],
            'motivo_salida' => ['required', 'string', 'max:200'],
            'resolucion_ingreso' => ['required', 'string', 'max:50'],
        ]);

        // El saliente es quien ocupa el cargo actualmente (si no hay, el SP lo rechaza).
        $datos['id_saliente'] = $proyecto->participaciones()
            ->where('cargo', $cargo)->whereNull('resolucion_salida')->value('id_profesor') ?? 0;

        return $datos;
    }
}
