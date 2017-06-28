
DROP VIEW vw_payroll_ledger_trx;
DROP VIEW vw_payroll_ledger;
DROP VIEW vw_sun_ledger_trx; 
DROP VIEW vw_employee_adjustments;
DROP VIEW vw_employee_tax_types;

CREATE VIEW vw_employee_tax_types AS
	SELECT eml.employee_month_id, eml.period_id, eml.start_date, 
		eml.month_id, eml.period_year, eml.period_month,
		eml.end_date, eml.gl_payroll_account,
		eml.entity_id, eml.entity_name, eml.employee_id, eml.identity_card,
		eml.surname, eml.first_name, eml.middle_name, eml.date_of_birth, 
		eml.department_id, eml.department_name, eml.department_account, eml.function_code,
		eml.department_role_id, eml.department_role_name,
		tax_types.tax_type_id, tax_types.tax_type_name, tax_types.account_id, tax_types.tax_type_number,
		tax_types.account_number, tax_types.employer_account,
		employee_tax_types.org_id, employee_tax_types.employee_tax_type_id, employee_tax_types.tax_identification, 
		employee_tax_types.amount, 
		employee_tax_types.additional, employee_tax_types.employer, employee_tax_types.narrative,
		currency.currency_id, currency.currency_name, currency.currency_symbol, employee_tax_types.exchange_rate,
		
		(employee_tax_types.exchange_rate * employee_tax_types.amount) as base_amount,
		(employee_tax_types.exchange_rate * employee_tax_types.employer) as base_employer,
		(employee_tax_types.exchange_rate * employee_tax_types.additional) as base_additional
		
	FROM employee_tax_types INNER JOIN vw_employee_month_list as eml ON employee_tax_types.employee_month_id = eml.employee_month_id
		INNER JOIN tax_types ON (employee_tax_types.tax_type_id = tax_types.tax_type_id)
		INNER JOIN currency ON tax_types.currency_id = currency.currency_id;


CREATE VIEW vw_employee_adjustments AS
	SELECT eml.employee_month_id, eml.period_id, eml.start_date, 
		eml.month_id, eml.period_year, eml.period_month,
		eml.end_date, 
		eml.entity_id, eml.entity_name, eml.employee_id, eml.identity_card,
		eml.department_id, eml.department_name, eml.department_account, eml.function_code,
		eml.department_role_id, eml.department_role_name,
		adjustments.adjustment_id, adjustments.adjustment_name, adjustments.adjustment_type, adjustments.account_number, 
		adjustments.earning_code,
		currency.currency_id, currency.currency_name, currency.currency_symbol,
		employee_adjustments.org_id, employee_adjustments.employee_adjustment_id, employee_adjustments.pay_date, employee_adjustments.amount, 
		employee_adjustments.in_payroll, employee_adjustments.in_tax, employee_adjustments.visible, employee_adjustments.exchange_rate,
		employee_adjustments.paid_amount, employee_adjustments.balance, employee_adjustments.narrative,
		employee_adjustments.tax_relief_amount,
		(employee_adjustments.exchange_rate * employee_adjustments.amount) as base_amount		
	FROM employee_adjustments INNER JOIN adjustments ON employee_adjustments.adjustment_id = adjustments.adjustment_id
		INNER JOIN vw_employee_month_list as eml ON employee_adjustments.employee_month_id = eml.employee_month_id
		INNER JOIN currency ON adjustments.currency_id = currency.currency_id;

		
