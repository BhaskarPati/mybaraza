CREATE TABLE dc_judgments (
	dc_judgment_id			serial primary key,
	dc_judgment_name		varchar(240),
	details					text
);

CREATE TABLE dc_category (
	dc_category_id			serial primary key,
	dc_category_name		varchar(240),
	category_type			integer default 1 not null,
	court_level				integer default 1 not null,
	children_category		boolean default false not null,
	details					text
);

CREATE TABLE dc_cases (
	dc_case_id				serial primary key,
	dc_category_id			integer references dc_category,
	dc_judgment_id			integer references dc_judgments,
	court_division_id		integer references court_divisions,
	entity_id				integer references entitys,
	org_id					integer references orgs,
	case_title				varchar(320) not null,
	file_number				varchar(50) not null,
	appeal					boolean default false not null,
	date_of_arrest			date,
	ob_number				varchar(120),
	alleged_crime			text,
	start_date				date not null,
	mention_date			date,
	hearing_date			date,
	end_date				date,
	value_of_claim			real,
	Name_of_litigant		varchar(320),
	litigant_age			integer,
	male_litigants			integer,
	female_litigant			integer,
	Number_of_witnesses		integer,
	Previous_conviction		boolean default false not null,
	legal_representation	boolean default false not null,
	closed					boolean default false not null,
	change_by				integer,
	change_date				timestamp default now(),
	adjournment_reason		text,
	judgment_summary		text,
	detail					text
);
CREATE INDEX dc_cases_dc_category_id ON dc_cases (dc_category_id);
CREATE INDEX dc_cases_dc_judgment_id ON dc_cases (dc_judgment_id);
CREATE INDEX dc_cases_court_division_id ON dc_cases (court_division_id);
CREATE INDEX dc_cases_entity_id ON dc_cases (entity_id);
CREATE INDEX dc_cases_org_id ON dc_cases (org_id);

CREATE TABLE dc_receipts (
	dc_receipt_id			serial primary key,
	dc_case_id				integer references dc_cases,
	receipt_type_id			integer references receipt_types,
	org_id					integer references orgs,
	receipt_for				varchar(320),
	receipt_date			date,
	amount					real not null,
	change_by				integer,
	change_date				timestamp default now(),
	details					text
);
CREATE INDEX dc_receipts_dc_case_id ON dc_receipts (dc_case_id);
CREATE INDEX dc_receipts_receipt_type_id ON dc_receipts (receipt_type_id);
CREATE INDEX dc_receipts_org_id ON dc_receipts (org_id);

CREATE VIEW vw_dc_cases AS
	SELECT dc_category.dc_category_id, dc_category.dc_category_name, dc_category.category_type, dc_category.court_level,
		dc_judgments.dc_judgment_id, dc_judgments.dc_judgment_name, 

		vw_court_divisions.region_id, vw_court_divisions.region_name, vw_court_divisions.county_id, vw_court_divisions.county_name,
		vw_court_divisions.court_rank_id, vw_court_divisions.court_rank_name, 
		vw_court_divisions.court_station_id, vw_court_divisions.court_station_name, vw_court_divisions.court_station_code, vw_court_divisions.court_station,
		vw_court_divisions.division_type_id, vw_court_divisions.division_type_name, 
		vw_court_divisions.court_division_id, vw_court_divisions.court_division_code, vw_court_divisions.court_division_num,
		vw_court_divisions.court_division,

		entitys.entity_id, entitys.entity_name, 

		dc_cases.org_id, dc_cases.dc_case_id, dc_cases.case_title, dc_cases.file_number, dc_cases.date_of_arrest, 
		dc_cases.ob_number, dc_cases.alleged_crime, dc_cases.start_date, dc_cases.mention_date, dc_cases.hearing_date, 
		dc_cases.end_date, dc_cases.value_of_claim, dc_cases.name_of_litigant, dc_cases.litigant_age, 
		dc_cases.male_litigants, dc_cases.female_litigant, dc_cases.number_of_witnesses, dc_cases.previous_conviction, 
		dc_cases.legal_representation, dc_cases.closed, dc_cases.change_by, dc_cases.change_date, 
		dc_cases.adjournment_reason, dc_cases.judgment_summary, dc_cases.appeal, dc_cases.detail
	FROM dc_cases INNER JOIN dc_category ON dc_cases.dc_category_id = dc_category.dc_category_id
		INNER JOIN dc_judgments ON dc_cases.dc_judgment_id = dc_judgments.dc_judgment_id
		INNER JOIN vw_court_divisions ON dc_cases.court_division_id = vw_court_divisions.court_division_id
		INNER JOIN entitys ON dc_cases.entity_id = entitys.entity_id;

