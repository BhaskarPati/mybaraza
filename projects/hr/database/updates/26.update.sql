CREATE TABLE pensions (
	pension_id 				serial primary key,
	entity_id				integer references entitys,
	adjustment_id			integer references adjustments,
	contribution_id			integer references adjustments,
	org_id					integer references orgs,
	
	pension_company			varchar(50) not null,
	pension_number			varchar(50),
	active					boolean default true,
	
	amount					float default 0 not null,
	use_formura				boolean default false not null,
	
	employer_ps				float default 0 not null,
	employer_amount			float default 0 not null,
	employer_formural		boolean default false not null,
	
	details					text
);
CREATE INDEX pension_entity_id ON pensions (entity_id);
CREATE INDEX pension_adjustment_id ON pensions (adjustment_id);
CREATE INDEX pension_contribution_id ON pensions (contribution_id);
CREATE INDEX pension_org_id ON pensions (org_id);

ALTER TABLE employee_adjustments ADD 	pension_id				integer references pensions;
CREATE INDEX employee_adjustments_pension_id ON employee_adjustments (pension_id);

ALTER TABLE tax_types ADD 	tax_type_number			varchar(50);
ALTER TABLE tax_types ADD 	employer_account		varchar(32);

ALTER TABLE periods ADD 	gl_advance_account		varchar(32);

ALTER TABLE applicants ADD applicant_phone varchar(50);

ALTER TABLE skills ADD 	state_skill				varchar(50);

INSERT INTO skill_category (org_id, skill_category_id, skill_category_name, details) VALUES (0, 0, 'Others', NULL);
INSERT INTO skill_types (org_id, skill_type_id, skill_category_id, skill_type_name) VALUES (0, 0, 0, 'Indicate Your Skill');

ALTER TABLE departments ADD  department_account		varchar(50);
ALTER TABLE departments ADD  function_code			varchar(50);
UPDATE departments SET department_account = dept_function,  function_code = dept_project;

DROP VIEW vw_intern_evaluations;
DROP VIEW vw_applicants;	
DROP VIEW vw_employees;
DROP VIEW vw_payroll_ledger;
DROP VIEW vw_payroll_ledger_trx;
DROP VIEW vw_employee_per_diem_ledger;
DROP VIEW vw_employee_overtime;
DROP VIEW vw_employee_per_diem;
DROP VIEW vw_employee_banking;
DROP VIEW vw_advance_deductions;
DROP VIEW vw_advance_statement;
DROP VIEW vw_employee_advances;
DROP VIEW vw_employee_adjustments;
DROP VIEW vw_employee_tax_types;
DROP VIEW vw_default_tax_types;
DROP VIEW vw_period_tax_types;
DROP VIEW vw_tax_types;
DROP VIEW vw_employee_month_list;
DROP VIEW vw_skills;

CREATE VIEW vw_skills AS
	SELECT vw_skill_types.skill_category_id, vw_skill_types.skill_category_name, vw_skill_types.skill_type_id, 
		vw_skill_types.basic, vw_skill_types.intermediate, vw_skill_types.advanced, 
		entitys.entity_id, entitys.entity_name, skills.skill_id, skills.skill_level, skills.aquired, skills.training_date, 
		skills.org_id, skills.trained, skills.training_institution, skills.training_cost, skills.details,
		
		(CASE WHEN vw_skill_types.skill_type_id = 0 THEN skills.state_skill
			ELSE vw_skill_types.skill_type_name END) as skill_type_name,
		
		(CASE WHEN skill_level = 1 THEN 'Basic' WHEN skill_level = 2 THEN 'Intermediate' 
			WHEN skill_level = 3 THEN 'Advanced' ELSE 'None' END) as skill_level_name,
		(CASE WHEN skill_level = 1 THEN vw_skill_types.Basic WHEN skill_level = 2 THEN vw_skill_types.Intermediate 
			WHEN skill_level = 3 THEN vw_skill_types.Advanced ELSE 'None' END) as skill_level_details
	FROM skills INNER JOIN entitys ON skills.entity_id = entitys.entity_id
		INNER JOIN vw_skill_types ON skills.skill_type_id = vw_skill_types.skill_type_id;

