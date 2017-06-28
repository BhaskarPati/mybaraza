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

CREATE TABLE sys_audit_trail (
	sys_audit_trail_id		integer primary key,
	user_id					varchar(50) not null,
	user_ip					varchar(50),
	change_date				timestamp default CURRENT_TIMESTAMP not null,
	table_name				varchar(50) not null,
	record_id				varchar(50) not null,
	change_type				varchar(50) not null,
	narrative				varchar(240)
);
CREATE SEQUENCE seq_sys_audit_trail_id MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER trg_sys_audit_trail BEFORE INSERT ON sys_audit_trail
for each row 
begin     
	if inserting then 
		if :NEW.sys_audit_trail_id is null then
			SELECT seq_sys_audit_trail_id.nextval into :NEW.sys_audit_trail_id from dual;
		end if;
	end if; 
end;
/

CREATE TABLE sys_audit_details (
	sys_audit_detail_id		integer primary key,
	sys_audit_trail_id		integer references sys_audit_trail,
	new_value				clob
);
CREATE INDEX sys_audit_sys_audit_trail_id ON sys_audit_details (sys_audit_trail_id);
CREATE SEQUENCE seq_sys_audit_detail_id MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER trg_sys_audit_details BEFORE INSERT ON sys_audit_details
for each row 
begin     
	if inserting then 
		if :NEW.sys_audit_detail_id is null then
			SELECT seq_sys_audit_detail_id.nextval into :NEW.sys_audit_detail_id from dual;
		end if;
	end if; 
end;
/

CREATE TABLE sys_queries (
	sys_query_name			varchar(50) primary key,
	query_date				timestamp default CURRENT_TIMESTAMP not null,
	query_text				clob,
	query_params			clob
);

CREATE TABLE sys_errors (
	sys_error_id			integer primary key,
	sys_error				varchar(240) not null,
	error_message			clob not null
);
CREATE SEQUENCE seq_sys_error_id MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER trg_sys_errors BEFORE INSERT ON sys_errors
for each row 
begin     
	if inserting then 
		if :NEW.sys_error_id is null then
			SELECT seq_sys_error_id.nextval into :NEW.sys_error_id from dual;
		end if;
	end if; 
end;
/

INSERT INTO sys_errors (sys_error, error_message) VALUES (20010, 'SORRY. THERE ARE PENDING (mandatory) CHECKLISTS. Approval Rejected');
INSERT INTO sys_errors (sys_error, error_message) VALUES (20011, 'SORRY. THE LICENSEE NEEDS TO CLEAR WITH FINANCE BEFORE PROCEEDING');
INSERT INTO sys_errors (sys_error, error_message) VALUES (20012, 'SORRY. YOU NEED TO INPUT THE TYPE APPROVAL FEE FOR ALL EQUIPMENT IN THIS APPLICATION');
INSERT INTO sys_errors (sys_error, error_message) VALUES (20015, 'SORRY. PLEASE SELECT A LICENSE');

CREATE TABLE sys_news (
	sys_news_id				integer primary key,
	sys_news_group			integer,
	sys_news_title			varchar(240) not null,
	publish					char(1) default '0' not null,
	details					clob
);
CREATE SEQUENCE seq_sys_news_id MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER trg_sys_news BEFORE INSERT ON sys_news
for each row 
begin     
	if inserting then 
		if :NEW.sys_news_id is null then
			SELECT seq_sys_news_id.nextval into :NEW.sys_news_id from dual;
		end if;
	end if; 
end;
/

CREATE TABLE sys_passwords (
	sys_password_id			integer primary key,
	sys_user_name			varchar(240) not null,
	password_sent			char(1) default '0' not null
);
CREATE SEQUENCE seq_sys_password_id MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER trg_sys_passwords BEFORE INSERT ON sys_passwords
for each row 
begin     
	if inserting then 
		if :NEW.sys_password_id is null then
			SELECT seq_sys_password_id.nextval into :NEW.sys_password_id from dual;
		end if;
	end if; 
end;
/

CREATE TABLE sys_files (
	sys_file_id				integer primary key,
	table_id				integer,
	table_name				varchar(50),
	file_name				varchar(240),
	file_type				varchar(50),
	details					clob
);
CREATE INDEX sys_files_table_id ON sys_files (table_id);
CREATE SEQUENCE seq_sys_file_id MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER trg_sys_files BEFORE INSERT ON sys_files
for each row 
begin     
	if inserting then 
		if :NEW.sys_file_id is null then
			SELECT seq_sys_file_id.nextval into :NEW.sys_file_id from dual;
		end if;
	end if; 
end;
/

CREATE TABLE address_types (
	address_type_id			integer primary key,
	address_type_name		varchar(50)
);

CREATE TABLE address (
	address_id				integer primary key,
	address_name			varchar(120),
	address_type_id			integer references address_types,
	sys_country_id			char(2) references sys_countrys,
	table_name				varchar(32),
	table_id				integer,
	post_office_box			varchar(50),
	postal_code				varchar(12),
	premises_floor			varchar(50),
	premises				varchar(120),
	street					varchar(120),
	town					varchar(50),
	phone_number			varchar(150),
	extension				varchar(15),
	mobile					varchar(150),
	fax						varchar(150),
	email					varchar(120),
	website					varchar(120),
	is_default				char(1),
	first_password			varchar(32),
	details					clob
);
CREATE INDEX address_sys_country_id ON address (sys_country_id);
CREATE INDEX address_address_type_id ON address (address_type_id);
CREATE INDEX address_table_name ON address (table_name);
CREATE INDEX address_table_id ON address (table_id);
CREATE SEQUENCE seq_address_id MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER trg_address BEFORE INSERT ON address
for each row 
begin     
	if inserting then 
		if :NEW.address_id is null then
			SELECT seq_address_id.nextval into :NEW.address_id from dual;
		end if;
	end if; 
end;
/

CREATE TABLE orgs (
	org_id					integer primary key,
	org_name				varchar(50),
	is_default				char(1) default '1' not null,
	is_active				char(1) default '1' not null,
	logo					varchar(50),
	details					clob
);
CREATE SEQUENCE seq_org_id MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER trg_orgs BEFORE INSERT ON orgs
for each row 
begin     
	if inserting then 
		if :NEW.org_id is null then
			SELECT seq_org_id.nextval into :NEW.org_id from dual;
		end if;
	end if; 
end;
/

INSERT INTO orgs (org_id, org_name, logo) 
VALUES (0, 'default', 'logo.png');

CREATE TABLE entity_types (
	entity_type_id			integer primary key,
	entity_type_name		varchar(50) unique,		--things like Checking Staff, Approving officers, etc
	entity_role				varchar(240),			--checking, approving, freq assignment etc
	use_key					integer default 0 not null,	
	Description				clob,
	Details					clob
);
ALTER TABLE entity_types ADD department_id integer references department;		--section eg planning.. etc
ALTER TABLE entity_types ADD group_email varchar(120);
ALTER TABLE entity_types ADD is_official char(1) DEFAULT '1' NOT NULL;			--wether its an official designation or just a role in the system

CREATE SEQUENCE seq_entity_type_id MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER trg_entity_types BEFORE INSERT ON entity_types
for each row 
begin     
	if inserting then 
		if :NEW.entity_type_id is null then
			SELECT seq_entity_type_id.nextval into :NEW.entity_type_id from dual;
		end if;
		if :NEW.entity_role is null then
			:NEW.entity_role := :NEW.entity_type_name;
		end if;
	end if; 
end;
/

INSERT INTO entity_types (entity_type_id, entity_type_name, entity_role) VALUES (0, 'Users', 'user');
INSERT INTO entity_types (entity_type_id, entity_type_name, entity_role) VALUES (1, 'Staff', 'staff');
INSERT INTO entity_types (entity_type_id, entity_type_name, entity_role) VALUES (2, 'Client', 'client');
INSERT INTO entity_types (entity_type_id, entity_type_name, entity_role) VALUES (3, 'Supplier', 'supplier');
INSERT INTO entity_types (entity_type_id, entity_type_name, entity_role) VALUES (4, 'FSM', 'FSM');

CREATE TABLE entitys (
	entity_id				integer primary key,
	org_id					integer references orgs,
	entity_type_id			integer references entity_types,
	entity_name				varchar(120) not null,
	user_name				varchar(120),
	primary_email			varchar(120),
	super_user				char(1) default '0' not null,
	entity_leader			char(1) default '0',
	function_role			varchar(240),
	date_enroled			timestamp default CURRENT_TIMESTAMP,
	is_active				char(1) default '1',
	entity_password			varchar(32) default 'enter' not null,
	first_password			varchar(32) default 'enter' not null,
	details					clob,
	UNIQUE(org_id, User_name)
);
CREATE INDEX entitys_org_id ON entitys (org_id);
CREATE SEQUENCE seg_entity_id MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER trg_entitys BEFORE INSERT ON entitys
for each row 
begin     
	if inserting then 
		if :NEW.entity_id is null then
			SELECT seg_entity_id.nextval into :NEW.entity_id from dual;
		end if;
	end if; 
