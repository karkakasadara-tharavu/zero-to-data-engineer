# Module 12: Data Processing with Pandas

## Theory Section 07: Time Series Analysis

### Learning Objectives
- Work with datetime data in Pandas
- Create and manipulate time series
- Resample and aggregate time-based data
- Perform time-based indexing and slicing
- Handle time zones and business days

### Introduction to Time Series

A time series is a sequence of data points indexed in time order. Pandas provides powerful tools for time series analysis.

```python
import pandas as pd
import numpy as np
from datetime import datetime, timedelta

# Create sample time series
dates = pd.date_range('2024-01-01', periods=100, freq='D')
ts = pd.Series(np.random.randn(100), index=dates)
print(ts.head())
# Output:
# 2024-01-01   -0.523456
# 2024-01-02    0.987234
# 2024-01-03   -1.234567
# ...
```

### DateTime Objects

```python
# Creating datetime objects
from datetime import datetime

dt = datetime(2024, 1, 15, 10, 30, 45)
print(dt)  # 2024-01-15 10:30:45

# Current datetime
now = datetime.now()
today = datetime.today()

# Parse string to datetime
dt = datetime.strptime('2024-01-15', '%Y-%m-%d')
```

### Pandas Timestamp

```python
# Pandas Timestamp (wrapper around datetime)
ts = pd.Timestamp('2024-01-15')
print(ts)  # 2024-01-15 00:00:00

# With time
ts = pd.Timestamp('2024-01-15 10:30:45')

# From datetime
ts = pd.Timestamp(datetime.now())

# Timestamp attributes
ts = pd.Timestamp('2024-03-15 10:30:45')
print(ts.year)        # 2024
print(ts.month)       # 3
print(ts.day)         # 15
print(ts.hour)        # 10
print(ts.dayofweek)   # 4 (Friday, 0=Monday)
print(ts.dayofyear)   # 75
print(ts.quarter)     # 1
print(ts.is_leap_year)  # True
```

### Creating Date Ranges

```python
# date_range - fixed frequency dates
dates = pd.date_range('2024-01-01', periods=10)
# Daily by default

dates = pd.date_range('2024-01-01', '2024-01-10')
# All days between start and end

dates = pd.date_range('2024-01-01', periods=12, freq='M')
# Month end dates

dates = pd.date_range('2024-01-01', periods=10, freq='H')
# Hourly

dates = pd.date_range('2024-01-01', periods=10, freq='15T')
# Every 15 minutes

# Common frequencies
# D - calendar day
# B - business day
# W - weekly
# M - month end
# MS - month start
# Q - quarter end
# QS - quarter start
# Y - year end
# YS - year start
# H - hourly
# T or min - minutely
# S - secondly
```

### Business Days

```python
# Business days only (excludes weekends)
bdays = pd.bdate_range('2024-01-01', periods=10)

# Custom business days
from pandas.tseries.offsets import CustomBusinessDay
cbd = CustomBusinessDay(weekmask='Mon Tue Wed Thu Fri')
dates = pd.date_range('2024-01-01', periods=10, freq=cbd)

# Exclude holidays
from pandas.tseries.holiday import USFederalHolidayCalendar
cal = USFederalHolidayCalendar()
cbd = CustomBusinessDay(calendar=cal)
```

### DatetimeIndex

```python
# Create Series with DatetimeIndex
dates = pd.date_range('2024-01-01', periods=100)
values = np.random.randn(100)
ts = pd.Series(values, index=dates)

# Check index type
print(type(ts.index))  # DatetimeIndex

# DatetimeIndex attributes
print(ts.index.year)
print(ts.index.month)
print(ts.index.day)
print(ts.index.dayofweek)
print(ts.index.weekday)  # Same as dayofweek
print(ts.index.quarter)
```

### Parsing Dates

```python
# Parse dates from strings
df = pd.DataFrame({
    'date_str': ['2024-01-15', '2024-02-20', '2024-03-25'],
    'value': [100, 200, 300]
})

# Convert column to datetime
df['date'] = pd.to_datetime(df['date_str'])
print(df['date'].dtype)  # datetime64[ns]

# Parse with format
df['date'] = pd.to_datetime(df['date_str'], format='%Y-%m-%d')

# Handle errors
df['date'] = pd.to_datetime(df['date_str'], errors='coerce')  # NaT for invalid
df['date'] = pd.to_datetime(df['date_str'], errors='ignore')  # Keep original

# Parse multiple formats
dates = ['2024-01-15', '15/02/2024', '03-25-2024']
df = pd.DataFrame({'date_str': dates})
df['date'] = pd.to_datetime(df['date_str'], infer_datetime_format=True)
```

### Reading Files with Dates

```python
# Parse dates while reading CSV
df = pd.read_csv('data.csv', parse_dates=['date_column'])

# Multiple date columns
df = pd.read_csv('data.csv', parse_dates=['start_date', 'end_date'])

# Combine columns into one date
df = pd.read_csv('data.csv', 
                 parse_dates={'datetime': ['date', 'time']})

# Set date column as index
df = pd.read_csv('data.csv', 
                 parse_dates=['date'],
                 index_col='date')
```

