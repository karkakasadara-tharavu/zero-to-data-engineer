/*
 * Lab 48: Transactions Fundamentals
 * Module 05: T-SQL Programming
 * 
 * Objective: Master transaction management and control
 * Duration: 90 minutes
 * Difficulty: ⭐⭐⭐⭐
 */

USE BookstoreDB;
GO

PRINT '==============================================';
PRINT 'Lab 48: Transactions Fundamentals';
PRINT '==============================================';
PRINT '';

/*
 * PART 1: BASIC TRANSACTIONS
 */

PRINT 'PART 1: Basic Transaction Syntax';
PRINT '----------------------------------';

-- Simple transaction
BEGIN TRANSACTION;

    INSERT INTO Books (Title, ISBN, Price, PublicationYear)
    VALUES ('Transaction Test 1', '777-7-77-777777-7', 19.99, 2024);
    
    PRINT 'Transaction active. @@TRANCOUNT = ' + CAST(@@TRANCOUNT AS NVARCHAR(10));
    
COMMIT TRANSACTION;

PRINT 'Transaction committed. @@TRANCOUNT = ' + CAST(@@TRANCOUNT AS NVARCHAR(10));
PRINT '';

-- Transaction with rollback
BEGIN TRANSACTION;

    INSERT INTO Books (Title, ISBN, Price, PublicationYear)
    VALUES ('Transaction Test 2', '766-6-66-666666-6', 24.99, 2024);
    
    PRINT 'Before rollback: @@TRANCOUNT = ' + CAST(@@TRANCOUNT AS NVARCHAR(10));
    
ROLLBACK TRANSACTION;

PRINT 'After rollback: @@TRANCOUNT = ' + CAST(@@TRANCOUNT AS NVARCHAR(10));
PRINT 'Transaction Test 2 should NOT exist:';

SELECT COUNT(*) AS Count 
FROM Books 
WHERE Title = 'Transaction Test 2';

PRINT '';

/*
 * PART 2: NESTED TRANSACTIONS
 */

PRINT 'PART 2: Nested Transactions';
PRINT '-----------------------------';

PRINT 'IMPORTANT: SQL Server does NOT support true nested transactions!';
PRINT '@@TRANCOUNT tracks nesting level, but ROLLBACK affects all levels.';
PRINT '';

BEGIN TRANSACTION;  -- Level 1
    PRINT 'Level 1: @@TRANCOUNT = ' + CAST(@@TRANCOUNT AS NVARCHAR(10));
    
    INSERT INTO Books (Title, ISBN, Price, PublicationYear)
    VALUES ('Nested Test 1', '755-5-55-555555-5', 29.99, 2024);
    
    BEGIN TRANSACTION;  -- Level 2
        PRINT 'Level 2: @@TRANCOUNT = ' + CAST(@@TRANCOUNT AS NVARCHAR(10));
        
        INSERT INTO Books (Title, ISBN, Price, PublicationYear)
        VALUES ('Nested Test 2', '744-4-44-444444-4', 34.99, 2024);
        
    COMMIT TRANSACTION;  -- Only decrements counter
    PRINT 'After inner commit: @@TRANCOUNT = ' + CAST(@@TRANCOUNT AS NVARCHAR(10));
    
COMMIT TRANSACTION;  -- Actually commits
PRINT 'After outer commit: @@TRANCOUNT = ' + CAST(@@TRANCOUNT AS NVARCHAR(10));

SELECT Title FROM Books WHERE Title LIKE 'Nested Test%';
PRINT '';

-- Demonstrate ROLLBACK behavior
BEGIN TRANSACTION;  -- Level 1
    PRINT 'Outer transaction started';
    
    INSERT INTO Books (Title, ISBN, Price, PublicationYear)
    VALUES ('Rollback Test 1', '733-3-33-333333-3', 39.99, 2024);
    
    BEGIN TRANSACTION;  -- Level 2
        PRINT 'Inner transaction started: @@TRANCOUNT = ' + CAST(@@TRANCOUNT AS NVARCHAR(10));
        
        INSERT INTO Books (Title, ISBN, Price, PublicationYear)
        VALUES ('Rollback Test 2', '722-2-22-222222-2', 44.99, 2024);
        
    ROLLBACK TRANSACTION;  -- ROLLS BACK EVERYTHING!
    PRINT 'After ROLLBACK: @@TRANCOUNT = ' + CAST(@@TRANCOUNT AS NVARCHAR(10));

