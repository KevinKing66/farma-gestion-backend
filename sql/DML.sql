INSERT INTO proveedores (id_proveedor, nombre, nit, telefono, direccion, correo) VALUES
(1, 'Laboratorios Genfar', '900123456-7', '6012345678', 'Calle 45 #12-34, Bogotá', 'contacto@genfar.com'),
(2, 'Pfizer Colombia', '800987654-3', '6018765432', 'Av. El Dorado #68C-61, Bogotá', 'info@pfizer.com.co'),
(3, 'Laboratorios La Santé', '900456789-1', '6023456789', 'Cra 15 #93-60, Bogotá', 'ventas@lasante.com'),
(4, 'Tecnoquímicas S.A.', '890123456-0', '6029876543', 'Calle 10 #25-30, Cali', 'clientes@tecnoquimicas.com'),
(5, 'Bayer S.A.', '890987654-2', '6013456789', 'Cra 7 #71-21, Bogotá', 'servicio@bayer.com.co'),
(6, 'Novartis Colombia', '900789123-4', '6012349876', 'Calle 100 #19-54, Bogotá', 'atencion@novartis.com'),
(7, 'Sanofi Aventis', '900321654-5', '6015678901', 'Cra 11 #82-01, Bogotá', 'contacto@sanofi.com'),
(8, 'Laboratorios MK', '890654321-8', '6026789012', 'Cra 50 #25-45, Cali', 'ventas@mk.com.co'),
(9, 'Abbott Laboratories', '900987321-6', '6017890123', 'Calle 26 #92-32, Bogotá', 'info@abbott.com.co'),
(10, 'Roche Colombia', '900654987-9', '6018901234', 'Cra 9 #115-30, Bogotá', 'clientes@roche.com.co');


INSERT INTO ubicaciones (id_ubicacion, nombre, tipo, activo) VALUES
(1, 'Almacén Principal', 'ALMACEN', 1),
(2, 'Farmacia Hospitalaria', 'SERVICIO', 1),
(3, 'Urgencias', 'SERVICIO', 1),
(4, 'UCI Adultos', 'SERVICIO', 1),
(5, 'UCI Pediátrica', 'SERVICIO', 1),
(6, 'Consulta Externa', 'SERVICIO', 1),
(7, 'Quirófanos', 'SERVICIO', 1),
(8, 'Hospitalización Piso 1', 'SERVICIO', 1),
(9, 'Hospitalización Piso 2', 'SERVICIO', 1),
(10, 'Almacén Secundario', 'ALMACEN', 1);

INSERT INTO usuarios (id_usuario, nombre_completo, correo, rol, contrasena, intentos_fallidos, bloqueado_hasta, fecha_ultimo_login, activo) VALUES
(1, 'Juan Pérez', 'juan.perez@hospital.com', 'ADMIN', '$2a$10$abcdefghijklmnopqrstuv', 0, NULL, NULL, 1),
(2, 'María Gómez', 'maria.gomez@hospital.com', 'REGENTE', '$2a$10$abcdefghijklmnopqrstuv', 0, NULL, NULL, 1),
(3, 'Carlos Ruiz', 'carlos.ruiz@hospital.com', 'AUXILIAR', '$2a$10$abcdefghijklmnopqrstuv', 0, NULL, NULL, 1),
(4, 'Ana Torres', 'ana.torres@hospital.com', 'AUDITOR', '$2a$10$abcdefghijklmnopqrstuv', 0, NULL, NULL, 1),
(5, 'Luis Herrera', 'luis.herrera@hospital.com', 'PROVEEDOR', '$2a$10$abcdefghijklmnopqrstuv', 0, NULL, NULL, 1),
(6, 'Sofía Martínez', 'sofia.martinez@hospital.com', 'AUXILIAR', '$2a$10$abcdefghijklmnopqrstuv', 0, NULL, NULL, 1),
(7, 'Pedro López', 'pedro.lopez@hospital.com', 'REGENTE', '$2a$10$abcdefghijklmnopqrstuv', 0, NULL, NULL, 1),
(8, 'Laura Castro', 'laura.castro@hospital.com', 'AUDITOR', '$2a$10$abcdefghijklmnopqrstuv', 0, NULL, NULL, 1),
(9, 'Andrés Silva', 'andres.silva@hospital.com', 'PROVEEDOR', '$2a$10$abcdefghijklmnopqrstuv', 0, NULL, NULL, 1),
(10, 'Camila Rojas', 'camila.rojas@hospital.com', 'ADMIN', '$2a$10$abcdefghijklmnopqrstuv', 0, NULL, NULL, 1);


