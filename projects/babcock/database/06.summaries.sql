CREATE OR REPLACE FUNCTION getprevquarter(int, varchar(12)) RETURNS varchar(12) AS $$
	SELECT max(qstudents.quarterid)
	FROM qstudents
	WHERE (qstudents.studentdegreeid = $1) AND (qstudents.quarterid < $2) AND (qstudents.approved = true);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getprevcredit(int, varchar(12)) RETURNS float AS $$
	SELECT sum(qgrades.credit)
	FROM (qgrades INNER JOIN qstudents ON qgrades.qstudentid = qstudents.qstudentid)
		INNER JOIN grades ON qgrades.gradeid = grades.gradeid
	WHERE (qstudents.studentdegreeid = $1) AND (qstudents.quarterid = $2) AND (qgrades.dropped = false)
		AND (grades.gpacount = true) AND (qgrades.repeated = false) AND (qgrades.gradeid <> 'W') AND (qgrades.gradeid <> 'AW')
		 AND (qstudents.approved = true);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getprevgpa(int, varchar(12)) RETURNS float AS $$
	SELECT (CASE sum(qgrades.credit) WHEN 0 THEN 0 ELSE (sum(grades.gradeweight * qgrades.credit)/sum(qgrades.credit)) END)
	FROM (qgrades INNER JOIN qstudents ON qgrades.qstudentid = qstudents.qstudentid)
		INNER JOIN grades ON qgrades.gradeid = grades.gradeid
	WHERE (qstudents.studentdegreeid = $1) AND (qstudents.quarterid = $2) AND (qgrades.dropped = false)
		AND (grades.gpacount = true) AND (qgrades.repeated = false) AND (qgrades.gradeid <> 'W') AND (qgrades.gradeid <> 'AW')
		AND (qstudents.approved = true);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getcurrhours(int) RETURNS float AS $$
	SELECT sum(qgrades.hours)
	FROM qgrades INNER JOIN qstudents ON qgrades.qstudentid = qstudents.qstudentid
	WHERE (qgrades.qstudentid = $1) AND (qgrades.dropped = false) AND (qgrades.gradeid <> 'W') AND (qgrades.gradeid <> 'AW')
		AND (qstudents.approved = true);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getcurrcredit(int) RETURNS float AS $$
	SELECT sum(qgrades.credit)
	FROM qgrades INNER JOIN grades ON qgrades.gradeid = grades.gradeid
		INNER JOIN qstudents ON qgrades.qstudentid = qstudents.qstudentid
	WHERE (qgrades.qstudentid = $1) AND (grades.gpacount = true) AND (qgrades.dropped = false) 
		AND (qgrades.repeated = false) AND (qgrades.gradeid <> 'W') AND (qgrades.gradeid <> 'AW')
		AND (qstudents.approved = true);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getcurrgpa(int) RETURNS float AS $$
	SELECT (CASE sum(qgrades.credit) WHEN 0 THEN 0 ELSE (sum(grades.gradeweight * qgrades.credit)/sum(qgrades.credit)) END)
	FROM qgrades INNER JOIN grades ON qgrades.gradeid = grades.gradeid
		INNER JOIN qstudents ON qgrades.qstudentid = qstudents.qstudentid
	WHERE (qgrades.qstudentid = $1)	AND (grades.gpacount = true) AND (qgrades.dropped = false) 
		AND (qgrades.repeated = false) AND (qgrades.gradeid <> 'W') AND (qgrades.gradeid <> 'AW')
		AND (qstudents.approved = true);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getcummcredit(int, varchar(12)) RETURNS float AS $$
	SELECT sum(qgrades.credit)
	FROM (qgrades INNER JOIN qstudents ON qgrades.qstudentid = qstudents.qstudentid)
		INNER JOIN grades ON qgrades.gradeid = grades.gradeid
	WHERE (qstudents.studentdegreeid = $1) AND (qstudents.quarterid <= $2) AND (qgrades.dropped = false)
		AND (grades.gpacount = true) AND (qgrades.repeated = false) AND (qgrades.gradeid <> 'W') AND (qgrades.gradeid <> 'AW')
		AND (qstudents.approved = true);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getcummgpa(int, varchar(12)) RETURNS float AS $$
	SELECT (CASE sum(qgrades.credit) WHEN 0 THEN 0 ELSE (sum(grades.gradeweight * qgrades.credit)/sum(qgrades.credit)) END)
	FROM (qgrades INNER JOIN qstudents ON qgrades.qstudentid = qstudents.qstudentid)
		INNER JOIN grades ON qgrades.gradeid = grades.gradeid
	WHERE (qstudents.studentdegreeid = $1) AND (qstudents.quarterid <= $2) AND (qgrades.dropped = false)
		AND (grades.gpacount = true) AND (qgrades.repeated = false) AND (qgrades.gradeid <> 'W') AND (qgrades.gradeid <> 'AW')
		AND (qstudents.approved = true);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_curr_score(int) RETURNS float AS $$
	SELECT (CASE sum(qgrades.credit) WHEN 0 THEN 0 
	ELSE (sum(get_grade_weight(round(finalmarks)::integer, qgrades.org_id) * qgrades.credit) / sum(qgrades.credit)) END)
	FROM qgrades 
	WHERE (qgrades.qstudentid = $1) AND (qgrades.dropped = false) 
		AND (qgrades.repeated = false) AND (qgrades.gradeid <> 'W') AND (qgrades.gradeid <> 'AW');
