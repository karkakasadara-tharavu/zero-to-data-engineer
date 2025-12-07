/*
 * Lab 28: Transaction Log Management
 * Module 04: Database Administration
 * 
 * Objective: Understand and manage SQL Server transaction logs
 * Duration: 2-3 hours
 * Difficulty: ⭐⭐⭐⭐
 */

USE master;
GO

PRINT '==============================================';
PRINT 'Lab 28: Transaction Log Management';
PRINT '==============================================';
PRINT '';

/*
 * TRANSACTION LOG OVERVIEW:
 * 
 * The transaction log is a serial record of all transactions and modifications
 * made to the database. It's critical for:
 * - Ensuring ACID properties
 * - Database recovery
 * - Point-in-time restore
 * - Replication and mirroring
 * 
 * Log Structure:
 * - Divided into Virtual Log Files (VLFs)
 * - Grows in chunks (based on autogrowth settings)
 * - Circular in nature (reusable after checkpoint/backup)
 */

IF DB_ID('BookstoreDB') IS NULL
BEGIN
    PRINT 'Error: BookstoreDB not found. Run Lab 20 first.';
    RETURN;
END;
GO

USE BookstoreDB;
GO

/*
 * PART 1: EXAMINE TRANSACTION LOG
 */

PRINT 'PART 1: Examining Transaction Log';
PRINT '-----------------------------------';

-- View log file information
SELECT 
    DB_NAME() AS DatabaseName,
    name AS LogicalName,
    physical_name AS PhysicalPath,
    type_desc AS FileType,
    size * 8.0 / 1024 AS CurrentSizeMB,
    max_size * 8.0 / 1024 AS MaxSizeMB,
    CASE max_size 
        WHEN -1 THEN 'Unlimited'
        WHEN 268435456 THEN 'Unlimited'
        ELSE CAST(max_size * 8.0 / 1024 AS VARCHAR) + ' MB'
    END AS MaxSizeDescription,
    growth AS GrowthValue,
    CASE is_percent_growth
        WHEN 1 THEN CAST(growth AS VARCHAR) + '%'
        ELSE CAST(growth * 8.0 / 1024 AS VARCHAR) + ' MB'
    END AS GrowthDescription
FROM sys.database_files
WHERE type_desc = 'LOG';

PRINT '';

-- View log space usage
DBCC SQLPERF(LOGSPACE);

PRINT '';

/*
 * PART 2: VIRTUAL LOG FILES (VLFs)
 */

PRINT 'PART 2: Understanding Virtual Log Files';
PRINT '----------------------------------------';

-- Check VLF count (SQL Server 2012+)
SELECT 
    DB_NAME() AS DatabaseName,
    COUNT(*) AS VLFCount,
    SUM(CAST(vlf_size_mb AS DECIMAL(10,2))) AS TotalLogSizeMB,
    SUM(CASE WHEN vlf_status = 2 THEN CAST(vlf_size_mb AS DECIMAL(10,2)) ELSE 0 END) AS ActiveLogMB,
    SUM(CASE WHEN vlf_status = 0 THEN CAST(vlf_size_mb AS DECIMAL(10,2)) ELSE 0 END) AS InactiveLogMB
FROM sys.dm_db_log_info(DB_ID());

PRINT '';
PRINT 'VLF Guidelines:';
PRINT '  - Optimal: Less than 50 VLFs';
PRINT '  - Acceptable: 50-100 VLFs';
PRINT '  - Poor: 100-500 VLFs';
PRINT '  - Critical: >500 VLFs (severely impacts performance)';
PRINT '';

-- Detailed VLF information
SELECT 
    vlf_sequence_number,
    vlf_size_mb,
    vlf_status,
    CASE vlf_status
        WHEN 0 THEN 'Inactive (Reusable)'
        WHEN 2 THEN 'Active'
    END AS VLFStatusDescription,
    vlf_parity,
    vlf_begin_offset,
    vlf_create_lsn
