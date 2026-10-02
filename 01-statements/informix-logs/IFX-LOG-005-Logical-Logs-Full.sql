SELECT
    CAST(SUM(CASE WHEN used >= size THEN 1 ELSE 0 END) AS INT) AS logical_logs_full
FROM syslogs;
