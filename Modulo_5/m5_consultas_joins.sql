-- =====================================================================
-- Pre-entrega Módulo 5 – Consultas con JOINs para el proyecto
-- Título: Cruzando tablas para enriquecer el análisis
-- Proyecto: RetailPro – Base de datos Ventas_Tech_DB (creada en M3)
-- Autor: Pedro Echagaray
-- Motor utilizado: SQL Server 2025 Express (SSMS 22)
--
-- Alias: v = ventas, c = clientes, p = productos, cat = categorias
-- Relaciones:
--   ventas.id_cliente     = clientes.id_cliente
--   ventas.id_producto    = productos.id_producto
--   productos.id_categoria = categorias.id_categoria
--
-- Requisito: haber ejecutado antes el script de M3 (ventas_tech_db.sql).
-- =====================================================================

USE Ventas_Tech_DB;
GO


-- =====================================================================
-- Datos de prueba para las consultas 2 y 3
-- En la base de M3 todos los clientes compraron y todos los productos
-- se vendieron, así que los LEFT JOIN no encontrarían casos. Se agregan
-- 2 clientes y 1 producto sin ventas. No se modifica la tabla ventas,
-- por lo que los resultados de M4 no cambian.
-- IF NOT EXISTS evita duplicarlos si el script se ejecuta más de una vez.
-- =====================================================================

IF NOT EXISTS (SELECT 1 FROM clientes WHERE email = N'sofia.paredes@mail.com')
    INSERT INTO clientes (nombre, apellido, email, ciudad, fecha_alta, activo)
    VALUES (N'Sofía', N'Paredes', N'sofia.paredes@mail.com', N'Luján de Cuyo', '2024-03-08', 1);

IF NOT EXISTS (SELECT 1 FROM clientes WHERE email = N'joaquin.ortiz@mail.com')
    INSERT INTO clientes (nombre, apellido, email, ciudad, fecha_alta, activo)
    VALUES (N'Joaquín', N'Ortiz', N'joaquin.ortiz@mail.com', N'Mendoza', '2024-03-20', 1);

IF NOT EXISTS (SELECT 1 FROM productos WHERE nombre = N'Parlante Bluetooth')
    INSERT INTO productos (nombre, id_categoria, precio_lista, stock)
    VALUES (N'Parlante Bluetooth', 4, 85.00, 30);
GO


-- =====================================================================
-- Consulta 1: Vista base del proyecto (INNER JOIN)
-- Propósito: tener en una sola fila cada venta con su cliente, ciudad,
-- producto y categoría. Es la fuente de datos principal para Power BI:
-- "categoria" y "ciudad" sirven para agrupar, "fecha_venta" para filtrar.
-- =====================================================================

SELECT
    v.id_venta,
    v.fecha_venta,
    c.nombre + N' ' + c.apellido     AS cliente,
    c.ciudad,
    p.nombre                         AS producto,
    cat.nombre                       AS categoria,
    v.cantidad,
    v.precio_unitario,
    v.cantidad * v.precio_unitario   AS total_venta
FROM ventas AS v
INNER JOIN clientes AS c
    ON v.id_cliente = c.id_cliente
INNER JOIN productos AS p
    ON v.id_producto = p.id_producto
INNER JOIN categorias AS cat
    ON p.id_categoria = cat.id_categoria
ORDER BY v.fecha_venta;
-- Resultado esperado: 10 filas, la primera Lucía Fernández / Notebook / 1200.00
-- Hallazgo: Computadoras y Monitores suman el 80% de la facturación
-- (3750 de 4689), y Mendoza es la ciudad que más compra (1535, 32,7%).


-- =====================================================================
-- Consulta 2: Clientes sin ventas (LEFT JOIN)
-- Propósito: detectar clientes registrados que nunca compraron, para que
-- CRM los contacte con una acción de primera compra.
-- =====================================================================

SELECT
    c.nombre + N' ' + c.apellido  AS cliente,
    c.email,
    c.fecha_alta                  AS fecha_registro
FROM clientes AS c
LEFT JOIN ventas AS v
    ON c.id_cliente = v.id_cliente
WHERE v.id_venta IS NULL
ORDER BY c.fecha_alta;
-- Resultado esperado: Sofía Paredes (2024-03-08) y Joaquín Ortiz (2024-03-20)
-- Hallazgo: 2 de los 7 clientes registrados (29%) nunca compraron, y los 2
-- se registraron en marzo 2024, el último mes con datos. Son altas recientes
-- sin conversión: CRM debería contactarlos con una promo de primera compra.


-- =====================================================================
-- Consulta 3: Productos sin ventas (LEFT JOIN)
-- Propósito: identificar artículos del catálogo sin movimiento, para que
-- el área de producto decida si promocionarlos, bajarlos o no reponerlos.
-- =====================================================================

SELECT
    p.nombre        AS producto,
    cat.nombre      AS categoria,
    p.precio_lista  AS precio,
    p.stock
FROM productos AS p
INNER JOIN categorias AS cat
    ON p.id_categoria = cat.id_categoria
LEFT JOIN ventas AS v
    ON p.id_producto = v.id_producto
WHERE v.id_venta IS NULL;
-- Resultado esperado: Parlante Bluetooth | Audio y Video | 85.00 | 30
-- Hallazgo: 1 de los 7 productos del catálogo no tuvo ventas: el Parlante
-- Bluetooth, con 30 unidades en stock inmovilizadas (2550 a precio de lista).
-- Producto debería promocionarlo o frenar su reposición.


-- =====================================================================
-- Consulta 4: Consolidado por canal (UNION ALL)
-- Propósito: comparar cuánto se vende en cada quincena del mes.
-- La columna "canal" no existe en las tablas: se crea como texto fijo
-- dentro de cada SELECT. Se usa UNION ALL (y no UNION) para que ninguna
-- venta se pierda aunque coincida en todos sus valores con otra.
-- =====================================================================

SELECT
    canal,
    COUNT(*)    AS cantidad_ventas,
    SUM(total)  AS total_canal
FROM (
    SELECT
        fecha_venta,
        cantidad * precio_unitario  AS total,
        'Primera quincena'          AS canal
    FROM ventas
    WHERE DAY(fecha_venta) <= 15

    UNION ALL

    SELECT
        fecha_venta,
        cantidad * precio_unitario  AS total,
        'Segunda quincena'          AS canal
    FROM ventas
    WHERE DAY(fecha_venta) > 15
) AS consolidado
GROUP BY canal
ORDER BY total_canal DESC;
-- Resultado esperado: Primera quincena | 6 | 2715.00
--                     Segunda quincena | 4 | 1974.00
-- Hallazgo: la primera quincena factura el 57,9% del mes (2715 de 4689) con
-- 6 de las 10 ventas. Conviene revisar si la segunda quincena necesita
-- acciones comerciales para sostener el ritmo de ventas.
GO
