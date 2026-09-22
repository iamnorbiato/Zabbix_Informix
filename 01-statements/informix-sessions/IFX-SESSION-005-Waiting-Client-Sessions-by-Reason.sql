SELECT
    'LATCH' AS dimension_id,
    'Waiting client sessions - latch' AS dimension_name,
    CAST(COUNT(*) AS INT8) AS waiting_client_sessions
FROM syssessions s
WHERE LENGTH(TRIM(s.hostname)) > 0
  AND s.sid <> DBINFO('sessionid')
  AND s.is_wlatch = 1

UNION ALL

SELECT
    'LOCK' AS dimension_id,
    'Waiting client sessions - lock' AS dimension_name,
    CAST(COUNT(*) AS INT8) AS waiting_client_sessions
FROM syssessions s
WHERE LENGTH(TRIM(s.hostname)) > 0
  AND s.sid <> DBINFO('sessionid')
  AND s.is_wlock = 1

UNION ALL

SELECT
    'BUFFER' AS dimension_id,
    'Waiting client sessions - buffer' AS dimension_name,
    CAST(COUNT(*) AS INT8) AS waiting_client_sessions
FROM syssessions s
WHERE LENGTH(TRIM(s.hostname)) > 0
  AND s.sid <> DBINFO('sessionid')
  AND s.is_wbuff = 1

UNION ALL

SELECT
    'CHECKPOINT' AS dimension_id,
    'Waiting client sessions - checkpoint' AS dimension_name,
    CAST(COUNT(*) AS INT8) AS waiting_client_sessions
FROM syssessions s
WHERE LENGTH(TRIM(s.hostname)) > 0
  AND s.sid <> DBINFO('sessionid')
  AND s.is_wckpt = 1

UNION ALL

SELECT
    'LOG_BUFFER' AS dimension_id,
    'Waiting client sessions - log buffer' AS dimension_name,
    CAST(COUNT(*) AS INT8) AS waiting_client_sessions
FROM syssessions s
WHERE LENGTH(TRIM(s.hostname)) > 0
  AND s.sid <> DBINFO('sessionid')
  AND s.is_wlogbuf = 1

UNION ALL

SELECT
    'TRANSACTION' AS dimension_id,
    'Waiting client sessions - transaction' AS dimension_name,
    CAST(COUNT(*) AS INT8) AS waiting_client_sessions
FROM syssessions s
WHERE LENGTH(TRIM(s.hostname)) > 0
  AND s.sid <> DBINFO('sessionid')
  AND s.is_wtrans = 1;