# Sections 03-08: DBA Core Topics (Condensed)

## Section 03: Backup and Recovery (6 hours) ⭐⭐⭐⭐

**Key Concepts**:
- **Full Backup**: Complete database copy
- **Differential Backup**: Changes since last full backup
- **Transaction Log Backup**: Log records (point-in-time recovery)

**Backup Strategy**:
```sql
-- Full Backup (Weekly - Sunday)
BACKUP DATABASE AdventureWorks2022
TO DISK = 'C:\Backups\AW_Full.bak'
WITH FORMAT, COMPRESSION;

-- Differential Backup (Daily)
BACKUP DATABASE AdventureWorks2022
TO DISK = 'C:\Backups\AW_Diff.bak'
WITH DIFFERENTIAL, COMPRESSION;

-- Log Backup (Hourly)
BACKUP LOG AdventureWorks2022
TO DISK = 'C:\Backups\AW_Log.trn';
```

**Restore**:
```sql
-- Restore full
RESTORE DATABASE AdventureWorks2022
FROM DISK = 'C:\Backups\AW_Full.bak'
WITH NORECOVERY;

-- Restore differential
RESTORE DATABASE AdventureWorks2022
FROM DISK = 'C:\Backups\AW_Diff.bak'
WITH RECOVERY;
```

**Labs 22-24**: Full backup, differential, point-in-time restore

---

## Section 04: Security and Permissions (7 hours) ⭐⭐⭐⭐⭐

**Login vs User**:
- **Login**: Server-level (access to SQL Server)
- **User**: Database-level (access to database)

```sql
-- Create Login (server-level)
CREATE LOGIN DataAnalyst WITH PASSWORD = 'StrongP@ssw0rd!';

-- Create User (database-level)
USE AdventureWorks2022;
CREATE USER DataAnalyst FOR LOGIN DataAnalyst;

-- Grant Permissions
GRANT SELECT ON Sales.SalesOrderHeader TO DataAnalyst;
GRANT SELECT, INSERT ON Sales.Customer TO DataAnalyst;

-- Database Roles
ALTER ROLE db_datareader ADD MEMBER DataAnalyst; -- Read-only
ALTER ROLE db_datawriter ADD MEMBER DataAnalyst; -- Read-write
```

**Row-Level Security**:
```sql
-- Create security policy
CREATE FUNCTION fn_SecurityPredicate(@SalesPersonID INT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN SELECT 1 AS Result
WHERE @SalesPersonID = CAST(SESSION_CONTEXT(N'SalesPersonID') AS INT);

CREATE SECURITY POLICY SalesFilter
ADD FILTER PREDICATE dbo.fn_SecurityPredicate(SalesPersonID)
ON Sales.SalesOrderHeader
WITH (STATE = ON);
```

**Labs 25-27**: Logins/users, roles, row-level security

---

## Section 05: Transaction Logs (5 hours) ⭐⭐⭐⭐

**Recovery Models**:
- **Simple**: Log auto-truncates, no point-in-time recovery
- **Full**: All transactions logged, supports point-in-time recovery
- **Bulk-Logged**: Minimal logging for bulk operations

```sql
-- Check recovery model
SELECT name, recovery_model_desc
FROM sys.databases
WHERE name = 'AdventureWorks2022';

-- Change recovery model
ALTER DATABASE AdventureWorks2022
SET RECOVERY FULL;

-- Shrink log (after backup)
BACKUP LOG AdventureWorks2022 TO DISK = 'C:\Backups\log.trn';
DBCC SHRINKFILE (AdventureWorks2022_Log, 100); -- 100 MB
```

**Labs 28-29**: Log management, recovery model testing

---

## Section 06: Maintenance Plans (4 hours) ⭐⭐⭐

**Index Maintenance**:
```sql
-- Check fragmentation
SELECT 
    object_name(object_id) AS TableName,
    index_id,
    avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED')
WHERE avg_fragmentation_in_percent > 10;

-- Rebuild index (>30% fragmentation)
ALTER INDEX ALL ON Sales.SalesOrderDetail REBUILD;

-- Reorganize index (10-30% fragmentation)
ALTER INDEX ALL ON Sales.SalesOrderDetail REORGANIZE;
```

**Update Statistics**:
```sql
UPDATE STATISTICS Sales.SalesOrderHeader WITH FULLSCAN;
```

**Database Integrity**:
```sql
DBCC CHECKDB('AdventureWorks2022') WITH NO_INFOMSGS;
```

**SQL Server Agent Job** (GUI): Create scheduled maintenance

**Labs 30-31**: Create maintenance plan, index maintenance scripts

---

## Section 07: Monitoring and Alerts (5 hours) ⭐⭐⭐⭐

**Activity Monitor**: SSMS → Right-click server → Activity Monitor

**DMVs (Dynamic Management Views)**:
```sql
-- Currently running queries
SELECT 
    session_id,
    start_time,
    status,
    command,
    sql_text = (SELECT TEXT FROM sys.dm_exec_sql_text(sql_handle))
FROM sys.dm_exec_requests;

-- Blocking queries
SELECT 
    blocking_session_id,
    session_id,
    wait_type,
    wait_time
FROM sys.dm_exec_requests
WHERE blocking_session_id <> 0;

-- Database sizes
SELECT 
    database_name = DB_NAME(database_id),
    size_mb = SUM(size * 8.0 / 1024)
FROM sys.master_files
GROUP BY database_id;
```

**Alerts** (SQL Server Agent):
- Severity 19-25 errors
- Performance counter thresholds
- Disk space warnings

**Labs 32-33**: Monitor queries, configure alerts

---

## Section 08: Advanced Administration (4 hours) ⭐⭐⭐⭐⭐

**Database Mail**:
```sql
-- Configure Database Mail (GUI: Management → Database Mail)
EXEC msdb.dbo.sp_send_dbmail
    @profile_name = 'DBA Profile',
    @recipients = 'dba@company.com',
    @subject = 'Backup Completed',
    @body = 'Full backup completed successfully.';
```

**Automation**:
```sql
-- Create SQL Agent Job
EXEC msdb.dbo.sp_add_job
    @job_name = 'Weekly Full Backup';

EXEC msdb.dbo.sp_add_jobstep
    @job_name = 'Weekly Full Backup',
    @step_name = 'Backup Step',
    @command = 'BACKUP DATABASE AdventureWorks2022 TO DISK = ''C:\Backups\AW_Full.bak''';

EXEC msdb.dbo.sp_add_schedule
    @schedule_name = 'Sunday 2AM',
    @freq_type = 8, -- Weekly
    @freq_interval = 1, -- Sunday
    @active_start_time = 020000;
```

**Lab 34**: Automation with SQL Agent

---

## Lab 35: Capstone - Production DBA Setup (8 hours) ⭐⭐⭐⭐⭐

**Requirements**:
1. Design normalized database (customer orders system)
2. Implement security (3 roles: admin, analyst, clerk)
3. Configure backup strategy (full + differential + log)
4. Create maintenance plan (weekly index rebuild, daily stats)
5. Set up monitoring (blocking alerts, disk space)
6. Document procedures

**Evaluation**:
- Design quality (20 pts)
- Security implementation (20 pts)
- Backup/restore tested (25 pts)
- Maintenance automation (20 pts)
- Documentation (15 pts)

---

**Module 04 Complete!** Continue to Module 05: T-SQL Programming
