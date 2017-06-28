

INSERT INTO courses(departmentid,  degreelevelid,  coursetypeid,  org_id,  courseid, coursetitle,    credithours,  lecturehours,  yeartaken)
SELECT 'PGST', pg_courses.degreelevelid, 0, 2, upper(trim(pg_courses.courseid)), 
	pg_courses.coursetitle, pg_courses.credithours, pg_courses.credithours, cast(substring(pg_courses.courseid from 5 for 1) as int)
FROM pg_courses LEFT JOIN courses ON upper(trim(pg_courses.courseid)) = upper(trim(courses.courseid))
WHERE courses.courseid is null;


DELETE FROM pg_result
WHERE (result_id IN (SELECT pg_result.result_id
FROM pg_result LEFT JOIN pg_students ON trim(upper(pg_result.matric_number)) = trim(upper(pg_students.matric_number))
WHERE pg_students.matric_number is null));

DELETE FROM pg_result
WHERE (result_id IN (SELECT pg_result.result_id
FROM pg_result LEFT JOIN courses ON trim(upper(pg_result.subject_id)) = trim(upper(courses.courseid))
WHERE courses.courseid is null));

DELETE FROM pg_students
WHERE (student_id IN (SELECT pg_students.student_id
FROM pg_students LEFT JOIN pg_result ON trim(upper(pg_students.matric_number)) = trim(upper(pg_result.matric_number))
WHERE (pg_result.matric_number is null)));

INSERT INTO majors (majorid, departmentid, org_id, majorname, major_title, electivecredit, minorelectivecredit, major, minor, is_active)
SELECT pg_major_code, 'PGST', 2, pg_major_name, pg_major_name, 8, 8, true, false, true
FROM pg_majors
WHERE (pg_major_code NOT IN (SELECT majorid FROM majors));

UPDATE pg_students SET matric_number = trim(upper(matric_number));

UPDATE pg_students SET new_matric = matric_number
WHERE (length(matric_number) = 10);

UPDATE pg_students SET new_matric = 'PG/' || matric_number
WHERE (length(matric_number) = 7) and (matric_number not like 'P%');

UPDATE pg_students SET new_matric = 'PG/' || substring(year from 3 for 2) || '/' || matric_number
WHERE (length(matric_number) = 4) and (matric_number not like 'P%');

DELETE FROM pg_students WHERE (new_matric is null);

DELETE FROM pg_result
WHERE (result_id IN (SELECT pg_result.result_id
FROM pg_result LEFT JOIN pg_students ON trim(upper(pg_result.matric_number)) = trim(upper(pg_students.matric_number))
WHERE pg_students.matric_number is null));

UPDATE pg_students SET new_matric = 'PG/10/1245' WHERE student_id = 230;
UPDATE pg_students SET new_matric = 'PG/10/1462' WHERE student_id = 249;
UPDATE pg_students SET new_matric = 'PG/10/1294' WHERE student_id = 267;
UPDATE pg_students SET new_matric = 'PG/10/1210' WHERE student_id = 63;

INSERT INTO students (departmentid, denominationid, org_id, Sex, MaritalStatus, Nationality, countrycodeid, gcountrycodeid, stateid,
	studentid, surname, firstname, othernames)
SELECT 'PGST', 'CHRI', 2, 'M', 'S', 'NG', 'NG', 'NG', 39,
	pg_students.new_matric, trim(pg_students.surname), trim(pg_students.firstname), trim(pg_students.middlename)
FROM pg_students
WHERE (pg_students.new_matric NOT IN (SELECT studentid FROM students));

--- next update changes

UPDATE pg_students SET degree = 'MPhi/PhD' WHERE degree = 'MPhi/PhD';
UPDATE pg_students SET degree = 'PHD' WHERE degree = 'PhD';
UPDATE pg_students SET degree = 'MSC' WHERE degree = 'M.SC.';
UPDATE pg_students SET degree = 'MSC' WHERE degree = 'M.A.';
UPDATE pg_students SET degree = 'MBA' WHERE degree = 'MBA';
UPDATE pg_students SET degree = 'MSC' WHERE degree = 'MPM';
UPDATE pg_students SET degree = 'MSC' WHERE degree = 'MPH';
UPDATE pg_students SET degree = 'MSC' WHERE degree = 'MIRM';
UPDATE pg_students SET degree = 'PGD' WHERE degree = 'PGD';
UPDATE pg_students SET degree = 'MPHIL' WHERE degree = 'MPhi';

