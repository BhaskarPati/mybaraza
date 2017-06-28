CREATE TABLE loan_types (
	loan_type_id			serial primary key,
	org_id					integer references orgs,
	loan_type_name			varchar(50) not null,
	default_interest		real,
	reducing_balance		boolean default true not null,
	penalty					real default  0 not null,
	details					text
);
CREATE INDEX loan_types_org_id ON loan_types (org_id);

CREATE TABLE loans (
	loan_id 				serial primary key,
	loan_type_id				integer not null references loan_types,
	bank_account_id			integer references bank_accounts,
	entity_id				integer not null references entitys,
	org_id					integer references orgs,
	
	ref_number				varchar(12),
	principle				real not null,
	interest				real not null,
	monthly_repayment			real not null,
	loan_date				date,
	initial_payment				real default 0 not null,
	reducing_balance			boolean default true not null,
	repayment_period			integer not null check (repayment_period > 0),
	
	application_date			timestamp default now(),
	approve_status				varchar(16) default 'Draft' not null,
	workflow_table_id			integer,
	action_date				timestamp,
	
	details					text
);

CREATE INDEX loans_bank_account_id ON loans (bank_account_id);
CREATE INDEX loans_loan_type_id ON loans (loan_type_id);
CREATE INDEX loans_entity_id ON loans (entity_id);
CREATE INDEX loans_org_id ON loans (org_id);

CREATE TABLE loan_monthly (
	loan_month_id 				serial primary key,
	loan_id					integer references loans,
	period_id				integer references periods,
	org_id					integer references orgs,
	interest_amount				real default 0 not null,
	repayment				real default 0 not null,
	interest_paid				real default 0 not null,
	penalty_paid				real default 0 not null,
	details					text,
	UNIQUE (loan_id, period_id)
);
CREATE INDEX loan_monthly_loan_id ON loan_monthly (loan_id);
CREATE INDEX loan_monthly_period_id ON loan_monthly (period_id);
CREATE INDEX loan_monthly_org_id ON loan_monthly (org_id);

CREATE OR REPLACE FUNCTION get_repayment(real, real, integer) RETURNS real AS $$
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

CREATE OR REPLACE FUNCTION get_loan_period(real, real, integer, real) RETURNS real AS $$
DECLARE
	loanbalance real;
	ri real;
BEGIN
	ri := 1 + ($2/1200);
	IF (ri = 1) THEN
		loanbalance := $1;
	ELSE
		loanbalance := $1 * (ri ^ $3) - ($4 * ((ri ^ $3)  - 1) / (ri - 1));
	END IF;
	RETURN loanbalance;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_payment_period(real, real, real) RETURNS real AS $$
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

CREATE OR REPLACE FUNCTION get_total_interest(integer) RETURNS real AS $$
	SELECT CASE WHEN sum(interest_amount) is null THEN 0 ELSE sum(interest_amount) END 
	FROM loan_monthly
	WHERE (loan_id = $1);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_total_interest(integer, date) RETURNS real AS $$
	SELECT CASE WHEN sum(interest_amount) is null THEN 0 ELSE sum(interest_amount) END 
	FROM loan_monthly INNER JOIN periods ON loan_monthly.period_id = periods.period_id
	WHERE (loan_monthly.loan_id = $1) AND (periods.start_date < $2);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_total_repayment(integer) RETURNS real AS $$
	SELECT CASE WHEN sum(repayment + interest_paid + penalty_paid) is null THEN 0 
		ELSE sum(repayment + interest_paid + penalty_paid) END
	FROM loan_monthly
	WHERE (loan_id = $1);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_intrest_repayment(integer, date) RETURNS real AS $$
	SELECT CASE WHEN sum(interest_paid) is null THEN 0 ELSE sum(interest_paid) END
	FROM loan_monthly INNER JOIN periods ON loan_monthly.period_id = periods.period_id
	WHERE (loan_monthly.loan_id = $1) AND (periods.start_date < $2);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_total_repayment(integer, date) RETURNS real AS $$
	SELECT CASE WHEN sum(repayment + interest_paid + penalty_paid) is null THEN 0 
		ELSE sum(repayment + interest_paid + penalty_paid) END
	FROM loan_monthly INNER JOIN periods ON loan_monthly.period_id = periods.period_id
	WHERE (loan_monthly.loan_id = $1) AND (periods.start_date < $2);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_penalty(integer, date) RETURNS real AS $$
	SELECT CASE WHEN sum(penalty_paid) is null THEN 0 ELSE sum(penalty_paid) END
	FROM loan_monthly INNER JOIN periods ON loan_monthly.period_id = periods.period_id
	WHERE (loan_monthly.loan_id = $1) AND (periods.start_date < $2);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_interest_amount(real)
  RETURNS real AS
