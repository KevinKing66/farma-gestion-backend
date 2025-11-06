-- ================================================================
-- PLAYBOOK SQL MAESTRO - FarmaGestion (Datos semilla + Casos HU)
-- Nota: Ejecutar en MySQL 8.x. Activa el event scheduler cuando aplique:
--   SET GLOBAL event_scheduler = ON;

-- Recomendación: usar un esquema de pruebas aislado.

-- ================================================================
-- SECCIÓN PREPARACIÓN: Usuarios, Ubicaciones, Proveedor, Ítem, Ingreso inicial
-- ================================================================

-- Usuarios (contraseñas deben ser hashes bcrypt válidos que empiecen por '$2')
INSERT INTO usuarios(nombre_completo, correo, rol, contrasena) VALUES
  ('Auxiliar Uno','aux1@demo','AUXILIAR','$2dummy_bcrypt_aux1'),
  ('Regente Uno','reg1@demo','REGENTE','$2dummy_bcrypt_reg1'),
  ('Auditor Uno','aud1@demo','AUDITOR','$2dummy_bcrypt_aud1'),
  ('Admin Uno','adm1@demo','ADMIN','$2dummy_bcrypt_admin'),
  ('Proveedor-Usuario','prov1@demo','PROVEEDOR','$2dummy_bcrypt_prov1');

-- Ubicaciones: 1 almacén + 2 servicios
CALL sp_crear_ubicacion('ALM_GENERAL','ALMACEN',1);
CALL sp_crear_ubicacion('SERVICIO_URGENCIAS','SERVICIO',1);
CALL sp_crear_ubicacion('SERVICIO_PISO2','SERVICIO',1);

-- Proveedor
CALL sp_crear_proveedor('ACME FARMA S.A.S.','900123456-7');

-- Ítem base (stock mínimo 100)
CALL sp_crear_item((SELECT id_ubicacion FROM ubicaciones WHERE nombre='ALM_GENERAL'),
  'AMOX500','AMOXICILINA 500MG CAPS','MEDICAMENTO','UND',100);

-- ================================================================
-- SECCIÓN HU-1: Entrada de lotes (ingreso y validaciones)
-- ================================================================
-- Happy path: crea lote y movimiento INGRESO + comprobante de recepción
CALL sp_registrar_ingreso((SELECT id_item FROM items WHERE codigo='AMOX500'),
  (SELECT id_proveedor FROM proveedores LIMIT 1), 'L-AX500-A',
  DATE_ADD(CURDATE(), INTERVAL 180 DAY), 120.00,
  (SELECT id_ubicacion FROM ubicaciones WHERE nombre='ALM_GENERAL'), 500,
  (SELECT id_usuario FROM usuarios WHERE correo='aux1@demo'), 'Recepción inicial');

-- Caso negativo: fecha vencida (debe fallar por trigger)
-- CALL sp_registrar_ingreso((SELECT id_item FROM items WHERE codigo='AMOX500'),
--  (SELECT id_proveedor FROM proveedores LIMIT 1), 'L-AX500-X',
--  DATE_SUB(CURDATE(), INTERVAL 1 DAY), 100.00,
--  (SELECT id_ubicacion FROM ubicaciones WHERE nombre='ALM_GENERAL'), 10,
--  (SELECT id_usuario FROM usuarios WHERE correo='aux1@demo'), 'Prueba error');

-- ================================================================
-- SECCIÓN HU-2: Salida de lotes (a servicio, valida stock/motivo)
-- ================================================================
SET @id_lote := (SELECT id_lote FROM lotes WHERE codigo_lote='L-AX500-A');
CALL sp_registrar_salida(@id_lote,
  (SELECT id_ubicacion FROM ubicaciones WHERE nombre='ALM_GENERAL'),
  (SELECT id_ubicacion FROM ubicaciones WHERE nombre='SERVICIO_URGENCIAS'),
  120, (SELECT id_usuario FROM usuarios WHERE correo='aux1@demo'), 'Dispensación urgencias');

-- Caso negativo: stock insuficiente (debe fallar)
-- CALL sp_registrar_salida(@id_lote, (SELECT id_ubicacion FROM ubicaciones WHERE nombre='ALM_GENERAL'),
--  (SELECT id_ubicacion FROM ubicaciones WHERE nombre='SERVICIO_URGENCIAS'), 999999, (SELECT id_usuario FROM usuarios WHERE correo='aux1@demo'), 'Exceso');

