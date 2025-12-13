# Lab 01: Project Setup and Requirements

## Overview
Set up the capstone project environment and define requirements.

**Duration**: 2 hours  
**Difficulty**: ⭐⭐⭐ Intermediate

---

## Learning Objectives
- ✅ Set up project structure
- ✅ Configure virtual environment
- ✅ Define project requirements
- ✅ Implement configuration management
- ✅ Set up version control

---

## Part 1: Project Overview

### The Capstone Project
Build a complete **E-Commerce Data Pipeline** that:
- Ingests data from multiple sources
- Transforms and cleanses data
- Loads into a data warehouse
- Generates analytics reports
- Handles errors gracefully

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    E-Commerce Data Pipeline                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │   Sources   │  │   Ingest    │  │  Transform  │  │    Load     │    │
│  │             │  │             │  │             │  │             │    │
│  │ • CSV Files │─▶│ • Validate  │─▶│ • Clean     │─▶│ • Warehouse │    │
│  │ • JSON API  │  │ • Schema    │  │ • Aggregate │  │ • Reports   │    │
│  │ • Database  │  │ • Quality   │  │ • Enrich    │  │ • Analytics │    │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Part 2: Project Structure

### Step 2.1: Create Directory Structure
```powershell
# Create project directory
mkdir ecommerce_pipeline
cd ecommerce_pipeline

# Create folder structure
mkdir src
mkdir src\ingestion
mkdir src\transformation
mkdir src\loading
mkdir src\utils
mkdir tests
mkdir tests\unit
mkdir tests\integration
mkdir config
mkdir data
mkdir data\raw
mkdir data\processed
mkdir data\output
mkdir logs
mkdir docs
```

### Step 2.2: Complete Project Layout
```
ecommerce_pipeline/
├── src/
│   ├── __init__.py
│   ├── main.py
│   ├── ingestion/
│   │   ├── __init__.py
│   │   ├── csv_ingester.py
│   │   ├── api_ingester.py
│   │   └── db_ingester.py
│   ├── transformation/
│   │   ├── __init__.py
│   │   ├── cleanser.py
│   │   ├── aggregator.py
│   │   └── enricher.py
│   ├── loading/
│   │   ├── __init__.py
│   │   ├── warehouse_loader.py
│   │   └── report_generator.py
│   └── utils/
│       ├── __init__.py
│       ├── config.py
│       ├── logger.py
│       └── validators.py
├── tests/
│   ├── __init__.py
│   ├── conftest.py
│   ├── unit/
│   │   ├── test_cleanser.py
│   │   ├── test_aggregator.py
│   │   └── test_validators.py
│   └── integration/
│       └── test_pipeline.py
├── config/
│   ├── development.yaml
│   ├── production.yaml
│   └── schemas.yaml
├── data/
│   ├── raw/
│   ├── processed/
│   └── output/
├── logs/
├── docs/
│   └── README.md
├── requirements.txt
├── requirements-dev.txt
├── setup.py
├── pyproject.toml
├── .gitignore
└── README.md
```

---

## Part 3: Virtual Environment

### Step 3.1: Create Virtual Environment
```powershell
# Create virtual environment
python -m venv venv

# Activate (Windows PowerShell)
.\venv\Scripts\Activate.ps1

# Verify Python
python --version
pip --version
```

### Step 3.2: Requirements Files
```txt
# requirements.txt - Production dependencies
pyspark==3.4.0
pandas==2.0.3
numpy==1.24.3
pyyaml==6.0.1
requests==2.31.0
python-dotenv==1.0.0
sqlalchemy==2.0.20
psycopg2-binary==2.9.7
delta-spark==2.4.0
pyarrow==13.0.0
```

```txt
# requirements-dev.txt - Development dependencies
-r requirements.txt
pytest==7.4.0
pytest-cov==4.1.0
pytest-mock==3.11.1
chispa==0.9.4
black==23.7.0
flake8==6.1.0
mypy==1.5.1
isort==5.12.0
pre-commit==3.3.3
```

### Step 3.3: Install Dependencies
```powershell
# Install production dependencies
pip install -r requirements.txt

# Install development dependencies
pip install -r requirements-dev.txt

# Verify installation
pip list
```

---

## Part 4: Package Setup

### Step 4.1: setup.py
```python
# setup.py
from setuptools import setup, find_packages

setup(
    name="ecommerce_pipeline",
    version="1.0.0",
    description="E-Commerce Data Pipeline",
    author="Your Name",
    author_email="your.email@example.com",
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    python_requires=">=3.9",
    install_requires=[
        "pyspark>=3.4.0",
        "pandas>=2.0.0",
        "pyyaml>=6.0",
        "requests>=2.31.0",
        "python-dotenv>=1.0.0",
    ],
    extras_require={
        "dev": [
            "pytest>=7.4.0",
            "pytest-cov>=4.1.0",
            "black>=23.7.0",
            "flake8>=6.1.0",
        ],
    },
    entry_points={
        "console_scripts": [
            "run-pipeline=main:main",
        ],
    },
)
```

