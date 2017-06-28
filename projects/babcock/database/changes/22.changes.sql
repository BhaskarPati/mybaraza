ALTER TABLE students ADD etranzact_card_no	varchar(64);

CREATE VIEW vw_students AS
	SELECT denominationview.religionid, denominationview.religionname, denominationview.denominationid, denominationview.denominationname,
		schools.schoolid, schools.schoolname, departments.departmentid, departments.departmentname,
		students.studentid, students.studentname, students.address, students.zipcode, students.town, 
		students.seeregistrar, students.seesecurity,
		c1.countryname as addresscountry, students.telno, students.email,  students.guardianname, students.gaddress,
		students.gzipcode, students.gtown, c2.countryname as gaddresscountry, students.gtelno, students.gemail,
		students.accountnumber, students.Nationality, c3.countryname as Nationalitycountry, students.Sex,
		students.MaritalStatus, students.birthdate, students.firstpasswd, students.alumnae, students.postcontacts, students.onprobation,
		students.offcampus, students.currentcontact, students.staff, students.fullbursary, students.newstudent, 
		students.picturefile, students.emailuser, students.matriculate, students.details, 
		students.etranzact_card_no, students.org_id
	FROM (((denominationview INNER JOIN students ON denominationview.denominationid = students.denominationid)
		INNER JOIN departments ON departments.departmentid = students.departmentid)
		INNER JOIN schools ON schools.schoolid = departments.schoolid)
		INNER JOIN countrys as c1 ON students.countrycodeid = c1.countryid
		INNER JOIN countrys as c2 ON students.gcountrycodeid = c2.countryid
		INNER JOIN countrys as c3 ON students.Nationality = c3.countryid;

UPDATE qgrades SET org_id = qstudents.org_id 
FROM qstudents
WHERE (qgrades.org_id is null)
	AND (qgrades.qstudentid = qstudents.qstudentid);


DROP TRIGGER ins_instructors ON instructors;

CREATE TRIGGER ins_instructors BEFORE INSERT OR UPDATE ON instructors
  FOR EACH ROW EXECUTE PROCEDURE ins_instructors();

CREATE OR REPLACE FUNCTION insQCourse(varchar(12), varchar(12), varchar(12)) RETURNS VARCHAR(120) AS $$
DECLARE
	mysrec RECORD;
	myrec RECORD;
	mystr VARCHAR(120);
	mycurrqs int;
BEGIN
	mycurrqs := getqstudentid($2);

	SELECT qstudentid, finalised, approved, org_id
		INTO mysrec
	FROM qstudents
	WHERE (qstudentid = mycurrqs);

	SELECT qgradeid, dropped, approved 
		INTO myrec
	FROM qgrades
	WHERE (qstudentid = mycurrqs) AND (qcourseid = CAST($1 as int));
	
	IF (mysrec.qstudentid IS NULL) THEN
		RAISE EXCEPTION 'Please register for Semester and select residence first.';
	ELSIF (mysrec.finalised = true) THEN
		RAISE EXCEPTION 'You have closed the selection.';
	ELSIF (myrec.qgradeid IS NULL) THEN
		INSERT INTO qgrades(qstudentid, qcourseid, hours, credit, approved, org_id) 
		VALUES (mycurrqs, CAST($1 AS integer), getcoursehours(CAST($1 AS integer)), getcoursecredits(CAST($1 AS integer)), true, mysrec.org_id);
		mystr := 'Course registered awaiting approval';
	ELSIF (myrec.dropped=true) THEN
		UPDATE qgrades SET dropped=false, askdrop=false, approved=false, hours=getcoursehours(CAST($1 AS integer)), credit=getcoursecredits(CAST($1 AS integer)) WHERE qgradeid = myrec.qgradeid;
		mystr := 'Course registered awaiting approval';
	ELSE
		mystr := 'Course already registered';
	END IF;

    RETURN mystr;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION insQSpecialCourse(varchar(12), varchar(12), varchar(12)) RETURNS VARCHAR(120) AS $$
DECLARE
	mysrec RECORD;
	myrec RECORD;
	mystr VARCHAR(120);
	mycurrqs int;
BEGIN
	mycurrqs := getqstudentid($2);

	SELECT qstudentid, finalised, approved, org_id
		INTO mysrec
	FROM qstudents
	WHERE (qstudentid = mycurrqs);

	SELECT qgradeid, dropped, approved 
		INTO myrec
	FROM qgrades
	WHERE (qstudentid = mycurrqs) AND (qcourseid = CAST($1 as int));
	
	IF (mysrec.qstudentid IS NULL) THEN
		RAISE EXCEPTION 'Please register for Semester and select residence first.';
	ELSIF (mysrec.finalised = true) THEN
		RAISE EXCEPTION 'You have closed the selection.';
	ELSIF (myrec.qgradeid IS NULL) THEN
		INSERT INTO qgrades(qstudentid, qcourseid, hours, credit, approved, org_id) 
		VALUES (mycurrqs, CAST($1 AS integer), getcoursehours(CAST($1 AS integer)), getcoursecredits(CAST($1 AS integer)), false, mysrec.org_id);
		mystr := 'Course registered awaiting approval';
	ELSIF (myrec.dropped=true) THEN
		UPDATE qgrades SET dropped=false, askdrop=false, approved=false, hours=getcoursehours(CAST($1 AS integer)), credit=getcoursecredits(CAST($1 AS integer)) WHERE qgradeid = myrec.qgradeid;
		mystr := 'Course registered awaiting approval';
	ELSE
		mystr := 'Course already registered';
	END IF;

    RETURN mystr;