end;
/
INSERT INTO entitys (entity_id, org_id, entity_type_id, user_name, entity_name, Entity_Leader, Super_User)  
VALUES (0, 0, 0, 'root', 'root', '1', '1');
--dummy user
INSERT INTO entitys (entity_id, org_id, entity_type_id, user_name, entity_name, Entity_Leader, Super_User)  
VALUES (1, 1, 4, 'dummy', 'Dummy User', '1', '0');
commit;


CREATE TABLE subscription_levels (
	subscription_level_id	integer primary key,
	subscription_level_name	varchar(50),
	details					clob
);
INSERT INTO subscription_levels (subscription_level_id, subscription_level_name) VALUES (0, 'Basic');
INSERT INTO subscription_levels (subscription_level_id, subscription_level_name) VALUES (1, 'Manager');
INSERT INTO subscription_levels (subscription_level_id, subscription_level_name) VALUES (2, 'Consumer');

CREATE TABLE entity_subscriptions (
	entity_subscription_id	integer primary key,
	entity_type_id			integer references entity_types,
	entity_id				integer references entitys,	
	details					clob,
	UNIQUE(entity_id, entity_type_id)
);
ALTER TABLE entity_subscriptions ADD subscription_level_id integer references subscription_levels;

CREATE INDEX entity_sub_entity_type_id ON entity_subscriptions (entity_type_id);
CREATE INDEX entity_sub_entity_id ON entity_subscriptions (entity_id);
CREATE INDEX entity_sub_sub_level_id ON entity_subscriptions (subscription_level_id);
CREATE SEQUENCE seq_entity_subscription_id MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER trg_entity_subscriptions BEFORE INSERT ON entity_subscriptions
for each row 
begin     
	if inserting then 
		if :NEW.entity_subscription_id is null then
			SELECT seq_entity_subscription_id.nextval into :NEW.entity_subscription_id from dual;
		end if;
	end if; 
end;
/
INSERT INTO Entity_subscriptions (Entity_subscription_id, entity_type_id, entity_id, subscription_level_id)  VALUES (0, 0, 0, 0);
--test user
INSERT INTO Entity_subscriptions (Entity_subscription_id, entity_type_id, entity_id, subscription_level_id)  VALUES (1, 4, 1, 0);

CREATE TABLE sys_logins (
	sys_login_id			integer primary key,
	entity_id				integer references entitys,
	login_time				timestamp default CURRENT_TIMESTAMP,
	login_ip				varchar(64),
	narrative				varchar(240)
);
CREATE INDEX sys_logins_entity_id ON sys_logins (entity_id);
CREATE SEQUENCE seq_sys_login_id MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER trg_sys_logins BEFORE INSERT ON sys_logins
for each row 
begin     
	if inserting then 
		if :NEW.sys_login_id is null then
			SELECT seq_sys_login_id.nextval into :NEW.sys_login_id from dual;
		end if;
	end if; 
end;
/

--EMAIL_TEMPLATE
CREATE TABLE sys_emails (
	sys_email_id			integer primary key,
	sys_email_name			varchar(50),
	title					varchar(240) not null,
	details					clob
);
CREATE SEQUENCE seq_sys_email_id MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER trg_sys_emails BEFORE INSERT ON sys_emails
for each row 
begin     
	if inserting then 
		if :NEW.sys_email_id is null then
			SELECT seq_sys_email_id.nextval into :NEW.sys_email_id from dual;
		end if;
	end if; 
end;
/


	
	

--email log
CREATE TABLE sys_emailed (
	sys_emailed_id			integer primary key,
	sys_email_id			integer references sys_emails,
	table_id				integer,				--specific row (using pk)
	table_name				varchar(50),			--table concerned
	email_level				integer default 1 not null,
	emailed					char(1) default '0' not null,
	narrative				varchar(240)
);
ALTER TABLE sys_emailed ADD email_type	integer default 1 not null;		--UTILITY COLUMN

ALTER TABLE sys_emailed ADD created date default SYSDATE;
ALTER TABLE sys_emailed ADD created_by integer references entitys;		--INITIAL INSERT
ALTER TABLE sys_emailed ADD updated date default SYSDATE;
ALTER TABLE sys_emailed ADD updated_by integer references entitys;

CREATE INDEX sys_emailed_sys_email_id ON sys_emailed (sys_email_id);
CREATE INDEX sys_emailed_table_id ON sys_emailed (table_id);
CREATE SEQUENCE seq_sys_emailed_id MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER trg_sys_emailed BEFORE INSERT ON sys_emailed
for each row 
begin     
	if inserting then 
		if :NEW.sys_emailed_id is null then
			SELECT seq_sys_emailed_id.nextval into :NEW.sys_emailed_id from dual;
		end if;
	end if; 
end;
/




-- arg one: actioncount arg two: keyfield
CREATE OR REPLACE FUNCTION Emailed(action_count IN varchar, keyfield IN varchar) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;

	BEGIN
		--APPROVALS (imis tasks)
		IF(action_count = '1') THEN		--approval
			UPDATE sys_emailed SET emailed = '1' WHERE (sys_emailed_id = CAST(keyfield as int));
			COMMIT;
		--CLC
		ELSIF(action_count = '5') THEN		
 			UPDATE sys_emailed SET emailed = '1' WHERE (sys_emailed_id = CAST(keyfield as int));
 			COMMIT;
		ELSIF(action_count = '10') THEN		
 			UPDATE sys_emailed SET emailed = '1' WHERE (sys_emailed_id = CAST(keyfield as int));
 			COMMIT;
-- 		--LCS NOTICES START HERE
-- 		ELSIF(action_count = '51') THEN		--Application acknowledgement
-- 			UPDATE clientlicenses SET isacknowlegementemailsent = '1' WHERE clientlicenseid = cast(keyfield as int);
-- 			COMMIT;		
-- 	
-- 		ELSIF(action_count = '52') THEN		--Application Differed acknowledgement
-- 			UPDATE clientlicenses SET isdifferalemailsent = '1' WHERE clientlicenseid = cast(keyfield as int);
-- 			COMMIT;
-- 
-- 		ELSIF(action_count = '53') THEN		--Gazettement Notice
-- 			UPDATE clientlicenses SET isgazettementemailsent = '1' WHERE clientlicenseid = cast(keyfield as int);
-- 			COMMIT;
-- 
-- 		ELSIF(action_count = '54') THEN		--License approval notice
-- 			UPDATE clientlicenses SET islicenseapprovalemailsent = '1' WHERE clientlicenseid = cast(keyfield as int);
-- 			COMMIT;
-- 			
-- 		ELSIF(action_count = '55') THEN		--Reminder: Submission of Quarterly compliance returns
-- 			UPDATE clientlicenses SET iscomplreturnsQemailsent = '1' WHERE clientlicenseid = cast(keyfield as int);
-- 			COMMIT;
-- 
-- 		ELSIF(action_count = '56') THEN		--Reminder: Submission of Annual compliance returns
-- 			UPDATE clientlicenses SET iscomplreturnsAemailsent = '1' WHERE clientlicenseid = cast(keyfield as int);
-- 			COMMIT;
-- 
-- 		ELSIF(action_count = '57') THEN		--Reminder: Submission of Annual Audited Accounts 
-- 			UPDATE clientlicenses SET isAAAremindersent = '1' WHERE clientlicenseid = cast(keyfield as int);
-- 			COMMIT;
-- 
-- 		ELSIF(action_count = '58') THEN		--Number Allocation approval notice
-- 			UPDATE clientlicenses SET isnummberallocationemailsent = '1' WHERE clientlicenseid = cast(keyfield as int);
-- 			COMMIT;
-- 
-- 		ELSIF(action_count = '59') THEN		--Type approval Certificate
-- 			UPDATE clientlicenses SET isTAcertificateemailsent = '1' WHERE clientlicenseid = cast(keyfield as int);
-- 			COMMIT;

		END IF;

	RETURN 'Updated ' || keyfield || ' Successfuly';
END;
/




--ideal scenario: all tasks go thru a workflow
CREATE TABLE workflows (
	workflow_id				integer primary key,
	workflow_name			varchar(240) not null,
	table_name				varchar(64),		--table concerned	eg LICENSE
	table_link_field		varchar(64),		--pk field			eg LICENSE_ID
	table_link_id			integer,			--pk val			eg 1 for DUMMY LAND MOBILE SERVICE
	approve_email			clob,
	reject_email			clob,
		
	details					clob
);
ALTER TABLE workflows ADD UNIQUE(table_name,table_link_field,table_link_id);
ALTER TABLE workflows ADD source_entity_id	integer references entity_types;

ALTER TABLE workflows ADD approve_file varchar(320);
ALTER TABLE workflows ADD advice_file varchar(320);


CREATE SEQUENCE seq_workflow_id MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER trg_workflows BEFORE INSERT ON workflows
for each row 
begin     
	if inserting then 
		if :NEW.workflow_id is null then
			SELECT seq_workflow_id.nextval into :NEW.workflow_id from dual;
		end if;
	end if; 
end;
/


	
	
