

CREATE TABLE locations (
	location_id			serial primary key,
	org_id 				integer references orgs,
	location_name 			character varying(50),
	details			 text
);

ALTER TABLE orgs ADD member_limit integer default 5 not null;
ALTER TABLE orgs ADD transaction_limit integer default 100 not null;


CREATE TABLE subscriptions (
	subscription_id			serial primary key,
	industry_id				integer references industry,
	entity_id				integer references entitys,
	account_manager_id		integer references entitys,
	org_id					integer references orgs,

	business_name			varchar(50),
	business_address		varchar(100),
	city					varchar(30),
	state					varchar(50),
	country_id				char(2) references sys_countrys,
	number_of_members		integer,
	telephone				varchar(50),
	website					varchar(120),
	
	primary_contact			varchar(120),
	job_title				varchar(120),
	primary_email			varchar(120),
	confirm_email			varchar(120),

	system_key				varchar(64),
	subscribed				boolean,
	subscribed_date			timestamp,
	
	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	application_date		timestamp default now(),
	action_date				timestamp,
	
	details					text
);
CREATE INDEX subscriptions_industry_id ON subscriptions(industry_id);
CREATE INDEX subscriptions_entity_id ON subscriptions(entity_id);
CREATE INDEX subscriptions_account_manager_id ON subscriptions(account_manager_id);
CREATE INDEX subscriptions_country_id ON subscriptions(country_id);
CREATE INDEX subscriptions_org_id ON subscriptions(org_id);

CREATE VIEW vw_subscriptions AS
	SELECT industry.industry_id, industry.industry_name, sys_countrys.sys_country_id, sys_countrys.sys_country_name,
		entitys.entity_id, entitys.entity_name, 
		account_manager.entity_id as account_manager_id, account_manager.entity_name as account_manager_name,
		orgs.org_id, orgs.org_name, 
		
		subscriptions.subscription_id, subscriptions.business_name, 
		subscriptions.business_address, subscriptions.city, subscriptions.state, subscriptions.country_id, 
		subscriptions.number_of_members, subscriptions.telephone, subscriptions.website, 
		subscriptions.primary_contact, subscriptions.job_title, subscriptions.primary_email, 
		subscriptions.approve_status, subscriptions.workflow_table_id, subscriptions.application_date, subscriptions.action_date, 
		subscriptions.system_key, subscriptions.subscribed, subscriptions.subscribed_date,
		subscriptions.details
	FROM subscriptions INNER JOIN industry ON subscriptions.industry_id = industry.industry_id
		INNER JOIN sys_countrys ON subscriptions.country_id = sys_countrys.sys_country_id
		LEFT JOIN entitys ON subscriptions.entity_id = entitys.entity_id
		LEFT JOIN entitys as account_manager ON subscriptions.account_manager_id = account_manager.entity_id
		LEFT JOIN orgs ON subscriptions.org_id = orgs.org_id;	
		
CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON subscriptions
    FOR EACH ROW EXECUTE PROCEDURE upd_action();
    
CREATE OR REPLACE FUNCTION ins_subscriptions() RETURNS trigger AS $$
DECLARE
	v_entity_id		integer;
	v_org_id		integer;
	v_currency_id	integer;
	v_department_id	integer;
	v_bank_id		integer;
	v_org_suffix    char(2);
	rec 			RECORD;
