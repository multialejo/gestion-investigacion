-- ============================================================================
-- ADAPTACIONES PARA LA APLICACIÓN LARAVEL (Sail) - gestion_investigacion
-- Se ejecuta DESPUÉS de gestion_investigacion_completo.sql, como root.
-- Reejecutable.
--
--   sail exec -T mariadb mariadb -uroot -p"$DB_PASSWORD" < db/adaptaciones_laravel.sql
--
-- Motivo: la aplicación corre en otro contenedor (laravel.test), por lo que
-- las cuentas '...'@'localhost' del respaldo no le sirven. Se crea:
--   1. Un esquema propio para las tablas internas de Laravel (users, sessions,
--      cache, jobs, migrations) y la cuenta `laravel`, SIN permisos sobre el
--      esquema del negocio (mínimo privilegio).
--   2. Una cuenta de servicio por rol (svc_*@'%') que hereda el rol MariaDB
--      ya diseñado: la aplicación cambia de conexión según el rol del usuario
--      autenticado y los GRANT del motor siguen siendo la última barrera.
--   3. fn_usuario_app() / fn_usuario_auditoria(): permiten que las vistas
--      personales y la auditoría identifiquen a la persona real cuando la
--      conexión es la cuenta de servicio (Laravel fija @app_usuario).
--   4. Permisos mínimos extra para que la secretaría pueda leer catálogos y
--      asignar equipo/líneas (Paso 8: transacción armada por la aplicación).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Esquema y cuenta de Laravel
-- ----------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS `laravel_app`
  DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS 'laravel'@'%' IDENTIFIED BY 'Ueb#Laravel-App26';
-- Sail concede ALL sobre MYSQL_DATABASE al crear el contenedor (con el "_"
-- escapado: `gestion\_investigacion`): se retira. El bloque ignora el error
-- 1141 (no existe el permiso) para que el script sea reejecutable.
DELIMITER $$
BEGIN NOT ATOMIC
    DECLARE CONTINUE HANDLER FOR 1141 BEGIN END;
    REVOKE ALL PRIVILEGES ON `gestion\_investigacion`.* FROM 'laravel'@'%';
    REVOKE ALL PRIVILEGES ON `gestion_investigacion`.*  FROM 'laravel'@'%';
END$$
DELIMITER ;
GRANT ALL PRIVILEGES ON `laravel_app`.* TO 'laravel'@'%';
GRANT ALL PRIVILEGES ON `testing%`.*   TO 'laravel'@'%';

-- ----------------------------------------------------------------------------
-- 2. Cuentas de servicio por rol
-- ----------------------------------------------------------------------------
DROP USER IF EXISTS 'svc_admin'@'%', 'svc_secretaria'@'%', 'svc_coordinador'@'%',
                    'svc_director'@'%', 'svc_profesor'@'%', 'svc_estudiante'@'%';

CREATE USER 'svc_admin'@'%'       IDENTIFIED BY 'Ueb#Svc-Admin26';
CREATE USER 'svc_secretaria'@'%'  IDENTIFIED BY 'Ueb#Svc-Secretaria26';
CREATE USER 'svc_coordinador'@'%' IDENTIFIED BY 'Ueb#Svc-Coordinador26';
CREATE USER 'svc_director'@'%'    IDENTIFIED BY 'Ueb#Svc-Director26';
CREATE USER 'svc_profesor'@'%'    IDENTIFIED BY 'Ueb#Svc-Profesor26';
CREATE USER 'svc_estudiante'@'%'  IDENTIFIED BY 'Ueb#Svc-Estudiante26';

GRANT rol_admin        TO 'svc_admin'@'%';
GRANT rol_secretaria   TO 'svc_secretaria'@'%';
GRANT rol_coordinador  TO 'svc_coordinador'@'%';
GRANT rol_director_inv TO 'svc_director'@'%';
GRANT rol_profesor     TO 'svc_profesor'@'%';
GRANT rol_estudiante   TO 'svc_estudiante'@'%';

