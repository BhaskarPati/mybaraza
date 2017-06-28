CREATE TABLE loan_types (
	loan_type_id			serial primary key,
	org_id					integer references orgs,
	loan_type_name			varchar(50) not null,
	default_interest		real,
	reducing_balance		boolean default true not null,
	details					text
);
CREATE INDEX loan_types_org_id ON loan_types (org_id);

CREATE TABLE loans (
	loan_id 				serial primary key,
	loan_type_id			integer not null references loan_types,
	entity_id				integer not null references entitys,
	entity_name 			varchar(120),
	org_id					integer references orgs,
	principle				real not null,
	interest				real not null,
	monthly_repayment		real not null,
	loan_date				date,
	initial_payment			real default 0 not null,
	reducing_balance		boolean default true not null,
	repayment_period		integer not null check (repayment_period > 0),
	journal_id				integer references journals,
	
	application_date		timestamp default now(),
	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	action_date				timestamp,
	
	is_closed				boolean default false,
	details					text
);
CREATE INDEX loans_journal_id ON loans (journal_id);
CREATE INDEX loans_loan_type_id ON loans (loan_type_id);
CREATE INDEX loans_entity_id ON loans (entity_id);
CREATE INDEX loans_org_id ON loans (org_id);

CREATE TABLE loan_monthly (
	loan_month_id 			serial primary key,
	loan_id					integer references loans,
	period_id				integer references periods,
	org_id					integer references orgs,

	penalty					real default 0 not null,
	penalty_paid			real default 0 not null,
	
	interest_amount			real default 0 not null,
	interest_paid			real default 0 not null,
	
	repayment				real default 0 not null,
	repayment_paid			real default 0 not null,
	
	additional_payments		real default 0 not null,

	is_paid      			boolean default false,
	details					text,
	UNIQUE (loan_id, period_id)
);
CREATE INDEX loan_monthly_loan_id ON loan_monthly (loan_id);
CREATE INDEX loan_monthly_period_id ON loan_monthly (period_id);
CREATE INDEX loan_monthly_org_id ON loan_monthly (org_id);

CREATE TABLE collateral_types (
  collateral_type_id 		serial primary key,
  org_id					integer references orgs,
  collateral_type_name		varchar(120),
  details 					text
);
CREATE INDEX collateral_types_org_id ON collateral_types (org_id);

CREATE TABLE collateral (
	collateral_id			serial primary key,
	loan_id					integer references loans,
	collateral_type_id		integer references collateral_types,
	org_id					integer references orgs,
	reference_number		varchar(50),
	collateral_amount		real,
	narrative 				text	
);
CREATE INDEX collateral_loan_id ON collateral (loan_id);
CREATE INDEX collateral_collateral_type on collateral (collateral_type_id);
CREATE INDEX collateral_org_id ON collateral (org_id);

CREATE TABLE gurrantors (
	gurrantor_id			serial primary key,
	entity_id				integer references entitys,
	loan_id					integer references loans,
	org_id					integer references orgs,
	is_accepted				boolean default false,
	is_approved				boolean default false,
	amount					real not null default 0,
	details					text
);
CREATE INDEX gurrantors_entity_id ON gurrantors (entity_id);
CREATE INDEX gurrantors_loan_id ON gurrantors (loan_id);
CREATE INDEX gurrantors_org_id ON gurrantors (org_id);

--here
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
	SELECT CASE WHEN sum(repayment_paid + interest_paid + penalty_paid) is null THEN 0 
		ELSE sum(repayment_paid + interest_paid + penalty_paid) END
	FROM loan_monthly
	WHERE (loan_id = $1);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_intrest_repayment(integer, date) RETURNS real AS $$
	SELECT CASE WHEN sum(interest_paid) is null THEN 0 ELSE sum(interest_paid) END
	FROM loan_monthly INNER JOIN periods ON loan_monthly.period_id = periods.period_id
	WHERE (loan_monthly.loan_id = $1) AND (periods.start_date < $2);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_total_repayment(integer, date) RETURNS real AS $$
	SELECT CASE WHEN sum(repayment_paid + interest_paid + penalty_paid) is null THEN 0 
		ELSE sum(repayment_paid + interest_paid + penalty_paid) END
	FROM loan_monthly INNER JOIN periods ON loan_monthly.period_id = periods.period_id
	WHERE (loan_monthly.loan_id = $1) AND (periods.start_date < $2);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_penalty(integer, date) RETURNS real AS $$
	SELECT CASE WHEN sum(penalty) is null THEN 0 ELSE sum(penalty) END
	FROM loan_monthly INNER JOIN periods ON loan_monthly.period_id = periods.period_id
	WHERE (loan_monthly.loan_id = $1) AND (periods.start_date < $2);
$$ LANGUAGE SQL;

CREATE VIEW vw_loan_types AS
	SELECT	currency.currency_id, currency.currency_name, currency.currency_symbol,
		loan_types.org_id, loan_types.loan_type_id, loan_types.loan_type_name, 
		loan_types.default_interest, loan_types.reducing_balance, loan_types.details
	FROM loan_types 
		INNER JOIN currency ON loan_types.org_id = currency.org_id;

