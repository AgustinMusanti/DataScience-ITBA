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
