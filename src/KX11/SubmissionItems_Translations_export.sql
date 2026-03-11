-- This will generate the complete script including IDENTITY_INSERT statements
SELECT 
    CASE 
        WHEN ROW_NUMBER() OVER (ORDER BY tsi.SubmissionItemID) = 1 
        THEN 'SET IDENTITY_INSERT [dbo].[CMS_TranslationSubmissionItem] ON' + CHAR(13) + CHAR(13)
        ELSE ''
    END +
    'INSERT INTO [dbo].[CMS_TranslationSubmissionItem] (' + CHAR(13) +
    '    [SubmissionItemID], [SubmissionItemSubmissionID], [SubmissionItemSourceXLIFF], [SubmissionItemTargetXLIFF],' + CHAR(13) +
    '    [SubmissionItemObjectType], [SubmissionItemObjectID], [SubmissionItemGUID], [SubmissionItemLastModified],' + CHAR(13) +
    '    [SubmissionItemName], [SubmissionItemWordCount], [SubmissionItemCharCount], [SubmissionItemCustomData],' + CHAR(13) +
    '    [SubmissionItemTargetObjectID], [SubmissionItemType], [SubmissionItemTargetCulture])' + CHAR(13) +
    'VALUES (' + CHAR(13) +
    '    ' + CAST(tsi.SubmissionItemID AS VARCHAR(10)) + ', ' + 
    CAST(tsi.SubmissionItemSubmissionID AS VARCHAR(10)) + ', ' +
    CASE WHEN tsi.SubmissionItemSourceXLIFF IS NULL THEN 'NULL' 
         WHEN LEN(tsi.SubmissionItemSourceXLIFF) > 8000 THEN 'NULL -- XLIFF TOO LARGE, COPY MANUALLY' 
         ELSE '''' + REPLACE(REPLACE(REPLACE(tsi.SubmissionItemSourceXLIFF, '''', ''''''), CHAR(13), ''), CHAR(10), '') + '''' END + ', ' +
    CASE WHEN tsi.SubmissionItemTargetXLIFF IS NULL THEN 'NULL' 
         WHEN LEN(tsi.SubmissionItemTargetXLIFF) > 8000 THEN 'NULL -- XLIFF TOO LARGE, COPY MANUALLY'
         ELSE '''' + REPLACE(REPLACE(REPLACE(tsi.SubmissionItemTargetXLIFF, '''', ''''''), CHAR(13), ''), CHAR(10), '') + '''' END + ', ''' +
    tsi.SubmissionItemObjectType + ''', ' +
    CAST(tsi.SubmissionItemObjectID AS VARCHAR(10)) + ', ''' +
    CAST(tsi.SubmissionItemGUID AS VARCHAR(36)) + ''', ''' +
    CONVERT(VARCHAR(23), tsi.SubmissionItemLastModified, 121) + ''', ''' +
    REPLACE(tsi.SubmissionItemName, '''', '''''') + ''', ' +
    CASE WHEN tsi.SubmissionItemWordCount IS NULL THEN 'NULL' ELSE CAST(tsi.SubmissionItemWordCount AS VARCHAR(10)) END + ', ' +
    CASE WHEN tsi.SubmissionItemCharCount IS NULL THEN 'NULL' ELSE CAST(tsi.SubmissionItemCharCount AS VARCHAR(10)) END + ', ' +
    CASE WHEN tsi.SubmissionItemCustomData IS NULL THEN 'NULL' 
         WHEN LEN(tsi.SubmissionItemCustomData) > 4000 THEN 'NULL -- CUSTOM DATA TOO LARGE'
         ELSE '''' + REPLACE(tsi.SubmissionItemCustomData, '''', '''''') + '''' END + ', ' +
    CAST(tsi.SubmissionItemTargetObjectID AS VARCHAR(10)) + ', ' +
    CASE WHEN tsi.SubmissionItemType IS NULL THEN 'NULL' ELSE '''' + tsi.SubmissionItemType + '''' END + ', ' +
    CASE WHEN tsi.SubmissionItemTargetCulture IS NULL THEN 'NULL' ELSE '''' + tsi.SubmissionItemTargetCulture + '''' END + ');' + CHAR(13) +
    CASE 
        WHEN ROW_NUMBER() OVER (ORDER BY tsi.SubmissionItemID) = COUNT(*) OVER ()
        THEN CHAR(13) + 'SET IDENTITY_INSERT [dbo].[CMS_TranslationSubmissionItem] OFF' + CHAR(13)
        ELSE ''
    END AS ExportScript
FROM CMS_TranslationSubmissionItem tsi
INNER JOIN CMS_TranslationSubmission ts ON tsi.SubmissionItemSubmissionID = ts.SubmissionID
WHERE ts.SubmissionStatus IN (0, 1, 2) -- Adjust as needed
AND ts.SubmissionServiceID = 10
ORDER BY tsi.SubmissionItemID