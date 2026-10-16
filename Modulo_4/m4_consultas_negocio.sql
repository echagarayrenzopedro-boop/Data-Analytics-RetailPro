-- =====================================================================

-- Pre-entrega Módulo 4 – Consultas SQL de negocio
-- Título: Extrayendo métricas clave con SQL
-- Proyecto: RetailPro – Base de datos Ventas_Tech_DB (creada en M3)
-- Autor: Pedro Echagaray
-- Motor utilizado: SQL Server 2025 Express (SSMS 22)
-- Tabla de trabajo: ventas (id_cliente, id_producto, cantidad,
--                   precio_unitario, fecha_venta)
-- Facturación de cada venta = cantidad * precio_unitario
-- =====================================================================
 
USE Ventas_Tech_DB;
GO
 
 
-- =====================================================================
-- CONSULTA 1 — Resumen ejecutivo mensual
-- Total facturado, cantidad de pedidos y ticket promedio por mes.
-- Se agrega el año para que no se mezclen meses de años distintos
-- (por ejemplo, marzo 2024 con marzo 2025).
-- =====================================================================
 
SELECT
    YEAR(fecha_venta)                                       AS anio,
    MONTH(fecha_venta)                                      AS mes,
    SUM(cantidad * precio_unitario)                         AS total_facturado,
    COUNT(*)                                                AS cantidad_pedidos,
    CAST(AVG(cantidad * precio_unitario) AS DECIMAL(10,2))  AS ticket_promedio
FROM ventas
GROUP BY YEAR(fecha_venta), MONTH(fecha_venta)
ORDER BY anio, mes;
-- Resultado: 2024 | 3 | 4689.00 | 10 | 468.90
 
 
-- =====================================================================
-- CONSULTA 2 — Ranking de productos (Top 5 por facturación)
-- Unidades vendidas y total generado por cada producto.
-- =====================================================================
 
SELECT TOP 5
    id_producto,
    SUM(cantidad)                    AS unidades_vendidas,
    SUM(cantidad * precio_unitario)  AS total_facturado
FROM ventas
GROUP BY id_producto
ORDER BY total_facturado DESC;
-- Resultado: 1 → 2 un. / 2400 · 3 → 3 un. / 1350 · 4 → 3 un. / 360
--            5 → 2 un. / 260  · 2 → 8 un. / 224
 
 
-- =====================================================================
-- CONSULTA 3 — Clientes recurrentes (más de un pedido)
-- HAVING filtra DESPUÉS de agrupar: deja solo los clientes con 2+ pedidos.
-- =====================================================================
 
SELECT
    id_cliente,
    COUNT(*)                         AS cantidad_pedidos,
    SUM(cantidad * precio_unitario)  AS total_gastado
FROM ventas
GROUP BY id_cliente
HAVING COUNT(*) > 1
ORDER BY total_gastado DESC;
-- Resultado: 1 → 3 pedidos / 1535 · 2 → 2 / 1340 · 3 → 2 / 984 · 4 → 2 / 570
-- El cliente 5 queda afuera: hizo un solo pedido.
 
 
-- =====================================================================
-- CONSULTA 4 — Meses por encima / por debajo del promedio
-- Paso 1 (CTE "facturacion_mensual"): total facturado de cada mes.
-- Paso 2: se compara cada mes contra el promedio de todos los meses.
-- Se agrega la etiqueta 'En el promedio' para el caso de empate
-- (pasa cuando hay un solo mes de datos, como en esta base).
-- =====================================================================
 
WITH facturacion_mensual AS (
    SELECT
        YEAR(fecha_venta)                AS anio,
        MONTH(fecha_venta)               AS mes,
        SUM(cantidad * precio_unitario)  AS total_facturado
    FROM ventas
    GROUP BY YEAR(fecha_venta), MONTH(fecha_venta)
)
SELECT
    anio,
    mes,
    total_facturado,
    CAST((SELECT AVG(total_facturado) FROM facturacion_mensual) AS DECIMAL(10,2))
                                                         AS promedio_mensual,
    CASE
        WHEN total_facturado > (SELECT AVG(total_facturado) FROM facturacion_mensual)
            THEN 'Por encima'
        WHEN total_facturado < (SELECT AVG(total_facturado) FROM facturacion_mensual)
            THEN 'Por debajo'
        ELSE 'En el promedio'
    END                                                  AS comparacion_vs_promedio
FROM facturacion_mensual
ORDER BY anio, mes;
-- Resultado: 2024 | 3 | 4689.00 | 4689.00 | En el promedio
GO
 
 
-- =====================================================================
-- HALLAZGOS
-- =====================================================================
-- 1. Alta concentración en pocos productos: el producto 1 (notebook)
--    genera el 51,2% de la facturación total (2400 de 4689), y junto al
--    producto 3 (monitor) llegan al 80%. Si alguno de los dos se queda
--    sin stock o baja su precio, el impacto en la facturación es directo.
--
-- 2. Vender más unidades no es facturar más: el producto 2 (mouse) es el
--    que más unidades vendió (8), pero queda último del Top 5 con apenas
--    224 (4,8% del total). Medir el negocio solo por volumen llevaría a
--    conclusiones equivocadas; hay que mirar facturación y margen.
--
-- 3. La facturación depende de clientes que repiten: 4 de los 5 clientes
--    compraron más de una vez y explican el 94,5% de la facturación. El
--    cliente 1 lidera con 3 pedidos y 1535 (32,7% del total). Conviene
--    priorizar su retención.
--
-- Limitación de los datos: las 10 ventas son de marzo 2024, así que las
-- consultas 1 y 4 devuelven un solo mes y la comparación contra el
-- promedio no permite sacar conclusiones. Para analizar tendencias hace
-- falta cargar ventas de más meses.
-- =====================================================================
