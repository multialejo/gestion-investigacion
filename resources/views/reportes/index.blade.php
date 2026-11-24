<x-app-layout>
    <x-slot name="header"><h2 class="font-semibold text-xl text-gray-800 leading-tight">Reportes</h2></x-slot>
    <x-tarjeta>
        <ul class="divide-y divide-gray-100 text-sm">
            @foreach ($catalogo as $codigo => [, $titulo])
                <li class="py-3 flex items-center justify-between">
                    <a class="text-indigo-700 hover:underline font-medium" href="{{ route('reportes.show', $codigo) }}">{{ $titulo }}</a>
                </li>
            @endforeach
        </ul>
    </x-tarjeta>
</x-app-layout>
