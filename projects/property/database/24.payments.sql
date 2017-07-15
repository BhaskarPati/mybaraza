DROP TABLE payments CASCADE;
DROP TABLE payment_types CASCADE;

CREATE TABLE payment_types (
	payment_type_id			serial primary key,
	account_id				integer not null references accounts,
	use_key_id				integer not null references use_keys,
	org_id					integer references orgs,
	payment_type_name		varchar(120) not null,
	is_active				boolean default true not null,
	details					text,
	UNIQUE(org_id, payment_type_name)
);
CREATE INDEX payment_types_account_id ON payment_types(account_id);
CREATE INDEX payment_types_use_key_id ON payment_types(use_key_id);
CREATE INDEX payment_types_org_id ON payment_types(org_id);

CREATE TABLE payments (
	payment_id				serial primary key,

	payment_type_id			integer references payment_types,
	currency_id				integer references currency,

	period_id				integer references periods,
	entity_id 				integer references entitys,
	property_id				integer references property,
	rental_id				integer references rentals,

	org_id					integer references orgs,
	journal_id				integer references journals,
	sys_audit_trail_id		integer references sys_audit_trail,

	payment_number			varchar(50),
	payment_date			date default current_date not null,
	tx_type					integer default 1 not null,

	account_credit			real default 0 not null,
	account_debit			real default 0 not null,
	balance					real not null,

	exchange_rate			real default 1 not null,
	activity_name 			varchar(50),
	action_date				timestamp,	
	
	details					text
);
CREATE INDEX payments_payment_type_id ON payments(payment_type_id);
CREATE INDEX payments_currency_id ON payments(currency_id);
CREATE INDEX payments_period_id ON payments(period_id);
CREATE INDEX payments_entity_id ON payments(entity_id);
CREATE INDEX payments_property_id ON payments(property_id);
CREATE INDEX payments_rental_id ON payments(rental_id);
CREATE INDEX payments_journal_id ON payments(journal_id);
CREATE INDEX payments_sys_audit_trail_id ON payments(sys_audit_trail_id);
CREATE INDEX payments_org_id ON payments(org_id);

---associative functions
CREATE OR REPLACE FUNCTION payment_number() 
  RETURNS trigger AS $$
DECLARE
	rnd 			integer;
	receipt_no  	varchar(12);
BEGIN
	receipt_no := trunc(random()*1000);
	rnd := trunc(65+random()*25);
	receipt_no := receipt_no || chr(rnd);
	receipt_no := receipt_no || trunc(random()*1000);
	rnd := trunc(65+random()*25);
	receipt_no := receipt_no || chr(rnd);
	rnd := trunc(65+random()*25);
	receipt_no := receipt_no || chr(rnd);

	NEW.payment_number:=receipt_no;
	---RAISE EXCEPTION '%',receipt_no;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

 CREATE TRIGGER payment_number BEFORE INSERT ON payments
 FOR EACH ROW
 EXECUTE PROCEDURE payment_number();


---Get balance trigger 
-- CREATE OR REPLACE FUNCTION ins_payments() RETURNS trigger AS $$
-- DECLARE
-- 	rec					RECORD;
-- BEGIN
	
-- 	IF(NEW.payments_id is not null AND NEW.tx_type = 1)THEN
-- 		SELECT sum(account_credit - account_debit) INTO NEW.balance
-- 		FROM payments
-- 		WHERE (payments_id < NEW.payments_id) AND (rental_id = NEW.rental_id);
-- 	ELSE
-- 		SELECT sum(account_debit - account_credit) INTO NEW.balance
-- 		FROM payments
-- 		WHERE (payments_id < NEW.payments_id) AND (rental_id = NEW.rental_id);
-- 	END IF;

-- 	IF(NEW.balance is null)THEN
-- 		NEW.balance := 0;
-- 	END IF;

-- 	IF(NEW.payments_id is not null AND NEW.tx_type = 1)THEN
-- 		NEW.balance := NEW.balance + (NEW.account_credit - NEW.account_debit);
-- 	ELSE
-- 		NEW.balance := NEW.balance + (NEW.account_debit - NEW.account_credit);
-- 	END IF
	
-- 	RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;

-- CREATE TRIGGER ins_payments BEFORE INSERT OR UPDATE ON payments
--     FOR EACH ROW EXECUTE PROCEDURE ins_payments();

CREATE OR REPLACE FUNCTION ins_payments() RETURNS trigger AS $$
DECLARE
	rec					RECORD;
BEGIN
	
	IF(NEW.payment_id is not null AND NEW.tx_type = 1)THEN
		SELECT sum(account_credit - account_debit) INTO NEW.balance
		FROM payments
		WHERE (payment_id < NEW.payment_id) AND (rental_id = NEW.rental_id);
	ELSE
		SELECT sum(account_debit - account_credit) INTO NEW.balance
		FROM payments
		WHERE (payment_id < NEW.payment_id) AND (rental_id = NEW.rental_id);
	END IF;

	IF(NEW.balance is null)THEN
		NEW.balance := 0;
	END IF;

	IF(NEW.payment_id is not null AND NEW.tx_type = 1)THEN
		NEW.balance := NEW.balance + (NEW.account_credit - NEW.account_debit);
	ELSE
		NEW.balance := NEW.balance + (NEW.account_debit - NEW.account_credit);
	END IF;
	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_payments BEFORE INSERT OR UPDATE ON payments
    FOR EACH ROW EXECUTE PROCEDURE ins_payments();