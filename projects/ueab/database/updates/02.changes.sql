

ALTER TABLE students ADD student_edit		varchar(50) default 'none' not null;

UPDATE students SET student_edit = 'allow';

CREATE OR REPLACE FUNCTION ins_students() RETURNS trigger AS $$
DECLARE
	v_entity_id		integer;
BEGIN

	SELECT entity_id INTO v_entity_id
	FROM entitys
	WHERE (user_name = upper(trim(NEW.studentid)));

	IF(v_entity_id is null)THEN
		INSERT INTO entitys (org_id, entity_type_id, entity_name, user_name, primary_email, first_password, entity_password)
		VALUES(0, 9, NEW.studentname, upper(trim(NEW.studentid)), NEW.email, NEW.firstpass, NEW.studentpass);

		INSERT INTO entitys (org_id, entity_type_id, entity_name, user_name, primary_email, first_password, entity_password)
		VALUES(0, 10, COALESCE(NEW.guardianname, NEW.studentname), 'G' || upper(trim(NEW.studentid)), NEW.gemail, NEW.gfirstpass, NEW.gstudentpass);
	END IF;
	
	IF(NEW.identification_no is null)THEN
		NEW.student_edit := 'allow';
	ELSIF(NEW.email is null)THEN
		NEW.student_edit := 'allow';
	ELSIF((NEW.address is null) OR (NEW.town is null) OR (NEW.countrycodeid is null) OR (NEW.telno is null) OR (NEW.county_id is null)) THEN
		NEW.student_edit := 'allow';
	ELSIF((NEW.guardianname is null) OR (NEW.gaddress is null) OR (NEW.gtown is null) OR (NEW.gcountrycodeid is null) OR (NEW.gtelno is null)) THEN 
		NEW.student_edit := 'allow';
	ELSIF(NEW.nationality is null) THEN
		NEW.student_edit := 'allow';
	ELSIF(NEW.disability is null) THEN
		NEW.student_edit := 'allow';
	ELSE
		NEW.student_edit := 'none';
	END IF;
	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER ins_students ON students;
CREATE TRIGGER ins_students BEFORE INSERT OR UPDATE ON students
FOR EACH ROW EXECUTE PROCEDURE ins_students();


DROP VIEW vw_students;
CREATE VIEW vw_students AS
	SELECT denominationview.religionid, denominationview.religionname, denominationview.denominationid, denominationview.denominationname,
		residences.residenceid, residences.residencename,
		schools.schoolid, schools.schoolname, c1.countryname as addresscountry, 
		students.org_id, students.studentid, students.studentname, students.address, students.zipcode, students.town,
		students.telno, students.email,  students.guardianname, students.gaddress,
		students.gzipcode, students.gtown, c2.countryname as gaddresscountry, students.gtelno, students.gemail,
		students.accountnumber, students.Nationality, c3.countryname as Nationalitycountry, students.Sex,
		students.MaritalStatus, students.birthdate, students.firstpass, students.alumnae, students.postcontacts, 
		students.onprobation, students.offcampus, students.currentcontact, students.currentemail, students.currenttel,
		students.seeregistrar, students.hallseats, students.staff, students.fullbursary, students.details,
		students.room_number, students.probation_details, students.registrar_details,
		students.student_edit,
		students.gfirstpass, ('G' || students.studentid) as gstudentid,
		('<a href="a_statement_acct.jsp?view=1:0&accountno=' || students.accountnumber ||
			'" target="_blank">View Accounts</a>') as view_statement
	FROM (((denominationview INNER JOIN students ON denominationview.denominationid = students.denominationid)
		INNER JOIN schools ON students.schoolid = schools.schoolid)
		LEFT JOIN residences ON students.residenceid = residences.residenceid)
		INNER JOIN countrys as c1 ON students.countrycodeid = c1.countryid
		INNER JOIN countrys as c2 ON students.gcountrycodeid = c2.countryid
		INNER JOIN countrys as c3 ON students.Nationality = c3.countryid;


CREATE OR REPLACE FUNCTION insQStudent(varchar(12), varchar(12), varchar(12)) RETURNS VARCHAR(1024) AS $$
DECLARE
	srec			RECORD;
	qrec			RECORD;
	qsrec			RECORD;
	qqrec			RECORD;
	v_minimal_fees	real;
	resid			VARCHAR(12);
	sclassid		INTEGER;
	qresid			INTEGER;
	mystr			VARCHAR(1024);
