

UPDATE adjustments SET currency_id = 1 WHERE currency_id is null;


INSERT INTO default_adjustments (entity_id, adjustment_id, org_id)
SELECT entity_id, 15, 0
FROM employees WHERE contract = false;
INSERT INTO default_adjustments (entity_id, adjustment_id, org_id)
SELECT entity_id, 16, 0
FROM employees WHERE contract = false;

INSERT INTO default_adjustments(entity_id, adjustment_id, org_id, amount, active)
SELECT a.employeeid, 41, 0, 0, true
FROM import.employees as a 
WHERE (a.houserate = 0.025);
INSERT INTO default_adjustments(entity_id, adjustment_id, org_id, amount, active)
SELECT a.employeeid, 42, 0, 0, true
FROM import.employees as a 
WHERE (a.houserate = 0.05);
INSERT INTO default_adjustments(entity_id, adjustment_id, org_id, amount, active)
SELECT a.employeeid, 43, 0, 0, true
FROM import.employees as a 
WHERE (a.houserate = 0.075);

INSERT INTO default_adjustments(entity_id, adjustment_id, org_id, amount, active)
SELECT employeeid,  17, 0, 0, true
FROM import.employees
WHERE ishoused = 'Yes';

INSERT INTO default_tax_types(entity_id, tax_type_id, org_id, active)
SELECT a.entity_id, 3, 0, true
FROM employees as a LEFT JOIN 
(SELECT entity_id FROM default_tax_types WHERE tax_type_id = 3) as b
ON a.entity_id = b.entity_id
WHERE b.entity_id is null;


INSERT INTO employee_tax_types(employee_month_id, org_id, tax_type_id, in_tax, amount, exchange_rate)
SELECT aa.employee_month_id, aa.org_id, 3, false, 0, 1
FROM employee_month  as aa LEFT JOIN 
(SELECT a.employee_month_id
FROM employee_month as a INNER JOIN employee_tax_types as b ON a.employee_month_id = b.employee_month_id
WHERE b.tax_type_id = 3 and a.period_id = 213) AS bb
ON aa.employee_month_id = bb.employee_month_id
WHERE aa.period_id = 213 AND bb.employee_month_id is null;




