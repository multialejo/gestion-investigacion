<?php

namespace App\Database\Procedimientos;

use App\Database\ProcedimientoAlmacenado;

/** sp_registrar_proyecto_transaccional: crea proyecto + participación del IP + resumen (una transacción). */
class RegistrarProyecto extends ProcedimientoAlmacenado
{
    public function __construct(private array $datos) {}

    public function nombre(): string
    {
        return 'sp_registrar_proyecto_transaccional';
    }

    protected function parametros(): array
    {
        $d = $this->datos;

        return [$d['nombre_proyecto'], $d['acronimo'], $d['presupuesto'], $d['programa'],
            $d['descripcion'] ?? null, $d['inicio_pro'], $d['fin_pro'], $d['resolucion'],
            $d['id_investigador_principal']];
    }
}
