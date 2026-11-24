<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpFoundation\Response;

/**
 * Segunda capa de seguridad: cada petición autenticada trabaja con la cuenta de
 * servicio MariaDB de su rol (svc_<rol>), por lo que los GRANT de rol_<rol>
 * limitan lo que puede hacer aunque fallara la autorización de Laravel.
 *
 * Además fija @app_usuario para que las vistas personales (vw_docente_*,
 * vw_estudiante_*) y los triggers de auditoría identifiquen a la persona real.
 *
 * Forma parte de la cadena de middleware de Laravel (patrón Chain of Responsibility).
 */
class UsarConexionDeRol
{
    public function handle(Request $request, Closure $next): Response
    {
        $usuario = $request->user();

        if ($usuario) {
            DB::setDefaultConnection($usuario->conexionDeRol());
            DB::statement('SET @app_usuario = ?', [$usuario->db_usuario]);
        }

        return $next($request);
    }
}
