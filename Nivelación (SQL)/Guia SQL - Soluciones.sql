/*1)	Listar el número y nombre de todos los departamentos.*/
SELECT numero, nombre 
FROM departamento;

/*2)	Listar los nombres de los departamentos ordenados alfabéticamente de manera descendente*/
SELECT nombre 
FROM departamento
order by nombre DESC;

/*3)	Listar el primero y segundo nombre de lista del ejercicio 2)*/
SELECT nombre 
FROM departamento
order by nombre DESC
LIMIT 2;

/*4)	Listar los DNIs de la tabla PARTICIPA ordenados ascendentemente.*/
SELECT dni 
FROM participa
order by dni;

/*5)	Listar los DNIs de la tabla PARTICIPA sin repeticiones ordenados alfabéticamente de manera ascendente.*/
SELECT distinct dni 
FROM participa
order by dni;

/*6)	  Mostrar el nombre y la fecha de nacimiento de aquellos empleados que ganan más de $30000 ordenados por fecha de nacimiento.*/
SELECT nombre, fechanac
FROM empleado
WHERE sueldo > 30000
ORDER BY fechanac;

/*7) Mostrar el nombre y la fecha de nacimiento de aquellos
empleados que ganan más de $30000 y que viven en CABA ordenados descendentemente por fecha de nacimiento.*/
SELECT nombre, fechanac
FROM empleado
WHERE sueldo > 30000 AND ciudad ='CABA'
ORDER BY fechanac;

/*8)	Mostrar el nombre y la fecha de nacimiento de aquellos empleados
 que ganan más de $30000 y que viven en CABA o en Quilmes ordenados por fecha de nacimiento.*/
SELECT nombre, fechanac
FROM empleado
WHERE sueldo > 30000 AND ciudad ='CABA'
OR ciudad ='Quilmes'
ORDER BY fechanac;

/*9)	Listar dni y número de proyecto en los cuales los empleados trabajaron 20 horas o menos, o más 60 hs.*/
SELECT dni, nroproyecto 
FROM participa
WHERE horas <= 20 
OR horas > 60;

/*10)	Listar los nombres de los departamentos junto al nombre de los empleados que trabajan en él, 
ordenando primero por nombre del departamento y luego por el nombre del empleado, ambos ascendentemente.*/

SELECT departamento.nombre, empleado.nombre
FROM departamento 
JOIN empleado ON departamento.numero=nrodpto
ORDER BY departamento.nombre, empleado.nombre;

/*	11)	Listar los números de los proyectos en los que participa Lourdes Perez. (preguntar por el nombre, no por 
el código). Tener en cuenta que el nombre podría estar con mayúsculas o minúsculas. La consulta debe responder a cualquier combinación de mayúsculas y minúsculas.*/
SELECT nroproyecto
FROM empleado 
JOIN participa ON participa.dni=empleado.dni
WHERE UPPER(empleado.nombre) = 'LOURDES PEREZ';

/*12)	Listar los nombres de los proyectos en los que participa Lourdes Perez. (preguntar por el nombre, no por el código). Tener en cuenta que el 
nombre podría estar con mayúsculas o minúsculas. La consulta debe responder a cualquier combinación de mayúsculas y minúsculas.*/
SELECT proyecto.nombre
FROM empleado 
JOIN participa ON participa.dni=empleado.dni JOIN proyecto
ON participa.nroproyecto = proyecto.numero
WHERE UPPER(empleado.nombre) = 'LOURDES PEREZ';

 /*13)	Listar los pares de empleados que trabajaron en el mismo proyecto. 
 Se debe mostrar el dni de un empleado y el dni de su compañero. 
 No deben repetirse los pares: si aparece dni1,dni2 no debe aparecer dni2, dni1.
 */
 
 SELECT distinct par1.dni dni1,par2.dni dni2
 FROM participa par1 
 JOIN participa par2 ON par1.nroproyecto=par2.nroproyecto AND par1.dni<par2.dni
 ORDER BY par1.dni;

/*14)	Mostrar los empleados que son jefes y tienen auto. 
Se debe listar el nombre del jefe y la patente de su auto.*/
SELECT nombre, patente 
FROM empleado 
JOIN auto 
ON empleado.dni=dniJefe;


/*15)	Mostrar los empleados que son jefes tengan o no auto. 
Se debe listar el dni del jefe y la patente de su auto. 
En caso de no tener auto debe aparecer vacío (NULL)*/
SELECT dni, patente
FROM jefe 
LEFT JOIN auto 
ON dnijefe=dni;

