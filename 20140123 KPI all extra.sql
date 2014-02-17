#changelog
#20131219 added label field
#20131224 added worklist generation
#20140123 changes to worklists; priority
# SA filled check in worklists
# BI team assignment, Maintenance assignment
#20140124 added 1.56 overhead columns on estimates and best estimates



# Issues with sums of estimate fields
drop temporary table if exists ENO_issueEstimates;
CREATE TEMPORARY TABLE IF NOT EXISTS ENO_issueEstimates AS (
	select 
		ji.id, 
		ji.pkey, 
		ji.summary, 
		issuestatus.pname, 
		cfTeam.customvalue as Team, 
		cfBucket.customvalue as Bucket, 
		cfHold.customvalue as onHold, 
		ji.created, 
		ji.updated, 
		sumfifty.sum50, 
		sumseventy.sum70, 
		storypoints.numbervalue as storypoints, 
		solutionarchitect.stringvalue as solutionarchitect,
		bse.stringvalue as bse
	from (
		jiraissue ji left join (
			select * from customfieldvalue where customfield = 10002) storypoints on storypoints.issue = ji.id
		) left join (
			/* Find sum of 50% estimates per issue */
			select issue, sum(numbervalue) as sum50
				from customfieldvalue 
				inner join customfield on customfield.id = customfieldvalue.customfield 
				where customfield.cfname like '%50%'
				group by issue
		) as sumfifty on sumfifty.issue = ji.id
		left join (
			select * from customfieldvalue where customfield = 10114) solutionarchitect on solutionarchitect.issue = ji.id
		left join (
			select * from customfieldvalue where customfield = 10014) bse on bse.issue = ji.id
		left join (
			select issue, sum(numbervalue) as sum70
				from customfieldvalue 
				inner join customfield on customfield.id = customfieldvalue.customfield 
				where customfield.cfname like '%70%'
				group by issue
		) as sumseventy on sumseventy.issue = ji.id
		inner join issuestatus on ji.issuestatus = issuestatus.id
		left join (
			select customfieldvalue.issue, customfieldoption.customvalue 
				from customfieldvalue inner join customfieldoption on customfieldoption.id = customfieldvalue.STRINGVALUE
				where customfieldvalue.customfield=10024) as cfTeam on cfTeam.issue = ji.id 
		left join (
			select customfieldvalue.issue, customfieldoption.customvalue 
				from customfieldvalue inner join customfieldoption on customfieldoption.id = customfieldvalue.STRINGVALUE
				where customfieldvalue.customfield=12558) as cfBucket on cfBucket.issue = ji.id 
		left join (
			select customfieldvalue.issue, customfieldoption.customvalue 
				from customfieldvalue inner join customfieldoption on customfieldoption.id = customfieldvalue.STRINGVALUE
				where customfieldvalue.customfield=10067) as cfHold on cfHold.issue = ji.id 
		where ji.project = 10002 
			and ji.issuetype = 5
			#and sum50 is not null
			#and sum70 is not null
			#and storypoints.numbervalue is not null
);

#Timestamps of estimate updates
drop temporary table if exists ENO_estimateStamps;
CREATE TEMPORARY TABLE IF NOT EXISTS ENO_estimateStamps AS (select ji.id, ji.pkey, ji.summary, q1.*, q2.maxStamp50, q2.NEWSTRING as latest50, q3.maxStamp70, q3.NEWSTRING as latest70 from jiraissue ji 
	left join (
		select issueid, author, max(created) as maxStampStoryPoints, NEWSTRING from changegroup 
			inner join changeitem on changegroup.id = changeitem.groupid
			where field = 'Story Points'
			group by issueid
			order by issueid, created ) as q1 on ji.id = q1.issueid
	left join (
		select issueid, author, max(created) as maxStamp50, NEWSTRING from changegroup
			inner join changeitem on changegroup.id = changeitem.groupid
			where field like '%50%'
			group by issueid
			order by issueid, created ) as q2 on ji.id = q2.issueid
	left join (
		select issueid, author, max(created) as maxStamp70, NEWSTRING from changegroup
			inner join changeitem on changegroup.id = changeitem.groupid
			where field like '%70%'
			group by issueid
			order by issueid, created ) as q3 on ji.id = q3.issueid
	where ji.issuetype = 5  and ji.project = 10002
);

