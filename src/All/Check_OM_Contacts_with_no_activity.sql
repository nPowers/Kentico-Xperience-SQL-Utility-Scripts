SELECT (COUNT(*)) AS [Count]
FROM (
  SELECT *
     FROM OM_Contact
     WHERE (([ContactEmail] = N'' OR [ContactEmail] IS NULL) AND (EXISTS (
          SELECT TOP 1 [ActivityContactID]
          FROM OM_Activity
          WHERE [ActivityContactID] = [ContactID]
          GROUP BY ActivityContactID
          HAVING MAX(ActivityCreated) <= '1/14/2023 2:00:20 AM'
    ) 
    OR ([ContactCreated] < '1/14/2023 2:00:20 AM' AND NOT EXISTS (
         SELECT TOP 1 [ActivityContactID]
         FROM OM_Activity
         WHERE [ActivityContactID] = [ContactID]
   ))))
) AS SubData