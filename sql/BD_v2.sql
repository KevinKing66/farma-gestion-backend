-- =========================================================
--||                      DDL                              ||
-- =========================================================

-- drop database farmagestion;
CREATE DATABASE IF NOT EXISTS farmagestion
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE farmagestion;

SET sql_safe_updates = 0;


SET FOREIGN_KEY_CHECKS = 0;

-- Drop Vistas (por si existían)
DROP VIEW IF EXISTS v_resumen_auditoria;
DROP VIEW IF EXISTS v_consumos_por_servicio;
DROP VIEW IF EXISTS v_stock_por_item;
DROP VIEW IF EXISTS v_lotes_vencidos;
DROP VIEW IF EXISTS v_alertas_stock_bajo;
DROP VIEW IF EXISTS v_alertas_vencimiento;
DROP VIEW IF EXISTS v_kardex_con_saldo;
DROP VIEW IF EXISTS v_kardex;
DROP VIEW IF EXISTS v_existencias_detalle;

-- Drop Triggers
DROP TRIGGER IF EXISTS trg_comprobante_ingreso_ai;
DROP TRIGGER IF EXISTS trg_mv2_ai;
DROP TRIGGER IF EXISTS trg_mv2_bd;
DROP TRIGGER IF EXISTS trg_mv2_bu;
DROP TRIGGER IF EXISTS trg_ubicaciones_ai;
DROP TRIGGER IF EXISTS trg_lotes_ai;
DROP TRIGGER IF EXISTS trg_items_ad;
DROP TRIGGER IF EXISTS trg_items_au;
DROP TRIGGER IF EXISTS trg_items_ai;
DROP TRIGGER IF EXISTS trg_auditoria_bd;
DROP TRIGGER IF EXISTS trg_auditoria_bu;

-- Drop Events
DROP EVENT IF EXISTS ev_generar_alertas_diarias;

-- Drop SP y Funciones
DROP PROCEDURE IF EXISTS sp_verificar_auditoria_integridad;
DROP PROCEDURE IF EXISTS sp_importar_inventario_inicial;
DROP PROCEDURE IF EXISTS sp_recalcular_existencias;
DROP PROCEDURE IF EXISTS sp_anular_movimiento;
DROP PROCEDURE IF EXISTS sp_ajustar_stock;
DROP PROCEDURE IF EXISTS sp_transferir_stock;
DROP PROCEDURE IF EXISTS sp_registrar_salida;
DROP PROCEDURE IF EXISTS sp_registrar_ingreso;
DROP PROCEDURE IF EXISTS sp_asegurar_lote;
DROP PROCEDURE IF EXISTS sp_registrar_login;
DROP FUNCTION  IF EXISTS fn_ultimo_hash;

-- Drop Tablas (orden inverso FKs)
DROP TABLE IF EXISTS comprobantes_recepcion;
DROP TABLE IF EXISTS notificaciones;
DROP TABLE IF EXISTS stg_inventario_inicial;
DROP TABLE IF EXISTS movimientos_v2;
DROP TABLE IF EXISTS auditoria;
DROP TABLE IF EXISTS existencias;
DROP TABLE IF EXISTS parametros_sistema;
DROP TABLE IF EXISTS lotes;
DROP TABLE IF EXISTS items;
DROP TABLE IF EXISTS usuarios;
DROP TABLE IF EXISTS ubicaciones;
DROP TABLE IF EXISTS proveedores;

SET FOREIGN_KEY_CHECKS = 1;

