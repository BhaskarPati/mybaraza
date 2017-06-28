CREATE TABLE religions (
	religionid			varchar(12) primary key,
	religionname		varchar(50),
	details				text
);

CREATE TABLE denominations (
	denominationid		varchar(12) primary key,
	religionid			varchar(12) references religions,
	denominationname	varchar(50) not null unique,
	details				text
);
CREATE INDEX denominations_religionid ON denominations (religionid);

CREATE TABLE schools (
	schoolid			varchar(12) primary key,
	schoolname			varchar(50) not null,
	philosopy			text,
	vision				text,
	mission				text,
	objectives			text,
	details				text
);

CREATE TABLE departments (
	departmentid		varchar(12) primary key,
	schoolid			varchar(12) references schools,
	departmentname		varchar(120) not null unique,
	philosopy			text,
	vision				text,
	mission				text,
	objectives			text,
	oppotunities		text,
	details				text
);
CREATE INDEX departments_schoolid ON departments (schoolid);

CREATE TABLE grades (
	gradeid				varchar(2) primary key,
	gradeweight			float default 0 not null,
	minrange			integer,
	maxrange			integer,
	gpacount			boolean default true not null,
	narrative			varchar(240),
	details				text
);

CREATE TABLE degreelevels (
	degreelevelid		varchar(12) primary key,
	degreelevelname		varchar(50) not null unique,
	details				text
);

CREATE TABLE degrees (
	degreeid			varchar(12) primary key,
	degreelevelid		varchar(12) references degreelevels,
	degreename			varchar(50) not null unique,
	details				text
);

CREATE TABLE residences (
	residenceid			varchar(12) primary key,
	residencename		varchar(50) not null unique,
	defaultrate			float default 0 not null,
	offcampus			boolean not null default false,
	roomsize			integer default 2 not null,
	capacity			integer default 20 not null,
	Sex					varchar(1),
	residencedean		varchar(50),
	details				text
);

CREATE TABLE assets (
	assetid				serial primary key,
	assetname			varchar(50) not null unique,
	building			varchar(50),
	location			varchar(50),
	capacity			integer not null,
	details				text
);

CREATE TABLE instructors (
	instructorid		varchar(12) primary key,
	departmentid		varchar(12) references departments,
	instructorname		varchar(50) not null unique,
	majoradvisor		boolean default false not null,
	headofdepartment	boolean default false not null,
	headoffaculty		boolean default false not null,
	userpasswd			varchar(32) not null default md5('enter'),
	firstpasswd			varchar(32) not null default firstPasswd(),
	email				varchar(240),
	telephone			varchar(240),
	photo_file			varchar(120),
	details				text
);
CREATE INDEX instructors_departmentid ON instructors (departmentid);

CREATE TABLE coursetypes (
	coursetypeid		serial primary key,
	coursetypename		varchar(50),
	details				text
);

CREATE TABLE coursemodes (
	coursemodeid		serial primary key,
	coursemodename		varchar(50),
	details				text
);

CREATE TABLE courses (
	courseid			varchar(12) primary key,
	departmentid		varchar(12) references departments,
	degreelevelid		varchar(12) references degreelevels,
	coursetypeid		integer references coursetypes,
	coursemodeid		integer references coursemodes,
	coursetitle			varchar(120) not null,
	credithours			float not null,
	mincredit			float not null default 0,
	maxcredit			float not null default 0,
	lecturehours		float not null default 0,
	practicalhours		float not null default 0,
	labcourse			boolean not null default false,
	iscurrent			boolean not null default true,
	nogpa				boolean not null default false,
	norepeats			boolean not null default false,
	yeartaken			integer not null default 1,
	details				text
);
CREATE INDEX courses_departmentid ON courses (departmentid);
CREATE INDEX courses_degreelevelid ON courses (degreelevelid);
CREATE INDEX courses_coursetypeid ON courses (coursetypeid);
CREATE INDEX courses_coursemodeid ON courses (coursemodeid);

CREATE TABLE bulleting (
	bulletingid			serial primary key,
 	bulletingname		varchar(50),
	starting			date,
	ending				date,
	active				boolean not null default false,
	details				text
);

