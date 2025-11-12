/* ============================================================
   FARMAGESTIÓN - Script de PRUEBAS end-to-end por HU
   Requisitos previos: haber ejecutado farmagestion_DDL_v3.sql
   ============================================================ */
-- CALL sp_crear_ip("123.0.0.1", "PRUEBA", 1);
-- Asegurar uso del esquema
USE farmagestion;
SET sql_safe_updates = 0;
SELECT *
    FROM ips_permitidas
    ORDER BY fecha_registro DESC;
-- ============================================================
-- 0) Datos base: Usuarios, Ubicaciones, Ítems, Proveedores
-- ============================================================
SET GLOBAL wait_timeout = 600;
SET GLOBAL interactive_timeout = 600;

SELECT COUNT(*) FROM auditoria;
SELECT COUNT(*) FROM auditoria_punteros;

-- Usuarios (bcrypt simulado: sólo debe empezar por '$2')
CALL sp_crear_usuario('Admin TI',    'admin@hospital.test',   'ADMIN',    '$2b$dummy.hash.admin');
CALL sp_crear_usuario('Regente',     'regente@hospital.test', 'REGENTE',  '$2b$dummy.hash.reg');
CALL sp_crear_usuario('Auditor',     'auditor@hospital.test', 'AUDITOR',  '$2b$dummy.hash.aud');
CALL sp_crear_usuario('Auxiliar',    'aux@hospital.test',     'AUXILIAR', '$2b$dummy.hash.aux');
CALL sp_crear_usuario('ProveedorApp','prov@laboratorio.test', 'PROVEEDOR','$2b$dummy.hash.prov');

-- Guardar IDs de usuarios para referencia
SELECT id_usuario INTO @u_admin   FROM usuarios WHERE correo='admin@hospital.test';
SELECT id_usuario INTO @u_regente FROM usuarios WHERE correo='regente@hospital.test';
SELECT id_usuario INTO @u_auditor FROM usuarios WHERE correo='auditor@hospital.test';
SELECT id_usuario INTO @u_aux     FROM usuarios WHERE correo='aux@hospital.test';

-- Ubicaciones: 2 almacenes y 2 servicios
CALL sp_crear_ubicacion('ALMACEN CENTRAL',   'ALMACEN', 1);
CALL sp_crear_ubicacion('ALMACEN SECUNDARIO','ALMACEN', 1);
CALL sp_crear_ubicacion('SERVICIO URGENCIAS','SERVICIO',1);
CALL sp_crear_ubicacion('SERVICIO UCI',      'SERVICIO',1);

SELECT id_ubicacion INTO @alm_central   FROM ubicaciones WHERE nombre='ALMACEN CENTRAL';
SELECT id_ubicacion INTO @alm_secund    FROM ubicaciones WHERE nombre='ALMACEN SECUNDARIO';
SELECT id_ubicacion INTO @srv_urgencias FROM ubicaciones WHERE nombre='SERVICIO URGENCIAS';
SELECT id_ubicacion INTO @srv_uci       FROM ubicaciones WHERE nombre='SERVICIO UCI';

-- Proveedores
CALL sp_crear_proveedor('LAB ACME', '901000111');
CALL sp_crear_proveedor('LAB BETA', '901000222');

SELECT id_proveedor INTO @prov_acme FROM proveedores WHERE nit='901000111';
SELECT id_proveedor INTO @prov_beta FROM proveedores WHERE nit='901000222';

-- Ítems (stock mínimo para probar alertas de bajo/critico)
CALL sp_crear_item(@alm_central, 'PARA500', 'PARACETAMOL 500MG TAB', 'MEDICAMENTO', 'UND', 50);
CALL sp_crear_item(@alm_central, 'AMOX500', 'AMOXICILINA 500MG CAP', 'MEDICAMENTO', 'UND', 10);
CALL sp_crear_item(@alm_central, 'EPI1MG',  'EPINEFRINA 1MG/1ML',    'MEDICAMENTO', 'AMP', 20);

SELECT id_item INTO @it_paracetamol FROM items WHERE codigo='PARA500';
SELECT id_item INTO @it_amoxi       FROM items WHERE codigo='AMOX500';
SELECT id_item INTO @it_epi         FROM items WHERE codigo='EPI1MG';

