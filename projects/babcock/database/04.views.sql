CREATE VIEW vw_student_emails AS
	SELECT entity_id, user_name, mail_user, primary_email as std_email,
		'{PLAIN-MD5}' || entity_password as mail_password, 
		'maildir:/var/stdmail/' || mail_user as userdb_mail,
		'/var/stdmail/' || mail_user as home, '1001'::integer as uid, '1001'::integer as gid
	FROM entitys 
	WHERE entity_type_id = 21;

CREATE OR REPLACE FUNCTION getfirstquarterid(varchar(12)) RETURNS varchar(12) AS $$
	SELECT min(quarterid) 
	FROM qstudents INNER JOIN studentdegrees ON qstudents.studentdegreeid = studentdegrees.studentdegreeid
	WHERE (studentid = $1);
$$ LANGUAGE SQL;

CREATE VIEW denominationview AS
	SELECT religions.religionid, religions.religionname, religions.details as religiondetails,
		denominations.denominationid, denominations.denominationname, denominations.details as denominationdetails
		FROM religions INNER JOIN denominations ON religions.religionid = denominations.religionid;

CREATE VIEW departmentview AS
	SELECT schools.schoolid, schools.schoolname, departments.departmentid, departments.departmentname,
		departments.philosopy, departments.vision, departments.mission, departments.objectives,
		departments.exposures, departments.oppotunities, departments.details, 
		departments.org_id, departments.is_active
	FROM schools INNER JOIN departments ON schools.schoolid = departments.schoolid
	ORDER BY departments.schoolid;

CREATE VIEW sublevelview AS
	SELECT degreelevels.degreelevelid, degreelevels.degreelevelname,
		levellocations.levellocationid, levellocations.levellocationname,
		sublevels.org_id, sublevels.sublevelid, sublevels.sublevelname, sublevels.details
	FROM (sublevels INNER JOIN degreelevels ON sublevels.degreelevelid = degreelevels.degreelevelid)
		INNER JOIN levellocations ON sublevels.levellocationid = levellocations.levellocationid;
		
CREATE VIEW degreeview AS
	SELECT degreelevels.degreelevelid, degreelevels.degreelevelname, degrees.degreeid, degrees.degreename, degrees.details
	FROM degreelevels INNER JOIN degrees ON degreelevels.degreelevelid = degrees.degreelevelid;

CREATE VIEW residencecapacityview AS
	SELECT residences.residenceid, residences.residencename, residencecapacitys.residencecapacityid, 
		residencecapacitys.blockname, residencecapacitys.capacity, residencecapacitys.roomsize, residencecapacitys.narrative
	FROM residencecapacitys INNER JOIN residences ON residencecapacitys.residenceid = residences.residenceid;

CREATE VIEW instructorview AS
	SELECT departmentview.schoolid, departmentview.schoolname, departmentview.departmentid, departmentview.departmentname,
		instructors.instructorid, instructors.instructorname,
		instructors.majoradvisor, instructors.headofdepartment, instructors.headoffaculty, instructors.email, instructors.org_id
	FROM departmentview INNER JOIN instructors ON departmentview.departmentid = instructors.departmentid;

CREATE VIEW courseview AS
	SELECT departmentview.schoolid, departmentview.schoolname, departmentview.departmentid, departmentview.departmentname,
		degreelevels.degreelevelid, degreelevels.degreelevelname, coursetypes.coursetypeid, coursetypes.coursetypename,
		courses.courseid, courses.coursetitle, courses.credithours, courses.maxcredit, courses.labcourse, courses.iscurrent,
		courses.nogpa, courses.yeartaken, courses.details,
		orgs.org_id, orgs.org_name
	FROM ((departmentview INNER JOIN courses ON departmentview.departmentid = courses.departmentid)
		INNER JOIN degreelevels ON courses.degreelevelid = degreelevels.degreelevelid)
		INNER JOIN coursetypes ON courses.coursetypeid = coursetypes.coursetypeid
		INNER JOIN orgs ON courses.org_id = orgs.org_id;

CREATE VIEW prereqview AS
	SELECT courses.courseid, courses.coursetitle, prerequisites.prerequisiteid,  prerequisites.precourseid, 
		bulleting.bulletingid, bulleting.bulletingname, bulleting.startingquarter, bulleting.endingquarter,
		bulleting.iscurrent,
		grades.gradeid, grades.gradeweight,
		prerequisites.optionlevel, prerequisites.narrative, prerequisites.org_id
	FROM ((courses INNER JOIN prerequisites ON courses.courseid = prerequisites.courseid)
		INNER JOIN grades ON prerequisites.gradeid = grades.gradeid)
		INNER JOIN bulleting ON prerequisites.bulletingid = bulleting.bulletingid;

CREATE VIEW prerequisiteview AS
	SELECT courses.courseid as precourseid, courses.coursetitle as precoursetitle,
		prereqview.courseid, prereqview.coursetitle, prereqview.prerequisiteid,  
		prereqview.optionlevel, prereqview.narrative, prereqview.gradeid, prereqview.gradeweight,
		prereqview.bulletingid, prereqview.bulletingname, prereqview.startingquarter, prereqview.endingquarter,
		prereqview.iscurrent, courses.org_id
	FROM courses INNER JOIN prereqview ON courses.courseid = prereqview.precourseid
	ORDER BY prereqview.courseid, prereqview.optionlevel;

CREATE VIEW majorview AS
	SELECT departmentview.schoolid, departmentview.schoolname, departmentview.departmentid, departmentview.departmentname,
		majors.majorid, majors.majorname, majors.electivecredit, majors.majorminimal, majors.minorminimum, majors.coreminimum,
		majors.major, majors.minor, majors.minlevel, majors.maxlevel, majors.details,
		majors.is_active, majors.major_title,
		degreelevels.degreelevelid, degreelevels.degreelevelname,
		orgs.org_id, orgs.org_name
	FROM departmentview INNER JOIN majors ON departmentview.departmentid = majors.departmentid
		INNER JOIN degreelevels ON majors.degreelevelid = degreelevels.degreelevelid
		INNER JOIN orgs ON majors.org_id = orgs.org_id;

CREATE VIEW vw_major_levels AS
	SELECT majors.majorid, majors.majorname, 
		major_levels.org_id, major_levels.major_level_id, major_levels.major_level, major_levels.quarterload, 
		major_levels.details
	FROM major_levels INNER JOIN majors ON major_levels.majorid = majors.majorid;

CREATE VIEW vw_major_bulletings AS
	SELECT majorview.schoolid, majorview.schoolname, majorview.departmentid, majorview.departmentname,
		majorview.majorid, majorview.majorname, majorview.electivecredit, majorview.majorminimal, 
		majorview.minorminimum, majorview.coreminimum, majorview.major, majorview.minor, majorview.details,
		bulleting.bulletingid, bulleting.bulletingname, bulleting.startingquarter,
		bulleting.endingquarter, bulleting.iscurrent
	FROM majorview CROSS JOIN bulleting;

CREATE VIEW majorcontentview AS
	SELECT majorview.schoolid, majorview.departmentid, majorview.departmentname, majorview.majorid, majorview.majorname, 
		majorview.electivecredit, courses.courseid, courses.coursetitle, courses.credithours, courses.nogpa, courses.yeartaken,
		contenttypes.contenttypeid, contenttypes.contenttypename, contenttypes.elective, contenttypes.prerequisite,
		contenttypes.premajor, majorcontents.majorcontentid, majorcontents.gradeid, majorcontents.narrative, 
		majorcontents.quarterdone, majorcontents.minor,
		bulleting.bulletingid, bulleting.bulletingname, bulleting.startingquarter, bulleting.endingquarter,
		bulleting.iscurrent,majorcontents.org_id
	FROM (((majorview INNER JOIN majorcontents ON majorview.majorid = majorcontents.majorid)
		INNER JOIN courses ON majorcontents.courseid = courses.courseid)
		INNER JOIN contenttypes ON majorcontents.contenttypeid = contenttypes.contenttypeid)
		INNER JOIN bulleting ON majorcontents.bulletingid = bulleting.bulletingid;

CREATE VIEW vw_students AS
	SELECT denominationview.religionid, denominationview.religionname, denominationview.denominationid, denominationview.denominationname,
		schools.schoolid, schools.schoolname, departments.departmentid, departments.departmentname,
		students.studentid, students.studentname, students.address, students.zipcode, students.town, 
		c1.countryname as addresscountry, students.telno, students.email,  students.guardianname, students.gaddress,
		students.gzipcode, students.gtown, c2.countryname as gaddresscountry, students.gtelno, students.gemail,
		students.accountnumber, students.Nationality, c3.countryname as Nationalitycountry, students.Sex,
		students.MaritalStatus, students.birthdate, students.firstpasswd, students.alumnae, students.postcontacts, students.onprobation,
		students.seeregistrar, students.seechaplain, students.seesecurity, students.seesss, students.seesdc, students.seehalls,
		students.offcampus, students.currentcontact, students.staff, students.fullbursary, students.newstudent, 
		students.picturefile, students.emailuser, students.matriculate, students.details,
		students.student_edit,
		students.etranzact_card_no, students.org_id,
		entitys.first_password, ('G' || students.studentid) as gstudentid
	FROM (((denominationview INNER JOIN students ON denominationview.denominationid = students.denominationid)
		INNER JOIN departments ON departments.departmentid = students.departmentid)
		INNER JOIN schools ON schools.schoolid = departments.schoolid)
		INNER JOIN countrys as c1 ON students.countrycodeid = c1.countryid
		INNER JOIN countrys as c2 ON students.gcountrycodeid = c2.countryid
		INNER JOIN countrys as c3 ON students.Nationality = c3.countryid
		INNER JOIN entitys ON students.studentid = entitys.user_name;

CREATE VIEW studentview AS
	SELECT denominationview.religionid, denominationview.religionname, denominationview.denominationid, denominationview.denominationname,
		states.stateid, states.statename,
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
		INNER JOIN countrys as c3 ON students.Nationality = c3.countryid
		INNER JOIN states ON students.stateid = states.stateid;

CREATE VIEW studentrequestview AS
	SELECT students.studentid, students.studentname, requesttypes.requesttypeid, requesttypes.requesttypename, requesttypes.toapprove,
		requesttypes.details as typedetails, studentrequests.studentrequestid, studentrequests.narrative, studentrequests.datesent,
		studentrequests.actioned, studentrequests.dateactioned, studentrequests.approved, studentrequests.dateapploved,
		studentrequests.details, studentrequests.reply, students.org_id
	FROM (students INNER JOIN studentrequests ON students.studentid = studentrequests.studentid)
		INNER JOIN requesttypes ON studentrequests.requesttypeid = requesttypes.requesttypeid;

CREATE VIEW studentdegreeview AS
	SELECT studentview.religionid, studentview.religionname, studentview.denominationid, studentview.denominationname,
		studentview.departmentid, studentview.departmentname, studentview.schoolid, studentview.schoolname,
		studentview.stateid, studentview.statename,
		studentview.studentid, studentview.studentname, studentview.address, studentview.zipcode,
		studentview.town, studentview.addresscountry, studentview.telno, studentview.email,  studentview.guardianname, studentview.gaddress,
		studentview.gzipcode, studentview.gtown, studentview.gaddresscountry, studentview.gtelno, studentview.gemail,
		studentview.accountnumber, studentview.Nationality, studentview.Nationalitycountry, studentview.Sex,
		studentview.MaritalStatus, studentview.birthdate, studentview.firstpasswd, studentview.alumnae, studentview.postcontacts,
		studentview.onprobation, studentview.offcampus, studentview.currentcontact,
		sublevelview.degreelevelid, sublevelview.degreelevelname, sublevelview.levellocationid, sublevelview.levellocationname,
		sublevelview.sublevelid, sublevelview.sublevelname, degrees.degreeid, degrees.degreename,
		studentdegrees.studentdegreeid, studentdegrees.completed, studentdegrees.started, studentdegrees.cleared, studentdegrees.clearedate,
		studentdegrees.graduated, studentdegrees.graduatedate, studentdegrees.dropout, studentdegrees.transferin, studentdegrees.transferout,
		studentdegrees.bulletingid, studentdegrees.details, studentdegrees.org_id
	FROM ((studentview INNER JOIN studentdegrees ON studentview.studentid = studentdegrees.studentid)
		INNER JOIN sublevelview ON studentdegrees.sublevelid = sublevelview.sublevelid)
		INNER JOIN degrees ON studentdegrees.degreeid = degrees.degreeid;

CREATE VIEW transcriptprintview AS
	SELECT entitys.entity_id, entitys.entity_name, entitys.user_name, 
		transcriptprint.transcriptprintid, transcriptprint.studentdegreeid,
		transcriptprint.printdate, transcriptprint.	narrative, transcriptprint.org_id
	FROM transcriptprint INNER JOIN entitys ON transcriptprint.entity_id = entitys.entity_id; 

CREATE VIEW transferedcreditsview AS
	SELECT studentdegreeview.degreeid, studentdegreeview.degreename, studentdegreeview.sublevelid, studentdegreeview.sublevelname,
		studentdegreeview.studentid, studentdegreeview.studentname, studentdegreeview.studentdegreeid, courses.courseid, courses.coursetitle,
		transferedcredits.transferedcreditid, transferedcredits.credithours, transferedcredits.narrative,transferedcredits.org_id
	FROM (studentdegreeview INNER JOIN transferedcredits ON studentdegreeview.studentdegreeid = transferedcredits.studentdegreeid)
		INNER JOIN courses ON transferedcredits.courseid = courses.courseid;

CREATE VIEW studentmajorview AS 
	SELECT studentdegreeview.religionid, studentdegreeview.religionname, studentdegreeview.denominationid, studentdegreeview.denominationname,
		studentdegreeview.departmentid as studentdepartmentid, studentdegreeview.departmentname as studentdepartmentname,
		studentdegreeview.schoolid as studentschoolid, studentdegreeview.schoolname as studentschoolname, studentdegreeview.studentid,
		studentdegreeview.studentname, studentdegreeview.Nationality, studentdegreeview.Nationalitycountry, studentdegreeview.Sex,
		studentdegreeview.MaritalStatus, studentdegreeview.birthdate, studentdegreeview.accountnumber,
		studentdegreeview.degreelevelid, studentdegreeview.degreelevelname,
		studentdegreeview.levellocationid, studentdegreeview.levellocationname,
		studentdegreeview.sublevelid, studentdegreeview.sublevelname,
		studentdegreeview.degreeid, studentdegreeview.degreename,
		studentdegreeview.studentdegreeid, studentdegreeview.completed, studentdegreeview.started, studentdegreeview.cleared, studentdegreeview.clearedate,
		studentdegreeview.graduated, studentdegreeview.graduatedate, studentdegreeview.dropout, studentdegreeview.transferin, studentdegreeview.transferout,
		majorview.schoolid, majorview.schoolname, majorview.departmentid, majorview.departmentname,
		majorview.majorid, majorview.majorname, majorview.major as domajor, majorview.minor as dominor,
		majorview.electivecredit, majorview.majorminimal, majorview.minorminimum, majorview.coreminimum,
		studentmajors.studentmajorid, studentmajors.major, studentmajors.nondegree, studentmajors.premajor, studentmajors.details,studentmajors.org_id
	FROM ((studentdegreeview INNER JOIN studentmajors ON studentdegreeview.studentdegreeid = studentmajors.studentdegreeid)
		INNER JOIN majorview ON studentmajors.majorid = majorview.majorid);

