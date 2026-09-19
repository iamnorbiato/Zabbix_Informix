SELECT
    CAST(value AS INT8) AS checkpoint_wait_count
FROM sysshmhdr
WHERE name = 'pf_ckptwts';