-- =====================================================
-- Database-Wide Text Search Script
-- Searches for 'tusk' across all text columns in all tables
-- =====================================================

DECLARE @searchTerm NVARCHAR(255) = 'tusk';
DECLARE @sql NVARCHAR(MAX) = '';
DECLARE @currentTable NVARCHAR(255);
DECLARE @currentColumn NVARCHAR(255);
DECLARE @currentSchema NVARCHAR(255);
DECLARE @identityColumn NVARCHAR(255);
DECLARE @tableSql NVARCHAR(MAX);
DECLARE @totalTables INT = 0;
DECLARE @processedTables INT = 0;
DECLARE @startTime DATETIME2 = GETDATE();

-- Create results table to store findings
IF OBJECT_ID('tempdb..#SearchResults') IS NOT NULL DROP TABLE #SearchResults;
CREATE TABLE #SearchResults (
    SchemaName NVARCHAR(128),
    TableName NVARCHAR(128),
    ColumnName NVARCHAR(128),
    IdentityValue NVARCHAR(50),
    TextSnippet NVARCHAR(500),
    FullValue NVARCHAR(MAX),
    FoundAt DATETIME2 DEFAULT GETDATE()
);

-- Create progress tracking table
IF OBJECT_ID('tempdb..#SearchProgress') IS NOT NULL DROP TABLE #SearchProgress;
CREATE TABLE #SearchProgress (
    TableNumber INT,
    SchemaName NVARCHAR(128),
    TableName NVARCHAR(128),
    ColumnCount INT,
    Status NVARCHAR(50),
    ProcessedAt DATETIME2,
    RowsSearched BIGINT DEFAULT 0
);

PRINT '=== DATABASE TEXT SEARCH INITIALIZED ===';
PRINT 'Search Term: ' + @searchTerm;
PRINT 'Started at: ' + CONVERT(VARCHAR, @startTime, 120);
PRINT '';

-- Get all tables with text columns and their identity columns
DECLARE table_cursor CURSOR FOR
SELECT DISTINCT 
    c.TABLE_SCHEMA,
    c.TABLE_NAME,
    COUNT(*) as TextColumnCount
FROM INFORMATION_SCHEMA.COLUMNS c
INNER JOIN INFORMATION_SCHEMA.TABLES t ON c.TABLE_NAME = t.TABLE_NAME AND c.TABLE_SCHEMA = t.TABLE_SCHEMA
WHERE c.DATA_TYPE IN ('varchar', 'nvarchar', 'text', 'ntext', 'char', 'nchar')
    AND t.TABLE_TYPE = 'BASE TABLE'
    AND c.TABLE_SCHEMA NOT IN ('sys', 'INFORMATION_SCHEMA') -- Exclude system schemas
GROUP BY c.TABLE_SCHEMA, c.TABLE_NAME
ORDER BY c.TABLE_SCHEMA, c.TABLE_NAME;

-- Count total tables to process
SELECT @totalTables = COUNT(*)
FROM (
    SELECT DISTINCT c.TABLE_SCHEMA, c.TABLE_NAME
    FROM INFORMATION_SCHEMA.COLUMNS c
    INNER JOIN INFORMATION_SCHEMA.TABLES t ON c.TABLE_NAME = t.TABLE_NAME AND c.TABLE_SCHEMA = t.TABLE_SCHEMA
    WHERE c.DATA_TYPE IN ('varchar', 'nvarchar', 'text', 'ntext', 'char', 'nchar')
        AND t.TABLE_TYPE = 'BASE TABLE'
        AND c.TABLE_SCHEMA NOT IN ('sys', 'INFORMATION_SCHEMA')
) sub;

PRINT 'Total tables to search: ' + CAST(@totalTables AS VARCHAR(10));
PRINT '==========================================';

OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @currentSchema, @currentTable, @totalTables;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @processedTables = @processedTables + 1;
    
    -- Get identity column for this table (if exists)
    SELECT @identityColumn = COLUMN_NAME
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = @currentSchema 
        AND TABLE_NAME = @currentTable
        AND COLUMNPROPERTY(OBJECT_ID(TABLE_SCHEMA + '.' + TABLE_NAME), COLUMN_NAME, 'IsIdentity') = 1;
    
    -- If no identity column, try to find a primary key
    IF @identityColumn IS NULL
    BEGIN
        SELECT TOP 1 @identityColumn = c.COLUMN_NAME
        FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE c
        INNER JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc ON c.CONSTRAINT_NAME = tc.CONSTRAINT_NAME
        WHERE tc.TABLE_SCHEMA = @currentSchema 
            AND tc.TABLE_NAME = @currentTable
            AND tc.CONSTRAINT_TYPE = 'PRIMARY KEY'
        ORDER BY c.ORDINAL_POSITION;
    END
    
    -- If still no key column, use first column as fallback
    IF @identityColumn IS NULL
    BEGIN
        SELECT TOP 1 @identityColumn = COLUMN_NAME
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = @currentSchema AND TABLE_NAME = @currentTable
        ORDER BY ORDINAL_POSITION;
    END

    PRINT 'Processing (' + CAST(@processedTables AS VARCHAR) + '/' + CAST(@totalTables AS VARCHAR) + '): ' 
          + @currentSchema + '.' + @currentTable + ' [Key: ' + ISNULL(@identityColumn, 'None') + ']';

    -- Insert progress record
    INSERT INTO #SearchProgress (TableNumber, SchemaName, TableName, ColumnCount, Status, ProcessedAt)
    VALUES (@processedTables, @currentSchema, @currentTable, 0, 'Processing', GETDATE());

    -- Build dynamic SQL for this table
    SET @tableSql = '';
    
    SELECT @tableSql = @tableSql + 
        CASE WHEN @tableSql = '' THEN '' ELSE ' UNION ALL ' END +
        'SELECT ''' + @currentSchema + ''' as SchemaName, ''' + @currentTable + ''' as TableName, ''' + 
        COLUMN_NAME + ''' as ColumnName, ' +
        'CAST(' + ISNULL(@identityColumn, '''N/A''') + ' AS NVARCHAR(50)) as IdentityValue, ' +
        'CASE WHEN LEN(' + QUOTENAME(COLUMN_NAME) + ') > 200 THEN ' +
        'LEFT(' + QUOTENAME(COLUMN_NAME) + ', CHARINDEX(''' + @searchTerm + ''', ' + QUOTENAME(COLUMN_NAME) + ') + 100) ' +
        'ELSE ' + QUOTENAME(COLUMN_NAME) + ' END as TextSnippet, ' +
        'CAST(' + QUOTENAME(COLUMN_NAME) + ' AS NVARCHAR(MAX)) as FullValue ' +
        'FROM ' + QUOTENAME(@currentSchema) + '.' + QUOTENAME(@currentTable) + ' ' +
        'WHERE ' + QUOTENAME(COLUMN_NAME) + ' LIKE ''%' + @searchTerm + '%'''
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = @currentSchema 
        AND TABLE_NAME = @currentTable
        AND DATA_TYPE IN ('varchar', 'nvarchar', 'text', 'ntext', 'char', 'nchar');

    -- Execute search for this table if we have searchable columns
    IF LEN(@tableSql) > 0
    BEGIN
        BEGIN TRY
            INSERT INTO #SearchResults (SchemaName, TableName, ColumnName, IdentityValue, TextSnippet, FullValue)
            EXEC sp_executesql @tableSql;
            
            UPDATE #SearchProgress 
            SET Status = 'Completed', ProcessedAt = GETDATE()
            WHERE TableNumber = @processedTables;
            
        END TRY
        BEGIN CATCH
            PRINT '  ERROR: ' + ERROR_MESSAGE();
            UPDATE #SearchProgress 
            SET Status = 'Error: ' + LEFT(ERROR_MESSAGE(), 40), ProcessedAt = GETDATE()
            WHERE TableNumber = @processedTables;
        END CATCH
    END
    ELSE
    BEGIN
        UPDATE #SearchProgress 
        SET Status = 'No text columns', ProcessedAt = GETDATE()
        WHERE TableNumber = @processedTables;
    END

    -- Show progress every 10 tables
    IF @processedTables % 10 = 0
    BEGIN
        DECLARE @elapsed INT = DATEDIFF(SECOND, @startTime, GETDATE());
        DECLARE @remaining INT = (@totalTables - @processedTables) * @elapsed / @processedTables;
        PRINT '  Progress: ' + CAST(@processedTables AS VARCHAR) + '/' + CAST(@totalTables AS VARCHAR) + 
              ' (' + CAST((@processedTables * 100 / @totalTables) AS VARCHAR) + '%) - ' +
              'Elapsed: ' + CAST(@elapsed/60 AS VARCHAR) + 'm ' + CAST(@elapsed%60 AS VARCHAR) + 's - ' +
              'Est. remaining: ' + CAST(@remaining/60 AS VARCHAR) + 'm ' + CAST(@remaining%60 AS VARCHAR) + 's';
        
        -- Show current results count
        SELECT @sql = CAST(COUNT(*) AS VARCHAR) FROM #SearchResults;
        PRINT '  Matches found so far: ' + @sql;
        PRINT '';
    END

    FETCH NEXT FROM table_cursor INTO @currentSchema, @currentTable, @totalTables;
END

CLOSE table_cursor;
DEALLOCATE table_cursor;

-- Final Results
DECLARE @endTime DATETIME2 = GETDATE();
DECLARE @totalTime INT = DATEDIFF(SECOND, @startTime, @endTime);

PRINT '==========================================';
PRINT '=== SEARCH COMPLETED ===';
PRINT 'Total time: ' + CAST(@totalTime/60 AS VARCHAR) + ' minutes ' + CAST(@totalTime%60 AS VARCHAR) + ' seconds';
PRINT 'Tables processed: ' + CAST(@processedTables AS VARCHAR);

-- Show summary of findings
SELECT @sql = CAST(COUNT(*) AS VARCHAR) FROM #SearchResults;
PRINT 'Total matches found: ' + @sql;
PRINT '';

-- Display all results
SELECT 
    SchemaName + '.' + TableName AS FullTableName,
    ColumnName,
    IdentityValue as ID,
    LEFT(TextSnippet, 200) as Snippet,
    FoundAt
FROM #SearchResults
ORDER BY SchemaName, TableName, ColumnName;

-- Show detailed results (uncomment if you want full text)
/*
SELECT 
    SchemaName + '.' + TableName AS FullTableName,
    ColumnName,
    IdentityValue as ID,
    FullValue
FROM #SearchResults
ORDER BY SchemaName, TableName, ColumnName;
*/

-- Show processing summary
SELECT 
    SchemaName + '.' + TableName AS FullTableName,
    Status,
    ProcessedAt
FROM #SearchProgress
WHERE Status LIKE 'Error%'
ORDER BY TableNumber;

PRINT 'Search for "' + @searchTerm + '" completed.';