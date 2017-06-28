--- Extend Entities to accomodate 
ALTER TABLE entitys ADD selection_id 			integer;
ALTER TABLE entitys ADD picture_file			varchar(50);

CREATE TABLE marks (
	markid					integer primary key,
	grade					varchar(2) not null,
	markweight				integer not null default 0,
	narrative				varchar(240)
);

CREATE TABLE subjects (
	subjectid				integer primary key,
	subjectname				varchar(25) not null,
	narrative				varchar(240)
);

CREATE TABLE exam_centers (
	exam_center_id			serial primary key,
	exam_center_name		varchar(320),
	center_capacity			integer default 100,
	is_active				boolean default true
);

CREATE TABLE exam_dates (
	exam_date_id			serial primary key,
	exam_center_id			integer references exam_centers,
	exam_date_name			varchar(240),
	exam_date				date,
	is_active				boolean default true
);
CREATE INDEX exam_dates_exam_center_id ON exam_dates (exam_center_id);

CREATE TABLE applications (
	applicationid			integer primary key,
	exam_date_id			integer references exam_dates,
	quarterid				varchar(12) references quarters,
	org_id					integer references orgs,
	approved				boolean not null default false,
	openapplication			boolean not null default false,
	closed					boolean not null default false,
	emailed					boolean not null default false,
	paid					boolean not null default false,
	receiptnumber			varchar(50),
	confirmationno			varchar(75),
	purchasecentre			varchar(50),
	amount					real not null,
	applicationdate    		date default current_date not null,
	Picked					boolean default false not null,
	Pickeddate				timestamp,
	paydate					timestamp,
	e_amount				real,
	success					varchar(50),
	payment_code			varchar(50),
	trans_no				varchar(50),

	card_type				varchar(50),
	transaction_id			integer,

	narrative				varchar(240)
);
CREATE INDEX applications_exam_date_id ON applications (exam_date_id);
CREATE INDEX applications_quarterid ON applications (quarterid);
CREATE INDEX applications_org_id ON applications (org_id);

CREATE SEQUENCE applications_transaction_id_seq;

CREATE TABLE registrations (
	registrationid			integer primary key,
	firstchoiceid			varchar(12) references majors,
	secondchoiceid			varchar(12) references majors,
	majorid					varchar(12) references majors,
	entry_form_id			integer references entry_forms,
	org_id					integer references orgs,
	surname					varchar(50) not null,
	firstname				varchar(50) not null,
	othernames				varchar(50),
	maidenname				varchar(50),
	formernames				varchar(50),
	homeaddress				text,
	phonenumber				varchar(50),
	email					varchar(120) not null,
	address					varchar(240),
	zipcode					varchar(50),
	town					varchar(50),
	birthdate				date not null,
	Sex						varchar(12),
	birthstateid			integer references states,
	originstateid			integer references states,
	homenumber				varchar(50),
	mobilenumber			varchar(50),
	nationalityid			char(2) references countrys,
	origincountryid			char(2) references countrys,
	denominationid			varchar(12) references denominations,
	MaritalStatus			varchar(12),
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
	admission_level			integer default 100 not null,
	
	jamb_reg_no				varchar(50),
	jamb_exam_no			varchar(50),
	jamb_score				varchar(50),
	
	acceptance_fees			real,
	af_date					timestamp,
	af_amount				real,
	af_success				varchar(50),
	af_payment_code			varchar(50),
	af_trans_no				varchar(50),
	af_card_type			varchar(50),
	af_picked				boolean default false not null,
	af_picked_date			timestamp,
	
	is_newstudent			boolean default false not null,
	account_number			varchar(50),
	e_tranzact_no			varchar(50),
	
	details					text
);
CREATE INDEX registrations_firstchoiceid ON registrations (firstchoiceid);
CREATE INDEX registrations_secondchoiceid ON registrations (secondchoiceid);
CREATE INDEX registrations_majorid ON registrations (majorid);
CREATE INDEX registrations_birthstateid ON registrations (birthstateid);
CREATE INDEX registrations_originstateid ON registrations (originstateid);
CREATE INDEX registrations_nationalityid ON registrations (nationalityid);
CREATE INDEX registrations_origincountryid ON registrations (origincountryid);
CREATE INDEX registrations_denominationid ON registrations (denominationid);
CREATE INDEX registrations_org_id ON registrations (org_id);

