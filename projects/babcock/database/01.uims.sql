--- Table listing all continents
CREATE TABLE continents (
	continentid		char(2) primary key,
	continentname	varchar(120) unique
);

--- Table listing all countries 
CREATE TABLE countrys (
	countryid		char(2) primary key,
	continentid		char(2) references continents,
	countryname 	varchar(120) unique
);
CREATE INDEX countrys_continentid ON countrys (continentid);

CREATE TABLE states (
	stateid				serial primary key,
	statename			varchar(50),
	details				text
);

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
	org_id				integer references orgs,
	schoolname			varchar(50) not null,
	is_active			boolean default true,
	philosopy			text,
	vision				text,
	mission				text,
	objectives			text,
	details				text
);

CREATE TABLE departments (
	departmentid		varchar(12) primary key,
	org_id				integer references orgs,
	schoolid			varchar(12) references schools,
	departmentname		varchar(120) not null unique,
	is_active			boolean default true,
	overload			real,
	philosopy			text,
	vision				text,
	mission				text,
	objectives			text,
	exposures			text,
	oppotunities		text,
	details				text
);
CREATE INDEX departments_schoolid ON departments (schoolid);
CREATE INDEX departments_org_id ON departments (org_id);

CREATE TABLE grades (
	gradeid				varchar(2) primary key,
	org_id				integer references orgs,
	gradeweight			float default 0 not null,
	minrange			integer,
	maxrange			integer,
	gpacount			boolean default true not null,
	narrative			varchar(240),
	details				text
);
CREATE INDEX grades_org_id ON grades (org_id);

CREATE TABLE degreelevels (
	degreelevelid		varchar(12) primary key,
	org_id				integer references orgs,
	degreelevelname		varchar(50) not null unique,
	details				text
);
CREATE INDEX degreelevels_org_id ON degreelevels (org_id);

CREATE TABLE levellocations (
	levellocationid		serial primary key,
	levellocationname	varchar(50) not null unique,
	details				text
);

CREATE TABLE sublevels (
	sublevelid			varchar(12) primary key,
	degreelevelid		varchar(12) references degreelevels,
	levellocationid		integer references levellocations,
	org_id				integer references orgs,
	sublevelname		varchar(50) not null unique,
	details				text
);
CREATE INDEX sublevels_degreelevelid ON sublevels (degreelevelid);
CREATE INDEX sublevels_levellocationid ON sublevels (levellocationid);
CREATE INDEX sublevels_org_id ON sublevels (org_id);

CREATE TABLE degrees (
	degreeid			varchar(12) primary key,
	degreelevelid		varchar(12) references degreelevels,
	degreename			varchar(50) not null unique,
	degree_narrative	varchar(240),
	details				text
);
CREATE INDEX degrees_degreelevelid ON degrees (degreelevelid);

CREATE TABLE residences (
	residenceid			varchar(12) primary key,
	residencename		varchar(50) not null unique,
	defaultrate			float default 0 not null,
	offcampus			boolean not null default false,
	sex					varchar(1),
	residencedean		varchar(50),
	min_level			integer default 100,
	max_level			integer default 500,
	majors				text,
	details				text
);

CREATE TABLE residenceCapacitys (
	residenceCapacityid serial primary key,
	residenceid			varchar(12) references residences,
	blockname			varchar(12) default 'A' not null,
	capacity			integer default 120 not null,
	roomsize			integer default 4 not null,
	Narrative			varchar(240),
	UNIQUE(residenceid, blockname)
);
CREATE INDEX residenceCapacitys_residenceid ON residenceCapacitys (residenceid);

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
	org_id				integer references orgs,
	instructorname		varchar(50) not null unique,
	majoradvisor		boolean default false not null,
	headofdepartment	boolean default false not null,
	headoffaculty		boolean default false not null,
	email				varchar(240),
	details				text
);
CREATE INDEX instructors_departmentid ON instructors (departmentid);
CREATE INDEX instructors_org_id ON instructors (org_id);

CREATE TABLE coursetypes (
	coursetypeid		serial primary key,
	coursetypename		varchar(50),
	details				text
);