-- 2) Catálogos base
CREATE TABLE proveedores (
  id_proveedor INT AUTO_INCREMENT PRIMARY KEY,
  nombre       VARCHAR(150) NOT NULL,
  nit          VARCHAR(50)  NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE ubicaciones (
  id_ubicacion INT AUTO_INCREMENT PRIMARY KEY,
  nombre       VARCHAR(100) NOT NULL,
  tipo         ENUM('ALMACEN','SERVICIO') NOT NULL DEFAULT 'ALMACEN',
  activo       TINYINT(1) NOT NULL DEFAULT 1,
  UNIQUE KEY ux_ubicaciones_nombre (nombre)
) ENGINE=InnoDB;

CREATE TABLE usuarios (
  id_usuario      INT AUTO_INCREMENT PRIMARY KEY,
  nombre_completo VARCHAR(150) NOT NULL,
  correo          VARCHAR(150) NOT NULL UNIQUE,
  rol             ENUM('AUXILIAR','REGENTE','AUDITOR','ADMIN') NOT NULL,
  contrasena      VARCHAR(255) NOT NULL,
  intentos_fallidos TINYINT NOT NULL DEFAULT 0,
  bloqueado_hasta  DATETIME NULL
) ENGINE=InnoDB;

-- Índice adicional por correo (idempotente)
SET @idx_exists := (
  SELECT COUNT(*) FROM information_schema.statistics
   WHERE table_schema = DATABASE()
     AND table_name = 'usuarios'
     AND index_name = 'ix_usuarios_correo'
);
SET @sql := IF(@idx_exists=0,
  'CREATE INDEX ix_usuarios_correo ON usuarios (correo)',
  'DO 0'
);
PREPARE st FROM @sql; EXECUTE st; DEALLOCATE PREPARE st;

-- CHECK bcrypt (idempotente)
SET @chk_exists := (
  SELECT COUNT(*) FROM information_schema.table_constraints
   WHERE table_schema = DATABASE()
     AND table_name = 'usuarios'
     AND constraint_name = 'chk_pwd_bcrypt'
);
SET @sql := IF(@chk_exists=0,
  'ALTER TABLE usuarios ADD CONSTRAINT chk_pwd_bcrypt CHECK (contrasena LIKE ''$2%'')',
  'DO 0'
);
PREPARE st FROM @sql; EXECUTE st; DEALLOCATE PREPARE st;

-- 3) Items y Lotes
CREATE TABLE items (
  id_item       INT AUTO_INCREMENT PRIMARY KEY,
  id_ubicacion  INT NOT NULL,
  codigo        VARCHAR(50)  NULL,
  descripcion   VARCHAR(255) NOT NULL,
  tipo_item     ENUM('MEDICAMENTO','DISPOSITIVO') NOT NULL,
  unidad_medida VARCHAR(20)  NOT NULL DEFAULT 'UND',
  stock_minimo  INT NOT NULL DEFAULT 0,
  CONSTRAINT fk_items_ubi FOREIGN KEY (id_ubicacion) REFERENCES ubicaciones(id_ubicacion)
) ENGINE=InnoDB;

-- Código único (idempotente)
SET @idx_exists := (
  SELECT COUNT(*) FROM information_schema.statistics
   WHERE table_schema = DATABASE()
     AND table_name = 'items'
     AND index_name = 'ux_items_codigo'
);
SET @sql := IF(@idx_exists=0,
  'ALTER TABLE items ADD UNIQUE KEY ux_items_codigo (codigo)',
  'DO 0'
);
PREPARE st FROM @sql; EXECUTE st; DEALLOCATE PREPARE st;

-- FULLTEXT opcional para búsquedas por texto (idempotente)
SET @ft_exists := (
  SELECT COUNT(*) FROM information_schema.statistics
   WHERE table_schema = DATABASE()
     AND table_name = 'items'
     AND index_name = 'ft_items_text'
     AND index_type = 'FULLTEXT'
);
SET @sql := IF(@ft_exists=0,
  'ALTER TABLE items ADD FULLTEXT ft_items_text (codigo, descripcion)',
  'DO 0'
);
PREPARE st FROM @sql; EXECUTE st; DEALLOCATE PREPARE st;

CREATE TABLE lotes (
  id_lote           INT AUTO_INCREMENT PRIMARY KEY,
  id_item           INT NOT NULL,
  id_proveedor      INT NOT NULL,
  codigo_lote       VARCHAR(50) NOT NULL,
  fecha_vencimiento DATE NOT NULL,
  costo_unitario    DECIMAL(10,2) NOT NULL,
  CONSTRAINT fk_lotes_item      FOREIGN KEY (id_item)      REFERENCES items(id_item),
  CONSTRAINT fk_lotes_proveedor FOREIGN KEY (id_proveedor) REFERENCES proveedores(id_proveedor)
) ENGINE=InnoDB;

