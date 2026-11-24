<?php

namespace App\Database\Procedimientos;

use App\Database\ProcedimientoAlmacenado;

/** sp_control_responsables_transaccional: el subrogante asciende a director y entra un nuevo subrogante. */
class ControlResponsables extends ProcedimientoAlmacenado
{
    public function __construct(private int $idProyecto, private array $datos) {}

    public function nombre(): string
    {
        return 'sp_control_responsables_transaccional';
    }

    protected function parametros(): array
    {
        $d = $this->datos;

        return [$this->idProyecto, $d['id_saliente'], $d['id_entrante'],
            $d['resolucion_salida'], $d['motivo_salida'], $d['resolucion_ingreso']];
    }
}
