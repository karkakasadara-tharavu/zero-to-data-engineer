/*
================================================================================
LAB 20A: DATABASE CONSTRAINTS - COMPLETE REFERENCE GUIDE
Module 04: Database Administration
================================================================================

WHAT YOU WILL LEARN:
✅ All constraint types explained with examples
✅ PRIMARY KEY - Identity and purpose
✅ FOREIGN KEY - Referential integrity
✅ UNIQUE - Preventing duplicates
✅ CHECK - Business rule enforcement
✅ DEFAULT - Automatic values
✅ NOT NULL - Required fields
✅ When and how to use each constraint
✅ Interview preparation

DURATION: 2-3 hours
DIFFICULTY: ⭐⭐⭐ (Intermediate)
DATABASE: ConstraintsDemo

================================================================================
SECTION 1: WHY CONSTRAINTS MATTER
================================================================================

WHAT ARE CONSTRAINTS?
---------------------
Constraints are RULES enforced at the database level that ensure data 
INTEGRITY, CONSISTENCY, and VALIDITY. They prevent bad data from ever 
entering your database.

WHY ARE THEY CRITICAL?
----------------------
Without constraints:
❌ Duplicate customer IDs
❌ Orders referencing non-existent customers  
❌ Negative prices and quantities
❌ Dates in wrong format
❌ Missing required fields

With constraints:
✅ Every row has unique identifier
✅ Relationships are always valid
✅ Business rules enforced automatically
✅ Data quality guaranteed
✅ Less application-level validation needed

THE 6 TYPES OF CONSTRAINTS:
---------------------------
1. PRIMARY KEY   - Unique identifier for each row
2. FOREIGN KEY   - Links to another table's primary key
3. UNIQUE        - Prevents duplicate values
4. CHECK         - Validates data against a condition
5. DEFAULT       - Provides automatic values
6. NOT NULL      - Requires a value (cannot be NULL)
*/

-- Create demo database
USE master;
GO

IF DB_ID('ConstraintsDemo') IS NOT NULL
BEGIN
    ALTER DATABASE ConstraintsDemo SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ConstraintsDemo;
END;
GO

CREATE DATABASE ConstraintsDemo;
GO

USE ConstraintsDemo;
GO

-- ============================================================================
-- SECTION 2: PRIMARY KEY CONSTRAINT
-- ============================================================================
/*
WHAT IS A PRIMARY KEY?
----------------------
A PRIMARY KEY uniquely identifies EACH ROW in a table. It's the most 
important constraint for relational databases.

RULES:
- Only ONE primary key per table
- CANNOT contain NULL values
- MUST be UNIQUE (no duplicates)
- Automatically creates a CLUSTERED INDEX (by default)
- Can be SINGLE column or COMPOSITE (multiple columns)

NAMING CONVENTION: PK_TableName
*/

-- Example 1: Simple Primary Key
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY,  -- Inline constraint (no name)
    CustomerName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(255)
);

-- Example 2: Named Primary Key (RECOMMENDED)
CREATE TABLE Products (
    ProductID INT NOT NULL,
    ProductName NVARCHAR(200) NOT NULL,
    Price DECIMAL(10,2),
    
    CONSTRAINT PK_Products PRIMARY KEY (ProductID)  -- Named constraint
);

-- Example 3: Primary Key with IDENTITY (Auto-increment)
CREATE TABLE Orders (
    OrderID INT IDENTITY(1,1),  -- Starts at 1, increments by 1
    CustomerID INT NOT NULL,
    OrderDate DATETIME2 DEFAULT GETDATE(),
    
    CONSTRAINT PK_Orders PRIMARY KEY (OrderID)
);

/*
IDENTITY(seed, increment):
- seed: Starting value (usually 1)
- increment: How much to add for each new row (usually 1)

IMPORTANT: IDENTITY does NOT mean PRIMARY KEY!
           IDENTITY is for auto-generation
           PRIMARY KEY is for uniqueness
           They are often used together but are different concepts.
*/

-- Example 4: Composite Primary Key (Multiple Columns)
CREATE TABLE OrderDetails (
    OrderID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    
    -- Composite PK: Combination of OrderID + ProductID must be unique
    CONSTRAINT PK_OrderDetails PRIMARY KEY (OrderID, ProductID)
);

