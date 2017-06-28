

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

SELECT pg_catalog.setval('sys_emails_sys_email_id_seq', 5, true);
UPDATE sys_emails SET use_type = sys_email_id;

INSERT INTO departments (org_id, department_id, ln_department_id, department_name) VALUES (0, 1, 1, 'Administration'); 
SELECT pg_catalog.setval('departments_department_id_seq', 1, true);

INSERT INTO entitys (entity_id, org_id, entity_type_id, use_key_id, user_name, entity_name, primary_email, entity_leader, super_user, no_org, first_password,function_role)
VALUES (2, 0, 0, 0, 'admin', 'admin', 'admin@admin.com', true, false, false, 'baraza','admin');
INSERT INTO entitys (entity_id, org_id, entity_type_id, use_key_id, user_name, entity_name, primary_email, entity_leader, super_user, no_org, first_password,function_role)
VALUES (3, 0, 0, 0, 'member', 'member', 'member@member.com', true, false, false, 'baraza','member');
SELECT pg_catalog.setval('entitys_entity_id_seq', 3, true);

INSERT INTO industry (org_id, industry_name) VALUES (0, 'Aerospace');
INSERT INTO industry (org_id, industry_name) VALUES (0, 'Agriculture');
INSERT INTO industry (org_id, industry_name) VALUES (0, 'Automotive');
INSERT INTO industry (org_id, industry_name) VALUES (0, 'Business and Consultancy Services');
INSERT INTO industry (org_id, industry_name) VALUES (0, 'ICT');
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