INSERT INTO items (id_item, id_ubicacion, codigo, descripcion, tipo_item, unidad_medida, stock_minimo, uso_frecuente) VALUES
(1, 1, 'MED001', 'Paracetamol 500mg', 'MEDICAMENTO', 'UND', 100, 1),
(2, 1, 'MED002', 'Ibuprofeno 400mg', 'MEDICAMENTO', 'UND', 80, 1),
(3, 2, 'MED003', 'Amoxicilina 500mg', 'MEDICAMENTO', 'UND', 50, 1),
(4, 2, 'MED004', 'Omeprazol 20mg', 'MEDICAMENTO', 'UND', 40, 0),
(5, 3, 'MED005', 'Lidocaína 2%', 'MEDICAMENTO', 'UND', 30, 0),
(6, 4, 'MED006', 'Adrenalina 1mg/ml', 'MEDICAMENTO', 'UND', 20, 1),
(7, 5, 'MED007', 'Salbutamol Inhalador', 'MEDICAMENTO', 'UND', 25, 1),
(8, 6, 'DIS001', 'Jeringa 5ml', 'DISPOSITIVO', 'UND', 200, 1),
(9, 7, 'DIS002', 'Guantes de látex Talla M', 'DISPOSITIVO', 'UND', 150, 1),
(10, 10, 'DIS003', 'Mascarilla N95', 'DISPOSITIVO', 'UND', 100, 1);


INSERT INTO lotes (id_lote, id_item, id_proveedor, codigo_lote, fecha_vencimiento, costo_unitario, estado) VALUES
(1, 1, 1, 'L001-PARACET', '2026-01-15', 120.00, 'ACTIVO'),
(2, 2, 2, 'L002-IBUPROF', '2025-12-10', 150.00, 'ACTIVO'),
(3, 3, 3, 'L003-AMOX', '2025-11-30', 200.00, 'ACTIVO'),
(4, 4, 4, 'L004-OMEP', '2026-03-20', 180.00, 'ACTIVO'),
(5, 5, 5, 'L005-LIDO', '2025-12-05', 250.00, 'ACTIVO'),
(6, 6, 6, 'L006-ADREN', '2025-11-20', 300.00, 'ACTIVO'),
(7, 7, 7, 'L007-SALBU', '2026-02-15', 350.00, 'ACTIVO'),
(8, 8, 8, 'L008-JER', '2027-01-01', 50.00, 'ACTIVO'),
(9, 9, 9, 'L009-GUANT', '2026-06-10', 30.00, 'ACTIVO'),
(10, 10, 10, 'L010-MASK', '2025-12-25', 80.00, 'ACTIVO');


INSERT INTO lotes_posiciones (id_posicion, id_lote, id_ubicacion, estante, nivel, pasillo, asignado_por) VALUES
(1, 1, 1, 'A', '1', 'P1', 1),
(2, 2, 1, 'A', '2', 'P1', 2),
(3, 3, 1, 'B', '1', 'P2', 3),
(4, 4, 1, 'B', '2', 'P2', 4),
(5, 5, 1, 'C', '1', 'P3', 5),
(6, 6, 10, 'A', '1', 'P1', 6),
(7, 7, 10, 'A', '2', 'P1', 7),
(8, 8, 10, 'B', '1', 'P2', 8),
(9, 9, 10, 'B', '2', 'P2', 9),
(10, 10, 10, 'C', '1', 'P3', 10);

INSERT INTO movimientos (id_lote, id_usuario, tipo, cantidad, id_ubicacion_destino, motivo)
VALUES
(1, 1, 'INGRESO', 120, 1, 'Carga inicial de Paracetamol'),
(2, 1, 'INGRESO', 50, 1, 'Carga inicial de Ibuprofeno'),
(3, 1, 'INGRESO', 20, 2, 'Carga inicial de Amoxicilina'),
(4, 1, 'INGRESO', 40, 2, 'Carga inicial de Omeprazol'),
(5, 1, 'INGRESO', 10, 3, 'Carga inicial de Lidocaína'),
(6, 1, 'INGRESO', 5, 4, 'Carga inicial de Adrenalina'),
(7, 1, 'INGRESO', 25, 5, 'Carga inicial de Salbutamol'),
(8, 1, 'INGRESO', 200, 10, 'Carga inicial de Jeringas'),
(9, 1, 'INGRESO', 150, 7, 'Carga inicial de Guantes'),
(10, 1, 'INGRESO', 80, 6, 'Carga inicial de medicamento adicional');