-- ================================================================
-- SECCIÓN HU-4: Transferencia de stock
-- ================================================================
CALL sp_transferir_stock(@id_lote,
  (SELECT id_ubicacion FROM ubicaciones WHERE nombre='ALM_GENERAL'),
  (SELECT id_ubicacion FROM ubicaciones WHERE nombre='SERVICIO_PISO2'),
  50, (SELECT id_usuario FROM usuarios WHERE correo='aux1@demo'), 'Reposición piso 2');

-- ================================================================
-- SECCIÓN HU-5: Kardex (consulta)
-- ================================================================
SELECT * FROM v_kardex_detalle WHERE codigo_lote='L-AX500-A' ORDER BY fecha, id_movimiento;

-- ================================================================
-- SECCIÓN HU-3 y HU-18: Alertas stock bajo y crítico
-- ================================================================
-- Consumir para quedar <= stock mínimo (100)
CALL sp_registrar_salida(@id_lote, (SELECT id_ubicacion FROM ubicaciones WHERE nombre='ALM_GENERAL'),
  (SELECT id_ubicacion FROM ubicaciones WHERE nombre='SERVICIO_URGENCIAS'), 320, (SELECT id_usuario FROM usuarios WHERE correo='aux1@demo'), 'Consumo masivo');
SELECT * FROM v_alertas_stock_bajo; -- Debe listar el ítem si stock_total <= stock_minimo

-- Consumir hasta 0 para crítico (si tienes la vista v_alertas_stock_critico)
-- (Repite salidas según saldo restante y luego:) SELECT * FROM v_alertas_stock_critico;

-- ================================================================
-- SECCIÓN HU-8: Ajustes de inventario
-- ================================================================
-- Aumento 10 en ALM_GENERAL
CALL sp_ajustar_stock(@id_lote, (SELECT id_ubicacion FROM ubicaciones WHERE nombre='ALM_GENERAL'), 10, 'AUMENTO', (SELECT id_usuario FROM usuarios WHERE correo='reg1@demo'), 'Corrección conteo');
-- Disminución 5 si hay saldo
CALL sp_ajustar_stock(@id_lote, (SELECT id_ubicacion FROM ubicaciones WHERE nombre='ALM_GENERAL'), 5, 'DISMINUCION', (SELECT id_usuario FROM usuarios WHERE correo='reg1@demo'), 'Daño en empaque');

-- ================================================================
-- SECCIÓN HU-9: Alertas por vencimiento + job diario
-- ================================================================
INSERT INTO parametros_sistema(clave,valor,descripcion) VALUES ('dias_alerta_venc','30','Días para alerta')
ON DUPLICATE KEY UPDATE valor='30';
CALL sp_registrar_ingreso((SELECT id_item FROM items WHERE codigo='AMOX500'), 
	(SELECT id_proveedor FROM proveedores LIMIT 1), 'L-AX500-VENC', DATE_ADD(CURDATE(), INTERVAL 15 DAY), 115.00, 
    (SELECT id_ubicacion FROM ubicaciones WHERE nombre='ALM_GENERAL'), 20, 
    (SELECT id_usuario FROM usuarios WHERE correo='aux1@demo'), 'Lote por vencer');
CALL sp_generar_alertas_diarias();
SELECT * FROM notificaciones WHERE tipo IN ('ALERTA_VENCIMIENTO','ALERTA_STOCK_BAJO','ALERTA_STOCK_CRITICO') ORDER BY id_notificacion DESC;

-- ================================================================
-- SECCIÓN HU-10: Confirmación proveedor (comprobantes)
-- ================================================================
SELECT cr.* FROM comprobantes_recepcion cr JOIN movimientos m ON m.id_movimiento=cr.id_movimiento ORDER BY cr.id_comprobante DESC LIMIT 1;
CALL sp_actualizar_comprobante_recepcion((SELECT MAX(id_comprobante) FROM comprobantes_recepcion), 1, NOW());