### Time-Based Indexing

```python
# Create time series
dates = pd.date_range('2024-01-01', periods=365, freq='D')
ts = pd.Series(np.random.randn(365), index=dates)

# Select by year
ts['2024']

# Select by year-month
ts['2024-03']

# Select range
ts['2024-03-01':'2024-03-31']

# Select by exact timestamp
ts['2024-03-15']

# Boolean indexing
ts[ts.index.month == 3]  # All March data
ts[ts.index.dayofweek < 5]  # Weekdays only
ts[ts.index.quarter == 1]  # First quarter
```

### Truncating and Selecting

```python
# Truncate to date range
ts.truncate(before='2024-03-01', after='2024-06-30')

# First/last N periods
ts.first('3M')  # First 3 months
ts.last('2W')   # Last 2 weeks

# At specific time
ts.at_time('10:30')  # All rows at 10:30

# Between times
ts.between_time('09:00', '17:00')  # Business hours
```

### Resampling

Resampling changes the frequency of time series data.

#### Downsampling (Higher to Lower Frequency)

```python
# Create hourly data
dates = pd.date_range('2024-01-01', periods=24*7, freq='H')
ts = pd.Series(np.random.randn(24*7), index=dates)

# Resample to daily (mean)
daily = ts.resample('D').mean()

# Other aggregations
daily_sum = ts.resample('D').sum()
daily_max = ts.resample('D').max()
daily_min = ts.resample('D').min()
daily_count = ts.resample('D').count()

# Multiple aggregations
daily_stats = ts.resample('D').agg(['mean', 'std', 'min', 'max'])

# Custom aggregation
daily_range = ts.resample('D').apply(lambda x: x.max() - x.min())
```

#### Upsampling (Lower to Higher Frequency)

```python
# Create daily data
dates = pd.date_range('2024-01-01', periods=30, freq='D')
ts = pd.Series(np.random.randn(30), index=dates)

# Upsample to hourly
hourly = ts.resample('H').asfreq()  # Creates NaN for missing

# Forward fill
hourly = ts.resample('H').ffill()

# Backward fill
hourly = ts.resample('H').bfill()

# Interpolate
hourly = ts.resample('H').interpolate()
```

#### OHLC Data (Open, High, Low, Close)

```python
# Stock price data
dates = pd.date_range('2024-01-01', periods=100, freq='T')
prices = pd.Series(100 + np.random.randn(100).cumsum(), index=dates)

# Resample to 5-minute OHLC
ohlc = prices.resample('5T').ohlc()
print(ohlc)
# Output:
#                      open   high    low  close
# 2024-01-01 00:00:00  100.0  102.3  99.5  101.2
# 2024-01-01 00:05:00  101.2  103.1  100.8  102.5
# ...
```

### Rolling Windows

```python
# Create time series
dates = pd.date_range('2024-01-01', periods=100, freq='D')
ts = pd.Series(np.random.randn(100).cumsum(), index=dates)

# Simple moving average
ma_7 = ts.rolling(window=7).mean()
ma_30 = ts.rolling(window=30).mean()

# Other rolling operations
roll_sum = ts.rolling(window=7).sum()
roll_std = ts.rolling(window=7).std()
roll_max = ts.rolling(window=7).max()
roll_min = ts.rolling(window=7).min()

# Rolling with minimum periods
ma = ts.rolling(window=7, min_periods=1).mean()

# Center the window
ma_centered = ts.rolling(window=7, center=True).mean()
```

### Expanding Windows

```python
# Cumulative statistics from start
expanding_mean = ts.expanding().mean()
expanding_sum = ts.expanding().sum()
expanding_std = ts.expanding().std()

# With minimum periods
expanding = ts.expanding(min_periods=10).mean()
```

### Exponentially Weighted Moving Average

```python
# EWMA - gives more weight to recent observations
ewma = ts.ewm(span=20).mean()

# With half-life
ewma = ts.ewm(halflife=10).mean()

# Adjust parameter
ewma = ts.ewm(span=20, adjust=False).mean()
```

### Shifting and Lagging

```python
# Shift forward (lag)
ts_lag1 = ts.shift(1)   # Previous day
ts_lag7 = ts.shift(7)   # 7 days ago

# Shift backward (lead)
ts_lead1 = ts.shift(-1)  # Next day

# Shift with frequency
ts_shifted = ts.shift(periods=2, freq='D')  # Shift index by 2 days

# Calculate returns
returns = ts / ts.shift(1) - 1

# Calculate differences
diff = ts.diff()         # ts - ts.shift(1)
diff2 = ts.diff(2)       # ts - ts.shift(2)

# Percentage change
pct_change = ts.pct_change()
```

### Time Zones

