/*
 * Lab 23: Differential Database Backups
 * Module 04: Database Administration
 * 
 * Objective: Implement differential backup strategy for faster recovery
 * Duration: 1-2 hours
 * Difficulty: ⭐⭐⭐
 */

USE master;
GO

PRINT '==============================================';
PRINT 'Lab 23: Differential Database Backups';
PRINT '==============================================';
PRINT '';

/*
 * DIFFERENTIAL BACKUP OVERVIEW:
 * 
 * - Backs up only data changed since the last FULL backup
 * - Faster than full backups (smaller size)
 * - Slower than transaction log backups
 * - Requires a full backup as base
 * 
 * RESTORE SEQUENCE:
 * 1. Restore FULL backup
 * 2. Restore latest DIFFERENTIAL backup
 * 3. Restore transaction log backups (if any)
 */

-- Ensure BookstoreDB exists
IF DB_ID('BookstoreDB') IS NULL
BEGIN
    PRINT 'Error: BookstoreDB not found. Run Lab 20 first.';
    RETURN;
END;
GO

USE BookstoreDB;
GO

-- Set recovery model to FULL for complete backup capabilities
ALTER DATABASE BookstoreDB SET RECOVERY FULL;
GO

/*
 * PART 1: CREATE FULL BACKUP (BASE)
 */

PRINT 'PART 1: Creating Full Backup (Base)';
PRINT '------------------------------------';

DECLARE @FullBackupPath NVARCHAR(500);
DECLARE @BackupName NVARCHAR(200);

SET @FullBackupPath = 'C:\SQLBackups\BookstoreDB_Full_' + 
    REPLACE(CONVERT(VARCHAR, GETDATE(), 120), ':', '') + '.bak';
SET @BackupName = 'BookstoreDB Full Backup - ' + CONVERT(VARCHAR, GETDATE(), 120);

BACKUP DATABASE BookstoreDB
TO DISK = @FullBackupPath
WITH FORMAT,
     NAME = @BackupName,
     COMPRESSION,
     STATS = 10,
     CHECKSUM;

PRINT '✓ Full backup completed: ' + @FullBackupPath;
PRINT '';

/*
 * PART 2: MAKE CHANGES TO DATABASE
 */

PRINT 'PART 2: Making Database Changes';
PRINT '--------------------------------';

-- Insert new books
INSERT INTO Books (Title, ISBN, PublicationYear, Price, StockQuantity, PublisherID)
VALUES 
    ('The Great Gatsby', '978-0-7432-7356-5', 1925, 12.99, 50, 1),
    ('To Kill a Mockingbird', '978-0-06-112008-4', 1960, 14.99, 45, 2),
    ('Brave New World', '978-0-06-085052-4', 1932, 13.99, 30, 3);

PRINT '✓ Inserted 3 new books';

-- Update prices
UPDATE Books SET Price = Price * 1.10 WHERE PublicationYear < 1950;
PRINT '✓ Updated prices for books published before 1950';

-- Insert new customer
INSERT INTO Customers (FirstName, LastName, Email, Phone, Address)
VALUES ('Jane', 'Smith', 'jane.smith@email.com', '555-9876', '456 Oak Ave');

PRINT '✓ Inserted 1 new customer';
PRINT '';

-- Show database size and change info
SELECT 
    name AS FileName,
    size * 8.0 / 1024 AS FileSizeMB,
    FILEPROPERTY(name, 'SpaceUsed') * 8.0 / 1024 AS UsedSpaceMB,
    (size - FILEPROPERTY(name, 'SpaceUsed')) * 8.0 / 1024 AS FreeSpaceMB
FROM sys.database_files;

PRINT '';

/*
 * PART 3: CREATE DIFFERENTIAL BACKUP
 */

PRINT 'PART 3: Creating Differential Backup';
PRINT '-------------------------------------';

DECLARE @DiffBackupPath NVARCHAR(500);
DECLARE @DiffBackupName NVARCHAR(200);

SET @DiffBackupPath = 'C:\SQLBackups\BookstoreDB_Diff_' + 
    REPLACE(CONVERT(VARCHAR, GETDATE(), 120), ':', '') + '.bak';
SET @DiffBackupName = 'BookstoreDB Differential Backup - ' + CONVERT(VARCHAR, GETDATE(), 120);

-- Wait 2 seconds to ensure timestamp difference
WAITFOR DELAY '00:00:02';

