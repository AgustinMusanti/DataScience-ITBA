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

