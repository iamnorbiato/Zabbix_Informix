SELECT COUNT(*) FROM systables;
SELECT FIRST 100 tabid, TRIM(tabname)
FROM systables
ORDER BY tabid DESC;
SELECT owner, COUNT(*)
FROM systables
GROUP BY owner
ORDER BY COUNT(*) DESC;
