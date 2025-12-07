/*
 * Lab 31: Index Maintenance and Optimization
 * Module 04: Database Administration
 * 
 * Objective: Master index maintenance strategies and optimization techniques
 * Duration: 2-3 hours
 * Difficulty: ⭐⭐⭐⭐
 */

USE master;
GO

PRINT '==============================================';
PRINT 'Lab 31: Index Maintenance and Optimization';
PRINT '==============================================';
PRINT '';

/*
 * INDEX MAINTENANCE OVERVIEW:
 * 
 * Fragmentation Types:
 * 1. Logical Fragmentation: Pages out of order
 * 2. Extent Fragmentation: Extents not contiguous
 * 
 * Maintenance Options:
 * 1. REORGANIZE: Online, defragments leaf level, compacts pages
 * 2. REBUILD: Offline (or online in Enterprise), recreates entire index
 * 
 * Guidelines:
 * - < 10% fragmentation: No action
 * - 10-30% fragmentation: REORGANIZE
 * - > 30% fragmentation: REBUILD
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
 * PART 1: ANALYZE INDEX FRAGMENTATION
 */

PRINT 'PART 1: Analyzing Index Fragmentation';
PRINT '--------------------------------------';

-- Comprehensive index fragmentation report
SELECT 
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    ips.index_id,
    ips.partition_number AS PartitionNum,
    ips.avg_fragmentation_in_percent AS AvgFragmentation,
    ips.fragment_count AS FragmentCount,
    ips.page_count AS PageCount,
    ips.avg_page_space_used_in_percent AS AvgPageDensity,
    ips.record_count AS RecordCount,
    CASE 
        WHEN ips.avg_fragmentation_in_percent < 10 THEN 'No Action'
        WHEN ips.avg_fragmentation_in_percent BETWEEN 10 AND 30 THEN 'REORGANIZE'
        WHEN ips.avg_fragmentation_in_percent > 30 AND ips.page_count > 1000 THEN 'REBUILD'
        WHEN ips.avg_fragmentation_in_percent > 30 THEN 'REBUILD (small, low priority)'
    END AS Recommendation,
    CASE 
        WHEN ips.page_count < 100 THEN 'Too small (ignore)'
        WHEN ips.avg_fragmentation_in_percent < 10 THEN 'Good'
        WHEN ips.avg_fragmentation_in_percent < 30 THEN 'Acceptable'
        ELSE 'Poor - Needs Maintenance'
    END AS Status
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'DETAILED') ips
INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.page_count > 100  -- Only indexes with significant size
    AND i.name IS NOT NULL  -- Exclude heaps
ORDER BY ips.avg_fragmentation_in_percent DESC, ips.page_count DESC;

PRINT '';

/*
 * PART 2: INDEX REORGANIZE
 */

PRINT 'PART 2: Index Reorganization';
PRINT '-----------------------------';

-- Reorganize specific index (always online)
PRINT 'Reorganizing Books primary key index...';
ALTER INDEX PK__Books__3214EC07 ON Books REORGANIZE;
PRINT '✓ Index reorganized';
PRINT '';

-- Reorganize all indexes on a table
PRINT 'Reorganizing all indexes on Orders table...';
ALTER INDEX ALL ON Orders REORGANIZE;
PRINT '✓ All indexes reorganized';
PRINT '';

-- Reorganize with LOB compaction
PRINT 'Reorganizing with LOB compaction...';
ALTER INDEX ALL ON Books REORGANIZE WITH (LOB_COMPACTION = ON);
PRINT '✓ Reorganized with LOB data compacted';
PRINT '';

PRINT 'REORGANIZE Characteristics:';
PRINT '  ✓ Always online operation';
PRINT '  ✓ Minimal system resources';
PRINT '  ✓ Can be stopped and resumed';
PRINT '  ✓ Compacts leaf level pages';
PRINT '  ✗ Does not recreate statistics';
PRINT '  Best for: 10-30% fragmentation';
PRINT '';

/*
 * PART 3: INDEX REBUILD
 */

PRINT 'PART 3: Index Rebuild';
PRINT '---------------------';

