/*
 * Lab 50: Dynamic SQL Mastery
 * Module 05: T-SQL Programming
 * 
 * Objective: Master dynamic SQL with sp_executesql
 * Duration: 75 minutes
 * Difficulty: ⭐⭐⭐⭐
 */

USE BookstoreDB;
GO

PRINT '==============================================';
PRINT 'Lab 50: Dynamic SQL Mastery';
PRINT '==============================================';
PRINT '';

/*
 * PART 1: EXEC vs sp_executesql
 */

PRINT 'PART 1: EXEC vs sp_executesql';
PRINT '-------------------------------';

-- EXEC method (NOT recommended)
PRINT 'EXEC method (vulnerable to SQL injection):';
DECLARE @TableName1 NVARCHAR(128) = 'Books';
DECLARE @SQL1 NVARCHAR(MAX) = 'SELECT TOP 5 * FROM ' + @TableName1;
PRINT @SQL1;
EXEC(@SQL1);

PRINT '';
PRINT 'Problem: String concatenation vulnerable to injection!';
PRINT 'Example attack: @TableName = ''Books; DROP TABLE Books;--''';
PRINT '';

-- sp_executesql method (recommended)
PRINT 'sp_executesql with parameters (SAFE):';
DECLARE @SQL2 NVARCHAR(MAX) = N'SELECT TOP 5 * FROM Books WHERE Price > @MinPrice';
DECLARE @Params NVARCHAR(MAX) = N'@MinPrice DECIMAL(10,2)';
DECLARE @MinPrice DECIMAL(10,2) = 20.00;

PRINT @SQL2;
EXEC sp_executesql @SQL2, @Params, @MinPrice = @MinPrice;

PRINT '';
PRINT 'Benefits:';
PRINT '  ✓ Parameterized (SQL injection safe)';
PRINT '  ✓ Plan reuse (better performance)';
PRINT '  ✓ OUTPUT parameters supported';
PRINT '  ✓ Type safety';
PRINT '';

/*
 * PART 2: DYNAMIC TABLE/COLUMN NAMES
 */

PRINT 'PART 2: Dynamic Object Names';
PRINT '------------------------------';

IF OBJECT_ID('usp_DynamicQuery', 'P') IS NOT NULL DROP PROCEDURE usp_DynamicQuery;
GO

CREATE PROCEDURE usp_DynamicQuery
    @TableName NVARCHAR(128),
    @ColumnName NVARCHAR(128),
    @FilterValue NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validate table name (security!)
    IF NOT EXISTS (
        SELECT 1 FROM sys.tables 
        WHERE name = @TableName AND SCHEMA_NAME(schema_id) = 'dbo'
    )
    BEGIN
        RAISERROR('Invalid table name', 16, 1);
        RETURN;
    END;
    
    -- Validate column name
    IF NOT EXISTS (
        SELECT 1 FROM sys.columns 
        WHERE object_id = OBJECT_ID(@TableName) AND name = @ColumnName
    )
    BEGIN
        RAISERROR('Invalid column name', 16, 1);
        RETURN;
    END;
    
    -- Build query safely
    DECLARE @SQL NVARCHAR(MAX);
    SET @SQL = N'
        SELECT TOP 10 * 
        FROM ' + QUOTENAME(@TableName) + N'
        WHERE ' + QUOTENAME(@ColumnName) + N' LIKE @FilterValueParam';
    
    -- Execute with parameter
    DECLARE @Params NVARCHAR(MAX) = N'@FilterValueParam NVARCHAR(255)';
    EXEC sp_executesql @SQL, @Params, @FilterValueParam = @FilterValue;
    
    PRINT 'Query executed safely with QUOTENAME protection';
END;
GO

-- Test
EXEC usp_DynamicQuery 
    @TableName = 'Books', 
    @ColumnName = 'Title', 
    @FilterValue = '%SQL%';

PRINT '';

/*
 * PART 3: DYNAMIC WHERE CLAUSE
 */

PRINT 'PART 3: Dynamic WHERE Clause';
PRINT '------------------------------';

