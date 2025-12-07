/*
 * Lab 45: Triggers - DDL Triggers
 * Module 05: T-SQL Programming
 * 
 * Objective: Master DDL triggers for schema change control
 * Duration: 75 minutes
 * Difficulty: ⭐⭐⭐⭐
 */

USE BookstoreDB;
GO

PRINT '==============================================';
PRINT 'Lab 45: DDL Triggers';
PRINT '==============================================';
PRINT '';

/*
 * PART 1: DATABASE-LEVEL DDL TRIGGER
 */

PRINT 'PART 1: Database DDL Trigger';
PRINT '------------------------------';

-- Create audit table for DDL changes
IF OBJECT_ID('DDLAuditLog', 'U') IS NOT NULL DROP TABLE DDLAuditLog;
CREATE TABLE DDLAuditLog (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    EventType NVARCHAR(100),
    ObjectName NVARCHAR(256),
    ObjectType NVARCHAR(100),
    SQLCommand NVARCHAR(MAX),
    LoginName NVARCHAR(128),
    EventDate DATETIME2 DEFAULT SYSDATETIME(),
    HostName NVARCHAR(128),
    ApplicationName NVARCHAR(128)
);

PRINT '✓ Created DDLAuditLog table';

-- Create DDL trigger for table operations
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'trg_DDL_TableAudit' AND parent_class = 0)
    DROP TRIGGER trg_DDL_TableAudit ON DATABASE;
GO

CREATE TRIGGER trg_DDL_TableAudit
ON DATABASE
FOR CREATE_TABLE, ALTER_TABLE, DROP_TABLE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @EventData XML = EVENTDATA();
    
    INSERT INTO DDLAuditLog (
        EventType,
        ObjectName,
        ObjectType,
        SQLCommand,
        LoginName,
        HostName,
        ApplicationName
    )
    VALUES (
        @EventData.value('(/EVENT_INSTANCE/EventType)[1]', 'NVARCHAR(100)'),
        @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(256)'),
        @EventData.value('(/EVENT_INSTANCE/ObjectType)[1]', 'NVARCHAR(100)'),
        @EventData.value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]', 'NVARCHAR(MAX)'),
        @EventData.value('(/EVENT_INSTANCE/LoginName)[1]', 'NVARCHAR(128)'),
        HOST_NAME(),
        APP_NAME()
    );
    
    PRINT 'DDL operation logged: ' + 
          @EventData.value('(/EVENT_INSTANCE/EventType)[1]', 'NVARCHAR(100)');
END;
GO

PRINT '✓ Created trg_DDL_TableAudit';

-- Test DDL trigger
CREATE TABLE TestTable1 (ID INT, Name NVARCHAR(50));
ALTER TABLE TestTable1 ADD Description NVARCHAR(200);
DROP TABLE TestTable1;

SELECT * FROM DDLAuditLog ORDER BY EventDate DESC;
PRINT '';

/*
 * PART 2: PREVENT DDL OPERATIONS
 */

PRINT 'PART 2: Prevent DDL Operations';
PRINT '--------------------------------';

IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'trg_DDL_PreventDrop' AND parent_class = 0)
    DROP TRIGGER trg_DDL_PreventDrop ON DATABASE;
GO

CREATE TRIGGER trg_DDL_PreventDrop
ON DATABASE
FOR DROP_TABLE, DROP_VIEW, DROP_PROCEDURE, DROP_FUNCTION
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @EventData XML = EVENTDATA();
    DECLARE @ObjectName NVARCHAR(256) = 
        @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(256)');
    
    -- Allow dropping test objects
    IF @ObjectName LIKE 'Test%'
    BEGIN
        PRINT 'DROP operation allowed for test object: ' + @ObjectName;
        RETURN;
    END;
    
    -- Prevent dropping production objects
    RAISERROR('DROP operations are not allowed on production objects. Contact DBA.', 16, 1);
    ROLLBACK;
