CREATE OR REPLACE FUNCTION getprevsession(int, varchar(12)) RETURNS varchar(12) AS $$
	SELECT max(sstudents.sessionid)
	FROM sstudents
	WHERE (sstudents.studentdegreeid = $1) AND (sstudents.sessionid < $2);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getprevcredit(int, varchar(12)) RETURNS float AS $$
	SELECT sum(sgrades.credit)
	FROM (sgrades INNER JOIN sstudents ON sgrades.sstudentid = sstudents.sstudentid)
		INNER JOIN grades ON sgrades.gradeid = grades.gradeid
	WHERE (sstudents.studentdegreeid = $1) AND (sstudents.sessionid = $2) AND (sgrades.dropped = false)
		AND (grades.gpacount = true) AND (sgrades.repeated = false) AND (sgrades.gradeid <> 'W') AND (sgrades.gradeid <> 'AW');
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getprevgpa(int, varchar(12)) RETURNS float AS $$
	SELECT (CASE sum(sgrades.credit) WHEN 0 THEN 0 ELSE (sum(grades.gradeweight * sgrades.credit)/sum(sgrades.credit)) END)
	FROM (sgrades INNER JOIN sstudents ON sgrades.sstudentid = sstudents.sstudentid)
		INNER JOIN grades ON sgrades.gradeid = grades.gradeid
	WHERE (sstudents.studentdegreeid = $1) AND (sstudents.sessionid = $2) AND (sgrades.dropped = false)
		AND (grades.gpacount = true) AND (sgrades.repeated = false) AND (sgrades.gradeid <> 'W') AND (sgrades.gradeid <> 'AW');
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getcurrhours(int) RETURNS float AS $$
	SELECT sum(sgrades.hours)
	FROM (sgrades INNER JOIN sstudents ON sgrades.sstudentid = sstudents.sstudentid)
	WHERE (sstudents.sstudentid = $1) AND (sgrades.dropped = false) AND (sgrades.gradeid <> 'W') AND (sgrades.gradeid <> 'AW');
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getcurrcredit(int) RETURNS float AS $$
	SELECT sum(sgrades.credit)
	FROM (sgrades INNER JOIN sstudents ON sgrades.sstudentid = sstudents.sstudentid)
		INNER JOIN grades ON sgrades.gradeid = grades.gradeid
	WHERE (sstudents.sstudentid = $1) AND (grades.gpacount = true) AND (sgrades.dropped = false) 
		AND (sgrades.repeated = false) AND (sgrades.gradeid <> 'W') AND (sgrades.gradeid <> 'AW');
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getcurrgpa(int) RETURNS float AS $$
	SELECT (CASE sum(sgrades.credit) WHEN 0 THEN 0 ELSE (sum(grades.gradeweight * sgrades.credit)/sum(sgrades.credit)) END)
	FROM (sgrades INNER JOIN sstudents ON sgrades.sstudentid = sstudents.sstudentid)
		INNER JOIN grades ON sgrades.gradeid = grades.gradeid
	WHERE (sstudents.sstudentid = $1)	AND (grades.gpacount = true) AND (sgrades.dropped = false) 
		AND (sgrades.repeated = false) AND (sgrades.gradeid <> 'W') AND (sgrades.gradeid <> 'AW');
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getcummcredit(int, varchar(12)) RETURNS float AS $$
	SELECT sum(sgrades.credit)
	FROM (sgrades INNER JOIN sstudents ON sgrades.sstudentid = sstudents.sstudentid)
		INNER JOIN grades ON sgrades.gradeid = grades.gradeid
	WHERE (sstudents.studentdegreeid = $1) AND (sstudents.sessionid <= $2) AND (sgrades.dropped = false)
		AND (grades.gpacount = true) AND (sgrades.repeated = false) AND (sgrades.gradeid <> 'W') AND (sgrades.gradeid <> 'AW');
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getcummgpa(int, varchar(12)) RETURNS float AS $$
	SELECT (CASE sum(sgrades.credit) WHEN 0 THEN 0 ELSE (sum(grades.gradeweight * sgrades.credit)/sum(sgrades.credit)) END)
	FROM (sgrades INNER JOIN sstudents ON sgrades.sstudentid = sstudents.sstudentid)
		INNER JOIN grades ON sgrades.gradeid = grades.gradeid
	WHERE (sstudents.studentdegreeid = $1) AND (sstudents.sessionid <= $2) AND (sgrades.dropped = false)
		AND (grades.gpacount = true) AND (sgrades.repeated = false) AND (sgrades.gradeid <> 'W') AND (sgrades.gradeid <> 'AW');
