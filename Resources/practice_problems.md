# Data Engineering Practice Problems

## 🎯 Purpose
Hands-on practice problems covering SQL, Python, and PySpark. Organized by difficulty level with solutions. Perfect for interview prep and skill building.

---

## SQL Practice Problems

### Easy Level

#### Problem 1: Find Employees with Above-Average Salary
Given an `employees` table:
```sql
CREATE TABLE employees (
    id INT,
    name VARCHAR(100),
    department VARCHAR(50),
    salary DECIMAL(10,2)
);
```

**Task**: Find all employees who earn more than the average salary.

<details>
<summary>Solution</summary>

```sql
SELECT name, department, salary
FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees)
ORDER BY salary DESC;
```
</details>

---

#### Problem 2: Second Highest Salary
**Task**: Find the second highest salary in the table.

<details>
<summary>Solution</summary>

```sql
-- Method 1: Subquery
SELECT MAX(salary) AS second_highest
FROM employees
WHERE salary < (SELECT MAX(salary) FROM employees);

-- Method 2: Window function
SELECT salary
FROM (
    SELECT salary, DENSE_RANK() OVER (ORDER BY salary DESC) AS rank
    FROM employees
) ranked
WHERE rank = 2;

-- Method 3: OFFSET
SELECT DISTINCT salary
FROM employees
ORDER BY salary DESC
OFFSET 1 ROW FETCH NEXT 1 ROW ONLY;
```
</details>

---

#### Problem 3: Duplicate Emails
Given a `users` table:
```sql
CREATE TABLE users (
    id INT,
    email VARCHAR(100)
);
```

**Task**: Find all duplicate email addresses.

<details>
<summary>Solution</summary>

```sql
SELECT email, COUNT(*) as count
FROM users
GROUP BY email
HAVING COUNT(*) > 1;
```
</details>

---

### Medium Level

#### Problem 4: Department-wise Top Earner
**Task**: Find the highest-paid employee in each department.

<details>
<summary>Solution</summary>

```sql
-- Method 1: Window function
WITH RankedEmployees AS (
    SELECT 
        name, 
        department, 
        salary,
        RANK() OVER (PARTITION BY department ORDER BY salary DESC) as rank
    FROM employees
)
SELECT name, department, salary
FROM RankedEmployees
WHERE rank = 1;

-- Method 2: Correlated subquery
SELECT e.name, e.department, e.salary
FROM employees e
WHERE e.salary = (
    SELECT MAX(salary) 
    FROM employees 
    WHERE department = e.department
);
```
</details>

---

#### Problem 5: Running Total
Given an `orders` table:
```sql
CREATE TABLE orders (
    order_id INT,
    order_date DATE,
    amount DECIMAL(10,2)
);
```

**Task**: Calculate running total of order amounts by date.

<details>
<summary>Solution</summary>

```sql
SELECT 
    order_date,
    amount,
    SUM(amount) OVER (ORDER BY order_date) AS running_total,
    AVG(amount) OVER (ORDER BY order_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3
FROM orders
ORDER BY order_date;
```
</details>

---

#### Problem 6: Consecutive Days
Given a `logins` table:
```sql
CREATE TABLE logins (
    user_id INT,
    login_date DATE
);
```

**Task**: Find users who logged in for 3 or more consecutive days.

<details>
<summary>Solution</summary>

```sql
WITH ConsecutiveGroups AS (
    SELECT 
        user_id,
        login_date,
        login_date - ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY login_date) * INTERVAL '1 day' AS group_date
    FROM logins
),
ConsecutiveCount AS (
    SELECT 
        user_id,
        group_date,
        COUNT(*) AS consecutive_days,
        MIN(login_date) AS start_date,
        MAX(login_date) AS end_date
    FROM ConsecutiveGroups
    GROUP BY user_id, group_date
)
SELECT DISTINCT user_id
FROM ConsecutiveCount
WHERE consecutive_days >= 3;
```
</details>

---

#### Problem 7: Year-over-Year Growth
Given a `sales` table:
```sql
CREATE TABLE sales (
    sale_date DATE,
    amount DECIMAL(10,2)
);
```

**Task**: Calculate YoY growth percentage by month.

<details>
<summary>Solution</summary>