END;
GO

PRINT '✓ Created trg_DDL_PreventDrop';

-- Test prevention
BEGIN TRY
    DROP TABLE Books; -- Should fail
END TRY
BEGIN CATCH
    PRINT 'Caught expected error: ' + ERROR_MESSAGE();
END CATCH;

-- Test allowed drop
CREATE TABLE TestTable2 (ID INT);
DROP TABLE TestTable2; -- Should succeed
PRINT '';

/*
 * PART 3: TRACK ALL DATABASE CHANGES
 */

PRINT 'PART 3: Comprehensive DDL Tracking';
PRINT '------------------------------------';

IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'trg_DDL_AllChanges' AND parent_class = 0)
    DROP TRIGGER trg_DDL_AllChanges ON DATABASE;
GO

CREATE TRIGGER trg_DDL_AllChanges
ON DATABASE
FOR DDL_DATABASE_LEVEL_EVENTS
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @EventData XML = EVENTDATA();
    
    -- Extract all relevant information
    DECLARE @EventType NVARCHAR(100) = 
        @EventData.value('(/EVENT_INSTANCE/EventType)[1]', 'NVARCHAR(100)');
    DECLARE @ObjectName NVARCHAR(256) = 
        @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(256)');
    DECLARE @SQLCommand NVARCHAR(MAX) = 
        @EventData.value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]', 'NVARCHAR(MAX)');
    
    -- Log the event
    INSERT INTO DDLAuditLog (
        EventType,
        ObjectName,
        ObjectType,
        SQLCommand,
        LoginName,
        HostName,
        ApplicationName
    )
    VALUES (
        @EventType,
        @ObjectName,
        @EventData.value('(/EVENT_INSTANCE/ObjectType)[1]', 'NVARCHAR(100)'),
        @SQLCommand,
        SUSER_SNAME(),
        HOST_NAME(),
        APP_NAME()
    );
    
    -- Alert on critical changes
    IF @EventType IN ('DROP_TABLE', 'DROP_DATABASE', 'ALTER_DATABASE')
    BEGIN
        PRINT '⚠️  CRITICAL DDL EVENT: ' + @EventType;
        PRINT '   Object: ' + ISNULL(@ObjectName, 'N/A');
        PRINT '   User: ' + SUSER_SNAME();
    END;
END;
GO

PRINT '✓ Created trg_DDL_AllChanges (comprehensive tracking)';
PRINT '';

/*
 * PART 4: SERVER-LEVEL DDL TRIGGER
 */

PRINT 'PART 4: Server-Level DDL Trigger';
PRINT '----------------------------------';
PRINT '';
PRINT 'Server-level triggers track changes across ALL databases:';
PRINT '';
PRINT '  CREATE TRIGGER trg_ServerDDL';
PRINT '  ON ALL SERVER';
PRINT '  FOR DDL_SERVER_LEVEL_EVENTS';
PRINT '  AS';
PRINT '  BEGIN';
PRINT '      -- Log to central audit database';
PRINT '      INSERT INTO AuditDB.dbo.ServerDDLLog ...';
PRINT '  END;';
PRINT '';
PRINT 'Use cases:';
PRINT '  - Track database creation/deletion';
PRINT '  - Monitor login/user changes';
PRINT '  - Audit server configuration changes';
PRINT '  - Compliance and security monitoring';
PRINT '';
PRINT 'Note: Requires ALTER ANY SERVER DDL TRIGGER permission';
PRINT '';

-- Server-level example (not executed - requires sysadmin)
/*
USE master;
GO

CREATE TRIGGER trg_Server_DatabaseChanges
ON ALL SERVER
FOR CREATE_DATABASE, ALTER_DATABASE, DROP_DATABASE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @EventData XML = EVENTDATA();
    
    -- Log to central audit table
    INSERT INTO AuditDB.dbo.ServerDDLAudit (EventData)
    VALUES (@EventData);
END;
GO
*/

