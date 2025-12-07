/*
 * Lab 33: SQL Server Agent and Alerts
 * Module 04: Database Administration
 * 
 * Objective: Configure SQL Server Agent jobs, schedules, and alerts
 * Duration: 2-3 hours
 * Difficulty: ⭐⭐⭐⭐
 */

USE msdb;  -- SQL Agent configuration stored in msdb
GO

PRINT '==============================================';
PRINT 'Lab 33: SQL Server Agent and Alerts';
PRINT '==============================================';
PRINT '';

/*
 * SQL SERVER AGENT COMPONENTS:
 * 
 * 1. Jobs: Scheduled tasks (backups, maintenance, etc.)
 * 2. Schedules: When jobs run
 * 3. Alerts: Respond to events or conditions
 * 4. Operators: Notification recipients
 * 5. Proxies: Security context for job steps
 */

/*
 * PART 1: CREATE OPERATORS (Notification Recipients)
 */

PRINT 'PART 1: Creating Operators';
PRINT '---------------------------';

-- Create DBA operator
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysoperators WHERE name = 'DBA_Team')
BEGIN
    EXEC msdb.dbo.sp_add_operator
        @name = N'DBA_Team',
        @enabled = 1,
        @email_address = N'dba@company.com',
        @pager_address = N'555-1234',
        @weekday_pager_start_time = 080000,  -- 8:00 AM
        @weekday_pager_end_time = 180000,    -- 6:00 PM
        @saturday_pager_start_time = 080000,
        @saturday_pager_end_time = 120000,   -- 12:00 PM
        @sunday_pager_start_time = 000000,
        @sunday_pager_end_time = 000000;     -- No Sunday pager
    
    PRINT '✓ Created operator: DBA_Team';
END;

-- Create backup administrator operator
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysoperators WHERE name = 'BackupAdmin')
BEGIN
    EXEC msdb.dbo.sp_add_operator
        @name = N'BackupAdmin',
        @enabled = 1,
        @email_address = N'backup-admin@company.com';
    
    PRINT '✓ Created operator: BackupAdmin';
END;

PRINT '';

-- View operators
SELECT 
    name AS OperatorName,
    enabled AS IsEnabled,
    email_address AS Email,
    pager_address AS Pager,
    last_email_date AS LastEmail,
    last_pager_date AS LastPager
FROM msdb.dbo.sysoperators
ORDER BY name;

PRINT '';

/*
 * PART 2: CREATE JOB - DAILY BACKUP
 */

PRINT 'PART 2: Creating Daily Backup Job';
PRINT '-----------------------------------';

DECLARE @jobId BINARY(16);

-- Delete job if exists
IF EXISTS (SELECT * FROM msdb.dbo.sysjobs WHERE name = N'DailyBackup_BookstoreDB')
BEGIN
    EXEC msdb.dbo.sp_delete_job @job_name = N'DailyBackup_BookstoreDB';
END;

-- Create job
EXEC msdb.dbo.sp_add_job
    @job_name = N'DailyBackup_BookstoreDB',
    @enabled = 1,
    @description = N'Performs daily full backup of BookstoreDB',
    @category_name = N'Database Maintenance',
    @owner_login_name = N'sa',
    @job_id = @jobId OUTPUT;

PRINT '✓ Created job: DailyBackup_BookstoreDB';

-- Add step 1: Full backup
EXEC msdb.dbo.sp_add_jobstep
    @job_id = @jobId,
    @step_name = N'Full Backup',
    @step_id = 1,
    @subsystem = N'TSQL',
    @command = N'
DECLARE @BackupPath NVARCHAR(500);
DECLARE @DatabaseName NVARCHAR(128) = ''BookstoreDB'';