ALTER TABLE studentpayments ADD registrationid integer references registrations;
CREATE INDEX studentpayments_registrationid ON studentpayments (registrationid);

CREATE TABLE registryexams (
	registryexamid		serial primary key,
	examnumber			varchar(12),
	examname			varchar(50),
	internalexam		boolean not null default false,
	examdate			date,
	narrative			varchar(240)
);

CREATE TABLE registrymarks (
	registrymarkid		serial primary key,
	registryexamid		integer not null references registryexams,
	registrationid		integer not null references registrations,
	subjectid			integer not null references subjects,
	markid				integer not null references marks,
	marks				integer,
	narrative			varchar(240),
	UNIQUE (registrationid, subjectid, registryexamid)
);
CREATE INDEX registrymarks_registryexamid ON registrymarks (registryexamid);
CREATE INDEX registrymarks_registrationid ON registrymarks (registrationid);
CREATE INDEX registrymarks_markid ON registrymarks (markid);
CREATE INDEX registrymarks_subjectid ON registrymarks (subjectid);

CREATE TABLE pin_data (
	payment_id			serial primary key,
	customer_id			varchar(40) not null,
	fullname			varchar(70) null,
	receipt_no			varchar(40) not null,
	confirmation_no		varchar(70) not null,
	description			varchar(70) null,
	amount				real default 0 not null,
	bank_code			varchar(5) null,
	branch_code			varchar(5) null,
	status				char(1) null,
	unique (customer_id),
	unique (confirmation_no)
);

CREATE TABLE app_students (
	app_student_id		integer primary key,
	student_number		serial,
	studentid			varchar(12),
	departmentid		varchar(12),
	denominationid		varchar(12),
	org_id				integer references orgs,
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
	guardianname		varchar(150),
	gaddress			varchar(250),
	gzipcode			varchar(50),
	gtown				varchar(50),
	gcountrycodeid		char(2) references countrys,
	gtelno				varchar(50),
	gemail				varchar(240),

	degreeid			varchar(12) references degrees,
	sublevelid			varchar(12) references sublevels,
	
	majorid				varchar(12),
	
	account_number		varchar(50),
	e_tranzact_no		varchar(50),
	first_password		varchar(50),
	
	denomination_name	varchar(50),
	state_name			varchar(50),
	degree_name			varchar(50),
	programme_name		varchar(50),
	
	is_picked			boolean default false
);


DROP VIEW vw_entitys;
CREATE VIEW vw_entitys AS
	SELECT orgs.org_id, orgs.org_name, 
		entity_types.entity_type_id, entity_types.entity_type_name, 
		entity_types.entity_role, entity_types.group_email, entity_types.use_key,
		entitys.entity_id, entitys.entity_name, entitys.user_name, entitys.Super_User, entitys.Entity_Leader, 
		entitys.Date_Enroled, entitys.Is_Active, entitys.entity_password, entitys.first_password, 
		entitys.primary_email, entitys.function_role, entitys.selection_id, entitys.details
	FROM entitys INNER JOIN orgs ON entitys.org_id = orgs.org_id
		INNER JOIN entity_types ON entitys.entity_type_id = entity_types.entity_type_id;

CREATE VIEW applicationview AS 
	SELECT entitys.entity_id, entitys.entity_name, entitys.user_name, entitys.primary_email,
		entitys.primary_telephone, entitys.selection_id, 
		(CASE WHEN entitys.selection_id = 4 THEN 'UNDERGRADUATE' ELSE 'POSTGRADUATE' END) as selection_name,

		applications.applicationid, applications.confirmationno, applications.receiptnumber, 
		applications.purchasecentre, applications.applicationdate, applications.amount, applications.paid,
		applications.approved, applications.closed, applications.openapplication, applications.narrative,
		applications.paydate, applications.card_type, applications.success,
		applications.quarterid, applications.org_id,
		'Babcock Application Responce'::varchar AS emailsubject,
		(CASE WHEN applications.paid = true THEN 'The payment is completed and updated'
		WHEN (applications.confirmationno is null) THEN applications.narrative
		ELSE
		'<a href="payments/paymentApplicant.jsp?amount=' || applications.amount || '&confirmationno='|| applications.confirmationno
		|| '&transId=' || applications.applicationid
		|| '" target="_blank"><IMG SRC="resources/images/etranzact.jpg" WIDTH=318 HEIGHT=32 ALT=""></a>'
		END) as makepayment,

		(CASE WHEN applications.paid = false THEN 
		'<a href="payments/paymentClientApp.jsp?AMOUNT=' || applications.amount || '&TRANSACTION_ID=' || applications.applicationid
		|| '" target="_blank"><IMG SRC="resources/images/visa.jpeg" WIDTH=575 HEIGHT=29 ALT=""></a>'
		ELSE 'The payment is completed and updated' END) as makevisapayment,

		(CASE WHEN applications.paid = true THEN 'The payment is completed' ELSE 'Payment has not been done' END) as paymentStatus,

		(CASE WHEN applications.paid = false THEN applications.applicationid
		ELSE 0 END) as payeditid
	FROM entitys INNER JOIN applications ON entitys.entity_id = applications.applicationid;

