/*
================================================================================
LAB 24 (ENHANCED): TRANSACTIONS AND ISOLATION LEVELS - COMPLETE GUIDE
Module 04: Database Administration
================================================================================

WHAT YOU WILL LEARN:
✅ What transactions are and ACID properties
✅ How to use BEGIN, COMMIT, ROLLBACK
✅ Savepoints for partial rollback
✅ Transaction isolation levels explained
✅ Concurrency problems and solutions
✅ Deadlocks and how to handle them
✅ Best practices for transaction management
✅ Interview preparation

DURATION: 2-3 hours
DIFFICULTY: ⭐⭐⭐⭐ (Advanced)
DATABASE: AdventureWorks2022

================================================================================
SECTION 1: WHAT IS A TRANSACTION?
================================================================================

DEFINITION:
-----------
A transaction is a SINGLE UNIT OF WORK that either:
- COMPLETES ENTIRELY (COMMIT)
- FAILS ENTIRELY (ROLLBACK)

There is NO in-between. This is called ATOMICITY.

REAL-WORLD EXAMPLE: Bank Transfer
---------------------------------
Transfer $100 from Account A to Account B:

WITHOUT Transaction (DANGEROUS!):
Step 1: Deduct $100 from Account A    ✓ Success
Step 2: [POWER FAILURE!]              
Step 3: Add $100 to Account B         Never happens!
Result: $100 vanished! Account A lost money, B never got it.

WITH Transaction (SAFE):
BEGIN TRANSACTION
    Step 1: Deduct $100 from Account A
    Step 2: Add $100 to Account B
    [POWER FAILURE!]
    ROLLBACK automatically
Result: Both accounts unchanged. No money lost.

THE ACID PROPERTIES:
--------------------
Every transaction must guarantee ACID:

A - ATOMICITY
    All or nothing. Either ALL operations succeed, or NONE do.
    
C - CONSISTENCY
    Database moves from one valid state to another valid state.
    Constraints are enforced before and after.
    
I - ISOLATION
    Concurrent transactions don't interfere with each other.
    Each transaction sees a consistent view of data.
    
D - DURABILITY
    Once committed, changes are permanent.
    Survives power failure, crashes, etc.
*/

USE AdventureWorks2022;
GO

-- ============================================================================
-- SECTION 2: TRANSACTION BASICS - BEGIN, COMMIT, ROLLBACK
-- ============================================================================

-- Create a demo table
IF OBJECT_ID('dbo.BankAccounts', 'U') IS NOT NULL DROP TABLE dbo.BankAccounts;

CREATE TABLE dbo.BankAccounts (
    AccountID INT PRIMARY KEY,
    AccountHolder NVARCHAR(100),
    Balance DECIMAL(18,2) CHECK (Balance >= 0)  -- Can't go negative!
);

INSERT INTO dbo.BankAccounts VALUES 
(1, 'Alice', 1000.00),
(2, 'Bob', 500.00),
(3, 'Charlie', 750.00);

-- View initial state
SELECT * FROM dbo.BankAccounts;

/*
BASIC TRANSACTION SYNTAX:
-------------------------
BEGIN TRANSACTION [name]   -- Start transaction
    -- SQL statements here
COMMIT TRANSACTION         -- Save changes permanently
-- OR
ROLLBACK TRANSACTION       -- Undo all changes
*/

-- EXAMPLE 1: Successful Transaction (COMMIT)
BEGIN TRANSACTION TransferMoney
    
    -- Deduct $100 from Alice
    UPDATE dbo.BankAccounts 
    SET Balance = Balance - 100 
    WHERE AccountID = 1;
    
    -- Add $100 to Bob
    UPDATE dbo.BankAccounts 
    SET Balance = Balance + 100 
    WHERE AccountID = 2;
    
    PRINT 'Transfer successful!';
    
COMMIT TRANSACTION;

SELECT * FROM dbo.BankAccounts;
-- Alice: 900, Bob: 600

-- EXAMPLE 2: Failed Transaction (ROLLBACK)
BEGIN TRANSACTION BadTransfer
    
    -- Deduct $1000 from Charlie (will leave -250!)
    UPDATE dbo.BankAccounts 
    SET Balance = Balance - 1000 
    WHERE AccountID = 3;
    
    -- Check for error
    IF @@ERROR <> 0 OR (SELECT Balance FROM dbo.BankAccounts WHERE AccountID = 3) < 0
    BEGIN
        PRINT 'Transfer failed - insufficient funds!';
        ROLLBACK TRANSACTION;
        RETURN;
    END
    
    -- This won't execute
    UPDATE dbo.BankAccounts 
    SET Balance = Balance + 1000 
    WHERE AccountID = 1;

