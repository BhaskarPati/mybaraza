CREATE TABLE contactseeker (
	contactseekerid		serial primary key,
	studentid			varchar(12) references students,
	seekername			varchar(120) not null,
	email				varchar(120),
	seekerdetails		varchar(120),
	seekdate			date,
	responded			boolean not null default false,
	responddate			date,
	responddetails		text,
	details				text
);
CREATE INDEX contactseeker_studentid ON contactseeker (studentid);

CREATE TABLE cvphases (
	cvphaseid			serial primary key,
	cvphasename			varchar(50),
	details				text
);

CREATE TABLE cvs (
	cvid				serial primary key,
	cvphaseid			integer references cvphases,
	studentid			varchar(12) references students,
	details				text,
	UNIQUE (cvphaseid, studentid)
);
CREATE INDEX cvs_cvphaseid ON cvs (cvphaseid);
CREATE INDEX cvs_studentid ON cvs (studentid);

CREATE TABLE employment (
	employmentid		serial primary key,
	studentid			varchar(12) references students,
	employer			varchar(120),
	empdate				date,
	lastdate			date,
	empaddress			varchar(120),
	position			varchar(120),
	details				text
);
CREATE INDEX employment_studentid ON employment (studentid);

CREATE TABLE employers (
	employerid			serial primary key,
	companyname			varchar(120) not null unique,
	email				varchar(120) not null unique,
	address				varchar(50),
	zipcode				varchar(12),
	town				varchar(50),
	street				varchar(50),
	premises			varchar(50),
	countrycodeid		char(2) references countrys,
	telno				varchar(50),
	faxno				varchar(50),
	approved			boolean not null default false,
	userpasswd			varchar(32),
	firstpasswd			varchar(32),
	details				text
);

CREATE TABLE employerjobs (
	employerjobid		serial primary key,
	employerid			integer references employers,
	jobdescription		varchar(120) not null,
	positions			integer not null,
	postdate			date,
	closedate			date,
	closed				boolean not null default false,
	qualifications		text,
	details				text
);
CREATE INDEX employerjobs_employerid ON employerjobs (employerid);

CREATE TABLE employeejobs (
	employeejobid		serial primary key,
	employerjobid		integer references employerjobs,
	studentid			varchar(12) references students,
	applicationdate		date default current_date,
	details				text
);
CREATE INDEX employeejobs_employerjobid ON employeejobs (employerjobid);
CREATE INDEX employeejobs_studentid ON employeejobs (studentid);

CREATE VIEW vwemployerjobs AS
	SELECT employers.employerid, employers.companyname, employers.email,
		employers.town, employers.countrycodeid, countrys.countryname,
		employerjobs.employerjobid, employerjobs.jobdescription,
		employerjobs.positions, employerjobs.postdate, employerjobs.closedate, employerjobs.closed
	FROM (employers INNER JOIN countrys ON employers.countrycodeid = countrys.countryid)
		INNER JOIN employerjobs ON employers.employerid = employerjobs.employerid;

CREATE VIEW vwemployeejobs AS
	SELECT vwemployerjobs.employerid, vwemployerjobs.companyname, vwemployerjobs.town, vwemployerjobs.countryname,
		vwemployerjobs.employerjobid, vwemployerjobs.jobdescription,
		vwemployerjobs.positions, vwemployerjobs.postdate, vwemployerjobs.closedate, vwemployerjobs.closed,
		employeejobs.employeejobid, employeejobs.applicationdate,
		students.studentid, students.studentname, students.email, students.telno, students.mobile
	FROM (vwemployerjobs INNER JOIN employeejobs ON vwemployerjobs.employerjobid = employeejobs.employerjobid)
		INNER JOIN students ON employeejobs.studentid = students.studentid;
	
CREATE VIEW cvview AS
	SELECT cvs.cvid, cvs.cvphaseid, cvs.studentid, cvs.details, cvphases.cvphasename, students.studentname
	FROM (cvs INNER JOIN cvphases ON cvs.cvphaseid = cvphases.cvphaseid) 
		INNER JOIN students ON cvs.studentid = students.studentid;


	