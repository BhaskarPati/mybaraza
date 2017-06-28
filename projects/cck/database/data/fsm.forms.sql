INSERT INTO forms (form_id, form_name, form_number, version, completed, is_active)
VALUES (56, 'STM 1 ROUTES ANNUAL FREQUENCY FEES', 'STM1', '1.0', '1', '1');

INSERT INTO fields (field_id, form_id, question, field_type, field_order)
VALUES (49557, 56, 'STM 1 ROUTES', 'SUBGRID', 10);

INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49557, 10, 'TEXTFIELD', 'LINK NO');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49557, 20, 'TEXTFIELD', 'LINK ID');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49557, 30, 'TEXTFIELD', 'LINK TYPE');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49557, 40, 'TEXTFIELD', 'SITE NAME A');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49557, 50, 'TEXTFIELD', 'SITE NAME B');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49557, 60, 'TEXTFIELD', 'REGION');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49557, 70, 'TEXTFIELD', 'Link Configuration');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49557, 80, 'TEXTFIELD', 'Capacity');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49557, 90, 'TEXTFIELD', 'TX B- END');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49557, 100, 'TEXTFIELD', 'TX A- END');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49557, 110, 'TEXTFIELD', 'Operating Band (GHZ)');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49557, 120, 'TEXTFIELD', 'USO Factor');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49557, 130, 'TEXTFIELD', 'Bandwidth(MHz)');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49557, 140, 'TEXTFIELD', 'SAF Annual Frequency fee(Kshs)');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49557, 150, 'TEXTFIELD', 'CCK Annual Frequency fee(Kshs)');

INSERT INTO forms (form_id, form_name, form_number, version, completed, is_active)
VALUES (57, '7 GHz & 8 GHz ANNUAL FREQ', '7 - 8 GHz', '1.0', '1', '1');

INSERT INTO fields (field_id, form_id, question, field_type, field_order)
VALUES (49558, 57, '7 GHz & 8 GHz ANNUAL FREQ', 'SUBGRID', 10);

INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49558, 10, 'TEXTFIELD', 'No');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49558, 20, 'TEXTFIELD', 'SITE NAME B');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49558, 30, 'TEXTFIELD', 'SITE NAME A');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49558, 40, 'TEXTFIELD', 'REGION');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49558, 50, 'TEXTFIELD', 'Capacity');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49558, 60, 'TEXTFIELD', 'TX B- END');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49558, 70, 'TEXTFIELD', 'TX A- END');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49558, 80, 'TEXTFIELD', 'BAND ');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49558, 90, 'TEXTFIELD', 'USO');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49558, 100, 'TEXTFIELD', 'BW');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49558, 110, 'TEXTFIELD', 'ANNUAL FREQ FEE(Kshs)');

INSERT INTO forms (form_id, form_name, form_number, version, completed, is_active)
VALUES (58, '15 GHz', '15 GHz', '1.0', '1', '1');

INSERT INTO fields (field_id, form_id, question, field_type, field_order)
VALUES (49559, 58, '15 GHz', 'SUBGRID', 10);

INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49559, 10, 'TEXTFIELD', 'No.');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49559, 20, 'TEXTFIELD', 'SITE NAME A');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49559, 30, 'TEXTFIELD', 'SITE NAME B');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49559, 40, 'TEXTFIELD', 'REGION');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49559, 50, 'TEXTFIELD', 'CAPACITY');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49559, 60, 'TEXTFIELD', 'TX B- END');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49559, 70, 'TEXTFIELD', 'TX A- END');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49559, 80, 'TEXTFIELD', 'BAND ');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49559, 90, 'TEXTFIELD', 'USO');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49559, 100, 'TEXTFIELD', 'BW(MHz)');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49559, 110, 'TEXTFIELD', 'ANNUAL FEES(Kshs)');

INSERT INTO forms (form_id, form_name, form_number, version, completed, is_active)
VALUES (59, '23 GHz MICROWAVE FREQUENCIES', '23Ghz', '1.0', '1', '1');

INSERT INTO fields (field_id, form_id, question, field_type, field_order)
VALUES (49560, 59, '23Ghz MICROWAVE FREQUENCIES', 'SUBGRID', 10);

INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49560, 10, 'TEXTFIELD', 'No');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49560, 20, 'TEXTFIELD', 'STATION A');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49560, 30, 'TEXTFIELD', 'STATION B');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49560, 40, 'TEXTFIELD', 'REGION');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49560, 50, 'TEXTFIELD', 'TX FREQ(MHZ)');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49560, 60, 'TEXTFIELD', 'RX FREQ(MHZ)');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49560, 70, 'TEXTFIELD', 'CAPACITY(Mbps)');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49560, 80, 'TEXTFIELD', 'BW(MHZ)');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49560, 90, 'TEXTFIELD', 'USO');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49560, 100, 'TEXTFIELD', 'Spectrum Fee in Kshs.');

INSERT INTO forms (form_id, form_name, form_number, version, completed, is_active)
VALUES (61, '2 GHz Trx', '2 GHz', '1.0', '1', '1');

