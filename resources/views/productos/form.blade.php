@php($reclasificar = $producto !== null)
<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
            {{ $reclasificar ? 'Reclasificar producto' : 'Registrar producto' }} · {{ $proyecto->acronimo }}
        </h2>
        <p class="text-sm text-gray-500">
            Estrategia: <code>{{ class_basename($estrategia) }}</code> →
            <code>{{ $reclasificar ? 'sp_reclasificar_producto_transaccional' : 'sp_registrar_producto_transaccional' }}</code>
        </p>
    </x-slot>

    <x-tarjeta>
        <div class="mb-4 flex flex-wrap gap-2 text-sm">
            <span class="py-1 text-gray-500">Tipo:</span>
            @foreach ($estrategias as $e)
                @continue($reclasificar && $e->idTipo() === $producto->id_tipo)
                <a href="{{ $reclasificar ? route('productos.edit-tipo', [$producto, 'tipo' => $e->idTipo()]) : route('productos.create', [$proyecto, 'tipo' => $e->idTipo()]) }}"
                   class="rounded-full px-3 py-1 {{ $e->idTipo() === $estrategia->idTipo() ? 'bg-indigo-600 text-white' : 'bg-gray-100 text-gray-700' }}">{{ $e->etiqueta() }}</a>
            @endforeach
        </div>

        @if ($reclasificar)
            <p class="mb-4 text-sm">Producto: <strong>{{ $producto->titulo_publicacion }}</strong> (actualmente {{ $producto->tipo->descripcion_tipo }})</p>
        @endif

        <form method="POST" action="{{ $reclasificar ? route('productos.reclasificar', $producto) : route('productos.store', $proyecto) }}" class="grid gap-4 md:grid-cols-2">
            @csrf
            <input type="hidden" name="tipo" value="{{ $estrategia->idTipo() }}">
            @unless ($reclasificar)
                <div class="md:col-span-2"><x-campo nombre="titulo" etiqueta="Título de la publicación" /></div>
            @endunless
            @foreach ($estrategia->campos() as $nombre => $def)
                <x-campo :nombre="$nombre" :etiqueta="$def[0]" :tipo="$def[1]" :opciones="$def[2] ?? []" />
            @endforeach
            <div class="md:col-span-2 flex justify-end gap-3">
                <a href="{{ route('proyectos.show', $proyecto) }}" class="px-4 py-2 text-sm text-gray-600">Cancelar</a>
                <x-primary-button>{{ $reclasificar ? 'Reclasificar' : 'Registrar' }}</x-primary-button>
            </div>
        </form>
    </x-tarjeta>
</x-app-layout>
