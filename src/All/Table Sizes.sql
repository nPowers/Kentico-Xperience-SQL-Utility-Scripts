SELECT
    t.NAME AS TableName,
    SUM(a.total_pages) * 8 AS TotalSpaceKB,
    SUM(a.used_pages) * 8 AS UsedSpaceKB,
    (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB
FROM sys.tables t
INNER JOIN sys.partitions p ON t.object_id = p.OBJECT_ID
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
GROUP BY t.NAME
ORDER BY TotalSpaceKB DESC;