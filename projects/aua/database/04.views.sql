DROP VIEW tomcatusers;
CREATE VIEW tomcatusers AS 
	(SELECT username, userpasswd, rolename FROM users)
	UNION
	(SELECT instructorid, userpasswd, 'instructor' FROM instructors)
	UNION
	(SELECT studentid, userpasswd, 'student' FROM students WHERE alumnae = false)
	UNION
	(SELECT studentid, userpasswd, 'alumnae' FROM students WHERE alumnae = true)
	UNION
	(SELECT 'SP' || cast(sponsorid as varchar(12)), userpasswd, 'sponsor' FROM sponsors WHERE active = true)
	UNION
	(SELECT email, userpasswd, 'applicant' FROM applications WHERE closed = false)
	UNION
	(SELECT email, userpasswd, 'employer' FROM employers WHERE approved = true);

CREATE VIEW vwregistrations AS
	SELECT registrations.registrationid, registrations.applicationid, registrations.email, registrations.submitapplication, 
		registrations.isaccepted, registrations.isreported, registrations.isdeferred, registrations.isrejected,
		registrations.applicationdate, getcountryname(registrations.nationalityid) as nationality,
		registrations.sex, registrations.surname, registrations.firstname, registrations.othernames, 
		(registrations.surname || ', ' ||  registrations.firstname || ' ' || registrations.othernames) as fullname,
		registrations.existingid, registrations.firstchoiceid, registrations.secondchoiceid, registrations.offcampus,
		majors.majorname as firstchoice, secondmajor.majorname as secondchoise
	FROM (registrations INNER JOIN majors ON registrations.firstchoiceid = majors.majorid)
		INNER JOIN majors as secondmajor ON registrations.secondchoiceid = secondmajor.majorid;

CREATE VIEW vwdenominations AS
	SELECT religions.religionid, religions.religionname, religions.details as religiondetails,
		denominations.denominationid, denominations.denominationname, denominations.details as denominationdetails
		FROM religions INNER JOIN denominations ON religions.religionid = denominations.religionid;

CREATE VIEW vwdepartments AS
	SELECT schools.schoolid, schools.schoolname, departments.departmentid, departments.departmentname,
		departments.philosopy, departments.vision, departments.mission, departments.objectives,
		departments.oppotunities, departments.details
	FROM schools INNER JOIN departments ON schools.schoolid = departments.schoolid
	ORDER BY departments.schoolid;

CREATE VIEW vwdegrees AS
	SELECT degreelevels.degreelevelid, degreelevels.degreelevelname, degrees.degreeid, degrees.degreename, degrees.details
	FROM degreelevels INNER JOIN degrees ON degreelevels.degreelevelid = degrees.degreelevelid;

CREATE VIEW vwinstructors AS
	SELECT departments.departmentid, departments.departmentname, instructors.instructorid,
		instructors.instructorname, instructors.majoradvisor, instructors.headofdepartment,
		instructors.firstpasswd, instructors.email,
		(CASE WHEN (instructors.majoradvisor = true) AND (instructors.headofdepartment = true) THEN 'HODMA'
		WHEN (instructors.majoradvisor = false) AND (instructors.headofdepartment = true) THEN 'HOD'
		WHEN (instructors.majoradvisor = true) AND (instructors.headofdepartment = false) THEN 'MA'
		ELSE 'NONE' END) as rolename
	FROM departments INNER JOIN instructors ON departments.departmentid = instructors.departmentid;

CREATE VIEW vwcourses AS
	SELECT vwdepartments.schoolid, vwdepartments.schoolname, vwdepartments.departmentid, vwdepartments.departmentname,
		degreelevels.degreelevelid, degreelevels.degreelevelname, coursetypes.coursetypeid, coursetypes.coursetypename,
		coursemodes.coursemodeid, coursemodes.coursemodename,
		courses.courseid, courses.coursetitle, courses.credithours, courses.maxcredit, courses.labcourse, courses.iscurrent,
		courses.nogpa, courses.yeartaken, courses.norepeats, courses.details
	FROM (((vwdepartments INNER JOIN courses ON vwdepartments.departmentid = courses.departmentid)
		INNER JOIN degreelevels ON courses.degreelevelid = degreelevels.degreelevelid)
		INNER JOIN coursetypes ON courses.coursetypeid = coursetypes.coursetypeid)
		INNER JOIN coursemodes ON courses.coursemodeid = coursemodes.coursemodeid;

CREATE VIEW vwprereq AS
	SELECT courses.courseid, courses.coursetitle, prerequisites.prerequisiteid,  prerequisites.precourseid, 
		prerequisites.optionlevel, prerequisites.narrative, grades.gradeid, grades.gradeweight,
		bulleting.bulletingid, bulleting.bulletingname, bulleting.starting, bulleting.ending, bulleting.active
	FROM ((courses INNER JOIN prerequisites ON courses.courseid = prerequisites.courseid)
		INNER JOIN grades ON prerequisites.gradeid = grades.gradeid)
		INNER JOIN bulleting ON prerequisites.bulletingid = bulleting.bulletingid;

CREATE VIEW vwprerequisites AS
	SELECT courses.courseid as precourseid, courses.coursetitle as precoursetitle,
		vwprereq.courseid, vwprereq.coursetitle, vwprereq.prerequisiteid,  
		vwprereq.optionlevel, vwprereq.narrative, vwprereq.gradeid, vwprereq.gradeweight,
		vwprereq.bulletingid, vwprereq.bulletingname, vwprereq.starting, vwprereq.ending, vwprereq.active
	FROM courses INNER JOIN vwprereq ON courses.courseid = vwprereq.precourseid
	ORDER BY vwprereq.courseid, vwprereq.optionlevel;

CREATE VIEW vwmajors AS
	SELECT vwdepartments.schoolid, vwdepartments.schoolname, vwdepartments.departmentid, vwdepartments.departmentname,
		majors.majorid, majors.majorname, majors.electivecredit, majors.coreminimum,
		majors.major, majors.minor, majors.details
	FROM vwdepartments INNER JOIN majors ON vwdepartments.departmentid = majors.departmentid;

CREATE VIEW vwmajorcontents AS
	SELECT vwmajors.schoolid, vwmajors.departmentid, vwmajors.departmentname, vwmajors.majorid, vwmajors.majorname, 
		vwmajors.electivecredit, courses.courseid, courses.coursetitle, courses.credithours, courses.nogpa, courses.yeartaken,
		contenttypes.contenttypeid, contenttypes.contenttypename, contenttypes.elective, contenttypes.prerequisite,
		contenttypes.premajor, majorcontents.majorcontentid, majorcontents.gradeid, majorcontents.narrative, 
		majorcontents.minor, bulleting.bulletingid, bulleting.bulletingname, bulleting.starting, bulleting.ending,
		bulleting.active
	FROM (((vwmajors INNER JOIN majorcontents ON vwmajors.majorid = majorcontents.majorid)
		INNER JOIN courses ON majorcontents.courseid = courses.courseid)
		INNER JOIN contenttypes ON majorcontents.contenttypeid = contenttypes.contenttypeid)
		INNER JOIN bulleting ON majorcontents.bulletingid = bulleting.bulletingid;

CREATE VIEW vwsponsors AS
	SELECT sponsortypes.sponsortypeid, sponsortypes.sponsortypename, sponsors.sponsorid,
		sponsors.sponsorname, sponsors.address, sponsors.street, sponsors.postalcode,
		sponsors.town, sponsors.telno, sponsors.email, sponsors.firstpasswd, sponsors.active, sponsors.details,
		countrys.countryid, countrys.countryname
	FROM sponsortypes INNER JOIN sponsors ON sponsortypes.sponsortypeid = sponsors.sponsortypeid
		INNER JOIN countrys ON countrys.countryid = sponsors.countryid;

CREATE VIEW vwstudents AS
	SELECT vwdenominations.religionid, vwdenominations.religionname, vwdenominations.denominationid, vwdenominations.denominationname,
		vwsponsors.sponsortypeid, vwsponsors.sponsortypename, vwsponsors.sponsorid, vwsponsors.sponsorname,
		vwsponsors.address as sponsoraddress, vwsponsors.street as sponsorstreet, vwsponsors.postalcode as sponsorpostalcode,
		vwsponsors.town as sponsortown, vwsponsors.telno as sponsortelno, vwsponsors.email as sponsoremail, 
		vwsponsors.countryid as sponsorcountryid, vwsponsors.countryname as sponsorcountryname,
		vwdepartments.schoolid, vwdepartments.schoolname, vwdepartments.departmentid, vwdepartments.departmentname,
		students.studentid, students.studentname, students.address, students.zipcode, students.town, 
		c1.countryname as addresscountry, students.telno, students.email,  
		students.accountnumber, students.Nationality, c2.countryname as Nationalitycountry, students.Sex,
		students.MaritalStatus, students.birthdate, students.firstpasswd, students.alumnae, students.offcampus, 
		students.onhold, students.currentcontact, students.onprobation, students.picturefile, students.details
	FROM (((vwdenominations INNER JOIN students ON vwdenominations.denominationid = students.denominationid)
		INNER JOIN vwdepartments ON vwdepartments.departmentid = students.departmentid)
		INNER JOIN vwsponsors ON students.sponsorid = vwsponsors.sponsorid)
		INNER JOIN countrys as c1 ON students.countrycodeid = c1.countryid
		INNER JOIN countrys as c2 ON students.Nationality = c2.countryid;