-- ============================================================
-- HU-1 Entrada de lotes: registrar ingreso (crea lote si no existe)
-- ============================================================

-- Ingreso de PARACETAMOL lote P500-A1 al ALMACEN CENTRAL (100 und)
CALL sp_registrar_ingreso(
  @it_paracetamol, @prov_acme, 'P500-A1',
  DATE_ADD(CURDATE(), INTERVAL 200 DAY), 200.00,
  @alm_central, 100, @u_aux, 'Recepción de proveedor'
);

-- Verificar: stock y comprobante de recepción creado por trigger
SELECT * FROM v_existencias_detalle WHERE codigo_item='PARA500';
SELECT cr.* FROM comprobantes_recepcion cr
JOIN movimientos m ON m.id_movimiento=cr.id_movimiento
JOIN lotes l ON l.id_lote=m.id_lote AND l.codigo_lote='P500-A1';

-- Guardar IDs de lote y comprobante
SELECT id_lote INTO @lote_p500a1 FROM lotes WHERE id_item=@it_paracetamol AND codigo_lote='P500-A1';
SELECT cr.id_comprobante INTO @comp_p500a1
FROM comprobantes_recepcion cr
JOIN movimientos m ON m.id_movimiento=cr.id_movimiento
WHERE m.id_lote=@lote_p500a1;

-- ============================================================
-- HU-10 Confirmación de proveedor: marcar comprobante como entregado
-- ============================================================
CALL sp_actualizar_comprobante_recepcion(@comp_p500a1, 1, NOW());
SELECT * FROM comprobantes_recepcion WHERE id_comprobante=@comp_p500a1;

-- ============================================================
-- HU-2 Salida de lotes (a un SERVICIO), validando stock
-- ============================================================
-- Salida de 30 und a SERVICIO URGENCIAS
CALL sp_registrar_salida(@lote_p500a1, @alm_central, @srv_urgencias, 30, @u_aux, 'Dispensación a pacientes');
SELECT * FROM v_existencias_detalle WHERE codigo_item='PARA500' ORDER BY id_ubicacion;

-- ============================================================
-- HU-4 Transferencia de stock entre ubicaciones
-- ============================================================
-- Transferir 20 und del ALMACEN CENTRAL al ALMACEN SECUNDARIO
CALL sp_transferir_stock(@lote_p500a1, @alm_central, @alm_secund, 20, @u_aux, 'Reabastecimiento interno');
SELECT * FROM v_existencias_detalle WHERE codigo_item='PARA500' ORDER BY id_ubicacion;

-- ============================================================
-- HU-8 Ajustes de inventario (aumento/disminución, sin negativos)
-- ============================================================
-- Disminución de 5 und por rotura en ALMACEN SECUNDARIO
CALL sp_ajustar_stock(@lote_p500a1, @alm_secund, 5, 'DISMINUCION', @u_regente, 'Rotura');
-- Aumento de 10 und por regularización en ALMACEN CENTRAL
CALL sp_ajustar_stock(@lote_p500a1, @alm_central, 10, 'AUMENTO', @u_regente, 'Regularización inventario');
SELECT * FROM v_kardex_con_saldo WHERE id_lote=@lote_p500a1 ORDER BY fecha, id_movimiento;

-- ============================================================
-- HU-20 Registro de devoluciones (ajuste de entrada con motivo)
-- ============================================================
CALL sp_registrar_devolucion(@lote_p500a1, @alm_central, 5, @u_aux, 'Devolución de servicio');
SELECT * FROM v_kardex_con_saldo WHERE id_lote=@lote_p500a1 ORDER BY fecha, id_movimiento;

-- ============================================================
-- HU-29 Asignación de ubicación física (estante/nivel/pasillo) al lote
-- ============================================================
CALL sp_asignar_ubicacion_lote(@lote_p500a1, @alm_central, 'A', '2', 'P1', @u_aux);
SELECT * FROM v_ubicaciones_lote WHERE codigo_lote='P500-A1';

-- ============================================================
-- HU-21 Generación de etiquetas QR del lote (contenido debe incluir el código de lote)
-- ============================================================
CALL sp_registrar_etiqueta_qr(@lote_p500a1, CONCAT('QR|lote=', 'P500-A1', '|id=', @lote_p500a1));
SELECT * FROM v_etiquetas_lote WHERE codigo_lote='P500-A1';

