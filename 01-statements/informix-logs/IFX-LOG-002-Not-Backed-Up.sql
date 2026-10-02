SELECT
    CAST(COUNT(*) AS INT) AS logical_logs_not_backed_up
FROM syslogs
WHERE is_backed_up = 0;