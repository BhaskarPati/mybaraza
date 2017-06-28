---Project Database File
CREATE TABLE languages (
	language_id				serial primary key,
	language_name			varchar(50),	
	details					text
);

CREATE TABLE messages (
	message_id						serial primary key,
	language_id						integer references languages,
	message_code					integer,
	message_use						varchar(240),
	message_data					varchar(240),
	details							text,
	UNIQUE(language_id, message_code)
);
CREATE INDEX messages_language_id ON messages (language_id);

CREATE TABLE points (
	point_id				serial primary key,
	Low_Range				integer not null,
	High_Range				integer not null,
	Grade					varchar(2) not null,
	Risk_Level				varchar(64),
	Credit_Worthiness		varchar(64),
	Business_Options		text,
	sms_message				text
);

CREATE TABLE banks (
	bank_id					serial primary key,
	bank_name				varchar(64),
	bank_contact			varchar(64),
	bank_email				varchar(64),
	details					text
);

CREATE TABLE credit_info (
	credit_info_id			serial primary key,
	bank_id					integer references banks,
	credit_item				varchar(50),
	interest_rate			real,
	repayment_period		integer,
	min_amount				real,
	max_amount				real,
	credit_info_query		varchar(120),
	credit_info_responce	varchar(120),
	details					text
);
CREATE INDEX credit_info_bank_id ON credit_info (bank_id);

CREATE TABLE market_info (
	market_info_id			serial primary key,
	market_info				varchar(160),
	created_date			timestamp default now(),
	message_ready			boolean default false not null,
	message_sent			boolean default false not null,
	public_info				boolean default false not null,
	details					text
);

CREATE TABLE auth_levels (
	auth_level_id			serial primary key,
	auth_level_name			varchar(50) not null unique,
	details					text
);
INSERT INTO auth_levels (auth_level_id, auth_level_name) VALUES (0, 'Generic Query');
INSERT INTO auth_levels (auth_level_id, auth_level_name) VALUES (1, 'Manual Confirmation required');
INSERT INTO auth_levels (auth_level_id, auth_level_name) VALUES (2, 'SMS Confirmation required');
INSERT INTO auth_levels (auth_level_id, auth_level_name) VALUES (3, 'No Confirmation required');

ALTER TABLE entitys
ADD	language_id				integer references languages,
ADD	auth_level_id			integer references auth_levels,
ADD	APIN					char(5),
ADD ID_Number				varchar(32),
ADD	KRAPIN					varchar(32),
ADD	Parent_ID				varchar(32),
ADD	email					varchar(240),
ADD	address					text,
ADD	verified				boolean default false not null,
ADD	rejected				boolean default false not null,
ADD	is_updated				boolean default true not null;
CREATE INDEX entitys_auth_level_id ON entitys (auth_level_id);
CREATE INDEX entitys_language_id ON entitys (language_id);

CREATE TABLE entity_phones (
	entity_phone_id			serial primary key,
	entity_id				integer references entitys,
	phone_number			varchar(32),
	ID_Number				varchar(32),
	is_picked				boolean default false not null,
	Created_Date			timestamp default now()
);
CREATE INDEX entity_phones_entity_id ON entity_phones (entity_id);

CREATE TABLE query_types (
	query_type_id			serial primary key,
	query_type_name			varchar(50),
	details					text
);

CREATE TABLE query_category (
	query_category_id		serial primary key,
	query_type_id			integer references query_types,
	query_category_name		varchar(50),
	details					text
);
CREATE INDEX query_category_query_type_id ON query_category (query_type_id);

CREATE TABLE request_types (
	request_type_id			serial primary key,
	request_type_name		varchar(50) not null unique,
	request_charge			real not null,
	request_tag				varchar(16),
	responce_number			integer default 1 not null,
	details					text
);

CREATE TABLE requests (
	request_id				serial primary key,
	entity_id				integer references entitys,
	request_type_id			integer not null references request_types,
	auth_level_id			integer not null references auth_levels,
	query_category_id		integer references query_category,
	responce_number			integer default 1 not null,
	current_responce		integer default 0 not null,
	last_responce			timestamp default now(),
	request_date			timestamp default now() not null,
	approved				boolean default false not null,
	ready					boolean default false not null,
	sent					boolean default false not null,
	alert_type				integer,
	wait_state				integer default 0 not null,
	alert_value				varchar(50),
	request_charge			real not null,
	request_phone			varchar(32),
	request_file			varchar(64),
	score					varchar(50),
	request					varchar(240),
	responce				varchar(240),
	responce_date			timestamp,
	details					text
);
CREATE INDEX requests_entity_id ON requests (entity_id);
CREATE INDEX requests_request_type_id ON requests (request_type_id);
CREATE INDEX requests_auth_level_id ON requests (auth_level_id);
CREATE INDEX requests_query_category_id ON requests (query_category_id);

