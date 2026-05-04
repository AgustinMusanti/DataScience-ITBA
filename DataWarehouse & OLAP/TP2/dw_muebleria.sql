-- ============================================================
--  DATA WAREHOUSE — Empresa Mayorista de Muebles
--  Esquema: Estrella (Star Schema)
--  Motor:   DuckDB (compatible con PostgreSQL)
--  Autor:   Agustín Musanti — Consigna 4
-- ============================================================


--  1. DDL — TABLAS DE DIMENSIÓN Y HECHO

-- ------------------------------------------------------------
--  DIM_TIEMPO
--  Granularidad: día
--  Jerarquía:   día → mes → trimestre → año
-- ------------------------------------------------------------
CREATE OR REPLACE TABLE DIM_TIEMPO (
    id_tiempo    INTEGER PRIMARY KEY,   -- surrogate key (formato YYYYMMDD)
    fecha        DATE        NOT NULL,
    dia          SMALLINT    NOT NULL,
    mes          SMALLINT    NOT NULL,
    nombre_mes   VARCHAR(12) NOT NULL,
    trimestre    VARCHAR(2)  NOT NULL,
    anio         SMALLINT    NOT NULL
);

-- ------------------------------------------------------------
--  DIM_MUEBLE
--  Jerarquía desnorm.: mueble → tipo → categoría  +  material
-- ------------------------------------------------------------
CREATE OR REPLACE TABLE DIM_MUEBLE (
    id_mueble    INTEGER PRIMARY KEY,
    nombre       VARCHAR(80)  NOT NULL,
    precio_lista DECIMAL(10,2) NOT NULL,
    tipo         VARCHAR(40)  NOT NULL,   -- silla, mesa, armario…
    categoria    VARCHAR(40)  NOT NULL,   -- cocina, living, dormitorio…
    material     VARCHAR(40)  NOT NULL    -- madera, mármol, metal…
);

-- ------------------------------------------------------------
--  DIM_CLIENTE  (con SCD Tipo 2)
--  Jerarquía desnorm.: cliente → ciudad → región → provincia
-- ------------------------------------------------------------
CREATE OR REPLACE TABLE DIM_CLIENTE (
    cliente_sk   INTEGER PRIMARY KEY,    -- surrogate key (única por versión)
    cliente_nk   INTEGER     NOT NULL,   -- natural key  (identifica al cliente real)
    nombre       VARCHAR(80) NOT NULL,
    ciudad       VARCHAR(60) NOT NULL,
    region       VARCHAR(60) NOT NULL,
    provincia    VARCHAR(60) NOT NULL,
    fecha_inicio DATE        NOT NULL,
    fecha_fin    DATE,                   -- NULL = versión actual
    es_actual    BOOLEAN     NOT NULL DEFAULT TRUE
);

-- ------------------------------------------------------------
--  DIM_DESCUENTO
-- ------------------------------------------------------------
CREATE OR REPLACE TABLE DIM_DESCUENTO (
    id_descuento INTEGER PRIMARY KEY,
    descripcion  VARCHAR(80)   NOT NULL,
    porcentaje   DECIMAL(5,2)  NOT NULL,  -- 0.00 – 100.00
    fecha_inicio DATE          NOT NULL,
    fecha_fin    DATE          NOT NULL
);

-- ------------------------------------------------------------
--  FACT_VENTAS
--  Granularidad: una fila = una línea de venta
-- ------------------------------------------------------------
CREATE OR REPLACE TABLE FACT_VENTAS (
    id_venta           INTEGER PRIMARY KEY,
    id_mueble          INTEGER      NOT NULL REFERENCES DIM_MUEBLE(id_mueble),
    id_cliente_sk      INTEGER      NOT NULL REFERENCES DIM_CLIENTE(cliente_sk),
    id_tiempo          INTEGER      NOT NULL REFERENCES DIM_TIEMPO(id_tiempo),
    id_descuento       INTEGER      REFERENCES DIM_DESCUENTO(id_descuento),  -- nullable
    cantidad           INTEGER      NOT NULL CHECK (cantidad > 0),
    monto              DECIMAL(12,2) NOT NULL,
    descuento_aplicado DECIMAL(12,2) NOT NULL DEFAULT 0,
    ingreso_neto       DECIMAL(12,2) NOT NULL   -- monto - descuento_aplicado
);


--  2. DML — DATOS DE EJEMPLO

