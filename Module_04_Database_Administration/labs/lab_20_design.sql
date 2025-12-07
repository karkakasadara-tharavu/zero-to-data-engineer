/*
 * Lab 20: Database Design Fundamentals
 * Module 04: Database Administration
 * 
 * Objective: Design a database schema from business requirements
 * Duration: 2-3 hours
 * Difficulty: ⭐⭐⭐
 */

USE master;
GO

-- Clean up if exists
IF DB_ID('BookstoreDB') IS NOT NULL
BEGIN
    ALTER DATABASE BookstoreDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE BookstoreDB;
END;
GO

/*
 * BUSINESS REQUIREMENTS:
 * 
 * Design a database for an online bookstore with the following requirements:
 * 1. Store information about books (title, ISBN, price, publication date, stock)
 * 2. Track authors (books can have multiple authors)
 * 3. Manage publishers (each book has one publisher)
 * 4. Handle customer information (name, email, phone, address)
 * 5. Process orders (order date, status, total amount)
 * 6. Track order details (which books were ordered, quantities, prices)
 * 7. Store customer reviews (rating, comment, date)
 * 8. Maintain book categories (books can belong to multiple categories)
 */

-- Step 1: Create the database
CREATE DATABASE BookstoreDB;
GO

USE BookstoreDB;
GO

-- Step 2: Create tables with proper design

-- TODO: Create Publishers table
-- Columns: PublisherID (PK, INT, IDENTITY), Name (NVARCHAR(200)), Country, Website, Email

CREATE TABLE Publishers (
    PublisherID INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(200) NOT NULL,
    Country NVARCHAR(100),
    Website NVARCHAR(300),
    Email NVARCHAR(100),
    CreatedDate DATETIME2 DEFAULT GETDATE()
);
GO

-- TODO: Create Authors table
-- Columns: AuthorID (PK), FirstName, LastName, Biography, BirthDate, Country

CREATE TABLE Authors (
    AuthorID INT PRIMARY KEY IDENTITY(1,1),
    FirstName NVARCHAR(100) NOT NULL,
    LastName NVARCHAR(100) NOT NULL,
    Biography NVARCHAR(MAX),
    BirthDate DATE,
    Country NVARCHAR(100),
    CreatedDate DATETIME2 DEFAULT GETDATE()
);
GO

-- TODO: Create Categories table
-- Columns: CategoryID (PK), CategoryName, Description

CREATE TABLE Categories (
    CategoryID INT PRIMARY KEY IDENTITY(1,1),
    CategoryName NVARCHAR(100) NOT NULL UNIQUE,
    Description NVARCHAR(500),
    CreatedDate DATETIME2 DEFAULT GETDATE()
);
GO

-- TODO: Create Books table
-- Columns: BookID (PK), Title, ISBN, PublisherID (FK), PublicationDate, Price, StockQuantity
-- Add CHECK constraint: Price > 0, StockQuantity >= 0

CREATE TABLE Books (
    BookID INT PRIMARY KEY IDENTITY(1,1),
    Title NVARCHAR(300) NOT NULL,
    ISBN NVARCHAR(20) UNIQUE NOT NULL,
    PublisherID INT NOT NULL,
    PublicationDate DATE,
    Price DECIMAL(10,2) NOT NULL,
    StockQuantity INT NOT NULL DEFAULT 0,
    Description NVARCHAR(MAX),
    PageCount INT,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    
    CONSTRAINT FK_Books_Publishers FOREIGN KEY (PublisherID) 
        REFERENCES Publishers(PublisherID),
    CONSTRAINT CK_Books_Price CHECK (Price > 0),
    CONSTRAINT CK_Books_Stock CHECK (StockQuantity >= 0)
);
GO

-- TODO: Create junction table for many-to-many: Books <-> Authors
-- Table: BookAuthors
-- Columns: BookID, AuthorID (composite PK)

CREATE TABLE BookAuthors (
    BookID INT NOT NULL,
    AuthorID INT NOT NULL,
    AuthorOrder INT DEFAULT 1,  -- For multiple authors, track order
    
    PRIMARY KEY (BookID, AuthorID),
    CONSTRAINT FK_BookAuthors_Books FOREIGN KEY (BookID) 
        REFERENCES Books(BookID) ON DELETE CASCADE,
    CONSTRAINT FK_BookAuthors_Authors FOREIGN KEY (AuthorID) 
        REFERENCES Authors(AuthorID) ON DELETE CASCADE
);
GO

