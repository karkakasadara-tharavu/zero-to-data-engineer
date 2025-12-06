![Module 01 Header](../assets/images/module_01_header.svg)

# Module 01: SQL Server Installation & Setup

**Duration**: 2 days (6-8 hours total)  
**Difficulty**: ⭐ Beginner  
**Prerequisites**: Windows 10/11, Admin rights, 20GB free disk space

---

## 🎯 Module Overview

Welcome to your first hands-on module! By the end of this module, you'll have a **fully functional SQL Server development environment** ready for learning. We'll install every tool step-by-step, verify everything works, and ensure you're 100% ready to start writing SQL queries.

**What You'll Install**:
1. ✅ SQL Server 2022 Express Edition (Free database engine)
2. ✅ SQL Server Management Studio (SSMS) - Your SQL IDE
3. ✅ AdventureWorks2022 Sample Database - Practice database
4. ✅ AdventureWorksLT2022 - Lightweight version for quick tests

**Why This Module Matters**:
- ❌ **Without proper setup**: You'll face errors, frustration, and delays
- ✅ **With this guide**: Smooth installation, verified environment, confidence to learn

---

## 📚 Module Contents

| Section | Document | Estimated Time | Type |
|---------|----------|----------------|------|
| 1 | [SQL Server Installation](./01_sql_server_installation.md) | 90 min | Hands-On |
| 2 | [SSMS Setup Guide](./02_ssms_setup_guide.md) | 45 min | Hands-On |
| 3 | [AdventureWorks Setup](./03_adventureworks_setup.md) | 60 min | Hands-On |
| 4 | [Verification Tests](./04_verification_tests.sql) | 30 min | Hands-On |
| 5 | [Troubleshooting Guide](./05_troubleshooting.md) | Reference | Reading |

**Total Time**: 4-5 hours (including downloads)

---

## 🎓 Learning Objectives

By completing this module, you will be able to:

✅ **Installation Skills**
- Install SQL Server Express 2022 in standalone mode
- Configure SQL Server authentication modes
- Understand SQL Server services and their purposes
- Install SQL Server Management Studio (SSMS)

✅ **Database Fundamentals**
- Connect to SQL Server using SSMS
- Understand database files (.mdf, .ldf) and their roles
- Restore databases from backup (.bak) files
- Navigate SSMS Object Explorer

✅ **Environment Setup**
- Verify SQL Server installation with diagnostic queries
- Test database connectivity
- Configure SSMS for optimal productivity
- Troubleshoot common installation issues

✅ **Confidence Building**
- Feel comfortable with SQL Server environment
- Know where to find help when stuck
- Ready to start writing SQL queries in Module 02

---

## 🛠️ What We're Installing

### SQL Server 2022 Express Edition

**What It Is**: 
A free, lightweight version of Microsoft SQL Server database engine. Perfect for learning, development, and small applications.

**Key Features**:
- Full SQL Server functionality (T-SQL, stored procedures, triggers, etc.)
- Supports up to 10 GB database size per database (plenty for learning!)
- No licensing costs or restrictions
- Same engine as expensive Enterprise edition (just with size limits)

**What You CAN Do**:
- ✅ Learn all SQL Server features
- ✅ Build and test applications
- ✅ Use for small production apps (up to 10GB)
- ✅ Connect with SSMS, Visual Studio, Azure Data Studio

**What You CANNOT Do**:
- ❌ Scale beyond 10GB per database (upgrade to Standard/Enterprise if needed)
- ❌ Use advanced features like AlwaysOn Availability Groups
- ❌ Exceed 1 socket or 4 cores (performance limits)

**Perfect for**: Students, developers, consultants, small businesses

---

### SQL Server Management Studio (SSMS)

**What It Is**: 
Free integrated environment (IDE) for managing SQL Server databases. Think of it as "Visual Studio Code for databases."

**Key Features**:
- ✅ IntelliSense (auto-complete for SQL)
- ✅ Query editor with syntax highlighting
- ✅ Visual database designer
- ✅ Execution plan analyzer (performance tuning)
- ✅ Backup/restore wizards
- ✅ Security management tools

**Why We Love It**:
- Industry-standard tool (used by professionals worldwide)
- Free and powerful (better than paid alternatives)
- Constantly updated by Microsoft
- Tons of tutorials and community support

---

### AdventureWorks Sample Databases

**What It Is**: 
Microsoft's official sample database representing a fictional bicycle manufacturing company. Used in official documentation and certifications.

