<?php

namespace App\Providers;

use App\Database\GatewayProcedimientos;
use App\Models\User;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        // Patrón SINGLETON gestionado por el contenedor: una sola instancia del
        // gateway por petición, inyectable o accesible con la fachada.
        $this->app->singleton(GatewayProcedimientos::class);
    }

    public function boot(): void
    {
        // Gates: permisos por rol para las secciones de la aplicación.
        Gate::define('ver-proyectos', fn (User $u) => $u->tieneRol('admin', 'secretaria', 'coordinador', 'director'));
        Gate::define('gestionar-proyectos', fn (User $u) => $u->tieneRol('admin', 'secretaria'));
        Gate::define('ver-reportes', fn (User $u) => $u->tieneRol('admin', 'coordinador', 'director'));
        Gate::define('ver-auditoria', fn (User $u) => $u->tieneRol('admin', 'director'));
        Gate::define('ver-mis-proyectos', fn (User $u) => $u->tieneRol('profesor', 'estudiante'));
    }
}