FROM sys.dm_db_log_info(DB_ID())
ORDER BY vlf_sequence_number;

PRINT '';

/*
 * PART 3: TRANSACTION LOG BACKUPS
 */

PRINT 'PART 3: Transaction Log Backups';
PRINT '--------------------------------';

-- Ensure FULL recovery model (required for log backups)
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'BookstoreDB' AND recovery_model = 1)
BEGIN
    ALTER DATABASE BookstoreDB SET RECOVERY FULL;
    PRINT '✓ Set recovery model to FULL';
END;

-- Perform full backup first (establishes log backup chain)
DECLARE @FullBackupPath NVARCHAR(500) = 'C:\SQLBackups\BookstoreDB_Full_LogLab.bak';
BACKUP DATABASE BookstoreDB
TO DISK = @FullBackupPath
WITH FORMAT, NAME = 'Full Backup for Log Chain';

PRINT '✓ Full backup completed';
PRINT '';

-- Make some transactions
BEGIN TRANSACTION;
    INSERT INTO Books (Title, ISBN, PublicationYear, Price, StockQuantity, PublisherID)
    VALUES ('Log Test Book 1', '978-0-00-000011-1', 2024, 19.99, 25, 1);
    
    UPDATE Books SET Price = Price * 1.05 WHERE PublicationYear < 2000;
COMMIT TRANSACTION;

PRINT '✓ Performed transactions';
PRINT '';

-- Backup transaction log
DECLARE @LogBackupPath NVARCHAR(500) = 'C:\SQLBackups\BookstoreDB_Log_' + 
    REPLACE(CONVERT(VARCHAR, GETDATE(), 120), ':', '') + '.trn';

BACKUP LOG BookstoreDB
TO DISK = @LogBackupPath
WITH 
    NAME = 'BookstoreDB Log Backup',
    COMPRESSION,
    STATS = 10,
    CHECKSUM;

PRINT '✓ Log backup completed: ' + @LogBackupPath;
PRINT '';

-- Check log reuse wait
SELECT 
    name AS DatabaseName,
    recovery_model_desc AS RecoveryModel,
    log_reuse_wait_desc AS LogReuseWaitReason,
    CASE log_reuse_wait_desc
        WHEN 'NOTHING' THEN 'Log can be truncated/reused'
        WHEN 'CHECKPOINT' THEN 'Checkpoint has not occurred'
        WHEN 'LOG_BACKUP' THEN 'Log backup is needed'
        WHEN 'ACTIVE_BACKUP_OR_RESTORE' THEN 'Backup/restore in progress'
        WHEN 'ACTIVE_TRANSACTION' THEN 'Transaction is active'
        WHEN 'DATABASE_MIRRORING' THEN 'Mirroring is waiting'
        WHEN 'REPLICATION' THEN 'Replication has not processed'
        WHEN 'DATABASE_SNAPSHOT_CREATION' THEN 'Snapshot being created'
        WHEN 'LOG_SCAN' THEN 'Log scan in progress'
        WHEN 'AVAILABILITY_REPLICA' THEN 'AlwaysOn secondary behind'
        ELSE log_reuse_wait_desc
    END AS Explanation
FROM sys.databases
WHERE name = 'BookstoreDB';

PRINT '';

/*
 * PART 4: LOG TRUNCATION AND REUSE
 */

PRINT 'PART 4: Log Truncation and Reuse';
PRINT '----------------------------------';

-- Log space before backup
SELECT 
    name,
    log_reuse_wait_desc,
    (total_log_size_in_bytes - used_log_space_in_bytes) * 1.0 / total_log_size_in_bytes * 100 AS PercentAvailable
FROM sys.dm_db_log_space_usage;

-- Another log backup to truncate log
BACKUP LOG BookstoreDB
TO DISK = 'C:\SQLBackups\BookstoreDB_Log2.trn'
WITH NAME = 'Log Backup 2', COMPRESSION;

