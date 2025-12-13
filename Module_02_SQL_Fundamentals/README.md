![Module 02 Header](../assets/images/module_02_header.svg)

# Module 02: SQL Fundamentals

**Duration**: 2 weeks (40-60 hours)  
**Difficulty**: ⭐⭐ Beginner to Intermediate  
**Prerequisites**: Module 01 complete (SQL Server + AdventureWorks installed)

---

## 🎯 Module Overview

Welcome to SQL Fundamentals - where you learn the **#1 skill every data engineer needs**: querying data! By the end of this module, you'll write SQL queries confidently and understand how databases think.

### What You'll Master

✅ **SELECT statements** - Retrieve exactly the data you need  
✅ **Filtering** (WHERE, AND, OR, NOT) - Find specific records  
✅ **Sorting** (ORDER BY) - Control result order  
✅ **JOINs** - Combine data from multiple tables  
✅ **Aggregations** (SUM, COUNT, AVG, MIN, MAX) - Calculate summaries  
✅ **GROUP BY** - Aggregate data by categories  
✅ **Subqueries** - Queries within queries  
✅ **CASE expressions** - Add conditional logic  
✅ **String functions** - Manipulate text data  
✅ **Date functions** - Work with dates and times

### Why This Matters

**80% of data engineering work** involves SQL queries:
- 📊 **Analytics**: Extract insights from data
- 🔄 **ETL**: Transform data between systems
- 🎯 **Data quality**: Validate and clean data
- 📈 **Reporting**: Power business intelligence tools

**Real-world scenario**: You'll query AdventureWorks just like a data analyst at a bicycle company analyzes sales, products, and customers!

---

## 📚 Module Structure

### Section Breakdown

| Section | Topic | Labs | Est. Time |
|---------|-------|------|-----------|
| **01** | SELECT Basics & Column Selection | 3 | 3 hours |
| **02** | Filtering Data (WHERE Clause) | 4 | 4 hours |
| **03** | Sorting & Limiting Results | 3 | 3 hours |
| **04** | Aggregate Functions | 4 | 4 hours |
| **05** | GROUP BY & HAVING | 4 | 5 hours |
| **06** | JOINs (INNER, LEFT, RIGHT, FULL) | 5 | 6 hours |
| **07** | Subqueries & Derived Tables | 4 | 5 hours |
| **08** | String & Date Functions | 3 | 4 hours |
| **09** | CASE Expressions & Logic | 3 | 4 hours |
| **10** | Practice Project: Sales Analysis | 1 | 8 hours |

**Total**: 10 sections, **28 labs**, **46-60 hours**

---

## 🗂️ Folder Structure

```
Module_02_SQL_Fundamentals/
├── README.md                        (This file)
├── 01_select_basics.md              (SELECT, columns, aliases)
├── 02_filtering_data.md             (WHERE, AND, OR, IN, BETWEEN, LIKE)
├── 03_sorting_limiting.md           (ORDER BY, TOP, DISTINCT)
├── 04_aggregate_functions.md        (COUNT, SUM, AVG, MIN, MAX)
├── 05_groupby_having.md             (GROUP BY, HAVING, ROLLUP)
├── 06_joins.md                      (INNER, LEFT, RIGHT, FULL, CROSS)
├── 07_subqueries.md                 (Scalar, multi-row, correlated)
├── 08_string_date_functions.md      (LEN, CONCAT, DATEPART, DATEDIFF)
├── 09_case_expressions.md           (CASE WHEN, IIF, COALESCE)
├── 10_practice_project.md           (Comprehensive sales analysis)
│
├── labs/
│   ├── lab_01_select_basics.sql
│   ├── lab_02_filtering.sql
│   ├── lab_03_sorting.sql
│   ├── ... (28 lab files)
│   └── lab_10_sales_project.sql
│
├── solutions/
│   ├── lab_01_select_basics_solution.sql
│   ├── lab_02_filtering_solution.sql
│   └── ... (28 solution files)
│
└── quizzes/
    ├── quiz_week1.md                (Sections 1-5)
    └── quiz_week2.md                (Sections 6-10)
```

