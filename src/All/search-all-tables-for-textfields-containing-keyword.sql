-- =====================================================
-- Database-Wide Text Search Script (Enhanced)
-- Searches for text across specified tables or all tables
-- =====================================================

-- *** CONFIGURATION SECTION ***

-- =====================================================
-- Database-Wide Text Search Script (SQL Server Compatible)
-- Searches for text across specified tables or all tables
-- =====================================================

-- *** CONFIGURATION SECTION ***
DECLARE @searchTerm NVARCHAR(255) = 'tusk';
DECLARE @specificTables NVARCHAR(MAX) = 'Analytics_Campaign,Analytics_CampaignAsset,Analytics_CampaignConversion,Analytics_CampaignConversionHits,APSSubmissions,BadWords_Word,BadWords_WordCulture,CMS_ACL,CMS_ACLItem,CMS_AllowedChildClasses,CMS_AlternativeForm,CMS_Attachment,CMS_AttachmentForEmail,CMS_AttachmentHistory,CMS_Avatar,CMS_Badge,CMS_Category,CMS_Class,CMS_ClassSite,CMS_Country,CMS_CssStylesheet,CMS_CssStylesheetSite,CMS_Culture,CMS_DeviceProfile,CMS_DeviceProfileLayout,CMS_Document,CMS_DocumentAlias,CMS_DocumentCategory,CMS_DocumentTypeScope,CMS_EmailAttachment,CMS_EmailTemplate,CMS_Form,CMS_FormUserControl,CMS_HelpTopic,CMS_Layout,CMS_LicenseKey,CMS_MacroIdentity,CMS_MacroRule,CMS_MetaFile,CMS_ObjectSettings,CMS_ObjectVersionHistory,CMS_PageTemplate,CMS_PageTemplateCategory,CMS_PageTemplateScope,CMS_PageTemplateSite,CMS_Permission,CMS_Personalization,CMS_Query,CMS_Relationship,CMS_RelationshipName,CMS_RelationshipNameSite,CMS_Resource,CMS_ResourceSite,CMS_ResourceString,CMS_ResourceTranslation,CMS_Role,CMS_RoleApplication,CMS_RolePermission,CMS_RoleUIElement,CMS_ScheduledTask,CMS_SearchEngine,CMS_SearchTaskAzure,CMS_Session,CMS_SettingsCategory,CMS_SettingsKey,CMS_Site,CMS_SiteCulture,CMS_SiteDomainAlias,CMS_State,CMS_TemplateDeviceLayout,CMS_TimeZone,CMS_Transformation,CMS_TranslationService,CMS_TranslationSubmission,CMS_TranslationSubmissionItem,CMS_Tree,CMS_UIElement,CMS_UserMacroIdentity,CMS_UserRole,CMS_VersionAttachment,CMS_VersionHistory,CMS_WebFarmServer,CMS_WebFarmServerLog,CMS_WebFarmServerMonitoring,CMS_WebFarmTask,CMS_WebPart,CMS_WebPartCategory,CMS_WebPartContainer,CMS_WebPartContainerSite,CMS_WebPartLayout,CMS_WebTemplate,CMS_Widget,CMS_WidgetCategory,CMS_WidgetRole,CMS_Workflow,CMS_WorkflowAction,CMS_WorkflowHistory,CMS_WorkflowScope,CMS_WorkflowStep,CMS_WorkflowTransition,COM_Bundle,COM_Collection,COM_Currency,COM_CustomerCreditHistory,COM_Department,COM_Discount,COM_GiftCard,COM_GiftCardCouponCode,COM_InternalStatus,COM_MultiBuyDiscount,COM_MultiBuyDiscountDepartment,COM_MultiBuyDiscountSKU,COM_MultiBuyDiscountTree,COM_OptionCategory,COM_OrderStatus,COM_OrderType,COM_PaymentOption,COM_PublicStatus,COM_ShoppingCartCouponCode,COM_SKU,COM_SKUAllowedOption,COM_SKUOptionCategory,COM_TaxClass,COM_TaxClassCountry,COM_TaxClassState,CONTENT_FAQ,CONTENT_File,CONTENT_MenuItem,CONTENT_Product'; -- Empty = search all tables
-- Example: 'cms_eventlog,cms_user,cms_document,table4,table5'

