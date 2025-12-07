/*
 * Lab 51: Advanced Dynamic SQL Patterns
 * Module 05: T-SQL Programming
 * 
 * Objective: Master advanced dynamic SQL techniques
 * Duration: 75 minutes
 * Difficulty: ⭐⭐⭐⭐⭐
 */

USE BookstoreDB;
GO

PRINT '==============================================';
PRINT 'Lab 51: Advanced Dynamic SQL';
PRINT '==============================================';
PRINT '';

/*
 * PART 1: DYNAMIC UNPIVOT
 */

PRINT 'PART 1: Dynamic UNPIVOT';
PRINT '------------------------';

-- Create sample pivoted data
IF OBJECT_ID('QuarterlySales', 'U') IS NOT NULL DROP TABLE QuarterlySales;
CREATE TABLE QuarterlySales (
    ProductID INT PRIMARY KEY,
    Q1 DECIMAL(10,2),
    Q2 DECIMAL(10,2),
    Q3 DECIMAL(10,2),
    Q4 DECIMAL(10,2)
);

INSERT INTO QuarterlySales VALUES
(1, 10000, 12000, 11000, 13000),
(2, 8000, 9000, 8500, 9500),
(3, 15000, 16000, 17000, 18000);

PRINT '✓ Created QuarterlySales';
PRINT '';

IF OBJECT_ID('usp_DynamicUnpivot', 'P') IS NOT NULL DROP PROCEDURE usp_DynamicUnpivot;
GO

CREATE PROCEDURE usp_DynamicUnpivot
    @TableName NVARCHAR(128),
    @KeyColumn NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Get columns to unpivot (exclude key column)
    DECLARE @Columns NVARCHAR(MAX);
    
    SELECT @Columns = STRING_AGG(QUOTENAME(column_name), ', ')
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE table_name = @TableName
    AND column_name <> @KeyColumn;
    
    -- Build UNPIVOT query
    DECLARE @SQL NVARCHAR(MAX) = N'
        SELECT ' + QUOTENAME(@KeyColumn) + N', Period, Amount
        FROM ' + QUOTENAME(@TableName) + N'
        UNPIVOT (
            Amount FOR Period IN (' + @Columns + N')
        ) AS UnpivotedData
        ORDER BY ' + QUOTENAME(@KeyColumn) + N', Period';
    
    PRINT 'Dynamic UNPIVOT query:';
    PRINT @SQL;
    PRINT '';
    
    EXEC sp_executesql @SQL;
END;
GO

EXEC usp_DynamicUnpivot 
    @TableName = 'QuarterlySales',
    @KeyColumn = 'ProductID';

PRINT '';

/*
 * PART 2: CONFIGURATION-DRIVEN QUERIES
 */

PRINT 'PART 2: Configuration-Driven Queries';
PRINT '--------------------------------------';

-- Create query configuration table
IF OBJECT_ID('QueryConfigs', 'U') IS NOT NULL DROP TABLE QueryConfigs;
CREATE TABLE QueryConfigs (
    ConfigID INT PRIMARY KEY,
    ConfigName NVARCHAR(100),
    BaseTable NVARCHAR(128),
    SelectColumns NVARCHAR(MAX),
    JoinClauses NVARCHAR(MAX),
    WhereClause NVARCHAR(MAX),
    OrderByClause NVARCHAR(MAX)
);

INSERT INTO QueryConfigs VALUES
(1, 'ExpensiveBooks', 'Books', 'BookID, Title, Price', NULL, 'Price > 50', 'Price DESC'),
(2, 'RecentOrders', 'Orders', 'OrderID, OrderDate, TotalAmount', 
    'INNER JOIN Customers c ON Orders.CustomerID = c.CustomerID', 
    'OrderDate >= DATEADD(DAY, -30, GETDATE())', 'OrderDate DESC');

PRINT '✓ Created QueryConfigs';
PRINT '';

IF OBJECT_ID('usp_ExecuteConfiguredQuery', 'P') IS NOT NULL DROP PROCEDURE usp_ExecuteConfiguredQuery;
GO

