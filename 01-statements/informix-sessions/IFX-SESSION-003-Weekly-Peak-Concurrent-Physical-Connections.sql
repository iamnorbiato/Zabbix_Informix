SELECT FIRST 1
    CAST(max_conns AS INT8) AS weekly_peak_concurrent_physical_connections
FROM sysfeatures
WHERE max_conns IS NOT NULL
ORDER BY
    year DESC,
    week DESC;