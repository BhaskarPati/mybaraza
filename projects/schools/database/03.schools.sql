---Project Database File

CREATE TABLE stream_classes (
	stream_class_id					serial primary key,
	org_id						integer references orgs,
	class_level					integer,
	stream						varchar(60),
	narrative					varchar(320),
	details						text
);
CREATE INDEX stream_classes_org_id ON stream_classes (org_id);

CREATE TABLE students (
	student_id					serial primary key,
	entity_id					integer references entitys,
	org_id						integer references orgs,
	stream_class_id 			integer references stream_classes,
	
	student_name				varchar(50) not null,
	Sex							varchar(1),
	nationality					varchar(2) not null references sys_countrys,
	birth_date					date not null,
	address						varchar(50),
	zipcode						varchar(50),
	town						varchar(50),
	country_code_id				char(2) not null references sys_countrys,
	telno						varchar(50),
	email						varchar(240),
	details						varchar (360) ,
	date_enroled 				timestamp without time zone
	
);

CREATE INDEX students_org_id ON students (org_id);
CREATE INDEX students_entity_id ON students (entity_id);
CREATE INDEX students_class_id ON students (stream_class_id);
CREATE INDEX students_nationality ON students (nationality);
CREATE INDEX students_country_code_id ON students (country_code_id);



CREATE TABLE guardians (
	guardian_id					serial primary key,
	org_id 						integer references orgs,
	fathers_name				varchar(320),
	fathers_tel_no				varchar(50),
	fathers_email				varchar(240),

	mothers_name				varchar(320),
	mothers_tel_no				varchar(50),
	mothers_email				varchar(240),

	table_name 					varchar(24),
	guardian_name				varchar(50),
	g_address					varchar(50),
	g_zipcode					varchar(50),
	g_town						varchar(50),
	sys_country_id				char(2) not null references sys_countrys,
	student_id					integer references students,
	g_telno						varchar(50),
	g_email						varchar(240),
	
	current_contact				text,
	registrar_details			text,
	details						text
); 
CREATE INDEX guardians_student_id on guardians(guardian_id);
CREATE INDEX guardians_org_id ON guardians (org_id);
CREATE INDEX guardians_sys_country_id ON guardians (sys_country_id);

CREATE TABLE staff (
	staff_id					serial primary key,
	entity_id					integer references entitys,
	org_id						integer references orgs,
	staff_role					varchar (60),
		
	full_name					varchar (120),
	surname 					varchar(50) NOT NULL,
	first_name 					varchar(50) NOT NULL,
  	middle_name 				varchar(50),
  	date_of_birth 				date,
  	gender 						character varying(1),
 	phone						character varying(120),
  	primary_email				character varying(120),
  	
  	place_of_birth				character varying(50),
  	marital_status 				character varying(2),
  	appointment_date 			timestamp default now(),
 
  	exit_date 					date,
  	picture_file 				varchar(32),
  	active 						boolean NOT NULL DEFAULT true,
  	language 					character varying(320),
	interests 					text,
	narrative					text
);
CREATE INDEX staff_org_id ON staff (org_id);
CREATE INDEX staff_entity_id ON staff (entity_id);


CREATE TABLE subjects (
	subject_id 					serial primary key,
	org_id						integer references orgs,
	staff_id 					integer references staff,
	subject_name				varchar (120),
	subject_year				date not null default now(),
	
	details						text
);
CREATE INDEX subjects_org_id ON subjects (org_id);
CREATE INDEX subjects_staff_id ON subjects (staff_id);



CREATE TABLE grades (
	grade_id 					varchar(2) primary key,
	org_id						integer references orgs,
	grade_range					real,
	details						text
);
CREATE INDEX grades_org_id ON grades (org_id);

--



CREATE TABLE sessions (
	session_id					serial primary key,
	org_id						integer references orgs,
	session_name				varchar(32),
	session_start_date			date,
	session_end_date			date,
	details						text
);

CREATE INDEX session_org_id ON sessions(org_id);

CREATE TABLE students_session (
	student_session_id			serial primary key,
	org_id 						integer references orgs,
	session_id					integer	references sessions,
	student_id					integer references students,
	details						text
);
CREATE INDEX students_session_org_id ON students_session(org_id);
CREATE INDEX students_session_student_id ON students_session(student_id);



