# Module 04: Database Administration

**Duration**: 2 weeks (40-60 hours)  
**Difficulty**: ⭐⭐⭐⭐ Advanced  
**Prerequisites**: Modules 00-03 complete  

---

## 📖 Module Overview

Master database administration fundamentals: design databases from business requirements, implement proper normalization, secure data with role-based access, backup/restore strategies, and automated maintenance.

**What You'll Build**: Production-ready database with security, backups, and monitoring.

---

## 🎯 Learning Objectives

By completing this module, you will:

✅ Design normalized databases (1NF through BCNF)  
✅ Implement backup and restore strategies  
✅ Configure security (logins, users, roles, permissions)  
✅ Create maintenance plans  
✅ Monitor database health and performance  
✅ Understand transaction logs and recovery models  
✅ Implement row-level security  
✅ Automate administrative tasks  

---

## 📚 Module Structure

| Section | Topic | Labs | Time | Difficulty |
|---------|-------|------|------|------------|
| 01 | Database Design Fundamentals | 2 | 5h | ⭐⭐⭐ |
| 02 | Normalization (1NF-BCNF) | 2 | 6h | ⭐⭐⭐⭐ |
| 03 | Backup and Recovery | 3 | 6h | ⭐⭐⭐⭐ |
| 04 | Security and Permissions | 3 | 7h | ⭐⭐⭐⭐⭐ |
| 05 | Transaction Logs and Recovery Models | 2 | 5h | ⭐⭐⭐⭐ |
| 06 | Maintenance Plans | 2 | 4h | ⭐⭐⭐ |
| 07 | Monitoring and Alerts | 2 | 5h | ⭐⭐⭐⭐ |
| 08 | Advanced Administration | 1 | 4h | ⭐⭐⭐⭐⭐ |
| **Total** | **8 sections** | **17 labs** | **42h** | - |

**Quizzes**: 2 (Week 1 + Week 2)  
**Capstone**: DBA project with security, backups, monitoring  

---

## 📂 Folder Structure

```
Module_04_Database_Administration/
├── README.md (this file)
├── 01_design_fundamentals.md
├── 02_normalization.md
├── 03_backup_recovery.md
├── 04_security.md
├── 05_transaction_logs.md
├── 06_maintenance_plans.md
├── 07_monitoring.md
├── 08_advanced_admin.md
├── labs/
│   ├── lab_20_design.sql
│   ├── lab_21_normalization.sql
│   ├── lab_22_backup_full.sql
│   ├── lab_23_backup_differential.sql
│   ├── lab_24_restore.sql
│   ├── lab_25_security_logins.sql
│   ├── lab_26_security_roles.sql
│   ├── lab_27_row_level_security.sql
│   ├── lab_28_transaction_logs.sql
│   ├── lab_29_recovery_models.sql
│   ├── lab_30_maintenance_plan.sql
│   ├── lab_31_index_maintenance.sql
│   ├── lab_32_monitoring.sql
│   ├── lab_33_alerts.sql
│   ├── lab_34_automation.sql
│   ├── lab_35_capstone.sql
├── solutions/
│   ├── lab_20_solution.sql
│   ├── lab_21_solution.sql
│   ├── [... other solutions]
├── quizzes/
│   ├── quiz_05_week1.md
│   ├── quiz_06_week2.md
└── MODULE_04_SUMMARY.md
```

---

## ⏱️ Learning Schedule

### **Option 1: Intensive (2 weeks full-time)**
- **Week 1**: Sections 1-4 (Design, Normalization, Backups, Security)  
  - Mon-Tue: Database design + normalization
  - Wed-Thu: Backup strategies
  - Fri: Security implementation
- **Week 2**: Sections 5-8 (Logs, Maintenance, Monitoring, Advanced)  
  - Mon: Transaction logs
  - Tue: Maintenance plans
  - Wed: Monitoring setup
  - Thu-Fri: Capstone project

### **Option 2: Part-Time (8 weeks, 5-7 hours/week)**
- **Weeks 1-2**: Database design and normalization
- **Weeks 3-4**: Backup and recovery strategies
- **Weeks 5-6**: Security and permissions
- **Weeks 7-8**: Maintenance and monitoring

### **Option 3: Self-Paced (10 weeks casual)**
- 1 section per week + labs
- Flexible schedule
- Focus on mastery over speed

---

## 🎓 Assessment Breakdown

| Component | Weight | Description |
|-----------|--------|-------------|
| Labs 20-34 | 40% | Hands-on exercises |
| Quiz 05 (Week 1) | 15% | Design, normalization, backups, security |
| Quiz 06 (Week 2) | 15% | Logs, maintenance, monitoring |
| Capstone Project | 30% | Complete DBA implementation |

**Passing Grade**: 70% overall

---

## 🔧 Tools & Resources

**Required**:
- SQL Server 2022 Express (installed in Module 01)
- SSMS 20.x
- AdventureWorks2022 database

**New Tools Introduced**:
- SQL Server Configuration Manager
- SQL Server Agent (jobs and alerts)
- Database Tuning Advisor
- Activity Monitor

**Documentation**:
- [SQL Server Backup and Restore](https://learn.microsoft.com/en-us/sql/relational-databases/backup-restore/)
- [SQL Server Security](https://learn.microsoft.com/en-us/sql/relational-databases/security/)
- [Maintenance Plans](https://learn.microsoft.com/en-us/sql/relational-databases/maintenance-plans/)

---

## ✅ Prerequisites Checklist

Before starting Module 04, ensure you have:

- [ ] Completed Module 03 with 70%+ score
- [ ] Can write complex queries with CTEs and window functions
- [ ] Understand execution plans and indexing
- [ ] Have AdventureWorks2022 database installed
- [ ] Can navigate SSMS Object Explorer
- [ ] Understand basic SQL Server architecture

---

## 🎯 Module Completion Criteria

To successfully complete Module 04, you must:

- [ ] Complete all 8 sections
- [ ] Finish 15+ labs (out of 17)
- [ ] Score 70%+ on both quizzes
- [ ] Complete capstone project (production-ready database)
- [ ] Demonstrate:
  - Database design skills (ERD to implementation)
  - Full + differential backup strategy
  - Role-based security implementation
  - Automated maintenance plan
  - Monitoring and alert configuration

---

## 💼 Career Impact

**Database Administrator**:
- Design production databases
- Implement backup/recovery plans
- Manage security and compliance
- Monitor database health

**Data Engineer**:
- Understand data storage design
- Implement secure data pipelines
- Configure automated maintenance
- Troubleshoot database issues

**BI Developer**:
- Design dimensional models
- Implement security for reports
- Optimize database performance
- Manage data warehouse backups

---

## 🚀 Success Metrics

After completing this module, you should be able to:

1. ✅ Design a normalized database from business requirements
2. ✅ Implement full, differential, and log backups
3. ✅ Restore database to point-in-time
4. ✅ Create logins, users, and role-based permissions
5. ✅ Configure automated maintenance plans
6. ✅ Monitor database health with Activity Monitor
7. ✅ Set up email alerts for critical events
8. ✅ Troubleshoot common DBA issues

---

**Let's master database administration!**  
**கற்க கசடற - Learn Flawlessly!** 🎯

---

**Start with**: [Section 01: Database Design Fundamentals →](./01_design_fundamentals.md)
