SELECT COUNT(*) FROM zbx_ifx_session_test_lock;
SELECT FIRST 100 id, note
FROM zbx_ifx_session_test_lock
ORDER BY id DESC;
SELECT id, note
FROM zbx_ifx_session_test_lock
ORDER BY note;