CREATE VIEW primarymajorview AS
	SELECT  departments.departmentid, departments.departmentname, majors.majorid, majors.majorname, studentmajors.studentdegreeid	
	FROM (departments INNER JOIN majors ON departments.departmentid = majors.departmentid)
		INNER JOIN studentmajors ON majors.majorid = studentmajors.majorid
	WHERE (studentmajors.major) AND (studentmajors.primarymajor=true); 

CREATE VIEW primajorstudentview AS
	SELECT students.studentid, students.studentname, students.accountnumber, students.Nationality, students.Sex,
		students.MaritalStatus, students.birthdate, students.onprobation, students.offcampus,
		studentdegrees.studentdegreeid, studentdegrees.completed, studentdegrees.started, studentdegrees.graduated,
		primarymajorview.departmentid, primarymajorview.departmentname, primarymajorview.majorid, primarymajorview.majorname
	FROM (students INNER JOIN studentdegrees ON students.studentid = studentdegrees.studentid)
		INNER JOIN primarymajorview ON studentdegrees.studentdegreeid = primarymajorview.studentdegreeid
	WHERE (studentdegrees.completed = false);

CREATE VIEW primajorinstructorview AS
	SELECT instructors.instructorid, instructors.instructorname, primajorstudentview.studentid, primajorstudentview.studentname,
		primajorstudentview.accountnumber, primajorstudentview.Nationality, primajorstudentview.Sex, primajorstudentview.MaritalStatus,
		primajorstudentview.birthdate, primajorstudentview.onprobation, primajorstudentview.offcampus,
		primajorstudentview.studentdegreeid, primajorstudentview.completed, primajorstudentview.started, primajorstudentview.graduated,
		primajorstudentview.departmentid, primajorstudentview.departmentname, primajorstudentview.majorid, primajorstudentview.majorname
	FROM instructors INNER JOIN primajorstudentview ON instructors.departmentid = primajorstudentview.departmentid
	WHERE (instructors.majoradvisor=true);

CREATE VIEW quarterview AS
	SELECT quarters.quarterid, quarters.qstart, quarters.qlatereg, quarters.qlatechange, quarters.qlastdrop,
		quarters.qend, quarters.active, quarters.feesline, quarters.resline, 
		quarters.postgraduate, quarters.mincredits, quarters.maxcredits,
		quarters.org_id, quarters.publishgrades, quarters.details,
		substring(quarters.quarterid from 1 for 9)  as quarteryear, trim(substring(quarters.quarterid from 11 for 2))  as quarter
	FROM quarters
	ORDER BY quarterid desc;

CREATE VIEW activequarter AS
	SELECT quarterid, quarteryear, quarter, qstart, qlatereg, qlatechange, qlastdrop, qend, active, feesline, resline,
		mincredits, maxcredits, publishgrades, org_id, details
	FROM quarterview
	WHERE (active = true);

CREATE VIEW yearview AS
	SELECT quarteryear
	FROM quarterview
	GROUP BY quarteryear
	ORDER BY quarteryear;

CREATE VIEW qcalendarview AS
	SELECT sublevelview.degreelevelid, sublevelview.degreelevelname, sublevelview.sublevelid, sublevelview.sublevelname,
		qcalendar.qcalendarid, qcalendar.quarterid, qcalendar.qdate, qcalendar.event, qcalendar.details, qcalendar.org_id
	FROM sublevelview INNER JOIN qcalendar ON sublevelview.sublevelid = qcalendar.sublevelid;

CREATE VIEW qresidenceview AS
	SELECT residences.residenceid, residences.residencename, residences.defaultrate,
		residences.offcampus, residences.Sex, residences.residencedean,
		qresidences.qresidenceid, qresidences.quarterid, qresidences.residenceoption,
		qresidences.charges, qresidences.charges as residencecharge, qresidences.full_charges,
		qresidences.details,
		quarterview.quarteryear, quarterview.quarter, quarterview.active, qresidences.org_id
	FROM (residences INNER JOIN qresidences ON residences.residenceid = qresidences.residenceid)
	INNER JOIN quarterview ON qresidences.quarterid = quarterview.quarterid;

CREATE VIEW chargeview AS
	SELECT degreelevels.degreelevelid, degreelevels.degreelevelname, 
		sublevels.sublevelid, sublevels.sublevelname,
		qcharges.org_id, qcharges.qchargeid, qcharges.quarterid, qcharges.studylevel, qcharges.narrative,
		qcharges.fees, qcharges.fullfees, qcharges.meal2fees, qcharges.meal3fees, qcharges.premiumhall,
		qcharges.minimalfees, qcharges.firstinstalment, qcharges.firstdate, 
		qcharges.secondinstalment, qcharges.seconddate,
		substring(qcharges.quarterid from 1 for 9)  as quarteryear, substring(qcharges.quarterid from 11 for 2)  as quarter
	FROM degreelevels INNER JOIN qcharges ON degreelevels.degreelevelid = qcharges.degreelevelid
		INNER JOIN sublevels ON qcharges.sublevelid = sublevels.sublevelid;

CREATE VIEW qchargeview AS
	SELECT quarters.quarterid, quarters.qstart, quarters.qlatereg, quarters.qlatechange, quarters.qlastdrop,
		quarters.qend, quarters.active, quarters.feesline, quarters.resline, 
		substring(quarters.quarterid from 1 for 9)  as quarteryear, substring(quarters.quarterid from 11 for 2)  as quarter,
		degreelevels.degreelevelid, degreelevels.degreelevelname, 
		sublevels.sublevelid, sublevels.sublevelname,
		qcharges.org_id, qcharges.qchargeid, qcharges.studylevel, qcharges.narrative,
		qcharges.fees, qcharges.fullfees, qcharges.meal2fees, qcharges.meal3fees, qcharges.premiumhall,
		qcharges.minimalfees, qcharges.firstinstalment, qcharges.firstdate,
		qcharges.secondinstalment, qcharges.seconddate
	FROM quarters INNER JOIN qcharges ON quarters.quarterid = qcharges.quarterid
		INNER JOIN degreelevels ON degreelevels.degreelevelid = qcharges.degreelevelid
		INNER JOIN sublevels ON qcharges.sublevelid = sublevels.sublevelid;

CREATE VIEW qmchargeview AS
	SELECT quarters.quarterid, quarters.qstart, quarters.qlatereg, quarters.qlatechange, quarters.qlastdrop,
		majors.majorid, majors.majorname,
		sublevels.sublevelid, sublevels.sublevelname,
		qmcharges.org_id, qmcharges.qmchargeid, qmcharges.studylevel, qmcharges.charge, qmcharges.fullcharge, 
		qmcharges.narrative
	FROM (quarters INNER JOIN qmcharges ON quarters.quarterid = qmcharges.quarterid)
		INNER JOIN majors ON qmcharges.majorid = majors.majorid
		INNER JOIN sublevels ON qmcharges.sublevelid = sublevels.sublevelid;

CREATE VIEW vwqcharges AS
	SELECT majors.majorid, majors.majorname, 
		qcharges.org_id, qcharges.degreelevelid, qcharges.quarterid, qcharges.studylevel, qcharges.sublevelid,
		qcharges.fullfees, (qcharges.fullfees + qcharges.fullmeal2fees) as fullmeal2fees, 
		(qcharges.fullfees + qcharges.fullmeal3fees) as fullmeal3fees, 
		qcharges.fees, (qcharges.fees + qcharges.meal2fees) as meal2fees, (qcharges.fees + qcharges.meal3fees) as meal3fees,
		(CASE WHEN substring(qcharges.quarterid from 11 for 2) = '1' THEN
		(2 * qcharges.premiumhall + qcharges.fullfees + qcharges.fullmeal2fees)
		ELSE (qcharges.premiumhall + qcharges.fullfees + qcharges.fullmeal2fees) END) as phfullmeal2fees, 
		(CASE WHEN substring(qcharges.quarterid from 11 for 2) = '1' THEN
		(2 * qcharges.premiumhall + qcharges.fullfees + qcharges.fullmeal3fees)
		ELSE (qcharges.premiumhall + qcharges.fullfees + qcharges.fullmeal3fees) END) as phfullmeal3fees, 
		(qcharges.premiumhall + qcharges.fees + qcharges.meal2fees) as phmeal2fees, 
		(qcharges.premiumhall + qcharges.fees + qcharges.meal3fees) as phmeal3fees
	FROM qcharges CROSS JOIN majors
	WHERE (qcharges.org_id = majors.org_id);

CREATE VIEW vwqmajorcharges AS
	SELECT vwqcharges.majorid, vwqcharges.majorname, vwqcharges.degreelevelid, vwqcharges.sublevelid,
		vwqcharges.quarterid, vwqcharges.studylevel, vwqcharges.org_id,
		(COALESCE(qmcharges.fullcharge, 0) + vwqcharges.fullfees) as fullfees, 
		(COALESCE(qmcharges.fullcharge, 0) + COALESCE(qmcharges.meal2charge * 2, 0) + vwqcharges.fullmeal2fees) as fullmeal2fees, 
		(COALESCE(qmcharges.fullcharge, 0) + COALESCE(qmcharges.meal3charge * 2, 0) + vwqcharges.fullmeal3fees) as fullmeal3fees, 
		(COALESCE(qmcharges.charge, 0) + vwqcharges.fees) as fees, 
		(COALESCE(qmcharges.charge, 0) + COALESCE(qmcharges.meal2charge, 0) + vwqcharges.meal2fees) as meal2fees, 
		(COALESCE(qmcharges.charge, 0) + COALESCE(qmcharges.meal3charge, 0) + vwqcharges.meal3fees) as meal3fees,
		(COALESCE(qmcharges.fullcharge, 0) + COALESCE(qmcharges.meal2charge, 0) + COALESCE(qmcharges.phallcharge, 0) + vwqcharges.phfullmeal2fees) as phfullmeal2fees, 
		(COALESCE(qmcharges.fullcharge, 0) + COALESCE(qmcharges.meal3charge, 0) + COALESCE(qmcharges.phallcharge, 0) + vwqcharges.phfullmeal3fees) as phfullmeal3fees,
		(COALESCE(qmcharges.charge, 0) + COALESCE(qmcharges.meal2charge, 0) + COALESCE(qmcharges.phallcharge, 0) + vwqcharges.phmeal2fees) as phmeal2fees, 
		(COALESCE(qmcharges.charge, 0) + COALESCE(qmcharges.meal3charge, 0) + COALESCE(qmcharges.phallcharge, 0) + vwqcharges.phmeal3fees) as phmeal3fees
	FROM vwqcharges LEFT JOIN qmcharges ON (vwqcharges.quarterid = qmcharges.quarterid) 
		AND (vwqcharges.majorid = qmcharges.majorid) AND (vwqcharges.studylevel = qmcharges.studylevel)
		AND (vwqcharges.sublevelid = qmcharges.sublevelid);

CREATE VIEW residenceroom AS
	SELECT residences.residenceid, residences.residencename, residences.offcampus, residences.Sex,
		residenceCapacitys.blockname, residenceCapacitys.capacity, residenceCapacitys.roomsize, 
		generate_series(1, residenceCapacitys.capacity) as roomnumber
	FROM residences INNER JOIN residenceCapacitys ON residences.residenceid = residenceCapacitys.residenceid;

CREATE OR REPLACE FUNCTION roomcount(integer, varchar(12), integer) RETURNS bigint AS $$
	SELECT count(qstudentid) FROM qstudents WHERE (qresidenceid = $1) AND (blockname = $2) AND (roomnumber = $3);
$$ LANGUAGE SQL;

CREATE VIEW qresidenceroom AS
	SELECT residenceroom.residenceid, residenceroom.residencename, residenceroom.roomsize, residenceroom.capacity, 
		residenceroom.blockname, residenceroom.roomnumber, 
		roomcount(qresidences.qresidenceid, residenceroom.blockname, residenceroom.roomnumber) as roomcount,
		residenceroom.roomsize - roomcount(qresidences.qresidenceid, residenceroom.blockname, residenceroom.roomnumber) as roombalance,
		qresidences.qresidenceid, qresidences.quarterid,
		(qresidences.qresidenceid || residenceroom.blockname || 'R' || residenceroom.roomnumber) as roomid
	FROM residenceroom INNER JOIN qresidences ON residenceroom.residenceid = qresidences.residenceid;

CREATE VIEW qstudentresroom AS
	SELECT students.studentid, students.studentname, students.Sex, qstudents.qstudentid,
		qresidenceroom.residenceid, qresidenceroom.residencename, qresidenceroom.roomsize, qresidenceroom.capacity,
		qresidenceroom.roomnumber, qresidenceroom.roomcount, qresidenceroom.roombalance, 
		qresidenceroom.blockname, qresidenceroom.roomid, 
		qresidenceroom.qresidenceid, qresidenceroom.quarterid 
	FROM (((students INNER JOIN studentdegrees ON students.studentid = studentdegrees.studentid)
		INNER JOIN qstudents ON studentdegrees.studentdegreeid = qstudents.studentdegreeid)  
		INNER JOIN qresidenceroom ON qstudents.qresidenceid = qresidenceroom.qresidenceid)
		INNER JOIN quarters ON qstudents.quarterid = quarters.quarterid
	WHERE (quarters.active = true) AND (qresidenceroom.roombalance > 0);

CREATE VIEW currentresidenceview AS
	SELECT residences.residenceid, residences.residencename, residences.offcampus, residences.Sex, residences.residencedean, 
		qresidences.qresidenceid, qresidences.quarterid, qresidences.residenceoption, qresidences.charges, qresidences.details,
		qresidences.org_id,
		students.studentid, students.studentname
	FROM ((residences INNER JOIN qresidences ON residences.residenceid = qresidences.residenceid)
	INNER JOIN quarterview ON qresidences.quarterid = quarterview.quarterid)
	INNER JOIN students ON ((residences.Sex = students.Sex) OR (residences.Sex = 'N')) 
	WHERE (quarterview.active = true);
	
CREATE VIEW vw_qresidence AS
	SELECT residences.residenceid, residences.residencename, residences.offcampus, residences.Sex, residences.residencedean, 
		qresidences.qresidenceid, qresidences.quarterid, qresidences.residenceoption, qresidences.charges, qresidences.details,
		qresidences.org_id,
		students.studentid, students.studentname,
		quarters.active,
		resc.res_capacity, resn.resCount, (resc.res_capacity - resn.resCount) as space_left
	FROM ((residences INNER JOIN qresidences ON residences.residenceid = qresidences.residenceid)
	INNER JOIN quarters ON qresidences.quarterid = quarters.quarterid)
	INNER JOIN students ON ((residences.Sex = students.Sex) OR (residences.Sex = 'N'))
	LEFT JOIN (SELECT residenceid, sum(residencecapacitys.capacity) as res_capacity FROM residencecapacitys
			GROUP BY residenceid) as resc
		ON residences.residenceid = resc.residenceid
	LEFT JOIN (SELECT qresidenceid, count(qstudentid) as resCount FROM qstudents
			GROUP BY qresidenceid) as resn
		ON qresidences.qresidenceid = resn.qresidenceid;

CREATE VIEW qstudentlist AS
	SELECT students.studentid, students.departmentid, students.studentname, students.Sex, students.Nationality, students.MaritalStatus,
		students.birthdate, students.email, studentdegrees.studentdegreeid, studentdegrees.degreeid, studentdegrees.sublevelid,
		qstudents.qstudentid, qstudents.quarterid, qstudents.charges, qstudents.probation, qstudents.roomnumber,
		qstudents.currbalance, qstudents.finaceapproval, qstudents.financenarrative, qstudents.finalised,
		qstudents.majorapproval, qstudents.chaplainapproval, qstudents.overloadapproval, qstudents.studentdeanapproval,
		qstudents.overloadhours, qstudents.intersession, qstudents.closed, qstudents.printed, qstudents.approved,
		substring(qstudents.quarterid from 1 for 9) as academicyear
	FROM (students INNER JOIN studentdegrees ON students.studentid = studentdegrees.studentid)
		INNER JOIN qstudents ON studentdegrees.studentdegreeid = qstudents.studentdegreeid;