$$ LANGUAGE SQL;

CREATE VIEW qstudentsummary AS
	SELECT qsd.studentid, qsd.studentname, qsd.quarterid, qsd.approved, qsd.studentdegreeid, qsd.qstudentid,
		qsd.sex, qsd.Nationality, qsd.MaritalStatus, qsd.studylevel, qsd.org_id,
		getcurrcredit(qsd.qstudentid) as credit, getcurrgpa(qsd.qstudentid) as gpa,
		getcummcredit(qsd.studentdegreeid, qsd.quarterid) as cummcredit,
		getcummgpa(qsd.studentdegreeid, qsd.quarterid) as cummgpa, 
		quarters.publishgrades
	FROM qstudentdegreeview as qsd INNER JOIN quarters ON qsd.quarterid = quarters.quarterid;

CREATE VIEW studentquarterlist AS
	SELECT religionid, religionname, denominationid, denominationname, schoolid, schoolname, studentid, studentname, address, zipcode,
		town, addresscountry, telno, email,  guardianname, gaddress, gzipcode, gtown, gaddresscountry, gtelno, gemail,
		accountnumber, Nationality, Nationalitycountry, Sex, MaritalStatus, birthdate, firstpasswd, alumnae, postcontacts,
		onprobation, offcampus, currentcontact, degreelevelid, degreelevelname,
		levellocationid, levellocationname, sublevelid, sublevelname, 
		degreeid, degreename, studentdegreeid, completed, started, cleared, clearedate,
		graduated, graduatedate, dropout, transferin, transferout, 
		quarterid, quarteryear, quarter, qstart, qlatereg, qlatechange, qlastdrop,
		qend, active,
		residenceid, residencename, defaultrate, residenceoffcampus, residencesex, residencedean,
		qresidenceid, residenceoption, qstudentid, approved, probation,
		roomnumber, finaceapproval, majorapproval, departapproval, overloadapproval, finalised, printed,
		getcurrhours(qstudentid) as hours,		
		getcurrcredit(qstudentid) as credit, 
		getcurrgpa(qstudentid) as gpa,
		getcummcredit(studentdegreeid, quarterid) as cummcredit,
		getcummgpa(studentdegreeid, quarterid) as cummgpa,
		getprevquarter(studentdegreeid, quarterid) as prevquarter,
		(CASE WHEN (getprevquarter(studentdegreeid, quarterid) is null) THEN true ELSE false END) as newstudent
	FROM qstudentview;

CREATE VIEW studentquartersummary AS
	SELECT religionid, religionname, denominationid, denominationname, schoolid, schoolname, studentid, studentname, address, zipcode,
		town, addresscountry, telno, email,  guardianname, gaddress, gzipcode, gtown, gaddresscountry, gtelno, gemail,
		accountnumber, Nationality, Nationalitycountry, Sex, MaritalStatus, birthdate, firstpasswd, alumnae, postcontacts,
		onprobation, offcampus, currentcontact, degreelevelid, degreelevelname,
		levellocationid, levellocationname, sublevelid, sublevelname,
		degreeid, degreename, studentdegreeid, completed, started, cleared, clearedate,
		graduated, graduatedate, dropout, transferin, transferout,
		quarterid, quarteryear, quarter, qstart, qlatereg, qlatechange, qlastdrop,
		qend, active,
		residenceid, residencename, defaultrate, residenceoffcampus, residencesex, residencedean,
		qresidenceid, residenceoption, qstudentid, approved, probation,
		roomnumber, finaceapproval, majorapproval, departapproval, overloadapproval, finalised, printed,		
		hours, gpa, credit, cummcredit, cummgpa, prevquarter, newstudent, 
		getprevcredit(studentdegreeid, prevquarter) as prevcredit, 
		getprevgpa(studentdegreeid, prevquarter) as prevgpa
	FROM studentquarterlist;

