
CREATE TABLE locations
(
	location_id			serial primary key,
	org_id 				integer references orgs,
	location_name 			character varying(50),
	details			 text
);

ALTER TABLE orgs ADD member_limit integer default 5 not null;
ALTER TABLE orgs ADD transaction_limit integer default 100 not null;
CREATE TABLE applicants (
	entity_id				integer references entitys primary key,
	org_id					integer references orgs,

	person_title			varchar(7),
	surname					varchar(50) not null,
	first_name				varchar(50) not null,
	middle_name				varchar(50),
	applicant_email			varchar(50) not null unique,
	applicant_phone			varchar(50),
	date_of_birth			date,
	gender					varchar(1),
	nationality				char(2) references sys_countrys,
	marital_status 			varchar(2),
	picture_file			varchar(32),
	identity_card			varchar(50),
	language				varchar(320),
	
	previous_salary			real,
	expected_salary			real,
	how_you_heard			varchar(320),
	created					timestamp default current_timestamp,

	field_of_study			text,
	interests				text,
	objective				text,
	details					text
);
CREATE INDEX applicants_org_id ON applicants(org_id);

CREATE TABLE kin_types (
	kin_type_id				serial primary key,
	org_id					integer references orgs,
	kin_type_name			varchar(50),
	details					text
);
CREATE INDEX kin_types_org_id ON kin_types(org_id);

CREATE TABLE kins (
	kin_id					serial primary key,
	entity_id				integer references entitys,
	kin_type_id				integer references kin_types,
	org_id					integer references orgs,
	full_names				varchar(120),
	date_of_birth			date,
	identification			varchar(50),
	relation				varchar(50),
	emergency_contact		boolean default false not null,
	beneficiary				boolean default false not null,
	beneficiary_ps			real,
	details					text
);
CREATE INDEX kins_entity_id ON kins (entity_id);
CREATE INDEX kins_kin_type_id ON kins (kin_type_id);
CREATE INDEX kins_org_id ON kins(org_id);

CREATE VIEW vw_applicants AS
	SELECT sys_countrys.sys_country_id, sys_countrys.sys_country_name, applicants.entity_id, applicants.surname, 
		applicants.org_id, applicants.first_name, applicants.middle_name, applicants.date_of_birth, applicants.nationality, 
		applicants.identity_card, applicants.language, applicants.objective, applicants.interests, applicants.picture_file, applicants.details,
		applicants.person_title, applicants.field_of_study, applicants.applicant_email, applicants.applicant_phone, 
		applicants.previous_salary, applicants.expected_salary,
		(applicants.Surname || ' ' || applicants.First_name || ' ' || COALESCE(applicants.Middle_name, '')) as applicant_name,
		to_char(age(applicants.date_of_birth), 'YY') as applicant_age,
		(CASE WHEN applicants.gender = 'M' THEN 'Male' ELSE 'Female' END) as gender_name,
		(CASE WHEN applicants.marital_status = 'M' THEN 'Married' ELSE 'Single' END) as marital_status_name
	FROM applicants INNER JOIN sys_countrys ON applicants.nationality = sys_countrys.sys_country_id;

CREATE VIEW vw_kins AS
	SELECT entitys.entity_id, entitys.entity_name, kin_types.kin_type_id, kin_types.kin_type_name, 
		kins.org_id, kins.kin_id, kins.full_names, kins.date_of_birth, kins.identification, kins.relation, 
		kins.emergency_contact, kins.beneficiary, kins.beneficiary_ps, kins.details
	FROM kins INNER JOIN entitys ON kins.entity_id = entitys.entity_id
	INNER JOIN kin_types ON kins.kin_type_id = kin_types.kin_type_id;

CREATE OR REPLACE FUNCTION get_default_country(int) RETURNS char(2) AS $$
	SELECT default_country_id::varchar(2)
	FROM orgs
	WHERE (org_id = $1);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_default_currency(int) RETURNS int AS $$
	SELECT currency_id
	FROM orgs
	WHERE (org_id = $1);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION ins_applicants() RETURNS trigger AS $$
DECLARE
	rec 			RECORD;
	v_entity_id		integer;
