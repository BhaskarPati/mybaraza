---Project Database File
ALTER TABLE entitys
ADD	contact_key			varchar(50),
ADD	auth_info			varchar(50),
ADD progress_status		varchar(50),
ADD progress_details	text,
ADD	updated				boolean default false not null;

ALTER TABLE address 
ADD	google_token		varchar(320);

CREATE TABLE zones (
	zone_id				serial primary key,
	zone_name			varchar(120) not null unique,
	zone_key			integer default 1 not null,
	annual_cost			real default 0 not null,
	tax_rate			real default 0 not null,
	details				text
);
INSERT INTO zones (zone_name, annual_cost, tax_rate) 
VALUES ('.co.ke', 5000, 16), ('.or.ke', 5000, 16), ('.me.ke', 1000, 16);

CREATE TABLE hosting (
	hosting_id			serial primary key,
	hosting_name		varchar(50),
	hosting_price		real not null,
	details				text
);

CREATE TABLE sites (
	site_id				serial primary key,
	hosting_id			integer references hosting,
	site_name			varchar(50),
	site_price			real not null,
	details				text
);
CREATE INDEX sites_hosting_id ON sites (hosting_id);

CREATE TABLE hosts (
	host_id				serial primary key,
	host_name			varchar(50),
	core_host			boolean default false not null,
	updated				boolean default false not null,
	details				text
);
INSERT INTO hosts (host_name, core_host, updated)
VALUES ('ns1.dewcis.com', true, true);
INSERT INTO hosts (host_name, core_host, updated)
VALUES ('ns2.dewcis.com', true, true);

CREATE TABLE domains (
	domain_id 			serial primary key,
	entity_id 			integer references entitys,
	zone_id				integer references zones,
	domain_name			varchar(120) not null unique,
	site_name			varchar(120),
	site_user			varchar(120),
	google_token		varchar(320),
	auth_info 			varchar(120),
	created_date 		timestamp default now(),
	transfer_date		timestamp,
	duration			integer,
	expiry_date			timestamp,
	updated				boolean default false not null,
	google_sync			boolean default false not null,
	details				text
);
CREATE INDEX domains_entity_id ON domains (entity_id);
CREATE INDEX domains_zone_id ON domains (zone_id);

CREATE TABLE domain_hosts (
	domain_host_id		serial primary key,
	domain_id			integer references domains,
	host_id				integer references hosts,
	updated				boolean default false not null
);
CREATE INDEX domain_hosts_domain_id ON domain_hosts (domain_id);
CREATE INDEX domain_hosts_host_id ON domain_hosts (host_id);

CREATE TABLE ledger (
	ledger_id			serial primary key,
	entity_id 			integer references entitys,
	domain_id			integer references domains,
	mpesa_trx_id		integer references mpesa_trxs,
	trans_type			varchar(50) default 'Receipt',
	payment_date		date,
	ledger_date			timestamp default now(),
	trx_code			varchar(32),
	amount				real default 0 not null,
	tax_amount			real default 0 not null,
	cheque				boolean default false not null,
	cleared				boolean default false not null,
	details				text
);
CREATE INDEX ledger_entity_id ON ledger (entity_id);
CREATE INDEX ledger_domain_id ON ledger (domain_id);
CREATE INDEX ledger_mpesa_trx_id ON ledger (mpesa_trx_id);

CREATE VIEW vw_domains AS
	SELECT entitys.entity_id, entitys.entity_name, entitys.user_name, entitys.first_password,
		zones.zone_id, zones.zone_name, domains.domain_id, domains.domain_name, domains.auth_info, domains.created_date,
		domains.transfer_date, domains.duration, domains.expiry_date, domains.updated, domains.site_user, 
		domains.google_token, domains.details
	FROM domains INNER JOIN entitys ON domains.entity_id = entitys.entity_id
		INNER JOIN zones ON domains.zone_id = zones.zone_id;

CREATE VIEW vw_domain_hosts AS
	SELECT domains.domain_id, domains.domain_name, hosts.host_id, hosts.host_name, 
			domain_hosts.domain_host_id, domain_hosts.updated
	FROM domain_hosts INNER JOIN domains ON domain_hosts.domain_id = domains.domain_id
		INNER JOIN hosts ON domain_hosts.host_id = hosts.host_id;