**Why It's Perfect for Learning**:
- ✅ **Realistic data**: Sales, products, customers, employees, manufacturing
- ✅ **Well-designed schema**: Proper normalization, relationships, indexes
- ✅ **Variety of scenarios**: Simple to complex queries possible
- ✅ **Industry-standard**: Used in Microsoft exams and courses
- ✅ **Free and safe**: No licensing issues, safe to experiment

**Two Versions**:
1. **AdventureWorks2022** (Full): ~45 MB, 70+ tables, complete business scenario
2. **AdventureWorksLT2022** (Lightweight): ~1 MB, 10 tables, simplified version

**We'll install both** - full version for deep learning, lightweight for quick tests.

---

## 📋 Pre-Installation Checklist

Before you begin, verify these requirements:

### System Requirements

| Requirement | Minimum | Recommended | How to Check |
|-------------|---------|-------------|--------------|
| **Operating System** | Windows 10 (64-bit) | Windows 11 | Settings → System → About |
| **RAM** | 4 GB | 8 GB or more | Task Manager → Performance |
| **Free Disk Space** | 6 GB | 20 GB | File Explorer → This PC |
| **Processor** | 1.4 GHz | 2.0 GHz or faster | Task Manager → Performance → CPU |
| **Admin Rights** | Required | Required | Try opening cmd as admin |
| **.NET Framework** | 4.7.2 or higher | Latest | Auto-installed with Windows Updates |

**Check Your System** (PowerShell):
```powershell
# Run this in PowerShell to see your system info
Get-ComputerInfo | Select-Object WindowsVersion, OsArchitecture, CsTotalPhysicalMemory, CsNumberOfLogicalProcessors

# Check free disk space
Get-PSDrive C | Format-Table Name, Used, Free -AutoSize
```

---

### Software to Uninstall (If Present)

**Before installing SQL Server 2022**, check if you have older versions installed:

1. Press `Win + R`, type `appwiz.cpl`, press Enter
2. Look for:
   - SQL Server 2019 (or older)
   - SQL Server Management Studio 18.x (or older)

**Should You Uninstall?**
- ✅ **YES** if you're a beginner (avoid conflicts)
- ⚠️ **NO** if you need older version for work (they can coexist, but requires careful configuration)

**For This Curriculum**: We recommend a **clean installation** of SQL Server 2022.

---

### Download Checklist

**Before starting, download these files** (saves time during installation):

| File | Size | Download Link | Purpose |
|------|------|---------------|---------|
| SQL Server 2022 Express | ~1.5 GB | [Link in Section 1](./01_sql_server_installation.md) | Database engine |
| SSMS 20.x | ~900 MB | [Link in Section 2](./02_ssms_setup_guide.md) | Management tool |
| AdventureWorks2022.bak | ~45 MB | [Link in Section 3](./03_adventureworks_setup.md) | Sample database |
| AdventureWorksLT2022.bak | ~1 MB | [Link in Section 3](./03_adventureworks_setup.md) | Lightweight sample |

**Total Download**: ~2.5 GB (budget 30-60 minutes on typical internet)

---

## 🚀 Installation Sequence

Follow this exact order for smoothest setup:

```
Step 1: SQL Server 2022 Express     (Section 1) → 60-90 minutes
   ↓
Step 2: Reboot (if prompted)         → 5 minutes
   ↓
Step 3: SQL Server Management Studio (Section 2) → 30-45 minutes
   ↓
Step 4: Connect and Test             (Section 2) → 10 minutes
   ↓
Step 5: Restore AdventureWorks       (Section 3) → 30-45 minutes
   ↓
Step 6: Run Verification Tests       (Section 4) → 15-30 minutes
   ↓
Step 7: Configure SSMS Settings      (Section 2) → 15 minutes
   ↓
✅ DONE! Ready for Module 02!
```

---

## 💡 Tips for Success

### During Installation

**Do's** ✅
- Read each step carefully before clicking "Next"
- Take screenshots if you're unsure (for troubleshooting later)
- Keep default settings unless guide says otherwise
- Wait for each step to complete (no rushing!)
- Verify at each checkpoint before proceeding

**Don'ts** ❌
- Don't skip steps or assume "it's probably fine"
- Don't change advanced settings unless you know what they do
- Don't close installer windows prematurely
- Don't ignore error messages (screenshot them!)
- Don't panic if something goes wrong (troubleshooting guide is here!)

---

### Common Concerns Addressed

**Q: "I'm not technical. Can I really do this?"**  
A: **Absolutely!** This guide is written for beginners. We explain every step, every screenshot, every option. Thousands have successfully installed SQL Server with less detailed guides than this.

