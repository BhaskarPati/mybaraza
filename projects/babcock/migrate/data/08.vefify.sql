SELECT *
FROM pg_majors LEFT JOIN majors ON pg_majors.majorid = majors.majorid
WHERE (majors.majorid is null);

UPDATE majors SET org_id = 2 WHERE majorid IN
(SELECT majorid FROM pg_majors);

INSERT INTO courses(departmentid, degreelevelid, coursetypeid, org_id, courseid, coursetitle, credithours, lecturehours, yeartaken)
SELECT DISTINCT 'PGST', pg_courses.degreelevelid, 0, 2, upper(trim(pg_courses.courseid)), 
	pg_courses.coursetitle, pg_courses.credithours, pg_courses.credithours, cast(substring(pg_courses.courseid from 5 for 1) as int)
FROM pg_courses LEFT JOIN courses ON upper(trim(pg_courses.courseid)) = upper(trim(courses.courseid))
WHERE courses.courseid is null;

UPDATE pg_results SET studentid = 'PG/11/0194' WHERE studentid = 'PG/AKINOLA';
INSERT INTO pg_students (degreeid, degreename, majorid, majorname, studentid, surname, firstname, othernames, sex) VALUES ('PHD', 'Doctor of Philosophy', 'PGPS', ' Political Science', 'PG/11/0194','AKONI', 'OMOTOLA', 'IBIDUNNI', 'M');

INSERT INTO students (departmentid, denominationid, org_id, Sex, MaritalStatus, Nationality, countrycodeid, gcountrycodeid, stateid,
	studentid, surname, firstname, othernames)
SELECT 'PGST', 'CHRI', 2, pg_students.sex, 'S', 'NG', 'NG', 'NG', 39,
	trim(upper(pg_students.studentid)), trim(pg_students.surname), trim(pg_students.firstname), trim(pg_students.othernames)
FROM pg_students LEFT JOIN students ON trim(upper(pg_students.studentid)) = trim(upper(students.studentid))
WHERE (students.studentid is null);

INSERT INTO studentdegrees (degreeid, studentid, sublevelid, bulletingid, org_id)
SELECT DISTINCT trim(upper(pg_students.degreeid)), trim(upper(pg_students.studentid)), 'MAST', 0, 2
FROM pg_students LEFT JOIN studentdegrees ON (trim(upper(pg_students.studentid))) = (trim(upper(studentdegrees.studentid)))
WHERE studentdegrees.studentid is null;

INSERT INTO studentmajors (studentdegreeid, majorid, org_id)
SELECT DISTINCT studentdegrees.studentdegreeid, pg_students.majorid, 2
FROM pg_students INNER JOIN studentdegrees ON pg_students.studentid = studentdegrees.studentid
LEFT JOIN studentmajors ON studentdegrees.studentdegreeid = studentmajors.studentdegreeid
WHERE (studentmajors.studentdegreeid is null);

UPDATE students SET org_id = 2 WHERE trim(upper(studentid)) IN
(SELECT trim(upper(studentid)) FROM pg_students);

UPDATE studentdegrees SET org_id = 2 WHERE trim(upper(studentid)) IN
(SELECT trim(upper(studentid)) FROM pg_students);

UPDATE pg_results SET courseid = 'IRMA899' WHERE courseid = 'IRMA 899';
UPDATE pg_results SET courseid = 'PMKM812' WHERE trim(upper(courseid)) =  'MKM812';
UPDATE pg_results SET courseid = 'PMKM852' WHERE trim(upper(courseid)) =  'MKM852';
UPDATE pg_results SET courseid = 'PMKM872' WHERE trim(upper(courseid)) =  'MKM872';
UPDATE pg_results SET courseid = 'PMKM891' WHERE trim(upper(courseid)) =  'MKM891';

INSERT INTO courses(departmentid, degreelevelid, coursetypeid, org_id, courseid, coursetitle, credithours, lecturehours, yeartaken) VALUES ('PGST', 'MAS', 0, 2, 'AMNS899', 'Thesis', 2, 2, 8);
INSERT INTO courses(departmentid, degreelevelid, coursetypeid, org_id, courseid, coursetitle, credithours, lecturehours, yeartaken) VALUES ('PGST', 'MAS', 0, 2, 'BCHM899', 'Thesis', 2, 2, 8);
INSERT INTO courses(departmentid, degreelevelid, coursetypeid, org_id, courseid, coursetitle, credithours, lecturehours, yeartaken) VALUES ('PGST', 'MAS', 0, 2, 'BSAD801', 'Reseach Methods', 2, 2, 8);
INSERT INTO courses(departmentid, degreelevelid, coursetypeid, org_id, courseid, coursetitle, credithours, lecturehours, yeartaken) VALUES ('PGST', 'MAS', 0, 2, 'IRMA832', 'Telecommunication and Netwroking', 2, 2, 8);
INSERT INTO courses(departmentid, degreelevelid, coursetypeid, org_id, courseid, coursetitle, credithours, lecturehours, yeartaken) VALUES ('PGST', 'MAS', 0, 2, 'MBIO899', 'Thesis', 2, 2, 8);
INSERT INTO courses(departmentid, degreelevelid, coursetypeid, org_id, courseid, coursetitle, credithours, lecturehours, yeartaken) VALUES ('PGST', 'MAS', 0, 2, 'PBMG832', 'Advanced Issues in Administrative Ethics', 2, 2, 8);
INSERT INTO courses(departmentid, degreelevelid, coursetypeid, org_id, courseid, coursetitle, credithours, lecturehours, yeartaken) VALUES ('PGST', 'MAS', 0, 2, 'PHFC925', 'Policy Issues and Advocacy of Public Health', 2, 2, 9);
INSERT INTO courses(departmentid, degreelevelid, coursetypeid, org_id, courseid, coursetitle, credithours, lecturehours, yeartaken) VALUES ('PGST', 'MAS', 0, 2, 'PHHP928', 'Field Work/Internship', 2, 2, 9);
INSERT INTO courses(departmentid, degreelevelid, coursetypeid, org_id, courseid, coursetitle, credithours, lecturehours, yeartaken) VALUES ('PGST', 'MAS', 0, 2, 'PMKM812', 'Knowledge management: Tools', 2, 2, 8);
INSERT INTO courses(departmentid, degreelevelid, coursetypeid, org_id, courseid, coursetitle, credithours, lecturehours, yeartaken) VALUES ('PGST', 'MAS', 0, 2, 'PMKM852', 'Knowledge Management Systems', 2, 2, 8);
INSERT INTO courses(departmentid, degreelevelid, coursetypeid, org_id, courseid, coursetitle, credithours, lecturehours, yeartaken) VALUES ('PGST', 'MAS', 0, 2, 'PMKM872', 'Intellectual Capital Management', 2, 2, 8);
INSERT INTO courses(departmentid, degreelevelid, coursetypeid, org_id, courseid, coursetitle, credithours, lecturehours, yeartaken) VALUES ('PGST', 'MAS', 0, 2, 'PMKM891', 'Knowledge Management Strategies', 2, 2, 8);

