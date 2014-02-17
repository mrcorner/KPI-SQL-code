#20131224




#20131223

explain select ji.id, 
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
    order by ji.id, created;



#20131219

select * from label;

select * from customfield where cfname like "%A Rea%";

select * from customfieldvalue where customfield = 10114;

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

#20140124

select * from ENO_kpi_all;
select ki.*, ct.overhead * ki.`Sum of 50%` as corrected50 from ENO_kpi_all ki left join calendar_table ct on ct.dt = max(date(ki.created), date(ki.`Timestamp 50%`)) where ki.`Sum of 50%`is not null;

select overhead from calendar_table where dt = date(now());
