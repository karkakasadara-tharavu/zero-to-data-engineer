# Lab 06: Time Series Analysis

## Estimated Time: 90 minutes

## Objectives
- Work with datetime data and DatetimeIndex
- Perform time-based indexing and slicing
- Resample time series data
- Calculate rolling and expanding windows
- Handle time zones and business days

## Prerequisites
- Completed Labs 01-05
- Understanding of time series concepts
- Basic knowledge of datetime operations

## Background

You're analyzing stock prices, weather data, and website traffic patterns. These time series datasets require specialized techniques for resampling, trend analysis, and forecasting.

## Tasks

### Task 1: DateTime Operations (20 min)
- Parse dates from various formats
- Create date ranges with different frequencies
- Extract date components (year, month, day, weekday)
- Handle time zones

### Task 2: Time-Based Indexing (20 min)
- Set DatetimeIndex
- Select by year, month, or date range
- Slice time series efficiently
- Use partial string indexing

### Task 3: Resampling (25 min)
- Downsample: hourly → daily, daily → monthly
- Upsample with fill methods
- Apply aggregations during resampling
- Create OHLC (Open, High, Low, Close) data

### Task 4: Rolling Windows (25 min)
- Calculate moving averages (7-day, 30-day)
- Compute rolling standard deviation
- Calculate percentage changes
- Apply custom rolling functions

## Starter Code

```python
import pandas as pd
import numpy as np
from datetime import datetime, timedelta

def create_time_series_data():
    """Create sample time series datasets"""
    # Stock prices (minute data)
    dates_minute = pd.date_range('2024-01-01 09:30', 
                                 periods=390*5,  # 5 trading days
                                 freq='min')
    stock_data = pd.DataFrame({
        'price': 100 + np.random.randn(len(dates_minute)).cumsum(),
        'volume': np.random.randint(1000, 10000, len(dates_minute))
    }, index=dates_minute)
    
    # Weather data (hourly)
    dates_hourly = pd.date_range('2024-01-01', periods=24*90, freq='H')
    weather_data = pd.DataFrame({
        'temperature': 50 + 20*np.sin(np.arange(len(dates_hourly))*2*np.pi/24) + np.random.randn(len(dates_hourly))*5,
        'humidity': 50 + np.random.randn(len(dates_hourly))*10
    }, index=dates_hourly)
    
    # Website traffic (daily)
    dates_daily = pd.date_range('2024-01-01', periods=365, freq='D')
    traffic_data = pd.DataFrame({
        'visits': np.random.randint(1000, 5000, len(dates_daily)),
        'page_views': np.random.randint(5000, 20000, len(dates_daily))
    }, index=dates_daily)
    
    return stock_data, weather_data, traffic_data

# Task 1: DateTime Operations
def parse_datetime_examples():
    """Examples of parsing dates"""
    # TODO: Parse various formats
    dates = [
        '2024-01-15',
        '15/01/2024',
        'Jan 15, 2024',
        '2024-01-15 10:30:45'
    ]
    
    parsed = [pd.to_datetime(d) for d in dates]
    
    # TODO: Create date ranges
    daily = pd.date_range('2024-01-01', periods=30, freq='D')
    business_days = pd.bdate_range('2024-01-01', periods=20)
    hourly = pd.date_range('2024-01-01', periods=24, freq='H')
    
    # TODO: Extract components
    df = pd.DataFrame({'date': daily})
    df['year'] = df['date'].dt.year
    df['month'] = df['date'].dt.month
    df['day'] = df['date'].dt.day
    df['dayofweek'] = df['date'].dt.dayofweek
    df['quarter'] = df['date'].dt.quarter
    
    return df

# Task 2: Time-Based Indexing
def time_based_selection(ts):
    """Demonstrate time-based selection"""
    # TODO: Select by year
    year_2024 = ts['2024']
    
    # TODO: Select by month
    jan_2024 = ts['2024-01']
    
    # TODO: Select date range
    date_range = ts['2024-01-01':'2024-01-31']
    
    # TODO: Boolean indexing with dates
    weekdays = ts[ts.index.dayofweek < 5]
    
    return {
        'full_year': year_2024,
        'january': jan_2024,
        'range': date_range,
        'weekdays': weekdays
    }

# Task 3: Resampling
def resample_operations(ts):
    """Resample time series"""
    # TODO: Downsample to daily (from hourly)
    daily = ts.resample('D').agg({
        'price': ['mean', 'min', 'max'],
        'volume': 'sum'
    })
    
    # TODO: Create OHLC
    ohlc = ts['price'].resample('D').ohlc()
    
    # TODO: Upsample with fill
    upsampled = ts.resample('30min').ffill()
    
    return daily, ohlc, upsampled

# Task 4: Rolling Windows
def rolling_analysis(ts):
    """Calculate rolling statistics"""
    # TODO: Moving averages
    ts['MA_7'] = ts['price'].rolling(window=7).mean()
    ts['MA_30'] = ts['price'].rolling(window=30).mean()
    
    # TODO: Rolling std
    ts['rolling_std'] = ts['price'].rolling(window=7).std()
    
    # TODO: Percentage change
    ts['pct_change'] = ts['price'].pct_change()
    
    # TODO: Cumulative sum
    ts['cumsum'] = ts['volume'].cumsum()
    
    return ts

def main():
    """Main execution"""
    print("LAB 06: TIME SERIES ANALYSIS")
    stock, weather, traffic = create_time_series_data()
    
    # Demonstrate operations
    print(f"Stock data: {stock.shape}")
    print(f"Weather data: {weather.shape}")
    print(f"Traffic data: {traffic.shape}")
    
    # Resampling
    daily_stock, ohlc, upsampled = resample_operations(stock)
    print("\nDaily OHLC:")
    print(ohlc.head())
    
    # Rolling analysis
    traffic_analyzed = rolling_analysis(traffic)
    print("\nTraffic with rolling metrics:")
    print(traffic_analyzed.tail())

if __name__ == "__main__":
    main()
```

## Deliverables
- Time series processing script
- Resampled datasets
- Rolling window calculations
- Time-based analysis report

## Bonus Challenges
- Business day calendars with holidays
- Timezone conversion for global data
- Seasonal decomposition
- Autocorrelation analysis
- Gap filling with interpolation

## Submission
Submit `lab_06_solution.py` with time series analysis implementations.