SELECT trim(upper(pg_results.courseid)), trim(pg_results.coursetitle)
FROM pg_results LEFT JOIN courses ON trim(upper(pg_results.courseid)) = trim(upper(courses.courseid))
WHERE courses.courseid is null
GROUP BY trim(upper(pg_results.courseid)), trim(pg_results.coursetitle)
ORDER BY trim(upper(pg_results.courseid));


INSERT INTO qcourses (quarterid, courseid, oldcourseid, coursetitle, instructorid, maxclass, org_id)
SELECT pg_results.quarterid, courses.courseid, courses.courseid, courses.coursetitle, 0, 100, 2
FROM pg_results INNER JOIN courses ON trim(upper(pg_results.courseid)) = trim(upper(courses.courseid))
LEFT JOIN qcourses ON (courses.courseid = qcourses.courseid) AND (pg_results.quarterid = qcourses.quarterid)
WHERE qcourses.qcourseid is null
GROUP BY pg_results.quarterid, courses.courseid, courses.coursetitle
ORDER BY pg_results.quarterid, courses.courseid;


INSERT INTO qstudents (quarterid, studentdegreeid, qresidenceid, org_id)
SELECT pg_results.quarterid, studentdegrees.studentdegreeid, max(qresidences.qresidenceid), 2
FROM pg_results INNER JOIN studentdegrees ON trim(upper(pg_results.studentid)) = trim(upper(studentdegrees.studentid))
	INNER JOIN qresidences ON pg_results.quarterid = qresidences.quarterid
	LEFT JOIN qstudents ON (studentdegrees.studentdegreeid = qstudents.studentdegreeid) AND (pg_results.quarterid = qresidences.quarterid)
WHERE (qresidences.residenceid = 'OC') AND (qstudents.studentdegreeid is null)
GROUP BY pg_results.quarterid, studentdegrees.studentdegreeid
ORDER BY pg_results.quarterid;


SELECT qstudents.qstudentid, qcourses.qcourseid, pg_results.finalmarksid, pg_results.finalmarksid, 
	pg_results.finalmarksid, pg_results.finalmarksid, pg_results.grade, courses.credithours, courses.credithours, 2
	FROM pg_results INNER JOIN studentdegrees ON trim(upper(pg_results.studentid)) = trim(upper(studentdegrees.studentid))
	INNER JOIN qstudents ON (studentdegrees.studentdegreeid = qstudents.studentdegreeid) AND (pg_results.quarterid = qstudents.quarterid)
	INNER JOIN qcourses ON trim(upper(pg_results.courseid)) = trim(upper(qcourses.courseid)) AND (pg_results.quarterid = qcourses.quarterid)
	INNER JOIN courses ON qcourses.courseid = courses.courseid
	LEFT JOIN qgrades ON (qstudents.qstudentid = qgrades.qstudentid) AND (qcourses.qcourseid = qgrades.qcourseid)
WHERE (qgrades.qgradeid is null)


INSERT INTO qgrades (qstudentid, qcourseid, instructormarks, departmentmarks, facultymark, finalmarks, gradeid, hours, credit, org_id)
SELECT qstudents.qstudentid, qcourses.qcourseid, 
	max(pg_results.finalmarksid), max(pg_results.finalmarksid), 
	max(pg_results.finalmarksid), max(pg_results.finalmarksid), 
	max(pg_results.grade), courses.credithours, courses.credithours, 2

	FROM pg_results INNER JOIN studentdegrees ON trim(upper(pg_results.studentid)) = trim(upper(studentdegrees.studentid))
	INNER JOIN qstudents ON (studentdegrees.studentdegreeid = qstudents.studentdegreeid) AND (pg_results.quarterid = qstudents.quarterid)
	INNER JOIN qcourses ON trim(upper(pg_results.courseid)) = trim(upper(qcourses.courseid)) AND (pg_results.quarterid = qcourses.quarterid)
	INNER JOIN courses ON qcourses.courseid = courses.courseid
	LEFT JOIN qgrades ON (qstudents.qstudentid = qgrades.qstudentid) AND (qcourses.qcourseid = qgrades.qcourseid)
WHERE (qgrades.qgradeid is null)
GROUP BY qstudents.qstudentid, qcourses.qcourseid, courses.credithours, courses.credithours;








