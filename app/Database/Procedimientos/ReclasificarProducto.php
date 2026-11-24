<?php

namespace App\Database\Procedimientos;

use App\Database\ProcedimientoAlmacenado;
use App\Productos\EstrategiaProducto;

/** sp_reclasificar_producto_transaccional: cambia el subtipo de un producto en una transacción. */
class ReclasificarProducto extends ProcedimientoAlmacenado
{
    public function __construct(
        private int $idProducto,
        private EstrategiaProducto $estrategia,
        private array $datos,
    ) {}

    public function nombre(): string
    {
        return 'sp_reclasificar_producto_transaccional';
    }

    protected function parametros(): array
    {
        return [$this->idProducto, $this->estrategia->idTipo(),
            ...$this->estrategia->parametrosSp($this->datos)];
    }
}
