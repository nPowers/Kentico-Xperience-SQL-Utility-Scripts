SELECT TOP 10 EventDescription, COUNT(*) AS ErrorCount, Source, MAX(EventTime) AS LastOccurrence
FROM CMS_EventLog
WHERE EventType = 'E'
GROUP BY EventDescription, Source
ORDER BY LastOccurrence DESC;