/*
   Consultas analíticas — DW Campaña DPF Colombia

   Convenciones:
     * "Vehículo afectado"    = fecha_produccion < 2023-02-26
     * "P2002 activo / urgente" = fila en fallas_reportadas con id_falla=1
                                  + vehículo sin last_cal_update_date
     * "Unidad campañada"     = vehículo con last_cal_update_date NOT NULL
*/


-- ========================= 1. Operatividad y Logística =========================


-- 1.a) ¿Cuál es el tiempo promedio mensual de diagnóstico y de espera
--      de la pieza por cada sucursal?
SELECT
    s.id_sucursal,
    s.nombre_sucursal,
    DATE_TRUNC('month', r.fecha_ingreso)::date  AS mes,
    COUNT(*)                                    AS cant_reclamos,
    ROUND(AVG(r.dias_diagnostico)::numeric,  2) AS prom_dias_diagnostico,
    ROUND(AVG(r.dias_espera_pieza)::numeric, 2) AS prom_dias_espera_pieza
FROM reclamos r
JOIN sucursales s ON s.id_sucursal = r.id_sucursal
WHERE r.fecha_resolucion IS NOT NULL
GROUP BY s.id_sucursal, s.nombre_sucursal, DATE_TRUNC('month', r.fecha_ingreso)
ORDER BY s.nombre_sucursal, mes;


-- 1.b) ¿Cuál es el ranking de departamento con mayor promedio de días
--      de tiempo de espera de la pieza?
SELECT
    RANK() OVER (ORDER BY AVG(r.dias_espera_pieza) DESC) AS ranking,
    d.nombre_departamento,
    COUNT(*)                                    AS cant_reclamos,
    ROUND(AVG(r.dias_espera_pieza)::numeric, 2) AS prom_dias_espera
FROM reclamos r
JOIN sucursales   s ON s.id_sucursal     = r.id_sucursal
JOIN ciudad       c ON c.id_ciudad       = s.id_ciudad
JOIN departamento d ON d.id_departamento = c.id_departamento
WHERE r.dias_espera_pieza IS NOT NULL
GROUP BY d.nombre_departamento
ORDER BY prom_dias_espera DESC;


-- 1.c) ¿Cuál es el ranking de sucursales dentro de cada departamento
--      según tiempo de espera de pieza?
SELECT
    d.nombre_departamento,
    s.nombre_sucursal,
    ROUND(AVG(r.dias_espera_pieza)::numeric, 2) AS prom_dias_espera,
    COUNT(*)                                    AS cant_reclamos,
    RANK() OVER (
        PARTITION BY d.id_departamento
        ORDER BY AVG(r.dias_espera_pieza) DESC
    )                                           AS ranking_dentro_depto
FROM reclamos r
JOIN sucursales   s ON s.id_sucursal     = r.id_sucursal
JOIN ciudad       c ON c.id_ciudad       = s.id_ciudad
JOIN departamento d ON d.id_departamento = c.id_departamento
WHERE r.dias_espera_pieza IS NOT NULL
GROUP BY d.id_departamento, d.nombre_departamento, s.nombre_sucursal
ORDER BY d.nombre_departamento, ranking_dentro_depto;


-- 1.d) ¿Cuál es el tiempo promedio de resolución agrupado por nombre
--      del concesionario y número de sucursales que posee?
WITH sucursales_por_concesionario AS (
    SELECT id_concesionario, COUNT(*) AS nro_sucursales
    FROM sucursales
    GROUP BY id_concesionario
)
SELECT
    con.nombre_comercial,
    spc.nro_sucursales,
    COUNT(r.id_reclamo)                              AS cant_reclamos,
    ROUND(AVG(r.dias_total_diagnostico)::numeric, 2) AS prom_dias_resolucion
FROM reclamos r
JOIN sucursales s                       ON s.id_sucursal        = r.id_sucursal
JOIN concesionario con                  ON con.id_concesionario = s.id_concesionario
JOIN sucursales_por_concesionario spc   ON spc.id_concesionario = con.id_concesionario
WHERE r.dias_total_diagnostico IS NOT NULL
GROUP BY con.nombre_comercial, spc.nro_sucursales
ORDER BY prom_dias_resolucion DESC;