CREATE VIEW vwstudentrequests AS
	SELECT students.studentid, students.studentname, requesttypes.requesttypeid, requesttypes.requesttypename, requesttypes.toapprove,
		requesttypes.details as typedetails, studentrequests.studentrequestid, studentrequests.narrative, studentrequests.datesent,
		studentrequests.actioned, studentrequests.dateactioned, studentrequests.approved, studentrequests.dateapploved,
		studentrequests.details, studentrequests.reply
	FROM (students INNER JOIN studentrequests ON students.studentid = studentrequests.studentid)
		INNER JOIN requesttypes ON studentrequests.requesttypeid = requesttypes.requesttypeid;

CREATE VIEW vwstudentdegrees AS
	SELECT vwstudents.religionid, vwstudents.religionname, vwstudents.denominationid, vwstudents.denominationname,
		vwstudents.sponsortypeid, vwstudents.sponsortypename, vwstudents.sponsorid, vwstudents.sponsorname,
		vwstudents.sponsoraddress, vwstudents.sponsorstreet, vwstudents.sponsorpostalcode,
		vwstudents.sponsortown, vwstudents.sponsortelno, vwstudents.sponsoremail, 
		vwstudents.sponsorcountryid, vwstudents.sponsorcountryname,
		vwstudents.departmentid, vwstudents.departmentname, vwstudents.schoolid, vwstudents.schoolname,
		vwstudents.studentid, vwstudents.studentname, vwstudents.address, vwstudents.zipcode,
		vwstudents.town, vwstudents.addresscountry, vwstudents.telno, vwstudents.email,  		
		vwstudents.accountnumber, vwstudents.Nationality, vwstudents.Nationalitycountry, vwstudents.Sex,
		vwstudents.MaritalStatus, vwstudents.birthdate, vwstudents.firstpasswd, vwstudents.alumnae,
		vwstudents.currentcontact, vwstudents.offcampus, vwstudents.onprobation, 
		vwdegrees.degreelevelid, vwdegrees.degreelevelname, vwdegrees.degreeid, vwdegrees.degreename,
		studentdegrees.studentdegreeid, studentdegrees.completed, studentdegrees.started, studentdegrees.cleared, studentdegrees.clearedate,
		studentdegrees.graduated, studentdegrees.graduatedate, studentdegrees.dropout, studentdegrees.transferin, studentdegrees.transferout,
		studentdegrees.bulletingid, studentdegrees.details
	FROM (vwstudents INNER JOIN studentdegrees ON vwstudents.studentid = studentdegrees.studentid)
		INNER JOIN vwdegrees ON studentdegrees.degreeid = vwdegrees.degreeid;

CREATE VIEW vwtranscriptprint AS
	SELECT users.userid, users.username, users.fullname, transcriptprint.transcriptprintid, transcriptprint.studentdegreeid,
		transcriptprint.printdate, transcriptprint.	narrative
	FROM transcriptprint INNER JOIN users ON transcriptprint.userid = users.userid; 

CREATE VIEW vwtransferedcredits AS
	SELECT vwstudentdegrees.degreeid, vwstudentdegrees.degreename, 
		vwstudentdegrees.studentid, vwstudentdegrees.studentname, vwstudentdegrees.studentdegreeid, courses.courseid, courses.coursetitle,
		transferedcredits.transferedcreditid, transferedcredits.credithours, transferedcredits.narrative
	FROM (vwstudentdegrees INNER JOIN transferedcredits ON vwstudentdegrees.studentdegreeid = transferedcredits.studentdegreeid)
		INNER JOIN courses ON transferedcredits.courseid = courses.courseid;

CREATE VIEW vwstudentmajors AS 
	SELECT vwstudentdegrees.religionid, vwstudentdegrees.religionname, vwstudentdegrees.denominationid, vwstudentdegrees.denominationname,
		vwstudentdegrees.sponsortypeid, vwstudentdegrees.sponsortypename, vwstudentdegrees.sponsorid, vwstudentdegrees.sponsorname,
		vwstudentdegrees.sponsoraddress, vwstudentdegrees.sponsorstreet, vwstudentdegrees.sponsorpostalcode,
		vwstudentdegrees.sponsortown, vwstudentdegrees.sponsortelno, vwstudentdegrees.sponsoremail, 
		vwstudentdegrees.sponsorcountryid, vwstudentdegrees.sponsorcountryname,
		vwstudentdegrees.schoolid as studentschoolid, vwstudentdegrees.schoolname as studentschoolname, 
		vwstudentdegrees.departmentid as studentdepartmentid, vwstudentdegrees.departmentname as studentdepartmentname,
		vwstudentdegrees.studentid, vwstudentdegrees.studentname, vwstudentdegrees.address, vwstudentdegrees.zipcode,
		vwstudentdegrees.town, vwstudentdegrees.addresscountry, vwstudentdegrees.telno, vwstudentdegrees.email,
		vwstudentdegrees.accountnumber, vwstudentdegrees.Nationality, vwstudentdegrees.Nationalitycountry, vwstudentdegrees.Sex,
		vwstudentdegrees.MaritalStatus, vwstudentdegrees.birthdate, vwstudentdegrees.firstpasswd, vwstudentdegrees.alumnae,
		vwstudentdegrees.onprobation, vwstudentdegrees.offcampus as allowoffcampus, vwstudentdegrees.currentcontact, 
		vwstudentdegrees.degreelevelid, vwstudentdegrees.degreelevelname, vwstudentdegrees.degreeid, vwstudentdegrees.degreename,
		vwstudentdegrees.studentdegreeid, vwstudentdegrees.completed, vwstudentdegrees.started, vwstudentdegrees.cleared, vwstudentdegrees.clearedate,
		vwstudentdegrees.graduated, vwstudentdegrees.graduatedate, vwstudentdegrees.dropout, vwstudentdegrees.transferin, vwstudentdegrees.transferout,
		vwmajors.schoolid, vwmajors.schoolname, vwmajors.departmentid, vwmajors.departmentname,
		vwmajors.majorid, vwmajors.majorname, vwmajors.major as domajor, vwmajors.minor as dominor,
		vwmajors.electivecredit, vwmajors.coreminimum,
		studentmajors.studentmajorid, studentmajors.major, studentmajors.nondegree, studentmajors.primarymajor, studentmajors.details
	FROM ((vwstudentdegrees INNER JOIN studentmajors ON vwstudentdegrees.studentdegreeid = studentmajors.studentdegreeid)
		INNER JOIN vwmajors ON studentmajors.majorid = vwmajors.majorid);

CREATE VIEW vwactivesession AS
	SELECT sessionid, sessionyear, semester, sstart, slatereg, slatechange, slastdrop, send
	FROM sessions
	WHERE (active=true);

CREATE VIEW vwyearview AS
	SELECT sessionyear
	FROM sessions
	GROUP BY sessionyear
	ORDER BY sessionyear;

CREATE VIEW vwsresidences AS
	SELECT residences.residenceid, residences.residencename, residences.defaultrate,
		residences.offcampus, residences.Sex, residences.residencedean,
		sresidences.sresidenceid, sresidences.sessionid, sresidences.residenceoption,
		sresidences.charges, sresidences.details, sresidences.charges as residencecharge,
		sessions.sessionyear, sessions.semester, sessions.active
	FROM (residences INNER JOIN sresidences ON residences.residenceid = sresidences.residenceid)
	INNER JOIN sessions ON sresidences.sessionid = sessions.sessionid;

CREATE VIEW vwscharges AS
	SELECT scharges.schargeid, scharges.fees, scharges.narrative, scharges.details,
		degreelevels.degreelevelid, degreelevels.degreelevelname,
		sessions.sessionid, sessions.sessionyear, sessions.semester, sessions.active
	FROM (degreelevels INNER JOIN scharges ON degreelevels.degreelevelid = scharges.degreelevelid)
		INNER JOIN sessions ON scharges.sessionid = sessions.sessionid;

CREATE OR REPLACE FUNCTION roomcount(integer, integer) RETURNS bigint AS $$
	SELECT count(sstudentid) FROM sstudents WHERE (sresidenceid = $1) AND (roomnumber = $2);
$$ LANGUAGE SQL;

CREATE VIEW vwresidenceroom AS
	SELECT residenceid, residencename, roomsize, capacity, generate_series(1, capacity+1) as roomnumber
	FROM residences;