CREATE VIEW studentfirstquarterview AS
	SELECT students.studentid, students.studentname, students.Nationality, students.Sex, students.MaritalStatus, 
		studentdegrees.studentdegreeid, studentdegrees.completed, studentdegrees.started, studentdegrees.graduated,
		degrees.degreeid, degrees.degreename, getfirstquarterid(students.studentid) as firstquarterid,
		substring(getfirstquarterid(students.studentid) from 1 for 9) as firstyear,
		substring(getfirstquarterid(students.studentid) from 11 for 1) as firstquarter
	FROM (students INNER JOIN studentdegrees ON students.studentid = studentdegrees.studentid)
		INNER JOIN degrees ON studentdegrees.degreeid = degrees.degreeid;

CREATE VIEW qstudentdegreeview AS
	SELECT students.studentid, students.departmentid, students.studentname, students.Sex, students.Nationality, students.MaritalStatus,
		students.birthdate, students.email, studentdegrees.studentdegreeid, studentdegrees.degreeid,
		sublevels.sublevelid, sublevels.degreelevelid, sublevels.levellocationid, sublevels.sublevelname,
        qstudents.qstudentid, qstudents.quarterid, qstudents.charges, 
		qstudents.probation, qstudents.roomnumber, qstudents.currbalance, qstudents.applicationtime, qstudents.studylevel,
		qstudents.finalised, qstudents.finaceapproval, qstudents.majorapproval, qstudents.chaplainapproval, qstudents.studentdeanapproval, 
		qstudents.overloadapproval, qstudents.overloadhours, qstudents.intersession, qstudents.closed, qstudents.printed, qstudents.approved, qstudents.noapproval,
		qstudents.org_id,
		qresidenceview.residenceid, qresidenceview.residencename, qresidenceview.defaultrate,
		qresidenceview.offcampus, qresidenceview.Sex as residencesex, qresidenceview.residencedean, qresidenceview.charges as residencecharges,
		qresidenceview.qresidenceid, qresidenceview.residenceoption, (qresidenceview.qresidenceid || 'R' || qstudents.roomnumber) as roomid  
	FROM (((students INNER JOIN (studentdegrees INNER JOIN sublevels ON studentdegrees.sublevelid = sublevels.sublevelid) ON students.studentid = studentdegrees.studentid)
		INNER JOIN qstudents ON studentdegrees.studentdegreeid = qstudents.studentdegreeid)
		LEFT JOIN qresidenceview ON qstudents.qresidenceid = qresidenceview.qresidenceid);

CREATE VIEW astudentdegreeview AS
	SELECT schools.schoolid, schools.schoolname, students.studentid, students.studentname, students.Sex, students.Nationality, students.MaritalStatus,
		students.birthdate, students.email, studentdegrees.studentdegreeid, degrees.degreeid, degrees.degreelevelid, degrees.degreename,
        qstudents.qstudentid, qstudents.quarterid, qstudents.charges, 
		qstudents.probation, qstudents.roomnumber, qstudents.currbalance, qstudents.applicationtime, 
		qstudents.finalised, qstudents.finaceapproval, qstudents.majorapproval, qstudents.chaplainapproval, qstudents.studentdeanapproval, 
		qstudents.overloadapproval, qstudents.overloadhours, qstudents.intersession, qstudents.closed, qstudents.printed, qstudents.approved, qstudents.noapproval,
		qstudents.org_id
	FROM ((schools INNER JOIN students ON schools.schoolid = students.departmentid)   
		INNER JOIN (studentdegrees INNER JOIN degrees ON studentdegrees.degreeid = degrees.degreeid) ON students.studentid = studentdegrees.studentid)
		INNER JOIN qstudents ON studentdegrees.studentdegreeid = qstudents.studentdegreeid;

CREATE VIEW qcurrstudentdegreeview AS 
	SELECT qstudentdegreeview.studentid, qstudentdegreeview.departmentid, qstudentdegreeview.studentname, qstudentdegreeview.sex, 
		qstudentdegreeview.nationality, qstudentdegreeview.maritalstatus, qstudentdegreeview.birthdate, qstudentdegreeview.email, 
		qstudentdegreeview.studentdegreeid, qstudentdegreeview.degreeid, qstudentdegreeview.sublevelid, qstudentdegreeview.qstudentid, 
		qstudentdegreeview.quarterid, qstudentdegreeview.charges, qstudentdegreeview.probation, qstudentdegreeview.roomnumber, 
		qstudentdegreeview.currbalance, qstudentdegreeview.finaceapproval, qstudentdegreeview.studylevel, 
		qstudentdegreeview.finalised, qstudentdegreeview.majorapproval, 
		qstudentdegreeview.chaplainapproval, qstudentdegreeview.overloadapproval, 
		qstudentdegreeview.studentdeanapproval, qstudentdegreeview.overloadhours, qstudentdegreeview.intersession, 
		qstudentdegreeview.closed, qstudentdegreeview.printed, qstudentdegreeview.approved, qstudentdegreeview.noapproval, 
		qstudentdegreeview.org_id,
		qstudentdegreeview.qresidenceid, qstudentdegreeview.residenceid, qstudentdegreeview.residencename, qstudentdegreeview.roomid
	FROM qstudentdegreeview JOIN quarters ON qstudentdegreeview.quarterid = quarters.quarterid
	WHERE quarters.active = true;

CREATE VIEW qstudentview AS
	SELECT studentdegreeview.religionid, studentdegreeview.religionname, studentdegreeview.denominationid, studentdegreeview.denominationname,
		studentdegreeview.schoolid, studentdegreeview.schoolname, studentdegreeview.stateid, studentdegreeview.statename,
		studentdegreeview.studentid, studentdegreeview.studentname, studentdegreeview.address, studentdegreeview.zipcode,
		studentdegreeview.town, studentdegreeview.addresscountry, studentdegreeview.telno, studentdegreeview.email,  studentdegreeview.guardianname, studentdegreeview.gaddress,
		studentdegreeview.gzipcode, studentdegreeview.gtown, studentdegreeview.gaddresscountry, studentdegreeview.gtelno, studentdegreeview.gemail,
		studentdegreeview.accountnumber, studentdegreeview.Nationality, studentdegreeview.Nationalitycountry, studentdegreeview.Sex,
		studentdegreeview.MaritalStatus, studentdegreeview.birthdate, studentdegreeview.firstpasswd, studentdegreeview.alumnae, studentdegreeview.postcontacts,
		studentdegreeview.onprobation, studentdegreeview.offcampus as allowoffcampus, studentdegreeview.currentcontact, 
		studentdegreeview.degreelevelid, studentdegreeview.degreelevelname, studentdegreeview.levellocationid, studentdegreeview.levellocationname,
		studentdegreeview.sublevelid, studentdegreeview.sublevelname, studentdegreeview.degreeid, studentdegreeview.degreename,
		studentdegreeview.studentdegreeid, studentdegreeview.completed, studentdegreeview.started, studentdegreeview.cleared, studentdegreeview.clearedate,
		studentdegreeview.graduated, studentdegreeview.graduatedate, studentdegreeview.dropout, studentdegreeview.transferin, studentdegreeview.transferout,
		quarterview.quarterid, quarterview.quarteryear, quarterview.quarter, quarterview.qstart, quarterview.qlatereg, quarterview.qlatechange,
		quarterview.qlastdrop, quarterview.qend, quarterview.active, quarterview.mincredits, quarterview.maxcredits,
		quarterview.publishgrades,
		qresidenceview.residenceid, qresidenceview.residencename, qresidenceview.defaultrate,
		qresidenceview.offcampus as residenceoffcampus, qresidenceview.Sex as residencesex, qresidenceview.residencedean,
		qresidenceview.qresidenceid, qresidenceview.residenceoption, qresidenceview.residencecharge,
		qstudents.qstudentid, qstudents.probation, qstudents.offcampus, qstudents.premiumhall,
		qstudents.mealtype, qstudents.citizengrade, qstudents.citizenmarks, qstudents.blockname, qstudents.roomnumber,
		qstudents.currbalance, qstudents.studylevel, qstudents.applicationtime, qstudents.firstclosetime, qstudents.paymenttype,
		qstudents.ispartpayment, qstudents.finalised, qstudents.clearedfinance, qstudents.finaceapproval, qstudents.majorapproval,
		qstudents.departapproval, qstudents.chaplainapproval, qstudents.studentdeanapproval, qstudents.overloadapproval,
		qstudents.overloadhours, qstudents.intersession, qstudents.financeclosed, qstudents.closed, qstudents.printed,
		qstudents.approved, qstudents.mealticket, qstudents.charges as extacharges, qstudents.org_id
	FROM (((studentdegreeview INNER JOIN qstudents ON studentdegreeview.studentdegreeid = qstudents.studentdegreeid)
		INNER JOIN quarterview ON (qstudents.quarterid = quarterview.quarterid))
		LEFT JOIN qresidenceview ON qstudents.qresidenceid = qresidenceview.qresidenceid);

CREATE VIEW printedstudentview AS
	SELECT qstudentview.religionid, qstudentview.religionname, qstudentview.denominationid, qstudentview.denominationname, qstudentview.schoolid,
		qstudentview.schoolname, qstudentview.studentid, qstudentview.studentname, qstudentview.address, qstudentview.zipcode, qstudentview.town,
		qstudentview.addresscountry, qstudentview.telno, qstudentview.email, qstudentview. guardianname, qstudentview.gaddress, qstudentview.gzipcode,
		qstudentview.gtown, qstudentview.gaddresscountry, qstudentview.gtelno, qstudentview.gemail, accountnumber, qstudentview.Nationality,
		qstudentview.Nationalitycountry, qstudentview.Sex, qstudentview.MaritalStatus, qstudentview.birthdate, qstudentview.firstpasswd, qstudentview.alumnae, 
		qstudentview.postcontacts, qstudentview.onprobation, qstudentview.offcampus, qstudentview.currentcontact, 
		qstudentview.degreelevelid, qstudentview.degreelevelname, 
		qstudentview.levellocationid, qstudentview.levellocationname, qstudentview.sublevelid, qstudentview.sublevelname,
		qstudentview.degreeid, qstudentview.degreename, qstudentview.studentdegreeid, qstudentview.completed, qstudentview.started, qstudentview.cleared, qstudentview.clearedate,
		qstudentview.graduated, qstudentview.graduatedate, qstudentview.dropout, qstudentview.transferin, qstudentview.transferout, 
		qstudentview.quarterid, qstudentview.quarteryear, qstudentview.quarter, qstudentview.qstart, qstudentview.qlatereg, qstudentview.qlatechange, qstudentview.qlastdrop,
		qstudentview.qend, qstudentview.active,
		qstudentview.residenceid, qstudentview.residencename, qstudentview.defaultrate, qstudentview.residenceoffcampus, qstudentview.residencesex, qstudentview.residencedean,
		qstudentview.qresidenceid, qstudentview.residenceoption, qstudentview.qstudentid, qstudentview.approved, qstudentview.probation,
		qstudentview.roomnumber, qstudentview.finaceapproval, qstudentview.majorapproval, qstudentview.departapproval, qstudentview.overloadapproval, qstudentview.finalised, qstudentview.printed,
		qstudentview.org_id, majors.majorname
	FROM (qstudentview LEFT JOIN (studentmajors INNER JOIN majors ON studentmajors.majorid = majors.majorid) ON qstudentview.studentdegreeid = studentmajors.studentdegreeid)
	WHERE (active=true) AND (finalised=true) AND (printed=true);

CREATE VIEW qprimajorinstructorview AS
	SELECT primajorinstructorview.instructorid, primajorinstructorview.instructorname, primajorinstructorview.studentid, primajorinstructorview.studentname,
		primajorinstructorview.accountnumber, primajorinstructorview.Nationality, primajorinstructorview.Sex, primajorinstructorview.MaritalStatus,
		primajorinstructorview.birthdate, primajorinstructorview.onprobation, primajorinstructorview.offcampus,
		primajorinstructorview.studentdegreeid, primajorinstructorview.completed, primajorinstructorview.started, primajorinstructorview.graduated,
		primajorinstructorview.departmentid, primajorinstructorview.departmentname, primajorinstructorview.majorid, primajorinstructorview.majorname,
		qstudents.qstudentid, qstudents.quarterid, qstudents.majorapproval, qstudents.departapproval, qstudents.noapproval,	
		qstudents.org_id
	FROM primajorinstructorview INNER JOIN (qstudents INNER JOIN quarters ON qstudents.quarterid = quarters.quarterid)
		ON primajorinstructorview.studentdegreeid = qstudents.studentdegreeid 
	WHERE (quarters.active = true) AND (qstudents.finalised = true) AND (qstudents.majorapproval = false);

CREATE VIEW qstudentmajorview AS 
	SELECT studentmajorview.religionid, studentmajorview.religionname, studentmajorview.denominationid, studentmajorview.denominationname,
		studentmajorview.schoolid, studentmajorview.schoolname, studentmajorview.departmentid, studentmajorview.departmentname,
		studentmajorview.studentid, studentmajorview.studentname, studentmajorview.Nationality, studentmajorview.Nationalitycountry, studentmajorview.Sex,
		studentmajorview.MaritalStatus, studentmajorview.birthdate, 
		studentmajorview.degreelevelid, studentmajorview.degreelevelname,
		studentmajorview.levellocationid, studentmajorview.levellocationname,
		studentmajorview.sublevelid, studentmajorview.sublevelname,
		studentmajorview.degreeid, studentmajorview.degreename,
		studentmajorview.studentdegreeid, studentmajorview.completed, studentmajorview.started, studentmajorview.cleared, studentmajorview.clearedate,
		studentmajorview.graduated, studentmajorview.graduatedate, studentmajorview.dropout, studentmajorview.transferin, studentmajorview.transferout,
		studentmajorview.schoolid, studentmajorview.schoolname, studentmajorview.departmentid, studentmajorview.departmentname,
		studentmajorview.majorid, studentmajorview.majorname, studentmajorview.electivecredit, studentmajorview.domajor, studentmajorview.dominor,
		studentmajorview.studentmajorid, studentmajorview.major, studentmajorview.nondegree, studentmajorview.premajor,
		qstudents.qstudentid, qstudents.quarterid, qstudents.charges as extacharges, qstudents.approved, qstudents.probation,
		qstudents.roomnumber, qstudents.currbalance, qstudents.finaceapproval, qstudents.majorapproval, 
		qstudents.departapproval, qstudents.overloadapproval, qstudents.finalised, qstudents.printed, qstudents.studylevel,
		qstudents.org_id
	FROM studentmajorview INNER JOIN qstudents ON studentmajorview.studentdegreeid = qstudents.studentdegreeid
	WHERE (qstudents.approved = true);

