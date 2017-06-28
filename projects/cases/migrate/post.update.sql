UPDATE entitys SET id_type_id = 1;

UPDATE court_stations SET court_station_name = initcap(court_station_name);

UPDATE court_stations SET org_id = 2 where court_rank_id = 2;

UPDATE court_divisions SET org_id = 2 
WHERE court_station_id IN (SELECT court_station_id FROM court_stations WHERE court_rank_id = 2);

UPDATE hearing_locations SET org_id = 2 
WHERE court_station_id IN (SELECT court_station_id FROM court_stations WHERE court_rank_id = 2);

DELETE FROM bank_accounts
WHERE (org_id <> 0) AND (org_id IN 
(SELECT orgs.org_id FROM orgs LEFT JOIN court_stations ON orgs.org_id = court_stations.org_id
WHERE court_stations.org_id is null));

DELETE FROM orgs
WHERE (org_id <> 0) AND (org_id IN 
(SELECT orgs.org_id FROM orgs LEFT JOIN court_stations ON orgs.org_id = court_stations.org_id
WHERE court_stations.org_id is null));

UPDATE court_stations SET county_id = counties.county_id FROM counties
WHERE trim(upper(court_stations.court_station_name)) = trim(upper(counties.county_name));

UPDATE court_stations SET county_id = 6 WHERE trim(upper(court_stations.court_station_name)) = 'ELDORET';
UPDATE court_stations SET county_id = 5 WHERE trim(upper(court_stations.court_station_name)) = 'KITALE';
UPDATE court_stations SET county_id = 33 WHERE trim(upper(court_stations.court_station_name)) = 'MALINDI';
UPDATE court_stations SET county_id = 45 WHERE trim(upper(court_stations.court_station_name)) = 'GARRISSA';
UPDATE court_stations SET county_id = 1 WHERE trim(upper(court_stations.court_station_name)) = 'NSSF BUILDING';
UPDATE court_stations SET county_id = 1 WHERE trim(upper(court_stations.court_station_name)) = 'MILIMANI';

INSERT INTO case_types (case_type_id, case_type_name) VALUES (3, 'Crimal Appeal');
INSERT INTO case_types (case_type_id, case_type_name) VALUES (4, 'Civil Appeal');
SELECT setval('case_types_case_type_id_seq', 5);

UPDATE Case_Category SET case_type_id = 3 WHERE case_type_id = 1;
UPDATE Case_Category SET case_type_id = 4 WHERE case_type_id = 2;
SELECT setval('Case_Category_Case_Category_id_seq', 200);

SELECT case_category.case_category_id, case_category.case_category_name, count(cases.case_id)
FROM case_category INNER JOIN cases ON case_category.case_category_id = cases.case_category_id
GROUP BY case_category.case_category_id, case_category.case_category_name;

UPDATE case_category SET case_type_id = 3 WHERE case_category_id = 174;
UPDATE case_category SET case_type_id = 4 WHERE case_category_id = 172;
UPDATE case_category SET case_type_id = 4 WHERE case_category_id = 21;
UPDATE case_category SET case_type_id = 4 WHERE case_category_id = 173;

UPDATE cases SET court_division_id = court_divisions.court_division_id FROM court_divisions
WHERE (cases.court_station_id = court_divisions.court_station_id) AND (court_divisions.division_type_id = 1)
AND (cases.case_category_id IN (SELECT case_category.case_category_id FROM case_category WHERE case_category.case_type_id = 3));

UPDATE cases SET court_division_id = court_divisions.court_division_id FROM court_divisions
WHERE (cases.court_station_id = court_divisions.court_station_id) AND (court_divisions.division_type_id = 2)
AND (cases.case_category_id IN (SELECT case_category.case_category_id FROM case_category WHERE case_category.case_type_id = 4));

DELETE
FROM cases
WHERE court_division_id is null;

UPDATE cases SET org_id = court_divisions.org_id FROM court_divisions
WHERE (cases.court_division_id = court_divisions.court_division_id);

UPDATE cases SET case_subject_id = 1;

INSERT INTO case_activity (hearing_location_id, court_station_id, 
	org_id, case_activity_id, case_id,
	activity_result_id, adjorn_reason_id, activity_id, activity_date, activity_time, finish_time)
SELECT hearing_locations.hearing_location_id, hearing_locations.court_station_id,
	cases.org_id, case_id, case_id, 
	6, 0, 12, COALESCE(end_date, start_date), '10:00:00'::time, '11:00:00'::time
FROM cases INNER JOIN hearing_locations ON cases.court_station_id = hearing_locations.court_station_id
WHERE decision_type_id is not null;
SELECT setval('case_activity_case_activity_id_seq', 7000);

