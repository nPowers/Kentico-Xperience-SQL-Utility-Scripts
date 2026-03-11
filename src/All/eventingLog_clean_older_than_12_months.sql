

-- Declare variables for batch processing and reporting
DECLARE @BatchSize INT = 50000;          -- Number of records to delete in each batch
DECLARE @DeletedCount INT = 0;           -- Counter for total records deleted
DECLARE @CurrentBatchCount INT = 0;      -- Counter for records in current batch
DECLARE @StartTime DATETIME = GETDATE(); -- Track when the cleanup started
DECLARE @CutoffDate DATETIME2 = DATEADD(MONTH, -12, GETDATE()); -- Records older than 12 months
DECLARE @TotalRecords INT;               -- To store total record count
DECLARE @RemainingRecords INT;           -- To store remaining record count

-- Get initial count for reporting
SELECT @TotalRecords = COUNT(*) FROM EventingLog;
PRINT 'Starting cleanup of EventingLog table';
PRINT 'Total records before cleanup: ' + CAST(@TotalRecords AS VARCHAR(20));
PRINT 'Cutoff date for deletion: ' + CONVERT(VARCHAR(20), @CutoffDate, 120);
PRINT 'Batch size: ' + CAST(@BatchSize AS VARCHAR(20));
PRINT '---------------------------------------------------';

-- Begin transaction for safety
BEGIN TRANSACTION;

-- Create a loop for batch processing
WHILE 1 = 1
BEGIN
    -- Delete a batch of records and capture the count
    DELETE TOP (@BatchSize)
    FROM EventingLog
    WHERE CreatedDate < @CutoffDate;
    
    -- Get the number of records affected by the last DELETE operation
    SET @CurrentBatchCount = @@ROWCOUNT;
    
    -- If no records were deleted, exit the loop
    IF @CurrentBatchCount = 0
        BREAK;
    
    -- Add to the running total
    SET @DeletedCount = @DeletedCount + @CurrentBatchCount;
    
    -- Print progress after each batch
    PRINT 'Deleted batch: ' + CAST(@CurrentBatchCount AS VARCHAR(20)) + 
          ' records. Total deleted: ' + CAST(@DeletedCount AS VARCHAR(20));
    
    -- Commit the current batch and start a new transaction
    -- This prevents transaction log growth and reduces blocking
    COMMIT TRANSACTION;
    BEGIN TRANSACTION;
    
    -- Optional: Add a small delay to reduce server load
    WAITFOR DELAY '00:00:00.1';
END

-- Commit the final transaction
COMMIT TRANSACTION;

-- Get final count for reporting
SELECT @RemainingRecords = COUNT(*) FROM EventingLog;

-- Print summary information
PRINT '---------------------------------------------------';
PRINT 'Cleanup completed in ' + 
      CAST(DATEDIFF(SECOND, @StartTime, GETDATE()) AS VARCHAR(10)) + 
      ' seconds';
PRINT 'Total records deleted: ' + CAST(@DeletedCount AS VARCHAR(20));
PRINT 'Remaining records: ' + CAST(@RemainingRecords AS VARCHAR(20));
PRINT '---------------------------------------------------';
GO
