# Data Engineering Interview Preparation Guide

## 🎯 Purpose
A comprehensive guide to ace Data Engineering interviews. Covers technical concepts, system design, behavioral questions, and practical tips for freshers and experienced candidates.

---

## Interview Structure Overview

Most Data Engineering interviews follow this pattern:

| Round | Focus | Duration |
|-------|-------|----------|
| Phone Screen | Resume, basics, motivation | 30-45 min |
| Technical 1 | SQL, Python coding | 45-60 min |
| Technical 2 | System design, architecture | 45-60 min |
| Technical 3 | Cloud, tools deep dive | 45-60 min |
| Behavioral | Culture fit, scenarios | 30-45 min |
| Hiring Manager | Experience, goals | 30-45 min |

---

## Part 1: SQL Interview Questions

### Beginner Level

**Q1: What is the difference between WHERE and HAVING?**
```
WHERE: Filters rows BEFORE grouping
HAVING: Filters groups AFTER aggregation

Example:
SELECT department, AVG(salary) as avg_sal
FROM employees
WHERE status = 'active'      -- Filter rows first
GROUP BY department
HAVING AVG(salary) > 50000;  -- Filter groups after
```

**Q2: Explain different types of JOINs.**
```
INNER JOIN: Only matching rows from both tables
LEFT JOIN: All from left + matching from right (NULL if no match)
RIGHT JOIN: All from right + matching from left
FULL OUTER: All from both, NULLs where no match
CROSS JOIN: Cartesian product (every row × every row)
SELF JOIN: Table joined with itself
```

**Q3: What is the difference between DELETE, TRUNCATE, and DROP?**
```
DELETE: Remove specific rows, logged, can rollback, triggers fire
TRUNCATE: Remove all rows, minimal logging, faster, resets identity
DROP: Remove entire table structure, cannot recover
```

### Intermediate Level

**Q4: Explain window functions with examples.**
```sql
-- Row numbering within groups
SELECT 
    employee_id,
    department,
    salary,
    ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC) as rank,
    SUM(salary) OVER (PARTITION BY department) as dept_total,
    LAG(salary) OVER (ORDER BY hire_date) as prev_salary
FROM employees;

Key concepts:
- PARTITION BY: Divides into groups
- ORDER BY: Orders within partition
- ROW_NUMBER: Unique sequential number
- RANK: Same rank for ties, gaps after
- DENSE_RANK: Same rank for ties, no gaps
- LAG/LEAD: Access previous/next row
- Running aggregates with frame specification
```

**Q5: What are CTEs and when would you use them?**
```sql
-- CTE for readability and reusability
WITH monthly_sales AS (
    SELECT 
        DATE_TRUNC('month', order_date) as month,
        SUM(amount) as total
    FROM orders
    GROUP BY 1
),
monthly_avg AS (
    SELECT AVG(total) as avg_monthly FROM monthly_sales
)
SELECT m.month, m.total, a.avg_monthly
FROM monthly_sales m, monthly_avg a
WHERE m.total > a.avg_monthly;

Use cases:
- Break complex queries into readable parts
- Reference same subquery multiple times
- Recursive queries for hierarchies
```

**Q6: How do you optimize a slow query?**
```
1. ANALYZE the execution plan (EXPLAIN)
2. Check for:
   - Table scans → Add indexes
   - Nested loops → Consider JOIN order
   - Sort operations → Add covering indexes
   
3. Optimization strategies:
   - Add indexes on WHERE and JOIN columns
   - Use covering indexes for SELECT columns
   - Avoid SELECT * (retrieve only needed columns)
   - Filter early with WHERE
   - Use EXISTS instead of IN for large subqueries
   - Partition large tables
   - Update statistics
```

### Advanced Level

**Q7: Explain Slowly Changing Dimensions (SCD).**
```
SCD Type 1: Overwrite old value (no history)
- Simple, but loses historical data

SCD Type 2: Add new row with version tracking
- Keeps full history
- Uses effective_date, end_date, is_current

SCD Type 3: Add previous value column
- Limited history (usually just one previous)

Example Type 2:
customer_id | name    | address  | effective_date | end_date   | is_current
1           | John    | NYC      | 2020-01-01     | 2023-05-15 | 0
1           | John    | LA       | 2023-05-16     | 9999-12-31 | 1
```