INSERT INTO studentdegrees (degreeid, studentid, sublevelid, bulletingid, org_id)
SELECT degree, new_matric, 'MAST', 0, 2
FROM pg_students 
WHERE (new_matric NOT IN (SELECT studentdegrees.studentid FROM studentdegrees));

INSERT INTO studentmajors (studentdegreeid, majorid, org_id)
SELECT studentdegrees.studentdegreeid, pg_majors.pg_major_code, 2
FROM pg_students INNER JOIN studentdegrees ON pg_students.new_matric = studentdegrees.studentid
INNER JOIN pg_majors ON pg_students.course_id = pg_majors.pg_major_id
LEFT JOIN studentmajors ON studentdegrees.studentdegreeid = studentmajors.studentdegreeid
WHERE studentmajors.studentdegreeid is null;

INSERT INTO quarters (org_id, quarterid, qstart, qlastdrop, qend)
SELECT 2, year || '.P', CAST(substring(year from 1 for 4) || '-07-01' as date), 
	CAST(substring(year from 1 for 4) || '-07-01' as date),
	CAST(substring(year from 6 for 4) || '-06-01' as date)
FROM pg_students
GROUP BY year;

INSERT INTO qresidences (quarterid, residenceid, org_id, residenceoption, charges, full_charges)
SELECT year || '.P', 'OC', 2, 'Off Campus', 0, 0
FROM pg_students
GROUP BY year;

INSERT INTO qcharges (quarterid, degreelevelid, studylevel, org_id)
SELECT year || '.P', degreelevelid, 700, 2
FROM pg_students INNER JOIN degrees ON pg_students.degree = degrees.degreeid
GROUP BY year, degreelevelid;

INSERT INTO qstudents (quarterid, studentdegreeid, qresidenceid, org_id)
SELECT pg_students.year || '.P', studentdegrees.studentdegreeid, max(qresidences.qresidenceid), 2
FROM pg_students INNER JOIN studentdegrees ON pg_students.new_matric = studentdegrees.studentid
	INNER JOIN qresidences ON pg_students.year || '.P' = qresidences.quarterid
WHERE (qresidences.residenceid = 'OC')
GROUP BY pg_students.year, studentdegrees.studentdegreeid
ORDER BY pg_students.year;

INSERT INTO qcourses (quarterid, courseid, oldcourseid, coursetitle, instructorid, maxclass, org_id)
SELECT pg_students.year || '.P', courses.courseid, courses.courseid, courses.coursetitle, 0, 100, 2
FROM pg_result INNER JOIN pg_students ON trim(upper(pg_result.matric_number)) = trim(upper(pg_students.matric_number))
	INNER JOIN courses ON trim(upper(pg_result.subject_id)) = trim(upper(courses.courseid))
GROUP BY pg_students.year, courses.courseid, courses.coursetitle
ORDER BY pg_students.year, courses.courseid;

INSERT INTO qgrades (qstudentid, qcourseid, instructormarks, departmentmarks, facultymark, finalmarks, gradeid, hours, credit, org_id)
SELECT DISTINCT qstudents.qstudentid, qcourses.qcourseid, 
	max(pg_results.finalmarksid), max(pg_results.finalmarksid), 
	max(pg_results.finalmarksid), max(pg_results.finalmarksid), 
	max(pg_results.grade), courses.credithours, courses.credithours, 2
FROM pg_results INNER JOIN studentdegrees ON pg_results.studentid = studentdegrees.studentid
	INNER JOIN qstudents ON (studentdegrees.studentdegreeid = qstudents.studentdegreeid) AND (pg_results.quarterid = qstudents.quarterid)
	INNER JOIN qcourses ON trim(upper(pg_results.courseid)) = trim(upper(qcourses.courseid)) AND (pg_results.quarterid = qcourses.quarterid)
	INNER JOIN courses ON qcourses.courseid = courses.courseid
GROUP BY qstudents.qstudentid, qcourses.qcourseid, courses.credithours;

	



	


