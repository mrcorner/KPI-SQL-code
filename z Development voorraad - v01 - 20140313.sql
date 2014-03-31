#base table with current status and current 50 / 70 estimates
select 
	ji.id, 
	ji.pkey, 
	cfHold.customvalue as onHold, 
	ji.summary, 
	issuestatus.pname as status,  
	sumfifty.sum50,
	sumseventy.sum70,
	ji.created, 
	ji.updated
	from 
		jiraissue ji
	inner join 
		issuestatus on ji.issuestatus = issuestatus.id
	left join (
		select customfieldvalue.issue, customfieldoption.customvalue 
			from customfieldvalue inner join customfieldoption on customfieldoption.id = customfieldvalue.STRINGVALUE
			where customfieldvalue.customfield=10067) as cfHold on cfHold.issue = ji.id 
	left join (
		/* Find sum of 50% estimates per issue */
		select issue, sum(numbervalue) as sum50
			from customfieldvalue 
			inner join customfield on customfield.id = customfieldvalue.customfield 
			where customfield.cfname like '%50%'
			group by issue
		) as sumfifty on sumfifty.issue = ji.id
	left join (
		/* Find sum of 70% estimates per issue */
		select issue, sum(numbervalue) as sum70
			from customfieldvalue 
			inner join customfield on customfield.id = customfieldvalue.customfield 
			where customfield.cfname like '%70%'
			group by issue
		) as sumseventy on sumseventy.issue = ji.id

	where 
		project = 10002 
		and issuetype = 5
		and issuestatus.pname in ('Open', 'Specification', 'Preparing', 'Ready', 'Plan')
	order by ji.id
;

select issue, numbervalue, cfname 
	from customfieldvalue 
	inner join customfield on customfield.id = customfieldvalue.customfield 
	where customfield.cfname like '%50%';




select issueid, field, created, if(oldstring is null, newstring, newstring - oldstring) as delta, OLDSTRING, NEWSTRING from changegroup
	inner join changeitem on changegroup.id = changeitem.groupid
	where field like '%50%';

drop table if exists ENO_statuschanges;
create table if not exists ENO_statuschanges as (
	select changeitem.id, issueid, created, oldstring, newstring from changegroup inner join changeitem on changegroup.id = changeitem.groupid where field = 'status');
select * from ENO_statuschanges;

drop temporary table if exists ENO_statuschangesmax;
create temporary table if not exists ENO_statuschangesmax as (
	select id, issueid, max(created) as maxcreated from ENO_statuschanges
		where created <= '2014-03-09 00:00:00'
		group by issueid);

select sc.issueid, sc.newstring from ENO_statuschanges sc inner join ENO_statuschangesmax scm on sc.id=scm.id;


