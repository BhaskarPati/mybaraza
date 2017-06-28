---Project Database File
-- DROP TABLE orgs;

CREATE TABLE orgs
(
  org_id serial primary key,
  currency_id integer ,
  parent_org_id integer,
  org_name character varying(50) NOT NULL,
  org_sufix character varying(4) NOT NULL,
  is_default boolean NOT NULL DEFAULT true,
  is_active boolean NOT NULL DEFAULT true,
  logo character varying(50),
  pin character varying(50),
  details text,
  pcc character varying(4),
  sp_id character varying(16),
  service_id character varying(32),
  sender_name character varying(16),
  sms_rate real NOT NULL DEFAULT 2,
  show_fare boolean DEFAULT false,
  gds_free_field integer DEFAULT 96,
  credit_limit real NOT NULL DEFAULT 0,
  UNIQUE (org_name,org_sufix)
);

CREATE INDEX orgs_currency_id  ON orgs(currency_id);


CREATE INDEX orgs_parent_org_id  ON orgs  (parent_org_id);

CREATE TABLE address_types(  address_type_id serial primary key,  org_id integer REFERENCES orgs,
  address_type_name character varying(50));

CREATE INDEX address_types_org_id  ON address_types (org_id);

CREATE TABLE sys_continents(
  sys_continent_id character(2) primary key,
  sys_continent_name character varying(120),
   UNIQUE (sys_continent_name)
);

CREATE TABLE sys_countrys(
  sys_country_id character(2) primary key,
  sys_continent_id character(2) REFERENCES sys_continents,
  sys_country_code character varying(3),
  sys_country_number character varying(3),
  sys_phone_code character varying(3),
  sys_country_name character varying(120),
  sys_currency_name character varying(50),
  sys_currency_cents character varying(50),
  sys_currency_code character varying(3),
  sys_currency_exchange real,
   UNIQUE (sys_country_name)
);

CREATE INDEX sys_countrys_sys_continent_id  ON sys_countrys   (sys_continent_id COLLATE pg_catalog."default");


CREATE TABLE address(  address_id serial primary key,  address_type_id integer REFERENCES address_types,  
	sys_country_id character(2) REFERENCES sys_countrys,  org_id integer REFERENCES orgs,
  address_name character varying(120),  table_name character varying(32),  table_id integer,  post_office_box character varying(50),
  postal_code character varying(12),  premises character varying(120),  street character varying(120),  town character varying(50),
  phone_number character varying(150),  extension character varying(15),  mobile character varying(150),
  fax character varying(150),  email character varying(120),  website character varying(120),  is_default boolean,
  first_password character varying(32),  details text,
    UNIQUE (org_id, mobile));

CREATE INDEX address_address_type_id  ON address (address_type_id);


CREATE INDEX address_org_id  ON address  (org_id);


CREATE INDEX address_sys_country_id  ON address  (sys_country_id COLLATE pg_catalog."default");

CREATE INDEX address_table_id  ON address   (table_id);


CREATE INDEX address_table_name  ON address  (table_name COLLATE pg_catalog."default");





CREATE TABLE address_groups(  address_group_id serial NOT NULL,  org_id integer,  address_group_name character varying(50),  details text,
  CONSTRAINT address_groups_pkey PRIMARY KEY (address_group_id),  CONSTRAINT address_groups_org_id_fkey FOREIGN KEY (org_id)
      REFERENCES orgs (org_id) MATCH SIMPLE      ON UPDATE NO ACTION ON DELETE NO ACTION);


CREATE INDEX address_groups_org_id  ON address_groups  USING btree  (org_id);

CREATE TABLE address_members (
	address_member_id		serial primary key,
	address_group_id		integer references address_groups,
	address_id				integer references address,
	org_id					integer references orgs,
	is_active				boolean default true,
	narrative				varchar(240),
	UNIQUE(address_group_id, address_id)
);
CREATE INDEX address_members_address_group_id ON address_members (address_group_id);
CREATE INDEX address_members_address_id ON address_members (address_id);
CREATE INDEX address_members_org_id ON address_members (org_id);



CREATE TABLE rate_types(
  rate_type_id serial primary key,
  rate_type_name character varying(100),
  age_limit integer DEFAULT 70,
  days_from integer,
  days_to integer,
  details text
);

CREATE TABLE rates(
  rate_id serial primary key,
  rate_type_id integer REFERENCES rate_types,
  days_from integer,
  days_to integer,
  standard_rate real,
  north_america_rate real
);

CREATE INDEX rates_rate_type_id  ON rates    (rate_type_id);




CREATE TABLE benefit_types(
  benefit_type_id serial primary key,
  benefit_type_name character varying(100),
  details text
);


CREATE TABLE benefits(
  benefit_id serial primary key,
  rate_type_id integer REFERENCES rate_types,
  benefit_type_id integer REFERENCES benefit_types,
  individual text,
  others text,
  UNIQUE (rate_type_id, benefit_type_id)
);


CREATE INDEX benefits_benefit_type_id  ON benefits    (benefit_type_id);


CREATE INDEX benefits_rate_type_id  ON benefits    (rate_type_id);


CREATE TABLE city_codes(
  city_code character(3) primary key ,
  city_name character varying(100),
  country character varying(100),
  sys_country_id character(2) REFERENCES sys_countrys
);


CREATE TABLE currency(
  currency_id serial primary key,
  currency_name character varying(50),
  currency_symbol character varying(3),
  org_id integer REFERENCES orgs 
);

CREATE INDEX currency_org_id  ON currency    (org_id);

CREATE TABLE currency_rates(
  currency_rate_id serial primary key,
  currency_id integer REFERENCES currency,
  org_id integer REFERENCES orgs,
  exchange_date date NOT NULL DEFAULT ('now'::text)::date,
  exchange_rate real NOT NULL DEFAULT 1
);


CREATE INDEX currency_rates_currency_id  ON currency_rates   (currency_id);

CREATE INDEX currency_rates_org_id  ON currency_rates (org_id);

CREATE TABLE entity_types(
  entity_type_id serial primary key,
  org_id integer REFERENCES orgs,
  entity_type_name character varying(50),
  entity_role character varying(240),
  use_key integer NOT NULL DEFAULT 0,
  start_view character varying(120),
  group_email character varying(120),
  description text,
  details text,
   UNIQUE (entity_type_name)
);

CREATE INDEX entity_types_org_id  ON entity_types   (org_id);



CREATE TABLE entitys(
  entity_id serial primary key,
  entity_type_id integer NOT NULL  REFERENCES entity_types ,
  org_id integer NOT NULL  REFERENCES orgs,
  entity_name character varying(120) NOT NULL,
  user_name character varying(120),
  primary_email character varying(120),
  primary_telephone character varying(50),
  super_user boolean NOT NULL DEFAULT false,
  entity_leader boolean NOT NULL DEFAULT false,
  no_org boolean NOT NULL DEFAULT false,
  function_role character varying(240),
  date_enroled timestamp without time zone DEFAULT now(),
  is_active boolean DEFAULT true,
  entity_password character varying(64) NOT NULL DEFAULT md5('baraza'::text),
  first_password character varying(64) NOT NULL DEFAULT 'baraza'::character varying,
  new_password character varying(64),
  start_url character varying(64),
  is_picked boolean NOT NULL DEFAULT false,
  details text,
  son character varying(6),
  phone_ph boolean DEFAULT true,
  phone_pa boolean DEFAULT false,
  phone_pb boolean DEFAULT false,
  phone_pt boolean DEFAULT false,
   UNIQUE (org_id, user_name)
);


CREATE INDEX entitys_entity_type_id  ON entitys   (entity_type_id);

CREATE INDEX entitys_org_id  ON entitys   (org_id);

CREATE INDEX entitys_user_name  ON entitys   (user_name COLLATE pg_catalog."default");


CREATE TABLE subscription_levels(
  subscription_level_id 	serial primary key,
  org_id 					integer REFERENCES orgs ,
  subscription_level_name 	character varying(50),
  details 					text
);

CREATE INDEX subscription_levels_org_id  ON subscription_levels   (org_id);




