UPDATE Users SET UserGroupID = 8 WHERE UserGroupID = 13;
DELETE FROM UserGroups WHERE UserGroupID = 13;

UPDATE students SET birthdate = '1991-12-31' WHERE studentid = '08/0767';
UPDATE students SET birthdate = '1992-09-26' WHERE studentid = '08/1033';
UPDATE students SET birthdate = '1992-11-30' WHERE studentid = '09/0709';
UPDATE students SET birthdate = '1984-04-12' WHERE studentid = '09/1064';
UPDATE students SET birthdate = '1992-10-24' WHERE studentid = '10/0782';
UPDATE students SET birthdate = '1989-05-15' WHERE studentid = '10/0880';
UPDATE students SET birthdate = '1994-10-04' WHERE studentid = '10/2590';

UPDATE students SET firstname = trim(othernames), othernames = ''
WHERE trim(firstname) = '';

UPDATE students SET surname = 'Obadimu', firstname = 'Yetunde', othernames = 'Omotola'
WHERE studentid = '08/1676';

UPDATE students SET firstname = 'PEGNYEMB'
WHERE studentid = '10/3000';

DELETE FROM gradechangelist where qgradeid in (select qgradeid from qgrades where dropped = true);
DELETE FROM qgrades where dropped = true;

CREATE TABLE currency (
	currency_id				integer primary key,
	currency_name			varchar(50),
	currency_symbol			varchar(3)
);
INSERT INTO currency (currency_id, currency_name, currency_symbol) VALUES (1, 'Kenya Shillings', 'KES');
INSERT INTO currency (currency_id, currency_name, currency_symbol) VALUES (2, 'US Dolar', 'USD');
INSERT INTO currency (currency_id, currency_name, currency_symbol) VALUES (3, 'British Pound', 'BPD');
INSERT INTO currency (currency_id, currency_name, currency_symbol) VALUES (4, 'Euro', 'ERO');

CREATE TABLE orgs (
	org_id					serial primary key,
	currency_id				integer references currency,
	org_name				varchar(50),
	is_default				boolean not null default true,
	is_active				boolean not null default true,
	logo					varchar(50),
	pin 					varchar(50),
	details					text
);
CREATE INDEX orgs_currency_id ON orgs (currency_id);
INSERT INTO orgs (org_id, org_name, currency_id, logo) VALUES (0, 'default', 1, 'logo.png');

CREATE TABLE entity_types (
	entity_type_id			serial primary key,
	org_id					integer references orgs,
	entity_type_name		varchar(50) unique,
	entity_role				varchar(240),
	use_key					integer default 0 not null,
	group_email				varchar(120),
	Description				text,
	Details					text
);
CREATE INDEX entity_types_org_id ON entity_types (org_id);
INSERT INTO entity_types (org_id, entity_type_id, entity_type_name, entity_role) VALUES (0, 0, 'Users', 'user');
INSERT INTO entity_types (org_id, entity_type_id, entity_type_name, entity_role) VALUES (0, 1, 'Staff', 'staff');
INSERT INTO entity_types (org_id, entity_type_id, entity_type_name, entity_role) VALUES (0, 2, 'Client', 'client');
INSERT INTO entity_types (org_id, entity_type_id, entity_type_name, entity_role) VALUES (0, 3, 'Supplier', 'supplier');

CREATE TABLE entitys (
	entity_id				serial primary key,
	org_id					integer not null references orgs,
	entity_type_id			integer not null references entity_types,
	entity_name				varchar(120) not null,
	user_name				varchar(120),
	primary_email			varchar(120),
	super_user				boolean default false not null,
	entity_leader			boolean default false not null,
	no_org					boolean default false not null,
	function_role			varchar(240),
	date_enroled			timestamp default now(),
	is_active				boolean default true,
	entity_password			varchar(64) default md5('enter') not null,
	first_password			varchar(64) default 'enter' not null,
	new_password			varchar(64),
	start_url				varchar(64),
	is_picked				boolean default false not null,
	details					text,
	UNIQUE(org_id, User_name)
);
CREATE INDEX entitys_org_id ON entitys (org_id);
INSERT INTO entitys (entity_id, org_id, entity_type_id, user_name, entity_name, primary_email, Entity_Leader, Super_User, no_org)  
VALUES (0, 0, 0, 'root', 'root', 'root@localhost', true, true, true);

CREATE TABLE subscription_levels (
	subscription_level_id	serial primary key,
	org_id					integer references orgs,
	subscription_level_name	varchar(50),
	details					text
);
CREATE INDEX subscription_levels_org_id ON subscription_levels (org_id);
INSERT INTO subscription_levels (org_id, subscription_level_id, subscription_level_name) VALUES (0, 0, 'Basic');
INSERT INTO subscription_levels (org_id, subscription_level_id, subscription_level_name) VALUES (0, 1, 'Manager');
INSERT INTO subscription_levels (org_id, subscription_level_id, subscription_level_name) VALUES (0, 2, 'Consumer');

CREATE TABLE entity_subscriptions (
	entity_subscription_id	serial primary key,
	org_id					integer references orgs,
	entity_type_id			integer not null references entity_types,
	entity_id				integer not null references entitys,
	subscription_level_id	integer not null references subscription_levels,
	details					text,
	UNIQUE(entity_id, entity_type_id)
);
CREATE INDEX entity_subscriptions_org_id ON entity_subscriptions (org_id);
CREATE INDEX entity_subscriptions_entity_type_id ON entity_subscriptions (entity_type_id);
CREATE INDEX entity_subscriptions_entity_id ON entity_subscriptions (entity_id);
CREATE INDEX entity_subscriptions_subscription_level_id ON entity_subscriptions (subscription_level_id);

INSERT INTO entity_subscriptions (org_id, Entity_subscription_id, entity_type_id, entity_id, subscription_level_id)  
VALUES (0, 0, 0, 0, 0);

CREATE TABLE sys_logins (
	sys_login_id			serial primary key,
	entity_id				integer references entitys,
	login_time				timestamp default now(),
	login_ip				varchar(64),
	narrative				varchar(240)
);
CREATE INDEX sys_logins_entity_id ON sys_logins (entity_id);




