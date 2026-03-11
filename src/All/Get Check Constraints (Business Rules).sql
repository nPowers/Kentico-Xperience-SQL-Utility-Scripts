-- Query 4A: Check Constraints (Business Rules)
SELECT 
    SCHEMA_NAME(t.schema_id) AS SchemaName,
    t.name AS TableName,
    cc.name AS ConstraintName,
    cc.definition AS ConstraintDefinition,
    cc.is_disabled AS IsDisabled
FROM sys.tables t
INNER JOIN sys.check_constraints cc ON t.object_id = cc.parent_object_id
ORDER BY t.name, cc.name;