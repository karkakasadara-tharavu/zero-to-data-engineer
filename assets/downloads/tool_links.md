# 📦 Software & Tools Download Links

Quick reference for all required and optional tools used throughout this curriculum.

**Last Updated**: December 7, 2025

---

## ✅ Required Downloads

### 1. SQL Server Express 2022 (Free Edition)

**What it is**: Lightweight, free database server perfect for learning and development.

**Download Link**: https://www.microsoft.com/en-us/sql-server/sql-server-downloads

**Version to Download**: SQL Server 2022 Express Edition

**Installation Size**: ~1.5 GB

**Key Features**:
- Full database engine
- 10 GB max database size (sufficient for learning)
- Supports all core SQL Server features
- No licensing cost

**Official Documentation**: https://learn.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server

---

### 2. SQL Server Management Studio (SSMS)

**What it is**: Free IDE for managing SQL Server databases.

**Download Link**: https://learn.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms

**Latest Version**: SSMS 20.x (December 2025)

**Direct Download**: https://aka.ms/ssmsfullsetup

**Installation Size**: ~900 MB

**Key Features**:
- Query editor with IntelliSense
- Object Explorer for database navigation
- Execution plan visualization
- Backup/restore wizards

**System Requirements**:
- Windows 10 or later (64-bit)
- .NET Framework 4.7.2 or later
- Minimum 4 GB RAM (8 GB recommended)

---

### 3. AdventureWorks Sample Database

**What it is**: Microsoft's official sample database representing a fictional bicycle company.

**Why AdventureWorks?**
- Realistic business data (sales, products, customers, HR)
- Well-designed schema with proper relationships
- Includes ~70 tables with various complexity levels
- Used in official Microsoft documentation

**Download Options**:

**Option A: Direct Download (Recommended)**
- **AdventureWorks2022.bak**: https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2022.bak
- File Size: ~45 MB
- Restore as a backup file in SSMS

**Option B: Lightweight Version**
- **AdventureWorksLT2022.bak**: https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorksLT2022.bak
- File Size: ~1 MB
- Simplified version with fewer tables (good for beginners)

**Option C: GitHub Repository**
- Full Scripts: https://github.com/Microsoft/sql-server-samples/tree/master/samples/databases/adventure-works
- Contains OLTP and Data Warehouse versions

**Installation Guide**: See Module 01 - Section 03

---

### 4. SQL Server Data Tools (SSDT) - For SSIS

**What it is**: Visual Studio extension for building ETL packages (SSIS), databases, and reports.

**Download Link**: https://learn.microsoft.com/en-us/sql/ssdt/download-sql-server-data-tools-ssdt

**What to Install**:
- SQL Server Integration Services (SSIS)
- SQL Server Reporting Services (SSRS) - Optional
- SQL Server Analysis Services (SSAS) - Optional

**Alternative**: Visual Studio 2022 Community Edition
- Download: https://visualstudio.microsoft.com/downloads/
- Select "Data storage and processing" workload during installation
- Completely free for individual developers and students

**Installation Size**: ~5-8 GB (with Visual Studio)

**Required For**: Modules 06-07 (ETL & SSIS)

---

### 5. Power BI Desktop

**What it is**: Free business intelligence tool for creating reports and dashboards.

**Download Link**: https://www.microsoft.com/en-us/download/details.aspx?id=58494

**Latest Version**: December 2025 release

**Microsoft Store Option**: https://aka.ms/pbidesktopstore
- Automatically updates
- Recommended for Windows 10/11 users

**Installation Size**: ~700 MB

**Key Features**:
- Data modeling and transformation
- 100+ visualizations
- DAX formula language
- Direct SQL Server connectivity

**Required For**: Module 08 (Power BI Reporting)

**License**: Free for desktop use, Power BI Pro ($10/month) needed only for sharing to cloud

---

## 🔧 Optional but Recommended Tools

### 6. Azure Data Studio

**What it is**: Modern, cross-platform database tool with notebook support.

**Download Link**: https://learn.microsoft.com/en-us/azure-data-studio/download-azure-data-studio

**Why Use It?**
- Jupyter-style notebooks for SQL
- Cross-platform (Windows, macOS, Linux)
- Git integration
- Extensions marketplace

**When to Use**: Alternative to SSMS for specific tasks, especially notebooks

