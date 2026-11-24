@props(['nombre', 'etiqueta', 'tipo' => 'text', 'opciones' => [], 'valor' => null])
<div>
    <x-input-label :for="$nombre" :value="$etiqueta" />
    @if ($tipo === 'select')
        <select id="{{ $nombre }}" name="{{ $nombre }}" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:border-indigo-500 focus:ring-indigo-500 text-sm">
            @foreach ($opciones as $clave => $texto)
                <option value="{{ $clave }}" @selected((string) old($nombre, $valor) === (string) $clave)>{{ $texto }}</option>
            @endforeach
        </select>
    @elseif ($tipo === 'textarea')
        <textarea id="{{ $nombre }}" name="{{ $nombre }}" rows="3" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:border-indigo-500 focus:ring-indigo-500 text-sm">{{ old($nombre, $valor) }}</textarea>
    @else
        <x-text-input :id="$nombre" :name="$nombre" :type="$tipo" class="mt-1 block w-full text-sm" :value="old($nombre, $valor)" step="any" />
    @endif
    <x-input-error :messages="$errors->get($nombre)" class="mt-1" />
</div>
