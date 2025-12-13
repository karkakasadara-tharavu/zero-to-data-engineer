# Lab 01: Apache Spark Installation and Setup

## Overview
In this lab, you'll install Apache Spark and configure your development environment for distributed data processing.

**Duration**: 2-3 hours  
**Difficulty**: ⭐⭐ Intermediate

---

## Prerequisites
- Python 3.11+ installed
- Java JDK 11 or 17 installed
- Basic command line knowledge

---

## Learning Objectives
By the end of this lab, you will be able to:
- ✅ Install Apache Spark on your local machine
- ✅ Configure environment variables
- ✅ Verify Spark installation
- ✅ Launch PySpark interactive shell
- ✅ Run your first Spark program

---

## Part 1: Install Java

### Step 1.1: Check Java Installation
```bash
# Check if Java is installed
java -version

# Expected output: java version "17.x.x" or "11.x.x"
```

### Step 1.2: Install Java (if needed)

**Windows:**
1. Download Java JDK 17 from [Oracle](https://www.oracle.com/java/technologies/downloads/) or [OpenJDK](https://adoptium.net/)
2. Run the installer
3. Set JAVA_HOME environment variable:
   ```powershell
   [Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\Program Files\Java\jdk-17", "User")
   ```

**macOS:**
```bash
brew install openjdk@17
```

**Linux:**
```bash
sudo apt update
sudo apt install openjdk-17-jdk
```

---

## Part 2: Install Apache Spark

### Step 2.1: Download Spark

1. Go to [spark.apache.org/downloads.html](https://spark.apache.org/downloads.html)
2. Select:
   - Spark release: 3.5.0 (or latest)
   - Package type: Pre-built for Apache Hadoop 3.3
3. Download the .tgz file

### Step 2.2: Extract and Configure

**Windows (PowerShell):**
```powershell
# Create directory
New-Item -Path "C:\spark" -ItemType Directory -Force

# Extract (you may need 7-Zip or similar)
# Move extracted folder to C:\spark\spark-3.5.0-bin-hadoop3

# Set environment variables
[Environment]::SetEnvironmentVariable("SPARK_HOME", "C:\spark\spark-3.5.0-bin-hadoop3", "User")
[Environment]::SetEnvironmentVariable("Path", "$env:Path;$env:SPARK_HOME\bin", "User")
```

**macOS/Linux:**
```bash
# Extract
tar -xzf spark-3.5.0-bin-hadoop3.tgz

# Move to /opt
sudo mv spark-3.5.0-bin-hadoop3 /opt/spark

# Add to .bashrc or .zshrc
export SPARK_HOME=/opt/spark
export PATH=$PATH:$SPARK_HOME/bin
```

---

## Part 3: Install PySpark via pip

### Step 3.1: Create Virtual Environment
```bash
# Create project directory
mkdir spark_learning
cd spark_learning

# Create virtual environment
python -m venv venv

# Activate (Windows)
venv\Scripts\activate

# Activate (macOS/Linux)
source venv/bin/activate
```

### Step 3.2: Install PySpark
```bash
pip install pyspark==3.5.0
```

---

## Part 4: Verify Installation

### Step 4.1: Launch PySpark Shell
```bash
pyspark
```

You should see:
```
Welcome to
      ____              __
     / __/__  ___ _____/ /__
    _\ \/ _ \/ _ `/ __/  '_/
   /__ / .__/\_,_/_/ /_/\_\   version 3.5.0
      /_/

Using Python version 3.11.x
SparkSession available as 'spark'.
>>>
```

### Step 4.2: Run Test Commands
```python
# In PySpark shell
spark.version  # Should show '3.5.0'

# Create simple DataFrame
data = [("Alice", 25), ("Bob", 30), ("Charlie", 35)]
df = spark.createDataFrame(data, ["Name", "Age"])
df.show()

# Output:
# +-------+---+
# |   Name|Age|
# +-------+---+
# |  Alice| 25|
# |    Bob| 30|
# |Charlie| 35|
# +-------+---+

# Exit shell
exit()
```

---

## Part 5: First Spark Script

### Step 5.1: Create Python Script
Create a file named `first_spark.py`:

```python
"""
first_spark.py
Your first Apache Spark program
"""

from pyspark.sql import SparkSession

def main():
    # Create SparkSession
    spark = SparkSession.builder \
        .appName("FirstSparkApp") \
        .master("local[*]") \
        .getOrCreate()
    
    # Set log level to reduce output
    spark.sparkContext.setLogLevel("WARN")
    
    print(f"Spark Version: {spark.version}")
    print(f"Python Version: {spark.sparkContext.pythonVer}")
    
    # Create sample data
    data = [
        ("Alice", "Engineering", 75000),
        ("Bob", "Engineering", 80000),
        ("Charlie", "Sales", 60000),
        ("Diana", "Sales", 65000),
        ("Eve", "Marketing", 55000)
    ]
    
    columns = ["Name", "Department", "Salary"]
    
    # Create DataFrame
    df = spark.createDataFrame(data, columns)
    
    print("\n=== Employee Data ===")
    df.show()
    
    print("\n=== Schema ===")
    df.printSchema()
    
    print("\n=== Average Salary by Department ===")
    df.groupBy("Department").avg("Salary").show()
    
    # Stop Spark session
    spark.stop()
    print("\nSpark session stopped successfully!")

if __name__ == "__main__":
    main()
```

### Step 5.2: Run the Script
```bash
python first_spark.py
```

---

## Part 6: Understanding Spark Architecture

### Key Components

```
┌─────────────────────────────────────────────────────────┐
│                    DRIVER PROGRAM                        │
│  ┌─────────────────────────────────────────────────┐    │
│  │              SparkSession/SparkContext           │    │
│  └─────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│                    CLUSTER MANAGER                       │
│             (Standalone, YARN, Mesos, K8s)              │
└─────────────────────────────────────────────────────────┘
                           │
         ┌─────────────────┼─────────────────┐
         ▼                 ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│   WORKER 1   │  │   WORKER 2   │  │   WORKER N   │
│  ┌────────┐  │  │  ┌────────┐  │  │  ┌────────┐  │
│  │Executor│  │  │  │Executor│  │  │  │Executor│  │
│  │ ┌────┐ │  │  │  │ ┌────┐ │  │  │  │ ┌────┐ │  │
│  │ │Task│ │  │  │  │ │Task│ │  │  │  │ │Task│ │  │
│  │ └────┘ │  │  │  │ └────┘ │  │  │  │ └────┘ │  │
│  └────────┘  │  │  └────────┘  │  │  └────────┘  │
└──────────────┘  └──────────────┘  └──────────────┘
```

### Terminology
| Term | Description |
|------|-------------|
| **Driver** | The process running the main() function, creates SparkContext |
| **Executor** | Process running on worker nodes, executes tasks |
| **Task** | Unit of work sent to executor |
| **Job** | Parallel computation triggered by action |
| **Stage** | Set of tasks that can run in parallel |
| **Partition** | Chunk of data for parallel processing |

---

## Exercises

### Exercise 1: Environment Verification
Create a script that prints:
- Spark version
- Python version  
- Number of available CPU cores
- Amount of memory available to Spark

### Exercise 2: Simple Data Processing
1. Create a DataFrame with 10 employees
2. Filter employees with salary > 60000
3. Calculate total salary by department
4. Find the highest-paid employee

### Exercise 3: Configuration
Modify the SparkSession to:
- Set app name to "MyFirstApp"
- Use only 2 CPU cores
- Set executor memory to 2GB

---

## Common Issues and Solutions

### Issue 1: Java not found
```
Error: Java not found
Solution: Ensure JAVA_HOME is set correctly and Java is in PATH
```

### Issue 2: Python version mismatch
```
Error: Python version mismatch
Solution: Ensure the Python version used by PySpark matches your virtual environment
```

### Issue 3: Winutils on Windows
```
Error: Could not find winutils.exe
Solution: Download winutils.exe and set HADOOP_HOME
```

---

## Summary

In this lab, you learned:
- ✅ How to install Apache Spark
- ✅ How to configure environment variables
- ✅ How to verify installation with PySpark shell
- ✅ How to create and run your first Spark script
- ✅ Basic Spark architecture concepts

**Next Lab**: Lab 02 - RDD Fundamentals
