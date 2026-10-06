SELECT FIRST 50
    TRIM(owner) AS table_owner,
    TRIM(tabname) AS table_name,
    ustlowts,
    nrows,
    npused
FROM systables
WHERE tabtype = 'T'
  AND TRIM(tabname) NOT MATCHES 'sys*'
ORDER BY ustlowts ASC, owner, tabname;