**Q8: How would you find the Nth highest salary?**
```sql
-- Method 1: Window function
SELECT salary FROM (
    SELECT salary, DENSE_RANK() OVER (ORDER BY salary DESC) as rank
    FROM employees
) ranked
WHERE rank = 3;  -- 3rd highest

-- Method 2: Subquery
SELECT MAX(salary) FROM employees
WHERE salary < (
    SELECT MAX(salary) FROM employees
    WHERE salary < (SELECT MAX(salary) FROM employees)
);

-- Method 3: OFFSET FETCH
SELECT DISTINCT salary 
FROM employees 
ORDER BY salary DESC 
OFFSET 2 ROWS FETCH NEXT 1 ROW ONLY;
```

**Q9: Write a query to find employees who earn more than their manager.**
```sql
SELECT e.name as employee, e.salary as emp_salary,
       m.name as manager, m.salary as mgr_salary
FROM employees e
JOIN employees m ON e.manager_id = m.employee_id
WHERE e.salary > m.salary;
```

**Q10: Explain query execution order.**
```
Logical order of SQL execution:
1. FROM (including JOINs)
2. WHERE
3. GROUP BY
4. HAVING
5. SELECT
6. DISTINCT
7. ORDER BY
8. LIMIT/OFFSET

This is why:
- You can't use SELECT alias in WHERE
- You can use SELECT alias in ORDER BY
- HAVING comes after GROUP BY
```

---

## Part 2: Python Interview Questions

### Data Structures

**Q1: What's the difference between list and tuple?**
```python
List: Mutable, slower, more memory
list1 = [1, 2, 3]
list1[0] = 10  # OK

Tuple: Immutable, faster, less memory, hashable
tuple1 = (1, 2, 3)
tuple1[0] = 10  # Error!

# Use tuple when:
# - Data shouldn't change
# - Need dictionary key
# - Want to ensure data integrity
```

**Q2: How does a dictionary work internally?**
```python
# Dictionaries use hash tables
# Key → Hash function → Index → Value

# Time complexity:
# - Access: O(1) average
# - Insert: O(1) average
# - Delete: O(1) average

# Hash collision: When two keys hash to same index
# Python handles via open addressing

# Keys must be hashable (immutable)
valid_key = (1, 2)     # Tuple OK
invalid_key = [1, 2]   # List not OK
```

**Q3: Explain list comprehension vs generator expression.**
```python
# List comprehension: Creates entire list in memory
squares = [x**2 for x in range(1000000)]  # Uses lots of memory

# Generator expression: Yields one item at a time
squares = (x**2 for x in range(1000000))  # Memory efficient

# Use generator when:
# - Processing large datasets
# - Only need to iterate once
# - Want lazy evaluation
```

### Functions and OOP

**Q4: What are *args and **kwargs?**
```python
def func(*args, **kwargs):
    print(args)    # Tuple of positional arguments
    print(kwargs)  # Dict of keyword arguments

func(1, 2, 3, name="John", age=30)
# args = (1, 2, 3)
# kwargs = {'name': 'John', 'age': 30}

# Useful for:
# - Flexible function signatures
# - Decorators
# - Passing arguments to another function
```

**Q5: Explain Python decorators.**
```python
def timer(func):
    def wrapper(*args, **kwargs):
        start = time.time()
        result = func(*args, **kwargs)
        print(f"Took {time.time() - start:.2f}s")
        return result
    return wrapper

@timer
def slow_function():
    time.sleep(1)
    return "done"

# Decorators wrap functions to extend behavior
# Common use cases: logging, timing, authentication, caching
```

**Q6: What is the difference between shallow and deep copy?**
```python
import copy

original = [[1, 2], [3, 4]]

# Shallow copy: New object, same nested references
shallow = copy.copy(original)
shallow[0][0] = 100  # Changes original too!

# Deep copy: New object, new nested objects
deep = copy.deepcopy(original)
deep[0][0] = 100  # Original unchanged
```

### Pandas Questions

**Q7: How do you handle missing data in Pandas?**
```python
# Detect
df.isna().sum()
df.isnull().any()

# Remove
df.dropna()                    # Drop rows with any null
df.dropna(subset=['col1'])     # Drop if specific column is null

# Fill
df.fillna(0)                   # Fill with constant
df.fillna(df.mean())           # Fill with mean
df.fillna(method='ffill')      # Forward fill
df.fillna(method='bfill')      # Backward fill

# Interpolate
df.interpolate()               # Linear interpolation
```

