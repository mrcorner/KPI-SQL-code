select * from view_kpi_all limit 10000;
select * from view_statustimes limit 10000;
select * from view_saready limit 10000;
select * from view_sareadychanges limit 10000;
select * from view_worklists_all limit 10000;
select * from view_worklists_selection limit 10000;
select * from view_voorraad limit 10000;
select * from view_dump_all limit 10000;
select * from view_b2ball limit 10000;
#select * from view_epicthememapping limit 10000;


SELECT * from view_kpi_all INTO OUTFILE '/tmp/1kpiall.jiradump';
SELECT * from view_statustimes INTO OUTFILE '/tmp/2statustimes.jiradump';
SELECT * from view_saready INTO OUTFILE '/tmp/3saready.jiradump';
SELECT * from view_sareadychanges INTO OUTFILE '/tmp/4sareadychanges.jiradump';
SELECT * from view_worklists_all INTO OUTFILE '/tmp/5worklistall.jiradump';
SELECT * from view_worklists_selection INTO OUTFILE '/tmp/6worklistselection.jiradump';
SELECT * from view_voorraad INTO OUTFILE '/tmp/7voorraad.jiradump';
SELECT * from view_b2ball INTO OUTFILE '/tmp/8b2ball.jiradump';
SELECT * from view_dump_all INTO OUTFILE '/tmp/9dumpall.xls';

