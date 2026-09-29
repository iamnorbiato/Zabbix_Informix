SELECT
    CAST(COALESCE(SUM(p.deadlks), 0) AS INT8) AS deadlocks
FROM sysptprof p;