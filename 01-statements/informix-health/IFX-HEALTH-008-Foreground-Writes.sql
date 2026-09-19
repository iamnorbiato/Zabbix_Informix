SELECT
    CAST(value AS INT8) AS foreground_write_count
FROM sysprofile
WHERE name = 'fgwrites';