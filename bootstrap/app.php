<?php

use App\Database\GatewayProcedimientos;
use App\Exceptions\ReglaDeNegocioException;
use App\Http\Middleware\UsarConexionDeRol;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->alias(['conexion.rol' => UsarConexionDeRol::class]);

        // La conexión del rol debe fijarse ANTES de resolver {proyecto} en la
        // ruta (SubstituteBindings), o el modelo se buscaría con la cuenta
        // `laravel`, que no tiene acceso al esquema del negocio.
        $middleware->prependToPriorityList(
            before: \Illuminate\Routing\Middleware\SubstituteBindings::class,
            prepend: UsarConexionDeRol::class,
        );
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->shouldRenderJsonWhen(
            fn (Request $request) => $request->is('api/*') || $request->expectsJson(),
        );

        // Una regla del negocio rechazada es un resultado esperado, no un fallo de la app.
        $exceptions->dontReport(ReglaDeNegocioException::class);

        // Cualquier error de MariaDB que llegue sin capturar se traduce con el
        // mismo Adapter que usan los procedimientos.
        $exceptions->map(QueryException::class, fn (QueryException $e) => GatewayProcedimientos::traducir($e));

        // Una regla del negocio rechazada por un trigger o SP vuelve al
        // formulario con el mensaje de la base de datos y los datos ingresados.
        $exceptions->render(function (ReglaDeNegocioException $e, Request $request) {
            if (! $request->expectsJson()) {
                return back()->withInput()->withErrors(['bd' => $e->getMessage()]);
            }
        });
    })->create();
