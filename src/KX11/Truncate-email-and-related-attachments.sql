-- =============================================
-- Kentico 11 Email Queue Cleanup Script - COMPLETE VERSION
-- Purpose: Safely truncate ALL email-related tables including junction tables
-- Author: Development Team
-- Date: 2025-07-28
-- Note: This handles CMS_Email, CMS_EmailAttachment, and all related tables
-- =============================================

-- SAFETY CHECKS AND PREPARATION
-- =============================================

-- 1. Check current record counts before cleanup
PRINT 'PRE-CLEANUP RECORD COUNTS:'
PRINT '=========================='
SELECT 'CMS_Email' as TableName, COUNT(*) as RecordCount FROM CMS_Email
UNION ALL
SELECT 'CMS_EmailAttachment' as TableName, COUNT(*) as RecordCount FROM CMS_EmailAttachment
UNION ALL
SELECT 'CMS_EmailUser' as TableName, COUNT(*) as RecordCount 
FROM CMS_EmailUser WHERE EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CMS_EmailUser')
UNION ALL
SELECT 'CMS_AttachmentForEmail' as TableName, COUNT(*) as RecordCount 
FROM CMS_AttachmentForEmail WHERE EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CMS_AttachmentForEmail')
PRINT ''

-- 2. Check for any foreign key relationships that reference these tables
PRINT 'CHECKING FOREIGN KEY DEPENDENCIES:'
PRINT '=================================='
SELECT 
    fk.name as ForeignKeyName,
    tp.name as ParentTable,
    cp.name as ParentColumn,
    tr.name as ReferencedTable,
    cr.name as ReferencedColumn
FROM sys.foreign_keys fk
INNER JOIN sys.tables tp ON fk.parent_object_id = tp.object_id
INNER JOIN sys.tables tr ON fk.referenced_object_id = tr.object_id
INNER JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id = fk.object_id
INNER JOIN sys.columns cp ON fkc.parent_column_id = cp.column_id AND fkc.parent_object_id = cp.object_id
INNER JOIN sys.columns cr ON fkc.referenced_column_id = cr.column_id AND fkc.referenced_object_id = cr.object_id
WHERE tr.name IN ('CMS_Email', 'CMS_EmailAttachment')
   OR tp.name IN ('CMS_Email', 'CMS_EmailAttachment', 'CMS_EmailUser', 'CMS_AttachmentForEmail')
ORDER BY tp.name, fk.name
PRINT ''

-- BACKUP PREPARATION (OPTIONAL BUT RECOMMENDED)
-- =============================================
-- Uncomment the following if you want to create backup tables first

/*
-- Create backup tables with current timestamp
DECLARE @BackupSuffix NVARCHAR(20) = FORMAT(GETDATE(), 'yyyyMMdd_HHmmss')
DECLARE @BackupEmailTable NVARCHAR(100) = 'CMS_Email_Backup_' + @BackupSuffix
DECLARE @BackupAttachmentTable NVARCHAR(100) = 'CMS_EmailAttachment_Backup_' + @BackupSuffix

PRINT 'CREATING BACKUP TABLES:'
PRINT '======================'
EXEC('SELECT * INTO ' + @BackupEmailTable + ' FROM CMS_Email')
EXEC('SELECT * INTO ' + @BackupAttachmentTable + ' FROM CMS_EmailAttachment')
PRINT 'Backup tables created: ' + @BackupEmailTable + ', ' + @BackupAttachmentTable
PRINT ''
*/

-- MAIN CLEANUP PROCESS - METHOD 1: DROP AND RECREATE CONSTRAINTS
-- =============================================

BEGIN TRANSACTION EmailCleanup

