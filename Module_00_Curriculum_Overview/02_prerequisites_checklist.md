# Section 2: Prerequisites Checklist

**Estimated Time**: 30 minutes

---

## ✅ Self-Assessment Guide

Rate yourself honestly on each prerequisite using this scale:

- ✅ **Strong** (4-5): I'm confident and have practical experience
- ⚠️ **Moderate** (2-3): I understand concepts but need more practice
- ❌ **Weak** (0-1): New to this or very limited knowledge

**Scoring**: To start this curriculum comfortably, aim for 70%+ (35/50 points).

---

## 1️⃣ Technical Prerequisites

### A. Basic Computer Skills (Required: 4/5)

| Skill | Rating (0-5) | Notes |
|-------|-------------|-------|
| Navigate Windows file system and folders | __ / 5 | |
| Install and uninstall software | __ / 5 | |
| Manage system resources (disk space, task manager) | __ / 5 | |
| Use web browsers and download files | __ / 5 | |
| Take screenshots and create documents | __ / 5 | |

**Subtotal**: __ / 25

**If you scored <15**: Review Windows basics tutorials on YouTube

---

### B. Programming Fundamentals (Required: 3/5)

| Concept | Rating (0-5) | Notes |
|---------|-------------|-------|
| Variables and data types (string, integer, boolean) | __ / 5 | |
| Conditional logic (if/else statements) | __ / 5 | |
| Loops (for, while) | __ / 5 | |
| Functions/procedures (calling and passing parameters) | __ / 5 | |
| Basic debugging (finding and fixing errors) | __ / 5 | |

**Subtotal**: __ / 25

**If you scored <15**: Take a free programming fundamentals course:
- **FreeCodeCamp** - JavaScript Basics: https://www.freecodecamp.org/
- **Python for Everybody** (Coursera): https://www.coursera.org/specializations/python
- **C Programming** (YouTube - Neso Academy): https://youtube.com/playlist?list=PLBlnK6fEyqRggZZgYpPMUxdY1CYkZtARR

---

### C. Relational Database Concepts (Required: 2/5)

| Concept | Rating (0-5) | Notes |
|---------|-------------|-------|
| Understand what a table, row, and column are | __ / 5 | |
| Know what a primary key is | __ / 5 | |
| Understand foreign keys and relationships | __ / 5 | |
| Basic SQL (SELECT, WHERE) | __ / 5 | |
| Understand data types (INT, VARCHAR, DATE) | __ / 5 | |

**Subtotal**: __ / 25

**If you scored <10**: Pre-study resources:
- **Khan Academy SQL**: https://www.khanacademy.org/computing/computer-programming/sql
- **SQLBolt Interactive Tutorial**: https://sqlbolt.com/
- **W3Schools SQL Tutorial**: https://www.w3schools.com/sql/

---

### D. Microsoft Excel Skills (Helpful but not required)

| Skill | Rating (0-5) | Notes |
|-------|-------------|-------|
| Create formulas (SUM, AVERAGE, IF) | __ / 5 | |
| Use filters and sorts | __ / 5 | |
| Understand pivot tables | __ / 5 | |
| Work with multiple sheets | __ / 5 | |
| Import/export CSV files | __ / 5 | |

**Subtotal**: __ / 25

**If you scored <10**: Excel will help you understand data concepts, but it's not required. Consider:
- **Excel Basics** (Microsoft Learn): https://support.microsoft.com/en-us/office/excel-for-windows-training

---

## 2️⃣ Hardware & Software Requirements

### Minimum System Requirements

| Component | Minimum | Recommended | Your System | ✅/❌ |
|-----------|---------|-------------|-------------|------|
| **Operating System** | Windows 10 (64-bit) | Windows 11 | | |
| **Processor** | Dual-core 2.0 GHz | Quad-core 2.5+ GHz | | |
| **RAM** | 4 GB | 8 GB or more | | |
| **Free Disk Space** | 20 GB | 50 GB or more | | |
| **Display** | 1280x720 | 1920x1080 or higher | | |
| **Internet** | Stable connection | High-speed (for downloads) | | |
| **Admin Rights** | Required | Required | | |

**How to Check Your System**:

```powershell
# Run in PowerShell to check your system
Get-ComputerInfo | Select-Object CsName, OsName, OsArchitecture, CsNumberOfProcessors, CsTotalPhysicalMemory

# Check free disk space
Get-PSDrive C | Select-Object Used, Free
```

**If your system doesn't meet minimums**:
- **RAM < 4 GB**: Consider upgrading RAM or using cloud-based SQL Azure
- **Disk < 20 GB**: Free up space or add external drive
- **No admin rights**: Contact IT department or use personal machine

---

### Software Checklist

Ensure you can install the following (detailed guides in Module 01):

