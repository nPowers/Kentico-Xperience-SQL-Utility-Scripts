-- =============================================
-- Kentico 11 Macro Detection Script
-- Purpose: Find tables containing Kentico macros to optimize exclusion list
-- Author: Development Team
-- Date: 2025-07-28
-- Note: Searches for macro syntax in text fields across all tables
-- =============================================

-- CONFIGURATION
-- =============================================
DECLARE @SampleSize INT = 100  -- Number of recent records to check per table
DECLARE @Debug BIT = 0          -- Set to 1 for detailed debugging output

-- Current exclusions from Functions.cs (update this list as needed)
DECLARE @CurrentExclusions TABLE (ObjectType NVARCHAR(255))
INSERT INTO @CurrentExclusions VALUES 
('eventinglog'),
('cms.email'),
('om.activity'),
('com.orderstatususer'),
('com.orderitem'),
('com.orderaddress'),
('export.task'),
('com.order'),
('om.contact'),
('com.address'),
('om.contactgroupmember'),
('com.customer'),
('cms.user'),
('cms.usersettings'),
('cms.usersite'),
('analytics.hourhits'),
('analytics.dayhits'),
('analytics.weekhits'),
('analytics.monthhits'),
('analytics.yearhits'),
('analytics.statistics'),
('tmp'),
('om.visitortocontact'),
('om.membership'),
('session_territory_joined'),
('cms.webfarmtask'),
('scheduletemplateday'),
('sysdiagrams'),
('temp.file'),
('newsletter.subscribernewsletter'),
('om.abtest'),
('om.abvariant'),
('om.account'),
('om.accountcontact'),
('om.accountstatus'),
('om.activityrecalculationqueue'),
('om.contactrole'),
('om.contactstatus'),
('om.contactchangerecalculationqueue'),
('media.libraryrolepermission'),
('messaging.contactlist'),
('messaging.ignorelist'),
('messaging.message'),
('newsletter.abtest'),
('newsletter.emails'),
('newsletter.emailwidget'),
('newsletter.emailwidgettemplate'),
('newsletter.issuecontactgroup'),
('personas.personanode'),
('polls.poll'),
('polls.pollanswer'),
('polls.pollroles'),
('polls.pollsite'),
('om.scorecontactrule'),
('om.mvtcombinationvariation'),
('om.mvtest'),
('om.mvtvariant'),
('om.personalizationvariant'),
('sharepoint.sharepointconnection'),
('sharepoint.sharepointfile'),
('sharepoint.sharepointlibrary'),
('sm.facebookaccount'),
('sm.facebookapplication'),
('sm.facebookpost'),
('sm.insight'),
('sm.insighthit_day'),
('sm.insighthit_month'),
('sm.insighthit_week'),
('sm.insighthit_year'),
('sm.linkedinaccount'),
('sm.linkedinapplication'),
('sm.linkedinpost'),
('sm.twitteraccount'),
('sm.twitterapplication'),
('sm.twitterpost'),
('content.simplearticle'),
('custom.htmlsnippet'),
('events.attendee'),
('forums.attachment'),
('forums.forum'),
('forums.forumgroup'),
('forums.forummoderators'),
('forums.forumpost'),
('forums.forumroles'),
('forums.forumsubscription'),
('forums.userfavorites'),
('integration.connector'),
('integration.synchronization'),
('integration.synclog'),
('integration.task'),
('com.variantoption'),
('com.volumediscount'),
('com.wishlist'),
('community.friend'),
('community.group'),
('community.groupmember'),
('community.grouprolepermission'),
('community.invitation'),
('content.article'),
('content.blog'),
('content.blogmonth'),
('content.blogpost'),
('content.bookingevent'),
('content.event'),
('content.imagegallery'),
('content.job'),
('content.kbarticle'),
('content.news'),
('content.office'),
('content.pressrelease'),
('com.orderitemskufile'),
('com.shippingcost'),
('com.shippingoption'),
('com.skufile'),
('com.supplier'),
('analytics.campaignasseturl'),
('analytics.campaignobjective'),
('analytics.conversion'),
('analytics.exitpages'),
('blog.comment'),
('blog.postsubscription'),
('board.board'),
('board.message'),
('board.moderator'),
('board.role'),
('board.subscription'),
('chat.initiatedchatrequest'),
('chat.message'),
('chat.notification'),
('chat.onlinesupport'),
('chat.onlineuser'),
('chat.popupwindowsettings'),
('chat.room'),
('chat.roomuser'),
('chat.supportcannedresponse'),
('chat.supporttakenroom'),
('chat.user'),
('ci.filemetadata'),
('ci.migration'),
('cms.abusereport'),
('cms.bannedip'),
('cms.banner'),
('cms.bannercategory'),
('cms.automationhistory'),
('cms.automationstate'),
('cms.documenttypescopeclass'),
('cms.externallogin'),
('cms.emailuser'),
('cms.formrole'),
('cms.documenttag'),
('cms.consent'),
('cms.consentagreement'),
('cms.consentarchive'),
('cms.resourcelibrary'),
('cms.searchindex'),
('cms.searchindexculture'),
('cms.searchindexsite'),
('cms.searchtask'),
('cms.membership'),
('cms.membershiprole'),
('cms.membershipuser'),
('cms.modulelicensekey'),
('cms.moduleusagecounter'),
('cms.objectworkflowtrigger'),
('cms.openiduser'),
('cms.userculture'),
('cms.smtpserver'),
('cms.smtpserversite'),
('cms.tag'),
('cms.taggroup'),
('cms.webfarmservertask'),
('com.manufacturer'),
('com.multibuydiscountbrand'),
('com.multibuydiscountcollection'),
('com.exchangetable'),
('com.currencyexchangerate'),
('com.carrier'),
('com.brand'),
('cms.workflowuser'),
('cms.workflowsteproles'),
('cms.workflowstepuser')