CREATE VIEW vwsresidenceroom AS
	SELECT vwresidenceroom.residenceid, vwresidenceroom.residencename, vwresidenceroom.roomsize, vwresidenceroom.capacity, 
		vwresidenceroom.roomnumber, 
		roomcount(sresidences.sresidenceid, vwresidenceroom.roomnumber) as roomcount,
		vwresidenceroom.roomsize - roomcount(sresidences.sresidenceid, vwresidenceroom.roomnumber) as roombalance,
		sresidences.sresidenceid, sresidences.sessionid,
		(sresidences.sresidenceid || 'R' || vwresidenceroom.roomnumber) as roomid
	FROM vwresidenceroom INNER JOIN sresidences ON vwresidenceroom.residenceid = sresidences.residenceid;

CREATE VIEW vwsstudentresidence AS
	SELECT students.studentid, students.studentname, students.Sex, sstudents.sstudentid,
		vwsresidenceroom.residenceid, vwsresidenceroom.residencename, vwsresidenceroom.roomsize, vwsresidenceroom.capacity,
		vwsresidenceroom.roomnumber, vwsresidenceroom.roomcount, vwsresidenceroom.roombalance, 
		vwsresidenceroom.roomid, vwsresidenceroom.sresidenceid, vwsresidenceroom.sessionid, sessions.active
	FROM (((students INNER JOIN studentdegrees ON students.studentid = studentdegrees.studentid)
		INNER JOIN sstudents ON studentdegrees.studentdegreeid = sstudents.studentdegreeid)  
		INNER JOIN vwsresidenceroom ON sstudents.sresidenceid = vwsresidenceroom.sresidenceid)
		INNER JOIN sessions ON sstudents.sessionid = sessions.sessionid;

CREATE VIEW vwsstudentlist AS
	SELECT students.studentid, students.departmentid, students.studentname, students.Sex, students.Nationality, students.MaritalStatus,
		students.birthdate, students.email, studentdegrees.studentdegreeid, studentdegrees.degreeid,
		sstudents.sstudentid, sstudents.extacharges, sstudents.probation, sstudents.roomnumber,
		sstudents.currbalance, sstudents.finaceapproval, sstudents.financenarrative, sstudents.finalised,
		sstudents.majorapproval, sstudents.chaplainapproval, sstudents.overloadapproval, sstudents.studentdeanapproval,
		sstudents.overloadhours, sstudents.closed, sstudents.printed, sstudents.approved,
		sessions.sessionid, sessions.sessionyear, sessions.semester, sessions.active
	FROM ((students INNER JOIN studentdegrees ON students.studentid = studentdegrees.studentid)
		INNER JOIN sstudents ON studentdegrees.studentdegreeid = sstudents.studentdegreeid)
		INNER JOIN sessions ON sstudents.sessionid = sessions.sessionid;

CREATE VIEW vwsstudents AS
	SELECT vwstudentdegrees.religionid, vwstudentdegrees.religionname, vwstudentdegrees.denominationid, vwstudentdegrees.denominationname,
		vwstudentdegrees.sponsortypeid, vwstudentdegrees.sponsortypename, vwstudentdegrees.sponsorid, vwstudentdegrees.sponsorname,
		vwstudentdegrees.sponsoraddress, vwstudentdegrees.sponsorstreet, vwstudentdegrees.sponsorpostalcode,
		vwstudentdegrees.sponsortown, vwstudentdegrees.sponsortelno, vwstudentdegrees.sponsoremail, 
		vwstudentdegrees.sponsorcountryid, vwstudentdegrees.sponsorcountryname,
		vwstudentdegrees.schoolid, vwstudentdegrees.schoolname, vwstudentdegrees.departmentid, vwstudentdegrees.departmentname,
		vwstudentdegrees.studentid, vwstudentdegrees.studentname, vwstudentdegrees.address, vwstudentdegrees.zipcode,
		vwstudentdegrees.town, vwstudentdegrees.addresscountry, vwstudentdegrees.telno, vwstudentdegrees.email,
		vwstudentdegrees.accountnumber, vwstudentdegrees.Nationality, vwstudentdegrees.Nationalitycountry, vwstudentdegrees.Sex,
		vwstudentdegrees.MaritalStatus, vwstudentdegrees.birthdate, vwstudentdegrees.firstpasswd, vwstudentdegrees.alumnae,
		vwstudentdegrees.onprobation, vwstudentdegrees.offcampus as allowoffcampus, vwstudentdegrees.currentcontact, 
		vwstudentdegrees.degreelevelid, vwstudentdegrees.degreelevelname, vwstudentdegrees.degreeid, vwstudentdegrees.degreename,
		vwstudentdegrees.studentdegreeid, vwstudentdegrees.completed, vwstudentdegrees.started, vwstudentdegrees.cleared, vwstudentdegrees.clearedate,
		vwstudentdegrees.graduated, vwstudentdegrees.graduatedate, vwstudentdegrees.dropout, vwstudentdegrees.transferin, vwstudentdegrees.transferout,
		sessions.sessionid, sessions.sessionyear, sessions.semester, sessions.sstart, sessions.slatereg, sessions.slatechange,
		sessions.slastdrop, sessions.send, sessions.active, sessions.mincredits, sessions.maxcredits,
		vwsresidences.residenceid, vwsresidences.residencename, vwsresidences.defaultrate,
		vwsresidences.offcampus as residenceoffcampus, vwsresidences.Sex as residencesex, vwsresidences.residencedean,
		vwsresidences.sresidenceid, vwsresidences.residenceoption, vwsresidences.residencecharge,
		(vwsresidences.sresidenceid || 'R' || sstudents.roomnumber) as roomid,
		sstudents.sstudentid, sstudents.probation, sstudents.offcampus, sstudents.blockname, sstudents.roomnumber,
		sstudents.currbalance, sstudents.studylevel, sstudents.applicationtime, sstudents.firstclosetime,
		sstudents.finalised, sstudents.clearedfinance, sstudents.finaceapproval, sstudents.majorapproval,
		sstudents.departapproval, sstudents.chaplainapproval, sstudents.studentdeanapproval, sstudents.overloadapproval,
		sstudents.overloadhours, sstudents.financeclosed, sstudents.closed, sstudents.printed,
		sstudents.approved, sstudents.extacharges
	FROM (((vwstudentdegrees INNER JOIN sstudents ON vwstudentdegrees.studentdegreeid = sstudents.studentdegreeid)
		INNER JOIN sessions ON (sstudents.sessionid = sessions.sessionid))
		LEFT JOIN vwsresidences ON sstudents.sresidenceid = vwsresidences.sresidenceid);

CREATE VIEW vwsstudentmajors AS 
	SELECT vwstudentmajors.religionid, vwstudentmajors.religionname, vwstudentmajors.denominationid, vwstudentmajors.denominationname,
		studentschoolid, studentschoolname, vwstudentmajors.studentid, studentdepartmentid, studentdepartmentname,
		vwstudentmajors.studentname, vwstudentmajors.Nationality, vwstudentmajors.Nationalitycountry, vwstudentmajors.Sex,
		vwstudentmajors.MaritalStatus, vwstudentmajors.birthdate, 
		vwstudentmajors.degreelevelid, vwstudentmajors.degreelevelname,
		vwstudentmajors.degreeid, vwstudentmajors.degreename,
		vwstudentmajors.studentdegreeid, vwstudentmajors.completed, vwstudentmajors.started, vwstudentmajors.cleared, vwstudentmajors.clearedate,
		vwstudentmajors.graduated, vwstudentmajors.graduatedate, vwstudentmajors.dropout, vwstudentmajors.transferin, vwstudentmajors.transferout,
		vwstudentmajors.schoolid, vwstudentmajors.schoolname, vwstudentmajors.departmentid, vwstudentmajors.departmentname,
		vwstudentmajors.majorid, vwstudentmajors.majorname, vwstudentmajors.electivecredit, vwstudentmajors.domajor, vwstudentmajors.dominor,
		vwstudentmajors.studentmajorid, vwstudentmajors.major, vwstudentmajors.nondegree, 
		sstudents.sstudentid, sstudents.probation, sstudents.offcampus, sstudents.blockname, sstudents.roomnumber,
		sstudents.sessionid, sstudents.currbalance, sstudents.studylevel, sstudents.applicationtime, sstudents.firstclosetime,
		sstudents.finalised, sstudents.clearedfinance, sstudents.finaceapproval, sstudents.majorapproval,
		sstudents.departapproval, sstudents.chaplainapproval, sstudents.studentdeanapproval, sstudents.overloadapproval,
		sstudents.overloadhours, sstudents.financeclosed, sstudents.closed, sstudents.printed,
		sstudents.approved, sstudents.extacharges
	FROM vwstudentmajors INNER JOIN sstudents ON vwstudentmajors.studentdegreeid = sstudents.studentdegreeid
	WHERE (sstudents.approved = true);