PRINT '✓ Second log backup completed';

-- Log space after backup
SELECT 
    name,
    log_reuse_wait_desc,
    (total_log_size_in_bytes - used_log_space_in_bytes) * 1.0 / total_log_size_in_bytes * 100 AS PercentAvailable
FROM sys.dm_db_log_space_usage;

PRINT '';

/*
 * PART 5: SHRINK LOG FILE (USE WITH CAUTION)
 */

PRINT 'PART 5: Shrinking Log File (Caution!)';
PRINT '---------------------------------------';

-- Check log size before shrink
SELECT 
    name,
    size * 8.0 / 1024 AS SizeMB,
    FILEPROPERTY(name, 'SpaceUsed') * 8.0 / 1024 AS UsedMB
FROM sys.database_files
WHERE type_desc = 'LOG';

PRINT '';

-- Shrink log file (only after log backup!)
DECLARE @LogFileName NVARCHAR(128);
SELECT @LogFileName = name FROM sys.database_files WHERE type_desc = 'LOG';

PRINT 'Shrinking log file: ' + @LogFileName;
DBCC SHRINKFILE(@LogFileName, 10);  -- Shrink to 10 MB

-- Check log size after shrink
SELECT 
    name,
    size * 8.0 / 1024 AS SizeMB,
    FILEPROPERTY(name, 'SpaceUsed') * 8.0 / 1024 AS UsedMB
FROM sys.database_files
WHERE type_desc = 'LOG';

PRINT '';
PRINT 'WARNING: Frequent log shrinking causes:';
PRINT '  - Excessive VLF fragmentation';
PRINT '  - Poor performance';
PRINT '  - Unnecessary disk I/O';
PRINT '  Better: Size log appropriately from the start';
PRINT '';

/*
 * PART 6: OPTIMIZE VLF COUNT
 */

PRINT 'PART 6: Optimizing VLF Count';
PRINT '-----------------------------';

-- Check current VLF count
DECLARE @CurrentVLFs INT;
SELECT @CurrentVLFs = COUNT(*) FROM sys.dm_db_log_info(DB_ID());
PRINT 'Current VLF count: ' + CAST(@CurrentVLFs AS VARCHAR);

IF @CurrentVLFs > 100
BEGIN
    PRINT 'VLF count is high. Rebuilding log file...';
    PRINT '';
    
    /*
    -- Steps to rebuild log with optimal VLFs:
    
    -- 1. Backup the log
    BACKUP LOG BookstoreDB TO DISK = 'C:\SQLBackups\BookstoreDB_PreRebuild.trn';
    
    -- 2. Shrink log to minimum
    DBCC SHRINKFILE(@LogFileName, 1);
    
    -- 3. Set log to fixed size (prevents autogrowth fragmentation)
    ALTER DATABASE BookstoreDB 
    MODIFY FILE (
        NAME = @LogFileName,
        SIZE = 512MB,        -- Size based on workload
        MAXSIZE = 2GB,
        FILEGROWTH = 512MB   -- Large growth increments
    );
    
    -- This creates optimal VLF structure
    */
    
    PRINT 'Log rebuild steps (commented out):';
    PRINT '  1. BACKUP LOG';
    PRINT '  2. SHRINK LOG to minimum';
    PRINT '  3. ALTER DATABASE ... MODIFY FILE (large SIZE, large FILEGROWTH)';
END;

PRINT '';

/*
 * PART 7: MONITOR ACTIVE TRANSACTIONS
 */

PRINT 'PART 7: Monitoring Active Transactions';
PRINT '---------------------------------------';

