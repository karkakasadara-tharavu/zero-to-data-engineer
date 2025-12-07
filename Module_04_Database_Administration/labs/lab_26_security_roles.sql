/*
 * Lab 26: Advanced Security - Database Roles and Permissions
 * Module 04: Database Administration
 * 
 * Objective: Implement comprehensive role-based access control (RBAC)
 * Duration: 2-3 hours
 * Difficulty: ⭐⭐⭐⭐
 */

USE master;
GO

PRINT '==============================================';
PRINT 'Lab 26: Advanced Security Roles';
PRINT '==============================================';
PRINT '';

/*
 * ROLE-BASED ACCESS CONTROL (RBAC):
 * 
 * Benefits:
 * - Simplifies permission management
 * - Enforces least privilege principle
 * - Easier to audit and maintain
 * - Separates duties
 * 
 * Role Hierarchy:
 * 1. Server Roles (sysadmin, securityadmin, etc.)
 * 2. Database Roles (db_owner, db_datareader, etc.)
 * 3. Custom Database Roles
 * 4. Application Roles (password-activated)
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
 * PART 1: BUILT-IN DATABASE ROLES
 */

PRINT 'PART 1: Built-in Database Roles';
PRINT '--------------------------------';

-- View all database roles
SELECT 
    name AS RoleName,
    type_desc AS RoleType,
    create_date,
    modify_date,
    CASE 
        WHEN is_fixed_role = 1 THEN 'Built-in'
        ELSE 'Custom'
    END AS RoleCategory
FROM sys.database_principals
WHERE type = 'R'  -- R = Role
ORDER BY is_fixed_role DESC, name;

PRINT '';
PRINT 'Built-in Database Roles:';
PRINT '  db_owner           - Full control over database';
PRINT '  db_accessadmin     - Manage user access';
PRINT '  db_securityadmin   - Manage permissions and roles';
PRINT '  db_ddladmin        - Run DDL commands (CREATE, ALTER, DROP)';
PRINT '  db_backupoperator  - Backup database';
PRINT '  db_datareader      - Read all user tables';
PRINT '  db_datawriter      - Insert/Update/Delete in all user tables';
PRINT '  db_denydatareader  - Cannot read any user tables';
PRINT '  db_denydatawriter  - Cannot modify any user tables';
PRINT '';

/*
 * PART 2: CREATE CUSTOM APPLICATION ROLES
 */

PRINT 'PART 2: Creating Custom Application Roles';
PRINT '------------------------------------------';

-- Create application-specific roles
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'WebApp_ReadOnly' AND type = 'R')
BEGIN
    CREATE ROLE WebApp_ReadOnly;
    PRINT '✓ Created role: WebApp_ReadOnly';
END;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'WebApp_OrderProcessor' AND type = 'R')
BEGIN
    CREATE ROLE WebApp_OrderProcessor;
    PRINT '✓ Created role: WebApp_OrderProcessor';
END;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'WebApp_InventoryManager' AND type = 'R')
BEGIN
    CREATE ROLE WebApp_InventoryManager;
    PRINT '✓ Created role: WebApp_InventoryManager';
END;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'WebApp_CustomerService' AND type = 'R')
BEGIN
    CREATE ROLE WebApp_CustomerService;
    PRINT '✓ Created role: WebApp_CustomerService';
END;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Analytics_ReadOnly' AND type = 'R')
BEGIN
    CREATE ROLE Analytics_ReadOnly;
    PRINT '✓ Created role: Analytics_ReadOnly';
END;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'DBA_Maintenance' AND type = 'R')
BEGIN
    CREATE ROLE DBA_Maintenance;
    PRINT '✓ Created role: DBA_Maintenance';
END;

PRINT '';

/*
 * PART 3: GRANT PERMISSIONS TO CUSTOM ROLES
 */

PRINT 'PART 3: Granting Permissions to Custom Roles';
PRINT '----------------------------------------------';

