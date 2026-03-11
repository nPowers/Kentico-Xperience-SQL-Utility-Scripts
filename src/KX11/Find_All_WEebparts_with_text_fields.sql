SELECT 
    WebPartID,
    WebPartName,
    WebPartDisplayName,
    WebPartProperties,
    WebPartDescription
FROM CMS_WebPart 
WHERE WebPartProperties IS NOT NULL
    AND (
        WebPartProperties LIKE '%columntype="text"%' OR
        WebPartProperties LIKE '%columntype="longtext"%' OR
        WebPartProperties LIKE '%columntype="htmlarea"%' OR
        WebPartProperties LIKE '%columntype="htmlareacontrol"%' OR
        WebPartProperties LIKE '%size="100"%' OR  -- Often indicates text fields
        WebPartProperties LIKE '%columntype%' AND WebPartProperties LIKE '%text%'
    )
ORDER BY WebPartName;