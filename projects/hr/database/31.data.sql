
INSERT INTO kin_types (org_id, kin_type_name) VALUES (0, 'Wife');
INSERT INTO kin_types (org_id, kin_type_name) VALUES (0, 'Husband');
INSERT INTO kin_types (org_id, kin_type_name) VALUES (0, 'Daughter');
INSERT INTO kin_types (org_id, kin_type_name) VALUES (0, 'Son');
INSERT INTO kin_types (org_id, kin_type_name) VALUES (0, 'Mother');
INSERT INTO kin_types (org_id, kin_type_name) VALUES (0, 'Father');
INSERT INTO kin_types (org_id, kin_type_name) VALUES (0, 'Brother');
INSERT INTO kin_types (org_id, kin_type_name) VALUES (0, 'Sister');
INSERT INTO kin_types (org_id, kin_type_name) VALUES (0, 'Others');

INSERT INTO education_class (org_id, education_class_id, education_class_name) VALUES (0, 1, 'Primary School');
INSERT INTO education_class (org_id, education_class_id, education_class_name) VALUES (0, 2, 'Secondary School');
INSERT INTO education_class (org_id, education_class_id, education_class_name) VALUES (0, 3, 'High School');
INSERT INTO education_class (org_id, education_class_id, education_class_name) VALUES (0, 4, 'Certificate');
INSERT INTO education_class (org_id, education_class_id, education_class_name) VALUES (0, 5, 'Diploma');
INSERT INTO education_class (org_id, education_class_id, education_class_name) VALUES (0, 6, 'Profesional Qualifications');
INSERT INTO education_class (org_id, education_class_id, education_class_name) VALUES (0, 7, 'Higher Diploma');
INSERT INTO education_class (org_id, education_class_id, education_class_name) VALUES (0, 8, 'Under Graduate');
INSERT INTO education_class (org_id, education_class_id, education_class_name) VALUES (0, 9, 'Post Graduate');
SELECT pg_catalog.setval('education_class_education_class_id_seq', 9, true);

INSERT INTO pay_scales (org_id, pay_scale_id, pay_scale_name, min_pay, max_pay) VALUES (0, 0, 'Basic', 0, 1000000);
INSERT INTO locations (org_id, location_id, location_name) VALUES (0, 0, 'Main office');
INSERT INTO pay_groups (org_id, pay_group_id, pay_group_name, gl_payment_account) VALUES (0, 0, 'Default', '40055');

INSERT INTO departments (org_id, department_id, ln_department_id, department_name) VALUES (0, 1, 0, 'Human Resources and Administration');
INSERT INTO departments (org_id, department_id, ln_department_id, department_name) VALUES (0, 2, 0, 'Sales and Marketing');
INSERT INTO departments (org_id, department_id, ln_department_id, department_name) VALUES (0, 3, 0, 'Finance');
INSERT INTO departments (org_id, department_id, ln_department_id, department_name) VALUES (0, 4, 4, 'Procurement');
SELECT pg_catalog.setval('departments_department_id_seq', 5, true);

INSERT INTO objective_types (org_id, objective_type_name) VALUES (0, 'General');

