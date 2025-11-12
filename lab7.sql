--1
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY,
    FirstName VARCHAR(50),
    LastName VARCHAR(50),
    Email VARCHAR(100),
    Phone VARCHAR(20)
);

CREATE TABLE Products (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(100),
    Category VARCHAR(50),
    Price DECIMAL(10,2),
    StockQuantity INT
);

CREATE TABLE Orders (
    OrderID INT PRIMARY KEY,
    CustomerID INT,
    OrderDate DATE,
    TotalAmount DECIMAL(10,2),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);

CREATE TABLE OrderDetails (
    OrderDetailID INT PRIMARY KEY,
    OrderID INT,
    ProductID INT,
    Quantity INT,
    UnitPrice DECIMAL(10,2),
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

--2
INSERT INTO Customers VALUES 
(1, 'John', 'Doe', 'john.doe@email.com', '123-456-7890'),
(2, 'Jane', 'Smith', 'jane.smith@email.com', '123-456-7891'),
(3, 'Bob', 'Johnson', 'bob.johnson@email.com', '123-456-7892');

INSERT INTO Products VALUES 
(1, 'Laptop', 'Electronics', 999.99, 10),
(2, 'Smartphone', 'Electronics', 699.99, 15),
(3, 'Desk Chair', 'Furniture', 149.99, 20);

INSERT INTO Orders VALUES 
(1, 1, '2024-01-15', 1149.98),
(2, 2, '2024-01-16', 699.99),
(3, 1, '2024-01-17', 149.99);

INSERT INTO OrderDetails VALUES 
(1, 1, 1, 1, 999.99),
(2, 1, 3, 1, 149.99),
(3, 2, 2, 1, 699.99),
(4, 3, 3, 1, 149.99);

--3
SELECT 
    c.CustomerID,
    c.FirstName,
    c.LastName,
    SUM(o.TotalAmount) AS TotalSales
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.FirstName, c.LastName;

--4
SELECT 
    p.ProductID,
    p.ProductName,
    SUM(od.Quantity) AS TotalQuantitySold
FROM Products p
JOIN OrderDetails od ON p.ProductID = od.ProductID
GROUP BY p.ProductID, p.ProductName
ORDER BY TotalQuantitySold DESC
LIMIT 1;

--5
UPDATE Products 
SET Price = 749.99 
WHERE ProductID = 2;

--6
CREATE VIEW OrderSummary AS
SELECT 
    o.OrderID,
    o.OrderDate,
    c.FirstName,
    c.LastName,
    o.TotalAmount,
    COUNT(od.ProductID) AS NumberOfProducts
FROM Orders o
JOIN Customers c ON o.CustomerID = c.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
GROUP BY o.OrderID, o.OrderDate, c.FirstName, c.LastName, o.TotalAmount;

--7
INSERT INTO Customers VALUES 
(4, 'Alice', 'Brown', 'alice.brown@email.com', '123-456-7893');

--8
DELETE FROM OrderDetails WHERE OrderID = 3;
DELETE FROM Orders WHERE OrderID = 3;

--9
SELECT 
    c.CustomerID,
    c.FirstName,
    c.LastName
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.OrderID IS NULL;

--10
CREATE INDEX idx_customer_email ON Customers(Email);