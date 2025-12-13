![Module 03 Header](../assets/images/module_03_header.svg)

# Module 03: Advanced SQL

**Duration**: 2 weeks (40-60 hours)  
**Difficulty**: ⭐⭐⭐⭐ Advanced  
**Prerequisites**: Module 02 (SQL Fundamentals) complete with 70%+ score

---

## 🎯 Module Overview

Master **advanced SQL techniques** used by professional data engineers. Learn CTEs, window functions, query optimization, execution plans, and performance tuning - essential skills for handling large-scale data operations.

---

## 📚 What You'll Learn

After completing this module, you will:
✅ Write recursive and non-recursive CTEs (Common Table Expressions)  
✅ Master window functions for advanced analytics  
✅ Optimize queries for performance  
✅ Read and understand execution plans  
✅ Design effective indexes  
✅ Handle hierarchical data  
✅ Write complex analytical queries  
✅ Apply query hints and optimization techniques  

---

## 📂 Module Structure

### 8 Sections | 20 Labs | 2 Quizzes | 1 Capstone Project

| Section | Topic | Labs | Time | Difficulty |
|---------|-------|------|------|------------|
| 01 | Common Table Expressions (CTEs) | 3 | 5h | ⭐⭐⭐ |
| 02 | Recursive CTEs | 2 | 4h | ⭐⭐⭐⭐ |
| 03 | Window Functions - Ranking | 3 | 6h | ⭐⭐⭐⭐ |
| 04 | Window Functions - Analytical | 3 | 6h | ⭐⭐⭐⭐⭐ |
| 05 | Query Optimization Basics | 2 | 5h | ⭐⭐⭐ |
| 06 | Execution Plans | 2 | 5h | ⭐⭐⭐⭐ |
| 07 | Indexing Strategies | 3 | 6h | ⭐⭐⭐⭐ |
| 08 | Advanced Techniques | 2 | 5h | ⭐⭐⭐⭐⭐ |
| **Total** | **8 Sections** | **20** | **42h** | **Advanced** |

---

## 📁 Folder Structure

```
Module_03_Advanced_SQL/
├── README.md                          (This file)
├── 01_ctes.md                         (Common Table Expressions)
├── 02_recursive_ctes.md               (Hierarchical queries)
├── 03_window_ranking.md               (ROW_NUMBER, RANK, DENSE_RANK)
├── 04_window_analytical.md            (LAG, LEAD, SUM OVER, etc.)
├── 05_query_optimization.md           (Performance basics)
├── 06_execution_plans.md              (Reading query plans)
├── 07_indexing.md                     (Clustered, nonclustered, covering)
├── 08_advanced_techniques.md          (Pivots, dynamic SQL, temp tables)
│
├── labs/
│   ├── lab_11_ctes.sql
│   ├── lab_12_recursive.sql
│   ├── lab_13_ranking.sql
│   ├── lab_14_window_functions.sql
│   ├── lab_15_optimization.sql
│   ├── lab_16_execution_plans.sql
│   ├── lab_17_indexes.sql
│   ├── lab_18_advanced.sql
│   └── lab_19_capstone.sql            (Comprehensive project)
│
├── solutions/
│   └── (Solution files for all labs)
│
└── quizzes/
    ├── quiz_03_week1.md               (Sections 1-4)
    └── quiz_04_week2.md               (Sections 5-8)
```

---

## 🎓 Learning Path

### Week 1: CTEs and Window Functions

**Days 1-2**: CTEs
- Non-recursive CTEs
- Multiple CTEs in one query
- CTE benefits vs subqueries

**Days 3-4**: Recursive CTEs
- Hierarchical data structures
- Organizational charts
- Bill of materials
- Graph traversal

**Days 5-7**: Window Functions
- ROW_NUMBER, RANK, DENSE_RANK, NTILE
- LAG, LEAD for time-series
- Running totals and moving averages
- PARTITION BY and ORDER BY

