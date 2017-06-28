
CREATE VIEW vw_staff AS 
		SELECT entitys.entity_id, entitys.entity_name,
		staff.org_id, staff.staff_id, staff.staff_role, staff.full_name, staff.surname, staff.first_name, staff.middle_name, staff.date_of_birth, staff.gender, staff.phone, staff.primary_email, staff.place_of_birth,
		staff.marital_status, staff.appointment_date, staff.exit_date, staff.picture_file, staff.active, staff.language, staff.interests, staff.narrative
	FROM staff JOIN entitys ON staff.entity_id = entitys.entity_id;

CREATE VIEW vw_subjects AS 
	SELECT subjects.org_id,subjects.subject_id, vw_staff.full_name,vw_staff.primary_email,vw_staff.staff_id, 
		date_part('year', subject_year) as subject_date,
		 subjects.subject_name, subjects.details
	FROM subjects
	join vw_staff on subjects.staff_id = vw_staff.staff_id   ;

	
CREATE OR REPLACE VIEW vw_stream_classes AS
		SELECT stream_classes.org_id, 
		stream_classes.stream_class_id, stream_classes.class_level, stream_classes.stream, stream_classes.narrative, stream_classes.details
	FROM stream_classes;
	
CREATE OR REPLACE VIEW vw_students AS 
		SELECT entitys.entity_id, entitys.entity_name,
		stream_classes.stream_class_id, stream_classes.stream,
		students.org_id, students.student_id, students.student_name,
		 students.sex, students.nationality, students.birth_date, students.address, students.zipcode,
		 students.town, students.country_code_id, students.telno, students.email, guardians.fathers_name, guardians.fathers_tel_no, guardians.fathers_email, guardians.mothers_name, guardians.mothers_tel_no, guardians.mothers_email, guardians.guardian_name, guardians.g_address, guardians.g_zipcode, guardians.g_town, guardians.sys_country_id, guardians.g_telno, guardians.g_email, guardians.current_contact, guardians.registrar_details, guardians.details
	FROM students	
		JOIN stream_classes ON students.stream_class_id = stream_classes.stream_class_id
		JOIN entitys ON students.entity_id = entitys.entity_id
		JOIN guardians ON students.student_id = guardians.student_id;
		
CREATE VIEW vw_grades AS 
		SELECT grades.org_id, grades.grade_id, grades.grade_range, grades.details
	FROM grades;

CREATE VIEW vw_sessions AS 
		SELECT sessions.org_id, sessions.session_id, sessions.session_name, sessions.session_start_date, sessions.session_end_date, sessions.details
	FROM sessions;

CREATE VIEW vw_students_session AS 
		SELECT sessions.session_id, sessions.session_name,
		students.student_id, students.student_name,
		students_session.org_id, 
		students_session.student_session_id, students_session.details
	FROM students_session	
		JOIN sessions ON students_session.session_id = sessions.session_id
		JOIN students ON students_session.student_id = students.student_id;

CREATE VIEW vw_exams AS 
		SELECT sessions.session_id, sessions.session_name,exams.exam_date,
		 exams.start_time,exams.end_time,
		stream_classes.stream_class_id, stream_classes.stream,vw_staff.staff_id, vw_staff.full_name,
		exams.org_id, exams.exam_id, exams.class_level, exams.subject_id, exams.exam_file, exams.exam_narrative
	FROM exams
		JOIN sessions ON exams.session_id = sessions.session_id
		JOIN vw_staff on vw_staff. staff_id = exams.staff_id
		JOIN stream_classes ON exams.class_level = stream_classes.stream_class_id;
		


CREATE VIEW vw_timetable AS 
		SELECT  sessions.session_id, sessions.session_name, 
		staff.staff_id, staff.surname,
		stream_classes.stream_class_id, stream_classes.stream, 
		subjects.org_id, subjects.subject_id, subjects.subject_name,
		timetable.timetable_id,timetable.monday, timetable.tuesday, timetable.wednesday, timetable.thursday, timetable.friday, timetable.saturday, timetable.start_time, timetable.end_time, timetable.narrative
	FROM timetable	
		JOIN stream_classes ON timetable.stream_class_id = stream_classes.stream_class_id
		JOIN subjects ON timetable.subject_id = subjects.subject_id
		JOIN staff ON timetable.staff_id = staff.staff_id
		JOIN sessions ON timetable.session_id = sessions.session_id;
		
CREATE VIEW vw_exams_subjects AS
	SELECT exams.exam_id, exams.exam_name, 
	subjects.subject_id, subjects.subject_name, 
	exams_subjects.org_id, exams_subjects.exams_subjects_id, exams_subjects.exam_file, exams_subjects.exam_description, exams_subjects.narrative
	FROM exams_subjects
		JOIN exams ON exams_subjects.exam_id = exams.exam_id
		JOIN subjects ON exams_subjects.subject_id = subjects.subject_id;

CREATE VIEW vw_fees_structure AS
	SELECT sessions.session_id, sessions.session_name,
	stream_classes.stream_class_id, stream_classes.stream,
	fees_structure.org_id, fees_structure.fees_structure_id, fees_structure.fees_amount,  fees_structure.additional_amounts, fees_structure.description
	FROM fees_structure
		JOIN sessions ON fees_structure.session_id = sessions.session_id
		JOIN stream_classes ON fees_structure.stream_class_id = stream_classes.stream_class_id;

CREATE VIEW vw_students_fees AS
	SELECT fees_structure.fees_structure_id,
	students.student_id, students.student_name,
	students_fees.student_fee_id, students_fees.fees_charged, students_fees.fees_paid, students_fees.paid_date, students_fees.fees_balance, students_fees.cleared, students_fees.description
	FROM students_fees
	INNER JOIN fees_structure ON students_fees.fees_structure_id = fees_structure.fees_structure_id
	INNER JOIN students ON students_fees.student_id = students.student_id;


CREATE VIEW vw_applicant AS
	SELECT orgs.org_id, orgs.org_name, 
	 students.student_id, students.student_name, applicant.applicant_name, applicant.applicant_dob, 
	 applicant.applicants_address, applicant.gender, applicant.country_code_id, applicant.telno,
	 applicant.email, applicant.workflow_table_id, applicant.action_date
	 
	FROM applicant
	INNER JOIN orgs ON applicant.org_id = orgs.org_id
	INNER JOIN students ON applicant.student_id = students.student_id
	 WHERE  applicant.approve_status = 'Approved';
	

CREATE VIEW vw_employee_details AS
SELECT employees_details.employees_details_id, employees_details.staff_id, employees_details.location_id, employees_details.entity_id,
	employees_details.bank_branch_id, employees_details.currency_id, employees_details.org_id,
	employees_details.person_title, employees_details.date_of_birth, employees_details.dob_email, 
	employees_details.designation,employees_details.gender, employees_details.phone, employees_details.nationality, employees_details.nation_of_birth,employees_details.place_of_birth, employees_details.marital_status, employees_details.appointment_date,employees_details.current_appointment, employees_details.contract, employees_details.contract_period,employees_details.employment_terms, locations.location_name, bank_branch.bank_branch_name, bank_branch.bank_branch_code,
	sys_countrys.sys_country_name, sys_countrys.sys_currency_name, currency.currency_name, currency.currency_symbol
FROM bank_branch INNER JOIN employees_details ON bank_branch.bank_branch_id = employees_details.bank_branch_id
  INNER JOIN currency ON currency.currency_id = employees_details.currency_id
  INNER JOIN locations ON locations.location_id = employees_details.location_id
  INNER JOIN sys_countrys ON sys_countrys.sys_country_id = employees_details.nation_of_birth
