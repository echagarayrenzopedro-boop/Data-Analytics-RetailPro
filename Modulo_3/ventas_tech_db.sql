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
-- Se usa NVARCHAR para soportar acentos y ñ (Lucía, Malargüe, etc.).
-- Todas las restricciones tienen nombre para identificarlas fácilmente.
-- =====================================================================

-- Dimensión: categorías de producto (tabla propia para cumplir 3NF)
CREATE TABLE categorias (
    id_categoria   INT IDENTITY(1,1) NOT NULL,
    nombre         NVARCHAR(50)  NOT NULL,
    descripcion    NVARCHAR(150) NULL,
    CONSTRAINT pk_categorias        PRIMARY KEY (id_categoria),
    CONSTRAINT uq_categorias_nombre UNIQUE (nombre)
);

-- Dimensión: clientes
CREATE TABLE clientes (
    id_cliente     INT IDENTITY(1,1) NOT NULL,
    nombre         NVARCHAR(60)  NOT NULL,
    apellido       NVARCHAR(60)  NOT NULL,
    email          NVARCHAR(100) NOT NULL,
    ciudad         NVARCHAR(60)  NOT NULL,
    fecha_alta     DATE          NOT NULL CONSTRAINT df_clientes_fecha_alta DEFAULT GETDATE(),
    activo         BIT           NOT NULL CONSTRAINT df_clientes_activo     DEFAULT 1,
    CONSTRAINT pk_clientes       PRIMARY KEY (id_cliente),
    CONSTRAINT uq_clientes_email UNIQUE (email)
);

-- Dimensión: productos (cada producto pertenece a una categoría)
CREATE TABLE productos (
    id_producto    INT IDENTITY(1,1) NOT NULL,
    nombre         NVARCHAR(80)  NOT NULL,
    id_categoria   INT           NOT NULL,
    precio_lista   DECIMAL(10,2) NOT NULL,
    stock          INT           NOT NULL CONSTRAINT df_productos_stock DEFAULT 0,
    CONSTRAINT pk_productos              PRIMARY KEY (id_producto),
    CONSTRAINT ck_productos_precio_lista CHECK (precio_lista > 0),
    CONSTRAINT ck_productos_stock        CHECK (stock >= 0),
    CONSTRAINT fk_productos_categorias
        FOREIGN KEY (id_categoria) REFERENCES categorias(id_categoria)
);

-- Hechos: ventas (une cliente + producto en una fecha)
-- id_venta no es autoincremental para poder cargar ventas con id definido
CREATE TABLE ventas (
    id_venta         INT           NOT NULL,
    id_cliente       INT           NOT NULL,
    id_producto      INT           NOT NULL,
    cantidad         INT           NOT NULL,
    precio_unitario  DECIMAL(10,2) NOT NULL,
    fecha_venta      DATE          NOT NULL,
    CONSTRAINT pk_ventas                 PRIMARY KEY (id_venta),
    CONSTRAINT ck_ventas_cantidad        CHECK (cantidad > 0),
    CONSTRAINT ck_ventas_precio_unitario CHECK (precio_unitario > 0),
    CONSTRAINT fk_ventas_clientes
        FOREIGN KEY (id_cliente)  REFERENCES clientes(id_cliente),
    CONSTRAINT fk_ventas_productos
        FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
);
GO


-- =====================================================================
-- SECCIÓN 3 — INSERT
-- Se carga en el mismo orden en que se crearon las tablas.
-- El prefijo N'...' indica texto Unicode (necesario para acentos y ñ).
-- =====================================================================

INSERT INTO categorias (nombre, descripcion) VALUES
    (N'Computadoras',  N'Notebooks y equipos de escritorio'),
    (N'Periféricos',   N'Mouse, teclados y accesorios de entrada'),
    (N'Monitores',     N'Pantallas y monitores'),
    (N'Audio y Video', N'Auriculares, webcams y parlantes');

INSERT INTO clientes (nombre, apellido, email, ciudad, fecha_alta, activo) VALUES
    (N'Lucía',    N'Fernández', N'lucia.fernandez@mail.com',  N'Mendoza',        '2023-08-14', 1),
    (N'Martín',   N'Gómez',     N'martin.gomez@mail.com',     N'San Rafael',     '2023-09-02', 1),
    (N'Valeria',  N'Sosa',      N'valeria.sosa@mail.com',     N'Neuquén',        '2023-10-21', 1),
    (N'Diego',    N'Ramírez',   N'diego.ramirez@mail.com',    N'Malargüe',       '2023-11-05', 1),
    (N'Carolina', N'Herrera',   N'carolina.herrera@mail.com', N'General Alvear', '2024-01-09', 0);

INSERT INTO productos (nombre, id_categoria, precio_lista, stock) VALUES
    (N'Notebook Ryzen 7 16GB',     1, 1200.00, 15),
    (N'Mouse inalámbrico',         2,   28.00, 120),
    (N'Monitor 27" QHD',           3,  450.00, 25),
    (N'Teclado mecánico',          2,  120.00, 40),
    (N'Auriculares con micrófono', 4,  130.00, 35),
    (N'Webcam Full HD',            4,   95.00, 50);

INSERT INTO ventas (id_venta, id_cliente, id_producto, cantidad, precio_unitario, fecha_venta) VALUES
    (1,  1, 1, 1, 1200.00, '2024-03-02'),
    (2,  2, 2, 5,   28.00, '2024-03-04'),
    (3,  3, 3, 2,  450.00, '2024-03-07'),
    (4,  4, 4, 1,  120.00, '2024-03-10'),
    (5,  5, 5, 2,  130.00, '2024-03-12'),  -- cliente hoy inactivo: compró antes de darse de baja
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

-- 4.1 Cantidad de registros por tabla (esperado: 4 / 5 / 6 / 10)
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
       c.nombre + N' ' + c.apellido    AS cliente,
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
