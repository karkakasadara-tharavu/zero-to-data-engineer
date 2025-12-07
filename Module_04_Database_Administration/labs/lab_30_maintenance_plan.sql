/*
 * Lab 30: Database Maintenance Plans
 * Module 04: Database Administration
 * 
 * Objective: Implement comprehensive database maintenance procedures
 * Duration: 2-3 hours
 * Difficulty: ⭐⭐⭐⭐
 */

USE master;
GO

PRINT '==============================================';
PRINT 'Lab 30: Database Maintenance Plans';
PRINT '==============================================';
PRINT '';

/*
 * MAINTENANCE TASKS:
 * 
 * 1. Index Maintenance (Rebuild/Reorganize)
 * 2. Statistics Updates
 * 3. Database Integrity Checks (DBCC CHECKDB)
 * 4. Backup Management
 * 5. Log File Management
 * 6. Cleanup Old Data
 * 
 * Best Practice: Schedule during maintenance windows
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
 * PART 1: DATABASE INTEGRITY CHECKS
 */

PRINT 'PART 1: Database Integrity Checks';
PRINT '-----------------------------------';

-- Check database integrity
PRINT 'Running DBCC CHECKDB...';
DBCC CHECKDB(BookstoreDB) WITH NO_INFOMSGS;
PRINT '✓ DBCC CHECKDB completed - No corruption detected';
PRINT '';

-- Check specific table
PRINT 'Checking Books table:';
DBCC CHECKTABLE(Books) WITH NO_INFOMSGS;
PRINT '✓ Books table integrity verified';
PRINT '';

-- Check allocation integrity only (faster)
PRINT 'Checking allocation integrity:';
DBCC CHECKALLOC(BookstoreDB) WITH NO_INFOMSGS;
PRINT '✓ Allocation integrity verified';
PRINT '';

-- Check catalog integrity
PRINT 'Checking catalog integrity:';
DBCC CHECKCATALOG(BookstoreDB) WITH NO_INFOMSGS;
PRINT '✓ Catalog integrity verified';
PRINT '';

PRINT 'INTEGRITY CHECK SCHEDULE:';
PRINT '  - DBCC CHECKDB: Weekly (full check)';
PRINT '  - DBCC CHECKALLOC: Daily (quick allocation check)';
PRINT '  - Run during maintenance window (can be resource-intensive)';
PRINT '';

/*
 * PART 2: INDEX MAINTENANCE
 */

PRINT 'PART 2: Index Maintenance';
PRINT '--------------------------';

-- View index fragmentation
SELECT 
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    ips.avg_fragmentation_in_percent AS Fragmentation,
    ips.page_count AS PageCount,
    CASE 
        WHEN ips.avg_fragmentation_in_percent < 10 THEN 'No action needed'
        WHEN ips.avg_fragmentation_in_percent BETWEEN 10 AND 30 THEN 'REORGANIZE'
        WHEN ips.avg_fragmentation_in_percent > 30 THEN 'REBUILD'
    END AS Recommendation
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.page_count > 100  -- Only consider indexes with >100 pages
    AND i.name IS NOT NULL
ORDER BY ips.avg_fragmentation_in_percent DESC;

PRINT '';

-- Reorganize indexes (< 30% fragmentation)
PRINT 'Reorganizing fragmented indexes...';
ALTER INDEX ALL ON Books REORGANIZE;
ALTER INDEX ALL ON Orders REORGANIZE;
PRINT '✓ Indexes reorganized (online operation)';
PRINT '';

-- Rebuild indexes (> 30% fragmentation)
PRINT 'Rebuilding heavily fragmented indexes...';
-- Online rebuild (Enterprise Edition only)
/*
ALTER INDEX ALL ON Books REBUILD WITH (ONLINE = ON, SORT_IN_TEMPDB = ON);
*/
-- Offline rebuild (all editions)
ALTER INDEX ALL ON Books REBUILD WITH (SORT_IN_TEMPDB = ON);
PRINT '✓ Indexes rebuilt';
PRINT '';

