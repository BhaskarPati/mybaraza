
CREATE OR REPLACE FUNCTION getcoremajor(integer) RETURNS varchar(75) AS $$
    SELECT max(majors.majorname)
    FROM studentmajors INNER JOIN majors ON studentmajors.majorid = majors.majorid
    WHERE (studentmajors.studentdegreeid = $1) AND (studentmajors.primarymajor = true);
$$ LANGUAGE sql;

DROP VIEW vw_studentdegrees;

CREATE VIEW vw_studentdegrees AS
	SELECT studentview.religionid, studentview.religionname, studentview.denominationid, studentview.denominationname,
		studentview.schoolid, studentview.schoolname, studentview.studentid, studentview.studentname, studentview.address, studentview.zipcode,
		studentview.town, studentview.addresscountry, studentview.telno, studentview.email,  studentview.guardianname, studentview.gaddress,
		studentview.gzipcode, studentview.gtown, studentview.gaddresscountry, studentview.gtelno, studentview.gemail,
		studentview.accountnumber, studentview.Nationality, studentview.Nationalitycountry, studentview.Sex,
		studentview.MaritalStatus, studentview.birthdate, studentview.firstpass, studentview.alumnae, studentview.postcontacts,
		studentview.onprobation, studentview.offcampus, studentview.currentcontact, studentview.currentemail, studentview.currenttel,
		studentview.org_id,
		sublevelview.degreelevelid, sublevelview.degreelevelname,
		sublevelview.freshman, sublevelview.sophomore, sublevelview.junior, sublevelview.senior,
		sublevelview.levellocationid, sublevelview.levellocationname,
		sublevelview.sublevelid, sublevelview.sublevelname, sublevelview.specialcharges,
		degrees.degreeid, degrees.degreename,
		studentdegrees.studentdegreeid, studentdegrees.completed, studentdegrees.started, studentdegrees.cleared, studentdegrees.clearedate,
		studentdegrees.graduated, studentdegrees.graduatedate, studentdegrees.dropout, studentdegrees.transferin, studentdegrees.transferout,
		
		studentdegrees.grad_apply, studentdegrees.grad_apply_date, studentdegrees.grad_finance, studentdegrees.grad_finance_date,
		studentdegrees.grad_accept, studentdegrees.grad_accept_date,
		
		studentdegrees.mathplacement, studentdegrees.englishplacement, studentdegrees.details,
		
		to_char(grad_accept_date, 'Mon YYYY') as grad_accept_month,
		to_char(grad_accept_date, 'YYYY') as grad_accept_year,
		
		getcoremajor(studentdegrees.studentdegreeid) as core_major,
		getcummcredit(studentdegrees.studentdegreeid) as cumm_credits,
		getcummgpa(studentdegrees.studentdegreeid) as cumm_gpa
	FROM ((studentview INNER JOIN studentdegrees ON studentview.studentid = studentdegrees.studentid)
		INNER JOIN sublevelview ON studentdegrees.sublevelid = sublevelview.sublevelid)
		INNER JOIN degrees ON studentdegrees.degreeid = degrees.degreeid;
		
		
CREATE VIEW vw_apply_grad_year AS
	SELECT grad_accept_year as apply_grad_year
	FROM vw_studentdegrees
	WHERE (graduated = true)
	GROUP BY grad_accept_year
	ORDER BY grad_accept_year;

ALTER TABLE majorcontents 
ADD	content_level		integer;

ALTER TABLE majoroptcontents
ADD	content_level		integer;


DROP VIEW majorgradeview;
DROP VIEW coregradeview;
DROP VIEW qcoursecheckpass;
DROP VIEW studentchecklist;
DROP VIEW coursechecklist;
DROP VIEW corecourseoutline;
DROP VIEW courseoutline;
DROP VIEW vw_major_prereq;
DROP VIEW majorcontentview;
DROP VIEW majoroptcontentview;