INSERT INTO sesiones_activas (id_usuario, ip, user_agent, hora_inicio, activo, hora_cierre) VALUES
(1, '192.168.1.10', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)', '2025-11-11 08:15:00', 1, NULL),
(2, '192.168.1.11', 'Mozilla/5.0 (Linux; Android 11)', '2025-11-11 08:30:00', 1, NULL),
(3, '192.168.1.12', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)', '2025-11-11 09:00:00', 0, '2025-11-11 10:00:00'),
(4, '192.168.1.13', 'Mozilla/5.0 (Windows NT 6.1; WOW64)', '2025-11-11 09:15:00', 1, NULL),
(5, '192.168.1.14', 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X)', '2025-11-11 09:30:00', 0, '2025-11-11 09:50:00'),
(6, '192.168.1.15', 'Mozilla/5.0 (Linux; Ubuntu 20.04)', '2025-11-11 09:45:00', 1, NULL),
(7, '192.168.1.16', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)', '2025-11-11 10:00:00', 1, NULL),
(8, '192.168.1.17', 'Mozilla/5.0 (Linux; Android 12)', '2025-11-11 10:15:00', 0, '2025-11-11 11:00:00'),
(9, '192.168.1.18', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 11_2_3)', '2025-11-11 10:30:00', 1, NULL),
(10, '192.168.1.19', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)', '2025-11-11 10:45:00', 0, '2025-11-11 11:15:00');

INSERT INTO etiquetas_qr (id_lote, fecha_generacion, contenido_qr) VALUES
(1, '2025-11-11 08:00:00', 'QR: Lote 1 - Paracetamol - Vence 12/2026'),
(2, '2025-11-11 08:05:00', 'QR: Lote 2 - Ibuprofeno - Vence 10/2026'),
(3, '2025-11-11 08:10:00', 'QR: Lote 3 - Amoxicilina - Vence 09/2026'),
(4, '2025-11-11 08:15:00', 'QR: Lote 4 - Omeprazol - Vence 08/2026'),
(5, '2025-11-11 08:20:00', 'QR: Lote 5 - Lidocaína - Vence 07/2026'),
(6, '2025-11-11 08:25:00', 'QR: Lote 6 - Adrenalina - Vence 06/2026'),
(7, '2025-11-11 08:30:00', 'QR: Lote 7 - Salbutamol - Vence 05/2026'),
(8, '2025-11-11 08:35:00', 'QR: Lote 8 - Jeringas - Vence 12/2027'),
(9, '2025-11-11 08:40:00', 'QR: Lote 9 - Guantes - Vence 11/2027'),
(10, '2025-11-11 08:45:00', 'QR: Lote 10 - Alcohol - Vence 10/2027');

INSERT INTO comprobantes_recepcion (id_movimiento, id_proveedor, canal, entregado, fecha_creacion, fecha_entrega) VALUES
(1, 1, 'PORTAL', 1, '2025-11-11 08:00:00', '2025-11-11 09:00:00'),
(2, 2, 'EMAIL', 0, '2025-11-11 08:10:00', NULL),
(3, 3, 'PORTAL', 1, '2025-11-11 08:20:00', '2025-11-11 09:30:00'),
(4, 4, 'EMAIL', 1, '2025-11-11 08:30:00', '2025-11-11 10:00:00'),
(5, 5, 'PORTAL', 0, '2025-11-11 08:40:00', NULL),
(6, 6, 'EMAIL', 1, '2025-11-11 08:50:00', '2025-11-11 09:50:00'),
(7, 7, 'PORTAL', 1, '2025-11-11 09:00:00', '2025-11-11 10:15:00'),
(8, 8, 'EMAIL', 0, '2025-11-11 09:10:00', NULL),
(9, 9, 'PORTAL', 1, '2025-11-11 09:20:00', '2025-11-11 10:30:00'),
(10, 10, 'EMAIL', 1, '2025-11-11 09:30:00', '2025-11-11 11:00:00');

