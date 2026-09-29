SELECT
    TRIM(name) AS server_name,
    TRIM(role) AS server_role,
    TRIM(nodetype) AS node_type,
    TRIM(server_status) AS server_status,
    NULLIF(TRIM(connection_status), '') AS connection_status
FROM syscluster;