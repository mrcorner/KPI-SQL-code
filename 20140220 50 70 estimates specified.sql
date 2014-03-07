drop table if exists ENO_estimatesDetail;
CREATE  TABLE IF NOT EXISTS ENO_estimatesDetail AS (
	select 
		ji.id, 
		ji.pkey, 
		ji.summary, 
		SAP50.sum50 as 50_SAP,
		Tibco50.sum50 as 50_Tibco,
		EOL50.sum50 as 50_EOL,
		MPR50.sum50 as 50_MPR,
		Streamserve50.sum50 as 50_Streamserve,
		BI50.sum50 as 50_BI,
		Testing50.sum50 as 50_Testing,
		Documentum50.sum50 as 50_Documentum,
		EDSN50.sum50 as 50_EDSN,
		RMS50.sum50 as 50_RMS,
		TEP50.sum50 as 50_TEP,
		Other50.sum50 as 50_Other,
		ALL50.sum50 as 50_All,
		SAP70.sum70 as 70_SAP,
		Tibco70.sum70 as 70_Tibco,
		EOL70.sum70 as 70_EOL,
		MPR70.sum70 as 70_MPR,
		Streamserve70.sum70 as 70_Streamserve,
		BI70.sum70 as 70_BI,
		Testing70.sum70 as 70_Testing,
		Documentum70.sum70 as 70_Documentum,
		EDSN70.sum70 as 70_EDSN,
		RMS70.sum70 as 70_RMS,
		TEP70.sum70 as 70_TEP,
		Other70.sum70 as 70_Other,
		ALL70.sum70 as 70_All
		
		from 
			jiraissue ji
			left join (
			/* SAP */
			select issue, sum(numbervalue) as sum50
				from customfieldvalue 
				inner join customfield on customfield.id = customfieldvalue.customfield 
				where customfield.cfname in (	'ABAP (50%)', 
												'SAP-FICO (50%)', 
												'CRM (50%)',
												'ISU (50%)',
												'FiCa (50%)', 
												'IDEX (50%)')
				group by issue ) as SAP50 on ji.id = SAP50.issue
			left join (
			/* Tibco */
			select issue, sum(numbervalue) as sum50
				from customfieldvalue 
				inner join customfield on customfield.id = customfieldvalue.customfield 
				where customfield.cfname in (	'iDecisions (50%)', 
												'iProcess (50%)', 
												'Tibco BW (50%)', 
												'Integration (50%)')
				group by issue ) as Tibco50 on ji.id = Tibco50.issue
			left join (
			/* EOL */
			select issue, sum(numbervalue) as sum50
				from customfieldvalue 
				inner join customfield on customfield.id = customfieldvalue.customfield 
				where customfield.cfname in (	'EOL (50%)', 
												'Other portals (OCP, 3PP, DMCP) (50%)')
				group by issue ) as EOL50 on ji.id = EOL50.issue
			left join (
			/* MPR */
			select issue, sum(numbervalue) as sum50
				from customfieldvalue 
				inner join customfield on customfield.id = customfieldvalue.customfield 
				where customfield.cfname in (	'MPR (50%)')
				group by issue ) as MPR50 on ji.id = MPR50.issue
			left join (
			/* Streamserve */
			select issue, sum(numbervalue) as sum50
				from customfieldvalue 
				inner join customfield on customfield.id = customfieldvalue.customfield 
				where customfield.cfname in (	'Streamserve (50%)')
				group by issue ) as Streamserve50 on ji.id = Streamserve50.issue
			left join (
			/* BI */
			select issue, sum(numbervalue) as sum50
				from customfieldvalue 
				inner join customfield on customfield.id = customfieldvalue.customfield 
				where customfield.cfname in (	'BI (50%)', 'Qlikview (50%)')
				group by issue ) as BI50 on ji.id = BI50.issue
			left join (
			/* Testing */
			select issue, sum(numbervalue) as sum50
				from customfieldvalue 
				inner join customfield on customfield.id = customfieldvalue.customfield 
				where customfield.cfname in (	'Testing (50%)')
				group by issue ) as Testing50 on ji.id = Testing50.issue
			left join (
			/* Documentum */
			select issue, sum(numbervalue) as sum50
				from customfieldvalue 
				inner join customfield on customfield.id = customfieldvalue.customfield 
				where customfield.cfname in (	'Documentum (50%)')
				group by issue ) as Documentum50 on ji.id = Documentum50.issue
			left join (
			/* EDSN */
			select issue, sum(numbervalue) as sum50
				from customfieldvalue 
				inner join customfield on customfield.id = customfieldvalue.customfield 
				where customfield.cfname in (	'EDSN (50%)')
				group by issue ) as EDSN50 on ji.id = EDSN50.issue
			left join (
			/* RMS */
			select issue, sum(numbervalue) as sum50
				from customfieldvalue 
				inner join customfield on customfield.id = customfieldvalue.customfield 
				where customfield.cfname in (	'RMS (50%)')
				group by issue ) as RMS50 on ji.id = RMS50.issue
			left join (
			/* TEP */
			select issue, sum(numbervalue) as sum50
				from customfieldvalue 
				inner join customfield on customfield.id = customfieldvalue.customfield 
				where customfield.cfname in (	'TEP (50%)')
				group by issue ) as TEP50 on ji.id = TEP50.issue
			left join (
			/* Others */
			select issue, sum(numbervalue) as sum50
				from customfieldvalue 
				inner join customfield on customfield.id = customfieldvalue.customfield 
				where customfield.cfname in (	'API Server (50%)',
												'BSE (50%)',
												'Costs 50%',
												'DM (50%)',	
												'Enterprise Architect (50%)',
												'Essent IT - Business Alignment (50%)',
												'Essent IT - Development (50%)',
												'Essent IT - Maintenance (50%)',
												'F&C (50%)',
												'Ferranti (50%)',
												'Gas Pricing (50%)',
												'GEN Nederland (50%)',
												'GPA (50%)',
												'GPM (50%)',
												'HR (50%)',
												'Infosys (50%)',
												'Matrica (50%)',
												'MCC (50%)',
												'Overig (50%)',
												'Performancetestteam (50%)',
												'Pioneer (50%)',
												'Power Pricing (50%)',
												'PPA (50%)',
												'PPM (50%)',
												'Pratos (50%)',
												'RAPS (50%)',
												'RISK (50%)',
												'RWE IT (50%)',
												'Solution Architect (50%)',
												'STF (50%)',
												'Sustainable (50%)')
				group by issue ) as Other50 on ji.id = Other50.issue
			left join (
			/* Find sum of 50% estimates per issue */
			select issue, sum(numbervalue) as sum50
					from customfieldvalue 
					inner join customfield on customfield.id = customfieldvalue.customfield 
					where customfield.cfname like '%50%'
					group by issue
			) as ALL50 on ALL50.issue = ji.id
			
			left join (
			/* SAP */
			select issue, sum(numbervalue) as sum70
				from customfieldvalue 
				inner join customfield on customfield.id = customfieldvalue.customfield 
				where customfield.cfname in (	'ABAP (70%)', 
												'SAP-FICO (70%)', 
												'CRM (70%)',
												'ISU (70%)',
												'FiCa (70%)', 
												'IDEX (70%)')
				group by issue ) as SAP70 on ji.id = SAP70.issue
			left join (
			/* Tibco */
			select issue, sum(numbervalue) as sum70
				from customfieldvalue 
				inner join customfield on customfield.id = customfieldvalue.customfield 
				where customfield.cfname in (	'iDecisions (70%)', 
												'iProcess (70%)', 
												'Tibco BW (70%)', 
												'Integration (70%)')
				group by issue ) as Tibco70 on ji.id = Tibco70.issue
			left join (
			/* EOL */
			select issue, sum(numbervalue) as sum70
				from customfieldvalue 
				inner join customfield on customfield.id = customfieldvalue.customfield 
				where customfield.cfname in (	'EOL (70%)', 
												'Other portals (OCP, 3PP, DMCP) (70%)')
				group by issue ) as EOL70 on ji.id = EOL70.issue
			left join (
			/* MPR */
			select issue, sum(numbervalue) as sum70
				from customfieldvalue 
				inner join customfield on customfield.id = customfieldvalue.customfield 
				where customfield.cfname in (	'MPR (70%)')
				group by issue ) as MPR70 on ji.id = MPR70.issue
			left join (
			/* Streamserve */
			select issue, sum(numbervalue) as sum70
				from customfieldvalue 
				inner join customfield on customfield.id = customfieldvalue.customfield 
				where customfield.cfname in (	'Streamserve (70%)')
				group by issue ) as Streamserve70 on ji.id = Streamserve70.issue
			left join (
			/* BI */
			select issue, sum(numbervalue) as sum70
				from customfieldvalue 
				inner join customfield on customfield.id = customfieldvalue.customfield 
				where customfield.cfname in (	'BI (70%)', 'Qlikview (70%)')
				group by issue ) as BI70 on ji.id = BI70.issue
			left join (
			/* Testing */
			select issue, sum(numbervalue) as sum70
				from customfieldvalue 
				inner join customfield on customfield.id = customfieldvalue.customfield 
				where customfield.cfname in (	'Testing (70%)')
				group by issue ) as Testing70 on ji.id = Testing70.issue
			left join (
			/* Documentum */
			select issue, sum(numbervalue) as sum70
				from customfieldvalue 
				inner join customfield on customfield.id = customfieldvalue.customfield 
				where customfield.cfname in (	'Documentum (70%)')
				group by issue ) as Documentum70 on ji.id = Documentum70.issue
			left join (
			/* EDSN */
			select issue, sum(numbervalue) as sum70
				from customfieldvalue 
				inner join customfield on customfield.id = customfieldvalue.customfield 
				where customfield.cfname in (	'EDSN (70%)')
				group by issue ) as EDSN70 on ji.id = EDSN70.issue
			left join (
			/* RMS */
			select issue, sum(numbervalue) as sum70
				from customfieldvalue 
				inner join customfield on customfield.id = customfieldvalue.customfield 
				where customfield.cfname in (	'RMS (70%)')
				group by issue ) as RMS70 on ji.id = RMS70.issue
			left join (
			/* TEP */
			select issue, sum(numbervalue) as sum70
				from customfieldvalue 
				inner join customfield on customfield.id = customfieldvalue.customfield 
				where customfield.cfname in (	'TEP (70%)')
				group by issue ) as TEP70 on ji.id = TEP70.issue
			left join (
			/* Others */
			select issue, sum(numbervalue) as sum70
				from customfieldvalue 
				inner join customfield on customfield.id = customfieldvalue.customfield 
				where customfield.cfname in (	'API Server (70%)',
												'BSE (70%)',
												'Costs 70%',
												'DM (70%)',	
												'Enterprise Architect (70%)',
												'Essent IT - Business Alignment (70%)',
												'Essent IT - Development (70%)',
												'Essent IT - Maintenance (70%)',
												'F&C (70%)',
												'Ferranti (70%)',
												'Gas Pricing (70%)',
												'GEN Nederland (70%)',
												'GPA (70%)',
												'GPM (70%)',
												'HR (70%)',
												'Infosys (70%)',
												'Matrica (70%)',
												'MCC (70%)',
												'Overig (70%)',
												'Performancetestteam (70%)',
												'Pioneer (70%)',
												'Power Pricing (70%)',
												'PPA (70%)',
												'PPM (70%)',
												'Pratos (70%)',
												'RAPS (70%)',
												'RISK (70%)',
												'RWE IT (70%)',
												'Solution Architect (70%)',
												'STF (70%)',
												'Sustainable (70%)')
				group by issue ) as Other70 on ji.id = Other70.issue
			left join (
			/* Find sum of 70% estimates per issue */
			select issue, sum(numbervalue) as sum70
					from customfieldvalue 
					inner join customfield on customfield.id = customfieldvalue.customfield 
					where customfield.cfname like '%70%'
					group by issue
			) as ALL70 on ALL70.issue = ji.id

			where ji.project = 10002 and ji.issuetype = 5

);
#select * from ENO_estimatesDetail;