INSERT INTO fields (field_id, form_id, question, field_type, field_order)
VALUES (49561, 61, '2 GHz Trx', 'SUBGRID', 10);

INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49561, 10, 'TEXTFIELD', 'Site_ID');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49561, 20, 'TEXTFIELD', 'CI');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49561, 30, 'TEXTFIELD', 'Cell_name');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49561, 40, 'TEXTFIELD', 'BSC_NAME');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49561, 50, 'TEXTFIELD', 'MSC');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49561, 60, 'TEXTFIELD', 'BCCH');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49561, 70, 'TEXTFIELD', 'NoOFTRXs');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49561, 80, 'TEXTFIELD', 'HOPP');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49561, 90, 'TEXTFIELD', 'VENDOR');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49561, 100, 'TEXTFIELD', 'VERSION');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49561, 110, 'TEXTFIELD', 'LATITUDE');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49561, 120, 'TEXTFIELD', 'LONGITUDE');

INSERT INTO forms (form_id, form_name, form_number, version, completed, is_active)
VALUES (63, '3 GHz Trx', '3 GHz', '1.0', '1', '1');

INSERT INTO fields (field_id, form_id, question, field_type, field_order)
VALUES (49563, 63, '3 GHz Trx', 'SUBGRID', 10);

INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49563, 10, 'TEXTFIELD', 'SiteID');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49563, 20, 'TEXTFIELD', 'CellID');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49563, 30, 'TEXTFIELD', 'CellName');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49563, 40, 'TEXTFIELD', 'RRU');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49563, 50, 'TEXTFIELD', 'RNC_ID');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49563, 60, 'TEXTFIELD', 'RNC');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49563, 70, 'TEXTFIELD', 'VENDOR');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49563, 80, 'TEXTFIELD', 'LATITUDE');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49563, 90, 'TEXTFIELD', 'LONGITUDE');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49563, 100, 'TEXTFIELD', 'MSC');

INSERT INTO forms (form_id, form_name, form_number, version, completed, is_active)
VALUES (64, 'VSAT', 'VSAT', '1.0', '1', '1');

INSERT INTO fields (field_id, form_id, question, field_type, field_order)
VALUES (49564, 64, 'VSAT', 'SUBGRID', 10);

INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49564, 10, 'TEXTFIELD', 'SiteID');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49564, 20, 'TEXTFIELD', 'VSAT SITE NAME');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49564, 30, 'TEXTFIELD', 'DATA RATE (KBPS)');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49564, 40, 'TEXTFIELD', 'TX FREQ.');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49564, 50, 'TEXTFIELD', 'RX FREQ.');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49564, 60, 'TEXTFIELD', 'IF TX Power (dBm)');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49564, 70, 'TEXTFIELD', 'TX BW (KHz)');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49564, 80, 'TEXTFIELD', 'FREQ. FEE');

INSERT INTO forms (form_id, form_name, form_number, version, completed, is_active)
VALUES (65, 'Installed Links', 'I Link', '1.0', '1', '1');

INSERT INTO fields (field_id, form_id, question, field_type, field_order)
VALUES (49565, 65, 'Installed Links', 'SUBGRID', 10);

INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49565, 10, 'TEXTFIELD', 'Date of Assignment');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49565, 20, 'TEXTFIELD', 'Date of offer');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49565, 30, 'TEXTFIELD', 'Date of application');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49565, 40, 'TEXTFIELD', 'Link No');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49565, 50, 'TEXTFIELD', 'Link Name/ Classification');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49565, 60, 'TEXTFIELD', 'Site A ID');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49565, 70, 'TEXTFIELD', 'Site A   Name ');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49565, 80, 'TEXTFIELD', 'Site B ID');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49565, 90, 'TEXTFIELD', 'Site B   Name ');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49565, 110, 'TEXTFIELD', 'Site B Longitude (dd mm ss)');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49565, 120, 'TEXTFIELD', 'Site B Latitude    (dd mm ss)');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49565, 130, 'TEXTFIELD', 'Site B Antenna Height    (m)');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49565, 140, 'TEXTFIELD', 'Site B Antenna Polarisation (H/V)');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49565, 150, 'TEXTFIELD', 'Site B Equipment Make/ Model');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49565, 160, 'TEXTFIELD', 'Region (District)');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49565, 170, 'TEXTFIELD', 'TX Freq w.r.A (MHz)');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49565, 180, 'TEXTFIELD', 'RX Freq w.r.A (MHz)');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49565, 190, 'TEXTFIELD', 'Link Configuration (XxY)');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49565, 200, 'TEXTFIELD', 'Link Capacity (Mbps)');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49565, 210, 'TEXTFIELD', 'Link Bandwidth (MHz)');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49565, 220, 'TEXTFIELD', 'Operating Band (GHz)');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49565, 230, 'TEXTFIELD', 'USO Factor');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49565, 240, 'TEXTFIELD', 'Spectrum Fees');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49565, 250, 'TEXTFIELD', 'REMARKS');

