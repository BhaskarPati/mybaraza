

ALTER TABLE review_category ADD rate_objectives			boolean default true not null;

UPDATE review_category SET rate_objectives = false WHERE review_category_id = 5;

CREATE TRIGGER upd_action BEFORE UPDATE ON applications
    FOR EACH ROW EXECUTE PROCEDURE upd_action();
    
CREATE OR REPLACE FUNCTION ins_applications() RETURNS trigger AS $$
DECLARE
	typeid	integer;
BEGIN
	
	IF ((NEW.entity_id is null) AND (NEW.employee_id is not null)) THEN
		NEW.entity_id := NEW.employee_id;
		NEW.approve_status := 'Completed';
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_applications BEFORE INSERT ON applications
    FOR EACH ROW EXECUTE PROCEDURE ins_applications();
    
CREATE OR REPLACE FUNCTION add_employee(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	v_application_id		integer;
	v_entity_id				integer;
	v_employee_id			integer;
	msg		 				varchar(120);
BEGIN

	v_application_id := CAST($1 as int);
	SELECT employees.entity_id, applications.employee_id INTO v_entity_id, v_employee_id
	FROM applications LEFT JOIN employees ON applications.entity_id = employees.entity_id
	WHERE (application_id = v_application_id);

	IF(v_employee_id is null) AND (v_entity_id is null)THEN
		INSERT INTO employees (org_id, currency_id, bank_branch_id,
			department_role_id, pay_scale_id, pay_group_id, location_id,  
			person_title, surname, first_name, middle_name,
			date_of_birth, gender, nationality, marital_status,
			picture_file, identity_card, language, interests, objective,
			contract, appointment_date, current_appointment, contract_period,
			basic_salary)

		SELECT orgs.org_id, orgs.currency_id, 0,
			intake.department_role_id, intake.pay_scale_id, intake.pay_group_id, intake.location_id,
			applicants.person_title, applicants.surname, applicants.first_name, applicants.middle_name,  
			applicants.date_of_birth, applicants.gender, applicants.nationality, applicants.marital_status, 
			applicants.picture_file, applicants.identity_card, applicants.language, applicants.interests, applicants.objective,
			
			
			intake.contract, applications.contract_date, applications.contract_start, 
			applications.contract_period, applications.initial_salary
		FROM orgs INNER JOIN applicants ON orgs.org_id = applicants.org_id
			INNER JOIN applications ON applicants.entity_id = applications.entity_id
			INNER JOIN intake ON applications.intake_id = intake.intake_id
			
		WHERE (applications.application_id = v_application_id);
		
		UPDATE applications SET employee_id = currval('entitys_entity_id_seq'), approve_status = 'Completed'
		WHERE (application_id = v_application_id);
			
		msg := 'Employee added';
	ELSIF(v_employee_id is null)THEN
		UPDATE applications SET employee_id = v_employee_id, 
			department_role_id = intake.department_role_id, pay_scale_id = intake.pay_scale_id, 
			pay_group_id = intake.pay_group_id, location_id = intake.location_id,
			approve_status = 'Completed'
		FROM intake  
		WHERE (applications.intake_id = intake.intake_id) AND (applications.application_id = v_application_id);
		
		msg := 'Employee details updated';
	ELSE
		msg := 'Employeed already added to the system';
	END IF;
	

	return msg;
END;
$$ LANGUAGE plpgsql;

ALTER TABLE contract_types ADD notice_period			integer default 30 not null;

ALTER TABLE applications ADD 	notice_email			boolean default false not null;
	
ALTER TABLE applicants ADD currency_id				integer references currency;
CREATE INDEX applicants_currency_id ON applicants(currency_id);

ALTER TABLE applications ADD	currency_id				integer references currency;
ALTER TABLE applications ADD	exchange_rate			real default 1;

DROP VIEW vw_contracting;
DROP VIEW vw_intern_evaluations;
DROP VIEW vw_applications;
DROP VIEW vw_applicants;


CREATE VIEW vw_applicants AS
	SELECT sys_countrys.sys_country_id, sys_countrys.sys_country_name,
		currency.currency_id, currency.currency_name, currency.currency_symbol,
		applicants.org_id, applicants.entity_id, applicants.surname, 
		applicants.first_name, applicants.middle_name, applicants.date_of_birth, applicants.nationality, 
		applicants.identity_card, applicants.language, applicants.objective, applicants.interests, applicants.picture_file, applicants.details,
		applicants.person_title, applicants.field_of_study, applicants.applicant_email, applicants.applicant_phone, 
		applicants.previous_salary, applicants.expected_salary,
		(applicants.Surname || ' ' || applicants.First_name || ' ' || COALESCE(applicants.Middle_name, '')) as applicant_name,
		to_char(age(applicants.date_of_birth), 'YY') as applicant_age,
		(CASE WHEN applicants.gender = 'M' THEN 'Male' ELSE 'Female' END) as gender_name,
		(CASE WHEN applicants.marital_status = 'M' THEN 'Married' ELSE 'Single' END) as marital_status_name,

		vw_education_max.education_class_id, vw_education_max.education_class_name, 
		vw_education_max.education_id, vw_education_max.date_from, vw_education_max.date_to, 
		vw_education_max.name_of_school, vw_education_max.examination_taken,
		vw_education_max.grades_obtained, vw_education_max.certificate_number,
		
		vw_employment_max.employers_name, vw_employment_max.position_held,
		vw_employment_max.date_from as emp_date_from, vw_employment_max.date_to as emp_date_to, 
		vw_employment_max.employment_duration, vw_employment_max.employment_experince,
		round((date_part('year', vw_employment_max.employment_duration) + date_part('month', vw_employment_max.employment_duration)/12)::numeric, 1) as emp_duration,
		round((date_part('year', vw_employment_max.employment_experince) + date_part('month', vw_employment_max.employment_experince)/12)::numeric, 1) as emp_experince
		
	FROM applicants INNER JOIN sys_countrys ON applicants.nationality = sys_countrys.sys_country_id
		LEFT JOIN vw_education_max ON applicants.entity_id = vw_education_max.entity_id
		LEFT JOIN vw_employment_max ON applicants.entity_id = vw_employment_max.entity_id
		LEFT JOIN currency ON applicants.currency_id = currency.currency_id;


CREATE VIEW vw_applications AS
	SELECT vw_intake.department_id, vw_intake.department_name, vw_intake.department_description, vw_intake.department_duties,
		vw_intake.department_role_id, vw_intake.department_role_name, vw_intake.parent_role_name,
		vw_intake.job_description, vw_intake.job_requirements, vw_intake.duties, vw_intake.performance_measures, 
		vw_intake.intake_id, vw_intake.opening_date, vw_intake.closing_date, vw_intake.positions, 
		vw_intake.org_name, vw_intake.org_detail,
		entitys.entity_id, entitys.entity_name, entitys.primary_email,
		currency.currency_id, currency.currency_name, currency.currency_symbol,
		
		applications.org_id,
		applications.application_id, applications.employee_id, applications.contract_date, applications.contract_close, 
		applications.contract_start, applications.contract_period, applications.contract_terms, applications.initial_salary, 
		applications.application_date, applications.approve_status, applications.workflow_table_id, applications.action_date, 
		applications.applicant_comments, applications.review, applications.short_listed,
		applications.previous_salary, applications.expected_salary, applications.exchange_rate, applications.review_rating,

		vw_education_max.education_class_name, vw_education_max.date_from, vw_education_max.date_to, 
		vw_education_max.name_of_school, vw_education_max.examination_taken, 
		vw_education_max.grades_obtained, vw_education_max.certificate_number,

		vw_employment_max.employment_id, vw_employment_max.employers_name, vw_employment_max.position_held,
		vw_employment_max.date_from as emp_date_from, vw_employment_max.date_to as emp_date_to, 
		vw_employment_max.employment_duration, vw_employment_max.employment_experince,
		round((date_part('year', vw_employment_max.employment_duration) + date_part('month', vw_employment_max.employment_duration)/12)::numeric, 1) as emp_duration,
		round((date_part('year', vw_employment_max.employment_experince) + date_part('month', vw_employment_max.employment_experince)/12)::numeric, 1) as emp_experince
		
	FROM applications INNER JOIN entitys ON applications.entity_id = entitys.entity_id
		INNER JOIN vw_intake ON applications.intake_id = vw_intake.intake_id
		LEFT JOIN vw_education_max ON entitys.entity_id = vw_education_max.entity_id
		LEFT JOIN vw_employment_max ON entitys.entity_id = vw_employment_max.entity_id
		LEFT JOIN currency ON applications.currency_id = currency.currency_id;
		
		
CREATE VIEW vw_intern_evaluations AS 
	SELECT vw_applicants.entity_id, vw_applicants.sys_country_name, vw_applicants.applicant_name, 
		vw_applicants.applicant_age, vw_applicants.gender_name, vw_applicants.marital_status_name, vw_applicants.language, 
		vw_applicants.objective, vw_applicants.interests, education.date_from, education.date_to, education.name_of_school, 
		education.examination_taken, vw_internships.department_id, vw_internships.department_name, 
		vw_internships.internship_id, vw_internships.positions, vw_internships.opening_date, vw_internships.closing_date, 

		interns.intern_id, interns.payment_amount, interns.start_date, interns.end_date, interns.application_date, 
		interns.approve_status, interns.action_date, interns.workflow_table_id, interns.applicant_comments, interns.review
	FROM vw_applicants JOIN education ON vw_applicants.entity_id = education.entity_id
		JOIN interns ON interns.entity_id = vw_applicants.entity_id
		JOIN vw_internships ON interns.internship_id = vw_internships.internship_id
		JOIN (SELECT education.entity_id, max(education.education_class_id) AS mx_class_id FROM education
			WHERE education.entity_id IS NOT NULL
			GROUP BY education.entity_id) a ON education.entity_id = a.entity_id AND education.education_class_id = a.mx_class_id
		WHERE education.education_class_id > 6
		ORDER BY vw_applicants.entity_id;
		
CREATE VIEW vw_contracting AS
	SELECT vw_intake.department_id, vw_intake.department_name, vw_intake.department_description, vw_intake.department_duties,
		vw_intake.department_role_id, vw_intake.department_role_name, 
		vw_intake.job_description, vw_intake.parent_role_name,
		vw_intake.job_requirements, vw_intake.duties, vw_intake.performance_measures, 
		vw_intake.intake_id, vw_intake.opening_date, vw_intake.closing_date, vw_intake.positions, 
		entitys.entity_id, entitys.entity_name, orgs.org_id, orgs.org_name,
		
		contract_types.contract_type_id, contract_types.contract_type_name, contract_types.notice_period, contract_types.contract_text,
		contract_status.contract_status_id, contract_status.contract_status_name,
		
		applications.application_id, applications.employee_id, applications.contract_date, applications.contract_close, 
		applications.contract_start, applications.contract_period, applications.contract_terms, applications.initial_salary, 
		applications.application_date, applications.approve_status, applications.workflow_table_id, applications.action_date, 
		applications.applicant_comments, applications.review, 
		applications.notice_email, (current_date - applications.contract_close) as days_end_contract,

		vw_education_max.education_class_name, vw_education_max.date_from, vw_education_max.date_to, 
		vw_education_max.name_of_school, vw_education_max.examination_taken, 
		vw_education_max.grades_obtained, vw_education_max.certificate_number,

		vw_employment_max.employment_id, vw_employment_max.employers_name, vw_employment_max.position_held,
		vw_employment_max.date_from as emp_date_from, vw_employment_max.date_to as emp_date_to, 
		
		vw_employment_max.employment_duration, vw_employment_max.employment_experince,
		round((date_part('year', vw_employment_max.employment_duration) + date_part('month', vw_employment_max.employment_duration)/12)::numeric, 1) as emp_duration,
		round((date_part('year', vw_employment_max.employment_experince) + date_part('month', vw_employment_max.employment_experince)/12)::numeric, 1) as emp_experince

	FROM applications INNER JOIN entitys ON applications.employee_id = entitys.entity_id
		INNER JOIN orgs ON applications.org_id = orgs.org_id
		LEFT JOIN vw_intake ON applications.intake_id = vw_intake.intake_id
		LEFT JOIN contract_types ON applications.contract_type_id = contract_types.contract_type_id
		LEFT JOIN contract_status ON applications.contract_status_id = contract_status.contract_status_id
		LEFT JOIN vw_education_max ON entitys.entity_id = vw_education_max.entity_id
		LEFT JOIN vw_employment_max ON entitys.entity_id = vw_employment_max.entity_id;
		
CREATE OR REPLACE FUNCTION ins_applications(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	v_entity_id				integer;
	v_application_id		integer;
	v_sys_email_id			integer;
	v_address				integer;
	c_education_id			integer;
	c_referees				integer;
	c_files					integer;
	reca					RECORD;
	msg 					varchar(120);
BEGIN
	SELECT application_id INTO v_application_id
	FROM applications 
	WHERE (intake_id = $1::int) AND (entity_id = $2::int);
	
	SELECT org_id, entity_id, currency_id, previous_salary, expected_salary INTO reca
	FROM applicants
	WHERE (entity_id = $2::int);
	v_entity_id := reca.entity_id;
	IF(reca.entity_id is null) THEN
		SELECT org_id, entity_id, currency_id, basic_salary as previous_salary, basic_salary as expected_salary INTO reca
		FROM employees
		WHERE (entity_id = $2::int);
		v_entity_id := reca.entity_id;
	END IF;
	
	SELECT count(address_id) INTO v_address
	FROM vw_address
	WHERE (table_name = 'applicant') AND (is_default = true) AND (table_id  = v_entity_id);
	IF(v_address is null) THEN v_address = 0; END IF;
	
	SELECT count(education_id) INTO c_education_id
	FROM education
	WHERE (entity_id  = v_entity_id);
	IF(c_education_id is null) THEN c_education_id = 0; END IF;
	
	SELECT count(address_id) INTO c_referees
	FROM vw_referees
	WHERE (table_id  = v_entity_id);
	IF(c_referees is null) THEN c_referees = 0; END IF;
	
	SELECT count(sys_file_id) INTO c_files
	FROM sys_files
	WHERE (table_id  = v_entity_id);
	IF(c_files is null) THEN c_files = 0; END IF;

	IF v_application_id is not null THEN
		msg := 'There is another application for the post.';
		RAISE EXCEPTION '%', msg;
	ELSIF (reca.previous_salary is null) OR (reca.expected_salary is null) THEN
		msg := 'Kindly indicate your previous and expected salary';
		RAISE EXCEPTION '%', msg;
	ELSIF (v_address < 1) THEN
		msg := 'You need to have at least one full address added';
		RAISE EXCEPTION '%', msg;
	ELSIF (c_education_id < 2) THEN
		msg := 'You need to have at least two education levels added';
		RAISE EXCEPTION '%', msg;
	ELSIF (c_referees < 3) THEN
		msg := 'You need to have at least three referees added';
		RAISE EXCEPTION '%', msg;
	ELSIF (c_files < 2) THEN
		msg := 'CV and Cover Letter MUST be uploaded';
		RAISE EXCEPTION '%', msg;
	ELSE
		v_application_id := nextval('applications_application_id_seq');
		INSERT INTO applications (application_id, intake_id, org_id, entity_id, currency_id, previous_salary, expected_salary, approve_status)
		VALUES (v_application_id, $1::int, reca.org_id, reca.entity_id, reca.currency_id, reca.previous_salary, reca.expected_salary, 'Completed');
		
		SELECT sys_email_id INTO v_sys_email_id FROM sys_emails
		WHERE (use_type = 10) AND (org_id = reca.org_id);
		
		INSERT INTO sys_emailed (sys_email_id, org_id, table_id, table_name, email_type)
		VALUES (v_sys_email_id, reca.org_id, v_application_id, 'applications', 10);
		
		msg := 'Added Job application';
	END IF;

	return msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION emailed_dob(integer, varchar(64)) RETURNS varchar(120) AS $$
DECLARE
	v_org_id				integer;
	v_entity_name			varchar(120);
BEGIN
	SELECT org_id, entity_name INTO v_org_id, v_entity_name
	FROM entitys WHERE (entity_id = $2::int);
	
	INSERT INTO sys_emailed (sys_email_id, org_id, email_type, narrative)
	VALUES (9, 0, 9, 'Its birthday for ' || v_entity_name);

	UPDATE employees SET dob_email = current_date WHERE (entity_id = $2::int);

	RETURN 'Done';
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION emailed_contract(integer, varchar(64)) RETURNS varchar(120) AS $$
BEGIN
	UPDATE applications SET notice_email = true WHERE (application_id = $2::int);
	RETURN 'Done';
END;
$$ LANGUAGE plpgsql;

INSERT INTO sys_emails (sys_email_id, use_type, org_id, sys_email_name, title, details) 
VALUES (12, 12, 0, 'Contract Ending', 'Contract Ending - {{entity_name}}', 'Hello,<br><br>
Kindly note that the contract for {{entity_name}} is due to employment.<br><br>
Regards,<br>
HR Manager<br>');

CREATE OR REPLACE FUNCTION process_loans(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	rec							RECORD;
	v_exchange_rate				real;
	v_employee_adjustment_id	integer;
	msg							varchar(120);
BEGIN
	
	FOR rec IN SELECT vw_loan_monthly.loan_month_id, vw_loan_monthly.loan_id, vw_loan_monthly.entity_id, vw_loan_monthly.period_id, 
		vw_loan_monthly.employee_adjustment_id, vw_loan_monthly.adjustment_id, vw_loan_monthly.loan_balance, 
		vw_loan_monthly.repayment, (vw_loan_monthly.interest_paid + vw_loan_monthly.penalty_paid) as total_interest,
		(vw_loan_monthly.repayment + vw_loan_monthly.interest_paid + vw_loan_monthly.penalty_paid) as total_deduction,
		employee_month.employee_month_id, employee_month.org_id, 
		employee_month.currency_id, employee_month.exchange_rate,
		adjustments.currency_id as adj_currency_id
	FROM vw_loan_monthly INNER JOIN employee_month ON (vw_loan_monthly.entity_id = employee_month.entity_id) AND (vw_loan_monthly.period_id = employee_month.period_id)
		INNER JOIN adjustments ON vw_loan_monthly.adjustment_id = adjustments.adjustment_id
	WHERE (vw_loan_monthly.period_id = CAST($1 as int)) LOOP
	
		IF(rec.currency_id = rec.adj_currency_id)THEN
			v_exchange_rate := 1;
		ELSE
			v_exchange_rate := 1 / rec.exchange_rate;
		END IF;

		IF(rec.employee_adjustment_id is null)THEN
			v_employee_adjustment_id := nextval('employee_adjustments_employee_adjustment_id_seq');
			
			INSERT INTO employee_adjustments (employee_month_id, adjustment_id, adjustment_type, adjustment_factor,
				amount, balance, in_tax, org_id, exchange_rate, employee_adjustment_id)
			VALUES (rec.employee_month_id, rec.adjustment_id, 2, -1,
				rec.total_deduction, rec.loan_balance, false, rec.org_id, v_exchange_rate, v_employee_adjustment_id);

			UPDATE loan_monthly SET employee_adjustment_id = v_employee_adjustment_id
			WHERE (loan_month_id = rec.loan_month_id);
		ELSE
			UPDATE employee_adjustments SET amount = rec.total_deduction, balance = rec.loan_balance, exchange_rate = v_exchange_rate
			WHERE (employee_adjustment_id = rec.employee_adjustment_id);
		END IF;

	END LOOP;

	msg := 'Payroll Processed';

	RETURN msg;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION compute_loans(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	v_period_id			integer;
	v_org_id			integer;
	msg					varchar(120);
BEGIN

	SELECT period_id, org_id INTO v_period_id, v_org_id
	FROM periods
	WHERE (period_id = $1::integer);
	
	DELETE FROM employee_adjustment_id WHERE employee_adjustment_id IN
	(SELECT employee_adjustment_id FROM loan_monthly WHERE period_id = v_period_id);
	DELETE FROM loan_monthly WHERE period_id = v_period_id;

	INSERT INTO loan_monthly (period_id, org_id, loan_id, interest_amount, interest_paid, repayment)
	SELECT v_period_id, org_id, loan_id, (loan_balance * interest / 1200), (loan_balance * interest / 1200),
		(CASE WHEN loan_balance > monthly_repayment THEN monthly_repayment ELSE loan_balance END)
	FROM vw_loans 
	WHERE (loan_balance > 0) AND (approve_status = 'Approved') AND (reducing_balance =  true) AND (org_id = v_org_id);

	INSERT INTO loan_monthly (period_id, org_id, loan_id, interest_amount, interest_paid, repayment)
	SELECT v_period_id, org_id, loan_id, (principle * interest / 1200), (principle * interest / 1200),
		(CASE WHEN loan_balance > monthly_repayment THEN monthly_repayment ELSE loan_balance END)
	FROM vw_loans 
	WHERE (loan_balance > 0) AND (approve_status = 'Approved') AND (reducing_balance =  false) AND (org_id = v_org_id);

	msg := 'Loans re-computed';

	RETURN msg;
END;
$$ LANGUAGE plpgsql;

DROP VIEW vw_career_development;
DROP VIEW vw_evaluation_objectives;
DROP VIEW vw_evaluation_points;
DROP VIEW vw_all_job_reviews;
DROP VIEW vw_review_year;
DROP VIEW vw_job_reviews;

CREATE VIEW vw_job_reviews AS
	SELECT entitys.entity_id, entitys.entity_name, 
		review_category.review_category_id, review_category.review_category_name, review_category.rate_objectives,
		job_reviews.org_id, job_reviews.job_review_id, job_reviews.total_points, 
		job_reviews.review_date, job_reviews.review_done, 
		job_reviews.approve_status, job_reviews.workflow_table_id, job_reviews.application_date, job_reviews.action_date,
		job_reviews.recomendation, job_reviews.reviewer_comments, job_reviews.pl_comments, job_reviews.details,
		EXTRACT(YEAR FROM job_reviews.review_date) as review_year
	FROM job_reviews INNER JOIN entitys ON job_reviews.entity_id = entitys.entity_id
		INNER JOIN  review_category ON job_reviews.review_category_id = review_category.review_category_id;
	
CREATE VIEW vw_review_year AS
	SELECT vw_job_reviews.org_id, vw_job_reviews.review_year
	FROM vw_job_reviews
	WHERE vw_job_reviews.review_year is not null
	GROUP BY vw_job_reviews.org_id, vw_job_reviews.review_year;

CREATE VIEW vw_all_job_reviews AS
	SELECT a.org_id, a.review_year,  a.entity_id, a.employee_id, a.employee_name,
		b.job_review_id, b.total_points, b.approve_status
	FROM 
		(SELECT vw_review_year.review_year, employees.org_id, employees.entity_id,
			employees.employee_id, 
			(employees.Surname || ' ' || employees.First_name || ' ' || COALESCE(employees.Middle_name, '')) as employee_name
		FROM vw_review_year INNER JOIN employees ON vw_review_year.org_id = employees.org_id
		WHERE employees.active = true) as a
	LEFT JOIN
		(SELECT job_review_id, total_points, approve_status, entity_id, review_year
		FROM vw_job_reviews) as b
		
	ON (a.entity_id = b.entity_id) AND (a.review_year = b.review_year);
	
CREATE VIEW vw_evaluation_points AS
	SELECT vw_job_reviews.entity_id, vw_job_reviews.entity_name, 
		vw_job_reviews.review_category_id, vw_job_reviews.review_category_name, vw_job_reviews.rate_objectives,
		vw_job_reviews.job_review_id, vw_job_reviews.total_points, 
		vw_job_reviews.review_date, vw_job_reviews.review_done, vw_job_reviews.recomendation, vw_job_reviews.reviewer_comments,
		vw_job_reviews.pl_comments,
		vw_job_reviews.approve_status, vw_job_reviews.workflow_table_id, vw_job_reviews.application_date, vw_job_reviews.action_date,
		vw_review_points.review_point_id, vw_review_points.review_point_name, vw_review_points.review_points,
		
		evaluation_points.org_id, evaluation_points.evaluation_point_id, evaluation_points.points, evaluation_points.grade,  
		evaluation_points.reviewer_points, evaluation_points.reviewer_grade, evaluation_points.reviewer_narrative,
		evaluation_points.narrative, evaluation_points.details
	FROM evaluation_points INNER JOIN vw_job_reviews ON evaluation_points.job_review_id = vw_job_reviews.job_review_id
		INNER JOIN vw_review_points ON evaluation_points.review_point_id = vw_review_points.review_point_id;

CREATE VIEW vw_evaluation_objectives AS
	SELECT vw_job_reviews.entity_id, vw_job_reviews.entity_name, 
		vw_job_reviews.review_category_id, vw_job_reviews.review_category_name, vw_job_reviews.rate_objectives,
		vw_job_reviews.job_review_id, vw_job_reviews.total_points, 
		vw_job_reviews.review_date, vw_job_reviews.review_done, vw_job_reviews.recomendation, vw_job_reviews.reviewer_comments,
		vw_job_reviews.pl_comments,
		vw_job_reviews.approve_status, vw_job_reviews.workflow_table_id, vw_job_reviews.application_date, vw_job_reviews.action_date,
		
		vw_objectives.objective_type_id, vw_objectives.objective_type_name, 
		vw_objectives.objective_id, vw_objectives.date_set, vw_objectives.objective_ps, vw_objectives.objective_name, 
		vw_objectives.objective_completed, vw_objectives.details as objective_details,

		evaluation_points.org_id, evaluation_points.evaluation_point_id, evaluation_points.points,
		evaluation_points.reviewer_points, evaluation_points.reviewer_narrative,
		evaluation_points.narrative, evaluation_points.details
	FROM evaluation_points INNER JOIN vw_job_reviews ON evaluation_points.job_review_id = vw_job_reviews.job_review_id
		INNER JOIN vw_objectives ON evaluation_points.objective_id = vw_objectives.objective_id;


CREATE VIEW vw_career_development AS
	SELECT vw_job_reviews.entity_id, vw_job_reviews.entity_name, vw_job_reviews.job_review_id, vw_job_reviews.total_points, 
		vw_job_reviews.review_date, vw_job_reviews.review_done, vw_job_reviews.recomendation, vw_job_reviews.reviewer_comments,
		vw_job_reviews.pl_comments,
		vw_job_reviews.approve_status, vw_job_reviews.workflow_table_id, vw_job_reviews.application_date, vw_job_reviews.action_date,
		
		career_development.career_development_id, career_development.career_development_name, 
		career_development.details as career_development_details,

		evaluation_points.org_id, evaluation_points.evaluation_point_id, evaluation_points.points,
		evaluation_points.reviewer_points, evaluation_points.reviewer_narrative,
		evaluation_points.narrative, evaluation_points.details
	FROM evaluation_points INNER JOIN vw_job_reviews ON evaluation_points.job_review_id = vw_job_reviews.job_review_id
		INNER JOIN career_development ON evaluation_points.career_development_id = career_development.career_development_id;
		
		

CREATE OR REPLACE FUNCTION job_review_check(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	rec							RECORD;
	v_approve_status			varchar(16);
	v_rate_objectives			boolean;
	v_self_rating				integer;
	v_objective_ps				real;
	sum_ods_ps					real;
	v_point_check				integer;
	msg 						varchar(120);
BEGIN
	
	SELECT sum(objectives.objective_ps) INTO v_objective_ps
	FROM objectives INNER JOIN evaluation_points ON evaluation_points.objective_id = objectives.objective_id
	WHERE (evaluation_points.job_review_id = CAST($1 as int));
	
	SELECT sum(ods_ps) INTO sum_ods_ps
	FROM objective_details INNER JOIN evaluation_points ON evaluation_points.objective_id = objective_details.objective_id
	WHERE (evaluation_points.job_review_id = CAST($1 as int));
	
	SELECT evaluation_points.evaluation_point_id INTO v_point_check
	FROM objectives INNER JOIN evaluation_points ON evaluation_points.objective_id = objectives.objective_id
	WHERE (evaluation_points.job_review_id = CAST($1 as int))
		AND (objectives.objective_ps > 0) AND (evaluation_points.points = 0);
		
	SELECT job_reviews.self_rating, review_category.rate_objectives, job_reviews.approve_status
		INTO v_self_rating, v_rate_objectives, v_approve_status
	FROM job_reviews INNER JOIN review_category ON job_reviews.review_category_id = review_category.review_category_id
	WHERE (job_reviews.job_review_id = $1::int);
	IF(v_self_rating is null) THEN v_self_rating := 0; END IF;
		
	IF(sum_ods_ps is null)THEN
		sum_ods_ps := 100;
	END IF;
	IF(sum_ods_ps = 0)THEN
		sum_ods_ps := 100;
	END IF;
	
	IF(v_rate_objectives = false)THEN
		v_objective_ps := 100;
		sum_ods_ps := 100;
	END IF;

	IF(v_approve_status <> 'Draft')THEN
		msg := 'The review is already submitted';
	ELSIF(v_objective_ps <> 100)THEN
		msg := 'Objective % must add up to 100';
		RAISE EXCEPTION '%', msg;
	ELSIF(sum_ods_ps <> 100)THEN
		msg := 'Objective details % must add up to 100';
		RAISE EXCEPTION '%', msg;
	ELSIF(v_self_rating = 0) AND (v_rate_objectives = true)THEN
		msg := 'Indicate your self rating';
		RAISE EXCEPTION '%', msg;
	ELSIF(v_point_check is not null)THEN
		msg := 'All objective evaluations points must be between 1 to 4';
		RAISE EXCEPTION '%', msg;
	ELSE
		UPDATE job_reviews SET approve_status = 'Completed'
		WHERE (job_review_id = CAST($1 as int));

		msg := 'Review Applied';
	END IF;

	RETURN msg;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION get_reporting_list(integer) RETURNS varchar(320) AS $$
DECLARE
    myrec	RECORD;
	mylist	varchar(320);
BEGIN
	mylist := null;
	FOR myrec IN SELECT entitys.entity_name
		FROM reporting INNER JOIN entitys ON reporting.report_to_id = entitys.entity_id
		WHERE (reporting.primary_report = true) AND (reporting.entity_id = $1) 
	LOOP

		IF (mylist is null) THEN
			mylist := myrec.entity_name;
		ELSE
			mylist := mylist || ', ' || myrec.entity_name;
		END IF;
	END LOOP;

	RETURN mylist;
END;
$$ LANGUAGE plpgsql;