**Q: "What if I make a mistake?"**  
A: SQL Server Express is **free** - you can uninstall and reinstall as many times as needed. We also have a comprehensive troubleshooting section.

**Q: "Will this slow down my computer?"**  
A: SQL Server services use ~200-500 MB RAM when running. You can stop the services when not using them (we'll show you how).

**Q: "Can I install this on a work laptop?"**  
A: Check with your IT department first. Some companies restrict software installations. Alternatively, use a personal computer or virtual machine.

**Q: "I have SQL Server 2019. Do I need to upgrade?"**  
A: **No**, SQL Server 2019 works fine for this curriculum. But 2022 has improvements and is what this guide covers.

---

## 🆘 Getting Help

### If You Get Stuck

**Step-by-step Help Strategy**:

1. **Read Error Message Carefully**
   - Screenshot it (Win + Shift + S)
   - Google the exact error code
   - Check our [Troubleshooting Guide](./05_troubleshooting.md)

2. **Check Installation Logs**
   - Located at: `C:\Program Files\Microsoft SQL Server\160\Setup Bootstrap\Log\Summary.txt`
   - Look for "Failed" or "Error" keywords

3. **Search Online**
   - Google: `[your error] SQL Server 2022 Express installation`
   - Check: Microsoft Docs, Stack Overflow, Reddit r/SQLServer

4. **Ask for Help**
   - [GitHub Discussions](https://github.com/karkakasadara-tharavu/zero-to-data-engineer/discussions)
   - Include: Windows version, error message, screenshots
   - What you've already tried

5. **Start Fresh (Last Resort)**
   - Uninstall SQL Server completely
   - Reboot
   - Follow guide from beginning

---

### Support Resources

**Official Microsoft Resources**:
- SQL Server Installation Guide: https://learn.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server
- SSMS Documentation: https://learn.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms
- AdventureWorks Setup: https://learn.microsoft.com/en-us/sql/samples/adventureworks-install-configure

**Community Forums**:
- Microsoft Q&A: https://learn.microsoft.com/en-us/answers/tags/134/sql-server
- Stack Overflow: https://stackoverflow.com/questions/tagged/sql-server
- Reddit: r/SQLServer

**Karka Kasadara Community**:
- GitHub Discussions: [Link to your discussions]
- GitHub Issues: https://github.com/karkakasadara-tharavu/zero-to-data-engineer/issues

---

## ✅ Module Completion Checklist

Before moving to Module 02, ensure you've completed:

- [ ] Downloaded all required installers
- [ ] Installed SQL Server 2022 Express successfully
- [ ] SQL Server service is running (verified in Services)
- [ ] Installed SQL Server Management Studio (SSMS)
- [ ] Connected to SQL Server in SSMS (localhost or server name)
- [ ] Restored AdventureWorks2022 database
- [ ] Restored AdventureWorksLT2022 database
- [ ] Ran all verification tests in Section 4 (all passed)
- [ ] Configured SSMS preferences (optional but recommended)
- [ ] Bookmarked troubleshooting guide for future reference

**Completion Indicator**: You should be able to:
- Open SSMS
- Connect to your SQL Server instance
- See AdventureWorks2022 database in Object Explorer
- Run a simple query: `SELECT * FROM Person.Person`
- See results without errors

**If all checked** ✅ → **Congratulations! You're ready for [Module 02: SQL Fundamentals](../Module_02_SQL_Fundamentals/README.md)!**

---

## 🎯 What's Next?

**Module 02 Preview**:
After completing this setup, you'll dive into SQL fundamentals:
- Writing your first SELECT statements
- Filtering data with WHERE clause
- Joining tables to combine data
- Aggregating data for reports
- 25+ hands-on labs with AdventureWorks

**Time Investment**: 
- Module 01 (Setup): 6-8 hours
- Module 02 (SQL Basics): 2 weeks (40-60 hours)

**You're taking the first step in an amazing journey. Let's make you awesome!** 🚀

---

## 📸 Screenshots Folder

This module includes detailed screenshots for every step. If screenshots are missing, refer to:
- [Screenshot Placeholders Guide](./screenshots/PLACEHOLDER_INSTRUCTIONS.md)
- Official Microsoft documentation (links in each section)

---

**Ready to begin? Start with [Section 1: SQL Server Installation →](./01_sql_server_installation.md)**

---

*Last Updated: December 7, 2025*  
*Maintained by: Karka Kasadara - Learn Flawlessly, Grow Together*
