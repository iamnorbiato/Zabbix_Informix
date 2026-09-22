SELECT
    CAST(COUNT(*) AS INT8) AS total_connected_sessions
FROM syssessions s,
     syssessions collector_session
WHERE collector_session.sid = DBINFO('sessionid')
  AND LENGTH(TRIM(s.hostname)) > 0
  AND s.sid <> DBINFO('sessionid')
  AND (
      s.feprogram IS NULL
      OR TRIM(s.feprogram) NOT MATCHES '*ontape*'
  )
  AND NOT (
      TRIM(s.hostname) = TRIM(collector_session.hostname)
      AND s.feprogram IS NOT NULL
      AND TRIM(s.feprogram) MATCHES '*/dbaccess'
  );