drop temporary table if exists ENO_maxfixversions;
CREATE TEMPORARY TABLE IF NOT EXISTS ENO_maxfixversions (select fv.id, projectversion.vname from (select ji.id, max(projectversion.id) as maxpvid from jiraissue ji
		left join nodeassociation on source_node_id = ji.id
		left join projectversion on projectversion.id = nodeassociation.sink_node_id
		where nodeassociation.ASSOCIATION_TYPE = 'IssueFixVersion'
		and ji.project = 10002
		and ji.issuetype = 5
		and projectversion.vname not like '%ear%'
		group by ji.id
	) as fv inner join projectversion on fv.maxpvid = projectversion.id);

drop temporary table if exists ENO_fixversions;
CREATE TEMPORARY TABLE IF NOT EXISTS ENO_fixversions AS (select ji.id, ji.pkey, ji.summary, pv1.vname as demandfix, pv2.vname as planfix, ENO_maxfixversions.vname as fixversion from 
	jiraissue ji left join
	(select ji.id, ji.pkey, ji.summary, max(cfv.numbervalue) as nvalue
		from jiraissue ji 
		left join customfieldvalue cfv on cfv.issue = ji.id 
		where cfv.customfield = 11130
			and cfv.numbervalue not in (select id from projectversion where project = 10002 and vname like '%ear%')
			group by ji.id
	) as q1 on ji.id = q1.id left join
	(select ji.id, max(cfv.numbervalue) as nvalue
		from jiraissue ji 
		left join customfieldvalue cfv on cfv.issue = ji.id 
		where cfv.customfield = 11232 
			and cfv.numbervalue not in (select id from projectversion where project = 10002 and vname like '%ear%') 
			group by ji.id
	) as q2 on ji.id = q2.id
		left join projectversion pv1 on q1.nvalue = pv1.id
		left join projectversion pv2 on q2.nvalue = pv2.id
	left join ENO_maxfixversions on ji.id = ENO_maxfixversions.id
	where ji.project = 10002 and ji.issuetype = 5
); 

#Timestamps of phase ends --------------------------------------------------------------------------------
drop temporary table if exists ENO_endspecphase;
CREATE TEMPORARY TABLE IF NOT EXISTS ENO_endspecphase AS (select ji.id, ji.pkey, q1.* from jiraissue ji inner join (
select issueid, max(created) as endspec, OLDSTRING, NEWSTRING from changegroup 
	inner join changeitem on changegroup.id = changeitem.groupid
	where field = 'status' 
	and OLDSTRING = 'Specification'
	and NEWSTRING = 'Preparing'
	#group by issueid, newvalue
	group by issueid
	order by issueid ) as q1 on ji.id = q1.issueid
	where ji.issuetype = 5 and ji.project = 10002);

drop temporary table if exists ENO_endprepphase;
CREATE TEMPORARY TABLE IF NOT EXISTS ENO_endprepphase AS (select ji.id, q1.* from jiraissue ji inner join (
select issueid, max(created) as endprep, OLDSTRING, NEWSTRING from changegroup 
	inner join changeitem on changegroup.id = changeitem.groupid
	where field = 'status' 
	and OLDSTRING = 'Preparing'
	and NEWSTRING = 'Ready'
	#group by issueid, newvalue
	group by issueid
	order by issueid ) as q1 on ji.id = q1.issueid
	where ji.issuetype = 5 and ji.project = 10002);

drop temporary table if exists ENO_endreadyphase;
CREATE TEMPORARY TABLE IF NOT EXISTS ENO_endreadyphase AS (select ji.id, q1.* from jiraissue ji inner join (
select issueid, max(created) as endready, OLDSTRING, NEWSTRING from changegroup 
	inner join changeitem on changegroup.id = changeitem.groupid
	where field = 'status' 
	and OLDSTRING = 'Ready'
	and NEWSTRING = 'Plan'
	#group by issueid, newvalue
	group by issueid
	order by issueid ) as q1 on ji.id = q1.issueid
	where ji.issuetype = 5 and ji.project = 10002);