### Week 2: Performance & Optimization

**Days 8-10**: Query Optimization
- Query execution order
- Operator costs
- Statistics and cardinality
- Query hints

**Days 11-12**: Execution Plans
- Graphical plans
- Actual vs estimated
- Identifying bottlenecks
- Common anti-patterns

**Days 13-14**: Indexing & Advanced
- Clustered vs nonclustered
- Covering indexes
- Index maintenance
- PIVOT, UNPIVOT, temp tables

---

## 📊 Assessment Breakdown

| Component | Weight | Description |
|-----------|--------|-------------|
| **Labs (11-18)** | 40% | 8 hands-on labs with progressive difficulty |
| **Quiz 1** | 15% | 20 questions on CTEs & Window Functions |
| **Quiz 2** | 15% | 20 questions on Optimization & Indexing |
| **Capstone Project** | 30% | Complex analytical queries with optimization |
| **TOTAL** | **100%** | Pass = 70%+ |

---

## 🎯 Key Concepts

### Common Table Expressions (CTEs)
```sql
WITH SalesCTE AS (
    SELECT CustomerID, SUM(TotalDue) AS TotalSales
    FROM SalesLT.SalesOrderHeader
    GROUP BY CustomerID
)
SELECT * FROM SalesCTE WHERE TotalSales > 5000;
```

### Window Functions
```sql
SELECT 
    CustomerID,
    OrderDate,
    TotalDue,
    ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY OrderDate) AS OrderNumber,
    SUM(TotalDue) OVER (PARTITION BY CustomerID ORDER BY OrderDate) AS RunningTotal
FROM SalesLT.SalesOrderHeader;
```

### Execution Plan Analysis
- Identify table scans vs index seeks
- Measure operator costs
- Find missing index recommendations
- Optimize JOIN operations

---

## 💡 Study Tips

### For Beginners to Advanced SQL:
1. **Build on Module 02**: CTEs are like named subqueries
2. **Visualize**: Draw diagrams for recursive CTEs
3. **Practice window functions**: They're initially confusing but powerful
4. **Use sample data**: AdventureWorks is perfect for learning

### For Experienced Programmers:
1. **Think set-based**: Avoid row-by-row processing
2. **Profile first**: Measure before optimizing
3. **Read execution plans**: They reveal SQL Server's strategy
4. **Index wisely**: Over-indexing hurts writes

### For Database Professionals:
1. **CTEs vs Temp Tables**: Know when to use each
2. **Window functions**: Replace self-joins and cursors
3. **Statistics matter**: Keep them updated
4. **Test with production volumes**: Small data hides problems

---

## 🔧 Tools & Resources

**SQL Server Management Studio (SSMS)**:
- Execution plan viewer (Ctrl+M)
- Query statistics (Ctrl+Shift+S)
- Database Tuning Advisor
- Index recommendations

**AdventureWorks2022** (Full version):
- 70+ tables (more complex than LT version)
- 120K+ sales order details
- Hierarchical data (organizational chart)
- Real-world complexity

---

## 📖 Recommended Reading Order

1. **Section 01**: CTEs - Start here, builds on subqueries
2. **Section 02**: Recursive CTEs - Mind-bending but powerful
3. **Section 03**: Window Ranking - Most commonly used
4. **Section 04**: Window Analytical - Advanced analytics
5. **Section 05**: Optimization - Theory before practice
6. **Section 06**: Execution Plans - See optimization in action
7. **Section 07**: Indexing - Physical performance tuning
8. **Section 08**: Advanced Techniques - Miscellaneous power tools

---

## ⏱️ Time Estimates

**Full-Time Learner** (8 hours/day):
- Week 1: Sections 1-4 + Labs + Quiz 1
- Week 2: Sections 5-8 + Labs + Quiz 2 + Capstone
- **Total**: 2 weeks