CREATE TABLE courses (
	courseid			varchar(12) primary key,
	departmentid		varchar(12) references departments,
	degreelevelid		varchar(12) references degreelevels,
	coursetypeid		integer references coursetypes,
	org_id				integer references orgs,
	coursetitle			varchar(120) not null,
	credithours			float not null,
	maxcredit			float not null default 0,
	lecturehours		float not null default 0,
	practicalhours		float not null default 0,
	cliniccourse		boolean not null default false,
	labcourse			boolean not null default false,
	iscurrent			boolean not null default true,
	nogpa				boolean not null default false,
	norepeats			boolean not null default false,
	allow_ws			boolean not null default false,
	yeartaken			integer not null default 1,
	details				text
);
CREATE INDEX courses_departmentid ON courses (departmentid);
CREATE INDEX courses_degreelevelid ON courses (degreelevelid);
CREATE INDEX courses_coursetypeid ON courses (coursetypeid);
CREATE INDEX courses_org_id ON courses (org_id);

CREATE TABLE bulleting (
	bulletingid			serial primary key,
 	bulletingname		varchar(50),
	startingquarter		varchar(12),
	endingquarter		varchar(12),
	iscurrent			boolean not null default false,
	details				text
);

CREATE TABLE prerequisites (
	prerequisiteid		serial primary key,
	courseid			varchar(12) references courses,
	precourseid			varchar(12) references courses,
	gradeid				varchar(2) references grades,
	bulletingid			integer references bulleting,
	org_id				integer references orgs,
	optionlevel			integer not null default 1,
	narrative			varchar(120)
);
CREATE INDEX prerequisites_courseid ON prerequisites (courseid);
CREATE INDEX prerequisites_precourseid ON prerequisites (precourseid);
CREATE INDEX prerequisites_gradeid ON prerequisites (gradeid);
CREATE INDEX prerequisites_bulletingid ON prerequisites (bulletingid);
CREATE INDEX prerequisites_org_id ON prerequisites (org_id);

CREATE TABLE majors (
	majorid				varchar(12) primary key,
	departmentid		varchar(12) references departments,
	degreelevelid		varchar(12) references degreelevels,
	org_id				integer references orgs,
	majorname			varchar(75) not null unique,
	major_title			varchar(120),
	major				boolean default false not null,
	minor				boolean default false not null,
	is_active			boolean default true not null,
	fullcredit			integer default 200 not null,
	electivecredit		integer not null,
	minorelectivecredit	integer not null,
	majorminimal		real,
	minorminimum		real,
	coreminimum			real,
	quarterload			real,
	minlevel			integer not null default 100,
	maxlevel			integer not null default 400,
	details				text
);
CREATE INDEX majors_departmentid ON majors (departmentid);
CREATE INDEX majors_degreelevelid ON majors (degreelevelid);
CREATE INDEX majors_org_id ON majors (org_id);

CREATE TABLE major_levels (
	major_level_id		serial primary key,
	majorid				varchar(12) references majors,
	org_id				integer references orgs,
	major_level			integer not null,
	quarterload			real not null,
	details				text
);
CREATE INDEX major_levels_majorid ON major_levels (majorid);
CREATE INDEX major_levels_org_id ON major_levels (org_id);

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
	org_id				integer references orgs,
	minor				boolean not null default false,
	quarterdone			integer,
	narrative			varchar(240),
	UNIQUE (majorid, courseid, contenttypeid, bulletingid, minor)
);
CREATE INDEX majorcontents_majorid ON majorcontents (majorid);
CREATE INDEX majorcontents_courseid ON majorcontents (courseid);
CREATE INDEX majorcontents_contenttypeid ON majorcontents (contenttypeid);
CREATE INDEX majorcontents_gradeid ON majorcontents (gradeid);
CREATE INDEX majorcontents_bulletingid ON majorcontents (bulletingid);
CREATE INDEX majorcontents_org_id ON majorcontents (org_id);