CREATE PROCEDURE usp_ExecuteConfiguredQuery
    @ConfigName NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @BaseTable NVARCHAR(128);
    DECLARE @SelectColumns NVARCHAR(MAX);
    DECLARE @JoinClauses NVARCHAR(MAX);
    DECLARE @WhereClause NVARCHAR(MAX);
    DECLARE @OrderByClause NVARCHAR(MAX);
    
    -- Get configuration
    SELECT 
        @BaseTable = BaseTable,
        @SelectColumns = SelectColumns,
        @JoinClauses = JoinClauses,
        @WhereClause = WhereClause,
        @OrderByClause = OrderByClause
    FROM QueryConfigs
    WHERE ConfigName = @ConfigName;
    
    IF @BaseTable IS NULL
    BEGIN
        RAISERROR('Configuration not found', 16, 1);
        RETURN;
    END;
    
    -- Build query from configuration
    DECLARE @SQL NVARCHAR(MAX) = N'SELECT ' + @SelectColumns + 
                                 N' FROM ' + QUOTENAME(@BaseTable);
    
    IF @JoinClauses IS NOT NULL
        SET @SQL = @SQL + N' ' + @JoinClauses;
    
    IF @WhereClause IS NOT NULL
        SET @SQL = @SQL + N' WHERE ' + @WhereClause;
    
    IF @OrderByClause IS NOT NULL
        SET @SQL = @SQL + N' ORDER BY ' + @OrderByClause;
    
    PRINT 'Executing configured query: ' + @ConfigName;
    PRINT @SQL;
    PRINT '';
    
    EXEC sp_executesql @SQL;
END;
GO

EXEC usp_ExecuteConfiguredQuery @ConfigName = 'ExpensiveBooks';
PRINT '';

/*
 * PART 3: DYNAMIC AGGREGATIONS
 */

PRINT 'PART 3: Dynamic Aggregations';
PRINT '------------------------------';

IF OBJECT_ID('usp_DynamicAggregation', 'P') IS NOT NULL DROP PROCEDURE usp_DynamicAggregation;
GO

CREATE PROCEDURE usp_DynamicAggregation
    @TableName NVARCHAR(128),
    @GroupByColumn NVARCHAR(128),
    @AggregateColumn NVARCHAR(128),
    @AggregateFunction NVARCHAR(10) = 'SUM'
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validate aggregate function
    IF @AggregateFunction NOT IN ('SUM', 'AVG', 'MIN', 'MAX', 'COUNT')
    BEGIN
        RAISERROR('Invalid aggregate function', 16, 1);
        RETURN;
    END;
    
    -- Build aggregation query
    DECLARE @SQL NVARCHAR(MAX) = N'
        SELECT 
            ' + QUOTENAME(@GroupByColumn) + N' AS GroupKey,
            COUNT(*) AS RecordCount,
            ' + @AggregateFunction + N'(' + QUOTENAME(@AggregateColumn) + N') AS AggregateValue,
            MIN(' + QUOTENAME(@AggregateColumn) + N') AS MinValue,
            MAX(' + QUOTENAME(@AggregateColumn) + N') AS MaxValue,
            AVG(' + QUOTENAME(@AggregateColumn) + N') AS AvgValue
        FROM ' + QUOTENAME(@TableName) + N'
        WHERE ' + QUOTENAME(@AggregateColumn) + N' IS NOT NULL
        GROUP BY ' + QUOTENAME(@GroupByColumn) + N'
        ORDER BY AggregateValue DESC';
    
    PRINT 'Aggregate: ' + @AggregateFunction + '(' + @AggregateColumn + ') BY ' + @GroupByColumn;
    PRINT '';
    
    EXEC sp_executesql @SQL;
END;
GO

EXEC usp_DynamicAggregation 
    @TableName = 'Books',
    @GroupByColumn = 'CategoryID',
    @AggregateColumn = 'Price',
    @AggregateFunction = 'AVG';

PRINT '';

/*
 * PART 4: DYNAMIC TEMP TABLE CREATION
 */

PRINT 'PART 4: Dynamic Temp Tables';
PRINT '-----------------------------';

