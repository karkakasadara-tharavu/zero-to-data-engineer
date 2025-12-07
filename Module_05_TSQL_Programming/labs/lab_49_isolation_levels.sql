/*
 * Lab 49: Isolation Levels and Concurrency
 * Module 05: T-SQL Programming
 * 
 * Objective: Master isolation levels and concurrency control
 * Duration: 90 minutes
 * Difficulty: ⭐⭐⭐⭐⭐
 */

USE BookstoreDB;
GO

PRINT '==============================================';
PRINT 'Lab 49: Isolation Levels';
PRINT '==============================================';
PRINT '';

/*
 * PART 1: ISOLATION LEVEL OVERVIEW
 */

PRINT 'PART 1: Isolation Levels Overview';
PRINT '-----------------------------------';
PRINT '';
PRINT 'SQL Server Isolation Levels:';
PRINT '';
PRINT '1. READ UNCOMMITTED (lowest)';
PRINT '   - Reads uncommitted data (dirty reads)';
PRINT '   - No shared locks';
PRINT '   - Fastest, least consistent';
PRINT '';
PRINT '2. READ COMMITTED (default)';
PRINT '   - Reads only committed data';
PRINT '   - Shared locks held during read';
PRINT '   - Released immediately after read';
PRINT '';
PRINT '3. REPEATABLE READ';
PRINT '   - Prevents non-repeatable reads';
PRINT '   - Shared locks held until transaction end';
PRINT '   - Phantom reads still possible';
PRINT '';
PRINT '4. SERIALIZABLE (highest)';
PRINT '   - Complete isolation';
PRINT '   - Range locks prevent phantoms';
PRINT '   - Slowest, most consistent';
PRINT '';
PRINT '5. SNAPSHOT';
PRINT '   - Row versioning';
PRINT '   - Readers don''t block writers';
PRINT '   - Writers don''t block readers';
PRINT '   - Requires database setting';
PRINT '';
PRINT '6. READ COMMITTED SNAPSHOT';
PRINT '   - READ COMMITTED using versioning';
PRINT '   - Statement-level consistency';
PRINT '   - Requires database setting';
PRINT '';

-- Check current isolation level
PRINT 'Current isolation level:';
SELECT CASE transaction_isolation_level
    WHEN 0 THEN 'Unspecified'
    WHEN 1 THEN 'READ UNCOMMITTED'
    WHEN 2 THEN 'READ COMMITTED'
    WHEN 3 THEN 'REPEATABLE READ'
    WHEN 4 THEN 'SERIALIZABLE'
    WHEN 5 THEN 'SNAPSHOT'
END AS IsolationLevel
FROM sys.dm_exec_sessions
WHERE session_id = @@SPID;

PRINT '';

/*
 * PART 2: READ UNCOMMITTED
 */

PRINT 'PART 2: READ UNCOMMITTED';
PRINT '-------------------------';

-- Setup test data
IF OBJECT_ID('TestAccounts', 'U') IS NOT NULL DROP TABLE TestAccounts;
CREATE TABLE TestAccounts (
    AccountID INT PRIMARY KEY,
    Balance DECIMAL(10,2)
);

INSERT INTO TestAccounts VALUES (1, 1000.00), (2, 2000.00);
PRINT '✓ Created TestAccounts';
PRINT '';

PRINT 'Demonstration: Dirty Read';
PRINT '';
PRINT 'Session 1 would execute:';
PRINT '  BEGIN TRANSACTION;';
PRINT '  UPDATE TestAccounts SET Balance = 9999 WHERE AccountID = 1;';
PRINT '  -- Don''t commit yet';
PRINT '';
PRINT 'Session 2 executes:';
PRINT '  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;';
PRINT '  SELECT Balance FROM TestAccounts WHERE AccountID = 1;';
PRINT '  -- Would see 9999 even though not committed!';
PRINT '';

-- Simulate dirty read (single session demo)
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT Balance AS 'READ UNCOMMITTED can see uncommitted changes'
FROM TestAccounts 
WHERE AccountID = 1;

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;  -- Reset
PRINT '';

PRINT 'USE CASES:';
PRINT '  ✓ Reporting queries where exact accuracy not critical';
PRINT '  ✓ Read-only queries on static data';
PRINT '  ✓ Performance-critical queries';
PRINT '';
PRINT 'RISKS:';
PRINT '  ✗ Dirty reads (uncommitted data)';
PRINT '  ✗ Non-repeatable reads';
PRINT '  ✗ Phantom reads';
PRINT '';