CREATE VIEW qcourseview AS
	SELECT courseview.schoolid, courseview.schoolname, courseview.departmentid, courseview.departmentname,
		courseview.degreelevelid, courseview.degreelevelname, courseview.coursetypeid, courseview.coursetypename,
		courseview.courseid, courseview.credithours, courseview.maxcredit, courseview.iscurrent,
		courseview.nogpa, courseview.yeartaken, 
		qcourses.instructorid, qcourses.quarterid, qcourses.qcourseid, qcourses.classoption, qcourses.maxclass,
		qcourses.labcourse, qcourses.extracharge, qcourses.approved, qcourses.attendance, qcourses.oldcourseid,
		qcourses.fullattendance, instructors.instructorname, qcourses.coursetitle, quarters.active,
		qcourses.lecturesubmit, qcourses.lsdate, qcourses.departmentsubmit,
		qcourses.dsdate, qcourses.facultysubmit, qcourses.fsdate, qcourses.org_id
	FROM (((courseview INNER JOIN qcourses ON courseview.courseid = qcourses.courseid)
		INNER JOIN instructors ON qcourses.instructorid = instructors.instructorid)
		INNER JOIN quarters ON qcourses.quarterid = quarters.quarterid);
		
CREATE VIEW vwqcourses AS
	SELECT courseview.schoolid, courseview.schoolname, courseview.departmentid, courseview.departmentname,
		courseview.degreelevelid, courseview.degreelevelname, courseview.coursetypeid, courseview.coursetypename,
		courseview.courseid, courseview.credithours, courseview.maxcredit, courseview.iscurrent,
		courseview.nogpa, courseview.yeartaken, instructors.instructorid, instructors.instructorname,
		qcourses.quarterid, qcourses.qcourseid, qcourses.classoption, qcourses.maxclass,
		qcourses.labcourse, qcourses.extracharge, qcourses.approved, qcourses.attendance, qcourses.oldcourseid,
		qcourses.fullattendance, qcourses.coursetitle, qcourses.lecturesubmit, qcourses.lsdate,
		qcourses.departmentsubmit, qcourses.dsdate, qcourses.facultysubmit, qcourses.fsdate, 
		qcourses.org_id, aa.enrolment
	FROM (courseview INNER JOIN qcourses ON courseview.courseid = qcourses.courseid)
		INNER JOIN instructors ON qcourses.instructorid = instructors.instructorid
		LEFT JOIN (SELECT count(qgradeid) enrolment, qcourseid FROM qgrades GROUP BY qcourseid) aa
			ON qcourses.qcourseid = aa.qcourseid;

CREATE VIEW qschoolcourseview AS
	SELECT courseview.schoolid, courseview.schoolname, courseview.departmentid, courseview.departmentname,
		courseview.degreelevelid, courseview.degreelevelname, courseview.coursetypeid, courseview.coursetypename,
		courseview.courseid, courseview.credithours, courseview.maxcredit, courseview.iscurrent,
		courseview.nogpa, courseview.yeartaken, instructors.instructorid, instructors.instructorname,
		qcourses.quarterid, qcourses.qcourseid, qcourses.classoption, qcourses.maxclass,
		qcourses.labcourse, qcourses.extracharge, qcourses.approved, qcourses.attendance, qcourses.oldcourseid,
		qcourses.fullattendance, qcourses.coursetitle, qcourses.lecturesubmit, qcourses.lsdate,
		qcourses.departmentsubmit, qcourses.dsdate, qcourses.facultysubmit, qcourses.fsdate
	FROM ((courseview INNER JOIN qcourses ON courseview.courseid = qcourses.courseid)
		INNER JOIN instructors ON qcourses.instructorid = instructors.instructorid);

CREATE VIEW vwgradeopening AS
	SELECT courseview.schoolid, courseview.schoolname, courseview.departmentid, courseview.departmentname,
		courseview.degreelevelid, courseview.degreelevelname, courseview.coursetypeid, courseview.coursetypename,
		courseview.courseid, courseview.credithours, courseview.maxcredit, courseview.iscurrent,
		courseview.nogpa, courseview.yeartaken, 
		qcourses.instructorid, qcourses.quarterid, qcourses.qcourseid, qcourses.classoption, qcourses.maxclass,
		qcourses.labcourse, qcourses.extracharge, qcourses.approved, qcourses.attendance, qcourses.oldcourseid,
		qcourses.fullattendance, instructors.instructorname, qcourses.coursetitle, 
		qcourses.lecturesubmit, qcourses.lsdate, qcourses.departmentsubmit, qcourses.dsdate, 
		qcourses.facultysubmit, qcourses.fsdate,
		gradeopening.gradeopeningid, gradeopening.requestdate, gradeopening.hodapproval, gradeopening.hodreject,
		gradeopening.hoddate, gradeopening.hodid, gradeopening.regapproval, gradeopening.regreject, gradeopening.regdate,
		gradeopening.regid, gradeopening.deanapproval, gradeopening.deanreject, gradeopening.deandate, gradeopening.deanid,
		gradeopening.details, gradeopening.org_id
	FROM (((courseview INNER JOIN qcourses ON courseview.courseid = qcourses.courseid)
		INNER JOIN instructors ON qcourses.instructorid = instructors.instructorid)
		INNER JOIN gradeopening ON qcourses.qcourseid = gradeopening.qcourseid);
		
CREATE OR REPLACE FUNCTION getqcoursestudents(integer) RETURNS bigint AS $$
	SELECT CASE WHEN count(qgradeid) is null THEN 0 ELSE count(qgradeid) END
	FROM qgrades INNER JOIN qstudents ON qgrades.qstudentid = qstudents.qstudentid 
	WHERE (qgrades.dropped = false) AND (qstudents.finalised = true) AND (qcourseid = $1);
$$ LANGUAGE SQL;

CREATE VIEW currqcourseview AS
	SELECT qcourseview.schoolid, qcourseview.schoolname, qcourseview.departmentid, qcourseview.departmentname,
		qcourseview.degreelevelid, qcourseview.degreelevelname, qcourseview.coursetypeid, qcourseview.coursetypename,
		qcourseview.courseid, qcourseview.credithours, qcourseview.maxcredit, qcourseview.iscurrent,
		qcourseview.nogpa, qcourseview.yeartaken, 
		qcourseview.instructorid, qcourseview.quarterid, qcourseview.qcourseid, qcourseview.classoption, qcourseview.maxclass,
		qcourseview.labcourse, qcourseview.extracharge, qcourseview.approved, qcourseview.attendance, qcourseview.oldcourseid,
		qcourseview.fullattendance, qcourseview.instructorname, qcourseview.coursetitle, qcourseview.org_id
	FROM qcourseview
	WHERE (qcourseview.active = true) AND (qcourseview.approved = false);

CREATE VIEW qtimetableview AS
	SELECT assets.assetid, assets.assetname, assets.location, assets.building, assets.capacity, 
		qcourseview.qcourseid, qcourseview.courseid, qcourseview.coursetitle, qcourseview.instructorid,
		qcourseview.instructorname, qcourseview.quarterid, qcourseview.maxclass, qcourseview.classoption,
		optiontimes.optiontimeid, optiontimes.optiontimename,
		qtimetable.qtimetableid, qtimetable.starttime, qtimetable.endtime, qtimetable.lab,
		qtimetable.details, qtimetable.cmonday, qtimetable.ctuesday, qtimetable.cwednesday, qtimetable.cthursday,
		qtimetable.cfriday, qtimetable.csaturday, qtimetable.csunday, qtimetable.org_id 
	FROM ((assets INNER JOIN qtimetable ON assets.assetid = qtimetable.assetid)
		INNER JOIN qcourseview ON qtimetable.qcourseid = qcourseview.qcourseid)
		INNER JOIN optiontimes ON qtimetable.optiontimeid = optiontimes.optiontimeid
	ORDER BY qtimetable.starttime;

CREATE VIEW qetimetableview AS
	SELECT assets.assetid, assets.assetname, assets.location, assets.building, assets.capacity, 
		qcourseview.qcourseid, qcourseview.courseid, qcourseview.coursetitle, qcourseview.instructorid,
		qcourseview.instructorname, qcourseview.quarterid, qcourseview.maxclass, qcourseview.classoption,
		optiontimes.optiontimeid, optiontimes.optiontimename,
		qexamtimetable.qexamtimetableid, qexamtimetable.starttime, qexamtimetable.endtime, qexamtimetable.lab,
		qexamtimetable.examdate, qexamtimetable.details, qexamtimetable.org_id
	FROM ((assets INNER JOIN qexamtimetable ON assets.assetid = qexamtimetable.assetid)
		INNER JOIN qcourseview ON qexamtimetable.qcourseid = qcourseview.qcourseid)
		INNER JOIN optiontimes ON qexamtimetable.optiontimeid = optiontimes.optiontimeid
	ORDER BY qexamtimetable.examdate, qexamtimetable.starttime;

CREATE OR REPLACE FUNCTION gettimeassetcount(integer, time, time, boolean, boolean, boolean, boolean, boolean, boolean, boolean) RETURNS bigint AS $$
	SELECT count(qtimetableid) FROM qtimetableview
	WHERE (assetid=$1) AND (((starttime, endtime) OVERLAPS ($2, $3))=true) 
	AND ((cmonday and $4) OR (ctuesday and $5) OR (cwednesday and $6) OR (cthursday and $7) OR (cfriday and $8) OR (csaturday and $9) OR (csunday and $10));
$$ LANGUAGE SQL;

CREATE VIEW qassettimetableview AS
	SELECT assetid, assetname, location, building, capacity, qcourseid, courseid, coursetitle, instructorid,
		instructorname, quarterid, maxclass, classoption, optiontimeid, optiontimename,
		qtimetableid, starttime, endtime, lab, details, cmonday, ctuesday, cwednesday, cthursday,
		cfriday, csaturday, csunday, org_id,
		gettimeassetcount(assetid, starttime, endtime, cmonday, ctuesday, cwednesday, cthursday, cfriday, csaturday, csunday) as timeassetcount 
	FROM qtimetableview
	ORDER BY assetid;

CREATE VIEW currtimetableview AS
	SELECT qtimetableview.assetid, qtimetableview.assetname, qtimetableview.location, qtimetableview.building, qtimetableview.capacity, 
		qtimetableview.qcourseid, qtimetableview.courseid, qtimetableview.coursetitle, qtimetableview.instructorid,
		qtimetableview.instructorname, qtimetableview.quarterid, qtimetableview.maxclass, qtimetableview.classoption,
		qtimetableview.optiontimeid, qtimetableview.optiontimename,
		qtimetableview.qtimetableid, qtimetableview.starttime, qtimetableview.endtime, qtimetableview.lab,
		qtimetableview.details, qtimetableview.cmonday, qtimetableview.ctuesday, qtimetableview.cwednesday, qtimetableview.cthursday,
		qtimetableview.cfriday, qtimetableview.csaturday, qtimetableview.csunday, qtimetableview.org_id
	FROM qtimetableview INNER JOIN quarters ON qtimetableview.quarterid = quarters.quarterid 
	WHERE (quarters.active = true)
	ORDER BY qtimetableview.starttime;

CREATE VIEW qcourseitemview AS
	SELECT qcourseview.qcourseid, qcourseview.courseid, qcourseview.coursetitle, qcourseview.instructorname, qcourseview.quarterid,
		qcourseview.classoption, qcourseitems.qcourseitemid, qcourseitems.qcourseitemname, qcourseitems.markratio,
		qcourseitems.totalmarks, qcourseitems.given, qcourseitems.deadline, qcourseitems.details,qcourseview.org_id
	FROM qcourseview INNER JOIN qcourseitems ON qcourseview.qcourseid = qcourseitems.qcourseid;

CREATE VIEW vwcourseitemmarks AS
	SELECT qcourseitems.qcourseid, qcoursemarks.qgradeid, 
		round(SUM(qcoursemarks.marks * qcourseitems.markratio / qcourseitems.totalmarks)) as netscore
	FROM qcourseitems INNER JOIN qcoursemarks ON qcourseitems.qcourseitemid = qcoursemarks.qcourseitemid
	WHERE qcoursemarks.marks > 0
	GROUP BY qcourseitems.qcourseid, qcoursemarks.qgradeid;

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

CREATE VIEW qgradeview AS
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
		INNER JOIN grades ON qgrades.gradeid = grades.gradeid
	WHERE (qgrades.dropped = false);

CREATE VIEW studentgradeview AS
	SELECT qstudentview.religionid, qstudentview.religionname, qstudentview.denominationid, qstudentview.denominationname,
		qstudentview.schoolid, qstudentview.schoolname, qstudentview.studentid, qstudentview.studentname, qstudentview.address, qstudentview.zipcode,
		qstudentview.town, qstudentview.addresscountry, qstudentview.telno, qstudentview.email,  qstudentview.guardianname, qstudentview.gaddress,
		qstudentview.gzipcode, qstudentview.gtown, qstudentview.gaddresscountry, qstudentview.gtelno, qstudentview.gemail,
		qstudentview.accountnumber, qstudentview.Nationality, qstudentview.Nationalitycountry, qstudentview.Sex,
		qstudentview.MaritalStatus, qstudentview.birthdate, qstudentview.firstpasswd, qstudentview.alumnae, qstudentview.postcontacts,
		qstudentview.onprobation, qstudentview.offcampus, qstudentview.currentcontact, 
		qstudentview.degreelevelid, qstudentview.degreelevelname, qstudentview.levellocationid, qstudentview.levellocationname,
		qstudentview.sublevelid, qstudentview.sublevelname, qstudentview.degreeid, qstudentview.degreename,
		qstudentview.studentdegreeid, qstudentview.completed, qstudentview.started, qstudentview.cleared, qstudentview.clearedate,
		qstudentview.graduated, qstudentview.graduatedate, qstudentview.dropout, qstudentview.transferin, qstudentview.transferout,
		qstudentview.quarterid, qstudentview.quarteryear, qstudentview.quarter, qstudentview.qstart, qstudentview.qlatereg, qstudentview.qlatechange, qstudentview.qlastdrop,
		qstudentview.qend, qstudentview.active, qstudentview.mincredits, qstudentview.maxcredits,
		qstudentview.residenceid, qstudentview.residencename, qstudentview.defaultrate,
		qstudentview.residenceoffcampus, qstudentview.residencesex, qstudentview.residencedean,
		qstudentview.qresidenceid, qstudentview.residenceoption, qstudentview.residencecharge,
		qstudentview.qstudentid, qstudentview.extacharges, qstudentview.approved, qstudentview.probation,
		qstudentview.roomnumber, qstudentview.currbalance, qstudentview.finaceapproval, qstudentview.majorapproval,
		qstudentview.departapproval, qstudentview.overloadapproval, qstudentview.finalised, qstudentview.printed,
		qstudentview.studentdeanapproval, qstudentview.overloadhours, qstudentview.studylevel,
		qstudentview.publishgrades, qstudentview.org_id,
		qgradeview.schoolid as crs_schoolid, qgradeview.schoolname as crs_schoolname,
		qgradeview.departmentid as crs_departmentid, qgradeview.departmentname as crs_departmentname,
		qgradeview.degreelevelid as crs_degreelevelid, qgradeview.degreelevelname as crs_degreelevelname,
		qgradeview.coursetypeid, qgradeview.coursetypename, qgradeview.courseid, qgradeview.credithours, qgradeview.iscurrent,
		qgradeview.nogpa, qgradeview.yeartaken, qgradeview.instructormarks, qgradeview.finalmarks,
		qgradeview.instructorid, qgradeview.qcourseid, qgradeview.classoption, qgradeview.maxclass,
		qgradeview.labcourse, qgradeview.extracharge, qgradeview.attendance as crs_attendance, qgradeview.oldcourseid,
		qgradeview.fullattendance, qgradeview.instructorname, qgradeview.coursetitle,
		qgradeview.qgradeid, qgradeview.hours, qgradeview.credit, qgradeview.crs_approved, qgradeview.approvedate, qgradeview.askdrop,	
		qgradeview.askdropdate, qgradeview.dropped, qgradeview.dropdate, qgradeview.repeated, qgradeview.attendance, qgradeview.narrative,
		qgradeview.gradeid, qgradeview.gradeweight, qgradeview.minrange, qgradeview.maxrange, qgradeview.gpacount, qgradeview.gradenarrative,
		qgradeview.gpa, qgradeview.gpahours, qgradeview.chargehours, qgradeview.departmentmarks
	FROM qstudentview INNER JOIN qgradeview ON qstudentview.qstudentid = qgradeview.qstudentid;