CREATE VIEW vwscourse AS
SELECT vwcourses.schoolid, vwcourses.schoolname, vwcourses.departmentid, vwcourses.departmentname,
		vwcourses.degreelevelid, vwcourses.degreelevelname, vwcourses.coursetypeid, vwcourses.coursetypename,
		vwcourses.courseid, vwcourses.credithours, vwcourses.maxcredit, vwcourses.iscurrent,
		vwcourses.nogpa, vwcourses.yeartaken, 
		scourses.instructorid, scourses.scourseid, scourses.classoption, scourses.maxclass,
		scourses.coursecharge, scourses.approved, scourses.attendance, 
		scourses.fullattendance, instructors.instructorname, scourses.coursetitle,
		scourses.lecturesubmit, scourses.lsdate, scourses.departmentsubmit,
		scourses.dsdate, scourses.facultysubmit, scourses.fsdate,
		sessions.sessionid, sessions.sessionyear, sessions.semester, sessions.slastdrop, sessions.send, sessions.active
	FROM (((vwcourses INNER JOIN scourses ON vwcourses.courseid = scourses.courseid)
		INNER JOIN instructors ON scourses.instructorid = instructors.instructorid)
		INNER JOIN sessions ON scourses.sessionid = sessions.sessionid);
		
CREATE OR REPLACE FUNCTION getscoursestudents(integer) RETURNS bigint AS $$
	SELECT CASE WHEN count(sgradeid) is null THEN 0 ELSE count(sgradeid) END
	FROM sgrades INNER JOIN sstudents ON sgrades.sstudentid = sstudents.sstudentid 
	WHERE (sgrades.dropped = false) AND (sstudents.finalised = true) AND (scourseid = $1);
$$ LANGUAGE SQL;

CREATE VIEW vwstimetable AS
	SELECT assets.assetid, assets.assetname, assets.location, assets.building, assets.capacity, 
		vwscourse.scourseid, vwscourse.courseid, vwscourse.coursetitle, vwscourse.instructorid,
		vwscourse.instructorname, vwscourse.sessionid, vwscourse.maxclass, vwscourse.classoption,
		optiontimes.optiontimeid, optiontimes.optiontimename,
		stimetable.stimetableid, stimetable.starttime, stimetable.endtime, stimetable.lab,
		stimetable.details, stimetable.cmonday, stimetable.ctuesday, stimetable.cwednesday, stimetable.cthursday,
		stimetable.cfriday, stimetable.csaturday, stimetable.csunday 
	FROM ((assets INNER JOIN stimetable ON assets.assetid = stimetable.assetid)
		INNER JOIN vwscourse ON stimetable.scourseid = vwscourse.scourseid)
		INNER JOIN optiontimes ON stimetable.optiontimeid = optiontimes.optiontimeid
	ORDER BY stimetable.starttime;

CREATE VIEW vwsetimetable AS
	SELECT assets.assetid, assets.assetname, assets.location, assets.building, assets.capacity, 
		vwscourse.scourseid, vwscourse.courseid, vwscourse.coursetitle, vwscourse.instructorid,
		vwscourse.instructorname, vwscourse.sessionid, vwscourse.maxclass, vwscourse.classoption,
		optiontimes.optiontimeid, optiontimes.optiontimename,
		sexamtimetable.sexamtimetableid, sexamtimetable.starttime, sexamtimetable.endtime, sexamtimetable.lab,
		sexamtimetable.examdate, sexamtimetable.details 
	FROM ((assets INNER JOIN sexamtimetable ON assets.assetid = sexamtimetable.assetid)
		INNER JOIN vwscourse ON sexamtimetable.scourseid = vwscourse.scourseid)
		INNER JOIN optiontimes ON sexamtimetable.optiontimeid = optiontimes.optiontimeid
	ORDER BY sexamtimetable.examdate, sexamtimetable.starttime;

CREATE OR REPLACE FUNCTION gettimeassetcount(integer, time, time, boolean, boolean, boolean, boolean, boolean, boolean, boolean) RETURNS bigint AS $$
	SELECT count(stimetableid) FROM vwstimetable
	WHERE (assetid=$1) AND (((starttime, endtime) OVERLAPS ($2, $3))=true) 
	AND ((cmonday and $4) OR (ctuesday and $5) OR (cwednesday and $6) OR (cthursday and $7) OR (cfriday and $8) OR (csaturday and $9) OR (csunday and $10));
$$ LANGUAGE SQL;

CREATE VIEW vwsassettimetable AS
	SELECT assetid, assetname, location, building, capacity, scourseid, courseid, coursetitle, instructorid,
		instructorname, sessionid, maxclass, classoption, optiontimeid, optiontimename,
		stimetableid, starttime, endtime, lab, details, cmonday, ctuesday, cwednesday, cthursday,
		cfriday, csaturday, csunday,
		gettimeassetcount(assetid, starttime, endtime, cmonday, ctuesday, cwednesday, cthursday, cfriday, csaturday, csunday) as timeassetcount 
	FROM vwstimetable
	ORDER BY assetid;

CREATE VIEW vwscourseitems AS
	SELECT vwscourse.scourseid, vwscourse.courseid, vwscourse.coursetitle, vwscourse.instructorname, vwscourse.sessionid,
		vwscourse.classoption, scourseitems.scourseitemid, scourseitems.scourseitemname, scourseitems.markratio,
		scourseitems.totalmarks, scourseitems.given, scourseitems.deadline, scourseitems.details
	FROM vwscourse INNER JOIN scourseitems ON vwscourse.scourseid = scourseitems.scourseid;

CREATE VIEW vwcourseitemmarks AS
	SELECT scourseitems.scourseid, scoursemarks.sgradeid, 
		round(SUM(scoursemarks.marks * scourseitems.markratio / scourseitems.totalmarks)) as netscore
	FROM scourseitems INNER JOIN scoursemarks ON scourseitems.scourseitemid = scoursemarks.scourseitemid
	WHERE scoursemarks.marks > 0
	GROUP BY scourseitems.scourseid, scoursemarks.sgradeid;

CREATE VIEW vwsgrades AS
	SELECT vwscourse.schoolid, vwscourse.schoolname, vwscourse.departmentid, vwscourse.departmentname,
		vwscourse.degreelevelid, vwscourse.degreelevelname, vwscourse.coursetypeid, vwscourse.coursetypename,
		vwscourse.courseid, vwscourse.credithours, vwscourse.iscurrent,
		vwscourse.nogpa, vwscourse.yeartaken,
		vwscourse.instructorid, vwscourse.sessionid, vwscourse.scourseid, vwscourse.classoption, vwscourse.maxclass,
		vwscourse.coursecharge, vwscourse.attendance as crs_attendance, 
		vwscourse.fullattendance, vwscourse.instructorname, vwscourse.coursetitle,		
		sgrades.sgradeid,sgrades.sstudentid, sgrades.hours, sgrades.credit, sgrades.approved as crs_approved, sgrades.approvedate, sgrades.askdrop,	
		sgrades.askdropdate, sgrades.dropped, sgrades.dropdate, sgrades.repeated, sgrades.attendance, sgrades.narrative,
		sgrades.challengecourse, sgrades.nongpacourse, sgrades.instructormarks, sgrades.departmentmarks, 
		sgrades.facultymark, sgrades.finalmarks, sgrades.optiontimeid, sgrades.withdrawdate,
		grades.gradeid, grades.gradeweight, grades.minrange, grades.maxrange, grades.gpacount, grades.narrative as gradenarrative,				
		(CASE sgrades.repeated WHEN true THEN 0 ELSE (grades.gradeweight * sgrades.credit) END) as gpa,
		(CASE WHEN ((sgrades.gradeid='W') OR (sgrades.gradeid='AW') OR (grades.gpacount=false) OR (sgrades.repeated=true) OR (sgrades.nongpacourse=true)) THEN 0 ELSE sgrades.credit END) as gpahours,
		(CASE WHEN ((sgrades.gradeid='W') OR (sgrades.gradeid='AW')) THEN 0 ELSE sgrades.hours END) as chargehours
	FROM (vwscourse INNER JOIN sgrades ON vwscourse.scourseid = sgrades.scourseid)
		INNER JOIN grades ON sgrades.gradeid = grades.gradeid
	WHERE (sgrades.dropped = false);