-- ============================================================
-- HU-23 Control de calidad del lote
-- ============================================================
CALL sp_registrar_control_calidad(@lote_p500a1, 'Inspección visual OK', 'APROBADO', 'foto_base64', @u_auditor);
SELECT * FROM control_calidad WHERE id_lote=@lote_p500a1;

-- ============================================================
-- HU-3 / HU-18 Alertas por stock bajo y crítico
-- ============================================================
-- EPI1MG quedó sin ingresos: debe aparecer en stock bajo (mín=20) y crítico (=0)
SELECT * FROM v_alertas_stock_bajo   WHERE codigo_item IN ('PARA500','EPI1MG');
SELECT * FROM v_alertas_stock_critico WHERE codigo_item IN ('EPI1MG');

-- Generar notificaciones automáticas de alertas (bajo, crítico y vencimiento)
CALL sp_generar_alertas_diarias();
SELECT * FROM notificaciones ORDER BY fecha_creacion DESC LIMIT 10;

-- HU-28 Confirmación de recepción de alertas (marcar una como REVISADA)
SELECT id_notificacion INTO @notif_crit
FROM notificaciones WHERE tipo='ALERTA_STOCK_CRITICO' ORDER BY id_notificacion DESC LIMIT 1;
CALL sp_confirmar_alerta(@notif_crit, @u_regente);
SELECT * FROM v_confirmaciones_alertas WHERE id_notificacion=@notif_crit;

-- ============================================================
-- HU-9 Alertas de vencimiento (lote con vencimiento <= 30 días)
-- ============================================================
-- Crear ingreso de AMOXICILINA con vencimiento en 10 días para generar alerta
CALL sp_registrar_ingreso(
  @it_amoxi, @prov_beta, 'AMO-EXP10',
  DATE_ADD(CURDATE(), INTERVAL 10 DAY), 350.00,
  @alm_central, 40, @u_aux, 'Recepción cercana a vencimiento'
);
CALL sp_generar_alertas_diarias(); -- generará ALERTA_VENCIMIENTO
SELECT * FROM notificaciones WHERE tipo='ALERTA_VENCIMIENTO' ORDER BY id_notificacion DESC;

-- ============================================================
-- HU-5 / HU-7 Reportes Kardex y trazabilidad por lote
-- ============================================================
SELECT * FROM v_kardex_detalle WHERE id_lote=@lote_p500a1 ORDER BY fecha, id_movimiento;
SELECT * FROM v_kardex_fisico  WHERE id_lote=@lote_p500a1 ORDER BY fecha, id_movimiento;

-- ============================================================
-- HU-11 Monitoreo de sesiones activas
-- ============================================================
-- Crear una sesión activa para Admin y listarla, luego cerrarla
CALL sp_registrar_sesion(@u_admin, '10.0.0.5', 'Pruebas-UA');
CALL sp_listar_sesiones_activas();
-- Obtener la última sesión del admin y cerrarla
SELECT id_sesion INTO @ses_admin FROM sesiones_activas WHERE id_usuario=@u_admin AND activo=1 ORDER BY hora_inicio DESC LIMIT 1;
CALL sp_cerrar_sesion(@ses_admin);
CALL sp_listar_sesiones_activas();

-- ============================================================
-- HU-12 Copia de seguridad automática (registro y notificación)
-- ============================================================
CALL sp_generar_backup(@u_admin, '/var/backups', CONCAT('farmagestion_', DATE_FORMAT(NOW(),'%Y%m%d_%H%i%s'), '.sql'));
SELECT * FROM backups ORDER BY fecha_creacion DESC LIMIT 1;
SELECT * FROM notificaciones WHERE tipo='BACKUP' ORDER BY id_notificacion DESC LIMIT 1;

-- ============================================================
-- HU-13 Recuperación de contraseña (token, validación, cambio)
-- ============================================================
CALL sp_generar_token_recuperacion(@u_aux, 'token_test_123');
CALL sp_validar_token_recuperacion('token_test_123');
CALL sp_cambiar_contrasena('token_test_123', '$2b$nueva.hash.bcrypt');
SELECT * FROM tokens_recuperacion WHERE id_usuario=@u_aux ORDER BY id_token DESC LIMIT 1;

