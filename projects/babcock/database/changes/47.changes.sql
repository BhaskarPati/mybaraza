CREATE TABLE probation_list (
	probation_list_id	serial primary key,
	studentid			varchar(12) references students,
	org_id				integer references orgs,
	approvedby			varchar(50),
	approvaltype		varchar(25),
	approvedate			timestamp default now(),
	clientip			varchar(50)
);
CREATE INDEX probation_list_studentid ON probation_list (studentid);
CREATE INDEX probation_list_org_id ON probation_list (org_id);

ALTER TABLE students ADD sys_audit_trail_id	integer references sys_audit_trail;
ALTER TABLE students ADD seechaplain boolean default false not null;
CREATE INDEX students_sys_audit_trail_id  ON students (sys_audit_trail_id);




UPDATE students SET onprobation = false;

DROP VIEW vw_students;
CREATE VIEW vw_students AS
	SELECT denominationview.religionid, denominationview.religionname, denominationview.denominationid, denominationview.denominationname,
		schools.schoolid, schools.schoolname, departments.departmentid, departments.departmentname,
		students.studentid, students.studentname, students.address, students.zipcode, students.town, 
		c1.countryname as addresscountry, students.telno, students.email,  students.guardianname, students.gaddress,
		students.gzipcode, students.gtown, c2.countryname as gaddresscountry, students.gtelno, students.gemail,
		students.accountnumber, students.Nationality, c3.countryname as Nationalitycountry, students.Sex,
		students.MaritalStatus, students.birthdate, students.firstpasswd, students.alumnae, students.postcontacts, students.onprobation,
		students.seeregistrar, students.seesecurity, students.seesss, students.seesdc, students.seehalls, students.seechaplain, 
		students.offcampus, students.currentcontact, students.staff, students.fullbursary, students.newstudent, 
		students.picturefile, students.emailuser, students.matriculate, students.details,
		students.student_edit,
		students.etranzact_card_no, students.org_id,
		entitys.first_password, ('G' || students.studentid) as gstudentid
	FROM (((denominationview INNER JOIN students ON denominationview.denominationid = students.denominationid)
		INNER JOIN departments ON departments.departmentid = students.departmentid)
		INNER JOIN schools ON schools.schoolid = departments.schoolid)
		INNER JOIN countrys as c1 ON students.countrycodeid = c1.countryid
		INNER JOIN countrys as c2 ON students.gcountrycodeid = c2.countryid
		INNER JOIN countrys as c3 ON students.Nationality = c3.countryid
		INNER JOIN entitys ON students.studentid = entitys.user_name;
		
CREATE OR REPLACE FUNCTION insQStudent(varchar(12), varchar(12), varchar(12)) RETURNS VARCHAR(120) AS $$
DECLARE
	mystud RECORD;
	myrec RECORD;
	mycourse RECORD;
	myquarter RECORD;
	mymajor RECORD;
	mystr VARCHAR(120);
	mydegreeid int;
	creditcount real;
	mycurrqs int;
	mystudylevel int;
	myqresidentid int;
	mylatefees real;
	mycurrbalance real;
	mynarrative VARCHAR(120);
