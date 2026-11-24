<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">Registrar proyecto</h2>
        <p class="text-sm text-gray-500">Al registrarlo se crea el proyecto y su investigador principal queda asignado como Director.</p>
    </x-slot>

    <x-tarjeta>
        <form method="POST" action="{{ route('proyectos.store') }}" class="grid gap-4 md:grid-cols-2">
            @csrf
            <div class="md:col-span-2"><x-campo nombre="nombre_proyecto" etiqueta="Nombre del proyecto" /></div>
            <x-campo nombre="acronimo" etiqueta="Acrónimo" />
            <x-campo nombre="presupuesto" etiqueta="Presupuesto (USD)" tipo="number" />
            <div>
                <x-input-label for="programa" value="Programa de I+D" />
                <x-text-input id="programa" name="programa" list="programas" class="mt-1 block w-full text-sm" :value="old('programa')" />
                <datalist id="programas">@foreach ($programas as $prog)<option value="{{ $prog }}">@endforeach</datalist>
                <x-input-error :messages="$errors->get('programa')" class="mt-1" />
            </div>
            <x-campo nombre="id_investigador_principal" etiqueta="Investigador principal" tipo="select"
                :opciones="['' => '— Seleccione —'] + $profesores->mapWithKeys(fn ($p) => [$p->id_profesor => $p->apellidos.' '.$p->nombres.' ('.str_replace('_', ' ', $p->tipo).')'])->all()" />
            <x-campo nombre="inicio_pro" etiqueta="Fecha de inicio" tipo="date" />
            <x-campo nombre="fin_pro" etiqueta="Fecha de fin" tipo="date" />
            <x-campo nombre="resolucion" etiqueta="Resolución del Consejo Universitario" />
            <div class="md:col-span-2"><x-campo nombre="descripcion" etiqueta="Objetivos / descripción" tipo="textarea" /></div>
            <div class="md:col-span-2 flex justify-end gap-3">
                <a href="{{ route('proyectos.index') }}" class="px-4 py-2 text-sm text-gray-600">Cancelar</a>
                <x-primary-button>Registrar</x-primary-button>
            </div>
        </form>
    </x-tarjeta>
</x-app-layout>
