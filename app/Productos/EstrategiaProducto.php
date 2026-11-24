<?php

namespace App\Productos;

/**
 * Patrón STRATEGY: cada tipo de producto (revista, congreso, libro, patente)
 * encapsula sus campos de formulario, sus reglas de validación y cómo se
 * traducen a los parámetros genéricos del procedimiento:
 *   p_nombre, p_editorial, p_dato_a, p_dato_b, p_dato_c, p_dato_d, p_fecha_1, p_fecha_2
 */
interface EstrategiaProducto
{
    public function idTipo(): int;

    public function etiqueta(): string;

    /** Campos del formulario: nombre => [etiqueta, tipo de input, opciones]. */
    public function campos(): array;

    /** Reglas de validación de Laravel para esos campos. */
    public function reglas(): array;

    /** Los 8 parámetros genéricos del SP, en orden. */
    public function parametrosSp(array $datos): array;
}
