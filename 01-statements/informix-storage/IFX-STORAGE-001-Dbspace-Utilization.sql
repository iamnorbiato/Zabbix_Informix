SELECT
    TRIM(d.name) AS dbspace_name,
    CASE
        WHEN LOWER(TRIM(d.name)) LIKE 'temp%' THEN 'TEMPORARY'
        WHEN LOWER(TRIM(d.name)) = 'root_dbs' THEN 'SYSTEM'
        WHEN LOWER(TRIM(d.name)) = 'rootdbs' THEN 'SYSTEM'
        WHEN LOWER(TRIM(d.name)) = 'sysadm_dbs' THEN 'SYSTEM'
        WHEN LOWER(TRIM(d.name)) = 'sysadmin' THEN 'SYSTEM'
        WHEN LOWER(TRIM(d.name)) = 'catal_dbs' THEN 'SYSTEM'
        WHEN LOWER(TRIM(d.name)) LIKE '%phys%' THEN 'PHYSICAL_LOG'
        WHEN LOWER(TRIM(d.name)) LIKE '%log%' THEN 'LOGICAL_LOG'
        ELSE 'APPLICATION'
    END AS dbspace_class,
    SUM(c.chksize) AS total_pages,
    SUM(c.nfree) AS free_pages,
    SUM(c.chksize) - SUM(c.nfree) AS used_pages,
    CAST(100.0 * (SUM(c.chksize) - SUM(c.nfree)) / SUM(c.chksize) AS DECIMAL(10,2)) AS used_percent
FROM sysdbstab d
JOIN syschunks c
    ON c.dbsnum = d.dbsnum
GROUP BY d.name;
