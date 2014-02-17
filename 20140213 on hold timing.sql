
#test to find current on hold value
select * from jiraissue ji
	left join (
		select customfieldvalue.issue, customfieldoption.customvalue 
			from customfieldvalue inner join customfieldoption on customfieldoption.id = customfieldvalue.STRINGVALUE
			where customfieldvalue.customfield=10067) as cfHold on cfHold.issue = ji.id  
;

#create table with counter to match two rows in a next step
SET @counter = 0; 
drop  table if exists ENO_onholdtemp;
create  table if not exists ENO_onholdtemp as (
select issueid, author, created, OLDSTRING, NEWSTRING, (@counter:=@counter + 1) as counter from changegroup 
		inner join changeitem on changegroup.id = changeitem.groupid
		where field = 'ON HOLD');

#create table with all lines "from null to on hold till on hold to null" and "from null to on hold - still on hold"
drop table if exists ENO_onholdtime;
create table if not exists ENO_onholdtime as (
	select 
		eht1.issueid as id,
		eht1.created as starthold,
		eht2.created as endhold
		from ENO_onholdtemp eht1 
		left join ENO_onholdtemp eht2 
			on eht1.counter = (eht2.counter -1) 
			and eht1.issueid = eht2.issueid
		where eht1.oldstring is null
);
update ENO_onholdtime set endhold = now() where endhold is null;

#create table with all first changes for an epic on the on hold field, to filter out the epics which started with 'on hold'
drop table if exists ENO_hold_firstlines;
create table if not exists ENO_hold_firstlines as (
select issueid, created, oldstring, newstring, min(counter) from ENO_onholdtemp group by issueid
);

#add the epics which started with on hold to table
insert into ENO_onholdtime
	select 
		ji.id, 
		ji.created as starthold, 
		ehfl.created as endhold 
		from jiraissue ji 
		inner join ENO_hold_firstlines ehfl on ji.id = ehfl.issueid
		where ehfl.oldstring = 'ON HOLD';

select ji.id, ji.created, ji.pkey, cfHold.customvalue, eht.* from jiraissue ji
	left join (
		select customfieldvalue.issue, customfieldoption.customvalue 
			from customfieldvalue inner join customfieldoption on customfieldoption.id = customfieldvalue.STRINGVALUE
			where customfieldvalue.customfield=10067) as cfHold on cfHold.issue = ji.id
	left join ENO_onholdtime eht on eht.id = ji.id
	where ji.project = 10002
;

drop temporary table if exists ENO_statuschangestemp2;
SET @counter = 0; 
 CREATE TEMPORARY TABLE IF NOT EXISTS ENO_statuschangestemp2 AS (
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
		where field = 'ON HOLD' or field = 'status') as ch on ch.issueid = ji.id
        inner join issuestatus on ji.issuestatus = issuestatus.id
		left join (
			select customfieldvalue.issue, customfieldoption.customvalue 
				from customfieldvalue inner join customfieldoption on customfieldoption.id = customfieldvalue.STRINGVALUE
				where customfieldvalue.customfield=10067) as cfHold on cfHold.issue = ji.id 
	where ji.project = 10002 and ji.issuetype = 5
    order by ji.id, created);
select * from ENO_statuschangestemp2;


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

drop table if exists ENO_statuschanges;
CREATE TABLE IF NOT EXISTS ENO_statuschanges AS (select *, (@counter:=@counter + 1) as counter from
    ENO_statuschangestemp);
ALTER TABLE ENO_statuschanges ADD INDEX (id);
ALTER TABLE ENO_statuschanges ADD INDEX (counter);

drop table if exists ENO_firstchange;
CREATE TABLE IF NOT EXISTS ENO_firstchange AS (select sc.id, sc.pkey, min(sc.created) as mincreated from
    ENO_statuschanges sc
group by sc.id);
ALTER TABLE ENO_firstchange ADD INDEX (id);

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

select * from ENO_statuschangetimestemp;


select * from ENO_statuschangetimes;

drop table if exists ENO_statusstartend;
CREATE TABLE IF NOT EXISTS ENO_statusstartend as (
	select id, pkey, statusbegin, statusend, thisstatus from ENO_statuschangetimes);
 
insert into ENO_statusstartend
	select id, pkey, epiccreated as statusbegin, statusbegin as statusend, oldstatus as thisstatus 
	from ENO_statuschangetimes 
	where timeinfirststatus is not null;

select * from ENO_statusstartend order by id, statusbegin;