CREATE TABLE request_sms (
	request_sms_id			serial primary key,
	request_id				integer references requests,
	sms_id					integer references sms
);
CREATE INDEX request_sms_request_id ON request_sms (request_id);
CREATE INDEX request_sms_sms_id ON request_sms (sms_id);

CREATE TABLE ledger (
	ledger_id				serial primary key,
	entity_id				integer references entitys,
	sms_trans_id			integer references sms_trans,
	request_id				integer references requests,
	trx_code				varchar(50),
	ledger_date				timestamp default now() not null,
	ledger_amount			real not null
);
CREATE INDEX ledger_entity_id ON ledger (entity_id);
CREATE INDEX ledger_sms_trans_id ON ledger (sms_trans_id);

CREATE TABLE request_info (
	request_info_id			serial primary key,
	market_info_id			integer references market_info,
	request_id				integer references requests,
	sent_date				timestamp default now(),
	message					varchar(240)
);
CREATE INDEX request_info_market_info_id ON request_info (market_info_id);
CREATE INDEX request_info_request_id ON request_info (request_id);

CREATE VIEW vw_credit_info AS
	SELECT banks.bank_id, banks.bank_name, credit_info.credit_info_id, credit_info.credit_item, credit_info.interest_rate, 
		credit_info.repayment_period, credit_info.min_amount, credit_info.max_amount, credit_info.credit_info_query, 
		credit_info.credit_info_responce, credit_info.details
	FROM credit_info INNER JOIN banks ON credit_info.bank_id = banks.bank_id;

CREATE VIEW vw_query_category AS
	SELECT query_types.query_type_id, query_types.query_type_name, query_category.query_category_id, 
		query_category.query_category_name, query_category.details,
		(query_types.query_type_name || ' - ' || query_category.query_category_name) as query_display
	FROM query_category INNER JOIN query_types ON query_category.query_type_id = query_types.query_type_id;

CREATE VIEW vw_clients AS
	SELECT auth_levels.auth_level_id, auth_levels.auth_level_name, entity_types.entity_type_id, entity_types.entity_type_name, 
		entitys.entity_id, entitys.entity_name, entitys.user_name, entitys.super_user, entitys.entity_leader, 
		entitys.function_role, entitys.date_enroled, entitys.is_active, entitys.entity_password, entitys.first_password, 
		entitys.apin, entitys.id_number, entitys.krapin, entitys.parent_id, entitys.email, entitys.verified,
		entitys.details
	FROM entitys INNER JOIN auth_levels ON entitys.auth_level_id = auth_levels.auth_level_id
		INNER JOIN entity_types ON entitys.entity_type_id = entity_types.entity_type_id;

CREATE VIEW vw_requests AS
	SELECT auth_levels.auth_level_id, auth_levels.auth_level_name, entitys.entity_id, entitys.entity_name, 
		request_types.request_type_id, request_types.request_type_name, requests.request_id, requests.request_date, 
		requests.approved, requests.ready, requests.request_charge, requests.request_phone, requests.request, 
		requests.sent, requests.responce, requests.details
	FROM requests INNER JOIN auth_levels ON requests.auth_level_id = auth_levels.auth_level_id
		INNER JOIN entitys ON requests.entity_id = entitys.entity_id
		INNER JOIN request_types ON requests.request_type_id = request_types.request_type_id;

CREATE VIEW vw_request_sms AS
	SELECT sms.sms_id, sms.message, request_sms.request_sms_id, request_sms.request_id
	FROM request_sms INNER JOIN sms ON request_sms.sms_id = sms.sms_id;

CREATE VIEW vw_ledger AS
	SELECT entitys.entity_id, entitys.entity_name, ledger.ledger_id, ledger.sms_trans_id, ledger.request_id,
		ledger.ledger_date, ledger.ledger_amount
	FROM ledger INNER JOIN entitys ON ledger.entity_id = entitys.entity_id;

