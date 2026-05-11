-- 1

SELECT DISTINCT p.ProductName
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
WHERE c.City = 'Madrid';

-- 2

SELECT p.ProductName, SUM(od.Quantity) AS TotalPedido
FROM Products p
JOIN OrderDetails od ON p.ProductID = od.ProductID
GROUP BY p.ProductID, p.ProductName
ORDER BY TotalPedido DESC;

--3 

SELECT c.ContactName AS nombre_cliente
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
GROUP BY c.CustomerID, c.ContactName
HAVING COUNT(DISTINCT od.ProductID) >= 10;

--4 

SELECT DISTINCT c1.ContactName AS Cliente1,
                c2.ContactName AS Cliente2
FROM Customers c1
JOIN Orders o1       ON c1.CustomerID = o1.CustomerID
JOIN OrderDetails od1 ON o1.OrderID = od1.OrderID
JOIN OrderDetails od2 ON od1.ProductID = od2.ProductID
JOIN Orders o2       ON od2.OrderID = o2.OrderID
JOIN Customers c2    ON o2.CustomerID = c2.CustomerID
WHERE c1.CustomerID < c2.CustomerID;

-- 5

SELECT p.ProductName
FROM Products p
LEFT JOIN OrderDetails od ON p.ProductID = od.ProductID
WHERE od.ProductID IS NULL;
-- no obtengo ningun valor, verifico:
SELECT COUNT(*) 
FROM Products p
LEFT JOIN OrderDetails od ON p.ProductID = od.ProductID
WHERE od.ProductID IS NULL; -- ok

-- 6

SELECT DISTINCT e.FirstName, e.LastName
FROM Employees e
WHERE e.EmployeeID NOT IN (
    SELECT o.EmployeeID
    FROM Orders o
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    JOIN Categories c ON p.CategoryID = c.CategoryID
    WHERE c.CategoryName = 'Beverages'
    AND o.EmployeeID IS NOT NULL
);

-- 7

SELECT e.FirstName, e.LastName,
       p.ProductName,
       SUM(od.Quantity * od.UnitPrice) AS MontoTotal
FROM Employees e
JOIN Orders o        ON e.EmployeeID = o.EmployeeID
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p      ON od.ProductID = p.ProductID
GROUP BY e.EmployeeID, e.FirstName, e.LastName, p.ProductID, p.ProductName
ORDER BY e.LastName, e.FirstName, MontoTotal DESC;
