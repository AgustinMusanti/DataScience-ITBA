-- Listar todos los eventos virtuales
SELECT *
FROM evento
WHERE modalidad = 'virtual';

-- Obtener nombres y fechas de eventos con capacidad mayor a 50
SELECT nombre, fecha
FROM evento
WHERE capacidad > 50;

-- Listar todos los tickets con precio mayor a 10.000
SELECT *
FROM ticket
WHERE precio > 10000;

-- Mostrar nombre del evento y precio de sus tickets
SELECT e.nombre, t.precio
FROM evento e
JOIN ticket t 
ON e.id = t.evento_id;

-- Cantidad de tickets por evento
SELECT e.nombre, COUNT(*) AS cantidad_tickets
FROM evento e
JOIN ticket t 
ON e.id = t.evento_id
GROUP BY e.nombre;

-- Total recaudado por evento (sin LEFT JOIN)
SELECT e.nombre, SUM(t.precio) AS total
FROM evento e
JOIN ticket t ON e.id = t.evento_id
JOIN compra c ON t.id = c.ticket_id
GROUP BY e.nombre;

-- Eventos que NO tienen compras (LEFT JOIN)
SELECT e.nombre
FROM evento e
LEFT JOIN ticket t ON e.id = t.evento_id
LEFT JOIN compra c ON t.id = c.ticket_id
WHERE c.ticket_id IS NULL;

-- Usuarios que compraron tickets VIP
SELECT DISTINCT u.nombre
FROM usuario u
JOIN compra c ON u.id = c.user_id
JOIN ticket t ON c.ticket_id = t.id
WHERE t.categoria = 'VIP';

-- Usuario que más compras realizó
SELECT u.nombre
FROM usuario u
JOIN compra c ON u.id = c.user_id
GROUP BY u.nombre
ORDER BY COUNT(*) DESC
LIMIT 1;

-- Usuarios que gastaron más que el promedio
SELECT u.nombre
FROM usuario u
JOIN compra c ON u.id = c.user_id
JOIN ticket t ON c.ticket_id = t.id
GROUP BY u.nombre
HAVING SUM(t.precio) > (
    SELECT AVG(total)
    FROM (
        SELECT SUM(t2.precio) AS total
        FROM compra c2
        JOIN ticket t2 ON c2.ticket_id = t2.id
        GROUP BY c2.user_id
    ) sub
);

-- Listar todos los usuarios cuyo email contenga “gmail”.
SELECT * FROM usuario
WHERE email= LIKE '%gmail%';

-- Mostrar todos los eventos que ocurren después de una fecha dada (por ejemplo: '2024-06-01').
SELECT * FROM evento
WHERE fecha > '2024-06-01';

-- Obtener todos los tickets cuya categoría sea distinta de “General”.
SELECT * FROM ticket
WHERE categoria <> 'General';

/* (otra solución): */
SELECT * FROM ticket
WHERE categoria != 'General';

-- Listar el nombre del usuario y el nombre del evento al que asistió (es decir, que compró ticket).
SELECT u.nombre, e.nombre
FROM usuario u
JOIN compra c ON u.id = c.user_id
JOIN ticket t ON c.ticket_id = t.id
JOIN evento e ON t.evento_id = e.id;

-- Mostrar todos los eventos junto con la cantidad de tickets que tienen disponibles.
SELECT e.nombre, COUNT(t.id) AS cantidad_tickets
FROM evento e
JOIN ticket t ON e.id = t.evento_id
GROUP BY e.nombre;

-- Usuarios que NO realizaron ninguna compra
SELECT u.nombre
FROM usuario u
LEFT JOIN compra c ON u.id = c.user_id
WHERE c.user_id IS NULL;

-- Precio promedio de tickets por categoría
SELECT categoria, AVG(precio) AS precio_promedio
FROM ticket
GROUP BY categoria;

-- Cantidad de compras por evento
SELECT e.nombre, COUNT(c.ticket_id) AS cantidad_compras
FROM evento e
JOIN ticket t ON e.id = t.evento_id
JOIN compra c ON t.id = c.ticket_id
GROUP BY e.nombre;

-- Usuarios que hicieron más compras que el promedio
SELECT u.nombre
FROM usuario u
JOIN compra c ON u.id = c.user_id
GROUP BY u.id, u.nombre
HAVING COUNT(*) > (
    SELECT AVG(cant)
    FROM (
        SELECT COUNT(*) AS cant
        FROM compra
        GROUP BY user_id
    ) sub
);

-- Eventos con precio promedio mayor al promedio global
SELECT e.nombre
FROM evento e
JOIN ticket t ON e.id = t.evento_id
GROUP BY e.id, e.nombre
HAVING AVG(t.precio) > (
    SELECT AVG(precio)
    FROM ticket
);