INSERT INTO case_decisions (org_id, case_id, case_activity_id, decision_type_id, judgment_status_id, 
	decision_summary, judgement, judgement_date)
SELECT org_id, case_id, case_id, decision_type_id, 1,
	decision_summary, judgement, COALESCE(end_date, start_date)
FROM cases
WHERE decision_type_id is not null;

INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '1.01', 'Murder, Manslaughter and Infanticide', 'Murder');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '1.02', 'Murder, Manslaughter and Infanticide', 'Manslaughter');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '1.03', 'Murder, Manslaughter and Infanticide', 'Manslaughter (Fatal Accident)');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '1.04', 'Murder, Manslaughter and Infanticide', 'Suspicious  Death');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '1.05', 'Murder, Manslaughter and Infanticide', 'Attempted Murder');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '1.06', 'Murder, Manslaughter and Infanticide', 'Infanticide');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '2.01', 'Other Serious Violent Offences', 'Abduction');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '2.02', 'Other Serious Violent Offences', 'Act intending to cause GBH');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '2.03', 'Other Serious Violent Offences', 'Assault on a Police Officer');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '2.04', 'Other Serious Violent Offences', 'Assaulting a child');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '2.05', 'Other Serious Violent Offences', 'Grievous Harm');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '2.06', 'Other Serious Violent Offences', 'Grievous Harm (D.V)');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '2.07', 'Other Serious Violent Offences', 'Kidnapping');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '2.08', 'Other Serious Violent Offences', 'Physical abuse');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '2.09', 'Other Serious Violent Offences', 'Wounding');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '2.10', 'Other Serious Violent Offences', 'Wounding (D.V)');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '3.01', 'Robberies', 'Attempted robbery');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '3.02', 'Robberies', 'Robbery with violence');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '3.03', 'Robberies', 'Robbery of mobile phone');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '4.01', 'Sexual offences', 'Attempted rape');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '4.02', 'Sexual offences', 'Rape');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '4.03', 'Sexual offences', 'Child abuse');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '4.04', 'Sexual offences', 'Indecent assault');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '4.05', 'Sexual offences', 'Sexual Abuse');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '4.06', 'Sexual offences', 'Sexual assault');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '4.07', 'Sexual offences', 'Sexual interference with a child');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '5.01', 'Other Offences Against the Person', 'A.O.A.B.H');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '5.02', 'Other Offences Against the Person', 'A.O.A.B.H (D.V)');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '5.03', 'Other Offences Against the Person', 'Assaulting a child');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '5.04', 'Other Offences Against the Person', 'Assaulting a child (D.V)');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '5.05', 'Other Offences Against the Person', 'Child neglect');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '5.06', 'Other Offences Against the Person', 'Common Assault');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '5.07', 'Other Offences Against the Person', 'Common Assault (D.V)');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '5.08', 'Other Offences Against the Person', 'Indecent act');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '5.09', 'Other Offences Against the Person', 'Obstruction of a Police Officer');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '5.10', 'Other Offences Against the Person', 'Procuring Abortion');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '5.11', 'Other Offences Against the Person', 'Resisting arrest');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '5.12', 'Other Offences Against the Person', 'Seditious offences');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '5.13', 'Other Offences Against the Person', 'Threatening Violence (D.V)');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '5.14', 'Other Offences Against the Person', 'Threatening Violence ');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '6.01', 'Property Offences', 'Attempted breaking');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '6.02', 'Property Offences', 'Attempted burglary');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '6.03', 'Property Offences', 'Breaking into a building other than a dwelling');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '6.04', 'Property Offences', 'Breaking into a building other than a dwelling and stealing');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '6.05', 'Property Offences', 'Breaking into a building with intent to commit a felony');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '6.06', 'Property Offences', 'Burglary');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '6.07', 'Property Offences', 'Burglary and stealing');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '6.08', 'Property Offences', 'Entering a dwelling house ');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '6.09', 'Property Offences', 'Entering a dwelling house and stealing');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '6.10', 'Property Offences', 'Entering a dwelling house with intent to commit a felony');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '6.11', 'Property Offences', 'Entering a building with intent to commit a felony');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '6.12', 'Property Offences', 'House breaking ');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '6.13', 'Property Offences', 'House breaking and stealing');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '6.14', 'Property Offences', 'House breaking with intent to commit a felony');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '6.15', 'Property Offences', 'Stealing by servant');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '6.16', 'Property Offences', 'Stealing from vehicle');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '6.17', 'Property Offences', 'Stealing');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '6.18', 'Property Offences', 'Unlawful use of a vehicle');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '6.19', 'Property Offences', 'Unlawful possession of property');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '6.20', 'Property Offences', 'Unlawful use of boat or vessel');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '7.01', 'Theft', 'Attempted stealing');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '7.02', 'Theft', 'Beach theft');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '7.03', 'Theft', 'Receiving stolen property');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '7.04', 'Theft', 'Retaining Stolen Property');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '7.05', 'Theft', 'Stealing');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '7.06', 'Theft', 'Stealing by finding');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '7.07', 'Theft', 'Stealing by servant');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '7.08', 'Theft', 'Stealing from boat or vessel');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '7.09', 'Theft', 'Stealing from dwelling house');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '7.10', 'Theft', 'Stealing from hotel room');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '7.11', 'Theft', 'Stealing from person');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '7.12', 'Theft', 'Stealing from vehicle');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '7.13', 'Theft', 'Unlawful possession of property');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '7.14', 'Theft', 'Unlawful use of a vehicle');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '7.15', 'Theft', 'Unlawful use of boat or vessel');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '8.01', 'Arson and criminal damage', 'Arson');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '8.02', 'Arson and criminal damage', 'Attempted Arson');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '8.03', 'Arson and criminal damage', 'Criminal trespass');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '8.04', 'Arson and criminal damage', 'Damaging government property');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '8.05', 'Arson and criminal damage', 'Damaging property');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '9.01', 'Fraud', 'Bribery');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '9.02', 'Fraud', 'Extortion ');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '9.03', 'Fraud', 'False accounting');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '9.04', 'Fraud', 'Forgery');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '9.05', 'Fraud', 'Fraud');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '9.06', 'Fraud', 'Giving false information to Govt employee');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '9.07', 'Fraud', 'Importing or purchasing forged notes');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '9.08', 'Fraud', 'Issuing a cheque without provision');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '9.09', 'Fraud', 'Misappropriation of money');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '9.10', 'Fraud', 'Money laundering');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '9.11', 'Fraud', 'Obtaining credit by false pretence');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '9.12', 'Fraud', 'Obtaining fares by false pretence');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '9.13', 'Fraud', 'Obtaining goods by false pretence');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '9.14', 'Fraud', 'Obtaining money by false pretence');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '9.15', 'Fraud', 'Obtaining service by false pretence');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '9.16', 'Fraud', 'Offering a bribe to Govt employee');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '9.17', 'Fraud', 'Perjury');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '9.18', 'Fraud', 'Possession of false/counterfeit currency');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '9.19', 'Fraud', 'Possession of false document');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '9.20', 'Fraud', 'Trading as a contractor without a licence');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '9.21', 'Fraud', 'Trading without a licence');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '9.22', 'Fraud', 'Unlawful possession of forged notes');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '9.23', 'Fraud', 'Uttering false notes');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '10.01', 'Public Order Offences', 'Affray');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '10.02', 'Public Order Offences', 'Attempt to commit negligent act to cause harm');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '10.03', 'Public Order Offences', 'Burning rubbish without permit');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '10.04', 'Public Order Offences', 'Common Nuisance');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '10.05', 'Public Order Offences', 'Consuming alcohol in a public place');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '10.06', 'Public Order Offences', 'Cruelty to animals');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '10.07', 'Public Order Offences', 'Defamation of the President');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '10.08', 'Public Order Offences', 'Disorderly conduct in a Police building');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '10.09', 'Public Order Offences', 'Entering a restricted airport attempting to board');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '10.10', 'Public Order Offences', 'Idle and disorderly (A-i)');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '10.11', 'Public Order Offences', 'Insulting the modesty of a woman');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '10.12', 'Public Order Offences', 'Loitering');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '10.13', 'Public Order Offences', 'Negligent act');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '10.14', 'Public Order Offences', 'Rash and negligent act');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '10.15', 'Public Order Offences', 'Reckless or negligent act');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '10.16', 'Public Order Offences', 'Rogue and vagabond');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '10.17', 'Public Order Offences', 'Unlawful assembly');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '10.18', 'Public Order Offences', 'Throwing litter in a public place');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '10.19', 'Public Order Offences', 'Using obscene and indescent language in public place');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '11.01', 'Offences relating to the administration of justice', 'Aiding and abetting escape prisoner');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '11.02', 'Offences relating to the administration of justice', 'Attempted escape');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '11.03', 'Offences relating to the administration of justice', 'Breach of court order');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '11.04', 'Offences relating to the administration of justice', 'Contempt of court');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '11.05', 'Offences relating to the administration of justice', 'Escape from lawful custody');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '11.06', 'Offences relating to the administration of justice', 'Failing to comply with bail');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '11.07', 'Offences relating to the administration of justice', 'Refuse to give name');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '11.08', 'Offences relating to the administration of justice', 'Trafficking in hard drugs');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '12.01', 'Drugs', 'Cultivation of controlled drugs');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '12.02', 'Drugs', 'Importation of controlled drugs');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '12.03', 'Drugs', 'Possession of controlled drugs');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '12.04', 'Drugs', 'Possession of hard drugs');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '12.05', 'Drugs', 'Poss of syringe for consumption or administration of controlled drugs.');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '12.06', 'Drugs', 'Presumption of Consumption Of Controlled Drugs');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '12.07', 'Drugs', 'Refuse to give control samples');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '12.08', 'Drugs', 'Trafficking controlled drugs');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '12.09', 'Drugs', 'Trafficking in hard drugs');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '13.01', 'Weapons and Ammunition', 'Importation of firearm and ammunition');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '13.02', 'Weapons and Ammunition', 'Possession of explosive(includes Tuna Crackers)');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '13.03', 'Weapons and Ammunition', 'Possession of offensive weapon');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '13.04', 'Weapons and Ammunition', 'Possession of spear gun');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '13.05', 'Weapons and Ammunition', 'Unlawful possession of a firearm');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '14.01', 'Environment and Fisheries', 'Catching turtle');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '14.02', 'Environment and Fisheries', 'Cutting or selling protected trees without a permit');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '14.03', 'Environment and Fisheries', 'Cutting protected trees without a permit');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '14.04', 'Environment and Fisheries', 'Dealing in nature nuts');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '14.05', 'Environment and Fisheries', 'Illegal fishing in Seychelles territoiral waters');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '14.06', 'Environment and Fisheries', 'Possession of Coco De Mer without a permit');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '14.07', 'Environment and Fisheries', 'Removal of sand without permit');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '14.08', 'Environment and Fisheries', 'Selling Protected trees');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '14.09', 'Environment and Fisheries', 'Stealing protected animals');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '14.10', 'Environment and Fisheries', 'Taking or processing of sea cucumber without a licence');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '14.11', 'Environment and Fisheries', 'Unauthorised catching of sea cucumber in Seychelles');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '14.12', 'Environment and Fisheries', 'Unlawful possession of a turtle meat, turtle shell, dolphin and lobster');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '15.01', 'Other crimes Not Elsewhere Classified (Miscellaneous)', 'Piracy');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '15.02', 'Other crimes Not Elsewhere Classified (Miscellaneous)', 'Allowing animals to stray');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '15.03', 'Other crimes Not Elsewhere Classified (Miscellaneous)', 'Bigamy');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '15.04', 'Other crimes Not Elsewhere Classified (Miscellaneous)', 'Endangering the safety of an aircraft');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '15.05', 'Other crimes Not Elsewhere Classified (Miscellaneous)', 'Gamble');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '15.06', 'Other crimes Not Elsewhere Classified (Miscellaneous)', 'Illegal connection of water');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '15.07', 'Other crimes Not Elsewhere Classified (Miscellaneous)', 'Killing of an animal with intent to steal');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '15.08', 'Other crimes Not Elsewhere Classified (Miscellaneous)', 'Possesion of more than 20 litres of baka or lapire without licence');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '15.09', 'Other crimes Not Elsewhere Classified (Miscellaneous)', 'Possession of pornographic materials');
INSERT INTO Case_Category (case_type_id, Case_Category_no, Case_Category_title, Case_Category_name) VALUES ('1', '15.10', 'Other crimes Not Elsewhere Classified (Miscellaneous)', 'Prohibited goods');

