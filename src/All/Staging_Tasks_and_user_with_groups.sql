SELECT 
    st.TaskID,
    st.TaskTitle AS Task,
    st.TaskType,
    st.TaskObjectType,
    st.TaskTime,
    stu.UserID AS TaskUserID,          -- The numeric User ID
    u.UserName AS TaskUserName,        -- The username from CMS_User lookup
    u.FullName AS TaskUserFullName,    -- Full name from CMS_User lookup
    stg.TaskGroupCodeName,
    CASE 
        WHEN st.TaskRunning = 1 THEN 'Running'
        ELSE 'Completed'
    END AS TaskStatus
FROM Staging_Task st
LEFT JOIN Staging_TaskUser stu ON st.TaskID = stu.TaskID
LEFT JOIN CMS_User u ON stu.UserID = u.UserID
LEFT JOIN Staging_TaskGroupTask stgt ON st.TaskID = stgt.TaskID
LEFT JOIN Staging_TaskGroup stg ON stgt.TaskGroupID = stg.TaskGroupID
ORDER BY st.TaskTime DESC, st.TaskID DESC;