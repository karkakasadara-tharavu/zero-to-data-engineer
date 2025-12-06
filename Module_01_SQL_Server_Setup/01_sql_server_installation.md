# Section 1: SQL Server 2022 Express Installation

**Estimated Time**: 60-90 minutes (including download)  
**Difficulty**: ⭐ Beginner  
**Result**: Fully functional SQL Server database engine

---

## 📥 Step 1: Download SQL Server 2022 Express

### Official Download Link

**Primary Source** (Microsoft Official):  
🔗 https://www.microsoft.com/en-us/sql-server/sql-server-downloads

**Direct Download Link** (December 2025):  
🔗 https://go.microsoft.com/fwlink/p/?linkid=2216019

### What You're Downloading

- **File Name**: `SQL2022-SSWEB-Expr.exe` (small web installer, ~5 MB)
- **Purpose**: This downloads the actual installer during installation
- **Alternative**: Advanced users can download offline ISO (~1.5 GB) from same page

### Download Instructions

1. **Visit the official page** (link above)
2. **Scroll down** to "Express" edition section
3. **Click "Download now"** button
4. **Save to Downloads folder** (or location you'll remember)

<!-- 🎨 PLACEHOLDER: Screenshot showing SQL Server download page with Express edition highlighted -->

**⏱️ Wait Time**: 1-2 minutes (small file)

**✅ Verification**: Check your Downloads folder for `SQL2022-SSWEB-Expr.exe` (~5 MB)

---

## 🚀 Step 2: Run the Installer

### Launch Installation

1. **Navigate to Downloads folder**
2. **Right-click** `SQL2022-SSWEB-Expr.exe`
3. **Select "Run as administrator"** (important!)
4. **Click "Yes"** when Windows asks for permission

<!-- 🎨 PLACEHOLDER: Screenshot of right-click menu showing "Run as administrator" -->

**Why Administrator?** SQL Server installs Windows services that require admin rights.

**🛑 If Blocked by Antivirus**: Temporarily disable antivirus (remember to re-enable later!)

---

## 📦 Step 3: Choose Installation Type

The installer will present **three installation options**:

### Option 1: Basic ⭐ **RECOMMENDED FOR BEGINNERS**

**What It Does**:
- Installs SQL Server with default settings
- Fastest setup (minimal user input)
- Perfect for learning and development
- Can configure advanced settings later

**When to Choose**: 
- ✅ You're new to SQL Server
- ✅ You want to start learning quickly
- ✅ You're using this for development/learning (not production)

**We recommend this for the curriculum.**

---

### Option 2: Custom

**What It Does**:
- Lets you customize installation location
- Choose specific features to install
- Configure advanced options during setup

**When to Choose**:
- You need SQL Server on a different drive (D:, E:, etc.)
- You want to select specific components
- You're comfortable with technical configurations

---

### Option 3: Download Media

**What It Does**:
- Downloads offline installer (ISO file)
- Install later or on offline machine
- Useful for multiple installations

**When to Choose**:
- You need to install on a machine without internet
- You want to keep installer for future use

---

### Our Choice: **Basic Installation**

**Click the "Basic" button** to proceed.

<!-- 🎨 PLACEHOLDER: Screenshot showing three installation options with Basic highlighted -->

---

## 📜 Step 4: Accept License Terms

1. **Read the license agreement** (or scroll to bottom)
2. **Check the box**: "I accept the license terms"
3. **Click "Accept"** or "Continue"

<!-- 🎨 PLACEHOLDER: Screenshot of license agreement screen -->

**Note**: SQL Server Express is free - no hidden costs or license fees!

---

## 📂 Step 5: Choose Installation Location

### Default Location (Recommended)

**Default Path**: `C:\Program Files\Microsoft SQL Server`

**Disk Space Required**: 
- Minimum: 6 GB
- Recommended: 10 GB (for logs and data)

### Custom Location (Optional)

**When to Change**:
- ❌ Not enough space on C: drive
- ✅ You have faster SSD on another drive
- ✅ Corporate policy requires specific location

**How to Change**:
1. Click "Browse" or "Change" button
2. Select different drive/folder
3. Ensure path has **no special characters** or spaces

**For This Guide**: We'll use the **default location**.

**Click "Install"** to proceed.

<!-- 🎨 PLACEHOLDER: Screenshot showing installation location selection -->

---

## ⏳ Step 6: Download and Installation Progress

### What Happens Now

The installer will:
1. **Download SQL Server files** (~1.5 GB) - takes 10-30 min depending on internet speed
2. **Extract files** to temporary location
3. **Install SQL Server components** - takes 15-30 min
4. **Configure services and security**
5. **Finalize installation**

**Total Time**: 30-60 minutes (be patient!)

### Progress Indicators

You'll see several stages:

**Stage 1: Downloading** (30-50%)
- Progress bar shows download status
- File size: ~1.5 GB
- ☕ Good time for a coffee break!

<!-- 🎨 PLACEHOLDER: Screenshot of download progress -->

**Stage 2: Installing** (50-90%)
- Files being copied and configured
- Several components installed:
  - Database Engine
  - SQL Browser
  - Integration Services (basic)
  - Client connectivity

**Stage 3: Finalizing** (90-100%)
- Services being configured
- Firewall rules added
- Registry entries created

### ⚠️ Important: Don't Close the Installer!

**Do NOT**:
- ❌ Close the installer window
- ❌ Restart your computer
- ❌ Put computer to sleep
- ❌ Disconnect internet during download

**DO**:
- ✅ Let it run to completion
- ✅ Keep computer plugged in (if laptop)
- ✅ Keep internet connected
- ✅ Wait patiently (grab lunch/coffee!)

---

## ✅ Step 7: Installation Complete

### Success Screen

When installation completes, you'll see:
- ✅ **Green checkmark** or "Installation completed successfully"
- **Server Name**: Usually `localhost\SQLEXPRESS` or your computer name
- **Instance Name**: `SQLEXPRESS`
- **Installation Summary** button (to view details)

<!-- 🎨 PLACEHOLDER: Screenshot of successful installation screen -->

### Important Information to Note

**Copy these details** (you'll need them to connect):

| Setting | Value | Purpose |
|---------|-------|---------|
| **Server Name** | `localhost\SQLEXPRESS` or `YOUR-PC-NAME\SQLEXPRESS` | Connection string |
| **Instance Name** | `SQLEXPRESS` | Named instance identifier |
| **Service Name** | `SQL Server (SQLEXPRESS)` | Windows service name |
| **Authentication Mode** | **Windows Authentication** (default) | How you'll log in |

**Save this info** in Notepad or take a screenshot!

---

## 🔍 Step 8: Verify SQL Server Services

### Check Services Are Running

**Method 1: Using Services App** (Recommended)

1. Press `Win + R` to open Run dialog
2. Type `services.msc` and press Enter
3. Scroll down to find:
   - **SQL Server (SQLEXPRESS)** - Should say "Running"
   - **SQL Server Browser** - May be "Stopped" (that's OK for now)

<!-- 🎨 PLACEHOLDER: Screenshot of Services window showing SQL Server running -->

**If SQL Server (SQLEXPRESS) is not running**:
1. Right-click on it
2. Select "Start"
3. Wait for status to change to "Running"

---

**Method 2: Using PowerShell** (Alternative)

```powershell
# Run in PowerShell to check SQL Server service status
Get-Service -Name "MSSQL$SQLEXPRESS" | Select-Object Name, Status, StartType

# Expected Output:
# Name                Status  StartType
# ----                ------  ---------
# MSSQL$SQLEXPRESS    Running Automatic
```

**Expected Output**:
- Status: **Running** ✅
- StartType: **Automatic** (starts with Windows)

---

### What These Services Do

**SQL Server (SQLEXPRESS)**:
- The actual database engine
- **Must be running** to connect and query data
- Uses ~200-500 MB RAM when idle

**SQL Server Browser**:
- Helps client tools find SQL Server instances
- Optional for named instances
- We'll enable it later if needed

---

## 🧪 Step 9: Test Connection (Command Line)

Before installing SSMS, let's verify SQL Server responds to commands.

### Using SQLCMD (Command-Line Tool)

**SQLCMD** is installed with SQL Server - it's a simple way to test connectivity.

**Open Command Prompt**:
1. Press `Win + R`
2. Type `cmd` and press Enter

**Run this command**:
```cmd
sqlcmd -S localhost\SQLEXPRESS -E
```

**Explanation**:
- `sqlcmd`: SQL Server command-line tool
- `-S localhost\SQLEXPRESS`: Server name (your instance)
- `-E`: Use Windows Authentication (your current login)

**Expected Output**:
```
1>
```

**If you see `1>` prompt** → ✅ **SUCCESS! SQL Server is running and responding!**

<!-- 🎨 PLACEHOLDER: Screenshot of cmd window showing successful sqlcmd connection -->

**Test a Query**:
```sql
SELECT @@VERSION
GO
```

**Expected Output**: Shows SQL Server version information
```
Microsoft SQL Server 2022 (RTM) - 16.0.1000.6 (X64) 
...
(1 rows affected)
```

**Exit SQLCMD**:
```
EXIT
```

---

### 🚨 Troubleshooting: Connection Failed

**Error**: "Cannot connect to localhost\SQLEXPRESS"

**Solutions** (try in order):

**1. Check Service is Running**
```powershell
Get-Service -Name "MSSQL$SQLEXPRESS" | Start-Service
```

**2. Try Different Server Names**
```cmd
sqlcmd -S localhost\SQLEXPRESS -E
sqlcmd -S .\SQLEXPRESS -E
sqlcmd -S YOUR-COMPUTER-NAME\SQLEXPRESS -E
```

**Find your computer name**:
```powershell
$env:COMPUTERNAME
```

**3. Enable SQL Server Browser** (if still failing)
```powershell
Get-Service -Name "SQLBrowser" | Set-Service -StartupType Automatic
Get-Service -Name "SQLBrowser" | Start-Service
```

**4. Check Firewall** (last resort)
```powershell
# Allow SQL Server through firewall
New-NetFirewallRule -DisplayName "SQL Server" -Direction Inbound -Protocol TCP -LocalPort 1433 -Action Allow
```

**Still Not Working?** See [Troubleshooting Guide](./05_troubleshooting.md) Section 1.

---

## 🔐 Step 10: Understanding Authentication Modes

SQL Server Express installs with **Windows Authentication Mode** by default. Let's understand what this means.

### Windows Authentication (Default) ⭐ **RECOMMENDED**

**How It Works**:
- Uses your Windows login credentials
- No separate SQL Server password needed
- More secure (leverages Windows security)

**Connection String**:
```
Server=localhost\SQLEXPRESS
Authentication=Windows Authentication
```

**Who Can Connect**:
- Your Windows user account (full admin rights)
- Other Windows users you grant access to

**Pros**:
- ✅ No passwords to remember
- ✅ More secure (domain-integrated)
- ✅ Single sign-on
- ✅ Easier for development

**Cons**:
- ❌ Can't connect from non-Windows apps easily
- ❌ Harder to share credentials with team

---

### Mixed Mode Authentication (Windows + SQL Server)

**What It Is**:
- Supports **both** Windows Authentication AND SQL Server logins
- Enables `sa` (system administrator) account with password
- Used when apps need SQL-based logins

**When You Need It**:
- Apps require SQL Server authentication (e.g., some web apps)
- You need to share database access via username/password
- Cross-platform connections (Linux clients)

**For This Curriculum**: **Windows Authentication is sufficient**. We'll cover changing to Mixed Mode in Module 04 if needed.

---

## 📊 Step 11: SQL Server Configuration Summary

### What Got Installed

**SQL Server Components**:
- ✅ **Database Engine**: Core SQL Server functionality
- ✅ **SQL Browser**: Helps locate named instances
- ✅ **Client Tools**: sqlcmd, bcp (bulk copy program)
- ✅ **Connectivity Components**: Drivers for applications

**What Wasn't Installed** (These are separate):
- ❌ SQL Server Management Studio (SSMS) - Next section!
- ❌ SQL Server Data Tools (SSDT) - Module 06
- ❌ Reporting Services (SSRS) - Not needed for curriculum
- ❌ Analysis Services (SSAS) - Not needed for curriculum

---

### Key Configuration Settings

| Setting | Value | Notes |
|---------|-------|-------|
| **SQL Server Version** | 2022 Express (16.0) | Latest features |
| **Instance Name** | SQLEXPRESS | Named instance (not default) |
| **Server Name** | `localhost\SQLEXPRESS` | Connection string |
| **Port** | Dynamic (usually 50000+) | SQL Browser helps locate |
| **Authentication** | Windows Authentication Only | Secure default |
| **Max Database Size** | 10 GB per database | Express limitation |
| **Max RAM** | ~1.4 GB | Express limitation |
| **Max CPUs** | 4 cores (1 socket) | Express limitation |
| **Collation** | SQL_Latin1_General_CP1_CI_AS | Default sorting/comparison |

**These limits are fine for learning!** 99% of exercises work perfectly within 10 GB.

---

## 🔧 Step 12: Optional Advanced Configuration

### SQL Server Configuration Manager

**What It Is**: Tool to manage SQL Server services, network protocols, and aliases.

**Access It**:
1. Press `Win + S`
2. Type "SQL Server Configuration Manager"
3. Or run: `SQLServerManager16.msc`

<!-- 🎨 PLACEHOLDER: Screenshot of Configuration Manager -->

### Useful Configurations (Optional)

**1. Enable TCP/IP** (if you'll connect from other machines)

**Path**: SQL Server Network Configuration → Protocols for SQLEXPRESS

1. Right-click **TCP/IP**
2. Select "Enable"
3. Restart SQL Server service

**Why**: Allows remote connections (not needed for local learning)

---

**2. Set SQL Server to Auto-Start** (default)

**Path**: SQL Server Services → SQL Server (SQLEXPRESS)

1. Right-click service
2. Properties
3. Service tab → Start Mode: **Automatic**

**Why**: SQL Server starts automatically when you boot Windows

---

**3. Increase Max Server Memory** (if you have 16GB+ RAM)

**Run in SSMS later** (after installing SSMS):
```sql
-- Allow SQL Server to use up to 4 GB RAM (example)
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;

EXEC sp_configure 'max server memory (MB)', 4096;
RECONFIGURE;
```

**For Now**: Skip this - Express Edition defaults are fine for learning.

---

## ✅ Step 13: Final Verification Checklist

Before moving to Section 2 (SSMS), verify:

- [ ] SQL Server 2022 Express installed successfully
- [ ] SQL Server (SQLEXPRESS) service is **Running**
- [ ] You can connect using `sqlcmd -S localhost\SQLEXPRESS -E`
- [ ] You ran `SELECT @@VERSION` and got SQL Server 2022 version info
- [ ] You know your server name: `localhost\SQLEXPRESS`
- [ ] No error messages or warnings during installation

**All checked?** → ✅ **Excellent! You're 50% done with Module 01!**

---

## 📝 What to Do if Installation Failed

### Common Failure Scenarios

**Scenario 1: Installation Stuck at 50%**
- **Cause**: Network issue during download
- **Fix**: Cancel installation, restart computer, try again with stable internet

**Scenario 2: "Installation Failed" Error**
- **Cause**: Conflicting software or insufficient permissions
- **Fix**: Check [Troubleshooting Guide](./05_troubleshooting.md) Section 2

**Scenario 3: Services Won't Start**
- **Cause**: Port conflict or corrupted installation
- **Fix**: Uninstall, reboot, reinstall with firewall/antivirus disabled temporarily

**Scenario 4: Can't Connect via SQLCMD**
- **Cause**: Service not running or wrong server name
- **Fix**: See troubleshooting steps in Step 9 above

---

## 🎯 Summary & Next Steps

### What You Accomplished ✅

- ✅ Downloaded SQL Server 2022 Express installer
- ✅ Installed SQL Server database engine
- ✅ Verified services are running
- ✅ Tested connection using SQLCMD
- ✅ Understand authentication modes
- ✅ Know your server name for future connections

### What's Next 🚀

**[Section 2: SSMS Setup →](./02_ssms_setup_guide.md)**

In the next section, you'll install SQL Server Management Studio (SSMS) - your graphical tool for writing queries and managing databases. Way better than command-line!

**Estimated Time**: 45 minutes

---

**Need Help?** See [Troubleshooting Guide](./05_troubleshooting.md) or ask in [GitHub Discussions](https://github.com/karkakasadara-tharavu/zero-to-data-engineer/discussions)

---

*You're doing great! SQL Server is running - that's the hard part done!* 💪

---

*Last Updated: December 7, 2025*  
*Karka Kasadara - கற்க கசடற - Learn Flawlessly*
