

UPDATE default_adjustments SET amount = WHERE adjustment_id = 1 AND entity_id = (SELECT entity_id FROM employees WHERE employee_id = '');

ALTER TABLE loan_monthly ADD extra_payment			real default 0 not null;

CREATE OR REPLACE FUNCTION get_total_repayment(integer) RETURNS real AS $$
	SELECT CASE WHEN sum(repayment + interest_paid + penalty_paid + extra_payment) is null THEN 0 
		ELSE sum(repayment + interest_paid + penalty_paid + extra_payment) END
	FROM loan_monthly
	WHERE (loan_id = $1);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_total_repayment(integer, date) RETURNS real AS $$
	SELECT CASE WHEN sum(repayment + interest_paid + penalty_paid + extra_payment) is null THEN 0 
		ELSE sum(repayment + interest_paid + penalty_paid + extra_payment) END
	FROM loan_monthly INNER JOIN periods ON loan_monthly.period_id = periods.period_id
	WHERE (loan_monthly.loan_id = $1) AND (periods.start_date < $2);
$$ LANGUAGE SQL;

DROP VIEW vw_period_loans;
DROP VIEW vw_loan_monthly;

CREATE VIEW vw_loan_monthly AS
	SELECT  vw_loans.adjustment_id, vw_loans.adjustment_name, vw_loans.account_number,
		vw_loans.currency_id, vw_loans.currency_name, vw_loans.currency_symbol,
		vw_loans.loan_type_id, vw_loans.loan_type_name, 
		vw_loans.entity_id, vw_loans.entity_name, vw_loans.employee_id, vw_loans.loan_date,
		vw_loans.loan_id, vw_loans.principle, vw_loans.interest, vw_loans.monthly_repayment, vw_loans.reducing_balance, 
		vw_loans.repayment_period, vw_periods.period_id, vw_periods.start_date, vw_periods.end_date, vw_periods.activated, vw_periods.closed,
		loan_monthly.org_id, loan_monthly.loan_month_id, loan_monthly.interest_amount, loan_monthly.repayment, loan_monthly.interest_paid, 
		loan_monthly.employee_adjustment_id, loan_monthly.penalty, loan_monthly.penalty_paid, 
		loan_monthly.extra_payment, loan_monthly.details,
		get_total_interest(vw_loans.loan_id, vw_periods.start_date) as total_interest,
		get_total_repayment(vw_loans.loan_id, vw_periods.start_date) as total_repayment,
		(vw_loans.principle + get_total_interest(vw_loans.loan_id, vw_periods.start_date + 1) + get_penalty(vw_loans.loan_id, vw_periods.start_date + 1)
		- vw_loans.initial_payment - get_total_repayment(vw_loans.loan_id, vw_periods.start_date + 1)) as loan_balance
	FROM loan_monthly INNER JOIN vw_loans ON loan_monthly.loan_id = vw_loans.loan_id
		INNER JOIN vw_periods ON loan_monthly.period_id = vw_periods.period_id;
		
		
CREATE VIEW vw_period_loans AS
	SELECT vw_loan_monthly.org_id, vw_loan_monthly.period_id, 
		sum(vw_loan_monthly.interest_amount) as sum_interest_amount, sum(vw_loan_monthly.repayment) as sum_repayment, 
		sum(vw_loan_monthly.penalty) as sum_penalty, sum(vw_loan_monthly.penalty_paid) as sum_penalty_paid, 
		sum(vw_loan_monthly.interest_paid) as sum_interest_paid, sum(vw_loan_monthly.loan_balance) as sum_loan_balance
	FROM vw_loan_monthly
	GROUP BY vw_loan_monthly.org_id, vw_loan_monthly.period_id;
	
	


DROP VIEW vw_referees;

ALTER TABLE address	ALTER COLUMN company_name	TYPE varchar(150);
ALTER TABLE address	ALTER COLUMN position_held	TYPE varchar(150);

CREATE VIEW vw_referees AS
	SELECT sys_countrys.sys_country_id, sys_countrys.sys_country_name, address.address_id, address.org_id, address.address_name, 
		address.table_name, address.table_id, address.post_office_box, address.postal_code, address.premises, address.street, address.town, 
		address.phone_number, address.extension, address.mobile, address.fax, address.email, address.is_default, address.website, 
		address.company_name, address.position_held, address.details
	FROM address INNER JOIN sys_countrys ON address.sys_country_id = sys_countrys.sys_country_id
	WHERE (address.table_name = 'referees');

