CREATE TABLE sms_trans (
	sms_trans_id		serial primary key,
	message				varchar(2400),
	origin				varchar(50),
	sms_time			timestamp,
	client_id			varchar(50),
	msg_number			varchar(50),
	code				varchar(25),
	amount				real,
	in_words			varchar(240),
	narrative			varchar(240),
	sms_id				integer,
	sms_deleted			boolean default false not null,
	sms_picked			boolean default false not null,
	part_id				integer,
	part_message		varchar(240),
	part_no				integer,
	part_count			integer,
	complete			boolean default false,
	UNIQUE(origin, sms_time)
);

CREATE TABLE folders (
	folder_id			serial primary key,
	folder_name			varchar(25) unique,
	details				text
);
INSERT INTO folders (folder_id, folder_name) VALUES (0, 'Outbox');
INSERT INTO folders (folder_id, folder_name) VALUES (1, 'Draft');
INSERT INTO folders (folder_id, folder_name) VALUES (2, 'Sent');
INSERT INTO folders (folder_id, folder_name) VALUES (3, 'Inbox');
INSERT INTO folders (folder_id, folder_name) VALUES (4, 'Action');

CREATE TABLE sms (
	sms_id				serial primary key,
	folder_id			integer references folders,
	sms_number			varchar(25),
	sms_time			timestamp default now(),
	message_ready		boolean default false,
	sent				boolean default false,
	message				text,
	details				text
);
CREATE INDEX sms_folder_id ON sms (folder_id);

CREATE TABLE sms_groups (
	sms_groups_id		serial primary key,
	sms_id				integer references sms,
	entity_type_id		integer references entity_types,
	narrative			varchar(240)
);
CREATE INDEX sms_groups_sms_id ON sms_groups (sms_id);
CREATE INDEX sms_groups_entity_type_id ON sms_groups (entity_type_id);

CREATE TABLE sms_address (
	sms_address_id		serial primary key,
	sms_id				integer references sms,
	address_id			integer references address,
	narrative			varchar(240)
);
CREATE INDEX sms_address_sms_id ON sms_address (sms_id);
CREATE INDEX sms_address_address_id ON sms_address (address_id);

CREATE VIEW vw_sms AS
	SELECT folders.folder_id, folders.folder_name, sms.sms_id, sms.sms_number, 
		sms.message_ready, sms.sent, sms.message, sms.details,
		vw_entitys.entity_name, vw_entitys.mobile
	FROM sms INNER JOIN folders ON sms.folder_id = folders.folder_id
	LEFT JOIN vw_entitys ON sms.sms_number = vw_entitys.mobile;

CREATE VIEW vw_sms_groups AS
	SELECT entity_types.entity_type_id, entity_types.entity_type_name,
		sms_groups.sms_groups_id, sms_groups.sms_id, sms_groups.narrative
	FROM entity_types INNER JOIN sms_groups ON entity_types.entity_type_id = sms_groups.entity_type_id;

CREATE VIEW vw_sms_address AS
	SELECT vw_entitys.entity_name, vw_entitys.mobile,
		sms_address.sms_address_id, sms_address.sms_id, sms_address.narrative
	FROM vw_entitys INNER JOIN sms_address ON vw_entitys.address_id = sms_address.address_id;

CREATE OR REPLACE FUNCTION ins_sms_trans() RETURNS trigger AS $$
DECLARE
	rec RECORD;
	msg varchar(2400);
BEGIN
	IF(NEW.part_no = NEW.part_count) THEN
		IF(NEW.part_no = 1) THEN
			INSERT INTO sms (folder_id, sms_number, message)
			VALUES(3, NEW.origin, NEW.message);

			NEW.sms_picked = true;
		ELSE
			msg := '';
			FOR rec IN SELECT part_no, message FROM sms_trans WHERE (part_id = NEW.part_id) AND (origin = NEW.origin)
			ORDER BY part_no LOOP
				msg := msg || rec.message;
			END LOOP;
			msg := msg || NEW.message;
			INSERT INTO sms (folder_id, sms_number, message)
			VALUES(3, NEW.origin, msg);

			NEW.sms_picked = true;
		END IF;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_sms_trans BEFORE INSERT ON sms_trans
    FOR EACH ROW EXECUTE PROCEDURE ins_sms_trans();

CREATE OR REPLACE FUNCTION ins_sms_address(varchar(32), varchar(32), varchar(32)) RETURNS varchar(120) AS $$
BEGIN
	INSERT INTO sms_address (address_id, sms_id)
	VALUES (CAST($1 AS Integer), CAST($3 AS integer));

	return 'Address Added';
END;
$$ LANGUAGE plpgsql;


