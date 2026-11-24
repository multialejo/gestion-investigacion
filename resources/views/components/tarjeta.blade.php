@props(['titulo' => null])
<div {{ $attributes->merge(['class' => 'bg-white shadow-sm sm:rounded-lg p-6']) }}>
    @if ($titulo)
        <h3 class="font-semibold text-gray-800 mb-4">{{ $titulo }}</h3>
    @endif
    {{ $slot }}
</div>