CREATE VIEW vwstudentgrades AS
	SELECT vwsstudents.religionid, vwsstudents.religionname, vwsstudents.denominationid, vwsstudents.denominationname,
		vwsstudents.schoolid, vwsstudents.schoolname, vwsstudents.departmentid, vwsstudents.departmentname,  
		vwsstudents.studentid, vwsstudents.studentname, vwsstudents.address, vwsstudents.zipcode,
		vwsstudents.town, vwsstudents.addresscountry, vwsstudents.telno, vwsstudents.email,
		vwsstudents.sponsortypeid, vwsstudents.sponsortypename, vwsstudents.sponsorid, vwsstudents.sponsorname,
		vwsstudents.sponsoraddress, vwsstudents.sponsorstreet, vwsstudents.sponsorpostalcode,
		vwsstudents.sponsortown, vwsstudents.sponsortelno, vwsstudents.sponsoremail, 
		vwsstudents.sponsorcountryid, vwsstudents.sponsorcountryname,
		vwsstudents.accountnumber, vwsstudents.Nationality, vwsstudents.Nationalitycountry, vwsstudents.Sex,
		vwsstudents.MaritalStatus, vwsstudents.birthdate, vwsstudents.firstpasswd, vwsstudents.alumnae, 
		vwsstudents.onprobation, vwsstudents.offcampus, vwsstudents.currentcontact, 
		vwsstudents.degreelevelid, vwsstudents.degreelevelname, vwsstudents.degreeid, vwsstudents.degreename,
		vwsstudents.studentdegreeid, vwsstudents.completed, vwsstudents.started, vwsstudents.cleared, vwsstudents.clearedate,
		vwsstudents.graduated, vwsstudents.graduatedate, vwsstudents.dropout, vwsstudents.transferin, vwsstudents.transferout,
		vwsstudents.sessionid, vwsstudents.sessionyear, vwsstudents.semester, vwsstudents.sstart, vwsstudents.slatereg, vwsstudents.slatechange, vwsstudents.slastdrop,
		vwsstudents.send, vwsstudents.active, vwsstudents.mincredits, vwsstudents.maxcredits,
		vwsstudents.residenceid, vwsstudents.residencename, vwsstudents.defaultrate,
		vwsstudents.residenceoffcampus, vwsstudents.residencesex, vwsstudents.residencedean,
		vwsstudents.sresidenceid, vwsstudents.residenceoption, vwsstudents.residencecharge,
		vwsstudents.sstudentid, vwsstudents.extacharges, vwsstudents.approved, vwsstudents.probation,
		vwsstudents.roomnumber, vwsstudents.currbalance, vwsstudents.finaceapproval, vwsstudents.majorapproval,
		vwsstudents.departapproval, vwsstudents.overloadapproval, vwsstudents.finalised, vwsstudents.printed,
		vwsstudents.studentdeanapproval, vwsstudents.overloadhours, vwsstudents.studylevel,
		vwsgrades.schoolid as crs_schoolid, vwsgrades.schoolname as crs_schoolname,
		vwsgrades.departmentid as crs_departmentid, vwsgrades.departmentname as crs_departmentname,
		vwsgrades.degreelevelid as crs_degreelevelid, vwsgrades.degreelevelname as crs_degreelevelname,
		vwsgrades.coursetypeid, vwsgrades.coursetypename, vwsgrades.courseid, vwsgrades.credithours, vwsgrades.iscurrent,
		vwsgrades.nogpa, vwsgrades.yeartaken, vwsgrades.instructormarks, vwsgrades.finalmarks,
		vwsgrades.instructorid, vwsgrades.scourseid, vwsgrades.classoption, vwsgrades.maxclass,
		vwsgrades.coursecharge, vwsgrades.attendance as crs_attendance, 
		vwsgrades.fullattendance, vwsgrades.instructorname, vwsgrades.coursetitle,
		vwsgrades.sgradeid, vwsgrades.hours, vwsgrades.credit, vwsgrades.crs_approved, vwsgrades.approvedate, vwsgrades.askdrop,	
		vwsgrades.askdropdate, vwsgrades.dropped, vwsgrades.dropdate, vwsgrades.repeated, vwsgrades.attendance, vwsgrades.narrative,
		vwsgrades.gradeid, vwsgrades.gradeweight, vwsgrades.minrange, vwsgrades.maxrange, vwsgrades.gpacount, vwsgrades.gradenarrative,
		vwsgrades.gpa, vwsgrades.gpahours, vwsgrades.chargehours, vwsgrades.departmentmarks
	FROM vwsstudents INNER JOIN vwsgrades ON vwsstudents.sstudentid = vwsgrades.sstudentid;

CREATE VIEW vwgradecount AS
	SELECT sstudents.studentdegreeid,  scourses.courseid, count(scourses.scourseid) as coursecount
	FROM (sgrades INNER JOIN (scourses INNER JOIN courses ON scourses.courseid = courses.courseid) ON sgrades.scourseid = scourses.scourseid)
		INNER JOIN sstudents ON sgrades.sstudentid = sstudents.sstudentid
	WHERE (sgrades.gradeid <> 'W') AND (sgrades.gradeid <> 'AW') AND (sgrades.gradeid <> 'NG') AND (sgrades.dropped = false)
		AND (repeated = false) AND (sstudents.approved = true) AND (courses.norepeats = false)
	GROUP BY sstudents.studentdegreeid,  scourses.courseid;

CREATE OR REPLACE FUNCTION getcoursedone(varchar(12), varchar(12)) RETURNS float AS $$
	SELECT max(grades.gradeweight)
	FROM (((scourses INNER JOIN sgrades ON scourses.scourseid = sgrades.scourseid)
		INNER JOIN sstudents ON sgrades.sstudentid = sstudents.sstudentid)
		INNER JOIN grades ON sgrades.gradeid = grades.gradeid)
		INNER JOIN studentdegrees ON sstudents.studentdegreeid = studentdegrees.studentdegreeid
	WHERE (studentdegrees.studentid=$1) AND (scourses.courseid=$2);		
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getcoursetransfered(varchar(12), varchar(12)) RETURNS float AS $$
	SELECT sum(transferedcredits.credithours)
	FROM transferedcredits INNER JOIN studentdegrees ON transferedcredits.studentdegreeid = studentdegrees.studentdegreeid
	WHERE (studentdegrees.studentid = $1) AND (transferedcredits.courseid = $2);		
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION getprereqpassed(varchar(12), varchar(12)) RETURNS boolean AS $$
DECLARE
	passed boolean;
	hasprereq boolean;
	myrec RECORD;
	orderid int;
BEGIN
	passed := false;
	hasprereq := false;
	orderid := 1;
	
	FOR myrec IN SELECT optionlevel, precourseid, gradeweight 
		FROM vwprereq WHERE (courseid = $2) AND (optionlevel > 0) 
	ORDER BY optionlevel LOOP
		hasprereq :=  true;
		IF(orderid <> myrec.optionlevel) THEN
			orderid := myrec.optionlevel;
			passed := false;
		END IF;

		IF (getcoursedone($1, myrec.precourseid) >= myrec.gradeweight) THEN
			passed := true;
		END IF;
		IF (getcoursetransfered($1, myrec.precourseid) is not null) THEN
			passed := true;
		END IF;
	END LOOP;

	IF (hasprereq = false) THEN
		passed := true;
	END IF;

    RETURN passed;
END;
$$ LANGUAGE plpgsql;

CREATE VIEW vwselectedgrades AS
	SELECT vwsgrades.courseid, vwsgrades.coursetitle, vwsgrades.credithours, vwsgrades.nogpa, vwsgrades.yeartaken,
		vwsgrades.scourseid, vwsgrades.sessionid, vwsgrades.classoption, vwsgrades.maxclass, 
		vwsgrades.instructorid, vwsgrades.instructorname, 
		vwsgrades.sgradeid, vwsgrades.sstudentid, vwsgrades.gradeid, vwsgrades.hours, vwsgrades.credit, 
		vwsgrades.approvedate, vwsgrades.askdrop, vwsgrades.askdropdate, vwsgrades.dropped,	vwsgrades.dropdate,
		vwsgrades.repeated, vwsgrades.withdrawdate, vwsgrades.attendance, vwsgrades.optiontimeid, vwsgrades.narrative,
		studentdegrees.studentdegreeid, studentdegrees.studentid, students.studentname, students.sex,
		getprereqpassed(studentdegrees.studentid, vwsgrades.courseid) as prereqpassed
	FROM ((vwsgrades INNER JOIN sstudents ON vwsgrades.sstudentid = sstudents.sstudentid)
		INNER JOIN studentdegrees ON sstudents.studentdegreeid = studentdegrees.studentdegreeid)
		INNER JOIN students ON studentdegrees.studentid = students.studentid;

