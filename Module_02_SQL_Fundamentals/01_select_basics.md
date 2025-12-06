# Section 01: SELECT Basics - Your First SQL Queries

**Estimated Time**: 3 hours  
**Difficulty**: ⭐ Beginner  
**Prerequisites**: Module 01 complete, AdventureWorksLT2022 restored

---

## 🎯 Learning Objectives

By the end of this section, you will:

✅ Understand the anatomy of a SELECT statement  
✅ Retrieve all columns or specific columns from a table  
✅ Use column aliases for readable output  
✅ Perform basic calculations in SELECT  
✅ Understand SQL execution order  
✅ Use comments to document your queries  

---

## 📚 What is SELECT?

**SELECT** is the most important SQL command you'll ever learn. It **retrieves data** from database tables.

**Analogy**: Think of SELECT as asking questions to your database:
- "Show me all products" → `SELECT * FROM Product`
- "What are the product names and prices?" → `SELECT Name, ListPrice FROM Product`
- "How many customers do we have?" → `SELECT COUNT(*) FROM Customer`

**Real-world usage**: Data engineers use SELECT statements:
- 📊 **Analytics**: Extract insights from data warehouses
- 🔍 **Data exploration**: Understand new datasets
- ✅ **Quality checks**: Verify data after ETL processes
- 📈 **Reporting**: Power dashboards and reports

---

## 🏗️ Anatomy of a SELECT Statement

### Basic Syntax

```sql
SELECT column1, column2, column3
FROM schema_name.table_name;
```

**Components**:
- **SELECT**: Keyword that starts the query (required)
- **column1, column2**: Columns you want to retrieve (comma-separated)
- **FROM**: Keyword that specifies the table (required)
- **schema_name.table_name**: Fully qualified table name
- **;** (semicolon): Statement terminator (optional in SSMS, good practice)

---

### Example: Basic SELECT

```sql
-- Retrieve all customers (first 5 rows shown)
SELECT 
    CustomerID,
    FirstName,
    LastName,
    EmailAddress
FROM SalesLT.Customer;
```

**Result** (sample):
| CustomerID | FirstName | LastName | EmailAddress |
|------------|-----------|----------|--------------|
| 1 | Orlando | Gee | orlando.gee@adventure-works.com |
| 2 | Keith | Harris | keith.harris@adventure-works.com |
| 3 | Donna | Carreras | donna.carreras@adventure-works.com |
| 4 | Janet | Gates | janet.gates@adventure-works.com |
| 5 | Lucy | Harrington | lucy.harrington@adventure-works.com |

**Explanation**:
- **SalesLT**: Schema name (namespace for tables)
- **Customer**: Table name
- **4 columns** selected out of 10+ available columns
- **847 rows** returned (entire table)

<!-- 🎨 PLACEHOLDER: Screenshot of SSMS query window showing above query with results grid -->

---

## 🌟 SELECT * (Select All Columns)

### The Wildcard Operator

**Syntax**:
```sql
SELECT *
FROM SalesLT.Customer;
```

**What * means**: "Give me ALL columns from this table"

**Result**: All 10 columns returned:
- CustomerID, NameStyle, Title, FirstName, MiddleName, LastName, Suffix, CompanyName, SalesPerson, EmailAddress, Phone, PasswordHash, PasswordSalt, rowguid, ModifiedDate

---

### When to Use SELECT *

**✅ Good for**:
- Quick exploration of new tables
- Checking if table has data
- Small tables (few columns)
- Learning/prototyping

**❌ Avoid in production for**:
- Large tables (wastes bandwidth)
- ETL processes (specific columns needed)
- Performance-critical queries
- Reporting (only need subset of columns)

---

### Example: Exploring a Table

```sql
-- Quick look at Product table structure
SELECT *
FROM SalesLT.Product;
```

**Use case**: "I just joined the team. What's in the Product table?"

**Result**: 295 rows, 16 columns (ProductID, Name, ProductNumber, Color, StandardCost, ListPrice, Size, Weight, etc.)

---

## 📋 Selecting Specific Columns

### Why Specify Columns?