/*	16)	Mostrar los empleados que son jefes tengan o no auto. 
Se debe listar el nombre del jefe y la patente de su auto. 
En caso de no tener auto debe aparecer vacío (NULL)*/
SELECT nombre, patente
FROM empleado 
JOIN jefe 
ON empleado.dni=jefe.dni 
LEFT JOIN auto 
ON dnijefe=dni;




/*17) Listar los nombres de los empleados que trabajaron en el proyecto 71 o en el proyecto 84*/
SELECT DISTINCT nombre 
FROM empleado 
JOIN participa 
ON empleado.dni=participa.dni
WHERE nroproyecto IN (84,71);

/*otra solucion*/
SELECT DISTINCT nombre 
FROM empleado 
JOIN participa 
ON empleado.dni=participa.dni
WHERE nroproyecto = 84
OR nroproyecto = 71;

/*18) Listar los nombres de los empleados que trabajaron en el proyecto 25 y en el proyecto 31*/
SELECT DISTINCT nombre 
FROM empleado 
JOIN participa 
ON empleado.dni=participa.dni
WHERE nroproyecto = 25 
AND empleado.dni IN (SELECT dni FROM participa WHERE nroproyecto=31);

/*otra solucion*/
SELECT DISTINCT nombre 
FROM empleado 
JOIN participa 
ON empleado.dni=participa.dni
WHERE nroproyecto = 25 
AND EXISTS (SELECT * FROM participa WHERE nroproyecto=31 AND dni=empleado.dni);


/* 19) Listar los nombres de los departamentos que no controlan ningún proyecto*/
SELECT nombre
FROM departamento
WHERE numero 
NOT IN 
	(SELECT nrodpto
	 FROM proyecto);

/*otra solucion*/
SELECT nombre
FROM departamento
WHERE NOT EXISTS 
	(SELECT * FROM proyecto
	 WHERE departamento.numero=proyecto.nrodpto);

/*	20) Listar los nombres de los empleados que no son jefes.*/ 

SELECT nombre
FROM empleado
WHERE NOT EXISTS 
	(SELECT * 
	 FROM jefe
	 WHERE jefe.dni=empleado.dni);


/*21) 
Listar los nombres de los empleados que trabajan para el departamento 
de Sistemas y que trabajaron en algún proyecto controlado por Recursos Humanos (RRHH). (Utilizar los nombres de los departamentos para la consulta, no los números)
*/
SELECT DISTINCT empleado.nombre
FROM empleado JOIN departamento ON empleado.nroDpto=departamento.numero
WHERE UPPER(departamento.nombre) = 'SISTEMAS'
AND dni IN ( SELECT dni
   FROM departamento JOIN proyecto ON nroDpto=departamento.numero JOIN participa ON proyecto.numero=participa.nroproyecto
   WHERE UPPER(departamento.nombre) = 'RRHH'
   )


--Otra
SELECT DISTINCT empleado.nombre
FROM empleado JOIN departamento ON empleado.nroDpto=departamento.numero
WHERE UPPER(departamento.nombre) = 'SISTEMAS'
AND EXISTS ( SELECT *
			FROM departamento JOIN proyecto ON nroDpto=departamento.numero JOIN participa ON proyecto.numero=participa.nroproyecto
			WHERE UPPER(departamento.nombre) = 'RRHH'
			AND participa.dni=empleado.dni
			)

--
/* 23) Mostrar la máxima cantidad de horas trabajadas por algún empleado en algún proyecto*/
SELECT MAX(horas) maxima_cantidad FROM participa;

/*	24) Listar el nombre del empleado que trabajó más horas en un proyecto.*/
SELECT empleado.nombre
FROM empleado JOIN participa ON empleado.dni=participa.dni
WHERE horas = (SELECT MAX(horas)
		FROM participa);


/*25) Mostrar el mayor sueldo de la empresa*/
SELECT MAX(sueldo)
FROM empleado;

/*26) Mostrar los nombres de los departamentos y el sueldo máximo de cada uno de ellos. No mostrar el departamento si no tiene empleados*/
SELECT departamento.nombre, max(sueldo) as SueldoMaximo
FROM departamento JOIN empleado ON departamento.numero=nrodpto
GROUP BY departamento.numero,departamento.nombre;

/*27) Mostrar el nombre de los empleados que ganan más del 50% del sueldo máximo de la empresa*/
SELECT nombre
FROM empleado
WHERE sueldo > (SELECT MAX(sueldo) * .5
FROM empleado);