CREATE VIEW majorcontentview AS
	SELECT majorview.schoolid, majorview.departmentid, majorview.departmentname, majorview.majorid, majorview.majorname, 
		majorview.electivecredit, courses.courseid, courses.coursetitle, courses.credithours, courses.nogpa, 
		courses.yeartaken, courses.details as course_details,
		contenttypes.contenttypeid, contenttypes.contenttypename, contenttypes.elective, contenttypes.prerequisite,
		contenttypes.premajor, majorcontents.majorcontentid, majorcontents.minor, majorcontents.gradeid, 
		majorcontents.content_level, majorcontents.narrative,
		bulleting.bulletingid, bulleting.bulletingname, bulleting.startingquarter, bulleting.endingquarter,
		bulleting.iscurrent
	FROM (((majorview INNER JOIN majorcontents ON majorview.majorid = majorcontents.majorid)
		INNER JOIN courses ON majorcontents.courseid = courses.courseid)
		INNER JOIN contenttypes ON majorcontents.contenttypeid = contenttypes.contenttypeid)
		INNER JOIN bulleting ON majorcontents.bulletingid = bulleting.bulletingid;
		
CREATE VIEW majoroptcontentview AS
	SELECT majoroptions.majoroptionid, majoroptions.majorid, majoroptions.majoroptionname,
		courses.courseid, courses.coursetitle, courses.credithours, courses.nogpa, 
		courses.yeartaken, courses.details as course_details,
		contenttypes.contenttypeid, contenttypes.contenttypename, contenttypes.elective, contenttypes.prerequisite, contenttypes.premajor,
		majoroptcontents.majoroptcontentid, majoroptcontents.minor, majoroptcontents.gradeid, 
		majoroptcontents.content_level, majoroptcontents.narrative,
		bulleting.bulletingid, bulleting.bulletingname, bulleting.startingquarter, bulleting.endingquarter,
		bulleting.iscurrent
	FROM (((majoroptions INNER JOIN majoroptcontents ON majoroptions.majoroptionid = majoroptcontents.majoroptionid)
		INNER JOIN courses ON majoroptcontents.courseid = courses.courseid)
		INNER JOIN contenttypes ON majoroptcontents.contenttypeid = contenttypes.contenttypeid)
		INNER JOIN bulleting ON majoroptcontents.bulletingid = bulleting.bulletingid;

CREATE VIEW vw_major_prereq AS
	SELECT majorcontentview.schoolid, majorcontentview.departmentid, majorcontentview.departmentname, 
		majorcontentview.majorid, majorcontentview.majorname, majorcontentview.electivecredit, 
		majorcontentview.courseid as precourseid, majorcontentview.coursetitle as precoursetitle,
		majorcontentview.contenttypeid, majorcontentview.contenttypename, majorcontentview.elective, majorcontentview.prerequisite,
		majorcontentview.premajor, majorcontentview.majorcontentid, majorcontentview.minor, 
		majorcontentview.iscurrent,
		prereqview.courseid, prereqview.coursetitle, prereqview.prerequisiteid,  
		prereqview.optionlevel, prereqview.narrative, prereqview.gradeid, prereqview.gradeweight,
		prereqview.bulletingid, prereqview.bulletingname, prereqview.startingquarter, prereqview.endingquarter		
	FROM majorcontentview INNER JOIN prereqview ON majorcontentview.courseid = prereqview.precourseid
	ORDER BY prereqview.courseid, prereqview.optionlevel;
	
CREATE VIEW courseoutline (
	orderid,
	studentid,
	studentdegreeid,
	degreeid,
	degreelevelid,
	description,
	courseid,
	coursetitle,
	minor,
	elective,
	credithours,
	nogpa,
	gradeid,
	content_level,
	gradeweight,
	courseweight,
	prereqpassed
	
) AS
	SELECT 1, vw_ol_students.studentid, vw_ol_students.studentdegreeid, vw_ol_students.degreeid, vw_ol_students.degreelevelid,
		majors.majorname, majorcontentview.courseid,
		majorcontentview.coursetitle, majorcontentview.minor, majorcontentview.elective, majorcontentview.credithours,
		majorcontentview.nogpa, majorcontentview.gradeid, majorcontentview.content_level, grades.gradeweight,
		getcoursedone(vw_ol_students.studentid, majorcontentview.courseid),
		getprereqpassed(vw_ol_students.studentid, majorcontentview.courseid, vw_ol_students.studentdegreeid)
	FROM ((majors INNER JOIN majorcontentview ON majors.majorid = majorcontentview.majorid)
		INNER JOIN vw_ol_students ON (majorcontentview.majorid = vw_ol_students.majorid) AND (majorcontentview.bulletingid = vw_ol_students.bulletingid))
		INNER JOIN grades ON majorcontentview.gradeid = grades.gradeid
	WHERE ((not vw_ol_students.premajor and majorcontentview.premajor)=false) 
		AND ((not vw_ol_students.nondegree and majorcontentview.prerequisite)=false);