-- Don't need outer commit - everything rolled back
SELECT COUNT(*) AS RollbackTestCount 
FROM Books 
WHERE Title LIKE 'Rollback Test%';

PRINT '';

/*
 * PART 3: @@TRANCOUNT MANAGEMENT
 */

PRINT 'PART 3: @@TRANCOUNT Management';
PRINT '--------------------------------';

IF OBJECT_ID('usp_TransactionDemo', 'P') IS NOT NULL DROP PROCEDURE usp_TransactionDemo;
GO

CREATE PROCEDURE usp_TransactionDemo
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @TranStarted BIT = 0;
    
    -- Check if transaction already active
    IF @@TRANCOUNT = 0
    BEGIN
        BEGIN TRANSACTION;
        SET @TranStarted = 1;
        PRINT 'New transaction started';
    END
    ELSE
    BEGIN
        PRINT 'Joined existing transaction (@@TRANCOUNT = ' + 
              CAST(@@TRANCOUNT AS NVARCHAR(10)) + ')';
    END;
    
    BEGIN TRY
        -- Perform operations
        INSERT INTO Books (Title, ISBN, Price, PublicationYear)
        VALUES ('TRANCOUNT Demo', '711-1-11-111111-1', 49.99, 2024);
        
        -- Only commit if we started the transaction
        IF @TranStarted = 1
        BEGIN
            COMMIT TRANSACTION;
            PRINT 'Transaction committed by procedure';
        END
        ELSE
        BEGIN
            PRINT 'Left transaction open for caller';
        END;
        
    END TRY
    BEGIN CATCH
        -- Only rollback if we started the transaction
        IF @TranStarted = 1 AND @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
            PRINT 'Transaction rolled back by procedure';
        END;
        
        -- Re-throw error
        THROW;
    END CATCH;
END;
GO

-- Test standalone call
EXEC usp_TransactionDemo;

PRINT '';

-- Test nested call
BEGIN TRANSACTION;
    PRINT 'Outer transaction: @@TRANCOUNT = ' + CAST(@@TRANCOUNT AS NVARCHAR(10));
    EXEC usp_TransactionDemo;
    PRINT 'After procedure: @@TRANCOUNT = ' + CAST(@@TRANCOUNT AS NVARCHAR(10));
COMMIT TRANSACTION;

PRINT '';

/*
 * PART 4: XACT_ABORT SETTING
 */

PRINT 'PART 4: XACT_ABORT Setting';
PRINT '----------------------------';

PRINT 'XACT_ABORT OFF (default):';
SET XACT_ABORT OFF;

BEGIN TRANSACTION;
    INSERT INTO Books (Title, ISBN, Price, PublicationYear)
    VALUES ('XACT_ABORT Test 1', '788-8-88-888888-8', 15.00, 2024);
    
    -- This will fail (NULL violation) but transaction continues
    BEGIN TRY
        INSERT INTO Books (Title, ISBN, Price, PublicationYear)
        VALUES (NULL, '799-9-99-999999-9', 20.00, 2024);
    END TRY
    BEGIN CATCH
        PRINT 'Error caught: ' + ERROR_MESSAGE();
        PRINT 'Transaction still active: @@TRANCOUNT = ' + CAST(@@TRANCOUNT AS NVARCHAR(10));
    END CATCH;
    
    -- This will succeed
    INSERT INTO Books (Title, ISBN, Price, PublicationYear)
    VALUES ('XACT_ABORT Test 2', '710-0-10-101010-0', 25.00, 2024);
    
COMMIT TRANSACTION;

SELECT Title FROM Books WHERE Title LIKE 'XACT_ABORT Test%';
PRINT '';

PRINT 'XACT_ABORT ON:';
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;
        INSERT INTO Books (Title, ISBN, Price, PublicationYear)
        VALUES ('XACT_ABORT Test 3', '800-8-00-800080-0', 30.00, 2024);
        
        -- This will fail and automatically rollback entire transaction
        INSERT INTO Books (Title, ISBN, Price, PublicationYear)
        VALUES (NULL, '801-8-01-800180-1', 35.00, 2024);
        
        -- This line never executes
        INSERT INTO Books (Title, ISBN, Price, PublicationYear)
        VALUES ('XACT_ABORT Test 4', '802-8-02-800280-2', 40.00, 2024);
        
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    PRINT 'Error: ' + ERROR_MESSAGE();
    PRINT '@@TRANCOUNT = ' + CAST(@@TRANCOUNT AS NVARCHAR(10));
    -- Transaction already rolled back automatically