-- ================================================================
-- SECCIÓN HU-11: Sesiones activas
-- ================================================================
CALL sp_registrar_sesion((SELECT id_usuario FROM usuarios WHERE correo='adm1@demo'),'10.0.0.99','Chrome');
CALL sp_listar_sesiones_activas();
CALL sp_cerrar_sesion((SELECT MAX(id_sesion) FROM sesiones_activas WHERE id_usuario=(SELECT id_usuario FROM usuarios WHERE correo='adm1@demo')));

-- ================================================================
-- SECCIÓN HU-12: Copia de seguridad (registro)
-- ================================================================
SET GLOBAL event_scheduler = ON;
CALL sp_generar_backup((SELECT id_usuario FROM usuarios WHERE correo='adm1@demo'), '/var/backups', CONCAT('farmagestion_', DATE_FORMAT(NOW(),'%Y%m%d_%H%i%s'), '.sql'));
SELECT * FROM backups ORDER BY id_backup DESC;

-- ================================================================
-- SECCIÓN HU-13: Recuperación de contraseña (tokens)
-- ================================================================
CALL sp_generar_token_recuperacion((SELECT id_usuario FROM usuarios WHERE correo='aux1@demo'),'token_demo_123');
CALL sp_validar_token_recuperacion('token_demo_123');
CALL sp_cambiar_contrasena('token_demo_123','$2nuevo_hash_bcrypt'); -- marca el token como usado

-- ================================================================
-- SECCIÓN HU-14: Dashboards por rol
-- ================================================================
SELECT * FROM v_dashboard_auxiliar;
SELECT * FROM v_dashboard_regente;
SELECT * FROM v_dashboard_auditor;
SELECT * FROM v_dashboard_proveedor;

-- ================================================================
-- SECCIÓN HU-15: Auditoría (consulta)
-- ================================================================
SELECT * FROM v_auditoria_por_usuario ORDER BY fecha DESC LIMIT 50;

-- ================================================================
-- SECCIÓN HU-16: Consumo por servicio
-- ================================================================
CALL sp_reporte_consumo_servicio((SELECT id_item FROM items WHERE codigo='AMOX500'), DATE_SUB(NOW(), INTERVAL 30 DAY), NOW());
SELECT * FROM v_consumos_por_servicio WHERE codigo='AMOX500';

-- ================================================================
-- SECCIÓN HU-17: Control de acceso por IP
-- ================================================================
CALL sp_crear_ip('10.0.0.10','Oficina TI',1);
CALL sp_validar_ip('10.0.0.10',(SELECT id_usuario FROM usuarios WHERE correo='adm1@demo')); -- OK
-- Denegada (debe fallar y registrar auditoría DENEGADO)
-- CALL sp_validar_ip('203.0.113.77',(SELECT id_usuario FROM usuarios WHERE correo='adm1@demo'));

-- ================================================================
-- SECCIÓN HU-20: Devoluciones (AJUSTE positivo)
-- ================================================================
CALL sp_registrar_devolucion(@id_lote, (SELECT id_ubicacion FROM ubicaciones WHERE nombre='ALM_GENERAL'), 10, 
										(SELECT id_usuario FROM usuarios WHERE correo='aux1@demo'), 'Paciente no usó medicamento');

-- ================================================================
-- SECCIÓN HU-21: Etiquetas QR
-- ================================================================
SET @cod := (SELECT codigo_lote FROM lotes WHERE id_lote=@id_lote);
CALL sp_registrar_etiqueta_qr(@id_lote, CONCAT('QR: lote=', @cod, '; item=AMOX500'));
-- Caso negativo: contenido sin código de lote (debe fallar)
-- CALL sp_registrar_etiqueta_qr(@id_lote, 'QR sin código');

-- ================================================================
-- SECCIÓN HU-22: Lotes vencidos (reporte)
-- ================================================================
CALL sp_registrar_ingreso((SELECT id_item FROM items WHERE codigo='AMOX500'), 
	(SELECT id_proveedor FROM proveedores LIMIT 1), 'L-AX500-OLD',CURDATE(), 110.00, 
    (SELECT id_ubicacion FROM ubicaciones WHERE nombre='ALM_GENERAL'), 5, 
    (SELECT id_usuario FROM usuarios WHERE correo='aux1@demo'), 'Lote ya vencido para prueba');
SELECT * FROM v_lotes_vencidos ORDER BY fecha_vencimiento;

