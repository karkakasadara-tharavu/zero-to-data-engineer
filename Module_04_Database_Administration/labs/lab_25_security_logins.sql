/*
 * Lab 25: Security - Logins, Users, and Roles
 * Module 04: Database Administration
 * 
 * Objective: Implement database security with logins, users, and role-based access
 * Duration: 2-3 hours
 * Difficulty: ⭐⭐⭐⭐
 */

USE master;
GO

PRINT '==============================================';
PRINT 'Lab 25: Database Security Fundamentals';
PRINT '==============================================';
PRINT '';

/*
 * SECURITY HIERARCHY IN SQL SERVER:
 * 
 * Server Level:
 * - Logins (authentication - who you are)
 * - Server Roles (server-wide permissions)
 * 
 * Database Level:
 * - Users (mapped to logins)
 * - Database Roles (database-specific permissions)
 * - Schemas (namespace for objects)
 */

-- Ensure our demo database exists
IF DB_ID('BookstoreDB') IS NULL
BEGIN
    PRINT 'Error: BookstoreDB not found. Run Lab 20 first.';
    RETURN;
END;
GO

USE BookstoreDB;
GO

/*
 * PART 1: CREATE LOGINS (Server Level)
 */

PRINT 'PART 1: Creating Server Logins';
PRINT '--------------------------------';

-- SQL Server Authentication (username/password)
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'sales_login')
BEGIN
    CREATE LOGIN sales_login 
    WITH PASSWORD = 'StrongP@ssw0rd123!',
         DEFAULT_DATABASE = BookstoreDB,
         CHECK_POLICY = ON,        -- Enforce Windows password policy
         CHECK_EXPIRATION = ON;     -- Password expiration enabled
    PRINT '✓ Created login: sales_login';
END;

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'inventory_login')
BEGIN
    CREATE LOGIN inventory_login 
    WITH PASSWORD = 'InvMgr@2024!',
         DEFAULT_DATABASE = BookstoreDB;
    PRINT '✓ Created login: inventory_login';
END;

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'readonly_login')
BEGIN
    CREATE LOGIN readonly_login 
    WITH PASSWORD = 'Read0nly@2024!',
         DEFAULT_DATABASE = BookstoreDB;
    PRINT '✓ Created login: readonly_login';
END;

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'dba_login')
BEGIN
    CREATE LOGIN dba_login 
    WITH PASSWORD = 'DBA@Secure2024!',
         DEFAULT_DATABASE = BookstoreDB;
    PRINT '✓ Created login: dba_login';
END;

-- Windows Authentication (domain account - example only, won't work without domain)
/*
CREATE LOGIN [DOMAIN\JohnDoe] FROM WINDOWS;
*/

PRINT '';

/*
 * PART 2: CREATE DATABASE USERS
 */

USE BookstoreDB;
GO

PRINT 'PART 2: Creating Database Users';
PRINT '--------------------------------';

-- Create users mapped to logins
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'sales_user')
BEGIN
    CREATE USER sales_user FOR LOGIN sales_login;
    PRINT '✓ Created user: sales_user';
END;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'inventory_user')
BEGIN
    CREATE USER inventory_user FOR LOGIN inventory_login;
    PRINT '✓ Created user: inventory_user';
END;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'readonly_user')
BEGIN
    CREATE USER readonly_user FOR LOGIN readonly_login;
    PRINT '✓ Created user: readonly_user';
END;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'dba_user')
BEGIN
    CREATE USER dba_user FOR LOGIN dba_login;
    PRINT '✓ Created user: dba_user';
END;

PRINT '';

/*
 * PART 3: CREATE CUSTOM DATABASE ROLES
 */

PRINT 'PART 3: Creating Custom Database Roles';
PRINT '---------------------------------------';

-- Sales role (can view and create orders)
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'SalesRole' AND type = 'R')
BEGIN
    CREATE ROLE SalesRole;
    PRINT '✓ Created role: SalesRole';
END;

-- Inventory role (manage books and stock)
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'InventoryRole' AND type = 'R')
BEGIN
    CREATE ROLE InventoryRole;
    PRINT '✓ Created role: InventoryRole';
END;

