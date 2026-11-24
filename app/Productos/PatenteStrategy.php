<?php

namespace App\Productos;

class PatenteStrategy implements EstrategiaProducto
{
    public function idTipo(): int { return 4; }

    public function etiqueta(): string { return 'Patente'; }

    public function campos(): array
    {
        return [
            'nombre' => ['Nombre de la patente', 'text'],
            'num_registro' => ['Nº de registro', 'text'],
            'pais' => ['País de registro', 'text'],
            'num_solicitud' => ['Nº de solicitud', 'text'],
            'fecha_solicitud' => ['Fecha de solicitud', 'date'],
        ];
    }

    public function reglas(): array
    {
        return [
            'nombre' => ['required', 'string', 'max:200'],
            'num_registro' => ['required', 'string', 'max:80'],
            'pais' => ['required', 'string', 'max:80'],
            'num_solicitud' => ['required', 'string', 'max:80'],
            'fecha_solicitud' => ['required', 'date'],
        ];
    }

    public function parametrosSp(array $d): array
    {
        return [$d['nombre'], null, $d['num_registro'], $d['pais'], $d['num_solicitud'], null, $d['fecha_solicitud'], null];
    }
}