```sql
WITH MonthlySales AS (
    SELECT 
        YEAR(sale_date) AS year,
        MONTH(sale_date) AS month,
        SUM(amount) AS total_sales
    FROM sales
    GROUP BY YEAR(sale_date), MONTH(sale_date)
)
SELECT 
    curr.year,
    curr.month,
    curr.total_sales,
    prev.total_sales AS prev_year_sales,
    ROUND(
        (curr.total_sales - prev.total_sales) / prev.total_sales * 100, 
        2
    ) AS yoy_growth_pct
FROM MonthlySales curr
LEFT JOIN MonthlySales prev 
    ON curr.year = prev.year + 1 
    AND curr.month = prev.month
ORDER BY curr.year, curr.month;
```
</details>

---

### Hard Level

#### Problem 8: Median Salary
**Task**: Calculate the median salary for each department.

<details>
<summary>Solution</summary>

```sql
-- SQL Server method
WITH Ordered AS (
    SELECT 
        department,
        salary,
        ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary) AS row_num,
        COUNT(*) OVER (PARTITION BY department) AS total_count
    FROM employees
)
SELECT 
    department,
    AVG(salary) AS median_salary
FROM Ordered
WHERE row_num IN ((total_count + 1) / 2, (total_count + 2) / 2)
GROUP BY department;

-- Using PERCENTILE_CONT (SQL Server 2012+)
SELECT DISTINCT
    department,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salary) 
        OVER (PARTITION BY department) AS median_salary
FROM employees;
```
</details>

---

#### Problem 9: Gaps in Sequences
Given an `ids` table with potentially missing IDs:
```sql
CREATE TABLE ids (id INT);
-- Contains: 1, 2, 3, 5, 6, 10
```

**Task**: Find all gaps in the sequence.

<details>
<summary>Solution</summary>

```sql
WITH NumberedIDs AS (
    SELECT 
        id,
        LEAD(id) OVER (ORDER BY id) AS next_id
    FROM ids
)
SELECT 
    id + 1 AS gap_start,
    next_id - 1 AS gap_end
FROM NumberedIDs
WHERE next_id - id > 1;

-- Result: (4, 4), (7, 9)
```
</details>

---

#### Problem 10: Tree Structure (Recursive CTE)
Given a hierarchical `categories` table:
```sql
CREATE TABLE categories (
    id INT,
    name VARCHAR(100),
    parent_id INT NULL
);
```

**Task**: Get all categories with their full path (e.g., "Electronics > Phones > Smartphones").

<details>
<summary>Solution</summary>

```sql
WITH CategoryPath AS (
    -- Base case: root categories
    SELECT 
        id, 
        name, 
        parent_id,
        CAST(name AS VARCHAR(1000)) AS full_path,
        0 AS level
    FROM categories
    WHERE parent_id IS NULL
    
    UNION ALL
    
    -- Recursive case: child categories
    SELECT 
        c.id, 
        c.name, 
        c.parent_id,
        CAST(cp.full_path + ' > ' + c.name AS VARCHAR(1000)),
        cp.level + 1
    FROM categories c
    INNER JOIN CategoryPath cp ON c.parent_id = cp.id
)
SELECT id, name, full_path, level
FROM CategoryPath
ORDER BY full_path;
```
</details>

---

## Python Practice Problems

### Easy Level

#### Problem 11: Remove Duplicates
**Task**: Remove duplicates from a list while preserving order.

```python
items = [1, 2, 3, 2, 4, 1, 5]
# Expected: [1, 2, 3, 4, 5]
```

<details>
<summary>Solution</summary>

```python
# Method 1: Using dict (Python 3.7+)
def remove_duplicates(items):
    return list(dict.fromkeys(items))

# Method 2: Using set with order tracking
def remove_duplicates(items):
    seen = set()
    result = []
    for item in items:
        if item not in seen:
            seen.add(item)
            result.append(item)
    return result

# Method 3: One-liner
items = list(dict.fromkeys(items))
```
</details>

---

#### Problem 12: Flatten Nested List
**Task**: Flatten a nested list of arbitrary depth.

```python
nested = [1, [2, 3], [4, [5, 6]], 7]
# Expected: [1, 2, 3, 4, 5, 6, 7]
```

<details>
<summary>Solution</summary>

```python
def flatten(lst):
    result = []
    for item in lst:
        if isinstance(item, list):
            result.extend(flatten(item))
        else:
            result.append(item)
    return result

# Generator version (memory efficient)
def flatten_gen(lst):
    for item in lst:
        if isinstance(item, list):
            yield from flatten_gen(item)
        else:
            yield item

flat = list(flatten_gen(nested))
```
</details>

---

#### Problem 13: Word Frequency
**Task**: Count word frequency in a string.

```python
text = "hello world hello python world world"
# Expected: {'world': 3, 'hello': 2, 'python': 1}
```

<details>
<summary>Solution</summary>

