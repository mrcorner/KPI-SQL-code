ALTER TABLE jiraissue 			ADD INDEX (id),
								add index (pkey),
								add index (issuetype),
								add index (issuestatus),
								add index (created),
								add index (updated),
								add index (project); 
ALTER TABLE changegroup 		ADD INDEX (id), 
								add index (issueid), 
								add index (created);
ALTER TABLE changeitem 			ADD INDEX (id), 
								add index (groupid), 
								add index (field), 
								add index (fieldtype);
ALTER TABLE issuestatus 		ADD INDEX (id), 
								add index (pname);
ALTER TABLE customfieldvalue 	ADD INDEX (id), 
								add index (issue), 
								add index (customfield), 
								add index (STRINGVALUE);
ALTER TABLE customfield 		ADD INDEX (id), 
								add index (cfname);
ALTER TABLE customfieldoption 	ADD INDEX (id), 
								add index (customvalue);