drop temporary table if exists ENO_toresolve;
CREATE TEMPORARY TABLE IF NOT EXISTS ENO_toresolve AS (select ji.id, q1.* from jiraissue ji inner join (
select issueid, max(created) as toresolve, OLDSTRING, NEWSTRING from changegroup 
	inner join changeitem on changegroup.id = changeitem.groupid
	where field = 'status' 
	#and OLDSTRING = 'Resolved'
	and NEWSTRING = 'Resolved'
	#group by issueid, newvalue
	group by issueid
	order by issueid ) as q1 on ji.id = q1.issueid
	where ji.issuetype = 5 and ji.project = 10002);

drop temporary table if exists ENO_toclose;
CREATE TEMPORARY TABLE IF NOT EXISTS ENO_toclose AS (select ji.id, q1.* from jiraissue ji inner join (
select issueid, max(created) as toclose, OLDSTRING, NEWSTRING from changegroup 
	inner join changeitem on changegroup.id = changeitem.groupid
	where field = 'status' 
	and OLDSTRING = 'Resolved'
	and NEWSTRING = 'Closed'
	#group by issueid, newvalue
	group by issueid
	order by issueid ) as q1 on ji.id = q1.issueid
	where ji.issuetype = 5 and ji.project = 10002);

#retrieve labels
drop temporary table if exists ENO_issuelabels;
create temporary table if not exists ENO_issuelabels as (select ji.id, ji.pkey, group_concat(label.label separator ', ') as labels from jiraissue ji left join label  on ji.id = label.issue
	where ji.project = 10002 and ji.issuetype = 5
	group by ji.id);
#select * from ENO_issuelabels;

drop table if exists ENO_kpi_all;
create table if not exists ENO_kpi_all as (select 
	   e.id,
	   e.pkey as 'Epic',
       e.summary as 'Summary',
       e.pname as 'Status', 
       group_concat(e.Team separator ', ') as 'Team(s)',
       e.solutionarchitect as SolutionArchitect,
	   e.bse as bse,
	   e.Bucket as Bucket,
	   elabels.labels as 'Labels',
	   e.onHold as 'On Hold',
	   e.created as dateCreated,
	   CONCAT(YEAR(e.created), ".", WEEKOFYEAR(e.created)) as weekCreated,
       e.updated as dateUpdated,
	   CONCAT(YEAR(e.updated), ".", WEEKOFYEAR(e.updated)) as weekUpdated, 
       e.sum50 as 'Sum of 50%', 
       e.sum70 as 'Sum of 70%', 
       e.storypoints as 'Story Points',
	   (e.storypoints * 11 / 8) as 'Converted Points',
	   if (e.storypoints is not null, e.storypoints * 11 / 8, if (e.sum70 is not null, e.sum70, e.sum50)) as bestEstimate,
	   if (e.storypoints is not null, "Poker", if (e.sum70 is not null, "70Percent", if(e.sum50 is not null, "50Percent", "None"))) as bestEstimateSource,
	   if (e.sum50 is not null and e.sum70 is not null, e.sum70 - e.sum50, null) as delta5070,
	   if (e.sum70 is not null and e.storypoints is not null,  (e.storypoints * 11 / 8) - e.sum70, if (e.sum50 is not null and e.storypoints is not null,  (e.storypoints * 11 / 8) - e.sum50, null)) as deltapp,
       s.maxStamp50 as 'Timestamp 50%', 
       s.maxStamp70 as 'Timestamp 70%',
	   s.maxStampStoryPoints as 'Timestamp Poker',
	   f.demandfix as 'Demanded Fix',
	   f.planfix as 'Planned Fix', 
       f.fixversion as 'Fix Version',
       if(f.fixversion is not null, f.fixversion, if(f.planfix is not null, f.planfix, if(f.demandfix is not null, f.demandfix, "No Sprint"))) as 'Sprint assignment',
	   espec.endspec as 'End of Specification',
       CONCAT(YEAR(espec.endspec), ".", WEEKOFYEAR(espec.endspec)) as weekEndSpec,
	   eprep.endprep as 'End of Preparation',
	   CONCAT(YEAR(eprep.endprep), ".", WEEKOFYEAR(eprep.endprep)) as weekEndPrep,
	   eready.endready as 'End of Ready',
       CONCAT(YEAR(eready.endready), ".", WEEKOFYEAR(eready.endready)) as weekEndReady,
	   eresolved.toresolve as 'Resolved date',
	   CONCAT(YEAR(eresolved.toresolve), ".", WEEKOFYEAR(eresolved.toresolve)) as weekToResolve,
	   eclosed.toclose as 'Closed date',
	   CONCAT(YEAR(eclosed.toclose), ".", WEEKOFYEAR(eclosed.toclose)) as weekToClose
	from ENO_issueEstimates e 
		inner join ENO_estimateStamps s 
		on e.id = s.id 
		inner join ENO_fixversions f
		on e.id = f.id
		left join ENO_endspecphase espec on e.id = espec.id
		left join ENO_endprepphase eprep on e.id = eprep.id
		left join ENO_endreadyphase eready on e.id = eready.id
		left join ENO_toresolve eresolved on e.id = eresolved.id
		left join ENO_toclose eclosed on e.id = eclosed.id
		left join ENO_issuelabels elabels on e.id = elabels.id		
	#where demandfix is null
	#and e.pname != "Closed" and e.pname != "Resolved" and e.pname != "Open" and e.pname != "Regression Test"
	#where planfix = "Sprint 55"
	group by e.id
	order by  e.id 
);