CREATE TABLE workflow_phases (
	workflow_phase_id		integer primary key,
	workflow_id				integer references workflows,
	entity_type_id			integer references entity_types,
	approval_entity_id		integer references entity_types,
	approval_level			integer default 1 not null,
	return_level			integer default 1 not null,
	escalation_hours		integer default 3 not null,
	required_approvals		integer default 1 not null,
	notice					char(1) default '0' not null,
	advice					char(1) default '0' not null,
	
	phase_narrative			varchar(240),		--name of the phase ?

	notice_email			clob,		--no action required on the part of the receiver. used when email is just FYI 
	advice_email			clob,		--ACTION in the workflow
	review_email			clob,

	details					clob
);
ALTER TABLE workflow_phases ADD advice_file varchar(320);
ALTER TABLE workflow_phases ADD notice_file varchar(320);

ALTER TABLE workflow_phases ADD UNIQUE(workflow_id,approval_level);
ALTER TABLE workflow_phases ADD is_utility char(1) default '0' not null;	-- miscleniouse eg approval/review/comment and mostly used with adhoc approvals
ALTER TABLE workflow_phases ADD is_done char(1) default '0' not null;
ALTER TABLE workflow_phases ADD payment_type_id	integer references payment_type;

SET SCAN OFF;
UPDATE workflow_phases 
SET advice_email = (SELECT '<p>{{approving_entity_name}},
</p><p>There is an IMIS task awaiting your action.</p><p>' ||
workflows.workflow_name || ': ' || workflow_phases.phase_narrative || '&nbsp; initiated by {{origin_entity_name}} on {{application_date}}. 
Time to completion of this task is {{escalation_time}} days.<br></p><p><a target="" title="Click here to view the task" href="http://localhost:8080/fsm/index.jsp?view=1:0">Click here to view the task</a><br></p>'
FROM workflow_phases
INNER JOIN workflows ON workflow_phases.workflow_id = workflows.workflow_id);


CREATE INDEX wp_workflow_id ON workflow_phases (workflow_id);
CREATE INDEX wp_entity_type_id ON workflow_phases (entity_type_id);
CREATE INDEX wp_approval_type_id ON workflow_phases (approval_type_id);
CREATE SEQUENCE seq_workflow_phase_id MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER trg_workflow_phases BEFORE INSERT ON workflow_phases
for each row 
begin     
	if inserting then 
		if :NEW.workflow_phase_id is null then
			SELECT seq_workflow_phase_id.nextval into :NEW.workflow_phase_id from dual;
		end if;
	end if; 
end;
/

CREATE OR REPLACE FUNCTION get_phase_email(ent_typ_id in integer) RETURN VARCHAR IS
PRAGMA AUTONOMOUS_TRANSACTION;
	--DECLARE
    --myrec	RECORD;
	my_email	varchar(320);
BEGIN
	my_email := null;
	FOR my_rec IN 
		(SELECT entitys.primary_email
		FROM entitys 
		INNER JOIN entity_subscriptions ON entitys.entity_id = entity_subscriptions.entity_id
		WHERE (entitys.primary_email IS NOT NULL) AND (entity_subscriptions.entity_type_id = ent_typ_id)) LOOP

		IF (my_email is null) THEN
			my_email := my_rec.primary_email;
		ELSE
			my_email := my_email || ',' || my_rec.primary_email;
		END IF;

	END LOOP;

	
	RETURN my_email;
	
END;
/
-- CREATE OR REPLACE TRIGGER tr_upd_wf_phases AFTER UPDATE ON workflow_phases
-- FOR EACH ROW
-- DECLARE
-- 	PRAGMA AUTONOMOUS_TRANSACTION;
-- 	
-- 	nxt_phase_id		    integer;
-- 	nxt_pay_type_id 		integer;
-- 	pay_header_id			integer;
-- 	app_fee					real;
--   
--    CURSOR cur_approval IS
--       SELECT approval_id, table_name, table_id, org_entity_id FROM approvals WHERE workflow_phase_id = :NEW.workflow_phase_id AND rownum = 1;--approval_level = 1;
-- 	  rec_approval cur_approval%ROWTYPE;
--     
-- begin    
-- 
-- 	OPEN cur_approval;
-- 	FETCH cur_approval INTO rec_approval;
-- 		
-- 		IF(:NEW.is_done = '1') THEN
--     
-- 			--THEN INSERT THE NEXT
-- 
-- 			--get id and level for the workflow responsible for this approval(via phase)			
-- 			--SELECT workflow_id, approval_level INTO this_wf_id,this_phase_level FROM workflow_phases WHERE workflow_phase_id = :NEW.workflow_phase_id;
-- 
-- 			--get next phase (in same workflow) with 
-- 			SELECT MIN(workflow_phase_id) INTO nxt_phase_id FROM workflow_phases WHERE workflow_id = :NEW.workflow_id AND approval_level > :NEW.approval_level AND is_utility = '0';
-- 			
-- 			--check payment_type for next phase 
-- 			SELECT payment_type_id INTO nxt_pay_type_id FROM workflow_phases WHERE workflow_phases.workflow_phase_id = nxt_phase_id;
-- 			
-- 			--IF NO PAYMENT CONTINUE
-- 			IF nxt_pay_type_id = 1 THEN
-- 
-- 				INSERT INTO approvals (workflow_phase_id, table_name, table_id, org_entity_id, app_entity_id, escalation_days, escalation_hours, approval_level, approval_narrative, to_be_done)
-- 				SELECT workflow_phases.workflow_phase_id, rec_approval.table_name, rec_approval.table_id, rec_approval.org_entity_id, entity_subscriptions.entity_id, 0, 3, 1, workflow_phases.phase_narrative, 'Approve - ' || workflow_phases.phase_narrative				
-- 						FROM workflow_phases				
-- 						INNER JOIN entity_subscriptions ON workflow_phases.approval_entity_id = entity_subscriptions.entity_type_id
-- 						WHERE workflow_phases.workflow_phase_id = nxt_phase_id;
-- 				COMMIT;		
-- 			--IF NEXT WORKFLOW NEEDS PAYMENT		
-- 			ELSIF nxt_pay_type_id = 2 THEN		--LICENSE APPLICATION FEE
-- 				--INSERT INTO LICENSE PAYMENT OR EQUIV. client_license_id id will be updated after confirmation by user via(gui/xml)
-- 				SELECT license_payment_header_id_seq.nextval into pay_header_id from dual;
-- 				--INSERT INTO license_payment_header(license_payment_header,workflow_phase_id,client_license_id,description) VALUES(pay_header_id,nxt_phase_id,?,'LICENSE APPLICATION');
-- 				INSERT INTO license_payment_header(license_payment_header_id,workflow_phase_id,workflow_table_id,description) 
-- 				VALUES(pay_header_id,nxt_phase_id,rec_approval.table_id,'LICENSE APPLICATION');
-- 				COMMIT;
-- 
-- 				--get license stuff
-- 				SELECT application_fee INTO app_fee FROM license 
-- 					INNER JOIN client_license ON license.license_id = client_license.license_id
-- 					WHERE client_license.workflow_table_id = rec_approval.table_id;
-- 
-- 				INSERT INTO license_payment_line(license_payment_header_id,product_code,description,amount) 
-- 						VALUES(pay_header_id,'AAAAAAAAAA','Application Fee (KES)',app_fee);
-- 				COMMIT;
-- 				
-- 				--FINALY THE APPROVALS
-- 				INSERT INTO approvals (workflow_phase_id, table_name, table_id, org_entity_id, app_entity_id, escalation_days, escalation_hours, approval_level, approval_narrative, to_be_done)
-- 				SELECT workflow_phases.workflow_phase_id, 'LICENSE_PAYMENT_HEADER', rec_approval.table_id, rec_approval.org_entity_id, entity_subscriptions.entity_id, 0, 3, 1, workflow_phases.phase_narrative, 'Confirm Payment - ' || workflow_phases.phase_narrative				
-- 						FROM workflow_phases				
-- 						INNER JOIN entity_subscriptions ON workflow_phases.approval_entity_id = entity_subscriptions.entity_type_id
-- 						WHERE workflow_phases.workflow_phase_id = nxt_phase_id;
-- 				COMMIT;	
-- 
-- 			ELSIF nxt_pay_type_id = 3 THEN		--LICENSE INITIAL FEE
-- 				--if static charge
-- 				--otherwise
-- 					amnt := (c2.stationcharge * (c5.trdate / 12)) ;
-- 					prtcode := c2.initialaccount;					
-- 				
-- 					INSERT INTO licensepayments (paymenttypeid,clientlicenseid,amount,userid,productcode,periodid,clientphaseid,details) 
-- 						SELECT c2.paymenttypeid ,c2.clientlicenseid ,sum(c2.stationcharge * (c5.trdate / 12)) ,CAST(myval2 as int) ,prtcode,c4.periodid,c2.clientphaseid,' Amount Includes Kshs 1000 application fee'
-- 						FROM clientphases INNER JOIN phases ON phases.phaseid = clientphases.phaseid
-- 						WHERE clientphases.clientphaseid = CAST(myval1 as int) AND (c2.forpayment = '1')
-- 						AND clientlicenseid = c2.clientlicenseid;
--     				COMMIT;
-- 			
-- 			END IF;
--       
-- 			
-- 			
-- 
-- --	... and checklists for the first level	
-- -- 	INSERT INTO approval_checklists (checklist_id)
-- -- 			SELECT checklist_id
-- -- 			FROM checklists
-- -- 			INNER JOIN workflow_phases ON checklists.workflow_phase_id = workflow_phases.workflow_phase_id
-- -- 			WHERE workflow_phases.approval_level='1';
-- 
-- 
-- 		--UPDATE ALL SIBLINGS.. all approvals for same level
-- 			--UPDATE approvals SET approve_status = 'C', action_date = CURRENT_TIMESTAMP --entity_id = :NEW.app_entity_id,
-- 			--WHERE approve_status != 'C' AND workflow_phase_id = :NEW.workflow_phase_id;
-- 			--COMMIT;
--       
--     CLOSE cur_approval;  
-- 		END IF;
-- end;