CREATE TABLE adjustment_effects (
	adjustment_effect_id	integer primary key,
	adjustment_effect_name	varchar(50) not null
);

ALTER TABLE adjustments ADD adjustment_effect_id	integer references adjustment_effects;
CREATE INDEX adjustments_adjustment_effect_id ON adjustments(adjustment_effect_id);

INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, title, details) 
VALUES (10, 0, 'Job Application - acknowledgement', 'Job Application', 'Hello {{name}},<br><br>
We acknowledge receipt of your job application for {{job}}<br><br>
Regards,<br>
HR Manager<br>');
INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, title, details) 
VALUES (11, 0, 'Internship Application - acknowledgement', 'Job Application', 'Hello {{name}},<br><br>
We acknowledge receipt of your Internship application<br><br>
Regards,<br>
HR Manager<br>');
SELECT pg_catalog.setval('sys_emails_sys_email_id_seq', 11, true);

CREATE TABLE jobs_category (
	jobs_category_id		serial primary key,
	org_id					integer references orgs,
	jobs_category			varchar(50),
	details					text
);
CREATE INDEX jobs_category_org_id ON jobs_category(org_id);

ALTER TABLE department_roles ADD jobs_category_id		integer references jobs_category;


INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Accounting');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Banking and Financial Services');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'CEO');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'General Management');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Creative and Design');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Customer Service and Call Centre');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Education and Training');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Engineering and Construction');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Farming and Agribusiness');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Government');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Healthcare and Pharmaceutical');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Human Resources');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Insurance');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'ICT');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Telecoms');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Legal');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Manufacturing');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Marketing, Media and Brand');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'NGO, Community and Social Development');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Office and Admin');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Project and Programme Management');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Research, Science and Biotech');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Retail');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Sales');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Security');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Strategy and Consulting');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Tourism and Travel');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Trades and Services');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Transport and Logistics');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Internships and Volunteering');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Real Estate');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Hospitality');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Other');