#20140124 add overhead for 50 and 70 estimates
alter table ENO_kpi_all add sum50overhead FLOAT NULL after `Sum of 50%`;
alter table ENO_kpi_all add sum70overhead FLOAT NULL after `Sum of 70%`;
alter table ENO_kpi_all add bestEstimateOverhead FLOAT NULL after bestEstimate;
alter table ENO_kpi_all add bestEstimateTotal FLOAT NULL after bestEstimateOverhead;

#first on creation date, then overwrite on 50 and 70 timestamps
update ENO_kpi_all ki left join calendar_table ct on date(ki.dateCreated) = ct.dt
	set sum50overhead = ki.`Sum of 50%` * (ct.overhead - 1),
		sum70overhead = ki.`Sum of 70%` * (ct.overhead - 1);
update ENO_kpi_all ki inner join calendar_table ct on date(ki.`Timestamp 50%`) = ct.dt
	set sum50overhead = ki.`Sum of 50%` * (ct.overhead - 1);
update ENO_kpi_all ki inner join calendar_table ct on date(ki.`Timestamp 70%`) = ct.dt
	set sum70overhead = ki.`Sum of 70%` * (ct.overhead - 1);

#add best estimate overhead
update ENO_kpi_all ki 
	set ki.bestEstimateOverhead = sum50overhead where bestEstimateSource = '50Percent';
update ENO_kpi_all ki 
	set ki.bestEstimateOverhead = sum70overhead where bestEstimateSource = '70Percent';
update ENO_kpi_all ki
	set ki.bestEstimateTotal = ki.bestEstimate + ki.bestEstimateOverhead 
	where ki.bestEstimateOverhead is not null;
update ENO_kpi_all ki
	set ki.bestEstimateTotal = ki.bestEstimate 
	where ki.bestEstimateOverhead is null;



select * from ENO_kpi_all limit 10000;

drop table if exists ENO_worklists;
create table if not exists ENO_worklists as (
	select e.id,
		   e.`Epic` as epic,
		   e.`Summary` as summary,
           e.`Status` as status,
           e.`On Hold` as onhold,
		   e.SolutionArchitect as SolutionArchitect,
		   e.`Team(s)` as teams,
           e.`Sum of 50%` as sum50,
           e.`Sum of 70%` as sum70,
		   e.`Story Points` as storypoints,
           e.`Sprint assignment` as sprintassignment
	from ENO_kpi_all e
);

