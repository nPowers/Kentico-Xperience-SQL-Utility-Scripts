SELECT 
    st.TaskID,
    st.TaskTitle AS Task,
    st.TaskType,
    st.TaskTime,
    stu.UserID AS AssignedUserID,       -- The numeric User ID
    u.UserName AS AssignedUserName,     -- The username from CMS_User lookup
    u.FullName AS AssignedUserFullName, -- Full name from CMS_User lookup
    u.Email AS AssignedUserEmail        -- Email from CMS_User lookup
FROM Staging_Task st
INNER JOIN Staging_TaskUser stu ON st.TaskID = stu.TaskID
INNER JOIN CMS_User u ON stu.UserID = u.UserID
ORDER BY st.TaskTime ASC, st.TaskID DESC;