BEGIN TRY
    PRINT 'STARTING EMAIL QUEUE CLEANUP PROCESS:'
    PRINT '====================================='
    
    -- Step 1: Store foreign key constraint definitions for recreation
    PRINT 'Step 1: Capturing foreign key constraint definitions...'
    
    DECLARE @FK_Scripts TABLE (
        ScriptID INT IDENTITY(1,1),
        DropScript NVARCHAR(MAX),
        CreateScript NVARCHAR(MAX)
    )
    
    -- Capture all foreign keys that reference email-related tables
    INSERT INTO @FK_Scripts (DropScript, CreateScript)
    SELECT 
        'ALTER TABLE [' + SCHEMA_NAME(tp.schema_id) + '].[' + tp.name + '] DROP CONSTRAINT [' + fk.name + ']',
        'ALTER TABLE [' + SCHEMA_NAME(tp.schema_id) + '].[' + tp.name + '] ADD CONSTRAINT [' + fk.name + '] FOREIGN KEY([' + cp.name + ']) REFERENCES [' + SCHEMA_NAME(tr.schema_id) + '].[' + tr.name + ']([' + cr.name + '])'
        + CASE 
            WHEN fk.delete_referential_action = 1 THEN ' ON DELETE CASCADE'
            WHEN fk.delete_referential_action = 2 THEN ' ON DELETE SET NULL'
            WHEN fk.delete_referential_action = 3 THEN ' ON DELETE SET DEFAULT'
            ELSE ''
          END
        + CASE 
            WHEN fk.update_referential_action = 1 THEN ' ON UPDATE CASCADE'
            WHEN fk.update_referential_action = 2 THEN ' ON UPDATE SET NULL'
            WHEN fk.update_referential_action = 3 THEN ' ON UPDATE SET DEFAULT'
            ELSE ''
          END
    FROM sys.foreign_keys fk
    INNER JOIN sys.tables tp ON fk.parent_object_id = tp.object_id
    INNER JOIN sys.tables tr ON fk.referenced_object_id = tr.object_id
    INNER JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id = fk.object_id
    INNER JOIN sys.columns cp ON fkc.parent_column_id = cp.column_id AND fkc.parent_object_id = cp.object_id
    INNER JOIN sys.columns cr ON fkc.referenced_column_id = cr.column_id AND fkc.referenced_object_id = cr.object_id
    WHERE tr.name IN ('CMS_Email', 'CMS_EmailAttachment')
       OR tp.name IN ('CMS_Email', 'CMS_EmailAttachment', 'CMS_EmailUser', 'CMS_AttachmentForEmail')
    
    -- Step 2: Drop foreign key constraints
    PRINT 'Step 2: Dropping foreign key constraints...'
    DECLARE @DropScript NVARCHAR(MAX)
    DECLARE drop_cursor CURSOR FOR 
    SELECT DropScript FROM @FK_Scripts
    
    OPEN drop_cursor
    FETCH NEXT FROM drop_cursor INTO @DropScript
    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT 'Executing: ' + @DropScript
        EXEC sp_executesql @DropScript
        FETCH NEXT FROM drop_cursor INTO @DropScript
    END
    CLOSE drop_cursor
    DEALLOCATE drop_cursor
    
    -- Step 3: Truncate related tables first (in dependency order)
    IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CMS_EmailUser')
    BEGIN
        PRINT 'Step 3a: Truncating CMS_EmailUser table...'
        TRUNCATE TABLE CMS_EmailUser
    END
    
    IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CMS_AttachmentForEmail')
    BEGIN
        PRINT 'Step 3b: Truncating CMS_AttachmentForEmail table...'
        TRUNCATE TABLE CMS_AttachmentForEmail
    END
    
    -- Step 4: Truncate main tables
    PRINT 'Step 4a: Truncating CMS_EmailAttachment table...'
    TRUNCATE TABLE CMS_EmailAttachment
    
    PRINT 'Step 4b: Truncating CMS_Email table...'
    TRUNCATE TABLE CMS_Email
    
    -- Step 5: Recreate foreign key constraints
    PRINT 'Step 5: Recreating foreign key constraints...'
    DECLARE @CreateScript NVARCHAR(MAX)
    DECLARE create_cursor CURSOR FOR 
    SELECT CreateScript FROM @FK_Scripts
    
    OPEN create_cursor
    FETCH NEXT FROM create_cursor INTO @CreateScript
    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT 'Executing: ' + @CreateScript
        EXEC sp_executesql @CreateScript
        FETCH NEXT FROM create_cursor INTO @CreateScript
    END
    CLOSE create_cursor
    DEALLOCATE create_cursor
    
    -- Step 6: Reset identity seeds to start from 1 (only for tables with identity columns)
    PRINT 'Step 6: Resetting identity seeds...'
    
    -- Only reset identity for tables that actually have identity columns
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('CMS_Email') AND is_identity = 1)
    BEGIN
        DBCC CHECKIDENT ('CMS_Email', RESEED, 0)
        PRINT 'Reset identity seed for CMS_Email'
    END
    
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('CMS_EmailAttachment') AND is_identity = 1)
    BEGIN
        DBCC CHECKIDENT ('CMS_EmailAttachment', RESEED, 0)
        PRINT 'Reset identity seed for CMS_EmailAttachment'
    END
    
    -- CMS_EmailUser and CMS_AttachmentForEmail don't have identity columns (composite PKs)
    -- so we skip them
    PRINT 'Skipped identity reset for junction tables (no identity columns)'
    
    -- Step 7: Update statistics for better performance
    PRINT 'Step 7: Updating table statistics...'
    UPDATE STATISTICS CMS_Email
    UPDATE STATISTICS CMS_EmailAttachment
    IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CMS_EmailUser')
        UPDATE STATISTICS CMS_EmailUser
    IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CMS_AttachmentForEmail')
        UPDATE STATISTICS CMS_AttachmentForEmail
    
    PRINT 'SUCCESS: Email queue cleanup completed successfully!'
    PRINT ''
    
    -- Verify the cleanup
    PRINT 'POST-CLEANUP VERIFICATION:'
    PRINT '========================='
    SELECT 'CMS_Email' as TableName, COUNT(*) as RecordCount FROM CMS_Email
    UNION ALL
    SELECT 'CMS_EmailAttachment' as TableName, COUNT(*) as RecordCount FROM CMS_EmailAttachment
    UNION ALL
    SELECT 'CMS_EmailUser' as TableName, COUNT(*) as RecordCount 
    FROM CMS_EmailUser WHERE EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CMS_EmailUser')
    UNION ALL
    SELECT 'CMS_AttachmentForEmail' as TableName, COUNT(*) as RecordCount 
    FROM CMS_AttachmentForEmail WHERE EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CMS_AttachmentForEmail')
    
    COMMIT TRANSACTION EmailCleanup
    PRINT ''
    PRINT 'TRANSACTION COMMITTED - Cleanup completed successfully!'
    
