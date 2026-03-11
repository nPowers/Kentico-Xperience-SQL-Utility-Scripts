SELECT 
    mf.FileID,
    mf.FileName,
    mf.FilePath,
    mf.FileSize / 1024.0 / 1024.0 AS FileSizeMB,
    ml.LibraryDisplayName,
    mf.FileCreatedWhen,
    DATEDIFF(day, mf.FileModifiedWhen, GETDATE()) AS DaysSinceModified
    
FROM Media_File mf
    INNER JOIN Media_Library ml ON mf.FileLibraryID = ml.LibraryID
    
WHERE NOT EXISTS (
    -- Not in attachments
    SELECT 1 FROM CMS_Attachment a 
    WHERE a.AttachmentGUID = mf.FileGUID
)
AND NOT EXISTS (
    -- Not in document content (basic check)
    SELECT 1 FROM CMS_Document d 
    WHERE d.DocumentContent LIKE '%' + CAST(mf.FileGUID AS NVARCHAR(50)) + '%'
)
AND NOT EXISTS (
    -- Not in email templates
    SELECT 1 FROM CMS_EmailTemplate et 
    WHERE et.EmailTemplateText LIKE '%' + CAST(mf.FileGUID AS NVARCHAR(50)) + '%'
)
AND mf.FileCreatedWhen < DATEADD(month, -3, GETDATE())

ORDER BY mf.FileSize DESC;