INSERT INTO Case_Category (case_type_id, Case_Category_name) VALUES ('2', 'Divorce');
INSERT INTO Case_Category (case_type_id, Case_Category_name) VALUES ('2', 'Civil Ex-Parte');
INSERT INTO Case_Category (case_type_id, Case_Category_name) VALUES ('2', 'Civil Suit');
INSERT INTO Case_Category (case_type_id, Case_Category_name) VALUES ('2', 'Petition/Application');
INSERT INTO Case_Category (case_type_id, Case_Category_name) VALUES ('2', 'Miscellaneous Application');


DELETE FROM case_transfers
WHERE case_id is null;
DELETE FROM case_transfers
WHERE court_station_id is null;
DELETE FROM case_transfers
WHERE judgment_date is null;

DELETE FROM case_transfers
WHERE (case_transfer_id IN
	(select max(case_transfer_id)
	from case_transfers
	group by case_id
	having count(case_id) > 1));

SELECT case_category.case_category_id, case_category.case_category_name, count(cases.case_id)
FROM case_category INNER JOIN cases ON case_category.case_category_id = cases.case_category_id
GROUP BY case_category.case_category_id, case_category.case_category_name;


ALTER TABLE cases
ADD	case_transfer_id integer,
ADD old_tf_case_id	integer;