END CATCH;

SET XACT_ABORT OFF;  -- Reset to default

SELECT COUNT(*) AS CountTest3And4
FROM Books 
WHERE Title IN ('XACT_ABORT Test 3', 'XACT_ABORT Test 4');

PRINT '';

/*
 * PART 5: XACT_STATE() FUNCTION
 */

PRINT 'PART 5: XACT_STATE() Function';
PRINT '-------------------------------';

IF OBJECT_ID('usp_XactStateDemo', 'P') IS NOT NULL DROP PROCEDURE usp_XactStateDemo;
GO

CREATE PROCEDURE usp_XactStateDemo
    @CauseError BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRANSACTION;
    
    BEGIN TRY
        PRINT 'XACT_STATE() = ' + CAST(XACT_STATE() AS NVARCHAR(10)) + ' (1 = committable)';
        
        INSERT INTO Books (Title, ISBN, Price, PublicationYear)
        VALUES ('XACT_STATE Demo', '811-8-11-811811-1', 45.00, 2024);
        
        IF @CauseError = 1
            RAISERROR('Intentional error', 16, 1);
        
        IF XACT_STATE() = 1
            COMMIT TRANSACTION;
        
    END TRY
    BEGIN CATCH
        PRINT 'In CATCH: XACT_STATE() = ' + CAST(XACT_STATE() AS NVARCHAR(10));
        
        IF XACT_STATE() = 1
        BEGIN
            -- Transaction is committable
            COMMIT TRANSACTION;
            PRINT 'Transaction committed despite error (rare)';
        END
        ELSE IF XACT_STATE() = -1
        BEGIN
            -- Transaction is uncommittable
            ROLLBACK TRANSACTION;
            PRINT 'Transaction rolled back (uncommittable)';
        END
        ELSE
        BEGIN
            -- No transaction active
            PRINT 'No active transaction';
        END;
        
        -- Re-throw
        THROW;
    END CATCH;
END;
GO

BEGIN TRY
    EXEC usp_XactStateDemo @CauseError = 1;
END TRY
BEGIN CATCH
    PRINT 'Error handled in caller';
END CATCH;

PRINT '';
PRINT 'XACT_STATE() values:';
PRINT '   1 = Transaction is active and committable';
PRINT '   0 = No transaction active';
PRINT '  -1 = Transaction is active but uncommittable (must rollback)';
PRINT '';

/*
 * PART 6: IMPLICIT TRANSACTIONS
 */

PRINT 'PART 6: Implicit Transactions';
PRINT '-------------------------------';

PRINT 'Default (IMPLICIT_TRANSACTIONS OFF):';
PRINT '  Each statement auto-commits';
PRINT '';

SET IMPLICIT_TRANSACTIONS ON;
PRINT 'IMPLICIT_TRANSACTIONS ON:';
PRINT '  Transaction starts automatically on first DML';
PRINT '  Must explicitly COMMIT or ROLLBACK';
PRINT '';

INSERT INTO Books (Title, ISBN, Price, PublicationYear)
VALUES ('Implicit Trans Test', '822-8-22-822822-2', 50.00, 2024);

PRINT 'After INSERT: @@TRANCOUNT = ' + CAST(@@TRANCOUNT AS NVARCHAR(10));
PRINT 'Transaction started implicitly!';
PRINT '';

-- Must explicitly commit
COMMIT TRANSACTION;
PRINT 'After COMMIT: @@TRANCOUNT = ' + CAST(@@TRANCOUNT AS NVARCHAR(10));

SET IMPLICIT_TRANSACTIONS OFF;  -- Reset
PRINT '';

/*
 * PART 7: LONG-RUNNING TRANSACTIONS
 */

PRINT 'PART 7: Long-Running Transaction Issues';
PRINT '-----------------------------------------';

PRINT 'Problems with long transactions:';
PRINT '  - Hold locks for extended periods';
PRINT '  - Block other users';
PRINT '  - Grow transaction log';
PRINT '  - Increase deadlock probability';
PRINT '  - Complicate backup/recovery';
PRINT '';

