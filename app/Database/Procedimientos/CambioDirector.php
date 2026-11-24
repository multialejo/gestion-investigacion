<?php

namespace App\Database\Procedimientos;

use App\Database\ProcedimientoAlmacenado;

/** sp_cambio_director_transaccional: cierra la participación del director y registra al nuevo. */
class CambioDirector extends ProcedimientoAlmacenado
{
    public function __construct(private int $idProyecto, private array $datos) {}

    public function nombre(): string
    {
        return 'sp_cambio_director_transaccional';
    }

    protected function parametros(): array
    {
        $d = $this->datos;

        return [$this->idProyecto, $d['id_saliente'], $d['id_entrante'],
            $d['resolucion_salida'], $d['motivo_salida'], $d['resolucion_ingreso']];
    }
}
