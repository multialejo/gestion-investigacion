<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">{{ strtoupper($codigo) }} · {{ $titulo }}</h2>
        <p class="text-sm text-gray-500"><code>CALL {{ $sp }}({{ implode(', ', array_map(fn ($p) => $argumentos[$p], array_keys($parametros))) }})</code></p>
    </x-slot>
    @if ($parametros)
        <x-tarjeta class="mb-6">
            <form method="GET" class="flex items-end gap-3">
                @foreach ($parametros as $nombre => $etiqueta)
                    @if ($nombre === 'id_proyecto')
                        <div><x-campo :nombre="$nombre" :etiqueta="$etiqueta" tipo="select" :opciones="$proyectos->all()" :valor="$argumentos[$nombre]" /></div>
                    @else
                        <div><x-campo :nombre="$nombre" :etiqueta="$etiqueta" tipo="number" :valor="$argumentos[$nombre]" /></div>
                    @endif
                @endforeach
                <x-primary-button>Ejecutar</x-primary-button>
            </form>
        </x-tarjeta>
    @endif
    <x-tarjeta>
        <p class="mb-3 text-xs text-gray-500">{{ $filas->count() }} fila(s)</p>
        <x-tabla :filas="$filas" />
    </x-tarjeta>
    <a href="{{ route('reportes.index') }}" class="mt-4 inline-block text-sm text-indigo-700">← Todos los reportes</a>
</x-app-layout>
