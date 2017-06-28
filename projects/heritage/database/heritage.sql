---Project Database File
ALTER TABLE orgs ADD credit_limit real not null default 0;
ALTER TABLE entitys ADD son varchar(15);
ALTER TABLE entitys ADD last_login timestamp;
ALTER TABLE entitys ADD salutation varchar(7);
ALTER TABLE entitys ADD birth_date date;

CREATE TABLE city_codes (
	city_code				char(3) primary key,
	city_name				varchar(100),
	country					varchar(100),
	sys_country_id			char(2) references sys_countrys
);

CREATE TABLE rate_category(
    rate_category_id              serial PRIMARY KEY,
    rate_category_name            character varying(120),
    group_rates                   boolean
);

CREATE TABLE rate_plan(
    rate_plan_id              serial PRIMARY KEY,
    rate_plan_name            character varying(50)
);

CREATE TABLE rate_types(
    rate_type_id            serial PRIMARY KEY,
    rate_category_id        integer references rate_category,
    rate_plan_id            integer references rate_plan,
    rate_type_name          character varying(100),
    age_limit               integer DEFAULT 70,
    age_from                integer,
    age_to                  integer,
    details                 text
);
CREATE INDEX rate_types_rate_plan_id ON rate_types(rate_plan_id);
CREATE INDEX rate_types_rate_category_id ON rate_types(rate_category_id);

CREATE TABLE benefit_types (
	benefit_type_id			serial primary key,
	benefit_type_name		varchar(100),
    benefit_section 		character varying(5),
	details					text
);

CREATE TABLE benefits (
	benefit_id				serial primary key,
	rate_type_id			integer references rate_types,
	benefit_type_id			integer references benefit_types,
	individual				text,
	others					text,
	UNIQUE(rate_type_id, benefit_type_id)
);
CREATE INDEX benefits_rate_type_id ON benefits(rate_type_id);
CREATE INDEX benefits_benefit_type_id ON benefits(benefit_type_id);


CREATE TABLE rates(
    rate_id             serial primary key,
    rate_type_id        integer references rate_types,
    days_from           integer,
    days_to             integer,
    standard_rate       real,
    north_america_rate  real,
	incountry_rate		real
);
CREATE INDEX rates_rate_type_id ON rates(rate_type_id);


CREATE TABLE policy_sequence(
  policy_no_id 		serial PRIMARY KEY,
  policy_sequence_no 	character varying(50)
);
INSERT INTO policy_sequence (policy_sequence_no) VALUES ('000');

CREATE TABLE corporate_rate_category
(
  corporate_rate_category_id serial primary key,
  corporate_rate_category_name character varying(120)
);

CREATE TABLE corporate_rate_plan(
    rate_plan_id              serial PRIMARY KEY,
    rate_plan_name            character varying(50)
);

CREATE TABLE corporate_rate_types  (
  rate_type_id 		serial PRIMARY KEY,
  corporate_rate_category_id integer references corporate_rate_category,
  rate_plan_id            integer references corporate_rate_plan,
  rate_type_name 	character varying(100),
  age_limit 		integer DEFAULT 80,
  details 		text
);
CREATE INDEX corporate_rate_plan_id ON corporate_rate_types(rate_plan_id);
CREATE INDEX corporate_rate_types_rate_category_id ON corporate_rate_types(corporate_rate_category_id);

CREATE TABLE corporate_benefit_types  (
  corporate_benefit_type_id 		serial PRIMARY KEY,
  corporate_section                 character varying(5),
  corporate_benefit_type_name 		character varying(100),
  details 			    			text
);

CREATE TABLE corporate_benefits (
  benefit_id 		    		serial PRIMARY KEY,
  rate_type_id 					integer references corporate_rate_types,
  corporate_benefit_type_id 	integer references corporate_benefit_types,
  individual 		    		text,
  others 		        		text
);
CREATE INDEX corporate_benefits_benefit_type_id ON corporate_benefits(corporate_benefit_type_id);
CREATE INDEX corporate_rate_types_rate_type_id ON corporate_benefits(rate_type_id);



CREATE TABLE corporate_rates   (
	corporate_rate_id 		        serial PRIMARY KEY,
	rate_type_id 		    		integer references corporate_rate_types,
	days_from 		    			integer,
	days_to 		      			integer,
	standard_rate 	    			real,
	north_america_rate 				real
	);
