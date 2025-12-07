# Section 3: Assessment Framework

**Estimated Time**: 45 minutes

---

## 📊 Overview of Assessment Strategy

This curriculum uses a **multi-dimensional assessment approach** to ensure comprehensive skill development:

| Assessment Type | Weight | Frequency | Purpose |
|----------------|--------|-----------|---------|
| **Hands-On Labs** | 30% | Daily/Weekly | Validate technical implementation skills |
| **Module Quizzes** | 20% | End of each module | Test theoretical understanding |
| **Module Projects** | 25% | 1-2 per module | Apply skills to real-world scenarios |
| **Capstone Project** | 25% | Final 2 weeks | Demonstrate end-to-end proficiency |

**Passing Criteria**: 80% overall to earn certificate

---

## 1️⃣ Hands-On Labs (30%)

### What Are Labs?

Labs are **practical exercises** where you write SQL queries, build SSIS packages, or create Power BI reports. Each module contains 8-25 labs progressing from basic to advanced.

### Lab Structure

**Typical Lab Format**:
```
Lab 5: Customer Sales Analysis

Difficulty: ⭐⭐⭐ Intermediate
Estimated Time: 45 minutes
Database: AdventureWorks2022

Scenario:
The sales team needs a report showing top 10 customers by revenue in 2013,
including their total orders and average order value.

Tasks:
1. Write a query to calculate total revenue per customer
2. Rank customers by revenue using window functions
3. Filter to show only top 10
4. Include customer name, total orders, total revenue, average order value

Expected Output:
- 10 rows
- Columns: CustomerID, CustomerName, TotalOrders, TotalRevenue, AvgOrderValue, Rank

Bonus Challenge:
- Add year-over-year revenue comparison
```

### How Labs Are Graded

**Self-Paced Learning** (No Instructor):
- Solutions provided in `solutions/` folder
- Self-check using provided answer key
- Focus on understanding, not just matching output

**Instructor-Led Training**:
- Submit lab reports using template
- Instructor reviews code quality, logic, and best practices
- Feedback provided within 48 hours

**Grading Rubric** (Per Lab):

| Criteria | Excellent (100%) | Good (85%) | Needs Work (70%) | Insufficient (<70%) |
|----------|-----------------|------------|------------------|-------------------|
| **Correctness** | Query produces exact expected output | Minor discrepancies in formatting | Logic errors but shows understanding | Incorrect approach or non-functional |
| **Code Quality** | Clean, readable, well-commented | Readable but minimal comments | Hard to read, poor formatting | Spaghetti code, no structure |
| **Efficiency** | Optimal approach, uses indexes | Functional but suboptimal | Inefficient (scans, multiple passes) | Extremely slow or resource-intensive |
| **Best Practices** | Follows all conventions | Follows most conventions | Some anti-patterns | Violates multiple best practices |

### Lab Completion Requirements

**To pass labs for a module**:
- ✅ Complete all required labs (70%+ passing score per lab)
- ✅ Submit lab reports (if instructor-led)
- ⚠️ Optional/bonus labs are NOT required but boost learning

**Time Management**:
- **Module 02** (SQL Fundamentals): 25 labs × 30 min = ~12.5 hours
- **Module 06** (SSIS): 15 labs × 60 min = ~15 hours
- **Total Across Curriculum**: ~80-100 hours of lab work

---

## 2️⃣ Module Quizzes (20%)

### What Are Quizzes?

**Multiple-choice and short-answer assessments** testing your theoretical understanding of concepts covered in each module.

### Quiz Format

**Sample Questions**:

**Module 02 Quiz (SQL Fundamentals) - 20 Questions**

*Question 1: Multiple Choice*
```
Which join type returns all rows from the left table and matching rows from the right table?

A) INNER JOIN
B) LEFT JOIN ✅ (Correct Answer)
C) RIGHT JOIN
D) CROSS JOIN
```

*Question 2: Code Analysis*
```sql
SELECT p.ProductID, p.Name, SUM(sod.OrderQty) AS TotalSold
FROM Production.Product p
LEFT JOIN Sales.SalesOrderDetail sod ON p.ProductID = sod.ProductID
GROUP BY p.ProductID
ORDER BY TotalSold DESC;
```

```
What is wrong with this query?

A) LEFT JOIN should be INNER JOIN
B) GROUP BY is missing p.Name ✅ (Correct Answer)
C) ORDER BY cannot use alias
D) Nothing, query is correct
```

*Question 3: Short Answer*
```
Explain the difference between WHERE and HAVING clauses in SQL.

Sample Answer:
WHERE filters rows BEFORE grouping, while HAVING filters groups AFTER aggregation.
WHERE works on individual rows, HAVING works on grouped results.

Example:
WHERE Quantity > 10 (filters rows with Quantity > 10)
HAVING SUM(Quantity) > 100 (filters groups where total Quantity > 100)
```

