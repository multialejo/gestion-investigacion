-- ============================================================================
-- RESPALDO COMPLETO: gestion_investigacion
-- Generado: 2026-11-24 · Servidor objetivo: MariaDB 11.8
-- Contenido:
--   Parte A: base de datos (estructura, datos, funciones, procedimientos,
--            triggers y vistas)  -> origen: gestion_investigacion.sql
--   Parte B: roles, cuentas y permisos -> origen: usuarios.sql
-- Restauración (como root):
--   mariadb -u root -p < gestion_investigacion_completo.sql
-- El script es reejecutable: elimina y recrea los objetos y las cuentas.
-- ============================================================================

-- DROP DATABASE IF EXISTS `gestion_investigacion`;
CREATE DATABASE IF NOT EXISTS `gestion_investigacion`
  DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `gestion_investigacion`;

-- ############################################################################
-- PARTE A: BASE DE DATOS
-- ############################################################################
-- ============================================================================
-- BASE DE DATOS: gestion_investigacion
-- Caso de estudio: "Problema 1.4: Proyectos de investigación" + extensiones UEB
-- Servidor objetivo: MariaDB 11.8
-- Fecha de revisión: 2026-11-24
-- ----------------------------------------------------------------------------
-- Trazabilidad de los supuestos semánticos (SS) del caso:
--   SS1  Sin solapamiento de periodos de participación    -> trg_validar_participacion / trg_participacion_bu
--   SS2  Inicio de participación <= fin                    -> CHECK chk_pp_fechas
--   SS3  Varias épocas por profesor y proyecto             -> PK proyecto_profesor(id_proyecto,id_profesor,fecha_inicio)
--                                                             + UNIQUE (id_proyecto,id_profesor,fecha_fin)
--   SS4  Un no doctor no tiene 2 supervisores a la vez     -> trg_supervision_bi / trg_supervision_bu
--   SS5  Inicio de supervisión implica un único fin        -> PK supervision(id_no_doctor,fecha_inicio) + UNIQUE
--   SS6  Inicio de supervisión < fin                       -> CHECK chk_supervision_fechas
--   SS7  El investigador principal participa en el proyecto-> sp_registrar_proyecto_transaccional
--   SS8  Solo se escribe sobre líneas que se desarrollan   -> trg_escribe_bi / trg_escribe_bu
--   SS9  Solo escriben profesores del proyecto             -> trg_escribe_bi / trg_escribe_bu
--   SS10 El proyecto solo incluye líneas de sus profesores -> trg_proyecto_linea_bi
--   SS11 Las líneas de una publicación están en Incluye    -> trg_escribe_bi / trg_escribe_bu
--   SS12 Página inicio <= página fin                       -> CHECK chk_revista_paginas
--   SS13 Inicio de congreso <= fin                         -> CHECK chk_congreso_fechas
--   SS14 Inicio de proyecto <= fin                         -> CHECK chk_proyecto_fechas
--   SS15 Congreso no anterior al inicio del proyecto       -> trg_congreso_bi / trg_congreso_bu
--   SS16 Tipo de publicación {congreso, revista}           -> tipo_pro (+ Libro y Patente como extensión UEB)
--   SS17 Tipo de congreso {nacional, internacional}        -> ENUM publicacion_congreso.tipo_congreso
--   SS18 Tipo de profesor {doctor, no_doctor}              -> ENUM profesores.tipo (jerarquía exclusiva y total)
--   Investigador principal: siempre doctor y nunca varía  -> trg_proyecto_bi / trg_proyecto_bu
--
-- Desviaciones documentadas respecto al caso:
--   * Extensiones UEB conservadas: estudiantes, resoluciones del Consejo
--     Universitario, prórroga y cierre, cargos Director / Director subrogante /
--     Investigador (rol administrativo que sí puede cambiar, distinto del
--     investigador principal), libros y patentes, auditoría y resúmenes.
--   * Participación: el fin puede ser igual al inicio (altas y bajas por
--     resolución el mismo día); la supervisión mantiene inicio < fin estricto.
--   * Los identificadores son sustitutos (id_*); los identificadores del caso
--     se conservan como claves únicas (nombre del proyecto, nombre y
--     apellidos del profesor, código de la línea).
--   * Normalización: los valores que se repetían como texto libre pasan a
--     catálogos con clave foránea:
--       facultad  <- profesores / estudiante.departamento_facultad
--       programa  <- proyecto_investigacion.programa
--       pais      <- publicacion_congreso.pais, patentes.pais_registro
--       editorial <- publicacion_revista / libro.editorial,
--                    publicacion_congreso.editorial_actas
--     Los subtipos de producto ya no copian id_tipo; los triggers
--     trg_revista_bi / trg_congreso_bi / trg_libro_bi / trg_patente_bi
--     comprueban que coincida con productos.id_tipo. Los procedimientos
--     siguen recibiendo nombres y crean la fila de catálogo si no existe.
-- ============================================================================

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION";
START TRANSACTION;
SET time_zone = "+00:00";

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------------------------------------------------------
-- Limpieza previa (permite volver a cargar el script)
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS `vw_docente_mis_proyectos`, `vw_docente_mi_equipo`,
                    `vw_docente_mis_publicaciones`, `vw_estudiante_mis_proyectos`;

DROP TABLE IF EXISTS `escribe`, `linea_descriptor`, `linea_profesor`, `proyecto_linea`,
                     `linea_investigacion`, `publicacion_revista`, `publicacion_congreso`,
                     `libro`, `patentes`, `productos`, `tipo_pro`, `resumen_proyecto`,
                     `estudiante`, `historial_participacion`, `proyecto_profesor`,
                     `supervision`, `auditoria_proyecto`, `auditoria_operaciones`,
                     `proyecto_investigacion`, `profesores`,
                     `facultad`, `programa`, `pais`, `editorial`;

DROP PROCEDURE IF EXISTS `sp_ca1_productividad_proyectos`;
DROP PROCEDURE IF EXISTS `sp_ca2_proyectos_sobre_promedio`;
DROP PROCEDURE IF EXISTS `sp_ca3_ultimo_producto_proyecto`;
DROP PROCEDURE IF EXISTS `sp_ca4_valoracion_revistas`;
DROP PROCEDURE IF EXISTS `sp_ca5_estado_proyectos`;
DROP PROCEDURE IF EXISTS `sp_cm1_equipo_proyecto`;
DROP PROCEDURE IF EXISTS `sp_cm2_carga_profesores`;
DROP PROCEDURE IF EXISTS `sp_cm3_estudiantes_por_proyecto`;
DROP PROCEDURE IF EXISTS `sp_cm4_cobertura_lineas`;
DROP PROCEDURE IF EXISTS `sp_cm5_catalogo_productos`;
DROP PROCEDURE IF EXISTS `sp_cambio_director_transaccional`;
DROP PROCEDURE IF EXISTS `sp_control_prorroga_transaccional`;
DROP PROCEDURE IF EXISTS `sp_control_responsables_transaccional`;
DROP PROCEDURE IF EXISTS `sp_desvincular_cierre_transaccional`;
DROP PROCEDURE IF EXISTS `sp_reclasificar_producto_transaccional`;
DROP PROCEDURE IF EXISTS `sp_registrar_producto_transaccional`;
DROP PROCEDURE IF EXISTS `sp_registrar_proyecto_transaccional`;
DROP PROCEDURE IF EXISTS `sp_aux_id_editorial`;
DROP PROCEDURE IF EXISTS `sp_aux_id_pais`;
DROP FUNCTION  IF EXISTS `fn_fin_vigente`;
DROP FUNCTION  IF EXISTS `fn_proyectos_activos`;
DROP FUNCTION  IF EXISTS `fn_puntaje_revista`;
DROP FUNCTION  IF EXISTS `fn_tipo_producto`;

-- ============================================================================
-- ESTRUCTURA DE TABLAS
-- ============================================================================