IF OBJECT_ID('usp_CreateTempFromSource', 'P') IS NOT NULL DROP PROCEDURE usp_CreateTempFromSource;
GO

CREATE PROCEDURE usp_CreateTempFromSource
    @SourceTable NVARCHAR(128),
    @WhereClause NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Drop existing temp table
    IF OBJECT_ID('tempdb..#DynamicTemp') IS NOT NULL
        DROP TABLE #DynamicTemp;
    
    -- Get column definitions
    DECLARE @ColumnDefs NVARCHAR(MAX);
    
    SELECT @ColumnDefs = STRING_AGG(
        QUOTENAME(column_name) + ' ' + 
        data_type + 
        CASE 
            WHEN data_type IN ('varchar', 'nvarchar', 'char', 'nchar') 
            THEN '(' + CASE WHEN character_maximum_length = -1 THEN 'MAX' 
                           ELSE CAST(character_maximum_length AS NVARCHAR(10)) END + ')'
            WHEN data_type IN ('decimal', 'numeric')
            THEN '(' + CAST(numeric_precision AS NVARCHAR(10)) + ',' + 
                       CAST(numeric_scale AS NVARCHAR(10)) + ')'
            ELSE ''
        END,
        ', '
    )
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE table_name = @SourceTable
    ORDER BY ordinal_position;
    
    -- Create temp table
    DECLARE @SQL1 NVARCHAR(MAX) = N'
        CREATE TABLE #DynamicTemp (' + @ColumnDefs + N')';
    
    PRINT 'Creating temp table:';
    PRINT @SQL1;
    PRINT '';
    
    EXEC sp_executesql @SQL1;
    
    -- Populate temp table
    DECLARE @SQL2 NVARCHAR(MAX) = N'
        INSERT INTO #DynamicTemp
        SELECT * FROM ' + QUOTENAME(@SourceTable);
    
    IF @WhereClause IS NOT NULL
        SET @SQL2 = @SQL2 + N' WHERE ' + @WhereClause;
    
    EXEC sp_executesql @SQL2;
    
    -- Query temp table
    DECLARE @SQL3 NVARCHAR(MAX) = N'SELECT TOP 5 * FROM #DynamicTemp';
    EXEC sp_executesql @SQL3;
    
    PRINT '✓ Temp table created and populated';
END;
GO

EXEC usp_CreateTempFromSource 
    @SourceTable = 'Books',
    @WhereClause = 'Price > 20';

PRINT '';

/*
 * PART 5: DYNAMIC CURSOR PROCESSING
 */

PRINT 'PART 5: Dynamic Cursor Processing';
PRINT '-----------------------------------';

IF OBJECT_ID('usp_DynamicCursorProcess', 'P') IS NOT NULL DROP PROCEDURE usp_DynamicCursorProcess;
GO

CREATE PROCEDURE usp_DynamicCursorProcess
    @TableName NVARCHAR(128),
    @KeyColumn NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Build cursor query
    DECLARE @SQL NVARCHAR(MAX) = N'
        DECLARE @KeyValue SQL_VARIANT;
        
        DECLARE cursor_dynamic CURSOR FOR
        SELECT ' + QUOTENAME(@KeyColumn) + N'
        FROM ' + QUOTENAME(@TableName) + N'
        ORDER BY ' + QUOTENAME(@KeyColumn) + N';
        
        OPEN cursor_dynamic;
        FETCH NEXT FROM cursor_dynamic INTO @KeyValue;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            PRINT ''Processing key: '' + CAST(@KeyValue AS NVARCHAR(100));
            -- Process logic here
            FETCH NEXT FROM cursor_dynamic INTO @KeyValue;
        END;
        
        CLOSE cursor_dynamic;
        DEALLOCATE cursor_dynamic;';
    
    PRINT 'Dynamic cursor for ' + @TableName + '.' + @KeyColumn;
    PRINT '';
    
    EXEC sp_executesql @SQL;
    
    PRINT '';
    PRINT 'NOTE: Cursors should be avoided when possible - use set-based operations!';
END;
GO