CREATE OR REPLACE FUNCTION generate_payroll(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	v_period_id		integer;
	v_org_id		integer;

	msg 			varchar(120);
BEGIN
	SELECT period_id, org_id INTO v_period_id, v_org_id
	FROM periods
	WHERE (period_id = CAST($1 as integer));

	INSERT INTO period_tax_types (period_id, org_id, tax_type_id, period_tax_type_name, formural, tax_relief, percentage, linear, employer, employer_ps, tax_type_order, in_tax, account_id)
	SELECT v_period_id, org_id, tax_type_id, tax_type_name, formural, tax_relief, percentage, linear, employer, employer_ps, tax_type_order, in_tax, account_id
	FROM tax_types
	WHERE (active = true) AND (org_id = v_org_id);

	INSERT INTO employee_month (period_id, org_id, pay_group_id, entity_id, bank_branch_id, department_role_id, currency_id, bank_account, basic_pay)
	SELECT v_period_id, org_id, pay_group_id, entity_id, bank_branch_id, department_role_id, currency_id, bank_account, basic_salary
	FROM employees
	WHERE (employees.active = true) and (employees.org_id = v_org_id);

	INSERT INTO loan_monthly (period_id, org_id, loan_id, repayment, interest_amount, interest_paid)
	SELECT v_period_id, org_id, loan_id, monthly_repayment, (loan_balance * interest / 1200), (loan_balance * interest / 1200)
	FROM vw_loans 
	WHERE (loan_balance > 0) AND (approve_status = 'Approved') AND (reducing_balance =  true) AND (org_id = v_org_id);

	INSERT INTO loan_monthly (period_id, org_id, loan_id, repayment, interest_amount, interest_paid)
	SELECT v_period_id, org_id, loan_id, monthly_repayment, (principle * interest / 1200), (principle * interest / 1200)
	FROM vw_loans 
	WHERE (loan_balance > 0) AND (approve_status = 'Approved') AND (reducing_balance =  false) AND (org_id = v_org_id);


	msg := 'Payroll Generated';

	RETURN msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION process_payroll(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	rec 		RECORD;
	msg 		varchar(120);
BEGIN
	IF ($3 = '1') THEN
		UPDATE employee_adjustments SET amount = 0
		FROM employee_month 
		WHERE (adjustment_id IN (15,16,17))
			AND (employee_adjustments.employee_month_id = employee_month.employee_month_id) 
			AND (employee_month.period_id = CAST($1 as int));
			
		UPDATE employee_adjustments SET tax_reduction_amount = 0 
		FROM employee_month 
		WHERE (employee_adjustments.employee_month_id = employee_month.employee_month_id) 
			AND (employee_month.period_id = CAST($1 as int));
			
		UPDATE employee_adjustments SET amount = 0 
		FROM employee_month 
		WHERE (employee_adjustments.employee_month_id = employee_month.employee_month_id) 
			AND (employee_month.period_id = CAST($1 as int))
			AND (adjustment_id IN (SELECT adjustment_id FROM adjustments WHERE formural is not null));

		UPDATE employee_adjustments 
			SET amount = ((vw_employee_month.basic_pay + vw_employee_month.full_allowance) * 0.15) - get_house_rent(vw_employee_month.employee_month_id)
		FROM vw_employee_month 
		WHERE (adjustment_id = 17)
			AND (employee_adjustments.employee_month_id = vw_employee_month.employee_month_id) 
			AND (vw_employee_month.period_id = CAST($1 as int));
	
		PERFORM updTax(employee_month_id, period_id)
		FROM employee_month
		WHERE (period_id = CAST($1 as int));
		PERFORM updTax(employee_month_id, period_id)
		FROM employee_month
		WHERE (period_id = CAST($1 as int));
		PERFORM updTax(employee_month_id, period_id)
		FROM employee_month
		WHERE (period_id = CAST($1 as int));
		
		msg := 'Payroll Processed';
	ELSIF ($3 = '2') THEN
		UPDATE periods SET entity_id = CAST($2 as int), approve_status = 'Completed'
		WHERE (period_id = CAST($1 as int));

		msg := 'Application for approval';
	ELSIF ($3 = '3') THEN
		UPDATE periods SET closed = true
		WHERE (period_id = CAST($1 as int));

		msg := 'Period closed';
	ELSIF ($3 = '4') THEN
		UPDATE periods SET closed = false
		WHERE (period_id = CAST($1 as int));

		msg := 'Period opened';
	END IF;

	RETURN msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION upd_employee_adjustments() RETURNS trigger AS $$
DECLARE
	rec 		RECORD;
	entityid 	integer;
	periodid 	integer;
BEGIN
	SELECT monthly_update, running_balance INTO rec
	FROM adjustments WHERE adjustment_id = NEW.Adjustment_ID;

	SELECT entity_id, period_id INTO entityid, periodid
	FROM employee_month WHERE employee_month_id = NEW.employee_month_id;

	IF(rec.running_balance = true) AND (NEW.balance is not null)THEN
		UPDATE default_adjustments SET balance = NEW.balance
		WHERE (entity_id = entityid) AND (adjustment_id = NEW.adjustment_id);
	END IF;

	IF(TG_OP = 'UPDATE')THEN
		IF (OLD.amount <> NEW.amount)THEN
			IF(rec.monthly_update = true)THEN
				UPDATE default_adjustments SET amount = NEW.amount 
				WHERE (entity_id = entityid) AND (adjustment_id = NEW.adjustment_id);
			END IF;
		END IF;
	END IF;

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION updtax(int, int) RETURNS float AS $$
DECLARE
	reca 					RECORD;
	income 					REAL;
	tax 					REAL;
	InsuranceRelief 		REAL;
	v_income				real;
BEGIN

	FOR reca IN SELECT employee_tax_types.employee_tax_type_id, employee_tax_types.tax_type_id, period_tax_types.formural,
			 period_tax_types.employer, period_tax_types.employer_ps
		FROM employee_tax_types INNER JOIN period_tax_types ON (employee_tax_types.tax_type_id = period_tax_types.tax_type_id)
		WHERE (employee_month_id = $1) AND (Period_Tax_Types.Period_ID = $2)
		ORDER BY Period_Tax_Types.Tax_Type_order LOOP

		EXECUTE 'SELECT ' || reca.formural || ' FROM employee_tax_types WHERE employee_tax_type_id = ' || reca.employee_tax_type_id 
		INTO tax;
		
		IF(reca.tax_type_id = 1)THEN 	---- PAYE
			UPDATE employee_adjustments SET amount = tax * .9
			WHERE (employee_month_id = $1) AND (adjustment_id = 15);
		END IF;
		
		IF(reca.tax_type_id = 3)THEN 	---- NHIF
			UPDATE employee_adjustments SET amount = tax * .75
			WHERE (employee_month_id = $1) AND (adjustment_id = 16);
		END IF;
		
		EXECUTE 'SELECT ' || reca.formural || ' FROM employee_tax_types WHERE employee_tax_type_id = ' || reca.employee_tax_type_id 
		INTO tax;

		UPDATE employee_tax_types SET amount = tax, employer = reca.employer + (tax * reca.employer_ps / 100)
		WHERE employee_tax_type_id = reca.employee_tax_type_id;
	END LOOP;

	RETURN tax;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION get_formula_adjustment(int, int, real) RETURNS float AS $$
DECLARE
	v_employee_month_id		integer;
	v_basic_pay				float;
	v_adjustment			float;
	v_prof_allowance		float;
BEGIN

	SELECT employee_month.employee_month_id, employee_month.basic_pay INTO v_employee_month_id, v_basic_pay
	FROM employee_month
	WHERE (employee_month.employee_month_id = $1);

	IF ($2 = 1) THEN
		v_adjustment := v_basic_pay * $3;
	ELSIF ($2 = 2) THEN
		SELECT amount INTO v_prof_allowance
		FROM employee_adjustments
		WHERE (employee_month_id = v_employee_month_id) AND (adjustment_id = 5);
		IF(v_prof_allowance is null) THEN v_prof_allowance := 0; END IF;
		
		v_adjustment := (v_basic_pay + v_prof_allowance) * $3;
	ELSE
		v_adjustment := 0;
	END IF;

	IF(v_adjustment is null) THEN
		v_adjustment := 0;
	END IF;

	RETURN v_adjustment;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_house_rent(integer) RETURNS double precision AS $$
	SELECT COALESCE(sum(amount), 0)
	FROM employee_adjustments
	WHERE (adjustment_id IN (41,42,43))
		AND (employee_adjustments.employee_month_id = $1);
$$ LANGUAGE SQL;

UPDATE departments SET department_account = dept_function,  function_code = dept_project;

CREATE VIEW vw_sun_ledger_trx AS
	SELECT org_id, period_id, end_date, entity_id,
		gl_payroll_account, description,
		department_account,  employee_id, function_code,
		description2, round(amount::numeric, 1) as gl_amount, debit_credit,
		(period_id::varchar || '.' || entity_id::varchar || '.' || COALESCE(gl_payroll_account, '')) as sun_ledger_id
	FROM 
	((SELECT vw_employee_month.org_id, vw_employee_month.period_id, vw_employee_month.end_date, vw_employee_month.entity_id,
		vw_employee_month.gl_payroll_account, 'Payroll' as description, 
		departments.department_account, vw_employee_month.employee_id, departments.function_code,
		to_char(vw_employee_month.start_date, 'Month YYYY') || ' - Basic Pay' as description2, 
		vw_employee_month.basic_pay as amount,
		'D' as debit_credit
	FROM vw_employee_month INNER JOIN departments ON vw_employee_month.department_id = departments.department_id)
	UNION
	(SELECT vw_employee_month.org_id, vw_employee_month.period_id, vw_employee_month.end_date, vw_employee_month.entity_id,
		vw_employee_month.employee_id, vw_employee_month.entity_name,
		'', '', '',
		to_char(vw_employee_month.start_date, 'Month YYYY') || ' - Netpay' as description2, 
		net_pay as amount,
		'C' as debit_credit
	FROM vw_employee_month)
	UNION
	(SELECT vw_employee_adjustments.org_id, vw_employee_adjustments.period_id, vw_employee_adjustments.end_date, vw_employee_adjustments.entity_id,
		vw_employee_adjustments.account_number, vw_employee_adjustments.adjustment_name, 
		vw_employee_adjustments.department_account, vw_employee_adjustments.employee_id, vw_employee_adjustments.function_code,
		to_char(vw_employee_adjustments.start_date, 'Month YYYY') || ' - ' || vw_employee_adjustments.adjustment_name as description2, 
			
		sum(vw_employee_adjustments.amount),
		'D' as debit_credit
	FROM vw_employee_adjustments
	WHERE (vw_employee_adjustments.visible = true) AND (vw_employee_adjustments.adjustment_type = 1)
	GROUP BY vw_employee_adjustments.org_id, vw_employee_adjustments.period_id, vw_employee_adjustments.end_date, vw_employee_adjustments.entity_id,
		vw_employee_adjustments.account_number, vw_employee_adjustments.adjustment_name, 
		vw_employee_adjustments.department_account, vw_employee_adjustments.employee_id, vw_employee_adjustments.function_code,
		vw_employee_adjustments.start_date)
	UNION
	(SELECT vw_employee_adjustments.org_id, vw_employee_adjustments.period_id, vw_employee_adjustments.end_date, vw_employee_adjustments.entity_id,
		vw_employee_adjustments.account_number, vw_employee_adjustments.adjustment_name, 
		vw_employee_adjustments.department_account, vw_employee_adjustments.employee_id, vw_employee_adjustments.function_code,
		to_char(vw_employee_adjustments.start_date, 'Month YYYY') || ' - ' || vw_employee_adjustments.adjustment_name as description2, 
			
		sum(vw_employee_adjustments.amount),
		'C' as debit_credit
	FROM vw_employee_adjustments
	WHERE (vw_employee_adjustments.visible = true) AND (vw_employee_adjustments.adjustment_type = 2)
	GROUP BY vw_employee_adjustments.org_id, vw_employee_adjustments.period_id, vw_employee_adjustments.end_date, vw_employee_adjustments.entity_id,
		vw_employee_adjustments.account_number, vw_employee_adjustments.adjustment_name, 
		vw_employee_adjustments.department_account, vw_employee_adjustments.employee_id, vw_employee_adjustments.function_code,
		vw_employee_adjustments.start_date)
	UNION
	(SELECT vw_employee_tax_types.org_id, vw_employee_tax_types.period_id, vw_employee_tax_types.end_date, vw_employee_tax_types.entity_id,
		vw_employee_tax_types.account_number, vw_employee_tax_types.tax_type_name,
		vw_employee_tax_types.department_account, vw_employee_tax_types.employee_id, vw_employee_tax_types.function_code,
		to_char(vw_employee_tax_types.start_date, 'Month YYYY') || ' - ' || vw_employee_tax_types.tax_type_name || ' - Deduction',
		(vw_employee_tax_types.amount + vw_employee_tax_types.additional + vw_employee_tax_types.employer),
		'C' as debit_credit
	FROM vw_employee_tax_types)
	UNION
	(SELECT vw_employee_tax_types.org_id, vw_employee_tax_types.period_id, vw_employee_tax_types.end_date, vw_employee_tax_types.entity_id,
		vw_employee_tax_types.employer_account, vw_employee_tax_types.tax_type_name,
		vw_employee_tax_types.department_account, vw_employee_tax_types.employee_id, vw_employee_tax_types.function_code,
		to_char(vw_employee_tax_types.start_date, 'Month YYYY') || ' - ' || vw_employee_tax_types.tax_type_name || ' - Contribution',
		vw_employee_tax_types.employer,
		'D' as debit_credit
	FROM vw_employee_tax_types
	WHERE vw_employee_tax_types.employer > 0)
	UNION
	(SELECT vw_employee_month.org_id, vw_employee_month.period_id, vw_employee_month.end_date, vw_employee_month.entity_id,
		vw_employee_month.employee_id, vw_employee_month.entity_name,
		'', '', '',
		to_char(vw_employee_month.start_date, 'Month YYYY') || ' - Payroll Banking' as description2, 
		banked as amount,
		'D' as debit_credit
	FROM vw_employee_month)
	UNION
	(SELECT vw_employee_month.org_id, vw_employee_month.period_id, vw_employee_month.end_date, vw_employee_month.entity_id,
		vw_employee_month.gl_bank_account, 'Bank Account',
		'', '', '',
		to_char(vw_employee_month.start_date, 'Month YYYY') || ' - Payroll Banking' as description2, 
		banked as amount,
		'C' as debit_credit
	FROM vw_employee_month)) as a
	WHERE amount > 0;
	

