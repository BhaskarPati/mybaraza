CREATE TABLE sys_menu_msg (
	sys_menu_msg_id			serial primary key,
	menu_id					integer not null,
	menu_name				varchar(50) not null,
	msg						text
);

CREATE TABLE sys_audit_trail (
	sys_audit_trail_id		serial primary key,
	user_id					varchar(50) not null,
	user_ip					varchar(50),
	change_date				timestamp default now() not null,
	table_name				varchar(50) not null,
	record_id				varchar(50) not null,
	change_type				varchar(50) not null,
	narrative				varchar(240)
);

CREATE TABLE sys_audit_details (
	sys_audit_detail_id		serial primary key,
	sys_audit_trail_id		integer references sys_audit_trail,
	new_value				text
);
CREATE INDEX sys_audit_details_sys_audit_trail_id ON sys_audit_details (sys_audit_trail_id);

CREATE TABLE sys_errors (
	sys_error_id			serial primary key,
	sys_error				varchar(240) not null,
	error_message			text not null
);

CREATE TABLE sys_continents (
	sys_continent_id		char(2) primary key,
	sys_continent_name		varchar(120) unique
);

CREATE TABLE sys_countrys (
	sys_country_id			char(2) primary key,
	sys_continent_id		char(2) references sys_continents,
	sys_country_code		varchar(3),
	sys_country_number		varchar(3),
	sys_phone_code			varchar(3),
	sys_country_name		varchar(120) unique,
	sys_currency_name		varchar(50),
	sys_currency_cents		varchar(50),
	sys_currency_code		varchar(3),
	sys_currency_exchange	real
);
CREATE INDEX sys_countrys_sys_continent_id ON sys_countrys (sys_continent_id);

CREATE TABLE currency (
	currency_id				serial primary key,
	currency_name			varchar(50),
	currency_symbol			varchar(3)
);

CREATE TABLE orgs(
  org_id 				serial primary key,
  currency_id 			integer ,
  parent_org_id 		integer,
  org_name 				character varying(50) NOT NULL,
  org_sufix 			character varying(4) NOT NULL,
  is_default 			boolean NOT NULL DEFAULT true,
  is_active 			boolean NOT NULL DEFAULT true,
  logo 					character varying(50),
  pin 					character varying(50),
  details 				text,
  pcc 					character varying(4),
  sp_id 				character varying(16),
  service_id 			character varying(32),
  sender_name 			character varying(16),
  sms_rate 				real NOT NULL DEFAULT 2,
  show_fare 			boolean DEFAULT false,
  gds_free_field 		integer DEFAULT 96,
  credit_limit 			real NOT NULL DEFAULT 0,
  UNIQUE (org_name,org_sufix)
);

CREATE INDEX orgs_currency_id  ON orgs(currency_id);


CREATE INDEX orgs_parent_org_id  ON orgs  (parent_org_id);



ALTER TABLE currency ADD org_id			integer references orgs;
CREATE INDEX currency_org_id ON currency (org_id);
INSERT INTO currency (currency_id, currency_name, currency_symbol) VALUES (1, 'Kenya Shillings', 'KES');
INSERT INTO currency (currency_id, currency_name, currency_symbol) VALUES (2, 'US Dollar', 'USD');
INSERT INTO currency (currency_id, currency_name, currency_symbol) VALUES (3, 'British Pound', 'BPD');
INSERT INTO currency (currency_id, currency_name, currency_symbol) VALUES (4, 'Euro', 'ERO');
INSERT INTO orgs (org_id, org_name, org_sufix, currency_id, logo) VALUES (0, 'default', 'dc', 1, 'logo.png');
UPDATE currency SET org_id = 0;
SELECT pg_catalog.setval('currency_currency_id_seq', 4, true);

CREATE TABLE currency_rates (
	currency_rate_id		serial primary key,
	currency_id				integer references currency,
	org_id					integer references orgs,
	exchange_date			date default current_date not null,
	exchange_rate			real default 1 not null
);
CREATE INDEX currency_rates_org_id ON currency_rates (org_id);
CREATE INDEX currency_rates_currency_id ON currency_rates (currency_id);
INSERT INTO currency_rates (currency_rate_id, org_id, currency_id, exchange_rate)
VALUES (0, 0, 1, 1);

CREATE TABLE sys_queries (
	sys_queries_id			serial primary key,
	org_id					integer references orgs,
	sys_query_Name			varchar(50),
	query_date				timestamp not null default now(),
	query_text				text,
	query_params			text,
	UNIQUE(org_id, sys_query_Name)
);
CREATE INDEX sys_queries_org_id ON sys_queries (org_id);

CREATE TABLE sys_news (
	sys_news_id				serial primary key,
	org_id					integer references orgs,
	sys_news_group			integer,
	sys_news_title			varchar(240) not null,
	publish					boolean default false not null,
	details					text
);
CREATE INDEX sys_news_org_id ON sys_news (org_id);

CREATE TABLE sys_files (
	sys_file_id				serial primary key,
	org_id					integer references orgs,
	table_id				integer,
	table_name				varchar(50),
	file_name				varchar(320),
	file_type				varchar(320),
	file_size				integer,
	narrative				varchar(320),
	details					text
);
CREATE INDEX sys_files_org_id ON sys_files (org_id);
CREATE INDEX sys_files_table_id ON sys_files (table_id);

CREATE TABLE address_types (
	address_type_id			serial primary key,
	org_id					integer references orgs,
	address_type_name		varchar(50)
);
CREATE INDEX address_types_org_id ON address_types (org_id);

CREATE TABLE address (
	address_id				serial primary key,
	address_type_id			integer references address_types,
	sys_country_id			char(2) references sys_countrys,
	org_id					integer references orgs,
	address_name			varchar(120),
	table_name				varchar(32),
	table_id				integer,
	post_office_box			varchar(50),
	postal_code				varchar(12),
	premises				varchar(120),
	street					varchar(120),
	town					varchar(50),
	phone_number			varchar(150),
	extension				varchar(15),
	mobile					varchar(150),
	fax						varchar(150),
	email					varchar(120),
	website					varchar(120),
	is_default				boolean,
	first_password			varchar(32),
	details					text
);
CREATE INDEX address_address_type_id ON address (address_type_id);
CREATE INDEX address_sys_country_id ON address (sys_country_id);
CREATE INDEX address_org_id ON address (org_id);
CREATE INDEX address_table_name ON address (table_name);
CREATE INDEX address_table_id ON address (table_id);

CREATE TABLE entity_types (
	entity_type_id			serial primary key,
	org_id					integer references orgs,
	entity_type_name		varchar(50) unique,
	entity_role				varchar(240),
	use_key					integer default 0 not null,
	start_view				varchar(120),
	group_email				varchar(120),
	Description				text,
	Details					text
);
CREATE INDEX entity_types_org_id ON entity_types (org_id);

CREATE TABLE entitys(
  entity_id 					serial primary key,
  entity_type_id 				integer NOT NULL  REFERENCES entity_types ,
  org_id 						integer NOT NULL  REFERENCES orgs,
  entity_name 					character varying(120) NOT NULL,
  user_name 					character varying(120),
  primary_email 				character varying(120),
  primary_telephone 			character varying(50),
  super_user 					boolean NOT NULL DEFAULT false,
  entity_leader 				boolean NOT NULL DEFAULT false,
  no_org 						boolean NOT NULL DEFAULT false,
  function_role 				character varying(240),
  date_enroled 					timestamp without time zone DEFAULT now(),
  is_active 					boolean DEFAULT true,
  entity_password 				character varying(64) NOT NULL DEFAULT md5('baraza'::text),
  first_password 				character varying(64) NOT NULL DEFAULT 'baraza'::character varying,
  new_password 					character varying(64),
  start_url 					character varying(64),
  is_picked 					boolean NOT NULL DEFAULT false,
  details 						text,
  son 							character varying(7),
  phone_ph 						boolean DEFAULT true,
  phone_pa 						boolean DEFAULT false,
  phone_pb 						boolean DEFAULT false,
  phone_pt 						boolean DEFAULT false,
   UNIQUE (org_id, user_name)
);
CREATE INDEX entitys_entity_type_id ON entitys (entity_type_id);
CREATE INDEX entitys_org_id ON entitys (org_id);
CREATE INDEX entitys_user_name ON entitys (user_name);

CREATE TABLE subscription_levels (
	subscription_level_id	serial primary key,
	org_id					integer references orgs,
	subscription_level_name	varchar(50),
	details					text
);
CREATE INDEX subscription_levels_org_id ON subscription_levels (org_id);

CREATE TABLE entity_subscriptions (
	entity_subscription_id	serial primary key,
	entity_type_id			integer not null references entity_types,
	entity_id				integer not null references entitys,
	subscription_level_id	integer not null references subscription_levels,
	org_id					integer references orgs,
	details					text,
	UNIQUE(entity_id, entity_type_id)
);
CREATE INDEX entity_subscriptions_entity_type_id ON entity_subscriptions (entity_type_id);
CREATE INDEX entity_subscriptions_entity_id ON entity_subscriptions (entity_id);
CREATE INDEX entity_subscriptions_subscription_level_id ON entity_subscriptions (subscription_level_id);
CREATE INDEX entity_subscriptions_org_id ON entity_subscriptions (org_id);

CREATE TABLE reporting (
	reporting_id			serial primary key,
	entity_id				integer references entitys,
	report_to_id			integer references entitys,
	org_id					integer references orgs,
	date_from				date,
	date_to					date,
	reporting_level			integer default 1 not null,
	primary_report			boolean default true not null,
	is_active				boolean default true not null,
	ps_reporting			real,
	details					text
);
CREATE INDEX reporting_entity_id ON reporting(entity_id);
CREATE INDEX reporting_report_to_id ON reporting(report_to_id);
CREATE INDEX reporting_org_id ON reporting(org_id);

