# Lab 06: Machine Learning with PySpark MLlib

## Overview
Introduction to machine learning using PySpark's MLlib library.

**Duration**: 3 hours  
**Difficulty**: ⭐⭐⭐ Advanced

---

## Learning Objectives
- ✅ Understand MLlib pipeline architecture
- ✅ Perform feature engineering
- ✅ Build classification and regression models
- ✅ Evaluate and tune models
- ✅ Save and load models

---

## Part 1: MLlib Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│ MLlib Pipeline Components                                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐   ┌───────────┐  │
│   │ Transformer │──▶│ Transformer │──▶│  Estimator  │──▶│   Model   │  │
│   │ (Feature    │   │ (Normalize) │   │ (Train)     │   │ (Predict) │  │
│   │  Engineer)  │   │             │   │             │   │           │  │
│   └─────────────┘   └─────────────┘   └─────────────┘   └───────────┘  │
│                                                                          │
│   Transformers: transform data (StringIndexer, VectorAssembler)         │
│   Estimators: fit on data to produce models (LogisticRegression, etc.)  │
│   Pipelines: chain multiple stages together                             │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Part 2: Setup

```python
from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from pyspark.sql.types import *

spark = SparkSession.builder \
    .appName("MLlib Tutorial") \
    .master("local[*]") \
    .config("spark.driver.memory", "4g") \
    .getOrCreate()
```

---

## Part 3: Sample Dataset

```python
# Create sample dataset for classification
data = [
    (1, 25, 50000, "Single", 0, 1),
    (2, 35, 75000, "Married", 1, 1),
    (3, 45, 100000, "Married", 2, 1),
    (4, 22, 30000, "Single", 0, 0),
    (5, 55, 120000, "Married", 3, 1),
    (6, 28, 45000, "Single", 0, 0),
    (7, 38, 85000, "Married", 1, 1),
    (8, 50, 95000, "Divorced", 2, 1),
    (9, 24, 35000, "Single", 0, 0),
    (10, 42, 90000, "Married", 2, 1),
    (11, 30, 55000, "Single", 0, 0),
    (12, 60, 150000, "Married", 4, 1),
    (13, 33, 62000, "Married", 1, 1),
    (14, 27, 42000, "Single", 0, 0),
    (15, 48, 110000, "Divorced", 2, 1),
]

df = spark.createDataFrame(
    data, 
    ["id", "age", "income", "marital_status", "num_children", "purchased"]
)
df.show()
```

---

## Part 4: Feature Engineering

### Step 4.1: String Indexer
```python
from pyspark.ml.feature import StringIndexer

# Convert categorical string to numeric
indexer = StringIndexer(inputCol="marital_status", outputCol="marital_index")

# Fit and transform
indexed_df = indexer.fit(df).transform(df)
indexed_df.select("marital_status", "marital_index").distinct().show()
```

### Step 4.2: One-Hot Encoder
```python
from pyspark.ml.feature import OneHotEncoder

# One-hot encode the indexed column
encoder = OneHotEncoder(inputCol="marital_index", outputCol="marital_vec")
encoded_df = encoder.fit(indexed_df).transform(indexed_df)
encoded_df.select("marital_status", "marital_index", "marital_vec").show(truncate=False)
```

### Step 4.3: Vector Assembler
```python
from pyspark.ml.feature import VectorAssembler

# Combine features into single vector
assembler = VectorAssembler(
    inputCols=["age", "income", "num_children", "marital_index"],
    outputCol="features"
)

assembled_df = assembler.transform(encoded_df)
assembled_df.select("features", "purchased").show(truncate=False)
```

### Step 4.4: Feature Scaling
```python
from pyspark.ml.feature import StandardScaler, MinMaxScaler

# StandardScaler (mean=0, std=1)
scaler = StandardScaler(inputCol="features", outputCol="scaled_features", withStd=True, withMean=True)
scaled_df = scaler.fit(assembled_df).transform(assembled_df)

# MinMaxScaler (0-1 range)
minmax_scaler = MinMaxScaler(inputCol="features", outputCol="normalized_features")
normalized_df = minmax_scaler.fit(assembled_df).transform(assembled_df)
```

---

## Part 5: Building a Classification Model

### Step 5.1: Train-Test Split
```python
# Split data
train_df, test_df = assembled_df.randomSplit([0.8, 0.2], seed=42)

print(f"Training samples: {train_df.count()}")
print(f"Test samples: {test_df.count()}")
```

### Step 5.2: Logistic Regression
```python
from pyspark.ml.classification import LogisticRegression

# Create model
lr = LogisticRegression(
    featuresCol="features",
    labelCol="purchased",
    maxIter=100,
    regParam=0.01
)

# Train model
lr_model = lr.fit(train_df)

# Make predictions
predictions = lr_model.transform(test_df)
predictions.select("features", "purchased", "prediction", "probability").show(truncate=False)
```