-- Único por item + código de lote
SET @idx_exists := (
  SELECT COUNT(*) FROM information_schema.statistics
   WHERE table_schema = DATABASE()
     AND table_name = 'lotes'
     AND index_name = 'ux_lote_item'
);
SET @sql := IF(@idx_exists=0,
  'ALTER TABLE lotes ADD UNIQUE KEY ux_lote_item (id_item, codigo_lote)',
  'DO 0'
);
PREPARE st FROM @sql; EXECUTE st; DEALLOCATE PREPARE st;

-- Índice por vencimiento
SET @idx_exists := (
  SELECT COUNT(*) FROM information_schema.statistics
   WHERE table_schema = DATABASE()
     AND table_name = 'lotes'
     AND index_name = 'ix_lotes_venc'
);
SET @sql := IF(@idx_exists=0,
  'ALTER TABLE lotes ADD INDEX ix_lotes_venc (fecha_vencimiento)',
  'DO 0'
);
PREPARE st FROM @sql; EXECUTE st; DEALLOCATE PREPARE st;

-- 4) Operativas y soporte
CREATE TABLE existencias (
  id_existencia BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_lote       INT NOT NULL,
  id_ubicacion  INT NOT NULL,
  saldo         INT NOT NULL DEFAULT 0,
  UNIQUE KEY ux_lote_ubicacion (id_lote, id_ubicacion),
  CONSTRAINT fk_ex_lote FOREIGN KEY (id_lote) REFERENCES lotes(id_lote),
  CONSTRAINT fk_ex_ubi  FOREIGN KEY (id_ubicacion) REFERENCES ubicaciones(id_ubicacion)
) ENGINE=InnoDB;

-- Índice por ubicación (idempotente)
SET @idx_exists := (
  SELECT COUNT(*) FROM information_schema.statistics
   WHERE table_schema = DATABASE()
     AND table_name = 'existencias'
     AND index_name = 'ix_existencias_ubicacion'
);
SET @sql := IF(@idx_exists=0,
  'CREATE INDEX ix_existencias_ubicacion ON existencias (id_ubicacion)',
  'DO 0'
);
PREPARE st FROM @sql; EXECUTE st; DEALLOCATE PREPARE st;

CREATE TABLE parametros_sistema (
  clave       VARCHAR(50) PRIMARY KEY,
  valor       VARCHAR(100) NOT NULL,
  descripcion VARCHAR(255)
) ENGINE=InnoDB;

-- Semilla mínima de parámetros (no es migración; parametrización)
INSERT INTO parametros_sistema (clave, valor, descripcion)
VALUES ('dias_alerta_venc','30','Días para alerta de vencimiento'),
       ('umbral_stock_bajo_default','0','Umbral por defecto')
ON DUPLICATE KEY UPDATE valor = VALUES(valor), descripcion = VALUES(descripcion);

-- Auditoría encadenada (inalterable por triggers)
CREATE TABLE auditoria (
  id_evento       BIGINT AUTO_INCREMENT PRIMARY KEY,
  tabla_afectada  VARCHAR(100) NOT NULL,
  pk_afectada     VARCHAR(100) NOT NULL,
  accion          ENUM('INSERT','UPDATE','DELETE') NOT NULL,
  valores_antes   JSON NULL,
  valores_despues JSON NULL,
  id_usuario      INT NULL,
  fecha           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  hash_anterior   CHAR(64) NULL,
  hash_evento     CHAR(64) NOT NULL,
  INDEX ix_aud_tabla_fecha (tabla_afectada, fecha),
  CONSTRAINT fk_aud_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
) ENGINE=InnoDB;

-- Outbox de notificaciones (para RF-04; materialización de alertas)
CREATE TABLE notificaciones (
  id_notificacion BIGINT AUTO_INCREMENT PRIMARY KEY,
  tipo ENUM('ALERTA_VENCIMIENTO','ALERTA_STOCK_BAJO') NOT NULL,
  payload JSON NOT NULL,
  destinatario VARCHAR(150) NULL,
  estado ENUM('PENDIENTE','ENVIADA','ERROR') NOT NULL DEFAULT 'PENDIENTE',
  detalle_error VARCHAR(255) NULL,
  fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_envio DATETIME NULL
) ENGINE=InnoDB;