EXEC usp_DynamicCursorProcess 
    @TableName = 'Categories',
    @KeyColumn = 'CategoryID';

PRINT '';

/*
 * PART 6: METADATA-DRIVEN ETL
 */

PRINT 'PART 6: Metadata-Driven ETL';
PRINT '-----------------------------';

-- Create ETL mapping configuration
IF OBJECT_ID('ETLMappings', 'U') IS NOT NULL DROP TABLE ETLMappings;
CREATE TABLE ETLMappings (
    MappingID INT PRIMARY KEY,
    SourceTable NVARCHAR(128),
    TargetTable NVARCHAR(128),
    ColumnMappings NVARCHAR(MAX), -- JSON: [{"source":"col1","target":"col1"}]
    Transformation NVARCHAR(MAX)  -- SQL expression
);

INSERT INTO ETLMappings VALUES
(1, 'Books', 'BooksArchive', 
 '[{"source":"BookID","target":"ArchiveID"},{"source":"Title","target":"BookTitle"}]',
 NULL);

PRINT '✓ Created ETLMappings';
PRINT '';

IF OBJECT_ID('usp_MetadataETL', 'P') IS NOT NULL DROP PROCEDURE usp_MetadataETL;
GO

CREATE PROCEDURE usp_MetadataETL
    @MappingID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @SourceTable NVARCHAR(128);
    DECLARE @TargetTable NVARCHAR(128);
    
    SELECT 
        @SourceTable = SourceTable,
        @TargetTable = TargetTable
    FROM ETLMappings
    WHERE MappingID = @MappingID;
    
    IF @SourceTable IS NULL
    BEGIN
        RAISERROR('Mapping not found', 16, 1);
        RETURN;
    END;
    
    -- Build INSERT statement
    DECLARE @SQL NVARCHAR(MAX) = N'
        INSERT INTO ' + QUOTENAME(@TargetTable) + N'
        SELECT * FROM ' + QUOTENAME(@SourceTable);
    
    PRINT 'ETL Operation: ' + @SourceTable + ' → ' + @TargetTable;
    PRINT @SQL;
    PRINT '';
    PRINT '(Would execute in production)';
    -- EXEC sp_executesql @SQL;
END;
GO

EXEC usp_MetadataETL @MappingID = 1;
PRINT '';

/*
 * PART 7: DYNAMIC INDEXING
 */

PRINT 'PART 7: Dynamic Index Management';
PRINT '----------------------------------';

IF OBJECT_ID('usp_CreateIndexDynamic', 'P') IS NOT NULL DROP PROCEDURE usp_CreateIndexDynamic;
GO

CREATE PROCEDURE usp_CreateIndexDynamic
    @TableName NVARCHAR(128),
    @ColumnName NVARCHAR(128),
    @Unique BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Generate index name
    DECLARE @IndexName NVARCHAR(200) = 'IX_' + @TableName + '_' + @ColumnName;
    
    -- Check if index exists
    IF EXISTS (
        SELECT 1 FROM sys.indexes 
        WHERE object_id = OBJECT_ID(@TableName) 
        AND name = @IndexName
    )
    BEGIN
        PRINT 'Index already exists: ' + @IndexName;
        RETURN;
    END;
    
    -- Build CREATE INDEX statement
    DECLARE @SQL NVARCHAR(MAX) = N'CREATE ' + 
        CASE WHEN @Unique = 1 THEN 'UNIQUE ' ELSE '' END +
        N'INDEX ' + QUOTENAME(@IndexName) + N'
        ON ' + QUOTENAME(@TableName) + N' (' + QUOTENAME(@ColumnName) + N')';
    
    PRINT 'Creating index:';
    PRINT @SQL;
    
    EXEC sp_executesql @SQL;
    
    PRINT '✓ Index created successfully';
END;
GO

-- Test (commented to avoid creating real indexes)
-- EXEC usp_CreateIndexDynamic 
--     @TableName = 'Books',
--     @ColumnName = 'PublicationYear',
--     @Unique = 0;

PRINT '';

/*
 * PART 8: DYNAMIC JSON/XML GENERATION
 */