CREATE TABLE students (
	studentid			varchar(12) primary key,
	departmentid		varchar(12) references departments,
	denominationid		varchar(12) references denominations,
	sys_audit_trail_id	integer references sys_audit_trail,
	org_id				integer references orgs,
	studentname			varchar(100) not null,
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
	stateid				integer references states,
	telno				varchar(50),
	mobile				varchar(75),
	BloodGroup			varchar(12),
	email				varchar(240),
	guardianname		varchar(50),
	gaddress			varchar(250),
	gzipcode			varchar(50),
	gtown				varchar(50),
	gcountrycodeid		char(2) references countrys,
	gtelno				varchar(50),
	gemail				varchar(240),
	accountnumber		varchar(16),
	residenceid			varchar(12),
	blockname			varchar(12),
	roomnumber			integer,
	staff				boolean default false not null,
	alumnae				boolean default false not null,
	postcontacts		boolean default false not null,
	
	onprobation			boolean default false not null,
	seesecurity			boolean default false not null,
	seesss				boolean default false not null, 
	seesdc				boolean default false not null, 
	seehalls			boolean default false not null,
	seeregistrar		boolean default false not null,
	seechaplain			boolean default false not null,

	offcampus			boolean default false not null,
	fullbursary			boolean default false not null,
	newstudent			boolean default false not null,
	matriculate			boolean default false not null,
	student_edit		varchar(50) default 'none' not null,

	balance_time		timestamp,
	currentbalance		real,

	etranzact_card_no	varchar(64),
	picturefile			varchar(240),
	emailuser			varchar(120),
	currentcontact		text,
	details				text
);
CREATE INDEX students_departmentid ON students (departmentid);
CREATE INDEX students_denominationid ON students (denominationid);
CREATE INDEX students_stateid ON students (stateid);
CREATE INDEX students_nationality ON students (nationality);
CREATE INDEX students_countrycodeid ON students (countrycodeid);
CREATE INDEX students_gcountrycodeid ON students (gcountrycodeid);
CREATE INDEX students_accountnumber ON students (accountnumber);
CREATE INDEX students_org_id ON students (org_id);
CREATE INDEX students_sys_audit_trail_id  ON students (sys_audit_trail_id);

CREATE TABLE probation_list (
	probation_list_id	serial primary key,
	studentid			varchar(12) references students,
	org_id				integer references orgs,
	approvedby			varchar(50),
	approvaltype		varchar(25),
	approvedate			timestamp default now(),
	clientip			varchar(50)
);
CREATE INDEX probation_list_studentid ON probation_list (studentid);
CREATE INDEX probation_list_org_id ON probation_list (org_id);

CREATE TABLE studentdegrees (
	studentdegreeid		serial primary key,
	degreeid			varchar(12) references degrees,
	sublevelid			varchar(12) references sublevels,
	studentid			varchar(12) references students,
	bulletingid			integer references bulleting,
	org_id				integer references orgs,
	completed			boolean not null default false,
	died				boolean not null default false,
	started				date,
	cleared				boolean not null default false,
	clearedate			date,
	graduated			boolean not null default false,
	graduatedate		date,
	dropout				boolean not null default false,
	transferin			boolean not null default false,
	transferout			boolean not null default false,
	details				text,
	unique (degreeid, studentid)
);
CREATE INDEX studentdegrees_degreeid ON studentdegrees (degreeid);
CREATE INDEX studentdegrees_sublevelid ON studentdegrees (sublevelid);
CREATE INDEX studentdegrees_studentid ON studentdegrees (studentid);
CREATE INDEX studentdegrees_bulletingid ON studentdegrees (bulletingid);
CREATE INDEX studentdegrees_org_id ON studentdegrees (org_id);

CREATE TABLE transcriptprint (
	transcriptprintid	serial primary key,
	studentdegreeid		integer references studentdegrees,
	entity_id			integer references entitys,
	org_id				integer references orgs,
	printdate			timestamp default now(),
	narrative			varchar(240)
);
CREATE INDEX transcriptprint_studentdegreeid ON transcriptprint (studentdegreeid);	
CREATE INDEX transcriptprint_entity_id ON transcriptprint (entity_id);
CREATE INDEX transcriptprint_org_id ON transcriptprint (org_id);

CREATE TABLE studentmajors ( 
	studentmajorid		serial primary key,
	studentdegreeid		integer references studentdegrees,
	majorid				varchar(12) references majors,
	org_id				integer references orgs,
	major				boolean not null default false,
	primarymajor		boolean not null default false,
	nondegree			boolean not null default false,
	premajor			boolean not null default false,
	Details				text,
	UNIQUE(studentdegreeid)
);
CREATE INDEX studentmajors_studentdegreeid ON studentmajors (studentdegreeid);
CREATE INDEX studentmajors_majorid ON studentmajors (majorid);
CREATE INDEX studentmajors_org_id ON studentmajors (org_id);

