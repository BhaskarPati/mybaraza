
ALTER TABLE qstudents ADD residence_time		timestamp not null default now();
UPDATE qstudents SET residence_time = residence_time - '2 days'::interval 
WHERE (offcampus = true) AND (finaceapproval = false);
	
ALTER TABLE residences 
ADD	min_level			integer default 100,
ADD	max_level			integer default 500,
ADD	majors				text;


ALTER TABLE studentpayments ADD old_amount			real;

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



-- update students email address
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
		s.sex, s.nationality, s.maritalstatus, s.birthdate, s.address, s.zipcode, s.town, s.countrycodeid, 
		s.stateid, s.telno, s.mobile, s.email,  s.guardianname, s.gaddress, s.gzipcode, s.gtown, 
		s.gcountrycodeid, s.gtelno, s.gemail, 
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
		AND (quarterid = myrec.quarterid);
	
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
		RAISE EXCEPTION 'The study levels allowed are between % and % for your level %', resrec.min_level, resrec.max_level, resrec.min_level;
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




