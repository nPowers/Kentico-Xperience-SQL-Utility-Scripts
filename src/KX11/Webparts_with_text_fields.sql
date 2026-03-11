SELECT 
    WebPartID,
    WebPartName,
    WebPartDisplayName,
    WebPartProperties,
    WebPartDescription,
    WebPartFileName,
    WebPartType,
    WebPartCategoryID
FROM CMS_WebPart 
WHERE WebPartProperties IS NOT NULL
    AND (
        WebPartProperties LIKE '%columntype="text"%' OR
        WebPartProperties LIKE '%columntype="longtext"%' OR
        WebPartProperties LIKE '%columntype="htmlarea"%' OR
        WebPartProperties LIKE '%columntype="htmlareacontrol"%' OR
        WebPartProperties LIKE '%size="100"%' OR  -- Often indicates text fields
        WebPartProperties LIKE '%columntype="text"%' AND
        WebPartProperties LIKE '%text%' and
        Webpartproperties NOT LIKE '%columntype="password"%'-- Exclude password fields
        
        -- WebPartProperties NOT LIKE '%columntype="textareacontrol"%' -- Exclude textarea controls
    )
    AND
    (
        webpartfilename NOT LIKE '%'  -- specific cases to exclude 

    )
ORDER BY WebPartName;