CREATE VIEW corecourseoutline AS 
	SELECT 1 AS orderid, studentdegrees.studentid, studentdegrees.studentdegreeid, studentdegrees.degreeid, 
		majors.majorname AS description, majorcontentview.contenttypeid, majorcontentview.contenttypename,
		majorcontentview.courseid, majorcontentview.coursetitle, majorcontentview.minor, 
		majorcontentview.elective, majorcontentview.credithours, majorcontentview.nogpa, majorcontentview.gradeid, 
		majorcontentview.content_level, grades.gradeweight
	FROM majors
		INNER JOIN majorcontentview ON majors.majorid = majorcontentview.majorid
		INNER JOIN studentmajors ON majorcontentview.majorid = studentmajors.majorid
		INNER JOIN studentdegrees ON (studentmajors.studentdegreeid = studentdegrees.studentdegreeid) AND (majorcontentview.bulletingid = studentdegrees.bulletingid)
		INNER JOIN grades ON majorcontentview.gradeid = grades.gradeid
		WHERE (studentmajors.major = true) AND ((NOT studentmajors.premajor AND majorcontentview.premajor) = false) 
			AND ((NOT studentmajors.nondegree AND majorcontentview.prerequisite) = false) AND (studentdegrees.dropout = false);

CREATE OR REPLACE FUNCTION get_passed(double precision, double precision, integer, varchar(12), varchar(12)) RETURNS boolean AS $$
DECLARE
	passed 			boolean;
	v_courseid		varchar(12);
BEGIN
	passed := false;
	
	IF($1 >= $2) THEN
		passed := true;
	ELSIF($3 is not null)THEN
		SELECT max(courseid) INTO v_courseid
		FROM courseoutline
		WHERE (content_level ) AND (studentid = $4) AND (majorid = $5)
			AND (courseweight >= gradeweight);
		IF(v_courseid is not null)THEN passed := true; END IF;
	END IF;

    RETURN passed;
END;
$$ LANGUAGE plpgsql;

			
CREATE VIEW coursechecklist AS
	SELECT DISTINCT courseoutline.orderid, courseoutline.studentid, courseoutline.studentdegreeid, courseoutline.degreeid, 
		courseoutline.degreelevelid, courseoutline.description, courseoutline.courseid,
		courseoutline.coursetitle, courseoutline.minor, courseoutline.elective, courseoutline.credithours, courseoutline.nogpa, courseoutline.gradeid,
		courseoutline.content_level, courseoutline.gradeweight, courseoutline.courseweight, courseoutline.prereqpassed,
		
		get_passed(courseoutline.courseweight, courseoutline.gradeweight, courseoutline.content_level, courseoutline.studentid, courseoutline.courseid) as coursepased
		
	FROM courseoutline;

CREATE VIEW studentchecklist AS
	SELECT coursechecklist.orderid, coursechecklist.studentid, coursechecklist.studentdegreeid, coursechecklist.degreeid, 
		coursechecklist.degreelevelid, coursechecklist.description, coursechecklist.courseid,
		coursechecklist.coursetitle, coursechecklist.minor, coursechecklist.elective, coursechecklist.credithours, coursechecklist.nogpa, coursechecklist.gradeid,
		coursechecklist.courseweight, coursechecklist.coursepased, coursechecklist.prereqpassed,
		students.studentname
	FROM coursechecklist INNER JOIN students ON coursechecklist.studentid = students.studentid;

