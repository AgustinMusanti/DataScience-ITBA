/*
   Data Warehouse — Campaña de servicio DPF Colombia

   Esquema estrella con dos tablas de hechos:
       reclamos           (un reclamo por ingreso del vehículo al taller)
       fallas_reportadas  (acumulado de fallas por vehículo, una fila por
                           combinación de falla + vehículo)

   El resto son dimensiones: vehiculo, falla, sucursales, concesionario,
   ciudad, departamento, pais y fecha.

   Nota importante sobre fallas_reportadas:
   La PK compuesta es (id_falla, id_vehiculo), así que cada vehículo tiene
   como máximo una fila por código de falla. El campo cantidad acumula
   cuántas veces se reportó esa falla en ese vehículo a lo largo del tiempo,
   y fecha_falla guarda la fecha de referencia del evento.
*/


-- Limpieza previa para poder re-ejecutar el script sin romper nada
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


-- ========================= DDL =========================

-- Dimensión de tiempo desnormalizada (una fila por fecha del calendario)
CREATE TABLE fecha (
    fecha       DATE PRIMARY KEY,
    numero_dia  INT  NOT NULL,
    numero_mes  INT  NOT NULL,
    nombre_mes  VARCHAR(20) NOT NULL
);

-- Jerarquía geográfica: pais -> departamento -> ciudad
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

-- Red comercial: un concesionario puede tener varias sucursales
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

-- Catálogo de fallas (códigos DTC)
CREATE TABLE falla (
    id_falla          SERIAL PRIMARY KEY,
    descripcion_falla VARCHAR(200) NOT NULL,
    numero_falla      VARCHAR(20)  NOT NULL UNIQUE
);

-- Vehículo con PK compuesta (id_vehiculo, numero_chasis) según modelo.
-- warranty_start_date NULL = unidad todavía en stock, no se vendió.
-- last_cal_update_date NOT NULL = vehículo ya intervenido en la campaña.
CREATE TABLE vehiculo (
    id_vehiculo          INT NOT NULL,
    numero_chasis        VARCHAR(20) NOT NULL,
    linea                VARCHAR(50) NOT NULL,
    transmision          VARCHAR(20) NOT NULL,
    modelo               VARCHAR(50) NOT NULL,
    version              VARCHAR(50) NOT NULL,
    planta_productora    VARCHAR(50) NOT NULL,
    fecha_produccion     DATE NOT NULL REFERENCES fecha(fecha),
    warranty_start_date  DATE          REFERENCES fecha(fecha),
    last_cal_update_date DATE          REFERENCES fecha(fecha),
    PRIMARY KEY (id_vehiculo, numero_chasis)
);
-- Secuencia explícita para id_vehiculo (al ser PK compuesta no podemos usar SERIAL directo)
CREATE SEQUENCE vehiculo_id_seq OWNED BY vehiculo.id_vehiculo;
ALTER TABLE vehiculo ALTER COLUMN id_vehiculo SET DEFAULT nextval('vehiculo_id_seq');

-- Hecho: cada reclamo es un ingreso al taller con su trazabilidad de tiempos.
-- dias_total_diagnostico = dias_diagnostico + dias_espera_pieza.
-- La FK referencia solo id_vehiculo de la PK compuesta de vehiculo, así que
-- creamos primero un índice único sobre esa columna.
CREATE UNIQUE INDEX ux_vehiculo_id ON vehiculo(id_vehiculo);

CREATE TABLE reclamos (
    id_reclamo             SERIAL PRIMARY KEY,
    id_vehiculo            INT  NOT NULL REFERENCES vehiculo(id_vehiculo),
    id_sucursal            INT  NOT NULL REFERENCES sucursales(id_sucursal),
    fecha_ingreso          DATE NOT NULL REFERENCES fecha(fecha),
    fecha_solicitud_pieza  DATE          REFERENCES fecha(fecha),
    fecha_resolucion       DATE          REFERENCES fecha(fecha),
    reclamo                VARCHAR(200),
    dias_diagnostico       INT,
    dias_espera_pieza      INT,
    dias_total_diagnostico INT,
    CHECK (fecha_solicitud_pieza IS NULL OR fecha_solicitud_pieza >= fecha_ingreso),
    CHECK (fecha_resolucion      IS NULL OR fecha_resolucion      >= fecha_solicitud_pieza)
);