$$ LANGUAGE SQL;

CREATE VIEW vwsstudentsummary AS
	SELECT studentid, studentname, sessionid, approved, studentdegreeid, sstudentid,
		sex, Nationality, MaritalStatus, studylevel,
		getcurrcredit(sstudentid) as credit, getcurrgpa(sstudentid) as gpa,
		getcummcredit(studentdegreeid, sessionid) as cummcredit,
		getcummgpa(studentdegreeid, sessionid) as cummgpa 
	FROM vwsstudents;

CREATE VIEW vwstudentsessionlist AS
	SELECT religionid, religionname, denominationid, denominationname, schoolid, schoolname, studentid, studentname, address, zipcode,
		town, addresscountry, telno, email, sponsortypeid, sponsortypename, sponsorid, sponsorname,
		sponsoraddress, sponsorstreet, sponsorpostalcode, sponsortown, sponsortelno, sponsoremail, 
		sponsorcountryid, sponsorcountryname,
		accountnumber, Nationality, Nationalitycountry, Sex, MaritalStatus, birthdate, firstpasswd, alumnae,
		onprobation, offcampus, currentcontact, degreelevelid, degreelevelname,
		degreeid, degreename, studentdegreeid, completed, started, cleared, clearedate,
		graduated, graduatedate, dropout, transferin, transferout, 
		sessionid, sessionyear, semester, sstart, slatereg, slatechange, slastdrop, send, active,
		residenceid, residencename, defaultrate, residenceoffcampus, residencesex, residencedean,
		sresidenceid, residenceoption, sstudentid, approved, probation,
		roomnumber, finaceapproval, majorapproval, departapproval, overloadapproval, finalised, printed,
		getcurrhours(sstudentid) as hours,		
		getcurrcredit(sstudentid) as credit, 
		getcurrgpa(sstudentid) as gpa,
		getcummcredit(studentdegreeid, sessionid) as cummcredit,
		getcummgpa(studentdegreeid, sessionid) as cummgpa,
		getprevsession(studentdegreeid, sessionid) as prevsession,
		(CASE WHEN (getprevsession(studentdegreeid, sessionid) is null) THEN true ELSE false END) as newstudent
	FROM vwsstudents;

CREATE VIEW vwstudentsessionsummary AS
	SELECT religionid, religionname, denominationid, denominationname, schoolid, schoolname, studentid, studentname, address, zipcode,
		town, addresscountry, telno, email, sponsortypeid, sponsortypename, sponsorid, sponsorname,
		sponsoraddress, sponsorstreet, sponsorpostalcode, sponsortown, sponsortelno, sponsoremail, 
		sponsorcountryid, sponsorcountryname,
		accountnumber, Nationality, Nationalitycountry, Sex, MaritalStatus, birthdate, firstpasswd, alumnae, 
		onprobation, offcampus, currentcontact, degreelevelid, degreelevelname,
		degreeid, degreename, studentdegreeid, completed, started, cleared, clearedate,
		graduated, graduatedate, dropout, transferin, transferout,
		sessionid, sessionyear, semester, sstart, slatereg, slatechange, slastdrop, send, active,
		residenceid, residencename, defaultrate, residenceoffcampus, residencesex, residencedean,
		sresidenceid, residenceoption, sstudentid, approved, probation,
		roomnumber, finaceapproval, majorapproval, departapproval, overloadapproval, finalised, printed,		
		hours, gpa, credit, cummcredit, cummgpa, prevsession, newstudent, 
		getprevcredit(studentdegreeid, prevsession) as prevcredit, 
		getprevgpa(studentdegreeid, prevsession) as prevgpa
	FROM vwstudentsessionlist;

CREATE VIEW vwscoursesummarya AS
	SELECT degreelevelid, degreelevelname, crs_schoolid, crs_schoolname, crs_departmentid, crs_departmentname,
		sessionid, scourseid, coursetypeid, coursetypename, courseid, credithours, iscurrent, instructorname, coursetitle, classoption,
		count(sgradeid) as enrolment, sum(chargehours) as sumchargehours
	FROM vwstudentgrades
	WHERE (approved=true) AND (dropped=false) AND (gradeid<>'W') AND (gradeid<>'AW')
	GROUP BY degreelevelid, degreelevelname, crs_schoolid, crs_schoolname, crs_departmentid, crs_departmentname,
		sessionid, scourseid, coursetypeid, coursetypename, courseid, credithours, iscurrent, instructorname, coursetitle, classoption;