CREATE VIEW vw_exam_dates AS
	SELECT exam_centers.exam_center_id, exam_centers.exam_center_name, exam_centers.is_active as center_active,
		exam_dates.exam_date_id, exam_dates.exam_date, exam_dates.is_active as date_active
	FROM exam_centers INNER JOIN exam_dates ON exam_centers.exam_center_id = exam_dates.exam_center_id;

CREATE VIEW registrationview AS
	SELECT registrations.registrationid, registrations.email, registrations.phonenumber,
		registrations.submitapplication, 
		registrations.isaccepted, registrations.isreported, registrations.isdeferred, registrations.isrejected,
		registrations.applicationdate, ca.countryname as nationality,
		registrations.sex, registrations.surname, registrations.firstname, registrations.othernames, 
		(registrations.surname || ', ' ||  registrations.firstname || ' ' || registrations.othernames) as fullname,
		registrations.existingid, registrations.firstchoiceid, registrations.secondchoiceid, registrations.offcampus,
		registrations.org_id, registrations.entry_form_id, registrations.admission_level,
		
		(CASE WHEN registrations.org_id = 0 THEN 'UNDERGRADUATE' ELSE 'POSTGRADUATE' END) as selection_name,
		(CASE WHEN registrations.af_success = '0' THEN 'The payment is completed' ELSE 'Payment has not been done' END) as paymentStatus,
		
		registrations.acceptance_fees, registrations.af_date, registrations.af_amount, registrations.af_success,
		registrations.af_payment_code, registrations.af_trans_no, registrations.af_card_type, 
		registrations.af_picked, registrations.af_picked_date, registrations.account_number,
		
		applications.applicationid, applications.exam_date_id, applications.quarterid,
		
		majorview.majorid, majorview.majorname, majorview.minlevel, majorview.maxlevel, majorview.major_title,
		majorview.departmentid, majorview.departmentname, majorview.schoolid, majorview.schoolname,
		
		firstchoice.majorname as firstchoice, secondmajor.majorname as secondchoise
	FROM registrations 
		INNER JOIN applications ON registrations.registrationid = applications.applicationid
		LEFT JOIN majorview ON registrations.majorid = majorview.majorid
		INNER JOIN majors as firstchoice ON registrations.firstchoiceid = firstchoice.majorid
		INNER JOIN majors as secondmajor ON registrations.secondchoiceid = secondmajor.majorid
		INNER JOIN countrys as ca ON registrations.nationalityid = ca.countryid;

CREATE VIEW vw_exam_registration AS
	SELECT registrations.registrationid, registrations.email, registrations.submitapplication, 
		registrations.isaccepted, registrations.isreported, registrations.isdeferred, registrations.isrejected,
		registrations.applicationdate, registrations.sex, registrations.surname, registrations.firstname, registrations.othernames, 
		registrations.org_id, registrations.entry_form_id,
		trim(registrations.surname || ', ' ||  registrations.firstname || ' ' || COALESCE(registrations.othernames)) as fullname,
		admissionstatus, gcemarks, sscemarks, othermarks, evaluationofficer, evaluationdate, reported, reporteddate,
		('<a href="http://afrihub.com/babcock/?data=' || ENCODE(CAST('10001:' || replace(trim(registrations.surname || ' ' ||  registrations.firstname || ' ' || COALESCE(registrations.othernames, '')), ':', '')
		|| ':' || registrationid || ':' || Sex || ':' || COALESCE(replace(email, ':', ''), '')  || 
		':' || replace(COALESCE(mobilenumber, phonenumber, ''), ':', '') AS bytea), 'base64') || '" target="_blank">Exam Registration</a>') as exam_registration
	FROM registrations;