CREATE TABLE checklists (
	checklist_id			integer primary key,
	workflow_phase_id		integer references workflow_phases,
	checklist_number		integer,	

	is_active				char(1) default '1' not null,		--for temporarily disabling/deleting checklists
	is_mandatory			char(1) default '1' not null,

	requirement				clob,
	details					clob
);
CREATE INDEX checklists_workflow_phase_id ON checklists (workflow_phase_id);
CREATE SEQUENCE seq_checklist_id MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_checklist_id BEFORE INSERT ON checklists
for each row 
begin     
	if inserting then 
		if :NEW.checklist_id is null then
			SELECT seq_checklist_id.nextval into :NEW.checklist_id from dual;
		end if;		
	end if; 
end;
/

--ultimate work is done here.
CREATE TABLE approvals (
	approval_id				integer primary key,
	workflow_phase_id		integer references workflow_phases,
	entity_id				integer references entitys,		--person who actualy did the approval on behalf of the entire group
	approve_status			varchar(32) DEFAULT 'D' NOT NULL,		--D FOR DRAFT
	approval_level			integer default 1 not null,
	forward_id				integer,
	table_name				varchar(64),			--table concerned. payload of this workflow
	table_id				integer,				--from workflow_table_id sequence. alternatively we can use the pk of the table
	escalation_time			integer default 3 not null,
	application_date		timestamp default CURRENT_TIMESTAMP not null,
	completion_date			timestamp,
	action_date				timestamp,
	narrative				varchar(240),
	to_be_done				clob,
	what_is_done			clob,
	details					clob
);
--ALTER TABLE approvals ADD narrative 			varchar(240);
ALTER TABLE approvals ADD escalation_days		integer default 0 not null;
ALTER TABLE approvals ADD escalation_hours		integer default 3 not null;
ALTER TABLE approvals ADD org_entity_id			integer references entitys;		--originating user. 
ALTER TABLE approvals ADD app_entity_id			integer references entitys;		--approving user. person expected to approve...
ALTER TABLE approvals ADD review_advice			clob;
ALTER TABLE approvals ADD approval_narrative	varchar(240);
ALTER TABLE approvals ADD is_ad_hoc				char(1) default '0' not null;	
ALTER TABLE approvals ADD approval_group		integer;	
ALTER TABLE approvals ADD hard_xml_link			varchar(20);

ALTER TABLE approvals ADD parent_approval_id	integer references approvals;
ALTER TABLE approvals ADD approve_status_ret	char(1);   --APPROVE THE RETURN STATUS

ALTER TABLE approvals ADD task_source		varchar(120);
ALTER TABLE approvals ADD task_type			varchar(120);



CREATE INDEX a_workflow_phase_id ON approvals (workflow_phase_id);
CREATE INDEX a_entity_id ON approvals (entity_id);
CREATE INDEX a_org_entity_id ON approvals (org_entity_id);
CREATE INDEX a_app_entity_id ON approvals (app_entity_id);
CREATE INDEX a_table_id ON approvals (table_id);
CREATE INDEX a_approve_status ON approvals (approve_status);

CREATE SEQUENCE seq_approval_id MINVALUE 1 INCREMENT BY 1 START WITH 1;
set scan off;
CREATE OR REPLACE TRIGGER trg_approvals BEFORE INSERT OR UPDATE ON approvals
for each row 
	
begin     
	if inserting then 
		if :NEW.approval_id is null then
			SELECT seq_approval_id.nextval into :NEW.approval_id from dual;
		end if;
								
		IF :NEW.is_ad_hoc = '1' AND :NEW.approval_group = '0' THEN
			SELECT seq_approval_group.nextval INTO :NEW.approval_group FROM dual;
		END IF;


		--BUG FIX.. unable to link adhoc approval via xml.. baraza inserts client_license_id instead..
		if :NEW.is_ad_hoc = '1' AND :NEW.table_name = 'LICENSE' THEN
			SELECT workflow_table_id INTO :NEW.table_id FROM client_license WHERE client_license_id = :NEW.table_id;
		elsif :NEW.is_ad_hoc = '1' AND :NEW.table_name = 'CLIENT_INSPECTION' THEN --:NEW.table_name = 'ACTIVITY_TYPE' THEN
			SELECT workflow_table_id INTO :NEW.table_id FROM client_inspection WHERE client_inspection_id = :NEW.table_id;
		end if;

		--SCHEDULE EMAIL TO BE SENT.. table_id links to the specific approval in the system
		INSERT INTO sys_emailed (sys_email_id,table_id, table_name, email_type) VALUES (1,:NEW.approval_id, 'APPROVALS', 1);			
		
		--STOP GAP FOR TECHNICAL DETAILS.
-- 		IF :NEW.approval_narrative = 'Technical Details' THEN
-- 			SELECT client_license_id INTO :NEW.hard_xml_link FROM client_license WHERE workflow_table_id = :NEW.table_id;
-- 			:NEW.approval_narrative := '<a href="http://172.100.3.30:9090/fsm/index.jsp?view=3:0:0&amp;data='|| :NEW.hard_xml_link ||'">Technical Details - Click to proceed</a>';
-- 		END IF;


	elsif updating then
		--LOGISTICS
		:NEW.completion_date := CURRENT_TIMESTAMP;
	end if; 
end;
/

CREATE SEQUENCE seq_approval_group;			--allows us to group/identify approvals on the same level
CREATE SEQUENCE workflow_table_id_seq;		--generates workflow sequences


CREATE OR REPLACE TRIGGER trg_upd_approvals AFTER UPDATE OF approve_status ON approvals
  FOR EACH ROW
  DECLARE

	PRAGMA AUTONOMOUS_TRANSACTION;
	
	this_wf_id				 integer; 	--id of the xponding wf
	nxt_phase_level			integer;
	nxt_phase_id		    integer;

	this_phase_level		 integer;
	--nxt_phase_level 		integer;
  
	req_approvals       integer;    --required approvals
	curr_approvals      integer;    --current approvals
  
	nxt_pay_type_id 	integer;
	pay_header_id		integer;
  
	app_fee				  real;
	initial_fee			real;
	type_appr_fee				real;
	pending_pay			integer;
	
  
	parent_table        varchar(50);    --first table used in this approval
	wf_table            varchar(50);

	ret_level			integer;	--return level number
	ret_wf_phase		integer;	--return workflow phase

	cli_lic_id			integer;		--corresponding client license id 
	lic_id				integer;		--license id
	cli_id				integer;		--client id
	lic_type_id			integer;
	
	p_checklists		integer;		--pending uncleared and manadatory checklists
	appr_group			integer;

	l_sql_stmt VARCHAR2(1000);