CREATE VIEW vw_tax_types AS
	SELECT vw_accounts.account_type_id, vw_accounts.account_type_name, vw_accounts.account_id, vw_accounts.account_name, 
		currency.currency_id, currency.currency_name, currency.currency_symbol,
		tax_types.org_id, tax_types.tax_type_id, tax_types.tax_type_name, tax_types.formural, tax_types.tax_relief, 
		tax_types.tax_type_order, tax_types.in_tax, tax_types.tax_rate, tax_types.tax_inclusive, tax_types.linear, 
		tax_types.percentage, tax_types.employer, tax_types.employer_ps, tax_types.account_number, 
		tax_types.employer_account, tax_types.active, 
		tax_types.tax_type_number, tax_types.use_key, tax_types.details
	FROM tax_types INNER JOIN currency ON tax_types.currency_id = currency.currency_id
		LEFT JOIN vw_accounts ON tax_types.account_id = vw_accounts.account_id;

CREATE VIEW vw_period_tax_types AS
	SELECT vw_periods.period_id, vw_periods.start_date, vw_periods.end_date, vw_periods.overtime_rate,  
		vw_periods.activated, vw_periods.closed, vw_periods.month_id, vw_periods.period_year, vw_periods.period_month,
		vw_periods.quarter, vw_periods.semister,
		tax_types.tax_type_id, tax_types.tax_type_name, period_tax_types.period_tax_type_id, tax_types.tax_type_number,
		period_tax_types.period_tax_type_name, tax_types.use_key,
		period_tax_types.org_id, period_tax_types.Pay_Date, period_tax_types.tax_relief, period_tax_types.linear, period_tax_types.percentage, 
		period_tax_types.formural, period_tax_types.details
	FROM period_tax_types INNER JOIN vw_periods ON period_tax_types.period_id = vw_periods.period_id
		INNER JOIN tax_types ON period_tax_types.tax_type_id = tax_types.tax_type_id;
		
CREATE VIEW vw_default_tax_types AS
	SELECT entitys.entity_id, entitys.entity_name, 
		vw_tax_types.tax_type_id, vw_tax_types.tax_type_name, vw_tax_types.tax_type_number,
		vw_tax_types.currency_id, vw_tax_types.currency_name, vw_tax_types.currency_symbol,
		default_tax_types.default_tax_type_id, 
		default_tax_types.org_id, default_tax_types.tax_identification, default_tax_types.active, default_tax_types.narrative
	FROM default_tax_types INNER JOIN entitys ON default_tax_types.entity_id = entitys.entity_id
		INNER JOIN vw_tax_types ON default_tax_types.tax_type_id = vw_tax_types.tax_type_id;

CREATE VIEW vw_employee_month_list AS
	SELECT vw_periods.period_id, vw_periods.start_date, vw_periods.end_date, vw_periods.overtime_rate, 
		vw_periods.activated, vw_periods.closed, vw_periods.month_id, vw_periods.period_year, vw_periods.period_month,
		vw_periods.quarter, vw_periods.semister, vw_periods.bank_header, vw_periods.bank_address,
		vw_periods.gl_payroll_account, vw_periods.gl_bank_account, vw_periods.is_posted, 
		entitys.entity_id, entitys.entity_name,
		employees.employee_id, employees.surname, employees.first_name, employees.middle_name, employees.date_of_birth, 
		employees.gender, employees.nationality, employees.marital_status, employees.appointment_date, employees.exit_date, 
		employees.contract, employees.contract_period, employees.employment_terms, employees.identity_card,
		(employees.Surname || ' ' || employees.First_name || ' ' || COALESCE(employees.Middle_name, '')) as employee_name,
		departments.department_id, departments.department_name, departments.department_account, departments.function_code,
		department_roles.department_role_id, department_roles.department_role_name,
		employee_month.pay_group_id,
		employee_month.org_id, employee_month.employee_month_id, employee_month.bank_account, employee_month.basic_pay
		
	FROM employee_month INNER JOIN vw_periods ON employee_month.period_id = vw_periods.period_id
		INNER JOIN entitys ON employee_month.entity_id = entitys.entity_id
		INNER JOIN employees ON employee_month.entity_id = employees.entity_id
		INNER JOIN department_roles ON employee_month.department_role_id = department_roles.department_role_id
		INNER JOIN departments ON department_roles.department_id = departments.department_id;
		
CREATE VIEW vw_employee_tax_types AS
	SELECT eml.employee_month_id, eml.period_id, eml.start_date, 
		eml.month_id, eml.period_year, eml.period_month,
		eml.end_date, eml.gl_payroll_account,
		eml.entity_id, eml.entity_name, eml.employee_id, eml.identity_card,
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
		eml.entity_id, eml.entity_name, eml.employee_id,
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
		