CREATE VIEW vw_payroll_ledger_trx AS
	SELECT org_id, period_id, end_date, description, gl_payroll_account, entity_name, employee_id,
		dr_amt, cr_amt 
	FROM 
	((SELECT vw_employee_month.org_id, vw_employee_month.period_id, vw_employee_month.end_date, 'BASIC SALARY' as description, 
		vw_employee_month.gl_payroll_account, vw_employee_month.entity_name, vw_employee_month.employee_id,
		vw_employee_month.basic_pay as dr_amt, 0.0 as cr_amt
	FROM vw_employee_month)
	UNION
	(SELECT vw_employee_month.org_id, vw_employee_month.period_id, vw_employee_month.end_date, 'SALARY PAYMENTS',
		vw_employee_month.gl_bank_account, vw_employee_month.entity_name, vw_employee_month.employee_id,
		0.0 as sum_basic_pay, 
		vw_employee_month.banked as sum_banked
	FROM vw_employee_month)
	UNION
	(SELECT vw_employee_tax_types.org_id, vw_employee_tax_types.period_id, vw_employee_tax_types.end_date, vw_employee_tax_types.tax_type_name, 
		vw_employee_tax_types.account_number, vw_employee_tax_types.entity_name, vw_employee_tax_types.employee_id,
		0.0, 
		(vw_employee_tax_types.amount + vw_employee_tax_types.additional + vw_employee_tax_types.employer) 
	FROM vw_employee_tax_types)
	UNION
	(SELECT vw_employee_tax_types.org_id, vw_employee_tax_types.period_id, vw_employee_tax_types.end_date, 'Employer - ' || vw_employee_tax_types.tax_type_name, 
		vw_employee_tax_types.account_number, vw_employee_tax_types.entity_name, vw_employee_tax_types.employee_id,
		vw_employee_tax_types.employer, 0.0
	FROM vw_employee_tax_types
	WHERE (vw_employee_tax_types.employer <> 0))
	UNION
	(SELECT vw_employee_adjustments.org_id, vw_employee_adjustments.period_id, vw_employee_adjustments.end_date, vw_employee_adjustments.adjustment_name, vw_employee_adjustments.account_number, 
		vw_employee_adjustments.entity_name, vw_employee_adjustments.employee_id,
		SUM(CASE WHEN vw_employee_adjustments.adjustment_type = 1 THEN vw_employee_adjustments.amount - vw_employee_adjustments.paid_amount ELSE 0 END) as dr_amt,
		SUM(CASE WHEN vw_employee_adjustments.adjustment_type = 2 THEN vw_employee_adjustments.amount - vw_employee_adjustments.paid_amount ELSE 0 END) as cr_amt
	FROM vw_employee_adjustments
	WHERE (vw_employee_adjustments.visible = true) AND (vw_employee_adjustments.adjustment_type < 3)
	GROUP BY vw_employee_adjustments.org_id, vw_employee_adjustments.period_id, vw_employee_adjustments.end_date, vw_employee_adjustments.adjustment_name, vw_employee_adjustments.account_number, 
		vw_employee_adjustments.entity_name, vw_employee_adjustments.employee_id)
	UNION
	(SELECT vw_employee_per_diem.org_id, vw_employee_per_diem.period_id, vw_employee_per_diem.travel_date, 'Transport' as description, 
		vw_employee_per_diem.post_account, vw_employee_per_diem.entity_name, vw_employee_per_diem.employee_id,
		(vw_employee_per_diem.full_amount - vw_employee_per_diem.Cash_paid) as dr_amt, 0.0 as cr_amt
	FROM vw_employee_per_diem
	WHERE (vw_employee_per_diem.approve_status = 'Approved'))
	UNION
	(SELECT ea.org_id, ea.period_id, ea.end_date, 'SALARY ADVANCE' as description, 
		ea.gl_payroll_account, ea.entity_name, ea.employee_id,
		ea.amount as dr_amt, 
		0.0 as cr_amt
	FROM vw_employee_advances as ea
	WHERE (ea.in_payroll = true))
	UNION
	(SELECT ead.org_id, ead.period_id, ead.end_date, 'ADVANCE DEDUCTION' as description, 
		ead.gl_payroll_account, ead.entity_name, ead.employee_id,
		0.0 as dr_amt, 
		ead.amount as cr_amt
	FROM vw_advance_deductions as ead
	WHERE (ead.in_payroll = true))) as a
	ORDER BY gl_payroll_account desc, dr_amt desc, cr_amt desc;

