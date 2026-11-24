<x-app-layout>
    <x-slot name="header">
        <div class="flex items-center justify-between">
            <h2 class="font-semibold text-xl text-gray-800 leading-tight">Proyectos de investigación</h2>
            @can('create', App\Models\Proyecto::class)
                <a href="{{ route('proyectos.create') }}" class="rounded-md bg-indigo-600 px-4 py-2 text-sm text-white">Registrar proyecto</a>
            @endcan
        </div>
    </x-slot>

    <x-tarjeta>
        <div class="overflow-x-auto">
            <table class="min-w-full text-sm divide-y divide-gray-200">
                <thead class="bg-gray-50 text-left text-gray-600">
                    <tr>
                        <th class="px-3 py-2">Acrónimo</th><th class="px-3 py-2">Nombre</th><th class="px-3 py-2">Investigador principal</th>
                        <th class="px-3 py-2">Programa</th><th class="px-3 py-2">Vigencia</th><th class="px-3 py-2">Productos</th><th class="px-3 py-2">Estado</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-100">
                    @foreach ($proyectos as $p)
                        <tr class="hover:bg-gray-50">
                            <td class="px-3 py-2 font-semibold"><a class="text-indigo-700 hover:underline" href="{{ route('proyectos.show', $p) }}">{{ $p->acronimo }}</a></td>
                            <td class="px-3 py-2">{{ $p->nombre_proyecto }}</td>
                            <td class="px-3 py-2">{{ $p->investigadorPrincipal?->nombre_completo }}</td>
                            <td class="px-3 py-2">{{ $p->programa?->nombre_programa }}</td>
                            <td class="px-3 py-2 whitespace-nowrap">{{ $p->inicio_pro->format('d/m/Y') }} – {{ $p->finVigente()->format('d/m/Y') }}</td>
                            <td class="px-3 py-2 text-center">{{ $p->resumen?->total_productos ?? 0 }}</td>
                            <td class="px-3 py-2">
                                @if ($p->estaCerrado())
                                    <span class="rounded bg-gray-200 px-2 py-0.5 text-xs">Cerrado</span>
                                @else
                                    <span class="rounded bg-green-100 px-2 py-0.5 text-xs text-green-800">Abierto</span>
                                @endif
                            </td>
                        </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
        <div class="mt-4">{{ $proyectos->links() }}</div>
    </x-tarjeta>
</x-app-layout>