BEGIN
	IF (TG_OP = 'INSERT') THEN
		
		IF(NEW.entity_id IS NULL) THEN
			SELECT entity_id INTO v_entity_id
			FROM entitys
			WHERE (trim(lower(user_name)) = trim(lower(NEW.applicant_email)));
				
			IF(v_entity_id is null)THEN
				SELECT org_id INTO rec
				FROM orgs WHERE (is_default = true);

				NEW.entity_id := nextval('entitys_entity_id_seq');

				INSERT INTO entitys (entity_id, org_id, entity_type_id, entity_name, User_name, 
					primary_email, primary_telephone, function_role)
				VALUES (NEW.entity_id, rec.org_id, 4, 
					(NEW.Surname || ' ' || NEW.First_name || ' ' || COALESCE(NEW.Middle_name, '')),
					lower(NEW.applicant_email), lower(NEW.applicant_email), NEW.applicant_phone, 'applicant');
			ELSE
				RAISE EXCEPTION 'The username exists use a different one or reset password for the current one';
			END IF;
		END IF;

		INSERT INTO sys_emailed (sys_email_id, table_id, table_name)
		VALUES (1, NEW.entity_id, 'applicant');
	ELSIF (TG_OP = 'UPDATE') THEN
		UPDATE entitys  SET entity_name = (NEW.Surname || ' ' || NEW.First_name || ' ' || COALESCE(NEW.Middle_name, ''))
		WHERE entity_id = NEW.entity_id;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_applicants BEFORE INSERT OR UPDATE ON applicants
    FOR EACH ROW EXECUTE PROCEDURE ins_applicants();

CREATE OR REPLACE FUNCTION upd_action() RETURNS trigger AS $$
DECLARE
	wfid		INTEGER;
	reca		RECORD;
	tbid		INTEGER;
	iswf		BOOLEAN;
	add_flow	BOOLEAN;
BEGIN

	add_flow := false;
	IF(TG_OP = 'INSERT')THEN
		IF (NEW.approve_status = 'Completed')THEN
			add_flow := true;
		END IF;
	ELSE
		IF(OLD.approve_status = 'Draft') AND (NEW.approve_status = 'Completed')THEN
			add_flow := true;
		END IF;
	END IF;
	
	IF(add_flow = true)THEN
		wfid := nextval('workflow_table_id_seq');
		NEW.workflow_table_id := wfid;

		IF(TG_OP = 'UPDATE')THEN
			IF(OLD.workflow_table_id is not null)THEN
				INSERT INTO workflow_logs (org_id, table_name, table_id, table_old_id)
				VALUES (NEW.org_id, TG_TABLE_NAME, wfid, OLD.workflow_table_id);
			END IF;
		END IF;

		FOR reca IN SELECT workflows.workflow_id, workflows.table_name, workflows.table_link_field, workflows.table_link_id
		FROM workflows INNER JOIN entity_subscriptions ON workflows.source_entity_id = entity_subscriptions.entity_type_id
		WHERE (workflows.table_name = TG_TABLE_NAME) AND (entity_subscriptions.entity_id= NEW.entity_id) LOOP
			iswf := false;
			IF(reca.table_link_field is null)THEN
				iswf := true;
			ELSE
				IF(TG_TABLE_NAME = 'entry_forms')THEN
					tbid := NEW.form_id;
				ELSIF(TG_TABLE_NAME = 'employee_leave')THEN
					tbid := NEW.leave_type_id;
				END IF;
				IF(tbid = reca.table_link_id)THEN
					iswf := true;
				END IF;
			END IF;

			IF(iswf = true)THEN
				INSERT INTO approvals (org_id, workflow_phase_id, table_name, table_id, org_entity_id, escalation_days, escalation_hours, approval_level, approval_narrative, to_be_done)
				SELECT org_id, workflow_phase_id, tg_table_name, wfid, new.entity_id, escalation_days, escalation_hours, approval_level, phase_narrative, 'Approve - ' || phase_narrative
				FROM vw_workflow_entitys
				WHERE (table_name = TG_TABLE_NAME) AND (entity_id = NEW.entity_id) AND (workflow_id = reca.workflow_id)
				ORDER BY approval_level, workflow_phase_id;

				UPDATE approvals SET approve_status = 'Completed' 
				WHERE (table_id = wfid) AND (approval_level = 1);
			END IF;
		END LOOP;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_approval_date(integer) RETURNS date AS $$
DECLARE
	v_workflow_table_id		integer;
	v_date					date;
BEGIN
	v_workflow_table_id := $1;

	SELECT action_date INTO v_date
	FROM approvals 
	WHERE (approvals.table_id = v_workflow_table_id) AND (approvals.workflow_phase_id = 6);

	return v_date;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_approver(integer) RETURNS varchar(120) AS $$
DECLARE
	v_workflow_table_id		integer;
	v_approver				varchar(120);
BEGIN
	v_approver :='';
	v_workflow_table_id := $1;

	SELECT entitys.entity_name INTO v_approver
	FROM entitys 
	INNER JOIN approvals ON entitys.entity_id = approvals.app_entity_id
	WHERE (approvals.table_id = v_workflow_table_id) AND (approvals.workflow_phase_id = 6);

	return v_approver;
END;
$$ LANGUAGE plpgsql;

