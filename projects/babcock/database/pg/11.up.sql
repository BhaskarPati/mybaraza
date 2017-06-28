

UPDATE entity_types SET entity_role = 'user' WHERE entity_role is null;

UPDATE entity_types SET org_id = 0;

UPDATE entitys SET org_id = 0 WHERE org_id is null;

UPDATE entitys SET org_id = 1 WHERE entity_id = 158;

INSERT INTO entitys (entity_id, org_id, entity_type_id, user_name, entity_name, primary_email, Entity_Leader)  
VALUES (75, 2, 1, 'gmakinde', 'Mrs Makinde Grace', 'gmakinde@babcock.edu.ng', true);

INSERT INTO schools (org_id, schoolid, schoolname) VALUES (2, 'PGST', 'Post Graduate');
INSERT INTO departments (org_id, departmentid, schoolid, departmentname) VALUES (2, 'PGST', 'PGST', 'Post Graduate');

--------------------------
UPDATE departments SET org_id = 0;
UPDATE schools SET org_id = 0;
UPDATE instructors SET org_id = 0;
UPDATE courses SET org_id = 0;
UPDATE prerequisites SET org_id = 0;
UPDATE majors SET org_id = 0;
UPDATE majorcontents SET org_id = 0;
UPDATE students SET org_id = 0;
UPDATE studentdegrees SET org_id = 0;
UPDATE transcriptprint SET org_id = 0;
UPDATE studentmajors SET org_id = 0;
UPDATE transferedcredits SET org_id = 0;
UPDATE studentrequests SET org_id = 0;
UPDATE qstudents SET org_id = 0;
UPDATE studentpayments SET org_id = 0;
UPDATE qcourses SET org_id = 0;
UPDATE qgrades SET org_id = 0;

UPDATE schools SET org_id = 1 WHERE (schoolid = 'MBBS');
UPDATE schools SET org_id = 2 WHERE (schoolid = 'PGST');

UPDATE departments SET org_id = 1 WHERE (schoolid = 'MBBS');
UPDATE departments SET org_id = 2 WHERE (schoolid = 'PGST');

DELETE FROM schools WHERE schoolid = 'CHMS';

UPDATE instructors SET org_id = 1 WHERE (departmentid IN (SELECT departmentid FROM departments WHERE (schoolid = 'MBBS')));
UPDATE courses SET org_id = 1 WHERE (departmentid IN (SELECT departmentid FROM departments WHERE (schoolid = 'MBBS')));
UPDATE prerequisites SET org_id = 1 WHERE (courseid IN (SELECT courseid FROM courses WHERE (org_id = 1)));
UPDATE majors SET org_id = 1 WHERE (departmentid IN (SELECT departmentid FROM departments WHERE (schoolid = 'MBBS')));
UPDATE majorcontents SET org_id = 1 WHERE (majorid IN (SELECT majorid FROM majors WHERE (org_id = 1)));

UPDATE majors SET org_id = 2 WHERE (departmentid IN (SELECT departmentid FROM departments WHERE (schoolid = 'PGST')));
UPDATE majorcontents SET org_id = 2 WHERE (majorid IN (SELECT majorid FROM majors WHERE (org_id = 2)));

UPDATE students SET org_id = 1 WHERE (departmentid IN (SELECT departmentid FROM departments WHERE (schoolid = 'MBBS')));
UPDATE students SET org_id = 2 WHERE (studentid ilike 'p%');

UPDATE studentdegrees SET org_id = 1 WHERE (studentid IN (SELECT studentid FROM students WHERE (org_id = 1)));
UPDATE transcriptprint SET org_id = 1 WHERE (studentdegreeid IN (SELECT studentdegreeid FROM studentdegrees WHERE (org_id = 1)));
UPDATE studentmajors SET org_id = 1 WHERE (studentdegreeid IN (SELECT studentdegreeid FROM studentdegrees WHERE (org_id = 1)));
UPDATE transferedcredits SET org_id = 1 WHERE (studentdegreeid IN (SELECT studentdegreeid FROM studentdegrees WHERE (org_id = 1)));
UPDATE studentrequests SET org_id = 1 WHERE (studentid IN (SELECT studentid FROM students WHERE (org_id = 1)));
UPDATE qstudents SET org_id = 1 WHERE (studentdegreeid IN (SELECT studentdegreeid FROM studentdegrees WHERE (org_id = 1)));
UPDATE studentpayments SET org_id = 1 WHERE (qstudentid IN (SELECT qstudentid FROM qstudents WHERE (org_id = 1)));
UPDATE qcourses SET org_id = 1 WHERE (courseid IN (SELECT courseid FROM courses WHERE (org_id = 1)));
UPDATE qgrades SET org_id = 1 WHERE (qstudentid IN (SELECT qstudentid FROM qstudents WHERE (org_id = 1)));

UPDATE studentdegrees SET org_id = 2 WHERE (studentid IN (SELECT studentid FROM students WHERE (org_id = 2)));
UPDATE transcriptprint SET org_id = 2 WHERE (studentdegreeid IN (SELECT studentdegreeid FROM studentdegrees WHERE (org_id = 2)));
UPDATE studentmajors SET org_id = 2 WHERE (studentdegreeid IN (SELECT studentdegreeid FROM studentdegrees WHERE (org_id = 2)));
UPDATE transferedcredits SET org_id = 2 WHERE (studentdegreeid IN (SELECT studentdegreeid FROM studentdegrees WHERE (org_id = 2)));
UPDATE studentrequests SET org_id = 2 WHERE (studentid IN (SELECT studentid FROM students WHERE (org_id = 2)));
UPDATE qstudents SET org_id = 2 WHERE (studentdegreeid IN (SELECT studentdegreeid FROM studentdegrees WHERE (org_id = 2)));
UPDATE studentpayments SET org_id = 2 WHERE (qstudentid IN (SELECT qstudentid FROM qstudents WHERE (org_id = 2)));
UPDATE qcourses SET org_id = 2 WHERE (courseid IN (SELECT courseid FROM courses WHERE (org_id = 2)));
UPDATE qgrades SET org_id = 2 WHERE (qstudentid IN (SELECT qstudentid FROM qstudents WHERE (org_id = 2)));