-- Demonstrate lock duration
BEGIN TRANSACTION;
    
    UPDATE Books 
    SET Price = Price * 1.01 
    WHERE BookID = 1;
    
    PRINT 'Updated book 1 (locks held)';
    PRINT 'Other sessions trying to read/update will BLOCK';
    PRINT '';
    
    -- In production, avoid delays in transactions!
    -- WAITFOR DELAY '00:00:05';  -- Simulates long process
    
    PRINT 'Best practice: Keep transactions SHORT';
    
COMMIT TRANSACTION;

PRINT '';
PRINT 'Guidelines:';
PRINT '  ✓ Keep transactions as short as possible';
PRINT '  ✓ Avoid user interaction during transaction';
PRINT '  ✓ Don''t include SELECT statements unnecessarily';
PRINT '  ✓ Access objects in same order to avoid deadlocks';
PRINT '  ✓ Use lowest isolation level that meets requirements';
PRINT '';

/*
 * PART 8: TRANSACTION MONITORING
 */

PRINT 'PART 8: Monitoring Active Transactions';
PRINT '----------------------------------------';

-- View current transaction information
SELECT 
    @@TRANCOUNT AS CurrentTranCount,
    XACT_STATE() AS CurrentXactState;

PRINT '';

-- View all active transactions
SELECT 
    tst.transaction_id,
    tst.name AS TransactionName,
    tst.transaction_begin_time AS BeginTime,
    DATEDIFF(SECOND, tst.transaction_begin_time, GETDATE()) AS DurationSeconds,
    tst.transaction_type AS Type,
    CASE tst.transaction_state
        WHEN 0 THEN 'Initializing'
        WHEN 1 THEN 'Initialized'
        WHEN 2 THEN 'Active'
        WHEN 3 THEN 'Ended (Read-Only)'
        WHEN 4 THEN 'Commit initiated'
        WHEN 5 THEN 'Prepared'
        WHEN 6 THEN 'Committed'
        WHEN 7 THEN 'Rolling back'
        WHEN 8 THEN 'Rolled back'
    END AS State,
    session_id AS SPID
FROM sys.dm_tran_active_transactions tst
LEFT JOIN sys.dm_tran_session_transactions sst 
    ON tst.transaction_id = sst.transaction_id
WHERE session_id = @@SPID OR session_id IS NULL;

PRINT '';

-- Find long-running transactions
PRINT 'Query to find long-running transactions (>30 seconds):';
PRINT '';
PRINT 'SELECT ';
PRINT '    tst.transaction_id,';
PRINT '    DATEDIFF(SECOND, tst.transaction_begin_time, GETDATE()) AS Duration,';
PRINT '    sst.session_id,';
PRINT '    txt.text AS SQLText';
PRINT 'FROM sys.dm_tran_active_transactions tst';
PRINT 'INNER JOIN sys.dm_tran_session_transactions sst ';
PRINT '    ON tst.transaction_id = sst.transaction_id';
PRINT 'CROSS APPLY sys.dm_exec_sql_text(conn.most_recent_sql_handle) txt';
PRINT 'WHERE DATEDIFF(SECOND, tst.transaction_begin_time, GETDATE()) > 30;';
PRINT '';

/*
 * PART 9: DISTRIBUTED TRANSACTIONS
 */

PRINT 'PART 9: Distributed Transactions';
PRINT '----------------------------------';
PRINT '';
PRINT 'Distributed transactions span multiple databases/servers:';
PRINT '';
PRINT 'BEGIN DISTRIBUTED TRANSACTION;';
PRINT '    -- Operations on Database1';
PRINT '    INSERT INTO Database1.dbo.Table1 VALUES (...);';
PRINT '    ';
PRINT '    -- Operations on Database2 (different server)';
PRINT '    INSERT INTO Database2.dbo.Table2 VALUES (...);';
PRINT '    ';
PRINT 'COMMIT TRANSACTION;';
PRINT '';
PRINT 'Requirements:';
PRINT '  - MS DTC (Distributed Transaction Coordinator) service';
PRINT '  - Linked servers configured';
PRINT '  - Network connectivity';
PRINT '  - Two-phase commit protocol';
PRINT '';
PRINT 'Considerations:';
PRINT '  - Slower than local transactions';
PRINT '  - More complex error handling';
PRINT '  - Network failures can leave in-doubt transactions';
PRINT '  - Avoid when possible (use queuing instead)';
PRINT '';

