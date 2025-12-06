# Section 01: Database Design Fundamentals

**Estimated Time**: 5 hours  
**Difficulty**: ⭐⭐⭐ Intermediate  

---

## 🎯 Learning Objectives

✅ Create Entity-Relationship Diagrams (ERDs)  
✅ Understand entities, attributes, and relationships  
✅ Define primary keys and foreign keys  
✅ Implement cardinality (1:1, 1:M, M:N)  
✅ Translate business requirements to database schema  
✅ Apply constraints (CHECK, UNIQUE, DEFAULT)  

---

## 📊 Database Design Process

1. **Requirements Analysis**: Understand business needs
2. **Conceptual Design**: Create ERD
3. **Logical Design**: Define tables, columns, relationships
4. **Physical Design**: Implement in SQL Server
5. **Testing**: Verify with sample data

---

## 🔷 Entities and Attributes

**Entity**: A thing or object (Customer, Order, Product)  
**Attribute**: A property of an entity (CustomerName, OrderDate, Price)

**Example - Customer Entity**:
```
Customer
├── CustomerID (Primary Key)
├── FirstName
├── LastName
├── Email
├── Phone
└── DateRegistered
```

---

## 🔑 Primary Keys

**Primary Key**: Uniquely identifies each row in a table.

**Best Practices**:
- Use INT or BIGINT with IDENTITY for auto-increment
- Avoid natural keys that can change (email, SSN)
- Keep it simple (single column preferred)

```sql
CREATE TABLE Customer (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) UNIQUE NOT NULL,
    CreatedDate DATETIME2 DEFAULT GETDATE()
);
```

---

## 🔗 Relationships and Foreign Keys

**Foreign Key**: Links two tables together.

### One-to-Many (1:M)
One customer can have many orders.

```sql
CREATE TABLE [Order] (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    OrderDate DATETIME2 DEFAULT GETDATE(),
    TotalAmount DECIMAL(10,2),
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
);
```

### One-to-One (1:1)
One employee has one login credential.

```sql
CREATE TABLE Employee (
    EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50)
);

CREATE TABLE EmployeeLogin (
    EmployeeID INT PRIMARY KEY,
    Username NVARCHAR(50) UNIQUE,
    PasswordHash NVARCHAR(255),
    FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID)
);
```

### Many-to-Many (M:N)
Students enroll in many courses, courses have many students.

**Solution**: Junction/Bridge table

```sql
CREATE TABLE Student (
    StudentID INT IDENTITY(1,1) PRIMARY KEY,
    StudentName NVARCHAR(100)
);

CREATE TABLE Course (
    CourseID INT IDENTITY(1,1) PRIMARY KEY,
    CourseName NVARCHAR(100)
);

CREATE TABLE Enrollment (
    EnrollmentID INT IDENTITY(1,1) PRIMARY KEY,
    StudentID INT NOT NULL,
    CourseID INT NOT NULL,
    EnrollmentDate DATE,
    Grade CHAR(2),
    FOREIGN KEY (StudentID) REFERENCES Student(StudentID),
    FOREIGN KEY (CourseID) REFERENCES Course(CourseID),
    UNIQUE(StudentID, CourseID) -- Prevent duplicate enrollments
);
```

---

## ⚙️ Constraints

### CHECK Constraint
```sql
CREATE TABLE Product (
    ProductID INT PRIMARY KEY,
    ProductName NVARCHAR(100),
    Price DECIMAL(10,2) CHECK (Price > 0),
    StockQuantity INT CHECK (StockQuantity >= 0)
);
```

### UNIQUE Constraint
```sql
ALTER TABLE Customer
ADD CONSTRAINT UQ_Customer_Email UNIQUE (Email);
```

### DEFAULT Constraint
```sql
CREATE TABLE OrderHistory (
    OrderID INT PRIMARY KEY,
    OrderDate DATETIME2 DEFAULT GETDATE(),
    Status NVARCHAR(20) DEFAULT 'Pending'
);
```

---

## 📋 Real-World Example: E-Commerce System

**Requirements**:
- Track customers and their orders
- Products belong to categories
- Orders contain multiple products (order details)
- Track inventory

**ERD Design**:
```
Customer (1) ----< (M) Order (1) ----< (M) OrderDetail (M) >---- (1) Product
                                                                        |
                                                                        | (M)
                                                                        |
                                                                        V
                                                                    Category (1)
```

**Implementation**:
```sql
-- Category Table
CREATE TABLE Category (
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName NVARCHAR(100) NOT NULL UNIQUE,
    Description NVARCHAR(MAX)
);

-- Product Table
CREATE TABLE Product (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductName NVARCHAR(100) NOT NULL,
    CategoryID INT NOT NULL,
    Price DECIMAL(10,2) CHECK (Price >= 0),
    StockQuantity INT CHECK (StockQuantity >= 0),
    FOREIGN KEY (CategoryID) REFERENCES Category(CategoryID)
);

-- Customer Table (already defined above)

-- Order Table
CREATE TABLE CustomerOrder (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    OrderDate DATETIME2 DEFAULT GETDATE(),
    Status NVARCHAR(20) DEFAULT 'Pending',
    TotalAmount DECIMAL(10,2),
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
);

-- OrderDetail Table (Junction for Order-Product M:N)
CREATE TABLE OrderDetail (
    OrderDetailID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT CHECK (Quantity > 0),
    UnitPrice DECIMAL(10,2),
    LineTotal AS (Quantity * UnitPrice) PERSISTED,
    FOREIGN KEY (OrderID) REFERENCES CustomerOrder(OrderID),
    FOREIGN KEY (ProductID) REFERENCES Product(ProductID)
);
```

---

## 📝 Lab 20: Database Design

Complete `labs/lab_20_design.sql`.

**Tasks**:
1. Design a library management system (books, authors, members, loans)
2. Create ERD for hospital (patients, doctors, appointments, prescriptions)
3. Implement school database (students, teachers, classes, grades)

---

**Next**: [Section 02: Normalization →](./02_normalization.md)