-- Customer Service role (view orders, update status)
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'CustomerServiceRole' AND type = 'R')
BEGIN
    CREATE ROLE CustomerServiceRole;
    PRINT '✓ Created role: CustomerServiceRole';
END;

PRINT '';

/*
 * PART 4: GRANT PERMISSIONS TO ROLES
 */

PRINT 'PART 4: Granting Permissions to Roles';
PRINT '--------------------------------------';

-- SalesRole permissions
GRANT SELECT, INSERT ON Orders TO SalesRole;
GRANT SELECT, INSERT ON OrderDetails TO SalesRole;
GRANT SELECT ON Books TO SalesRole;
GRANT SELECT ON Customers TO SalesRole;
PRINT '✓ SalesRole: Can view books/customers, create orders';

-- InventoryRole permissions
GRANT SELECT, INSERT, UPDATE ON Books TO InventoryRole;
GRANT SELECT, INSERT, UPDATE ON Publishers TO InventoryRole;
GRANT SELECT, INSERT, UPDATE ON Authors TO InventoryRole;
GRANT SELECT, INSERT, UPDATE ON BookAuthors TO InventoryRole;
PRINT '✓ InventoryRole: Full control over books and inventory';

-- CustomerServiceRole permissions
GRANT SELECT ON Orders TO CustomerServiceRole;
GRANT SELECT ON OrderDetails TO CustomerServiceRole;
GRANT SELECT ON Customers TO CustomerServiceRole;
GRANT UPDATE (Status) ON Orders TO CustomerServiceRole;  -- Can only update Status column
PRINT '✓ CustomerServiceRole: View orders and update status';

PRINT '';

/*
 * PART 5: ADD USERS TO ROLES
 */

PRINT 'PART 5: Adding Users to Roles';
PRINT '------------------------------';

-- Add users to appropriate roles
ALTER ROLE SalesRole ADD MEMBER sales_user;
PRINT '✓ Added sales_user to SalesRole';

ALTER ROLE InventoryRole ADD MEMBER inventory_user;
PRINT '✓ Added inventory_user to InventoryRole';

-- Add readonly_user to built-in db_datareader role
ALTER ROLE db_datareader ADD MEMBER readonly_user;
PRINT '✓ Added readonly_user to db_datareader (read-only)';

-- Add dba_user to db_owner role
ALTER ROLE db_owner ADD MEMBER dba_user;
PRINT '✓ Added dba_user to db_owner (full control)';

PRINT '';

/*
 * PART 6: TEST PERMISSIONS
 */

PRINT 'PART 6: Verifying Permissions';
PRINT '------------------------------';

-- View all users and their roles
SELECT 
    dp.name AS UserName,
    dp.type_desc AS UserType,
    STRING_AGG(rp.name, ', ') AS Roles
FROM sys.database_principals dp
LEFT JOIN sys.database_role_members drm ON dp.principal_id = drm.member_principal_id
LEFT JOIN sys.database_principals rp ON drm.role_principal_id = rp.principal_id
WHERE dp.type IN ('S', 'U', 'G')  -- SQL user, Windows user, Windows group
    AND dp.name NOT LIKE '##%'     -- Exclude system accounts
GROUP BY dp.name, dp.type_desc
ORDER BY dp.name;

-- View permissions for a specific user
PRINT '';
PRINT 'Permissions for sales_user:';
SELECT 
    USER_NAME(p.grantee_principal_id) AS UserName,
    OBJECT_NAME(p.major_id) AS ObjectName,
    p.permission_name,
    p.state_desc
FROM sys.database_permissions p
WHERE USER_NAME(p.grantee_principal_id) = 'sales_user'
    OR USER_NAME(p.grantee_principal_id) IN (
        SELECT name FROM sys.database_principals 
        WHERE principal_id IN (
            SELECT role_principal_id FROM sys.database_role_members
            WHERE member_principal_id = USER_ID('sales_user')
        )
    )
ORDER BY ObjectName, permission_name;

PRINT '';

/*
 * PART 7: ROW-LEVEL SECURITY (Advanced)
 */

PRINT 'PART 7: Row-Level Security';
PRINT '---------------------------';

-- Create a security policy to limit access based on user
-- Example: Sales people can only see orders from their region

