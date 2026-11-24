<?php

namespace App\Facades;

use App\Database\GatewayProcedimientos;
use Illuminate\Support\Facades\Facade;

/**
 * Patrón FACADE: punto de acceso simple y estático al subsistema de
 * procedimientos almacenados. Procedimientos::ejecutar(new RegistrarProyecto(...)).
 *
 * @method static mixed ejecutar(\App\Database\ProcedimientoAlmacenado $procedimiento)
 * @method static \Illuminate\Support\Collection llamar(string $nombre, array $parametros = [])
 *
 * @see GatewayProcedimientos
 */
class Procedimientos extends Facade
{
    protected static function getFacadeAccessor(): string
    {
        return GatewayProcedimientos::class;
    }
}