CREATE VIEW vwsselectedgrades AS
	SELECT courses.courseid, courses.coursetitle, courses.credithours, courses.nogpa, courses.yeartaken,
		scourses.scourseid, scourses.sessionid, scourses.classoption, scourses.maxclass, 
		instructors.instructorid, instructors.instructorname,
		sgrades.sgradeid, sgrades.sstudentid, sgrades.gradeid, sgrades.hours, sgrades.credit, sgrades.approved,
		sgrades.approvedate, sgrades.askdrop, sgrades.askdropdate, sgrades.dropped,	sgrades.dropdate,
		sgrades.repeated, sgrades.withdrawdate, sgrades.attendance, sgrades.optiontimeid, sgrades.narrative,
		studentdegrees.studentdegreeid, studentdegrees.studentid, students.studentname, students.sex
	FROM ((((courses INNER JOIN scourses ON courses.courseid = scourses.courseid)
		INNER JOIN instructors ON scourses.instructorid = instructors.instructorid)
		INNER JOIN sgrades ON sgrades.scourseid = scourses.scourseid)
		INNER JOIN sessions ON scourses.sessionid = sessions.sessionid)
		INNER JOIN (sstudents INNER JOIN (studentdegrees INNER JOIN students 
			ON studentdegrees.studentid = students.studentid)
			ON sstudents.studentdegreeid = studentdegrees.studentdegreeid)
			ON sgrades.sstudentid = sstudents.sstudentid
	WHERE (sessions.active = true) AND (sgrades.dropped = false);

CREATE VIEW vwstudenttimetable AS
	SELECT assets.assetid, assets.assetname, assets.location, assets.building, assets.capacity, 
		vwselectedgrades.courseid, vwselectedgrades.coursetitle, vwselectedgrades.credithours, vwselectedgrades.nogpa, vwselectedgrades.yeartaken,
		vwselectedgrades.scourseid, vwselectedgrades.sessionid, vwselectedgrades.classoption, vwselectedgrades.maxclass, 
		vwselectedgrades.instructorid, vwselectedgrades.instructorname, vwselectedgrades.studentdegreeid, vwselectedgrades.studentid,
		vwselectedgrades.sgradeid, vwselectedgrades.sstudentid, vwselectedgrades.gradeid, vwselectedgrades.hours, vwselectedgrades.credit, 
		vwselectedgrades.approvedate, vwselectedgrades.askdrop, vwselectedgrades.askdropdate, vwselectedgrades.dropped,	vwselectedgrades.dropdate,
		vwselectedgrades.repeated, vwselectedgrades.withdrawdate, vwselectedgrades.attendance, vwselectedgrades.narrative,
		stimetable.stimetableid, stimetable.starttime, stimetable.endtime, stimetable.lab,
		stimetable.details, stimetable.cmonday, stimetable.ctuesday, stimetable.cwednesday, stimetable.cthursday,
		stimetable.cfriday, stimetable.csaturday, stimetable.csunday,
		optiontimes.optiontimeid, optiontimes.optiontimename
	FROM (assets INNER JOIN (stimetable INNER JOIN optiontimes ON stimetable.optiontimeid = optiontimes.optiontimeid) ON assets.assetid = stimetable.assetid)
		INNER JOIN vwselectedgrades ON (stimetable.scourseid = vwselectedgrades.scourseid AND stimetable.optiontimeid =  vwselectedgrades.optiontimeid)
	ORDER BY stimetable.starttime;

CREATE VIEW vwsexamtimetable AS
	SELECT vwselectedgrades.courseid, vwselectedgrades.coursetitle, vwselectedgrades.credithours, vwselectedgrades.nogpa, vwselectedgrades.yeartaken,
		vwselectedgrades.scourseid, vwselectedgrades.sessionid, vwselectedgrades.classoption, vwselectedgrades.maxclass, 
		vwselectedgrades.instructorid, vwselectedgrades.instructorname, 
		vwselectedgrades.sgradeid, vwselectedgrades.sstudentid, vwselectedgrades.gradeid, vwselectedgrades.hours, vwselectedgrades.credit, 
		vwselectedgrades.approvedate, vwselectedgrades.askdrop, vwselectedgrades.askdropdate, vwselectedgrades.dropped,	vwselectedgrades.dropdate,
		vwselectedgrades.repeated, vwselectedgrades.withdrawdate, vwselectedgrades.attendance, vwselectedgrades.optiontimeid, vwselectedgrades.narrative,
		studentdegrees.studentdegreeid, studentdegrees.studentid, students.studentname, students.sex,
		sexamtimetable.sexamtimetableid, sexamtimetable.examdate, sexamtimetable.starttime, sexamtimetable.endtime, sexamtimetable.lab
	FROM (((vwselectedgrades INNER JOIN sstudents ON vwselectedgrades.sstudentid = sstudents.sstudentid)
		INNER JOIN studentdegrees ON sstudents.studentdegreeid = studentdegrees.studentdegreeid)
		INNER JOIN students ON studentdegrees.studentid = students.studentid)
		INNER JOIN sexamtimetable ON (sexamtimetable.scourseid = vwselectedgrades.scourseid)
	WHERE (sstudents.approved = true) AND (vwselectedgrades.gradeid <> 'W');

CREATE VIEW vwqcoursemarks AS
	SELECT vwstudentgrades.schoolid, vwstudentgrades.schoolname, vwstudentgrades.studentid, vwstudentgrades.studentname, vwstudentgrades.email,
		vwstudentgrades.degreelevelid, vwstudentgrades.degreelevelname, 
		vwstudentgrades.degreeid, vwstudentgrades.degreename, vwstudentgrades.studentdegreeid, vwstudentgrades.completed, vwstudentgrades.started,
		vwstudentgrades.cleared, vwstudentgrades.clearedate, vwstudentgrades.sessionid, vwstudentgrades.approved,
		vwstudentgrades.fullattendance, vwstudentgrades.instructorname, vwstudentgrades.coursetitle, vwstudentgrades.classoption,
		vwstudentgrades.sgradeid, vwstudentgrades.hours, vwstudentgrades.credit, vwstudentgrades.crs_approved,
		vwstudentgrades.dropped, vwstudentgrades.gradeid, vwstudentgrades.gradeweight, vwstudentgrades.minrange,
		vwstudentgrades.maxrange, vwstudentgrades.gpacount,
		scoursemarks.scoursemarkid, scoursemarks.submited, scoursemarks.markdate, scoursemarks.marks,
		scoursemarks.details,
		scourseitems.scourseitemid, scourseitems.scourseitemname, scourseitems.markratio, scourseitems.totalmarks,
		scourseitems.given, scourseitems.deadline, scourseitems.details as itemdetails
	FROM (vwstudentgrades INNER JOIN scoursemarks ON vwstudentgrades.sgradeid = scoursemarks.sgradeid)
		INNER JOIN scourseitems ON scoursemarks.scourseitemid =  scourseitems.scourseitemid;