INSERT INTO department_roles (org_id, department_role_id, department_id, ln_department_role_id, department_role_name, active, job_description, job_requirements, duties, performance_measures, details) VALUES (0, 1, 0, 0, 'Chief Executive Officer', true, '- Defining short term and long term corporate strategies and objectives
- Direct overall company operations ', NULL, '- Develop and control strategic relationships with third-party companies
- Guide the development of client specific systems
- Provide leadership and monitor team performance and individual staff performance ', NULL, NULL);
INSERT INTO department_roles (org_id, department_role_id, department_id, ln_department_role_id, department_role_name, active, job_description, job_requirements, duties, performance_measures, details) VALUES (0, 2, 1, 0, 'Director, Human Resources', true, '- To direct and guide projects support services
- Train end client users 
- Provide leadership and monitor team performance and individual staff performance ', NULL, NULL, NULL, NULL);
INSERT INTO department_roles (org_id, department_role_id, department_id, ln_department_role_id, department_role_name, active, job_description, job_requirements, duties, performance_measures, details) VALUES (0, 3, 2, 0, 'Director, Sales and Marketing', true, '- To direct and guide in systems and products development.
- Provide leadership and monitor team performance and individual staff performance ', NULL, NULL, NULL, NULL);
INSERT INTO department_roles (org_id, department_role_id, department_id, ln_department_role_id, department_role_name, active, job_description, job_requirements, duties, performance_measures, details) VALUES (0, 4, 3, 0, 'Director, Finance', true, '- To direct and guide projects implementation
- Train end client users 
- Provide leadership and monitor team performance and individual staff performance ', NULL, NULL, NULL, NULL);
SELECT pg_catalog.setval('department_roles_department_role_id_seq', 9, true);

INSERT INTO skill_category (org_id, skill_category_id, skill_category_name, details) VALUES (0, 0, 'Others', NULL);
INSERT INTO skill_category (org_id, skill_category_id, skill_category_name, details) VALUES (0, 1, 'HARDWARE', NULL);
INSERT INTO skill_category (org_id, skill_category_id, skill_category_name, details) VALUES (0, 2, 'OPERATING SYSTEM', NULL);
INSERT INTO skill_category (org_id, skill_category_id, skill_category_name, details) VALUES (0, 3, 'SOFTWARE', NULL);
INSERT INTO skill_category (org_id, skill_category_id, skill_category_name, details) VALUES (0, 4, 'NETWORKING', NULL);
INSERT INTO skill_category (org_id, skill_category_id, skill_category_name, details) VALUES (0, 6, 'SERVERS', NULL);
INSERT INTO skill_category (org_id, skill_category_id, skill_category_name, details) VALUES (0, 8, 'COMMUNICATION/MESSAGING SUITE', NULL);
INSERT INTO skill_category (org_id, skill_category_id, skill_category_name, details) VALUES (0, 9, 'VOIP', NULL);
INSERT INTO skill_category (org_id, skill_category_id, skill_category_name, details) VALUES (0, 10, 'DEVELOPMENT', NULL);
SELECT pg_catalog.setval('skill_category_skill_category_id_seq', 10, true);
UPDATE skill_category SET skill_category_name =  initcap(skill_category_name);

INSERT INTO skill_types (skill_type_id, skill_category_id, skill_type_name, basic, intermediate, advanced, details) VALUES (0, 0, 'Indicate Your Skill', null, null, null, null);
INSERT INTO skill_types (skill_type_id, skill_category_id, skill_type_name, basic, intermediate, advanced, details) VALUES (1, 1, 'Personal Computer', 'Identify the different components of a computer', 'Understand the working of each component', 'Troubleshoot, Diagonize and Repair', NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, skill_type_name, basic, intermediate, advanced, details) VALUES (2, 1, 'Dot Matrix Printer', 'Identify the different components of a computer', 'Understand the working of each component', 'Troubleshoot, Diagonize and Repair', NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, skill_type_name, basic, intermediate, advanced, details) VALUES (3, 1, 'Ticket Printer', 'Identify the different components of a computer', 'Understand the working of each component', 'Troubleshoot, Diagonize and Repair', NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, skill_type_name, basic, intermediate, advanced, details) VALUES (4, 1, 'HP Printer', 'Identify the different components of a computer', 'Understand the working of each component', 'Troubleshoot, Diagonize and Repair', NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, skill_type_name, basic, intermediate, advanced, details) VALUES (5, 2, 'DOS', 'Installation', 'Configuration', 'Troubleshooting and Support', NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, skill_type_name, basic, intermediate, advanced, details) VALUES (6, 2, 'WindowsXP', 'Installation', 'Configuration', 'Troubleshooting and Support', NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, skill_type_name, basic, intermediate, advanced, details) VALUES (7, 2, 'Linux', 'Installation', 'Configuration', 'Troubleshooting and Support', NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, skill_type_name, basic, intermediate, advanced, details) VALUES (8, 2, 'Solaris UNIX', 'Installation', 'Configuration', 'Troubleshooting and Support', NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, skill_type_name, basic, intermediate, advanced, details) VALUES (10, 3, 'Office', 'Installation, Backup and Recovery', 'Application and Usage', 'Advanced Usage', NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, skill_type_name, basic, intermediate, advanced, details) VALUES (11, 3, 'Browsing', 'Setup ', 'Usage ', 'Troubleshooting and Support', NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, skill_type_name, basic, intermediate, advanced, details) VALUES (12, 3, 'Galileo Products', 'Setup ', 'Usage ', 'Troubleshooting and Support', NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, skill_type_name, basic, intermediate, advanced, details) VALUES (13, 3, 'Antivirus', 'Setup ', 'Updates and Support', 'Troubleshooting and Support', NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, skill_type_name, basic, intermediate, advanced, details) VALUES (9, 3, 'Dialup', 'Installation', 'Configuration', 'Troubleshooting and Support', NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, skill_type_name, basic, intermediate, advanced, details) VALUES (21, 4, 'Dialup', 'Dialup', 'Configuration', 'Troubleshooting and Support', NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, skill_type_name, basic, intermediate, advanced, details) VALUES (22, 4, 'LAN', 'Installation ', 'Configuration', 'Troubleshooting and Support', NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, skill_type_name, basic, intermediate, advanced, details) VALUES (23, 4, 'WAN', 'Installation', 'Configuration', 'Configuration', NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, skill_type_name, basic, intermediate, advanced, details) VALUES (29, 6, 'SAMBA', NULL, NULL, NULL, NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, skill_type_name, basic, intermediate, advanced, details) VALUES (30, 6, 'MAIL', NULL, NULL, NULL, NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, skill_type_name, basic, intermediate, advanced, details) VALUES (31, 6, 'WEB', NULL, NULL, NULL, NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, skill_type_name, basic, intermediate, advanced, details) VALUES (32, 6, 'APPLICATION ', NULL, NULL, NULL, NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, skill_type_name, basic, intermediate, advanced, details) VALUES (33, 6, 'IDENTITY MANAGEMENT', NULL, NULL, NULL, NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, skill_type_name, basic, intermediate, advanced, details) VALUES (34, 6, 'NETWORK MANAGEMENT   ', NULL, NULL, NULL, NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, skill_type_name, basic, intermediate, advanced, details) VALUES (36, 6, 'BACKUP AND STORAGE SERVICES', NULL, NULL, NULL, NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, skill_type_name, basic, intermediate, advanced, details) VALUES (37, 8, 'GROUPWARE', NULL, NULL, NULL, NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, skill_type_name, basic, intermediate, advanced, details) VALUES (38, 9, 'ASTERIX', NULL, NULL, NULL, NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, skill_type_name, basic, intermediate, advanced, details) VALUES (39, 10, 'DATABASE', NULL, NULL, NULL, NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, skill_type_name, basic, intermediate, advanced, details) VALUES (40, 10, 'DESIGN', NULL, NULL, NULL, NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, skill_type_name, basic, intermediate, advanced, details) VALUES (41, 10, 'BARAZA', NULL, NULL, NULL, NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, skill_type_name, basic, intermediate, advanced, details) VALUES (42, 10, 'CODING JAVA', NULL, NULL, NULL, NULL);
SELECT pg_catalog.setval('skill_types_skill_type_id_seq', 42, true);
UPDATE skill_types SET skill_type_name =  initcap(skill_type_name), org_id = 0;

INSERT INTO adjustment_effects (adjustment_effect_id, adjustment_effect_name) VALUES (0, 'General');
INSERT INTO adjustment_effects (adjustment_effect_id, adjustment_effect_name) VALUES (1, 'Housing');
INSERT INTO adjustment_effects (adjustment_effect_id, adjustment_effect_name) VALUES (2, 'Insurance');

INSERT INTO adjustments (adjustment_type, adjustment_id, adjustment_Name, Visible, In_Tax, account_number) VALUES (1, 1, 'Sacco Allowance', true, true, '90005');
INSERT INTO adjustments (adjustment_type, adjustment_id, adjustment_Name, Visible, In_Tax, account_number) VALUES (1, 2, 'Bonus', true, true, '90005');
INSERT INTO adjustments (adjustment_type, adjustment_id, adjustment_Name, in_payroll, Visible, In_Tax, account_number) VALUES (1, 3, 'Employer - Pension', false, true, false, '90005');

INSERT INTO adjustments (adjustment_type, adjustment_id, adjustment_Name, Visible, In_Tax, account_number) VALUES (2, 11, 'SACCO', true, false, '40055');
INSERT INTO adjustments (adjustment_type, adjustment_id, adjustment_Name, Visible, In_Tax, account_number) VALUES (2, 12, 'HELB', true, false, '40055');
INSERT INTO adjustments (adjustment_type, adjustment_id, adjustment_Name, Visible, In_Tax, account_number) VALUES (2, 13, 'Rent Payment', true, false, '40055');
INSERT INTO adjustments (adjustment_type, adjustment_id, adjustment_Name, Visible, In_Tax, account_number) VALUES (2, 14, 'Pension deduction', true, false, '40055');
INSERT INTO adjustments (adjustment_type, adjustment_id, adjustment_Name, Visible, In_Tax, account_number) VALUES (2, 15, 'Internal loans', true, false, '40055');

INSERT INTO adjustments (adjustment_type, adjustment_id, adjustment_Name, Visible, In_Tax, account_number) VALUES (3, 21, 'Travel', true, false, '90070');
INSERT INTO adjustments (adjustment_type, adjustment_id, adjustment_Name, Visible, In_Tax, account_number) VALUES (3, 22, 'Communcation', true, false, '90070');
INSERT INTO adjustments (adjustment_type, adjustment_id, adjustment_Name, Visible, In_Tax, account_number) VALUES (3, 23, 'Tools', true, false, '90070');
INSERT INTO adjustments (adjustment_type, adjustment_id, adjustment_Name, Visible, In_Tax, account_number) VALUES (3, 24, 'Payroll Cost', true, false, '90070');
INSERT INTO adjustments (adjustment_type, adjustment_id, adjustment_Name, Visible, In_Tax, account_number) VALUES (3, 25, 'Health Insurance', false, false, '90070');
INSERT INTO adjustments (adjustment_type, adjustment_id, adjustment_Name, Visible, In_Tax, account_number) VALUES (3, 26, 'GPA Insurance', false, false, '90070');
INSERT INTO adjustments (adjustment_type, adjustment_id, adjustment_Name, Visible, In_Tax, account_number) VALUES (3, 27, 'Accomodation', true, false, '90070');
INSERT INTO adjustments (adjustment_type, adjustment_id, adjustment_Name, Visible, In_Tax, account_number) VALUES (3, 28, 'Avenue Health Care', false, false, '90070');
INSERT INTO adjustments (adjustment_type, adjustment_id, adjustment_Name, Visible, In_Tax, account_number) VALUES (3, 29, 'Maternety Cost', true, false, '90070');
INSERT INTO adjustments (adjustment_type, adjustment_id, adjustment_Name, Visible, In_Tax, account_number) VALUES (3, 30, 'Health care claims', true, false, '90070');
INSERT INTO adjustments (adjustment_type, adjustment_id, adjustment_Name, Visible, In_Tax, account_number) VALUES (3, 31, 'Trainining', true, false, '90070');
INSERT INTO adjustments (adjustment_type, adjustment_id, adjustment_Name, Visible, In_Tax, account_number) VALUES (3, 32, 'per diem', true, false, '90070');
SELECT pg_catalog.setval('adjustments_adjustment_id_seq', 32, true);
UPDATE adjustments SET org_id = 0, currency_id = 1;

INSERT INTO use_keys (use_key_id, use_key_name, use_function) VALUES (11, 'Payroll Tax', 1);
INSERT INTO use_keys (use_key_id, use_key_name, use_function) VALUES (12, 'Payroll Contributions', 1);

INSERT INTO tax_types (tax_type_id, use_key_id, tax_type_name, formural, tax_relief, tax_type_order, in_tax, linear, percentage, employer, employer_ps, active, account_number, employer_account) VALUES (1, 11, 'PAYE', 'Get_Employee_Tax(employee_tax_type_id, 2)', 1280, 1, false, true, true, 0, 0, true, '40045', '40045');
INSERT INTO tax_types (tax_type_id, use_key_id, tax_type_name, formural, tax_relief, tax_type_order, in_tax, linear, percentage, employer, employer_ps, active, account_number, employer_account) VALUES (2, 12, 'NSSF', 'Get_Employee_Tax(employee_tax_type_id, 1)', 0, 0, true, true, true, 0, 0, true, '40030', '40030');
INSERT INTO tax_types (tax_type_id, use_key_id, tax_type_name, formural, tax_relief, tax_type_order, in_tax, linear, percentage, employer, employer_ps, active, account_number, employer_account) VALUES (3, 12, 'NHIF', 'Get_Employee_Tax(employee_tax_type_id, 1)', 0, 0, false, false, false, 0, 0, true, '40035', '40035');
INSERT INTO tax_types (tax_type_id, use_key_id, tax_type_name, formural, tax_relief, tax_type_order, in_tax, linear, percentage, employer, employer_ps, active, account_number, employer_account) VALUES (4, 11, 'FULL PAYE', 'Get_Employee_Tax(employee_tax_type_id, 2)', 0, 0, false, false, false, 0, 0, false, '40045', '40045');
SELECT pg_catalog.setval('tax_types_tax_type_id_seq', 4, true);
UPDATE tax_types SET org_id = 0;

INSERT INTO tax_rates (tax_type_id, tax_range, tax_rate) VALUES (1, 11180.33, 10);
INSERT INTO tax_rates (tax_type_id, tax_range, tax_rate) VALUES (1, 21713.91, 15);
INSERT INTO tax_rates (tax_type_id, tax_range, tax_rate) VALUES (1, 32247.5, 20);
INSERT INTO tax_rates (tax_type_id, tax_range, tax_rate) VALUES (1, 42781.08, 25);
INSERT INTO tax_rates (tax_type_id, tax_range, tax_rate) VALUES (1, 10000000, 30);

INSERT INTO tax_rates (tax_type_id, tax_range, tax_rate) VALUES (2, 4000, 5);
INSERT INTO tax_rates (tax_type_id, tax_range, tax_rate) VALUES (2, 10000000, 0);

INSERT INTO tax_rates (tax_type_id, tax_range, tax_rate) VALUES (3, 5999, 150);
INSERT INTO tax_rates (tax_type_id, tax_range, tax_rate) VALUES (3, 7999, 300);
INSERT INTO tax_rates (tax_type_id, tax_range, tax_rate) VALUES (3, 11999, 400);
INSERT INTO tax_rates (tax_type_id, tax_range, tax_rate) VALUES (3, 14999, 500);
INSERT INTO tax_rates (tax_type_id, tax_range, tax_rate) VALUES (3, 19999, 600);
INSERT INTO tax_rates (tax_type_id, tax_range, tax_rate) VALUES (3, 24999, 750);
INSERT INTO tax_rates (tax_type_id, tax_range, tax_rate) VALUES (3, 29999, 850);
INSERT INTO tax_rates (tax_type_id, tax_range, tax_rate) VALUES (3, 34999, 900);
INSERT INTO tax_rates (tax_type_id, tax_range, tax_rate) VALUES (3, 39999, 950);
INSERT INTO tax_rates (tax_type_id, tax_range, tax_rate) VALUES (3, 44999, 1000);
INSERT INTO tax_rates (tax_type_id, tax_range, tax_rate) VALUES (3, 49999, 1100);
INSERT INTO tax_rates (tax_type_id, tax_range, tax_rate) VALUES (3, 59999, 1200);
INSERT INTO tax_rates (tax_type_id, tax_range, tax_rate) VALUES (3, 69999, 1300);
INSERT INTO tax_rates (tax_type_id, tax_range, tax_rate) VALUES (3, 79999, 1400);
INSERT INTO tax_rates (tax_type_id, tax_range, tax_rate) VALUES (3, 89000, 1500);
INSERT INTO tax_rates (tax_type_id, tax_range, tax_rate) VALUES (3, 99000, 1600);
INSERT INTO tax_rates (tax_type_id, tax_range, tax_rate) VALUES (3, 10000000, 1700);

INSERT INTO tax_rates (tax_type_id, tax_range, tax_rate) VALUES (4, 10000000, 30);

UPDATE Tax_Rates SET org_id = 0;

INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, title, details) 
VALUES (1, 0, 'Application', 'Thank you for your Application', 'Thank you {{name}} for your application.<br><br>
Your user name is {{username}}<br> 
Your password is {{password}}<br><br>
Regards<br>
Human Resources Manager<br>');
INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, title, details) 
VALUES (2, 0, 'New Staff', 'HR Your credentials ', 'Hello {{name}},<br><br>
Your credentials to the HR system have been created.<br>
Your user name is {{username}}<br> 
Your password is {{password}}<br><br>
Regards<br>
Human Resources Manager<br>');
INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, title, details) 
VALUES (3, 0, 'Password reset', 'Password reset', 'Hello {{name}},<br><br>
Your password has been reset to:<br><br>
Your user name is {{username}}<br> 
Your password is {{password}}<br><br>
Regards<br>
Human Resources Manager<br>');
INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, title, details) 
VALUES (4, 0, 'Subscription', 'Subscription', 'Hello {{name}},<br><br>
Welcome to OpenBaraza SaaS Platform<br><br>
Your password is:<br><br>
Your user name is {{username}}<br> 
Your password is {{password}}<br><br>
Regards,<br>
OpenBaraza<br>');
INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, title, details) 
VALUES (5, 0, 'Subscription', 'Subscription', 'Hello {{name}},<br><br>
Your OpenBaraza SaaS Platform application has been approved<br><br>
Welcome to OpenBaraza SaaS Platform<br><br>
Regards,<br>
OpenBaraza<br>');
INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, title, details) 
VALUES (7, 0, 'Payroll Generated', 'Payroll Generated', 'Hello {{name}},<br><br>
They payroll has been generated for {{narrative}}<br><br>
Regards,<br>
HR Manager<br>');
INSERT INTO sys_emails (sys_email_id, use_type, org_id, sys_email_name, title, details) 
VALUES (8, 8, 0, 'Have a Happy Birthday', 'Have a Happy Birthday', 'Happy Birthday {{name}},<br><br>
A very happy birthday to you.<br><br>
Regards,<br>
HR Manager<br>');
INSERT INTO sys_emails (sys_email_id, use_type, org_id, sys_email_name, title, details) 
VALUES (9, 9, 0, 'Happy Birthday', 'Happy Birthday', 'Hello HR,<br><br>
{{narrative}}.<br><br>
Regards,<br>
HR Manager<br>');
INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, title, details) 
VALUES (10, 0, 'Job Application - acknowledgement', 'Job Application', 'Hello {{name}},<br><br>
We acknowledge receipt of your job application for {{job}}<br><br>
Regards,<br>
HR Manager<br>');
INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, title, details) 
VALUES (11, 0, 'Internship Application - acknowledgement', 'Job Application', 'Hello {{name}},<br><br>
We acknowledge receipt of your Internship application<br><br>
Regards,<br>
HR Manager<br>');
INSERT INTO sys_emails (sys_email_id, use_type, org_id, sys_email_name, title, details) 
VALUES (12, 12, 0, 'Contract Ending', 'Contract Ending - {{entity_name}}', 'Hello,<br><br>
Kindly note that the contract for {{entity_name}} is due to employment.<br><br>
Regards,<br>
HR Manager<br>');
SELECT pg_catalog.setval('sys_emails_sys_email_id_seq', 12, true);
UPDATE sys_emails SET use_type = sys_email_id;


INSERT INTO contract_status (contract_status_name) VALUES ('Active');
INSERT INTO contract_status (contract_status_name) VALUES ('Resigned');
INSERT INTO contract_status (contract_status_name) VALUES ('Deceased');
INSERT INTO contract_status (contract_status_name) VALUES ('Terminated');
INSERT INTO contract_status (contract_status_name) VALUES ('Transferred');
UPDATE contract_status SET org_id = 0;

INSERT INTO skill_levels (org_id, skill_level_name) VALUES (0, 'Basic');
INSERT INTO skill_levels (org_id, skill_level_name) VALUES (0, 'Intermediate');
INSERT INTO skill_levels (org_id, skill_level_name) VALUES (0, 'Advanced');

INSERT INTO industry (org_id, industry_name) VALUES (0, 'Aerospace');
INSERT INTO industry (org_id, industry_name) VALUES (0, 'Agriculture');
INSERT INTO industry (org_id, industry_name) VALUES (0, 'Automotive');
INSERT INTO industry (org_id, industry_name) VALUES (0, 'Business and Consultancy Services');
INSERT INTO industry (org_id, industry_name) VALUES (0, 'ICT - Reseller');
INSERT INTO industry (org_id, industry_name) VALUES (0, 'ICT - Services and Consultancy');
INSERT INTO industry (org_id, industry_name) VALUES (0, 'ICT - Manufacturer');
INSERT INTO industry (org_id, industry_name) VALUES (0, 'ICT - Software Development');
INSERT INTO industry (org_id, industry_name) VALUES (0, 'Investments');
INSERT INTO industry (org_id, industry_name) VALUES (0, 'Education');
INSERT INTO industry (org_id, industry_name) VALUES (0, 'Electronics');
INSERT INTO industry (org_id, industry_name) VALUES (0, 'Finance, Banking, Insurance');
INSERT INTO industry (org_id, industry_name) VALUES (0, 'Government - National or Federal');
INSERT INTO industry (org_id, industry_name) VALUES (0, 'Government - State, Country or Local');
INSERT INTO industry (org_id, industry_name) VALUES (0, 'Healthcare');
INSERT INTO industry (org_id, industry_name) VALUES (0, 'Hotel and Leisure');
INSERT INTO industry (org_id, industry_name) VALUES (0, 'Legal');
INSERT INTO industry (org_id, industry_name) VALUES (0, 'Manufacturing');
INSERT INTO industry (org_id, industry_name) VALUES (0, 'Media, Marketing, Entertainment, Publishing, PR');
INSERT INTO industry (org_id, industry_name) VALUES (0, 'Real Estate');
INSERT INTO industry (org_id, industry_name) VALUES (0, 'Retail, Wholesale');
INSERT INTO industry (org_id, industry_name) VALUES (0, 'Telecoms');
INSERT INTO industry (org_id, industry_name) VALUES (0, 'Transportation and Distribution');
INSERT INTO industry (org_id, industry_name) VALUES (0, 'Travel and Tours');
INSERT INTO industry (org_id, industry_name) VALUES (0, 'Other');

INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Accounting');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Banking and Financial Services');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'CEO');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'General Management');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Creative and Design');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Customer Service and Call Centre');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Education and Training');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Engineering and Construction');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Farming and Agribusiness');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Government');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Healthcare and Pharmaceutical');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Human Resources');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Insurance');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'ICT');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Telecoms');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Legal');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Manufacturing');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Marketing, Media and Brand');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'NGO, Community and Social Development');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Office and Administration');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Project and Programme Management');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Research, Science and Biotech');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Retail');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Sales');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Security');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Strategy and Consulting');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Tourism and Travel');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Trades and Services');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Transport and Logistics');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Internships and Volunteering');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Real Estate');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Hospitality');
INSERT INTO jobs_category (org_id, jobs_category) VALUES (0, 'Other');

INSERT INTO leave_types (org_id, leave_type_id, leave_type_name, allowed_leave_days, leave_days_span, use_type)
VALUES (0, 0, 'Annual Leave', 21, 7, 1);

INSERT INTO loan_types(loan_type_id, adjustment_id, org_id, loan_type_name, default_interest, reducing_balance)
VALUES (0, 15, 0, 'Emergency', 6, true);

INSERT INTO products (org_id, product_name, annual_cost, details) VALUES (0, 'HCM Hosting per employee', 200, 'HR and Payroll Hosting per employee per year');

INSERT INTO receipt_sources (org_id, receipt_source_name) VALUES (0, 'MPESA');
INSERT INTO receipt_sources (org_id, receipt_source_name) VALUES (0, 'Cash');
INSERT INTO receipt_sources (org_id, receipt_source_name) VALUES (0, 'Cheque');

INSERT INTO review_category (review_category_id, org_id, review_category_name) VALUES (0, 0, 'Annual Review');


