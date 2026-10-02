SELECT TRIM(d.name) AS dbspace_name, c.chknum, c.nfree AS free_pages, CAST((c.nfree * d.pagesize) / 1073741824.0 AS DECIMAL(18,2)) AS free_gb FROM sysdbstab d JOIN syschunks c ON c.dbsnum = d.dbsnum;
