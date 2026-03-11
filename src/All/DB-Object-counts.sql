SELECT 
    CASE type
        WHEN 'U' THEN 'Tables'
        WHEN 'P' THEN 'Stored Procedures'
        WHEN 'V' THEN 'Views'
    END AS ObjectType,
    COUNT(*) AS TotalCount
FROM 
    sys.objects
WHERE 
    type IN ('U', 'P', 'V')
GROUP BY 
    type
