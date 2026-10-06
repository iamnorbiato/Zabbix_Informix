SELECT FIRST 50
    c.cbl_sessionid,
    TRIM(s.username) AS username,
    TRIM(s.hostname) AS hostname,
    TRIM(s.feprogram) AS client_program,
    c.cbl_ismainblock,
    c.cbl_estcost,
    c.cbl_estrows,
    c.cbl_seqscan,
    c.cbl_tempfile,
    c.cbl_tempview,
    TRIM(c.cbl_stmt) AS statement_text
FROM sysconblock c, syssessions s
WHERE s.sid = c.cbl_sessionid
  AND c.cbl_sessionid IS NOT NULL
ORDER BY c.cbl_estcost DESC, c.cbl_sessionid;
