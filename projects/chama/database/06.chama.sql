CREATE TABLE members (
	entity_id 					integer primary key references entitys,
	bank_id						integer references banks,
	bank_account_id				integer references bank_accounts,
	bank_branch_id 				integer references bank_branch,
 	org_id 						integer references orgs,
	location_id					integer references locations,

	person_title				varchar(50),
	surname 					varchar(50) ,
	first_name 					varchar(50) ,
  	middle_name 				varchar(50),
  	full_name					varchar(50),
  	id_number					varchar(50) ,
  	email						varchar(50),
  	date_of_birth 				date,
  	
	gender 						varchar(10),
 	phone						varchar(50),
 	bank_account_number			varchar(50),
  	nationality 				char(2) references sys_countrys,
  	nation_of_birth 			char(2) references sys_countrys,
  	marital_status 				varchar(20),
	joining_date				date,
	exit_date					date,
	merry_go_round_number 		integer,

 	picture_file 				character varying(32),
  	active 						boolean DEFAULT true,
  	details 					text
);

CREATE INDEX members_bank_id ON members (bank_id);
CREATE INDEX members_entity_id ON members (entity_id);
CREATE INDEX members_bank_branch_id ON members (bank_branch_id);
CREATE INDEX members_bank_account_id ON members (bank_account_id);
CREATE INDEX members_org_id ON members (org_id);
CREATE INDEX members_location_id ON members (location_id);
CREATE INDEX members_nationality ON members (nationality);
CREATE INDEX members_nation_of_birth ON members (nation_of_birth);

CREATE TABLE meetings (
	meeting_id					serial primary key,
	org_id                      integer references orgs,
	meeting_date				date,
	meeting_place				varchar (120) not null,
	status						varchar (16) default 'Draft' not null,
	minutes						text,
	details						text
);

CREATE INDEX meetings_org_id ON meetings (org_id);

CREATE TABLE contribution_types (
	contribution_type_id		serial primary key,
	org_id						integer references orgs,
	contribution_type_name		varchar(240),
	investment_amount			real default 0 not null,
	merry_go_round_amount		real default 0 not null,
	frequency					varchar (15),		--- Irregural, Weekly, Fortnighly, Monthly,  quartely, semi-annually, annually
	applies_to_all				boolean default true not null,
	day_of_contrib				varchar(12),
	details						text
);	
CREATE INDEX contribution_types_org_id ON contribution_types (org_id);

CREATE TABLE contribution_defaults (
	contribution_default_id    	serial primary key,
	contribution_type_id 		integer references contribution_types,
	entity_id					integer references entitys,
	org_id						integer references orgs,

	investment_amount			real default 0 not null,
	merry_go_round_amount		real default 0 not null,
	details						text
);

CREATE INDEX contribution_defaults_contributions_type_id ON contribution_defaults (contribution_type_id);
CREATE INDEX contribution_defaults_org_id ON contribution_defaults (org_id);
CREATE INDEX contribution_defaults_entity_id ON contribution_defaults (entity_id);


CREATE TABLE contributions (
	contribution_id				serial primary key,
	contribution_type_id		integer references contribution_types,
	entity_id					integer references entitys,
	period_id					integer references periods,
	org_id						integer references orgs,
	
	contribution_date			date,
	investment_amount			real not null,
	merry_go_round_amount	 	real,
	loan_contrib				real DEFAULT 0,
	paid						boolean DEFAULT false,
	extra_contrib				boolean DEFAULT false,
	
	details						text
);

CREATE INDEX contributions_contributions_type_id ON contributions (contribution_type_id);
CREATE INDEX contributions_entity_id ON contributions (entity_id);
CREATE INDEX contributions_period_id ON contributions (period_id);
CREATE INDEX contributions_org_id ON contributions (org_id);

CREATE TABLE drawings (
	drawing_id					serial primary key,
	org_id						integer references orgs,
	period_id					integer references periods,
	entity_id					integer references entitys,
	bank_account_id 			integer references bank_accounts,

	withdrawal_date				date,
	narrative					varchar(120),
	ref_number					varchar(24),
	amount						real,
	recieved					boolean DEFAULT false,
	details						text
);