---

### 7. Git for Version Control

**What it is**: Version control system for tracking code changes.

**Download Link**: https://git-scm.com/downloads

**Why It's Useful**:
- Track changes to SQL scripts
- Collaborate with others
- Required for GitHub workflow
- Industry-standard tool

**GitHub Desktop (GUI Option)**: https://desktop.github.com/

---

### 8. Visual Studio Code

**What it is**: Lightweight code editor with SQL extensions.

**Download Link**: https://code.visualstudio.com/

**Recommended Extensions**:
- SQL Server (mssql) by Microsoft
- SQL Formatter
- Rainbow CSV (for data file viewing)

**When to Use**: Quick SQL script editing, markdown documentation

---

## 📊 Additional Sample Databases (Optional)

### WideWorldImporters

**Description**: Modern sample database with advanced features.

**Download**: https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0

**Use Case**: Advanced scenarios, JSON data, temporal tables

---

### Northwind Database

**Description**: Classic sample database (older but simple).

**Download**: https://github.com/microsoft/sql-server-samples/tree/master/samples/databases/northwind-pubs

**Use Case**: Simple schema for quick practice

---

## 💻 System Requirements Summary

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **OS** | Windows 10 (64-bit) | Windows 11 |
| **RAM** | 4 GB | 8 GB or more |
| **Storage** | 20 GB free | 50 GB free (for all tools + databases) |
| **CPU** | Dual-core | Quad-core or better |
| **Display** | 1280x720 | 1920x1080 (for Power BI) |
| **Internet** | Required for downloads | Stable connection for cloud features |

---

## 🚀 Installation Order (Recommended)

Follow this sequence for smoothest setup:

1. **SQL Server Express** (30-45 min)
   - Reboot may be required

2. **SQL Server Management Studio** (15-20 min)
   - No reboot needed

3. **AdventureWorks Database** (5-10 min)
   - Restore backup in SSMS

4. **Visual Studio / SSDT** (60-90 min)
   - Large download, do when you start Module 06

5. **Power BI Desktop** (10-15 min)
   - Can install anytime before Module 08

6. **Git / VS Code** (10 min each)
   - Optional but recommended early on

**Total Setup Time**: 2-3 hours (with breaks)

---

## 🆘 Troubleshooting Download Issues

### SQL Server Express Won't Install
- **Solution**: Check Windows version (must be 64-bit)
- Install all Windows Updates first
- Disable antivirus temporarily during installation

### SSMS Download Fails
- **Alternative Link**: https://aka.ms/ssmsfullsetup
- Try Microsoft Edge browser
- Check available disk space

### AdventureWorks Restore Errors
- **Solution**: Verify SQL Server service is running
- Check file permissions on backup file
- See Module 01 detailed troubleshooting guide

### Power BI Won't Start
- **Solution**: Update graphics drivers
- Install from Microsoft Store instead
- Check .NET Framework 4.7.2 is installed

---

## 📱 Mobile / Cloud Alternatives

### Power BI Mobile
- **iOS**: https://apps.apple.com/app/microsoft-power-bi/id929738808
- **Android**: https://play.google.com/store/apps/details?id=com.microsoft.powerbim

### Azure Data Studio (macOS/Linux)
- **macOS**: https://learn.microsoft.com/en-us/azure-data-studio/download-azure-data-studio#macos
- **Linux**: https://learn.microsoft.com/en-us/azure-data-studio/download-azure-data-studio#linux

---

## 🔐 License Information

All tools listed are **free for educational and development use**:

- ✅ SQL Server Express: Free forever, no license needed
- ✅ SSMS: Free, no restrictions
- ✅ Visual Studio Community: Free for students and individual developers
- ✅ Power BI Desktop: Free for local use
- ✅ Sample Databases: Open source, no license

**Note**: Commercial use of some tools (Visual Studio, Power BI Pro) may require paid licenses.

---

## 📞 Support Resources

- **SQL Server Forums**: https://learn.microsoft.com/en-us/answers/tags/134/sql-server
- **Power BI Community**: https://community.powerbi.com/
- **Stack Overflow**: https://stackoverflow.com/questions/tagged/sql-server
- **GitHub Issues**: Report curriculum-specific issues in this repository

---

*Last verified: December 7, 2025*
*Links checked and updated monthly*
