SELECT
    CAST(
        COALESCE(
            MAX(
                CASE
                    WHEN TRIM(name) = 'ovlock' THEN value
                END
            ),
            0
        ) AS INT8
    ) AS lock_table_exhaustion_attempts
FROM sysprofile;