CREATE VIEW vw_employee_advances AS
	SELECT eml.employee_month_id, eml.period_id, eml.start_date, eml.end_date,
		eml.month_id, eml.period_year, eml.period_month, 
		eml.gl_payroll_account, eml.gl_bank_account,
		eml.entity_id, eml.entity_name, eml.employee_id,
		employee_advances.org_id, employee_advances.employee_advance_id, employee_advances.pay_date, employee_advances.pay_period, 
		employee_advances.Pay_upto, employee_advances.amount, employee_advances.in_payroll, employee_advances.completed, 
		employee_advances.approve_status, employee_advances.Action_date, employee_advances.narrative
	FROM employee_advances INNER JOIN vw_employee_month_list as eml ON employee_advances.employee_month_id = eml.employee_month_id;

CREATE VIEW vw_advance_deductions AS
	SELECT eml.employee_month_id, eml.period_id, eml.start_date, eml.end_date,
		eml.month_id, eml.period_year, eml.period_month,
		eml.gl_payroll_account, eml.gl_bank_account,
		eml.entity_id, eml.entity_name, eml.employee_id,
		advance_deductions.org_id, advance_deductions.advance_deduction_id, advance_deductions.pay_date, advance_deductions.amount, 
		advance_deductions.in_payroll, advance_deductions.narrative
	FROM advance_deductions INNER JOIN vw_employee_month_list as eml ON advance_deductions.employee_month_id = eml.employee_month_id;

CREATE VIEW vw_advance_statement AS
	(SELECT eml.employee_month_id, eml.period_id, eml.start_date, 
		eml.month_id, eml.period_year, eml.period_month,
		eml.entity_id, eml.entity_name, eml.employee_id,
		employee_advances.org_id, employee_advances.pay_date, employee_advances.in_payroll, employee_advances.narrative,
		employee_advances.amount, cast(0 as real) as recovery
	FROM employee_advances INNER JOIN vw_employee_month_list as eml ON employee_advances.employee_month_id = eml.employee_month_id
	WHERE (employee_advances.approve_status = 'Approved'))
	UNION
	(SELECT eml.employee_month_id, eml.period_id, eml.start_date, 
		eml.month_id, eml.period_year, eml.period_month,
		eml.entity_id, eml.entity_name, eml.employee_id,
		advance_deductions.org_id, advance_deductions.pay_date, advance_deductions.in_payroll, advance_deductions.narrative, 
		cast(0 as real), advance_deductions.amount
	FROM advance_deductions INNER JOIN vw_employee_month_list as eml ON advance_deductions.employee_month_id = eml.employee_month_id);

CREATE VIEW vw_employee_overtime AS
	SELECT eml.employee_month_id, eml.period_id, eml.start_date, 
		eml.month_id, eml.period_year, eml.period_month,
		eml.entity_id, eml.entity_name, eml.employee_id,
		employee_overtime.org_id, employee_overtime.employee_overtime_id, employee_overtime.overtime_date, employee_overtime.overtime, 
		employee_overtime.overtime_rate, employee_overtime.narrative, employee_overtime.approve_status, 
		employee_overtime.Action_date, employee_overtime.details
	FROM employee_overtime INNER JOIN vw_employee_month_list as eml ON employee_overtime.employee_month_id = eml.employee_month_id;

CREATE VIEW vw_employee_per_diem AS
	SELECT eml.employee_month_id, eml.period_id, eml.start_date, 
		eml.month_id, eml.period_year, eml.period_month,
		eml.entity_id, eml.entity_name, eml.employee_id,
		employee_per_diem.org_id, employee_per_diem.employee_per_diem_id, employee_per_diem.travel_date, employee_per_diem.return_date, employee_per_diem.days_travelled, 
		employee_per_diem.per_diem, employee_per_diem.cash_paid, employee_per_diem.tax_amount, employee_per_diem.full_amount,
		employee_per_diem.travel_to,  employee_per_diem.approve_status, employee_per_diem.action_date, 
		employee_per_diem.completed, employee_per_diem.post_account, employee_per_diem.details,
		(employee_per_diem.exchange_rate * employee_per_diem.tax_amount) as base_tax_amount, 
		(employee_per_diem.exchange_rate *  employee_per_diem.full_amount) as base_full_amount
	FROM employee_per_diem INNER JOIN vw_employee_month_list as eml ON employee_per_diem.employee_month_id = eml.employee_month_id;
	
