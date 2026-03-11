WITH CleanedEvents AS (
    SELECT *,
        -- Remove the prefix if present
        CASE
            WHEN EventDescription LIKE 'Error while evaluating expression: %'
                THEN SUBSTRING(EventDescription, LEN('Error while evaluating expression: ') + 1, LEN(EventDescription))
            ELSE EventDescription
        END AS EventDescriptionNoPrefix
    FROM [Neutron].[dbo].[CMS_EventLog]
    WHERE EventType = 'E'
      AND EventDescription LIKE '%macro%'
),
PreUrlDesc AS (
    SELECT *,
        PATINDEX('%http%?%', EventDescriptionNoPrefix) AS UrlStartPos
    FROM CleanedEvents
),
TrimmedDesc AS (
    SELECT *,
        -- Extract only the part before the URL with '?', or the full description if not found
        CASE 
            WHEN UrlStartPos > 0 
                THEN LEFT(EventDescriptionNoPrefix, UrlStartPos - 1)
            ELSE EventDescriptionNoPrefix
        END AS EventDescriptionTrimmed,
        -- Remove anything after '?' in EventUrl
        CASE 
            WHEN CHARINDEX('?', EventUrl) > 0
                THEN LEFT(EventUrl, CHARINDEX('?', EventUrl) - 1)
            ELSE EventUrl
        END AS EventUrlTrimmed
    FROM PreUrlDesc
),
RankedEvents AS (
    SELECT
        LEFT(EventDescriptionTrimmed, 60) AS EventDescriptionCompare,
        EventDescriptionTrimmed AS EventDescription,
        EventUrlTrimmed,
        EventTime,
        EventID,
        ROW_NUMBER() OVER (
            PARTITION BY LEFT(EventDescriptionTrimmed, 60), EventUrlTrimmed
            ORDER BY EventTime DESC
        ) AS rn
    FROM TrimmedDesc
)
SELECT TOP 2000
    EventDescriptionCompare,
    EventDescription,
    EventUrlTrimmed AS EventUrl,
    EventTime,
    EventID
FROM RankedEvents
WHERE rn = 1
ORDER BY EventTime DESC
