@php
    $opcionesProfesor = ['' => '— Seleccione —'] + $profesores->mapWithKeys(fn ($p) => [$p->id_profesor => $p->apellidos.' '.$p->nombres.' ('.str_replace('_', ' ', $p->tipo).')'])->all();
    $boton = 'rounded-md bg-indigo-600 px-3 py-2 text-sm text-white hover:bg-indigo-700';
@endphp
<x-app-layout>
    <x-slot name="header">
        <div class="flex flex-wrap items-center justify-between gap-2">
            <div>
                <h2 class="font-semibold text-xl text-gray-800 leading-tight">{{ $proyecto->acronimo }} · {{ $proyecto->nombre_proyecto }}</h2>
                <p class="text-sm text-gray-500">{{ $proyecto->programa?->nombre_programa }}</p>
            </div>
            @if ($proyecto->estaCerrado())
                <span class="rounded bg-gray-200 px-3 py-1 text-sm">Cerrado · {{ $proyecto->resolucion_consejo_uni_cierre }}</span>
            @else
                <span class="rounded bg-green-100 px-3 py-1 text-sm text-green-800">Abierto</span>
            @endif
        </div>
    </x-slot>

    <div class="grid gap-6 lg:grid-cols-3">
        <x-tarjeta titulo="Datos del proyecto" class="lg:col-span-1">
            <dl class="text-sm grid grid-cols-2 gap-y-2">
                <dt class="text-gray-500">Investigador principal</dt><dd>{{ $proyecto->investigadorPrincipal?->nombre_completo }}</dd>
                <dt class="text-gray-500">Presupuesto</dt><dd>$ {{ number_format($proyecto->presupuesto, 2) }}</dd>
                <dt class="text-gray-500">Inicio</dt><dd>{{ $proyecto->inicio_pro->format('d/m/Y') }}</dd>
                <dt class="text-gray-500">Fin</dt><dd>{{ $proyecto->fin_pro->format('d/m/Y') }}</dd>
                <dt class="text-gray-500">Prórroga</dt><dd>{{ $proyecto->prorroga?->format('d/m/Y') ?? '—' }}</dd>
                <dt class="text-gray-500">Resolución</dt><dd>{{ $proyecto->resolucion_consejo_uni_aprobado }}</dd>
                <dt class="text-gray-500">Productos</dt><dd>{{ $proyecto->resumen?->total_productos ?? 0 }} <span class="text-xs text-gray-400">(se actualiza automáticamente)</span></dd>
            </dl>
            <p class="mt-4 text-sm text-gray-700">{{ $proyecto->descripcion }}</p>
            <h4 class="mt-4 font-semibold text-sm text-gray-700">Líneas de investigación</h4>
            <ul class="mt-1 text-sm list-disc ps-5">
                @forelse ($proyecto->lineas as $l) <li>{{ $l->codigo }} · {{ $l->nombre_linea }}</li> @empty <li class="list-none -ms-5 text-gray-500 italic">Sin líneas.</li> @endforelse
            </ul>
        </x-tarjeta>

        <x-tarjeta titulo="Equipo del proyecto" class="lg:col-span-2">
            <table class="min-w-full text-sm divide-y divide-gray-200">
                <thead class="bg-gray-50 text-left text-gray-600"><tr><th class="px-2 py-2">Profesor</th><th class="px-2 py-2">Cargo</th><th class="px-2 py-2">Desde</th><th class="px-2 py-2">Hasta</th><th class="px-2 py-2">Resoluciones</th></tr></thead>
                <tbody class="divide-y divide-gray-100">
                    @foreach ($proyecto->participaciones as $pp)
                        <tr class="{{ $pp->estaActiva() ? '' : 'text-gray-400' }}">
                            <td class="px-2 py-2">{{ $pp->profesor->nombre_completo }}</td>
                            <td class="px-2 py-2">{{ $pp->cargo }}</td>
                            <td class="px-2 py-2">{{ $pp->fecha_inicio->format('d/m/Y') }}</td>
                            <td class="px-2 py-2">{{ $pp->fecha_fin?->format('d/m/Y') ?? 'activo' }}</td>
                            <td class="px-2 py-2 text-xs">{{ $pp->resolucion_ingreso }} {{ $pp->resolucion_salida ? '→ '.$pp->resolucion_salida : '' }}</td>
                        </tr>
                    @endforeach
                </tbody>
            </table>
        </x-tarjeta>
    </div>

    <x-tarjeta titulo="Productos (publicaciones)" class="mt-6">
        <table class="min-w-full text-sm divide-y divide-gray-200">
            <thead class="bg-gray-50 text-left text-gray-600"><tr><th class="px-2 py-2">Nº</th><th class="px-2 py-2">Título</th><th class="px-2 py-2">Tipo</th><th></th></tr></thead>
            <tbody class="divide-y divide-gray-100">
                @forelse ($proyecto->productos as $pr)
                    <tr>
                        <td class="px-2 py-2">{{ $pr->num_secuencia }}</td>
                        <td class="px-2 py-2">{{ $pr->titulo_publicacion }}</td>
                        <td class="px-2 py-2">{{ $pr->tipo->descripcion_tipo }}</td>
                        <td class="px-2 py-2 text-right">
                            @can('modificar', $proyecto)
                                <a class="text-indigo-700 hover:underline text-xs" href="{{ route('productos.edit-tipo', $pr) }}">Reclasificar</a>
                            @endcan
                        </td>
                    </tr>
                @empty
                    <tr><td colspan="4" class="px-2 py-2 text-gray-500 italic">Sin productos.</td></tr>
                @endforelse
            </tbody>
        </table>
        @can('modificar', $proyecto)
            <div class="mt-4 flex flex-wrap gap-2">
                @foreach ($estrategias as $e)
                    <a class="{{ $boton }}" href="{{ route('productos.create', [$proyecto, 'tipo' => $e->idTipo()]) }}">+ {{ $e->etiqueta() }}</a>
                @endforeach
            </div>
        @endcan
    </x-tarjeta>

    @can('modificar', $proyecto)
        <h3 class="mt-8 mb-3 font-semibold text-lg text-gray-800">Operaciones (secretaría)</h3>
        <div class="grid gap-6 lg:grid-cols-2">
            <x-tarjeta titulo="Asignar equipo y líneas de investigación">
                <form method="POST" action="{{ route('proyectos.equipo', $proyecto) }}" class="space-y-3">
                    @csrf
                    @for ($i = 0; $i < 2; $i++)
                        <div class="grid grid-cols-2 gap-2 border-b pb-3">
                            <x-campo nombre="miembros[{{ $i }}][id_profesor]" etiqueta="Profesor {{ $i + 1 }}" tipo="select" :opciones="$opcionesProfesor" :valor="old('miembros.'.$i.'.id_profesor')" />
                            <x-campo nombre="miembros[{{ $i }}][cargo]" etiqueta="Cargo" tipo="select" :opciones="['Investigador' => 'Investigador', 'Director subrogante' => 'Director subrogante']" :valor="old('miembros.'.$i.'.cargo')" />
                            <x-campo nombre="miembros[{{ $i }}][fecha_inicio]" etiqueta="Desde" tipo="date" :valor="old('miembros.'.$i.'.fecha_inicio')" />
                            <x-campo nombre="miembros[{{ $i }}][resolucion_ingreso]" etiqueta="Resolución de ingreso" :valor="old('miembros.'.$i.'.resolucion_ingreso')" />
                        </div>
                    @endfor
                    <div>
                        <x-input-label value="Líneas a incluir" />
                        <div class="mt-1 grid grid-cols-1 gap-1 text-sm">
                            @foreach ($lineas->whereNotIn('id_linea', $proyecto->lineas->pluck('id_linea')) as $l)
                                <label class="flex items-center gap-2"><input type="checkbox" name="lineas[]" value="{{ $l->id_linea }}" @checked(in_array($l->id_linea, old('lineas', []))) class="rounded border-gray-300"> {{ $l->codigo }} · {{ $l->nombre_linea }}</label>
                            @endforeach
                        </div>
                    </div>
                    <button class="{{ $boton }}">Guardar lote</button>
                </form>
            </x-tarjeta>

            <div class="space-y-6">
                <x-tarjeta titulo="Prórroga">
                    <form method="POST" action="{{ route('proyectos.prorroga', $proyecto) }}" class="flex items-end gap-3">
                        @csrf
                        <div class="flex-1"><x-campo nombre="nueva_fecha_fin" etiqueta="Nueva fecha de fin" tipo="date" /></div>
                        <button class="{{ $boton }}">Registrar</button>
                    </form>
                </x-tarjeta>

                <x-tarjeta titulo="Cambio de director / relevo">
                    <form method="POST" action="{{ route('proyectos.cambio-director', $proyecto) }}" class="grid grid-cols-2 gap-2">
                        @csrf
                        <div class="col-span-2"><x-campo nombre="id_entrante" etiqueta="Profesor entrante" tipo="select" :opciones="$opcionesProfesor" /></div>
                        <x-campo nombre="resolucion_salida" etiqueta="Resolución de salida" />
                        <x-campo nombre="resolucion_ingreso" etiqueta="Resolución de ingreso" />
                        <div class="col-span-2"><x-campo nombre="motivo_salida" etiqueta="Motivo de salida" /></div>
                        <div class="col-span-2 flex flex-wrap gap-2">
                            <button class="{{ $boton }}">Nuevo director</button>
                            <button class="{{ $boton }} bg-slate-600 hover:bg-slate-700" formaction="{{ route('proyectos.relevo', $proyecto) }}">Subrogante asume la dirección</button>
                        </div>
                    </form>
                </x-tarjeta>
            </div>
        </div>
    @endcan

    @can('registrarCierre', $proyecto)
        <x-tarjeta titulo="Cierre del proyecto (administrador)" class="mt-6">
            <form method="POST" action="{{ route('proyectos.cierre', $proyecto) }}" class="flex items-end gap-3">
                @csrf
                <div class="flex-1"><x-campo nombre="resolucion_cierre" etiqueta="Resolución de cierre del Consejo Universitario" /></div>
                <button class="{{ $boton }} bg-red-600 hover:bg-red-700">Registrar cierre</button>
            </form>
        </x-tarjeta>
    @endcan

    @can('desvincular', $proyecto)
        <x-tarjeta titulo="Desvincular personal" class="mt-6">
            <form method="POST" action="{{ route('proyectos.desvincular', $proyecto) }}">
                @csrf
                <button class="{{ $boton }} bg-red-600 hover:bg-red-700">Desvincular profesores y estudiantes</button>
            </form>
        </x-tarjeta>
    @endcan
</x-app-layout>
