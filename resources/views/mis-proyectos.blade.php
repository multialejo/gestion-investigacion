<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">Mis proyectos</h2>
        <p class="text-sm text-gray-500">Aquí ve únicamente su información personal: los proyectos, el equipo y las publicaciones en los que participa.</p>
    </x-slot>
    @foreach ($secciones as $titulo => $s)
        <x-tarjeta :titulo="$titulo" class="mb-6">
            <x-tabla :filas="$s['filas']" />
        </x-tarjeta>
    @endforeach
</x-app-layout>
