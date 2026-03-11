SELECT TOP 10
    CASE
        WHEN LEN(EventDescription) > 80 THEN SUBSTRING(EventDescription, 1, 77) + '...'
        ELSE EventDescription
    END AS TruncatedDescription,
    COUNT(*) AS ErrorCount,
    Source,
    MAX(EventTime) AS LastOccurrence
FROM CMS_EventLog
WHERE EventType = 'E'
GROUP BY EventDescription, Source
ORDER BY LastOccurrence DESC;
