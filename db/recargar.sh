#!/usr/bin/env bash
# Recarga desde cero el esquema del negocio en el contenedor de Sail:
#   1. DROP DATABASE gestion_investigacion (así se crea con utf8mb4_unicode_ci,
#      la intercalación con la que se diseñaron tablas y rutinas)
#   2. respaldo completo (estructura, datos, SP, triggers, vistas, roles, cuentas)
#   3. adaptaciones para Laravel (cuentas svc_*, vistas y auditoría con @app_usuario)
# Uso: db/recargar.sh            (desde la raíz del proyecto)
set -euo pipefail
DIR="$(dirname "$(readlink -f "$0")")"
APP="$DIR/.."
CLAVE="$(grep -E '^DB_PASSWORD=' "$APP/.env" | cut -d= -f2- | tr -d '"')"
db() { (cd "$APP" && docker compose exec -T mariadb mariadb -uroot -p"$CLAVE" "$@" 2>/dev/null); }

db -e 'DROP DATABASE IF EXISTS gestion_investigacion'
db < "$DIR/gestion_investigacion_completo.sql"
db < "$DIR/adaptaciones_laravel.sql"
db -N -e "SELECT CONCAT('gestion_investigacion recargada · intercalación: ', default_collation_name,
                        ' · tablas: ', (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='gestion_investigacion'),
                        ' · rutinas: ', (SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema='gestion_investigacion'),
                        ' · triggers: ', (SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_schema='gestion_investigacion'))
          FROM information_schema.schemata WHERE schema_name='gestion_investigacion'"
