CREATE OR REPLACE FUNCTION insnewstudent(integer) RETURNS varchar(50) AS $$
DECLARE
	myrec RECORD;
	priadd RECORD;
	gudadd RECORD;
	idcount RECORD;
	myqtr RECORD;
	baseid VARCHAR(12);
	newid VARCHAR(12);
	fullname VARCHAR(50);
	genfirstpass VARCHAR(32);
	genstudentpass VARCHAR(32);
BEGIN
	SELECT INTO myrec departments.schoolid, registrations.denominationid, registrations.registrationid,
		registrations.lastname, registrations.middlename, registrations.firstname,
		registrations.sex, registrations.nationalityid, registrations.maritalstatus,
		registrations.birthdate, registrations.existingid, registrations.degreeid, registrations.sublevelid,
		registrations.majorid, registrations.premajor
	FROM (departments INNER JOIN majors ON departments.departmentid = majors.departmentid)
	INNER JOIN registrations ON majors.majorid = registrations.majorid
	WHERE (registrations.registrationid=$1);

	SELECT INTO priadd regcontacts.address, regcontacts.zipcode, regcontacts.town, regcontacts.countrycodeid,
		regcontacts.telephone, regcontacts.email
	FROM contacttypes INNER JOIN regcontacts ON contacttypes.contacttypeid = regcontacts.contacttypeid
	WHERE (contacttypes.primarycontact = true) AND (regcontacts.registrationid=$1);

	SELECT INTO gudadd regcontacts.regcontactname, regcontacts.address, regcontacts.zipcode, regcontacts.town,
		regcontacts.countrycodeid, regcontacts.telephone, regcontacts.email
	FROM regcontacts
	WHERE (regcontacts.guardiancontact = true) AND (regcontacts.registrationid=$1);

	SELECT INTO myqtr quarterid FROM quarters WHERE active = true;

	baseid := upper('S' || substring(trim(myrec.lastname) from 1 for 3) || substring(trim(myrec.firstname) from 1 for 2) || substring(myqtr.quarterid from 8 for 2) || substring(myqtr.quarterid from 11 for 1));

	SELECT INTO idcount count(studentid) as baseidcount
	FROM students
	WHERE substring(studentid from 1 for 9) = baseid;

	newid := baseid || (idcount.baseidcount + 1);

	IF (myrec.middlename IS NULL) THEN
		fullname := upper(trim(myrec.lastname)) || ', ' || upper(trim(myrec.firstname));
	ELSE
		fullname := upper(trim(myrec.lastname)) || ', ' || upper(trim(myrec.middlename)) || ' ' || upper(trim(myrec.firstname));
	END IF;
	
	genfirstpass := firstPasswd();
	genstudentpass := md5(genfirstpass);

	IF myrec.existingid IS NULL THEN
		INSERT INTO students (studentid, accountnumber, studentname, schoolid, denominationid, Sex, Nationality,
			MaritalStatus, birthdate, firstpass, studentpass, address, zipcode, town, countrycodeid, telno, email,
			guardianname, gaddress, gzipcode, gtown, gcountrycodeid, gtelno, gemail)
		VALUES (newid, newid, fullname, myrec.schoolid, myrec.denominationid, myrec.Sex, myrec.Nationalityid,
			myrec.MaritalStatus, myrec.birthdate, genfirstpass, genstudentpass,
			priadd.address, priadd.zipcode, priadd.town, priadd.countrycodeid, priadd.telephone, priadd.email,
			gudadd.regcontactname, gudadd.address, gudadd.zipcode, gudadd.town, gudadd.countrycodeid, gudadd.telephone, gudadd.email);

		INSERT INTO studentdegrees (degreeid, sublevelid, studentid, started, bulletingid)
		VALUES (myrec.degreeid,  myrec.sublevelid, newid, current_date, 0);

		INSERT INTO studentmajors (studentdegreeid, majorid, major, nondegree, premajor, primarymajor)
		VALUES (getstudentdegreeid(newid), myrec.majorid, true, false, myrec.premajor, true);

		UPDATE registrations SET existingid = newid, accepted=true, accepteddate=current_date, firstpass=genfirstpass  WHERE (registrations.registrationid=$1);
	END IF;

    RETURN newid;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION insstudentname() RETURNS trigger AS $$
DECLARE
	myrec RECORD;
	stdnum integer;
BEGIN	
	NEW.studentname := UPPER(NEW.surname)	|| ', ' || UPPER(NEW.firstname) || ' ' || UPPER(COALESCE(NEW.othernames, ''));

	IF (TG_OP = 'INSERT') AND (NEW.studentid is null) THEN
		SELECT max(cast(substring(studentid from 6 for 3) as int)) as stdno INTO myrec
		FROM students
		WHERE substring(studentid from 2 for 4) = to_char(current_timestamp, 'YYYY');

		if(myrec.stdno is null) then
			stdnum := 1;
		else
			stdnum := myrec.stdno + 1;
		end if;

		NEW.studentid := 'S' || to_char(current_timestamp, 'YYYY') || lpad(cast((stdnum) as varchar), 3, '0');
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER insstudentname BEFORE INSERT OR UPDATE ON students
    FOR EACH ROW EXECUTE PROCEDURE insstudentname();