END;
$$ LANGUAGE plpgsql;


UPDATE studentpayments SET org_id = qstudents.org_id 
FROM qstudents
WHERE (studentpayments.org_id is null)
	AND (studentpayments.qstudentid = qstudents.qstudentid);

update majors set quarterload = 16 where quarterload = 10;

DROP VIEW vwstudentpayments;
CREATE VIEW vwstudentpayments AS
	SELECT students.studentid, students.studentname, students.accountnumber,
		qstudents.qstudentid, qstudents.quarterid, qstudents.financeclosed, qstudents.org_id, 
		studentpayments.studentpaymentid, studentpayments.applydate, studentpayments.amount, 
		studentpayments.approved, studentpayments.approvedtime,
		studentpayments.narrative, studentpayments.Picked, studentpayments.Pickeddate,
		studentpayments.terminalid, phistory.phistoryid, phistory.phistoryname, 
		(CASE WHEN studentpayments.approved = false THEN 
		'<a href="payments/paymentClient.jsp?TRANSACTION_ID='|| studentpayments.studentpaymentid
		|| '" target="_blank"><IMG SRC="resources/images/etranzact.jpg" WIDTH=120 HEIGHT=24 ALT=""></a>'
		ELSE 'The payment is completed and updated' END) as makepayment,

		(CASE WHEN studentpayments.approved = false THEN 
		'<a href="payments/paymentClient.new.jsp?TRANSACTION_ID='|| studentpayments.studentpaymentid
		|| '" target="_blank"><IMG SRC="resources/images/etranzact.jpg" WIDTH=120 HEIGHT=24 ALT=""></a>'
		ELSE 'The payment is completed and updated' END) as visapayment,

		(CASE WHEN studentpayments.approved = false THEN 
		'<a href="payments/query.jsp?TRANSACTION_ID='|| studentpayments.studentpaymentid
		|| '" target="_blank">Query Payment Status</a>'
		ELSE 'Ok' END) as querypayment
	FROM (((students INNER JOIN studentdegrees ON students.studentid = studentdegrees.studentid)
		INNER JOIN qstudents ON studentdegrees.studentdegreeid = qstudents.studentdegreeid)
		INNER JOIN studentpayments ON studentpayments.qstudentid = qstudents.qstudentid)
		INNER JOIN PHistory ON PHistory.PHistoryid = studentpayments.PHistoryid;

