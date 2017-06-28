
--
-- Data for Name: booking_types; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO booking_types (booking_type_id, booking_type_name, details) VALUES (1, 'Local', NULL);
INSERT INTO booking_types (booking_type_id, booking_type_name, details) VALUES (2, 'East Africa', NULL);
INSERT INTO booking_types (booking_type_id, booking_type_name, details) VALUES (3, 'Rest of Africa', NULL);
INSERT INTO booking_types (booking_type_id, booking_type_name, details) VALUES (4, 'International', NULL);


--
-- Name: booking_types_booking_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('booking_types_booking_type_id_seq', 4, true);


INSERT INTO class_categorys (class_id, booking_type_id, class_name, details) VALUES (2, 1, 'Online booking', NULL);
INSERT INTO class_categorys (class_id, booking_type_id, class_name, details) VALUES (1, 1, 'Domestic', NULL);
INSERT INTO class_categorys (class_id, booking_type_id, class_name, details) VALUES (3, 2, 'Economy', NULL);
INSERT INTO class_categorys (class_id, booking_type_id, class_name, details) VALUES (4, 2, 'Business', NULL);
INSERT INTO class_categorys (class_id, booking_type_id, class_name, details) VALUES (5, 3, 'Economy', NULL);
INSERT INTO class_categorys (class_id, booking_type_id, class_name, details) VALUES (6, 3, 'Business', NULL);
INSERT INTO class_categorys (class_id, booking_type_id, class_name, details) VALUES (7, 4, 'Economy', NULL);
INSERT INTO class_categorys (class_id, booking_type_id, class_name, details) VALUES (8, 4, 'Business', NULL);


--
-- Name: class_categorys_class_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('class_categorys_class_id_seq', 8, true);

INSERT INTO points_scaling (scaling_id, class_id, one_way, isreturn, start_date, end_date, details, code) VALUES (1, 1, 5, 10, '2017-01-01', '2018-02-02', NULL, 'L');
INSERT INTO points_scaling (scaling_id, class_id, one_way, isreturn, start_date, end_date, details, code) VALUES (2, 2, 5, 10, '2017-01-01', '2018-08-24', NULL, 'L');
INSERT INTO points_scaling (scaling_id, class_id, one_way, isreturn, start_date, end_date, details, code) VALUES (7, 7, 35, 50, '2017-01-01', '2018-08-17', NULL, 'IE');
INSERT INTO points_scaling (scaling_id, class_id, one_way, isreturn, start_date, end_date, details, code) VALUES (8, 8, 40, 60, '2017-01-01', '2018-08-10', NULL, 'IB');
INSERT INTO points_scaling (scaling_id, class_id, one_way, isreturn, start_date, end_date, details, code) VALUES (3, 3, 10, 20, '2017-01-01', '2018-08-10', NULL, 'REE');
INSERT INTO points_scaling (scaling_id, class_id, one_way, isreturn, start_date, end_date, details, code) VALUES (4, 4, 15, 25, '2017-01-01', '2018-03-03', NULL, 'REB');
INSERT INTO points_scaling (scaling_id, class_id, one_way, isreturn, start_date, end_date, details, code) VALUES (6, 6, 25, 40, '2017-01-01', '2018-08-17', NULL, 'RAB');
INSERT INTO points_scaling (scaling_id, class_id, one_way, isreturn, start_date, end_date, details, code) VALUES (5, 5, 20, 30, '2017-01-01', '2018-08-11', NULL, 'RAE');
--
-- Name: points_scaling_scaling_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--
SELECT pg_catalog.setval('points_scaling_scaling_id_seq', 8, true);

INSERT INTO suppliers (supplier_id, supplier_name, create_date, contact_name, email, website, address, details) VALUES (1, 'Tusky''s', '2016-06-28 08:59:18.871826', NULL, NULL, NULL, NULL, NULL);
INSERT INTO suppliers (supplier_id, supplier_name, create_date, contact_name, email, website, address, details) VALUES (2, 'Nakumatt', '2016-06-28 08:59:36.604859', NULL, NULL, NULL, NULL, NULL);
INSERT INTO suppliers (supplier_id, supplier_name, create_date, contact_name, email, website, address, details) VALUES (3, 'Airport', '2016-06-28 08:59:58.991743', NULL, NULL, NULL, NULL, NULL);