CREATE TABLE sys_logins (
	sys_login_id			serial primary key,
	entity_id				integer references entitys,
	login_time				timestamp default now(),
	login_ip				varchar(64),
	narrative				varchar(240)
);
CREATE INDEX sys_logins_entity_id ON sys_logins (entity_id);

CREATE TABLE sys_reset (
	sys_reset_id			serial primary key,
	entity_id				integer references entitys,
	org_id					integer references orgs,
	request_email			varchar(320),
	request_time			timestamp default now(),
	login_ip				varchar(64),
	narrative				varchar(240)
);
CREATE INDEX sys_reset_entity_id ON sys_reset (entity_id);
CREATE INDEX sys_reset_org_id ON sys_reset (org_id);

CREATE TABLE sys_dashboard (
	sys_dashboard_id		serial primary key,
	entity_id				integer references entitys,
	org_id					integer references orgs,
	narrative				varchar(240),
	details					text
);
CREATE INDEX sys_dashboard_entity_id ON sys_dashboard (entity_id);
CREATE INDEX sys_dashboard_org_id ON sys_dashboard (org_id);

CREATE TABLE sys_emails (
	sys_email_id			serial primary key,
	org_id					integer references orgs,
	sys_email_name			varchar(50),
	default_email			varchar(120),
	title					varchar(240) not null,
	details					text
);
CREATE INDEX sys_emails_org_id ON sys_emails (org_id);

CREATE TABLE sys_emailed (
	sys_emailed_id			serial primary key,
	sys_email_id			integer references sys_emails,
	org_id					integer references orgs,
	table_id				integer,
	table_name				varchar(50),
	email_type				integer default 1 not null,
	emailed					boolean default false not null,
	created					timestamp default current_timestamp,
	narrative				varchar(240),
	mail_body				text
);
CREATE INDEX sys_emailed_sys_email_id ON sys_emailed (sys_email_id);
CREATE INDEX sys_emailed_org_id ON sys_emailed (org_id);
CREATE INDEX sys_emailed_table_id ON sys_emailed (table_id);

CREATE TABLE workflows (
	workflow_id				serial primary key,
	source_entity_id		integer not null references entity_types,
	org_id					integer references orgs,
	workflow_name			varchar(240) not null,
	table_name				varchar(64),
	table_link_field		varchar(64),
	table_link_id			integer,
	approve_email			text,
	reject_email			text,
	approve_file			varchar(320),
	reject_file				varchar(320),
	details					text
);
CREATE INDEX workflows_source_entity_id ON workflows (source_entity_id);
CREATE INDEX workflows_org_id ON workflows (org_id);

CREATE TABLE workflow_phases (
	workflow_phase_id		serial primary key,
	workflow_id				integer not null references workflows,
	approval_entity_id		integer not null references entity_types,
	org_id					integer references orgs,
	approval_level			integer default 1 not null,
	return_level			integer default 1 not null,
	escalation_days			integer default 0 not null,
	escalation_hours		integer default 3 not null,
	required_approvals		integer default 1 not null,
	reporting_level			integer default 1 not null,
	use_reporting			boolean default false not null,
	advice					boolean default false not null,
	notice					boolean default false not null,
	phase_narrative			varchar(240),
	advice_email			text,
	notice_email			text,
	advice_file				varchar(320),
	notice_file				varchar(320),
	details					text
);
CREATE INDEX workflow_phases_workflow_id ON workflow_phases (workflow_id);
CREATE INDEX workflow_phases_approval_entity_id ON workflow_phases (approval_entity_id);
CREATE INDEX workflow_phases_org_id ON workflow_phases (org_id);

CREATE TABLE checklists (
	checklist_id			serial primary key,
	workflow_phase_id		integer not null references workflow_phases,
	org_id					integer references orgs,
	checklist_number		integer,
	manditory				boolean default false not null,
	requirement				text,
	details					text
);
CREATE INDEX checklists_workflow_phase_id ON checklists (workflow_phase_id);
CREATE INDEX checklists_org_id ON checklists (org_id);

CREATE TABLE workflow_sql (
	workflow_sql_id			integer primary key,
	workflow_phase_id		integer not null references workflow_phases,
	org_id					integer references orgs,
	workflow_sql_name		varchar(50),
	is_condition			boolean default false,
	is_action				boolean default false,
	message_number			varchar(32),
	ca_sql					text
);
CREATE INDEX workflow_sql_workflow_phase_id ON workflow_sql (workflow_phase_id);
CREATE INDEX workflow_sql_org_id ON workflow_sql (org_id);

CREATE TABLE approvals (
	approval_id				serial primary key,
	workflow_phase_id		integer not null references workflow_phases,
	org_entity_id			integer not null references entitys,
	app_entity_id			integer references entitys,
	org_id					integer references orgs,
	approval_level			integer default 1 not null,
	escalation_days			integer default 0 not null,
	escalation_hours		integer default 3 not null,
	escalation_time			timestamp default now() not null,
	forward_id				integer,
	table_name				varchar(64),
	table_id				integer,
	application_date		timestamp default now() not null,
	completion_date			timestamp,
	action_date				timestamp,
	approve_status			varchar(16) default 'Draft' not null,
	approval_narrative		varchar(240),
	to_be_done				text,
	what_is_done			text,
	review_advice			text,
	details					text
);
CREATE INDEX approvals_workflow_phase_id ON approvals (workflow_phase_id);
CREATE INDEX approvals_org_entity_id ON approvals (org_entity_id);
CREATE INDEX approvals_app_entity_id ON approvals (app_entity_id);
CREATE INDEX approvals_org_id ON approvals (org_id);
CREATE INDEX approvals_forward_id ON approvals (forward_id);
CREATE INDEX approvals_table_id ON approvals (table_id);
CREATE INDEX approvals_approve_status ON approvals (approve_status);

CREATE TABLE approval_checklists (
	approval_checklist_id	serial primary key,
	approval_id				integer not null references approvals,
	checklist_id			integer not null references checklists,
	org_id					integer references orgs,
	requirement				text,
	manditory				boolean default false not null,
	done					boolean default false not null,
	narrative				varchar(320)
);
CREATE INDEX approval_checklists_approval_id ON approval_checklists (approval_id);
CREATE INDEX approval_checklists_checklist_id ON approval_checklists (checklist_id);
CREATE INDEX approval_checklists_org_id ON approval_checklists (org_id);

CREATE TABLE workflow_logs (
	workflow_log_id			serial primary key,
	org_id					integer references orgs,
	table_name				varchar(64),
	table_id				integer,
	table_old_id			integer
);
CREATE INDEX workflow_logs_org_id ON workflow_logs (org_id);

CREATE SEQUENCE workflow_table_id_seq;

CREATE SEQUENCE picture_id_seq;

CREATE TABLE jp_pay (
	jp_id					serial primary key,
	entity_id				integer references entitys,
	org_id					integer references orgs,
	jp_tranid				varchar(320),
	jp_merchant_orderid			integer references passengers,
	jp_amount				real,
	jp_currency				varchar(10),
	jp_timestamp				timestamp default now(),
	jp_password				varchar(240),
	details					text
);
CREATE INDEX jp_pay_entity_id ON jp_pay (entity_id);
CREATE INDEX jp_pay_org_id ON jp_pay (org_id);


CREATE VIEW vw_sys_emailed AS
	SELECT sys_emails.sys_email_id, sys_emails.org_id, sys_emails.sys_email_name, sys_emails.title, sys_emails.details,
		sys_emailed.sys_emailed_id, sys_emailed.table_id, sys_emailed.table_name, sys_emailed.email_type,
		sys_emailed.emailed, sys_emailed.narrative
	FROM sys_emails RIGHT JOIN sys_emailed ON sys_emails.sys_email_id = sys_emailed.sys_email_id;

CREATE VIEW vw_sys_countrys AS
	SELECT sys_continents.sys_continent_id, sys_continents.sys_continent_name,
		sys_countrys.sys_country_id, sys_countrys.sys_country_code, sys_countrys.sys_country_number,
		sys_countrys.sys_phone_code, sys_countrys.sys_country_name
	FROM sys_continents INNER JOIN sys_countrys ON sys_continents.sys_continent_id = sys_countrys.sys_continent_id;

CREATE OR REPLACE VIEW vw_address AS
 SELECT sys_countrys.sys_country_id,
    sys_countrys.sys_country_name,
    address.address_id,
    address.org_id,
    address.address_name,
    address.table_name,
    address.table_id,
    address.post_office_box,
    address.postal_code,
    address.premises,
    address.street,
    address.town,
    address.phone_number,
    address.extension,
    address.mobile,
    address.fax,
    address.email,
    address.is_default,
    address.website,
    address.details,
    address_types.address_type_id,
    address_types.address_type_name
   FROM address
     JOIN sys_countrys ON address.sys_country_id = sys_countrys.sys_country_id
     LEFT JOIN address_types ON address.address_type_id = address_types.address_type_id;

CREATE OR REPLACE VIEW vw_org_address AS
 SELECT vw_address.sys_country_id AS org_sys_country_id,
    vw_address.sys_country_name AS org_sys_country_name,
    vw_address.address_id AS org_address_id,
    vw_address.table_id AS org_table_id,
    vw_address.table_name AS org_table_name,
    vw_address.post_office_box AS org_post_office_box,
    vw_address.postal_code AS org_postal_code,
    vw_address.premises AS org_premises,
    vw_address.street AS org_street,
    vw_address.town AS org_town,
    vw_address.phone_number AS org_phone_number,
    vw_address.extension AS org_extension,
    vw_address.mobile AS org_mobile,
    vw_address.fax AS org_fax,
    vw_address.email AS org_email,
    vw_address.website AS org_website
   FROM vw_address
  WHERE vw_address.table_name::text = 'orgs'::text AND vw_address.is_default = true;