CREATE VIEW qcoursesummarya AS
	SELECT degreelevelid, degreelevelname, levellocationid, levellocationname, sublevelid, sublevelname,
		crs_schoolid, crs_schoolname, crs_departmentid, crs_departmentname,
		quarterid, qcourseid, coursetypeid, coursetypename, courseid, credithours, iscurrent, instructorname, coursetitle, classoption,
		count(qgradeid) as enrolment, sum(chargehours) as sumchargehours
	FROM studentgradeview
	WHERE (approved = true) AND (dropped = false) AND (gradeid <> 'W') AND (gradeid <> 'AW')
	GROUP BY degreelevelid, degreelevelname, levellocationid, levellocationname, sublevelid, sublevelname,
		crs_schoolid, crs_schoolname, crs_departmentid, crs_departmentname,
		quarterid, qcourseid, coursetypeid, coursetypename, courseid, credithours, iscurrent, instructorname, coursetitle, classoption;

CREATE VIEW qcoursesummaryb AS
	SELECT degreelevelid, degreelevelname, crs_schoolid, crs_schoolname, crs_departmentid, crs_departmentname,
		quarterid, qcourseid, coursetypeid, coursetypename, courseid, credithours, iscurrent, instructorname, coursetitle, classoption,
		count(qgradeid) as enrolment, sum(chargehours) as sumchargehours
	FROM studentgradeview
	WHERE (approved=true) AND (dropped=false) AND (gradeid<>'W') AND (gradeid<>'AW')
	GROUP BY degreelevelid, degreelevelname, crs_schoolid, crs_schoolname, crs_departmentid, crs_departmentname,
		quarterid, qcourseid, coursetypeid, coursetypename, courseid, credithours, iscurrent, instructorname, coursetitle, classoption;
		
CREATE VIEW qcoursesummaryc AS
	SELECT crs_schoolid, crs_schoolname, crs_departmentid, crs_departmentname, crs_degreelevelid, crs_degreelevelname,
		quarterid, qcourseid, coursetypeid, coursetypename, courseid, credithours, iscurrent, instructorname, coursetitle, classoption,
		count(qgradeid) as enrolment, sum(chargehours) as sumchargehours
	FROM studentgradeview
	WHERE (approved=true) AND (dropped=false) AND (gradeid<>'W') AND (gradeid<>'AW')
	GROUP BY crs_schoolid, crs_schoolname, crs_departmentid, crs_departmentname, crs_degreelevelid, crs_degreelevelname,
		quarterid, qcourseid, coursetypeid, coursetypename, courseid, credithours, iscurrent, instructorname, coursetitle, classoption;

CREATE VIEW qstudentmajorsummary AS
	SELECT qstudentmajorview.schoolid, qstudentmajorview.schoolname, qstudentmajorview.departmentid, qstudentmajorview.departmentname,
		qstudentmajorview.degreelevelid, qstudentmajorview.degreelevelname, qstudentmajorview.sublevelid, qstudentmajorview.sublevelname,
		qstudentmajorview.majorid, qstudentmajorview.majorname, qstudentmajorview.premajor, qstudentmajorview.major,
		qstudentmajorview.sex, qstudentmajorview.quarterid, count(qstudentmajorview.studentdegreeid) as studentcount
	FROM qstudentmajorview
	GROUP BY qstudentmajorview.schoolid, qstudentmajorview.schoolname, qstudentmajorview.departmentid, qstudentmajorview.departmentname,
		qstudentmajorview.degreelevelid, qstudentmajorview.degreelevelname, qstudentmajorview.sublevelid, qstudentmajorview.sublevelname,
		qstudentmajorview.majorid, qstudentmajorview.majorname, qstudentmajorview.premajor, qstudentmajorview.major,
		qstudentmajorview.sex, qstudentmajorview.quarterid;