### Step 4.2: pyproject.toml
```toml
# pyproject.toml
[build-system]
requires = ["setuptools>=61.0", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "ecommerce_pipeline"
version = "1.0.0"
description = "E-Commerce Data Pipeline"
readme = "README.md"
requires-python = ">=3.9"
license = {text = "MIT"}
authors = [
    {name = "Your Name", email = "your.email@example.com"}
]

[tool.black]
line-length = 88
target-version = ["py39"]
include = '\.pyi?$'
exclude = '''
/(
    \.git
  | \.venv
  | build
  | dist
)/
'''

[tool.isort]
profile = "black"
line_length = 88
skip = [".venv", "build", "dist"]

[tool.mypy]
python_version = "3.9"
warn_return_any = true
warn_unused_configs = true
ignore_missing_imports = true

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
addopts = "-v --tb=short"
```

---

## Part 5: Configuration Management

### Step 5.1: Development Configuration
```yaml
# config/development.yaml
environment: development
debug: true

# Data paths
paths:
  raw_data: "./data/raw"
  processed_data: "./data/processed"
  output: "./data/output"
  logs: "./logs"

# Database configuration
database:
  host: "localhost"
  port: 5432
  name: "ecommerce_dev"
  user: "postgres"
  password: "${DB_PASSWORD}"

# Spark configuration
spark:
  app_name: "ECommerce Pipeline - Dev"
  master: "local[*]"
  config:
    spark.sql.shuffle.partitions: 4
    spark.sql.adaptive.enabled: true
    spark.driver.memory: "2g"

# API configuration
api:
  base_url: "https://api.dev.example.com"
  timeout: 30
  retry_attempts: 3

# Quality thresholds
quality:
  null_threshold: 0.05
  duplicate_threshold: 0.01
```

### Step 5.2: Production Configuration
```yaml
# config/production.yaml
environment: production
debug: false

paths:
  raw_data: "s3://bucket/raw"
  processed_data: "s3://bucket/processed"
  output: "s3://bucket/output"
  logs: "s3://bucket/logs"

database:
  host: "${DB_HOST}"
  port: 5432
  name: "ecommerce_prod"
  user: "${DB_USER}"
  password: "${DB_PASSWORD}"

spark:
  app_name: "ECommerce Pipeline - Prod"
  master: "yarn"
  config:
    spark.sql.shuffle.partitions: 200
    spark.sql.adaptive.enabled: true
    spark.executor.memory: "8g"
    spark.executor.cores: 4
    spark.dynamicAllocation.enabled: true

api:
  base_url: "https://api.example.com"
  timeout: 60
  retry_attempts: 5

quality:
  null_threshold: 0.01
  duplicate_threshold: 0.001
```

### Step 5.3: Configuration Loader
```python
# src/utils/config.py
import os
import yaml
from pathlib import Path
from typing import Any, Dict, Optional
import re


class Config:
    """Configuration manager with environment variable support."""
    
    _instance: Optional['Config'] = None
    _config: Dict[str, Any] = {}
    
    def __new__(cls, *args, **kwargs):
        """Singleton pattern."""
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance
    
    def __init__(self, env: str = None):
        if not self._config:
            self.env = env or os.getenv("ENVIRONMENT", "development")
            self._load_config()
    
    def _load_config(self):
        """Load configuration from YAML file."""
        config_path = Path(__file__).parent.parent.parent / "config" / f"{self.env}.yaml"
        
        if not config_path.exists():
            raise FileNotFoundError(f"Config file not found: {config_path}")
        
        with open(config_path, 'r') as f:
            raw_config = yaml.safe_load(f)
        
        # Resolve environment variables
        self._config = self._resolve_env_vars(raw_config)
    
    def _resolve_env_vars(self, config: Any) -> Any:
        """Recursively resolve ${VAR} patterns."""
        if isinstance(config, dict):
            return {k: self._resolve_env_vars(v) for k, v in config.items()}
        elif isinstance(config, list):
            return [self._resolve_env_vars(item) for item in config]
        elif isinstance(config, str):
            # Replace ${VAR} with environment variable
            pattern = r'\$\{([^}]+)\}'
            matches = re.findall(pattern, config)
            for var in matches:
                value = os.getenv(var, "")
                config = config.replace(f"${{{var}}}", value)
            return config
        return config
    
    def get(self, key: str, default: Any = None) -> Any:
        """Get configuration value using dot notation."""
        keys = key.split('.')
        value = self._config
        
        for k in keys:
            if isinstance(value, dict) and k in value:
                value = value[k]
            else:
                return default
        
        return value
    
    @property
    def database(self) -> Dict[str, Any]:
        return self.get('database', {})
    
    @property
    def spark_config(self) -> Dict[str, Any]:
        return self.get('spark', {})
    
    @property
    def paths(self) -> Dict[str, str]:
        return self.get('paths', {})
    
    def __repr__(self):
        return f"Config(env={self.env})"


# Usage
config = Config()
db_host = config.get('database.host')
raw_path = config.paths['raw_data']
```