/*28) Listar la cantidad de proyectos en los que trabaja Gastón Felicce y la suma de sus horas.*/
SELECT COUNT(*) cantidad, SUM(horas) suma
FROM empleado JOIN participa ON empleado.dni=participa.dni
WHERE UPPER(nombre) = 'GASTÓN FELICCE';

/*29) Listar los nombres de los departamentos que controlan exactamente un proyecto.*/
SELECT departamento.nombre
FROM departamento JOIN proyecto ON nrodpto=departamento.numero
GROUP BY departamento.nombre
HAVING COUNT(*) = 1;

/*30) Listar los nombres de los departamentos que controlan exactamente dos proyectos.*/
SELECT departamento.nombre
FROM departamento JOIN proyecto ON nrodpto=departamento.numero
GROUP BY departamento.nombre
HAVING COUNT(*) = 2;

/*31) Listar para cada empleado la cantidad de proyectos en los que trabaja. Se debe mostrar el nombre del empleado.*/
SELECT empleado.nombre, count(participa.nroproyecto) cantidad
FROM empleado left Join participa ON empleado.dni=participa.dni
GROUP BY empleado.dni,empleado.nombre;

/*32) Listar para cada empleado la suma de las horas de todos los proyectos en los que trabaja. 
En caso de no trabajar en ningún proyecto debe aparecer 
con null en el resultado. Se debe mostrar el nombre del empleado y cado uno de ellos debe aparecer sólo una vez. */

SELECT empleado.nombre, sum(horas) horas
FROM empleado left Join participa ON empleado.dni=participa.dni
GROUP BY empleado.dni, empleado.nombre;

--en caso de que quisiéramos que el null sea cero, podemos usar la función COALESCE que permite transformar
--los valores NULL en alguno del mismo tipo que nosotros indiquemos

SELECT empleado.nombre, COALESCE(sum(horas),0) horas
FROM empleado left Join participa ON empleado.dni=participa.dni
GROUP BY empleado.dni, empleado.nombre;



/*33) Listar los nombres de los proyectos junto 
con la suma de sus horas ordenados descendentemente por la suma de las horas.*/
SELECT proyecto.nombre, sum(horas) suma 
FROM proyecto Join participa ON proyecto.numero=participa.nroproyecto
GROUP BY proyecto.nombre
ORDER BY suma DESC;


/*34) Listar los nombres de los proyectos junto con la suma de sus horas 
ordenados descendentemente por la suma de las horas sólo para aquellos proyectos 
que tuvieron entre 100 Y 200 (inclusive) horas acumuladas.*/
SELECT proyecto.nombre, sum(horas) suma 
FROM proyecto Join participa ON proyecto.numero=participa.nroproyecto
GROUP BY proyecto.nombre
HAVING sum(horas) >= 100
AND sum(horas) <= 200
ORDER BY suma DESC;


/*35)	Sabiendo que el valor de la hora de los empleados del departamento de sistemas es $1200 y del resto de $1000, 
crear la vista MONTOS que contenga 
el dni y nombre del empleado, su departamento junto con las horas trabajadas en cada proyecto * su correspondiente valor;
*/
--DROP VIEW montos;
CREATE VIEW montos(dni,nombre,departamento,monto) AS (
SELECT empleado.dni, empleado.nombre, departamento.nombre, 1000*horas
FROM empleado JOIN departamento ON departamento.numero=nrodpto 
	JOIN participa ON empleado.dni=participa.dni
	WHERE UPPER(departamento.nombre) !='SISTEMAS'
UNION
SELECT empleado.dni, empleado.nombre, departamento.nombre, 1200*horas 
FROM empleado JOIN departamento ON departamento.numero=nrodpto 
	JOIN participa ON empleado.dni=participa.dni
	WHERE UPPER(departamento.nombre)='SISTEMAS'	);

--Se puede utilizar CASE WHEN también

--DROP VIEW montos;
CREATE VIEW montos(dni,nombre,departamento,monto) AS (
SELECT empleado.dni, empleado.nombre, departamento.nombre, CASE WHEN UPPER(departamento.nombre)='SISTEMAS' THEN 1200*horas 
																ELSE 1000*horas END
FROM empleado JOIN departamento ON departamento.numero=nrodpto 
			  JOIN participa ON empleado.dni=participa.dni);


SELECT * FROM montos;

/*36)	Utilizando la vista MONTOS, mostrar el nombre de cada 
empleado junto con el total acumulado de montos ordenados por este último descendentemente.*/
SELECT nombre, SUM(monto) total
FROM montos
GROUP BY nombre
ORDER BY total DESC;