| Software | Required? | Your Status | Notes |
|----------|-----------|-------------|-------|
| SQL Server Express 2022 | ✅ Required | ☐ Can install | ~1.5 GB |
| SQL Server Management Studio | ✅ Required | ☐ Can install | ~900 MB |
| SQL Server Data Tools (SSDT) | ✅ Required | ☐ Can install | ~5-8 GB |
| Power BI Desktop | ✅ Required | ☐ Can install | ~700 MB |
| Visual Studio Code | ⚠️ Optional | ☐ Can install | ~200 MB |
| Git for Windows | ⚠️ Optional | ☐ Can install | ~300 MB |

**Total Installation Size**: ~10-15 GB

**Installation Blockers?**
- **Corporate firewall**: May need IT approval for installations
- **Antivirus blocking**: Temporarily disable during installation
- **Windows S Mode**: Must disable S Mode to install desktop apps

---

## 3️⃣ Time Commitment Requirements

### Study Time Availability

**How many hours per week can you dedicate to learning?**

| Study Pattern | Hours/Week | Completion Time | Your Plan |
|---------------|-----------|----------------|-----------|
| **Full-Time** (Career switcher) | 35-40 hours | 8-10 weeks | ☐ |
| **Part-Time** (Working professional) | 20-25 hours | 14-16 weeks | ☐ |
| **Casual** (Exploratory learning) | 10-15 hours | 28-32 weeks | ☐ |
| **Weekend-Only** | 8-12 hours | 30-40 weeks | ☐ |

**Weekly Study Plan Template**:

**Full-Time Schedule** (40 hours/week):
```
Monday-Friday: 6-8 hours/day
- Morning: Video lectures + theory (2-3 hours)
- Afternoon: Hands-on labs (3-4 hours)
- Evening: Practice and review (1 hour)
Weekend: Optional catch-up or projects
```

**Part-Time Schedule** (20 hours/week):
```
Weekdays: 2-3 hours/day (early morning or evening)
- Theory and demos (1 hour)
- Labs and practice (1-2 hours)
Weekend: 8-10 hours
- Saturday: Deep work on module content (4-5 hours)
- Sunday: Labs and projects (4-5 hours)
```

**Casual Schedule** (10 hours/week):
```
Weekdays: 1 hour/day
- Focused learning (theory OR labs)
Weekend: 5-6 hours
- Catch up on labs and practice
```

---

## 4️⃣ Learning Style & Expectations

### Self-Assessment Questions

**Answer honestly - there are no wrong answers!**

1. **How do you learn best?**
   - ☐ Hands-on practice (kinesthetic learner)
   - ☐ Reading and following written instructions
   - ☐ Watching video demonstrations
   - ☐ A mix of all three

   **Curriculum Fit**: This curriculum emphasizes hands-on labs with written guides. Video resources are linked but not primary.

2. **How do you handle frustration?**
   - ☐ I debug independently and enjoy problem-solving
   - ☐ I try for a while, then seek help from forums/communities
   - ☐ I prefer instructor guidance when stuck
   - ☐ I get discouraged easily and need encouragement

   **Curriculum Fit**: Self-paced learners should be comfortable with independent problem-solving. Each module has troubleshooting sections, but instructor-led cohorts are better if you need frequent guidance.

3. **Do you have a support network?**
   - ☐ I have mentor/instructor access
   - ☐ I'm part of an online community (Discord, Reddit)
   - ☐ I have peers learning with me
   - ☐ I'm learning completely alone

   **Recommendation**: If alone, join r/dataengineering or SQL Server forums ASAP!

4. **What's your goal?**
   - ☐ Career change to data engineering
   - ☐ Upskill for current job
   - ☐ Personal interest/hobby
   - ☐ Academic requirement

   **Curriculum Fit**: Designed for career changers and upskilling professionals. Adjust pace based on urgency.

---

## 5️⃣ English Language Proficiency

### Reading Comprehension

| Skill | Rating (0-5) | Notes |
|-------|-------------|-------|
| Read and understand technical documentation | __ / 5 | |
| Follow step-by-step instructions | __ / 5 | |
| Understand error messages and troubleshoot | __ / 5 | |

**Required**: 3/5 or higher

**If struggling**: Use translation tools (Google Translate), consider translated SQL resources in your language

---

## 6️⃣ Professional Background

### Educational Background

Which describes you best?

- ☐ **BE/BTech in Computer Science/IT** → Perfect fit, you'll progress quickly
- ☐ **BE/BTech in other engineering** (Mechanical, Civil, Electrical) → Good fit, expect steeper learning curve in weeks 1-3
- ☐ **BSc in Mathematics/Statistics** → Great fit for analytics, may need extra programming practice
- ☐ **Non-technical degree** → Achievable! Allocate extra time for fundamentals
- ☐ **Self-taught/Bootcamp graduate** → Assess programming prerequisites carefully

### Work Experience