$BODY$
DECLARE
	ri real;
BEGIN
	ri := 1 + ($1/1200);
RETURN ri;
END;
$BODY$
  LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_interest_amount(
    real,
    integer)
  RETURNS real AS
$BODY$
DECLARE
	ri real;
BEGIN
	ri :=($1 * $2)/1200;
RETURN ri;
END;
$BODY$
  LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_interest_amount(
    real,
    real,
    integer)
  RETURNS real AS
$BODY$
DECLARE
	ri real;
BEGIN
	ri :=(($1* $2 * $3)/1200);
RETURN ri;
END;
$BODY$
  LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_interest_amount(
    real,
    real,
    real)
  RETURNS real AS
$BODY$
DECLARE
	ri real;
BEGIN
	ri :=(($1* $2 * $3)/1200);
RETURN ri;
END;
$BODY$
  LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_total_repayment(
    real,
    real,
    integer)
  RETURNS real AS
$BODY$
DECLARE
	repayment real;
	ri real;
BEGIN
	ri := (($1* $2 * $3)/1200);
	repayment := $1 + (($1* $2 * $3)/1200);
	RETURN repayment;
END;
$BODY$
  LANGUAGE plpgsql;

CREATE VIEW vw_loan_types AS
	SELECT	currency.currency_id, currency.currency_name, currency.currency_symbol,
		loan_types.org_id, loan_types.loan_type_id, loan_types.loan_type_name, 
		loan_types.default_interest, loan_types.reducing_balance, loan_types.penalty, loan_types.details
	FROM loan_types 
		INNER JOIN currency ON loan_types.org_id = currency.org_id;


CREATE VIEW vw_loans AS
	SELECT 	vw_loan_types.currency_id, vw_loan_types.currency_name, vw_loan_types.currency_symbol,
		vw_loan_types.loan_type_id, vw_loan_types.loan_type_name, 
		entitys.entity_id, entitys.entity_name,
		loans.org_id, loans.loan_id, loans.principle, loans.interest, loans.monthly_repayment, loans.reducing_balance, 
		loans.repayment_period, loans.application_date, loans.approve_status, loans.initial_payment, 
		loans.loan_date, loans.action_date, loans.details,
		get_repayment(loans.principle, loans.interest, loans.repayment_period) as repayment_amount, 
		loans.initial_payment + get_total_repayment(loans.loan_id) as total_repayment, get_total_interest(loans.loan_id) as total_interest,
		(loans.principle + get_total_interest(loans.loan_id) - loans.initial_payment - get_total_repayment(loans.loan_id)) as loan_balance,
		get_payment_period(loans.principle, loans.monthly_repayment, loans.interest) as calc_repayment_period
	FROM loans INNER JOIN entitys ON loans.entity_id = entitys.entity_id
		INNER JOIN vw_loan_types ON loans.loan_type_id = vw_loan_types.loan_type_id;