/*
WHEN TO USE COMPOSITE KEYS:
- Junction tables (many-to-many relationships)
- When no single column uniquely identifies a row
- When the combination is the natural identifier

EXAMPLE: An order can have Product A once, but not twice.
         OrderID=1, ProductID=100 ✓
         OrderID=1, ProductID=101 ✓
         OrderID=1, ProductID=100 ✗ (duplicate!)
*/

-- Demonstrate: Cannot insert duplicate primary keys
INSERT INTO Customers (CustomerID, CustomerName, Email) VALUES (1, 'John Doe', 'john@email.com');
INSERT INTO Customers (CustomerID, CustomerName, Email) VALUES (2, 'Jane Smith', 'jane@email.com');

-- This will FAIL:
-- INSERT INTO Customers (CustomerID, CustomerName, Email) VALUES (1, 'Bob Brown', 'bob@email.com');
-- Error: Violation of PRIMARY KEY constraint

-- This will also FAIL (NULL in PK):
-- INSERT INTO Customers (CustomerID, CustomerName, Email) VALUES (NULL, 'Bob Brown', 'bob@email.com');
-- Error: Cannot insert NULL into column 'CustomerID'

-- ============================================================================
-- SECTION 3: FOREIGN KEY CONSTRAINT
-- ============================================================================
/*
WHAT IS A FOREIGN KEY?
----------------------
A FOREIGN KEY creates a LINK between two tables. It ensures that values 
in the child table MUST exist in the parent table's primary key.

This is called REFERENTIAL INTEGRITY.

RULES:
- References a PRIMARY KEY (or UNIQUE constraint) in another table
- CAN contain NULL values (unless NOT NULL specified)
- CAN have duplicates
- Parent record must exist before child can reference it
- Can define ON DELETE and ON UPDATE actions

NAMING CONVENTION: FK_ChildTable_ParentTable
*/

-- Create parent table
CREATE TABLE Categories (
    CategoryID INT IDENTITY(1,1),
    CategoryName NVARCHAR(100) NOT NULL,
    
    CONSTRAINT PK_Categories PRIMARY KEY (CategoryID)
);

-- Create child table with foreign key
CREATE TABLE ProductsWithFK (
    ProductID INT IDENTITY(1,1),
    ProductName NVARCHAR(200) NOT NULL,
    CategoryID INT NOT NULL,  -- This references Categories
    Price DECIMAL(10,2),
    
    CONSTRAINT PK_ProductsWithFK PRIMARY KEY (ProductID),
    
    -- FOREIGN KEY: CategoryID must exist in Categories table
    CONSTRAINT FK_Products_Categories 
        FOREIGN KEY (CategoryID) 
        REFERENCES Categories(CategoryID)
);

-- Insert parent records first
INSERT INTO Categories (CategoryName) VALUES ('Electronics'), ('Clothing'), ('Books');

-- Now we can insert child records
INSERT INTO ProductsWithFK (ProductName, CategoryID, Price) 
VALUES ('Laptop', 1, 999.99), ('T-Shirt', 2, 29.99), ('SQL Guide', 3, 49.99);