-- TODO: Create junction table for many-to-many: Books <-> Categories
-- Table: BookCategories
-- Columns: BookID, CategoryID (composite PK)

CREATE TABLE BookCategories (
    BookID INT NOT NULL,
    CategoryID INT NOT NULL,
    
    PRIMARY KEY (BookID, CategoryID),
    CONSTRAINT FK_BookCategories_Books FOREIGN KEY (BookID) 
        REFERENCES Books(BookID) ON DELETE CASCADE,
    CONSTRAINT FK_BookCategories_Categories FOREIGN KEY (CategoryID) 
        REFERENCES Categories(CategoryID) ON DELETE CASCADE
);
GO

-- TODO: Create Customers table
-- Columns: CustomerID (PK), Email (UNIQUE), FirstName, LastName, Phone, AddressLine1, City, State, ZipCode

CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY IDENTITY(1,1),
    Email NVARCHAR(100) NOT NULL UNIQUE,
    FirstName NVARCHAR(100) NOT NULL,
    LastName NVARCHAR(100) NOT NULL,
    Phone NVARCHAR(20),
    AddressLine1 NVARCHAR(200),
    AddressLine2 NVARCHAR(200),
    City NVARCHAR(100),
    State NVARCHAR(50),
    ZipCode NVARCHAR(10),
    Country NVARCHAR(100) DEFAULT 'USA',
    CreatedDate DATETIME2 DEFAULT GETDATE()
);
GO

-- TODO: Create Orders table
-- Columns: OrderID (PK), CustomerID (FK), OrderDate, Status, TotalAmount
-- Status options: 'Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled'

CREATE TABLE Orders (
    OrderID INT PRIMARY KEY IDENTITY(1,1),
    CustomerID INT NOT NULL,
    OrderDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    Status NVARCHAR(20) NOT NULL DEFAULT 'Pending',
    TotalAmount DECIMAL(10,2) NOT NULL DEFAULT 0,
    ShippingAddress NVARCHAR(500),
    
    CONSTRAINT FK_Orders_Customers FOREIGN KEY (CustomerID) 
        REFERENCES Customers(CustomerID),
    CONSTRAINT CK_Orders_Status CHECK (Status IN 
        ('Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled')),
    CONSTRAINT CK_Orders_TotalAmount CHECK (TotalAmount >= 0)
);
GO

-- TODO: Create OrderDetails table
-- Columns: OrderDetailID (PK), OrderID (FK), BookID (FK), Quantity, UnitPrice, Subtotal
-- Subtotal should be calculated as Quantity * UnitPrice

CREATE TABLE OrderDetails (
    OrderDetailID INT PRIMARY KEY IDENTITY(1,1),
    OrderID INT NOT NULL,
    BookID INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    Subtotal AS (Quantity * UnitPrice) PERSISTED,  -- Computed column
    
    CONSTRAINT FK_OrderDetails_Orders FOREIGN KEY (OrderID) 
        REFERENCES Orders(OrderID) ON DELETE CASCADE,
    CONSTRAINT FK_OrderDetails_Books FOREIGN KEY (BookID) 
        REFERENCES Books(BookID),
    CONSTRAINT CK_OrderDetails_Quantity CHECK (Quantity > 0),
    CONSTRAINT CK_OrderDetails_UnitPrice CHECK (UnitPrice > 0)
);
GO

-- TODO: Create Reviews table
-- Columns: ReviewID (PK), BookID (FK), CustomerID (FK), Rating, ReviewText, ReviewDate
-- Rating should be between 1 and 5

