<?php

namespace App\Database;

use App\Exceptions\AccesoDenegadoBdException;
use App\Exceptions\ReglaDeNegocioException;
use Illuminate\Database\QueryException;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

/**
 * Patrón ADAPTER: adapta la interfaz de los procedimientos almacenados de
 * MariaDB (sentencia CALL, parámetros posicionales, errores SQLSTATE) a la
 * interfaz que espera la aplicación (métodos PHP, colecciones y excepciones
 * del dominio).
 *
 * Se registra como singleton en el contenedor de servicios y se expone con la
 * fachada App\Facades\Procedimientos (patrón FACADE).
 */
class GatewayProcedimientos
{
    /** Ejecuta un objeto procedimiento (ver ProcedimientoAlmacenado). */
    public function ejecutar(ProcedimientoAlmacenado $procedimiento): mixed
    {
        return $procedimiento->ejecutarCon($this);
    }

    /**
     * CALL nombre(?, ?, …) con parámetros enlazados (sin concatenar valores:
     * evita inyección SQL). Usa la conexión por defecto, que el middleware
     * UsarConexionDeRol fijó según el rol del usuario.
     */
    public function llamar(string $nombre, array $parametros = []): Collection
    {
        $marcadores = implode(', ', array_fill(0, count($parametros), '?'));

        try {
            return collect(DB::select("CALL {$nombre}({$marcadores})", array_values($parametros)));
        } catch (QueryException $e) {
            throw self::traducir($e);
        }
    }

    /** Convierte errores de MariaDB en excepciones del dominio. */
    public static function traducir(QueryException $e): \Throwable
    {
        return match (true) {
            ReglaDeNegocioException::esRegla($e) => ReglaDeNegocioException::desde($e),
            AccesoDenegadoBdException::esDenegacion($e) => AccesoDenegadoBdException::desde($e),
            default => $e,
        };
    }
}