BEGIN
	SELECT students.onprobation, students.seeregistrar, students.probation_details, students.registrar_details,
		students.balance_time, CAST(students.balance_time as date) as balance_date, students.curr_balance,
		students.offcampus, students.residenceid, students.room_number, students.org_id,
		students.fullbursary, students.staff,
		students.identification_no, 
		students.email, 
		students.address, students.town, students.countrycodeid, students.telno, students.county_id, 
		students.guardianname, students.gaddress, students.gtown, students.gcountrycodeid, students.gtelno, 
		students.gemail, 
		students.nationality, 
		students.disability,
		studentdegrees.studentdegreeid, studentdegrees.degreeid, studentdegrees.sublevelid
	INTO srec
	FROM students INNER JOIN studentdegrees ON students.studentid = studentdegrees.studentid
	WHERE (studentdegrees.completed = false) AND (students.studentid = $2);

	SELECT quarterid, levellocationid, active, closed, charge_id, session_active, session_closed, minimal_fees
	INTO qrec
	FROM vw_charges
	WHERE (quarterid = $1) AND (sublevelid = srec.sublevelid);

	SELECT qstudentid INTO qsrec
	FROM qstudents WHERE (studentdegreeid = srec.studentdegreeid) AND (charge_id = qrec.charge_id);
	SELECT qstudentid INTO qqrec
	FROM qstudents WHERE (studentdegreeid = srec.studentdegreeid) AND (quarterid = $1); 

	IF (srec.offcampus = false) THEN
		resid := 'OC';
	ELSE
		resid := srec.residenceid;
	END IF;

	SELECT qresidenceid INTO qresid
	FROM qresidences
	WHERE (quarterid = qrec.quarterid) AND (residenceid = resid);

	v_minimal_fees := -1 * qrec.minimal_fees;
	IF (srec.fullbursary = true) THEN
		v_minimal_fees := 1000000;
	ELSIF (srec.staff = true) THEN
		v_minimal_fees := 1000000;
	END IF;
	
	mystr := 'You have to update your student details before you proceed. Click on student then student details, On student details click on go (green arrow) then click edit details. Put the correct details and save. You can thereafter proceed with registration';
	
	IF(srec.identification_no is null)THEN
		RAISE EXCEPTION 'No nation ID {For Kenyan} or Passport number <br>%', mystr;
	ELSIF(srec.email is null)THEN
		RAISE EXCEPTION 'No email address <br>%', mystr;
	ELSIF((srec.address is null) OR (srec.town is null) OR (srec.countrycodeid is null) OR (srec.telno is null) OR (srec.county_id is null)) THEN
		RAISE EXCEPTION 'No address details <br>%', mystr;
	ELSIF((srec.guardianname is null) OR (srec.gaddress is null) OR (srec.gtown is null) OR (srec.gcountrycodeid is null) OR (srec.gtelno is null)) THEN 
		RAISE EXCEPTION 'No guardian details <br>%', mystr;
	ELSIF(srec.nationality is null) THEN
		RAISE EXCEPTION 'No nationality <br>%', mystr;
	ELSIF(srec.disability is null) THEN
		RAISE EXCEPTION 'No disability stated <br>%', mystr;
	END IF;

	mystr := '';
	IF (qsrec.qstudentid IS NOT NULL) THEN
		RAISE EXCEPTION 'Semester already registered';
	ELSIF (qrec.active = false) OR (qrec.closed = true) THEN
		RAISE EXCEPTION 'The semester is closed for application';
	ELSIF (qrec.session_active = false) OR (qrec.session_closed = true) THEN
		RAISE EXCEPTION 'The semester session is closed for application';
	ELSIF (srec.studentdegreeid IS NULL) THEN
		RAISE EXCEPTION 'No Degree Indicated contact Registrars Office';
	ELSIF (srec.onprobation = true) THEN
		IF(srec.probation_details != null) THEN
			mystr := '<br/>' || srec.probation_details;
		END IF;
		RAISE EXCEPTION 'You are on Probation, See the Dean of Students. % ', mystr;
	ELSIF (srec.seeregistrar = true) THEN
		IF(srec.registrar_details != null) THEN
			mystr := '<br/>' ||srec.registrar_details;
		END IF;
		RAISE EXCEPTION 'Cannot Proceed, See Registars office. % ', mystr;
	ELSIF (qresid IS NULL) THEN
		RAISE EXCEPTION 'See the Dean of Students to allocate you a residence';
	ELSIF (srec.balance_date is null) THEN
		RAISE EXCEPTION 'Access your finace statement so that the system picks your current balance';
	ELSIF (srec.balance_date <> current_date) THEN
		RAISE EXCEPTION 'Access your finace statement so that the system picks your current balance';
	ELSIF (srec.curr_balance is null) THEN
		RAISE EXCEPTION 'You need to pay a minimum fee of % to register for the semster', qrec.minimal_fees;
	ELSIF (srec.curr_balance > v_minimal_fees) THEN
		RAISE EXCEPTION 'You need to pay a minimum fee of % to register for the semster', qrec.minimal_fees;
	ELSE
		sclassid := null;
		IF(qrec.levellocationid = 1)THEN
			sclassid := 0;
		END IF;

		IF(qqrec.qstudentid IS NULL) THEN
			INSERT INTO qstudents(org_id, quarterid, charge_id, studentdegreeid, chaplainapproval, qresidenceid, roomnumber, sabathclassid, currbalance)
			VALUES (srec.org_id, qrec.quarterid, qrec.charge_id, srec.studentdegreeid, true, qresid, srec.room_number, sclassid, srec.curr_balance);
			mystr := 'Quarter registered. Select courses and submit.';
		ELSE
			UPDATE qstudents SET charge_id = qrec.charge_id WHERE qstudentid = qqrec.qstudentid;
			mystr := 'Quarter registered. Select courses and submit.';
		END IF;
	END IF;

    RETURN mystr;