ALTER TABLE ENO_worklists add priority VARCHAR(255) NULL;
ALTER TABLE ENO_worklists add workitem VARCHAR(255) NULL;
ALTER TABLE ENO_worklists add actionholder VARCHAR(255) NULL;

ALTER TABLE ENO_worklists 	ADD INDEX (id), 
							ADD INDEX (epic), 
							ADD INDEX(status), 
							ADD INDEX(onhold), 
							ADD INDEX(sum50), 
							ADD INDEX(sum70), 
							ADD INDEX (storypoints);



#fill calendar tables
drop table if exists ENO_currentsprint;
create table if not exists ENO_currentsprint as (
	select sprint from calendar_table where dt = CURDATE()
);



drop table if exists ENO_pastsprints;
create table if not exists ENO_pastsprints as (
	select sprint from calendar_table where dt < CURDATE() and sprint not in (select * from ENO_currentsprint)
    group by sprint
);

drop table if exists ENO_futuresprints;
create table if not exists ENO_futuresprints as (
	select sprint from calendar_table where dt > CURDATE() and sprint not in (select * from ENO_currentsprint)
    group by sprint
);

drop table if exists ENO_nextsprint;
create table if not exists ENO_nextsprint as (
	select sprint from ENO_futuresprints limit 1
);




UPDATE ENO_worklists wl
	SET wl.workitem = 'Current sprint, wrong status',
		wl.priority = 'High',
        wl.actionholder = 'Rob Perfors'
	WHERE
		wl.sprintassignment in (select * from ENO_currentsprint) 
        and wl.status in ('Open', 'Specification', 'Preparing', 'Ready')
		and wl.priority is null
		and wl.onhold is null
;

UPDATE ENO_worklists wl
	SET wl.workitem = 'Future sprint, wrong status',
		wl.priority = 'High',
        wl.actionholder = 'Richard Herremans'
	WHERE
		wl.sprintassignment in (select * from ENO_futuresprints) 
        and wl.status in ('Closed', 'Resolved', 'Ready for P')
		and wl.priority is null
		and wl.onhold is null
;

UPDATE ENO_worklists wl
	SET wl.workitem = 'Next sprint, no Solution Architect assigned',
		wl.priority = 'High',
        wl.actionholder = 'Niels Wolf'
	WHERE
		wl.sprintassignment in (select * from ENO_nextsprint) 
        and wl.SolutionArchitect is null
		and wl.priority is null
		and wl.onhold is null
;

UPDATE ENO_worklists wl
	SET wl.workitem = 'Next sprint, wrong status',
		wl.priority = 'High',
        wl.actionholder = 'Niels Wolf'
	WHERE
		wl.sprintassignment in (select * from ENO_nextsprint) 
        and wl.status in ('Open', 'Specification')
		and wl.priority is null
		and wl.onhold is null
;

UPDATE ENO_worklists wl
	SET wl.workitem = 'No Sprint filled, status Specification',
		wl.priority = 'High',
        wl.actionholder = 'Joost Looij'
	WHERE
		wl.sprintassignment = 'No Sprint'
        and wl.status = 'Specification'
		and wl.priority is null
		and wl.onhold is null
;

UPDATE ENO_worklists wl
	SET wl.workitem = 'No Sprint filled, status > Preparing',
		wl.priority = 'High',
        wl.actionholder = 'Richard Herremans'
	WHERE
		wl.sprintassignment = 'No Sprint'
        and wl.status in ('Ready', 'Plan', 'In Progress', 'Regression Test', 'Ready for P')
		and wl.priority is null
		and wl.onhold is null
;



UPDATE ENO_worklists wl
	SET wl.workitem = 'No Team assigned, status ready or plan',
		wl.priority = 'High',
        wl.actionholder = 'Rob Perfors'
	WHERE
		wl.teams is null
        and wl.status in ('Ready', 'Plan')
		and wl.priority is null
		and wl.onhold is null
;