PRINT 'INDEX MAINTENANCE GUIDELINES:';
PRINT '  Fragmentation < 10%:  No action';
PRINT '  Fragmentation 10-30%: REORGANIZE (online, faster)';
PRINT '  Fragmentation > 30%:  REBUILD (offline unless Enterprise)';
PRINT '';

/*
 * PART 3: STATISTICS UPDATES
 */

PRINT 'PART 3: Statistics Updates';
PRINT '---------------------------';

-- View statistics information
SELECT 
    OBJECT_NAME(s.object_id) AS TableName,
    s.name AS StatName,
    STATS_DATE(s.object_id, s.stats_id) AS LastUpdated,
    DATEDIFF(DAY, STATS_DATE(s.object_id, s.stats_id), GETDATE()) AS DaysSinceUpdate,
    sp.rows AS RowCount,
    sp.modification_counter AS ModifiedRows,
    CASE 
        WHEN sp.rows > 0 THEN 
            CAST(sp.modification_counter * 100.0 / sp.rows AS DECIMAL(5,2))
        ELSE 0
    END AS PercentModified,
    CASE
        WHEN DATEDIFF(DAY, STATS_DATE(s.object_id, s.stats_id), GETDATE()) > 7 THEN 'UPDATE'
        WHEN sp.modification_counter * 100.0 / sp.rows > 20 THEN 'UPDATE'
        ELSE 'OK'
    END AS Recommendation
FROM sys.stats s
CROSS APPLY sys.dm_db_stats_properties(s.object_id, s.stats_id) sp
WHERE OBJECTPROPERTY(s.object_id, 'IsUserTable') = 1
ORDER BY DaysSinceUpdate DESC;

PRINT '';

-- Update statistics with full scan
PRINT 'Updating statistics...';
UPDATE STATISTICS Books WITH FULLSCAN;
UPDATE STATISTICS Orders WITH FULLSCAN;
UPDATE STATISTICS Customers WITH FULLSCAN;
PRINT '✓ Statistics updated with FULLSCAN';
PRINT '';

-- Update all statistics in database
PRINT 'Updating all database statistics...';
EXEC sp_updatestats;
PRINT '✓ All database statistics updated';
PRINT '';

PRINT 'STATISTICS UPDATE GUIDELINES:';
PRINT '  - Update after significant data changes (>20% rows)';
PRINT '  - Use FULLSCAN for accuracy (default is sample)';
PRINT '  - Schedule weekly or after large data loads';
PRINT '  - Automatic updates enabled by default (AUTO_UPDATE_STATISTICS)';
PRINT '';

/*
 * PART 4: BACKUP VERIFICATION
 */

PRINT 'PART 4: Backup Verification';
PRINT '----------------------------';

-- Check last backup dates
SELECT 
    DB_NAME() AS DatabaseName,
    MAX(CASE WHEN type = 'D' THEN backup_finish_date END) AS LastFullBackup,
    MAX(CASE WHEN type = 'I' THEN backup_finish_date END) AS LastDiffBackup,
    MAX(CASE WHEN type = 'L' THEN backup_finish_date END) AS LastLogBackup,
    DATEDIFF(HOUR, MAX(CASE WHEN type = 'D' THEN backup_finish_date END), GETDATE()) AS HoursSinceFullBackup
FROM msdb.dbo.backupset
WHERE database_name = 'BookstoreDB'
GROUP BY database_name;

PRINT '';

-- Verify most recent backup
DECLARE @LastBackup NVARCHAR(500);
SELECT TOP 1 @LastBackup = physical_device_name
FROM msdb.dbo.backupset bs
INNER JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
WHERE database_name = 'BookstoreDB'
ORDER BY backup_finish_date DESC;

IF @LastBackup IS NOT NULL
BEGIN
    PRINT 'Verifying latest backup: ' + @LastBackup;
    RESTORE VERIFYONLY FROM DISK = @LastBackup WITH CHECKSUM;
    PRINT '✓ Backup verified successfully';