BEGIN
  
	SELECT table_name INTO parent_table 
	FROM approvals 
	INNER JOIN workflow_phases ON approvals.workflow_phase_id = workflow_phases.workflow_phase_id
	WHERE approvals.table_id = :NEW.table_id AND workflow_phases.approval_level = 1 AND ROWNUM = 1 ORDER BY approval_id;
	
	SELECT seq_approval_group.nextval INTO appr_group FROM dual;

	IF parent_table = 'CLIENT_LICENSE' THEN
  
		SELECT client_license.client_license_id, client_license.client_id,license.license_id, license.license_type_id INTO cli_lic_id, cli_id, lic_id, lic_type_id
		FROM client_license 
		INNER JOIN license ON client_license.license_id = license.license_id
		LEFT JOIN license_type ON license.license_type_id = license_type.license_type_id
		WHERE workflow_table_id = :NEW.table_id;
    
	END IF;
    
	IF :NEW.approve_status = 'X' THEN
		--LOCATE return level
		SELECT return_level, workflow_id INTO ret_level,this_wf_id 
		FROM workflow_phases WHERE workflow_phase_id = :NEW.workflow_phase_id AND rownum = 1;

		--identify the workflow phase
		SELECT workflow_phase_id INTO ret_wf_phase 
		FROM workflow_phases WHERE approval_level = ret_level AND workflow_id = this_wf_id;

		--send approvals
		INSERT INTO approvals (workflow_phase_id, parent_approval_id, approval_group, table_name, table_id, org_entity_id, app_entity_id, escalation_days, escalation_hours, approval_level, approval_narrative, to_be_done)
		SELECT workflow_phases.workflow_phase_id, :NEW.approval_id, appr_group, parent_table, :NEW.table_id, :NEW.org_entity_id, entity_subscriptions.entity_id, 0, 3, 1, workflow_phases.phase_narrative, 'REVIEW THIS: - ' || workflow_phases.phase_narrative
		FROM workflow_phases
			INNER JOIN entity_subscriptions ON workflow_phases.approval_entity_id = entity_subscriptions.entity_type_id
			WHERE workflow_phases.workflow_phase_id = ret_wf_phase;
		COMMIT;	

		--GET PENDING CHECKLISTS INTO THE ADHOC TASK
		SELECT count(approval_checklist_id) as cl_count INTO p_checklists
		FROM approval_checklists
		INNER JOIN checklists ON approval_checklists.checklist_id = checklists.checklist_id
		INNER JOIN workflow_phases ON checklists.workflow_phase_id = workflow_phases.workflow_phase_id
		WHERE workflow_phases.workflow_phase_id = :NEW.workflow_phase_id AND approval_checklists.workflow_table_id = :NEW.table_id
			AND checklists.is_mandatory = '1' AND approval_checklists.done = '0';
		
	ELSIF(:OLD.approve_status != 'C' AND :NEW.approve_status = 'C') THEN		

		--COUNT PENDING (MANDATORY) CHECKLISTS
		SELECT count(approval_checklist_id) as cl_count INTO p_checklists
			FROM approval_checklists
			INNER JOIN checklists ON approval_checklists.checklist_id = checklists.checklist_id
			INNER JOIN workflow_phases ON checklists.workflow_phase_id = workflow_phases.workflow_phase_id
		WHERE workflow_phases.workflow_phase_id = :NEW.workflow_phase_id AND approval_checklists.workflow_table_id = :NEW.table_id
			AND checklists.is_mandatory = '1' AND approval_checklists.done = '0';
		
		IF p_checklists = 0 THEN		--IF NO MANDATORY CHECKLISTS REMAINING

			--NOW CONFIRM PENDING PAYMENTS
			SELECT count(license_payment_header_id) INTO pending_pay FROM license_payment_header 
			WHERE workflow_table_id = :NEW.table_id AND is_paid = '0';
			IF(pending_pay > 0) THEN
				RAISE_APPLICATION_ERROR(-20011,'SORRY. THE LICENSEE NEEDS TO CLEAR WITH FINANCE BEFORE PROCEEDING');		
			END IF;
			
			--IF THIS IS A CHILD...REVIVE THE PARENT
			IF (:NEW.parent_approval_id IS NOT NULL) THEN  
			 	RETURN;
			END IF;
	        
			SELECT workflow_id, approval_level, required_approvals INTO this_wf_id,this_phase_level,req_approvals
			FROM workflow_phases WHERE workflow_phase_id = :NEW.workflow_phase_id;
      
			--get next phase (in same workflow) with 
			SELECT MIN(approval_level) INTO nxt_phase_level
			FROM workflow_phases 
			WHERE workflow_id = this_wf_id AND approval_level > this_phase_level AND is_utility = '0';

			SELECT MIN(workflow_phase_id) INTO nxt_phase_id 
			FROM workflow_phases 
			WHERE workflow_id = this_wf_id AND approval_level = nxt_phase_level;
			
			--check payment_type for next phase 
			IF nxt_phase_id IS NOT NULL THEN
				SELECT payment_type_id INTO nxt_pay_type_id FROM workflow_phases WHERE workflow_phases.workflow_phase_id = nxt_phase_id;
			ELSE --if this is the final phase		
				nxt_pay_type_id := -1;
			
				EXECUTE IMMEDIATE 'UPDATE ' || parent_table || ' SET is_workflow_complete = ''1''  WHERE workflow_table_id = ' || :NEW.table_id;
				COMMIT;

			END IF;
			
			--IF NO PAYMENT (in next fase) CONTINUE
			IF nxt_pay_type_id = 1 THEN

				INSERT INTO approvals (workflow_phase_id, approval_group, table_name, table_id, org_entity_id, app_entity_id, escalation_days, escalation_hours, approval_level, approval_narrative, to_be_done)
				SELECT workflow_phases.workflow_phase_id, appr_group, parent_table, :NEW.table_id, :NEW.org_entity_id, entity_subscriptions.entity_id, 0, 3, 1, workflow_phases.phase_narrative, 'Approve - ' || workflow_phases.phase_narrative				
						FROM workflow_phases				
						INNER JOIN entity_subscriptions ON workflow_phases.approval_entity_id = entity_subscriptions.entity_type_id
						WHERE workflow_phases.workflow_phase_id = nxt_phase_id;
				COMMIT;		

			ELSIF nxt_pay_type_id = 6 THEN		--TYPE APPROVAL FEE
				
				SELECT ta_fee INTO type_appr_fee FROM client_license WHERE client_license_id = cli_lic_id;

				IF(type_appr_fee = 0 OR type_appr_fee IS NULL) THEN
					RAISE_APPLICATION_ERROR(-20012,'SORRY. U NEED TO INPUT THE TYPE APPROVAL FEE FOR ALL EQUIPMENT IN THIS APPLICATION');		
				END IF;

				--INSERT INTO LICENSE PAYMENT OR EQUIV. client_license_id id will be updated after confirmation by user via(gui/xml)
				SELECT license_payment_header_id_seq.nextval into pay_header_id from dual;

				--INSERT INTO license_payment_header(license_payment_header,workflow_phase_id,client_license_id,description) VALUES(pay_header_id,nxt_phase_id,?,'LICENSE APPLICATION');
				INSERT INTO license_payment_header(license_payment_header_id,client_license_id,workflow_phase_id,workflow_table_id,description) 
				VALUES(pay_header_id,cli_lic_id,nxt_phase_id,:NEW.table_id,'TYPE APPROVAL');
				COMMIT;

				--GET TYPE APPROVAL FEE
				INSERT INTO license_payment_line(license_payment_header_id,product_code,description,amount) 
					VALUES(pay_header_id,'EAC2DCB2C5B54A7C953E7C10F105B246','Type Approval Fee (KES)',type_appr_fee);
				COMMIT;

				--FINALY THE APPROVALS
				INSERT INTO approvals (workflow_phase_id, approval_group, table_name, table_id, org_entity_id, app_entity_id, escalation_days, escalation_hours, approval_level, approval_narrative, to_be_done)
				SELECT workflow_phases.workflow_phase_id, appr_group, 'LICENSE_PAYMENT_HEADER', :NEW.table_id, :NEW.org_entity_id, entity_subscriptions.entity_id, 0, 3, 1, workflow_phases.phase_narrative, 'Confirm Payment - ' || workflow_phases.phase_narrative				
					FROM workflow_phases				
					INNER JOIN entity_subscriptions ON workflow_phases.approval_entity_id = entity_subscriptions.entity_type_id
					WHERE workflow_phases.workflow_phase_id = nxt_phase_id;
				COMMIT;	

			--IF NEXT WORKFLOW NEEDS PAYMENT		
			ELSIF nxt_pay_type_id = 2 THEN		--LICENSE APPLICATION FEE
				--INSERT INTO LICENSE PAYMENT OR EQUIV. client_license_id id will be updated after confirmation by user via(gui/xml)
				SELECT license_payment_header_id_seq.nextval into pay_header_id from dual;
				--INSERT INTO license_payment_header(license_payment_header,workflow_phase_id,client_license_id,description) VALUES(pay_header_id,nxt_phase_id,?,'LICENSE APPLICATION');
				INSERT INTO license_payment_header(license_payment_header_id,client_license_id,workflow_phase_id,workflow_table_id,description) 
				VALUES(pay_header_id,cli_lic_id,nxt_phase_id,:NEW.table_id,'LICENSE APPLICATION');
				COMMIT;
				
				--get license stuff
				SELECT application_fee INTO app_fee FROM license 
					INNER JOIN client_license ON license.license_id = client_license.license_id
					WHERE client_license.workflow_table_id = :NEW.table_id;

				INSERT INTO license_payment_line(license_payment_header_id,product_code,description,amount) 
					VALUES(pay_header_id,'DED128EAB8C746DD93121305EBBE0488','Application Fee (KES)',app_fee);
				COMMIT;
				
				--FINALY THE APPROVALS
				INSERT INTO approvals (workflow_phase_id, approval_group, table_name, table_id, org_entity_id, app_entity_id, escalation_days, escalation_hours, approval_level, approval_narrative, to_be_done)
				SELECT workflow_phases.workflow_phase_id, appr_group, 'LICENSE_PAYMENT_HEADER', :NEW.table_id, :NEW.org_entity_id, entity_subscriptions.entity_id, 0, 3, 1, workflow_phases.phase_narrative, 'Confirm Payment - ' || workflow_phases.phase_narrative				
					FROM workflow_phases				
					INNER JOIN entity_subscriptions ON workflow_phases.approval_entity_id = entity_subscriptions.entity_type_id
					WHERE workflow_phases.workflow_phase_id = nxt_phase_id;
				COMMIT;	

			ELSIF nxt_pay_type_id = 3 THEN		--LICENSE INITIAL FEE
				
				--IF LAND MOBILE ...
				IF lic_id = 12 THEN		--IF LAND MOBILE
					--FIRST CALCULATE THE CHARGES
					SELECT sum(prorated_charge) INTO initial_fee
						FROM station					
						INNER JOIN vhf_network ON station.vhf_network_id = vhf_network.vhf_network_id					
						WHERE vhf_network.client_license_id = cli_lic_id;
					
					--THEN INSERT INTO PAYMENTS TABLE
					SELECT license_payment_header_id_seq.nextval into pay_header_id from dual;						
					--HEADER 
					INSERT INTO license_payment_header(license_payment_header_id,client_license_id,workflow_phase_id,workflow_table_id,description) 
						VALUES(pay_header_id,cli_lic_id,nxt_phase_id,:NEW.table_id,'LICENSE INITIAL FEE');
						COMMIT;

					--NOTIFY CLIENT OF PENDING PAYMENNT
					INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type) VALUES (11, :NEW.table_id, 'LICENSE_PAYMENT_HEADER', 10);		
					COMMIT;

					--LINES
					INSERT INTO license_payment_line(license_payment_header_id,product_code,description,amount) 
						VALUES(pay_header_id,'6BC94EBDB33D425D9B9F87EA17300E0A','Initial Fee (KES)', initial_fee);
						COMMIT;

					--FINALY PREPARE APPROVALS
					INSERT INTO approvals (workflow_phase_id, approval_group, table_name, table_id, org_entity_id, app_entity_id, escalation_days, escalation_hours, approval_level, approval_narrative, to_be_done)
						SELECT workflow_phases.workflow_phase_id, appr_group, 'CLIENT_LICENSE', :NEW.table_id, :NEW.org_entity_id, entity_subscriptions.entity_id, 0, 3, 1, workflow_phases.phase_narrative, 'Confirm Payment - ' || workflow_phases.phase_narrative				
							FROM workflow_phases				
							INNER JOIN entity_subscriptions ON workflow_phases.approval_entity_id = entity_subscriptions.entity_type_id
							WHERE workflow_phases.workflow_phase_id = nxt_phase_id;
						COMMIT;	

				ELSIF lic_id = 20 THEN		--IF ALARM
					--FIRST CALCULATE THE CHARGES
					SELECT sum(prorated_charge) INTO initial_fee
						FROM station					
						INNER JOIN vhf_network ON station.vhf_network_id = vhf_network.vhf_network_id					
						WHERE vhf_network.client_license_id = cli_lic_id;
					
					--THEN INSERT INTO PAYMENTS TABLE
					SELECT license_payment_header_id_seq.nextval into pay_header_id from dual;						
					--HEADER 
					INSERT INTO license_payment_header(license_payment_header_id,client_license_id,workflow_phase_id,workflow_table_id,description) 
						VALUES(pay_header_id,cli_lic_id,nxt_phase_id,:NEW.table_id,'LICENSE INITIAL FEE');
						COMMIT;

					--NOTIFY CLIENT OF PENDING PAYMENNT
					INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type) VALUES (11, :NEW.table_id, 'LICENSE_PAYMENT_HEADER', 10);		
					COMMIT;

					--LINES
					INSERT INTO license_payment_line(license_payment_header_id,product_code,description,amount) 
						VALUES(pay_header_id,'6BC94EBDB33D425D9B9F87EA17300E0A','Initial Fee (KES)', initial_fee);
						COMMIT;

					--FINALY PREPARE APPROVALS
					INSERT INTO approvals (workflow_phase_id, approval_group, table_name, table_id, org_entity_id, app_entity_id, escalation_days, escalation_hours, approval_level, approval_narrative, to_be_done)
						SELECT workflow_phases.workflow_phase_id, appr_group, 'CLIENT_LICENSE', :NEW.table_id, :NEW.org_entity_id, entity_subscriptions.entity_id, 0, 3, 1, workflow_phases.phase_narrative, 'Confirm Payment - ' || workflow_phases.phase_narrative				
							FROM workflow_phases				
							INNER JOIN entity_subscriptions ON workflow_phases.approval_entity_id = entity_subscriptions.entity_type_id
							WHERE workflow_phases.workflow_phase_id = nxt_phase_id;
						COMMIT;	


				ELSIF lic_id = 8 THEN		--AIRCRAFT 
					--FIRST CALCULATE THE CHARGES  - this is a stop gap measure.. i need to use prorated_charge
					SELECT sum(annual_station_charge) INTO initial_fee
						FROM station											
						WHERE station.client_license_id = cli_lic_id AND rownum = 1;
					
					--THEN INSERT INTO PAYMENTS TABLE
					SELECT license_payment_header_id_seq.nextval into pay_header_id from dual;						
					--HEADER 
					INSERT INTO license_payment_header(license_payment_header_id,client_license_id,workflow_phase_id,workflow_table_id,description) 
						VALUES(pay_header_id,cli_lic_id,nxt_phase_id,:NEW.table_id,'LICENSE INITIAL FEE');
						COMMIT;

					--NOTIFY CLIENT OF PENDING PAYMENNT
					INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type) VALUES (11, :NEW.table_id, 'LICENSE_PAYMENT_HEADER', 10);		
					COMMIT;

					--LINES
					INSERT INTO license_payment_line(license_payment_header_id,product_code,description,amount) 
						VALUES(pay_header_id,'6BC94EBDB33D425D9B9F87EA17300E0A','Initial Fee (KES)', initial_fee);
						COMMIT;

					--FINALY PREPARE APPROVALS
					INSERT INTO approvals (workflow_phase_id, approval_group, table_name, table_id, org_entity_id, app_entity_id, escalation_days, escalation_hours, approval_level, approval_narrative, to_be_done)
						SELECT workflow_phases.workflow_phase_id, appr_group, 'LICENSE_PAYMENT_HEADER', :NEW.table_id, :NEW.org_entity_id, entity_subscriptions.entity_id, 0, 3, 1, workflow_phases.phase_narrative, 'Confirm Payment - ' || workflow_phases.phase_narrative				
							FROM workflow_phases				
							INNER JOIN entity_subscriptions ON workflow_phases.approval_entity_id = entity_subscriptions.entity_type_id
							WHERE workflow_phases.workflow_phase_id = nxt_phase_id;
						COMMIT;	

				ELSIF lic_id = 21 THEN		--P2P
					--FIRST CALCULATE THE CHARGES  - this is a stop gap measure.. i need to use prorated_charge
					SELECT sum(annual_station_charge) INTO initial_fee
						FROM terrestrial_link											
						WHERE terrestrial_link.client_license_id = cli_lic_id;
					
					--THEN INSERT INTO PAYMENTS TABLE
					SELECT license_payment_header_id_seq.nextval into pay_header_id from dual;						
					--HEADER 
					INSERT INTO license_payment_header(license_payment_header_id,client_license_id,workflow_phase_id,workflow_table_id,description) 
						VALUES(pay_header_id,cli_lic_id,nxt_phase_id,:NEW.table_id,'LICENSE INITIAL FEE');
						COMMIT;

					--NOTIFY CLIENT OF PENDING PAYMENNT
					INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type) VALUES (11, :NEW.table_id, 'LICENSE_PAYMENT_HEADER', 10);		
					COMMIT;

					--LINES
					INSERT INTO license_payment_line(license_payment_header_id,product_code,description,amount) 
						VALUES(pay_header_id,'6BC94EBDB33D425D9B9F87EA17300E0A','Initial Fee (KES)', initial_fee);
						COMMIT;

					--FINALY PREPARE APPROVALS
					INSERT INTO approvals (workflow_phase_id, approval_group, table_name, table_id, org_entity_id, app_entity_id, escalation_days, escalation_hours, approval_level, approval_narrative, to_be_done)
						SELECT workflow_phases.workflow_phase_id, appr_group, 'LICENSE_PAYMENT_HEADER', :NEW.table_id, :NEW.org_entity_id, entity_subscriptions.entity_id, 0, 3, 1, workflow_phases.phase_narrative, 'Confirm Payment - ' || workflow_phases.phase_narrative				
							FROM workflow_phases				
							INNER JOIN entity_subscriptions ON workflow_phases.approval_entity_id = entity_subscriptions.entity_type_id
							WHERE workflow_phases.workflow_phase_id = nxt_phase_id;
						COMMIT;	


				ELSIF lic_id = 24 THEN		--P2P
					--FIRST CALCULATE THE CHARGES  - this is a stop gap measure.. i need to use prorated_charge
					SELECT sum(annual_station_charge) INTO initial_fee
						FROM station											
						WHERE station.client_license_id = cli_lic_id;
					
					--THEN INSERT INTO PAYMENTS TABLE
					SELECT license_payment_header_id_seq.nextval into pay_header_id from dual;						
					--HEADER 
					INSERT INTO license_payment_header(license_payment_header_id,client_license_id,workflow_phase_id,workflow_table_id,description) 
						VALUES(pay_header_id,cli_lic_id,nxt_phase_id,:NEW.table_id,'LICENSE INITIAL FEE');
						COMMIT;

					--NOTIFY CLIENT OF PENDING PAYMENNT
					INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type) VALUES (11, :NEW.table_id, 'LICENSE_PAYMENT_HEADER', 10);		
					COMMIT;

					--LINES
					INSERT INTO license_payment_line(license_payment_header_id,product_code,description,amount) 
						VALUES(pay_header_id,'6BC94EBDB33D425D9B9F87EA17300E0A','Initial Fee (KES)', initial_fee);
						COMMIT;

					--FINALY PREPARE APPROVALS
					INSERT INTO approvals (workflow_phase_id, approval_group, table_name, table_id, org_entity_id, app_entity_id, escalation_days, escalation_hours, approval_level, approval_narrative, to_be_done)
						SELECT workflow_phases.workflow_phase_id, appr_group, 'LICENSE_PAYMENT_HEADER', :NEW.table_id, :NEW.org_entity_id, entity_subscriptions.entity_id, 0, 3, 1, workflow_phases.phase_narrative, 'Confirm Payment - ' || workflow_phases.phase_narrative				
							FROM workflow_phases				
							INNER JOIN entity_subscriptions ON workflow_phases.approval_entity_id = entity_subscriptions.entity_type_id
							WHERE workflow_phases.workflow_phase_id = nxt_phase_id;
						COMMIT;	


				ELSIF lic_id = 136 THEN		--VSAT LOCAL/KENYA
					--FIRST CALCULATE THE CHARGES  - this is a stop gap measure.. i need to use prorated_charge
					SELECT sum(station_charge.amount) INTO initial_fee
						FROM station		
						INNER JOIN station_charge ON station.station_charge_id = station_charge.station_charge_id
						WHERE station.client_license_id = cli_lic_id AND rownum = 1;
					
					--THEN INSERT INTO PAYMENTS TABLE
					SELECT license_payment_header_id_seq.nextval into pay_header_id from dual;						
					--HEADER 
					INSERT INTO license_payment_header(license_payment_header_id,client_license_id,workflow_phase_id,workflow_table_id,description) 
						VALUES(pay_header_id,cli_lic_id,nxt_phase_id,:NEW.table_id,'LICENSE INITIAL FEE');
						COMMIT;

					--NOTIFY CLIENT OF PENDING PAYMENNT
					INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type) VALUES (11, :NEW.table_id, 'LICENSE_PAYMENT_HEADER', 10);		
					COMMIT;

					--LINES
					INSERT INTO license_payment_line(license_payment_header_id,product_code,description,amount) 
						VALUES(pay_header_id,'6BC94EBDB33D425D9B9F87EA17300E0A','Initial Fee (KES)', initial_fee);
						COMMIT;

					--FINALY PREPARE APPROVALS
					INSERT INTO approvals (workflow_phase_id, approval_group, table_name, table_id, org_entity_id, app_entity_id, escalation_days, escalation_hours, approval_level, approval_narrative, to_be_done)
						SELECT workflow_phases.workflow_phase_id, appr_group, 'LICENSE_PAYMENT_HEADER', :NEW.table_id, :NEW.org_entity_id, entity_subscriptions.entity_id, 0, 3, 1, workflow_phases.phase_narrative, 'Confirm Payment - ' || workflow_phases.phase_narrative				
							FROM workflow_phases				
							INNER JOIN entity_subscriptions ON workflow_phases.approval_entity_id = entity_subscriptions.entity_type_id
							WHERE workflow_phases.workflow_phase_id = nxt_phase_id;
						COMMIT;	

				ELSIF (lic_type_id = 11) OR (lic_type_id = 13) OR (lic_type_id = 14) OR (lic_type_id = 17) THEN		--ASP,CSP, TEC

					--get license stuff
					SELECT COALESCE(initial_fee,0) INTO initial_fee FROM license 
						INNER JOIN client_license ON license.license_id = client_license.license_id
						WHERE client_license.workflow_table_id = :NEW.table_id;
	

					--THEN INSERT INTO PAYMENTS TABLE
					SELECT license_payment_header_id_seq.nextval into pay_header_id from dual;						
					--HEADER 
					INSERT INTO license_payment_header(license_payment_header_id,client_license_id,workflow_phase_id,workflow_table_id,description) 
						VALUES(pay_header_id,cli_lic_id,nxt_phase_id,:NEW.table_id,'LICENSE INITIAL FEE');
						COMMIT;

					--NOTIFY CLIENT OF PENDING PAYMENNT
					INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type) VALUES (11, :NEW.table_id, 'LICENSE_PAYMENT_HEADER', 10);		
					COMMIT;

					--LINES
					INSERT INTO license_payment_line(license_payment_header_id,product_code,description,amount) 
						VALUES(pay_header_id,'6BC94EBDB33D425D9B9F87EA17300E0A','Initial Fee (KES)', initial_fee);
						COMMIT;

					--FINALY PREPARE APPROVALS
					INSERT INTO approvals (workflow_phase_id, approval_group, table_name, table_id, org_entity_id, app_entity_id, escalation_days, escalation_hours, approval_level, approval_narrative, to_be_done)
						SELECT workflow_phases.workflow_phase_id, appr_group, 'LICENSE_PAYMENT_HEADER', :NEW.table_id, :NEW.org_entity_id, entity_subscriptions.entity_id, 0, 3, 1, workflow_phases.phase_narrative, 'Confirm Payment - ' || workflow_phases.phase_narrative				
							FROM workflow_phases				
							INNER JOIN entity_subscriptions ON workflow_phases.approval_entity_id = entity_subscriptions.entity_type_id
							WHERE workflow_phases.workflow_phase_id = nxt_phase_id;
						COMMIT;	
				
				END IF;		--IF LICENS TYPE ID

			END IF;		--END IF PAY_TYPE ......

			--WE ADD checklists for the NEXT PHASE.. REGARDLESS OF THE VARIABLES ABOVE
			INSERT INTO approval_checklists (checklist_id, workflow_table_id)				
			SELECT checklist_id, :NEW.table_id
				FROM checklists
					INNER JOIN workflow_phases ON checklists.workflow_phase_id = workflow_phases.workflow_phase_id
					INNER JOIN workflows ON workflow_phases.workflow_id = workflows.workflow_id					
					WHERE workflow_phases.is_utility = '0' AND workflow_phases.workflow_phase_id = nxt_phase_id
					ORDER BY workflow_phases.approval_level, workflow_phases.workflow_phase_id;
          
			COMMIT;
		
		ELSE			--IF THERE ARE PENDING CHECKLISTS
			--raise_application_error(-20030,'Client email NOT DEFINED ('||fsm_pay_rec.clientname|| '). Offer not sent');
			--INSERT INTO sys_errors(sys_error,error_message) VALUES('SORRY. THERE ARE PENDING (mandatory) CHECKLISTS. Approval Rejected',NULL);
			--COMMIT;
			RAISE_APPLICATION_ERROR(-20010,'SORRY. THERE ARE  '|| p_checklists|| ' PENDING (mandatory) CHECKLISTS. Approval Rejected');		
		END IF;
	
	END IF;		--END IF APPROVE_STATUS... (C OR COMPLETE ETC)
	