UPDATE ENO_worklists wl
	SET wl.workitem = 'No 50% estimate, status > specification',
		wl.priority = 'High',
        wl.actionholder = 'Joost Looij'
	WHERE
		(wl.sprintassignment in (select * from ENO_futuresprints) or wl.sprintassignment = 'No Sprint')
        and wl.sum50 = 0
		and wl.status in ('Preparing', 'Plan', 'Ready', 'In Progress', 'Regression Test', 'Ready for P')
		and wl.priority is null
		and wl.onhold is null
;

UPDATE ENO_worklists wl
	SET wl.workitem = 'No SA assigned, status > Preparing',
		wl.priority = 'High',
        wl.actionholder = 'Niels Wolf'
	WHERE
		wl.SolutionArchitect is null
        and wl.status in ('Ready', 'Plan', 'In Progress', 'Regression Test', 'Ready for P')
		and wl.priority is null
		and wl.onhold is null
;

UPDATE ENO_worklists wl
	SET wl.workitem = 'No 70% estimate, status > preparing',
		wl.priority = 'High',
        wl.actionholder = 'Joost Looij'
	WHERE
		(wl.sprintassignment in (select * from ENO_futuresprints) or wl.sprintassignment = 'No Sprint')
        and wl.sum70 = 0
		and wl.status in ('Plan', 'Ready', 'In Progress', 'Regression Test', 'Ready for P')
		and wl.priority is null
		and wl.onhold is null
;

UPDATE ENO_worklists wl
	SET wl.workitem = 'No Sprint filled, status Preparing',
		wl.priority = 'Medium',
        wl.actionholder = 'Niels Wolf'
	WHERE
		wl.sprintassignment = 'No Sprint'
        and wl.status = 'Preparing'
		and wl.priority is null
		and wl.onhold is null
;


UPDATE ENO_worklists wl
	SET wl.workitem = 'Historic sprint, wrong status',
		wl.priority = 'Medium',
        wl.actionholder = 'Rob Perfors'
	WHERE
		wl.sprintassignment in (select * from ENO_pastsprints) 
        and wl.status in ('Plan', 'In Progress')
		and wl.onhold is null
;

UPDATE ENO_worklists wl
	SET wl.workitem = 'ON HOLD and status > Preparing',
		wl.priority = 'Low',
        wl.actionholder = 'Niels Wolf'
	WHERE
        wl.status in ('Plan', 'Ready', 'In Progress', 'Regression Test', 'Ready for P')
		and wl.priority is null
		and wl.onhold is not null
;

UPDATE ENO_worklists wl
	SET wl.workitem = 'No Sprint filled, status open',
		wl.priority = 'Low',
        wl.actionholder = 'Joost Looij'
	WHERE
		wl.sprintassignment = 'No Sprint'
        and wl.status = 'Open'
		and wl.priority is null
		and wl.onhold is null
;

UPDATE ENO_worklists wl
	SET wl.workitem = 'Historic sprint, still in backlog',
		wl.priority = 'Warning',
        wl.actionholder = 'Jano Masarovic'
	WHERE
		wl.sprintassignment in (select * from ENO_pastsprints) 
        and wl.status in ('Open', 'Specification', 'Preparing', 'Ready')
		and wl.onhold is null
;

UPDATE ENO_worklists wl
	SET wl.workitem = 'Historic sprint, still in Regression',
		wl.priority = 'Warning',
        wl.actionholder = 'Rob Perfors'
	WHERE
		wl.sprintassignment in (select * from ENO_pastsprints) 
        and wl.status in ('Regression Test')
		and wl.onhold is null
;

#Eric Prins as Owner of all BI PC epics
UPDATE ENO_worklists wl
	SET wl.actionholder = 'Eric Prins'
	WHERE wl.teams like '%BI PC%' and wl.priority is not null;

#Maintenance as Owner of all Maintenance epics
UPDATE ENO_worklists wl
	SET wl.actionholder = 'Maintenance'
	WHERE wl.teams like 'Maintenance Morphis' and wl.priority is not null;

#Maintenance as Owner of all Inofsys epics
UPDATE ENO_worklists wl
	SET wl.actionholder = 'Infosys'
	WHERE wl.teams like 'Infosys' and wl.priority is not null;

select * from ENO_worklists where workitem is not null;
select * from ENO_worklists limit 10000;



