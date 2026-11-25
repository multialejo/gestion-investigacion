# CLAUDE.md

Research project management system: a Laravel 13 web app (PHP 8.5, MariaDB, Blade, Breeze, Pest) on top of the `gestion_investigacion` database. See `README.md` for first-time setup and test accounts.

The UI, code comments, identifiers, test names and commit messages are in Spanish. Keep new ones in Spanish.

## Commands

Everything runs in Docker through Sail. The host doesn't need PHP or Composer, so don't install them.

```bash
./vendor/bin/sail up -d                  # app: http://localhost · phpMyAdmin: http://localhost:8080
./vendor/bin/sail stop
./vendor/bin/sail artisan <command>
./vendor/bin/sail composer <command>
./vendor/bin/sail npm run dev            # or: npm run build
./vendor/bin/sail pint --dirty           # format changed PHP files

db/recargar.sh                           # DROPS and rebuilds gestion_investigacion
./vendor/bin/sail artisan test
./vendor/bin/sail artisan test tests/Feature/TriggersTest.php
./vendor/bin/sail artisan test --filter="part of the test name"
```

## Architecture

**Business logic lives in the database**: stored procedures, triggers, views, roles and grants. Laravel provides the web layer, authentication, authorization and access to the procedures. Don't reimplement a business rule in PHP. FormRequests and controller validation check format and required fields, and the database enforces the rules.

### Two schemas

| Schema | Contents | Accessed through | Managed by |
|---|---|---|---|
| `laravel_app` | users, sessions, cache, jobs | `mariadb` connection (`laravel` account) | Laravel migrations and seeders |
| `gestion_investigacion` | business data and logic | `rol_<rol>` connections (`svc_<rol>` accounts) | SQL scripts in `db/` |

- The `laravel` account has no access to the business schema. `User` pins `$connection = 'mariadb'`.
- Business models don't set `$connection`. They use the default one, which changes with each request.
- Don't write migrations for business tables. `db/gestion_investigacion_completo.sql` is the original dump. `db/adaptaciones_laravel.sql` runs after it, is re-runnable, and holds the app-specific changes (service accounts, grants, overridden views, functions and triggers). Put app-driven changes there, then run `db/recargar.sh`.

### Two layers of authorization

1. **Laravel:** gates in `app/Providers/AppServiceProvider.php`, `can:` middleware in `routes/web.php`, and `app/Policies/ProyectoPolicy.php`, which also depends on whether a project is closed.
2. **MariaDB:** the `UsarConexionDeRol` middleware (alias `conexion.rol`) sets the default connection from `users.rol` and sets `@app_usuario` to `users.db_usuario`.

When adding or changing a feature, check both layers. A new table, view or procedure also needs a `GRANT` for each role that uses it.

- The roles are `admin`, `secretaria`, `coordinador`, `director`, `profesor` and `estudiante`. The MariaDB role for `director` is `rol_director_inv`.
- `bootstrap/app.php` places `UsarConexionDeRol` before `SubstituteBindings`. Otherwise route model binding would query with the `laravel` account and fail. Routes that touch business data belong in the `['auth', 'conexion.rol']` group.
- Personal views (`vw_docente_*`, `vw_estudiante_*`) filter rows with `fn_usuario_app()`, which reads `@app_usuario`. Audit triggers use `fn_usuario_auditoria()`. Don't add a user filter in PHP.
- Public registration is disabled. `UserSeeder` creates users from people already in the business schema.

### Writes and transactions

- Most writes go through stored procedures: `Procedimientos::ejecutar(new SomeProcedure(...))`. To add one, extend `ProcedimientoAlmacenado` in `app/Database/Procedimientos/` and define `nombre()` and `parametros()`. The parameter order must match the SQL signature.
- The exceptions that use Eloquent or the query builder are project closure (`ProyectoController::registrarCierre`, admin only) and the batch of team members and research lines (`EquipoController`, inside `DB::transaction()`).
- **Never call a `sp_*_transaccional` procedure inside `DB::transaction()`.** Its internal `START TRANSACTION` commits the outer transaction, so Laravel can't roll it back. `tests/Feature/TransaccionesTest.php` demonstrates this.
- `ParticipacionObserver` runs only after commit and writes to the `auditoria` log channel (`storage/logs/auditoria.log`).

### Database errors

`GatewayProcedimientos::traducir()` converts MariaDB errors, and `bootstrap/app.php` applies it to every uncaught `QueryException`:

- Business rule errors (`SIGNAL` 45000, `CHECK`, unique and foreign key) become `ReglaDeNegocioException`. The user returns to the form with the database message under the `bd` error key. These errors aren't reported to the log.
- Permission errors become `AccesoDenegadoBdException` (HTTP 403).

Let these exceptions propagate. Controllers don't need to catch them.

### Other conventions

- **Product types** (journal, conference, book, patent): each has a strategy in `app/Productos/` that defines its form fields, validation rules and generic procedure parameters. Add or change types through the strategy and `FabricaEstrategiaProducto`, whose IDs match the `tipo_pro` table. Don't branch on type in controllers.
- **Reports:** `Reporte::CATALOGO` is the allowlist of report procedures. A procedure name must never come from user input.
- **Labels:** readable column headings and values for the `<x-tabla>` component go in `config/etiquetas.php`.
- **Design patterns:** the GoF patterns named in class docblocks and `README.md` are intentional. Keep them when refactoring.
- **Frontend:** Tailwind 3 through PostCSS (`tailwind.config.js`) and Alpine.js, built with Vite. `@tailwindcss/vite` (v4) is listed in `package.json`, but `vite.config.js` doesn't use it. Don't write Tailwind 4 syntax.

## Testing

- Run `db/recargar.sh` before the tests. This erases any local changes to the business data.
- `RefreshDatabase` resets only the `testing` schema (Laravel tables). Tests use the real `gestion_investigacion` database, including its procedures, triggers and grants, and writes to it persist. Run `db/recargar.sh` afterwards if you need the original data back.
- Use the helpers in `tests/Pest.php` (`usuarioCon`, `negocio`, `datosProyecto`, `proyectoDePrueba`, `limpiarProyectosDePrueba`). Test projects need an acronym starting with `PT` so cleanup can find them.

## Local environment

- `.env.example` leaves the database passwords empty. The `DB_<ROL>_PASSWORD` values must match the `svc_*` accounts in `db/adaptaciones_laravel.sql`. Quote them, because they contain `#`.
- `.env.example` sets `APP_URL` to port 8000, but Sail serves on port 80 unless `APP_PORT` is set. Use `http://localhost`.