CREATE TABLE entity_subscriptions(
  entity_subscription_id 	serial primary key,
  entity_type_id 			integer NOT NULL REFERENCES entity_types,
  entity_id 				integer NOT NULL REFERENCES entitys ,
  subscription_level_id 	integer NOT NULL REFERENCES subscription_levels,
  org_id 					integer REFERENCES orgs,
  details 					text,
  UNIQUE (entity_id, entity_type_id)
);


CREATE INDEX entity_subscriptions_entity_id  ON entity_subscriptions    (entity_id);


CREATE INDEX entity_subscriptions_entity_type_id  ON entity_subscriptions   (entity_type_id);

CREATE INDEX entity_subscriptions_org_id  ON entity_subscriptions   (org_id);

CREATE INDEX entity_subscriptions_subscription_level_id  ON entity_subscriptions    (subscription_level_id);



CREATE TABLE forms(
  form_id serial primary key,
  org_id integer REFERENCES orgs,
  form_name character varying(240) NOT NULL,
  form_number character varying(50),
  table_name character varying(50),
  version character varying(25),
  completed character(1) NOT NULL DEFAULT '0'::bpchar,
  is_active character(1) NOT NULL DEFAULT '0'::bpchar,
  use_key integer DEFAULT 0,
  form_header text,
  form_footer text,
  default_values text,
  default_sub_values text,
  details text,
   UNIQUE (form_name, version)
);

CREATE INDEX forms_org_id  ON forms   (org_id);

CREATE TABLE entry_forms(
  entry_form_id serial primary key,
  org_id integer REFERENCES orgs,
  entity_id integer REFERENCES entitys,
  form_id integer REFERENCES forms,
  entered_by_id integer REFERENCES entitys,
  application_date timestamp without time zone NOT NULL DEFAULT now(),
  completion_date timestamp without time zone,
  approve_status character varying(16) NOT NULL DEFAULT 'Draft'::character varying,
  workflow_table_id integer,
  action_date timestamp without time zone,
  narrative character varying(240),
  answer text,
  sub_answer text,
  details text
);

CREATE INDEX entry_forms_entered_by_id  ON entry_forms   (entered_by_id);

CREATE INDEX entry_forms_entity_id  ON entry_forms   (entity_id);

CREATE INDEX entry_forms_form_id  ON entry_forms   (form_id);

CREATE INDEX entry_forms_org_id  ON entry_forms    (org_id);





CREATE TABLE fields(
  field_id serial primary key,
  org_id integer REFERENCES orgs,
  form_id integer REFERENCES forms,
  field_name character varying(50),
  question text,
  field_lookup text,
  field_type character varying(25) NOT NULL,
  field_class character varying(25),
  field_bold character(1) NOT NULL DEFAULT '0'::bpchar,
  field_italics character(1) NOT NULL DEFAULT '0'::bpchar,
  field_order integer NOT NULL,
  share_line integer,
  field_size integer NOT NULL DEFAULT 25,
  label_position character(1) DEFAULT 'L'::bpchar,
  field_fnct character varying(120),
  manditory character(1) NOT NULL DEFAULT '0'::bpchar,
  show character(1) DEFAULT '1'::bpchar,
  tab character varying(25),
  details text
);

CREATE INDEX fields_form_id  ON fields   (form_id);

CREATE INDEX fields_org_id  ON fields   (org_id);


CREATE TABLE folders (
	folder_id				serial primary key,
	org_id					integer references orgs,
	folder_name				varchar(25) unique,
	details					text
);
CREATE INDEX folders_org_id ON folders (org_id);
INSERT INTO folders (folder_id, folder_name) VALUES (0, 'Outbox');
INSERT INTO folders (folder_id, folder_name) VALUES (1, 'Draft');
INSERT INTO folders (folder_id, folder_name) VALUES (2, 'Sent');
INSERT INTO folders (folder_id, folder_name) VALUES (3, 'Inbox');
INSERT INTO folders (folder_id, folder_name) VALUES (4, 'Action');


CREATE TABLE mpesa_trxs(
  mpesa_trx_id serial primary key,
  org_id integer REFERENCES orgs,
  mpesa_id integer,
  mpesa_orig character varying(50),
  mpesa_dest character varying(50),
  mpesa_tstamp timestamp without time zone,
  mpesa_text character varying(320),
  mpesa_code character varying(50),
  mpesa_acc character varying(50),
  mpesa_msisdn character varying(50),
  mpesa_trx_date date,
  mpesa_trx_time time without time zone,
  mpesa_amt real,
  mpesa_sender character varying(50),
  mpesa_pick_time timestamp without time zone DEFAULT now()
);

CREATE INDEX mpesa_trxs_org_id  ON mpesa_trxs   (org_id);

CREATE TABLE numbers_imports (
	numbers_import_id		serial primary key,
	address_group_id		integer references address_groups,
	entity_id				integer references entitys,
	org_id					integer references orgs,
	number_name				varchar(120),
	mobile_number			varchar(50)
);
CREATE INDEX numbers_imports_address_group_id ON numbers_imports (address_group_id);
CREATE INDEX numbers_imports_entity_id ON numbers_imports (entity_id);
CREATE INDEX numbers_imports_org_id ON numbers_imports (org_id);

CREATE TABLE passengers(
  passenger_id serial primary key,
  rate_id integer REFERENCES rates,
  entity_id integer REFERENCES entitys,
  org_id integer REFERENCES orgs,
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
  details text,
  days_from character varying(20),
  days_to character varying(20),
  destown character varying(10),
  approved_date timestamp without time zone
);

CREATE INDEX passengers_org_id  ON passengers   (org_id);
  
CREATE INDEX passengers_rate_id  ON passengers   (rate_id);



  
CREATE TABLE payment_types(
  payment_type_id serial primary key,
  payment_type_name character varying(100),
  details text
);


CREATE TABLE payments(
  payment_id serial primary key,
  payment_type_id integer REFERENCES payment_types,
  org_id integer REFERENCES orgs,
  payment_amount real,
  transaction_reference character varying(100),
  payment_date date,
  approved boolean DEFAULT false,
  details text
);

CREATE INDEX payments_org_id  ON payments   (org_id);




CREATE TABLE receipts (
	receipt_id				serial primary key,
	mpesa_trx_id			integer references mpesa_trxs,
	org_id					integer references orgs,
	receipt_date			date not null,
	receipt_amount			real not null,
	details					text
);
CREATE INDEX receipts_mpesa_trx_id ON receipts (mpesa_trx_id);
CREATE INDEX receipts_org_id ON receipts (org_id);

CREATE TABLE reporting(
  reporting_id serial primary key,
  entity_id integer REFERENCES entitys,
  report_to_id integer REFERENCES entitys,
  org_id integer REFERENCES orgs,
  date_from date,
  date_to date,
  reporting_level integer NOT NULL DEFAULT 1,
  primary_report boolean NOT NULL DEFAULT true,
  is_active boolean NOT NULL DEFAULT true,
  ps_reporting real,
  details text
);

CREATE INDEX reporting_entity_id  ON reporting    (entity_id);

CREATE INDEX reporting_org_id  ON reporting   (org_id);

CREATE INDEX reporting_report_to_id  ON reporting   (report_to_id);


CREATE TABLE sms (
	sms_id					serial primary key,
	folder_id				integer references folders,
	address_group_id		integer references address_groups,
	entity_id				integer references entitys,
	org_id					integer references orgs,
	sms_origin				varchar(50),
	sms_number				varchar(25),
	sms_numbers				text,
	sms_time				timestamp default now(),
	sms_count				integer not null default 0,
	number_error			boolean default false,
	message_ready			boolean default false,
	sent					boolean default false,
	retries					integer default 0 not null,
	last_retry				timestamp default now(),
	
	addresses				text,
	senderAddress			varchar(64),
	serviceId				varchar(64), 
	spRevpassword			varchar(64), 
	dateTime				timestamp, 
	correlator				varchar(64), 
	traceUniqueID			varchar(64), 
	linkid					varchar(64), 
	spRevId					varchar(64), 
	spId					varchar(64), 
	smsServiceActivationNumber	varchar(64),

	link_id					integer,

	message					text,
	details					text
);
CREATE INDEX sms_folder_id ON sms (folder_id);
CREATE INDEX sms_address_group_id ON sms (address_group_id);
CREATE INDEX sms_entity_id ON sms (entity_id);
CREATE INDEX sms_org_id ON sms (org_id);