```python
from collections import Counter

def word_frequency(text):
    words = text.lower().split()
    return dict(Counter(words).most_common())

# Without Counter
def word_frequency(text):
    words = text.lower().split()
    freq = {}
    for word in words:
        freq[word] = freq.get(word, 0) + 1
    return dict(sorted(freq.items(), key=lambda x: -x[1]))
```
</details>

---

### Medium Level

#### Problem 14: Group Anagrams
**Task**: Group strings that are anagrams of each other.

```python
words = ["eat", "tea", "tan", "ate", "nat", "bat"]
# Expected: [["eat", "tea", "ate"], ["tan", "nat"], ["bat"]]
```

<details>
<summary>Solution</summary>

```python
from collections import defaultdict

def group_anagrams(words):
    groups = defaultdict(list)
    for word in words:
        key = ''.join(sorted(word))
        groups[key].append(word)
    return list(groups.values())

# Alternative: using tuple of character counts
def group_anagrams(words):
    groups = defaultdict(list)
    for word in words:
        count = [0] * 26
        for char in word:
            count[ord(char) - ord('a')] += 1
        groups[tuple(count)].append(word)
    return list(groups.values())
```
</details>

---

#### Problem 15: Merge Intervals
**Task**: Merge overlapping intervals.

```python
intervals = [[1,3], [2,6], [8,10], [15,18]]
# Expected: [[1,6], [8,10], [15,18]]
```

<details>
<summary>Solution</summary>

```python
def merge_intervals(intervals):
    if not intervals:
        return []
    
    # Sort by start time
    intervals.sort(key=lambda x: x[0])
    merged = [intervals[0]]
    
    for start, end in intervals[1:]:
        if start <= merged[-1][1]:  # Overlapping
            merged[-1][1] = max(merged[-1][1], end)
        else:
            merged.append([start, end])
    
    return merged
```
</details>

---

#### Problem 16: LRU Cache
**Task**: Implement an LRU (Least Recently Used) cache.

<details>
<summary>Solution</summary>

```python
from collections import OrderedDict

class LRUCache:
    def __init__(self, capacity: int):
        self.capacity = capacity
        self.cache = OrderedDict()
    
    def get(self, key: int) -> int:
        if key not in self.cache:
            return -1
        # Move to end (most recently used)
        self.cache.move_to_end(key)
        return self.cache[key]
    
    def put(self, key: int, value: int) -> None:
        if key in self.cache:
            self.cache.move_to_end(key)
        self.cache[key] = value
        if len(self.cache) > self.capacity:
            self.cache.popitem(last=False)  # Remove oldest

# Usage
cache = LRUCache(2)
cache.put(1, 1)
cache.put(2, 2)
cache.get(1)      # Returns 1
cache.put(3, 3)   # Evicts key 2
cache.get(2)      # Returns -1 (not found)
```
</details>

---

### Hard Level

#### Problem 17: Rate Limiter
**Task**: Implement a sliding window rate limiter.

<details>
<summary>Solution</summary>

```python
import time
from collections import deque

class RateLimiter:
    def __init__(self, max_requests: int, window_seconds: int):
        self.max_requests = max_requests
        self.window_seconds = window_seconds
        self.requests = {}  # user_id -> deque of timestamps
    
    def is_allowed(self, user_id: str) -> bool:
        current_time = time.time()
        
        if user_id not in self.requests:
            self.requests[user_id] = deque()
        
        user_requests = self.requests[user_id]
        
        # Remove expired timestamps
        while user_requests and current_time - user_requests[0] > self.window_seconds:
            user_requests.popleft()
        
        if len(user_requests) < self.max_requests:
            user_requests.append(current_time)
            return True
        return False

# Usage
limiter = RateLimiter(max_requests=5, window_seconds=60)
for i in range(7):
    print(f"Request {i+1}: {'Allowed' if limiter.is_allowed('user1') else 'Blocked'}")
```
</details>

---

## Pandas Practice Problems

#### Problem 18: Clean and Transform Data
Given a messy DataFrame:

```python
import pandas as pd

df = pd.DataFrame({
    'name': ['  John  ', 'JANE', 'bob', None],
    'age': ['25', '30', 'invalid', '35'],
    'salary': [50000, None, 60000, 55000]
})
```

**Task**: Clean and transform the data.

<details>
<summary>Solution</summary>

```python
def clean_data(df):
    # Copy to avoid modifying original
    df = df.copy()
    
    # Clean name: strip, title case, handle nulls
    df['name'] = df['name'].str.strip().str.title().fillna('Unknown')
    
    # Convert age to numeric, coerce errors
    df['age'] = pd.to_numeric(df['age'], errors='coerce')
    
    # Fill missing salary with median
    df['salary'] = df['salary'].fillna(df['salary'].median())
    
    # Fill missing age with median
    df['age'] = df['age'].fillna(df['age'].median())
    
    return df
```
</details>

