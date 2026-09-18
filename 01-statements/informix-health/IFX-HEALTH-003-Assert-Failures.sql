SELECT id,
       REPLACE(
           REPLACE(
               REPLACE(TRIM(alert_object_name), CHR(13), ' '),
               CHR(10), ' '
           ),
           '|', ' '
       ) AS object_name,
       alert_object_info,
       alert_time,
       REPLACE(
           REPLACE(
               REPLACE(alert_message, CHR(13), ' '),
               CHR(10), ' '
           ),
           '|', ' '
       ) AS alert_message
FROM ph_alert
WHERE id > {{LAST_ID}}
ORDER BY id;