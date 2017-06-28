
 
CREATE TABLE class (
	
	class_id		serial primary key,
	class_name    varchar(20),
	capacity      integer,
	details		text
);
	
CREATE TABLE streams (
	
	steam_id		serial primary key,
	stream_name	varchar(30),
	details		text
);

CREATE TABLE religions(
	
	religion_id			serial primary key,
	religion_name			varchar(20);
	details				text
	
	
);

CREATE TABLE students(
	
	entity_id	   		 	serial primary key,
	org_id					integer references orgs,
	surname					varchar(50),
	middle_name				varchar(50),
	first_name				varchar(50),
	adm_no					varchar(20),
	gender					char(1),
	dob						date,
	age 					integer,
	entry_grade				integer,
	exit_date				date,
	dormitory_id		    integer references dormitorys,
	adm_date				date,	
	telephone				varchar(50),
	email 					varchar(50),
	class_id				integer references class,
	religion_id				integer references religions,
	address_id				integer references address
	
	
);
		
		
		
		
CREATE TABLE kin_types(
	
	kin_type_id					serial primary key,
	kin_name					varchar(30),
	details						text
	
);
		
		
		
CREATE TABLE guardians(
	
	entity_id	    serial primary key,
	org_id			integer references orgs,
	surname			varchar(50),
	middle_name		varchar(50),
	entity_name		varchar(50),
	student_id		integer references students,
	relationship    integer references kin_types,
	gender			varchar(20),
	dob				date,
	age 			integer,	
	telephone		varchar(50),
	email 			varchar(50),
	post_office_box	varchar(50),
	postal_code		varchar(50),
	town			varchar(30),
	premises		varchar(30),
	street			varchar(30)
	
);
		
CREATE TABLE teachers(
		
	teacher_id 		serial primary key,
	org_id			integer default 0,
	title			varchar(20),
	surname			varchar(20),
	firstname 		varchar(50),
	middlename		varchar(50)		
		
);
		
		
		
CREATE TABLE applicants(
		
	applicant_id		serial primary key,
	surname			varchar(30),
	middle_name		varchar(30),
	first_name			varchar(30),
	dob				date,
	gender				varchar(30),
	telephone		varchar(50),
	email 			varchar(50),
	post_office_box	varchar(50),
	postal_code		varchar(50),
	town			varchar(30),
	premises		varchar(30),
	street			varchar(30)
		
		
);
		
		
CREATE TABLE displinarys(

	displinary_id			serial primary key
	displinary_name		varchar(50),
	details				text
	
);
		
	
	
CREATE TABLE disciplined_students(
	
	disciplined_student_id		serial primary key,
	entity_id						integer references students,
	displinary_id					integer references displinarys,
	details						text
	
);


CREATE TABLE achievements(

	achievement_id		serial primary key,
	achievement_name	varchar(50),
	details				text
	

);

CREATE TABLE scholarships(

	scholarship_id			serial primary key,
	scholarship_name		varchar(50),
	details					text
);

CREATE TABLE scholarships_student(

	scholarship_student_id			serial primary key,
	scholarship_id 					integer references scholarships,
	entity_id						integer references students,
	start_date						date,
	end_date						date

);

CREATE TABLE seminars(

	seminar_id		serial primary key,
	seminar_name		varchar(50),
	
	details			text
);

CREATE TABLE students_seminars(

	students_seminar_id			serial primary key,
	seminar_id					integer references seminars,
	entity_id 					integer references entitys,
	from_date					date,
	to_date 					date

);

CREATE TABLE clubs(

	club_id			serial primary key,
	club_name			varchar(50),
	details			text
);


CREATE TABLE dormitorys(

	dormitory_id		serial primary key,
	dormitory_name		varchar(50),
	capacity			integer,
	matron				varchar(30),
	cubicles			integer,
	cubicle_capacity	integer,
	sex					char(10),
	details				text
);



CREATE TABLE dormitory_students(

	dormitory_student_id		serial primary key,
	dormitory_id				integer references dormitorys,
	entity_id					integer references students,

);




