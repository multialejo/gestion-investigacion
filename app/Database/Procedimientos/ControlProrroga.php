<?php

namespace App\Database\Procedimientos;

use App\Database\ProcedimientoAlmacenado;

/** sp_control_prorroga_transaccional: máximo una prórroga de hasta 3 meses. */
class ControlProrroga extends ProcedimientoAlmacenado
{
    public function __construct(private int $idProyecto, private string $nuevaFechaFin) {}

    public function nombre(): string
    {
        return 'sp_control_prorroga_transaccional';
    }

    protected function parametros(): array
    {
        return [$this->idProyecto, $this->nuevaFechaFin];
    }
}