CREATE VIEW vwqstudentmajorlist AS
	SELECT departmentid, departmentname, majorid, majorname, studylevel, studentid, studentname,
		getcummcredit(studentdegreeid, quarterid) as cummcredit,
		getcummgpa(studentdegreeid, quarterid) as cummgpa
	FROM qstudentmajorview;

CREATE VIEW quartersexstats AS
	SELECT quarterid, schoolid, schoolname, departmentid, departmentname, 
		majorid, majorname, studylevel, sex, count(qstudentid) as studentcount
	FROM qstudentmajorview
	GROUP BY quarterid, schoolid, schoolname, departmentid, departmentname, 
		majorid, majorname, studylevel, sex;

CREATE VIEW nationalityview AS
	SELECT nationality, nationalitycountry
	FROM studentview
	GROUP BY nationality, nationalitycountry
	ORDER BY nationalitycountry;

CREATE VIEW sexview AS
	(SELECT 'M' as sex) UNION (SELECT 'F' as sex);

CREATE VIEW qsummaryaview AS
	SELECT quarterid, quarteryear, quarter, Sex, count(studentid) as studentcount
	FROM qstudentview
	WHERE (approved=true)
	GROUP BY quarterid, quarteryear, quarter, Sex;
	
CREATE VIEW qsummarybview AS
	SELECT quarterid, quarteryear, quarter, degreelevelname, Sex, count(studentid) as studentcount
	FROM qstudentview
	WHERE (approved=true)
	GROUP BY quarterid, quarteryear, quarter, degreelevelname, Sex;
	
CREATE VIEW qsummarycview AS
	SELECT quarterid, quarteryear, quarter, sublevelname, Sex, count(studentid) as studentcount
	FROM qstudentview
	WHERE (approved=true)
	GROUP BY quarterid, quarteryear, quarter, sublevelname, Sex;

CREATE VIEW qsummarydview AS
	SELECT quarteryear, Sex, count(studentid) as studentcount
	FROM qstudentview
	WHERE (approved=true)
	GROUP BY quarteryear, Sex;

CREATE VIEW schoolsummary AS
	SELECT quarterid, quarteryear, quarter, schoolname, sex, varchar 'School' as "defination", count(qstudentid) as studentcount
	FROM qstudentview
	WHERE approved=true
	GROUP BY quarterid, quarteryear, quarter, schoolname, sex
	ORDER BY quarterid, quarteryear, quarter, schoolname, sex;

CREATE VIEW levelsummary AS
	SELECT quarterid, quarteryear, quarter, degreelevelname, sex, varchar 'Degree Level' as "defination", count(qstudentid) as studentcount
	FROM qstudentview
	WHERE approved=true
	GROUP BY quarterid, quarteryear, quarter, degreelevelname, sex
	ORDER BY quarterid, quarteryear, quarter, degreelevelname, sex;

CREATE VIEW sublevelsummary AS
	SELECT quarterid, quarteryear, quarter, sublevelname, sex, varchar 'Sub Level' as "defination", count(qstudentid) as studentcount
	FROM qstudentview
	WHERE approved=true
	GROUP BY quarterid, quarteryear, quarter, sublevelname, sex
	ORDER BY quarterid, quarteryear, quarter, sublevelname, sex;

CREATE VIEW newstudentssummary AS
	SELECT quarterid, quarteryear, quarter, (CASE WHEN newstudent=true THEN 'New' ELSE 'Continuing' END) as status, sex, varchar 'Student Status' as "defination", count(qstudentid) as studentcount
	FROM studentquartersummary
	WHERE approved=true
	GROUP BY quarterid, quarteryear, quarter, newstudent, sex
	ORDER BY quarterid, quarteryear, quarter, newstudent, sex;

CREATE VIEW religionsummary AS
	SELECT quarterid, quarteryear, quarter, religionname, sex, varchar 'Religion' as "defination", count(qstudentid) as studentcount
	FROM qstudentview
	WHERE approved=true
	GROUP BY quarterid, quarteryear, quarter, religionname, sex
	ORDER BY quarterid, quarteryear, quarter, religionname, sex;

CREATE VIEW denominationsummary AS
	SELECT quarterid, quarteryear, quarter, denominationname, sex, varchar 'Denomination' as "defination", count(qstudentid) as studentcount
	FROM qstudentview
	WHERE approved=true
	GROUP BY quarterid, quarteryear, quarter, denominationname, sex
	ORDER BY quarterid, quarteryear, quarter, denominationname, sex;

