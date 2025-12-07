# Lab 08: Performance Optimization

## Estimated Time: 90 minutes

## Objectives
- Profile memory usage and identify bottlenecks
- Optimize data types for memory efficiency
- Use vectorization instead of loops
- Implement efficient data processing techniques
- Benchmark performance improvements

## Prerequisites
- Completed Labs 01-07
- Understanding of Python performance concepts
- Familiarity with data types

## Background

As datasets grow larger, performance becomes critical. You'll optimize a slow data pipeline, reducing memory usage by 50-90% and improving processing speed by 10-100x through proper techniques.

## Tasks

### Task 1: Memory Profiling (20 min)
- Profile DataFrame memory usage
- Identify memory-heavy columns
- Calculate memory per data type
- Compare before/after optimization

### Task 2: Data Type Optimization (25 min)
- Convert to optimal numeric types
- Use categorical for repeated strings
- Implement sparse data for nulls
- Downcast integers and floats

### Task 3: Vectorization (25 min)
- Replace loops with vectorized operations
- Use NumPy functions
- Apply string vectorization
- Benchmark loop vs vectorized performance

### Task 4: Processing Optimization (20 min)
- Chunked reading for large files
- Efficient filtering techniques
- Query vs boolean indexing
- Parallel processing basics

## Starter Code