-- Hecho: una fila por combinación de falla y vehículo. La columna cantidad
-- acumula cuántas veces se levantó ese DTC en ese vehículo, y fecha_falla
-- guarda la fecha de referencia (en la carga inicial usamos la última ocurrencia).
CREATE TABLE fallas_reportadas (
    id_falla    INT  NOT NULL REFERENCES falla(id_falla),
    id_vehiculo INT  NOT NULL REFERENCES vehiculo(id_vehiculo),
    fecha_falla DATE NOT NULL REFERENCES fecha(fecha),
    cantidad    INT  NOT NULL DEFAULT 1,
    PRIMARY KEY (id_falla, id_vehiculo)
);


/*
   ================= Inserción de datos sintéticos =================

   Para llegar a un volumen alto no tiene sentido escribir un INSERT por fila: serían millones de líneas
   imposibles de mantener. En lugar de eso usamos generate_series como motor
   de generación y random() para introducir variabilidad realista.

   La lógica es:
     1) generate_series(1, N) genera N filas "vacías"
     2) sobre cada fila aplico expresiones con random(), CASE y aritmética
        para inventar valores plausibles (chasis, fechas, líneas, etc.)
     3) cuando algo depende de otra tabla (p. ej. un reclamo necesita un
        vehículo válido), uso CTEs con joins por número de fila para
        garantizar integridad referencial.

   Los pesos y porcentajes que aparecen abajo (80% afectados, 15% stock,
   sesgo geográfico Bogotá/Antioquia/Costa, etc.) están elegidos para
   reflejar el caso de negocio: vehículos pre-2023-02-26 son los que
   concentran el problema y por eso reciben la mayor parte de los reclamos.
*/


-- País único del caso
INSERT INTO pais (nombre_pais) VALUES ('Colombia');