-- WebApp_ReadOnly: Can only read catalog data
GRANT SELECT ON Books TO WebApp_ReadOnly;
GRANT SELECT ON Authors TO WebApp_ReadOnly;
GRANT SELECT ON Publishers TO WebApp_ReadOnly;
GRANT SELECT ON Categories TO WebApp_ReadOnly;
GRANT SELECT ON BookAuthors TO WebApp_ReadOnly;
GRANT SELECT ON BookCategories TO WebApp_ReadOnly;
PRINT '✓ WebApp_ReadOnly: Can read catalog tables';

-- WebApp_OrderProcessor: Manage orders
GRANT SELECT, INSERT, UPDATE ON Orders TO WebApp_OrderProcessor;
GRANT SELECT, INSERT, UPDATE ON OrderDetails TO WebApp_OrderProcessor;
GRANT SELECT ON Customers TO WebApp_OrderProcessor;
GRANT SELECT ON Books TO WebApp_OrderProcessor;
GRANT UPDATE (StockQuantity) ON Books TO WebApp_OrderProcessor;  -- Column-level permission
PRINT '✓ WebApp_OrderProcessor: Can process orders and update stock';

-- WebApp_InventoryManager: Full control over inventory
GRANT SELECT, INSERT, UPDATE, DELETE ON Books TO WebApp_InventoryManager;
GRANT SELECT, INSERT, UPDATE, DELETE ON Authors TO WebApp_InventoryManager;
GRANT SELECT, INSERT, UPDATE, DELETE ON Publishers TO WebApp_InventoryManager;
GRANT SELECT, INSERT, UPDATE, DELETE ON BookAuthors TO WebApp_InventoryManager;
GRANT SELECT, INSERT, UPDATE, DELETE ON BookCategories TO WebApp_InventoryManager;
PRINT '✓ WebApp_InventoryManager: Full control over inventory tables';

-- WebApp_CustomerService: View orders and customers, update order status
GRANT SELECT ON Orders TO WebApp_CustomerService;
GRANT SELECT ON OrderDetails TO WebApp_CustomerService;
GRANT SELECT ON Customers TO WebApp_CustomerService;
GRANT SELECT ON Books TO WebApp_CustomerService;
GRANT UPDATE (Status) ON Orders TO WebApp_CustomerService;  -- Only Status column
GRANT SELECT ON Reviews TO WebApp_CustomerService;
PRINT '✓ WebApp_CustomerService: Can view data and update order status';

-- Analytics_ReadOnly: Read access to everything (for reporting)
GRANT SELECT ON SCHEMA::dbo TO Analytics_ReadOnly;
PRINT '✓ Analytics_ReadOnly: Read access to all tables';

-- DBA_Maintenance: Can run maintenance tasks
GRANT VIEW DATABASE STATE TO DBA_Maintenance;
GRANT VIEW DEFINITION TO DBA_Maintenance;
GRANT SHOWPLAN TO DBA_Maintenance;
PRINT '✓ DBA_Maintenance: Can view database state and execution plans';

PRINT '';

/*
 * PART 4: CREATE USERS AND ASSIGN TO ROLES
 */

PRINT 'PART 4: Creating Users and Role Assignments';
PRINT '--------------------------------------------';

-- Create logins and users
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'webapp_user')
BEGIN
    CREATE LOGIN webapp_user WITH PASSWORD = 'WebApp@2024!';
END;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'webapp_user')
BEGIN
    CREATE USER webapp_user FOR LOGIN webapp_user;
    ALTER ROLE WebApp_OrderProcessor ADD MEMBER webapp_user;
    PRINT '✓ Created webapp_user and assigned to WebApp_OrderProcessor';
END;

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'inventory_user')
BEGIN
    CREATE LOGIN inventory_user WITH PASSWORD = 'Inventory@2024!';
END;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'inventory_user')
BEGIN
    CREATE USER inventory_user FOR LOGIN inventory_user;
    ALTER ROLE WebApp_InventoryManager ADD MEMBER inventory_user;
    PRINT '✓ Created inventory_user and assigned to WebApp_InventoryManager';
END;

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'analyst_user')
BEGIN
    CREATE LOGIN analyst_user WITH PASSWORD = 'Analyst@2024!';
END;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'analyst_user')
BEGIN
    CREATE USER analyst_user FOR LOGIN analyst_user;
    ALTER ROLE Analytics_ReadOnly ADD MEMBER analyst_user;
    PRINT '✓ Created analyst_user and assigned to Analytics_ReadOnly';
