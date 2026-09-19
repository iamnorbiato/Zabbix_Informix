SELECT
    CAST(value AS INT8) AS lru_write_count
FROM sysprofile
WHERE name = 'lruwrites';