--
-- Name: suppliers_supplier_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('suppliers_supplier_id_seq', 3, true);

INSERT INTO points_value (point_value_id, point_value, start_date, end_date, details) VALUES (1, 5, '2017-01-01', '2017-12-30', NULL);


--
-- Name: points_value_point_value_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('points_value_point_value_id_seq', 1, true);

INSERT INTO product_category (product_category_id, product_category_name, details, icon) VALUES (1, 'Super Markets', NULL, 'fa-cart-plus');
INSERT INTO product_category (product_category_id, product_category_name, details, icon) VALUES (2, 'Airtime', NULL, 'fa-credit-card');
INSERT INTO product_category (product_category_id, product_category_name, details, icon) VALUES (3, 'Airport transfers', NULL, NULL);


--
-- Name: product_category_product_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('product_category_product_category_id_seq', 2, true);


INSERT INTO products (product_id, product_category_id, supplier_id, created_by, product_name, product_uprice, product_ucost, created, product_details, terms, weight, remarks, is_active, updated_by, updated, narrative, image, details) VALUES (2, 1, 1, NULL, 'Tusky''s Kshs 2,000 Voucher', 2000, NULL, '2016-06-28', NULL, NULL, NULL, NULL, true, NULL, '2016-06-28 09:19:59.347323', NULL, NULL, NULL);
INSERT INTO products (product_id, product_category_id, supplier_id, created_by, product_name, product_uprice, product_ucost, created, product_details, terms, weight, remarks, is_active, updated_by, updated, narrative, image, details) VALUES (3, 1, 1, NULL, 'Tusky''s Kshs 5,000 Voucher', 5000, NULL, '2016-06-28', NULL, NULL, NULL, NULL, true, NULL, '2016-06-28 09:23:12.009596', NULL, NULL, NULL);
INSERT INTO products (product_id, product_category_id, supplier_id, created_by, product_name, product_uprice, product_ucost, created, product_details, terms, weight, remarks, is_active, updated_by, updated, narrative, image, details) VALUES (5, 1, 2, NULL, 'Nakumatt Ksh 2,000 Voucher', 2000, NULL, '2016-06-28', NULL, NULL, NULL, NULL, true, NULL, '2016-06-28 09:24:48.086772', NULL, NULL, NULL);
INSERT INTO products (product_id, product_category_id, supplier_id, created_by, product_name, product_uprice, product_ucost, created, product_details, terms, weight, remarks, is_active, updated_by, updated, narrative, image, details) VALUES (6, 1, 2, NULL, 'Nakumatt Ksh 5,000 Voucher', 5000, NULL, '2016-06-28', NULL, NULL, NULL, NULL, true, NULL, '2016-06-28 09:25:17.178204', NULL, NULL, NULL);
INSERT INTO products (product_id, product_category_id, supplier_id, created_by, product_name, product_uprice, product_ucost, created, product_details, terms, weight, remarks, is_active, updated_by, updated, narrative, image, details) VALUES (7, 3, 3, NULL, 'Airport transfer Ksh 2,000', 2000, NULL, '2016-06-28', NULL, NULL, NULL, NULL, true, NULL, '2016-06-28 09:26:11.388658', NULL, NULL, NULL);
INSERT INTO products (product_id, product_category_id, supplier_id, created_by, product_name, product_uprice, product_ucost, created, product_details, terms, weight, remarks, is_active, updated_by, updated, narrative, image, details) VALUES (1, 1, 1, NULL, 'Tusky''s Kshs 1,000 Voucher', 1000, NULL, '2016-06-28', NULL, NULL, NULL, NULL, true, NULL, '2016-06-28 09:19:30.282344', NULL, '1pic.jpg', NULL);
INSERT INTO products (product_id, product_category_id, supplier_id, created_by, product_name, product_uprice, product_ucost, created, product_details, terms, weight, remarks, is_active, updated_by, updated, narrative, image, details) VALUES (4, 1, 2, NULL, 'Nakumatt Ksh 1,000 Voucher', 1000, NULL, '2016-06-28', NULL, NULL, NULL, NULL, true, NULL, '2016-06-28 09:24:22.593581', NULL, '2pic.jpg', NULL);


--
-- Name: products_product_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('products_product_id_seq', 7, true);