CREATE VIEW registrymarkview AS
	SELECT registrationview.registrationid, registrationview.fullname, 
		registrationview.org_id, registrationview.entry_form_id,
		subjects.subjectid, subjects.subjectname, 
		marks.markid, marks.grade, registrymarks.registrymarkid, registrymarks.narrative
	FROM ((registrationview INNER JOIN registrymarks ON registrationview.registrationid = registrymarks.registrationid)
		INNER JOIN subjects ON registrymarks.subjectid = subjects.subjectid)
		INNER JOIN marks ON registrymarks.markid =  marks.markid;

CREATE VIEW vw_applicant_exam_center AS
	SELECT applications.org_id, applications.applicationid, applications.applicationdate, applications.paid,
		(registrations.firstname || ' ' || registrations.othernames || ', ' || registrations.surname) as fulname,
		registrations.email, registrations.sex, registrations.phonenumber,
		vw_exam_dates.exam_center_name, vw_exam_dates.exam_date, m1.major_title as first_choise, m2.major_title as second_choise
	FROM applications INNER JOIN registrations ON registrations.registrationid = applications.applicationid
		INNER JOIN vw_exam_dates ON vw_exam_dates.exam_date_id = applications.exam_date_id
		INNER JOIN majors as m1 ON m1.majorid=registrations.firstchoiceid
		INNER JOIN majors as m2 ON m2.majorid=registrations.secondchoiceid
	ORDER BY applications.applicationid desc;

CREATE OR REPLACE FUNCTION ins_application() RETURNS trigger AS $$
DECLARE
	reca			RECORD;
	v_org_id		INTEGER;
BEGIN	
	IF(NEW.selection_id is not null) THEN
		IF(TG_WHEN = 'BEFORE')THEN
			IF((NEW.user_name is null) OR (NEW.primary_email is null))THEN
				RAISE EXCEPTION 'You need to enter the email address';
			END IF;

			IF(NEW.user_name != NEW.primary_email)THEN
				RAISE EXCEPTION 'The email and confirmation email should match.';
			END IF;

			SELECT org_id INTO v_org_id
			FROM forms WHERE (form_id = NEW.selection_id);

			NEW.user_name := lower(trim(NEW.user_name));
			NEW.primary_email := lower(trim(NEW.user_name));

			NEW.first_password := upper(substring(md5(random()::text) from 3 for 9));
			NEW.entity_password := md5(NEW.first_password);

			NEW.org_id = v_org_id;

			RETURN NEW;
		END IF;

		IF(TG_WHEN = 'AFTER')THEN
			INSERT INTO entry_forms (org_id, entity_id, entered_by_id, form_id)
			VALUES(NEW.org_id, NEW.entity_id, NEW.entity_id, NEW.selection_id);

			INSERT INTO sys_emailed (org_id, sys_email_id, table_id, table_name)
			VALUES(NEW.org_id, 1, NEW.entity_id, 'entitys');

			SELECT quarterid, applicationfees INTO reca
			FROM quarters 
			WHERE (quarterid IN (SELECT max(quarterid) FROM quarters WHERE (org_id = NEW.org_id)));

			INSERT INTO applications (org_id, applicationid, quarterid, amount, narrative)
			VALUES(NEW.org_id, NEW.entity_id, reca.quarterid, reca.applicationfees,
				'For ETranzact PIN payment enter receipt and confirmation numbers');
		END IF;
	ELSE
		IF(TG_WHEN = 'BEFORE')THEN
			RETURN NEW;
		END IF;
	END IF;

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_bf_application BEFORE INSERT ON entitys
    FOR EACH ROW EXECUTE PROCEDURE ins_application();

CREATE TRIGGER ins_application AFTER INSERT ON entitys
    FOR EACH ROW EXECUTE PROCEDURE ins_application();

CREATE OR REPLACE FUNCTION upd_application() RETURNS trigger AS $$
DECLARE
	v_submit_application	BOOLEAN;
