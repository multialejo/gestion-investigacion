<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

/**
 * PROYECTO DE INVESTIGACIÓN (tabla existente proyecto_investigacion).
 * Sin $connection: usa la conexión por defecto, que el middleware fija según el
 * rol (svc_secretaria, svc_coordinador, …). La escritura se hace por SP;
 * Eloquent se usa para leer y para la resolución de cierre (rol admin).
 */
class Proyecto extends Model
{
    protected $table = 'proyecto_investigacion';

    protected $primaryKey = 'id_proyecto';

    public $timestamps = false;

    protected $fillable = ['resolucion_consejo_uni_cierre'];

    protected function casts(): array
    {
        return [
            'inicio_pro' => 'date',
            'fin_pro' => 'date',
            'prorroga' => 'date',
            'presupuesto' => 'decimal:2',
        ];
    }

    public function investigadorPrincipal(): BelongsTo
    {
        return $this->belongsTo(Profesor::class, 'id_investigador_principal', 'id_profesor');
    }

    public function programa(): BelongsTo
    {
        return $this->belongsTo(Programa::class, 'id_programa', 'id_programa');
    }

    public function participaciones(): HasMany
    {
        return $this->hasMany(Participacion::class, 'id_proyecto', 'id_proyecto');
    }

    public function productos(): HasMany
    {
        return $this->hasMany(Producto::class, 'id_proyecto', 'id_proyecto');
    }

    public function lineas(): BelongsToMany
    {
        return $this->belongsToMany(LineaInvestigacion::class, 'proyecto_linea', 'id_proyecto', 'id_linea');
    }

    public function resumen(): HasOne
    {
        return $this->hasOne(ResumenProyecto::class, 'id_proyecto', 'id_proyecto');
    }

    public function estaCerrado(): bool
    {
        return $this->resolucion_consejo_uni_cierre !== null;
    }

    public function finVigente()
    {
        return $this->prorroga ?? $this->fin_pro;
    }
}