BEGIN
	SELECT s.org_id, s.onprobation, s.residenceid, s.blockname, s.roomnumber,
		s.currentbalance, s.accountnumber, s.newstudent, 
		s.sex, s.nationality, s.maritalstatus, s.birthdate, s.address, s.zipcode, s.town, s.countrycodeid, 
		s.stateid, s.telno, s.mobile, s.email,  s.guardianname, s.gaddress, s.gzipcode, s.gtown, 
		s.gcountrycodeid, s.gtelno, s.gemail, 
		s.seeregistrar, s.seesecurity, s.seesss, s.seesdc, s.seehalls, s.seechaplain, 
		entitys.entity_password, entitys.first_password
		INTO mystud
	FROM students as s INNER JOIN entitys ON s.studentid = entitys.user_name
	WHERE (studentid = $2);

	mydegreeid := getstudentdegreeid($2);
	mystudylevel := getstudylevel(mydegreeid);
	myqresidentid := get_qresidentid(mystud.residenceid, $1);
	
	SELECT majors.majorid, majors.minlevel, majors.maxlevel INTO mymajor
	FROM majors INNER JOIN studentmajors ON majors.majorid = studentmajors.majorid
	WHERE (studentmajors.studentdegreeid = mydegreeid);
	
	SELECT qstudents.qstudentid, studentdegrees.sublevelid INTO myrec
	FROM qstudents INNER JOIN studentdegrees ON qstudents.studentdegreeid = studentdegrees.studentdegreeid
	WHERE (qstudents.studentdegreeid = mydegreeid) AND (qstudents.quarterid = $1);
	
	SELECT qlatereg, qlastdrop, lateregistrationfee, getchargedays(qlatereg, current_date) as latedays,
		lateregistrationfee * getchargedays(qlatereg, current_date) as latefees,
		quarterid, substring(quarterid from 11 for 1) as quarter,
		length(quarterid) as q_length
	INTO myquarter
	FROM quarters WHERE (quarterid = $1);
	
	IF (mystud.currentbalance IS NOT NULL) THEN
		mycurrbalance := mystud.currentbalance;
	ELSIF (mystud.newstudent = true) THEN
		mycurrbalance := 0;
	END IF;

	mylatefees := 0;
	mynarrative := '';
	IF (myquarter.latefees > 0) AND ((mystud.newstudent = false) OR (myquarter.quarter != '1')) THEN 
		mylatefees := myquarter.latefees;
		mynarrative := 'Late Registration fees charges for ' || CAST(myquarter.latedays as text) || ' days at a rate of ' || CAST(myquarter.lateregistrationfee as text) || ' Per day.';
	END IF;

	IF (mystudylevel is null) AND (mymajor.minlevel is not null) THEN
		mystudylevel := mymajor.minlevel;
	ELSIF (mystudylevel is null) THEN
		mystudylevel := 100;
	ELSIF (substring($1 from 11 for 1) = '1') THEN
			mystudylevel := mystudylevel + 100;
	END IF;

	IF (mymajor.maxlevel is not null) THEN
		IF (mystudylevel > mymajor.maxlevel) THEN
			mystudylevel := mymajor.maxlevel;
		END IF;
	ELSE
		IF (mystudylevel > 500) THEN
			mystudylevel := 500;
		END IF;
	END IF;

	IF (myquarter.qlastdrop < current_date) THEN
		RAISE EXCEPTION 'The registration is closed for this session.';
	ELSIF (mystud.sex is null) or (mystud.nationality is null) or (mystud.maritalstatus is null) or (mystud.birthdate is null) THEN
		RAISE EXCEPTION 'Your students details are in complete and need to be updated by registry';
	ELSIF (mystud.address is null) or (mystud.town is null) or (mystud.countrycodeid is null) or (mystud.stateid is null) THEN
		RAISE EXCEPTION 'Your students address details are in complete and need to be updated by registry';
	ELSIF (mystud.telno is null) or (mystud.mobile is null) or (mystud.email is null) THEN
		RAISE EXCEPTION 'Your students contact details are in complete and need to be updated by registry';
	ELSIF (mystud.guardianname is null) THEN
		RAISE EXCEPTION 'Your guardian details are in complete and need to be updated by registry';
	ELSIF (mystud.gaddress is null) or (mystud.gzipcode is null) or (mystud.gtown is null) or (mystud.gcountrycodeid is null) or (mystud.gtelno is null) or (mystud.gemail is null) THEN
		RAISE EXCEPTION 'Your guardian address details are in complete and need to be updated by registry';
	ELSIF (mystud.onprobation = true) THEN
		RAISE EXCEPTION 'Student on Probation cannot proceed.';
	ELSIF (mystud.seeregistrar = true) THEN
		RAISE EXCEPTION 'Cannot Proceed, See Registars office.';
	ELSIF (mystud.seesecurity = true) THEN
		RAISE EXCEPTION 'Cannot Proceed, See security office.';
	ELSIF (mystud.seesss = true) THEN
		RAISE EXCEPTION 'Cannot Proceed, See Student Support office.';
	ELSIF (mystud.seesdc = true) THEN
		RAISE EXCEPTION 'Cannot Proceed, See the dean of students.';
	ELSIF (mystud.seehalls = true) THEN
		RAISE EXCEPTION 'Cannot Proceed, See hall dean office.';
	ELSIF (mystud.seechaplain = true) THEN
		RAISE EXCEPTION 'Cannot Proceed, See the chaplain office.';
	ELSIF (mystud.entity_password = md5(mystud.first_password)) THEN
		RAISE EXCEPTION 'You must change your password first before proceeding.';
	ELSIF (mystud.accountnumber IS NULL) THEN
		RAISE EXCEPTION 'You must have an account number, contact Finance office.';
	ELSIF (mydegreeid IS NULL) THEN
		RAISE EXCEPTION 'No Degree Indicated contact Registrars Office';
	ELSIF (getcoremajor(mydegreeid) IS NULL) THEN
		RAISE EXCEPTION 'No Major Indicated contact Registrars Office';
	ELSIF ((myrec.sublevelid = 'UGPM') AND (myquarter.q_length <> 12)) THEN
		RAISE EXCEPTION 'Select the session with either 1M, 2M or 3M';
	ELSIF (myrec.qstudentid IS NULL) THEN
		INSERT INTO qstudents(quarterid, studentdegreeid, studylevel, currbalance, charges, financenarrative, paymenttype, org_id)
		VALUES ($1, mydegreeid, mystudylevel, mycurrbalance, mylatefees, mynarrative, 1, mystud.org_id);
		
		mycurrqs := getqstudentid($2);
		creditcount := 0;
		FOR mycourse IN SELECT yeartaken, courseid, min(qcourseid) as qcourseid, max(credithours) as credithours
			FROM qcoursecheckpass
			WHERE (elective = false) AND (coursepased = false) AND (prereqpassed = true)
				AND (yeartaken <= (mystudylevel/100)) AND (studentid = $2) AND (quarterid = $1)
			GROUP BY yeartaken, courseid
			ORDER BY yeartaken, courseid
		LOOP
			IF (creditcount < 16) THEN
				INSERT INTO qgrades(qstudentid, qcourseid, hours, credit, approved) 
				VALUES (mycurrqs, mycourse.qcourseid, mycourse.credithours, mycourse.credithours, true);
				creditcount := creditcount + mycourse.credithours;
			END IF;
		END LOOP;
		
		mystr := 'Semester registered confirm course selection and awaiting approval';
	ELSE
		mystr := 'You are already registered for the Semester proceed with course selection';
	END IF;

    RETURN mystr;
