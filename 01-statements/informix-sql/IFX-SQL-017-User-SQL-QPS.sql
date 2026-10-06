SELECT
    CAST(COUNT(*) / 60.0 AS DECIMAL(18,4)) AS user_sql_qps
FROM syssqltrace
WHERE sql_finishtime >= DBINFO('utc_current') - 60
  AND TRIM(sql_database) NOT IN ('sysmaster', 'sysadmin')
  AND TRIM(sql_stmtname) NOT IN ('DATABASE', 'SET ISOLATION');
