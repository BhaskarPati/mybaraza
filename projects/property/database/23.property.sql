---Project Database File

---Property tables
CREATE TABLE property_types (
	property_type_id		serial primary key,
	org_id					integer references orgs,
	property_type_name		varchar(50),
	commercial_property		boolean not null default false,
	details					text
);
CREATE INDEX property_types_org_id ON property_types (org_id);

CREATE TABLE property (
	property_id				serial primary key,
	property_type_id		integer references property_types,
	entity_id				integer references entitys, --- property owner
	org_id					integer references orgs,
	property_name			varchar(50),
	estate					varchar(50),
	plot_no					varchar(50),
	is_active				boolean not null default true,
	units					integer,
	rental_value			float default 0 not null,
	service_fees			float default 0 not null,
	commision_value			float default 0 not null,
	commision_pct			float default 0 not null,
	details					text
);
CREATE INDEX property_property_type_id ON property (property_type_id);
CREATE INDEX property_entity_id ON property (entity_id);
CREATE INDEX property_org_id ON property (org_id);

ALTER TABLE transactions
ADD property_id				integer references property;
CREATE INDEX transactions_property_id ON transactions (property_id);

ALTER TABLE helpdesk
ADD property_id				integer references property;
CREATE INDEX helpdesk_property_id ON helpdesk(property_id);

---Property rentals table
CREATE TABLE rentals (
	rental_id				serial primary key,
	property_id				integer references property,
	entity_id				integer references entitys,		--- Tenant
	org_id					integer references orgs,
	start_rent				date,
	hse_no					varchar(10),
	elec_no					varchar(50),
	water_no				varchar(50),
	is_active				boolean not null default true,
	rental_value			float not null,
	service_fees			float not null,
	commision_value			float not null,
	commision_pct			float not null,
	deposit_fee				float,
	deposit_fee_date		date,
	deposit_refund			float,
	deposit_refund_date		date,
	details					text
);
CREATE INDEX rentals_property_id ON rentals (property_id);
CREATE INDEX rentals_entity_id ON rentals (entity_id);
CREATE INDEX rentals_org_id ON rentals (org_id);

---Function to count occupied units
CREATE OR REPLACE FUNCTION get_occupied(integer) RETURNS integer AS $$
    SELECT COALESCE(count(rental_id), 0)::integer
	FROM rentals
	WHERE (is_active = true) AND (property_id = $1);
$$ LANGUAGE SQL;

---Property period rentals 
CREATE TABLE period_rentals (
	period_rental_id		serial primary key,
	rental_id				integer references rentals,
	period_id				integer references periods,
	property_id				integer references property,
	entity_id				integer references entitys,		--- Tenant
	sys_audit_trail_id		integer references sys_audit_trail,
	org_id					integer references orgs,
	rental_amount			float not null,
	service_fees			float not null,
	repair_amount			float default 0 not null,
	commision				float not null,
	commision_pct			float not null,
	status					varchar(50) default 'Draft' not null,
	narrative				varchar(240)
);
CREATE INDEX period_rentals_rental_id ON period_rentals (rental_id);
CREATE INDEX period_rentals_period_id ON period_rentals (period_id);
CREATE INDEX period_rentals_property_id ON period_rentals (property_id);
CREATE INDEX period_rentals_entity_id ON period_rentals (entity_id);
CREATE INDEX period_rentals_sys_audit_trail_id ON period_rentals (sys_audit_trail_id);
CREATE INDEX period_rentals_org_id ON period_rentals (org_id);

CREATE TABLE log_period_rentals (
	log_period_rental_id	serial primary key,
	sys_audit_trail_id		integer references sys_audit_trail,
	period_rental_id		integer,
	rental_id				integer,
	period_id				integer,
	org_id					integer,
	rental_amount			float,
	service_fees			float,
	repair_amount			float,
	commision				float,
	commision_pct			float,
	status					varchar(50),
	narrative				varchar(240)
);
CREATE INDEX log_period_rentals_period_rental_id ON log_period_rentals (period_rental_id);
CREATE INDEX log_period_rentals_sys_audit_trail_id ON log_period_rentals (sys_audit_trail_id);

---Property,  Rentals and period rentals views 
CREATE VIEW vw_property AS
	SELECT entitys.entity_id as client_id, entitys.entity_name as client_name, 
		property_types.property_type_id, property_types.property_type_name,
		property.org_id, property.property_id, property.property_name, property.estate, 
		property.plot_no, property.is_active, property.units, property.rental_value, 
		property.service_fees, property.commision_value, property.commision_pct, property.details,
		get_occupied(property.property_id) as accupied,
		(property.units - get_occupied(property.property_id)) as vacant
	FROM property INNER JOIN entitys ON property.entity_id = entitys.entity_id
		INNER JOIN property_types ON property.property_type_id = property_types.property_type_id;

