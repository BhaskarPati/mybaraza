

INSERT INTO charges (quarterid, sublevelid, unit_charge, lab_charges, exam_fees, general_fees)
SELECT quarterid, sublevelid, unitcharge, labcharges, exam_fees, fees
FROM qsubcharges
ORDER BY quarterid, sublevelid;

INSERT INTO charges (quarterid, sublevelid, unit_charge, lab_charges, exam_fees, general_fees)
SELECT DISTINCT a.quarterid, a.sublevelid, a.unitcharge, a.labcharges, a.exam_fees, a.fees
FROM 
(SELECT DISTINCT sublevels.sublevelid, qcharges.quarterid, qcharges.unitcharge, qcharges.labcharges, qcharges.exam_fees, qcharges.fees
FROM sublevels INNER JOIN qcharges ON sublevels.degreelevelid = qcharges.degreelevelid) as a
LEFT JOIN qsubcharges ON (a.sublevelid = qsubcharges.sublevelid) AND (a.quarterid = qsubcharges.quarterid)
WHERE qsubcharges.sublevelid is null
ORDER BY a.quarterid, a.sublevelid;

CREATE FUNCTION get_charge_id(integer, varchar(12)) RETURNS integer AS $$
	SELECT charges.charge_id
	FROM charges INNER JOIN studentdegrees ON charges.sublevelid = studentdegrees.sublevelid
	WHERE (studentdegrees.studentdegreeid = $1) AND (charges.quarterid = $2);
$$ LANGUAGE SQL;

DELETE FROM qstudents WHERE studentdegreeid is null;
DELETE FROM qstudents WHERE quarterid is null;

UPDATE qstudents SET charge_id = get_charge_id(studentdegreeid, quarterid);
DROP FUNCTION get_charge_id(integer, varchar(12));

UPDATE qcourses SET levellocationid = 1;

----------- Copy the users into the system

DROP TRIGGER ins_password ON entitys;

DELETE FROM sys_logins;

DELETE FROM entity_subscriptions;
DELETE FROM entitys;
DELETE FROM entity_types;

INSERT INTO entity_types (entity_type_id, entity_type_name, Description, Details)
SELECT UserGroupID, UserGroupName, Description, Activities
FROM UserGroups 
ORDER BY UserGroupID;

INSERT INTO entitys (entity_id, org_id, entity_type_id, entity_name, user_name, super_user,
	entity_leader, function_role, is_active, entity_password, first_password, details)
SELECT UserID, 0, UserGroupID, FullName, username, SuperUser, GroupLeader, 
	RoleName, IsActive, userpasswd, firstpasswd, Details
FROM Users;

DROP TABLE Users;
DROP TABLE UserGroups;
DROP TABLE qsubcharges;
DROP TABLE qcharges;

INSERT INTO entity_types (entity_type_id, entity_type_name, entity_role)
VALUES (8, 'Applicants', 'applicant');
INSERT INTO entity_types (entity_type_id, entity_type_name, entity_role)
VALUES (9, 'Students', 'student');
INSERT INTO entity_types (entity_type_id, entity_type_name, entity_role)
VALUES (10, 'Guardians', 'guardian');
INSERT INTO entity_types (entity_type_id, entity_type_name, entity_role)
VALUES (11, 'Lecturers', 'lecturer');
INSERT INTO entity_types (entity_type_id, entity_type_name, entity_role)
VALUES (12, 'Industry', 'industry');

UPDATE entity_types SET entity_role = 'admin' WHERE entity_type_id = 0;


SELECT setval('entitys_entity_id_seq', 2000);

INSERT INTO entitys (org_id, entity_type_id, entity_name, user_name, primary_email, first_password, entity_password)
SELECT 0, 8, firstname || ' ' || lastname, email, email, firstpass, md5(firstpass)
FROM registrations;

INSERT INTO entitys (org_id, entity_type_id, entity_name, user_name, primary_email, first_password, entity_password)
SELECT 0, 9, studentname, studentid, email, firstpass, studentpass
FROM students;

INSERT INTO entitys (org_id, entity_type_id, entity_name, user_name, primary_email, first_password, entity_password)
SELECT 0, 10, COALESCE(guardianname, studentname), 'G' || studentid, gemail, gfirstpass, gstudentpass
FROM students;

INSERT INTO entitys (org_id, entity_type_id, entity_name, user_name, first_password, entity_password)
SELECT 0, 11, instructorname, instructorid, firstpass, instructorpass
FROM instructors;

CREATE TRIGGER ins_password BEFORE INSERT OR UPDATE ON entitys
    FOR EACH ROW EXECUTE PROCEDURE ins_password();

UPDATE qcourses SET session_title = courses.coursetitle
FROM courses WHERE qcourses.courseid = courses.courseid;

---- Create default emails

INSERT INTO sys_emails (sys_email_id, sys_email_name, title, details)
VALUES (1, 'Applications', 'Student Application', 'Thank you for applying to the University of East Africa, Baraton');
INSERT INTO sys_emails (sys_email_id, sys_email_name, title, details)
VALUES (2, 'Applications', 'Student Application', 'Thank you for applying to the University of East Africa, Baraton');
SELECT setval('sys_emails_sys_email_id_seq', 2);

------------------- Update the default residence and room
CREATE FUNCTION get_student_residence_id(varchar(12)) RETURNS varchar(12) AS $$
	SELECT MAX(qresidences.residenceid)
	FROM qstudents INNER JOIN qresidences ON qstudents.qresidenceid = qresidences.qresidenceid
	WHERE qstudents.qstudentid IN
		(SELECT max(qstudents.qstudentid)
		FROM studentdegrees INNER JOIN qstudents ON studentdegrees.studentdegreeid = qstudents.studentdegreeid
		WHERE (studentdegrees.studentid = $1));
$$ LANGUAGE SQL;

CREATE FUNCTION get_student_room_number(varchar(12)) RETURNS integer AS $$
	SELECT MAX(qstudents.roomnumber)
	FROM qstudents 
	WHERE qstudents.qstudentid IN
		(SELECT max(qstudents.qstudentid)
		FROM studentdegrees INNER JOIN qstudents ON studentdegrees.studentdegreeid = qstudents.studentdegreeid
		WHERE (qstudents.roomnumber is not null) AND (studentdegrees.studentid = $1));
$$ LANGUAGE SQL;

UPDATE students SET residenceid = get_student_residence_id(studentid), room_number = get_student_room_number(studentid);

DROP FUNCTION get_student_residence_id(varchar(12));
DROP FUNCTION get_student_room_number(varchar(12));

UPDATE transcriptprint SET accepted = true;

---- ORG ID updates
UPDATE qcourses SET org_id = 0, levellocationid = 1;

UPDATE entity_types SET org_id = 0;
UPDATE entitys SET org_id = 0;

UPDATE levellocations SET org_id = 0;
UPDATE sublevels SET org_id = 0;
UPDATE residences SET org_id = 0;
UPDATE assets SET org_id = 0;
UPDATE instructors SET org_id = 0;
UPDATE sabathclasses SET org_id = 0;
UPDATE students SET org_id = 0;
UPDATE studentrequests SET org_id = 0;
UPDATE qcalendar SET org_id = 0;
UPDATE qresidences SET org_id = 0;
UPDATE charges SET org_id = 0;
UPDATE qstudents SET org_id = 0;
UPDATE qgrades SET org_id = 0;