CREATE VIEW vw_dc_receipts AS
	SELECT vw_dc_cases.dc_category_id, vw_dc_cases.dc_category_name, 

		vw_dc_cases.region_id, vw_dc_cases.region_name, vw_dc_cases.county_id, vw_dc_cases.county_name,
		vw_dc_cases.court_rank_id, vw_dc_cases.court_rank_name, 
		vw_dc_cases.court_station_id, vw_dc_cases.court_station_name, vw_dc_cases.court_station_code, vw_dc_cases.court_station,
		vw_dc_cases.division_type_id, vw_dc_cases.division_type_name, 
		vw_dc_cases.court_division_id, vw_dc_cases.court_division_code, vw_dc_cases.court_division_num,
		vw_dc_cases.court_division,

		vw_dc_cases.dc_judgment_id, vw_dc_cases.dc_judgment_name, 
		vw_dc_cases.entity_id, vw_dc_cases.entity_name, 

		vw_dc_cases.dc_case_id, vw_dc_cases.case_title, vw_dc_cases.file_number, vw_dc_cases.date_of_arrest, 
		vw_dc_cases.ob_number, vw_dc_cases.alleged_crime, vw_dc_cases.start_date, vw_dc_cases.mention_date, 
		vw_dc_cases.hearing_date, vw_dc_cases.end_date, vw_dc_cases.value_of_claim, vw_dc_cases.name_of_litigant, 
		vw_dc_cases.litigant_age, vw_dc_cases.male_litigants, vw_dc_cases.female_litigant, vw_dc_cases.number_of_witnesses, 
		vw_dc_cases.previous_conviction, vw_dc_cases.legal_representation, vw_dc_cases.closed, 
		vw_dc_cases.adjournment_reason, vw_dc_cases.judgment_summary,

		receipt_types.receipt_type_id, receipt_types.receipt_type_name,

		dc_receipts.org_id, dc_receipts.dc_receipt_id, dc_receipts.receipt_for, dc_receipts.receipt_date, 
		dc_receipts.amount, dc_receipts.change_by, dc_receipts.change_date, dc_receipts.details
	FROM dc_receipts INNER JOIN vw_dc_cases ON dc_receipts.dc_case_id = vw_dc_cases.dc_case_id
		INNER JOIN receipt_types ON dc_receipts.receipt_type_id = receipt_types.receipt_type_id;

CREATE OR REPLACE FUNCTION month_diff(date, date) RETURNS integer AS $$
	SELECT CAST(((DATE_PART('year', $2) - DATE_PART('year', $1)) * 12) + (DATE_PART('month', $2) - DATE_PART('month', $1)) as integer);
$$ LANGUAGE SQL;

INSERT INTO dc_judgments (dc_judgment_name) VALUES('Not Heard');
INSERT INTO dc_judgments (dc_judgment_name) VALUES('Adjonment');
INSERT INTO dc_judgments (dc_judgment_name) VALUES('Solved on application');
INSERT INTO dc_judgments (dc_judgment_name) VALUES('Bail');
INSERT INTO dc_judgments (dc_judgment_name) VALUES('Appeals allowed and persons acquitted/discharged');
INSERT INTO dc_judgments (dc_judgment_name) VALUES('Appeals allowed and sentence reduced');
INSERT INTO dc_judgments (dc_judgment_name) VALUES('Appeals dismissed and sentence upheld');
INSERT INTO dc_judgments (dc_judgment_name) VALUES('Appeals dismissed and sentence enhanced');
INSERT INTO dc_judgments (dc_judgment_name) VALUES('Rulings/judgments made per Judge');
INSERT INTO dc_judgments (dc_judgment_name) VALUES('Fined');
INSERT INTO dc_judgments (dc_judgment_name) VALUES('Sent to prison');
INSERT INTO dc_judgments (dc_judgment_name) VALUES('Sent to CSO');
INSERT INTO dc_judgments (dc_judgment_name) VALUES('Remand');
INSERT INTO dc_judgments (dc_judgment_name) VALUES('Sentenced to probation (Adults)');
INSERT INTO dc_judgments (dc_judgment_name) VALUES('Sentenced to probation (Children in conflict with the law)');
INSERT INTO dc_judgments (dc_judgment_name) VALUES('Repatriated');
INSERT INTO dc_judgments (dc_judgment_name) VALUES('Juveniles sentenced to Borstal');
INSERT INTO dc_judgments (dc_judgment_name) VALUES('Juveniles sentenced to Approved School');
INSERT INTO dc_judgments (dc_judgment_name) VALUES('Juveniles sentenced to Corrective Training Centre');

INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (1, 2, false, 'Murder, manslaughter, attempted murder and suicide, assault with maim, grevious harm and affray');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (1, 3, false, 'Miscellaneous Applications');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (1, 3, false, 'Ordinary Criminal Appeals');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (1, 3, false, 'Capital Appeals');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (1, 3, false, 'Criminal Revisions');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (1, 1, false, 'Robbery');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (1, 1, false, 'Robbery with violence');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (1, 1, false, 'Unlawful assembly and riots');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (1, 1, false, 'Offenses allied to stealing');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (1, 1, false, 'Forgery and impersonation');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (1, 1, false, 'Assault');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (1, 1, false, 'Theft');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (1, 1, false, 'Children in conflict with the law');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (1, 1, false, 'Sexual offenses');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (1, 1, false, 'Offenses against morality e.g conspiracy to defile, to procure an abortion, gender based violance etc.');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (1, 1, false, 'Offenses against marrige and domestic obligations');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (1, 1, false, 'Offenses against Liberty e.g kidnapping, malicious injury to property etc.');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (1, 1, false, 'Other criminal matters filed under Acts of Parliament');

INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (2, 1, false, 'Tort (Personal injury/ defamation)');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (2, 1, false, 'Negligence and recklessness');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (2, 1, false, 'Disputes from contracts (excluding land)');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (2, 1, false, 'Traffic cases');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (2, 1, false, 'Land (cases not involving title deeds)');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (2, 1, false, 'Succession');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (2, 1, false, 'Matrimonial Cases');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (2, 1, true, 'Children cases : Adoption');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (2, 1, true, 'Children cases : Protection and care');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (2, 1, true, 'Children cases : Child maintenance and custody');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (2, 1, true, 'Children cases : Committal proceedings for abandoned babies');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (2, 1, true, 'Children cases : Miscellaneous applications (including applications not under Childrens Act)');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (2, 1, false, 'Anti corruption and economic crime cases');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (2, 1, false, 'Miscellaneous (Interlocutory applications)');

INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (2, 3, false, 'P and A');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (2, 3, false, 'Civil Appeals (including succession matters)');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (2, 3, false, 'Miscellaneous Applications');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (2, 3, false, 'Income Tax Appeals');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (2, 3, false, 'Commercial  Cases');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (2, 3, false, 'Winding up cases ');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (2, 3, false, 'Bankruptcy cases ');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (2, 3, false, 'Running Down cases');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (2, 3, false, 'Land and environmental cases');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (2, 3, false, 'Industrial cases');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (2, 3, false, 'Judicial review cases');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (2, 3, false, 'Constitutional reference cases');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (2, 3, false, 'Matrimonial cases');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (2, 3, false, 'Succession cases');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (2, 3, false, 'Adoption cases');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (2, 3, false, 'Taxation of advocates costs cases');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (2, 3, false, 'Ad Litem cases');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (2, 3, false, 'Admiralty cases');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (2, 3, false, 'Other Civil cases');

INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (2, 4, false, 'Marriage');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (2, 4, false, 'Divorce');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (2, 4, false, 'Succession');
INSERT INTO dc_category (category_type, court_level, children_category, dc_category_name) VALUES (2, 4, false, 'Other cases');