**Part-Time Learner** (2 hours/day):
- Weeks 1-4: Sections 1-4 + Labs
- Weeks 5-8: Sections 5-8 + Labs + Quizzes + Capstone
- **Total**: 8 weeks

**Self-Paced Casual**:
- 1 section per week + lab
- 2 weeks for capstone
- **Total**: 10 weeks

---

## ✅ Prerequisites Checklist

Before starting Module 03:

- [ ] Completed Module 02 with 70%+ score
- [ ] Comfortable with JOINs (all types)
- [ ] Understand subqueries
- [ ] Can write GROUP BY queries
- [ ] Familiar with aggregate functions
- [ ] AdventureWorks2022 (FULL version) installed
- [ ] SSMS configured to show execution plans

---

## 🚀 Module Completion Criteria

To pass Module 03, you must:

- [ ] Complete all 8 section readings
- [ ] Complete Labs 11-18 (8 labs)
- [ ] Score 70%+ on Quiz 1 (CTEs & Window Functions)
- [ ] Score 70%+ on Quiz 2 (Optimization & Indexing)
- [ ] Complete Capstone Project (Lab 19) with 70%+
- [ ] Demonstrate query optimization skills
- [ ] Read and interpret execution plans

---

## 🎁 What You'll Build

**Lab 19 Capstone**: Sales Performance Dashboard
- Customer segmentation using window functions
- Recursive category hierarchy
- Year-over-year growth analysis
- Top N analysis with CTEs
- Optimized queries with proper indexes
- Execution plan analysis and tuning

Real-world skills applicable to:
- Business intelligence reporting
- Data warehousing
- Analytics engineering
- Database performance tuning

---

## 🆘 Getting Help

**Stuck on a concept?**
1. Re-read the section (concepts build on each other)
2. Review Module 02 fundamentals
3. Check solution files AFTER attempting
4. Draw diagrams for recursive CTEs
5. Practice with smaller datasets first

**Performance issues?**
1. Check execution plans first
2. Verify statistics are updated
3. Look for missing indexes
4. Avoid SELECT *
5. Use appropriate indexes

---

## 📈 Career Impact

**Skills from Module 03** translate to:

**Data Engineer**: 
- Optimize ETL queries for large datasets
- Design efficient data pipelines
- Tune warehouse performance

**BI Developer**:
- Create complex analytical queries
- Build performant dashboards
- Handle hierarchical dimensions

**Database Administrator**:
- Tune query performance
- Design indexing strategies
- Troubleshoot slow queries

**Analytics Engineer**:
- Write efficient transformations
- Implement incremental processing
- Optimize dbt models

---

## 🎯 Success Metrics

After Module 03, you should be able to:

✅ Replace complex subqueries with CTEs  
✅ Calculate running totals without self-joins  
✅ Rank results within groups  
✅ Traverse hierarchical data structures  
✅ Identify query bottlenecks in execution plans  
✅ Design effective indexes  
✅ Optimize queries for 10x+ performance gains  
✅ Write production-ready analytical SQL  

---

## 🔜 Next Steps

After completing Module 03:

→ **Module 04**: Database Administration (Design, Normalization, Security)  
→ **Module 05**: T-SQL Programming (Stored Procedures, Functions, Triggers)  
→ **Module 06**: ETL with SSIS (Integration Services)

---

## 🔗 Navigation

| Direction | Link |
|-----------|------|
| ⬅️ Previous | [Module 02: SQL Fundamentals](../Module_02_SQL_Fundamentals/) |
| ➡️ Next | [Module 04: Database Administration](../Module_04_Database_Administration/) |
| 🏠 Home | [Main Curriculum](../README.md) |
| 📚 Resources | [Study Materials](../Resources/) |

---

*கற்க கசடற - Learn Flawlessly!*

**Ready to level up your SQL skills? Let's begin! →** [Section 01: CTEs](./01_ctes.md)