-- ============================================================
-- HU-14 Dashboards por rol
-- ============================================================
SELECT * FROM v_dashboard_auxiliar;
SELECT * FROM v_dashboard_regente;
SELECT * FROM v_dashboard_auditor;
SELECT * FROM v_dashboard_proveedor;

-- ============================================================
-- HU-15 Auditoría de acciones de usuario
-- ============================================================
SELECT * FROM v_resumen_auditoria ORDER BY tabla_afectada;
-- (Ejemplo filtrado por usuario)
SELECT * FROM v_auditoria_por_usuario WHERE id_usuario=@u_aux ORDER BY fecha DESC LIMIT 20;

-- ============================================================
-- HU-16 Reporte de consumo por servicio (salidas)
-- ============================================================
CALL sp_reporte_consumo_servicio(@it_paracetamol, DATE_SUB(NOW(), INTERVAL 30 DAY), NOW());

-- ============================================================
-- HU-17 Control de acceso por IP
-- ============================================================
CALL sp_crear_ip('10.0.0.5', 'IP del Admin en pruebas', @u_admin);
CALL sp_validar_ip('10.0.0.5', @u_admin);

CALL sp_crear_ip('10.0.0.5', 'IP del Admin en pruebas 2', @u_admin);
CALL sp_validar_ip('10.0.0.5', @u_admin);

CALL sp_crear_ip('10.0.0.4', 'IP del Admin en pruebas', @u_admin);
CALL sp_validar_ip('10.0.0.5', @u_admin);
-- Escenario de denegación (opcional: provocaría ERROR y detendría el script)
CALL sp_validar_ip('192.0.2.1', @u_admin);

-- ============================================================
-- HU-22 Reporte de lotes vencidos
-- ============================================================
-- Por diseño, crear/actualizar lotes con fecha pasada está prohibido vía SP y trigger BU.
-- La vista debe listar lotes con fecha < hoy si existieran (ejecución informativa):
SELECT * FROM v_lotes_vencidos;

-- ============================================================
-- HU-24 Proveedores activos/inactivos + reporte
-- ============================================================
-- Desactivar proveedor BETA y listar por estado/fechas
CALL sp_actualizar_estado_proveedor(@prov_beta, 0, @u_admin);
CALL sp_listar_proveedores_estado(0, DATE_SUB(CURDATE(), INTERVAL 365 DAY), CURDATE());
SELECT * FROM v_proveedores_estado ORDER BY fecha_registro DESC;

-- ============================================================
-- HU-25 Historial de notificaciones (filtros básicos)
-- ============================================================
CALL sp_listar_historial_notificaciones(NULL, NULL, DATE_SUB(CURDATE(), INTERVAL 7 DAY), CURDATE());

-- ============================================================
-- HU-26 Incidentes de almacenamiento (registro + listado)
-- ============================================================
CALL sp_registrar_incidente('Derrame menor zona A', 'Auxiliar', 'Limpieza y reposición', 'foto_base64', @u_aux);
CALL sp_listar_incidentes();

-- ============================================================
-- HU-27 Control de usuarios inactivos (>60 días)
-- ============================================================
-- Como los usuarios nuevos tienen fecha_ultimo_login NULL, serán marcados como bloqueados por 365 días
CALL sp_desactivar_usuarios_inactivos(@u_admin);
SELECT * FROM v_usuarios_inactivos;

-- ============================================================
-- Integridad y consistencia: recalcular existencias desde movimientos
-- (útil para pruebas de coherencia)
-- ============================================================
CALL sp_recalcular_existencias();
SELECT * FROM v_existencias_detalle ORDER BY codigo_item, id_ubicacion;

/* ============================================================
   OPCIONAL (sólo testing HU-22): simular un lote ya vencido
   Nota: usa INSERT directo porque los SP y triggers BU impiden
   fechas pasadas. Descomentar para ver la vista con datos.

-- INSERT INTO lotes(id_item,id_proveedor,codigo_lote,fecha_vencimiento,costo_unitario)
-- VALUES (@it_amoxi, @prov_beta, 'AMO-VENCIDO', DATE_SUB(CURDATE(), INTERVAL 5 DAY), 300.00);
-- SELECT * FROM v_lotes_vencidos WHERE codigo_item='AMOX500';
============================================================ */