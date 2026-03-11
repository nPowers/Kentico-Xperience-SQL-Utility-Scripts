SELECT
    t.NAME AS TableName,
    SUM(p.rows) AS RowCounts,
    SUM(a.total_pages) * 8 AS TotalSpaceKB,
    SUM(a.used_pages) * 8 AS UsedSpaceKB,
    (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB,
    CAST(SUM(a.total_pages) * 8 / 1024.0 AS DECIMAL(18,2)) AS TotalSpaceMB,
    CAST(SUM(a.total_pages) * 8 / 1024.0 / 1024.0 AS DECIMAL(18,2)) AS TotalSpaceGB
FROM sys.tables t 
INNER JOIN sys.partitions p ON t.object_id = p.OBJECT_ID
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id 
WHERE t.name NOT LIKE '%email%'
GROUP BY t.NAME
HAVING SUM(p.rows) > 100000
ORDER BY SUM(p.rows) DESC;