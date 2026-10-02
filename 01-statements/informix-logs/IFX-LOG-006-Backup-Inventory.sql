SELECT
    TRIM(d.name) AS database_name,
    TRIM(s.name) AS dbspace_name,
    CASE
        WHEN s.level0 = 0 THEN -1
        ELSE ROUND((DBINFO('utc_current') - s.level0) / 86400, 1)
    END AS level0_backup_age_days,
    CASE
        WHEN s.level0 = 0 THEN 'Nenhum'
        ELSE DBINFO('utc_to_datetime', s.level0)::VARCHAR(25)
    END AS last_level0,
    CASE
        WHEN s.level1 = 0 THEN 'Nenhum'
        ELSE DBINFO('utc_to_datetime', s.level1)::VARCHAR(25)
    END AS last_level1,
    CASE
        WHEN s.level2 = 0 THEN 'Nenhum'
        ELSE DBINFO('utc_to_datetime', s.level2)::VARCHAR(25)
    END AS last_level2,
    TRIM(c.cf_effective) AS backup_destination
FROM sysdatabases d
JOIN sysdbstab s
    ON s.dbsnum = TRUNC(d.partnum / 1048576)
CROSS JOIN syscfgtab c
WHERE c.cf_name = 'TAPEDEV'
  AND LOWER(TRIM(d.name)) NOT LIKE 'sys%'
  AND LOWER(TRIM(s.name)) NOT LIKE '%temp%'
ORDER BY d.name, s.name;
