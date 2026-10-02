SELECT
    CAST(
        100.0 * pl_phyused / pl_physize
        AS DECIMAL(10,2)
    ) AS physical_log_utilization_percent
FROM sysplog;
