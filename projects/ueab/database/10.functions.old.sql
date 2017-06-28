CREATE OR REPLACE FUNCTION updBalances() RETURNS varchar(50) AS $$
DECLARE
    myrecord RECORD;
	myqstudentid int;
BEGIN
	
	FOR myrecord IN SELECT sunimports.balance, students.studentid
		FROM (sunimports INNER JOIN students ON sunimports.accountnumber = students.accountnumber) 
		WHERE sunimports.IsUploaded = False
	LOOP
		myqstudentid = getqstudentid(myrecord.studentid);

		IF (myqstudentid is not null) THEN
			UPDATE qstudents SET currbalance = (-1) * myrecord.balance WHERE qstudentid = myqstudentid;
		END IF;
	END LOOP;

	DELETE FROM sunimports;
	
	RETURN 'Done';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION updBanking() RETURNS varchar(50) AS $$
DECLARE
    myrecord RECORD;
	myqstudentid int;
BEGIN
	
	INSERT INTO banksuspence (TransactionDate, ValueDate, TransactionAmount, DRCRFlag, CustomerReference, BankTransactionDetail, TransactionDetail, TransactionType)
	SELECT cast(TransactionDate as date), cast(ValueDate as date), cast(TransactionAmount as real), DRCRFlag,  CustomerReference, TransactionDetail, trim(replace(TransactionDetail, 'CASH DEPOSIT', '')), cast(TransactionType as int)
	FROM bankfile WHERE (transactiontype = '504') OR (transactiontype = '591');

	INSERT INTO banksuspence (TransactionDate, ValueDate, TransactionAmount, DRCRFlag, CustomerReference, BankTransactionDetail, TransactionDetail, TransactionType)
	SELECT cast(TransactionDate as date), cast(ValueDate as date),  cast(TransactionAmount as real), DRCR, OwnerReference, TransactionDescription, InformationAccountOwner, cast(TransactionType as int)
	FROM bankdayfile WHERE (transactiontype = '504') OR (transactiontype = '591');

	DELETE FROM bankdayfile;
	DELETE FROM bankfile;
	
	RETURN 'Done';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION getCustomerReference(varchar(25)) RETURNS varchar(25) AS $$
    SELECT max(CustomerReference) FROM studentbank WHERE (CustomerReference = $1);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION updStudentBank(int) RETURNS varchar(50) AS $$
DECLARE
    myrecord RECORD;
	mydup RECORD;
BEGIN
	
	FOR myrecord IN SELECT banksuspenceid, TransactionDate, ValueDate, TransactionAmount, DRCRFlag, CustomerReference, TransactionDetail, TransactionType, studentid
		FROM banksuspenceview WHERE (Picked = false) AND (Approve = true) AND (getstudentid(studentid) is not null)
	LOOP
		SELECT INTO mydup max(studentbankid) as custref FROM studentbank WHERE (CustomerReference = myrecord.CustomerReference) 
			AND (TransactionDetail = myrecord.TransactionDetail);
 
		IF (mydup.custref is null) THEN
			INSERT INTO studentbank (studentid, CustomerReference, TransactionDate, ValueDate, TransactionAmount, 
				DRCRFlag, TransactionDetail, TransactionType)
			VALUES (myrecord.studentid, myrecord.CustomerReference, myrecord.TransactionDate, myrecord.ValueDate,
				myrecord.TransactionAmount, myrecord.DRCRFlag, myrecord.TransactionDetail, myrecord.TransactionType);

			UPDATE banksuspence SET Picked = true WHERE banksuspenceid = myrecord.banksuspenceid;
		ELSE
			UPDATE banksuspence SET Duplicate = true WHERE banksuspenceid = myrecord.banksuspenceid;
		END IF;
	END LOOP;
	
	RETURN 'Done';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION updBankPicked(int) RETURNS varchar(50) AS $$
BEGIN	
	UPDATE studentbank SET Picked = true, Pickeddate = now() WHERE studentbankid = $1;
	RETURN 'Done';
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION updprinted(integer) RETURNS void AS $$
	UPDATE qstudents SET printed = true, approved = true WHERE qstudentid=$1;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION updsubmited(varchar(12), varchar(12)) RETURNS VARCHAR(50) AS $$
BEGIN
	UPDATE qcoursemarks SET submited = current_date WHERE qcoursemarkid = $2;
	RETURN 'Submmited';
END;
$$ LANGUAGE plpgsql;


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


CREATE OR REPLACE FUNCTION updExamBalances() RETURNS varchar(50) AS $$
DECLARE
    myrec RECORD;
	examBalance real;
BEGIN
	examBalance := -10000;
	SELECT max(exam_line) as exam_balance, max(quarterid) as max_quarterid INTO myrec
	FROM quarters
	WHERE (closed = false);

	IF(myrec.exam_balance is not null) THEN
		examBalance := (-1) * myrec.exam_balance;

		PERFORM updBalances();

		UPDATE qstudents SET exam_clear	= true, exam_clear_date	= now(), exam_clear_balance = currbalance
		WHERE (approved = true) and (currbalance >= examBalance) AND (exam_clear = false)
			AND (quarterid = myrec.max_quarterid);

		UPDATE qstudents SET exam_clear = false WHERE (exam_clear = true) AND (exam_clear_balance < examBalance);
	END IF;
	
	RETURN 'Done';
END;
$$ LANGUAGE plpgsql;