CREATE TABLE Reviews (
    ReviewID INT PRIMARY KEY IDENTITY(1,1),
    BookID INT NOT NULL,
    CustomerID INT NOT NULL,
    Rating INT NOT NULL,
    ReviewText NVARCHAR(MAX),
    ReviewDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    HelpfulCount INT DEFAULT 0,
    
    CONSTRAINT FK_Reviews_Books FOREIGN KEY (BookID) 
        REFERENCES Books(BookID) ON DELETE CASCADE,
    CONSTRAINT FK_Reviews_Customers FOREIGN KEY (CustomerID) 
        REFERENCES Customers(CustomerID),
    CONSTRAINT CK_Reviews_Rating CHECK (Rating BETWEEN 1 AND 5),
    CONSTRAINT UQ_Reviews_BookCustomer UNIQUE (BookID, CustomerID)  -- One review per customer per book
);
GO

-- Step 3: Insert sample data

-- Publishers
INSERT INTO Publishers (Name, Country, Website, Email) VALUES
('Penguin Random House', 'USA', 'www.penguinrandomhouse.com', 'contact@prh.com'),
('HarperCollins', 'USA', 'www.harpercollins.com', 'info@hc.com'),
('Simon & Schuster', 'USA', 'www.simonandschuster.com', 'contact@ss.com'),
('Hachette Book Group', 'USA', 'www.hachettebookgroup.com', 'info@hbg.com'),
('Macmillan Publishers', 'UK', 'www.macmillan.com', 'contact@macmillan.com');

-- Authors
INSERT INTO Authors (FirstName, LastName, Biography, BirthDate, Country) VALUES
('George', 'Orwell', 'English novelist and essayist', '1903-06-25', 'UK'),
('Jane', 'Austen', 'English novelist', '1775-12-16', 'UK'),
('Ernest', 'Hemingway', 'American novelist', '1899-07-21', 'USA'),
('Agatha', 'Christie', 'English mystery writer', '1890-09-15', 'UK'),
('J.K.', 'Rowling', 'British author', '1965-07-31', 'UK');

-- Categories
INSERT INTO Categories (CategoryName, Description) VALUES
('Fiction', 'Literary fiction and novels'),
('Mystery', 'Mystery and thriller books'),
('Science Fiction', 'Science fiction and fantasy'),
('Romance', 'Romantic fiction'),
('Biography', 'Biographical and autobiographical works'),
('History', 'Historical non-fiction'),
('Self-Help', 'Personal development books');

-- Books
INSERT INTO Books (Title, ISBN, PublisherID, PublicationDate, Price, StockQuantity, PageCount) VALUES
('1984', '978-0-452-28423-4', 1, '1949-06-08', 15.99, 120, 328),
('Animal Farm', '978-0-452-28424-1', 1, '1945-08-17', 12.99, 85, 112),
('Pride and Prejudice', '978-0-14-143951-8', 2, '1813-01-28', 11.99, 95, 432),
('The Old Man and the Sea', '978-0-684-80122-3', 3, '1952-09-01', 14.99, 60, 127),
('Murder on the Orient Express', '978-0-06-207348-7', 4, '1934-01-01', 13.99, 75, 256);

-- BookAuthors (linking books to authors)
INSERT INTO BookAuthors (BookID, AuthorID, AuthorOrder) VALUES
(1, 1, 1),  -- 1984 by George Orwell
(2, 1, 1),  -- Animal Farm by George Orwell
(3, 2, 1),  -- Pride and Prejudice by Jane Austen
(4, 3, 1),  -- The Old Man and the Sea by Hemingway
(5, 4, 1);  -- Murder on the Orient Express by Agatha Christie

-- BookCategories
INSERT INTO BookCategories (BookID, CategoryID) VALUES
(1, 1), (1, 3),  -- 1984: Fiction, Science Fiction
(2, 1),          -- Animal Farm: Fiction
(3, 1), (3, 4),  -- Pride and Prejudice: Fiction, Romance
(4, 1),          -- The Old Man and the Sea: Fiction
(5, 2);          -- Murder on the Orient Express: Mystery

-- Customers
INSERT INTO Customers (Email, FirstName, LastName, Phone, AddressLine1, City, State, ZipCode) VALUES
('john.doe@email.com', 'John', 'Doe', '555-0101', '123 Main St', 'New York', 'NY', '10001'),
('jane.smith@email.com', 'Jane', 'Smith', '555-0102', '456 Oak Ave', 'Los Angeles', 'CA', '90001'),
('bob.johnson@email.com', 'Bob', 'Johnson', '555-0103', '789 Pine Rd', 'Chicago', 'IL', '60601');

