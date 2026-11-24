<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Enlaza cada usuario de la aplicación con:
 *  - rol: decide la conexión MariaDB (svc_<rol>) y los Gates de Laravel.
 *  - db_usuario: identifica a la persona en el negocio
 *    (profesores.db_usuario / estudiante.db_usuario) y se envía como @app_usuario.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->enum('rol', ['admin', 'secretaria', 'coordinador', 'director', 'profesor', 'estudiante'])
                ->default('estudiante')->after('email');
            $table->string('db_usuario', 80)->nullable()->unique()->after('rol');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['rol', 'db_usuario']);
        });
    }
};