CREATE TABLE exams (
	exam_id							serial primary key,
	session_id					integer references sessions,
	subject_id					integer references subjects,
	class_level					integer references stream_classes,				
	org_id							integer references orgs,
	staff_id 					integer references staff,
	exam_name						varchar(50),
	exam_date						date,
	start_time						time without time zone NOT NULL,
	end_time						time without time zone NOT NULL,
	exam_file						varchar(32),
	exam_narrative					text
);
CREATE INDEX exams_org_id on exams(org_id);
CREATE INDEX exams_session_id on exams(session_id);
CREATE INDEX exams_subject_id on exams(subject_id);
CREATE INDEX exams_class_level on exams(class_level);
CREATE INDEX exams_staff_id on exams(staff_id);


CREATE TABLE timetable (
	timetable_id				serial primary key,
	stream_class_id					integer references stream_classes,
	session_id					integer references sessions,
	subject_id					integer references subjects,
	staff_id					integer references staff,	
	org_id						integer references orgs,
	monday						boolean not null default false,
	tuesday						boolean not null default false,
	wednesday					boolean not null default false,
	thursday					boolean not null default false,
	friday						boolean not null default false,
	saturday					boolean not null default false,
	start_time					time,
	end_time					time,
	narrative					text
);
CREATE INDEX timetable_stream_class_id ON timetable(stream_class_id);
CREATE INDEX timetable_org_id ON timetable(org_id);
CREATE INDEX timetable_session_id ON timetable(session_id);
CREATE INDEX timetable_subject_id ON timetable(subject_id);
CREATE INDEX timetable_staff_id ON timetable(staff_id);

--NEW TABLES
CREATE TABLE exams_subjects(
	exams_subjects_id				serial primary key,
	exam_id						integer references exams,
	org_id						integer references orgs,
	subject_id					integer references subjects,
	exam_file					varchar(32),
	exam_description			varchar(320),
	narrative					text
);
CREATE INDEX exams_subjects_exam_id ON exams_subjects(exam_id);
CREATE INDEX exams_subjects_org_id ON exams_subjects(org_id);
CREATE INDEX exams_subjects_subject_id ON exams_subjects(subject_id);

CREATE TABLE fees_structure(
	fees_structure_id			serial primary key,
	session_id					integer references sessions,
	stream_class_id				integer references stream_classes,
	org_id						integer references orgs,
	fees_amount					real,
	additional_amounts			real,
	description					varchar(320)
);
CREATE INDEX fees_structure_session_id ON fees_structure(session_id);
CREATE INDEX fees_structure_org_id ON fees_structure(org_id);
CREATE INDEX fees_structure_stream_class_id ON fees_structure(stream_class_id);

CREATE TABLE students_fees(
	student_fee_id				serial primary key,
	student_id					integer references students,
	fees_structure_id			integer  references fees_structure,
	fees_charged				real,
	fees_paid					real,
	paid_date					date,
	fees_balance				real,
	cleared						boolean default false,
	description					text
);
CREATE INDEX student_fees_student_id ON students_fees(student_id);
CREATE INDEX student_fees_fees_structure_id ON students_fees(fees_structure_id);


CREATE TABLE applicant(
	student_id					integer references students primary key,
	org_id						integer not null references orgs,

	stream_class_id 			integer references stream_classes,
	applicant_name				varchar (320),
	applicant_DOB				date,
	applicants_address			varchar(120),
	gender						boolean default 'true',
	
	country_code_id				char(2) not null references sys_countrys,
	telno						varchar(50),
	email						varchar(240),
	
	approve_status				varchar(16) default 'Draft' not null,
	workflow_table_id			integer,
	action_date					timestamp,
	details 					text
	
);

CREATE INDEX applicant_org_id on applicant(org_id);
CREATE INDEX applicant_student_id on applicant(student_id);
CREATE INDEX applicant_stream_class_id ON applicant (stream_class_id);



CREATE TABLE school_events(
	school_event_id 	serial primary key,
	org_id 				integer,
	school_event_name 		character varying(50) NOT NULL,
	start_date 			date,
	start_time 			time,
	end_date 			date,
	end_time			time,
	details 			text
);
CREATE INDEX school_events_org_id ON school_events (org_id);




	CREATE OR REPLACE FUNCTION ins_students() RETURNS TRIGGER AS
$BODY$
DECLARE
	rec 			RECORD;
	v_entity_id		integer;