CREATE VIEW vw_payroll_ledger AS
	SELECT org_id, period_id, end_date, description, gl_payroll_account, dr_amt, cr_amt 
	FROM 
	((SELECT vw_employee_month.org_id, vw_employee_month.period_id, vw_employee_month.end_date, 'BASIC SALARY' as description, 
		vw_employee_month.gl_payroll_account, 
		sum(vw_employee_month.basic_pay) as dr_amt, 
		0.0 as cr_amt
	FROM vw_employee_month
	GROUP BY vw_employee_month.org_id, vw_employee_month.period_id, vw_employee_month.end_date, vw_employee_month.gl_payroll_account)
	UNION
	(SELECT vw_employee_month.org_id, vw_employee_month.period_id, vw_employee_month.end_date, 'SALARY PAYMENTS',
		vw_employee_month.gl_bank_account, 0.0 as sum_basic_pay, sum(vw_employee_month.banked) as sum_banked
	FROM vw_employee_month
	GROUP BY vw_employee_month.org_id, vw_employee_month.period_id, vw_employee_month.end_date, vw_employee_month.gl_bank_account)
	UNION
	(SELECT vw_employee_tax_types.org_id, vw_employee_tax_types.period_id, vw_employee_tax_types.end_date, vw_employee_tax_types.tax_type_name, 
		vw_employee_tax_types.account_number, 0.0, 
		sum(vw_employee_tax_types.amount + vw_employee_tax_types.additional + vw_employee_tax_types.employer) 
	FROM vw_employee_tax_types
	GROUP BY vw_employee_tax_types.org_id, vw_employee_tax_types.period_id, vw_employee_tax_types.end_date, vw_employee_tax_types.tax_type_name, 
		vw_employee_tax_types.account_number)
	UNION
	(SELECT vw_employee_tax_types.org_id, vw_employee_tax_types.period_id, vw_employee_tax_types.end_date, 'Employer - ' || vw_employee_tax_types.tax_type_name, 
		vw_employee_tax_types.account_number, SUM(vw_employee_tax_types.employer), 0.0
	FROM vw_employee_tax_types
	WHERE (vw_employee_tax_types.employer <> 0)
	GROUP BY vw_employee_tax_types.org_id, vw_employee_tax_types.period_id, vw_employee_tax_types.end_date, vw_employee_tax_types.tax_type_name,
		vw_employee_tax_types.account_number)
	UNION
	(SELECT vw_employee_adjustments.org_id, vw_employee_adjustments.period_id, vw_employee_adjustments.end_date, vw_employee_adjustments.adjustment_name, vw_employee_adjustments.account_number, 
		SUM(CASE WHEN vw_employee_adjustments.adjustment_type = 1 THEN vw_employee_adjustments.amount - vw_employee_adjustments.paid_amount ELSE 0 END) as dr_amt,
		SUM(CASE WHEN vw_employee_adjustments.adjustment_type = 2 THEN vw_employee_adjustments.amount - vw_employee_adjustments.paid_amount ELSE 0 END) as cr_amt
	FROM vw_employee_adjustments
	WHERE (vw_employee_adjustments.in_payroll = true) AND (vw_employee_adjustments.visible = true) AND (vw_employee_adjustments.adjustment_type < 3)
	GROUP BY vw_employee_adjustments.org_id, vw_employee_adjustments.period_id, vw_employee_adjustments.end_date, vw_employee_adjustments.adjustment_name, 
		vw_employee_adjustments.account_number, vw_employee_adjustments.adjustment_type)
	UNION
	(SELECT vw_employee_per_diem.org_id, vw_employee_per_diem.period_id, vw_employee_per_diem.travel_date, 'Transport' as description, 
		vw_employee_per_diem.post_account, 
		sum(vw_employee_per_diem.full_amount - vw_employee_per_diem.Cash_paid) as dr_amt, 0.0 as cr_amt
	FROM vw_employee_per_diem
	WHERE (vw_employee_per_diem.approve_status = 'Approved')
	GROUP BY vw_employee_per_diem.org_id, vw_employee_per_diem.period_id, vw_employee_per_diem.travel_date, vw_employee_per_diem.post_account)
	UNION
	(SELECT ea.org_id, ea.period_id, ea.end_date, 'SALARY ADVANCE' as description, 
		ea.gl_payroll_account, 
		sum(ea.amount) as dr_amt, 
		0.0 as cr_amt
	FROM vw_employee_advances as ea
	WHERE (ea.in_payroll = true)
	GROUP BY ea.org_id, ea.period_id, ea.end_date, ea.gl_payroll_account)
	UNION
	(SELECT ead.org_id, ead.period_id, ead.end_date, 'ADVANCE DEDUCTION' as description, 
		ead.gl_payroll_account, 
		0.0 as dr_amt, 
		sum(ead.amount) as cr_amt
	FROM vw_advance_deductions as ead
	WHERE (ead.in_payroll = true)
	GROUP BY ead.org_id, ead.period_id, ead.end_date, ead.gl_payroll_account)) as a
	ORDER BY gl_payroll_account desc, dr_amt desc, cr_amt desc;
	
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
	ORDER BY gl_payroll_account desc, amount desc, debit_credit desc;