CREATE VIEW vwstudentsessions AS
	SELECT vwstudentgrades.religionid, vwstudentgrades.religionname, vwstudentgrades.denominationid, vwstudentgrades.denominationname,
		vwstudentgrades.schoolid, vwstudentgrades.schoolname, vwstudentgrades.studentid, vwstudentgrades.studentname, vwstudentgrades.address, vwstudentgrades.zipcode,
		vwstudentgrades.town, vwstudentgrades.addresscountry, vwstudentgrades.telno, vwstudentgrades.email,  
		vwstudentgrades.sponsortypeid, vwstudentgrades.sponsortypename, vwstudentgrades.sponsorid, vwstudentgrades.sponsorname,
		vwstudentgrades.sponsoraddress, vwstudentgrades.sponsorstreet, vwstudentgrades.sponsorpostalcode,
		vwstudentgrades.sponsortown, vwstudentgrades.sponsortelno, vwstudentgrades.sponsoremail, 
		vwstudentgrades.sponsorcountryid, vwstudentgrades.sponsorcountryname,
		vwstudentgrades.accountnumber, vwstudentgrades.Nationality, vwstudentgrades.Nationalitycountry, vwstudentgrades.Sex,
		vwstudentgrades.MaritalStatus, vwstudentgrades.birthdate, vwstudentgrades.firstpasswd, vwstudentgrades.alumnae, 
		vwstudentgrades.onprobation, vwstudentgrades.offcampus, vwstudentgrades.currentcontact, 
		vwstudentgrades.degreelevelid, vwstudentgrades.degreelevelname, vwstudentgrades.degreeid, vwstudentgrades.degreename,
		vwstudentgrades.studentdegreeid, vwstudentgrades.completed, vwstudentgrades.started, vwstudentgrades.cleared, vwstudentgrades.clearedate,
		vwstudentgrades.graduated, vwstudentgrades.graduatedate, vwstudentgrades.dropout, vwstudentgrades.transferin, vwstudentgrades.transferout,
		vwstudentgrades.sessionid, vwstudentgrades.sessionyear, vwstudentgrades.semester, vwstudentgrades.sstart, vwstudentgrades.slatereg, vwstudentgrades.slatechange, vwstudentgrades.slastdrop,
		vwstudentgrades.send, vwstudentgrades.active, vwstudentgrades.mincredits, vwstudentgrades.maxcredits,
		vwstudentgrades.residenceid, vwstudentgrades.residencename, vwstudentgrades.defaultrate,
		vwstudentgrades.residenceoffcampus, vwstudentgrades.residencesex, vwstudentgrades.residencedean,
		vwstudentgrades.sresidenceid, vwstudentgrades.residenceoption, vwstudentgrades.studylevel,
		vwstudentgrades.sstudentid, vwstudentgrades.approved, vwstudentgrades.probation,
		vwstudentgrades.roomnumber, vwstudentgrades.finaceapproval, vwstudentgrades.majorapproval,
		vwstudentgrades.departapproval, vwstudentgrades.overloadapproval, vwstudentgrades.finalised, vwstudentgrades.printed,
		vwstudentgrades.studentdeanapproval, vwstudentgrades.overloadhours,
		(CASE WHEN (sum(vwstudentgrades.gpahours) = 0) THEN 0 ELSE (sum(vwstudentgrades.gpa)/sum(vwstudentgrades.gpahours)) END) as gpa,
		sum(vwstudentgrades.gpahours) as credit, sum(vwstudentgrades.chargehours) as hours
	FROM vwstudentgrades
	WHERE (vwstudentgrades.gradeid<>'W') AND (vwstudentgrades.gradeid<>'AW')
	GROUP BY vwstudentgrades.religionid, vwstudentgrades.religionname, vwstudentgrades.denominationid, vwstudentgrades.denominationname,
		vwstudentgrades.schoolid, vwstudentgrades.schoolname, vwstudentgrades.studentid, vwstudentgrades.studentname, vwstudentgrades.address, vwstudentgrades.zipcode,
		vwstudentgrades.town, vwstudentgrades.addresscountry, vwstudentgrades.telno, vwstudentgrades.email, 
		vwstudentgrades.sponsortypeid, vwstudentgrades.sponsortypename, vwstudentgrades.sponsorid, vwstudentgrades.sponsorname,
		vwstudentgrades.sponsoraddress, vwstudentgrades.sponsorstreet, vwstudentgrades.sponsorpostalcode,
		vwstudentgrades.sponsortown, vwstudentgrades.sponsortelno, vwstudentgrades.sponsoremail, 
		vwstudentgrades.sponsorcountryid, vwstudentgrades.sponsorcountryname,
		vwstudentgrades.accountnumber, vwstudentgrades.Nationality, vwstudentgrades.Nationalitycountry, vwstudentgrades.Sex,
		vwstudentgrades.MaritalStatus, vwstudentgrades.birthdate, vwstudentgrades.firstpasswd, vwstudentgrades.alumnae, 
		vwstudentgrades.onprobation, vwstudentgrades.offcampus, vwstudentgrades.currentcontact, 
		vwstudentgrades.degreelevelid, vwstudentgrades.degreelevelname, vwstudentgrades.degreeid, vwstudentgrades.degreename,
		vwstudentgrades.studentdegreeid, vwstudentgrades.completed, vwstudentgrades.started, vwstudentgrades.cleared, vwstudentgrades.clearedate,
		vwstudentgrades.graduated, vwstudentgrades.graduatedate, vwstudentgrades.dropout, vwstudentgrades.transferin, vwstudentgrades.transferout,
		vwstudentgrades.sessionid, vwstudentgrades.sessionyear, vwstudentgrades.semester, vwstudentgrades.sstart, vwstudentgrades.slatereg, vwstudentgrades.slatechange, vwstudentgrades.slastdrop,
		vwstudentgrades.send, vwstudentgrades.active, vwstudentgrades.mincredits, vwstudentgrades.maxcredits,
		vwstudentgrades.residenceid, vwstudentgrades.residencename, vwstudentgrades.defaultrate,
		vwstudentgrades.residenceoffcampus, vwstudentgrades.residencesex, vwstudentgrades.residencedean,
		vwstudentgrades.sresidenceid, vwstudentgrades.residenceoption, vwstudentgrades.studylevel,
		vwstudentgrades.sstudentid, vwstudentgrades.approved, vwstudentgrades.probation,
		vwstudentgrades.roomnumber, vwstudentgrades.finaceapproval, vwstudentgrades.majorapproval,
		vwstudentgrades.departapproval, vwstudentgrades.overloadapproval, vwstudentgrades.finalised, vwstudentgrades.printed,
		vwstudentgrades.studentdeanapproval, vwstudentgrades.overloadhours;

CREATE VIEW vwcourseoutline (
	orderid,
	studentid,
	studentdegreeid,
	degreeid,
	description,
	courseid,
	coursetitle,
	minor,
	elective,
	yeartaken,
	credithours,
	nogpa,
	gradeid,
	gradeweight
) AS
	SELECT 1, studentdegrees.studentid, studentdegrees.studentdegreeid, studentdegrees.degreeid, majors.majorname, vwmajorcontents.courseid,
		vwmajorcontents.coursetitle, vwmajorcontents.minor, vwmajorcontents.elective,
		vwmajorcontents.yeartaken, 
		vwmajorcontents.credithours, vwmajorcontents.nogpa, vwmajorcontents.gradeid, grades.gradeweight
	FROM (((majors INNER JOIN vwmajorcontents ON majors.majorid = vwmajorcontents.majorid)
		INNER JOIN studentmajors ON vwmajorcontents.majorid = studentmajors.majorid)
		INNER JOIN studentdegrees ON (studentmajors.studentdegreeid = studentdegrees.studentdegreeid)
			AND (vwmajorcontents.bulletingid = studentdegrees.bulletingid))
		INNER JOIN grades ON vwmajorcontents.gradeid = grades.gradeid
	WHERE (studentdegrees.completed = false) AND (studentdegrees.dropout = false);

CREATE VIEW vwcorecourseoutline AS 
	SELECT 1, studentdegrees.studentid, studentdegrees.studentdegreeid, studentdegrees.degreeid, majors.majorname, vwmajorcontents.courseid,
		vwmajorcontents.coursetitle, vwmajorcontents.minor, vwmajorcontents.elective,
		vwmajorcontents.yeartaken, 
		vwmajorcontents.credithours, vwmajorcontents.nogpa, vwmajorcontents.gradeid, grades.gradeweight
	FROM (((majors INNER JOIN vwmajorcontents ON majors.majorid = vwmajorcontents.majorid)
		INNER JOIN studentmajors ON vwmajorcontents.majorid = studentmajors.majorid)
		INNER JOIN studentdegrees ON (studentmajors.studentdegreeid = studentdegrees.studentdegreeid)
			AND (vwmajorcontents.bulletingid = studentdegrees.bulletingid))
		INNER JOIN grades ON vwmajorcontents.gradeid = grades.gradeid
	WHERE (studentmajors.major = true) AND (studentdegrees.dropout = false) AND (studentdegrees.completed = false);

CREATE VIEW vwcoursechecklist AS
	SELECT DISTINCT vwcourseoutline.orderid, vwcourseoutline.studentid, vwcourseoutline.studentdegreeid, vwcourseoutline.degreeid, 
		vwcourseoutline.description, vwcourseoutline.courseid,
		vwcourseoutline.coursetitle, vwcourseoutline.minor, vwcourseoutline.elective, vwcourseoutline.yeartaken, 
		vwcourseoutline.credithours, vwcourseoutline.nogpa, vwcourseoutline.gradeid,
		vwcourseoutline.gradeweight, getcoursedone(vwcourseoutline.studentid, vwcourseoutline.courseid) as courseweight,
		(CASE WHEN (getcoursedone(vwcourseoutline.studentid, vwcourseoutline.courseid)>=vwcourseoutline.gradeweight) THEN true ELSE false END) as coursepased,
		getprereqpassed(vwcourseoutline.studentid, vwcourseoutline.courseid) as prereqpassed
	FROM vwcourseoutline;

CREATE VIEW vwstudentchecklist AS
	SELECT vwcoursechecklist.orderid, vwcoursechecklist.studentid, vwcoursechecklist.studentdegreeid, vwcoursechecklist.degreeid, 
		vwcoursechecklist.description, vwcoursechecklist.courseid, vwcoursechecklist.coursetitle, vwcoursechecklist.minor, 
		vwcoursechecklist.elective, vwcoursechecklist.yeartaken, vwcoursechecklist.credithours, vwcoursechecklist.nogpa, 
		vwcoursechecklist.gradeid, vwcoursechecklist.courseweight, vwcoursechecklist.coursepased, vwcoursechecklist.prereqpassed,
		students.studentname
	FROM vwcoursechecklist INNER JOIN students ON vwcoursechecklist.studentid = students.studentid;