CREATE VIEW vw_loan_monthly AS
	SELECT 	vw_loans.currency_id, vw_loans.currency_name, vw_loans.currency_symbol,
		vw_loans.loan_type_id, vw_loans.loan_type_name, 
		vw_loans.entity_id, vw_loans.entity_name, vw_loans.loan_date,
		vw_loans.loan_id, vw_loans.principle, vw_loans.interest, vw_loans.monthly_repayment, vw_loans.reducing_balance, 
		vw_loans.repayment_period, vw_periods.period_id, vw_periods.start_date, vw_periods.end_date, vw_periods.activated, vw_periods.closed,
		loan_monthly.org_id, loan_monthly.loan_month_id, loan_monthly.interest_amount, loan_monthly.repayment, loan_monthly.interest_paid, 
		loan_monthly.penalty_paid, loan_monthly.details,
		get_total_interest(vw_loans.loan_id, vw_periods.start_date) as total_interest,
		get_total_repayment(vw_loans.loan_id, vw_periods.start_date) as total_repayment,
		(vw_loans.principle + get_total_interest(vw_loans.loan_id, vw_periods.start_date + 1) + get_penalty(vw_loans.loan_id, vw_periods.start_date + 1)
		- vw_loans.initial_payment - get_total_repayment(vw_loans.loan_id, vw_periods.start_date + 1)) as loan_balance
	FROM loan_monthly INNER JOIN vw_loans ON loan_monthly.loan_id = vw_loans.loan_id
		INNER JOIN vw_periods ON loan_monthly.period_id = vw_periods.period_id;

CREATE VIEW vw_loan_payments AS
	SELECT	vw_loans.currency_id, vw_loans.currency_name, vw_loans.currency_symbol,
		vw_loans.loan_type_id, vw_loans.loan_type_name, 
		vw_loans.entity_id, vw_loans.entity_name,vw_loans.loan_date,
		vw_loans.loan_id, vw_loans.principle, vw_loans.interest, vw_loans.monthly_repayment, vw_loans.reducing_balance, 
		vw_loans.repayment_period, vw_loans.application_date, vw_loans.approve_status, vw_loans.initial_payment, 
		vw_loans.org_id, vw_loans.action_date,
		generate_series(1, repayment_period) as months,
		get_loan_period(principle, interest, generate_series(1, repayment_period), repayment_amount) as loan_balance, 
		(get_loan_period(principle, interest, generate_series(1, repayment_period) - 1, repayment_amount) * (interest/1200)) as loan_intrest 
	FROM vw_loans;

CREATE VIEW vw_period_loans AS
	SELECT vw_loan_monthly.org_id, vw_loan_monthly.period_id, 
		sum(vw_loan_monthly.interest_amount) as sum_interest_amount, sum(vw_loan_monthly.repayment) as sum_repayment, 
		 sum(vw_loan_monthly.penalty_paid) as sum_penalty_paid, 
		sum(vw_loan_monthly.interest_paid) as sum_interest_paid, sum(vw_loan_monthly.loan_balance) as sum_loan_balance
	FROM vw_loan_monthly
	GROUP BY vw_loan_monthly.org_id, vw_loan_monthly.period_id;
	
CREATE OR REPLACE FUNCTION get_total_repayment(integer, integer) RETURNS double precision AS $$
	SELECT sum(monthly_repayment + loan_intrest)
	FROM vw_loan_payments 
	WHERE (loan_id = $1) and (months <= $2);
$$ LANGUAGE SQL;
	
CREATE VIEW vw_loan_projection AS
	SELECT org_id, loan_id, loan_type_name, entity_name, principle, monthly_repayment, loan_date, 
		(EXTRACT(YEAR FROM age(current_date, '2010-05-01')) * 12) + EXTRACT(MONTH FROM age(current_date, loan_date)) as loan_months,
		get_total_repayment(loan_id, CAST((EXTRACT(YEAR FROM age(current_date, '2010-05-01')) * 12) + EXTRACT(MONTH FROM age(current_date, loan_date)) as integer)) as loan_paid
	FROM vw_loans;


