CREATE TABLE locations ( 
	location_id				serial primary key,
	org_id					integer references orgs,
	location_name			varchar(50),
	details					text
);
CREATE INDEX locations_org_id ON locations(org_id);



--drop table employees_details cascade

CREATE TABLE employees_details(
	employees_details_id		serial primary key,
	entity_id				integer not null references entitys,
	staff_id				integer references staff,
	location_id				integer  references locations,
	bank_branch_id			integer  references bank_branch,
	currency_id				integer  references currency,
	org_id					integer not null references orgs,

	
	person_title			varchar(7),
	designation				varchar (25) not null default 'Teaching',
	surname					varchar(50) not null,
	first_name				varchar(50) not null,
	middle_name				varchar(50),
	date_of_birth			date,
	dob_email				date default '2016-01-01'::date,
	
	
	gender					varchar(1),
	phone					varchar(120),
	nationality				char(2) not null references sys_countrys default 'KE',
	
	nation_of_birth			char(2) references sys_countrys,
	place_of_birth			varchar(50),
	
	marital_status 			varchar(2),
	appointment_date		date,
	current_appointment		date,

	exit_date				date,
	contract				boolean default false not null,
	contract_period			integer not null default 1,
	employment_terms		varchar(320),
	identity_card			varchar(50),
	basic_salary			real not null default 0,
	bank_account			varchar(32),
	picture_file			varchar(32),
	active					boolean default true not null,
	language				varchar(320),
	
	previous_salary			varchar(16),
	bio_metric_number		varchar(32),

	height					real, 
	weight					real, 
	blood_group				varchar(3),
	allergies				varchar(320),

	field_of_study			text,
	major					text,
	institution				text, 
	interests				text,
	objective				text,
	details					text,

	UNIQUE(org_id, staff_id)
);
CREATE INDEX employees_details_entity_id ON employees_details (entity_id);
CREATE INDEX employees_details_staff_id ON employees_details (staff_id);
CREATE INDEX employees_details_bank_branch_id ON employees_details (bank_branch_id);
CREATE INDEX employees_details_location_id ON employees_details (location_id);
CREATE INDEX employees_details_nationality ON employees_details (nationality);
CREATE INDEX employees_details_nation_of_birth ON employees_details (nation_of_birth);
CREATE INDEX employees_details_currency_id ON employees_details (currency_id);
CREATE INDEX employees_details_org_id ON employees_details(org_id);