CREATE VIEW vw_employee_banking AS
	SELECT eml.employee_month_id, eml.period_id, eml.start_date, 
		eml.month_id, eml.period_year, eml.period_month,
		eml.entity_id, eml.entity_name, eml.employee_id,
		eml.pay_group_id, eml.bank_Header, eml.bank_address,
		vw_bank_branch.bank_id, vw_bank_branch.bank_name, vw_bank_branch.bank_branch_id, 
		vw_bank_branch.bank_branch_name, vw_bank_branch.bank_branch_code,
		currency.currency_id, currency.currency_name, currency.currency_symbol,
		
		employee_banking.org_id, employee_banking.employee_banking_id, employee_banking.amount, 
		employee_banking.exchange_rate, employee_banking.active, employee_banking.bank_account,
		employee_banking.narrative,
		(employee_banking.exchange_rate * employee_banking.amount) as base_amount
	FROM employee_banking INNER JOIN vw_employee_month_list as eml ON employee_banking.employee_month_id = eml.employee_month_id
		INNER JOIN vw_bank_branch ON employee_banking.bank_branch_id = vw_bank_branch.bank_branch_id
		INNER JOIN currency ON employee_banking.currency_id = currency.currency_id;

CREATE VIEW vw_employee_per_diem_ledger AS
	(SELECT vw_employee_per_diem.org_id, vw_employee_per_diem.period_id, vw_employee_per_diem.travel_date, 'Transport' as description, 
		vw_employee_per_diem.post_account, vw_employee_per_diem.entity_name, vw_employee_per_diem.full_amount as dr_amt, 0.0 as cr_amt
	FROM vw_employee_per_diem
	WHERE (vw_employee_per_diem.approve_status = 'Approved'))
	UNION
	(SELECT vw_employee_per_diem.org_id, vw_employee_per_diem.period_id, vw_employee_per_diem.travel_date, 'Travel Petty Cash' as description, 
		'3305', vw_employee_per_diem.entity_name, 0.0 as dr_amt, cash_paid as cr_amt
	FROM vw_employee_per_diem
	WHERE (vw_employee_per_diem.approve_status = 'Approved'))
	UNION
	(SELECT  vw_employee_per_diem.org_id, vw_employee_per_diem.period_id, vw_employee_per_diem.travel_date, 'Transport PAYE' as description, 
		'4045', vw_employee_per_diem.entity_name, 0.0 as dr_amt, full_amount - cash_paid as cr_amt
	FROM vw_employee_per_diem
	WHERE (vw_employee_per_diem.approve_status = 'Approved'));
	
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
	

CREATE VIEW vw_pensions AS
	SELECT entitys.entity_id, entitys.entity_name,
		adjustments.adjustment_id, adjustments.adjustment_name, 
		pensions.contribution_id, contributions.adjustment_name as contribution_name, 
		pensions.org_id, pensions.pension_id, pensions.pension_company, pensions.pension_number, 
		pensions.amount, pensions.use_formura, pensions.employer_ps, pensions.employer_amount, 
		pensions.employer_formural, pensions.active, pensions.details
	FROM pensions INNER JOIN entitys ON pensions.entity_id = entitys.entity_id
		INNER JOIN adjustments ON pensions.adjustment_id = adjustments.adjustment_id
		INNER JOIN adjustments as contributions ON pensions.contribution_id = contributions.adjustment_id;
	

CREATE VIEW vw_employees AS
	SELECT vw_bank_branch.bank_id, vw_bank_branch.bank_name, vw_bank_branch.bank_branch_id, vw_bank_branch.bank_branch_name, 
		vw_bank_branch.bank_branch_code, vw_department_roles.department_id, vw_department_roles.department_name, 
		vw_department_roles.department_role_id, vw_department_roles.department_role_name, 
		locations.location_id, locations.location_name,
		currency.currency_id, currency.currency_name, currency.currency_symbol,
		sys_countrys.sys_country_name, nob.sys_country_name as birth_nation_name,  
		disability.disability_id, disability.disability_name,		
		employees.org_id, employees.entity_id, employees.employee_id, employees.surname, employees.first_name, employees.middle_name, 
		employees.person_title, employees.field_of_study,
		(employees.Surname || ' ' || employees.First_name || ' ' || COALESCE(employees.Middle_name, '')) as employee_name,
		employees.date_of_birth, employees.place_of_birth, employees.gender, 
		employees.nationality, employees.nation_of_birth, 
		employees.marital_status, employees.appointment_date, 
		employees.exit_date, employees.contract, employees.contract_period, employees.employment_terms, employees.identity_card, 
		employees.basic_salary, employees.bank_account, employees.language, employees.picture_file, employees.active, 
		employees.height, employees.weight, employees.blood_group, employees.allergies,
		employees.phone, employees.objective, employees.interests, employees.details, 
		to_char(age(employees.date_of_birth), 'YY') as employee_age,
		(CASE WHEN employees.gender = 'M' THEN 'Male' ELSE 'Female' END) as gender_name,
		(CASE WHEN employees.marital_status = 'M' THEN 'Married' ELSE 'Single' END) as marital_status_name,

		vw_education_max.education_class_name, vw_education_max.date_from, vw_education_max.date_to, 
		vw_education_max.name_of_school, vw_education_max.examination_taken, 
		vw_education_max.grades_obtained, vw_education_max.certificate_number
	FROM employees INNER JOIN vw_bank_branch ON employees.bank_branch_id = vw_bank_branch.bank_branch_id
		INNER JOIN vw_department_roles ON employees.department_role_id = vw_department_roles.department_role_id
		INNER JOIN locations ON employees.location_id = locations.location_id
		INNER JOIN currency ON employees.currency_id = currency.currency_id
		INNER JOIN sys_countrys ON employees.nationality = sys_countrys.sys_country_id		
		LEFT JOIN sys_countrys as nob ON employees.nation_of_birth = nob.sys_country_id
		LEFT JOIN disability ON employees.disability_id = disability.disability_id
		LEFT JOIN vw_education_max ON employees.entity_id = vw_education_max.entity_id;


