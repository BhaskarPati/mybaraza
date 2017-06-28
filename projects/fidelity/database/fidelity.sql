---Project Database File
CREATE TABLE account_types (
	account_type_id			serial	primary key,
	account_type_name		varchar(50),
	details					text
);

CREATE TABLE corporate_types (
	corporate_type_id		serial	primary key,
	corporate_type_name		varchar(50),
	details					text
);

CREATE TABLE account_openings (
	account_opening_id		serial primary key,
	account_type_id			integer references account_types,
	corporate_type_id		integer references corporate_types,
	currency_id				integer references currency,
	entity_id				integer references entitys,
	
	account_name			varchar(50),
	business_address		varchar(100),
	city					varchar(30),
	state					varchar(50),
	phone					varchar(50),
	email					varchar(120),
	website					varchar(120),
	
	primary_contact			varchar(120),
	primary_email			varchar(120)
);
CREATE INDEX account_openings_account_type_id ON account_openings(account_type_id);
CREATE INDEX account_openings_corporate_type_id ON account_openings(corporate_type_id);
CREATE INDEX account_openings_entity_id ON account_openings(entity_id);

CREATE TABLE accounts (
	org_id					integer references orgs primary key,
	account_type_id			integer references account_types,
	corporate_type_id		integer references corporate_types,
	country_id				char(2) references sys_countrys,
	currency_id				integer references currency,
	entity_id				integer references entitys,
	
	account_name			varchar(50),
	business_address		varchar(100),
	city					varchar(30),
	lga						varchar(50),
	state					varchar(50),
	phone					varchar(50),
	email					varchar(120),
	website					varchar(120),
	
	commencement_date		date,
	incorporation_date		date,
	incorporation_no		varchar(50),
	industry_sector			varchar(50),
	line_of_business		varchar(50),
	
	annual_revenue			float,
	tax_id_number			varchar(50),
	employees_no			integer,
	activity				varchar(10),
	other_banks				varchar(50),
	
	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	application_date		timestamp default now(),
	action_date				timestamp,
	
	details					text
);
CREATE INDEX accounts_org_id ON accounts(org_id);
CREATE INDEX accounts_account_type_id ON accounts(account_type_id);
CREATE INDEX accounts_corporate_type_id ON accounts(corporate_type_id);
CREATE INDEX accounts_country_id ON accounts(country_id);
CREATE INDEX accounts_currency_id ON accounts(currency_id);
CREATE INDEX accounts_entity_id ON accounts(entity_id);

CREATE TABLE id_types (
	id_type_id				serial	primary key,
	id_type_name			varchar(50),
	details					text
);

CREATE TABLE directors (
	entity_id				integer references entitys primary key,
	id_type_id				integer references id_types,
	org_id					integer references orgs,
	director_name			varchar(50),
	id_no					varchar(20),
    email					varchar(50),
	gsm_no					varchar(20),
	
	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	application_date		timestamp default now(),
	action_date				timestamp,
	
	signatory				bytea,
	details					text
);
CREATE INDEX directors_entity_id ON directors(entity_id);
CREATE INDEX directors_id_type_id ON directors(id_type_id);
CREATE INDEX directors_org_id ON directors(org_id);

CREATE TABLE loan_types (
	loan_type_id			serial primary key,
	loan_type_name			varchar(50),
	default_interest		integer,
	details					text
);

CREATE TABLE loans (
	loan_id 				serial primary key,
	loan_type_id			integer references loan_types,
	entity_id				integer references entitys,
	org_id					integer references orgs,
	loan_date				date not null default current_date,
	principle				real not null,
	interest				real not null,
	monthly_repayment		real not null,
	repayment_period		integer not null CHECK (repayment_period > 0),
	
    approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	application_date		timestamp default now(),
	action_date				timestamp,
	
	guarantor1_name			varchar(50),
	guarantor1_address		varchar(50),
	guarantor2_name			varchar(50),
	guarantor2_address		varchar(50),
	security1_desc			text,
	security2_desc			text,
	security3_desc			text,
	details				    text
);
CREATE INDEX loans_loan_type_id ON loans(loan_type_id);
CREATE INDEX loans_entity_id ON loans(entity_id);
CREATE INDEX loans_org_id ON loans(org_id);

CREATE VIEW vw_account_openings AS
	SELECT account_types.account_type_id, account_types.account_type_name, 
		corporate_types.corporate_type_id, corporate_types.corporate_type_name, 
		account_openings.entity_id, account_openings.account_opening_id, account_openings.account_name, 
		account_openings.business_address, account_openings.city, account_openings.state, 
		account_openings.phone, account_openings.email, account_openings.website, 
		account_openings.primary_contact, account_openings.primary_email
	FROM account_openings INNER JOIN account_types ON account_openings.account_type_id = account_types.account_type_id
	INNER JOIN corporate_types ON account_openings.corporate_type_id = corporate_types.corporate_type_id;
	