---

#### Problem 19: Pivot and Aggregate
Given a sales DataFrame:

```python
df = pd.DataFrame({
    'date': ['2024-01-01', '2024-01-01', '2024-01-02', '2024-01-02'],
    'product': ['A', 'B', 'A', 'B'],
    'region': ['North', 'North', 'South', 'South'],
    'sales': [100, 150, 200, 250]
})
```

**Task**: Create a pivot table showing total sales by product and region.

<details>
<summary>Solution</summary>

```python
# Pivot table
pivot = pd.pivot_table(
    df, 
    values='sales', 
    index='product', 
    columns='region', 
    aggfunc='sum',
    fill_value=0,
    margins=True,
    margins_name='Total'
)

# Multiple aggregations
pivot_multi = pd.pivot_table(
    df,
    values='sales',
    index='product',
    columns='region',
    aggfunc=['sum', 'mean', 'count']
)
```
</details>

---

## PySpark Practice Problems

#### Problem 20: Window Functions
Given a PySpark DataFrame with employee salaries:

```python
from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from pyspark.sql.window import Window

spark = SparkSession.builder.appName("Practice").getOrCreate()

data = [
    (1, "John", "IT", 50000),
    (2, "Jane", "IT", 60000),
    (3, "Bob", "HR", 45000),
    (4, "Alice", "HR", 55000),
    (5, "Charlie", "IT", 55000)
]
df = spark.createDataFrame(data, ["id", "name", "dept", "salary"])
```

**Task**: 
1. Rank employees by salary within each department
2. Calculate running total of salaries
3. Compare each employee's salary to department average

<details>
<summary>Solution</summary>

```python
from pyspark.sql.window import Window
from pyspark.sql.functions import *

# Window definitions
dept_window = Window.partitionBy("dept").orderBy(col("salary").desc())
running_window = Window.partitionBy("dept").orderBy("id").rowsBetween(Window.unboundedPreceding, Window.currentRow)
dept_avg_window = Window.partitionBy("dept")

result = df.select(
    "*",
    # Rank within department
    row_number().over(dept_window).alias("dept_rank"),
    dense_rank().over(dept_window).alias("dept_dense_rank"),
    
    # Running total within department
    sum("salary").over(running_window).alias("running_total"),
    
    # Compare to department average
    avg("salary").over(dept_avg_window).alias("dept_avg"),
    (col("salary") - avg("salary").over(dept_avg_window)).alias("diff_from_avg"),
    
    # Percent of department total
    round(col("salary") / sum("salary").over(dept_avg_window) * 100, 2).alias("pct_of_dept")
)

result.show()
```
</details>

---

#### Problem 21: Complex Aggregation
**Task**: Calculate RFM (Recency, Frequency, Monetary) scores for customers.

```python
from datetime import datetime

orders_data = [
    (1, "C001", "2024-01-15", 100),
    (2, "C001", "2024-02-20", 150),
    (3, "C002", "2024-01-10", 200),
    (4, "C002", "2024-03-01", 300),
    (5, "C003", "2024-02-15", 50),
]
orders = spark.createDataFrame(orders_data, ["order_id", "customer_id", "order_date", "amount"])
orders = orders.withColumn("order_date", to_date(col("order_date")))
```

<details>
<summary>Solution</summary>

```python
from pyspark.sql.functions import *

# Current date for recency calculation
current_date = lit("2024-03-15")

# Calculate RFM metrics
rfm = orders.groupBy("customer_id").agg(
    datediff(to_date(current_date), max("order_date")).alias("recency"),
    count("order_id").alias("frequency"),
    sum("amount").alias("monetary")
)

# Calculate RFM scores (1-5) using NTILE
from pyspark.sql.window import Window

rfm_scored = rfm.select(
    "*",
    ntile(5).over(Window.orderBy(col("recency").desc())).alias("r_score"),
    ntile(5).over(Window.orderBy("frequency")).alias("f_score"),
    ntile(5).over(Window.orderBy("monetary")).alias("m_score")
).withColumn(
    "rfm_score", col("r_score") + col("f_score") + col("m_score")
).withColumn(
    "segment",
    when(col("rfm_score") >= 12, "Champions")
    .when(col("rfm_score") >= 9, "Loyal")
    .when(col("rfm_score") >= 6, "Potential")
    .otherwise("At Risk")
)

rfm_scored.show()
```
</details>