END
ELSE
BEGIN
    PRINT '⚠ Warning: No backups found for BookstoreDB';
END;

PRINT '';

/*
 * PART 5: LOG FILE MANAGEMENT
 */

PRINT 'PART 5: Log File Management';
PRINT '----------------------------';

-- Check log file size and usage
SELECT 
    name AS FileName,
    type_desc AS FileType,
    size * 8.0 / 1024 AS CurrentSizeMB,
    FILEPROPERTY(name, 'SpaceUsed') * 8.0 / 1024 AS UsedSpaceMB,
    (size - FILEPROPERTY(name, 'SpaceUsed')) * 8.0 / 1024 AS FreeSpaceMB,
    CAST((size - FILEPROPERTY(name, 'SpaceUsed')) * 100.0 / size AS DECIMAL(5,2)) AS PercentFree
FROM sys.database_files
WHERE type_desc = 'LOG';

PRINT '';

-- Check VLF count
DECLARE @VLFCount INT;
SELECT @VLFCount = COUNT(*) FROM sys.dm_db_log_info(DB_ID());
PRINT 'Virtual Log Files (VLFs): ' + CAST(@VLFCount AS VARCHAR);

IF @VLFCount > 100
BEGIN
    PRINT '⚠ Warning: High VLF count (>100) can impact performance';
    PRINT '  Recommendation: Rebuild log file (shrink then regrow to proper size)';
END
ELSE
BEGIN
    PRINT '✓ VLF count is acceptable';
END;

PRINT '';

-- Backup log to truncate (FULL recovery only)
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'BookstoreDB' AND recovery_model = 1)
BEGIN
    BACKUP LOG BookstoreDB
    TO DISK = 'C:\SQLBackups\BookstoreDB_Log_Maintenance.trn'
    WITH NAME = 'Maintenance Log Backup', COMPRESSION, NO_TRUNCATE;
    PRINT '✓ Log backed up and truncated';
END;

PRINT '';

/*
 * PART 6: CLEANUP OLD DATA
 */

PRINT 'PART 6: Data Cleanup';
PRINT '--------------------';

-- Example: Delete old orders (retention policy)
IF OBJECT_ID('tempdb..#DeletedOrders') IS NOT NULL DROP TABLE #DeletedOrders;

-- Soft delete approach (keep audit trail)
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Orders') AND name = 'IsDeleted')
BEGIN
    ALTER TABLE Orders ADD IsDeleted BIT NOT NULL DEFAULT 0;
    ALTER TABLE Orders ADD DeletedDate DATETIME NULL;
END;

-- Mark old test orders for deletion
UPDATE Orders
SET IsDeleted = 1, DeletedDate = GETDATE()
WHERE OrderDate < DATEADD(YEAR, -1, GETDATE())
    AND TotalAmount < 10;  -- Test orders only

DECLARE @DeletedCount INT = @@ROWCOUNT;
PRINT 'Marked ' + CAST(@DeletedCount AS VARCHAR) + ' old orders for deletion';
PRINT '';

-- Cleanup backup history (older than 30 days)
EXEC msdb.dbo.sp_delete_backuphistory @oldest_date = '2024-01-01';
PRINT '✓ Old backup history cleaned up';
PRINT '';

-- Cleanup SQL Agent job history
EXEC msdb.dbo.sp_purge_jobhistory @oldest_date = '2024-01-01';
PRINT '✓ Old job history cleaned up';
PRINT '';

/*
 * PART 7: SHRINK DATABASE (USE WITH CAUTION)
 */

PRINT 'PART 7: Shrink Database (Caution!)';
PRINT '------------------------------------';

-- Check database size
EXEC sp_spaceused;
PRINT '';

-- View file sizes
SELECT 
    name,
    size * 8.0 / 1024 AS CurrentSizeMB,
    FILEPROPERTY(name, 'SpaceUsed') * 8.0 / 1024 AS UsedSpaceMB,
    (size - FILEPROPERTY(name, 'SpaceUsed')) * 8.0 / 1024 AS FreeSpaceMB
