/*
 * Lab 27: Row-Level Security (RLS)
 * Module 04: Database Administration
 * 
 * Objective: Implement fine-grained access control using Row-Level Security
 * Duration: 2-3 hours
 * Difficulty: ⭐⭐⭐⭐⭐
 */

USE master;
GO

PRINT '==============================================';
PRINT 'Lab 27: Row-Level Security (RLS)';
PRINT '==============================================';
PRINT '';

/*
 * ROW-LEVEL SECURITY (RLS):
 * 
 * Allows you to control access to rows in a table based on:
 * - User identity
 * - User role membership
 * - Execution context
 * - Custom application logic
 * 
 * Two types of predicates:
 * 1. FILTER PREDICATE: Silently filters rows on SELECT/UPDATE/DELETE
 * 2. BLOCK PREDICATE: Explicitly blocks INSERT/UPDATE/DELETE operations
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
 * PART 1: PREPARE DATA FOR RLS DEMO
 */

PRINT 'PART 1: Preparing Multi-Tenant Data';
PRINT '-------------------------------------';

-- Add TenantID column to Orders
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Orders') AND name = 'TenantID')
BEGIN
    ALTER TABLE Orders ADD TenantID INT NOT NULL DEFAULT 1;
    PRINT '✓ Added TenantID column to Orders';
END;

-- Add SalesRegion column to Orders
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Orders') AND name = 'SalesRegion')
BEGIN
    ALTER TABLE Orders ADD SalesRegion NVARCHAR(50) NULL;
    UPDATE Orders SET SalesRegion = CASE 
        WHEN OrderID % 3 = 0 THEN 'West'
        WHEN OrderID % 3 = 1 THEN 'East'
        ELSE 'Central'
    END;
    PRINT '✓ Added SalesRegion column to Orders';
END;

-- Update existing orders with different tenants
UPDATE Orders SET TenantID = 1 WHERE OrderID % 3 = 0;
UPDATE Orders SET TenantID = 2 WHERE OrderID % 3 = 1;
UPDATE Orders SET TenantID = 3 WHERE OrderID % 3 = 2;

PRINT '✓ Updated orders with tenant assignments';
PRINT '';

-- View data distribution
SELECT 
    TenantID,
    SalesRegion,
    COUNT(*) AS OrderCount
FROM Orders
GROUP BY TenantID, SalesRegion
ORDER BY TenantID, SalesRegion;

PRINT '';

/*
 * PART 2: CREATE USERS FOR RLS TESTING
 */

PRINT 'PART 2: Creating Test Users';
PRINT '----------------------------';

-- Create logins and users for different tenants
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'tenant1_user')
BEGIN
    CREATE LOGIN tenant1_user WITH PASSWORD = 'Tenant1@2024!';
END;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'tenant1_user')
BEGIN
    CREATE USER tenant1_user FOR LOGIN tenant1_user;
    GRANT SELECT, INSERT, UPDATE, DELETE ON Orders TO tenant1_user;
    PRINT '✓ Created tenant1_user';
END;

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'tenant2_user')
BEGIN
    CREATE LOGIN tenant2_user WITH PASSWORD = 'Tenant2@2024!';
END;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'tenant2_user')
BEGIN
    CREATE USER tenant2_user FOR LOGIN tenant2_user;
    GRANT SELECT, INSERT, UPDATE, DELETE ON Orders TO tenant2_user;
    PRINT '✓ Created tenant2_user';
END;

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'region_west_user')
BEGIN
    CREATE LOGIN region_west_user WITH PASSWORD = 'West@2024!';
END;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'region_west_user')
BEGIN
    CREATE USER region_west_user FOR LOGIN region_west_user;
    GRANT SELECT, INSERT, UPDATE ON Orders TO region_west_user;
    PRINT '✓ Created region_west_user';
END;

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'manager_user')
BEGIN
    CREATE LOGIN manager_user WITH PASSWORD = 'Manager@2024!';
END;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'manager_user')
BEGIN
    CREATE USER manager_user FOR LOGIN manager_user;
    GRANT SELECT ON Orders TO manager_user;
    ALTER ROLE db_datareader ADD MEMBER manager_user;  -- Can see all data
    PRINT '✓ Created manager_user (can see all tenants)';
END;

PRINT '';

/*
 * PART 3: CREATE SECURITY PREDICATE FUNCTION (Multi-Tenant)
 */

PRINT 'PART 3: Creating Security Predicate Function';
PRINT '----------------------------------------------';