---

#### Problem 22: Data Quality Checks
**Task**: Implement data quality validation for a DataFrame.

<details>
<summary>Solution</summary>

```python
from pyspark.sql.functions import *

def validate_dataframe(df, rules):
    """
    Validate DataFrame against quality rules.
    Returns validation report.
    """
    results = []
    total_rows = df.count()
    
    for rule in rules:
        column = rule['column']
        check = rule['check']
        
        if check == 'not_null':
            failed = df.filter(col(column).isNull()).count()
        elif check == 'positive':
            failed = df.filter(col(column) <= 0).count()
        elif check == 'unique':
            duplicates = df.groupBy(column).count().filter(col("count") > 1)
            failed = duplicates.select(sum("count") - count("*")).first()[0] or 0
        elif check == 'in_list':
            valid_values = rule['values']
            failed = df.filter(~col(column).isin(valid_values)).count()
        else:
            failed = 0
        
        pass_rate = ((total_rows - failed) / total_rows * 100) if total_rows > 0 else 0
        
        results.append({
            'column': column,
            'check': check,
            'total': total_rows,
            'passed': total_rows - failed,
            'failed': failed,
            'pass_rate': round(pass_rate, 2)
        })
    
    return results

# Usage
rules = [
    {'column': 'name', 'check': 'not_null'},
    {'column': 'salary', 'check': 'positive'},
    {'column': 'dept', 'check': 'in_list', 'values': ['IT', 'HR', 'Finance']}
]

validation_results = validate_dataframe(df, rules)
for result in validation_results:
    print(f"{result['column']}.{result['check']}: {result['pass_rate']}% passed")
```
</details>

---

## Bonus: System Design Problems

### Problem 23: Design a Data Pipeline
**Scenario**: You need to process 1TB of daily log files and make them queryable within 1 hour.

<details>
<summary>Solution Outline</summary>

```
Architecture:
1. INGESTION
   - Source: S3/ADLS (log files in JSON/Parquet)
   - Trigger: Event-based (new file arrival) or scheduled

2. PROCESSING
   - Spark on Databricks/EMR/Synapse
   - Parallel processing with appropriate partitioning
   - Transformations: parse, validate, enrich

3. STORAGE
   - Delta Lake for reliability
   - Partition by date for efficient queries
   - Z-ORDER by common query columns

4. SERVING
   - Synapse Serverless or Databricks SQL
   - Materialized views for common queries

Key Decisions:
- Partition: 200 partitions for 1TB (~5GB each)
- File format: Parquet with snappy compression
- Incremental: Process only new files
- Monitoring: Row counts, latency, error rates

SLA Consideration:
- 1TB / 1 hour = ~17GB/minute
- Need sufficient cluster size
- Consider auto-scaling
```
</details>

---

### Problem 24: Design Real-time Fraud Detection
**Scenario**: Detect fraudulent transactions in real-time (< 100ms latency).

<details>
<summary>Solution Outline</summary>

```
Architecture:
1. INGESTION
   - Kafka/Event Hubs for high throughput
   - Schema registry for data contracts

2. STREAM PROCESSING
   - Spark Structured Streaming or Flink
   - Feature enrichment from Redis (customer history)
   - ML model scoring (pre-trained, loaded in memory)

3. DECISION ENGINE
   - Rules engine for known patterns
   - ML model for anomaly detection
   - Threshold-based decisions

4. OUTPUT
   - Approved: Continue to payment processor
   - Suspicious: Human review queue
   - Blocked: Reject + alert

Latency Optimization:
- Keep model in memory (don't load per request)
- Pre-compute features (customer avg transaction)
- Use broadcast joins for reference data
- Minimize shuffles in streaming

Fallback:
- If system fails, default to rules-only
- If latency exceeds SLA, approve with flag for review
```
</details>

---

## Practice Tips

### For SQL
1. Practice on LeetCode, HackerRank, or StrataScratch
2. Focus on window functions - they're heavily tested
3. Master CTEs for readable complex queries
4. Always consider edge cases (nulls, duplicates)

### For Python
1. Know your data structures' time complexity
2. Practice pandas operations until they're automatic
3. Understand generators for memory efficiency
4. Write clean, readable code (it matters in interviews)

### For PySpark
1. Understand when to use transformations vs actions
2. Practice window functions (same concepts as SQL)
3. Know how to optimize (broadcast, partition, cache)
4. Be comfortable with both DataFrame and SQL APIs

---

**Good luck with your practice! 🚀**

Remember: Consistent practice beats cramming. Solve one problem per day for better retention.
