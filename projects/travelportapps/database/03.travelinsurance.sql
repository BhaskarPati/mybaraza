---Project Database File

ALTER TABLE orgs ADD credit_limit real not null default 0;


CREATE TABLE city_codes (
	city_code				char(3) primary key,
	city_name				varchar(100),
	country					varchar(100),
	sys_country_id			char(2) references sys_countrys
);

CREATE TABLE rate_types (
	rate_type_id			serial primary key,
	rate_type_name			varchar(100),
	age_limit				integer default 70,
	details					text
);

CREATE TABLE benefit_types (
	benefit_type_id			serial primary key,
	benefit_type_name		varchar(100),
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

CREATE TABLE rates (
	rate_id					serial primary key,
	rate_type_id			integer references rate_types,
	days_from				integer,
	days_to					integer,
	standard_rate			real,
	north_america_rate		real
);
CREATE INDEX rates_rate_type_id ON rates(rate_type_id);

CREATE TABLE passengers (
	passenger_id			serial primary key,
	rate_id					integer references rates,
	entity_id				integer references entitys,
	org_id					integer references orgs,
	passenger_name			varchar(100),
	passenger_mobile		varchar(15),
	passenger_email			varchar(100),
	passenger_age			integer default 0,
	days_covered			integer,
	nok_name				varchar(100),
	nok_mobile				varchar(15),
	nok_national_id			varchar(20),
	
	is_north_america		boolean default false,

	cover_amount			real,
	approved				boolean default false,
	
	details					text
);
CREATE INDEX passengers_rate_id ON passengers(rate_id);
CREATE INDEX passengers_org_id ON passengers(org_id);


CREATE TABLE payment_types (
	payment_type_id			serial primary key,
	payment_type_name		varchar(100),
	details					text
);

CREATE TABLE payments (
	payment_id				serial primary key,
	payment_type_id			integer references payment_types,
	org_id					integer references orgs,
	
	payment_amount			real,
	transaction_reference	varchar(100),
	payment_date			date,
	
	approved				boolean default false,
	details					text
); 
CREATE INDEX payments_org_id ON payments(org_id);


CREATE VIEW vw_benefits AS
	SELECT benefit_types.benefit_type_id, benefit_types.benefit_type_name, 
		rate_types.rate_type_id, rate_types.rate_type_name, 
		benefits.benefit_id, benefits.individual, benefits.others
	FROM benefits INNER JOIN benefit_types ON benefits.benefit_type_id = benefit_types.benefit_type_id
		INNER JOIN rate_types ON benefits.rate_type_id = rate_types.rate_type_id;
	
CREATE VIEW vw_rates AS
	SELECT rate_types.rate_type_id, rate_types.rate_type_name, 
		rates.rate_id, rates.days_from, rates.days_to, rates.standard_rate, rates.north_america_rate
	FROM rates INNER JOIN rate_types ON rates.rate_type_id = rate_types.rate_type_id;

CREATE VIEW vw_passengers AS
	SELECT orgs.org_id, orgs.org_name, 
		vw_rates.rate_type_id, vw_rates.rate_type_name, 
		vw_rates.rate_id, vw_rates.days_from, vw_rates.days_to, vw_rates.standard_rate, vw_rates.north_america_rate,
		passengers.entity_id,
		passengers.passenger_id, passengers.passenger_name, passengers.passenger_mobile, 
		passengers.passenger_email, passengers.passenger_age, passengers.days_covered, passengers.nok_name, 
		passengers.nok_mobile, passengers.nok_national_id, passengers.cover_amount, 
		passengers.is_north_america, passengers.details
	FROM passengers INNER JOIN orgs ON passengers.org_id = orgs.org_id
		INNER JOIN vw_rates ON passengers.rate_id = vw_rates.rate_id;

CREATE VIEW vw_payments AS
	SELECT orgs.org_id, orgs.org_name, 
		payment_types.payment_type_id, payment_types.payment_type_name, 
		payments.payment_id, payments.payment_amount, payments.transaction_reference, 
		payments.payment_date, payments.approved, payments.details
	FROM payments
	INNER JOIN orgs ON payments.org_id = orgs.org_id
	INNER JOIN payment_types ON payments.payment_type_id = payment_types.payment_type_id;

CREATE OR REPLACE FUNCTION upd_passengers() RETURNS trigger AS $$
DECLARE

BEGIN
	IF(NEW.approved = true) THEN
		NEW.approved_date = CURRENT_TIMESTAMP; 
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER upd_passengers BEFORE UPDATE ON passengers 
	FOR EACH ROW EXECUTE PROCEDURE upd_passengers();