**Benefits**:
- 🚀 **Faster queries** - Less data transferred
- 📖 **Readable results** - Only what you need
- 💾 **Less memory** - Important for large datasets
- 🎯 **Clear intent** - Shows exactly what you're analyzing

---

### Example: Customer Names Only

```sql
-- Get just customer names
SELECT 
    FirstName,
    LastName
FROM SalesLT.Customer;
```

**Result**:
| FirstName | LastName |
|-----------|----------|
| Orlando | Gee |
| Keith | Harris |
| Donna | Carreras |
| ... | ... |

**Best practice**: List columns vertically (one per line) for readability when selecting multiple columns.

---

### Example: Product Pricing Information

```sql
-- Products with pricing data
SELECT 
    ProductID,
    Name,
    StandardCost,
    ListPrice
FROM SalesLT.Product;
```

**Result**:
| ProductID | Name | StandardCost | ListPrice |
|-----------|------|--------------|-----------|
| 680 | HL Road Frame - Black, 58 | 1059.31 | 1431.50 |
| 706 | HL Road Frame - Red, 58 | 1059.31 | 1431.50 |
| 707 | Sport-100 Helmet, Red | 13.09 | 34.99 |

**Use case**: Analyzing profit margins (ListPrice - StandardCost)

---

## 🏷️ Column Aliases (AS Keyword)

### What are Aliases?

**Aliases** give columns custom names in the result set. Think of them as "nicknames" for columns.

**Syntax**:
```sql
SELECT column_name AS AliasName
FROM table_name;
```

---

### Example: Readable Column Names

**Without aliases** (default column names):
```sql
SELECT 
    FirstName,
    LastName,
    EmailAddress
FROM SalesLT.Customer;
```

**Result columns**: FirstName, LastName, EmailAddress

---

**With aliases** (custom names):
```sql
SELECT 
    FirstName AS 'First Name',
    LastName AS 'Last Name',
    EmailAddress AS 'Email'
FROM SalesLT.Customer;
```

**Result columns**: First Name, Last Name, Email

<!-- 🎨 PLACEHOLDER: Screenshot showing result with alias column headers -->

**Note**: Use single quotes `'Alias Name'` or square brackets `[Alias Name]` for aliases with spaces.

---

### Example: Business-Friendly Names

```sql
-- Product catalog with readable names
SELECT 
    ProductID AS 'Product Code',
    Name AS 'Product Name',
    Color AS 'Available Color',
    ListPrice AS 'Retail Price',
    StandardCost AS 'Cost'
FROM SalesLT.Product;
```

**Use case**: Exporting to Excel for non-technical stakeholders.

---

### AS Keyword is Optional

**These are equivalent**:
```sql
-- With AS (recommended - more readable)
SELECT FirstName AS First, LastName AS Last
FROM SalesLT.Customer;

-- Without AS (works but less clear)
SELECT FirstName First, LastName Last
FROM SalesLT.Customer;
```

**Best practice**: Always use `AS` for clarity.

---

## 🧮 Calculations in SELECT

### Arithmetic Operators

You can perform math directly in SELECT statements!

**Operators**:
- `+` Addition
- `-` Subtraction
- `*` Multiplication
- `/` Division
- `%` Modulo (remainder)

---

### Example: Profit Margin Calculation

```sql
-- Calculate profit per product
SELECT 
    ProductID,
    Name,
    StandardCost,
    ListPrice,
    ListPrice - StandardCost AS ProfitMargin,
    (ListPrice - StandardCost) / ListPrice * 100 AS ProfitPercentage
FROM SalesLT.Product;
```

**Result**:
| ProductID | Name | StandardCost | ListPrice | ProfitMargin | ProfitPercentage |
|-----------|------|--------------|-----------|--------------|------------------|
| 680 | HL Road Frame - Black, 58 | 1059.31 | 1431.50 | 372.19 | 25.99 |
| 707 | Sport-100 Helmet, Red | 13.09 | 34.99 | 21.90 | 62.59 |

**Explanation**:
- `ProfitMargin = ListPrice - StandardCost` (absolute profit)
- `ProfitPercentage = (Profit / ListPrice) * 100` (percentage)

