ALTER TABLE entity_types ADD start_view varchar(50);
ALTER TABLE entitys ADD no_org boolean default false;

UPDATE students SET birthdate = '1967-09-09' WHERE studentid = 'SOTIEU1311';
UPDATE students SET birthdate = '1994-06-12' WHERE studentid = 'SSAMCA1331';

UPDATE students SET countrycodeid = 'KE' WHERE countrycodeid is null;
UPDATE students SET gcountrycodeid = 'KE' WHERE gcountrycodeid is null;

DELETE FROM studentdegrees WHERE studentdegreeid = 19299;
UPDATE studentdegrees SET started = '2080-04-15' WHERE studentdegreeid = 15296;

update qstudents set firstdate = null where firstdate < '1900-01-01';
update qstudents set seconddate = null where seconddate < '1900-01-01';
update qstudents set firstdate = null where firstdate > '2014-01-01';
update qstudents set seconddate = null where seconddate > '2014-01-01';

DELETE FROM qmeetings
WHERE (qstudentid IN (SELECT qstudents.qstudentid
FROM qstudents LEFT JOIN qgrades ON qstudents.qstudentid = qgrades.qstudentid
WHERE (qgrades.qstudentid is null)));

DELETE FROM approvallist
WHERE (qstudentid IN (SELECT qstudents.qstudentid
FROM qstudents LEFT JOIN qgrades ON qstudents.qstudentid = qgrades.qstudentid
WHERE (qgrades.qstudentid is null)));

DELETE FROM qstudents
WHERE (qstudentid IN (SELECT qstudents.qstudentid
FROM qstudents LEFT JOIN qgrades ON qstudents.qstudentid = qgrades.qstudentid
WHERE (qgrades.qstudentid is null)));

UPDATE qstudents SET qresidenceid = qresidences.qresidenceid
FROM qresidences 
WHERE (qstudents.qresidenceid is null) AND (qresidences.quarterid = qresidences.quarterid) AND (qresidences.residenceid = 'OC');

delete from studentmajors where studentdegreeid IN (SELECT studentdegreeid from studentdegrees where studentid ilike '%''%');
delete from studentdegrees where studentid ilike '%''%';
delete from students where studentid ilike '%''%';

delete from gradechangelist where qgradeid in (select qgradeid from qgrades where dropped = true);
delete from qgrades where dropped = true;

delete from gradechangelist where qgradeid = 1048071;
delete from qgrades where qgradeid = 1048071;
delete from gradechangelist where qgradeid = 1106319;
delete from qgrades where qgradeid = 1106319;
delete from gradechangelist where qgradeid = 1107426;
delete from qgrades where qgradeid = 1107426;
delete from gradechangelist where qgradeid = 1123206;
delete from qgrades where qgradeid = 1123206;

delete from gradechangelist where qgradeid = 1124491;
delete from qgrades where qgradeid = 875991;
delete from gradechangelist where qgradeid = 909060;
delete from qgrades where qgradeid = 909060;
delete from qgrades where qgradeid = 935024;
delete from qgrades where qgradeid = 935224;
delete from qgrades where qgradeid = 935222;
delete from qgrades where qgradeid = 940121;
delete from qgrades where qgradeid = 1073415;
delete from qgrades where qgradeid = 1020595;
delete from gradechangelist where qgradeid = 1074830;
delete from qgrades where qgradeid = 1074830;
delete from qgrades where qgradeid = 1124491;

UPDATE registrations SET baptismdate = null WHERE baptismdate  < '1900-01-01';
UPDATE registrations SET baptismdate = null WHERE baptismdate  > '2014-01-01';

UPDATE registryschools SET edate = null WHERE edate  < '1900-01-01';
UPDATE registryschools SET edate = null WHERE edate  > '2014-01-01';

UPDATE regcontacts SET countrycodeid = 'KE' WHERE countrycodeid = 'XX';

delete from studentmajors where studentdegreeid = 17168;
delete from studentdegrees where studentdegreeid = 17168;



