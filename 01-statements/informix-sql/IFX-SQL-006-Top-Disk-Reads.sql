SELECT FIRST 50
    sql_id,
    sql_sid,
    TRIM(sql_stmtname) AS statement_type,
    sql_pgreads,
    sql_bfreads,
    sql_rdcache,
    sql_executions,
    sql_runtime,
    sql_avgtime,
    sql_maxtime,
    sql_lockwaits,
    sql_lockwttime,
    sql_numiowaits,
    sql_totaliowaits,
    sql_sorttotal,
    sql_sortdisk,
    sql_sortmem,
    sql_estcost,
    sql_estrows,
    sql_actualrows,
    TRIM(sql_database) AS database_name,
    TRIM(SUBSTR(sql_statement, 1, 150)) AS statement_text_preview
FROM syssqltrace
WHERE sql_pgreads IS NOT NULL
ORDER BY sql_pgreads DESC, sql_id DESC;