CREATE VIEW vwscoursecheckpass AS
	SELECT vwcoursechecklist.orderid, vwcoursechecklist.studentid, vwcoursechecklist.studentdegreeid, vwcoursechecklist.degreeid, vwcoursechecklist.description,
		vwcoursechecklist.minor, vwcoursechecklist.elective,  vwcoursechecklist.yeartaken, vwcoursechecklist.gradeid,
		vwcoursechecklist.gradeweight, vwcoursechecklist.courseweight, vwcoursechecklist.coursepased, vwcoursechecklist.prereqpassed,
		vwscourse.schoolid, vwscourse.schoolname, vwscourse.departmentid, vwscourse.departmentname,
		vwscourse.degreelevelid, vwscourse.degreelevelname, vwscourse.coursetypeid, vwscourse.coursetypename,
		vwscourse.courseid, vwscourse.credithours, vwscourse.maxcredit, vwscourse.iscurrent, vwscourse.nogpa, 
		vwscourse.instructorid, vwscourse.sessionid, vwscourse.scourseid, vwscourse.classoption, vwscourse.maxclass,
		vwscourse.coursecharge, vwscourse.approved, vwscourse.attendance, 
		vwscourse.fullattendance, vwscourse.instructorname, vwscourse.coursetitle
	FROM vwcoursechecklist INNER JOIN vwscourse ON vwcoursechecklist.courseid = vwscourse.courseid
	WHERE (vwscourse.active = true) AND (vwscourse.approved = false) 
		AND (vwcoursechecklist.coursepased = false) AND (vwcoursechecklist.prereqpassed = true);

CREATE VIEW vwmajorgrades AS
	SELECT vwstudentdegrees.studentid, vwstudentdegrees.studentname, vwstudentdegrees.sex, vwstudentdegrees.degreelevelid, vwstudentdegrees.degreelevelname, 
		vwstudentdegrees.degreeid, vwstudentdegrees.degreename, vwstudentdegrees.studentdegreeid,  vwstudentdegrees.bulletingid,
		studentmajors.studentmajorid, studentmajors.major, studentmajors.nondegree,  
		vwmajorcontents.departmentid, vwmajorcontents.departmentname, vwmajorcontents.majorid, vwmajorcontents.majorname, 
		vwmajorcontents.courseid, vwmajorcontents.coursetitle, vwmajorcontents.contenttypeid, vwmajorcontents.contenttypename,
		vwmajorcontents.elective, vwmajorcontents.yeartaken, vwmajorcontents.prerequisite, vwmajorcontents.majorcontentid,
		vwmajorcontents.minor, vwmajorcontents.gradeid as mingrade,
		vwsgrades.sessionid, vwsgrades.sgradeid, vwsgrades.sstudentid, vwsgrades.gradeid, vwsgrades.gpahours, vwsgrades.gpa,
		vwsgrades.instructorname
	FROM (((vwstudentdegrees INNER JOIN studentmajors ON vwstudentdegrees.studentdegreeid = studentmajors.studentdegreeid)
		INNER JOIN vwmajorcontents ON (vwmajorcontents.majorid = studentmajors.majorid)
			AND (vwmajorcontents.bulletingid = vwstudentdegrees.bulletingid))
		INNER JOIN sstudents ON sstudents.studentdegreeid = vwstudentdegrees.studentdegreeid)
		INNER JOIN vwsgrades ON (vwsgrades.courseid = vwmajorcontents.courseid) and (vwsgrades.sstudentid = sstudents.sstudentid);

CREATE VIEW vwsstudentcharges AS 
	SELECT vwstudentmajors.denominationid, vwstudentmajors.denominationname,
		vwstudentmajors.studentid, vwstudentmajors.studentname, vwstudentmajors.Nationality, vwstudentmajors.Nationalitycountry,
		vwstudentmajors.Sex, vwstudentmajors.MaritalStatus, vwstudentmajors.birthdate, vwstudentmajors.accountnumber,
		vwstudentmajors.telno, vwstudentmajors.email, vwstudentmajors.degreelevelid, vwstudentmajors.degreelevelname, 
		vwstudentmajors.degreeid, vwstudentmajors.degreename,
		vwstudentmajors.studentdegreeid, vwstudentmajors.completed, vwstudentmajors.started, vwstudentmajors.cleared, vwstudentmajors.clearedate,
		vwstudentmajors.graduated, vwstudentmajors.graduatedate, vwstudentmajors.dropout, vwstudentmajors.transferin, vwstudentmajors.transferout,
		vwstudentmajors.schoolid, vwstudentmajors.schoolname, vwstudentmajors.departmentid, vwstudentmajors.departmentname,
		vwstudentmajors.majorid, vwstudentmajors.majorname, vwstudentmajors.electivecredit, vwstudentmajors.domajor, vwstudentmajors.dominor,
		vwstudentmajors.studentmajorid, vwstudentmajors.major, vwstudentmajors.nondegree, 
		sstudents.sstudentid, sstudents.sessionid, sstudents.sresidenceid, sstudents.extacharges, sstudents.probation, sstudents.offcampus,
		sstudents.blockname, sstudents.roomnumber, sstudents.currbalance,
		sstudents.studylevel, sstudents.finalised, sstudents.finaceapproval,
		sstudents.majorapproval, sstudents.chaplainapproval, sstudents.studentdeanapproval, sstudents.overloadapproval,
		sstudents.departapproval, sstudents.overloadhours, sstudents.closed, sstudents.printed,
		sstudents.approved, sstudents.financenarrative, sstudents.noapproval, 
		sstudents.financeclosed, sstudents.ApprovedDate, sstudents.Picked, sessions.active
	FROM vwstudentmajors INNER JOIN sstudents ON vwstudentmajors.studentdegreeid = sstudents.studentdegreeid
		INNER JOIN sessions ON sstudents.sessionid = sessions.sessionid		
		INNER JOIN scharges ON (vwstudentmajors.degreelevelid = scharges.degreelevelid)	AND (sstudents.sessionid = scharges.sessionid);

CREATE VIEW vwscholarships AS
	SELECT students.studentid, students.studentname, students.accountnumber, students.Nationality, students.Sex,
		scholarshiptypes.scholarshiptypeid, scholarshiptypes.scholarshiptypename, scholarshiptypes.scholarshipaccount,
		scholarships.sessionid, scholarships.scholarshipid, scholarships.entrydate, scholarships.paymentdate,
		scholarships.amount, scholarships.approved, scholarships.posted, scholarships.dateposted
	FROM (students INNER JOIN scholarships ON students.studentid = scholarships.studentid)
	INNER JOIN scholarshiptypes ON scholarships.scholarshiptypeid = scholarshiptypes.scholarshiptypeid;

CREATE VIEW vwstudentpayments AS
	SELECT students.studentid, students.studentname, students.accountnumber,
		sstudents.sstudentid, sstudents.sessionid, sstudents.financeclosed, studentpayments.studentpaymentid,
		studentpayments.applydate, studentpayments.amount, studentpayments.approved, studentpayments.approvedtime,
		studentpayments.narrative, studentpayments.Picked, studentpayments.Pickeddate,
		studentpayments.terminalid, phistory.phistoryid, phistory.phistoryname
	FROM (((students INNER JOIN studentdegrees ON students.studentid = studentdegrees.studentid)
		INNER JOIN sstudents ON studentdegrees.studentdegreeid = sstudents.studentdegreeid)
		INNER JOIN studentpayments ON studentpayments.sstudentid = sstudents.sstudentid)
		INNER JOIN PHistory ON PHistory.PHistoryid = studentpayments.PHistoryid;

CREATE VIEW vwsstudentbalances AS
	SELECT vwsstudentcharges.studentid, vwsstudentcharges.studentname, vwsstudentcharges.Nationality,
		vwsstudentcharges.Nationalitycountry, vwsstudentcharges.Sex, vwsstudentcharges.MaritalStatus, vwsstudentcharges.birthdate, 
		vwsstudentcharges.degreelevelid, vwsstudentcharges.degreelevelname,
		vwsstudentcharges.degreeid, vwsstudentcharges.degreename,
		vwsstudentcharges.studentdegreeid, vwsstudentcharges.schoolid, vwsstudentcharges.schoolname, vwsstudentcharges.departmentid, vwsstudentcharges.departmentname,
		vwsstudentcharges.majorid, vwsstudentcharges.majorname, vwsstudentcharges.accountnumber,
		vwsstudentcharges.sstudentid, vwsstudentcharges.sessionid, vwsstudentcharges.sresidenceid, vwsstudentcharges.probation, vwsstudentcharges.offcampus,
		vwsstudentcharges.studylevel, vwsstudentcharges.finalised, vwsstudentcharges.finaceapproval,
		vwsstudentcharges.majorapproval, vwsstudentcharges.chaplainapproval, vwsstudentcharges.studentdeanapproval, vwsstudentcharges.overloadapproval,
		vwsstudentcharges.departapproval, vwsstudentcharges.overloadhours,  vwsstudentcharges.closed, vwsstudentcharges.printed,
		vwsstudentcharges.approved, vwsstudentcharges.financenarrative, vwsstudentcharges.noapproval, 
		vwsstudentcharges.financeclosed, vwsstudentcharges.currbalance,
		vwsstudentcharges.ApprovedDate, vwsstudentcharges.Picked
	FROM vwsstudentcharges;