CREATE TABLE prefects(

	prefect_id			serial primary key,
	prefect_name		varchar(50),
	details				text
);

CREATE TABLE students_club(

	students_club_id		serial primary key,
	entity_id				integer references students,
	club_id					integer references clubs,
	position				varchar(50),

);



CREATE TABLE subjects(
	subject_id			serial primary key,
	subject_name			varchar(50),
	teacher_id			integer references teachers,
	details				text

);

CREATE TABLE absents(

	absent_id		serial primary key,
	absent_name		varchar(50),
	from_date		date,
	to_date			date,
	details			text
);


CREATE TABLE exams(
	exam_id			serial primary key,
	exam_name		varchar(50),
	exam_type		varchar(50),
	details			text
);

CREATE TABLE trimester (
	trimester_id		    varchar(50) primary key not null,
	start_date				date,
	end_date				date,

	active					boolean default true not null,
	closed					boolean default false not null,
	details					text
);


CREATE TABLE trimester_student(

	trimester_student_id	serial primary key,
	trimester_id			varchar(20) references trimester,
	entity_id				integer references students
	
);


CREATE TABLE term_student_exams (
	term_student_exam			serial primary key,
	term_student_id				integer references term_students,
	exam_id						integer references exams,
	start_date					date,
	end_date					date



);


CREATE TABLE term_teachers(

	term_teacher_id			serial primary key,
	term_id					integer references terms,
	entity_id				integer references entitys,
	details					text
);

CREATE TABLE term_teachers_subjects(

	term_teachers_subject_id		serial primary key,
	term_teacher_id					integer references term_teachers,
	subject_id						integer references subjects,
	class_id						integer references class
);




CREATE TABLE prefect_students(
	prefect_student_id		serial primary key,
	class_id				integer references class,
	entity_id				integer references students,
	prefect_id				integer references prefects
	
);
	
CREATE TABLE student_previous_schools (
	student_previous_schools_id		serial primary key,
	entity_id						integer references students,
	school_name						varchar(50),
	start_date						date,
	end_date						date,
	details							text
	
	
);
	
CREATE TABLE roles(
	role_id 					serial primary key,
	role_name     				varchar(50),
	details						text
);
	
	
CREATE TABLE weekdays (
	
	weekday_id					serial primary key,
	weekday_name				varchar(30),
);
	
	
	
CREATE TABLE teacher_roles (
	
	teacher_role_id				serial primary key,
	teacher_id					integer references teachers,
	role_id						integer references roles,
	details						text
	
);
	
	
CREATE TABLE timetable (
	
	timetable_id				serial primary key,
	class_id					integer references class,
	trimester_id				varchar(50) references trimester,
	subject_id					integer references subjects,
	exam_date					date,
	weekday_id 					integer references weekdays,
	start_time					time,
	end_time					time
	
);
	
	
	
CREATE TABLE class_exam (
	
	class_exam_id				serial primary key,
	class_id					integer references class,
	exam_id						integer references exams,
	org_id						integer references orgs,
	start_date					date,
	end_date					date,
	details						text
);
	
	
CREATE TABLE student_exam (
	
	student_exam_id			    serial primary key,
	entity_id					integer references students,
	org_id						integer references orgs,
	exam_id						integer references exams,
	subject_id					integer references subjects,
	cat1						integer,
	cat2						integer,
	main_exam					integer,
	grade                       varchar(20)
	
	
);
	
	
CREATE TABLE grades (
	
	grade_id				serial primary key,
	grade_name				varchar(10),
	grade_weight			float,
	min_range			    integer,
	max_range				integer
	
	
);
	
	
CREATE VIEW vw_students AS
SELECT class.class_id, class.class_name, dormitorys.dormitory_id, dormitorys.dormitory_name, orgs.org_id, orgs.org_name, religions.religion_id, religions.religion_name, students.entity_id, students.surname, students.middle_name, students.first_name, students.adm_no, students.gender, students.dob, students.age, students.adm_date, students.telephone, students.email, students.entry_grade, students.exit_date, students.pri_school
FROM students
INNER JOIN class ON students.class_id = class.class_id
INNER JOIN dormitorys ON students.dormitory_id = dormitorys.dormitory_id
INNER JOIN orgs ON students.org_id = orgs.org_id
INNER JOIN religions ON students.religion_id = religions.religion_id;


