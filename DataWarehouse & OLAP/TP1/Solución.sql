/* 1.1
La tabla measurement tiene 53 mediciones. Tiene el  ítem_code pero no el nombre del 
contaminante. Para poder listar el nombre de dicho contaminante se precisa usar la información de 
2 tablas: measurement y item.  
¿Por qué la siguiente consulta no arroja lo esperado, es decir, no muestra 53 valores una columna 
más con el nombre del contaminante? ¿Por qué se obtienen  424  ( 53 * 8)  tuplas? 
Explicar */
SELECT  measurement.*, name
FROM measurement,  item 

RTA: por producto cartesiano.
Cuando se escribe FROM measurement, item sin una condición de JOIN, SQL combina cada fila de measurement con cada fila de item.

Solución:

SELECT measurement.*, item.name
FROM measurement
JOIN item ON measurement.item_code = item.code;


/* 1.3
Mostrar del histórico de mediciones solo hasta las 8 más recientes, desplegando el nombre del ítem también */

SELECT m.date, m.station_code, i.name, m.value
FROM measurement m
JOIN item i ON m.item_code = i.code
ORDER BY m.date DESC
LIMIT 8;

/* 1.4)   Escribir una consulta SQL que permita obtener:  nombre de la estación (no código), nombre del 
contaminante (no código), fecha de la medición y el valor medido, mostrando primero las más 
reciente y de repetirse la fecha, ordenar luego por nombre del ítem ascendentemente y luego por 
nombre de la estación ascendentemente.  Con los datos del ejemplo, deberíamos obtener sólo 53 
tuplas. Mostramos solo un subconjunto */

SELECT s.name AS station, i.name AS item, m.date, m.value
FROM measurement m
JOIN item i ON m.item_code = i.code
JOIN station s ON m.station_code = s.code
ORDER BY m.date DESC, i.name ASC, s.name ASC;

/* 2.1)  La misma consulta que realizamos en el item 1.4 */
SELECT name, name, date, value 
FROM (measurement JOIN item ON item_code = code) JOIN station  
ON station_code= code 
ORDER BY date DESC, name ASC, name ASC 
/* podría realizarse colocando la condición de “matcheo” en la cláusula WHERE. Es decir, usar un 
producto cartesiano entre dichas 3 tablas, para luego establecer en el WHERE las restricciones 
esperadas. 
Reescribir dicha consulta de esta manera */

SELECT s.name AS station, i.name AS item, m.date, m.value
FROM measurement m, item i, station s
WHERE m.item_code = i.code
  AND m.station_code = s.code
ORDER BY m.date DESC, i.name ASC, s.name ASC;

/* 2.2) Mostrar los nombres de los contaminantes cuyos valores registrados fueron Very Bad (superaron 
el valor VeryBad de la tabla indicada por ITEM). Mostrar dicho valor y el valor del umbral 
correspondiente (el cual depende de cada item) 
Con los datos del ejemplo no se obtiene ninguno */

SELECT i.name, m.value, i.very_bad
FROM measurement m
JOIN item i ON m.item_code = i.code
WHERE m.value > i.very_bad;

/* 2.3) Mostrar los nombres de los contaminantes cuyos valores registrados fueron Bad (superaron el valor 
Bad pero no el valor VeryBad de los umbrales  indicados por la tabla ITEM). Mostrar dicho valor y los 
2 umbrales correspondientes. 
Con los datos del ejemplo se obtendría */

SELECT i.name, m.value, i.bad, i.very_bad
FROM measurement m
JOIN item i ON m.item_code = i.code
WHERE m.value > i.bad
  AND m.value <= i.very_bad;

/* 2.4)  Mostrar el nombre de los contaminantes que no se miden en unidades ppm 
Con los datos del ejemplo sólo debería obtenerse 2 tuplas. */

SELECT name, uom
FROM item
WHERE uom <> 'ppm';

/* 2.5) Mostrar aquellos nombres de contaminantes que todavía no tienen ingresados algún valor de sus 
umbrales. 
Obtendremos 2:  dummy  y  bis */

SELECT name
FROM item
WHERE good IS NULL
   OR normal IS NULL
   OR bad IS NULL
   OR very_bad IS NULL;

o
  
SELECT name
FROM item
WHERE (good + normal + bad + very_bad) IS NULL; -- lógica de De Morgan --

/* 2.6)  Mostrar aquellos  código y nombres de contaminantes  que todavía no tienen mediciones asociadas */

SELECT i.code, i.name
FROM item i
LEFT JOIN measurement m ON i.code = m.item_code
WHERE m.item_code IS NULL;

/* 2.7)  Notar que para ver cuáles son los contaminantes (código y nombre) que sí tuvieron 
mediciones podemos proceder de diferentes formas también: 
a) con algún tipo de Join 
b) con un IN 
Realizar las 2 versiones. */

-- a
SELECT DISTINCT i.code, i.name
FROM item i
JOIN measurement m ON i.code = m.item_code;

--b
SELECT code, name
FROM item
WHERE code IN (SELECT item_code FROM measurement); --(subconsulta)--

/* 2.8) Mostrar los nombres de contaminantes que tuvieron algún valor registrado considerado 
excelente (<= good), ordenados por su código numérico */

SELECT DISTINCT i.code, i.name
FROM item i
JOIN measurement m ON i.code = m.item_code
WHERE m.value <= i.good
ORDER BY i.code;

/* 2.9) Reescribir la consulta anterior para no solo mostrar el nombre del contaminante sino 
también cuál es ese valor que lo hizo excelente en dicha medición. Para verificar el resultado, 
mostrar también el valor del umbral Good */

SELECT i.name, m.value, i.good AS threshold_good
FROM item i
JOIN measurement m ON i.code = m.item_code
WHERE m.value <= i.good
ORDER BY i.code;

