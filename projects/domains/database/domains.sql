---Project Database File
ALTER TABLE entitys ADD COLUMN contact_key character varying(50);
ALTER TABLE entitys ADD COLUMN auth_info character varying(50);
CREATE TABLE zones
(
  zone_id serial PRIMARY KEY,
  zone_name character varying(120) NOT NULL,
  zone_key integer NOT NULL DEFAULT 1,
  annual_cost real NOT NULL DEFAULT 0,
  tax_rate real NOT NULL DEFAULT 0,
  details text,
  CONSTRAINT zones_zone_name_key UNIQUE (zone_name)
);

CREATE TABLE hosting (
	hosting_id			serial primary key,
	hosting_name		varchar(50),
	hosting_price		real not null,
    disk_space          varchar(20);
    backup_recovery     varchar(20);
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
    status              varchar(20) NOT NULL default 'Active',
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

CREATE TABLE mpesa_trxs(
  mpesa_trx_id      serial PRIMARY KEY,
  org_id            integer References orgs,
  mpesa_id          integer,
  mpesa_orig        character varying(50),
  mpesa_dest        character varying(50),
  mpesa_tstamp      timestamp without time zone,
  mpesa_text        character varying(320),
  mpesa_code        character varying(50),
  mpesa_acc         character varying(50),
  mpesa_msisdn      character varying(50),
  mpesa_trx_date    date,
  mpesa_trx_time    time without time zone,
  mpesa_amt         real,
  mpesa_sender      character varying(50),
  mpesa_pick_time   timestamp without time zone DEFAULT now()
);
CREATE INDEX mpesa_trxs_org_id ON orgs (org_id);

CREATE TABLE ledger(
  ledger_id             serial PRIMARY KEY,
  entity_id             integer REFERENCES entitys,
  domain_id             integer REFERENCES domains,
  mpesa_trx_id          integer REFERENCES mpesa_trxs,
  trans_type            character varying(50) DEFAULT 'Receipt'::character varying,
  payment_date          date,
  ledger_date           timestamp without time zone DEFAULT now(),
  trx_code              character varying(32),
  amount                real NOT NULL DEFAULT 0,
  tax_amount            real NOT NULL DEFAULT 0,
  cheque                boolean NOT NULL DEFAULT false,
  cleared               boolean NOT NULL DEFAULT false,
  details               text
);
CREATE INDEX ledger_domain_id ON domains (domain_id);
CREATE INDEX ledger_mpesa_trx_id ON mpesa_trxs (mpesa_trx_id);
CREATE INDEX ledger_entity_id ON entitys (entity_id);

CREATE TABLE hosting_server (
    hosting_server_id           serial primary key,
    hosting_id                  integer REFERENCES hosting,
    domain_id                   integer REFERENCES domains,
    entity_id                   integer REFERENCES entitys,
    created_date               	date NOT NULL default now(),
    expiry_date                 date,
    updated			            date,
    status                      varchar(20) NOT NULL default 'Active',
    details                     text

);

CREATE INDEX hosting_server_domain_id ON domains (domain_id);
CREATE INDEX hosting_server_hosting_id ON hosting (hosting_id);
CREATE INDEX hosting_server_entity_id ON entitys (entity_id);

CREATE OR REPLACE VIEW vw_domains AS
	SELECT entitys.entity_id, entitys.entity_name, entitys.user_name, entitys.first_password,
		zones.zone_id, zones.zone_name, domains.domain_id, domains.domain_name, domains.auth_info, domains.created_date,
		domains.transfer_date, domains.duration, domains.expiry_date::date, domains.updated, domains.site_user,
		domains.google_token, domains.details, domains.site_name, (CASE WHEN (domains.expiry_date < now()::date) THEN 'Expired'
            WHEN (domains.expiry_date >= now()::date)  THEN 'Active'
            ELSE 'Canceled'
       END)as status
	FROM domains INNER JOIN entitys ON domains.entity_id = entitys.entity_id
		INNER JOIN zones ON domains.zone_id = zones.zone_id;

CREATE OR REPLACE  VIEW vw_domain_hosts AS
	SELECT domains.domain_id, domains.domain_name, hosts.host_id, hosts.host_name,
			domain_hosts.domain_host_id, domain_hosts.updated
	FROM domain_hosts INNER JOIN domains ON domain_hosts.domain_id = domains.domain_id
		INNER JOIN hosts ON domain_hosts.host_id = hosts.host_id;