-- Orders
INSERT INTO Orders (CustomerID, OrderDate, Status, TotalAmount, ShippingAddress) VALUES
(1, '2024-01-15', 'Delivered', 28.98, '123 Main St, New York, NY 10001'),
(2, '2024-01-20', 'Shipped', 26.98, '456 Oak Ave, Los Angeles, CA 90001'),
(3, '2024-01-25', 'Processing', 14.99, '789 Pine Rd, Chicago, IL 60601');

-- OrderDetails
INSERT INTO OrderDetails (OrderID, BookID, Quantity, UnitPrice) VALUES
(1, 1, 1, 15.99),  -- Order 1: 1984
(1, 2, 1, 12.99),  -- Order 1: Animal Farm
(2, 3, 1, 11.99),  -- Order 2: Pride and Prejudice
(2, 4, 1, 14.99),  -- Order 2: The Old Man and the Sea
(3, 5, 1, 14.99);  -- Order 3: Murder on the Orient Express

-- Reviews
INSERT INTO Reviews (BookID, CustomerID, Rating, ReviewText) VALUES
(1, 1, 5, 'A masterpiece of dystopian fiction. Still relevant today!'),
(2, 2, 4, 'Great allegory. Short but powerful.'),
(3, 2, 5, 'Beautiful romance and witty dialogue.'),
(5, 3, 5, 'Classic Agatha Christie. Could not put it down!');

GO

-- Step 4: Verification queries

PRINT 'Database Design Lab 20 - Verification';
PRINT '=====================================';
PRINT '';

-- Check table counts
SELECT 'Publishers' AS TableName, COUNT(*) AS RecordCount FROM Publishers
UNION ALL
SELECT 'Authors', COUNT(*) FROM Authors
UNION ALL
SELECT 'Categories', COUNT(*) FROM Categories
UNION ALL
SELECT 'Books', COUNT(*) FROM Books
UNION ALL
SELECT 'BookAuthors', COUNT(*) FROM BookAuthors
UNION ALL
SELECT 'BookCategories', COUNT(*) FROM BookCategories
UNION ALL
SELECT 'Customers', COUNT(*) FROM Customers
UNION ALL
SELECT 'Orders', COUNT(*) FROM Orders
UNION ALL
SELECT 'OrderDetails', COUNT(*) FROM OrderDetails
UNION ALL
SELECT 'Reviews', COUNT(*) FROM Reviews
ORDER BY TableName;

-- Sample queries to verify relationships
PRINT '';
PRINT 'Books with Authors and Publishers:';
SELECT 
    b.Title,
    STRING_AGG(a.FirstName + ' ' + a.LastName, ', ') AS Authors,
    p.Name AS Publisher,
    b.Price,
    b.StockQuantity
FROM Books b
JOIN Publishers p ON b.PublisherID = p.PublisherID
JOIN BookAuthors ba ON b.BookID = ba.BookID
JOIN Authors a ON ba.AuthorID = a.AuthorID
GROUP BY b.BookID, b.Title, p.Name, b.Price, b.StockQuantity
ORDER BY b.Title;

PRINT '';
PRINT 'Order Summary with Customer Details:';
SELECT 
    o.OrderID,
    c.FirstName + ' ' + c.LastName AS CustomerName,
    o.OrderDate,
    o.Status,
    o.TotalAmount,
    COUNT(od.OrderDetailID) AS ItemCount
FROM Orders o
JOIN Customers c ON o.CustomerID = c.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
GROUP BY o.OrderID, c.FirstName, c.LastName, o.OrderDate, o.Status, o.TotalAmount
ORDER BY o.OrderDate DESC;

GO

/*
 * EXERCISES:
 * 
 * 1. Add a WishList table to track books customers want to buy later
 * 2. Create an Inventory table to track book locations in warehouses
 * 3. Add a Promotions table for discount codes
 * 4. Design a table structure for book series (books that belong to a series)
 * 5. Create an AuditLog table to track all changes to important tables
 * 
 * CHALLENGE:
 * Draw an ERD (Entity Relationship Diagram) showing all tables and their relationships
 */