IF OBJECT_ID('usp_FlexibleSearch', 'P') IS NOT NULL DROP PROCEDURE usp_FlexibleSearch;
GO

CREATE PROCEDURE usp_FlexibleSearch
    @Title NVARCHAR(255) = NULL,
    @MinPrice DECIMAL(10,2) = NULL,
    @MaxPrice DECIMAL(10,2) = NULL,
    @MinYear INT = NULL,
    @CategoryID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @SQL NVARCHAR(MAX) = N'SELECT * FROM Books WHERE 1=1';
    DECLARE @Params NVARCHAR(MAX) = N'';
    
    -- Build WHERE clause dynamically
    IF @Title IS NOT NULL
    BEGIN
        SET @SQL = @SQL + N' AND Title LIKE @TitleParam';
        SET @Params = @Params + N'@TitleParam NVARCHAR(255), ';
    END;
    
    IF @MinPrice IS NOT NULL
    BEGIN
        SET @SQL = @SQL + N' AND Price >= @MinPriceParam';
        SET @Params = @Params + N'@MinPriceParam DECIMAL(10,2), ';
    END;
    
    IF @MaxPrice IS NOT NULL
    BEGIN
        SET @SQL = @SQL + N' AND Price <= @MaxPriceParam';
        SET @Params = @Params + N'@MaxPriceParam DECIMAL(10,2), ';
    END;
    
    IF @MinYear IS NOT NULL
    BEGIN
        SET @SQL = @SQL + N' AND PublicationYear >= @MinYearParam';
        SET @Params = @Params + N'@MinYearParam INT, ';
    END;
    
    IF @CategoryID IS NOT NULL
    BEGIN
        SET @SQL = @SQL + N' AND CategoryID = @CategoryIDParam';
        SET @Params = @Params + N'@CategoryIDParam INT, ';
    END;
    
    -- Remove trailing comma
    IF LEN(@Params) > 0
        SET @Params = LEFT(@Params, LEN(@Params) - 1);
    
    -- Debug output
    PRINT 'Generated SQL:';
    PRINT @SQL;
    PRINT '';
    
    -- Execute
    EXEC sp_executesql 
        @SQL, 
        @Params,
        @TitleParam = @Title,
        @MinPriceParam = @MinPrice,
        @MaxPriceParam = @MaxPrice,
        @MinYearParam = @MinYear,
        @CategoryIDParam = @CategoryID;
END;
GO

-- Test with various combinations
EXEC usp_FlexibleSearch @Title = '%SQL%', @MinPrice = 20;
PRINT '';

/*
 * PART 4: DYNAMIC ORDER BY
 */

PRINT 'PART 4: Dynamic ORDER BY';
PRINT '-------------------------';

IF OBJECT_ID('usp_DynamicSort', 'P') IS NOT NULL DROP PROCEDURE usp_DynamicSort;
GO

CREATE PROCEDURE usp_DynamicSort
    @SortColumn NVARCHAR(128) = 'Title',
    @SortDirection NVARCHAR(4) = 'ASC',
    @TopN INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validate sort column
    IF @SortColumn NOT IN ('BookID', 'Title', 'Price', 'PublicationYear')
    BEGIN
        RAISERROR('Invalid sort column', 16, 1);
        RETURN;
    END;
    
    -- Validate sort direction
    IF @SortDirection NOT IN ('ASC', 'DESC')
    BEGIN
        RAISERROR('Sort direction must be ASC or DESC', 16, 1);
        RETURN;
    END;
    
    -- Build query
    DECLARE @SQL NVARCHAR(MAX) = N'
        SELECT TOP (@TopNParam) 
            BookID, Title, Price, PublicationYear
        FROM Books
        ORDER BY ' + QUOTENAME(@SortColumn) + N' ' + @SortDirection;
    
    DECLARE @Params NVARCHAR(MAX) = N'@TopNParam INT';
    
    PRINT 'Sorting by: ' + @SortColumn + ' ' + @SortDirection;
    
    EXEC sp_executesql @SQL, @Params, @TopNParam = @TopN;
END;
GO

-- Test different sorts
EXEC usp_DynamicSort @SortColumn = 'Price', @SortDirection = 'DESC', @TopN = 5;
PRINT '';