-- Kentico 11 macro patterns to search for
DECLARE @MacroPatterns TABLE (
    PatternName NVARCHAR(50),
    Pattern NVARCHAR(255),
    Description NVARCHAR(500)
)

INSERT INTO @MacroPatterns VALUES
('Standard Macro', '{%[^%]*%}', 'Standard Kentico macro syntax {%...%}'),
('Unsigned Macro', '{%[^%]*@%}', 'Unsigned macro with @ symbol'),
('Legacy Macro', '{#[^#]*#}', 'Legacy macro syntax (converted to ProcessCustomMacro)'),
('ProcessCustomMacro', 'ProcessCustomMacro', 'Converted legacy macro function'),
('CurrentDocument', 'CurrentDocument', 'Common macro object'),
('CurrentUser', 'CurrentUser', 'Common macro object'),
('CurrentSite', 'CurrentSite', 'Common macro object'),
('DocumentContext', 'DocumentContext', 'Common macro context'),
('Eval Expression', 'Eval(', 'Macro evaluation function'),
('HTML Encode', 'HTMLEncode(', 'Macro encoding function'),
('URL Encode', 'UrlEncode(', 'Macro encoding function')

PRINT 'KENTICO 11 MACRO DETECTION ANALYSIS'
PRINT '===================================='
PRINT 'Sample Size: ' + CAST(@SampleSize AS NVARCHAR(10)) + ' recent records per table'
PRINT 'Current Date: ' + CONVERT(NVARCHAR(19), GETDATE(), 120)
PRINT ''

-- Results table to store findings
CREATE TABLE #MacroFindings (
    SchemaName NVARCHAR(128),
    TableName NVARCHAR(128),
    ColumnName NVARCHAR(128),
    ColumnType NVARCHAR(128),
    RecordsChecked INT,
    MacrosFound INT,
    MacroTypes NVARCHAR(500),
    SampleMacro NVARCHAR(1000),
    ObjectType NVARCHAR(255),
    HasIdentity BIT,
    LastModifiedColumn NVARCHAR(128),
    RecommendedAction NVARCHAR(50)
)

-- STEP 1: IDENTIFY ALL CANDIDATE TABLES AND COLUMNS
-- =============================================

PRINT 'STEP 1: IDENTIFYING CANDIDATE TABLES AND COLUMNS'
PRINT '================================================='