CREATE VIEW nationalitysummary AS
	SELECT quarterid, quarteryear, quarter, nationalitycountry, sex, varchar 'Nationality' as "defination", count(qstudentid) as studentcount
	FROM qstudentview
	WHERE approved=true
	GROUP BY quarterid, quarteryear, quarter, nationalitycountry, sex
	ORDER BY quarterid, quarteryear, quarter, nationalitycountry, sex;

CREATE VIEW residencesummary AS
	SELECT quarterid, quarteryear, quarter, residencename, sex, varchar 'Residence' as "defination", count(qstudentid) as studentcount
	FROM studentquarterview
	WHERE approved=true
	GROUP BY quarterid, quarteryear, quarter, residencename, sex
	ORDER BY quarterid, quarteryear, quarter, residencename, sex;

CREATE VIEW fullsummary AS
	(SELECT * FROM schoolsummary) UNION
	(SELECT * FROM levelsummary) UNION
	(SELECT * FROM sublevelsummary) UNION
	(SELECT * FROM newstudentssummary) UNION
	(SELECT * FROM religionsummary) UNION
	(SELECT * FROM denominationsummary) UNION
	(SELECT * FROM nationalitysummary) UNION
	(SELECT * FROM residencesummary);

CREATE VIEW mealstats AS
	SELECT 1 as statid,  quarterid,finaceapproval, mealtype, 'Student Mealtype'::text AS "narrative", count(qstudentid) AS studentcount 
	FROM vwqstudentbalances WHERE (finaceapproval = true) GROUP BY quarterid, mealtype, finaceapproval;

CREATE VIEW premiumstats AS
	SELECT 1 as statid,  quarterid,finaceapproval, premiumhall, Sex, 'Premium Hall'::text AS "narrative", count(qstudentid) AS studentcount 
	FROM vwqstudentbalances WHERE (finaceapproval = true) GROUP BY quarterid, sex, premiumhall, finaceapproval;

CREATE VIEW quarterstats AS
	(SELECT 1 as statid, schoolname, quarterid, 'Opened Applications'::text AS "narrative", count(qstudentid) AS studentcount 
		FROM qstudentview GROUP BY schoolname, quarterid)
	UNION
	(SELECT 2, schoolname, quarterid, 'Cleared Balance'::text AS "narrative", count(qstudentid) 
		FROM vwqstudentbalances WHERE (finalbalance >= (-2000))  GROUP BY schoolname, quarterid)
	UNION
	(SELECT 3, schoolname, quarterid, 'Cleared Balance and Financially Approved'::text AS "narrative", count(qstudentid) 
		FROM vwqstudentbalances WHERE (finalbalance >= (-2000)) AND (finaceapproval = true)  GROUP BY schoolname, quarterid)
	UNION
	(SELECT 4, schoolname, quarterid, 'Financially Approved'::text AS "narrative", count(qstudentid) 
		FROM vwqstudentbalances WHERE (finaceapproval = true) GROUP BY schoolname, quarterid)
	UNION
	(SELECT 5, schoolname, quarterid, 'Closed Applications'::text AS "narrative", count(qstudentid) 
		FROM qstudentview WHERE (finalised = true) GROUP BY schoolname, quarterid)
	UNION
	(SELECT 6, schoolname, quarterid, 'Printed Applications'::text AS "narrative", count(qstudentid) 
		FROM qstudentview WHERE (printed = true) GROUP BY schoolname, quarterid)
	UNION
	(SELECT 7, schoolname, quarterid, 'Fully Registered'::text AS "narrative", count(qstudentid) 
		FROM qstudentview WHERE (approved = true) GROUP BY schoolname, quarterid);

