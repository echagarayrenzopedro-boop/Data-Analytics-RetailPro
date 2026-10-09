-- =====================================================================
-- Checkpoint Módulo 3 – Script SQL de Ingeniería de Datos
-- Proyecto: TechStore – Base de datos Ventas_Tech_DB
-- Autor: Pedro Echagaray
-- Motor utilizado: SQL Server 2025 Express (SSMS 22)
-- Modelo: categorias (1) - (N) productos (1) - (N) ventas (N) - (1) clientes
-- =====================================================================

-- Crear la base solo si todavía no existe (permite correr el script varias veces)
IF DB_ID('Ventas_Tech_DB') IS NULL
    CREATE DATABASE Ventas_Tech_DB;
GO

USE Ventas_Tech_DB;
GO


-- =====================================================================
-- SECCIÓN 1 — DROP TABLES
-- Se eliminan en orden inverso a las dependencias:
-- primero la tabla de hechos (ventas), al final la que no depende de nadie.
-- =====================================================================

DROP TABLE IF EXISTS ventas;
DROP TABLE IF EXISTS productos;
DROP TABLE IF EXISTS clientes;
DROP TABLE IF EXISTS categorias;
GO


-- =====================================================================
-- SECCIÓN 2 — CREATE TABLES
-- Orden: primero las dimensiones independientes, después las que tienen FK.
-- =====================================================================

-- Dimensión: categorías de producto (tabla propia para cumplir 3NF)
CREATE TABLE categorias (
    id_categoria   INT IDENTITY(1,1) PRIMARY KEY,
    nombre         VARCHAR(50)  NOT NULL UNIQUE,
    descripcion    VARCHAR(150) NULL
);

-- Dimensión: clientes
CREATE TABLE clientes (
    id_cliente     INT IDENTITY(1,1) PRIMARY KEY,
    nombre         VARCHAR(60)  NOT NULL,
    apellido       VARCHAR(60)  NOT NULL,
    email          VARCHAR(100) NOT NULL UNIQUE,
    ciudad         VARCHAR(60)  NOT NULL,
    fecha_alta     DATE         NOT NULL DEFAULT GETDATE(),
    activo         BIT          NOT NULL DEFAULT 1
);

-- Dimensión: productos (cada producto pertenece a una categoría)
CREATE TABLE productos (
    id_producto    INT IDENTITY(1,1) PRIMARY KEY,
    nombre         VARCHAR(80)   NOT NULL,
    id_categoria   INT           NOT NULL,
    precio_lista   DECIMAL(10,2) NOT NULL CHECK (precio_lista > 0),
    stock          INT           NOT NULL DEFAULT 0 CHECK (stock >= 0),
    CONSTRAINT fk_productos_categorias
        FOREIGN KEY (id_categoria) REFERENCES categorias(id_categoria)
);

-- Hechos: ventas (une cliente + producto en una fecha)
-- id_venta no es autoincremental para poder cargar ventas con id definido
CREATE TABLE ventas (
    id_venta         INT           PRIMARY KEY,
    id_cliente       INT           NOT NULL,
    id_producto      INT           NOT NULL,
    cantidad         INT           NOT NULL CHECK (cantidad > 0),
    precio_unitario  DECIMAL(10,2) NOT NULL CHECK (precio_unitario > 0),
    fecha_venta      DATE          NOT NULL,
    CONSTRAINT fk_ventas_clientes
        FOREIGN KEY (id_cliente)  REFERENCES clientes(id_cliente),
    CONSTRAINT fk_ventas_productos
        FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
);
GO


-- =====================================================================
-- SECCIÓN 3 — INSERT
-- Se carga en el mismo orden en que se crearon las tablas.
-- =====================================================================

INSERT INTO categorias (nombre, descripcion) VALUES
    ('Computadoras', 'Notebooks y equipos de escritorio'),
    ('Periféricos',  'Mouse, teclados y accesorios de entrada'),
    ('Monitores',    'Pantallas y monitores'),
    ('Audio y Video','Auriculares, webcams y parlantes');