DECLARE @SQL NVARCHAR(MAX)
DECLARE @TableSchema NVARCHAR(128)
DECLARE @TableName NVARCHAR(128) 
DECLARE @ColumnName NVARCHAR(128)
DECLARE @ColumnType NVARCHAR(128)
DECLARE @HasIdentity BIT
DECLARE @IdentityColumn NVARCHAR(128)
DECLARE @LastModifiedColumn NVARCHAR(128)

-- Cursor to iterate through all text-based columns in all tables
DECLARE table_cursor CURSOR FOR
SELECT 
    s.name as SchemaName,
    t.name as TableName,
    c.name as ColumnName,
    ty.name as ColumnType,
    CASE WHEN EXISTS (
        SELECT 1 FROM sys.columns ic 
        WHERE ic.object_id = t.object_id AND ic.is_identity = 1
    ) THEN 1 ELSE 0 END as HasIdentity
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE ty.name IN ('nvarchar', 'varchar', 'ntext', 'text', 'xml')  -- Text-based columns
    AND c.max_length > 50  -- Skip short columns unlikely to contain macros
    AND t.name NOT LIKE 'sys%'  -- Skip system tables
    AND t.name NOT LIKE '#%'    -- Skip temp tables
    -- Skip known large data tables that definitely don't contain macros
    AND t.name NOT IN ('CMS_EventLog', 'CMS_WebAnalyticsData', 'CMS_SearchIndex')
ORDER BY s.name, t.name, c.name

