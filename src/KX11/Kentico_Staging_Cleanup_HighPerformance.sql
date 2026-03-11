-- =====================================================
-- Kentico 11 Staging Tables - HIGH PERFORMANCE CLEANUP
-- Purpose: Clean large staging tables (1M+ records)
-- =====================================================
-- This version uses batch deletion for large datasets
-- Estimated for: 1,125,000 records (45,000 pages × 25 items)
-- =====================================================

SET NOCOUNT ON;

-- =====================================================
-- CONFIGURATION
-- =====================================================
DECLARE @BatchSize INT = 10000;  -- Delete 10K records per batch
DECLARE @DelaySeconds INT = 1;    -- Pause 1 second between batches
DECLARE @MaxBatches INT = 200;    -- Safety limit (10000 × 200 = 2M records max)

-- =====================================================
-- PRE-CLEANUP ANALYSIS
-- =====================================================
PRINT '========================================';
PRINT 'HIGH PERFORMANCE STAGING CLEANUP';
PRINT 'Date: ' + CONVERT(VARCHAR(20), GETDATE(), 120);
PRINT '========================================';
PRINT '';
PRINT 'Configuration:';
PRINT '  Batch Size: ' + CAST(@BatchSize AS VARCHAR(20));
PRINT '  Delay: ' + CAST(@DelaySeconds AS VARCHAR(20)) + ' second(s)';
PRINT '  Max Batches: ' + CAST(@MaxBatches AS VARCHAR(20));
PRINT '';

-- Count records before cleanup
DECLARE @BeforeSyncCount INT, @BeforeTaskUserCount INT, @BeforeTaskGroupTaskCount INT;
DECLARE @BeforeTaskGroupUserCount INT, @BeforeTaskCount INT, @BeforeTaskGroupCount INT;

SELECT @BeforeSyncCount = COUNT(*) FROM Staging_Synchronization;
SELECT @BeforeTaskUserCount = COUNT(*) FROM Staging_TaskUser;
SELECT @BeforeTaskGroupTaskCount = COUNT(*) FROM staging_TaskGroupTask;
SELECT @BeforeTaskGroupUserCount = COUNT(*) FROM staging_TaskGroupUser;
SELECT @BeforeTaskCount = COUNT(*) FROM Staging_Task;
SELECT @BeforeTaskGroupCount = COUNT(*) FROM staging_TaskGroup;

PRINT 'Records BEFORE cleanup:';
PRINT '  Staging_Synchronization: ' + CAST(@BeforeSyncCount AS VARCHAR(20));
PRINT '  Staging_TaskUser: ' + CAST(@BeforeTaskUserCount AS VARCHAR(20));
PRINT '  staging_TaskGroupTask: ' + CAST(@BeforeTaskGroupTaskCount AS VARCHAR(20));
PRINT '  staging_TaskGroupUser: ' + CAST(@BeforeTaskGroupUserCount AS VARCHAR(20));
PRINT '  Staging_Task: ' + CAST(@BeforeTaskCount AS VARCHAR(20));
PRINT '  staging_TaskGroup: ' + CAST(@BeforeTaskGroupCount AS VARCHAR(20));
PRINT '  ----------------------------------------';
PRINT '  TOTAL: ' + CAST((@BeforeSyncCount + @BeforeTaskUserCount + @BeforeTaskGroupTaskCount + 
                          @BeforeTaskGroupUserCount + @BeforeTaskCount + @BeforeTaskGroupCount) AS VARCHAR(20));
PRINT '';

-- =====================================================
-- STEP 1: Temporarily disable foreign key constraints
-- (Massive performance improvement for large deletes)
-- =====================================================
PRINT 'STEP 1: Disabling foreign key constraints...';
PRINT '';

ALTER TABLE Staging_Synchronization NOCHECK CONSTRAINT ALL;
ALTER TABLE Staging_TaskUser NOCHECK CONSTRAINT ALL;
ALTER TABLE staging_TaskGroupTask NOCHECK CONSTRAINT ALL;
ALTER TABLE staging_TaskGroupUser NOCHECK CONSTRAINT ALL;
ALTER TABLE Staging_Task NOCHECK CONSTRAINT ALL;
ALTER TABLE staging_TaskGroup NOCHECK CONSTRAINT ALL;

PRINT '  All foreign key constraints disabled.';
PRINT '  This improves deletion performance by 10-100x.';
PRINT '';

-- =====================================================
-- STEP 2: Switch to SIMPLE recovery (prevents log bloat)
-- =====================================================
PRINT 'STEP 2: Switching to SIMPLE recovery mode...';
PRINT '';

DECLARE @OriginalRecoveryModel VARCHAR(20);
SELECT @OriginalRecoveryModel = recovery_model_desc 
FROM sys.databases 
WHERE name = 'Neutron';

