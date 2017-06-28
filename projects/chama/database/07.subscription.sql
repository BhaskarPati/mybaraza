--alter table orgs add default_country_id varchar(6); 
-- CREATE TABLE industry (
-- 	industry_id			serial primary key,
-- 	org_id				integer references orgs,
-- 	industry_name			varchar(50) not null,
-- 	details				text
-- );
-- CREATE INDEX industry_org_id ON industry(org_id); 

CREATE TABLE subscriptions (
	subscription_id			serial primary key,
	--industry_id			integer references industry,
	entity_id			integer references entitys,
	account_manager_id		integer references entitys,
	org_id				integer references orgs,

	chama_name			varchar(50),
	chama_address		varchar(100),
	city				varchar(30),
	state				varchar(50),
	country_id			char(2) references sys_countrys,
	number_of_members		integer,
	telephone			varchar(50),
	website				varchar(120),
	
	primary_contact			varchar(120),
	job_title				varchar(120),
	primary_email			varchar(120),
	confirm_email			varchar(120),
	
	approve_status			varchar(16) default 'Completed' not null,
	workflow_table_id		integer,
	application_date		timestamp default now(),
	action_date				timestamp,
	
	details					text
);
--CREATE INDEX subscriptions_industry_id ON subscriptions(industry_id);
CREATE INDEX subscriptions_entity_id ON subscriptions(entity_id);
CREATE INDEX subscriptions_account_manager_id ON subscriptions(account_manager_id);
CREATE INDEX subscriptions_country_id ON subscriptions(country_id);
CREATE INDEX subscriptions_org_id ON subscriptions(org_id);

CREATE TABLE products (
	product_id				serial primary key,
	org_id					integer references orgs,
	product_name			varchar(50),
	is_montly_bill			boolean default false not null,
	montly_cost				real default 0 not null,
	is_annual_bill			boolean default true not null,
	annual_cost				real default 0 not null,
	
	transaction_limit		integer not null,
	
	details					text
);
CREATE INDEX products_org_id ON products(org_id);

INSERT INTO products (org_id, product_name, transaction_limit) VALUES (0, 'HCM Hosting', 5);

CREATE TABLE productions (
	production_id			serial primary key,
	subscription_id			integer references subscriptions,
	product_id				integer references products,
	entity_id				integer references entitys,
	org_id					integer references orgs,
	
	approve_status			varchar(16) default 'draft' not null,
	workflow_table_id		integer,
	application_date		timestamp default now(),
	action_date				timestamp,
	
	montly_billing			boolean default false not null,
	is_active				boolean default false not null,
	
	details					text
);
CREATE INDEX productions_subscription_id ON productions(subscription_id);
CREATE INDEX productions_product_id ON productions(product_id);
CREATE INDEX productions_org_id ON productions(org_id);

CREATE VIEW vw_subscriptions AS
	SELECT sys_countrys.sys_country_id, sys_countrys.sys_country_name,
		entitys.entity_id, entitys.entity_name, 
		account_manager.entity_id as account_manager_id, account_manager.entity_name as account_manager_name,
		orgs.org_id, orgs.org_name, 
		
		subscriptions.subscription_id, subscriptions.chama_name, 
		subscriptions.chama_address, subscriptions.city, subscriptions.state, subscriptions.country_id, 
		subscriptions.number_of_members, subscriptions.telephone, subscriptions.website, 
		subscriptions.primary_contact, subscriptions.job_title, subscriptions.primary_email, 
		subscriptions.approve_status, subscriptions.workflow_table_id, subscriptions.application_date, subscriptions.action_date, 
		subscriptions.details
	FROM subscriptions
		INNER JOIN sys_countrys ON subscriptions.country_id = sys_countrys.sys_country_id
		LEFT JOIN entitys ON subscriptions.entity_id = entitys.entity_id
		LEFT JOIN entitys as account_manager ON subscriptions.account_manager_id = account_manager.entity_id
		LEFT JOIN orgs ON subscriptions.org_id = orgs.org_id;	
		
CREATE VIEW vw_productions AS
	SELECT orgs.org_id, orgs.org_name, 
		products.product_id, products.product_name, products.transaction_limit,
		subscriptions.subscription_id, subscriptions.chama_name, 
		
		productions.production_id, productions.approve_status, productions.workflow_table_id, productions.application_date, 
		productions.action_date, productions.montly_billing, productions.is_active, 
		productions.details
	FROM productions INNER JOIN orgs ON productions.org_id = orgs.org_id
		INNER JOIN products ON productions.product_id = products.product_id
		INNER JOIN subscriptions ON productions.subscription_id = subscriptions.subscription_id;

CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON subscriptions
    FOR EACH ROW EXECUTE PROCEDURE upd_action();
    
CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON productions
    FOR EACH ROW EXECUTE PROCEDURE upd_action();

CREATE OR REPLACE FUNCTION ins_subscriptions()
  RETURNS trigger AS