---

### Example: Sales Tax Calculation

```sql
-- Add 8.5% sales tax to product prices
SELECT 
    ProductID,
    Name,
    ListPrice AS OriginalPrice,
    ListPrice * 0.085 AS SalesTax,
    ListPrice * 1.085 AS PriceWithTax
FROM SalesLT.Product;
```

**Result**:
| ProductID | Name | OriginalPrice | SalesTax | PriceWithTax |
|-----------|------|---------------|----------|--------------|
| 680 | HL Road Frame | 1431.50 | 121.68 | 1553.18 |

---

### Order of Operations (Math)

**PEMDAS/BODMAS applies** in SQL:
1. **Parentheses** `()`
2. **Multiplication** `*` and **Division** `/`
3. **Addition** `+` and **Subtraction** `-`

**Example**:
```sql
SELECT 
    10 + 5 * 2 AS Result1,        -- Result: 20 (multiply first)
    (10 + 5) * 2 AS Result2;      -- Result: 30 (parentheses first)
```

---

## 🔗 String Concatenation

### Combining Text Columns

**Operator**: `+` (for strings)

**Example: Full Name**:
```sql
SELECT 
    FirstName,
    LastName,
    FirstName + ' ' + LastName AS FullName
FROM SalesLT.Customer;
```

**Result**:
| FirstName | LastName | FullName |
|-----------|----------|----------|
| Orlando | Gee | Orlando Gee |
| Keith | Harris | Keith Harris |

---

### CONCAT Function (Safer)

**Problem with +**: If any value is NULL, entire result is NULL.

**Solution**: Use `CONCAT()` function (handles NULLs gracefully).

```sql
SELECT 
    FirstName,
    MiddleName,
    LastName,
    -- Using + operator (fails if MiddleName is NULL)
    FirstName + ' ' + MiddleName + ' ' + LastName AS FullName_BadWay,
    
    -- Using CONCAT (handles NULLs)
    CONCAT(FirstName, ' ', MiddleName, ' ', LastName) AS FullName_GoodWay
FROM SalesLT.Customer;
```

**Result** (if MiddleName is NULL):
| FirstName | MiddleName | LastName | FullName_BadWay | FullName_GoodWay |
|-----------|------------|----------|-----------------|------------------|
| Orlando | NULL | Gee | NULL | Orlando  Gee |
| Keith | M | Harris | Keith M Harris | Keith M Harris |

**Best practice**: Use `CONCAT()` for string concatenation.

---

## 💬 Comments in SQL

### Why Comment Your Code?

**Comments** are text ignored by SQL Server - used to explain your queries.

**Benefits**:
- 📝 **Documentation**: Explain complex logic
- 🧑‍🤝‍🧑 **Collaboration**: Help teammates understand your code
- 🔍 **Debugging**: Temporarily disable parts of queries
- 📚 **Learning**: Add notes for future reference

---

### Single-Line Comments

**Syntax**: `-- comment text`

```sql
-- This is a comment
SELECT ProductID, Name  -- Comments can go at end of line too
FROM SalesLT.Product;   -- Retrieves product info
```

---

### Multi-Line Comments

**Syntax**: `/* comment text */`

```sql
/*
  Author: Your Name
  Date: 2025-12-07
  Purpose: Retrieve high-value products for marketing campaign
  
  Business Context:
  Marketing team needs products with ListPrice > $1000
  for luxury product catalog.
*/
SELECT 
    ProductID,
    Name,
    ListPrice
FROM SalesLT.Product
WHERE ListPrice > 1000;  -- High-value threshold
```

---

### Commenting Out Code (Debugging)

```sql
SELECT 
    ProductID,
    Name,
    -- StandardCost,    -- Temporarily hide cost column
    ListPrice
FROM SalesLT.Product;
```

**Use case**: Testing queries without deleting code.

---

## ⚙️ SQL Execution Order

### What You Write vs. What SQL Executes

**Important**: SQL doesn't execute in the order you write it!

