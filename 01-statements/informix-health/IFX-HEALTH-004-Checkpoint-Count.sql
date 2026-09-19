SELECT
    CAST(value AS INT8) AS checkpoint_count
FROM sysshmhdr
WHERE name = 'pf_numckpts';