CREATE INDEX corporate_rates_rate_type_id ON corporate_rates(rate_type_id);


CREATE TABLE passengers(
	passenger_id 			serial primary key,
	rate_id 				integer REFERENCES rates ,
	corporate_rate_id			integer REFERENCES corporate_rates,
	entity_id 				integer REFERENCES entitys,
	org_id 					integer REFERENCES orgs,
	policy_number 			character varying(50),
	passenger_name 			character varying(100),
	passenger_mobile 		character varying(15),
	passenger_email 		character varying(100),
	passenger_age 			integer DEFAULT 0,
	passenger_id_no 		character varying(20),
	passenger_dob 			character varying(20),
	pin_no 					character varying(25),
	days_covered 			integer,
	nok_name 				character varying(100),
	nok_mobile 				character varying(15),
	passport_num 			character varying(20),
	is_north_america 		boolean DEFAULT false,
	cover_amount 			real,
	totalamount_covered 	real,
	approved 				boolean DEFAULT false,
	details 				text,
	days_from 				date,
	days_to 				date,
	destown 				character varying(50),
	approved_date 			timestamp without time zone,
	sys_country_id 			character varying(2),
	countries 				text,
	relationship 			character varying(120),
	address 				text,
	departure_country 		character varying(50),
	reason_for_travel 		text,
	customer_code 			character varying(50),
	customer_name 			character varying(100),
	postal_code 			character varying(50),
	expiry_date 			character varying(20),
	incountry				boolean default false,
	physical_address 		text,
	exchange_rate			real ,
	kesamount				real,
	pnrno					character varying(50),
	policy_holder_fund		real,
	stamp_duty				real,
	training_levy			real

);
CREATE INDEX passengers_rate_id ON passengers(rate_id);
CREATE INDEX passengers_corporate_rate_id ON passengers(corporate_rate_id);
CREATE INDEX passengers_entity_id ON passengers(entity_id);
CREATE INDEX passengers_org_id ON passengers(org_id);



DROP VIEW vw_entitys;
DROP VIEW vw_orgs;

CREATE OR REPLACE VIEW vw_orgs AS
SELECT orgs.org_id, orgs.org_name, orgs.is_default, orgs.is_active, orgs.logo, orgs.pcc,
		vw_org_address.org_sys_country_id, vw_org_address.org_sys_country_name,
		vw_org_address.org_address_id, vw_org_address.org_table_name,
		vw_org_address.org_post_office_box, vw_org_address.org_postal_code,
		vw_org_address.org_premises, vw_org_address.org_street, vw_org_address.org_town,
		vw_org_address.org_phone_number, vw_org_address.org_extension,
		vw_org_address.org_mobile, vw_org_address.org_fax, vw_org_address.org_email, vw_org_address.org_website, orgs.credit_limit
	FROM orgs LEFT JOIN vw_org_address ON orgs.org_id = vw_org_address.org_table_id;

CREATE OR REPLACE VIEW vw_entitys AS
	SELECT vw_orgs.org_id, vw_orgs.org_name, vw_orgs.is_default as org_is_default,
	vw_orgs.is_active as org_is_active, vw_orgs.logo as org_logo, vw_orgs.pcc,

	vw_orgs.org_sys_country_id, vw_orgs.org_sys_country_name,
	vw_orgs.org_address_id, vw_orgs.org_table_name,
	vw_orgs.org_post_office_box, vw_orgs.org_postal_code,
	vw_orgs.org_premises, vw_orgs.org_street, vw_orgs.org_town,
	vw_orgs.org_phone_number, vw_orgs.org_extension,
	vw_orgs.org_mobile, vw_orgs.org_fax, vw_orgs.org_email, vw_orgs.org_website,

	vw_entity_address.address_id, vw_entity_address.address_name,
	vw_entity_address.sys_country_id, vw_entity_address.sys_country_name, vw_entity_address.table_name,
	vw_entity_address.is_default, vw_entity_address.post_office_box, vw_entity_address.postal_code,
	vw_entity_address.premises, vw_entity_address.street, vw_entity_address.town,
	vw_entity_address.phone_number, vw_entity_address.extension, vw_entity_address.mobile,
	vw_entity_address.fax, vw_entity_address.email, vw_entity_address.website,

	entitys.entity_id, entitys.entity_name, entitys.user_name, entitys.super_user, entitys.entity_leader,
	entitys.date_enroled, entitys.is_active, entitys.entity_password, entitys.first_password,
	entitys.function_role, entitys.primary_email, entitys.primary_telephone,
	entitys.salutation, entitys.son,entitys.birth_date,entitys.last_login,
	entity_types.entity_type_id, entity_types.entity_type_name
	FROM (entitys LEFT JOIN vw_entity_address ON entitys.entity_id = vw_entity_address.table_id)
	INNER JOIN vw_orgs ON entitys.org_id = vw_orgs.org_id
	INNER JOIN entity_types ON entitys.entity_type_id = entity_types.entity_type_id;

