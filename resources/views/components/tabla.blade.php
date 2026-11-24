@props(['filas', 'vacio' => 'Sin registros.'])
@php($filas = collect($filas))
@if ($filas->isEmpty())
    <p class="text-sm text-gray-500 italic">{{ $vacio }}</p>
@else
    <div class="overflow-x-auto">
        <table class="min-w-full text-sm divide-y divide-gray-200">
            <thead class="bg-gray-50">
                <tr>
                    @foreach (array_keys((array) $filas->first()) as $col)
                        <th class="px-3 py-2 text-left font-semibold text-gray-600 whitespace-nowrap">{{ str_replace('_', ' ', $col) }}</th>
                    @endforeach
                </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
                @foreach ($filas as $fila)
                    <tr class="hover:bg-gray-50">
                        @foreach ((array) $fila as $valor)
                            <td class="px-3 py-2 text-gray-800">{{ $valor ?? '—' }}</td>
                        @endforeach
                    </tr>
                @endforeach
            </tbody>
        </table>
    </div>
@endif
