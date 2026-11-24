<?php

namespace App\Productos;

class RevistaStrategy implements EstrategiaProducto
{
    public function idTipo(): int { return 1; }

    public function etiqueta(): string { return 'Publicación en revista'; }

    public function campos(): array
    {
        return [
            'nombre' => ['Nombre de la revista', 'text'],
            'editorial' => ['Editorial', 'text'],
            'volumen' => ['Volumen', 'text'],
            'cuartil' => ['Cuartil (vacío = regional)', 'select', ['' => 'Regional', 'Q1' => 'Q1', 'Q2' => 'Q2', 'Q3' => 'Q3', 'Q4' => 'Q4']],
            'numero' => ['Número', 'text'],
            'pagina_inicio' => ['Página inicial', 'number'],
            'pagina_fin' => ['Página final', 'number'],
        ];
    }

    public function reglas(): array
    {
        return [
            'nombre' => ['required', 'string', 'max:200'],
            'editorial' => ['required', 'string', 'max:150'],
            'volumen' => ['required', 'string', 'max:80'],
            'cuartil' => ['nullable', 'in:Q1,Q2,Q3,Q4'],
            'numero' => ['nullable', 'string', 'max:80'],
            'pagina_inicio' => ['nullable', 'integer', 'min:1'],
            'pagina_fin' => ['nullable', 'integer', 'min:1'],
        ];
    }

    public function parametrosSp(array $d): array
    {
        $paginas = filled($d['pagina_inicio'] ?? null) ? "{$d['pagina_inicio']}-{$d['pagina_fin']}" : '';

        return [$d['nombre'], $d['editorial'], $d['volumen'], $d['cuartil'] ?? '', $d['numero'] ?? '', $paginas, null, null];
    }
}
