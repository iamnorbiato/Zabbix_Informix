SELECT
    CAST(COALESCE(SUM(p.lktouts), 0) AS INT8) AS lock_timeouts
FROM sysptprof p;
