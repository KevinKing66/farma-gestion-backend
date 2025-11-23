
DELIMITER //

/* =========================
   LOTES + MOVIMIENTOS
   ========================= */

/* sp_crear_lote_ctx */
DROP PROCEDURE IF EXISTS sp_crear_lote_ctx;
CREATE PROCEDURE sp_crear_lote_ctx(
  IN p_id_item INT,
  IN p_nombre_item VARCHAR(255),
  IN p_unidad_medida VARCHAR(20),
  IN p_stock_minimo INT,
  IN p_id_proveedor INT,
  IN p_codigo_lote VARCHAR(50),
  IN p_fecha_vencimiento DATE,
  IN p_costo_unitario DECIMAL(10,2),
  IN p_id_ubicacion_destino INT,
  IN p_cantidad INT,
  IN p_id_usuario INT,
  IN p_motivo VARCHAR(255)
)
BEGIN
  SET @ctx_id_usuario = p_id_usuario;
  CALL sp_crear_lote(
    p_id_item, p_nombre_item, p_unidad_medida, p_stock_minimo,
    p_id_proveedor, p_codigo_lote, p_fecha_vencimiento, p_costo_unitario,
    p_id_ubicacion_destino, p_cantidad, p_id_usuario, p_motivo
  );
  SET @ctx_id_usuario = NULL;
END//

/* sp_registrar_ingreso_ctx */
DROP PROCEDURE IF EXISTS sp_registrar_ingreso_ctx;
CREATE PROCEDURE sp_registrar_ingreso_ctx(
  IN p_id_item INT, IN p_id_proveedor INT, IN p_codigo_lote VARCHAR(50),
  IN p_fecha_venc DATE, IN p_costo_unitario DECIMAL(10,2),
  IN p_id_ubicacion_destino INT, IN p_cantidad INT,
  IN p_id_usuario INT, IN p_motivo VARCHAR(255)
)
BEGIN
  SET @ctx_id_usuario = p_id_usuario;
  CALL sp_registrar_ingreso(
    p_id_item, p_id_proveedor, p_codigo_lote, p_fecha_venc, p_costo_unitario,
    p_id_ubicacion_destino, p_cantidad, p_id_usuario, p_motivo
  );
  SET @ctx_id_usuario = NULL;
END//

/* sp_registrar_salida_ctx */
DROP PROCEDURE IF EXISTS sp_registrar_salida_ctx;
CREATE PROCEDURE sp_registrar_salida_ctx(
  IN p_id_lote INT, IN p_id_ubicacion_origen INT, IN p_id_ubicacion_destino INT,
  IN p_cantidad INT, IN p_id_usuario INT, IN p_motivo VARCHAR(255)
)
BEGIN
  SET @ctx_id_usuario = p_id_usuario;
  CALL sp_registrar_salida(
    p_id_lote, p_id_ubicacion_origen, p_id_ubicacion_destino, p_cantidad, p_id_usuario, p_motivo
  );
  SET @ctx_id_usuario = NULL;
END//

/* sp_transferir_stock_ctx */
DROP PROCEDURE IF EXISTS sp_transferir_stock_ctx;
CREATE PROCEDURE sp_transferir_stock_ctx(
  IN p_id_lote INT, IN p_id_ubicacion_origen INT, IN p_id_ubicacion_destino INT,
  IN p_cantidad INT, IN p_id_usuario INT, IN p_motivo VARCHAR(255)
)
BEGIN
  SET @ctx_id_usuario = p_id_usuario;
  CALL sp_transferir_stock(
    p_id_lote, p_id_ubicacion_origen, p_id_ubicacion_destino, p_cantidad, p_id_usuario, p_motivo
  );
  SET @ctx_id_usuario = NULL;
END//

/* sp_ajustar_stock_ctx */
DROP PROCEDURE IF EXISTS sp_ajustar_stock_ctx;
CREATE PROCEDURE sp_ajustar_stock_ctx(
  IN p_id_lote INT,
  IN p_id_ubicacion INT,
  IN p_cantidad INT,
  IN p_sentido VARCHAR(12), /* 'AUMENTO' | 'DISMINUCION' */
  IN p_id_usuario INT,
  IN p_motivo VARCHAR(255)
)
BEGIN
  SET @ctx_id_usuario = p_id_usuario;
  CALL sp_ajustar_stock(
    p_id_lote, p_id_ubicacion, p_cantidad, p_sentido, p_id_usuario, p_motivo
  );
  SET @ctx_id_usuario = NULL;