-- Departamentos reales de Colombia. Los primeros nueve son los relevantes
-- para el análisis (Bogotá, Antioquia y la franja de la costa atlántica)
-- concentramos el sesgo de fallas ahí.
INSERT INTO departamento (nombre_departamento, id_pais)
SELECT d, 1
FROM (VALUES
    ('Bogotá D.C.'),
    ('Antioquia'),
    ('Atlántico'),
    ('Bolívar'),
    ('Magdalena'),
    ('Córdoba'),
    ('Sucre'),
    ('La Guajira'),
    ('Cesar'),
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

-- Ciudades asociadas a su departamento real
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

-- Concesionarios: mezclamos cadenas grandes con boutiques de una sola sucursal
INSERT INTO concesionario (nombre_comercial)
SELECT 'Concesionario ' || nombre
FROM (VALUES
    ('AutoNorte'),
    ('MotorAndino'),
    ('CaribeMotors'),
    ('PacificoAuto'),
    ('CentralCars'),
    ('AltiplanoVehiculos'),
    ('LosAndesAutos'),
    ('SurMotor'),
    ('CafeteroAuto'),
    ('CapitalDiesel')
) AS x(nombre);

-- AutoNorte y MotorAndino son las cadenas grandes con presencia en Bogotá
-- y Antioquia. CaribeMotors concentra la costa. El resto son chicos.
INSERT INTO sucursales (id_concesionario, nombre_sucursal, id_ciudad)
SELECT 1,
       'AutoNorte Sucursal ' || gs,
       CASE
           WHEN gs % 3 = 0 THEN 1
           WHEN gs % 3 = 1 THEN 2 + (gs % 5)
           ELSE 20 + (gs % 19)
       END
FROM generate_series(1, 25) gs;

INSERT INTO sucursales (id_concesionario, nombre_sucursal, id_ciudad)
SELECT 2,
       'MotorAndino Sucursal ' || gs,
       CASE
           WHEN gs % 2 = 0 THEN 1
           ELSE 20 + (gs % 19)
       END
FROM generate_series(1, 20) gs;

INSERT INTO sucursales (id_concesionario, nombre_sucursal, id_ciudad)
SELECT 3,
       'CaribeMotors Sucursal ' || gs,
       7 + (gs % 13)
FROM generate_series(1, 18) gs;

INSERT INTO sucursales (id_concesionario, nombre_sucursal, id_ciudad)
SELECT 4,
       'PacificoAuto Sucursal ' || gs,
       20 + (gs % 19)
FROM generate_series(1, 8) gs;

INSERT INTO sucursales (id_concesionario, nombre_sucursal, id_ciudad)
SELECT 5,
       'CentralCars Sucursal ' || gs,
       1 + (gs % 38)
FROM generate_series(1, 6) gs;

INSERT INTO sucursales (id_concesionario, nombre_sucursal, id_ciudad) VALUES
    (6,  'AltiplanoVehiculos Central', 1),
    (7,  'LosAndesAutos Principal',    2),
    (8,  'SurMotor Pasto',             30),
    (9,  'CafeteroAuto Pereira',       35),
    (10, 'CapitalDiesel Bogotá',       1);

-- Catálogo de DTC. La id=1 es P2002 (el código del caso) y el resto son
-- DTC reales del mundo diésel que sirven como "ruido" en los reclamos.
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


-- Calendario 2018-01-01 a 2026-12-31, suficiente para producción, garantías
-- e ingresos al taller a lo largo de toda la ventana del caso.
INSERT INTO fecha (fecha, numero_dia, numero_mes, nombre_mes)
SELECT d::date,
       EXTRACT(DAY   FROM d)::int,
       EXTRACT(MONTH FROM d)::int,
       CASE EXTRACT(MONTH FROM d)::int
            WHEN 1 THEN 'Enero'    WHEN 2 THEN 'Febrero'   WHEN 3 THEN 'Marzo'
            WHEN 4 THEN 'Abril'    WHEN 5 THEN 'Mayo'      WHEN 6 THEN 'Junio'
            WHEN 7 THEN 'Julio'    WHEN 8 THEN 'Agosto'    WHEN 9 THEN 'Septiembre'
            WHEN 10 THEN 'Octubre' WHEN 11 THEN 'Noviembre' WHEN 12 THEN 'Diciembre'
       END
FROM generate_series('2018-01-01'::date, '2026-12-31'::date, '1 day') d;


-- La planta es mayormente Argentina porque el proveedor del DPF está allá.
-- Líneas, modelos, versiones y transmisión se sortean dentro de catálogos
-- de Ford realmente disponibles en Colombia y Latinoamérica.
-- linea  = segmento/familia del vehículo (Pickup, SUV, Comercial, etc.)
-- modelo = nombre comercial específico (Ranger, F-150, Everest, etc.)
INSERT INTO vehiculo (numero_chasis, linea, transmision, modelo, version,
                      planta_productora, fecha_produccion,
                      warranty_start_date, last_cal_update_date)
SELECT
    'CHS' || LPAD(gs::text, 8, '0'),
    (ARRAY['Pickup Mediana','Pickup Full-Size','Pickup Heavy-Duty',
           'SUV Mediana','SUV Full-Size','SUV Compacta','Comercial'])[1 + (gs % 7)],
    (ARRAY['Manual','Automática'])[1 + (gs % 2)],
    (ARRAY['Ranger','Ranger Raptor','F-150','F-250','F-350','F-450',
           'F-550','F-650','F-750','F-Max','Maverick','Bronco',
           'Bronco Sport','Everest','Territory','Explorer','Escape','Transit']
    )[1 + (gs % 18)],
    (ARRAY['XL','XLS','XLT','Limited','Lariat','King Ranch','Platinum','Wildtrak']
    )[1 + ((gs / 18) % 8)],
    CASE
        WHEN gs % 100 < 50 THEN 'Argentina'
        WHEN gs % 100 < 75 THEN 'Brasil'
        WHEN gs % 100 < 90 THEN 'México'
        ELSE 'Colombia'
    END,
    CASE
        WHEN gs % 10 < 8
            THEN '2019-01-01'::date + ((random() * 1516)::int)
        ELSE '2023-02-26'::date + ((random() * 1039)::int)
    END,
    NULL::date,
    NULL::date
FROM generate_series(1, 50000) gs;

-- Una vez insertados, asignamos warranty_start_date y last_cal_update_date.
-- Se hace en un UPDATE separado porque dependen de fecha_produccion ya cargada.
-- El LEAST con '2026-12-31' evita que alguna fecha calculada se vaya del
-- rango del calendario y rompa la FK contra la dimensión fecha.
UPDATE vehiculo SET
    warranty_start_date = CASE
        WHEN random() < 0.15 THEN NULL
        ELSE LEAST(fecha_produccion + ((30 + random() * 180)::int), DATE '2026-12-31')
    END,
    last_cal_update_date = CASE
        WHEN fecha_produccion < DATE '2023-02-26' THEN NULL
        ELSE LEAST(fecha_produccion + ((1 + random() * 15)::int), DATE '2026-12-31')
    END;


-- La regla que respetamos:
--   * Solo los vehículos vendidos (warranty_start_date NOT NULL) pueden tener reclamos
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
           v.warranty_start_date + ((random() *
               GREATEST(1,
                   ('2026-05-15'::date - v.warranty_start_date)::int
               ))::int) AS fecha_ingreso,
           (1 + (random() * 4)::int)  AS d_diag,
           (5 + (random() * 25)::int) AS d_esp,
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
    LEAST(fecha_ingreso + d_diag, DATE '2026-12-31'),
    CASE WHEN r_open < 0.05 THEN NULL
         ELSE LEAST(fecha_ingreso + d_diag + d_esp, DATE '2026-12-31') END,
    'Reclamo postventa - revisión sistema DPF / motor diésel',
    d_diag,
    CASE WHEN r_open < 0.05 THEN NULL ELSE d_esp END,
    CASE WHEN r_open < 0.05 THEN NULL ELSE d_diag + d_esp END
FROM joined
WHERE fecha_ingreso <= DATE '2026-05-15';


-- Fallas reportadas: como la PK es (id_falla, id_vehiculo), cada vehículo
-- tiene a lo sumo una fila por código DTC. La estrategia es:
--   1) recorremos todos los reclamos y sorteamos qué fallas se levantaron
--      en cada uno (con sesgo a P2002 para vehículos afectados)
--   2) agregamos por (id_falla, id_vehiculo) sumando ocurrencias en cantidad
--      y guardando la última fecha de aparición en fecha_falla
WITH reclamo_nfallas AS (
    SELECT r.id_reclamo,
           r.id_vehiculo,
           r.fecha_ingreso,
           v.fecha_produccion,
           (1 + (random() * 2)::int) AS n_fallas
    FROM reclamos r
    JOIN vehiculo v ON v.id_vehiculo = r.id_vehiculo
),
expandido AS (
    SELECT id_reclamo, id_vehiculo, fecha_ingreso, fecha_produccion, gs AS slot
    FROM reclamo_nfallas, LATERAL generate_series(1, n_fallas) gs
),
asignado AS (
    SELECT id_vehiculo, fecha_ingreso,
           CASE
             WHEN fecha_produccion < '2023-02-26' THEN
                CASE WHEN slot = 1 AND random() < 0.70 THEN 1
                     WHEN slot > 1 AND random() < 0.30 THEN 1
                     ELSE 2 + (random() * 10)::int
                END
             ELSE
                CASE WHEN random() < 0.05 THEN 1
                     ELSE 2 + (random() * 10)::int
                END
           END AS id_falla
    FROM expandido
)
INSERT INTO fallas_reportadas (id_falla, id_vehiculo, fecha_falla, cantidad)
SELECT id_falla,
       id_vehiculo,
       MAX(fecha_ingreso)  AS fecha_falla,    -- última vez que se reportó
       COUNT(*)            AS cantidad        -- cuántas veces apareció