CREATE TABLE transferedcredits (
	transferedcreditid		serial primary key,
	studentdegreeid			integer references studentdegrees,
	courseid				varchar(12) references courses,
	org_id					integer references orgs,
	credithours				float default 0 not null,
	narrative				varchar(240),
	UNIQUE (studentdegreeid, courseid)
);
CREATE INDEX transferedcredits_studentdegreeid ON transferedcredits (studentdegreeid);
CREATE INDEX transferedcredits_courseid ON transferedcredits (courseid);
CREATE INDEX transferedcredits_org_id ON transferedcredits (org_id);

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
	org_id				integer references orgs,
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
CREATE INDEX studentrequests_org_id ON studentrequests (org_id);

CREATE TABLE quarters (
	quarterid			varchar(12) primary key,
	org_id				integer references orgs,
	qstart				date not null,
	qlatereg			date not null default current_date,
	qlatechange			date not null default current_date,
	qlastdrop			date not null,
	qend				date not null,
	active				boolean default false not null,
	feesline			real not null default 20000,
	resline				real not null default 20000,
	applicationfees		real not null default 5500,
	acceptance_fee		real not null default 125000,
	transcriptfees		real not null default 5000,
	lateregistrationfee	real not null default 5000,
	mealcharge			real not null default 33600,
	premialhall			real not null default 80000,
	mincredits			real not null default 16,
	maxcredits			real not null default 21,
	publishgrades		boolean default false not null,
	postgraduate		boolean default false not null,
	new_student_code	varchar(2) default 'NU' not null,
	new_student_index	integer default 1 not null,
	details				text
);
CREATE INDEX quarters_active ON quarters (active);
CREATE INDEX quarters_org_id ON quarters (org_id);

CREATE TABLE qcalendar (
	qcalendarid			serial primary key,
	quarterid			varchar(12) references quarters,
	sublevelid			varchar(12) references sublevels,
	org_id				integer references orgs,
	qdate				date not null,
	qenddate			date not null,
	event				varchar(120),
	details				text
);
CREATE INDEX qcalendar_quarterid ON qcalendar (quarterid);
CREATE INDEX qcalendar_sublevelid ON qcalendar (sublevelid);
CREATE INDEX qcalendar_org_id ON qcalendar (org_id);

CREATE TABLE qresidences (
	qresidenceid		serial primary key,
	quarterid			varchar(12) references quarters,
	residenceid			varchar(12) references residences,
	org_id				integer references orgs,
	residenceoption		varchar(50) not null default 'Full',
	charges				float not null,
	full_charges		float not null,
	active				boolean not null default true,
	details				text,
	UNIQUE (quarterid, residenceid, residenceoption)
);
CREATE INDEX qresidences_quarterid ON qresidences (quarterid);
CREATE INDEX qresidences_residenceid ON qresidences (residenceid);
CREATE INDEX qresidences_org_id ON qresidences (org_id);

CREATE TABLE qcharges (
	qchargeid			serial primary key,
	quarterid			varchar(12) references quarters,
	degreelevelid		varchar(12) references degreelevels,
	sublevelid			varchar(12) references sublevels,
	org_id				integer references orgs,
	studylevel			integer not null,
	fullfees			float not null default 263864,
	fullmeal2fees		float not null default 1000,
	fullmeal3fees		float not null default 1000,
	fees				float not null default 263864,
	meal2fees			float not null default 1000,
	meal3fees			float not null default 1000,
	premiumhall			float not null default 1000,
	minimalfees			float not null default 0,
	firstinstalment		real not null default 0,
	firstdate			date,
	secondinstalment	real not null default 0,
	seconddate			date,
	narrative			varchar(120),
	UNIQUE (quarterid, degreelevelid, studylevel, sublevelid)
);
CREATE INDEX qcharges_quarterid ON qcharges (quarterid);
CREATE INDEX qcharges_degreelevelid ON qcharges (degreelevelid);
CREATE INDEX qcharges_studylevel ON qcharges (studylevel);
CREATE INDEX qcharges_sublevelid ON qcharges (sublevelid);
CREATE INDEX qcharges_org_id ON qcharges (org_id);

CREATE TABLE qmcharges (
	qmchargeid			serial primary key,
	quarterid			varchar(12) references quarters,
	majorid				varchar(12) references majors,
	sublevelid			varchar(12) references sublevels,
	org_id				integer references orgs,
	studylevel			integer not null,
	charge				float not null default 0,
	fullcharge			float not null default 0,
	meal2charge			float not null default 0,
	meal3charge			float not null default 0,
	phallcharge			float not null default 0,
	narrative			varchar(120),
	UNIQUE (quarterid, majorid, studylevel, sublevelid)
);
CREATE INDEX qmcharges_quarterids ON qmcharges (quarterid);
CREATE INDEX qmcharges_majorid ON qmcharges (majorid);
CREATE INDEX qmcharges_studylevel ON qmcharges (studylevel);
CREATE INDEX qmcharges_sublevelid ON qmcharges (sublevelid);
CREATE INDEX qmcharges_org_id ON qmcharges (org_id);