**Logical Execution Order**:
1. **FROM** - Identify the table(s)
2. **WHERE** - Filter rows (we'll learn in Section 02)
3. **GROUP BY** - Group rows (Section 05)
4. **HAVING** - Filter groups (Section 05)
5. **SELECT** - Choose columns & perform calculations
6. **ORDER BY** - Sort results (Section 03)

**For now, remember**: SQL reads `FROM` first, then `SELECT`.

---

### Why This Matters

**Example that will make sense later**:
```sql
-- This works (alias used in ORDER BY - comes after SELECT)
SELECT 
    ProductID,
    ListPrice * 1.1 AS PriceWithMarkup
FROM SalesLT.Product
ORDER BY PriceWithMarkup;  -- ✅ OK: ORDER BY sees alias

-- This fails (alias used in WHERE - comes before SELECT)
SELECT 
    ProductID,
    ListPrice * 1.1 AS PriceWithMarkup
FROM SalesLT.Product
WHERE PriceWithMarkup > 100;  -- ❌ ERROR: WHERE doesn't know alias yet
```

**We'll explore this more in Section 02!**

---

## 🎯 Practical Examples

### Example 1: Customer Contact List

**Scenario**: Create an email distribution list for marketing.

```sql
-- Generate customer contact info
SELECT 
    FirstName + ' ' + LastName AS CustomerName,
    EmailAddress AS Email,
    Phone AS PhoneNumber,
    CompanyName AS Company
FROM SalesLT.Customer
WHERE EmailAddress IS NOT NULL;  -- Only customers with emails
```

**Use case**: Export to Excel, import to email marketing tool.

---

### Example 2: Product Catalog

**Scenario**: Generate product catalog for website.

```sql
-- Product listings with pricing
SELECT 
    ProductNumber AS SKU,
    Name AS ProductName,
    Color,
    ListPrice AS Price,
    'In Stock' AS Availability  -- Literal value for all rows
FROM SalesLT.Product;
```

**Note**: `'In Stock'` is a **string literal** - same value for every row.

---

### Example 3: Inventory Value

**Scenario**: Calculate total inventory value per product.

```sql
-- Inventory valuation (假设 we had quantity column)
-- For now, showing calculation concept
SELECT 
    ProductID,
    Name,
    StandardCost,
    10 AS QuantityOnHand,  -- Hardcoded for example (real data would come from inventory table)
    StandardCost * 10 AS TotalInventoryValue
FROM SalesLT.Product;
```

**Real-world**: You'd JOIN to an Inventory table (we'll learn JOINs in Section 06!).

---

## 🧪 Practice Queries (Try These!)

### Practice 1: Simple SELECT

**Task**: Retrieve product names and colors.

**Expected Columns**: Name, Color

**Hint**: Use `SalesLT.Product` table.

<details>
<summary>Click for Solution</summary>

```sql
SELECT 
    Name,
    Color
FROM SalesLT.Product;
```
</details>

---

### Practice 2: Column Aliases

**Task**: Retrieve customer names with friendly column headers:
- "First Name"
- "Last Name"
- "Email Address"

<details>
<summary>Click for Solution</summary>

```sql
SELECT 
    FirstName AS 'First Name',
    LastName AS 'Last Name',
    EmailAddress AS 'Email Address'
FROM SalesLT.Customer;
```
</details>

---

### Practice 3: Calculations

**Task**: Show products with:
- Product name
- List price
- Price with 10% discount
- Amount saved

<details>
<summary>Click for Solution</summary>

```sql
SELECT 
    Name AS ProductName,
    ListPrice AS OriginalPrice,
    ListPrice * 0.90 AS DiscountedPrice,
    ListPrice * 0.10 AS AmountSaved
FROM SalesLT.Product;
```
</details>

---

### Practice 4: String Concatenation

**Task**: Create a product description in format: "ProductNumber - Name (Color)"

Example: "FR-R92B-58 - HL Road Frame (Black)"

<details>
<summary>Click for Solution</summary>

```sql
SELECT 
    CONCAT(ProductNumber, ' - ', Name, ' (', Color, ')') AS ProductDescription
FROM SalesLT.Product;
```
</details>

---

## 📝 Lab 01: SELECT Basics