CREATE OR REPLACE VIEW vw_loans AS 
	SELECT vw_loan_types.currency_id, vw_loan_types.currency_name, vw_loan_types.currency_symbol,
		vw_loan_types.loan_type_id, vw_loan_types.loan_type_name, 
		loans.entity_id, loans.org_id, loans.loan_id, loans.principle, loans.interest, loans.monthly_repayment, loans.reducing_balance, 
		loans.repayment_period, loans.initial_payment, loans.loan_date, 
		loans.application_date, loans.approve_status, loans.workflow_table_id, loans.action_date, 
		loans.details, entitys.entity_name ,
		get_repayment(loans.principle, loans.interest, loans.repayment_period) as repayment_amount, 
		loans.initial_payment + get_total_repayment(loans.loan_id) as total_repayment, get_total_interest(loans.loan_id) as total_interest,
		(loans.principle + get_total_interest(loans.loan_id) - loans.initial_payment - get_total_repayment(loans.loan_id)) as loan_balance,
		get_payment_period(loans.principle, loans.monthly_repayment, loans.interest) as calc_repayment_period
	FROM loans
		INNER JOIN entitys ON loans.entity_id = entitys.entity_id
		INNER JOIN vw_loan_types ON loans.loan_type_id = vw_loan_types.loan_type_id;
		
		
		
CREATE VIEW vw_loan_monthly AS
	SELECT 	vw_loans.currency_id, vw_loans.currency_name, vw_loans.currency_symbol,
		vw_loans.loan_type_id, vw_loans.loan_type_name,vw_loans.approve_status,

		vw_loans.entity_id,  members.expired, vw_loans.loan_date,vw_loans.entity_name,
		vw_loans.loan_id, vw_loans.principle, vw_loans.interest, vw_loans.monthly_repayment, vw_loans.reducing_balance, 
		vw_loans.repayment_period, vw_periods.period_id, vw_periods.start_date, vw_periods.end_date, vw_periods.activated, vw_periods.closed, vw_periods.period_year,vw_periods.period_month,
		loan_monthly.org_id, loan_monthly.loan_month_id, loan_monthly.interest_amount, 
		 loan_monthly. is_paid, 
		loan_monthly.repayment_paid, loan_monthly.interest_paid, 
		loan_monthly.penalty, loan_monthly.penalty_paid, loan_monthly.details,
		get_total_interest(vw_loans.loan_id, vw_periods.start_date) as total_interest,
		get_total_repayment(vw_loans.loan_id, vw_periods.start_date) as total_repayment,
		
		(vw_loans.principle + get_total_interest(vw_loans.loan_id, vw_periods.start_date + 1) + get_penalty(vw_loans.loan_id, vw_periods.start_date + 1) - vw_loans.initial_payment - get_total_repayment(vw_loans.loan_id, vw_periods.start_date + 1)) as loan_balance
	FROM loan_monthly INNER JOIN vw_loans ON loan_monthly.loan_id = vw_loans.loan_id
		INNER JOIN members ON vw_loans.entity_id = members.entity_id
		INNER JOIN vw_periods ON loan_monthly.period_id = vw_periods.period_id;
		
		

CREATE VIEW vw_loan_payments AS
	SELECT	vw_loans.currency_id, vw_loans.currency_name, vw_loans.currency_symbol,
		vw_loans.loan_type_id, vw_loans.loan_type_name, vw_loan_monthly.is_paid,
		vw_loans.entity_id, vw_loans.entity_name,vw_loans.loan_date,
		vw_loans.loan_id, vw_loans.principle, vw_loans.interest, vw_loans.monthly_repayment, vw_loans.reducing_balance, 
		vw_loans.repayment_period, vw_loans.application_date, vw_loans.approve_status, vw_loans.initial_payment, 
		vw_loans.org_id, vw_loans.action_date,vw_loans.calc_repayment_period,vw_loans.repayment_amount ,
		generate_series(1, vw_loans.repayment_period) as months,
		get_loan_period(vw_loans.principle, vw_loans.interest, generate_series(1, vw_loans.repayment_period), vw_loans.repayment_amount) as loan_balance, 
		
		(get_loan_period(vw_loans.principle, vw_loans.interest, generate_series(1, vw_loans.repayment_period) - 1, vw_loans.repayment_amount) * (vw_loans.interest/1200)) as loan_intrest 
	FROM vw_loans
	JOIN vw_loan_monthly on vw_loans.loan_id = vw_loan_monthly.loan_id where vw_loan_monthly.is_paid = 'true' ;

CREATE VIEW vw_period_loans AS
	SELECT vw_loan_monthly.org_id, vw_loan_monthly.period_id, vw_loan_monthly.is_paid,
		sum(vw_loan_monthly.interest_amount) as sum_interest_amount, sum(vw_loan_monthly.repayment_paid) as sum_repayment, 
		sum(vw_loan_monthly.penalty) as sum_penalty, sum(vw_loan_monthly.penalty_paid) as sum_penalty_paid, 
		--sum( vw_loan_monthly.additional_payments) as sum_additional_payments,
		sum(vw_loan_monthly.interest_paid) as sum_interest_paid, sum(vw_loan_monthly.loan_balance) as sum_loan_balance
	FROM vw_loan_monthly
	GROUP BY vw_loan_monthly.org_id, vw_loan_monthly.period_id,  vw_loan_monthly.is_paid;
	
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