INSERT INTO ips_permitidas (ip, descripcion, fecha_registro) VALUES
('192.168.1.10', 'Servidor principal de la farmacia', '2025-11-11 08:00:00'),
('192.168.1.11', 'Estación de trabajo en almacén', '2025-11-11 08:05:00'),
('192.168.1.12', 'Equipo de Farmacia Hospitalaria', '2025-11-11 08:10:00'),
('192.168.1.13', 'Terminal de Urgencias', '2025-11-11 08:15:00'),
('192.168.1.14', 'Terminal UCI Adultos', '2025-11-11 08:20:00'),
('192.168.1.15', 'Terminal UCI Pediátrica', '2025-11-11 08:25:00'),
('192.168.1.16', 'Equipo Consulta Externa', '2025-11-11 08:30:00'),
('192.168.1.17', 'Equipo Quirófanos', '2025-11-11 08:35:00'),
('192.168.1.18', 'Servidor de respaldo', '2025-11-11 08:40:00'),
('192.168.1.19', 'Equipo Almacén Secundario', '2025-11-11 08:45:00');

INSERT INTO tokens_recuperacion (id_usuario, token, expiracion, usado) VALUES
(1, 'a1b2c3d4e5f6g7h8i9j0', '2025-11-11 23:59:59', 0),
(2, 'z9y8x7w6v5u4t3s2r1q0', '2025-11-12 00:30:00', 0),
(3, 'm1n2o3p4q5r6s7t8u9v0', '2025-11-12 01:00:00', 1),
(4, 'k9l8j7h6g5f4d3s2a1z0', '2025-11-12 01:30:00', 0),
(5, 'p0o9i8u7y6t5r4e3w2q1', '2025-11-12 02:00:00', 0),
(6, 'v1b2n3m4c5x6z7a8s9d0', '2025-11-12 02:30:00', 1),
(7, 'r9t8y7u6i5o4p3l2k1j0', '2025-11-12 03:00:00', 0),
(8, 'e1w2q3a4s5d6f7g8h9j0', '2025-11-12 03:30:00', 0),
(9, 'u9i8o7p6l5k4j3h2g1f0', '2025-11-12 04:00:00', 1),
(10, 'c1v2b3n4m5x6z7a8s9d0', '2025-11-12 04:30:00', 0);

INSERT INTO incidentes_almacenamiento (fecha, descripcion, responsable, accion_correctiva, evidencia, registrado_por) VALUES
('2025-11-10 08:30:00', 'Derrame de solución salina en área de almacenamiento', 'Carlos Pérez', 'Limpieza inmediata y revisión de estanterías', 'Foto del área limpia', 1),
('2025-11-10 09:15:00', 'Medicamento vencido encontrado en estante', 'Ana Gómez', 'Retiro del lote y actualización de inventario', 'Registro en sistema y foto del lote', 2),
('2025-11-10 10:00:00', 'Falla en refrigerador de insulina', 'Luis Torres', 'Traslado de insulina a otro refrigerador y reporte técnico', 'Informe técnico adjunto', 3),
('2025-11-10 11:20:00', 'Caja de jeringas dañada por humedad', 'María Rodríguez', 'Revisión de condiciones ambientales y reposición', 'Foto de la caja dañada', 4),
('2025-11-10 12:45:00', 'Error en etiquetado de lote de antibióticos', 'Pedro Sánchez', 'Corrección de etiquetas y verificación de trazabilidad', 'Etiqueta corregida', 5),
('2025-11-10 14:00:00', 'Ingreso no autorizado al almacén', 'Laura Jiménez', 'Bloqueo de acceso y actualización de credenciales', 'Registro de cámara', 6),
('2025-11-10 15:30:00', 'Rotura de frasco de solución glucosada', 'Andrés López', 'Limpieza y reporte de pérdida', 'Foto del frasco roto', 7),
('2025-11-10 16:10:00', 'Incidente por falta de stock crítico de adrenalina', 'Sofía Martínez', 'Solicitud urgente al proveedor y alerta en sistema', 'Captura de pantalla del stock', 8),
('2025-11-10 17:00:00', 'Desconexión del sistema de monitoreo de temperatura', 'Javier Castro', 'Reconexión y prueba de funcionamiento', 'Informe de reconexión', 9),
('2025-11-10 18:20:00', 'Contaminación cruzada detectada en área de preparación', 'Paula Herrera', 'Desinfección completa y capacitación al personal', 'Certificado de limpieza', 10);