COMMIT TRANSACTION;

SELECT * FROM dbo.BankAccounts;
-- Charlie should still have 750 (constraint prevented the update)

-- EXAMPLE 3: Using TRY-CATCH with Transactions (BEST PRACTICE)
BEGIN TRY
    BEGIN TRANSACTION
        
        -- Attempt to transfer $200 from Alice to Bob
        UPDATE dbo.BankAccounts SET Balance = Balance - 200 WHERE AccountID = 1;
        UPDATE dbo.BankAccounts SET Balance = Balance + 200 WHERE AccountID = 2;
        
        -- Force an error for demo
        -- SELECT 1/0;  -- Uncomment to see rollback
        
        COMMIT TRANSACTION;
        PRINT 'Transaction committed successfully!';
        
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
        
    PRINT 'Error: ' + ERROR_MESSAGE();
    PRINT 'Transaction rolled back!';
END CATCH;

SELECT * FROM dbo.BankAccounts;

-- ============================================================================
-- SECTION 3: SAVEPOINTS - PARTIAL ROLLBACK
-- ============================================================================
/*
SAVEPOINTS let you rollback to a specific point without undoing everything.

Useful when:
- You have multiple operations
- Want to undo only SOME of them
- Keep earlier successful work
*/

BEGIN TRANSACTION
    
    -- First operation
    UPDATE dbo.BankAccounts SET Balance = Balance + 50 WHERE AccountID = 1;
    PRINT 'Added $50 to Alice';
    
    -- Create savepoint
    SAVE TRANSACTION SavePoint1;
    
    -- Second operation (we might want to undo this)
    UPDATE dbo.BankAccounts SET Balance = Balance - 50 WHERE AccountID = 2;
    PRINT 'Removed $50 from Bob';
    
    -- Oh no, we made a mistake! Roll back to savepoint
    ROLLBACK TRANSACTION SavePoint1;
    PRINT 'Rolled back to SavePoint1 - Bob''s deduction undone';
    
    -- Third operation (this will be kept)
    UPDATE dbo.BankAccounts SET Balance = Balance + 25 WHERE AccountID = 3;
    PRINT 'Added $25 to Charlie';
    
COMMIT TRANSACTION;
PRINT 'Transaction committed!';

SELECT * FROM dbo.BankAccounts;
-- Alice: increased, Bob: unchanged, Charlie: increased

-- ============================================================================
-- SECTION 4: TRANSACTION ISOLATION LEVELS
-- ============================================================================
/*
ISOLATION LEVELS control how transactions see each other's changes.
Higher isolation = more protection but less concurrency (slower).

SQL Server Isolation Levels (lowest to highest):
┌───────────────────────┬────────────┬──────────────┬────────────────┬───────────┐
│ Isolation Level       │ Dirty Read │ Non-Repeat   │ Phantom Read   │ Lock Type │
├───────────────────────┼────────────┼──────────────┼────────────────┼───────────┤
│ READ UNCOMMITTED      │ Possible   │ Possible     │ Possible       │ None      │
│ READ COMMITTED        │ Prevented  │ Possible     │ Possible       │ Shared    │
│ REPEATABLE READ       │ Prevented  │ Prevented    │ Possible       │ Range     │
│ SERIALIZABLE          │ Prevented  │ Prevented    │ Prevented      │ Full      │
│ SNAPSHOT              │ Prevented  │ Prevented    │ Prevented      │ Row Ver.  │
└───────────────────────┴────────────┴──────────────┴────────────────┴───────────┘

CONCURRENCY PROBLEMS EXPLAINED:
-------------------------------

1. DIRTY READ: Reading uncommitted data that might be rolled back
   Transaction A: Updates row (not committed)
   Transaction B: Reads the updated row
   Transaction A: ROLLBACK
   Result: Transaction B has data that never existed!

2. NON-REPEATABLE READ: Same row gives different values
   Transaction A: Reads row (Balance = 100)
   Transaction B: Updates row to Balance = 50, COMMITS
   Transaction A: Reads same row again (Balance = 50!)
   Result: Different values for same row in same transaction!

3. PHANTOM READ: New rows appear/disappear
   Transaction A: SELECT COUNT(*) WHERE Status = 'Active' → 10
   Transaction B: INSERT new active row, COMMITS
   Transaction A: SELECT COUNT(*) WHERE Status = 'Active' → 11
   Result: Different row count in same transaction!
*/

