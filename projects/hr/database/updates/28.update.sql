
CREATE OR REPLACE FUNCTION compute_loans(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	v_period_id			integer;
	v_org_id			integer;
	msg					varchar(120);
BEGIN

	SELECT period_id, org_id INTO v_period_id, v_org_id
	FROM periods
	WHERE (period_id = $1::integer);
	
	DELETE FROM loan_monthly WHERE period_id = v_period_id;

	INSERT INTO loan_monthly (period_id, org_id, loan_id, repayment, interest_amount, interest_paid)
	SELECT v_period_id, org_id, loan_id, monthly_repayment, (loan_balance * interest / 1200), (loan_balance * interest / 1200)
	FROM vw_loans 
	WHERE (loan_balance > 0) AND (approve_status = 'Approved') AND (reducing_balance =  true) AND (org_id = v_org_id);

	INSERT INTO loan_monthly (period_id, org_id, loan_id, repayment, interest_amount, interest_paid)
	SELECT v_period_id, org_id, loan_id, monthly_repayment, (principle * interest / 1200), (principle * interest / 1200)
	FROM vw_loans 
	WHERE (loan_balance > 0) AND (approve_status = 'Approved') AND (reducing_balance =  false) AND (org_id = v_org_id);

	msg := 'Loans re-computed';

	RETURN msg;
END;
$$ LANGUAGE plpgsql;

ALTER TABLE orgs ADD pcc varchar(12);

DROP VIEW vw_trx;
DROP VIEW vw_entitys;
DROP VIEW vw_entity_address;
DROP VIEW vw_orgs;

CREATE VIEW vw_orgs AS
	SELECT orgs.org_id, orgs.org_name, orgs.is_default, orgs.is_active, orgs.logo, 
		orgs.pin, orgs.pcc, orgs.details,

		vw_org_address.org_sys_country_id, vw_org_address.org_sys_country_name,
		vw_org_address.org_address_id, vw_org_address.org_table_name,
		vw_org_address.org_post_office_box, vw_org_address.org_postal_code,
		vw_org_address.org_premises, vw_org_address.org_street, vw_org_address.org_town,
		vw_org_address.org_phone_number, vw_org_address.org_extension,
		vw_org_address.org_mobile, vw_org_address.org_fax, vw_org_address.org_email, vw_org_address.org_website
	FROM orgs LEFT JOIN vw_org_address ON orgs.org_id = vw_org_address.org_table_id;

CREATE VIEW vw_entity_address AS
	SELECT vw_address.address_id, vw_address.address_name,
		vw_address.sys_country_id, vw_address.sys_country_name, vw_address.table_id, vw_address.table_name,
		vw_address.is_default, vw_address.post_office_box, vw_address.postal_code, vw_address.premises,
		vw_address.street, vw_address.town, vw_address.phone_number, vw_address.extension, vw_address.mobile,
		vw_address.fax, vw_address.email, vw_address.website
	FROM vw_address
	WHERE (vw_address.table_name = 'entitys') AND (vw_address.is_default = true);

CREATE VIEW vw_entitys AS
	SELECT vw_orgs.org_id, vw_orgs.org_name, vw_orgs.is_default as org_is_default,
		vw_orgs.is_active as org_is_active, vw_orgs.logo as org_logo,

		vw_orgs.org_sys_country_id, vw_orgs.org_sys_country_name,
		vw_orgs.org_address_id, vw_orgs.org_table_name,
		vw_orgs.org_post_office_box, vw_orgs.org_postal_code,
		vw_orgs.org_premises, vw_orgs.org_street, vw_orgs.org_town,
		vw_orgs.org_phone_number, vw_orgs.org_extension,
		vw_orgs.org_mobile, vw_orgs.org_fax, vw_orgs.org_email, vw_orgs.org_website,

		vw_entity_address.address_id, vw_entity_address.address_name,
		vw_entity_address.sys_country_id, vw_entity_address.sys_country_name, vw_entity_address.table_name,
		vw_entity_address.is_default, vw_entity_address.post_office_box, vw_entity_address.postal_code,
		vw_entity_address.premises, vw_entity_address.street, vw_entity_address.town,
		vw_entity_address.phone_number, vw_entity_address.extension, vw_entity_address.mobile,
		vw_entity_address.fax, vw_entity_address.email, vw_entity_address.website,

		entitys.entity_id, entitys.entity_name, entitys.user_name, entitys.super_user, entitys.entity_leader,
		entitys.date_enroled, entitys.is_active, entitys.entity_password, entitys.first_password,
		entitys.function_role, entitys.primary_email, entitys.primary_telephone,
		entity_types.entity_type_id, entity_types.entity_type_name,
		entity_types.entity_role, entity_types.use_key
	FROM (entitys LEFT JOIN vw_entity_address ON entitys.entity_id = vw_entity_address.table_id)
		INNER JOIN vw_orgs ON entitys.org_id = vw_orgs.org_id
		INNER JOIN entity_types ON entitys.entity_type_id = entity_types.entity_type_id;

ALTER TABLE interns ADD phone_mobile			varchar(50);

DROP VIEW vw_intern_evaluations;
DROP VIEW vw_interns;
DROP VIEW vw_internships;

CREATE VIEW vw_internships AS
	SELECT departments.department_id, departments.department_name, internships.internship_id, internships.opening_date, 
		orgs.org_id, orgs.org_name, orgs.details as org_details,
		internships.closing_date, internships.positions, internships.location, internships.details
	FROM internships INNER JOIN departments ON internships.department_id = departments.department_id
		INNER JOIN orgs ON internships.org_id = orgs.org_id;

CREATE VIEW vw_interns AS
	SELECT entitys.entity_id, entitys.entity_name, entitys.primary_email, entitys.primary_telephone, 
		vw_internships.department_id, vw_internships.department_name,
		vw_internships.org_name, vw_internships.org_details,
		vw_internships.internship_id, vw_internships.positions, vw_internships.opening_date, vw_internships.closing_date,
		interns.org_id, interns.intern_id, interns.payment_amount, interns.start_date, interns.end_date, 
		interns.application_date, interns.approve_status, interns.action_date, interns.workflow_table_id,
		interns.phone_mobile,
		interns.applicant_comments, interns.review,

		vw_education_max.education_class_name, vw_education_max.date_from, vw_education_max.date_to, 
		vw_education_max.name_of_school, vw_education_max.examination_taken, 
		vw_education_max.grades_obtained, vw_education_max.certificate_number
	FROM interns INNER JOIN entitys ON interns.entity_id = entitys.entity_id
		INNER JOIN vw_internships ON interns.internship_id = vw_internships.internship_id
		LEFT JOIN vw_education_max ON entitys.entity_id = vw_education_max.entity_id;

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
		
ALTER TABLE tax_types ADD use_type				integer default 0 not null;
UPDATE tax_types SET use_type = 3, use_key = 1 WHERE tax_type_id IN (1, 4, 8, 11);

UPDATE employee_tax_types SET tax_identification = a.tax_identification
FROM (SELECT default_tax_types.tax_identification, default_tax_types.tax_type_id, employee_month.employee_month_id
FROM default_tax_types, employee_month WHERE default_tax_types.entity_id = employee_month.entity_id) as a
WHERE employee_tax_types.employee_month_id = a.employee_month_id and (employee_tax_types.tax_type_id = a.tax_type_id);


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