-- This will FAIL (CategoryID 99 doesn't exist):
-- INSERT INTO ProductsWithFK (ProductName, CategoryID, Price) VALUES ('Mystery', 99, 10.00);
-- Error: The INSERT statement conflicted with the FOREIGN KEY constraint

/*
ON DELETE and ON UPDATE OPTIONS:
--------------------------------
What happens when the PARENT record is deleted or updated?

NO ACTION (default):
- Block the delete/update if children exist
- Most restrictive, safest

CASCADE:
- Delete/update all children automatically
- Dangerous! Use with caution

SET NULL:
- Set the foreign key to NULL in children
- Requires FK column to allow NULLs

SET DEFAULT:
- Set the foreign key to its default value
- Requires a DEFAULT constraint
*/

-- Example with CASCADE DELETE (use carefully!)
CREATE TABLE Departments (
    DeptID INT IDENTITY(1,1) PRIMARY KEY,
    DeptName NVARCHAR(100) NOT NULL
);

CREATE TABLE Employees (
    EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeName NVARCHAR(100) NOT NULL,
    DeptID INT,
    
    CONSTRAINT FK_Employees_Departments 
        FOREIGN KEY (DeptID) 
        REFERENCES Departments(DeptID)
        ON DELETE CASCADE      -- Delete employees when department deleted
        ON UPDATE CASCADE      -- Update employees when department ID changes
);

-- Example with SET NULL
CREATE TABLE Projects (
    ProjectID INT IDENTITY(1,1) PRIMARY KEY,
    ProjectName NVARCHAR(100) NOT NULL,
    ManagerID INT NULL,  -- Must allow NULL
    
    CONSTRAINT FK_Projects_Employees 
        FOREIGN KEY (ManagerID) 
        REFERENCES Employees(EmployeeID)
        ON DELETE SET NULL  -- Set to NULL if manager is deleted
);

-- ============================================================================
-- SECTION 4: UNIQUE CONSTRAINT
-- ============================================================================
/*
WHAT IS A UNIQUE CONSTRAINT?
----------------------------
Ensures that ALL values in a column (or combination of columns) are DIFFERENT.

DIFFERENCE FROM PRIMARY KEY:
- Table can have MULTIPLE unique constraints
- UNIQUE allows ONE NULL value (in SQL Server)
- UNIQUE creates a non-clustered index (by default)

NAMING CONVENTION: UQ_TableName_ColumnName
*/

CREATE TABLE Users (
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    Username NVARCHAR(50) NOT NULL,
    Email NVARCHAR(255) NOT NULL,
    Phone NVARCHAR(20),
    
    -- Email must be unique
    CONSTRAINT UQ_Users_Email UNIQUE (Email),
    
    -- Username must be unique
    CONSTRAINT UQ_Users_Username UNIQUE (Username)
);

-- These inserts work:
INSERT INTO Users (Username, Email, Phone) VALUES ('johndoe', 'john@email.com', '555-1234');
INSERT INTO Users (Username, Email, Phone) VALUES ('janesmith', 'jane@email.com', '555-5678');

-- This will FAIL (duplicate email):
-- INSERT INTO Users (Username, Email, Phone) VALUES ('johnsmith', 'john@email.com', '555-9999');
-- Error: Violation of UNIQUE KEY constraint

-- Composite Unique (combination must be unique)
CREATE TABLE Subscriptions (
    SubscriptionID INT IDENTITY(1,1) PRIMARY KEY,
    UserID INT NOT NULL,
    ServiceType NVARCHAR(50) NOT NULL,
    StartDate DATE NOT NULL,
    
    -- User can only have ONE subscription per service type
    CONSTRAINT UQ_Subscriptions_UserService UNIQUE (UserID, ServiceType)
);

-- ============================================================================
-- SECTION 5: CHECK CONSTRAINT
-- ============================================================================
/*
WHAT IS A CHECK CONSTRAINT?
---------------------------
Validates data against a BOOLEAN EXPRESSION. If the expression evaluates 
to FALSE, the insert/update is REJECTED.

USE FOR:
- Range validation (price > 0)
- List of valid values (status IN (...))
- Pattern matching (zip code format)
- Cross-column validation (end_date > start_date)

NAMING CONVENTION: CK_TableName_ColumnName
*/

CREATE TABLE Inventory (
    ItemID INT IDENTITY(1,1) PRIMARY KEY,
    ItemName NVARCHAR(100) NOT NULL,
    Quantity INT NOT NULL,
    Price DECIMAL(10,2) NOT NULL,
    Status NVARCHAR(20) NOT NULL,
    DiscountPercent DECIMAL(5,2),
    MinStock INT DEFAULT 10,
    MaxStock INT DEFAULT 1000,
    
    -- Quantity cannot be negative
    CONSTRAINT CK_Inventory_Quantity CHECK (Quantity >= 0),
    
    -- Price must be positive
    CONSTRAINT CK_Inventory_Price CHECK (Price > 0),
    
    -- Status must be one of these values
    CONSTRAINT CK_Inventory_Status CHECK (Status IN ('Active', 'Inactive', 'Discontinued')),
    
    -- Discount between 0 and 100
    CONSTRAINT CK_Inventory_Discount CHECK (DiscountPercent >= 0 AND DiscountPercent <= 100),
    
    -- Cross-column check: MaxStock must be greater than MinStock
    CONSTRAINT CK_Inventory_StockRange CHECK (MaxStock > MinStock)
);

-- Valid insert:
INSERT INTO Inventory (ItemName, Quantity, Price, Status, DiscountPercent)
VALUES ('Widget', 100, 29.99, 'Active', 10);

-- This will FAIL (negative quantity):
-- INSERT INTO Inventory (ItemName, Quantity, Price, Status) VALUES ('Widget', -5, 29.99, 'Active');
-- Error: The INSERT statement conflicted with the CHECK constraint

-- This will FAIL (invalid status):
-- INSERT INTO Inventory (ItemName, Quantity, Price, Status) VALUES ('Widget', 10, 29.99, 'Unknown');
-- Error: The INSERT statement conflicted with the CHECK constraint

-- Date validation example
CREATE TABLE Events (
    EventID INT IDENTITY(1,1) PRIMARY KEY,
    EventName NVARCHAR(200) NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    
    -- End date must be on or after start date
    CONSTRAINT CK_Events_DateRange CHECK (EndDate >= StartDate)
);

-- ============================================================================
-- SECTION 6: DEFAULT CONSTRAINT
-- ============================================================================
/*
WHAT IS A DEFAULT CONSTRAINT?
-----------------------------
Provides an AUTOMATIC VALUE when no value is specified during INSERT.

USE FOR:
- Timestamps (CreatedDate = GETDATE())
- Status fields (Status = 'Active')
- Counters (ViewCount = 0)
- Boolean flags (IsActive = 1)

NAMING CONVENTION: DF_TableName_ColumnName
*/

CREATE TABLE Articles (
    ArticleID INT IDENTITY(1,1) PRIMARY KEY,
    Title NVARCHAR(200) NOT NULL,
    Content NVARCHAR(MAX),
    Author NVARCHAR(100),
    
    -- Default values
    CreatedDate DATETIME2 CONSTRAINT DF_Articles_CreatedDate DEFAULT GETDATE(),
    ModifiedDate DATETIME2 CONSTRAINT DF_Articles_ModifiedDate DEFAULT GETDATE(),
    Status NVARCHAR(20) CONSTRAINT DF_Articles_Status DEFAULT 'Draft',
    ViewCount INT CONSTRAINT DF_Articles_ViewCount DEFAULT 0,
    IsPublished BIT CONSTRAINT DF_Articles_IsPublished DEFAULT 0
);

-- Insert without specifying default columns:
INSERT INTO Articles (Title, Content, Author)
VALUES ('SQL Basics', 'Learn SQL...', 'John Doe');

-- Check the defaults were applied:
SELECT * FROM Articles;
-- CreatedDate = current datetime
-- Status = 'Draft'
-- ViewCount = 0
-- IsPublished = 0

-- You can override defaults:
INSERT INTO Articles (Title, Content, Author, Status, IsPublished)
VALUES ('Advanced SQL', 'Master SQL...', 'Jane Smith', 'Published', 1);

-- ============================================================================
-- SECTION 7: NOT NULL CONSTRAINT
-- ============================================================================
/*
WHAT IS NOT NULL?
-----------------
Requires that a column MUST have a value - NULL is not allowed.

THIS IS THE MOST BASIC FORM OF DATA VALIDATION!

IMPORTANT: NOT NULL is defined inline, not as a named constraint.

WHEN TO USE:
- Primary keys (automatically NOT NULL)
- Required fields (name, email, etc.)
- Foreign keys (usually)
- Any field that must have a value
*/

CREATE TABLE Contacts (
    ContactID INT IDENTITY(1,1) PRIMARY KEY,
    
    -- Required fields
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(255) NOT NULL,
    
    -- Optional fields
    Phone NVARCHAR(20) NULL,      -- Explicitly allows NULL
    Address NVARCHAR(200),         -- Implicitly allows NULL
    Notes NVARCHAR(MAX)            -- Implicitly allows NULL
);

-- Valid insert:
INSERT INTO Contacts (FirstName, LastName, Email)
VALUES ('John', 'Doe', 'john@email.com');

-- This will FAIL (missing required field):
-- INSERT INTO Contacts (FirstName, Email) VALUES ('Jane', 'jane@email.com');
-- Error: Cannot insert the value NULL into column 'LastName'

-- ============================================================================
-- SECTION 8: VIEWING AND MANAGING CONSTRAINTS
-- ============================================================================

-- View all constraints in the database
SELECT 
    tc.TABLE_NAME,
    tc.CONSTRAINT_NAME,
    tc.CONSTRAINT_TYPE
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
ORDER BY tc.TABLE_NAME, tc.CONSTRAINT_TYPE;

-- View constraint details
SELECT 
    OBJECT_NAME(parent_object_id) AS TableName,
    name AS ConstraintName,
    type_desc AS ConstraintType,
    definition  -- For CHECK constraints
FROM sys.check_constraints
ORDER BY TableName;

-- View foreign key relationships
SELECT 
    fk.name AS ForeignKeyName,
    OBJECT_NAME(fk.parent_object_id) AS ChildTable,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS ChildColumn,
    OBJECT_NAME(fk.referenced_object_id) AS ParentTable,
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS ParentColumn,
    fk.delete_referential_action_desc AS OnDelete,
    fk.update_referential_action_desc AS OnUpdate
FROM sys.foreign_keys fk
INNER JOIN sys.foreign_key_columns fkc 
    ON fk.object_id = fkc.constraint_object_id;

-- ============================================================================
-- SECTION 9: ADDING AND REMOVING CONSTRAINTS
-- ============================================================================

-- Add a constraint to an existing table
ALTER TABLE Customers
ADD CONSTRAINT UQ_Customers_Email UNIQUE (Email);

-- Add a CHECK constraint
ALTER TABLE Products
ADD CONSTRAINT CK_Products_Price CHECK (Price >= 0);

-- Add a DEFAULT constraint
ALTER TABLE Products
ADD CONSTRAINT DF_Products_Price DEFAULT 0.00 FOR Price;

-- Add a FOREIGN KEY
ALTER TABLE Orders
ADD CONSTRAINT FK_Orders_Customers 
    FOREIGN KEY (CustomerID) 
    REFERENCES Customers(CustomerID);

-- REMOVE (DROP) a constraint
ALTER TABLE Customers
DROP CONSTRAINT UQ_Customers_Email;

-- DISABLE a constraint (temporarily, for bulk loads)
ALTER TABLE Orders
NOCHECK CONSTRAINT FK_Orders_Customers;

-- RE-ENABLE a constraint
ALTER TABLE Orders
CHECK CONSTRAINT FK_Orders_Customers;

-- ============================================================================
-- SECTION 10: COMPREHENSIVE EXAMPLE - E-COMMERCE DATABASE
-- ============================================================================

-- Drop if exists
IF OBJECT_ID('OrderItems', 'U') IS NOT NULL DROP TABLE OrderItems;
IF OBJECT_ID('CustomerOrders', 'U') IS NOT NULL DROP TABLE CustomerOrders;
IF OBJECT_ID('ProductCatalog', 'U') IS NOT NULL DROP TABLE ProductCatalog;
IF OBJECT_ID('ProductCategories', 'U') IS NOT NULL DROP TABLE ProductCategories;
IF OBJECT_ID('CustomerAccounts', 'U') IS NOT NULL DROP TABLE CustomerAccounts;
GO

-- Customers table with all constraint types
CREATE TABLE CustomerAccounts (
    CustomerID INT IDENTITY(1,1),
    Email NVARCHAR(255) NOT NULL,
    PasswordHash NVARCHAR(255) NOT NULL,
    FirstName NVARCHAR(100) NOT NULL,
    LastName NVARCHAR(100) NOT NULL,
    Phone NVARCHAR(20),
    DateOfBirth DATE,
    LoyaltyPoints INT,
    Status NVARCHAR(20),
    CreatedDate DATETIME2,
    LastLoginDate DATETIME2,
    
    -- PRIMARY KEY
    CONSTRAINT PK_CustomerAccounts PRIMARY KEY (CustomerID),
    
    -- UNIQUE constraints
    CONSTRAINT UQ_CustomerAccounts_Email UNIQUE (Email),
    
    -- CHECK constraints
    CONSTRAINT CK_CustomerAccounts_Email 
        CHECK (Email LIKE '%_@_%.__%'),  -- Basic email format
    CONSTRAINT CK_CustomerAccounts_Status 
        CHECK (Status IN ('Active', 'Inactive', 'Suspended', 'Deleted')),
    CONSTRAINT CK_CustomerAccounts_Points 
        CHECK (LoyaltyPoints >= 0),
    CONSTRAINT CK_CustomerAccounts_DOB 
        CHECK (DateOfBirth < GETDATE()),  -- Must be in the past
    
    -- DEFAULT constraints
    CONSTRAINT DF_CustomerAccounts_Points DEFAULT 0 FOR LoyaltyPoints,
    CONSTRAINT DF_CustomerAccounts_Status DEFAULT 'Active' FOR Status,
    CONSTRAINT DF_CustomerAccounts_CreatedDate DEFAULT GETDATE() FOR CreatedDate
);

-- Categories
CREATE TABLE ProductCategories (
    CategoryID INT IDENTITY(1,1),
    CategoryName NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500),
    IsActive BIT,
    
    CONSTRAINT PK_ProductCategories PRIMARY KEY (CategoryID),
    CONSTRAINT UQ_ProductCategories_Name UNIQUE (CategoryName),
    CONSTRAINT DF_ProductCategories_IsActive DEFAULT 1 FOR IsActive
);

