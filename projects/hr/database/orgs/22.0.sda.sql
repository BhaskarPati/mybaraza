

UPDATE adjustments SET formural =  null;

DELETE FROM adjustments WHERE adjustment_id = 1;
DELETE FROM adjustments WHERE adjustment_id = 2;


INSERT INTO adjustments (adjustment_type, adjustment_id, adjustment_name, visible, in_tax, monthly_update, org_id) VALUES (1, 1, 'NHIF Allowance', true, true, false, 2);
INSERT INTO adjustments (adjustment_type, adjustment_id, adjustment_name, visible, in_tax, monthly_update, org_id) VALUES (1, 2, 'PAYE Allowance', true, true, false, 2);
UPDATE adjustments SET currency_id = 5 WHERE currency_id is null;


INSERT INTO default_adjustments (entity_id, adjustment_id, org_id)
SELECT entity_id, 1, 2
FROM employees WHERE contract = false;
INSERT INTO default_adjustments (entity_id, adjustment_id, org_id)
SELECT entity_id, 2, 2
FROM employees WHERE contract = false;


UPDATE tax_types SET formural = 'Get_Employee_Tax(employee_tax_type_id, 1)', employer_ps = 0 WHERE tax_type_id = 9;
UPDATE tax_types SET formural = 'Get_Employee_Tax(employee_tax_type_id, 1)', employer_ps = 100 WHERE tax_type_id = 10;
UPDATE tax_types SET formural = 'Get_Employee_Tax(employee_tax_type_id, 2)', employer_ps = 0 WHERE tax_type_id = 8;
UPDATE tax_types SET formural = 'Get_Employee_Tax(employee_tax_type_id, 2)', employer_ps = 0 WHERE tax_type_id = 11;


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

	PERFORM updTax(employee_month_id, Period_id)
	FROM employee_month
	WHERE (period_id = v_period_id);

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
		WHERE (adjustment_id < 4)
			AND (employee_adjustments.employee_month_id = employee_month.employee_month_id) 
			AND (employee_month.period_id = CAST($1 as int));
			
		UPDATE employee_adjustments SET tax_reduction_amount = 0 
		FROM employee_month 
		WHERE (employee_adjustments.employee_month_id = employee_month.employee_month_id) 
			AND (employee_month.period_id = CAST($1 as int));
	
		PERFORM updTax(employee_month_id, period_id)
		FROM employee_month
		WHERE (period_id = CAST($1 as int));
		
		msg := 'Payroll Processed';
	ELSIF ($3 = '2') THEN
		UPDATE periods SET entity_id = CAST($2 as int), approve_status = 'Completed'
		WHERE (period_id = CAST($1 as int));

		msg := 'Application for approval';
	END IF;

	return msg;
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
	reca 				RECORD;
	income 				REAL;
	tax 				REAL;
	InsuranceRelief 	REAL;
BEGIN

	FOR reca IN SELECT employee_tax_types.employee_tax_type_id, employee_tax_types.tax_type_id, period_tax_types.formural,
			 period_tax_types.employer, period_tax_types.employer_ps
		FROM employee_tax_types INNER JOIN period_tax_types ON (employee_tax_types.tax_type_id = period_tax_types.tax_type_id)
		WHERE (employee_month_id = $1) AND (Period_Tax_Types.Period_ID = $2)
		ORDER BY Period_Tax_Types.Tax_Type_order LOOP

		EXECUTE 'SELECT ' || reca.formural || ' FROM employee_tax_types WHERE employee_tax_type_id = ' || reca.employee_tax_type_id 
		INTO tax;
		
		IF(reca.tax_type_id = 8)THEN 	---- PAYE
			UPDATE employee_adjustments SET amount = tax * .9
			WHERE (employee_month_id = $1) AND (adjustment_id = 2);
		END IF;

		UPDATE employee_tax_types SET amount = tax, employer = reca.employer + (tax * reca.employer_ps / 100)
		WHERE employee_tax_type_id = reca.employee_tax_type_id;
	END LOOP;

	RETURN tax;
END;
$$ LANGUAGE plpgsql;



DROP VIEW vw_employee_tax_month;
CREATE VIEW vw_employee_tax_month AS
	SELECT emp.period_id, emp.start_date, emp.end_date, emp.overtime_rate, 
		emp.activated, emp.closed, emp.month_id, emp.period_year, emp.period_month,
		emp.quarter, emp.semister, emp.bank_header, emp.bank_address,
		emp.gl_payroll_account, emp.gl_bank_account, emp.is_posted,
		emp.bank_id, emp.bank_name, emp.bank_branch_id, 
		emp.bank_branch_name, emp.bank_branch_code,
		emp.pay_group_id, emp.pay_group_name, emp.department_id, emp.department_name,
		emp.department_role_id, emp.department_role_name, 
		emp.entity_id, emp.entity_name,
		emp.employee_id, emp.surname, emp.first_name, emp.middle_name, emp.date_of_birth, 
		emp.gender, emp.nationality, emp.marital_status, emp.appointment_date, emp.exit_date, 
		emp.contract, emp.contract_period, emp.employment_terms, emp.identity_card,
		emp.employee_name,
		emp.currency_id, emp.currency_name, emp.currency_symbol, emp.exchange_rate,
		
		emp.org_id, emp.employee_month_id, emp.bank_account, emp.basic_pay, emp.details,
		emp.overtime, emp.full_allowance, emp.payroll_allowance, emp.tax_allowance,
		emp.full_deduction, emp.payroll_deduction, emp.tax_deduction, emp.full_expense,
		emp.payroll_expense, emp.tax_expense, emp.payroll_tax, emp.tax_tax,
		emp.net_adjustment, emp.per_diem, emp.advance, emp.advance_deduction,
		emp.net_pay, emp.banked, emp.cost,
		
		tax_types.tax_type_id, tax_types.tax_type_name, tax_types.account_id, 
		employee_tax_types.employee_tax_type_id, employee_tax_types.tax_identification, 
		employee_tax_types.amount, employee_tax_types.exchange_rate as tax_exchange_rate,
		employee_tax_types.additional, employee_tax_types.employer, employee_tax_types.narrative,
		
		(employee_tax_types.amount * employee_tax_types.exchange_rate) as tax_base_amount,
		
		(CASE WHEN (emp.contract = true) THEN 'Primary Employee' ELSE 'Contarct Employee') as contract_status,
		(CASE WHEN (emp.nationality = 'KE') THEN 'Resident' ELSE 'Foreigner' END) as residential_status


	FROM vw_employee_month as emp INNER JOIN employee_tax_types ON emp.employee_month_id = employee_tax_types.employee_month_id
		INNER JOIN tax_types ON employee_tax_types.tax_type_id = tax_types.tax_type_id;
		
		
		