CREATE TABLE sms_address (
	sms_address_id			serial primary key,
	sms_id					integer references sms,
	address_id				integer references address,
	org_id					integer references orgs,
	narrative				varchar(50),
	UNIQUE(sms_id, address_id)
);
CREATE INDEX sms_address_sms_id ON sms_address (sms_id);
CREATE INDEX sms_address_address_id ON sms_address (address_id);
CREATE INDEX sms_address_org_id ON sms_address (org_id);


CREATE TABLE sms_queue (
	sms_queue_id			serial primary key,
	sms_id					integer references sms,
	org_id					integer references orgs,
	send_results			varchar(64),
	message_sent			boolean default false not null,
	status_code				varchar(4),
	delivery_status			varchar(64),
	trace_id				varchar(32),
	message_parts			integer default 1 not null,
	sms_number				varchar(25),
	sms_price				real default 2 not null,
	retries					integer default 0 not null,
	last_retry				timestamp default now()
);
CREATE INDEX sms_queue_sms_id ON sms_queue (sms_id);
CREATE INDEX sms_queue_org_id ON sms_queue (org_id);

CREATE TABLE sms_trans(
  sms_trans_id serial primary key,
  org_id integer  REFERENCES orgs,
  message character varying(2400),
  origin character varying(50),
  sms_time timestamp without time zone,
  client_id character varying(50),
  msg_number character varying(50),
  code character varying(25),
  amount real,
  in_words character varying(240),
  narrative character varying(240),
  sms_id integer,
  sms_deleted boolean NOT NULL DEFAULT false,
  sms_picked boolean NOT NULL DEFAULT false,
  part_id integer,
  part_message character varying(240),
  part_no integer,
  part_count integer,
  complete boolean DEFAULT false,
   UNIQUE (origin, sms_time)
);

CREATE INDEX sms_trans_org_id  ON sms_trans    (org_id);



-- DROP TABLE sub_fields;

CREATE TABLE sub_fields
(
  sub_field_id serial primary key,
  org_id integer REFERENCES orgs ,
  field_id integer REFERENCES fields,
  sub_field_order integer NOT NULL,
  sub_title_share character varying(120),
  sub_field_type character varying(25),
  sub_field_lookup text,
  sub_field_size integer NOT NULL,
  sub_col_spans integer NOT NULL DEFAULT 1,
  manditory character(1) NOT NULL DEFAULT '0'::bpchar,
  show character(1) DEFAULT '1'::bpchar,
  question text
);


CREATE INDEX sub_fields_field_id  ON sub_fields    (field_id);

CREATE INDEX sub_fields_org_id  ON sub_fields  (org_id);




CREATE TABLE sys_audit_trail
(
  sys_audit_trail_id serial NOT NULL,
  user_id character varying(50) NOT NULL,
  user_ip character varying(50),
  change_date timestamp without time zone NOT NULL DEFAULT now(),
  table_name character varying(50) NOT NULL,
  record_id character varying(50) NOT NULL,
  change_type character varying(50) NOT NULL,
  narrative character varying(240),
  CONSTRAINT sys_audit_trail_pkey PRIMARY KEY (sys_audit_trail_id)
);

CREATE TABLE sys_audit_details(
  sys_audit_detail_id serial primary key,
  sys_audit_trail_id integer REFERENCES sys_audit_trail,
  new_value text
);

CREATE INDEX sys_audit_details_sys_audit_trail_id  ON sys_audit_details    (sys_audit_trail_id);



CREATE TABLE sys_dashboard(
  sys_dashboard_id serial primary key,
  entity_id integer REFERENCES entitys,
  org_id integer REFERENCES orgs,
  narrative character varying(240),
  details text
);

CREATE INDEX sys_dashboard_entity_id  ON sys_dashboard    (entity_id);

CREATE INDEX sys_dashboard_org_id  ON sys_dashboard    (org_id);

CREATE TABLE sys_emails(
  sys_email_id serial primary key,
  org_id integer REFERENCES orgs ,
  sys_email_name character varying(50),
  default_email character varying(120),
  title character varying(240) NOT NULL,
  details text
);

CREATE INDEX sys_emails_org_id  ON sys_emails    (org_id);

CREATE TABLE sys_emailed(
  sys_emailed_id serial primary key,
  sys_email_id integer REFERENCES sys_emails,
  org_id integer REFERENCES orgs,
  table_id integer,
  table_name character varying(50),
  email_type integer NOT NULL DEFAULT 1,
  emailed boolean NOT NULL DEFAULT false,
  narrative character varying(240),
  mail_body text
);

CREATE INDEX sys_emailed_org_id  ON sys_emailed   (org_id);

CREATE INDEX sys_emailed_sys_email_id  ON sys_emailed   (sys_email_id);

CREATE INDEX sys_emailed_table_id  ON sys_emailed    (table_id);


CREATE TABLE sys_errors(
  sys_error_id serial primary key,
  sys_error character varying(240) NOT NULL,
  error_message text NOT NULL
);

CREATE TABLE sys_files(
  sys_file_id serial primary key,
  org_id integer REFERENCES orgs ,
  table_id integer,
  table_name character varying(50),
  file_name character varying(320),
  file_type character varying(320),
  file_size integer,
  narrative character varying(320),
  details text
);

CREATE INDEX sys_files_org_id  ON sys_files    (org_id);

CREATE INDEX sys_files_table_id  ON sys_files   (table_id);

CREATE TABLE sys_logins(
  sys_login_id serial primary key,
  entity_id integer REFERENCES entitys,
  login_time timestamp without time zone DEFAULT now(),
  login_ip character varying(64),
  narrative character varying(240)
);

CREATE INDEX sys_logins_entity_id  ON sys_logins   (entity_id);

CREATE TABLE sys_menu_msg(
  sys_menu_msg_id serial primary key,
  menu_id integer NOT NULL,
  menu_name character varying(50) NOT NULL,
  msg text
);

CREATE TABLE sys_news(
  sys_news_id serial primary key,
  org_id integer REFERENCES orgs,
  sys_news_group integer,
  sys_news_title character varying(240) NOT NULL,
  publish boolean NOT NULL DEFAULT false,
  details text
);

CREATE INDEX sys_news_org_id  ON sys_news   (org_id);

CREATE TABLE sys_queries(
  sys_queries_id serial primary key,
  org_id integer REFERENCES orgs,
  sys_query_name character varying(50),
  query_date timestamp without time zone NOT NULL DEFAULT now(),
  query_text text,
  query_params text,
   UNIQUE (org_id, sys_query_name)
);

CREATE INDEX sys_queries_org_id  ON sys_queries   (org_id);

CREATE TABLE sys_reset(
  sys_reset_id serial primary key,
  entity_id integer REFERENCES entitys,
  org_id integer REFERENCES orgs,
  request_email character varying(320),
  request_time timestamp without time zone DEFAULT now(),
  login_ip character varying(64),
  narrative character varying(240)
);

CREATE INDEX sys_reset_entity_id  ON sys_reset   (entity_id);

CREATE INDEX sys_reset_org_id  ON sys_reset   (org_id);





CREATE TABLE workflow_logs(
  workflow_log_id serial primary key,
  org_id integer REFERENCES orgs,
  table_name character varying(64),
  table_id integer,
  table_old_id integer
);

CREATE INDEX workflow_logs_org_id  ON workflow_logs    (org_id);

CREATE TABLE workflows(  workflow_id serial primary key,  source_entity_id integer NOT NULL   REFERENCES entity_types , 
 org_id integer REFERENCES orgs,  workflow_name character varying(240) NOT NULL,
  table_name character varying(64),  table_link_field character varying(64),  table_link_id integer,  approve_email text,  reject_email text,
  approve_file character varying(320),  reject_file character varying(320),  details text
  );

CREATE INDEX workflows_org_id  ON workflows  (org_id);

CREATE INDEX workflows_source_entity_id  ON workflows    (source_entity_id);



