ALTER TABLE default_banking 
ADD	bank_account			varchar(64);

DROP VIEW vw_default_banking;
CREATE VIEW vw_default_banking AS
	SELECT entitys.entity_id, entitys.entity_name, 
		vw_bank_branch.bank_id, vw_bank_branch.bank_name, vw_bank_branch.bank_branch_id, 
		vw_bank_branch.bank_branch_name, vw_bank_branch.bank_branch_code,
		currency.currency_id, currency.currency_name, currency.currency_symbol,
		default_banking.org_id, default_banking.default_banking_id, default_banking.amount, 
		default_banking.ps_amount, default_banking.final_date, default_banking.active, default_banking.narrative
	FROM default_banking INNER JOIN entitys ON default_banking.entity_id = entitys.entity_id
		INNER JOIN vw_bank_branch ON default_banking.bank_branch_id = vw_bank_branch.bank_branch_id
		INNER JOIN currency ON default_banking.currency_id = currency.currency_id;

	
ALTER TABLE applications
ADD	previous_salary			real,
ADD	expected_salary			real,
ADD	review_rating			integer;

CREATE OR REPLACE FUNCTION ins_applications(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	v_entity_id				integer;
	v_application_id		integer;
	v_address				integer;
	c_education_id			integer;
	c_referees				integer;
	reca					RECORD;
	msg 					varchar(120);
BEGIN
	SELECT application_id INTO v_application_id
	FROM applications 
	WHERE (intake_id = $1::int) AND (entity_id = $2::int);
	
	SELECT org_id, entity_id, previous_salary, expected_salary INTO reca
	FROM applicants
	WHERE (entity_id = $2::int);
	v_entity_id := reca.entity_id;
	IF(reca.entity_id is null) THEN
		SELECT org_id, entity_id, basic_salary as previous_salary, basic_salary as expected_salary INTO reca
		FROM employees
		WHERE (entity_id = $2::int);
		v_entity_id := reca.entity_id;
	END IF;
	
	SELECT count(address_id) INTO v_address
	FROM vw_address
	WHERE (table_name = 'applicant') AND (is_default = true) AND (table_id  = v_entity_id);
	IF(v_address is null) THEN v_address = 0; END IF;
	
	SELECT count(education_id) INTO c_education_id
	FROM education
	WHERE (entity_id  = v_entity_id);
	IF(c_education_id is null) THEN c_education_id = 0; END IF;
	
	SELECT count(address_id) INTO c_referees
	FROM vw_referees
	WHERE (table_id  = v_entity_id);
	IF(c_referees is null) THEN c_referees = 0; END IF;

	IF v_application_id is not null THEN
		msg := 'There is another application for the post.';
		RAISE EXCEPTION '%', msg;
	ELSIF (reca.previous_salary is null) OR (reca.expected_salary is null) THEN
		msg := 'Kindly indicate your previous and expected salary';
		RAISE EXCEPTION '%', msg;
	ELSIF (v_address < 1) THEN
		msg := 'You need to have at least one full address added';
		RAISE EXCEPTION '%', msg;
	ELSIF (c_education_id < 2) THEN
		msg := 'You need to have at least two education levels added';
		RAISE EXCEPTION '%', msg;
	ELSIF (c_referees < 3) THEN
		msg := 'You need to have at least three referees added';
		RAISE EXCEPTION '%', msg;
	ELSE
		INSERT INTO applications (intake_id, org_id, entity_id, previous_salary, expected_salary, approve_status)
		VALUES ($1::int, reca.org_id, reca.entity_id, reca.previous_salary, reca.expected_salary, 'Completed');
		msg := 'Added Job application';
	END IF;

	return msg;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION objectives_review(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	v_objective_ps		real;
	max_objective_ps	real;
	sum_ods_ps			real;
	rec					RECORD;
	msg 				varchar(120);
BEGIN

	SELECT sum(objectives.objective_ps) INTO v_objective_ps
	FROM objectives
	WHERE (objectives.employee_objective_id = CAST($1 as int));
	SELECT max(objectives.objective_ps) INTO max_objective_ps
	FROM objectives
	WHERE (objectives.employee_objective_id = CAST($1 as int));
	SELECT sum(objective_details.ods_ps) INTO sum_ods_ps
	FROM objective_details INNER JOIN objectives ON objective_details.objective_id = objectives.objective_id
	WHERE (objectives.employee_objective_id = CAST($1 as int));
	
	IF(v_objective_ps is null)THEN
		v_objective_ps := 0;
	END IF;
	IF(max_objective_ps is null)THEN
		max_objective_ps := 0;
	END IF;
	IF(sum_ods_ps is null)THEN
		sum_ods_ps := 100;
	END IF;
	IF(sum_ods_ps = 0)THEN
		sum_ods_ps := 100;
	END IF;

	IF(max_objective_ps > 50)THEN
		msg := 'Objective should not have a % higer than 50';
		RAISE EXCEPTION '%', msg;
	ELSIF(v_objective_ps = 100) AND (sum_ods_ps = 100)THEN
		UPDATE employee_objectives SET approve_status = 'Completed'
		WHERE (employee_objective_id = CAST($1 as int));

		msg := 'Objectives Review Applied';	
	ELSIF(sum_ods_ps <> 100)THEN
		msg := 'Objective details % must add up to 100';
		RAISE EXCEPTION '%', msg;
	ELSE
		msg := 'Objective % must add up to 100';
		RAISE EXCEPTION '%', msg;
	END IF;

	return msg;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION job_review_check(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	v_self_rating		integer;
	v_objective_ps		real;
	sum_ods_ps			real;
	v_point_check		integer;
	rec					RECORD;
	msg 				varchar(120);
BEGIN
	
	SELECT sum(objectives.objective_ps) INTO v_objective_ps
	FROM objectives INNER JOIN evaluation_points ON evaluation_points.objective_id = objectives.objective_id
	WHERE (evaluation_points.job_review_id = CAST($1 as int));
	SELECT sum(ods_ps) INTO sum_ods_ps
	FROM objective_details INNER JOIN evaluation_points ON evaluation_points.objective_id = objective_details.objective_id
	WHERE (evaluation_points.job_review_id = CAST($1 as int));
	
	SELECT evaluation_points.evaluation_point_id INTO v_point_check
	FROM objectives INNER JOIN evaluation_points ON evaluation_points.objective_id = objectives.objective_id
	WHERE (evaluation_points.job_review_id = CAST($1 as int))
		AND (objectives.objective_ps > 0) AND (evaluation_points.points = 0);
		
	SELECT self_rating INTO v_self_rating
	FROM job_reviews
	WHERE (job_review_id = $1::int);
	IF(v_self_rating is null) THEN v_self_rating := 0; END IF;
	
	IF(sum_ods_ps is null)THEN
		sum_ods_ps := 100;
	END IF;
	IF(sum_ods_ps = 0)THEN
		sum_ods_ps := 100;
	END IF;

	IF(v_objective_ps = 100) AND (sum_ods_ps = 100)THEN
		UPDATE job_reviews SET approve_status = 'Completed'
		WHERE (job_review_id = CAST($1 as int));

		msg := 'Review Applied';
	ELSIF(sum_ods_ps <> 100)THEN
		msg := 'Objective details % must add up to 100';
		RAISE EXCEPTION '%', msg;
	ELSIF(v_self_rating = 0)THEN
		msg := 'Indicate your self rating';
		RAISE EXCEPTION '%', msg;
	ELSIF(v_point_check is not null)THEN
		msg := 'All objective evaluations points must be between 1 to 4';
		RAISE EXCEPTION '%', msg;
	ELSE
		msg := 'Objective % must add up to 100';
		RAISE EXCEPTION '%', msg;
	END IF;

	return msg;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION getComputedReviewPoints(v_type integer, v_job_review_id integer) RETURNS double precision AS $$
DECLARE
	v_points double precision;
BEGIN
	IF(v_type = 1) THEN
		SELECT SUM((vw_evaluation_objectives.objective_ps/100) * vw_evaluation_objectives.points)  INTO v_points
		FROM job_reviews INNER JOIN vw_evaluation_objectives
		ON job_reviews.job_review_id = vw_evaluation_objectives.job_review_id

		WHERE (job_reviews.job_review_id =v_job_review_id)
		AND (EXTRACT(YEAR FROM vw_evaluation_objectives.date_set) = EXTRACT(YEAR FROM job_reviews.review_date));
	ELSE
		SELECT SUM((vw_evaluation_objectives.objective_ps/100) * vw_evaluation_objectives.reviewer_points) INTO  v_points
		FROM job_reviews INNER JOIN vw_evaluation_objectives
		ON job_reviews.job_review_id = vw_evaluation_objectives.job_review_id

		WHERE (job_reviews.job_review_id = v_job_review_id)
		AND (EXTRACT(YEAR FROM vw_evaluation_objectives.date_set) = EXTRACT(YEAR FROM job_reviews.review_date));
	END IF;
	
	IF(v_points is null) THEN v_points := 0; END IF;
   
	RETURN v_points;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION ins_loans() RETURNS trigger AS $$
DECLARE
	v_default_interest	real;
	v_reducing_balance	boolean;
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
	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_loans BEFORE INSERT OR UPDATE ON loans
    FOR EACH ROW EXECUTE PROCEDURE ins_loans();


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
    

CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON loans
    FOR EACH ROW EXECUTE PROCEDURE upd_action();
    

CREATE OR REPLACE FUNCTION generate_payroll(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	v_period_id		integer;
	v_org_id		integer;
	v_month_name	varchar(50);

	msg 			varchar(120);
BEGIN
	SELECT period_id, org_id, to_char(start_date, 'Month YYYY') INTO v_period_id, v_org_id, v_month_name
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
	
	INSERT INTO sys_emailed (sys_email_id, table_id, table_name, narrative, org_id)
	SELECT 7, entity_id, 'periods', v_month_name, v_org_id
	FROM entity_subscriptions
	WHERE entity_type_id = 6;

	msg := 'Payroll Generated';

	RETURN msg;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION upd_employee_month() RETURNS trigger AS $$
BEGIN
	INSERT INTO employee_tax_types (org_id, employee_month_id, tax_type_id, tax_identification, additional, amount, employer, in_tax, exchange_rate)
	SELECT NEW.org_id, NEW.employee_month_id, default_tax_types.tax_type_id, default_tax_types.tax_identification, 
		Default_Tax_Types.Additional, 0, 0, Tax_Types.In_Tax,
		(CASE WHEN Tax_Types.currency_id = NEW.currency_id THEN 1 ELSE 1 / NEW.exchange_rate END)
	FROM Default_Tax_Types INNER JOIN Tax_Types ON Default_Tax_Types.Tax_Type_id = Tax_Types.Tax_Type_id
	WHERE (Default_Tax_Types.active = true) AND (Default_Tax_Types.entity_ID = NEW.entity_ID);

	INSERT INTO employee_adjustments (org_id, employee_month_id, adjustment_id, amount, adjustment_type, in_payroll, in_tax, visible, adjustment_factor, 
		balance, tax_relief_amount, exchange_rate, narrative)
	SELECT NEW.org_id, NEW.employee_month_id, default_adjustments.adjustment_id, default_adjustments.amount,
		adjustments.adjustment_type, adjustments.in_payroll, adjustments.in_tax, adjustments.visible,
		(CASE WHEN adjustments.adjustment_type = 2 THEN -1 ELSE 1 END),
		(CASE WHEN (adjustments.running_balance = true) AND (adjustments.reduce_balance = false) THEN (default_adjustments.balance + default_adjustments.amount)
			WHEN (adjustments.running_balance = true) AND (adjustments.reduce_balance = true) THEN (default_adjustments.balance - default_adjustments.amount) END),
		(default_adjustments.amount * adjustments.tax_relief_ps / 100),
		(CASE WHEN adjustments.currency_id = NEW.currency_id THEN 1 ELSE 1 / NEW.exchange_rate END),
		narrative
	FROM default_adjustments INNER JOIN adjustments ON default_adjustments.adjustment_id = adjustments.adjustment_id
	WHERE ((default_adjustments.final_date is null) OR (default_adjustments.final_date > current_date))
		AND (default_adjustments.active = true) AND (default_adjustments.entity_id = NEW.entity_id);

	INSERT INTO advance_deductions (org_id, amount, employee_month_id)
	SELECT NEW.org_id, (Amount / Pay_Period), NEW.Employee_Month_ID
	FROM employee_advances INNER JOIN employee_month ON employee_advances.employee_month_id = employee_month.employee_month_id
	WHERE (employee_month.entity_id = NEW.entity_id) AND (employee_advances.pay_period > 0) AND (employee_advances.completed = false)
		AND (employee_advances.pay_upto >= current_date);
		
	INSERT INTO project_staff_costs (org_id, employee_month_id, project_id, project_role, payroll_ps, staff_cost, tax_cost)
	SELECT NEW.org_id, NEW.employee_month_id, 
		project_staff.project_id, project_staff.project_role, project_staff.payroll_ps, project_staff.staff_cost, project_staff.tax_cost
	FROM project_staff
	WHERE (project_staff.entity_id = NEW.entity_id) AND (project_staff.monthly_cost = true);
	
	INSERT INTO employee_banking (org_id, employee_month_id, bank_branch_id, currency_id, 
		bank_account, amount, 
		exchange_rate)
	SELECT NEW.org_id, NEW.employee_month_id, bank_branch_id, currency_id,
		bank_account, amount,
		(CASE WHEN default_banking.currency_id = NEW.currency_id THEN 1 ELSE 1 / NEW.exchange_rate END)
	FROM default_banking 
	WHERE (default_banking.entity_id = NEW.entity_id) AND (default_banking.active = true)
		AND (amount > 0);

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

UPDATE entitys SET function_role = 'staff,payroll,payrolladmin' WHERE user_name = 'ERNYAOB01';



DROP VIEW vw_employee_periods;
CREATE VIEW vw_employee_periods AS
	SELECT aa.period_id, aa.start_date, aa.period_year, aa.period_month, aa.period_code, 
		aa.week_start, EXTRACT(WEEK FROM aa.week_start) as p_week,
		b.org_id, b.entity_id, b.employee_id, b.active,
		(b.Surname || ' ' || b.First_name || ' ' || COALESCE(b.Middle_name, '')) as employee_name 
	FROM (SELECT a.org_id, a.period_id, a.start_date, a.end_date, 
		to_char(a.start_date, 'YYYY') as period_year, to_char(a.start_date, 'Month') as period_month,
		to_char(a.start_date, 'YYYYMM') as period_code,
		generate_series(a.start_date, a.end_date, interval '1 week') as week_start
		FROM periods a) aa
	INNER JOIN employees b ON aa.org_id = b.org_id;

	
DROP VIEW vw_attendance;
CREATE VIEW vw_attendance AS
	SELECT entitys.entity_id, entitys.entity_name, attendance.attendance_id, attendance.attendance_date, 
		attendance.org_id, attendance.time_in, attendance.time_out, attendance.details,
		to_char(attendance.attendance_date, 'YYYYMM') as a_month,
        EXTRACT(WEEK FROM attendance.attendance_date) as a_week,
        EXTRACT(DOW FROM attendance.attendance_date) as a_dow
	FROM attendance INNER JOIN entitys ON attendance.entity_id = entitys.entity_id;
	
DROP VIEW vw_week_attendance;	
CREATE VIEW vw_week_attendance AS
	SELECT a.period_id, a.start_date, a.period_year, a.period_month, a.period_code, 
		a.week_start, a.p_week, a.org_id, a.entity_id, a.employee_id, a.employee_name, a.active,
		
		pp1.time_in as mon_time_in, pp1.time_out as mon_time_out, (pp1.time_out - pp1.time_in) as mon_time_diff,
		pp2.time_in as tue_time_in, pp2.time_out as tue_time_out, (pp2.time_out - pp2.time_in) as tue_time_diff,
		pp3.time_in as wed_time_in, pp3.time_out as wed_time_out, (pp3.time_out - pp3.time_in) as wed_time_diff,
		pp4.time_in as thu_time_in, pp4.time_out as thu_time_out, (pp4.time_out - pp4.time_in) as thu_time_diff,
		pp5.time_in as fri_time_in, pp5.time_out as fri_time_out, (pp5.time_out - pp5.time_in) as fri_time_diff,
		
		(CASE WHEN (pp1.time_in is null) or (pp1.time_out is null) THEN 0 ELSE 1 END) mon_count,
		(CASE WHEN (pp2.time_in is null) or (pp2.time_out is null) THEN 0 ELSE 1 END) tue_count,
		(CASE WHEN (pp3.time_in is null) or (pp3.time_out is null) THEN 0 ELSE 1 END) wed_count,
		(CASE WHEN (pp4.time_in is null) or (pp4.time_out is null) THEN 0 ELSE 1 END) thu_count,
		(CASE WHEN (pp5.time_in is null) or (pp5.time_out is null) THEN 0 ELSE 1 END) fri_count
	FROM vw_employee_periods a
		LEFT JOIN (SELECT p1.time_in, p1.time_out, p1.entity_id, p1.a_month, p1.a_week
			FROM vw_attendance p1 WHERE p1.a_dow = 1) pp1 ON
			(a.entity_id = pp1.entity_id) AND (a.period_code = pp1.a_month) AND (a.p_week = pp1.a_week)
		LEFT JOIN (SELECT p2.time_in, p2.time_out, p2.entity_id, p2.a_month, p2.a_week
			FROM vw_attendance p2 WHERE p2.a_dow = 2) pp2 ON
			(a.entity_id = pp2.entity_id) AND (a.period_code = pp2.a_month) AND (a.p_week = pp2.a_week)
		LEFT JOIN (SELECT p3.time_in, p3.time_out, p3.entity_id, p3.a_month, p3.a_week
			FROM vw_attendance p3 WHERE p3.a_dow = 1) pp3 ON
			(a.entity_id = pp3.entity_id) AND (a.period_code = pp3.a_month) AND (a.p_week = pp3.a_week)
		LEFT JOIN (SELECT p4.time_in, p4.time_out, p4.entity_id, p4.a_month, p4.a_week
			FROM vw_attendance p4 WHERE p4.a_dow = 4) pp4 ON
			(a.entity_id = pp4.entity_id) AND (a.period_code = pp4.a_month) AND (a.p_week = pp4.a_week)
		LEFT JOIN (SELECT p5.time_in, p5.time_out, p5.entity_id, p5.a_month, p5.a_week
			FROM vw_attendance p5 WHERE p5.a_dow = 1) pp5 ON
			(a.entity_id = pp5.entity_id) AND (a.period_code = pp5.a_month) AND (a.p_week = pp5.a_week);

DROP  VIEW vw_employee_tax_types;
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