PRINT 'PART 8: Dynamic JSON/XML Output';
PRINT '---------------------------------';

IF OBJECT_ID('usp_DynamicJSONExport', 'P') IS NOT NULL DROP PROCEDURE usp_DynamicJSONExport;
GO

CREATE PROCEDURE usp_DynamicJSONExport
    @TableName NVARCHAR(128),
    @TopN INT = 5
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Build JSON query
    DECLARE @SQL NVARCHAR(MAX) = N'
        SELECT TOP (@TopNParam) *
        FROM ' + QUOTENAME(@TableName) + N'
        FOR JSON AUTO, ROOT(''' + @TableName + ''')';
    
    DECLARE @Params NVARCHAR(MAX) = N'@TopNParam INT';
    
    PRINT 'Generating JSON for ' + @TableName + ':';
    PRINT '';
    
    EXEC sp_executesql @SQL, @Params, @TopNParam = @TopN;
END;
GO

EXEC usp_DynamicJSONExport @TableName = 'Categories', @TopN = 3;
PRINT '';

/*
 * PART 9: DYNAMIC STATISTICS COLLECTION
 */

PRINT 'PART 9: Dynamic Statistics';
PRINT '----------------------------';

IF OBJECT_ID('usp_CollectTableStats', 'P') IS NOT NULL DROP PROCEDURE usp_CollectTableStats;
GO

CREATE PROCEDURE usp_CollectTableStats
    @SchemaName NVARCHAR(128) = 'dbo'
AS
BEGIN
    SET NOCOUNT ON;
    
    CREATE TABLE #TableStats (
        TableName NVARCHAR(128),
        RowCount BIGINT,
        TotalSpaceKB BIGINT,
        UsedSpaceKB BIGINT
    );
    
    -- Get list of tables
    DECLARE @TableName NVARCHAR(128);
    DECLARE @SQL NVARCHAR(MAX);
    
    DECLARE table_cursor CURSOR FOR
    SELECT name 
    FROM sys.tables 
    WHERE SCHEMA_NAME(schema_id) = @SchemaName
    ORDER BY name;
    
    OPEN table_cursor;
    FETCH NEXT FROM table_cursor INTO @TableName;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Get row count dynamically
        SET @SQL = N'
            INSERT INTO #TableStats (TableName, RowCount, TotalSpaceKB, UsedSpaceKB)
            SELECT 
                @TableParam,
                COUNT(*),
                0,
                0
            FROM ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName);
        
        EXEC sp_executesql @SQL, N'@TableParam NVARCHAR(128)', @TableParam = @TableName;
        
        FETCH NEXT FROM table_cursor INTO @TableName;
    END;
    
    CLOSE table_cursor;
    DEALLOCATE table_cursor;
    
    -- Return results
    SELECT * FROM #TableStats ORDER BY RowCount DESC;
    
    DROP TABLE #TableStats;
END;
GO

EXEC usp_CollectTableStats @SchemaName = 'dbo';
PRINT '';

/*
 * PART 10: BEST PRACTICES
 */