INSERT INTO control_calidad (id_lote, fecha_control, observaciones, resultado, evidencia, registrado_por) VALUES
(1, '2025-11-10 08:30:00', 'Revisión visual completa, sin anomalías', 'APROBADO', 'Foto del lote intacto', 1),
(2, '2025-11-10 09:00:00', 'Se detectó humedad en el empaque', 'RECHAZADO', 'Imagen del empaque dañado', 2),
(3, '2025-11-10 09:45:00', 'Control microbiológico satisfactorio', 'APROBADO', 'Informe de laboratorio adjunto', 3),
(4, '2025-11-10 10:15:00', 'Etiqueta ilegible, requiere reimpresión', 'RECHAZADO', 'Foto de etiqueta', 4),
(5, '2025-11-10 11:00:00', 'Temperatura de almacenamiento correcta', 'APROBADO', 'Registro de temperatura', 5),
(6, '2025-11-10 11:30:00', 'Frasco con fisura detectada', 'RECHAZADO', 'Foto del frasco', 6),
(7, '2025-11-10 12:00:00', 'Cumple especificaciones de lote', 'APROBADO', 'Certificado de calidad', 7),
(8, '2025-11-10 12:30:00', 'Presencia de partículas extrañas', 'RECHAZADO', 'Imagen microscópica', 8),
(9, '2025-11-10 13:00:00', 'Prueba de estabilidad satisfactoria', 'APROBADO', 'Informe técnico', 9),
(10, '2025-11-10 13:30:00', 'Envase deformado por presión', 'RECHAZADO', 'Foto del envase', 10);

INSERT INTO backups (nombre_archivo, ruta_archivo, generado_por, estado, mensaje) VALUES
('backup_2025_11_01.sql', '/var/backups/backup_2025_11_01.sql', 1, 'EXITOSO', 'Backup generado correctamente.'),
('backup_2025_11_02.sql', '/var/backups/backup_2025_11_02.sql', 2, 'EXITOSO', 'Backup completado sin errores.'),
('backup_2025_11_03.sql', '/var/backups/backup_2025_11_03.sql', 3, 'ERROR', 'Error de conexión durante el backup.'),
('backup_2025_11_04.sql', '/var/backups/backup_2025_11_04.sql', 1, 'EXITOSO', 'Backup realizado en tiempo récord.'),
('backup_2025_11_05.sql', '/var/backups/backup_2025_11_05.sql', 4, 'EXITOSO', 'Backup validado correctamente.'),
('backup_2025_11_06.sql', '/var/backups/backup_2025_11_06.sql', 2, 'ERROR', 'Espacio insuficiente en disco.'),
('backup_2025_11_07.sql', '/var/backups/backup_2025_11_07.sql', 3, 'EXITOSO', 'Backup generado y verificado.'),
('backup_2025_11_08.sql', '/var/backups/backup_2025_11_08.sql', 1, 'EXITOSO', 'Backup automático completado.'),
('backup_2025_11_09.sql', '/var/backups/backup_2025_11_09.sql', 4, 'ERROR', 'Permisos insuficientes para escribir archivo.'),
('backup_2025_11_10.sql', '/var/backups/backup_2025_11_10.sql', 2, 'EXITOSO', 'Backup finalizado sin inconvenientes.');

INSERT INTO pacientes (tipo_documento, documento, fecha_ingreso, ultima_atencion, nombre_completo)
VALUES
('CEDULA', '1023456789', '2025-01-15', '2025-02-10', 'Juan Pérez'),
('TARJETA DE IDENTIDAD', 'TI-987654', '2025-03-01', '2025-03-15', 'María Gómez'),
('CEDULA', '1122334455', '2025-04-20', '2025-05-05', 'Carlos Rodríguez'),
('TARJETA DE EXTRANJERÍA', 'EXT-556677', '2025-06-10', NULL, 'Anna Müller'),
('CEDULA', '9988776655', '2025-07-25', '2025-08-01', 'Laura Fernández'),
('TARJETA DE IDENTIDAD', 'TI-123456', '2025-08-30', '2025-09-10', 'Pedro Sánchez'),
('CEDULA', '2233445566', '2025-09-15', NULL, 'Sofía Herrera'),
('TARJETA DE EXTRANJERÍA', 'EXT-889900', '2025-10-05', '2025-10-20', 'John Smith'),
('CEDULA', '3344556677', '2025-10-25', '2025-11-01', 'Camila Torres'),
('TARJETA DE IDENTIDAD', 'TI-654321', '2025-11-10', NULL, 'Andrés López');

