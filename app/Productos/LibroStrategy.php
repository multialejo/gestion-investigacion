<?php

namespace App\Productos;

class LibroStrategy implements EstrategiaProducto
{
    public function idTipo(): int { return 3; }

    public function etiqueta(): string { return 'Libro'; }

    public function campos(): array
    {
        return [
            'nombre' => ['Título del libro', 'text'],
            'editorial' => ['Editorial', 'text'],
            'isbn' => ['ISBN', 'text'],
            'fecha_publicacion' => ['Fecha de publicación', 'date'],
        ];
    }

    public function reglas(): array
    {
        return [
            'nombre' => ['required', 'string', 'max:200'],
            'editorial' => ['required', 'string', 'max:150'],
            'isbn' => ['required', 'string', 'max:80'],
            'fecha_publicacion' => ['required', 'date'],
        ];
    }

    public function parametrosSp(array $d): array
    {
        return [$d['nombre'], $d['editorial'], $d['isbn'], null, null, null, $d['fecha_publicacion'], null];
    }
}
