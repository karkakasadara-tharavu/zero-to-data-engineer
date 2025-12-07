# Python to PySpark Curriculum Plan
## Modules 10-17: Python Data Engineering Track

---

## 📊 Curriculum Overview

**Target Audience**: Data Engineers who completed SQL modules (00-09)  
**Total Duration**: 14-18 weeks (280-360 hours)  
**Progression**: Python Basics → Advanced Python → Pandas → SQL Integration → Spark → PySpark → Advanced PySpark  
**Tools**: Python 3.11+, Jupyter Notebooks, Pandas, PySpark, Apache Spark

---

## 🗺️ Module Structure

| Module | Topic | Duration | Difficulty | Prerequisites |
|--------|-------|----------|------------|---------------|
| **10** | Python Fundamentals | 2 weeks | ⭐ Beginner | None (fresh start) |
| **11** | Advanced Python & OOP | 2 weeks | ⭐⭐ Intermediate | Module 10 |
| **12** | Data Processing with Pandas | 2 weeks | ⭐⭐⭐ Intermediate | Module 11 |
| **13** | Python + SQL Integration | 2 weeks | ⭐⭐⭐ Intermediate-Advanced | Modules 02, 12 |
| **14** | Introduction to Apache Spark | 1.5 weeks | ⭐⭐⭐ Advanced | Module 13 |
| **15** | PySpark Fundamentals | 2 weeks | ⭐⭐⭐⭐ Advanced | Module 14 |
| **16** | Advanced PySpark | 2 weeks | ⭐⭐⭐⭐ Expert | Module 15 |
| **17** | Python Capstone Project | 1.5 weeks | ⭐⭐⭐⭐ Expert | All modules |

---

## 📚 Module 10: Python Fundamentals

**Duration**: 2 weeks (40-50 hours)  
**Difficulty**: ⭐ Beginner  
**Goal**: Master Python syntax, data structures, and control flow

### Topics:
1. **Python Installation & Setup**
   - Installing Python 3.11+
   - VS Code setup with Python extension
   - Virtual environments (venv)
   - pip package management

2. **Python Basics**
   - Variables and data types (int, float, str, bool)
   - Type conversion and type hints
   - Input/output operations
   - Comments and documentation

3. **Data Structures**
   - Lists (creation, indexing, slicing, methods)
   - Tuples (immutability, packing/unpacking)
   - Dictionaries (key-value pairs, methods)
   - Sets (unique elements, operations)

4. **Control Flow**
   - if/elif/else statements
   - for loops (range, enumerate, zip)
   - while loops
   - break, continue, pass

5. **Functions**
   - Function definition and calling
   - Parameters and arguments
   - Return values
   - Lambda functions
   - *args and **kwargs

6. **String Manipulation**
   - String methods (split, join, strip, replace)
   - f-strings and formatting
   - Regular expressions basics

### Labs (10 labs):
- Lab 01: Variables and Data Types
- Lab 02: Lists and List Comprehensions
- Lab 03: Dictionary Operations
- Lab 04: Control Flow - Decision Making
- Lab 05: Loops and Iterations
- Lab 06: Functions - Basic to Advanced
- Lab 07: String Processing
- Lab 08: Working with Files (CSV reading)
- Lab 09: Error Handling Basics
- Lab 10: Mini Project - Data Analysis Script

### Assessment:
- Quiz 01: Python Basics (20 questions)
- Quiz 02: Functions and Data Structures (15 questions)

---

## 📚 Module 11: Advanced Python & OOP

**Duration**: 2 weeks (40-50 hours)  
**Difficulty**: ⭐⭐ Intermediate  
**Goal**: Object-oriented programming and advanced Python concepts

### Topics:
1. **Object-Oriented Programming**
   - Classes and objects
   - __init__ constructor
   - Attributes and methods
   - self parameter
   - Encapsulation

2. **OOP Advanced Concepts**
   - Inheritance (single, multiple)
   - Polymorphism
   - Method overriding
   - super() function
   - Abstract classes

3. **File Operations**
   - Reading/writing text files
   - CSV files with csv module
   - JSON files
   - Context managers (with statement)

4. **Error Handling**
   - try/except/finally
   - Raising exceptions
   - Custom exceptions
   - Logging module

5. **Modules and Packages**
   - Importing modules
   - Creating custom modules
   - __name__ == "__main__"
   - Virtual environments deep dive

