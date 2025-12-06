# Module 09: Capstone Project

**Duration**: 4 weeks (80-100 hours) | **Difficulty**: ⭐⭐⭐⭐⭐ Expert

---

## 🎯 Project Overview

Build a complete **end-to-end data engineering solution** integrating all skills from Modules 00-08:

1. Design dimensional data warehouse
2. Build ETL pipelines with SSIS
3. Implement database administration
4. Create Power BI executive dashboard
5. Deploy and document solution

---

## 📋 Project Requirements

### Phase 1: Database Design (Week 1 - 20 hours)

**Deliverables**:
1. **Dimensional Model**:
   - 1 Fact table (FactSales)
   - 4 Dimension tables (DimCustomer, DimProduct, DimDate, DimGeography)
   - Star schema diagram
   
2. **Source Systems**:
   - 2-3 transactional databases (OLTP)
   - Sample data (10K+ rows per table)
   
3. **DDL Scripts**:
   - Table creation with constraints
   - Indexes (clustered + nonclustered)
   - Foreign key relationships

**Schema Example**:
```sql
-- Fact Table
CREATE TABLE FactSales (
    SalesKey INT IDENTITY(1,1) PRIMARY KEY,
    DateKey INT NOT NULL,
    CustomerKey INT NOT NULL,
    ProductKey INT NOT NULL,
    Quantity INT,
    UnitPrice DECIMAL(10,2),
    TotalAmount DECIMAL(10,2),
    FOREIGN KEY (DateKey) REFERENCES DimDate(DateKey),
    FOREIGN KEY (CustomerKey) REFERENCES DimCustomer(CustomerKey),
    FOREIGN KEY (ProductKey) REFERENCES DimProduct(ProductKey)
);

-- Dimension Table with SCD Type 2
CREATE TABLE DimCustomer (
    CustomerKey INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL, -- Business key
    CustomerName NVARCHAR(100),
    City NVARCHAR(50),
    State NVARCHAR(50),
    StartDate DATETIME2 DEFAULT GETDATE(),
    EndDate DATETIME2 DEFAULT '9999-12-31',
    IsCurrent BIT DEFAULT 1
);
```

---

### Phase 2: ETL Implementation (Week 2 - 30 hours)

**Deliverables**:
1. **Dimension Load Packages** (SSIS):
   - DimCustomer (SCD Type 2)
   - DimProduct (SCD Type 1)
   - DimDate (date table generation)
   - DimGeography

2. **Fact Load Package**:
   - Incremental load (watermark pattern)
   - Lookup transformations for surrogate keys
   - Aggregate calculations

3. **Master Orchestration Package**:
   - Load dimensions in parallel
   - Load fact after dimensions complete
   - Error handling and logging

4. **CDC Configuration**:
   - Enable CDC on source tables
   - Extract changes only

**ETL Features**:
- Error handling (redirect bad rows)
- Logging (row counts, execution time)
- Variables and configurations
- Parameterized connections (dev/prod)

---

### Phase 3: Database Administration (Week 3 - 15 hours)

**Deliverables**:
1. **Security Implementation**:
   - 3 roles: Admin, Analyst, Reporting
   - Row-level security on DimCustomer
   - Login/user creation scripts

2. **Backup Strategy**:
   - Full backup (weekly)
   - Differential backup (daily)
   - Transaction log backup (hourly)
   - Test restore procedure

3. **Maintenance Plan**:
   - Index rebuild (weekly)
   - Statistics update (daily)
   - DBCC CHECKDB (weekly)
   - SQL Agent jobs

4. **Monitoring**:
   - DMV queries for performance
   - Alerts for failures
   - Database mail setup

---

### Phase 4: Power BI Dashboard (Week 3 - 20 hours)

**Deliverables**:
1. **Data Model**:
   - Connect to data warehouse
   - Verify relationships (star schema)
   - Create date table

2. **DAX Measures** (15+ measures):
   ```dax
   Total Sales = SUM(FactSales[TotalAmount])
   Sales YTD = TOTALYTD([Total Sales], DimDate[Date])
   Sales Growth % = 
       DIVIDE([Total Sales] - [Sales LY], [Sales LY], 0)
   Top 10 Products = 
       CALCULATE([Total Sales], TOPN(10, ALL(DimProduct), [Total Sales]))
   ```

3. **Dashboard Pages** (3-5 pages):
   - **Executive Summary**: KPI cards, YTD vs LY, trends
   - **Sales Analysis**: By product, region, customer segment
   - **Customer Analysis**: Lifetime value, cohort analysis
   - **Product Performance**: Top/bottom products, category trends
   - **Drill-Through**: Transaction details