--
-- Data for Name: sys_emails; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, default_email, title, details, use_type) VALUES (10, NULL, 'Donation', NULL, 'Sambaza Update status', NULL, 3);
INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, default_email, title, details, use_type) VALUES (9, NULL, 'Points', NULL, 'Points Generated', '<p>Dear {{name}}</p>

<p>Congratulations!!! Your points are ready for you to redeem.</p>

<p>&nbsp;</p>

<p>Sit back, &nbsp;choose by clicking a button of your preferred reward/s for delivery.</p>

<p>&nbsp;</p>

<p>Thank you</p>

<p>&nbsp;</p>

<p>Travel Creations Team</p>
', 3);
INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, default_email, title, details, use_type) VALUES (1, 0, 'Application', NULL, 'Application', '<p>Dear {{name}}</p>

<p>Your have successfully register with travelcreactions loyalty program.&nbsp;</p>

<p>&nbsp;We shall respond within the next 48hrs with your username and password.</p>

<p>&nbsp;</p>

<p>Thank you</p>

<p>&nbsp;</p>

<p>Travel Creations Team</p>
', 2);
INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, default_email, title, details, use_type) VALUES (2, 0, 'Clients account Activated', NULL, 'Clients Activated', '<p>Dear {{name}},</p>

<p>&nbsp;</p>

<p>Welcome to TCL Advantage Plus</p>

<p>&nbsp;</p>

<p>We are happy to inform you that your application for our loyalty program has been accepted.&nbsp;</p>

<p>&nbsp;</p>

<p>Username:{{username}}</p>

<p>password : {{password}}</p>

<p>Thank you</p>

<p>&nbsp;</p>

<p>Travel Creations Team</p>
', 2);
INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, default_email, title, details, use_type) VALUES (3, NULL, 'Clients Rejected', NULL, 'Clients Rejected', '<p>Dear{{name}},</p>

<p>Welcome to TCL Advantage Plus</p>

<p>&nbsp;</p>

<p>Thank you for applying for membership to our loyalty program</p>

<p>&nbsp;</p>

<p>We appreciate your interest&nbsp; in our program, unfortunately you don&rsquo;t qualify for membership.</p>

<p>&nbsp;</p>

<p>&nbsp;</p>

<p>&nbsp;</p>

<p><strong>Terms &amp; Conditions</strong></p>

<ol>
	<li>TCL Advantage Plus loyalty program is open to any individual, corporation, firm or other entities</li>
	<li>The applicant must supply all the information required while applying for membership and you will be guided through the registration process. At the end of the registration process, the system will attribute automatically your unique Username and Password&nbsp; to be recorded in each booking that you will create in the future.<br />
	<br />
	&nbsp;</li>
	<li>TCL Aadvantage Plus program may accept or reject any application for membership in its absolute discretion</li>
	<li>All points earned and not redeemed or utilized are cancelled upon a person or a company ceasing to be a member of TCL advantage Plus program or at expiry date</li>
	<li>Statements will be available to active members vide our website which will include, points earned, redeemed and expired</li>
	<li>Ticket taxes and VAT on tour bookings are not eligible to earn points</li>
	<li>Redeeming of rewards remain the sole responsibility of the member</li>
	<li>Points are redeemable twice a year i.e. 15 June and 15 December with a two week notice</li>
	<li>Points earned can be redeemed to purchase rewards from our shopping cart</li>
	<li>Points earned will be deducted in case of any cancelled services</li>
</ol>

<p>&nbsp;</p>

<p>Thank you</p>

<p>&nbsp;</p>

<p>Travel Creations Team</p>
', 2);
INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, default_email, title, details, use_type) VALUES (8, NULL, 'Reset Password', NULL, 'Password Reset', '<p>Dear {{name}},</p>

<p>Username: {{username}}</p>

<p>&nbsp;</p>

<p>Password : {{password}}</p>
', 1);

INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, default_email, title, details, use_type) VALUES (5, NULL, 'Order on processing ', NULL, 'Order on processing ', '<p><span style="color:#0075B0">Dear {{name}},</span></p>

<p><span style="color:#0075B0">Your order of </span>{{mailbody}}<span style="color:#0075B0"> is being processed, once ready for collection an email notification will be sent to you. </span></p>

<p>Regards,</p>

<p>Travel Creations Team</p>
', 3);
INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, default_email, title, details, use_type) VALUES (7, NULL, 'Order Collected', NULL, 'Order Collected', '<p><span style="color:#0075B0">Dear {{name}},</span></p>

<p><span style="color:#0075B0">Thank you for collecting the order in the subject line. Happy selling!</span></p>

<p>&nbsp;</p>

<p>Regards,</p>

<p>Travel Creations Team</p>
', 3);
INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, default_email, title, details, use_type) VALUES (6, 0, 'Order awaiting collection', NULL, 'Order awaiting collection', '<p>Dear {{name}},</p>

<p><span style="color:#0075B0">Your order&nbsp;</span>{{mailbody}}<span style="color:#0075B0"> is ready for collection. Please login to Travelcreactions go to the orders tab, download and print the collection document and present at the office during collection.</span></p>

<p>Regards,</p>

<p>Travel Creations Team</p>
', 3);
INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, default_email, title, details, use_type) VALUES (4, 0, 'Order submitted', NULL, 'Order submitted', '<p>Dear {{name}}</p>

<p>&nbsp;</p>

<p><span style="color:#0075B0">Your order of </span>{{mailbody}} <span style="color:#0075B0">has been submitted, you will be notified once the order processing begins. </span></p>

<p>&nbsp;</p>

<p>Regards,</p>

<p>Travel Creations Team</p>
', 3);


--
-- Name: sys_emails_sys_email_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('sys_emails_sys_email_id_seq', 10, true);


--
-- PostgreSQL database dump complete
--

--
-- Data for Name: workflows; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO workflows (workflow_id, source_entity_id, org_id, workflow_name, table_name, table_link_field, table_link_id, approve_email, reject_email, approve_file, reject_file, details) VALUES (1, 0, NULL, 'Applicant', 'clients', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO workflows (workflow_id, source_entity_id, org_id, workflow_name, table_name, table_link_field, table_link_id, approve_email, reject_email, approve_file, reject_file, details) VALUES (2, 4, NULL, 'Period points approval', 'periods', NULL, NULL, '<p>Request approved</p>
', '<p>Request rejected</p>', NULL, NULL, NULL);
INSERT INTO workflows (workflow_id, source_entity_id, org_id, workflow_name, table_name, table_link_field, table_link_id, approve_email, reject_email, approve_file, reject_file, details) VALUES (3, 4, NULL, 'Batch Orders ', 'orders', NULL, NULL, '<p>Request approved</p>
', '<p>Request rejected</p>', NULL, NULL, NULL);


--
-- Name: workflows_workflow_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('workflows_workflow_id_seq', 3, true);


--
-- Data for Name: workflow_phases; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO workflow_phases (workflow_phase_id, workflow_id, approval_entity_id, org_id, approval_level, return_level, escalation_days, escalation_hours, required_approvals, reporting_level, use_reporting, advice, notice, phase_narrative, advice_email, notice_email, advice_file, notice_file, details) VALUES (1, 1, 0, NULL, 1, 0, 0, 3, 1, 1, false, false, false, NULL, '<p>For your approval</p>
', '<p>Phase approved</p>
', NULL, NULL, NULL);
INSERT INTO workflow_phases (workflow_phase_id, workflow_id, approval_entity_id, org_id, approval_level, return_level, escalation_days, escalation_hours, required_approvals, reporting_level, use_reporting, advice, notice, phase_narrative, advice_email, notice_email, advice_file, notice_file, details) VALUES (2, 2, 4, NULL, 1, 0, 0, 3, 1, 1, false, false, false, NULL, '<p>For your approval</p>
', '<p>Phase approved</p>
', NULL, NULL, NULL);
INSERT INTO workflow_phases (workflow_phase_id, workflow_id, approval_entity_id, org_id, approval_level, return_level, escalation_days, escalation_hours, required_approvals, reporting_level, use_reporting, advice, notice, phase_narrative, advice_email, notice_email, advice_file, notice_file, details) VALUES (3, 3, 4, NULL, 1, 0, 0, 3, 1, 1, false, false, false, NULL, '<p>For your approval</p>
', '<p>Phase approved</p>
', NULL, NULL, NULL);


--
-- Name: workflow_phases_workflow_phase_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('workflow_phases_workflow_phase_id_seq', 3, true);
