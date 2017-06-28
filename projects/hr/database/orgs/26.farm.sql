

ALTER TABLE employee_advances ADD for_farm boolean default false;
ALTER TABLE advance_deductions ADD for_farm boolean default false;
    
CREATE OR REPLACE FUNCTION farm_payroll(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	rec 					RECORD;
	msg 					varchar(120);
	v_employee_advance_id	integer;
BEGIN
	IF ($3 = '1') THEN
		FOR rec IN SELECT works.entity_id, sum(works.work_amount) as sum_amount
			FROM works INNER JOIN day_works ON works.day_work_id = day_works.day_work_id
			WHERE (day_works.period_id = $1::int) 
			GROUP BY works.entity_id
		LOOP
		
			UPDATE employee_month SET basic_pay = rec.sum_amount
			WHERE (entity_id = rec.entity_id) 
				AND (period_id = $1::int);
				
		END LOOP;
		
		msg := process_payroll($1, $2, '1', $4);
		
	ELSIF ($3 = '2') THEN
		FOR rec IN SELECT employee_month_id, currency_id, entity_id, org_id, end_date, banked
			FROM vw_employee_month
			WHERE (period_id = $1::int) AND (net_pay > 0)
		LOOP
			DELETE FROM employee_advances WHERE for_farm = true AND employee_month_id = rec.employee_month_id;
			DELETE FROM advance_deductions WHERE for_farm = true AND employee_month_id = rec.employee_month_id;
			
			v_employee_advance_id :=  nextval('employee_advances_employee_advance_id_seq');
		
			INSERT INTO employee_advances (employee_advance_id, employee_month_id, currency_id, entity_id, org_id,
				pay_date, pay_upto, pay_period, amount, payment_amount, in_payroll, completed, for_farm)
			VALUES (v_employee_advance_id, rec.employee_month_id, rec.currency_id, rec.entity_id, rec.org_id, 
				current_date, rec.end_date, 1, rec.banked, rec.banked, false, true, true);
			
			UPDATE employee_advances SET approve_status = 'Approved' WHERE employee_advance_id = v_employee_advance_id;

			INSERT INTO advance_deductions (employee_month_id, org_id, pay_date, amount, in_payroll, for_farm)
			VALUES (rec.employee_month_id, rec.org_id, current_date, rec.banked, true, true);
		
		END LOOP;
		
		msg := 'Advance posted';
	END IF;

	return msg;
END;
$$ LANGUAGE plpgsql;

	