-- Reset demo data
UPDATE dbo.BankAccounts SET Balance = 1000 WHERE AccountID = 1;
UPDATE dbo.BankAccounts SET Balance = 500 WHERE AccountID = 2;
UPDATE dbo.BankAccounts SET Balance = 750 WHERE AccountID = 3;

-- ============================================================================
-- ISOLATION LEVEL 1: READ UNCOMMITTED (Most permissive, least safe)
-- ============================================================================
/*
READ UNCOMMITTED:
- Can read uncommitted changes (dirty reads)
- No locks acquired
- Fastest but dangerous!
- Use only for rough estimates where accuracy doesn't matter

Same as using NOLOCK hint.
*/

-- In Session 1:
BEGIN TRANSACTION
    UPDATE dbo.BankAccounts SET Balance = 9999 WHERE AccountID = 1;
    -- Don't commit yet!
    WAITFOR DELAY '00:00:10';  -- Wait 10 seconds
ROLLBACK;

-- In Session 2 (run this in parallel):
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT * FROM dbo.BankAccounts WHERE AccountID = 1;
-- Will see 9999 even though it will be rolled back! (DIRTY READ)

-- Same as using NOLOCK:
SELECT * FROM dbo.BankAccounts WITH (NOLOCK) WHERE AccountID = 1;

-- ============================================================================
-- ISOLATION LEVEL 2: READ COMMITTED (SQL Server default)
-- ============================================================================
/*
READ COMMITTED (DEFAULT):
- Can only read committed data (no dirty reads)
- Shared locks released immediately after read
- Non-repeatable reads still possible
- Good balance of safety and performance
*/

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

BEGIN TRANSACTION
    -- Read 1
    SELECT Balance FROM dbo.BankAccounts WHERE AccountID = 1;
    -- If another transaction updates and commits here...
    WAITFOR DELAY '00:00:05';
    -- Read 2 might show different value!
    SELECT Balance FROM dbo.BankAccounts WHERE AccountID = 1;
COMMIT;

-- ============================================================================
-- ISOLATION LEVEL 3: REPEATABLE READ
-- ============================================================================
/*
REPEATABLE READ:
- No dirty reads
- Same row returns same data within transaction
- Shared locks held until transaction ends
- Phantom reads still possible (new rows can appear)
*/

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

BEGIN TRANSACTION
    -- First read: 10 rows with Status = 'Active'
    SELECT COUNT(*) FROM dbo.BankAccounts WHERE Balance > 0;
    
    WAITFOR DELAY '00:00:05';
    
    -- Second read: Same rows return same values
    -- But a new row could appear! (phantom)
    SELECT COUNT(*) FROM dbo.BankAccounts WHERE Balance > 0;
COMMIT;

-- ============================================================================
-- ISOLATION LEVEL 4: SERIALIZABLE (Most restrictive)
-- ============================================================================
/*
SERIALIZABLE:
- Highest isolation level
- Range locks prevent all anomalies
- Transactions execute as if serial (one after another)
- Slowest - use sparingly!
*/

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

BEGIN TRANSACTION
    SELECT * FROM dbo.BankAccounts WHERE Balance > 500;
    -- Range lock prevents any inserts/updates/deletes in this range
    WAITFOR DELAY '00:00:05';
    SELECT * FROM dbo.BankAccounts WHERE Balance > 500;
    -- Guaranteed same results!
COMMIT;

-- Reset to default
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- ============================================================================
-- ISOLATION LEVEL 5: SNAPSHOT ISOLATION
-- ============================================================================
/*
SNAPSHOT ISOLATION:
- Uses row versioning instead of locks
- Readers don't block writers, writers don't block readers
- Each transaction sees a consistent snapshot from start
- Must be enabled at database level
*/

-- Enable snapshot isolation (one-time setup)
-- ALTER DATABASE AdventureWorks2022 SET ALLOW_SNAPSHOT_ISOLATION ON;

-- SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
-- BEGIN TRANSACTION
--     SELECT * FROM dbo.BankAccounts;
--     -- See data as of transaction start time
--     -- Other transactions can modify data
--     -- We still see the old version
-- COMMIT;

-- ============================================================================
-- SECTION 5: DEADLOCKS
-- ============================================================================
/*
DEADLOCK: Two transactions waiting for each other forever.

Example:
Transaction A: Locks Row 1, needs Row 2
Transaction B: Locks Row 2, needs Row 1

Both wait forever → DEADLOCK!

SQL Server Solution: One transaction is chosen as VICTIM and rolled back.

HOW TO PREVENT DEADLOCKS:
-------------------------
1. Access tables in same order
2. Keep transactions short
3. Avoid user interaction during transactions
4. Use lowest possible isolation level
5. Create appropriate indexes
6. Use NOLOCK where appropriate
*/

