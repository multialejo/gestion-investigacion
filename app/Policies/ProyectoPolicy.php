<?php

namespace App\Policies;

use App\Models\Proyecto;
use App\Models\User;

/**
 * Autorización por recurso: qué puede hacer cada rol sobre un proyecto concreto
 * (además del rol, se considera el estado del proyecto).
 */
class ProyectoPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->tieneRol('admin', 'secretaria', 'coordinador', 'director');
    }

    public function view(User $user, Proyecto $proyecto): bool
    {
        return $this->viewAny($user);
    }

    public function create(User $user): bool
    {
        return $user->tieneRol('admin', 'secretaria');
    }

    /** Prórroga, cambio de director, equipo y productos: solo proyectos abiertos. */
    public function modificar(User $user, Proyecto $proyecto): bool
    {
        return $user->tieneRol('admin', 'secretaria') && ! $proyecto->estaCerrado();
    }

    /** Registrar la resolución de cierre del Consejo Universitario. */
    public function registrarCierre(User $user, Proyecto $proyecto): bool
    {
        return $user->tieneRol('admin') && ! $proyecto->estaCerrado();
    }

    /** Desvincular al personal: solo cuando el proyecto ya está cerrado. */
    public function desvincular(User $user, Proyecto $proyecto): bool
    {
        return $user->tieneRol('admin', 'secretaria') && $proyecto->estaCerrado();
    }
}
