<x-app-layout>
    <x-slot name="header"><h2 class="font-semibold text-xl text-gray-800 leading-tight">Auditoría</h2></x-slot>
    <x-tarjeta titulo="Operaciones realizadas — resultado de cada operación (EXITOSO / FALLIDO)">
        <x-tabla :filas="$operaciones" />
    </x-tarjeta>
    <x-tarjeta titulo="Cambios y eliminaciones de proyectos" class="mt-6">
        <x-tabla :filas="$proyectos" />
    </x-tarjeta>
    <x-tarjeta titulo="Historial de cambios en el equipo de los proyectos" class="mt-6">
        <x-tabla :filas="$historial" />
    </x-tarjeta>
</x-app-layout>