6. **Advanced Topics**
   - Decorators
   - Generators and iterators
   - List/dict/set comprehensions
   - datetime module

### Labs (10 labs):
- Lab 11: Creating Classes - Customer Database
- Lab 12: Inheritance - Employee Management
- Lab 13: File I/O - Log File Processing
- Lab 14: CSV Processing - Sales Data
- Lab 15: JSON Operations - Configuration Files
- Lab 16: Error Handling - Robust Scripts
- Lab 17: Decorators - Function Timing
- Lab 18: Generators - Large File Processing
- Lab 19: Custom Module - Data Utilities
- Lab 20: Mini Project - OOP ETL Pipeline

### Assessment:
- Quiz 03: OOP Concepts (20 questions)
- Quiz 04: File Operations & Error Handling (15 questions)

---

## 📚 Module 12: Data Processing with Pandas

**Duration**: 2 weeks (40-50 hours)  
**Difficulty**: ⭐⭐⭐ Intermediate  
**Goal**: Master Pandas for data manipulation and analysis

### Topics:
1. **Pandas Fundamentals**
   - Installing Pandas and NumPy
   - Series and DataFrames
   - Reading data (CSV, Excel, JSON)
   - DataFrame exploration (head, tail, info, describe)

2. **Data Selection**
   - Indexing with [] and .loc[]/.iloc[]
   - Boolean filtering
   - Query method
   - Selecting columns and rows

3. **Data Cleaning**
   - Handling missing values (isnull, fillna, dropna)
   - Removing duplicates
   - Data type conversions
   - String operations on columns

4. **Data Transformation**
   - Creating new columns
   - Apply and map functions
   - Lambda with Pandas
   - Binning and categorization

5. **Aggregations & Grouping**
   - groupby operations
   - Aggregation functions (sum, mean, count)
   - Multiple aggregations
   - Pivot tables

6. **Merging & Joining**
   - concat for combining DataFrames
   - merge for SQL-style joins
   - join method
   - Handling merge keys

7. **Time Series**
   - datetime handling
   - Date ranges
   - Resampling
   - Rolling windows

### Labs (12 labs):
- Lab 21: DataFrame Basics - AdventureWorks Products
- Lab 22: Data Selection - Filtering Customers
- Lab 23: Missing Data Handling - Sales Records
- Lab 24: Data Cleaning Project
- Lab 25: Creating Calculated Columns
- Lab 26: GroupBy - Sales Analysis
- Lab 27: Pivot Tables - Regional Performance
- Lab 28: Merging Datasets - Customer Orders
- Lab 29: Time Series - Daily Sales Trends
- Lab 30: Apply Functions - Custom Transformations
- Lab 31: Data Export - Multiple Formats
- Lab 32: Mini Project - Sales Dashboard Data Prep

### Assessment:
- Quiz 05: Pandas Fundamentals (20 questions)
- Quiz 06: Data Manipulation & Aggregation (20 questions)

---

## 📚 Module 13: Python + SQL Integration

**Duration**: 2 weeks (40-50 hours)  
**Difficulty**: ⭐⭐⭐ Intermediate-Advanced  
**Goal**: Connect Python to SQL Server, perform ETL operations

### Topics:
1. **Database Connectivity**
   - pyodbc installation and setup
   - Connection strings
   - Creating connections
   - Cursor objects

2. **Executing SQL from Python**
   - SELECT queries with fetchall/fetchone
   - Parameterized queries (SQL injection prevention)
   - INSERT operations
   - UPDATE and DELETE

3. **SQLAlchemy ORM**
   - SQLAlchemy installation
   - Engine creation
   - Table reflection
   - ORM basics

4. **Pandas + SQL**
   - read_sql_query
   - read_sql_table
   - to_sql method
   - Chunking large datasets

5. **ETL Patterns in Python**
   - Extract from SQL Server
   - Transform with Pandas
   - Load back to database
   - Error handling in ETL

6. **Advanced Integration**
   - Stored procedure execution
   - Bulk inserts
   - Transaction management
   - Connection pooling

### Labs (10 labs):
- Lab 33: pyodbc Connection Setup
- Lab 34: Basic SQL Queries from Python
- Lab 35: Parameterized Queries - Safe Inserts
- Lab 36: Reading SQL to DataFrame
- Lab 37: DataFrame to SQL Table
- Lab 38: SQLAlchemy Basics
- Lab 39: Calling Stored Procedures
- Lab 40: ETL Pipeline - Extract Transform Load
- Lab 41: Bulk Operations - Performance
- Lab 42: Mini Project - Automated Report Generation