-- Products with foreign key
CREATE TABLE ProductCatalog (
    ProductID INT IDENTITY(1,1),
    SKU NVARCHAR(50) NOT NULL,
    ProductName NVARCHAR(200) NOT NULL,
    Description NVARCHAR(MAX),
    CategoryID INT NOT NULL,
    Price DECIMAL(10,2) NOT NULL,
    CostPrice DECIMAL(10,2),
    StockQuantity INT NOT NULL,
    ReorderLevel INT,
    Status NVARCHAR(20),
    CreatedDate DATETIME2,
    
    -- PRIMARY KEY
    CONSTRAINT PK_ProductCatalog PRIMARY KEY (ProductID),
    
    -- UNIQUE
    CONSTRAINT UQ_ProductCatalog_SKU UNIQUE (SKU),
    
    -- FOREIGN KEY
    CONSTRAINT FK_ProductCatalog_Categories 
        FOREIGN KEY (CategoryID) 
        REFERENCES ProductCategories(CategoryID),
    
    -- CHECK constraints
    CONSTRAINT CK_ProductCatalog_Price CHECK (Price > 0),
    CONSTRAINT CK_ProductCatalog_CostPrice CHECK (CostPrice IS NULL OR CostPrice >= 0),
    CONSTRAINT CK_ProductCatalog_Stock CHECK (StockQuantity >= 0),
    CONSTRAINT CK_ProductCatalog_Margin CHECK (CostPrice IS NULL OR Price >= CostPrice),
    CONSTRAINT CK_ProductCatalog_Status 
        CHECK (Status IN ('Active', 'Inactive', 'OutOfStock', 'Discontinued')),
    
    -- DEFAULTS
    CONSTRAINT DF_ProductCatalog_Stock DEFAULT 0 FOR StockQuantity,
    CONSTRAINT DF_ProductCatalog_Status DEFAULT 'Active' FOR Status,
    CONSTRAINT DF_ProductCatalog_Created DEFAULT GETDATE() FOR CreatedDate
);

