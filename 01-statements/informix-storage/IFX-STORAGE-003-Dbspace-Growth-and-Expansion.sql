SELECT TRIM(d.name) AS dbspace_name, d.extend_size, d.max_size, c.chknum, c.is_extendable, c.chksize, TRIM(c.fname) AS chunk_path FROM sysdbstab d JOIN syschunks c ON c.dbsnum = d.dbsnum;