-- Example deadlock scenario (DO NOT run both at the same time on production!)

-- Session 1:
/*
BEGIN TRANSACTION
    UPDATE dbo.BankAccounts SET Balance = Balance + 100 WHERE AccountID = 1;
    WAITFOR DELAY '00:00:05';
    UPDATE dbo.BankAccounts SET Balance = Balance + 100 WHERE AccountID = 2;
COMMIT;
*/

-- Session 2:
/*
BEGIN TRANSACTION
    UPDATE dbo.BankAccounts SET Balance = Balance + 100 WHERE AccountID = 2;
    WAITFOR DELAY '00:00:05';
    UPDATE dbo.BankAccounts SET Balance = Balance + 100 WHERE AccountID = 1;
COMMIT;
*/

-- One session will get error 1205: "Transaction was deadlocked"

-- Set deadlock priority (which transaction becomes victim)
SET DEADLOCK_PRIORITY LOW;    -- More likely to be victim
SET DEADLOCK_PRIORITY NORMAL; -- Default
SET DEADLOCK_PRIORITY HIGH;   -- Less likely to be victim

-- ============================================================================
-- SECTION 6: TRANSACTION BEST PRACTICES
-- ============================================================================
/*
BEST PRACTICES:
---------------

1. KEEP TRANSACTIONS SHORT
   - Less lock contention
   - Smaller rollback
   - Better concurrency

2. ALWAYS USE TRY-CATCH
   - Proper error handling
   - Guaranteed cleanup

3. CHECK @@TRANCOUNT BEFORE ROLLBACK
   - Avoid nested transaction errors

4. AVOID USER INTERACTION IN TRANSACTIONS
   - Don't wait for user input
   - Don't send emails mid-transaction

5. USE APPROPRIATE ISOLATION LEVEL
   - Start with READ COMMITTED (default)
   - Only increase if needed

6. ACCESS OBJECTS IN CONSISTENT ORDER
   - Prevents deadlocks
   - Document the order for team

7. DON'T USE TRANSACTIONS FOR READ-ONLY
   - Unless you need specific isolation
*/