CREATE VIEW vw_qgrades AS
	SELECT qcourseview.schoolid, qcourseview.schoolname, qcourseview.departmentid, qcourseview.departmentname,
		qcourseview.degreelevelid, qcourseview.degreelevelname, qcourseview.coursetypeid, qcourseview.coursetypename,
		qcourseview.courseid, qcourseview.credithours, qcourseview.iscurrent,
		qcourseview.nogpa, qcourseview.yeartaken,
		qcourseview.instructorid, qcourseview.quarterid, qcourseview.qcourseid, qcourseview.classoption, qcourseview.maxclass,
		qcourseview.labcourse, qcourseview.extracharge, qcourseview.attendance as crs_attendance, qcourseview.oldcourseid,
		qcourseview.fullattendance, qcourseview.instructorname, qcourseview.coursetitle,
		grades.gradeid, grades.gradeweight, grades.minrange, grades.maxrange, grades.gpacount, grades.narrative as gradenarrative,
		qgrades.qgradeid, qgrades.qstudentid, qgrades.hours, qgrades.credit, qgrades.approved as crs_approved, qgrades.approvedate, qgrades.askdrop,	
		qgrades.askdropdate, qgrades.dropped, qgrades.dropdate, qgrades.repeated, qgrades.attendance, qgrades.narrative,
		qgrades.challengecourse, qgrades.nongpacourse, qgrades.instructormarks, qgrades.departmentmarks, qgrades.finalmarks,
		qgrades.org_id,
		(CASE qgrades.repeated WHEN true THEN 0 ELSE (grades.gradeweight * qgrades.credit) END) as gpa,
		(CASE WHEN ((qgrades.gradeid='W') OR (qgrades.gradeid='AW') OR (grades.gpacount=false) OR (qgrades.repeated=true) OR (qgrades.nongpacourse=true)) THEN 0 ELSE qgrades.credit END) as gpahours,
		(CASE WHEN ((qgrades.gradeid='W') OR (qgrades.gradeid='AW')) THEN 0 ELSE qgrades.hours END) as chargehours
	FROM (qcourseview INNER JOIN qgrades ON qcourseview.qcourseid = qgrades.qcourseid)
		INNER JOIN grades ON qgrades.gradeid = grades.gradeid;

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
		s.currentbalance, s.accountnumber, s.newstudent, s.seeregistrar,
		entitys.entity_password, entitys.first_password
		INTO mystud
	FROM students as s INNER JOIN entitys ON s.studentid = entitys.user_name
	WHERE (studentid = $2);

	mydegreeid := getstudentdegreeid($2);
	mystudylevel := getstudylevel(mydegreeid);
	myqresidentid := getcurrqresidentid(mystud.residenceid);
	
	SELECT INTO mymajor minlevel, maxlevel FROM majors INNER JOIN studentmajors ON majors.majorid = studentmajors.majorid
	WHERE (studentmajors.studentdegreeid = mydegreeid);
	
	SELECT INTO myrec qstudentid FROM qstudents
	WHERE (studentdegreeid = mydegreeid) AND (quarterid = $1);
	
	SELECT INTO myquarter qlatereg, qlastdrop, lateregistrationfee, getchargedays(qlatereg, current_date) as latedays,
		lateregistrationfee * getchargedays(qlatereg, current_date) as latefees,
		quarterid, substring(quarterid from 11 for 1) as quarter
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
	ELSIF (mystud.onprobation = true) THEN
		RAISE EXCEPTION 'Student on Probation cannot proceed.';
	ELSIF (mystud.seeregistrar = true) THEN
		RAISE EXCEPTION 'Cannot Proceed, See Registars office.';
	ELSIF (mystud.entity_password = md5(mystud.first_password)) THEN
		RAISE EXCEPTION 'You must change your password first before proceeding.';
	ELSIF (mystud.accountnumber IS NULL) THEN
		RAISE EXCEPTION 'You must have an account number, contact Finance office.';
	ELSIF (mydegreeid IS NULL) THEN
		RAISE EXCEPTION 'No Degree Indicated contact Registrars Office';
	ELSIF (getcoremajor(mydegreeid) IS NULL) THEN
		RAISE EXCEPTION 'No Major Indicated contact Registrars Office';
	ELSIF (myrec.qstudentid IS NULL) THEN
		IF (myqresidentid is null) THEN
			INSERT INTO qstudents(quarterid, studentdegreeid, studylevel, currbalance, charges, financenarrative, paymenttype, org_id)
			VALUES ($1, mydegreeid, mystudylevel, mycurrbalance, mylatefees, mynarrative, 1, mystud.org_id);
		ELSE
			INSERT INTO qstudents(quarterid, studentdegreeid, studylevel, qresidenceid, blockname, roomnumber, currbalance, charges, financenarrative, paymenttype, org_id)
			VALUES ($1, mydegreeid, mystudylevel, myqresidentid, mystud.blockname, mystud.roomnumber, mycurrbalance, mylatefees, mynarrative, 1, mystud.org_id);
		END IF;
		
		mycurrqs := getqstudentid($2);
		creditcount := 0;
		FOR mycourse IN SELECT yeartaken, courseid, min(qcourseid) as qcourseid, max(credithours) as credithours
			FROM qcoursecheckpass
			WHERE (elective = false) AND (coursepased = false) AND (prereqpassed = true)
				AND (yeartaken <= (mystudylevel/100)) AND (studentid = $2)
			GROUP BY yeartaken, courseid
			ORDER BY yeartaken, courseid
		LOOP
			IF (creditcount < 16) THEN
				INSERT INTO qgrades(qstudentid, qcourseid, hours, credit, approved) 
				VALUES (mycurrqs, mycourse.qcourseid, mycourse.credithours, mycourse.credithours, true);
				creditcount := creditcount + mycourse.credithours;
			END IF;
		END LOOP;
		
		mystr := 'Semester registered, confirm course selection and awaiting approval';
	ELSE
		mystr := 'You are already registered for the Semester proceed with course selection';
	END IF;

    RETURN mystr;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION reset_password(varchar(12), varchar(32), varchar(32)) RETURNS varchar(120) AS $$
DECLARE
	old_password 	varchar(64);
	passchange 		varchar(120);
	entityID		integer;
BEGIN
	entityID := CAST($1 AS INT);
	SELECT Entity_password INTO old_password
	FROM entitys WHERE (entity_id = entityID);

	passchange := first_password();
	UPDATE entitys SET first_password = passchange, Entity_password = md5(passchange) WHERE (entity_id = entityID);
	passchange := 'New Password : ' || passchange;

	return passchange;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION updQStudent(varchar(12), varchar(12), varchar(12)) RETURNS VARCHAR(120) AS $$
DECLARE
	myrec 		RECORD;
	mystr 		varchar(120);
	mysel		varchar(32);	
	mycurrqs 	int;
