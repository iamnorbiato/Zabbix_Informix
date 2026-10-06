SELECT FIRST 50
    sql_id,
    sql_sid,
    TRIM(sql_stmtname) AS statement_type,
    sql_actualrows,
    sql_estrows,
    sql_estcost,
    sql_executions,
    sql_totaltime,
    TRIM(SUBSTR(sql_statement, 1, 150)) AS statement_text_preview
FROM syssqltrace
ORDER BY sql_actualrows DESC, sql_estrows DESC, sql_id DESC;