PRINT 'PART 10: Advanced Dynamic SQL Best Practices';
PRINT '----------------------------------------------';
PRINT '';
PRINT 'ARCHITECTURE:';
PRINT '  ✓ Centralize dynamic SQL in utility procedures';
PRINT '  ✓ Use configuration tables for complex rules';
PRINT '  ✓ Separate business logic from SQL generation';
PRINT '  ✓ Version control dynamic SQL patterns';
PRINT '  ✓ Document metadata dependencies';
PRINT '';
PRINT 'METADATA USAGE:';
PRINT '  ✓ Cache metadata when possible';
PRINT '  ✓ Validate against INFORMATION_SCHEMA';
PRINT '  ✓ Use sys views for detailed information';
PRINT '  ✓ Handle schema changes gracefully';
PRINT '';
PRINT 'PERFORMANCE:';
PRINT '  ✓ Monitor plan cache pollution';
PRINT '  ✓ Reuse parameter definitions';
PRINT '  ✓ Avoid over-parameterization';
PRINT '  ✓ Consider compile-time overhead';
PRINT '  ✓ Use RECOMPILE hint when needed';
PRINT '';
PRINT 'TESTING:';
PRINT '  ✓ Unit test all dynamic procedures';
PRINT '  ✓ Test with edge cases';
PRINT '  ✓ Verify SQL injection protection';
PRINT '  ✓ Load test with realistic data';
PRINT '  ✓ Review execution plans';
PRINT '';
PRINT 'DEBUGGING:';
PRINT '  ✓ PRINT generated SQL in development';
PRINT '  ✓ Log dynamic SQL to audit table';
PRINT '  ✓ Add debug mode parameter';
PRINT '  ✓ Use TRY/CATCH with detailed errors';
PRINT '  ✓ Validate inputs before execution';
PRINT '';
PRINT 'PATTERNS TO AVOID:';
PRINT '  ✗ Excessive dynamic SQL (consider alternatives)';
PRINT '  ✗ Complex business logic in dynamic SQL';
PRINT '  ✗ Dynamic SQL in high-frequency paths';
PRINT '  ✗ Generating entire applications dynamically';
PRINT '  ✗ Ignoring metadata validation';
PRINT '';

-- Final example: Complete dynamic query builder
PRINT 'Complete Query Builder Example:';
PRINT '';
PRINT 'CREATE PROCEDURE usp_QueryBuilder';
PRINT '    @Table NVARCHAR(128),';
PRINT '    @Columns NVARCHAR(MAX) = NULL,';
PRINT '    @Where NVARCHAR(MAX) = NULL,';
PRINT '    @OrderBy NVARCHAR(MAX) = NULL,';
PRINT '    @TopN INT = NULL,';
PRINT '    @Debug BIT = 0';
PRINT 'AS';
PRINT 'BEGIN';
PRINT '    -- Validate table';
PRINT '    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = @Table)';
PRINT '        THROW 50001, ''Invalid table'', 1;';
PRINT '    ';
PRINT '    -- Default columns';
PRINT '    IF @Columns IS NULL';
PRINT '        SET @Columns = ''*'';';
PRINT '    ';
PRINT '    -- Build query';
PRINT '    DECLARE @SQL NVARCHAR(MAX) = ';
PRINT '        N''SELECT '' + CASE WHEN @TopN IS NOT NULL ';
PRINT '        THEN ''TOP '' + CAST(@TopN AS NVARCHAR(10)) + '' '' ELSE '''' END +';
PRINT '        @Columns + N'' FROM '' + QUOTENAME(@Table);';
PRINT '    ';
PRINT '    IF @Where IS NOT NULL';
PRINT '        SET @SQL = @SQL + N'' WHERE '' + @Where;';
PRINT '    ';
PRINT '    IF @OrderBy IS NOT NULL';
PRINT '        SET @SQL = @SQL + N'' ORDER BY '' + @OrderBy;';
PRINT '    ';
PRINT '    IF @Debug = 1';
PRINT '        PRINT @SQL;';
PRINT '    ';
PRINT '    EXEC sp_executesql @SQL;';
PRINT 'END;';
PRINT '';

/*
 * EXERCISES:
 * 
 * 1. Create dynamic stored procedure generator from table metadata
 * 2. Build configurable data comparison tool
 * 3. Implement dynamic data masking system
 * 4. Create metadata-driven data warehouse ETL
 * 5. Build query performance analyzer with dynamic queries
 * 
 * CHALLENGE:
 * Create enterprise metadata framework:
 * - MetadataRepository: Store all metadata centrally
 * - Dynamic CRUD generator: Full Create/Read/Update/Delete
 * - Query builder with validation and optimization
 * - Automatic index recommendation engine
 * - Data quality rules engine (metadata-driven)
 * - Schema comparison and sync tools
 * - Automatic documentation generator
 * - Performance baseline collector
 * - Change impact analyzer
 * - Self-service BI query builder
 */

PRINT '✓ Lab 51 Complete: Advanced dynamic SQL mastered';
PRINT '';
PRINT 'Dynamic SQL section complete!';
PRINT 'Final Lab: T-SQL Capstone Project (Lab 52)';
GO