DECLARE
BEGIN
	IF (TG_OP = 'INSERT') THEN
	
		IF (New.student_name is null)THEN
			RAISE EXCEPTION 'You have to enter your full name';
			ELSEIF (NEW.email is null) THEN
			RAISE EXCEPTION 'Fill your current email';
			ELSEIF ( date_part('year', NEW.birth_date) < 1991 )THEN
			RAISE EXCEPTION 'You are too old for school';
		END IF;
			
		NEW.entity_id := nextval('entitys_entity_id_seq');
		NEW.student_id := nextval('students_student_id_seq');
		
		INSERT INTO entitys(entity_id,entity_name,org_id,entity_type_id,user_name,primary_email,function_role,details, use_key_id)
			VALUES (New.entity_id,New.student_name,New.org_id::INTEGER,0,NEW.email,NEW.email,'student',NEW.details,0) RETURNING entity_id INTO v_entity_id;
			NEW.entity_id := v_entity_id;
	END IF;
	RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql;
  
CREATE TRIGGER ins_students BEFORE INSERT OR UPDATE ON students
  FOR EACH ROW  EXECUTE PROCEDURE ins_students();	
	

CREATE OR REPLACE FUNCTION ins_staff() RETURNS TRIGGER AS
$BODY$
DECLARE
	rec 			RECORD;
	v_entity_id		integer;
DECLARE
BEGIN
	IF (TG_OP = 'INSERT') THEN

			IF(v_entity_id is null)THEN
				NEW.entity_id := nextval('entitys_entity_id_seq');
				IF(NEW.staff_id is null) THEN NEW.staff_id := NEW.entity_id;
				END IF;		
				NEW.full_name = (NEW.surname || ' ' || NEW.first_name || ' ' || COALESCE(NEW.middle_name, ''));
				INSERT INTO entitys (entity_id, org_id,  entity_type_id, entity_name, User_name, primary_email,  function_role, first_password, use_key_id)
				VALUES (NEW.entity_id, New.org_id, 0, NEW.full_name, lower(trim(NEW.primary_email)), NEW.primary_email, NEW.staff_role, null,0);
			ELSE
				RAISE EXCEPTION 'You already have an account, login and continue';
			END IF;
	END IF;
	IF (TG_OP = 'UPDATE')	THEN 
		INSERT INTO employees_details(staff_id, org_id,entity_id ,designation, surname,first_name, middle_name, date_of_birth,  gender, phone)
				VALUES (NEW.staff_id, NEW.org_id,NEW.entity_id, NEW.staff_role, NEW.surname,NEW.first_name, NEW.middle_name, NEW.date_of_birth, NEW.gender, NEW.phone) ;
	END IF;				
	RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql;
 
CREATE TRIGGER ins_staff BEFORE INSERT OR UPDATE ON staff
  FOR EACH ROW  EXECUTE PROCEDURE ins_staff();	

  

	
	

CREATE OR REPLACE FUNCTION ins_applicants()
  RETURNS trigger AS
$BODY$
DECLARE
    rec             RECORD;
    v_entity_id     integer;
    v_exist         integer;
BEGIN

  IF (TG_OP = 'INSERT') then 
		NEW.student_id := nextval('students_student_id_seq');
        Select count(applicant_email) INTO v_exist from applicants where applicant_email = NEW.applicant_email;
        IF(v_exist != 0) THEN
            Raise exception 'email exists';
        END IF;
       
      
  END IF;
   
  IF (TG_OP = 'UPDATE' AND NEW.approve_status = 'Approved') THEN
         
            INSERT INTO students( student_id,org_id, entity_id,student_name , stream_class_id, birth_date, address,
            sex, country_code_id,telno, email, joined_date,details) 
            
            VALUES( New.student_id, New.org_id,0,NEW.applicant_name,NEW.stream_class_id, NEW.applicant_dob, NEW.applicants_address, 
            NEW.gender, NEW.country_code_id, NEW.telno, NEW.email, now()::date, details);
				
		
        INSERT INTO sys_emailed (sys_email_id, table_id,org_id, table_name)
        VALUES (1,NEW.entity_id,NEW.org_id, 'applicant');
        
  END IF;  
  RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql;

CREATE TRIGGER ins_applicants BEFORE INSERT OR UPDATE ON applicants
  FOR EACH ROW  EXECUTE PROCEDURE ins_applicants();

	
	
	
	
--inserts

INSERT INTO entitys (entity_id, org_id, entity_type_id, use_key_id, user_name, entity_name, primary_email, entity_leader, super_user, no_org, first_password,function_role)
VALUES (2, 0, 0, 0, 'admin', 'admin', 'admin@admin.com', true, false, false, 'baraza','admin');
SELECT pg_catalog.setval('entitys_entity_id_seq', 2, true);
