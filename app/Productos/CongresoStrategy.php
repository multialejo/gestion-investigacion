<?php

namespace App\Productos;

class CongresoStrategy implements EstrategiaProducto
{
    public function idTipo(): int { return 2; }

    public function etiqueta(): string { return 'Publicación en congreso'; }

    public function campos(): array
    {
        return [
            'nombre' => ['Nombre del congreso', 'text'],
            'tipo_congreso' => ['Tipo', 'select', ['Nacional' => 'Nacional', 'Internacional' => 'Internacional']],
            'fecha_inicio' => ['Fecha de inicio', 'date'],
            'fecha_fin' => ['Fecha de fin', 'date'],
            'lugar' => ['Lugar de celebración', 'text'],
            'pais' => ['País', 'text'],
            'editorial' => ['Editorial de las actas (opcional)', 'text'],
            'participacion' => ['Tipo de participación', 'select', ['Ponencia' => 'Ponencia', 'Póster' => 'Póster', 'Conferencia magistral' => 'Conferencia magistral']],
        ];
    }

    public function reglas(): array
    {
        return [
            'nombre' => ['required', 'string', 'max:200'],
            'tipo_congreso' => ['required', 'in:Nacional,Internacional'],
            'fecha_inicio' => ['required', 'date'],
            'fecha_fin' => ['required', 'date', 'after_or_equal:fecha_inicio'],
            'lugar' => ['required', 'string', 'max:150'],
            'pais' => ['required', 'string', 'max:80'],
            'editorial' => ['nullable', 'string', 'max:150'],
            'participacion' => ['required', 'string', 'max:80'],
        ];
    }

    public function parametrosSp(array $d): array
    {
        return [$d['nombre'], $d['editorial'] ?? null, $d['tipo_congreso'], $d['lugar'], $d['pais'],
            $d['participacion'], $d['fecha_inicio'], $d['fecha_fin']];
    }
}
