SELECT TOP 25 EventDescription, COUNT(*) AS ErrorCount, Source
FROM CMS_EventLog
WHERE EventType = 'E'
GROUP BY EventDescription, Source
ORDER BY ErrorCount DESC;