BACKUP DATABASE BookstoreDB
TO DISK = @DiffBackupPath
WITH DIFFERENTIAL,  -- Key: specifies differential backup
     NAME = @DiffBackupName,
     COMPRESSION,
     STATS = 10,
     CHECKSUM;

PRINT '✓ Differential backup completed: ' + @DiffBackupPath;
PRINT '';

/*
 * PART 4: COMPARE BACKUP SIZES
 */

PRINT 'PART 4: Comparing Backup Sizes';
PRINT '--------------------------------';

-- Query backup history
SELECT 
    database_name,
    backup_set_id,
    type AS BackupType,
    CASE type
        WHEN 'D' THEN 'Full'
        WHEN 'I' THEN 'Differential'
        WHEN 'L' THEN 'Transaction Log'
    END AS BackupTypeDesc,
    backup_start_date,
    backup_finish_date,
    DATEDIFF(SECOND, backup_start_date, backup_finish_date) AS DurationSeconds,
    backup_size / 1024 / 1024 AS BackupSizeMB,
    compressed_backup_size / 1024 / 1024 AS CompressedSizeMB,
    CAST((1 - compressed_backup_size * 1.0 / backup_size) * 100 AS DECIMAL(5,2)) AS CompressionRatio
FROM msdb.dbo.backupset
WHERE database_name = 'BookstoreDB'
    AND backup_start_date >= DATEADD(HOUR, -1, GETDATE())
ORDER BY backup_start_date DESC;

PRINT '';

/*
 * PART 5: MULTIPLE DIFFERENTIAL BACKUPS
 */

PRINT 'PART 5: Multiple Differential Backups';
PRINT '--------------------------------------';

-- Make more changes
INSERT INTO Books (Title, ISBN, PublicationYear, Price, StockQuantity, PublisherID)
VALUES ('Fahrenheit 451', '978-1-4516-7331-9', 1953, 15.99, 40, 1);

PRINT '✓ Inserted another book';

-- Second differential backup
DECLARE @Diff2BackupPath NVARCHAR(500);
SET @Diff2BackupPath = 'C:\SQLBackups\BookstoreDB_Diff2_' + 
    REPLACE(CONVERT(VARCHAR, GETDATE(), 120), ':', '') + '.bak';

WAITFOR DELAY '00:00:02';

BACKUP DATABASE BookstoreDB
TO DISK = @Diff2BackupPath
WITH DIFFERENTIAL,
     NAME = 'BookstoreDB Differential Backup 2',
     COMPRESSION,
     STATS = 10;

PRINT '✓ Second differential backup completed';
PRINT '';

/*
 * IMPORTANT NOTE:
 * Each differential backup contains ALL changes since the last FULL backup,
 * not just changes since the last differential backup.
 * Therefore, to restore, you only need the FULL + the LATEST differential.
 */

PRINT 'Note: Each differential contains ALL changes since last FULL backup';
PRINT '';

/*
 * PART 6: RESTORE SIMULATION (Commented - DO NOT RUN on production)
 */

PRINT 'PART 6: Restore Sequence (Demonstration)';
PRINT '-----------------------------------------';

-- The restore sequence would be:
/*
-- Step 1: Restore FULL backup with NORECOVERY
RESTORE DATABASE BookstoreDB_Restored
FROM DISK = 'C:\SQLBackups\BookstoreDB_Full_*.bak'
WITH NORECOVERY,  -- Keeps DB in restoring state
     MOVE 'BookstoreDB' TO 'C:\SQLData\BookstoreDB_Restored.mdf',
     MOVE 'BookstoreDB_log' TO 'C:\SQLData\BookstoreDB_Restored_log.ldf',
     REPLACE;

-- Step 2: Restore latest DIFFERENTIAL backup with RECOVERY
RESTORE DATABASE BookstoreDB_Restored
FROM DISK = 'C:\SQLBackups\BookstoreDB_Diff2_*.bak'
WITH RECOVERY;  -- Completes the restore

-- Database is now online and accessible
*/

PRINT 'Restore sequence (if needed):';
PRINT '  1. RESTORE DATABASE ... FROM FULL backup WITH NORECOVERY';
PRINT '  2. RESTORE DATABASE ... FROM DIFF backup WITH RECOVERY';
PRINT '';

/*
 * PART 7: DIFFERENTIAL BASE LSN
 */

PRINT 'PART 7: Understanding Differential Base';
PRINT '----------------------------------------';