-- *** END CONFIGURATION ***

DECLARE @sql NVARCHAR(MAX) = '';
DECLARE @currentTable NVARCHAR(255);
DECLARE @currentColumn NVARCHAR(255);
DECLARE @currentSchema NVARCHAR(255);
DECLARE @identityColumn NVARCHAR(255);
DECLARE @tableSql NVARCHAR(MAX);
DECLARE @totalTables INT = 0;
DECLARE @processedTables INT = 0;
DECLARE @startTime DATETIME2 = GETDATE();
DECLARE @searchMode NVARCHAR(20);

-- Determine search mode
IF LEN(LTRIM(RTRIM(@specificTables))) > 0
    SET @searchMode = 'SPECIFIC';
ELSE
    SET @searchMode = 'ALL';

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

-- Create table list for specific tables (if specified)
IF OBJECT_ID('tempdb..#SpecificTables') IS NOT NULL DROP TABLE #SpecificTables;
CREATE TABLE #SpecificTables (
    TableName NVARCHAR(128),
    SchemaName NVARCHAR(128),
    TableExists BIT DEFAULT 0
);

PRINT '=== DATABASE TEXT SEARCH INITIALIZED ===';
PRINT 'Search Term: ' + @searchTerm;
PRINT 'Search Mode: ' + @searchMode;
PRINT 'Started at: ' + CONVERT(VARCHAR, @startTime, 120);

-- Process specific tables list if provided
IF @searchMode = 'SPECIFIC'
BEGIN
    PRINT 'Specified Tables: ' + @specificTables;
    
    -- Parse the comma-delimited list manually (compatible with older SQL Server)
    DECLARE @pos INT = 1;
    DECLARE @nextPos INT;
    DECLARE @tableName NVARCHAR(128);
    DECLARE @schemaName NVARCHAR(128);
    
    WHILE @pos <= LEN(@specificTables)
    BEGIN
        SET @nextPos = CHARINDEX(',', @specificTables, @pos);
        IF @nextPos = 0
            SET @nextPos = LEN(@specificTables) + 1;
        
        SET @tableName = LTRIM(RTRIM(SUBSTRING(@specificTables, @pos, @nextPos - @pos)));
        
        IF LEN(@tableName) > 0
        BEGIN
            -- Handle schema-qualified table names
            IF CHARINDEX('.', @tableName) > 0
            BEGIN
                SET @schemaName = LEFT(@tableName, CHARINDEX('.', @tableName) - 1);
                SET @tableName = RIGHT(@tableName, LEN(@tableName) - CHARINDEX('.', @tableName));
            END
            ELSE
            BEGIN
                SET @schemaName = 'dbo';
            END
            
            INSERT INTO #SpecificTables (TableName, SchemaName) 
            VALUES (@tableName, @schemaName);
        END
        
        SET @pos = @nextPos + 1;
    END
    
    -- Validate that specified tables exist and have text columns
    UPDATE st
    SET TableExists = 1
    FROM #SpecificTables st
    WHERE EXISTS (
        SELECT 1 
        FROM INFORMATION_SCHEMA.TABLES t
        INNER JOIN INFORMATION_SCHEMA.COLUMNS c ON t.TABLE_NAME = c.TABLE_NAME AND t.TABLE_SCHEMA = c.TABLE_SCHEMA
        WHERE t.TABLE_NAME = st.TableName 
            AND t.TABLE_SCHEMA = st.SchemaName
            AND t.TABLE_TYPE = 'BASE TABLE'
            AND c.DATA_TYPE IN ('varchar', 'nvarchar', 'text', 'ntext', 'char', 'nchar')
    );
    
    -- Show validation results
    PRINT '';
    PRINT '=== TABLE VALIDATION ===';
    
    DECLARE validation_cursor CURSOR FOR
    SELECT 
        CASE WHEN SchemaName = 'dbo' THEN TableName ELSE SchemaName + '.' + TableName END,
        CASE WHEN TableExists = 1 THEN 'FOUND' ELSE 'NOT FOUND OR NO TEXT COLUMNS' END
    FROM #SpecificTables
    ORDER BY TableName;
    
    DECLARE @tableNameDisplay NVARCHAR(256), @statusDisplay NVARCHAR(50);
    OPEN validation_cursor;
    FETCH NEXT FROM validation_cursor INTO @tableNameDisplay, @statusDisplay;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT @tableNameDisplay + ': ' + @statusDisplay;
        FETCH NEXT FROM validation_cursor INTO @tableNameDisplay, @statusDisplay;
    END
    
    CLOSE validation_cursor;
    DEALLOCATE validation_cursor;
    
    SELECT @totalTables = COUNT(*) FROM #SpecificTables WHERE TableExists = 1;
    PRINT '';
    PRINT 'Valid tables to search: ' + CAST(@totalTables AS VARCHAR(10));
    
    IF @totalTables = 0
    BEGIN
        PRINT 'ERROR: No valid tables found to search!';
        RETURN;
    END
