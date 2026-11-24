<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

/**
 * Crea los usuarios de la aplicación a partir de las personas que ya existen en
 * gestion_investigacion (mismas cuentas y contraseñas documentadas en el respaldo).
 */
class UserSeeder extends Seeder
{
    public function run(): void
    {
        $personal = [
            ['Patricio Lara',   'patricio.lara',   'admin',       'Ueb#Lara-Adm26'],
            ['Mónica Cárdenas', 'monica.cardenas', 'secretaria',  'Ueb#Cardenas-Sec26'],
            ['Santiago Borja',  'santiago.borja',  'coordinador', 'Ueb#Borja-Coo26'],
            ['Elena Mosquera',  'elena.mosquera',  'director',    'Ueb#Mosquera-Dir26'],
        ];

        foreach ($personal as [$nombre, $cuenta, $rol, $clave]) {
            $this->crear($nombre, $cuenta, $rol, $clave);
        }

        // Se leen con la conexión del administrador (svc_admin → rol_admin).
        $negocio = DB::connection('rol_admin');

        foreach ($negocio->table('profesores')->whereNotNull('db_usuario')->get() as $p) {
            $this->crear("{$p->nombres} {$p->apellidos}", $p->db_usuario, 'profesor',
                'Ueb#'.$this->apellido($p->db_usuario).'-Doc26');
        }

        foreach ($negocio->table('estudiante')->whereNotNull('db_usuario')->get() as $e) {
            $this->crear($e->nombres_est, $e->db_usuario, 'estudiante',
                'Ueb#'.$this->apellido($e->db_usuario).'-Est26');
        }
    }

    private function crear(string $nombre, string $cuenta, string $rol, string $clave): void
    {
        User::updateOrCreate(
            ['db_usuario' => $cuenta],
            [
                'name' => $nombre,
                'email' => "{$cuenta}@ueb.edu.ec",
                'rol' => $rol,
                'password' => $clave,          // el cast "hashed" aplica bcrypt
                'email_verified_at' => now(),
            ],
        );
    }

    /** carlos.villacres → Villacres (convención de las contraseñas del respaldo). */
    private function apellido(string $cuenta): string
    {
        return Str::ucfirst(Str::after($cuenta, '.'));
    }
}
