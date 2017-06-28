
INSERT INTO pay_scales (org_id, pay_scale_id, pay_scale_name, min_pay, max_pay) VALUES (0, 0, 'Basic', 0, 1000000);
INSERT INTO pay_groups (org_id, pay_group_id, pay_group_name) VALUES (0, 0, 'Default');
INSERT INTO locations (org_id, location_id, location_name) VALUES (0, 0, 'Main office');

INSERT INTO kin_types (org_id, kin_type_name) VALUES (0, 'Wife');
INSERT INTO kin_types (org_id, kin_type_name) VALUES (0, 'Husband');
INSERT INTO kin_types (org_id, kin_type_name) VALUES (0, 'Daughter');
INSERT INTO kin_types (org_id, kin_type_name) VALUES (0, 'Son');
INSERT INTO kin_types (org_id, kin_type_name) VALUES (0, 'Mother');
INSERT INTO kin_types (org_id, kin_type_name) VALUES (0, 'Father');
INSERT INTO kin_types (org_id, kin_type_name) VALUES (0, 'Brother');
INSERT INTO kin_types (org_id, kin_type_name) VALUES (0, 'Sister');
INSERT INTO kin_types (org_id, kin_type_name) VALUES (0, 'Others');


INSERT INTO tax_types (use_key, tax_type_id, tax_type_name, formural, tax_relief, tax_type_order, in_tax, linear, percentage, employer, employer_ps, active, details) VALUES (1, 1, 'PAYE', 'Get_Employee_Tax(employee_tax_type_id, 2)', 1162, 1, false, true, true, 0, 0, true, NULL);
INSERT INTO tax_types (use_key, tax_type_id, tax_type_name, formural, tax_relief, tax_type_order, in_tax, linear, percentage, employer, employer_ps, active, details) VALUES (1, 2, 'NSSF', 'Get_Employee_Tax(employee_tax_type_id, 1)', 0, 0, true, true, true, 0, 0, true, NULL);
INSERT INTO tax_types (use_key, tax_type_id, tax_type_name, formural, tax_relief, tax_type_order, in_tax, linear, percentage, employer, employer_ps, active, details) VALUES (1, 3, 'NHIF', 'Get_Employee_Tax(employee_tax_type_id, 1)', 0, 0, false, false, false, 0, 0, true, NULL);
INSERT INTO tax_types (use_key, tax_type_id, tax_type_name, formural, tax_relief, tax_type_order, in_tax, linear, percentage, employer, employer_ps, active, details) VALUES (1, 4, 'FULL PAYE', 'Get_Employee_Tax(employee_tax_type_id, 2)', 0, 0, false, false, false, 0, 0, false, NULL);
SELECT pg_catalog.setval('tax_types_tax_type_id_seq', 4, true);
UPDATE tax_types SET org_id = 0;

INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (1, 10164, 10);
INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (1, 19740, 15);
INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (1, 29316, 20);
INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (1, 38892, 25);
INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (1, 10000000, 30);

INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (2, 4000, 5);
INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (2, 10000000, 0);

INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (3, 999, 0);
INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (3, 1499, 30);
INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (3, 1999, 40);
INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (3, 2999, 60);
INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (3, 3999, 80);
INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (3, 4999, 100);
INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (3, 5999, 120);
INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (3, 6999, 140);
INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (3, 7999, 160);
INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (3, 8999, 180);
INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (3, 9999, 200);
INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (3, 10999, 220);
INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (3, 11999, 240);
INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (3, 12999, 260);
INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (3, 13999, 280);
INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (3, 14999, 300);
INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (3, 1000000, 320);

INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (4, 10000000, 30);

UPDATE Tax_Rates SET org_id = 0;

INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, title, details) 
VALUES (1, 0, 'Application', 'Thank you for your Application', 'Thank you {{name}} for your application.<br><br>
Your user name is {{username}}<br> 
Your password is {{password}}<br><br>
Regards<br>
Human Resources Manager<br>
');
INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, title, details) 
VALUES (2, 0, 'New Staff', 'HR Your credentials ', 'Hello {{name}},<br><br>
Your credentials to the HR system have been created.<br>
Your user name is {{username}}<br> 
Your password is {{password}}<br><br>
Regards<br>
Human Resources Manager<br>
');
INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, title, details) 
VALUES (3, 0, 'Password reset', 'Password reset', 'Hello {{name}},<br><br>
Your password has been reset to:<br><br>
Your user name is {{username}}<br> 
Your password is {{password}}<br><br>
Regards<br>
Human Resources Manager<br>
');
SELECT pg_catalog.setval('sys_emails_sys_email_id_seq', 3, true);


INSERT INTO adjustments VALUES (43, 1, 0, 'Medical costs', 3, 0, NULL, NULL, false, true, false, true, false, false, 0, 0, 0, '0', NULL);
INSERT INTO adjustments VALUES (44, 1, 0, 'Education costs', 3, 0, NULL, NULL, false, true, false, true, false, false, 0, 0, 0, '0', NULL);
INSERT INTO adjustments VALUES (65, 1, 0, 'ACORD Loan KES', 2, 0, NULL, NULL, false, true, false, true, false, false, 0, 0, 0, '0', NULL);
INSERT INTO adjustments VALUES (1, 1, 0, 'Sacco Allowance', 1, 0, NULL, NULL, true, true, true, true, false, false, 0, 0, 0, NULL, NULL);
INSERT INTO adjustments VALUES (2, 1, 0, 'Bonus', 1, 0, NULL, NULL, true, true, true, true, false, false, 0, 0, 0, NULL, NULL);
INSERT INTO adjustments VALUES (11, 1, 0, 'SACCO', 2, 0, NULL, NULL, true, true, false, true, false, false, 0, 0, 0, NULL, NULL);
INSERT INTO adjustments VALUES (12, 1, 0, 'HELB', 2, 0, NULL, NULL, true, true, false, true, false, false, 0, 0, 0, NULL, NULL);
INSERT INTO adjustments VALUES (13, 1, 0, 'Rent Payment', 2, 0, NULL, NULL, true, true, false, true, false, false, 0, 0, 0, NULL, NULL);
INSERT INTO adjustments VALUES (21, 1, 0, 'Travel', 3, 0, NULL, NULL, true, true, false, true, false, false, 0, 0, 0, NULL, NULL);
INSERT INTO adjustments VALUES (22, 1, 0, 'Communcation', 3, 0, NULL, NULL, true, true, false, true, false, false, 0, 0, 0, NULL, NULL);
INSERT INTO adjustments VALUES (23, 1, 0, 'Tools', 3, 0, NULL, NULL, true, true, false, true, false, false, 0, 0, 0, NULL, NULL);
INSERT INTO adjustments VALUES (24, 1, 0, 'Payroll Cost', 3, 0, NULL, NULL, true, true, false, true, false, false, 0, 0, 0, NULL, NULL);
INSERT INTO adjustments VALUES (25, 1, 0, 'Health Insurance', 3, 0, NULL, NULL, true, true, false, false, false, false, 0, 0, 0, NULL, NULL);
INSERT INTO adjustments VALUES (26, 1, 0, 'GPA Insurance', 3, 0, NULL, NULL, true, true, false, false, false, false, 0, 0, 0, NULL, NULL);
INSERT INTO adjustments VALUES (27, 1, 0, 'Accomodation', 3, 0, NULL, NULL, true, true, false, true, false, false, 0, 0, 0, NULL, NULL);
INSERT INTO adjustments VALUES (28, 1, 0, 'Avenue Health Care', 3, 0, NULL, NULL, true, true, false, false, false, false, 0, 0, 0, NULL, NULL);
INSERT INTO adjustments VALUES (29, 1, 0, 'Maternety Cost', 3, 0, NULL, NULL, true, true, false, true, false, false, 0, 0, 0, NULL, NULL);
INSERT INTO adjustments VALUES (30, 1, 0, 'Health care claims', 3, 0, NULL, NULL, true, true, false, true, false, false, 0, 0, 0, NULL, NULL);
INSERT INTO adjustments VALUES (31, 1, 0, 'Trainining', 3, 0, NULL, NULL, true, true, false, true, false, false, 0, 0, 0, NULL, NULL);
INSERT INTO adjustments VALUES (32, 1, 0, 'per diem', 3, 0, NULL, NULL, true, true, false, true, false, false, 0, 0, 0, NULL, NULL);
INSERT INTO adjustments VALUES (66, 1, 0, 'Pension Contribution KES', 2, 0, NULL, NULL, false, true, true, true, false, false, 100, 0, 20000, '0', NULL);
INSERT INTO adjustments VALUES (42, 1, 0, 'Home leave', 3, 0, NULL, NULL, false, true, false, true, false, false, 0, 0, 0, '0', NULL);
INSERT INTO adjustments VALUES (59, 3, 0, 'House Allowance STG', 1, 0, NULL, NULL, false, true, true, true, false, false, 0, 0, 0, '0', NULL);
INSERT INTO adjustments VALUES (60, 3, 0, 'Acting Allowance STG', 1, 0, NULL, NULL, false, true, true, true, false, false, 0, 0, 0, '0', NULL);
INSERT INTO adjustments VALUES (35, 1, 0, 'Employer Pension Contribution KES', 1, 0, NULL, 'get_formula_adjustment(employee_month_id, 1, 0.115)', false, false, false, true, false, false, 0, 0, 0, '0', NULL);
INSERT INTO adjustments VALUES (63, 3, 0, 'Insurance Premiums STG', 2, 0, NULL, NULL, false, true, false, true, false, false, 0, 0, 0, '0', NULL);
INSERT INTO adjustments VALUES (64, 3, 0, 'Insurance Relief STG', 2, 0, NULL, NULL, false, true, false, true, false, false, 0, 0, 0, '0', NULL);
INSERT INTO adjustments VALUES (68, 3, 0, 'ACORD Loan STG', 2, 0, NULL, NULL, false, true, false, true, false, false, 0, 0, 0, '0', NULL);
INSERT INTO adjustments VALUES (69, 1, 0, 'Owner occupier interest KES', 2, 0, NULL, NULL, false, false, true, true, false, false, 100, 0, 12500, '0', NULL);
INSERT INTO adjustments VALUES (70, 1, 0, 'Home Ownership saving plan KES', 2, 0, NULL, NULL, false, false, true, true, false, false, 100, 0, 4000, '0', NULL);
INSERT INTO adjustments VALUES (36, 1, 0, 'ACORD association contribution KES', 2, 0, NULL, NULL, false, true, false, true, false, false, 0, 0, 0, '0', NULL);
INSERT INTO adjustments VALUES (62, 3, 0, 'ACORD association contribution STG', 2, 0, NULL, NULL, false, true, false, true, false, false, 0, 0, 0, '0', NULL);
INSERT INTO adjustments VALUES (33, 1, 0, 'House Allowance KES', 1, 0, NULL, NULL, false, true, true, true, false, false, 0, 0, 0, '0', NULL);
INSERT INTO adjustments VALUES (34, 1, 0, 'Acting Allowance KES', 1, 0, NULL, NULL, false, true, true, true, false, false, 0, 0, 0, '0', NULL);
INSERT INTO adjustments VALUES (45, 1, 0, 'Insurance relief KES', 2, 0, NULL, NULL, false, true, false, true, false, false, 0, 15, 0, '0', NULL);
INSERT INTO adjustments VALUES (40, 1, 0, 'Insurance Premiums KES', 2, 0, NULL, NULL, false, true, true, true, false, false, 0, 15, 5000, '0', NULL);


SELECT pg_catalog.setval('adjustments_adjustment_id_seq', 70, true);

INSERT INTO loan_types VALUES (1, 65, 0, 'ACORD Loan KES', 4, true, NULL);
INSERT INTO loan_types VALUES (7, 68, 0, 'ACORD Loan GBP', 4, true, NULL);

SELECT pg_catalog.setval('loan_types_loan_type_id_seq', 7, true);


INSERT INTO accounts_class (accounts_class_id, chat_type_id, chat_type_name, accounts_class_name)  VALUES (10, 1, 'ASSETS', 'FIXED ASSETS');
INSERT INTO accounts_class (accounts_class_id, chat_type_id, chat_type_name, accounts_class_name)  VALUES (20, 1, 'ASSETS', 'INTANGIBLE ASSETS');
INSERT INTO accounts_class (accounts_class_id, chat_type_id, chat_type_name, accounts_class_name)  VALUES (30, 1, 'ASSETS', 'CURRENT ASSETS');
INSERT INTO accounts_class (accounts_class_id, chat_type_id, chat_type_name, accounts_class_name)  VALUES (40, 2, 'LIABILITIES', 'CURRENT LIABILITIES');
INSERT INTO accounts_class (accounts_class_id, chat_type_id, chat_type_name, accounts_class_name)  VALUES (50, 2, 'LIABILITIES', 'LONG TERM LIABILITIES');
INSERT INTO accounts_class (accounts_class_id, chat_type_id, chat_type_name, accounts_class_name)  VALUES (60, 3, 'EQUITY', 'EQUITY AND RESERVES');
INSERT INTO accounts_class (accounts_class_id, chat_type_id, chat_type_name, accounts_class_name)  VALUES (70, 4, 'REVENUE', 'REVENUE AND OTHER INCOME');
INSERT INTO accounts_class (accounts_class_id, chat_type_id, chat_type_name, accounts_class_name)  VALUES (80, 5, 'COST OF REVENUE', 'COST OF REVENUE');
INSERT INTO accounts_class (accounts_class_id, chat_type_id, chat_type_name, accounts_class_name)  VALUES (90, 6, 'EXPENSES', 'EXPENSES');
UPDATE accounts_class SET org_id = 0;

INSERT INTO account_types (account_type_id, accounts_class_id, account_type_name) VALUES ('100', '10', 'COST');
INSERT INTO account_types (account_type_id, accounts_class_id, account_type_name) VALUES ('110', '10', 'ACCUMULATED DEPRECIATION');
INSERT INTO account_types (account_type_id, accounts_class_id, account_type_name) VALUES ('200', '20', 'COST');
INSERT INTO account_types (account_type_id, accounts_class_id, account_type_name) VALUES ('210', '20', 'ACCUMULATED AMORTISATION');
INSERT INTO account_types (account_type_id, accounts_class_id, account_type_name) VALUES ('300', '30', 'DEBTORS');
INSERT INTO account_types (account_type_id, accounts_class_id, account_type_name) VALUES ('310', '30', 'INVESTMENTS');
INSERT INTO account_types (account_type_id, accounts_class_id, account_type_name) VALUES ('320', '30', 'CURRENT BANK ACCOUNTS');
INSERT INTO account_types (account_type_id, accounts_class_id, account_type_name) VALUES ('330', '30', 'CASH ON HAND');
INSERT INTO account_types (account_type_id, accounts_class_id, account_type_name) VALUES ('340', '30', 'PRE-PAYMMENTS');
INSERT INTO account_types (account_type_id, accounts_class_id, account_type_name) VALUES ('400', '40', 'CREDITORS');
INSERT INTO account_types (account_type_id, accounts_class_id, account_type_name) VALUES ('410', '40', 'ADVANCED BILLING');
INSERT INTO account_types (account_type_id, accounts_class_id, account_type_name) VALUES ('420', '40', 'VAT');
INSERT INTO account_types (account_type_id, accounts_class_id, account_type_name) VALUES ('430', '40', 'WITHHOLDING TAX');
INSERT INTO account_types (account_type_id, accounts_class_id, account_type_name) VALUES ('500', '50', 'LOANS');
INSERT INTO account_types (account_type_id, accounts_class_id, account_type_name) VALUES ('600', '60', 'CAPITAL GRANTS');
INSERT INTO account_types (account_type_id, accounts_class_id, account_type_name) VALUES ('610', '60', 'ACCUMULATED SURPLUS');
INSERT INTO account_types (account_type_id, accounts_class_id, account_type_name) VALUES ('700', '70', 'SALES REVENUE');
INSERT INTO account_types (account_type_id, accounts_class_id, account_type_name) VALUES ('710', '70', 'OTHER INCOME');
INSERT INTO account_types (account_type_id, accounts_class_id, account_type_name) VALUES ('800', '80', 'COST OF REVENUE');
INSERT INTO account_types (account_type_id, accounts_class_id, account_type_name) VALUES ('900', '90', 'STAFF COSTS');
INSERT INTO account_types (account_type_id, accounts_class_id, account_type_name) VALUES ('905', '90', 'COMMUNICATIONS');
INSERT INTO account_types (account_type_id, accounts_class_id, account_type_name) VALUES ('910', '90', 'DIRECTORS ALLOWANCES');
INSERT INTO account_types (account_type_id, accounts_class_id, account_type_name) VALUES ('915', '90', 'TRANSPORT');
INSERT INTO account_types (account_type_id, accounts_class_id, account_type_name) VALUES ('920', '90', 'TRAVEL');
INSERT INTO account_types (account_type_id, accounts_class_id, account_type_name) VALUES ('925', '90', 'POSTAL and COURIER');
INSERT INTO account_types (account_type_id, accounts_class_id, account_type_name) VALUES ('930', '90', 'ICT PROJECT');
INSERT INTO account_types (account_type_id, accounts_class_id, account_type_name) VALUES ('935', '90', 'STATIONERY');
INSERT INTO account_types (account_type_id, accounts_class_id, account_type_name) VALUES ('940', '90', 'SUBSCRIPTION FEES');
INSERT INTO account_types (account_type_id, accounts_class_id, account_type_name) VALUES ('945', '90', 'REPAIRS');
INSERT INTO account_types (account_type_id, accounts_class_id, account_type_name) VALUES ('950', '90', 'PROFESSIONAL FEES');
INSERT INTO account_types (account_type_id, accounts_class_id, account_type_name) VALUES ('955', '90', 'OFFICE EXPENSES');
INSERT INTO account_types (account_type_id, accounts_class_id, account_type_name) VALUES ('960', '90', 'MARKETING EXPENSES');
INSERT INTO account_types (account_type_id, accounts_class_id, account_type_name) VALUES ('965', '90', 'STRATEGIC PLANNING');
INSERT INTO account_types (account_type_id, accounts_class_id, account_type_name) VALUES ('970', '90', 'DEPRECIATION');
INSERT INTO account_types (account_type_id, accounts_class_id, account_type_name) VALUES ('975', '90', 'CORPORATE SOCIAL INVESTMENT');
INSERT INTO account_types (account_type_id, accounts_class_id, account_type_name) VALUES ('980', '90', 'FINANCE COSTS');
INSERT INTO account_types (account_type_id, accounts_class_id, account_type_name) VALUES ('985', '90', 'TAXES');
INSERT INTO account_types (account_type_id, accounts_class_id, account_type_name) VALUES ('990', '90', 'INSURANCE');
INSERT INTO account_types (account_type_id, accounts_class_id, account_type_name) VALUES ('995', '90', 'OTHER EXPENSES');
UPDATE account_types SET org_id = 0;

INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('10000',100,'COMPUTERS and EQUIPMENT');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('10005',100,'FURNITURE');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('11000',110,'COMPUTERS and EQUIPMENT');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('11005',110,'FURNITURE');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('20000',200,'INTANGIBLE ASSETS');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('20005',200,'NON CURRENT ASSETS: DEFFERED TAX');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('20010',200,'INTANGIBLE ASSETS: ACCOUNTING PACKAGE');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('21000',210,'ACCUMULATED AMORTISATION');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('30000',300,'TRADE DEBTORS');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('30005',300,'STAFF DEBTORS');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('30010',300,'OTHER DEBTORS');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('30015',300,'DEBTORS PROMPT PAYMENT DISCOUNT');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('30020',300,'INVENTORY');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('30025',300,'INVENTORY WORK IN PROGRESS');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('30030',300,'GOODS RECEIVED CLEARING ACCOUNT');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('31005',310,'UNIT TRUST INVESTMENTS');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('32000',320,'COMMERCIAL BANK');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('32005',320,'MPESA');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('33000',330,'CASH ACCOUNT');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('33005',330,'PETTY CASH');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('34000',340,'PREPAYMENTS');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('34005',340,'DEPOSITS');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('34010',340,'TAX RECOVERABLE');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('34015',340,'TOTAL REGISTRAR DEPOSITS');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('40000',400,'CREDITORS- ACCRUALS');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('40005',400,'ADVANCE BILLING');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('40010',400,'LEAVE - ACCRUALS');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('40015',400,'ACCRUED LIABILITIES: CORPORATE TAX');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('40020',400,'OTHER ACCRUALS');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('40025',400,'PROVISION FOR CREDIT NOTES');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('40030',400,'NSSF');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('40035',400,'NHIF');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('40040',400,'HELB');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('40045',400,'PAYE');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('40050',400,'PENSION');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('41000',410,'ADVANCED BILLING');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('42000',420,'INPUT');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('42005',420,'OUTPUT');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('42010',420,'REMITTANCE');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('43000',430,'WITHHOLDING TAX');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('50000',500,'BANK LOANS');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('60000',600,'CAPITAL GRANTS');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('60005',600,'ACCUMULATED AMORTISATION OF CAPITAL GRANTS');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('60010',600,'DIVIDEND');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('61000',610,'RETAINED EARNINGS');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('61005',610,'ACCUMULATED SURPLUS');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('61010',610,'ASSET REVALUATION GAIN / LOSS');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('70005',700,'GOODS SALES');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('70010',700,'SERVICE SALES');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('70015',700,'SALES DISCOUNT');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('71000',710,'FAIR VALUE GAIN/LOSS IN INVESTMENTS');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('71005',710,'DONATION');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('71010',710,'EXCHANGE GAIN(LOSS)');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('71015',710,'REGISTRAR TRAINING FEES');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('71020',710,'DISPOSAL OF ASSETS');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('71025',710,'DIVIDEND INCOME');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('71030',710,'INTEREST INCOME');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('71035',710,'TRAINING, FORUM, MEETINGS and WORKSHOPS');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('80000',800,'COST OF GOODS');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('90000',900,'BASIC SALARY');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('90005',900,'LEAVE ALLOWANCES');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('90010',900,'AIRTIME ');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('90012',900,'TRANSPORT ALLOWANCE');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('90015',900,'REMOTE ACCESS');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('90020',900,'ICEA EMPLOYER PENSION CONTRIBUTION');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('90025',900,'NSSF EMPLOYER CONTRIBUTION');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('90035',900,'CAPACITY BUILDING - TRAINING');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('90040',900,'INTERNSHIP ALLOWANCES');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('90045',900,'BONUSES');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('90050',900,'LEAVE ACCRUAL');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('90055',900,'WELFARE');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('90056',900,'STAFF WELLFARE: WATER');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('90057',900,'STAFF WELLFARE: TEA');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('90058',900,'STAFF WELLFARE: OTHER CONSUMABLES');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('90060',900,'MEDICAL INSURANCE');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('90065',900,'GROUP PERSONAL ACCIDENT AND WIBA');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('90070',900,'STAFF SATISFACTION SURVEY');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('90075',900,'GROUP LIFE INSURANCE');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('90500',905,'FIXED LINES');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('90505',905,'CALLING CARDS');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('90510',905,'LEASE LINES');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('90515',905,'REMOTE ACCESS');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('90520',905,'LEASE LINE');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('91000',910,'SITTING ALLOWANCES');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('91005',910,'HONORARIUM');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('91010',910,'WORKSHOPS and SEMINARS');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('91500',915,'CAB FARE');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('91505',915,'FUEL');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('91510',915,'BUS FARE');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('91515',915,'POSTAGE and BOX RENTAL');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('92000',920,'TRAINING');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('92005',920,'BUSINESS PROSPECTING');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('92505',925,'DIRECTORY LISTING');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('92510',925,'COURIER');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('93000',930,'IP TRAINING');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('93010',930,'COMPUTER SUPPORT');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('93500',935,'PRINTED MATTER');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('93505',935,'PAPER');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('93510',935,'OTHER CONSUMABLES');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('93515',935,'TONER and CATRIDGE');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('93520',935,'COMPUTER ACCESSORIES');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('94010',940,'LICENSE FEE');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('94015',940,'SYSTEM SUPPORT FEES');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('94500',945,'FURNITURE');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('94505',945,'COMPUTERS and EQUIPMENT');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('94510',945,'JANITORIAL');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('95000',950,'AUDIT');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('95005',950,'MARKETING AGENCY');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('95010',950,'ADVERTISING');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('95015',950,'CONSULTANCY');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('95020',950,'TAX CONSULTANCY');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('95025',950,'MARKETING CAMPAIGN');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('95030',950,'PROMOTIONAL MATERIALS');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('95035',950,'RECRUITMENT');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('95040',950,'ANNUAL GENERAL MEETING');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('95045',950,'SEMINARS, WORKSHOPS and MEETINGS');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('95500',955,'OFFICE RENT');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('95505',955,'CLEANING');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('95510',955,'NEWSPAPERS');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('95515',955,'OTHER CONSUMABLES');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('95520',955,'ADMINISTRATIVE EXPENSES');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('96005',960,'WEBSITE REVAMPING COSTS');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('96505',965,'STRATEGIC PLANNING');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('96510',965,'MONITORING and EVALUATION');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('97000',970,'COMPUTERS and EQUIPMENT');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('97005',970,'FURNITURE');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('97010',970,'AMMORTISATION OF INTANGIBLE ASSETS');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('97500',975,'CORPORATE SOCIAL INVESTMENT');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('97505',975,'DONATION');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('98000',980,'LEDGER FEES');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('98005',980,'BOUNCED CHEQUE CHARGES');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('98010',980,'OTHER FEES');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('98015',980,'SALARY TRANSFERS');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('98020',980,'UPCOUNTRY CHEQUES');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('98025',980,'SAFETY DEPOSIT BOX');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('98030',980,'MPESA TRANSFERS');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('98035',980,'CUSTODY FEES');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('98040',980,'PROFESSIONAL FEES: MANAGEMENT FEES');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('98500',985,'EXCISE DUTY');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('98505',985,'FINES and PENALTIES');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('98510',985,'CORPORATE TAX');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('98515',985,'FRINGE BENEFIT TAX');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('99000',990,'ALL RISKS');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('99005',990,'FIRE and PERILS');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('99010',990,'BURGLARY');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('99015',990,'COMPUTER POLICY');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('99500',995,'BAD DEBTS WRITTEN OFF');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('99505',995,'PURCHASE DISCOUNT');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('99510',995,'COST OF GOODS SOLD (COGS)');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('99515',995,'PURCHASE PRICE VARIANCE');
INSERT INTO accounts (account_id, account_type_id, account_name) VALUES ('99999',995,'SURPLUS/DEFICIT');
UPDATE accounts set org_id = 0;

INSERT INTO default_accounts (default_account_id, account_id, narrative) VALUES (1, 99999, 'SURPLUS/DEFICIT ACCOUNT');
INSERT INTO default_accounts (default_account_id, account_id, narrative) VALUES (2, 61000, 'RETAINED EARNINGS ACCOUNT');
UPDATE default_accounts set org_id = 0;

INSERT INTO bank_accounts (bank_account_id, org_id, currency_id, bank_branch_id, account_id, bank_account_name, is_default) 
VALUES (0, 0, 1, 0, '33000', 'Cash Account', true);

INSERT INTO tax_types (org_id, tax_type_name, tax_rate, account_id) VALUES (0, 'Exempt', 0, '42005');
INSERT INTO tax_types (org_id, tax_type_name, tax_rate, account_id) VALUES (0, 'VAT', 16, '42005');

UPDATE tax_types SET currency_id = 1;
UPDATE tax_types SET account_id = 90000;

INSERT INTO workflows (workflow_id, org_id, source_entity_id, workflow_name, table_name, table_link_field, table_link_id, approve_email, reject_email, approve_file, reject_file, details) 
VALUES (1, 0, 0, 'Budget', 'budgets', NULL, NULL, 'Request approved', 'Request rejected', NULL, NULL, NULL);
INSERT INTO workflows (workflow_id, org_id, source_entity_id, workflow_name, table_name, table_link_field, table_link_id, approve_email, reject_email, approve_file, reject_file, details) 
VALUES (2, 0, 0, 'Requisition', 'transactions', NULL, NULL, 'Request approved', 'Request rejected', NULL, NULL, NULL);
INSERT INTO workflows (workflow_id, org_id, source_entity_id, workflow_name, table_name, table_link_field, table_link_id, approve_email, reject_email, approve_file, reject_file, details) 
VALUES (3, 0, 3, 'Transactions', 'transactions', NULL, NULL, 'Request approved', 'Request rejected', NULL, NULL, NULL);
INSERT INTO workflows VALUES (4, 1, 0, 'Payroll', 'periods', NULL, NULL, '<p>Request approved</p>', '<p>Request rejected</p>', NULL, NULL, NULL);
SELECT pg_catalog.setval('workflows_workflow_id_seq', 4, true);

INSERT INTO workflow_phases (workflow_phase_id, org_id, workflow_id, approval_entity_id, approval_level, return_level, escalation_days, escalation_hours, required_approvals, advice, notice, phase_narrative, advice_email, notice_email, advice_file, notice_file, details) 
VALUES (1, 0, 1, 0, 1, 0, 0, 3, 1, false, false, 'Approve', 'For your approval', 'Phase approved', NULL, NULL, NULL);
INSERT INTO workflow_phases (workflow_phase_id, org_id, workflow_id, approval_entity_id, approval_level, return_level, escalation_days, escalation_hours, required_approvals, advice, notice, phase_narrative, advice_email, notice_email, advice_file, notice_file, details) 
VALUES (2, 0, 2, 0, 1, 0, 0, 3, 1, false, false, 'Approve', 'For your approval', 'Phase approved', NULL, NULL, NULL);
INSERT INTO workflow_phases (workflow_phase_id, org_id, workflow_id, approval_entity_id, approval_level, return_level, escalation_days, escalation_hours, required_approvals, advice, notice, phase_narrative, advice_email, notice_email, advice_file, notice_file, details) 
VALUES (3, 0, 3, 0, 1, 0, 0, 3, 1, false, false, 'Approve', 'For your approval', 'Phase approved', NULL, NULL, NULL);
SELECT pg_catalog.setval('workflow_phases_workflow_phase_id_seq', 3, true);


INSERT INTO contract_status (contract_status_name) VALUES ('Active');
INSERT INTO contract_status (contract_status_name) VALUES ('Resigned');
INSERT INTO contract_status (contract_status_name) VALUES ('Deceased');
INSERT INTO contract_status (contract_status_name) VALUES ('Terminated');
INSERT INTO contract_status (contract_status_name) VALUES ('Transferred');









