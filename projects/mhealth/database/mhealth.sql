---MHealth Database File
CREATE TABLE languages (
	language_id			serial primary key,
	language_name		varchar(50),	
	details				text
);

CREATE TABLE sites (
	site_id				serial primary key,
	site_name			varchar(50),
	details				text
);

--we extend entity
ALTER TABLE entitys add site_id						integer references sites;

ALTER TABLE entitys add health_worker_id			integer references entitys;
ALTER TABLE entitys add language_id					integer references languages;
ALTER TABLE entitys add mobile_number				varchar(20);
ALTER TABLE entitys add birth_date					date;
ALTER TABLE entitys add conception_date				date;
ALTER TABLE entitys add expected_delivery_date		date;
ALTER TABLE entitys add actual_delivery_date		date;
ALTER TABLE entitys add enrollment_date				date;
ALTER TABLE entitys add is_patient_enrolled			boolean default false;		--to receive sms

ALTER TABLE entitys add partner_language_id			integer references languages;
ALTER TABLE entitys add partner_name				varchar(50);	
ALTER TABLE entitys add partner_birth_date			date;
ALTER TABLE entitys add partner_enrollment_date		date;
ALTER TABLE entitys add is_partner_enrolled			boolean default false;		--to receive sms
ALTER TABLE entitys add partner_mobile_no			char(10);	

CREATE INDEX entitys_site_id ON entitys (site_id);
CREATE INDEX entitys_health_worker_id ON entitys (health_worker_id);
CREATE INDEX entitys_language_id ON entitys (language_id);
CREATE INDEX entitys_partner_language_id ON entitys (partner_language_id);

CREATE TABLE message_category (
	message_category_id				serial primary key,
	message_category_name			varchar(50),
	details							text
);
INSERT INTO message_category(message_category_name) VALUES('Enrollment & Exit');
INSERT INTO message_category(message_category_name) VALUES('Drug Adherence');
INSERT INTO message_category(message_category_name) VALUES('Appointment/Retention');

--directory of all messages that can be sent
CREATE TABLE messages (
	message_id						serial primary key,
	message_category_id				integer references message_category,
	language_id						integer references languages,
	message_code					char(3),
	is_before_delivery				boolean default false,
	is_after_delivery				boolean default false,
	week_number						integer,	--when to be sent
	message_order					integer,	--for more than one message we need to identify the sequence/precedence
	frequency						integer,	--for recurrent msgs
	frequency_interval				integer,	--
	is_weekly_interval				boolean default true,
	is_partner						boolean default false,
	message_data					varchar(240),
	details							text
);
CREATE INDEX messages_message_category_id ON messages (message_category_id);
CREATE INDEX messages_language_id ON messages (language_id);

--message_schedule
CREATE TABLE message_schedule (
	message_schedule_id				serial primary key,
	entity_id						integer references entitys,
	message_id						integer references messages,
	sms_id							integer references sms,

	schedule_date					date,
	schedule_time					time,
	message							varchar(240),

	details							text
);
CREATE INDEX message_schedule_entity_id ON message_schedule (entity_id);
CREATE INDEX message_schedule_message_id ON message_schedule (message_id);
CREATE INDEX message_schedule_sms_id ON message_schedule (sms_id);