/*
 * PART 5: DYNAMIC PIVOT
 */

PRINT 'PART 5: Dynamic PIVOT Queries';
PRINT '-------------------------------';

-- Create sample sales data
IF OBJECT_ID('MonthlySales', 'U') IS NOT NULL DROP TABLE MonthlySales;
CREATE TABLE MonthlySales (
    SaleYear INT,
    SaleMonth INT,
    CategoryID INT,
    Amount DECIMAL(10,2)
);

INSERT INTO MonthlySales VALUES
(2024, 1, 1, 1000), (2024, 2, 1, 1200), (2024, 3, 1, 1100),
(2024, 1, 2, 800), (2024, 2, 2, 900), (2024, 3, 2, 950),
(2024, 1, 3, 1500), (2024, 2, 3, 1600), (2024, 3, 3, 1700);

PRINT '✓ Created MonthlySales test data';
PRINT '';

IF OBJECT_ID('usp_DynamicPivot', 'P') IS NOT NULL DROP PROCEDURE usp_DynamicPivot;
GO

CREATE PROCEDURE usp_DynamicPivot
    @Year INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Get distinct months dynamically
    DECLARE @Columns NVARCHAR(MAX);
    DECLARE @SQL NVARCHAR(MAX);
    
    SELECT @Columns = STRING_AGG(QUOTENAME(SaleMonth), ', ')
    FROM (SELECT DISTINCT SaleMonth FROM MonthlySales WHERE SaleYear = @Year) AS Months;
    
    -- Build pivot query
    SET @SQL = N'
        SELECT CategoryID, ' + @Columns + N'
        FROM (
            SELECT CategoryID, SaleMonth, Amount
            FROM MonthlySales
            WHERE SaleYear = @YearParam
        ) AS SourceData
        PIVOT (
            SUM(Amount)
            FOR SaleMonth IN (' + @Columns + N')
        ) AS PivotTable
        ORDER BY CategoryID';
    
    PRINT 'Dynamic PIVOT for year ' + CAST(@Year AS NVARCHAR(10));
    PRINT 'Columns: ' + @Columns;
    PRINT '';
    
    DECLARE @Params NVARCHAR(MAX) = N'@YearParam INT';
    EXEC sp_executesql @SQL, @Params, @YearParam = @Year;
END;
GO

EXEC usp_DynamicPivot @Year = 2024;
PRINT '';

/*
 * PART 6: OUTPUT PARAMETERS
 */

PRINT 'PART 6: Dynamic SQL with OUTPUT';
PRINT '---------------------------------';

IF OBJECT_ID('usp_DynamicCount', 'P') IS NOT NULL DROP PROCEDURE usp_DynamicCount;
GO

CREATE PROCEDURE usp_DynamicCount
    @TableName NVARCHAR(128),
    @WhereClause NVARCHAR(MAX) = NULL,
    @RowCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validate table
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = @TableName)
    BEGIN
        RAISERROR('Invalid table name', 16, 1);
        RETURN;
    END;
    
    -- Build query
    DECLARE @SQL NVARCHAR(MAX) = N'SELECT @CountOUT = COUNT(*) FROM ' + QUOTENAME(@TableName);
    
    IF @WhereClause IS NOT NULL
        SET @SQL = @SQL + N' WHERE ' + @WhereClause;
    
    DECLARE @Params NVARCHAR(MAX) = N'@CountOUT INT OUTPUT';
    
    -- Execute with OUTPUT
    EXEC sp_executesql @SQL, @Params, @CountOUT = @RowCount OUTPUT;
    
    PRINT 'Count from ' + @TableName + ': ' + CAST(@RowCount AS NVARCHAR(10));
END;
GO

DECLARE @Count INT;
EXEC usp_DynamicCount 
    @TableName = 'Books', 
    @WhereClause = 'Price > 20',
    @RowCount = @Count OUTPUT;

PRINT 'Returned count: ' + CAST(@Count AS NVARCHAR(10));
PRINT '';

/*
 * PART 7: DYNAMIC DDL
 */

