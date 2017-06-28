

--- Updating tax types

UPDATE employee_tax_types SET tax_identification = a.tax_identification
FROM (SELECT default_tax_types.tax_identification, default_tax_types.tax_type_id, employee_month.employee_month_id
FROM default_tax_types, employee_month WHERE default_tax_types.entity_id = employee_month.entity_id) as a
WHERE employee_tax_types.employee_month_id = a.employee_month_id and (employee_tax_types.tax_type_id = a.tax_type_id);


---- Get the data for employees

SELECT department_name, department_role_name, location_name, employee_name, date_of_birth, gender, 
	appointment_date, identity_card, language, employee_age, gender_name, marital_status_name, 
	education_class_name, date_from, date_to, name_of_school, examination_taken, grades_obtained
FROM vw_employees
WHERE active = true
ORDER BY department_name, department_role_name;


----------- Kenya Tax rate increase
UPDATE tax_rates SET tax_range = 11180.33 WHERE tax_rate_id = 1;
UPDATE tax_rates SET tax_range = 21713.91 WHERE tax_rate_id = 2;
UPDATE tax_rates SET tax_range = 32247.5 WHERE tax_rate_id = 3;
UPDATE tax_rates SET tax_range = 42781.08 WHERE tax_rate_id = 4;

UPDATE tax_types SET tax_relief = 1280 WHERE tax_type_id = 1;


----------- Update tax on a larger scale using work join
INSERT INTO tax_rates (tax_type_id, org_id, tax_range, tax_rate)
SELECT aa.tax_type_id, aa.org_id, bb.tax_range, bb.tax_rate
FROM (SELECT tax_type_id, tax_type_name, org_id FROM tax_types WHERE org_id <> 0) aa INNER JOIN
(SELECT tax_types.tax_type_name, tax_rates.tax_type_id, tax_rates.tax_range, tax_rates.tax_rate
FROM tax_types INNER JOIN tax_rates ON tax_types.tax_type_id = tax_rates.tax_type_id
WHERE tax_types.org_id = 0) bb
ON aa.tax_type_name = bb.tax_type_name
ORDER BY aa.tax_type_id, bb.tax_range