END;

PRINT '';

/*
 * PART 5: APPLICATION ROLES (Password-Activated)
 */

PRINT 'PART 5: Application Roles (Password-Activated)';
PRINT '------------------------------------------------';

-- Application role: Activated at runtime with password
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'AppRole_SecureProcessing' AND type = 'A')
BEGIN
    CREATE APPLICATION ROLE AppRole_SecureProcessing
    WITH PASSWORD = 'AppR0le@Secure2024!',
         DEFAULT_SCHEMA = dbo;
    PRINT '✓ Created application role: AppRole_SecureProcessing';
END;

-- Grant elevated permissions to application role
GRANT SELECT, INSERT, UPDATE, DELETE ON Orders TO AppRole_SecureProcessing;
GRANT SELECT, INSERT, UPDATE, DELETE ON OrderDetails TO AppRole_SecureProcessing;
GRANT EXECUTE TO AppRole_SecureProcessing;  -- Can execute stored procedures
PRINT '✓ Granted permissions to application role';

-- Application activates the role at runtime:
/*
EXEC sp_setapprole 'AppRole_SecureProcessing', 
     @password = 'AppR0le@Secure2024!';
-- User now has application role permissions
-- Cannot be deactivated until connection closes
*/

PRINT '';
PRINT 'Application roles are activated programmatically:';
PRINT '  EXEC sp_setapprole ''RoleName'', @password = ''RolePassword''';
PRINT '  (Cannot be deactivated until connection closes)';
PRINT '';

/*
 * PART 6: NESTED ROLES (Role Hierarchy)
 */

PRINT 'PART 6: Nested Roles (Role Hierarchy)';
PRINT '--------------------------------------';

-- Create manager role that includes other roles
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Manager_Role' AND type = 'R')
BEGIN
    CREATE ROLE Manager_Role;
END;

-- Add other roles as members of Manager_Role
ALTER ROLE Manager_Role ADD MEMBER WebApp_OrderProcessor;
ALTER ROLE Manager_Role ADD MEMBER WebApp_CustomerService;
PRINT '✓ Manager_Role includes OrderProcessor and CustomerService permissions';

-- Create admin role hierarchy
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Admin_Role' AND type = 'R')
BEGIN
    CREATE ROLE Admin_Role;
END;

ALTER ROLE Admin_Role ADD MEMBER Manager_Role;
ALTER ROLE Admin_Role ADD MEMBER WebApp_InventoryManager;
PRINT '✓ Admin_Role includes Manager and InventoryManager permissions';

PRINT '';

/*
 * PART 7: DENY PERMISSIONS (Explicit Denial)
 */

PRINT 'PART 7: DENY Permissions (Overrides GRANT)';
PRINT '--------------------------------------------';

-- DENY overrides GRANT, even from role membership
-- Example: Prevent deletion of critical data

DENY DELETE ON Publishers TO WebApp_InventoryManager;
DENY DELETE ON Authors TO WebApp_InventoryManager;
PRINT '✓ Denied DELETE on Publishers and Authors (safety measure)';

-- DENY specific columns
DENY SELECT, UPDATE ON Customers (CreditCard) TO WebApp_CustomerService;
PRINT '✓ Denied access to CreditCard column for CustomerService';

PRINT '';

/*
 * PART 8: VIEW EFFECTIVE PERMISSIONS
 */

PRINT 'PART 8: Viewing Effective Permissions';
PRINT '--------------------------------------';

-- View all role memberships
SELECT 
    USER_NAME(rm.member_principal_id) AS MemberName,
    USER_NAME(rm.role_principal_id) AS RoleName,
    dp.type_desc AS MemberType
FROM sys.database_role_members rm
INNER JOIN sys.database_principals dp ON rm.member_principal_id = dp.principal_id
ORDER BY RoleName, MemberName;

PRINT '';

-- View permissions for a specific user
PRINT 'Permissions for webapp_user:';
EXECUTE AS USER = 'webapp_user';

-- Check effective permissions
SELECT * FROM fn_my_permissions(NULL, 'DATABASE');

