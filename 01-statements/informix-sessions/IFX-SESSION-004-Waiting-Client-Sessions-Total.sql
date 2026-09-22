SELECT
    CAST(COUNT(*) AS INT8) AS waiting_client_sessions
FROM syssessions s
WHERE LENGTH(TRIM(s.hostname)) > 0
  AND s.sid <> DBINFO('sessionid')
  AND (
        s.is_wlatch = 1
     OR s.is_wlock = 1
     OR s.is_wbuff = 1
     OR s.is_wckpt = 1
     OR s.is_wlogbuf = 1
     OR s.is_wtrans = 1
  );