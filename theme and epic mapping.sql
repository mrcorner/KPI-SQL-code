drop temporary table if exists ENO_parentlinks;



 select * from issuestatus;

select jithemes.id, 
       jithemes.pkey as ThemeKey, 
	   jithemes.summary as ThemeSummary,
       jithemes.ThemeStatus as ThemeStatus,
	   tshirtsize.customvalue as ThemeSize,
	   projectcode.projectcode as ProjectCode,

	   #issuelink.source,
	   #issuelink.destination,
	   #issuelink.linktype,
	   jiepics.pkey as EpicKey,
	   jithemes.summary as EpicSummary,
	   jiepics.EpicStatus as EpicStatus,
	   nwp.nwp as EpicNWP
	from (
	select ji.*, issuestatus.pname as ThemeStatus
		from jiraissue ji inner join issuestatus on ji.issuestatus = issuestatus.id
		where project = 10002
		and issuetype = 9 #theme
	) as jithemes
	inner join issuelink on jithemes.id = issuelink.destination
	inner join (
		select ji.*, issuestatus.pname as EpicStatus
			from jiraissue ji inner join issuestatus on ji.issuestatus = issuestatus.id
			where project = 10002
			and ji.issuetype = 5
	) as jiepics
	on jiepics.id = issuelink.source
	left join (select cv.issue, cvo.customvalue from customfieldvalue cv
						inner join customfieldoption cvo 
						on cvo.id = cv.stringvalue 
						where cv.customfield = 11238
			   ) tshirtsize on tshirtsize.issue = jithemes.id
	left join 	(select cv.issue, cv.stringvalue as projectcode from customfieldvalue cv 
					where cv.customfield = 11336) 
				as projectcode on projectcode.issue = jithemes.id
	left join 	(select cv.issue, cv.stringvalue as nwp from customfieldvalue cv 
					where cv.customfield = 10546) 
				as nwp on nwp.issue = jiepics.id
	where issuelink.linktype = 10000 #parent links
	
	order by jithemes.id
	;

select * from jiraissue	left join (select cv.issue, cv.stringvalue as nwp from customfieldvalue cv 
					where cv.customfield = 10546) 
				as nwp on nwp.issue = jiraissue.id where nwp is not null;

select * from issuetype;
select * from issuelink;
select * from issuelinktype;
select * from customfieldoption ;
select * from customfield where cfname like '%abel%';

select * from customfieldvalue cv where cv.customfield = 10076;