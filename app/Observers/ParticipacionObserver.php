<?php

namespace App\Observers;

use App\Models\Participacion;
use Illuminate\Contracts\Events\ShouldHandleEventsAfterCommit;
use Illuminate\Support\Facades\Log;

/**
 * Patrón OBSERVER: Eloquent notifica la creación de participaciones.
 * ShouldHandleEventsAfterCommit hace que el observador solo reaccione si la
 * transacción de la aplicación se confirma (COMMIT); si un trigger rechaza una
 * fila y Laravel hace ROLLBACK, no se registra nada.
 */
class ParticipacionObserver implements ShouldHandleEventsAfterCommit
{
    public function created(Participacion $p): void
    {
        Log::channel('auditoria')->info('Participación registrada', [
            'usuario' => auth()->user()?->db_usuario,
            'id_proyecto' => $p->id_proyecto,
            'id_profesor' => $p->id_profesor,
            'cargo' => $p->cargo,
            'fecha_inicio' => (string) $p->fecha_inicio?->toDateString(),
        ]);
    }
}