CREATE VIEW vw_applicants AS
	SELECT sys_countrys.sys_country_id, sys_countrys.sys_country_name, applicants.entity_id, applicants.surname, 
		applicants.org_id, applicants.first_name, applicants.middle_name, applicants.date_of_birth, applicants.nationality, 
		applicants.identity_card, applicants.language, applicants.objective, applicants.interests, applicants.picture_file, applicants.details,
		applicants.person_title, applicants.field_of_study, applicants.applicant_email, applicants.applicant_phone, 
		(applicants.Surname || ' ' || applicants.First_name || ' ' || COALESCE(applicants.Middle_name, '')) as applicant_name,
		to_char(age(applicants.date_of_birth), 'YY') as applicant_age,
		(CASE WHEN applicants.gender = 'M' THEN 'Male' ELSE 'Female' END) as gender_name,
		(CASE WHEN applicants.marital_status = 'M' THEN 'Married' ELSE 'Single' END) as marital_status_name,

		vw_education_max.education_class_id, vw_education_max.education_class_name, 
		vw_education_max.education_id, vw_education_max.date_from, vw_education_max.date_to, 
		vw_education_max.name_of_school, vw_education_max.examination_taken,
		vw_education_max.grades_obtained, vw_education_max.certificate_number,
		
		vw_employment_max.employers_name, vw_employment_max.position_held,
		vw_employment_max.date_from as emp_date_from, vw_employment_max.date_to as emp_date_to, 
		vw_employment_max.employment_duration, vw_employment_max.employment_experince,
		round((date_part('year', vw_employment_max.employment_duration) + date_part('month', vw_employment_max.employment_duration)/12)::numeric, 1) as emp_duration,
		round((date_part('year', vw_employment_max.employment_experince) + date_part('month', vw_employment_max.employment_experince)/12)::numeric, 1) as emp_experince
		
	FROM applicants INNER JOIN sys_countrys ON applicants.nationality = sys_countrys.sys_country_id
		LEFT JOIN vw_education_max ON applicants.entity_id = vw_education_max.entity_id
		LEFT JOIN vw_employment_max ON applicants.entity_id = vw_employment_max.entity_id;

CREATE VIEW vw_intern_evaluations AS 
	SELECT vw_applicants.entity_id, vw_applicants.sys_country_name, vw_applicants.applicant_name, 
		vw_applicants.applicant_age, vw_applicants.gender_name, vw_applicants.marital_status_name, vw_applicants.language, 
		vw_applicants.objective, vw_applicants.interests, education.date_from, education.date_to, education.name_of_school, 
		education.examination_taken, vw_internships.department_id, vw_internships.department_name, 
		vw_internships.internship_id, vw_internships.positions, vw_internships.opening_date, vw_internships.closing_date, 

		interns.intern_id, interns.payment_amount, interns.start_date, interns.end_date, interns.application_date, 
		interns.approve_status, interns.action_date, interns.workflow_table_id, interns.applicant_comments, interns.review
	FROM vw_applicants JOIN education ON vw_applicants.entity_id = education.entity_id
		JOIN interns ON interns.entity_id = vw_applicants.entity_id
		JOIN vw_internships ON interns.internship_id = vw_internships.internship_id
		JOIN (SELECT education.entity_id, max(education.education_class_id) AS mx_class_id FROM education
			WHERE education.entity_id IS NOT NULL
			GROUP BY education.entity_id) a ON education.entity_id = a.entity_id AND education.education_class_id = a.mx_class_id
		WHERE education.education_class_id > 6
		ORDER BY vw_applicants.entity_id;
		
