---Project Database Functions File

	
CREATE OR REPLACE FUNCTION aft_customers() RETURNS trigger AS $$
DECLARE
	v_entity_type_id		integer;
	v_entity_id				integer;
	v_user_name				varchar(32);
BEGIN

	IF((TG_OP = 'INSERT') AND (NEW.business_account = 0))THEN
		SELECT entity_type_id INTO v_entity_type_id
		FROM entity_types 
		WHERE (org_id = NEW.org_id) AND (use_key_id = 100);
		v_entity_id := nextval('entitys_entity_id_seq');
		v_user_name := 'OR' || NEW.org_id || 'EN' || v_entity_id;
		
		INSERT INTO entitys (entity_id, org_id, use_key_id, entity_type_id, customer_id, entity_name, user_name, primary_email, primary_telephone, function_role)
		VALUES (v_entity_id, NEW.org_id, 100, v_entity_type_id, NEW.customer_id, NEW.customer_name, v_user_name, lower(trim(NEW.client_email)), NEW.telephone_number, 'client');
	END IF;

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER aft_customers AFTER INSERT OR UPDATE ON customers
	FOR EACH ROW EXECUTE PROCEDURE aft_customers();

CREATE OR REPLACE FUNCTION ins_deposit_accounts() RETURNS trigger AS $$
DECLARE
	v_fee_amount		real;
	v_fee_ps			real;
	myrec				RECORD;
BEGIN

	IF(TG_OP = 'INSERT')THEN
		SELECT interest_rate, activity_frequency_id, min_opening_balance, lockin_period_frequency,
			minimum_balance, maximum_balance INTO myrec
		FROM products WHERE product_id = NEW.product_id;
	
		NEW.account_number := '4' || lpad(NEW.org_id::varchar, 2, '0')  || lpad(NEW.customer_id::varchar, 4, '0') || lpad(NEW.deposit_account_id::varchar, 2, '0');
		
		NEW.minimum_balance = myrec.minimum_balance;
		NEW.maximum_balance = myrec.maximum_balance;
	
		NEW.interest_rate = myrec.interest_rate;
		NEW.activity_frequency_id = myrec.activity_frequency_id;
		NEW.lockin_period_frequency = myrec.lockin_period_frequency;
	ELSE
		IF(NEW.approve_status = 'Approved')THEN
			INSERT INTO account_activity (deposit_account_id, activity_type_id, activity_frequency_id,
				activity_status_id, currency_id, entity_id, org_id, transfer_account_no,
				activity_date, value_date, account_debit)
			SELECT NEW.deposit_account_id, account_fees.activity_type_id, account_fees.activity_frequency_id,
				1, products.currency_id, NEW.entity_id, NEW.org_id, account_fees.account_number,
				current_date, current_date, account_fees.fee_amount
			FROM account_fees INNER JOIN activity_types ON account_fees.activity_type_id = activity_types.activity_type_id
				INNER JOIN products ON account_fees.product_id = products.product_id
			WHERE (account_fees.product_id = NEW.product_id) AND (account_fees.org_id = NEW.org_id)
				AND (account_fees.activity_frequency_id = 1) AND (activity_types.use_key_id = 201) 
				AND (account_fees.is_active = true) AND (account_fees.start_date < current_date);
		END IF;
	END IF;
	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_deposit_accounts BEFORE INSERT OR UPDATE ON deposit_accounts
	FOR EACH ROW EXECUTE PROCEDURE ins_deposit_accounts();


CREATE OR REPLACE FUNCTION ins_account_activity() RETURNS trigger AS $$
DECLARE
	v_deposit_account_id		integer;
	v_loan_id					integer;
BEGIN
	IF(NEW.link_activity_id is null)THEN
		NEW.link_activity_id := nextval('link_activity_id_seq');
	END IF;
	
	IF(NEW.transfer_account_no is not null)THEN
		SELECT deposit_account_id INTO v_deposit_account_id
		FROM deposit_accounts
		WHERE (account_number = NEW.transfer_account_no);
		
		IF(v_deposit_account_id is null)THEN
			SELECT loan_id INTO v_loan_id
			FROM loans
			WHERE (account_number = NEW.transfer_account_no);
		END IF;
		
		IF((v_deposit_account_id is null) AND (v_loan_id is null))THEN
			RAISE EXCEPTION 'Enter a valid account to do transfer';
		ELSIF(v_deposit_account_id is not null)THEN
			NEW.transfer_account_id := v_deposit_account_id;
		ELSIF(v_loan_id is not null)THEN
			NEW.transfer_loan_id := v_loan_id;
		END IF;
	END IF;
	
	IF(NEW.deposit_account_id is not null)THEN
		SELECT sum(account_credit - account_debit) INTO NEW.balance
		FROM account_activity
		WHERE (account_activity_id < NEW.account_activity_id)
			AND (deposit_account_id = NEW.deposit_account_id);
	END IF;
	IF(NEW.loan_id is not null)THEN
		SELECT sum(account_credit - account_debit) INTO NEW.balance
		FROM account_activity
		WHERE (account_activity_id < NEW.account_activity_id)
			AND (loan_id = NEW.loan_id);
	END IF;
	IF(NEW.balance is null)THEN
		NEW.balance := 0;
	END IF;
	NEW.balance := NEW.balance + (NEW.account_credit - NEW.account_debit);
	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_account_activity BEFORE INSERT OR UPDATE ON account_activity
	FOR EACH ROW EXECUTE PROCEDURE ins_account_activity();

CREATE OR REPLACE FUNCTION aft_account_activity() RETURNS trigger AS $$
DECLARE
	v_account_activity_id		integer;
	v_product_id				integer;
	v_use_key_id				integer;
	v_account_id				integer;