-- Add Region column to Orders (if not exists)
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Orders') AND name = 'Region')
BEGIN
    ALTER TABLE Orders ADD Region NVARCHAR(50);
    UPDATE Orders SET Region = 'West' WHERE OrderID % 2 = 0;
    UPDATE Orders SET Region = 'East' WHERE OrderID % 2 = 1;
END;

-- Create function for security predicate
CREATE OR ALTER FUNCTION dbo.fn_SecurityPredicate_Orders(@Region NVARCHAR(50))
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
    SELECT 1 AS AccessResult
    WHERE 
        IS_MEMBER('db_owner') = 1  -- DBAs can see everything
        OR IS_MEMBER('SalesRole') = 1 AND @Region = 'West'  -- Sales sees only West
        OR USER_NAME() = 'readonly_user';  -- Readonly sees everything
GO

-- Create security policy (commented - for demonstration)
/*
CREATE SECURITY POLICY OrdersSecurityPolicy
ADD FILTER PREDICATE dbo.fn_SecurityPredicate_Orders(Region)
ON dbo.Orders
WITH (STATE = ON);
*/

PRINT '✓ Row-level security function created';
PRINT '  (Policy commented out - uncomment to activate)';

PRINT '';

/*
 * PART 8: SCHEMA-LEVEL SECURITY
 */

PRINT 'PART 8: Schema-Level Security';
PRINT '------------------------------';

-- Create schemas for better organization
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Sales')
BEGIN
    CREATE SCHEMA Sales;
    PRINT '✓ Created schema: Sales';
END;

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Inventory')
BEGIN
    CREATE SCHEMA Inventory;
    PRINT '✓ Created schema: Inventory';
END;

-- Grant schema-level permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::Sales TO SalesRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::Inventory TO InventoryRole;

PRINT '✓ Granted schema-level permissions';

PRINT '';

/*
 * PART 9: DENY PERMISSIONS (Explicit Denial)
 */

PRINT 'PART 9: Deny Permissions';
PRINT '-------------------------';

-- DENY overrides GRANT
-- Example: Deny DELETE on Customers to everyone except db_owner
DENY DELETE ON Customers TO SalesRole;
DENY DELETE ON Customers TO CustomerServiceRole;
PRINT '✓ Denied DELETE on Customers to sales roles';

PRINT '';

/*
 * PART 10: AUDIT AND MONITORING
 */

PRINT 'PART 10: Security Auditing';
PRINT '---------------------------';

-- View login history
SELECT 
    login_name,
    login_time,
    host_name,
    program_name
FROM sys.dm_exec_sessions
WHERE is_user_process = 1
ORDER BY login_time DESC;

-- View current user permissions
PRINT '';
PRINT 'Current user permissions in this database:';
EXECUTE AS USER = 'sales_user';
SELECT * FROM fn_my_permissions(NULL, 'DATABASE');
REVERT;

PRINT '';

/*
 * CLEANUP (commented out - remove comment to clean up)
 */

/*
USE master;
GO

-- Remove database users
DROP USER IF EXISTS sales_user;
DROP USER IF EXISTS inventory_user;
DROP USER IF EXISTS readonly_user;
DROP USER IF EXISTS dba_user;

-- Remove server logins
DROP LOGIN IF EXISTS sales_login;
DROP LOGIN IF EXISTS inventory_login;
DROP LOGIN IF EXISTS readonly_login;
DROP LOGIN IF EXISTS dba_login;

PRINT 'Cleanup complete';
*/

/*
 * EXERCISES:
 * 
 * 1. Create a role that can only INSERT new customers but not view existing ones
 * 2. Implement column-level security (hide customer email from certain roles)
 * 3. Create a login auditing system using triggers
 * 4. Set up Dynamic Data Masking for sensitive columns
 * 5. Implement Always Encrypted for credit card data
 * 
 * CHALLENGE:
 * Design a complete security model for a healthcare database with HIPAA compliance
 */

PRINT '';
PRINT '✓ Lab 25 Complete: Database security configured';
PRINT '';
PRINT 'Summary:';
PRINT '  - Created 4 logins and users';
PRINT '  - Created 3 custom roles';
PRINT '  - Configured permissions and schemas';
PRINT '  - Implemented row-level security example';
GO