BEGIN
	mycurrqs := getqstudentid($2);
	mysel := $1;
	
	SELECT INTO myrec qstudentid, financeclosed, finaceapproval, mealtype, mealticket
		FROM qstudents WHERE (qstudentid = mycurrqs);

	IF (myrec.qstudentid is null) THEN
		RAISE EXCEPTION 'Register for the semester first';
	ELSIF (myrec.financeclosed = true) OR (myrec.finaceapproval = true) THEN
		RAISE EXCEPTION 'You cannot make changes after submiting your payment unless you apply on the post for it to be opened by finance.';
	ELSIF (myrec.mealticket > 0) THEN
		RAISE EXCEPTION 'You cannot not change meal selection after getting meal ticket.';
	ELSIF (mysel = '1') THEN
		UPDATE qstudents SET offcampus = true, premiumhall = false, mealtype = 'NONE' WHERE (qstudentid = mycurrqs);
		mystr := 'Off campus applied, await authorization.';
	ELSIF (mysel = '2') THEN
		UPDATE qstudents SET offcampus = false, premiumhall = false, mealtype = 'BL' WHERE (qstudentid = mycurrqs);
		mystr := 'Resident Student Taking Breakfast and Lunch';
	ELSIF (mysel = '3') THEN
		UPDATE qstudents SET offcampus = false, premiumhall = false, mealtype = 'BS' WHERE (qstudentid = mycurrqs);
		mystr := 'Resident Student Taking Breakfast and Supper';
	ELSIF (mysel = '4') THEN
		UPDATE qstudents SET offcampus = false, premiumhall = false, mealtype = 'LS' WHERE (qstudentid = mycurrqs);
		mystr := 'Resident Student Taking Lunch and Supper';
	ELSIF (mysel = '5') THEN
		UPDATE qstudents SET offcampus = false, premiumhall = false, mealtype = 'BLS' WHERE (qstudentid = mycurrqs);
		mystr := 'Resident Student Taking Breakfast, Lunch and Supper';
	ELSIF (mysel = '6') THEN
		UPDATE qstudents SET offcampus = false, premiumhall = true, mealtype = 'BL' WHERE (qstudentid = mycurrqs);
		mystr := 'Premier Hall Resident Student Taking Breakfast and Lunch';
	ELSIF (mysel = '7') THEN
		UPDATE qstudents SET offcampus = false, premiumhall = true, mealtype = 'BS' WHERE (qstudentid = mycurrqs);
		mystr := 'Premier Hall Resident Student Taking Breakfast and Supper';
	ELSIF (mysel = '8') THEN
		UPDATE qstudents SET offcampus = false, premiumhall = true, mealtype = 'LS' WHERE (qstudentid = mycurrqs);
		mystr := 'Premier Hall Resident Student Taking Lunch and Supper';
	ELSIF (mysel = '9') THEN
		UPDATE qstudents SET offcampus = false, premiumhall = true, mealtype = 'BLS' WHERE (qstudentid = mycurrqs);
		mystr := 'Premier Hall Resident Student Taking Breakfast, Lunch and Supper';
	ELSIF (mysel = '10') THEN
		UPDATE qstudents SET paymenttype = 1 WHERE (qstudentid = mycurrqs);
		mystr := 'Make full payment for the entire session.';
	ELSIF (mysel = '11') THEN
		UPDATE qstudents SET paymenttype = 2 WHERE (qstudentid = mycurrqs);
		mystr := 'Make full payment for the semester.';
	ELSIF (mysel = '12') THEN
		UPDATE qstudents SET paymenttype = 3 WHERE (qstudentid = mycurrqs);
		mystr := 'Applied for part payment for the semester.';
	ELSIF (mysel = '14') THEN
		UPDATE qstudents SET paymenttype = 4, offcampus = false, mealtype = 'BLS', qresidenceid = getcurrqresidentid('NA')
		WHERE (qstudentid = mycurrqs);
		mystr := 'Applied for acceptance fee.';
	ELSE
		RAISE EXCEPTION 'Make Proper selection';
	END IF;

    RETURN mystr;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION selQResidence(varchar(12), varchar(12), varchar(12)) RETURNS VARCHAR(120) AS $$
DECLARE
	mystr VARCHAR(120);
	myrec RECORD;
	myqstud int;
	myres int;
BEGIN
	myqstud := getqstudentid($2);
	myres := CAST($1 AS integer);

	SELECT qstudentid, finalised, financeclosed, finaceapproval, mealtype, mealticket
	INTO myrec
	FROM qstudents WHERE (qstudentid = myqstud);

	IF (myrec.qstudentid is null) THEN
		RAISE EXCEPTION 'Register for the semester first';
	ELSIF (myrec.financeclosed = true) OR (myrec.finaceapproval = true) THEN
		RAISE EXCEPTION 'You cannot make changes after submiting your payment unless you apply on the post for it to be opened by finance.';
	ELSIF (myrec.finalised = true) THEN
		RAISE EXCEPTION 'You have closed the selection.';
	ELSE
		UPDATE qstudents SET qresidenceid = myres, roomnumber = null WHERE (qstudentid = myqstud);
		mystr := 'Residence registered awaiting approval';
	END IF;

    RETURN mystr;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION insQCourse(varchar(12), varchar(12), varchar(12)) RETURNS VARCHAR(120) AS $$