SELECT setval('cases_case_id_seq', 7000);

INSERT INTO cases (case_category_id, case_subject_id, closed, case_locked, 
	case_transfer_id, old_tf_case_id, court_division_id, org_id,
	case_title, file_number, start_date, end_date, decision_summary)
SELECT 201, 7, true, true,
	case_transfers.case_transfer_id, case_transfers.case_id, court_divisions.court_division_id, court_divisions.org_id,
	cases.case_title, case_transfers.previous_case_number, 
	case_transfers.judgment_date, case_transfers.judgment_date, 'Judgement by ' || case_transfers.presiding_judge
FROM case_transfers INNER JOIN cases ON case_transfers.case_id = cases.case_id
	INNER JOIN court_divisions ON court_divisions.court_station_id = case_transfers.court_station_id
WHERE (cases.case_category_id = 174) AND (court_divisions.division_type_id = 1);

INSERT INTO cases (case_category_id, case_subject_id, closed, case_locked, 
	case_transfer_id, old_tf_case_id, court_division_id, org_id,
	case_title, file_number, start_date, end_date, decision_summary)
SELECT 221, 7, true, true,
	case_transfers.case_transfer_id, case_transfers.case_id, court_divisions.court_division_id, court_divisions.org_id,
	cases.case_title, case_transfers.previous_case_number, 
	case_transfers.judgment_date, case_transfers.judgment_date, 'Judgement by ' || case_transfers.presiding_judge
