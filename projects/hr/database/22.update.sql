

CREATE OR REPLACE FUNCTION ins_address() RETURNS trigger AS $$
DECLARE
	v_address_id		integer;
BEGIN
	SELECT address_id INTO v_address_id
	FROM address WHERE (is_default = true)
		AND (table_name = NEW.table_name) AND (table_id = NEW.table_id) AND (address_id <> NEW.address_id);

	IF(NEW.is_default is null)THEN
		NEW.is_default := false;
	END IF;

	IF(NEW.is_default = true) AND (v_address_id is not null) THEN
		RAISE EXCEPTION 'Only one default Address allowed.';
	ELSIF (NEW.is_default = false) AND (v_address_id is null) THEN
		NEW.is_default := true;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TABLE skill_levels (
	skill_level_id			serial primary key,
	org_id					integer references orgs,
	skill_level_name		varchar(50),
	details					text
);
CREATE INDEX skill_levels_org_id ON skill_levels(org_id);


INSERT INTO skill_levels (org_id, skill_level_name) VALUES (0, 'Basic');
INSERT INTO skill_levels (org_id, skill_level_name) VALUES (0, 'Intermediate');
INSERT INTO skill_levels (org_id, skill_level_name) VALUES (0, 'Advanced');

ALTER TABLE skills ADD skill_level_id			integer references skill_levels;
UPDATE skills SET skill_level_id = skill_level;

DROP VIEW vw_skills;
CREATE VIEW vw_skills AS
	SELECT vw_skill_types.skill_category_id, vw_skill_types.skill_category_name, vw_skill_types.skill_type_id, 
		vw_skill_types.basic, vw_skill_types.intermediate, vw_skill_types.advanced, 
		entitys.entity_id, entitys.entity_name, 
		skill_levels.skill_level_id, skill_levels.skill_level_name,
		skills.skill_id, skills.aquired, skills.training_date, 
		skills.org_id, skills.trained, skills.training_institution, skills.training_cost, 
		skills.details,
		
		(CASE WHEN vw_skill_types.skill_type_id = 0 THEN skills.state_skill
			ELSE vw_skill_types.skill_type_name END) as skill_type_name
		
	FROM skills INNER JOIN entitys ON skills.entity_id = entitys.entity_id
		INNER JOIN vw_skill_types ON skills.skill_type_id = vw_skill_types.skill_type_id
		INNER JOIN skill_levels ON skills.skill_level_id = skill_levels.skill_level_id;
		
		
CREATE OR REPLACE FUNCTION ins_skills() RETURNS trigger AS $$
BEGIN
	IF((NEW.skill_level_id is null) AND (NEW.skill_level is not null)) THEN
		NEW.skill_level_id := NEW.skill_level;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
	
CREATE TRIGGER ins_skills BEFORE INSERT OR UPDATE ON skills
    FOR EACH ROW EXECUTE PROCEDURE ins_skills();
		
DROP VIEW vw_contracting;
DROP VIEW vw_applications;
DROP VIEW vw_intake;

CREATE VIEW vw_intake AS
	SELECT vw_department_roles.department_id, vw_department_roles.department_name, vw_department_roles.department_description, 
		vw_department_roles.department_duties, vw_department_roles.department_role_id, vw_department_roles.department_role_name,
		vw_department_roles.parent_role_name,
		vw_department_roles.job_description, vw_department_roles.job_requirements, vw_department_roles.duties, 
		vw_department_roles.performance_measures, 
		
		locations.location_id, locations.location_name, pay_groups.pay_group_id, pay_groups.pay_group_name, 
		pay_scales.pay_scale_id, pay_scales.pay_scale_name, 
		orgs.org_name, orgs.details as org_detail,
		
		intake.org_id, intake.intake_id, intake.opening_date, intake.closing_date, intake.positions, intake.contract, 
		intake.contract_period, intake.details,
		
		(vw_department_roles.department_name || ', ' || vw_department_roles.department_role_name || ', ' || to_char(intake.opening_date, 'YYYY, Mon')) as intake_disp,
		('<a href="index.jsp?view=14:0:0&data=' || intake.intake_id || '">Apply For Post</a>') as apply
		
		
	FROM intake INNER JOIN vw_department_roles ON intake.department_role_id = vw_department_roles.department_role_id
		INNER JOIN locations ON intake.location_id = locations.location_id
		INNER JOIN pay_groups ON intake.pay_group_id = pay_groups.pay_group_id
		INNER JOIN pay_scales ON intake.pay_scale_id = pay_scales.pay_scale_id
		INNER JOIN orgs ON intake.org_id = orgs.org_id;

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
		