ALTER USER 'farmagestion_user'@'localhost' IDENTIFIED BY 'password123';

-- descomentar siguiente llinea solo si ienes problemas con la conexion
-- ALTER USER 'farmagestion_user'@'localhost' IDENTIFIED BY 'Fg@2025!Secure#';

GRANT ALL PRIVILEGES ON farmagestion.* TO 'farmagestion_user'@'localhost';

FLUSH PRIVILEGES;