-- Offline rebuild (all editions)
PRINT 'Rebuilding Books indexes (offline)...';
ALTER INDEX ALL ON Books REBUILD;
PRINT '✓ Indexes rebuilt (offline)';
PRINT '';

-- Rebuild with options
PRINT 'Rebuilding with optimizations...';
ALTER INDEX ALL ON Orders REBUILD 
WITH (
    SORT_IN_TEMPDB = ON,      -- Use tempdb (better if tempdb on fast drive)
    MAXDOP = 4,                -- Parallel execution (4 CPUs)
    FILLFACTOR = 90,           -- Leave 10% free space for inserts
    STATISTICS_NORECOMPUTE = OFF,  -- Recompute statistics
    PAD_INDEX = ON             -- Apply fillfactor to intermediate levels
);
PRINT '✓ Indexes rebuilt with optimizations';
PRINT '';

-- Online rebuild (Enterprise Edition only)
/*
PRINT 'Rebuilding online (Enterprise Edition)...';
ALTER INDEX ALL ON Customers REBUILD 
WITH (
    ONLINE = ON,               -- Keep table accessible during rebuild
    MAXDOP = 4,
    SORT_IN_TEMPDB = ON
);
PRINT '✓ Online rebuild completed';
*/

PRINT 'REBUILD Characteristics:';
PRINT '  ✓ Complete index recreation';
PRINT '  ✓ Removes all fragmentation';
PRINT '  ✓ Updates statistics';
PRINT '  ✓ Can apply new fillfactor';
PRINT '  ✗ Offline by default (Enterprise has ONLINE option)';
PRINT '  ✗ More resource-intensive';
PRINT '  Best for: > 30% fragmentation';
PRINT '';

/*
 * PART 4: FILLFACTOR OPTIMIZATION
 */

PRINT 'PART 4: Fillfactor Optimization';
PRINT '--------------------------------';

-- View current fillfactors
SELECT 
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    i.fill_factor AS FillFactor,
    CASE 
        WHEN i.fill_factor = 0 THEN 100
        ELSE i.fill_factor
    END AS ActualFillFactor
FROM sys.indexes i
WHERE i.object_id IN (OBJECT_ID('Books'), OBJECT_ID('Orders'), OBJECT_ID('Customers'))
    AND i.name IS NOT NULL
ORDER BY TableName, IndexName;

PRINT '';

-- Rebuild with appropriate fillfactor
PRINT 'Rebuilding with fillfactor based on usage pattern...';

-- Heavy insert/update table: Lower fillfactor (more free space)
ALTER INDEX ALL ON Orders REBUILD WITH (FILLFACTOR = 80, PAD_INDEX = ON);
PRINT '✓ Orders indexes: FILLFACTOR = 80 (frequent inserts/updates)';

-- Read-mostly table: Higher fillfactor (less free space)
ALTER INDEX ALL ON Publishers REBUILD WITH (FILLFACTOR = 95, PAD_INDEX = ON);
PRINT '✓ Publishers indexes: FILLFACTOR = 95 (mostly read-only)';

PRINT '';
PRINT 'FILLFACTOR Guidelines:';
PRINT '  100 (or 0): Read-only data, no free space';
PRINT '  95-99:      Mostly reads, rare updates';
PRINT '  85-95:      Balanced read/write';
PRINT '  70-85:      Heavy updates/inserts';
PRINT '  < 70:       Very high churn (rare)';
PRINT '';

/*
 * PART 5: INDEX USAGE STATISTICS
 */

PRINT 'PART 5: Index Usage Statistics';
PRINT '--------------------------------';

