SELECT FIRST 50
    sql_id,
    sql_sid,
    TRIM(sql_stmtname) AS statement_type,
    sql_sortdisk,
    sql_sorttotal,
    sql_sortmem,
    sql_executions,
    sql_totaltime,
    TRIM(SUBSTR(sql_statement, 1, 150)) AS statement_text_preview
FROM syssqltrace
ORDER BY sql_sortdisk DESC, sql_sorttotal DESC, sql_id DESC;
