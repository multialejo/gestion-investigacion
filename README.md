# Sistema de Gestión de Proyectos de Investigación

Aplicación web en **Laravel 13 + Sail** (PHP 8.5, MariaDB 11.8) sobre la base de datos
`gestion_investigacion` (caso «Proyectos de investigación», Cuadra 2010, Problema 1.4 + extensiones UEB).

La lógica de negocio vive en la base de datos (procedimientos almacenados transaccionales,
triggers, vistas, roles). Laravel aporta la capa web, la autenticación y la autorización, y una capa
de acceso a los procedimientos construida con patrones GoF.

## Requisitos

Solo **Docker** (no hace falta PHP ni Composer en el equipo).

## Puesta en marcha

```bash
# 1. dependencias (una vez)
docker run --rm -u "$(id -u):$(id -g)" -v "$PWD":/app -w /app laravelsail/php84-composer:latest composer install
cp .env.example .env        # completar DB_PASSWORD y DB_<ROL>_PASSWORD (ver ../db/adaptaciones_laravel.sql)

# 2. contenedores
./vendor/bin/sail up -d
./vendor/bin/sail artisan key:generate

# 3. base de datos del negocio (respaldo + adaptaciones para Laravel)
../db/recargar.sh

# 4. tablas de Laravel y usuarios
./vendor/bin/sail artisan migrate --seed
./vendor/bin/sail npm install && ./vendor/bin/sail npm run build
```

Abrir <http://localhost>.

## Usuarios de prueba

| Rol | Correo | Contraseña |
|---|---|---|
| Administrador | patricio.lara@ueb.edu.ec | `Ueb#Lara-Adm26` |
| Secretaría | monica.cardenas@ueb.edu.ec | `Ueb#Cardenas-Sec26` |
| Coordinador | santiago.borja@ueb.edu.ec | `Ueb#Borja-Coo26` |
| Director de investigación | elena.mosquera@ueb.edu.ec | `Ueb#Mosquera-Dir26` |
| Profesor (13) | p. ej. carlos.villacres@ueb.edu.ec | `Ueb#Villacres-Doc26` (`Ueb#<Apellido>-Doc26`) |
| Estudiante (7) | p. ej. andony.cortez@ueb.edu.ec | `Ueb#Cortez-Est26` (`Ueb#<Apellido>-Est26`) |

## Arquitectura

MVC en capas: Blade → rutas/middleware → controladores → servicios de dominio y gateway de
procedimientos / Eloquent → MariaDB (SP, triggers, vistas, roles).

Seguridad en **doble capa**:
1. Breeze (login, sesión, CSRF, throttle, bcrypt) + Gates + `ProyectoPolicy` + middleware `can:`.
2. El middleware `UsarConexionDeRol` cambia, en cada petición, a la cuenta de servicio MariaDB del rol
   (`svc_secretaria` → `rol_secretaria`, …) y fija `@app_usuario`. Los GRANT del motor siguen
   protegiendo los datos aunque falle la capa de Laravel.

Patrones GoF: Adapter (`GatewayProcedimientos`), Template Method (`ProcedimientoAlmacenado`),
Facade (`Procedimientos`), Singleton (contenedor), Strategy + Factory Method (`app/Productos`),
Observer (`ParticipacionObserver`), Chain of Responsibility (middleware).

## Pruebas

```bash
../db/recargar.sh && ./vendor/bin/sail artisan test
```

67 pruebas (Pest): seguridad en las dos capas, procedimientos, triggers y transacciones.
