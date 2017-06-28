
CREATE OR REPLACE FUNCTION updqcoursefaculty(varchar(12), varchar(12), varchar(12)) RETURNS varchar(240) AS $$
BEGIN
	UPDATE qgrades SET finalmarks = departmentmarks
	WHERE (qgrades.qcourseid = CAST($1 as int));
	
	UPDATE qcourses SET departmentsubmit = true, dsdate = now()
	WHERE (qcourseid = CAST($1 as int));
	
	RETURN 'Marks Submitted to the Faculty Correctly';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION getdbgradeid(integer, integer) RETURNS varchar(2) AS $$
	SELECT CASE WHEN max(aa.gradeid) is null THEN 'NG' ELSE max(aa.gradeid) END
	FROM ((SELECT gradeid, minrange, maxrange, org_id
		FROM grades)
		UNION
		(SELECT gradeid, minrange, maxrange, 2
		FROM grades
		WHERE org_id = 0)) aa
	WHERE (aa.minrange <= $1) AND (aa.maxrange >= $1) AND (aa.org_id = $2);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION updqcoursegrade(varchar(12), varchar(12), varchar(12)) RETURNS varchar(240) AS $$
BEGIN
	UPDATE qgrades SET gradeid = getdbgradeid(round(finalmarks)::integer, qgrades.org_id)
	WHERE (qgrades.qcourseid = CAST($1 as int));
	
	UPDATE qcourses SET facultysubmit = true, fsdate = now()
	WHERE (qcourseid = CAST($1 as int));
	
	RETURN 'Final Grade Submitted to Registry Correctly';
END;
$$ LANGUAGE plpgsql;

ALTER TABLE courses ADD allow_ws			boolean not null default false;
UPDATE courses SET allow_ws = true WHERE courseid = 'GEDS001';

DROP TABLE import_grades;
CREATE TABLE import_grades (
	import_grade_id				serial primary key,
	course_id					varchar(12),
	session_id					varchar(12),
	student_id					varchar(12),
	score						real,
	created						timestamp default current_timestamp
);
	

CREATE OR REPLACE FUNCTION aft_import_grades() RETURNS trigger AS $$
DECLARE
	v_qgradeid				integer;
	v_allow_ws				boolean;
BEGIN

	SELECT allow_ws INTO v_allow_ws
	FROM courses 
	WHERE courseid = NEW.course_id;
	
	IF(v_allow_ws = true)THEN
		SELECT qgradeid INTO v_qgradeid
		FROM studentgradeview
		WHERE (courseid = NEW.course_id) AND (quarterid = NEW.session_id)
			AND (studentid = NEW.student_id);
			
		UPDATE qgrades SET instructormarks = NEW.score WHERE qgradeid = v_qgradeid;
	END IF;

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER aft_import_grades AFTER INSERT OR UPDATE ON import_grades
  FOR EACH ROW EXECUTE PROCEDURE aft_import_grades();


CREATE OR REPLACE FUNCTION get_grade_weight(real, int) RETURNS real AS $$
	SELECT max(aa.gradeweight)::real
	FROM ((SELECT gradeweight, minrange, maxrange, org_id
		FROM grades)
		UNION
		(SELECT gradeweight, minrange, maxrange, 2
		FROM grades
		WHERE org_id = 0)) aa
	WHERE (aa.minrange <= $1) AND (aa.maxrange >= $1) AND (aa.org_id = $2);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_curr_score(int) RETURNS float AS $$
	SELECT (CASE sum(qgrades.credit) WHEN 0 THEN 0 
	ELSE (sum(get_grade_weight(round(finalmarks)::integer, qgrades.org_id) * qgrades.credit) / sum(qgrades.credit)) END)
	FROM qgrades 
	WHERE (qgrades.qstudentid = $1) AND (qgrades.dropped = false) 
		AND (qgrades.repeated = false) AND (qgrades.gradeid <> 'W') AND (qgrades.gradeid <> 'AW');
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getgradeid(real, int) RETURNS varchar(2) AS $$
	SELECT max(aa.gradeid)
	FROM ((SELECT gradeid, minrange, maxrange, org_id
		FROM grades)
		UNION
		(SELECT gradeid, minrange, maxrange, 2
		FROM grades
		WHERE org_id = 0)) aa
	WHERE (aa.minrange <= $1) AND (aa.maxrange >= $1) AND (aa.org_id = $2);
$$ LANGUAGE SQL;

CREATE VIEW vwqcourses AS
	SELECT courseview.schoolid, courseview.schoolname, courseview.departmentid, courseview.departmentname,
		courseview.degreelevelid, courseview.degreelevelname, courseview.coursetypeid, courseview.coursetypename,
		courseview.courseid, courseview.credithours, courseview.maxcredit, courseview.iscurrent,
		courseview.nogpa, courseview.yeartaken, instructors.instructorid, instructors.instructorname,
		qcourses.quarterid, qcourses.qcourseid, qcourses.classoption, qcourses.maxclass,
		qcourses.labcourse, qcourses.extracharge, qcourses.approved, qcourses.attendance, qcourses.oldcourseid,
		qcourses.fullattendance, qcourses.coursetitle, qcourses.lecturesubmit, qcourses.lsdate,
		qcourses.departmentsubmit, qcourses.dsdate, qcourses.facultysubmit, qcourses.fsdate, 
		qcourses.org_id
	FROM (courseview INNER JOIN qcourses ON courseview.courseid = qcourses.courseid)
		INNER JOIN instructors ON qcourses.instructorid = instructors.instructorid;