CREATE OR REPLACE VIEW vw_review_year AS
	SELECT vw_job_reviews.org_id, vw_job_reviews.review_year
	FROM vw_job_reviews
	WHERE vw_job_reviews.review_year is not null
	GROUP BY vw_job_reviews.org_id, vw_job_reviews.review_year;
	
CREATE OR REPLACE VIEW vw_objective_year AS
	SELECT vw_employee_objectives.org_id, vw_employee_objectives.objective_year
	FROM vw_employee_objectives
	WHERE vw_employee_objectives.objective_year is not null
	GROUP BY vw_employee_objectives.org_id, vw_employee_objectives.objective_year;

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
	
CREATE VIEW vw_pension_adjustments AS
	SELECT c.period_id, c.start_date,
		a.employee_adjustment_id, a.employee_month_id, a.adjustment_id, a.pension_id, 
		a.org_id, a.adjustment_type, a.adjustment_factor, a.pay_date, a.amount, 
		a.exchange_rate, a.in_payroll, a.in_tax, a.visible,
		(a.amount * a.exchange_rate) as base_amount
	FROM employee_adjustments as a INNER JOIN employee_month as b ON a.employee_month_id = b.employee_month_id
		INNER JOIN periods as c ON b.period_id = c.period_id
	WHERE (a.pension_id is not null);

CREATE VIEW vw_employee_pensions AS
	SELECT a.entity_id, a.entity_name, a.adjustment_id, a.adjustment_name, a.contribution_id, 
		a.contribution_name, a.org_id, a.pension_id, a.pension_company, a.pension_number, 
		a.active,
		b.period_id, b.start_date, b.employee_month_id, 
		b.amount, b.base_amount,
		COALESCE(c.amount, 0) as employer_amount, 
		COALESCE(c.base_amount, 0) as employer_base_amount,
		(b.amount + COALESCE(c.amount, 0)) as pension_amount, 
		(b.base_amount + COALESCE(c.base_amount, 0)) as pension_base_amount
	FROM (vw_pensions as a INNER JOIN vw_pension_adjustments as b 
		ON (a.pension_id = b.pension_id) AND (a.adjustment_id = b.adjustment_id))
		LEFT JOIN vw_pension_adjustments as c
		ON (a.pension_id = c.pension_id) AND (a.contribution_id = c.adjustment_id)
		AND (b.employee_month_id = c.employee_month_id);	


--- Loans views
DROP VIEW vw_loan_projection;
DROP VIEW vw_period_loans;
DROP VIEW vw_loan_payments;
DROP VIEW vw_loan_monthly;
DROP VIEW vw_loans;
DROP VIEW vw_loan_types;

CREATE VIEW vw_loan_types AS
	SELECT adjustments.adjustment_id, adjustments.adjustment_name, adjustments.account_number,
		currency.currency_id, currency.currency_name, currency.currency_symbol,
		loan_types.org_id, loan_types.loan_type_id, loan_types.loan_type_name, 
		loan_types.default_interest, loan_types.reducing_balance, loan_types.details
	FROM loan_types INNER JOIN adjustments ON loan_types.adjustment_id = adjustments.adjustment_id
		INNER JOIN currency ON adjustments.currency_id = currency.currency_id;

CREATE VIEW vw_loans AS
	SELECT vw_loan_types.adjustment_id, vw_loan_types.adjustment_name, vw_loan_types.account_number,
		vw_loan_types.currency_id, vw_loan_types.currency_name, vw_loan_types.currency_symbol,
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
	SELECT  vw_loans.adjustment_id, vw_loans.adjustment_name, vw_loans.account_number,
		vw_loans.currency_id, vw_loans.currency_name, vw_loans.currency_symbol,
		vw_loans.loan_type_id, vw_loans.loan_type_name, 
		vw_loans.entity_id, vw_loans.entity_name, vw_loans.loan_date,
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
		vw_loans.entity_id, vw_loans.entity_name, vw_loans.loan_date,
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
		
CREATE OR REPLACE FUNCTION get_leave_approved_balance(integer, integer) RETURNS real AS $$
DECLARE
	reca					RECORD;
	v_months				integer;
	v_leave_starting		date;
	v_leave_carryover		real;
	v_leave_balance			real;
	v_leave_days			real;
	v_leave_work_days		real;
	v_leave_initial			real;
	v_year_leave			real;