end;
/





--FOR AD HOC APPROVALS
CREATE TABLE approval_checklists (
	approval_checklist_id	integer primary key,
	--approval_id			integer references approvals,
	checklist_id			integer references checklists,
	--manditory				char(1) default '1' not null,
	
	done					char(1) default '0' not null	
	);
ALTER TABLE approval_checklists ADD updated date;
ALTER TABLE approval_checklists ADD updated_by integer references entitys;		--FOR UPDATE OPERATIONS (last updater)
ALTER TABLE approval_checklists ADD workflow_table_id	integer;
ALTER TABLE approval_checklists ADD checklist_comment	clob;

CREATE INDEX approval_chk_approval_id ON approval_checklists (approval_id);
CREATE INDEX approval_chk_checklist_id ON approval_checklists (checklist_id);

CREATE SEQUENCE seq_approval_checklist_id MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER trg_approval_checklists BEFORE INSERT ON approval_checklists
for each row 
begin     
	if inserting then 
		if :NEW.approval_checklist_id is null then
			SELECT seq_approval_checklist_id.nextval into :NEW.approval_checklist_id from dual;
		end if;
	end if; 	
end;


CREATE VIEW vw_sys_emailed AS
	SELECT sys_emails.sys_email_id, sys_emails.sys_email_name, sys_emails.title, sys_emails.details,
		sys_emailed.sys_emailed_id, sys_emailed.table_id, sys_emailed.table_name, sys_emailed.email_level,
		sys_emailed.emailed, sys_emailed.narrative
	FROM sys_emails 
	INNER JOIN sys_emailed ON sys_emails.sys_email_id = sys_emailed.sys_email_id;