CREATE OR REPLACE FUNCTION ins_sms_receipt() RETURNS trigger AS $$
DECLARE
	entityid INTEGER;
	rec RECORD;
	msg varchar(2400);
BEGIN

	IF((trim(NEW.origin) = 'D48617A140') AND (NEW.amount is not null) AND (NEW.code is not null) AND (NEW.msg_number is not null)) THEN
		SELECT entity_id INTO entityid
		FROM entity_phones
		WHERE phone_number = NEW.msg_number;

		IF(entityid IS NULL) THEN
			INSERT INTO sms (folder_id, sms_number, message_ready, message)
			VALUES (0, NEW.msg_number, true, 'The account does not match update our account mobile number.');
		ELSE
			INSERT INTO ledger (entity_id, sms_trans_id, ledger_amount, trx_code)
			VALUES (entityid, NEW.sms_trans_id, NEW.amount, NEW.code);

			INSERT INTO sms (folder_id, sms_number, message_ready, message)
			VALUES (0, NEW.msg_number, true, 'Your account has been credited with KES ' || NEW.amount);
		END IF;
	END IF;

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_sms_receipt AFTER INSERT ON sms_trans
    FOR EACH ROW EXECUTE PROCEDURE ins_sms_receipt();

CREATE OR REPLACE FUNCTION upd_entitys() RETURNS trigger AS $$
DECLARE
	phone_num varchar(25);
	rec RECORD;
	msg varchar(2400);
BEGIN

	IF((OLD.verified = false) AND (NEW.verified = true))THEN
		SELECT phone_number INTO phone_num
		FROM entity_phones
		WHERE entity_id = NEW.entity_id;

		INSERT INTO ledger (entity_id, ledger_amount, trx_code)
		VALUES (NEW.entity_id, 500, 'AR');

		INSERT INTO sms (folder_id, sms_number, message_ready, message)
		VALUES (0, phone_num, true, 'You have now been registered. You can now access your credit report and credit score.You can also monitor events on your credit profile.');
	END IF;

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER upd_entitys AFTER UPDATE ON entitys
    FOR EACH ROW EXECUTE PROCEDURE upd_entitys();


INSERT INTO request_types (request_type_id, request_type_name, request_tag, request_charge) VALUES (1, 'Registration', 'REG', 0);
INSERT INTO request_types (request_type_id, request_type_name, request_tag, request_charge) VALUES (2, 'Query', 'query', 0);
INSERT INTO request_types (request_type_id, request_type_name, request_tag, request_charge) VALUES (3, 'Credit', 'credit', 0);
INSERT INTO request_types (request_type_id, request_type_name, request_tag, request_charge) VALUES (4, 'Score', 'score', 100);
INSERT INTO request_types (request_type_id, request_type_name, request_tag, request_charge) VALUES (5, 'Report', 'score report', 500);
INSERT INTO request_types (request_type_id, request_type_name, request_tag, request_charge) VALUES (6, 'Alert', 'alert', 500);
INSERT INTO request_types (request_type_id, request_type_name, request_tag, request_charge) VALUES (7, 'Borrow', 'borrow', 500);
INSERT INTO request_types (request_type_id, request_type_name, request_tag, request_charge) VALUES (8, 'Check', 'check', 500);

INSERT INTO query_types (query_type_id, query_type_name) VALUES (1, 'Compliment');
INSERT INTO query_types (query_type_id, query_type_name) VALUES (2, 'Inquiry');
INSERT INTO query_types (query_type_id, query_type_name) VALUES (3, 'Identification');
INSERT INTO query_types (query_type_id, query_type_name) VALUES (4, 'Contact');
INSERT INTO query_types (query_type_id, query_type_name) VALUES (5, 'Account Activities');
INSERT INTO query_types (query_type_id, query_type_name) VALUES (6, 'Credit Score');
INSERT INTO query_types (query_type_id, query_type_name) VALUES (7, 'Others');