BEGIN

	SELECT allowed_leave_days, month_quota, initial_days, maximum_carry 
		INTO reca
	FROM leave_types
	WHERE (leave_type_id = $2);

	SELECT leave_balance, leave_starting INTO v_leave_carryover, v_leave_starting
	FROM employee_leave_types
	WHERE (entity_id = $1) AND (leave_type_id = $2);
	IF(v_leave_carryover is null) THEN v_leave_carryover := 0; END IF;
	IF(v_leave_carryover > reca.maximum_carry) THEN v_leave_carryover := reca.maximum_carry; END IF;
	IF(v_leave_starting is null) THEN v_leave_starting := current_date; END IF;

	v_months := EXTRACT(MONTH FROM CURRENT_TIMESTAMP) - 1;
	v_leave_balance := reca.initial_days + reca.month_quota * v_months;
	if(reca.month_quota = 0)THEN v_leave_balance := reca.allowed_leave_days; END IF;

	IF(reca.maximum_carry = 0)THEN
		SELECT sum(employee_leave.leave_days) INTO v_leave_days
		FROM employee_leave 
		WHERE (entity_id = $1) AND (leave_type_id = $2)
			AND (approve_status = 'Approved')
			AND (EXTRACT(YEAR FROM leave_from) = EXTRACT(YEAR FROM now()));
		IF(v_leave_days is null) THEN v_leave_days := 0; END IF;

		SELECT SUM(CASE WHEN leave_work_days.half_day = true THEN 0.5 ELSE 1 END) INTO v_leave_work_days
		FROM leave_work_days INNER JOIN employee_leave ON leave_work_days.employee_leave_id = employee_leave.employee_leave_id
		WHERE (employee_leave.entity_id = $1) AND (employee_leave.leave_type_id = $2)
			AND (leave_work_days.approve_status = 'Approved')
			AND (EXTRACT(YEAR FROM employee_leave.leave_from) = EXTRACT(YEAR FROM now()));
		IF(v_leave_work_days is null) THEN v_leave_work_days := 0; END IF;
		v_leave_days := v_leave_days - v_leave_work_days;

		IF(v_leave_balance > reca.allowed_leave_days) THEN v_leave_balance := reca.allowed_leave_days; END IF;
		v_leave_balance := v_leave_balance - v_leave_days;
	ELSE
		SELECT sum(employee_leave.leave_days) INTO v_leave_days
		FROM employee_leave 
		WHERE (entity_id = $1) AND (leave_type_id = $2)
			AND (approve_status = 'Approved');
		IF(v_leave_days is null) THEN v_leave_days := 0; END IF;
		
		SELECT sum(employee_leave.leave_days) INTO v_year_leave
		FROM employee_leave 
		WHERE (entity_id = $1) AND (leave_type_id = $2)
			AND (approve_status = 'Approved')
			AND (EXTRACT(YEAR FROM leave_from) = EXTRACT(YEAR FROM now()));
		IF(v_year_leave is null) THEN v_year_leave := 0; END IF;

		SELECT SUM(CASE WHEN leave_work_days.half_day = true THEN 0.5 ELSE 1 END) INTO v_leave_work_days
		FROM leave_work_days INNER JOIN employee_leave ON leave_work_days.employee_leave_id = employee_leave.employee_leave_id
		WHERE (employee_leave.entity_id = $1) AND (employee_leave.leave_type_id = $2)
			AND (leave_work_days.approve_status = 'Approved');
		IF(v_leave_work_days is null) THEN v_leave_work_days := 0; END IF;
		v_leave_days := v_leave_days - v_leave_work_days;
		
		v_leave_initial := v_leave_carryover + (EXTRACT(YEAR FROM now()) - EXTRACT(YEAR FROM v_leave_starting)) * reca.allowed_leave_days;
		IF(EXTRACT(MONTH FROM v_leave_starting) > 1)THEN
			v_leave_initial := v_leave_carryover + (EXTRACT(YEAR FROM now()) - EXTRACT(YEAR FROM v_leave_starting) - 1) * reca.allowed_leave_days;
			IF(reca.month_quota = 0)THEN v_leave_initial := v_leave_initial + (13 - EXTRACT(MONTH FROM v_leave_starting)) * reca.month_quota;
			ELSE v_leave_initial := v_leave_initial + reca.allowed_leave_days;
			END IF;
		END IF;
		v_leave_initial := v_leave_initial - (v_leave_days - v_year_leave);
		IF(v_leave_initial > reca.maximum_carry) THEN v_leave_initial := reca.maximum_carry; END IF;		
		v_leave_balance := v_leave_initial + v_leave_balance - v_year_leave;
	END IF;

	RETURN v_leave_balance;
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
		
		IF(rec.use_formura = true) AND (adj.formural != null)THEN
			EXECUTE 'SELECT ' || adj.formural || ' FROM employee_month WHERE employee_month_id = ' || v_employee_month_id
			INTO v_amount;
		ELSIF(rec.amount > 0)THEN
			v_amount := rec.amount;
		END IF;
		
		IF(v_employee_adjustment_id is null)THEN
			INSERT INTO employee_adjustments(employee_month_id, pension_id, org_id, 
				adjustment_id, adjustment_type, adjustment_factor, 
				in_payroll, in_tax, visible,
				exchange_rate, pay_date, amount)
			VALUES (v_employee_month_id, rec.pension_id, v_org_id,
				adj.adjustment_id, adj.adjustment_type, -1, 
				adj.in_payroll, adj.in_tax, adj.visible,
				1, current_date, v_amount);
		ELSE
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
			
			IF(rec.employer_formural = true) AND (adj.formural != null)THEN
				EXECUTE 'SELECT ' || adj.formural || ' FROM employee_month WHERE employee_month_id = ' || v_employee_month_id
				INTO v_amount;
			ELSIF(rec.employer_ps > 0)THEN
				v_amount := v_amount * rec.employer_ps / 100;
			ELSIF(rec.employer_amount > 0)THEN
				v_amount := rec.employer_amount;
			END IF;
			
			IF(v_employee_adjustment_id is null)THEN
				INSERT INTO employee_adjustments(employee_month_id, pension_id, org_id, 
					adjustment_id, adjustment_type, adjustment_factor, 
					in_payroll, in_tax, visible,
					exchange_rate, pay_date, amount)
				VALUES (v_employee_month_id, rec.pension_id, v_org_id,
					adj.adjustment_id, adj.adjustment_type, 1, 
					adj.in_payroll, adj.in_tax, adj.visible,
					1, current_date, v_amount);
			ELSE
				UPDATE employee_adjustments SET amount = v_amount
				WHERE employee_adjustment_id = v_employee_adjustment_id;
			END IF;
		END IF;
		
	END LOOP;

	msg := 'Pension Processed';

	RETURN msg;