-- ── DIM_TIEMPO ──────────────────────────────────────────────
INSERT INTO DIM_TIEMPO VALUES
  (20230301, '2023-03-01', 1,  3,  'Marzo',      'Q1', 2023),
  (20230615, '2023-06-15', 15, 6,  'Junio',      'Q2', 2023),
  (20230901, '2023-09-01', 1,  9,  'Septiembre', 'Q3', 2023),
  (20231115, '2023-11-15', 15, 11, 'Noviembre',  'Q4', 2023),
  (20231210, '2023-12-10', 10, 12, 'Diciembre',  'Q4', 2023),
  (20240120, '2024-01-20', 20, 1,  'Enero',      'Q1', 2024),
  (20240315, '2024-03-15', 15, 3,  'Marzo',      'Q1', 2024),
  (20240510, '2024-05-10', 10, 5,  'Mayo',       'Q2', 2024),
  (20240820, '2024-08-20', 20, 8,  'Agosto',     'Q3', 2024),
  (20241105, '2024-11-05', 5,  11, 'Noviembre',  'Q4', 2024),
  (20241220, '2024-12-20', 20, 12, 'Diciembre',  'Q4', 2024),
  (20250210, '2025-02-10', 10, 2,  'Febrero',    'Q1', 2025),
  (20250405, '2025-04-05', 5,  4,  'Abril',      'Q2', 2025);

-- ── DIM_MUEBLE ──────────────────────────────────────────────
INSERT INTO DIM_MUEBLE VALUES
-- id  nombre                       precio    tipo          categoria    material
  (1,  'Silla Paris',               8500.00,  'Silla',      'Living',    'Madera'),
  (2,  'Mesa Roma',                45000.00,  'Mesa',       'Comedor',   'Madera'),
  (3,  'Armario Milán',            72000.00,  'Armario',    'Dormitorio','Madera'),
  (4,  'Silla Vienna',             12000.00,  'Silla',      'Oficina',   'Metal'),
  (5,  'Escritorio Berlín',        38000.00,  'Escritorio', 'Oficina',   'Madera'),
  (6,  'Mesada Atenas',            95000.00,  'Mesada',     'Cocina',    'Mármol'),
  (7,  'Taburete Tokio',            6500.00,  'Taburete',   'Cocina',    'Madera'),
  (8,  'Cama Praga',               85000.00,  'Cama',       'Dormitorio','Madera'),
  (9,  'Biblioteca Oslo',          52000.00,  'Biblioteca', 'Living',    'Madera'),
  (10, 'Sillón Cairo',             35000.00,  'Sillón',     'Living',    'Metal'),
  (11, 'Mesa Mármol Lisboa',       110000.00, 'Mesa',       'Comedor',   'Mármol'),
  (12, 'Gabinete Baño Estambul',   28000.00,  'Gabinete',   'Baño',      'Madera');

-- ── DIM_CLIENTE (con SCD-2 para cliente NK=3) ───────────────
-- Clientes sin cambio de ciudad (una sola versión)
INSERT INTO DIM_CLIENTE VALUES
-- sk   nk   nombre              ciudad          region         provincia       f_ini         f_fin    actual
  (1,   1,   'María García',     'Buenos Aires', 'GBA',         'Buenos Aires', '2020-01-01', NULL,    TRUE),
  (2,   2,   'Carlos Rodríguez', 'Córdoba',      'Centro',      'Córdoba',      '2020-01-01', NULL,    TRUE),
  (4,   4,   'Ana Martínez',     'Rosario',      'Litoral',     'Santa Fe',     '2020-01-01', NULL,    TRUE),
  (5,   5,   'Pedro Sánchez',    'Mendoza',      'Cuyo',        'Mendoza',      '2020-01-01', NULL,    TRUE),
  (6,   6,   'Laura López',      'Mar del Plata','Costa',       'Buenos Aires', '2020-01-01', NULL,    TRUE),
  (7,   7,   'Diego Fernández',  'Tucumán',      'NOA',         'Tucumán',      '2020-01-01', NULL,    TRUE),
  (8,   8,   'Sofía Torres',     'Salta',        'NOA',         'Salta',        '2020-01-01', NULL,    TRUE);

-- Cliente NK=3 (Juan Pérez) — SE MUDÓ: La Plata → Buenos Aires en marzo 2024
INSERT INTO DIM_CLIENTE VALUES
  (3,   3,   'Juan Pérez',       'La Plata',     'GBA',         'Buenos Aires', '2020-01-01', '2024-03-14', FALSE),  -- versión histórica
  (9,   3,   'Juan Pérez',       'Buenos Aires', 'GBA',         'Buenos Aires', '2024-03-15', NULL,         TRUE);   -- versión actual