CREATE OR REPLACE FUNCTION getfirstsessionid(varchar(12)) RETURNS varchar(12) AS $$
	SELECT min(sessionid) 
	FROM sstudents INNER JOIN studentdegrees ON sstudents.studentdegreeid = studentdegrees.studentdegreeid
	WHERE (studentid = $1);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getexamtimecount(integer, date, time, time) RETURNS bigint AS $$
	SELECT count(qgradeid) FROM qexamtimetableview
	WHERE (qstudentid = $1) AND (examdate = $2) AND (((starttime, endtime) OVERLAPS ($3, $4))=true);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getstudentdegreeid(varchar(12)) RETURNS integer AS $$
    SELECT max(studentdegreeid) FROM studentdegrees WHERE (studentid = $1);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getsstudentid(varchar(12)) RETURNS int AS $$
	SELECT max(sstudents.sstudentid) 
	FROM (studentdegrees INNER JOIN sstudents ON studentdegrees.studentdegreeid = sstudents.studentdegreeid)
		INNER JOIN sessions ON sstudents.sessionid = sessions.sessionid
	WHERE (studentdegrees.studentid = $1) AND (sessions.active = true);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getsstudentid(varchar(12), varchar(12)) RETURNS int AS $$
	SELECT max(sstudents.sstudentid) 
	FROM studentdegrees INNER JOIN sstudents ON studentdegrees.studentdegreeid = sstudents.studentdegreeid
	WHERE (studentdegrees.studentid = $1) AND (sstudents.sessionid = $2);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getstudentid(varchar(12)) RETURNS varchar(12) AS $$
    SELECT max(studentid) FROM students WHERE (studentid = $1);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getstudylevel(int) RETURNS int AS $$
	SELECT max(studylevel) 
	FROM qstudents
	WHERE (studentdegreeid = $1) AND (approved = true);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getSresidentid(varchar(12)) RETURNS int AS $$
	SELECT max(sresidences.sresidenceid) 
	FROM sresidences INNER JOIN sessions ON sresidences.sessionid =sessions.sessionid 
	WHERE (sresidences.residenceid = $1) AND (sessions.active = true);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getSresidentid(varchar(12), varchar(12)) RETURNS int AS $$
	SELECT max(sresidenceid) 
	FROM sresidences 
	WHERE (residenceid = $1) AND (sessionid  = $2);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION updBalances() RETURNS varchar(50) AS $$
DECLARE
    myrecord RECORD;
	myqstudentid int;
BEGIN
	
	FOR myrecord IN SELECT sunimports.balance, students.studentid
		FROM (sunimports INNER JOIN students ON TRIM(UPPER(sunimports.accountnumber)) = TRIM(UPPER(students.accountnumber))) 
		WHERE sunimports.IsUploaded = False
	LOOP
		myqstudentid = getsstudentid(myrecord.studentid);

		IF (myqstudentid is not null) THEN
			UPDATE qstudents SET currbalance = myrecord.balance WHERE qstudentid = myqstudentid;
		ELSE
			UPDATE students SET currentbalance = myrecord.balance WHERE studentid = myrecord.studentid;
		END IF;
	END LOOP;
	
	INSERT INTO audittrail (username, tablename, recordid, changetype, narrative)
	VALUES (current_user, 'qstudents', 'UPLOAD', 'UPLOAD', 'Charges Upload');

	DELETE FROM sunimports;
	
	RETURN 'Done';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION updBankPicked() RETURNS varchar(50) AS $$
BEGIN	
	INSERT INTO banksuspence (entrydate, CustomerReference, quarterid, accountnumber, TransactionAmount, Narrative)
	SELECT vwbankfile.entrydate, vwbankfile.CustomerReference, vwbankfile.quarterid,
		vwbankfile.accountnumber, vwbankfile.TransactionAmount, vwbankfile.Narrative
	FROM vwbankfile LEFT JOIN banksuspence ON vwbankfile.Narrative = banksuspence.Narrative
	WHERE (banksuspence.Narrative is null);
	
	UPDATE studentpayments SET approved = true, phistoryid = 0 FROM vwbankfile
	WHERE (studentpayments.Narrative = vwbankfile.Narrative) AND (studentpayments.approved = false) AND (studentpayments.amount = vwbankfile.Transactionamount);
	
	UPDATE studentpayments SET approved = true, phistoryid = 0 FROM banksuspence
	WHERE (studentpayments.Narrative = banksuspence.TransComments) AND (studentpayments.approved = false) AND (studentpayments.amount = banksuspence.Transactionamount);
	
	DELETE FROM bankfile;
	
	UPDATE banksuspence SET Approved = true, Approveddate = now()
	FROM studentpayments
	WHERE (banksuspence.narrative = studentpayments.narrative)
		AND (banksuspence.Approved = false) AND (studentpayments.Approved = true);
		
	UPDATE banksuspence SET Approved = true, Approveddate = now()
	FROM studentpayments
	WHERE (banksuspence.TransComments = studentpayments.narrative)
		AND (banksuspence.Approved = false) AND (studentpayments.Approved = true);
		
	INSERT INTO audittrail (username, tablename, recordid, changetype, narrative)
	VALUES (current_user, 'banksuspence', 'RECONSILIATION', 'ETRANZACT', 'Charges Bank Reconsiliation');
	
	RETURN 'Done';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION updBankPicked(varchar(12)) RETURNS varchar(50) AS $$
