SELECT 17 AS id,
       '6' AS object_name,
       6300 AS object_info,
       CURRENT AS alert_time,
       'Synthetic HEALTH-003 assertion event' AS alert_message
FROM systables
WHERE tabid = 1
  AND {{LAST_ID}} < 17
ORDER BY id;