END
ELSE
BEGIN
    -- Count total tables for full database search
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
END

PRINT '==========================================';

-- Define cursor based on search mode
DECLARE table_cursor CURSOR FOR
SELECT DISTINCT 
    c.TABLE_SCHEMA,
    c.TABLE_NAME,
    COUNT(*) as TextColumnCount
FROM INFORMATION_SCHEMA.COLUMNS c
INNER JOIN INFORMATION_SCHEMA.TABLES t ON c.TABLE_NAME = t.TABLE_NAME AND c.TABLE_SCHEMA = t.TABLE_SCHEMA
LEFT JOIN #SpecificTables st ON c.TABLE_NAME = st.TableName AND c.TABLE_SCHEMA = st.SchemaName
WHERE c.DATA_TYPE IN ('varchar', 'nvarchar', 'text', 'ntext', 'char', 'nchar')
    AND t.TABLE_TYPE = 'BASE TABLE'
    AND ((@searchMode = 'ALL' AND c.TABLE_SCHEMA NOT IN ('sys', 'INFORMATION_SCHEMA'))
         OR (@searchMode = 'SPECIFIC' AND st.TableExists = 1))
GROUP BY c.TABLE_SCHEMA, c.TABLE_NAME
ORDER BY c.TABLE_SCHEMA, c.TABLE_NAME;

OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @currentSchema, @currentTable, @totalTables;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @processedTables = @processedTables + 1;
    SET @identityColumn = NULL;
    
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
        'SUBSTRING(' + QUOTENAME(COLUMN_NAME) + ', CHARINDEX(''' + @searchTerm + ''', ' + QUOTENAME(COLUMN_NAME) + '), 200) ' +
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

    -- Show progress
    IF @searchMode = 'SPECIFIC' OR @processedTables % 10 = 0
    BEGIN
        DECLARE @elapsed INT = DATEDIFF(SECOND, @startTime, GETDATE());
        DECLARE @remaining INT = CASE WHEN @processedTables > 0 
                                     THEN (@totalTables - @processedTables) * @elapsed / @processedTables 
                                     ELSE 0 END;
        PRINT '  Progress: ' + CAST(@processedTables AS VARCHAR) + '/' + CAST(@totalTables AS VARCHAR) + 
              ' (' + CAST((@processedTables * 100 / @totalTables) AS VARCHAR) + '%)';
        
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
PRINT 'Search Mode: ' + @searchMode;
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

-- Show processing summary for errors
SELECT 
    SchemaName + '.' + TableName AS FullTableName,
    Status,
    ProcessedAt
FROM #SearchProgress
WHERE Status LIKE 'Error%'
ORDER BY TableNumber;

-- Cleanup
IF OBJECT_ID('tempdb..#SpecificTables') IS NOT NULL DROP TABLE #SpecificTables;

PRINT 'Search for "' + @searchTerm + '" completed.';