DECLARE
	mysrec RECORD;
	myrec RECORD;
	mystr VARCHAR(120);
	mycurrqs int;
BEGIN
	mycurrqs := getqstudentid($2);

	SELECT INTO mysrec qstudentid, finalised, approved FROM qstudents
	WHERE (qstudentid = mycurrqs);

	SELECT INTO myrec qgradeid, dropped, approved FROM qgrades
	WHERE (qstudentid = mycurrqs) AND (qcourseid = CAST($1 as int));
	
	IF (mysrec.qstudentid IS NULL) THEN
		RAISE EXCEPTION 'Please register for Semester and select residence first.';
	ELSIF (mysrec.finalised = true) THEN
		RAISE EXCEPTION 'You have closed the selection.';
	ELSIF (myrec.qgradeid IS NULL) THEN
		INSERT INTO qgrades(qstudentid, qcourseid, hours, credit, approved) 
		VALUES (mycurrqs, CAST($1 AS integer), getcoursehours(CAST($1 AS integer)), getcoursecredits(CAST($1 AS integer)), true);
		mystr := 'Course registered awaiting approval';
	ELSIF (myrec.dropped=true) THEN
		UPDATE qgrades SET dropped=false, askdrop=false, approved=false, hours=getcoursehours(CAST($1 AS integer)), credit=getcoursecredits(CAST($1 AS integer)) WHERE qgradeid = myrec.qgradeid;
		mystr := 'Course registered awaiting approval';
	ELSE
		mystr := 'Course already registered';
	END IF;

    RETURN mystr;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION insQSpecialCourse(varchar(12), varchar(12), varchar(12)) RETURNS VARCHAR(120) AS $$
DECLARE
	mysrec RECORD;
	myrec RECORD;
	mystr VARCHAR(120);
	mycurrqs int;
BEGIN
	mycurrqs := getqstudentid($2);

	SELECT INTO mysrec qstudentid, finalised, approved FROM qstudents
	WHERE (qstudentid = mycurrqs);

	SELECT INTO myrec qgradeid, dropped, approved FROM qgrades
	WHERE (qstudentid = mycurrqs) AND (qcourseid = CAST($1 as int));
	
	IF (mysrec.qstudentid IS NULL) THEN
		RAISE EXCEPTION 'Please register for Semester and select residence first.';
	ELSIF (mysrec.finalised = true) THEN
		RAISE EXCEPTION 'You have closed the selection.';
	ELSIF (myrec.qgradeid IS NULL) THEN
		INSERT INTO qgrades(qstudentid, qcourseid, hours, credit, approved) 
		VALUES (mycurrqs, CAST($1 AS integer), getcoursehours(CAST($1 AS integer)), getcoursecredits(CAST($1 AS integer)), false);
		mystr := 'Course registered awaiting approval';
	ELSIF (myrec.dropped=true) THEN
		UPDATE qgrades SET dropped=false, askdrop=false, approved=false, hours=getcoursehours(CAST($1 AS integer)), credit=getcoursecredits(CAST($1 AS integer)) WHERE qgradeid = myrec.qgradeid;
		mystr := 'Course registered awaiting approval';
	ELSE
		mystr := 'Course already registered';
	END IF;

    RETURN mystr;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION dropQCourse(varchar(12), varchar(12), varchar(12)) RETURNS VARCHAR(50) AS $$
DECLARE
	myrec RECORD;
	mystr VARCHAR(50);
	mycurrqs int;
BEGIN
	mycurrqs := getqstudentid($2);

	SELECT INTO myrec qstudentid, finalised FROM qstudents
	WHERE (qstudentid = mycurrqs);

	IF (myrec.qstudentid IS NULL) THEN
		RAISE EXCEPTION 'Please register for Semester and select residence first.';
	ELSIF (myrec.finalised = true) THEN
		RAISE EXCEPTION 'You have closed the selection.';
	ELSE
		UPDATE qgrades SET askdrop = true, askdropdate = current_timestamp WHERE qgradeid = CAST($1 as int);
		UPDATE qgrades SET dropped = true, dropdate = current_date WHERE qgradeid = CAST($1 as int);
		mystr := 'Course Dropped.';
	END IF;
	
    RETURN mystr;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION insQClose(varchar(12), varchar(12), varchar(12)) RETURNS VARCHAR(250) AS $$
DECLARE
	myrec RECORD;
	mymajor RECORD;
	ttb RECORD;
	courserec RECORD;
	placerec RECORD;
	prererec RECORD;
	studentrec RECORD;
	myquarter RECORD;
	myqrec RECORD;
	mystr VARCHAR(250);
	mydegreeid int;
	myoverload boolean;
	myfeesline integer;
	mymaxcredit real;
	mylatefees int;
	mynarrative varchar(120);
