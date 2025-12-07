/*
 * Lab 29: Recovery Models
 * Module 04: Database Administration
 * 
 * Objective: Understand and configure database recovery models
 * Duration: 1-2 hours
 * Difficulty: ⭐⭐⭐
 */

USE master;
GO

PRINT '==============================================';
PRINT 'Lab 29: Database Recovery Models';
PRINT '==============================================';
PRINT '';

/*
 * THREE RECOVERY MODELS:
 * 
 * 1. SIMPLE:
 *    - Log automatically truncated after checkpoint
 *    - Cannot do point-in-time recovery
 *    - No log backups possible
 *    - Smallest log file size
 *    - Data loss: Changes since last full/differential backup
 * 
 * 2. FULL:
 *    - All transactions logged
 *    - Point-in-time recovery possible
 *    - Requires log backups
 *    - Largest log file (until backed up)
 *    - Data loss: Minimal (to last log backup)
 * 
 * 3. BULK_LOGGED:
 *    - Minimal logging for bulk operations
 *    - Better performance for large data loads
 *    - Point-in-time recovery limited during bulk operations
 *    - Requires log backups
 *    - Hybrid between SIMPLE and FULL
 */

IF DB_ID('BookstoreDB') IS NULL
BEGIN
    PRINT 'Error: BookstoreDB not found. Run Lab 20 first.';
    RETURN;
END;
GO

/*
 * PART 1: CHECK CURRENT RECOVERY MODEL
 */

PRINT 'PART 1: Checking Current Recovery Model';
PRINT '----------------------------------------';

-- Query recovery model for all databases
SELECT 
    name AS DatabaseName,
    recovery_model_desc AS RecoveryModel,
    log_reuse_wait_desc AS LogReuseWait,
    state_desc AS DatabaseState,
    create_date,
    CASE recovery_model_desc
        WHEN 'SIMPLE' THEN 'No log backups, auto-truncate, no point-in-time recovery'
        WHEN 'FULL' THEN 'Full logging, log backups required, point-in-time recovery'
        WHEN 'BULK_LOGGED' THEN 'Minimal logging for bulk ops, log backups required'
    END AS Description
FROM sys.databases
WHERE name IN ('BookstoreDB', 'master', 'model', 'msdb', 'tempdb')
ORDER BY name;

PRINT '';

/*
 * PART 2: SIMPLE RECOVERY MODEL
 */

PRINT 'PART 2: SIMPLE Recovery Model';
PRINT '------------------------------';

-- Switch to SIMPLE recovery
ALTER DATABASE BookstoreDB SET RECOVERY SIMPLE;
PRINT '✓ Changed to SIMPLE recovery model';

-- View recovery model
SELECT name, recovery_model_desc FROM sys.databases WHERE name = 'BookstoreDB';
PRINT '';

USE BookstoreDB;
GO

-- Perform some transactions
BEGIN TRANSACTION;
    INSERT INTO Books (Title, ISBN, PublicationYear, Price, StockQuantity, PublisherID)
    VALUES ('Simple Recovery Test', '978-0-00-000020-1', 2024, 15.99, 20, 1);
    
    UPDATE Books SET Price = Price + 1 WHERE PublicationYear = 2024;
COMMIT TRANSACTION;

PRINT '✓ Performed transactions in SIMPLE mode';
PRINT '';

-- Try to backup log (will fail in SIMPLE mode)
BEGIN TRY
    BACKUP LOG BookstoreDB TO DISK = 'C:\SQLBackups\BookstoreDB_Log_Simple.trn';
    PRINT '✗ ERROR: Log backup should not work in SIMPLE mode!';
END TRY
BEGIN CATCH
    PRINT '✓ Log backup failed (expected in SIMPLE mode)';
    PRINT '  Error: ' + ERROR_MESSAGE();
END CATCH;

PRINT '';

-- Force checkpoint (truncates log in SIMPLE mode)
CHECKPOINT;
PRINT '✓ Checkpoint executed (log auto-truncated in SIMPLE mode)';

-- View log space usage
SELECT 
    name AS DatabaseName,
    (total_log_size_in_bytes / 1024.0 / 1024.0) AS TotalLogMB,
    (used_log_space_in_bytes / 1024.0 / 1024.0) AS UsedLogMB,
    (used_log_space_in_percent) AS UsedLogPercent,
    log_space_in_bytes_since_last_backup / 1024.0 / 1024.0 AS LogSinceBackupMB
FROM sys.dm_db_log_space_usage;

PRINT '';