CREATE TABLE workflow_phases(  workflow_phase_id serial primary key, 
 workflow_id integer NOT NULL REFERENCES workflows,  approval_entity_id integer NOT NULL  REFERENCES entity_types,
  org_id integer REFERENCES orgs,  approval_level integer NOT NULL DEFAULT 1, 
   return_level integer NOT NULL DEFAULT 1,  escalation_days integer NOT NULL DEFAULT 0,
  escalation_hours integer NOT NULL DEFAULT 3, 
   required_approvals integer NOT NULL DEFAULT 1,  
   reporting_level integer NOT NULL DEFAULT 1,
  use_reporting boolean NOT NULL DEFAULT false,  advice boolean NOT NULL DEFAULT false,  notice boolean NOT NULL DEFAULT false,
  phase_narrative character varying(240),  advice_email text,  notice_email text,  advice_file character varying(320),
  notice_file character varying(320),  details text
);


CREATE INDEX workflow_phases_approval_entity_id  ON workflow_phases   (approval_entity_id);

CREATE INDEX workflow_phases_org_id  ON workflow_phases   (org_id);

CREATE INDEX workflow_phases_workflow_id  ON workflow_phases  USING btree  (workflow_id);

CREATE TABLE workflow_sql(  workflow_sql_id integer primary key, 
 workflow_phase_id integer NOT NULL REFERENCES workflow_phases, 
  org_id integer REFERENCES orgs ,  workflow_sql_name character varying(50),
  is_condition boolean DEFAULT false, 
   is_action boolean DEFAULT false,  message_number character varying(32), 
    ca_sql text);

CREATE INDEX workflow_sql_org_id  ON workflow_sql  USING btree  (org_id);


CREATE INDEX workflow_sql_workflow_phase_id  ON workflow_sql  USING btree  (workflow_phase_id);

CREATE TABLE checklists(
  checklist_id serial primary key,
  workflow_phase_id integer NOT NULL REFERENCES workflow_phases ,
  org_id integer REFERENCES orgs,
  checklist_number integer,
  manditory boolean NOT NULL DEFAULT false,
  requirement text,
  details text
);

CREATE INDEX checklists_org_id  ON checklists    (org_id);

CREATE INDEX checklists_workflow_phase_id  ON checklists   (workflow_phase_id);




CREATE TABLE approvals(  approval_id serial primary key,  workflow_phase_id integer NOT NULL REFERENCES workflow_phases,  org_entity_id integer NOT NULL,
  app_entity_id integer REFERENCES entitys,  org_id integer REFERENCES orgs,  approval_level integer NOT NULL DEFAULT 1,  escalation_days integer NOT NULL DEFAULT 0,
  escalation_hours integer NOT NULL DEFAULT 3,  escalation_time timestamp without time zone NOT NULL DEFAULT now(),
  forward_id integer,  table_name character varying(64),  table_id integer,  application_date timestamp without time zone NOT NULL DEFAULT now(),
  completion_date timestamp without time zone,  action_date timestamp without time zone,
  approve_status character varying(16) NOT NULL DEFAULT 'Draft'::character varying,  approval_narrative character varying(240),
  to_be_done text,  what_is_done text,  review_advice text,  details text
 
);

CREATE INDEX approvals_app_entity_id  ON approvals    (app_entity_id);


CREATE INDEX approvals_approve_status  ON approvals (approve_status COLLATE pg_catalog."default");


CREATE INDEX approvals_forward_id  ON approvals (forward_id);


CREATE INDEX approvals_org_entity_id ON approvals  (org_entity_id);


CREATE INDEX approvals_org_id  ON approvals   (org_id);


CREATE INDEX approvals_table_id  ON approvals (table_id);

CREATE INDEX approvals_workflow_phase_id  ON approvals  (workflow_phase_id);






CREATE TABLE approval_checklists(  approval_checklist_id serial NOT NULL,  
approval_id integer NOT NULL REFERENCES approvals,  checklist_id integer NOT NULL REFERENCES checklists ,
  org_id integer REFERENCES orgs ,  requirement text,  manditory boolean NOT NULL DEFAULT false,  done boolean NOT NULL DEFAULT false,
  narrative character varying(320));

CREATE INDEX approval_checklists_approval_id  ON approval_checklists(approval_id);

CREATE INDEX approval_checklists_checklist_id  ON approval_checklists  (checklist_id);

CREATE INDEX approval_checklists_org_id  ON approval_checklists (org_id);