---

## 🚀 Getting Started

### Prerequisites Checklist

Before starting Module 02, verify:

- [ ] SQL Server 2022 Express installed and running
- [ ] SSMS installed and configured
- [ ] AdventureWorksLT2022 database restored
- [ ] AdventureWorks2022 database restored
- [ ] You can execute `SELECT @@VERSION` successfully
- [ ] Module 01 verification tests passed

**Not ready?** → Go back to [Module 01: SQL Server Setup](../Module_01_SQL_Server_Setup/README.md)

---

### Database Context

**Primary Database**: AdventureWorksLT2022 (lightweight, perfect for learning)  
**Secondary Database**: AdventureWorks2022 (for advanced examples)

**Quick connection test**:
```sql
USE AdventureWorksLT2022;
GO

SELECT 
    'Database connected!' AS Status,
    COUNT(*) AS TableCount
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE';
GO
```

**Expected Result**: Status = "Database connected!", TableCount = 10

---

## 📖 Learning Path

### Week 1: Foundations (Sections 1-5)

**Focus**: Single-table queries and basic analysis

**Daily Schedule** (5 hours/day):
- **Day 1**: Section 01 (SELECT Basics) - 3 labs
- **Day 2**: Section 02 (Filtering) - 4 labs
- **Day 3**: Section 03 (Sorting) - 3 labs
- **Day 4**: Section 04 (Aggregations) - 4 labs
- **Day 5**: Section 05 (GROUP BY) + Quiz 1 - 4 labs + review

**Learning Outcome**: You can analyze data from a single table with filters, sorting, and aggregations.

---

### Week 2: Multi-Table & Advanced (Sections 6-10)

**Focus**: JOINs, subqueries, and complex analysis

**Daily Schedule** (5 hours/day):
- **Day 6**: Section 06 (JOINs) - 5 labs
- **Day 7**: Section 07 (Subqueries) - 4 labs
- **Day 8**: Section 08 (Functions) - 3 labs
- **Day 9**: Section 09 (CASE logic) - 3 labs
- **Day 10**: Section 10 (Practice Project) + Quiz 2 - 1 comprehensive project + review

**Learning Outcome**: You can write complex queries joining multiple tables with conditional logic and functions.

---

## 🎓 Assessment

### Grading Breakdown

| Component | Weight | Description |
|-----------|--------|-------------|
| **Lab Completion** | 40% | Complete all 28 labs (pass = 80%+ correct) |
| **Quiz 1 (Week 1)** | 20% | 20 questions on Sections 1-5 |
| **Quiz 2 (Week 2)** | 20% | 20 questions on Sections 6-10 |
| **Practice Project** | 20% | Comprehensive sales analysis (Section 10) |

**Passing Score**: 75% overall

**Mastery Level**: 90%+ (ready for Module 03: Advanced SQL)

---

### Lab Expectations

**Each lab includes**:
1. **Objective**: What you'll learn
2. **Scenario**: Real-world context
3. **Tasks**: 5-10 queries to write
4. **Hints**: If you get stuck
5. **Expected output**: Sample results
6. **Self-check**: Verify your answer

**Example Lab Format**:
```sql
-- Lab 02.3: Filter Customers by Region
-- Objective: Use WHERE clause with multiple conditions
-- Difficulty: ⭐⭐

-- Task 1: Find all customers in California
-- Expected: 50+ rows with CompanyName, City, StateProvince

-- YOUR CODE HERE:


-- Task 2: Find customers in California OR Washington
-- Expected: 100+ rows

-- YOUR CODE HERE:
```

---

## 💡 Study Tips

### For Beginners

1. **Type every query** - Don't copy-paste! Muscle memory matters.
2. **Run queries often** - See results after each step.
3. **Break complex queries** - Build piece by piece.
4. **Use comments** - Explain your logic with `--` comments.
5. **Check solutions only after trying** - Learn from mistakes!