-- Orders
CREATE TABLE CustomerOrders (
    OrderID INT IDENTITY(1001, 1),  -- Start at 1001
    CustomerID INT NOT NULL,
    OrderDate DATETIME2,
    RequiredDate DATE,
    ShippedDate DATE,
    Status NVARCHAR(20),
    TotalAmount DECIMAL(12,2),
    ShippingAddress NVARCHAR(500) NOT NULL,
    Notes NVARCHAR(MAX),
    
    CONSTRAINT PK_CustomerOrders PRIMARY KEY (OrderID),
    
    CONSTRAINT FK_CustomerOrders_Customers 
        FOREIGN KEY (CustomerID) 
        REFERENCES CustomerAccounts(CustomerID),
    
    CONSTRAINT CK_CustomerOrders_Status 
        CHECK (Status IN ('Pending', 'Confirmed', 'Processing', 'Shipped', 'Delivered', 'Cancelled')),
    CONSTRAINT CK_CustomerOrders_Dates 
        CHECK (ShippedDate IS NULL OR ShippedDate >= OrderDate),
    CONSTRAINT CK_CustomerOrders_Total 
        CHECK (TotalAmount >= 0),
    
    CONSTRAINT DF_CustomerOrders_Date DEFAULT GETDATE() FOR OrderDate,
    CONSTRAINT DF_CustomerOrders_Status DEFAULT 'Pending' FOR Status,
    CONSTRAINT DF_CustomerOrders_Total DEFAULT 0 FOR TotalAmount
);