CREATE INDEX drawings_org_id ON drawings(org_id);
CREATE INDEX drawings_period_id ON drawings(period_id);
CREATE INDEX drawings_entity_id ON drawings(entity_id);
CREATE INDEX drawings_bank_account_id ON drawings(bank_account_id);

CREATE TABLE receipts (
	receipts_id					serial primary key,
	org_id						integer references orgs,
	period_id					integer references periods,
	entity_id					integer references entitys,
	bank_account_id 			integer references bank_accounts,

	receipts_date				date,
	narrative					varchar(120),
	ref_number					varchar(24),
	amount						real,
	remaining_amount			real default 0,
	details						text
);

CREATE INDEX receipts_org_id ON receipts(org_id);
CREATE INDEX receipts_period_id ON receipts(period_id);
CREATE INDEX receipts_entity_id ON receipts(entity_id);
CREATE INDEX receipts_bank_account_id ON receipts(bank_account_id);

CREATE TABLE penalty_type (
	penalty_type_id				serial primary key,
	org_id                      integer references orgs,
	penalty_type_name           varchar (120) ,
	details						text
);

CREATE INDEX penalty_type_org_id ON penalty_type (org_id);

CREATE TABLE penalty (
	penalty_id               	serial primary key,
	penalty_type_id				integer references penalty_type, 
	bank_account_id 			integer references bank_accounts, 
	currency_id                 integer references currency,
    org_id                      integer references orgs,
	entity_id 					integer references entitys,
	date_of_accrual             date,
	amount                      real not null,
	paid						boolean default true not null,
	penalty_paid				real default  0 not null,
	action_date					timestamp,
	is_active                   boolean default true not null,
	details                     text
);


CREATE INDEX penalty_bank_account_id ON penalty (bank_account_id);
CREATE INDEX penalty_penalty_type_id ON penalty (penalty_type_id);
CREATE INDEX penalty_currency_id ON penalty (currency_id);
CREATE INDEX penalty_org_id ON penalty (org_id);
CREATE INDEX penalty_entity_id ON penalty (entity_id);

CREATE TABLE expenses (
	expense_id					serial primary key,
	entity_id					integer references entitys,
	bank_account_id				integer references bank_accounts,
	org_id						integer references orgs,
	currency_id					integer references currency,
	date_accrued				date,
	amount						real not null,
	details						text
);

CREATE INDEX expenses_entity_id ON expenses (entity_id);
CREATE INDEX expenses_bank_account_id ON expenses (bank_account_id);
CREATE INDEX expenses_currency_id ON expenses (currency_id);
CREATE INDEX expenses_org_id ON expenses (org_id);


CREATE TABLE investment_types (
	investment_type_id			serial primary key,
	org_id                      integer references orgs,
	investment_type_name        varchar (120) ,
	interest_amount 			real,
	details						text
);

CREATE INDEX investment_types_org_id ON investment_types (org_id);


CREATE TABLE investments (
   	investment_id               serial primary key,
	investment_type_id			integer references investment_types, 
	currency_id                 integer references currency,
    org_id                      integer references orgs,
    bank_account_id 			integer references bank_accounts,
    
    investment_name 			varchar(120),
	investment_status			character varying(25) NOT NULL DEFAULT 'Prospective',
	date_of_accrual             date,
	principal 					real,
	interest					real,
	repayment_period			real,
	initial_payment				real default 0 not null,
	monthly_payments			real,
	
	approve_status				varchar(16) default 'Draft' not null,
	workflow_table_id			integer,
	action_date					timestamp,
	
	is_active                   boolean default true not null,
	details                     text
);
CREATE INDEX investments_bank_account_id ON investments (bank_account_id);
CREATE INDEX investments_investment_type_id ON investments (investment_type_id);
CREATE INDEX investments_currency_id ON investments (currency_id);
CREATE INDEX investments_org_id ON investments (org_id);


ALTER TABLE transactions ADD investment_id integer references investments;
CREATE INDEX transactions_investment_id ON transactions (investment_id);




CREATE TABLE member_meeting (
	member_meeting_id			serial primary key,
	entity_id 					integer references entitys,
	meeting_id					integer references meetings,
	org_id                      integer references orgs,
	narrative					text
	);

ALTER TABLE periods ADD COLUMN mgr_number integer;

