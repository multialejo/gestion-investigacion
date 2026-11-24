<?php

namespace App\Database;

use Illuminate\Support\Collection;

/**
 * Patrón TEMPLATE METHOD: ejecutarCon() fija el algoritmo
 *   1. validar()            (gancho opcional)
 *   2. llamar al SP          (paso fijo, vía el Adapter)
 *   3. mapearResultado()     (gancho opcional)
 * y cada subclase solo define el nombre del procedimiento y sus parámetros.
 */
abstract class ProcedimientoAlmacenado
{
    /** Nombre del procedimiento en MariaDB. */
    abstract public function nombre(): string;

    /** Parámetros en el mismo orden que la firma del procedimiento. */
    abstract protected function parametros(): array;

    final public function ejecutarCon(GatewayProcedimientos $gateway): mixed
    {
        $this->validar();

        $filas = $gateway->llamar($this->nombre(), $this->parametros());

        return $this->mapearResultado($filas);
    }

    protected function validar(): void
    {
        // Por defecto, la validación la hacen el FormRequest y el propio SP.
    }

    protected function mapearResultado(Collection $filas): mixed
    {
        return $filas;
    }
}
