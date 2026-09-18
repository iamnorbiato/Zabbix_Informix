SELECT id
FROM ph_alert
WHERE id > {{LAST_ID}}
ORDER BY id;