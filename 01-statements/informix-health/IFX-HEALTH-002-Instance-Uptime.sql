SELECT
    CAST(DBINFO('utc_current') - value AS INT8) AS uptime_seconds
FROM sysshmhdr
WHERE name = 'bttime';