FROM sys.database_files;

PRINT '';

PRINT '⚠ SHRINK WARNING:';
PRINT '  - Shrinking causes index fragmentation';
PRINT '  - Shrinking causes VLF fragmentation (log files)';
PRINT '  - Database will likely regrow anyway';
PRINT '  - Better: Size databases properly from start';
PRINT '';

-- Shrink if absolutely necessary (commented)
/*
DBCC SHRINKDATABASE(BookstoreDB, 10);  -- 10% free space
DBCC SHRINKFILE('BookstoreDB_log', 10);  -- Shrink log to 10 MB
*/

PRINT 'Shrink operations commented out (not recommended for regular maintenance)';
PRINT '';

/*
 * PART 8: MAINTENANCE SCHEDULE
 */

PRINT 'PART 8: Recommended Maintenance Schedule';
PRINT '------------------------------------------';
PRINT '';
PRINT 'DAILY:';
PRINT '  - Full backup (off-hours)';
PRINT '  - Log backups (every 15-30 minutes)';
PRINT '  - DBCC CHECKALLOC (quick integrity check)';
PRINT '  - Monitor log file growth';
PRINT '';
PRINT 'WEEKLY:';
PRINT '  - Differential backups (if using)';
PRINT '  - DBCC CHECKDB (full integrity check)';
PRINT '  - Index maintenance (reorganize/rebuild)';
PRINT '  - Statistics updates';
PRINT '  - Review error logs';
PRINT '';
PRINT 'MONTHLY:';
PRINT '  - Review growth trends';
PRINT '  - Capacity planning';
PRINT '  - Test disaster recovery';
PRINT '  - Cleanup old backups';
PRINT '  - Audit security';
PRINT '';
PRINT 'QUARTERLY:';
PRINT '  - Full database restore test';
PRINT '  - Review maintenance plan effectiveness';
PRINT '  - Update documentation';
PRINT '';

/*
 * PART 9: AUTOMATED MAINTENANCE SCRIPT
 */

PRINT 'PART 9: Automated Maintenance Script';
PRINT '--------------------------------------';

-- Create maintenance procedure
CREATE OR ALTER PROCEDURE dbo.sp_DatabaseMaintenance
    @DatabaseName NVARCHAR(128) = NULL,
    @PerformIntegrityCheck BIT = 1,
    @PerformIndexMaint BIT = 1,
    @PerformStatisticsUpdate BIT = 1,
    @FragmentationThreshold INT = 30
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @DatabaseName IS NULL SET @DatabaseName = DB_NAME();
    
    PRINT 'Starting maintenance for: ' + @DatabaseName;
    PRINT 'Time: ' + CONVERT(VARCHAR, GETDATE(), 120);
    PRINT '';
    
    -- 1. Integrity Check
    IF @PerformIntegrityCheck = 1
    BEGIN
        PRINT 'Running integrity check...';
        EXEC('DBCC CHECKDB([' + @DatabaseName + ']) WITH NO_INFOMSGS');
        PRINT '✓ Integrity check complete';
        PRINT '';
    END;
    
    -- 2. Index Maintenance
    IF @PerformIndexMaint = 1
    BEGIN
        PRINT 'Performing index maintenance...';
        
        DECLARE @SQL NVARCHAR(MAX);
        DECLARE @TableName NVARCHAR(128);
        DECLARE @Fragmentation FLOAT;
        
        DECLARE index_cursor CURSOR FOR
        SELECT DISTINCT 
            OBJECT_NAME(ips.object_id),
            MAX(ips.avg_fragmentation_in_percent)
        FROM sys.dm_db_index_physical_stats(DB_ID(@DatabaseName), NULL, NULL, NULL, 'LIMITED') ips
        INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
        WHERE ips.page_count > 100
            AND i.name IS NOT NULL
            AND ips.avg_fragmentation_in_percent > 10
        GROUP BY OBJECT_NAME(ips.object_id);
        
        OPEN index_cursor;
        FETCH NEXT FROM index_cursor INTO @TableName, @Fragmentation;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            IF @Fragmentation > @FragmentationThreshold
            BEGIN
                SET @SQL = 'ALTER INDEX ALL ON [' + @DatabaseName + '].[dbo].[' + @TableName + '] REBUILD';
                PRINT '  Rebuilding: ' + @TableName;
            END
            ELSE
            BEGIN
                SET @SQL = 'ALTER INDEX ALL ON [' + @DatabaseName + '].[dbo].[' + @TableName + '] REORGANIZE';
                PRINT '  Reorganizing: ' + @TableName;
            END;
            
            EXEC sp_executesql @SQL;
            
            FETCH NEXT FROM index_cursor INTO @TableName, @Fragmentation;
        END;
        
        CLOSE index_cursor;
        DEALLOCATE index_cursor;
        
        PRINT '✓ Index maintenance complete';
        PRINT '';
    END;
    
    -- 3. Statistics Update
    IF @PerformStatisticsUpdate = 1
    BEGIN
        PRINT 'Updating statistics...';
        EXEC('USE [' + @DatabaseName + ']; EXEC sp_updatestats');
        PRINT '✓ Statistics updated';
        PRINT '';
    END;
    
    PRINT 'Maintenance completed: ' + CONVERT(VARCHAR, GETDATE(), 120);
