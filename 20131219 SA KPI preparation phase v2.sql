#doorlooptijd in fase preparation







drop temporary table if exists ENO_statuschangestemp;
SET @counter = 0; 
CREATE TEMPORARY TABLE IF NOT EXISTS ENO_statuschangestemp AS (
	select ji.id, 
		   ji.pkey, 
		   issuestatus.pname as currentstatus,
		   ji.created as epiccreated,
           cfHold.customvalue as onHold,
           ch.author, 
           ch.created, 
           ch.OLDSTRING, 
           ch.NEWSTRING
		   
	from jiraissue ji inner join (select issueid, author, created, OLDSTRING, NEWSTRING from changegroup 
		inner join changeitem on changegroup.id = changeitem.groupid
		where field = 'status') as ch on ch.issueid = ji.id
        inner join issuestatus on ji.issuestatus = issuestatus.id
		left join (
			select customfieldvalue.issue, customfieldoption.customvalue 
				from customfieldvalue inner join customfieldoption on customfieldoption.id = customfieldvalue.STRINGVALUE
				where customfieldvalue.customfield=10067) as cfHold on cfHold.issue = ji.id 
	where ji.project = 10002 and ji.issuetype = 5
    order by ji.id, created
);

drop table if exists ENO_firstchange;
CREATE TABLE IF NOT EXISTS ENO_firstchange AS (
	select sc.id, sc.pkey, min(sc.created) as mincreated from ENO_statuschanges sc group by sc.id);
ALTER TABLE ENO_firstchange ADD INDEX (id);

drop table if exists ENO_statuschanges;
CREATE TABLE IF NOT EXISTS ENO_statuschanges AS(
	select *, (@counter := @counter +1) as counter 
	from ENO_statuschangestemp);
ALTER TABLE ENO_statuschanges ADD INDEX (id);
ALTER TABLE ENO_statuschanges ADD INDEX (counter);

drop temporary table if exists ENO_statuschangetimestemp;
CREATE TEMPORARY TABLE IF NOT EXISTS ENO_statuschangetimestemp AS(
select enoa.id, 
       enoa.pkey,
       enoa.currentstatus,
       enoa.onHold,
	   enoa.epiccreated,
       enoa.author, 
       enoa.created as statusbegin,
	   enob.created as statusend, 
       enoa.OLDSTRING,
       enoa.NEWSTRING,
       #enob.NEWSTRING as NEXTSTRING
	   fc.mincreated as firstchange
	   from ENO_statuschanges enoa left join ENO_statuschanges enob on enoa.counter = (enob.counter-1) and enoa.id = enob.id
	   left join ENO_firstchange fc on enoa.id = fc.id
);
#select * from ENO_statuschangetimestemp;


drop table if exists ENO_statuschangetimes;
CREATE TABLE IF NOT EXISTS ENO_statuschangetimes AS(
	select sc.id,
           sc.pkey,
           sc.currentstatus,
           sc.onHold,
           sc.epiccreated,
	       sc.author,
           sc.statusbegin,
           CONCAT(YEAR(sc.statusbegin), ".", WEEKOFYEAR(sc.statusbegin)) as weekStatusBegin,
           sc.statusend,
           CONCAT(YEAR(sc.statusend), ".", WEEKOFYEAR(sc.statusend)) as weekStatusEnd,
           sc.OLDSTRING as oldstatus,
           sc.NEWSTRING as thisstatus,
		   sc.firstchange,
           if(sc.statusend is not null, datediff(sc.statusend, sc.statusbegin), datediff(now(), sc.statusbegin)) as timeinthisstatus,
	       if(sc.statusbegin = sc.firstchange, datediff(sc.firstchange, sc.epiccreated), null) as timeinfirststatus
		   from ENO_statuschangetimestemp sc);

drop table if exists ENO_timesinprep;
CREATE TABLE IF NOT EXISTS ENO_timesinprep AS(
	select 	sct.id, 
			sct.pkey, 
			count(sct.id) as timesinprep 
	from ENO_statuschangetimes sct 
	where thisstatus = 'Preparing' 
	group by sct.id
);

/*select sct.*, tip.timesinprep 
	from ENO_statuschangetimes sct 
	left join ENO_timesinprep tip
		on sct.id = tip.id
	where sct.thisstatus = 'Preparing'
	limit 100000;*/

#only sum and max
select 	sct.id, 
		sct.pkey,
		sct.currentstatus,
		sct.onHold,
		max(weekStatusEnd) as weeklaststatusend,
		sum(timeinthisstatus) as totalTimeInStatus,
		tip.timesinprep
	from ENO_statuschangetimes sct 
	left join ENO_timesinprep tip
		on sct.id = tip.id
	where sct.thisstatus = 'Preparing'
	group by sct.id
	limit 10000;



	