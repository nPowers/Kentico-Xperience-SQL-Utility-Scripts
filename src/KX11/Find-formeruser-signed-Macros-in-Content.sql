-- Find signed macros by former user in page content and web parts
SELECT 'CMS_Document' AS [Pages],  DocumentName, DocumentContent, NodeID, DocumentWebParts
FROM View_cms_Tree_joined
WHERE (
    DocumentContent LIKE '%formeruser%'
)

union all

-- Find signed macros by Tusk in web part properties
SELECT 'WebPartName' AS [Webparts],  WebPartName, WebPartProperties, WebPartID, WebPartfilename
FROM CMS_WebPart
WHERE (
    WebPartProperties LIKE '%formeruser%'

)

union all

-- Find signed macros by Tusk in email templates
SELECT 'EmailTemplateDisplayName' AS [Email Templates], 'CMS_EmailTemplate', EmailTemplateDisplayName, EmailTemplateID, EmailTemplatetext
FROM CMS_EmailTemplate
WHERE EmailTemplatetext LIKE '%formeruser%'

union all

-- Find signed macros by Tusk in transformations
SELECT 'TransformationName' AS [Transformations], 'CMS_Transformation', TransformationName, TransformationID, TransformationCode
FROM CMS_Transformation
WHERE TransformationCode LIKE '%formeruser%'

union all

-- Find signed macros by Tusk in queries
SELECT 'QueryName' AS [Queries], 'CMS_Query', QueryName, QueryID, QueryText
FROM CMS_Query
WHERE QueryText LIKE '%formeruser%'