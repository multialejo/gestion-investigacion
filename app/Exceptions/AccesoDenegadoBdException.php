<?php

namespace App\Exceptions;

use Illuminate\Database\QueryException;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;

/** MariaDB negó la operación a la cuenta de servicio del rol (segunda capa). */
class AccesoDenegadoBdException extends AccessDeniedHttpException
{
    private const CODIGOS = [1142, 1143, 1370]; // tabla, columna, rutina

    public static function esDenegacion(QueryException $e): bool
    {
        return in_array($e->errorInfo[1] ?? null, self::CODIGOS, true);
    }

    public static function desde(QueryException $e): self
    {
        return new self('No tiene permiso para realizar esta operación.', $e);
    }
}