END;
$$ LANGUAGE plpgsql;
		
-- update the person who approved a student
CREATE OR REPLACE FUNCTION upd_students() RETURNS trigger AS $$
DECLARE
	v_user_id		varchar(50);
	v_user_ip		varchar(50);
	mystr 			varchar(120);
BEGIN

	SELECT user_id, user_ip INTO v_user_id, v_user_ip
	FROM sys_audit_trail
	WHERE (sys_audit_trail_id = NEW.sys_audit_trail_id);
	IF(v_user_id is null)THEN
		v_user_id := current_user;
		v_user_ip := cast(inet_client_addr() as varchar);
	ELSE
		SELECT user_name INTO v_user_id
		FROM entitys WHERE entity_id::varchar = v_user_id;
	END IF;
	
	IF(OLD.onprobation <> NEW.onprobation)THEN
		INSERT INTO probation_list(studentid, approvedby, approvaltype, approvedate, clientip) 
		VALUES (NEW.studentid, v_user_id, 'Probation ' || NEW.onprobation::text, now(), v_user_ip);
	END IF;
	IF(OLD.seeregistrar <> NEW.seeregistrar)THEN
		INSERT INTO probation_list(studentid, approvedby, approvaltype, approvedate, clientip) 
		VALUES (NEW.studentid, v_user_id, 'Registrar ' || NEW.seeregistrar::text, now(), v_user_ip);
	END IF;
	IF(OLD.seesecurity <> NEW.seesecurity)THEN 
		INSERT INTO probation_list(studentid, approvedby, approvaltype, approvedate, clientip) 
		VALUES (NEW.studentid, v_user_id, 'Security ' || NEW.seesecurity::text, now(), v_user_ip);
	END IF;
	IF(OLD.seesss <> NEW.seesss)THEN
		INSERT INTO probation_list(studentid, approvedby, approvaltype, approvedate, clientip) 
		VALUES (NEW.studentid, v_user_id, 'Student Support ' || NEW.seesss::text, now(), v_user_ip);
	END IF;
	IF(OLD.seesdc <> NEW.seesdc)THEN
		INSERT INTO probation_list(studentid, approvedby, approvaltype, approvedate, clientip) 
		VALUES (NEW.studentid, v_user_id, 'Dean of Students ' || NEW.seesdc::text, now(), v_user_ip);
	END IF;
	IF(OLD.seehalls <> NEW.seehalls)THEN
		INSERT INTO probation_list(studentid, approvedby, approvaltype, approvedate, clientip) 
		VALUES (NEW.studentid, v_user_id, 'Halls ' || NEW.seehalls::text, now(), v_user_ip);
	END IF;
	IF(OLD.seechaplain <> NEW.seechaplain)THEN
		INSERT INTO probation_list(studentid, approvedby, approvaltype, approvedate, clientip) 
		VALUES (NEW.studentid, v_user_id, 'Chaplain ' || NEW.seechaplain::text, now(), v_user_ip);
	END IF;
	IF(OLD.offcampus <> NEW.offcampus)THEN
		INSERT INTO probation_list(studentid, approvedby, approvaltype, approvedate, clientip) 
		VALUES (NEW.studentid, v_user_id, 'Off Campus ' || NEW.offcampus::text, now(), v_user_ip);
	END IF;

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER upd_students AFTER UPDATE ON students
    FOR EACH ROW EXECUTE PROCEDURE upd_students();
    


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
	WHERE (finaceapproval = false) AND (age(residence_time) > '1 day'::interval) AND (offcampus = false)
		AND (qresidenceid is not null) AND (quarterid = myrec.quarterid);
	
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


