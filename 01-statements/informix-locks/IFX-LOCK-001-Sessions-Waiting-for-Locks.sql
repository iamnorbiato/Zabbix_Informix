SELECT
    CAST(COUNT(DISTINCT l.waiter) AS INT8) AS sessions_waiting_for_locks
FROM syslocks l
INNER JOIN syssessions s
    ON s.sid = l.waiter
WHERE l.waiter > 0
  AND s.sid <> DBINFO('sessionid')
  AND LENGTH(TRIM(s.hostname)) > 0;
