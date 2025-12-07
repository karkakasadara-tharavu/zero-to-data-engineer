# Lab 09: Real-World Data Pipeline

## Estimated Time: 120 minutes

## Objectives
- Build end-to-end ETL pipeline
- Implement data quality checks
- Handle errors gracefully
- Create logging and monitoring
- Deploy production-ready code

## Prerequisites
- Completed Labs 01-08
- Understanding of ETL concepts
- Basic logging and error handling

## Background

You're building a production data pipeline for an e-commerce company. The pipeline ingests data from multiple sources, cleans and transforms it, performs quality checks, and outputs analytics-ready datasets. This must handle errors, log operations, and run reliably.

## Tasks

### Task 1: Data Ingestion (25 min)
- Read from multiple sources (CSV, JSON, API)
- Handle different encodings and formats
- Implement retry logic for failures
- Validate input data structure

### Task 2: Data Cleaning Pipeline (30 min)
- Standardize column names
- Handle missing values systematically
- Remove duplicates intelligently
- Type conversion with validation
- Outlier detection and handling

### Task 3: Data Transformation (30 min)
- Business logic implementation
- Feature engineering
- Aggregations and joins
- Time-based calculations
- Create derived columns

### Task 4: Quality Checks & Output (35 min)
- Schema validation
- Data quality metrics
- Anomaly detection
- Error reporting
- Export in multiple formats

## Starter Code