BEGIN	
	SELECT submitapplication INTO v_submit_application
	FROM registrations
	WHERE (registrationid = NEW.entity_id);

	IF(NEW.first_password = OLD.first_password) AND (NEW.entity_password = OLD.entity_password)THEN
		IF(v_submit_application = true) THEN
			RAISE EXCEPTION 'You cannot make changed after submission of application.';
		END IF;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER upd_application BEFORE UPDATE ON entitys
    FOR EACH ROW EXECUTE PROCEDURE upd_application();

CREATE OR REPLACE FUNCTION updApplications() RETURNS trigger AS $$
DECLARE
	myrec RECORD;
BEGIN

	IF(OLD.paid = true) AND (NEW.paid = true)THEN
		IF(OLD.confirmationno <> NEW.confirmationno)THEN
			RAISE EXCEPTION 'You cannot make changes to a paid application.';
		END IF;
	END IF;

	SELECT applications.applicationid, applications.receiptnumber, applications.confirmationno INTO myrec
	FROM applications
	WHERE (applications.applicationid <> NEW.applicationid) 
		AND ((receiptnumber = NEW.receiptnumber) OR (confirmationno = NEW.confirmationno));
	
	IF(myrec.applicationid is not null) THEN
		NEW.receiptnumber = null;
		NEW.confirmationno = null;
		NEW.narrative = 'The receipt number or confirmation number you have used have been used before';
	ELSE
		NEW.narrative = 'Click on the PIN Payment icon bellow to proceed';
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER updApplications BEFORE UPDATE ON applications
    FOR EACH ROW EXECUTE PROCEDURE updApplications();

CREATE OR REPLACE FUNCTION ins_registrations() RETURNS trigger AS $$
DECLARE
	v_org_id			INTEGER;	
	v_entity_id			INTEGER;
BEGIN
	
	SELECT org_id, entity_id INTO v_org_id, v_entity_id
	FROM entry_forms
	WHERE (entry_form_id = NEW.entry_form_id);
	
	NEW.registrationid := v_entity_id;
	NEW.org_id := v_org_id;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_registrations BEFORE INSERT ON registrations
    FOR EACH ROW EXECUTE PROCEDURE ins_registrations();