CREATE OR REPLACE FUNCTION process_loans(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	rec					RECORD;
	v_exchange_rate		real;
	msg					varchar(120);
BEGIN
	
	FOR rec IN SELECT vw_loan_monthly.loan_month_id, vw_loan_monthly.loan_id, vw_loan_monthly.entity_id, vw_loan_monthly.period_id, 
		vw_loan_monthly.loan_balance, vw_loan_monthly.repayment, (vw_loan_monthly.interest_paid + vw_loan_monthly.penalty_paid) as total_interest
	FROM vw_loan_monthly
	WHERE (vw_loan_monthly.period_id = CAST($1 as int)) LOOP
	
		IF(rec.currency_id = rec.adj_currency_id)THEN
			v_exchange_rate := 1;
		ELSE
			v_exchange_rate := 1 / rec.exchange_rate;
		END IF;
	END LOOP;

	msg := 'Loan Processed';

	RETURN msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ins_loans() RETURNS trigger AS $$
BEGIN
	SELECT CAST (repayment_period AS FLOAT);
	IF(NEW.principle is null) OR (NEW.interest is null)THEN
		RAISE EXCEPTION 'You have to enter a principle and interest amount';
	ELSIF(NEW.monthly_repayment is null) AND (NEW.repayment_period is null)THEN
		RAISE EXCEPTION 'You have need to enter either monthly repayment amount or repayment period';
	ELSIF(NEW.monthly_repayment is null) AND (NEW.repayment_period is not null)THEN
		IF(NEW.repayment_period > 0)THEN
			NEW.monthly_repayment := NEW.principle / NEW.repayment_period;
		ELSE
			RAISE EXCEPTION 'The repayment period should be greater than 0';
		END IF;
	ELSIF(NEW.monthly_repayment is not null) AND (NEW.repayment_period is null)THEN
		IF(NEW.monthly_repayment > 0)THEN
			NEW.repayment_period := NEW.principle / NEW.monthly_repayment;
		ELSE
			RAISE EXCEPTION 'The monthly repayment should be greater than 0';
		END IF;
	END IF;
	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_loans BEFORE INSERT OR UPDATE ON loans
    FOR EACH ROW EXECUTE PROCEDURE ins_loans();


CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON loans
    FOR EACH ROW EXECUTE PROCEDURE upd_action();


CREATE OR REPLACE FUNCTION generate_repayment(
    character varying,
    character varying,
    character varying)
  RETURNS character varying AS
$BODY$
DECLARE
	rec			RECORD;
	recu			RECORD;
	reca			RECORD;
	v_penalty		real;
	v_org_id		integer;
	v_period_id		integer;
	v_month_name		varchar(20);
	vi_period_id		integer;
	v_loan_type_id		integer;
	v_loan_intrest		real;
	v_loan_id		integer;
	msg			varchar(120);
BEGIN
SELECT   period_id, org_id, to_char(start_date, 'Month YYYY') INTO v_period_id, v_org_id, v_month_name
	FROM periods
	WHERE (period_id = $1::integer);
SELECT loan_month_id, loan_id, period_id, org_id, interest_amount, repayment, interest_paid, penalty_paid INTO recu 
FROM loan_monthly WHERE period_id in (v_period_id) AND org_id in (v_org_id);

	IF( recu.period_id is null) THEN
	
		FOR rec IN SELECT org_id, loan_id, loan_type_id, monthly_repayment FROM loans WHERE (org_id = v_org_id) LOOP
		raise exception '%',rec.loan_id;	
		SELECT loan_intrest, loan_id INTO v_loan_intrest, v_loan_id FROM vw_loan_payments WHERE v_loan_id = rec.loan_id;
		recu.repayment = rec.monthly_repayment - v_loan_intrest;
			
	
		INSERT INTO loan_monthly (loan_id, period_id, org_id, interest_amount, repayment, interest_paid)
		VALUES(rec.loan_id, v_period_id, rec.org_id, v_loan_intrest, recu.repayment,  v_loan_intrest);
	END LOOP;
	

msg := 'Repayment Generated';
	END IF;

	return msg;
END;
$BODY$
  LANGUAGE plpgsql
