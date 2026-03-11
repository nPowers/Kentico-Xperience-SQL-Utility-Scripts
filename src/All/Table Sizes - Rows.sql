SELECT 
    sch.NAME AS [Schema],
    tab.NAME AS [Table],
    CASE
        WHEN par.INDEX_ID = 0 THEN 'Heap'
        WHEN par.INDEX_ID = 1 THEN 'Clustered Index'
    END AS [Index Type],
    SUM(par.rows) AS [Rows]
FROM 
    sys.tables tab
    INNER JOIN sys.partitions par ON tab.OBJECT_ID = par.OBJECT_ID
    INNER JOIN sys.schemas sch ON tab.SCHEMA_ID = sch.SCHEMA_ID
WHERE 
    par.INDEX_ID < 2
GROUP BY 
    sch.NAME, tab.NAME, par.INDEX_ID
ORDER BY 
    SUM(par.rows) DESC