CREATE VIEW gradecountview AS
	SELECT qstudents.studentdegreeid,  qcourses.courseid, count(qcourses.qcourseid) as coursecount
	FROM (qgrades INNER JOIN (qcourses INNER JOIN courses ON qcourses.courseid = courses.courseid) ON qgrades.qcourseid = qcourses.qcourseid)
		INNER JOIN qstudents ON qgrades.qstudentid = qstudents.qstudentid
	WHERE (qgrades.gradeid <> 'W') AND (qgrades.gradeid <> 'AW') AND (qgrades.gradeid <> 'NG') AND (qgrades.dropped = false)
		AND (repeated = false) AND (qstudents.approved = true) AND (courses.norepeats = false)
	GROUP BY qstudents.studentdegreeid,  qcourses.courseid;

CREATE VIEW astudentgradeview AS
	SELECT astudentdegreeview.schoolid, astudentdegreeview.schoolname, astudentdegreeview.studentid, astudentdegreeview.studentname, astudentdegreeview.Sex, astudentdegreeview.Nationality,
		astudentdegreeview.MaritalStatus, astudentdegreeview.birthdate, astudentdegreeview.email, astudentdegreeview.studentdegreeid, astudentdegreeview.degreeid,
		astudentdegreeview.degreelevelid, astudentdegreeview.degreename, astudentdegreeview.qstudentid, astudentdegreeview.quarterid, astudentdegreeview.charges, 
		astudentdegreeview.probation, astudentdegreeview.roomnumber, astudentdegreeview.currbalance, astudentdegreeview.applicationtime, 
		astudentdegreeview.finalised, astudentdegreeview.finaceapproval, astudentdegreeview.majorapproval, astudentdegreeview.chaplainapproval,
		astudentdegreeview.studentdeanapproval, astudentdegreeview.overloadapproval, astudentdegreeview.overloadhours, astudentdegreeview.intersession,
		astudentdegreeview.closed, astudentdegreeview.printed, astudentdegreeview.approved, astudentdegreeview.noapproval,
		qgradeview.schoolid as crs_schoolid, qgradeview.schoolname as crs_schoolname,
		qgradeview.departmentid as crs_departmentid, qgradeview.departmentname as crs_departmentname,
		qgradeview.degreelevelid as crs_degreelevelid, qgradeview.degreelevelname as crs_degreelevelname,
		qgradeview.coursetypeid, qgradeview.coursetypename, qgradeview.courseid, qgradeview.credithours, qgradeview.iscurrent,
		qgradeview.nogpa, qgradeview.yeartaken, qgradeview.instructormarks, qgradeview.finalmarks,
		qgradeview.instructorid, qgradeview.qcourseid, qgradeview.classoption, qgradeview.maxclass,
		qgradeview.labcourse, qgradeview.extracharge, qgradeview.attendance as crs_attendance, qgradeview.oldcourseid,
		qgradeview.fullattendance, qgradeview.instructorname, qgradeview.coursetitle,
		qgradeview.qgradeid, qgradeview.hours, qgradeview.credit, qgradeview.crs_approved, qgradeview.approvedate, qgradeview.askdrop,	
		qgradeview.askdropdate, qgradeview.dropped, qgradeview.dropdate, qgradeview.repeated, qgradeview.attendance, qgradeview.narrative,
		qgradeview.gradeid, qgradeview.gradeweight, qgradeview.minrange, qgradeview.maxrange, qgradeview.gpacount, qgradeview.gradenarrative,
		qgradeview.gpa, qgradeview.gpahours, qgradeview.chargehours
	FROM astudentdegreeview INNER JOIN qgradeview ON astudentdegreeview.qstudentid = qgradeview.qstudentid;

CREATE VIEW selcourseview AS
	SELECT courses.courseid, courses.coursetitle, courses.credithours, courses.nogpa, courses.yeartaken,
		qcourses.qcourseid, qcourses.quarterid, qcourses.classoption, qcourses.maxclass, qcourses.labcourse,
		instructors.instructorid, instructors.instructorname, getqcoursestudents(qcourses.qcourseid) as qcoursestudents,
		qgrades.qgradeid, qgrades.qstudentid, qgrades.gradeid, qgrades.hours, qgrades.credit, qgrades.approved,
		qgrades.approvedate, qgrades.askdrop, qgrades.askdropdate, qgrades.dropped,	qgrades.dropdate,
		qgrades.repeated, qgrades.withdrawdate, qgrades.attendance, qgrades.optiontimeid, qgrades.narrative
	FROM (((courses INNER JOIN qcourses ON courses.courseid = qcourses.courseid)
		INNER JOIN instructors ON qcourses.instructorid = instructors.instructorid)
		INNER JOIN qgrades ON qgrades.qcourseid = qcourses.qcourseid)
		INNER JOIN quarters ON qcourses.quarterid = quarters.quarterid
	WHERE (quarters.active = true) AND (qgrades.dropped = false);

CREATE OR REPLACE FUNCTION getcoursedone(varchar(12), varchar(12)) RETURNS float AS $$
	SELECT max(grades.gradeweight)
	FROM (((qcourses INNER JOIN qgrades ON qcourses.qcourseid = qgrades.qcourseid)
		INNER JOIN qstudents ON qgrades.qstudentid = qstudents.qstudentid)
		INNER JOIN grades ON qgrades.gradeid = grades.gradeid)
		INNER JOIN studentdegrees ON qstudents.studentdegreeid = studentdegrees.studentdegreeid
	WHERE (studentdegrees.studentid=$1) AND (qcourses.courseid=$2);		
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
	
	FOR myrec IN SELECT optionlevel, precourseid, gradeweight FROM prereqview WHERE (prereqview.courseid = $2) AND (prereqview.optionlevel > 0) 
	ORDER BY prereqview.optionlevel LOOP
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

CREATE VIEW selectedgradeview AS
	SELECT selcourseview.courseid, selcourseview.coursetitle, selcourseview.credithours, selcourseview.nogpa, selcourseview.yeartaken,
		selcourseview.qcourseid, selcourseview.quarterid, selcourseview.classoption, selcourseview.maxclass, selcourseview.labcourse,
		selcourseview.instructorid, selcourseview.instructorname, selcourseview.qcoursestudents,
		selcourseview.qgradeid, selcourseview.qstudentid, selcourseview.gradeid, selcourseview.hours, selcourseview.credit, selcourseview.approved,
		selcourseview.approvedate, selcourseview.askdrop, selcourseview.askdropdate, selcourseview.dropped,	selcourseview.dropdate,
		selcourseview.repeated, selcourseview.withdrawdate, selcourseview.attendance, selcourseview.optiontimeid, selcourseview.narrative,
		studentdegrees.studentdegreeid, studentdegrees.studentid, students.studentname, students.sex,
		qstudents.org_id,
		getprereqpassed(studentdegrees.studentid, selcourseview.courseid) as prereqpassed
	FROM ((selcourseview INNER JOIN qstudents ON selcourseview.qstudentid = qstudents.qstudentid)
		INNER JOIN studentdegrees ON qstudents.studentdegreeid = studentdegrees.studentdegreeid)
		INNER JOIN students ON studentdegrees.studentid = students.studentid;

CREATE VIEW qselectedgradeview AS
	SELECT courses.courseid, courses.coursetitle, courses.credithours, courses.nogpa, courses.yeartaken,
		qcourses.qcourseid, qcourses.quarterid, qcourses.classoption, qcourses.maxclass, qcourses.labcourse,
		instructors.instructorid, instructors.instructorname,
		qgrades.org_id,
		qgrades.qgradeid, qgrades.qstudentid, qgrades.gradeid, qgrades.hours, qgrades.credit, qgrades.approved,
		qgrades.approvedate, qgrades.askdrop, qgrades.askdropdate, qgrades.dropped,	qgrades.dropdate,
		qgrades.repeated, qgrades.withdrawdate, qgrades.attendance, qgrades.optiontimeid, qgrades.narrative,
		studentdegrees.studentdegreeid, studentdegrees.studentid, students.studentname, students.sex
	FROM ((((courses INNER JOIN qcourses ON courses.courseid = qcourses.courseid)
		INNER JOIN instructors ON qcourses.instructorid = instructors.instructorid)
		INNER JOIN qgrades ON qgrades.qcourseid = qcourses.qcourseid)
		INNER JOIN quarters ON qcourses.quarterid = quarters.quarterid)
		INNER JOIN (qstudents INNER JOIN (studentdegrees INNER JOIN students 
			ON studentdegrees.studentid = students.studentid)
			ON qstudents.studentdegreeid = studentdegrees.studentdegreeid)
			ON qgrades.qstudentid = qstudents.qstudentid
	WHERE (quarters.active = true) AND (qgrades.dropped = false);

CREATE VIEW studenttimetableview AS
	SELECT assets.assetid, assets.assetname, assets.location, assets.building, assets.capacity, 
		selectedgradeview.courseid, selectedgradeview.coursetitle, selectedgradeview.credithours, selectedgradeview.nogpa, selectedgradeview.yeartaken,
		selectedgradeview.qcourseid, selectedgradeview.quarterid, selectedgradeview.classoption, selectedgradeview.maxclass, selectedgradeview.labcourse,
		selectedgradeview.instructorid, selectedgradeview.instructorname, selectedgradeview.studentdegreeid, selectedgradeview.studentid,
		selectedgradeview.qgradeid, selectedgradeview.qstudentid, selectedgradeview.gradeid, selectedgradeview.hours, selectedgradeview.credit, selectedgradeview.approved,
		selectedgradeview.approvedate, selectedgradeview.askdrop, selectedgradeview.askdropdate, selectedgradeview.dropped,	selectedgradeview.dropdate,
		selectedgradeview.repeated, selectedgradeview.withdrawdate, selectedgradeview.attendance, selectedgradeview.narrative,
		selectedgradeview.org_id,
		qtimetable.qtimetableid, qtimetable.starttime, qtimetable.endtime, qtimetable.lab,
		qtimetable.details, qtimetable.cmonday, qtimetable.ctuesday, qtimetable.cwednesday, qtimetable.cthursday,
		qtimetable.cfriday, qtimetable.csaturday, qtimetable.csunday,
		optiontimes.optiontimeid, optiontimes.optiontimename
	FROM (assets INNER JOIN (qtimetable INNER JOIN optiontimes ON qtimetable.optiontimeid = optiontimes.optiontimeid) ON assets.assetid = qtimetable.assetid)
		INNER JOIN selectedgradeview ON (qtimetable.qcourseid = selectedgradeview.qcourseid AND qtimetable.optiontimeid =  selectedgradeview.optiontimeid)
	ORDER BY qtimetable.starttime;

CREATE VIEW qexamtimetableview AS
	SELECT selcourseview.courseid, selcourseview.coursetitle, selcourseview.credithours, selcourseview.nogpa, selcourseview.yeartaken,
		selcourseview.qcourseid, selcourseview.quarterid, selcourseview.classoption, selcourseview.maxclass, selcourseview.labcourse,
		selcourseview.instructorid, selcourseview.instructorname, selcourseview.qcoursestudents,
		selcourseview.qgradeid, selcourseview.qstudentid, selcourseview.gradeid, selcourseview.hours, selcourseview.credit, selcourseview.approved,
		selcourseview.approvedate, selcourseview.askdrop, selcourseview.askdropdate, selcourseview.dropped,	selcourseview.dropdate,
		selcourseview.repeated, selcourseview.withdrawdate, selcourseview.attendance, selcourseview.optiontimeid, selcourseview.narrative,
		studentdegrees.studentdegreeid, studentdegrees.studentid, students.studentname, students.sex,
		qexamtimetable.qexamtimetableid, qexamtimetable.examdate, qexamtimetable.starttime, qexamtimetable.endtime, qexamtimetable.lab
	FROM (((selcourseview INNER JOIN qstudents ON selcourseview.qstudentid = qstudents.qstudentid)
		INNER JOIN studentdegrees ON qstudents.studentdegreeid = studentdegrees.studentdegreeid)
		INNER JOIN students ON studentdegrees.studentid = students.studentid)
		INNER JOIN qexamtimetable ON (qexamtimetable.qcourseid = selcourseview.qcourseid)
	WHERE (qstudents.approved = true) AND (selcourseview.gradeid <> 'W');

CREATE VIEW qcoursemarkview AS
	SELECT studentgradeview.schoolid, studentgradeview.schoolname, studentgradeview.studentid, studentgradeview.studentname, studentgradeview.email,
		studentgradeview.degreelevelid, studentgradeview.degreelevelname, studentgradeview.sublevelid, studentgradeview.sublevelname, 
		studentgradeview.degreeid, studentgradeview.degreename, studentgradeview.studentdegreeid, studentgradeview.completed, studentgradeview.started,
		studentgradeview.cleared, studentgradeview.clearedate, studentgradeview.quarterid, studentgradeview.approved,
		studentgradeview.fullattendance, studentgradeview.instructorname, studentgradeview.coursetitle, studentgradeview.classoption,
		studentgradeview.qgradeid, studentgradeview.hours, studentgradeview.credit, studentgradeview.crs_approved,
		studentgradeview.dropped, studentgradeview.gradeid, studentgradeview.gradeweight, studentgradeview.minrange,
		studentgradeview.maxrange, studentgradeview.gpacount,
		qcoursemarks.qcoursemarkid, qcoursemarks.submited, qcoursemarks.markdate, qcoursemarks.marks,
		qcoursemarks.details, qcoursemarks.org_id,
		qcourseitems.qcourseitemid, qcourseitems.qcourseitemname, qcourseitems.markratio, qcourseitems.totalmarks,
		qcourseitems.given, qcourseitems.deadline, qcourseitems.details as itemdetails
	FROM (studentgradeview INNER JOIN qcoursemarks ON studentgradeview.qgradeid = qcoursemarks.qgradeid)
		INNER JOIN qcourseitems ON qcoursemarks.qcourseitemid =  qcourseitems.qcourseitemid;