CREATE VIEW qcoursecheckpass AS
	SELECT coursechecklist.orderid, coursechecklist.studentid, coursechecklist.studentdegreeid, coursechecklist.degreeid, coursechecklist.description,
		coursechecklist.minor, coursechecklist.elective, coursechecklist.gradeid,
		coursechecklist.gradeweight, coursechecklist.courseweight, coursechecklist.coursepased, coursechecklist.prereqpassed,
		qcourseview.org_id, qcourseview.schoolid, qcourseview.schoolname, qcourseview.departmentid, qcourseview.departmentname,
		qcourseview.degreelevelid, qcourseview.degreelevelname, qcourseview.coursetypeid, qcourseview.coursetypename,
		qcourseview.courseid, qcourseview.credithours, qcourseview.maxcredit, qcourseview.iscurrent,
		qcourseview.nogpa, qcourseview.yeartaken, qcourseview.mathplacement, qcourseview.englishplacement,
		qcourseview.instructorid, qcourseview.quarterid, qcourseview.qcourseid, qcourseview.classoption, qcourseview.maxclass,
		qcourseview.labcourse, qcourseview.extracharge, qcourseview.approved, qcourseview.attendance, qcourseview.oldcourseid,
		qcourseview.fullattendance, qcourseview.instructorname, qcourseview.coursetitle,
		qcourseview.levellocationid, qcourseview.levellocationname
	FROM coursechecklist INNER JOIN qcourseview ON (coursechecklist.courseid = qcourseview.courseid) AND (coursechecklist.degreelevelid = qcourseview.degreelevelid)
	WHERE (qcourseview.active = true) AND (qcourseview.approved = false) 
		AND (coursechecklist.coursepased = false) AND (coursechecklist.prereqpassed = true);

CREATE VIEW coregradeview AS 
	SELECT studentgradeview.schoolid, studentgradeview.schoolname, studentgradeview.studentid, studentgradeview.studentname, studentgradeview.sex,
		studentgradeview.degreeid, studentgradeview.degreename, studentgradeview.studentdegreeid, studentgradeview.quarterid, studentgradeview.quarteryear,
		studentgradeview.quarter, studentgradeview.coursetypeid, studentgradeview.coursetypename, studentgradeview.courseid, studentgradeview.nogpa,
		studentgradeview.instructorid, studentgradeview.qcourseid, studentgradeview.classoption, studentgradeview.labcourse, studentgradeview.instructorname,
		studentgradeview.coursetitle, studentgradeview.qgradeid, studentgradeview.hours, studentgradeview.credit, studentgradeview.gpa, studentgradeview.gradeid,
		studentgradeview.repeated, studentgradeview.gpahours, studentgradeview.chargehours, 
		corecourseoutline.description, corecourseoutline.minor, corecourseoutline.elective,
		corecourseoutline.contenttypeid, corecourseoutline.contenttypename
	FROM corecourseoutline INNER JOIN studentgradeview ON (corecourseoutline.studentdegreeid = studentgradeview.studentdegreeid) AND (corecourseoutline.courseid = studentgradeview.courseid)
	WHERE (studentgradeview.approved = true) AND (corecourseoutline.minor = false);

CREATE VIEW majorgradeview AS
	SELECT studentdegreeview.studentid, studentdegreeview.studentname, studentdegreeview.sex, studentdegreeview.degreelevelid, studentdegreeview.degreelevelname, 
		studentdegreeview.levellocationid, studentdegreeview.levellocationname, studentdegreeview.sublevelid, studentdegreeview.sublevelname, 
		studentdegreeview.degreeid, studentdegreeview.degreename, studentdegreeview.studentdegreeid, 
		studentmajors.studentmajorid, studentmajors.major, studentmajors.nondegree, studentmajors.premajor, 
		majorcontentview.departmentid, majorcontentview.departmentname, majorcontentview.majorid, majorcontentview.majorname, 
		majorcontentview.courseid, majorcontentview.coursetitle, majorcontentview.contenttypeid, majorcontentview.contenttypename,
		majorcontentview.elective, majorcontentview.prerequisite, majorcontentview.majorcontentid,
		majorcontentview.premajor as premajoritem, majorcontentview.minor, majorcontentview.gradeid as mingrade,
		qgradeview.quarterid, qgradeview.qgradeid, qgradeview.qstudentid, qgradeview.gradeid, qgradeview.gpahours, qgradeview.gpa,
		qgradeview.instructorname
	FROM (((studentdegreeview INNER JOIN studentmajors ON studentdegreeview.studentdegreeid = studentmajors.studentdegreeid)
		INNER JOIN majorcontentview ON majorcontentview.majorid = studentmajors.majorid)
		INNER JOIN qstudents ON qstudents.studentdegreeid = studentdegreeview.studentdegreeid)
		INNER JOIN qgradeview ON (qgradeview.courseid = majorcontentview.courseid) and (qgradeview.qstudentid =   qstudents.qstudentid)
	WHERE ((not studentmajors.premajor and majorcontentview.premajor)=false) AND ((not studentmajors.nondegree and majorcontentview.prerequisite)=false);
	
	