CREATE OR REPLACE VIEW vw_rate_types AS
 SELECT rate_types.rate_type_id, rate_types.rate_type_name, rate_types.age_limit, rate_types.details, rate_types.age_from,
    rate_types.age_to, rate_category.rate_category_name, rate_plan.rate_plan_name, rate_plan.rate_plan_id, rate_category.rate_category_id
   FROM rate_types
     JOIN rate_category ON rate_types.rate_category_id = rate_category.rate_category_id
     JOIN rate_plan ON rate_plan.rate_plan_id = rate_types.rate_plan_id;

CREATE OR REPLACE VIEW vw_benefits AS
    SELECT benefit_types.benefit_type_id, benefit_types.benefit_type_name,  benefit_types.benefit_section, vw_rate_types.rate_type_id,
        vw_rate_types.rate_plan_name, benefits.benefit_id, benefits.individual, benefits.others
    FROM benefits
     JOIN benefit_types ON benefits.benefit_type_id = benefit_types.benefit_type_id
     JOIN vw_rate_types ON benefits.rate_type_id = vw_rate_types.rate_type_id;

CREATE OR REPLACE VIEW vw_rate_plan AS
    SELECT rate_plan.rate_plan_id, rate_plan.rate_plan_name
    FROM rate_plan;



CREATE OR REPLACE VIEW vw_rates AS
    SELECT vw_rate_types.rate_type_id, vw_rate_types.rate_type_name, rates.rate_id, rates.days_from, rates.days_to, rates.standard_rate,
     rates.north_america_rate,  vw_rate_types.rate_category_name, vw_rate_types.rate_category_id, vw_rate_types.rate_plan_id,
     vw_rate_types.rate_plan_name, vw_rate_types.age_from, vw_rate_types.age_to,rates.incountry_rate
    FROM rates
      JOIN vw_rate_types ON rates.rate_type_id = vw_rate_types.rate_type_id;


CREATE OR REPLACE VIEW vw_passengers AS
SELECT vw_entitys.org_id,  vw_entitys.org_name, vw_rates.rate_type_id, vw_rates.rate_plan_id, vw_rates.rate_category_name, vw_rates.rate_id,
  vw_rates.rate_plan_name, vw_rates.standard_rate, vw_rates.north_america_rate, passengers.days_from, passengers.days_to, passengers.approved,
  passengers.entity_id, passengers.countries, passengers.passenger_id, passengers.passenger_name, passengers.passenger_mobile, passengers.passenger_email,
  passengers.passenger_age, passengers.days_covered, passengers.nok_name, passengers.nok_mobile, passengers.passenger_id_no, passengers.passport_num,
  passengers.cover_amount, passengers.totalamount_covered, passengers.is_north_america, passengers.details, passengers.passenger_dob,
  passengers.policy_number, vw_entitys.entity_name, passengers.destown, sys_countrys.sys_country_name, passengers.approved_date, passengers.pin_no,
  passengers.reason_for_travel, passengers.departure_country, vw_entitys.function_role, vw_entitys.is_active,passengers.customer_code,passengers.customer_name,
  passengers.incountry
 FROM passengers
   JOIN vw_rates ON passengers.rate_id = vw_rates.rate_id
   JOIN vw_entitys ON passengers.entity_id = vw_entitys.entity_id
   JOIN sys_countrys ON passengers.sys_country_id = sys_countrys.sys_country_id;

   CREATE OR REPLACE VIEW vw_corporate_rate_types AS
   SELECT corporate_rate_types.rate_type_id,  corporate_rate_types.rate_type_name,  corporate_rate_types.age_limit,
  	corporate_rate_types.details,  corporate_rate_category.corporate_rate_category_name,corporate_rate_plan.rate_plan_name, corporate_rate_plan.rate_plan_id,
  	corporate_rate_types.corporate_rate_category_id
     FROM corporate_rate_types
     JOIN corporate_rate_category ON corporate_rate_types.corporate_rate_category_id = corporate_rate_category.corporate_rate_category_id
     JOIN corporate_rate_plan ON corporate_rate_plan.rate_plan_id = corporate_rate_types.rate_plan_id;

    CREATE OR REPLACE VIEW vw_corporate_rates AS
    SELECT vw_corporate_rate_types.rate_type_id, vw_corporate_rate_types.rate_type_name, corporate_rates.corporate_rate_id,
    corporate_rates.days_from, corporate_rates.days_to, corporate_rates.standard_rate, corporate_rates.north_america_rate,
     vw_corporate_rate_types.rate_plan_name,vw_corporate_rate_types.corporate_rate_category_name,vw_corporate_rate_types.rate_plan_id,
    vw_corporate_rate_types.corporate_rate_category_id
    FROM corporate_rates
    JOIN vw_corporate_rate_types ON corporate_rates.rate_type_id = vw_corporate_rate_types.rate_type_id;