INSERT INTO ordenes (id_paciente, id_usuario, fecha_creacion, estado, observaciones) VALUES
(1, 2, '2025-11-11 09:15:00', 'PENDIENTE', 'Orden inicial para paciente con fiebre'),
(2, 3, '2025-11-11 09:30:00', 'PREPARACION', 'Medicamentos en preparación'),
(3, 2, '2025-11-11 10:00:00', 'ENTREGADO', 'Orden entregada en farmacia'),
(4, 4, '2025-11-11 10:15:00', 'CANCELADO', 'Paciente dado de alta antes de entrega'),
(5, 2, '2025-11-11 10:45:00', 'PENDIENTE', 'Pendiente validación por médico'),
(6, 3, '2025-11-11 11:00:00', 'PREPARACION', 'Preparando antibióticos'),
(7, 4, '2025-11-11 11:30:00', 'ENTREGADO', 'Entrega confirmada por enfermería'),
(8, 2, '2025-11-11 12:00:00', 'PENDIENTE', 'Orden urgente para paciente crítico'),
(9, 3, '2025-11-11 12:15:00', 'CANCELADO', 'Paciente trasladado a otra unidad'),
(10, 4, '2025-11-11 12:30:00', 'ENTREGADO', 'Orden completada y registrada');

INSERT INTO orden_detalle (id_orden, id_item, cantidad) VALUES
(1, 1, 2.00),   -- Orden 1: Paracetamol 500mg
(1, 2, 1.00),   -- Orden 1: Ibuprofeno 400mg
(2, 3, 5.00),   -- Orden 2: Amoxicilina 500mg
(3, 4, 3.50),   -- Orden 3: Omeprazol 20mg
(4, 5, 1.00),   -- Orden 4: Lidocaína 2%
(5, 6, 10.00),  -- Orden 5: Adrenalina 1mg/ml
(6, 7, 0.50),   -- Orden 6: Salbutamol Inhalador
(7, 8, 4.00),   -- Orden 7: Jeringa 5ml
(8, 9, 2.00),   -- Orden 8: Guantes de látex Talla M
(9, 10, 6.00);  -- Orden 9: Mascarilla N95



/* ==========================================================
   TESTS: procedimientos_front  (FarmaGestión)
   Precondiciones:
   - farmagestion_DDL_v3.sql cargado
   - procedimientos_front.sql cargado
   - DML_para_front.sql cargado
   ========================================================== */
USE farmagestion;

-- =========================
-- 0) SANITY CHECK DEL DATASET
-- =========================
SELECT 'SANITY_proveedores' AS test, COUNT(*) AS got FROM proveedores;      -- ESPERADO: 10
SELECT 'SANITY_ubicaciones' AS test, COUNT(*) AS got FROM ubicaciones;      -- ESPERADO: 10
SELECT 'SANITY_usuarios'     AS test, COUNT(*) AS got FROM usuarios;        -- ESPERADO: 10
SELECT 'SANITY_items'        AS test, COUNT(*) AS got FROM items;           -- ESPERADO: 10
SELECT 'SANITY_lotes'        AS test, COUNT(*) AS got FROM lotes;           -- ESPERADO: 10
SELECT 'SANITY_movimientos'  AS test, COUNT(*) AS got FROM movimientos;     -- ESPERADO: 10 (todos INGRESO)
SELECT 'SANITY_existencias'  AS test, COALESCE(SUM(saldo),0) AS stock_total FROM existencias; -- ESPERADO: 700
SELECT 'SANITY_pacientes'    AS test, COUNT(*) AS got FROM pacientes;       -- ESPERADO: 10
SELECT 'SANITY_ordenes'      AS test, COUNT(*) AS got FROM ordenes;         -- ESPERADO: 10
SELECT 'SANITY_detalle'      AS test, COUNT(*) AS got FROM orden_detalle;   -- ESPERADO: 10

-- ==========================================================
-- 1) INVENTARIO
-- ==========================================================
-- 1.1 sp_listar_inventario: Debe listar por lote+ubicación con stock agregado.
CALL sp_listar_inventario();
-- ESPERADO: 10 filas; suma(stock) = 700; estado 'Activo' si stock > 0

-- 1.2 sp_buscar_inventario: por código de lote exacto
CALL sp_buscar_inventario('L002-IBUPROF');
-- ESPERADO: 1 fila, lote='L002-IBUPROF', categoria='MEDICAMENTO', stock=50

-- 1.3 sp_obtener_detalle_lote: id_lote=2
CALL sp_obtener_detalle_lote(2);
-- ESPERADO: nombre='Ibuprofeno 400mg', lote='L002-IBUPROF', stock=50, fecha_vencimiento='10/12/2025'