CREATE VIEW vw_address_entitys AS
	SELECT vw_address.address_id, vw_address.address_name, vw_address.table_id, vw_address.table_name,
		vw_address.sys_country_id, vw_address.sys_country_name, vw_address.is_default,
		vw_address.post_office_box, vw_address.postal_code, vw_address.premises, vw_address.street, vw_address.town,
		vw_address.phone_number, vw_address.extension, vw_address.mobile, vw_address.fax, vw_address.email, vw_address.website
	FROM vw_address
	WHERE (vw_address.table_name = 'entitys');

CREATE VIEW vw_org_select AS
	(SELECT org_id, parent_org_id, org_name
	FROM orgs
	WHERE (is_active = true) AND (org_id <> parent_org_id))
	UNION
	(SELECT org_id, org_id, org_name
	FROM orgs
	WHERE (is_active = true));

CREATE OR REPLACE VIEW vw_orgs AS
 SELECT orgs.org_id,
    orgs.org_name,
    orgs.is_default,
    orgs.is_active,
    orgs.logo,
    orgs.details,
    orgs.pcc,
    orgs.gds_free_field,
    orgs.show_fare,
    vw_org_address.org_sys_country_id,
    vw_org_address.org_sys_country_name,
    vw_org_address.org_address_id,
    vw_org_address.org_table_name,
    vw_org_address.org_post_office_box,
    vw_org_address.org_postal_code,
    vw_org_address.org_premises,
    vw_org_address.org_street,
    vw_org_address.org_town,
    vw_org_address.org_phone_number,
    vw_org_address.org_extension,
    vw_org_address.org_mobile,
    vw_org_address.org_fax,
    vw_org_address.org_email,
    vw_org_address.org_website
   FROM orgs
     LEFT JOIN vw_org_address ON orgs.org_id = vw_org_address.org_table_id;

CREATE OR REPLACE VIEW vw_entity_address AS
 SELECT vw_address.address_id,
    vw_address.address_name,
    vw_address.sys_country_id,
    vw_address.sys_country_name,
    vw_address.table_id,
    vw_address.table_name,
    vw_address.is_default,
    vw_address.post_office_box,
    vw_address.postal_code,
    vw_address.premises,
    vw_address.street,
    vw_address.town,
    vw_address.phone_number,
    vw_address.extension,
    vw_address.mobile,
    vw_address.fax,
    vw_address.email,
    vw_address.website
   FROM vw_address
  WHERE vw_address.table_name::text = 'entitys'::text AND vw_address.is_default = true;

CREATE OR REPLACE VIEW vw_entitys AS
 SELECT vw_orgs.org_id,
    vw_orgs.org_name,
    vw_orgs.is_default AS org_is_default,
    vw_orgs.is_active AS org_is_active,
    vw_orgs.logo AS org_logo,
    vw_orgs.org_sys_country_id,
    vw_orgs.org_sys_country_name,
    vw_orgs.org_address_id,
    vw_orgs.org_table_name,
    vw_orgs.org_post_office_box,
    vw_orgs.org_postal_code,
    vw_orgs.org_premises,
    vw_orgs.org_street,
    vw_orgs.org_town,
    vw_orgs.org_phone_number,
    vw_orgs.org_extension,
    vw_orgs.org_mobile,
    vw_orgs.org_fax,
    vw_orgs.org_email,
    vw_orgs.org_website,
    vw_entity_address.address_id,
    vw_entity_address.address_name,
    vw_entity_address.sys_country_id,
    vw_entity_address.sys_country_name,
    vw_entity_address.table_name,
    vw_entity_address.is_default,
    vw_entity_address.post_office_box,
    vw_entity_address.postal_code,
    vw_entity_address.premises,
    vw_entity_address.street,
    vw_entity_address.town,
    vw_entity_address.phone_number,
    vw_entity_address.extension,
    vw_entity_address.mobile,
    vw_entity_address.fax,
    vw_entity_address.email,
    vw_entity_address.website,
    entitys.entity_id,
    entitys.entity_name,
    entitys.user_name,
    entitys.super_user,
    entitys.entity_leader,
    entitys.date_enroled,
    entitys.is_active,
    entitys.entity_password,
    entitys.first_password,
    entitys.function_role,
    entitys.primary_email,
    entitys.primary_telephone,
    entity_types.entity_type_id,
    entity_types.entity_type_name,
    entity_types.entity_role,
    entity_types.use_key
   FROM entitys
     LEFT JOIN vw_entity_address ON entitys.entity_id = vw_entity_address.table_id
     JOIN vw_orgs ON entitys.org_id = vw_orgs.org_id
     JOIN entity_types ON entitys.entity_type_id = entity_types.entity_type_id;
     CREATE OR REPLACE VIEW vw_sys_countrys AS
      SELECT sys_continents.sys_continent_id,
         sys_continents.sys_continent_name,
         sys_countrys.sys_country_id,
         sys_countrys.sys_country_code,
         sys_countrys.sys_country_number,
         sys_countrys.sys_phone_code,
         sys_countrys.sys_country_name
        FROM sys_continents
          JOIN sys_countrys ON sys_continents.sys_continent_id = sys_countrys.sys_continent_id;

CREATE VIEW vw_entity_subscriptions AS
	SELECT entity_types.entity_type_id, entity_types.entity_type_name, entitys.entity_id, entitys.entity_name,
		subscription_levels.subscription_level_id, subscription_levels.subscription_level_name,
		entity_subscriptions.entity_subscription_id, entity_subscriptions.org_id, entity_subscriptions.details
	FROM entity_subscriptions INNER JOIN entity_types ON entity_subscriptions.entity_type_id = entity_types.entity_type_id
		INNER JOIN entitys ON entity_subscriptions.entity_id = entitys.entity_id
		INNER JOIN subscription_levels ON entity_subscriptions.subscription_level_id = subscription_levels.subscription_level_id;

CREATE VIEW vw_reporting AS
	SELECT entitys.entity_id, entitys.entity_name, rpt.entity_id as rpt_id, rpt.entity_name as rpt_name,
		reporting.org_id, reporting.reporting_id, reporting.date_from,
		reporting.date_to, reporting.primary_report, reporting.is_active, reporting.ps_reporting,
		reporting.reporting_level, reporting.details
	FROM reporting INNER JOIN entitys ON reporting.entity_id = entitys.entity_id
		INNER JOIN entitys as rpt ON reporting.report_to_id = rpt.entity_id;

CREATE VIEW vw_workflows AS
	SELECT entity_types.entity_type_id as source_entity_id, entity_types.entity_type_name as source_entity_name,
		workflows.workflow_id, workflows.org_id, workflows.workflow_name, workflows.table_name, workflows.table_link_field,
		workflows.table_link_id, workflows.approve_email, workflows.reject_email,
		workflows.approve_file, workflows.reject_file, workflows.details
	FROM workflows INNER JOIN entity_types ON workflows.source_entity_id = entity_types.entity_type_id;

CREATE VIEW vw_workflow_phases AS
	SELECT vw_workflows.source_entity_id, vw_workflows.source_entity_name, vw_workflows.workflow_id,
		vw_workflows.workflow_name, vw_workflows.table_name, vw_workflows.table_link_field, vw_workflows.table_link_id,
		vw_workflows.approve_email, vw_workflows.reject_email, vw_workflows.approve_file, vw_workflows.reject_file,
		entity_types.entity_type_id as approval_entity_id, entity_types.entity_type_name as approval_entity_name,
		workflow_phases.workflow_phase_id, workflow_phases.org_id, workflow_phases.approval_level,
		workflow_phases.return_level, workflow_phases.escalation_days, workflow_phases.escalation_hours,
		workflow_phases.notice, workflow_phases.notice_email, workflow_phases.notice_file,
		workflow_phases.advice, workflow_phases.advice_email, workflow_phases.advice_file,
		workflow_phases.required_approvals, workflow_phases.use_reporting, workflow_phases.reporting_level,
		workflow_phases.phase_narrative, workflow_phases.details
	FROM (workflow_phases INNER JOIN vw_workflows ON workflow_phases.workflow_id = vw_workflows.workflow_id)
		INNER JOIN entity_types ON workflow_phases.approval_entity_id = entity_types.entity_type_id;

CREATE VIEW vw_workflow_entitys AS
	SELECT vw_workflow_phases.workflow_id, vw_workflow_phases.org_id, vw_workflow_phases.workflow_name, vw_workflow_phases.table_name,
		vw_workflow_phases.table_link_id, vw_workflow_phases.source_entity_id, vw_workflow_phases.source_entity_name,
		vw_workflow_phases.approval_entity_id, vw_workflow_phases.approval_entity_name,
		vw_workflow_phases.workflow_phase_id, vw_workflow_phases.approval_level,
		vw_workflow_phases.return_level, vw_workflow_phases.escalation_days, vw_workflow_phases.escalation_hours,
		vw_workflow_phases.notice, vw_workflow_phases.notice_email, vw_workflow_phases.notice_file,
		vw_workflow_phases.advice, vw_workflow_phases.advice_email, vw_workflow_phases.advice_file,
		vw_workflow_phases.required_approvals, vw_workflow_phases.use_reporting, vw_workflow_phases.phase_narrative,
		entity_subscriptions.entity_subscription_id, entity_subscriptions.entity_id, entity_subscriptions.subscription_level_id
	FROM vw_workflow_phases INNER JOIN entity_subscriptions ON vw_workflow_phases.source_entity_id = entity_subscriptions.entity_type_id;

