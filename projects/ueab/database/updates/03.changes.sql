
CREATE OR REPLACE FUNCTION getdbgradeid(integer) RETURNS varchar(2) AS $$
	SELECT CASE WHEN max(gradeid) is null THEN 'NG' WHEN $1 = -1 THEN 'DG' ELSE max(gradeid) END
	FROM grades 
	WHERE (minrange <= $1) AND (maxrange > $1);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getPGgradeid(integer) RETURNS varchar(2) AS $$
	SELECT CASE WHEN max(gradeid) is null THEN 'NG' WHEN $1 = -1 THEN 'DG' ELSE max(gradeid) END
	FROM grades 
	WHERE (p_minrange <= $1) AND (p_maxrange > $1);
$$ LANGUAGE SQL;




CREATE OR REPLACE FUNCTION insnewstudent(varchar, varchar, varchar) RETURNS VARCHAR(50) AS $$
DECLARE
	reg_check		RECORD;
	myrec 			RECORD;
	priadd 			RECORD;
	gudadd 			RECORD;
	idcount 		RECORD;
	myqtr 			RECORD;

	rtn				varchar(50);
	v_org_id		integer;
	reg_id			integer;
	v_bulletingid	integer;
	baseid 			VARCHAR(12);
	newid 			VARCHAR(12);
	fullname 		VARCHAR(50);
	genfirstpass 	VARCHAR(32);
	gfirstpass 		VARCHAR(32);
	genstudentpass 	VARCHAR(32);
BEGIN
	
	reg_id := CAST($1 as integer);

	SELECT denominationid, majorid, degreeid, sublevelid, residenceid, nationalityid, citizenshipid
		INTO reg_check
	FROM registrations
	WHERE (registrationid = reg_id);

	SELECT departments.schoolid, registrations.org_id, registrations.registrationid,
		registrations.denominationid, registrations.lastname, registrations.middlename, registrations.firstname,
		registrations.sex, registrations.nationalityid, registrations.maritalstatus,
		registrations.birthdate, registrations.existingid, registrations.degreeid, registrations.sublevelid,
		registrations.majorid, registrations.premajor
		INTO myrec
	FROM (departments INNER JOIN majors ON departments.departmentid = majors.departmentid)
	INNER JOIN registrations ON majors.majorid = registrations.majorid
	WHERE (registrations.registrationid = reg_id);

	SELECT regcontacts.regcontactid, regcontacts.address, regcontacts.zipcode, regcontacts.town, 
		regcontacts.countrycodeid, regcontacts.telephone, regcontacts.email
		INTO priadd
	FROM contacttypes INNER JOIN regcontacts ON contacttypes.contacttypeid = regcontacts.contacttypeid
	WHERE (contacttypes.primarycontact = true) AND (regcontacts.registrationid = reg_id);

	SELECT regcontacts.regcontactid, regcontacts.regcontactname, regcontacts.address, regcontacts.zipcode, 
		regcontacts.town, regcontacts.countrycodeid, regcontacts.telephone, regcontacts.email
		INTO gudadd
	FROM regcontacts
	WHERE (regcontacts.guardiancontact = true) AND (regcontacts.registrationid = reg_id);
	
	SELECT max(bulletingid) INTO v_bulletingid
	FROM bulleting 
	WHERE iscurrent = true;
	IF(v_bulletingid is null)THEN v_bulletingid := 0; END IF;

	SELECT quarterid INTO myqtr
	FROM quarters WHERE active = true;

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
	
	genfirstpass := first_password();
	gfirstpass := first_password();
	genstudentpass := md5(genfirstpass);

	IF(reg_check.denominationid is null)THEN
		rtn := 'You need to add denomination';
	ELSIF(reg_check.majorid is null)THEN
		rtn := 'You need to add major';
	ELSIF(reg_check.degreeid is null)THEN
		rtn := 'You need to add major';
	ELSIF(reg_check.sublevelid is null)THEN
		rtn := 'You need to add degree level';
	ELSIF(reg_check.residenceid is null)THEN
		rtn := 'You need to add country';
	ELSIF(reg_check.nationalityid is null)THEN
		rtn := 'You need to add nationality';
	ELSIF(reg_check.citizenshipid is null)THEN
		rtn := 'You need to add citizenship';
	ELSIF (myrec.existingid is null) THEN

		v_org_id := myrec.org_id;
		IF(v_org_id is null)THEN
			SELECT org_id INTO v_org_id
			FROM sublevels
			WHERE (sublevelid = reg_check.sublevelid);
		END IF;

		INSERT INTO students (org_id, studentid, accountnumber, studentname, schoolid, denominationid, Sex, Nationality,
			MaritalStatus, birthdate, firstpass, studentpass, address, zipcode, town, countrycodeid, telno, email,
			guardianname, gaddress, gzipcode, gtown, gcountrycodeid, gtelno, gemail, gfirstpass, gstudentpass,
			balance_time, curr_balance)
		VALUES (v_org_id, newid, newid, fullname, myrec.schoolid, myrec.denominationid, myrec.Sex, myrec.Nationalityid,
			myrec.MaritalStatus, myrec.birthdate, genfirstpass, genstudentpass,
			priadd.address, priadd.zipcode, priadd.town, myrec.Nationalityid, priadd.telephone, priadd.email,
			gudadd.regcontactname, gudadd.address, gudadd.zipcode, gudadd.town, myrec.Nationalityid, gudadd.telephone, gudadd.email,
			gfirstpass, md5(gfirstpass), now(), 0);

		INSERT INTO studentdegrees (degreeid, sublevelid, studentid, started, bulletingid)
		VALUES (myrec.degreeid,  myrec.sublevelid, newid, current_date, v_bulletingid);

		INSERT INTO studentmajors (studentdegreeid, majorid, major, nondegree, premajor, primarymajor)
		VALUES (getstudentdegreeid(newid), myrec.majorid, true, false, myrec.premajor, true);

		UPDATE registrations SET existingid = newid, accepted=true, accepteddate=current_date, firstpass=genfirstpass  
		WHERE (registrations.registrationid = reg_id);

		rtn := newid;
	ELSE
		rtn := myrec.existingid;
	END IF;

    RETURN rtn;
END;
$$ LANGUAGE plpgsql;

UPDATE studentdegrees SET bulletingid = 3
WHERE studentdegreeid IN
(SELECT studentdegreeid
FROM qstudents
GROUP BY studentdegreeid
HAVING min(quarterid) > '2012/2013.1');