-- 1.4 sp_actualizar_estado_lote: probar cambio y revertir
START TRANSACTION;
  CALL sp_actualizar_estado_lote(2, 'INACTIVO');
  SELECT 'ver_estado_lote_2' AS test, estado FROM lotes WHERE id_lote=2; -- ESPERADO: 'INACTIVO'
ROLLBACK;

-- 1.5 sp_exportar_inventario: igual a listar pero con fecha tipo DATE
CALL sp_exportar_inventario();
-- ESPERADO: 10 filas; mismas cantidades del 1.1

-- ==========================================================
-- 2) REPORTES
-- ==========================================================
-- 2.1 sp_reportes_medicamentos_entregados_mes: no hay SALIDA -> 0
CALL sp_reportes_medicamentos_entregados_mes();
-- ESPERADO: total_entregados = 0

-- 2.2 sp_reportes_alertas_resueltas: si no hay notificaciones, puede devolver NULL
CALL sp_reportes_alertas_resueltas();
-- ESPERADO: porcentaje_resueltas = NULL o 0 (según división por 0); validar manual

-- 2.3 sp_reportes_pedidos_completados: ENTREGADO en mes actual -> 3 (órdenes 3,7,10)
CALL sp_reportes_pedidos_completados();
-- ESPERADO: pedidos_completados = 3

-- 2.4 sp_reportes_medicamentos_entregados_por_semana: sin SALIDA -> 0 filas
CALL sp_reportes_medicamentos_entregados_por_semana();
-- ESPERADO: 0 filas

-- 2.5 sp_reportes_ordenes_mes: 10 filas (una por detalle)
CALL sp_reportes_ordenes_mes();
-- ESPERADO: 10 filas

-- 2.6 sp_exportar_reporte_ordenes_mes: 10 filas (raw date)
CALL sp_exportar_reporte_ordenes_mes();
-- ESPERADO: 10 filas

-- ==========================================================
-- 3) ÓRDENES
-- ==========================================================
-- 3.1 sp_listar_ordenes: 10
CALL sp_listar_ordenes();  -- ESPERADO: 10 filas

-- 3.2 sp_listar_ordenes_por_estado('PENDIENTE'): 3 (1,5,8)
CALL sp_listar_ordenes_por_estado('PENDIENTE'); -- ESPERADO: 3 filas

-- 3.3 sp_buscar_ordenes('Juan'): debe traer al menos 1 (Juan Pérez)
CALL sp_buscar_ordenes('Juan'); -- ESPERADO: >=1

-- 3.4 sp_crear_orden + sp_agregar_detalle_orden + sp_actualizar_estado_orden + sp_obtener_detalle_orden
START TRANSACTION;
  -- Crear
  CALL sp_crear_orden(1, 2, 'Orden de prueba');
  -- Capturar el último id (sesión)
  SET @id_orden_new := LAST_INSERT_ID();
  SELECT 'orden_creada' AS test, @id_orden_new AS id, estado FROM ordenes WHERE id_orden=@id_orden_new;
  -- ESPERADO: estado='PENDIENTE'

  -- Agregar detalle (Paracetamol id_item=1)
  CALL sp_agregar_detalle_orden(@id_orden_new, 1, 3.00);
  
SELECT 'detalle_count' AS test, COUNT(*) AS cnt
FROM orden_detalle
WHERE id_orden=@id_orden_new;

  -- ESPERADO: 1

  -- Cambiar estado
  CALL sp_actualizar_estado_orden(@id_orden_new, 'ENTREGADO');
  SELECT 'orden_estado' AS test, estado FROM ordenes WHERE id_orden=@id_orden_new; 
  -- ESPERADO: 'ENTREGADO'

  -- Obtener detalle
  CALL sp_obtener_detalle_orden(@id_orden_new);
  -- ESPERADO: 1 fila (Paracetamol 3.00)
ROLLBACK;

-- 3.5 sp_obtener_detalle_orden sobre una existente (id=1): 2 filas (2 y 1 und)
CALL sp_obtener_detalle_orden(1);
-- ESPERADO: Paracetamol 2.00, Ibuprofeno 1.00

-- ==========================================================
-- 4) MEDICAMENTOS
-- ==========================================================
-- 4.1 sp_listar_medicamentos: 10 filas, stock agregado por ítem; uso_frecuente 'Frecuente/No frecuente'
CALL sp_listar_medicamentos(); -- ESPERADO: 10 filas

-- 4.2 sp_buscar_medicamento('Paracetamol'): 1 fila, stock 120, área 'Almacén Principal'
CALL sp_buscar_medicamento('Paracetamol');