CREATE TABLE chargetypes (
	chargetypeid			serial primary key,
	chargetypename			varchar(50) not null unique,
	accountnumber			varchar(25) not null,
	accountcode				varchar(25) not null,
	oncampus				boolean not null default true,
	offcampus				boolean not null default false,
	addmeal					boolean not null default false,
	details					text
);

CREATE TABLE qchargedefinations (
	qchargedefinationid		serial primary key,
	chargetypeid			integer references chargetypes,
	sublevelid				varchar(12) references sublevels,
	quarterid				varchar(12) references quarters,
	org_id					integer references orgs,
	studylevel				integer not null,
	amount					real not null,
	narrative				varchar(240),
	UNIQUE (chargetypeid, quarterid, studylevel, sublevelid)
);
CREATE INDEX qchargedefinations_chargetypeid ON qchargedefinations (chargetypeid);
CREATE INDEX qchargedefinations_sublevelid ON qchargedefinations (sublevelid);
CREATE INDEX qchargedefinations_quarterid ON qchargedefinations (quarterid);
CREATE INDEX qchargedefinations_org_id ON qchargedefinations (org_id);

CREATE TABLE qmchargedefinations (
	qmchargedefinationid	serial primary key,
	chargetypeid			integer references chargetypes,
	quarterid				varchar(12) references quarters,
	majorid					varchar(12) references majors,
	sublevelid				varchar(12) references sublevels,
	org_id					integer references orgs,
	studylevel				integer not null,
	amount					real not null,
	narrative				varchar(240),
	UNIQUE (chargetypeid, quarterid, majorid, studylevel, sublevelid)
);
CREATE INDEX qmchargedefinations_chargetypeid ON qmchargedefinations (chargetypeid);
CREATE INDEX qmchargedefinations_quarterid ON qmchargedefinations (quarterid);
CREATE INDEX qmchargedefinations_majorid ON qmchargedefinations (majorid);
CREATE INDEX qmchargedefinations_sublevelid ON qmchargedefinations (sublevelid);
CREATE INDEX qmchargedefinations_org_id ON qmchargedefinations (org_id);

CREATE TABLE qselections (
	qselectionid		integer primary key,
	stage				integer,
	selection			varchar(240),
	details				text
);

CREATE TABLE qstudents (
	qstudentid			serial primary key,
	quarterid			varchar(12) references quarters,
	studentdegreeid		integer references studentdegrees,
	qresidenceid		integer references qresidences,
	sublevelid			varchar(12) references sublevels,
	org_id				integer references orgs,
	sys_audit_trail_id	integer references sys_audit_trail,
	charges				float default 0 not null,
	probation			boolean default false not null,
	offcampus			boolean default false not null,
	premiumhall			boolean default false not null,
	mealtype			varchar(12) default 'BLS' not null,
	citizengrade		varchar(2),
	citizenmarks		integer,
	blockname			varchar(12),
	roomnumber			integer,

	balance_time		timestamp,
	currbalance			real,

	studylevel			integer,
	applicationtime		timestamp not null default now(),
	residence_time		timestamp not null default now(),
	firstclosetime		timestamp,
	lateregdate			timestamp,
	paymenttype			integer default 1 not null,
	lateFeePayment		boolean default false not null,
	ispartpayment		boolean default false not null,
	finalised			boolean default false not null,
	clearedfinance		boolean default false not null,
	finaceapproval		boolean default false not null,
	majorapproval		boolean default false not null,
	departapproval		boolean default false not null,
	chaplainapproval	boolean default false not null,
	studentdeanapproval	boolean default false not null,
	overloadapproval	boolean default false not null,
	overloadhours		float,
	intersession		boolean default false not null,
	financeclosed		boolean default false not null,
	closed				boolean default false not null,
	printed				boolean default false not null,
	approved			boolean default false not null,
	ApprovedDate		timestamp,
	Picked				boolean default false not null,
	Pickeddate			timestamp,
	LRFPicked			boolean default false not null,
	LRFPickeddate		timestamp,
	ArrivalDate			timestamp,
	hallreceipt			integer,
	mealticket			integer,
	
	financenarrative	text,
	noapproval			text,
	details				text,
	UNIQUE(quarterid, studentdegreeid)
);
CREATE INDEX qstudents_quarterid ON qstudents (quarterid);
CREATE INDEX qstudents_studentdegreeid ON qstudents (studentdegreeid);
CREATE INDEX qstudents_qresidenceid ON qstudents (qresidenceid);
CREATE INDEX qstudents_sublevelid ON qstudents (sublevelid);
CREATE INDEX qstudents_roomnumber ON qstudents (roomnumber);
CREATE INDEX qstudents_studylevel ON qstudents (studylevel);
CREATE INDEX qstudents_org_id ON qstudents (org_id);
CREATE INDEX qstudents_sys_audit_trail_id ON qstudents (sys_audit_trail_id);

