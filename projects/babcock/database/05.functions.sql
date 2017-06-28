CREATE OR REPLACE FUNCTION getexamtimecount(integer, date, time, time) RETURNS bigint AS $$
	SELECT count(qgradeid) FROM qexamtimetableview
	WHERE (qstudentid = $1) AND (examdate = $2) AND (((starttime, endtime) OVERLAPS ($3, $4))=true);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getstudentdegreeid(varchar(12)) RETURNS integer AS $$
    SELECT max(studentdegreeid) FROM studentdegrees WHERE (studentid=$1) AND (completed = false);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getqstudentid(varchar(12)) RETURNS int AS $$
	SELECT max(qstudents.qstudentid) 
	FROM (studentdegrees INNER JOIN qstudents ON studentdegrees.studentdegreeid = qstudents.studentdegreeid)
		INNER JOIN quarters ON (qstudents.quarterid = quarters.quarterid) AND (qstudents.org_id = quarters.org_id)
	WHERE (studentdegrees.studentid = $1) AND (quarters.active = true);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getstudentid(varchar(12)) RETURNS varchar(12) AS $$
    SELECT max(studentid) FROM students WHERE (studentid = $1);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getstudylevel(int) RETURNS int AS $$
	SELECT max(studylevel) 
	FROM qstudents
	WHERE (studentdegreeid = $1) AND (approved = true);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_qresidentid(varchar(12), varchar(12)) RETURNS int AS $$
	SELECT max(qresidenceid) 
	FROM qresidences
	WHERE (residenceid = $1) AND (quarterid = $2);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getcurrqresidentid(varchar(12)) RETURNS int AS $$
	SELECT max(qresidenceid) 
	FROM qresidences INNER JOIN quarters ON qresidences.quarterid = quarters.quarterid 
	WHERE (residenceid = $1) AND (quarters.active = true);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION updBalances(varchar(50), varchar(50)) RETURNS varchar(50) AS $$
DECLARE
    myrecord RECORD;
	myqstudentid int;
BEGIN
	
	FOR myrecord IN SELECT sunimports.balance, students.studentid
		FROM (sunimports INNER JOIN students ON TRIM(UPPER(sunimports.accountnumber)) = TRIM(UPPER(students.accountnumber))) 
		WHERE sunimports.IsUploaded = False
	LOOP
		myqstudentid = getqstudentid(myrecord.studentid);

		IF (myqstudentid is not null) THEN
			UPDATE qstudents SET currbalance = myrecord.balance WHERE qstudentid = myqstudentid;
		ELSE
			UPDATE students SET currentbalance = myrecord.balance WHERE studentid = myrecord.studentid;
		END IF;
	END LOOP;
	
	INSERT INTO sys_audit_trail (user_id, user_ip, table_name, record_id, change_type, narrative)
	VALUES ($1, $2, 'qstudents', 'UPLOAD', 'UPLOAD', 'Charges Upload');

	DELETE FROM sunimports;
	
	RETURN 'Done';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION updBankPicked(varchar(50), varchar(50)) RETURNS varchar(50) AS $$