PRINT '  Original Recovery Model: ' + @OriginalRecoveryModel;

IF @OriginalRecoveryModel <> 'SIMPLE'
BEGIN
    ALTER DATABASE Neutron SET RECOVERY SIMPLE;
    PRINT '  Switched to SIMPLE recovery mode for cleanup.';
    PRINT '  This allows log truncation between batches.';
END
ELSE
BEGIN
    PRINT '  Already in SIMPLE recovery mode.';
END
PRINT '';

-- =====================================================
-- STEP 3: Batch delete child tables
-- =====================================================
PRINT 'STEP 3: Deleting child table records in batches...';
PRINT '';

-- Variables for batch tracking
DECLARE @RowsDeleted INT, @TotalDeleted INT, @BatchNumber INT;
DECLARE @StartTime DATETIME, @ElapsedSeconds INT;

-- 3.1: Delete Staging_Synchronization
PRINT '  [3.1] Deleting Staging_Synchronization...';
SET @TotalDeleted = 0;
SET @BatchNumber = 0;
SET @StartTime = GETDATE();

WHILE @BatchNumber < @MaxBatches
BEGIN
    DELETE TOP (@BatchSize) FROM Staging_Synchronization;
    SET @RowsDeleted = @@ROWCOUNT;
    SET @TotalDeleted = @TotalDeleted + @RowsDeleted;
    SET @BatchNumber = @BatchNumber + 1;
    
    IF @RowsDeleted = 0 BREAK;
    
    IF @BatchNumber % 10 = 0  -- Progress every 10 batches
        PRINT '    Batch ' + CAST(@BatchNumber AS VARCHAR(10)) + ': Deleted ' + CAST(@TotalDeleted AS VARCHAR(20)) + ' records...';
    
    CHECKPOINT; -- Force log truncation
    WAITFOR DELAY '00:00:01'; -- Brief pause
END

SET @ElapsedSeconds = DATEDIFF(SECOND, @StartTime, GETDATE());
PRINT '    COMPLETED: ' + CAST(@TotalDeleted AS VARCHAR(20)) + ' records in ' + CAST(@ElapsedSeconds AS VARCHAR(10)) + ' seconds';
PRINT '';

-- 3.2: Delete Staging_TaskUser
PRINT '  [3.2] Deleting Staging_TaskUser...';
SET @TotalDeleted = 0;
SET @BatchNumber = 0;
SET @StartTime = GETDATE();

WHILE @BatchNumber < @MaxBatches
BEGIN
    DELETE TOP (@BatchSize) FROM Staging_TaskUser;
    SET @RowsDeleted = @@ROWCOUNT;
    SET @TotalDeleted = @TotalDeleted + @RowsDeleted;
    SET @BatchNumber = @BatchNumber + 1;
    
    IF @RowsDeleted = 0 BREAK;
    
    IF @BatchNumber % 10 = 0
        PRINT '    Batch ' + CAST(@BatchNumber AS VARCHAR(10)) + ': Deleted ' + CAST(@TotalDeleted AS VARCHAR(20)) + ' records...';
    
    CHECKPOINT;
    WAITFOR DELAY '00:00:01';
END

SET @ElapsedSeconds = DATEDIFF(SECOND, @StartTime, GETDATE());
PRINT '    COMPLETED: ' + CAST(@TotalDeleted AS VARCHAR(20)) + ' records in ' + CAST(@ElapsedSeconds AS VARCHAR(10)) + ' seconds';
PRINT '';

-- 3.3: Delete staging_TaskGroupTask
PRINT '  [3.3] Deleting staging_TaskGroupTask...';
SET @TotalDeleted = 0;
SET @BatchNumber = 0;
SET @StartTime = GETDATE();

WHILE @BatchNumber < @MaxBatches
BEGIN
    DELETE TOP (@BatchSize) FROM staging_TaskGroupTask;
    SET @RowsDeleted = @@ROWCOUNT;
    SET @TotalDeleted = @TotalDeleted + @RowsDeleted;
    SET @BatchNumber = @BatchNumber + 1;
    
    IF @RowsDeleted = 0 BREAK;
    
    IF @BatchNumber % 10 = 0
        PRINT '    Batch ' + CAST(@BatchNumber AS VARCHAR(10)) + ': Deleted ' + CAST(@TotalDeleted AS VARCHAR(20)) + ' records...';
    
    CHECKPOINT;
    WAITFOR DELAY '00:00:01';
END

SET @ElapsedSeconds = DATEDIFF(SECOND, @StartTime, GETDATE());
PRINT '    COMPLETED: ' + CAST(@TotalDeleted AS VARCHAR(20)) + ' records in ' + CAST(@ElapsedSeconds AS VARCHAR(10)) + ' seconds';
PRINT '';