CREATE VIEW vwscoursesummaryb AS
	SELECT degreelevelid, degreelevelname, crs_schoolid, crs_schoolname, crs_departmentid, crs_departmentname,
		sessionid, scourseid, coursetypeid, coursetypename, courseid, credithours, iscurrent, instructorname, coursetitle, classoption,
		count(sgradeid) as enrolment, sum(chargehours) as sumchargehours
	FROM studentgradeview
	WHERE (approved=true) AND (dropped=false) AND (gradeid<>'W') AND (gradeid<>'AW')
	GROUP BY degreelevelid, degreelevelname, crs_schoolid, crs_schoolname, crs_departmentid, crs_departmentname,
		sessionid, scourseid, coursetypeid, coursetypename, courseid, credithours, iscurrent, instructorname, coursetitle, classoption;
		
CREATE VIEW vwscoursesummaryc AS
	SELECT crs_schoolid, crs_schoolname, crs_departmentid, crs_departmentname, crs_degreelevelid, crs_degreelevelname,
		sessionid, scourseid, coursetypeid, coursetypename, courseid, credithours, iscurrent, instructorname, coursetitle, classoption,
		count(sgradeid) as enrolment, sum(chargehours) as sumchargehours
	FROM vwstudentgrades
	WHERE (approved=true) AND (dropped=false) AND (gradeid<>'W') AND (gradeid<>'AW')
	GROUP BY crs_schoolid, crs_schoolname, crs_departmentid, crs_departmentname, crs_degreelevelid, crs_degreelevelname,
		sessionid, scourseid, coursetypeid, coursetypename, courseid, credithours, iscurrent, instructorname, coursetitle, classoption;

CREATE VIEW vwsstudentmajorsummary AS
	SELECT schoolid, schoolname, departmentid, departmentname, degreelevelid, degreelevelname, 
		majorid, majorname, major, sex, sessionid, count(studentdegreeid) as studentcount
	FROM vwsstudentmajors
	GROUP BY schoolid, schoolname, departmentid, departmentname, degreelevelid, degreelevelname, 
		majorid, majorname, major, sex, sessionid;

CREATE VIEW vwnationality AS
	SELECT nationality, nationalitycountry
	FROM vwstudents
	GROUP BY nationality, nationalitycountry
	ORDER BY nationalitycountry;

CREATE VIEW vwgender AS
	(SELECT 'M' as sex) UNION (SELECT 'F' as sex);

CREATE VIEW vwssummarya AS
	SELECT sessionid, sessionyear, semester, Sex, count(studentid) as studentcount
	FROM vwsstudents
	WHERE (approved=true)
	GROUP BY sessionid, sessionyear, semester, Sex;
	
CREATE VIEW vwssummaryb AS
	SELECT sessionid, sessionyear, semester, degreelevelname, Sex, count(studentid) as studentcount
	FROM vwsstudents
	WHERE (approved=true)
	GROUP BY sessionid, sessionyear, semester, degreelevelname, Sex;
	
CREATE VIEW vwssummaryc AS
	SELECT sessionyear, Sex, count(studentid) as studentcount
	FROM vwsstudents
	WHERE (approved=true)
	GROUP BY sessionyear, Sex;

CREATE VIEW vwschoolsummary AS
	SELECT sessionid, sessionyear, semester, schoolname, sex, varchar 'School' as "defination", count(sstudentid) as studentcount
	FROM vwsstudents
	WHERE approved=true
	GROUP BY sessionid, sessionyear, semester, schoolname, sex
	ORDER BY sessionid, sessionyear, semester, schoolname, sex;

CREATE VIEW vwlevelsummary AS
	SELECT sessionid, sessionyear, semester, degreelevelname, sex, varchar 'Degree Level' as "defination", count(sstudentid) as studentcount
	FROM vwsstudents
	WHERE approved=true
	GROUP BY sessionid, sessionyear, semester, degreelevelname, sex
	ORDER BY sessionid, sessionyear, semester, degreelevelname, sex;

CREATE VIEW vwnewstudentssummary AS
	SELECT sessionid, sessionyear, semester, (CASE WHEN newstudent=true THEN 'New' ELSE 'Continuing' END) as status, sex, varchar 'Student Status' as "defination", count(sstudentid) as studentcount
	FROM vwstudentsessionsummary
	WHERE approved=true
	GROUP BY sessionid, sessionyear, semester, newstudent, sex
	ORDER BY sessionid, sessionyear, semester, newstudent, sex;

CREATE VIEW vwreligionsummary AS
	SELECT sessionid, sessionyear, semester, religionname, sex, varchar 'Religion' as "defination", count(sstudentid) as studentcount
	FROM vwsstudents
	WHERE approved=true
	GROUP BY sessionid, sessionyear, semester, religionname, sex
	ORDER BY sessionid, sessionyear, semester, religionname, sex;