CREATE OR REPLACE FUNCTION ins_applications(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	v_entity_id				integer;
	v_application_id		integer;
	v_sys_email_id			integer;
	v_address				integer;
	c_education_id			integer;
	c_referees				integer;
	reca					RECORD;
	msg 					varchar(120);
BEGIN
	SELECT application_id INTO v_application_id
	FROM applications 
	WHERE (intake_id = $1::int) AND (entity_id = $2::int);
	
	SELECT org_id, entity_id, previous_salary, expected_salary INTO reca
	FROM applicants
	WHERE (entity_id = $2::int);
	v_entity_id := reca.entity_id;
	IF(reca.entity_id is null) THEN
		SELECT org_id, entity_id, basic_salary as previous_salary, basic_salary as expected_salary INTO reca
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
	ELSE
		v_application_id := nextval('applications_application_id_seq');
		INSERT INTO applications (application_id, intake_id, org_id, entity_id, previous_salary, expected_salary, approve_status)
		VALUES (v_application_id, $1::int, reca.org_id, reca.entity_id, reca.previous_salary, reca.expected_salary, 'Completed');
		
		SELECT sys_email_id INTO v_sys_email_id FROM sys_emails
		WHERE (use_type = 10) AND (org_id = reca.org_id);
		
		INSERT INTO sys_emailed (sys_email_id, org_id, table_id, table_name, email_type)
		VALUES (v_sys_email_id, reca.org_id, v_application_id, 'applications', 10);
		
		msg := 'Added Job application';
	END IF;

	return msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ins_interns(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	v_intern_id			integer;
	v_org_id			integer;
	v_sys_email_id		integer;
	msg					varchar(120);
BEGIN
	SELECT intern_id INTO v_intern_id FROM interns 
	WHERE (internship_id = $1::int) AND (entity_id = $2::int);
	
	SELECT org_id INTO v_org_id FROM internships 
	WHERE (internship_id = $1::int);

	IF v_intern_id is null THEN
		v_intern_id := nextval('interns_intern_id_seq');
		INSERT INTO interns (intern_id, org_id, internship_id, entity_id, approve_status)
		VALUES (v_intern_id, v_org_id, $1::int, $2::int, 'Completed');
		
		SELECT sys_email_id INTO v_sys_email_id FROM sys_emails
		WHERE (use_type = 11) AND (org_id = v_org_id);
		
		INSERT INTO sys_emailed (sys_email_id, org_id, table_id, table_name, email_type)
		VALUES (v_sys_email_id, v_org_id, v_intern_id, 'interns', 11);
		
		msg := 'Added internship application';
	ELSE
		msg := 'There is another application for the internship.';
	END IF;

	return msg;
END;
$$ LANGUAGE plpgsql;


------------ End of APHRC change request


UPDATE Tax_Types SET use_key = 3 WHERE Tax_Type_ID IN (1, 4, 8, 11);

CREATE FUNCTION get_phase_entitys(integer) RETURNS varchar(320) AS $$
DECLARE
    myrec			RECORD;
	myentitys		varchar(320);
BEGIN
	myentitys := null;
	FOR myrec IN SELECT entitys.entity_name
		FROM entitys INNER JOIN entity_subscriptions ON entitys.entity_id = entity_subscriptions.entity_id
		WHERE (entity_subscriptions.entity_type_id = $1) LOOP

		IF (myentitys is null) THEN
			IF (myrec.entity_name is not null) THEN
				myentitys := myrec.entity_name;
			END IF;
		ELSE
			IF (myrec.entity_name is not null) THEN
				myentitys := myemail || ', ' || myrec.entity_name;
			END IF;
		END IF;

	END LOOP;

	RETURN myentitys;
END;
$$ LANGUAGE plpgsql;


ALTER TABLE orgs ADD default_country_id varchar(2) default 'KE';

CREATE OR REPLACE FUNCTION ins_loans() RETURNS trigger AS $$
DECLARE
	v_default_interest	real;
	v_reducing_balance	boolean;
BEGIN

	SELECT default_interest, reducing_balance INTO v_default_interest, v_reducing_balance
	FROM loan_types 
	WHERE (loan_type_id = NEW.loan_type_id);
	
	IF(NEW.interest is null)THEN
		NEW.interest := v_default_interest;
	END IF;
	IF (NEW.reducing_balance is null)THEN
		NEW.reducing_balance := v_reducing_balance;
	END IF;
	IF(NEW.monthly_repayment is null) THEN
		NEW.monthly_repayment := 0;
	END IF;
	IF (NEW.repayment_period is null)THEN
		NEW.repayment_period := 0;
	END IF;
	

	IF(NEW.principle is null)THEN
		RAISE EXCEPTION 'You have to enter a principle amount';
	ELSIF((NEW.monthly_repayment = 0) AND (NEW.repayment_period = 0))THEN
		RAISE EXCEPTION 'You have need to enter either monthly repayment amount or repayment period';
	ELSIF((NEW.monthly_repayment = 0) AND (NEW.repayment_period < 1))THEN
		RAISE EXCEPTION 'The repayment period should be greater than 0';
	ELSIF((NEW.repayment_period = 0) AND (NEW.monthly_repayment < 1))THEN
		RAISE EXCEPTION 'The monthly repayment should be greater than 0';
	ELSIF((NEW.monthly_repayment = 0) AND (NEW.repayment_period > 0))THEN
		NEW.monthly_repayment := NEW.principle / NEW.repayment_period;
	ELSIF((NEW.repayment_period = 0) AND (NEW.monthly_repayment > 0))THEN
		NEW.repayment_period := NEW.principle / NEW.monthly_repayment;
	END IF;
	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION loan_aplication(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	msg 				varchar(120);
BEGIN
	msg := 'Loan applied';
	
	UPDATE loans SET approve_status = 'Completed'
	WHERE (loan_id = CAST($1 as int)) AND (approve_status = 'Draft');

	return msg;
END;
$$ LANGUAGE plpgsql;
    
   
CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON employee_advances
    FOR EACH ROW EXECUTE PROCEDURE upd_action();
    
    
CREATE OR REPLACE FUNCTION advance_aplication(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	msg 				varchar(120);
BEGIN
	msg := 'Advance applied';
	
	UPDATE employee_advances SET approve_status = 'Completed'
	WHERE (employee_advance_id = CAST($1 as int)) AND (approve_status = 'Draft');

	return msg;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION ins_employee_advances() RETURNS trigger AS $$
DECLARE
	v_period_id			integer;
BEGIN

	IF(NEW.pay_upto is null)THEN
		NEW.pay_upto := current_date;
	END IF;
	IF(NEW.payment_amount is null)THEN
		NEW.payment_amount := NEW.amount;
		NEW.pay_period := 1;
	END IF;

	IF((NEW.approve_status = 'Approved') AND (OLD.approve_status = 'Completed'))THEN
		SELECT max(period_id) INTO v_period_id
		FROM periods
		WHERE (closed = false);
		
		SELECT max(employee_month_id) INTO NEW.employee_month_id
		FROM employee_month
		WHERE (period_id = v_period_id) AND (entity_id = NEW.entity_id);
		
		IF(v_period_id is null)THEN
			RAISE EXCEPTION 'You need to have the current period approved';
		ELSIF(NEW.employee_month_id is null)THEN
			RAISE EXCEPTION 'You need to have the staff in the current active month';
		END IF;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_employee_advances BEFORE INSERT OR UPDATE ON employee_advances
    FOR EACH ROW EXECUTE PROCEDURE ins_employee_advances();
    
DROP VIEW vw_intern_evaluations;
DROP VIEW vw_applicants;
    
CREATE VIEW vw_applicants AS
	SELECT sys_countrys.sys_country_id, sys_countrys.sys_country_name, applicants.entity_id, applicants.surname, 
		applicants.org_id, applicants.first_name, applicants.middle_name, applicants.date_of_birth, applicants.nationality, 
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
		LEFT JOIN vw_employment_max ON applicants.entity_id = vw_employment_max.entity_id;
		
		
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
		
CREATE OR REPLACE FUNCTION get_leave_taken(integer, integer) RETURNS real AS $$
	SELECT COALESCE(sum(leave_days), 0)
	FROM employee_leave
	WHERE (approve_status = 'Approved') AND (to_char(leave_from, 'YYYY') = to_char(current_date, 'YYYY'))
		AND (entity_id = $1) AND (leave_type_id = $2);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION ins_employees() RETURNS trigger AS $$
DECLARE
	v_entity_type_id	integer;
	v_use_type			integer;
	v_org_sufix 		varchar(4);
	v_first_password	varchar(12);
	v_user_count		integer;
	v_user_name			varchar(120);
BEGIN
	IF (TG_OP = 'INSERT') THEN
		IF(NEW.entity_id IS NULL) THEN
			SELECT org_sufix INTO v_org_sufix
			FROM orgs WHERE (org_id = NEW.org_id);
			
			IF(v_org_sufix is null)THEN v_org_sufix := ''; END IF;

			NEW.entity_id := nextval('entitys_entity_id_seq');

			IF(NEW.employee_id is null) THEN
				NEW.employee_id := NEW.entity_id;
			END IF;
			
			SELECT entity_type_id INTO v_entity_type_id
			FROM entity_types 
			WHERE (org_id = NEW.org_id) AND (use_key = 1);

			v_first_password := first_password();
			v_user_name := lower(substr(NEW.First_name, 1, 1) || NEW.Surname);

			SELECT count(entity_id) INTO v_user_count
			FROM entitys
			WHERE (org_id = NEW.org_id) AND (user_name = v_user_name);
			IF(v_user_count > 0) THEN v_user_name := v_user_name || v_user_count::varchar; END IF;

			INSERT INTO entitys (entity_id, org_id, entity_type_id, use_function,
				entity_name, user_name, function_role, 
				first_password, entity_password)
			VALUES (NEW.entity_id, NEW.org_id, v_entity_type_id, 1, 
				(NEW.Surname || ' ' || NEW.First_name || ' ' || COALESCE(NEW.Middle_name, '')),
				v_user_name, 'staff',
				v_first_password, md5(v_first_password));
		END IF;

		v_use_type := 2;
		IF(NEW.gender = 'M')THEN v_use_type := 3; END IF;

		INSERT INTO employee_leave_types (entity_id, org_id, leave_type_id, leave_balance)
		SELECT NEW.entity_id, NEW.org_id, leave_type_id, 0
		FROM leave_types
		WHERE (org_id = NEW.org_id) AND ((use_type = 1) OR (use_type = v_use_type));
	ELSIF (TG_OP = 'UPDATE') THEN
		UPDATE entitys  SET entity_name = (NEW.Surname || ' ' || NEW.First_name || ' ' || COALESCE(NEW.Middle_name, ''))
		WHERE entity_id = NEW.entity_id;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

