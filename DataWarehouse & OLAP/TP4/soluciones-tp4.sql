-- Query 6.1. Total sales amount per customer, year, and product category.

SELECT c.CompanyName,
       EXTRACT(YEAR FROM o.OrderDate) AS Anio, -- No toma la "ñ" postgress
       cat.CategoryName,
       SUM(od.Quantity * od.UnitPrice) AS TotalVentas
FROM Customers c
JOIN Orders o        ON c.CustomerID = o.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p      ON od.ProductID = p.ProductID
JOIN Categories cat  ON p.CategoryID = cat.CategoryID
GROUP BY c.CustomerID, c.CompanyName, EXTRACT(YEAR FROM o.OrderDate), cat.CategoryID, cat.CategoryName
ORDER BY c.CompanyName, Anio, TotalVentas DESC;

-- Query 6.2. Yearly sales amount for each pair of customer country and supplier countries.

SELECT c.Country AS PaisCliente,
       s.Country AS PaisProveedor,
       EXTRACT(YEAR FROM o.OrderDate) AS Anio,
       SUM(od.Quantity * od.UnitPrice) AS TotalVentas
FROM Customers c
JOIN Orders o        ON c.CustomerID = o.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p      ON od.ProductID = p.ProductID
JOIN Suppliers s     ON p.SupplierID = s.SupplierID
GROUP BY c.Country, s.Country, EXTRACT(YEAR FROM o.OrderDate)
ORDER BY c.Country, s.Country, Anio;

-- Query 6.3. Monthly sales by customer state compared to those of the previous year.
-- Uso PARTITIONS
/*Esta query introduce las Window Functions, que son funciones que operan sobre un conjunto de filas relacionadas sin colapsar el resultado como hace GROUP BY.
  LAG() es la función clave acá — trae el valor de la fila anterior dentro de una ventana definida. */

SELECT c.Region AS Estado,
       EXTRACT(YEAR FROM o.OrderDate)  AS Anio,
       EXTRACT(MONTH FROM o.OrderDate) AS Mes,
       SUM(od.Quantity * od.UnitPrice) AS TotalVentas,
       LAG(SUM(od.Quantity * od.UnitPrice)) OVER (
           PARTITION BY c.Region, EXTRACT(MONTH FROM o.OrderDate)
           ORDER BY EXTRACT(YEAR FROM o.OrderDate)
       ) AS TotalAnoAnterior
FROM Customers c
JOIN Orders o        ON c.CustomerID = o.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p      ON od.ProductID = p.ProductID
GROUP BY c.Region, EXTRACT(YEAR FROM o.OrderDate), EXTRACT(MONTH FROM o.OrderDate)
ORDER BY c.Region, Anio, Mes;

-- Query 6.4. Three best-selling employees.

SELECT e.FirstName, e.LastName,
       SUM(od.Quantity * od.UnitPrice) AS TotalVentas
FROM Employees e
JOIN Orders o        ON e.EmployeeID = o.EmployeeID
JOIN OrderDetails od ON o.OrderID = od.OrderID
GROUP BY e.EmployeeID, e.FirstName, e.LastName
ORDER BY TotalVentas DESC
LIMIT 3;

-- Query 6.5. Best-selling employee per product and year.
/* No alcanza con LIMIT 3 como antes, porque acá necesitamos el mejor por cada combinación producto+año. Para eso se usa RANK(), otra window function. */
/* Se necesita la subquery porque NO puedo escribir WHERE RANK() = 1 directamente porque RANK() se calcula después del WHERE. 
   Entonces primero calculo el ranking en una subquery, y recién en la query exterior filtro por WHERE Ranking = 1. */

SELECT Anio, ProductName, FirstName, LastName, TotalVentas
FROM (
    SELECT EXTRACT(YEAR FROM o.OrderDate)  AS Anio,
           p.ProductName,
           e.FirstName,
           e.LastName,
           SUM(od.Quantity * od.UnitPrice) AS TotalVentas,
           RANK() OVER (
               PARTITION BY EXTRACT(YEAR FROM o.OrderDate), p.ProductID
               ORDER BY SUM(od.Quantity * od.UnitPrice) DESC
           ) AS Ranking
    FROM Employees e
    JOIN Orders o        ON e.EmployeeID = o.EmployeeID
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    JOIN Products p      ON od.ProductID = p.ProductID
    GROUP BY EXTRACT(YEAR FROM o.OrderDate), p.ProductID, p.ProductName, e.EmployeeID, e.FirstName, e.LastName
) ranked
WHERE Ranking = 1
ORDER BY Anio, ProductName;

-- Query 6.6. Total sales and average monthly sales by employee and 

SELECT e.FirstName, e.LastName,
       EXTRACT(YEAR FROM o.OrderDate) AS Anio,
       SUM(od.Quantity * od.UnitPrice) AS TotalVentas,
       SUM(od.Quantity * od.UnitPrice) / COUNT(DISTINCT EXTRACT(MONTH FROM o.OrderDate)) AS PromedioMensual
