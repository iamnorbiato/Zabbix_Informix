SELECT
    CAST(COUNT(*) AS INT) AS logical_logs_not_archived
FROM syslogs
WHERE is_archived = 0;
