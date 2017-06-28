CREATE TABLE borrowing_types (
	borrowing_type_id			serial primary key,
	org_id           	        integer references orgs,

	borrowing_type_name         varchar (120) ,
	default_interest		real,
	reducing_balance		boolean default true not null,

	details						text
);

CREATE INDEX borrowing_types_org_id ON borrowing_types (org_id);


CREATE TABLE borrowing (
	borrowing_id            	serial primary key,
    borrowing_type_id			integer references borrowing_types, 
    currency_id             	integer references currency,
    org_id                  	integer references orgs,
    bank_account_id 			integer references bank_accounts,
	
	principle					real not null,
	interest					real not null,
	monthly_repayment			real,
	borrowing_date				date,
	initial_payment				real default 0 not null,
	reducing_balance			boolean default true not null,
	repayment_period			integer not null check (repayment_period > 0),
	
	application_date			timestamp default now(),
	approve_status				varchar(16) default 'Draft' not null,
	workflow_table_id			integer,
	action_date					timestamp,
	details                     text
);


CREATE INDEX borrowing_bank_account_id ON borrowing (bank_account_id);
CREATE INDEX borrowing_borrowing_type_id ON borrowing (borrowing_type_id);
CREATE INDEX borrowing_currency_id ON borrowing (currency_id);
CREATE INDEX borrowing_org_id ON borrowing (org_id);

CREATE TABLE borrowing_repayment (
	borrowing_repayment_id		serial primary key,
	org_id                      integer references orgs,
	borrowing_id                integer references borrowing,
	period_id					integer references periods,
	
	interest_amount				real default 0 not null,
	repayment				real default 0 not null,
	interest_paid				real default 0 not null,
	
	penalty_paid				real default 0 not null,
	details                     text
);

CREATE INDEX borrowing_repayment_org_id ON borrowing_repayment(org_id);
CREATE INDEX borrowing_repayment_borrowing_id ON borrowing_repayment (borrowing_id);
CREATE INDEX borrowing_repayment_period_id ON borrowing_repayment (period_id);


CREATE OR REPLACE FUNCTION get_borrowing_repayment(real, real, integer) RETURNS real AS $$
DECLARE
	repayment real;
	ri real;
BEGIN
	ri := 1 + ($2/1200);
	IF ((ri ^ $3) = 1) THEN
		repayment := $1;
	ELSE
		repayment := $1 * (ri ^ $3) * (ri - 1) / ((ri ^ $3) - 1);
	END IF;
	RETURN repayment;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_borrowing_period(real, real, integer, real) RETURNS real AS $$
DECLARE
	borrowing_balance real;
	ri real;
BEGIN
	ri := 1 + ($2/1200);
	IF (ri = 1) THEN
		borrowing_balance := $1;
	ELSE
		borrowing_balance := $1 * (ri ^ $3) - ($4 * ((ri ^ $3)  - 1) / (ri - 1));
	END IF;
	RETURN borrowing_balance;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_bpayment_period(real, real, real) RETURNS real AS $$
DECLARE
	paymentperiod real;
	q real;
BEGIN
	q := $3/1200;
	
	IF ($2 = 0) OR (q = -1) OR ((q * $1) >= $2) THEN
		paymentperiod := 1;
	ELSIF (log(q + 1) = 0) THEN
		paymentperiod := 1;
	ELSE
		paymentperiod := (log($2) - log($2 - (q * $1))) / log(q + 1);
	END IF;

	RETURN paymentperiod;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_total_binterest(integer) RETURNS real AS $$
	SELECT CASE WHEN sum(interest_amount) is null THEN 0 ELSE sum(interest_amount) END 
	FROM borrowing_repayment
	WHERE (borrowing_id = $1);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_total_binterest(integer, date) RETURNS real AS $$
	SELECT CASE WHEN sum(interest_amount) is null THEN 0 ELSE sum(interest_amount) END 
	FROM borrowing_repayment INNER JOIN periods ON borrowing_repayment.period_id = periods.period_id
	WHERE (borrowing_repayment.borrowing_id = $1) AND (periods.start_date < $2);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_total_brepayment(integer) RETURNS real AS $$
	SELECT CASE WHEN sum(repayment + interest_paid + penalty_paid) is null THEN 0 
		ELSE sum(repayment + interest_paid + penalty_paid) END
	FROM borrowing_repayment
	WHERE (borrowing_id = $1);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_interest_brepayment(integer, date) RETURNS real AS $$
	SELECT CASE WHEN sum(interest_paid) is null THEN 0 ELSE sum(interest_paid) END
	FROM borrowing_repayment INNER JOIN periods ON borrowing_repayment.period_id = periods.period_id
	WHERE (borrowing_repayment.borrowing_id = $1) AND (periods.start_date < $2);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_total_brepayment(integer, date) RETURNS real AS $$
	SELECT CASE WHEN sum(repayment + interest_paid + penalty_paid) is null THEN 0 
		ELSE sum(repayment + interest_paid + penalty_paid) END
	FROM borrowing_repayment INNER JOIN periods ON borrowing_repayment.period_id = periods.period_id
	WHERE (borrowing_repayment.borrowing_id = $1) AND (periods.start_date < $2);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_bpenalty(integer, date) RETURNS real AS $$
	SELECT CASE WHEN sum(penalty_paid) is null THEN 0 ELSE sum(penalty_paid) END
	FROM borrowing_repayment INNER JOIN periods ON borrowing_repayment.period_id = periods.period_id
	WHERE (borrowing_repayment.borrowing_id = $1) AND (periods.start_date < $2);
