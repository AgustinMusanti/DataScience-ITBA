--  DATA WAREHOUSE — CAMPAÑA DE SERVICIO DPF COLOMBIA

-- 0. Limpieza previa (idempotencia para re-ejecución)
DROP TABLE IF EXISTS fallas_reportadas CASCADE;
DROP TABLE IF EXISTS reclamos          CASCADE;
DROP TABLE IF EXISTS falla             CASCADE;
DROP TABLE IF EXISTS vehiculo          CASCADE;
DROP TABLE IF EXISTS sucursales        CASCADE;
DROP TABLE IF EXISTS concesionario     CASCADE;
DROP TABLE IF EXISTS ciudad            CASCADE;
DROP TABLE IF EXISTS departamento      CASCADE;
DROP TABLE IF EXISTS pais              CASCADE;
DROP TABLE IF EXISTS fecha             CASCADE;
DROP TABLE IF EXISTS dia               CASCADE;
DROP TABLE IF EXISTS mes               CASCADE;
DROP TABLE IF EXISTS anio              CASCADE;


-- =====================================================================
-- SECCIÓN 1 — DDL
-- =====================================================================

-- --- Dimensiones de tiempo (jerarquía año -> mes -> día -> fecha) -----
CREATE TABLE anio (
    id_anio     SERIAL PRIMARY KEY,
    numero_anio INT NOT NULL UNIQUE
);

CREATE TABLE mes (
    id_mes      SERIAL PRIMARY KEY,
    numero_mes  INT  NOT NULL,
    nombre_mes  VARCHAR(20) NOT NULL,
    id_anio     INT  NOT NULL REFERENCES anio(id_anio),
    UNIQUE (numero_mes, id_anio)
);

CREATE TABLE dia (
    id_dia      SERIAL PRIMARY KEY,
    numero_dia  INT  NOT NULL,
    id_mes      INT  NOT NULL REFERENCES mes(id_mes),
    UNIQUE (numero_dia, id_mes)
);

CREATE TABLE fecha (
    fecha       DATE PRIMARY KEY,
    id_dia      INT  NOT NULL REFERENCES dia(id_dia)
);