INSERT INTO forms (form_id, form_name, form_number, version, completed, is_active)
VALUES (67, 'Decomisionned Links', 'D Link', '1.0', '1', '1');

INSERT INTO fields (field_id, form_id, question, field_type, field_order)
VALUES (49567, 67, 'Decomisionned Links', 'SUBGRID', 10);

INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49567, 10, 'TEXTFIELD', 'Date of Assignment');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49567, 20, 'TEXTFIELD', 'Date of offer');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49567, 30, 'TEXTFIELD', 'Date of application');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49567, 40, 'TEXTFIELD', 'Link No');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49567, 50, 'TEXTFIELD', 'Link Name/ Classification');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49567, 60, 'TEXTFIELD', 'Site A ID');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49567, 70, 'TEXTFIELD', 'Site A   Name ');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49567, 80, 'TEXTFIELD', 'Site B ID');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49567, 90, 'TEXTFIELD', 'Site B   Name ');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49567, 110, 'TEXTFIELD', 'Site B Longitude (dd mm ss)');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49567, 120, 'TEXTFIELD', 'Site B Latitude    (dd mm ss)');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49567, 130, 'TEXTFIELD', 'Site B Antenna Height    (m)');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49567, 140, 'TEXTFIELD', 'Site B Antenna Polarisation (H/V)');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49567, 150, 'TEXTFIELD', 'Site B Equipment Make/ Model');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49567, 160, 'TEXTFIELD', 'Region (District)');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49567, 170, 'TEXTFIELD', 'TX Freq w.r.A (MHz)');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49567, 180, 'TEXTFIELD', 'RX Freq w.r.A (MHz)');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49567, 190, 'TEXTFIELD', 'Link Configuration (XxY)');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49567, 200, 'TEXTFIELD', 'Link Capacity (Mbps)');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49567, 210, 'TEXTFIELD', 'Link Bandwidth (MHz)');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49567, 220, 'TEXTFIELD', 'Operating Band (GHz)');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49567, 230, 'TEXTFIELD', 'USO Factor');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49567, 240, 'TEXTFIELD', 'Spectrum Fees');
INSERT INTO sub_fields (field_id, sub_field_order, sub_field_type, question) VALUES (49567, 250, 'TEXTFIELD', 'REMARKS');

UPDATE sub_fields SET sub_field_size = 5;

INSERT INTO forms (form_id, form_name, form_number, version, completed, is_active)
VALUES (1, 'Summary of Adverts Paid for by the Commission', 'ADVERT 01', '1.0', '1', '1');

INSERT INTO fields (form_id, question, field_type, field_order, field_size)
VALUES (1, 'YEAR', 'TEXTFIELD', 10, 50);
INSERT INTO fields (form_id, question, field_type, field_order, field_size)
VALUES (1, 'MONTH', 'TEXTFIELD', 20, 50);
INSERT INTO fields (form_id, question, field_type, field_order, field_size)
VALUES (1, 'MEDIA', 'TEXTFIELD', 30, 50);
INSERT INTO fields (form_id, question, field_type, field_order, field_size)
VALUES (1, 'SIZE', 'TEXTFIELD', 40, 50);
INSERT INTO fields (form_id, question, field_type, field_order, field_size)
VALUES (1, 'COST', 'TEXTFIELD', 50, 50);
INSERT INTO fields (form_id, question, field_type, field_order, field_size)
VALUES (1, 'TITLE', 'TEXTFIELD', 60, 50);
INSERT INTO fields (form_id, question, field_type, field_order, field_size)
VALUES (1, 'DEPT', 'TEXTFIELD', 70, 50);
INSERT INTO fields (form_id, question, field_type, field_order, field_size)
VALUES (1, 'SIGN OFF', 'TEXTFIELD', 80, 50);

INSERT INTO forms (form_id, form_name, form_number, version, completed, is_active)
VALUES (2, 'TRAVEL SCHEDULE', 'TRAVEL 01', '1.0', '1', '1');

INSERT INTO fields (form_id, question, field_type, field_order, field_size)
VALUES (2, 'NAME', 'TEXTFIELD', 10, 50);
INSERT INTO fields (form_id, question, field_type, field_order, field_size)
VALUES (2, 'MEETING/ COURSE', 'TEXTFIELD', 20, 50);
INSERT INTO fields (form_id, question, field_type, field_order, field_size)
VALUES (2, 'DATE', 'TEXTFIELD', 30, 50);
INSERT INTO fields (form_id, question, field_type, field_order, field_size)
VALUES (2, 'VENUE', 'TEXTFIELD', 40, 50);
INSERT INTO fields (form_id, question, field_type, field_order, field_size)
VALUES (2, 'TRAVEL AGENT', 'TEXTFIELD', 50, 50);
INSERT INTO fields (form_id, question, field_type, field_order, field_size)
VALUES (2, 'TICKET COST', 'TEXTFIELD', 60, 50);
INSERT INTO fields (form_id, question, field_type, field_order, field_size)
VALUES (2, 'REPORT SUBMITTED', 'TEXTFIELD', 70, 50);
		

		 				
					 	