CREATE TABLE phistory (
	PHistoryID			integer primary key,
	PHistoryName		varchar(120) not null unique
);

CREATE TABLE studentpayments (
	studentpaymentid	serial primary key,
	qstudentid			integer references qstudents,
	org_id				integer references orgs,
	phistoryid			integer default -100,
	applydate			timestamp not null default now(),
	amount				real not null,
	old_amount			real,
	approved			boolean not null default false,
	approvedtime		timestamp,
	Picked				boolean default false not null,
	Pickeddate			timestamp,
	first_attempt		timestamp,
	ns_amount			real,
	payment_code		varchar(50),
	terminalid			varchar(12),
	mechant_code		varchar(16),
	narrative			varchar(240),
	purpose				varchar(240)
);	
CREATE INDEX studentpayments_qstudentid ON studentpayments (qstudentid);
CREATE INDEX studentpayments_phistoryid ON studentpayments (phistoryid);
CREATE INDEX studentpayments_org_id ON studentpayments (org_id);

CREATE SEQUENCE studentpayment_seq START 1;

CREATE TABLE studentpayment_logs (
	studentpayment_log_id	serial primary key,
	studentpaymentid	integer,
	created				timestamp not null default now()
);

CREATE TABLE paymentracks (
	paymentrackid		serial primary key,
	studentpaymentid	integer,
	oldtransactionid	integer
);

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
	quarterid			varchar(12) references quarters,
	org_id				integer references orgs,
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
CREATE INDEX scholarships_quarterid ON scholarships (quarterid);
CREATE INDEX scholarships_org_id ON scholarships (org_id);

CREATE TABLE citizenshiptypes (
	citizenshiptypeid	serial primary key,
	citizenshiptypename	varchar(50) not null unique,
	demerits			integer not null,
	details				text
);

CREATE TABLE citizenships (
	citizenshipid		serial primary key,
	citizenshiptypeid	integer references citizenshiptypes,
	qstudentid			integer references qstudents,
	org_id				integer references orgs,
	entrydate			date not null,
	narrative			varchar(240),
	details				text
);
CREATE INDEX citizenships_citizenshiptypeid ON citizenships (citizenshiptypeid);
CREATE INDEX citizenships_qstudentid ON citizenships (qstudentid);
CREATE INDEX citizenships_org_id ON citizenships (org_id);

CREATE TABLE studentexits (
	studentexitid		serial primary key,
	qstudentid			integer references qstudents,
	org_id				integer references orgs,
	exitdate			date not null,
	entrydate			date not null,
	requestexit			date not null,
	requestentry		date not null,
	reason				varchar(240) not null,
	longexit			boolean not null default false,
	approved			boolean not null default false,
	details				text
);
CREATE INDEX studentexits_qstudentid ON studentexits (qstudentid);
CREATE INDEX studentexits_org_id ON studentexits (org_id);

CREATE TABLE approvallist (
	approvalid			serial primary key,
	qstudentid			integer references qstudents,
	org_id				integer references orgs,
	approvedby			varchar(50),
	approvaltype		varchar(25),
	approvedate			timestamp default now(),
	clientip			varchar(50)
);
CREATE INDEX approvallist_qstudentid ON approvallist (qstudentid);
CREATE INDEX approvallist_org_id ON approvallist (org_id);

CREATE TABLE class_options (
	class_option_id		serial primary key,
	org_id				integer references orgs,
	class_option_name	varchar(50) not null unique
);
CREATE INDEX class_options_org_id ON class_options (org_id);

