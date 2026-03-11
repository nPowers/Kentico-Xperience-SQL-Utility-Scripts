SELECT 
    wp.WebPartID,
    wp.WebPartName,
    wp.WebPartDisplayName,
    wp.WebPartProperties,
    wp.WebPartDescription,
    wp.WebPartFileName,
    wp.WebPartType,
    -- Map WebPartType to text
    CASE wp.WebPartType
        WHEN 1 THEN 'Standard'
        WHEN 2 THEN 'Inherited'
        WHEN 3 THEN 'Widget'
        ELSE 'Unknown'
    END AS WebPartTypeText,
    wp.WebPartCategoryID,
    cat.CategoryDisplayName AS WebPartCategoryDisplayName
FROM CMS_WebPart wp
LEFT JOIN CMS_WebPartCategory cat ON wp.WebPartCategoryID = cat.CategoryID
WHERE wp.WebPartProperties IS NOT NULL
    AND (
        wp.WebPartProperties LIKE '%columntype="text"%' OR
        wp.WebPartProperties LIKE '%columntype="longtext"%' OR
        wp.WebPartProperties LIKE '%columntype="htmlarea"%' OR
        wp.WebPartProperties LIKE '%columntype="htmlareacontrol"%' OR
        wp.WebPartProperties LIKE '%size="100"%' OR
        (wp.WebPartProperties LIKE '%columntype="text"%' AND
         wp.WebPartProperties LIKE '%text%' AND
         wp.WebPartProperties NOT LIKE '%columntype="password"%')
    )
    AND (wp.WebPartFileName NOT LIKE 'Cady%')
ORDER BY wp.WebPartName;