4. **Features**:
   - Slicers (date, region, product category)
   - Drill-down/drill-through
   - Tooltips with details
   - Bookmarks for navigation
   - Row-level security

---

### Phase 5: Documentation (Week 4 - 10 hours)

**Deliverables**:
1. **Architecture Diagram**:
   - Source systems → ETL → Data warehouse → Power BI
   - Data flow diagram

2. **Technical Documentation**:
   - Database schema (ERD)
   - ETL process documentation (each package)
   - DAX measure definitions
   - Security setup

3. **User Guide**:
   - How to use dashboard
   - Filters and navigation
   - Report descriptions

4. **Deployment Guide**:
   - Step-by-step installation
   - Configuration settings
   - Troubleshooting

5. **Performance Metrics**:
   - ETL execution times
   - Row counts
   - Dashboard load time

---

### Phase 6: Presentation (Week 4 - 5 hours)

**Deliverables**:
1. **Video Walkthrough** (15-20 minutes):
   - Project overview
   - Demo of ETL process
   - Dashboard walkthrough
   - Technical highlights

2. **GitHub Repository**:
   - Well-organized folder structure
   - README with project description
   - All scripts and documentation
   - Screenshots

---

## 📊 Evaluation Rubric (100 Points)

### Design Quality (20 points)
- [ ] Proper star schema (5 pts)
- [ ] Normalized dimensions (5 pts)
- [ ] Appropriate indexes (5 pts)
- [ ] Constraints and relationships (5 pts)

### ETL Implementation (30 points)
- [ ] SCD Type 2 working correctly (8 pts)
- [ ] Incremental load implemented (7 pts)
- [ ] Error handling and logging (5 pts)
- [ ] CDC or change detection (5 pts)
- [ ] Master package orchestration (5 pts)

### Database Administration (15 points)
- [ ] Security properly configured (5 pts)
- [ ] Backup strategy tested (5 pts)
- [ ] Maintenance plan working (3 pts)
- [ ] Monitoring setup (2 pts)

### Power BI Dashboard (20 points)
- [ ] Data model correct (4 pts)
- [ ] 15+ DAX measures (6 pts)
- [ ] 3+ dashboard pages (5 pts)
- [ ] Interactive features (3 pts)
- [ ] Row-level security (2 pts)

### Documentation (10 points)
- [ ] Architecture diagram (2 pts)
- [ ] Technical documentation (3 pts)
- [ ] User guide (2 pts)
- [ ] Deployment guide (2 pts)
- [ ] Performance metrics (1 pt)

### Presentation (5 points)
- [ ] Clear video walkthrough (3 pts)
- [ ] GitHub repository organized (2 pts)

---

## 🚀 Success Criteria

**Minimum Requirements** (70% to pass):
- Functional data warehouse with 4 dimensions + 1 fact
- Working ETL pipeline loading all tables
- SCD Type 2 on at least one dimension
- Basic security and backup implemented
- Power BI dashboard with 10+ visuals
- Complete documentation

**Excellence** (90%+):
- Incremental loads with CDC
- Advanced DAX (time intelligence, complex calculations)
- Automated maintenance with alerts
- Professional dashboard design
- Comprehensive documentation with diagrams

---

## 📚 Suggested Timeline

**Week 1**: Design schema, create tables, generate sample data  
**Week 2**: Build all SSIS packages, test ETL  
**Week 3**: Security, backups, maintenance + Start Power BI  
**Week 4**: Complete dashboard, documentation, video

---

## 💼 Career Impact

**Portfolio Project**: Showcase on GitHub and LinkedIn  
**Interview Topics**: Explain design decisions, ETL strategies, performance tuning  
**Job Titles**: Data Engineer, BI Developer, ETL Developer, Database Administrator  
**Expected Salary**: $65K-$95K (entry), $95K-$130K (2-3 years experience)

---

**கற்க கசடற - You've Learned Flawlessly!** 🎉

**Congratulations on completing the Karka Kasadara Data Engineering Curriculum!**

---

## 📖 Resources

- [GitHub Repository](https://github.com/karkakasadara-tharavu/zero-to-data-engineer)
- [Report Issues](https://github.com/karkakasadara-tharavu/zero-to-data-engineer/issues)
- [Job Search Guide](../Module_00_Curriculum_Overview/04_career_roadmap.md)
- [Resume Template](../assets/templates/resume_template.md)

---

**Next Steps**: Update resume → Build portfolio → Start job search → Join data engineering community!
