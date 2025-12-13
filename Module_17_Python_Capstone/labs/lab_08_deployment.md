# Lab 08: Documentation and Deployment

## Overview
Document the project and prepare it for deployment.

**Duration**: 2 hours  
**Difficulty**: ⭐⭐⭐ Intermediate

---

## Learning Objectives
- ✅ Write comprehensive documentation
- ✅ Create deployment configurations
- ✅ Build Docker containers
- ✅ Set up CI/CD pipelines
- ✅ Prepare for production

---

## Part 1: Project Documentation

### Step 1.1: Main README
```markdown
# E-Commerce Data Pipeline

A production-ready data pipeline for processing e-commerce data using PySpark.

## Overview

This pipeline ingests, transforms, and loads e-commerce data from multiple sources
into a data warehouse, generating analytics and reports.

### Architecture

```
┌─────────────┐    ┌──────────────┐    ┌──────────────┐    ┌─────────────┐
│   Sources   │───▶│   Ingest     │───▶│  Transform   │───▶│    Load     │
│             │    │              │    │              │    │             │
│ • CSV Files │    │ • Validate   │    │ • Clean      │    │ • Warehouse │
│ • APIs      │    │ • Schema     │    │ • Enrich     │    │ • Reports   │
│ • Database  │    │ • Quality    │    │ • Aggregate  │    │ • Analytics │
└─────────────┘    └──────────────┘    └──────────────┘    └─────────────┘
```

## Features

- **Multi-source ingestion**: CSV, REST APIs, databases
- **Data quality**: Validation, quarantine, monitoring
- **Transformations**: Cleansing, enrichment, aggregation
- **Warehouse loading**: Dimensions, facts, aggregates
- **Error handling**: Retry logic, graceful degradation
- **Monitoring**: Metrics, alerting, dashboards

## Quick Start

### Prerequisites

- Python 3.9+
- Apache Spark 3.4+
- Java 11+

### Installation

```bash
# Clone repository
git clone https://github.com/your-org/ecommerce-pipeline.git
cd ecommerce-pipeline

# Create virtual environment
python -m venv venv
source venv/bin/activate  # or .\venv\Scripts\activate on Windows

# Install dependencies
pip install -r requirements.txt
```

### Running the Pipeline

```bash
# Development
python -m src.main --env development

# Production
python -m src.main --env production
```

## Project Structure

```
ecommerce_pipeline/
├── src/
│   ├── ingestion/      # Data ingestion modules
│   ├── transformation/ # Data transformation modules
│   ├── loading/        # Data loading modules
│   └── utils/          # Utility modules
├── tests/              # Test suite
├── config/             # Configuration files
├── data/               # Data directories
├── docs/               # Documentation
└── scripts/            # Utility scripts
```

## Configuration

Configure the pipeline by editing `config/development.yaml` or 
`config/production.yaml`.

## Testing

```bash
# Run all tests
pytest tests/ -v

# Run with coverage
pytest tests/ --cov=src --cov-report=html
```

## Documentation

- [Architecture Guide](docs/architecture.md)
- [API Reference](docs/api.md)
- [Configuration Guide](docs/configuration.md)
- [Deployment Guide](docs/deployment.md)

## License

MIT License
```

### Step 1.2: API Documentation
```markdown
# API Reference

## Ingestion Module

### CSVIngester

```python
from src.ingestion import CSVIngester

ingester = CSVIngester(
    spark=spark,
    config=config,
    path="data/raw/orders.csv",
    schema=orders_schema,
    options={"dateFormat": "yyyy-MM-dd"}
)

df = ingester.ingest()
```

**Parameters:**
- `spark`: SparkSession instance
- `config`: Configuration dictionary
- `path`: Path to CSV file or directory
- `schema`: Optional StructType schema
- `options`: CSV reader options

**Returns:** DataFrame

### APIIngester

```python
from src.ingestion import APIIngester

ingester = APIIngester(
    spark=spark,
    config=config,
    base_url="https://api.example.com",
    endpoint="products",
    headers={"Authorization": "Bearer token"},
    pagination={"page_size": 100}
)

df = ingester.ingest()
```

## Transformation Module

### DataCleanser

```python
from src.transformation import DataCleanser

cleanser = DataCleanser(spark) \
    .trim_strings() \
    .drop_nulls(columns=["id", "email"]) \
    .remove_duplicates(["id"])

