--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = public, pg_catalog;

--
-- Data for Name: sys_emails; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, default_email, title, details, use_type) VALUES (2, 0, 'Consultant  Approval', NULL, 'Account Activated', '<p>Dear{{name}},</p>

<p>Your account has been approved.</p>

<p>Username : {{username}}</p>

<p>Password : {{password}}</p>

<p>Regards,</p>

<p>Faidaplus Support</p>
', 2);
INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, default_email, title, details, use_type) VALUES (3, 0, 'Application Rejected', NULL, 'Application Rejected', '<p>Dear{{name}},</p>

<p>We are sorry your application was rejected, check if your pcc/son is&nbsp;correct.</p>

<p>Alternatively Reach the faidaplus Support desk on 020 4287000.</p>

<p>&nbsp;</p>

<p>{{details}}</p>

<p>&nbsp;</p>

<p>Regards,</p>

<p>Faidaplus Support</p>
', 4);
INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, default_email, title, details, use_type) VALUES (6, 0, 'Reset Password ', NULL, 'Reset Password ', '<p>Dear {{name}},</p>

<p>Password reset.</p>

<p>Your new password is: {{password}}</p>

<p>Regards,</p>

<p>Faidaplus Team</p>
', 2);
INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, default_email, title, details, use_type) VALUES (7, NULL, 'Birthday', NULL, 'Birthday', '<p><strong><span style="color:#800080"><span style="font-family:comic sans ms,cursive"><em>Dear {{name}} ,</em></span></span></strong></p>

<p><strong><span style="color:#800080"><span style="font-family:comic sans ms,cursive"><em>Today is your day to dream... Your day to shine... Your day to imagine the future you will create! Happy Birthday from all of us at Travelport.</em></span></span></strong></p>

<p>&nbsp;</p>

<p><strong><span style="color:#800080"><span style="font-family:comic sans ms,cursive"><em>Regards,</em></span></span></strong></p>

<p><strong><span style="color:#800080"><span style="font-family:comic sans ms,cursive"><em>Faidaplus Team</em></span></span></strong></p>
', 5);
INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, default_email, title, details, use_type) VALUES (1, 0, 'New consultant application', NULL, 'New Application', '<p>Dear{{name}},</p>

<p>Thank you for registering with faidaplus, your details are been verified and user details will be sent to you on a separate email.</p>
', 4);
INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, default_email, title, details, use_type) VALUES (9, NULL, 'Order Collected', NULL, 'Order Collected', '<p><span style="color:#0075B0">Dear {{name}},</span></p>

<p><span style="color:#0075B0">Thank you for collecting the order in the subject line. Happy selling!</span></p>

<p>&nbsp;</p>

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
INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, default_email, title, details, use_type) VALUES (8, NULL, 'Order on processing ', NULL, 'Order on processing ', '<p><span style="color:#0075B0">Dear {{name}},</span></p>

<p><span style="color:#0075B0">Your order of </span>{{mailbody}}<span style="color:#0075B0"> is being processed, once ready for collection an email notification will be sent to you. </span></p>

<p>Regards,</p>

<p>Faidaplus Team</p>
', 3);
INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, default_email, title, details, use_type) VALUES (4, 0, 'Order awaiting collection', NULL, 'Order awaiting collection', '<p>Dear {{name}},</p>

<p><span style="color:#0075B0">Your order&nbsp;</span>{{mailbody}}<span style="color:#0075B0"> is ready for collection. Please login to Faidaplus go to the orders tab, download and print the collection document and present at the office during collection.</span></p>

<p>Regards,</p>

<p>Faidaplus Team</p>
', 3);


--
-- Name: sys_emails_sys_email_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('sys_emails_sys_email_id_seq', 9, true);


--
-- PostgreSQL database dump complete
--

