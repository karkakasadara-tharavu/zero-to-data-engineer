# Quiz 02: Advanced Pandas

**Module**: 12 - Data Processing with Pandas  
**Duration**: 50 minutes  
**Total Points**: 25  
**Passing Score**: 70% (18/25)

---

## Section 1: Transformation and Aggregation (7 points)

### Question 1 (2 points)
What is the difference between `apply()` and `transform()` in GroupBy operations?

A) `apply()` returns a DataFrame, `transform()` returns a Series  
B) `apply()` can change shape, `transform()` must preserve shape  
C) They are identical  
D) `transform()` is faster but less flexible

**Answer**: B  
**Explanation**: `transform()` must return a result with the same shape as the input (same index), while `apply()` can return aggregated results that change the shape.

---

### Question 2 (2 points)
Given `df.groupby('category')['sales'].agg(['sum', 'mean', 'count'])`, what is returned?

A) A Series with three values  
B) A DataFrame with three columns  
C) Three separate DataFrames  
D) A MultiIndex Series

**Answer**: B  
**Explanation**: Using `agg()` with a list returns a DataFrame where each function becomes a column.

---

### Question 3 (1 point)
Which method creates a pivot table?

A) `df.pivot()`  
B) `df.pivot_table()`  
C) `df.crosstab()`  
D) Both A and B

**Answer**: D  
**Explanation**: Both `pivot()` and `pivot_table()` create pivot tables, but `pivot_table()` can handle duplicate entries and supports aggregation functions.

---

### Question 4 (2 points)
What does `df['price'].rolling(window=7).mean()` calculate?

A) Mean of every 7th value  
B) Mean of 7 random values  
C) Moving average using a 7-period window  
D) Mean of values greater than 7

**Answer**: C  
**Explanation**: `rolling()` creates a sliding window that calculates the mean over the previous 7 values for each position.

---

## Section 2: Merging and Joining (6 points)

### Question 5 (2 points)
What is the difference between `merge()` and `join()`?

A) `merge()` uses columns by default, `join()` uses index by default  
B) `join()` is faster  
C) They are identical  
D) `merge()` only supports inner joins

**Answer**: A  
**Explanation**: `merge()` typically joins on columns using the `on` parameter, while `join()` defaults to joining on the index.

---

### Question 6 (2 points)
Given two DataFrames merged with `how='outer'`, what happens to unmatched rows?

A) They are dropped  
B) They are included with NaN for missing values  
C) An error is raised  
D) They are filled with zeros

**Answer**: B  
**Explanation**: Outer join includes all rows from both DataFrames, filling NaN where data doesn't match.

---

### Question 7 (2 points)
Which parameter in `merge()` helps identify the source of each row after merging?

A) `validate`  
B) `indicator`  
C) `suffixes`  
D) `source`

**Answer**: B  
**Explanation**: `indicator=True` adds a `_merge` column showing whether each row came from 'left_only', 'right_only', or 'both'.

---

## Section 3: Time Series (5 points)

### Question 8 (2 points)
What does `df.resample('M').sum()` do?

A) Samples random rows monthly  
B) Resamples time series to monthly frequency, summing values  
C) Removes monthly data  
D) Creates monthly predictions

**Answer**: B  
**Explanation**: `resample('M')` groups data by month, and `sum()` aggregates by summing values in each group.

---

### Question 9 (1 point)
Which method creates a range of business days (excluding weekends)?

A) `pd.date_range(freq='B')`  
B) `pd.bdate_range()`  
C) Both A and B  
D) `pd.business_days()`

**Answer**: C  
**Explanation**: Both `date_range(freq='B')` and `bdate_range()` generate business day ranges, excluding weekends.

---

### Question 10 (2 points)
Given a DataFrame with DatetimeIndex, how do you select all data from January 2024?

A) `df['2024-01']`  
B) `df.loc['2024-01']`  
C) Both A and B  
D) `df[df.index.month == 1]`

**Answer**: C  
**Explanation**: Pandas supports partial string indexing for datetime indices, so both methods work.

---

## Section 4: Performance Optimization (5 points)

### Question 11 (2 points)
Which data type is most memory-efficient for a column with 100,000 rows and 5 unique values?

A) `object`  
B) `string`  
C) `category`  
D) `int64`

**Answer**: C  
**Explanation**: Categorical dtype stores data as integers referencing unique categories, dramatically reducing memory for low-cardinality data.

---

### Question 12 (1 point)
What does `pd.to_numeric(df['col'], downcast='integer')` do?

A) Converts to the smallest integer type that can hold the values  
B) Converts to int8 always  
C) Rounds down all numbers  
D) Removes decimal places

**Answer**: A  
**Explanation**: `downcast='integer'` automatically selects the smallest integer dtype (int8, int16, int32, or int64) that can represent the data.

---

### Question 13 (2 points)
Which operation is fastest for element-wise calculations?

A) `for` loop with iterrows()  
B) `apply()` function  
C) Vectorized NumPy operations  
D) List comprehension

**Answer**: C  
**Explanation**: Vectorized operations using NumPy are implemented in C and avoid Python loops, making them significantly faster.

---

## Section 5: Advanced Features (2 points)

### Question 14 (1 point)
What is a MultiIndex?

A) Multiple columns used as a single index  
B) Hierarchical indexing with multiple levels  
C) An index with multiple data types  
D) Multiple DataFrames with the same index

