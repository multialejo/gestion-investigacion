<?php

namespace App\Models;

use App\Observers\ParticipacionObserver;
use Illuminate\Database\Eloquent\Attributes\ObservedBy;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Interrelación PARTICIPA (tabla proyecto_profesor, PK compuesta
 * id_proyecto + id_profesor + fecha_inicio). Al insertarse se dispara
 * trg_validar_participacion (solapamiento SS1, máximo de investigadores, …).
 */
#[ObservedBy(ParticipacionObserver::class)]
class Participacion extends Model
{
    protected $table = 'proyecto_profesor';

    protected $primaryKey = 'id_proyecto';

    public $incrementing = false;

    public $timestamps = false;

    protected $fillable = ['id_proyecto', 'id_profesor', 'fecha_inicio', 'cargo', 'resolucion_ingreso'];

    protected function casts(): array
    {
        return ['fecha_inicio' => 'date', 'fecha_fin' => 'date'];
    }

    public function profesor(): BelongsTo
    {
        return $this->belongsTo(Profesor::class, 'id_profesor', 'id_profesor');
    }

    public function proyecto(): BelongsTo
    {
        return $this->belongsTo(Proyecto::class, 'id_proyecto', 'id_proyecto');
    }

    public function estaActiva(): bool
    {
        return $this->resolucion_salida === null;
    }
}
