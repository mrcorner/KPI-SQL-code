# Issues with sums of estimate fields
select ji.id, ji.pkey, ji.summary, issuestatus.pname, cfTeam.customvalue as Team, ji.updated, sumfifty.sum50, sumseventy.sum70, storypoints.numbervalue as 'Story Points'
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
;


#Help queries
select * from groupbase;
select * from jiraissue;
select * from customfieldvalue;
select * from customfield;
select * from customfieldoption where customfield = 10024; 
select * from changegroup;
select * from changeitem where field like '%50%';

#Issues with last updates of estimate fields

select ji.id, ji.pkey, ji.summary, q1.*, q2.maxStamp50, q2.NEWSTRING, q3.maxStamp70, q3.NEWSTRING from jiraissue ji left join (
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
	where ji.issuetype = 5 and (maxStampStoryPoints > '2013-01-01' or maxStampStoryPoints is null) and ji.project = 10002;
