


/*changes on custom fields */


## add left join to status, to include open (never changed) epics

select ji.pkey, 
       ji.created,
	   issuestatus.pname,
       statuschanges.author,
	   statuschanges.mcreated,
       CONCAT(YEAR(statuschanges.mcreated), ".", WEEKOFYEAR(statuschanges.mcreated)) as weekOfChange,
       CONCAT(statuschanges.OLDSTRING, CONCAT(YEAR(statuschanges.mcreated), ".", WEEKOFYEAR(statuschanges.mcreated))) as 'statusweek',
       statuschanges.OLDSTRING,
       statuschanges.NEWSTRING,
	   if(@lastpkey <> ji.pkey, datediff(statuschanges.mcreated, ji.created), datediff(statuschanges.mcreated, @lastdate)) as timeinstatus, 
       if(issuestatus.pname = statuschanges.NEWSTRING, datediff( now(), statuschanges.mcreated), null) as timeincurrentstatus,
       @lastpkey := ji.pkey,
       @lastdate := ji.statuschanges.mcreated
       from ( select @lastpkey := "none",
               @lastdate := now() ) SQLvars, jiraissue ji inner join (
select issueid, author, created as mcreated, OLDVALUE, OLDSTRING, NEWVALUE, NEWSTRING from changegroup 
	inner join changeitem on changegroup.id = changeitem.groupid
	where field = 'status'
	#group by issueid, newvalue
	order by issueid, created ) as statuschanges on ji.id = statuschanges.issueid
    inner join issuestatus on ji.issuestatus = issuestatus.id
	where ji.issuetype = 5 and ji.project = 10002 and ji.created > '2013-01-01'
	LIMIT 20000;
		