### Assessment:
- Quiz 07: Python-SQL Connectivity (15 questions)
- Quiz 08: ETL Patterns (15 questions)

---

## 📚 Module 14: Introduction to Apache Spark

**Duration**: 1.5 weeks (30-40 hours)  
**Difficulty**: ⭐⭐⭐ Advanced  
**Goal**: Understand distributed computing and Spark architecture

### Topics:
1. **Spark Fundamentals**
   - What is Apache Spark?
   - Spark vs Hadoop MapReduce
   - Use cases for Spark
   - Spark architecture (Driver, Executors, Cluster Manager)

2. **Spark Installation**
   - Installing Java JDK
   - Installing Apache Spark locally
   - Setting environment variables
   - Spark shell basics

3. **RDD Basics**
   - Resilient Distributed Datasets
   - Creating RDDs
   - Transformations vs Actions
   - Lazy evaluation

4. **Spark SQL**
   - SparkSession
   - Creating DataFrames
   - SQL queries in Spark
   - Temporary views

5. **Data Sources**
   - Reading CSV, JSON, Parquet
   - Writing data
   - Schema inference
   - Schema specification

### Labs (8 labs):
- Lab 43: Spark Installation & Setup
- Lab 44: First Spark Application
- Lab 45: RDD Transformations
- Lab 46: RDD Actions
- Lab 47: Creating Spark DataFrames
- Lab 48: Reading Different File Formats
- Lab 49: Spark SQL Queries
- Lab 50: Mini Project - Log File Analysis

### Assessment:
- Quiz 09: Spark Fundamentals (20 questions)

---

## 📚 Module 15: PySpark Fundamentals

**Duration**: 2 weeks (40-50 hours)  
**Difficulty**: ⭐⭐⭐⭐ Advanced  
**Goal**: Master PySpark DataFrame API and operations

### Topics:
1. **PySpark Setup**
   - Installing PySpark via pip
   - Jupyter integration
   - SparkSession configuration
   - Understanding Spark UI

2. **DataFrame Operations**
   - select, filter, where
   - withColumn, drop
   - Renaming columns
   - Column expressions

3. **Aggregations**
   - groupBy and agg
   - Built-in functions (sum, avg, count, max, min)
   - Multiple aggregations
   - Having clause

4. **Joins**
   - Inner, left, right, outer joins
   - Cross joins
   - Semi and anti joins
   - Broadcast joins

5. **SQL Functions**
   - String functions (concat, substring, regexp)
   - Date functions (date_format, datediff)
   - Mathematical functions
   - Conditional functions (when, otherwise)

6. **Data Reading/Writing**
   - CSV, JSON, Parquet, ORC
   - Options and configurations
   - Partitioning data
   - Compression

### Labs (12 labs):
- Lab 51: PySpark Environment Setup
- Lab 52: DataFrame Basics - Selection & Filtering
- Lab 53: Column Operations & Transformations
- Lab 54: Aggregations - Sales Analysis
- Lab 55: Joins - Customer Order Analysis
- Lab 56: String Functions - Text Processing
- Lab 57: Date Operations - Time Series
- Lab 58: Complex Aggregations
- Lab 59: Reading from Multiple Sources
- Lab 60: Writing with Partitioning
- Lab 61: Working with Nested Data
- Lab 62: Mini Project - E-commerce Analytics

### Assessment:
- Quiz 10: PySpark DataFrame API (20 questions)
- Quiz 11: Aggregations & Joins (15 questions)

---

## 📚 Module 16: Advanced PySpark

**Duration**: 2 weeks (40-50 hours)  
**Difficulty**: ⭐⭐⭐⭐ Expert  
**Goal**: Advanced PySpark techniques and performance optimization

### Topics:
1. **Window Functions**
   - Window specification
   - Ranking functions (row_number, rank, dense_rank)
   - Analytic functions (lead, lag)
   - Aggregate window functions

2. **User Defined Functions (UDFs)**
   - Creating UDFs
   - Registering UDFs
   - Pandas UDFs (vectorized)
   - UDF performance considerations

3. **Performance Optimization**
   - Caching and persistence
   - Partitioning strategies
   - Broadcast variables
   - Avoiding shuffles

4. **Advanced Transformations**
   - Explode and arrays
   - Struct columns
   - Map operations
   - Complex nested data