### Step 5.3: Model Coefficients
```python
# View model parameters
print(f"Coefficients: {lr_model.coefficients}")
print(f"Intercept: {lr_model.intercept}")

# Feature importance
import pandas as pd

feature_names = ["age", "income", "num_children", "marital_index"]
coefficients = lr_model.coefficients.toArray()

importance_df = pd.DataFrame({
    "feature": feature_names,
    "coefficient": coefficients
}).sort_values("coefficient", ascending=False)

print(importance_df)
```

---

## Part 6: Model Evaluation

### Step 6.1: Binary Classification Metrics
```python
from pyspark.ml.evaluation import BinaryClassificationEvaluator, MulticlassClassificationEvaluator

# AUC-ROC
auc_evaluator = BinaryClassificationEvaluator(
    labelCol="purchased",
    rawPredictionCol="rawPrediction",
    metricName="areaUnderROC"
)
auc = auc_evaluator.evaluate(predictions)
print(f"AUC-ROC: {auc:.4f}")

# Accuracy
accuracy_evaluator = MulticlassClassificationEvaluator(
    labelCol="purchased",
    predictionCol="prediction",
    metricName="accuracy"
)
accuracy = accuracy_evaluator.evaluate(predictions)
print(f"Accuracy: {accuracy:.4f}")

# Precision, Recall, F1
for metric in ["precisionByLabel", "recallByLabel", "f1"]:
    evaluator = MulticlassClassificationEvaluator(
        labelCol="purchased",
        predictionCol="prediction",
        metricName=metric
    )
    print(f"{metric}: {evaluator.evaluate(predictions):.4f}")
```

### Step 6.2: Confusion Matrix
```python
# Calculate confusion matrix manually
confusion = predictions.groupBy("purchased", "prediction").count()
confusion.show()

# Pivot for matrix format
confusion_matrix = predictions.groupBy("purchased").pivot("prediction").count()
confusion_matrix.show()
```

---

## Part 7: Other Classification Algorithms

### Step 7.1: Decision Tree
```python
from pyspark.ml.classification import DecisionTreeClassifier

dt = DecisionTreeClassifier(
    featuresCol="features",
    labelCol="purchased",
    maxDepth=5
)

dt_model = dt.fit(train_df)
dt_predictions = dt_model.transform(test_df)

# Feature importance
print("Feature Importance:")
for i, importance in enumerate(dt_model.featureImportances):
    print(f"  {feature_names[i]}: {importance:.4f}")
```

### Step 7.2: Random Forest
```python
from pyspark.ml.classification import RandomForestClassifier

rf = RandomForestClassifier(
    featuresCol="features",
    labelCol="purchased",
    numTrees=100,
    maxDepth=5
)

rf_model = rf.fit(train_df)
rf_predictions = rf_model.transform(test_df)
```

### Step 7.3: Gradient Boosted Trees
```python
from pyspark.ml.classification import GBTClassifier

gbt = GBTClassifier(
    featuresCol="features",
    labelCol="purchased",
    maxIter=10
)

gbt_model = gbt.fit(train_df)
gbt_predictions = gbt_model.transform(test_df)
```

---

## Part 8: Regression Models

```python
# Create regression dataset
regression_data = [
    (1, 1500, 3, 2, 250000),
    (2, 2000, 4, 2, 350000),
    (3, 1200, 2, 1, 180000),
    (4, 2500, 4, 3, 450000),
    (5, 1800, 3, 2, 300000),
    (6, 3000, 5, 3, 550000),
    (7, 1400, 3, 1, 220000),
    (8, 2200, 4, 2, 380000),
]

house_df = spark.createDataFrame(
    regression_data,
    ["id", "sqft", "bedrooms", "bathrooms", "price"]
)

# Feature engineering
assembler = VectorAssembler(
    inputCols=["sqft", "bedrooms", "bathrooms"],
    outputCol="features"
)
house_features = assembler.transform(house_df)

# Linear Regression
from pyspark.ml.regression import LinearRegression

lr = LinearRegression(
    featuresCol="features",
    labelCol="price",
    maxIter=100
)

lr_model = lr.fit(house_features)

print(f"Coefficients: {lr_model.coefficients}")
print(f"Intercept: {lr_model.intercept}")
print(f"R-squared: {lr_model.summary.r2:.4f}")
print(f"RMSE: {lr_model.summary.rootMeanSquaredError:.2f}")
```

---

## Part 9: ML Pipelines

