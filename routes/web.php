<?php

use App\Http\Controllers\AuditoriaController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\EquipoController;
use App\Http\Controllers\MisProyectosController;
use App\Http\Controllers\ProductoController;
use App\Http\Controllers\ProfileController;
use App\Http\Controllers\ProyectoController;
use App\Http\Controllers\ReporteController;
use App\Models\Proyecto;
use Illuminate\Support\Facades\Route;

Route::redirect('/', '/dashboard');

/*
| Todas las rutas del sistema exigen sesión (auth) y trabajan con la conexión
| MariaDB del rol (conexion.rol). Cada grupo añade su Gate (can:…).
*/
Route::middleware(['auth', 'conexion.rol'])->group(function () {
    Route::get('/dashboard', DashboardController::class)->name('dashboard');

    // Proyectos: lectura (secretaría, coordinador, director, admin)
    Route::middleware('can:ver-proyectos')->group(function () {
        Route::get('/proyectos', [ProyectoController::class, 'index'])->name('proyectos.index');
        Route::get('/proyectos/nuevo', [ProyectoController::class, 'create'])
            ->middleware('can:create,'.Proyecto::class)->name('proyectos.create');
        Route::get('/proyectos/{proyecto}', [ProyectoController::class, 'show'])->name('proyectos.show');
    });

    // Proyectos: escritura (secretaría y admin)
    Route::middleware('can:gestionar-proyectos')->group(function () {
        Route::post('/proyectos', [ProyectoController::class, 'store'])->name('proyectos.store');
        Route::post('/proyectos/{proyecto}/prorroga', [ProyectoController::class, 'prorroga'])->name('proyectos.prorroga');
        Route::post('/proyectos/{proyecto}/cambio-director', [ProyectoController::class, 'cambioDirector'])->name('proyectos.cambio-director');
        Route::post('/proyectos/{proyecto}/relevo', [ProyectoController::class, 'relevo'])->name('proyectos.relevo');
        Route::post('/proyectos/{proyecto}/cierre', [ProyectoController::class, 'registrarCierre'])->name('proyectos.cierre');
        Route::post('/proyectos/{proyecto}/desvincular', [ProyectoController::class, 'desvincular'])->name('proyectos.desvincular');
        Route::post('/proyectos/{proyecto}/equipo', [EquipoController::class, 'store'])->name('proyectos.equipo');

        Route::get('/proyectos/{proyecto}/productos/nuevo', [ProductoController::class, 'create'])->name('productos.create');
        Route::post('/proyectos/{proyecto}/productos', [ProductoController::class, 'store'])->name('productos.store');
        Route::get('/productos/{producto}/reclasificar', [ProductoController::class, 'editTipo'])->name('productos.edit-tipo');
        Route::post('/productos/{producto}/reclasificar', [ProductoController::class, 'reclasificar'])->name('productos.reclasificar');
    });

    Route::middleware('can:ver-reportes')->group(function () {
        Route::get('/reportes', [ReporteController::class, 'index'])->name('reportes.index');
        Route::get('/reportes/{codigo}', [ReporteController::class, 'show'])->name('reportes.show');
    });

    Route::get('/auditoria', AuditoriaController::class)->middleware('can:ver-auditoria')->name('auditoria');
    Route::get('/mis-proyectos', MisProyectosController::class)->middleware('can:ver-mis-proyectos')->name('mis-proyectos');

    Route::get('/profile', [ProfileController::class, 'edit'])->name('profile.edit');
    Route::patch('/profile', [ProfileController::class, 'update'])->name('profile.update');
    Route::delete('/profile', [ProfileController::class, 'destroy'])->name('profile.destroy');
});

require __DIR__.'/auth.php';