CREATE VIEW quarterlevelstats AS
	(SELECT 1 as statid, schoolname, quarterid, studylevel, 'Opened Applications'::text AS "narrative", count(qstudentid) AS studentcount 
		FROM qstudentview GROUP BY schoolname, quarterid, studylevel)
	UNION
	(SELECT 2, schoolname, quarterid, studylevel, 'Cleared Balance'::text AS "narrative", count(qstudentid) 
		FROM vwqstudentbalances WHERE (finalbalance >= (-2000))  GROUP BY schoolname, quarterid, studylevel)
	UNION
	(SELECT 3, schoolname, quarterid, studylevel, 'Cleared Balance and Financially Approved'::text AS "narrative", count(qstudentid) 
		FROM vwqstudentbalances WHERE (finalbalance >= (-2000)) AND (finaceapproval = true)  GROUP BY schoolname, quarterid, studylevel)
	UNION
	(SELECT 4, schoolname, quarterid, studylevel, 'Financially Approved'::text AS "narrative", count(qstudentid) 
		FROM vwqstudentbalances WHERE (finaceapproval = true) GROUP BY schoolname, quarterid, studylevel)
	UNION
	(SELECT 5, schoolname, quarterid, studylevel, 'Closed Applications'::text AS "narrative", count(qstudentid) 
		FROM qstudentview WHERE (finalised = true) GROUP BY schoolname, quarterid, studylevel)
	UNION
	(SELECT 6, schoolname, quarterid, studylevel, 'Printed Applications'::text AS "narrative", count(qstudentid) 
		FROM qstudentview WHERE (printed = true) GROUP BY schoolname, quarterid, studylevel)
	UNION
	(SELECT 7, schoolname, quarterid, studylevel, 'Fully Registered'::text AS "narrative", count(qstudentid) 
		FROM qstudentview WHERE (approved = true) GROUP BY schoolname, quarterid, studylevel);

CREATE VIEW quartermajorstats AS
	(SELECT 1 as statid, schoolname, quarterid, studylevel, majorname, 'Started Registration'::text AS "narrative", count(qstudentid) AS studentcount 
		FROM vwqstudentcharges GROUP BY schoolname, quarterid, studylevel,majorname)
	UNION
	(SELECT 2, schoolname, quarterid, studylevel, majorname, 'Without Balance'::text AS "narrative", count(qstudentid) 
		FROM vwqstudentbalances WHERE (finalbalance >= (-2000))  GROUP BY schoolname, quarterid, studylevel,majorname)
	UNION
	(SELECT 3, schoolname, quarterid, studylevel, majorname, 'Without Balance and Financially Approved'::text AS "narrative", count(qstudentid) 
		FROM vwqstudentbalances WHERE (finalbalance >= (-2000)) AND (finaceapproval = true)  GROUP BY schoolname, quarterid, studylevel,majorname)
	UNION
	(SELECT 4, schoolname, quarterid, studylevel, majorname, 'Financially Approved'::text AS "narrative", count(qstudentid) 
		FROM vwqstudentbalances WHERE (finaceapproval = true) GROUP BY schoolname, quarterid, studylevel,majorname)
	UNION
	(SELECT 5, schoolname, quarterid, studylevel, majorname, 'Submitted Course Form for Approval'::text AS "narrative", count(qstudentid) 
		FROM vwqstudentcharges WHERE (finalised = true) GROUP BY schoolname, quarterid, studylevel,majorname)
	UNION
	(SELECT 6, schoolname, quarterid, studylevel,majorname, 'Printed Applications'::text AS "narrative", count(qstudentid) 
		FROM vwqstudentcharges WHERE (printed = true) GROUP BY schoolname, quarterid, studylevel,majorname)
	UNION
	(SELECT 7, schoolname, quarterid, studylevel,majorname,  'Fully Registered'::text AS "narrative", count(qstudentid) 
		FROM vwqstudentcharges WHERE (approved = true) GROUP BY schoolname, quarterid, studylevel,majorname);

CREATE OR REPLACE FUNCTION getqstudentid(int, varchar(12)) RETURNS int AS $$
	SELECT max(qstudents.qstudentid)
	FROM qstudents
	WHERE (studentdegreeid = $1) AND (quarterid = $2);
$$ LANGUAGE SQL;

CREATE VIEW studentsyearlist AS
	SELECT qstudentlist.studentid, qstudentlist.studentname, qstudentlist.Sex, qstudentlist.Nationality, qstudentlist.MaritalStatus,
		qstudentlist.birthdate, qstudentlist.studentdegreeid, qstudentlist.degreeid, qstudentlist.sublevelid,
		academicyear, count(qstudentlist.qstudentid) as quartersdone,
		getqstudentid(qstudentlist.studentdegreeid, academicyear || '.1') as qstudent1, 
		getqstudentid(qstudentlist.studentdegreeid, academicyear || '.2') as qstudent2,
		getqstudentid(qstudentlist.studentdegreeid, academicyear || '.3') as qstudent3,
		getqstudentid(qstudentlist.studentdegreeid, academicyear || '.4') as qstudent4
	FROM qstudentlist 
	WHERE (qstudentlist.approved = true) AND (getcurrcredit(qstudentlist.qstudentid) >= 12)
	GROUP BY qstudentlist.studentid, qstudentlist.studentname, qstudentlist.Sex, qstudentlist.Nationality, qstudentlist.MaritalStatus,
		qstudentlist.birthdate, qstudentlist.studentdegreeid, qstudentlist.degreeid, qstudentlist.sublevelid, academicyear;