CREATE VIEW vw_approvals AS
	SELECT vw_workflow_phases.workflow_id, vw_workflow_phases.workflow_name,
		vw_workflow_phases.approve_email, vw_workflow_phases.reject_email,
		vw_workflow_phases.source_entity_id, vw_workflow_phases.source_entity_name,
		vw_workflow_phases.approval_entity_id, vw_workflow_phases.approval_entity_name,
		vw_workflow_phases.workflow_phase_id, vw_workflow_phases.approval_level, vw_workflow_phases.phase_narrative,
		vw_workflow_phases.return_level, vw_workflow_phases.required_approvals,
		vw_workflow_phases.notice, vw_workflow_phases.notice_email, vw_workflow_phases.notice_file,
		vw_workflow_phases.advice, vw_workflow_phases.advice_email, vw_workflow_phases.advice_file,
		vw_workflow_phases.use_reporting,
		approvals.approval_id, approvals.org_id, approvals.forward_id, approvals.table_name, approvals.table_id,
		approvals.completion_date, approvals.escalation_days, approvals.escalation_hours,
		approvals.escalation_time, approvals.application_date, approvals.approve_status, approvals.action_date,
		approvals.approval_narrative, approvals.to_be_done, approvals.what_is_done, approvals.review_advice, approvals.details,
		oe.entity_id as org_entity_id, oe.entity_name as org_entity_name, oe.user_name as org_user_name, oe.primary_email as org_primary_email,
		ae.entity_id as app_entity_id, ae.entity_name as app_entity_name, ae.user_name as app_user_name, ae.primary_email as app_primary_email
	FROM (vw_workflow_phases INNER JOIN approvals ON vw_workflow_phases.workflow_phase_id = approvals.workflow_phase_id)
		INNER JOIN entitys as oe ON approvals.org_entity_id = oe.entity_id
		LEFT JOIN entitys as ae ON approvals.app_entity_id = ae.entity_id;

CREATE VIEW vw_workflow_approvals AS
	SELECT vw_approvals.workflow_id, vw_approvals.org_id, vw_approvals.workflow_name, vw_approvals.approve_email,
		vw_approvals.reject_email, vw_approvals.source_entity_id, vw_approvals.source_entity_name, vw_approvals.table_name,
		vw_approvals.table_id, vw_approvals.org_entity_id, vw_approvals.org_entity_name, vw_approvals.org_user_name,
		vw_approvals.org_primary_email, rt.rejected_count,
		(CASE WHEN rt.rejected_count is null THEN vw_approvals.workflow_name || ' Approved'
			ELSE vw_approvals.workflow_name || ' declined' END) as workflow_narrative
	FROM vw_approvals LEFT JOIN
		(SELECT table_id, count(approval_id) as rejected_count FROM approvals WHERE (approve_status = 'Rejected') AND (approvals.forward_id is null)
		GROUP BY table_id) as rt ON vw_approvals.table_id = rt.table_id
	GROUP BY vw_approvals.workflow_id, vw_approvals.org_id, vw_approvals.workflow_name, vw_approvals.approve_email,
		vw_approvals.reject_email, vw_approvals.source_entity_id, vw_approvals.source_entity_name, vw_approvals.table_name,
		vw_approvals.table_id, vw_approvals.org_entity_id, vw_approvals.org_entity_name, vw_approvals.org_user_name,
		vw_approvals.org_primary_email, rt.rejected_count;

CREATE VIEW vw_approvals_entitys AS
	(SELECT vw_workflow_phases.workflow_id, vw_workflow_phases.workflow_name,
		vw_workflow_phases.source_entity_id, vw_workflow_phases.source_entity_name,
		vw_workflow_phases.approval_entity_id, vw_workflow_phases.approval_entity_name,
		vw_workflow_phases.workflow_phase_id, vw_workflow_phases.approval_level,
		vw_workflow_phases.notice, vw_workflow_phases.notice_email, vw_workflow_phases.notice_file,
		vw_workflow_phases.advice, vw_workflow_phases.advice_email, vw_workflow_phases.advice_file,
		vw_workflow_phases.return_level, vw_workflow_phases.required_approvals, vw_workflow_phases.phase_narrative,
		vw_workflow_phases.use_reporting,
		approvals.approval_id, approvals.org_id, approvals.forward_id, approvals.table_name, approvals.table_id,
		approvals.completion_date, approvals.escalation_days, approvals.escalation_hours,
		approvals.escalation_time, approvals.application_date, approvals.approve_status, approvals.action_date,
		approvals.approval_narrative, approvals.to_be_done, approvals.what_is_done, approvals.review_advice, approvals.details,
		oe.entity_id as org_entity_id, oe.entity_name as org_entity_name, oe.user_name as org_user_name, oe.primary_email as org_primary_email,
		entitys.entity_id, entitys.entity_name, entitys.user_name, entitys.primary_email
	FROM ((vw_workflow_phases INNER JOIN approvals ON vw_workflow_phases.workflow_phase_id = approvals.workflow_phase_id)
		INNER JOIN entitys as oe  ON approvals.org_entity_id = oe.entity_id)
		INNER JOIN entity_subscriptions ON vw_workflow_phases.approval_entity_id = entity_subscriptions.entity_type_id
		INNER JOIN entitys ON entity_subscriptions.entity_id = entitys.entity_id
	WHERE (approvals.forward_id is null) AND (vw_workflow_phases.use_reporting = false))
	UNION
	(SELECT vw_workflow_phases.workflow_id, vw_workflow_phases.workflow_name,
		vw_workflow_phases.source_entity_id, vw_workflow_phases.source_entity_name,
		vw_workflow_phases.approval_entity_id, vw_workflow_phases.approval_entity_name,
		vw_workflow_phases.workflow_phase_id, vw_workflow_phases.approval_level,
		vw_workflow_phases.notice, vw_workflow_phases.notice_email, vw_workflow_phases.notice_file,
		vw_workflow_phases.advice, vw_workflow_phases.advice_email, vw_workflow_phases.advice_file,
		vw_workflow_phases.return_level, vw_workflow_phases.required_approvals, vw_workflow_phases.phase_narrative,
		vw_workflow_phases.use_reporting,
		approvals.approval_id, approvals.org_id, approvals.forward_id, approvals.table_name, approvals.table_id,
		approvals.completion_date, approvals.escalation_days, approvals.escalation_hours,
		approvals.escalation_time, approvals.application_date, approvals.approve_status, approvals.action_date,
		approvals.approval_narrative, approvals.to_be_done, approvals.what_is_done, approvals.review_advice, approvals.details,
		oe.entity_id as org_entity_id, oe.entity_name as org_entity_name, oe.user_name as org_user_name, oe.primary_email as org_primary_email,
		entitys.entity_id, entitys.entity_name, entitys.user_name, entitys.primary_email
	FROM ((vw_workflow_phases INNER JOIN approvals ON vw_workflow_phases.workflow_phase_id = approvals.workflow_phase_id)
		INNER JOIN entitys as oe  ON approvals.org_entity_id = oe.entity_id)
		INNER JOIN reporting ON ((approvals.org_entity_id = reporting.entity_id)
			AND (vw_workflow_phases.reporting_level = reporting.reporting_level))
		INNER JOIN entitys ON reporting.report_to_id = entitys.entity_id
	WHERE (approvals.forward_id is null) AND (reporting.primary_report = true) AND (reporting.is_active = true)
		AND (vw_workflow_phases.use_reporting = true));


CREATE OR REPLACE VIEW tomcat_users AS
    SELECT entitys.user_name,
     entitys.entity_password,
     entity_types.entity_role
    FROM entity_subscriptions
      JOIN entitys ON entity_subscriptions.entity_id = entitys.entity_id
      JOIN entity_types ON entity_subscriptions.entity_type_id = entity_types.entity_type_id
      WHERE entitys.is_active = true;

CREATE OR REPLACE FUNCTION default_currency(varchar(16)) RETURNS integer AS $$
	SELECT orgs.currency_id
	FROM orgs INNER JOIN entitys ON orgs.org_id = entitys.org_id
	WHERE (entitys.entity_id = CAST($1 as integer));
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION ins_address() RETURNS trigger AS $$
DECLARE
	v_address_id		integer;
BEGIN
	SELECT address_id INTO v_address_id
	FROM address WHERE (is_default = true)
		AND (table_name = NEW.table_name) AND (table_id = NEW.table_id) AND (address_id <> NEW.address_id);

	IF(NEW.is_default = true) AND (v_address_id is not null) THEN
		RAISE EXCEPTION 'Only one default Address allowed.';
	ELSIF (NEW.is_default = false) AND (v_address_id is null) THEN
		NEW.is_default := true;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_address BEFORE INSERT OR UPDATE ON address
    FOR EACH ROW EXECUTE PROCEDURE ins_address();

CREATE OR REPLACE FUNCTION first_password() RETURNS varchar(12) AS $$
DECLARE
	rnd integer;
	passchange varchar(12);
BEGIN
	passchange := trunc(random()*1000);
	rnd := trunc(65+random()*25);
	passchange := passchange || chr(rnd);
	passchange := passchange || trunc(random()*1000);
	rnd := trunc(65+random()*25);
	passchange := passchange || chr(rnd);
	rnd := trunc(65+random()*25);
	passchange := passchange || chr(rnd);

	return passchange;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION change_password(varchar(12), varchar(32), varchar(32)) RETURNS varchar(120) AS $$
DECLARE
	old_password 	varchar(64);
	passchange 		varchar(120);
	entityID		integer;
BEGIN
	passchange := 'Password Error';
	entityID := CAST($1 AS INT);
	SELECT Entity_password INTO old_password
	FROM entitys WHERE (entity_id = entityID);

	IF ($2 = '0') THEN
		passchange := first_password();
		UPDATE entitys SET first_password = passchange, Entity_password = md5(passchange) WHERE (entity_id = entityID);
		passchange := 'Password Changed';
	ELSIF (old_password = md5($2)) THEN
		UPDATE entitys SET Entity_password = md5($3) WHERE (entity_id = entityID);
		passchange := 'Password Changed';
	ELSE
		passchange := null;
	END IF;

	return passchange;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ins_password() RETURNS trigger AS $$
DECLARE
	v_entity_id		integer;
