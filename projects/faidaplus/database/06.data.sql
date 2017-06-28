
UPDATE orders SET batch_no = 1;
INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, default_email, title, details) VALUES (1, NULL, 'Application', NULL, 'Application', '<p>Dear{{name}},</p><p>Thank you for registering with faidaplus, your details are been verified.</p>');
INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, default_email, title, details) VALUES (2, NULL, 'Application Approval', NULL, 'Account Activated', NULL);
INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, default_email, title, details) VALUES (3, NULL, 'Application Rejected', NULL, 'Application Rejected', '<p>Dear{{name}},</p><p>We are sorry your application was rejected, check your pcc/son if valid.</p>');
INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, default_email, title, details, use_type) VALUES (4, 0, 'Order awaiting collection', NULL, 'Order awaiting collection', '<p>Dear {{name}},</p>

<p><span style="color:#0075B0">Your order&nbsp;</span>{{mailbody}}<span style="color:#0075B0"> is ready for collection. Please login to Faidaplus go to the orders tab, download and print the collection document and present at the office during collection.</span></p>

<p>Regards,</p>

<p>Faidaplus Team</p>
', 3);
INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, default_email, title, details, use_type) VALUES (5, 0, 'Order submitted', NULL, 'Order submitted', '<p>Dear {{name}}</p>

<p>&nbsp;</p>

<p><span style="color:#0075B0">Your order of </span>{{mailbody}} <span style="color:#0075B0">has been submitted, you will be notified once the order processing begins. </span></p>

<p>&nbsp;</p>

<p>Regards,</p>

<p>Faidaplus Team</p>
', 3);
INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, default_email, title, details) VALUES (6, NULL, 'Reset Password', NULL, 'Reset Password', '<p>Dear {{name}} ,</p><p>Username {{username}}</p><p>Password {{password}}</p>');

INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, default_email, title, details, use_type) VALUES (7, NULL, 'Birthday', NULL, 'Birthday', '<p><strong><span style="color:#800080"><span style="font-family:comic sans ms,cursive"><em>Dear {{name}} ,</em></span></span></strong></p>

<p><strong><span style="color:#800080"><span style="font-family:comic sans ms,cursive"><em>Today is your day to dream... Your day to shine... Your day to imagine the future you will create! Happy Birthday from all of us at Travelport.</em></span></span></strong></p>

<p>&nbsp;</p>

<p><strong><span style="color:#800080"><span style="font-family:comic sans ms,cursive"><em>Regards,</em></span></span></strong></p>

<p><strong><span style="color:#800080"><span style="font-family:comic sans ms,cursive"><em>Faidaplus Team</em></span></span></strong></p>
', 5);
INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, default_email, title, details, use_type) VALUES (8, NULL, 'Order on processing ', NULL, 'Order on processing ', '<p><span style="color:#0075B0">Dear {{name}},</span></p>

<p><span style="color:#0075B0">Your order of </span>{{mailbody}}<span style="color:#0075B0"> is being processed, once ready for collection an email notification will be sent to you. </span></p>

<p>Regards,</p>

<p>Faidaplus Team</p>
', 3);
INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, default_email, title, details, use_type) VALUES (9, NULL, 'Order Collected', NULL, 'Order Collected', '<p><span style="color:#0075B0">Dear {{name}},</span></p>

<p><span style="color:#0075B0">Thank you for collecting the order in the subject line. Happy selling!</span></p>

<p>&nbsp;</p>

<p>Regards,</p>

<p>Faidaplus Team</p>
', 3);
SELECT pg_catalog.setval('sys_emails_sys_email_id_seq', 9, true);

INSERT INTO bonus (amount, start_date, end_date, details, pcc) VALUES ('4', '2016-01-01','2016-01-31','To handle segments discrepancies in Aug 2015','2RJ');
INSERT INTO bonus (amount, start_date, end_date, details, pcc) VALUES ('50', '2016-01-01','2016-02-29','kes. 50 to push share to 50% from 10%','7PX1');
INSERT INTO bonus (amount, start_date, end_date, details, pcc) VALUES ('50', '2016-01-01','2016-02-29','kes. 50 to push share to 50% from 10%','B30');
INSERT INTO bonus (amount, start_date, end_date, details, pcc) VALUES ('25', '2016-01-01','2016-02-29','50% bonus to push share from 10% to 50%','75M5');
INSERT INTO bonus (amount, start_date, end_date, details, pcc) VALUES ('40', '2016-01-01','2016-03-31','Shiamsy extension from Jan-Mar to push more share','7GQ4');
INSERT INTO bonus (amount, start_date, end_date, details, pcc) VALUES ('5', '2016-01-01','2016-02-29','Discrepancies Aug and Dec 2015','757E');
INSERT INTO bonus (amount, start_date, end_date, details, pcc) VALUES ('8', '2016-02-01','2016-03-31','points difference in Jan','8GH');


INSERT INTO bonus (amount, start_date, end_date, details, pcc) VALUES ('25', '2016-01-01','2016-12-31','Travel Agency Bonus','5GW0');
INSERT INTO bonus (amount, start_date, end_date, details, pcc) VALUES ('25', '2016-01-01','2016-12-31','Travel Agency Bonus','7MA8');
INSERT INTO bonus (amount, start_date, end_date, details, pcc) VALUES ('54', '2016-01-01','2016-12-31','Travel Agency Bonus','9D0');


INSERT INTO bonus (percentage, start_date, end_date, details, consultant_id) VALUES ('51', '2016-01-01','2016-01-31','Recovery', 1701);
INSERT INTO bonus (percentage, start_date, end_date, details, consultant_id) VALUES ('42', '2016-02-01','2016-02-29','Recovery', 1701);


INSERT INTO bonus (percentage, start_date, end_date, details, consultant_id) VALUES ('30', '2016-01-01','2016-01-31','Recovery', 505);
INSERT INTO bonus (percentage, start_date, end_date, details, consultant_id) VALUES ('1', '2016-01-01','2016-01-31','Recovery', 2028);
INSERT INTO bonus (percentage, start_date, end_date, details, consultant_id) VALUES ('25', '2016-01-01','2016-01-31','Recovery', 180);

INSERT INTO bonus (percentage, start_date, end_date, details, consultant_id) VALUES ('15', '2016-02-01','2016-02-29','Recovery', 139);
INSERT INTO bonus (percentage, start_date, end_date, details, consultant_id) VALUES ('27', '2016-02-01','2016-02-29','Recovery', 505);
INSERT INTO bonus (percentage, start_date, end_date, details, consultant_id) VALUES ('16', '2016-02-01','2016-02-29','Recovery', 2031);
INSERT INTO bonus (percentage, start_date, end_date, details, consultant_id) VALUES ('11', '2016-02-01','2016-02-29','Recovery', 2028);

INSERT INTO bonus (percentage, start_date, end_date, details, period_id) VALUES ('50', '2016-02-01','2016-02-29','Recovery', 110);
INSERT INTO bonus (percentage, start_date, end_date, details, period_id) VALUES ('50', '2016-03-01','2016-03-31','Market Bonus', 111);


UPDATE bonus SET org_id = orgs.org_id
FROM orgs
WHERE orgs.pcc = bonus.pcc AND pcc is not null AND org_id is null;

UPDATE bonus SET approve_status = 'Approved', is_active = true;