-- ================================================================
-- SECCIÓN HU-23: Control de calidad por lote
-- ================================================================
CALL sp_registrar_control_calidad(@id_lote, 'Inspección visual OK','APROBADO','foto://path/img1.jpg', (SELECT id_usuario FROM usuarios WHERE correo='aud1@demo'));

-- ================================================================
-- SECCIÓN HU-24: Proveedores activos/inactivos
-- ================================================================
CALL sp_listar_proveedores_estado(1, DATE_SUB(CURDATE(), INTERVAL 365 DAY), CURDATE());
CALL sp_actualizar_estado_proveedor((SELECT id_proveedor FROM proveedores LIMIT 1), 0, (SELECT id_usuario FROM usuarios WHERE correo='adm1@demo'));


-- ================================================================
-- SECCIÓN HU-25: Historial de notificaciones
-- ================================================================
CALL sp_generar_alertas_diarias();
CALL sp_listar_historial_notificaciones(NULL,NULL, DATE_SUB(CURDATE(), INTERVAL 30 DAY), CURDATE());
SELECT * FROM v_historial_notificaciones ORDER BY fecha_creacion DESC;

-- ================================================================
-- SECCIÓN HU-26: Incidentes de almacenamiento
-- ================================================================
CALL sp_registrar_incidente('Derrame leve en estante A','Auxiliar Uno','Limpieza y reposición','foto://derr1.jpg', (SELECT id_usuario FROM usuarios WHERE correo='aux1@demo'));

-- ================================================================
-- SECCIÓN HU-27: Usuarios inactivos (>60 días)
-- ================================================================
UPDATE usuarios SET fecha_ultimo_login = DATE_SUB(CURDATE(), INTERVAL 61 DAY) WHERE correo='reg1@demo';
CALL sp_desactivar_usuarios_inactivos((SELECT id_usuario FROM usuarios WHERE correo='adm1@demo'));
SELECT nombre_completo, bloqueado_hasta FROM usuarios WHERE correo='reg1@demo';
SELECT * FROM v_usuarios_inactivos;

-- ================================================================
-- SECCIÓN HU-28: Confirmación de recepción de alertas
-- ================================================================
SET @id_notif := (SELECT id_notificacion FROM notificaciones ORDER BY id_notificacion DESC LIMIT 1);
CALL sp_confirmar_alerta(@id_notif, (SELECT id_usuario FROM usuarios WHERE correo='reg1@demo'));
-- Intento de reversa (debe fallar por trigger)
-- UPDATE notificaciones SET estado_confirmacion='PENDIENTE' WHERE id_notificacion=@id_notif;

-- ================================================================
-- SECCIÓN HU-29: Posiciones físicas de lote (estante/nivel/pasillo)
-- ================================================================
SET @ctx_id_usuario := (SELECT id_usuario FROM usuarios WHERE correo='aux1@demo');
CALL sp_asignar_ubicacion_lote(@id_lote, (SELECT id_ubicacion FROM ubicaciones WHERE nombre='ALM_GENERAL'), 'A','1','01', @ctx_id_usuario);
-- Intento de duplicado (debe fallar por UX)
-- CALL sp_asignar_ubicacion_lote(@id_lote, (SELECT id_ubicacion FROM ubicaciones WHERE nombre='ALM_GENERAL'), 'A','1','01', @ctx_id_usuario);

-- ================================================================
-- SECCIÓN TRANSVERSAL: Inmutabilidad & Recalcular existencias
-- ================================================================
-- Deben fallar por triggers de protección:
-- UPDATE movimientos SET motivo='hack' WHERE id_movimiento=(SELECT MAX(id_movimiento) FROM movimientos);
-- DELETE FROM movimientos WHERE id_movimiento=(SELECT MAX(id_movimiento) FROM movimientos);
-- UPDATE auditoria SET accion='UPDATE' WHERE id_evento=(SELECT MAX(id_evento) FROM auditoria);
-- DELETE FROM auditoria WHERE id_evento=(SELECT MAX(id_evento) FROM auditoria);

-- Recalcular existencias desde movimientos
CALL sp_recalcular_existencias();
SELECT i.codigo, SUM(e.saldo) AS stock_total FROM existencias e JOIN lotes l ON l.id_lote=e.id_lote JOIN items i ON i.id_item=l.id_item GROUP BY i.codigo;