5. **Streaming Basics**
   - Structured Streaming introduction
   - Reading streams
   - Writing streams
   - Triggers and windowing

6. **Integration Patterns**
   - Reading from SQL Server with JDBC
   - Writing to data lakes
   - Delta Lake basics
   - Connecting to cloud storage

### Labs (10 labs):
- Lab 63: Window Functions - Rankings
- Lab 64: Running Totals & Moving Averages
- Lab 65: Creating Custom UDFs
- Lab 66: Pandas UDFs for Performance
- Lab 67: Caching Strategies
- Lab 68: Partitioning Optimization
- Lab 69: Working with Nested JSON
- Lab 70: Streaming Data Processing
- Lab 71: SQL Server Integration via JDBC
- Lab 72: Mini Project - Real-time Analytics Pipeline

### Assessment:
- Quiz 12: Window Functions & UDFs (15 questions)
- Quiz 13: Performance Optimization (15 questions)

---

## 📚 Module 17: Python Data Engineering Capstone

**Duration**: 1.5 weeks (30-40 hours)  
**Difficulty**: ⭐⭐⭐⭐ Expert  
**Goal**: Build end-to-end data pipeline integrating all learned skills

### Project Requirements:

**Scenario**: Build a complete data engineering solution for retail analytics

**Components**:
1. **Data Extraction**
   - Extract from SQL Server (AdventureWorks)
   - Read from CSV files
   - Ingest JSON API data

2. **Data Processing (Pandas)**
   - Clean and validate data
   - Handle missing values
   - Create calculated metrics

3. **Large-Scale Processing (PySpark)**
   - Process large datasets
   - Complex transformations
   - Aggregations and window functions

4. **Data Loading**
   - Write processed data back to SQL Server
   - Export to Parquet data lake
   - Generate summary reports

5. **Pipeline Orchestration**
   - Create modular Python scripts
   - Error handling and logging
   - Configuration management
   - Documentation

**Deliverables**:
- Complete Python/PySpark codebase
- Documentation (README, code comments)
- Data pipeline architecture diagram
- Performance metrics report
- Testing and validation scripts

### Evaluation Rubric (100 points):
- Code Quality (20 points)
- Functionality (30 points)
- Performance (15 points)
- Error Handling (10 points)
- Documentation (15 points)
- Innovation (10 points)

---

## 🛠️ Tools & Setup

### Required Software:
- **Python 3.11+** (latest stable)
- **Anaconda/Miniconda** (recommended)
- **VS Code** with Python extension
- **Jupyter Notebooks**
- **Git** for version control

### Python Packages:
```bash
# Core packages
pip install pandas numpy matplotlib seaborn

# SQL connectivity
pip install pyodbc sqlalchemy

# Spark
pip install pyspark

# Development
pip install jupyter ipython pytest black pylint
```

### Datasets:
- **AdventureWorks2022** (from SQL modules)
- **Sample CSV/JSON files** (provided in assets)
- **Large datasets** for PySpark practice (10GB+)

---

## 📈 Learning Path Visualization

```
SQL Modules (00-09)
       ↓
Python Basics (10) → Advanced Python (11)
       ↓                      ↓
Pandas Data Processing (12)  ←
       ↓
Python + SQL Integration (13)
       ↓
Apache Spark Intro (14)
       ↓
PySpark Fundamentals (15)
       ↓
Advanced PySpark (16)
       ↓
Python Capstone (17)
```

---

## 🎯 Career Outcomes

After completing this Python track, you will be able to:

✅ Write production-quality Python code  
✅ Process data with Pandas efficiently  
✅ Integrate Python with SQL Server  
✅ Build distributed data pipelines with PySpark  
✅ Optimize Spark jobs for performance  
✅ Handle large-scale data processing (100GB+)  
✅ Create end-to-end ETL solutions  

**Job Roles**: Data Engineer, ETL Developer, Big Data Engineer, Analytics Engineer

**Salary Range**: $75K - $150K (with SQL + Python + PySpark skills)

---

## 📝 Next Steps

1. Complete SQL modules (00-09) if not already done
2. Start with Module 10: Python Fundamentals
3. Practice daily with hands-on labs
4. Join Python/PySpark communities
5. Build portfolio projects
6. Apply for data engineering roles

---

**கற்க கசடற** - Learn Flawlessly

*This Python curriculum is part of the Karka Kasadara Data Engineering program.*

