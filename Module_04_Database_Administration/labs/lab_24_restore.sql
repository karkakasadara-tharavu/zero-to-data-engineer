/*
 * Lab 24: Database Restore Procedures
 * Module 04: Database Administration
 * 
 * Objective: Master database restoration techniques and recovery scenarios
 * Duration: 2-3 hours
 * Difficulty: ⭐⭐⭐⭐
 */

USE master;
GO

PRINT '==============================================';
PRINT 'Lab 24: Database Restore Procedures';
PRINT '==============================================';
PRINT '';

/*
 * RESTORE SCENARIOS:
 * 
 * 1. Complete database restore (full backup)
 * 2. Restore with differential backup
 * 3. Point-in-time restore (transaction logs)
 * 4. Restore to different database name
 * 5. Restore to different server
 * 6. Restore specific filegroups
 */

-- Ensure we have a backup to work with
IF DB_ID('BookstoreDB') IS NULL
BEGIN
    PRINT 'Error: BookstoreDB not found. Run Lab 20 first.';
    RETURN;
END;
GO

/*
 * PART 1: EXAMINE BACKUP FILE
 */

PRINT 'PART 1: Examining Backup Files';
PRINT '--------------------------------';

-- List backup file contents (logical file names)
DECLARE @BackupFile NVARCHAR(500) = 'C:\SQLBackups\BookstoreDB_Full_*.bak';

PRINT 'Backup file contents:';
RESTORE FILELISTONLY
FROM DISK = @BackupFile;

PRINT '';

-- View backup header information
PRINT 'Backup header information:';
RESTORE HEADERONLY
FROM DISK = @BackupFile;

PRINT '';

-- View backup metadata
PRINT 'Backup metadata:';
RESTORE LABELONLY
FROM DISK = @BackupFile;

PRINT '';

/*
 * PART 2: VERIFY BACKUP INTEGRITY
 */

PRINT 'PART 2: Verifying Backup Integrity';
PRINT '------------------------------------';

