<?php

namespace App\Database\Procedimientos;

use App\Database\ProcedimientoAlmacenado;

/** sp_desvincular_cierre_transaccional: da de baja a profesores y estudiantes de un proyecto cerrado. */
class DesvincularCierre extends ProcedimientoAlmacenado
{
    public function __construct(private int $idProyecto) {}

    public function nombre(): string
    {
        return 'sp_desvincular_cierre_transaccional';
    }

    protected function parametros(): array
    {
        return [$this->idProyecto];
    }
}
