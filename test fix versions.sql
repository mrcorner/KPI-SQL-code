select * from projectversion where project = 10002;

select * from customfield where id = 11130;

select * from customfieldvalue where customfield = 12348;

select * from customfieldoption;

select * from projectversion where project = 10002;
select * from jiraissue;

select ji.id, ji.pkey, ji.summary, pv1.vname as demandfix, pv2.vname as planfix, q3.vname as fixversion from 
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
	where ji.project = 10002 and ji.issuetype = 5; 
	 