CREATE VIEW vw_students_club AS
SELECT clubs.club_id, clubs.club_name,clubs.details ,students_club.students_club_id, students_club.entity_id, students_club.position
FROM students_club
INNER JOIN clubs ON students_club.club_id = clubs.club_id;


CREATE VIEW vw_student_guardians AS
SELECT  student_guardians.student_guardian_id, student_guardians.details, student_guardians.student_id,student_guardians.relationship, guardians.surname,guardians.entity_name,
guardians.telephone
FROM student_guardians
INNER JOIN students ON student_guardians.student_id = students.entity_id
INNER JOIN guardians ON student_guardians.entity_id= guardians.entity_id;


CREATE VIEW vw_guardians AS
SELECT address.address_id, address.address_name, orgs.org_id, orgs.org_name, guardians.entity_id, guardians.surname, guardians.middle_name, guardians.entity_name, guardians.gender, guardians.dob, guardians.age, guardians.telephone
FROM guardians
INNER JOIN address ON guardians.address_id = address.address_id
INNER JOIN orgs ON guardians.org_id = orgs.org_id;




CREATE VIEW vw_scholarships_student AS
SELECT scholarships.scholarship_id, scholarships.scholarship_name,students.entity_id, students.surname, scholarships_student.scholarship_student_id, scholarships_student.start_date, scholarships_student.end_date
FROM scholarships_student
INNER JOIN scholarships ON scholarships_student.scholarship_id = scholarships.scholarship_id
INNER JOIN students ON scholarships_student.entity_id = students.entity_id;


CREATE VIEW vw_prefect_students AS
SELECT  prefects.prefect_id, prefects.prefect_name, vw_students.entity_id, vw_students.surname,vw_students.class_name, prefect_students.prefect_student_id
FROM prefect_students
INNER JOIN prefects ON prefect_students.prefect_id = prefects.prefect_id
INNER JOIN vw_students ON prefect_students.entity_id = vw_students.entity_id;


CREATE VIEW vw_students AS
SELECT  class.class_id, class.class_name, dormitorys.dormitory_id, dormitorys.dormitory_name,  students.entity_id, students.surname, students.middle_name, students.first_name, students.adm_no, students.gender, students.dob, students.age, students.adm_date, students.telephone, students.email, students.entry_grade, students.exit_date, students.pri_school
FROM students
INNER JOIN class ON students.class_id = class.class_id
INNER JOIN dormitorys ON students.dormitory_id = dormitorys.dormitory_id


CREATE VIEW vw_trimester_student AS
SELECT students.entity_id, students.surname, trimester.trimester_id,trimester.start_date,trimester.end_date, trimester_student.trimester_student_id
FROM trimester_student
INNER JOIN students ON trimester_student.entity_id = students.entity_id
INNER JOIN trimester ON trimester_student.trimester_id = trimester.trimester_id;



CREATE VIEW vw_disciplined_students AS
SELECT displinarys.displinary_id, displinarys.displinary_name, students.entity_id, students.surname, disciplined_students.disciplined_student_id, disciplined_students.details
FROM disciplined_students
INNER JOIN displinarys ON disciplined_students.displinary_id = displinarys.displinary_id
INNER JOIN students ON disciplined_students.entity_id = students.entity_id;





CREATE VIEW vw_dormitory_students AS
SELECT dormitorys.dormitory_id, dormitorys.dormitory_name,dormitorys.capacity,dormitorys.remaining, students.entity_id, students.surname, dormitory_students.dormitory_student_id
FROM dormitory_students
INNER JOIN dormitorys ON dormitory_students.dormitory_id = dormitorys.dormitory_id
INNER JOIN students ON dormitory_students.entity_id = students.entity_id;