BEGIN

	SELECT entity_id INTO v_entity_id
	FROM entitys
	WHERE (trim(lower(user_name)) = trim(lower(NEW.user_name)))
		AND entity_id <> NEW.entity_id;

	IF(v_entity_id is not null)THEN
		RAISE EXCEPTION 'The username exists use a different one or reset password for the current one';
	END IF;

	IF(TG_OP = 'INSERT') THEN
		IF(NEW.first_password is null)THEN
			NEW.first_password := first_password();
		END IF;

		IF (NEW.entity_password is null) THEN
			NEW.entity_password := md5(NEW.first_password);
		END IF;
	ELSIF(OLD.first_password <> NEW.first_password) THEN
		NEW.Entity_password := md5(NEW.first_password);
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_password BEFORE INSERT OR UPDATE ON entitys
    FOR EACH ROW EXECUTE PROCEDURE ins_password();

CREATE OR REPLACE FUNCTION ins_entitys() RETURNS trigger AS $$
BEGIN
	IF(NEW.entity_type_id is not null) THEN
		INSERT INTO Entity_subscriptions (org_id, entity_type_id, entity_id, subscription_level_id)
		VALUES (NEW.org_id, NEW.entity_type_id, NEW.entity_id, 0);
	END IF;

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_entitys AFTER INSERT ON entitys
    FOR EACH ROW EXECUTE PROCEDURE ins_entitys();

CREATE OR REPLACE FUNCTION ins_sys_reset() RETURNS trigger AS $$
DECLARE
	v_entity_id			integer;
	v_org_id			integer;
	v_password			varchar(32);
BEGIN
	SELECT entity_id, org_id INTO v_entity_id, v_org_id
	FROM entitys
	WHERE (lower(trim(primary_email)) = lower(trim(NEW.request_email)));

	IF(v_entity_id is not null) THEN
		v_password := upper(substring(md5(random()::text) from 3 for 9));

		UPDATE entitys SET first_password = v_password, entity_password = md5(v_password)
		WHERE entity_id = v_entity_id;

		INSERT INTO sys_emailed (org_id, sys_email_id, table_id, table_name)
		VALUES(v_org_id, 3, v_entity_id, 'entitys');
	END IF;

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_sys_reset AFTER INSERT ON sys_reset
    FOR EACH ROW EXECUTE PROCEDURE ins_sys_reset();

CREATE FUNCTION Emailed(integer, varchar(64)) RETURNS void AS $$
    UPDATE sys_emailed SET emailed = true WHERE (sys_emailed_id = CAST($2 as int));
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION ins_approvals() RETURNS trigger AS $$
DECLARE
	reca	RECORD;
BEGIN

	IF (NEW.forward_id is not null) THEN
		SELECT workflow_phase_id, org_entity_id, app_entity_id, approval_level, table_name, table_id INTO reca
		FROM approvals
		WHERE (approval_id = NEW.forward_id);

		NEW.workflow_phase_id := reca.workflow_phase_id;
		NEW.approval_level := reca.approval_level;
		NEW.table_name := reca.table_name;
		NEW.table_id := reca.table_id;
		NEW.approve_status := 'Completed';
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_approvals BEFORE INSERT ON approvals
    FOR EACH ROW EXECUTE PROCEDURE ins_approvals();

CREATE OR REPLACE FUNCTION upd_approvals() RETURNS trigger AS $$
DECLARE
	reca	RECORD;
	wfid	integer;
	vorgid	integer;
	vnotice	boolean;
	vadvice	boolean;
BEGIN

	SELECT notice, advice, org_id INTO vnotice, vadvice, vorgid
	FROM workflow_phases
	WHERE (workflow_phase_id = NEW.workflow_phase_id);

	IF (NEW.approve_status = 'Completed') THEN
		INSERT INTO sys_emailed (table_id, table_name, email_type, org_id)
		VALUES (NEW.approval_id, TG_TABLE_NAME, 1, vorgid);
	END IF;
	IF (NEW.approve_status = 'Approved') AND (vadvice = true) AND (NEW.forward_id is null) THEN
		INSERT INTO sys_emailed (table_id, table_name, email_type, org_id)
		VALUES (NEW.approval_id, TG_TABLE_NAME, 1, vorgid);
	END IF;
	IF (NEW.approve_status = 'Approved') AND (vnotice = true) AND (NEW.forward_id is null) THEN
		INSERT INTO sys_emailed (table_id, table_name, email_type, org_id)
		VALUES (NEW.approval_id, TG_TABLE_NAME, 2, vorgid);
	END IF;

	IF(TG_OP = 'INSERT') AND (NEW.forward_id is null) THEN
		INSERT INTO approval_checklists (approval_id, checklist_id, requirement, manditory, org_id)
		SELECT NEW.approval_id, checklist_id, requirement, manditory, org_id
		FROM checklists
		WHERE (workflow_phase_id = NEW.workflow_phase_id)
		ORDER BY checklist_number;
	END IF;

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER upd_approvals AFTER INSERT OR UPDATE ON approvals
    FOR EACH ROW EXECUTE PROCEDURE upd_approvals();

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
			iswf := true;
			IF(reca.table_link_field is null)THEN
				iswf := true;
			ELSE
				IF(TG_TABLE_NAME = 'entry_forms')THEN
					tbid := NEW.form_id;
				END IF;
				IF(tbid = reca.table_link_id)THEN
					iswf := true;
				END IF;
			END IF;

			IF(iswf = true)THEN
				INSERT INTO approvals (org_id, workflow_phase_id, table_name, table_id, org_entity_id, escalation_days, escalation_hours, approval_level, approval_narrative, to_be_done)
				SELECT org_id, workflow_phase_id, TG_TABLE_NAME, wfid, NEW.entity_id, escalation_days, escalation_hours, approval_level, phase_narrative, 'Approve - ' || phase_narrative
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