CREATE TABLE qcourses (
	qcourseid			serial primary key,
	quarterid			varchar(12) references quarters,
	instructorid		varchar(12) references instructors,
	courseid			varchar(12) references courses,
	org_id				integer references orgs,
	coursetitle			varchar(120),
	classoption			varchar(50) default 'Main' not null,
	maxclass			integer not null,
	labcourse			boolean default false not null,
	extracharge			float default 0 not null,
	approved			boolean default false not null,
	intersession		boolean default false not null,
	lecturesubmit		boolean default false not null,
	lsdate				timestamp default now(),
	departmentsubmit	boolean default false not null,
	dsdate				timestamp default now(),
	facultysubmit		boolean default false not null,
	fsdate				timestamp default now(),
	departmentchange	varchar(240),
	facultychange		varchar(240),
	registrychange		varchar(240),
	attendance			integer,
	oldcourseid			varchar(12),
	fullattendance		integer,
	details				text,
	UNIQUE (instructorid, courseid, quarterid, classoption)
);
CREATE INDEX qcourses_quarterid ON qcourses (quarterid);
CREATE INDEX qcourses_instructorid ON qcourses (instructorid);
CREATE INDEX qcourses_courseid ON qcourses (courseid);
CREATE INDEX qcourses_org_id ON qcourses (org_id);

CREATE TABLE gradeopening (
	gradeopeningid		serial primary key,
	qcourseid			integer references qcourses,
	org_id				integer references orgs,
	requestdate			timestamp default now(),
	hodapproval			boolean default false not null,
	hodreject			boolean default false not null,
	hoddate				timestamp,
	hodid				varchar(12),
	deanapproval		boolean default false not null,
	deanreject			boolean default false not null,
	deandate			timestamp,
	deanid				varchar(12),
	regapproval			boolean default false not null,
	regreject			boolean default false not null,
	regdate				timestamp,
	regid				integer,
	details				text
);
CREATE INDEX gradeopening_qcourseid ON gradeopening (qcourseid);
CREATE INDEX gradeopening_hodid ON gradeopening (hodid);
CREATE INDEX gradeopening_deanid ON gradeopening (deanid);
CREATE INDEX gradeopening_regid ON gradeopening (regid);
CREATE INDEX gradeopening_org_id ON gradeopening (org_id);

CREATE TABLE optiontimes (
	optiontimeid		serial primary key,
	optiontimename		varchar(50),
	details				text
);
INSERT INTO optiontimes (optiontimeid, optiontimename) VALUES (0, 'Main');

