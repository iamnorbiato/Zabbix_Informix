SELECT
    CAST(
        100.0 * MAX(CASE WHEN is_current = 1 THEN used ELSE NULL END)
        / MAX(CASE WHEN is_current = 1 THEN size ELSE NULL END)
        AS DECIMAL(10,2)
    ) AS current_log_utilization_percent
FROM syslogs;
