#20131219

select * from label;

select * from customfield where cfname like "%abel%";

select * from customfieldvalue where customfield = 10113;

select ji.id, ji.pkey, group_concat(label.label separator ', ') as labels from jiraissue ji left join label  on ji.id = label.issue
	where ji.project = 10002 and ji.issuetype = 5
	group by ji.id;

select js.pname, count(ji.id), year(ji.created) as myear 
	from jiraissue ji inner join issuestatus js on ji.issuestatus = js.id 
	where project = '10002'
	group by myear, js.pname;

select * from issuestatus;

select jiraissue.id, issuestatus.pname from jiraissue inner join issuestatus on jiraissue.id = issuestatus.id;

select * from jiraissue;

select * from jiraissue where pkey = "EPB-8055" ;

SELECT jiraissue.id, projectversion.id, projectversion.vname
		FROM projectversion,
		nodeassociation,
		jiraissue
		WHERE ASSOCIATION_TYPE = 'IssueFixVersion'
		AND SINK_NODE_ID = projectversion.id
		AND SOURCE_NODE_ID = jiraissue.id
		#and projectversion.vname not like '%ear%'
		and jiraissue.id = 32665 	
		group by jiraissue.id;

	
select pv1.id, pv1.pvid, pv2.vname from (SELECT jiraissue.id, max(projectversion.id) as pvid 
		FROM projectversion,
		nodeassociation,
		jiraissue
		WHERE ASSOCIATION_TYPE = 'IssueFixVersion'
		AND SINK_NODE_ID = projectversion.id
		AND SOURCE_NODE_ID = jiraissue.id
		#and projectversion.vname not like '%ear%'
		and jiraissue.id = 32665 	
		group by jiraissue.id) as pv1 inner join projectversion pv2 on pv1.pvid = pv2.id;



select fv.id, projectversion.vname from (select ji.id, max(projectversion.id) as maxpvid from jiraissue ji
	left join nodeassociation on source_node_id = ji.id
	left join projectversion on projectversion.id = nodeassociation.sink_node_id
	where nodeassociation.ASSOCIATION_TYPE = 'IssueFixVersion'
	and projectversion.vname not like '%ear%'
	and ji.id = 32665) as fv inner join projectversion on fv.maxpvid = projectversion.id
;

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
	select fv.id, projectversion.vname from (select ji.id, max(projectversion.id) as maxpvid from jiraissue ji
		left join nodeassociation on source_node_id = ji.id
		left join projectversion on projectversion.id = nodeassociation.sink_node_id
		where nodeassociation.ASSOCIATION_TYPE = 'IssueFixVersion'
		and projectversion.vname not like '%ear%'
		group by ji.id
	) as fv inner join projectversion on fv.maxpvid = projectversion.id) as q3 on q1.id = q3.id
	where ji.project = 10002 and ji.issuetype = 5 
; 
	
 limit 100000;