/*
 * PART 5: EVENTDATA() FUNCTION DETAILS
 */

PRINT 'PART 5: EVENTDATA() Function';
PRINT '------------------------------';

IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'trg_DDL_ShowEventData' AND parent_class = 0)
    DROP TRIGGER trg_DDL_ShowEventData ON DATABASE;
GO

CREATE TRIGGER trg_DDL_ShowEventData
ON DATABASE
FOR CREATE_PROCEDURE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @EventData XML = EVENTDATA();
    
    -- Display full event data
    SELECT @EventData AS EventDataXML;
    
    -- Extract specific values
    SELECT 
        @EventData.value('(/EVENT_INSTANCE/EventType)[1]', 'NVARCHAR(100)') AS EventType,
        @EventData.value('(/EVENT_INSTANCE/PostTime)[1]', 'DATETIME2') AS PostTime,
        @EventData.value('(/EVENT_INSTANCE/SPID)[1]', 'INT') AS SPID,
        @EventData.value('(/EVENT_INSTANCE/ServerName)[1]', 'NVARCHAR(128)') AS ServerName,
        @EventData.value('(/EVENT_INSTANCE/LoginName)[1]', 'NVARCHAR(128)') AS LoginName,
        @EventData.value('(/EVENT_INSTANCE/UserName)[1]', 'NVARCHAR(128)') AS UserName,
        @EventData.value('(/EVENT_INSTANCE/DatabaseName)[1]', 'NVARCHAR(128)') AS DatabaseName,
        @EventData.value('(/EVENT_INSTANCE/SchemaName)[1]', 'NVARCHAR(128)') AS SchemaName,
        @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(256)') AS ObjectName,
        @EventData.value('(/EVENT_INSTANCE/ObjectType)[1]', 'NVARCHAR(100)') AS ObjectType,
        @EventData.value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]', 'NVARCHAR(MAX)') AS CommandText;
    
    -- Log to audit table
    INSERT INTO DDLAuditLog (EventType, ObjectName, ObjectType, SQLCommand, LoginName)
    SELECT 
        @EventData.value('(/EVENT_INSTANCE/EventType)[1]', 'NVARCHAR(100)'),
        @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(256)'),
        @EventData.value('(/EVENT_INSTANCE/ObjectType)[1]', 'NVARCHAR(100)'),
        @EventData.value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]', 'NVARCHAR(MAX)'),
        @EventData.value('(/EVENT_INSTANCE/LoginName)[1]', 'NVARCHAR(128)');
END;
GO

PRINT '✓ Created trg_DDL_ShowEventData (displays EVENTDATA details)';

-- Test to see event data
IF OBJECT_ID('usp_TestProc', 'P') IS NOT NULL DROP PROCEDURE usp_TestProc;
GO
CREATE PROCEDURE usp_TestProc AS BEGIN SELECT 1; END;
GO

PRINT '';

/*
 * PART 6: DDL TRIGGER EVENT GROUPS
 */

