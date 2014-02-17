# New SA KPI report based on actual ready date and SA ready field

#timestamp of ready date
drop temporary table if exists ENO_dateready;
CREATE TEMPORARY TABLE IF NOT EXISTS ENO_dateready AS (select ji.id, q1.* from jiraissue ji inner join (
select issueid, max(created) as endready, OLDSTRING, NEWSTRING from changegroup 
	inner join changeitem on changegroup.id = changeitem.groupid
	where field = 'status' 
	and OLDSTRING = 'Preparing'
	and NEWSTRING = 'Ready'
	#group by issueid, newvalue
	group by issueid
	order by issueid ) as q1 on ji.id = q1.issueid
	where ji.issuetype = 5 and ji.project = 10002);
select * from ENO_dateready;

#changes on SAready field

select 
	issueid, 
	author, 
	created as dateOfChange,
	CONCAT(YEAR(created), ".", WEEKOFYEAR(created)) as weekOfChange,
	OLDVALUE, 
	NEWVALUE 
	from changegroup 
	inner join changeitem on changegroup.id = changeitem.groupid
	where field = 'SA Ready'
	and OLDVALUE is not null
			#group by issueid
			#order by issueid, created
;

# master data table
select 
	ji.id, 
	ji.pkey, 
	ji.summary, 
	issuestatus.pname, 
	cfHold.customvalue as onHold, 
	solutionarchitect.stringvalue as solutionarchitect,
	bse.stringvalue as bse,
	saready.datevalue as SAReady,
	if (issuestatus.pname in ("Open", "Specification", "Preparing") and saready.datevalue is not null, 
		if (saready.datevalue > adddate(date(now()),7), "On Time", if(saready.datevalue >= date(now()), "Due", if(saready.datevalue >= subdate(date(now()),7), "Overdue 0-7", "Overdue >7"))), 
		"NVT") as currentDue, 
	
	if (issuestatus.pname not in ("Open", "Specification", "Preparing") and saready.datevalue is not null, 
		if (saready.datevalue >= date(dr.endready), "On Time", if(saready.datevalue >= subdate(date(dr.endready),7), "Overdue 0-7", "Overdue >7")),
	"NVT") as historicDue, 
	dr.endready as ActualReady,
	CONCAT(YEAR(dr.endready), ".", WEEKOFYEAR(dr.endready)) as weekActualReady
from jiraissue ji
	inner join issuestatus on ji.issuestatus = issuestatus.id
	left join (
		select * from customfieldvalue where customfield = 10114) solutionarchitect on solutionarchitect.issue = ji.id
	left join (
		select * from customfieldvalue where customfield = 10014) bse on bse.issue = ji.id
	left join (
		select * from customfieldvalue where customfield = 12837) saready on saready.issue = ji.id
	left join (
		select customfieldvalue.issue, customfieldoption.customvalue 
			from customfieldvalue inner join customfieldoption on customfieldoption.id = customfieldvalue.STRINGVALUE
			where customfieldvalue.customfield=10067) as cfHold on cfHold.issue = ji.id 
	left join ENO_dateready dr on ji.id = dr.id
where ji.project = 10002 
	and ji.issuetype = 5
	#and saready.datevalue is not null
limit 10000
	;