CREATE OR REPLACE VIEW vw_timetable AS
SELECT class.class_id, class.class_name,trimester.trimester_id, subjects.subject_id,weekdays.weekday_id,weekdays.weekday_name,
subjects.subject_name,timetable.timetable_id, timetable.start_time, timetable.end_time,timetable.exam_date
FROM timetable
INNER JOIN trimester ON timetable.trimester_id=trimester.trimester_id
INNER JOIN class ON timetable.class_id = class.class_id
INNER JOIN weekdays ON weekdays.weekday_id=timetable.weekday_id
INNER JOIN subjects ON timetable.subject_id = subjects.subject_id;



CREATE VIEW vw_student_grading AS
SELECT exams.exam_id, exams.exam_name, students.entity_id, subjects.subject_id, subjects.subject_name, student_grading.student_grading_id, student_grading.marks, student_grading.grade
FROM student_grading
INNER JOIN exams ON student_grading.exam_id = exams.exam_id
INNER JOIN students ON student_grading.entity_id = students.entity_id
INNER JOIN subjects ON student_grading.subject_id = subjects.subject_id;


CREATE VIEW vw_student_grading AS
SELECT exams.exam_id, exams.exam_name,vw_students.entity_id, vw_students.surname,vw_students.middle_name,vw_students.first_name, 
subjects.subject_id,vw_students.dormitory_name, subjects.subject_name, student_grading.student_grading_id, student_grading.marks, student_grading.grade
FROM student_grading
INNER JOIN exams ON student_grading.exam_id = exams.exam_id
INNER JOIN vw_students ON student_grading.entity_id = vw_students.entity_id
INNER JOIN subjects ON student_grading.subject_id = subjects.subject_id;

CREATE VIEW vw_student_exam AS
SELECT vw_students.entity_id, vw_students.surname,vw_students.middle_name,vw_students.first_name,vw_students.class_name,vw_students.adm_no,
subjects.subject_id, subjects.subject_name,exams.exam_name, 
student_exam.student_exam_id, student_exam.exam_id, student_exam.cat1, student_exam.cat2, student_exam.main_exam, student_exam.grade
FROM student_exam
INNER JOIN vw_students ON student_exam.entity_id = vw_students.entity_id
INNER JOIN subjects ON student_exam.subject_id = subjects.subject_id
INNER JOIN exams ON student_exam.exam_id = exams.exam_id;



CREATE VIEW vw_subjects AS
SELECT teachers.teacher_id, teachers.surname, subjects.subject_id, subjects.subject_name, subjects.details
FROM subjects
INNER JOIN orgs ON subjects.org_id = orgs.org_id
INNER JOIN teachers ON subjects.teacher_id = teachers.teacher_id;

CREATE VIEW vw_timetable AS
SELECT class.class_id, class.class_name, b.subject_id, b.subject_name,b.surname, trimester.trimester_id, 
	weekdays.weekday_id, weekdays.weekday_name, timetable.timetable_id, timetable.start_time, 
timetable.end_time, timetable.exam_date
FROM timetable
INNER JOIN class ON timetable.class_id = class.class_id
INNER JOIN vw_subjects as b ON timetable.subject_id = b.subject_id
INNER JOIN trimester ON timetable.trimester_id = trimester.trimester_id
INNER JOIN weekdays ON timetable.weekday_id = weekdays.weekday_id;


	
	
CREATE OR REPLACE FUNCTION ins_students() RETURNS trigger AS $$
      DECLARE
	  rec RECORD;