CREATE VIEW vw_rentals AS
	SELECT vw_property.client_id, vw_property.client_name, vw_property.property_type_id, vw_property.property_type_name,
		vw_property.property_id, vw_property.property_name, vw_property.estate, 
		vw_property.plot_no, vw_property.units,
		entitys.entity_id as tenant_id, entitys.entity_name as tenant_name,
		rentals.org_id, rentals.rental_id, rentals.start_rent, rentals.hse_no, rentals.elec_no, 
		rentals.water_no, rentals.is_active, rentals.rental_value, rentals.commision_value, 
		rentals.commision_pct, rentals.service_fees, rentals.deposit_fee, rentals.deposit_fee_date, 
		rentals.deposit_refund, rentals.deposit_refund_date, rentals.details
	FROM vw_property INNER JOIN rentals ON vw_property.property_id = rentals.property_id
		INNER JOIN entitys ON rentals.entity_id = entitys.entity_id;

CREATE VIEW vw_period_rentals AS
		SELECT vw_rentals.client_id, vw_rentals.client_name, vw_rentals.property_type_id, vw_rentals.property_type_name,
		vw_rentals.property_id, vw_rentals.property_name, vw_rentals.estate, 
		vw_rentals.plot_no, vw_rentals.units,
		vw_rentals.tenant_id, vw_rentals.tenant_name, 
		vw_rentals.rental_id, vw_rentals.start_rent, vw_rentals.hse_no, vw_rentals.elec_no, 
		vw_rentals.water_no, vw_rentals.is_active, vw_rentals.rental_value, 
		vw_rentals.deposit_fee, vw_rentals.deposit_fee_date, 
		vw_rentals.deposit_refund, vw_rentals.deposit_refund_date,

		vw_periods.fiscal_year_id, vw_periods.fiscal_year_start, vw_periods.fiscal_year_end,
		vw_periods.year_opened, vw_periods.year_closed,
		vw_periods.period_id, vw_periods.start_date, vw_periods.end_date, vw_periods.opened, vw_periods.closed, 
		vw_periods.month_id, vw_periods.period_year, vw_periods.period_month, vw_periods.quarter, vw_periods.semister,

		period_rentals.org_id, period_rentals.period_rental_id, period_rentals.rental_amount, period_rentals.service_fees,
		period_rentals.commision, period_rentals.commision_pct, period_rentals.repair_amount, period_rentals.narrative,period_rentals.status,
		(period_rentals.rental_amount - period_rentals.commision) as rent_to_remit,
		(period_rentals.rental_amount + period_rentals.service_fees + period_rentals.repair_amount) as rent_to_pay
	FROM vw_rentals INNER JOIN period_rentals ON vw_rentals.rental_id = period_rentals.rental_id
		INNER JOIN vw_periods ON period_rentals.period_id = vw_periods.period_id;


	