PRINT 'PART 7: Dynamic DDL Statements';
PRINT '--------------------------------';

IF OBJECT_ID('usp_CreateTableDynamic', 'P') IS NOT NULL DROP PROCEDURE usp_CreateTableDynamic;
GO

CREATE PROCEDURE usp_CreateTableDynamic
    @TableName NVARCHAR(128),
    @ColumnDef NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validate table doesn't exist
    IF EXISTS (SELECT 1 FROM sys.tables WHERE name = @TableName)
    BEGIN
        RAISERROR('Table already exists', 16, 1);
        RETURN;
    END;
    
    -- Build CREATE TABLE statement
    DECLARE @SQL NVARCHAR(MAX) = N'
        CREATE TABLE ' + QUOTENAME(@TableName) + N' (
            ' + @ColumnDef + N'
        )';
    
    PRINT 'Creating table:';
    PRINT @SQL;
    PRINT '';
    
    EXEC sp_executesql @SQL;
    
    PRINT '✓ Table created successfully';
END;
GO

-- Test
EXEC usp_CreateTableDynamic 
    @TableName = 'DynamicTest',
    @ColumnDef = 'ID INT PRIMARY KEY, Name NVARCHAR(100), CreatedDate DATETIME2 DEFAULT SYSDATETIME()';

-- Cleanup
DROP TABLE DynamicTest;
PRINT '';

/*
 * PART 8: METADATA-DRIVEN QUERIES
 */

PRINT 'PART 8: Metadata-Driven Queries';
PRINT '---------------------------------';

IF OBJECT_ID('usp_GenerateSelectAll', 'P') IS NOT NULL DROP PROCEDURE usp_GenerateSelectAll;
GO

CREATE PROCEDURE usp_GenerateSelectAll
    @TableName NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Get column list from metadata
    DECLARE @ColumnList NVARCHAR(MAX);
    
    SELECT @ColumnList = STRING_AGG(
        QUOTENAME(column_name) + 
        CASE 
            WHEN data_type IN ('varchar', 'nvarchar', 'char', 'nchar') 
            THEN ' AS [' + column_name + ' (len=' + CAST(character_maximum_length AS NVARCHAR(10)) + ')]'
            ELSE ' AS [' + column_name + ']'
        END,
        ', '
    )
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE table_name = @TableName
    ORDER BY ordinal_position;
    
    -- Build query
    DECLARE @SQL NVARCHAR(MAX) = N'
        SELECT TOP 5 ' + @ColumnList + N'
        FROM ' + QUOTENAME(@TableName);
    
    PRINT 'Generated SELECT with metadata:';
    PRINT @SQL;
    PRINT '';
    
    EXEC sp_executesql @SQL;
END;
GO

EXEC usp_GenerateSelectAll @TableName = 'Books';
PRINT '';

/*
 * PART 9: PERFORMANCE CONSIDERATIONS
 */

PRINT 'PART 9: Performance & Plan Caching';
PRINT '------------------------------------';
PRINT '';
PRINT 'Plan Reuse with sp_executesql:';
PRINT '';

-- Clear plan cache (dev only!)
-- DBCC FREEPROCCACHE;

-- Multiple executions with different parameters
DECLARE @SQL3 NVARCHAR(MAX) = N'SELECT * FROM Books WHERE Price > @Price';
DECLARE @Params3 NVARCHAR(MAX) = N'@Price DECIMAL(10,2)';

EXEC sp_executesql @SQL3, @Params3, @Price = 10.00;
EXEC sp_executesql @SQL3, @Params3, @Price = 20.00;
EXEC sp_executesql @SQL3, @Params3, @Price = 30.00;

PRINT 'Same plan reused for all three executions!';
PRINT '';
PRINT 'Check plan cache:';
PRINT 'SELECT usecounts, cacheobjtype, objtype, text';
PRINT 'FROM sys.dm_exec_cached_plans';
PRINT 'CROSS APPLY sys.dm_exec_sql_text(plan_handle);';
PRINT '';