cleaned_df = cleanser.transform(raw_df)
```

**Available Methods:**
- `trim_strings(columns)` - Trim whitespace
- `drop_nulls(columns, how)` - Remove rows with nulls
- `fill_nulls(value_map)` - Fill null values
- `remove_duplicates(columns)` - Remove duplicates
- `standardize_case(columns, case)` - Standardize string case

### DataEnricher

```python
from src.transformation import DataEnricher

enricher = DataEnricher(spark)
enricher.register_lookup("products", products_df)
enricher \
    .add_total_amount("quantity", "price") \
    .add_date_parts("order_date") \
    .join_lookup("products", "product_id")

enriched_df = enricher.transform(orders_df)
```

## Loading Module

### WarehouseLoader

```python
from src.loading import WarehouseLoader

loader = WarehouseLoader(spark, config)

# Load dimension
loader.load_dimension(
    df=customers_df,
    dim_name="customers",
    key_column="customer_id"
)

# Load fact
loader.load_fact(
    df=sales_df,
    fact_name="sales",
    partition_columns=["year", "month"]
)
```
```

---

## Part 2: Docker Configuration

### Step 2.1: Dockerfile
```dockerfile
# Dockerfile
FROM python:3.9-slim

# Install Java
RUN apt-get update && \
    apt-get install -y openjdk-11-jre-headless && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

# Set working directory
WORKDIR /app

# Copy requirements
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY src/ ./src/
COPY config/ ./config/
COPY scripts/ ./scripts/

# Create data directories
RUN mkdir -p data/raw data/processed data/output logs

# Set environment variables
ENV PYTHONPATH=/app
ENV PYSPARK_PYTHON=python3

# Default command
CMD ["python", "-m", "src.main", "--env", "production"]
```

### Step 2.2: Docker Compose
```yaml
# docker-compose.yml
version: '3.8'

services:
  pipeline:
    build: .
    container_name: ecommerce-pipeline
    environment:
      - ENVIRONMENT=production
      - SPARK_MASTER=local[*]
      - DB_HOST=postgres
      - DB_PASSWORD=${DB_PASSWORD}
    volumes:
      - ./data:/app/data
      - ./logs:/app/logs
      - ./config:/app/config:ro
    depends_on:
      - postgres
    networks:
      - pipeline-network

  postgres:
    image: postgres:14
    container_name: pipeline-postgres
    environment:
      - POSTGRES_DB=ecommerce
      - POSTGRES_USER=pipeline
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - postgres-data:/var/lib/postgresql/data
      - ./scripts/init.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "5432:5432"
    networks:
      - pipeline-network

  scheduler:
    build: .
    container_name: pipeline-scheduler
    command: python scripts/schedule.py
    environment:
      - ENVIRONMENT=production
    volumes:
      - ./data:/app/data
      - ./logs:/app/logs
    depends_on:
      - pipeline
    networks:
      - pipeline-network

volumes:
  postgres-data:

networks:
  pipeline-network:
    driver: bridge
```

### Step 2.3: Build and Run
```powershell
# Build image
docker build -t ecommerce-pipeline:latest .

# Run with docker-compose
docker-compose up -d

# View logs
docker-compose logs -f pipeline

# Run pipeline manually
docker-compose run --rm pipeline python -m src.main --env production

# Stop services
docker-compose down
```

---

## Part 3: CI/CD Pipeline

### Step 3.1: GitHub Actions
```yaml
# .github/workflows/ci.yml
name: CI Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.9'
    
    - name: Set up Java
      uses: actions/setup-java@v3
      with:
        java-version: '11'
        distribution: 'adopt'
    
    - name: Install dependencies
      run: |
        pip install -r requirements-dev.txt
    
    - name: Lint
      run: |
        flake8 src/ tests/ --max-line-length=100
        black --check src/ tests/
    
    - name: Type check
      run: |
        mypy src/ --ignore-missing-imports
    
    - name: Run tests
      run: |
        pytest tests/ -v --cov=src --cov-report=xml
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        file: coverage.xml

  build:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v2
    
    - name: Login to Container Registry
      uses: docker/login-action@v2
      with:
        registry: ghcr.io
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
    
    - name: Build and push
      uses: docker/build-push-action@v4
      with:
        push: true
        tags: ghcr.io/${{ github.repository }}:latest
```

