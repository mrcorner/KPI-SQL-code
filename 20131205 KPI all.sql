drop temporary table if exists ENO_issueEstimates;
drop temporary table if exists ENO_estimateStamps;
drop temporary table if exists ENO_fixversions;


# Issues with sums of estimate fields
CREATE TEMPORARY TABLE IF NOT EXISTS ENO_issueEstimates AS (select ji.id, ji.pkey, ji.summary, issuestatus.pname, cfTeam.customvalue as Team, ji.created, ji.updated, sumfifty.sum50, sumseventy.sum70, storypoints.numbervalue as storypoints
	from (
		jiraissue ji left join (select * from customfieldvalue where customfield = 10002) storypoints on storypoints.issue = ji.id
		) left join (
			/* Find sum of 50% estimates per issue */
			select issue, sum(numbervalue) as sum50
				from customfieldvalue 
				inner join customfield on customfield.id = customfieldvalue.customfield 
				where customfield.cfname like '%50%'
				group by issue
		) as sumfifty on sumfifty.issue = ji.id
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
		where ji.project = 10002 
			and ji.issuetype = 5
			#and sum50 is not null
			#and sum70 is not null
			#and storypoints.numbervalue is not null
);

#Timestamps of estimate updates
CREATE TEMPORARY TABLE IF NOT EXISTS ENO_estimateStamps AS (select ji.id, ji.pkey, ji.summary, q1.*, q2.maxStamp50, q2.NEWSTRING as latest50, q3.maxStamp70, q3.NEWSTRING as latest70 from jiraissue ji left join (
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

CREATE TEMPORARY TABLE IF NOT EXISTS ENO_fixversions AS (select ji.id, ji.pkey, ji.summary, pv1.vname as demandfix, pv2.vname as planfix, q3.vname as fixversion from 
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
	) as q2 on q1.id = q2.id
		left join projectversion pv1 on q1.nvalue = pv1.id
		left join projectversion pv2 on q2.nvalue = pv2.id
	left join (
	SELECT jiraissue.id, max(projectversion.id) as pvid, vname
		FROM projectversion,
		nodeassociation,
		jiraissue
		WHERE ASSOCIATION_TYPE = 'IssueFixVersion'
		AND SINK_NODE_ID = projectversion.id
		AND SOURCE_NODE_ID = jiraissue.id
		and projectversion.vname not like '%ear%'
		group by jiraissue.id
	) as q3 on q1.id = q3.id
	where ji.project = 10002 and ji.issuetype = 5
); 


select 
	   e.pkey as 'Epic',
       e.summary as 'Summary',
       e.pname as 'Status', 
       group_concat(e.Team separator ', ') as 'Team(s)',
	   e.created as dataCreated,
       e.updated as dateUpdated, 
       e.sum50 as 'Sum of 50%', 
       e.sum70 as 'Sum of 70%', 
       e.storypoints as 'Story Points', 
       s.maxStamp50 as 'Timestamp 50%', 
       s.maxStamp70 as 'Timestamp 70%',
	   s.maxStampStoryPoints as 'Timestamp Poker',
	   f.demandfix as 'Demanded Fix',
	   f.planfix as 'Planned Fix', 
       f.fixversion as 'Fix Version'
	from ENO_issueEstimates e 
		inner join ENO_estimateStamps s 
		on e.id = s.id 
		inner join ENO_fixversions f
		on e.id = f.id
	group by e.id
	order by  e.id 
	LIMIT 5000;