INSERT INTO query_category (query_type_id, query_category_name) VALUES (1, 'Compliment');
INSERT INTO query_category (query_type_id, query_category_name) VALUES (2, 'Inquery');
INSERT INTO query_category (query_type_id, query_category_name) VALUES (3, 'Name');
INSERT INTO query_category (query_type_id, query_category_name) VALUES (3, 'Date of birth');
INSERT INTO query_category (query_type_id, query_category_name) VALUES (3, 'Gender');
INSERT INTO query_category (query_type_id, query_category_name) VALUES (4, 'Postal Address');
INSERT INTO query_category (query_type_id, query_category_name) VALUES (4, 'Residential Address');
INSERT INTO query_category (query_type_id, query_category_name) VALUES (4, 'Telephone');
INSERT INTO query_category (query_type_id, query_category_name) VALUES (4, 'EMail');
INSERT INTO query_category (query_type_id, query_category_name) VALUES (5, 'Balance');
INSERT INTO query_category (query_type_id, query_category_name) VALUES (5, 'Missed payment');
INSERT INTO query_category (query_type_id, query_category_name) VALUES (5, 'Delayed payment');
INSERT INTO query_category (query_type_id, query_category_name) VALUES (6, 'Bound cheque');
INSERT INTO query_category (query_type_id, query_category_name) VALUES (6, 'Debt collection');
INSERT INTO query_category (query_type_id, query_category_name) VALUES (7, 'Others');

INSERT INTO points (Low_Range, High_Range, Grade, Risk_Level, Credit_Worthiness, Business_Options) VALUES ('850', '900', 'A1', 'Lower Risk', 'Highest Credit Quality', 'Easy access to credit. Empowers you to negotiate lower interest rates. Lenders will offer more favourable terms. Lenders may offer more suitable products.');
INSERT INTO points (Low_Range, High_Range, Grade, Risk_Level, Credit_Worthiness, Business_Options) VALUES ('800', '849', 'A2', 'Lower Risk', 'Highest Credit Quality', 'Easy access to credit. Empowers you to negotiate lower interest rates. Lenders will offer more favourable terms. Lenders may offer more suitable products.');
INSERT INTO points (Low_Range, High_Range, Grade, Risk_Level, Credit_Worthiness, Business_Options) VALUES ('750', '799', 'A3', 'Lower Risk', 'Highest Credit Quality', 'Easy access to credit. Empowers you to negotiate lower interest rates. Lenders will offer more favourable terms. Lenders may offer more suitable products.');
INSERT INTO points (Low_Range, High_Range, Grade, Risk_Level, Credit_Worthiness, Business_Options) VALUES ('700', '749', 'B1', 'Low Risk', 'High Credit quality', 'Easy access to credit. Lenders may offer standard terms.');
INSERT INTO points (Low_Range, High_Range, Grade, Risk_Level, Credit_Worthiness, Business_Options) VALUES ('650', '699', 'B2', 'Low Risk', 'High Credit quality', 'Easy access to credit. Lenders may offer standard terms.');
INSERT INTO points (Low_Range, High_Range, Grade, Risk_Level, Credit_Worthiness, Business_Options) VALUES ('600', '649', 'B3', 'Low Risk', 'High Credit quality', 'Easy access to credit. Lenders may offer standard terms.');
INSERT INTO points (Low_Range, High_Range, Grade, Risk_Level, Credit_Worthiness, Business_Options) VALUES ('550', '599', 'C1', 'Moderate Risk', 'Moderate Credit Quality', 'Lenders may charge higher interest rates.');
INSERT INTO points (Low_Range, High_Range, Grade, Risk_Level, Credit_Worthiness, Business_Options) VALUES ('500', '549', 'C2', 'Moderate Risk', 'Moderate Credit Quality', 'Lenders may charge higher interest rates.');
INSERT INTO points (Low_Range, High_Range, Grade, Risk_Level, Credit_Worthiness, Business_Options) VALUES ('450', '499', 'C3', 'High Risk', 'Low Credit Quality', 'Lenders may charge high interest. Collateral may be required.');
INSERT INTO points (Low_Range, High_Range, Grade, Risk_Level, Credit_Worthiness, Business_Options) VALUES ('400', '449', 'C4', 'High Risk', 'Low Credit Quality', 'Lenders may charge high interest. Collateral may be required.');
INSERT INTO points (Low_Range, High_Range, Grade, Risk_Level, Credit_Worthiness, Business_Options) VALUES ('300', '399', 'D', 'Highest Risk', 'Lowest Credit quality', 'Access to credit may be denied.');
INSERT INTO points (Low_Range, High_Range, Grade, Risk_Level, Credit_Worthiness, Business_Options) VALUES ('0', '299', 'NR', 'Undetermined', 'Inadequate data on the credit file', 'Ask yor creditors to contribute data on your credit profile.');