CREATE TABLE apps_list(
  apps_list_id serial primary key,
  org_id integer REFERENCES orgs,
  app_name character varying(50),
  descriptions text,
  query_date timestamp without time zone NOT NULL DEFAULT now(),
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


-- DROP VIEW tomcat_users;
CREATE OR REPLACE VIEW vw_app_users AS 
 SELECT vw_orgs.org_id,
    vw_orgs.org_name,
    vw_orgs.pcc,
    vw_orgs.gds_free_field,
    vw_orgs.show_fare,
    vw_orgs.logo,
    vw_entity_address.table_id,
    vw_entity_address.table_name,
    vw_entity_address.post_office_box,
    vw_entity_address.postal_code,
    vw_entity_address.premises,
    vw_entity_address.street,
    vw_entity_address.town,
    vw_entity_address.phone_number,
    vw_entity_address.email,
    vw_entity_address.sys_country_name,
    entitys.entity_id,
    entitys.entity_name,
    entitys.son,
    entitys.phone_ph,
    entitys.phone_pa,
    entitys.phone_pb,
    entitys.phone_pt,
    apps_list.app_name
   FROM entitys
     LEFT JOIN vw_entity_address ON entitys.entity_id = vw_entity_address.table_id
     JOIN vw_orgs ON entitys.org_id = vw_orgs.org_id
     JOIN entity_types ON entitys.entity_type_id = entity_types.entity_type_id
     JOIN apps_subscriptions ON entitys.org_id = apps_subscriptions.org_id
     JOIN apps_list ON apps_subscriptions.apps_list_id = apps_list.apps_list_id;
  
  
  CREATE OR REPLACE VIEW vw_app_subscriptions AS 
 SELECT vw_orgs.org_id, apps_subscriptions.app_subscriptions_id,
    vw_orgs.org_name,
    apps_list.descriptions,
    apps_list.app_name
    
   FROM apps_subscriptions
     JOIN apps_list ON apps_subscriptions.apps_list_id = apps_list.apps_list_id
     JOIN vw_orgs ON apps_subscriptions.org_id = vw_orgs.org_id;
  
  CREATE OR REPLACE VIEW vw_app_list AS 
 SELECT vw_orgs.org_id, apps_list.apps_list_id,
    vw_orgs.org_name,
    apps_list.app_name,apps_list.query_date,
    apps_list.descriptions
    
   FROM apps_list
     JOIN vw_orgs ON apps_list.org_id = vw_orgs.org_id;
  


CREATE OR REPLACE VIEW tomcat_users AS 
 SELECT entitys.user_name,
    entitys.entity_password,
    entity_types.entity_role
   FROM entity_subscriptions
     JOIN entitys ON entity_subscriptions.entity_id = entitys.entity_id
     JOIN entity_types ON entity_subscriptions.entity_type_id = entity_types.entity_type_id
  WHERE entitys.is_active = true;
  
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
     
     
     
     
     CREATE OR REPLACE VIEW vw_address_entitys AS 
 SELECT vw_address.address_id,
    vw_address.address_name,
    vw_address.table_id,
    vw_address.table_name,
    vw_address.sys_country_id,
    vw_address.sys_country_name,
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
  WHERE vw_address.table_name::text = 'entitys'::text;
CREATE OR REPLACE VIEW vw_address_members AS 
 SELECT address.address_id,
    address.address_name,
    address.mobile,
    address_groups.address_group_id,
    address_groups.address_group_name,
    address_members.org_id,
    address_members.address_member_id,
    address_members.is_active,
    address_members.narrative
   FROM address_members
     JOIN address ON address_members.address_id = address.address_id
     JOIN address_groups ON address_members.address_group_id = address_groups.address_group_id;



CREATE OR REPLACE VIEW vw_workflows AS 
 SELECT entity_types.entity_type_id AS source_entity_id,
    entity_types.entity_type_name AS source_entity_name,
    workflows.workflow_id,
    workflows.org_id,
    workflows.workflow_name,
    workflows.table_name,
    workflows.table_link_field,
    workflows.table_link_id,
    workflows.approve_email,
    workflows.reject_email,
    workflows.approve_file,
    workflows.reject_file,
    workflows.details
   FROM workflows
     JOIN entity_types ON workflows.source_entity_id = entity_types.entity_type_id;


CREATE OR REPLACE VIEW vw_workflow_phases AS 
 SELECT vw_workflows.source_entity_id,
    vw_workflows.source_entity_name,
    vw_workflows.workflow_id,
    vw_workflows.workflow_name,
    vw_workflows.table_name,
    vw_workflows.table_link_field,
    vw_workflows.table_link_id,
    vw_workflows.approve_email,
    vw_workflows.reject_email,
    vw_workflows.approve_file,
    vw_workflows.reject_file,
    entity_types.entity_type_id AS approval_entity_id,
    entity_types.entity_type_name AS approval_entity_name,
    workflow_phases.workflow_phase_id,
    workflow_phases.org_id,
    workflow_phases.approval_level,
    workflow_phases.return_level,
    workflow_phases.escalation_days,
    workflow_phases.escalation_hours,
    workflow_phases.notice,
    workflow_phases.notice_email,
    workflow_phases.notice_file,
    workflow_phases.advice,
    workflow_phases.advice_email,
    workflow_phases.advice_file,
    workflow_phases.required_approvals,
    workflow_phases.use_reporting,
    workflow_phases.reporting_level,
    workflow_phases.phase_narrative,
    workflow_phases.details
   FROM workflow_phases
     JOIN vw_workflows ON workflow_phases.workflow_id = vw_workflows.workflow_id
     JOIN entity_types ON workflow_phases.approval_entity_id = entity_types.entity_type_id;


CREATE OR REPLACE VIEW vw_approvals AS 
 SELECT vw_workflow_phases.workflow_id,
    vw_workflow_phases.workflow_name,
    vw_workflow_phases.approve_email,
    vw_workflow_phases.reject_email,
    vw_workflow_phases.source_entity_id,
    vw_workflow_phases.source_entity_name,
    vw_workflow_phases.approval_entity_id,
    vw_workflow_phases.approval_entity_name,
    vw_workflow_phases.workflow_phase_id,
    vw_workflow_phases.approval_level,
    vw_workflow_phases.phase_narrative,
    vw_workflow_phases.return_level,
    vw_workflow_phases.required_approvals,
    vw_workflow_phases.notice,
    vw_workflow_phases.notice_email,
    vw_workflow_phases.notice_file,
    vw_workflow_phases.advice,
    vw_workflow_phases.advice_email,
    vw_workflow_phases.advice_file,
    vw_workflow_phases.use_reporting,
    approvals.approval_id,
    approvals.org_id,
    approvals.forward_id,
    approvals.table_name,
    approvals.table_id,
    approvals.completion_date,
    approvals.escalation_days,
    approvals.escalation_hours,
    approvals.escalation_time,
    approvals.application_date,
    approvals.approve_status,
    approvals.action_date,
    approvals.approval_narrative,
    approvals.to_be_done,
    approvals.what_is_done,
    approvals.review_advice,
    approvals.details,
    oe.entity_id AS org_entity_id,
    oe.entity_name AS org_entity_name,
    oe.user_name AS org_user_name,
    oe.primary_email AS org_primary_email,
    ae.entity_id AS app_entity_id,
    ae.entity_name AS app_entity_name,
    ae.user_name AS app_user_name,
    ae.primary_email AS app_primary_email
   FROM vw_workflow_phases
     JOIN approvals ON vw_workflow_phases.workflow_phase_id = approvals.workflow_phase_id
     JOIN entitys oe ON approvals.org_entity_id = oe.entity_id
     LEFT JOIN entitys ae ON approvals.app_entity_id = ae.entity_id;



CREATE OR REPLACE VIEW vw_approvals_entitys AS 
 SELECT vw_workflow_phases.workflow_id,
    vw_workflow_phases.workflow_name,
    vw_workflow_phases.source_entity_id,
    vw_workflow_phases.source_entity_name,
    vw_workflow_phases.approval_entity_id,
    vw_workflow_phases.approval_entity_name,
    vw_workflow_phases.workflow_phase_id,
    vw_workflow_phases.approval_level,
    vw_workflow_phases.notice,
    vw_workflow_phases.notice_email,
    vw_workflow_phases.notice_file,
    vw_workflow_phases.advice,
    vw_workflow_phases.advice_email,
    vw_workflow_phases.advice_file,
    vw_workflow_phases.return_level,
    vw_workflow_phases.required_approvals,
    vw_workflow_phases.phase_narrative,
    vw_workflow_phases.use_reporting,
    approvals.approval_id,
    approvals.org_id,
    approvals.forward_id,
    approvals.table_name,
    approvals.table_id,
    approvals.completion_date,
    approvals.escalation_days,
    approvals.escalation_hours,
    approvals.escalation_time,
    approvals.application_date,
    approvals.approve_status,
    approvals.action_date,
    approvals.approval_narrative,
    approvals.to_be_done,
    approvals.what_is_done,
    approvals.review_advice,
    approvals.details,
    oe.entity_id AS org_entity_id,
    oe.entity_name AS org_entity_name,
    oe.user_name AS org_user_name,
    oe.primary_email AS org_primary_email,
    entitys.entity_id,
    entitys.entity_name,
    entitys.user_name,
    entitys.primary_email
   FROM vw_workflow_phases
     JOIN approvals ON vw_workflow_phases.workflow_phase_id = approvals.workflow_phase_id
     JOIN entitys oe ON approvals.org_entity_id = oe.entity_id
     JOIN entity_subscriptions ON vw_workflow_phases.approval_entity_id = entity_subscriptions.entity_type_id
     JOIN entitys ON entity_subscriptions.entity_id = entitys.entity_id
  WHERE approvals.forward_id IS NULL AND vw_workflow_phases.use_reporting = false
UNION
 SELECT vw_workflow_phases.workflow_id,
    vw_workflow_phases.workflow_name,
    vw_workflow_phases.source_entity_id,
    vw_workflow_phases.source_entity_name,
    vw_workflow_phases.approval_entity_id,
    vw_workflow_phases.approval_entity_name,
    vw_workflow_phases.workflow_phase_id,
    vw_workflow_phases.approval_level,
    vw_workflow_phases.notice,
    vw_workflow_phases.notice_email,
    vw_workflow_phases.notice_file,
    vw_workflow_phases.advice,
    vw_workflow_phases.advice_email,
    vw_workflow_phases.advice_file,
    vw_workflow_phases.return_level,
    vw_workflow_phases.required_approvals,
    vw_workflow_phases.phase_narrative,
    vw_workflow_phases.use_reporting,
    approvals.approval_id,
    approvals.org_id,
    approvals.forward_id,
    approvals.table_name,
    approvals.table_id,
    approvals.completion_date,
    approvals.escalation_days,
    approvals.escalation_hours,
    approvals.escalation_time,
    approvals.application_date,
    approvals.approve_status,
    approvals.action_date,
    approvals.approval_narrative,
    approvals.to_be_done,
    approvals.what_is_done,
    approvals.review_advice,
    approvals.details,
    oe.entity_id AS org_entity_id,
    oe.entity_name AS org_entity_name,
    oe.user_name AS org_user_name,
    oe.primary_email AS org_primary_email,
    entitys.entity_id,
    entitys.entity_name,
    entitys.user_name,
    entitys.primary_email
   FROM vw_workflow_phases
     JOIN approvals ON vw_workflow_phases.workflow_phase_id = approvals.workflow_phase_id
     JOIN entitys oe ON approvals.org_entity_id = oe.entity_id
     JOIN reporting ON approvals.org_entity_id = reporting.entity_id AND vw_workflow_phases.reporting_level = reporting.reporting_level
     JOIN entitys ON reporting.report_to_id = entitys.entity_id
  WHERE approvals.forward_id IS NULL AND reporting.primary_report = true AND reporting.is_active = true AND vw_workflow_phases.use_reporting = true;


CREATE OR REPLACE VIEW vw_benefits AS 
 SELECT benefit_types.benefit_type_id,
    benefit_types.benefit_type_name,
    rate_types.rate_type_id,
    rate_types.rate_type_name,
    benefits.benefit_id,
    benefits.individual,
    benefits.others
   FROM benefits
     JOIN benefit_types ON benefits.benefit_type_id = benefit_types.benefit_type_id
     JOIN rate_types ON benefits.rate_type_id = rate_types.rate_type_id;


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




CREATE OR REPLACE VIEW vw_entity_subscriptions AS 
 SELECT entity_types.entity_type_id,
    entity_types.entity_type_name,
    entitys.entity_id,
    entitys.entity_name,
    subscription_levels.subscription_level_id,
    subscription_levels.subscription_level_name,
    entity_subscriptions.entity_subscription_id,
    entity_subscriptions.org_id,
    entity_subscriptions.details
   FROM entity_subscriptions
     JOIN entity_types ON entity_subscriptions.entity_type_id = entity_types.entity_type_id
     JOIN entitys ON entity_subscriptions.entity_id = entitys.entity_id
     JOIN subscription_levels ON entity_subscriptions.subscription_level_id = subscription_levels.subscription_level_id;



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




CREATE OR REPLACE VIEW vw_entry_forms AS 
 SELECT entitys.entity_id,
    entitys.entity_name,
    forms.form_id,
    forms.form_name,
    entry_forms.entry_form_id,
    entry_forms.org_id,
    entry_forms.approve_status,
    entry_forms.application_date,
    entry_forms.completion_date,
    entry_forms.action_date,
    entry_forms.narrative,
    entry_forms.answer,
    entry_forms.workflow_table_id,
    entry_forms.details
   FROM entry_forms
     JOIN entitys ON entry_forms.entity_id = entitys.entity_id
     JOIN forms ON entry_forms.form_id = forms.form_id;




CREATE OR REPLACE VIEW vw_fields AS 
 SELECT forms.form_id,
    forms.form_name,
    fields.field_id,
    fields.org_id,
    fields.question,
    fields.field_lookup,
    fields.field_type,
    fields.field_order,
    fields.share_line,
    fields.field_size,
    fields.field_fnct,
    fields.manditory,
    fields.field_bold,
    fields.field_italics
   FROM fields
     JOIN forms ON fields.form_id = forms.form_id;





CREATE OR REPLACE VIEW vw_org_select AS 
 SELECT orgs.org_id,
    orgs.parent_org_id,
    orgs.org_name
   FROM orgs
  WHERE orgs.is_active = true AND orgs.org_id <> orgs.parent_org_id
UNION
 SELECT orgs.org_id,
    orgs.org_id AS parent_org_id,
    orgs.org_name
   FROM orgs
  WHERE orgs.is_active = true;



CREATE OR REPLACE VIEW vw_rates AS 
 SELECT rate_types.rate_type_id,
    rate_types.rate_type_name,
    rates.rate_id,
    rates.days_from,
    rates.days_to,
    rates.standard_rate,
    rates.north_america_rate
   FROM rates
     JOIN rate_types ON rates.rate_type_id = rate_types.rate_type_id;


CREATE OR REPLACE VIEW vw_passengers AS 
 SELECT orgs.org_id,
    orgs.org_name,
    vw_rates.rate_type_id,
    vw_rates.rate_type_name,
    vw_rates.rate_id,
    passengers.days_from,
    passengers.days_to,
    vw_rates.standard_rate,
    vw_rates.north_america_rate,
    passengers.approved,
    passengers.entity_id,
    passengers.passenger_id,
    passengers.passenger_name,
    passengers.passenger_mobile,
    passengers.passenger_email,
    passengers.passenger_age,
    passengers.days_covered,
    passengers.nok_name,
    passengers.nok_mobile,
    passengers.nok_national_id,
    passengers.cover_amount,
    passengers.is_north_america,
    passengers.details,
    entitys.entity_name,
    passengers.destown,
    passengers.approved_date
   FROM passengers
     JOIN orgs ON passengers.org_id = orgs.org_id
     JOIN vw_rates ON passengers.rate_id = vw_rates.rate_id
     JOIN entitys ON passengers.entity_id = entitys.entity_id;




CREATE OR REPLACE VIEW vw_payments AS 
 SELECT orgs.org_id,
    orgs.org_name,
    payment_types.payment_type_id,
    payment_types.payment_type_name,
    payments.payment_id,
    payments.payment_amount,
    payments.transaction_reference,
    payments.payment_date,
    payments.approved,
    payments.details
   FROM payments
     JOIN orgs ON payments.org_id = orgs.org_id
     JOIN payment_types ON payments.payment_type_id = payment_types.payment_type_id;




CREATE OR REPLACE VIEW vw_receipts AS 
 SELECT orgs.org_id,
    orgs.org_name,
    receipts.receipt_id,
    receipts.mpesa_trx_id,
    receipts.receipt_date,
    receipts.receipt_amount,
    receipts.details
   FROM receipts
     JOIN orgs ON receipts.org_id = orgs.org_id;


CREATE OR REPLACE VIEW vw_reporting AS 
 SELECT entitys.entity_id,
    entitys.entity_name,
    rpt.entity_id AS rpt_id,
    rpt.entity_name AS rpt_name,
    reporting.org_id,
    reporting.reporting_id,
    reporting.date_from,
    reporting.date_to,
    reporting.primary_report,
    reporting.is_active,
    reporting.ps_reporting,
    reporting.reporting_level,
    reporting.details
   FROM reporting
     JOIN entitys ON reporting.entity_id = entitys.entity_id
     JOIN entitys rpt ON reporting.report_to_id = rpt.entity_id;



CREATE OR REPLACE VIEW vw_sms AS 
 SELECT folders.folder_id,
    folders.folder_name,
    sms.sms_id,
    sms.sms_number,
    sms.message_ready,
    sms.sent,
    sms.message,
    sms.details,
    sms.org_id,
    vw_address.address_name,
    to_char(sms.sms_time, 'yyyy-mm-dd'::text) AS date,
    sms.sms_count,
    address_groups.address_group_id,
    address_groups.address_group_name
   FROM sms
     JOIN folders ON sms.folder_id = folders.folder_id
     LEFT JOIN vw_address ON sms.sms_number::text = vw_address.mobile::text AND sms.org_id = vw_address.org_id
     LEFT JOIN address_groups ON sms.address_group_id = address_groups.address_group_id;



CREATE OR REPLACE VIEW vw_sms_address AS 
 SELECT folders.folder_id,
    folders.folder_name,
    sms.sms_id,
    sms.sms_number,
    sms.message_ready,
    sms.sent,
    sms.message,
    address.address_id,
    address.address_name,
    address.mobile,
    sms_address.sms_address_id,
    sms_address.org_id,
    sms_address.narrative
   FROM sms
     JOIN folders ON sms.folder_id = folders.folder_id
     JOIN sms_address ON sms.sms_id = sms_address.sms_id
     JOIN address ON sms_address.address_id = address.address_id;



CREATE OR REPLACE VIEW vw_sms_entitys AS 
 SELECT orgs.org_id,
    orgs.org_name,
    orgs.is_default AS org_is_default,
    orgs.is_active AS org_is_active,
    orgs.logo AS org_logo,
    orgs.pcc,
    orgs.sp_id,
    orgs.service_id,
    orgs.sender_name,
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
    entity_types.use_key,
    entitys.son
   FROM entitys
     LEFT JOIN vw_entity_address ON entitys.entity_id = vw_entity_address.table_id
     JOIN orgs ON entitys.org_id = orgs.org_id
     JOIN entity_types ON entitys.entity_type_id = entity_types.entity_type_id;



CREATE OR REPLACE VIEW vw_sub_fields AS 
 SELECT vw_fields.form_id,
    vw_fields.form_name,
    vw_fields.field_id,
    sub_fields.sub_field_id,
    sub_fields.org_id,
    sub_fields.sub_field_order,
    sub_fields.sub_title_share,
    sub_fields.sub_field_type,
    sub_fields.sub_field_lookup,
    sub_fields.sub_field_size,
    sub_fields.sub_col_spans,
    sub_fields.manditory,
    sub_fields.question
   FROM sub_fields
     JOIN vw_fields ON sub_fields.field_id = vw_fields.field_id;


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



CREATE OR REPLACE VIEW vw_sys_emailed AS 
 SELECT sys_emails.sys_email_id,
    sys_emails.org_id,
    sys_emails.sys_email_name,
    sys_emails.title,
    sys_emails.details,
    sys_emailed.sys_emailed_id,
    sys_emailed.table_id,
    sys_emailed.table_name,
    sys_emailed.email_type,
    sys_emailed.emailed,
    sys_emailed.narrative
   FROM sys_emails
     RIGHT JOIN sys_emailed ON sys_emails.sys_email_id = sys_emailed.sys_email_id;


CREATE OR REPLACE VIEW vw_travdoc_user AS 
 SELECT vw_orgs.org_id,
    vw_orgs.org_name,
    vw_orgs.pcc,
    vw_orgs.gds_free_field,
    vw_orgs.show_fare,
    vw_orgs.logo,
    vw_entity_address.table_id,
    vw_entity_address.table_name,
    vw_entity_address.post_office_box,
    vw_entity_address.postal_code,
    vw_entity_address.premises,
    vw_entity_address.street,
    vw_entity_address.town,
    vw_entity_address.phone_number,
    vw_entity_address.email,
    vw_entity_address.sys_country_name,
    entitys.entity_id,
    entitys.entity_name,
    entitys.son,
    entitys.phone_ph,
    entitys.phone_pa,
    entitys.phone_pb,
    entitys.phone_pt
   FROM entitys
     LEFT JOIN vw_entity_address ON entitys.entity_id = vw_entity_address.table_id
     JOIN vw_orgs ON entitys.org_id = vw_orgs.org_id
     JOIN entity_types ON entitys.entity_type_id = entity_types.entity_type_id;


CREATE OR REPLACE VIEW vw_usage AS 
 SELECT sms.sms_id,
    to_char(sms.sms_time, 'yyyy-mm-dd'::text) AS date,
    sms.sms_count,
    sms.entity_id,
    sms.org_id,
    sms.sent,
    entitys.son,
    orgs.pcc
   FROM sms
     JOIN entitys ON entitys.entity_id = sms.entity_id
     JOIN orgs ON orgs.org_id = sms.org_id;



CREATE OR REPLACE VIEW vw_workflow_approvals AS 
 SELECT vw_approvals.workflow_id,
    vw_approvals.org_id,
    vw_approvals.workflow_name,
    vw_approvals.approve_email,
    vw_approvals.reject_email,
    vw_approvals.source_entity_id,
    vw_approvals.source_entity_name,
    vw_approvals.table_name,
    vw_approvals.table_id,
    vw_approvals.org_entity_id,
    vw_approvals.org_entity_name,
    vw_approvals.org_user_name,
    vw_approvals.org_primary_email,
    rt.rejected_count,
        CASE
            WHEN rt.rejected_count IS NULL THEN vw_approvals.workflow_name::text || ' Approved'::text
            ELSE vw_approvals.workflow_name::text || ' declined'::text
        END AS workflow_narrative
   FROM vw_approvals
     LEFT JOIN ( SELECT approvals.table_id,
            count(approvals.approval_id) AS rejected_count
           FROM approvals
          WHERE approvals.approve_status::text = 'Rejected'::text AND approvals.forward_id IS NULL
          GROUP BY approvals.table_id) rt ON vw_approvals.table_id = rt.table_id
  GROUP BY vw_approvals.workflow_id, vw_approvals.org_id, vw_approvals.workflow_name, vw_approvals.approve_email, vw_approvals.reject_email, vw_approvals.source_entity_id, vw_approvals.source_entity_name, vw_approvals.table_name, vw_approvals.table_id, vw_approvals.org_entity_id, vw_approvals.org_entity_name, vw_approvals.org_user_name, vw_approvals.org_primary_email, rt.rejected_count;



CREATE OR REPLACE VIEW vw_workflow_entitys AS 
 SELECT vw_workflow_phases.workflow_id,
    vw_workflow_phases.org_id,
    vw_workflow_phases.workflow_name,
    vw_workflow_phases.table_name,
    vw_workflow_phases.table_link_id,
    vw_workflow_phases.source_entity_id,
    vw_workflow_phases.source_entity_name,
    vw_workflow_phases.approval_entity_id,
    vw_workflow_phases.approval_entity_name,
    vw_workflow_phases.workflow_phase_id,
    vw_workflow_phases.approval_level,
    vw_workflow_phases.return_level,
    vw_workflow_phases.escalation_days,
    vw_workflow_phases.escalation_hours,
    vw_workflow_phases.notice,
    vw_workflow_phases.notice_email,
    vw_workflow_phases.notice_file,
    vw_workflow_phases.advice,
    vw_workflow_phases.advice_email,
    vw_workflow_phases.advice_file,
    vw_workflow_phases.required_approvals,
    vw_workflow_phases.use_reporting,
    vw_workflow_phases.phase_narrative,
    entity_subscriptions.entity_subscription_id,
    entity_subscriptions.entity_id,
    entity_subscriptions.subscription_level_id
   FROM vw_workflow_phases
     JOIN entity_subscriptions ON vw_workflow_phases.source_entity_id = entity_subscriptions.entity_type_id;





---Travsms tables script------------

CREATE OR REPLACE FUNCTION ins_sms_trans() RETURNS trigger AS $$
DECLARE
	rec RECORD;
	msg varchar(2400);
BEGIN
	IF(NEW.part_no = NEW.part_count) THEN
		IF(NEW.part_no = 1) THEN
			INSERT INTO sms (folder_id, sms_number, message)
			VALUES(3, NEW.origin, NEW.message);

			NEW.sms_picked = true;
		ELSE
			msg := '';
			FOR rec IN SELECT part_no, message FROM sms_trans WHERE (part_id = NEW.part_id) AND (origin = NEW.origin) AND (sms_picked = false)
			ORDER BY part_no LOOP
				msg := msg || rec.message;
			END LOOP;
			msg := msg || NEW.message;

			INSERT INTO sms (folder_id, sms_number, message)
			VALUES(3, NEW.origin, msg);

			UPDATE sms_trans SET sms_picked = true WHERE (part_id = NEW.part_id) AND (origin = NEW.origin) AND (sms_picked = false);
			NEW.sms_picked = true;
		END IF;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_sms_trans BEFORE INSERT ON sms_trans    FOR EACH ROW EXECUTE PROCEDURE ins_sms_trans();
CREATE OR REPLACE FUNCTION ins_sms() RETURNS trigger AS $$
BEGIN
	
	IF(NEW.addresses is not null)THEN
		IF(NEW.sms_numbers is null) THEN
			NEW.sms_numbers := NEW.addresses;
		ELSE
			NEW.sms_numbers := NEW.sms_numbers || ',' || NEW.addresses;
		END IF;
	END IF;
	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_sms BEFORE INSERT OR UPDATE ON sms   FOR EACH ROW EXECUTE PROCEDURE ins_sms();

CREATE OR REPLACE FUNCTION aft_sms() RETURNS trigger AS $$
BEGIN
	IF (NEW.smsServiceActivationNumber = 'tel:20583') THEN
		INSERT INTO sms (org_id, folder_id, sms_origin, sms_number, linkid, message_ready, message)
		VALUES (0, 0, '20583', '254' || replace(NEW.senderAddress, 'tel:', ''), NEW.linkid, true, 'Thank you for contacting the Judiciary Service Desk. Your submission is being attended to. For further assistance call 020 2221221.');

		INSERT INTO sys_emailed (org_id, sys_email_id, table_name, table_id)
		VALUES (0, 1, 'sms', NEW.sms_id);
	END IF;

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER aft_sms AFTER INSERT ON sms    FOR EACH ROW EXECUTE PROCEDURE aft_sms();

CREATE OR REPLACE FUNCTION ins_member_address(varchar(12), varchar(32), varchar(32)) RETURNS varchar(120) AS $$
DECLARE
	v_address_member_id		integer;
	v_org_id				integer;
	msg 					varchar(120);
BEGIN

	SELECT org_id INTO v_org_id
	FROM address_groups WHERE address_group_id = CAST($3 as int);

	SELECT address_member_id INTO v_address_member_id
	FROM address_members
	WHERE (address_id = CAST($1 as int)) AND (address_group_id = CAST($3 as int));

	IF(v_address_member_id is null)THEN
		INSERT INTO address_members (address_group_id, address_id, org_id, is_active)
		VALUES(CAST($3 as int), CAST($1 as int), v_org_id, true);
		msg := 'Address added';
	ELSE
		msg := 'No duplicates address allowed';
		RAISE EXCEPTION 'No duplicates address allowed';
	END IF;

	return msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ins_sms_address(varchar(12), varchar(32), varchar(32)) RETURNS varchar(120) AS $$
DECLARE
	v_sms_address_id		integer;
	v_org_id				integer;
	msg 					varchar(120);
BEGIN
	SELECT org_id INTO v_org_id
	FROM sms WHERE sms_id = CAST($3 as int);

	SELECT sms_address_id INTO v_sms_address_id
	FROM sms_address
	WHERE (address_id = CAST($1 as int)) AND (sms_id = CAST($3 as int));

	IF(v_sms_address_id is null)THEN
		INSERT INTO sms_address (sms_id, address_id, org_id)
		VALUES(CAST($3 as int), CAST($1 as int), v_org_id);
		msg := 'Address Added';
	ELSE
		msg := 'No duplicates address allowed';
		RAISE EXCEPTION 'No duplicates address allowed';
	END IF;

	return msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION aft_sms()
  RETURNS trigger AS
$BODY$
BEGIN
	IF (NEW.smsServiceActivationNumber = 'tel:20583') THEN
		INSERT INTO sms (org_id, folder_id, sms_origin, sms_number, linkid, message_ready, message)
		VALUES (0, 0, '20583', '254' || replace(NEW.senderAddress, 'tel:', ''), NEW.linkid, true, 'Thank you for contacting the Judiciary Service Desk. Your submission is being attended to. For further assistance call 020 2221221.');

		INSERT INTO sys_emailed (org_id, sys_email_id, table_name, table_id)
		VALUES (0, 1, 'sms', NEW.sms_id);
	END IF;

	RETURN NULL;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION ins_address()
  RETURNS trigger AS
$$
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
$$
  LANGUAGE plpgsql ;
  
  
  CREATE TRIGGER ins_address  BEFORE INSERT OR UPDATE  ON address  FOR EACH ROW  EXECUTE PROCEDURE ins_address();
  
  CREATE OR REPLACE FUNCTION ins_approvals()
  RETURNS trigger AS
$BODY$
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
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  CREATE TRIGGER ins_approvals  BEFORE INSERT  ON approvals  FOR EACH ROW  EXECUTE PROCEDURE ins_approvals();
  
  CREATE OR REPLACE FUNCTION ins_entitys()
  RETURNS trigger AS
$BODY$
BEGIN
	IF(NEW.entity_type_id is not null) THEN
		INSERT INTO Entity_subscriptions (org_id, entity_type_id, entity_id, subscription_level_id)
		VALUES (NEW.org_id, NEW.entity_type_id, NEW.entity_id, 0);
	END IF;

	RETURN NULL;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  
  
  CREATE TRIGGER ins_entitys  AFTER INSERT  ON entitys  FOR EACH ROW  EXECUTE PROCEDURE ins_entitys();
  
  CREATE OR REPLACE FUNCTION ins_entry_forms()
  RETURNS trigger AS
$BODY$
DECLARE
	reca		RECORD;
BEGIN
	
	SELECT default_values, default_sub_values INTO reca
	FROM forms
	WHERE (form_id = NEW.form_id);
	
	NEW.answer := reca.default_values;
	NEW.sub_answer := reca.default_sub_values;

	RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  
  CREATE TRIGGER ins_entry_forms  BEFORE INSERT  ON entry_forms  FOR EACH ROW  EXECUTE PROCEDURE ins_entry_forms();
  
  CREATE OR REPLACE FUNCTION ins_fields()
  RETURNS trigger AS
$BODY$
DECLARE
	v_ord	integer;
BEGIN
	IF(NEW.field_order is null) THEN
		SELECT max(field_order) INTO v_ord
		FROM fields
		WHERE (form_id = NEW.form_id);

		IF (v_ord is null) THEN
			NEW.field_order := 10;
		ELSE
			NEW.field_order := v_ord + 10;
		END IF;
	END IF;

	RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  
  CREATE TRIGGER ins_fields  BEFORE INSERT  ON fields  FOR EACH ROW  EXECUTE PROCEDURE ins_fields();
  
  CREATE OR REPLACE FUNCTION ins_password()
  RETURNS trigger AS
$BODY$
BEGIN
	IF(NEW.first_password is null) AND (TG_OP = 'INSERT') THEN
		NEW.first_password := first_password();
	END IF;
	IF(TG_OP = 'INSERT') THEN
		IF (NEW.Entity_password is null) THEN
			NEW.Entity_password := md5(NEW.first_password);
		END IF;
	ELSIF(OLD.first_password <> NEW.first_password) THEN
		NEW.Entity_password := md5(NEW.first_password);
	END IF;

	RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  
  CREATE TRIGGER ins_password  BEFORE INSERT OR UPDATE  ON entitys  FOR EACH ROW  EXECUTE PROCEDURE ins_password();
  
  CREATE OR REPLACE FUNCTION ins_sms()
  RETURNS trigger AS
$BODY$
BEGIN
	
	IF(NEW.addresses is not null)THEN
		IF(NEW.sms_numbers is null) THEN
			NEW.sms_numbers := NEW.addresses;
		ELSE
			NEW.sms_numbers := NEW.sms_numbers || ',' || NEW.addresses;
		END IF;
	END IF;
	
	RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  
  CREATE OR REPLACE FUNCTION ins_sms_trans()
  RETURNS trigger AS
$BODY$
DECLARE
	rec RECORD;
	msg varchar(2400);
BEGIN
	IF(NEW.part_no = NEW.part_count) THEN
		IF(NEW.part_no = 1) THEN
			INSERT INTO sms (folder_id, sms_number, message)
			VALUES(3, NEW.origin, NEW.message);

			NEW.sms_picked = true;
		ELSE
			msg := '';
			FOR rec IN SELECT part_no, message FROM sms_trans WHERE (part_id = NEW.part_id) AND (origin = NEW.origin) AND (sms_picked = false)
			ORDER BY part_no LOOP
				msg := msg || rec.message;
			END LOOP;
			msg := msg || NEW.message;

			INSERT INTO sms (folder_id, sms_number, message)
			VALUES(3, NEW.origin, msg);

			UPDATE sms_trans SET sms_picked = true WHERE (part_id = NEW.part_id) AND (origin = NEW.origin) AND (sms_picked = false);
			NEW.sms_picked = true;
		END IF;
	END IF;

	RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  CREATE OR REPLACE FUNCTION ins_sub_fields()
  RETURNS trigger AS
$BODY$
DECLARE
	v_ord	integer;
BEGIN
	IF(NEW.sub_field_order is null) THEN
		SELECT max(sub_field_order) INTO v_ord
		FROM sub_fields
		WHERE (field_id = NEW.field_id);

		IF (v_ord is null) THEN
			NEW.sub_field_order := 10;
		ELSE
			NEW.sub_field_order := v_ord + 10;
		END IF;
	END IF;

	RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  
  CREATE TRIGGER ins_sub_fields  BEFORE INSERT  ON sub_fields  FOR EACH ROW  EXECUTE PROCEDURE ins_sub_fields();
  
  CREATE OR REPLACE FUNCTION ins_sys_reset()
  RETURNS trigger AS
$BODY$
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
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  
  CREATE TRIGGER ins_sys_reset  AFTER INSERT  ON sys_reset  FOR EACH ROW  EXECUTE PROCEDURE ins_sys_reset();
  
  CREATE OR REPLACE FUNCTION upd_action()
  RETURNS trigger AS
$BODY$
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
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  
  CREATE TRIGGER upd_action  BEFORE INSERT OR UPDATE  ON entry_forms  FOR EACH ROW  EXECUTE PROCEDURE upd_action();
  
  CREATE OR REPLACE FUNCTION upd_approvals()
  RETURNS trigger AS
$BODY$
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
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  CREATE TRIGGER upd_approvals  AFTER INSERT OR UPDATE  ON approvals  FOR EACH ROW  EXECUTE PROCEDURE upd_approvals();
  
  CREATE OR REPLACE FUNCTION upd_passengers()
  RETURNS trigger AS
$BODY$
DECLARE

BEGIN
	IF(NEW.approved = true) THEN
		NEW.approved_date = CURRENT_TIMESTAMP; 
	END IF;
	RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
CREATE TRIGGER upd_passengers  BEFORE UPDATE  ON passengers  FOR EACH ROW  EXECUTE PROCEDURE upd_passengers();


