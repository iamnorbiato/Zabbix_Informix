SELECT FIRST 50
    sysconblock.cbl_sessionid,
    TRIM(syssessions.username) AS username,
    TRIM(syssessions.hostname) AS hostname,
    TRIM(syssessions.feprogram) AS client_program,
    sysconblock.cbl_estrows,
    sysconblock.cbl_estcost,
    sysconblock.cbl_seqscan,
    sysconblock.cbl_tempfile,
    sysconblock.cbl_tempview,
    TRIM(sysconblock.cbl_stmt) AS statement_text
FROM sysconblock, syssessions
WHERE syssessions.sid = sysconblock.cbl_sessionid
  AND sysconblock.cbl_sessionid IS NOT NULL
ORDER BY sysconblock.cbl_estrows DESC, sysconblock.cbl_sessionid;
