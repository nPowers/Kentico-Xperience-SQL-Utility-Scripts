-- =====================================================
-- Kentico 11 Staging Tables Cleanup Script
-- Purpose: Clean staging tables for new server clone

-- =====================================================
-- Author: Neil Powers
-- Date: 2025-11-11
-- 
-- WARNING: This script will DELETE ALL staging tasks and related data
-- This is appropriate when cloning to a new environment where you want
-- staging to start fresh without historical tasks
-- =====================================================


-- Begin transaction for safety
BEGIN TRANSACTION;

PRINT '========================================';
PRINT 'Starting Kentico Staging Cleanup';
PRINT 'Date: ' + CONVERT(VARCHAR(20), GETDATE(), 120);
PRINT '========================================';
PRINT '';

-- =====================================================
-- STEP 1: Count current records before cleanup
-- =====================================================
PRINT 'STEP 1: Counting records before cleanup...';

DECLARE @BeforeSyncCount INT, @BeforeTaskUserCount INT, @BeforeTaskGroupTaskCount INT;
DECLARE @BeforeTaskGroupUserCount INT, @BeforeTaskCount INT, @BeforeTaskGroupCount INT;

SELECT @BeforeSyncCount = COUNT(*) FROM Staging_Synchronization;
SELECT @BeforeTaskUserCount = COUNT(*) FROM Staging_TaskUser;
SELECT @BeforeTaskGroupTaskCount = COUNT(*) FROM staging_TaskGroupTask;
SELECT @BeforeTaskGroupUserCount = COUNT(*) FROM staging_TaskGroupUser;
SELECT @BeforeTaskCount = COUNT(*) FROM Staging_Task;
SELECT @BeforeTaskGroupCount = COUNT(*) FROM staging_TaskGroup;

PRINT '  Staging_Synchronization: ' + CAST(@BeforeSyncCount AS VARCHAR(20));
PRINT '  Staging_TaskUser: ' + CAST(@BeforeTaskUserCount AS VARCHAR(20));
PRINT '  staging_TaskGroupTask: ' + CAST(@BeforeTaskGroupTaskCount AS VARCHAR(20));
PRINT '  staging_TaskGroupUser: ' + CAST(@BeforeTaskGroupUserCount AS VARCHAR(20));
PRINT '  Staging_Task: ' + CAST(@BeforeTaskCount AS VARCHAR(20));
PRINT '  staging_TaskGroup: ' + CAST(@BeforeTaskGroupCount AS VARCHAR(20));
PRINT '';

-- =====================================================
-- STEP 2: Delete child tables first (foreign key order)
-- =====================================================
PRINT 'STEP 2: Deleting child table records...';

-- 2.1: Delete Staging_Synchronization (references Staging_Task)
PRINT '  Deleting Staging_Synchronization records...';
DELETE FROM Staging_Synchronization;
PRINT '    Deleted: ' + CAST(@@ROWCOUNT AS VARCHAR(20)) + ' records';

-- 2.2: Delete Staging_TaskUser (references Staging_Task)
PRINT '  Deleting Staging_TaskUser records...';
DELETE FROM Staging_TaskUser;
PRINT '    Deleted: ' + CAST(@@ROWCOUNT AS VARCHAR(20)) + ' records';

-- 2.3: Delete staging_TaskGroupTask (references Staging_Task and staging_TaskGroup)
PRINT '  Deleting staging_TaskGroupTask records...';
DELETE FROM staging_TaskGroupTask;
PRINT '    Deleted: ' + CAST(@@ROWCOUNT AS VARCHAR(20)) + ' records';

-- 2.4: Delete staging_TaskGroupUser (references staging_TaskGroup)
PRINT '  Deleting staging_TaskGroupUser records...';
DELETE FROM staging_TaskGroupUser;
PRINT '    Deleted: ' + CAST(@@ROWCOUNT AS VARCHAR(20)) + ' records';

PRINT '';

-- =====================================================
-- STEP 3: Delete parent tables
-- =====================================================
PRINT 'STEP 3: Deleting parent table records...';

-- 3.1: Delete Staging_Task (main staging task table)
PRINT '  Deleting Staging_Task records...';
DELETE FROM Staging_Task;
PRINT '    Deleted: ' + CAST(@@ROWCOUNT AS VARCHAR(20)) + ' records';

-- 3.2: Delete staging_TaskGroup
PRINT '  Deleting staging_TaskGroup records...';
DELETE FROM staging_TaskGroup;
PRINT '    Deleted: ' + CAST(@@ROWCOUNT AS VARCHAR(20)) + ' records';

PRINT '';

-- =====================================================
-- STEP 4: Reset identity seeds (optional - for clean IDs)
-- =====================================================
PRINT 'STEP 4: Resetting identity seeds...';