---FUNCTION to generate_rentals
CREATE OR REPLACE FUNCTION generate_rentals(varchar(12), varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	v_org_id			integer;
	v_period_id			integer;
	v_total_rent		float;
	myrec				RECORD;
	msg					varchar(120);
BEGIN
	IF ($3 = '1') THEN
	SELECT period_id INTO v_period_id FROM period_rentals WHERE period_id = $1::int AND rental_id = rental_id;
		IF(v_period_id is NULL) THEN
			INSERT INTO period_rentals (period_id, org_id, entity_id, property_id, rental_id, rental_amount, service_fees, commision, commision_pct, sys_audit_trail_id)
			SELECT $1::int, org_id, entity_id, property_id,rental_id, rental_value, service_fees, commision_value, commision_pct, $5::int
				FROM rentals 
				WHERE is_active = true;
			msg := 'Rentals generated';
		ELSE 
			msg := 'Rentals exists';
		END IF;		
	END IF;
	return msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ins_property() RETURNS trigger AS $$
BEGIN

	IF((NEW.commision_value = 0) AND (NEW.commision_pct > 0))THEN
		NEW.commision_value := NEW.rental_value * NEW.commision_pct / 100;
	END IF;
	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_property BEFORE INSERT OR UPDATE ON property
    FOR EACH ROW EXECUTE PROCEDURE ins_property();


CREATE OR REPLACE FUNCTION ins_rentals() RETURNS trigger AS $$
DECLARE
	rec					RECORD;
BEGIN
	SELECT rental_value, service_fees, commision_value, commision_pct INTO rec
	FROM property
	WHERE property_id = NEW.property_id;

	IF(NEW.rental_value is null)THEN
		NEW.rental_value := rec.rental_value;
	END IF;
	IF(NEW.service_fees is null)THEN
		NEW.service_fees := rec.service_fees;
	END IF;
	IF((NEW.commision_value is null) AND (NEW.commision_pct is null))THEN
		NEW.commision_value := rec.commision_value;
		NEW.commision_pct := rec.commision_pct;
	END IF;
	
	IF(NEW.commision_value is null)THEN NEW.commision_value := 0; END IF;
	IF(NEW.commision_pct is null)THEN NEW.commision_pct := 0; END IF;
	
	IF((NEW.commision_value = 0) AND (NEW.commision_pct > 0))THEN
		NEW.commision_value := NEW.rental_value * NEW.commision_pct / 100;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_rentals BEFORE INSERT OR UPDATE ON rentals
    FOR EACH ROW EXECUTE PROCEDURE ins_rentals();


CREATE OR REPLACE FUNCTION ins_period_rentals() RETURNS trigger AS $$
DECLARE
	rec					RECORD;
BEGIN
	SELECT rental_value, service_fees, commision_value, commision_pct INTO rec
	FROM rentals
	WHERE rental_id = NEW.rental_id;

	IF(NEW.rental_amount is null)THEN
		NEW.rental_amount := rec.rental_value;
	END IF;
	IF(NEW.service_fees is null)THEN
		NEW.service_fees := rec.service_fees;
	END IF;
	IF((NEW.commision is null) AND (NEW.commision_pct is null))THEN
		NEW.commision := rec.commision_value;
		NEW.commision_pct := rec.commision_pct;
	END IF;
	
	IF(NEW.commision is null)THEN NEW.commision := 0; END IF;
	IF(NEW.commision_pct is null)THEN NEW.commision_pct := 0; END IF;
	
	IF((NEW.commision = 0) AND (NEW.commision_pct > 0))THEN
		NEW.commision := NEW.rental_amount * NEW.commision_pct / 100;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_period_rentals BEFORE INSERT OR UPDATE ON period_rentals
    FOR EACH ROW EXECUTE PROCEDURE ins_period_rentals();
    
CREATE OR REPLACE FUNCTION aud_period_rentals() RETURNS trigger AS $$
BEGIN

	INSERT INTO log_period_rentals (period_rental_id, rental_id, period_id, 
		sys_audit_trail_id, org_id, rental_amount, service_fees,
		repair_amount, status, commision, commision_pct, narrative)
	VALUES (OLD.period_rental_id, OLD.rental_id, OLD.period_id, 
		OLD.sys_audit_trail_id, OLD.org_id, OLD.rental_amount, OLD.service_fees,
		OLD.repair_amount, OLD.status, OLD.commision, OLD.commision_pct, OLD.narrative);

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER aud_period_rentals AFTER UPDATE OR DELETE ON period_rentals
    FOR EACH ROW EXECUTE PROCEDURE aud_period_rentals();
	

CREATE OR REPLACE FUNCTION get_total_remit(float) RETURNS float AS $$
    SELECT COALESCE(SUM(rent_to_remit), 0)::float 
	FROM vw_period_rentals
	WHERE (is_active = true) AND (period_id = $1);
$$ LANGUAGE SQL;


CREATE OR REPLACE FUNCTION post_period_rentals(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
	DECLARE
		v_org_id			integer;
		v_use_key_id		integer;
		v_currency_id		integer;
		v_status			varchar(50);
		v_total_rent		float;
		v_total_remmit		float;
		myrec				RECORD;
		msg					varchar(120);
	BEGIN
		IF ($3::int = 2) THEN
			SELECT status INTO v_status FROM period_rentals WHERE period_rental_id = $1::int;
			IF (v_status = 'Draft') THEN
				SELECT currency_id INTO v_currency_id FROM orgs WHERE is_active = true;
				--RAISE EXCEPTION '%',$1;

				SELECT org_id,entity_id,property_id,rental_id,period_id,rental_amount,service_fees,
				repair_amount,commision,commision_pct,status,narrative,sys_audit_trail_id INTO myrec FROM period_rentals
				WHERE status = 'Draft' AND period_rental_id = $1::int;

				SELECT use_key_id INTO v_use_key_id FROM entitys WHERE is_active = true AND entity_id = myrec.entity_id;

				v_total_rent = myrec.rental_amount+myrec.service_fees+myrec.repair_amount;
				v_total_remmit= myrec.rental_amount-myrec.commision;

				---Debit all tenants rental accounts
					INSERT INTO payments (payment_type_id,org_id,entity_id,property_id,rental_id,period_id,currency_id,tx_type,account_credit,account_debit,activity_name)
					VALUES(5,myrec.org_id,myrec.entity_id,myrec.property_id,myrec.rental_id,myrec.period_id,v_currency_id,1,0,v_total_rent::float,'Peroid Rent');

					INSERT INTO payments (payment_type_id,org_id,entity_id,property_id,rental_id,period_id,currency_id,tx_type,account_credit,account_debit,activity_name)
					VALUES(5,myrec.org_id,myrec.entity_id,myrec.property_id,myrec.rental_id,myrec.period_id,v_currency_id,-1,v_total_remmit::float,0,'Peroid Rent');				
					
				UPDATE period_rentals SET status = 'Posted' WHERE period_rental_id = $1::int;
				msg := 'Period Rental Posted';
			ELSE
				msg := 'Period Rental Already Posted';
			END IF;
		END IF;
		return msg;
	END;
$$ LANGUAGE plpgsql;