### Quiz Grading

**Scoring**:
- Multiple choice: 1 point each (auto-graded)
- Short answer: 2-3 points each (instructor/self-graded with rubric)
- **Passing Score**: 80% (16/20 on typical quiz)

**Retake Policy**:
- **Self-Paced**: Unlimited retakes, but study before retaking!
- **Instructor-Led**: 1 retake allowed after reviewing incorrect answers with instructor

### Quiz Topics by Module

| Module | Quiz Topics | # Questions | Time Limit |
|--------|------------|-------------|------------|
| **01** | Installation, database concepts, SSMS navigation | 10 | 20 min |
| **02** | SELECT, WHERE, JOINs, aggregations, subqueries | 20 | 40 min |
| **03** | CTEs, window functions, execution plans, optimization | 20 | 45 min |
| **04** | Normalization, indexing, backup/recovery, security | 25 | 50 min |
| **05** | Stored procedures, functions, triggers, error handling | 20 | 45 min |
| **06** | SSIS architecture, control flow, data flow | 20 | 40 min |
| **07** | CDC, SCD, incremental loads, orchestration | 25 | 50 min |
| **08** | Data modeling, DAX, visualizations, deployment | 20 | 45 min |

**No quiz for Module 09** (evaluated via capstone project)

---

## 3️⃣ Module Projects (25%)

### What Are Module Projects?

**Mini-projects** that simulate real-world tasks, requiring you to apply multiple skills from the module. Unlike labs (which are single-concept exercises), projects are comprehensive.

### Project Examples

**Module 04 Project: E-Commerce Database Design**

**Scenario**:
You're hired as a database consultant for a startup e-commerce company. They need a database to manage products, customers, orders, and inventory.

**Requirements**:
1. Design normalized schema (3NF minimum)
2. Create Entity-Relationship (ER) diagram
3. Implement database with tables, relationships, and constraints
4. Create 5+ indexes based on expected query patterns
5. Write stored procedure for placing an order (with transactions)
6. Implement backup strategy (full + differential)
7. Document all design decisions

**Deliverables**:
- ER diagram (PDF or image)
- SQL script to create database
- Stored procedure scripts
- Backup/recovery documentation
- Design justification document (2-3 pages)

**Grading Rubric** (100 points total):
- Schema design and normalization (25 points)
- ER diagram quality (10 points)
- Implementation correctness (25 points)
- Index strategy (15 points)
- Stored procedure quality (15 points)
- Documentation clarity (10 points)

**Time Estimate**: 8-12 hours

---

**Module 07 Project: Incremental ETL Pipeline**

**Scenario**:
Build a production-ready ETL pipeline that incrementally loads sales data from an OLTP database to a data warehouse using Change Data Capture (CDC).

**Requirements**:
1. Enable CDC on source tables
2. Create dimension tables with SCD Type 2 (Customer, Product)
3. Create fact table (Sales)
4. Build SSIS packages:
   - Dimension load package (with SCD logic)
   - Fact table incremental load (CDC-based)
   - Master orchestration package
5. Implement error handling and logging
6. Test with sample data (insert, update, delete scenarios)
7. Document ETL workflow

**Deliverables**:
- SSIS packages (.dtsx files)
- SQL scripts (table creation, CDC setup)
- Test data scripts
- Architecture diagram
- ETL workflow documentation (5+ pages)

**Grading Rubric** (100 points total):
- CDC implementation (20 points)
- SCD Type 2 logic (25 points)
- Incremental fact load (20 points)
- Error handling (15 points)
- Testing and validation (10 points)
- Documentation (10 points)

**Time Estimate**: 12-16 hours

---

### Module Project Schedule

| Module | Project Title | Estimated Hours |
|--------|--------------|-----------------|
| **02** | Sales Analytics Report (Complex SQL) | 4-6 hours |
| **03** | Query Optimization Case Study | 4-6 hours |
| **04** | E-Commerce Database Design | 8-12 hours |
| **05** | Order Processing System (T-SQL) | 8-10 hours |
| **06** | Multi-Source Data Integration (SSIS) | 10-12 hours |
| **07** | Incremental ETL Pipeline | 12-16 hours |
| **08** | Executive Dashboard (Power BI) | 8-12 hours |
| **09** | Capstone (see Section 4) | 40-60 hours |

**Total**: ~94-134 hours of project work

---

## 4️⃣ Capstone Project (25%)

### Overview

The **capstone project** is your portfolio centerpiece - a **complete data warehouse solution** demonstrating all skills from Modules 01-08.

### Project Themes (Choose One)