CREATE TABLE prerequisites (
	prerequisiteid		serial primary key,
	courseid			varchar(12) references courses,
	precourseid			varchar(12) references courses,
	gradeid				varchar(2) references grades,
	bulletingid			integer references bulleting,
	optionlevel			integer not null default 1,
	narrative			varchar(120)
);
CREATE INDEX prerequisites_courseid ON prerequisites (courseid);
CREATE INDEX prerequisites_precourseid ON prerequisites (precourseid);
CREATE INDEX prerequisites_gradeid ON prerequisites (gradeid);
CREATE INDEX prerequisites_bulletingid ON prerequisites (bulletingid);

CREATE TABLE majors (
	majorid				varchar(12) primary key,
	departmentid		varchar(12) references departments,
	majorname			varchar(75) not null unique,
	major				boolean default false not null,
	minor				boolean default false not null,
	fullcredit			integer default 200 not null,
	coreminimum			integer not null,
	electivecredit		integer not null,
	details				text
);
CREATE INDEX majors_departmentid ON majors (departmentid);

CREATE TABLE contenttypes (
	contenttypeid		serial primary key,
	contenttypename		varchar(50) not null,
	elective			boolean default false not null,
	prerequisite		boolean default false not null,
	premajor			boolean default false not null,
	details				text
);

CREATE TABLE majorcontents (
	majorcontentid		serial primary key,
	majorid				varchar(12) references majors,
	courseid			varchar(12) references courses,
	contenttypeid		integer references contenttypes,
	gradeid				varchar(2) references grades,
	bulletingid			integer references bulleting,
	minor				boolean not null default false,
	narrative			varchar(240),
	UNIQUE (majorid, courseid, contenttypeid, bulletingid, minor)
);
CREATE INDEX majorcontents_majorid ON majorcontents (majorid);
CREATE INDEX majorcontents_courseid ON majorcontents (courseid);
CREATE INDEX majorcontents_contenttypeid ON majorcontents (contenttypeid);
CREATE INDEX majorcontents_gradeid ON majorcontents (gradeid);
CREATE INDEX majorcontents_bulletingid ON majorcontents (bulletingid);

CREATE TABLE sponsortypes (
	sponsortypeid		serial primary key,
	sponsortypename		varchar(50),
	details				text
);

CREATE TABLE sponsors (
	sponsorid			serial primary key,
	sponsortypeid		integer references sponsortypes,
	sponsorname			varchar(50),
	address				varchar(50),
	street				varchar(50),
	postalcode			varchar(50),
	town				varchar(50),
	countryid			char(2) references countrys,
	telno				varchar(50),
	email				varchar(240),
	firstpasswd			varchar(32) not null default firstPasswd(),
	userpasswd			varchar(32) not null default md5('enter'),
	active				boolean default true not null,
	details				text
);
CREATE INDEX sponsors_countryid ON sponsors (countryid);

CREATE TABLE centers (
	center_id			varchar(12) primary key,
	center_name			varchar(120),
	details				text
);

CREATE TABLE students (
	studentid			varchar(12) primary key,
	departmentid		varchar(12) references departments,
	denominationid		varchar(12) references denominations,
	sponsorid			integer references sponsors,
	studentname			varchar(50) not null,
	surname				varchar(50) not null,
	firstname			varchar(50) not null,
	othernames			varchar(50),
	Sex					varchar(1),
	Nationality			char(2) references countrys,
	MaritalStatus		varchar(2),
	birthdate			date,
	address				varchar(240),
	zipcode				varchar(50),
	town				varchar(50),
	countrycodeid		char(2) references countrys,
	telno				varchar(50),
	mobile				varchar(50),
	email				varchar(240),
	accountnumber		varchar(16),
	adminision_basis	varchar(240),
	firstpasswd			varchar(32) not null default firstPasswd(),
	userpasswd			varchar(32) not null default md5('enter'),
	alumnae				boolean not null default false,
	onprobation			boolean not null default false,
	offcampus			boolean default false not null,
	onhold				boolean not null default false,
	currentbalance		real,
	picturefile			varchar(240),
	currentcontact		text,
	details				text
);
CREATE INDEX students_departmentid ON students (departmentid);
CREATE INDEX students_denominationid ON students (denominationid);
CREATE INDEX students_sponsorid ON students (sponsorid);
CREATE INDEX students_Nationality ON students (Nationality);
CREATE INDEX students_countrycodeid ON students (countrycodeid);
CREATE INDEX students_accountnumber ON students (accountnumber);