-- 4.3 Crear/Actualizar/Obtener (rollback al final)
START TRANSACTION;
  CALL sp_crear_medicamento(1, 'MEDTEST001', 'Item de prueba', 'UND', 5, 1);
  SET @id_item_new := LAST_INSERT_ID();
  SELECT 'item_creado' AS test, id_item, codigo, descripcion, stock_minimo, uso_frecuente 
  FROM items WHERE id_item=@id_item_new;
  -- ESPERADO: codigo='MEDTEST001', uso_frecuente=1

  CALL sp_actualizar_medicamento(@id_item_new, 'Item de prueba editado', 10, 0);
  CALL sp_obtener_medicamento(@id_item_new);
  -- ESPERADO: descripcion='Item de prueba editado', stock_minimo=10, uso_frecuente=0
ROLLBACK;

-- ==========================================================
-- 5) PACIENTES
-- ==========================================================
CALL sp_listar_pacientes();         -- ESPERADO: 10
CALL sp_buscar_paciente('Juan');    -- ESPERADO: >=1

START TRANSACTION;
  CALL sp_crear_paciente('CEDULA','DOC-PRUEBA-001','Paciente Test','2025-11-11');
  SET @id_paciente_new := LAST_INSERT_ID();
  SELECT 'pac_creado' AS test, id_paciente, documento, nombre_completo FROM pacientes WHERE id_paciente=@id_paciente_new;

  CALL sp_actualizar_ultima_atencion(@id_paciente_new);
  SELECT 'pac_ultima_atencion' AS test, ultima_atencion FROM pacientes WHERE id_paciente=@id_paciente_new;
  -- ESPERADO: fecha = CURDATE()

  CALL sp_eliminar_paciente(@id_paciente_new);
  SELECT 'pac_eliminado' AS test, COUNT(*) AS cnt
FROM pacientes
WHERE id_paciente=@id_paciente_new; -- ESPERADO: 0
ROLLBACK;

-- ==========================================================
-- 6) DASHBOARD
-- ==========================================================
-- 6.1 stock disponible = ROUND( SUM(saldo)/SUM(stock_minimo)*100 , 2 )
-- Con DML: SUM(saldo)=700, SUM(stock_minimo)=795 => 88.05 %
CALL sp_dashboard_stock_disponible();           -- ESPERADO: 88.05

-- 6.2 alertas vencimiento: lotes que vencen en <= 30 días desde hoy (2025-11-11)
-- Con DML: L002 (2025-12-10), L003 (2025-11-30), L005 (2025-12-05), L006 (2025-11-20) => 4
CALL sp_dashboard_alertas_vencimiento();        -- ESPERADO: 4

-- 6.3 órdenes pendientes: 3
CALL sp_dashboard_ordenes_pendientes();         -- ESPERADO: 3

-- 6.4 top 5 medicamentos más usados (SALIDA): 0 filas (no hay SALIDA)
CALL sp_dashboard_medicamentos_mas_usados();    -- ESPERADO: 0 filas

-- 6.5 distribución por área (SALIDA): 0 filas
CALL sp_dashboard_distribucion_por_area();      -- ESPERADO: 0 filas

-- 6.6 medicamentos en stock crítico (=0): 0
CALL sp_dashboard_medicamentos_stock_critico(); -- ESPERADO: 0

-- 6.7 próximos a vencer (<= 30 días), orden asc y limit 5: 4 filas con cantidades [50,20,10,5]
CALL sp_dashboard_medicamentos_proximos_vencer();

-- 6.8 lista órdenes pendientes (ver nota de incompatibilidad)
-- Si NO aplicaste el parche, aquí fallará por columna inexistente:
-- CALL sp_dashboard_lista_ordenes_pendientes();

-- 6.9 fecha actual (formateada)
CALL sp_dashboard_fecha_actual();               -- ESPERADO: no NULL

-- 6.10 último backup
CALL sp_dashboard_ultimo_backup();              -- ESPERADO: backup_2025_11_10.sql, estado='EXITOSO'

-- 6.11 alertas stock bajo (stock_total <= stock_minimo)
-- Con DML: 9 ítems con stock <= stock_minimo (todos menos el ítem 1)
CALL sp_dashboard_alertas_stock_bajo();         -- ESPERADO: 9

-- 6.12 sesiones activas
CALL sp_dashboard_sesiones_activas();           -- ESPERADO: 6


