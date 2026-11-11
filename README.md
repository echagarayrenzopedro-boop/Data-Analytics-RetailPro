# Data-Analytics-RetailPro

Proyecto integrador del curso **Data Analytics – Coderhouse**: análisis de ventas de **RetailPro**, una tienda de tecnología, desde la base de datos en SQL Server hasta el modelo y las medidas en Power BI.

**Objetivo de negocio:** saber qué productos, clientes y ciudades explican la facturación, para que el equipo comercial decida dónde poner stock, promociones y acciones de retención.

## Herramientas

| Herramienta | Uso en el proyecto |
|---|---|
| SQL Server 2025 Express + SSMS 22 | Base `Ventas_Tech_DB`: creación, carga, consultas de negocio y JOINs |
| Power BI Desktop (Power Query / código M) | Pipeline ETL: limpieza de nulos, duplicados y tipos |
| Power BI Desktop (modelo + DAX) | Esquema en estrella, tabla calendario y medidas de tiempo |
| GitHub | Versionado y portfolio de las entregas |

## Estructura del repositorio

| Carpeta | Contenido | Archivo principal |
|---|---|---|
| `Modulo_3` | Creación del modelo (4 tablas con PK, FK y CHECK) y carga de datos | `ventas_tech_db.sql` |
| `Modulo_4` | Consultas de negocio: resumen mensual, ranking, clientes recurrentes | `m4_consultas_negocio.sql` |
| `Modulo_5` | Consultas con INNER JOIN, LEFT JOIN y UNION ALL | `m5_consultas_joins.sql` |
| `Modulo_6` | Pipeline ETL en Power Query | `Pipeline_ETL_Echagaray_Pedro.pbix` + código M + PDF |
| `Modulo_8` | Modelo de datos y medidas DAX (Total Ventas, YTD, LY, % crecimiento) | `Echagaray_Pedro_Checkpoint2.pbix` |

Los módulos 1, 2 y 7 se entregaron como documentos en la plataforma del curso, por eso no tienen carpeta.

## Modelo de datos (SQL)

```
categorias (1) ──< productos (1) ──< ventas >── (1) clientes
```

- `ventas`: tabla de hechos (id_venta, id_cliente, id_producto, cantidad, precio_unitario, fecha_venta)
- `clientes`, `productos`, `categorias`: dimensiones
- Facturación de cada venta = `cantidad * precio_unitario`

## Cómo ejecutar los scripts SQL

1. Abrí SSMS y conectate a tu instancia (por ejemplo `localhost\SQLEXPRESS`).
2. Ejecutá **en este orden**:
   1. `Modulo_3/ventas_tech_db.sql` → crea la base `Ventas_Tech_DB` y carga los datos.
   2. `Modulo_4/m4_consultas_negocio.sql` → consultas de negocio (solo lectura).
   3. `Modulo_5/m5_consultas_joins.sql` → agrega 2 clientes y 1 producto **sin ventas** (para probar los LEFT JOIN) y ejecuta las consultas.
3. Antes de ejecutar, verificá que el desplegable de bases diga `Ventas_Tech_DB` y no `master`.

> ⚠️ **Atención:** el script del Módulo 3 hace `DROP TABLE` y recrea todo. Si lo volvés a correr después del Módulo 5, se borran los datos de prueba: ejecutá de nuevo el Módulo 5.

## Resultados de control

Si estos números coinciden, la base quedó bien cargada:

| Control | Resultado esperado |
|---|---|
| Registros por tabla (después de M3) | categorias 4 · clientes 5 · productos 6 · ventas 10 |
| Facturación total (M4, consulta 1) | 4689.00 en 10 pedidos, ticket promedio 468.90 (marzo 2024) |
| Clientes sin ventas (M5, consulta 2) | Sofía Paredes y Joaquín Ortiz |
| Productos sin ventas (M5, consulta 3) | Parlante Bluetooth (30 u. en stock) |

## Archivos de Power BI

- Abrir los `.pbix` con Power BI Desktop.
- El pipeline del Módulo 6 lee un Excel (`Pipeline_ETL_Dataset.xlsx`) que no está en el repositorio. Si la ruta no existe en tu PC, cambiala en **Transformar datos → Configuración de origen de datos**.

## Limitaciones conocidas

- Las 10 ventas de la base SQL son de marzo 2024: no alcanzan para analizar tendencias.
- El dataset de Power BI (50 ventas, 2023–2024) es distinto del de SQL; sus totales no se comparan entre sí.

## Autor y uso de IA

**Pedro Echagaray** – Técnico Superior en Petróleo y Gas, estudiante de la Licenciatura en Administración de Empresas.

Este README se generó como borrador con asistencia de IA (Claude) y lo edité y validé contra los archivos del repositorio. Las cifras de "Resultados de control" salen de la 
