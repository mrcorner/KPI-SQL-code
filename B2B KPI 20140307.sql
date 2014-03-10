#determine releases

drop temporary table if exists ENO_B2Bmaxfixversions;
CREATE TEMPORARY TABLE IF NOT EXISTS ENO_B2Bmaxfixversions (select fv.id, projectversion.vname from (select ji.id, max(projectversion.id) as maxpvid from jiraissue ji
		left join nodeassociation on source_node_id = ji.id
		left join projectversion on projectversion.id = nodeassociation.sink_node_id
		where nodeassociation.ASSOCIATION_TYPE = 'IssueFixVersion'
		and ji.project = 10131
		and ji.issuetype = 5
		and projectversion.vname not like '%ear%'
		group by ji.id
	) as fv inner join projectversion on fv.maxpvid = projectversion.id);

#create master data table

drop table if exists ENO_B2Bmaster;
CREATE TABLE IF NOT EXISTS ENO_B2Bmaster AS (
	select 
		ji.id, 
		ji.pkey, 
		cfHold.customvalue as onHold, 
		ji.reporter,
		solutionarchitect.stringvalue as solutionarchitect,
		group_concat(cfTeam.customvalue separator ', ') as Team, 
		ji.summary, 
		issuestatus.pname as status,  
		sumfifty.sum50,
		if(stamp50.maxStamp50 is null and sumfifty.sum50 is not null, ji.created, stamp50.maxStamp50) as maxStamp50,
		sumseventy.sum70,
		if(stamp70.maxStamp70 is null and sumseventy.sum70 is not null, ji.created, stamp70.maxStamp70) as maxStamp70,
		storypoints.numbervalue as storypoints,
		if (sumfifty.sum50 is not null and sumseventy.sum70 is not null, sumseventy.sum70 - sumfifty.sum50, null) as delta5070,
		if (sumseventy.sum70 is not null and storypoints.numbervalue is not null,  (storypoints.numbervalue) - sumseventy.sum70, if (sumfifty.sum50 is not null and storypoints.numbervalue is not null,  (storypoints.numbervalue) - sumfifty.sum50, null)) as deltapp,
		stampstorypoints.maxStampStoryPoints,
		ji.created, 
		ji.updated, 
		mfv.vname as fixVersion
	from 
		jiraissue ji
	inner join 
		issuestatus on ji.issuestatus = issuestatus.id
	left join (
			select * from customfieldvalue where customfield = 10002) storypoints on storypoints.issue = ji.id
	left join (
		select customfieldvalue.issue, customfieldoption.customvalue 
			from customfieldvalue inner join customfieldoption on customfieldoption.id = customfieldvalue.STRINGVALUE
			where customfieldvalue.customfield=10067) as cfHold on cfHold.issue = ji.id 
	left join (
			select * from customfieldvalue where customfield = 10114) solutionarchitect on solutionarchitect.issue = ji.id
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
	left join (
		select issueid, author, max(created) as maxStampStoryPoints, NEWSTRING from changegroup 
			inner join changeitem on changegroup.id = changeitem.groupid
			where field = 'Story Points'
			group by issueid
			order by issueid, created ) as stampstorypoints on ji.id = stampstorypoints.issueid
	left join (
		select customfieldvalue.issue, customfieldoption.customvalue 
			from customfieldvalue inner join customfieldoption on customfieldoption.id = customfieldvalue.STRINGVALUE
			where customfieldvalue.customfield=10024) as cfTeam on cfTeam.issue = ji.id 
	left join (
		select issueid, author, max(created) as maxStamp50, NEWSTRING from changegroup
			inner join changeitem on changegroup.id = changeitem.groupid
			where field like '%50%'
			group by issueid
			order by issueid, created ) as stamp50 on ji.id = stamp50.issueid
	left join (
		select issueid, author, max(created) as maxStamp70, NEWSTRING from changegroup
			inner join changeitem on changegroup.id = changeitem.groupid
			where field like '%70%'
			group by issueid
			order by issueid, created ) as stamp70 on ji.id = stamp70.issueid
	left join ENO_B2Bmaxfixversions mfv on mfv.id = ji.id
	where 
		project = 10131 
		and issuetype = 5
		and created > '2013-04-01'
	group by ji.id
	order by ji.id
	
);

ALTER TABLE ENO_B2Bmaster add priority VARCHAR(255) NULL;
ALTER TABLE ENO_B2Bmaster add workitem VARCHAR(255) NULL;
ALTER TABLE ENO_B2Bmaster add actionholder VARCHAR(255) NULL;

select * from ENO_B2Bmaster;

UPDATE ENO_B2Bmaster wl
	SET wl.workitem = 'Current sprint, wrong status',
		wl.priority = 'High',
        wl.actionholder = 'Tim Verstegen'
	WHERE
		wl.fixVersion in ('Release 2014.2') 
        and wl.status in ('Open', 'Specification', 'Preparing', 'Ready')
		and wl.priority is null
		and wl.onhold is null