CREATE VIEW vw_sys_countrys AS
	SELECT sys_continents.sys_continent_id, sys_continents.sys_continent_name,
		sys_countrys.sys_country_id, sys_countrys.sys_country_code, sys_countrys.sys_country_number, 
		sys_countrys.sys_phone_code, sys_countrys.sys_country_name
	FROM sys_continents INNER JOIN sys_countrys ON sys_continents.sys_continent_id = sys_countrys.sys_continent_id;

CREATE VIEW vw_address AS
	SELECT sys_countrys.sys_country_id, sys_countrys.sys_country_name, address.address_id, address.address_name, address.table_name,
		address.table_id, address.post_office_box, address.postal_code, address.premises, address.street, address.town, 
		address.phone_number, address.extension, address.mobile, address.fax, address.email, address.is_default, address.website, address.details
	FROM address INNER JOIN sys_countrys ON address.sys_country_id = sys_countrys.sys_country_id;

CREATE VIEW vw_orgs AS
	SELECT orgs.org_id, orgs.org_name, orgs.is_default, orgs.is_active, orgs.logo, orgs.details,
		vw_address.sys_country_id, vw_address.sys_country_name, vw_address.address_id, vw_address.table_name,
		vw_address.post_office_box, vw_address.postal_code, vw_address.premises, vw_address.street, vw_address.town, 
		vw_address.phone_number, vw_address.extension, vw_address.mobile, vw_address.fax, vw_address.email, vw_address.website
	FROM orgs LEFT JOIN vw_address ON (orgs.org_id = vw_address.table_id)
	WHERE (vw_address.table_name = 'orgs') OR (vw_address.table_name is null);