DROP VIEW fullsummary;
DROP VIEW schoolmajorsummary;
DROP VIEW qstudentmajorsummary;
DROP VIEW qstudentmajorview;
DROP VIEW vw_apply_grad_year;
DROP VIEW vw_studentdegrees;

CREATE VIEW vw_studentdegrees AS
	SELECT studentview.religionid, studentview.religionname, studentview.denominationid, studentview.denominationname,
		studentview.schoolid, studentview.schoolname, studentview.studentid, studentview.studentname, studentview.address, studentview.zipcode,
		studentview.town, studentview.addresscountry, studentview.telno, studentview.email,  studentview.guardianname, studentview.gaddress,
		studentview.gzipcode, studentview.gtown, studentview.gaddresscountry, studentview.gtelno, studentview.gemail,
		studentview.accountnumber, studentview.Nationality, studentview.Nationalitycountry, studentview.Sex,
		studentview.MaritalStatus, studentview.birthdate, studentview.firstpass, studentview.alumnae, studentview.postcontacts,
		studentview.onprobation, studentview.offcampus, studentview.currentcontact, studentview.currentemail, studentview.currenttel,
		studentview.org_id,
		sublevelview.degreelevelid, sublevelview.degreelevelname,
		sublevelview.freshman, sublevelview.sophomore, sublevelview.junior, sublevelview.senior,
		sublevelview.levellocationid, sublevelview.levellocationname,
		sublevelview.sublevelid, sublevelview.sublevelname, sublevelview.specialcharges,
		degrees.degreeid, degrees.degreename,
		studentdegrees.studentdegreeid, studentdegrees.completed, studentdegrees.started, studentdegrees.cleared, studentdegrees.clearedate,
		studentdegrees.graduated, studentdegrees.graduatedate, studentdegrees.dropout, studentdegrees.transferin, studentdegrees.transferout,
		
		studentdegrees.grad_apply, studentdegrees.grad_apply_date, studentdegrees.grad_finance, studentdegrees.grad_finance_date,
		studentdegrees.grad_accept, studentdegrees.grad_accept_date,
		
		studentdegrees.mathplacement, studentdegrees.englishplacement, studentdegrees.details,
		
		to_char(grad_apply_date, 'Mon YYYY') as grad_apply_month,
		to_char(grad_accept_date, 'Mon YYYY') as grad_accept_month,
		to_char(grad_accept_date, 'YYYY') as grad_accept_year,
		
		getcoremajor(studentdegrees.studentdegreeid) as core_major,
		getcummcredit(studentdegrees.studentdegreeid) as cumm_credits,
		getcummgpa(studentdegrees.studentdegreeid) as cumm_gpa
	FROM ((studentview INNER JOIN studentdegrees ON studentview.studentid = studentdegrees.studentid)
		INNER JOIN sublevelview ON studentdegrees.sublevelid = sublevelview.sublevelid)
		INNER JOIN degrees ON studentdegrees.degreeid = degrees.degreeid;
		
CREATE VIEW vw_apply_grad_year AS
	SELECT grad_accept_year as apply_grad_year
	FROM vw_studentdegrees
	WHERE (graduated = true)
	GROUP BY grad_accept_year
	ORDER BY grad_accept_year;
	
	
	