$$ LANGUAGE SQL;


CREATE VIEW vw_borrowing_types AS
	SELECT borrowing_types.org_id, borrowing_types.borrowing_type_id, borrowing_types.borrowing_type_name, borrowing_types.details
	FROM borrowing_types;


CREATE OR REPLACE VIEW vw_borrowing AS
	SELECT  borrowing_types.borrowing_type_id, borrowing_types.borrowing_type_name, 
	 bank_accounts.bank_account_id, bank_accounts.bank_account_name,
	currency.currency_id, currency.currency_name, currency.currency_symbol,
	 borrowing.org_id, borrowing.borrowing_id,  borrowing.principle,
	 borrowing.interest, borrowing.monthly_repayment, borrowing.reducing_balance, 
		borrowing.repayment_period, borrowing.initial_payment, borrowing.borrowing_date, 
		borrowing.application_date, borrowing.approve_status, borrowing.workflow_table_id, borrowing.action_date,   borrowing.details,
		get_borrowing_repayment(borrowing.principle, borrowing.interest, borrowing.repayment_period) as repayment_amount, 
		  borrowing.initial_payment + get_total_brepayment(borrowing.borrowing_id) as total_repayment, get_total_binterest(borrowing.borrowing_id) as total_interest,
		(borrowing.principle + get_total_binterest(borrowing.borrowing_id) - borrowing.initial_payment - get_total_brepayment(borrowing.borrowing_id)) as borrowing_balance,
		get_bpayment_period(borrowing.principle, borrowing.monthly_repayment, borrowing.interest) as calc_repayment_period
	FROM borrowing
		JOIN bank_accounts ON borrowing.bank_account_id = bank_accounts.bank_account_id
		JOIN borrowing_types ON borrowing.borrowing_type_id = borrowing_types.borrowing_type_id
		JOIN currency ON borrowing.currency_id = currency.currency_id;
	
CREATE OR REPLACE VIEW vw_borrowing_mrepayment AS
		SELECT vw_borrowing.currency_id, vw_borrowing.currency_name, vw_borrowing.currency_symbol,
		vw_borrowing.borrowing_type_id, vw_borrowing.borrowing_type_name, 
		vw_borrowing.borrowing_date, vw_borrowing.borrowing_id, vw_borrowing.principle, vw_borrowing.interest, vw_borrowing.monthly_repayment, vw_borrowing.reducing_balance, vw_borrowing.repayment_period, 
		vw_periods.period_id, vw_periods.start_date, vw_periods.end_date, vw_periods.activated, vw_periods.closed,
		borrowing_repayment.org_id, borrowing_repayment.borrowing_repayment_id,  borrowing_repayment.interest_amount, 
		borrowing_repayment.repayment, borrowing_repayment.interest_paid, borrowing_repayment.penalty_paid, borrowing_repayment.details, get_total_binterest(vw_borrowing.borrowing_id, vw_periods.start_date) as total_interest, 
		get_total_brepayment(vw_borrowing.borrowing_id, vw_periods.start_date) as total_repayment,
		(vw_borrowing.principle + get_total_binterest(vw_borrowing.borrowing_id, vw_periods.start_date + 1) + get_bpenalty(vw_borrowing.borrowing_id, vw_periods.start_date + 1)
		- vw_borrowing.initial_payment - get_total_brepayment(vw_borrowing.borrowing_id, vw_periods.start_date + 1)) as borrowing_balance
	FROM borrowing_repayment INNER JOIN vw_borrowing ON borrowing_repayment.borrowing_id = vw_borrowing.borrowing_id
		INNER JOIN vw_periods ON borrowing_repayment.period_id = vw_periods.period_id;

CREATE VIEW vw_borrowing_payments AS
	SELECT vw_borrowing.currency_id, vw_borrowing.currency_name, vw_borrowing.currency_symbol,
		vw_borrowing.borrowing_type_id, vw_borrowing.borrowing_type_name, 
		vw_borrowing.borrowing_date, vw_borrowing.borrowing_id, vw_borrowing.principle, vw_borrowing.interest, vw_borrowing.monthly_repayment, vw_borrowing.reducing_balance, 
		vw_borrowing.repayment_period, vw_borrowing.application_date, vw_borrowing.approve_status, vw_borrowing.initial_payment, 
		vw_borrowing.org_id, vw_borrowing.action_date,
		generate_series(1, repayment_period) as months,
		get_borrowing_period(principle, interest, generate_series(1, repayment_period), repayment_amount) as borrowing_balance, 
		(get_borrowing_period(principle, interest, generate_series(1, repayment_period) - 1, repayment_amount) * (interest/1200)) as borrowing_interest 
	FROM vw_borrowing;