CREATE VIEW vw_accounts AS
	SELECT account_types.account_type_id, account_types.account_type_name, 
		corporate_types.corporate_type_id, corporate_types.corporate_type_name, 
		currency.currency_id, currency.currency_name, currency.currency_symbol,
		orgs.org_id, orgs.org_name,
		sys_countrys.sys_country_id, sys_countrys.sys_country_name, 
		accounts.entity_id, accounts.account_name, accounts.business_address, accounts.city, 
		accounts.lga, accounts.state, accounts.phone, accounts.email, accounts.website, 
		accounts.commencement_date, accounts.incorporation_date, accounts.incorporation_no, 
		accounts.industry_sector, accounts.line_of_business, accounts.annual_revenue, 
		accounts.tax_id_number, accounts.employees_no, accounts.activity, accounts.other_banks, 
		accounts.approve_status, accounts.workflow_table_id, accounts.application_date, accounts.action_date, 
		accounts.details
	FROM accounts INNER JOIN account_types ON accounts.account_type_id = account_types.account_type_id
	INNER JOIN corporate_types ON accounts.corporate_type_id = corporate_types.corporate_type_id
	INNER JOIN orgs ON accounts.org_id = orgs.org_id
	INNER JOIN currency ON accounts.currency_id = currency.currency_id
	LEFT JOIN sys_countrys ON accounts.country_id = sys_countrys.sys_country_id;
	
CREATE VIEW vw_directors AS
	SELECT entitys.entity_id, entitys.entity_name, id_types.id_type_id, id_types.id_type_name, 
		orgs.org_id, orgs.org_name, directors.director_name, directors.id_no, directors.email, directors.gsm_no, 
		directors.approve_status, directors.workflow_table_id, directors.application_date, directors.action_date, 
		directors.signatory, directors.details
	FROM directors INNER JOIN entitys ON directors.entity_id = entitys.entity_id
	INNER JOIN id_types ON directors.id_type_id = id_types.id_type_id
	INNER JOIN orgs ON directors.org_id = orgs.org_id;
	
CREATE VIEW vw_loans AS
	SELECT entitys.entity_id, entitys.entity_name, loan_types.loan_type_id, loan_types.loan_type_name, 
		loans.org_id, loans.loan_id, loans.loan_date, loans.principle, loans.interest, loans.monthly_repayment, 
		loans.repayment_period, loans.approve_status, loans.workflow_table_id, loans.application_date, 
		loans.action_date, loans.details
	FROM loans INNER JOIN entitys ON loans.entity_id = entitys.entity_id
		INNER JOIN loan_types ON loans.loan_type_id = loan_types.loan_type_id;


INSERT INTO id_types (id_type_name) VALUES ('international passport'),('national drivers licence'),('national id card');
INSERT INTO account_types (account_type_name) VALUES ('Corporate'),('DBXA starter'),('DBXA growing'),('Established'),('Govt agency'),('MIDs'), ('PMIs'),('Others(specify)');
INSERT INTO corporate_types (corporate_type_name) VALUES ('PLC'),('LTD'),('Enterprise'),('Ass & club'),('Govt agency'),('Unlimited'),('Partnership'),('Enterprise'),('Others(specify)');
INSERT INTO sys_emails(sys_email_id,org_id,sys_email_name,title,details) VALUES (1,0,'Application','Thanks for your application','Thanks for your application');
 
CREATE OR REPLACE FUNCTION ins_account_openings() RETURNS trigger AS $$
DECLARE
	v_org_id		integer;
	v_org_suffix    char(2);
	rec 			RECORD;
BEGIN
	IF (TG_OP = 'INSERT') THEN
		v_org_id := nextval('orgs_org_id_seq');
		INSERT INTO orgs(org_id, currency_id, org_name,org_sufix)
		VALUES(v_org_id, NEW.currency_id, NEW.account_name,v_org_id);
		
		NEW.entity_id := nextval('entitys_entity_id_seq');
		INSERT INTO entitys (entity_id, org_id, entity_type_id, entity_name, User_name, primary_email,  function_role)
		VALUES (NEW.entity_id, v_org_id, 2, NEW.primary_contact, lower(trim(NEW.primary_email)), lower(trim(NEW.primary_email)), 'client');
		
		

		INSERT INTO sys_emailed (sys_email_id, org_id, table_id, table_name)
		VALUES (1, v_org_id, NEW.entity_id, 'student');
		
		INSERT INTO accounts(org_id, account_type_id, corporate_type_id, currency_id, 
            entity_id, account_name, business_address, city, state, 
            phone, email, website, approve_status)
        VALUES (v_org_id,NEW.account_type_id,NEW.corporate_type_id,NEW.currency_id,NEW.entity_id,NEW.account_name,NEW.business_address,NEW.city,
            NEW.state,NEW.phone,NEW.email,NEW.website, 'Draft');
	
	
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_account_openings BEFORE INSERT ON account_openings
    FOR EACH ROW EXECUTE PROCEDURE ins_account_openings();
 

CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON accounts
    FOR EACH ROW EXECUTE PROCEDURE upd_action();
    

CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON loans
    FOR EACH ROW EXECUTE PROCEDURE upd_action();

CREATE OR REPLACE FUNCTION account_completion(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	msg 		varchar(120);
BEGIN

	UPDATE accounts SET approve_status = 'Completed' WHERE org_id = $1::integer;
	
	msg := 'Account completed and forwarded for approval';

	RETURN msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION loan_completion(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	msg 		varchar(120);
BEGIN

	UPDATE loans SET approve_status = 'Completed' WHERE org_id = $1::integer;
	
	msg := 'Loan completed and forwarded for approval';

	RETURN msg;
END;
$$ LANGUAGE plpgsql;