FROM case_transfers INNER JOIN cases ON case_transfers.case_id = cases.case_id
	INNER JOIN court_divisions ON court_divisions.court_station_id = case_transfers.court_station_id
WHERE (cases.case_category_id = 21) AND (court_divisions.division_type_id = 1);

INSERT INTO cases (case_category_id, case_subject_id, closed, case_locked, 
	case_transfer_id, old_tf_case_id, court_division_id, org_id,
	case_title, file_number, start_date, end_date, decision_summary)
SELECT 369, 1, true, true,
	case_transfers.case_transfer_id, case_transfers.case_id, court_divisions.court_division_id, court_divisions.org_id,
	cases.case_title, case_transfers.previous_case_number, 
	case_transfers.judgment_date, case_transfers.judgment_date, 'Judgement by ' || case_transfers.presiding_judge
FROM case_transfers INNER JOIN cases ON case_transfers.case_id = cases.case_id
	INNER JOIN court_divisions ON court_divisions.court_station_id = case_transfers.court_station_id
WHERE ((cases.case_category_id = 172) OR (cases.case_category_id = 173)) AND (court_divisions.division_type_id = 2);

INSERT INTO case_activity (hearing_location_id, court_station_id, 
	org_id, case_activity_id, case_id,
	activity_result_id, adjorn_reason_id, activity_id, activity_date, activity_time, finish_time)
SELECT hearing_locations.hearing_location_id, hearing_locations.court_station_id,
	cases.org_id, case_id, case_id, 
	6, 0, 12, COALESCE(end_date, start_date), '10:00:00'::time, '11:00:00'::time
FROM cases INNER JOIN court_divisions ON cases.court_division_id = court_divisions.court_division_id
	INNER JOIN hearing_locations ON court_divisions.court_station_id = hearing_locations.court_station_id
WHERE (case_transfer_id is not null) AND (hearing_locations.hearing_location_name = 'Room 1');
SELECT setval('case_activity_case_activity_id_seq', 11000);

INSERT INTO case_decisions (org_id, case_id, case_activity_id, decision_type_id, judgment_status_id, 
	decision_summary, judgement, judgement_date)
SELECT org_id, case_id, case_id, decision_type_id, 1,
	decision_summary, judgement, COALESCE(end_date, start_date)
FROM cases
WHERE case_transfer_id is not null;

SELECT setval('case_contacts_case_contact_id_seq', 20000);

INSERT INTO case_contacts (case_id, entity_id, contact_type_id, details)
SELECT cases.old_case_id, case_contacts.entity_id, case_contacts.contact_type_id, case_contacts.details
FROM case_contacts INNER JOIN cases ON case_contacts.case_id = cases.case_id
WHERE (case_contacts.contact_type_id <> 1) AND (cases.old_case_id is not null);


SELECT setval('entitys_entity_id_seq', 16000);


