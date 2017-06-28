CREATE TABLE marks (
	markid				integer primary key,
	grade				varchar(2) not null,
	markweight			integer not null default 0,
	narrative			varchar(240)
);

CREATE TABLE subjects (
	subjectid			integer primary key,
	subjectname			varchar(25) not null,
	narrative			varchar(240)
);

CREATE TABLE applications (
	applicationid			serial primary key,
	email					varchar(120) not null UNIQUE,
	userpasswd				varchar(32),
	firstpasswd				varchar(32),
	surname					varchar(50) not null,
	othernames				varchar(50),
	firstname				varchar(50) not null,
	appoved					boolean not null default false,
	openapplication			boolean not null default false,
	closed					boolean not null default false,
	emailed					boolean not null default false,
	paid					boolean not null default false,
	receiptnumber			varchar(50),
	confirmationno			varchar(75),
	applicationdate    		date not null default current_date
);

CREATE TABLE registrations (
	registrationid			serial primary key,
	firstchoiceid			varchar(12) references majors,
	secondchoiceid			varchar(12) references majors,
	applicationid			integer unique references applications,
	surname					varchar(50) not null,
	firstname				varchar(50) not null,
	othernames				varchar(50),
	maidenname				varchar(50),
	formernames				varchar(50),
	homeaddress				text,
	phonenumber				varchar(50),
	email					varchar(120) not null unique,
	address					varchar(240),
	zipcode					varchar(50),
	town					varchar(50),
	birthdate				date not null,
	Sex						varchar(1),
	homenumber				varchar(50),
	mobilenumber			varchar(50),
	nationalityid			char(2) references countrys,
	origincountryid			char(2) references countrys,
	denominationid			varchar(12) references denominations,
	MaritalStatus			varchar(2),
	guardian				text,
	nextofknin				varchar(50),
	kinrelationship			varchar(50),
	existingid				varchar(12),
	applicationdate    		date not null default current_date,
	submitapplication		boolean not null default false,
	submitdate				timestamp,
	isaccepted				boolean not null default false,
	isreported				boolean not null default false,
	isdeferred				boolean not null default false,
	isrejected				boolean not null default false,
	evaluationdate			date,
	reported				boolean not null default false,
	reporteddate			date,
	offcampus				boolean not null default false,
	previousapplications	boolean not null default false,
	previousadmitted		boolean not null default false,
	admittedyear			varchar(12),
	admitttedmajorid		varchar(12) references majors,
	previoussuspended		boolean not null default false,
	suspendedperiod			varchar(12),
	drugabuse				boolean not null default false,
	drugtherapies			varchar(240),
	cultmemeber				boolean not null default false,
	cultperiod				varchar(240),
	culttherapies			varchar(240),
	GCEMarks				real,
	SSCEMarks				real,
	OtherMarks				real,
	evaluationofficer		varchar(50),
	admissionstatus			varchar(25) not null default 'Regular',
	picturefile				varchar(240),
	socialproblems			text,
	details					text
);
CREATE INDEX registrations_firstchoiceid ON registrations (firstchoiceid);
CREATE INDEX registrations_secondchoiceid ON registrations (secondchoiceid);
CREATE INDEX registrations_applicationid ON registrations (applicationid);
CREATE INDEX registrations_nationalityid ON registrations (nationalityid);
CREATE INDEX registrations_origincountryid ON registrations (origincountryid);
CREATE INDEX registrations_denominationid ON registrations (denominationid);