BEGIN

	IF(NEW.deposit_account_id is not null) THEN v_account_id := NEW.deposit_account_id; END IF;
	IF(NEW.loan_id is not null) THEN v_account_id := NEW.loan_id; END IF;

	IF(NEW.transfer_account_id is not null)THEN
		SELECT account_activity_id INTO v_account_activity_id
		FROM account_activity
		WHERE (deposit_account_id = NEW.transfer_account_id)
			AND (link_activity_id = NEW.link_activity_id);
			
		IF(v_account_activity_id is null)THEN
			INSERT INTO account_activity (deposit_account_id, transfer_account_id, activity_type_id,
				currency_id, org_id, link_activity_id, activity_date, value_date,
				activity_status_id, account_credit, account_debit, activity_frequency_id)
			VALUES (NEW.transfer_account_id, v_account_id, NEW.activity_type_id,
				NEW.currency_id, NEW.org_id, NEW.link_activity_id, NEW.activity_date, NEW.value_date,
				NEW.activity_status_id, NEW.account_debit, NEW.account_credit, 1);
		END IF;
	END IF;
	
	IF(NEW.transfer_loan_id is not null)THEN
		SELECT account_activity_id INTO v_account_activity_id
		FROM account_activity
		WHERE (loan_id = NEW.transfer_loan_id)
			AND (link_activity_id = NEW.link_activity_id);
			
		IF(v_account_activity_id is null)THEN
			INSERT INTO account_activity (loan_id, transfer_account_id, activity_type_id,
				currency_id, org_id, link_activity_id, activity_date, value_date,
				activity_status_id, account_credit, account_debit, activity_frequency_id)
			VALUES (NEW.transfer_loan_id, v_account_id, NEW.activity_type_id,
				NEW.currency_id, NEW.org_id, NEW.link_activity_id, NEW.activity_date, NEW.value_date,
				NEW.activity_status_id, NEW.account_debit, NEW.account_credit, 1);
		END IF;
	END IF;
	
	SELECT use_key_id INTO v_use_key_id
	FROM activity_types
	WHERE (activity_type_id = NEW.activity_type_id);

	IF(v_use_key_id < 200) AND (NEW.account_debit > 0)THEN
		--- Posting the charge on the transfer tranzaction
		SELECT product_id INTO v_product_id
		FROM deposit_accounts WHERE deposit_account_id = NEW.deposit_account_id;
		
		INSERT INTO account_activity (deposit_account_id, activity_type_id, activity_frequency_id,
			activity_status_id, currency_id, entity_id, org_id, transfer_account_no,
			link_activity_id, activity_date, value_date, account_debit)
		SELECT NEW.deposit_account_id, account_fees.activity_type_id, account_fees.activity_frequency_id,
			1, products.currency_id, NEW.entity_id, NEW.org_id, account_fees.account_number,
			NEW.link_activity_id, current_date, current_date, 
			(account_fees.fee_amount + account_fees.fee_ps * NEW.account_debit / 100)
		FROM account_fees INNER JOIN activity_types ON account_fees.activity_type_id = activity_types.activity_type_id
			INNER JOIN products ON account_fees.product_id = products.product_id
		WHERE (account_fees.product_id = v_product_id) AND (account_fees.org_id = NEW.org_id)
			AND (account_fees.activity_frequency_id = 1) AND (account_fees.use_key_id = v_use_key_id) 
			AND (account_fees.is_active = true) AND (account_fees.start_date < current_date);
	END IF;
	
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER aft_account_activity AFTER INSERT OR UPDATE ON account_activity
	FOR EACH ROW EXECUTE PROCEDURE aft_account_activity();
	
CREATE OR REPLACE FUNCTION apply_approval(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	msg							varchar(120);
BEGIN

	IF($3 = '1')THEN
		UPDATE customers SET approve_status = 'Completed' 
		WHERE (customer_id = $1::integer) AND (approve_status = 'Draft');

		msg := 'Applied for client approval';
	ELSIF($3 = '2')THEN
		UPDATE deposit_accounts SET approve_status = 'Completed' 
		WHERE (deposit_account_id = $1::integer) AND (approve_status = 'Draft');
		
		msg := 'Applied for account approval';
	ELSIF($3 = '3')THEN
		UPDATE loans SET approve_status = 'Completed' 
		WHERE (loan_id = $1::integer) AND (approve_status = 'Draft');
		
		msg := 'Applied for loan approval';
	ELSIF($3 = '4')THEN
		UPDATE guarantees SET approve_status = 'Completed' 
		WHERE (guarantee_id = $1::integer) AND (approve_status = 'Draft');
		
		msg := 'Applied for guarantees approval';
	ELSIF($3 = '5')THEN
		UPDATE collaterals SET approve_status = 'Completed' 
		WHERE (collateral_id = $1::integer) AND (approve_status = 'Draft');
		
		msg := 'Applied for collateral approval';
	END IF;

	RETURN msg;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION ins_loans() RETURNS trigger AS $$
DECLARE
	myrec			RECORD;
BEGIN

	IF(TG_OP = 'INSERT')THEN
		SELECT interest_rate, activity_frequency_id, min_opening_balance, lockin_period_frequency,
			minimum_balance, maximum_balance INTO myrec
		FROM products WHERE product_id = NEW.product_id;
	
		NEW.account_number := '5' || lpad(NEW.org_id::varchar, 2, '0')  || lpad(NEW.customer_id::varchar, 4, '0') || lpad(NEW.loan_id::varchar, 2, '0');
			
		NEW.interest_rate = myrec.interest_rate;
		NEW.activity_frequency_id = myrec.activity_frequency_id;
	END IF;
	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_loans BEFORE INSERT OR UPDATE ON loans
	FOR EACH ROW EXECUTE PROCEDURE ins_loans();
	