BEGIN	
	UPDATE studentpayments SET Picked = true, Pickeddate  = now() FROM qstudents
	WHERE (studentpayments.qstudentid = qstudents.qstudentid) 
	AND (qstudents.quarterid = $1) AND (studentpayments.approved = true)
	AND (studentpayments.Picked = false);
	
	UPDATE qstudents SET Picked = true, Pickeddate  = now(), LRFPicked = true, LRFPickeddate  = now()
	WHERE (quarterid = $1) AND (finaceapproval = true) AND (Picked = false);

	UPDATE scholarships SET posted = true, dateposted = now()
	WHERE (quarterid = $1) AND (approved = true) AND (posted = false);
	
	RETURN 'Done';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION delBankPicked() RETURNS varchar(50) AS $$
BEGIN
	DELETE FROM Bankrecons;
	RETURN 'Done';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION updOpenFinance(varchar(12), varchar(12)) RETURNS VARCHAR(120) AS $$
DECLARE
	myrec RECORD;
	mystr VARCHAR(120);
BEGIN
	SELECT INTO myrec qstudentid, finaceapproval, financeclosed FROM qstudents
	WHERE (qstudentid = CAST($2 as int));
	
	IF (myrec.qstudentid IS NULL) THEN
		mystr := 'You must add the semester first.';
	ELSIF (myrec.finaceapproval = true) THEN
		mystr := 'You have been finacially approved, Visit busuary to get your payments opened.';
	ELSE
		UPDATE qstudents SET finaceapproval = false, financeclosed = false WHERE qstudentid = myrec.qstudentid;
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

CREATE OR REPLACE FUNCTION insQStudent(varchar(12), varchar(12)) RETURNS VARCHAR(120) AS $$
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
	SELECT INTO mystud onprobation, userpasswd, firstpasswd, residenceid, blockname, roomnumber,
		currentbalance, accountnumber, newstudent, seeregistrar
	FROM students
	WHERE (studentid = $1);

	mydegreeid := getstudentdegreeid($1);
	mystudylevel := getstudylevel(mydegreeid);
	myqresidentid := getSresidentid(mystud.residenceid);
	
	SELECT INTO mymajor minlevel, maxlevel FROM majors INNER JOIN studentmajors ON majors.majorid = studentmajors.majorid
	WHERE (studentmajors.studentdegreeid = mydegreeid);
	
	SELECT INTO myrec qstudentid FROM qstudents
	WHERE (studentdegreeid = mydegreeid) AND (quarterid = $2);
	
	SELECT INTO myquarter qlatereg, qlastdrop, lateregistrationfee, getchargedays(qlatereg, current_date) as latedays,
		lateregistrationfee * getchargedays(qlatereg, current_date) as latefees,
		quarterid, substring(quarterid from 11 for 1) as quarter
	FROM quarters WHERE (quarterid = $2);
	
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
	ELSIF (substring($2 from 11 for 1) = '1') THEN
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
		mystr := 'The registration is closed for this session.';
	ELSIF (mystud.onprobation = true) THEN
		mystr := 'Student on Probation cannot proceed.';
	ELSIF (mystud.seeregistrar = true) THEN
		mystr := 'Cannot Proceed, See Registars office.';
	ELSIF (mystud.userpasswd = md5(mystud.firstpasswd)) THEN
		mystr := 'You must change your password first before proceeding.';
	ELSIF (mystud.accountnumber IS NULL) THEN
		mystr := 'You must have an account number, contact Finance office.';
	ELSIF (mydegreeid IS NULL) THEN
		mystr := 'No Degree Indicated contact Registrars Office';
	ELSIF (getcoremajor(mydegreeid) IS NULL) THEN
		mystr := 'No Major Indicated contact Registrars Office';
	ELSIF (myrec.qstudentid IS NULL) THEN
		IF (myqresidentid is null) THEN
			INSERT INTO qstudents(quarterid, studentdegreeid, studylevel, currbalance, charges, financenarrative, paymenttype)
			VALUES ($2, mydegreeid, mystudylevel, mycurrbalance, mylatefees, mynarrative, 1);
		ELSE
			INSERT INTO qstudents(quarterid, studentdegreeid, studylevel, qresidentid, blockname, roomnumber, currbalance, charges, financenarrative, paymenttype)
			VALUES ($2, mydegreeid, mystudylevel, myqresidentid, mystud.blockname, mystud.roomnumber, mycurrbalance, mylatefees, mynarrative, 1);
		END IF;
		
		mycurrqs := getsstudentid($1);
		creditcount := 0;
		FOR mycourse IN SELECT yeartaken, courseid, min(qcourseid) as qcourseid, max(credithours) as credithours
			FROM qcoursecheckpass
			WHERE (elective = false) AND (coursepased = false) AND (prereqpassed = true)
				AND (yeartaken <= (mystudylevel/100)) AND (studentid = $1)
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
		mystr := 'Semester already registered';
	END IF;

    RETURN mystr;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION updQStudent(varchar(12), varchar(12)) RETURNS VARCHAR(120) AS $$