### Step 9.1: Create Pipeline
```python
from pyspark.ml import Pipeline

# Define pipeline stages
stages = [
    StringIndexer(inputCol="marital_status", outputCol="marital_index"),
    VectorAssembler(
        inputCols=["age", "income", "num_children", "marital_index"],
        outputCol="raw_features"
    ),
    StandardScaler(inputCol="raw_features", outputCol="features"),
    LogisticRegression(labelCol="purchased", featuresCol="features")
]

# Create pipeline
pipeline = Pipeline(stages=stages)

# Fit pipeline
pipeline_model = pipeline.fit(train_df)

# Transform
final_predictions = pipeline_model.transform(test_df)
final_predictions.select("id", "purchased", "prediction").show()
```

### Step 9.2: Pipeline Benefits
```
Advantages of Pipelines:
1. Reproducibility - Same preprocessing for train and test
2. Simplicity - Single object to fit and transform
3. Tuning - Can tune all stages together
4. Serialization - Save/load entire workflow
```

---

## Part 10: Hyperparameter Tuning

### Step 10.1: Parameter Grid
```python
from pyspark.ml.tuning import ParamGridBuilder, CrossValidator

# Create parameter grid
paramGrid = ParamGridBuilder() \
    .addGrid(lr.regParam, [0.01, 0.1, 1.0]) \
    .addGrid(lr.elasticNetParam, [0.0, 0.5, 1.0]) \
    .addGrid(lr.maxIter, [50, 100]) \
    .build()

print(f"Number of parameter combinations: {len(paramGrid)}")
```

### Step 10.2: Cross Validation
```python
# Create cross validator
crossval = CrossValidator(
    estimator=pipeline,
    estimatorParamMaps=paramGrid,
    evaluator=BinaryClassificationEvaluator(labelCol="purchased"),
    numFolds=3,
    seed=42
)

# Run cross validation
cv_model = crossval.fit(train_df)

# Best model
best_model = cv_model.bestModel
print(f"Best AUC: {max(cv_model.avgMetrics):.4f}")
```

---

## Part 11: Save and Load Models

```python
# Save pipeline model
pipeline_model.save("models/purchase_predictor")

# Load pipeline model
from pyspark.ml import PipelineModel
loaded_model = PipelineModel.load("models/purchase_predictor")

# Use loaded model
new_predictions = loaded_model.transform(test_df)
new_predictions.select("id", "prediction").show()
```

---

## Part 12: Complete ML Pipeline Example

```python
from pyspark.sql import SparkSession
from pyspark.ml import Pipeline
from pyspark.ml.feature import StringIndexer, VectorAssembler, StandardScaler
from pyspark.ml.classification import RandomForestClassifier
from pyspark.ml.evaluation import BinaryClassificationEvaluator
from pyspark.ml.tuning import ParamGridBuilder, CrossValidator

# Setup
spark = SparkSession.builder.appName("Complete ML").getOrCreate()

# Load data
df = spark.read.csv("data/customer_churn.csv", header=True, inferSchema=True)

# Train-test split
train, test = df.randomSplit([0.8, 0.2], seed=42)

# Define pipeline
pipeline = Pipeline(stages=[
    StringIndexer(inputCol="contract_type", outputCol="contract_idx"),
    StringIndexer(inputCol="payment_method", outputCol="payment_idx"),
    VectorAssembler(
        inputCols=["tenure", "monthly_charges", "total_charges", "contract_idx", "payment_idx"],
        outputCol="features"
    ),
    StandardScaler(inputCol="features", outputCol="scaled_features"),
    RandomForestClassifier(featuresCol="scaled_features", labelCol="churn")
])

# Hyperparameter tuning
paramGrid = ParamGridBuilder() \
    .addGrid(pipeline.getStages()[-1].numTrees, [50, 100]) \
    .addGrid(pipeline.getStages()[-1].maxDepth, [5, 10]) \
    .build()

crossval = CrossValidator(
    estimator=pipeline,
    estimatorParamMaps=paramGrid,
    evaluator=BinaryClassificationEvaluator(labelCol="churn"),
    numFolds=3
)

# Train
model = crossval.fit(train)

# Evaluate
predictions = model.transform(test)
auc = BinaryClassificationEvaluator(labelCol="churn").evaluate(predictions)
print(f"Test AUC: {auc:.4f}")

# Save
model.bestModel.save("models/churn_predictor")
```

---

## Exercises

1. Build a multi-class classifier for customer segments
2. Create a regression model to predict sales
3. Implement feature selection using ChiSqSelector
4. Compare multiple algorithms using cross-validation

---

## Summary
- MLlib uses Pipeline architecture
- Feature engineering with transformers
- Estimators train models
- Pipelines chain stages together
- Cross-validation for tuning
- Save/load models for production
