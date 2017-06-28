
CREATE TABLE folders (
	folder_id				serial primary key,
	org_id					integer references orgs,
	folder_name				varchar(25) unique,
	details					text
);
CREATE INDEX folders_org_id ON folders (org_id);
INSERT INTO folders (folder_id, folder_name) VALUES (0, 'Outbox');
INSERT INTO folders (folder_id, folder_name) VALUES (1, 'Draft');
INSERT INTO folders (folder_id, folder_name) VALUES (2, 'Sent');
INSERT INTO folders (folder_id, folder_name) VALUES (3, 'Inbox');
INSERT INTO folders (folder_id, folder_name) VALUES (4, 'Action');

CREATE TABLE sms (
	sms_id					serial primary key,
	folder_id				integer references folders,
	entity_id				integer references entitys,
	org_id					integer references orgs,
	sms_origin				varchar(50),
	sms_number				varchar(25),
	sms_numbers				text,
	sms_time				timestamp default now(),
	sms_count				integer not null default 0,
	number_error			boolean default false,
	message_ready			boolean default false,
	sent					boolean default false,
	retries					integer default 0 not null,
	last_retry				timestamp default now(),

	addresses				text,
	senderAddress			varchar(64),
	serviceId				varchar(64),
	spRevpassword			varchar(64),
	dateTime				timestamp,
	correlator				varchar(64),
	traceUniqueID			varchar(64),
	linkid					varchar(64),
	spRevId					varchar(64),
	spId					varchar(64),
	smsServiceActivationNumber	varchar(64),

	link_id					integer,

	message					text,
	details					text
);
CREATE INDEX sms_folder_id ON sms (folder_id);
CREATE INDEX sms_entity_id ON sms (entity_id);
CREATE INDEX sms_org_id ON sms (org_id);
