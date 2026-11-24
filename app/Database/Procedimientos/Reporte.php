<?php

namespace App\Database\Procedimientos;

use App\Database\ProcedimientoAlmacenado;
use InvalidArgumentException;

/**
 * Reportes sp_ca1..5 (consultas avanzadas) y sp_cm1..5 (consultas multitabla).
 * Solo se aceptan los procedimientos de la lista blanca: el nombre nunca
 * proviene directamente del usuario.
 */
class Reporte extends ProcedimientoAlmacenado
{
    public const CATALOGO = [
        'ca1' => ['sp_ca1_productividad_proyectos', 'Productividad por proyecto', []],
        'ca2' => ['sp_ca2_proyectos_sobre_promedio', 'Proyectos con productividad sobre el promedio', []],
        'ca3' => ['sp_ca3_ultimo_producto_proyecto', 'Último producto de cada proyecto', []],
        'ca4' => ['sp_ca4_valoracion_revistas', 'Valoración de publicaciones en revistas', []],
        'ca5' => ['sp_ca5_estado_proyectos', 'Estado de los proyectos (aviso de vencimiento)', ['dias_aviso' => 'Días de aviso']],
        'cm1' => ['sp_cm1_equipo_proyecto', 'Equipo de un proyecto', ['id_proyecto' => 'Proyecto']],
        'cm2' => ['sp_cm2_carga_profesores', 'Carga de los profesores', []],
        'cm3' => ['sp_cm3_estudiantes_por_proyecto', 'Estudiantes por proyecto', []],
        'cm4' => ['sp_cm4_cobertura_lineas', 'Cobertura de líneas de investigación', []],
        'cm5' => ['sp_cm5_catalogo_productos', 'Catálogo de productos', []],
    ];

    public function __construct(private string $codigo, private array $argumentos = [])
    {
        if (! isset(self::CATALOGO[$codigo])) {
            throw new InvalidArgumentException("Reporte desconocido: {$codigo}");
        }
    }

    public function nombre(): string
    {
        return self::CATALOGO[$this->codigo][0];
    }

    protected function parametros(): array
    {
        return array_map(fn ($clave) => $this->argumentos[$clave] ?? null,
            array_keys(self::CATALOGO[$this->codigo][2]));
    }
}