BEGIN	
	INSERT INTO banksuspence (entrydate, CustomerReference, TransactionAmount, Narrative, quarterid, accountnumber)
	SELECT CAST(vwbankfile.TransactionDate as timestamp), trim(vwbankfile.card_number), cast(vwbankfile.amount as real), 
		trim(vwbankfile.description), vwbankfile.quarterid, vwbankfile.accountnumber
	FROM vwbankfile LEFT JOIN banksuspence ON CAST(vwbankfile.TransactionDate as timestamp) = banksuspence.entrydate
	WHERE (banksuspence.entrydate is null);
	
	UPDATE studentpayments SET approved = true, phistoryid = 0, amount = CAST(vwbankfile.amount as real) FROM vwbankfile
	WHERE (trim(studentpayments.Narrative) = trim(vwbankfile.description)) AND (studentpayments.approved = false) 
		AND (abs(studentpayments.amount - CAST(vwbankfile.amount as real)) < 1000);
	
	UPDATE studentpayments SET approved = true, phistoryid = 0, amount = banksuspence.Transactionamount FROM banksuspence
	WHERE (trim(studentpayments.Narrative) = trim(banksuspence.TransComments)) 
		AND (studentpayments.approved = false) AND (abs(studentpayments.amount - banksuspence.Transactionamount) < 1000);
	
	DELETE FROM bankfile;
	
	UPDATE banksuspence SET Approved = true, Approveddate = now()
	FROM studentpayments
	WHERE (trim(banksuspence.narrative) = trim(studentpayments.narrative))
		AND (banksuspence.Approved = false) AND (studentpayments.Approved = true);
		
	UPDATE banksuspence SET Approved = true, Approveddate = now()
	FROM studentpayments
	WHERE (trim(banksuspence.TransComments) = trim(studentpayments.narrative))
		AND (banksuspence.Approved = false) AND (studentpayments.Approved = true);
		
	INSERT INTO sys_audit_trail (user_id, user_ip, table_name, record_id, change_type, narrative)
	VALUES ($1, $2, 'banksuspence', 'RECONSILIATION', 'ETRANZACT', 'Charges Bank Reconsiliation');
	
	RETURN 'Done';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_posting(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(50) AS $$
BEGIN
	INSERT INTO qposting_logs (sys_audit_trail_id, posted_type_id, qstudentid, posted_amount, narrative)
	SELECT CAST($4 as int), 1, qstudentid, fees, (majorid || ',' || studylevel || ',' || mealtype || ',' || residenceid)
	FROM vwqstudentcharges
	WHERE (quarterid = $1) AND (finaceapproval = true) AND (picked = false)
	ORDER BY qstudentid;

	UPDATE studentpayments SET Picked = true, Pickeddate  = now() FROM qstudents
	WHERE (studentpayments.qstudentid = qstudents.qstudentid) 
	AND (qstudents.quarterid = $1) AND (studentpayments.approved = true)
	AND (studentpayments.Picked = false);
	
	UPDATE qstudents SET Picked = true, Pickeddate  = now(), LRFPicked = true, LRFPickeddate  = now()
	WHERE (quarterid = $1) AND (finaceapproval = true) AND (picked = false);

	UPDATE scholarships SET posted = true, dateposted = now()
	WHERE (quarterid = $1) AND (approved = true) AND (posted = false);
	
	RETURN 'Done';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION delBankPicked(varchar(50), varchar(50)) RETURNS varchar(50) AS $$
BEGIN
	DELETE FROM Bankrecons;
	RETURN 'Done';
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
		UPDATE qstudents SET financeclosed = false WHERE qstudentid = myrec.qstudentid;
		mystr := 'Your financial application has been opened for adjustments.';
	END IF;
		
	RETURN mystr;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION getchargedays(date, date) RETURNS integer AS $$
DECLARE
	cdays integer;
	mydays integer;
BEGIN
	cdays := 0;
	mydays := $2 - $1;
	
	FOR i IN 0..mydays LOOP
		IF not ((date_part('DOW', ($1 + i)) = 0) OR (date_part('DOW', ($1 + i)) = 6)) THEN
			cdays := cdays + 1;
		END IF;
	END LOOP;
	
	RETURN cdays;
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
	ELSIF ((myrec.sublevelid = 'MEDI') AND (myquarter.q_length <> 12)) THEN
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

CREATE OR REPLACE FUNCTION updQStudent(varchar(12), varchar(12), varchar(12)) RETURNS VARCHAR(120) AS $$
DECLARE
	myrec 			RECORD;
	mystr 			varchar(120);
	mysel			varchar(32);
	mycurrqs 		int;
	nc_res_id		int;
BEGIN
	mycurrqs := getqstudentid($2);
	mysel := $1;
	
	SELECT qstudentid, financeclosed, finaceapproval, mealtype, mealticket, quarterid, org_id INTO myrec
	FROM qstudents WHERE (qstudentid = mycurrqs);

	SELECT qresidences.qresidenceid INTO nc_res_id
	FROM residences INNER JOIN qresidences ON residences.residenceid = qresidences.residenceid
	WHERE (qresidences.quarterid = myrec.quarterid) AND (residences.offcampus = true);

	IF (myrec.qstudentid is null) THEN
		RAISE EXCEPTION 'Register for the semester first';
	ELSIF (myrec.financeclosed = true) OR (myrec.finaceapproval = true) THEN
		RAISE EXCEPTION 'You cannot make changes after submiting your payment unless you apply on the post for it to be opened by finance.';
	ELSIF (myrec.mealticket > 0) THEN
		RAISE EXCEPTION 'You cannot not change meal selection after getting meal ticket.';
	ELSIF (mysel = '1') THEN
		IF(myrec.org_id = 2)THEN
			UPDATE qstudents SET offcampus = true, premiumhall = false, mealtype = 'NONE', qresidenceid = nc_res_id, studentdeanapproval = true
			WHERE (qstudentid = mycurrqs);
		ELSE
			UPDATE qstudents SET offcampus = true, premiumhall = false, mealtype = 'NONE', qresidenceid = nc_res_id
			WHERE (qstudentid = mycurrqs);
		END IF;
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
		UPDATE qstudents SET paymenttype = 4, offcampus = false, mealtype = 'BLS', qresidenceid = get_qresidentid('NA', myrec.quarterid)
		WHERE (qstudentid = mycurrqs);
		mystr := 'Applied for acceptance fee.';
	ELSE
		RAISE EXCEPTION 'Make Proper selection';
	END IF;

    RETURN mystr;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION getcoursehours(int) RETURNS float AS $$
	SELECT courses.credithours
	FROM courses INNER JOIN qcourses ON courses.courseid = qcourses.courseid
	WHERE (qcourseid = $1);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getcoursecredits(int) RETURNS float AS $$
	SELECT (CASE courses.nogpa WHEN true THEN 0 ELSE courses.credithours END)
	FROM courses INNER JOIN qcourses ON courses.courseid = qcourses.courseid
	WHERE (qcourseid = $1);
$$ LANGUAGE SQL;

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

CREATE OR REPLACE FUNCTION dropQCourse(varchar(12), varchar(12), varchar(12)) RETURNS VARCHAR(50) AS $$
DECLARE
	myrec 			RECORD;
	mystr 			VARCHAR(50);
	v_grade_id		varchar(2);
	mycurrqs 		int;
BEGIN
	mycurrqs := getqstudentid($2);

	SELECT qstudentid, finalised INTO myrec
	FROM qstudents
	WHERE (qstudentid = mycurrqs);

	SELECT gradeid INTO v_grade_id
	FROM qgrades WHERE qgradeid = CAST($1 as int);

	IF (myrec.qstudentid IS NULL) THEN
		RAISE EXCEPTION 'Please register for Semester and select residence first.';
	ELSIF (myrec.finalised = true) THEN
		RAISE EXCEPTION 'You have closed the selection.';
	ELSIF (v_grade_id <> 'NG') THEN
		RAISE EXCEPTION 'You can only drop a course that has no grade.';
	ELSE
		UPDATE qgrades SET askdrop = true, askdropdate = current_timestamp WHERE qgradeid = CAST($1 as int);
		UPDATE qgrades SET dropped = true, dropdate = current_date WHERE qgradeid = CAST($1 as int);
		mystr := 'Course Dropped.';
	END IF;
	
    RETURN mystr;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION gettimecount(integer, time, time, boolean, boolean, boolean, boolean, boolean, boolean, boolean) RETURNS bigint AS $$
	SELECT count(qtimetableid) FROM studenttimetableview
	WHERE (qstudentid=$1) AND (((starttime, endtime) OVERLAPS ($2, $3))=true) 
	AND ((cmonday and $4) OR (ctuesday and $5) OR (cwednesday and $6) OR (cthursday and $7) OR (cfriday and $8) OR (csaturday and $9) OR (csunday and $10));
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION insQClose(varchar(12), varchar(12), varchar(12)) RETURNS VARCHAR(250) AS $$
DECLARE
	myrec 			RECORD;
	p_major			varchar(12);
	m_load			real;
	ml_load			real;
	ttb 			RECORD;
	courserec 		RECORD;
	placerec 		RECORD;
	prererec 		RECORD;
	studentrec 		RECORD;
	myquarter 		RECORD;
	myqrec 			RECORD;
	mystr 			VARCHAR(250);
	mydegreeid 		int;
	myoverload 		boolean;
	myfeesline 		integer;
	mymaxcredit 	real;
	mylatefees 		int;
	mynarrative 	varchar(120);
BEGIN

	SELECT studentid, studentdegreeid, qstudentid, finalised, finaceapproval, gpa, hours, 
		quarterid, quarter, mincredits, maxcredits, studylevel,
		offcampus, residenceoffcampus, overloadapproval, overloadhours, studentdeanapproval
		INTO myrec
	FROM studentquarterview
	WHERE (qstudentid = CAST($1 as int));

	mydegreeid := myrec.studentdegreeid;
	mymaxcredit := myrec.maxcredits;

	SELECT majors.majorid, majors.quarterload INTO p_major, m_load
	FROM (majors INNER JOIN studentmajors ON majors.majorid = studentmajors.majorid)
	WHERE (studentmajors.primarymajor = true) AND (studentmajors.studentdegreeid = mydegreeid);

	SELECT quarterload INTO ml_load
	FROM major_levels
	WHERE (majorid = p_major) AND (major_level = myrec.studylevel);
	
	IF (ml_load IS NOT NULL) THEN
		mymaxcredit := ml_load;
	ELSIF (m_load IS NOT NULL) THEN
		mymaxcredit := m_load;
	END IF;

	SELECT courseid, coursetitle INTO courserec
	FROM selcourseview WHERE (qstudentid = myrec.qstudentid) AND (maxclass < qcoursestudents);
	SELECT courseid, coursetitle, prereqpassed INTO prererec
	FROM selectedgradeview WHERE (qstudentid = myrec.qstudentid) AND (prereqpassed = false);
		
---	SELECT INTO placerec qcoursecheckpass.yeartaken, qcoursecheckpass.courseid, qcoursecheckpass.coursetitle
---	FROM qcoursecheckpass LEFT JOIN studentgradeview ON (qcoursecheckpass.studentid = studentgradeview.studentid)
---		AND (qcoursecheckpass.courseid = studentgradeview.courseid)
---	WHERE (qcoursecheckpass.elective = false) AND (qcoursecheckpass.coursepased = false)
---		AND (qcoursecheckpass.yeartaken <= ((myrec.studylevel/100)-1)) AND (qcoursecheckpass.studentid = $1)
---		AND ((studentgradeview.gradeid is null) OR (studentgradeview.gradeid <> 'NG'))
---	ORDER BY yeartaken, courseid;

	SELECT  coursetitle INTO ttb
	FROM studenttimetableview WHERE (qstudentid=myrec.qstudentid)
		AND (gettimecount(qstudentid, starttime, endtime, cmonday, ctuesday, cwednesday, cthursday, cfriday, csaturday, csunday) >1);


	SELECT qlatereg, qlastdrop, lateregistrationfee, getchargedays(qlatereg, current_date) as latedays,
		lateregistrationfee * getchargedays(qlatereg, current_date) as latefees,
		quarterid, substring(quarterid from 11 for 1) as quarter
	INTO myquarter 
	FROM quarters WHERE (active = true);

	mylatefees := 0;
	mynarrative := '';
	IF (myrec.qstudentid is not null) AND (myquarter.latefees > 0) THEN 
		mylatefees := myquarter.latefees;
		mynarrative := 'Late Registration fees charges for ' || CAST(myquarter.latedays as text) || ' days at a rate of ' || CAST(myquarter.lateregistrationfee as text) || ' Per day.';

		SELECT charges, lateFeePayment INTO myqrec
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
	ELSIF (myrec.finaceapproval = false) THEN
		RAISE EXCEPTION 'You need to have financial approval to proceed';
	ELSIF (ttb.coursetitle IS NOT NULL) THEN
		RAISE EXCEPTION 'You have an timetable clashing for % ', ttb.coursetitle;
	ELSIF (courserec.courseid IS NOT NULL) THEN
		RAISE EXCEPTION 'The class %, % is full ', courserec.courseid, courserec.coursetitle;
	ELSIF (prererec.courseid IS NOT NULL) THEN
		RAISE EXCEPTION 'You need to complete the prerequisites or placement for course % : %', prererec.courseid, prererec.coursetitle;
---	ELSIF (placerec.courseid IS NOT NULL) THEN
---		mystr := 'You need to take all lower level course first like ' || placerec.courseid || ', ' || placerec.coursetitle;
	ELSIF (myrec.hours < myrec.mincredits) AND (myrec.overloadapproval = false) THEN
		RAISE EXCEPTION 'You have an underload, the required minimum is % credits.', CAST(myrec.mincredits as text);
	ELSIF (myrec.hours < myrec.mincredits) AND (myrec.overloadapproval = true) AND (myrec.hours < myrec.overloadhours) THEN
		RAISE EXCEPTION 'You have an underload, you can only take the approved minimum of % ', CAST(myrec.overloadhours as text);
	ELSIF (myrec.hours > mymaxcredit) AND (myrec.overloadapproval = false) THEN
		RAISE EXCEPTION 'You have an overload, the required maximum is % ', CAST(mymaxcredit as text);
	ELSIF (myrec.hours > mymaxcredit) AND (myrec.overloadapproval = true) AND (myrec.hours > myrec.overloadhours) THEN
		RAISE EXCEPTION 'You have an overload, you can only take the approved maximum of % ', CAST(myrec.overloadhours as text);
	ELSIF (myrec.offcampus = true) AND (myrec.studentdeanapproval = false) THEN
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
		RAISE EXCEPTION 'Submit courses first';
	ELSIF (myrec.paymentamount > 1000) THEN
		RAISE EXCEPTION 'Clear all fees first before you can be financialy approved';
	ELSE
		mystr := 'You will get Financial approval';
	END IF;

    RETURN mystr;
END;
$$ LANGUAGE plpgsql;

-- update the person who finacially approved a student
CREATE OR REPLACE FUNCTION updqstudents() RETURNS trigger AS $$
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

	IF (OLD.ispartpayment = false) AND (NEW.ispartpayment = true) THEN
		INSERT INTO approvallist(qstudentid, approvedby, approvaltype, approvedate, clientip) 
		VALUES (NEW.qstudentid, v_user_id, 'Plan Payment', now(), v_user_ip);
	END IF;
	
	IF (OLD.finaceapproval = false) AND (NEW.finaceapproval = true) THEN
		INSERT INTO approvallist(qstudentid, approvedby, approvaltype, approvedate, clientip) 
		VALUES (NEW.qstudentid, v_user_id, 'Finance', now(), v_user_ip);
	END IF;

	IF (OLD.finaceapproval = true) AND (NEW.finaceapproval = false) THEN
		INSERT INTO approvallist(qstudentid, approvedby, approvaltype, approvedate, clientip) 
		VALUES (NEW.qstudentid, v_user_id, 'Finance Open', now(), v_user_ip);
	END IF;
	
	IF (OLD.studentdeanapproval = false) AND (NEW.studentdeanapproval = true) THEN
		INSERT INTO approvallist(qstudentid, approvedby, approvaltype, approvedate, clientip) 
		VALUES (NEW.qstudentid, v_user_id, 'Dean', now(), v_user_ip);
	END IF;
	
	IF (OLD.approved = false) AND (NEW.approved = true) THEN
		INSERT INTO approvallist(qstudentid, approvedby, approvaltype, approvedate, clientip) 
		VALUES (NEW.qstudentid, v_user_id, 'Registry', now(), v_user_ip);
	END IF;

	IF (OLD.finalised = true) AND (NEW.finalised = false) THEN
		UPDATE qstudents SET printed = false, approved = false, majorapproval = false 
		WHERE qstudentID = NEW.qstudentID;
	END IF;

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER updqstudents AFTER UPDATE ON qstudents
    FOR EACH ROW EXECUTE PROCEDURE updqstudents();
    

CREATE OR REPLACE FUNCTION updb_qstudents() RETURNS trigger AS $$
BEGIN

	IF(NEW.finaceapproval = true)THEN
		IF(NEW.studylevel is null) OR (OLD.studylevel <> NEW.studylevel)THEN
			RAISE EXCEPTION 'You cannot change study level after financial approval';
		END IF;

		IF(NEW.qresidenceid is null) OR (OLD.qresidenceid <> NEW.qresidenceid)THEN
			RAISE EXCEPTION 'You cannot change residence after financial approval';
		END IF;
		
		IF(NEW.sublevelid is null) OR (OLD.sublevelid <> NEW.sublevelid)THEN
			RAISE EXCEPTION 'You cannot change sub level after financial approval';
		END IF;
		
		IF(NEW.mealtype is null) OR (OLD.mealtype <> NEW.mealtype)THEN
			RAISE EXCEPTION 'You cannot change meal type after financial approval';
		END IF;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER updb_qstudents BEFORE UPDATE ON qstudents
    FOR EACH ROW EXECUTE PROCEDURE updb_qstudents();

-- update the date a course was withdrawn
CREATE OR REPLACE FUNCTION updqgrades() RETURNS trigger AS $$
DECLARE
	v_entity_id			integer;
	v_entity_name 		varchar(50);
	v_user_ip			varchar(50);
BEGIN
	IF (OLD.gradeid <> 'W') and (NEW.gradeid = 'W') THEN
		UPDATE qgrades SET withdrawdate = current_date WHERE qgradeID = NEW.qgradeID;
	END IF;

	IF (OLD.gradeid <> NEW.gradeid) THEN
		SELECT entitys.entity_id, entitys.entity_name, sys_audit_trail.user_ip INTO v_entity_id, v_entity_name, v_user_ip
		FROM sys_audit_trail INNER JOIN entitys ON trim(upper(sys_audit_trail.user_id)) = CAST(entitys.entity_id as varchar)
		WHERE (sys_audit_trail.sys_audit_trail_id = NEW.sys_audit_trail_id);

		IF(v_entity_id is null) THEN
			SELECT entitys.entity_id, entitys.entity_name, sys_audit_trail.user_ip INTO v_entity_id, v_entity_name, v_user_ip
			FROM sys_audit_trail INNER JOIN entitys ON trim(upper(sys_audit_trail.user_id)) = trim(upper(entitys.user_name))
			WHERE (sys_audit_trail.sys_audit_trail_id = NEW.sys_audit_trail_id);
		END IF;

		IF(v_user_ip is null) THEN v_user_ip := CAST(inet_client_addr() as varchar); END IF;

		INSERT INTO gradechangelist (qgradeid, changedby, entity_id, oldgrade, newgrade, changedate, clientip) 
		VALUES (NEW.qgradeid, v_entity_name, v_entity_id, OLD.gradeid, NEW.gradeid, now(), v_user_ip);
	END IF;

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER updqgrades AFTER UPDATE ON qgrades
    FOR EACH ROW EXECUTE PROCEDURE updqgrades();

-- insert qcoursemarks after adding qcourseitems
CREATE OR REPLACE FUNCTION updqcourseitems(varchar(12), varchar(12)) RETURNS varchar(240) AS $$
BEGIN
	INSERT INTO qcoursemarks (qgradeid, qcourseitemid)
	SELECT qgrades.qgradeid, qcourseitems.qcourseitemid
	FROM (qcourseitems INNER JOIN qgrades ON qcourseitems.qcourseid = qgrades.qcourseid)
		LEFT JOIN qcoursemarks ON (qgrades.qgradeid = qcoursemarks.qgradeid) AND (qcourseitems.qcourseitemid = qcoursemarks.qcourseitemid)
	WHERE (qcoursemarks.qcoursemarkid is null) AND (qgrades.qgradeid = CAST($2 as int));
	
	RETURN 'Student Marks Items Entered Correctly';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION updqcourseitems() RETURNS trigger AS $$
BEGIN
	INSERT INTO qcoursemarks (qgradeid, qcourseitemid)
	SELECT qgrades.qgradeid, NEW.qcourseitemid
	FROM qstudents INNER JOIN qgrades ON qstudents.qstudentid = qgrades.qstudentid
	WHERE (qstudents.approved = true) AND (qgrades.qcourseid = NEW.qcourseid);
	
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER updqcourseitems AFTER INSERT ON qcourseitems
    FOR EACH ROW EXECUTE PROCEDURE updqcourseitems();
	
CREATE OR REPLACE FUNCTION updqcourseitemmarks(varchar(12), varchar(12), varchar(12)) RETURNS varchar(240) AS $$
BEGIN
	UPDATE qgrades SET instructormarks = vwcourseitemmarks.netscore FROM vwcourseitemmarks
	WHERE (qgrades.qgradeid = vwcourseitemmarks.qgradeid) AND 
		(qgrades.qcourseid = CAST($1 as int));
	
	RETURN 'Student Marks Updated Correctly';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION updqcoursedepartment(varchar(12), varchar(12), varchar(12)) RETURNS varchar(240) AS $$
DECLARE
	myrec 		RECORD;
	myrecb		RECORD;
	mystr 		VARCHAR(120);
BEGIN
	mystr := null;

	SELECT qgrades.qgradeid, studentdegrees.studentid INTO myrec
	FROM qgrades INNER JOIN qstudents ON qgrades.qstudentid = qstudents.qstudentid
		INNER JOIN studentdegrees ON studentdegrees.studentdegreeid = qstudents.studentdegreeid
	WHERE (qgrades.instructormarks is null) AND (qgrades.qcourseid = CAST($1 as int))
		AND (qgrades.dropped = false) AND (qstudents.approved = true) AND (qstudents.finaceapproval = true);

	SELECT studentdegrees.studentid INTO myrecb
	FROM qgrades INNER JOIN qstudents ON qgrades.qstudentid = qstudents.qstudentid
		INNER JOIN studentdegrees ON studentdegrees.studentdegreeid = qstudents.studentdegreeid
	WHERE (qgrades.instructormarks > 100) AND (qgrades.qcourseid = CAST($1 as int))
		AND (qgrades.dropped = false) AND (qstudents.approved = true) AND (qstudents.finaceapproval = true);

	IF(myrec.qgradeid is not null)THEN
		RAISE EXCEPTION 'Ensure all scores are put for all students in your class % ', myrec.studentid;
	ELSIF(myrecb.studentid is not null)THEN
		RAISE EXCEPTION 'Ensure all scores are correct and below 100 % ', myrecb.studentid;
	ELSE
		UPDATE qgrades SET departmentmarks = instructormarks
		WHERE (qgrades.qcourseid = CAST($1 as int));
		
		UPDATE qcourses SET lecturesubmit = true, lsdate = now()
		WHERE (qcourseid = CAST($1 as int));

		mystr := 'Marks Submitted to the Department Correctly';
	END IF;
	
	RETURN mystr;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION openqcoursedepartment(varchar(12), varchar(12), varchar(12)) RETURNS varchar(240) AS $$
BEGIN
	UPDATE qcourses SET lecturesubmit = false
	WHERE (qcourseid = CAST($1 as int));
	
	RETURN 'Course opened for lecturer to correct';
END;
$$ LANGUAGE plpgsql;

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

CREATE OR REPLACE FUNCTION updprinted(varchar(12), varchar(12), varchar(12)) RETURNS void AS $$
	UPDATE qstudents SET printed = true WHERE qstudentid = CAST($3 as int);
$$ LANGUAGE SQL;

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


CREATE OR REPLACE FUNCTION selQRoom(varchar(12), varchar(12), varchar(12)) RETURNS VARCHAR(50) AS $$
DECLARE
	mystr VARCHAR(120);
	myrec RECORD;
	myqstud int;
	myroom int;
BEGIN
	myqstud := getqstudentid($1);
	myroom := CAST($2 AS integer);

	SELECT INTO myrec qstudentid, finalised FROM qstudents
	WHERE (qstudentid = myqstud);

	IF (myrec.qstudentid IS NULL) THEN
		mystr := 'Please register for the semester first.';
	ELSIF (myrec.finalised = true) THEN
		mystr := 'You have closed the selection.';
	ELSE
		UPDATE qstudents SET roomnumber = myroom WHERE qstudentid = myqstud;
		mystr := 'Room Selected';
	END IF;

	RETURN mystr; 
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION selQsabathclass(varchar(12), varchar(12), varchar(12)) RETURNS VARCHAR(50) AS $$
DECLARE
	mystr VARCHAR(120);
	myrec RECORD;
	myqstud int;
	myclass int;
BEGIN
	myqstud := getqstudentid($2);
	myclass := CAST($1 AS integer);

	SELECT INTO myrec qstudentid, finalised FROM qstudents
	WHERE (qstudentid = myqstud);

	IF (myrec.qstudentid IS NULL) THEN
		mystr := 'Please register for the semester first.';
	ELSIF (myrec.finalised = true) THEN
		mystr := 'You have closed the selection.';
	ELSE
		UPDATE qstudents SET sabathclassid = myclass, chaplainapproval = true WHERE qstudentid = myqstud;
		mystr := 'Sabath Class Selected';
	END IF;

	RETURN mystr; 
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION updsubmited(varchar(12), varchar(12), varchar(12)) RETURNS VARCHAR(50) AS $$
BEGIN
	UPDATE qcoursemarks SET submited = current_date WHERE qcoursemarkid = $1;
	RETURN 'Submmited';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION updatemajorapproval(varchar(12), int) RETURNS varchar AS $$
	UPDATE qstudents SET majorapproval = true WHERE qstudentid = $2;
	INSERT INTO approvallist(qstudentid, approvedby, approvaltype, approvedate) VALUES ($2, $1, 'Major', now());
	SELECT varchar 'Major Approval Done' as reply;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getcoremajor(int) RETURNS varchar(50) AS $$
    SELECT max(majors.majorname)
    FROM studentmajors INNER JOIN majors ON studentmajors.majorid = majors.majorid
    WHERE (studentmajors.studentdegreeid = $1) AND (studentmajors.primarymajor = true);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getaccqstudentid(varchar(25)) RETURNS int AS $$
	SELECT max(qstudents.qstudentid) 
	FROM (studentdegreeview INNER JOIN qstudents ON studentdegreeview.studentdegreeid = qstudents.studentdegreeid)
		INNER JOIN quarters ON qstudents.quarterid = quarters.quarterid
	WHERE (studentdegreeview.accountnumber=$1) AND (quarters.active = true);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION insTranscript(integer) RETURNS integer AS $$
	INSERT INTO transcriptprint (studentdegreeid) VALUES($1);
	SELECT 1;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getstudentdegreeid(varchar(12), varchar(12)) RETURNS integer AS $$
	SELECT MAX(qstudents.studentdegreeid)
	FROM studentdegrees INNER JOIN qstudents ON studentdegrees.studentdegreeid = qstudents.studentdegreeid
	WHERE (studentdegrees.studentid = $1) AND (qstudents.quarterid = $2);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION addacademicyear(varchar(12), int) RETURNS varchar(12) AS $$
	SELECT cast(substring($1 from 1 for 4) as int) + $2 || '/' || cast(substring($1 from 1 for 4) as int) + $2 + 1 || '.3';
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

-- update the course title from course titles
CREATE OR REPLACE FUNCTION getcoursetitle(varchar(12)) RETURNS varchar(50) AS $$
	SELECT MAX(coursetitle) FROM courses WHERE (courseid = $1);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION insQuarter() RETURNS trigger AS $$
BEGIN
	INSERT INTO qcourses (quarterid, instructorid, courseid, maxclass)
	SELECT NEW.quarterid, 0, courseid, 200
	FROM majorcontents
	WHERE CAST(quarterdone as varchar) = substring(NEW.quarterid from 11 for 1)
	GROUP BY courseid;

	INSERT INTO qresidences (quarterid, residenceid, charges, full_charges)
	SELECT NEW.quarterid, residenceid, defaultrate, defaultrate * 2
	FROM residences;

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER insQuarter AFTER INSERT ON quarters
    FOR EACH ROW EXECUTE PROCEDURE insQuarter();

CREATE OR REPLACE FUNCTION insqcourses() RETURNS trigger AS $$
BEGIN
	NEW.coursetitle := getcoursetitle(NEW.courseid);
	SELECT org_id INTO NEW.org_id
	FROM quarters WHERE (quarterid = NEW.quarterid);

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER inscourses BEFORE INSERT ON qcourses
    FOR EACH ROW EXECUTE PROCEDURE insqcourses();

CREATE OR REPLACE FUNCTION updqcourses() RETURNS trigger AS $$
BEGIN
	IF (OLD.courseid <> NEW.courseid) THEN
		NEW.coursetitle := getcoursetitle(NEW.courseid);
	END IF;
	SELECT org_id INTO NEW.org_id
	FROM quarters WHERE (quarterid = NEW.quarterid);

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER updcourses BEFORE UPDATE ON qcourses
    FOR EACH ROW EXECUTE PROCEDURE updqcourses();
	
-- update students email address
CREATE OR REPLACE FUNCTION insstudentname() RETURNS trigger AS $$
DECLARE
	v_entity_id			integer;
	v_guardian_id		integer;
BEGIN
	NEW.studentname := UPPER(NEW.surname)	|| ', ' || UPPER(NEW.firstname) || ' ' || UPPER(COALESCE(NEW.othernames, ''));
	NEW.accountnumber := trim(upper(NEW.accountnumber));
	NEW.emailuser := lower(NEW.surname) || lower(replace(NEW.studentid, '/', ''));
	NEW.studentid := trim(upper(NEW.studentid));
	
	SELECT entity_id INTO v_entity_id FROM entitys WHERE user_name = trim(NEW.studentid);
	SELECT entity_id INTO v_guardian_id FROM entitys WHERE user_name = trim('G' || NEW.studentid);

	IF((NEW.birthdate is null) OR (NEW.guardianname is null) OR (NEW.gaddress is null))THEN
		NEW.student_edit = 'allow';
	ELSIF(NEW.address is null) or (NEW.town is null) or (NEW.countrycodeid is null) or (NEW.stateid is null) THEN
		NEW.student_edit = 'allow';
	ELSIF((NEW.telno is null) or (NEW.mobile is null) or (NEW.email is null))THEN
		NEW.student_edit = 'allow';
	ELSE
		NEW.student_edit = 'none';
	END IF;
	
	IF(TG_OP = 'INSERT')THEN
		IF(NEW.firstpasswd is null)THEN
			NEW.firstpasswd := first_password();
		END IF;

		SELECT entity_id INTO v_entity_id FROM entitys WHERE user_name = NEW.studentid;
		IF(v_entity_id is null)THEN
			INSERT INTO entitys (org_id, entity_type_id, entity_name, user_name, 
				mail_user, primary_email, 
				function_role, first_password, entity_password)
			VALUES (NEW.org_id, 21, NEW.studentname, trim(NEW.studentid), 
				NEW.emailuser, NEW.emailuser || '@std.babcock.edu.ng', 
				'student', NEW.firstpasswd, md5(NEW.firstpasswd));
		END IF;
		
		IF(v_guardian_id is null)THEN
			INSERT INTO entitys (org_id, entity_type_id, entity_name, user_name, 
				mail_user, primary_email, 
				function_role, first_password, entity_password)
			VALUES (NEW.org_id, 22, COALESCE(NEW.guardianname, NEW.studentname), ('G' || trim(NEW.studentid)),
				NEW.emailuser, NEW.emailuser || '@std.babcock.edu.ng', 
				'student', NEW.firstpasswd, md5(NEW.firstpasswd));
		END IF;
	ELSIF(TG_OP = 'UPDATE')THEN
		UPDATE entitys SET entity_name = NEW.studentname, mail_user = NEW.emailuser, primary_email = NEW.emailuser || '@std.babcock.edu.ng'
		WHERE user_name = trim(NEW.studentid);
		
		IF (NEW.guardianname IS NOT NULL) THEN
			IF(v_guardian_id is null)THEN
				INSERT INTO entitys (org_id, entity_type_id, entity_name, user_name, 
					mail_user, primary_email, 
					function_role, first_password, entity_password)
				VALUES (NEW.org_id, 22, COALESCE(NEW.guardianname, NEW.studentname), ('G' || trim(NEW.studentid)), 
					NEW.emailuser, NEW.emailuser || '@std.babcock.edu.ng', 
					'student', NEW.firstpasswd, md5(NEW.firstpasswd));
			ELSE
				UPDATE entitys SET entity_name = NEW.guardianname
				WHERE user_name = ('G' || trim(NEW.studentid));
			END IF;
		END IF;
	END IF;

	IF(NEW.org_id = 2)THEN
		NEW.offcampus = true;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER insstudentname BEFORE INSERT OR UPDATE ON students
    FOR EACH ROW EXECUTE PROCEDURE insstudentname();

-- update students email address
CREATE OR REPLACE FUNCTION updstudentemail(varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	myrec RECORD;
	mystr VARCHAR(120);
BEGIN
	SELECT INTO myrec updstudentemail(firstname, surname) as newemail, emailuser
	FROM students
	WHERE (studentid = $1);
	
	IF (myrec.emailuser is not null) THEN
		mystr := 'There is already and email ' || myrec.emailuser || ' assigned';
	ELSE
		UPDATE students SET emailuser = myrec.newemail WHERE (studentid = $1);
		mystr := 'New email ' || myrec.newemail;
	END IF;
	
	RETURN mystr;
END;
$$ LANGUAGE plpgsql;

--- Finance payment
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
	FROM quarters 
	WHERE (active = true) and (org_id = myqrec.org_id);
	
	mylatefees := 0;
	mynarrative := '';
	IF (myquarter.latefees > 0) AND (myqrec.charges = 0) AND ((mystud.newstudent = false) OR (myquarter.quarter != '1')) THEN 
		mylatefees := myquarter.latefees;
		mynarrative := 'Late Registration fees charges for ' || CAST(myquarter.latedays as text) || ' days at a rate of ' || CAST(myquarter.lateregistrationfee as text) || ' Per day.';
	END IF;

	IF (mycurrqs is not null) THEN
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


-- Change a students ID Number
CREATE OR REPLACE FUNCTION deldupstudent(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	myrec RECORD;
	myreca RECORD;
	myrecb RECORD;
	myrecc RECORD;
	myqtr RECORD;
	newid VARCHAR(16);
	mystr VARCHAR(120);
BEGIN
	IF($2 is null) THEN 
		newid := $3 || substring($1 from 3 for 5);
	ELSE
		newid := $2;
	END IF;
	
	SELECT INTO myrec studentid, studentname FROM students WHERE (studentid = newid);
	SELECT INTO myreca studentdegreeid, studentid FROM studentdegrees WHERE (studentid = $2);
	SELECT INTO myrecb studentdegreeid, studentid FROM studentdegrees WHERE (studentid = $1);
	SELECT INTO myrecc a.studentdegreeid, a.quarterid FROM
	((SELECT studentdegreeid, quarterid FROM qstudents WHERE studentdegreeid = myreca.studentdegreeid)
	EXCEPT (SELECT studentdegreeid, quarterid FROM qstudents WHERE studentdegreeid = myrecb.studentdegreeid)) as a;
	
	IF ($1 = $2) THEN
		mystr := 'That the same ID no change';
	ELSIF (myrecc.quarterid IS NOT NULL) THEN
		mystr := 'Conflict in quarter ' || myrecc.quarterid;
	ELSIF (myreca.studentdegreeid IS NOT NULL) AND (myrecb.studentdegreeid IS NOT NULL) THEN
		UPDATE qstudents SET studentdegreeid = myreca.studentdegreeid WHERE studentdegreeid = myrecb.studentdegreeid;
		UPDATE studentrequests SET studentid = $2 WHERE studentid = $1;
		DELETE FROM studentmajors WHERE studentdegreeid = myrecb.studentdegreeid;
		DELETE FROM studentdegrees WHERE studentdegreeid = myrecb.studentdegreeid;
		DELETE FROM students WHERE studentid = $1;	
		mystr := 'Changes to ' || $2;
	ELSIF (myrec.studentid is not null) THEN
		UPDATE studentdegrees SET studentid = $2 WHERE studentid = $1;
		UPDATE studentrequests SET studentid = $2 WHERE studentid = $1;
		DELETE FROM students WHERE studentid = $1;
		mystr := 'Changes to ' || $2;
	ELSIF ($2 is null) THEN
		DELETE FROM studentdegrees WHERE studentid is null;
		UPDATE studentdegrees SET studentid = null WHERE studentid = $1;
		UPDATE studentrequests SET studentid = null WHERE studentid = $1;
		UPDATE sun_audits SET studentid = null WHERE studentid = $1;
		
		UPDATE students SET studentid = newid, newstudent = false  WHERE studentid = $1;
		UPDATE studentdegrees SET studentid = newid WHERE studentid is null;
		UPDATE studentrequests SET studentid = newid WHERE studentid is null;
		UPDATE sun_audits SET studentid = newid WHERE studentid = null;
		UPDATE entitys SET user_name = newid WHERE user_name = $1;
		mystr := 'Changes to ' || newid;
	ELSIF ($2 is not null) AND (newid is not null) THEN
		DELETE FROM studentdegrees WHERE studentid is null;
		UPDATE studentdegrees SET studentid = null WHERE studentid = $1;
		UPDATE studentrequests SET studentid = null WHERE studentid = $1;
		UPDATE sun_audits SET studentid = null WHERE studentid = $1;
		
		UPDATE students SET studentid = newid, newstudent = false  WHERE studentid = $1;
		UPDATE studentdegrees SET studentid = newid WHERE studentid is null;
		UPDATE studentrequests SET studentid = newid WHERE studentid is null;
		UPDATE sun_audits SET studentid = newid WHERE studentid = null;
		UPDATE entitys SET user_name = newid WHERE user_name = $1;
		mystr := 'Changes to ' || newid;
	END IF;
	
	RETURN mystr;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION CloseQuarter(varchar(12)) RETURNS varchar(50) AS $$
	UPDATE qcourses SET approved = true WHERE (quarterid = $1);
	
	SELECT text 'Done' AS mylabel;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION OpenQuarter(varchar(12)) RETURNS varchar(50) AS $$
	UPDATE qcourses SET approved = false WHERE (quarterid = $1);
	
	SELECT text 'Done' AS mylabel;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION Matriculate(varchar(12)) RETURNS varchar(50) AS $$
	SELECT deldupstudent(studentid, null) FROM students
	WHERE (newstudent = true) AND (matriculate = true);
	
	SELECT text 'Done' AS mylabel;
$$ LANGUAGE SQL;

-- update the transaction ID
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
		ELSE
			IF(OLD.amount <> NEW.amount)THEN
				new.old_amount := NEW.amount;
			END IF;
		END IF;
	END IF;

	IF (reca.schoolid = 'COEN') THEN
		NEW.terminalid = '7000000089';
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

CREATE OR REPLACE FUNCTION updQPayment(varchar(12), varchar(12), varchar(12)) RETURNS VARCHAR(120) AS $$
DECLARE
	transid integer;
	oldtransid integer;
BEGIN
	transid := nextval('studentpayments_studentpaymentid_seq');
	oldtransid := CAST($1 as integer);
	
	INSERT INTO paymentracks (studentpaymentid, oldtransactionid)
	VALUES (transid, oldtransid);

	UPDATE studentpayments SET studentpaymentid = transid
	WHERE studentpaymentid = oldtransid;

	RETURN 'Update Transaction to new ID ' || CAST(transid as varchar);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION applyCourseOpen(varchar(12), varchar(12), varchar(12)) RETURNS varchar(240) AS $$
DECLARE
	myrec 		RECORD;
	v_org_id	integer;
	mystr 		varchar(120);
BEGIN
	SELECT INTO myrec gradeopeningid, hodapproval, hodreject, deanapproval, deanreject, regapproval, regreject
	FROM gradeopening 
	WHERE (qcourseid = CAST($1 AS int)) AND (hodreject = false) AND (deanapproval = false) AND (regreject = false);
	
	SELECT org_id INTO v_org_id
	FROM qcourses
	WHERE (qcourseid = CAST($1 AS int));

	IF (myrec.gradeopeningid is null) THEN
		INSERT INTO gradeopening (qcourseid, org_id) VALUES (CAST($1 AS int), v_org_id);
		mystr := 'Opening of course for grading has been summited to the HOD';
	ELSIF (myrec.regapproval = true) THEN
		mystr := 'Your application has been approved.';
	ELSE
		mystr := 'Another application exists check on status';
	END IF;

	RETURN mystr;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION approveCourseOpen(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(240) AS $$
DECLARE
	mystr VARCHAR(120);
BEGIN

	IF ($4 = '1') THEN
		IF($3 = 'Approve') THEN
			UPDATE gradeopening SET hodapproval = true, hoddate = now(), hodid = $2
			WHERE gradeopeningid = (CAST($1 AS int));
			mystr := 'Opening of course for grading Approved by HOD';
		ELSE
			UPDATE gradeopening SET hodreject = true, hoddate = now(), hodid = $2
			WHERE gradeopeningid = (CAST($1 AS int));
			mystr := 'Opening of course for grading Rejected by HOD';
		END IF;
	END IF;
	IF ($4 = '2') THEN
		IF($3 = 'Approve') THEN
			UPDATE gradeopening SET deanapproval = true, deandate = now(), deanid = $2
			WHERE gradeopeningid = (CAST($1 AS int));
			mystr := 'Opening of course for grading Approved by Dean';
		ELSE
			UPDATE gradeopening SET deanreject = true, deandate = now(), deanid = $2
			WHERE gradeopeningid = (CAST($1 AS int));
			mystr := 'Opening of course for grading Rejected by Dean';
		END IF;
	END IF;

	RETURN mystr;
END;
$$ LANGUAGE plpgsql;	

CREATE OR REPLACE FUNCTION updgradeopening() RETURNS trigger AS $$
BEGIN
	IF (OLD.regapproval = false) AND (NEW.regapproval = true) THEN
		NEW.regreject := false;
		NEW.regdate := now();

		UPDATE qcourses SET lecturesubmit = false, departmentsubmit	= false, facultysubmit = false
		WHERE qcourseid = NEW.qcourseid;
	ELSIF (OLD.regreject = false) AND (NEW.regreject = true) THEN
		NEW.regapproval := false;
		NEW.regdate := now();

	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER updgradeopening BEFORE UPDATE ON gradeopening
    FOR EACH ROW EXECUTE PROCEDURE updgradeopening();

CREATE OR REPLACE FUNCTION getOutstanding(int) RETURNS text AS $$
DECLARE
    myrec RECORD;
	mycourses text;
BEGIN
	mycourses := '';
	FOR myrec IN 
		SELECT vwchecklist.courseid, vwchecklist.credithours
		FROM vwchecklist LEFT JOIN vwqgrades 
			ON (vwchecklist.courseid = vwqgrades.courseid) AND (vwchecklist.studentdegreeid = vwqgrades.studentdegreeid)
		WHERE (vwchecklist.studentdegreeid = $1)
			AND ((vwqgrades.gradeid is null) OR (vwqgrades.gradeweight < vwchecklist.gradeweight))
			AND (vwchecklist.elective = false)
		ORDER BY vwchecklist.yeartaken, vwchecklist.courseid 
	LOOP
		IF (mycourses != '') THEN
			mycourses := mycourses || ', ';
		END IF;
		mycourses := mycourses || myrec.courseid || ' (' || trim(to_char(myrec.credithours, '999')) || ')';
	END LOOP;

    RETURN mycourses;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION merge_student(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	myreca RECORD;
	myrecb RECORD;
	mystr VARCHAR(120);
BEGIN
	SELECT studentdegreeid INTO myreca
	FROM studentdegrees WHERE (studentid = $1);
	SELECT studentdegreeid INTO myrecb
	FROM studentdegrees WHERE (studentid = $2);
	
	IF ($1 = $2) THEN
		mystr := 'That the same ID no change';
	ELSIF (myreca.studentdegreeid IS NOT NULL) AND (myrecb.studentdegreeid IS NOT NULL) THEN
		UPDATE studentpayments set qstudentid = b.qstudentid 
		FROM qstudents as a, qstudents as b 
		WHERE (a.studentdegreeid = myreca.studentdegreeid) AND (a.approved = true)
		AND (b.studentdegreeid = myrecb.studentdegreeid) AND (a.quarterid = b.quarterid)
		AND (studentpayments.qstudentid = a.qstudentid);

		DELETE FROM gradechangelist USING studentgradeview
		WHERE (gradechangelist.qgradeid = studentgradeview.qgradeid) AND (studentgradeview.studentdegreeid = myreca.studentdegreeid);
		DELETE FROM studentpayments USING qstudents 
		WHERE (studentpayments.qstudentid = qstudents.qstudentid) AND (qstudents.studentdegreeid = myreca.studentdegreeid)
			AND (studentpayments.approved = false);
		DELETE FROM approvallist USING qstudents 
		WHERE (approvallist.qstudentid = qstudents.qstudentid) AND (qstudents.studentdegreeid = myreca.studentdegreeid);
		DELETE FROM qgrades USING qstudents 
		WHERE (qgrades.qstudentid = qstudents.qstudentid) AND (qstudents.approved = false)
		AND (qstudents.studentdegreeid = myreca.studentdegreeid);
		DELETE FROM qstudents WHERE (approved = false) AND (studentdegreeid = myreca.studentdegreeid)
			AND (qstudentid NOT IN (SELECT qstudentid FROM studentpayments 
				WHERE (studentpayments.qstudentid = qstudents.qstudentid) AND (studentpayments.approved = true)));

		DELETE FROM gradechangelist USING studentgradeview
		WHERE (gradechangelist.qgradeid = studentgradeview.qgradeid) AND (studentgradeview.studentdegreeid = myrecb.studentdegreeid)
			AND (studentgradeview.approved = false);
		DELETE FROM studentpayments USING qstudents 
		WHERE (studentpayments.qstudentid = qstudents.qstudentid) AND (qstudents.studentdegreeid = myrecb.studentdegreeid)
			AND (studentpayments.approved = false);
		DELETE FROM approvallist USING qstudents 
		WHERE (approvallist.qstudentid = qstudents.qstudentid) AND (qstudents.approved = false)
		AND (qstudents.studentdegreeid = myrecb.studentdegreeid);
		DELETE FROM qgrades USING qstudents 
		WHERE (qgrades.qstudentid = qstudents.qstudentid) AND (qstudents.approved = false)
		AND (qstudents.studentdegreeid = myrecb.studentdegreeid);
		DELETE FROM qstudents WHERE (approved = false) AND (studentdegreeid = myrecb.studentdegreeid)
			AND (qstudentid NOT IN (SELECT qstudentid FROM studentpayments 
				WHERE (studentpayments.qstudentid = qstudents.qstudentid) AND (studentpayments.approved = true)));

		UPDATE qstudents SET studentdegreeid = myrecb.studentdegreeid 
		WHERE (studentdegreeid = myreca.studentdegreeid)
		AND (quarterid IN (SELECT quarterid FROM ((SELECT quarterid FROM qstudents 
			WHERE (studentdegreeid = myreca.studentdegreeid))
			EXCEPT
			(SELECT quarterid FROM qstudents 
			WHERE (studentdegreeid = myrecb.studentdegreeid))) as a));

		UPDATE qgrades set qstudentid = b.qstudentid 
		FROM qstudents as a, qstudents as b 
		WHERE (a.studentdegreeid = myreca.studentdegreeid) AND (a.approved = true)
		AND (b.studentdegreeid = myrecb.studentdegreeid) AND (a.quarterid = b.quarterid)
		AND (qgrades.qstudentid = a.qstudentid);

		UPDATE studentrequests SET studentid = $2 WHERE studentid = $1;

		DELETE FROM qstudents WHERE studentdegreeid = myreca.studentdegreeid;
		DELETE FROM studentmajors WHERE studentdegreeid = myreca.studentdegreeid;
		DELETE FROM studentdegrees WHERE studentdegreeid = myreca.studentdegreeid;
		DELETE FROM students WHERE studentid = $1;
		mystr := 'Merged to old ID ' || $2;
	ELSIF (myreca.studentdegreeid is null) THEN
		mystr := 'Old student ID not found.';
	ELSIF (myrecb.studentdegreeid is null) THEN
		DELETE FROM studentdegrees WHERE studentid is null;
		UPDATE studentdegrees SET studentid = null WHERE studentid = $1;
		UPDATE studentrequests SET studentid = null WHERE studentid = $1;
		UPDATE students SET studentid = $2 WHERE studentid = $1;
		UPDATE studentdegrees SET studentid = $2 WHERE studentid is null;
		UPDATE studentrequests SET studentid = $2 WHERE studentid is null;
		mystr := 'Changed to new ID ' || $2;
	END IF;
	
	RETURN mystr;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION del_student(varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	myreca RECORD;
	mystr VARCHAR(120);
BEGIN
	SELECT studentdegreeid INTO myreca
	FROM studentdegrees WHERE (studentid = $1);
	
	IF (myreca.studentdegreeid IS NOT NULL) THEN
		DELETE FROM gradechangelist USING studentgradeview
		WHERE (gradechangelist.qgradeid = studentgradeview.qgradeid) AND (studentgradeview.studentdegreeid = myreca.studentdegreeid);

		DELETE FROM studentpayments USING qstudents 
		WHERE (studentpayments.qstudentid = qstudents.qstudentid) AND (qstudents.studentdegreeid = myreca.studentdegreeid);

		DELETE FROM approvallist USING qstudents 
		WHERE (approvallist.qstudentid = qstudents.qstudentid) AND (qstudents.studentdegreeid = myreca.studentdegreeid);

		DELETE FROM qgrades USING qstudents 
		WHERE (qgrades.qstudentid = qstudents.qstudentid) AND (qstudents.studentdegreeid = myreca.studentdegreeid);

		DELETE FROM qstudents WHERE studentdegreeid = myreca.studentdegreeid;
		DELETE FROM studentmajors WHERE studentdegreeid = myreca.studentdegreeid;
		DELETE FROM studentdegrees WHERE studentdegreeid = myreca.studentdegreeid;
		DELETE FROM studentrequests WHERE studentid = $1;
		DELETE FROM students WHERE studentid = $1;
		mystr := 'Student ID deleted';
	ELSE
		mystr := 'Student ID not found.';
	END IF;
	
	RETURN mystr;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION getstudentpaymentid(varchar(12), varchar(25), real) RETURNS int AS $$
	SELECT min(studentpayments.studentpaymentid)
	FROM (qstudentview INNER JOIN studentpayments ON qstudentview.qstudentid = studentpayments.qstudentid)
	WHERE (qstudentview.quarterid = $1) AND (qstudentview.accountnumber = $2) AND (studentpayments.amount = abs($3));
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getcurrcp(integer) RETURNS double precision AS $$
	SELECT sum(grades.gradeweight * qgrades.credit)  as currcp
	FROM qgrades INNER JOIN grades ON qgrades.gradeid = grades.gradeid
	WHERE (qgrades.qstudentid = $1)	AND (grades.gpacount = true) AND (qgrades.dropped = false) 
		AND (qgrades.repeated = false) AND (qgrades.gradeid <> 'W') AND (qgrades.gradeid <> 'AW');
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getcummcurrcp(integer, character varying) RETURNS double precision AS $$
	SELECT sum(grades.gradeweight * qgrades.credit)  as currcp
	FROM (qgrades INNER JOIN qstudents ON qgrades.qstudentid = qstudents.qstudentid)
		INNER JOIN grades ON qgrades.gradeid = grades.gradeid
	WHERE (qstudents.studentdegreeid = $1) AND (qstudents.quarterid <= $2) AND (qgrades.dropped = false)
		AND (grades.gpacount = true) AND (qgrades.repeated = false) AND (qgrades.gradeid <> 'W') AND (qgrades.gradeid <> 'AW');
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION updaterepeats(int, varchar(12)) RETURNS varchar(50) AS $$
DECLARE
    myrec RECORD;
	pass boolean;
BEGIN
	pass := false;
	FOR myrec IN SELECT qgrades.qgradeid
		FROM ((qgrades INNER JOIN grades ON qgrades.gradeid = grades.gradeid)
			INNER JOIN qcourses ON qgrades.qcourseid = qcourses.qcourseid)
			INNER JOIN qstudents ON qgrades.qstudentid = qstudents.qstudentid 
		WHERE (qgrades.gradeid<>'W') AND (qgrades.gradeid<>'AW') AND (qgrades.gradeid<>'NG') AND (qgrades.dropped = false)
			AND (qstudents.approved = true) AND (qstudents.studentdegreeid = $1) AND (qcourses.courseid = $2)
		ORDER BY grades.gradeweight desc, qcourses.qcourseid
	LOOP
		IF (pass = true) THEN
			UPDATE qgrades SET repeated = true WHERE (qgradeid = myrec.qgradeid);
		ELSE
			UPDATE qgrades SET repeated = false WHERE (qgradeid = myrec.qgradeid);
		END IF;
		pass := true;
	END LOOP;

    RETURN 'Updated';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION getcurrcp(integer) RETURNS double precision AS $$
	SELECT sum(grades.gradeweight * qgrades.credit)  as currcp
	FROM qgrades INNER JOIN grades ON qgrades.gradeid = grades.gradeid
	WHERE (qgrades.qstudentid = $1)	AND (grades.gpacount = true) AND (qgrades.dropped = false) 
		AND (qgrades.repeated = false) AND (qgrades.gradeid <> 'W') AND (qgrades.gradeid <> 'AW');
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION ins_departments() RETURNS trigger AS $$
BEGIN
	SELECT org_id INTO NEW.org_id
	FROM schools
	WHERE (schoolid = NEW.schoolid);

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_departments AFTER INSERT OR UPDATE ON departments
  FOR EACH ROW EXECUTE PROCEDURE ins_departments();


CREATE OR REPLACE FUNCTION ins_studentdegrees() RETURNS trigger AS $$
BEGIN
	SELECT org_id INTO NEW.org_id
	FROM sublevels
	WHERE (sublevelid = NEW.sublevelid);

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_studentdegrees BEFORE INSERT OR UPDATE ON studentdegrees
  FOR EACH ROW EXECUTE PROCEDURE ins_studentdegrees();

CREATE OR REPLACE FUNCTION ins_studentmajors() RETURNS trigger AS $$
BEGIN
	SELECT org_id INTO NEW.org_id
	FROM majors
	WHERE (majorid = NEW.majorid);

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_studentmajors AFTER INSERT OR UPDATE ON studentmajors
  FOR EACH ROW EXECUTE PROCEDURE ins_studentmajors();

CREATE OR REPLACE FUNCTION del_studentmajors() RETURNS trigger AS $$
DECLARE
	v_qstudentid		integer;
BEGIN
	SELECT qstudentid INTO v_qstudentid
	FROM qstudents
	WHERE (studentdegreeid = OLD.studentdegreeid);

	IF(v_qstudentid is not null)THEN
		RAISE EXCEPTION 'You cannot delete a program for an existing student.';
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER del_studentmajors BEFORE DELETE ON studentmajors
  FOR EACH ROW EXECUTE PROCEDURE del_studentmajors();

CREATE OR REPLACE FUNCTION aft_studentdegrees() RETURNS trigger AS $$
DECLARE
	v_org_id		integer;
BEGIN

	IF(NEW.completed = false)THEN
		SELECT org_id INTO v_org_id
		FROM sublevels
		WHERE (sublevelid = NEW.sublevelid);

		UPDATE students SET org_id = v_org_id WHERE (studentid = NEW.studentid);
		UPDATE entitys SET org_id = v_org_id WHERE (user_name = NEW.studentid);
		
		UPDATE qstudents SET org_id = v_org_id, sublevelid = NEW.sublevelid 
		FROM quarters
		WHERE (qstudents.quarterid = quarters.quarterid) AND (studentdegreeid = NEW.studentdegreeid)
			AND (quarters.active = true);
	END IF;

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER aft_studentdegrees AFTER INSERT OR UPDATE ON studentdegrees
  FOR EACH ROW EXECUTE PROCEDURE aft_studentdegrees();

CREATE OR REPLACE FUNCTION ins_instructors() RETURNS trigger AS $$
BEGIN
	SELECT org_id INTO NEW.org_id
	FROM departments
	WHERE (departmentid = NEW.departmentid);

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_instructors BEFORE INSERT OR UPDATE ON instructors
  FOR EACH ROW EXECUTE PROCEDURE ins_instructors();

CREATE OR REPLACE FUNCTION aft_instructors() RETURNS trigger AS $$
DECLARE
	v_role		varchar(240);
BEGIN

	v_role := 'lecturer';
	IF(NEW.majoradvisor = true)THEN
		v_role := v_role || ',majoradvisor';
	END IF;
	IF(NEW.headofdepartment = true)THEN
		v_role := v_role || ',headofdepartment';
	END IF;
	IF(NEW.headoffaculty = true)THEN
			v_role := v_role || ',headoffaculty';
	END IF;

	IF(TG_OP = 'INSERT')THEN
		INSERT INTO entitys (org_id, entity_type_id, user_name, entity_name, Entity_Leader, Super_User, no_org, function_role, primary_email)
		VALUES (NEW.org_id, 23, NEW.instructorid, NEW.instructorname, false, false, false, NEW.email, v_role);
	ELSE
		UPDATE entitys SET function_role = v_role, org_id = NEW.org_id WHERE user_name = NEW.instructorid;
	END IF;

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER aft_instructors AFTER INSERT OR UPDATE ON instructors
  FOR EACH ROW EXECUTE PROCEDURE aft_instructors();

CREATE OR REPLACE FUNCTION get_school(varchar(16)) RETURNS varchar(16) AS $$
	SELECT departments.schoolid
	FROM instructors INNER JOIN departments ON instructors.departmentid = departments.departmentid
	WHERE (instructorid = $1);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_department(varchar(16)) RETURNS varchar(16) AS $$
	SELECT departmentid
	FROM instructors
	WHERE (instructorid = $1);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_course_quarter(varchar(16)) RETURNS varchar(16) AS $$
	SELECT quarterid
	FROM qcourses
	WHERE (qcourseid = CAST($1 as int));
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_student_quarter(varchar(16)) RETURNS varchar(16) AS $$
	SELECT quarterid
	FROM qstudents
	WHERE (qstudentid = getqstudentid($1));
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION upd_sun_balance(varchar(12), varchar(64), Float) RETURNS VARCHAR(120) AS $$
DECLARE
	srec RECORD;
	examBalance real;
	mystr VARCHAR(120);
BEGIN

	SELECT qstudents.qstudentid, qstudents.quarterid, qstudents.finaceapproval,  
			quarters.qlatereg, quarters.active INTO srec
	FROM studentdegrees INNER JOIN qstudents ON studentdegrees.studentdegreeid = qstudents.studentdegreeid
		INNER JOIN quarters ON qstudents.quarterid = quarters.quarterid
	WHERE (studentdegrees.completed = false) AND (studentdegrees.studentid = $1) AND (quarters.active = true);

	IF (srec.qstudentid is null) THEN
		UPDATE students SET balance_time = now(), currentbalance = $3
		WHERE (studentid = $1);

		INSERT INTO sun_audits (studentid, update_type, update_time, sun_balance, user_ip)
		VALUES ($1, 'student', now(), $3, $2);
	ELSIF (srec.active = true) AND (srec.finaceapproval = false) THEN
		UPDATE qstudents SET balance_time = now(), currbalance = $3
		WHERE (qstudentid = srec.qstudentid);

		INSERT INTO sun_audits (studentid, update_type, update_time, sun_balance, user_ip)
		VALUES ($1, 'balance', now(), $3, $2);
	END IF;

	mystr := 'Balance updated';

    RETURN mystr;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION change_password(varchar(12), varchar(32), varchar(32)) RETURNS varchar(120) AS $$
DECLARE
	old_password 	varchar(64);
	passchange 		varchar(120);
	entityID		integer;
BEGIN
	passchange := 'Password Error';
	entityID := CAST($1 AS INT);
	SELECT Entity_password INTO old_password
	FROM entitys WHERE (entity_id = entityID);

	IF ($2 = '0') THEN
		passchange := first_password();
		UPDATE entitys SET first_password = passchange, Entity_password = md5(passchange) WHERE (entity_id = entityID);
		passchange := 'Password Changed';
	ELSIF (old_password = md5($2)) THEN
		UPDATE entitys SET Entity_password = md5($3) WHERE (entity_id = entityID);
		passchange := 'Password Changed';
	ELSE
		passchange := 'Password Changing Error Ensure you have correct details';
	END IF;

	return passchange;
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


CREATE OR REPLACE FUNCTION open_registration(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(240) AS $$
DECLARE
	mystr VARCHAR(120);
BEGIN


	UPDATE qstudents SET finalised = false, printed = false WHERE (qstudentid = CAST($1 as integer));
	mystr := 'Registration opened';

	RETURN mystr;
END;
$$ LANGUAGE plpgsql;	


CREATE OR REPLACE FUNCTION ins_courses() RETURNS trigger AS $$
BEGIN
	SELECT org_id INTO NEW.org_id
	FROM degreelevels WHERE (degreelevelid = NEW.degreelevelid);

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_courses BEFORE INSERT OR UPDATE ON courses
  FOR EACH ROW EXECUTE PROCEDURE ins_courses();

CREATE OR REPLACE FUNCTION ins_majors() RETURNS trigger AS $$
BEGIN
	SELECT org_id INTO NEW.org_id
	FROM degreelevels WHERE (degreelevelid = NEW.degreelevelid);

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_majors BEFORE INSERT OR UPDATE ON majors
  FOR EACH ROW EXECUTE PROCEDURE ins_majors();

CREATE OR REPLACE FUNCTION ins_qresidences() RETURNS trigger AS $$
BEGIN
	SELECT org_id INTO NEW.org_id
	FROM quarters WHERE (quarterid = NEW.quarterid);

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_qresidences BEFORE INSERT OR UPDATE ON qresidences
  FOR EACH ROW EXECUTE PROCEDURE ins_qresidences();

CREATE OR REPLACE FUNCTION del_qgrades() RETURNS trigger AS $$
BEGIN
	RAISE EXCEPTION 'Cannot delete a grade.';
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER del_qgrades BEFORE DELETE ON qgrades
  FOR EACH ROW EXECUTE PROCEDURE del_qgrades();

CREATE OR REPLACE FUNCTION ins_qstudents() RETURNS trigger AS $$
BEGIN
	SELECT org_id, sublevelid INTO NEW.org_id, NEW.sublevelid
	FROM studentdegrees
	WHERE (studentdegreeid = NEW.studentdegreeid);

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_qstudents BEFORE INSERT
  ON qstudents FOR EACH ROW EXECUTE PROCEDURE ins_qstudents();

CREATE OR REPLACE FUNCTION ins_qgrades() RETURNS trigger AS $$
BEGIN
	SELECT org_id INTO NEW.org_id
	FROM qstudents
	WHERE (qstudentid = NEW.qstudentid);

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_qgrades BEFORE INSERT OR UPDATE
  ON qgrades FOR EACH ROW EXECUTE PROCEDURE ins_qgrades();

CREATE OR REPLACE FUNCTION ins_qorg_id() RETURNS trigger AS $$
BEGIN
	SELECT org_id INTO NEW.org_id
	FROM quarters
	WHERE (quarterid = NEW.quarterid);
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ins_sublevel_org_id() RETURNS trigger AS $$
BEGIN
	SELECT org_id INTO NEW.org_id
	FROM sublevels
	WHERE (sublevelid = NEW.sublevelid);
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_sublevel_org_id BEFORE INSERT OR UPDATE
  ON qcharges FOR EACH ROW EXECUTE PROCEDURE ins_sublevel_org_id();
CREATE TRIGGER ins_sublevel_org_id BEFORE INSERT OR UPDATE
  ON qmcharges FOR EACH ROW EXECUTE PROCEDURE ins_sublevel_org_id();
CREATE TRIGGER ins_sublevel_org_id BEFORE INSERT OR UPDATE
  ON qchargedefinations FOR EACH ROW EXECUTE PROCEDURE ins_sublevel_org_id();
CREATE TRIGGER ins_sublevel_org_id BEFORE INSERT OR UPDATE
  ON qmchargedefinations FOR EACH ROW EXECUTE PROCEDURE ins_sublevel_org_id();

CREATE OR REPLACE FUNCTION get_quarter_org(varchar(12)) RETURNS int AS $$
	SELECT org_id
	FROM quarters
	WHERE (quarterid = $1);
$$ LANGUAGE SQL;


CREATE OR REPLACE FUNCTION replace_quarter(varchar(12), varchar(12)) RETURNS varchar(50) AS $$
DECLARE
    myrec RECORD;
	pass boolean;
BEGIN

	DELETE FROM qresidences WHERE quarterid = $2;

	UPDATE qcalendar SET quarterid = $2 WHERE quarterid = $1; 
	UPDATE qresidences SET quarterid = $2 WHERE quarterid = $1; 
	UPDATE qcharges SET quarterid = $2 WHERE quarterid = $1; 
	UPDATE qmcharges SET quarterid = $2 WHERE quarterid = $1; 
	UPDATE qchargedefinations SET quarterid = $2 WHERE quarterid = $1; 
	UPDATE qmchargedefinations SET quarterid = $2 WHERE quarterid = $1; 
	UPDATE qstudents SET quarterid = $2 WHERE quarterid = $1; 
	UPDATE qcourses SET quarterid = $2 WHERE quarterid = $1; 
	
	DELETE FROM quarters WHERE quarterid = $1; 

    RETURN 'Updated';
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION replace_qstudent(int, int) RETURNS varchar(50) AS $$
BEGIN
	UPDATE qstudents SET studentdegreeid = $1 WHERE studentdegreeid = $2 and studylevel < 600;
	RETURN 'Updated';
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION process_payroll(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	rec 		RECORD;
	msg 		varchar(120);
BEGIN
	IF ($3 = '1') THEN

	
CREATE OR REPLACE FUNCTION generate_charges(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	v_year				integer;
	v_quarter			varchar(2);
	v_old_qid			varchar(12);

	msg 				varchar(120);
BEGIN

	msg := 'No Function selected';
	
	SELECT substring(quarters.quarterid from 1 for 4)::integer, 
		trim(substring(quarters.quarterid from 11 for 2)) INTO v_year, v_quarter
	FROM quarters
	WHERE quarterid = $1;
	
	v_old_qid := (v_year-1)::varchar(4) || '/' || v_year::varchar(4) || '.' || v_quarter;

	IF ($3 = '1') THEN
		INSERT INTO qresidences (quarterid, residenceid, org_id, residenceoption, charges, full_charges, active, details)
		SELECT $1, a.residenceid, a.org_id, a.residenceoption, a.charges, a.full_charges, a.active, a.details
		FROM qresidences a LEFT JOIN 
			(SELECT qresidenceid, residenceid FROM qresidences WHERE quarterid = $1) as b ON a.residenceid = b.residenceid
		WHERE (a.quarterid = v_old_qid) AND (b.qresidenceid is null);
		
		INSERT INTO qcharges(quarterid, degreelevelid, org_id, studylevel, fullfees, 
			fullmeal2fees, fullmeal3fees, fees, meal2fees, meal3fees, premiumhall, 
			minimalfees, firstinstalment, firstdate, secondinstalment, seconddate, narrative, sublevelid)
		SELECT $1, a.degreelevelid, a.org_id, a.studylevel, a.fullfees, 
			a.fullmeal2fees, a.fullmeal3fees, a.fees, a.meal2fees, a.meal3fees, a.premiumhall, 
			a.minimalfees, a.firstinstalment, a.firstdate, a.secondinstalment, a.seconddate, a.narrative, a.sublevelid
		FROM qcharges a LEFT JOIN 
			(SELECT qchargeid, degreelevelid, studylevel FROM qcharges WHERE quarterid = $1) b
		ON (a.degreelevelid = b.degreelevelid) AND (a.studylevel = b.studylevel)
		WHERE (a.quarterid = v_old_qid) AND (b.qchargeid is null);
		
		INSERT INTO qmcharges(quarterid, majorid, org_id, studylevel, charge, fullcharge, 
			meal2charge, meal3charge, phallcharge, narrative, sublevelid)
		SELECT $1, a.majorid, a.org_id, a.studylevel, a.charge, a.fullcharge, 
			a.meal2charge, a.meal3charge, a.phallcharge, a.narrative, a.sublevelid
		FROM qmcharges a LEFT JOIN 
			(SELECT qmchargeid, majorid, studylevel FROM qmcharges WHERE quarterid = $1) b
		ON (a.majorid = b.majorid) AND (a.studylevel = b.studylevel)
		WHERE (a.quarterid = v_old_qid) AND (b.qmchargeid is null);
		
		msg := 'Charges Generated';
	END IF;

	IF ($3 = '2') THEN
		INSERT INTO qchargedefinations(quarterid, chargetypeid, studylevel, amount, narrative, sublevelid, org_id)
		SELECT $1, a.chargetypeid, a.studylevel, a.amount, a.narrative, a.sublevelid, a.org_id
		FROM qchargedefinations a LEFT JOIN
			(SELECT qchargedefinationid, chargetypeid, studylevel FROM qchargedefinations WHERE quarterid = $1) b
		ON (a.chargetypeid = b.chargetypeid) AND (a.studylevel = b.studylevel)
		WHERE (a.quarterid = v_old_qid) AND (b.qchargedefinationid is null);
		
		INSERT INTO qmchargedefinations(quarterid, chargetypeid, majorid, org_id, studylevel, amount, narrative, sublevelid)
		SELECT $1, a.chargetypeid, a.majorid, a.org_id, a.studylevel, a.amount, a.narrative, a.sublevelid
		FROM qmchargedefinations a LEFT JOIN
			(SELECT qmchargedefinationid, chargetypeid, majorid, studylevel FROM qmchargedefinations WHERE quarterid = $1) b
		ON (a.chargetypeid = b.chargetypeid) AND (a.majorid = b.majorid) AND (a.studylevel = b.studylevel)
		WHERE (a.quarterid = v_old_qid) AND (b.qmchargedefinationid is null);
	
		msg := 'Charges Defination Generated';
	END IF;	

	RETURN msg;
END;
$$ LANGUAGE plpgsql;


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
  
  
  
