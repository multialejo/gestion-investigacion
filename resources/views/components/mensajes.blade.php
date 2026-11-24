@if (session('status'))
    <div class="mb-4 rounded-md bg-green-50 border border-green-200 p-4 text-sm text-green-800" role="status">
        {{ session('status') }}
    </div>
@endif
@if ($errors->any())
    <div class="mb-4 rounded-md bg-red-50 border border-red-200 p-4 text-sm text-red-800" role="alert">
        @if ($errors->has('bd'))
            <p class="font-semibold">La base de datos rechazó la operación:</p>
            <p class="mt-1 font-mono">{{ $errors->first('bd') }}</p>
        @else
            <p class="font-semibold">Revise los datos del formulario:</p>
            <ul class="mt-1 list-disc ps-5">
                @foreach ($errors->all() as $error)
                    <li>{{ $error }}</li>
                @endforeach
            </ul>
        @endif
    </div>
@endif