END//

/* sp_registrar_devolucion_ctx */
DROP PROCEDURE IF EXISTS sp_registrar_devolucion_ctx;
CREATE PROCEDURE sp_registrar_devolucion_ctx(
  IN p_id_lote INT,
  IN p_id_ubicacion INT,
  IN p_cantidad INT,
  IN p_id_usuario INT,
  IN p_motivo VARCHAR(255)
)
BEGIN
  SET @ctx_id_usuario = p_id_usuario;
  CALL sp_registrar_devolucion(
    p_id_lote, p_id_ubicacion, p_cantidad, p_id_usuario, p_motivo
  );
  SET @ctx_id_usuario = NULL;
END//

/* =========================
   SEGURIDAD / ACCESO / SOPORTE
   ========================= */

/* sp_validar_ip_ctx (opcional; el SP ya recibe p_id_usuario, pero envolvemos para uniformidad) */
DROP PROCEDURE IF EXISTS sp_validar_ip_ctx;
CREATE PROCEDURE sp_validar_ip_ctx(IN p_ip VARCHAR(45), IN p_id_usuario INT)
BEGIN
  SET @ctx_id_usuario = p_id_usuario;
  CALL sp_validar_ip(p_ip, p_id_usuario);
  SET @ctx_id_usuario = NULL;
END//

/* sp_asignar_ubicacion_lote_ctx */
DROP PROCEDURE IF EXISTS sp_asignar_ubicacion_lote_ctx;
CREATE PROCEDURE sp_asignar_ubicacion_lote_ctx(
  IN p_id_lote INT,
  IN p_id_ubicacion INT,
  IN p_estante VARCHAR(20),
  IN p_nivel VARCHAR(20),
  IN p_pasillo VARCHAR(20),
  IN p_id_usuario INT
)
BEGIN
  SET @ctx_id_usuario = p_id_usuario;
  CALL sp_asignar_ubicacion_lote(
    p_id_lote, p_id_ubicacion, p_estante, p_nivel, p_pasillo, p_id_usuario
  );
  SET @ctx_id_usuario = NULL;
END//

/* sp_generar_alertas_diarias_ctx */
DROP PROCEDURE IF EXISTS sp_generar_alertas_diarias_ctx;
CREATE PROCEDURE sp_generar_alertas_diarias_ctx(IN p_id_usuario INT)
BEGIN
  SET @ctx_id_usuario = p_id_usuario;
  CALL sp_generar_alertas_diarias();
  SET @ctx_id_usuario = NULL;
END//

/* sp_generar_backup_ctx (ya existía en tu DDL; se incluye para estandarizar) */
DROP PROCEDURE IF EXISTS sp_generar_backup_ctx;
CREATE PROCEDURE sp_generar_backup_ctx(
  IN p_usuario INT,
  IN p_ruta TEXT,
  IN p_nombre_archivo VARCHAR(255),
  IN p_id_usuario INT
)
BEGIN
  SET @ctx_id_usuario = p_id_usuario;
  CALL sp_generar_backup(p_usuario, p_ruta, p_nombre_archivo);
  SET @ctx_id_usuario = NULL;
END//

/* sp_generar_token_recuperacion_ctx (ya existía; se redefine si hace falta para mantener formato) */
DROP PROCEDURE IF EXISTS sp_generar_token_recuperacion_ctx;
CREATE PROCEDURE sp_generar_token_recuperacion_ctx(
  IN p_id_usuario INT,
  IN p_token VARCHAR(255),
  IN p_id_admin INT
)
BEGIN
  SET @ctx_id_usuario = p_id_admin;
  CALL sp_generar_token_recuperacion(p_id_usuario, p_token);
  SET @ctx_id_usuario = NULL;
END//

DELIMITER ;