-- View active transactions
SELECT 
    DB_NAME(transaction_id) AS DatabaseName,
    transaction_id,
    transaction_begin_time,
    DATEDIFF(SECOND, transaction_begin_time, GETDATE()) AS DurationSeconds,
    CASE transaction_type
        WHEN 1 THEN 'Read/Write'
        WHEN 2 THEN 'Read-Only'
        WHEN 3 THEN 'System'
        WHEN 4 THEN 'Distributed'
    END AS TransactionType,
    CASE transaction_state
        WHEN 0 THEN 'Uninitialized'
        WHEN 1 THEN 'Initialized not started'
        WHEN 2 THEN 'Active'
        WHEN 3 THEN 'Ended (read-only)'
        WHEN 4 THEN 'Commit initiated'
        WHEN 5 THEN 'Prepared waiting'
        WHEN 6 THEN 'Committed'
        WHEN 7 THEN 'Rolling back'
        WHEN 8 THEN 'Rolled back'
    END AS TransactionState
FROM sys.dm_tran_active_transactions
WHERE database_id = DB_ID();

PRINT '';

-- View transaction log usage by transaction
SELECT 
    s.session_id,
    s.login_name,
    s.host_name,
    s.program_name,
    t.transaction_id,
    DATEDIFF(SECOND, t.transaction_begin_time, GETDATE()) AS DurationSeconds,
    dt.database_transaction_log_bytes_used / 1024.0 / 1024.0 AS LogUsedMB,
    dt.database_transaction_log_bytes_reserved / 1024.0 / 1024.0 AS LogReservedMB
FROM sys.dm_tran_session_transactions st
INNER JOIN sys.dm_tran_active_transactions t ON st.transaction_id = t.transaction_id
INNER JOIN sys.dm_exec_sessions s ON st.session_id = s.session_id
INNER JOIN sys.dm_tran_database_transactions dt ON t.transaction_id = dt.transaction_id
WHERE dt.database_id = DB_ID()
ORDER BY dt.database_transaction_log_bytes_used DESC;

PRINT '';

/*
 * PART 8: LOG GROWTH EVENTS
 */

PRINT 'PART 8: Monitoring Log Growth Events';
PRINT '--------------------------------------';