CREATE TABLE studentdegrees (
	studentdegreeid		serial primary key,
	degreeid			varchar(12) references degrees,
	studentid			varchar(12) references students,
	bulletingid			integer references bulleting,
	center_id			varchar(12) references centers,
	completed			boolean not null default false,
	started				date,
	cleared				boolean not null default false,
	clearedate			date,
	graduated			boolean not null default false,
	graduatedate		date,
	dropout				boolean not null default false,
	transferin			boolean not null default false,
	transferout			boolean not null default false,
	admission_basis		varchar(240),
	details				text,
	unique (degreeid, studentid)
);
CREATE INDEX studentdegrees_degreeid ON studentdegrees (degreeid);
CREATE INDEX studentdegrees_studentid ON studentdegrees (studentid);
CREATE INDEX studentdegrees_bulletingid ON studentdegrees (bulletingid);
CREATE INDEX studentdegrees_center_id ON studentdegrees (center_id);

CREATE TABLE transcriptprint (
	transcriptprintid	serial primary key,
	studentdegreeid		integer references studentdegrees,
	UserID				integer references Users default getUserID(),
	printdate			timestamp default now(),
	narrative			varchar(240)
);
CREATE INDEX transcriptprint_studentdegreeid ON transcriptprint (studentdegreeid);	
CREATE INDEX transcriptprint_UserID ON transcriptprint (UserID);

CREATE TABLE studentmajors ( 
	studentmajorid		serial primary key,
	studentdegreeid		integer references studentdegrees,
	majorid				varchar(12) references majors,
	major				boolean not null default false,
	primarymajor		boolean not null default false,
	nondegree			boolean not null default false,
	Details				text,
	UNIQUE(studentdegreeid)
);
CREATE INDEX studentmajors_studentdegreeid ON studentmajors (studentdegreeid);
CREATE INDEX studentmajors_majorid ON studentmajors (majorid);

CREATE TABLE transferedcredits (
	transferedcreditid		serial primary key,
	studentdegreeid			integer references studentdegrees,
	courseid				varchar(12) references courses,
	credithours				float default 0 not null,
	narrative				varchar(240),
	UNIQUE (studentdegreeid, courseid)
);
CREATE INDEX transferedcredits_studentdegreeid ON transferedcredits (studentdegreeid);
CREATE INDEX transferedcredits_courseid ON transferedcredits (courseid);

CREATE TABLE requesttypes (
	requesttypeid		serial primary key,
	requesttypename		varchar(50) not null unique,
	toapprove			boolean not null default false,
	details 			text
);

CREATE TABLE studentrequests (
	studentrequestid	serial primary key,
	studentid			varchar(12) references students,
	requesttypeid		integer references requesttypes,
	narrative			varchar(240) not null,
	datesent			timestamp not null default now(),
	actioned			boolean not null default false,
	dateactioned		timestamp,
	approved			boolean not null default false,
	dateapploved		timestamp,
	details				text,
	reply				text
);
CREATE INDEX studentrequests_studentid ON studentrequests (studentid);
CREATE INDEX studentrequests_requesttypeid ON studentrequests (requesttypeid);

CREATE TABLE sessions (
	sessionid			varchar(12) primary key,
	sessionyear			varchar(9) not null,
	semester			integer not null,
	center				varchar(50),
	sstart				date not null,
	slatereg			date not null default current_date,
	slatechange			date not null default current_date,
	slastdrop			date not null,
	send				date not null,
	active				boolean default false not null,
	mincredits			real not null default 16,
	maxcredits			real not null default 21,
	details				text
);
CREATE INDEX sessions_active ON sessions (active);

CREATE TABLE scalendar (
	scalendarid			serial primary key,
	sessionid			varchar(12) references sessions,
	sdate				date not null,
	senddate			date not null,
	event				varchar(120),
	details				text
);
CREATE INDEX scalendar_sessionid ON scalendar (sessionid);

CREATE TABLE sresidences (
	sresidenceid		serial primary key,
	sessionid			varchar(12) references sessions,
	residenceid			varchar(12) references residences,
	residenceoption		varchar(50) not null default 'Full',
	charges				float not null,
	active				boolean not null default true,
	details				text,
	UNIQUE (sessionid, residenceid, residenceoption)
);
CREATE INDEX sresidences_sessionid ON sresidences (sessionid);
CREATE INDEX sresidences_residenceid ON sresidences (residenceid);

CREATE TABLE scharges (
	schargeid			serial primary key,
	sessionid			varchar(12) references sessions,
	degreelevelid		varchar(12) references degreelevels,
	fees				float not null default 263864,
	narrative			varchar(120),
	details				text,
	UNIQUE (sessionid, degreelevelid)
);
CREATE INDEX scharges_sessionid ON scharges (sessionid);
CREATE INDEX scharges_degreelevelid ON scharges (degreelevelid);