CREATE OR REPLACE VIEW vw_corporate_passengers AS
SELECT vw_entitys.org_id,  vw_entitys.org_name, vw_corporate_rates.rate_type_id, vw_corporate_rates.rate_plan_id, vw_corporate_rates.corporate_rate_category_name, vw_corporate_rates.corporate_rate_id,
 vw_corporate_rates.rate_plan_name, vw_corporate_rates.standard_rate, vw_corporate_rates.north_america_rate, passengers.days_from, passengers.days_to, passengers.approved,
 passengers.entity_id, passengers.countries, passengers.passenger_id, passengers.passenger_name, passengers.passenger_mobile, passengers.passenger_email,
 passengers.passenger_age, passengers.days_covered, passengers.nok_name, passengers.nok_mobile, passengers.passenger_id_no, passengers.passport_num,
 passengers.cover_amount, passengers.totalamount_covered, passengers.is_north_america, passengers.details, passengers.passenger_dob,
 passengers.policy_number, vw_entitys.entity_name, passengers.destown, sys_countrys.sys_country_name, passengers.approved_date, passengers.pin_no,
 passengers.reason_for_travel, passengers.departure_country, vw_entitys.function_role, vw_entitys.is_active,passengers.customer_code,passengers.customer_name,
 passengers.incountry
FROM passengers
  JOIN vw_corporate_rates ON passengers.corporate_rate_id = vw_corporate_rates.corporate_rate_id
  JOIN vw_entitys ON passengers.entity_id = vw_entitys.entity_id
  JOIN sys_countrys ON passengers.sys_country_id = sys_countrys.sys_country_id;



CREATE OR REPLACE VIEW vw_corporate_rate_plan AS
SELECT corporate_rate_plan.rate_plan_id, corporate_rate_plan.rate_plan_name
FROM corporate_rate_plan;

CREATE OR REPLACE VIEW vw_corporate_benefits AS
SELECT corporate_benefits.corporate_benefit_type_id,  corporate_benefit_types.corporate_benefit_type_name,
  corporate_benefits.rate_type_id,  corporate_rate_types.rate_type_name,  corporate_benefits.benefit_id,
  corporate_benefits.individual,  corporate_benefits.others, corporate_benefit_types.corporate_section
 FROM corporate_benefits
   JOIN corporate_benefit_types ON corporate_benefits.corporate_benefit_type_id = corporate_benefit_types.corporate_benefit_type_id
   JOIN corporate_rate_types ON corporate_benefits.rate_type_id = corporate_rate_types.rate_type_id;



	CREATE OR REPLACE VIEW vw_exchange_rates AS
	 SELECT currency.currency_id AS base_currency_id,  currency.currency_name AS base_currency_name,
	    currency.currency_symbol AS base_currency_symbol,  currency_rates.exchange_date, currency_rates.exchange_rate
	   FROM currency_rates
	     JOIN currency ON currency_rates.currency_id = currency.currency_id;
