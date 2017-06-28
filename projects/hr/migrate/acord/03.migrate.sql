INSERT INTO department_roles(department_role_id, department_id, ln_department_role_id, org_id,  department_role_name, active)
            SELECT id, 0, 0, 0, Title, true  FROM mysqldb.designation;


ALTER TABLE employees DISABLE TRIGGER ins_employees;

DELETE FROM entity_subscriptions WHERE entity_id = 1;
DELETE FROM entitys WHERE entity_id = 1;

-- ignore rowid 54 :: duplicate
INSERT INTO entitys (entity_id, org_id, entity_type_id, entity_name, user_name, function_role, 
				first_password, entity_password)
            SELECT rowid, 0, 1,  fullname, 
                    lower(split_part(fullname, ' ', 1) || '.'::text || split_part(fullname, ' ', 2)),  'staff', 'baraza', md5('baraza') 
            FROM mysqldb.prmember WHERE rowid != 54;


INSERT INTO employees( entity_id, department_role_id, bank_branch_id, employee_id, pay_scale_id, pay_group_id, location_id, currency_id, org_id, person_title, 
                surname, first_name, middle_name, date_of_birth, gender, nationality,
             nation_of_birth, place_of_birth, appointment_date, current_appointment, contract_period, basic_salary,
                     bank_account, identity_card)
             
            SELECT rowid, 0, 0, rowid, 0,0, 0, 1,0,  
            (CASE WHEN sex = 'M' THEN 'Mr' ELSE 'Mrs' END) as person_title, 
                lastname, COALESCE(othernames,lastname), othernames, birthdate::date, sex,'KE', 'KE', placeofbirth, empdate, empdate, 1, 0,
                accountno, idnumber
            FROM mysqldb.prmember WHERE rowid != 54;

ALTER TABLE employees ENABLE TRIGGER ins_employees;

-- leave types
INSERT INTO leave_types(leave_type_id, org_id, leave_type_name, allowed_leave_days)
SELECT  id, 0, leavetype, totaldays FROM mysqldb.tbl_leavetypes;

UPDATE leave_types SET use_type = 1;
UPDATE leave_types SET use_type = 2 WHERE leave_type_id = 4;
UPDATE leave_types SET use_type = 3 WHERE leave_type_id = 8;


UPDATE employees SET  bank_account = mysqldb.prmember.accountno , identity_card = mysqldb.prmember.idnumber
FROM mysqldb.prmember
WHERE mysqldb.prmember.rowid = employees.entity_id;

UPDATE employees SET  marital_status = 
  (CASE WHEN MaritalStatus::integer = 1 THEN 'S' 
	 WHEN MaritalStatus::integer = 2 THEN 'M'
	 WHEN MaritalStatus::integer = 3 THEN 'D'
	 WHEN MaritalStatus::integer = 4 THEN 'W'
	 WHEN MaritalStatus::integer = 5 THEN 'X' ELSE 'S' END) 
    FROM mysqldb.prmember WHERE prmember.MaritalStatus != '' AND prmember.rowid = employees.entity_id;



INSERT INTO kins( kin_id, entity_id, kin_type_id, org_id, full_names,relation, emergency_contact, details)
SELECT id, empid_fk,  
	 (CASE WHEN lower(relationship) = 'wife' THEN 1
        WHEN lower(relationship) = 'husband' THEN 2
        WHEN lower(relationship) = 'daughter' THEN 3
        WHEN lower(relationship) = 'son' THEN 4
        WHEN lower(relationship) = 'mother' THEN 5
        WHEN lower(relationship) = 'father' THEN 6
        WHEN lower(relationship) = 'brother' THEN 7
        WHEN lower(relationship) = 'sister' THEN 8
        WHEN lower(relationship) = 'others' THEN 9
        ELSE 9 END ) , 0, fname || ' ' || mname || ' ' || lname, upper(relationship), true,  mphone || '\n' || address || '\n' || email
FROM mysqldb.tbl_nextofkin;


DELETE FROM education_class;
INSERT INTO education_class( education_class_id, org_id, education_class_name)
    SELECT id, 0, qlevel FROM mysqldb.tbl_qlevels;

-- has data matching issues for education_class id
INSERT INTO education( education_id, entity_id, education_class_id, org_id, date_from, date_to, name_of_school, examination_taken, grades_obtained)
SELECT id,empid_fk, qlevel,0, (yearfrom|| '-01-01')::date, (yearto ||'-12-31')::date, institution,  qualname,  qualname
FROM  mysqldb.tbl_qualifications;


INSERT INTO identification_types(identification_type_id, org_id, identification_type_name) VALUES (1, 0, 'PIN');
INSERT INTO identifications( entity_id, identification_type_id, nationality, org_id, identification, is_active)
	SELECT rowid, 1, 'KE', 0, pinnumber, true FROM mysqldb.prmember WHERE rowid != 54 AND pinnumber !='';

INSERT INTO banks (org_id, bank_name, sys_country_id, swift_code, sort_code, bank_code)
SELECT 0, bank, country, swift, sort_code, bank_code
FROM mysqldb.imp_banks
GROUP BY bank, country, swift, sort_code, bank_code
ORDER BY bank, country;

INSERT INTO bank_branch (org_id, bank_id, bank_branch_name, bank_branch_code)
SELECT 0, a.bank_id, b.branch_name, b.branch_code
FROM banks as a INNER JOIN mysqldb.imp_banks as b
ON (a.bank_name = b.bank) and (a.sys_country_id = b.country);