-- Query to see differential base LSN
SELECT 
    database_name,
    backup_set_id,
    CASE type
        WHEN 'D' THEN 'Full'
        WHEN 'I' THEN 'Differential'
    END AS BackupType,
    backup_start_date,
    database_backup_lsn,  -- LSN of the base full backup
    differential_base_lsn,  -- For differential backups
    CASE 
        WHEN differential_base_lsn IS NULL THEN 'N/A (Full Backup)'
        ELSE CAST(differential_base_lsn AS VARCHAR)
    END AS DiffBaseInfo
FROM msdb.dbo.backupset
WHERE database_name = 'BookstoreDB'
    AND type IN ('D', 'I')
    AND backup_start_date >= DATEADD(HOUR, -1, GETDATE())
ORDER BY backup_start_date;

PRINT '';

/*
 * PART 8: BACKUP STRATEGY RECOMMENDATIONS
 */

PRINT 'PART 8: Backup Strategy Recommendations';
PRINT '----------------------------------------';
PRINT '';
PRINT 'TYPICAL STRATEGIES:';
PRINT '';
PRINT '1. SMALL DATABASES (<10 GB):';
PRINT '   - Full backup: Daily';
PRINT '   - Differential: Not needed';
PRINT '   - Transaction log: Every 15-60 minutes';
PRINT '';
PRINT '2. MEDIUM DATABASES (10-100 GB):';
PRINT '   - Full backup: Weekly (Sunday)';
PRINT '   - Differential: Daily (Mon-Sat)';
PRINT '   - Transaction log: Every 15 minutes';
PRINT '';
PRINT '3. LARGE DATABASES (>100 GB):';
PRINT '   - Full backup: Weekly';
PRINT '   - Differential: Every 6-12 hours';
PRINT '   - Transaction log: Every 5-15 minutes';
PRINT '';
PRINT 'BENEFITS OF DIFFERENTIAL:';
PRINT '  ✓ Faster than full backups';
PRINT '  ✓ Simpler restore than many log backups';
PRINT '  ✓ Good balance between full and log backups';
PRINT '';

/*
 * PART 9: DIFFERENTIAL BITMAP
 */

PRINT 'PART 9: Differential Change Tracking';
PRINT '-------------------------------------';

-- SQL Server tracks changed pages using differential changed map (DCM)
-- Each extent (8 pages) has a bit indicating if it changed since last full backup

-- View database backup information
SELECT 
    DB_NAME() AS DatabaseName,
    recovery_model_desc AS RecoveryModel,
    log_reuse_wait_desc AS LogReuseWait,
    state_desc AS DatabaseState
FROM sys.databases
WHERE name = 'BookstoreDB';

PRINT '';

/*
 * PART 10: CLEANUP AND MAINTENANCE
 */

PRINT 'PART 10: Backup File Management';
PRINT '--------------------------------';

-- Query to identify old backups for cleanup
SELECT 
    database_name,
    physical_device_name,
    backup_start_date,
    DATEDIFF(DAY, backup_start_date, GETDATE()) AS DaysOld,
    backup_size / 1024 / 1024 AS SizeMB,
    CASE 
        WHEN DATEDIFF(DAY, backup_start_date, GETDATE()) > 30 THEN 'DELETE'
        WHEN DATEDIFF(DAY, backup_start_date, GETDATE()) > 7 THEN 'ARCHIVE'
        ELSE 'KEEP'
    END AS Recommendation
FROM msdb.dbo.backupset bs
INNER JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
WHERE database_name = 'BookstoreDB'
ORDER BY backup_start_date DESC;

PRINT '';

/*
 * EXERCISES:
 * 
 * 1. Create a backup schedule: Full (Sunday), Differential (Daily), Log (Hourly)
 * 2. Calculate the restore time difference between:
 *    - Full + Latest Differential
 *    - Full + All Transaction Logs
 * 3. Script a cleanup job to delete backups older than 30 days
 * 4. Implement backup verification after each differential backup
 * 5. Create alerts for backup failures
 * 
 * CHALLENGE:
 * Design an automated backup system that:
 * - Performs full backups on Sunday
 * - Performs differential backups daily at midnight
 * - Performs log backups every 15 minutes
 * - Verifies all backups
 * - Sends email notifications on failure
 * - Maintains 30 days of backup history
 */

PRINT '✓ Lab 23 Complete: Differential backup strategy implemented';
PRINT '';
PRINT 'Key Takeaways:';
PRINT '  - Differential backups contain all changes since last FULL backup';
PRINT '  - Restore = FULL + Latest DIFFERENTIAL (simpler than many logs)';
PRINT '  - Good balance between speed and simplicity';
PRINT '  - Each new FULL backup resets the differential base';
GO