/*
 * PART 10: BEST PRACTICES
 */

PRINT 'PART 10: Transaction Best Practices';
PRINT '-------------------------------------';
PRINT '';
PRINT 'DO:';
PRINT '  ✓ Keep transactions SHORT';
PRINT '  ✓ Access objects in consistent order';
PRINT '  ✓ Use TRY/CATCH for error handling';
PRINT '  ✓ Check @@TRANCOUNT before ROLLBACK';
PRINT '  ✓ Use XACT_STATE() to check committability';
PRINT '  ✓ Set XACT_ABORT ON for safety';
PRINT '  ✓ Explicitly COMMIT or ROLLBACK';
PRINT '';
PRINT 'DON''T:';
PRINT '  ✗ Leave transactions open';
PRINT '  ✗ Include user interaction in transaction';
PRINT '  ✗ Perform slow operations (file I/O, web calls)';
PRINT '  ✗ Use SELECT unnecessarily in transaction';
PRINT '  ✗ Hold locks longer than needed';
PRINT '  ✗ Nest transactions (not truly supported)';
PRINT '';
PRINT 'PATTERN: Safe transaction procedure';
PRINT '';
PRINT 'CREATE PROCEDURE usp_SafeTransaction';
PRINT 'AS';
PRINT 'BEGIN';
PRINT '    SET NOCOUNT ON;';
PRINT '    SET XACT_ABORT ON;';
PRINT '    ';
PRINT '    BEGIN TRANSACTION;';
PRINT '    ';
PRINT '    BEGIN TRY';
PRINT '        -- Operations here';
PRINT '        ';
PRINT '        IF XACT_STATE() = 1';
PRINT '            COMMIT TRANSACTION;';
PRINT '    END TRY';
PRINT '    BEGIN CATCH';
PRINT '        IF XACT_STATE() <> 0';
PRINT '            ROLLBACK TRANSACTION;';
PRINT '        ';
PRINT '        -- Log error';
PRINT '        THROW;';
PRINT '    END CATCH;';
PRINT 'END;';
PRINT '';
PRINT 'PERFORMANCE TIPS:';
PRINT '  - Batch large operations (commit every N rows)';
PRINT '  - Use appropriate isolation level';
PRINT '  - Consider NOLOCK hint for read-only queries';
PRINT '  - Monitor transaction log size';
PRINT '  - Analyze blocking with DMVs';
PRINT '';
PRINT 'TROUBLESHOOTING:';
PRINT '  - Check sys.dm_tran_active_transactions';
PRINT '  - Use sp_who2 to find blocking';
PRINT '  - Monitor transaction log with DBCC SQLPERF(LOGSPACE)';
PRINT '  - Review error log for deadlocks';
PRINT '';

-- Transaction statistics
SELECT 
    'Transaction Summary' AS Report,
    @@TRANCOUNT AS CurrentTranCount,
    XACT_STATE() AS CurrentXactState,
    CASE 
        WHEN @@OPTIONS & 2 = 2 THEN 'ON' 
        ELSE 'OFF' 
    END AS ImplicitTransactions,
    CASE 
        WHEN @@OPTIONS & 16384 = 16384 THEN 'ON' 
        ELSE 'OFF' 
    END AS XactAbort;

PRINT '';

/*
 * EXERCISES:
 * 
 * 1. Create procedure with proper transaction handling
 * 2. Implement retry logic for transaction deadlocks
 * 3. Build transaction auditing system (log start/commit/rollback)
 * 4. Create procedure that safely handles nested transaction calls
 * 5. Implement long-running transaction monitoring and alerts
 * 
 * CHALLENGE:
 * Build enterprise transaction management framework:
 * - TransactionLog table (ID, begin_time, commit_time, duration, status)
 * - usp_BeginManagedTransaction (returns transaction ID, logs start)
 * - usp_CommitManagedTransaction (logs commit, tracks duration)
 * - usp_RollbackManagedTransaction (logs rollback with reason)
 * - Automatic monitoring of transactions >30 seconds
 * - Alert system for uncommitted transactions
 * - Transaction performance analytics
 * - Deadlock detection and automatic retry (max 3 attempts)
 * - Integration with application logging
 * - Transaction dependency graph (which transactions block which)
 */

PRINT '✓ Lab 48 Complete: Transaction fundamentals mastered';
GO
