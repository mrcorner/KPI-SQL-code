ALTER TABLE jiraissue ADD INDEX (id, pkey, project, issuetype, issuestatus, created, updated);
ALTER TABLE changegroup ADD INDEX (id, issueid, created);
ALTER TABLE changeitem ADD INDEX (id, groupid, field, fieldtype);
ALTER TABLE issuestatus ADD INDEX (id, pname);
ALTER TABLE customfieldvalue ADD INDEX (id, issue, customfield);
ALTER TABLE customfield ADD INDEX (id, cfname);
ALTER TABLE customfieldoption ADD INDEX (id, customvalue);

describe customfieldoption;