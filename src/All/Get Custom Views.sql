-- Query 5B: Custom Views
SELECT 
    SCHEMA_NAME(v.schema_id) AS SchemaName,
    v.name AS ViewName,
    v.create_date AS CreatedDate,
    v.modify_date AS ModifiedDate,
    CASE 
        WHEN v.name LIKE 'v_Custom%' OR v.name LIKE 'vw_Custom%' THEN 'Custom - Named'
        WHEN v.name LIKE 'View_%' THEN 'Kentico'
        ELSE 'Likely Custom'
    END AS ViewType
FROM sys.views v
WHERE v.is_ms_shipped = 0
ORDER BY ViewType, v.name;