DECLARE
	myrec RECORD;
	mystr VARCHAR(120);
	mycurrqs int;
BEGIN
	mycurrqs := getsstudentid($1);
	
	SELECT INTO myrec qstudentid, financeclosed, finaceapproval, mealtype, mealticket
		FROM qstudents WHERE (qstudentid = mycurrqs);

	IF (myrec.qstudentid is null) THEN
		mystr := 'Register for the semester first';
	ELSIF (myrec.financeclosed = true) OR (myrec.finaceapproval = true) THEN
		mystr := 'You cannot make changes after submiting your payment unless you apply on the post for it to be opened by finance.';
	ELSIF (myrec.mealticket > 0) THEN
			mystr := 'You cannot not change meal selection after getting meal ticket.';
	ELSIF ($2 = '1') THEN
		UPDATE qstudents SET offcampus = true, premiumhall = false, mealtype = 'NONE' WHERE (qstudentid = mycurrqs);
		mystr := 'Off campus applied, await authorization.';
	ELSIF ($2 = '2') THEN
		UPDATE qstudents SET offcampus = false, premiumhall = false, mealtype = 'BL' WHERE (qstudentid = mycurrqs);
		mystr := 'Resident Student Taking Breakfast and Lunch';
	ELSIF ($2 = '3') THEN
		UPDATE qstudents SET offcampus = false, premiumhall = false, mealtype = 'BS' WHERE (qstudentid = mycurrqs);
		mystr := 'Resident Student Taking Breakfast and Supper';
	ELSIF ($2 = '4') THEN
		UPDATE qstudents SET offcampus = false, premiumhall = false, mealtype = 'LS' WHERE (qstudentid = mycurrqs);
		mystr := 'Resident Student Taking Lunch and Supper';
	ELSIF ($2 = '5') THEN
		UPDATE qstudents SET offcampus = false, premiumhall = false, mealtype = 'BLS' WHERE (qstudentid = mycurrqs);
		mystr := 'Resident Student Taking Breakfast, Lunch and Supper';
	ELSIF ($2 = '6') THEN
		UPDATE qstudents SET offcampus = false, premiumhall = true, mealtype = 'BL' WHERE (qstudentid = mycurrqs);
		mystr := 'Premier Hall Resident Student Taking Breakfast and Lunch';
	ELSIF ($2 = '7') THEN
		UPDATE qstudents SET offcampus = false, premiumhall = true, mealtype = 'BS' WHERE (qstudentid = mycurrqs);
		mystr := 'Premier Hall Resident Student Taking Breakfast and Supper';
	ELSIF ($2 = '8') THEN
		UPDATE qstudents SET offcampus = false, premiumhall = true, mealtype = 'LS' WHERE (qstudentid = mycurrqs);
		mystr := 'Premier Hall Resident Student Taking Lunch and Supper';
	ELSIF ($2 = '9') THEN
		UPDATE qstudents SET offcampus = false, premiumhall = true, mealtype = 'BLS' WHERE (qstudentid = mycurrqs);
		mystr := 'Premier Hall Resident Student Taking Breakfast, Lunch and Supper';
	ELSIF ($2 = '10') THEN
		UPDATE qstudents SET paymenttype = 1 WHERE (qstudentid = mycurrqs);
		mystr := 'Make full payment for the entire session.';
	ELSIF ($2 = '11') THEN
		UPDATE qstudents SET paymenttype = 2 WHERE (qstudentid = mycurrqs);
		mystr := 'Make full payment for the semester.';
	ELSIF ($2 = '12') THEN
		UPDATE qstudents SET paymenttype = 3 WHERE (qstudentid = mycurrqs);
		mystr := 'Applied for part payment for the semester.';
	ELSE
		mystr := 'Make Proper selection';
	END IF;

    RETURN mystr;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION getcoursehours(int) RETURNS float AS $$
	SELECT courses.credithours
	FROM courses INNER JOIN qcourses ON courses.courseid = qcourses.courseid
	WHERE (qcourseid=$1);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getcoursecredits(int) RETURNS float AS $$
	SELECT (CASE courses.nogpa WHEN true THEN 0 ELSE courses.credithours END)
	FROM courses INNER JOIN qcourses ON courses.courseid = qcourses.courseid
	WHERE (qcourseid=$1);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION insQCourse(varchar(12), varchar(12)) RETURNS VARCHAR(120) AS $$
DECLARE
	mysrec RECORD;
	myrec RECORD;
	mystr VARCHAR(120);
	mycurrqs int;