-- Query default trace for autogrowth events (if enabled)
DECLARE @TraceFile NVARCHAR(500);
SELECT @TraceFile = SUBSTRING(path, 1, LEN(path) - CHARINDEX('\', REVERSE(path))) + '\log.trc'
FROM sys.traces
WHERE is_default = 1;

IF @TraceFile IS NOT NULL
BEGIN
    SELECT TOP 20
        DatabaseName,
        FileName,
        CASE EventClass
            WHEN 92 THEN 'Data File Auto Grow'
            WHEN 93 THEN 'Log File Auto Grow'
            WHEN 94 THEN 'Data File Auto Shrink'
            WHEN 95 THEN 'Log File Auto Shrink'
        END AS EventType,
        StartTime,
        Duration / 1000 AS DurationMS,
        (IntegerData * 8.0 / 1024) AS SizeChangeMB
    FROM fn_trace_gettable(@TraceFile, DEFAULT)
    WHERE EventClass IN (92, 93, 94, 95)
        AND DatabaseName = 'BookstoreDB'
    ORDER BY StartTime DESC;
    
    PRINT '(Recent autogrowth events from default trace)';
END
ELSE
BEGIN
    PRINT 'Default trace not enabled';
END;

PRINT '';

/*
 * PART 9: LOG BACKUP STRATEGIES
 */

PRINT 'PART 9: Log Backup Strategies';
PRINT '------------------------------';
PRINT '';
PRINT 'FREQUENCY RECOMMENDATIONS:';
PRINT '';
PRINT '1. HIGH AVAILABILITY (RPO < 5 minutes):';
PRINT '   - Log backup every 5-15 minutes';
PRINT '   - AlwaysOn or mirroring for real-time';
PRINT '';
PRINT '2. STANDARD (RPO < 1 hour):';
PRINT '   - Log backup every 15-30 minutes';
PRINT '   - Balance between data loss and overhead';
PRINT '';
PRINT '3. BATCH SYSTEMS (RPO < 24 hours):';
PRINT '   - Log backup every 1-4 hours';
PRINT '   - Less frequent updates';
PRINT '';
PRINT 'BACKUP SCHEDULE EXAMPLE:';
PRINT '  Sunday:    Full backup';
PRINT '  Mon-Sat:   Differential backup (daily)';
PRINT '  All days:  Log backup every 15 minutes';
PRINT '';

/*
 * PART 10: TROUBLESHOOTING LOG ISSUES
 */

PRINT 'PART 10: Troubleshooting Log Issues';
PRINT '-------------------------------------';
PRINT '';
PRINT 'ISSUE: Log file growing too large';
PRINT 'SOLUTIONS:';
PRINT '  1. Backup log more frequently';
PRINT '  2. Check for long-running transactions (KILL if needed)';
PRINT '  3. Check replication/mirroring lag';
PRINT '  4. Verify log_reuse_wait_desc';
PRINT '';
PRINT 'ISSUE: Transaction log full error';
PRINT 'IMMEDIATE ACTIONS:';
PRINT '  1. BACKUP LOG ... TO DISK (frees space)';
PRINT '  2. Find and terminate long transactions';
PRINT '  3. Switch to SIMPLE recovery temporarily (DATA LOSS RISK!)';
PRINT '  4. Add more disk space';
PRINT '';
PRINT 'ISSUE: Too many VLFs (slow performance)';
PRINT 'SOLUTION:';
PRINT '  1. Backup and shrink log';
PRINT '  2. Set large fixed size with large growth increments';
PRINT '  3. Prevents future fragmentation';
PRINT '';

-- Script to find blocking transactions
PRINT 'Query to find long-running transactions:';
PRINT '';
PRINT 'SELECT s.session_id, s.login_name,';
PRINT '       DATEDIFF(SECOND, t.transaction_begin_time, GETDATE()) AS DurationSec,';
PRINT '       r.blocking_session_id, r.wait_type, r.wait_time,';
PRINT '       SUBSTRING(qt.text, r.statement_start_offset/2+1,';
PRINT '                 CASE WHEN r.statement_end_offset=-1';
PRINT '                      THEN LEN(CONVERT(NVARCHAR(MAX),qt.text))*2';
PRINT '                      ELSE r.statement_end_offset-r.statement_start_offset';
PRINT '                 END/2) AS CurrentQuery';
PRINT 'FROM sys.dm_tran_active_transactions t';
PRINT 'INNER JOIN sys.dm_tran_session_transactions st ON t.transaction_id = st.transaction_id';
PRINT 'INNER JOIN sys.dm_exec_sessions s ON st.session_id = s.session_id';
PRINT 'LEFT JOIN sys.dm_exec_requests r ON s.session_id = r.session_id';
PRINT 'OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) qt';
PRINT 'ORDER BY DurationSec DESC;';
PRINT '';

/*
 * EXERCISES:
 * 
 * 1. Create a SQL Agent job to backup logs every 15 minutes
 * 2. Implement alerting when log reaches 80% full
 * 3. Script to automatically find and kill long-running transactions
 * 4. Create a log growth history report
 * 5. Build a dashboard monitoring VLF count across all databases
 * 
 * CHALLENGE:
 * Design a complete transaction log management solution:
 * - Automated log backups with retention policy
 * - VLF monitoring and optimization
 * - Alert system for log issues
 * - Long transaction detection and notification
 * - Log size trending and capacity planning
 * - Disaster recovery testing
 */

PRINT '✓ Lab 28 Complete: Transaction log management mastered';
PRINT '';
PRINT 'Key Takeaways:';
PRINT '  - Log backups are essential in FULL recovery model';
PRINT '  - VLF count impacts performance (keep under 100)';
PRINT '  - Size log files properly to prevent autogrowth';
PRINT '  - Monitor log_reuse_wait_desc to diagnose issues';
PRINT '  - Regular log backups prevent log file bloat';
GO
