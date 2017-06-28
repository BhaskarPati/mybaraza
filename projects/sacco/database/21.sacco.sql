
---Project Database File
CREATE TABLE payment_types (
	payment_type_id			serial primary key,
	org_id					integer references orgs,
	payment_type_name		varchar (50),
	payment_narrative 		text
);
CREATE INDEX payment_types_org_id ON payment_types (org_id);

CREATE TABLE contribution_types (
	contribution_type_id	serial primary key,
	org_id					integer references orgs,
	contribution_type_name	varchar(20),
	interval_days			integer,
	amount                  real default 0,
	details					text
);
CREATE INDEX contribution_types_org_id ON contribution_types (org_id);

--Contributions
CREATE TABLE contributions (
	contribution_id			serial primary key,
	entity_id				integer references entitys,  
	period_id				integer references periods, 
	payment_type_id         integer references payment_types,
	contribution_type_id 	integer references contribution_types,
	org_id					integer references orgs, 

	entity_name 			varchar(120),
	contribution_amount		real default 0 not null,
	contribution_paid		real default 0 not null,

	loan_repayment			boolean default false,
	is_paid 				boolean default false,
	
	deposit_date			date,
	receipt					real default 0 not null,
	receipt_date			date,
	repayment_paid			real default 0 not null,
	
	entry_date              timestamp default current_timestamp,
	additional_payments 	real not null default 0,
	transaction_ref         varchar(50),
	
	narrative				varchar(255)
);
CREATE INDEX contributions_entity_id ON contributions (entity_id);
CREATE INDEX contributions_period_id ON contributions (period_id);
CREATE INDEX contributions_payment_type_id ON contributions (payment_type_id);
CREATE INDEX contributions_contribution_type_id ON contributions (contribution_type_id);
CREATE INDEX contributions_orgs_id ON contributions (org_id);

CREATE TABLE additional_funds (
	additional_funds_id		serial primary key,
	contribution_id			integer references contributions,  
	payment_type_id       	integer references payment_types,
	org_id					integer references orgs, 
	
	additional_amount		real not null default 0,
	deposit_date			date,
	
	entry_date              timestamp default CURRENT_TIMESTAMP,
	transaction_ref         varchar(50),
	narrative				varchar(255)
);
CREATE INDEX additional_funds_contribution_id on additional_funds(contribution_id);
CREATE INDEX additional_funds_payment_type_id on additional_funds(payment_type_id);


CREATE TABLE investment_types (
	investment_type_id 		serial primary key,
	org_id					integer references orgs,
	investment_type_name	varchar(120),
	interest_type			real not null default 0,
	details 				text
);
CREATE INDEX investment_types_org_id ON investment_types (org_id);

CREATE TABLE investments (
	investment_id     		serial primary key,
	entity_id				integer references entitys,
	investment_type_id		integer references investment_types,
	org_id					integer references orgs,
	period_id  				integer references periods,
	entity_name 			varchar(120),
	maturity_date			date,
	invest_amount			real,
	yearly_dividend			real,
	withdrawal_date			date,
	withdrwal_amount		real,
	period_years			real not null default 1,
	default_interest 		real not null default 1,
	return_on_investment 	real not null default 0,
	expenses 				real,
	
	application_date		timestamp default now() not null,
	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	action_date				timestamp,
	
	details 				text
);
CREATE INDEX investments_investment_type_id ON investments (investment_type_id);
CREATE INDEX investments_entity_id ON investments (entity_id);
CREATE INDEX investments_period_id ON investments (period_id);
CREATE INDEX investments_org_id ON investments (org_id);

CREATE TABLE applicants	(
	entity_id				integer references entitys,
	org_id 					integer references orgs,
	person_title			varchar(7),
	surname 				varchar(50) not null,
	first_name 				varchar(50) not null,
	middle_name				varchar(50),
	applicant_email			varchar(50) not null,
	applicant_phone			varchar(50),
	date_of_birth			date,
	gender 					varchar(1),
	nationality 			character(2),
	marital_status 			varchar(2),
	picture_file 			varchar(32),
	identity_card 			varchar(50),
	language 				varchar(320),

	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	action_date				timestamp,
	
	salary 					real,
	how_you_heard 			varchar(320),
	created 				timestamp without time zone DEFAULT now(),
	interests				text,
	objective 				text,
	details 				text
);
CREATE INDEX applicants_entity_id ON applicants (entity_id);
CREATE INDEX applicants_org_id ON applicants (org_id);

