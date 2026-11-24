<?php

namespace App\Exceptions;

use Illuminate\Database\QueryException;
use RuntimeException;

/**
 * Una regla del negocio rechazada por la base de datos: SIGNAL de un trigger o
 * de un procedimiento (SQLSTATE 45000), CHECK, UNIQUE o clave foránea.
 * Se muestra al usuario como un error de formulario.
 */
class ReglaDeNegocioException extends RuntimeException
{
    /** Códigos MariaDB que representan reglas del negocio y no fallos técnicos. */
    private const CODIGOS = [
        1644, // SIGNAL SQLSTATE '45000' (triggers y procedimientos)
        4025, // CHECK constraint
        1062, // UNIQUE / PRIMARY KEY duplicada
        1451, // FK: fila referenciada
        1452, // FK: no existe la fila padre
    ];

    public static function esRegla(QueryException $e): bool
    {
        return ($e->errorInfo[0] ?? null) === '45000'
            || in_array($e->errorInfo[1] ?? null, self::CODIGOS, true);
    }

    public static function desde(QueryException $e): self
    {
        return new self($e->errorInfo[2] ?? $e->getMessage(), (int) ($e->errorInfo[1] ?? 0), $e);
    }
}
