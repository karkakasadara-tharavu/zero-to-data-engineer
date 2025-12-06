# Section 02: Normalization

**Estimated Time**: 6 hours  
**Difficulty**: ⭐⭐⭐⭐ Advanced  

---

## 🎯 Learning Objectives

✅ Understand normal forms (1NF through BCNF)  
✅ Identify and eliminate data redundancy  
✅ Remove insertion, update, and deletion anomalies  
✅ Apply normalization to real-world scenarios  
✅ Know when to denormalize for performance  

---

## 🔢 First Normal Form (1NF)

**Rule**: Eliminate repeating groups, ensure atomic values.

### ❌ Violation (Repeating Groups)
```
OrderID | CustomerName | Products
1       | John Smith   | Laptop, Mouse, Keyboard
2       | Jane Doe     | Monitor, Cable
```

### ✅ 1NF Compliant
```
OrderID | CustomerName | Product
1       | John Smith   | Laptop
1       | John Smith   | Mouse
1       | John Smith   | Keyboard
2       | Jane Doe     | Monitor
2       | Jane Doe     | Cable
```

**SQL Implementation**:
```sql
-- Wrong approach (violates 1NF)
CREATE TABLE OrderWrong (
    OrderID INT,
    CustomerName NVARCHAR(100),
    Products NVARCHAR(MAX) -- CSV list
);

-- Correct approach (1NF)
CREATE TABLE OrderItem (
    OrderID INT,
    CustomerName NVARCHAR(100),
    Product NVARCHAR(100)
);
```

---

## 🔢 Second Normal Form (2NF)

**Rule**: Must be in 1NF + Remove partial dependencies.

**Partial Dependency**: Non-key attribute depends on part of composite key.

### ❌ Violation
```
Composite Key: (OrderID, ProductID)

OrderID | ProductID | ProductName | ProductPrice | CustomerName | OrderDate
1       | 101       | Laptop      | 1200         | John         | 2024-01-15
1       | 102       | Mouse       | 25           | John         | 2024-01-15
```

**Problem**: ProductName and ProductPrice depend only on ProductID (not full key).

### ✅ 2NF Compliant
Split into separate tables:

```sql
-- Order Table
CREATE TABLE [Order] (
    OrderID INT PRIMARY KEY,
    CustomerName NVARCHAR(100),
    OrderDate DATE
);

-- Product Table
CREATE TABLE Product (
    ProductID INT PRIMARY KEY,
    ProductName NVARCHAR(100),
    ProductPrice DECIMAL(10,2)
);

-- OrderDetail Table (many-to-many junction)
CREATE TABLE OrderDetail (
    OrderID INT,
    ProductID INT,
    Quantity INT,
    PRIMARY KEY (OrderID, ProductID),
    FOREIGN KEY (OrderID) REFERENCES [Order](OrderID),
    FOREIGN KEY (ProductID) REFERENCES Product(ProductID)
);
```

---

## 🔢 Third Normal Form (3NF)

**Rule**: Must be in 2NF + Remove transitive dependencies.

**Transitive Dependency**: Non-key attribute depends on another non-key attribute.

### ❌ Violation
```
EmployeeID | EmployeeName | DepartmentID | DepartmentName | DepartmentLocation
1          | John Smith   | 10           | Sales          | Building A
2          | Jane Doe     | 10           | Sales          | Building A
```

**Problem**: DepartmentName and DepartmentLocation depend on DepartmentID (not on EmployeeID).

### ✅ 3NF Compliant
```sql
-- Employee Table
CREATE TABLE Employee (
    EmployeeID INT PRIMARY KEY,
    EmployeeName NVARCHAR(100),
    DepartmentID INT,
    FOREIGN KEY (DepartmentID) REFERENCES Department(DepartmentID)
);

-- Department Table
CREATE TABLE Department (
    DepartmentID INT PRIMARY KEY,
    DepartmentName NVARCHAR(100),
    DepartmentLocation NVARCHAR(100)
);
```

---

## 🔢 Boyce-Codd Normal Form (BCNF)

**Rule**: Stricter version of 3NF - every determinant must be a candidate key.

### Example Scenario
```
Student | Course   | Instructor
Alice   | Math     | Prof. Smith
Alice   | Physics  | Prof. Jones
Bob     | Math     | Prof. Smith
```

**Assumptions**:
- One instructor per course
- Instructor determines the course

**Problem**: {Student, Course} is the key, but Instructor → Course (Instructor is determinant but not a candidate key).

### ✅ BCNF Compliant
```sql
-- CourseInstructor Table
CREATE TABLE CourseInstructor (
    InstructorID INT PRIMARY KEY,
    InstructorName NVARCHAR(100),
    CourseID INT
);

-- Enrollment Table
CREATE TABLE Enrollment (
    StudentID INT,
    InstructorID INT,
    PRIMARY KEY (StudentID, InstructorID),
    FOREIGN KEY (InstructorID) REFERENCES CourseInstructor(InstructorID)
);
```

---

## 🎯 Practical Example: Invoice Normalization

### Original (Unnormalized)
```
InvoiceNo | Date       | CustomerName | CustomerAddress | Product  | Qty | Price | Total
1001      | 2024-01-15 | John Smith   | 123 Main St     | Laptop   | 1   | 1200  | 1200
1001      | 2024-01-15 | John Smith   | 123 Main St     | Mouse    | 2   | 25    | 50
1002      | 2024-01-16 | Jane Doe     | 456 Oak Ave     | Monitor  | 1   | 300   | 300
```

**Problems**: Customer data repeated, update anomalies.

### Normalized (3NF)
```sql
-- Customer Table
CREATE TABLE Customer (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerName NVARCHAR(100),
    CustomerAddress NVARCHAR(200)
);

-- Invoice Table
CREATE TABLE Invoice (
    InvoiceNo INT PRIMARY KEY,
    InvoiceDate DATE,
    CustomerID INT,
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
);

-- Product Table
CREATE TABLE Product (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductName NVARCHAR(100),
    UnitPrice DECIMAL(10,2)
);

-- InvoiceDetail Table
CREATE TABLE InvoiceDetail (
    InvoiceDetailID INT IDENTITY(1,1) PRIMARY KEY,
    InvoiceNo INT,
    ProductID INT,
    Quantity INT,
    LineTotal AS (Quantity * (SELECT UnitPrice FROM Product WHERE ProductID = InvoiceDetail.ProductID)),
    FOREIGN KEY (InvoiceNo) REFERENCES Invoice(InvoiceNo),
    FOREIGN KEY (ProductID) REFERENCES Product(ProductID)
);
```

---

## 🔄 Denormalization (Strategic)

**When to Denormalize**:
- Read-heavy workloads (reporting)
- Performance optimization
- Data warehousing (fact tables)

**Example**: Store calculated totals to avoid JOINs
```sql
ALTER TABLE Invoice
ADD TotalAmount DECIMAL(10,2);

-- Update with trigger or ETL process
```

**Trade-off**: Better read performance vs. data redundancy and update complexity.

---

## 📝 Lab 21: Normalization

Complete `labs/lab_21_normalization.sql`.

**Tasks**:
1. Normalize a student registration spreadsheet (1NF → 3NF)
2. Identify violations in sample schemas
3. Convert unnormalized invoice data to 3NF
4. Design normalized schema for hospital database

---

**Next**: [Section 03: Backup and Recovery →](./03_backup_recovery.md)
