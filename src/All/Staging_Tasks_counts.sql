SELECT 
    u.UserID,                          -- The numeric User ID
    u.UserName,                        -- The username from CMS_User
    u.FullName,                        -- Full name from CMS_User
    COUNT(st.TaskID) AS TaskCount,
    MAX(st.TaskTime) AS LastTaskTime
FROM Staging_Task st
INNER JOIN Staging_TaskUser stu ON st.TaskID = stu.TaskID
INNER JOIN CMS_User u ON stu.UserID = u.UserID
GROUP BY u.UserID, u.UserName, u.FullName
ORDER BY TaskCount DESC;