CREATE TABLE sstudents (
	sstudentid			serial primary key,
	sessionid			varchar(12) references sessions,
	studentdegreeid		integer references studentdegrees,
	sresidenceid		integer references sresidences,
	extacharges			float default 0 not null,
	probation			boolean default false not null,
	offcampus			boolean default false not null,
	blockname			varchar(12),
	roomnumber			integer,
	currbalance			real,
	studylevel			integer,
	applicationtime		timestamp not null default now(),
	firstclosetime		timestamp,
	finalised			boolean default false not null,
	clearedfinance		boolean default false not null,
	finaceapproval		boolean default false not null,
	majorapproval		boolean default false not null,
	departapproval		boolean default false not null,
	chaplainapproval	boolean default false not null,
	studentdeanapproval	boolean default false not null,
	overloadapproval	boolean default false not null,
	overloadhours		float,
	financeclosed		boolean default false not null,
	closed				boolean default false not null,
	printed				boolean default false not null,
	approved			boolean default false not null,
	ApprovedDate		timestamp,
	onprobation			boolean default false not null,
	Picked				boolean default false not null,
	Pickeddate			timestamp,
	LRFPicked			boolean default false not null,
	LRFPickeddate		timestamp,
	financenarrative	text,
	noapproval			text,
	details				text,
	UNIQUE(sessionid, studentdegreeid)
);
CREATE INDEX sstudents_sessionid ON sstudents (sessionid);
CREATE INDEX sstudents_studentdegreeid ON sstudents (studentdegreeid);
CREATE INDEX sstudents_sresidenceid ON sstudents (sresidenceid);
CREATE INDEX sstudents_roomnumber ON sstudents (roomnumber);
CREATE INDEX sstudents_studylevel ON sstudents (studylevel);

CREATE TABLE phistory (
	PHistoryID			integer primary key,
	PHistoryName		varchar(120) not null unique
);

CREATE TABLE studentpayments (
	studentpaymentid	serial primary key,
	sstudentid			integer references sstudents,
	phistoryid			integer default -100,
	applydate			timestamp not null default now(),
	amount				real not null,
	approved			boolean not null default false,
	approvedtime		timestamp,
	Picked				boolean default false not null,
	Pickeddate			timestamp,
	terminalid			varchar(12),
	narrative			varchar(240)
);	
CREATE INDEX studentpayments_sstudentid ON studentpayments (sstudentid);
CREATE INDEX studentpayments_PHistoryID ON studentpayments (PHistoryID);

CREATE TABLE scholarshiptypes (
	scholarshiptypeid	serial primary key,
	scholarshiptypename	varchar(50) not null unique,
	scholarshipaccount	varchar(12),
	details				text
);

CREATE TABLE scholarships (
	scholarshipid		serial primary key,
	scholarshiptypeid	integer references scholarshiptypes,
	studentid			varchar(12) references students,
	sessionid			varchar(12) references sessions,
	entrydate			date not null default current_date,
	paymentdate			date not null,
	amount				real not null,
	approved			boolean not null default false,
	Approveddate		timestamp,
	posted				boolean not null default false,
	dateposted			timestamp,
	details				text
);
CREATE INDEX scholarships_scholarshiptypeid ON scholarships (scholarshiptypeid);
CREATE INDEX scholarships_studentid ON scholarships (studentid);
CREATE INDEX scholarships_sessionid ON scholarships (sessionid);

CREATE TABLE approvallist (
	approvalid			serial primary key,
	sstudentid			integer references sstudents,
	approvedby			varchar(50),
	approvaltype		varchar(25),
	approvedate			timestamp default now(),
	clientip			varchar(25)
);
CREATE INDEX approvallist_sstudentid ON approvallist (sstudentid);

CREATE TABLE scourses (
	scourseid			serial primary key,
	sessionid			varchar(12) references sessions,
	instructorid		varchar(12) references instructors,
	courseid			varchar(12) references courses,
	center_id			varchar(12) references centers,
	coursetitle			varchar(120),
	classoption			varchar(50) default 'Main' not null,
	maxclass			integer not null,
	coursecharge		float default 0 not null,
	approved			boolean default false not null,
	lecturesubmit		boolean default false not null,
	lsdate				timestamp default now(),
	departmentsubmit	boolean default false not null,
	dsdate				timestamp default now(),
	facultysubmit		boolean default false not null,
	fsdate				timestamp default now(),
	attendance			integer,
	fullattendance		integer,
	details				text,
	UNIQUE (instructorid, courseid, sessionid, classoption)
);
CREATE INDEX scourses_sessionid ON scourses (sessionid);
CREATE INDEX scourses_instructorid ON scourses (instructorid);
CREATE INDEX scourses_courseid ON scourses (courseid);
CREATE INDEX scourses_center_id ON scourses (center_id);