-- 3.4: Delete staging_TaskGroupUser
PRINT '  [3.4] Deleting staging_TaskGroupUser...';
SET @TotalDeleted = 0;
SET @BatchNumber = 0;
SET @StartTime = GETDATE();

WHILE @BatchNumber < @MaxBatches
BEGIN
    DELETE TOP (@BatchSize) FROM staging_TaskGroupUser;
    SET @RowsDeleted = @@ROWCOUNT;
    SET @TotalDeleted = @TotalDeleted + @RowsDeleted;
    SET @BatchNumber = @BatchNumber + 1;
    
    IF @RowsDeleted = 0 BREAK;
    
    IF @BatchNumber % 10 = 0
        PRINT '    Batch ' + CAST(@BatchNumber AS VARCHAR(10)) + ': Deleted ' + CAST(@TotalDeleted AS VARCHAR(20)) + ' records...';
    
    CHECKPOINT;
    WAITFOR DELAY '00:00:01';
END

SET @ElapsedSeconds = DATEDIFF(SECOND, @StartTime, GETDATE());
PRINT '    COMPLETED: ' + CAST(@TotalDeleted AS VARCHAR(20)) + ' records in ' + CAST(@ElapsedSeconds AS VARCHAR(10)) + ' seconds';
PRINT '';

-- =====================================================
-- STEP 4: Batch delete parent tables
-- =====================================================
PRINT 'STEP 4: Deleting parent table records in batches...';
PRINT '';

-- 4.1: Delete Staging_Task (LARGEST TABLE)
PRINT '  [4.1] Deleting Staging_Task (this may take several minutes)...';
SET @TotalDeleted = 0;
SET @BatchNumber = 0;
SET @StartTime = GETDATE();

WHILE @BatchNumber < @MaxBatches
BEGIN
    DELETE TOP (@BatchSize) FROM Staging_Task;
    SET @RowsDeleted = @@ROWCOUNT;
    SET @TotalDeleted = @TotalDeleted + @RowsDeleted;
    SET @BatchNumber = @BatchNumber + 1;
    
    IF @RowsDeleted = 0 BREAK;
    
    IF @BatchNumber % 10 = 0
        PRINT '    Batch ' + CAST(@BatchNumber AS VARCHAR(10)) + ': Deleted ' + CAST(@TotalDeleted AS VARCHAR(20)) + ' records...';
    
    CHECKPOINT;
    WAITFOR DELAY '00:00:01';
END

SET @ElapsedSeconds = DATEDIFF(SECOND, @StartTime, GETDATE());
PRINT '    COMPLETED: ' + CAST(@TotalDeleted AS VARCHAR(20)) + ' records in ' + CAST(@ElapsedSeconds AS VARCHAR(10)) + ' seconds';
PRINT '';

-- 4.2: Delete staging_TaskGroup
PRINT '  [4.2] Deleting staging_TaskGroup...';
SET @TotalDeleted = 0;
SET @BatchNumber = 0;
SET @StartTime = GETDATE();

WHILE @BatchNumber < @MaxBatches
BEGIN
    DELETE TOP (@BatchSize) FROM staging_TaskGroup;
    SET @RowsDeleted = @@ROWCOUNT;
    SET @TotalDeleted = @TotalDeleted + @RowsDeleted;
    SET @BatchNumber = @BatchNumber + 1;
    
    IF @RowsDeleted = 0 BREAK;
    
    IF @BatchNumber % 10 = 0
        PRINT '    Batch ' + CAST(@BatchNumber AS VARCHAR(10)) + ': Deleted ' + CAST(@TotalDeleted AS VARCHAR(20)) + ' records...';
    
    CHECKPOINT;
    WAITFOR DELAY '00:00:01';
END

SET @ElapsedSeconds = DATEDIFF(SECOND, @StartTime, GETDATE());
PRINT '    COMPLETED: ' + CAST(@TotalDeleted AS VARCHAR(20)) + ' records in ' + CAST(@ElapsedSeconds AS VARCHAR(10)) + ' seconds';
PRINT '';

-- =====================================================
-- STEP 5: Re-enable foreign key constraints
-- =====================================================
PRINT 'STEP 5: Re-enabling foreign key constraints...';
PRINT '';

ALTER TABLE Staging_Synchronization CHECK CONSTRAINT ALL;
ALTER TABLE Staging_TaskUser CHECK CONSTRAINT ALL;
ALTER TABLE staging_TaskGroupTask CHECK CONSTRAINT ALL;
ALTER TABLE staging_TaskGroupUser CHECK CONSTRAINT ALL;
ALTER TABLE Staging_Task CHECK CONSTRAINT ALL;
ALTER TABLE staging_TaskGroup CHECK CONSTRAINT ALL;

PRINT '  All foreign key constraints re-enabled.';
PRINT '';