CREATE VIEW vwdenominationsummary AS
	SELECT sessionid, sessionyear, semester, denominationname, sex, varchar 'Denomination' as "defination", count(sstudentid) as studentcount
	FROM vwsstudents
	WHERE approved=true
	GROUP BY sessionid, sessionyear, semester, denominationname, sex
	ORDER BY sessionid, sessionyear, semester, denominationname, sex;

CREATE VIEW vwnationalitysummary AS
	SELECT sessionid, sessionyear, semester, nationalitycountry, sex, varchar 'Nationality' as "defination", count(sstudentid) as studentcount
	FROM vwsstudents
	WHERE approved=true
	GROUP BY sessionid, sessionyear, semester, nationalitycountry, sex
	ORDER BY sessionid, sessionyear, semester, nationalitycountry, sex;

CREATE VIEW vwresidencesummary AS
	SELECT sessionid, sessionyear, semester, residencename, sex, varchar 'Residence' as "defination", count(sstudentid) as studentcount
	FROM vwsstudents
	WHERE approved=true
	GROUP BY sessionid, sessionyear, semester, residencename, sex
	ORDER BY sessionid, sessionyear, semester, residencename, sex;

CREATE VIEW vwfullsummary AS
	(SELECT * FROM vwschoolsummary) UNION
	(SELECT * FROM vwlevelsummary) UNION
	(SELECT * FROM vwnewstudentssummary) UNION
	(SELECT * FROM vwreligionsummary) UNION
	(SELECT * FROM vwdenominationsummary) UNION
	(SELECT * FROM vwnationalitysummary) UNION
	(SELECT * FROM vwresidencesummary);

CREATE VIEW vwsessionstats AS
	(SELECT 1 as statid, schoolname, sessionid, text 'Opened Applications' AS "narrative", count(sstudentid) AS studentcount 
		FROM vwsstudentcharges GROUP BY schoolname, sessionid)
	UNION
	(SELECT 2, schoolname, sessionid, text 'Cleared Balance' AS "narrative", count(sstudentid) 
		FROM vwsstudentbalances WHERE (finalbalance >= (-2000))  GROUP BY schoolname, sessionid)
	UNION
	(SELECT 3, schoolname, sessionid, text 'Cleared Balance and Financially Approved' AS "narrative", count(sstudentid) 
		FROM vwsstudentbalances WHERE (finalbalance >= (-2000)) AND (finaceapproval = true)  GROUP BY schoolname, sessionid)
	UNION
	(SELECT 4, schoolname, sessionid, text 'Financially Approved' AS "narrative", count(sstudentid) 
		FROM vwsstudentbalances WHERE (finaceapproval = true) GROUP BY schoolname, sessionid)
	UNION
	(SELECT 5, schoolname, sessionid, text 'Closed Applications' AS "narrative", count(sstudentid) 
		FROM vwsstudentcharges WHERE (finalised = true) GROUP BY schoolname, sessionid)
	UNION
	(SELECT 6, schoolname, sessionid, text 'Printed Applications' AS "narrative", count(sstudentid) 
		FROM vwsstudentcharges WHERE (printed = true) GROUP BY schoolname, sessionid)
	UNION
	(SELECT 7, schoolname, sessionid, text 'Fully Registered' AS "narrative", count(sstudentid) 
		FROM vwsstudentcharges WHERE (approved = true) GROUP BY schoolname, sessionid);

CREATE VIEW vwsessionlevelstats AS
	(SELECT 1 as statid, schoolname, sessionid, studylevel, text 'Opened Applications' AS "narrative", count(sstudentid) AS studentcount 
		FROM vwsstudentcharges GROUP BY schoolname, sessionid, studylevel)
	UNION
	(SELECT 2, schoolname, sessionid, studylevel, text 'Cleared Balance' AS "narrative", count(sstudentid) 
		FROM vwsstudentbalances WHERE (finalbalance >= (-2000))  GROUP BY schoolname, sessionid, studylevel)
	UNION
	(SELECT 3, schoolname, sessionid, studylevel, text 'Cleared Balance and Financially Approved' AS "narrative", count(sstudentid) 
		FROM vwsstudentbalances WHERE (finalbalance >= (-2000)) AND (finaceapproval = true)  GROUP BY schoolname, sessionid, studylevel)
	UNION
	(SELECT 4, schoolname, sessionid, studylevel, text 'Financially Approved' AS "narrative", count(sstudentid) 
		FROM vwsstudentbalances WHERE (finaceapproval = true) GROUP BY schoolname, sessionid, studylevel)
	UNION
	(SELECT 5, schoolname, sessionid, studylevel, text 'Closed Applications' AS "narrative", count(sstudentid) 
		FROM vwsstudentcharges WHERE (finalised = true) GROUP BY schoolname, sessionid, studylevel)
	UNION
	(SELECT 6, schoolname, sessionid, studylevel, text 'Printed Applications' AS "narrative", count(sstudentid) 
		FROM vwsstudentcharges WHERE (printed = true) GROUP BY schoolname, sessionid, studylevel)
	UNION
	(SELECT 7, schoolname, sessionid, studylevel, text 'Fully Registered' AS "narrative", count(sstudentid) 
		FROM vwsstudentcharges WHERE (approved = true) GROUP BY schoolname, sessionid, studylevel);