CREATE VIEW vw_ledger AS
	SELECT entitys.entity_id, entitys.entity_name, domains.domain_id, domains.domain_name, 
		ledger.ledger_id, ledger.mpesa_trx_id, ledger.amount, ledger.tax_amount, ledger.cheque, 
		ledger.cleared, ledger.trans_type, ledger.details,
		(CASE WHEN ledger.amount > 0 THEN ledger.amount ELSE null END) as debit,
		(CASE WHEN ledger.amount < 0 THEN -(ledger.amount) ELSE null END) as credit
	FROM ledger INNER JOIN entitys ON ledger.entity_id = entitys.entity_id
		LEFT JOIN domains ON ledger.domain_id = domains.domain_id;

CREATE VIEW vw_kbo_entitys AS
	SELECT entitys.entity_id, entitys.entity_name, entitys.user_name,
		entitys.date_enroled, entitys.progress_status, entitys.progress_details,
		address.town, address.mobile, domains.domain_name, domains.created_date
FROM entitys INNER JOIN address ON entitys.entity_id = address.table_id
	LEFT JOIN domains ON entitys.entity_id = domains.entity_id
WHERE address.google_token is not null
ORDER BY entitys.entity_id;

CREATE OR REPLACE FUNCTION ins_address() RETURNS trigger AS $$
DECLARE
	v_address_id		integer;
BEGIN
	IF(NEW.address_name is not null) THEN
		INSERT INTO entitys (org_id, entity_type_id, entity_name, user_name, function_role, entity_password, first_password, contact_key, auth_info)
		VALUES (0, 0, NEW.address_name, NEW.email, 'user', md5(NEW.first_password), NEW.first_password, 
			'esl-' || substring(md5(CAST(random() as text)) from 3 for 12), substring(md5(CAST(random() as text)) from 3 for 12));
		
		NEW.table_name := 'entitys';
		NEW.table_id := lastval();
	END IF;

	SELECT address_id INTO v_address_id
	FROM address WHERE (is_default = true)
		AND (table_name = NEW.table_name) AND (table_id = NEW.table_id) AND (address_id <> NEW.address_id);

	IF (NEW.is_default = true) AND (v_address_id is not null) THEN
		RAISE EXCEPTION 'Only one default Address allowed.';
	ELSIF (NEW.is_default = false) AND (v_address_id is null) THEN
		NEW.is_default := true;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ins_domains() RETURNS trigger AS $$
BEGIN	
	NEW.auth_info := substring(md5(CAST(random() as text)) from 3 for 12);
	NEW.expiry_date	:= now() + CAST(CAST(NEW.duration as text ) || ' years' as interval);
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_domains BEFORE INSERT ON domains
    FOR EACH ROW EXECUTE PROCEDURE ins_domains();

CREATE OR REPLACE FUNCTION ins_domains_aft() RETURNS trigger AS $$
BEGIN	
	INSERT INTO domain_hosts (domain_id, host_id, updated)
	SELECT NEW.domain_id, host_id, true
	FROM hosts
	WHERE (core_host = true) AND (updated = true);

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_domains_aft AFTER INSERT ON domains
    FOR EACH ROW EXECUTE PROCEDURE ins_domains_aft();

CREATE OR REPLACE FUNCTION ins_sms_receipt() RETURNS trigger AS $$
DECLARE
	entityid INTEGER;
	rec RECORD;
	msg varchar(2400);
BEGIN

	IF((trim(NEW.origin) = 'D48617A140') AND (NEW.amount is not null) AND (NEW.code is not null) AND (NEW.msg_number is not null)) THEN

		SELECT entity_id INTO entityid
		FROM mobiles
		WHERE mobile_id = NEW.msg_number;

		IF(entityid IS NULL) THEN
			INSERT INTO sms (folder_id, sms_number, message_ready, message)
			VALUES (0, NEW.msg_number, true, 'The account does not match update our account mobile number.');
		ELSE
			INSERT INTO ledger (entity_id, sms_trans_id, amount, trx_code)
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

