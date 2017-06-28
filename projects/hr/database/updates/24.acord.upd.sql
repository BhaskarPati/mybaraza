
CREATE OR REPLACE FUNCTION process_pensions(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	rec							RECORD;
	adj							RECORD;
	v_period_id					integer;
	v_org_id					integer;
	v_employee_month_id			integer;
	v_employee_adjustment_id	integer;
	v_currency_id				integer;
	v_exchange_rate				real;
	a_exchange_rate				real;
	v_amount					real;
	msg							varchar(120);
BEGIN

	SELECT period_id, org_id INTO v_period_id, v_org_id
	FROM periods WHERE period_id = $1::int;
	
	FOR rec IN SELECT pension_id, entity_id, adjustment_id, contribution_id, 
       pension_company, pension_number, amount, use_formura, 
       employer_ps, employer_amount, employer_formural
	FROM pensions WHERE (active = true) AND (org_id = v_org_id) LOOP
	
		SELECT employee_month_id, currency_id, exchange_rate 
			INTO v_employee_month_id, v_currency_id, v_exchange_rate
		FROM employee_month
		WHERE (period_id = v_period_id) AND (entity_id = rec.entity_id);
		
		--- Deduction
		SELECT employee_adjustment_id INTO v_employee_adjustment_id
		FROM employee_adjustments
		WHERE (employee_month_id = v_employee_month_id) AND (pension_id = rec.pension_id)
			AND (adjustment_id = rec.adjustment_id);
		
		SELECT adjustment_id, currency_id, org_id, adjustment_name, adjustment_type, 
			adjustment_order, earning_code, formural, monthly_update, in_payroll, 
			in_tax, visible, running_balance, reduce_balance, tax_reduction_ps, 
			tax_relief_ps, tax_max_allowed, account_number
		INTO adj
		FROM adjustments
		WHERE (adjustment_id = rec.adjustment_id);
		
		IF(rec.use_formura = true) AND (adj.formural is not null) AND (v_employee_month_id is not null) THEN
			EXECUTE 'SELECT ' || adj.formural || ' FROM employee_month WHERE employee_month_id = ' || v_employee_month_id
			INTO v_amount;
			IF(v_currency_id <> adj.currency_id)THEN
				v_amount := v_amount * v_exchange_rate;
			END IF;
		ELSIF(rec.amount > 0)THEN
			v_amount := rec.amount;
		END IF;
		
		IF(v_currency_id <> adj.currency_id)THEN
			a_exchange_rate := 1 / v_exchange_rate;
		END IF;
		
		IF(v_employee_adjustment_id is null) AND (v_employee_month_id is not null) THEN
			INSERT INTO employee_adjustments(employee_month_id, pension_id, org_id, 
				adjustment_id, adjustment_type, adjustment_factor, 
				in_payroll, in_tax, visible,
				exchange_rate, pay_date, amount)
			VALUES (v_employee_month_id, rec.pension_id, v_org_id,
				adj.adjustment_id, adj.adjustment_type, -1, 
				adj.in_payroll, adj.in_tax, adj.visible,
				a_exchange_rate, current_date, v_amount);
		ELSIF (v_employee_month_id is not null) THEN
			UPDATE employee_adjustments SET amount = v_amount, exchange_rate = a_exchange_rate
			WHERE employee_adjustment_id = v_employee_adjustment_id;
		END IF;
	
		--- Employer contribution
		IF((rec.employer_ps > 0) OR (rec.employer_amount > 0) OR (rec.employer_formural = true))THEN
			SELECT employee_adjustment_id INTO v_employee_adjustment_id
			FROM employee_adjustments
			WHERE (employee_month_id = v_employee_month_id) AND (pension_id = rec.pension_id)
				AND (adjustment_id = rec.contribution_id);
			
			SELECT adjustment_id, currency_id, org_id, adjustment_name, adjustment_type, 
				adjustment_order, earning_code, formural, monthly_update, in_payroll, 
				in_tax, visible, running_balance, reduce_balance, tax_reduction_ps, 
				tax_relief_ps, tax_max_allowed, account_number
			INTO adj
			FROM adjustments
			WHERE (adjustment_id = rec.contribution_id);
			
			IF(v_currency_id <> adj.currency_id)THEN
				a_exchange_rate := 1 / v_exchange_rate;
			END IF;
			
			IF(rec.employer_formural = true) AND (adj.formural is not null) AND (v_employee_month_id is not null) THEN
				EXECUTE 'SELECT ' || adj.formural || ' FROM employee_month WHERE employee_month_id = ' || v_employee_month_id
				INTO v_amount;
				IF(v_currency_id <> adj.currency_id)THEN
					v_amount := v_amount * v_exchange_rate;
				END IF;
			ELSIF(rec.employer_ps > 0)THEN
				v_amount := v_amount * rec.employer_ps / 100;
			ELSIF(rec.employer_amount > 0)THEN
				v_amount := rec.employer_amount;
			END IF;
			
			IF(v_employee_adjustment_id is null) AND (v_employee_month_id is not null)THEN
				INSERT INTO employee_adjustments(employee_month_id, pension_id, org_id, 
					adjustment_id, adjustment_type, adjustment_factor, 
					in_payroll, in_tax, visible,
					exchange_rate, pay_date, amount)
				VALUES (v_employee_month_id, rec.pension_id, v_org_id,
					adj.adjustment_id, adj.adjustment_type, 1, 
					adj.in_payroll, adj.in_tax, adj.visible,
					a_exchange_rate, current_date, v_amount);
			ELSIF (v_employee_month_id is not null) THEN
				UPDATE employee_adjustments SET amount = v_amount, exchange_rate = a_exchange_rate
				WHERE employee_adjustment_id = v_employee_adjustment_id;
			END IF;
		END IF;
		
	END LOOP;

	msg := 'Pension Processed';

	RETURN msg;
END;
$$ LANGUAGE plpgsql;

	
CREATE OR REPLACE FUNCTION process_pensions(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	rec							RECORD;
	adj							RECORD;
	v_period_id					integer;
	v_org_id					integer;
	v_employee_month_id			integer;
	v_employee_adjustment_id	integer;
	v_exchange_rate				real;
	v_amount					real;
	msg							varchar(120);
BEGIN

	SELECT period_id, org_id INTO v_period_id, v_org_id
	FROM periods WHERE period_id = $1::int;
	
	FOR rec IN SELECT pension_id, entity_id, adjustment_id, contribution_id, 
       pension_company, pension_number, amount, use_formura, 
       employer_ps, employer_amount, employer_formural
	FROM pensions WHERE (active = true) AND (org_id = v_org_id) LOOP
	
		SELECT employee_month_id INTO v_employee_month_id
		FROM employee_month
		WHERE (period_id = v_period_id) AND (entity_id = rec.entity_id);
		
		--- Deduction
		SELECT employee_adjustment_id INTO v_employee_adjustment_id
		FROM employee_adjustments
		WHERE (employee_month_id = v_employee_month_id) AND (pension_id = rec.pension_id)
			AND (adjustment_id = rec.adjustment_id);
		
		SELECT adjustment_id, currency_id, org_id, adjustment_name, adjustment_type, 
			adjustment_order, earning_code, formural, monthly_update, in_payroll, 
			in_tax, visible, running_balance, reduce_balance, tax_reduction_ps, 
			tax_relief_ps, tax_max_allowed, account_number
		INTO adj
		FROM adjustments
		WHERE (adjustment_id = rec.adjustment_id);
		
		IF(rec.use_formura = true) AND (adj.formural is not null)THEN
			EXECUTE 'SELECT ' || adj.formural || ' FROM employee_month WHERE employee_month_id = ' || v_employee_month_id
			INTO v_amount;
		ELSIF(rec.amount > 0)THEN
			v_amount := rec.amount;
		END IF;
		
		
		IF(v_employee_adjustment_id is null) AND (v_employee_month_id is not null) THEN
			INSERT INTO employee_adjustments(employee_month_id, pension_id, org_id, 
				adjustment_id, adjustment_type, adjustment_factor, 
				in_payroll, in_tax, visible,
				exchange_rate, pay_date, amount)
			VALUES (v_employee_month_id, rec.pension_id, v_org_id,
				adj.adjustment_id, adj.adjustment_type, -1, 
				adj.in_payroll, adj.in_tax, adj.visible,
				1, current_date, v_amount);
		ELSIF (employee_month_id is not null) THEN
			UPDATE employee_adjustments SET amount = v_amount
			WHERE employee_adjustment_id = v_employee_adjustment_id;
		END IF;
	
		--- Employer contribution
		IF((rec.employer_ps > 0) OR (rec.employer_amount > 0) OR (rec.employer_formural = true))THEN
			SELECT employee_adjustment_id INTO v_employee_adjustment_id
			FROM employee_adjustments
			WHERE (employee_month_id = v_employee_month_id) AND (pension_id = rec.pension_id)
				AND (adjustment_id = rec.contribution_id);
			
			SELECT adjustment_id, currency_id, org_id, adjustment_name, adjustment_type, 
				adjustment_order, earning_code, formural, monthly_update, in_payroll, 
				in_tax, visible, running_balance, reduce_balance, tax_reduction_ps, 
				tax_relief_ps, tax_max_allowed, account_number
			INTO adj
			FROM adjustments
			WHERE (adjustment_id = rec.contribution_id);
			
			IF(rec.employer_formural = true) AND (adj.formural is not null)THEN
				EXECUTE 'SELECT ' || adj.formural || ' FROM employee_month WHERE employee_month_id = ' || v_employee_month_id
				INTO v_amount;
			ELSIF(rec.employer_ps > 0)THEN
				v_amount := v_amount * rec.employer_ps / 100;
			ELSIF(rec.employer_amount > 0)THEN
				v_amount := rec.employer_amount;
			END IF;
			
			IF(v_employee_adjustment_id is null) AND (employee_month_id is not null)THEN
				INSERT INTO employee_adjustments(employee_month_id, pension_id, org_id, 
					adjustment_id, adjustment_type, adjustment_factor, 
					in_payroll, in_tax, visible,
					exchange_rate, pay_date, amount)
				VALUES (v_employee_month_id, rec.pension_id, v_org_id,
					adj.adjustment_id, adj.adjustment_type, 1, 
					adj.in_payroll, adj.in_tax, adj.visible,
					1, current_date, v_amount);
			ELSIF (employee_month_id is not null) THEN
				UPDATE employee_adjustments SET amount = v_amount
				WHERE employee_adjustment_id = v_employee_adjustment_id;
			END IF;
		END IF;
		
	END LOOP;

	msg := 'Pension Processed';

	RETURN msg;
END;
$$ LANGUAGE plpgsql;

	

INSERT INTO pensions(entity_id, adjustment_id, contribution_id, org_id, 
	pension_company, pension_number, active, amount, use_formura, 
	employer_ps, employer_amount, employer_formural)
SELECT entity_id, adjustment_id, 35, org_id, 
	'BRITAM', trim(replace(narrative, 'BRITAM', '')), true, amount, false,
	0, 0, true
FROM default_adjustments
WHERE adjustment_id = 66 and amount > 0;

DELETE FROM default_adjustments WHERE adjustment_id = 35;
DELETE FROM default_adjustments WHERE adjustment_id = 66;

INSERT INTO pensions(entity_id, adjustment_id, contribution_id, org_id, 
	pension_company, pension_number, active, amount, use_formura, 
	employer_ps, employer_amount, employer_formural)
SELECT entity_id, adjustment_id, 71, org_id, 
	'BRITAM', trim(replace(narrative, 'BRITAM', '')), true, amount, false,
	0, 0, true
FROM default_adjustments
WHERE adjustment_id = 76 and amount > 0;

DELETE FROM default_adjustments WHERE adjustment_id = 76;
DELETE FROM default_adjustments WHERE adjustment_id = 71;


UPDATE pensions SET pension_company = 'JUBILEE', pension_number = 'PPP050149' WHERE entity_id = 47;


UPDATE employee_adjustments SET pension_id = aa.pension_id
FROM (SELECT vw_employee_adjustments.employee_adjustment_id, pensions.pension_id
FROM vw_employee_adjustments INNER JOIN pensions ON 
vw_employee_adjustments.entity_id = pensions.entity_id
WHERE vw_employee_adjustments.adjustment_id IN (35, 66, 71, 76)) as aa
WHERE employee_adjustments.employee_adjustment_id = aa.employee_adjustment_id;

DROP VIEW vw_loan_projection;
DROP VIEW vw_period_loans;
DROP VIEW vw_loan_payments;
DROP VIEW vw_loan_monthly;
DROP VIEW vw_loans;

CREATE VIEW vw_loans AS
	SELECT vw_loan_types.adjustment_id, vw_loan_types.adjustment_name, vw_loan_types.account_number,
		vw_loan_types.currency_id, vw_loan_types.currency_name, vw_loan_types.currency_symbol,
		vw_loan_types.loan_type_id, vw_loan_types.loan_type_name, 
		entitys.entity_id, entitys.entity_name, employees.employee_id,
		loans.org_id, loans.loan_id, loans.principle, loans.interest, loans.monthly_repayment, loans.reducing_balance, 
		loans.repayment_period, loans.application_date, loans.approve_status, loans.initial_payment, 
		loans.loan_date, loans.action_date, loans.details,
		get_repayment(loans.principle, loans.interest, loans.repayment_period) as repayment_amount, 
		loans.initial_payment + get_total_repayment(loans.loan_id) as total_repayment, get_total_interest(loans.loan_id) as total_interest,
		(loans.principle + get_total_interest(loans.loan_id) - loans.initial_payment - get_total_repayment(loans.loan_id)) as loan_balance,
		get_payment_period(loans.principle, loans.monthly_repayment, loans.interest) as calc_repayment_period
	FROM loans INNER JOIN entitys ON loans.entity_id = entitys.entity_id
		INNER JOIN employees ON loans.entity_id = employees.entity_id
		INNER JOIN vw_loan_types ON loans.loan_type_id = vw_loan_types.loan_type_id;

CREATE VIEW vw_loan_monthly AS
	SELECT  vw_loans.adjustment_id, vw_loans.adjustment_name, vw_loans.account_number,
		vw_loans.currency_id, vw_loans.currency_name, vw_loans.currency_symbol,
		vw_loans.loan_type_id, vw_loans.loan_type_name, 
		vw_loans.entity_id, vw_loans.entity_name, vw_loans.employee_id, vw_loans.loan_date,
		vw_loans.loan_id, vw_loans.principle, vw_loans.interest, vw_loans.monthly_repayment, vw_loans.reducing_balance, 
		vw_loans.repayment_period, vw_periods.period_id, vw_periods.start_date, vw_periods.end_date, vw_periods.activated, vw_periods.closed,
		loan_monthly.org_id, loan_monthly.loan_month_id, loan_monthly.interest_amount, loan_monthly.repayment, loan_monthly.interest_paid, 
		loan_monthly.employee_adjustment_id, loan_monthly.penalty, loan_monthly.penalty_paid, loan_monthly.details,
		get_total_interest(vw_loans.loan_id, vw_periods.start_date) as total_interest,
		get_total_repayment(vw_loans.loan_id, vw_periods.start_date) as total_repayment,
		(vw_loans.principle + get_total_interest(vw_loans.loan_id, vw_periods.start_date + 1) + get_penalty(vw_loans.loan_id, vw_periods.start_date + 1)
		- vw_loans.initial_payment - get_total_repayment(vw_loans.loan_id, vw_periods.start_date + 1)) as loan_balance
	FROM loan_monthly INNER JOIN vw_loans ON loan_monthly.loan_id = vw_loans.loan_id
		INNER JOIN vw_periods ON loan_monthly.period_id = vw_periods.period_id;

CREATE VIEW vw_loan_payments AS
	SELECT vw_loans.adjustment_id, vw_loans.adjustment_name, vw_loans.account_number,
		vw_loans.currency_id, vw_loans.currency_name, vw_loans.currency_symbol,
		vw_loans.loan_type_id, vw_loans.loan_type_name, 
		vw_loans.entity_id, vw_loans.entity_name, vw_loans.employee_id, vw_loans.loan_date,
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
		sum(vw_loan_monthly.penalty) as sum_penalty, sum(vw_loan_monthly.penalty_paid) as sum_penalty_paid, 
		sum(vw_loan_monthly.interest_paid) as sum_interest_paid, sum(vw_loan_monthly.loan_balance) as sum_loan_balance
	FROM vw_loan_monthly
	GROUP BY vw_loan_monthly.org_id, vw_loan_monthly.period_id;
	
CREATE VIEW vw_loan_projection AS
	SELECT org_id, loan_id, loan_type_name, entity_name, principle, monthly_repayment, loan_date, 
		(EXTRACT(YEAR FROM age(current_date, '2010-05-01')) * 12) + EXTRACT(MONTH FROM age(current_date, loan_date)) as loan_months,
		get_total_repayment(loan_id, CAST((EXTRACT(YEAR FROM age(current_date, '2010-05-01')) * 12) + EXTRACT(MONTH FROM age(current_date, loan_date)) as integer)) as loan_paid
	FROM vw_loans;	

UPDATE loans SET reducing_balance = true, monthly_repayment = 10216.89 WHERE loan_id = 12;
UPDATE loans SET reducing_balance = true, monthly_repayment = 21700.21 WHERE loan_id = 13;
UPDATE loans SET reducing_balance = true, monthly_repayment = 586.10 WHERE loan_id = 15;
UPDATE loans SET reducing_balance = true, monthly_repayment = 598.24 WHERE loan_id = 16;
UPDATE loans SET reducing_balance = true, monthly_repayment = 8445.03 WHERE loan_id = 17;
UPDATE loans SET reducing_balance = true, monthly_repayment = 292.88 WHERE loan_id = 18;
UPDATE loans SET reducing_balance = true, monthly_repayment = 293.18 WHERE loan_id = 19;
UPDATE loans SET reducing_balance = true, monthly_repayment = 9670.60 WHERE loan_id = 20;
UPDATE loans SET reducing_balance = true, monthly_repayment = 401.03 WHERE loan_id = 21;
UPDATE loans SET reducing_balance = true, monthly_repayment = 620.82 WHERE loan_id = 23;
UPDATE loans SET reducing_balance = true, monthly_repayment = 21139.42 WHERE loan_id = 24;
UPDATE loans SET reducing_balance = true, monthly_repayment = 12434.46 WHERE loan_id = 26;
UPDATE loans SET reducing_balance = true, monthly_repayment = 41448.20 WHERE loan_id = 27;
UPDATE loans SET reducing_balance = true, monthly_repayment = 24791.24 WHERE loan_id = 30;
UPDATE loans SET reducing_balance = true, monthly_repayment = 231.47 WHERE loan_id = 32;

ALTER TABLE loan_monthly ADD deduction real;
UPDATE loan_monthly SET deduction = repayment + interest_paid;

UPDATE loan_monthly SET repayment = 9354.08 WHERE loan_id = 20 AND period_id = 13;
UPDATE loan_monthly SET repayment = 9385.26 WHERE loan_id = 20 AND period_id = 14;
UPDATE loan_monthly SET repayment = 9416.54 WHERE loan_id = 20 AND period_id = 15;
UPDATE loan_monthly SET repayment = 9447.93 WHERE loan_id = 20 AND period_id = 16;
UPDATE loan_monthly SET repayment = 9479.42 WHERE loan_id = 20 AND period_id = 17;
UPDATE loan_monthly SET repayment = 9511.02 WHERE loan_id = 20 AND period_id = 18;
UPDATE loan_monthly SET repayment = 9542.73 WHERE loan_id = 20 AND period_id = 19;
UPDATE loan_monthly SET repayment = 9574.53 WHERE loan_id = 20 AND period_id = 20;
UPDATE loan_monthly SET repayment = 9606.45 WHERE loan_id = 20 AND period_id = 25;
UPDATE loan_monthly SET repayment = 9638.47 WHERE loan_id = 20 AND period_id = 26;
UPDATE loan_monthly SET repayment = 9670.60 WHERE loan_id = 20 AND period_id = 28;
UPDATE loan_monthly SET repayment = 282.52 WHERE loan_id = 21 AND period_id = 13;
UPDATE loan_monthly SET repayment = 283.46 WHERE loan_id = 21 AND period_id = 14;
UPDATE loan_monthly SET repayment = 284.40 WHERE loan_id = 21 AND period_id = 15;
UPDATE loan_monthly SET repayment = 285.35 WHERE loan_id = 21 AND period_id = 16;
UPDATE loan_monthly SET repayment = 286.30 WHERE loan_id = 21 AND period_id = 17;
UPDATE loan_monthly SET repayment = 287.26 WHERE loan_id = 21 AND period_id = 18;
UPDATE loan_monthly SET repayment = 288.21 WHERE loan_id = 21 AND period_id = 19;
UPDATE loan_monthly SET repayment = 397.35 WHERE loan_id = 21 AND period_id = 20;
UPDATE loan_monthly SET repayment = 398.57 WHERE loan_id = 21 AND period_id = 25;
UPDATE loan_monthly SET repayment = 399.80 WHERE loan_id = 21 AND period_id = 26;
UPDATE loan_monthly SET repayment = 401.03 WHERE loan_id = 21 AND period_id = 28;
UPDATE loan_monthly SET repayment = 281.41 WHERE loan_id = 18 AND period_id = 13;
UPDATE loan_monthly SET repayment = 282.35 WHERE loan_id = 18 AND period_id = 14;
UPDATE loan_monthly SET repayment = 285.18 WHERE loan_id = 18 AND period_id = 15;
UPDATE loan_monthly SET repayment = 286.13 WHERE loan_id = 18 AND period_id = 16;
UPDATE loan_monthly SET repayment = 287.09 WHERE loan_id = 18 AND period_id = 17;
UPDATE loan_monthly SET repayment = 288.04 WHERE loan_id = 18 AND period_id = 18;
UPDATE loan_monthly SET repayment = 289.00 WHERE loan_id = 18 AND period_id = 19;
UPDATE loan_monthly SET repayment = 289.97 WHERE loan_id = 18 AND period_id = 20;
UPDATE loan_monthly SET repayment = 290.93 WHERE loan_id = 18 AND period_id = 25;
UPDATE loan_monthly SET repayment = 291.90 WHERE loan_id = 18 AND period_id = 26;
UPDATE loan_monthly SET repayment = 292.88 WHERE loan_id = 18 AND period_id = 28;
UPDATE loan_monthly SET repayment = 230.32 WHERE loan_id = 32 AND period_id = 25;
UPDATE loan_monthly SET repayment = 230.89 WHERE loan_id = 32 AND period_id = 26;
UPDATE loan_monthly SET repayment = 231.47 WHERE loan_id = 32 AND period_id = 28;
UPDATE loan_monthly SET repayment = 566.91 WHERE loan_id = 15 AND period_id = 13;
UPDATE loan_monthly SET repayment = 568.80 WHERE loan_id = 15 AND period_id = 14;
UPDATE loan_monthly SET repayment = 570.70 WHERE loan_id = 15 AND period_id = 15;
UPDATE loan_monthly SET repayment = 572.60 WHERE loan_id = 15 AND period_id = 16;
UPDATE loan_monthly SET repayment = 574.51 WHERE loan_id = 15 AND period_id = 17;
UPDATE loan_monthly SET repayment = 576.43 WHERE loan_id = 15 AND period_id = 18;
UPDATE loan_monthly SET repayment = 578.35 WHERE loan_id = 15 AND period_id = 19;
UPDATE loan_monthly SET repayment = 580.27 WHERE loan_id = 15 AND period_id = 20;
UPDATE loan_monthly SET repayment = 582.21 WHERE loan_id = 15 AND period_id = 25;
UPDATE loan_monthly SET repayment = 584.15 WHERE loan_id = 15 AND period_id = 26;
UPDATE loan_monthly SET repayment = 586.10 WHERE loan_id = 15 AND period_id = 28;
UPDATE loan_monthly SET repayment = 40091.59 WHERE loan_id = 27 AND period_id = 13;
UPDATE loan_monthly SET repayment = 40225.23 WHERE loan_id = 27 AND period_id = 14;
UPDATE loan_monthly SET repayment = 40359.31 WHERE loan_id = 27 AND period_id = 15;
UPDATE loan_monthly SET repayment = 40493.84 WHERE loan_id = 27 AND period_id = 16;
UPDATE loan_monthly SET repayment = 40628.82 WHERE loan_id = 27 AND period_id = 17;
UPDATE loan_monthly SET repayment = 40764.00 WHERE loan_id = 27 AND period_id = 18;
UPDATE loan_monthly SET repayment = 40900.13 WHERE loan_id = 27 AND period_id = 19;
UPDATE loan_monthly SET repayment = 41036.47 WHERE loan_id = 27 AND period_id = 20;
UPDATE loan_monthly SET repayment = 41173.25 WHERE loan_id = 27 AND period_id = 25;
UPDATE loan_monthly SET repayment = 41310.50 WHERE loan_id = 27 AND period_id = 26;
UPDATE loan_monthly SET repayment = 41448.20 WHERE loan_id = 27 AND period_id = 28;
UPDATE loan_monthly SET repayment = 24544.97 WHERE loan_id = 30 AND period_id = 20;
UPDATE loan_monthly SET repayment = 24626.79 WHERE loan_id = 30 AND period_id = 25;
UPDATE loan_monthly SET repayment = 24708.88 WHERE loan_id = 30 AND period_id = 26;
UPDATE loan_monthly SET repayment = 24791.24 WHERE loan_id = 30 AND period_id = 28;
UPDATE loan_monthly SET repayment = 20584.06 WHERE loan_id = 24 AND period_id = 13;
UPDATE loan_monthly SET repayment = 20652.67 WHERE loan_id = 24 AND period_id = 14;
UPDATE loan_monthly SET repayment = 20721.52 WHERE loan_id = 24 AND period_id = 15;
UPDATE loan_monthly SET repayment = 20790.59 WHERE loan_id = 24 AND period_id = 16;
UPDATE loan_monthly SET repayment = 20859.89 WHERE loan_id = 24 AND period_id = 17;
UPDATE loan_monthly SET repayment = 20929.42 WHERE loan_id = 24 AND period_id = 18;
UPDATE loan_monthly SET repayment = 20999.19 WHERE loan_id = 24 AND period_id = 19;
UPDATE loan_monthly SET repayment = 21069.19 WHERE loan_id = 24 AND period_id = 20;
UPDATE loan_monthly SET repayment = 21139.42 WHERE loan_id = 24 AND period_id = 25;
UPDATE loan_monthly SET repayment = 404.94 WHERE loan_id = 16 AND period_id = 13;
UPDATE loan_monthly SET repayment = 406.29 WHERE loan_id = 16 AND period_id = 14;
UPDATE loan_monthly SET repayment = 407.64 WHERE loan_id = 16 AND period_id = 15;
UPDATE loan_monthly SET repayment = 409.00 WHERE loan_id = 16 AND period_id = 16;
UPDATE loan_monthly SET repayment = 410.36 WHERE loan_id = 16 AND period_id = 17;
UPDATE loan_monthly SET repayment = 411.73 WHERE loan_id = 16 AND period_id = 18;
UPDATE loan_monthly SET repayment = 413.10 WHERE loan_id = 16 AND period_id = 19;
UPDATE loan_monthly SET repayment = 414.48 WHERE loan_id = 16 AND period_id = 20;
UPDATE loan_monthly SET repayment = 415.86 WHERE loan_id = 16 AND period_id = 25;
UPDATE loan_monthly SET repayment = 597.20 WHERE loan_id = 16 AND period_id = 26;
UPDATE loan_monthly SET repayment = 598.24 WHERE loan_id = 16 AND period_id = 28;
UPDATE loan_monthly SET repayment = 8168.62 WHERE loan_id = 17 AND period_id = 13;
UPDATE loan_monthly SET repayment = 8195.85 WHERE loan_id = 17 AND period_id = 14;
UPDATE loan_monthly SET repayment = 8223.17 WHERE loan_id = 17 AND period_id = 15;
UPDATE loan_monthly SET repayment = 8250.58 WHERE loan_id = 17 AND period_id = 16;
UPDATE loan_monthly SET repayment = 8278.09 WHERE loan_id = 17 AND period_id = 17;
UPDATE loan_monthly SET repayment = 8305.68 WHERE loan_id = 17 AND period_id = 18;
UPDATE loan_monthly SET repayment = 8333.36 WHERE loan_id = 17 AND period_id = 19;
UPDATE loan_monthly SET repayment = 8361.14 WHERE loan_id = 17 AND period_id = 20;
UPDATE loan_monthly SET repayment = 8389.01 WHERE loan_id = 17 AND period_id = 25;
UPDATE loan_monthly SET repayment = 8416.98 WHERE loan_id = 17 AND period_id = 26;
UPDATE loan_monthly SET repayment = 8445.03 WHERE loan_id = 17 AND period_id = 28;
UPDATE loan_monthly SET repayment = 20989.95 WHERE loan_id = 13 AND period_id = 13;
UPDATE loan_monthly SET repayment = 21059.92 WHERE loan_id = 13 AND period_id = 14;
UPDATE loan_monthly SET repayment = 21130.12 WHERE loan_id = 13 AND period_id = 15;
UPDATE loan_monthly SET repayment = 21200.55 WHERE loan_id = 13 AND period_id = 16;
UPDATE loan_monthly SET repayment = 21271.22 WHERE loan_id = 13 AND period_id = 17;
UPDATE loan_monthly SET repayment = 21342.13 WHERE loan_id = 13 AND period_id = 18;
UPDATE loan_monthly SET repayment = 21413.27 WHERE loan_id = 13 AND period_id = 19;
UPDATE loan_monthly SET repayment = 21484.64 WHERE loan_id = 13 AND period_id = 20;
UPDATE loan_monthly SET repayment = 21556.26 WHERE loan_id = 13 AND period_id = 25;
UPDATE loan_monthly SET repayment = 21628.11 WHERE loan_id = 13 AND period_id = 26;
UPDATE loan_monthly SET repayment = 21700.21 WHERE loan_id = 13 AND period_id = 28;
UPDATE loan_monthly SET repayment = 283.59 WHERE loan_id = 19 AND period_id = 13;
UPDATE loan_monthly SET repayment = 284.53 WHERE loan_id = 19 AND period_id = 14;
UPDATE loan_monthly SET repayment = 285.48 WHERE loan_id = 19 AND period_id = 15;
UPDATE loan_monthly SET repayment = 286.43 WHERE loan_id = 19 AND period_id = 16;
UPDATE loan_monthly SET repayment = 287.39 WHERE loan_id = 19 AND period_id = 17;
UPDATE loan_monthly SET repayment = 288.35 WHERE loan_id = 19 AND period_id = 18;
UPDATE loan_monthly SET repayment = 289.31 WHERE loan_id = 19 AND period_id = 19;
UPDATE loan_monthly SET repayment = 290.27 WHERE loan_id = 19 AND period_id = 20;
UPDATE loan_monthly SET repayment = 291.24 WHERE loan_id = 19 AND period_id = 25;
UPDATE loan_monthly SET repayment = 292.21 WHERE loan_id = 19 AND period_id = 26;
UPDATE loan_monthly SET repayment = 293.18 WHERE loan_id = 19 AND period_id = 28;
UPDATE loan_monthly SET repayment = 9751.81 WHERE loan_id = 12 AND period_id = 13;
UPDATE loan_monthly SET repayment = 9784.31 WHERE loan_id = 12 AND period_id = 14;
UPDATE loan_monthly SET repayment = 9816.93 WHERE loan_id = 12 AND period_id = 15;
UPDATE loan_monthly SET repayment = 9849.65 WHERE loan_id = 12 AND period_id = 16;
UPDATE loan_monthly SET repayment = 10014.91 WHERE loan_id = 12 AND period_id = 17;
UPDATE loan_monthly SET repayment = 10048.29 WHERE loan_id = 12 AND period_id = 18;
UPDATE loan_monthly SET repayment = 10081.79 WHERE loan_id = 12 AND period_id = 19;
UPDATE loan_monthly SET repayment = 10115.39 WHERE loan_id = 12 AND period_id = 20;
UPDATE loan_monthly SET repayment = 10149.11 WHERE loan_id = 12 AND period_id = 25;
UPDATE loan_monthly SET repayment = 10182.94 WHERE loan_id = 12 AND period_id = 26;
UPDATE loan_monthly SET repayment = 10216.89 WHERE loan_id = 12 AND period_id = 28;
UPDATE loan_monthly SET repayment = 12027.48 WHERE loan_id = 26 AND period_id = 13;
UPDATE loan_monthly SET repayment = 12067.57 WHERE loan_id = 26 AND period_id = 14;
UPDATE loan_monthly SET repayment = 12107.79 WHERE loan_id = 26 AND period_id = 15;
UPDATE loan_monthly SET repayment = 12148.15 WHERE loan_id = 26 AND period_id = 16;
UPDATE loan_monthly SET repayment = 12188.65 WHERE loan_id = 26 AND period_id = 17;
UPDATE loan_monthly SET repayment = 12229.28 WHERE loan_id = 26 AND period_id = 18;
UPDATE loan_monthly SET repayment = 12270.04 WHERE loan_id = 26 AND period_id = 19;
UPDATE loan_monthly SET repayment = 12310.94 WHERE loan_id = 26 AND period_id = 20;
UPDATE loan_monthly SET repayment = 12351.98 WHERE loan_id = 26 AND period_id = 25;
UPDATE loan_monthly SET repayment = 12393.15 WHERE loan_id = 26 AND period_id = 26;
UPDATE loan_monthly SET repayment = 12434.46 WHERE loan_id = 26 AND period_id = 28;
UPDATE loan_monthly SET repayment = 614.65 WHERE loan_id = 23 AND period_id = 19;
UPDATE loan_monthly SET repayment = 616.19 WHERE loan_id = 23 AND period_id = 20;
UPDATE loan_monthly SET repayment = 617.73 WHERE loan_id = 23 AND period_id = 25;
UPDATE loan_monthly SET repayment = 619.27 WHERE loan_id = 23 AND period_id = 26;
UPDATE loan_monthly SET repayment = 620.82 WHERE loan_id = 23 AND period_id = 28;

UPDATE loan_monthly SET interest_amount = deduction - repayment;
UPDATE loan_monthly SET interest_paid = interest_amount;

ALTER TABLE loan_monthly DROP deduction;