-- ── DIM_DESCUENTO ───────────────────────────────────────────
INSERT INTO DIM_DESCUENTO VALUES
  (1, 'Promo Verano',       15.00, '2023-12-01', '2024-02-28'),
  (2, 'Liquidación Invierno',20.00, '2023-06-01', '2023-07-31'),
  (3, 'Black Friday',       25.00, '2023-11-24', '2023-11-30'),
  (4, 'Descuento Oficina',  10.00, '2024-01-01', '2024-12-31'),
  (5, 'Promo Verano 2025',  15.00, '2024-12-01', '2025-02-28');

-- ── FACT_VENTAS ─────────────────────────────────────────────
-- Formato: id, id_mueble, id_cliente_sk, id_tiempo, id_desc, cant, monto, desc_aplic, ingreso_neto
INSERT INTO FACT_VENTAS VALUES
-- 2023
  (1,  1,  1,  20230301, NULL, 4,  34000.00,    0.00,  34000.00),  -- María: 4 sillas Paris
  (2,  2,  2,  20230615, 2,    1,  45000.00, 9000.00,  36000.00),  -- Carlos: mesa (liq. invierno 20%)
  (3,  3,  3,  20230901, NULL, 2,  17000.00,    0.00,  17000.00),  -- Juan (La Plata): 2 taburetes Tokio
  (4,  8,  4,  20230901, NULL, 1,  85000.00,    0.00,  85000.00),  -- Ana: cama Praga
  (5,  4,  5,  20231115, 3,    6,  72000.00,18000.00,  54000.00),  -- Pedro: 6 sillas Vienna (Black Friday 25%)
  (6,  9,  6,  20231115, 3,    1,  52000.00,13000.00,  39000.00),  -- Laura: biblioteca Oslo (Black Friday)
  (7,  6,  1,  20231210, 1,    1,  95000.00,14250.00,  80750.00),  -- María: mesada Atenas (Promo Verano 15%)
  (8,  11, 7,  20231210, NULL, 1, 110000.00,    0.00, 110000.00),  -- Diego: mesa mármol Lisboa
  (9,  5,  2,  20231210, NULL, 2,  76000.00,    0.00,  76000.00),  -- Carlos: 2 escritorios Berlín
-- 2024
  (10, 1,  8,  20240120, 1,    8,  68000.00,10200.00,  57800.00),  -- Sofía: 8 sillas Paris (Promo Verano)
  (11, 4,  9,  20240120, 4,    4,  48000.00, 4800.00,  43200.00),  -- Juan (Bs As, SK=9): 4 sillas oficina (desc. oficina)
  (12, 5,  9,  20240315, 4,    1,  38000.00, 3800.00,  34200.00),  -- Juan (Bs As): escritorio Berlín
  (13, 3,  4,  20240510, NULL, 1,  72000.00,    0.00,  72000.00),  -- Ana: armario Milán
  (14, 12, 5,  20240510, NULL, 2,  56000.00,    0.00,  56000.00),  -- Pedro: 2 gabinetes baño
  (15, 10, 6,  20240820, NULL, 3, 105000.00,    0.00, 105000.00),  -- Laura: 3 sillones Cairo
  (16, 2,  1,  20240820, NULL, 1,  45000.00,    0.00,  45000.00),  -- María: mesa Roma
  (17, 8,  7,  20241105, NULL, 2, 170000.00,    0.00, 170000.00),  -- Diego: 2 camas Praga
  (18, 6,  3,  20241105, NULL, 1,  95000.00,    0.00,  95000.00),  -- Juan (histórico SK=3, venta pasada sin desc)
  (19, 1,  2,  20241220, 5,    6,  51000.00, 7650.00,  43350.00),  -- Carlos: 6 sillas (Promo Verano 2025)
  (20, 11, 8,  20241220, 5,    1, 110000.00,16500.00,  93500.00),  -- Sofía: mesa mármol (Promo Verano 2025)
-- 2025
  (21, 9,  4,  20250210, NULL, 1,  52000.00,    0.00,  52000.00),  -- Ana: biblioteca Oslo
  (22, 7,  5,  20250405, NULL, 4,  26000.00,    0.00,  26000.00),  -- Pedro: 4 taburetes Tokio
  (23, 3,  1,  20250405, NULL, 1,  72000.00,    0.00,  72000.00),  -- María: armario Milán
  (24, 4,  9,  20250405, 4,    3,  36000.00, 3600.00,  32400.00);  -- Juan (Bs As): 3 sillas oficina


