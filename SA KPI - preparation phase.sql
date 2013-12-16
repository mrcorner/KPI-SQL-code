#doorlooptijd in fase specification

drop temporary table if exists ENO_endspecphase;
drop temporary table if exists ENO_startspecphase;
drop temporary table if exists ENO_timesinspec;

CREATE TEMPORARY TABLE IF NOT EXISTS ENO_startspecphase AS (select ji.id, ji.pkey, ji.summary, q1.* from jiraissue ji inner join (
select issueid, author, min(created) as mincreated, OLDVALUE, OLDSTRING, NEWVALUE, NEWSTRING from changegroup 
	inner join changeitem on changegroup.id = changeitem.groupid
	where field = 'status' 
	and NEWSTRING = 'Preparing'
	#group by issueid, newvalue
	group by issueid
	 ) as q1 on ji.id = q1.issueid
	where ji.issuetype = 5 and ji.project = 10002);

CREATE TEMPORARY TABLE IF NOT EXISTS ENO_endspecphase AS (select ji.id, q1.* from jiraissue ji inner join (
select issueid, max(created) as maxcreated, OLDSTRING, NEWSTRING from changegroup 
	inner join changeitem on changegroup.id = changeitem.groupid
	where field = 'status' 
	and OLDSTRING = 'Preparing'
	#group by issueid, newvalue
	group by issueid
	order by issueid ) as q1 on ji.id = q1.issueid
	where ji.issuetype = 5 and ji.project = 10002);

CREATE TEMPORARY TABLE IF NOT EXISTS ENO_timesinspec AS (
select ji.id, ji.pkey, ji.summary, q1.* from jiraissue ji inner join (
select issueid, max(created) as maxstamp, count(OLDVALUE) as timesinspec from changegroup 
	inner join changeitem on changegroup.id = changeitem.groupid
	where field = 'status' 
	and NEWSTRING = 'Preparing'
	#group by issueid, newvalue
	group by issueid
	 ) as q1 on ji.id = q1.issueid
	where ji.issuetype = 5 and ji.project = 10002 and timesinspec > 1
)
;

select ss.id, ss.pkey, ss.summary, es.maxcreated, ss.mincreated, DATEDIFF(es.maxcreated,ss.mincreated)as daysinstatus, DATEDIFF(now(), ss.mincreated) as dayspast, ts.timesinspec
	from ENO_startspecphase ss left join ENO_endspecphase es on es.id = ss.id
	left join ENO_timesinspec ts on ss.id = ts.id
	limit 10000;


	