SET DEFAULT ROLE rol_admin        FOR 'svc_admin'@'%';
SET DEFAULT ROLE rol_secretaria   FOR 'svc_secretaria'@'%';
SET DEFAULT ROLE rol_coordinador  FOR 'svc_coordinador'@'%';
SET DEFAULT ROLE rol_director_inv FOR 'svc_director'@'%';
SET DEFAULT ROLE rol_profesor     FOR 'svc_profesor'@'%';
SET DEFAULT ROLE rol_estudiante   FOR 'svc_estudiante'@'%';

USE `gestion_investigacion`;

-- ----------------------------------------------------------------------------
-- 3. Identidad de la persona conectada a través de la aplicación
-- ----------------------------------------------------------------------------
DELIMITER $$

DROP FUNCTION IF EXISTS `fn_usuario_app`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_usuario_app` ()
RETURNS VARCHAR(80) CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci
NOT DETERMINISTIC NO SQL
BEGIN
    -- @app_usuario lo fija Laravel (middleware UsarConexionDeRol) en cada petición.
    -- Si no existe, se usa la cuenta MariaDB conectada (acceso directo).
    RETURN COALESCE(@app_usuario, SUBSTRING_INDEX(USER(), '@', 1));
END$$

DROP FUNCTION IF EXISTS `fn_usuario_auditoria`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_usuario_auditoria` ()
RETURNS VARCHAR(100) CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci
NOT DETERMINISTIC NO SQL
BEGIN
    RETURN IF(@app_usuario IS NULL, USER(),
              LEFT(CONCAT(@app_usuario, ' (app: ', USER(), ')'), 100));
END$$

-- Triggers de auditoría: misma lógica que el respaldo, pero registran a la persona
DROP TRIGGER IF EXISTS `trg_auditoria_proyecto_upd`$$
CREATE DEFINER=`root`@`localhost` TRIGGER `trg_auditoria_proyecto_upd` AFTER UPDATE ON `proyecto_investigacion` FOR EACH ROW BEGIN
    INSERT INTO auditoria_proyecto (id_proyecto, operacion, datos_anteriores, datos_nuevos, usuario)
    VALUES (OLD.id_proyecto, 'UPDATE',
            CONCAT('acronimo=', OLD.acronimo, '; presupuesto=', OLD.presupuesto,
                   '; fin_pro=', OLD.fin_pro, '; prorroga=', IFNULL(OLD.prorroga, '-'),
                   '; cierre=', IFNULL(OLD.resolucion_consejo_uni_cierre, '-')),
            CONCAT('acronimo=', NEW.acronimo, '; presupuesto=', NEW.presupuesto,
                   '; fin_pro=', NEW.fin_pro, '; prorroga=', IFNULL(NEW.prorroga, '-'),
                   '; cierre=', IFNULL(NEW.resolucion_consejo_uni_cierre, '-')),
            fn_usuario_auditoria());
END$$

DROP TRIGGER IF EXISTS `trg_auditoria_proyecto_del`$$
CREATE DEFINER=`root`@`localhost` TRIGGER `trg_auditoria_proyecto_del` AFTER DELETE ON `proyecto_investigacion` FOR EACH ROW BEGIN
    INSERT INTO auditoria_proyecto (id_proyecto, operacion, datos_anteriores, datos_nuevos, usuario)
    VALUES (OLD.id_proyecto, 'DELETE',
            CONCAT('nombre=', OLD.nombre_proyecto, '; acronimo=', OLD.acronimo,
                   '; presupuesto=', OLD.presupuesto),
            NULL, fn_usuario_auditoria());
END$$

DROP TRIGGER IF EXISTS `trg_historial_participacion`$$
CREATE DEFINER=`root`@`localhost` TRIGGER `trg_historial_participacion` AFTER UPDATE ON `proyecto_profesor` FOR EACH ROW BEGIN
    IF NOT (OLD.cargo <=> NEW.cargo)
       OR NOT (OLD.resolucion_salida <=> NEW.resolucion_salida) THEN
        INSERT INTO historial_participacion
               (id_proyecto, id_profesor, cargo_anterior, cargo_nuevo,
                resolucion_salida, motivo_salida, usuario)
        VALUES (OLD.id_proyecto, OLD.id_profesor, OLD.cargo, NEW.cargo,
                NEW.resolucion_salida, NEW.motivo_salida, fn_usuario_auditoria());
    END IF;