PRINT 'SIMPLE Recovery Model Summary:';
PRINT '  ✓ Pros: Automatic log management, no log backups needed, small log';
PRINT '  ✗ Cons: No point-in-time recovery, data loss to last full/diff backup';
PRINT '  Use case: Dev/test databases, data warehouses (ETL reload)';
PRINT '';

/*
 * PART 3: FULL RECOVERY MODEL
 */

USE master;
GO

PRINT 'PART 3: FULL Recovery Model';
PRINT '----------------------------';

-- Switch to FULL recovery
ALTER DATABASE BookstoreDB SET RECOVERY FULL;
PRINT '✓ Changed to FULL recovery model';
PRINT '';

USE BookstoreDB;
GO

-- Take full backup (establishes log chain)
BACKUP DATABASE BookstoreDB
TO DISK = 'C:\SQLBackups\BookstoreDB_Full_Recovery.bak'
WITH FORMAT, NAME = 'Full Backup - Establish Log Chain';

PRINT '✓ Full backup taken (log chain established)';
PRINT '';

-- Perform transactions
BEGIN TRANSACTION;
    INSERT INTO Books (Title, ISBN, PublicationYear, Price, StockQuantity, PublisherID)
    VALUES ('Full Recovery Test 1', '978-0-00-000021-1', 2024, 16.99, 15, 1);
    WAITFOR DELAY '00:00:02';
END;
COMMIT TRANSACTION;

DECLARE @Time1 DATETIME = GETDATE();
PRINT 'Marker 1: ' + CONVERT(VARCHAR, @Time1, 120);
WAITFOR DELAY '00:00:02';

BEGIN TRANSACTION;
    INSERT INTO Books (Title, ISBN, PublicationYear, Price, StockQuantity, PublisherID)
    VALUES ('Full Recovery Test 2', '978-0-00-000022-2', 2024, 17.99, 10, 1);
COMMIT TRANSACTION;

DECLARE @Time2 DATETIME = GETDATE();
PRINT 'Marker 2: ' + CONVERT(VARCHAR, @Time2, 120);
PRINT '';

-- Backup log (now works in FULL mode)
BACKUP LOG BookstoreDB
TO DISK = 'C:\SQLBackups\BookstoreDB_Log_Full.trn'
WITH NAME = 'Log Backup - Full Recovery', COMPRESSION;

PRINT '✓ Log backup successful (FULL recovery)';
PRINT '';

-- View log space after backup
SELECT 
    name AS DatabaseName,
    (total_log_size_in_bytes / 1024.0 / 1024.0) AS TotalLogMB,
    (used_log_space_in_bytes / 1024.0 / 1024.0) AS UsedLogMB,
    (used_log_space_in_percent) AS UsedLogPercent
FROM sys.dm_db_log_space_usage;

PRINT '';

PRINT 'FULL Recovery Model Summary:';
PRINT '  ✓ Pros: Point-in-time recovery, minimal data loss';
PRINT '  ✗ Cons: Requires log backups, larger log file, more management';
PRINT '  Use case: Production OLTP systems, critical data';
PRINT '';

/*
 * PART 4: BULK_LOGGED RECOVERY MODEL
 */

USE master;
GO

PRINT 'PART 4: BULK_LOGGED Recovery Model';
PRINT '------------------------------------';

-- Switch to BULK_LOGGED
ALTER DATABASE BookstoreDB SET RECOVERY BULK_LOGGED;
PRINT '✓ Changed to BULK_LOGGED recovery model';
PRINT '';

USE BookstoreDB;
GO

-- Create staging table for bulk operations
IF OBJECT_ID('BooksStaging', 'U') IS NOT NULL DROP TABLE BooksStaging;

CREATE TABLE BooksStaging (
    Title NVARCHAR(200),
    ISBN NVARCHAR(20),
    PublicationYear INT,
    Price DECIMAL(10,2),
    StockQuantity INT,
    PublisherID INT
);

-- Bulk insert (minimally logged in BULK_LOGGED mode)
DECLARE @i INT = 1;
WHILE @i <= 1000
BEGIN
    INSERT INTO BooksStaging (Title, ISBN, PublicationYear, Price, StockQuantity, PublisherID)
    VALUES 
        ('Bulk Test Book ' + CAST(@i AS VARCHAR), 
         '978-0-99-' + RIGHT('000000' + CAST(@i AS VARCHAR), 6) + '-1',
         2024, 19.99, 100, 1);
    SET @i = @i + 1;
END;

PRINT '✓ Inserted 1000 rows (minimally logged in BULK_LOGGED)';
PRINT '';

-- Switch back to FULL and take log backup
ALTER DATABASE BookstoreDB SET RECOVERY FULL;
BACKUP LOG BookstoreDB
TO DISK = 'C:\SQLBackups\BookstoreDB_Log_BulkLogged.trn'
WITH NAME = 'Log After Bulk Operation';