CREATE VIEW studentquarterview AS
	SELECT studentgradeview.religionid, studentgradeview.religionname, studentgradeview.denominationid, studentgradeview.denominationname,
		studentgradeview.schoolid, studentgradeview.schoolname, studentgradeview.studentid, studentgradeview.studentname, studentgradeview.address, studentgradeview.zipcode,
		studentgradeview.town, studentgradeview.addresscountry, studentgradeview.telno, studentgradeview.email,  studentgradeview.guardianname, studentgradeview.gaddress,
		studentgradeview.gzipcode, studentgradeview.gtown, studentgradeview.gaddresscountry, studentgradeview.gtelno, studentgradeview.gemail,
		studentgradeview.accountnumber, studentgradeview.Nationality, studentgradeview.Nationalitycountry, studentgradeview.Sex,
		studentgradeview.MaritalStatus, studentgradeview.birthdate, studentgradeview.firstpasswd, studentgradeview.alumnae, studentgradeview.postcontacts,
		studentgradeview.onprobation, studentgradeview.offcampus, studentgradeview.currentcontact, 
		studentgradeview.degreelevelid, studentgradeview.degreelevelname, studentgradeview.levellocationid, studentgradeview.levellocationname,
		studentgradeview.sublevelid, studentgradeview.sublevelname, studentgradeview.degreeid, studentgradeview.degreename,
		studentgradeview.studentdegreeid, studentgradeview.completed, studentgradeview.started, studentgradeview.cleared, studentgradeview.clearedate,
		studentgradeview.graduated, studentgradeview.graduatedate, studentgradeview.dropout, studentgradeview.transferin, studentgradeview.transferout,
		studentgradeview.quarterid, studentgradeview.quarteryear, studentgradeview.quarter, studentgradeview.qstart, studentgradeview.qlatereg, studentgradeview.qlatechange, studentgradeview.qlastdrop,
		studentgradeview.qend, studentgradeview.active, studentgradeview.mincredits, studentgradeview.maxcredits,
		studentgradeview.residenceid, studentgradeview.residencename, studentgradeview.defaultrate,
		studentgradeview.residenceoffcampus, studentgradeview.residencesex, studentgradeview.residencedean,
		studentgradeview.qresidenceid, studentgradeview.residenceoption, studentgradeview.studylevel,
		studentgradeview.qstudentid, studentgradeview.approved, studentgradeview.probation,
		studentgradeview.roomnumber, studentgradeview.finaceapproval, studentgradeview.majorapproval,
		studentgradeview.departapproval, studentgradeview.overloadapproval, studentgradeview.finalised, studentgradeview.printed,
		studentgradeview.studentdeanapproval, studentgradeview.overloadhours,
		studentgradeview.org_id,
		(CASE WHEN (sum(studentgradeview.gpahours) = 0) THEN 0 ELSE (sum(studentgradeview.gpa)/sum(studentgradeview.gpahours)) END) as gpa,
		sum(studentgradeview.gpahours) as credit, sum(studentgradeview.chargehours) as hours
	FROM studentgradeview
	WHERE (studentgradeview.gradeid<>'W') AND (studentgradeview.gradeid<>'AW')
	GROUP BY studentgradeview.religionid, studentgradeview.religionname, studentgradeview.denominationid, studentgradeview.denominationname,
		studentgradeview.schoolid, studentgradeview.schoolname, studentgradeview.studentid, studentgradeview.studentname, studentgradeview.address, studentgradeview.zipcode,
		studentgradeview.town, studentgradeview.addresscountry, studentgradeview.telno, studentgradeview.email,  studentgradeview.guardianname, studentgradeview.gaddress,
		studentgradeview.gzipcode, studentgradeview.gtown, studentgradeview.gaddresscountry, studentgradeview.gtelno, studentgradeview.gemail,
		studentgradeview.accountnumber, studentgradeview.Nationality, studentgradeview.Nationalitycountry, studentgradeview.Sex,
		studentgradeview.MaritalStatus, studentgradeview.birthdate, studentgradeview.firstpasswd, studentgradeview.alumnae, studentgradeview.postcontacts,
		studentgradeview.onprobation, studentgradeview.offcampus, studentgradeview.currentcontact, 
		studentgradeview.degreelevelid, studentgradeview.degreelevelname, studentgradeview.levellocationid, studentgradeview.levellocationname,
		studentgradeview.sublevelid, studentgradeview.sublevelname, studentgradeview.degreeid, studentgradeview.degreename,
		studentgradeview.studentdegreeid, studentgradeview.completed, studentgradeview.started, studentgradeview.cleared, studentgradeview.clearedate,
		studentgradeview.graduated, studentgradeview.graduatedate, studentgradeview.dropout, studentgradeview.transferin, studentgradeview.transferout,
		studentgradeview.quarterid, studentgradeview.quarteryear, studentgradeview.quarter, studentgradeview.qstart, studentgradeview.qlatereg, studentgradeview.qlatechange, studentgradeview.qlastdrop,
		studentgradeview.qend, studentgradeview.active, studentgradeview.mincredits, studentgradeview.maxcredits,
		studentgradeview.residenceid, studentgradeview.residencename, studentgradeview.defaultrate,
		studentgradeview.residenceoffcampus, studentgradeview.residencesex, studentgradeview.residencedean,
		studentgradeview.qresidenceid, studentgradeview.residenceoption, studentgradeview.studylevel,
		studentgradeview.qstudentid, studentgradeview.approved, studentgradeview.probation,
		studentgradeview.roomnumber, studentgradeview.finaceapproval, studentgradeview.majorapproval,
		studentgradeview.departapproval, studentgradeview.overloadapproval, studentgradeview.finalised, studentgradeview.printed,
		studentgradeview.studentdeanapproval, studentgradeview.overloadhours, studentgradeview.org_id;

CREATE VIEW courseoutline AS
	SELECT 3 as orderid, studentdegrees.studentid, studentdegrees.studentdegreeid, studentdegrees.degreeid, 
		studentdegrees.org_id, majors.majorname as description, majorcontentview.courseid,
		majorcontentview.coursetitle, majorcontentview.minor, majorcontentview.elective,
		majorcontentview.yeartaken, majorcontentview.quarterdone, 
		majorcontentview.credithours, majorcontentview.nogpa, majorcontentview.gradeid, grades.gradeweight
	FROM (((majors INNER JOIN majorcontentview ON majors.majorid = majorcontentview.majorid)
		INNER JOIN studentmajors ON majorcontentview.majorid = studentmajors.majorid)
		INNER JOIN studentdegrees ON (studentmajors.studentdegreeid = studentdegrees.studentdegreeid)
			AND (majorcontentview.bulletingid = studentdegrees.bulletingid))
		INNER JOIN grades ON majorcontentview.gradeid = grades.gradeid
	WHERE ((not studentmajors.premajor and majorcontentview.premajor)=false) AND ((not studentmajors.nondegree and majorcontentview.prerequisite)=false)
		and (studentdegrees.completed=false) and (studentdegrees.dropout=false);

CREATE VIEW corecourseoutline AS 
	SELECT 3 AS orderid, studentdegrees.studentid, studentdegrees.studentdegreeid, studentdegrees.degreeid, 
		studentdegrees.org_id, majors.majorname AS description,
		majorcontentview.courseid, majorcontentview.coursetitle, majorcontentview.minor,
		majorcontentview.elective, majorcontentview.yeartaken, majorcontentview.quarterdone,
		majorcontentview.credithours, majorcontentview.nogpa, majorcontentview.gradeid, grades.gradeweight
	FROM (((majors INNER JOIN majorcontentview ON majors.majorid = majorcontentview.majorid)
		INNER JOIN studentmajors ON majorcontentview.majorid = studentmajors.majorid)
		INNER JOIN studentdegrees ON (studentmajors.studentdegreeid = studentdegrees.studentdegreeid)
			AND (majorcontentview.bulletingid = studentdegrees.bulletingid))
		INNER JOIN grades ON majorcontentview.gradeid = grades.gradeid
	WHERE (studentmajors.major = true) AND (studentdegrees.dropout = false) AND (studentdegrees.completed = false);

CREATE VIEW coursechecklist AS
	SELECT DISTINCT courseoutline.orderid, courseoutline.studentid, courseoutline.studentdegreeid, courseoutline.degreeid, 
		courseoutline.org_id, courseoutline.description, courseoutline.courseid,
		courseoutline.coursetitle, courseoutline.minor, courseoutline.elective, courseoutline.yeartaken, courseoutline.quarterdone,
		courseoutline.credithours, courseoutline.nogpa, courseoutline.gradeid,
		courseoutline.gradeweight, getcoursedone(courseoutline.studentid, courseoutline.courseid) as courseweight,
		(CASE WHEN (getcoursedone(courseoutline.studentid, courseoutline.courseid)>=courseoutline.gradeweight) THEN true ELSE false END) as coursepased,
		getprereqpassed(courseoutline.studentid, courseoutline.courseid) as prereqpassed
	FROM courseoutline;

CREATE VIEW studentchecklist AS
	SELECT coursechecklist.orderid, coursechecklist.studentid, coursechecklist.studentdegreeid, coursechecklist.degreeid, 
		coursechecklist.org_id, coursechecklist.description, coursechecklist.courseid,
		coursechecklist.coursetitle, coursechecklist.minor, coursechecklist.elective, coursechecklist.yeartaken, coursechecklist.quarterdone,
		coursechecklist.credithours, coursechecklist.nogpa, coursechecklist.gradeid,
		coursechecklist.courseweight, coursechecklist.coursepased, coursechecklist.prereqpassed,
		students.studentname
	FROM coursechecklist INNER JOIN students ON coursechecklist.studentid = students.studentid;

CREATE VIEW qcoursecheckpass AS
	SELECT coursechecklist.orderid, coursechecklist.studentid, coursechecklist.studentdegreeid, coursechecklist.degreeid, 
		coursechecklist.description,
		coursechecklist.minor, coursechecklist.elective,  coursechecklist.yeartaken, coursechecklist.quarterdone, coursechecklist.gradeid,
		coursechecklist.gradeweight, coursechecklist.courseweight, coursechecklist.coursepased, coursechecklist.prereqpassed,
		qcourseview.schoolid, qcourseview.schoolname, qcourseview.departmentid, qcourseview.departmentname,
		qcourseview.degreelevelid, qcourseview.degreelevelname, qcourseview.coursetypeid, qcourseview.coursetypename,
		qcourseview.courseid, qcourseview.credithours, qcourseview.maxcredit, qcourseview.iscurrent, qcourseview.nogpa, 
		qcourseview.instructorid, qcourseview.quarterid, qcourseview.qcourseid, qcourseview.classoption, qcourseview.maxclass,
		qcourseview.labcourse, qcourseview.extracharge, qcourseview.approved, qcourseview.attendance, qcourseview.oldcourseid,
		qcourseview.fullattendance, qcourseview.instructorname, qcourseview.coursetitle,
		qcourseview.org_id
	FROM coursechecklist INNER JOIN qcourseview ON coursechecklist.courseid = qcourseview.courseid
	WHERE (qcourseview.active = true) AND (qcourseview.approved = false) 
		AND (coursechecklist.coursepased = false) AND (coursechecklist.prereqpassed = true);

CREATE VIEW coregradeview AS 
	SELECT studentgradeview.schoolid, studentgradeview.schoolname, studentgradeview.studentid, studentgradeview.studentname, studentgradeview.sex,
		studentgradeview.degreeid, studentgradeview.degreename, studentgradeview.studentdegreeid, studentgradeview.quarterid, studentgradeview.quarteryear,
		studentgradeview.quarter, studentgradeview.coursetypeid, studentgradeview.coursetypename, studentgradeview.courseid, studentgradeview.nogpa,
		studentgradeview.instructorid, studentgradeview.qcourseid, studentgradeview.classoption, studentgradeview.labcourse, studentgradeview.instructorname,
		studentgradeview.coursetitle, studentgradeview.qgradeid, studentgradeview.hours, studentgradeview.credit, studentgradeview.gpa, studentgradeview.gradeid,
		studentgradeview.repeated, studentgradeview.gpahours, studentgradeview.chargehours, studentgradeview.org_id,
		corecourseoutline.description, corecourseoutline.minor, corecourseoutline.elective, corecourseoutline.quarterdone
	FROM corecourseoutline INNER JOIN studentgradeview ON (corecourseoutline.studentdegreeid = studentgradeview.studentdegreeid) AND (corecourseoutline.courseid = studentgradeview.courseid)
	WHERE (studentgradeview.approved = true) AND (corecourseoutline.minor = false);

CREATE VIEW majorgradeview AS
	SELECT studentdegreeview.studentid, studentdegreeview.studentname, studentdegreeview.sex, studentdegreeview.degreelevelid, studentdegreeview.degreelevelname, 
		studentdegreeview.levellocationid, studentdegreeview.levellocationname, studentdegreeview.sublevelid, studentdegreeview.sublevelname, 
		studentdegreeview.degreeid, studentdegreeview.degreename, studentdegreeview.studentdegreeid,  studentdegreeview.bulletingid,
		studentmajors.studentmajorid, studentmajors.major, studentmajors.nondegree, studentmajors.premajor, 
		majorcontentview.departmentid, majorcontentview.departmentname, majorcontentview.majorid, majorcontentview.majorname, 
		majorcontentview.courseid, majorcontentview.coursetitle, majorcontentview.contenttypeid, majorcontentview.contenttypename,
		majorcontentview.elective, majorcontentview.yeartaken, majorcontentview.quarterdone, majorcontentview.prerequisite, majorcontentview.majorcontentid,
		majorcontentview.premajor as premajoritem, majorcontentview.minor, majorcontentview.gradeid as mingrade,
		qgradeview.quarterid, qgradeview.qgradeid, qgradeview.qstudentid, qgradeview.gradeid, qgradeview.gpahours, qgradeview.gpa,
		qgradeview.instructorname
	FROM (((studentdegreeview INNER JOIN studentmajors ON studentdegreeview.studentdegreeid = studentmajors.studentdegreeid)
		INNER JOIN majorcontentview ON (majorcontentview.majorid = studentmajors.majorid)
			AND (majorcontentview.bulletingid = studentdegreeview.bulletingid))
		INNER JOIN qstudents ON qstudents.studentdegreeid = studentdegreeview.studentdegreeid)
		INNER JOIN qgradeview ON (qgradeview.courseid = majorcontentview.courseid) and (qgradeview.qstudentid = qstudents.qstudentid);

CREATE VIEW vwstudentmajors AS 
	SELECT denominations.denominationid, denominations.denominationname, students.studentid, countrys.countryname as Nationalitycountry,
		students.studentname, students.Nationality, students.Sex, students.MaritalStatus, students.birthdate, students.accountnumber,
		students.mobile, students.telno, students.email, students.emailuser, students.picturefile,
		sublevelview.degreelevelid, sublevelview.degreelevelname, sublevelview.sublevelid, sublevelview.sublevelname,
		degrees.degreeid, degrees.degreename,
		studentdegrees.studentdegreeid, studentdegrees.completed, studentdegrees.started, studentdegrees.cleared, studentdegrees.clearedate,
		studentdegrees.graduated, studentdegrees.graduatedate, studentdegrees.dropout, studentdegrees.transferin, studentdegrees.transferout,
		majorview.schoolid, majorview.schoolname, majorview.departmentid, majorview.departmentname,
		majorview.majorid, majorview.majorname, majorview.major as domajor, majorview.minor as dominor,
		majorview.electivecredit, majorview.majorminimal, majorview.minorminimum, majorview.coreminimum,
		studentmajors.org_id, studentmajors.studentmajorid, studentmajors.major, studentmajors.nondegree, studentmajors.premajor, 
		studentmajors.details
	FROM (((students INNER JOIN denominations ON students.denominationid = denominations.denominationid)
		INNER JOIN countrys ON students.Nationality = countrys.countryid)
		INNER JOIN ((studentdegrees INNER JOIN sublevelview ON studentdegrees.sublevelid = sublevelview.sublevelid)
			INNER JOIN degrees ON studentdegrees.degreeid = degrees.degreeid)
			ON students.studentid = studentdegrees.studentid)
		INNER JOIN (studentmajors INNER JOIN majorview ON studentmajors.majorid = majorview.majorid)
			ON studentdegrees.studentdegreeid = studentmajors.studentdegreeid;