BEGIN

	SELECT studentid, studentdegreeid, qstudentid, finalised, finaceapproval, gpa, hours, 
		quarterid, quarter, mincredits, maxcredits, studylevel,
		offcampus, residenceoffcampus, overloadapproval, overloadhours, studentdeanapproval
		INTO myrec
	FROM studentquarterview
	WHERE (qstudentid = CAST($1 as int));

	mydegreeid := myrec.studentdegreeid;
	mymaxcredit := myrec.maxcredits;
	
	SELECT majors.quarterload INTO mymajor
	FROM (majors INNER JOIN studentmajors ON majors.majorid = studentmajors.majorid)
	WHERE studentmajors.studentdegreeid = mydegreeid;
	
	IF (mymajor.quarterload IS NOT NULL) THEN
		mymaxcredit := mymajor.quarterload;
	END IF;

	SELECT INTO courserec courseid, coursetitle FROM selcourseview 
		WHERE (qstudentid = myrec.qstudentid) AND (maxclass < qcoursestudents);
	SELECT INTO prererec courseid, coursetitle, prereqpassed FROM selectedgradeview 
		WHERE (qstudentid = myrec.qstudentid) AND (prereqpassed = false);
		
---	SELECT INTO placerec qcoursecheckpass.yeartaken, qcoursecheckpass.courseid, qcoursecheckpass.coursetitle
---	FROM qcoursecheckpass LEFT JOIN studentgradeview ON (qcoursecheckpass.studentid = studentgradeview.studentid)
---		AND (qcoursecheckpass.courseid = studentgradeview.courseid)
---	WHERE (qcoursecheckpass.elective = false) AND (qcoursecheckpass.coursepased = false)
---		AND (qcoursecheckpass.yeartaken <= ((myrec.studylevel/100)-1)) AND (qcoursecheckpass.studentid = $1)
---		AND ((studentgradeview.gradeid is null) OR (studentgradeview.gradeid <> 'NG'))
---	ORDER BY yeartaken, courseid;

	SELECT INTO ttb coursetitle FROM studenttimetableview WHERE (qstudentid=myrec.qstudentid)
	AND (gettimecount(qstudentid, starttime, endtime, cmonday, ctuesday, cwednesday, cthursday, cfriday, csaturday, csunday) >1);


	SELECT INTO myquarter qlatereg, qlastdrop, lateregistrationfee, getchargedays(qlatereg, current_date) as latedays,
		lateregistrationfee * getchargedays(qlatereg, current_date) as latefees,
		quarterid, substring(quarterid from 11 for 1) as quarter
	FROM quarters WHERE (active = true);

	mylatefees := 0;
	mynarrative := '';
	IF (myrec.qstudentid is not null) AND (myquarter.latefees > 0) THEN 
		mylatefees := myquarter.latefees;
		mynarrative := 'Late Registration fees charges for ' || CAST(myquarter.latedays as text) || ' days at a rate of ' || CAST(myquarter.lateregistrationfee as text) || ' Per day.';

		SELECT INTO myqrec charges, lateFeePayment
		FROM qstudents
		WHERE (qstudentid = myrec.qstudentid);

		if(myqrec.lateFeePayment = false) then
			UPDATE qstudents SET charges = mylatefees, financenarrative = mynarrative
			WHERE (qstudentid = myrec.qstudentid) AND (firstclosetime is null);
		end if;
	END IF;

	IF (myrec.qstudentid IS NULL) THEN 
		RAISE EXCEPTION 'Please register for the semester and make course selections first before closing.';
	ELSIF (myrec.finalised = true) THEN
		RAISE EXCEPTION 'Semester is closed for registration';
	ELSIF (ttb.coursetitle IS NOT NULL) THEN
		RAISE EXCEPTION 'You have an timetable clashing for % ', ttb.coursetitle;
	ELSIF (courserec.courseid IS NOT NULL) THEN
		RAISE EXCEPTION 'The class %, % is full ', courserec.courseid, courserec.coursetitle;
	ELSIF (prererec.courseid IS NOT NULL) THEN
		RAISE EXCEPTION 'You need to complete the prerequisites or placement for course % : %', prererec.courseid, prererec.coursetitle;
