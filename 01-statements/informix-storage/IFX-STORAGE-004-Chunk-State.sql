SELECT TRIM(d.name) AS dbspace_name, c.chknum, TRIM(c.fname) AS chunk_path, c.is_offline, c.is_recovering, c.is_inconsistent, c.is_extendable FROM sysdbstab d JOIN syschunks c ON c.dbsnum = d.dbsnum;
