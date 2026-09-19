SELECT FIRST 1
    cp_time AS checkpoint_duration_seconds
FROM syscheckpoint
ORDER BY clock_time DESC;