INSERT INTO regions (region_id, region_name) VALUES ('1', 'Nairobi');
INSERT INTO regions (region_id, region_name) VALUES ('2', 'Rift Valley');
INSERT INTO regions (region_id, region_name) VALUES ('3', 'Eastern');
INSERT INTO regions (region_id, region_name) VALUES ('4', 'Nyanza');
INSERT INTO regions (region_id, region_name) VALUES ('5', 'Coast');
INSERT INTO regions (region_id, region_name) VALUES ('6', 'Central');
INSERT INTO regions (region_id, region_name) VALUES ('7', 'Western');
INSERT INTO regions (region_id, region_name) VALUES ('8', 'North-Eastern');
SELECT setval('regions_region_id_seq', 9);

INSERT INTO counties (county_id, region_id, county_name) VALUES ('1', '1', 'Nairobi');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('2', '2', 'Narok');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('3', '2', 'Turkana');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('4', '2', 'Elgeyo Marakwet');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('5', '2', 'Trans Nzoia');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('6', '2', 'Uasin Gishu');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('7', '2', 'Nandi');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('8', '2', 'Kericho');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('9', '2', 'Bomet');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('10', '2', 'Baringo');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('11', '2', 'Nakuru');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('12', '2', 'Samburu');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('13', '2', 'Laikipia');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('14', '2', 'Kajiado');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('15', '2', 'West Pokot');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('16', '3', 'Makueni');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('17', '3', 'Machakos');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('18', '3', 'Meru');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('19', '3', 'Tharaka Nithi');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('20', '3', 'Embu');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('21', '3', 'Isiolo');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('22', '3', 'Marsabit');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('23', '3', 'Kitui');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('24', '4', 'Siaya');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('25', '4', 'Kisii');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('26', '4', 'Nyamira');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('27', '4', 'Kisumu');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('28', '4', 'Homa Bay');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('29', '4', 'Migori');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('30', '5', 'Kwale');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('31', '5', 'Mombasa');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('32', '5', 'Taita Taveta');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('33', '5', 'Kilifi');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('34', '5', 'Lamu');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('35', '5', 'Tana River');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('36', '6', 'Kiambu');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('37', '6', 'Muranga');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('38', '6', 'Nyandarua');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('39', '6', 'Nyeri');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('40', '6', 'Kirinyaga');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('41', '7', 'Busia');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('42', '7', 'Bungoma');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('43', '7', 'Kakamega');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('44', '7', 'Vihiga');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('45', '8', 'Garissa');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('46', '8', 'Mandera');
INSERT INTO counties (county_id, region_id, county_name) VALUES ('47', '8', 'Wajir');
SELECT setval('counties_county_id_seq', 48);

INSERT INTO id_types (id_type_id, id_type_name) VALUES (1, 'National ID');
INSERT INTO id_types (id_type_id, id_type_name) VALUES (2, 'Passport');
INSERT INTO id_types (id_type_id, id_type_name) VALUES (3, 'PIN Number');
INSERT INTO id_types (id_type_id, id_type_name) VALUES (4, 'Company Certificate');
SELECT setval('id_types_id_type_id_seq', 2);

INSERT INTO division_types (division_type_id, division_type_name) VALUES (1, 'Crimal');
INSERT INTO division_types (division_type_id, division_type_name) VALUES (2, 'Civil');
SELECT setval('division_types_division_type_id_seq', 3);

INSERT INTO case_subjects (case_subject_id, case_subject_name) VALUES (1, 'Commercial');
INSERT INTO case_subjects (case_subject_id, case_subject_name) VALUES (2, 'Family');
INSERT INTO case_subjects (case_subject_id, case_subject_name) VALUES (3, 'Insurance');
INSERT INTO case_subjects (case_subject_id, case_subject_name) VALUES (4, 'Constitution');
INSERT INTO case_subjects (case_subject_id, case_subject_name) VALUES (5, 'Contract');
INSERT INTO case_subjects (case_subject_id, case_subject_name) VALUES (6, 'Electoral Disputes');
INSERT INTO case_subjects (case_subject_id, case_subject_name) VALUES (7, 'Criminal');
SELECT setval('case_subjects_case_subject_id_seq', 8);

INSERT INTO judgment_status (judgment_status_id, judgment_status_name) VALUES (1, 'Active');
INSERT INTO judgment_status (judgment_status_id, judgment_status_name) VALUES (2, 'Dormant');
INSERT INTO judgment_status (judgment_status_id, judgment_status_name) VALUES (3, 'Satisfied');
INSERT INTO judgment_status (judgment_status_id, judgment_status_name) VALUES (4, 'Partially satisfied');
INSERT INTO judgment_status (judgment_status_id, judgment_status_name) VALUES (5, 'Expired');
SELECT setval('judgment_status_judgment_status_id_seq', 6);

INSERT INTO order_types (order_type_id, order_type_name) VALUES (1, 'Witness Summons');
INSERT INTO order_types (order_type_id, order_type_name) VALUES (2, 'Warrant of Arrest');
INSERT INTO order_types (order_type_id, order_type_name) VALUES (3, 'Warrant of Commitment to Civil Jail');
INSERT INTO order_types (order_type_id, order_type_name) VALUES (4, 'Language Understood by Accused');
INSERT INTO order_types (order_type_id, order_type_name) VALUES (5, 'Release Order - where cash bail has been paid');
INSERT INTO order_types (order_type_id, order_type_name) VALUES (6, 'Release Order - where surety has signed bond');
INSERT INTO order_types (order_type_id, order_type_name) VALUES (7, 'Release Order');
INSERT INTO order_types (order_type_id, order_type_name) VALUES (8, 'Committal Warrant to Medical Institution/Mathare Mental Hospital');
INSERT INTO order_types (order_type_id, order_type_name) VALUES (9, 'Escort to Hospital for treatment, Age assessment or mental assessment');
INSERT INTO order_types (order_type_id, order_type_name) VALUES (10, 'Judgment Extraction');
INSERT INTO order_types (order_type_id, order_type_name) VALUES (11, 'Particulars of Surety');
INSERT INTO order_types (order_type_id, order_type_name) VALUES (12, 'Others');
SELECT setval('order_types_order_type_id_seq', 14);

INSERT INTO receipt_types (receipt_type_id, receipt_type_name, receipt_type_code) VALUES (1, 'Traffic Fine', 'TR');
INSERT INTO receipt_types (receipt_type_id, receipt_type_name, receipt_type_code) VALUES (2, 'Criminal Fine', 'CR');
INSERT INTO receipt_types (receipt_type_id, receipt_type_name, receipt_type_code) VALUES (3, 'Filing Fee', 'FF');
SELECT setval('receipt_types_receipt_type_id_seq', 14);

INSERT INTO payment_types (payment_type_id, payment_type_name, cash) VALUES (1, 'Cash Receipt', true);
INSERT INTO payment_types (payment_type_id, payment_type_name) VALUES (2, 'KCB Bank Payment');
INSERT INTO payment_types (payment_type_id, payment_type_name, for_credit_note) VALUES (3, 'Credit Note', true);
INSERT INTO payment_types (payment_type_id, payment_type_name, for_refund) VALUES (4, 'Refund', true);
SELECT setval('payment_types_payment_type_id_seq', 5);

INSERT INTO adjorn_reasons (adjorn_reason_id, adjorn_reason_name) VALUES (0, 'Not Adjorned');

ALTER TABLE cases
ADD	court_station_id integer,
ADD	decision_type_id integer,
ADD	judgement text,
ADD	decision_summary text;

ALTER TABLE cases ALTER court_division_id DROP NOT NULL;