END$$

DELIMITER ;

-- Vistas personales: idénticas a las del respaldo, filtrando con fn_usuario_app()
-- (una vista no puede leer @variables directamente; una función sí).
CREATE OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_docente_mis_proyectos` AS
SELECT p.acronimo, p.nombre_proyecto, pp.cargo, pp.fecha_inicio, pp.fecha_fin,
       IF(p.id_investigador_principal = pf.id_profesor, 'Sí', 'No') AS investigador_principal,
       p.presupuesto, p.inicio_pro, p.fin_pro
  FROM proyecto_investigacion p
  JOIN proyecto_profesor pp ON pp.id_proyecto = p.id_proyecto
  JOIN profesores pf        ON pf.id_profesor = pp.id_profesor
 WHERE pf.db_usuario = fn_usuario_app();

CREATE OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_docente_mi_equipo` AS
SELECT p.acronimo, pp.cargo, CONCAT(pf.nombres, ' ', pf.apellidos) AS nombre,
       pf.despacho, pf.telefono, pp.fecha_inicio
  FROM proyecto_investigacion p
  JOIN proyecto_profesor pp ON pp.id_proyecto = p.id_proyecto
  JOIN profesores pf        ON pf.id_profesor = pp.id_profesor
 WHERE pp.resolucion_salida IS NULL
   AND p.id_proyecto IN (SELECT pp2.id_proyecto
                           FROM proyecto_profesor pp2
                           JOIN profesores yo ON yo.id_profesor = pp2.id_profesor
                          WHERE yo.db_usuario = fn_usuario_app()
                            AND pp2.resolucion_salida IS NULL);

CREATE OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_docente_mis_publicaciones` AS
SELECT p.acronimo, pr.num_secuencia, pr.titulo_publicacion, t.descripcion_tipo AS tipo,
       l.codigo AS codigo_linea, l.nombre_linea
  FROM escribe e
  JOIN profesores pf            ON pf.id_profesor = e.id_profesor
  JOIN productos pr             ON pr.id_producto = e.id_producto
  JOIN proyecto_investigacion p ON p.id_proyecto  = pr.id_proyecto
  JOIN tipo_pro t               ON t.id_tipo      = pr.id_tipo
  JOIN linea_investigacion l    ON l.id_linea     = e.id_linea
 WHERE pf.db_usuario = fn_usuario_app();

CREATE OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_estudiante_mis_proyectos` AS
SELECT p.acronimo, p.nombre_proyecto, e.nombres_est, f.nombre_facultad AS facultad
  FROM proyecto_investigacion p
  JOIN estudiante e ON e.id_proyecto = p.id_proyecto
  JOIN facultad f   ON f.id_facultad = e.id_facultad
 WHERE e.db_usuario = fn_usuario_app();

-- ----------------------------------------------------------------------------
-- 4. Permisos extra de la secretaría (la escritura de proyectos y productos
--    sigue siendo solo por procedimientos almacenados)
-- ----------------------------------------------------------------------------
GRANT SELECT ON gestion_investigacion.proyecto_investigacion TO rol_secretaria;
GRANT SELECT ON gestion_investigacion.profesores             TO rol_secretaria;
GRANT SELECT ON gestion_investigacion.programa               TO rol_secretaria;
GRANT SELECT ON gestion_investigacion.tipo_pro               TO rol_secretaria;
GRANT SELECT ON gestion_investigacion.productos              TO rol_secretaria;
GRANT SELECT ON gestion_investigacion.linea_investigacion    TO rol_secretaria;
GRANT SELECT ON gestion_investigacion.linea_profesor         TO rol_secretaria;
GRANT SELECT ON gestion_investigacion.resumen_proyecto       TO rol_secretaria;
GRANT SELECT, INSERT ON gestion_investigacion.proyecto_profesor TO rol_secretaria;
GRANT SELECT, INSERT ON gestion_investigacion.proyecto_linea    TO rol_secretaria;

FLUSH PRIVILEGES;
