--- ADJUSTMENTS

CREATE TABLE departments (
	dept_id	serial primary key,
	dept_name	varchar(200),
	details		text	
      );

INSERT INTO departments (dept_name) VALUES('Boards');
INSERT INTO departments (dept_name) VALUES('Magnification');
INSERT INTO departments (dept_name) VALUES('Membercare');
INSERT INTO departments (dept_name) VALUES('Ministry Identification');
INSERT INTO departments (dept_name) VALUES('Maturity');
INSERT INTO departments (dept_name) VALUES('Missions');
INSERT INTO departments (dept_name) VALUES('Ministries');
INSERT INTO departments (dept_name) VALUES('Committees');
INSERT INTO departments (dept_name) VALUES('Staff');


INSERT INTO orgs (currency_id, org_name, org_sufix, is_default, is_active, logo)  VALUES (1, 'Westlands', 'WLDS', true, true, 'logo.png');
INSERT INTO orgs (currency_id, org_name, org_sufix, is_default, is_active, logo)  VALUES (1, 'Mombasa Road', 'MSRD', false, true, 'logo.png');
INSERT INTO orgs (currency_id, org_name, org_sufix, is_default, is_active, logo)  VALUES (1, 'Makueni', 'MKNI', false, true, 'logo.png');
INSERT INTO orgs (currency_id, org_name, org_sufix, is_default, is_active, logo)  VALUES (1, 'Lower Kabete', 'LKBT', false, true, 'logo.png');
INSERT INTO orgs (currency_id, org_name, org_sufix, is_default, is_active, logo)  VALUES (1, 'Kikuyu', 'KKYU', false, true, 'logo.png');
INSERT INTO orgs (currency_id, org_name, org_sufix, is_default, is_active, logo)  VALUES (1, 'Kahawa', 'KHWA', false, true, 'logo.png');

CREATE TABLE ministries (
	ministry_id		serial primary key,
	ministry_name	varchar(120),
	dept_id		integer references departments,
	org_id			integer references orgs,
	details			text
);



CREATE TABLE ministry_memberships (
	ministry_membership_id	serial primary key,
	ministry_id			integer references ministries,
	entity_id			integer references entitys,
	rank				varchar(120),
	is_active			boolean,
	details				text
);