END;
$$ LANGUAGE plpgsql;


UPDATE fields SET field_size = 25;
UPDATE fields SET field_size = 85 WHERE (field_type = 'SUBGRID') OR (field_type = 'TABLE');

DROP VIEW vw_entry_forms;
CREATE VIEW vw_entry_forms AS
	SELECT entitys.entity_id, entitys.entity_name, 
		forms.form_id, forms.form_name, forms.form_number, forms.completed, forms.is_active, forms.use_key,
		entry_forms.org_id, entry_forms.entry_form_id, entry_forms.approve_status, entry_forms.application_date, 
		entry_forms.completion_date, entry_forms.action_date, entry_forms.narrative, 
		entry_forms.answer, entry_forms.workflow_table_id, entry_forms.details
	FROM entry_forms INNER JOIN entitys ON entry_forms.entity_id = entitys.entity_id
		INNER JOIN forms ON entry_forms.form_id = forms.form_id;

----- Do a backend approve
CREATE OR REPLACE FUNCTION upd_qapprove(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS VARCHAR(250) AS $$
DECLARE
	myrec 			RECORD;
	myqrec 			RECORD;
	ttb 			RECORD;
	fnar 			RECORD;
	courserec 		RECORD;
	placerec 		RECORD;
	prererec 		RECORD;
	studentrec 		RECORD;
	mystr 			varchar(250);
	myrepeatapprove	varchar(12);
	mydegreeid 		int;
	myoverload 		boolean;
	myprobation 	boolean;
	mysabathclass	boolean;
	v_last_reg		boolean;
	myfeesline 		real;
BEGIN

	SELECT studentid, studentdegreeid,
		qstudentid, finalised, finaceapproval, totalfees, finalbalance, gpa, hours, quarterid, quarter, feesline, 
		resline, offcampus, residenceoffcampus, overloadapproval,
		degreelevelid, getcummcredit(studentdegreeid, quarterid) as cummcredit, 
		getcummgpa(studentdegreeid, quarterid) as cummgpa 
		INTO myrec
	FROM studentquarterview
	WHERE (qstudentid = $1::integer);
	
	mydegreeid := myrec.studentdegreeid;

	SELECT studentdegrees.sublevelid, students.fullbursary, students.seeregistrar, students.onprobation, 
		students.details as probationdetail, students.gaddress, students.address 
		INTO studentrec
	FROM students INNER JOIN studentdegrees ON students.studentid = studentdegrees.studentid  
	WHERE (studentdegrees.studentdegreeid = mydegreeid);

	SELECT qstudents.roomnumber, qstudents.qresidenceid, qstudents.sabathclassid, qstudents.overloadapproval, 
		qstudents.overloadhours, qstudents.financenarrative, qstudents.firstinstalment, 
		qstudents.firstdate, qstudents.secondinstalment, qstudents.seconddate, qstudents.registrarapproval, 
		qstudents.approve_late_fee, qstudents.late_fee_date,
		charges.last_reg_date, charges.charge_feesline, charges.charge_resline,
		sublevels.max_credits
		INTO myqrec
	FROM qstudents INNER JOIN charges ON qstudents.charge_id = charges.charge_id
		INNER JOIN sublevels ON charges.sublevelid = sublevels.sublevelid 
	WHERE qstudents.qstudentid = myrec.qstudentid;

	SELECT courseid, coursetitle INTO courserec
	FROM selcourseview WHERE (qstudentid = myrec.qstudentid) AND (maxclass < qcoursestudents);

	SELECT courseid, coursetitle, placementpassed, prereqpassed INTO prererec
	FROM selectedgradeview 
	WHERE (qstudentid = myrec.qstudentid) AND ((prereqpassed = false) OR (placementpassed = false));

	myoverload := getoverload(myqrec.max_credits, myrec.hours, myrec.cummgpa, myrec.cummcredit, myqrec.overloadapproval, myqrec.overloadhours);

	SELECT coursetitle INTO ttb 
	FROM studenttimetableview WHERE (qstudentid=myrec.qstudentid)
	AND (gettimecount(qstudentid, starttime, endtime, cmonday, ctuesday, cwednesday, cthursday, cfriday, csaturday, csunday) >1);

	myrepeatapprove := getrepeatapprove(myrec.qstudentid);

	IF (myrec.offcampus = TRUE) THEN
		IF(myqrec.charge_feesline is not null)THEN
			myfeesline := myrec.totalfees * (100 - myqrec.charge_feesline) / 100;
		ELSE
			myfeesline := myrec.totalfees * (100 - myrec.feesline) /100;
		END IF;
		mysabathclass := false;
	ELSE
		IF(myqrec.charge_resline is not null)THEN
			myfeesline := myrec.totalfees * (100 - myrec.charge_resline) / 100;
		ELSE
			myfeesline := myrec.totalfees * (100 - myrec.resline) / 100;
		END IF;
		IF (myqrec.sabathclassid is null) THEN
			mysabathclass := true;
		ELSIF (myqrec.sabathclassid = 0) THEN
			mysabathclass := true;
		ELSE
			mysabathclass := false;
		END IF;
	END IF;
	
	myprobation := false;
	IF (myrec.cummgpa is not null) THEN
		IF (((myrec.degreelevelid = 'MAS') OR (upper(myrec.degreelevelid) = 'PHD')) AND (myrec.cummgpa < 2.99)) THEN
			myprobation := true;
		END IF;
		IF (myrec.cummgpa < 1.99) THEN
			myprobation := true;
		END IF;
	END IF;
	IF (myqrec.registrarapproval = true) THEN
		myprobation := false;
	END IF;

	v_last_reg := false;
	IF(myqrec.last_reg_date <= current_date) THEN
		IF(myqrec.approve_late_fee = false)THEN
			v_last_reg := true;
		ELSIF((current_date - myqrec.late_fee_date) > 14)THEN
			v_last_reg := true;
		END IF;
	END IF;

	mystr := '';
	IF (studentrec.onprobation = true) THEN
		mystr := 'Probation issue to be resolved first before approval ';
		IF(studentrec.probationdetail != null) THEN
			mystr := mystr || ' ' || studentrec.probationdetail;
		END IF;
	ELSIF (studentrec.seeregistrar = true) THEN
		mystr := 'Probation issue to be resolved first before approval ';
		IF(studentrec.probationdetail != null) THEN
			mystr := mystr || ' ' || studentrec.probationdetail;
		END IF;
	ELSIF (ttb.coursetitle IS NOT NULL) THEN
		mystr := 'You have an timetable clashing for ' || ttb.coursetitle;
	ELSIF (courserec.courseid IS NOT NULL) THEN
		mystr := 'The class ' || courserec.courseid || ', ' || courserec.coursetitle || ' is full';
	ELSIF (prererec.courseid IS NOT NULL) THEN
		mystr := 'You need to complete the prerequisites or placement for course , ' || prererec.courseid || ', ' || prererec.coursetitle;
	ELSIF (getprobation(myrec.quarter, myrec.cummgpa, myrec.hours) = true) THEN
		mystr := 'See your major adviser for courses you need to pick, get financial approval and then visit records office for approval ';
	ELSIF (myoverload = true) THEN
		mystr := 'You have an overload';
	ELSIF (myrec.offcampus = false) and (myrec.residenceoffcampus = true) THEN
		mystr := 'You have no clearence to be off campus';
	ELSIF (myrec.finaceapproval = false) THEN
		mystr := 'Your need finance approved before final approval';
	ELSE
		UPDATE qstudents SET approved = true, sys_audit_trail_id = $4::int
		WHERE qstudentid = myrec.qstudentid;
		mystr := 'You have successful approved the student';
	END IF;

    RETURN mystr;
END;
$$ LANGUAGE plpgsql;