$BODY$
DECLARE
	v_entity_id		integer;
	v_org_id		integer;
	v_currency_id	integer;
	v_department_id	integer;
	v_bank_id		integer;
	v_org_suffix    char(2);
	v_member_id		integer;
	rec 			RECORD;
BEGIN

	IF (TG_OP = 'INSERT') THEN
		SELECT entity_id INTO v_entity_id
		FROM entitys WHERE lower(trim(user_name)) = lower(trim(NEW.primary_email));
		IF(v_entity_id is null)THEN
			NEW.entity_id := nextval('entitys_entity_id_seq');
			INSERT INTO entitys (entity_id, org_id, entity_type_id, entity_name, User_name, primary_email,  function_role, first_password)
			VALUES (NEW.entity_id, 0, 5, NEW.primary_contact, lower(trim(NEW.primary_email)), lower(trim(NEW.primary_email)), 'subscription', null);
		
			INSERT INTO sys_emailed ( org_id, table_id, table_name)
			VALUES ( 0, 1, 'subscription');
		
			ELSE
			RAISE EXCEPTION 'You already have an account, login and request for services';
		END IF ;
		
	ELSIF(NEW.approve_status = 'Approved')THEN

		NEW.org_id := nextval('orgs_org_id_seq');
		
		INSERT INTO orgs(org_id, currency_id, org_name, org_sufix, default_country_id)
		VALUES(NEW.org_id, 1, NEW.chama_name, NEW.org_id, NEW.country_id);
		
		v_currency_id := nextval('currency_currency_id_seq');
		INSERT INTO currency (org_id, currency_id, currency_name, currency_symbol) VALUES (NEW.org_id, v_currency_id, 'Default Currency', 'DC');
		UPDATE orgs SET currency_id = v_currency_id WHERE org_id = NEW.org_id;
		v_bank_id := nextval('banks_bank_id_seq');

		INSERT INTO currency_rates (org_id, currency_id, exchange_rate) VALUES (NEW.org_id, v_currency_id, 1);
		
		INSERT INTO banks (org_id, bank_id, bank_name) VALUES (NEW.org_id, v_bank_id, 'Cash');
		
		INSERT INTO bank_branch (org_id, bank_id, bank_branch_name) VALUES (NEW.org_id, v_bank_id, 'Cash');

		INSERT INTO bank_accounts (org_id, currency_id, bank_account_id, account_id, bank_branch_id, bank_account_name, bank_account_number) VALUES (NEW.org_id, v_currency_id, v_bank_id, '33000', '0','Cash', '0');
		
		INSERT INTO locations (org_id, location_name) VALUES (NEW.org_id, 'Main');

		INSERT INTO transaction_counters(transaction_type_id, org_id, document_number)
		SELECT transaction_type_id, NEW.org_id, 1
		FROM transaction_types;
		
		UPDATE entitys SET org_id = NEW.org_id, function_role='subscription,admin,staff,finance'
		WHERE entity_id = NEW.entity_id;
		
		INSERT INTO members(org_id, entity_id, email, surname) VALUES (NEW.org_id, NEW.entity_id, NEW.primary_email, NEW.primary_contact);

		INSERT INTO sys_emailed ( org_id, table_id, table_name)
		VALUES ( NEW.org_id, NEW.entity_id, 'subscription');
		
		INSERT INTO accounts_class (org_id, accounts_class_no, chat_type_id, chat_type_name, accounts_class_name)
		SELECT NEW.org_id, accounts_class_no, chat_type_id, chat_type_name, accounts_class_name
		FROM accounts_class
		WHERE org_id = 1;
		
		INSERT INTO account_types (org_id, accounts_class_id, account_type_no, account_type_name)
		SELECT a.org_id, a.accounts_class_id, b.account_type_no, b.account_type_name
		FROM accounts_class a INNER JOIN vw_account_types b ON a.accounts_class_no = b.accounts_class_no
		WHERE (a.org_id = NEW.org_id) AND (b.org_id = 1);
		
		INSERT INTO accounts (org_id, account_type_id, account_no, account_name)
		SELECT a.org_id, a.account_type_id, b.account_no, b.account_name
		FROM account_types a INNER JOIN vw_accounts b ON a.account_type_no = b.account_type_no
		WHERE (a.org_id = NEW.org_id) AND (b.org_id = 1);

	END IF;
		
	RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql;
  
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

	
CREATE OR REPLACE FUNCTION ins_transactions_limit() RETURNS trigger AS $$
DECLARE
	v_transaction_count	integer;
	v_transaction_limit	integer;
BEGIN

	SELECT count(transaction_id) INTO v_transaction_count
	FROM transactions
	WHERE (org_id = NEW.org_id);
	
	SELECT transaction_limit INTO v_transaction_limit
	FROM orgs
	WHERE (org_id = NEW.org_id);
	
	IF(v_transaction_count > v_transaction_limit)THEN
		RAISE EXCEPTION 'You have reached the maximum transaction limit, request for a quite for more';
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_transactions_limit BEFORE INSERT ON transactions
    FOR EACH ROW EXECUTE PROCEDURE ins_transactions_limit();
