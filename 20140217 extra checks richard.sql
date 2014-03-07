select * 
	from ENO_kpi_all 
	where  	`Sum of 50%` is not null 
			and `Sum of 70%` is null
			and `On Hold` is null
			and `Status` <> 'Closed'
			and `Status` <> 'Resolved'
	limit 10000;


select * 
	from ENO_kpi_all 
	where  	`Sum of 70%` is not null
			and `Team(s)` is null
			and `Status` <> 'Closed'
			and `Status` <> 'Resolved'
	limit 10000;