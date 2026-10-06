SELECT FIRST 50
    sql_id,
    sql_sid,
    TRIM(sql_stmtname) AS statement_type,
    sql_lockwttime,
    sql_lockwaits,
    sql_executions,
    sql_totaltime,
    TRIM(SUBSTR(sql_statement, 1, 150)) AS statement_text_preview
FROM syssqltrace
ORDER BY sql_lockwttime DESC, sql_lockwaits DESC, sql_id DESC;