CREATE TABLE qtimetable (
	qtimetableid		serial primary key,
	assetid				integer references assets,
	qcourseid			integer references qcourses,
	optiontimeid		integer references optiontimes default 0,
	org_id				integer references orgs,
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
CREATE INDEX qtimetable_assetid ON qtimetable (assetid);
CREATE INDEX qtimetable_qcourseid ON qtimetable (qcourseid);
CREATE INDEX qtimetable_optiontimeid ON qtimetable (optiontimeid);
CREATE INDEX qtimetable_org_id ON qtimetable (org_id);

CREATE TABLE qexamtimetable (
	qexamtimetableid	serial primary key,
	assetid				integer references assets,
	qcourseid			integer references qcourses,
	optiontimeid		integer references optiontimes default 0,
	org_id				integer references orgs,
	examdate			date,
	starttime			time not null,
	endtime				time not null,
	lab					boolean not null default false,
	details				text
);
CREATE INDEX qexamtimetable_assetid ON qexamtimetable (assetid);
CREATE INDEX qexamtimetable_qcourseid ON qexamtimetable (qcourseid);
CREATE INDEX qexamtimetable_optiontimeid ON qexamtimetable (optiontimeid);
CREATE INDEX qexamtimetable_org_id ON qexamtimetable (org_id);

CREATE TABLE qgrades (
	qgradeid 			serial primary key,
	qstudentid			integer references qstudents,
	qcourseid			integer references qcourses,
	gradeid				varchar(2) references grades default 'NG',
	org_id				integer references orgs,
	sys_audit_trail_id	integer references sys_audit_trail,
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
	UNIQUE (qstudentid, qcourseid)
);
CREATE INDEX qgrades_qstudentid ON qgrades (qstudentid);
CREATE INDEX qgrades_qcourseid ON qgrades (qcourseid);
CREATE INDEX qgrades_gradeid ON qgrades (gradeid);
CREATE INDEX qgrades_optiontimeid ON qgrades (optiontimeid);
CREATE INDEX qgrades_org_id ON qgrades (org_id);
CREATE INDEX qgrades_sys_audit_trail_id ON qgrades (sys_audit_trail_id);

CREATE TABLE gradechangelist (
	gradechangeid		serial primary key,
	qgradeid			integer references qgrades,
	entity_id			integer references entitys,
	org_id				integer references orgs,
	changedby			varchar(50),
	oldgrade			varchar(2),
	newgrade			varchar(2),
	changedate			timestamp default now(),
	clientip			varchar(50)
);
CREATE INDEX gradechangelist_qgradeid ON gradechangelist (qgradeid);
CREATE INDEX gradechangelist_entity_id ON gradechangelist (entity_id);
CREATE INDEX gradechangelist_org_id ON gradechangelist (org_id);

CREATE TABLE qcourseitems (
	qcourseitemid		serial primary key,
	qcourseid			integer references qcourses,
	org_id				integer references orgs,
	qcourseitemname		varchar(50),
	markratio			float not null,
	totalmarks			integer not null,
	given				date,
	deadline			date,
	details				text
);
CREATE INDEX qcourseitems_qcourseid ON qcourseitems (qcourseid);
CREATE INDEX qcourseitems_org_id ON qcourseitems (org_id);

CREATE TABLE qcoursemarks (
	qcoursemarkid		serial primary key,
	qgradeid			integer references qgrades,
	qcourseitemid		integer references qcourseitems,
	org_id				integer references orgs,
	approved        	boolean not null default false,
	submited			date,
	markdate			date,
	marks				float not null default 0,
	details				text,
	UNIQUE (qgradeid, qcourseitemid)
);
CREATE INDEX qcoursemarks_qgradeid ON qcoursemarks (qgradeid);
CREATE INDEX qcoursemarks_qcourseitemid ON qcoursemarks (qcourseitemid);
CREATE INDEX qcoursemarks_org_id ON qcoursemarks (org_id);

CREATE TABLE sunimports (
	sunimportid			serial primary key,
	accountnumber		varchar(125),
	studentname			varchar(250),
	balance				real,
	Downloaddate		date not null default current_date,
	IsUploaded			boolean not null default false
);

CREATE TABLE bankfile (
	bankfileid			serial primary key,
	TransactionDate		varchar(120),
	card_number			varchar(120),
	request_id			varchar(120),
	description			varchar(120),
	amount				varchar(120),
	response_code		varchar(120),
	Downloaddate		date not null default current_date,
	IsUploaded			boolean not null default false
);

CREATE TABLE banksuspence (
	banksuspenceid			serial primary key,
	entrydate				timestamp not null, 
	CustomerReference		varchar(50),
	quarterid				varchar(25),
	accountnumber			varchar(25),
	TransactionAmount		real,
	Narrative				varchar(120),
	studentpaymentid		integer,
	ValueDate				date,
	Suspence				boolean default false not null,
	Suspencedate			timestamp,
	Picked					boolean default false not null,
	Pickeddate				timestamp,
	Approved				boolean default false not null,
	Approveddate			timestamp,
	TransComments			varchar(120)
);

CREATE TABLE Bankrecons (
	BankreconID				serial primary key,
	TransactionDate			varchar(120),
	ValueDate				varchar(120),
	TransactionDetails		varchar(120),
	DebitValue				varchar(120),
	CreditValue				varchar(120)
);

CREATE TABLE banks (
	terminalid		varchar(32) primary key,
	bankname 		varchar(32),
	accountcode		varchar(32)
);

CREATE TABLE qposting_logs (
	qposting_log_id 	serial primary key,
	qstudentid			integer references qstudents,
	sys_audit_trail_id	integer references sys_audit_trail,
	posted_type_id		integer default 1 not null,
	posted_date			timestamp default now() not null,
	posted_amount		real,
	narrative			varchar(120)
);
CREATE INDEX qposting_logs_qstudentid ON qposting_logs (qstudentid);
CREATE INDEX qposting_logs_sys_audit_trail_id ON qposting_logs (sys_audit_trail_id);

ALTER TABLE entitys ADD mail_user	varchar(50);


CREATE TABLE import_grades (
	import_grade_id				serial primary key,
	course_id					varchar(12),
	session_id					varchar(12),
	student_id					varchar(12),
	score						real,
	created						timestamp default current_timestamp
);

