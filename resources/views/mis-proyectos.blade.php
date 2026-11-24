<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">Mis proyectos</h2>
        <p class="text-sm text-gray-500">Datos de vistas personales filtradas en la base de datos por <code>fn_usuario_app()</code> = <code>{{ auth()->user()->db_usuario }}</code>.</p>
    </x-slot>
    @foreach ($secciones as $titulo => $s)
        <x-tarjeta :titulo="$titulo.' — '.$s['vista']" class="mb-6">
            <x-tabla :filas="$s['filas']" />
        </x-tarjeta>
    @endforeach
</x-app-layout>