END TRY
BEGIN CATCH
    PRINT 'ERROR OCCURRED - Rolling back transaction...'
    PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR(10))
    PRINT 'Error Message: ' + ERROR_MESSAGE()
    
    ROLLBACK TRANSACTION EmailCleanup
    PRINT 'TRANSACTION ROLLED BACK - All changes reverted!'
    
    -- Re-raise the error (compatible with older SQL Server versions)
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY()
    DECLARE @ErrorState INT = ERROR_STATE()
    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState)
END CATCH

-- =============================================
-- ALTERNATIVE METHOD 2: BATCH DELETE APPROACH
-- (Use this if Method 1 above fails or you prefer a safer approach)
-- =============================================

/*
-- This method uses batched deletes instead of truncate
-- Slower but safer and doesn't require dropping constraints

PRINT ''
PRINT 'ALTERNATIVE METHOD - BATCH DELETE APPROACH:'
PRINT '============================================'

BEGIN TRANSACTION BatchDelete

BEGIN TRY
    DECLARE @BatchSize INT = 10000  -- Adjust batch size as needed
    DECLARE @RowsDeleted INT = 1
    DECLARE @TotalDeleted INT = 0
    
    -- Delete CMS_EmailAttachment in batches
    PRINT 'Deleting CMS_EmailAttachment records in batches...'
    WHILE @RowsDeleted > 0
    BEGIN
        DELETE TOP (@BatchSize) FROM CMS_EmailAttachment
        SET @RowsDeleted = @@ROWCOUNT
        SET @TotalDeleted = @TotalDeleted + @RowsDeleted
        
        IF @RowsDeleted > 0
        BEGIN
            PRINT 'Deleted ' + CAST(@RowsDeleted AS NVARCHAR(10)) + ' attachment records (Total: ' + CAST(@TotalDeleted AS NVARCHAR(10)) + ')'
            WAITFOR DELAY '00:00:01'  -- Small delay to prevent blocking
        END
    END
    
    -- Reset counters for email deletion
    SET @RowsDeleted = 1
    SET @TotalDeleted = 0
    
    -- Delete CMS_Email in batches
    PRINT 'Deleting CMS_Email records in batches...'
    WHILE @RowsDeleted > 0
    BEGIN
        DELETE TOP (@BatchSize) FROM CMS_Email
        SET @RowsDeleted = @@ROWCOUNT
        SET @TotalDeleted = @TotalDeleted + @RowsDeleted
        
        IF @RowsDeleted > 0
        BEGIN
            PRINT 'Deleted ' + CAST(@RowsDeleted AS NVARCHAR(10)) + ' email records (Total: ' + CAST(@TotalDeleted AS NVARCHAR(10)) + ')'
            WAITFOR DELAY '00:00:01'  -- Small delay to prevent blocking
        END
    END
    
    -- Reset identity seeds
    DBCC CHECKIDENT ('CMS_Email', RESEED, 0)
    DBCC CHECKIDENT ('CMS_EmailAttachment', RESEED, 0)
    
    -- Update statistics
    UPDATE STATISTICS CMS_Email
    UPDATE STATISTICS CMS_EmailAttachment
    
    COMMIT TRANSACTION BatchDelete
    PRINT 'Batch delete completed successfully!'
    
END TRY
BEGIN CATCH
    PRINT 'Batch delete failed: ' + ERROR_MESSAGE()
    ROLLBACK TRANSACTION BatchDelete
    
    -- Re-raise the error (compatible with older SQL Server versions)
    DECLARE @ErrorMessage2 NVARCHAR(4000) = ERROR_MESSAGE()
    DECLARE @ErrorSeverity2 INT = ERROR_SEVERITY() 
    DECLARE @ErrorState2 INT = ERROR_STATE()
    RAISERROR(@ErrorMessage2, @ErrorSeverity2, @ErrorState2)
END CATCH
*/

-- OPTIONAL: ADDITIONAL MAINTENANCE
-- =============================================

-- Rebuild indexes for optimal performance (optional)
/*
PRINT ''
PRINT 'REBUILDING INDEXES (OPTIONAL):'
PRINT '=============================='

-- Rebuild all indexes on CMS_Email
ALTER INDEX ALL ON CMS_Email REBUILD WITH (ONLINE = OFF)
PRINT 'CMS_Email indexes rebuilt'

-- Rebuild all indexes on CMS_EmailAttachment  
ALTER INDEX ALL ON CMS_EmailAttachment REBUILD WITH (ONLINE = OFF)
PRINT 'CMS_EmailAttachment indexes rebuilt'
*/

-- KENTICO CACHE CLEARING RECOMMENDATION
-- =============================================
PRINT ''
PRINT 'IMPORTANT POST-CLEANUP STEPS:'
PRINT '============================='
PRINT '1. Clear Kentico application cache via Admin UI'
PRINT '2. Restart the application pool if possible'
PRINT '3. Monitor email queue performance after cleanup'
PRINT '4. Consider implementing email archiving strategy'
PRINT ''
PRINT 'Email queue cleanup script completed successfully!'
PRINT 'Tables are now empty but retain all constraints and structure.'