INSERT INTO clientes (nombre, apellido, email, ciudad, fecha_alta, activo) VALUES
    ('Lucía',    'Fernández', 'lucia.fernandez@mail.com', 'Mendoza',     '2023-08-14', 1),
    ('Martín',   'Gómez',     'martin.gomez@mail.com',    'San Rafael',  '2023-09-02', 1),
    ('Valeria',  'Sosa',      'valeria.sosa@mail.com',    'Neuquén',     '2023-10-21', 1),
    ('Diego',    'Ramírez',   'diego.ramirez@mail.com',   'Malargüe',    '2023-11-05', 1),
    ('Carolina', 'Herrera',   'carolina.herrera@mail.com','General Alvear','2024-01-09', 0);

INSERT INTO productos (nombre, id_categoria, precio_lista, stock) VALUES
    ('Notebook Ryzen 7 16GB',      1, 1200.00, 15),
    ('Mouse inalámbrico',          2,   28.00, 120),
    ('Monitor 27" QHD',            3,  450.00, 25),
    ('Teclado mecánico',           2,  120.00, 40),
    ('Auriculares con micrófono',  4,  130.00, 35),
    ('Webcam Full HD',             4,   95.00, 50);

INSERT INTO ventas (id_venta, id_cliente, id_producto, cantidad, precio_unitario, fecha_venta) VALUES
    (1,  1, 1, 1, 1200.00, '2024-03-02'),
    (2,  2, 2, 5,   28.00, '2024-03-04'),
    (3,  3, 3, 2,  450.00, '2024-03-07'),
    (4,  4, 4, 1,  120.00, '2024-03-10'),
    (5,  5, 5, 2,  130.00, '2024-03-12'),
    (6,  1, 6, 1,   95.00, '2024-03-15'),
    (7,  2, 1, 1, 1200.00, '2024-03-19'),
    (8,  3, 2, 3,   28.00, '2024-03-22'),
    (9,  4, 3, 1,  450.00, '2024-03-26'),
    (10, 1, 4, 2,  120.00, '2024-03-29');
GO


-- =====================================================================
-- SECCIÓN 4 — VALIDACIÓN
-- Controles para confirmar que el modelo quedó bien cargado.
-- =====================================================================

-- 4.1 Cantidad de registros por tabla
SELECT 'categorias' AS tabla, COUNT(*) AS registros FROM categorias
UNION ALL
SELECT 'clientes',  COUNT(*) FROM clientes
UNION ALL
SELECT 'productos', COUNT(*) FROM productos
UNION ALL
SELECT 'ventas',    COUNT(*) FROM ventas;

-- 4.2 Integridad: ventas sin cliente o sin producto válido (debe devolver 0 filas)
SELECT v.id_venta
FROM ventas v
LEFT JOIN clientes  c ON v.id_cliente  = c.id_cliente
LEFT JOIN productos p ON v.id_producto = p.id_producto
WHERE c.id_cliente IS NULL OR p.id_producto IS NULL;

-- 4.3 Productos sin categoría válida (debe devolver 0 filas)
SELECT p.id_producto, p.nombre
FROM productos p
LEFT JOIN categorias cat ON p.id_categoria = cat.id_categoria
WHERE cat.id_categoria IS NULL;

-- 4.4 Vista integrada del modelo: cada venta con su cliente, producto y categoría
SELECT v.id_venta,
       v.fecha_venta,
       c.nombre + ' ' + c.apellido     AS cliente,
       p.nombre                        AS producto,
       cat.nombre                      AS categoria,
       v.cantidad,
       v.precio_unitario,
       v.cantidad * v.precio_unitario  AS total_venta
FROM ventas v
JOIN clientes   c   ON v.id_cliente   = c.id_cliente
JOIN productos  p   ON v.id_producto  = p.id_producto
JOIN categorias cat ON p.id_categoria = cat.id_categoria
ORDER BY v.id_venta;
GO