CREATE TABLE members (
	entity_id 				integer references entitys primary key,
	bank_branch_id			integer references bank_branch,
	recruiter_id 			integer references entitys,
	org_id 					integer references orgs,

	person_title			varchar(7),

	full_name				varchar (120),
	surname 				varchar(50) not null,
	first_name		 		varchar(50) not null,
	middle_name 			varchar(50),
	date_of_birth 			date,
	gender 					varchar(1),
	phone					varchar(120),
	primary_email			varchar(120),
	account_number			varchar(50),

	place_of_birth			varchar(50),
	marital_status 			varchar(2),
	appointment_date 		timestamp default now(),

	exit_date 				date,
	exit_amount				real default 0 null,
	
	picture_file 			varchar(32),
	active 					boolean not null default true,
	language 				varchar(320),
	interests 				text,
	objective 				text,
	details 				text,
	division 				varchar (120),
	location 				varchar (120),
	sub_location			varchar (120),
	district				varchar (120),
	county					varchar (120) not null default 'Nairobi',
	residential_address 	varchar (120),

	expired 				boolean default false,
	contribution			real default 0 not null
);	 
CREATE INDEX members_bank_branch_id ON members (bank_branch_id);
CREATE INDEX members_recruiter_id ON members (recruiter_id); 
CREATE INDEX members_org_id ON members (org_id);
 
ALTER TABLE entitys ADD exit_amount REAL default 0;

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
	
	postal_address 			varchar (120) ,
	tel_number 				varchar (120) ,
	email_address			varchar (120) ,
	pin						varchar (120) ,
	postal_code 			varchar (120),
	details					text
);
CREATE INDEX kins_entity_id ON kins (entity_id);
CREATE INDEX kins_kin_type_id ON kins (kin_type_id);
CREATE INDEX kins_org_id ON kins(org_id);

CREATE TABLE employment (
	employment_id			serial primary key,
	entity_id				integer references entitys,
	org_id					integer references orgs,
	employer_names			varchar(120),
	current_branch			varchar (120),
	staff_number			varchar(120),			
	employer_address		varchar(50),
	employer_postal_code	varchar(50),
	employer_contact_person	varchar(120),
	employer_email			varchar(50),
	telephone_number 		varchar(60),
	details					text
);
CREATE INDEX employment_entity_id ON employment (entity_id);
CREATE INDEX employment_org_id ON employment(org_id);

CREATE TABLE member_business (
	member_business_id 		serial primary key,
	entity_id				integer references entitys,
	org_id					integer references orgs,
	business_name			varchar(120),
	nature_of_business		varchar(120),
	business_address		varchar(120),
	business_location		varchar(120),
	business_telephone		varchar(120),
	business_telephone_1	varchar(120),			
	business_email			varchar(120),
	business_area_code		varchar(120),
	registration_particulars	varchar(240),
	details					text
);
CREATE INDEX member_business_entity_id ON member_business (entity_id);
CREATE INDEX member_business_org_id ON member_business(org_id);

CREATE TABLE sacco_investments (
   	sacco_investment_id		serial primary key,
	investment_type_id		integer references investment_types, 
	currency_id				integer references currency,
    org_id					integer references orgs,
    bank_account_id 		integer references bank_accounts,
    
    investment_name 		varchar(120),
	investment_status		varchar(25) NOT NULL DEFAULT 'Prospective',
	date_of_accrual			date,
	principal 				real,
	interest				real,
	repayment_period		real,
	initial_payment			real default 0 not null,
	monthly_payments		real,
	
	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	action_date				timestamp,
	
	is_active				boolean default true not null,
	details					text
);
CREATE INDEX sacco_investments_bank_account_id ON sacco_investments (bank_account_id);
CREATE INDEX sacco_investments_investment_type_id ON sacco_investments (investment_type_id);
CREATE INDEX sacco_investments_currency_id ON sacco_investments (currency_id);
CREATE INDEX sacco_investments_org_id ON sacco_investments (org_id);
