SELECT
    CAST(COALESCE(SUM(p.lockwts), 0) AS INT8) AS lock_waits
FROM sysptprof p;