-- Order Items (Junction table)
CREATE TABLE OrderItems (
    OrderID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    Discount DECIMAL(5,2),
    LineTotal AS (Quantity * UnitPrice * (1 - ISNULL(Discount, 0) / 100)) PERSISTED,
    
    -- COMPOSITE PRIMARY KEY
    CONSTRAINT PK_OrderItems PRIMARY KEY (OrderID, ProductID),
    
    -- FOREIGN KEYS
    CONSTRAINT FK_OrderItems_Orders 
        FOREIGN KEY (OrderID) 
        REFERENCES CustomerOrders(OrderID)
        ON DELETE CASCADE,  -- Delete items when order is deleted
    CONSTRAINT FK_OrderItems_Products 
        FOREIGN KEY (ProductID) 
        REFERENCES ProductCatalog(ProductID),
    
    -- CHECK constraints
    CONSTRAINT CK_OrderItems_Quantity CHECK (Quantity > 0),
    CONSTRAINT CK_OrderItems_Price CHECK (UnitPrice > 0),
    CONSTRAINT CK_OrderItems_Discount CHECK (Discount IS NULL OR (Discount >= 0 AND Discount <= 100))
);

PRINT 'E-commerce database schema created successfully!';
GO

-- ============================================================================
-- SECTION 11: INTERVIEW QUESTIONS AND ANSWERS
-- ============================================================================
/*
================================================================================
INTERVIEW FOCUS: DATABASE CONSTRAINTS - Top 20 Questions
================================================================================

Q1: What is the difference between PRIMARY KEY and UNIQUE constraint?
A1: 
    PRIMARY KEY:
    - Only ONE per table
    - Cannot contain NULL values
    - Creates CLUSTERED index by default
    - Identifies each row uniquely
    
    UNIQUE:
    - Multiple allowed per table
    - Allows ONE NULL value
    - Creates NON-CLUSTERED index
    - Ensures no duplicates

Q2: What is referential integrity and how is it enforced?
A2: Referential integrity ensures that relationships between tables remain 
    consistent. It's enforced through FOREIGN KEY constraints:
    - Child records must reference existing parent records
    - Parent records cannot be deleted if children exist (unless CASCADE)

Q3: What are the ON DELETE/ON UPDATE options for foreign keys?
A3: 
    - NO ACTION: Block the operation (default)
    - CASCADE: Propagate the change to children
    - SET NULL: Set FK column to NULL
    - SET DEFAULT: Set FK column to its default value

Q4: When would you use a composite primary key?
A4: 
    - Junction tables (many-to-many relationships)
    - When no single column uniquely identifies a row
    - When the business key is naturally multi-column
    Example: OrderDetails (OrderID, ProductID)

Q5: What is the difference between CHECK and FOREIGN KEY constraints?
A5: 
    CHECK: Validates against a boolean expression (Price > 0)
    FOREIGN KEY: Validates against values in another table

Q6: Can a FOREIGN KEY reference a UNIQUE constraint instead of PRIMARY KEY?
A6: Yes! A foreign key can reference any column(s) with a UNIQUE constraint,
    not just the primary key.

Q7: What happens if you try to insert a duplicate primary key?
A7: SQL Server rejects the insert with error:
    "Violation of PRIMARY KEY constraint. Cannot insert duplicate key."

Q8: How do you add a constraint to an existing table?
A8: ALTER TABLE TableName ADD CONSTRAINT ConstraintName ...
    Example: ALTER TABLE Products ADD CONSTRAINT CK_Price CHECK (Price > 0);

Q9: Can you temporarily disable a constraint?
A9: Yes, for FOREIGN KEY and CHECK constraints:
    ALTER TABLE TableName NOCHECK CONSTRAINT ConstraintName;
    Re-enable: ALTER TABLE TableName CHECK CONSTRAINT ConstraintName;
    Note: PRIMARY KEY and UNIQUE cannot be disabled.

Q10: What is a computed column and can it have constraints?
A10: A computed column's value is derived from an expression.
     - Can be PERSISTED (stored) or virtual (calculated each time)
     - Can have CHECK constraints if PERSISTED
     - Cannot have DEFAULT constraints

Q11: What is the IDENTITY property and is it a constraint?
A11: IDENTITY is NOT a constraint - it's a column property that auto-generates
     sequential values. It doesn't guarantee uniqueness (duplicates possible 
     with IDENTITY_INSERT ON). Use PRIMARY KEY for uniqueness.

Q12: How do you see all constraints on a table?
A12: 
     SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS 
     WHERE TABLE_NAME = 'YourTable';
     
     Or: sp_help 'TableName';

Q13: What is a self-referencing foreign key?
A13: A foreign key that references the same table. Common for hierarchies:
     CREATE TABLE Employees (
         EmployeeID INT PRIMARY KEY,
         ManagerID INT REFERENCES Employees(EmployeeID)
     );

Q14: Can CHECK constraints reference other tables?
A14: No! CHECK constraints can only reference columns in the same row.
     For cross-table validation, use triggers or stored procedures.

Q15: What is the naming convention for constraints?
A15: 
     - PK_TableName (Primary Key)
     - FK_ChildTable_ParentTable (Foreign Key)
     - UQ_TableName_ColumnName (Unique)
     - CK_TableName_ColumnName (Check)
     - DF_TableName_ColumnName (Default)

Q16: Why should you name your constraints?
A16: 
     - Easier to drop/modify later
     - Better error messages
     - Self-documenting schema
     - Required for some operations

Q17: What's the difference between column-level and table-level constraints?
A17: 
     Column-level: Defined inline with the column
         Price DECIMAL(10,2) NOT NULL CHECK (Price > 0)
     
     Table-level: Defined after all columns
         CONSTRAINT CK_Price CHECK (Price > 0)
     
     Use table-level for composite constraints or named constraints.

Q18: Can you have a NULL value in a UNIQUE column?
A18: In SQL Server, UNIQUE allows ONE NULL value (because NULL ≠ NULL).
     Some databases allow multiple NULLs.

Q19: What happens if you update a primary key that has foreign key references?
A19: By default (NO ACTION), the update is blocked. With ON UPDATE CASCADE,
     all referencing foreign keys are updated automatically.

Q20: How do constraints affect performance?
A20: 
     Positive:
     - PRIMARY KEY/UNIQUE create indexes (faster searches)
     - Better query optimization with known constraints
     
     Negative:
     - CHECK constraints validated on every INSERT/UPDATE
     - FOREIGN KEY requires lookup on parent table
     
     Trade-off: Data integrity vs. slight performance overhead.
     ALWAYS prioritize data integrity!

================================================================================
*/

