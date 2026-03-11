SELECT 
    'SET IDENTITY_INSERT [dbo].[CMS_TranslationSubmission] ON' + CHAR(13) +
    'INSERT INTO [dbo].[CMS_TranslationSubmission] (' + CHAR(13) +
    '    [SubmissionID], [SubmissionName], [SubmissionTicket], [SubmissionStatus],' + CHAR(13) +
    '    [SubmissionServiceID], [SubmissionSourceCulture], [SubmissionTargetCulture], [SubmissionPriority],' + CHAR(13) +
    '    [SubmissionDeadline], [SubmissionInstructions], [SubmissionLastModified], [SubmissionGUID],' + CHAR(13) +
    '    [SubmissionSiteID], [SubmissionPrice], [SubmissionStatusMessage], [SubmissionTranslateAttachments],' + CHAR(13) +
    '    [SubmissionItemCount], [SubmissionDate], [SubmissionWordCount], [SubmissionCharCount],' + CHAR(13) +
    '    [SubmissionSubmittedByUserID])' + CHAR(13) +
    'VALUES (' + CHAR(13) +
    '    ' + CAST(SubmissionID AS VARCHAR(10)) + ', ''' + 
    REPLACE(SubmissionName, '''', '''''') + ''', ' +
    CASE WHEN SubmissionTicket IS NULL THEN 'NULL' ELSE '''' + REPLACE(SubmissionTicket, '''', '''''') + '''' END + ', ' +
    CAST(SubmissionStatus AS VARCHAR(10)) + ', ' +
    CAST(SubmissionServiceID AS VARCHAR(10)) + ', ''' +
    SubmissionSourceCulture + ''', ''' +
    REPLACE(SubmissionTargetCulture, '''', '''''') + ''', ' +
    CAST(SubmissionPriority AS VARCHAR(10)) + ', ' +
    CASE WHEN SubmissionDeadline IS NULL THEN 'NULL' ELSE '''' + CONVERT(VARCHAR(23), SubmissionDeadline, 121) + '''' END + ', ' +
    CASE WHEN SubmissionInstructions IS NULL THEN 'NULL' ELSE '''' + REPLACE(SubmissionInstructions, '''', '''''') + '''' END + ', ''' +
    CONVERT(VARCHAR(23), SubmissionLastModified, 121) + ''', ''' +
    CAST(SubmissionGUID AS VARCHAR(36)) + ''', ' +
    CASE WHEN SubmissionSiteID IS NULL THEN 'NULL' ELSE CAST(SubmissionSiteID AS VARCHAR(10)) END + ', ' +
    CASE WHEN SubmissionPrice IS NULL THEN 'NULL' ELSE CAST(SubmissionPrice AS VARCHAR(20)) END + ', ' +
    CASE WHEN SubmissionStatusMessage IS NULL THEN 'NULL' ELSE '''' + REPLACE(SubmissionStatusMessage, '''', '''''') + '''' END + ', ' +
    CASE WHEN SubmissionTranslateAttachments IS NULL THEN 'NULL' ELSE CAST(SubmissionTranslateAttachments AS VARCHAR(1)) END + ', ' +
    CAST(SubmissionItemCount AS VARCHAR(10)) + ', ''' +
    CONVERT(VARCHAR(23), SubmissionDate, 121) + ''', ' +
    CASE WHEN SubmissionWordCount IS NULL THEN 'NULL' ELSE CAST(SubmissionWordCount AS VARCHAR(10)) END + ', ' +
    CASE WHEN SubmissionCharCount IS NULL THEN 'NULL' ELSE CAST(SubmissionCharCount AS VARCHAR(10)) END + ', ' +
    CASE WHEN SubmissionSubmittedByUserID IS NULL THEN 'NULL' ELSE CAST(SubmissionSubmittedByUserID AS VARCHAR(10)) END + ');' + CHAR(13) AS ExportScript
FROM CMS_TranslationSubmission 
WHERE SubmissionStatus IN (0, 1, 2) -- Adjust status values as needed for "pending" translations
AND SubmissionServiceID = 10 -- Manual translation service
ORDER BY SubmissionID