**1. E-Commerce Analytics Platform**
- **OLTP Database**: Products, Orders, Customers, Shipments
- **Data Warehouse**: Sales analysis, customer segmentation, inventory trends
- **Power BI**: Executive dashboard, sales team reports

**2. Healthcare Operations Dashboard**
- **OLTP Database**: Patients, Appointments, Treatments, Billing
- **Data Warehouse**: Patient outcomes, department performance, revenue analysis
- **Power BI**: Hospital management dashboard

**3. Financial Services Data Warehouse**
- **OLTP Database**: Accounts, Transactions, Customers, Loans
- **Data Warehouse**: Customer profitability, transaction patterns, loan performance
- **Power BI**: Risk management dashboard

**4. Retail Chain Analytics**
- **OLTP Database**: Stores, Employees, Products, Sales, Inventory
- **Data Warehouse**: Store performance, product mix analysis, workforce analytics
- **Power BI**: Regional manager dashboard

**5. Custom Project** (Requires Approval)
- Must demonstrate equivalent complexity
- Instructor approval required (if applicable)

### Capstone Requirements

**Phase 1: Design (Week 1)**
- ✅ Business requirements document
- ✅ Dimensional model design (star schema)
- ✅ Architecture diagram
- ✅ ETL workflow design
- ✅ Dashboard mockups

**Phase 2: Implementation (Week 2)**
- ✅ OLTP database creation (operational system)
- ✅ Data warehouse creation (dimensional model)
- ✅ 5-10 SSIS packages (full ETL pipeline)
- ✅ Power BI semantic model
- ✅ 3-5 dashboard pages with 10+ visualizations

**Phase 3: Documentation & Presentation**
- ✅ Technical documentation (20+ pages)
- ✅ GitHub repository with README
- ✅ 15-minute project presentation (video or live)
- ✅ Demo of working solution

### Capstone Grading Rubric (250 points total)

| Category | Weight | Criteria |
|----------|--------|----------|
| **Database Design** | 20% (50 pts) | OLTP design, dimensional model, normalization, indexing |
| **ETL Implementation** | 30% (75 pts) | Package functionality, error handling, SCD/CDC, performance |
| **Power BI Dashboard** | 20% (50 pts) | Insights quality, visual design, DAX complexity, interactivity |
| **Documentation** | 15% (37.5 pts) | Clarity, completeness, architecture diagrams, code comments |
| **Presentation** | 10% (25 pts) | Communication, demo quality, Q&A handling |
| **Code Quality** | 5% (12.5 pts) | Best practices, reusability, maintainability |

**Passing Score**: 85% (212.5/250 points)

**Detailed Rubric Available**: See [Module 09 - Evaluation Rubric](../Module_09_Capstone/04_evaluation_rubric.md)

---

## 📅 Assessment Timeline

### Typical 16-Week Schedule

| Week | Module | Assessments Due |
|------|--------|-----------------|
| **Week 1** | Module 01 | Quiz 01 (end of week) |
| **Weeks 2-3** | Module 02 | Labs 1-25 (weekly), Quiz 02, Project 02 |
| **Weeks 4-5** | Module 03 | Labs 1-20 (weekly), Quiz 03, Project 03 |
| **Weeks 6-7** | Module 04 | Labs 1-15 (weekly), Quiz 04, Project 04 |
| **Weeks 8-9** | Module 05 | Labs 1-12 (weekly), Quiz 05, Project 05 |
| **Weeks 10-11** | Module 06 | Labs 1-15 (weekly), Quiz 06, Project 06 |
| **Weeks 12-13** | Module 07 | Labs 1-12 (weekly), Quiz 07, Project 07 |
| **Week 14** | Module 08 | Labs 1-10, Quiz 08, Project 08 |
| **Weeks 15-16** | Module 09 | Capstone Project (all deliverables) |

### Self-Paced Deadlines