### Step 3.2: Deployment Workflow
```yaml
# .github/workflows/deploy.yml
name: Deploy Pipeline

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Deployment environment'
        required: true
        default: 'staging'
        type: choice
        options:
          - staging
          - production

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment }}
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-east-1
    
    - name: Deploy to EMR
      run: |
        # Upload code to S3
        aws s3 sync src/ s3://${{ secrets.S3_BUCKET }}/code/src/
        aws s3 cp config/${{ github.event.inputs.environment }}.yaml \
          s3://${{ secrets.S3_BUCKET }}/config/
        
        # Submit Spark job
        aws emr add-steps \
          --cluster-id ${{ secrets.EMR_CLUSTER_ID }} \
          --steps '[{
            "Name": "ECommerce Pipeline",
            "ActionOnFailure": "CONTINUE",
            "Jar": "command-runner.jar",
            "Args": [
              "spark-submit",
              "--deploy-mode", "cluster",
              "s3://${{ secrets.S3_BUCKET }}/code/src/main.py",
              "--env", "${{ github.event.inputs.environment }}"
            ]
          }]'
```

---

## Part 4: Production Checklist

### Step 4.1: Pre-Production Checklist
```markdown
# Production Readiness Checklist

## Code Quality
- [ ] All tests passing
- [ ] Code coverage > 80%
- [ ] No linting errors
- [ ] Type hints added
- [ ] Documentation complete

## Configuration
- [ ] Production config reviewed
- [ ] Secrets in secure storage
- [ ] Environment variables set
- [ ] Database connections tested

## Data Quality
- [ ] Validation rules defined
- [ ] Quarantine process set up
- [ ] Quality thresholds configured
- [ ] Monitoring alerts set

## Performance
- [ ] Spark configs optimized
- [ ] Partition strategy defined
- [ ] Memory settings tuned
- [ ] Tested with production-scale data

## Operations
- [ ] Logging configured
- [ ] Metrics collection enabled
- [ ] Alerting set up
- [ ] Runbooks documented
- [ ] Rollback plan defined

## Security
- [ ] Credentials secured
- [ ] Data encryption configured
- [ ] Access controls set
- [ ] Audit logging enabled

## Deployment
- [ ] Docker images built
- [ ] CI/CD pipeline tested
- [ ] Infrastructure provisioned
- [ ] Scheduling configured
```

### Step 4.2: Runbook
```markdown
# Operations Runbook

## Daily Operations

### Verify Pipeline Run
1. Check Airflow UI for successful completion
2. Verify records processed in logs
3. Check data quality metrics

### Common Issues

#### Pipeline Failure: Ingestion Stage
**Symptoms:** Ingestion stage fails with connection error
**Resolution:**
1. Check source system availability
2. Verify credentials
3. Retry pipeline

#### Pipeline Failure: Data Quality
**Symptoms:** Validation stage fails with quality error
**Resolution:**
1. Check quarantine for failed records
2. Analyze error patterns
3. Fix source data or adjust thresholds

#### Performance Issues
**Symptoms:** Pipeline runs longer than expected
**Resolution:**
1. Check Spark UI for bottlenecks
2. Review partition count
3. Check for data skew

## Recovery Procedures

### Reprocessing Data
```bash
# Reprocess specific date
python -m src.main --env production --date 2024-01-15
```

### Rollback
```bash
# Restore previous data version
aws s3 sync s3://backup/warehouse/ s3://production/warehouse/
```
```

---

## Part 5: Final Project Summary

### Step 5.1: What We Built
```
E-Commerce Data Pipeline
├── Ingestion Layer
│   ├── CSV file ingestion
│   ├── REST API ingestion
│   └── Database ingestion
├── Transformation Layer
│   ├── Data cleansing
│   ├── Data enrichment
│   └── Aggregations
├── Loading Layer
│   ├── Warehouse (Delta Lake)
│   ├── Dimensions (SCD)
│   └── Reports
├── Quality Framework
│   ├── Validation rules
│   ├── Quarantine management
│   └── Quality monitoring
├── Testing
│   ├── Unit tests
│   └── Integration tests
├── Orchestration
│   ├── Pipeline framework
│   └── Scheduling
└── Deployment
    ├── Docker containers
    └── CI/CD pipelines
```

---

## Exercises

1. Write complete API documentation
2. Create a Docker deployment
3. Set up a CI/CD pipeline
4. Create a runbook for operations

---

## Summary
- Wrote comprehensive documentation
- Created Docker configuration
- Set up CI/CD pipelines
- Prepared production checklist
- Created operations runbook

---

## Congratulations!
You have completed the Python Capstone Project! You now have a production-ready
data pipeline with:
- Modular, testable code
- Comprehensive error handling
- Data quality management
- Professional documentation
- Deployment automation