CREATE VIEW vw_entitys AS
	SELECT orgs.org_id, orgs.org_name, vw_address.address_id, vw_address.address_name,
		vw_address.sys_country_id, vw_address.sys_country_name, vw_address.table_name, vw_address.is_default,
		vw_address.post_office_box, vw_address.postal_code, vw_address.premises, vw_address.street, vw_address.town, 
		vw_address.phone_number, vw_address.extension, vw_address.mobile, vw_address.fax, vw_address.email, vw_address.website,
		entitys.entity_id, entitys.entity_name, entitys.user_name, entitys.Super_User, entitys.Entity_Leader, 
		entitys.Date_Enroled, entitys.Is_Active, entitys.entity_password, entitys.first_password, entitys.Details,
		entity_types.entity_type_id, entity_types.entity_type_name, entitys.primary_email,
		entity_types.entity_role, entity_types.group_email, entity_types.use_key
	FROM (entitys LEFT JOIN vw_address ON entitys.entity_id = vw_address.table_id)
		INNER JOIN orgs ON entitys.org_id = orgs.org_id
		INNER JOIN entity_types ON entitys.entity_type_id = entity_types.entity_type_id 
	WHERE ((vw_address.table_name = 'entitys') OR (vw_address.table_name is null));


CREATE VIEW vw_entity_subscriptions AS
	SELECT entity_types.entity_type_id, entity_types.entity_type_name, entitys.entity_id, entitys.entity_name, 
		entity_subscriptions.entity_subscription_id, entity_subscriptions.details
	FROM entity_subscriptions 
	INNER JOIN entity_types ON entity_subscriptions.entity_type_id = entity_types.entity_type_id
	INNER JOIN entitys ON entity_subscriptions.entity_id = entitys.entity_id;

CREATE OR REPLACE VIEW vw_workflows AS
	SELECT entity_types.entity_type_id as source_entity_id, entity_types.entity_type_name as source_entity_name, 
		workflows.workflow_id, workflows.workflow_name, workflows.table_name, workflows.table_link_field, 
		workflows.table_link_id, workflows.approve_email, workflows.reject_email, workflows.details
	FROM workflows 
  INNER JOIN entity_types ON workflows.source_entity_id = entity_types.entity_type_id;


CREATE OR REPLACE VIEW vw_workflow_phases AS
	SELECT vw_workflows.source_entity_id, vw_workflows.source_entity_name, vw_workflows.workflow_id, 
		vw_workflows.workflow_name, vw_workflows.table_name, vw_workflows.table_link_field, vw_workflows.table_link_id, 
		vw_workflows.approve_email, vw_workflows.reject_email,
		entity_types.entity_type_id as approval_entity_id, entity_types.entity_type_name as approval_entity_name, 
		workflow_phases.workflow_phase_id, workflow_phases.approval_level, workflow_phases.notice_email,
		workflow_phases.return_level, workflow_phases.escalation_hours, workflow_phases.notice,
		workflow_phases.required_approvals, workflow_phases.phase_narrative, workflow_phases.details
	FROM workflow_phases 
  LEFT JOIN vw_workflows ON workflow_phases.workflow_id = vw_workflows.workflow_id
  INNER JOIN entity_types ON workflow_phases.approval_entity_id = entity_types.entity_type_id;


CREATE VIEW vw_workflow_entitys AS
	SELECT vw_workflow_phases.workflow_id, vw_workflow_phases.workflow_name, vw_workflow_phases.table_name,
		vw_workflow_phases.table_link_id, vw_workflow_phases.source_entity_id, vw_workflow_phases.source_entity_name, 
		vw_workflow_phases.approval_entity_id, vw_workflow_phases.approval_entity_name, 
		vw_workflow_phases.workflow_phase_id, vw_workflow_phases.approval_level, vw_workflow_phases.notice_email,
		vw_workflow_phases.return_level, vw_workflow_phases.escalation_hours, 
		vw_workflow_phases.required_approvals, vw_workflow_phases.phase_narrative, vw_workflow_phases.notice,
		entity_subscriptions.entity_subscription_id, entity_subscriptions.entity_id, entity_subscriptions.subscription_level_id
	FROM vw_workflow_phases 
	INNER JOIN entity_subscriptions ON vw_workflow_phases.source_entity_id = entity_subscriptions.entity_type_id;


CREATE VIEW vw_workflow_approvals AS
	SELECT vw_approvals.workflow_id, vw_approvals.workflow_name, vw_approvals.approve_email, vw_approvals.reject_email,
		vw_approvals.source_entity_id, vw_approvals.source_entity_name, vw_approvals.table_name, vw_approvals.table_id,
		vw_approvals.org_entity_id, vw_approvals.org_entity_name, vw_approvals.org_user_name, 
		vw_approvals.org_primary_email, rt.rejected_count,
		(CASE WHEN rt.rejected_count is null THEN vw_approvals.workflow_name || ' Approved'
			ELSE vw_approvals.workflow_name || ' Rejected' END) as workflow_narrative
	FROM vw_approvals LEFT JOIN 
		(SELECT table_id, count(approval_id) as rejected_count FROM approvals WHERE (approve_status = 'Rejected') AND (approvals.forward_id is null)
		GROUP BY table_id) rt ON vw_approvals.table_id = rt.table_id
	GROUP BY vw_approvals.workflow_id, vw_approvals.workflow_name, vw_approvals.approve_email, vw_approvals.reject_email,
		vw_approvals.source_entity_id, vw_approvals.source_entity_name, vw_approvals.table_name, vw_approvals.table_id,
		vw_approvals.org_entity_id, vw_approvals.org_entity_name, vw_approvals.org_user_name, 
		vw_approvals.org_primary_email, rt.rejected_count;


CREATE VIEW vw_approvals_entitys AS
	SELECT vw_workflow_phases.workflow_id, vw_workflow_phases.workflow_name, 
		vw_workflow_phases.source_entity_id, vw_workflow_phases.source_entity_name, 
		vw_workflow_phases.approval_entity_id, vw_workflow_phases.approval_entity_name,
		vw_workflow_phases.workflow_phase_id, vw_workflow_phases.approval_level, vw_workflow_phases.notice_email,
		vw_workflow_phases.return_level, vw_workflow_phases.required_approvals,
		vw_workflow_phases.notice, vw_workflow_phases.phase_narrative,
		approvals.approval_id, approvals.forward_id, approvals.table_name, approvals.table_id,
		approvals.completion_date, approvals.escalation_days, approvals.escalation_hours,
		approvals.escalation_time, approvals.application_date, approvals.approve_status, approvals.action_date,
		approvals.approval_narrative, approvals.to_be_done, approvals.what_is_done, approvals.review_advice, approvals.details,
		oe.entity_id as org_entity_id, oe.entity_name as org_entity_name, oe.user_name as org_user_name, oe.primary_email as org_primary_email,
		entity_subscriptions.entity_subscription_id, entity_subscriptions.subscription_level_id,
		entitys.entity_id, entitys.entity_name, entitys.user_name, entitys.primary_email
	FROM ((vw_workflow_phases INNER JOIN approvals ON vw_workflow_phases.workflow_phase_id = approvals.workflow_phase_id)
		INNER JOIN entitys as oe  ON approvals.org_entity_id = oe.entity_id)
		INNER JOIN entity_subscriptions ON vw_workflow_phases.approval_entity_id = entity_subscriptions.entity_type_id
		INNER JOIN entitys ON entity_subscriptions.entity_id = entitys.entity_id
	WHERE (approvals.forward_id is null);

CREATE VIEW tomcat_users AS 
	SELECT entitys.user_name, entitys.Entity_password, entity_types.entity_role
	FROM (Entity_subscriptions 
		INNER JOIN entitys ON Entity_subscriptions.entity_id = entitys.entity_id)
		INNER JOIN entity_types ON Entity_subscriptions.entity_type_id = entity_types.entity_type_id
	WHERE entitys.is_active = '1';

CREATE OR REPLACE FUNCTION md5(p_password  IN  VARCHAR2) RETURN VARCHAR2 AS
BEGIN
	RETURN DBMS_OBFUSCATION_TOOLKIT.MD5(input_string => p_password);
END;
/

CREATE OR REPLACE FUNCTION first_password RETURN varchar2 IS
	r RAW(256);
	mypass varchar2(16);
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	r := utl_raw.cast_to_raw(dbms_random.random);	
	r := utl_encode.base64_encode(r);
	mypass := substr(r, 2, 9);

	RETURN mypass;
END;
/

