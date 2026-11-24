<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">Gestión de Proyectos de Investigación</h2>
    </x-slot>

    <div class="grid gap-6 md:grid-cols-2">
        <x-tarjeta titulo="Sesión">
            <dl class="text-sm grid grid-cols-3 gap-y-2">
                <dt class="text-gray-500">Usuario</dt><dd class="col-span-2">{{ $usuario->name }} ({{ $usuario->email }})</dd>
                <dt class="text-gray-500">Rol en la aplicación</dt><dd class="col-span-2 font-semibold">{{ $usuario->rol }}</dd>
            </dl>
        </x-tarjeta>

        <x-tarjeta titulo="Conexión a MariaDB de esta petición">
            <dl class="text-sm grid grid-cols-3 gap-y-2">
                <dt class="text-gray-500">CURRENT_USER()</dt><dd class="col-span-2 font-mono">{{ $conexion->cuenta }}</dd>
                <dt class="text-gray-500">CURRENT_ROLE()</dt><dd class="col-span-2 font-mono">{{ $conexion->rol }}</dd>
                <dt class="text-gray-500">@app_usuario</dt><dd class="col-span-2 font-mono">{{ $conexion->persona }}</dd>
            </dl>
            <p class="mt-3 text-xs text-gray-500">Los permisos de la base de datos dependen de esta cuenta de servicio, no solo de la aplicación.</p>
        </x-tarjeta>
    </div>

    <x-tarjeta titulo="Accesos" class="mt-6">
        <div class="flex flex-wrap gap-3 text-sm">
            @can('ver-proyectos') <a class="rounded-md bg-indigo-600 px-4 py-2 text-white" href="{{ route('proyectos.index') }}">Proyectos</a> @endcan
            @can('create', App\Models\Proyecto::class) <a class="rounded-md bg-indigo-600 px-4 py-2 text-white" href="{{ route('proyectos.create') }}">Registrar proyecto</a> @endcan
            @can('ver-reportes') <a class="rounded-md bg-indigo-600 px-4 py-2 text-white" href="{{ route('reportes.index') }}">Reportes</a> @endcan
            @can('ver-auditoria') <a class="rounded-md bg-indigo-600 px-4 py-2 text-white" href="{{ route('auditoria') }}">Auditoría</a> @endcan
            @can('ver-mis-proyectos') <a class="rounded-md bg-indigo-600 px-4 py-2 text-white" href="{{ route('mis-proyectos') }}">Mis proyectos</a> @endcan
        </div>
    </x-tarjeta>
</x-app-layout>
