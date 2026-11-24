<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Profesor extends Model
{
    protected $table = 'profesores';

    protected $primaryKey = 'id_profesor';

    public $timestamps = false;

    public function getNombreCompletoAttribute(): string
    {
        return "{$this->nombres} {$this->apellidos}";
    }

    public function participaciones(): HasMany
    {
        return $this->hasMany(Participacion::class, 'id_profesor', 'id_profesor');
    }

    public function lineas(): BelongsToMany
    {
        return $this->belongsToMany(LineaInvestigacion::class, 'linea_profesor', 'id_profesor', 'id_linea');
    }

    /** Ámbito local: solo doctores (pueden ser investigador principal). */
    public function scopeDoctores(Builder $q): Builder
    {
        return $q->where('tipo', 'doctor');
    }
}