BEGIN
	mycurrqs := getsstudentid($1);

	SELECT INTO mysrec qstudentid, finalised, approved FROM qstudents
	WHERE (qstudentid = mycurrqs);

	SELECT INTO myrec qgradeid, dropped, approved FROM qgrades
	WHERE (qstudentid = mycurrqs) AND (qcourseid = CAST($2 as int));
	
	IF (mysrec.qstudentid IS NULL) THEN
		mystr := 'Please register for Semester and select residence first.';
	ELSIF (mysrec.finalised = true) THEN
		mystr := 'You have closed the selection.';
	ELSIF (myrec.qgradeid IS NULL) THEN
		INSERT INTO qgrades(qstudentid, qcourseid, hours, credit, approved) VALUES (mycurrqs, CAST($2 AS integer), getcoursehours(CAST($2 AS integer)), getcoursecredits(CAST($2 AS integer)), true);
		mystr := 'Course registered awaiting approval';
	ELSIF (myrec.dropped=true) THEN
		UPDATE qgrades SET dropped=false, askdrop=false, approved=false, hours=getcoursehours(CAST($2 AS integer)), credit=getcoursecredits(CAST($2 AS integer)) WHERE qgradeid = myrec.qgradeid;
		mystr := 'Course registered awaiting approval';
	ELSE
		mystr := 'Course already registered';
	END IF;

    RETURN mystr;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION insQSpecialCourse(varchar(12), varchar(12)) RETURNS VARCHAR(120) AS $$
DECLARE
	mysrec RECORD;
	myrec RECORD;
	mystr VARCHAR(120);
	mycurrqs int;
BEGIN
	mycurrqs := getsstudentid($1);

	SELECT INTO mysrec qstudentid, finalised, approved FROM qstudents
	WHERE (qstudentid = mycurrqs);

	SELECT INTO myrec qgradeid, dropped, approved FROM qgrades
	WHERE (qstudentid = mycurrqs) AND (qcourseid = CAST($2 as int));
	
	IF (mysrec.qstudentid IS NULL) THEN
		mystr := 'Please register for Semester and select residence first.';
	ELSIF (mysrec.finalised = true) THEN
		mystr := 'You have closed the selection.';
	ELSIF (myrec.qgradeid IS NULL) THEN
		INSERT INTO qgrades(qstudentid, qcourseid, hours, credit, approved) VALUES (mycurrqs, CAST($2 AS integer), getcoursehours(CAST($2 AS integer)), getcoursecredits(CAST($2 AS integer)), false);
		mystr := 'Course registered awaiting approval';
	ELSIF (myrec.dropped=true) THEN
		UPDATE qgrades SET dropped=false, askdrop=false, approved=false, hours=getcoursehours(CAST($2 AS integer)), credit=getcoursecredits(CAST($2 AS integer)) WHERE qgradeid = myrec.qgradeid;
		mystr := 'Course registered awaiting approval';
	ELSE
		mystr := 'Course already registered';
	END IF;

    RETURN mystr;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION dropQCourse(varchar(12), varchar(12)) RETURNS VARCHAR(50) AS $$
DECLARE
	myrec RECORD;
	mystr VARCHAR(50);
	mycurrqs int;
BEGIN
	mycurrqs := getsstudentid($1);

	SELECT INTO myrec qstudentid, finalised FROM qstudents
	WHERE (qstudentid = mycurrqs);

	IF (myrec.qstudentid IS NULL) THEN
		mystr := 'Please register for Semester and select residence first.';
	ELSIF (myrec.finalised = true) THEN
		mystr := 'You have closed the selection.';
	ELSE
		UPDATE qgrades SET askdrop = true, askdropdate = current_timestamp WHERE qgradeid = CAST($2 as int);
		UPDATE qgrades SET dropped = true, dropdate = current_date WHERE qgradeid = CAST($2 as int);
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

CREATE OR REPLACE FUNCTION insQClose(varchar(12), varchar(12)) RETURNS VARCHAR(250) AS $$
DECLARE
	myrec RECORD;
	mymajor RECORD;
	ttb RECORD;
	courserec RECORD;
	placerec RECORD;
	prererec RECORD;
	studentrec RECORD;
	mystr VARCHAR(250);
	mydegreeid int;
	myoverload boolean;
	myfeesline integer;
	mymaxcredit real;
BEGIN
	mydegreeid := getstudentdegreeid($1);

	SELECT INTO myrec qstudentid, finalised, finaceapproval, gpa, hours, 
		quarterid, quarter, mincredits, maxcredits, studylevel,
		offcampus, residenceoffcampus, overloadapproval, overloadhours, studentdeanapproval
	FROM studentquarterview
	WHERE (studentdegreeid = mydegreeid) AND (quarterid = $2);
	
	mymaxcredit := myrec.maxcredits;
	
	SELECT INTO mymajor majors.quarterload
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

	IF (myrec.qstudentid IS NULL) THEN 
		mystr := 'Please register for the semester and make course selections first before closing.';
	ELSIF (myrec.finalised = true) THEN
		mystr := 'Semester is closed for registration';
	ELSIF (ttb.coursetitle IS NOT NULL) THEN
		mystr := 'You have an timetable clashing for ' || ttb.coursetitle;
	ELSIF (courserec.courseid IS NOT NULL) THEN
		mystr := 'The class ' || courserec.courseid || ', ' || courserec.coursetitle || ' is full';
	ELSIF (prererec.courseid IS NOT NULL) THEN
		mystr := 'You need to complete the prerequisites or placement for course ' || prererec.courseid || ', ' || prererec.coursetitle;
