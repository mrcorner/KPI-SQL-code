drop temporary table if exists ENO_parentlinks;



#select * from issuestatus;

drop table if exists ENO_themeEpicMapping;
CREATE TABLE IF NOT EXISTS ENO_themeEpicMapping AS (
select jithemes.id, 
       jithemes.pkey as ThemeKey, 
	   jithemes.summary as ThemeSummary,
       jithemes.ThemeStatus as ThemeStatus,
	   tshirtsize.customvalue as ThemeSize,
	   projectcode.projectcode as ProjectCode,

	   #issuelink.source,
	   #issuelink.destination,
	   #issuelink.linktype,
	   jiepics.id as EpicId,
	   jiepics.pkey as EpicKey,
	   jiepics.summary as EpicSummary,
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
	
);

alter table ENO_themeEpicMapping add epicCount INT(7) NULL;
alter table ENO_themeEpicMapping add epicTshirt INT(7) NULL;

drop table if exists ENO_themeEpicMappingCount;
CREATE TABLE IF NOT EXISTS ENO_themeEpicMappingCount AS (
	select id, themeKey, count(epicKey) as ec from ENO_themeEpicMapping as mm group by themeKey
);

update ENO_themeEpicMapping tem inner join 
	ENO_themeEpicMappingCount as tec on tem.id = tec.id 
	set tem.epicCount = tec.ec;

update ENO_themeEpicMapping tem 
	set tem.epicTshirt = 25 / tem.epicCount
	where tem.ThemeSize = '<30K Small';
update ENO_themeEpicMapping tem 
	set tem.epicTshirt = 150 / tem.epicCount
	where tem.ThemeSize = '30K-200K Medium';
update ENO_themeEpicMapping tem 
	set tem.epicTshirt = 300 / tem.epicCount
	where tem.ThemeSize = '200K-500K Large';
update ENO_themeEpicMapping tem 
	set tem.epicTshirt = 600 / tem.epicCount
	where tem.ThemeSize = '>500K Extra Large';

select * from  ENO_themeEpicMapping;


#select * from customfieldoption where customfield = 11238;