-- Check if tables have identity columns before resetting
IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID('Staging_Task'))
BEGIN
    DBCC CHECKIDENT ('Staging_Task', RESEED, 0);
    PRINT '  Reset Staging_Task identity seed to 0';
END

IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID('staging_TaskGroup'))
BEGIN
    DBCC CHECKIDENT ('staging_TaskGroup', RESEED, 0);
    PRINT '  Reset staging_TaskGroup identity seed to 0';
END

IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID('Staging_Synchronization'))
BEGIN
    DBCC CHECKIDENT ('Staging_Synchronization', RESEED, 0);
    PRINT '  Reset Staging_Synchronization identity seed to 0';
END

PRINT '';

-- =====================================================
-- STEP 5: Verify cleanup results
-- =====================================================
PRINT 'STEP 5: Verifying cleanup...';

DECLARE @AfterSyncCount INT, @AfterTaskUserCount INT, @AfterTaskGroupTaskCount INT;
DECLARE @AfterTaskGroupUserCount INT, @AfterTaskCount INT, @AfterTaskGroupCount INT;

SELECT @AfterSyncCount = COUNT(*) FROM Staging_Synchronization;
SELECT @AfterTaskUserCount = COUNT(*) FROM Staging_TaskUser;
SELECT @AfterTaskGroupTaskCount = COUNT(*) FROM staging_TaskGroupTask;
SELECT @AfterTaskGroupUserCount = COUNT(*) FROM staging_TaskGroupUser;
SELECT @AfterTaskCount = COUNT(*) FROM Staging_Task;
SELECT @AfterTaskGroupCount = COUNT(*) FROM staging_TaskGroup;

PRINT '  Staging_Synchronization: ' + CAST(@AfterSyncCount AS VARCHAR(20));
PRINT '  Staging_TaskUser: ' + CAST(@AfterTaskUserCount AS VARCHAR(20));
PRINT '  staging_TaskGroupTask: ' + CAST(@AfterTaskGroupTaskCount AS VARCHAR(20));
PRINT '  staging_TaskGroupUser: ' + CAST(@AfterTaskGroupUserCount AS VARCHAR(20));
PRINT '  Staging_Task: ' + CAST(@AfterTaskCount AS VARCHAR(20));
PRINT '  staging_TaskGroup: ' + CAST(@AfterTaskGroupCount AS VARCHAR(20));
PRINT '';

-- =====================================================
-- STEP 6: Summary report
-- =====================================================
PRINT '========================================';
PRINT 'CLEANUP SUMMARY';
PRINT '========================================';
PRINT 'Records Deleted:';
PRINT '  Staging_Synchronization: ' + CAST(@BeforeSyncCount AS VARCHAR(20));
PRINT '  Staging_TaskUser: ' + CAST(@BeforeTaskUserCount AS VARCHAR(20));
PRINT '  staging_TaskGroupTask: ' + CAST(@BeforeTaskGroupTaskCount AS VARCHAR(20));
PRINT '  staging_TaskGroupUser: ' + CAST(@BeforeTaskGroupUserCount AS VARCHAR(20));
PRINT '  Staging_Task: ' + CAST(@BeforeTaskCount AS VARCHAR(20));
PRINT '  staging_TaskGroup: ' + CAST(@BeforeTaskGroupCount AS VARCHAR(20));
PRINT '----------------------------------------';
PRINT 'Total Deleted: ' + CAST((@BeforeSyncCount + @BeforeTaskUserCount + @BeforeTaskGroupTaskCount + 
                                  @BeforeTaskGroupUserCount + @BeforeTaskCount + @BeforeTaskGroupCount) AS VARCHAR(20));
PRINT '';
PRINT 'All staging tables cleaned successfully!';
PRINT 'The staging system is ready for a clean clone.';
PRINT '';
PRINT 'NOTE: Staging_Server table was NOT modified.';
PRINT 'This preserves your staging server configurations.';
PRINT '========================================';

-- =====================================================
-- IMPORTANT: Review results before committing!
-- =====================================================
-- Uncomment ONE of the following lines:

-- ROLLBACK TRANSACTION;  -- Undo all changes (for testing)
COMMIT TRANSACTION;       -- Make changes permanent

PRINT '';
PRINT 'Transaction committed. Cleanup complete.';
PRINT '';

-- =====================================================
-- OPTIONAL: Space reclamation
-- =====================================================
-- After cleanup, you may want to reclaim disk space:
-- EXEC sp_MSforeachtable 'ALTER INDEX ALL ON ? REBUILD';
-- Or for specific tables:
-- ALTER INDEX ALL ON Staging_Task REBUILD;

GO