/*
 * PART 3: READ COMMITTED
 */

PRINT 'PART 3: READ COMMITTED (Default)';
PRINT '----------------------------------';

PRINT 'Prevents dirty reads but allows non-repeatable reads';
PRINT '';

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

BEGIN TRANSACTION;
    
    -- First read
    SELECT Balance AS FirstRead
    FROM TestAccounts 
    WHERE AccountID = 1;
    
    PRINT 'Read 1 complete. If another session updates now...';
    PRINT '';
    
    -- Simulate external update (can't actually do in same session)
    PRINT 'External session could:';
    PRINT '  UPDATE TestAccounts SET Balance = 1500 WHERE AccountID = 1;';
    PRINT '';
    
    -- Second read
    SELECT Balance AS SecondRead
    FROM TestAccounts 
    WHERE AccountID = 1;
    
    PRINT 'Read 2 might show different value (non-repeatable read)';
    
COMMIT TRANSACTION;

PRINT '';
PRINT 'CHARACTERISTICS:';
PRINT '  ✓ No dirty reads';
PRINT '  ✗ Non-repeatable reads possible';
PRINT '  ✗ Phantom reads possible';
PRINT '  ✓ Shared locks released immediately';
PRINT '';

/*
 * PART 4: REPEATABLE READ
 */

PRINT 'PART 4: REPEATABLE READ';
PRINT '------------------------';

PRINT 'Prevents non-repeatable reads but allows phantoms';
PRINT '';

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

BEGIN TRANSACTION;
    
    -- First read
    SELECT Balance AS 'First Read'
    FROM TestAccounts 
    WHERE AccountID = 1;
    
    PRINT 'Shared lock held on AccountID = 1';
    PRINT 'Other sessions CANNOT update this row until commit';
    PRINT '';
    
    PRINT 'But new rows CAN be inserted (phantoms):';
    PRINT '  INSERT INTO TestAccounts VALUES (3, 3000);';
    PRINT '';
    
    -- Second read - same value guaranteed
    SELECT Balance AS 'Second Read (same value)'
    FROM TestAccounts 
    WHERE AccountID = 1;
    
    -- Count might change (phantom)
    SELECT COUNT(*) AS 'Count (might include phantom)'
    FROM TestAccounts;
    
COMMIT TRANSACTION;

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;  -- Reset
PRINT '';

PRINT 'CHARACTERISTICS:';
PRINT '  ✓ No dirty reads';
PRINT '  ✓ No non-repeatable reads';
PRINT '  ✗ Phantom reads possible';
PRINT '  - Shared locks held until commit';
PRINT '';

/*
 * PART 5: SERIALIZABLE
 */

PRINT 'PART 5: SERIALIZABLE';
PRINT '---------------------';

PRINT 'Highest isolation - prevents all anomalies';
PRINT '';

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

BEGIN TRANSACTION;
    
    SELECT COUNT(*) AS AccountCount
    FROM TestAccounts;
    
    PRINT 'Range lock on entire table';
    PRINT 'Other sessions CANNOT:';
    PRINT '  - Update any row';
    PRINT '  - Delete any row';
    PRINT '  - Insert new rows';
    PRINT '';
    PRINT 'Until this transaction commits';
    
    -- Read again - guaranteed same count
    SELECT COUNT(*) AS 'Same Count'
    FROM TestAccounts;
    
COMMIT TRANSACTION;

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;  -- Reset
PRINT '';

PRINT 'CHARACTERISTICS:';
PRINT '  ✓ No dirty reads';
PRINT '  ✓ No non-repeatable reads';
PRINT '  ✓ No phantom reads';
PRINT '  - Highest consistency';
PRINT '  - Most blocking';
PRINT '  - Deadlock risk increases';
PRINT '';

/*
 * PART 6: SNAPSHOT ISOLATION
 */

PRINT 'PART 6: SNAPSHOT Isolation';
PRINT '----------------------------';

-- Enable snapshot isolation
PRINT 'Enabling SNAPSHOT isolation on database...';

-- Check if already enabled
DECLARE @SnapshotEnabled BIT = 
    (SELECT snapshot_isolation_state FROM sys.databases WHERE name = DB_NAME());

IF @SnapshotEnabled = 0
BEGIN
    -- Must have no active transactions
    ALTER DATABASE BookstoreDB SET ALLOW_SNAPSHOT_ISOLATION ON;
    PRINT '✓ SNAPSHOT isolation enabled';
END
ELSE
BEGIN
    PRINT '✓ SNAPSHOT isolation already enabled';
END;

PRINT '';
PRINT 'SNAPSHOT Isolation characteristics:';
PRINT '  - Uses row versioning in tempdb';
PRINT '  - Readers see snapshot at transaction start';
PRINT '  - Readers never block writers';
PRINT '  - Writers never block readers';
PRINT '  - Update conflicts detected';
PRINT '';

-- Demonstrate snapshot
SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

BEGIN TRANSACTION;
    
    -- Take snapshot
    SELECT Balance AS SnapshotValue
    FROM TestAccounts
    WHERE AccountID = 1;
    
    PRINT 'Snapshot taken. Balance = ' + 
          CAST((SELECT Balance FROM TestAccounts WHERE AccountID = 1) AS NVARCHAR(20));
    PRINT '';
    PRINT 'If another session updates now:';
    PRINT '  UPDATE TestAccounts SET Balance = 5000 WHERE AccountID = 1;';
    PRINT '';
    PRINT 'This transaction still sees original value:';
    
    SELECT Balance AS 'Still sees snapshot'
    FROM TestAccounts
    WHERE AccountID = 1;
    
COMMIT TRANSACTION;

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;  -- Reset
PRINT '';

/*
 * PART 7: READ COMMITTED SNAPSHOT
 */

PRINT 'PART 7: READ COMMITTED SNAPSHOT';
PRINT '---------------------------------';

PRINT 'Similar to SNAPSHOT but at statement level:';
PRINT '';

-- Check if enabled
DECLARE @RCSIEnabled BIT = 
    (SELECT is_read_committed_snapshot_on FROM sys.databases WHERE name = DB_NAME());

IF @RCSIEnabled = 0
BEGIN
    -- Enable RCSI
    PRINT 'To enable READ_COMMITTED_SNAPSHOT:';
    PRINT '  ALTER DATABASE BookstoreDB';
    PRINT '  SET READ_COMMITTED_SNAPSHOT ON;';
    PRINT '';
    PRINT 'Note: Requires exclusive database access';
    PRINT '(Not enabling in this lab to avoid access issues)';
END
ELSE
BEGIN
    PRINT '✓ READ_COMMITTED_SNAPSHOT already enabled';
    PRINT '';
    PRINT 'With RCSI, READ COMMITTED behaves like:';
    PRINT '  - Uses row versioning';
    PRINT '  - Statement-level consistency (not transaction)';
    PRINT '  - No shared locks for reads';
    PRINT '  - Better concurrency';
END;

PRINT '';
PRINT 'SNAPSHOT vs READ_COMMITTED_SNAPSHOT:';
PRINT '';
PRINT 'SNAPSHOT:';
PRINT '  - Transaction-level consistency';
PRINT '  - Must explicitly set isolation level';
PRINT '  - Consistent view for entire transaction';
PRINT '';
PRINT 'READ_COMMITTED_SNAPSHOT:';
PRINT '  - Statement-level consistency';
PRINT '  - Changes READ COMMITTED behavior';
PRINT '  - Each statement sees latest committed';
PRINT '';

/*
 * PART 8: ISOLATION LEVEL DEMONSTRATIONS
 */

PRINT 'PART 8: Concurrency Problems';
PRINT '------------------------------';

-- Demonstrate with procedures
IF OBJECT_ID('usp_SimulateDirtyRead', 'P') IS NOT NULL DROP PROCEDURE usp_SimulateDirtyRead;
GO

CREATE PROCEDURE usp_SimulateDirtyRead
AS
BEGIN
    PRINT 'DIRTY READ Example:';
    PRINT '';
    PRINT 'Session A:                    Session B:';
    PRINT '  BEGIN TRAN;                  SET ISOLATION LEVEL';
    PRINT '  UPDATE Account               READ UNCOMMITTED;';
    PRINT '  SET Balance=5000;            SELECT Balance';
    PRINT '  WHERE ID=1;                  FROM Account';
    PRINT '                               WHERE ID=1;';
    PRINT '  -- Sees 5000 (uncommitted!)';
    PRINT '  ROLLBACK; -- Oops!';
    PRINT '                               -- Read wrong value!';
END;
GO

IF OBJECT_ID('usp_SimulateNonRepeatableRead', 'P') IS NOT NULL DROP PROCEDURE usp_SimulateNonRepeatableRead;
GO

CREATE PROCEDURE usp_SimulateNonRepeatableRead
AS
BEGIN
    PRINT 'NON-REPEATABLE READ Example:';
    PRINT '';
    PRINT 'Session A:                    Session B:';
    PRINT '  BEGIN TRAN;';
    PRINT '  SELECT Balance               ';
    PRINT '  FROM Account';
    PRINT '  WHERE ID=1;';
    PRINT '  -- Sees 1000';
    PRINT '                               UPDATE Account';
    PRINT '                               SET Balance=2000';
    PRINT '                               WHERE ID=1;';
    PRINT '  SELECT Balance';
    PRINT '  FROM Account';
    PRINT '  WHERE ID=1;';
    PRINT '  -- Sees 2000 (changed!)';
    PRINT '  COMMIT;';
END;
GO

IF OBJECT_ID('usp_SimulatePhantomRead', 'P') IS NOT NULL DROP PROCEDURE usp_SimulatePhantomRead;
GO

CREATE PROCEDURE usp_SimulatePhantomRead
AS
BEGIN
    PRINT 'PHANTOM READ Example:';
    PRINT '';
    PRINT 'Session A:                    Session B:';
    PRINT '  BEGIN TRAN;';
    PRINT '  SELECT COUNT(*)';
    PRINT '  FROM Account;';
    PRINT '  -- Count = 10';
    PRINT '                               INSERT Account';
    PRINT '                               VALUES (11, 1000);';
    PRINT '  SELECT COUNT(*)';
    PRINT '  FROM Account;';
    PRINT '  -- Count = 11 (phantom!)';
    PRINT '  COMMIT;';
END;
GO

EXEC usp_SimulateDirtyRead;
PRINT '';
EXEC usp_SimulateNonRepeatableRead;
PRINT '';
EXEC usp_SimulatePhantomRead;
PRINT '';

/*
 * PART 9: LOCK COMPATIBILITY
 */

PRINT 'PART 9: Lock Types and Compatibility';
PRINT '--------------------------------------';
PRINT '';
PRINT 'Lock Types:';
PRINT '  S  = Shared (read lock)';
PRINT '  X  = Exclusive (write lock)';
PRINT '  U  = Update (intent to update)';
PRINT '  IS = Intent Shared';
PRINT '  IX = Intent Exclusive';
PRINT '';
PRINT 'Compatibility Matrix:';
PRINT '       S    X    U    IS   IX';
PRINT '  S    ✓    ✗    ✓    ✓    ✗';
PRINT '  X    ✗    ✗    ✗    ✗    ✗';
PRINT '  U    ✓    ✗    ✗    ✓    ✗';
PRINT '  IS   ✓    ✗    ✓    ✓    ✓';
PRINT '  IX   ✗    ✗    ✗    ✓    ✓';
PRINT '';
PRINT 'Lock Hints:';
PRINT '  NOLOCK       = READ UNCOMMITTED';
PRINT '  HOLDLOCK     = SERIALIZABLE';
PRINT '  UPDLOCK      = Update lock';
PRINT '  TABLOCK      = Table lock';
PRINT '  PAGLOCK      = Page lock';
PRINT '  ROWLOCK      = Row lock';
PRINT '  XLOCK        = Exclusive lock';
PRINT '';

-- View current locks
SELECT 
    resource_type,
    resource_description,
    request_mode AS LockType,
    request_status AS Status
FROM sys.dm_tran_locks
WHERE request_session_id = @@SPID;

PRINT '';

/*
 * PART 10: BEST PRACTICES
 */

PRINT 'PART 10: Isolation Level Best Practices';
PRINT '-----------------------------------------';
PRINT '';
PRINT 'CHOOSING ISOLATION LEVEL:';
PRINT '';
PRINT 'READ UNCOMMITTED:';
PRINT '  Use for: Reports, dashboards, approximate counts';
PRINT '  Avoid: Financial transactions, critical data';
PRINT '';
PRINT 'READ COMMITTED (default):';
PRINT '  Use for: Most OLTP applications';
PRINT '  Good balance: consistency vs performance';
PRINT '';
PRINT 'REPEATABLE READ:';
PRINT '  Use for: Financial calculations, multi-step processes';
PRINT '  Watch: Deadlock risk, blocking';
PRINT '';
PRINT 'SERIALIZABLE:';
PRINT '  Use for: Critical transactions requiring complete isolation';
PRINT '  Avoid: High-concurrency systems';
PRINT '';
PRINT 'SNAPSHOT:';
PRINT '  Use for: Reporting + OLTP mixed workload';
PRINT '  Consider: TempDB overhead, update conflicts';
PRINT '';
PRINT 'GUIDELINES:';
PRINT '  ✓ Use lowest level that meets requirements';
PRINT '  ✓ Consider SNAPSHOT for reporting';
PRINT '  ✓ Test under load';
PRINT '  ✓ Monitor blocking and deadlocks';
PRINT '  ✓ Use query hints sparingly';
PRINT '  ✓ Document isolation level choices';
PRINT '';
PRINT 'PERFORMANCE TIPS:';
PRINT '  - Keep transactions short';
PRINT '  - Access tables in same order';
PRINT '  - Use proper indexes';
PRINT '  - Consider READ_COMMITTED_SNAPSHOT';
PRINT '  - Monitor sys.dm_tran_locks';
PRINT '  - Use lock hints judiciously';
PRINT '';
PRINT 'MONITORING:';
PRINT '';
PRINT '-- Find blocking:';
PRINT 'SELECT blocking_session_id, wait_type, wait_time';
PRINT 'FROM sys.dm_exec_requests';
PRINT 'WHERE blocking_session_id <> 0;';
PRINT '';
PRINT '-- View lock details:';
PRINT 'SELECT resource_type, request_mode, request_status';
PRINT 'FROM sys.dm_tran_locks';
PRINT 'WHERE request_session_id = @@SPID;';
PRINT '';
PRINT '-- Deadlock graph:';
PRINT 'Enable trace flag 1222 for detailed deadlock logging';
PRINT '';

-- Isolation level comparison table
PRINT 'SUMMARY TABLE:';
PRINT '';
PRINT 'Level                Dirty  Non-Rep  Phantom  Locks       Speed';
PRINT '-------------------  -----  -------  -------  ----------  -----';
PRINT 'READ UNCOMMITTED     YES    YES      YES      None        ★★★★★';
PRINT 'READ COMMITTED       NO     YES      YES      Short       ★★★★☆';
PRINT 'REPEATABLE READ      NO     NO       YES      Long        ★★★☆☆';
PRINT 'SERIALIZABLE         NO     NO       NO       Range       ★★☆☆☆';
PRINT 'SNAPSHOT             NO     NO       NO       None*       ★★★★☆';
PRINT '';
PRINT '* Uses row versioning in tempdb';
PRINT '';

-- Check database settings
SELECT 
    'Database Snapshot Settings' AS Info,
    name AS DatabaseName,
    snapshot_isolation_state_desc AS SnapshotState,
    is_read_committed_snapshot_on AS RCSI_Enabled
FROM sys.databases
WHERE name = DB_NAME();

PRINT '';

/*
 * EXERCISES:
 * 
 * 1. Create procedure demonstrating each isolation level
 * 2. Implement deadlock detection and resolution procedure
 * 3. Build blocking chain analysis query
 * 4. Create isolation level recommendation system
 * 5. Implement automated performance testing across isolation levels
 * 
 * CHALLENGE:
 * Build concurrency testing framework:
 * - Simulate multiple concurrent users (10-100)
 * - Test each isolation level under load
 * - Measure: throughput, deadlocks, blocking time
 * - Generate comparison report
 * - Identify optimal isolation level for workload
 * - Create automated load testing harness
 * - Build deadlock reproduction environment
 * - Implement lock escalation monitoring
 * - Create visual lock dependency graph
 * - Build automatic deadlock resolution system
 */

PRINT '✓ Lab 49 Complete: Isolation levels and concurrency mastered';
PRINT '';
PRINT 'Transaction section complete!';
PRINT 'Next: Dynamic SQL Mastery (Labs 50-51) and Capstone (Lab 52)';
GO
