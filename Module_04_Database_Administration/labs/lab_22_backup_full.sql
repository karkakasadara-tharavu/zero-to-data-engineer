/*
 * Lab 22: Full Database Backup
 * Module 04: Database Administration
 * 
 * Objective: Learn to create full database backups
 * Duration: 1-2 hours
 * Difficulty: ⭐⭐⭐
 */

USE master;
GO

-- Ensure backup directory exists
EXEC xp_cmdshell 'mkdir C:\SQLBackups', NO_OUTPUT;
GO

PRINT '==============================================';
PRINT 'Lab 22: Full Database Backup';
PRINT '==============================================';
PRINT '';

-- Use the BookstoreDB from Lab 20 (or create sample DB)
IF DB_ID('BookstoreDB') IS NULL
BEGIN
    PRINT 'Creating sample BookstoreDB...';
    CREATE DATABASE BookstoreDB;
END;
GO

USE BookstoreDB;
GO

/*
 * FULL BACKUP
 * 
 * A full backup captures the entire database including:
 * - All data files
 * - Enough transaction log to provide consistency
 * - System metadata
 */

-- Check current database size
EXEC sp_spaceused;
GO

-- Perform full backup
DECLARE @BackupPath NVARCHAR(500);
DECLARE @BackupName NVARCHAR(200);
DECLARE @CurrentDate NVARCHAR(20);

SET @CurrentDate = CONVERT(NVARCHAR, GETDATE(), 112) + '_' + REPLACE(CONVERT(NVARCHAR, GETDATE(), 108), ':', '');
SET @BackupPath = 'C:\SQLBackups\BookstoreDB_Full_' + @CurrentDate + '.bak';
SET @BackupName = 'BookstoreDB Full Backup - ' + CONVERT(NVARCHAR, GETDATE(), 120);

PRINT 'Creating full backup...';
PRINT 'Backup file: ' + @BackupPath;

BACKUP DATABASE BookstoreDB
TO DISK = @BackupPath
WITH 
    FORMAT,                    -- Overwrite existing media
    NAME = @BackupName,
    DESCRIPTION = 'Full backup of BookstoreDB',
    COMPRESSION,               -- Compress backup (saves space)
    STATS = 10,                -- Show progress every 10%
    CHECKSUM;                  -- Verify backup integrity
GO

-- Verify the backup
PRINT '';
PRINT 'Verifying backup integrity...';
RESTORE VERIFYONLY 
FROM DISK = 'C:\SQLBackups\BookstoreDB_Full_*.bak';
GO

-- View backup history
PRINT '';
PRINT 'Recent backup history:';
SELECT 
    database_name,
    backup_start_date,
    backup_finish_date,
    DATEDIFF(SECOND, backup_start_date, backup_finish_date) AS DurationSeconds,
    backup_size / 1024 / 1024 AS BackupSizeMB,
    compressed_backup_size / 1024 / 1024 AS CompressedSizeMB,
    type AS BackupType, -- D=Full, I=Differential, L=Log
    physical_device_name
FROM msdb.dbo.backupset bs
JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
WHERE database_name = 'BookstoreDB'
ORDER BY backup_start_date DESC;
GO

/*
 * BACKUP OPTIONS
 */

-- Backup with multiple files (striped backup for better performance)
BACKUP DATABASE BookstoreDB
TO DISK = 'C:\SQLBackups\BookstoreDB_Stripe1.bak',
   DISK = 'C:\SQLBackups\BookstoreDB_Stripe2.bak',
   DISK = 'C:\SQLBackups\BookstoreDB_Stripe3.bak'
WITH 
    FORMAT,
    NAME = 'Striped Full Backup',
    COMPRESSION;
GO

-- Backup to URL (Azure Blob Storage example - commented out)
/*
CREATE CREDENTIAL [MyAzureCredential]
WITH IDENTITY = 'mystorageaccount',
SECRET = '<storage account access key>';

BACKUP DATABASE BookstoreDB
TO URL = 'https://mystorageaccount.blob.core.windows.net/backups/BookstoreDB.bak'
WITH CREDENTIAL = 'MyAzureCredential',
     COMPRESSION;
*/

-- Copy-only backup (doesn't affect backup chain)
BACKUP DATABASE BookstoreDB
TO DISK = 'C:\SQLBackups\BookstoreDB_CopyOnly.bak'
WITH 
    COPY_ONLY,
    FORMAT,
    NAME = 'Copy-Only Full Backup',
    COMPRESSION;
GO

/*
 * EXERCISES:
 * 
 * 1. Create a script that backs up all user databases
 * 2. Implement backup file retention (delete backups older than 7 days)
 * 3. Calculate compression ratio for your backups
 * 4. Set up backup verification job
 * 5. Create backup documentation with restore steps
 */

PRINT '';
PRINT '✓ Lab 22 Complete: Full database backup created successfully';
PRINT 'Backup location: C:\SQLBackups\';
GO
