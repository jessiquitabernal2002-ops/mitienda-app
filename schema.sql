CREATE DATABASE tienda_db;
USE tienda_db;

CREATE TABLE usuarios (
  id INT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  nombre VARCHAR(100) NOT NULL,
  contrasena_hash VARCHAR(255) NOT NULL,
  fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  esta_activo BOOLEAN DEFAULT TRUE
);

CREATE TABLE productos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(200) NOT NULL,
  precio DECIMAL(10,2) NOT NULL,
  imagen_url TEXT,
  descripcion TEXT,
  categoria VARCHAR(100),
  calificacion DECIMAL(2,1) DEFAULT 0.0,
  tiene_descuento BOOLEAN DEFAULT FALSE,
  activo BOOLEAN DEFAULT TRUE
);

-- Productos hombre
INSERT INTO productos (nombre, precio, imagen_url, descripcion, categoria) VALUES
('Camiseta Basica', 29.99, 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400', 'Algodon 100%', 'Ropa'),
('Pantalon Casual', 59.99, 'https://images.unsplash.com/photo-1542272604-787c3835535d?w=400', 'Comodo y elegante', 'Ropa'),
('Zapatillas Running', 89.99, 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400', 'Ideal para correr', 'Calzado'),
('Gorra Deportiva', 19.99, 'https://images.unsplash.com/photo-1588850561407-ed78c282e89b?w=400', 'Gorra ajustable', 'Accesorios'),
('Sudadera Capucha', 49.99, 'https://images.unsplash.com/photo-1620799140408-edc6dcb6d633?w=400', 'Calida y comoda', 'Ropa'),
('Cinturon Cuero', 34.99, 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400', 'Cuero genuino', 'Accesorios'),

-- Productos mujer
('Vestido Floral', 49.99, 'https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?w=400', 'Vestido ligero con estampado floral', 'Mujer'),
('Blusa Elegante', 34.99, 'https://images.unsplash.com/photo-1564257631407-4deb1f99d992?w=400', 'Blusa de seda para ocasiones especiales', 'Mujer'),
('Jeans Skinny', 59.99, 'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=400', 'Jeans ajustados de alta calidad', 'Mujer'),
('Bolso de Mano', 79.99, 'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=400', 'Bolso elegante de cuero genuino', 'Mujer'),
('Tacones Clasicos', 89.99, 'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?w=400', 'Tacones clasicos para toda ocasion', 'Mujer'),
('Falda Midi', 44.99, 'https://images.unsplash.com/photo-1583496661160-fb5886a0aaaa?w=400', 'Falda midi elegante y comoda', 'Mujer');

-- Usuario de prueba (contraseña: contrasena123)
INSERT INTO usuarios (email, nombre, contrasena_hash) VALUES
('test@tienda.com', 'Usuario Prueba',
'$2b$12$tqJejqLcb.WC9aSg5jJWtObQQZbo1I5e6eu1MjZGwwZbiZrzGxL.O');