PRINT 'PART 6: DDL Event Groups';
PRINT '--------------------------';
PRINT '';
PRINT 'Common DDL event groups:';
PRINT '';
PRINT 'DATABASE LEVEL:';
PRINT '  DDL_DATABASE_LEVEL_EVENTS    - All database DDL';
PRINT '  DDL_TABLE_EVENTS              - CREATE/ALTER/DROP TABLE';
PRINT '  DDL_VIEW_EVENTS               - CREATE/ALTER/DROP VIEW';
PRINT '  DDL_PROCEDURE_EVENTS          - CREATE/ALTER/DROP PROCEDURE';
PRINT '  DDL_FUNCTION_EVENTS           - CREATE/ALTER/DROP FUNCTION';
PRINT '  DDL_TRIGGER_EVENTS            - CREATE/ALTER/DROP TRIGGER';
PRINT '  DDL_INDEX_EVENTS              - CREATE/ALTER/DROP INDEX';
PRINT '';
PRINT 'SERVER LEVEL:';
PRINT '  DDL_SERVER_LEVEL_EVENTS       - All server DDL';
PRINT '  DDL_DATABASE_EVENTS           - CREATE/ALTER/DROP DATABASE';
PRINT '  DDL_LOGIN_EVENTS              - CREATE/ALTER/DROP LOGIN';
PRINT '  DDL_SERVER_SECURITY_EVENTS    - Server roles, endpoints';
PRINT '';
PRINT 'Specific events:';
PRINT '  CREATE_TABLE, ALTER_TABLE, DROP_TABLE';
PRINT '  CREATE_INDEX, ALTER_INDEX, DROP_INDEX';
PRINT '  RENAME (via sp_rename)';
PRINT '  GRANT, DENY, REVOKE';
PRINT '';

-- Example: Track only specific events
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'trg_DDL_IndexChanges' AND parent_class = 0)
    DROP TRIGGER trg_DDL_IndexChanges ON DATABASE;
GO

CREATE TRIGGER trg_DDL_IndexChanges
ON DATABASE
FOR DDL_INDEX_EVENTS
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @EventData XML = EVENTDATA();
    
    INSERT INTO DDLAuditLog (EventType, ObjectName, SQLCommand, LoginName)
    VALUES (
        @EventData.value('(/EVENT_INSTANCE/EventType)[1]', 'NVARCHAR(100)'),
        @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(256)'),
        @EventData.value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]', 'NVARCHAR(MAX)'),
        SUSER_SNAME()
    );
    
    PRINT 'Index change logged';
END;
GO

PRINT '✓ Created trg_DDL_IndexChanges (specific event group)';
PRINT '';

/*
 * PART 7: DDL TRIGGER MANAGEMENT
 */

PRINT 'PART 7: Managing DDL Triggers';
PRINT '-------------------------------';

-- View all DDL triggers
SELECT 
    name AS TriggerName,
    parent_class_desc AS Scope,
    CASE is_disabled 
        WHEN 0 THEN 'Enabled' 
        ELSE 'Disabled' 
    END AS Status,
    create_date AS CreatedDate,
    modify_date AS ModifiedDate
FROM sys.triggers
WHERE parent_class = 0  -- Database level
ORDER BY name;

PRINT '';
PRINT 'DDL Trigger Commands:';
PRINT '';
PRINT '-- Disable trigger:';
PRINT '  DISABLE TRIGGER trg_DDL_TableAudit ON DATABASE;';
PRINT '';
PRINT '-- Enable trigger:';
PRINT '  ENABLE TRIGGER trg_DDL_TableAudit ON DATABASE;';
PRINT '';
PRINT '-- Drop trigger:';
PRINT '  DROP TRIGGER trg_DDL_TableAudit ON DATABASE;';
PRINT '';
PRINT '-- Get trigger definition:';
PRINT '  SELECT OBJECT_DEFINITION(OBJECT_ID(''trg_DDL_TableAudit''));';
PRINT '';

-- Demonstrate disable/enable
PRINT 'Disabling trg_DDL_PreventDrop temporarily...';
DISABLE TRIGGER trg_DDL_PreventDrop ON DATABASE;

PRINT 'Re-enabling trg_DDL_PreventDrop...';
ENABLE TRIGGER trg_DDL_PreventDrop ON DATABASE;

PRINT '';

/*
 * PART 8: DDL TRIGGERS FOR COMPLIANCE
 */

PRINT 'PART 8: Compliance and Security';
PRINT '---------------------------------';

-- Create table for security-sensitive changes
IF OBJECT_ID('SecurityAudit', 'U') IS NOT NULL DROP TABLE SecurityAudit;
CREATE TABLE SecurityAudit (
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    EventType NVARCHAR(100),
    ObjectName NVARCHAR(256),
    GranteeOrPrincipal NVARCHAR(128),
    PermissionType NVARCHAR(100),
    SQLCommand NVARCHAR(MAX),
    LoginName NVARCHAR(128),
    EventDate DATETIME2 DEFAULT SYSDATETIME()
);

IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'trg_DDL_SecurityAudit' AND parent_class = 0)
    DROP TRIGGER trg_DDL_SecurityAudit ON DATABASE;
GO

CREATE TRIGGER trg_DDL_SecurityAudit
ON DATABASE
FOR DDL_DATABASE_SECURITY_EVENTS
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @EventData XML = EVENTDATA();
    
    -- Log all security-related changes
    INSERT INTO SecurityAudit (
        EventType,
        ObjectName,
        SQLCommand,
        LoginName
    )
    VALUES (
        @EventData.value('(/EVENT_INSTANCE/EventType)[1]', 'NVARCHAR(100)'),
        @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(256)'),
        @EventData.value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]', 'NVARCHAR(MAX)'),
        @EventData.value('(/EVENT_INSTANCE/LoginName)[1]', 'NVARCHAR(128)')
    );
    
    -- Alert on sensitive changes
    PRINT '🔒 SECURITY EVENT: ' + 
          @EventData.value('(/EVENT_INSTANCE/EventType)[1]', 'NVARCHAR(100)');
    PRINT '   By: ' + @EventData.value('(/EVENT_INSTANCE/LoginName)[1]', 'NVARCHAR(128)');
END;
GO

PRINT '✓ Created trg_DDL_SecurityAudit (compliance tracking)';
PRINT '';

/*
 * PART 9: CHANGE CONTROL WORKFLOW
 */

PRINT 'PART 9: Change Control Workflow';
PRINT '---------------------------------';

-- Create change approval table
IF OBJECT_ID('ChangeApprovals', 'U') IS NOT NULL DROP TABLE ChangeApprovals;
CREATE TABLE ChangeApprovals (
    ApprovalID INT IDENTITY(1,1) PRIMARY KEY,
    ChangeType NVARCHAR(100),
    ObjectName NVARCHAR(256),
    Description NVARCHAR(1000),
    RequestedBy NVARCHAR(128),
    ApprovedBy NVARCHAR(128) NULL,
    ApprovalDate DATETIME2 NULL,
    Status NVARCHAR(20) DEFAULT 'Pending',
    SQLScript NVARCHAR(MAX)
);

PRINT '✓ Created ChangeApprovals table';

-- Trigger to enforce approval workflow
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'trg_DDL_RequireApproval' AND parent_class = 0)
    DROP TRIGGER trg_DDL_RequireApproval ON DATABASE;
GO

CREATE TRIGGER trg_DDL_RequireApproval
ON DATABASE
FOR ALTER_TABLE, DROP_TABLE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @EventData XML = EVENTDATA();
    DECLARE @ObjectName NVARCHAR(256) = 
        @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(256)');
    DECLARE @EventType NVARCHAR(100) = 
        @EventData.value('(/EVENT_INSTANCE/EventType)[1]', 'NVARCHAR(100)');
    
    -- Allow changes to test objects
    IF @ObjectName LIKE 'Test%'
    BEGIN
        RETURN;
    END;
    
    -- Check if change is approved
    IF NOT EXISTS (
        SELECT 1 FROM ChangeApprovals
        WHERE ObjectName = @ObjectName
        AND ChangeType = @EventType
        AND Status = 'Approved'
        AND ApprovalDate >= DATEADD(DAY, -7, GETDATE())  -- Approval valid for 7 days
    )
    BEGIN
        -- Log unauthorized attempt
        INSERT INTO DDLAuditLog (EventType, ObjectName, SQLCommand, LoginName)
        VALUES (
            @EventType + ' - BLOCKED',
            @ObjectName,
            @EventData.value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]', 'NVARCHAR(MAX)'),
            SUSER_SNAME()
        );
        
        RAISERROR('Change requires prior approval in ChangeApprovals table', 16, 1);
        ROLLBACK;
    END;
    
    PRINT 'Change approved and executed';