PRINT '✓ Switched back to FULL and backed up log';
PRINT '';

-- Cleanup
DROP TABLE BooksStaging;

PRINT 'BULK_LOGGED Recovery Model Summary:';
PRINT '  ✓ Pros: Better performance for bulk operations, smaller log';
PRINT '  ✗ Cons: Point-in-time recovery limited during bulk ops';
PRINT '  Use case: Large data loads, index rebuilds, SELECT INTO';
PRINT '  Best practice: Switch to BULK_LOGGED temporarily, then back to FULL';
PRINT '';

/*
 * PART 5: RECOVERY MODEL COMPARISON
 */

PRINT 'PART 5: Recovery Model Comparison';
PRINT '-----------------------------------';
PRINT '';
PRINT '┌────────────────┬────────┬─────────────┬───────────────┐';
PRINT '│ Feature        │ SIMPLE │ FULL        │ BULK_LOGGED   │';
PRINT '├────────────────┼────────┼─────────────┼───────────────┤';
PRINT '│ Log Backups    │ No     │ Required    │ Required      │';
PRINT '│ Point-in-Time  │ No     │ Yes         │ Limited       │';
PRINT '│ Log Truncation │ Auto   │ After backup│ After backup  │';
PRINT '│ Log Size       │ Small  │ Large       │ Medium        │';
PRINT '│ Bulk Ops       │ Minimal│ Full        │ Minimal       │';
PRINT '│ Performance    │ Good   │ Standard    │ Better (bulk) │';
PRINT '│ Data Loss Risk │ High   │ Low         │ Low           │';
PRINT '└────────────────┴────────┴─────────────┴───────────────┘';
PRINT '';

/*
 * PART 6: DECISION TREE
 */

PRINT 'PART 6: Choosing a Recovery Model';
PRINT '-----------------------------------';
PRINT '';
PRINT 'USE SIMPLE WHEN:';
PRINT '  ✓ Development or test databases';
PRINT '  ✓ Data can be recreated from other sources';
PRINT '  ✓ Data warehouse (reloaded nightly)';
PRINT '  ✓ Point-in-time recovery not needed';
PRINT '  ✓ Scheduled downtime acceptable';
PRINT '';
PRINT 'USE FULL WHEN:';
PRINT '  ✓ Production OLTP databases';
PRINT '  ✓ Critical business data';
PRINT '  ✓ Point-in-time recovery required';
PRINT '  ✓ Minimal data loss acceptable';
PRINT '  ✓ 24/7 availability needed';
PRINT '';
PRINT 'USE BULK_LOGGED WHEN:';
PRINT '  ✓ Temporarily during large data loads';
PRINT '  ✓ Index maintenance windows';
PRINT '  ✓ Then switch back to FULL immediately';
PRINT '';

/*
 * PART 7: CHANGING RECOVERY MODELS SAFELY
 */

PRINT 'PART 7: Safe Recovery Model Changes';
PRINT '-------------------------------------';
PRINT '';
PRINT 'SIMPLE → FULL:';
PRINT '  1. ALTER DATABASE ... SET RECOVERY FULL';
PRINT '  2. BACKUP DATABASE (full backup)';
PRINT '  3. Schedule regular log backups';
PRINT '';
PRINT 'FULL → SIMPLE:';
PRINT '  1. BACKUP LOG ... (final log backup)';
PRINT '  2. ALTER DATABASE ... SET RECOVERY SIMPLE';
PRINT '  3. Log automatically truncates';
PRINT '  WARNING: Cannot restore to point-in-time after this!';
PRINT '';
PRINT 'FULL → BULK_LOGGED (temporary):';
PRINT '  1. BACKUP LOG ... (before change)';
PRINT '  2. ALTER DATABASE ... SET RECOVERY BULK_LOGGED';
PRINT '  3. Perform bulk operations';
PRINT '  4. ALTER DATABASE ... SET RECOVERY FULL';
PRINT '  5. BACKUP LOG ... (after change)';
PRINT '';

/*
 * PART 8: MONITORING RECOVERY MODEL
 */

PRINT 'PART 8: Monitoring Recovery Model';
PRINT '-----------------------------------';

