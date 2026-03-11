WITH RankedEvents AS (
    SELECT
        LEFT(EventDescription, 60) AS EventDescriptionStart,
        EventUrl,
        EventTime,
        EventID,
        ROW_NUMBER() OVER (
            PARTITION BY LEFT(EventDescription, 60), EventUrl
            ORDER BY EventTime DESC
        ) AS rn,
        EventDescription AS FullEventDescription
    FROM [Neutron].[dbo].[CMS_EventLog]
    WHERE EventType = 'E'
      AND EventDescription LIKE '%macro%'
)
SELECT TOP 2000
    EventDescriptionStart,
    EventUrl,
    EventTime,
    EventID,
    FullEventDescription
FROM RankedEvents
WHERE rn = 1
ORDER BY EventTime DESC