CREATE VIEW vwsessionmajorstats AS
	(SELECT 1 as statid, schoolname, sessionid, studylevel, majorname, text 'Started Registration ' AS "narrative", count(sstudentid) AS studentcount 
		FROM vwsstudentcharges GROUP BY schoolname, sessionid, studylevel,majorname)
	UNION
	(SELECT 2, schoolname, sessionid, studylevel, majorname, text 'Without Balance' AS "narrative", count(sstudentid) 
		FROM vwsstudentbalances WHERE (finalbalance >= (-2000))  GROUP BY schoolname, sessionid, studylevel,majorname)
	UNION
	(SELECT 3, schoolname, sessionid, studylevel, majorname, text 'Without Balance and Financially Approved' AS "narrative", count(sstudentid) 
		FROM vwsstudentbalances WHERE (finalbalance >= (-2000)) AND (finaceapproval = true)  GROUP BY schoolname, sessionid, studylevel,majorname)
	UNION
	(SELECT 4, schoolname, sessionid, studylevel, majorname, text 'Financially Approved' AS "narrative", count(sstudentid) 
		FROM vwsstudentbalances WHERE (finaceapproval = true) GROUP BY schoolname, sessionid, studylevel,majorname)
	UNION
	(SELECT 5, schoolname, sessionid, studylevel, majorname, text 'Submitted Course Form for Approval' AS "narrative", count(sstudentid) 
		FROM vwsstudentcharges WHERE (finalised = true) GROUP BY schoolname, sessionid, studylevel,majorname)
	UNION
	(SELECT 6, schoolname, sessionid, studylevel,majorname, text 'Printed Applications' AS "narrative", count(sstudentid) 
		FROM vwsstudentcharges WHERE (printed = true) GROUP BY schoolname, sessionid, studylevel,majorname)
	UNION
	(SELECT 7, schoolname, sessionid, studylevel,majorname,  text 'Fully Registered' AS "narrative", count(sstudentid) 
		FROM vwsstudentcharges WHERE (approved = true) GROUP BY schoolname, sessionid, studylevel,majorname);

CREATE OR REPLACE FUNCTION getsstudentid(int, varchar(12)) RETURNS int AS $$
	SELECT max(sstudents.sstudentid)
	FROM sstudents
	WHERE (studentdegreeid = $1) AND (sessionid = $2);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION checkincomplete(int) RETURNS bigint AS $$
	SELECT count(sgrades.sgradeid)
	FROM sgrades INNER JOIN sstudents ON sgrades.sstudentid = sstudents.sstudentid
	WHERE (sstudents.sstudentid = $1) AND (sstudents.approved = true)
		AND (sgrades.gradeid = 'IW') AND (sgrades.dropped = false);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION checkgrade(int, float) RETURNS bigint AS $$
	SELECT count(sgrades.sgradeid)
	FROM (sgrades INNER JOIN sstudents ON sgrades.sstudentid = sstudents.sstudentid)
	INNER JOIN grades ON sgrades.gradeid = grades.gradeid
	WHERE (sstudents.sstudentid = $1) AND (sstudents.approved = true) AND (sgrades.dropped = false)
		AND (grades.gradeweight < $2) AND (grades.gpacount = true);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION checkgrade(int, varchar(10), float) RETURNS bigint AS $$
	SELECT count(sgrades.sgradeid)
	FROM (sgrades INNER JOIN sstudents ON sgrades.sstudentid = sstudents.sstudentid)
	INNER JOIN grades ON sgrades.gradeid = grades.gradeid
	WHERE (sstudents.studentdegreeid = $1) AND (substring(sstudents.sessionid from 1 for 9) = $2) AND (sstudents.approved = true)
		AND (sgrades.dropped = false) AND (grades.gradeweight < $3) AND (grades.gpacount = true);
$$ LANGUAGE SQL;