FROM Employees e
JOIN Orders o        ON e.EmployeeID = o.EmployeeID
JOIN OrderDetails od ON o.OrderID = od.OrderID
GROUP BY e.EmployeeID, e.FirstName, e.LastName, EXTRACT(YEAR FROM o.OrderDate)
ORDER BY e.LastName, e.FirstName, Anio;
/*El DISTINCT dentro del COUNT garantiza que cada mes se cuente una sola vez, aunque el empleado haya tenido múltiples órdenes ese mes.*/

/* Con subconsulta queda de esta manera: */
SELECT FirstName, LastName, Anio,
       SUM(TotalMes)  AS TotalVentas,
       AVG(TotalMes)  AS PromedioMensual -- uso AVG (mas correcto conceptualmente)
FROM (
    SELECT e.FirstName, e.LastName,
           EXTRACT(YEAR FROM o.OrderDate)  AS Anio,
           EXTRACT(MONTH FROM o.OrderDate) AS Mes,
           SUM(od.Quantity * od.UnitPrice) AS TotalMes
    FROM Employees e
    JOIN Orders o        ON e.EmployeeID = o.EmployeeID
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    GROUP BY e.EmployeeID, e.FirstName, e.LastName,
             EXTRACT(YEAR FROM o.OrderDate),
             EXTRACT(MONTH FROM o.OrderDate)
) mensual
GROUP BY FirstName, LastName, Anio
ORDER BY LastName, FirstName, Anio;

-- Query 6.7. Total sales amount and total discount amount per product and month.

SELECT p.ProductName,
       EXTRACT(YEAR FROM o.OrderDate)  AS Anio,
       EXTRACT(MONTH FROM o.OrderDate) AS Mes,
       SUM(od.Quantity * od.UnitPrice)                     AS TotalVentas,
       SUM(od.Quantity * od.UnitPrice * od.Discount)       AS TotalDescuento
FROM Products p
JOIN OrderDetails od ON p.ProductID = od.ProductID
JOIN Orders o        ON od.OrderID = o.OrderID
GROUP BY p.ProductID, p.ProductName,
         EXTRACT(YEAR FROM o.OrderDate),
         EXTRACT(MONTH FROM o.OrderDate)
ORDER BY p.ProductName, Anio, Mes;

-- Query 6.8. Monthly year-to-date sales for each product category.

SELECT cat.CategoryName,
       EXTRACT(YEAR FROM o.OrderDate)  AS Anio,
       EXTRACT(MONTH FROM o.OrderDate) AS Mes,
       SUM(od.Quantity * od.UnitPrice) AS VentasMes,
       SUM(SUM(od.Quantity * od.UnitPrice)) OVER (
           PARTITION BY cat.CategoryID, EXTRACT(YEAR FROM o.OrderDate) -- reinicia cada año
           ORDER BY EXTRACT(MONTH FROM o.OrderDate) -- acumula mes a mes
       ) AS VentasAcumuladas
FROM Categories cat
JOIN Products p      ON cat.CategoryID = p.CategoryID
JOIN OrderDetails od ON p.ProductID = od.ProductID
JOIN Orders o        ON od.OrderID = o.OrderID
GROUP BY cat.CategoryID, cat.CategoryName,
         EXTRACT(YEAR FROM o.OrderDate),
         EXTRACT(MONTH FROM o.OrderDate)
ORDER BY cat.CategoryName, Anio, Mes;

-- Query 6.9. Promedio móvil de los últimos 3 meses del monto de ventas por categoría de producto.

SELECT cat.CategoryName,
       EXTRACT(YEAR FROM o.OrderDate)  AS Anio,
       EXTRACT(MONTH FROM o.OrderDate) AS Mes,
       SUM(od.Quantity * od.UnitPrice) AS VentasMes,
       ROUND(AVG(SUM(od.Quantity * od.UnitPrice)) OVER (
           PARTITION BY cat.CategoryID
           ORDER BY EXTRACT(YEAR FROM o.OrderDate),
                    EXTRACT(MONTH FROM o.OrderDate)
           ROWS BETWEEN 2 PRECEDING AND CURRENT ROW -- tomo la fila actual y las 2 anteriores
       ), 1) AS MediaMovil3Meses
FROM Categories cat
JOIN Products p      ON cat.CategoryID = p.CategoryID
JOIN OrderDetails od ON p.ProductID = od.ProductID
JOIN Orders o        ON od.OrderID = o.OrderID
GROUP BY cat.CategoryID, cat.CategoryName,
         EXTRACT(YEAR FROM o.OrderDate),
         EXTRACT(MONTH FROM o.OrderDate)
ORDER BY cat.CategoryName, Anio, Mes;

-- Query 6.10. For each month, total number of orders, total sales amount, and average sales amount by order. 

SELECT EXTRACT(YEAR FROM o.OrderDate)  AS Anio,
       EXTRACT(MONTH FROM o.OrderDate) AS Mes,
       COUNT(DISTINCT o.OrderID)       AS CantidadOrdenes,
       SUM(od.Quantity * od.UnitPrice) AS TotalVentas,
       ROUND(SUM(od.Quantity * od.UnitPrice) / COUNT(DISTINCT o.OrderID), 2) AS PromedioVentaPorOrden
FROM Orders o
JOIN OrderDetails od ON o.OrderID = od.OrderID
GROUP BY EXTRACT(YEAR FROM o.OrderDate),
         EXTRACT(MONTH FROM o.OrderDate)
ORDER BY Anio, Mes;