CREATE TABLE optiontimes (
	optiontimeid		serial primary key,
	optiontimename		varchar(50),
	details				text
);
INSERT INTO optiontimes (optiontimeid, optiontimename) VALUES (0, 'Main');

CREATE TABLE stimetable (
	stimetableid		serial primary key,
	assetid				integer references assets,
	scourseid			integer references scourses,
	optiontimeid		integer references optiontimes default 0,
	cmonday				boolean not null default false,
	ctuesday			boolean not null default false,
	cwednesday			boolean not null default false,
	cthursday			boolean not null default false,
	cfriday				boolean not null default false,
	csaturday			boolean not null default false,
	csunday				boolean not null default false,
	starttime			time not null,
	endtime				time not null,
	lab					boolean not null default false,
	details				text
);
CREATE INDEX stimetable_assetid ON stimetable (assetid);
CREATE INDEX stimetable_scourseid ON stimetable (scourseid);
CREATE INDEX stimetable_optiontimeid ON stimetable (optiontimeid);

CREATE TABLE sexamtimetable (
	sexamtimetableid	serial primary key,
	assetid				integer references assets,
	scourseid			integer references scourses,
	optiontimeid		integer references optiontimes default 0,
	examdate			date,
	starttime			time not null,
	endtime				time not null,
	lab					boolean not null default false,
	details				text
);
CREATE INDEX sexamtimetable_assetid ON sexamtimetable (assetid);
CREATE INDEX sexamtimetable_scourseid ON sexamtimetable (scourseid);
CREATE INDEX sexamtimetable_optiontimeid ON sexamtimetable (optiontimeid);

CREATE TABLE sgrades (
	sgradeid 			serial primary key,
	sstudentid			integer references sstudents,
	scourseid			integer references scourses,
	gradeid				varchar(2) references grades default 'NG',
	instructormarks		real,
	departmentmarks		real,
	facultymark			real,
	finalmarks			real,
	optiontimeid		integer references optiontimes default 0,
	hours				float not null,
	credit				float not null,
	selectiondate		timestamp default now(),
	approved        	boolean not null default false,
	approvedate			timestamp,
	askdrop				boolean not null default false,	
	askdropdate			timestamp,	
	dropped				boolean not null default false,	
	dropdate			date,
	repeated			boolean not null default false,
	nongpacourse		boolean not null default false,	
	challengecourse		boolean not null default false,
	withdrawdate		date,
	attendance			integer,
	narrative			varchar(240),
	UNIQUE (sstudentid, scourseid)
);
CREATE INDEX sgrades_sstudentid ON sgrades (sstudentid);
CREATE INDEX sgrades_scourseid ON sgrades (scourseid);
CREATE INDEX sgrades_gradeid ON sgrades (gradeid);
CREATE INDEX sgrades_optiontimeid ON sgrades (optiontimeid);

CREATE TABLE scourseitems (
	scourseitemid		serial primary key,
	scourseid			integer references scourses,
	scourseitemname		varchar(50),
	markratio			float not null,
	totalmarks			integer not null,
	given				date,
	deadline			date,
	details				text
);
CREATE INDEX scourseitems_scourseid ON scourseitems (scourseid);

CREATE TABLE scoursemarks (
	scoursemarkid		serial primary key,
	sgradeid			integer references sgrades,
	scourseitemid		integer references scourseitems,
	approved        	boolean not null default false,
	submited			date,
	markdate			date,
	marks				float not null default 0,
	details				text,
	UNIQUE (sgradeid, scourseitemid)
);
CREATE INDEX scoursemarks_sgradeid ON scoursemarks (sgradeid);
CREATE INDEX scoursemarks_scourseitemid ON scoursemarks (scourseitemid);

CREATE TABLE sunimports (
	sunimportid			serial primary key,
	accountnumber		varchar(125),
	studentname			varchar(250),
	balance				real,
	Downloaddate		date not null default current_date,
	IsUploaded			boolean not null default false
);