---	ELSIF (placerec.courseid IS NOT NULL) THEN
---		mystr := 'You need to take all lower level course first like ' || placerec.courseid || ', ' || placerec.coursetitle;
	ELSIF (myrec.hours < myrec.mincredits) AND (myrec.overloadapproval = false) THEN
		mystr := 'You have an underload, the required minimum is ' || CAST(myrec.mincredits as text) || ' credits.';
	ELSIF (myrec.hours < myrec.mincredits) AND (myrec.overloadapproval = true) AND (myrec.hours < myrec.overloadhours) THEN
		mystr := 'You have an underload, you can only take the approved minimum of ' ||  CAST(myrec.overloadhours as text);
	ELSIF (myrec.hours > mymaxcredit) AND (myrec.overloadapproval = false) THEN
		mystr := 'You have an overload, the required maximum is ' || CAST(mymaxcredit as text) || ' credits.';
	ELSIF (myrec.hours > mymaxcredit) AND (myrec.overloadapproval = true) AND (myrec.hours > myrec.overloadhours) THEN
		mystr := 'You have an overload, you can only take the approved maximum of ' ||  CAST(myrec.overloadhours as text);
	ELSIF (myrec.offcampus = true) and (myrec.studentdeanapproval = false) THEN
		mystr := 'You have no clearence to be off campus';
	ELSIF (myrec.finaceapproval = true) THEN
		UPDATE qstudents SET finalised = true WHERE qstudentid = myrec.qstudentid;
		UPDATE qstudents SET firstclosetime = now() WHERE (firstclosetime is null) AND (qstudentid = myrec.qstudentid);
		mystr := 'Semester Submision done check status for approvals.';
	ELSE
		mystr := 'Get Financial approval first';
	END IF;

    RETURN mystr;
END;
$$ LANGUAGE plpgsql;

-- update the person who finacially approved a student
CREATE OR REPLACE FUNCTION updqstudents() RETURNS trigger AS $$
DECLARE
	myrec RECORD;
	mystr VARCHAR(120);
BEGIN
	IF (OLD.ispartpayment = false) AND (NEW.ispartpayment = true) THEN
		INSERT INTO approvallist(qstudentid, approvedby, approvaltype, approvedate, clientip) 
		VALUES (NEW.qstudentid, current_user, 'Plan Payment', now(), cast(inet_client_addr() as varchar));
	END IF;
	
	IF (OLD.finaceapproval = false) AND (NEW.finaceapproval = true) THEN
		INSERT INTO approvallist(qstudentid, approvedby, approvaltype, approvedate, clientip) 
		VALUES (NEW.qstudentid, current_user, 'Finance', now(), cast(inet_client_addr() as varchar));
	END IF;

	IF (OLD.finaceapproval = true) AND (NEW.finaceapproval = false) THEN
		INSERT INTO approvallist(qstudentid, approvedby, approvaltype, approvedate, clientip) 
		VALUES (NEW.qstudentid, current_user, 'Finance Open', now(), cast(inet_client_addr() as varchar));
	END IF;
	
	IF (OLD.studentdeanapproval = false) AND (NEW.studentdeanapproval = true) THEN
		INSERT INTO approvallist(qstudentid, approvedby, approvaltype, approvedate, clientip) 
		VALUES (NEW.qstudentid, current_user, 'Dean', now(), cast(inet_client_addr() as varchar));
	END IF;
	
	IF (OLD.approved = false) AND (NEW.approved = true) THEN
		INSERT INTO approvallist(qstudentid, approvedby, approvaltype, approvedate, clientip) 
		VALUES (NEW.qstudentid, current_user, 'Registary', now(), cast(inet_client_addr() as varchar));
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

-- update the date a course was withdrawn
CREATE OR REPLACE FUNCTION updqgrades() RETURNS trigger AS $$
BEGIN
	IF (OLD.gradeid <> 'W') and (NEW.gradeid = 'W') THEN
		UPDATE qgrades SET withdrawdate = current_date WHERE qgradeID = NEW.qgradeID;
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
	
CREATE OR REPLACE FUNCTION updqcourseitemmarks(varchar(12), varchar(12)) RETURNS varchar(240) AS $$
BEGIN
	UPDATE qgrades SET instructormarks = vwcourseitemmarks.netscore FROM vwcourseitemmarks
	WHERE (qgrades.qgradeid = vwcourseitemmarks.qgradeid) AND 
		(qgrades.qcourseid = CAST($2 as int));
	
	RETURN 'Student Marks Updated Correctly';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION updqcoursedepartment(varchar(12), varchar(12)) RETURNS varchar(240) AS $$
BEGIN
	UPDATE qgrades SET departmentmarks = instructormarks
	WHERE (qgrades.qcourseid = CAST($2 as int));
	
	UPDATE qcourses SET lecturesubmit = true, lsdate = now()
	WHERE (qcourseid = CAST($2 as int));
	
	RETURN 'Marks Submitted to the Department Correctly';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION openqcoursedepartment(varchar(12), varchar(12)) RETURNS varchar(240) AS $$
BEGIN
	UPDATE qcourses SET lecturesubmit = false
	WHERE (qcourseid = CAST($2 as int));
	
	RETURN 'Course opened for lecturer to correct';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION updqcoursefaculty(varchar(12), varchar(12)) RETURNS varchar(240) AS $$
BEGIN
	UPDATE qgrades SET finalmarks = departmentmarks
	WHERE (qgrades.qcourseid = CAST($2 as int));
	
	UPDATE qcourses SET departmentsubmit = true, dsdate = now()
	WHERE (qcourseid = CAST($2 as int));
	
	RETURN 'Marks Submitted to the Faculty Correctly';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION updqcoursegrade(varchar(12), varchar(12)) RETURNS varchar(240) AS $$
