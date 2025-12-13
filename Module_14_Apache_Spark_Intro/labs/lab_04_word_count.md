# Lab 04: Word Count - The Hello World of Spark

## Overview
Implement the classic Word Count example - the "Hello World" of distributed computing - using multiple Spark approaches.

**Duration**: 2-3 hours  
**Difficulty**: ⭐⭐ Intermediate

---

## Prerequisites
- Labs 01-03 completed
- Understanding of RDDs and DataFrames

---

## Learning Objectives
- ✅ Implement Word Count using RDDs
- ✅ Implement Word Count using DataFrames
- ✅ Implement Word Count using SQL
- ✅ Understand the MapReduce paradigm
- ✅ Compare different approaches

---

## Part 1: Create Sample Text Data

```python
"""
word_count.py
Word Count - The Hello World of Spark
"""

from pyspark.sql import SparkSession
from pyspark.sql.functions import *

# Create SparkSession
spark = SparkSession.builder \
    .appName("Word Count") \
    .master("local[*]") \
    .getOrCreate()

sc = spark.sparkContext
sc.setLogLevel("WARN")

# Create sample text file
sample_text = """Apache Spark is a unified analytics engine for large scale data processing
Spark provides high level APIs in Java Scala Python and R
Spark also supports a rich set of higher level tools including Spark SQL for SQL
Spark Streaming for stream processing MLlib for machine learning and GraphX for graph processing
The main abstraction Spark provides is a resilient distributed dataset RDD
RDD is a collection of elements partitioned across the nodes of the cluster
Spark can be run on Hadoop YARN Mesos or standalone mode
Spark is up to 100 times faster than Hadoop MapReduce in memory
Spark is designed to be highly accessible offering simple APIs in Python Java Scala and SQL
Spark is fast and general purpose cluster computing system"""

with open("sample_text.txt", "w") as f:
    f.write(sample_text)

print("Sample text file created!")
print(f"Content preview:\n{sample_text[:200]}...")
```

---

## Part 2: Word Count with RDDs

### Step 2.1: The Classic MapReduce Approach
```python
print("\n" + "="*60)
print("WORD COUNT WITH RDDs")
print("="*60)

# Step 1: Read text file into RDD
text_rdd = sc.textFile("sample_text.txt")
print(f"\nLines in file: {text_rdd.count()}")

# Step 2: Split lines into words (flatMap)
words_rdd = text_rdd.flatMap(lambda line: line.lower().split())
print(f"Total words: {words_rdd.count()}")

# Step 3: Map each word to (word, 1)
word_pairs_rdd = words_rdd.map(lambda word: (word, 1))
print(f"Sample pairs: {word_pairs_rdd.take(5)}")

# Step 4: Reduce by key (sum counts)
word_counts_rdd = word_pairs_rdd.reduceByKey(lambda a, b: a + b)

# Step 5: Sort by count (descending)
sorted_counts = word_counts_rdd.sortBy(lambda x: x[1], ascending=False)

# Display results
print("\nTop 10 words (RDD approach):")
for word, count in sorted_counts.take(10):
    print(f"  {word}: {count}")
```

### Step 2.2: One-Liner Version
```python
# Compact one-liner (same result)
print("\n--- One-liner approach ---")
result = sc.textFile("sample_text.txt") \
    .flatMap(lambda line: line.lower().split()) \
    .map(lambda word: (word, 1)) \
    .reduceByKey(lambda a, b: a + b) \
    .sortBy(lambda x: x[1], ascending=False)

print("Top 10 words:")
for word, count in result.take(10):
    print(f"  {word}: {count}")
```

