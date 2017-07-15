
INSERT INTO use_keys (use_key_id, use_key_name, use_function) VALUES (6, 'Tenants', 0);
INSERT INTO entity_types (org_id, entity_type_name, entity_role, use_key_id) VALUES (0, 'Tenants', 'tenants', 6);

INSERT INTO property_types (org_id, property_type_name) VALUES (0, 'Apartments');



INSERT INTO sys_emails (org_id, use_type, sys_email_name, default_email, title, details) VALUES (0, 1, 'Tenant Rent Adjustment', '', 'Tenant Rent Adjustment', '');
INSERT INTO sys_emails (org_id, use_type, sys_email_name, default_email, title, details) VALUES (0, 2, 'Release of bills/invoices', '', 'Release of bills/invoices', '');
INSERT INTO sys_emails (org_id, use_type, sys_email_name, default_email, title, details) VALUES (0, 3, 'Overdue Payment', '', 'Overdue Payment', '');
INSERT INTO sys_emails (org_id, use_type, sys_email_name, default_email, title, details) VALUES (0, 4, 'contracts/rental agreements', '', 'contracts/rental agreements', '');

INSERT INTO payment_types (payment_type_id, account_id, use_key_id, org_id, payment_type_name, is_active, details) 
				VALUES (2, 34005, 101, 0, 'Rent Payment', true, NULL);

INSERT INTO payment_types (payment_type_id, account_id, use_key_id, org_id, payment_type_name, is_active, details) 
				VALUES (3, 34005, 102, 0, 'Rent Remmitance', true, NULL);

INSERT INTO payment_types (payment_type_id, account_id, use_key_id, org_id, payment_type_name, is_active, details) 
				VALUES (4, 34005, 103, 0, 'Rental Penalty Payment', true, NULL);

INSERT INTO payment_types (payment_type_id, account_id, use_key_id, org_id, payment_type_name, is_active, details) 
				VALUES (5, 34005, 103, 0, 'Billing', true, NULL);

SELECT pg_catalog.setval('payment_types_payment_type_id_seq', 22, true);