CREATE OR REPLACE FUNCTION select_exam_date(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar AS $$
DECLARE
	v_app_id			int;
	v_exam_id			int;
	v_capacity			int;
	v_count				int;
	v_paid 				boolean;
	msg					varchar;
BEGIN
	v_app_id := CAST($2 AS int);
	v_exam_id := CAST($1 AS int);
	
	SELECT exam_centers.center_capacity INTO v_capacity
	FROM exam_centers INNER JOIN exam_dates ON exam_centers.exam_center_id = exam_dates.exam_center_id
	WHERE (exam_dates.exam_date_id = v_exam_id);
	
	SELECT count(applicationid) INTO v_count
	FROM applications
	WHERE (paid = true) AND (exam_date_id = v_exam_id);
	
	SELECT paid INTO v_paid
	FROM applications
	WHERE (applicationid = v_app_id);

	IF(v_exam_id is null) THEN
		msg:= 'Not Updated';
		RAISE EXCEPTION 'The exam center for this date is full select another one.';
	ELSIF(v_count >= v_capacity) THEN
		msg:= 'Not Updated';
		RAISE EXCEPTION 'The exam center for this date is full select another one.';
	ELSIF(v_paid = false) THEN
		msg:= 'You need to pay before selecting the exam center';
		RAISE EXCEPTION 'You need to pay before selecting the exam center';
	ELSE
		UPDATE applications SET exam_date_id = v_exam_id
		WHERE applicationid = v_app_id;
		msg:= 'Updated'|| ' Application ID ' || v_app_id || ' exam center and date ID ' || v_exam_id;
	END IF;

	RETURN msg;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION submitapplication(varchar(12), varchar(12), varchar(12)) RETURNS VARCHAR(120) AS $$
DECLARE
	myrec				RECORD;
	v_approve_status	VARCHAR(16);
	mystr 				VARCHAR(120);
BEGIN
	SELECT applications.applicationid, applications.exam_date_id, applications.paid, 
		entitys.entity_id, entitys.picture_file,
		registrations.registrationid, registrations.firstchoiceid, registrations.secondchoiceid,
		registrations.denominationid, age(registrations.birthdate) as app_age
	INTO myrec
	FROM applications INNER JOIN registrations ON applications.applicationid = registrations.registrationid
		INNER JOIN entitys ON applications.applicationid = entitys.entity_id
	WHERE (applications.applicationid = CAST($1 as integer));

	SELECT approve_status INTO v_approve_status
	FROM entry_forms
	WHERE (entity_id = myrec.entity_id);

	IF (myrec.picture_file is null) THEN
		mystr := 'You must upload your photo before submission';
	ELSIF (myrec.paid = false) THEN
		mystr := 'You must first make full payment before submiting the application.';
	ELSIF (myrec.exam_date_id is null) THEN
		mystr := 'Select exam center date';
	ELSIF (myrec.app_age < '14 years'::interval) THEN
		mystr := 'You need to be older than 16 years to apply for this programme';
	ELSIF (myrec.firstchoiceid is null) THEN
		mystr := 'Select First Programme Choice';
	ELSIF (myrec.secondchoiceid is null) THEN
		mystr := 'Select Second Programme Choice';
	ELSIF (myrec.denominationid is null) THEN
		mystr := 'Select Denomination';
	ELSIF (v_approve_status = 'Draft') THEN
		mystr := 'You need the form submited first';
	ELSE
		UPDATE applications SET openapplication = false
		WHERE (applicationid = myrec.applicationid);

		UPDATE registrations SET submitapplication = true, submitdate = now(), majorid = firstchoiceid
		WHERE (registrationid = myrec.applicationid);

		mystr := 'Submitted the application.';
	END IF;

	RETURN mystr;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION manage_application(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS VARCHAR(120) AS $$
DECLARE
	v_registration_id		integer;
	v_org_id				integer;
	v_studentpaymentid		integer;
	myrec					RECORD;
	msg 					varchar(120);
BEGIN
	v_registration_id := CAST($1 as integer);

	SELECT org_id INTO v_org_id
	FROM registrations WHERE (registrationid = v_registration_id);

	IF ($3 = '1') THEN
		SELECT quarterid, acceptance_fee INTO myrec
		FROM quarters 
		WHERE quarterid IN (SELECT max(quarterid) FROM quarters);

		UPDATE registrations SET isaccepted = true, evaluationdate = current_date,
			acceptance_fees = myrec.acceptance_fee
		WHERE (registrationid = v_registration_id) AND (isaccepted = false);

		INSERT INTO sys_emailed (org_id, sys_email_id, table_id, table_name)
		VALUES(v_org_id, 4, v_registration_id, 'entitys');

		msg := 'Application Accepted';
	ELSIF ($3 = '2') THEN
		UPDATE registrations SET isrejected = true, evaluationdate = current_date
		WHERE (registrationid = v_registration_id);

		INSERT INTO sys_emailed (org_id, sys_email_id, table_id, table_name)
		VALUES(v_org_id, 5, v_registration_id, 'entitys');

		msg := 'Application rejected';
	ELSIF ($3 = '3') THEN
		UPDATE entry_forms SET approve_status = 'Draft'
		WHERE (entity_id = v_registration_id);

		UPDATE applications SET openapplication = true
		WHERE (applicationid = v_registration_id);

		DELETE FROM registrations WHERE (registrationid = v_registration_id);

		INSERT INTO sys_emailed (org_id, sys_email_id, table_id, table_name)
		VALUES(v_org_id, 6, v_registration_id, 'entitys');

		msg := 'Application opened for corrections';
	ELSIF ($3 = '4') THEN
		UPDATE registrations SET isreported = true
		WHERE (registrationid = v_registration_id);

		msg := 'Applicant reported';
	ELSIF ($3 = '5') THEN
		UPDATE registrations SET isdeferred = true
		WHERE (registrationid = v_registration_id);

		msg := 'Applicant deferred';
	END IF;

	RETURN msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION pick_appfees(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	msg				varchar(120);
BEGIN
	UPDATE registrations SET af_picked = true, af_picked_date = now()
	WHERE registrations.registrationid = CAST($1 as int);

	msg := 'Picked';

    RETURN msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION admit_applicant(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	myrec 			RECORD;
	reca			RECORD;
	newid 			varchar(12);
	fullname 		varchar(100);
	pemail			varchar(120);
	emailcount		bigint;
	genfirstpass 	varchar(32);
	genstudentpass 	varchar(32);
	v_degree_id		integer;
	msg				varchar(120);
BEGIN
	SELECT departments.departmentid, departments.org_id, majors.majorid,
		registrations.denominationid, registrations.registrationid,
		registrations.surname, registrations.firstname, registrations.othernames,
		registrations.nationalityid, registrations.birthdate, registrations.existingid, registrations.firstchoiceid,
		registrations.address, registrations.zipcode, registrations.town, registrations.origincountryid,
		registrations.phonenumber, registrations.email, registrations.account_number, registrations.e_tranzact_no,
		registrations.birthstateid,
		substring(registrations.sex from 1 for 1) as sex, substring(registrations.maritalstatus from 1 for 1) as maritalstatus,
		entitys.picture_file
		INTO myrec
	FROM (departments INNER JOIN majors ON departments.departmentid = majors.departmentid)
		INNER JOIN registrations ON majors.majorid = registrations.majorid
		INNER JOIN entitys ON registrations.registrationid = entitys.entity_id
	WHERE (registrations.registrationid = CAST($1 as integer));

	SELECT quarterid, new_student_code, new_student_index INTO reca
	FROM quarters 
	WHERE quarterid IN (SELECT max(quarterid) FROM quarters);
	
	IF myrec.majorid IS NULL THEN
		msg := 'No programme selected.';
	ELSIF myrec.existingid IS NULL THEN
		IF (myrec.othernames IS NULL) THEN
			fullname := upper(trim(myrec.surname)) || ', ' || upper(trim(myrec.firstname));
		ELSE
			fullname := upper(trim(myrec.surname)) || ', ' || upper(trim(myrec.firstname)) || ' ' || upper(trim(myrec.othernames));
		END IF;		

		pemail := lower(trim(myrec.surname)) || '.' || lower(trim(myrec.firstname));
		SELECT count(entity_id) + 1 INTO emailcount
		FROM entitys 
		WHERE primary_email ilike pemail || '%';

		pemail :=  pemail || lpad(CAST(emailcount as varchar), 2, '0') || '@std.babcock.edu.ng';

		genfirstpass := upper(substring(md5(random()::text) from 3 for 10));
		genstudentpass := md5(genfirstpass);

		newid := reca.new_student_code || '/' || lpad(CAST(reca.new_student_index as varchar), 4, '0');
		UPDATE quarters SET new_student_index = new_student_index + 1 WHERE (quarterid = reca.quarterid);

		INSERT INTO students (org_id, studentid, studentname, surname, firstname, othernames,
			departmentid, denominationid, sex, 
			MaritalStatus, birthdate, address, zipcode, town, telno, email,
			nationality, countrycodeid, gcountrycodeid, picturefile,
			accountnumber, Etranzact_card_no, stateid)
		VALUES (myrec.org_id, newid, fullname, myrec.surname, myrec.firstname, myrec.othernames,
			myrec.departmentid, myrec.denominationid, myrec.sex, 
			myrec.MaritalStatus, myrec.birthdate, 
			myrec.address, myrec.zipcode, myrec.town, myrec.phonenumber, myrec.email,
			myrec.nationalityid, myrec.nationalityid, myrec.nationalityid, myrec.picture_file,
			myrec.account_number, myrec.e_tranzact_no, myrec.birthstateid);

		INSERT INTO sys_emailed (org_id, sys_email_id, table_id, table_name)
		VALUES(myrec.org_id, 7, myrec.registrationid, 'registrations');

		INSERT INTO studentdegrees (org_id, degreeid, sublevelid, studentid, started, bulletingid)
		VALUES (myrec.org_id, 'B.A',  'UNDM', newid, current_date, 0);

		v_degree_id = currval('studentdegrees_studentdegreeid_seq');

		INSERT INTO studentmajors (org_id, studentdegreeid, majorid, major, nondegree, premajor, primarymajor)
		VALUES (myrec.org_id, v_degree_id, myrec.majorid, true, false, false, true);

		UPDATE registrations SET existingid = newid
		WHERE (registrations.registrationid = myrec.registrationid);

		msg := fullname || ' matric number : ' || newid || ' password : ' || genfirstpass;
	ELSE
		msg := myrec.existingid;
	END IF;

    RETURN msg;
END;
$$ LANGUAGE plpgsql;