-- BEST PRACTICE TEMPLATE:
CREATE OR ALTER PROCEDURE dbo.TransferFunds
    @FromAccount INT,
    @ToAccount INT,
    @Amount DECIMAL(18,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;  -- Auto-rollback on error
    
    BEGIN TRY
        BEGIN TRANSACTION
            -- Validate
            IF @Amount <= 0
                THROW 50001, 'Amount must be positive', 1;
            
            IF NOT EXISTS (SELECT 1 FROM dbo.BankAccounts WHERE AccountID = @FromAccount AND Balance >= @Amount)
                THROW 50002, 'Insufficient funds', 1;
            
            -- Execute transfer
            UPDATE dbo.BankAccounts SET Balance = Balance - @Amount WHERE AccountID = @FromAccount;
            UPDATE dbo.BankAccounts SET Balance = Balance + @Amount WHERE AccountID = @ToAccount;
            
            -- Log the transfer (hypothetical)
            -- INSERT INTO TransferLog (FromAccount, ToAccount, Amount, TransferDate) VALUES (...);
            
        COMMIT TRANSACTION;
        
        PRINT 'Transfer completed successfully!';
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        -- Re-throw the error
        THROW;
    END CATCH
END;
GO

-- Test the procedure
EXEC dbo.TransferFunds @FromAccount = 1, @ToAccount = 2, @Amount = 100;
SELECT * FROM dbo.BankAccounts;

-- ============================================================================
-- SECTION 7: MONITORING TRANSACTIONS
-- ============================================================================

-- View active transactions
SELECT 
    t.transaction_id,
    t.name,
    t.transaction_begin_time,
    CASE t.transaction_type
        WHEN 1 THEN 'Read/Write'
        WHEN 2 THEN 'Read-Only'
        WHEN 3 THEN 'System'
        WHEN 4 THEN 'Distributed'
    END AS transaction_type,
    CASE t.transaction_state
        WHEN 0 THEN 'Not Initialized'
        WHEN 1 THEN 'Not Started'
        WHEN 2 THEN 'Active'
        WHEN 3 THEN 'Ended (Read-Only)'
        WHEN 4 THEN 'Commit Initiated'
        WHEN 5 THEN 'Prepared'
        WHEN 6 THEN 'Committed'
        WHEN 7 THEN 'Rolling Back'
        WHEN 8 THEN 'Rolled Back'
    END AS transaction_state
FROM sys.dm_tran_active_transactions t;

-- View locks held
SELECT 
    request_session_id,
    resource_type,
    resource_description,
    request_mode,
    request_status
FROM sys.dm_tran_locks
WHERE request_session_id = @@SPID;

-- ============================================================================
-- SECTION 8: INTERVIEW QUESTIONS AND ANSWERS
-- ============================================================================
/*
================================================================================
INTERVIEW FOCUS: TRANSACTIONS AND ISOLATION LEVELS
================================================================================

Q1: What is a transaction?
A1: A transaction is a single unit of work that must either complete entirely 
    (COMMIT) or fail entirely (ROLLBACK). It groups multiple operations 
    together to maintain data integrity.

Q2: What are the ACID properties?
A2: 
    Atomicity: All or nothing - complete success or complete rollback
    Consistency: Database stays valid before and after transaction
    Isolation: Concurrent transactions don't interfere with each other
    Durability: Committed changes are permanent (survive crashes)

Q3: What is a dirty read?
A3: Reading uncommitted data from another transaction that might be 
    rolled back. The data you read might never have existed!
    Prevented by: READ COMMITTED and higher isolation levels.

Q4: What is a non-repeatable read?
A4: Reading the same row twice in a transaction and getting different 
    values because another transaction modified it in between.
    Prevented by: REPEATABLE READ and higher isolation levels.

Q5: What is a phantom read?
A5: Running the same query twice in a transaction and getting different 
    rows because another transaction inserted/deleted rows matching your criteria.
    Prevented by: SERIALIZABLE or SNAPSHOT isolation.

Q6: What is the default isolation level in SQL Server?
A6: READ COMMITTED. It prevents dirty reads but allows non-repeatable 
    reads and phantom reads.

Q7: What is SERIALIZABLE isolation level?
A7: The highest isolation level. Transactions execute as if serial 
    (one after another). Uses range locks to prevent all anomalies 
    but has the most locking overhead.

Q8: What is SNAPSHOT isolation?
A8: Uses row versioning instead of locks. Each transaction sees a 
    consistent snapshot of data from when the transaction started.
    Readers don't block writers and vice versa.

Q9: What is a deadlock?
A9: When two or more transactions are waiting for each other to release 
    locks, creating a circular wait. SQL Server detects this and 
    terminates one transaction (the victim) with error 1205.

Q10: How do you prevent deadlocks?
A10: 
     - Access tables in consistent order
     - Keep transactions short
     - Use lowest necessary isolation level
     - Create appropriate indexes
     - Avoid user interaction in transactions

Q11: What is XACT_ABORT?
A11: SET XACT_ABORT ON causes the transaction to automatically rollback 
     if any statement causes an error. Without it, some errors might 
     leave the transaction in an uncommitted state.

Q12: What is a savepoint?
A12: A savepoint marks a point within a transaction that you can roll 
     back to without rolling back the entire transaction. Created with 
     SAVE TRANSACTION name.

Q13: What is @@TRANCOUNT?
A13: A system variable that returns the nesting level of transactions.
     0 = no active transaction
     1 = one transaction
     2+ = nested transactions
     
Q14: What is the difference between NOLOCK and READ UNCOMMITTED?
A14: They are functionally the same. NOLOCK is a table hint that can 
     be used on specific tables. READ UNCOMMITTED sets the isolation 
     level for the entire session/transaction.

Q15: When would you use each isolation level?
A15: 
     READ UNCOMMITTED: Quick estimates, reporting where accuracy isn't critical
     READ COMMITTED: Default, good for most OLTP operations
     REPEATABLE READ: When you need consistent reads of the same rows
     SERIALIZABLE: Financial transactions, inventory management
     SNAPSHOT: High-concurrency systems, avoiding blocking

================================================================================
*/

-- ============================================================================
-- CLEANUP
-- ============================================================================

DROP PROCEDURE IF EXISTS dbo.TransferFunds;
-- DROP TABLE IF EXISTS dbo.BankAccounts;

/*
================================================================================
LAB COMPLETION CHECKLIST
================================================================================
□ Understand transactions and ACID properties
□ Can use BEGIN, COMMIT, ROLLBACK correctly
□ Know how to use savepoints for partial rollback
□ Understand all isolation levels and when to use them
□ Can explain dirty reads, non-repeatable reads, phantom reads
□ Know how to prevent and handle deadlocks
□ Can implement proper transaction error handling with TRY-CATCH
□ Can answer interview questions confidently

NEXT LAB: Lab 25 - Backup and Recovery
================================================================================
*/
