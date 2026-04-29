/* 1.1

La tabla measurement tiene 53 mediciones. Tiene el  ítem_code pero no el nombre del 
contaminante. Para poder listar el nombre de dicho contaminante se precisa usar la información de 
2 tablas: measurement y item.  
¿Por qué la siguiente consulta no arroja lo esperado, es decir, no muestra 53 valores una columna 
más con el nombre del contaminante? ¿Por qué se obtienen  424  ( 53 * 8)  tuplas? 
Explicar */
SELECT  measurement.*, name