--  3. QUERIES ANALÍTICAS DE EJEMPLO

-- Q1. Ventas totales por año
SELECT
    t.anio,
    COUNT(*)                        AS cantidad_transacciones,
    SUM(f.cantidad)                 AS unidades_vendidas,
    SUM(f.monto)                    AS monto_bruto,
    SUM(f.descuento_aplicado)       AS total_descuentos,
    SUM(f.ingreso_neto)             AS ingreso_neto_total
FROM FACT_VENTAS f
JOIN DIM_TIEMPO  t ON f.id_tiempo = t.id_tiempo
GROUP BY t.anio
ORDER BY t.anio;

-- Q2. Ingreso neto por categoría de mueble y año
SELECT
    m.categoria,
    t.anio,
    SUM(f.ingreso_neto)  AS ingreso_neto,
    SUM(f.cantidad)      AS unidades
FROM FACT_VENTAS f
JOIN DIM_MUEBLE m ON f.id_mueble  = m.id_mueble
JOIN DIM_TIEMPO t ON f.id_tiempo  = t.id_tiempo
GROUP BY m.categoria, t.anio
ORDER BY m.categoria, t.anio;

-- Q3. Top 5 muebles por ingreso neto total
SELECT
    m.nombre,
    m.tipo,
    m.categoria,
    m.material,
    SUM(f.cantidad)      AS unidades_vendidas,
    SUM(f.ingreso_neto)  AS ingreso_neto_total
FROM FACT_VENTAS f
JOIN DIM_MUEBLE m ON f.id_mueble = m.id_mueble
GROUP BY m.id_mueble, m.nombre, m.tipo, m.categoria, m.material
ORDER BY ingreso_neto_total DESC
LIMIT 5;

-- Q4. Ventas por provincia y material (drill-down geográfico)
SELECT
    c.provincia,
    m.material,
    SUM(f.ingreso_neto)  AS ingreso_neto,
    SUM(f.cantidad)      AS unidades
FROM FACT_VENTAS f
JOIN DIM_CLIENTE c ON f.id_cliente_sk = c.cliente_sk
JOIN DIM_MUEBLE  m ON f.id_mueble     = m.id_mueble
GROUP BY c.provincia, m.material
ORDER BY c.provincia, ingreso_neto DESC;

-- Q5. Impacto de los descuentos por campaña
SELECT
    d.descripcion,
    d.porcentaje,
    COUNT(*)                        AS ventas_con_descuento,
    SUM(f.monto)                    AS monto_bruto_total,
    SUM(f.descuento_aplicado)       AS total_descuentado,
    SUM(f.ingreso_neto)             AS ingreso_neto_total,
    ROUND(SUM(f.descuento_aplicado) / SUM(f.monto) * 100, 1) AS pct_real_descuento
FROM FACT_VENTAS   f
JOIN DIM_DESCUENTO d ON f.id_descuento = d.id_descuento
GROUP BY d.id_descuento, d.descripcion, d.porcentaje
ORDER BY total_descuentado DESC;

-- Q6. Demostración SCD-2: historial de ventas de Juan Pérez con ciudad correcta
SELECT
    t.fecha,
    c.nombre          AS cliente,
    c.ciudad          AS ciudad_en_momento_de_venta,
    c.es_actual,
    m.nombre          AS mueble,
    f.cantidad,
    f.ingreso_neto
FROM FACT_VENTAS f
JOIN DIM_CLIENTE c ON f.id_cliente_sk = c.cliente_sk
JOIN DIM_TIEMPO  t ON f.id_tiempo     = t.id_tiempo
JOIN DIM_MUEBLE  m ON f.id_mueble     = m.id_mueble
WHERE c.cliente_nk = 3
ORDER BY t.fecha;

-- Q7. Ventas por trimestre (roll-up temporal)
SELECT
    t.anio,
    t.trimestre,
    SUM(f.ingreso_neto)  AS ingreso_neto,
    COUNT(*)             AS transacciones
FROM FACT_VENTAS f
JOIN DIM_TIEMPO t ON f.id_tiempo = t.id_tiempo
GROUP BY t.anio, t.trimestre
ORDER BY t.anio, t.trimestre;