CREATE OR REPLACE FUNCTION checkincomplete(int) RETURNS bigint AS $$
	SELECT count(qgrades.qgradeid)
	FROM qgrades INNER JOIN qstudents ON qgrades.qstudentid = qstudents.qstudentid
	WHERE (qstudents.qstudentid = $1) AND (qstudents.approved = true)
		AND (qgrades.gradeid = 'IW') AND (qgrades.dropped = false);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION checkgrade(int, float) RETURNS bigint AS $$
	SELECT count(qgrades.qgradeid)
	FROM (qgrades INNER JOIN qstudents ON qgrades.qstudentid = qstudents.qstudentid)
	INNER JOIN grades ON qgrades.gradeid = grades.gradeid
	WHERE (qstudents.qstudentid = $1) AND (qstudents.approved = true) AND (qgrades.dropped = false)
		AND (grades.gradeweight < $2) AND (grades.gpacount = true);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION checkgrade(int, varchar(10), float) RETURNS bigint AS $$
	SELECT count(qgrades.qgradeid)
	FROM (qgrades INNER JOIN qstudents ON qgrades.qstudentid = qstudents.qstudentid)
	INNER JOIN grades ON qgrades.gradeid = grades.gradeid
	WHERE (qstudents.studentdegreeid = $1) AND (substring(qstudents.quarterid from 1 for 9) = $2) AND (qstudents.approved = true)
		AND (qgrades.dropped = false) AND (grades.gradeweight < $3) AND (grades.gpacount = true);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION checkhonors(float, float, float, float) RETURNS int AS $$
DECLARE
	myhonors int;
	gpa float;
	pgpa float;
	i int;
BEGIN
	myhonors := 0;

	pgpa := 0;
	FOR i IN 1..4 LOOP
		if(i = 1) then gpa := $1; end if;
		if(i = 2) then gpa := $2; end if;
		if(i = 3) then gpa := $3; end if;
		if(i = 4) then gpa := $4; end if;

		IF (gpa IS NOT NULL) THEN
    		IF ((gpa >= 3.5) AND (pgpa >= 3.5)) THEN
				myhonors := myhonors + 1;
			END IF;
			pgpa := gpa; 
		END IF;
	END LOOP;

    RETURN myhonors;
END;
$$ LANGUAGE plpgsql;

CREATE VIEW honorslist AS
	SELECT studentid, studentname, Sex, Nationality, MaritalStatus, birthdate, studentdegreeid, degreeid, sublevelid,
		academicyear, quartersdone, qstudent1, qstudent2, qstudent3, qstudent4,
		getcurrgpa(qstudent1) as gpa1, getcurrgpa(qstudent2) as gpa2, getcurrgpa(qstudent3) as gpa3, getcurrgpa(qstudent4) as gpa4,
		getcummgpa(studentdegreeid, academicyear || '.1') as cummgpa1, getcummgpa(studentdegreeid, academicyear || '.2') as cummgpa2,
		getcummgpa(studentdegreeid, academicyear || '.3') as cummgpa3, getcummgpa(studentdegreeid, academicyear || '.4') as cummgpa4
	FROM studentsyearlist 
	WHERE (quartersdone >  1) AND (checkgrade(studentdegreeid, academicyear, 2.67) = 0);

CREATE VIEW honorsview AS
	SELECT studentid, studentname, Sex, Nationality, MaritalStatus, birthdate, studentdegreeid, degreeid, sublevelid,
		academicyear, quartersdone, qstudent1, qstudent2, qstudent3, qstudent4,
		gpa1, gpa2, gpa3, gpa4, cummgpa1, cummgpa2, cummgpa3, cummgpa4,
		checkhonors(gpa1, gpa2, gpa3, gpa4) as gpahonors,
		checkhonors(cummgpa1, cummgpa2, cummgpa3, cummgpa4) as cummgpahonours
	FROM honorslist;