END;
GO

PRINT '✓ Created trg_DDL_RequireApproval (change control)';
PRINT '';

/*
 * PART 10: BEST PRACTICES
 */

PRINT 'PART 10: DDL Trigger Best Practices';
PRINT '-------------------------------------';
PRINT '';
PRINT 'USE CASES:';
PRINT '  ✓ Audit schema changes (compliance)';
PRINT '  ✓ Prevent unauthorized drops';
PRINT '  ✓ Enforce naming conventions';
PRINT '  ✓ Change control workflow';
PRINT '  ✓ Security monitoring';
PRINT '  ✓ Documentation automation';
PRINT '';
PRINT 'BEST PRACTICES:';
PRINT '  - Keep logic simple and fast';
PRINT '  - Log events, don''t block unnecessarily';
PRINT '  - Use specific event groups (not all events)';
PRINT '  - Test thoroughly before production';
PRINT '  - Document trigger purpose and behavior';
PRINT '  - Provide override mechanism for emergencies';
PRINT '  - Regular review of audit logs';
PRINT '';
PRINT 'CAUTIONS:';
PRINT '  ⚠️  DDL triggers fire for ALL users (including admins)';
PRINT '  ⚠️  Can prevent critical emergency changes';
PRINT '  ⚠️  Performance impact on DDL operations';
PRINT '  ⚠️  Test with application deployment scripts';
PRINT '  ⚠️  Backup/restore may be affected';
PRINT '';
PRINT 'EMERGENCY DISABLE:';
PRINT '  DISABLE TRIGGER ALL ON DATABASE;  -- Disable all';
PRINT '  ENABLE TRIGGER ALL ON DATABASE;   -- Re-enable all';
PRINT '';
PRINT 'TROUBLESHOOTING:';
PRINT '  - Check sys.triggers for DDL triggers';
PRINT '  - Review DDLAuditLog for history';
PRINT '  - Test in development first';
PRINT '  - Monitor performance impact';
PRINT '  - Have rollback plan ready';
PRINT '';

-- View all DDL audit logs
SELECT TOP 10
    EventType,
    ObjectName,
    LoginName,
    EventDate,
    LEFT(SQLCommand, 100) AS SQLCommandPreview
FROM DDLAuditLog
ORDER BY EventDate DESC;

PRINT '';

-- Summary of active DDL triggers
SELECT 
    'DDL Triggers Active' AS Summary,
    COUNT(*) AS TriggerCount
FROM sys.triggers
WHERE parent_class = 0 AND is_disabled = 0;

PRINT '';

/*
 * EXERCISES:
 * 
 * 1. Create DDL trigger to enforce naming convention (tables must start with 'tbl_')
 * 2. Create trigger to prevent database schema changes during business hours
 * 3. Create trigger to email DBA on critical DDL operations
 * 4. Create comprehensive audit system tracking all DDL with retention policy
 * 5. Create trigger to automatically generate documentation on schema changes
 * 
 * CHALLENGE:
 * Create enterprise-grade change management system:
 * - ChangeRequests table (ID, description, SQL script, approval workflow)
 * - Multi-level approval (developer → lead → DBA)
 * - DDL trigger enforcing approval before execution
 * - Email notifications on change requests
 * - Scheduled execution window (changes only during maintenance)
 * - Rollback scripts required for approval
 * - Audit trail with before/after schema comparison
 * - Emergency override with justification logging
 * - Compliance report showing all changes in last 90 days
 */

PRINT '✓ Lab 45 Complete: DDL triggers mastered';
PRINT '';
PRINT 'Module 05 Triggers section complete!';
PRINT 'Next: Error Handling Deep Dive (Labs 46-47)';
GO