**Q8: Explain the difference between apply, map, and applymap.**
```python
# map: Series only, element-wise
df['col'].map(lambda x: x * 2)
df['col'].map({'old': 'new'})  # Also works with dict

# apply: Series or DataFrame
df['col'].apply(lambda x: x * 2)          # On Series
df.apply(lambda row: row.sum(), axis=1)   # On DataFrame rows

# applymap: DataFrame only, element-wise (deprecated, use map)
df.applymap(lambda x: x * 2)  # On every cell
```

**Q9: How do you optimize Pandas performance?**
```python
# 1. Use appropriate dtypes
df['category_col'] = df['category_col'].astype('category')
df['int_col'] = df['int_col'].astype('int32')  # Instead of int64

# 2. Avoid iterrows - use vectorization
# Bad
for idx, row in df.iterrows():
    df.loc[idx, 'new'] = row['a'] + row['b']

# Good
df['new'] = df['a'] + df['b']

# 3. Use chunking for large files
for chunk in pd.read_csv('large.csv', chunksize=10000):
    process(chunk)

# 4. Use eval for complex expressions
df.eval('new = (a + b) / c')

# 5. Use query for filtering
df.query('age > 25 and city == "NYC"')
```

### Coding Challenges

**Q10: Reverse a string without using built-in reverse.**
```python
def reverse_string(s):
    return s[::-1]  # Slicing

# Without slicing
def reverse_string(s):
    result = []
    for char in s:
        result.insert(0, char)
    return ''.join(result)

# Two pointers
def reverse_string(s):
    s = list(s)
    left, right = 0, len(s) - 1
    while left < right:
        s[left], s[right] = s[right], s[left]
        left += 1
        right -= 1
    return ''.join(s)
```

**Q11: Find duplicate elements in a list.**
```python
def find_duplicates(lst):
    seen = set()
    duplicates = set()
    for item in lst:
        if item in seen:
            duplicates.add(item)
        seen.add(item)
    return list(duplicates)

# One-liner
from collections import Counter
duplicates = [x for x, count in Counter(lst).items() if count > 1]
```

**Q12: Flatten a nested list.**
```python
def flatten(lst):
    result = []
    for item in lst:
        if isinstance(item, list):
            result.extend(flatten(item))
        else:
            result.append(item)
    return result

# Using itertools
from itertools import chain
flat = list(chain.from_iterable(nested))  # Only 1 level deep
```

---

## Part 3: System Design Questions

### ETL Pipeline Design

**Q1: Design a data pipeline for processing 10TB of daily log data.**

```
Requirements clarification:
- Data sources: Web server logs, application logs
- Frequency: Daily batch, near-real-time preferred
- Output: Analytics dashboard, ML features
- Latency requirement: Data available within 1 hour

Architecture:
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Sources   │ --> │   Ingest    │ --> │   Storage   │
│  (Logs)     │     │  (Kafka)    │     │  (S3/ADLS)  │
└─────────────┘     └─────────────┘     └─────────────┘
                           │                   │
                           v                   v
                    ┌─────────────┐     ┌─────────────┐
                    │  Streaming  │     │   Batch     │
                    │  (Spark SS) │     │  (Spark)    │
                    └─────────────┘     └─────────────┘
                           │                   │
                           v                   v
                    ┌─────────────────────────────────┐
                    │        Data Warehouse           │
                    │    (Snowflake/Synapse/BQ)       │
                    └─────────────────────────────────┘
                                   │
                                   v
                    ┌─────────────────────────────────┐
                    │         BI / Analytics          │
                    │     (Power BI / Looker)         │
                    └─────────────────────────────────┘

Key considerations:
1. Partitioning: Partition by date for efficient queries
2. File format: Parquet for columnar storage, compression
3. Data quality: Schema validation, null checks, deduplication
4. Monitoring: Data freshness, row counts, error rates
5. Recovery: Idempotent processing, checkpointing
6. Cost: Spot instances, auto-scaling, data lifecycle
```

### Data Warehouse Design

**Q2: Design a data warehouse for an e-commerce company.**