-- 1.e) ¿Cuál es la evolución mensual del tiempo promedio de reparación
--      por región, y cómo se compara cada mes contra el mes anterior?
WITH mensual AS (
    SELECT
        d.nombre_departamento                      AS region,
        DATE_TRUNC('month', r.fecha_ingreso)::date AS mes,
        AVG(r.dias_total_diagnostico)              AS prom_dias_reparacion
    FROM reclamos r
    JOIN sucursales   s ON s.id_sucursal     = r.id_sucursal
    JOIN ciudad       c ON c.id_ciudad       = s.id_ciudad
    JOIN departamento d ON d.id_departamento = c.id_departamento
    WHERE r.dias_total_diagnostico IS NOT NULL
    GROUP BY d.nombre_departamento, DATE_TRUNC('month', r.fecha_ingreso)
)
SELECT
    region,
    mes,
    ROUND(prom_dias_reparacion::numeric, 2) AS prom_dias_reparacion,
    ROUND(LAG(prom_dias_reparacion) OVER (
            PARTITION BY region ORDER BY mes
          )::numeric, 2)                    AS prom_mes_anterior,
    ROUND((prom_dias_reparacion - LAG(prom_dias_reparacion) OVER (
            PARTITION BY region ORDER BY mes
          ))::numeric, 2)                   AS variacion_abs,
    ROUND((
        (prom_dias_reparacion - LAG(prom_dias_reparacion) OVER (
            PARTITION BY region ORDER BY mes))
        / NULLIF(LAG(prom_dias_reparacion) OVER (
            PARTITION BY region ORDER BY mes), 0) * 100
    )::numeric, 2)                          AS variacion_pct
FROM mensual
ORDER BY region, mes;


-- ========================= 2. Incidencia y Segmentación =========================


-- 2.a) ¿Cuál es el número de unidades que actualmente tienen prendido
--      el código de falla en cada región?
-- Como fallas_reportadas no tiene contexto geográfico propio, derivamos
-- la región del vehículo usando la sucursal de su último reclamo.
WITH ultima_sucursal_por_vehiculo AS (
    SELECT DISTINCT ON (id_vehiculo)
           id_vehiculo, id_sucursal
    FROM reclamos
    ORDER BY id_vehiculo, fecha_ingreso DESC
)
SELECT
    d.nombre_departamento         AS region,
    COUNT(DISTINCT v.id_vehiculo) AS unidades_dtc_activo
FROM vehiculo v
JOIN fallas_reportadas fr        ON fr.id_vehiculo  = v.id_vehiculo
JOIN falla f                     ON f.id_falla      = fr.id_falla
JOIN ultima_sucursal_por_vehiculo usv ON usv.id_vehiculo = v.id_vehiculo
JOIN sucursales   s              ON s.id_sucursal     = usv.id_sucursal
JOIN ciudad       c              ON c.id_ciudad       = s.id_ciudad
JOIN departamento d              ON d.id_departamento = c.id_departamento
WHERE f.numero_falla = 'P2002'
  AND v.last_cal_update_date IS NULL
GROUP BY d.nombre_departamento
ORDER BY unidades_dtc_activo DESC;


-- 2.b) ¿Cuál es la tasa de falla por región y qué regiones tienen
--      la mayor cantidad de unidades pendientes de resolución?
WITH ultima_sucursal_por_vehiculo AS (
    SELECT DISTINCT ON (id_vehiculo)
           id_vehiculo, id_sucursal
    FROM reclamos
    ORDER BY id_vehiculo, fecha_ingreso DESC
),
reclamo_abierto_p2002 AS (
    -- Vehículos con al menos un reclamo abierto cuyo vehículo tiene P2002 reportado
    SELECT DISTINCT r.id_vehiculo
    FROM reclamos r
    JOIN fallas_reportadas fr ON fr.id_vehiculo = r.id_vehiculo
    WHERE fr.id_falla = 1
      AND r.fecha_resolucion IS NULL
),
base AS (
    SELECT
        d.nombre_departamento                                   AS region,
        v.id_vehiculo,
        MAX(CASE WHEN fr.id_falla = 1 THEN 1 ELSE 0 END)        AS tiene_p2002,
        MAX(CASE WHEN rap.id_vehiculo IS NOT NULL THEN 1 ELSE 0 END) AS pendiente
    FROM vehiculo v
    JOIN ultima_sucursal_por_vehiculo usv ON usv.id_vehiculo = v.id_vehiculo
    JOIN sucursales   s ON s.id_sucursal     = usv.id_sucursal
    JOIN ciudad       c ON c.id_ciudad       = s.id_ciudad
    JOIN departamento d ON d.id_departamento = c.id_departamento
    LEFT JOIN fallas_reportadas fr ON fr.id_vehiculo = v.id_vehiculo
    LEFT JOIN reclamo_abierto_p2002 rap ON rap.id_vehiculo = v.id_vehiculo
    GROUP BY d.nombre_departamento, v.id_vehiculo
)
SELECT
    region,
    COUNT(*)                                                AS unidades_atendidas,
    SUM(tiene_p2002)                                        AS unidades_con_p2002,
    SUM(pendiente)                                          AS unidades_pendientes,
    ROUND(100.0 * SUM(tiene_p2002) / NULLIF(COUNT(*),0), 2) AS tasa_falla_pct