---	ELSIF (placerec.courseid IS NOT NULL) THEN
---		mystr := 'You need to take all lower level course first like ' || placerec.courseid || ', ' || placerec.coursetitle;
	ELSIF (myrec.hours < myrec.mincredits) AND (myrec.overloadapproval = false) THEN
		RAISE EXCEPTION 'You have an underload, the required minimum is % credits.', myrec.mincredits;
	ELSIF (myrec.hours < myrec.mincredits) AND (myrec.overloadapproval = true) AND (myrec.hours < myrec.overloadhours) THEN
		RAISE EXCEPTION 'You have an underload, you can only take the approved minimum of % ', CAST(myrec.overloadhours as text);
	ELSIF (myrec.hours > mymaxcredit) AND (myrec.overloadapproval = false) THEN
		RAISE EXCEPTION 'You have an overload, the required maximum is % ', CAST(mymaxcredit as text);
	ELSIF (myrec.hours > mymaxcredit) AND (myrec.overloadapproval = true) AND (myrec.hours > myrec.overloadhours) THEN
		RAISE EXCEPTION 'You have an overload, you can only take the approved maximum of % ', CAST(myrec.overloadhours as text);
	ELSIF (myrec.offcampus = true) and (myrec.studentdeanapproval = false) THEN
		RAISE EXCEPTION 'You have no clearence to be off campus';
	ELSE
		UPDATE qstudents SET finalised = true WHERE qstudentid = myrec.qstudentid;
		UPDATE qstudents SET firstclosetime = now() WHERE (firstclosetime is null) AND (qstudentid = myrec.qstudentid);
		mystr := 'Semester Submision done check status for approvals.';
	END IF;

    RETURN mystr;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION insCloseFinance(varchar(12), varchar(12), varchar(12)) RETURNS VARCHAR(250) AS $$
DECLARE
	myrec RECORD;
	mystr VARCHAR(250);
BEGIN

	SELECT studentid, studentdegreeid, qstudentid, finalised, finaceapproval, paymentamount
		INTO myrec
	FROM vwqstudentbalances
	WHERE (qstudentid = CAST($1 as int));

	IF (myrec.qstudentid IS NULL) THEN 
		RAISE EXCEPTION 'Please register for the semester and make course selections first before closing.';
	ELSIF (myrec.finaceapproval = true) THEN
		mystr := 'You already have financial approval';
	ELSIF (myrec.finalised = false) THEN
		mystr := 'Submit courses first';
	ELSIF (myrec.paymentamount > 1000) THEN
		mystr := 'Clear all fees first before you can be financialy approved';
	ELSE
		mystr := 'You will get Financial approval';
	END IF;

    RETURN mystr;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION updOpenFinance(varchar(12), varchar(12), varchar(12)) RETURNS VARCHAR(120) AS $$
DECLARE
	myrec RECORD;
	mystr VARCHAR(120);
BEGIN
	SELECT INTO myrec qstudentid, finaceapproval, financeclosed FROM qstudents
	WHERE (qstudentid = CAST($1 as int));
	
	IF (myrec.qstudentid IS NULL) THEN
		RAISE EXCEPTION 'You must add the semester first.';
	ELSIF (myrec.finaceapproval = true) THEN
		RAISE EXCEPTION 'You have been finacially approved, Visit busuary to get your payments opened.';
	ELSE
		UPDATE qstudents SET finaceapproval = false, financeclosed = false WHERE qstudentid = myrec.qstudentid;
		mystr := 'Your financial application has been opened for adjustments.';
	END IF;
		
	RETURN mystr;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION insQPayment(varchar(12), varchar(12), varchar(12)) RETURNS VARCHAR(120) AS $$
DECLARE
	myrec RECORD;
	myqrec RECORD;
	mypayrec RECORD;
	mypayreccheck RECORD;
	myquarter RECORD;
	mystud RECORD;
	mystr VARCHAR(120);
	mycurrqs int;
	myamount REAL;
	mylatefees int;
	mynarrative varchar(120);
