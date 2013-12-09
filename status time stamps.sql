select * from projectversion where project = 10002 and vname like '%ear%';


select * from jiraissue inner join issuestatus on jiraissue.issuestatus = issuestatus.id;


/*changes on custom fields */

select * from customfieldvalue;;
select * from changegroup;
select * from changeitem where field = 'status';

select ji.id, ji.pkey, ji.summary, q1.* from jiraissue ji inner join (
select issueid, author, created as mcreated, OLDVALUE, OLDSTRING, NEWVALUE, NEWSTRING from changegroup 
	inner join changeitem on changegroup.id = changeitem.groupid
	where field = 'status'
	#group by issueid, newvalue
	order by issueid, created ) as q1 on ji.id = q1.issueid
	where ji.issuetype = 5 and mcreated > '2013-01-01' and ji.project = 10002
	LIMIT 10000;
		