### Step 2.3: Understanding the Flow
```
┌─────────────────────────────────────────────────────────────┐
│                    WORD COUNT PIPELINE                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   INPUT: "Spark is fast and Spark is great"                 │
│                                                              │
│   flatMap(split) → ["spark", "is", "fast", "and",           │
│                     "spark", "is", "great"]                  │
│                                                              │
│   map(x → (x,1)) → [("spark",1), ("is",1), ("fast",1),      │
│                     ("and",1), ("spark",1), ("is",1),        │
│                     ("great",1)]                             │
│                                                              │
│   reduceByKey(+) → [("spark",2), ("is",2), ("fast",1),      │
│                     ("and",1), ("great",1)]                  │
│                                                              │
│   sortBy(desc)   → [("spark",2), ("is",2), ("and",1),       │
│                     ("fast",1), ("great",1)]                 │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Part 3: Word Count with DataFrames

### Step 3.1: DataFrame Approach
```python
print("\n" + "="*60)
print("WORD COUNT WITH DATAFRAMES")
print("="*60)

# Read text file as DataFrame
df = spark.read.text("sample_text.txt")
print("\nOriginal DataFrame:")
df.show(5, truncate=False)

# Split lines into words using explode
words_df = df.select(
    explode(split(lower(col("value")), " ")).alias("word")
)
print("\nWords DataFrame:")
words_df.show(10)

# Count words
word_counts_df = words_df \
    .groupBy("word") \
    .count() \
    .orderBy(col("count").desc())

print("\nTop 10 words (DataFrame approach):")
word_counts_df.show(10)
```

### Step 3.2: Filtering Common Words (Stop Words)
```python
# Define stop words
stop_words = ["a", "an", "the", "is", "are", "was", "were", "be", "been",
              "and", "or", "in", "on", "at", "to", "for", "of", "with",
              "as", "it", "that", "this", "can", "also", "up"]

# Filter out stop words
filtered_counts = words_df \
    .filter(~col("word").isin(stop_words)) \
    .filter(length(col("word")) > 2) \
    .groupBy("word") \
    .count() \
    .orderBy(col("count").desc())

print("\nTop 10 meaningful words (filtered):")
filtered_counts.show(10)
```

---

## Part 4: Word Count with SQL

### Step 4.1: SQL Approach
```python
print("\n" + "="*60)
print("WORD COUNT WITH SQL")
print("="*60)

# Create temp view
words_df.createOrReplaceTempView("words")

# SQL query
sql_result = spark.sql("""
    SELECT word, COUNT(*) as count
    FROM words
    WHERE LENGTH(word) > 2
    GROUP BY word
    ORDER BY count DESC
    LIMIT 10
""")

print("\nTop 10 words (SQL approach):")
sql_result.show()
```

### Step 4.2: Advanced SQL Analysis
```python
# Word length statistics
spark.sql("""
    SELECT 
        LENGTH(word) as word_length,
        COUNT(*) as word_count,
        COLLECT_LIST(word) as sample_words
    FROM words
    WHERE LENGTH(word) > 0
    GROUP BY LENGTH(word)
    ORDER BY word_length
""").show(truncate=False)

# Words starting with specific letter
spark.sql("""
    SELECT 
        UPPER(SUBSTRING(word, 1, 1)) as first_letter,
        COUNT(*) as count
    FROM words
    WHERE LENGTH(word) > 0
    GROUP BY SUBSTRING(word, 1, 1)
    ORDER BY count DESC
""").show()
```

---

## Part 5: Performance Comparison

### Step 5.1: Timing Different Approaches
```python
import time

# Create larger dataset
large_text = sample_text * 1000  # Repeat 1000 times
with open("large_text.txt", "w") as f:
    f.write(large_text)

print("\n" + "="*60)
print("PERFORMANCE COMPARISON")
print("="*60)

# RDD approach timing
start = time.time()
rdd_result = sc.textFile("large_text.txt") \
    .flatMap(lambda line: line.lower().split()) \
    .map(lambda word: (word, 1)) \
    .reduceByKey(lambda a, b: a + b) \
    .collect()
rdd_time = time.time() - start
print(f"\nRDD approach: {rdd_time:.3f} seconds")

# DataFrame approach timing
start = time.time()
df_result = spark.read.text("large_text.txt") \
    .select(explode(split(lower(col("value")), " ")).alias("word")) \
    .groupBy("word") \
    .count() \
    .collect()
df_time = time.time() - start
print(f"DataFrame approach: {df_time:.3f} seconds")