```
Star Schema Design:

         ┌──────────────┐
         │ dim_customer │
         └──────┬───────┘
                │
┌──────────────┐│┌──────────────┐
│  dim_product │││  dim_date    │
└──────┬───────┘│└──────┬───────┘
       │        │       │
       └────────┼───────┘
                │
         ┌──────┴───────┐
         │  fact_sales  │
         └──────┬───────┘
                │
         ┌──────┴───────┐
         │ dim_store    │
         └──────────────┘

Dimension Tables:
- dim_customer: customer_id, name, segment, region, signup_date
- dim_product: product_id, name, category, brand, price
- dim_date: date_id, date, day, month, quarter, year, is_weekend
- dim_store: store_id, name, city, state, country, type

Fact Table:
- fact_sales: sale_id, customer_id, product_id, date_id, store_id,
              quantity, unit_price, discount, total_amount

Design decisions:
1. Surrogate keys for dimensions (handle SCD Type 2)
2. Date dimension pre-populated with calendar attributes
3. Conformed dimensions across multiple fact tables
4. Aggregate tables for common queries
5. Partitioning fact table by date
6. Columnar storage for analytics
```

### Real-time Pipeline

**Q3: Design a real-time fraud detection system.**

```
Architecture:
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│Transaction  │ --> │   Kafka     │ --> │Spark Stream │
│  Events     │     │   Topic     │     │  Processing │
└─────────────┘     └─────────────┘     └─────────────┘
                                               │
                    ┌──────────────────────────┼───────────────────────┐
                    │                          │                       │
                    v                          v                       v
             ┌─────────────┐          ┌─────────────┐          ┌─────────────┐
             │  ML Model   │          │    Rules    │          │  Historical │
             │  Scoring    │          │   Engine    │          │   Lookup    │
             └─────────────┘          └─────────────┘          └─────────────┘
                    │                          │                       │
                    └──────────────────────────┼───────────────────────┘
                                               │
                                               v
                                        ┌─────────────┐
                                        │   Decision  │
                                        │   Service   │
                                        └──────┬──────┘
                                               │
                    ┌──────────────────────────┼───────────────────────┐
                    v                          v                       v
             ┌─────────────┐          ┌─────────────┐          ┌─────────────┐
             │   Approve   │          │   Review    │          │   Block     │
             │   Topic     │          │   Queue     │          │   + Alert   │
             └─────────────┘          └─────────────┘          └─────────────┘

Key requirements:
1. Latency: < 100ms decision time
2. Throughput: 10,000 transactions/second
3. Accuracy: Minimize false positives

Components:
- Feature store: Pre-computed features (avg transaction amount, etc.)
- Redis: Real-time feature lookup
- ML model: Gradient boosting or neural network
- Rules engine: Explicit fraud patterns
- Fallback: Default to manual review if system fails
```

---

## Part 4: Behavioral Questions

### STAR Method
Structure your answers as:
- **Situation**: Context and background
- **Task**: Your specific responsibility
- **Action**: Steps you took
- **Result**: Outcome with metrics

### Common Questions

**Q1: Tell me about a challenging project you worked on.**
```
Example answer:
Situation: Our e-commerce platform was experiencing 4-hour data delays 
in reporting, causing business decisions based on stale data.

Task: As the lead data engineer, I was responsible for reducing latency 
to under 15 minutes.

Action: 
1. Analyzed the existing batch ETL and identified bottlenecks
2. Proposed a streaming architecture using Kafka and Spark Streaming
3. Implemented incremental loads instead of full table scans
4. Added monitoring dashboards for data freshness

Result: Reduced data latency from 4 hours to 8 minutes. The business 
was able to respond to trends same-day, increasing conversion by 12%.
```

**Q2: How do you handle disagreements with team members?**
```
Example answer:
I focus on data and outcomes rather than opinions. Recently, a colleague 
and I disagreed on whether to use Airflow or Prefect for orchestration.

Instead of debating preferences, I suggested we define evaluation criteria 
(scalability, learning curve, cost, community support) and score each option.

We ran a small POC with both tools. The results clearly showed Airflow 
was better for our specific use case. My colleague agreed, and we moved 
forward with full team buy-in.
```

**Q3: Describe a time you failed and what you learned.**
```
Example answer:
Early in my career, I deployed a data pipeline without proper testing. 
It worked in development but failed in production due to different data 
volumes and edge cases. We had 6 hours of downtime.

What I learned:
1. Always test with production-like data volumes
2. Implement proper error handling and alerting
3. Create runbooks for incident response
4. Set up staging environments that mirror production

Now I advocate for comprehensive testing and have implemented automated 
testing pipelines that have prevented similar issues.
```