-- Staging de importación CSV (opcional)
CREATE TABLE stg_inventario_inicial (
  codigo_item       VARCHAR(50) NOT NULL,
  nit_proveedor     VARCHAR(50) NOT NULL,
  codigo_lote       VARCHAR(50) NOT NULL,
  fecha_vencimiento DATE NOT NULL,
  costo_unitario    DECIMAL(10,2) NOT NULL,
  nombre_ubicacion  VARCHAR(100) NOT NULL,
  cantidad          INT NOT NULL CHECK (cantidad > 0)
) ENGINE=InnoDB;

-- 5) Función de soporte auditoría
DELIMITER $$
CREATE FUNCTION fn_ultimo_hash()
RETURNS CHAR(64)
DETERMINISTIC
BEGIN
  DECLARE h CHAR(64);
  SELECT hash_evento INTO h FROM auditoria ORDER BY id_evento DESC LIMIT 1;
  RETURN COALESCE(h, REPEAT('0',64));
END$$
DELIMITER ;

-- 6) Movimientos (modelo final)
CREATE TABLE movimientos_v2 (
  id_movimiento        BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_lote              INT NOT NULL,
  id_usuario           INT NOT NULL,
  tipo                 ENUM('INGRESO','SALIDA','TRANSFERENCIA','AJUSTE') NOT NULL,
  cantidad             INT NOT NULL,
  id_ubicacion_origen  INT NULL,
  id_ubicacion_destino INT NULL,
  motivo               VARCHAR(255) NULL,
  fecha                DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_mv2_lote   FOREIGN KEY (id_lote)    REFERENCES lotes(id_lote),
  CONSTRAINT fk_mv2_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario),
  CONSTRAINT fk_mv2_ori    FOREIGN KEY (id_ubicacion_origen)  REFERENCES ubicaciones(id_ubicacion),
  CONSTRAINT fk_mv2_des    FOREIGN KEY (id_ubicacion_destino) REFERENCES ubicaciones(id_ubicacion)
) ENGINE=InnoDB;

-- Índices útiles (idempotentes)
SET @idx_exists := (
  SELECT COUNT(*) FROM information_schema.statistics
   WHERE table_schema = DATABASE()
     AND table_name = 'movimientos_v2'
     AND index_name = 'ix_mv2_lote_fecha'
);
SET @sql := IF(@idx_exists=0,
  'CREATE INDEX ix_mv2_lote_fecha ON movimientos_v2 (id_lote, fecha)',
  'DO 0'
);
PREPARE st FROM @sql; EXECUTE st; DEALLOCATE PREPARE st;

SET @idx_exists := (
  SELECT COUNT(*) FROM information_schema.statistics
   WHERE table_schema = DATABASE()
     AND table_name = 'movimientos_v2'
     AND index_name = 'ix_mv2_destino_fecha'
);
SET @sql := IF(@idx_exists=0,
  'CREATE INDEX ix_mv2_destino_fecha ON movimientos_v2 (id_ubicacion_destino, fecha)',
  'DO 0'
);
PREPARE st FROM @sql; EXECUTE st; DEALLOCATE PREPARE st;

-- Índice extra sugerido por rendimiento: origen+fecha
SET @idx_exists := (
  SELECT COUNT(*) FROM information_schema.statistics
   WHERE table_schema = DATABASE()
     AND table_name = 'movimientos_v2'
     AND index_name = 'ix_mv2_origen_fecha'
);
SET @sql := IF(@idx_exists=0,
  'CREATE INDEX ix_mv2_origen_fecha ON movimientos_v2 (id_ubicacion_origen, fecha)',
  'DO 0'
);
PREPARE st FROM @sql; EXECUTE st; DEALLOCATE PREPARE st;

-- 6.1) Comprobantes de recepción (opcional) para HU-10, tras crear movimientos_v2
CREATE TABLE comprobantes_recepcion (
  id_comprobante BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_movimiento BIGINT NOT NULL,
  id_proveedor  INT NOT NULL,
  canal ENUM('PORTAL','EMAIL') NOT NULL DEFAULT 'PORTAL',
  entregado TINYINT(1) NOT NULL DEFAULT 0,
  fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_entrega DATETIME NULL,
  FOREIGN KEY (id_movimiento) REFERENCES movimientos_v2(id_movimiento),
  FOREIGN KEY (id_proveedor)  REFERENCES proveedores(id_proveedor)
) ENGINE=InnoDB;