---

## Part 6: Logging Setup

### Step 6.1: Logger Configuration
```python
# src/utils/logger.py
import logging
import sys
from pathlib import Path
from datetime import datetime
from typing import Optional


def setup_logger(
    name: str,
    log_level: int = logging.INFO,
    log_file: Optional[str] = None,
    format_string: str = None
) -> logging.Logger:
    """
    Set up a logger with console and file handlers.
    
    Args:
        name: Logger name
        log_level: Logging level
        log_file: Path to log file (optional)
        format_string: Custom format string
    
    Returns:
        Configured logger
    """
    logger = logging.getLogger(name)
    logger.setLevel(log_level)
    
    # Avoid duplicate handlers
    if logger.handlers:
        return logger
    
    # Default format
    if format_string is None:
        format_string = (
            '%(asctime)s | %(levelname)-8s | %(name)s | '
            '%(filename)s:%(lineno)d | %(message)s'
        )
    
    formatter = logging.Formatter(format_string, datefmt='%Y-%m-%d %H:%M:%S')
    
    # Console handler
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(log_level)
    console_handler.setFormatter(formatter)
    logger.addHandler(console_handler)
    
    # File handler
    if log_file:
        log_path = Path(log_file)
        log_path.parent.mkdir(parents=True, exist_ok=True)
        
        file_handler = logging.FileHandler(log_file)
        file_handler.setLevel(log_level)
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)
    
    return logger


def get_pipeline_logger(pipeline_name: str = "pipeline") -> logging.Logger:
    """Get a logger configured for the pipeline."""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_file = f"logs/{pipeline_name}_{timestamp}.log"
    
    return setup_logger(
        name=pipeline_name,
        log_level=logging.INFO,
        log_file=log_file
    )


# Usage
logger = get_pipeline_logger("ecommerce_etl")
logger.info("Pipeline started")
logger.warning("Missing optional field")
logger.error("Failed to process record")
```

---

## Part 7: Git Configuration

### Step 7.1: .gitignore
```gitignore
# .gitignore

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# Virtual environments
venv/
ENV/
env/
.venv/

# IDE
.idea/
.vscode/
*.swp
*.swo
*~

# Testing
.pytest_cache/
.coverage
htmlcov/
.tox/
.nox/

# MyPy
.mypy_cache/

# Data (keep structure, ignore files)
data/raw/*
data/processed/*
data/output/*
!data/raw/.gitkeep
!data/processed/.gitkeep
!data/output/.gitkeep

# Logs
logs/*
!logs/.gitkeep

# Environment
.env
.env.local
*.local.yaml

# Spark
metastore_db/
spark-warehouse/
derby.log

# Secrets
secrets/
*.pem
*.key
```

### Step 7.2: Initialize Git
```powershell
# Initialize repository
git init

# Create .gitkeep files
New-Item -Path "data/raw/.gitkeep" -ItemType File -Force
New-Item -Path "data/processed/.gitkeep" -ItemType File -Force
New-Item -Path "data/output/.gitkeep" -ItemType File -Force
New-Item -Path "logs/.gitkeep" -ItemType File -Force

# Initial commit
git add .
git commit -m "Initial project setup"
```

---

## Part 8: Create Init Files

### Step 8.1: Package Init Files
```python
# src/__init__.py
"""E-Commerce Data Pipeline."""

__version__ = "1.0.0"
```

```python
# src/ingestion/__init__.py
"""Data ingestion modules."""

from .csv_ingester import CSVIngester
from .api_ingester import APIIngester
from .db_ingester import DatabaseIngester

__all__ = ["CSVIngester", "APIIngester", "DatabaseIngester"]
```

```python
# src/transformation/__init__.py
"""Data transformation modules."""

from .cleanser import DataCleanser
from .aggregator import DataAggregator
from .enricher import DataEnricher

__all__ = ["DataCleanser", "DataAggregator", "DataEnricher"]
```

```python
# src/loading/__init__.py
"""Data loading modules."""

from .warehouse_loader import WarehouseLoader
from .report_generator import ReportGenerator

__all__ = ["WarehouseLoader", "ReportGenerator"]
```

```python
# src/utils/__init__.py
"""Utility modules."""

from .config import Config
from .logger import setup_logger, get_pipeline_logger
from .validators import DataValidator

__all__ = ["Config", "setup_logger", "get_pipeline_logger", "DataValidator"]
```

---

## Exercises

1. Create the complete project structure
2. Set up virtual environment and install dependencies
3. Create configuration files for dev and prod
4. Implement the configuration loader
5. Set up logging with file rotation

---

## Summary
- Created professional project structure
- Set up virtual environment
- Configured dependencies
- Implemented configuration management
- Set up logging infrastructure
- Initialized Git repository

---

## Next Lab
In the next lab, we'll implement the data ingestion layer.