-- ============================================================================
-- SECTION 12: PRACTICE EXERCISES
-- ============================================================================

/*
EXERCISE 1: Create a table with all constraint types
-----------------------------------------------------
Create a "Students" table with:
- StudentID (Primary Key, auto-increment)
- Email (Unique, Not Null)
- FirstName, LastName (Not Null)
- GPA (Check: between 0.0 and 4.0)
- EnrollmentDate (Default: today)
- Status (Check: 'Active', 'Graduated', 'Withdrawn')
- MajorID (Foreign Key to a Majors table)
*/
-- Your solution here:



/*
EXERCISE 2: Fix the constraint violations
-----------------------------------------
The following INSERT statements will fail. Identify why and fix them.
*/
-- INSERT INTO CustomerAccounts (Email, PasswordHash, FirstName, LastName, DateOfBirth)
-- VALUES ('invalid-email', 'hash123', 'John', 'Doe', '2030-01-01');

-- What violations? Answer:
-- 1. 
-- 2.



/*
EXERCISE 3: Design a constraint strategy
----------------------------------------
You're designing a banking system. List the constraints you would use for:
- Account balance
- Transaction amounts
- Transfer between accounts
- Account status
*/
-- Your design here:



/*
================================================================================
LAB COMPLETION CHECKLIST
================================================================================
□ Understand all 6 constraint types
□ Can create PRIMARY KEY (simple and composite)
□ Can create FOREIGN KEY with referential actions
□ Can create UNIQUE constraints
□ Can create CHECK constraints for validation
□ Can create DEFAULT constraints
□ Understand NOT NULL importance
□ Can view and manage existing constraints
□ Can answer interview questions confidently
□ Completed practice exercises

NEXT LAB: Lab 21 - Database Normalization
================================================================================
*/