BEGIN

	IF (TG_OP = 'INSERT') THEN
		SELECT entity_id INTO v_entity_id
		FROM entitys WHERE lower(trim(user_name)) = lower(trim(NEW.primary_email));
		IF(v_entity_id is null)THEN
			NEW.entity_id := nextval('entitys_entity_id_seq');
			INSERT INTO entitys (entity_id, org_id, entity_type_id, use_key_id, entity_name, User_name, primary_email,  function_role, first_password)
			VALUES (NEW.entity_id, 0, 5, 5, NEW.primary_contact, lower(trim(NEW.primary_email)), lower(trim(NEW.primary_email)), 'admin', null);
		
			INSERT INTO sys_emailed (sys_email_id, org_id, table_id, table_name)
			VALUES (4, 0, NEW.entity_id, 'subscription');
			
			NEW.approve_status := 'Completed';
		ELSE
			RAISE EXCEPTION 'You already have an account, login and request for services';
		END IF ;
		
	ELSIF(NEW.approve_status = 'Approved')THEN
		NEW.org_id := nextval('orgs_org_id_seq');
		
		INSERT INTO orgs(org_id, currency_id, org_name, org_sufix, default_country_id)
		VALUES(NEW.org_id, 1, NEW.business_name, NEW.org_id, NEW.country_id);
		
		INSERT INTO entity_types (org_id, entity_type_name, entity_role, use_key_id)
		SELECT NEW.org_id, entity_type_name, entity_role, use_key_id
		FROM entity_types WHERE org_id = 1;
		
		UPDATE entitys SET org_id = NEW.org_id, function_role='admin'
		WHERE entity_id = NEW.entity_id;
		
		v_bank_id := nextval('banks_bank_id_seq');
		INSERT INTO banks (org_id, bank_id, bank_name) VALUES (NEW.org_id, v_bank_id, 'Cash');
		INSERT INTO bank_branch (org_id, bank_id, bank_branch_name) VALUES (NEW.org_id, v_bank_id, 'Cash');
		
		INSERT INTO currency(currency_name, currency_symbol, org_id) VALUES ('Kenya Shillings', 'kes', NEW.org_id);
		INSERT INTO currency_rates (org_id, currency_id, exchange_rate) VALUES (NEW.org_id, v_currency_id, 1);
		
		INSERT INTO sys_emailed (sys_email_id, org_id, table_id, table_name)
		VALUES ( 5, NEW.org_id, NEW.entity_id, 'subscription');

		INSERT INTO account_class (org_id, account_class_no, chat_type_id, chat_type_name, account_class_name)
		SELECT NEW.org_id, account_class_no, chat_type_id, chat_type_name, account_class_name
		FROM account_class
		WHERE org_id = 1;
		
		INSERT INTO account_types (org_id, account_class_id, account_type_no, account_type_name)
		SELECT a.org_id, a.account_class_id, b.account_type_no, b.account_type_name
		FROM account_class a INNER JOIN vw_account_types b ON a.account_class_no = b.account_class_no
		WHERE (a.org_id = NEW.org_id) AND (b.org_id = 1);
		
		INSERT INTO accounts (org_id, account_type_id, account_no, account_name)
		SELECT a.org_id, a.account_type_id, b.account_no, b.account_name
		FROM account_types a INNER JOIN vw_accounts b ON a.account_type_no = b.account_type_no
		WHERE (a.org_id = NEW.org_id) AND (b.org_id = 1);
		
		INSERT INTO default_accounts (org_id, use_key_id, account_id)
		SELECT c.org_id, a.use_key_id, c.account_id
		FROM default_accounts a INNER JOIN accounts b ON a.account_id = b.account_id
			INNER JOIN accounts c ON b.account_no = c.account_no
		WHERE (a.org_id = 1) AND (c.org_id = NEW.org_id);
		
		INSERT INTO departments (org_id, department_name) 
		VALUES (NEW.org_id, 'Administration'); 
	END IF;
		
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_subscriptions BEFORE INSERT OR UPDATE ON subscriptions
    FOR EACH ROW EXECUTE PROCEDURE ins_subscriptions();
 

CREATE OR REPLACE FUNCTION ins_member_limit() RETURNS trigger AS $$
DECLARE
	v_member_count	integer;
	v_member_limit	integer;
BEGIN

	SELECT count(entity_id) INTO v_member_count
	FROM members
	WHERE (org_id = NEW.org_id);
	
	SELECT member_limit INTO v_member_limit
	FROM orgs
	WHERE (org_id = NEW.org_id);
	
	IF(v_member_count > v_member_limit)THEN
		RAISE EXCEPTION 'You have reached the maximum staff limit, request for a quite for more';
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_member_limit BEFORE INSERT ON members
    FOR EACH ROW EXECUTE PROCEDURE ins_member_limit();