-- Find unused indexes (consider dropping)
SELECT 
    OBJECT_NAME(s.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    s.user_seeks AS UserSeeks,
    s.user_scans AS UserScans,
    s.user_lookups AS UserLookups,
    s.user_updates AS UserUpdates,
    s.user_seeks + s.user_scans + s.user_lookups AS TotalReads,
    CASE 
        WHEN s.user_seeks + s.user_scans + s.user_lookups = 0 THEN 'UNUSED - Consider dropping'
        WHEN s.user_updates > (s.user_seeks + s.user_scans + s.user_lookups) * 10 THEN 'High update cost'
        ELSE 'In use'
    END AS Status
FROM sys.dm_db_index_usage_stats s
INNER JOIN sys.indexes i ON s.object_id = i.object_id AND s.index_id = i.index_id
WHERE s.database_id = DB_ID()
    AND OBJECTPROPERTY(s.object_id, 'IsUserTable') = 1
    AND i.type_desc != 'CLUSTERED'  -- Don't include clustered (table itself)
ORDER BY s.user_seeks + s.user_scans + s.user_lookups ASC;

PRINT '';

-- Find missing indexes (SQL Server recommendations)
SELECT 
    OBJECT_NAME(mid.object_id) AS TableName,
    mid.equality_columns AS EqualityColumns,
    mid.inequality_columns AS InequalityColumns,
    mid.included_columns AS IncludedColumns,
    migs.user_seeks AS UserSeeks,
    migs.user_scans AS UserScans,
    migs.avg_user_impact AS AvgImpact,
    migs.avg_total_user_cost AS AvgCost,
    'CREATE NONCLUSTERED INDEX IX_' + OBJECT_NAME(mid.object_id) + '_' +
        ISNULL(REPLACE(REPLACE(REPLACE(mid.equality_columns, ', ', '_'), '[', ''), ']', ''), 'Key') +
        ' ON ' + mid.statement +
        ' (' + ISNULL(mid.equality_columns, '') +
        CASE WHEN mid.inequality_columns IS NOT NULL THEN ',' + mid.inequality_columns ELSE '' END +
        ')' +
        CASE WHEN mid.included_columns IS NOT NULL THEN ' INCLUDE (' + mid.included_columns + ')' ELSE '' END
        AS CreateStatement
FROM sys.dm_db_missing_index_details mid
INNER JOIN sys.dm_db_missing_index_groups mig ON mid.index_handle = mig.index_handle
INNER JOIN sys.dm_db_missing_index_group_stats migs ON mig.index_group_handle = migs.group_handle
WHERE mid.database_id = DB_ID()
    AND migs.avg_user_impact > 50  -- Only show high-impact missing indexes
ORDER BY migs.avg_user_impact DESC;

PRINT '';

/*
 * PART 6: AUTOMATED INDEX MAINTENANCE
 */

PRINT 'PART 6: Automated Index Maintenance';
PRINT '-------------------------------------';

-- Create smart maintenance procedure
CREATE OR ALTER PROCEDURE dbo.sp_SmartIndexMaintenance
    @FragmentationThresholdReorg INT = 10,
    @FragmentationThresholdRebuild INT = 30,
    @MinPageCount INT = 100,
    @TimeLimit INT = 120,  -- Minutes
    @MaxDOP INT = 4
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartTime DATETIME = GETDATE();
    DECLARE @TableName NVARCHAR(128);
    DECLARE @IndexName NVARCHAR(128);
    DECLARE @Fragmentation FLOAT;
    DECLARE @PageCount INT;
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @Action NVARCHAR(20);
    
    -- Create temp table for results
    IF OBJECT_ID('tempdb..#IndexMaintenance') IS NOT NULL DROP TABLE #IndexMaintenance;
    
    CREATE TABLE #IndexMaintenance (
        TableName NVARCHAR(128),
        IndexName NVARCHAR(128),
        Fragmentation FLOAT,
        PageCount INT,
        Action NVARCHAR(20),
        StartTime DATETIME NULL,
        EndTime DATETIME NULL,
        Status NVARCHAR(50)
    );
    
    -- Get indexes needing maintenance
    INSERT INTO #IndexMaintenance (TableName, IndexName, Fragmentation, PageCount, Action, Status)
    SELECT 
        OBJECT_NAME(ips.object_id),
        i.name,
        ips.avg_fragmentation_in_percent,
        ips.page_count,
        CASE 
            WHEN ips.avg_fragmentation_in_percent >= @FragmentationThresholdRebuild THEN 'REBUILD'
            WHEN ips.avg_fragmentation_in_percent >= @FragmentationThresholdReorg THEN 'REORGANIZE'
        END,
        'Pending'
    FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
    INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
    WHERE ips.page_count >= @MinPageCount
        AND i.name IS NOT NULL
        AND ips.avg_fragmentation_in_percent >= @FragmentationThresholdReorg
    ORDER BY ips.avg_fragmentation_in_percent DESC, ips.page_count DESC;
    
    PRINT 'Found ' + CAST(@@ROWCOUNT AS VARCHAR) + ' indexes needing maintenance';
    PRINT 'Time limit: ' + CAST(@TimeLimit AS VARCHAR) + ' minutes';
    PRINT '';
    
    -- Process each index
    DECLARE index_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT TableName, IndexName, Fragmentation, PageCount, Action
    FROM #IndexMaintenance
    WHERE Status = 'Pending';
    
    OPEN index_cursor;
    FETCH NEXT FROM index_cursor INTO @TableName, @IndexName, @Fragmentation, @PageCount, @Action;
    
    WHILE @@FETCH_STATUS = 0 AND DATEDIFF(MINUTE, @StartTime, GETDATE()) < @TimeLimit
    BEGIN
        BEGIN TRY
            UPDATE #IndexMaintenance
            SET StartTime = GETDATE(), Status = 'In Progress'
            WHERE TableName = @TableName AND IndexName = @IndexName;
            
            PRINT CONVERT(VARCHAR, GETDATE(), 120) + ' - ' + @Action + ': ' + @TableName + '.' + @IndexName +
                  ' (' + CAST(CAST(@Fragmentation AS INT) AS VARCHAR) + '% fragmented, ' +
                  CAST(@PageCount AS VARCHAR) + ' pages)';
            
            IF @Action = 'REORGANIZE'
            BEGIN
                SET @SQL = 'ALTER INDEX [' + @IndexName + '] ON [' + @TableName + '] REORGANIZE';
            END
            ELSE -- REBUILD
            BEGIN
                SET @SQL = 'ALTER INDEX [' + @IndexName + '] ON [' + @TableName + '] REBUILD WITH (MAXDOP = ' +
                          CAST(@MaxDOP AS VARCHAR) + ', SORT_IN_TEMPDB = ON, FILLFACTOR = 90)';
            END;
            
            EXEC sp_executesql @SQL;
            
            UPDATE #IndexMaintenance
            SET EndTime = GETDATE(), Status = 'Completed'
            WHERE TableName = @TableName AND IndexName = @IndexName;
            
            PRINT '  ✓ Completed in ' + CAST(DATEDIFF(SECOND, 
                (SELECT StartTime FROM #IndexMaintenance WHERE TableName = @TableName AND IndexName = @IndexName),
                GETDATE()) AS VARCHAR) + ' seconds';
            PRINT '';
        END TRY
        BEGIN CATCH
            UPDATE #IndexMaintenance
            SET EndTime = GETDATE(), Status = 'FAILED: ' + ERROR_MESSAGE()
            WHERE TableName = @TableName AND IndexName = @IndexName;
            
            PRINT '  ✗ FAILED: ' + ERROR_MESSAGE();
            PRINT '';
        END CATCH;
        
        FETCH NEXT FROM index_cursor INTO @TableName, @IndexName, @Fragmentation, @PageCount, @Action;
    END;
    
    CLOSE index_cursor;
    DEALLOCATE index_cursor;
    
    -- Summary report
    PRINT '';
    PRINT '=== MAINTENANCE SUMMARY ===';
    PRINT 'Start Time: ' + CONVERT(VARCHAR, @StartTime, 120);
    PRINT 'End Time: ' + CONVERT(VARCHAR, GETDATE(), 120);
    PRINT 'Duration: ' + CAST(DATEDIFF(MINUTE, @StartTime, GETDATE()) AS VARCHAR) + ' minutes';
    PRINT '';
    
    SELECT 
        Action,
        COUNT(*) AS IndexCount,
        SUM(CASE WHEN Status = 'Completed' THEN 1 ELSE 0 END) AS Completed,
        SUM(CASE WHEN Status LIKE 'FAILED%' THEN 1 ELSE 0 END) AS Failed,
        AVG(DATEDIFF(SECOND, StartTime, EndTime)) AS AvgDurationSec
    FROM #IndexMaintenance
    GROUP BY Action
    ORDER BY Action;
    
    -- Detailed results
    PRINT '';
    PRINT 'Detailed Results:';
    SELECT * FROM #IndexMaintenance ORDER BY StartTime;
    
    DROP TABLE #IndexMaintenance;
END;
GO

PRINT '✓ Created sp_SmartIndexMaintenance procedure';
PRINT '';

-- Execute smart maintenance
EXEC dbo.sp_SmartIndexMaintenance 
    @FragmentationThresholdReorg = 10,
    @FragmentationThresholdRebuild = 30,
    @MinPageCount = 100,
    @TimeLimit = 30,
    @MaxDOP = 4;

PRINT '';

/*
 * PART 7: INDEX COMPRESSION
 */

PRINT 'PART 7: Index Compression';
PRINT '--------------------------';

-- Estimate compression savings
EXEC sp_estimate_data_compression_savings 
    @schema_name = 'dbo',
    @object_name = 'Books',
    @index_id = NULL,
    @partition_number = NULL,
    @data_compression = 'ROW';  -- or 'PAGE'

PRINT '';

-- Rebuild with compression (Enterprise Edition feature)
/*
ALTER INDEX ALL ON Books REBUILD WITH (DATA_COMPRESSION = PAGE);
PRINT '✓ Indexes rebuilt with PAGE compression';
*/

PRINT 'Compression Types:';
PRINT '  ROW:  Store fixed-length columns efficiently (5-15% savings)';
PRINT '  PAGE: Compress duplicate values across rows (15-60% savings)';
PRINT '  Note: Enterprise Edition feature only';
PRINT '';

/*
 * PART 8: MAINTENANCE BEST PRACTICES
 */

PRINT 'PART 8: Index Maintenance Best Practices';
PRINT '------------------------------------------';
PRINT '';
PRINT '1. SCHEDULE WISELY:';
PRINT '   - Run during maintenance windows';
PRINT '   - Monitor system load';
PRINT '   - Use time limits to prevent overruns';
PRINT '';
PRINT '2. PRIORITIZE:';
PRINT '   - High-fragmentation + high-usage indexes first';
PRINT '   - Skip small indexes (< 100 pages)';
PRINT '   - Skip rarely-used indexes';
PRINT '';
PRINT '3. CHOOSE APPROPRIATE METHOD:';
PRINT '   - REORGANIZE: 10-30%, always online, less resource-intensive';
PRINT '   - REBUILD: >30%, better results, more resources';
PRINT '   - Online rebuild if available (Enterprise)';
PRINT '';
PRINT '4. OPTIMIZE SETTINGS:';
PRINT '   - SORT_IN_TEMPDB = ON (if tempdb on fast storage)';
PRINT '   - MAXDOP: Limit parallelism to leave CPU for other queries';
PRINT '   - FILLFACTOR: Based on insert/update patterns';
PRINT '';
PRINT '5. UPDATE STATISTICS:';
PRINT '   - Rebuild automatically updates stats';
PRINT '   - Reorganize does NOT update stats';
PRINT '   - Run UPDATE STATISTICS after REORGANIZE';
PRINT '';

/*
 * EXERCISES:
 * 
 * 1. Create an index health dashboard showing fragmentation trends
 * 2. Implement adaptive maintenance (adjusts based on workload)
 * 3. Build alerting for sudden fragmentation increases
 * 4. Create cost-benefit analysis for index maintenance vs creation
 * 5. Implement index usage tracking and cleanup recommendations
 * 
 * CHALLENGE:
 * Design an intelligent index maintenance system:
 * - Machine learning to predict optimal maintenance schedules
 * - Workload-aware maintenance (pauses during peak hours)
 * - Automatic fillfactor optimization based on usage patterns
 * - Index consolidation recommendations
 * - Performance impact analysis (before/after metrics)
 */

PRINT '✓ Lab 31 Complete: Index maintenance mastered';
PRINT '';
PRINT 'Key Takeaways:';
PRINT '  - Regular maintenance prevents performance degradation';
PRINT '  - REORGANIZE for moderate fragmentation (online, fast)';
PRINT '  - REBUILD for severe fragmentation (offline, thorough)';
PRINT '  - Monitor index usage to identify unused indexes';
PRINT '  - Adjust fillfactor based on insert/update patterns';
GO