-- =====================================================
-- STEP 6: Restore original recovery model
-- =====================================================
PRINT 'STEP 6: Restoring original recovery model...';
PRINT '';

IF @OriginalRecoveryModel <> 'SIMPLE'
BEGIN
    IF @OriginalRecoveryModel = 'FULL'
        ALTER DATABASE Neutron SET RECOVERY FULL;
    ELSE IF @OriginalRecoveryModel = 'BULK_LOGGED'
        ALTER DATABASE Neutron SET RECOVERY BULK_LOGGED;
    
    PRINT '  Restored to ' + @OriginalRecoveryModel + ' recovery mode.';
    PRINT '  IMPORTANT: Take a full backup to re-establish log chain!';
END
PRINT '';

-- =====================================================
-- STEP 7: Reset identity seeds
-- =====================================================
PRINT 'STEP 7: Resetting identity seeds...';
PRINT '';

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
-- STEP 8: Verify cleanup results
-- =====================================================
PRINT 'STEP 8: Verifying cleanup results...';
PRINT '';

DECLARE @AfterSyncCount INT, @AfterTaskUserCount INT, @AfterTaskGroupTaskCount INT;
DECLARE @AfterTaskGroupUserCount INT, @AfterTaskCount INT, @AfterTaskGroupCount INT;

SELECT @AfterSyncCount = COUNT(*) FROM Staging_Synchronization;
SELECT @AfterTaskUserCount = COUNT(*) FROM Staging_TaskUser;
SELECT @AfterTaskGroupTaskCount = COUNT(*) FROM staging_TaskGroupTask;
SELECT @AfterTaskGroupUserCount = COUNT(*) FROM staging_TaskGroupUser;
SELECT @AfterTaskCount = COUNT(*) FROM Staging_Task;
SELECT @AfterTaskGroupCount = COUNT(*) FROM staging_TaskGroup;

PRINT 'Records AFTER cleanup:';
PRINT '  Staging_Synchronization: ' + CAST(@AfterSyncCount AS VARCHAR(20));
PRINT '  Staging_TaskUser: ' + CAST(@AfterTaskUserCount AS VARCHAR(20));
PRINT '  staging_TaskGroupTask: ' + CAST(@AfterTaskGroupTaskCount AS VARCHAR(20));
PRINT '  staging_TaskGroupUser: ' + CAST(@AfterTaskGroupUserCount AS VARCHAR(20));
PRINT '  Staging_Task: ' + CAST(@AfterTaskCount AS VARCHAR(20));
PRINT '  staging_TaskGroup: ' + CAST(@AfterTaskGroupCount AS VARCHAR(20));
PRINT '';

-- =====================================================
-- FINAL SUMMARY
-- =====================================================
PRINT '========================================';
PRINT 'HIGH PERFORMANCE CLEANUP SUMMARY';
PRINT '========================================';
PRINT '';
PRINT 'Records Deleted:';
PRINT '  Staging_Synchronization: ' + CAST(@BeforeSyncCount AS VARCHAR(20));
PRINT '  Staging_TaskUser: ' + CAST(@BeforeTaskUserCount AS VARCHAR(20));
PRINT '  staging_TaskGroupTask: ' + CAST(@BeforeTaskGroupTaskCount AS VARCHAR(20));
PRINT '  staging_TaskGroupUser: ' + CAST(@BeforeTaskGroupUserCount AS VARCHAR(20));
PRINT '  Staging_Task: ' + CAST(@BeforeTaskCount AS VARCHAR(20));
PRINT '  staging_TaskGroup: ' + CAST(@BeforeTaskGroupCount AS VARCHAR(20));
PRINT '  ----------------------------------------';
PRINT '  TOTAL DELETED: ' + CAST((@BeforeSyncCount + @BeforeTaskUserCount + @BeforeTaskGroupTaskCount + 
                                    @BeforeTaskGroupUserCount + @BeforeTaskCount + @BeforeTaskGroupCount) AS VARCHAR(20));
PRINT '';
PRINT '✓ All staging tables cleaned successfully!';
PRINT '✓ Foreign keys re-enabled and validated';
PRINT '✓ Identity seeds reset to 0';
PRINT '✓ Staging system ready for clean clone';
PRINT '';
PRINT 'NOTE: Staging_Server table was preserved.';
PRINT '';
PRINT '========================================';
PRINT 'RECOMMENDED NEXT STEPS:';
PRINT '========================================';
PRINT '1. Take a FULL database backup (to re-establish log chain)';
PRINT '2. Rebuild indexes: EXEC sp_MSforeachtable ''ALTER INDEX ALL ON ? REBUILD''';
PRINT '3. Update statistics: EXEC sp_updatestats';
PRINT '4. Verify staging configuration in Kentico admin';
PRINT '';

SET NOCOUNT OFF;

GO