```python
import pandas as pd
import numpy as np
import logging
import json
from datetime import datetime
from pathlib import Path

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('pipeline.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

class DataPipeline:
    """Production-ready data pipeline"""
    
    def __init__(self, config_file='config.json'):
        """Initialize pipeline with configuration"""
        self.config = self.load_config(config_file)
        self.data = {}
        self.quality_metrics = {}
        logger.info("Pipeline initialized")
    
    def load_config(self, config_file):
        """Load pipeline configuration"""
        # TODO: Load from JSON
        default_config = {
            'input_sources': {
                'sales': 'data/sales.csv',
                'customers': 'data/customers.json',
                'products': 'data/products.csv'
            },
            'output_dir': 'output',
            'quality_thresholds': {
                'missing_threshold': 0.1,
                'duplicate_threshold': 0.05
            }
        }
        return default_config
    
    # Task 1: Data Ingestion
    def ingest_data(self):
        """Ingest data from all sources"""
        logger.info("Starting data ingestion")
        
        try:
            # TODO: Read sales data
            self.data['sales'] = self.read_with_retry(
                self.config['input_sources']['sales'],
                file_type='csv'
            )
            logger.info(f"Loaded sales: {self.data['sales'].shape}")
            
            # TODO: Read customers data
            self.data['customers'] = self.read_with_retry(
                self.config['input_sources']['customers'],
                file_type='json'
            )
            logger.info(f"Loaded customers: {self.data['customers'].shape}")
            
            # TODO: Read products data
            self.data['products'] = self.read_with_retry(
                self.config['input_sources']['products'],
                file_type='csv'
            )
            logger.info(f"Loaded products: {self.data['products'].shape}")
            
            return True
            
        except Exception as e:
            logger.error(f"Ingestion failed: {e}")
            return False
    
    def read_with_retry(self, filepath, file_type='csv', max_retries=3):
        """Read file with retry logic"""
        for attempt in range(max_retries):
            try:
                if file_type == 'csv':
                    return pd.read_csv(filepath, encoding='utf-8')
                elif file_type == 'json':
                    return pd.read_json(filepath)
                else:
                    raise ValueError(f"Unsupported file type: {file_type}")
            except Exception as e:
                logger.warning(f"Read attempt {attempt + 1} failed: {e}")
                if attempt == max_retries - 1:
                    raise
    
    # Task 2: Data Cleaning
    def clean_data(self):
        """Clean all datasets"""
        logger.info("Starting data cleaning")
        
        for name, df in self.data.items():
            logger.info(f"Cleaning {name}")
            
            # TODO: Standardize column names
            df.columns = df.columns.str.lower().str.replace(' ', '_')
            
            # TODO: Record initial quality
            initial_rows = len(df)
            initial_missing = df.isnull().sum().sum()
            
            # TODO: Handle missing values
            df = self.handle_missing(df, name)
            
            # TODO: Remove duplicates
            df = self.remove_duplicates(df, name)
            
            # TODO: Type conversion
            df = self.convert_types(df, name)
            
            # TODO: Outlier handling
            df = self.handle_outliers(df, name)
            
            # Update dataset
            self.data[name] = df
            
            # Log cleaning results
            final_rows = len(df)
            final_missing = df.isnull().sum().sum()
            logger.info(f"{name} cleaned: {initial_rows} → {final_rows} rows, "
                       f"{initial_missing} → {final_missing} missing values")
    
    def handle_missing(self, df, dataset_name):
        """Handle missing values intelligently"""
        # TODO: Strategy varies by column type
        for col in df.columns:
            missing_pct = df[col].isnull().sum() / len(df)
            
            if missing_pct > 0:
                if missing_pct > 0.5:
                    # Drop column if >50% missing
                    logger.warning(f"Dropping {col} ({missing_pct:.1%} missing)")
                    df = df.drop(columns=[col])
                elif df[col].dtype in ['float64', 'int64']:
                    # Fill numeric with median
                    df[col] = df[col].fillna(df[col].median())
                else:
                    # Fill categorical with mode
                    df[col] = df[col].fillna(df[col].mode()[0] if not df[col].mode().empty else 'Unknown')
        
        return df
    
    def remove_duplicates(self, df, dataset_name):
        """Remove duplicates with logging"""
        initial_rows = len(df)
        df = df.drop_duplicates()
        removed = initial_rows - len(df)
        
        if removed > 0:
            logger.info(f"{dataset_name}: Removed {removed} duplicates ({removed/initial_rows:.2%})")
        
        return df
    
    def convert_types(self, df, dataset_name):
        """Convert to appropriate types"""
        # TODO: Date columns
        date_cols = [col for col in df.columns if 'date' in col.lower()]
        for col in date_cols:
            df[col] = pd.to_datetime(df[col], errors='coerce')
        
        # TODO: Categorical columns
        categorical_threshold = 10
        for col in df.select_dtypes(include=['object']).columns:
            if df[col].nunique() < categorical_threshold:
                df[col] = df[col].astype('category')
        
        return df
    
    def handle_outliers(self, df, dataset_name):
        """Detect and handle outliers"""
        numeric_cols = df.select_dtypes(include=[np.number]).columns
        
        for col in numeric_cols:
            # IQR method
            Q1 = df[col].quantile(0.25)
            Q3 = df[col].quantile(0.75)
            IQR = Q3 - Q1
            lower_bound = Q1 - 3 * IQR
            upper_bound = Q3 + 3 * IQR
            
            outliers = ((df[col] < lower_bound) | (df[col] > upper_bound)).sum()
            if outliers > 0:
                logger.info(f"{dataset_name}.{col}: {outliers} outliers detected")
                # Cap outliers
                df[col] = df[col].clip(lower_bound, upper_bound)
        
        return df
    
    # Task 3: Data Transformation
    def transform_data(self):
        """Apply business transformations"""
        logger.info("Starting data transformation")
        
        # TODO: Create unified sales view
        sales = self.data['sales']
        customers = self.data['customers']
        products = self.data['products']
        
        # Join datasets
        sales_enriched = (sales
                         .merge(customers, on='customer_id', how='left', suffixes=('', '_customer'))
                         .merge(products, on='product_id', how='left', suffixes=('', '_product')))
        
        # TODO: Feature engineering
        sales_enriched['revenue'] = sales_enriched['quantity'] * sales_enriched['unit_price']
        sales_enriched['profit'] = sales_enriched['revenue'] * sales_enriched['profit_margin']
        sales_enriched['order_month'] = sales_enriched['order_date'].dt.to_period('M')
        sales_enriched['order_quarter'] = sales_enriched['order_date'].dt.to_period('Q')
        sales_enriched['days_since_order'] = (datetime.now() - sales_enriched['order_date']).dt.days
        
        # TODO: Customer segmentation
        customer_metrics = sales_enriched.groupby('customer_id').agg({
            'revenue': 'sum',
            'order_date': 'count',
            'profit': 'sum'
        }).rename(columns={'order_date': 'order_count'})
        
        # RFM scoring
        customer_metrics['recency'] = sales_enriched.groupby('customer_id')['days_since_order'].min()
        customer_metrics['monetary'] = customer_metrics['revenue']
        customer_metrics['frequency'] = customer_metrics['order_count']
        
        # Segment customers
        customer_metrics['segment'] = pd.cut(
            customer_metrics['monetary'],
            bins=[0, 1000, 5000, float('inf')],
            labels=['Bronze', 'Silver', 'Gold']
        )
        
        # TODO: Product performance
        product_metrics = sales_enriched.groupby('product_id').agg({
            'revenue': ['sum', 'mean'],
            'quantity': 'sum',
            'profit': 'sum'
        })
        product_metrics.columns = ['_'.join(col).strip() for col in product_metrics.columns]
        
        # Store results
        self.data['sales_enriched'] = sales_enriched
        self.data['customer_metrics'] = customer_metrics
        self.data['product_metrics'] = product_metrics
        
        logger.info("Transformation complete")
    
    # Task 4: Quality Checks
    def validate_quality(self):
        """Perform data quality checks"""
        logger.info("Starting quality validation")
        
        for name, df in self.data.items():
            metrics = {}
            
            # TODO: Completeness
            total_cells = df.shape[0] * df.shape[1]
            missing_cells = df.isnull().sum().sum()
            metrics['completeness'] = 1 - (missing_cells / total_cells)
            
            # TODO: Uniqueness
            if 'id' in df.columns[0].lower():
                metrics['uniqueness'] = df.iloc[:, 0].nunique() / len(df)
            
            # TODO: Validity
            numeric_cols = df.select_dtypes(include=[np.number]).columns
            if len(numeric_cols) > 0:
                metrics['validity'] = (df[numeric_cols] >= 0).all().all()
            
            # TODO: Consistency
            metrics['row_count'] = len(df)
            metrics['column_count'] = len(df.columns)
            
            self.quality_metrics[name] = metrics
            
            # Check thresholds
            if metrics['completeness'] < (1 - self.config['quality_thresholds']['missing_threshold']):
                logger.warning(f"{name}: Completeness below threshold ({metrics['completeness']:.2%})")
        
        logger.info("Quality validation complete")
        return self.quality_metrics
    
    def export_results(self):
        """Export processed data"""
        logger.info("Exporting results")
        
        output_dir = Path(self.config['output_dir'])
        output_dir.mkdir(exist_ok=True)
        
        # TODO: Export each dataset
        for name, df in self.data.items():
            # CSV
            csv_path = output_dir / f"{name}.csv"
            df.to_csv(csv_path, index=False)
            
            # Parquet (compressed)
            parquet_path = output_dir / f"{name}.parquet"
            df.to_parquet(parquet_path, index=False, compression='snappy')
            
            logger.info(f"Exported {name}: {len(df)} rows")
        
        # TODO: Export quality report
        quality_report = pd.DataFrame(self.quality_metrics).T
        quality_report.to_csv(output_dir / 'quality_report.csv')
        
        logger.info("Export complete")
    
    def run(self):
        """Execute full pipeline"""
        logger.info("="*60)
        logger.info("STARTING DATA PIPELINE")
        logger.info("="*60)
        
        try:
            # Execute pipeline stages
            if not self.ingest_data():
                raise Exception("Ingestion failed")
            
            self.clean_data()
            self.transform_data()
            metrics = self.validate_quality()
            self.export_results()
            
            logger.info("="*60)
            logger.info("PIPELINE COMPLETED SUCCESSFULLY")
            logger.info("="*60)
            
            return True
            
        except Exception as e:
            logger.error(f"Pipeline failed: {e}")
            return False

def main():
    """Main execution"""
    print("LAB 09: REAL-WORLD DATA PIPELINE\n")
    
    # Create sample data
    create_sample_data()
    
    # Run pipeline
    pipeline = DataPipeline()
    success = pipeline.run()
    
    if success:
        print("\n✓ Pipeline executed successfully!")
        print("Check 'pipeline.log' for details")
        print("Check 'output/' for results")
    else:
        print("\n✗ Pipeline failed. Check logs for errors.")

def create_sample_data():
    """Create sample datasets for testing"""
    # Create data directory
    Path('data').mkdir(exist_ok=True)
    
    # Sales data
    sales = pd.DataFrame({
        'order_id': range(1, 1001),
        'customer_id': np.random.randint(1, 101, 1000),
        'product_id': np.random.randint(1, 51, 1000),
        'quantity': np.random.randint(1, 10, 1000),
        'unit_price': np.random.uniform(10, 500, 1000),
        'order_date': pd.date_range('2024-01-01', periods=1000, freq='H')
    })
    sales.to_csv('data/sales.csv', index=False)
    
    # Customers data
    customers = pd.DataFrame({
        'customer_id': range(1, 101),
        'name': [f'Customer {i}' for i in range(1, 101)],
        'email': [f'customer{i}@example.com' for i in range(1, 101)],
        'segment': np.random.choice(['Premium', 'Standard', 'Basic'], 100)
    })
    customers.to_json('data/customers.json', orient='records')
    
    # Products data
    products = pd.DataFrame({
        'product_id': range(1, 51),
        'product_name': [f'Product {i}' for i in range(1, 51)],
        'category': np.random.choice(['Electronics', 'Clothing', 'Books'], 50),
        'profit_margin': np.random.uniform(0.1, 0.4, 50)
    })
    products.to_csv('data/products.csv', index=False)

if __name__ == "__main__":
    main()
```

## Deliverables
- Complete ETL pipeline implementation
- Pipeline execution logs
- Quality validation report
- Processed datasets (CSV, Parquet)
- Documentation

## Bonus Challenges
- Add data versioning
- Implement incremental loading
- Create monitoring dashboard
- Add automated testing
- Schedule with Airflow

## Submission
Submit `lab_09_solution.py` with complete pipeline implementation and sample run output.