CREATE OR REPLACE VIEW vwqstudentcharges AS 
	SELECT vwstudentmajors.denominationid, vwstudentmajors.denominationname, vwstudentmajors.studentid, vwstudentmajors.studentname, 
		vwstudentmajors.nationality, vwstudentmajors.nationalitycountry, vwstudentmajors.sex, vwstudentmajors.maritalstatus, vwstudentmajors.birthdate, 
		vwstudentmajors.accountnumber, vwstudentmajors.mobile, vwstudentmajors.telno, vwstudentmajors.email, vwstudentmajors.emailuser, 
		vwstudentmajors.picturefile, vwstudentmajors.degreelevelid, vwstudentmajors.degreelevelname, sublevels.sublevelid, sublevels.sublevelname,
		vwstudentmajors.degreeid, vwstudentmajors.degreename, vwstudentmajors.studentdegreeid, vwstudentmajors.completed, 
		vwstudentmajors.started, vwstudentmajors.cleared, vwstudentmajors.clearedate, vwstudentmajors.graduated, vwstudentmajors.graduatedate, 
		vwstudentmajors.dropout, vwstudentmajors.transferin, vwstudentmajors.transferout, vwstudentmajors.schoolid, vwstudentmajors.schoolname, 
		vwstudentmajors.departmentid, vwstudentmajors.departmentname, vwstudentmajors.majorid, vwstudentmajors.majorname, vwstudentmajors.electivecredit, 
		vwstudentmajors.domajor, vwstudentmajors.dominor, vwstudentmajors.studentmajorid, vwstudentmajors.major, vwstudentmajors.nondegree, 
		vwstudentmajors.premajor, qstudents.qstudentid, qstudents.quarterid, qstudents.qresidenceid, qstudents.charges, qstudents.probation, 
		qstudents.offcampus, qstudents.citizengrade, qstudents.citizenmarks, qstudents.blockname, qstudents.roomnumber, qstudents.currbalance, 
		qstudents.studylevel, qstudents.mealtype, qstudents.applicationtime, qstudents.finalised, qstudents.finaceapproval, qstudents.majorapproval, 
		qstudents.chaplainapproval, qstudents.studentdeanapproval, qstudents.overloadapproval, qstudents.departapproval, qstudents.overloadhours, 
		qstudents.intersession, qstudents.closed, qstudents.printed, qstudents.approved, qstudents.financenarrative, qstudents.noapproval, 
		qstudents.premiumhall, qstudents.paymenttype, qstudents.ispartpayment, qstudents.financeclosed, qstudents.mealticket, qstudents.approveddate, 
		qstudents.picked, qstudents.pickeddate, qstudents.arrivaldate, qstudents.hallreceipt, qstudents.lrfpicked, qstudents.lrfpickeddate, 
		qstudents.org_id, 
		quarters.active, qresidenceview.residenceid, qresidenceview.residencename, qresidenceview.residencecharge,

		qcharges.fullfees + qresidenceview.full_charges + COALESCE(qmcharges.fullcharge, 0::double precision) + 
		CASE
			WHEN qstudents.offcampus = true THEN 0::double precision
			WHEN qstudents.mealtype::text = 'BLS'::text THEN qcharges.fullmeal3fees + COALESCE(qmcharges.meal3charge * 2, 0::double precision)
			ELSE qcharges.fullmeal2fees + COALESCE(qmcharges.meal2charge * 2, 0::double precision)
			END AS fullfees, 

		qcharges.fees + qresidenceview.charges + COALESCE(qmcharges.charge, 0::double precision) + 
		CASE
			WHEN qstudents.offcampus = true THEN 0::double precision
			WHEN qstudents.mealtype::text = 'BLS'::text THEN qcharges.meal3fees + COALESCE(qmcharges.meal3charge, 0::double precision)
			ELSE qcharges.meal2fees + COALESCE(qmcharges.meal2charge, 0::double precision)
		END AS fees

	FROM vwstudentmajors INNER JOIN (qstudents INNER JOIN quarters ON qstudents.quarterid::text = quarters.quarterid::text) 
			ON vwstudentmajors.studentdegreeid = qstudents.studentdegreeid
		INNER JOIN qresidenceview ON qstudents.qresidenceid = qresidenceview.qresidenceid
		INNER JOIN sublevels ON qstudents.sublevelid = sublevels.sublevelid
		INNER JOIN qcharges ON (qstudents.sublevelid = qcharges.sublevelid)
			AND (qstudents.quarterid::text = qcharges.quarterid::text)
			AND (qstudents.studylevel = qcharges.studylevel)
		LEFT JOIN qmcharges ON (vwstudentmajors.majorid::text = qmcharges.majorid::text)
			AND (qstudents.quarterid::text = qmcharges.quarterid::text)
			AND (qstudents.studylevel = qmcharges.studylevel)
			AND (qstudents.sublevelid = qmcharges.sublevelid);

CREATE VIEW vwscholarships AS
	SELECT students.studentid, students.studentname, students.accountnumber, students.Nationality, students.Sex,
		scholarshiptypes.scholarshiptypeid, scholarshiptypes.scholarshiptypename, scholarshiptypes.scholarshipaccount,
		scholarships.org_id, scholarships.quarterid, scholarships.scholarshipid, scholarships.entrydate, scholarships.paymentdate,
		scholarships.amount, scholarships.approved, scholarships.posted, scholarships.dateposted
	FROM (students INNER JOIN scholarships ON students.studentid = scholarships.studentid)
	INNER JOIN scholarshiptypes ON scholarships.scholarshiptypeid = scholarshiptypes.scholarshiptypeid;

CREATE VIEW smscholarships AS
	SELECT scholarships.org_id, scholarships.studentid, scholarships.quarterid, sum(scholarships.amount) as scholarship
	FROM scholarships
	WHERE (scholarships.approved = true)
	GROUP BY scholarships.org_id, scholarships.studentid, scholarships.quarterid;

CREATE VIEW vwbanks AS
	SELECT bankname, terminalid, accountcode
	FROM banks;

CREATE VIEW vwstudentpayments AS
	SELECT students.studentid, students.studentname, students.accountnumber,
		qstudents.qstudentid, qstudents.quarterid, qstudents.financeclosed, qstudents.org_id, 
		studentpayments.studentpaymentid, studentpayments.applydate, studentpayments.amount, 
		studentpayments.approved, studentpayments.approvedtime,
		studentpayments.narrative, studentpayments.Picked, studentpayments.Pickeddate,
		studentpayments.terminalid, phistory.phistoryid, phistory.phistoryname, 
		students.emailuser || '@std.babcock.edu.ng' as student_email,
		(CASE WHEN studentpayments.approved = false THEN 
		'<a href="payments/paymentClient.jsp?TRANSACTION_ID='|| studentpayments.studentpaymentid
		|| '" target="_blank"><IMG SRC="resources/images/etranzact.jpg" WIDTH=120 HEIGHT=24 ALT=""></a>'
		ELSE 'The payment is completed and updated' END) as makepayment,

		(CASE WHEN studentpayments.approved = false THEN 
		'<a href="payments/paymentVisa.jsp?TRANSACTION_ID='|| studentpayments.studentpaymentid
		|| '" target="_blank"><IMG SRC="resources/images/visa.jpeg" WIDTH=380 HEIGHT=29 ALT=""></a>'
		ELSE 'The payment is completed and updated' END) as visapayment,

		(CASE WHEN studentpayments.approved = false THEN 
		'<a href="payments/query.jsp?TRANSACTION_ID='|| studentpayments.studentpaymentid
		|| '" target="_blank">Query Payment Status</a>'
		ELSE 'Ok' END) as querypayment
	FROM (((students INNER JOIN studentdegrees ON students.studentid = studentdegrees.studentid)
		INNER JOIN qstudents ON studentdegrees.studentdegreeid = qstudents.studentdegreeid)
		INNER JOIN studentpayments ON studentpayments.qstudentid = qstudents.qstudentid)
		INNER JOIN PHistory ON PHistory.PHistoryid = studentpayments.PHistoryid;

CREATE VIEW vw_applicant_payments AS
	SELECT registrations.registrationid, registrations.email, registrations.submitapplication, 
		registrations.isaccepted, registrations.isreported, registrations.isdeferred, registrations.isrejected,
		registrations.applicationdate, 
		registrations.sex, registrations.surname, registrations.firstname, registrations.othernames, 
		(registrations.surname || ', ' ||  registrations.firstname || ' ' || registrations.othernames) as fullname,
		registrations.existingid, registrations.firstchoiceid, registrations.secondchoiceid, registrations.offcampus,
		registrations.org_id, registrations.entry_form_id,
		studentpayments.studentpaymentid, studentpayments.applydate, studentpayments.amount, 
		studentpayments.approved, studentpayments.approvedtime,
		studentpayments.narrative, studentpayments.Picked, studentpayments.Pickeddate,
		studentpayments.terminalid, phistory.phistoryid, phistory.phistoryname, 
		(CASE WHEN studentpayments.approved = false THEN 
		'<a href="paymentClient.jsp?TRANSACTION_ID='|| studentpayments.studentpaymentid
		|| '"><IMG SRC="images/etranzact.jpg" WIDTH=120 HEIGHT=24 ALT=""></a>'
		ELSE 'The payment is completed and updated' END) as makepayment,

		(CASE WHEN studentpayments.approved = false THEN 
		'<a href="query.jsp?TRANSACTION_ID='|| studentpayments.studentpaymentid
		|| '">Query Payment Status</a>'
		ELSE 'Ok' END) as querypayment
	FROM (registrations INNER JOIN studentpayments ON studentpayments.registrationid = registrations.registrationid)
		INNER JOIN PHistory ON PHistory.PHistoryid = studentpayments.PHistoryid;

CREATE VIEW smstudentpayment AS
	SELECT qstudentid, sum(Amount) as studentpayment
	FROM studentpayments
	WHERE (Approved = true)
	GROUP BY qstudentid;

CREATE OR REPLACE VIEW vwbankfile AS 
	SELECT bankfileid, TransactionDate, card_number, amount, response_code,
		replace(description, 'R:', '') as description,
		trim(split_part(description, ';', 2)) as quarterid, 
		trim(split_part(description, ';', 3)) as accountnumber
	FROM bankfile
	WHERE (trim(response_code) = '0');

CREATE VIEW vwqstudentbalances AS 
	SELECT vwqstudentcharges.studentid, vwqstudentcharges.studentname, vwqstudentcharges.nationality, 
		vwqstudentcharges.nationalitycountry, vwqstudentcharges.sex, vwqstudentcharges.maritalstatus, 
		vwqstudentcharges.birthdate, vwqstudentcharges.degreelevelid, vwqstudentcharges.degreelevelname, 
		vwqstudentcharges.sublevelid, vwqstudentcharges.sublevelname, vwqstudentcharges.degreeid, 
		vwqstudentcharges.degreename, vwqstudentcharges.studentdegreeid, vwqstudentcharges.schoolid, 
		vwqstudentcharges.schoolname, vwqstudentcharges.departmentid, vwqstudentcharges.departmentname, 
		vwqstudentcharges.majorid, vwqstudentcharges.majorname, vwqstudentcharges.accountnumber, vwqstudentcharges.qstudentid, 
		vwqstudentcharges.quarterid, vwqstudentcharges.qresidenceid, vwqstudentcharges.charges, vwqstudentcharges.probation, 
		vwqstudentcharges.offcampus, vwqstudentcharges.citizengrade, vwqstudentcharges.citizenmarks, vwqstudentcharges.blockname, 
		vwqstudentcharges.roomnumber, vwqstudentcharges.studylevel, vwqstudentcharges.mealtype, vwqstudentcharges.applicationtime, 
		vwqstudentcharges.finalised, vwqstudentcharges.finaceapproval, vwqstudentcharges.majorapproval, 
		vwqstudentcharges.chaplainapproval, vwqstudentcharges.studentdeanapproval, vwqstudentcharges.overloadapproval, 
		vwqstudentcharges.departapproval, vwqstudentcharges.overloadhours, vwqstudentcharges.intersession, 
		vwqstudentcharges.closed, vwqstudentcharges.printed, vwqstudentcharges.approved, vwqstudentcharges.financenarrative, 
		vwqstudentcharges.noapproval, vwqstudentcharges.premiumhall, vwqstudentcharges.fullfees, vwqstudentcharges.fees, 
		smscholarships.scholarship, smstudentpayment.studentpayment, vwqstudentcharges.financeclosed, vwqstudentcharges.mealticket, 
		vwqstudentcharges.paymenttype, vwqstudentcharges.ispartpayment, vwqstudentcharges.currbalance, 
		vwqstudentcharges.approveddate, vwqstudentcharges.picked, vwqstudentcharges.pickeddate, vwqstudentcharges.arrivaldate, 
		vwqstudentcharges.hallreceipt, vwqstudentcharges.lrfpicked, vwqstudentcharges.lrfpickeddate, vwqstudentcharges.active, 
		vwqstudentcharges.residenceid, vwqstudentcharges.residencename, vwqstudentcharges.residencecharge, 
		vwqstudentcharges.org_id,

		(COALESCE(smscholarships.scholarship, 0::real) + COALESCE(smstudentpayment.studentpayment, 0::real) - 
		(COALESCE(vwqstudentcharges.currbalance, 0::real) + vwqstudentcharges.fullfees + vwqstudentcharges.charges)) AS fullfinalbalance, 

		(COALESCE(smscholarships.scholarship, 0::real) + COALESCE(smstudentpayment.studentpayment, 0::real) - 
		(COALESCE(vwqstudentcharges.currbalance, 0::real) + vwqstudentcharges.fees + vwqstudentcharges.charges)) AS finalbalance, 

		(COALESCE(vwqstudentcharges.currbalance, 0::real) + vwqstudentcharges.charges + 
        (CASE WHEN vwqstudentcharges.paymenttype = 1 THEN vwqstudentcharges.fullfees ELSE vwqstudentcharges.fees END) - 
		(COALESCE(smscholarships.scholarship, 0::real) + COALESCE(smstudentpayment.studentpayment, 0::real))) AS paymentamount
	FROM vwqstudentcharges
		LEFT JOIN smstudentpayment ON vwqstudentcharges.qstudentid = smstudentpayment.qstudentid
		LEFT JOIN smscholarships ON vwqstudentcharges.studentid::text = smscholarships.studentid::text AND vwqstudentcharges.quarterid::text = smscholarships.quarterid::text;

CREATE VIEW vwcitizenships AS
	SELECT studentdegreeview.studentid, studentdegreeview.studentname, studentdegreeview.sex,
		studentdegreeview.MaritalStatus, studentdegreeview.birthdate, qstudents.qstudentid, qstudents.quarterid,
		qstudents.org_id,
		citizenships.citizenshipid, citizenships.entrydate, citizenships.narrative,
		citizenshiptypes.citizenshiptypeid, citizenshiptypes.citizenshiptypename, citizenshiptypes.demerits
	FROM ((studentdegreeview INNER JOIN qstudents ON studentdegreeview.studentdegreeid = qstudents.studentdegreeid)
		INNER JOIN citizenships ON qstudents.qstudentid = citizenships.qstudentid)
		INNER JOIN citizenshiptypes ON citizenships.citizenshiptypeid = citizenshiptypes.citizenshiptypeid;

CREATE VIEW vwstudentexits AS
	SELECT studentdegreeview.studentid, studentdegreeview.studentname, studentdegreeview.sex,
		studentdegreeview.MaritalStatus, studentdegreeview.birthdate, qstudents.qstudentid, qstudents.quarterid,
		qstudents.org_id,
		studentexits.studentexitid, studentexits.exitdate, studentexits.entrydate,
		studentexits.requestexit, studentexits.requestentry, studentexits.reason,
		studentexits.longexit, studentexits.approved
	FROM (studentdegreeview INNER JOIN qstudents ON studentdegreeview.studentdegreeid = qstudents.studentdegreeid)
		INNER JOIN studentexits ON studentexits.qstudentid = qstudents.qstudentid;