FROM asignado
GROUP BY id_falla, id_vehiculo;


-- ========================= Índices =========================
-- Acompañan a las FK y a los campos por los que se filtra/agrupa habitualmente.

CREATE INDEX idx_vehiculo_planta        ON vehiculo(planta_productora);
CREATE INDEX idx_vehiculo_linea         ON vehiculo(linea);
CREATE INDEX idx_vehiculo_modelo        ON vehiculo(modelo);
CREATE INDEX idx_vehiculo_fecha_prod    ON vehiculo(fecha_produccion);
CREATE INDEX idx_vehiculo_warranty      ON vehiculo(warranty_start_date);
CREATE INDEX idx_vehiculo_lastcal       ON vehiculo(last_cal_update_date);

CREATE INDEX idx_reclamos_vehiculo      ON reclamos(id_vehiculo);
CREATE INDEX idx_reclamos_sucursal      ON reclamos(id_sucursal);
CREATE INDEX idx_reclamos_fecha_ing     ON reclamos(fecha_ingreso);
CREATE INDEX idx_reclamos_fecha_res     ON reclamos(fecha_resolucion);

CREATE INDEX idx_freport_falla          ON fallas_reportadas(id_falla);
CREATE INDEX idx_freport_vehiculo       ON fallas_reportadas(id_vehiculo);
CREATE INDEX idx_freport_fecha          ON fallas_reportadas(fecha_falla);

CREATE INDEX idx_sucursal_ciudad        ON sucursales(id_ciudad);
CREATE INDEX idx_sucursal_concesionario ON sucursales(id_concesionario);
CREATE INDEX idx_ciudad_depto           ON ciudad(id_departamento);
CREATE INDEX idx_depto_pais             ON departamento(id_pais);
