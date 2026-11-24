<x-app-layout>
    <x-slot name="header"><h2 class="font-semibold text-xl text-gray-800 leading-tight">Auditoría</h2></x-slot>
    <x-tarjeta titulo="auditoria_operaciones — resultado de cada procedimiento transaccional (EXITOSO / FALLIDO)">
        <x-tabla :filas="$operaciones" />
    </x-tarjeta>
    <x-tarjeta titulo="auditoria_proyecto — trg_auditoria_proyecto_upd / _del" class="mt-6">
        <x-tabla :filas="$proyectos" />
    </x-tarjeta>
    <x-tarjeta titulo="historial_participacion — trg_historial_participacion" class="mt-6">
        <x-tabla :filas="$historial" />
    </x-tarjeta>
</x-app-layout>
