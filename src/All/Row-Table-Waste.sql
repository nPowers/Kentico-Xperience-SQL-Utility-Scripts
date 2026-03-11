CREATE TABLE #tmpTableSizes (
  tableName varchar(100),
  numberofRows int,
  reservedSize varchar(50),
  dataSize varchar(50),
  indexSize varchar(50),
  unusedSize varchar(50)
)

INSERT #tmpTableSizes
EXEC sp_MSforeachtable @command1="EXEC sp_spaceused '?'"

SELECT * FROM #tmpTableSizes
ORDER BY numberofRows DESC

DROP TABLE #tmpTableSizes