| Experience Type | Relevance to Curriculum |
|----------------|------------------------|
| **Software Development** | ✅ High - programming skills transfer well |
| **Database Administration** | ✅ High - will accelerate through Modules 04-05 |
| **Data Analysis/Excel Power User** | ⚠️ Moderate - understand data concepts, need programming |
| **IT Support/System Admin** | ⚠️ Moderate - technical aptitude helps |
| **Business Analyst** | ⚠️ Moderate - domain knowledge helps with scenarios |
| **No IT experience** | ⚠️ Lower - plan for longer timeline and extra study |

---

## 📊 Final Scoring & Recommendation

### Calculate Your Readiness Score

| Category | Your Score | Possible |
|----------|-----------|----------|
| **Technical Prerequisites** | __ | 75 |
| **Hardware/Software** | __ (5 points per ✅) | 25 |
| **Time Availability** | __ (10 if realistic plan) | 10 |
| **Learning Style Fit** | __ (10 if good fit) | 10 |
| **English Proficiency** | __ (out of 15) | 15 |
| **TOTAL** | __ | 135 |

### Readiness Assessment

**90-135 points (67%+)**: ✅ **Ready to Start Immediately**
- You have strong fundamentals and resources to succeed
- Proceed to Module 01 with confidence
- Join community forums for support

**60-89 points (45-66%)**: ⚠️ **Conditional Start**
- Identify your weakest areas from scoring above
- Spend 1-2 weeks on pre-learning resources (linked in each section)
- Consider pairing with a study buddy or mentor
- Start with Module 01 but expect slower pace initially

**Below 60 points (<45%)**: ⏸️ **Pre-Learning Recommended**
- Invest 4-6 weeks in foundational skills:
  - **Week 1-2**: Programming fundamentals (Python or JavaScript)
  - **Week 3-4**: SQL basics (SQLBolt, Khan Academy)
  - **Week 5-6**: Database concepts (YouTube - Database Design Course)
- Retake this assessment after pre-learning
- You WILL succeed, just need more preparation time!

---

## 🎯 Gap-Filling Resources

### Programming Fundamentals (If scored <15/25)

**Free Courses**:
1. **CS50's Introduction to Computer Science** (Harvard): https://cs50.harvard.edu/x/
2. **Python for Everybody** (University of Michigan): https://www.py4e.com/
3. **JavaScript Basics** (FreeCodeCamp): https://www.freecodecamp.org/

**Time Required**: 20-40 hours

---

### SQL Basics (If scored <10/25)

**Interactive Tutorials**:
1. **SQLBolt** (Free, interactive): https://sqlbolt.com/
2. **Khan Academy SQL**: https://www.khanacademy.org/computing/computer-programming/sql
3. **W3Schools SQL**: https://www.w3schools.com/sql/
4. **LeetCode SQL** (Practice): https://leetcode.com/studyplan/top-sql-50/

**Time Required**: 15-30 hours

---

### Database Concepts (If scored <10/25)

**Video Courses**:
1. **Database Design Course** (freeCodeCamp - 4 hours): https://www.youtube.com/watch?v=ztHopE5Wnpc
2. **Relational Database Basics** (Khan Academy): https://www.khanacademy.org/computing/computer-programming/sql

**Time Required**: 10-20 hours

---

## ✅ Action Plan Template

Based on your assessment, create your personalized action plan:

### My Readiness Score: ______ / 135

### My Weak Areas (Need Improvement):
1. ___________________________________
2. ___________________________________
3. ___________________________________

### My Pre-Learning Plan (If needed):
**Weeks 1-2**: _______________________________
**Weeks 3-4**: _______________________________
**Week 5-6**: _______________________________

### My Study Schedule:
**Weekdays**: _____ hours/day (from __:__ to __:__)
**Weekends**: _____ hours/day (from __:__ to __:__)
**Total**: _____ hours/week

**Expected Completion Date**: ___________________

### My Support Network:
- ☐ Joined r/dataengineering
- ☐ Joined SQL Server community forums
- ☐ Found study buddy: ______________
- ☐ Have mentor/instructor: ______________

### My Accountability:
I commit to dedicating _____ hours/week to this curriculum.
I will track my progress weekly and adjust as needed.
I understand this is a marathon, not a sprint.

**Signed**: ____________________
**Date**: ______________________

---

## 🚀 Ready to Start?

If your readiness score is 60+, you're ready for Module 01!

**Next Steps**:
1. ✅ Complete this checklist
2. ✅ Set up study schedule in your calendar
3. ✅ Prepare workspace (quiet environment, dual monitors if possible)
4. ✅ Bookmark key resources
5. ✅ Join at least one community forum
6. ➡️ **Proceed to [Module 01: SQL Server Setup](../Module_01_SQL_Server_Setup/README.md)**

---

**Previous**: [← Learning Objectives](./01_learning_objectives.md) | **Next**: [Assessment Framework →](./03_assessment_framework.md)

---

*Last Updated: December 7, 2025*