-- --- Dimensiones geográficas ------------------------------------------
CREATE TABLE pais (
    id_pais     SERIAL PRIMARY KEY,
    nombre_pais VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE departamento (
    id_departamento     SERIAL PRIMARY KEY,
    nombre_departamento VARCHAR(80) NOT NULL,
    id_pais             INT NOT NULL REFERENCES pais(id_pais),
    UNIQUE (nombre_departamento, id_pais)
);

CREATE TABLE ciudad (
    id_ciudad       SERIAL PRIMARY KEY,
    nombre_ciudad   VARCHAR(100) NOT NULL,
    id_departamento INT NOT NULL REFERENCES departamento(id_departamento)
);

-- --- Red comercial ----------------------------------------------------
CREATE TABLE concesionario (
    id_concesionario SERIAL PRIMARY KEY,
    nombre_comercial VARCHAR(120) NOT NULL
);

CREATE TABLE sucursales (
    id_sucursal      SERIAL PRIMARY KEY,
    id_concesionario INT NOT NULL REFERENCES concesionario(id_concesionario),
    nombre_sucursal  VARCHAR(150) NOT NULL,
    id_ciudad        INT NOT NULL REFERENCES ciudad(id_ciudad)
);

-- --- Catálogo de fallas ----------------------------------------------
CREATE TABLE falla (
    id_falla          SERIAL PRIMARY KEY,
    descripcion_falla VARCHAR(200) NOT NULL,
    numero_falla      VARCHAR(20)  NOT NULL UNIQUE   -- código DTC
);

-- --- Vehículo ---------------------------------------------------------
CREATE TABLE vehiculo (
    id_vehiculo         SERIAL PRIMARY KEY,
    numero_chasis       VARCHAR(20) NOT NULL UNIQUE,
    linea               VARCHAR(50) NOT NULL,
    planta_productora   VARCHAR(50) NOT NULL,
    fecha_produccion    DATE NOT NULL REFERENCES fecha(fecha),
    warranty_start_date DATE          REFERENCES fecha(fecha),     -- NULL = stock
    last_cal_update_date DATE         REFERENCES fecha(fecha)
);

-- --- HECHO 1: reclamos -----------------------------------------------
CREATE TABLE reclamos (
    id_reclamo            SERIAL PRIMARY KEY,
    id_vehiculo           INT  NOT NULL REFERENCES vehiculo(id_vehiculo),
    id_sucursal           INT  NOT NULL REFERENCES sucursales(id_sucursal),
    fecha_ingreso         DATE NOT NULL REFERENCES fecha(fecha),
    fecha_solicitud_pieza DATE          REFERENCES fecha(fecha),
    fecha_resolucion      DATE          REFERENCES fecha(fecha),
    reclamo               VARCHAR(200),
    dias_diagnostico      INT,
    dias_espera_pieza     INT,
    dias_total_diagnostico INT,
    CHECK (fecha_solicitud_pieza IS NULL OR fecha_solicitud_pieza >= fecha_ingreso),
    CHECK (fecha_resolucion      IS NULL OR fecha_resolucion      >= fecha_solicitud_pieza)
);

-- --- HECHO 2: fallas_reportadas --------------------------------------
CREATE TABLE fallas_reportadas (
    id_falla    INT NOT NULL REFERENCES falla(id_falla),
    id_vehiculo INT NOT NULL REFERENCES vehiculo(id_vehiculo),
    id_reclamo  INT NOT NULL REFERENCES reclamos(id_reclamo),
    cantidad    INT NOT NULL DEFAULT 1,
    PRIMARY KEY (id_falla, id_vehiculo, id_reclamo)
);


-- =====================================================================
-- SECCIÓN 2 — CARGA DE DIMENSIONES BASE
-- =====================================================================

-- --- País -------------------------------------------------------------
INSERT INTO pais (nombre_pais) VALUES ('Colombia');

-- --- Departamentos reales de Colombia (subset relevante) -------------
INSERT INTO departamento (nombre_departamento, id_pais)
SELECT d, 1
FROM (VALUES
    ('Bogotá D.C.'),       -- alta concentración
    ('Antioquia'),         -- alta concentración (Medellín)
    ('Atlántico'),         -- costa atlántica - alta
    ('Bolívar'),           -- costa atlántica
    ('Magdalena'),         -- costa atlántica
    ('Córdoba'),           -- costa atlántica
    ('Sucre'),             -- costa atlántica
    ('La Guajira'),        -- costa atlántica
    ('Cesar'),             -- costa atlántica
    ('Valle del Cauca'),
    ('Cundinamarca'),
    ('Santander'),
    ('Norte de Santander'),
    ('Tolima'),
    ('Huila'),
    ('Nariño'),
    ('Cauca'),
    ('Boyacá'),
    ('Caldas'),
    ('Risaralda'),
    ('Quindío'),
    ('Meta')
) AS t(d);

-- --- Ciudades coherentes con cada departamento -----------------------
INSERT INTO ciudad (nombre_ciudad, id_departamento)
SELECT c.nombre, d.id_departamento
FROM (VALUES
    ('Bogotá',          'Bogotá D.C.'),
    ('Medellín',        'Antioquia'),
    ('Bello',           'Antioquia'),
    ('Envigado',        'Antioquia'),
    ('Itagüí',          'Antioquia'),
    ('Rionegro',        'Antioquia'),
    ('Barranquilla',    'Atlántico'),
    ('Soledad',         'Atlántico'),
    ('Malambo',         'Atlántico'),
    ('Cartagena',       'Bolívar'),
    ('Magangué',        'Bolívar'),
    ('Santa Marta',     'Magdalena'),
    ('Ciénaga',         'Magdalena'),
    ('Montería',        'Córdoba'),
    ('Lorica',          'Córdoba'),
    ('Sincelejo',       'Sucre'),
    ('Riohacha',        'La Guajira'),
    ('Maicao',          'La Guajira'),
    ('Valledupar',      'Cesar'),
    ('Cali',            'Valle del Cauca'),
    ('Palmira',         'Valle del Cauca'),
    ('Buenaventura',    'Valle del Cauca'),
    ('Soacha',          'Cundinamarca'),
    ('Zipaquirá',       'Cundinamarca'),
    ('Bucaramanga',     'Santander'),
    ('Floridablanca',   'Santander'),
    ('Cúcuta',          'Norte de Santander'),
    ('Ibagué',          'Tolima'),
    ('Neiva',           'Huila'),
    ('Pasto',           'Nariño'),
    ('Popayán',         'Cauca'),
    ('Tunja',           'Boyacá'),
    ('Duitama',         'Boyacá'),
    ('Manizales',       'Caldas'),
    ('Pereira',         'Risaralda'),
    ('Dosquebradas',    'Risaralda'),
    ('Armenia',         'Quindío'),
    ('Villavicencio',   'Meta')
) AS c(nombre, depto)
JOIN departamento d ON d.nombre_departamento = c.depto;

-- --- Concesionarios (mix cadenas grandes + boutique) -----------------
INSERT INTO concesionario (nombre_comercial)
SELECT 'Concesionario ' || nombre
FROM (VALUES
    ('AutoNorte'),       -- cadena grande
    ('MotorAndino'),     -- cadena grande
    ('CaribeMotors'),    -- cadena grande costa
    ('PacificoAuto'),    -- mediano
    ('CentralCars'),     -- mediano
    ('AltiplanoVehiculos'),  -- chico
    ('LosAndesAutos'),   -- chico
    ('SurMotor'),        -- chico
    ('CafeteroAuto'),    -- chico
    ('CapitalDiesel')    -- chico
) AS x(nombre);

-- --- Sucursales: las cadenas grandes con muchas sucursales -----------
-- AutoNorte (id=1): 25 sucursales, sesgo Bogotá/Antioquia
-- MotorAndino (id=2): 20, sesgo Bogotá
-- CaribeMotors (id=3): 18, sesgo costa atlántica
-- PacificoAuto (id=4): 8
-- CentralCars (id=5): 6
-- resto: 1-2

-- helper: lista de id_ciudad por región para sesgar
-- ciudades_bogota = (1)  -- Bogotá
-- ciudades_antioquia: 2..6
-- ciudades_costa: 7..19  (Atlántico->Cesar)
-- resto: 20..38

-- AutoNorte: fuerte en Bogotá + Antioquia
INSERT INTO sucursales (id_concesionario, nombre_sucursal, id_ciudad)
SELECT 1,
       'AutoNorte Sucursal ' || gs,
       CASE
           WHEN gs % 3 = 0 THEN 1                              -- Bogotá
           WHEN gs % 3 = 1 THEN 2 + (gs % 5)                   -- Antioquia (ids 2..6)
           ELSE 20 + (gs % 19)                                 -- resto del país
       END
FROM generate_series(1, 25) gs;

-- MotorAndino: capital + andes
INSERT INTO sucursales (id_concesionario, nombre_sucursal, id_ciudad)
SELECT 2,
       'MotorAndino Sucursal ' || gs,
       CASE
           WHEN gs % 2 = 0 THEN 1
           ELSE 20 + (gs % 19)
       END
FROM generate_series(1, 20) gs;

-- CaribeMotors: costa atlántica (ids 7..19)
INSERT INTO sucursales (id_concesionario, nombre_sucursal, id_ciudad)
SELECT 3,
       'CaribeMotors Sucursal ' || gs,
       7 + (gs % 13)
FROM generate_series(1, 18) gs;

-- PacificoAuto: pacífico/sur
INSERT INTO sucursales (id_concesionario, nombre_sucursal, id_ciudad)
SELECT 4,
       'PacificoAuto Sucursal ' || gs,
       20 + (gs % 19)
FROM generate_series(1, 8) gs;

-- CentralCars: zona central
INSERT INTO sucursales (id_concesionario, nombre_sucursal, id_ciudad)
SELECT 5,
       'CentralCars Sucursal ' || gs,
       1 + (gs % 38)
FROM generate_series(1, 6) gs;

-- Concesionarios chicos: 1 sucursal cada uno
INSERT INTO sucursales (id_concesionario, nombre_sucursal, id_ciudad) VALUES
    (6,  'AltiplanoVehiculos Central',     1),       -- Bogotá
    (7,  'LosAndesAutos Principal',        2),       -- Medellín
    (8,  'SurMotor Pasto',                 30),      -- Pasto
    (9,  'CafeteroAuto Pereira',           35),      -- Pereira
    (10, 'CapitalDiesel Bogotá',           1);       -- Bogotá

-- --- Catálogo de fallas (con P2002 + otras DTC realistas) ------------
INSERT INTO falla (descripcion_falla, numero_falla) VALUES
    ('Eficiencia del Filtro de Partículas Diésel (DPF) por debajo del umbral', 'P2002'),
    ('Sensor de presión diferencial DPF - señal fuera de rango',               'P2453'),
    ('Sensor de temperatura de escape - circuito alto',                        'P0546'),
    ('Regeneración DPF incompleta',                                            'P244A'),
    ('Inyector cilindro 1 - circuito abierto',                                 'P0201'),
    ('Inyector cilindro 2 - circuito abierto',                                 'P0202'),
    ('Sistema EGR - flujo insuficiente',                                       'P0401'),
    ('Sensor MAF - señal baja',                                                'P0102'),
    ('Sensor de oxígeno bank 1 - lento',                                       'P0133'),
    ('Turbocompresor - presión baja',                                          'P0299'),
    ('Sistema de combustible - presión rail baja',                             'P0087'),
    ('Bujía precalentamiento cilindro 1',                                      'P0671');


-- =====================================================================
-- SECCIÓN 3 — DIMENSIONES DE TIEMPO
-- =====================================================================
-- Cubrimos 2018-01-01 .. 2026-12-31 para soportar:
--   * fecha_produccion (vehículos viejos)
--   * warranty_start_date
--   * fecha_ingreso / solicitud / resolución de reclamos
--   * last_cal_update_date

-- Años
INSERT INTO anio (numero_anio)
SELECT y FROM generate_series(2018, 2026) y;

-- Meses
INSERT INTO mes (numero_mes, nombre_mes, id_anio)
SELECT m,
       CASE m WHEN 1 THEN 'Enero' WHEN 2 THEN 'Febrero' WHEN 3 THEN 'Marzo'
              WHEN 4 THEN 'Abril' WHEN 5 THEN 'Mayo' WHEN 6 THEN 'Junio'
              WHEN 7 THEN 'Julio' WHEN 8 THEN 'Agosto' WHEN 9 THEN 'Septiembre'
              WHEN 10 THEN 'Octubre' WHEN 11 THEN 'Noviembre' WHEN 12 THEN 'Diciembre'
       END,
       a.id_anio
FROM anio a
CROSS JOIN generate_series(1, 12) m;

-- Días (sólo los válidos por mes)
INSERT INTO dia (numero_dia, id_mes)
SELECT EXTRACT(DAY FROM d)::INT, m.id_mes
FROM mes m
JOIN anio a ON a.id_anio = m.id_anio
CROSS JOIN LATERAL generate_series(
    make_date(a.numero_anio, m.numero_mes, 1),
    (make_date(a.numero_anio, m.numero_mes, 1) + INTERVAL '1 month - 1 day')::date,
    INTERVAL '1 day'
) d;

-- Fechas (PK = date)
INSERT INTO fecha (fecha, id_dia)
SELECT d.fecha, dia.id_dia
FROM generate_series('2018-01-01'::date, '2026-12-31'::date, '1 day') d(fecha)
JOIN mes m ON m.numero_mes = EXTRACT(MONTH FROM d.fecha)::INT
JOIN anio a ON a.id_anio = m.id_anio AND a.numero_anio = EXTRACT(YEAR FROM d.fecha)::INT
JOIN dia ON dia.id_mes = m.id_mes AND dia.numero_dia = EXTRACT(DAY FROM d.fecha)::INT;


-- =====================================================================
-- SECCIÓN 4 — VEHÍCULOS (50.000)
-- =====================================================================
-- Reglas:
--   * 80% producidos ANTES del 2023-02-26  (afectados)
--   * 20% producidos a partir de esa fecha (no afectados, con cal actualizada)
--   * ~15% sin warranty_start_date (stock)
--   * plantas: Argentina, Brasil, México, Colombia (proveedor DPF: Argentina)
--   * líneas: 6 modelos diésel

INSERT INTO vehiculo (numero_chasis, linea, planta_productora,
                      fecha_produccion, warranty_start_date, last_cal_update_date)
SELECT
    'CHS' || LPAD(gs::text, 8, '0'),
    (ARRAY['Hilux','Ranger','Amarok','Frontier','S10','D-Max'])[1 + (gs % 6)],
    -- distribución por planta: 50% Argentina, 25% Brasil, 15% México, 10% Colombia
    CASE
        WHEN gs % 100 < 50 THEN 'Argentina'
        WHEN gs % 100 < 75 THEN 'Brasil'
        WHEN gs % 100 < 90 THEN 'México'
        ELSE 'Colombia'
    END AS planta_productora,
    -- fecha_produccion: 80% antes de 2023-02-26, 20% después
    CASE
        WHEN gs % 10 < 8 THEN
            -- afectados: entre 2019-01-01 y 2023-02-25
            ('2019-01-01'::date + ((random() * 1516)::int))
        ELSE
            -- no afectados: entre 2023-02-26 y 2025-12-31
            ('2023-02-26'::date + ((random() * 1039)::int))
    END AS fecha_produccion,
    NULL::date,  -- placeholder, lo seteamos en el UPDATE de abajo
    NULL::date
FROM generate_series(1, 50000) gs;

-- Setear warranty_start_date y last_cal_update_date con coherencia.
-- LEAST(..., '2026-12-31') asegura que nunca caigamos fuera de la dim fecha.
UPDATE vehiculo SET
    warranty_start_date = CASE
        WHEN random() < 0.15 THEN NULL                                              -- 15% stock
        ELSE LEAST(fecha_produccion + ((30 + random() * 180)::int), DATE '2026-12-31')
    END,
    last_cal_update_date = CASE
        WHEN fecha_produccion < DATE '2023-02-26' THEN NULL                         -- pendientes de campaña
        ELSE LEAST(fecha_produccion + ((1 + random() * 15)::int), DATE '2026-12-31')
    END;


-- =====================================================================
-- SECCIÓN 5 — RECLAMOS (80.000)
-- =====================================================================
-- Reglas:
--   * Solo vehículos con warranty_start_date NO NULL pueden tener reclamos
--     (los de stock NO se reclaman porque no se vendieron)
--   * fecha_ingreso >= warranty_start_date
--   * fecha_ingreso <= fecha_solicitud_pieza <= fecha_resolucion
--   * dias_diagnostico ∈ [1,5]
--   * dias_espera_pieza ∈ [5,30]
--   * ~5% sin resolución (casos abiertos)
--   * sesgo geográfico: 60% en sucursales de Bogotá / Antioquia / Costa Atlántica
--   * vehículos afectados (pre-2023-02-26) concentran ~85% de los reclamos
--   * algunos vehículos sin reclamos, otros con múltiples

-- Pool de vehículos elegibles (vendidos)
-- Pesamos los afectados x6 para que concentren el grueso de los reclamos
WITH vehiculos_vendidos AS (
    SELECT id_vehiculo, fecha_produccion, warranty_start_date,
           CASE WHEN fecha_produccion < '2023-02-26' THEN 6 ELSE 1 END AS peso
    FROM vehiculo
    WHERE warranty_start_date IS NOT NULL
),
pool AS (
    SELECT id_vehiculo, fecha_produccion, warranty_start_date
    FROM vehiculos_vendidos,
         LATERAL generate_series(1, peso)
),
-- Sucursales con peso geográfico
sucursales_pesadas AS (
    SELECT s.id_sucursal, s.id_ciudad,
           CASE
               WHEN s.id_ciudad = 1                  THEN 8   -- Bogotá
               WHEN s.id_ciudad BETWEEN 2 AND 6      THEN 6   -- Antioquia
               WHEN s.id_ciudad BETWEEN 7 AND 19     THEN 5   -- Costa Atlántica
               ELSE 1
           END AS peso
    FROM sucursales s
),
suc_pool AS (
    SELECT id_sucursal
    FROM sucursales_pesadas, LATERAL generate_series(1, peso)
),
-- Sampleamos 80.000 vehículos del pool (con reemplazo => múltiples reclamos por vehículo)
vehiculos_sample AS (
    SELECT id_vehiculo, fecha_produccion, warranty_start_date,
           ROW_NUMBER() OVER (ORDER BY random()) AS rn
    FROM pool
    ORDER BY random()
    LIMIT 80000
),
sucursales_sample AS (
    SELECT id_sucursal,
           ROW_NUMBER() OVER (ORDER BY random()) AS rn
    FROM (
        SELECT id_sucursal FROM suc_pool ORDER BY random() LIMIT 80000
    ) x
),
joined AS (
    SELECT v.id_vehiculo,
           s.id_sucursal,
           v.warranty_start_date,
           -- fecha_ingreso entre warranty_start y 2026-05-15
           v.warranty_start_date + ((random() *
               GREATEST(1,
                   ('2026-05-15'::date - v.warranty_start_date)::int
               ))::int) AS fecha_ingreso,
           (1 + (random() * 4)::int)  AS d_diag,    -- 1..5
           (5 + (random() * 25)::int) AS d_esp,     -- 5..30
           random() AS r_open
    FROM vehiculos_sample v
    JOIN sucursales_sample s ON v.rn = s.rn
)
INSERT INTO reclamos (id_vehiculo, id_sucursal, fecha_ingreso,
                      fecha_solicitud_pieza, fecha_resolucion,
                      reclamo, dias_diagnostico, dias_espera_pieza,
                      dias_total_diagnostico)
SELECT
    id_vehiculo,
    id_sucursal,
    fecha_ingreso,
    LEAST(fecha_ingreso + d_diag, DATE '2026-12-31') AS f_solicitud,
    CASE WHEN r_open < 0.05 THEN NULL                                        -- 5% casos abiertos
         ELSE LEAST(fecha_ingreso + d_diag + d_esp, DATE '2026-12-31') END,
    'Reclamo postventa - revisión sistema DPF / motor diésel',
    d_diag,
    CASE WHEN r_open < 0.05 THEN NULL ELSE d_esp END,
    CASE WHEN r_open < 0.05 THEN NULL ELSE d_diag + d_esp END
FROM joined
-- garantizamos que fecha_ingreso quede dentro del rango de la dim fecha
WHERE fecha_ingreso <= DATE '2026-05-15';


-- =====================================================================
-- SECCIÓN 6 — FALLAS_REPORTADAS (120.000+)
-- =====================================================================
-- Reglas:
--   * Cada reclamo tiene entre 1 y 3 fallas (en promedio 1.5)
--   * P2002 (id_falla=1) es la falla dominante en vehículos pre-2023-02-26
--     (60% de las fallas de esos reclamos)
--   * Otros DTC aparecen como ruido y para reclamos no-P2002
--   * Un mismo vehículo puede tener múltiples reclamos con P2002 en el tiempo
--     (ya implícito porque distintos id_reclamo => evento independiente)

-- Pre-cargamos cantidad de fallas por reclamo (1..3)
WITH reclamo_nfallas AS (
    SELECT r.id_reclamo,
           r.id_vehiculo,
           v.fecha_produccion,
           (1 + (random() * 2)::int) AS n_fallas    -- 1, 2 o 3
    FROM reclamos r
    JOIN vehiculo v ON v.id_vehiculo = r.id_vehiculo
),
-- Expandimos en filas (1 fila por falla a reportar)
expandido AS (
    SELECT id_reclamo, id_vehiculo, fecha_produccion,
           gs AS slot
    FROM reclamo_nfallas, LATERAL generate_series(1, n_fallas) gs
),
-- Asignamos id_falla:
-- - Para vehículos afectados (pre-2023-02-26):
--     slot=1 => P2002 con 70% prob, sino otra DTC
--     slot>1 => 30% P2002, 70% otras
-- - Para vehículos no afectados:
--     P2002 sólo con 5% prob, mayormente otras DTC
asignado AS (
    SELECT id_reclamo, id_vehiculo, slot,
           CASE
             WHEN fecha_produccion < '2023-02-26' THEN
                CASE WHEN slot = 1 AND random() < 0.70 THEN 1
                     WHEN slot > 1 AND random() < 0.30 THEN 1
                     ELSE 2 + (random() * 10)::int        -- ids 2..11 (otras fallas)
                END
             ELSE
                CASE WHEN random() < 0.05 THEN 1
                     ELSE 2 + (random() * 10)::int
                END
           END AS id_falla
    FROM expandido
)
INSERT INTO fallas_reportadas (id_falla, id_vehiculo, id_reclamo, cantidad)
SELECT id_falla, id_vehiculo, id_reclamo,
       -- cantidad: P2002 puede repetirse 1-3 veces en mismo reclamo (eventos)
       CASE WHEN id_falla = 1 THEN 1 + (random() * 2)::int ELSE 1 END
FROM asignado
ON CONFLICT (id_falla, id_vehiculo, id_reclamo) DO NOTHING;   -- evita PK duplicada


-- =====================================================================
-- SECCIÓN 7 — ÍNDICES PARA PERFORMANCE ANALÍTICA
-- =====================================================================
-- Foreign keys e índices que aceleran joins/agregaciones típicas de DW

-- Vehiculo
CREATE INDEX idx_vehiculo_planta        ON vehiculo(planta_productora);
CREATE INDEX idx_vehiculo_linea         ON vehiculo(linea);
CREATE INDEX idx_vehiculo_fecha_prod    ON vehiculo(fecha_produccion);
CREATE INDEX idx_vehiculo_warranty      ON vehiculo(warranty_start_date);

-- Reclamos
CREATE INDEX idx_reclamos_vehiculo      ON reclamos(id_vehiculo);
CREATE INDEX idx_reclamos_sucursal      ON reclamos(id_sucursal);
CREATE INDEX idx_reclamos_fecha_ing     ON reclamos(fecha_ingreso);
CREATE INDEX idx_reclamos_fecha_res     ON reclamos(fecha_resolucion);

-- Fallas reportadas
CREATE INDEX idx_freport_falla          ON fallas_reportadas(id_falla);
CREATE INDEX idx_freport_vehiculo       ON fallas_reportadas(id_vehiculo);
CREATE INDEX idx_freport_reclamo        ON fallas_reportadas(id_reclamo);

-- Geografía
CREATE INDEX idx_sucursal_ciudad        ON sucursales(id_ciudad);
CREATE INDEX idx_sucursal_concesionario ON sucursales(id_concesionario);
CREATE INDEX idx_ciudad_depto           ON ciudad(id_departamento);
CREATE INDEX idx_depto_pais             ON departamento(id_pais);

-- Tiempo
CREATE INDEX idx_dia_mes                ON dia(id_mes);
CREATE INDEX idx_mes_anio               ON mes(id_anio);


-- SECCIÓN 8 — VERIFICACIONES RÁPIDAS (opcionales)

-- Distribución de reclamos por región (validar sesgo geográfico):
-- SELECT d.nombre_departamento, COUNT(*) AS qty
-- FROM reclamos r
-- JOIN sucursales s ON s.id_sucursal = r.id_sucursal
-- JOIN ciudad c     ON c.id_ciudad = s.id_ciudad
-- JOIN departamento d ON d.id_departamento = c.id_departamento
-- GROUP BY d.nombre_departamento
-- ORDER BY qty DESC;

-- Vehículos afectados (pre-2023-02-26) con P2002 activo:
-- SELECT COUNT(DISTINCT fr.id_vehiculo)
-- FROM fallas_reportadas fr
-- JOIN vehiculo v ON v.id_vehiculo = fr.id_vehiculo
-- WHERE fr.id_falla = 1
--   AND v.fecha_produccion < '2023-02-26';