-- CATÁLOGOS (normalización: valores que antes se repetían como texto libre) ----
CREATE TABLE `facultad` (
  `id_facultad` tinyint(3) UNSIGNED NOT NULL AUTO_INCREMENT,
  `siglas` varchar(10) NOT NULL,
  `nombre_facultad` varchar(150) NOT NULL,
  PRIMARY KEY (`id_facultad`),
  UNIQUE KEY `uq_facultad_siglas` (`siglas`),
  UNIQUE KEY `uq_facultad_nombre` (`nombre_facultad`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `programa` (
  `id_programa` smallint(5) UNSIGNED NOT NULL AUTO_INCREMENT,
  `nombre_programa` varchar(150) NOT NULL COMMENT 'Programa de I+D que financia proyectos',
  PRIMARY KEY (`id_programa`),
  UNIQUE KEY `uq_programa_nombre` (`nombre_programa`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `pais` (
  `id_pais` smallint(5) UNSIGNED NOT NULL AUTO_INCREMENT,
  `nombre_pais` varchar(80) NOT NULL,
  PRIMARY KEY (`id_pais`),
  UNIQUE KEY `uq_pais_nombre` (`nombre_pais`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `editorial` (
  `id_editorial` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `nombre_editorial` varchar(150) NOT NULL,
  PRIMARY KEY (`id_editorial`),
  UNIQUE KEY `uq_editorial_nombre` (`nombre_editorial`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- PARTE 1: PROFESOR (jerarquía DOCTOR / NO_DOCTOR) -----------------------------
CREATE TABLE `profesores` (
  `id_profesor` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `nombres` varchar(80) NOT NULL,
  `apellidos` varchar(80) NOT NULL,
  `despacho` varchar(20) DEFAULT NULL,
  `telefono` varchar(20) DEFAULT NULL,
  `id_facultad` tinyint(3) UNSIGNED NOT NULL,
  `tipo` enum('doctor','no_doctor') NOT NULL COMMENT 'Discriminante de la jerarquía (SS18)',
  `db_usuario` varchar(80) DEFAULT NULL COMMENT 'Cuenta MariaDB del profesor',
  PRIMARY KEY (`id_profesor`),
  UNIQUE KEY `uq_profesor_nombre` (`nombres`,`apellidos`),
  UNIQUE KEY `uq_profesor_usuario` (`db_usuario`),
  KEY `idx_prof_facultad` (`id_facultad`),
  CONSTRAINT `fk_profesor_facultad` FOREIGN KEY (`id_facultad`) REFERENCES `facultad` (`id_facultad`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Interrelación SUPERVISA (DOCTOR 1,N - NO_DOCTOR 0,N) con periodos
CREATE TABLE `supervision` (
  `id_doctor` int(10) UNSIGNED NOT NULL,
  `id_no_doctor` int(10) UNSIGNED NOT NULL,
  `fecha_inicio` date NOT NULL,
  `fecha_fin` date DEFAULT NULL,
  PRIMARY KEY (`id_no_doctor`,`fecha_inicio`),
  UNIQUE KEY `uq_supervision_fin` (`id_doctor`,`id_no_doctor`,`fecha_fin`),
  KEY `idx_sup_doctor` (`id_doctor`),
  CONSTRAINT `chk_supervision_fechas` CHECK (`fecha_fin` IS NULL OR `fecha_fin` > `fecha_inicio`),
  CONSTRAINT `fk_supervision_doctor` FOREIGN KEY (`id_doctor`) REFERENCES `profesores` (`id_profesor`) ON UPDATE CASCADE,
  CONSTRAINT `fk_supervision_no_doctor` FOREIGN KEY (`id_no_doctor`) REFERENCES `profesores` (`id_profesor`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- PROYECTO DE INVESTIGACIÓN (+ interrelación 1:N INVESTIGADOR_PRINCIPAL) ------
CREATE TABLE `proyecto_investigacion` (
  `id_proyecto` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `nombre_proyecto` varchar(200) NOT NULL,
  `acronimo` varchar(30) NOT NULL,
  `presupuesto` decimal(14,2) UNSIGNED NOT NULL DEFAULT 0.00,
  `id_programa` smallint(5) UNSIGNED NOT NULL COMMENT 'Programa de I+D que lo financia',
  `descripcion` text DEFAULT NULL,
  `inicio_pro` date NOT NULL,
  `fin_pro` date NOT NULL,
  `id_investigador_principal` int(10) UNSIGNED NOT NULL,
  `resolucion_consejo_uni_aprobado` varchar(50) NOT NULL,
  `resolucion_consejo_uni_cierre` varchar(50) DEFAULT NULL,
  `prorroga` date DEFAULT NULL,
  PRIMARY KEY (`id_proyecto`),
  UNIQUE KEY `uq_proyecto_nombre` (`nombre_proyecto`),
  UNIQUE KEY `uq_proyecto_acronimo` (`acronimo`),
  KEY `idx_proy_ip` (`id_investigador_principal`),
  KEY `idx_proy_programa` (`id_programa`),
  CONSTRAINT `chk_proyecto_fechas` CHECK (`fin_pro` >= `inicio_pro`),
  CONSTRAINT `chk_proyecto_prorroga` CHECK (`prorroga` IS NULL OR `prorroga` > `fin_pro`),
  CONSTRAINT `fk_proyecto_ip` FOREIGN KEY (`id_investigador_principal`) REFERENCES `profesores` (`id_profesor`) ON UPDATE CASCADE,
  CONSTRAINT `fk_proyecto_programa` FOREIGN KEY (`id_programa`) REFERENCES `programa` (`id_programa`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Interrelación PARTICIPA (N:M) con periodos + cargo UEB -----------------------
CREATE TABLE `proyecto_profesor` (
  `id_proyecto` int(10) UNSIGNED NOT NULL,
  `id_profesor` int(10) UNSIGNED NOT NULL,
  `fecha_inicio` date NOT NULL,
  `fecha_fin` date DEFAULT NULL,
  `num_profesores` tinyint(3) UNSIGNED DEFAULT NULL,
  `cargo` enum('Director','Director subrogante','Investigador') NOT NULL,
  `resolucion_ingreso` varchar(50) DEFAULT NULL,
  `resolucion_salida` varchar(50) DEFAULT NULL,
  `motivo_salida` varchar(200) DEFAULT NULL,
  PRIMARY KEY (`id_proyecto`,`id_profesor`,`fecha_inicio`),
  UNIQUE KEY `uq_pp_fin` (`id_proyecto`,`id_profesor`,`fecha_fin`),
  KEY `idx_pp_profesor` (`id_profesor`),
  CONSTRAINT `chk_pp_fechas` CHECK (`fecha_fin` IS NULL OR `fecha_fin` >= `fecha_inicio`),
  CONSTRAINT `chk_pp_salida` CHECK ((`resolucion_salida` IS NULL) = (`fecha_fin` IS NULL)),
  CONSTRAINT `fk_proyecto_profesor_profesor` FOREIGN KEY (`id_profesor`) REFERENCES `profesores` (`id_profesor`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_proyecto_profesor_proyecto` FOREIGN KEY (`id_proyecto`) REFERENCES `proyecto_investigacion` (`id_proyecto`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- PARTE 2: PUBLICACIÓN (entidad débil de PROYECTO; jerarquía por tipo) --------
CREATE TABLE `tipo_pro` (
  `id_tipo` tinyint(3) UNSIGNED NOT NULL,
  `descripcion_tipo` varchar(30) NOT NULL,
  PRIMARY KEY (`id_tipo`),
  UNIQUE KEY `uq_tipo_descripcion` (`descripcion_tipo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `productos` (
  `id_producto` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `id_proyecto` int(10) UNSIGNED NOT NULL,
  `id_tipo` tinyint(3) UNSIGNED NOT NULL,
  `titulo_publicacion` varchar(255) NOT NULL,
  `num_secuencia` int(10) UNSIGNED NOT NULL,
  PRIMARY KEY (`id_producto`),
  UNIQUE KEY `uq_producto_secuencia` (`id_proyecto`,`num_secuencia`),
  KEY `idx_prod_tipo` (`id_tipo`),
  CONSTRAINT `fk_productos_proyecto` FOREIGN KEY (`id_proyecto`) REFERENCES `proyecto_investigacion` (`id_proyecto`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_productos_tipo` FOREIGN KEY (`id_tipo`) REFERENCES `tipo_pro` (`id_tipo`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `publicacion_revista` (
  `id_revista` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `id_producto` int(10) UNSIGNED NOT NULL,
  `nombre_revista` varchar(200) NOT NULL,
  `id_editorial` int(10) UNSIGNED NOT NULL,
  `volumen` varchar(20) NOT NULL,
  `numero` varchar(20) DEFAULT NULL,
  `pagina_inicio` int(10) UNSIGNED DEFAULT NULL,
  `pagina_fin` int(10) UNSIGNED DEFAULT NULL,
  `quartil` enum('Q1','Q2','Q3','Q4') DEFAULT NULL,
  `url` varchar(500) DEFAULT NULL,
  `doi` varchar(150) DEFAULT NULL,
  `issn` char(9) DEFAULT NULL,
  `e_issn` char(9) DEFAULT NULL,
  PRIMARY KEY (`id_revista`),
  UNIQUE KEY `uq_revista_producto` (`id_producto`),
  UNIQUE KEY `uq_revista_doi` (`doi`),
  KEY `idx_rev_editorial` (`id_editorial`),
  CONSTRAINT `chk_revista_paginas` CHECK (`pagina_inicio` IS NULL OR `pagina_fin` IS NULL OR `pagina_fin` >= `pagina_inicio`),
  CONSTRAINT `fk_publicacion_revista_producto` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`) ON DELETE CASCADE,
  CONSTRAINT `fk_revista_editorial` FOREIGN KEY (`id_editorial`) REFERENCES `editorial` (`id_editorial`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `publicacion_congreso` (
  `id_congreso` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `id_producto` int(10) UNSIGNED NOT NULL,
  `nombre_congreso` varchar(200) NOT NULL,
  `tipo_congreso` enum('Nacional','Internacional') NOT NULL COMMENT 'SS17',
  `modalidad` varchar(80) DEFAULT NULL COMMENT 'Congreso, conferencia, jornada... (extensión UEB)',
  `fecha_inicio` date NOT NULL,
  `fecha_fin` date NOT NULL,
  `lugar_celebracion` varchar(150) NOT NULL,
  `id_pais` smallint(5) UNSIGNED NOT NULL,
  `id_editorial_actas` int(10) UNSIGNED DEFAULT NULL,
  `entidad_organizadora` varchar(150) DEFAULT NULL,
  `tipo_participacion` varchar(80) NOT NULL,
  PRIMARY KEY (`id_congreso`),
  UNIQUE KEY `uq_congreso_producto` (`id_producto`),
  KEY `idx_cong_pais` (`id_pais`),
  KEY `idx_cong_editorial` (`id_editorial_actas`),
  CONSTRAINT `chk_congreso_fechas` CHECK (`fecha_fin` >= `fecha_inicio`),
  CONSTRAINT `fk_publicacion_congreso_producto` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`) ON DELETE CASCADE,
  CONSTRAINT `fk_congreso_pais` FOREIGN KEY (`id_pais`) REFERENCES `pais` (`id_pais`) ON UPDATE CASCADE,
  CONSTRAINT `fk_congreso_editorial` FOREIGN KEY (`id_editorial_actas`) REFERENCES `editorial` (`id_editorial`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Extensión UEB: libros y patentes
CREATE TABLE `libro` (
  `id_libro` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `id_producto` int(10) UNSIGNED NOT NULL,
  `isbn` varchar(17) NOT NULL,
  `titulo_libro` varchar(255) NOT NULL,
  `id_editorial` int(10) UNSIGNED NOT NULL,
  `lugar_publicacion` varchar(150) DEFAULT NULL,
  `fecha_publicacion` date NOT NULL,
  `total_paginas` int(10) UNSIGNED DEFAULT NULL,
  PRIMARY KEY (`id_libro`),
  UNIQUE KEY `uq_libro_producto` (`id_producto`),
  UNIQUE KEY `uq_libro_isbn` (`isbn`),
  KEY `idx_libro_editorial` (`id_editorial`),
  CONSTRAINT `fk_libro_producto` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`) ON DELETE CASCADE,
  CONSTRAINT `fk_libro_editorial` FOREIGN KEY (`id_editorial`) REFERENCES `editorial` (`id_editorial`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `patentes` (
  `num_registro` varchar(40) NOT NULL,
  `id_producto` int(10) UNSIGNED NOT NULL,
  `nombre_patente` varchar(200) NOT NULL,
  `estado` enum('Solicitada','Concedida','Denegada','Caducada') NOT NULL DEFAULT 'Solicitada',
  `id_pais_registro` smallint(5) UNSIGNED NOT NULL,
  `fecha_concesion` date DEFAULT NULL,
  `num_solicitud` varchar(40) NOT NULL,
  `fecha_solicitud` date NOT NULL,
  `clasificacion_inter` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`num_registro`),
  UNIQUE KEY `uq_patente_producto` (`id_producto`),
  KEY `idx_pat_pais` (`id_pais_registro`),
  CONSTRAINT `fk_patentes_producto` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`) ON DELETE CASCADE,
  CONSTRAINT `fk_patentes_pais` FOREIGN KEY (`id_pais_registro`) REFERENCES `pais` (`id_pais`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- PARTE 3: LÍNEA DE INVESTIGACIÓN ---------------------------------------------
CREATE TABLE `linea_investigacion` (
  `id_linea` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `codigo` varchar(10) NOT NULL,
  `nombre_linea` varchar(150) NOT NULL,
  PRIMARY KEY (`id_linea`),
  UNIQUE KEY `uq_linea_codigo` (`codigo`),
  UNIQUE KEY `uq_linea_nombre` (`nombre_linea`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Atributo multivaluado "descriptores"
CREATE TABLE `linea_descriptor` (
  `id_linea` int(10) UNSIGNED NOT NULL,
  `descriptor` varchar(100) NOT NULL,
  PRIMARY KEY (`id_linea`,`descriptor`),
  CONSTRAINT `fk_descriptor_linea` FOREIGN KEY (`id_linea`) REFERENCES `linea_investigacion` (`id_linea`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Interrelación DESARROLLA (PROFESOR N:M LÍNEA)
CREATE TABLE `linea_profesor` (
  `id_linea` int(10) UNSIGNED NOT NULL,
  `id_profesor` int(10) UNSIGNED NOT NULL,
  PRIMARY KEY (`id_linea`,`id_profesor`),
  KEY `idx_lp_profesor` (`id_profesor`),
  CONSTRAINT `fk_linea_profesor_linea` FOREIGN KEY (`id_linea`) REFERENCES `linea_investigacion` (`id_linea`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_linea_profesor_profesor` FOREIGN KEY (`id_profesor`) REFERENCES `profesores` (`id_profesor`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Interrelación INCLUYE (PROYECTO N:M LÍNEA)
CREATE TABLE `proyecto_linea` (
  `id_linea` int(10) UNSIGNED NOT NULL,
  `id_proyecto` int(10) UNSIGNED NOT NULL,
  PRIMARY KEY (`id_linea`,`id_proyecto`),
  KEY `idx_pl_proyecto` (`id_proyecto`),
  CONSTRAINT `fk_proyecto_linea_linea` FOREIGN KEY (`id_linea`) REFERENCES `linea_investigacion` (`id_linea`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_proyecto_linea_proyecto` FOREIGN KEY (`id_proyecto`) REFERENCES `proyecto_investigacion` (`id_proyecto`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Interrelación ternaria ESCRIBE (PROFESOR, PUBLICACIÓN, LÍNEA) 1:N:M:
-- un profesor escribe en una publicación sobre una sola línea.
CREATE TABLE `escribe` (
  `id_producto` int(10) UNSIGNED NOT NULL,
  `id_profesor` int(10) UNSIGNED NOT NULL,
  `id_linea` int(10) UNSIGNED NOT NULL,
  PRIMARY KEY (`id_producto`,`id_profesor`),
  KEY `idx_esc_profesor` (`id_profesor`),
  KEY `idx_esc_linea` (`id_linea`),
  CONSTRAINT `fk_escribe_producto` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_escribe_profesor` FOREIGN KEY (`id_profesor`) REFERENCES `profesores` (`id_profesor`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_escribe_linea` FOREIGN KEY (`id_linea`) REFERENCES `linea_investigacion` (`id_linea`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- EXTENSIONES UEB ---------------------------------------------------------------
CREATE TABLE `estudiante` (
  `id_estudiante` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `id_proyecto` int(10) UNSIGNED NOT NULL,
  `nombres_est` varchar(150) NOT NULL,
  `telefono_est` varchar(20) DEFAULT NULL,
  `id_facultad` tinyint(3) UNSIGNED NOT NULL,
  `db_usuario` varchar(80) DEFAULT NULL COMMENT 'Cuenta MariaDB del estudiante',
  PRIMARY KEY (`id_estudiante`),
  UNIQUE KEY `uq_estudiante_usuario` (`db_usuario`),
  KEY `idx_est_proyecto` (`id_proyecto`),
  KEY `idx_est_facultad` (`id_facultad`),
  CONSTRAINT `fk_estudiante_proyecto` FOREIGN KEY (`id_proyecto`) REFERENCES `proyecto_investigacion` (`id_proyecto`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_estudiante_facultad` FOREIGN KEY (`id_facultad`) REFERENCES `facultad` (`id_facultad`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `resumen_proyecto` (
  `id_proyecto` int(10) UNSIGNED NOT NULL,
  `total_productos` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `ultima_actualizacion` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id_proyecto`),
  CONSTRAINT `fk_resumen_proyecto` FOREIGN KEY (`id_proyecto`) REFERENCES `proyecto_investigacion` (`id_proyecto`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `historial_participacion` (
  `id_historial` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `id_proyecto` int(10) UNSIGNED NOT NULL,
  `id_profesor` int(10) UNSIGNED NOT NULL,
  `cargo_anterior` varchar(30) DEFAULT NULL,
  `cargo_nuevo` varchar(30) DEFAULT NULL,
  `resolucion_salida` varchar(50) DEFAULT NULL,
  `motivo_salida` varchar(200) DEFAULT NULL,
  `usuario` varchar(100) NOT NULL,
  `fecha_cambio` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id_historial`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `auditoria_proyecto` (
  `id_auditoria` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `id_proyecto` int(10) UNSIGNED NOT NULL,
  `operacion` enum('UPDATE','DELETE') NOT NULL,
  `datos_anteriores` text DEFAULT NULL,
  `datos_nuevos` text DEFAULT NULL,
  `usuario` varchar(100) NOT NULL,
  `fecha_hora` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id_auditoria`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `auditoria_operaciones` (
  `id_auditoria` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `fecha` datetime NOT NULL DEFAULT current_timestamp(),
  `operacion` varchar(50) NOT NULL,
  `procedimiento_ejecutado` varchar(100) NOT NULL,
  `resultado` varchar(255) NOT NULL,
  PRIMARY KEY (`id_auditoria`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- DATOS
-- ============================================================================

INSERT INTO `facultad` (`id_facultad`, `siglas`, `nombre_facultad`) VALUES
(1, 'FCA', 'Facultad de Ciencias Administrativas, Gestión Empresarial e Informática'),
(2, 'FCAG', 'Facultad de Ciencias Agropecuarias, Recursos Naturales y del Ambiente'),
(3, 'FCE', 'Facultad de Ciencias de la Educación, Sociales, Filosóficas y Humanísticas');

INSERT INTO `programa` (`id_programa`, `nombre_programa`) VALUES
(1, 'Programa de Desarrollo Tecnológico'),
(2, 'Programa de Ambiente y Clima'),
(3, 'Programa Agropecuario Sostenible'),
(4, 'Programa de Gestión Pública');

INSERT INTO `pais` (`id_pais`, `nombre_pais`) VALUES
(1, 'Ecuador'),
(2, 'Perú');

INSERT INTO `editorial` (`id_editorial`, `nombre_editorial`) VALUES
(1, 'AISTI'),
(2, 'MDPI'),
(3, 'Universidad Estatal de Milagro'),
(4, 'Elsevier'),
(5, 'ESPOL'),
(6, 'Editorial UEB'),
(7, 'IEEE');

INSERT INTO `profesores` (`id_profesor`, `nombres`, `apellidos`, `despacho`, `telefono`, `id_facultad`, `tipo`, `db_usuario`) VALUES
(1, 'Carlos Andrés', 'Villacrés Ramos', 'FCA-201', '0991234501', 1, 'doctor', 'carlos.villacres'),
(2, 'María Fernanda', 'Gavilanes Silva', 'FCA-202', '0991234502', 1, 'doctor', 'maria.gavilanes'),
(3, 'Luis Alberto', 'Chimbo Yánez', 'FCAG-105', '0991234503', 2, 'doctor', 'luis.chimbo'),
(4, 'Ana Lucía', 'Arellano Torres', 'FCA-203', '0991234504', 1, 'doctor', 'ana.arellano'),
(5, 'Jorge Patricio', 'Naranjo Coloma', 'FCA-204', '0991234505', 1, 'doctor', 'jorge.naranjo'),
(6, 'Diana Carolina', 'Pazmiño Llerena', 'FCAG-106', '0991234506', 2, 'doctor', 'diana.pazmino'),
(7, 'Héctor Iván', 'Sánchez Barragán', 'FCA-205', '0991234507', 1, 'no_doctor', 'hector.sanchez'),
(8, 'Gabriela Estefanía', 'Mora Lema', 'FCA-206', '0991234508', 1, 'no_doctor', 'gabriela.mora'),
(9, 'Ramiro Javier', 'Guamán Ortiz', 'FCA-207', '0991234509', 1, 'doctor', 'ramiro.guaman'),
(10, 'Paola Alexandra', 'Salazar Vega', 'FCAG-107', '0991234510', 2, 'no_doctor', 'paola.salazar'),
(11, 'Edison Fabricio', 'Lombeida Pilco', 'FCAG-108', '0991234511', 2, 'no_doctor', 'edison.lombeida'),
(12, 'Verónica Isabel', 'Coello Ruiz', 'FCA-208', '0991234512', 1, 'no_doctor', 'veronica.coello'),
(13, 'Fausto Rodrigo', 'Escobar Núñez', 'FCE-301', '0991234513', 3, 'doctor', 'fausto.escobar');

INSERT INTO `supervision` (`id_doctor`, `id_no_doctor`, `fecha_inicio`, `fecha_fin`) VALUES
(1, 7, '2022-03-01', '2024-02-28'),
(4, 7, '2024-03-01', NULL),
(1, 8, '2023-01-10', NULL),
(6, 10, '2022-09-01', NULL),
(3, 11, '2023-04-01', NULL),
(9, 12, '2024-05-15', NULL);

INSERT INTO `proyecto_investigacion` (`id_proyecto`, `nombre_proyecto`, `acronimo`, `presupuesto`, `id_programa`, `descripcion`, `inicio_pro`, `fin_pro`, `id_investigador_principal`, `resolucion_consejo_uni_aprobado`, `resolucion_consejo_uni_cierre`, `prorroga`) VALUES
(1, 'Plataforma web para la gestión de la investigación universitaria', 'PLATINV', 18500.00, 1, 'Desarrollar un sistema web para registrar proyectos, investigadores y productos de investigación de la UEB.', '2025-03-01', '2026-12-31', 1, 'RCU-UEB-2025-045', NULL, NULL),
(2, 'Análisis de imágenes satelitales para el monitoreo del clima en Bolívar', 'SATCLIMA', 32000.00, 2, 'Aplicar técnicas de inteligencia artificial sobre imágenes satelitales para analizar el clima de la provincia.', '2024-09-01', '2026-08-31', 2, 'RCU-UEB-2024-118', NULL, '2027-02-28'),
(3, 'Red IoT para el monitoreo de cultivos andinos', 'IOTAGRO', 24750.00, 3, 'Implementar sensores conectados en red para medir humedad y temperatura en cultivos.', '2025-06-01', '2027-06-30', 3, 'RCU-UEB-2025-089', NULL, NULL),
(4, 'Modelo de ciberseguridad para gobiernos autónomos descentralizados', 'CIBERGAD', 12000.00, 4, 'Proponer un modelo de seguridad de la información para los GAD de la provincia Bolívar.', '2023-02-01', '2024-01-31', 1, 'RCU-UEB-2023-007', 'RCU-UEB-2024-012', NULL),
(5, 'Repositorio de datos abiertos de la provincia Bolívar', 'DATABOL', 11500.00, 1, 'Construir un repositorio de datos abiertos con información socioeconómica de la provincia.', '2026-01-05', '2026-11-30', 2, 'RCU-UEB-2025-201', NULL, NULL),
(6, 'Sistema de alertas de heladas en Bolívar', 'HELADAS', 15000.00, 3, 'Monitoreo y alerta temprana de heladas para productores agrícolas de la provincia.', '2026-12-01', '2027-10-30', 6, 'RCU-UEB-2026-300', NULL, NULL);

INSERT INTO `proyecto_profesor` (`id_proyecto`, `id_profesor`, `fecha_inicio`, `fecha_fin`, `num_profesores`, `cargo`, `resolucion_ingreso`, `resolucion_salida`, `motivo_salida`) VALUES
(1, 1, '2025-03-01', '2026-06-15', 1, 'Director', NULL, 'RCU-SAL-01', 'Renuncia voluntaria'),
(1, 4, '2025-03-01', NULL, 2, 'Director subrogante', NULL, NULL, NULL),
(1, 7, '2025-03-01', NULL, 3, 'Investigador', NULL, NULL, NULL),
(1, 8, '2025-03-01', '2026-02-20', 4, 'Investigador', NULL, 'RCU-UEB-2026-030', 'Cambio de dedicación a docencia'),
(1, 8, '2026-09-01', NULL, 5, 'Investigador', 'RCU-UEB-2026-210', NULL, NULL),
(1, 12, '2025-03-01', NULL, 5, 'Investigador', NULL, NULL, NULL),
(1, 13, '2026-06-16', NULL, 5, 'Director', 'RCU-ING-13', NULL, NULL),
(2, 2, '2024-09-01', NULL, 1, 'Director', NULL, NULL, NULL),
(2, 5, '2024-09-01', NULL, 2, 'Director subrogante', NULL, NULL, NULL),
(2, 9, '2024-10-15', NULL, 3, 'Investigador', 'RCU-UEB-2024-131', NULL, NULL),
(2, 10, '2024-09-01', NULL, 4, 'Investigador', NULL, NULL, NULL),
(2, 11, '2025-01-20', NULL, 5, 'Investigador', 'RCU-UEB-2025-004', NULL, NULL),
(3, 3, '2025-06-01', NULL, 1, 'Director', NULL, NULL, NULL),
(3, 6, '2025-06-01', NULL, 2, 'Director subrogante', NULL, NULL, NULL),
(3, 8, '2026-03-01', NULL, 5, 'Investigador', 'RCU-UEB-2026-150', NULL, NULL),
(3, 9, '2025-06-01', NULL, 3, 'Investigador', NULL, NULL, NULL),
(3, 11, '2025-06-01', NULL, 4, 'Investigador', NULL, NULL, NULL),
(4, 1, '2023-02-01', '2024-01-31', 1, 'Director', NULL, 'RCU-UEB-2024-012', 'Cierre del proyecto'),
(4, 5, '2023-02-01', '2024-01-31', 2, 'Director subrogante', NULL, 'RCU-UEB-2024-012', 'Cierre del proyecto'),
(4, 8, '2023-02-01', '2024-01-31', 3, 'Investigador', NULL, 'RCU-UEB-2024-012', 'Cierre del proyecto'),
(5, 2, '2026-01-05', NULL, 1, 'Director', NULL, NULL, NULL),
(5, 4, '2026-01-05', NULL, 2, 'Director subrogante', NULL, NULL, NULL),
(5, 7, '2026-01-05', NULL, 3, 'Investigador', NULL, NULL, NULL),
(5, 13, '2026-04-10', NULL, 4, 'Investigador', 'RCU-UEB-2026-223', NULL, NULL),
(6, 6, '2026-12-01', NULL, 1, 'Director', 'RCU-UEB-2026-300', NULL, NULL),
(6, 10, '2026-12-01', NULL, 2, 'Investigador', 'RCU-UEB-2026-300', NULL, NULL);

INSERT INTO `tipo_pro` (`id_tipo`, `descripcion_tipo`) VALUES
(1, 'Revista'),
(2, 'Congreso'),
(3, 'Libro'),
(4, 'Patente');

INSERT INTO `productos` (`id_producto`, `id_proyecto`, `id_tipo`, `titulo_publicacion`, `num_secuencia`) VALUES
(1, 1, 1, 'Arquitectura de un sistema web para la gestión de proyectos de investigación', 1),
(2, 1, 3, 'Gestión de la investigación universitaria con software libre', 2),
(3, 1, 2, 'Evaluación de usabilidad de una plataforma de investigación universitaria', 3),
(4, 2, 1, 'Clasificación de cobertura vegetal con imágenes satelitales en Bolívar', 1),
(5, 2, 1, 'Modelo predictivo de precipitaciones con redes neuronales', 2),
(6, 2, 4, 'Método de procesamiento de imágenes satelitales para zonas andinas', 3),
(7, 2, 3, 'Inteligencia artificial aplicada al clima andino', 4),
(8, 3, 1, 'Sensores de bajo costo para la agricultura de precisión', 1),
(9, 3, 4, 'Dispositivo IoT para medir la humedad del suelo', 2),
(10, 4, 1, 'Diagnóstico de seguridad de la información en GAD cantonales', 1),
(11, 4, 2, 'Buenas prácticas de ciberseguridad para gobiernos locales', 2),
(12, 5, 2, 'Portal de datos abiertos de la provincia Bolívar', 1),
(13, 5, 2, 'Ponencia sobre datos abiertos', 2);

INSERT INTO `publicacion_revista` (`id_revista`, `id_producto`, `nombre_revista`, `id_editorial`, `volumen`, `numero`, `pagina_inicio`, `pagina_fin`, `quartil`, `url`, `doi`, `issn`, `e_issn`) VALUES
(1, 1, 'Revista Ibérica de Sistemas e Tecnologias de Informação', 1, '45', '3', 112, 125, 'Q3', 'https://www.risti.xyz', '10.17013/risti.45.112-125', '1646-9895', NULL),
(2, 4, 'Remote Sensing', 2, '17', '1', 1, 22, 'Q1', 'https://www.mdpi.com/journal/remotesensing', '10.3390/rs17010001', NULL, '2072-4292'),
(3, 5, 'Revista Ciencia UNEMI', 3, '18', '47', 45, 58, NULL, 'https://ojs.unemi.edu.ec', '10.29076/issn.2528-7737vol18iss47.2025pp45-58p', '1390-4272', '2528-7737'),
(4, 8, 'Computers and Electronics in Agriculture', 4, '230', '2', 101, 115, 'Q2', 'https://www.sciencedirect.com/journal/computers-and-electronics-in-agriculture', '10.1016/j.compag.2025.101', '0168-1699', NULL),
(5, 10, 'Revista Tecnológica ESPOL', 5, '36', '1', 70, 84, 'Q4', 'https://rte.espol.edu.ec', '10.37815/rte.v36n1.2024', '0257-1749', '1390-3659');

INSERT INTO `publicacion_congreso` (`id_congreso`, `id_producto`, `nombre_congreso`, `tipo_congreso`, `modalidad`, `fecha_inicio`, `fecha_fin`, `lugar_celebracion`, `id_pais`, `id_editorial_actas`, `entidad_organizadora`, `tipo_participacion`) VALUES
(1, 3, 'Congreso Internacional de Ciencia y Tecnología UEB 2026', 'Internacional', 'Congreso científico', '2026-05-20', '2026-05-22', 'Guaranda', 1, 6, 'Universidad Estatal de Bolívar', 'Ponencia'),
(2, 11, 'IEEE ANDESCON 2024', 'Internacional', 'Conferencia', '2024-10-08', '2024-10-11', 'Lima', 2, 7, 'IEEE Sección Perú', 'Artículo en actas'),
(3, 12, 'Jornadas de Investigación UEB 2026', 'Nacional', 'Jornada científica', '2026-10-14', '2026-10-15', 'Guaranda', 1, NULL, 'Universidad Estatal de Bolívar', 'Ponencia'),
(4, 13, 'Encuentro Nacional de Datos Abiertos 2026', 'Nacional', 'Jornada científica', '2026-11-20', '2026-11-21', 'Quito', 1, NULL, 'Red Ecuatoriana de Datos Abiertos', 'Ponencia');

INSERT INTO `libro` (`id_libro`, `id_producto`, `isbn`, `titulo_libro`, `id_editorial`, `lugar_publicacion`, `fecha_publicacion`, `total_paginas`) VALUES
(1, 2, '978-9942-0000-1-1', 'Gestión de la investigación universitaria con software libre', 6, 'Guaranda', '2026-03-10', 186),
(2, 7, '978-9942-0000-2-8', 'Inteligencia artificial aplicada al clima andino', 6, 'Guaranda', '2025-11-20', 240);

INSERT INTO `patentes` (`num_registro`, `id_producto`, `nombre_patente`, `estado`, `id_pais_registro`, `fecha_concesion`, `num_solicitud`, `fecha_solicitud`, `clasificacion_inter`) VALUES
('SENADI-2025-0457', 6, 'Método de procesamiento de imágenes satelitales para zonas andinas', 'Concedida', 1, '2026-04-18', 'SOL-2025-0457', '2025-05-02', 'G06T 7/00'),
('SENADI-2026-0112', 9, 'Dispositivo IoT para medir la humedad del suelo', 'Solicitada', 1, NULL, 'SOL-2026-0112', '2026-02-14', 'A01G 25/16');

INSERT INTO `linea_investigacion` (`id_linea`, `codigo`, `nombre_linea`) VALUES
(1, 'LI-01', 'Desarrollo de software'),
(2, 'LI-02', 'Inteligencia artificial y ciencia de datos'),
(3, 'LI-03', 'Redes y telecomunicaciones'),
(4, 'LI-04', 'Seguridad de la información'),
(5, 'LI-05', 'Sistemas de información y bases de datos'),
(6, 'LI-06', 'Producción agropecuaria sostenible'),
(7, 'LI-07', 'Emprendimiento e innovación');

INSERT INTO `linea_descriptor` (`id_linea`, `descriptor`) VALUES
(1, 'Ingeniería de software'), (1, 'Aplicaciones web'), (1, 'Aplicaciones móviles'),
(2, 'Aprendizaje automático'), (2, 'Visión por computador'), (2, 'Análisis de datos'),
(3, 'Redes de datos'), (3, 'VoIP'), (3, 'Internet de las cosas'),
(4, 'Ciberseguridad'), (4, 'Criptografía'), (4, 'Auditoría informática'),
(5, 'SGBD relacional'), (5, 'Bases de datos temporales'), (5, 'Inteligencia de negocios'),
(6, 'Agronomía'), (6, 'Clima'), (6, 'Agricultura de precisión'),
(7, 'Gestión empresarial'), (7, 'Modelos de negocio'), (7, 'Innovación tecnológica');

INSERT INTO `linea_profesor` (`id_linea`, `id_profesor`) VALUES
(1, 1), (4, 1), (2, 2), (6, 3), (5, 4), (2, 5), (6, 6), (1, 7), (4, 8), (5, 8),
(2, 9), (3, 9), (6, 10), (3, 11), (6, 11), (1, 12), (7, 13);

INSERT INTO `proyecto_linea` (`id_linea`, `id_proyecto`) VALUES
(1, 1), (5, 1), (2, 2), (3, 2), (6, 2), (3, 3), (6, 3), (4, 4), (2, 5), (5, 5), (6, 6);

INSERT INTO `escribe` (`id_producto`, `id_profesor`, `id_linea`) VALUES
(1, 1, 1), (1, 7, 1), (1, 4, 5),
(2, 12, 1), (2, 1, 1),
(3, 7, 1), (3, 8, 5),
(4, 2, 2), (4, 10, 6),
(5, 5, 2), (5, 9, 2),
(6, 2, 2), (6, 11, 3),
(7, 2, 2), (7, 5, 2), (7, 10, 6),
(8, 3, 6), (8, 9, 3),
(9, 11, 3), (9, 6, 6),
(10, 1, 4), (10, 8, 4),
(11, 8, 4),
(12, 4, 5), (12, 2, 2),
(13, 4, 5);

INSERT INTO `estudiante` (`id_estudiante`, `id_proyecto`, `nombres_est`, `telefono_est`, `id_facultad`, `db_usuario`) VALUES
(1, 1, 'Andony Fernando Cortez Cuascota', '0987654301', 1, 'andony.cortez'),
(2, 1, 'Jonthan Polito Ayme Caiza', '0987654302', 1, 'jonathan.ayme'),
(3, 2, 'Bryan Santiago Ruiz Vargas', '0987654303', 1, 'bryan.ruiz'),
(4, 2, 'Lizbeth Johanna Tixi Coles', '0987654304', 2, 'lizbeth.tixi'),
(5, 2, 'Jonathan David Sisa Llumitasig', '0987654305', 1, 'jonathan.sisa'),
(6, 3, 'Erika Fernanda Gaibor Arias', '0987654306', 2, 'erika.gaibor'),
(7, 3, 'Marco Vinicio Paredes Cruz', '0987654307', 2, 'marco.paredes');

INSERT INTO `resumen_proyecto` (`id_proyecto`, `total_productos`, `ultima_actualizacion`) VALUES
(1, 3, '2026-11-06 18:47:54'),
(2, 4, '2026-11-06 18:47:54'),
(3, 2, '2026-11-06 18:47:54'),
(4, 2, '2026-11-06 18:47:54'),
(5, 2, '2026-11-11 22:04:49'),
(6, 0, '2026-11-11 22:04:11');

INSERT INTO `historial_participacion` (`id_historial`, `id_proyecto`, `id_profesor`, `cargo_anterior`, `cargo_nuevo`, `resolucion_salida`, `motivo_salida`, `usuario`, `fecha_cambio`) VALUES
(1, 1, 1, 'Director', 'Director', 'RCU-SAL-01', 'Renuncia voluntaria', 'root@localhost', '2026-11-11 22:04:30');

INSERT INTO `auditoria_operaciones` (`id_auditoria`, `fecha`, `operacion`, `procedimiento_ejecutado`, `resultado`) VALUES
(1, '2026-11-12 00:42:26', 'UPDATE', 'sp_cambio_director_transaccional', 'FALLIDO - Rollback por datos erroneos o excepcion');

ALTER TABLE `facultad`                AUTO_INCREMENT=4;
ALTER TABLE `programa`                AUTO_INCREMENT=5;
ALTER TABLE `pais`                    AUTO_INCREMENT=3;
ALTER TABLE `editorial`               AUTO_INCREMENT=8;
ALTER TABLE `profesores`              AUTO_INCREMENT=14;
ALTER TABLE `proyecto_investigacion`  AUTO_INCREMENT=7;
ALTER TABLE `productos`               AUTO_INCREMENT=14;
ALTER TABLE `publicacion_revista`     AUTO_INCREMENT=6;
ALTER TABLE `publicacion_congreso`    AUTO_INCREMENT=5;
ALTER TABLE `libro`                   AUTO_INCREMENT=3;
ALTER TABLE `linea_investigacion`     AUTO_INCREMENT=8;
ALTER TABLE `estudiante`              AUTO_INCREMENT=8;
ALTER TABLE `historial_participacion` AUTO_INCREMENT=2;
ALTER TABLE `auditoria_proyecto`      AUTO_INCREMENT=1;
ALTER TABLE `auditoria_operaciones`   AUTO_INCREMENT=2;

-- ============================================================================
-- FUNCIONES
-- ============================================================================
DELIMITER $$

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_fin_vigente` (`p_fin` DATE, `p_prorroga` DATE) RETURNS DATE DETERMINISTIC BEGIN
    RETURN IFNULL(p_prorroga, p_fin);
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_proyectos_activos` (`p_id_profesor` INT UNSIGNED) RETURNS INT(11) READS SQL DATA BEGIN
    DECLARE v_total INT DEFAULT 0;
    SELECT COUNT(DISTINCT pp.id_proyecto) INTO v_total
      FROM proyecto_profesor pp
      JOIN proyecto_investigacion p ON p.id_proyecto = pp.id_proyecto
     WHERE pp.id_profesor = p_id_profesor
       AND pp.resolucion_salida IS NULL
       AND p.resolucion_consejo_uni_cierre IS NULL;
    RETURN v_total;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_puntaje_revista` (`p_quartil` VARCHAR(2)) RETURNS DECIMAL(4,2) DETERMINISTIC BEGIN
    RETURN CASE p_quartil
               WHEN 'Q1' THEN 1.00
               WHEN 'Q2' THEN 0.80
               WHEN 'Q3' THEN 0.60
               WHEN 'Q4' THEN 0.40
               ELSE 0.20
           END;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_tipo_producto` (`p_id_producto` INT UNSIGNED) RETURNS VARCHAR(30) CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci READS SQL DATA BEGIN
    DECLARE v_tipo VARCHAR(30);
    SELECT t.descripcion_tipo INTO v_tipo
      FROM productos pr
      JOIN tipo_pro t ON t.id_tipo = pr.id_tipo
     WHERE pr.id_producto = p_id_producto;
    RETURN IFNULL(v_tipo, 'No existe');
END$$

-- ============================================================================
-- PROCEDIMIENTOS DE CONSULTA (reportes)
-- ============================================================================

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_ca1_productividad_proyectos` ()   BEGIN
    SELECT CASE WHEN r.acronimo IS NULL THEN 'TOTAL UEB' ELSE r.acronimo END AS proyecto,
           CASE WHEN r.acronimo IS NULL THEN '-'
                WHEN r.tipo IS NULL     THEN 'Subtotal'
                ELSE r.tipo END                                   AS tipo_producto,
           r.cantidad
      FROM (SELECT p.acronimo, t.descripcion_tipo AS tipo, COUNT(*) AS cantidad
              FROM productos pr
              JOIN proyecto_investigacion p ON p.id_proyecto = pr.id_proyecto
              JOIN tipo_pro t               ON t.id_tipo     = pr.id_tipo
             GROUP BY p.acronimo, t.descripcion_tipo WITH ROLLUP) r;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_ca2_proyectos_sobre_promedio` ()   BEGIN
    SELECT p.acronimo,
           p.presupuesto,
           ROUND((SELECT AVG(presupuesto) FROM proyecto_investigacion), 2) AS promedio_ueb,
           ROUND(p.presupuesto - (SELECT AVG(presupuesto)
                                    FROM proyecto_investigacion), 2)    AS diferencia
      FROM proyecto_investigacion p
     WHERE p.presupuesto > (SELECT AVG(presupuesto) FROM proyecto_investigacion)
     ORDER BY p.presupuesto DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_ca3_ultimo_producto_proyecto` ()   BEGIN
    SELECT p.acronimo,
           pr.num_secuencia,
           LEFT(pr.titulo_publicacion, 50)  AS titulo,
           fn_tipo_producto(pr.id_producto) AS tipo
      FROM productos pr
      JOIN proyecto_investigacion p ON p.id_proyecto = pr.id_proyecto
     WHERE pr.num_secuencia = (SELECT MAX(x.num_secuencia)
                                 FROM productos x
                                WHERE x.id_proyecto = pr.id_proyecto)
     ORDER BY p.acronimo;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_ca4_valoracion_revistas` ()   BEGIN
    SELECT p.acronimo,
           COUNT(r.id_revista)                                    AS articulos,
           SUM(CASE WHEN r.quartil IS NOT NULL THEN 1 ELSE 0 END) AS alto_impacto,
           SUM(CASE WHEN r.quartil IS NULL     THEN 1 ELSE 0 END) AS regionales,
           SUM(fn_puntaje_revista(r.quartil))                     AS puntaje_total,
           CASE WHEN SUM(fn_puntaje_revista(r.quartil)) >= 1
                THEN 'Cumple 1 punto' ELSE 'No cumple' END        AS evaluacion
      FROM publicacion_revista r
      JOIN productos pr             ON pr.id_producto = r.id_producto
      JOIN proyecto_investigacion p ON p.id_proyecto  = pr.id_proyecto
     GROUP BY p.acronimo
     ORDER BY puntaje_total DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_ca5_estado_proyectos` (IN `p_dias_aviso` INT)   BEGIN
    SELECT p.acronimo,
           DATE_FORMAT(p.inicio_pro, '%d/%m/%Y')                          AS inicio,
           DATE_FORMAT(fn_fin_vigente(p.fin_pro, p.prorroga), '%d/%m/%Y') AS fin_vigente,
           IF(p.prorroga IS NULL, 'No', 'Sí')                             AS prorroga,
           GREATEST(TIMESTAMPDIFF(MONTH, p.inicio_pro,
                         LEAST(CURDATE(), fn_fin_vigente(p.fin_pro, p.prorroga))), 0) AS meses_ejecucion,
           GREATEST(DATEDIFF(fn_fin_vigente(p.fin_pro, p.prorroga), CURDATE()), 0) AS dias_restantes,
           CASE WHEN p.resolucion_consejo_uni_cierre IS NOT NULL THEN 'Cerrado'
                WHEN p.inicio_pro > CURDATE() THEN 'Por iniciar'
                WHEN fn_fin_vigente(p.fin_pro, p.prorroga) < CURDATE() THEN 'Vencido sin cierre'
                WHEN fn_fin_vigente(p.fin_pro, p.prorroga)
                     <= DATE_ADD(CURDATE(), INTERVAL p_dias_aviso DAY) THEN 'Por finalizar'
                ELSE 'En ejecución' END                                   AS estado
      FROM proyecto_investigacion p
     ORDER BY FIELD(estado, 'Vencido sin cierre', 'Por finalizar', 'En ejecución', 'Por iniciar', 'Cerrado'),
              dias_restantes;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_cm1_equipo_proyecto` (IN `p_id_proyecto` INT UNSIGNED)   BEGIN
    SELECT p.acronimo, pp.cargo,
           CONCAT(pf.nombres, ' ', pf.apellidos)            AS nombre,
           pf.tipo, pf.despacho, pf.telefono,
           IF(p.id_investigador_principal = pf.id_profesor, 'Sí', 'No') AS investigador_principal,
           pp.fecha_inicio,
           IFNULL(pp.resolucion_ingreso, 'Desde el inicio') AS resolucion_ingreso
      FROM proyecto_investigacion p
     INNER JOIN proyecto_profesor pp ON pp.id_proyecto = p.id_proyecto
     INNER JOIN profesores pf        ON pf.id_profesor = pp.id_profesor
     WHERE (p_id_proyecto IS NULL OR p.id_proyecto = p_id_proyecto)
       AND pp.resolucion_salida IS NULL
       AND p.resolucion_consejo_uni_cierre IS NULL
     ORDER BY p.acronimo, pp.cargo, nombre;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_cm2_carga_profesores` ()   BEGIN
    SELECT CONCAT(pf.nombres, ' ', pf.apellidos)                     AS nombre,
           pf.tipo,
           COUNT(pp.id_proyecto)                                     AS proyectos_activos,
           IFNULL(GROUP_CONCAT(p.acronimo ORDER BY p.acronimo SEPARATOR ', '), '-') AS proyectos,
           CASE WHEN COUNT(pp.id_proyecto) = 0 THEN 'Disponible'
                WHEN COUNT(pp.id_proyecto) = 1 THEN 'Puede tomar 1 más'
                ELSE 'Límite alcanzado' END                          AS disponibilidad
      FROM profesores pf
      LEFT JOIN (proyecto_profesor pp
                 INNER JOIN proyecto_investigacion p
                         ON p.id_proyecto = pp.id_proyecto
                        AND p.resolucion_consejo_uni_cierre IS NULL)
             ON pp.id_profesor = pf.id_profesor
            AND pp.resolucion_salida IS NULL
     GROUP BY pf.id_profesor, pf.nombres, pf.apellidos, pf.tipo
     ORDER BY proyectos_activos DESC, nombre;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_cm3_estudiantes_por_proyecto` ()   BEGIN
    SELECT p.acronimo,
           COUNT(e.id_estudiante)                                       AS estudiantes,
           IFNULL(GROUP_CONCAT(e.nombres_est ORDER BY e.nombres_est SEPARATOR ', '), '-') AS nombres,
           IF(COUNT(e.id_estudiante) = 0, 'Sin estudiantes', 'Con estudiantes') AS observacion
      FROM proyecto_investigacion p
      LEFT JOIN estudiante e ON e.id_proyecto = p.id_proyecto
     GROUP BY p.id_proyecto, p.acronimo
     ORDER BY estudiantes DESC, p.acronimo;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_cm4_cobertura_lineas` ()   BEGIN
    SELECT l.codigo,
           l.nombre_linea,
           (SELECT COUNT(*) FROM linea_profesor lp
             WHERE lp.id_linea = l.id_linea)                         AS profesores,
           (SELECT COUNT(DISTINCT e.id_producto) FROM escribe e
             WHERE e.id_linea = l.id_linea)                          AS publicaciones,
           COUNT(p.id_proyecto)                                      AS proyectos,
           IFNULL(GROUP_CONCAT(p.acronimo ORDER BY p.acronimo SEPARATOR ', '), 'Ninguno') AS acronimos,
           IFNULL(SUM(p.presupuesto), 0)                             AS presupuesto_linea
      FROM proyecto_investigacion p
      JOIN proyecto_linea pl           ON pl.id_proyecto = p.id_proyecto
     RIGHT JOIN linea_investigacion l  ON l.id_linea     = pl.id_linea
     GROUP BY l.id_linea, l.codigo, l.nombre_linea
     ORDER BY proyectos DESC, l.nombre_linea;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_cm5_catalogo_productos` ()   BEGIN
    SELECT p.acronimo,
           pr.num_secuencia                    AS sec,
           LEFT(pr.titulo_publicacion, 40)     AS titulo,
           t.descripcion_tipo                  AS tipo,
           LEFT(COALESCE(CONCAT(r.nombre_revista, IFNULL(CONCAT(' (', r.quartil, ')'), ' (Regional)')),
                         CONCAT(c.nombre_congreso, ' - ', c.tipo_congreso),
                         CONCAT(le.nombre_editorial, ' - ISBN ', l.isbn),
                         CONCAT(pa.num_registro, ' - ', pa.estado)), 55) AS medio,
           IFNULL(CAST(COALESCE(c.fecha_inicio, l.fecha_publicacion, pa.fecha_solicitud) AS CHAR),
                  'No registra')               AS fecha
      FROM productos pr
     INNER JOIN proyecto_investigacion p ON p.id_proyecto  = pr.id_proyecto
     INNER JOIN tipo_pro t               ON t.id_tipo      = pr.id_tipo
      LEFT JOIN publicacion_revista r    ON r.id_producto  = pr.id_producto
      LEFT JOIN publicacion_congreso c   ON c.id_producto  = pr.id_producto
      LEFT JOIN libro l                  ON l.id_producto  = pr.id_producto
      LEFT JOIN editorial le             ON le.id_editorial = l.id_editorial
      LEFT JOIN patentes pa              ON pa.id_producto = pr.id_producto
     ORDER BY p.acronimo, pr.num_secuencia;
END$$

-- ============================================================================
-- PROCEDIMIENTOS TRANSACCIONALES
-- Todos registran el resultado en auditoria_operaciones y, ante cualquier
-- error, hacen ROLLBACK y relanzan el mensaje original.
-- ============================================================================

-- Auxiliares de catálogo: devuelven el id del nombre recibido y lo crean si
-- no existe. Nombre NULL o vacío -> id NULL. Se invocan desde los
-- procedimientos transaccionales (no se conceden a ningún rol).
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_aux_id_editorial` (IN `p_nombre` VARCHAR(150), OUT `p_id` INT UNSIGNED)   BEGIN
    SET p_id = NULL;
    IF TRIM(IFNULL(p_nombre,'')) <> '' THEN
        INSERT INTO editorial (nombre_editorial) VALUES (TRIM(p_nombre))
            ON DUPLICATE KEY UPDATE id_editorial = id_editorial;
        SELECT id_editorial INTO p_id FROM editorial WHERE nombre_editorial = TRIM(p_nombre);
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_aux_id_pais` (IN `p_nombre` VARCHAR(80), OUT `p_id` SMALLINT UNSIGNED)   BEGIN
    SET p_id = NULL;
    IF TRIM(IFNULL(p_nombre,'')) <> '' THEN
        INSERT INTO pais (nombre_pais) VALUES (TRIM(p_nombre))
            ON DUPLICATE KEY UPDATE id_pais = id_pais;
        SELECT id_pais INTO p_id FROM pais WHERE nombre_pais = TRIM(p_nombre);
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_proyecto_transaccional` (IN `p_nombre_proyecto` VARCHAR(200), IN `p_acronimo` VARCHAR(30), IN `p_presupuesto` DECIMAL(14,2), IN `p_programa` VARCHAR(150), IN `p_descripcion` TEXT, IN `p_inicio_pro` DATE, IN `p_fin_pro` DATE, IN `p_resolucion` VARCHAR(50), IN `p_id_investigador_principal` INT UNSIGNED)   BEGIN
    DECLARE v_id INT UNSIGNED;
    DECLARE v_id_programa SMALLINT UNSIGNED DEFAULT NULL;
    DECLARE v_tipo VARCHAR(10) DEFAULT NULL;
    DECLARE v_msg VARCHAR(255) DEFAULT '';
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
        ROLLBACK;
        INSERT INTO auditoria_operaciones (operacion,procedimiento_ejecutado,resultado)
        VALUES ('INSERT','sp_registrar_proyecto_transaccional',LEFT(CONCAT('FALLIDO - ',v_msg),255));
        SET v_msg = LEFT(CONCAT('Transaccion revertida: ',v_msg),255);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END;
    START TRANSACTION;
    IF p_fin_pro < p_inicio_pro THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='La fecha de fin no puede ser menor a la fecha de inicio.';
    END IF;
    SELECT tipo INTO v_tipo FROM profesores WHERE id_profesor=p_id_investigador_principal;
    IF v_tipo IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El investigador principal no existe.';
    END IF;
    IF v_tipo <> 'doctor' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El investigador principal debe ser doctor.';
    END IF;
    IF TRIM(IFNULL(p_programa,'')) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El programa de I+D es obligatorio.';
    END IF;
    INSERT INTO programa (nombre_programa) VALUES (TRIM(p_programa))
        ON DUPLICATE KEY UPDATE id_programa = id_programa;
    SELECT id_programa INTO v_id_programa FROM programa WHERE nombre_programa = TRIM(p_programa);
    INSERT INTO proyecto_investigacion
        (nombre_proyecto,acronimo,presupuesto,id_programa,descripcion,inicio_pro,fin_pro,
         id_investigador_principal,resolucion_consejo_uni_aprobado)
    VALUES
        (p_nombre_proyecto,p_acronimo,p_presupuesto,v_id_programa,p_descripcion,p_inicio_pro,p_fin_pro,
         p_id_investigador_principal,p_resolucion);
    SET v_id=LAST_INSERT_ID();
    -- SS7: el investigador principal participa en el proyecto desde su inicio
    INSERT INTO proyecto_profesor (id_proyecto,id_profesor,fecha_inicio,cargo,resolucion_ingreso)
    VALUES (v_id,p_id_investigador_principal,p_inicio_pro,'Director',p_resolucion);
    INSERT INTO resumen_proyecto (id_proyecto,total_productos) VALUES (v_id,0);
    INSERT INTO auditoria_operaciones (operacion,procedimiento_ejecutado,resultado)
    VALUES ('INSERT','sp_registrar_proyecto_transaccional',
            CONCAT('EXITOSO - Proyecto creado: ',p_acronimo));
    COMMIT;
END$$

-- Parámetros genéricos según p_id_tipo:
--   1 Revista : p_nombre=revista, p_editorial, p_dato_a=volumen, p_dato_b=cuartil ('' = regional),
--               p_dato_c=número, p_dato_d='pag_inicio-pag_fin'
--   2 Congreso: p_nombre=congreso, p_editorial=editorial de actas (opcional),
--               p_dato_a=tipo (Nacional|Internacional), p_dato_b=lugar, p_dato_c=país,
--               p_dato_d=tipo de participación, p_fecha_1/p_fecha_2=inicio/fin
--   3 Libro   : p_nombre=título, p_editorial, p_dato_a=ISBN, p_fecha_1=publicación
--   4 Patente : p_nombre, p_dato_a=nº registro, p_dato_b=país, p_dato_c=nº solicitud, p_fecha_1=solicitud
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_producto_transaccional` (IN `p_id_proyecto` INT UNSIGNED, IN `p_id_tipo` TINYINT UNSIGNED, IN `p_titulo` VARCHAR(255), IN `p_nombre` VARCHAR(200), IN `p_editorial` VARCHAR(150), IN `p_dato_a` VARCHAR(80), IN `p_dato_b` VARCHAR(150), IN `p_dato_c` VARCHAR(80), IN `p_dato_d` VARCHAR(80), IN `p_fecha_1` DATE, IN `p_fecha_2` DATE)   BEGIN
    DECLARE v_cierre VARCHAR(50);
    DECLARE v_existe INT DEFAULT 0;
    DECLARE v_sec INT UNSIGNED DEFAULT 1;
    DECLARE v_id INT UNSIGNED;
    DECLARE v_id_editorial INT UNSIGNED DEFAULT NULL;
    DECLARE v_id_pais SMALLINT UNSIGNED DEFAULT NULL;
    DECLARE v_msg VARCHAR(255) DEFAULT '';
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
        ROLLBACK;
        INSERT INTO auditoria_operaciones (operacion,procedimiento_ejecutado,resultado)
        VALUES ('INSERT','sp_registrar_producto_transaccional',LEFT(CONCAT('FALLIDO - ',v_msg),255));
        SET v_msg = LEFT(CONCAT('Transaccion revertida: ',v_msg),255);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END;
    START TRANSACTION;
    SELECT COUNT(*), MAX(resolucion_consejo_uni_cierre) INTO v_existe, v_cierre
      FROM proyecto_investigacion WHERE id_proyecto=p_id_proyecto;
    IF v_existe=0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El proyecto no existe.';
    END IF;
    IF v_cierre IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='No se pueden registrar productos en un proyecto cerrado.';
    END IF;
    IF p_id_tipo NOT IN (1,2,3,4) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Tipo de producto no valido.';
    END IF;
    SELECT IFNULL(MAX(num_secuencia),0)+1 INTO v_sec
      FROM productos WHERE id_proyecto=p_id_proyecto;
    INSERT INTO productos (id_proyecto,id_tipo,titulo_publicacion,num_secuencia)
    VALUES (p_id_proyecto,p_id_tipo,p_titulo,v_sec);
    SET v_id=LAST_INSERT_ID();
    CALL sp_aux_id_editorial(p_editorial, v_id_editorial);
    IF p_id_tipo=1 THEN
        INSERT INTO publicacion_revista (id_producto,nombre_revista,id_editorial,volumen,quartil,numero,pagina_inicio,pagina_fin)
        VALUES (v_id,p_nombre,v_id_editorial,p_dato_a,NULLIF(p_dato_b,''),NULLIF(p_dato_c,''),
                IF(IFNULL(p_dato_d,'')='',NULL,CAST(SUBSTRING_INDEX(p_dato_d,'-',1) AS UNSIGNED)),
                IF(IFNULL(p_dato_d,'')='',NULL,CAST(SUBSTRING_INDEX(p_dato_d,'-',-1) AS UNSIGNED)));
    ELSEIF p_id_tipo=2 THEN
        CALL sp_aux_id_pais(p_dato_c, v_id_pais);
        INSERT INTO publicacion_congreso (id_producto,nombre_congreso,tipo_congreso,fecha_inicio,fecha_fin,lugar_celebracion,id_pais,id_editorial_actas,tipo_participacion)
        VALUES (v_id,p_nombre,p_dato_a,p_fecha_1,p_fecha_2,p_dato_b,v_id_pais,v_id_editorial,p_dato_d);
    ELSEIF p_id_tipo=3 THEN
        INSERT INTO libro (id_producto,isbn,titulo_libro,id_editorial,fecha_publicacion)
        VALUES (v_id,p_dato_a,p_nombre,v_id_editorial,p_fecha_1);
    ELSE
        CALL sp_aux_id_pais(p_dato_b, v_id_pais);
        INSERT INTO patentes (num_registro,id_producto,nombre_patente,id_pais_registro,num_solicitud,fecha_solicitud)
        VALUES (p_dato_a,v_id,p_nombre,v_id_pais,p_dato_c,p_fecha_1);
    END IF;
    INSERT INTO auditoria_operaciones (operacion,procedimiento_ejecutado,resultado)
    VALUES ('INSERT','sp_registrar_producto_transaccional',
            CONCAT('EXITOSO - Producto ',v_id,' registrado para proyecto ID: ',p_id_proyecto));
    COMMIT;
END$$

-- Mismos parámetros genéricos que sp_registrar_producto_transaccional.
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_reclasificar_producto_transaccional` (IN `p_id_producto` INT UNSIGNED, IN `p_nuevo_tipo` TINYINT UNSIGNED, IN `p_nombre` VARCHAR(200), IN `p_editorial` VARCHAR(150), IN `p_dato_a` VARCHAR(80), IN `p_dato_b` VARCHAR(150), IN `p_dato_c` VARCHAR(80), IN `p_dato_d` VARCHAR(80), IN `p_fecha_1` DATE, IN `p_fecha_2` DATE)   BEGIN
    DECLARE v_tipo_actual TINYINT UNSIGNED DEFAULT NULL;
    DECLARE v_id_editorial INT UNSIGNED DEFAULT NULL;
    DECLARE v_id_pais SMALLINT UNSIGNED DEFAULT NULL;
    DECLARE v_msg VARCHAR(255) DEFAULT '';
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
        ROLLBACK;
        INSERT INTO auditoria_operaciones (operacion,procedimiento_ejecutado,resultado)
        VALUES ('UPDATE','sp_reclasificar_producto_transaccional',LEFT(CONCAT('FALLIDO - ',v_msg),255));
        SET v_msg = LEFT(CONCAT('Transaccion revertida: ',v_msg),255);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END;
    START TRANSACTION;
    SELECT id_tipo INTO v_tipo_actual FROM productos WHERE id_producto=p_id_producto;
    IF v_tipo_actual IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El producto no existe en la tabla padre.';
    END IF;
    IF p_nuevo_tipo NOT IN (1,2,3,4) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El nuevo tipo de producto no es valido.';
    END IF;
    IF p_nuevo_tipo=v_tipo_actual THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El nuevo tipo debe ser diferente al tipo ya registrado.';
    END IF;
    IF v_tipo_actual=1 THEN DELETE FROM publicacion_revista WHERE id_producto=p_id_producto;
    ELSEIF v_tipo_actual=2 THEN DELETE FROM publicacion_congreso WHERE id_producto=p_id_producto;
    ELSEIF v_tipo_actual=3 THEN DELETE FROM libro WHERE id_producto=p_id_producto;
    ELSEIF v_tipo_actual=4 THEN DELETE FROM patentes WHERE id_producto=p_id_producto;
    END IF;
    UPDATE productos SET id_tipo=p_nuevo_tipo WHERE id_producto=p_id_producto;
    CALL sp_aux_id_editorial(p_editorial, v_id_editorial);
    IF p_nuevo_tipo=1 THEN
        INSERT INTO publicacion_revista (id_producto,nombre_revista,id_editorial,volumen,quartil,numero,pagina_inicio,pagina_fin)
        VALUES (p_id_producto,p_nombre,v_id_editorial,p_dato_a,NULLIF(p_dato_b,''),NULLIF(p_dato_c,''),
                IF(IFNULL(p_dato_d,'')='',NULL,CAST(SUBSTRING_INDEX(p_dato_d,'-',1) AS UNSIGNED)),
                IF(IFNULL(p_dato_d,'')='',NULL,CAST(SUBSTRING_INDEX(p_dato_d,'-',-1) AS UNSIGNED)));
    ELSEIF p_nuevo_tipo=2 THEN
        CALL sp_aux_id_pais(p_dato_c, v_id_pais);
        INSERT INTO publicacion_congreso (id_producto,nombre_congreso,tipo_congreso,fecha_inicio,fecha_fin,lugar_celebracion,id_pais,id_editorial_actas,tipo_participacion)
        VALUES (p_id_producto,p_nombre,p_dato_a,p_fecha_1,p_fecha_2,p_dato_b,v_id_pais,v_id_editorial,p_dato_d);
    ELSEIF p_nuevo_tipo=3 THEN
        INSERT INTO libro (id_producto,isbn,titulo_libro,id_editorial,fecha_publicacion)
        VALUES (p_id_producto,p_dato_a,p_nombre,v_id_editorial,p_fecha_1);
    ELSE
        CALL sp_aux_id_pais(p_dato_b, v_id_pais);
        INSERT INTO patentes (num_registro,id_producto,nombre_patente,id_pais_registro,num_solicitud,fecha_solicitud)
        VALUES (p_dato_a,p_id_producto,p_nombre,v_id_pais,p_dato_c,p_fecha_1);
    END IF;
    INSERT INTO auditoria_operaciones (operacion,procedimiento_ejecutado,resultado)
    VALUES ('UPDATE','sp_reclasificar_producto_transaccional',
            CONCAT('EXITOSO - Producto ',p_id_producto,' reclasificado de tipo ',v_tipo_actual,' a ',p_nuevo_tipo));
    COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_control_prorroga_transaccional` (IN `p_id_proyecto` INT UNSIGNED, IN `p_nueva_fecha_fin` DATE)   BEGIN
    DECLARE v_cierre VARCHAR(50);
    DECLARE v_fin DATE;
    DECLARE v_prorroga DATE;
    DECLARE v_existe INT DEFAULT 0;
    DECLARE v_msg VARCHAR(255) DEFAULT '';
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
        ROLLBACK;
        INSERT INTO auditoria_operaciones (operacion,procedimiento_ejecutado,resultado)
        VALUES ('UPDATE','sp_control_prorroga_transaccional',LEFT(CONCAT('FALLIDO - ',v_msg),255));
        SET v_msg = LEFT(CONCAT('Transaccion revertida: ',v_msg),255);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END;
    START TRANSACTION;
    SELECT COUNT(*) INTO v_existe FROM proyecto_investigacion WHERE id_proyecto=p_id_proyecto;
    IF v_existe=0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El proyecto no existe.';
    END IF;
    SELECT resolucion_consejo_uni_cierre,fin_pro,prorroga INTO v_cierre,v_fin,v_prorroga
      FROM proyecto_investigacion WHERE id_proyecto=p_id_proyecto;
    IF v_cierre IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El proyecto esta cerrado, no admite prorroga.';
    END IF;
    IF v_prorroga IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El proyecto ya tiene una prorroga registrada.';
    END IF;
    IF p_nueva_fecha_fin <= v_fin THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='La nueva fecha debe ser mayor a la fecha de fin original.';
    END IF;
    IF p_nueva_fecha_fin > DATE_ADD(v_fin,INTERVAL 3 MONTH) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='La prorroga no puede exceder los 3 meses sobre la fecha de fin.';
    END IF;
    UPDATE proyecto_investigacion SET prorroga=p_nueva_fecha_fin WHERE id_proyecto=p_id_proyecto;
    INSERT INTO auditoria_operaciones (operacion,procedimiento_ejecutado,resultado)
    VALUES ('UPDATE','sp_control_prorroga_transaccional',
            CONCAT('EXITOSO - Prorroga registrada en proyecto ID: ',p_id_proyecto));
    COMMIT;
END$$

-- Cambia el Director (cargo administrativo UEB). El investigador principal
-- del proyecto (proyecto_investigacion.id_investigador_principal) no cambia.
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_cambio_director_transaccional` (IN `p_id_proyecto` INT UNSIGNED, IN `p_id_docente_saliente` INT UNSIGNED, IN `p_id_docente_entrante` INT UNSIGNED, IN `p_resolucion_salida` VARCHAR(50), IN `p_motivo_salida` VARCHAR(200), IN `p_resolucion_ingreso` VARCHAR(50))   BEGIN
    DECLARE v_cierre VARCHAR(50);
    DECLARE v_inicio DATE;
    DECLARE v_existe INT DEFAULT 0;
    DECLARE v_saliente_activo INT DEFAULT 0;
    DECLARE v_msg VARCHAR(255) DEFAULT '';
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
        ROLLBACK;
        INSERT INTO auditoria_operaciones (operacion,procedimiento_ejecutado,resultado)
        VALUES ('UPDATE','sp_cambio_director_transaccional',LEFT(CONCAT('FALLIDO - ',v_msg),255));
        SET v_msg = LEFT(CONCAT('Transaccion revertida: ',v_msg),255);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END;
    START TRANSACTION;
    SELECT COUNT(*), MAX(resolucion_consejo_uni_cierre), MAX(inicio_pro) INTO v_existe, v_cierre, v_inicio
      FROM proyecto_investigacion WHERE id_proyecto=p_id_proyecto;
    IF v_existe=0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El proyecto no existe.';
    END IF;
    IF v_cierre IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El proyecto esta cerrado. No se puede cambiar de director.';
    END IF;
    SELECT COUNT(*) INTO v_saliente_activo
      FROM proyecto_profesor
     WHERE id_proyecto=p_id_proyecto
       AND id_profesor=p_id_docente_saliente
       AND cargo='Director'
       AND resolucion_salida IS NULL;
    IF v_saliente_activo=0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El docente saliente no es Director activo de este proyecto.';
    END IF;
    UPDATE proyecto_profesor
       SET resolucion_salida=p_resolucion_salida, motivo_salida=p_motivo_salida,
           fecha_fin=GREATEST(fecha_inicio,CURDATE())
     WHERE id_proyecto=p_id_proyecto AND id_profesor=p_id_docente_saliente
       AND resolucion_salida IS NULL;
    INSERT INTO proyecto_profesor (id_proyecto,id_profesor,fecha_inicio,cargo,resolucion_ingreso)
    VALUES (p_id_proyecto,p_id_docente_entrante,GREATEST(CURDATE(),v_inicio),'Director',p_resolucion_ingreso);
    INSERT INTO auditoria_operaciones (operacion,procedimiento_ejecutado,resultado)
    VALUES ('UPDATE','sp_cambio_director_transaccional',
            CONCAT('EXITOSO - Cambio de director en proyecto ID: ',p_id_proyecto));
    COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_control_responsables_transaccional` (IN `p_id_proyecto` INT UNSIGNED, IN `p_id_director_saliente` INT UNSIGNED, IN `p_id_nuevo_subrogante` INT UNSIGNED, IN `p_resolucion_salida` VARCHAR(50), IN `p_motivo_salida` VARCHAR(200), IN `p_resolucion_ingreso` VARCHAR(50))   BEGIN
    DECLARE v_cierre VARCHAR(50);
    DECLARE v_inicio DATE;
    DECLARE v_existe INT DEFAULT 0;
    DECLARE v_dir_activo INT DEFAULT 0;
    DECLARE v_sub_activo INT DEFAULT 0;
    DECLARE v_msg VARCHAR(255) DEFAULT '';
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
        ROLLBACK;
        INSERT INTO auditoria_operaciones (operacion,procedimiento_ejecutado,resultado)
        VALUES ('UPDATE','sp_control_responsables_transaccional',LEFT(CONCAT('FALLIDO - ',v_msg),255));
        SET v_msg = LEFT(CONCAT('Transaccion revertida: ',v_msg),255);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END;
    START TRANSACTION;
    SELECT COUNT(*), MAX(resolucion_consejo_uni_cierre), MAX(inicio_pro) INTO v_existe, v_cierre, v_inicio
      FROM proyecto_investigacion WHERE id_proyecto=p_id_proyecto;
    IF v_existe=0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El proyecto no existe.';
    END IF;
    IF v_cierre IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El proyecto esta cerrado, no admite relevo.';
    END IF;
    SELECT COUNT(*) INTO v_dir_activo
      FROM proyecto_profesor
     WHERE id_proyecto=p_id_proyecto
       AND id_profesor=p_id_director_saliente
       AND cargo='Director'
       AND resolucion_salida IS NULL;
    IF v_dir_activo=0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El Director saliente no esta activo en el proyecto.';
    END IF;
    SELECT COUNT(*) INTO v_sub_activo
      FROM proyecto_profesor
     WHERE id_proyecto=p_id_proyecto
       AND cargo='Director subrogante'
       AND resolucion_salida IS NULL;
    IF v_sub_activo=0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El proyecto no tiene Director subrogante activo para ascender.';
    END IF;
    UPDATE proyecto_profesor
       SET resolucion_salida=p_resolucion_salida, motivo_salida=p_motivo_salida,
           fecha_fin=GREATEST(fecha_inicio,CURDATE())
     WHERE id_proyecto=p_id_proyecto AND id_profesor=p_id_director_saliente
       AND resolucion_salida IS NULL;
    UPDATE proyecto_profesor
       SET cargo='Director'
     WHERE id_proyecto=p_id_proyecto
       AND cargo='Director subrogante'
       AND resolucion_salida IS NULL;
    INSERT INTO proyecto_profesor (id_proyecto,id_profesor,fecha_inicio,cargo,resolucion_ingreso)
    VALUES (p_id_proyecto,p_id_nuevo_subrogante,GREATEST(CURDATE(),v_inicio),'Director subrogante',p_resolucion_ingreso);
    INSERT INTO auditoria_operaciones (operacion,procedimiento_ejecutado,resultado)
    VALUES ('UPDATE','sp_control_responsables_transaccional',
            CONCAT('EXITOSO - Relevo de direccion en proyecto ID: ',p_id_proyecto));
    COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_desvincular_cierre_transaccional` (IN `p_id_proyecto` INT UNSIGNED)   BEGIN
    DECLARE v_cierre VARCHAR(50);
    DECLARE v_existe INT DEFAULT 0;
    DECLARE v_docentes INT DEFAULT 0;
    DECLARE v_estud INT DEFAULT 0;
    DECLARE v_msg VARCHAR(255) DEFAULT '';
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
        ROLLBACK;
        INSERT INTO auditoria_operaciones (operacion,procedimiento_ejecutado,resultado)
        VALUES ('UPDATE','sp_desvincular_cierre_transaccional',LEFT(CONCAT('FALLIDO - ',v_msg),255));
        SET v_msg = LEFT(CONCAT('Transaccion revertida: ',v_msg),255);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END;
    START TRANSACTION;
    SELECT COUNT(*),MAX(resolucion_consejo_uni_cierre) INTO v_existe,v_cierre
      FROM proyecto_investigacion WHERE id_proyecto=p_id_proyecto;
    IF v_existe=0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El proyecto no existe.';
    END IF;
    IF v_cierre IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El proyecto no se encuentra formalmente cerrado.';
    END IF;
    SELECT COUNT(*) INTO v_docentes
      FROM proyecto_profesor
     WHERE id_proyecto=p_id_proyecto AND resolucion_salida IS NULL;
    SELECT COUNT(*) INTO v_estud FROM estudiante WHERE id_proyecto=p_id_proyecto;
    IF v_docentes=0 AND v_estud=0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El proyecto no tiene personal ni estudiantes activos que desvincular.';
    END IF;
    UPDATE proyecto_profesor
       SET resolucion_salida=v_cierre, motivo_salida='Finalizacion oficial del proyecto',
           fecha_fin=GREATEST(fecha_inicio,CURDATE())
     WHERE id_proyecto=p_id_proyecto AND resolucion_salida IS NULL;
    DELETE FROM estudiante WHERE id_proyecto=p_id_proyecto;
    UPDATE resumen_proyecto SET ultima_actualizacion=NOW() WHERE id_proyecto=p_id_proyecto;
    INSERT INTO auditoria_operaciones (operacion,procedimiento_ejecutado,resultado)
    VALUES ('UPDATE','sp_desvincular_cierre_transaccional',
            CONCAT('EXITOSO - Desvinculacion por cierre del proyecto ID: ',p_id_proyecto));
    COMMIT;
END$$

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Profesores: un doctor no puede pasar a no doctor si es investigador
-- principal o supervisa a alguien.
CREATE DEFINER=`root`@`localhost` TRIGGER `trg_profesor_bu` BEFORE UPDATE ON `profesores` FOR EACH ROW BEGIN
    IF OLD.tipo = 'doctor' AND NEW.tipo = 'no_doctor' THEN
        IF EXISTS (SELECT 1 FROM proyecto_investigacion WHERE id_investigador_principal = OLD.id_profesor)
           OR EXISTS (SELECT 1 FROM supervision WHERE id_doctor = OLD.id_profesor) THEN
            SIGNAL SQLSTATE '45000'
               SET MESSAGE_TEXT = 'El profesor es investigador principal o supervisor; no puede dejar de ser doctor.';
        END IF;
    END IF;
END$$

-- Supervisa: doctor -> no doctor, sin supervisiones simultáneas (SS4)
CREATE DEFINER=`root`@`localhost` TRIGGER `trg_supervision_bi` BEFORE INSERT ON `supervision` FOR EACH ROW BEGIN
    IF IFNULL((SELECT tipo FROM profesores WHERE id_profesor = NEW.id_doctor), '') <> 'doctor' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El supervisor debe ser un profesor doctor.';
    END IF;
    IF IFNULL((SELECT tipo FROM profesores WHERE id_profesor = NEW.id_no_doctor), '') <> 'no_doctor' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo se supervisa a profesores no doctores.';
    END IF;
    IF EXISTS (SELECT 1 FROM supervision s
                WHERE s.id_no_doctor = NEW.id_no_doctor
                  AND NEW.fecha_inicio <= IFNULL(s.fecha_fin, '9999-12-31')
                  AND s.fecha_inicio <= IFNULL(NEW.fecha_fin, '9999-12-31')) THEN
        SIGNAL SQLSTATE '45000'
           SET MESSAGE_TEXT = 'El profesor no doctor ya tiene un supervisor en ese periodo (SS4).';
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` TRIGGER `trg_supervision_bu` BEFORE UPDATE ON `supervision` FOR EACH ROW BEGIN
    IF IFNULL((SELECT tipo FROM profesores WHERE id_profesor = NEW.id_doctor), '') <> 'doctor' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El supervisor debe ser un profesor doctor.';
    END IF;
    IF IFNULL((SELECT tipo FROM profesores WHERE id_profesor = NEW.id_no_doctor), '') <> 'no_doctor' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo se supervisa a profesores no doctores.';
    END IF;
    IF EXISTS (SELECT 1 FROM supervision s
                WHERE s.id_no_doctor = NEW.id_no_doctor
                  AND NOT (s.id_no_doctor = OLD.id_no_doctor AND s.fecha_inicio = OLD.fecha_inicio)
                  AND NEW.fecha_inicio <= IFNULL(s.fecha_fin, '9999-12-31')
                  AND s.fecha_inicio <= IFNULL(NEW.fecha_fin, '9999-12-31')) THEN
        SIGNAL SQLSTATE '45000'
           SET MESSAGE_TEXT = 'El profesor no doctor ya tiene un supervisor en ese periodo (SS4).';
    END IF;
END$$

-- Investigador principal: siempre doctor y nunca varía
CREATE DEFINER=`root`@`localhost` TRIGGER `trg_proyecto_bi` BEFORE INSERT ON `proyecto_investigacion` FOR EACH ROW BEGIN
    IF IFNULL((SELECT tipo FROM profesores WHERE id_profesor = NEW.id_investigador_principal), '') <> 'doctor' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El investigador principal debe ser un profesor doctor.';
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` TRIGGER `trg_proyecto_bu` BEFORE UPDATE ON `proyecto_investigacion` FOR EACH ROW BEGIN
    IF NEW.id_investigador_principal <> OLD.id_investigador_principal THEN
        SIGNAL SQLSTATE '45000'
           SET MESSAGE_TEXT = 'El investigador principal de un proyecto nunca varía.';
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` TRIGGER `trg_auditoria_proyecto_upd` AFTER UPDATE ON `proyecto_investigacion` FOR EACH ROW BEGIN
    INSERT INTO auditoria_proyecto (id_proyecto, operacion, datos_anteriores, datos_nuevos, usuario)
    VALUES (OLD.id_proyecto, 'UPDATE',
            CONCAT('acronimo=', OLD.acronimo, '; presupuesto=', OLD.presupuesto,
                   '; fin_pro=', OLD.fin_pro, '; prorroga=', IFNULL(OLD.prorroga, '-'),
                   '; cierre=', IFNULL(OLD.resolucion_consejo_uni_cierre, '-')),
            CONCAT('acronimo=', NEW.acronimo, '; presupuesto=', NEW.presupuesto,
                   '; fin_pro=', NEW.fin_pro, '; prorroga=', IFNULL(NEW.prorroga, '-'),
                   '; cierre=', IFNULL(NEW.resolucion_consejo_uni_cierre, '-')),
            USER());
END$$

CREATE DEFINER=`root`@`localhost` TRIGGER `trg_auditoria_proyecto_del` AFTER DELETE ON `proyecto_investigacion` FOR EACH ROW BEGIN
    INSERT INTO auditoria_proyecto (id_proyecto, operacion, datos_anteriores, datos_nuevos, usuario)
    VALUES (OLD.id_proyecto, 'DELETE',
            CONCAT('nombre=', OLD.nombre_proyecto, '; acronimo=', OLD.acronimo,
                   '; presupuesto=', OLD.presupuesto),
            NULL, USER());
END$$

-- Participa: reglas UEB + sin solapamiento de periodos (SS1)
CREATE DEFINER=`root`@`localhost` TRIGGER `trg_validar_participacion` BEFORE INSERT ON `proyecto_profesor` FOR EACH ROW BEGIN
    DECLARE v_cierre   VARCHAR(50);
    DECLARE v_mismo    INT DEFAULT 0;
    DECLARE v_no_dir   INT DEFAULT 0;
    DECLARE v_equipo   INT DEFAULT 0;

    SELECT resolucion_consejo_uni_cierre INTO v_cierre
      FROM proyecto_investigacion WHERE id_proyecto = NEW.id_proyecto;

    IF v_cierre IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
           SET MESSAGE_TEXT = 'El proyecto ya está cerrado y no admite nuevos profesores.';
    END IF;

    IF EXISTS (SELECT 1 FROM proyecto_profesor pp
                WHERE pp.id_proyecto = NEW.id_proyecto
                  AND pp.id_profesor = NEW.id_profesor
                  AND NEW.fecha_inicio <= IFNULL(pp.fecha_fin, '9999-12-31')
                  AND pp.fecha_inicio <= IFNULL(NEW.fecha_fin, '9999-12-31')) THEN
        SIGNAL SQLSTATE '45000'
           SET MESSAGE_TEXT = 'El periodo se solapa con otra participación del profesor en el proyecto (SS1).';
    END IF;

    IF NEW.cargo IN ('Director', 'Director subrogante') AND NEW.resolucion_salida IS NULL THEN
        SELECT COUNT(*) INTO v_mismo
          FROM proyecto_profesor
         WHERE id_proyecto = NEW.id_proyecto
           AND cargo = NEW.cargo
           AND resolucion_salida IS NULL;
        IF v_mismo >= 1 THEN
            SIGNAL SQLSTATE '45000'
               SET MESSAGE_TEXT = 'El proyecto ya tiene un profesor activo con ese cargo.';
        END IF;
    END IF;

    IF NEW.cargo <> 'Director' AND NEW.resolucion_salida IS NULL THEN
        SELECT COUNT(*) INTO v_no_dir
          FROM proyecto_profesor
         WHERE id_proyecto = NEW.id_proyecto
           AND cargo <> 'Director'
           AND resolucion_salida IS NULL;
        IF v_no_dir >= 4 THEN
            SIGNAL SQLSTATE '45000'
               SET MESSAGE_TEXT = 'El proyecto ya tiene 4 investigadores activos, que es el máximo permitido.';
        END IF;
    END IF;

    IF NEW.resolucion_salida IS NULL AND fn_proyectos_activos(NEW.id_profesor) >= 2 THEN
        SIGNAL SQLSTATE '45000'
           SET MESSAGE_TEXT = 'El profesor ya participa en 2 proyectos activos, que es el máximo permitido.';
    END IF;

    SELECT COUNT(*) INTO v_equipo
      FROM proyecto_profesor
     WHERE id_proyecto = NEW.id_proyecto AND resolucion_salida IS NULL;
    SET NEW.num_profesores = v_equipo + 1;
END$$

CREATE DEFINER=`root`@`localhost` TRIGGER `trg_participacion_bu` BEFORE UPDATE ON `proyecto_profesor` FOR EACH ROW BEGIN
    IF EXISTS (SELECT 1 FROM proyecto_profesor pp
                WHERE pp.id_proyecto = NEW.id_proyecto
                  AND pp.id_profesor = NEW.id_profesor
                  AND NOT (pp.id_proyecto = OLD.id_proyecto
                           AND pp.id_profesor = OLD.id_profesor
                           AND pp.fecha_inicio = OLD.fecha_inicio)
                  AND NEW.fecha_inicio <= IFNULL(pp.fecha_fin, '9999-12-31')
                  AND pp.fecha_inicio <= IFNULL(NEW.fecha_fin, '9999-12-31')) THEN
        SIGNAL SQLSTATE '45000'
           SET MESSAGE_TEXT = 'El periodo se solapa con otra participación del profesor en el proyecto (SS1).';
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` TRIGGER `trg_historial_participacion` AFTER UPDATE ON `proyecto_profesor` FOR EACH ROW BEGIN
    IF NOT (OLD.cargo <=> NEW.cargo)
       OR NOT (OLD.resolucion_salida <=> NEW.resolucion_salida) THEN
        INSERT INTO historial_participacion
               (id_proyecto, id_profesor, cargo_anterior, cargo_nuevo,
                resolucion_salida, motivo_salida, usuario)
        VALUES (OLD.id_proyecto, OLD.id_profesor, OLD.cargo, NEW.cargo,
                NEW.resolucion_salida, NEW.motivo_salida, USER());
    END IF;
END$$

-- Productos: mantenimiento de resumen_proyecto
CREATE DEFINER=`root`@`localhost` TRIGGER `trg_resumen_producto_ins` AFTER INSERT ON `productos` FOR EACH ROW BEGIN
    INSERT INTO resumen_proyecto (id_proyecto, total_productos, ultima_actualizacion)
    VALUES (NEW.id_proyecto, 1, NOW())
    ON DUPLICATE KEY UPDATE total_productos      = total_productos + 1,
                            ultima_actualizacion = NOW();
END$$

CREATE DEFINER=`root`@`localhost` TRIGGER `trg_resumen_producto_del` AFTER DELETE ON `productos` FOR EACH ROW BEGIN
    UPDATE resumen_proyecto
       SET total_productos      = IF(total_productos > 0, total_productos - 1, 0),
           ultima_actualizacion = NOW()
     WHERE id_proyecto = OLD.id_proyecto;
END$$

-- Subtipos de producto: la fila del subtipo debe coincidir con productos.id_tipo
-- (sustituye a la columna id_tipo que antes se copiaba en cada subtipo).
CREATE DEFINER=`root`@`localhost` TRIGGER `trg_revista_bi` BEFORE INSERT ON `publicacion_revista` FOR EACH ROW BEGIN
    IF NOT EXISTS (SELECT 1 FROM productos WHERE id_producto = NEW.id_producto AND id_tipo = 1) THEN
        SIGNAL SQLSTATE '45000'
           SET MESSAGE_TEXT = 'El producto no es de tipo Revista.';
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` TRIGGER `trg_libro_bi` BEFORE INSERT ON `libro` FOR EACH ROW BEGIN
    IF NOT EXISTS (SELECT 1 FROM productos WHERE id_producto = NEW.id_producto AND id_tipo = 3) THEN
        SIGNAL SQLSTATE '45000'
           SET MESSAGE_TEXT = 'El producto no es de tipo Libro.';
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` TRIGGER `trg_patente_bi` BEFORE INSERT ON `patentes` FOR EACH ROW BEGIN
    IF NOT EXISTS (SELECT 1 FROM productos WHERE id_producto = NEW.id_producto AND id_tipo = 4) THEN
        SIGNAL SQLSTATE '45000'
           SET MESSAGE_TEXT = 'El producto no es de tipo Patente.';
    END IF;
END$$

-- Congreso: el producto debe ser de tipo Congreso y no anterior al inicio
-- del proyecto (SS15)
CREATE DEFINER=`root`@`localhost` TRIGGER `trg_congreso_bi` BEFORE INSERT ON `publicacion_congreso` FOR EACH ROW BEGIN
    IF NOT EXISTS (SELECT 1 FROM productos WHERE id_producto = NEW.id_producto AND id_tipo = 2) THEN
        SIGNAL SQLSTATE '45000'
           SET MESSAGE_TEXT = 'El producto no es de tipo Congreso.';
    END IF;
    IF NEW.fecha_inicio < (SELECT p.inicio_pro
                             FROM productos pr
                             JOIN proyecto_investigacion p ON p.id_proyecto = pr.id_proyecto
                            WHERE pr.id_producto = NEW.id_producto) THEN
        SIGNAL SQLSTATE '45000'
           SET MESSAGE_TEXT = 'El congreso no puede iniciar antes que el proyecto de investigación (SS15).';
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` TRIGGER `trg_congreso_bu` BEFORE UPDATE ON `publicacion_congreso` FOR EACH ROW BEGIN
    IF NEW.fecha_inicio < (SELECT p.inicio_pro
                             FROM productos pr
                             JOIN proyecto_investigacion p ON p.id_proyecto = pr.id_proyecto
                            WHERE pr.id_producto = NEW.id_producto) THEN
        SIGNAL SQLSTATE '45000'
           SET MESSAGE_TEXT = 'El congreso no puede iniciar antes que el proyecto de investigación (SS15).';
    END IF;
END$$

-- Incluye: el proyecto solo incluye líneas de sus profesores (SS10)
CREATE DEFINER=`root`@`localhost` TRIGGER `trg_proyecto_linea_bi` BEFORE INSERT ON `proyecto_linea` FOR EACH ROW BEGIN
    IF NOT EXISTS (SELECT 1
                     FROM proyecto_profesor pp
                     JOIN linea_profesor lp ON lp.id_profesor = pp.id_profesor
                    WHERE pp.id_proyecto = NEW.id_proyecto
                      AND lp.id_linea = NEW.id_linea) THEN
        SIGNAL SQLSTATE '45000'
           SET MESSAGE_TEXT = 'Ningún profesor del proyecto desarrolla esa línea de investigación (SS10).';
    END IF;
END$$

-- Escribe: SS8, SS9 y SS11
CREATE DEFINER=`root`@`localhost` TRIGGER `trg_escribe_bi` BEFORE INSERT ON `escribe` FOR EACH ROW BEGIN
    DECLARE v_proyecto INT UNSIGNED;
    SELECT id_proyecto INTO v_proyecto FROM productos WHERE id_producto = NEW.id_producto;
    IF NOT EXISTS (SELECT 1 FROM linea_profesor
                    WHERE id_profesor = NEW.id_profesor AND id_linea = NEW.id_linea) THEN
        SIGNAL SQLSTATE '45000'
           SET MESSAGE_TEXT = 'El profesor no desarrolla esa línea de investigación (SS8).';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM proyecto_profesor
                    WHERE id_proyecto = v_proyecto AND id_profesor = NEW.id_profesor) THEN
        SIGNAL SQLSTATE '45000'
           SET MESSAGE_TEXT = 'El profesor no trabaja en el proyecto de la publicación (SS9).';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM proyecto_linea
                    WHERE id_proyecto = v_proyecto AND id_linea = NEW.id_linea) THEN
        SIGNAL SQLSTATE '45000'
           SET MESSAGE_TEXT = 'La línea no está incluida en el proyecto de la publicación (SS11).';
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` TRIGGER `trg_escribe_bu` BEFORE UPDATE ON `escribe` FOR EACH ROW BEGIN
    DECLARE v_proyecto INT UNSIGNED;
    SELECT id_proyecto INTO v_proyecto FROM productos WHERE id_producto = NEW.id_producto;
    IF NOT EXISTS (SELECT 1 FROM linea_profesor
                    WHERE id_profesor = NEW.id_profesor AND id_linea = NEW.id_linea) THEN
        SIGNAL SQLSTATE '45000'
           SET MESSAGE_TEXT = 'El profesor no desarrolla esa línea de investigación (SS8).';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM proyecto_profesor
                    WHERE id_proyecto = v_proyecto AND id_profesor = NEW.id_profesor) THEN
        SIGNAL SQLSTATE '45000'
           SET MESSAGE_TEXT = 'El profesor no trabaja en el proyecto de la publicación (SS9).';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM proyecto_linea
                    WHERE id_proyecto = v_proyecto AND id_linea = NEW.id_linea) THEN
        SIGNAL SQLSTATE '45000'
           SET MESSAGE_TEXT = 'La línea no está incluida en el proyecto de la publicación (SS11).';
    END IF;
END$$

DELIMITER ;

-- ============================================================================
-- VISTAS PERSONALES (filtran por la cuenta conectada: USER() devuelve al
-- invocador incluso dentro de una vista SQL SECURITY DEFINER)
-- ============================================================================

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_docente_mis_proyectos` AS
SELECT p.acronimo, p.nombre_proyecto, pp.cargo, pp.fecha_inicio, pp.fecha_fin,
       IF(p.id_investigador_principal = pf.id_profesor, 'Sí', 'No') AS investigador_principal,
       p.presupuesto, p.inicio_pro, p.fin_pro
  FROM proyecto_investigacion p
  JOIN proyecto_profesor pp ON pp.id_proyecto = p.id_proyecto
  JOIN profesores pf        ON pf.id_profesor = pp.id_profesor
 WHERE pf.db_usuario = SUBSTRING_INDEX(USER(), '@', 1);

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_docente_mi_equipo` AS
SELECT p.acronimo, pp.cargo, CONCAT(pf.nombres, ' ', pf.apellidos) AS nombre,
       pf.despacho, pf.telefono, pp.fecha_inicio
  FROM proyecto_investigacion p
  JOIN proyecto_profesor pp ON pp.id_proyecto = p.id_proyecto
  JOIN profesores pf        ON pf.id_profesor = pp.id_profesor
 WHERE pp.resolucion_salida IS NULL
   AND p.id_proyecto IN (SELECT pp2.id_proyecto
                           FROM proyecto_profesor pp2
                           JOIN profesores yo ON yo.id_profesor = pp2.id_profesor
                          WHERE yo.db_usuario = SUBSTRING_INDEX(USER(), '@', 1)
                            AND pp2.resolucion_salida IS NULL);

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_docente_mis_publicaciones` AS
SELECT p.acronimo, pr.num_secuencia, pr.titulo_publicacion, t.descripcion_tipo AS tipo,
       l.codigo AS codigo_linea, l.nombre_linea
  FROM escribe e
  JOIN profesores pf            ON pf.id_profesor = e.id_profesor
  JOIN productos pr             ON pr.id_producto = e.id_producto
  JOIN proyecto_investigacion p ON p.id_proyecto  = pr.id_proyecto
  JOIN tipo_pro t               ON t.id_tipo      = pr.id_tipo
  JOIN linea_investigacion l    ON l.id_linea     = e.id_linea
 WHERE pf.db_usuario = SUBSTRING_INDEX(USER(), '@', 1);

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_estudiante_mis_proyectos` AS
SELECT p.acronimo, p.nombre_proyecto, e.nombres_est, f.nombre_facultad AS facultad
  FROM proyecto_investigacion p
  JOIN estudiante e ON e.id_proyecto = p.id_proyecto
  JOIN facultad f   ON f.id_facultad = e.id_facultad
 WHERE e.db_usuario = SUBSTRING_INDEX(USER(), '@', 1);

SET FOREIGN_KEY_CHECKS = 1;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

-- ############################################################################
-- PARTE B: ROLES, CUENTAS Y PERMISOS
-- ############################################################################
-- ============================================================================
-- CONTROL DE USUARIOS, ROLES Y PERMISOS - gestion_investigacion
-- Versión SQL de Usuarios.txt (MariaDB 11.8). Requiere que el esquema,
-- los procedimientos y las vistas ya existan.
-- ----------------------------------------------------------------------------
-- Modelo: cada perfil es un ROL; cada persona tiene su propia cuenta con su
-- rol por defecto. Las vistas vw_docente_* y vw_estudiante_* filtran por la
-- cuenta conectada (columna db_usuario de profesores / estudiante).
--
-- Cuentas y contraseñas iniciales (cambiar en el primer acceso):
--   Rol               Cuenta              Contraseña
--   rol_admin         patricio.lara       Ueb#Lara-Adm26
--   rol_secretaria    monica.cardenas     Ueb#Cardenas-Sec26
--   rol_coordinador   santiago.borja      Ueb#Borja-Coo26
--   rol_director_inv  elena.mosquera      Ueb#Mosquera-Dir26
--   rol_profesor      <nombre.apellido>   Ueb#<Apellido>-Doc26   (13 cuentas)
--   rol_estudiante    <nombre.apellido>   Ueb#<Apellido>-Est26   (7 cuentas)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. LIMPIEZA (idempotente; incluye las cuentas genéricas anteriores)
-- ----------------------------------------------------------------------------
DROP USER IF EXISTS 'admin_sistema'@'localhost', 'secretaria'@'localhost',
                    'coordinador'@'localhost', 'director_inv'@'localhost',
                    'profesor'@'localhost', 'estudiante'@'localhost';

DROP USER IF EXISTS 'patricio.lara'@'localhost', 'monica.cardenas'@'localhost',
                    'santiago.borja'@'localhost', 'elena.mosquera'@'localhost';

DROP USER IF EXISTS 'carlos.villacres'@'localhost', 'maria.gavilanes'@'localhost',
                    'luis.chimbo'@'localhost', 'ana.arellano'@'localhost',
                    'jorge.naranjo'@'localhost', 'diana.pazmino'@'localhost',
                    'hector.sanchez'@'localhost', 'gabriela.mora'@'localhost',
                    'ramiro.guaman'@'localhost', 'paola.salazar'@'localhost',
                    'edison.lombeida'@'localhost', 'veronica.coello'@'localhost',
                    'fausto.escobar'@'localhost';

DROP USER IF EXISTS 'andony.cortez'@'localhost', 'jonathan.ayme'@'localhost',
                    'bryan.ruiz'@'localhost', 'lizbeth.tixi'@'localhost',
                    'jonathan.sisa'@'localhost', 'erika.gaibor'@'localhost',
                    'marco.paredes'@'localhost';

DROP ROLE IF EXISTS rol_admin, rol_secretaria, rol_coordinador,
                    rol_director_inv, rol_profesor, rol_estudiante;

-- ----------------------------------------------------------------------------
-- 2. ROLES Y PERMISOS
-- ----------------------------------------------------------------------------
CREATE ROLE rol_admin;
CREATE ROLE rol_secretaria;
CREATE ROLE rol_coordinador;
CREATE ROLE rol_director_inv;
CREATE ROLE rol_profesor;
CREATE ROLE rol_estudiante;

-- A. ADMINISTRADOR DEL SISTEMA: acceso total al esquema
GRANT ALL PRIVILEGES ON gestion_investigacion.* TO rol_admin;

-- B. SECRETARÍA: solo procedimientos (sin acceso directo a tablas)
GRANT EXECUTE ON PROCEDURE gestion_investigacion.sp_registrar_proyecto_transaccional    TO rol_secretaria;
GRANT EXECUTE ON PROCEDURE gestion_investigacion.sp_registrar_producto_transaccional    TO rol_secretaria;
GRANT EXECUTE ON PROCEDURE gestion_investigacion.sp_reclasificar_producto_transaccional TO rol_secretaria;
GRANT EXECUTE ON PROCEDURE gestion_investigacion.sp_control_prorroga_transaccional      TO rol_secretaria;
GRANT EXECUTE ON PROCEDURE gestion_investigacion.sp_cambio_director_transaccional       TO rol_secretaria;
GRANT EXECUTE ON PROCEDURE gestion_investigacion.sp_control_responsables_transaccional  TO rol_secretaria;
GRANT EXECUTE ON PROCEDURE gestion_investigacion.sp_desvincular_cierre_transaccional    TO rol_secretaria;
GRANT EXECUTE ON PROCEDURE gestion_investigacion.sp_cm1_equipo_proyecto                 TO rol_secretaria;
GRANT EXECUTE ON PROCEDURE gestion_investigacion.sp_cm2_carga_profesores                TO rol_secretaria;
GRANT EXECUTE ON PROCEDURE gestion_investigacion.sp_cm3_estudiantes_por_proyecto        TO rol_secretaria;

-- C. COORDINADOR: lectura de las tablas del negocio (sin auditoría ni datos
--    de contacto de estudiantes) y todos los reportes
GRANT SELECT ON gestion_investigacion.proyecto_investigacion TO rol_coordinador;
GRANT SELECT ON gestion_investigacion.profesores             TO rol_coordinador;
GRANT SELECT ON gestion_investigacion.supervision            TO rol_coordinador;
GRANT SELECT ON gestion_investigacion.proyecto_profesor      TO rol_coordinador;
GRANT SELECT ON gestion_investigacion.tipo_pro               TO rol_coordinador;
GRANT SELECT ON gestion_investigacion.productos              TO rol_coordinador;
GRANT SELECT ON gestion_investigacion.publicacion_revista    TO rol_coordinador;
GRANT SELECT ON gestion_investigacion.publicacion_congreso   TO rol_coordinador;
GRANT SELECT ON gestion_investigacion.libro                  TO rol_coordinador;
GRANT SELECT ON gestion_investigacion.patentes               TO rol_coordinador;
GRANT SELECT ON gestion_investigacion.linea_investigacion    TO rol_coordinador;
GRANT SELECT ON gestion_investigacion.linea_descriptor       TO rol_coordinador;
GRANT SELECT ON gestion_investigacion.linea_profesor         TO rol_coordinador;
GRANT SELECT ON gestion_investigacion.proyecto_linea         TO rol_coordinador;
GRANT SELECT ON gestion_investigacion.escribe                TO rol_coordinador;
GRANT SELECT ON gestion_investigacion.resumen_proyecto       TO rol_coordinador;
GRANT SELECT ON gestion_investigacion.facultad               TO rol_coordinador;
GRANT SELECT ON gestion_investigacion.programa               TO rol_coordinador;
GRANT SELECT ON gestion_investigacion.pais                   TO rol_coordinador;
GRANT SELECT ON gestion_investigacion.editorial              TO rol_coordinador;
GRANT EXECUTE ON PROCEDURE gestion_investigacion.sp_ca1_productividad_proyectos  TO rol_coordinador;
GRANT EXECUTE ON PROCEDURE gestion_investigacion.sp_ca2_proyectos_sobre_promedio TO rol_coordinador;
GRANT EXECUTE ON PROCEDURE gestion_investigacion.sp_ca3_ultimo_producto_proyecto TO rol_coordinador;
GRANT EXECUTE ON PROCEDURE gestion_investigacion.sp_ca4_valoracion_revistas      TO rol_coordinador;
GRANT EXECUTE ON PROCEDURE gestion_investigacion.sp_ca5_estado_proyectos         TO rol_coordinador;
GRANT EXECUTE ON PROCEDURE gestion_investigacion.sp_cm1_equipo_proyecto          TO rol_coordinador;
GRANT EXECUTE ON PROCEDURE gestion_investigacion.sp_cm2_carga_profesores         TO rol_coordinador;
GRANT EXECUTE ON PROCEDURE gestion_investigacion.sp_cm3_estudiantes_por_proyecto TO rol_coordinador;
GRANT EXECUTE ON PROCEDURE gestion_investigacion.sp_cm4_cobertura_lineas         TO rol_coordinador;
GRANT EXECUTE ON PROCEDURE gestion_investigacion.sp_cm5_catalogo_productos       TO rol_coordinador;

-- D. DIRECTOR DE INVESTIGACIÓN: todo lo del coordinador + supervisión de la
--    auditoría y del historial de participación
GRANT rol_coordinador TO rol_director_inv;
GRANT SELECT ON gestion_investigacion.auditoria_operaciones   TO rol_director_inv;
GRANT SELECT ON gestion_investigacion.auditoria_proyecto      TO rol_director_inv;
GRANT SELECT ON gestion_investigacion.historial_participacion TO rol_director_inv;

-- E. PROFESOR: solo sus vistas personales y reportes públicos
GRANT SELECT ON gestion_investigacion.vw_docente_mis_proyectos     TO rol_profesor;
GRANT SELECT ON gestion_investigacion.vw_docente_mi_equipo         TO rol_profesor;
GRANT SELECT ON gestion_investigacion.vw_docente_mis_publicaciones TO rol_profesor;
GRANT EXECUTE ON PROCEDURE gestion_investigacion.sp_ca3_ultimo_producto_proyecto TO rol_profesor;
GRANT EXECUTE ON PROCEDURE gestion_investigacion.sp_cm5_catalogo_productos       TO rol_profesor;

-- F. ESTUDIANTE: solo su vista personal y el catálogo público de productos
GRANT SELECT ON gestion_investigacion.vw_estudiante_mis_proyectos TO rol_estudiante;
GRANT EXECUTE ON PROCEDURE gestion_investigacion.sp_cm5_catalogo_productos TO rol_estudiante;

-- ----------------------------------------------------------------------------
-- 3. CUENTAS PERSONALES
-- ----------------------------------------------------------------------------
-- Personal administrativo
CREATE USER 'patricio.lara'@'localhost'   IDENTIFIED BY 'Ueb#Lara-Adm26';
CREATE USER 'monica.cardenas'@'localhost' IDENTIFIED BY 'Ueb#Cardenas-Sec26';
CREATE USER 'santiago.borja'@'localhost'  IDENTIFIED BY 'Ueb#Borja-Coo26';
CREATE USER 'elena.mosquera'@'localhost'  IDENTIFIED BY 'Ueb#Mosquera-Dir26';

GRANT rol_admin        TO 'patricio.lara'@'localhost';
GRANT rol_secretaria   TO 'monica.cardenas'@'localhost';
GRANT rol_coordinador  TO 'santiago.borja'@'localhost';
GRANT rol_director_inv TO 'elena.mosquera'@'localhost';

SET DEFAULT ROLE rol_admin        FOR 'patricio.lara'@'localhost';
SET DEFAULT ROLE rol_secretaria   FOR 'monica.cardenas'@'localhost';
SET DEFAULT ROLE rol_coordinador  FOR 'santiago.borja'@'localhost';
SET DEFAULT ROLE rol_director_inv FOR 'elena.mosquera'@'localhost';

-- Profesores (cuenta = profesores.db_usuario)
CREATE USER 'carlos.villacres'@'localhost' IDENTIFIED BY 'Ueb#Villacres-Doc26';
CREATE USER 'maria.gavilanes'@'localhost'  IDENTIFIED BY 'Ueb#Gavilanes-Doc26';
CREATE USER 'luis.chimbo'@'localhost'      IDENTIFIED BY 'Ueb#Chimbo-Doc26';
CREATE USER 'ana.arellano'@'localhost'     IDENTIFIED BY 'Ueb#Arellano-Doc26';
CREATE USER 'jorge.naranjo'@'localhost'    IDENTIFIED BY 'Ueb#Naranjo-Doc26';
CREATE USER 'diana.pazmino'@'localhost'    IDENTIFIED BY 'Ueb#Pazmino-Doc26';
CREATE USER 'hector.sanchez'@'localhost'   IDENTIFIED BY 'Ueb#Sanchez-Doc26';
CREATE USER 'gabriela.mora'@'localhost'    IDENTIFIED BY 'Ueb#Mora-Doc26';
CREATE USER 'ramiro.guaman'@'localhost'    IDENTIFIED BY 'Ueb#Guaman-Doc26';
CREATE USER 'paola.salazar'@'localhost'    IDENTIFIED BY 'Ueb#Salazar-Doc26';
CREATE USER 'edison.lombeida'@'localhost'  IDENTIFIED BY 'Ueb#Lombeida-Doc26';
CREATE USER 'veronica.coello'@'localhost'  IDENTIFIED BY 'Ueb#Coello-Doc26';
CREATE USER 'fausto.escobar'@'localhost'   IDENTIFIED BY 'Ueb#Escobar-Doc26';

GRANT rol_profesor TO 'carlos.villacres'@'localhost', 'maria.gavilanes'@'localhost',
                      'luis.chimbo'@'localhost', 'ana.arellano'@'localhost',
                      'jorge.naranjo'@'localhost', 'diana.pazmino'@'localhost',
                      'hector.sanchez'@'localhost', 'gabriela.mora'@'localhost',
                      'ramiro.guaman'@'localhost', 'paola.salazar'@'localhost',
                      'edison.lombeida'@'localhost', 'veronica.coello'@'localhost',
                      'fausto.escobar'@'localhost';

SET DEFAULT ROLE rol_profesor FOR 'carlos.villacres'@'localhost';
SET DEFAULT ROLE rol_profesor FOR 'maria.gavilanes'@'localhost';
SET DEFAULT ROLE rol_profesor FOR 'luis.chimbo'@'localhost';
SET DEFAULT ROLE rol_profesor FOR 'ana.arellano'@'localhost';
SET DEFAULT ROLE rol_profesor FOR 'jorge.naranjo'@'localhost';
SET DEFAULT ROLE rol_profesor FOR 'diana.pazmino'@'localhost';
SET DEFAULT ROLE rol_profesor FOR 'hector.sanchez'@'localhost';
SET DEFAULT ROLE rol_profesor FOR 'gabriela.mora'@'localhost';
SET DEFAULT ROLE rol_profesor FOR 'ramiro.guaman'@'localhost';
SET DEFAULT ROLE rol_profesor FOR 'paola.salazar'@'localhost';
SET DEFAULT ROLE rol_profesor FOR 'edison.lombeida'@'localhost';
SET DEFAULT ROLE rol_profesor FOR 'veronica.coello'@'localhost';
SET DEFAULT ROLE rol_profesor FOR 'fausto.escobar'@'localhost';

-- Estudiantes (cuenta = estudiante.db_usuario)
CREATE USER 'andony.cortez'@'localhost'   IDENTIFIED BY 'Ueb#Cortez-Est26';
CREATE USER 'jonathan.ayme'@'localhost'  IDENTIFIED BY 'Ueb#Ayme-Est26';
CREATE USER 'bryan.ruiz'@'localhost'    IDENTIFIED BY 'Ueb#Ruiz-Est26';
CREATE USER 'lizbeth.tixi'@'localhost'  IDENTIFIED BY 'Ueb#Tixi-Est26';
CREATE USER 'jonathan.sisa'@'localhost' IDENTIFIED BY 'Ueb#Sisa-Est26';
CREATE USER 'erika.gaibor'@'localhost'  IDENTIFIED BY 'Ueb#Gaibor-Est26';
CREATE USER 'marco.paredes'@'localhost' IDENTIFIED BY 'Ueb#Paredes-Est26';

GRANT rol_estudiante TO 'andony.cortez'@'localhost', 'jonathan.ayme'@'localhost',
                        'bryan.ruiz'@'localhost', 'lizbeth.tixi'@'localhost',
                        'jonathan.sisa'@'localhost', 'erika.gaibor'@'localhost',
                        'marco.paredes'@'localhost';

SET DEFAULT ROLE rol_estudiante FOR 'andony.cortez'@'localhost';
SET DEFAULT ROLE rol_estudiante FOR 'jonathan.ayme'@'localhost';
SET DEFAULT ROLE rol_estudiante FOR 'bryan.ruiz'@'localhost';
SET DEFAULT ROLE rol_estudiante FOR 'lizbeth.tixi'@'localhost';
SET DEFAULT ROLE rol_estudiante FOR 'jonathan.sisa'@'localhost';
SET DEFAULT ROLE rol_estudiante FOR 'erika.gaibor'@'localhost';
SET DEFAULT ROLE rol_estudiante FOR 'marco.paredes'@'localhost';
