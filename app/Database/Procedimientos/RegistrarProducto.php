<?php

namespace App\Database\Procedimientos;

use App\Database\ProcedimientoAlmacenado;
use App\Productos\EstrategiaProducto;

/**
 * sp_registrar_producto_transaccional. El SP recibe parámetros genéricos
 * (p_dato_a..d, p_fecha_1/2) cuyo significado depende del tipo: la estrategia
 * del tipo (patrón Strategy) sabe cómo llenarlos.
 */
class RegistrarProducto extends ProcedimientoAlmacenado
{
    public function __construct(
        private int $idProyecto,
        private EstrategiaProducto $estrategia,
        private array $datos,
    ) {}

    public function nombre(): string
    {
        return 'sp_registrar_producto_transaccional';
    }

    protected function parametros(): array
    {
        return [$this->idProyecto, $this->estrategia->idTipo(), $this->datos['titulo'],
            ...$this->estrategia->parametrosSp($this->datos)];
    }
}
