SELECT FIRST 50
    sql_id,
    sql_sid,
    TRIM(sql_stmtname) AS statement_type,
    sql_runtime,
    sql_executions,
    sql_avgtime,
    sql_maxtime,
    sql_pgreads,
    sql_bfreads,
    sql_pgwrites,
    sql_bfwrites,
    CAST(
        (sql_pgreads + sql_bfreads) /
        NULLIF(sql_pgwrites + sql_bfwrites, 0)
        AS DECIMAL(18,2)
    ) AS read_write_ratio,
    sql_rdcache,
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
    TRIM(SUBSTR(sql_statement, 1, 150)) AS statement_text_preview,
    REPLACE(TRIM(sql_statement), '|', ' ') AS statement_text_full
FROM syssqltrace
WHERE sql_database NOT IN ('sysmaster', 'sysadmin')
  AND sql_stmtname NOT IN ('DATABASE', 'SET ISOLATION')
ORDER BY sql_runtime DESC, sql_id DESC;
