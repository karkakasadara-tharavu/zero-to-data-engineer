# Section 5: Troubleshooting Guide

**Purpose**: Comprehensive solutions to common installation and setup issues  
**When to Use**: When you encounter errors during Modules 01 setup  
**Format**: Problem → Diagnosis → Solution

---

## 🔍 How to Use This Guide

### Problem Resolution Workflow

1. **Identify your error** - Look for the exact error message or symptom
2. **Find matching section** - Use Ctrl+F to search for keywords from your error
3. **Follow diagnosis steps** - Determine the root cause
4. **Apply solution** - Execute the fix step-by-step
5. **Verify fix** - Run verification tests from Section 4

---

## 📑 Troubleshooting Index

### Quick Jump Links

**SQL Server Installation Issues** → [Section 1](#section-1-sql-server-installation-issues)  
**SQL Server Service Problems** → [Section 2](#section-2-sql-server-service-issues)  
**SSMS Connection Errors** → [Section 3](#section-3-ssms-connection-issues)  
**AdventureWorks Restore Failures** → [Section 4](#section-4-adventureworks-restore-issues)  
**SSMS Performance/Crashes** → [Section 5](#section-5-ssms-performance-issues)  
**Permission Errors** → [Section 6](#section-6-permission-and-security-issues)  
**Disk Space Issues** → [Section 7](#section-7-disk-space-and-storage-issues)  
**Network/Firewall Blocks** → [Section 8](#section-8-network-and-firewall-issues)

---

<a name="section-1-sql-server-installation-issues"></a>
## 📦 Section 1: SQL Server Installation Issues

### Problem 1.1: Installer Won't Run

**Symptom**: Double-clicking `SQL2022-SRVR-Expr-x64-ENU.exe` does nothing or shows error.

**Diagnosis**:
```powershell
# Check if file is blocked
Get-Item "C:\Users\$env:USERNAME\Downloads\SQL2022-SRVR-Expr-x64-ENU.exe" | Select-Object -ExpandProperty Attributes
```

**Solution 1**: Unblock the file
```powershell
Unblock-File -Path "C:\Users\$env:USERNAME\Downloads\SQL2022-SRVR-Expr-x64-ENU.exe"
```

**Solution 2**: Run as Administrator
1. Right-click installer
2. **"Run as administrator"**
3. Click "Yes" to UAC prompt

**Solution 3**: Check antivirus
- Temporarily disable antivirus
- Re-download installer from official Microsoft link
- Re-enable antivirus after installation

---

### Problem 1.2: "The specified account already exists" Error

**Symptom**: Installation fails with error about account already existing.

**Diagnosis**: Previous incomplete installation left registry keys or service accounts.

**Solution**:
```powershell
# Remove SQL Server services (if present)
sc delete "MSSQL$SQLEXPRESS"
sc delete "SQLBrowser"
sc delete "SQLSERVERAGENT"

# Clean registry (CAUTION: Backup first!)
# Navigate to: HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SQL Server
# Delete SQLEXPRESS entries
```

**Safer Alternative**: 
1. Use **SQL Server Installation Center** (if partially installed)
2. Go to **"Maintenance"** → **"Uninstall"**
3. Remove SQL Server instance
4. Restart computer
5. Re-run installation

---

### Problem 1.3: "Rule Check Failed: .NET Framework 4.7.2 Not Installed"

**Symptom**: Installation blocked by .NET Framework version check.

**Diagnosis**:
```powershell
# Check installed .NET versions
Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -Recurse | Get-ItemProperty -Name Version -ErrorAction SilentlyContinue | Select-Object PSChildName, Version
```

**Solution**: Install .NET Framework 4.7.2 or higher
1. Download from: https://dotnet.microsoft.com/download/dotnet-framework
2. Choose **.NET Framework 4.8** (latest, includes 4.7.2)
3. Install and restart
4. Re-run SQL Server installer

---

### Problem 1.4: "Setup Failed. Installation Incomplete."

**Symptom**: Generic setup failure at end of installation.

**Diagnosis**: Check SQL Server Setup logs
```powershell
# Open setup log folder
$logFolder = "C:\Program Files\Microsoft SQL Server\160\Setup Bootstrap\Log"
Invoke-Item $logFolder

# Look for Summary.txt (most recent)
Get-ChildItem $logFolder -Filter "Summary.txt" -Recurse | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | Get-Content
```

**Common Causes & Solutions**:

**Cause A: Insufficient disk space**
```powershell
Get-PSDrive C | Select-Object Used, Free
```
- **Need**: Minimum 6 GB free on C: drive
- **Solution**: Free up space or install to different drive

**Cause B: Previous installation remnants**
- **Solution**: Use Microsoft's cleanup tool
- Download: https://support.microsoft.com/en-us/topic/kb2977315-fix-sql-server-utility-to-remove-sql-instances
- Run cleanup utility
- Restart and reinstall

**Cause C: Windows Update required**
- **Solution**: Install all Windows updates
```powershell
# Check for updates
Start-Process ms-settings:windowsupdate
```

---

### Problem 1.5: "SQL Server Installation Hangs/Freezes"

**Symptom**: Installer stuck at specific percentage (e.g., 30%, 60%).

**Diagnosis**: Likely downloading components from Microsoft servers.

**Solution 1**: Wait longer (30-60 minutes)
- Installation downloads 1.5 GB+ of components
- Slow internet can make it seem frozen
- Check network activity in Task Manager (Ctrl+Shift+Esc → Performance → Ethernet/Wi-Fi)

**Solution 2**: Use offline installation
1. Choose **"Download Media"** installation type instead of "Basic"
2. Download full ISO (~1.8 GB)
3. Mount ISO (double-click in Windows 10/11)
4. Run setup.exe from mounted drive

**Solution 3**: Disable firewall/antivirus temporarily
- Some security software blocks installer network calls
- Disable → Install → Re-enable

---

<a name="section-2-sql-server-service-issues"></a>
## 🔧 Section 2: SQL Server Service Issues

### Problem 2.1: "SQL Server Service Won't Start"

**Symptom**: Service status shows "Stopped" and won't start.

**Diagnosis**:
```powershell
# Check service status
Get-Service -Name "MSSQL$SQLEXPRESS" | Select-Object Name, Status, StartType

# Check SQL Server error log
Get-Content "C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\Log\ERRORLOG" -Tail 50
```

**Solution 1**: Check service startup account
```powershell
# View service account
Get-WmiObject -Class Win32_Service -Filter "Name='MSSQL`$SQLEXPRESS'" | Select-Object Name, StartName
```

**Fix**: If not "NT Service\MSSQL$SQLEXPRESS":
1. Open **services.msc**
2. Right-click **SQL Server (SQLEXPRESS)** → **Properties**
3. **Log On** tab
4. Select **"This account"**: `NT Service\MSSQL$SQLEXPRESS`
5. Leave password blank
6. **OK** → **Start service**

**Solution 2**: Check TempDB corruption
```powershell
# Delete tempdb files (safe - recreated on startup)
Remove-Item "C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\tempdb.mdf" -Force
Remove-Item "C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\templog.ldf" -Force

# Start service
Start-Service -Name "MSSQL$SQLEXPRESS"
```

**Solution 3**: Check port conflicts
```powershell
# Check if port 1433 is in use
Get-NetTCPConnection -LocalPort 1433 -ErrorAction SilentlyContinue
```
- If another service uses 1433, configure SQL Server to use different port
- See [Problem 8.2](#problem-82-port-1433-in-use) below

---

### Problem 2.2: "Service Starts Then Immediately Stops"

**Symptom**: Service starts briefly, then stops within seconds.

**Diagnosis**: Check error log for access denied or missing files
```powershell
Get-Content "C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\Log\ERRORLOG" | Select-String -Pattern "error", "failed", "cannot"
```

**Common Causes**:

**Cause A: File permission issue**
```powershell
# Grant full control to SQL Server service account
$sqlDataPath = "C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA"
icacls $sqlDataPath /grant "NT Service\MSSQL`$SQLEXPRESS:(OI)(CI)F" /T
```

**Cause B: Master database corruption**
- **Solution**: Rebuild system databases
```cmd
REM Run as Administrator in Command Prompt
cd "C:\Program Files\Microsoft SQL Server\160\Setup Bootstrap\Release"
Setup.exe /QUIET /ACTION=REBUILDDATABASE /INSTANCENAME=SQLEXPRESS /SQLSYSADMINACCOUNTS=%USERDOMAIN%\%USERNAME%
```

**Cause C: Trace flag startup parameter issue**
1. Open **SQL Server Configuration Manager**
2. Right-click **SQL Server (SQLEXPRESS)** → **Properties**
3. **Startup Parameters** tab
4. Remove any `-T####` trace flags
5. **OK** → **Start service**

---

### Problem 2.3: "SQL Server Browser Service Not Running"

**Symptom**: Can't connect using server name without instance (e.g., `localhost`).

**Diagnosis**:
```powershell
Get-Service -Name "SQLBrowser" | Select-Object Status, StartType
```

**Solution**: Enable and start SQL Server Browser
```powershell
# Set startup type to Automatic
Set-Service -Name "SQLBrowser" -StartupType Automatic

# Start service
Start-Service -Name "SQLBrowser"

# Verify
Get-Service -Name "SQLBrowser"
```

**Why SQL Server Browser?**
- **Purpose**: Listens for incoming requests for SQL Server instances
- **Requirement**: Needed if connecting without port number
- **Express Edition**: Especially important (uses dynamic ports)

---

<a name="section-3-ssms-connection-issues"></a>
## 🔌 Section 3: SSMS Connection Issues

### Problem 3.1: "A network-related or instance-specific error occurred"

**Full Error Message**:
```
A network-related or instance-specific error occurred while establishing a connection to SQL Server. 
The server was not found or was not accessible. Verify that the instance name is correct and that SQL 
Server is configured to allow remote connections. (provider: SQL Network Interfaces, error: 26 - Error 
Locating Server/Instance Specified)
```

**Diagnosis Checklist**:
```powershell
# 1. Check SQL Server service is running
Get-Service -Name "MSSQL$SQLEXPRESS"

# 2. Check SQL Browser service
Get-Service -Name "SQLBrowser"

# 3. Test local connectivity
sqlcmd -S localhost\SQLEXPRESS -E
```

**Solution Steps** (try in order):

**Step 1**: Verify server name
- Try these variations:
  - `localhost\SQLEXPRESS`
  - `.\SQLEXPRESS`
  - `(local)\SQLEXPRESS`
  - `YOUR-COMPUTER-NAME\SQLEXPRESS`

To find your computer name:
```powershell
$env:COMPUTERNAME
```

**Step 2**: Enable TCP/IP protocol
1. Open **SQL Server Configuration Manager**
   - Start menu → Search "SQL Server Configuration Manager"
2. Expand **SQL Server Network Configuration** → **Protocols for SQLEXPRESS**
3. Right-click **TCP/IP** → **Enable**
4. Restart SQL Server service:
```powershell
Restart-Service -Name "MSSQL$SQLEXPRESS"
```

**Step 3**: Enable Named Pipes (alternative)
- Same as TCP/IP steps, but enable **"Named Pipes"** instead
- Restart service

**Step 4**: Start SQL Browser and set to automatic
```powershell
Set-Service -Name "SQLBrowser" -StartupType Automatic
Start-Service -Name "SQLBrowser"
```

**Step 5**: Check Windows Firewall (see [Section 8](#section-8-network-and-firewall-issues))

---

### Problem 3.2: "Login failed for user 'DOMAIN\Username'"

**Symptom**: Connection dialog accepts, but login fails with error 18456.

**Diagnosis**: Authentication mode or login not created.

**Solution 1**: Verify Windows Authentication is enabled
```powershell
# Check registry for authentication mode
$authMode = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQLServer" -Name LoginMode
$authMode.LoginMode
# 1 = Windows Authentication Only
# 2 = Mixed Mode (Windows + SQL Server)
```

**Solution 2**: Add your Windows login to SQL Server
1. Open SSMS with **"Run as administrator"**
2. Connect using **".\Administrator"** if possible
3. **Security** → **Logins** → Right-click → **New Login...**
4. Click **"Search..."** button
5. Enter your Windows username → **Check Names** → **OK**
6. **Server Roles** tab → Check **"sysadmin"**
7. **OK**

**Solution 3**: Enable Mixed Mode Authentication
1. Open **SQL Server Configuration Manager**
2. Right-click **SQL Server (SQLEXPRESS)** → **Properties**
3. **Security** tab
4. Select **"SQL Server and Windows Authentication mode"**
5. **OK**
6. Restart service:
```powershell
Restart-Service -Name "MSSQL$SQLEXPRESS"
```

---

### Problem 3.3: "Timeout expired. The timeout period elapsed..."

**Symptom**: Connection attempts wait 15-30 seconds then fail.

**Diagnosis**: Network latency, blocked ports, or service not responding.

**Solution 1**: Increase connection timeout in SSMS
1. **Tools** → **Options** → **Connection** → **Database Engine**
2. **Login time-out**: Change from 15 to **30 seconds**
3. **OK**
4. Retry connection

**Solution 2**: Check if SQL Server is responding
```powershell
# Test port connectivity
Test-NetConnection -ComputerName localhost -Port 1433

# If fails, SQL Server not listening on port
```

**Solution 3**: Restart SQL Server service
```powershell
Restart-Service -Name "MSSQL$SQLEXPRESS" -Force
Start-Service -Name "SQLBrowser"
```

**Solution 4**: Check for resource exhaustion
```powershell
# Check CPU usage
Get-Process sqlservr | Select-Object CPU, WorkingSet64

# If CPU >90% for long time or RAM >80%, see Problem 2.1
```

---

### Problem 3.4: "Cannot generate SSPI context"

**Full Error**: "Cannot generate SSPI context" (Error 17806)

**Cause**: Kerberos authentication issue (Windows domain environments).

**Solution 1**: Use IP address instead of server name
- Instead of: `SERVERNAME\SQLEXPRESS`
- Use: `127.0.0.1\SQLEXPRESS` or `localhost\SQLEXPRESS`

**Solution 2**: Clear Kerberos tickets
```cmd
REM Run as Administrator
klist purge
```
- Restart computer
- Try connecting again

**Solution 3**: Use SQL Server Authentication (if enabled)
- In SSMS connection dialog:
- **Authentication**: SQL Server Authentication
- **Login**: sa
- **Password**: (set during installation)

---

<a name="section-4-adventureworks-restore-issues"></a>
## 📦 Section 4: AdventureWorks Restore Issues

### Problem 4.1: "The media set has 2 media families but only 1 are provided"

**Symptom**: Restore fails with media family error.

**Cause**: Corrupted or incomplete .bak file download.

**Solution**: Re-download the backup file
```powershell
# Delete corrupted file
Remove-Item "C:\Temp\AdventureWorks2022.bak" -Force

# Re-download
Invoke-WebRequest -Uri "https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2022.bak" -OutFile "C:\Temp\AdventureWorks2022.bak"

# Verify file size (should be ~45 MB)
(Get-Item "C:\Temp\AdventureWorks2022.bak").Length / 1MB
```

**Expected Size**: ~45 MB (AdventureWorks2022), ~1 MB (AdventureWorksLT2022)

---

### Problem 4.2: "Directory lookup for the file failed"

**Symptom**: Restore fails with error 3201 - cannot access backup file.

**Diagnosis**:
```powershell
# Check if file exists
Test-Path "C:\Temp\AdventureWorks2022.bak"

# Check file permissions
Get-Acl "C:\Temp\AdventureWorks2022.bak" | Format-List
```

**Solution 1**: Grant SQL Server service account read permissions
```powershell
# Add SQL Server service account to file permissions
$file = "C:\Temp\AdventureWorks2022.bak"
$acl = Get-Acl $file
$permission = "NT Service\MSSQL`$SQLEXPRESS", "Read", "Allow"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
$acl.SetAccessRule($accessRule)
Set-Acl $file $acl
```

**Solution 2**: Move file to SQL Server data directory
```powershell
# Copy to SQL Server data folder (already has permissions)
Copy-Item "C:\Temp\AdventureWorks2022.bak" -Destination "C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\Backup\"

# Use new path in RESTORE command
```

**Solution 3**: Run SSMS as Administrator
1. Close SSMS
2. Right-click SSMS shortcut → **Run as administrator**
3. Reconnect to SQL Server
4. Retry restore

---

### Problem 4.3: "Logical file 'X' is not part of database 'Y'"

**Symptom**: RESTORE DATABASE fails with error about logical file names.

**Cause**: Logical file names in RESTORE script don't match backup file.

**Solution**: Query backup file for correct logical names
```sql
-- Check logical file names in backup
RESTORE FILELISTONLY 
FROM DISK = 'C:\Temp\AdventureWorks2022.bak';
```

**Output Example**:
| LogicalName | PhysicalName | Type |
|-------------|--------------|------|
| AdventureWorks2022 | ...\AdventureWorks2022.mdf | D |
| AdventureWorks2022_log | ...\AdventureWorks2022_log.ldf | L |

**Updated RESTORE Command**:
```sql
RESTORE DATABASE AdventureWorks2022
FROM DISK = 'C:\Temp\AdventureWorks2022.bak'
WITH 
    MOVE 'AdventureWorks2022' TO 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\AdventureWorks2022.mdf',
    MOVE 'AdventureWorks2022_log' TO 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\AdventureWorks2022_log.ldf',
    REPLACE;
GO
```

---

### Problem 4.4: "Database 'X' already exists"

**Symptom**: Restore fails because database already exists.

**Solution 1**: Add WITH REPLACE option
```sql
RESTORE DATABASE AdventureWorks2022
FROM DISK = 'C:\Temp\AdventureWorks2022.bak'
WITH REPLACE;  -- Overwrites existing database
GO
```

**Solution 2**: Drop existing database first
```sql
-- Close any open connections
USE master;
GO

ALTER DATABASE AdventureWorks2022 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

DROP DATABASE AdventureWorks2022;
GO

-- Now restore
RESTORE DATABASE AdventureWorks2022
FROM DISK = 'C:\Temp\AdventureWorks2022.bak';
GO
```

**Solution 3**: Restore with different name
```sql
RESTORE DATABASE AdventureWorks2022_NEW
FROM DISK = 'C:\Temp\AdventureWorks2022.bak'
WITH 
    MOVE 'AdventureWorks2022' TO 'C:\...\AdventureWorks2022_NEW.mdf',
    MOVE 'AdventureWorks2022_log' TO 'C:\...\AdventureWorks2022_NEW_log.ldf';
GO
```

---

### Problem 4.5: "Not enough space on disk"

**Symptom**: Restore fails due to insufficient disk space.

**Diagnosis**:
```powershell
# Check free space on C: drive
Get-PSDrive C | Select-Object Used, Free
```

**Solution 1**: Free up disk space
```powershell
# Clean temporary files
Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue

# Empty Recycle Bin
Clear-RecycleBin -Force

# Run Disk Cleanup
cleanmgr /sagerun:1
```

**Solution 2**: Restore to different drive with more space
```sql
RESTORE DATABASE AdventureWorks2022
FROM DISK = 'C:\Temp\AdventureWorks2022.bak'
WITH 
    MOVE 'AdventureWorks2022' TO 'D:\SQLData\AdventureWorks2022.mdf',  -- Different drive
    MOVE 'AdventureWorks2022_log' TO 'D:\SQLData\AdventureWorks2022_log.ldf',
    REPLACE;
GO
```

**Note**: Ensure SQL Server service account has access to destination folder!

---

<a name="section-5-ssms-performance-issues"></a>
## 🐌 Section 5: SSMS Performance Issues

### Problem 5.1: "SSMS Freezes or Becomes Unresponsive"

**Symptom**: SSMS hangs when expanding databases or executing queries.

**Solution 1**: Disable IntelliSense auto-refresh
1. **Tools** → **Options** → **Text Editor** → **Transact-SQL** → **IntelliSense**
2. Uncheck **"Auto list members"** (or reduce refresh frequency)
3. **OK**
4. Restart SSMS

**Solution 2**: Increase SSMS memory allocation
1. Close SSMS
2. Edit `ssms.exe.config` file:
```powershell
notepad "C:\Program Files (x86)\Microsoft SQL Server Management Studio 20\Common7\IDE\ssms.exe.config"
```
3. Find `<runtime>` section, add:
```xml
<gcAllowVeryLargeObjects enabled="true" />
```
4. Save and restart SSMS

**Solution 3**: Reset SSMS settings to default
```powershell
# Backup current settings
Copy-Item "$env:APPDATA\Microsoft\SQL Server Management Studio" -Destination "$env:APPDATA\Microsoft\SSMS_Backup" -Recurse

# Delete settings folder (forces reset)
Remove-Item "$env:APPDATA\Microsoft\SQL Server Management Studio" -Recurse -Force

# Restart SSMS (will create default settings)
```

---

### Problem 5.2: "SSMS Crashes When Running Queries"

**Symptom**: SSMS closes unexpectedly during query execution.

**Solution 1**: Update SSMS to latest version
- Download latest from: https://aka.ms/ssmsfullsetup
- Install over existing version (settings preserved)

**Solution 2**: Disable query execution plan auto-display
1. **Tools** → **Options** → **Query Execution** → **SQL Server** → **General**
2. Uncheck **"Include actual execution plan"**
3. Uncheck **"Display execution plan XML"**
4. **OK**

**Solution 3**: Increase query result limits
1. **Tools** → **Options** → **Query Results** → **SQL Server** → **Results to Grid**
2. **Maximum Characters Retrieved**:
   - XML: 2 MB → 1 MB
   - Non-XML: Unlimited → 65535
3. **OK**

---

### Problem 5.3: "IntelliSense Not Working"

**Symptom**: Auto-complete doesn't suggest table/column names.

**Solution 1**: Manually refresh IntelliSense cache
- Press **Ctrl + Shift + R** (or **Edit** → **IntelliSense** → **Refresh Local Cache**)

**Solution 2**: Verify IntelliSense is enabled
1. **Tools** → **Options** → **Text Editor** → **Transact-SQL** → **IntelliSense**
2. Check **"Enable IntelliSense"**
3. **OK**

**Solution 3**: Check database compatibility level
```sql
-- IntelliSense requires compatibility level 100+
SELECT name, compatibility_level
FROM sys.databases
WHERE name = 'AdventureWorks2022';

-- If <100, upgrade:
ALTER DATABASE AdventureWorks2022 SET COMPATIBILITY_LEVEL = 160;  -- SQL Server 2022
GO
```

---

<a name="section-6-permission-and-security-issues"></a>
## 🔐 Section 6: Permission and Security Issues

### Problem 6.1: "The SELECT permission was denied on the object"

**Symptom**: Query fails with permission error (Error 229).

**Diagnosis**: Your login lacks permissions on the table/database.

**Solution 1**: Add user to db_datareader role
```sql
USE AdventureWorks2022;
GO

-- Replace 'DOMAIN\Username' with your Windows account
CREATE USER [DOMAIN\Username] FOR LOGIN [DOMAIN\Username];
GO

ALTER ROLE db_datareader ADD MEMBER [DOMAIN\Username];
GO
```

**Solution 2**: Grant explicit SELECT permission
```sql
GRANT SELECT ON SCHEMA::Sales TO [DOMAIN\Username];
GO
```

**Solution 3**: Make user database owner (full permissions)
```sql
ALTER AUTHORIZATION ON DATABASE::AdventureWorks2022 TO [DOMAIN\Username];
GO
```

---

### Problem 6.2: "CREATE DATABASE permission denied"

**Symptom**: Cannot create new databases.

**Solution**: Add login to sysadmin or dbcreator role
```sql
USE master;
GO

-- Option 1: Make sysadmin (full server access)
ALTER SERVER ROLE sysadmin ADD MEMBER [DOMAIN\Username];
GO

-- Option 2: Grant only CREATE DATABASE (restricted)
ALTER SERVER ROLE dbcreator ADD MEMBER [DOMAIN\Username];
GO
```

---

### Problem 6.3: "Cannot access SQL Server Configuration Manager"

**Symptom**: "The RPC server is unavailable" when opening SQL Server Configuration Manager.

**Solution 1**: Start WMI service
```powershell
# Start Windows Management Instrumentation service
Start-Service -Name "Winmgmt"

# Set to automatic startup
Set-Service -Name "Winmgmt" -StartupType Automatic
```

**Solution 2**: Re-register SQL Server WMI provider
```cmd
REM Run as Administrator
mofcomp "C:\Program Files (x86)\Microsoft SQL Server\160\Shared\sqlmgmproviderxpsp2up.mof"
```

**Solution 3**: Use PowerShell alternative
```powershell
# List SQL Server services
Get-Service -Name "MSSQL*", "SQL*"

# Start/stop services
Start-Service -Name "MSSQL$SQLEXPRESS"
Stop-Service -Name "MSSQL$SQLEXPRESS"

# Change startup type
Set-Service -Name "MSSQL$SQLEXPRESS" -StartupType Automatic
```

---

<a name="section-7-disk-space-and-storage-issues"></a>
## 💾 Section 7: Disk Space and Storage Issues

### Problem 7.1: "Transaction log is full" (Error 9002)

**Symptom**: INSERT/UPDATE operations fail with error 9002.

**Diagnosis**:
```sql
USE AdventureWorks2022;
GO

-- Check log file size
SELECT 
    name AS FileName,
    size * 8 / 1024 AS CurrentSizeMB,
    max_size * 8 / 1024 AS MaxSizeMB,
    growth AS GrowthSetting
FROM sys.database_files
WHERE type_desc = 'LOG';
GO
```

**Solution 1**: Backup transaction log
```sql
-- Only works if recovery model is FULL
BACKUP LOG AdventureWorks2022
TO DISK = 'C:\Temp\AdventureWorks2022_LogBackup.trn'
WITH COMPRESSION;
GO
```

**Solution 2**: Change recovery model to SIMPLE (for non-production)
```sql
ALTER DATABASE AdventureWorks2022 SET RECOVERY SIMPLE;
GO

-- Shrink log file
DBCC SHRINKFILE (AdventureWorks2022_log, 1);  -- Shrink to 1 MB
GO
```

**Solution 3**: Increase log file size/autogrowth
```sql
ALTER DATABASE AdventureWorks2022
MODIFY FILE (
    NAME = AdventureWorks2022_log,
    SIZE = 100MB,        -- Initial size
    MAXSIZE = 500MB,     -- Maximum size
    FILEGROWTH = 10MB    -- Growth increment
);
GO
```

---

### Problem 7.2: "Could not allocate space for object"

**Symptom**: Data file full, can't insert new rows.

**Solution 1**: Shrink database (reclaim unused space)
```sql
-- Check current space usage
EXEC sp_spaceused;
GO

-- Shrink database
DBCC SHRINKDATABASE (AdventureWorks2022, 10);  -- 10% free space
GO
```

**Solution 2**: Add new data file
```sql
ALTER DATABASE AdventureWorks2022
ADD FILE (
    NAME = AdventureWorks2022_Data2,
    FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\AdventureWorks2022_Data2.ndf',
    SIZE = 50MB,
    MAXSIZE = 500MB,
    FILEGROWTH = 10MB
);
GO
```

**Solution 3**: Increase data file size
```sql
ALTER DATABASE AdventureWorks2022
MODIFY FILE (
    NAME = AdventureWorks2022,
    SIZE = 100MB,
    MAXSIZE = 1024MB  -- 1 GB (Express max per DB: 10 GB)
);
GO
```

---

<a name="section-8-network-and-firewall-issues"></a>
## 🔥 Section 8: Network and Firewall Issues

### Problem 8.1: "Windows Firewall Blocking SQL Server"

**Symptom**: Can't connect to SQL Server from another machine (or locally via TCP/IP).

**Solution**: Add firewall rules for SQL Server
```powershell
# Rule 1: SQL Server instance (port 1433 or dynamic)
New-NetFirewallRule -DisplayName "SQL Server" -Direction Inbound -Protocol TCP -LocalPort 1433 -Action Allow

# Rule 2: SQL Server Browser (UDP 1434)
New-NetFirewallRule -DisplayName "SQL Browser" -Direction Inbound -Protocol UDP -LocalPort 1434 -Action Allow

# Rule 3: SQL Server executable (alternative)
$sqlExePath = "C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\Binn\sqlservr.exe"
New-NetFirewallRule -DisplayName "SQL Server Express" -Direction Inbound -Program $sqlExePath -Action Allow
```

**Verify Firewall Rules**:
```powershell
Get-NetFirewallRule -DisplayName "SQL*" | Select-Object DisplayName, Enabled, Direction, Action
```

---

### Problem 8.2: "Port 1433 Already in Use"

**Symptom**: SQL Server can't start because port 1433 is occupied.

**Diagnosis**: Find which process is using port 1433
```powershell
Get-NetTCPConnection -LocalPort 1433 -ErrorAction SilentlyContinue | Select-Object State, OwningProcess

# Find process name
$process = Get-NetTCPConnection -LocalPort 1433 | Select-Object -ExpandProperty OwningProcess
Get-Process -Id $process | Select-Object ProcessName, Id
```

**Solution 1**: Stop conflicting process
```powershell
# Example: Stop MySQL if it's using 1433
Stop-Service -Name "MySQL" -Force
Set-Service -Name "MySQL" -StartupType Disabled
```

**Solution 2**: Configure SQL Server to use different port
1. Open **SQL Server Configuration Manager**
2. Expand **SQL Server Network Configuration** → **Protocols for SQLEXPRESS**
3. Right-click **TCP/IP** → **Properties**
4. **IP Addresses** tab
5. Scroll to **IPAll** section
6. **TCP Port**: Change `1433` to `1435` (or any unused port)
7. **OK**
8. Restart SQL Server service
```powershell
Restart-Service -Name "MSSQL$SQLEXPRESS"
```

**Connect using new port**: `localhost\SQLEXPRESS,1435` (comma, not colon!)

---

### Problem 8.3: "Named Pipes Provider: Could not open a connection"

**Symptom**: Error 2 - "Named Pipes Provider: Could not open a connection to SQL Server [2]."

**Solution**: Enable Named Pipes protocol
1. Open **SQL Server Configuration Manager**
2. Expand **SQL Server Network Configuration** → **Protocols for SQLEXPRESS**
3. Right-click **Named Pipes** → **Enable**
4. Restart SQL Server service
```powershell
Restart-Service -Name "MSSQL$SQLEXPRESS"
```

**Alternative**: Use TCP/IP connection instead
- Connection string: `tcp:localhost\SQLEXPRESS`

---

## 🆘 Getting Additional Help

### Step 1: Capture Error Details

When seeking help, provide:

**1. Exact error message**
```powershell
# Copy from SSMS Messages tab (Ctrl+C after selecting text)
```

**2. SQL Server version**
```sql
SELECT @@VERSION;
```

**3. Service status**
```powershell
Get-Service -Name "MSSQL$SQLEXPRESS", "SQLBrowser" | Select-Object Name, Status
```

**4. Error logs**
```powershell
Get-Content "C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\Log\ERRORLOG" -Tail 50
```

---

### Step 2: Search Official Resources

**Microsoft Docs**:  
🔗 https://learn.microsoft.com/en-us/sql/sql-server/

**SQL Server Error Messages**:  
🔗 https://learn.microsoft.com/en-us/sql/relational-databases/errors-events/database-engine-events-and-errors

**Stack Overflow**:  
🔗 https://stackoverflow.com/questions/tagged/sql-server

---

### Step 3: Community Support

**Karka Kasadara Community Forum**:  
📧 Email: karkakasadara@yourcompany.com  
💬 Discord: [Your Discord Link]  
💼 LinkedIn: [Your LinkedIn Group]

**What to Include in Your Question**:
- Operating system (Windows 10/11, version)
- SQL Server version (2022 Express)
- What you were trying to do
- Exact error message
- Steps you've already tried
- Screenshots of error (use 🎨 placeholder location)

---

## ✅ Final Verification

After fixing any issue, run verification tests:

```sql
-- Quick health check
SELECT @@VERSION AS SQLServerVersion;
SELECT @@SERVERNAME AS ServerName;
EXEC sp_databases;  -- List all databases
```

**Full verification**: Run `04_verification_tests.sql` from Section 4.

---

## 🎯 Summary

This troubleshooting guide covers 95% of common setup issues. Remember:

✅ **Most issues are fixable** - Don't give up!  
✅ **Check error logs** - They contain valuable clues  
✅ **Search error codes** - Microsoft docs are excellent  
✅ **Ask for help** - Karka Kasadara community is here for you  

**கற்க கசடற - Learn Flawlessly, Grow Together** 🚀

---

*Last Updated: December 7, 2025*  
*Karka Kasadara Data Engineering Curriculum*