BEGIN
	UPDATE qgrades SET gradeid = getgradeid(finalmarks)
	WHERE (qgrades.qcourseid = CAST($2 as int));
	
	UPDATE qcourses SET facultysubmit = true, fsdate = now()
	WHERE (qcourseid = CAST($2 as int));
	
	RETURN 'Final Grade Submitted to Registry Correctly';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION updprinted(integer) RETURNS void AS $$
	UPDATE qstudents SET printed = true WHERE qstudentid=$1;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION selQResidence(varchar(12), varchar(12)) RETURNS VARCHAR(120) AS $$
DECLARE
	mystr VARCHAR(120);
	myrec RECORD;
	myqstud int;
	myres int;
BEGIN
	myqstud := getsstudentid($1);
	myres := CAST($2 AS integer);

	SELECT INTO myrec qstudentid, finalised FROM qstudents
	WHERE (qstudentid=myqstud);

	IF (myrec.qstudentid IS NULL) THEN
		mystr := 'Please register for the semester first.';
	ELSIF (myrec.finalised = true) THEN
		mystr := 'You have closed the selection.';
	ELSE
		UPDATE qstudents SET qresidenceid = myres, roomnumber = null WHERE (qstudentid = myqstud);
		mystr := 'Residence registered awaiting approval';
	END IF;

    RETURN mystr;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION selQRoom(varchar(12), varchar(12)) RETURNS VARCHAR(50) AS $$
DECLARE
	mystr VARCHAR(120);
	myrec RECORD;
	myqstud int;
	myroom int;
BEGIN
	myqstud := getsstudentid($1);
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

CREATE OR REPLACE FUNCTION selQsabathclass(varchar(12), varchar(12)) RETURNS VARCHAR(50) AS $$
DECLARE
	mystr VARCHAR(120);
	myrec RECORD;
	myqstud int;
	myclass int;
BEGIN
	myqstud := getsstudentid($1);
	myclass := CAST($2 AS integer);

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

CREATE OR REPLACE FUNCTION updsubmited(varchar(12), varchar(12)) RETURNS VARCHAR(50) AS $$
BEGIN
	UPDATE qcoursemarks SET submited = current_date WHERE qcoursemarkid=$2;
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

CREATE OR REPLACE FUNCTION getgradeid(real) RETURNS varchar(2) AS $$
	SELECT max(gradeid)
	FROM grades 
	WHERE (minrange <= $1) AND (maxrange >= $1);
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
	WHERE quarterdone = CAST(substring(NEW.quarterid from 11 for 1) as int)
	GROUP BY courseid;

	INSERT INTO qresidences (quarterid, residenceid, charges)
	SELECT NEW.quarterid, residenceid, defaultrate
	FROM residences;

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER insQuarter AFTER INSERT ON quarters
    FOR EACH ROW EXECUTE PROCEDURE insQuarter();

CREATE OR REPLACE FUNCTION insScourses() RETURNS trigger AS $$
BEGIN
	NEW.coursetitle := getcoursetitle(NEW.courseid);
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER insScourses BEFORE INSERT ON scourses
    FOR EACH ROW EXECUTE PROCEDURE insScourses();

CREATE OR REPLACE FUNCTION updScourses() RETURNS trigger AS $$
BEGIN
	IF (OLD.courseid <> NEW.courseid) THEN
		NEW.coursetitle := getcoursetitle(NEW.courseid);
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER updScourses BEFORE UPDATE ON scourses
    FOR EACH ROW EXECUTE PROCEDURE updScourses();
	
-- update students email address
CREATE OR REPLACE FUNCTION updstudentemail(varchar(50), varchar(50)) RETURNS varchar(120) AS $$
DECLARE
	mycnt RECORD;
	mypass VARCHAR(120);
	mystr VARCHAR(120);
BEGIN
	mypass := lower($2 || substring($1 from 1 for 2));

	SELECT INTO mycnt count(studentid) as emailcount
	FROM students
	WHERE (emailuser = mypass);
	
	IF (mycnt.emailcount = 0) THEN
		mystr := mypass;
	ELSE
		mystr := mypass || mycnt.emailcount;
	END IF;
	
	RETURN mystr;
END;
$$ LANGUAGE plpgsql;

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

CREATE OR REPLACE FUNCTION insstudentname() RETURNS trigger AS $$
BEGIN	
	NEW.studentname := UPPER(NEW.surname)	|| ', ' || UPPER(NEW.firstname) || ' ' || UPPER(COALESCE(NEW.othernames, ''));
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER insstudentname BEFORE INSERT OR UPDATE ON students
    FOR EACH ROW EXECUTE PROCEDURE insstudentname();