```python
# Create timezone-aware timestamp
ts = pd.Timestamp('2024-01-15 10:30', tz='US/Eastern')
print(ts)

# Create timezone-aware date range
dates = pd.date_range('2024-01-01', periods=10, tz='UTC')

# Localize timezone-naive to timezone-aware
dates_naive = pd.date_range('2024-01-01', periods=10)
dates_aware = dates_naive.tz_localize('US/Eastern')

# Convert between timezones
dates_utc = dates_aware.tz_convert('UTC')
dates_tokyo = dates_aware.tz_convert('Asia/Tokyo')

# Remove timezone
dates_naive = dates_aware.tz_localize(None)
```

### Period Objects

```python
# Period represents a time span
p = pd.Period('2024-01')  # January 2024
print(p)  # 2024-01

# Period arithmetic
p + 1  # 2024-02
p - 2  # 2023-11

# Create period range
periods = pd.period_range('2024-01', periods=12, freq='M')

# Convert to timestamp
periods.to_timestamp()

# Convert timestamp to period
dates = pd.date_range('2024-01-01', periods=12, freq='M')
periods = dates.to_period('M')
```

### Timedelta

```python
# Timedelta represents duration
td = pd.Timedelta('1 day')
td = pd.Timedelta(days=1)
td = pd.Timedelta(hours=24)

# Arithmetic with dates
date = pd.Timestamp('2024-01-15')
next_week = date + pd.Timedelta(weeks=1)
yesterday = date - pd.Timedelta(days=1)

# Timedelta in Series
dates = pd.date_range('2024-01-01', periods=10)
ts = pd.Series(dates)
ts_plus_week = ts + pd.Timedelta(weeks=1)

# Duration between dates
df = pd.DataFrame({
    'start': pd.date_range('2024-01-01', periods=5),
    'end': pd.date_range('2024-01-10', periods=5)
})
df['duration'] = df['end'] - df['start']
```

### Time Series Offsets

```python
from pandas.tseries.offsets import *

date = pd.Timestamp('2024-01-15')

# Add offsets
date + Day(1)          # Next day
date + BusinessDay(5)  # 5 business days later
date + Week()          # Next week
date + MonthEnd()      # End of month
date + QuarterEnd()    # End of quarter

# Custom business day
cbd = CustomBusinessDay(weekmask='Mon Wed Fri')
date + cbd
```

### Practical Examples

#### Example 1: Stock Price Analysis

```python
# Load stock data
df = pd.DataFrame({
    'date': pd.date_range('2024-01-01', periods=252, freq='B'),
    'price': 100 + np.random.randn(252).cumsum()
})
df = df.set_index('date')

# Calculate returns
df['returns'] = df['price'].pct_change()

# Moving averages
df['ma_20'] = df['price'].rolling(20).mean()
df['ma_50'] = df['price'].rolling(50).mean()

# Volatility (rolling standard deviation)
df['volatility'] = df['returns'].rolling(20).std() * np.sqrt(252)

# Bollinger Bands
df['bb_upper'] = df['ma_20'] + 2 * df['price'].rolling(20).std()
df['bb_lower'] = df['ma_20'] - 2 * df['price'].rolling(20).std()
```

#### Example 2: Sales Analysis by Time Periods

```python
# Load sales data
df = pd.DataFrame({
    'date': pd.date_range('2023-01-01', periods=365, freq='D'),
    'sales': np.random.randint(1000, 5000, 365)
})
df = df.set_index('date')

# Monthly total sales
monthly = df.resample('M').sum()

# Quarterly average
quarterly = df.resample('Q').mean()

# Year-over-year comparison
df['year'] = df.index.year
df['month'] = df.index.month
yearly_comparison = df.pivot_table(values='sales', 
                                   index='month', 
                                   columns='year', 
                                   aggfunc='sum')
```

#### Example 3: Handling Missing Time Series Data

```python
# Create data with gaps
dates = pd.date_range('2024-01-01', periods=100, freq='D')
ts = pd.Series(np.random.randn(100), index=dates)
ts = ts.sample(frac=0.8)  # Remove 20% of data

# Reindex to fill gaps
full_range = pd.date_range(ts.index.min(), ts.index.max(), freq='D')
ts_full = ts.reindex(full_range)

# Fill gaps with interpolation
ts_filled = ts_full.interpolate()

# Or with forward fill
ts_filled = ts_full.ffill()
```

### Summary

- Use `pd.Timestamp` for individual datetime points
- Use `DatetimeIndex` for time series data
- Use `pd.to_datetime()` to parse dates from strings
- Use `resample()` to change frequency
- Use `rolling()` for moving window calculations
- Use `shift()` for lagging/leading
- Handle time zones with `tz_localize()` and `tz_convert()`

### Key Takeaways

1. Pandas has excellent datetime support
2. DatetimeIndex enables time-based indexing
3. Resampling aggregates data to different frequencies
4. Rolling windows calculate moving statistics
5. Use business day calendars for financial data
6. Always be aware of time zones in your data

---

**Practice Exercise:**

1. Create a time series of hourly temperature data for one year
2. Calculate daily average, min, and max temperatures
3. Compute 7-day and 30-day moving averages
4. Find the hottest and coldest weeks
5. Resample to monthly data and identify seasonal patterns
6. Handle missing data with interpolation