### For Experienced Learners

1. **Challenge yourself** - Try variations of each lab.
2. **Optimize queries** - Use execution plans (Ctrl+L in SSMS).
3. **Explore AdventureWorks** - Query tables not covered in labs.
4. **Time yourself** - Track improvement speed.
5. **Help others** - Teaching reinforces learning!

---

## 🔧 Tools & Resources

### SSMS Keyboard Shortcuts (Essential)

| Shortcut | Action | Use Case |
|----------|--------|----------|
| **F5** | Execute query | Run your SQL |
| **Ctrl + R** | Show/hide results | Toggle results pane |
| **Ctrl + L** | Display execution plan | Check query performance |
| **Ctrl + Shift + U** | Uppercase selected text | Format SQL keywords |
| **Ctrl + K, C** | Comment selected lines | Add `--` to multiple lines |
| **Ctrl + K, U** | Uncomment lines | Remove `--` from lines |
| **Ctrl + Shift + R** | Refresh IntelliSense | Update table/column suggestions |

---

### SQL Style Guide (Recommended)

**Follow these conventions for readable code**:

```sql
-- ✅ GOOD: Keywords uppercase, readable formatting
SELECT 
    ProductID,
    Name,
    ListPrice
FROM Production.Product
WHERE ListPrice > 100
ORDER BY ListPrice DESC;

-- ❌ BAD: All lowercase, single line
select productid,name,listprice from production.product where listprice>100 order by listprice desc;
```

**Key Rules**:
- **Keywords**: UPPERCASE (SELECT, FROM, WHERE, JOIN)
- **Identifiers**: PascalCase (table/column names as defined)
- **Indentation**: 4 spaces per level
- **One clause per line**: SELECT, FROM, WHERE on separate lines
- **Align columns**: Vertically align selected columns
- **Comments**: Use `--` for single-line, `/* */` for multi-line

---

## 📊 AdventureWorksLT2022 Schema Reference

### Key Tables You'll Use

**Sales Schema** (`SalesLT.*`):

1. **Customer** (847 rows)
   - CustomerID, FirstName, LastName, EmailAddress, Phone
   - **Use for**: Customer analysis, filtering by name/email

2. **Product** (295 rows)
   - ProductID, Name, ProductNumber, Color, ListPrice, StandardCost
   - **Use for**: Product pricing, inventory analysis

3. **ProductCategory** (41 rows)
   - ProductCategoryID, Name (e.g., "Bikes", "Accessories")
   - **Use for**: Category-level aggregations

4. **SalesOrderHeader** (32 rows)
   - SalesOrderID, CustomerID, OrderDate, TotalDue, ShipDate
   - **Use for**: Sales trends, order analysis

5. **SalesOrderDetail** (542 rows)
   - SalesOrderDetailID, SalesOrderID, ProductID, OrderQty, UnitPrice
   - **Use for**: Line-item analysis, revenue calculations

6. **Address** (450 rows)
   - AddressID, AddressLine1, City, StateProvince, CountryRegion, PostalCode
   - **Use for**: Geographic analysis

---

### Common Relationships (JOINs)

```
Customer (1) ────── (Many) SalesOrderHeader
                              │
                              │ (1)
                              │
                              ▼
                         (Many) SalesOrderDetail ────── (1) Product
                                                                │
                                                                │ (Many)
                                                                │
                                                                ▼
                                                           (1) ProductCategory
```

**Translation**:
- One customer has many orders (Customer → SalesOrderHeader)
- One order has many line items (SalesOrderHeader → SalesOrderDetail)
- One product appears in many line items (Product → SalesOrderDetail)
- Many products belong to one category (Product → ProductCategory)

---

## 🎯 Module Completion Criteria

You've mastered Module 02 when you can:

- [ ] Write SELECT statements to retrieve specific columns
- [ ] Filter data with WHERE clause (AND, OR, IN, BETWEEN, LIKE)
- [ ] Sort results with ORDER BY (ASC, DESC, multiple columns)
- [ ] Calculate aggregates (COUNT, SUM, AVG, MIN, MAX)
- [ ] Group data with GROUP BY and filter groups with HAVING
- [ ] Join 2-3 tables using INNER JOIN and LEFT JOIN
- [ ] Write subqueries in WHERE and FROM clauses
- [ ] Use string functions (CONCAT, SUBSTRING, LEN)
- [ ] Use date functions (DATEPART, DATEDIFF, GETDATE)
- [ ] Apply CASE expressions for conditional logic
- [ ] Complete 80%+ of labs correctly
- [ ] Pass both quizzes with 75%+
- [ ] Complete practice project with all requirements

---

## 🚀 What's Next?

### After Module 02

**If you passed** (75%+ overall):
→ **Module 03: Advanced SQL** - CTEs, window functions, query optimization

**If you need more practice** (60-74%):
→ Redo labs with errors, review quiz answers, ask community for help

**If you struggled** (<60%):
→ Review prerequisites, slow down, focus on Week 1 first, join study group

---

## 📞 Getting Help

### Stuck on a Lab?

1. **Review the section** - Re-read the explanation
2. **Check hints** - Labs include hints for tricky parts
3. **Look at examples** - Each section has 5-10 examples
4. **Try partial solution** - Get partial results first, then refine
5. **Ask for help** - See below

---

### Community Support

**Karka Kasadara Community**:
- 💬 Discussions: https://github.com/karkakasadara-tharavu/zero-to-data-engineer/discussions
- 💬 Discord: [Your Discord Link]
- 💼 LinkedIn: [Your LinkedIn Group]
- 📖 Forum: [Your Forum Link]

**When asking for help, include**:
- Lab number (e.g., "Lab 02.3")
- What you tried (paste your SQL code)
- Error message (if any)
- Expected vs. actual results

**Remember**: Asking questions shows you're learning! 🎓

---

## 📅 Recommended Schedule

### Full-Time Learners (40 hours/week)

**Week 1**: Complete Sections 1-5 + Quiz 1  
**Week 2**: Complete Sections 6-10 + Quiz 2 + Practice Project

**Total**: 2 weeks, 46-60 hours

---

### Part-Time Learners (10 hours/week)

**Week 1-2**: Sections 1-3 (SELECT, WHERE, ORDER BY)  
**Week 3-4**: Sections 4-5 + Quiz 1 (Aggregations, GROUP BY)  
**Week 5-6**: Sections 6-7 (JOINs, Subqueries)  
**Week 7-8**: Sections 8-9 + Quiz 2 (Functions, CASE)  
**Week 9-10**: Section 10 (Practice Project)

**Total**: 10 weeks, 50-60 hours

---

### Casual Learners (3-5 hours/week)

**Month 1**: Sections 1-5 (Foundations)  
**Month 2**: Sections 6-7 (JOINs, Subqueries)  
**Month 3**: Sections 8-10 (Functions, Logic, Project)

**Total**: 12 weeks, 48-60 hours

---

## 🎉 Ready to Begin?

**Your first step**: [Section 01: SELECT Basics →](./01_select_basics.md)

**Estimated time**: 3 hours  
**What you'll learn**: SELECT syntax, column selection, aliases, basic queries

---

**Remember our motto**: கற்க கசடற (Karka Kasadara) - **Learn Flawlessly, Grow Together!**

You've got this! Every expert was once a beginner. Let's write some SQL! 💪📊

---

## 🔗 Navigation

| Direction | Link |
|-----------|------|
| ⬅️ Previous | [Module 01: SQL Server Setup](../Module_01_SQL_Server_Setup/) |
| ➡️ Next | [Module 03: Advanced SQL](../Module_03_Advanced_SQL/) |
| 🏠 Home | [Main Curriculum](../README.md) |
| 📚 Resources | [Study Materials](../Resources/) |

---

*Last Updated: December 7, 2025*
*Karka Kasadara - Your Data Engineering Partner*