--- Finance payment
CREATE OR REPLACE FUNCTION insQPayment(varchar(12), varchar(12)) RETURNS VARCHAR(120) AS $$
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
	mycurrqs := getsstudentid($1);
	
	SELECT INTO mystud currentbalance, accountnumber, newstudent, seeregistrar
	FROM students WHERE (studentid = $1);
	
	SELECT INTO mypayrec studentpaymentid
	FROM studentpayments WHERE (qstudentid = mycurrqs) AND (approved = false);
	
	SELECT INTO mypayreccheck studentpaymentid
	FROM studentpayments WHERE (qstudentid = mycurrqs) AND (approved = true);
	
	SELECT INTO myqrec charges
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
	
	SELECT INTO myrec accountnumber, quarterid, currbalance, fullfinalbalance, finalbalance,
		paymenttype, ispartpayment, offcampus, studentdeanapproval, financeclosed, finaceapproval
	FROM vwqstudentbalances
	WHERE (qstudentid = mycurrqs);	

	myamount := 0;
	mystr := null;
	IF (myrec.currbalance is null) THEN
		mystr := 'Application for payment rejected because your current credit is not updated, send a post to Bursary.';
	ELSIF (myrec.financeclosed = true) OR (myrec.finaceapproval = true) THEN
		mystr := 'You cannot make changes after submiting your payment unless you apply on the post for it to be opened by finance.';
	ELSIF (myrec.offcampus = true) AND (myrec.studentdeanapproval = false) THEN
		mystr := 'Application for payment rejected, first get off campus approval.';
	ELSIF (myrec.paymenttype = 1) THEN
		myamount := myrec.fullfinalbalance;
	ELSIF (myrec.paymenttype = 2) THEN
		myamount := myrec.finalbalance;
	ELSIF (myrec.paymenttype = 3) AND (myrec.ispartpayment = false) THEN
		mystr := 'Application for payment rejected, your require approval for the payment plan';
	ELSIF (myrec.paymenttype = 3) AND (myrec.ispartpayment = true) THEN
		myamount := myrec.currbalance + (myrec.finalbalance - myrec.currbalance) / 2;
	ELSE
		mystr := 'Application for payment rejected, verify application and approvals';
	END IF;

	IF (myamount < 0) THEN
		IF (mypayrec.studentpaymentid is null) THEN
			INSERT INTO studentpayments (qstudentid, amount, narrative) 
			VALUES (mycurrqs, myamount * (-1), CAST(nextval('studentpayment_seq') as text) || 'Fees;' || myrec.quarterid || ';' || myrec.accountnumber);
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

-- update students email address
CREATE OR REPLACE FUNCTION deldupstudent(varchar(12), varchar(12)) RETURNS varchar(120) AS $$
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
		SELECT INTO myqtr substring(quarterid from 3 for 2) as qid, quarterid FROM quarters WHERE active = true;
		newid := myqtr.qid || substring($1 from 3 for 5);
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
		UPDATE students SET studentid = newid, newstudent = false  WHERE studentid = $1;
		UPDATE studentdegrees SET studentid = newid WHERE studentid is null;
		UPDATE studentrequests SET studentid = newid WHERE studentid is null;
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
	reca RECORD;
BEGIN
	SELECT schoolid, departmentid INTO reca
	FROM (students INNER JOIN studentdegrees ON students.studentid = studentdegrees.studentid)
		INNER JOIN qstudents ON studentdegrees.studentdegreeid = qstudents.studentdegreeid
	WHERE (qstudents.qstudentid = NEW.qstudentid);

	IF(reca.departmentid = 'CSMA') THEN
		NEW.terminalid = '0110000004';
	ELSIF(reca.schoolid = 'LSS') THEN
		NEW.terminalid = '0560000128';
	ELSIF(reca.schoolid = 'SAT') THEN
		NEW.terminalid = '0330000008';
	ELSIF(reca.schoolid = 'EAH') THEN
		NEW.terminalid = '0350000001';
	ELSE
		NEW.terminalid = '0690000082';
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER updstudentpayments BEFORE INSERT ON studentpayments
    FOR EACH ROW EXECUTE PROCEDURE updstudentpayments();

CREATE OR REPLACE FUNCTION updQPayment(varchar(12), varchar(12)) RETURNS VARCHAR(120) AS $$
DECLARE
	transid integer;
	oldtransid integer;
BEGIN
	transid := nextval('studentpayments_studentpaymentid_seq');
	oldtransid := CAST($2 as integer);
	
	INSERT INTO paymentracks (studentpaymentid, oldtransactionid)
	VALUES (transid, oldtransid);

	UPDATE studentpayments SET studentpaymentid = transid
	WHERE studentpaymentid = oldtransid;

	RETURN 'Update Transaction to new ID ' || CAST(transid as varchar);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION inspin_data() RETURNS trigger AS $$
BEGIN	
	UPDATE applications SET paid = true, openapplication = true
	WHERE (receiptnumber = NEW.receipt_no) AND (confirmationno = NEW.confirmation_no);

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER inspin_data AFTER INSERT ON pin_data
    FOR EACH ROW EXECUTE PROCEDURE inspin_data();

CREATE OR REPLACE FUNCTION submitapplication(varchar(12), varchar(12)) RETURNS VARCHAR(120) AS $$
BEGIN
	UPDATE registrations SET submitapplication = true, submitdate = now()
	WHERE (applicationid = CAST($2 as integer));

	UPDATE applications SET openapplication = false
	WHERE (applicationid = CAST($2 as integer));

	RETURN 'Submitted the application.';
END;
$$ LANGUAGE plpgsql;
