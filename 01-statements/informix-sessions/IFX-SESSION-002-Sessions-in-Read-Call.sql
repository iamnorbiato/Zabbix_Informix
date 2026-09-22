SELECT
    CAST(COUNT(*) AS INT8) AS sessions_in_read_call
FROM syssessions s
WHERE LENGTH(TRIM(s.hostname)) > 0
  AND s.sid <> DBINFO('sessionid')
  AND BITAND(s.state, 32) = 32
  AND (
      s.feprogram IS NULL
      OR TRIM(s.feprogram) NOT MATCHES '*ontape*'
  );