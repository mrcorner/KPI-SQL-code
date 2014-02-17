ALTER TABLE jiraissue 			ADD INDEX (id),
								add index (pkey),
								add index (issuetype),
								add index (issuestatus),
								add index (created),
								add index (updated),
								add index (project); 
ALTER TABLE changegroup 		ADD INDEX (id), 
								add index (issueid), 
								add index (created);
ALTER TABLE changeitem 			ADD INDEX (id), 
								add index (groupid), 
								add index (field), 
								add index (fieldtype);
ALTER TABLE issuestatus 		ADD INDEX (id), 
								add index (pname);
ALTER TABLE customfieldvalue 	ADD INDEX (id), 
								add index (issue), 
								add index (customfield), 
								add index (STRINGVALUE);
ALTER TABLE customfield 		ADD INDEX (id), 
								add index (cfname);
ALTER TABLE customfieldoption 	ADD INDEX (id), 
								add index (customvalue);

DROP TABLE if exists calendar_table;

CREATE TABLE calendar_table (
	dt DATE NOT NULL PRIMARY KEY,
	y SMALLINT NULL,
	q tinyint NULL,
	m tinyint NULL,
	d tinyint NULL,
	dw tinyint NULL,
	monthName VARCHAR(9) NULL,
	dayName VARCHAR(9) NULL,
	w tinyint NULL,
	isWeekday tinyint NULL,
	isHoliday tinyint NULL,
	holidayDescr VARCHAR(32) NULL,
	isPayday tinyint NULL
);

alter table calendar_table add sprint VARCHAR(9) NULL;
alter table calendar_table add overhead FLOAT NULL;



drop table if exists ints;
CREATE TABLE ints ( i tinyint );
 
INSERT INTO ints VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9);
 
INSERT INTO calendar_table (dt)
SELECT DATE('2010-01-01') + INTERVAL a.i*10000 + b.i*1000 + c.i*100 + d.i*10 + e.i DAY
FROM ints a JOIN ints b JOIN ints c JOIN ints d JOIN ints e
WHERE (a.i*10000 + b.i*1000 + c.i*100 + d.i*10 + e.i) <= 11322
ORDER BY 1;

UPDATE calendar_table
SET isWeekday = CASE WHEN dayofweek(dt) IN (1,7) THEN 0 ELSE 1 END,
	isHoliday = 0,
	isPayday = 0,
	y = YEAR(dt),
	q = quarter(dt),
	m = MONTH(dt),
	d = dayofmonth(dt),
	dw = dayofweek(dt),
	monthname = monthname(dt),
	dayname = dayname(dt),
	w = week(dt),
	holidayDescr = '';

UPDATE calendar_table SET isHoliday = 1, holidayDescr = 'New Year''s Day' WHERE m = 1 AND d = 1;
 
UPDATE calendar_table c1
LEFT JOIN calendar_table c2 ON c2.dt = c1.dt + INTERVAL 1 DAY
SET c1.isHoliday = 1, c1.holidayDescr = 'Holiday for New Year''s Day'
WHERE c1.dw = 6 AND c2.m = 1 AND c2.dw = 7 AND c2.isHoliday = 1;
 
UPDATE calendar_table c1
LEFT JOIN calendar_table c2 ON c2.dt = c1.dt - INTERVAL 1 DAY
SET c1.isHoliday = 1, c1.holidayDescr = 'Holiday for New Year''s Day'
WHERE c1.dw = 2 AND c2.m = 1 AND c2.dw = 1 AND c2.isHoliday = 1;

UPDATE calendar_table c1
SET c1.sprint = 'Sprint 46' where c1.dt >= 20130621 and c1.dt < 20130712;

UPDATE calendar_table c1
SET c1.sprint = 'Sprint 47' where c1.dt >= 20130712 and c1.dt < 20130802;

UPDATE calendar_table c1
SET c1.sprint = 'Sprint 48' where c1.dt >= 20130802 and c1.dt < 20130823;

UPDATE calendar_table c1
SET c1.sprint = 'Sprint 49' where c1.dt >= 20130823 and c1.dt < 20130913;

UPDATE calendar_table c1
SET c1.sprint = 'Sprint 50' where c1.dt >= 20130913 and c1.dt < 20131004;

UPDATE calendar_table c1
SET c1.sprint = 'Sprint 51' where c1.dt >= 20131004 and c1.dt < 20131025;

UPDATE calendar_table c1
SET c1.sprint = 'Sprint 52' where c1.dt >= 20131025 and c1.dt < 20131115;

UPDATE calendar_table c1
SET c1.sprint = 'Sprint 53' where c1.dt >= 20131115 and c1.dt < 20131206;

UPDATE calendar_table c1
SET c1.sprint = 'Sprint 54' where c1.dt >= 20131206 and c1.dt < 20140107;

UPDATE calendar_table c1
SET c1.sprint = 'Sprint 55' where c1.dt >= 20140107 and c1.dt < 20140128;

UPDATE calendar_table c1
SET c1.sprint = 'Sprint 56' where c1.dt >= 20140128 and c1.dt < 20140218;

UPDATE calendar_table c1
SET c1.sprint = 'Sprint 57' where c1.dt >= 20140218 and c1.dt < 20140311;

UPDATE calendar_table c1
SET c1.sprint = 'Sprint 58' where c1.dt >= 20140311 and c1.dt < 20140401;

UPDATE calendar_table c1
SET c1.sprint = 'Sprint 59' where c1.dt >= 20140401 and c1.dt < 20140422;

UPDATE calendar_table c1
SET c1.sprint = 'Sprint 60' where c1.dt >= 20140422 and c1.dt < 20140513;

UPDATE calendar_table c1
SET c1.sprint = 'Sprint 61' where c1.dt >= 20140513 and c1.dt < 20140603;

UPDATE calendar_table c1
SET c1.sprint = 'Sprint 62' where c1.dt >= 20140603 and c1.dt < 20140624;

UPDATE calendar_table c1
SET c1.sprint = 'Sprint 63' where c1.dt >= 20140624 and c1.dt < 20140715;

UPDATE calendar_table c1
SET c1.sprint = 'Sprint 64' where c1.dt >= 20140715 and c1.dt < 20140805;

UPDATE calendar_table c1
SET c1.sprint = 'Sprint 65' where c1.dt >= 20140805 and c1.dt < 20140826;

UPDATE calendar_table c1
SET c1.sprint = 'Sprint 66' where c1.dt >= 20140826 and c1.dt < 20140916;


UPDATE calendar_table
SET isHoliday = 1, holidayDescr = 'First Christmas day'
WHERE m = 12 AND d = 25;

UPDATE calendar_table
SET isHoliday = 1, holidayDescr = 'Second Christmas day'
WHERE m = 12 AND d = 26;

update calendar_table set overhead = 1.56;

select * from calendar_table c1 where c1.sprint is not null;