CREATE VIEW vwinstructors AS
	SELECT departments.departmentid, departments.departmentname, instructors.instructorid,
		instructors.instructorname, instructors.majoradvisor, instructors.headofdepartment,
		instructors.firstpasswd, instructors.email,
		(CASE WHEN (instructors.majoradvisor = true) AND (instructors.headofdepartment = true) THEN 'HODMA'
		WHEN (instructors.majoradvisor = false) AND (instructors.headofdepartment = true) THEN 'HOD'
		WHEN (instructors.majoradvisor = true) AND (instructors.headofdepartment = false) THEN 'MA'
		ELSE 'NONE' END) as rolename
	FROM departments INNER JOIN instructors ON departments.departmentid = instructors.departmentid;
	
CREATE VIEW vw_instructor_entitys AS
	SELECT departments.departmentid, departments.departmentname, instructors.org_id,
		instructors.instructorid, instructors.instructorname, instructors.majoradvisor, 
		instructors.headofdepartment, instructors.email,
		entitys.entity_id, entitys.user_name, entitys.function_role, entitys.first_password, entitys.is_active
	FROM departments INNER JOIN instructors ON departments.departmentid = instructors.departmentid
		INNER JOIN entitys ON instructors.instructorid = entitys.user_name;

CREATE VIEW vwqchargedefinations AS
	SELECT chargetypes.chargetypeid, chargetypes.chargetypename, chargetypes.accountnumber, chargetypes.accountcode,
		sublevels.sublevelid, sublevels.sublevelname,
		qchargedefinations.org_id, qchargedefinations.qchargedefinationid,
		qchargedefinations.studylevel, qchargedefinations.amount, qchargedefinations.narrative, quarters.quarterid,
		(CASE WHEN (chargetypes.offcampus = true) THEN qchargedefinations.amount ELSE 0 END) as nonresident,
		(CASE WHEN (chargetypes.oncampus = true) THEN qchargedefinations.amount ELSE 0 END) as regural,
		(CASE WHEN (chargetypes.chargetypeid = 2) THEN quarters.mealcharge ELSE 0 END) as addmeal,
		(CASE WHEN (chargetypes.chargetypeid = 3) THEN quarters.premialhall ELSE 0 END) as premialhall
	FROM (chargetypes INNER JOIN qchargedefinations ON chargetypes.chargetypeid = qchargedefinations.chargetypeid)
		INNER JOIN quarters ON qchargedefinations.quarterid = quarters.quarterid
		INNER JOIN sublevels ON qchargedefinations.sublevelid = sublevels.sublevelid;

CREATE VIEW vwqmchargedefinations AS
	SELECT chargetypes.chargetypeid, chargetypes.chargetypename, chargetypes.accountnumber, chargetypes.accountcode,
		chargetypes.oncampus, chargetypes.offcampus, majors.majorid, majors.majorname, 
		sublevels.sublevelid, sublevels.sublevelname,
		qmchargedefinations.qmchargedefinationid, qmchargedefinations.quarterid,
		qmchargedefinations.studylevel, qmchargedefinations.amount, qmchargedefinations.narrative
	FROM (chargetypes INNER JOIN qmchargedefinations ON chargetypes.chargetypeid = qmchargedefinations.chargetypeid)
		INNER JOIN majors ON qmchargedefinations.majorid = majors.majorid
		INNER JOIN sublevels ON qmchargedefinations.sublevelid = sublevels.sublevelid;

CREATE VIEW vwqmajorchargelists AS
	(SELECT majors.majorid, majors.majorname, 
		vwqchargedefinations.chargetypeid, vwqchargedefinations.chargetypename,
		vwqchargedefinations.sublevelid, vwqchargedefinations.sublevelname,
		vwqchargedefinations.accountnumber, vwqchargedefinations.accountcode,
		vwqchargedefinations.qchargedefinationid, vwqchargedefinations.quarterid,
		vwqchargedefinations.studylevel,  vwqchargedefinations.narrative,
		vwqchargedefinations.nonresident, vwqchargedefinations.regural, 
		(vwqchargedefinations.regural + vwqchargedefinations.addmeal) as threemeals,
		(vwqchargedefinations.regural + vwqchargedefinations.premialhall) as premialhall,
		(vwqchargedefinations.regural + vwqchargedefinations.premialhall + vwqchargedefinations.addmeal) as premialhallthree
	FROM (majors CROSS JOIN vwqchargedefinations)
	WHERE (majors.org_id = vwqchargedefinations.org_id))
	UNION
	(SELECT vwqmchargedefinations.majorid, vwqmchargedefinations.majorname,
		vwqmchargedefinations.chargetypeid, vwqmchargedefinations.chargetypename, 
		vwqmchargedefinations.sublevelid, vwqmchargedefinations.sublevelname,
		vwqmchargedefinations.accountnumber, vwqmchargedefinations.accountcode, 
		vwqmchargedefinations.qmchargedefinationid, vwqmchargedefinations.quarterid, 
		vwqmchargedefinations.studylevel, vwqmchargedefinations.narrative,
		vwqmchargedefinations.amount, vwqmchargedefinations.amount, vwqmchargedefinations.amount,
		vwqmchargedefinations.amount, vwqmchargedefinations.amount
	FROM vwqmchargedefinations);

CREATE VIEW vwqmajorchargesummary AS
	SELECT vwqmajorchargelists.quarterid, vwqmajorchargelists.majorid, vwqmajorchargelists.majorname, 
		vwqmajorchargelists.accountnumber, vwqmajorchargelists.accountcode, 
		vwqmajorchargelists.chargetypeid, vwqmajorchargelists.chargetypename, 
		vwqmajorchargelists.sublevelid, vwqmajorchargelists.sublevelname, vwqmajorchargelists.studylevel, 
		sum(vwqmajorchargelists.nonresident) as nonresident, sum(vwqmajorchargelists.regural) as regural, 
		sum(vwqmajorchargelists.threemeals) as threemeals, 
		sum(vwqmajorchargelists.premialhall) as premialhall, 
		sum(vwqmajorchargelists.premialhallthree) as premialhallthree
	FROM vwqmajorchargelists
	GROUP BY vwqmajorchargelists.quarterid, vwqmajorchargelists.majorid, vwqmajorchargelists.majorname, 
		vwqmajorchargelists.accountnumber, vwqmajorchargelists.accountcode, 
		vwqmajorchargelists.chargetypeid, vwqmajorchargelists.chargetypename, 
		vwqmajorchargelists.sublevelid, vwqmajorchargelists.sublevelname, vwqmajorchargelists.studylevel;

CREATE VIEW vwsuncharges AS 
	SELECT vwqmajorchargesummary.accountnumber AS chargeaccount, vwqmajorchargesummary.accountcode, 
		vwqmajorchargesummary.chargetypeid, vwqmajorchargesummary.chargetypename, 
		vwqmajorchargesummary.quarterid, vwqmajorchargesummary.studylevel, 
		vwqmajorchargesummary.majorid, vwqmajorchargesummary.majorname, 
		vwqmajorchargesummary.sublevelid, vwqmajorchargesummary.sublevelname,
        CASE WHEN vwqstudentbalances.offcampus = true THEN vwqmajorchargesummary.nonresident
            WHEN vwqstudentbalances.mealtype::text = 'BLS'::text THEN vwqmajorchargesummary.threemeals
            ELSE vwqmajorchargesummary.regural END AS unitfees, 
		vwqstudentbalances.accountnumber, vwqstudentbalances.studentname, vwqstudentbalances.fees, 
		vwqstudentbalances.residencecharge, vwqstudentbalances.picked, vwqstudentbalances.qstudentid,
		vwqstudentbalances.mealtype
	FROM vwqmajorchargesummary JOIN vwqstudentbalances ON 
		(vwqmajorchargesummary.majorid = vwqstudentbalances.majorid) AND
		(vwqmajorchargesummary.sublevelid = vwqstudentbalances.sublevelid) AND 
		(vwqmajorchargesummary.studylevel = vwqstudentbalances.studylevel) AND 
		(vwqmajorchargesummary.quarterid = vwqstudentbalances.quarterid)
	WHERE (vwqstudentbalances.finaceapproval = true)
	ORDER BY vwqstudentbalances.accountnumber;

CREATE VIEW vwBankrecons AS
	SELECT 	trunc(cast(creditvalue as real)) as bankamount, count(BankreconID) as bankcountamount,
		sum(cast(creditvalue as real)) as banksumamount
	FROM Bankrecons
	WHERE (TransactionDetails like '00000%') and trim(debitvalue) = '0.0'
	GROUP BY trunc(cast(creditvalue as real))
	ORDER BY count(BankreconID);

CREATE VIEW vwEtranzactRecons AS
	SELECT 	trunc(TransactionAmount) as amount, count(banksuspenceid) as countamount, sum(TransactionAmount) as sumamount
	FROM banksuspence
	GROUP BY trunc(TransactionAmount)
	ORDER BY count(banksuspenceid);

CREATE VIEW vwlevel AS
	SELECT studylevel
	FROM qstudents
	GROUP BY studylevel;

CREATE VIEW vwchecklist AS
	SELECT studentdegrees.studentdegreeid, studentdegrees.studentid, studentdegrees.degreeid, 
		majorcontentview.departmentid, majorcontentview.departmentname, 
		majorcontentview.majorid, majorcontentview.majorname, majorcontentview.courseid,
		majorcontentview.coursetitle, majorcontentview.minor, majorcontentview.elective,
		majorcontentview.yeartaken, majorcontentview.quarterdone, 
		majorcontentview.credithours, majorcontentview.nogpa, majorcontentview.gradeid, grades.gradeweight
	FROM (((majorcontentview INNER JOIN studentmajors ON majorcontentview.majorid = studentmajors.majorid)
		INNER JOIN studentdegrees ON (studentmajors.studentdegreeid = studentdegrees.studentdegreeid)
			AND (majorcontentview.bulletingid = studentdegrees.bulletingid))
		INNER JOIN grades ON majorcontentview.gradeid = grades.gradeid);

CREATE VIEW vwqgrades AS
	SELECT qgrades.qgradeid, qgrades.hours, qgrades.credit, 
		qgrades.instructormarks, qgrades.departmentmarks, qgrades.finalmarks,
		qcourses.courseid, qstudents.qstudentid, qstudents.studentdegreeid, qstudents.quarterid, 
		grades.gradeid, grades.gradeweight
	FROM ((qgrades INNER JOIN qcourses ON qgrades.qcourseid = qcourses.qcourseid)
		INNER JOIN qstudents ON qgrades.qstudentid = qstudents.qstudentid)
		INNER JOIN grades ON qgrades.gradeid = grades.gradeid
	WHERE (qgrades.dropped = false) AND (qgrades.repeated = false) AND (qgrades.gradeid <> 'NG');

CREATE VIEW vw_moodle_users AS
	SELECT entitys.entity_id, entitys.entity_name, entitys.user_name, 
		entitys.primary_email, entitys.entity_password,
		departments.departmentid, departments.departmentname,
		students.firstname, students.surname,
		students.town, students.address, students.telno, students.mobile,
		countrys.countryname
	FROM entitys INNER JOIN students ON entitys.user_name = students.studentid
		INNER JOIN departments ON students.departmentid = departments.departmentid
		INNER JOIN countrys ON students.countrycodeid = countrys.countryid
	WHERE (students.alumnae = false);
	
CREATE OR REPLACE VIEW vw_gradechangelist AS 
 SELECT gradechangelist.gradechangeid, gradechangelist.qgradeid, gradechangelist.org_id,
    gradechangelist.changedby, gradechangelist.oldgrade, gradechangelist.newgrade,
    gradechangelist.changedate, gradechangelist.clientip, gradechangelist.entity_id,
    COALESCE(gradechangelist.changedby, entitys.entity_name) AS changed_by
   FROM gradechangelist
     LEFT JOIN entitys ON gradechangelist.entity_id = entitys.entity_id;


--- get the student id eliminated
CREATE VIEW vwduplicatestudents AS
	SELECT studentname, studentid, length(studentid) as idlength,
	(CASE WHEN (substring(studentid from 4 for 1) = '0') AND (length(studentid) = 8) THEN 
	substring(studentid from 1 for 3) || substring(studentid from 5 for 4) ELSE studentid END) as newstudentid
	FROM students 
	WHERE studentname IN (SELECT studentname
	FROM students
	GROUP BY studentname
	HAVING count(studentid) > 1)
	ORDER BY studentname;

CREATE VIEW ws_students AS
	SELECT students.studentid, students.departmentid, students.denominationid, students.org_id,
		students.studentname, students.surname, students.firstname, students.othernames, students.sex,
		students.Nationality, students.MaritalStatus, students.birthdate, students.address,
		students.zipcode, students.town, students.countrycodeid, students.stateid,
		students.telno, students.mobile, students.email,
		entitys.entity_id, entitys.entity_password
	FROM students INNER JOIN entitys ON students.studentid = entitys.user_name;

CREATE VIEW ws_student_grades AS
	SELECT quarterid, studentid, studyLevel, credit, gpa, cummcredit, cummgpa, qstudentid
	FROM qstudentsummary;

CREATE VIEW ws_student_timetable AS
	SELECT studentid, starttime, endtime, cmonday, ctuesday, cwednesday, cthursday, cfriday, csunday, lab, courseid, 
		coursetitle, instructorname, classoption, assetname, location, building
	FROM studenttimetableview;
	
	
CREATE VIEW vw_active_studentid AS
	SELECT studentdegrees.studentid
	FROM studentdegrees INNER JOIN qstudents ON studentdegrees.studentdegreeid = qstudents.studentdegreeid
		INNER JOIN quarters ON qstudents.quarterid = quarters.quarterid
	WHERE (quarters.active = true) AND (qstudents.approved = true)
	GROUP BY studentdegrees.studentid;
GRANT ALL ON radcheck TO radius;

CREATE OR REPLACE VIEW radcheck (id, username, attribute, op, value) AS
	SELECT entity_id, user_name, 'MD5-Password'::character(12), ':='::character(2), entity_password
	FROM entitys INNER JOIN vw_active_studentid ON entitys.user_name = vw_active_studentid.studentid
	WHERE (entity_type_id = 21) AND (is_active = true);
GRANT ALL ON radcheck TO radius;


CREATE VIEW ws_food_service AS
	SELECT studentid, studentname, mealtype, studylevel, majorid, majorname
	FROM vwqstudentbalances
	WHERE (active = true) AND (finaceapproval = true);

CREATE VIEW ws_hall_service AS
	SELECT studentid, studentname, mealtype, studylevel, majorid, majorname, finaceapproval,
		quarterid, schoolid, schoolname, departmentid, departmentname, residenceid, residencename
	FROM vwqstudentbalances
	WHERE (active = true);
	
CREATE VIEW ws_qstudents AS
	SELECT studentid, studentname, sex, mealtype, studylevel, majorid, majorname, 
		quarterid, schoolid, schoolname, departmentid, departmentname, residenceid, residencename,
		qstudentid, finaceapproval, approved
	FROM vwqstudentbalances;
	
----------- Creating radius server interface
CREATE EXTENSION postgres_fdw;
CREATE SERVER umisdb1 FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host '192.168.1.111', dbname 'babcock', port '5432');
CREATE USER MAPPING FOR radius SERVER umisdb1 OPTIONS (user 'radius', password 'inventRadius');

DROP TABLE radcheck;
CREATE FOREIGN TABLE radcheck (
 id      integer, 
 UserName    varchar(64),
 Attribute    varchar(12),
 op      char(2),
 Value     varchar(253)
)
SERVER umisdb1 OPTIONS(table_name 'radcheck');
GRANT ALL ON radcheck TO radius;


GRANT ALL ON nas TO radius;
GRANT ALL ON radpostauth TO radius;
GRANT ALL ON radpostauth_id_seq TO radius;