OPEN table_cursor
FETCH NEXT FROM table_cursor INTO @TableSchema, @TableName, @ColumnName, @ColumnType, @HasIdentity

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Find identity column for ordering
    SELECT @IdentityColumn = c.name 
    FROM sys.columns c 
    WHERE c.object_id = OBJECT_ID(@TableSchema + '.' + @TableName) 
        AND c.is_identity = 1
    
    -- Find LastModified column (common Kentico pattern)
    SET @LastModifiedColumn = NULL
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(@TableSchema + '.' + @TableName) AND name LIKE '%LastModified')
    BEGIN
        SELECT @LastModifiedColumn = name 
        FROM sys.columns 
        WHERE object_id = OBJECT_ID(@TableSchema + '.' + @TableName) 
            AND name LIKE '%LastModified'
    END
    
    -- Determine ObjectType (Kentico naming convention)
    DECLARE @ObjectType NVARCHAR(255) = LOWER(@TableSchema + '.' + @TableName)
    IF @TableName LIKE 'CMS_%'
        SET @ObjectType = LOWER('cms.' + SUBSTRING(@TableName, 5, LEN(@TableName)))
    
    -- Build dynamic SQL to search for macros in this column
    SET @SQL = '
    DECLARE @MacroCount INT = 0
    DECLARE @RecordsChecked INT = 0
    DECLARE @MacroTypes NVARCHAR(500) = ''''
    DECLARE @SampleMacro NVARCHAR(1000) = ''''
    
    -- Get sample of recent records to check
    SELECT TOP (' + CAST(@SampleSize AS NVARCHAR(10)) + ')
        [' + @ColumnName + ']
    FROM [' + @TableSchema + '].[' + @TableName + ']
    WHERE [' + @ColumnName + '] IS NOT NULL 
        AND LEN([' + @ColumnName + ']) > 10'
    
    -- Add ordering by identity or LastModified if available
    IF @IdentityColumn IS NOT NULL
        SET @SQL = @SQL + ' ORDER BY [' + @IdentityColumn + '] DESC'
    ELSE IF @LastModifiedColumn IS NOT NULL
        SET @SQL = @SQL + ' ORDER BY [' + @LastModifiedColumn + '] DESC'
    
    -- Complete the dynamic SQL
    SET @SQL = @SQL + '
    
    -- Check each record for macro patterns
    DECLARE @Content NVARCHAR(MAX)
    DECLARE content_cursor CURSOR FOR 
    SELECT [' + @ColumnName + '] FROM [' + @TableSchema + '].[' + @TableName + ']
    WHERE [' + @ColumnName + '] IS NOT NULL AND LEN([' + @ColumnName + ']) > 10'
    
    IF @IdentityColumn IS NOT NULL
        SET @SQL = @SQL + ' ORDER BY [' + @IdentityColumn + '] DESC'
    ELSE IF @LastModifiedColumn IS NOT NULL
        SET @SQL = @SQL + ' ORDER BY [' + @LastModifiedColumn + '] DESC'
        
    SET @SQL = @SQL + '
    
    OPEN content_cursor
    FETCH NEXT FROM content_cursor INTO @Content
    
    WHILE @@FETCH_STATUS = 0 AND @RecordsChecked < ' + CAST(@SampleSize AS NVARCHAR(10)) + '
    BEGIN
        SET @RecordsChecked = @RecordsChecked + 1
        
        -- Check for various macro patterns
        IF @Content LIKE ''%{%[^%]%}%'' OR @Content LIKE ''%{#%#}%'' OR 
           @Content LIKE ''%ProcessCustomMacro%'' OR @Content LIKE ''%CurrentDocument%'' OR
           @Content LIKE ''%CurrentUser%'' OR @Content LIKE ''%CurrentSite%'' OR
           @Content LIKE ''%DocumentContext%'' OR @Content LIKE ''%Eval(%'' OR
           @Content LIKE ''%HTMLEncode(%'' OR @Content LIKE ''%UrlEncode(%''
        BEGIN
            SET @MacroCount = @MacroCount + 1
            
            -- Capture sample macro if we don''t have one yet
            IF @SampleMacro = ''''
            BEGIN
                SET @SampleMacro = LEFT(@Content, 200)
            END
            
            -- Identify macro types found
            IF @Content LIKE ''%{%[^%]%}%'' AND @MacroTypes NOT LIKE ''%Standard%''
                SET @MacroTypes = @MacroTypes + ''Standard,''
            IF @Content LIKE ''%{#%#}%'' AND @MacroTypes NOT LIKE ''%Legacy%''
                SET @MacroTypes = @MacroTypes + ''Legacy,''
            IF @Content LIKE ''%ProcessCustomMacro%'' AND @MacroTypes NOT LIKE ''%ProcessCustomMacro%''
                SET @MacroTypes = @MacroTypes + ''ProcessCustomMacro,''
            IF @Content LIKE ''%CurrentDocument%'' AND @MacroTypes NOT LIKE ''%CurrentDocument%''
                SET @MacroTypes = @MacroTypes + ''CurrentDocument,''
            IF @Content LIKE ''%CurrentUser%'' AND @MacroTypes NOT LIKE ''%CurrentUser%''
                SET @MacroTypes = @MacroTypes + ''CurrentUser,''
        END
        
        FETCH NEXT FROM content_cursor INTO @Content
    END
    
    CLOSE content_cursor
    DEALLOCATE content_cursor
    
    -- Insert results
    INSERT INTO #MacroFindings 
    VALUES (''' + @TableSchema + ''', ''' + @TableName + ''', ''' + @ColumnName + ''', ''' + @ColumnType + ''',
            @RecordsChecked, @MacroCount, @MacroTypes, @SampleMacro, ''' + @ObjectType + ''', ' + CAST(@HasIdentity AS NVARCHAR(1)) + ',
            ' + CASE WHEN @LastModifiedColumn IS NOT NULL THEN '''' + @LastModifiedColumn + '''' ELSE 'NULL' END + ',
            CASE 
                WHEN @MacroCount > 0 THEN ''INCLUDE''
                WHEN @RecordsChecked = 0 THEN ''SKIP - NO DATA''
                ELSE ''EXCLUDE''
            END)'
    
    -- Execute the dynamic SQL
    BEGIN TRY
        EXEC sp_executesql @SQL
        
        IF @Debug = 1
            PRINT 'Checked: ' + @TableSchema + '.' + @TableName + '.' + @ColumnName
            
    END TRY
    BEGIN CATCH
        PRINT 'Error checking ' + @TableSchema + '.' + @TableName + '.' + @ColumnName + ': ' + ERROR_MESSAGE()
    END CATCH
    
    FETCH NEXT FROM table_cursor INTO @TableSchema, @TableName, @ColumnName, @ColumnType, @HasIdentity
END

CLOSE table_cursor
DEALLOCATE table_cursor

-- STEP 2: ANALYZE RESULTS
-- =============================================

PRINT ''
PRINT 'STEP 2: ANALYSIS RESULTS'
PRINT '========================'

PRINT ''
PRINT 'TABLES WITH MACROS FOUND:'
PRINT '========================='
SELECT 
    SchemaName + '.' + TableName as FullTableName,
    ObjectType,
    COUNT(*) as ColumnsWithMacros,
    SUM(MacrosFound) as TotalMacrosFound,
    STRING_AGG(ColumnName + '(' + CAST(MacrosFound AS NVARCHAR(10)) + ')', ', ') as ColumnsAffected
FROM #MacroFindings 
WHERE MacrosFound > 0
GROUP BY SchemaName, TableName, ObjectType
ORDER BY SUM(MacrosFound) DESC

-- Force display of results by also using PRINT statements
DECLARE @TableCount INT = 0
DECLARE @CursorTableName NVARCHAR(255), @CursorObjectType NVARCHAR(255), @CursorMacroCount INT

SELECT @TableCount = COUNT(DISTINCT SchemaName + '.' + TableName)
FROM #MacroFindings 
WHERE MacrosFound > 0

PRINT 'Found ' + CAST(@TableCount AS NVARCHAR(10)) + ' tables containing macros:'

DECLARE macro_tables_cursor CURSOR FOR
SELECT DISTINCT 
    SchemaName + '.' + TableName,
    ObjectType,
    SUM(MacrosFound)
FROM #MacroFindings 
WHERE MacrosFound > 0
GROUP BY SchemaName, TableName, ObjectType
ORDER BY SUM(MacrosFound) DESC

OPEN macro_tables_cursor
FETCH NEXT FROM macro_tables_cursor INTO @CursorTableName, @CursorObjectType, @CursorMacroCount
WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT '  - ' + @CursorTableName + ' (' + @CursorObjectType + ') - ' + CAST(@CursorMacroCount AS NVARCHAR(10)) + ' macros found'
    FETCH NEXT FROM macro_tables_cursor INTO @CursorTableName, @CursorObjectType, @CursorMacroCount
END
CLOSE macro_tables_cursor
DEALLOCATE macro_tables_cursor

PRINT ''
PRINT 'TABLES WITH NO MACROS (CANDIDATES FOR EXCLUSION):'
PRINT '=================================================='
SELECT 
    SchemaName + '.' + TableName as FullTableName,
    ObjectType,
    COUNT(*) as ColumnsChecked,
    SUM(RecordsChecked) as TotalRecordsChecked,
    'ADD TO EXCLUSION LIST' as Recommendation
FROM #MacroFindings 
WHERE MacrosFound = 0 AND RecordsChecked > 0
    AND ObjectType NOT IN (SELECT ObjectType FROM @CurrentExclusions)
GROUP BY SchemaName, TableName, ObjectType
ORDER BY ObjectType

-- Also print the exclusion candidates
DECLARE @ExcludeTableName NVARCHAR(255), @ExcludeObjectType NVARCHAR(255)

SELECT @TableCount = COUNT(DISTINCT SchemaName + '.' + TableName)
FROM #MacroFindings 
WHERE MacrosFound = 0 AND RecordsChecked > 0
    AND ObjectType NOT IN (SELECT ObjectType FROM @CurrentExclusions)

PRINT 'Found ' + CAST(@TableCount AS NVARCHAR(10)) + ' additional tables that can be excluded:'

DECLARE exclusion_cursor CURSOR FOR
SELECT DISTINCT 
    SchemaName + '.' + TableName,
    ObjectType
FROM #MacroFindings 
WHERE MacrosFound = 0 AND RecordsChecked > 0
    AND ObjectType NOT IN (SELECT ObjectType FROM @CurrentExclusions)
GROUP BY SchemaName, TableName, ObjectType
ORDER BY ObjectType

OPEN exclusion_cursor
FETCH NEXT FROM exclusion_cursor INTO @ExcludeTableName, @ExcludeObjectType
WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT '  - ' + @ExcludeTableName + ' (' + @ExcludeObjectType + ')'
    FETCH NEXT FROM exclusion_cursor INTO @ExcludeTableName, @ExcludeObjectType
END
CLOSE exclusion_cursor
DEALLOCATE exclusion_cursor

PRINT ''
PRINT 'SUGGESTED EXCLUSIONS FOR Functions.cs:'
PRINT '======================================'
PRINT 'Add these to your GetHardcodedMacroExclusions() method:'
PRINT ''

-- Print each exclusion line
DECLARE @SuggestionText NVARCHAR(500)
DECLARE suggestion_cursor CURSOR FOR
SELECT 
    '"' + ObjectType + '",           // No macros found in ' + CAST(COUNT(*) AS NVARCHAR(10)) + ' columns, ' + CAST(SUM(RecordsChecked) AS NVARCHAR(10)) + ' records checked'
FROM #MacroFindings 
WHERE MacrosFound = 0 AND RecordsChecked > 0
    AND ObjectType NOT IN (SELECT ObjectType FROM @CurrentExclusions)
GROUP BY ObjectType
ORDER BY ObjectType

OPEN suggestion_cursor
FETCH NEXT FROM suggestion_cursor INTO @SuggestionText
WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT '            ' + @SuggestionText
    FETCH NEXT FROM suggestion_cursor INTO @SuggestionText
END
CLOSE suggestion_cursor
DEALLOCATE suggestion_cursor

PRINT ''
PRINT 'DETAILED FINDINGS BY COLUMN:'
PRINT '============================'
SELECT 
    SchemaName + '.' + TableName as FullTableName,
    ColumnName,
    ColumnType,
    RecordsChecked,
    MacrosFound,
    MacroTypes,
    RecommendedAction,
    LEFT(SampleMacro, 100) + CASE WHEN LEN(SampleMacro) > 100 THEN '...' ELSE '' END as SampleMacro
FROM #MacroFindings
ORDER BY MacrosFound DESC, FullTableName, ColumnName

PRINT ''
PRINT 'SUMMARY STATISTICS:'
PRINT '=================='
SELECT 
    COUNT(*) as TotalColumnsChecked,
    SUM(RecordsChecked) as TotalRecordsChecked,
    SUM(MacrosFound) as TotalMacrosFound,
    COUNT(CASE WHEN MacrosFound > 0 THEN 1 END) as ColumnsWithMacros,
    COUNT(CASE WHEN MacrosFound = 0 AND RecordsChecked > 0 THEN 1 END) as CandidatesForExclusion
FROM #MacroFindings

-- STEP 3: GENERATE EXCLUSION CODE
-- =============================================

PRINT ''
PRINT 'STEP 3: GENERATED CODE FOR Functions.cs'
PRINT '========================================'
PRINT 'Replace your GetHardcodedMacroExclusions() method with:'
PRINT ''
PRINT '/// <summary>'
PRINT '/// Gets hardcoded list of object types to exclude from macro signature checking'
PRINT '/// These are typically large data tables that don''t contain macros -NP'
PRINT '/// Auto-generated on ' + CONVERT(NVARCHAR(19), GETDATE(), 120) + ''
PRINT '/// </summary>'
PRINT '/// <returns>Collection of object type names to exclude</returns>'
PRINT 'public static IEnumerable<string> GetHardcodedMacroExclusions()'
PRINT '{'
PRINT '    return new List<string>'
PRINT '    {'

-- Include current exclusions
SELECT '        "' + ObjectType + '",           // Previously excluded'
FROM @CurrentExclusions

-- Add new exclusions found
SELECT 
    '        "' + ObjectType + '",           // No macros found - auto-detected ' + CONVERT(NVARCHAR(19), GETDATE(), 120)
FROM #MacroFindings 
WHERE MacrosFound = 0 AND RecordsChecked > 0
    AND ObjectType NOT IN (SELECT ObjectType FROM @CurrentExclusions)
GROUP BY ObjectType
ORDER BY ObjectType

PRINT '        // TODO: Review and verify these exclusions are appropriate -NP'
PRINT '    };'
PRINT '}'

-- Cleanup
DROP TABLE #MacroFindings

PRINT ''
PRINT 'MACRO DETECTION ANALYSIS COMPLETED!'
PRINT 'Generated exclusion list should significantly improve macro signing performance.'