**No strict deadlines**, but recommended pacing:
- Complete labs as you study (don't batch them)
- Take quiz immediately after completing module readings
- Start module project after passing quiz
- Don't move to next module until current one is 100% complete

---

## 🎯 Grading Philosophy

### Focus on Learning, Not Just Scores

**Our Approach**:
- ✅ **Mastery-Based**: Retake quizzes/labs until you demonstrate understanding
- ✅ **Feedback-Driven**: Learn from mistakes (solutions explained in detail)
- ✅ **Portfolio-Focused**: Build GitHub presence, not just grades
- ✅ **Real-World Aligned**: Assessments simulate actual job tasks

### Academic Honesty

**Allowed**:
- ✅ Use documentation (Microsoft Learn, Stack Overflow)
- ✅ Discuss concepts with peers (conceptual help)
- ✅ Review similar examples and adapt to your scenario
- ✅ Ask instructor/community for hints when stuck

**Not Allowed**:
- ❌ Copy-paste solutions from other students
- ❌ Submit AI-generated code without understanding
- ❌ Claim others' work as your own
- ❌ Share quiz answers or project code directly

**If You're Stuck**:
1. Review module readings and examples
2. Search official documentation
3. Ask specific questions in community forums
4. Request conceptual help (not full solutions)
5. Learn from solution after attempting (self-paced)

---

## 📊 Progress Tracking

### Recommended Tracking Sheet

Create a spreadsheet or use this template:

| Module | Labs Completed | Lab Avg Score | Quiz Score | Project Score | Status |
|--------|---------------|---------------|------------|---------------|--------|
| **01** | 5/5 | 95% | 90% | N/A | ✅ Complete |
| **02** | 18/25 | 88% | Pending | Pending | 🔄 In Progress |
| **03** | 0/20 | N/A | N/A | N/A | ⏸️ Not Started |
| ... | | | | | |

### Milestone Celebrations 🎉

**Celebrate these achievements:**
- ✅ Complete first module (Module 01)
- ✅ Write first complex SQL query (Module 02)
- ✅ Build first SSIS package (Module 06)
- ✅ Create first Power BI dashboard (Module 08)
- ✅ Complete capstone project (Module 09)

**Reward yourself**: Take a day off, share accomplishment on LinkedIn, treat yourself!

---

## 🏆 Final Certification Criteria

### Certificate of Completion Requirements

To earn the **Data Engineering Curriculum Certificate**, you must:

1. ✅ **Complete all labs** (70%+ average across all modules)
2. ✅ **Pass all quizzes** (80%+ score on each)
3. ✅ **Submit all module projects** (75%+ average)
4. ✅ **Complete capstone project** (85%+ score)
5. ✅ **Maintain 80%+ overall grade**

**Overall Grade Calculation**:
```
Overall Grade = (Labs × 30%) + (Quizzes × 20%) + (Module Projects × 25%) + (Capstone × 25%)

Example:
Labs: 88% → 88 × 0.30 = 26.4
Quizzes: 85% → 85 × 0.20 = 17.0
Module Projects: 82% → 82 × 0.25 = 20.5
Capstone: 90% → 90 × 0.25 = 22.5
OVERALL: 86.4% ✅ PASS
```

### Certificate Details

**Your certificate will include:**
- ✅ Full name and completion date
- ✅ Overall grade and distinction level
- ✅ Breakdown of modules completed
- ✅ Capstone project title
- ✅ Instructor signature (if applicable)
- ✅ Unique certificate ID (for verification)
- ✅ Digital badge for LinkedIn

**Distinction Levels**:
- **90-100%**: Certificate with High Distinction
- **85-89%**: Certificate with Distinction
- **80-84%**: Certificate of Completion

---

## 💡 Tips for Success

### Study Strategies

**1. Active Learning**
- Don't just read - type every query, run every example
- Modify examples to test your understanding
- Teach concepts to others (Feynman technique)

**2. Spaced Repetition**
- Review previous module concepts weekly
- Redo challenging labs after a week
- Create flashcards for key concepts

**3. Deliberate Practice**
- Focus on weaknesses (don't just repeat what you know)
- Time yourself on labs to simulate work pressure
- Attempt bonus challenges for extra practice

**4. Community Engagement**
- Share your learnings on LinkedIn
- Help others in forums (teaching reinforces learning)
- Join study groups or find an accountability partner

### Time Management

**Avoid These Pitfalls**:
- ❌ Cramming all labs at the end of a module
- ❌ Taking quiz before completing all labs
- ❌ Starting project before fully understanding concepts
- ❌ Skipping modules or rushing through content

**Best Practices**:
- ✅ Daily study habit (consistency > intensity)
- ✅ Complete labs as you learn concepts
- ✅ Take breaks to avoid burnout
- ✅ Review before quizzes and projects

---

## 📞 Getting Help

### When You're Struggling

**Lab/Quiz Help**:
1. Review module readings and examples
2. Check troubleshooting section in module README
3. Search Stack Overflow / Microsoft Learn
4. Ask in GitHub Discussions (link conceptual question, not full problem)
5. Request instructor office hours (if applicable)

**Technical Issues**:
1. Check Module 01 troubleshooting guide
2. Verify SQL Server service is running
3. Google exact error message
4. Post in SQL Server forums with full error details

**Mental Health**:
- It's normal to feel overwhelmed sometimes
- Take breaks when frustrated (walk away, come back fresh)
- Remember: everyone learns at different pace
- Reach out to instructor/community for encouragement

---

**Previous**: [← Prerequisites Checklist](./02_prerequisites_checklist.md) | **Next**: [Career Roadmap →](./04_career_roadmap.md)

---

*Last Updated: December 7, 2025*