-- Script to check all databases
SELECT 
    d.name AS DatabaseName,
    d.recovery_model_desc AS RecoveryModel,
    d.log_reuse_wait_desc AS LogReuseWait,
    d.state_desc AS State,
    CASE 
        WHEN d.recovery_model_desc = 'SIMPLE' THEN 'OK - No log backups needed'
        WHEN d.recovery_model_desc IN ('FULL', 'BULK_LOGGED') 
             AND d.log_reuse_wait_desc = 'LOG_BACKUP' THEN 'WARNING - Log backup needed'
        WHEN d.recovery_model_desc IN ('FULL', 'BULK_LOGGED') 
             AND d.log_reuse_wait_desc = 'NOTHING' THEN 'OK - Log backed up recently'
        ELSE 'CHECK REQUIRED - ' + d.log_reuse_wait_desc
    END AS Status,
    bs.backup_finish_date AS LastFullBackup,
    ls.backup_finish_date AS LastLogBackup
FROM sys.databases d
LEFT JOIN (
    SELECT database_name, MAX(backup_finish_date) AS backup_finish_date
    FROM msdb.dbo.backupset
    WHERE type = 'D'  -- Full backup
    GROUP BY database_name
) bs ON d.name = bs.database_name
LEFT JOIN (
    SELECT database_name, MAX(backup_finish_date) AS backup_finish_date
    FROM msdb.dbo.backupset
    WHERE type = 'L'  -- Log backup
    GROUP BY database_name
) ls ON d.name = ls.database_name
WHERE d.database_id > 4  -- Exclude system databases
ORDER BY d.name;

PRINT '';

/*
 * PART 9: RECOVERY MODEL BEST PRACTICES
 */

PRINT 'PART 9: Best Practices';
PRINT '-----------------------';
PRINT '';
PRINT '1. SET CORRECT MODEL FROM START:';
PRINT '   - Use model database as template';
PRINT '   - ALTER DATABASE model SET RECOVERY FULL';
PRINT '   - All new databases inherit this setting';
PRINT '';
PRINT '2. SCHEDULE LOG BACKUPS (FULL/BULK_LOGGED):';
PRINT '   - Every 15-30 minutes for critical systems';
PRINT '   - Every 1-4 hours for standard systems';
PRINT '   - Monitor log file growth';
PRINT '';
PRINT '3. DOCUMENT RPO/RTO:';
PRINT '   - RPO (Recovery Point Objective): Acceptable data loss';
PRINT '   - RTO (Recovery Time Objective): Acceptable downtime';
PRINT '   - Recovery model affects both metrics';
PRINT '';
PRINT '4. TEST RESTORES REGULARLY:';
PRINT '   - Verify backups are valid';
PRINT '   - Practice point-in-time recovery';
PRINT '   - Document recovery procedures';
PRINT '';
PRINT '5. MONITOR AND ALERT:';
PRINT '   - Log file size growth';
PRINT '   - Missed log backups';
PRINT '   - Recovery model changes';
PRINT '';

/*
 * PART 10: SET DEFAULT FOR NEW DATABASES
 */

PRINT 'PART 10: Setting Defaults';
PRINT '--------------------------';

-- Check model database recovery model
SELECT 
    name,
    recovery_model_desc,
    CASE recovery_model_desc
        WHEN 'SIMPLE' THEN 'New databases will use SIMPLE'
        WHEN 'FULL' THEN 'New databases will use FULL'
        WHEN 'BULK_LOGGED' THEN 'New databases will use BULK_LOGGED'
    END AS Impact
FROM sys.databases
WHERE name = 'model';

PRINT '';
PRINT 'To set default recovery model for new databases:';
PRINT '  ALTER DATABASE model SET RECOVERY FULL;';
PRINT '';

-- Restore BookstoreDB to FULL recovery
ALTER DATABASE BookstoreDB SET RECOVERY FULL;
PRINT '✓ Restored BookstoreDB to FULL recovery model';

/*
 * EXERCISES:
 * 
 * 1. Create a script to audit recovery models across all databases
 * 2. Implement automated alerts when log_reuse_wait = LOG_BACKUP
 * 3. Test point-in-time recovery using FULL model
 * 4. Measure performance difference: FULL vs BULK_LOGGED for bulk insert
 * 5. Document RPO/RTO for each database
 * 
 * CHALLENGE:
 * Build a recovery model management system:
 * - Daily audit of all recovery models
 * - Automated alerts for incorrect settings
 * - Performance monitoring (log growth, backup duration)
 * - Compliance reporting
 * - Disaster recovery testing automation
 */

PRINT '';
PRINT '✓ Lab 29 Complete: Recovery models mastered';
PRINT '';
PRINT 'Key Decision Factors:';
PRINT '  - Data criticality (can it be recreated?)';
PRINT '  - RPO requirements (acceptable data loss)';
PRINT '  - RTO requirements (acceptable downtime)';
PRINT '  - Compliance requirements';
PRINT '  - Available disk space for log files';
PRINT '  - Backup management capabilities';
GO