CREATE TABLE studentpayment_logs (
	studentpayment_log_id	serial primary key,
	studentpaymentid	integer,
	created				timestamp not null default now()
);


CREATE VIEW vw_qresidence AS
	SELECT residences.residenceid, residences.residencename, residences.offcampus, residences.Sex, residences.residencedean, 
		qresidences.qresidenceid, qresidences.quarterid, qresidences.residenceoption, qresidences.charges, qresidences.details,
		qresidences.org_id,
		students.studentid, students.studentname,
		quarters.active,
		resc.res_capacity, resn.resCount, (resc.res_capacity - resn.resCount) as space_left
	FROM ((residences INNER JOIN qresidences ON residences.residenceid = qresidences.residenceid)
	INNER JOIN quarters ON qresidences.quarterid = quarters.quarterid)
	INNER JOIN students ON ((residences.Sex = students.Sex) OR (residences.Sex = 'N'))
	LEFT JOIN (SELECT residenceid, sum(residencecapacitys.capacity) as res_capacity FROM residencecapacitys
			GROUP BY residenceid) as resc
		ON residences.residenceid = resc.residenceid
	LEFT JOIN (SELECT qresidenceid, count(qstudentid) as resCount FROM qstudents
			GROUP BY qresidenceid) as resn
		ON qresidences.qresidenceid = resn.qresidenceid;
		

CREATE OR REPLACE FUNCTION selQResidence(varchar(12), varchar(12), varchar(12)) RETURNS VARCHAR(120) AS $$
DECLARE
	myrec 				RECORD;
	resrec				RECORD;
	myqstud 			int;
	myres				int;
	resCapacity			int;
	resCount			int;
	v_qstudentid		int;
	allowMajors			boolean;
	mystr 				varchar(120);
BEGIN
	myqstud := getqstudentid($2);
	myres := $1::integer;

	SELECT qstudentid, quarterid, finalised, financeclosed, finaceapproval, mealtype, mealticket, studylevel INTO myrec
	FROM qstudents WHERE (qstudentid = myqstud);
	
	SELECT sex, min_level, max_level, majors INTO resrec
	FROM residences INNER JOIN qresidences ON residences.residenceid = qresidences.residenceid
	WHERE (qresidenceid = myres);	
	
	SELECT sum(residencecapacitys.capacity) INTO resCapacity
	FROM residencecapacitys INNER JOIN qresidences ON residencecapacitys.residenceid = qresidences.residenceid
	WHERE (qresidenceid = myres);
	
	UPDATE qstudents SET qresidenceid = null, financeclosed = false
	FROM vwqstudentbalances 
	WHERE (qstudents.finaceapproval = false) AND (age(qstudents.residence_time) > '1 day'::interval) AND (qstudents.offcampus = false)
		AND (qstudents.qresidenceid is not null) AND (qstudents.quarterid = myrec.quarterid)
		AND (qstudents.qstudentid = vwqstudentbalances.qstudentid) AND (vwqstudentbalances.finalbalance < 10000)
		AND (vwqstudentbalances.finaceapproval = false) AND (vwqstudentbalances.quarterid = myrec.quarterid);
	
	SELECT count(qstudentid) INTO resCount
	FROM qstudents
	WHERE (qresidenceid = myres);
	
	allowMajors := true;
	IF(resrec.majors is not null)THEN
		SELECT qstudents.qstudentid INTO v_qstudentid
		FROM qstudents INNER JOIN qresidences ON qstudents.qresidenceid = qresidences.qresidenceid
			INNER JOIN residences ON qresidences.residenceid = residences.residenceid
			INNER JOIN studentdegrees ON qstudents.studentdegreeid = studentdegrees.studentdegreeid
			INNER JOIN studentmajors ON studentdegrees.studentdegreeid = studentmajors.studentdegreeid
		WHERE (qstudents.qstudentid = myqstud) AND (residences.majors ILIKE '%' || studentmajors.majorid || '%');
		IF(v_qstudentid is not null)THEN
			allowMajors := false;
		END IF;
	END IF;

	IF (myrec.qstudentid is null) THEN
		RAISE EXCEPTION 'Register for the semester first';
	ELSIF (myrec.financeclosed = true) OR (myrec.finaceapproval = true) THEN
		RAISE EXCEPTION 'You cannot make changes after submiting your payment unless you apply on the post for it to be opened by finance.';
	ELSIF (myrec.finalised = true) THEN
		RAISE EXCEPTION 'You have closed the selection.';
	ELSIF (myrec.studylevel < resrec.min_level) OR (myrec.studylevel > resrec.max_level) THEN
		RAISE EXCEPTION 'The study levels allowed are between % and % for your level %', resrec.min_level, resrec.max_level, myrec.studylevel;
	ELSIF (resCount > resCapacity) THEN
		RAISE EXCEPTION 'The residence you have selected is full.';
	ELSIF(allowMajors = false)THEN
		RAISE EXCEPTION 'The hall selected is not for the course you are doing';
	ELSE
		UPDATE qstudents SET qresidenceid = myres, roomnumber = null, residence_time = now() WHERE (qstudentid = myqstud);
		mystr := 'Residence registered. You need to pay fees and get finacial approval today or you will loose the residence selection.';
	END IF;

    RETURN mystr;
END;
$$ LANGUAGE plpgsql;


CREATE VIEW ws_hall_service AS
	SELECT studentid, studentname, mealtype, studylevel, majorid, majorname, finaceapproval,
		quarterid, schoolid, schoolname, departmentid, departmentname, residenceid, residencename
	FROM vwqstudentbalances
	WHERE (active = true);