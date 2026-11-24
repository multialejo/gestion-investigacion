<?php

namespace App\Productos;

use InvalidArgumentException;

/**
 * Patrón FACTORY METHOD: decide qué estrategia concreta instanciar a partir
 * del id_tipo (tabla tipo_pro). Los controladores dependen solo de la
 * interfaz EstrategiaProducto.
 */
class FabricaEstrategiaProducto
{
    private const TIPOS = [
        1 => RevistaStrategy::class,
        2 => CongresoStrategy::class,
        3 => LibroStrategy::class,
        4 => PatenteStrategy::class,
    ];

    public static function para(int $idTipo): EstrategiaProducto
    {
        $clase = self::TIPOS[$idTipo] ?? throw new InvalidArgumentException("Tipo de producto no válido: {$idTipo}");

        return new $clase;
    }

    /** @return array<int, EstrategiaProducto> */
    public static function todas(): array
    {
        return array_map(fn ($clase) => new $clase, self::TIPOS);
    }
}
