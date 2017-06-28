INSERT INTO contact_types (contact_type_id, contact_type_name, ep) VALUES (10, 'Petitioner', true); 
INSERT INTO contact_types (contact_type_id, contact_type_name) VALUES (11, 'Advocate of the Plaintiff');
INSERT INTO contact_types (contact_type_id, contact_type_name) VALUES (12, 'Advocate of the Defendant');
INSERT INTO contact_types (contact_type_id, contact_type_name, ep) VALUES (13, 'Advocate of the Petitioner', true);
INSERT INTO contact_types (contact_type_id, contact_type_name, ep) VALUES (14, 'Advocate of the Respondent', true);
INSERT INTO contact_types (contact_type_id, contact_type_name) VALUES (15, 'Defence Witness');
INSERT INTO contact_types (contact_type_id, contact_type_name, ep) VALUES (16, 'Petitioner Witness', true);
INSERT INTO contact_types (contact_type_id, contact_type_name, ep) VALUES (17, 'Respondent Witness', true);
SELECT setval('contact_types_contact_type_id_seq', 18);

UPDATE entity_types set org_id = 0;

UPDATE entitys SET ranking_id = 3 WHERE entity_type_id = 4 and ranking_id is null;

UPDATE entitys SET court_station_id = 2 WHERE entity_type_id = 4 and court_station_id is null;