-- Create schema for RLS functions
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Security')
BEGIN
    CREATE SCHEMA Security;
    PRINT '✓ Created Security schema';
END;
GO

-- Predicate function for tenant isolation
CREATE OR ALTER FUNCTION Security.fn_TenantAccessPredicate(@TenantID INT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
    SELECT 1 AS AccessResult
    WHERE 
        -- Managers can see all tenants
        IS_MEMBER('db_datareader') = 1
        -- Or user matches the tenant
        OR @TenantID = CAST(SESSION_CONTEXT(N'TenantID') AS INT)
        -- Or user is the specific tenant user
        OR (@TenantID = 1 AND USER_NAME() = 'tenant1_user')
        OR (@TenantID = 2 AND USER_NAME() = 'tenant2_user')
        -- Or user is db_owner
        OR IS_MEMBER('db_owner') = 1;
GO

PRINT '✓ Created tenant access predicate function';
PRINT '';

/*
 * PART 4: CREATE SECURITY POLICY (Apply RLS)
 */

PRINT 'PART 4: Creating Security Policy';
PRINT '----------------------------------';

-- Drop existing policy if exists
IF EXISTS (SELECT * FROM sys.security_policies WHERE name = 'TenantSecurityPolicy')
BEGIN
    DROP SECURITY POLICY TenantSecurityPolicy;
END;

-- Create security policy with FILTER predicate
CREATE SECURITY POLICY TenantSecurityPolicy
ADD FILTER PREDICATE Security.fn_TenantAccessPredicate(TenantID)
    ON dbo.Orders
WITH (STATE = ON);  -- Enable immediately

PRINT '✓ Created and enabled TenantSecurityPolicy';
PRINT '  - FILTER predicate applied to Orders table';
PRINT '  - Users can only see their tenant data';
PRINT '';

/*
 * PART 5: TEST RLS - FILTER PREDICATE
 */

PRINT 'PART 5: Testing RLS Filter Predicate';
PRINT '--------------------------------------';

-- Test as tenant1_user (should see only TenantID = 1)
PRINT 'Executing as tenant1_user:';
EXECUTE AS USER = 'tenant1_user';

SELECT 
    OrderID, 
    CustomerID, 
    TenantID, 
    SalesRegion,
    OrderDate,
    TotalAmount
FROM Orders
ORDER BY OrderID;

PRINT '(tenant1_user sees only TenantID = 1 orders)';
PRINT '';

REVERT;

-- Test as tenant2_user (should see only TenantID = 2)
PRINT 'Executing as tenant2_user:';
EXECUTE AS USER = 'tenant2_user';

SELECT 
    OrderID, 
    TenantID, 
    COUNT(*) AS RowsSeen
FROM Orders
GROUP BY OrderID, TenantID;

PRINT '(tenant2_user sees only TenantID = 2 orders)';
PRINT '';

REVERT;

-- Test as manager (should see all)
PRINT 'Executing as manager_user:';
EXECUTE AS USER = 'manager_user';

SELECT 
    TenantID,
    COUNT(*) AS OrderCount
FROM Orders
GROUP BY TenantID
ORDER BY TenantID;

PRINT '(manager_user sees all tenants)';
PRINT '';

REVERT;

/*
 * PART 6: ADD BLOCK PREDICATE (Prevent Cross-Tenant Updates)
 */

PRINT 'PART 6: Adding Block Predicate';
PRINT '--------------------------------';

-- Create block predicate function
CREATE OR ALTER FUNCTION Security.fn_TenantWriteCheck(@TenantID INT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
    SELECT 1 AS WriteAllowed
    WHERE 
        -- Can only write to own tenant
        @TenantID = CAST(SESSION_CONTEXT(N'TenantID') AS INT)
        OR (@TenantID = 1 AND USER_NAME() = 'tenant1_user')
        OR (@TenantID = 2 AND USER_NAME() = 'tenant2_user')
        -- Managers can write to all
        OR IS_MEMBER('db_owner') = 1;
GO

-- Add BLOCK predicate to existing policy
ALTER SECURITY POLICY TenantSecurityPolicy
ADD BLOCK PREDICATE Security.fn_TenantWriteCheck(TenantID)
    ON dbo.Orders AFTER INSERT,
ADD BLOCK PREDICATE Security.fn_TenantWriteCheck(TenantID)
    ON dbo.Orders AFTER UPDATE;

PRINT '✓ Added BLOCK predicates for INSERT and UPDATE';
PRINT '  - Prevents cross-tenant data manipulation';
PRINT '';

/*
 * PART 7: TEST RLS - BLOCK PREDICATE
 */

PRINT 'PART 7: Testing RLS Block Predicate';
PRINT '-------------------------------------';

-- Try to update another tenant's data (should fail)
PRINT 'Attempting to update Tenant 2 order as tenant1_user:';
EXECUTE AS USER = 'tenant1_user';

BEGIN TRY
    UPDATE Orders 
    SET TotalAmount = 999.99 
    WHERE TenantID = 2;  -- Trying to update different tenant
    
    PRINT '✗ ERROR: Update should have been blocked!';
END TRY
BEGIN CATCH
    PRINT '✓ Update blocked by RLS (expected behavior)';
    PRINT '  Error: ' + ERROR_MESSAGE();
END CATCH;

REVERT;
PRINT '';

/*
 * PART 8: REGION-BASED SECURITY POLICY
 */

PRINT 'PART 8: Creating Region-Based Security';
PRINT '----------------------------------------';

-- Create predicate for regional access
CREATE OR ALTER FUNCTION Security.fn_RegionAccessPredicate(@SalesRegion NVARCHAR(50))
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
    SELECT 1 AS AccessResult
    WHERE 
        -- West region users see only West
        (@SalesRegion = 'West' AND USER_NAME() = 'region_west_user')
        -- Managers see all regions
        OR IS_MEMBER('db_datareader') = 1
        OR IS_MEMBER('db_owner') = 1;
GO

-- Create separate security policy for regions
CREATE OR ALTER SECURITY POLICY RegionSecurityPolicy
ADD FILTER PREDICATE Security.fn_RegionAccessPredicate(SalesRegion)
    ON dbo.Orders
WITH (STATE = OFF);  -- Keep disabled for now (already have tenant policy)

PRINT '✓ Created RegionSecurityPolicy (currently disabled)';
PRINT '  Note: Multiple policies can coexist but may impact performance';
PRINT '';

/*
 * PART 9: SESSION CONTEXT (Application-Controlled RLS)
 */

PRINT 'PART 9: Using SESSION_CONTEXT for Dynamic RLS';
PRINT '-----------------------------------------------';

-- Applications can set session context
EXEC sp_set_session_context @key = N'TenantID', @value = 1;
PRINT '✓ Set session context: TenantID = 1';

-- Create predicate that uses session context
CREATE OR ALTER FUNCTION Security.fn_SessionContextPredicate(@TenantID INT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
    SELECT 1 AS AccessResult
    WHERE 
        @TenantID = CAST(SESSION_CONTEXT(N'TenantID') AS INT)
        OR CAST(SESSION_CONTEXT(N'TenantID') AS INT) IS NULL  -- If not set, allow (for admins)
        OR IS_MEMBER('db_owner') = 1;
GO

PRINT '✓ Created session context predicate';
PRINT '';

PRINT 'Application usage:';
PRINT '  -- User logs in to web app';
PRINT '  EXEC sp_set_session_context @key = N''TenantID'', @value = <UserTenantID>';
PRINT '  -- All subsequent queries automatically filtered';
PRINT '';

/*
 * PART 10: PERFORMANCE CONSIDERATIONS
 */

PRINT 'PART 10: RLS Performance Optimization';
PRINT '---------------------------------------';

-- RLS predicates should be indexed for performance
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Orders_TenantID')
BEGIN
    CREATE NONCLUSTERED INDEX IX_Orders_TenantID
    ON Orders(TenantID)
    INCLUDE (OrderID, CustomerID, OrderDate, TotalAmount);
    
    PRINT '✓ Created index on TenantID for RLS performance';
END;

-- View execution plan to verify index usage
PRINT '';
PRINT 'Always check execution plans for RLS queries:';
PRINT '  SET STATISTICS IO ON;';
PRINT '  SET SHOWPLAN_XML ON;';
PRINT '';

-- Query to find RLS policies
SELECT 
    OBJECT_NAME(p.object_id) AS TableName,
    p.name AS PolicyName,
    CASE p.type
        WHEN 1 THEN 'FILTER'
        WHEN 2 THEN 'BLOCK'
    END AS PredicateType,
    p.is_enabled,
    p.create_date,
    OBJECT_NAME(c.predicate_definition) AS PredicateFunction
FROM sys.security_policies p
LEFT JOIN sys.security_predicates c ON p.object_id = c.object_id
ORDER BY TableName, PolicyName;

PRINT '';

/*
 * PART 11: RLS BEST PRACTICES
 */

PRINT 'PART 11: RLS Best Practices';
PRINT '----------------------------';
PRINT '';
PRINT '✓ DESIGN:';
PRINT '  - Use SCHEMABINDING on predicate functions';
PRINT '  - Keep predicates simple and fast';
PRINT '  - Test thoroughly before production';
PRINT '';
PRINT '✓ PERFORMANCE:';
PRINT '  - Index columns used in predicates';
PRINT '  - Avoid complex joins in predicates';
PRINT '  - Monitor query performance';
PRINT '';
PRINT '✓ SECURITY:';
PRINT '  - RLS is transparent to users (can''t be bypassed)';
PRINT '  - Applies to all SELECT, INSERT, UPDATE, DELETE';
PRINT '  - Does NOT apply to table owners (dbo schema)';
PRINT '  - Use DENY permissions in addition to RLS for defense in depth';
PRINT '';
PRINT '✓ MAINTENANCE:';
PRINT '  - Document RLS policies clearly';
PRINT '  - Test policy changes in non-production first';
PRINT '  - Disable policy temporarily: ALTER SECURITY POLICY ... WITH (STATE = OFF)';
PRINT '';

/*
 * PART 12: TROUBLESHOOTING RLS
 */

PRINT 'PART 12: Troubleshooting RLS';
PRINT '-----------------------------';

-- View all security policies
SELECT 
    sp.name AS PolicyName,
    OBJECT_NAME(sp.object_id) AS AppliedTo,
    sp.is_enabled AS IsEnabled,
    sp.create_date,
    sp.modify_date
FROM sys.security_policies sp;

PRINT '';

-- View all predicates
SELECT 
    OBJECT_NAME(sp.object_id) AS PolicyName,
    OBJECT_NAME(sp_pred.target_object_id) AS TargetTable,
    CASE sp_pred.operation
        WHEN 1 THEN 'AFTER INSERT'
        WHEN 2 THEN 'AFTER UPDATE'
        WHEN 3 THEN 'BEFORE UPDATE'
        WHEN 4 THEN 'BEFORE DELETE'
        WHEN 5 THEN 'AFTER DELETE'
    END AS Operation,
    OBJECT_NAME(sp_pred.predicate_definition) AS PredicateFunction
FROM sys.security_policies sp
INNER JOIN sys.security_predicates sp_pred ON sp.object_id = sp_pred.object_id;

PRINT '';

/*
 * CLEANUP (commented - uncomment to remove RLS)
 */
/*
-- Disable and drop security policies
DROP SECURITY POLICY IF EXISTS TenantSecurityPolicy;
DROP SECURITY POLICY IF EXISTS RegionSecurityPolicy;

-- Drop functions
DROP FUNCTION IF EXISTS Security.fn_TenantAccessPredicate;
DROP FUNCTION IF EXISTS Security.fn_TenantWriteCheck;
DROP FUNCTION IF EXISTS Security.fn_RegionAccessPredicate;
DROP FUNCTION IF EXISTS Security.fn_SessionContextPredicate;

PRINT 'RLS policies and functions removed';
*/

/*
 * EXERCISES:
 * 
 * 1. Implement RLS for a healthcare database (HIPAA compliance - patients can only see own records)
 * 2. Create time-based RLS (data visible only during business hours)
 * 3. Implement department-based RLS (HR sees HR data, Sales sees Sales data)
 * 4. Build hierarchical RLS (managers see their team's data)
 * 5. Combine RLS with Dynamic Data Masking for comprehensive security
 * 
 * CHALLENGE:
 * Design a complete multi-tenant SaaS application security model:
 * - Tenant isolation using RLS
 * - User roles within tenants
 * - Audit logging of all data access
 * - Performance optimization for 1000+ tenants
 * - Compliance reporting (prove tenant isolation)
 */

PRINT '✓ Lab 27 Complete: Row-Level Security implemented';
PRINT '';
PRINT 'Key RLS Concepts:';
PRINT '  - FILTER PREDICATE: Silently filters rows (SELECT/UPDATE/DELETE)';
PRINT '  - BLOCK PREDICATE: Explicitly blocks operations (INSERT/UPDATE)';
PRINT '  - Predicates are inline table-valued functions';
PRINT '  - Multiple policies can apply to same table';
PRINT '  - Always test performance with realistic data volumes';
GO
