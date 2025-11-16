-- FARMAGESTION_DDL_V3.SQL
-- Esquema + SPs + Vistas + Triggers + Eventos
-- DROP DATABASE farmagestion;
CREATE DATABASE IF NOT EXISTS farmagestion
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE farmagestion;

SET sql_safe_updates = 0;
SET FOREIGN_KEY_CHECKS = 0;

SET FOREIGN_KEY_CHECKS = 1;

/* ===========================================================
   1) Catálogos base
   =========================================================== */
CREATE TABLE proveedores (
    id_proveedor INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    nit VARCHAR(50) NOT NULL UNIQUE,
    telefono VARCHAR(15) NOT NULL,
    direccion VARCHAR(255) NOT NULL,
    correo VARCHAR(100) NOT NULL,
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    activo TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;

CREATE TABLE ubicaciones (
  id_ubicacion INT AUTO_INCREMENT PRIMARY KEY,
  nombre       VARCHAR(100) NOT NULL,
  tipo         ENUM('ALMACEN','SERVICIO') NOT NULL DEFAULT 'ALMACEN',
  activo       TINYINT(1) NOT NULL DEFAULT 1,
  UNIQUE KEY ux_ubicaciones_nombre (nombre)
) ENGINE=InnoDB;

CREATE TABLE usuarios (
    id_usuario        INT AUTO_INCREMENT PRIMARY KEY,
    nombre_completo   VARCHAR(150) NOT NULL,
    correo            VARCHAR(150) NOT NULL UNIQUE,
    rol               ENUM('AUXILIAR','REGENTE','AUDITOR','ADMIN', 'PROVEEDOR') NOT NULL,
    contrasena        VARCHAR(255) NOT NULL,
    intentos_fallidos TINYINT NOT NULL DEFAULT 0,
    bloqueado_hasta   DATETIME NULL,
    fecha_ultimo_login DATETIME NULL,
    activo            TINYINT (1) NOT NULL DEFAULT 1,
    CONSTRAINT chk_pwd_bcrypt CHECK (contrasena LIKE '$2%')
) ENGINE=InnoDB;


/* ===========================================================
   2) Items y Lotes
   =========================================================== */
CREATE TABLE items (
  id_item       INT AUTO_INCREMENT PRIMARY KEY,
  id_ubicacion  INT NOT NULL,
  codigo        VARCHAR(50) NULL,
  descripcion   VARCHAR(255) NOT NULL,
  tipo_item     ENUM('MEDICAMENTO','DISPOSITIVO') NOT NULL,
  unidad_medida VARCHAR(20) NOT NULL DEFAULT 'UND',
  stock_minimo  INT NOT NULL DEFAULT 0,
  uso_frecuente TINYINT(1) DEFAULT 0,
  CONSTRAINT fk_items_ubi FOREIGN KEY (id_ubicacion) REFERENCES ubicaciones(id_ubicacion),
  UNIQUE KEY ux_items_codigo (codigo)
) ENGINE=InnoDB;

-- FULLTEXT idempotente (si no existe)
SET @ft_exists := (
  SELECT COUNT(*)
  FROM information_schema.statistics
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
    estado ENUM('ACTIVO', 'INACTIVO') DEFAULT 'ACTIVO',
    CONSTRAINT fk_lotes_item      FOREIGN KEY (id_item)      REFERENCES items(id_item),
    CONSTRAINT fk_lotes_proveedor FOREIGN KEY (id_proveedor) REFERENCES proveedores(id_proveedor),
    UNIQUE KEY ux_lote_item (id_item, codigo_lote),
    INDEX ix_lotes_venc (fecha_vencimiento)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS lotes_posiciones (
  id_posicion   BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_lote       INT NOT NULL,
  id_ubicacion  INT NOT NULL,    -- debe ser ubicaciones.tipo = 'ALMACEN'
  estante       VARCHAR(20) NULL,
  nivel         VARCHAR(20) NULL,
  pasillo       VARCHAR(20) NULL,
  fecha_asignacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  asignado_por  INT NULL,        -- usuario que asignó (opcional)

  -- Unicidad de la posición dentro de un almacén:
  UNIQUE KEY ux_ubicacion_pos (id_ubicacion, estante, nivel, pasillo),

  -- Evita múltiples posiciones del mismo lote dentro del MISMO almacén:
  UNIQUE KEY ux_lote_ubicacion (id_lote, id_ubicacion),

  -- Índices de apoyo
  KEY ix_lpos_lote (id_lote),
  KEY ix_lpos_ubicacion (id_ubicacion),

  CONSTRAINT fk_lpos_lote
    FOREIGN KEY (id_lote) REFERENCES lotes(id_lote),

  CONSTRAINT fk_lpos_ubicacion
    FOREIGN KEY (id_ubicacion) REFERENCES ubicaciones(id_ubicacion),

  CONSTRAINT fk_lpos_asignado_por
    FOREIGN KEY (asignado_por) REFERENCES usuarios(id_usuario),

CONSTRAINT chk_lpos_completitud CHECK ((estante IS NULL AND nivel IS NULL AND pasillo IS NULL)
	OR (estante IS NOT NULL AND nivel IS NOT NULL AND pasillo IS NOT NULL))
) ENGINE=InnoDB;

/* ===========================================================
   3) Operativas y soporte
   =========================================================== */
CREATE TABLE existencias (
  id_existencia BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_lote       INT NOT NULL,
  id_ubicacion  INT NOT NULL,
  saldo         INT NOT NULL DEFAULT 0,
  UNIQUE KEY ux_lote_ubicacion (id_lote, id_ubicacion),
  CONSTRAINT fk_ex_lote FOREIGN KEY (id_lote) REFERENCES lotes(id_lote),
  CONSTRAINT fk_ex_ubi  FOREIGN KEY (id_ubicacion) REFERENCES ubicaciones(id_ubicacion)
) ENGINE=InnoDB;

CREATE TABLE parametros_sistema (
  clave       VARCHAR(50) PRIMARY KEY,
  valor       VARCHAR(100) NOT NULL,
  descripcion VARCHAR(255)
) ENGINE=InnoDB;

-- Parámetros por defecto
INSERT INTO parametros_sistema (clave, valor, descripcion)
VALUES ('dias_alerta_venc','30','Días para alerta de vencimiento'),
       ('umbral_stock_bajo_default','0','Umbral por defecto')
ON DUPLICATE KEY UPDATE valor=VALUES(valor), descripcion=VALUES(descripcion);

CREATE TABLE auditoria (
  id_evento      BIGINT AUTO_INCREMENT PRIMARY KEY,
  tabla_afectada VARCHAR(100) NOT NULL,
  pk_afectada    VARCHAR(100) NOT NULL,
  accion         ENUM('INSERT','UPDATE','DELETE', 'DENEGADO') NOT NULL,
  valores_antes  JSON NULL,
  valores_despues JSON NULL,
  id_usuario     INT NULL,
  fecha          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  hash_anterior  CHAR(64) NULL,
  hash_evento    CHAR(64) NOT NULL,
  INDEX ix_aud_tabla_fecha (tabla_afectada, fecha),
  CONSTRAINT fk_aud_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
) ENGINE=InnoDB;

CREATE TABLE notificaciones (
    id_notificacion BIGINT AUTO_INCREMENT PRIMARY KEY,
    tipo            ENUM('ALERTA_VENCIMIENTO','ALERTA_STOCK_BAJO', 'ALERTA_STOCK_CRITICO','BACKUP') NOT NULL,
    payload         JSON NOT NULL,
    destinatario    VARCHAR(150) NULL,
    estado          ENUM('PENDIENTE','ENVIADA','ERROR') NOT NULL DEFAULT 'PENDIENTE',
    detalle_error   VARCHAR(255) NULL,
    fecha_creacion  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_envio     DATETIME NULL,
    confirmado_por  INT NULL,
    fecha_confirmacion DATETIME NULL,
    estado_confirmacion ENUM('PENDIENTE','REVISADA') DEFAULT 'PENDIENTE',
    CONSTRAINT fk_notif_confirmado_por FOREIGN KEY (confirmado_por) REFERENCES usuarios(id_usuario)
) ENGINE=InnoDB;

CREATE TABLE stg_inventario_inicial (
  codigo_item      VARCHAR(50) NOT NULL,
  nit_proveedor    VARCHAR(50) NOT NULL,
  codigo_lote      VARCHAR(50) NOT NULL,
  fecha_vencimiento DATE NOT NULL,
  costo_unitario   DECIMAL(10,2) NOT NULL,
  nombre_ubicacion VARCHAR(100) NOT NULL,
  cantidad         INT NOT NULL CHECK (cantidad > 0)
) ENGINE=InnoDB;

CREATE TABLE sesiones_activas (
    id_sesion BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    ip VARCHAR(45) NOT NULL,
    user_agent VARCHAR (255) NULL,
    hora_inicio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    activo TINYINT(1) NOT NULL DEFAULT 1,
    hora_cierre DATETIME NULL,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
);
  
CREATE INDEX ix_sesiones_usuario_activo 
  ON sesiones_activas (id_usuario, activo);
  
  CREATE INDEX ix_notif_fecha_estado
  ON notificaciones (fecha_creacion, estado);
  
-- Asegurar índice de sesiones (si no existe)
SET @idx_exists := (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'sesiones_activas'
    AND INDEX_NAME = 'ix_sesiones_usuario_activo'
);
SET @sql := IF(@idx_exists = 0,
  'CREATE INDEX ix_sesiones_usuario_activo ON sesiones_activas (id_usuario, activo)',
  'DO 0'
);
PREPARE st FROM @sql; EXECUTE st; DEALLOCATE PREPARE st;

-- Tabla para etiquetas QR (HU-21)
CREATE TABLE etiquetas_qr (
    id_etiqueta INT AUTO_INCREMENT PRIMARY KEY,
    id_lote INT NOT NULL,
    fecha_generacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    contenido_qr TEXT NOT NULL,
    FOREIGN KEY (id_lote) REFERENCES lotes(id_lote)
) ENGINE=InnoDB;

/* ===========================================================
   5) Movimientos + Comprobantes
   =========================================================== */
CREATE TABLE movimientos (
  id_movimiento       BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_lote             INT NOT NULL,
  id_usuario          INT NOT NULL,
  tipo                ENUM('INGRESO','SALIDA','TRANSFERENCIA','AJUSTE') NOT NULL,
  cantidad            INT NOT NULL,
  id_ubicacion_origen INT NULL,
  id_ubicacion_destino INT NULL,
  motivo              VARCHAR(255) NULL,
  fecha               DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_mov_lote    FOREIGN KEY (id_lote)    REFERENCES lotes(id_lote),
  CONSTRAINT fk_mov_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario),
  CONSTRAINT fk_mov_ori     FOREIGN KEY (id_ubicacion_origen)  REFERENCES ubicaciones(id_ubicacion),
  CONSTRAINT fk_mov_des     FOREIGN KEY (id_ubicacion_destino) REFERENCES ubicaciones(id_ubicacion)
) ENGINE=InnoDB;

CREATE INDEX ix_mov_lote_fecha    ON movimientos (id_lote, fecha);
CREATE INDEX ix_mov_destino_fecha ON movimientos (id_ubicacion_destino, fecha);
CREATE INDEX ix_mov_origen_fecha  ON movimientos (id_ubicacion_origen,  fecha);

CREATE TABLE comprobantes_recepcion (
  id_comprobante  BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_movimiento   BIGINT NOT NULL,
  id_proveedor    INT NOT NULL,
  canal           ENUM('PORTAL','EMAIL') NOT NULL DEFAULT 'PORTAL',
  entregado       TINYINT(1) NOT NULL DEFAULT 0,
  fecha_creacion  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_entrega   DATETIME NULL,
  FOREIGN KEY (id_movimiento) REFERENCES movimientos(id_movimiento),
  FOREIGN KEY (id_proveedor)  REFERENCES proveedores(id_proveedor)
) ENGINE=InnoDB;


CREATE TABLE ips_permitidas (
    id_ip INT AUTO_INCREMENT PRIMARY KEY,
    ip VARCHAR(45) NOT NULL,
    descripcion VARCHAR(255),
    fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE tokens_recuperacion (
    id_token BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    token VARCHAR(255) NOT NULL,
    expiracion DATETIME NOT NULL,
    usado TINYINT(1) DEFAULT 0,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario),
    UNIQUE KEY ux_token_unico (token)
);

CREATE TABLE incidentes_almacenamiento (
    id_incidente INT AUTO_INCREMENT PRIMARY KEY,
    fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    descripcion TEXT NOT NULL,
    responsable VARCHAR(150) NOT NULL,
    accion_correctiva TEXT,
    evidencia TEXT,
    registrado_por INT,
    FOREIGN KEY (registrado_por) REFERENCES usuarios(id_usuario)
);

-- Tabla para controles de calidad (HU-23)
CREATE TABLE control_calidad (
    id_control INT AUTO_INCREMENT PRIMARY KEY,
    id_lote INT NOT NULL,
    fecha_control DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    observaciones TEXT,
    resultado ENUM('APROBADO','RECHAZADO') NOT NULL,
    evidencia TEXT,
    registrado_por INT,
    FOREIGN KEY (id_lote) REFERENCES lotes(id_lote),
    FOREIGN KEY (registrado_por) REFERENCES usuarios(id_usuario)
) ENGINE=InnoDB;


CREATE TABLE backups (
    id_backup BIGINT AUTO_INCREMENT PRIMARY KEY,
    nombre_archivo VARCHAR(255) NOT NULL,
    ruta_archivo TEXT NOT NULL,
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    generado_por INT,
    estado ENUM('EXITOSO','ERROR') NOT NULL DEFAULT 'EXITOSO',
    mensaje TEXT,
    FOREIGN KEY (generado_por) REFERENCES usuarios(id_usuario)
);



CREATE TABLE IF NOT EXISTS auditoria_punteros (
  tabla_afectada VARCHAR(100) PRIMARY KEY,
  id_ultimo BIGINT NULL,
  hash_ultimo CHAR(64) NOT NULL DEFAULT '0000000000000000000000000000000000000000000000000000000000000000'
) ENGINE=InnoDB;



CREATE TABLE IF NOT EXISTS pacientes (
id_paciente INT PRIMARY KEY AUTO_INCREMENT,
tipo_documento ENUM ('CEDULA', 'TARJETA DE IDENTIDAD', 'TARJETA DE EXTRANJERÍA') NOT NULL,
documento VARCHAR (25) NOT NULL,
fecha_ingreso DATE NULL,
ultima_atencion DATE NULL,
nombre_completo VARCHAR (50)
)ENGINE = InnoDB;

CREATE TABLE ordenes (
    id_orden INT AUTO_INCREMENT PRIMARY KEY,
    id_paciente INT NOT NULL,
    id_usuario INT NOT NULL, -- quien genera la orden
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('PENDIENTE','PREPARACION','ENTREGADO','CANCELADO') DEFAULT 'PENDIENTE',
    observaciones VARCHAR(255),
    FOREIGN KEY (id_paciente) REFERENCES pacientes(id_paciente),
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
);

CREATE TABLE orden_detalle (
    id_detalle INT AUTO_INCREMENT PRIMARY KEY,
    id_orden INT NOT NULL,
    id_item INT NOT NULL,
    cantidad DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (id_orden) REFERENCES ordenes(id_orden),
    FOREIGN KEY (id_item) REFERENCES items(id_item)
);

/* ===========================================================
                    Procedimientos (CRUDs)
   =========================================================== */

-- Crear proveedor RF-06
DELIMITER //
CREATE PROCEDURE sp_crear_proveedor(
    IN p_nombre VARCHAR(150),
    IN p_nit VARCHAR(50)
)
BEGIN
    IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nombre obligatorio';
    END IF;
    IF p_nit IS NULL OR TRIM(p_nit) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'NIT obligatorio';
    END IF;
    INSERT INTO proveedores(nombre, nit) VALUES (p_nombre, p_nit);
    SELECT LAST_INSERT_ID() AS id_proveedor;
END//
DELIMITER ;

-- Obtener proveedor por ID
DELIMITER //
CREATE PROCEDURE sp_obtener_proveedor(IN p_id INT)
BEGIN
    SELECT * FROM proveedores WHERE id_proveedor = p_id;
END//
DELIMITER ;

-- Listar todos los proveedores
DELIMITER //
CREATE PROCEDURE sp_listar_proveedores()
BEGIN
    SELECT * FROM proveedores ORDER BY nombre;
END//
DELIMITER ;

-- Actualizar proveedor
DELIMITER //
CREATE PROCEDURE sp_actualizar_proveedor(
    IN p_id INT,
    IN p_nombre VARCHAR(150),
    IN p_nit VARCHAR(50)
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM proveedores WHERE id_proveedor = p_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Proveedor no existe';
    END IF;
    UPDATE proveedores SET nombre = p_nombre, nit = p_nit WHERE id_proveedor = p_id;
END//
DELIMITER ;

-- Eliminar proveedor
DELIMITER //
CREATE PROCEDURE sp_eliminar_proveedor(IN p_id INT)
BEGIN
    IF EXISTS (SELECT 1 FROM lotes WHERE id_proveedor = p_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar: tiene lotes asociados';
    END IF;
    DELETE FROM proveedores WHERE id_proveedor = p_id;
END//
DELIMITER ;

-- Crear ubicación RF-06
DELIMITER //
CREATE PROCEDURE sp_crear_ubicacion(
    IN p_nombre VARCHAR(100),
    IN p_tipo ENUM('ALMACEN','SERVICIO'),
    IN p_activo TINYINT
)
BEGIN
    IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nombre obligatorio';
    END IF;
    IF p_tipo NOT IN ('ALMACEN','SERVICIO') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tipo inválido';
    END IF;
    INSERT INTO ubicaciones(nombre, tipo, activo)
    VALUES (p_nombre, p_tipo, COALESCE(p_activo, 1));
    SELECT LAST_INSERT_ID() AS id_ubicacion;
END//
DELIMITER ;

-- Obtener ubicación por ID
DELIMITER //
CREATE PROCEDURE sp_obtener_ubicacion(IN p_id INT)
BEGIN
    SELECT * FROM ubicaciones WHERE id_ubicacion = p_id;
END//
DELIMITER ;

-- Listar todas las ubicaciones
DELIMITER //
CREATE PROCEDURE sp_listar_ubicaciones()
BEGIN
    SELECT * FROM ubicaciones ORDER BY nombre;
END//
DELIMITER ;

-- Actualizar ubicación
DELIMITER //
CREATE PROCEDURE sp_actualizar_ubicacion(
    IN p_id INT,
    IN p_nombre VARCHAR(100),
    IN p_tipo ENUM('ALMACEN','SERVICIO'),
    IN p_activo TINYINT
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM ubicaciones WHERE id_ubicacion = p_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ubicación no existe';
    END IF;
    IF p_tipo NOT IN ('ALMACEN','SERVICIO') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tipo inválido';
    END IF;
    UPDATE ubicaciones
    SET nombre = p_nombre,
        tipo = p_tipo,
        activo = p_activo
    WHERE id_ubicacion = p_id;
END//
DELIMITER ;

-- Eliminar ubicación
DELIMITER //
CREATE PROCEDURE sp_eliminar_ubicacion(IN p_id INT)
BEGIN
    IF EXISTS (SELECT 1 FROM existencias WHERE id_ubicacion = p_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar: tiene existencias';
    END IF;
    IF EXISTS (
        SELECT 1 FROM movimientos
        WHERE id_ubicacion_origen = p_id OR id_ubicacion_destino = p_id
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar: tiene movimientos asociados';
    END IF;
    DELETE FROM ubicaciones WHERE id_ubicacion = p_id;
END//
DELIMITER ;

-- Crear usuario FR-07
DELIMITER //
CREATE PROCEDURE sp_crear_usuario(
    IN p_nombre_completo VARCHAR(150),
    IN p_correo VARCHAR(150),
    IN p_rol ENUM('AUXILIAR','REGENTE','AUDITOR','ADMIN','PROVEEDOR'),
    IN p_contrasena VARCHAR(255)
)
BEGIN
    IF p_nombre_completo IS NULL OR TRIM(p_nombre_completo) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nombre completo obligatorio';
    END IF;
    IF p_correo IS NULL OR TRIM(p_correo) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Correo obligatorio';
    END IF;
    IF p_rol NOT IN ('AUXILIAR','REGENTE','AUDITOR','ADMIN','PROVEEDOR') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Rol inválido';
    END IF;
    IF p_contrasena NOT LIKE '$2%' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La contraseña debe estar cifrada con bcrypt';
    END IF;
    INSERT INTO usuarios(nombre_completo, correo, rol, contrasena)
    VALUES (p_nombre_completo, p_correo, p_rol, p_contrasena);
    SELECT LAST_INSERT_ID() AS id_usuario;
END//
DELIMITER ;

-- Obtener usuario por ID
DELIMITER //
CREATE PROCEDURE sp_obtener_usuario(IN p_id INT)
BEGIN
    SELECT id_usuario, nombre_completo, correo, rol, intentos_fallidos, bloqueado_hasta, fecha_ultimo_login
    FROM usuarios
    WHERE id_usuario = p_id;
END//
DELIMITER ;

-- Listar todos los usuarios
DELIMITER //
CREATE PROCEDURE sp_listar_usuarios()
BEGIN
    SELECT id_usuario, nombre_completo, correo, rol, intentos_fallidos, bloqueado_hasta, fecha_ultimo_login
    FROM usuarios
    ORDER BY nombre_completo;
END//
DELIMITER ;

-- Actualizar usuario
DELIMITER //
CREATE PROCEDURE sp_actualizar_usuario(
    IN p_id INT,
    IN p_nombre_completo VARCHAR(150),
    IN p_correo VARCHAR(150),
    IN p_rol ENUM('AUXILIAR','REGENTE','AUDITOR','ADMIN','PROVEEDOR'),
    IN p_contrasena VARCHAR(255)
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM usuarios WHERE id_usuario = p_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Usuario no existe';
    END IF;
    IF p_rol NOT IN ('AUXILIAR','REGENTE','AUDITOR','ADMIN','PROVEEDOR') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Rol inválido';
    END IF;
    IF p_contrasena NOT LIKE '$2%' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La contraseña debe estar cifrada con bcrypt';
    END IF;
    UPDATE usuarios
    SET nombre_completo = p_nombre_completo,
        correo = p_correo,
        rol = p_rol,
        contrasena = p_contrasena
    WHERE id_usuario = p_id;
END//
DELIMITER ;

-- Eliminar usuario
DELIMITER //
CREATE PROCEDURE sp_eliminar_usuario(IN p_id INT)
BEGIN
    IF EXISTS (SELECT 1 FROM movimientos WHERE id_usuario = p_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar: tiene movimientos registrados';
    END IF;
    DELETE FROM usuarios WHERE id_usuario = p_id;
END//
DELIMITER ;

-- ITEMS RF-06
-- Crear ítem
DELIMITER //
CREATE PROCEDURE sp_crear_item(
    IN p_id_ubicacion INT,
    IN p_codigo VARCHAR(50),
    IN p_descripcion VARCHAR(255),
    IN p_tipo_item ENUM('MEDICAMENTO','DISPOSITIVO'),
    IN p_unidad_medida VARCHAR(20),
    IN p_stock_minimo INT
)
BEGIN
    IF p_descripcion IS NULL OR TRIM(p_descripcion) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Descripción obligatoria';
    END IF;
    IF p_tipo_item NOT IN ('MEDICAMENTO','DISPOSITIVO') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tipo de ítem inválido';
    END IF;
    INSERT INTO items(id_ubicacion, codigo, descripcion, tipo_item, unidad_medida, stock_minimo)
    VALUES (p_id_ubicacion, p_codigo, p_descripcion, p_tipo_item, COALESCE(p_unidad_medida, 'UND'), COALESCE(p_stock_minimo, 0));
    SELECT LAST_INSERT_ID() AS id_item;
END//
DELIMITER ;

-- Obtener ítem por ID
DELIMITER //
CREATE PROCEDURE sp_obtener_item(IN p_id INT)
BEGIN
    SELECT * FROM items WHERE id_item = p_id;
END//
DELIMITER ;

-- Listar todos los ítems
DELIMITER //
CREATE PROCEDURE sp_listar_items()
BEGIN
    SELECT * FROM items ORDER BY descripcion;
END//
DELIMITER ;

-- Actualizar ítem
DELIMITER //
CREATE PROCEDURE sp_actualizar_item(
    IN p_id INT,
    IN p_id_ubicacion INT,
    IN p_codigo VARCHAR(50),
    IN p_descripcion VARCHAR(255),
    IN p_tipo_item ENUM('MEDICAMENTO','DISPOSITIVO'),
    IN p_unidad_medida VARCHAR(20),
    IN p_stock_minimo INT
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM items WHERE id_item = p_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ítem no existe';
    END IF;
    IF p_tipo_item NOT IN ('MEDICAMENTO','DISPOSITIVO') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tipo de ítem inválido';
    END IF;
    UPDATE items
    SET id_ubicacion = p_id_ubicacion,
        codigo = p_codigo,
        descripcion = p_descripcion,
        tipo_item = p_tipo_item,
        unidad_medida = p_unidad_medida,
        stock_minimo = p_stock_minimo
    WHERE id_item = p_id;
END//
DELIMITER ;

-- Eliminar ítem
DELIMITER //
CREATE PROCEDURE sp_eliminar_item(IN p_id INT)
BEGIN
    IF EXISTS (SELECT 1 FROM lotes WHERE id_item = p_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar: tiene lotes asociados';
    END IF;
    DELETE FROM items WHERE id_item = p_id;
END//
DELIMITER ;

-- LOTES
-- Crear lote
-- LOTES (refactor sin campos de posición)
DELIMITER //
CREATE PROCEDURE sp_crear_lote(
  IN p_id_item INT,
  IN p_id_proveedor INT,
  IN p_codigo_lote VARCHAR(50),
  IN p_fecha_vencimiento DATE,
  IN p_costo_unitario DECIMAL(10,2)
)
BEGIN
  IF p_fecha_vencimiento < CURRENT_DATE() THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Fecha de vencimiento inválida';
  END IF;
  IF p_costo_unitario <= 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Costo unitario > 0';
  END IF;

  INSERT INTO lotes(id_item, id_proveedor, codigo_lote, fecha_vencimiento, costo_unitario)
  VALUES (p_id_item, p_id_proveedor, p_codigo_lote, p_fecha_vencimiento, p_costo_unitario);

  SELECT LAST_INSERT_ID() AS id_lote;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_actualizar_lote(
  IN p_id INT,
  IN p_fecha_vencimiento DATE,
  IN p_costo_unitario DECIMAL(10,2)
)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM lotes WHERE id_lote = p_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lote no existe';
  END IF;
  IF p_fecha_vencimiento < CURRENT_DATE() THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Fecha de vencimiento inválida';
  END IF;
  IF p_costo_unitario <= 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Costo unitario > 0';
  END IF;

  UPDATE lotes
    SET fecha_vencimiento = p_fecha_vencimiento,
        costo_unitario    = p_costo_unitario
  WHERE id_lote = p_id;
END//
DELIMITER ;

-- Obtener lote por ID
DELIMITER //
CREATE PROCEDURE sp_obtener_lote(IN p_id INT)
BEGIN
    SELECT * FROM lotes WHERE id_lote = p_id;
END//
DELIMITER ;

-- Listar todos los lotes
DELIMITER //
CREATE PROCEDURE sp_listar_lotes()
BEGIN
    SELECT * FROM lotes ORDER BY fecha_vencimiento DESC;
END//
DELIMITER ;

-- Eliminar lote
DELIMITER //
CREATE PROCEDURE sp_eliminar_lote(IN p_id INT)
BEGIN
    IF EXISTS (SELECT 1 FROM existencias WHERE id_lote = p_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar: tiene existencias asociadas';
    END IF;
    IF EXISTS (SELECT 1 FROM movimientos WHERE id_lote = p_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar: tiene movimientos registrados';
    END IF;
    DELETE FROM lotes WHERE id_lote = p_id;
END//
DELIMITER ;

-- EXISTENCIAS
-- Crear existencia
DELIMITER //
CREATE PROCEDURE sp_crear_existencia(
    IN p_id_lote INT,
    IN p_id_ubicacion INT,
    IN p_saldo INT
)
BEGIN
    IF p_saldo < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El saldo no puede ser negativo';
    END IF;
    INSERT INTO existencias(id_lote, id_ubicacion, saldo)
    VALUES (p_id_lote, p_id_ubicacion, p_saldo);
    SELECT LAST_INSERT_ID() AS id_existencia;
END//
DELIMITER ;

-- Obtener existencia por ID
DELIMITER //
CREATE PROCEDURE sp_obtener_existencia(IN p_id BIGINT)
BEGIN
    SELECT * FROM existencias WHERE id_existencia = p_id;
END//
DELIMITER ;

-- Listar todas las existencias
DELIMITER //
CREATE PROCEDURE sp_listar_existencias()
BEGIN
    SELECT * FROM existencias ORDER BY id_lote, id_ubicacion;
END//
DELIMITER ;

-- Actualizar existencia
DELIMITER //
CREATE PROCEDURE sp_actualizar_existencia(
    IN p_id BIGINT,
    IN p_saldo INT
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM existencias WHERE id_existencia = p_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Existencia no encontrada';
    END IF;
    IF p_saldo < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El saldo no puede ser negativo';
    END IF;
    UPDATE existencias
    SET saldo = p_saldo
    WHERE id_existencia = p_id;
END//
DELIMITER ;

-- Eliminar existencia
DELIMITER //
CREATE PROCEDURE sp_eliminar_existencia(IN p_id BIGINT)
BEGIN
    DELETE FROM existencias WHERE id_existencia = p_id;
END//
DELIMITER ;

-- PARÁMETROS (wrappers)
-- Crear parámetro
DELIMITER //
CREATE PROCEDURE sp_crear_parametro(
    IN p_clave VARCHAR(50),
    IN p_valor VARCHAR(100),
    IN p_descripcion VARCHAR(255)
)
BEGIN
    IF p_clave IS NULL OR TRIM(p_clave) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Clave obligatoria';
    END IF;
    INSERT INTO parametros_sistema(clave, valor, descripcion)
    VALUES (p_clave, p_valor, p_descripcion);
END//
DELIMITER ;

-- Obtener parámetro por clave
DELIMITER //
CREATE PROCEDURE sp_obtener_parametro(IN p_clave VARCHAR(50))
BEGIN
    SELECT * FROM parametros_sistema WHERE clave = p_clave;
END//
DELIMITER ;

-- Listar todos los parámetros
DELIMITER //
CREATE PROCEDURE sp_listar_parametros()
BEGIN
    SELECT * FROM parametros_sistema ORDER BY clave;
END//
DELIMITER ;

-- Actualizar parámetro
DELIMITER //
CREATE PROCEDURE sp_actualizar_parametro(
    IN p_clave VARCHAR(50),
    IN p_valor VARCHAR(100),
    IN p_descripcion VARCHAR(255)
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM parametros_sistema WHERE clave = p_clave) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Parámetro no existe';
    END IF;
    UPDATE parametros_sistema
    SET valor = p_valor,
        descripcion = p_descripcion
    WHERE clave = p_clave;
END//
DELIMITER ;

-- Eliminar parámetro
DELIMITER //
CREATE PROCEDURE sp_eliminar_parametro(IN p_clave VARCHAR(50))
BEGIN
    DELETE FROM parametros_sistema WHERE clave = p_clave;
END//
DELIMITER ;

-- AUDITORIA RF-07

-- Registrar evento de auditoría (solo si se desea hacerlo manualmente)

DELIMITER //
CREATE PROCEDURE sp_crear_evento_auditoria(
  IN p_tabla_afectada VARCHAR(100),
  IN p_pk_afectada VARCHAR(100),
  IN p_accion ENUM('INSERT','UPDATE','DELETE'),
  IN p_valores_antes JSON,
  IN p_valores_despues JSON,
  IN p_id_usuario INT
)
BEGIN
  -- Wrapper: delega en el SP central con fecha NOW()
  CALL sp_auditar_encadenado(
    p_tabla_afectada,
    p_pk_afectada,
    p_accion,
    p_valores_antes,
    p_valores_despues,
    p_id_usuario,
    NOW()
  );
END//
DELIMITER ;
-- Obtener evento por ID
DELIMITER //
CREATE PROCEDURE sp_obtener_evento_auditoria(IN p_id BIGINT)
BEGIN
    SELECT * FROM auditoria WHERE id_evento = p_id;
END//
DELIMITER ;

-- Listar eventos de auditoría
DELIMITER //
CREATE PROCEDURE sp_listar_auditoria()
BEGIN
    SELECT * FROM auditoria ORDER BY fecha DESC;
END//
DELIMITER ;

-- NOTIFICACIONES
-- Crear notificación
DELIMITER //
CREATE PROCEDURE sp_crear_notificacion(
  IN p_tipo ENUM('ALERTA_VENCIMIENTO','ALERTA_STOCK_BAJO','ALERTA_STOCK_CRITICO','BACKUP'),
  IN p_payload JSON,
  IN p_destinatario VARCHAR(150),
  IN p_estado ENUM('PENDIENTE','ENVIADA','ERROR'),
  IN p_detalle_error VARCHAR(255)
)
BEGIN
  IF p_tipo NOT IN ('ALERTA_VENCIMIENTO','ALERTA_STOCK_BAJO','ALERTA_STOCK_CRITICO','BACKUP') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tipo de notificación inválido';
  END IF;

  INSERT INTO notificaciones(tipo, payload, destinatario, estado, detalle_error)
  VALUES (p_tipo, p_payload, p_destinatario, COALESCE(p_estado,'PENDIENTE'), p_detalle_error);

  SELECT LAST_INSERT_ID() AS id_notificacion;
END//
DELIMITER ;

-- Obtener notificación por ID
DELIMITER //
CREATE PROCEDURE sp_obtener_notificacion(IN p_id BIGINT)
BEGIN
    SELECT * FROM notificaciones WHERE id_notificacion = p_id;
END//
DELIMITER ;

-- Listar todas las notificaciones
DELIMITER //
CREATE PROCEDURE sp_listar_notificaciones()
BEGIN
    SELECT * FROM notificaciones ORDER BY fecha_creacion DESC;
END//
DELIMITER ;

-- Actualizar notificación
DELIMITER //
CREATE PROCEDURE sp_actualizar_notificacion(
  IN p_id BIGINT,
  IN p_estado ENUM('PENDIENTE','ENVIADA','ERROR'),
  IN p_detalle_error VARCHAR(255),
  IN p_confirmado_por INT,
  IN p_estado_confirmacion ENUM('PENDIENTE','REVISADA')
)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM notificaciones WHERE id_notificacion = p_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Notificación no existe';
  END IF;

  UPDATE notificaciones
     SET estado               = p_estado,
         detalle_error        = p_detalle_error,
         confirmado_por       = p_confirmado_por,
         -- fecha_confirmacion: la maneja el trigger trg_notif_bu_confirmacion
         estado_confirmacion  = p_estado_confirmacion
   WHERE id_notificacion = p_id;
END//
DELIMITER ;

-- Eliminar notificación
DELIMITER //
CREATE PROCEDURE sp_eliminar_notificacion(IN p_id BIGINT)
BEGIN
    DELETE FROM notificaciones WHERE id_notificacion = p_id;
END//
DELIMITER ;

-- STG_INVENTARIO_INICIAL
-- Crear registro de inventario inicial
DELIMITER //
CREATE PROCEDURE sp_crear_stg_inventario_inicial(
    IN p_codigo_item VARCHAR(50),
    IN p_nit_proveedor VARCHAR(50),
    IN p_codigo_lote VARCHAR(50),
    IN p_fecha_vencimiento DATE,
    IN p_costo_unitario DECIMAL(10,2),
    IN p_nombre_ubicacion VARCHAR(100),
    IN p_cantidad INT
)
BEGIN
    IF p_cantidad <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cantidad debe ser mayor a cero';
    END IF;
    INSERT INTO stg_inventario_inicial(
        codigo_item, nit_proveedor, codigo_lote, fecha_vencimiento,
        costo_unitario, nombre_ubicacion, cantidad
    )
    VALUES (
        p_codigo_item, p_nit_proveedor, p_codigo_lote, p_fecha_vencimiento,
        p_costo_unitario, p_nombre_ubicacion, p_cantidad
    );
END//
DELIMITER ;

-- Obtener registro por código de ítem y lote
DELIMITER //
CREATE PROCEDURE sp_obtener_stg_inventario_inicial(
    IN p_codigo_item VARCHAR(50),
    IN p_codigo_lote VARCHAR(50)
)
BEGIN
    SELECT * FROM stg_inventario_inicial
    WHERE codigo_item = p_codigo_item AND codigo_lote = p_codigo_lote;
END//
DELIMITER ;

-- Listar todos los registros
DELIMITER //
CREATE PROCEDURE sp_listar_stg_inventario_inicial()
BEGIN
    SELECT * FROM stg_inventario_inicial ORDER BY nombre_ubicacion, codigo_item;
END//
DELIMITER ;

-- Actualizar registro
DELIMITER //
CREATE PROCEDURE sp_actualizar_stg_inventario_inicial(
    IN p_codigo_item VARCHAR(50),
    IN p_codigo_lote VARCHAR(50),
    IN p_fecha_vencimiento DATE,
    IN p_costo_unitario DECIMAL(10,2),
    IN p_nombre_ubicacion VARCHAR(100),
    IN p_cantidad INT
)
BEGIN
    IF p_cantidad <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cantidad debe ser mayor a cero';
    END IF;
    UPDATE stg_inventario_inicial
    SET fecha_vencimiento = p_fecha_vencimiento,
        costo_unitario = p_costo_unitario,
        nombre_ubicacion = p_nombre_ubicacion,
        cantidad = p_cantidad
    WHERE codigo_item = p_codigo_item AND codigo_lote = p_codigo_lote;
END//
DELIMITER ;

-- Eliminar registro
DELIMITER //
CREATE PROCEDURE sp_eliminar_stg_inventario_inicial(
    IN p_codigo_item VARCHAR(50),
    IN p_codigo_lote VARCHAR(50)
)
BEGIN
    DELETE FROM stg_inventario_inicial
    WHERE codigo_item = p_codigo_item AND codigo_lote = p_codigo_lote;
END//
DELIMITER ;

-- SESIONES ACTIVAS
-- Crear sesión activa
DELIMITER //
CREATE PROCEDURE sp_crear_sesion_activa(
    IN p_id_usuario INT,
    IN p_ip VARCHAR(45)
)
BEGIN
    INSERT INTO sesiones_activas(id_usuario, ip)
    VALUES (p_id_usuario, p_ip);
    SELECT LAST_INSERT_ID() AS id_sesion;
END//
DELIMITER ;

-- Obtener sesión por ID
DELIMITER //
CREATE PROCEDURE sp_obtener_sesion_activa(IN p_id BIGINT)
BEGIN
    SELECT * FROM sesiones_activas WHERE id_sesion = p_id;
END//
DELIMITER ;


-- Actualizar sesión (por ejemplo, marcar como inactiva)
DELIMITER //
CREATE PROCEDURE sp_actualizar_sesion_activa(
    IN p_id BIGINT,
    IN p_activo TINYINT
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sesiones_activas WHERE id_sesion = p_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Sesión no encontrada';
    END IF;
    UPDATE sesiones_activas
    SET activo = p_activo
    WHERE id_sesion = p_id;
END//
DELIMITER ;

-- Eliminar sesión
DELIMITER //
CREATE PROCEDURE sp_eliminar_sesion_activa(IN p_id BIGINT)
BEGIN
    DELETE FROM sesiones_activas WHERE id_sesion = p_id;
END//
DELIMITER ;

-- ETIQUETAS QR

-- Crear etiqueta QR
DELIMITER //
CREATE PROCEDURE sp_crear_etiqueta_qr(
    IN p_id_lote INT,
    IN p_contenido_qr TEXT
)
BEGIN
    IF p_contenido_qr IS NULL OR TRIM(p_contenido_qr) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Contenido QR obligatorio';
    END IF;
    INSERT INTO etiquetas_qr(id_lote, contenido_qr)
    VALUES (p_id_lote, p_contenido_qr);
    SELECT LAST_INSERT_ID() AS id_etiqueta;
END//
DELIMITER ;

-- Obtener etiqueta por ID
DELIMITER //
CREATE PROCEDURE sp_obtener_etiqueta_qr(IN p_id INT)
BEGIN
    SELECT * FROM etiquetas_qr WHERE id_etiqueta = p_id;
END//
DELIMITER ;

-- Listar etiquetas por lote


-- Actualizar etiqueta QR
DELIMITER //
CREATE PROCEDURE sp_actualizar_etiqueta_qr(
    IN p_id INT,
    IN p_contenido_qr TEXT
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM etiquetas_qr WHERE id_etiqueta = p_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Etiqueta no encontrada';
    END IF;
    UPDATE etiquetas_qr
    SET contenido_qr = p_contenido_qr
    WHERE id_etiqueta = p_id;
END//
DELIMITER ;

-- Eliminar etiqueta QR
DELIMITER //
CREATE PROCEDURE sp_eliminar_etiqueta_qr(IN p_id INT)
BEGIN
    DELETE FROM etiquetas_qr WHERE id_etiqueta = p_id;
END//
DELIMITER ;

-- MOVIMIENTOS

-- Crear movimiento
-- Restringe sp_crear_movimiento: redirige a SP especializados para garantizar auditoria
DELIMITER //
CREATE PROCEDURE sp_crear_movimiento(
  IN p_id_lote INT,
  IN p_id_usuario INT,
  IN p_tipo ENUM('INGRESO','SALIDA','TRANSFERENCIA','AJUSTE'),
  IN p_cantidad INT,
  IN p_id_ubicacion_origen INT,
  IN p_id_ubicacion_destino INT,
  IN p_motivo VARCHAR(255)
)
BEGIN
  SIGNAL SQLSTATE '45000'
  SET MESSAGE_TEXT = 'Use los SP dedicados: sp_registrar_ingreso/salida, sp_transferir_stock, sp_ajustar_stock';
END//


-- Obtener movimiento por ID
DELIMITER //
CREATE PROCEDURE sp_obtener_movimiento(IN p_id BIGINT)
BEGIN
    SELECT * FROM movimientos WHERE id_movimiento = p_id;
END//
DELIMITER ;

-- Listar movimientos por lote
DELIMITER //
CREATE PROCEDURE sp_listar_movimientos_por_lote(IN p_id_lote INT)
BEGIN
    SELECT * FROM movimientos
    WHERE id_lote = p_id_lote
    ORDER BY fecha DESC;
END//
DELIMITER ;

-- Listar movimientos por fecha
DELIMITER //
CREATE PROCEDURE sp_listar_movimientos_por_fecha(
    IN p_desde DATETIME,
    IN p_hasta DATETIME
)
BEGIN
    SELECT * FROM movimientos
    WHERE fecha BETWEEN p_desde AND p_hasta
    ORDER BY fecha DESC;
END//
DELIMITER ;

-- COMPROBANTES RECEPCION

-- Crear comprobante de recepción
DELIMITER //
CREATE PROCEDURE sp_crear_comprobante_recepcion(
    IN p_id_movimiento BIGINT,
    IN p_id_proveedor INT,
    IN p_canal ENUM('PORTAL','EMAIL'),
    IN p_entregado TINYINT
)
BEGIN
    IF p_canal NOT IN ('PORTAL','EMAIL') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Canal inválido';
    END IF;
    INSERT INTO comprobantes_recepcion(
        id_movimiento, id_proveedor, canal, entregado
    )
    VALUES (
        p_id_movimiento, p_id_proveedor, p_canal, COALESCE(p_entregado, 0)
    );
    SELECT LAST_INSERT_ID() AS id_comprobante;
END//
DELIMITER ;

-- Obtener comprobante por ID
DELIMITER //
CREATE PROCEDURE sp_obtener_comprobante_recepcion(IN p_id BIGINT)
BEGIN
    SELECT * FROM comprobantes_recepcion WHERE id_comprobante = p_id;
END//
DELIMITER ;

-- Listar comprobantes por proveedor
DELIMITER //
CREATE PROCEDURE sp_listar_comprobantes_recepcion(IN p_id_proveedor INT)
BEGIN
    SELECT * FROM comprobantes_recepcion
    WHERE id_proveedor = p_id_proveedor
    ORDER BY fecha_creacion DESC;
END//
DELIMITER ;

-- Actualizar comprobante
DELIMITER //
CREATE PROCEDURE sp_actualizar_comprobante_recepcion(
    IN p_id BIGINT,
    IN p_entregado TINYINT,
    IN p_fecha_entrega DATETIME
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM comprobantes_recepcion WHERE id_comprobante = p_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Comprobante no encontrado';
    END IF;
    UPDATE comprobantes_recepcion
    SET entregado = p_entregado,
        fecha_entrega = p_fecha_entrega
    WHERE id_comprobante = p_id;
END//
DELIMITER ;

-- Eliminar comprobante
DELIMITER //
CREATE PROCEDURE sp_eliminar_comprobante_recepcion(IN p_id BIGINT)
BEGIN
    DELETE FROM comprobantes_recepcion WHERE id_comprobante = p_id;
END//
DELIMITER ;

-- TOKENS RECUPERACION
-- Crear token de recuperación
DELIMITER //
CREATE PROCEDURE sp_crear_token_recuperacion(
    IN p_id_usuario INT,
    IN p_token VARCHAR(255),
    IN p_expiracion DATETIME
)
BEGIN
    INSERT INTO tokens_recuperacion(id_usuario, token, expiracion)
    VALUES (p_id_usuario, p_token, p_expiracion);
    SELECT LAST_INSERT_ID() AS id_token;
END//
DELIMITER ;

-- Obtener token por ID
DELIMITER //
CREATE PROCEDURE sp_obtener_token_recuperacion(IN p_id BIGINT)
BEGIN
    SELECT * FROM tokens_recuperacion WHERE id_token = p_id;
END//
DELIMITER ;

-- Listar todos los tokens
DELIMITER //
CREATE PROCEDURE sp_listar_tokens_recuperacion()
BEGIN
    SELECT * FROM tokens_recuperacion ORDER BY expiracion DESC;
END//
DELIMITER ;

-- Actualizar token (por ejemplo, marcar como usado)
DELIMITER //
CREATE PROCEDURE sp_actualizar_token_recuperacion(
    IN p_id BIGINT,
    IN p_usado TINYINT
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tokens_recuperacion WHERE id_token = p_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Token no encontrado';
    END IF;
    UPDATE tokens_recuperacion
    SET usado = p_usado
    WHERE id_token = p_id;
END//
DELIMITER ;

-- Eliminar token
DELIMITER //
CREATE PROCEDURE sp_eliminar_token_recuperacion(IN p_id BIGINT)
BEGIN
    DELETE FROM tokens_recuperacion WHERE id_token = p_id;
END//
DELIMITER ;

-- INCIDENTES ALMACENAMIENTO

-- Crear incidente de almacenamiento
DELIMITER //
CREATE PROCEDURE sp_crear_incidente_almacenamiento(
    IN p_descripcion TEXT,
    IN p_responsable VARCHAR(150),
    IN p_accion_correctiva TEXT,
    IN p_evidencia TEXT
)
BEGIN
    IF p_descripcion IS NULL OR TRIM(p_descripcion) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Descripción obligatoria';
    END IF;
    IF p_responsable IS NULL OR TRIM(p_responsable) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Responsable obligatorio';
    END IF;
    INSERT INTO incidentes_almacenamiento(
        descripcion, responsable, accion_correctiva, evidencia
    )
    VALUES (
        p_descripcion, p_responsable, p_accion_correctiva, p_evidencia
    );
    SELECT LAST_INSERT_ID() AS id_incidente;
END//
DELIMITER ;

-- Obtener incidente por ID
DELIMITER //
CREATE PROCEDURE sp_obtener_incidente_almacenamiento(IN p_id INT)
BEGIN
    SELECT * FROM incidentes_almacenamiento WHERE id_incidente = p_id;
END//
DELIMITER ;

-- Listar todos los incidentes
DELIMITER //
CREATE PROCEDURE sp_listar_incidentes_almacenamiento()
BEGIN
    SELECT * FROM incidentes_almacenamiento ORDER BY fecha DESC;
END//
DELIMITER ;

-- Actualizar incidente
DELIMITER //
CREATE PROCEDURE sp_actualizar_incidente_almacenamiento(
    IN p_id INT,
    IN p_descripcion TEXT,
    IN p_responsable VARCHAR(150),
    IN p_accion_correctiva TEXT,
    IN p_evidencia TEXT
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM incidentes_almacenamiento WHERE id_incidente = p_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Incidente no encontrado';
    END IF;
    UPDATE incidentes_almacenamiento
    SET descripcion = p_descripcion,
        responsable = p_responsable,
        accion_correctiva = p_accion_correctiva,
        evidencia = p_evidencia
    WHERE id_incidente = p_id;
END//
DELIMITER ;

-- Eliminar incidente
DELIMITER //
CREATE PROCEDURE sp_eliminar_incidente_almacenamiento(IN p_id INT)
BEGIN
    DELETE FROM incidentes_almacenamiento WHERE id_incidente = p_id;
END//
DELIMITER ;

-- CONTROL CALIDAD

-- Crear control de calidad
DELIMITER //
CREATE PROCEDURE sp_crear_control_calidad(
    IN p_id_lote INT,
    IN p_observaciones TEXT,
    IN p_resultado ENUM('APROBADO','RECHAZADO'),
    IN p_evidencia TEXT
)
BEGIN
    IF p_resultado NOT IN ('APROBADO','RECHAZADO') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Resultado inválido';
    END IF;
    INSERT INTO control_calidad(id_lote, observaciones, resultado, evidencia)
    VALUES (p_id_lote, p_observaciones, p_resultado, p_evidencia);
    SELECT LAST_INSERT_ID() AS id_control;
END//
DELIMITER ;

-- Obtener control por ID
DELIMITER //
CREATE PROCEDURE sp_obtener_control_calidad(IN p_id INT)
BEGIN
    SELECT * FROM control_calidad WHERE id_control = p_id;
END//
DELIMITER ;

-- Listar controles por lote
DELIMITER //
CREATE PROCEDURE sp_listar_controles_calidad(IN p_id_lote INT)
BEGIN	
    SELECT * FROM control_calidad
    WHERE id_lote = p_id_lote
    ORDER BY fecha_control DESC;
END//
DELIMITER ;

-- Actualizar control de calidad
DELIMITER //
CREATE PROCEDURE sp_actualizar_control_calidad(
    IN p_id INT,
    IN p_observaciones TEXT,
    IN p_resultado ENUM('APROBADO','RECHAZADO'),
    IN p_evidencia TEXT
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM control_calidad WHERE id_control = p_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Control no encontrado';
    END IF;
    IF p_resultado NOT IN ('APROBADO','RECHAZADO') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Resultado inválido';
    END IF;
    UPDATE control_calidad
    SET observaciones = p_observaciones,
        resultado = p_resultado,
        evidencia = p_evidencia
    WHERE id_control = p_id;
END//
DELIMITER ;

-- Eliminar control de calidad


-- CREAR POSICION DEL LOTE
-- CREATE
DELIMITER //
CREATE PROCEDURE sp_crear_lote_posicion(
  IN p_id_lote INT,
  IN p_id_ubicacion INT,     -- debe ser tipo 'ALMACEN'
  IN p_estante VARCHAR(20),
  IN p_nivel   VARCHAR(20),
  IN p_pasillo VARCHAR(20),
  IN p_asignado_por INT
)
BEGIN

  IF (p_estante IS NULL OR p_nivel IS NULL OR p_pasillo IS NULL) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'estante/nivel/pasillo obligatorios';
  END IF;

  INSERT INTO lotes_posiciones(id_lote,id_ubicacion,estante,nivel,pasillo,asignado_por)
  VALUES (p_id_lote,p_id_ubicacion,p_estante,p_nivel,p_pasillo,p_asignado_por);

  SELECT LAST_INSERT_ID() AS id_posicion;
END//
DELIMITER ;

-- READ por PK
DELIMITER //
CREATE PROCEDURE sp_obtener_lote_posicion(IN p_id_pos BIGINT)
BEGIN
  SELECT * FROM lotes_posiciones WHERE id_posicion = p_id_pos;
END//
DELIMITER ;

-- LIST por lote
DELIMITER //
CREATE PROCEDURE sp_listar_lote_posiciones(IN p_id_lote INT)
BEGIN
  SELECT lp.*, u.nombre AS ubicacion
  FROM lotes_posiciones lp
  JOIN ubicaciones u ON u.id_ubicacion = lp.id_ubicacion
  WHERE lp.id_lote = p_id_lote
  ORDER BY lp.id_ubicacion, lp.estante, lp.nivel, lp.pasillo;
END//
DELIMITER ;

-- UPDATE (cambia tripleta física y/o ubicación)
DELIMITER //
CREATE PROCEDURE sp_actualizar_lote_posicion(
  IN p_id_pos BIGINT,
  IN p_id_ubicacion INT,
  IN p_estante VARCHAR(20),
  IN p_nivel   VARCHAR(20),
  IN p_pasillo VARCHAR(20)
)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM lotes_posiciones WHERE id_posicion = p_id_pos) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Posición no existe';
  END IF;
  UPDATE lotes_posiciones
     SET id_ubicacion = p_id_ubicacion,
         estante      = p_estante,
         nivel        = p_nivel,
         pasillo      = p_pasillo
   WHERE id_posicion  = p_id_pos;
END//
DELIMITER ;

-- DELETE
DELIMITER //
CREATE PROCEDURE sp_eliminar_lote_posicion(IN p_id_pos BIGINT)
BEGIN
  DELETE FROM lotes_posiciones WHERE id_posicion = p_id_pos;
END//
DELIMITER ;

-- BACKUPS
DELIMITER //
CREATE PROCEDURE sp_crear_backup(
  IN p_nombre_archivo VARCHAR(255),
  IN p_ruta_archivo TEXT,
  IN p_generado_por INT,
  IN p_estado ENUM('EXITOSO','ERROR'),
  IN p_mensaje TEXT
)
BEGIN
  INSERT INTO backups(nombre_archivo, ruta_archivo, generado_por, estado, mensaje)
  VALUES (p_nombre_archivo, p_ruta_archivo, p_generado_por, p_estado, p_mensaje);
  SELECT LAST_INSERT_ID() AS id_backup;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_obtener_backup(IN p_id BIGINT)
BEGIN
  SELECT * FROM backups WHERE id_backup = p_id;
END//	
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_listar_backups(
  IN p_desde DATETIME,
  IN p_hasta DATETIME,
  IN p_estado ENUM('EXITOSO','ERROR')
)
BEGIN
  SELECT b.*, u.nombre_completo AS generado_por_nombre
  FROM backups b
  LEFT JOIN usuarios u ON u.id_usuario = b.generado_por
  WHERE (p_desde IS NULL OR b.fecha_creacion >= p_desde)
    AND (p_hasta IS NULL OR b.fecha_creacion <= p_hasta)
    AND (p_estado IS NULL OR b.estado = p_estado)
  ORDER BY b.fecha_creacion DESC;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_actualizar_backup(
  IN p_id BIGINT,
  IN p_estado ENUM('EXITOSO','ERROR'),
  IN p_mensaje TEXT
)
BEGIN
  UPDATE backups SET estado = p_estado, mensaje = p_mensaje WHERE id_backup = p_id;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_eliminar_backup(IN p_id BIGINT)
BEGIN
  DELETE FROM backups WHERE id_backup = p_id;
END//
DELIMITER ;

-- HU-01, RF-01
DELIMITER //
CREATE PROCEDURE sp_registrar_ingreso(
  IN p_id_item INT, IN p_id_proveedor INT, IN p_codigo_lote VARCHAR(50),
  IN p_fecha_venc DATE, IN p_costo_unitario DECIMAL(10,2),
  IN p_id_ubicacion_destino INT, IN p_cantidad INT, IN p_id_usuario INT, IN p_motivo VARCHAR(255)
)
BEGIN
  DECLARE v_id_lote INT;
  IF p_cantidad <= 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cantidad debe ser > 0';
  END IF;
	 SET @ctx_id_usuario = p_id_usuario;
  START TRANSACTION;
  CALL sp_asegurar_lote(p_id_item, p_id_proveedor, p_codigo_lote, p_fecha_venc, p_costo_unitario, v_id_lote);
  INSERT INTO movimientos(id_lote, id_usuario, tipo, cantidad, id_ubicacion_destino, motivo)
  VALUES (v_id_lote, p_id_usuario, 'INGRESO', p_cantidad, p_id_ubicacion_destino, COALESCE(p_motivo,'Recepción de proveedor'));
  COMMIT;
  SET @ctx_id_usuario = NULL;
END//
DELIMITER ;

-- HU-01 RF-01
DELIMITER //
CREATE PROCEDURE sp_mov_registrar_ingreso(
  IN p_id_item INT, IN p_id_proveedor INT, IN p_codigo_lote VARCHAR(50),
  IN p_fecha_venc DATE, IN p_costo_unitario DECIMAL(10,2), IN p_id_ubic_dest INT,
  IN p_cantidad INT, IN p_id_usuario INT, IN p_motivo VARCHAR(255)
)
BEGIN
  CALL sp_registrar_ingreso(p_id_item, p_id_proveedor, p_codigo_lote, p_fecha_venc,
    p_costo_unitario, p_id_ubic_dest, p_cantidad, p_id_usuario, p_motivo);
END//
DELIMITER;

-- HU-01, RF-01
DELIMITER //
CREATE PROCEDURE sp_asegurar_lote(
  IN  p_id_item INT, IN  p_id_proveedor INT, IN  p_codigo_lote VARCHAR(50),
  IN  p_fecha_venc DATE, IN  p_costo_unitario DECIMAL(10,2),
  OUT p_id_lote INT
)
BEGIN
  IF p_fecha_venc < CURRENT_DATE() THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Fecha de vencimiento inválida (pasada)';
  END IF;
  SELECT id_lote INTO p_id_lote
  FROM lotes
  WHERE id_item = p_id_item AND codigo_lote = p_codigo_lote
  LIMIT 1;

  IF p_id_lote IS NULL THEN
    INSERT INTO lotes(id_item, id_proveedor, codigo_lote, fecha_vencimiento, costo_unitario)
    VALUES (p_id_item, p_id_proveedor, p_codigo_lote, p_fecha_venc, p_costo_unitario);
    SET p_id_lote = LAST_INSERT_ID();
  END IF;
END//
DELIMITER;

-- HU-02, RF-02
-- Añade validación de tipo SERVICIO en sp_registrar_salida
DELIMITER //
CREATE PROCEDURE sp_registrar_salida(
  IN p_id_lote INT, IN p_id_ubicacion_origen INT, IN p_id_ubicacion_destino INT,
  IN p_cantidad INT, IN p_id_usuario INT, IN p_motivo VARCHAR(255)
)
BEGIN
  DECLARE v_saldo INT;
  DECLARE v_tipo_dest ENUM('ALMACEN','SERVICIO');

  IF p_cantidad <= 0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cantidad debe ser > 0'; END IF;
  IF p_motivo IS NULL OR TRIM(p_motivo) = '' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Motivo es obligatorio en SALIDA'; END IF;
  IF p_id_ubicacion_destino IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'SALIDA requiere id_ubicacion_destino (servicio)'; END IF;

  SELECT tipo INTO v_tipo_dest FROM ubicaciones WHERE id_ubicacion = p_id_ubicacion_destino;
  IF v_tipo_dest IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ubicación destino no existe'; END IF;
  IF v_tipo_dest <> 'SERVICIO' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Destino debe ser de tipo SERVICIO'; END IF;

  START TRANSACTION;
    SELECT saldo INTO v_saldo
    FROM existencias
    WHERE id_lote = p_id_lote AND id_ubicacion = p_id_ubicacion_origen
    FOR UPDATE;
    IF v_saldo IS NULL OR v_saldo < p_cantidad THEN
      ROLLBACK; SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stock insuficiente para SALIDA';
    END IF;

    INSERT INTO movimientos(id_lote, id_usuario, tipo, cantidad, id_ubicacion_origen, id_ubicacion_destino, motivo)
    VALUES (p_id_lote, p_id_usuario, 'SALIDA', p_cantidad, p_id_ubicacion_origen, p_id_ubicacion_destino, p_motivo);
  COMMIT;
END//
DELIMITER;

-- HU-02, RF-02
DELIMITER //
CREATE PROCEDURE sp_mov_registrar_salida(
  IN p_id_lote INT, IN p_id_ubic_origen INT, IN p_id_ubic_dest INT,
  IN p_cantidad INT, IN p_id_usuario INT, IN p_motivo VARCHAR(255)
)
BEGIN
  CALL sp_registrar_salida(p_id_lote, p_id_ubic_origen, p_id_ubic_dest, p_cantidad, p_id_usuario, p_motivo);
END//
DELIMITER;

-- HU-04, RF-05
DELIMITER //
CREATE PROCEDURE sp_transferir_stock(
  IN p_id_lote INT, IN p_id_ubicacion_origen INT, IN p_id_ubicacion_destino INT,
  IN p_cantidad INT, IN p_id_usuario INT, IN p_motivo VARCHAR(255)
)
BEGIN
  DECLARE v_saldo INT;
  IF p_cantidad <= 0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cantidad debe ser > 0'; END IF;
  IF p_id_ubicacion_origen = p_id_ubicacion_destino THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Origen y Destino no pueden ser iguales';
  END IF;

  START TRANSACTION;
  SELECT saldo INTO v_saldo
  FROM existencias
  WHERE id_lote = p_id_lote AND id_ubicacion = p_id_ubicacion_origen
  FOR UPDATE;

  IF v_saldo IS NULL OR v_saldo < p_cantidad THEN
    ROLLBACK;
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stock insuficiente para TRANSFERENCIA';
  END IF;

  INSERT INTO movimientos
    (id_lote, id_usuario, tipo, cantidad, id_ubicacion_origen, id_ubicacion_destino, motivo)
  VALUES
    (p_id_lote, p_id_usuario, 'TRANSFERENCIA', p_cantidad, p_id_ubicacion_origen, p_id_ubicacion_destino, COALESCE(p_motivo,'Reabastecimiento'));
  COMMIT;
  END //
  DELIMITER;
  
-- HU-04, RF-05
DELIMITER //
CREATE PROCEDURE sp_mov_transferir_stock(
  IN p_id_lote INT, IN p_id_ubic_origen INT, IN p_id_ubic_dest INT,
  IN p_cantidad INT, IN p_id_usuario INT, IN p_motivo VARCHAR(255)
)
BEGIN
  CALL sp_transferir_stock(p_id_lote, p_id_ubic_origen, p_id_ubic_dest, p_cantidad, p_id_usuario, p_motivo);
END//
DELIMITER;

-- HU-08, RF-08
DELIMITER //
CREATE PROCEDURE sp_ajustar_stock(
  IN p_id_lote INT,
  IN p_id_ubicacion INT,
  IN p_cantidad INT,
  IN p_sentido VARCHAR(12), -- 'AUMENTO' | 'DISMINUCION'
  IN p_id_usuario INT,
  IN p_motivo VARCHAR(255)
)
BEGIN
  DECLARE v_saldo INT;
  DECLARE v_sentido VARCHAR(12);

  SET v_sentido = UPPER(TRIM(p_sentido));

  IF p_cantidad <= 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cantidad debe ser > 0';
  END IF;

  IF p_motivo IS NULL OR TRIM(p_motivo) = '' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Motivo es obligatorio en AJUSTE';
  END IF;

  IF v_sentido NOT IN ('AUMENTO','DISMINUCION') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'p_sentido debe ser AUMENTO o DISMINUCION';
  END IF;

  START TRANSACTION;

  IF v_sentido = 'DISMINUCION' THEN
    -- Validación de saldo en la ubicación indicada
    SELECT saldo INTO v_saldo
    FROM existencias
    WHERE id_lote = p_id_lote
      AND id_ubicacion = p_id_ubicacion
    FOR UPDATE;

    IF v_saldo IS NULL OR v_saldo < p_cantidad THEN
      ROLLBACK;
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stock insuficiente para AJUSTE (DISMINUCION)';
    END IF;

    -- Disminución: afecta ORIGEN
    INSERT INTO movimientos (id_lote, id_usuario, tipo, cantidad, id_ubicacion_origen, motivo)
    VALUES (p_id_lote, p_id_usuario, 'AJUSTE', p_cantidad, p_id_ubicacion, p_motivo);
  ELSE
    -- Aumento: afecta DESTINO
    INSERT INTO movimientos (id_lote, id_usuario, tipo, cantidad, id_ubicacion_destino, motivo)
    VALUES (p_id_lote, p_id_usuario, 'AJUSTE', p_cantidad, p_id_ubicacion, p_motivo);
  END IF;

  COMMIT;
END//
DELIMITER ;

-- HU-08, RF-08
DELIMITER //
CREATE PROCEDURE sp_mov_ajustar_stock(
  IN p_id_lote INT, IN p_id_ubic INT, IN p_cantidad INT,
  IN p_sentido VARCHAR(12), IN p_id_usuario INT, IN p_motivo VARCHAR(255)
)
BEGIN
  CALL sp_ajustar_stock(p_id_lote, p_id_ubic, p_cantidad, p_sentido, p_id_usuario, p_motivo);
END//

CREATE PROCEDURE sp_mov_anular(
  IN p_id_movimiento BIGINT, IN p_id_usuario INT, IN p_motivo VARCHAR(255)
)
BEGIN
  CALL sp_anular_movimiento(p_id_movimiento, p_id_usuario, p_motivo);
END//
DELIMITER ;

-- Importación inicial
-- RF-09
DELIMITER //
CREATE PROCEDURE sp_importar_inventario_inicial()
BEGIN
  DECLARE done INT DEFAULT 0;
  DECLARE v_codigo_item VARCHAR(50);
  DECLARE v_nit_proveedor VARCHAR(50);
  DECLARE v_codigo_lote VARCHAR(50);
  DECLARE v_fecha_venc DATE;
  DECLARE v_costo DECIMAL(10,2);
  DECLARE v_nombre_ubicacion VARCHAR(100);
  DECLARE v_cantidad INT;
	
  DECLARE v_id_item INT;
  DECLARE v_id_proveedor INT;
  DECLARE v_id_ubicacion INT;

  DECLARE cur CURSOR FOR
    SELECT codigo_item, nit_proveedor, codigo_lote, fecha_vencimiento, costo_unitario, nombre_ubicacion, cantidad
    FROM stg_inventario_inicial;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
  
   SET @ctx_id_usuario = 1;

  OPEN cur;
  read_loop: LOOP
    FETCH cur INTO v_codigo_item, v_nit_proveedor, v_codigo_lote, v_fecha_venc, v_costo, v_nombre_ubicacion, v_cantidad;
    IF done = 1 THEN LEAVE read_loop; END IF;

-- Dentro de sp_importar_inventario_inicial()

-- 1) Ubicación primero (crear si no existe)
SELECT id_ubicacion INTO v_id_ubicacion
FROM ubicaciones WHERE nombre = v_nombre_ubicacion LIMIT 1;

IF v_id_ubicacion IS NULL THEN
  INSERT INTO ubicaciones(nombre, tipo, activo)
  VALUES (v_nombre_ubicacion, 'ALMACEN', 1);
  SET v_id_ubicacion = LAST_INSERT_ID();
END IF;

-- 2) Proveedor (crear si no existe)
SELECT id_proveedor INTO v_id_proveedor
FROM proveedores WHERE nit = v_nit_proveedor LIMIT 1;

IF v_id_proveedor IS NULL THEN
  INSERT INTO proveedores(nombre, nit)
  VALUES (v_nit_proveedor, v_nit_proveedor);
  SET v_id_proveedor = LAST_INSERT_ID();
END IF;

-- 3) Ítem (crear si no existe, ya con v_id_ubicacion resuelto)
SELECT id_item INTO v_id_item
FROM items WHERE codigo = v_codigo_item LIMIT 1;

IF v_id_item IS NULL THEN
  INSERT INTO items(id_ubicacion, codigo, descripcion, tipo_item, unidad_medida, stock_minimo)
  VALUES (v_id_ubicacion, v_codigo_item, v_codigo_item, 'MEDICAMENTO', 'UND', 0);
  SET v_id_item = LAST_INSERT_ID();
END IF;

-- 4) Registrar ingreso (y que el trigger y sp_procesar_movimiento hagan el resto)
CALL sp_registrar_ingreso(
  v_id_item, v_id_proveedor, v_codigo_lote, v_fecha_venc, v_costo,
  v_id_ubicacion, v_cantidad, 1, 'Carga inventario inicial'
);
  END LOOP;
  CLOSE cur;
    SET @ctx_id_usuario = NULL;
END//
DELIMITER;

-- HU-11
DELIMITER //
CREATE PROCEDURE sp_listar_sesiones_activas()
BEGIN
    SELECT 
        s.id_sesion,
        s.id_usuario,
        u.nombre_completo AS usuario,
        u.rol,
        s.ip,
        s.hora_inicio,
        s.activo
    FROM sesiones_activas s
    JOIN usuarios u ON u.id_usuario = s.id_usuario
    WHERE s.activo = 1
    ORDER BY s.hora_inicio DESC;
END//
DELIMITER;

-- HU-11
DELIMITER //
CREATE PROCEDURE sp_cerrar_sesion(IN p_id_sesion BIGINT)
BEGIN
    UPDATE sesiones_activas 
    SET activo = 0, hora_cierre = NOW()
    WHERE id_sesion = p_id_sesion;
END//
DELIMITER;

-- HU-11
DELIMITER //
CREATE PROCEDURE sp_registrar_sesion(
    IN p_id_usuario INT,
    IN p_ip VARCHAR(45),
    IN p_user_agent VARCHAR(255)
)
BEGIN
    IF EXISTS (
        SELECT 1 FROM sesiones_activas 
        WHERE id_usuario = p_id_usuario AND activo = 1
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El usuario ya tiene una sesión activa';
    END IF;

    INSERT INTO sesiones_activas(id_usuario, ip, user_agent)
    VALUES (p_id_usuario, p_ip, p_user_agent);
END//
DELIMITER;

-- HU-12
DELIMITER //

DELIMITER //
CREATE PROCEDURE sp_generar_backup(
  IN p_usuario INT,
  IN p_ruta TEXT,
  IN p_nombre_archivo VARCHAR(255)
)
BEGIN
  INSERT INTO backups(nombre_archivo, ruta_archivo, generado_por, estado, mensaje)
  VALUES (p_nombre_archivo, p_ruta, p_usuario, 'EXITOSO', 'Respaldo programado. Ejecutar comando externamente.');

  INSERT INTO notificaciones(tipo, payload, destinatario, estado)
  VALUES (
    'BACKUP',
    JSON_OBJECT('backup', p_nombre_archivo, 'ruta', p_ruta, 'estado', 'EXITOSO'),
    (SELECT correo FROM usuarios WHERE id_usuario = p_usuario),
    'PENDIENTE'
  );
END//
DELIMITER ;


-- HU-13

DELIMITER //
CREATE PROCEDURE sp_generar_token_recuperacion(
  IN p_id_usuario INT,
  IN p_token VARCHAR(255)
)
BEGIN
  -- Puedes ajustar aquí el TTL si lo deseas (minutos)
  DECLARE v_exp DATETIME DEFAULT DATE_ADD(NOW(), INTERVAL 15 MINUTE);

  START TRANSACTION;

    -- Invalida cualquier token vigente (no usado y no expirado)
    UPDATE tokens_recuperacion
       SET usado = 1
     WHERE id_usuario = p_id_usuario
       AND usado = 0
       AND expiracion > NOW();

    -- Inserta el nuevo token (el trigger trg_tokens_bi_defaults completará defaults si hace falta)
    INSERT INTO tokens_recuperacion(id_usuario, token, expiracion)
    VALUES (p_id_usuario, p_token, v_exp);

  COMMIT;
END//
DELIMITER ;


-- HU-13
DELIMITER //
CREATE PROCEDURE sp_validar_token_recuperacion(IN p_token VARCHAR(255))
BEGIN
  DECLARE v_exp DATETIME; DECLARE v_usado TINYINT;
  SELECT expiracion, usado INTO v_exp, v_usado
  FROM tokens_recuperacion WHERE token = p_token;
  IF v_usado = 1 OR v_exp < NOW() THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Token inválido o expirado';
  END IF;
END//
DELIMITER ;


-- HU-16
DELIMITER //
CREATE PROCEDURE sp_reporte_consumo_servicio(
    IN p_id_item INT,
    IN p_fecha_inicio DATETIME,
    IN p_fecha_fin DATETIME
)
BEGIN
    SELECT mv.id_ubicacion_destino AS id_servicio,
           u.nombre AS servicio,
           SUM(mv.cantidad) AS consumo_total
    FROM movimientos mv
    JOIN lotes l ON l.id_lote = mv.id_lote
    JOIN items i ON i.id_item = l.id_item
    JOIN ubicaciones u ON u.id_ubicacion = mv.id_ubicacion_destino
    WHERE mv.tipo = 'SALIDA'
      AND mv.id_ubicacion_destino IS NOT NULL
      AND mv.fecha BETWEEN p_fecha_inicio AND p_fecha_fin
      AND (p_id_item IS NULL OR i.id_item = p_id_item)
    GROUP BY mv.id_ubicacion_destino, u.nombre;
END//
DELIMITER;

-- HU-17


DELIMITER //
CREATE PROCEDURE sp_validar_ip(IN p_ip VARCHAR(45), IN p_id_usuario INT)
BEGIN
  -- Acepta IPv4 o IPv6 válidas
  IF (INET_ATON(p_ip) IS NULL) AND (INET6_ATON(p_ip) IS NULL) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Formato de IP inválido';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM ips_permitidas WHERE ip = p_ip) THEN
    -- Auditoría encadenada: acceso denegado por IP
    CALL sp_auditar_encadenado(
      'ips_permitidas',
      p_ip,
      'DENEGADO',
      NULL,
      JSON_OBJECT('ip', p_ip),
      p_id_usuario,
      NOW()
    );
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Acceso denegado: IP no autorizada';
  END IF;
END//
DELIMITER ;



DELIMITER //
CREATE PROCEDURE sp_crear_ip(IN p_ip VARCHAR(45), IN p_descripcion VARCHAR(255), IN p_id_usuario INT)
BEGIN
  INSERT INTO ips_permitidas(ip, descripcion)
  VALUES (p_ip, p_descripcion);

  -- Auditoría encadenada
  CALL sp_auditar_encadenado(
    'ips_permitidas',
    p_ip,
    'INSERT',
    NULL,
    JSON_OBJECT('ip', p_ip, 'descripcion', p_descripcion),
    p_id_usuario,
    NOW()
  );
END//
DELIMITER ;


-- HU-17
DELIMITER //
CREATE PROCEDURE sp_listar_ips()
BEGIN
    SELECT id_ip, ip, descripcion, fecha_registro
    FROM ips_permitidas
    ORDER BY fecha_registro DESC;
END//
DELIMITER;

-- HU-17

DELIMITER //
CREATE PROCEDURE sp_eliminar_ip(IN p_id_ip INT, IN p_id_usuario INT)
BEGIN
  DECLARE v_ip VARCHAR(45);

  SELECT ip INTO v_ip FROM ips_permitidas WHERE id_ip = p_id_ip;

  DELETE FROM ips_permitidas WHERE id_ip = p_id_ip;

  -- Auditoría encadenada
  CALL sp_auditar_encadenado(
    'ips_permitidas',
    v_ip,
    'DELETE',
    JSON_OBJECT('ip', v_ip),
    NULL,
    p_id_usuario,
    NOW()
  );
END//
DELIMITER ;

-- HU-20
DELIMITER //
CREATE PROCEDURE sp_registrar_devolucion(
    IN p_id_lote INT,
    IN p_id_ubicacion INT,
    IN p_cantidad INT,
    IN p_id_usuario INT,
    IN p_motivo VARCHAR(255)
)
BEGIN
    IF p_cantidad <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cantidad debe ser > 0';
    END IF;

    IF p_motivo IS NULL OR TRIM(p_motivo) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Motivo obligatorio';
    END IF;

    INSERT INTO movimientos(id_lote, id_usuario, tipo, cantidad, id_ubicacion_destino, motivo)
    VALUES (p_id_lote, p_id_usuario, 'AJUSTE', p_cantidad, p_id_ubicacion, CONCAT('Devolución: ', p_motivo));
END//
DELIMITER;

-- HU-21
DELIMITER //
CREATE PROCEDURE sp_registrar_etiqueta_qr(
    IN p_id_lote INT,
    IN p_contenido_qr TEXT
)
BEGIN
    DECLARE v_codigo_lote VARCHAR(50);

    SELECT codigo_lote INTO v_codigo_lote FROM lotes WHERE id_lote = p_id_lote;

    IF v_codigo_lote IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lote no existe';
    END IF;

    IF LOCATE(v_codigo_lote, p_contenido_qr) = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Contenido QR inválido: no contiene código de lote';
    END IF;

    INSERT INTO etiquetas_qr(id_lote, contenido_qr)
    VALUES (p_id_lote, p_contenido_qr);
END//
DELIMITER ;

-- HU-21
DELIMITER //
CREATE PROCEDURE sp_listar_etiquetas_qr(IN p_id_lote INT)
BEGIN
    SELECT * FROM etiquetas_qr
    WHERE id_lote = p_id_lote
    ORDER BY fecha_generacion DESC;
END//
DELIMITER ;

-- HU-23

DELIMITER //
CREATE PROCEDURE sp_registrar_control_calidad(
  IN p_id_lote INT,
  IN p_observaciones TEXT,
  IN p_resultado ENUM('APROBADO','RECHAZADO'),
  IN p_evidencia TEXT,
  IN p_id_usuario INT
)
BEGIN
  DECLARE v_codigo_lote VARCHAR(50);
  SELECT codigo_lote INTO v_codigo_lote FROM lotes WHERE id_lote = p_id_lote;

  IF v_codigo_lote IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lote no existe';
  END IF;

  IF p_resultado NOT IN ('APROBADO','RECHAZADO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Resultado inválido';
  END IF;

  INSERT INTO control_calidad(id_lote, observaciones, resultado, evidencia, registrado_por)
  VALUES (p_id_lote, p_observaciones, p_resultado, p_evidencia, p_id_usuario);

  -- Auditoría encadenada (se mantiene el mismo PK lógico que ya usabas)
  CALL sp_auditar_encadenado(
    'control_calidad',
    CONCAT('lote_', p_id_lote),
    'INSERT',
    NULL,
    JSON_OBJECT('resultado', p_resultado, 'observaciones', p_observaciones),
    p_id_usuario,
    NOW()
  );
END//
DELIMITER ;

-- HU-23
DELIMITER //
CREATE PROCEDURE sp_listar_control_calidad(IN p_id_lote INT)
BEGIN
    SELECT cc.*, u.nombre_completo AS auditor
    FROM control_calidad cc
    LEFT JOIN usuarios u ON u.id_usuario = cc.registrado_por
    WHERE cc.id_lote = p_id_lote
    ORDER BY cc.fecha_control DESC;
END//
DELIMITER ;

-- HU-23
DELIMITER //
CREATE PROCEDURE sp_eliminar_control_calidad(IN p_id_control INT, IN p_id_usuario INT)
BEGIN
  DECLARE v_id_lote INT;

  SELECT id_lote INTO v_id_lote FROM control_calidad WHERE id_control = p_id_control;

  DELETE FROM control_calidad WHERE id_control = p_id_control;

  -- Auditoría encadenada
  CALL sp_auditar_encadenado(
    'control_calidad',
    CONCAT('control_', p_id_control),
    'DELETE',
    JSON_OBJECT('id_control', p_id_control, 'id_lote', v_id_lote),
    NULL,
    p_id_usuario,
    NOW()
  );
END//
DELIMITER ;


-- HU-24
DELIMITER //
CREATE PROCEDURE sp_listar_proveedores_estado(
    IN p_estado TINYINT,
    IN p_fecha_inicio DATE,
    IN p_fecha_fin DATE
)
BEGIN
    SELECT 
        id_proveedor,
        nombre,
        nit,
        CASE activo WHEN 1 THEN 'ACTIVO' ELSE 'INACTIVO' END AS estado,
        DATE(fecha_creacion) AS fecha_registro
    FROM proveedores
    WHERE activo = p_estado
      AND fecha_creacion BETWEEN p_fecha_inicio AND p_fecha_fin
    ORDER BY fecha_creacion DESC;
END;//
DELIMITER ;

-- HU-24

DELIMITER //
CREATE PROCEDURE sp_actualizar_estado_proveedor(
  IN p_id INT,
  IN p_activo TINYINT,
  IN p_id_usuario INT
)
BEGIN
  DECLARE v_nombre VARCHAR(150);
  DECLARE v_nit    VARCHAR(50);

  SELECT nombre, nit INTO v_nombre, v_nit FROM proveedores WHERE id_proveedor = p_id;

  UPDATE proveedores SET activo = p_activo WHERE id_proveedor = p_id;

  -- Auditoría encadenada (se respeta el PK lógico previo: 'prov_<id>')
  CALL sp_auditar_encadenado(
    'proveedores',
    CONCAT('prov_', p_id),
    'UPDATE',
    JSON_OBJECT('nombre', v_nombre, 'nit', v_nit),
    JSON_OBJECT('activo', p_activo),
    p_id_usuario,
    NOW()
  );
END//
DELIMITER ;



-- HU-25
DELIMITER //
CREATE PROCEDURE sp_listar_historial_notificaciones(
    IN p_usuario VARCHAR(150),
    IN p_rol VARCHAR(20),
    IN p_fecha_inicio DATE,
    IN p_fecha_fin DATE
)
BEGIN
    SELECT 
        n.id_notificacion,
        n.tipo,
        n.payload,
        n.destinatario,
        n.estado,
        n.fecha_creacion,
        n.fecha_envio,
        n.confirmado_por,
        u.nombre_completo AS usuario_confirmador,
        n.fecha_confirmacion,
        n.estado_confirmacion
    FROM notificaciones n
    LEFT JOIN usuarios u ON u.id_usuario = n.confirmado_por
    WHERE (p_usuario IS NULL OR n.destinatario LIKE CONCAT('%', p_usuario, '%'))
      AND (p_rol IS NULL OR u.rol = p_rol)
      AND n.fecha_creacion BETWEEN p_fecha_inicio AND p_fecha_fin
    ORDER BY n.fecha_creacion DESC;
END;//
DELIMITER ;

-- HU-26

DELIMITER //
CREATE PROCEDURE sp_registrar_incidente(
  IN p_descripcion TEXT,
  IN p_responsable VARCHAR(150),
  IN p_accion_correctiva TEXT,
  IN p_evidencia TEXT,
  IN p_id_usuario INT
)
BEGIN
  IF p_descripcion IS NULL OR TRIM(p_descripcion) = '' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Descripción obligatoria';
  END IF;
  IF p_responsable IS NULL OR TRIM(p_responsable) = '' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Responsable obligatorio';
  END IF;

  INSERT INTO incidentes_almacenamiento(descripcion, responsable, accion_correctiva, evidencia, registrado_por)
  VALUES (p_descripcion, p_responsable, p_accion_correctiva, p_evidencia, p_id_usuario);

  -- Auditoría encadenada (PK lógico previo: 'desc_<20car>')
  CALL sp_auditar_encadenado(
    'incidentes_almacenamiento',
    CONCAT('desc_', LEFT(p_descripcion, 20)),
    'INSERT',
    NULL,
    JSON_OBJECT('responsable', p_responsable, 'accion', p_accion_correctiva),
    p_id_usuario,
    NOW()
  );
END//
DELIMITER ;


-- HU-26
DELIMITER //
CREATE PROCEDURE sp_listar_incidentes()
BEGIN
    SELECT ia.*, u.nombre_completo AS registrado_por_nombre
    FROM incidentes_almacenamiento ia
    LEFT JOIN usuarios u ON u.id_usuario = ia.registrado_por
    ORDER BY ia.fecha DESC;
END;//
DELIMITER ;

-- HU-26

DELIMITER //
CREATE PROCEDURE sp_eliminar_incidente(IN p_id_incidente INT, IN p_id_usuario INT)
BEGIN
  DECLARE v_desc TEXT;

  SELECT descripcion INTO v_desc FROM incidentes_almacenamiento WHERE id_incidente = p_id_incidente;

  DELETE FROM incidentes_almacenamiento WHERE id_incidente = p_id_incidente;

  -- Auditoría encadenada (PK lógico previo: 'inc_<id>')
  CALL sp_auditar_encadenado(
    'incidentes_almacenamiento',
    CONCAT('inc_', p_id_incidente),
    'DELETE',
    JSON_OBJECT('descripcion', v_desc),
    NULL,
    p_id_usuario,
    NOW()
  );
END//
DELIMITER ;


-- HU-27

DELIMITER //
CREATE PROCEDURE sp_desactivar_usuarios_inactivos(IN p_id_admin INT)
BEGIN
  DECLARE done INT DEFAULT 0;
  DECLARE v_id_usuario INT;
  DECLARE v_nombre     VARCHAR(150);

  DECLARE cur CURSOR FOR
    SELECT id_usuario, nombre_completo
    FROM usuarios
    WHERE fecha_ultimo_login IS NULL
       OR fecha_ultimo_login < DATE_SUB(CURRENT_DATE(), INTERVAL 60 DAY);

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

  OPEN cur;
  read_loop: LOOP
    FETCH cur INTO v_id_usuario, v_nombre;
    IF done THEN LEAVE read_loop; END IF;

    UPDATE usuarios
       SET bloqueado_hasta = DATE_ADD(NOW(), INTERVAL 365 DAY)
     WHERE id_usuario = v_id_usuario;

    -- Auditoría encadenada (PK lógico previo: 'usr_<id>')
    CALL sp_auditar_encadenado(
      'usuarios',
      CONCAT('usr_', v_id_usuario),
      'UPDATE',
      JSON_OBJECT('nombre', v_nombre),
      JSON_OBJECT('bloqueado_hasta', DATE_ADD(NOW(), INTERVAL 365 DAY)),
      p_id_admin,
      NOW()
    );
  END LOOP;
  CLOSE cur;
END//
DELIMITER ;

-- HU-29
DELIMITER //
CREATE PROCEDURE sp_asignar_ubicacion_lote(
  IN p_id_lote INT,
  IN p_id_ubicacion INT,     -- debe ser de tipo 'ALMACEN' (trigger lo valida)
  IN p_estante VARCHAR(20),
  IN p_nivel   VARCHAR(20),
  IN p_pasillo VARCHAR(20),
  IN p_id_usuario INT        -- para auditoría en triggers (@ctx_id_usuario)
)
BEGIN
  DECLARE v_existe INT DEFAULT 0;
  DECLARE v_id_pos BIGINT;
  /* Handler para clave duplicada (UX físicas o (lote,ubicación)) */
  DECLARE EXIT HANDLER FOR 1062
  BEGIN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'La posición física ya está ocupada en ese almacén o el lote ya tiene posición en ese almacén';
  END;
  /* Validaciones básicas de existencia (FKs las refuerzan) */
  IF NOT EXISTS (SELECT 1 FROM lotes WHERE id_lote = p_id_lote) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lote no existe';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM ubicaciones WHERE id_ubicacion = p_id_ubicacion) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ubicación no existe';
  END IF;
  /* Contexto de auditoría para triggers */
  SET @ctx_id_usuario = p_id_usuario;
  /* ¿Ya hay registro para (lote, almacén)? */
  SELECT COUNT(*)
    INTO v_existe
  FROM lotes_posiciones
  WHERE id_lote = p_id_lote
    AND id_ubicacion = p_id_ubicacion;

  IF v_existe > 0 THEN
    /* UPDATE de la tripleta física */
    UPDATE lotes_posiciones
       SET estante = p_estante,
           nivel   = p_nivel,
           pasillo = p_pasillo
     WHERE id_lote = p_id_lote
       AND id_ubicacion = p_id_ubicacion;
       
    SELECT id_posicion
      INTO v_id_pos
    FROM lotes_posiciones
    WHERE id_lote = p_id_lote
      AND id_ubicacion = p_id_ubicacion;

    SELECT v_id_pos AS id_posicion, 'UPDATED' AS accion;
  ELSE
    /* INSERT (los triggers validan ALMACEN y completitud) */
    INSERT INTO lotes_posiciones
      (id_lote, id_ubicacion, estante, nivel, pasillo, asignado_por)
    VALUES
      (p_id_lote, p_id_ubicacion, p_estante, p_nivel, p_pasillo, p_id_usuario);

    SELECT LAST_INSERT_ID() AS id_posicion, 'INSERTED' AS accion;
  END IF;
END//
DELIMITER ;

-- HU-29
DELIMITER //
CREATE PROCEDURE sp_listar_ubicacion_lote(
  IN p_id_lote INT
)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM lotes WHERE id_lote = p_id_lote) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lote no existe';
  END IF;

  SELECT
    lp.id_posicion,
    lp.id_lote,
    lp.id_ubicacion,
    u.nombre           AS almacen,
    lp.estante,
    lp.nivel,
    lp.pasillo,
    lp.fecha_asignacion,
    lp.asignado_por
  FROM lotes_posiciones lp
  JOIN ubicaciones u ON u.id_ubicacion = lp.id_ubicacion
  WHERE lp.id_lote = p_id_lote
  ORDER BY u.nombre, lp.estante, lp.nivel, lp.pasillo;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_anular_movimiento(IN p_id_movimiento BIGINT, IN p_id_usuario INT, IN p_motivo VARCHAR(255))
BEGIN
  
  DECLARE v_tipo VARCHAR(20); DECLARE v_id_lote INT; DECLARE v_ori INT; DECLARE v_des INT; DECLARE v_cant INT;
  
  IF EXISTS (
    SELECT 1 FROM movimientos 
    WHERE motivo LIKE CONCAT('Anulación mov ', p_id_movimiento, '%')) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Movimiento ya fue anulado previamente';
END IF;

  IF p_motivo IS NULL OR TRIM(p_motivo) = '' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Motivo obligatorio para anulación';
  END IF;

  SELECT tipo, id_lote, id_ubicacion_origen, id_ubicacion_destino, cantidad
    INTO v_tipo, v_id_lote, v_ori, v_des, v_cant
  FROM movimientos
  WHERE id_movimiento = p_id_movimiento
    AND motivo NOT LIKE 'Anulación mov %'
  LIMIT 1;

  IF v_tipo IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Movimiento no existe o ya es anulación';
  END IF;

  START TRANSACTION;
  CASE v_tipo
    WHEN 'INGRESO' THEN
      INSERT INTO movimientos(id_lote, id_usuario, tipo, cantidad, id_ubicacion_origen, motivo)
      VALUES (v_id_lote, p_id_usuario, 'AJUSTE', v_cant, v_des, CONCAT('Anulación mov ', p_id_movimiento, ': ', p_motivo));

    WHEN 'SALIDA' THEN
      INSERT INTO movimientos(id_lote, id_usuario, tipo, cantidad, id_ubicacion_destino, motivo)
      VALUES (v_id_lote, p_id_usuario, 'AJUSTE', v_cant, v_ori, CONCAT('Anulación mov ', p_id_movimiento, ': ', p_motivo));

    WHEN 'TRANSFERENCIA' THEN
      INSERT INTO movimientos(id_lote, id_usuario, tipo, cantidad, id_ubicacion_origen, id_ubicacion_destino, motivo)
      VALUES (v_id_lote, p_id_usuario, 'TRANSFERENCIA', v_cant, v_des, v_ori, CONCAT('Anulación mov ', p_id_movimiento, ': ', p_motivo));

    WHEN 'AJUSTE' THEN
      IF v_ori IS NOT NULL THEN
        INSERT INTO movimientos(id_lote, id_usuario, tipo, cantidad, id_ubicacion_destino, motivo)
        VALUES (v_id_lote, p_id_usuario, 'AJUSTE', v_cant, v_ori, CONCAT('Reversa ajuste mov ', p_id_movimiento, ': ', p_motivo));
      ELSE
        INSERT INTO movimientos(id_lote, id_usuario, tipo, cantidad, id_ubicacion_origen, motivo)
        VALUES (v_id_lote, p_id_usuario, 'AJUSTE', v_cant, v_des, CONCAT('Reversa ajuste mov ', p_id_movimiento, ': ', p_motivo));
      END IF;
  END CASE;
  COMMIT;
END//

-- Recalcular existencias SIN TRUNCATE (sin commits implícitos)
DELIMITER //
CREATE PROCEDURE sp_recalcular_existencias()
BEGIN
  /* habilitar bypass para que los triggers de existencias no bloqueen */
  SET @bypass_existencias = 1;

  START TRANSACTION;

  DELETE FROM existencias;

  INSERT INTO existencias (id_lote, id_ubicacion, saldo)
  SELECT id_lote, id_ubicacion, SUM(delta) AS saldo
  FROM (
    SELECT
      mv.id_lote,
      CASE
        WHEN mv.tipo IN ('INGRESO','TRANSFERENCIA') AND mv.id_ubicacion_destino IS NOT NULL THEN mv.id_ubicacion_destino
        WHEN mv.tipo IN ('SALIDA','TRANSFERENCIA','AJUSTE')  AND mv.id_ubicacion_origen  IS NOT NULL THEN mv.id_ubicacion_origen
        ELSE NULL
      END AS id_ubicacion,
      CASE
        WHEN mv.tipo IN ('INGRESO','TRANSFERENCIA') AND mv.id_ubicacion_destino IS NOT NULL THEN  mv.cantidad
        WHEN mv.tipo IN ('SALIDA','TRANSFERENCIA','AJUSTE')  AND mv.id_ubicacion_origen  IS NOT NULL THEN -mv.cantidad
        ELSE 0
      END AS delta
    FROM movimientos mv
  ) t
  WHERE id_ubicacion IS NOT NULL
  GROUP BY id_lote, id_ubicacion
  HAVING SUM(delta) <> 0;

  COMMIT;

  /* cerrar bypass */
  SET @bypass_existencias = NULL;
END//

-- Verificación de cadena de auditoría
CREATE PROCEDURE sp_verificar_auditoria_integridad()
BEGIN
  WITH ordered AS (
    SELECT a.*, ROW_NUMBER() OVER (ORDER BY id_evento) AS rn
    FROM auditoria a
  ),
  prevs AS (
    SELECT o1.id_evento, o1.tabla_afectada, o1.pk_afectada, o1.fecha,
           o1.hash_anterior AS esperado,
           COALESCE(o2.hash_evento, REPEAT('0',64)) AS hash_real
    FROM ordered o1
    LEFT JOIN ordered o2 ON o2.rn = o1.rn - 1
  )
  SELECT * FROM prevs
  WHERE esperado <> hash_real;
END//

-- SP: Actualizar fecha de último login
CREATE PROCEDURE sp_actualizar_ultimo_login(IN p_id_usuario INT)
BEGIN
    UPDATE usuarios SET fecha_ultimo_login = NOW() WHERE id_usuario = p_id_usuario;
END;//

-- SP: Confirmar recepción de alerta
CREATE PROCEDURE sp_confirmar_alerta(IN p_id_notificacion BIGINT, IN p_id_usuario INT)
BEGIN
    UPDATE notificaciones
    SET confirmado_por = p_id_usuario,
        fecha_confirmacion = NOW(),
        estado_confirmacion = 'REVISADA'
    WHERE id_notificacion = p_id_notificacion;
END;//

-- SP: Actualizar ubicación física de lote
DELIMITER //

CREATE PROCEDURE sp_actualizar_ubicacion_lote(
  IN p_id_posicion BIGINT,
  IN p_id_ubicacion INT,     -- debe ser 'ALMACEN' (trigger lo valida)
  IN p_estante VARCHAR(20),
  IN p_nivel   VARCHAR(20),
  IN p_pasillo VARCHAR(20),
  IN p_id_usuario INT        -- para auditoría en triggers (@ctx_id_usuario)
)
BEGIN
  /* Handler duplicidad */
  DECLARE EXIT HANDLER FOR 1062
  BEGIN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'No se puede actualizar: la nueva posición física ya está ocupada o el lote ya tiene posición en ese almacén';
  END;

  IF NOT EXISTS (SELECT 1 FROM lotes_posiciones WHERE id_posicion = p_id_posicion) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Posición no existe';
  END IF;

  /* Contexto de auditoría para triggers */
  SET @ctx_id_usuario = p_id_usuario;

  UPDATE lotes_posiciones
     SET id_ubicacion = p_id_ubicacion,
         estante      = p_estante,
         nivel        = p_nivel,
         pasillo      = p_pasillo
   WHERE id_posicion  = p_id_posicion;

  /* Devuelvo el registro actualizado */
  SELECT
    lp.id_posicion,
    lp.id_lote,
    lp.id_ubicacion,
    u.nombre AS almacen,
    lp.estante,
    lp.nivel,
    lp.pasillo,
    lp.fecha_asignacion,
    lp.asignado_por
  FROM lotes_posiciones lp
  JOIN ubicaciones u ON u.id_ubicacion = lp.id_ubicacion
  WHERE lp.id_posicion = p_id_posicion;
END//
DELIMITER ;

/* 2) MOVIMIENTOS: sp_procesar_movimiento con bypass de existencias */

DELIMITER //
CREATE PROCEDURE sp_procesar_movimiento(IN p_id_movimiento BIGINT)
BEGIN
  DECLARE v_saldo INT;

  SET @bypass_existencias = 1;

  -- Obtener datos del movimiento
  SELECT tipo, id_lote, id_usuario, cantidad, id_ubicacion_origen, id_ubicacion_destino, motivo
  INTO @tipo, @id_lote, @id_usuario, @cantidad, @ori, @des, @motivo
  FROM movimientos
  WHERE id_movimiento = p_id_movimiento;

  -- Validaciones generales
  IF @cantidad <= 0 THEN
    SET @bypass_existencias = NULL;
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cantidad debe ser > 0';
  END IF;

  -- Procesamiento según tipo
  CASE @tipo
    WHEN 'INGRESO' THEN
      IF @des IS NULL THEN
        SET @bypass_existencias = NULL;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INGRESO requiere ubicación destino';
      END IF;
      INSERT INTO existencias(id_lote, id_ubicacion, saldo)
      VALUES (@id_lote, @des, @cantidad)
      ON DUPLICATE KEY UPDATE saldo = saldo + VALUES(saldo);

    WHEN 'SALIDA' THEN
      IF @ori IS NULL THEN
        SET @bypass_existencias = NULL;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'SALIDA requiere ubicación origen';
      END IF;
      SELECT saldo INTO v_saldo
      FROM existencias
      WHERE id_lote = @id_lote AND id_ubicacion = @ori
      FOR UPDATE;
      IF v_saldo IS NULL OR v_saldo < @cantidad THEN
        SET @bypass_existencias = NULL;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stock insuficiente para SALIDA';
      END IF;
      UPDATE existencias
      SET saldo = saldo - @cantidad
      WHERE id_lote = @id_lote AND id_ubicacion = @ori;

    WHEN 'TRANSFERENCIA' THEN
      IF @ori IS NULL OR @des IS NULL THEN
        SET @bypass_existencias = NULL;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TRANSFERENCIA requiere origen y destino';
      END IF;
      IF @ori = @des THEN
        SET @bypass_existencias = NULL;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Origen y destino no pueden ser iguales';
      END IF;
      SELECT saldo INTO v_saldo
      FROM existencias
      WHERE id_lote = @id_lote AND id_ubicacion = @ori
      FOR UPDATE;
      IF v_saldo IS NULL OR v_saldo < @cantidad THEN
        SET @bypass_existencias = NULL;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stock insuficiente en origen para TRANSFERENCIA';
      END IF;
      UPDATE existencias
      SET saldo = saldo - @cantidad
      WHERE id_lote = @id_lote AND id_ubicacion = @ori;
      INSERT INTO existencias(id_lote, id_ubicacion, saldo)
      VALUES (@id_lote, @des, @cantidad)
      ON DUPLICATE KEY UPDATE saldo = saldo + VALUES(saldo);

    WHEN 'AJUSTE' THEN
      IF @motivo IS NULL OR @motivo = '' THEN
        SET @bypass_existencias = NULL;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Motivo obligatorio para AJUSTE';
      END IF;
      IF @ori IS NOT NULL AND @des IS NOT NULL THEN
        SET @bypass_existencias = NULL;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'AJUSTE debe afectar solo una ubicación';
      END IF;
      IF @des IS NOT NULL THEN
        INSERT INTO existencias(id_lote, id_ubicacion, saldo)
        VALUES (@id_lote, @des, @cantidad)
        ON DUPLICATE KEY UPDATE saldo = saldo + VALUES(saldo);
      ELSEIF @ori IS NOT NULL THEN
        SELECT saldo INTO v_saldo
        FROM existencias
        WHERE id_lote = @id_lote AND id_ubicacion = @ori
        FOR UPDATE;
        IF v_saldo IS NULL OR v_saldo < @cantidad THEN
          SET @bypass_existencias = NULL;
          SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stock insuficiente para AJUSTE (disminución)';
        END IF;
        UPDATE existencias
        SET saldo = saldo - @cantidad
        WHERE id_lote = @id_lote AND id_ubicacion = @ori;
      ELSE
        SET @bypass_existencias = NULL;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'AJUSTE requiere una ubicación (origen o destino)';
      END IF;
  END CASE;

  SET @bypass_existencias = NULL;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_login (
  IN p_correo VARCHAR(150))
BEGIN
  -- Sólo devuelve datos mínimos para la app tras autenticar externamente (bcrypt)
  SELECT id_usuario, nombre_completo, correo, rol, fecha_ultimo_login
  FROM usuarios
  WHERE correo = p_correo AND activo = 1;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_cambiar_contrasena(
    IN p_token VARCHAR(255),
    IN p_nueva_contrasena VARCHAR(255)
)
BEGIN
    DECLARE v_id_usuario INT;
    DECLARE v_exp DATETIME;
    DECLARE v_usado TINYINT;

    SELECT id_usuario, expiracion, usado INTO v_id_usuario, v_exp, v_usado
    FROM tokens_recuperacion
    WHERE token = p_token;

    IF v_id_usuario IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Token inválido';
    END IF;

    IF v_usado = 1 OR v_exp < NOW() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Token expirado o ya usado';
    END IF;

    IF p_nueva_contrasena NOT LIKE '$2%' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La contraseña debe estar cifrada con bcrypt';
    END IF;

    UPDATE usuarios SET contrasena = p_nueva_contrasena WHERE id_usuario = v_id_usuario;
    UPDATE tokens_recuperacion SET usado = 1 WHERE token = p_token;
END//

DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_generar_alertas_diarias()
BEGIN
  IF NOT EXISTS (SELECT 1 FROM parametros_sistema WHERE clave = 'dias_alerta_venc') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Parámetro dias_alerta_venc no definido';
  END IF;

  -- STOCK BAJO
  INSERT INTO notificaciones(tipo, payload, destinatario, estado, fecha_creacion)
  SELECT 'ALERTA_STOCK_BAJO',
         JSON_OBJECT('id_item', id_item, 'codigo_item', codigo_item, 'stock_minimo', stock_minimo, 'stock_total', stock_total),
         NULL, 'PENDIENTE', NOW()
  FROM v_alertas_stock_bajo;

  -- STOCK CRÍTICO (=0)
  INSERT INTO notificaciones(tipo, payload, destinatario, estado, fecha_creacion)
  SELECT 'ALERTA_STOCK_CRITICO',
         JSON_OBJECT('id_item', id_item, 'codigo_item', codigo_item, 'stock_total', stock_total),
         NULL, 'PENDIENTE', NOW()
  FROM v_alertas_stock_critico;

  -- VENCIMIENTOS
  INSERT INTO notificaciones(tipo, payload, destinatario, estado, fecha_creacion)
  SELECT 'ALERTA_VENCIMIENTO',
         JSON_OBJECT('id_lote', id_lote, 'codigo_lote', codigo_lote, 'id_item', id_item, 'codigo_item', codigo_item, 'dias_restantes', dias_restantes),
         NULL, 'PENDIENTE', NOW()
  FROM v_alertas_vencimiento;
END//



-- SP central para registrar eventos encadenados por tabla_afectada
DELIMITER //
CREATE PROCEDURE sp_auditar_encadenado(
  IN p_tabla            VARCHAR(100),
  IN p_pk               VARCHAR(100),
  IN p_accion           ENUM('INSERT','UPDATE','DELETE','DENEGADO'),
  IN p_valores_antes    JSON,
  IN p_valores_despues  JSON,
  IN p_id_usuario       INT,
  IN p_fecha_evento     DATETIME
)
BEGIN
  DECLARE v_hash_prev CHAR(64);
  DECLARE v_id_nuevo BIGINT;

  -- 1) Asegurar fila de puntero (idempotente)
  INSERT INTO auditoria_punteros(tabla_afectada, id_ultimo, hash_ultimo)
  VALUES (p_tabla, NULL, REPEAT('0',64))
  ON DUPLICATE KEY UPDATE tabla_afectada = VALUES(tabla_afectada);
    
 -- 2) Serializar por tabla_afectada
  SELECT hash_ultimo
    INTO v_hash_prev
    FROM auditoria_punteros
   WHERE tabla_afectada = p_tabla
   FOR UPDATE;

  SET v_hash_prev = COALESCE(v_hash_prev, REPEAT('0',64));

  -- 3) Calcular hash_evento (incluye hash_prev y campos clave)
  --    CONCAT forzará a string los JSON si no son NULL.
  SET @hash_evento := SHA2(
    CONCAT(
      p_tabla, '|', p_pk, '|', p_accion, '|',
      COALESCE(CAST(p_valores_despues AS CHAR), CAST(p_valores_antes AS CHAR), ''), '|',
      DATE_FORMAT(p_fecha_evento, '%Y-%m-%d %H:%i:%s'), '|',
      v_hash_prev
    ),
  256);

  -- 4) Insertar evento en auditoria
    SET @__aud_via_sp = 1;
  INSERT INTO auditoria(
    tabla_afectada, pk_afectada, accion,
    valores_antes, valores_despues,
    id_usuario, fecha,
    hash_anterior, hash_evento
  ) VALUES (
    p_tabla, p_pk, p_accion,
    p_valores_antes, p_valores_despues,
    p_id_usuario, p_fecha_evento,
    v_hash_prev, @hash_evento
  );
  SET @__aud_via_sp = NULL;

  SET v_id_nuevo = LAST_INSERT_ID();

  -- 5) Actualizar puntero
  UPDATE auditoria_punteros
     SET id_ultimo = v_id_nuevo,
         hash_ultimo = @hash_evento
   WHERE tabla_afectada = p_tabla;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_verificar_auditoria_integridad_v2()
BEGIN
  /* Compara hash_anterior vs LAG(hash_evento) particionado por tabla */
  SELECT *
  FROM (
    SELECT
      a.tabla_afectada,
      a.id_evento,
      a.fecha,
      a.hash_anterior AS esperado,
      COALESCE(
        LAG(a.hash_evento) OVER (PARTITION BY a.tabla_afectada ORDER BY a.id_evento),
        REPEAT('0',64)
      ) AS hash_real
    FROM auditoria a
  ) t
  WHERE t.esperado <> t.hash_real;
END//
DELIMITER ;


/* ===========================================================
		     TRIGGERS (HU) (LOGICA DE NEGOCIO)
   =========================================================== */
   
-- HU-01, HU-10	
 DELIMITER //  
CREATE TRIGGER trg_comprobante_ingreso_ai
AFTER INSERT ON movimientos FOR EACH ROW
BEGIN
  IF NEW.tipo = 'INGRESO' THEN
    INSERT INTO comprobantes_recepcion (id_movimiento, id_proveedor)
    SELECT NEW.id_movimiento, l.id_proveedor
    FROM lotes l WHERE l.id_lote = NEW.id_lote;
  END IF;
END//
DELIMITER ;

-- HU-02, HU-04, RF-08
DELIMITER //
CREATE TRIGGER trg_mov_ai
AFTER INSERT ON movimientos
FOR EACH ROW
BEGIN
  -- Auditoría encadenada por 'movimientos'
  CALL sp_auditar_encadenado(
    'movimientos',
    CAST(NEW.id_movimiento AS CHAR),
    'INSERT',
    NULL,
    JSON_OBJECT(
      'id_mov', NEW.id_movimiento,
      'id_lote', NEW.id_lote,
      'tipo', NEW.tipo,
      'cant', NEW.cantidad,
      'ori', NEW.id_ubicacion_origen,
      'des', NEW.id_ubicacion_destino,
      'motivo', NEW.motivo,
      'fecha', DATE_FORMAT(NEW.fecha, '%Y-%m-%d %H:%i:%s')
    ),
    NEW.id_usuario,
    NEW.fecha
  );
  -- Mantener procesamiento de existencias
  CALL sp_procesar_movimiento(NEW.id_movimiento);
END//
DELIMITER ;


-- HU-06
DELIMITER //
CREATE TRIGGER trg_items_ai
AFTER INSERT ON items
FOR EACH ROW
BEGIN
  CALL sp_auditar_encadenado(
    'items',
    CAST(NEW.id_item AS CHAR),
    'INSERT',
    NULL,
    JSON_OBJECT(
      'id_item', NEW.id_item,
      'codigo', NEW.codigo,
      'descripcion', NEW.descripcion,
      'unidad_medida', NEW.unidad_medida,
      'tipo_item', NEW.tipo_item,
      'stock_minimo', NEW.stock_minimo
    ),
    @ctx_id_usuario,
    NOW()
  );
END//
DELIMITER ;

-- HU-06
DELIMITER //
CREATE TRIGGER trg_items_au
AFTER UPDATE ON items
FOR EACH ROW
BEGIN
  CALL sp_auditar_encadenado(
    'items',
    CAST(NEW.id_item AS CHAR),
    'UPDATE',
    JSON_OBJECT(
      'id_item', OLD.id_item,
      'codigo', OLD.codigo,
      'descripcion', OLD.descripcion,
      'unidad_medida', OLD.unidad_medida,
      'tipo_item', OLD.tipo_item,
      'stock_minimo', OLD.stock_minimo
    ),
    JSON_OBJECT(
      'id_item', NEW.id_item,
      'codigo', NEW.codigo,
      'descripcion', NEW.descripcion,
      'unidad_medida', NEW.unidad_medida,
      'tipo_item', NEW.tipo_item,
      'stock_minimo', NEW.stock_minimo
    ),	
	@ctx_id_usuario,
    NOW()
  );
END//
DELIMITER ;

-- HU-06
DELIMITER //
CREATE TRIGGER trg_items_ad
AFTER DELETE ON items
FOR EACH ROW
BEGIN
  CALL sp_auditar_encadenado(
    'items',
    CAST(OLD.id_item AS CHAR),
    'DELETE',
    JSON_OBJECT(
      'id_item', OLD.id_item,
      'codigo', OLD.codigo,
      'descripcion', OLD.descripcion,
      'unidad_medida', OLD.unidad_medida,
      'tipo_item', OLD.tipo_item,
      'stock_minimo', OLD.stock_minimo
    ),
    NULL,
    @ctx_id_usuario,
    NOW()
  );
END//
DELIMITER ;

-- LOTES: validación costo > 0
DELIMITER //
CREATE TRIGGER trg_lotes_bi_validacion
BEFORE INSERT ON lotes FOR EACH ROW
BEGIN
  IF NEW.costo_unitario <= 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Costo unitario debe ser mayor a cero';
  END IF;
END//
DELIMITER ;

-- LOTES: auditoría AFTER INSERT
DELIMITER //
CREATE TRIGGER trg_lotes_ai_auditoria
AFTER INSERT ON lotes
FOR EACH ROW
BEGIN
  CALL sp_auditar_encadenado(
    'lotes',
    CAST(NEW.id_lote AS CHAR),
    'INSERT',
    NULL,
    JSON_OBJECT(
      'id_lote', NEW.id_lote,
      'id_item', NEW.id_item,
      'codigo_lote', NEW.codigo_lote,
      'vencimiento', DATE_FORMAT(NEW.fecha_vencimiento, '%Y-%m-%d'),
      'costo_u', NEW.costo_unitario
    ),
    @ctx_id_usuario,
    NOW()
  );
END//
DELIMITER ;

-- UBICACIONES: auditoría AFTER INSERT

DELIMITER //
CREATE TRIGGER trg_ubicaciones_ai
AFTER INSERT ON ubicaciones
FOR EACH ROW
BEGIN
  CALL sp_auditar_encadenado(
    'ubicaciones',
    CAST(NEW.id_ubicacion AS CHAR),
    'INSERT',
    NULL,
    JSON_OBJECT(
      'id_ubicacion', NEW.id_ubicacion,
      'nombre', NEW.nombre,
      'tipo', NEW.tipo,
      'activo', NEW.activo
    ),
    @ctx_id_usuario,
    NOW()
  );
END//
DELIMITER ;


-- MOVIMIENTOS: inmutabilidad + AFTER INSERT único (audita + procesa)
DELIMITER //
CREATE TRIGGER trg_mov_bu
BEFORE UPDATE ON movimientos FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Los movimientos no se pueden actualizar. Use sp_anular_movimiento()';
END//
DELIMITER ;

DELIMITER //
CREATE TRIGGER trg_mov_bd
BEFORE DELETE ON movimientos FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Los movimientos no se pueden eliminar. Use sp_anular_movimiento()';
END//
DELIMITER ;

-- AUDITORÍA inmutable
DELIMITER //
CREATE TRIGGER trg_auditoria_bu
BEFORE UPDATE ON auditoria FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tabla de auditoría es inmutable (UPDATE prohibido)';
END//
DELIMITER ;

DROP TRIGGER IF EXISTS trg_auditoria_bd;
DELIMITER //
CREATE TRIGGER trg_auditoria_bd
BEFORE DELETE ON auditoria FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tabla de auditoría es inmutable (DELETE prohibido)';
END//
DELIMITER ;

DELIMITER //
CREATE TRIGGER trg_auditoria_bi_guard
BEFORE INSERT ON auditoria
FOR EACH ROW
BEGIN
  IF COALESCE(@__aud_via_sp, 0) = 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Inserción directa en auditoria prohibida. Use sp_auditar_encadenado()';
  END IF;
END//
DELIMITER ;


DELIMITER //
CREATE TRIGGER trg_lotes_bu_validacion
BEFORE UPDATE ON lotes
FOR EACH ROW
BEGIN
  IF NEW.costo_unitario <= 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Costo unitario debe ser > 0';
  END IF;
  IF NEW.fecha_vencimiento < CURRENT_DATE() THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Fecha de vencimiento inválida (pasada)';
  END IF;
END//
DELIMITER ;


DELIMITER //
CREATE TRIGGER trg_lotes_au_auditoria
AFTER UPDATE ON lotes
FOR EACH ROW
BEGIN
  CALL sp_auditar_encadenado(
    'lotes',
    CAST(NEW.id_lote AS CHAR),
    'UPDATE',
    JSON_OBJECT(
      'id_lote', OLD.id_lote,
      'fecha_vencimiento', DATE_FORMAT(OLD.fecha_vencimiento, '%Y-%m-%d'),
      'costo_unitario', OLD.costo_unitario
    ),
    JSON_OBJECT(
      'id_lote', NEW.id_lote,
      'fecha_vencimiento', DATE_FORMAT(NEW.fecha_vencimiento, '%Y-%m-%d'),
      'costo_unitario', NEW.costo_unitario
    ),
    @ctx_id_usuario,
    NOW()
  );
END//
DELIMITER ;



DELIMITER //
CREATE TRIGGER trg_lotes_ad_auditoria
AFTER DELETE ON lotes
FOR EACH ROW
BEGIN
  CALL sp_auditar_encadenado(
    'lotes',
    CAST(OLD.id_lote AS CHAR),
    'DELETE',
    JSON_OBJECT(
      'id_lote', OLD.id_lote,
      'codigo_lote', OLD.codigo_lote
    ),
    NULL,
    @ctx_id_usuario,
    NOW()
  );
END//
DELIMITER ;


	

DELIMITER //
CREATE TRIGGER trg_ubicaciones_au
AFTER UPDATE ON ubicaciones
FOR EACH ROW
BEGIN
  CALL sp_auditar_encadenado(
    'ubicaciones',
    CAST(NEW.id_ubicacion AS CHAR),
    'UPDATE',
    JSON_OBJECT(
      'nombre', OLD.nombre,
      'tipo', OLD.tipo,
      'activo', OLD.activo
    ),
    JSON_OBJECT(
      'nombre', NEW.nombre,
      'tipo', NEW.tipo,
      'activo', NEW.activo
    ),
    @ctx_id_usuario,
    NOW()
  );
END//
DELIMITER ;



DELIMITER //
CREATE TRIGGER trg_ubicaciones_ad
AFTER DELETE ON ubicaciones
FOR EACH ROW
BEGIN
  CALL sp_auditar_encadenado(
    'ubicaciones',
    CAST(OLD.id_ubicacion AS CHAR),
    'DELETE',
    JSON_OBJECT(
      'nombre', OLD.nombre,
      'tipo', OLD.tipo,
      'activo', OLD.activo
    ),
    NULL,
    @ctx_id_usuario,
    NOW()
  );
END//
DELIMITER ;


-- PROVEEDORES
DELIMITER //
CREATE TRIGGER trg_proveedores_ai
AFTER INSERT ON proveedores
FOR EACH ROW
BEGIN
  CALL sp_auditar_encadenado(
    'proveedores',
    CAST(NEW.id_proveedor AS CHAR),
    'INSERT',
    NULL,
    JSON_OBJECT(
      'nombre', NEW.nombre,
      'nit', NEW.nit,
      'activo', NEW.activo,
      'fecha_creacion', DATE_FORMAT(NEW.fecha_creacion, '%Y-%m-%d %H:%i:%s')
    ),
    @ctx_id_usuario,
    NOW()
  );
END//
DELIMITER ;



DELIMITER //
CREATE TRIGGER trg_proveedores_au
AFTER UPDATE ON proveedores
FOR EACH ROW
BEGIN
  CALL sp_auditar_encadenado(
    'proveedores',
    CAST(NEW.id_proveedor AS CHAR),
    'UPDATE',
    JSON_OBJECT(
      'nombre', OLD.nombre,
      'nit', OLD.nit,
      'activo', OLD.activo
    ),
    JSON_OBJECT(
      'nombre', NEW.nombre,
      'nit', NEW.nit,
      'activo', NEW.activo
    ),
    @ctx_id_usuario,
    NOW()
  );
END//
DELIMITER ;

DELIMITER //
CREATE TRIGGER trg_proveedores_ad
AFTER DELETE ON proveedores
FOR EACH ROW
BEGIN
  CALL sp_auditar_encadenado(
    'proveedores',
    CAST(OLD.id_proveedor AS CHAR),
    'DELETE',
    JSON_OBJECT(
      'nombre', OLD.nombre,
      'nit', OLD.nit,
      'activo', OLD.activo
    ),
    NULL,
    @ctx_id_usuario,
    NOW()
  );
END//
DELIMITER ;


-- USUARIOS
DELIMITER //
CREATE TRIGGER trg_usuarios_ai
AFTER INSERT ON usuarios
FOR EACH ROW
BEGIN
  CALL sp_auditar_encadenado(
    'usuarios',
    CAST(NEW.id_usuario AS CHAR),
    'INSERT',
    NULL,
    JSON_OBJECT(
      'nombre', NEW.nombre_completo,
      'correo', NEW.correo,
      'rol', NEW.rol
    ),
    @ctx_id_usuario,
    NOW()
  );
END//
DELIMITER ;



DELIMITER //
CREATE TRIGGER trg_usuarios_au
AFTER UPDATE ON usuarios
FOR EACH ROW
BEGIN
  CALL sp_auditar_encadenado(
    'usuarios',
    CAST(NEW.id_usuario AS CHAR),
    'UPDATE',
    JSON_OBJECT(
      'nombre', OLD.nombre_completo,
      'correo', OLD.correo,
      'rol', OLD.rol,
      'bloqueado_hasta', IFNULL(DATE_FORMAT(OLD.bloqueado_hasta, '%Y-%m-%d %H:%i:%s'),'NULL'),
      'fecha_ultimo_login', IFNULL(DATE_FORMAT(OLD.fecha_ultimo_login, '%Y-%m-%d %H:%i:%s'),'NULL')
    ),
    JSON_OBJECT(
      'nombre', NEW.nombre_completo,
      'correo', NEW.correo,
      'rol', NEW.rol,
      'bloqueado_hasta', IFNULL(DATE_FORMAT(NEW.bloqueado_hasta, '%Y-%m-%d %H:%i:%s'),'NULL'),
      'fecha_ultimo_login', IFNULL(DATE_FORMAT(NEW.fecha_ultimo_login, '%Y-%m-%d %H:%i:%s'),'NULL')
    ),
	@ctx_id_usuario,
    NOW()
  );
END//
DELIMITER ;

DELIMITER //
CREATE TRIGGER trg_usuarios_ad
AFTER DELETE ON usuarios
FOR EACH ROW
BEGIN
  CALL sp_auditar_encadenado(
    'usuarios',
    CAST(OLD.id_usuario AS CHAR),
    'DELETE',
    JSON_OBJECT(
      'nombre', OLD.nombre_completo,
      'correo', OLD.correo,
      'rol', OLD.rol
    ),
    NULL,
    @ctx_id_usuario,
    NOW()
  );
END//
DELIMITER ;


-- NOTIFICACIONES: confirmar → setear fecha y bloquear “reversas”
DELIMITER //
CREATE TRIGGER trg_notif_bu_confirmacion
BEFORE UPDATE ON notificaciones
FOR EACH ROW
BEGIN
  -- Si pasa a REVISADA y antes no lo estaba → poner fecha_confirmacion
  IF NEW.estado_confirmacion = 'REVISADA' AND OLD.estado_confirmacion <> 'REVISADA' THEN
    SET NEW.fecha_confirmacion = NOW();
    IF NEW.confirmado_por IS NULL THEN
      -- Si app no llenó confirmado_por, usar @ctx_id_usuario
      SET NEW.confirmado_por = COALESCE(@ctx_id_usuario, NEW.confirmado_por);
    END IF;
  END IF;

  -- No permitir volver de REVISADA a PENDIENTE
  IF OLD.estado_confirmacion = 'REVISADA' AND NEW.estado_confirmacion <> 'REVISADA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Una notificación ya REVISADA no puede revertirse';
  END IF;
END//
DELIMITER ;

-- SESIONES: antes de crear, verificar que no haya otra activa
DELIMITER //
CREATE TRIGGER trg_sesiones_bi_unica
BEFORE INSERT ON sesiones_activas
FOR EACH ROW
BEGIN
  IF EXISTS (SELECT 1 FROM sesiones_activas WHERE id_usuario = NEW.id_usuario AND activo = 1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El usuario ya tiene una sesión activa';
  END IF;
END//
DELIMITER ;

-- SESIONES: en UPDATE, si se marca activa=1, asegurar unicidad; si se cierra, poner hora_cierre
DELIMITER //
CREATE TRIGGER trg_sesiones_bu_control
BEFORE UPDATE ON sesiones_activas
FOR EACH ROW
BEGIN
  IF NEW.activo = 1 AND OLD.activo <> 1 THEN
    IF EXISTS (SELECT 1 FROM sesiones_activas WHERE id_usuario = NEW.id_usuario AND activo = 1 AND id_sesion <> OLD.id_sesion) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya existe otra sesión activa para este usuario';
    END IF;
  END IF;
  IF NEW.activo = 0 AND OLD.activo = 1 AND NEW.hora_cierre IS NULL THEN
    SET NEW.hora_cierre = NOW();
  END IF;
END//
DELIMITER ;

-- EXISTENCIAS: prohibir INSERT/UPDATE/DELETE manuales
DELIMITER //
CREATE TRIGGER trg_existencias_bi_guard
BEFORE INSERT ON existencias
FOR EACH ROW
BEGIN
  IF COALESCE(@bypass_existencias,0) = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Existencias sólo se actualizan desde movimientos';
  END IF;
END//
DELIMITER ;

DELIMITER //
CREATE TRIGGER trg_existencias_bu_guard
BEFORE UPDATE ON existencias
FOR EACH ROW
BEGIN
  IF COALESCE(@bypass_existencias,0) = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Existencias sólo se actualizan desde movimientos';
  END IF;
END//
DELIMITER ;

DELIMITER //
CREATE TRIGGER trg_existencias_bd_guard
BEFORE DELETE ON existencias
FOR EACH ROW
BEGIN
  IF COALESCE(@bypass_existencias,0) = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Existencias sólo se actualizan desde movimientos';
  END IF;
END//
DELIMITER ;

-- LOTES_POSICIONES: sólo ubicaciones tipo ALMACEN + tripleta completa o nula
DELIMITER //
CREATE TRIGGER trg_lpos_bi_validacion
BEFORE INSERT ON lotes_posiciones
FOR EACH ROW
BEGIN
  DECLARE v_tipo VARCHAR(10);

  SELECT tipo INTO v_tipo
  FROM ubicaciones
  WHERE id_ubicacion = NEW.id_ubicacion;

  IF v_tipo IS NULL OR v_tipo <> 'ALMACEN' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'id_ubicacion debe ser de tipo ALMACEN';
  END IF;

  IF NOT (
       (NEW.estante IS NULL AND NEW.nivel IS NULL AND NEW.pasillo IS NULL)
       OR
       (NEW.estante IS NOT NULL AND NEW.nivel IS NOT NULL AND NEW.pasillo IS NOT NULL)
     ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'estante/nivel/pasillo: o todo NULL o todo informado';
  END IF;
END//
DELIMITER ;

DELIMITER //
CREATE TRIGGER trg_lpos_bu_validacion
BEFORE UPDATE ON lotes_posiciones
FOR EACH ROW
BEGIN
  DECLARE v_tipo VARCHAR(10);

  SELECT tipo INTO v_tipo
  FROM ubicaciones
  WHERE id_ubicacion = NEW.id_ubicacion;

  IF v_tipo IS NULL OR v_tipo <> 'ALMACEN' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'id_ubicacion debe ser de tipo ALMACEN';
  END IF;

  IF NOT (
       (NEW.estante IS NULL AND NEW.nivel IS NULL AND NEW.pasillo IS NULL)
       OR
       (NEW.estante IS NOT NULL AND NEW.nivel IS NOT NULL AND NEW.pasillo IS NOT NULL)
     ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'estante/nivel/pasillo: o todo NULL o todo informado';
  END IF;
END//
DELIMITER ;

-- LOTES_POSICIONES: auditoría AI/AU/AD

DELIMITER //
CREATE TRIGGER trg_lpos_ai_aud
AFTER INSERT ON lotes_posiciones
FOR EACH ROW
BEGIN
  CALL sp_auditar_encadenado(
    'lotes_posiciones',
    CAST(NEW.id_posicion AS CHAR),
    'INSERT',
    NULL,
    JSON_OBJECT(
      'id_lote', NEW.id_lote,
      'id_ubicacion', NEW.id_ubicacion,
      'estante', NEW.estante,
      'nivel', NEW.nivel,
      'pasillo', NEW.pasillo
    ),
    @ctx_id_usuario,
    NOW()
  );
END//
DELIMITER ;

DELIMITER //
CREATE TRIGGER trg_lpos_au_aud
AFTER UPDATE ON lotes_posiciones
FOR EACH ROW
BEGIN
  CALL sp_auditar_encadenado(
    'lotes_posiciones',
    CAST(NEW.id_posicion AS CHAR),
    'UPDATE',
    JSON_OBJECT(
      'id_lote', OLD.id_lote,
      'id_ubicacion', OLD.id_ubicacion,
      'estante', OLD.estante,
      'nivel', OLD.nivel,
      'pasillo', OLD.pasillo
    ),
    JSON_OBJECT(
      'id_lote', NEW.id_lote,
      'id_ubicacion', NEW.id_ubicacion,
      'estante', NEW.estante,
      'nivel', NEW.nivel,
      'pasillo', NEW.pasillo
    ),
    @ctx_id_usuario,
    NOW()
  );
END//
DELIMITER ;

DELIMITER //
CREATE TRIGGER trg_lpos_ad_aud
AFTER DELETE ON lotes_posiciones
FOR EACH ROW
BEGIN
  CALL sp_auditar_encadenado(
    'lotes_posiciones',
    CAST(OLD.id_posicion AS CHAR),
    'DELETE',
    JSON_OBJECT(
      'id_lote', OLD.id_lote,
      'id_ubicacion', OLD.id_ubicacion,
      'estante', OLD.estante,
      'nivel', OLD.nivel,
      'pasillo', OLD.pasillo
    ),
    NULL,
    @ctx_id_usuario,
    NOW()
  );
END//
DELIMITER ;


-- TOKENS: si expiracion es NULL al crear → poner NOW()+15 min; no permitir “des-uso”
DELIMITER //
CREATE TRIGGER trg_tokens_bi_defaults
BEFORE INSERT ON tokens_recuperacion
FOR EACH ROW
BEGIN
  IF NEW.expiracion IS NULL THEN
    SET NEW.expiracion = DATE_ADD(NOW(), INTERVAL 15 MINUTE);
  END IF;
  SET NEW.usado = COALESCE(NEW.usado, 0);
END//
DELIMITER ;

DELIMITER //
CREATE TRIGGER trg_tokens_bu_no_rev
BEFORE UPDATE ON tokens_recuperacion
FOR EACH ROW
BEGIN
  -- no permitir volver usado de 1 a 0
  IF OLD.usado = 1 AND NEW.usado = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Token ya usado: no reversible';
  END IF;
END//
DELIMITER ;

-- BACKUPS: normalizar estado y auditar inserción
DELIMITER //
CREATE TRIGGER trg_backups_bi_estado
BEFORE INSERT ON backups
FOR EACH ROW
BEGIN
  SET NEW.estado = UPPER(NEW.estado);
END//
DELIMITER ;

DELIMITER //

DELIMITER //
CREATE TRIGGER trg_backups_ai_aud
AFTER INSERT ON backups
FOR EACH ROW
BEGIN
  CALL sp_auditar_encadenado(
    'backups',
    CAST(NEW.id_backup AS CHAR),
    'INSERT',
    NULL,
    JSON_OBJECT(
      'nombre', NEW.nombre_archivo,
      'ruta', NEW.ruta_archivo,
      'estado', NEW.estado
    ),
    @ctx_id_usuario,
    NOW()
  );
END//
DELIMITER ;



DELIMITER //
CREATE TRIGGER trg_comprobantes_bu_control
BEFORE UPDATE ON comprobantes_recepcion
FOR EACH ROW
BEGIN
  -- Al pasar a entregado, asegurar fecha_entrega
  IF NEW.entregado = 1 AND OLD.entregado <> 1 AND NEW.fecha_entrega IS NULL THEN
    SET NEW.fecha_entrega = NOW();
  END IF;
  -- No permitir revertir un comprobante ya entregado
  IF OLD.entregado = 1 AND NEW.entregado = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede revertir un comprobante entregado';
  END IF;
END//
DELIMITER ;

DELIMITER //
CREATE TRIGGER trg_usuarios_bi_normaliza
BEFORE INSERT ON usuarios
FOR EACH ROW
BEGIN
  SET NEW.correo = LOWER(TRIM(NEW.correo));
END//
DELIMITER ;

DELIMITER //
CREATE TRIGGER trg_usuarios_bu_normaliza
BEFORE UPDATE ON usuarios
FOR EACH ROW
BEGIN
  SET NEW.correo = LOWER(TRIM(NEW.correo));
END//
DELIMITER ;


DELIMITER //
CREATE TRIGGER trg_mov_bi_valida
BEFORE INSERT ON movimientos
FOR EACH ROW
BEGIN
  IF NEW.cantidad <= 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'cantidad debe ser > 0';
  END IF;
  IF NEW.tipo NOT IN ('INGRESO','SALIDA','TRANSFERENCIA','AJUSTE') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'tipo inválido';
  END IF;
  IF NEW.tipo='INGRESO' AND NEW.id_ubicacion_destino IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INGRESO requiere id_ubicacion_destino';
  END IF;
  IF NEW.tipo='SALIDA' AND NEW.id_ubicacion_origen IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'SALIDA requiere id_ubicacion_origen';
  END IF;
  IF NEW.tipo='TRANSFERENCIA' AND (NEW.id_ubicacion_origen IS NULL OR NEW.id_ubicacion_destino IS NULL OR NEW.id_ubicacion_origen = NEW.id_ubicacion_destino) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TRANSFERENCIA requiere origen y destino distintos';
  END IF;
  IF NEW.tipo='AJUSTE' AND (NEW.id_ubicacion_origen IS NOT NULL AND NEW.id_ubicacion_destino IS NOT NULL) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'AJUSTE debe afectar solo una ubicación';
  END IF;
END//

/* ===========================================================
		     VISTAS (HU) (LOGICA DE NEGOCIO)
   =========================================================== */

-- HU-03, RF-04, HU-18
CREATE OR REPLACE VIEW v_alertas_stock_bajo AS
SELECT
  it.id_item, it.codigo AS codigo_item, it.descripcion,
  CASE WHEN it.stock_minimo > 0
       THEN it.stock_minimo
       ELSE CAST((SELECT valor FROM parametros_sistema WHERE clave='umbral_stock_bajo_default' LIMIT 1) AS SIGNED)
  END AS stock_minimo,
  COALESCE(SUM(e.saldo),0) AS stock_total
FROM items it
LEFT JOIN lotes l ON l.id_item = it.id_item
LEFT JOIN existencias e ON e.id_lote = l.id_lote
GROUP BY it.id_item, it.codigo, it.descripcion, it.stock_minimo
HAVING COALESCE(SUM(e.saldo),0) <=
       CASE WHEN it.stock_minimo > 0
            THEN it.stock_minimo
            ELSE CAST((SELECT valor FROM parametros_sistema WHERE clave='umbral_stock_bajo_default' LIMIT 1) AS SIGNED)
            END;
            
            
CREATE OR REPLACE VIEW v_alertas_stock_critico AS
SELECT i.id_item, i.codigo AS codigo_item, i.descripcion,
       COALESCE(SUM(e.saldo),0) AS stock_total
FROM items i
LEFT JOIN lotes l ON l.id_item = i.id_item
LEFT JOIN existencias e ON e.id_lote = l.id_lote
GROUP BY i.id_item, i.codigo, i.descripcion
HAVING COALESCE(SUM(e.saldo),0) = 0;

-- HU-03
CREATE OR REPLACE VIEW v_stock_por_item AS
SELECT
  l.id_item, i.codigo, i.descripcion, i.unidad_medida,
  COALESCE(SUM(e.saldo),0) AS stock_total
FROM items i
LEFT JOIN lotes l ON l.id_item = i.id_item
LEFT JOIN existencias e ON e.id_lote = l.id_lote
GROUP BY l.id_item, i.codigo, i.descripcion, i.unidad_medida;
   
-- RF-03
CREATE OR REPLACE VIEW v_existencias_detalle AS
SELECT
  e	.id_existencia,
  l.id_lote, l.codigo_lote, l.fecha_vencimiento, l.costo_unitario,
  i.id_item, i.codigo AS codigo_item, i.descripcion AS descripcion_item,
  e.id_ubicacion, u.nombre AS ubicacion_nombre,
  e.saldo
FROM existencias e
JOIN lotes l ON l.id_lote = e.id_lote
JOIN items i ON i.id_item = l.id_item
JOIN ubicaciones u ON u.id_ubicacion = e.id_ubicacion;

-- RF-03, HU-05, RF-10
CREATE OR REPLACE VIEW v_kardex AS
SELECT
  mv.id_movimiento, mv.fecha, mv.id_lote, l.id_item, mv.tipo,
  COALESCE(mv.id_ubicacion_origen, mv.id_ubicacion_destino) AS id_ubicacion,
  CASE
    WHEN mv.tipo IN ('INGRESO','TRANSFERENCIA') AND mv.id_ubicacion_destino IS NOT NULL THEN mv.cantidad
    WHEN mv.tipo IN ('SALIDA','TRANSFERENCIA','AJUSTE')  AND mv.id_ubicacion_origen  IS NOT NULL THEN -mv.cantidad
    ELSE 0
  END AS delta,
  mv.id_usuario, mv.motivo
FROM movimientos mv
JOIN lotes l ON l.id_lote = mv.id_lote;

-- RF-03, HU-05, RF-10
CREATE OR REPLACE VIEW v_kardex_con_saldo AS
SELECT
  k.*,
  SUM(k.delta) OVER (PARTITION BY k.id_lote, k.id_ubicacion ORDER BY k.fecha, k.id_movimiento) AS saldo_acum
FROM v_kardex k;

-- RF-04, RF-09, RF-10
CREATE OR REPLACE VIEW v_alertas_vencimiento AS
SELECT
  l.id_lote, l.codigo_lote, i.id_item, i.codigo AS codigo_item, i.descripcion,
  l.fecha_vencimiento,
  DATEDIFF(l.fecha_vencimiento, CURDATE()) AS dias_restantes
FROM lotes l
JOIN items i ON i.id_item = l.id_item
WHERE l.fecha_vencimiento <= DATE_ADD(CURDATE(), INTERVAL (SELECT CAST(valor AS SIGNED) FROM parametros_sistema WHERE clave='dias_alerta_venc' LIMIT 1) DAY);

-- HU-05, HU-07
CREATE OR REPLACE VIEW v_kardex_detalle AS
SELECT
  mv.id_movimiento, mv.id_lote, l.codigo_lote,
  it.id_item, it.codigo AS codigo_item, it.descripcion AS descripcion_item,
  mv.tipo, mv.cantidad, mv.id_ubicacion_origen, mv.id_ubicacion_destino,
  mv.motivo, mv.id_usuario, mv.fecha
FROM movimientos mv
JOIN lotes l  ON l.id_lote  = mv.id_lote
JOIN items it ON it.id_item = l.id_item;

-- RF-10,
CREATE OR REPLACE VIEW v_consumos_por_servicio AS
SELECT
  mv.id_ubicacion_destino AS id_servicio,
  u.nombre AS servicio,
  l.id_item, i.codigo, i.descripcion AS item,
  SUM(mv.cantidad) AS consumo_total,
  MIN(mv.fecha) AS desde, MAX(mv.fecha) AS hasta
FROM movimientos mv
JOIN lotes l ON l.id_lote = mv.id_lote
JOIN items i ON i.id_item = l.id_item
JOIN ubicaciones u ON u.id_ubicacion = mv.id_ubicacion_destino
WHERE mv.tipo = 'SALIDA' AND mv.id_ubicacion_destino IS NOT NULL
GROUP BY mv.id_ubicacion_destino, u.nombre, l.id_item, i.codigo, i.descripcion;

-- RF-10, HU-15
CREATE OR REPLACE VIEW v_auditoria_por_usuario AS
SELECT 
    a.id_usuario,
    u.nombre_completo AS usuario,
    u.rol,
    a.tabla_afectada,
    a.pk_afectada,
    a.accion,
    a.valores_antes,
    a.valores_despues,
    a.fecha
FROM auditoria a
LEFT JOIN usuarios u ON u.id_usuario = a.id_usuario
ORDER BY a.fecha DESC;

-- HU-14
CREATE OR REPLACE VIEW v_dashboard_auxiliar AS
SELECT 
    'Entradas últimos 30 días' AS metrica,
    COUNT(*) AS valor
FROM movimientos
WHERE tipo = 'INGRESO'
  AND fecha >= DATE_SUB(CURDATE(), INTERVAL 30 DAY);
  
  -- HU-14
  CREATE OR REPLACE VIEW v_dashboard_regente AS
SELECT 'Ítems con stock bajo' AS metrica, COUNT(*) AS valor
FROM v_alertas_stock_bajo
UNION ALL
SELECT 'Lotes próximos a vencer', COUNT(*) AS valor
FROM v_alertas_vencimiento;

-- HU-14
CREATE OR REPLACE VIEW v_dashboard_auditor AS
SELECT 'Eventos de auditoría últimos 30 días' AS metrica, COUNT(*) AS valor
FROM auditoria
WHERE fecha >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
UNION ALL
SELECT 'Usuarios modificados', COUNT(*) AS valor
FROM auditoria
WHERE tabla_afectada = 'usuarios'
  AND fecha >= DATE_SUB(CURDATE(), INTERVAL 30 DAY);

-- HU-14
CREATE OR REPLACE VIEW v_dashboard_proveedor AS
SELECT 'Lotes entregados confirmados' AS metrica, COUNT(*) AS valor
FROM comprobantes_recepcion
WHERE entregado = 1
UNION ALL
SELECT 'Lotes entregados últimos 30 días', COUNT(*) AS valor
FROM comprobantes_recepcion
WHERE fecha_entrega >= DATE_SUB(CURDATE(), INTERVAL 30 DAY);



-- HU-21
CREATE OR REPLACE VIEW v_etiquetas_lote AS
SELECT 
    e.id_etiqueta,
    l.codigo_lote,
    i.descripcion AS medicamento,
    l.fecha_vencimiento,
    e.fecha_generacion,
    e.contenido_qr
FROM etiquetas_qr e
JOIN lotes l ON l.id_lote = e.id_lote
JOIN items i ON i.id_item = l.id_item;

-- HU-22
CREATE OR REPLACE VIEW v_lotes_vencidos AS
WITH ult AS (
  SELECT id_lote, id_usuario
  FROM (
    SELECT m.*,
           ROW_NUMBER() OVER (PARTITION BY m.id_lote ORDER BY m.fecha DESC, m.id_movimiento DESC) AS rn
    FROM movimientos m
  ) x
  WHERE rn = 1
)
SELECT
  l.id_lote,
  l.codigo_lote,
  i.codigo     AS codigo_item,
  i.descripcion AS medicamento,
  l.fecha_vencimiento,
  DATEDIFF(l.fecha_vencimiento, CURRENT_DATE()) AS dias_restantes,
  u.nombre_completo AS responsable
FROM lotes l
JOIN items i ON i.id_item = l.id_item
LEFT JOIN ult      ON ult.id_lote = l.id_lote
LEFT JOIN usuarios u ON u.id_usuario = ult.id_usuario
WHERE l.fecha_vencimiento < CURRENT_DATE();

-- HU-24
CREATE OR REPLACE VIEW v_proveedores_estado AS
SELECT 
    id_proveedor,
    nombre,
    nit,
    CASE activo WHEN 1 THEN 'ACTIVO' ELSE 'INACTIVO' END AS estado,
    DATE(fecha_creacion) AS fecha_registro
FROM proveedores;

-- HU-25
CREATE OR REPLACE VIEW v_historial_notificaciones AS
SELECT 
    n.id_notificacion,
    n.tipo,
    n.payload,
    n.destinatario,
    n.estado,
    n.fecha_creacion,
    n.fecha_envio,
    n.confirmado_por,
    u.nombre_completo AS usuario_confirmador,
    n.fecha_confirmacion,
    n.estado_confirmacion
FROM notificaciones n
LEFT JOIN usuarios u ON u.id_usuario = n.confirmado_por;


-- HU-27
CREATE OR REPLACE VIEW v_usuarios_inactivos AS
SELECT 
    id_usuario,
    nombre_completo,
    correo,
    rol,
    fecha_ultimo_login,
    DATEDIFF(CURRENT_DATE(), fecha_ultimo_login) AS dias_inactivo
FROM usuarios
WHERE fecha_ultimo_login IS NULL
   OR fecha_ultimo_login < DATE_SUB(CURRENT_DATE(), INTERVAL 60 DAY);
   
-- HU-28
CREATE OR REPLACE VIEW v_confirmaciones_alertas AS
SELECT 
    n.id_notificacion,
    n.tipo,
    n.destinatario,
    n.estado,
    n.fecha_creacion,
    n.fecha_envio,
    n.estado_confirmacion,
    n.fecha_confirmacion,
    u.nombre_completo AS confirmado_por
FROM notificaciones n
LEFT JOIN usuarios u ON u.id_usuario = n.confirmado_por
WHERE n.estado_confirmacion = 'REVISADA';

-- HU-29
CREATE OR REPLACE VIEW v_ubicaciones_lote AS
SELECT
  l.id_lote,
  l.codigo_lote,
  i.descripcion     AS medicamento,
  u.nombre          AS almacen,
  lp.estante,
  lp.nivel,
  lp.pasillo
FROM lotes l
JOIN items i             ON i.id_item = l.id_item
JOIN lotes_posiciones lp ON lp.id_lote = l.id_lote
JOIN ubicaciones u       ON u.id_ubicacion = lp.id_ubicacion;

CREATE OR REPLACE VIEW v_resumen_auditoria AS
SELECT
  tabla_afectada, COUNT(*) AS total_eventos, MAX(fecha) AS ultimo_evento, MAX(id_evento) AS id_ultimo
FROM auditoria
GROUP BY tabla_afectada;

CREATE OR REPLACE VIEW v_kardex_fisico AS
SELECT
  mv.id_movimiento, mv.fecha, mv.id_lote, l.id_item,
  i.codigo AS codigo_item, i.descripcion AS item,
  mv.tipo,
  COALESCE(mv.id_ubicacion_origen, mv.id_ubicacion_destino) AS id_ubicacion,
  u.nombre AS ubicacion,
  CASE
    WHEN mv.tipo IN ('INGRESO','TRANSFERENCIA') AND mv.id_ubicacion_destino IS NOT NULL THEN mv.cantidad
    WHEN mv.tipo IN ('SALIDA','TRANSFERENCIA','AJUSTE')  AND mv.id_ubicacion_origen  IS NOT NULL THEN -mv.cantidad
    ELSE 0
  END AS delta,
  mv.id_usuario, us.nombre_completo AS usuario, mv.motivo
FROM movimientos mv
JOIN lotes l ON l.id_lote = mv.id_lote
JOIN items i ON i.id_item = l.id_item
LEFT JOIN ubicaciones u ON u.id_ubicacion = COALESCE(mv.id_ubicacion_origen, mv.id_ubicacion_destino)
LEFT JOIN usuarios us ON us.id_usuario = mv.id_usuario;

-- RF-04, RF-09, HU-18
DROP EVENT IF EXISTS ev_generar_alertas_diarias;
CREATE EVENT ev_generar_alertas_diarias
ON SCHEDULE EVERY 1 DAY
STARTS (CURRENT_DATE + INTERVAL 6 HOUR)
DO CALL sp_generar_alertas_diarias();

-- HU-12
DROP EVENT IF EXISTS ev_backup_diario;
CREATE EVENT ev_backup_diario
ON SCHEDULE EVERY 1 DAY
STARTS (CURRENT_DATE + INTERVAL 2 HOUR)
DO CALL sp_generar_backup(1, '/var/backups', CONCAT('farmagestion_', DATE_FORMAT(NOW(), '%Y%m%d_%H%i%s'), '.sql'));


CREATE OR REPLACE VIEW v_trazabilidad_lote_full AS
SELECT
  l.id_lote, l.codigo_lote, l.fecha_vencimiento, l.costo_unitario,
  i.id_item, i.codigo AS codigo_item, i.descripcion AS item,
  p.id_proveedor, p.nombre AS proveedor,
  SUM(e.saldo) AS stock_total,
  MIN(mv.fecha) AS primera_operacion,
  MAX(mv.fecha) AS ultima_operacion,
  COUNT(mv.id_movimiento) AS movimientos,
  (SELECT COUNT(*) FROM control_calidad cc WHERE cc.id_lote=l.id_lote) AS controles_calidad,
  (SELECT COUNT(*) FROM etiquetas_qr eq WHERE eq.id_lote=l.id_lote) AS etiquetas_qr
FROM lotes l
JOIN items i ON i.id_item=l.id_item
JOIN proveedores p ON p.id_proveedor=l.id_proveedor
LEFT JOIN existencias e ON e.id_lote=l.id_lote
LEFT JOIN movimientos mv ON mv.id_lote=l.id_lote
GROUP BY l.id_lote, l.codigo_lote, l.fecha_vencimiento, l.costo_unitario, i.id_item, i.codigo, i.descripcion, p.id_proveedor, p.nombre;



CREATE OR REPLACE VIEW v_stock_por_servicio AS
SELECT
  u.id_ubicacion AS id_servicio,
  u.nombre       AS servicio,
  i.id_item, i.codigo, i.descripcion,
  SUM(e.saldo)   AS stock_en_servicio
FROM existencias e
JOIN lotes l ON l.id_lote=e.id_lote
JOIN items i ON i.id_item=l.id_item
JOIN ubicaciones u ON u.id_ubicacion=e.id_ubicacion
WHERE u.tipo='SERVICIO'
GROUP BY u.id_ubicacion, u.nombre, i.id_item, i.codigo, i.descripcion;


CREATE OR REPLACE VIEW v_items_con_anomalias AS
SELECT i.id_item, i.codigo, i.descripcion,
       SUM(e.saldo) AS stock_total
FROM items i
LEFT JOIN lotes l ON l.id_item=i.id_item
LEFT JOIN existencias e ON e.id_lote=l.id_lote
GROUP BY i.id_item,i.codigo,i.descripcion
HAVING SUM(COALESCE(e.saldo,0)) < 0;


-- procedimientos para el front

DELIMITER //
CREATE PROCEDURE sp_listar_inventario()
BEGIN
    SELECT i.descripcion AS nombre,
           l.codigo_lote AS lote,
           i.tipo_item AS categoria,
           COALESCE(SUM(e.saldo),0) AS stock,
           DATE_FORMAT(l.fecha_vencimiento, '%d/%m/%Y') AS fecha_vencimiento,
           u.nombre AS ubicacion,
           CASE WHEN COALESCE(SUM(e.saldo),0) > 0 THEN 'Activo' ELSE 'Inactivo' END AS estado
    FROM lotes l
    JOIN items i ON i.id_item = l.id_item
    LEFT JOIN existencias e ON e.id_lote = l.id_lote
    LEFT JOIN ubicaciones u ON u.id_ubicacion = e.id_ubicacion
    GROUP BY i.descripcion, l.codigo_lote, i.tipo_item, l.fecha_vencimiento, u.nombre
    ORDER BY i.descripcion ASC;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_buscar_inventario(
    IN p_filtro VARCHAR(100),
    IN p_page INT,
    IN p_limit INT
)
BEGIN
    DECLARE v_offset INT;
    SET v_offset = (p_page - 1) * p_limit;

    SELECT 
        i.descripcion AS nombre,
        l.codigo_lote AS lote,
        i.tipo_item AS categoria,
        COALESCE(SUM(e.saldo),0) AS stock,
        DATE_FORMAT(l.fecha_vencimiento, '%d/%m/%Y') AS fecha_vencimiento,
        u.nombre AS ubicacion,
        CASE WHEN COALESCE(SUM(e.saldo),0) > 0 THEN 'Activo' ELSE 'Inactivo' END AS estado
    FROM lotes l
    JOIN items i ON i.id_item = l.id_item
    LEFT JOIN existencias e ON e.id_lote = l.id_lote
    LEFT JOIN ubicaciones u ON u.id_ubicacion = e.id_ubicacion
    WHERE LOWER(i.descripcion) LIKE LOWER(CONCAT('%', p_filtro, '%'))
       OR LOWER(l.codigo_lote) LIKE LOWER(CONCAT('%', p_filtro, '%'))
    GROUP BY i.descripcion, l.codigo_lote, i.tipo_item, l.fecha_vencimiento, u.nombre
    ORDER BY i.descripcion ASC
    LIMIT p_limit OFFSET v_offset;
END//
DELIMITER ;


DELIMITER //
CREATE PROCEDURE sp_exportar_inventario()
BEGIN
    SELECT i.descripcion AS nombre,
           l.codigo_lote AS lote,
           i.tipo_item AS categoria,
           COALESCE(SUM(e.saldo),0) AS stock,
           l.fecha_vencimiento,
           u.nombre AS ubicacion
    FROM lotes l
    JOIN items i ON i.id_item = l.id_item
    LEFT JOIN existencias e ON e.id_lote = l.id_lote
    LEFT JOIN ubicaciones u ON u.id_ubicacion = e.id_ubicacion
    GROUP BY i.descripcion, l.codigo_lote, i.tipo_item, l.fecha_vencimiento, u.nombre;
END//
DELIMITER ;


DELIMITER //
CREATE PROCEDURE sp_obtener_detalle_lote(IN p_id_lote INT)
BEGIN
    SELECT i.descripcion AS nombre,
           l.codigo_lote AS lote,
           i.tipo_item AS categoria,
           COALESCE(SUM(e.saldo),0) AS stock,
           DATE_FORMAT(l.fecha_vencimiento, '%d/%m/%Y') AS fecha_vencimiento
    FROM lotes l
    JOIN items i ON i.id_item = l.id_item
    LEFT JOIN existencias e ON e.id_lote = l.id_lote
    WHERE l.id_lote = p_id_lote
    GROUP BY i.descripcion, l.codigo_lote, i.tipo_item, l.fecha_vencimiento;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_actualizar_estado_lote(IN p_id_lote INT, IN p_estado ENUM('ACTIVO','INACTIVO'))
BEGIN
    UPDATE lotes SET estado = p_estado WHERE id_lote = p_id_lote;
END//
DELIMITER ;



DELIMITER //
CREATE PROCEDURE sp_reportes_alertas_resueltas()
BEGIN
    SELECT ROUND(
        (SELECT COUNT(*) FROM notificaciones WHERE estado_confirmacion = 'REVISADA') /
        (SELECT COUNT(*) FROM notificaciones) * 100, 2
    ) AS porcentaje_resueltas;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_reportes_pedidos_completados()
BEGIN
    SELECT COUNT(*) AS pedidos_completados
    FROM ordenes
    WHERE estado = 'ENTREGADO'
      AND MONTH(fecha_creacion) = MONTH(CURDATE())
      AND YEAR(fecha_creacion) = YEAR(CURDATE());
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_reportes_medicamentos_entregados_por_semana()
BEGIN
    SELECT WEEK(mv.fecha) AS semana, SUM(mv.cantidad) AS total_entregados
    FROM movimientos mv
    WHERE mv.tipo = 'SALIDA'
      AND MONTH(mv.fecha) = MONTH(CURDATE())
      AND YEAR(mv.fecha) = YEAR(CURDATE())
    GROUP BY WEEK(mv.fecha)
    ORDER BY semana;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_reportes_ordenes_mes()
BEGIN
    SELECT o.id_orden AS orden,
           i.descripcion AS medicamento,
           u.nombre AS area_hospitalaria,
           DATE_FORMAT(o.fecha_creacion, '%d/%m/%Y') AS fecha,
           od.cantidad
    FROM ordenes o
    JOIN orden_detalle od ON od.id_orden = o.id_orden
    JOIN items i ON i.id_item = od.id_item
    JOIN ubicaciones u ON u.id_ubicacion = i.id_ubicacion
    WHERE MONTH(o.fecha_creacion) = MONTH(CURDATE())
      AND YEAR(o.fecha_creacion) = YEAR(CURDATE())
    ORDER BY o.fecha_creacion DESC;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_exportar_reporte_ordenes_mes()
BEGIN
    SELECT o.id_orden, i.descripcion AS medicamento, u.nombre AS area_hospitalaria,
           o.fecha_creacion, od.cantidad
    FROM ordenes o
    JOIN orden_detalle od ON od.id_orden = o.id_orden
    JOIN items i ON i.id_item = od.id_item
    JOIN ubicaciones u ON u.id_ubicacion = i.id_ubicacion
    WHERE MONTH(o.fecha_creacion) = MONTH(CURDATE())
      AND YEAR(o.fecha_creacion) = YEAR(CURDATE());
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_listar_ordenes()
BEGIN
    SELECT o.id_orden AS ID,
           p.nombre_completo AS paciente,
           DATE_FORMAT(o.fecha_creacion, '%d/%m/%Y') AS fecha,
           o.estado
    FROM ordenes o
    JOIN pacientes p ON p.id_paciente = o.id_paciente
    ORDER BY o.fecha_creacion DESC;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_listar_ordenes_por_estado(IN p_estado ENUM('PENDIENTE','PREPARACION','ENTREGADO','CANCELADO'))
BEGIN
    SELECT o.id_orden AS ID,
           p.nombre_completo AS paciente,
           DATE_FORMAT(o.fecha_creacion, '%d/%m/%Y') AS fecha,
           o.estado
    FROM ordenes o
    JOIN pacientes p ON p.id_paciente = o.id_paciente
    WHERE o.estado = p_estado
    ORDER BY o.fecha_creacion DESC;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_buscar_ordenes(IN p_filtro VARCHAR(100))
BEGIN
    SELECT o.id_orden AS ID,
           p.nombre_completo AS paciente,
           DATE_FORMAT(o.fecha_creacion, '%d/%m/%Y') AS fecha,
           o.estado
    FROM ordenes o
    JOIN pacientes p ON p.id_paciente = o.id_paciente
    WHERE p.nombre_completo LIKE CONCAT('%', p_filtro, '%')
    ORDER BY o.fecha_creacion DESC;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_crear_orden(
    IN p_id_paciente INT,
    IN p_id_usuario INT,
    IN p_observaciones VARCHAR(255)
)
BEGIN
    INSERT INTO ordenes(id_paciente, id_usuario, observaciones)
    VALUES (p_id_paciente, p_id_usuario, p_observaciones);
    SELECT LAST_INSERT_ID() AS id_orden;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_agregar_detalle_orden(
    IN p_id_orden INT,
    IN p_id_item INT,
    IN p_cantidad DECIMAL(10,2)
)
BEGIN
    INSERT INTO orden_detalle(id_orden, id_item, cantidad)
    VALUES (p_id_orden, p_id_item, p_cantidad);
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_actualizar_estado_orden(
    IN p_id_orden INT,
    IN p_estado ENUM('PENDIENTE','PREPARACION','ENTREGADO','CANCELADO')
)
BEGIN
    UPDATE ordenes SET estado = p_estado WHERE id_orden = p_id_orden;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_obtener_detalle_orden(IN p_id_orden INT)
BEGIN
    SELECT i.descripcion AS medicamento, od.cantidad
    FROM orden_detalle od
    JOIN items i ON i.id_item = od.id_item
    WHERE od.id_orden = p_id_orden;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_listar_medicamentos()
BEGIN
    SELECT i.descripcion AS medicamento,
           COALESCE(SUM(e.saldo),0) AS stock,
           DATE_FORMAT(MIN(l.fecha_vencimiento), '%d/%m/%Y') AS vencimiento,
           u.nombre AS area,
           CASE WHEN i.uso_frecuente = 1 THEN 'Frecuente' ELSE 'No frecuente' END AS uso_frecuente
    FROM items i
    LEFT JOIN lotes l ON l.id_item = i.id_item
    LEFT JOIN existencias e ON e.id_lote = l.id_lote
    LEFT JOIN ubicaciones u ON u.id_ubicacion = i.id_ubicacion
    GROUP BY i.descripcion, u.nombre, i.uso_frecuente
    ORDER BY i.descripcion ASC;
END//
DELIMITER ;


DELIMITER //
CREATE PROCEDURE sp_reportes_medicamentos_entregados_mes()
BEGIN
    SELECT COALESCE(SUM(mv.cantidad),0) AS total_entregados
    FROM movimientos mv
    WHERE mv.tipo = 'SALIDA'
      AND MONTH(mv.fecha) = MONTH(CURDATE())
      AND YEAR(mv.fecha) = YEAR(CURDATE());
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_buscar_medicamento(
    IN p_filtro VARCHAR(100),
    IN p_page INT,
    IN p_limit INT
)
BEGIN
    DECLARE v_offset INT;
    SET v_offset = (p_page - 1) * p_limit;

    SELECT 
        i.descripcion AS nombre,
        u.nombre AS area,
        l.codigo_lote AS lote,
        i.tipo_item AS categoria,
        COALESCE(SUM(e.saldo),0) AS stock,
        DATE_FORMAT(l.fecha_vencimiento, '%d/%m/%Y') AS fecha_vencimiento,
        CASE WHEN i.uso_frecuente = 1 THEN 'Frecuente' ELSE 'No frecuente' END AS uso_frecuente,
        CASE WHEN COALESCE(SUM(e.saldo),0) > 0 THEN 'Activo' ELSE 'Inactivo' END AS estado
    FROM lotes l
    JOIN items i ON i.id_item = l.id_item
    LEFT JOIN existencias e ON e.id_lote = l.id_lote
    LEFT JOIN ubicaciones u ON u.id_ubicacion = e.id_ubicacion
    WHERE 
          (LOWER(i.descripcion) LIKE LOWER(CONCAT('%', p_filtro, '%'))
        OR
          LOWER(l.codigo_lote) LIKE LOWER(CONCAT('%', p_filtro, '%')))
        AND
          i.tipo_item = 'MEDICAMENTO'
    GROUP BY i.descripcion, l.codigo_lote, i.tipo_item, l.fecha_vencimiento, u.nombre
    ORDER BY i.descripcion ASC
    LIMIT p_limit OFFSET v_offset;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_crear_medicamento(
    IN p_id_ubicacion INT,
    IN p_codigo VARCHAR(50),
    IN p_descripcion VARCHAR(255),
    IN p_unidad_medida VARCHAR(20),
    IN p_stock_minimo INT,
    IN p_uso_frecuente TINYINT
)
BEGIN
    INSERT INTO items(id_ubicacion, codigo, descripcion, tipo_item, unidad_medida, stock_minimo, uso_frecuente)
    VALUES (p_id_ubicacion, p_codigo, p_descripcion, 'MEDICAMENTO', COALESCE(p_unidad_medida,'UND'), COALESCE(p_stock_minimo,0), COALESCE(p_uso_frecuente,0));
    SELECT LAST_INSERT_ID() AS id_item;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_actualizar_medicamento(
    IN p_id_item INT,
    IN p_descripcion VARCHAR(255),
    IN p_stock_minimo INT,
    IN p_uso_frecuente TINYINT
)
BEGIN
    UPDATE items
    SET descripcion = p_descripcion,
        stock_minimo = p_stock_minimo,
        uso_frecuente = p_uso_frecuente
    WHERE id_item = p_id_item;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_obtener_medicamento(IN p_id_item INT)
BEGIN
    SELECT id_item, descripcion, stock_minimo, uso_frecuente
    FROM items
    WHERE id_item = p_id_item;
END//
DELIMITER ;

DELIMITER //
CREATE TRIGGER trg_items_bi_validacion_front
BEFORE INSERT ON items
FOR EACH ROW
BEGIN
    IF NEW.descripcion IS NULL OR TRIM(NEW.descripcion) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Descripción obligatoria';
    END IF;
    IF EXISTS (SELECT 1 FROM items WHERE codigo = NEW.codigo) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Código de medicamento ya existe';
    END IF;
    IF NEW.uso_frecuente NOT IN (0,1) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor inválido para uso frecuente';
    END IF;
END//
DELIMITER ;

DELIMITER //
CREATE TRIGGER trg_ordenes_bi_validacion
BEFORE INSERT ON ordenes
FOR EACH ROW
BEGIN
    IF NEW.id_paciente IS NULL OR NOT EXISTS (SELECT 1 FROM pacientes WHERE id_paciente = NEW.id_paciente) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Paciente no válido para la orden';
    END IF;
    IF NEW.estado NOT IN ('PENDIENTE','PREPARACION','ENTREGADO','CANCELADO') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Estado de orden inválido';
    END IF;
END//
DELIMITER ;

DELIMITER //
CREATE TRIGGER trg_orden_detalle_bi_validacion
BEFORE INSERT ON orden_detalle
FOR EACH ROW
BEGIN
    IF NEW.cantidad <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cantidad debe ser mayor a cero';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM items WHERE id_item = NEW.id_item) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ítem no válido para la orden';
    END IF;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_listar_pacientes()
BEGIN
    SELECT id_paciente, nombre_completo AS nombre, documento AS identificacion,
           DATE_FORMAT(fecha_ingreso, '%d/%m/%Y') AS fecha_ingreso,
           DATE_FORMAT(ultima_atencion, '%d/%m/%Y') AS ultima_atencion
    FROM pacientes
    ORDER BY nombre_completo ASC;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_buscar_paciente(IN p_filtro VARCHAR(100))
BEGIN
    SELECT id_paciente, nombre_completo AS nombre, documento AS identificacion,
           DATE_FORMAT(fecha_ingreso, '%d/%m/%Y') AS fecha_ingreso,
           DATE_FORMAT(ultima_atencion, '%d/%m/%Y') AS ultima_atencion
    FROM pacientes
    WHERE nombre_completo LIKE CONCAT('%', p_filtro, '%')
       OR documento LIKE CONCAT('%', p_filtro, '%')
    ORDER BY nombre_completo ASC;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_crear_paciente(
    IN p_tipo_documento ENUM('CEDULA','TARJETA DE IDENTIDAD','TARJETA DE EXTRANJERÍA'),
    IN p_documento VARCHAR(25),
    IN p_nombre_completo VARCHAR(50),
    IN p_fecha_ingreso DATE
)
BEGIN
    INSERT INTO pacientes(tipo_documento, documento, nombre_completo, fecha_ingreso)
    VALUES (p_tipo_documento, p_documento, p_nombre_completo, p_fecha_ingreso);
    SELECT LAST_INSERT_ID() AS id_paciente;
END//

DELIMITER //
CREATE PROCEDURE sp_actualizar_ultima_atencion(IN p_id_paciente INT)
BEGIN
    UPDATE pacientes SET ultima_atencion = CURDATE() WHERE id_paciente = p_id_paciente;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_eliminar_paciente(IN p_id_paciente INT)
BEGIN
    DELETE FROM pacientes WHERE id_paciente = p_id_paciente;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_obtener_paciente(IN p_id_paciente INT)
BEGIN
    SELECT id_paciente, tipo_documento, documento, nombre_completo, fecha_ingreso, ultima_atencion
    FROM pacientes WHERE id_paciente = p_id_paciente;
END//
DELIMITER ;


DELIMITER //
CREATE TRIGGER trg_pacientes_bi_validacion
BEFORE INSERT ON pacientes
FOR EACH ROW
BEGIN
    IF NEW.documento IS NULL OR TRIM(NEW.documento) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Documento obligatorio';
    END IF;
    IF EXISTS (SELECT 1 FROM pacientes WHERE documento = NEW.documento) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Documento ya registrado';
    END IF;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_dashboard_stock_disponible()
BEGIN
    SELECT ROUND(
        (SELECT COALESCE(SUM(saldo),0) FROM existencias) /
        (SELECT COALESCE(SUM(stock_minimo),1) FROM items) * 100, 2
    ) AS stock_disponible;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_dashboard_alertas_vencimiento()
BEGIN
    SELECT COUNT(*) AS alertas_vencimiento FROM v_alertas_vencimiento;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_dashboard_ordenes_pendientes()
BEGIN
    SELECT COUNT(*) AS ordenes_pendientes FROM ordenes WHERE estado = 'PENDIENTE';
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_dashboard_medicamentos_mas_usados()
BEGIN
    SELECT i.descripcion AS medicamento, SUM(mv.cantidad) AS total_consumo
    FROM movimientos mv
    JOIN lotes l ON l.id_lote = mv.id_lote
    JOIN items i ON i.id_item = l.id_item
    WHERE mv.tipo = 'SALIDA'
    GROUP BY i.descripcion
    ORDER BY total_consumo DESC
    LIMIT 5;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_dashboard_distribucion_por_area()
BEGIN
    SELECT u.nombre AS area, SUM(mv.cantidad) AS consumo_total
    FROM movimientos mv
    JOIN ubicaciones u ON u.id_ubicacion = mv.id_ubicacion_destino
    WHERE mv.tipo = 'SALIDA'
    GROUP BY u.nombre;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_dashboard_medicamentos_stock_critico()
BEGIN
    SELECT COUNT(*) AS medicamentos_stock_critico FROM v_alertas_stock_critico;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_dashboard_medicamentos_proximos_vencer()
BEGIN
    SELECT i.descripcion AS medicamento, l.fecha_vencimiento, 
           COALESCE(SUM(e.saldo),0) AS cantidad
    FROM lotes l
    JOIN items i ON i.id_item = l.id_item
    LEFT JOIN existencias e ON e.id_lote = l.id_lote
    WHERE l.fecha_vencimiento <= DATE_ADD(CURDATE(), INTERVAL (SELECT CAST(valor AS SIGNED) FROM parametros_sistema WHERE clave='dias_alerta_venc') DAY)
    GROUP BY i.descripcion, l.fecha_vencimiento
    ORDER BY l.fecha_vencimiento ASC
    LIMIT 5;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_dashboard_lista_ordenes_pendientes()
BEGIN
  SELECT 
    o.id_orden,
    p.nombre_completo AS paciente,
    u.nombre AS area,
    o.estado,
    GROUP_CONCAT(CONCAT(i.descripcion, ' (', od.cantidad, ')') SEPARATOR ', ') AS medicamentos
  FROM ordenes o
  JOIN pacientes p ON p.id_paciente = o.id_paciente
  JOIN orden_detalle od ON od.id_orden = o.id_orden
  JOIN items i ON i.id_item = od.id_item
  JOIN ubicaciones u ON u.id_ubicacion = i.id_ubicacion     -- <== área por ítem
  WHERE o.estado = 'PENDIENTE'
  GROUP BY o.id_orden, p.nombre_completo, u.nombre, o.estado
  ORDER BY o.fecha_creacion ASC
  LIMIT 5;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_dashboard_fecha_actual()
BEGIN
    SELECT DATE_FORMAT(NOW(), '%d de %M de %Y') AS fecha_actual;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_dashboard_ultimo_backup()
BEGIN
    SELECT nombre_archivo, fecha_creacion, estado
    FROM backups
    ORDER BY fecha_creacion DESC
    LIMIT 1;
END//
DELIMITER ; 

DELIMITER //
CREATE PROCEDURE sp_dashboard_alertas_stock_bajo()
BEGIN
    SELECT COUNT(*) AS alertas_stock_bajo FROM v_alertas_stock_bajo;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_dashboard_sesiones_activas()
BEGIN
    SELECT COUNT(*) AS sesiones_activas FROM sesiones_activas WHERE activo = 1;
END//
DELIMITER ;