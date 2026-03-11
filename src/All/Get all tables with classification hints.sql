-- Query 1A: Get all tables with classification hints
SELECT 
    TABLE_SCHEMA,
    TABLE_NAME,
    CASE 
        WHEN TABLE_NAME LIKE 'CMS_%' THEN 'Kentico Core'
        WHEN TABLE_NAME LIKE 'COM_%' THEN 'Kentico Commerce'
        WHEN TABLE_NAME LIKE 'Chat_%' THEN 'Kentico Chat'
        WHEN TABLE_NAME LIKE 'Forums_%' THEN 'Kentico Forums'
        WHEN TABLE_NAME LIKE 'Media_%' THEN 'Kentico Media'
        WHEN TABLE_NAME LIKE 'Newsletter_%' THEN 'Kentico Newsletter'
        WHEN TABLE_NAME LIKE 'Polls_%' THEN 'Kentico Polls'
        WHEN TABLE_NAME LIKE 'Reporting_%' THEN 'Kentico Reporting'
        WHEN TABLE_NAME LIKE 'Staging_%' THEN 'Kentico Staging'
        WHEN TABLE_NAME LIKE 'Custom%' THEN 'Custom - Named'
        ELSE 'Likely Custom'
    END AS TableType,
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = t.TABLE_NAME) AS ColumnCount
FROM INFORMATION_SCHEMA.TABLES t
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TableType, TABLE_NAME;