**Q4: How do you prioritize when everything is urgent?**
```
Example answer:
I use a framework based on business impact and effort:

1. First, understand the actual urgency vs. perceived urgency
2. Assess business impact of each task
3. Estimate effort required
4. Communicate trade-offs to stakeholders

Recently, I had three "urgent" requests simultaneously. I held a quick 
sync with stakeholders, explained the situation, and we agreed on:
- Task A (production bug): Immediate fix
- Task B (exec report): Next-day delivery
- Task C (new feature): Pushed to next sprint

Clear communication and setting expectations prevented everyone feeling 
ignored while ensuring the most critical work got done first.
```

---

## Part 5: Technical Deep Dives

### Cloud Platforms

**Azure Data Engineering Stack:**
```
Storage: Azure Data Lake Storage Gen2
Compute: Azure Synapse Analytics, Databricks
Orchestration: Azure Data Factory
Streaming: Event Hubs, Stream Analytics
Governance: Purview
Monitoring: Azure Monitor
```

**AWS Data Engineering Stack:**
```
Storage: S3
Compute: Redshift, EMR, Glue
Orchestration: Step Functions, MWAA (Airflow)
Streaming: Kinesis
Governance: Lake Formation
Monitoring: CloudWatch
```

### Data Quality

**Q: How do you ensure data quality in pipelines?**
```
1. Schema validation
   - Enforce expected columns and types
   - Fail fast on schema changes

2. Data validation rules
   - Null checks on required fields
   - Range checks (e.g., age between 0-150)
   - Pattern matching (email, phone)
   - Referential integrity

3. Monitoring and alerting
   - Row count anomalies
   - Null percentage spikes
   - Data freshness tracking

4. Testing
   - Unit tests for transformations
   - Integration tests for pipelines
   - Data contracts between teams

5. Tools
   - Great Expectations
   - dbt tests
   - Custom validation frameworks
```

### Performance Optimization

**Q: How do you optimize PySpark jobs?**
```
1. Partitioning
   - Choose partition column wisely
   - Aim for 100-200MB per partition
   - Use repartition() or coalesce()

2. Caching
   - Cache DataFrames reused multiple times
   - Use appropriate storage level
   - Unpersist when done

3. Broadcast joins
   - Broadcast small tables (< 10MB)
   - Avoid shuffles

4. Avoid anti-patterns
   - No Python UDFs when built-in exists
   - No collect() on large data
   - Use filter early

5. Configuration tuning
   - spark.sql.shuffle.partitions
   - executor memory and cores
   - Enable AQE (Adaptive Query Execution)

6. File formats
   - Use Parquet or Delta
   - Enable predicate pushdown
```

---

## Part 6: Tips for Success

### Before the Interview
- [ ] Review the job description carefully
- [ ] Research the company's data stack
- [ ] Practice SQL on LeetCode/HackerRank
- [ ] Prepare 5-7 STAR stories
- [ ] Have questions ready for interviewers

### During the Interview
- [ ] Think out loud during technical problems
- [ ] Ask clarifying questions before coding
- [ ] Discuss trade-offs in design questions
- [ ] Be honest about what you don't know
- [ ] Show enthusiasm and curiosity

### Common Mistakes to Avoid
- Jumping into code without understanding requirements
- Overcomplicating solutions
- Not testing edge cases
- Giving vague behavioral answers
- Not asking questions at the end

### Questions to Ask Interviewers
1. "What does a typical day look like for this role?"
2. "What's the current data architecture?"
3. "What are the biggest data challenges you're facing?"
4. "How does the data team collaborate with other departments?"
5. "What growth opportunities exist for data engineers?"
6. "What does success look like in the first 6 months?"

---

## Quick Reference Card

### SQL Must-Know
- JOINs (all types)
- Window functions
- CTEs and subqueries
- GROUP BY / HAVING
- CASE statements
- Query optimization

### Python Must-Know
- Data structures
- List comprehensions
- Pandas operations
- Error handling
- File I/O
- Basic OOP

### System Design Must-Know
- ETL vs ELT
- Star schema
- Data partitioning
- Streaming vs batch
- Data quality
- Scalability patterns

### Behavioral Must-Know
- STAR method
- 5-7 prepared stories
- Failure and learning
- Conflict resolution
- Prioritization

---

**Good luck with your interviews! 🚀**

Remember: Interviewers want you to succeed. They're looking for someone who can solve problems, communicate clearly, and work well with others. Be yourself, stay calm, and show your passion for data engineering.