-- Check table-specific permissions
SELECT * FROM fn_my_permissions('Orders', 'OBJECT');

REVERT;

PRINT '';

/*
 * PART 9: PERMISSION REPORTING QUERIES
 */

PRINT 'PART 9: Permission Reporting Queries';
PRINT '--------------------------------------';

-- Comprehensive permission report
SELECT 
    prin.name AS UserName,
    prin.type_desc AS UserType,
    perm.permission_name AS Permission,
    perm.state_desc AS PermissionState,
    OBJECT_NAME(perm.major_id) AS ObjectName,
    perm.class_desc AS ObjectClass
FROM sys.database_permissions perm
INNER JOIN sys.database_principals prin ON perm.grantee_principal_id = prin.principal_id
WHERE prin.type IN ('S', 'U', 'R', 'A')  -- SQL user, Windows user, Role, Application role
    AND prin.name NOT LIKE '##%'
ORDER BY prin.name, ObjectName, Permission;

PRINT '';

-- Role membership hierarchy
;WITH RoleMembers AS (
    SELECT 
        USER_NAME(member_principal_id) AS MemberName,
        USER_NAME(role_principal_id) AS RoleName,
        0 AS Level
    FROM sys.database_role_members
    WHERE USER_NAME(member_principal_id) NOT LIKE '##%'
    
    UNION ALL
    
    SELECT 
        rm.MemberName,
        USER_NAME(drm.role_principal_id) AS RoleName,
        rm.Level + 1
    FROM RoleMembers rm
    INNER JOIN sys.database_role_members drm 
        ON drm.member_principal_id = USER_ID(rm.RoleName)
    WHERE rm.Level < 10  -- Prevent infinite recursion
)
SELECT DISTINCT
    MemberName,
    RoleName,
    Level AS RoleLevel
FROM RoleMembers
ORDER BY MemberName, Level;

PRINT '';

/*
 * PART 10: SECURITY BEST PRACTICES
 */

PRINT 'PART 10: Security Best Practices';
PRINT '----------------------------------';
PRINT '';
PRINT 'PRINCIPLE OF LEAST PRIVILEGE:';
PRINT '  ✓ Grant minimum permissions needed';
PRINT '  ✓ Use roles instead of direct user permissions';
PRINT '  ✓ Regularly audit permissions';
PRINT '';
PRINT 'ROLE-BASED ACCESS CONTROL:';
PRINT '  ✓ Create roles for job functions';
PRINT '  ✓ Assign users to roles, not direct permissions';
PRINT '  ✓ Use nested roles for hierarchies';
PRINT '';
PRINT 'SEPARATION OF DUTIES:';
PRINT '  ✓ Different roles for different functions';
PRINT '  ✓ No single user should have complete control';
PRINT '  ✓ Require multiple approvals for sensitive operations';
PRINT '';
PRINT 'MONITORING AND AUDITING:';
PRINT '  ✓ Enable SQL Server Audit';
PRINT '  ✓ Track permission changes';
PRINT '  ✓ Review access logs regularly';
PRINT '  ✓ Alert on suspicious activity';
PRINT '';

/*
 * EXERCISES:
 * 
 * 1. Create a role structure for a multi-tenant application
 * 2. Implement column-level security for sensitive data (SSN, credit cards)
 * 3. Create a stored procedure to generate permission reports
 * 4. Design a role-based approval workflow (e.g., order approval)
 * 5. Implement time-based access (users active only during business hours)
 * 
 * CHALLENGE:
 * Build a complete RBAC system:
 * - Multiple role hierarchies (Sales, IT, Finance, Management)
 * - Separation of duties enforcement
 * - Permission change auditing
 * - Automated permission reviews
 * - Compliance reporting (SOX, HIPAA, GDPR)
 */

PRINT '✓ Lab 26 Complete: Advanced role-based security implemented';
PRINT '';
PRINT 'Key Concepts:';
PRINT '  - GRANT: Allows specific permissions';
PRINT '  - DENY: Explicitly prevents (overrides GRANT)';
PRINT '  - REVOKE: Removes previously granted/denied permission';
PRINT '  - Roles simplify permission management';
PRINT '  - Always follow principle of least privilege';
GO