PRINT 'Performance Tips:';
PRINT '  ✓ Use sp_executesql not EXEC for better caching';
PRINT '  ✓ Parameterize when possible';
PRINT '  ✓ Reuse parameter definitions';
PRINT '  ✓ Avoid changing query structure';
PRINT '  ✗ Don''t concatenate parameters into SQL string';
PRINT '';

/*
 * PART 10: BEST PRACTICES
 */

PRINT 'PART 10: Dynamic SQL Best Practices';
PRINT '-------------------------------------';
PRINT '';
PRINT 'SECURITY:';
PRINT '  ✓ ALWAYS use sp_executesql with parameters';
PRINT '  ✓ NEVER concatenate user input into SQL';
PRINT '  ✓ Validate table/column names against metadata';
PRINT '  ✓ Use QUOTENAME for identifiers';
PRINT '  ✓ Whitelist allowed values when possible';
PRINT '  ✓ Grant minimum permissions';
PRINT '';
PRINT 'PERFORMANCE:';
PRINT '  ✓ Use sp_executesql for plan reuse';
PRINT '  ✓ Parameterize variable parts';
PRINT '  ✓ Keep dynamic parts minimal';
PRINT '  ✓ Consider indexed views for common queries';
PRINT '  ✓ Monitor plan cache pollution';
PRINT '';
PRINT 'MAINTAINABILITY:';
PRINT '  ✓ Document why dynamic SQL is needed';
PRINT '  ✓ Use consistent coding style';
PRINT '  ✓ Include debug PRINT statements';
PRINT '  ✓ Add error handling';
PRINT '  ✓ Validate inputs thoroughly';
PRINT '';
PRINT 'WHEN TO USE:';
PRINT '  ✓ Dynamic sorting/filtering';
PRINT '  ✓ Dynamic table/column names';
PRINT '  ✓ Parameterized DDL';
PRINT '  ✓ Metadata-driven operations';
PRINT '  ✓ Dynamic PIVOT/UNPIVOT';
PRINT '';
PRINT 'WHEN TO AVOID:';
PRINT '  ✗ Static queries (use regular SQL)';
PRINT '  ✗ High-frequency operations (overhead)';
PRINT '  ✗ Complex business logic (use procedures)';
PRINT '  ✗ When permissions complexity is high';
PRINT '';
PRINT 'SQL INJECTION EXAMPLE (DON''T DO THIS!):';
PRINT '  -- VULNERABLE:';
PRINT '  SET @SQL = ''SELECT * FROM Users WHERE UserName='''''' + @UserInput + ''''''''';';
PRINT '  -- Attacker provides: '' OR 1=1--';
PRINT '  -- Results in: SELECT * FROM Users WHERE UserName='''' OR 1=1--''';
PRINT '  -- Returns ALL users!';
PRINT '';
PRINT '  -- SAFE:';
PRINT '  SET @SQL = N''SELECT * FROM Users WHERE UserName=@UserParam'';';
PRINT '  EXEC sp_executesql @SQL, N''@UserParam NVARCHAR(50)'', @UserParam=@UserInput;';
PRINT '';

-- Example validation pattern
PRINT 'Validation Pattern:';
PRINT '';
PRINT 'IF @TableName NOT IN (SELECT name FROM sys.tables)';
PRINT 'BEGIN';
PRINT '    RAISERROR(''Invalid table'', 16, 1);';
PRINT '    RETURN;';
PRINT 'END;';
PRINT '';

/*
 * EXERCISES:
 * 
 * 1. Create dynamic search with 10+ optional parameters
 * 2. Build metadata-driven CRUD generator
 * 3. Create dynamic unpivot procedure
 * 4. Implement configurable batch processing
 * 5. Build query builder with validation
 * 
 * CHALLENGE:
 * Create enterprise dynamic SQL framework:
 * - Query builder class with fluent API
 * - Automatic SQL injection prevention
 * - Parameter validation framework
 * - Query template library
 * - Plan cache monitoring
 * - Performance metrics collection
 * - Automatic query optimization hints
 * - Debug mode with query logging
 * - Unit tests for all dynamic procedures
 * - Documentation generator from metadata
 */

PRINT '✓ Lab 50 Complete: Dynamic SQL mastered';
GO