**File**: `labs/lab_01_select_basics.sql`

Now it's time for your first graded lab! Complete all tasks below.

**Instructions**:
1. Open SSMS and connect to SQL Server
2. Create new query window (Ctrl + N)
3. Switch to AdventureWorksLT2022 database
4. Complete each task
5. Compare your results with solution file (after attempting!)

---

### Lab Tasks

**Task 1**: Retrieve all columns from `SalesLT.Customer` table.

**Expected**: 847 rows, all columns

**Your code**:
```sql
-- Task 1: Your code here


```

---

**Task 2**: Retrieve only the following columns from `SalesLT.Product`:
- ProductID
- Name
- ListPrice

**Expected**: 295 rows, 3 columns

**Your code**:
```sql
-- Task 2: Your code here


```

---

**Task 3**: Retrieve customer names with aliases:
- "Customer ID" for CustomerID
- "Full Name" for FirstName + LastName combined
- "Email" for EmailAddress

**Expected**: 847 rows, 3 columns with custom headers

**Your code**:
```sql
-- Task 3: Your code here


```

---

**Task 4**: Calculate profit margin for products:
- Show: ProductID, Name, StandardCost, ListPrice
- Calculate: Profit (ListPrice - StandardCost)
- Calculate: Profit Percentage ((Profit / ListPrice) * 100)

**Expected**: 295 rows, 6 columns

**Your code**:
```sql
-- Task 4: Your code here


```

---

**Task 5**: Create a product label in format: "Name - Color - $Price"

Example: "HL Road Frame - Black - $1431.50"

Show ProductID and ProductLabel columns.

**Hint**: Use CONCAT() and consider products with NULL colors.

**Your code**:
```sql
-- Task 5: Your code here


```

---

**Task 6**: Retrieve order information from `SalesLT.SalesOrderHeader`:
- OrderDate with alias "Order Date"
- TotalDue with alias "Total Amount"
- Calculate TotalDue * 0.065 as "Estimated Sales Tax"

**Expected**: 32 rows, 3 columns

**Your code**:
```sql
-- Task 6: Your code here


```

---

**Task 7**: Create a customer greeting message in format:

"Dear [FirstName] [LastName], your email is [EmailAddress]"

Show CustomerID and GreetingMessage columns.

**Your code**:
```sql
-- Task 7: Your code here


```

---

### Self-Check

After completing all tasks:
- [ ] All queries execute without errors
- [ ] Column names match expected (aliases applied)
- [ ] Row counts match expected
- [ ] Calculations produce reasonable values
- [ ] NULL values handled gracefully (CONCAT vs. +)

**Solution file**: `solutions/lab_01_select_basics_solution.sql`

---

## ✅ Section Summary

### What You Learned

✅ SELECT statement anatomy (SELECT, FROM, semicolon)  
✅ SELECT * (all columns) vs. specific columns  
✅ Column aliases with AS keyword  
✅ Arithmetic calculations in SELECT  
✅ String concatenation with + and CONCAT()  
✅ Comments (-- and /* */)  
✅ SQL logical execution order  

### Key Takeaways

🎯 **SELECT is the foundation** - You'll use it in 99% of SQL queries  
🎯 **Be specific** - Select only needed columns (avoid SELECT *)  
🎯 **Use aliases** - Make results readable for business users  
🎯 **Comment your code** - Future you will thank present you!  
🎯 **CONCAT over +** - Handles NULLs gracefully  

---

## 🚀 Next Steps

**You're ready for**: [Section 02: Filtering Data (WHERE Clause) →](./02_filtering_data.md)

**What's next**:
- WHERE clause syntax
- Comparison operators (=, <, >, !=)
- Logical operators (AND, OR, NOT)
- IN, BETWEEN, LIKE operators
- NULL handling

**Estimated time**: 4 hours, 4 labs

---

**Great job on completing Section 01!** 🎉  
You just wrote your first SQL queries! Every data engineer started right where you are now.

---

*கற்க கசடற - Learn Flawlessly, Grow Together*  
*Karka Kasadara Data Engineering Curriculum*

*Last Updated: December 7, 2025*