CREATE VIEW vw_period_borrowing AS
	SELECT vw_borrowing_mrepayment.org_id, vw_borrowing_mrepayment.period_id, 
		sum(vw_borrowing_mrepayment.interest_amount) as sum_interest_amount, sum(vw_borrowing_mrepayment.repayment) as sum_repayment, 
		sum(vw_borrowing_mrepayment.penalty_paid) as sum_penalty_paid, 
		sum(vw_borrowing_mrepayment.interest_paid) as sum_interest_paid, sum(vw_borrowing_mrepayment.borrowing_balance) as sum_borrowing_balance
	FROM vw_borrowing_mrepayment
	GROUP BY vw_borrowing_mrepayment.org_id, vw_borrowing_mrepayment.period_id;


CREATE OR REPLACE FUNCTION get_total_brepayment(integer, integer) RETURNS double precision AS $$
	SELECT sum(monthly_repayment + borrowing_interest)
	FROM vw_borrowing_payments
	WHERE (borrowing_id = $1) and (months <= $2);
$$ LANGUAGE SQL;


CREATE VIEW vw_borrowing_projection AS
	SELECT org_id, borrowing_id, borrowing_type_name, principle, monthly_repayment, borrowing_date, 
		(EXTRACT(YEAR FROM age(current_date, '2010-05-01')) * 12) + EXTRACT(MONTH FROM age(current_date, borrowing_date)) as borrowing_months,
		get_total_brepayment(borrowing_id, CAST((EXTRACT(YEAR FROM age(current_date, '2010-05-01')) * 12) + EXTRACT(MONTH FROM age(current_date, borrowing_date)) as integer)) as borrowing_paid
	FROM vw_borrowing;

CREATE OR REPLACE FUNCTION ins_borrowing() RETURNS trigger AS $$
DECLARE
	v_default_interest	real;
	v_reducing_balance	boolean;
BEGIN

	SELECT default_interest, reducing_balance INTO v_default_interest, v_reducing_balance
	FROM borrowing_types 
	WHERE (borrowing_type_id = NEW.borrowing_type_id);
		
	IF(NEW.interest is null)THEN
		NEW.interest := v_default_interest;
	END IF;
	IF (NEW.reducing_balance is null)THEN
		NEW.reducing_balance := v_reducing_balance;
	END IF;
	IF(NEW.monthly_repayment is null) THEN
		NEW.monthly_repayment := 0;
	END IF;
	IF (NEW.repayment_period is null)THEN
		NEW.repayment_period := 0;
	END IF;
	IF(NEW.approve_status = 'Draft')THEN
		NEW.repayment_period := 0;
	END IF;
	SELECT CAST (repayment_period AS FLOAT);
	IF(NEW.principle is null)THEN
		RAISE EXCEPTION 'You have to enter a principle amount';
	ELSIF((NEW.monthly_repayment = 0) AND (NEW.repayment_period = 0))THEN
		RAISE EXCEPTION 'You have need to enter either monthly repayment amount or repayment period';
	ELSIF((NEW.monthly_repayment = 0) AND (NEW.repayment_period < 1))THEN
		RAISE EXCEPTION 'The repayment period should be greater than 0';
	ELSIF((NEW.repayment_period = 0) AND (NEW.monthly_repayment < 1))THEN
		RAISE EXCEPTION 'The monthly repayment should be greater than 0';
	ELSIF((NEW.monthly_repayment = 0) AND (NEW.repayment_period > 0))THEN
		NEW.monthly_repayment := NEW.principle / NEW.repayment_period;
	ELSIF((NEW.repayment_period = 0) AND (NEW.monthly_repayment > 0))THEN
		NEW.repayment_period := NEW.principle / NEW.monthly_repayment;
	END IF;
	
	IF(NEW.monthly_repayment > NEW.principle)THEN
		RAISE EXCEPTION 'Repayment should be less than the principal amount';
	END IF;
	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_borrowing BEFORE INSERT OR UPDATE ON borrowing
    FOR EACH ROW EXECUTE PROCEDURE ins_borrowing();


CREATE OR REPLACE FUNCTION borrowing_aplication(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	msg 				varchar(120);
BEGIN
	msg := 'borrowing applied';
	
	UPDATE borrowing SET approve_status = 'Completed'
	WHERE (borrowing_id = CAST($1 as int)) AND (approve_status = 'Draft');

	return msg;
END;
$$ LANGUAGE plpgsql;
    

CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON borrowing
    FOR EACH ROW EXECUTE PROCEDURE upd_action();
    
CREATE OR REPLACE FUNCTION get_borrowing_repayment(
    real,
    real,
    real)
  RETURNS real AS
$BODY$
DECLARE
    repayment real;
    ri real;
BEGIN
    ri := 1 + ($2/1200);
    IF ((ri ^ $3) = 1) THEN
        repayment := $1;
    ELSE
        repayment := $1 * (ri ^ $3) * (ri - 1) / ((ri ^ $3) - 1);
    END IF;
    RETURN repayment;
END;
$BODY$
  LANGUAGE plpgsql; 