CREATE VIEW qstudentmajorview AS 
	SELECT studentmajorview.religionid, studentmajorview.religionname, studentmajorview.denominationid, studentmajorview.denominationname,
		studentmajorview.schoolid as studentschoolid, studentmajorview.schoolname as studentschoolname, studentmajorview.studentid,
		studentmajorview.studentname, studentmajorview.Nationality, studentmajorview.Nationalitycountry, studentmajorview.Sex,
		studentmajorview.MaritalStatus, studentmajorview.birthdate, 
		studentmajorview.degreelevelid, studentmajorview.degreelevelname,
		studentmajorview.freshman, studentmajorview.sophomore, studentmajorview.junior, studentmajorview.senior,
		studentmajorview.levellocationid, studentmajorview.levellocationname,
		studentmajorview.sublevelid, studentmajorview.sublevelname, studentmajorview.specialcharges,
		studentmajorview.degreeid, studentmajorview.degreename,
		studentmajorview.studentdegreeid, studentmajorview.completed, studentmajorview.started, studentmajorview.cleared, studentmajorview.clearedate,
		studentmajorview.graduated, studentmajorview.graduatedate, studentmajorview.dropout, studentmajorview.transferin, studentmajorview.transferout,
		studentmajorview.mathplacement, studentmajorview.englishplacement,
		studentmajorview.schoolid, studentmajorview.schoolname, studentmajorview.departmentid, studentmajorview.departmentname,
		studentmajorview.majorid, studentmajorview.majorname, studentmajorview.electivecredit, studentmajorview.domajor, studentmajorview.dominor,
		studentmajorview.majoroptionid, studentmajorview.majoroptionname, studentmajorview.primarymajor,
		studentmajorview.studentmajorid, studentmajorview.major, studentmajorview.nondegree, studentmajorview.premajor,
		qstudents.org_id, qstudents.qstudentid, qstudents.quarterid, qstudents.charges as additionalcharges, 
		qstudents.approved, qstudents.probation,
		qstudents.roomnumber, qstudents.currbalance, qstudents.finaceapproval, qstudents.majorapproval,
		qstudents.departapproval, qstudents.overloadapproval, qstudents.finalised, qstudents.printed,
		qstudents.noapproval, qstudents.exam_clear, qstudents.exam_clear_date, qstudents.exam_clear_balance,
		qstudents.qresidenceid,
		quarters.active, quarters.closed,
		substring(quarters.quarterid from 1 for 9)  as quarteryear, 
		trim(substring(quarters.quarterid from 11 for 2)) as quarter
	FROM (studentmajorview INNER JOIN qstudents ON studentmajorview.studentdegreeid = qstudents.studentdegreeid)
		INNER JOIN quarters ON qstudents.quarterid = quarters.quarterid;

CREATE VIEW qstudentmajorsummary AS
	SELECT qstudentmajorview.schoolid, qstudentmajorview.schoolname, qstudentmajorview.departmentid, qstudentmajorview.departmentname,
		qstudentmajorview.degreelevelid, qstudentmajorview.degreelevelname, qstudentmajorview.sublevelid, qstudentmajorview.sublevelname,
		qstudentmajorview.majorid, qstudentmajorview.majorname, qstudentmajorview.premajor, qstudentmajorview.major,qstudentmajorview.probation,
		qstudentmajorview.studentdegreeid, qstudentmajorview.primarymajor,
		qstudentmajorview.sex, qstudentmajorview.quarterid, count(qstudentmajorview.studentdegreeid) as studentcount
	FROM qstudentmajorview
	GROUP BY qstudentmajorview.schoolid, qstudentmajorview.schoolname, qstudentmajorview.departmentid, qstudentmajorview.departmentname,
		qstudentmajorview.degreelevelid, qstudentmajorview.degreelevelname, qstudentmajorview.sublevelid, qstudentmajorview.sublevelname,
		qstudentmajorview.majorid, qstudentmajorview.majorname, qstudentmajorview.premajor, qstudentmajorview.major,
		qstudentmajorview.studentdegreeid, qstudentmajorview.primarymajor,qstudentmajorview.probation,
		qstudentmajorview.sex, qstudentmajorview.quarterid;

		
CREATE VIEW schoolmajorsummary AS
	SELECT qstudentmajorview.quarterid, substring(quarterid from 1 for 9) as quarteryear, 
		substring(quarterid from 11 for 2) as quarter, majorview.schoolname, qstudentmajorview.sex, 
		varchar 'School' as "defination", count(qstudentid) as studentcount
	FROM qstudentmajorview
	INNER JOIN majorview ON majorview.majorid = qstudentmajorview.majorid
	GROUP BY qstudentmajorview.quarterid, substring(quarterid from 1 for 9), substring(quarterid from 11 for 2),majorview.schoolname,qstudentmajorview.sex
	ORDER BY qstudentmajorview.quarterid, substring(quarterid from 1 for 9), substring(quarterid from 11 for 2),majorview.schoolname,qstudentmajorview.sex;


CREATE VIEW fullsummary AS
	(SELECT * FROM schoolmajorsummary) UNION
	(SELECT * FROM levelsummary) UNION
	(SELECT * FROM sublevelsummary) UNION
	(SELECT * FROM newstudentssummary) UNION
	(SELECT * FROM religionsummary) UNION
	(SELECT * FROM denominationsummary) UNION
	(SELECT * FROM nationalitysummary) UNION
	(SELECT * FROM residencesummary) UNION
	(SELECT * FROM locationsummary);
		

		