CREATE OR REPLACE FUNCTION loan_aplication(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	msg 				varchar(120);
BEGIN
	msg := 'Loan applied';
	
	UPDATE loans SET approve_status = 'Completed'
	WHERE (loan_id = CAST($1 as int)) AND (approve_status = 'Draft');

	return msg;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION ins_loans()
  RETURNS trigger AS
$BODY$
DECLARE
	v_default_interest	real;
	v_reducing_balance	boolean;
	periodid         	integer;
	journalid			integer;
	currencyid  		integer;	
	entityname     		varchar(120);
	loanid				integer;
	vpenalty 			real;
	vinterest			real;
BEGIN

	SELECT default_interest, reducing_balance INTO v_default_interest, v_reducing_balance
	FROM loan_types 
	WHERE (loan_type_id = NEW.loan_type_id);
		
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
		NEW.repayment_period := ceil(NEW.principle / NEW.monthly_repayment);
	END IF;
	
	IF(NEW.monthly_repayment > NEW.principle)THEN
		RAISE EXCEPTION 'Repayment should be less than the principal amount';
	END IF;
	
	If ( New. approve_status = 'Approved' ) THEN 
		
		IF(periodid is null) THEN
		periodid := get_open_period(New.loan_date);
		ELSE
		select currency_id into currencyid from currency where org_id = NEW.org_id;
		Select entity_name into entityname from entitys where entity_id = NEW.entity_id;
		
			INSERT INTO journals (period_id, journal_date, org_id, department_id, currency_id, narrative, year_closing)
			VALUES (periodid, New.application_date::date,New.org_id, 1, currencyid, entityname || ' Loan', false) returning journal_id into journalid ;
			
			INSERT INTO gls ( journal_id, account_id, debit,credit, gl_narrative,  org_id)
			VALUES (journalid, 30000, NEW.principle, 0, entityname || ' Loan principal', NEW.org_id) ;
			
			INSERT INTO  gls (journal_id, account_id, debit, credit, gl_narrative, org_id)
			VALUES ( journalid, 33000,0, NEW.principle,  entityname || ' Loan principal', NEW.org_id);
			
			NEW.journal_id = journalid;
			
			
		END IF;
		 
		
	END IF;	
	
	RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql;

CREATE TRIGGER ins_loans BEFORE INSERT OR UPDATE ON loans
    FOR EACH ROW EXECUTE PROCEDURE ins_loans();
    

CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON loans
    FOR EACH ROW EXECUTE PROCEDURE upd_action();

CREATE OR REPLACE FUNCTION compute_loans(v_period_id varchar(12), v_org_id varchar(12), v_approval varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	msg					varchar(120);
BEGIN
	
	
	DELETE FROM loan_monthly WHERE period_id = v_period_id::integer;

	INSERT INTO loan_monthly (period_id, org_id, loan_id, repayment, interest_amount)
	SELECT v_period_id::integer, org_id::integer, loan_id, monthly_repayment, (loan_balance * interest / 1200)
	FROM vw_loans 
	WHERE (loan_balance > 0) AND (approve_status = 'Approved') AND (reducing_balance =  true);

	INSERT INTO loan_monthly (period_id, org_id, loan_id, repayment, interest_amount)
	SELECT v_period_id::integer, org_id::integer, loan_id, monthly_repayment, (principle * interest / 1200) 	FROM vw_loans 
	WHERE (loan_balance > 0) AND (approve_status = 'Approved') AND (reducing_balance =  false) ;

	msg := ' Repayments Computed';

	RETURN msg;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION ins_loan_monthly() RETURNS trigger AS $BODY$
DECLARE
	vdate					date;
	entityname				varchar(120);
	journalid				integer;
	currencyid				integer;
	vpenalty 				real;
	periodid         		integer;
	entityid				integer;
	vinterest				real;
	vpenaltypaid 			real;
	vinterestpaid			real;
	vrepaymentpaid          real;
	vtotalinterest          real;
BEGIN
			
	SELECT penalty , interest_amount, start_date, vw_loans.entity_name,period_id, vw_loans.entity_id,
		vw_loans.currency_id, vw_loans.total_interest 
	INTO vpenalty , vinterest,vdate, entityname, periodid,entityid, currencyid, vtotalinterest 
	FROM vw_loan_monthly INNER JOIN vw_loans ON vw_loans.loan_id = vw_loan_monthly.loan_id 
	WHERE( vw_loan_monthly.loan_id = New.loan_id);
	    
	RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql;

CREATE TRIGGER ins_loan_monthly AFTER INSERT OR UPDATE ON loan_monthly
    FOR EACH ROW EXECUTE PROCEDURE ins_loan_monthly();
