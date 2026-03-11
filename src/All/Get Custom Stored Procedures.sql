-- Query 5A: Custom Stored Procedures
SELECT 
    SCHEMA_NAME(p.schema_id) AS SchemaName,
    p.name AS ProcedureName,
    p.create_date AS CreatedDate,
    p.modify_date AS ModifiedDate,
    CASE 
        WHEN p.name LIKE 'sp_Custom%' THEN 'Custom - Named'
        WHEN p.name LIKE 'sp_%' AND p.name NOT LIKE 'sp_help%' AND p.name NOT LIKE 'sp_MS%' THEN 'Likely Custom'
        ELSE 'System'
    END AS ProcType
FROM sys.procedures p
WHERE p.is_ms_shipped = 0  -- Exclude system procedures
ORDER BY ProcType, p.name;