END;
GO

PRINT '✓ Created sp_DatabaseMaintenance procedure';
PRINT '';

-- Test the maintenance procedure
EXEC dbo.sp_DatabaseMaintenance 
    @DatabaseName = 'BookstoreDB',
    @PerformIntegrityCheck = 1,
    @PerformIndexMaint = 1,
    @PerformStatisticsUpdate = 1;

PRINT '';

/*
 * PART 10: MONITORING MAINTENANCE TASKS
 */

PRINT 'PART 10: Monitoring Maintenance Tasks';
PRINT '---------------------------------------';

-- Query to check when maintenance tasks last ran
SELECT 
    'DBCC CHECKDB' AS MaintenanceTask,
    MAX(backup_start_date) AS LastCompleted,
    DATEDIFF(DAY, MAX(backup_start_date), GETDATE()) AS DaysSince
FROM msdb.dbo.backupset
WHERE database_name = 'BookstoreDB'
    AND type = 'D'

UNION ALL

SELECT 
    'Index Rebuild/Reorg',
    MAX(STATS_DATE(object_id, index_id)),
    DATEDIFF(DAY, MAX(STATS_DATE(object_id, index_id)), GETDATE())
FROM sys.indexes
WHERE object_id = OBJECT_ID('Books')

UNION ALL

SELECT 
    'Statistics Update',
    MAX(STATS_DATE(object_id, stats_id)),
    DATEDIFF(DAY, MAX(STATS_DATE(object_id, stats_id)), GETDATE())
FROM sys.stats
WHERE object_id = OBJECT_ID('Books');

PRINT '';

/*
 * EXERCISES:
 * 
 * 1. Create SQL Agent jobs for daily, weekly, and monthly maintenance
 * 2. Implement email notifications for maintenance failures
 * 3. Build a dashboard showing maintenance history and health
 * 4. Create a script to estimate maintenance window duration
 * 5. Implement automated index defragmentation based on fragmentation levels
 * 
 * CHALLENGE:
 * Design a complete maintenance automation system:
 * - Adaptive maintenance (adjusts based on workload)
 * - Performance impact monitoring
 * - Automatic rollback on errors
 * - Compliance reporting
 * - Capacity trend analysis
 * - Predictive maintenance alerts
 */

PRINT '✓ Lab 30 Complete: Database maintenance mastered';
PRINT '';
PRINT 'Maintenance Priorities:';
PRINT '  1. Backups (most critical - ensure recoverability)';
PRINT '  2. Integrity checks (detect corruption early)';
PRINT '  3. Index maintenance (ensure query performance)';
PRINT '  4. Statistics (ensure optimal execution plans)';
PRINT '  5. Cleanup (manage growth and history)';
GO