SET @BackupPath = ''C:\SQLBackups\'' + @DatabaseName + ''_Full_'' + 
    REPLACE(CONVERT(VARCHAR, GETDATE(), 120), '':'', '''') + ''.bak'';

BACKUP DATABASE BookstoreDB
TO DISK = @BackupPath
WITH 
    FORMAT,
    COMPRESSION,
    CHECKSUM,
    STATS = 10,
    NAME = ''BookstoreDB Daily Full Backup'';

PRINT ''Backup completed: '' + @BackupPath;
',
    @database_name = N'master',
    @on_success_action = 3,  -- Go to next step
    @on_fail_action = 2,     -- Quit with failure
    @retry_attempts = 3,
    @retry_interval = 5;

-- Add step 2: Verify backup
EXEC msdb.dbo.sp_add_jobstep
    @job_id = @jobId,
    @step_name = N'Verify Backup',
    @step_id = 2,
    @subsystem = N'TSQL',
    @command = N'
DECLARE @LastBackup NVARCHAR(500);

SELECT TOP 1 @LastBackup = physical_device_name
FROM msdb.dbo.backupset bs
INNER JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
WHERE database_name = ''BookstoreDB''
ORDER BY backup_finish_date DESC;

IF @LastBackup IS NOT NULL
BEGIN
    RESTORE VERIFYONLY FROM DISK = @LastBackup WITH CHECKSUM;
    PRINT ''Backup verified: '' + @LastBackup;
END;
',
    @database_name = N'master',
    @on_success_action = 3,
    @on_fail_action = 2;

-- Add step 3: Cleanup old backups
EXEC msdb.dbo.sp_add_jobstep
    @job_id = @jobId,
    @step_name = N'Cleanup Old Backups',
    @step_id = 3,
    @subsystem = N'TSQL',
    @command = N'
-- Delete backup history older than 30 days
DECLARE @DeleteDate DATETIME = DATEADD(DAY, -30, GETDATE());
EXEC msdb.dbo.sp_delete_backuphistory @oldest_date = @DeleteDate;
PRINT ''Cleaned up backup history older than 30 days'';
',
    @database_name = N'msdb',
    @on_success_action = 1,  -- Quit with success
    @on_fail_action = 2;

PRINT '✓ Added 3 job steps';

-- Set job to start at step 1
EXEC msdb.dbo.sp_update_job
    @job_id = @jobId,
    @start_step_id = 1;

-- Add schedule: Daily at 2:00 AM
EXEC msdb.dbo.sp_add_jobschedule
    @job_id = @jobId,
    @name = N'Daily at 2 AM',
    @enabled = 1,
    @freq_type = 4,          -- Daily
    @freq_interval = 1,      -- Every 1 day
    @freq_subday_type = 1,   -- At specified time
    @active_start_time = 020000;  -- 2:00 AM

PRINT '✓ Scheduled: Daily at 2:00 AM';

-- Add notification on failure
EXEC msdb.dbo.sp_add_jobserver
    @job_id = @jobId,
    @server_name = N'(local)';

EXEC msdb.dbo.sp_update_job
    @job_id = @jobId,
    @notify_level_email = 2,  -- On failure
    @notify_email_operator_name = N'DBA_Team';

PRINT '✓ Configured to notify DBA_Team on failure';
PRINT '';

/*
 * PART 3: CREATE JOB - INDEX MAINTENANCE
 */

PRINT 'PART 3: Creating Index Maintenance Job';
PRINT '---------------------------------------';

-- Delete job if exists
IF EXISTS (SELECT * FROM msdb.dbo.sysjobs WHERE name = N'WeeklyIndexMaintenance')
BEGIN
    EXEC msdb.dbo.sp_delete_job @job_name = N'WeeklyIndexMaintenance';
END;

-- Create job
EXEC msdb.dbo.sp_add_job
    @job_name = N'WeeklyIndexMaintenance',
    @enabled = 1,
    @description = N'Weekly index rebuild and reorganize',
    @category_name = N'Database Maintenance',
    @job_id = @jobId OUTPUT;

-- Add step: Run index maintenance
EXEC msdb.dbo.sp_add_jobstep
    @job_id = @jobId,
    @step_name = N'Index Maintenance',
    @subsystem = N'TSQL',
    @command = N'
-- Reorganize indexes with 10-30% fragmentation
ALTER INDEX ALL ON BookstoreDB.dbo.Books REORGANIZE;
ALTER INDEX ALL ON BookstoreDB.dbo.Orders REORGANIZE;
ALTER INDEX ALL ON BookstoreDB.dbo.Customers REORGANIZE;

-- Rebuild indexes with >30% fragmentation
ALTER INDEX ALL ON BookstoreDB.dbo.Books REBUILD WITH (FILLFACTOR = 90, SORT_IN_TEMPDB = ON);
ALTER INDEX ALL ON BookstoreDB.dbo.Orders REBUILD WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = ON);

-- Update statistics
EXEC BookstoreDB.dbo.sp_updatestats;

PRINT ''Index maintenance completed'';
',
    @database_name = N'master',
    @on_success_action = 1,
    @on_fail_action = 2;

-- Schedule: Weekly on Sunday at 3:00 AM
EXEC msdb.dbo.sp_add_jobschedule
    @job_id = @jobId,
    @name = N'Weekly Sunday 3 AM',
    @enabled = 1,
    @freq_type = 8,          -- Weekly
    @freq_interval = 1,      -- Sunday (1=Sun, 2=Mon, ..., 64=Sat)
    @freq_recurrence_factor = 1,  -- Every 1 week
    @active_start_time = 030000;  -- 3:00 AM

EXEC msdb.dbo.sp_add_jobserver @job_id = @jobId;

PRINT '✓ Created WeeklyIndexMaintenance job';
PRINT '';

/*
 * PART 4: CREATE JOB - INTEGRITY CHECK
 */

PRINT 'PART 4: Creating Integrity Check Job';
PRINT '--------------------------------------';

IF EXISTS (SELECT * FROM msdb.dbo.sysjobs WHERE name = N'Weekly_DBCC_CHECKDB')
BEGIN
    EXEC msdb.dbo.sp_delete_job @job_name = N'Weekly_DBCC_CHECKDB';
END;

EXEC msdb.dbo.sp_add_job
    @job_name = N'Weekly_DBCC_CHECKDB',
    @enabled = 1,
    @description = N'Weekly database integrity check',
    @job_id = @jobId OUTPUT;

EXEC msdb.dbo.sp_add_jobstep
    @job_id = @jobId,
    @step_name = N'DBCC CHECKDB',
    @subsystem = N'TSQL',
    @command = N'
DBCC CHECKDB(BookstoreDB) WITH NO_INFOMSGS, ALL_ERRORMSGS;
PRINT ''DBCC CHECKDB completed successfully'';
',
    @database_name = N'master',
    @on_success_action = 1,
    @on_fail_action = 2;

EXEC msdb.dbo.sp_add_jobschedule
    @job_id = @jobId,
    @name = N'Weekly Saturday Midnight',
    @freq_type = 8,
    @freq_interval = 64,  -- Saturday
    @active_start_time = 000000;

EXEC msdb.dbo.sp_add_jobserver @job_id = @jobId;

PRINT '✓ Created Weekly_DBCC_CHECKDB job';
PRINT '';

/*
 * PART 5: CREATE ALERTS
 */

PRINT 'PART 5: Creating Alerts';
PRINT '------------------------';

-- Alert: Severity 17 (Insufficient Resources)
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysalerts WHERE name = N'Severity 17 - Insufficient Resources')
BEGIN
    EXEC msdb.dbo.sp_add_alert
        @name = N'Severity 17 - Insufficient Resources',
        @message_id = 0,
        @severity = 17,
        @enabled = 1,
        @delay_between_responses = 300,  -- 5 minutes
        @include_event_description_in = 1;  -- Email
    
    EXEC msdb.dbo.sp_add_notification
        @alert_name = N'Severity 17 - Insufficient Resources',
        @operator_name = N'DBA_Team',
        @notification_method = 1;  -- Email
    
    PRINT '✓ Created alert: Severity 17';
END;

-- Alert: Severity 19 (Fatal Error in Resource)
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysalerts WHERE name = N'Severity 19 - Fatal Error')
BEGIN
    EXEC msdb.dbo.sp_add_alert
        @name = N'Severity 19 - Fatal Error',
        @severity = 19,
        @enabled = 1,
        @delay_between_responses = 0,  -- Immediate
        @include_event_description_in = 1;
    
    EXEC msdb.dbo.sp_add_notification
        @alert_name = N'Severity 19 - Fatal Error',
        @operator_name = N'DBA_Team',
        @notification_method = 1;
    
    PRINT '✓ Created alert: Severity 19';
END;

-- Alert: Severity 20 (Fatal Error in Current Process)
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysalerts WHERE name = N'Severity 20 - Fatal Error')
BEGIN
    EXEC msdb.dbo.sp_add_alert
        @name = N'Severity 20 - Fatal Error',
        @severity = 20,
        @enabled = 1,
        @include_event_description_in = 1;
    
    EXEC msdb.dbo.sp_add_notification
        @alert_name = N'Severity 20 - Fatal Error',
        @operator_name = N'DBA_Team',
        @notification_method = 1;
    
    PRINT '✓ Created alert: Severity 20';
END;

-- Alert: Error 823 (I/O Error)
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysalerts WHERE name = N'Error 823 - I/O Error')
BEGIN
    EXEC msdb.dbo.sp_add_alert
        @name = N'Error 823 - I/O Error',
        @message_id = 823,
        @enabled = 1,
        @delay_between_responses = 0;
    
    EXEC msdb.dbo.sp_add_notification
        @alert_name = N'Error 823 - I/O Error',
        @operator_name = N'DBA_Team',
        @notification_method = 1;
    
    PRINT '✓ Created alert: Error 823 (I/O Error)';
END;

-- Alert: Error 824 (Logical I/O Error)
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysalerts WHERE name = N'Error 824 - Logical I/O Error')
BEGIN
    EXEC msdb.dbo.sp_add_alert
        @name = N'Error 824 - Logical I/O Error',
        @message_id = 824,
        @enabled = 1;
    
    EXEC msdb.dbo.sp_add_notification
        @alert_name = N'Error 824 - Logical I/O Error',
        @operator_name = N'DBA_Team',
        @notification_method = 1;
    
    PRINT '✓ Created alert: Error 824';
END;

-- Alert: Error 825 (Read-Retry)
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysalerts WHERE name = N'Error 825 - Read Retry')
BEGIN
    EXEC msdb.dbo.sp_add_alert
        @name = N'Error 825 - Read Retry',
        @message_id = 825,
        @enabled = 1;
    
    EXEC msdb.dbo.sp_add_notification
        @alert_name = N'Error 825 - Read Retry',
        @operator_name = N'DBA_Team',
        @notification_method = 1;
    
    PRINT '✓ Created alert: Error 825';
END;

-- Performance condition alert: CPU > 90%
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysalerts WHERE name = N'High CPU Usage')
BEGIN
    EXEC msdb.dbo.sp_add_alert
        @name = N'High CPU Usage',
        @enabled = 1,
        @delay_between_responses = 600,  -- 10 minutes
        @performance_condition = N'SQLServer:Resource Pool Stats|CPU usage %|default|>|90';
    
    EXEC msdb.dbo.sp_add_notification
        @alert_name = N'High CPU Usage',
        @operator_name = N'DBA_Team',
        @notification_method = 1;
    
    PRINT '✓ Created alert: High CPU Usage';
END;

PRINT '';

/*
 * PART 6: VIEW JOBS AND ALERTS
 */

PRINT 'PART 6: Viewing Jobs and Alerts';
PRINT '--------------------------------';

-- List all jobs
SELECT 
    j.name AS JobName,
    j.enabled AS IsEnabled,
    SUSER_SNAME(j.owner_sid) AS Owner,
    c.name AS Category,
    j.date_created AS CreatedDate,
    j.date_modified AS ModifiedDate,
    CASE j.notify_level_email
        WHEN 0 THEN 'Never'
        WHEN 1 THEN 'On Success'
        WHEN 2 THEN 'On Failure'
        WHEN 3 THEN 'Always'
    END AS EmailNotification
FROM msdb.dbo.sysjobs j
LEFT JOIN msdb.dbo.syscategories c ON j.category_id = c.category_id
WHERE j.name LIKE '%Bookstore%' OR j.name LIKE '%Weekly%' OR j.name LIKE '%Daily%'
ORDER BY j.name;

PRINT '';

-- List all alerts
SELECT 
    name AS AlertName,
    enabled AS IsEnabled,
    severity AS Severity,
    message_id AS MessageID,
    delay_between_responses AS DelaySeconds,
    last_occurrence_date AS LastOccurrence,
    occurrence_count AS OccurrenceCount
FROM msdb.dbo.sysalerts
ORDER BY severity DESC, name;

PRINT '';

/*
 * PART 7: JOB HISTORY
 */

PRINT 'PART 7: Job Execution History';
PRINT '------------------------------';

-- Recent job executions
SELECT TOP 20
    j.name AS JobName,
    jh.step_name AS StepName,
    CASE jh.run_status
        WHEN 0 THEN 'Failed'
        WHEN 1 THEN 'Succeeded'
        WHEN 2 THEN 'Retry'
        WHEN 3 THEN 'Canceled'
        WHEN 4 THEN 'In Progress'
    END AS Status,
    msdb.dbo.agent_datetime(jh.run_date, jh.run_time) AS RunDateTime,
    jh.run_duration AS DurationSeconds,
    jh.message AS Message
FROM msdb.dbo.sysjobhistory jh
INNER JOIN msdb.dbo.sysjobs j ON jh.job_id = j.job_id
WHERE jh.step_id = 0  -- Overall job outcome (0 = job level)
ORDER BY jh.run_date DESC, jh.run_time DESC;

PRINT '';

/*
 * PART 8: MANUALLY RUN A JOB
 */

PRINT 'PART 8: Manual Job Execution';
PRINT '-----------------------------';

-- Start a job manually (commented - don't run automatically)
/*
EXEC msdb.dbo.sp_start_job @job_name = N'DailyBackup_BookstoreDB';
PRINT 'Job started: DailyBackup_BookstoreDB';

-- Check job status
WAITFOR DELAY '00:00:05';  -- Wait 5 seconds

SELECT 
    j.name AS JobName,
    ja.start_execution_date AS StartTime,
    ISNULL(ja.stop_execution_date, GETDATE()) AS EndTime,
    DATEDIFF(SECOND, ja.start_execution_date, ISNULL(ja.stop_execution_date, GETDATE())) AS DurationSec,
    ja.last_executed_step_id AS CurrentStep,
    CASE ja.last_run_outcome
        WHEN 0 THEN 'Failed'
        WHEN 1 THEN 'Succeeded'
        WHEN 3 THEN 'Canceled'
        WHEN 5 THEN 'Unknown'
    END AS Status
FROM msdb.dbo.sysjobs j
INNER JOIN msdb.dbo.sysjobactivity ja ON j.job_id = ja.job_id
WHERE j.name = N'DailyBackup_BookstoreDB'
    AND ja.run_requested_date IS NOT NULL
ORDER BY ja.start_execution_date DESC;
*/

PRINT 'Manual execution commands (commented out for safety)';
PRINT '  EXEC msdb.dbo.sp_start_job @job_name = ''JobName'';';
PRINT '  EXEC msdb.dbo.sp_stop_job @job_name = ''JobName'';';
PRINT '';

/*
 * PART 9: JOB AND ALERT MAINTENANCE
 */

PRINT 'PART 9: Job and Alert Maintenance';
PRINT '-----------------------------------';

-- Disable a job
/*
EXEC msdb.dbo.sp_update_job 
    @job_name = N'WeeklyIndexMaintenance',
    @enabled = 0;
*/

-- Modify job schedule
/*
EXEC msdb.dbo.sp_update_schedule
    @name = N'Daily at 2 AM',
    @active_start_time = 030000;  -- Change to 3:00 AM
*/

-- Delete old job history (keep last 30 days)
DECLARE @DeleteBeforeDate DATETIME = DATEADD(DAY, -30, GETDATE());
EXEC msdb.dbo.sp_purge_jobhistory @oldest_date = @DeleteBeforeDate;
PRINT '✓ Purged job history older than 30 days';

PRINT '';

/*
 * PART 10: BEST PRACTICES
 */

PRINT 'PART 10: SQL Agent Best Practices';
PRINT '-----------------------------------';
PRINT '';
PRINT 'JOB DESIGN:';
PRINT '  ✓ Break complex tasks into multiple steps';
PRINT '  ✓ Log output to tables for historical tracking';
PRINT '  ✓ Implement error handling in T-SQL steps';
PRINT '  ✓ Use appropriate retry logic';
PRINT '  ✓ Test jobs before scheduling';
PRINT '';
PRINT 'SCHEDULING:';
PRINT '  ✓ Avoid overlapping maintenance windows';
PRINT '  ✓ Schedule backups during low-activity periods';
PRINT '  ✓ Stagger job start times';
PRINT '  ✓ Account for time zones';
PRINT '';
PRINT 'NOTIFICATIONS:';
PRINT '  ✓ Configure Database Mail first';
PRINT '  ✓ Alert on failures, not successes';
PRINT '  ✓ Use operator schedules (on-call rotations)';
PRINT '  ✓ Include meaningful error messages';
PRINT '';
PRINT 'MONITORING:';
PRINT '  ✓ Review job history regularly';
PRINT '  ✓ Track job duration trends';
PRINT '  ✓ Alert on job runtime anomalies';
PRINT '  ✓ Monitor SQL Agent service status';
PRINT '';
PRINT 'SECURITY:';
PRINT '  ✓ Use least privilege for job owners';
PRINT '  ✓ Implement proxy accounts for non-SQL steps';
PRINT '  ✓ Encrypt sensitive data in job steps';
PRINT '  ✓ Audit job changes';
PRINT '';

/*
 * EXERCISES:
 * 
 * 1. Create a multi-step backup job (full + log + verify)
 * 2. Implement a job that sends daily database health report email
 * 3. Create alerts for long-running queries
 * 4. Build a job monitoring dashboard
 * 5. Implement job dependency management (job A must complete before job B)
 * 
 * CHALLENGE:
 * Design a complete job automation framework:
 * - Dynamic job generation based on database inventory
 * - Intelligent scheduling (avoid resource conflicts)
 * - Self-healing jobs (automatic retry with escalation)
 * - Centralized job management for multiple servers
 * - Integration with ITSM tools (ServiceNow, etc.)
 * - Compliance tracking and audit logging
 */

PRINT '✓ Lab 33 Complete: SQL Server Agent mastered';
PRINT '';
PRINT 'SQL Agent Components:';
PRINT '  1. Jobs:      Scheduled tasks';
PRINT '  2. Steps:     Individual job actions';
PRINT '  3. Schedules: When jobs run';
PRINT '  4. Alerts:    Event-driven notifications';
PRINT '  5. Operators: Notification recipients';
PRINT '  6. Proxies:   Security contexts (non-SQL steps)';
GO