BEGIN
	mycurrqs := getqstudentid($2);
	
	SELECT INTO mystud currentbalance, accountnumber, newstudent, seeregistrar
	FROM students WHERE (studentid = $2);
	
	SELECT INTO mypayrec studentpaymentid
	FROM studentpayments WHERE (qstudentid = mycurrqs) AND (approved = false);
	
	SELECT INTO mypayreccheck studentpaymentid
	FROM studentpayments WHERE (qstudentid = mycurrqs) AND (approved = true);
	
	SELECT INTO myqrec charges, org_id
	FROM qstudents
	WHERE (qstudentid = mycurrqs);	
	
	SELECT INTO myquarter qlatereg, qlastdrop, lateregistrationfee, getchargedays(qlatereg, current_date) as latedays,
		lateregistrationfee * getchargedays(qlatereg, current_date) as latefees,
		quarterid, substring(quarterid from 11 for 1) as quarter
	FROM quarters WHERE (active = true);
	
	mylatefees := 0;
	mynarrative := '';
	IF (myquarter.latefees > 0) AND (myqrec.charges = 0) AND ((mystud.newstudent = false) OR (myquarter.quarter != '1')) THEN 
		mylatefees := myquarter.latefees;
		mynarrative := 'Late Registration fees charges for ' || CAST(myquarter.latedays as text) || ' days at a rate of ' || CAST(myquarter.lateregistrationfee as text) || ' Per day.';
	END IF;

	IF (mycurrqs is not null) AND (mypayreccheck.studentpaymentid is null) AND (myquarter.latefees > 0) THEN
		UPDATE qstudents SET charges = mylatefees, financenarrative = mynarrative
		WHERE (qstudentid = mycurrqs);
	END IF;
	
	SELECT accountnumber, quarterid, currbalance, fullfinalbalance, finalbalance, studylevel,
		paymenttype, ispartpayment, offcampus, studentdeanapproval, financeclosed, finaceapproval
	INTO myrec
	FROM vwqstudentbalances
	WHERE (qstudentid = mycurrqs);	

	myamount := 0;
	mystr := null;
	IF (myrec.currbalance is null) THEN
		RAISE EXCEPTION 'Application for payment rejected because your current credit is not updated, send a post to Bursary.';
	ELSIF (myrec.financeclosed = true) OR (myrec.finaceapproval = true) THEN
		RAISE EXCEPTION 'You cannot make changes after submiting your payment unless you apply on the post for it to be opened by finance.';
	ELSIF (myrec.offcampus = true) AND (myrec.studentdeanapproval = false) THEN
		RAISE EXCEPTION 'Application for payment rejected, first get off campus approval.';
	ELSIF (myrec.paymenttype = 1) THEN
		myamount := myrec.fullfinalbalance;
	ELSIF (myrec.paymenttype = 2) THEN
		myamount := myrec.finalbalance;
	ELSIF (myrec.paymenttype = 3) AND (myrec.ispartpayment = false) THEN
		RAISE EXCEPTION 'Application for payment rejected, your require approval for the payment plan';
	ELSIF (myrec.paymenttype = 3) AND (myrec.ispartpayment = true) THEN
		myamount := myrec.currbalance + (myrec.finalbalance - myrec.currbalance) / 2;
	ELSIF (myrec.paymenttype = 4) AND (myrec.studylevel = 100) THEN
		myamount := -209000.0;
	ELSIF (myrec.paymenttype = 4) AND (myrec.studylevel != 100) THEN
		RAISE EXCEPTION 'You can only apply for acceptance fee.';
	ELSE
		RAISE EXCEPTION 'Application for payment rejected, verify application and approvals';
	END IF;

	IF (myamount < 0) THEN
		IF (mypayrec.studentpaymentid is null) THEN
			INSERT INTO studentpayments (org_id, qstudentid, amount, narrative) 
			VALUES (myqrec.org_id, mycurrqs, myamount * (-1), CAST(nextval('studentpayment_seq') as text) || 'Fees;' || myrec.quarterid || ';' || myrec.accountnumber);
		ELSE
			UPDATE studentpayments SET amount = myamount * (-1)
			WHERE studentpaymentid = mypayrec.studentpaymentid;
		END IF;
		UPDATE qstudents SET financeclosed = true WHERE (qstudentid = mycurrqs);
		mystr := 'Application for payment accepted, proceed';
	END IF;

	IF (myamount >= 0) AND (mystr is null) THEN
		UPDATE qstudents SET financeclosed = true WHERE qstudentid = mycurrqs;
		mystr := 'Fees indicated as fully paid';
	END IF;

    RETURN mystr;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER updstudentpayments ON studentpayments;

CREATE OR REPLACE FUNCTION updstudentpayments() RETURNS trigger AS $$
DECLARE
	reca 					RECORD;
	old_studentpaymentid 	integer;
BEGIN
	SELECT departments.schoolid, departments.departmentid, students.accountnumber, qstudents.quarterid, qstudents.studylevel 
		INTO reca
	FROM ((departments INNER JOIN students ON students.departmentid = departments.departmentid)
		INNER JOIN studentdegrees ON students.studentid = studentdegrees.studentid)
		INNER JOIN qstudents ON studentdegrees.studentdegreeid = qstudents.studentdegreeid
	WHERE (qstudents.qstudentid = NEW.qstudentid);

	IF (TG_OP = 'INSERT') THEN
		SELECT studentpaymentid INTO old_studentpaymentid
		FROM studentpayments 
		WHERE (approved = false) AND (qstudentid = NEW.qstudentid);

		IF(old_studentpaymentid is not null)THEN
			RAISE EXCEPTION 'You have another uncleared payment, ammend that first and pay';
		END IF;
	ELSE
		IF(OLD.approved = true) AND (NEW.approved = true)THEN
			IF(OLD.amount <> NEW.amount)THEN
				RAISE EXCEPTION 'You cannot change amount value after transaction approval.';
			END IF;
		END IF;
	END IF;

	IF (reca.studylevel = 100) AND (reca.departmentid = 'CSMA') THEN
		NEW.terminalid = '0690000082';
	ELSIF (reca.studylevel = 100) AND (reca.departmentid = 'CSIT') THEN
		NEW.terminalid = '0690000082';
	ELSE
		NEW.terminalid = '0690000082';
	END IF;

	IF(NEW.narrative is null) THEN
		NEW.narrative = CAST(NEW.studentpaymentid as text) || ';Pay;' || reca.quarterid || ';' || reca.accountnumber;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER updstudentpayments BEFORE INSERT OR UPDATE ON studentpayments
    FOR EACH ROW EXECUTE PROCEDURE updstudentpayments();