;

UPDATE ENO_B2Bmaster wl
	SET wl.workitem = 'Future sprint, wrong status',
		wl.priority = 'High',
        wl.actionholder = 'Tim Verstegen'
	WHERE
		wl.fixVersion in ('Release 2014.3', 'Release 2014.4') 
        and wl.status in ('Closed', 'Resolved', 'Ready for P')
		and wl.priority is null
		and wl.onhold is null
;

UPDATE ENO_B2Bmaster wl
	SET wl.workitem = 'Next sprint, no Solution Architect assigned',
		wl.priority = 'High',
        wl.actionholder = 'Tim Verstegen'
	WHERE
		wl.fixVersion in ('Release 2014.3')
        and wl.SolutionArchitect is null
		and wl.priority is null
		and wl.onhold is null
;

UPDATE ENO_B2Bmaster wl
	SET wl.workitem = 'Next sprint, wrong status',
		wl.priority = 'High',
        wl.actionholder = 'Sander Timmers'
	WHERE
		wl.fixVersion in ('Release 2014.3')
        and wl.SolutionArchitect is null
		and wl.priority is null
		and wl.onhold is null
;

UPDATE ENO_B2Bmaster wl
	SET wl.workitem = 'No Sprint filled, status Specification',
		wl.priority = 'High',
        wl.actionholder = 'Sander Timmers'
	WHERE
		wl.fixVersion is null
        and wl.status = 'Specification'
		and wl.priority is null
		and wl.onhold is null
;

UPDATE ENO_B2Bmaster wl
	SET wl.workitem = 'No Sprint filled, status > Preparing',
		wl.priority = 'High',
        wl.actionholder = 'Tim Verstegen'
	WHERE
		wl.fixVersion is null
        and wl.status in ('Ready', 'Plan', 'In Progress', 'Regression Test', 'Ready for P')
		and wl.priority is null
		and wl.onhold is null
;

UPDATE ENO_B2Bmaster wl
	SET wl.workitem = 'No Team assigned, status ready or plan',
		wl.priority = 'High',
        wl.actionholder = 'Tim Verstegen'
	WHERE
		wl.Team is null
        and wl.status in ('Ready', 'Plan')
		and wl.priority is null
		and wl.onhold is null
;

UPDATE ENO_B2Bmaster wl
	SET wl.workitem = 'No 50% estimate, status > specification',
		wl.priority = 'High',
        wl.actionholder = 'Sander Timmers'
	WHERE
		(wl.fixVersion in ('Release 2014.3', 'Release 2014.4')  or wl.fixVersion is null)
        and wl.sum50 = 0
		and wl.status in ('Preparing', 'Plan', 'Ready', 'In Progress', 'Regression Test', 'Ready for P')
		and wl.priority is null
		and wl.onhold is null
;


UPDATE ENO_B2Bmaster wl
	SET wl.workitem = 'No SA assigned, status > Preparing',
		wl.priority = 'High',
        wl.actionholder = 'Tim Verstegen'
	WHERE
		wl.SolutionArchitect is null
        and wl.status in ('Ready', 'Plan', 'In Progress', 'Regression Test', 'Ready for P')
		and wl.priority is null
		and wl.onhold is null
;

UPDATE ENO_B2Bmaster wl
	SET wl.workitem = 'No 70% estimate, status > Preparing',
		wl.priority = 'High',
        wl.actionholder = 'Sander Timmers'
	WHERE
		(wl.fixVersion in ('Release 2014.3', 'Release 2014.4')  or wl.fixVersion is null)
        and wl.sum70 = 0
		and wl.status in ( 'Plan', 'Ready', 'In Progress', 'Regression Test', 'Ready for P')
		and wl.priority is null
		and wl.onhold is null
;

UPDATE ENO_B2Bmaster wl
	SET wl.workitem = 'No Sprint filled, status = Preparing',
		wl.priority = 'Medium',
        wl.actionholder = 'Tim Verstegen'
	WHERE
		wl.fixVersion is null
        and wl.status in ('Preparing')
		and wl.priority is null
		and wl.onhold is null
;


UPDATE ENO_B2Bmaster wl
	SET wl.workitem = 'ON HOLD and status > Preparing',
		wl.priority = 'Low',
        wl.actionholder = 'Tim Verstegen	'
	WHERE
        wl.status in ('Plan', 'Ready', 'In Progress', 'Regression Test', 'Ready for P')
		and wl.priority is null
		and wl.onhold is not null
;

UPDATE ENO_B2Bmaster wl
	SET wl.workitem = 'No Sprint filled, status = Preparing',
		wl.priority = 'Low',
        wl.actionholder = 'Sander Timmers'
	WHERE
		wl.fixVersion is null
        and wl.status in ('Open')
		and wl.priority is null
		and wl.onhold is null
;

#to add: historic releases



select * from ENO_B2Bmaster bb limit 10000 ;