FROM base
GROUP BY region
ORDER BY unidades_pendientes DESC, tasa_falla_pct DESC;


-- 2.c) Top 1 de línea y modelo más afectado por planta productiva.
     /* Por cada planta, mostramos la combinación línea + modelo con mayor
        cantidad de eventos P2002, usando ROW_NUMBER() para quedarnos
        con el top 1 por planta. */
WITH eventos_p2002 AS (
    SELECT
        v.planta_productora,
        v.linea,
        v.modelo,
        SUM(fr.cantidad) AS eventos_p2002
    FROM vehiculo v
    JOIN fallas_reportadas fr ON fr.id_vehiculo = v.id_vehiculo
    JOIN falla f              ON f.id_falla     = fr.id_falla
    WHERE f.numero_falla = 'P2002'
    GROUP BY v.planta_productora, v.linea, v.modelo
),
ranking AS (
    SELECT
        planta_productora,
        linea,
        modelo,
        eventos_p2002,
        ROW_NUMBER() OVER (
            PARTITION BY planta_productora
            ORDER BY eventos_p2002 DESC
        ) AS rn
    FROM eventos_p2002
)
SELECT planta_productora, linea, modelo, eventos_p2002
FROM ranking
WHERE rn = 1
ORDER BY eventos_p2002 DESC;


-- ========================= 3. Gestión de Campaña =========================


-- 3.a) ¿Cuántas unidades tienen presente la falla urgente para darles
--      prioridad en la lista de atención?
--      Urgente = vehículo con P2002 reportado y sin campaña aplicada aún.
SELECT COUNT(DISTINCT v.id_vehiculo) AS unidades_urgentes
FROM vehiculo v
JOIN fallas_reportadas fr ON fr.id_vehiculo = v.id_vehiculo
JOIN falla f              ON f.id_falla     = fr.id_falla
WHERE f.numero_falla = 'P2002'
  AND v.last_cal_update_date IS NULL;


-- 3.b) ¿Cuántas unidades son parte de la campaña preventiva y cuántas
--      todavía no han sido vendidas (sin warranty_start_date)?
--      Preventiva = afectado, vendido, sin P2002 reportado todavía.
WITH afectados AS (
    SELECT id_vehiculo, warranty_start_date
    FROM vehiculo
    WHERE fecha_produccion < DATE '2023-02-26'
),
con_p2002 AS (
    SELECT DISTINCT fr.id_vehiculo
    FROM fallas_reportadas fr
    JOIN falla f ON f.id_falla = fr.id_falla
    WHERE f.numero_falla = 'P2002'
)
SELECT
    COUNT(*) FILTER (
        WHERE a.warranty_start_date IS NOT NULL
          AND a.id_vehiculo NOT IN (SELECT id_vehiculo FROM con_p2002)
    ) AS unidades_campania_preventiva,
    COUNT(*) FILTER (
        WHERE a.warranty_start_date IS NULL
    ) AS unidades_sin_vender_stock,
    COUNT(*) AS total_universo_afectado
FROM afectados a;


-- 3.c) ¿Qué cantidad de unidades se tendrán que llamar al cliente y
--      qué porcentaje del total representa el Recall?
--      Recall = afectados, vendidos, sin campaña aplicada todavía.
SELECT
    COUNT(*) FILTER (
        WHERE fecha_produccion    <  DATE '2023-02-26'
          AND warranty_start_date  IS NOT NULL
          AND last_cal_update_date IS NULL
    ) AS unidades_a_llamar,
    COUNT(*) AS total_vehiculos,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE fecha_produccion    <  DATE '2023-02-26'
              AND warranty_start_date  IS NOT NULL
              AND last_cal_update_date IS NULL
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS pct_recall_sobre_total
FROM vehiculo;


-- 3.d) Unidades campañadas mes a mes con acumulado progresivo.
--      Campañada = vehículo con last_cal_update_date NOT NULL.
WITH campania_mensual AS (
    SELECT
        DATE_TRUNC('month', last_cal_update_date)::date AS mes,
        COUNT(*)                                        AS unidades_campañadas
    FROM vehiculo
    WHERE last_cal_update_date IS NOT NULL
    GROUP BY DATE_TRUNC('month', last_cal_update_date)
)
SELECT
    mes,
    unidades_campañadas,
    SUM(unidades_campañadas) OVER (
        ORDER BY mes
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS acumulado_progresivo
FROM campania_mensual
ORDER BY mes;
