
--Convert date strings to datetime.
UPDATE BavarianLodge.dbo.holidays
SET Date = REPLACE(Date, Date, CAST(Date AS datetime));

UPDATE BavarianLodge.dbo.input_variables
SET Date = REPLACE(Date, Date, CAST(Date AS datetime));


--Create intermediate table with holidays.
SELECT
	b.Friendly AS holiday_friendly,
	b.[Holiday Code] AS holiday_code,
	b.Type AS holiday_type,
	a.*
INTO BavarianLodge.dbo.temp1
FROM BavarianLodge.dbo.input_variables AS a
LEFT JOIN BavarianLodge.dbo.holidays AS b
ON a.date = b.Date;

--Create holiday flag column
ALTER TABLE BavarianLodge.dbo.temp1
	ADD is_holiday AS (CASE WHEN holiday_code IS NOT NULL THEN '1' ELSE '0' END);

--Check output
--SELECT TOP 100* FROM BavarianLodge.dbo.temp1;

--Create holiday +/-5 days date range
SELECT date
INTO BavarianLodge.dbo.temp2
FROM BavarianLodge.dbo.temp1
WHERE holiday_code IS NOT NULL;

 SELECT date
 INTO BavarianLodge.dbo.temp3
 FROM BavarianLodge.dbo.temp1
 WHERE date IN (
	(SELECT DATEADD(day, 1, date) FROM BavarianLodge.dbo.temp2) UNION ALL
	(SELECT DATEADD(day, -1, date) FROM BavarianLodge.dbo.temp2) UNION ALL
	(SELECT DATEADD(day, 2, date) FROM BavarianLodge.dbo.temp2) UNION ALL
	(SELECT DATEADD(day, -2, date) FROM BavarianLodge.dbo.temp2) UNION ALL
	(SELECT DATEADD(day, 3, date) FROM BavarianLodge.dbo.temp2) UNION ALL
	(SELECT DATEADD(day, -3, date) FROM BavarianLodge.dbo.temp2) UNION ALL
	(SELECT DATEADD(day, 4, date) FROM BavarianLodge.dbo.temp2) UNION ALL
	(SELECT DATEADD(day, -4, date) FROM BavarianLodge.dbo.temp2) UNION ALL
	(SELECT DATEADD(day, 5, date) FROM BavarianLodge.dbo.temp2) UNION ALL
	(SELECT DATEADD(day, -5, date) FROM BavarianLodge.dbo.temp2)
	);

--Create holiday_5 column

SELECT
	'1' AS holiday_5,
	*
INTO BavarianLodge.dbo.temp4
FROM BavarianLodge.dbo.temp1 WHERE date IN (SELECT date FROM BavarianLodge.dbo.temp3);

--Add holiday_5 column to temp5

SELECT
	a.*,
	holiday_5 = CASE WHEN b.holiday_5 = '1' THEN b.holiday_5 ELSE '0' END
	INTO BavarianLodge.dbo.temp5
	FROM BavarianLodge.dbo.temp1 AS a
	LEFT JOIN BavarianLodge.dbo.temp4 AS b
	ON a.date = b.date;

--Create holiday weekend column
ALTER TABLE BavarianLodge.dbo.temp5
	ADD holiday_weekend AS (CASE WHEN holiday_5 = '1' AND day_of_week_code IN('6','7','1') THEN '1' ELSE '0' END);
SELECT TOP 10* FROM BavarianLodge.dbo.temp1;

SELECT * FROM BavarianLodge.dbo.temp5;