-- Verify backup can be restored (doesn't actually restore)
RESTORE VERIFYONLY
FROM DISK = @BackupFile
WITH CHECKSUM;

PRINT '✓ Backup verification successful';
PRINT '';

/*
 * PART 3: SIMPLE RESTORE (Full Database)
 */

PRINT 'PART 3: Simple Full Database Restore';
PRINT '--------------------------------------';

-- Restore to a new database name
/*
RESTORE DATABASE BookstoreDB_Test
FROM DISK = 'C:\SQLBackups\BookstoreDB_Full_*.bak'
WITH 
    MOVE 'BookstoreDB' TO 'C:\SQLData\BookstoreDB_Test.mdf',
    MOVE 'BookstoreDB_log' TO 'C:\SQLData\BookstoreDB_Test_log.ldf',
    REPLACE,  -- Overwrite existing database
    RECOVERY,  -- Bring database online
    STATS = 10;  -- Show progress every 10%

PRINT '✓ Database restored as BookstoreDB_Test';
*/

PRINT 'Restore command (commented - do not run on production):';
PRINT '  RESTORE DATABASE ... FROM DISK WITH MOVE, REPLACE, RECOVERY';
PRINT '';

/*
 * PART 4: RESTORE WITH DIFFERENTIAL
 */

PRINT 'PART 4: Restore with Differential Backup';
PRINT '-----------------------------------------';

/*
-- Step 1: Restore full backup with NORECOVERY
RESTORE DATABASE BookstoreDB_Restored
FROM DISK = 'C:\SQLBackups\BookstoreDB_Full_*.bak'
WITH 
    MOVE 'BookstoreDB' TO 'C:\SQLData\BookstoreDB_Restored.mdf',
    MOVE 'BookstoreDB_log' TO 'C:\SQLData\BookstoreDB_Restored_log.ldf',
    NORECOVERY,  -- Keep database in restoring state
    REPLACE,
    STATS = 10;

PRINT '✓ Full backup restored with NORECOVERY';

-- Step 2: Restore differential backup with RECOVERY
RESTORE DATABASE BookstoreDB_Restored
FROM DISK = 'C:\SQLBackups\BookstoreDB_Diff_*.bak'
WITH 
    RECOVERY,  -- Bring database online
    STATS = 10;

PRINT '✓ Differential backup restored with RECOVERY';
PRINT '✓ Database is now online';
*/

PRINT 'Two-step restore process:';
PRINT '  1. RESTORE FULL backup WITH NORECOVERY';
PRINT '  2. RESTORE DIFFERENTIAL backup WITH RECOVERY';
PRINT '';

/*
 * PART 5: POINT-IN-TIME RESTORE
 */

PRINT 'PART 5: Point-in-Time Restore';
PRINT '------------------------------';

-- First, create transaction log backups
USE BookstoreDB;
GO

-- Ensure FULL recovery model
ALTER DATABASE BookstoreDB SET RECOVERY FULL;
GO

-- Make some changes we'll want to recover
INSERT INTO Books (Title, ISBN, PublicationYear, Price, StockQuantity, PublisherID)
VALUES ('Time Machine Test 1', '978-0-00-000001-1', 2024, 9.99, 10, 1);

DECLARE @TimePoint DATETIME = GETDATE();
WAITFOR DELAY '00:00:02';

INSERT INTO Books (Title, ISBN, PublicationYear, Price, StockQuantity, PublisherID)
VALUES ('Time Machine Test 2', '978-0-00-000002-2', 2024, 9.99, 10, 1);

PRINT 'Point-in-time marker: ' + CONVERT(VARCHAR, @TimePoint, 120);
PRINT '';

-- Backup transaction log
BACKUP LOG BookstoreDB
TO DISK = 'C:\SQLBackups\BookstoreDB_Log.trn'
WITH NAME = 'BookstoreDB Log Backup',
     COMPRESSION,
     STATS = 10;

PRINT '✓ Transaction log backed up';
PRINT '';

-- Point-in-time restore (commented)
/*
USE master;
GO

-- Restore full backup
RESTORE DATABASE BookstoreDB_PITR
FROM DISK = 'C:\SQLBackups\BookstoreDB_Full_*.bak'
WITH 
    MOVE 'BookstoreDB' TO 'C:\SQLData\BookstoreDB_PITR.mdf',
    MOVE 'BookstoreDB_log' TO 'C:\SQLData\BookstoreDB_PITR_log.ldf',
    NORECOVERY,
    REPLACE;

-- Restore log to specific point in time
RESTORE LOG BookstoreDB_PITR
FROM DISK = 'C:\SQLBackups\BookstoreDB_Log.trn'
WITH 
    STOPAT = @TimePoint,  -- Restore to this exact moment
    RECOVERY;

-- Result: Database contains 'Time Machine Test 1' but NOT 'Test 2'
*/

PRINT 'Point-in-time restore uses STOPAT parameter:';
PRINT '  RESTORE LOG ... WITH STOPAT = ''2024-12-07 10:30:00'', RECOVERY';
PRINT '';

/*
 * PART 6: RESTORE WITH FILE RELOCATION
 */

PRINT 'PART 6: Restore to Different Location';
PRINT '---------------------------------------';

-- Query to get logical file names
SELECT 
    name AS LogicalFileName,
    physical_name AS CurrentPhysicalPath,
    type_desc AS FileType,
    size * 8.0 / 1024 AS SizeMB
FROM sys.master_files
WHERE database_id = DB_ID('BookstoreDB');

PRINT '';

/*
-- Restore with custom file locations
RESTORE DATABASE BookstoreDB_NewLocation
FROM DISK = 'C:\SQLBackups\BookstoreDB_Full_*.bak'
WITH 
    MOVE 'BookstoreDB' TO 'D:\NewSQLData\BookstoreDB.mdf',
    MOVE 'BookstoreDB_log' TO 'E:\NewSQLLogs\BookstoreDB_log.ldf',
    REPLACE,
    STATS = 10;
*/

PRINT 'Use MOVE clause to restore to different drives:';
PRINT '  MOVE ''LogicalName'' TO ''D:\NewPath\FileName.mdf''';
PRINT '';

/*
 * PART 7: RESTORE WITH STANDBY
 */

PRINT 'PART 7: Restore with STANDBY (Read-Only Access)';
PRINT '-------------------------------------------------';

/*
-- Restore in standby mode (allows read-only access between restores)
RESTORE DATABASE BookstoreDB_Standby
FROM DISK = 'C:\SQLBackups\BookstoreDB_Full_*.bak'
WITH 
    MOVE 'BookstoreDB' TO 'C:\SQLData\BookstoreDB_Standby.mdf',
    MOVE 'BookstoreDB_log' TO 'C:\SQLData\BookstoreDB_Standby_log.ldf',
    STANDBY = 'C:\SQLData\BookstoreDB_Standby_Undo.ldf',  -- Undo file
    REPLACE;

-- Database is now READ-ONLY but accessible
-- You can query it, then apply more log backups

-- Apply additional log backup
RESTORE LOG BookstoreDB_Standby
FROM DISK = 'C:\SQLBackups\BookstoreDB_Log.trn'
WITH 
    STANDBY = 'C:\SQLData\BookstoreDB_Standby_Undo.ldf';

-- Bring online permanently
RESTORE DATABASE BookstoreDB_Standby WITH RECOVERY;
*/

PRINT 'STANDBY mode allows read-only access during multi-step restore:';
PRINT '  RESTORE DATABASE ... WITH STANDBY = ''UndoFile.ldf''';
PRINT '  (Database is read-only, can query data)';
PRINT '  RESTORE LOG ... WITH STANDBY = ''UndoFile.ldf''';
PRINT '  RESTORE DATABASE ... WITH RECOVERY (final step)';
PRINT '';

/*
 * PART 8: PARTIAL RESTORE (Enterprise Edition)
 */

PRINT 'PART 8: Partial/Piecemeal Restore';
PRINT '-----------------------------------';

-- Partial restore restores PRIMARY filegroup first, then additional filegroups
-- Useful for very large databases to get critical data online quickly

/*
-- Step 1: Restore primary filegroup
RESTORE DATABASE BookstoreDB_Partial
FILEGROUP = 'PRIMARY'
FROM DISK = 'C:\SQLBackups\BookstoreDB_Full_*.bak'
WITH 
    PARTIAL,  -- Indicates partial restore
    NORECOVERY,
    MOVE 'BookstoreDB' TO 'C:\SQLData\BookstoreDB_Partial.mdf',
    MOVE 'BookstoreDB_log' TO 'C:\SQLData\BookstoreDB_Partial_log.ldf';

-- Bring primary filegroup online
RESTORE DATABASE BookstoreDB_Partial WITH RECOVERY;

-- Database is now partially online (PRIMARY filegroup accessible)

-- Step 2: Restore additional filegroups later
RESTORE DATABASE BookstoreDB_Partial
FILEGROUP = 'SecondaryFG'
FROM DISK = 'C:\SQLBackups\BookstoreDB_Full_*.bak'
WITH RECOVERY;
*/

PRINT 'Partial restore (for very large databases):';
PRINT '  1. RESTORE PRIMARY filegroup WITH PARTIAL, NORECOVERY';
PRINT '  2. RESTORE WITH RECOVERY (PRIMARY now online)';
PRINT '  3. RESTORE additional filegroups as needed';
PRINT '';

/*
 * PART 9: RESTORE FROM MULTIPLE FILES (Striped Backup)
 */

PRINT 'PART 9: Restore from Striped Backup';
PRINT '-------------------------------------';

/*
-- If backup was striped across multiple files
RESTORE DATABASE BookstoreDB_Striped
FROM 
    DISK = 'C:\SQLBackups\BookstoreDB_Stripe1.bak',
    DISK = 'C:\SQLBackups\BookstoreDB_Stripe2.bak',
    DISK = 'C:\SQLBackups\BookstoreDB_Stripe3.bak'
WITH 
    MOVE 'BookstoreDB' TO 'C:\SQLData\BookstoreDB_Striped.mdf',
    MOVE 'BookstoreDB_log' TO 'C:\SQLData\BookstoreDB_Striped_log.ldf',
    REPLACE,
    STATS = 10;
*/

PRINT 'Restore striped backup (all files required):';
PRINT '  RESTORE DATABASE ... FROM DISK = ''File1.bak'',';
PRINT '                                    DISK = ''File2.bak'',';
PRINT '                                    DISK = ''File3.bak''';
PRINT '';

/*
 * PART 10: AUTOMATED RESTORE VERIFICATION
 */

PRINT 'PART 10: Automated Restore Testing';
PRINT '------------------------------------';

-- Script to test restore on a schedule
/*
CREATE PROCEDURE dbo.VerifyBackupRestorability
    @BackupFilePath NVARCHAR(500),
    @TestDatabaseName NVARCHAR(128) = 'RESTORE_TEST'
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Verify backup file integrity
        RESTORE VERIFYONLY FROM DISK = @BackupFilePath WITH CHECKSUM;
        PRINT '✓ Backup file integrity verified';
        
        -- Drop test database if exists
        IF DB_ID(@TestDatabaseName) IS NOT NULL
        BEGIN
            EXEC('ALTER DATABASE [' + @TestDatabaseName + '] SET SINGLE_USER WITH ROLLBACK IMMEDIATE');
            EXEC('DROP DATABASE [' + @TestDatabaseName + ']');
        END;
        
        -- Perform test restore
        RESTORE DATABASE @TestDatabaseName
        FROM DISK = @BackupFilePath
        WITH 
            MOVE 'BookstoreDB' TO 'C:\SQLData\' + @TestDatabaseName + '.mdf',
            MOVE 'BookstoreDB_log' TO 'C:\SQLData\' + @TestDatabaseName + '_log.ldf',
            REPLACE,
            RECOVERY;
        
        PRINT '✓ Test restore successful';
        
        -- Run DBCC CHECKDB
        EXEC('DBCC CHECKDB([' + @TestDatabaseName + ']) WITH NO_INFOMSGS');
        PRINT '✓ Database integrity check passed';
        
        -- Cleanup
        EXEC('DROP DATABASE [' + @TestDatabaseName + ']');
        PRINT '✓ Test database cleaned up';
        
        RETURN 0;  -- Success
    END TRY
    BEGIN CATCH
        PRINT 'ERROR: ' + ERROR_MESSAGE();
        RETURN 1;  -- Failure
    END CATCH;
END;
GO
*/

PRINT 'Best practice: Regularly test restore procedures';
PRINT '  - Automate restore verification';
PRINT '  - Test on separate server';
PRINT '  - Verify data integrity with DBCC CHECKDB';
PRINT '  - Document restore time (RTO)';
PRINT '';

/*
 * PART 11: COMMON RESTORE ERRORS
 */

PRINT 'PART 11: Common Restore Errors and Solutions';
PRINT '----------------------------------------------';
PRINT '';
PRINT 'Error: "Database is in use"';
PRINT '  Solution: Use WITH REPLACE or set to SINGLE_USER mode';
PRINT '';
PRINT 'Error: "Backup set not found"';
PRINT '  Solution: Use RESTORE HEADERONLY to list backup sets';
PRINT '           Use FILE = N option to specify backup set number';
PRINT '';
PRINT 'Error: "Cannot restore log - database not in NORECOVERY"';
PRINT '  Solution: Full backup must be restored WITH NORECOVERY first';
PRINT '';
PRINT 'Error: "Insufficient disk space"';
PRINT '  Solution: Check space with RESTORE FILELISTONLY';
PRINT '           Free up disk space or restore to different location';
PRINT '';

/*
 * EXERCISES:
 * 
 * 1. Create a restore procedure that accepts backup file path and target DB name
 * 2. Write a script to restore to yesterday at 3:00 PM (point-in-time)
 * 3. Implement automated nightly restore testing
 * 4. Calculate and document your RTO (Recovery Time Objective)
 * 5. Create a disaster recovery runbook with step-by-step restore procedures
 * 
 * CHALLENGE:
 * Build a complete disaster recovery solution:
 * - Automated backup verification
 * - Off-site backup copies
 * - Automated restore testing (non-production)
 * - Monitoring and alerting
 * - Documented recovery procedures
 * - RTO and RPO tracking
 */

PRINT '✓ Lab 24 Complete: Database restore procedures mastered';
PRINT '';
PRINT 'Key Restore Options:';
PRINT '  - RECOVERY: Brings database online (default)';
PRINT '  - NORECOVERY: Keeps database restoring (for log restores)';
PRINT '  - STANDBY: Read-only access between restores';
PRINT '  - REPLACE: Overwrites existing database';
PRINT '  - STOPAT: Point-in-time recovery';
PRINT '  - MOVE: Relocate database files';
GO