# SQL approach timing
spark.read.text("large_text.txt") \
    .select(explode(split(lower(col("value")), " ")).alias("word")) \
    .createOrReplaceTempView("large_words")

start = time.time()
sql_result = spark.sql("SELECT word, COUNT(*) FROM large_words GROUP BY word").collect()
sql_time = time.time() - start
print(f"SQL approach: {sql_time:.3f} seconds")

print(f"\nNote: DataFrame/SQL typically faster due to Catalyst optimizer")
```

---

## Part 6: Real-World Enhancements

### Step 6.1: Word Cleaning
```python
from pyspark.sql.functions import regexp_replace, trim

print("\n" + "="*60)
print("ENHANCED WORD COUNT")
print("="*60)

# Read and clean text
cleaned_words = spark.read.text("sample_text.txt") \
    .select(
        explode(
            split(
                regexp_replace(lower(col("value")), "[^a-zA-Z\\s]", ""),
                "\\s+"
            )
        ).alias("word")
    ) \
    .filter(col("word") != "") \
    .filter(length(col("word")) > 2)

print("\nCleaned word counts:")
cleaned_words.groupBy("word").count().orderBy(col("count").desc()).show(10)
```

### Step 6.2: N-gram Analysis
```python
from pyspark.ml.feature import NGram, Tokenizer

# Create DataFrame with text
text_df = spark.createDataFrame([
    (0, sample_text.lower()),
], ["id", "text"])

# Tokenize
tokenizer = Tokenizer(inputCol="text", outputCol="words")
words_data = tokenizer.transform(text_df)

# Generate bigrams (2-word phrases)
ngram = NGram(n=2, inputCol="words", outputCol="ngrams")
ngrams_data = ngram.transform(words_data)

# Count bigrams
bigrams_df = ngrams_data.select(explode(col("ngrams")).alias("bigram")) \
    .groupBy("bigram") \
    .count() \
    .orderBy(col("count").desc())

print("\nTop 10 Bigrams (2-word phrases):")
bigrams_df.show(10, truncate=False)
```

---

## Part 7: Save Results

### Step 7.1: Save Word Counts
```python
# Save to various formats
word_counts_df.write.mode("overwrite").csv("output/word_counts_csv")
word_counts_df.write.mode("overwrite").parquet("output/word_counts_parquet")
word_counts_df.write.mode("overwrite").json("output/word_counts_json")

print("\nResults saved to output/ directory")
```

---

## Exercises

### Exercise 1: Character Count
Modify the word count to count characters instead:
1. Count occurrences of each letter (a-z)
2. Calculate the percentage of each letter
3. Compare to expected English letter frequency

### Exercise 2: Sentence Analysis
Using the same text:
1. Split into sentences (by period)
2. Count words per sentence
3. Find the longest and shortest sentences
4. Calculate average sentence length

### Exercise 3: Custom Word Count
1. Read a book from Project Gutenberg (download a .txt file)
2. Remove headers and footers
3. Perform word count analysis
4. Create a word cloud visualization (optional)

### Exercise 4: Parallel Processing
1. Create multiple text files (file1.txt, file2.txt, ...)
2. Process all files using wildcard: `sc.textFile("*.txt")`
3. Compare processing time vs single file
4. Analyze word counts across all files

---

## Cleanup
```python
import shutil
import os

# Remove temporary files
for f in ["sample_text.txt", "large_text.txt"]:
    if os.path.exists(f):
        os.remove(f)

if os.path.exists("output"):
    shutil.rmtree("output")

spark.stop()
print("\nCleanup complete. Spark session stopped.")
```

---

## Summary

In this lab, you learned:
- ✅ The classic MapReduce word count pattern
- ✅ Implementing word count with RDDs
- ✅ Implementing word count with DataFrames
- ✅ Implementing word count with SQL
- ✅ Performance comparison between approaches
- ✅ Real-world enhancements (cleaning, n-grams)
- ✅ Saving results to files

**Key Takeaway**: DataFrames/SQL are typically preferred due to:
- Automatic optimization (Catalyst)
- Better performance (Tungsten)
- More readable code
- Easier debugging

**Next Module**: Module 15 - PySpark Fundamentals
