SELECT 
    st.TaskID,
    st.TaskTitle AS Task,
    st.TaskType,
    st.TaskTime,
    stu.UserID AS CreatedByUserID,      -- The numeric User ID  
    u.UserName AS CreatedByUserName,    -- The username from CMS_User lookup
    u.FullName AS CreatedByFullName     -- Full name from CMS_User lookup
FROM Staging_Task st
LEFT JOIN Staging_TaskUser stu ON st.TaskID = stu.TaskID
LEFT JOIN CMS_User u ON stu.UserID = u.UserID
WHERE st.TaskTime >= DATEADD(day, -30, GETDATE())
ORDER BY st.TaskTime DESC;