CREATE OR REPLACE FUNCTION upd_approvals(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	app_id		Integer;
	reca 		RECORD;
	recb		RECORD;
	recc		RECORD;
	min_level	Integer;
	mysql		varchar(240);
	msg 		varchar(120);
BEGIN
	app_id := CAST($1 as int);
	SELECT approvals.org_id, approvals.approval_id, approvals.org_id, approvals.table_name, approvals.table_id, approvals.review_advice,
		workflow_phases.workflow_phase_id, workflow_phases.workflow_id, workflow_phases.return_level INTO reca
	FROM approvals INNER JOIN workflow_phases ON approvals.workflow_phase_id = workflow_phases.workflow_phase_id
	WHERE (approvals.approval_id = app_id);

	SELECT count(approval_checklist_id) as cl_count INTO recc
	FROM approval_checklists
	WHERE (approval_id = app_id) AND (manditory = true) AND (done = false);

	IF ($3 = '1') THEN
		UPDATE approvals SET approve_status = 'Completed', completion_date = now()
		WHERE approval_id = app_id;
		msg := 'Completed';
	ELSIF ($3 = '2') AND (recc.cl_count <> 0) THEN
		msg := 'There are manditory checklist that must be checked first.';
	ELSIF ($3 = '2') AND (recc.cl_count = 0) THEN
		UPDATE approvals SET approve_status = 'Approved', action_date = now(), app_entity_id = CAST($2 as int)
		WHERE approval_id = app_id;

		SELECT min(approvals.approval_level) INTO min_level
		FROM approvals INNER JOIN workflow_phases ON approvals.workflow_phase_id = workflow_phases.workflow_phase_id
		WHERE (approvals.table_id = reca.table_id) AND (approvals.approve_status = 'Draft')
			AND (workflow_phases.advice = false) AND (workflow_phases.notice = false);

		IF(min_level is null)THEN
			mysql := 'UPDATE ' || reca.table_name || ' SET approve_status = ' || quote_literal('Approved')
			|| ', action_date = now()'
			|| ' WHERE workflow_table_id = ' || reca.table_id;
			EXECUTE mysql;

			INSERT INTO sys_emailed (org_id, table_id, table_name, email_type)
			VALUES (reca.org_id, reca.table_id, 'vw_workflow_approvals', 1);

			FOR recb IN SELECT workflow_phase_id, advice
			FROM workflow_phases
			WHERE (workflow_id = reca.workflow_id) AND (approval_level = min_level) LOOP
				IF (recb.advice = true) THEN
					UPDATE approvals SET approve_status = 'Approved', action_date = now(), completion_date = now()
					WHERE (workflow_phase_id = recb.workflow_phase_id) AND (table_id = reca.table_id);
				END IF;
			END LOOP;
		ELSE
			FOR recb IN SELECT workflow_phase_id, advice
			FROM workflow_phases
			WHERE (workflow_id = reca.workflow_id) AND (approval_level = min_level) LOOP
				IF (recb.advice = true) THEN
					UPDATE approvals SET approve_status = 'Approved', action_date = now(), completion_date = now()
					WHERE (workflow_phase_id = recb.workflow_phase_id) AND (table_id = reca.table_id);
				ELSE
					UPDATE approvals SET approve_status = 'Completed', completion_date = now()
					WHERE (workflow_phase_id = recb.workflow_phase_id) AND (table_id = reca.table_id);
				END IF;
			END LOOP;
		END IF;
		msg := 'Approved';
	ELSIF ($3 = '3') THEN
		UPDATE approvals SET approve_status = 'Rejected',  action_date = now(), app_entity_id = CAST($2 as int)
		WHERE approval_id = app_id;

		mysql := 'UPDATE ' || reca.table_name || ' SET approve_status = ' || quote_literal('Rejected')
		|| ', action_date = now()'
		|| ' WHERE workflow_table_id = ' || reca.table_id;
		EXECUTE mysql;

		INSERT INTO sys_emailed (table_id, table_name, email_type, org_id)
		VALUES (reca.table_id, 'vw_workflow_approvals', 2, reca.org_id);
		msg := 'Rejected';
	ELSIF ($3 = '4') AND (reca.return_level = 0) THEN
		UPDATE approvals SET approve_status = 'Review',  action_date = now(), app_entity_id = CAST($2 as int)
		WHERE approval_id = app_id;

		mysql := 'UPDATE ' || reca.table_name || ' SET approve_status = ' || quote_literal('Draft')
		|| ', action_date = now()'
		|| ' WHERE workflow_table_id = ' || reca.table_id;
		EXECUTE mysql;

		msg := 'Forwarded for review';
	ELSIF ($3 = '4') AND (reca.return_level <> 0) THEN
		UPDATE approvals SET approve_status = 'Review',  action_date = now(), app_entity_id = CAST($2 as int)
		WHERE approval_id = app_id;

		INSERT INTO approvals (org_id, workflow_phase_id, table_name, table_id, org_entity_id, escalation_days, escalation_hours, approval_level, approval_narrative, to_be_done, approve_status)
		SELECT org_id, workflow_phase_id, reca.table_name, reca.table_id, CAST($2 as int), escalation_days, escalation_hours, approval_level, phase_narrative, reca.review_advice, 'Completed'
		FROM vw_workflow_entitys
		WHERE (workflow_id = reca.workflow_id) AND (approval_level = reca.return_level)
		ORDER BY workflow_phase_id;

		UPDATE approvals SET approve_status = 'Draft' WHERE approval_id = app_id;

		msg := 'Forwarded to owner for review';
	END IF;

	RETURN msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION upd_checklist(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	cl_id		Integer;
	reca 		RECORD;
	recc 		RECORD;
	msg 		varchar(120);
BEGIN
	cl_id := CAST($1 as int);

	SELECT approval_checklist_id, approval_id, checklist_id, requirement, manditory, done INTO reca
	FROM approval_checklists
	WHERE (approval_checklist_id = cl_id);

	IF ($3 = '1') THEN
		UPDATE approval_checklists SET done = true WHERE (approval_checklist_id = cl_id);

		SELECT count(approval_checklist_id) as cl_count INTO recc
		FROM approval_checklists
		WHERE (approval_id = reca.approval_id) AND (manditory = true) AND (done = false);
		msg := 'Checklist done.';

		IF(recc.cl_count = 0) THEN
			msg := upd_approvals(CAST(reca.approval_id as varchar(12)), $2, '2');
		END IF;
	ELSIF ($3 = '2') THEN
		UPDATE approval_checklists SET done = false WHERE (approval_checklist_id = cl_id);
		msg := 'Checklist not done.';
	END IF;

	RETURN msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_phase_status(boolean, boolean) RETURNS varchar(16) AS $$
DECLARE
	ps		varchar(16);
BEGIN
	ps := 'Draft';
	IF ($1 = true) THEN
		ps := 'Approved';
	END IF;
	IF ($2 = true) THEN
		ps := 'Rejected';
	END IF;

	RETURN ps;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION get_phase_email(integer) RETURNS varchar(320) AS $$
DECLARE
    myrec	RECORD;
	myemail	varchar(320);
BEGIN
	myemail := null;
	FOR myrec IN SELECT entitys.primary_email
		FROM entitys INNER JOIN entity_subscriptions ON entitys.entity_id = entity_subscriptions.entity_id
		WHERE (entity_subscriptions.entity_type_id = $1) LOOP

		IF (myemail is null) THEN
			IF (myrec.primary_email is not null) THEN
				myemail := myrec.primary_email;
			END IF;
		ELSE
			IF (myrec.primary_email is not null) THEN
				myemail := myemail || ', ' || myrec.primary_email;
			END IF;
		END IF;

	END LOOP;

	RETURN myemail;
END;
$$ LANGUAGE plpgsql;



--- Data
INSERT INTO entity_types (org_id, entity_type_id, entity_type_name, entity_role) VALUES (0, 0, 'Users', 'user');
INSERT INTO entity_types (org_id, entity_type_id, entity_type_name, entity_role) VALUES (0, 1, 'Staff', 'staff');
INSERT INTO entity_types (org_id, entity_type_id, entity_type_name, entity_role) VALUES (0, 2, 'Client', 'client');
INSERT INTO entity_types (org_id, entity_type_id, entity_type_name, entity_role) VALUES (0, 3, 'Supplier', 'supplier');
SELECT pg_catalog.setval('entity_types_entity_type_id_seq', 3, true);

INSERT INTO subscription_levels (org_id, subscription_level_id, subscription_level_name) VALUES (0, 0, 'Basic');
INSERT INTO subscription_levels (org_id, subscription_level_id, subscription_level_name) VALUES (0, 1, 'Manager');
INSERT INTO subscription_levels (org_id, subscription_level_id, subscription_level_name) VALUES (0, 2, 'Consumer');

INSERT INTO entitys (entity_id, org_id, entity_type_id, user_name, entity_name, primary_email, entity_leader, super_user, no_org, first_password)
VALUES (0, 0, 0, 'root', 'root', 'root@localhost', true, true, false, 'baraza');
INSERT INTO entitys (entity_id, org_id, entity_type_id, user_name, entity_name, primary_email, entity_leader, super_user, no_org, first_password)
VALUES (1, 0, 0, 'repository', 'repository', 'repository@localhost', true, false, false, 'baraza');
SELECT pg_catalog.setval('entitys_entity_id_seq', 1, true);




CREATE TABLE rate_category(
  rate_category_id 			serial primary key,
  rate_category_name 		character varying(120),
  group_rates boolean
);
CREATE TABLE corporate_rate_category
(
  corporate_rate_category_id serial primary key,
  corporate_rate_category_name character varying(120)
);

CREATE TABLE corporates(
  corporate_id 				serial primary key,
  corporate_name 				character varying(50) NOT NULL,
  is_default 			boolean NOT NULL DEFAULT true,
  is_active 			boolean NOT NULL DEFAULT true,
  logo 					character varying(50),
  pin 					character varying(50),
  details 				text,
  credit_limit 			real NOT NULL DEFAULT 0,
  UNIQUE (corporate_name)
);



CREATE TABLE rate_types
  (
    rate_type_id 		serial NOT NULL,
    rate_type_name 	character varying(100),
    age_limit 		integer DEFAULT 70,
    details 		text,
    age_from 		integer,
    age_to 		    integer,
    rate_category_id  integer REFERENCES rate_category,
    CONSTRAINT rate_types_pkey PRIMARY KEY (rate_type_id)
  );
  CREATE INDEX rate_category_id_rf  ON rate_category (rate_category_id);

  CREATE TABLE benefit_types
  (
    benefit_type_id 		serial NOT NULL,
    benefit_type_name 		character varying(100),
    benefit_section 		character varying(5),
    details 			    text,

    CONSTRAINT benefit_types_pkey PRIMARY KEY (benefit_type_id)
  );

  CREATE TABLE benefits
  (
    benefit_id 		    serial NOT NULL,
    rate_type_id 		integer,
    benefit_type_id 	integer,
    individual 		    text,
    others 		        text,
    CONSTRAINT benefits_pkey PRIMARY KEY (benefit_id),
    CONSTRAINT benefits_benefit_type_id_fkey FOREIGN KEY (benefit_type_id)
        REFERENCES benefit_types (benefit_type_id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT benefits_rate_type_id_fkey FOREIGN KEY (rate_type_id)
        REFERENCES rate_types (rate_type_id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT benefits_rate_type_id_benefit_type_id_key UNIQUE (rate_type_id, benefit_type_id)
  );


  CREATE INDEX benefits_benefit_type_id
    ON benefits
    USING btree
    (benefit_type_id);

  CREATE INDEX benefits_rate_type_id
    ON benefits
    USING btree
    (rate_type_id);

    CREATE TABLE corporate_rate_types
    (
      rate_type_id 		serial NOT NULL,
      rate_type_name 	character varying(100),
      age_limit 		integer DEFAULT 80,
      details 		text,
      corporate_rate_category_id integer,
      CONSTRAINT corporate_rate_types_pkey PRIMARY KEY (rate_type_id)
    );


    CREATE TABLE corporate_benefit_types
    (
      corporate_benefit_type_id 		serial NOT NULL,
      corporate_section                 character varying(5),
      corporate_benefit_type_name 		character varying(100),
      details 			    text,
      CONSTRAINT corporate_benefit_types_pkey PRIMARY KEY (corporate_benefit_type_id)
    );

    CREATE TABLE corporate_benefits
    (
      benefit_id 		    serial NOT NULL,
      rate_type_id 		integer,
      corporate_benefit_type_id 	integer,
      individual 		    text,
      others 		        text,
      CONSTRAINT corporate_benefits_pkey PRIMARY KEY (benefit_id),
      CONSTRAINT corporate_benefits_benefit_type_id_fkey FOREIGN KEY (corporate_benefit_type_id)
          REFERENCES corporate_benefit_types (corporate_benefit_type_id) MATCH SIMPLE
          ON UPDATE NO ACTION ON DELETE NO ACTION,
      CONSTRAINT benefits_rate_type_id_fkey FOREIGN KEY (rate_type_id)
          REFERENCES corporate_rate_types (rate_type_id) MATCH SIMPLE
          ON UPDATE NO ACTION ON DELETE NO ACTION,
      CONSTRAINT corporate_benefits_rate_type_id_benefit_type_id_key UNIQUE (rate_type_id, corporate_benefit_type_id)
    );

    CREATE INDEX corporate_benefits_benefit_type_id
      ON corporate_benefits
      USING btree
      (corporate_benefit_type_id);

    CREATE INDEX corporate_benefits_rate_type_id
      ON corporate_benefits
      USING btree
      (rate_type_id);

      CREATE TABLE corporate_rates
      (
        corporate_rate_id 		        serial NOT NULL,
        rate_type_id 		    integer,
        days_from 		    integer,
        days_to 		        integer,
        standard_rate 	    real,
        north_america_rate 	real,
        CONSTRAINT corporate_rates_pkey PRIMARY KEY (corporate_rate_id),
        CONSTRAINT corporate_rates_rate_type_id_fkey FOREIGN KEY (rate_type_id)
            REFERENCES corporate_rate_types (rate_type_id) MATCH SIMPLE
            ON UPDATE NO ACTION ON DELETE NO ACTION
      );



    CREATE TABLE rates
    (
      rate_id 		        serial NOT NULL,
      rate_type_id 		    integer,
      days_from 		    integer,
      days_to 		        integer,
      standard_rate 	    real,
      north_america_rate 	real,
      CONSTRAINT rates_pkey PRIMARY KEY (rate_id),
      CONSTRAINT rates_rate_type_id_fkey FOREIGN KEY (rate_type_id)
          REFERENCES rate_types (rate_type_id) MATCH SIMPLE
          ON UPDATE NO ACTION ON DELETE NO ACTION
    );

CREATE TABLE apps_list(
  apps_list_id 			serial primary key,
  org_id 				integer REFERENCES orgs,
  app_name 				character varying(50),
  descriptions 			text,
  query_date 			timestamp without time zone NOT NULL DEFAULT now(),
   UNIQUE (app_name)
);

CREATE INDEX apps_list_org_id  ON apps_list   (org_id);

CREATE TABLE apps_subscriptions(
  app_subscriptions_id serial primary key,
  org_id integer REFERENCES orgs,
  apps_list_id integer REFERENCES apps_list,
  subscription_date timestamp without time zone NOT NULL DEFAULT now()
);

CREATE INDEX apps_subscriptions_org_id  ON apps_subscriptions   (org_id);
CREATE INDEX apps_subscriptions_list_id  ON apps_subscriptions   (apps_list_id);


CREATE TABLE passengers
(
  passenger_id serial NOT NULL,
  rate_id integer,
  entity_id integer,
  org_id integer,
  passenger_name character varying(100),
  passenger_mobile character varying(15),
  passenger_email character varying(100),
  passenger_age integer DEFAULT 0,
  days_covered integer,
  nok_name character varying(100),
  nok_mobile character varying(15),
  nok_national_id character varying(20),
  is_north_america boolean DEFAULT false,
  cover_amount real,
  approved boolean DEFAULT false,
  departure_country character varying(50);
  details text,
  days_from character varying(20),
  days_to character varying(20),
  destown character varying(50),
  approved_date timestamp without time zone,
  sys_country_id character(2),
  passenger_id_no character varying(20),
  passenger_dob character varying(20),
  corporate_id integer,
  corporate_rate_id integer,
  pin_no character varying(25),
  totalamount_covered real,
  countries text,
  policy_number character varying(50),
 reason_for_travel text,
  postal_code character varying(50),
 expiry_date character varying(20),
  physical_address text,

  CONSTRAINT passengers_pkey PRIMARY KEY (passenger_id),
  CONSTRAINT passengers_corporate_id_fkey FOREIGN KEY (corporate_id)
      REFERENCES corporates (corporate_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT passengers_corporate_rate_id_fkey FOREIGN KEY (corporate_rate_id)
      REFERENCES corporate_rates (corporate_rate_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT passengers_entity_id_fkey FOREIGN KEY (entity_id)
      REFERENCES entitys (entity_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT passengers_org_id_fkey FOREIGN KEY (org_id)
      REFERENCES orgs (org_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT passengers_rate_id_fkey FOREIGN KEY (rate_id)
      REFERENCES rates (rate_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT passengers_sys_country_id_fkey FOREIGN KEY (sys_country_id)
      REFERENCES sys_countrys (sys_country_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
);
	CREATE INDEX passenger_sys_country_id  ON passengers   (sys_country_id);
      CREATE INDEX passengers_org_id
        ON passengers
        USING btree
        (org_id);

      CREATE INDEX passengers_rate_id
        ON passengers
        USING btree
        (rate_id);



     CREATE TABLE policy_sequence (
	  policy_no_id serial primary key,
	  policy_sequence_no character varying(50)
	  );
	  INSERT INTO policy_sequence (policy_sequence_no ) VALUES('036A0528342');




CREATE TABLE policy_members (
    policy_member_id    serial primary key,
    passenger_id        integer references passengers,
    org_id              integer,
    entity_id           integer,
    member_name         character varying(50),
    passport_number     character varying(50),
    pin_number          character varying(50),
    phone_number        character varying(20),
    primary_email       character varying(50),
    policy_number       character varying(50),
    rate_id             integer,
    amount_covered      real,
    totalamount_covered real,
    age                 integer,
    passenger_dob       date
);
CREATE INDEX policy_members_passenger_id ON passengers (passenger_id);

CREATE TABLE portal(
  portal_id 			serial primary key,
  portal_name 			character varying(50),
  descriptions 			text
);



    CREATE TABLE logs (
        logsId serial PRIMARY KEY,
        transId integer references passengers,
        entity_id integer references entitys,
        userip varchar(50),
        amount_1 real,
        amount_2 real,
        portal  text,
        status text,
        transDate timestamp default now() not null
    );
    CREATE INDEX logs_transId  ON logs(transId);
    CREATE INDEX logs_entity_id  ON logs(entity_id);

	CREATE TABLE quotationlogs (
		logsId serial PRIMARY KEY,
		email varchar(50),
		mobile_no varchar(50),
		rate_type varchar(50),
		rate_plan varchar(50),
		amount_1 real,
		status text,
		log_date timestamp default now() not null
	);

    CREATE  OR REPLACE VIEW vw_logs AS
    SELECT logs.logsid, logs.transid, logs.entity_id, logs.userip, logs.amount_1, logs.amount_2, logs.transdate,
       logs.portal, logs.status,passengers.passenger_name, passengers.passenger_email,entitys.primary_email,entitys.entity_name
    FROM logs
    INNER JOIN passengers ON passengers.passenger_id = logs.transid
    INNER JOIN entitys ON entitys.entity_id = logs.entity_id;


	CREATE OR REPLACE VIEW vw_rates AS
     SELECT vw_rate_types.rate_type_id,  vw_rate_types.rate_type_name,  rates.rate_id,  rates.days_from,
   rates.days_to,  rates.standard_rate,  rates.north_america_rate,  vw_rate_types.rate_category_name,
   vw_rate_types.rate_category_id,  vw_rate_types.rate_plan_id,  vw_rate_types.rate_plan_name,
   vw_rate_types.age_from,  vw_rate_types.age_to
  FROM rates
    JOIN vw_rate_types ON rates.rate_type_id = vw_rate_types.rate_type_id;

CREATE OR REPLACE VIEW vw_corporate_rates AS
SELECT corporate_rate_types.rate_type_id, corporate_rate_types.rate_type_name, corporate_rates.corporate_rate_id,
  corporate_rates.days_from, corporate_rates.days_to, corporate_rates.standard_rate, corporate_rates.north_america_rate
 FROM corporate_rates
   JOIN corporate_rate_types ON corporate_rates.rate_type_id = corporate_rate_types.rate_type_id;

CREATE OR REPLACE VIEW vw_benefits AS
SELECT benefit_types.benefit_type_id,  benefit_types.benefit_type_name,  benefit_types.benefit_section,
 vw_rate_types.rate_type_id, vw_rate_types.rate_plan_name,  benefits.benefit_id,  benefits.individual, benefits.others
FROM benefits
  JOIN benefit_types ON benefits.benefit_type_id = benefit_types.benefit_type_id
  JOIN vw_rate_types ON benefits.rate_type_id = vw_rate_types.rate_type_id;



CREATE OR REPLACE VIEW vw_corporate_benefits AS
SELECT corporate_benefits.corporate_benefit_type_id,  corporate_benefit_types.corporate_benefit_type_name,
  corporate_benefits.rate_type_id,  corporate_rate_types.rate_type_name,  corporate_benefits.benefit_id,
  corporate_benefits.individual,  corporate_benefits.others
 FROM corporate_benefits
   JOIN corporate_benefit_types ON corporate_benefits.corporate_benefit_type_id = corporate_benefit_types.corporate_benefit_type_id
   JOIN corporate_rate_types ON corporate_benefits.rate_type_id = corporate_rate_types.rate_type_id;



CREATE OR REPLACE VIEW vw_rate_types AS
SELECT rate_types.rate_type_id,  rate_types.rate_type_name,  rate_types.age_limit,  rate_types.details,
  rate_types.age_from,  rate_types.age_to,  rate_category.rate_category_name
 FROM rate_types
   JOIN rate_category ON rate_types.rate_category_id = rate_category.rate_category_id ;

CREATE OR REPLACE VIEW vw_corporate_rate_types AS
SELECT corporate_rate_types.rate_type_id,  corporate_rate_types.rate_type_name,  corporate_rate_types.age_limit,
   corporate_rate_types.details,  corporate_rate_category.corporate_rate_category_name
  FROM corporate_rate_types
  JOIN corporate_rate_category ON corporate_rate_types.corporate_rate_category_id = corporate_rate_category.corporate_rate_category_id ;


  CREATE OR REPLACE VIEW vw_passengers AS
  	SELECT vw_entitys.org_id,  vw_entitys.org_name, vw_rates.rate_type_id, vw_rates.rate_plan_id, vw_rates.rate_category_name,
  	vw_rates.rate_id, vw_rates.rate_plan_name, vw_rates.standard_rate, vw_rates.north_america_rate,
  	 passengers.days_from,  passengers.days_to,  passengers.corporate_rate_id,
  	 passengers.approved,  passengers.entity_id,
  	passengers.countries,  passengers.passenger_id,  passengers.passenger_name,  passengers.passenger_mobile,
  	passengers.passenger_email,  passengers.passenger_age,  passengers.days_covered,  passengers.nok_name,
  	passengers.nok_mobile,  passengers.passenger_id_no,  passengers.nok_national_id,  passengers.cover_amount,
  	passengers.totalAmount_covered,  passengers.is_north_america,  passengers.details,  passengers.passenger_dob,
  	passengers.policy_number,  vw_entitys.entity_name,  passengers.destown,  sys_countrys.sys_country_name,
  	passengers.approved_date,  passengers.corporate_id,  passengers.pin_no, passengers.reason_for_travel,
  	passengers.departure_country, vw_entitys.entity_role, vw_entitys.function_role, vw_entitys.is_active,passengers.physical_address,
  	passengers.is_valid,passengers.is_individual, portal.portal_id,portal.portal_name,passengers.id_no,passengers.relationship
  	FROM passengers
  	 JOIN vw_rates ON passengers.rate_id = vw_rates.rate_id
  	 JOIN vw_entitys ON passengers.entity_id = vw_entitys.entity_id
  	 JOIN portal ON portal.portal_id = passengers.portal_id
  	 JOIN sys_countrys ON passengers.sys_country_id = sys_countrys.sys_country_id;


CREATE OR REPLACE VIEW vw_policy_members AS
SELECT
    p.policy_member_id, p.passenger_id, p.org_id, p.entity_id, p.member_name, p.passport_number, p.pin_number,
    p.phone_number,  p.primary_email, p.rate_id, p.amount_covered, p.totalamount_covered, p.age,
    p.passenger_dob, a.countries,a.policy_number, a.destown, a.sys_country_name, a.reason_for_travel,
    a.departure_country, a.entity_name, a.days_from, a.days_to,
    a.rate_type_id, a.approved_date, a.rate_plan_id, a.rate_category_name,a.approved,
    a.rate_plan_name, a.standard_rate, a.north_america_rate,a.org_name,a.function_role,a.entity_role,a.is_active,
	a.is_valid, a.is_individual, a.portal_id, a.portal_name
    FROM  policy_members p
    JOIN vw_passengers a ON p.passenger_id = a.passenger_id ;

	CREATE OR REPLACE VIEW vw_allpassengers AS
	SELECT a.org_id,  a.org_name, a.rate_type_id,a.rate_plan_id, a.rate_category_name,
	a.rate_id,a.rate_plan_name, a.standard_rate, a.north_america_rate,a.days_from,  a.days_to,  a.corporate_rate_id,
	a.approved, a.entity_id, a.countries, a.passenger_id,  a.passenger_name,  a.passenger_mobile,
	a.passenger_email,  a.passenger_age,  a.days_covered,  a.nok_name, a.nok_mobile,  a.passenger_id_no,
	a.passport_number,  round(a.cover_amount::DECIMAL,2)::real as cover_amount,  round(a.totalAmount_covered::DECIMAL,2)::real as totalAmount_covered,  a.is_north_america,  a.details,  a.passenger_dob,
	a.policy_number,  a.entity_name,  a.destown,  a.sys_country_name, a.approved_date,  a.corporate_id,
	a.pin_no, a.reason_for_travel,  a.departure_country, a.entity_role, a.function_role, a.is_active,a.is_valid,a.is_individual,
	a.portal_id,a.portal_name,  a.id_no, a.relationship
	FROM ((
	SELECT org_id,org_name,rate_type_id, rate_plan_id, rate_category_name,rate_id, rate_plan_name, standard_rate, north_america_rate,
	    days_from,  days_to,  corporate_rate_id,   approved,  entity_id,  countries,  passenger_id,  passenger_name,  passenger_mobile,
	    passenger_email,  passenger_age,  days_covered,  nok_name,  nok_mobile,  passenger_id_no,  nok_national_id as passport_number,  cover_amount,
	    totalAmount_covered,  is_north_america,  details,  passenger_dob,  policy_number,  entity_name,  destown,  sys_country_name,
	    approved_date,  corporate_id,  pin_no, reason_for_travel,  departure_country, entity_role, function_role, is_active,is_valid,is_individual,
	    portal_id, portal_name,id_no,relationship
	FROM vw_passengers  )
	UNION ALL
	(SELECT org_id,org_name, rate_type_id,  rate_plan_id,  rate_category_name, rate_id,    rate_plan_name,  standard_rate,
	    north_america_rate, days_from,days_to,   null::integer as corporate_rate_id,  approved,  entity_id,
	    countries,passenger_id, member_name as passenger_name,  phone_number as passenger_mobile,
	    primary_email as passenger_email , age as  passenger_age,    null::integer as days_covered, ''::text as nok_name,
	    ''::text as nok_mobile,  ''::text as passenger_id_no, passport_number, amount_covered as cover_amount,
	    totalamount_covered,  null::boolean as is_north_america, ''::text as details, passenger_dob::text,policy_number,
	    entity_name, destown, sys_country_name, approved_date, null::integer as corporate_id, pin_number as pin_no,
	    reason_for_travel,     departure_country,   entity_role, function_role ,
	    is_active,  is_valid,is_individual,portal_id, portal_name, ''::text as id_no,''::text as relationship
	FROM  vw_policy_members )
	)a order by passenger_id DESC;



CREATE OR REPLACE VIEW vw_staff AS
    SELECT orgs.org_id,   orgs.org_name, vw_corporate_rates.rate_type_id,   vw_corporate_rates.rate_type_name,
       passengers.days_from,  passengers.days_to,   passengers.corporate_rate_id,
       vw_corporate_rates.standard_rate,  vw_corporate_rates.north_america_rate,   passengers.approved,
       passengers.entity_id,  passengers.passenger_id, passengers.passenger_name,  passengers.passenger_mobile,
       passengers.passenger_email,  passengers.passenger_age,   passengers.days_covered,
       passengers.nok_name,    passengers.nok_mobile, passengers.passenger_id_no,  passengers.nok_national_id,
       passengers.cover_amount,  passengers.is_north_america,  passengers.details,  passengers.passenger_dob,
       entitys.entity_name,   passengers.destown,  sys_countrys.sys_country_name,    passengers.approved_date,
       passengers.corporate_id
      FROM passengers
        JOIN orgs ON passengers.org_id = orgs.org_id
        JOIN vw_corporate_rates ON passengers.corporate_rate_id = vw_corporate_rates.corporate_rate_id
        JOIN entitys ON passengers.entity_id = entitys.entity_id
        JOIN sys_countrys ON passengers.sys_country_id = sys_countrys.sys_country_id;



CREATE OR REPLACE VIEW vw_app_users AS
 SELECT vw_orgs.org_id, vw_orgs.org_name, vw_orgs.pcc, vw_orgs.gds_free_field, vw_orgs.show_fare,
    vw_orgs.logo,  vw_entity_address.table_id, vw_entity_address.table_name, vw_entity_address.post_office_box,
    vw_entity_address.postal_code, vw_entity_address.premises, vw_entity_address.street,
    vw_entity_address.town, vw_entity_address.phone_number, vw_entity_address.email,
    vw_entity_address.sys_country_name, entitys.entity_id, entitys.entity_name, entitys.user_name,
    entitys.entity_password,  entitys.son, entitys.phone_ph,  entitys.phone_pa, entitys.phone_pb,  entitys.phone_pt,
    apps_list.app_name
   FROM entitys
     LEFT JOIN vw_entity_address ON entitys.entity_id = vw_entity_address.table_id
     JOIN vw_orgs ON entitys.org_id = vw_orgs.org_id
     JOIN entity_types ON entitys.entity_type_id = entity_types.entity_type_id
     JOIN apps_subscriptions ON entitys.org_id = apps_subscriptions.org_id
     JOIN apps_list ON apps_subscriptions.apps_list_id = apps_list.apps_list_id;

	 CREATE OR REPLACE VIEW vw_app_subscriptions AS
  SELECT vw_orgs.org_id,    apps_subscriptions.app_subscriptions_id,    vw_orgs.org_name,    apps_list.descriptions,
     apps_list.app_name,    apps_list.apps_list_id
    FROM apps_subscriptions
      JOIN apps_list ON apps_subscriptions.apps_list_id = apps_list.apps_list_id
      JOIN vw_orgs ON apps_subscriptions.org_id = vw_orgs.org_id;

	  CREATE OR REPLACE VIEW vw_jp_pay AS
   SELECT jp_pay.jp_id, jp_pay.jp_tranid, jp_pay.jp_merchant_orderid, jp_pay.jp_amount,
       jp_pay.jp_currency, jp_pay.jp_timestamp, jp_pay.jp_password, jp_pay.details,
	   vw_entitys.org_id,  vw_entitys.entity_id, vw_entitys.entity_name, vw_entitys.org_name
     FROM jp_pay
       JOIN vw_entitys ON jp_pay.entity_id = vw_entitys.entity_id;


 CREATE OR REPLACE VIEW vw_app_list AS
 SELECT vw_orgs.org_id, apps_list.apps_list_id,
    vw_orgs.org_name,
    apps_list.app_name,apps_list.query_date,
    apps_list.descriptions

   FROM apps_list
     JOIN vw_orgs ON apps_list.org_id = vw_orgs.org_id;


CREATE FUNCTION get_benefit_section_a(integer) RETURNS text AS $$
    SELECT individual AS result from vw_benefits WHERE rate_type_id = $1 AND benefit_section IN('1A');
$$LANGUAGE SQL;
CREATE FUNCTION get_benefit_section_b(integer) RETURNS text AS $$
    SELECT individual AS result from vw_benefits WHERE rate_type_id = $1 AND benefit_section IN('1B');
$$LANGUAGE SQL;

drop function getCreditLimit(integer);
CREATE FUNCTION getCreditLimit(integer) RETURNS double precision AS $$
	DECLARE
		credit_limit 	double precision;
		cover_amount 	double precision;
		paid_amount 	double precision;
		current_limit 	double precision;
		BEGIN
			credit_limit := COALESCE((SELECT orgs.credit_limit FROM orgs WHERE orgs.org_id = $1 GROUP BY orgs.credit_limit),0);
			cover_amount:= COALESCE((SELECT SUM(vw_allpassengers.totalamount_covered)AS cover_amount FROM vw_allpassengers WHERE org_id = $1
				GROUP BY org_id),0);

			paid_amount :=COALESCE((SELECT SUM(payment_amount)as payment_amount FROM payments WHERE org_id = $1 GROUP BY org_id),0);

			current_limit := (credit_limit + paid_amount) - cover_amount;


		RETURN current_limit;
		END;
$$LANGUAGE plpgsql;