END;
$$ LANGUAGE plpgsql;


CREATE VIEW vw_all_job_reviews AS
	SELECT a.org_id, a.review_year,  a.entity_id, a.employee_id, a.employee_name,
		b.job_review_id, b.total_points, b.approve_status
	FROM 
		(SELECT vw_review_year.review_year, employees.org_id, employees.entity_id,
			employees.employee_id, 
			(employees.Surname || ' ' || employees.First_name || ' ' || COALESCE(employees.Middle_name, '')) as employee_name
		FROM vw_review_year INNER JOIN employees ON vw_review_year.org_id = employees.org_id
		WHERE employees.active = true) as a
	LEFT JOIN
		(SELECT job_review_id, total_points, approve_status, entity_id, review_year
		FROM vw_job_reviews) as b
		
	ON (a.entity_id = b.entity_id) AND (a.review_year = b.review_year);
	
	
	
ALTER TABLE applicants ADD previous_salary			real;
ALTER TABLE applicants ADD expected_salary			real;

CREATE OR REPLACE FUNCTION ins_applications(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	v_application_id		integer;
	
	reca					RECORD;
	msg 					varchar(120);
BEGIN
	SELECT application_id INTO v_application_id
	FROM applications 
	WHERE (intake_id = $1::int) AND (entity_id = $2::int);
	
	SELECT org_id, entity_id, previous_salary, expected_salary INTO reca
	FROM applicants
	WHERE (entity_id = $2::int);

	IF(reca.entity_id is null) THEN
		SELECT org_id, entity_id, basic_salary as previous_salary, basic_salary as expected_salary INTO reca
		FROM employees
		WHERE (entity_id = $2::int);
	END IF;

	IF v_application_id is not null THEN
		msg := 'There is another application for the post.';
	ELSIF (reca.previous_salary is null) OR (reca.expected_salary is null) THEN
		msg := 'Kindly indicate your previous and expected salary';
	ELSE
		INSERT INTO applications (intake_id, org_id, entity_id, previous_salary, expected_salary, approve_status)
		VALUES ($1::int, reca.org_id, reca.entity_id, reca.previous_salary, reca.expected_salary, 'Completed');
		msg := 'Added Job application';
	END IF;

	return msg;
END;
$$ LANGUAGE plpgsql;