BEGIN
	IF (TG_OP = 'INSERT') THEN
		IF(NEW.entity_id IS NULL) THEN
			SELECT org_id INTO rec
			FROM orgs WHERE (is_default = true);

			NEW.entity_id := nextval('entitys_entity_id_seq');

			INSERT INTO entitys (entity_id, org_id, entity_type_id, entity_name, User_name, 
				primary_email, primary_telephone, function_role)
			VALUES (NEW.entity_id, rec.org_id, 4, 
				(NEW.surname || ' ' || NEW.last_name || ' ' || COALESCE(NEW.middle_name, '')),
				lower(NEW.email),  NEW.telephone, 'student');
		END IF;

		INSERT INTO sys_emailed (sys_email_id, table_id, table_name)
		VALUES (1, NEW.entity_id, 'student');
	ELSIF (TG_OP = 'UPDATE') THEN
		UPDATE entitys  SET entity_name = (NEW.surname || ' ' || NEW.first_name || ' ' || COALESCE(NEW.middle_name, ''))
		WHERE entity_id = NEW.entity_id;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_students BEFORE INSERT OR UPDATE ON students
    FOR EACH ROW EXECUTE PROCEDURE ins_students();
    
    

		 
	

	
	insert into entity_types(org_id,entity_type_name,entity_role,use_key) VALUES (0,'students','student',0);
    insert into entity_types(org_id,entity_type_name,entity_role,use_key) VALUES (0,'teachers','teacher',0);
    insert into entity_types(org_id,entity_type_name,entity_role,use_key) VALUES (0,'guardians','guardian',0);
	

	
CREATE OR REPLACE FUNCTION getGradeName(marks integer) RETURNS varchar(2) AS $$
DECLARE 
	v_grade		varchar(2);
BEGIN 
	SELECT grade_name INTO v_grade FROM grades WHERE marks >= min_range AND marks <= max_range;
	return v_grade;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION process_remaining_dorms() RETURNS TRIGGER AS $$
DECLARE

	v_curr_remaining		integer;
	v_curr_remaining1		integer;
BEGIN      
     IF (TG_OP = 'INSERT') THEN
	SELECT remaining INTO v_curr_remaining FROM dormitorys  WHERE dormitory_id = NEW.dormitory_id;
	IF( v_curr_remaining > 0 ) THEN 
		UPDATE dormitorys SET remaining = (v_curr_remaining -1) WHERE dormitory_id = NEW.dormitory_id;
	ELSE
		RAISE EXCEPTION 'Domitory is full';
	END IF;
	
      END IF;  
      
       IF (TG_OP = 'UPDATE') THEN
      
      SELECT remaining INTO v_curr_remaining FROM dormitorys  WHERE dormitory_id = NEW.dormitory_id;
      SELECT remaining INTO v_curr_remaining1 FROM dormitorys  WHERE dormitory_id = OLD.dormitory_id;
	IF( v_curr_remaining > 0 ) THEN 
		UPDATE dormitorys SET remaining = (v_curr_remaining -1) WHERE dormitory_id = NEW.dormitory_id;
		UPDATE dormitorys SET remaining = (v_curr_remaining1 +1) WHERE dormitory_id = OLD.dormitory_id;
	ELSE
		RAISE EXCEPTION 'Domitory is full';
	END IF;
      
       END IF;  
      
    RETURN NEW;
END;
    
$$ LANGUAGE plpgsql;

CREATE TRIGGER remaining_dorms BEFORE INSERT OR UPDATE ON dormitory_students
    FOR EACH ROW EXECUTE PROCEDURE process_remaining_dorms();
    
    
 CREATE OR REPLACE function calculate_grades() RETURNS TRIGGER AS $$
    
    DECLARE
    totals			integer;
    v_grade			Varchar(30);
    
    BEGIN
    
    IF(TG_OP = 'INSERT') THEN
    
    SELECT ((NEW.cat1 + NEW.cat2) * 0.5 + NEW.main_exam):: integer INTO totals;
     SELECT grade_name INTO v_grade FROM grades WHERE totals <= max_range AND totals >= min_range;
     NEW.grade= v_grade;
    
    
    END IF;
    
    RETURN NEW;
    END;
    
    $$ LANGUAGE plpgsql;

CREATE TRIGGER calculate_grades BEFORE INSERT OR UPDATE ON student_exam
    FOR EACH ROW EXECUTE PROCEDURE calculate_grades();
    
    
    
    
    



	
	
	
	

	
	
   