```python
import pandas as pd
import numpy as np
import time
from memory_profiler import profile

def create_large_dataset(n_rows=1000000):
    """Create large dataset for optimization"""
    np.random.seed(42)
    
    df = pd.DataFrame({
        'id': range(n_rows),
        'category': np.random.choice(['A', 'B', 'C', 'D', 'E'], n_rows),
        'subcategory': np.random.choice([f'Sub{i}' for i in range(20)], n_rows),
        'value': np.random.randn(n_rows) * 1000,
        'quantity': np.random.randint(1, 100, n_rows),
        'price': np.random.uniform(10, 1000, n_rows),
        'is_active': np.random.choice([True, False], n_rows),
        'rating': np.random.uniform(1, 5, n_rows),
        'date': pd.date_range('2020-01-01', periods=n_rows, freq='min')
    })
    
    # Add some nulls
    df.loc[df.sample(frac=0.1).index, 'rating'] = np.nan
    
    return df

# Task 1: Memory Profiling
def profile_memory(df):
    """Profile DataFrame memory usage"""
    print("MEMORY PROFILING")
    print("=" * 60)
    
    # TODO: Overall memory usage
    total_memory = df.memory_usage(deep=True).sum() / 1024**2
    print(f"Total memory: {total_memory:.2f} MB\n")
    
    # TODO: Per-column memory
    memory_by_column = df.memory_usage(deep=True) / 1024**2
    print("Memory by column:")
    print(memory_by_column.sort_values(ascending=False))
    
    # TODO: Data type summary
    print("\nData types:")
    print(df.dtypes.value_counts())
    
    # TODO: Memory by data type
    memory_by_dtype = df.memory_usage(deep=True).groupby(df.dtypes).sum() / 1024**2
    print("\nMemory by data type:")
    print(memory_by_dtype.sort_values(ascending=False))
    
    return {
        'total_mb': total_memory,
        'by_column': memory_by_column,
        'by_dtype': memory_by_dtype
    }

# Task 2: Data Type Optimization
def optimize_datatypes(df):
    """Optimize DataFrame data types"""
    print("\nDATATYPE OPTIMIZATION")
    print("=" * 60)
    
    df_optimized = df.copy()
    
    # TODO: Optimize integers
    for col in ['id', 'quantity']:
        col_min = df_optimized[col].min()
        col_max = df_optimized[col].max()
        
        if col_min >= 0:
            if col_max < 255:
                df_optimized[col] = df_optimized[col].astype('uint8')
            elif col_max < 65535:
                df_optimized[col] = df_optimized[col].astype('uint16')
            elif col_max < 4294967295:
                df_optimized[col] = df_optimized[col].astype('uint32')
        else:
            if col_min > np.iinfo(np.int8).min and col_max < np.iinfo(np.int8).max:
                df_optimized[col] = df_optimized[col].astype('int8')
            elif col_min > np.iinfo(np.int16).min and col_max < np.iinfo(np.int16).max:
                df_optimized[col] = df_optimized[col].astype('int16')
            elif col_min > np.iinfo(np.int32).min and col_max < np.iinfo(np.int32).max:
                df_optimized[col] = df_optimized[col].astype('int32')
    
    # TODO: Optimize floats
    for col in ['value', 'price', 'rating']:
        df_optimized[col] = df_optimized[col].astype('float32')
    
    # TODO: Convert to categorical
    for col in ['category', 'subcategory']:
        df_optimized[col] = df_optimized[col].astype('category')
    
    # TODO: Optimize boolean
    df_optimized['is_active'] = df_optimized['is_active'].astype('bool')
    
    # Compare memory
    original_memory = df.memory_usage(deep=True).sum() / 1024**2
    optimized_memory = df_optimized.memory_usage(deep=True).sum() / 1024**2
    reduction = (1 - optimized_memory / original_memory) * 100
    
    print(f"Original memory: {original_memory:.2f} MB")
    print(f"Optimized memory: {optimized_memory:.2f} MB")
    print(f"Reduction: {reduction:.1f}%")
    
    return df_optimized

# Task 3: Vectorization
def benchmark_vectorization(df, n_rows=100000):
    """Compare loop vs vectorized operations"""
    print("\nVECTORIZATION BENCHMARK")
    print("=" * 60)
    
    df_sample = df.head(n_rows).copy()
    
    # Method 1: Iterrows (SLOW)
    start = time.time()
    results_loop = []
    for idx, row in df_sample.iterrows():
        if row['quantity'] > 50:
            results_loop.append(row['price'] * row['quantity'] * 1.1)
        else:
            results_loop.append(row['price'] * row['quantity'])
    loop_time = time.time() - start
    
    # Method 2: Apply (MEDIUM)
    start = time.time()
    def calculate_total(row):
        multiplier = 1.1 if row['quantity'] > 50 else 1.0
        return row['price'] * row['quantity'] * multiplier
    results_apply = df_sample.apply(calculate_total, axis=1)
    apply_time = time.time() - start
    
    # Method 3: Vectorized (FAST)
    start = time.time()
    multiplier = np.where(df_sample['quantity'] > 50, 1.1, 1.0)
    results_vectorized = df_sample['price'] * df_sample['quantity'] * multiplier
    vectorized_time = time.time() - start
    
    # Method 4: NumPy (FASTEST)
    start = time.time()
    quantity = df_sample['quantity'].values
    price = df_sample['price'].values
    multiplier = np.where(quantity > 50, 1.1, 1.0)
    results_numpy = price * quantity * multiplier
    numpy_time = time.time() - start
    
    print(f"Loop (iterrows):     {loop_time:.4f}s  (1.0x)")
    print(f"Apply:               {apply_time:.4f}s  ({loop_time/apply_time:.1f}x faster)")
    print(f"Vectorized:          {vectorized_time:.4f}s  ({loop_time/vectorized_time:.1f}x faster)")
    print(f"NumPy:               {numpy_time:.4f}s  ({loop_time/numpy_time:.1f}x faster)")
    
    return {
        'loop': loop_time,
        'apply': apply_time,
        'vectorized': vectorized_time,
        'numpy': numpy_time
    }

# Task 4: Processing Optimization
def optimize_processing(filename='large_data.csv'):
    """Demonstrate efficient processing techniques"""
    print("\nPROCESSING OPTIMIZATION")
    print("=" * 60)
    
    # TODO: Chunked reading
    print("1. Chunked Reading:")
    chunk_size = 100000
    results = []
    
    start = time.time()
    for chunk in pd.read_csv(filename, chunksize=chunk_size):
        # Process each chunk
        filtered = chunk[chunk['quantity'] > 50]
        results.append(filtered['price'].sum())
    chunk_time = time.time() - start
    total = sum(results)
    print(f"   Processed in chunks: {chunk_time:.2f}s")
    print(f"   Total: {total:,.2f}")
    
    # TODO: Efficient filtering
    df = pd.read_csv(filename)
    
    # Method 1: Boolean indexing
    start = time.time()
    filtered1 = df[(df['quantity'] > 50) & (df['price'] > 100)]
    bool_time = time.time() - start
    
    # Method 2: Query
    start = time.time()
    filtered2 = df.query('quantity > 50 and price > 100')
    query_time = time.time() - start
    
    print(f"\n2. Filtering Comparison:")
    print(f"   Boolean indexing: {bool_time:.4f}s")
    print(f"   Query method:     {query_time:.4f}s")
    
    # TODO: Column selection
    start = time.time()
    df_all = pd.read_csv(filename)
    all_cols_time = time.time() - start
    
    start = time.time()
    df_subset = pd.read_csv(filename, usecols=['category', 'price', 'quantity'])
    subset_time = time.time() - start
    
    print(f"\n3. Column Selection:")
    print(f"   All columns:  {all_cols_time:.4f}s")
    print(f"   Subset only:  {subset_time:.4f}s ({all_cols_time/subset_time:.1f}x faster)")
    
    return {
        'chunk_time': chunk_time,
        'bool_time': bool_time,
        'query_time': query_time
    }

def create_optimization_report(df):
    """Generate comprehensive optimization report"""
    print("\n" + "="*60)
    print("OPTIMIZATION REPORT")
    print("="*60)
    
    # Profile original
    original_profile = profile_memory(df)
    
    # Optimize
    df_optimized = optimize_datatypes(df)
    
    # Benchmark
    benchmark_results = benchmark_vectorization(df)
    
    # Summary
    print("\n" + "="*60)
    print("SUMMARY")
    print("="*60)
    print(f"Memory reduction: {(1 - df_optimized.memory_usage(deep=True).sum() / df.memory_usage(deep=True).sum()) * 100:.1f}%")
    print(f"Vectorization speedup: {benchmark_results['loop'] / benchmark_results['numpy']:.1f}x")
    print("\nRecommendations:")
    print("- Always use categorical for low-cardinality strings")
    print("- Downcast numeric types when possible")
    print("- Prefer vectorized operations over loops")
    print("- Use chunked reading for files > 1GB")
    print("- Select only needed columns when reading")

def main():
    """Main execution"""
    print("LAB 08: PERFORMANCE OPTIMIZATION\n")
    
    # Create dataset
    print("Creating large dataset (1M rows)...")
    df = create_large_dataset(1000000)
    
    # Save for chunked reading example
    df.to_csv('large_data.csv', index=False)
    
    # Generate report
    create_optimization_report(df)
    
    print("\nOptimization complete!")

if __name__ == "__main__":
    main()
```

## Deliverables
- Optimized data processing script
- Memory profiling report
- Performance benchmark results
- Before/after comparison

## Bonus Challenges
- Parallel processing with Dask
- GPU acceleration with cuDF
- Memory mapping large files
- Custom Cython functions
- Profile with line_profiler

## Common Pitfalls
- Not using deep=True for memory_usage()
- Converting to categorical with high cardinality
- Using iterrows() instead of vectorization
- Loading entire file when chunking would work
- Not considering nullable dtypes

## Resources
- [Pandas Performance](https://pandas.pydata.org/docs/user_guide/enhancingperf.html)
- [Memory Optimization](https://pandas.pydata.org/docs/user_guide/scale.html)

## Submission
Submit `lab_08_solution.py` with optimization implementations and performance report.
