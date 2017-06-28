DROP TRIGGER ins_password ON entitys;

DELETE FROM sys_logins;
DELETE FROM entity_subscriptions;
DELETE FROM entitys;
DELETE FROM entity_types;

INSERT INTO entity_types (entity_type_id, entity_type_name, Description, Details)
SELECT UserGroupID, UserGroupName, Description, Activities
FROM UserGroups 
ORDER BY UserGroupID;

INSERT INTO entitys (org_id, entity_type_id, entity_name, user_name, super_user,
	entity_leader, function_role, is_active, entity_password, first_password, details)
SELECT 0, UserGroupID, FullName, username, SuperUser, GroupLeader, 
	RoleName, IsActive, userpasswd, firstpasswd, Details
FROM Users;

DROP TABLE Users;
DROP TABLE UserGroups;

INSERT INTO entity_types (entity_type_id, entity_type_name, entity_role)
VALUES (20, 'Applicants', 'applicant');
INSERT INTO entity_types (entity_type_id, entity_type_name, entity_role)
VALUES (21, 'Students', 'student');
INSERT INTO entity_types (entity_type_id, entity_type_name, entity_role)
VALUES (22, 'Guardians', 'guardian');
INSERT INTO entity_types (entity_type_id, entity_type_name, entity_role)
VALUES (23, 'Lecturers', 'lecturer');
INSERT INTO entity_types (entity_type_id, entity_type_name, entity_role)
VALUES (24, 'Industry', 'industry');
SELECT setval('entity_types_entity_type_id_seq', 25);

INSERT INTO entitys (org_id, entity_type_id, entity_name, user_name, primary_email, first_password, entity_password)
SELECT 0, 21, studentname, studentid, email, firstpasswd, userpasswd
FROM students;

INSERT INTO entitys (org_id, entity_type_id, entity_name, user_name, first_password, entity_password)
SELECT 0, 23, instructorname, instructorid, firstpasswd, userpasswd
FROM instructors;

CREATE TRIGGER ins_password BEFORE INSERT OR UPDATE ON entitys
    FOR EACH ROW EXECUTE PROCEDURE ins_password();


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

UPDATE students SET org_id = 0;
UPDATE studentdegrees SET org_id = 0;
UPDATE studentrequests SET org_id = 0;
UPDATE quarters SET org_id = 0;
UPDATE qresidences SET org_id = 0;