**Answer**: B  
**Explanation**: MultiIndex provides hierarchical indexing, allowing multiple index levels for more complex data structures.

---

### Question 15 (1 point)
Which method converts a MultiIndex DataFrame to a regular DataFrame?

A) `df.reset_index()`  
B) `df.unstack()`  
C) `df.flatten()`  
D) Both A and B

**Answer**: D  
**Explanation**: Both `reset_index()` (converts index levels to columns) and `unstack()` (pivots inner index to columns) can flatten a MultiIndex.

---

## Coding Questions

### Question 16 (3 points)
Write code to perform the following on `sales_df`:
1. Group by 'category'
2. Calculate sum, mean, and count of 'revenue'
3. Sort by sum in descending order

**Solution**:
```python
result = (sales_df
          .groupby('category')['revenue']
          .agg(['sum', 'mean', 'count'])
          .sort_values('sum', ascending=False))
```

**Grading**:
- 1 point: Correct groupby and aggregation
- 1 point: Correct functions (sum, mean, count)
- 1 point: Correct sorting

---

### Question 17 (4 points)
Given DataFrames `customers` and `orders`, write code to:
1. Perform a left join on 'customer_id'
2. Filter for orders > $1000
3. Add a column showing order count per customer
4. Sort by order count descending

**Solution**:
```python
merged = customers.merge(orders, on='customer_id', how='left')
high_value = merged[merged['order_amount'] > 1000]
high_value['order_count'] = high_value.groupby('customer_id')['order_id'].transform('count')
result = high_value.sort_values('order_count', ascending=False)
```

**Grading**:
- 1 point: Correct merge
- 1 point: Correct filtering
- 1 point: Correct order count calculation
- 1 point: Correct sorting

---

### Question 18 (3 points)
Write code to optimize this DataFrame's memory usage:
- Convert 'category' (10 unique values out of 100,000 rows) to categorical
- Downcast 'age' (values 18-65) to smallest integer
- Convert 'price' (float) to float32

**Solution**:
```python
df['category'] = df['category'].astype('category')
df['age'] = pd.to_numeric(df['age'], downcast='integer')
df['price'] = df['price'].astype('float32')
```

**Grading**:
- 1 point: Categorical conversion
- 1 point: Integer downcasting
- 1 point: Float32 conversion

---

## Short Answer Questions (Write brief explanations)

### Question 19 (2 points)
Explain when you would use `concat()` vs `merge()`.

**Model Answer**:
- Use `concat()` for stacking DataFrames vertically (adding rows) or horizontally (adding columns) when they share the same structure
- Use `merge()` for database-style joins based on key columns when combining DataFrames with related but different data

**Grading**:
- 1 point: Correct concat explanation
- 1 point: Correct merge explanation

---

### Question 20 (1 point)
Why is vectorization faster than loops in Pandas?

**Model Answer**:
Vectorized operations are implemented in C/Cython and operate on entire arrays at once, avoiding Python's interpreted loop overhead. They also leverage CPU optimizations and SIMD instructions.

**Grading**:
- 0.5 points: Mentions C implementation
- 0.5 points: Mentions avoiding Python loop overhead

---

## Scenario-Based Questions

### Question 21 (2 points)
You have a 5GB CSV file. Describe an efficient strategy to analyze it.

**Model Answer**:
1. Use `chunksize` parameter to read in chunks (e.g., 100,000 rows at a time)
2. Process each chunk and accumulate results
3. Alternatively, read only required columns with `usecols`
4. Consider using Dask for parallel processing if available
5. Or convert to Parquet format for faster subsequent reads

**Grading**:
- 1 point: Mentions chunked reading
- 1 point: Mentions alternative approach (columns selection, Parquet, or Dask)

---

## Answer Key Summary

1. B (apply vs transform)
2. B (agg returns DataFrame)
3. D (pivot methods)
4. C (rolling mean)
5. A (merge vs join default behavior)
6. B (outer join with NaN)
7. B (indicator parameter)
8. B (resample monthly sum)
9. C (business day methods)
10. C (datetime string indexing)
11. C (categorical for low cardinality)
12. A (downcast to smallest type)
13. C (vectorized fastest)
14. B (MultiIndex definition)
15. D (reset_index and unstack)
16-21. See detailed solutions above

---

## Scoring Guide

- **23-25 points**: Excellent (90-100%)
- **20-22 points**: Good (80-89%)
- **18-19 points**: Passing (70-79%)
- **Below 18**: Needs Review (<70%)

## Time Management

- Multiple Choice (Q1-15): 25 minutes
- Coding Questions (Q16-18): 15 minutes
- Short Answer/Scenario (Q19-21): 10 minutes

## Key Concepts Tested

- **Aggregation**: GroupBy, pivot tables, window functions
- **Merging**: Join types, indicators, validation
- **Time Series**: Resampling, datetime indexing
- **Performance**: Data types, vectorization, memory
- **Advanced**: MultiIndex, optimization strategies

## Study Tips

1. Practice GroupBy with multiple aggregations
2. Understand all join types (inner, left, right, outer)
3. Master datetime operations and resampling
4. Know data type optimization techniques
5. Compare vectorized vs loop performance
6. Practice reading large files efficiently
7. Understand MultiIndex manipulation

---

**Good luck!**
