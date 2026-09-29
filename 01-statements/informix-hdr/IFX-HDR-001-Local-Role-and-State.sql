SELECT
    TRIM(type) AS hdr_type,
    TRIM(state) AS hdr_state,
    NULLIF(TRIM(name), '') AS hdr_peer
FROM sysdri;