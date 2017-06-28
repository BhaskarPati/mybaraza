--- Project Database File
CREATE TABLE account_managers (
	account_manager_id		serial primary key,
	org_id					integer references orgs,
	account_manager_name	varchar(120),
	account_manager_phone	varchar(120),
	account_manager_email	varchar(120),
	details					text
);
CREATE INDEX account_managers_org_id ON account_managers (org_id);

CREATE TABLE clients (
	client_id				serial primary key,
	account_manager_id		integer references account_managers,
	org_id					integer references orgs,
	client_name				varchar(120),
	address					varchar(50),
	zipcode					varchar(16),
	premises				varchar(120),
	street					varchar(120),
	division				varchar(50),
	town					varchar(50),
	country_id				varchar(2) references sys_countrys,
	telno					varchar(320),
	email					varchar(320),
	pcc						varchar(50),
	iatano					varchar(50),
	website					varchar(120),
	travel_manager			varchar(120),
	travel_manager_email	varchar(120),
	technical_contact		varchar(120),
	technical_contact_email	varchar(120),
	is_active				boolean not null default true,
	address_updated			boolean not null default false,
	details					text
);
CREATE INDEX clients_account_manager_id ON clients (account_manager_id);
CREATE INDEX clients_country_id ON clients (country_id);
CREATE INDEX clients_org_id ON clients (org_id);

CREATE TABLE contact_roles (
	contact_role_id			serial primary key,
	org_id					integer references orgs,
	contact_role_name		varchar(50)
);
CREATE INDEX contact_roles_org_id ON contact_roles (org_id);

CREATE TABLE contacts (
	contact_id				serial primary key,
	client_id				integer references clients,
	contact_role_id			integer references contact_roles,
	org_id					integer references orgs,
	salutation				varchar(7),
	full_name				varchar(120) not null,
	phone_number			varchar(25),
	mobile_number			varchar(25),
	email					varchar(120),
	birthdate				date,
	SON						varchar(4),
	details					text
);
CREATE INDEX contacts_client_id ON contacts (client_id);
CREATE INDEX contacts_contact_role_id ON contacts (contact_role_id);
CREATE INDEX contacts_org_id ON contacts (org_id);

CREATE TABLE client_requests (
	client_request_id		serial primary key,
	client_id				integer references clients,
	org_id					integer references orgs,

	otrs_ref				varchar(50),
	crm_ref					varchar(50),
	dnote_no				varchar(50),

	request_type			varchar(16),
	request_status			varchar(16),
	request_completed		boolean default false not null,
	completion_date			date,

	receiving_engineer		varchar(32),
	receiving_at_agency		varchar(32),

	request_details			text,
	details					text,

	application_date		timestamp default now(),
	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	action_date				timestamp
);
CREATE INDEX client_requests_client_id ON client_requests (client_id);
CREATE INDEX client_requests_org_id ON client_requests (org_id);

CREATE TABLE client_assets (
	client_asset_id			serial primary key,
	client_request_id		integer references client_requests,
	asset_id				integer references assets,
	replaced_asset_id		integer references assets,
	org_id					integer references orgs,
	is_issued				boolean not null default true,
	date_issued 			date not null default current_date,
	is_retrived				boolean default false not null,
	is_for_client			boolean default false not null,
	date_retrived			date,
	units					integer default 1 not null,

	equipment_status		varchar(240),

	narrative 				varchar(240),
	date_added				date default current_date,
	date_changed			date
);
CREATE INDEX client_assets_client_request_id ON client_assets (client_request_id);
CREATE INDEX client_assets_asset_id ON client_assets (asset_id);
CREATE INDEX client_assets_replaced_asset_id ON client_assets (replaced_asset_id);
CREATE INDEX client_assets_org_id ON client_assets (org_id);

CREATE TABLE client_links (
	client_link_id			serial primary key,
	client_request_id		integer references client_requests,
	entity_id				integer references entitys, 	--- Link provider
	org_id					integer references orgs,

	is_issued				boolean not null default true,
	date_issued 			date not null default current_date,

	is_retrived				boolean default false not null,
	date_retrived			date,

	link_capacity			integer,

	link_number				varchar(16),
	vlan_id					varchar(16),
	use_type				varchar(16),

	connection_type			varchar(16),
	IP_Allocation			varchar(32),
	public_IPs				varchar(32),


	narrative 				varchar(240),
	date_added				date default current_date,
	date_changed			date,

	details					text
);
CREATE INDEX client_links_client_request_id ON client_links (client_request_id);
CREATE INDEX client_links_entity_id ON client_links (entity_id);
CREATE INDEX client_links_org_id ON client_links (org_id);

CREATE TABLE provision_types (
	provision_type_id		serial primary key,
	provision_type_name		varchar(240),
	charge_per_hour			real not null,
	details					text
);

CREATE TABLE client_provisions (
	client_provision_id		serial primary key,
	client_request_id		integer references client_requests,
	provision_type_id		integer references provision_types,
	org_id					integer references orgs,

	is_issued				boolean not null default true,
	date_issued 			date not null default current_date,

	narrative 				varchar(240),

	hours					real,
	amount					real,

	date_added				date default current_date,
	date_changed			date,

	details					text
);
CREATE INDEX client_provisions_client_request_id ON client_provisions (client_request_id);
CREATE INDEX client_provisions_provision_type_id ON client_provisions (provision_type_id);
CREATE INDEX client_provisions_org_id ON client_provisions (org_id);

CREATE VIEW vw_clients AS
	SELECT sys_countrys.sys_country_id, sys_countrys.sys_country_name, 

		account_managers.account_manager_id, account_managers.account_manager_name,
		account_managers.account_manager_phone, account_managers.account_manager_email,

		clients.client_id, clients.client_name, clients.address, clients.zipcode, 
		clients.premises, clients.street, clients.division, clients.town, 
		clients.telno, clients.email, clients.pcc, clients.iatano, clients.website, 
		clients.travel_manager, clients.technical_contact, clients.technical_contact_email,
		clients.is_active, clients.details
	FROM clients INNER JOIN sys_countrys ON clients.country_id = sys_countrys.sys_country_id
		LEFT JOIN account_managers ON clients.account_manager_id = account_managers.account_manager_id;

CREATE VIEW vw_client_requests AS
	SELECT vw_clients.client_id, vw_clients.client_name, vw_clients.address, vw_clients.zipcode, 
		vw_clients.premises, vw_clients.street, vw_clients.division, vw_clients.town, 
		vw_clients.telno, vw_clients.email, vw_clients.pcc, vw_clients.iatano, vw_clients.website, 
		vw_clients.travel_manager, vw_clients.technical_contact,
		vw_clients.is_active, vw_clients.sys_country_id, vw_clients.sys_country_name, 
		vw_clients.account_manager_id, vw_clients.account_manager_name,
		vw_clients.account_manager_phone, vw_clients.account_manager_email,

		client_requests.client_request_id, client_requests.otrs_ref, client_requests.crm_ref, client_requests.dnote_no, 
		client_requests.request_type, client_requests.request_status,
		client_requests.receiving_engineer, client_requests.receiving_at_agency,
		client_requests.request_completed, client_requests.completion_date,
		client_requests.request_details, client_requests.details,
		client_requests.application_date, client_requests.approve_status, 
		client_requests.workflow_table_id, client_requests.action_date
	FROM vw_clients INNER JOIN client_requests ON vw_clients.client_id = client_requests.client_id;
	
CREATE OR REPLACE FUNCTION check_retrived(int, int) RETURNS int AS $$
	SELECT max(client_assets.client_asset_id)
	FROM client_requests INNER JOIN client_assets ON client_requests.client_request_id = client_assets.client_request_id
	WHERE (client_requests.client_id = $1) AND (client_assets.replaced_asset_id = $2) AND (client_assets.is_retrived = true);
$$ LANGUAGE SQL;

CREATE VIEW vw_client_assets AS
	SELECT vw_client_requests.client_id, vw_client_requests.client_name, vw_client_requests.address, vw_client_requests.zipcode, 
		vw_client_requests.premises, vw_client_requests.street, vw_client_requests.division, vw_client_requests.town, 
		vw_client_requests.telno, vw_client_requests.email, vw_client_requests.pcc, vw_client_requests.iatano, vw_client_requests.website, 
		vw_client_requests.travel_manager, vw_client_requests.technical_contact,
		vw_client_requests.is_active, vw_client_requests.sys_country_id, vw_client_requests.sys_country_name, 
		vw_client_requests.account_manager_id, vw_client_requests.account_manager_name,
		vw_client_requests.account_manager_phone, vw_client_requests.account_manager_email,

		vw_client_requests.client_request_id, vw_client_requests.otrs_ref, vw_client_requests.crm_ref, 
		vw_client_requests.dnote_no, vw_client_requests.request_details, 
		vw_client_requests.request_type, vw_client_requests.request_status,
		vw_client_requests.receiving_engineer, vw_client_requests.receiving_at_agency,
		vw_client_requests.request_completed, vw_client_requests.completion_date,
		vw_client_requests.application_date, vw_client_requests.approve_status, 
		vw_client_requests.workflow_table_id, vw_client_requests.action_date,

		vw_assets.asset_type_id, vw_assets.asset_type_name, vw_assets.manufacturer_id, vw_assets.manufacturer_name, 
		vw_assets.model_id, vw_assets.model_name, vw_assets.model,
		vw_assets.asset_status_id, vw_assets.asset_status_name, vw_assets.entity_id, vw_assets.entity_name,
		vw_assets.asset_id, vw_assets.asset_description, vw_assets.asset_serial, vw_assets.purchase_date, 
		vw_assets.purchase_value, vw_assets.disposal_amount, vw_assets.disposal_date, vw_assets.disposal_posting, vw_assets.lost, 
		vw_assets.stolen, vw_assets.tag_number, vw_assets.asset_condition, 
		vw_assets.asset_disp,
		check_retrived(vw_client_requests.client_id, client_assets.asset_id) as retrived,
		
		r_assets.asset_type_id as r_asset_type_id, r_assets.asset_type_name as r_asset_type_name, 
		r_assets.manufacturer_id as r_manufacturer_id, r_assets.manufacturer_name as r_manufacturer_name,
		r_assets.model_id as r_model_id, r_assets.model_name as r_model_name, r_assets.model as r_model,
		r_assets.asset_id as r_asset_id, r_assets.asset_serial as r_asset_serial,
		r_assets.tag_number as r_tag_number, r_assets.asset_condition as r_asset_condition, 
		r_assets.asset_disp as r_asset_disp,

		client_assets.org_id, client_assets.client_asset_id, client_assets.is_issued, client_assets.date_issued, 
		client_assets.is_retrived, client_assets.date_retrived, client_assets.units, client_assets.narrative, 
		client_assets.equipment_status, client_assets.date_added, client_assets.date_changed,
		client_assets.is_for_client
	FROM client_assets INNER JOIN vw_client_requests ON client_assets.client_request_id = vw_client_requests.client_request_id
		LEFT JOIN vw_assets ON client_assets.asset_id = vw_assets.asset_id
		LEFT JOIN vw_assets as r_assets ON client_assets.replaced_asset_id = r_assets.asset_id;

CREATE VIEW vw_client_links AS
	SELECT vw_client_requests.client_id, vw_client_requests.client_name, vw_client_requests.address, vw_client_requests.zipcode, 
		vw_client_requests.premises, vw_client_requests.street, vw_client_requests.division, vw_client_requests.town, 
		vw_client_requests.telno, vw_client_requests.email, vw_client_requests.pcc, vw_client_requests.iatano, vw_client_requests.website, 
		vw_client_requests.travel_manager, vw_client_requests.technical_contact,
		vw_client_requests.is_active, vw_client_requests.sys_country_id, vw_client_requests.sys_country_name, 
		vw_client_requests.account_manager_id, vw_client_requests.account_manager_name,
		vw_client_requests.account_manager_phone, vw_client_requests.account_manager_email,

		vw_client_requests.client_request_id, vw_client_requests.otrs_ref, vw_client_requests.crm_ref, 
		vw_client_requests.dnote_no, vw_client_requests.request_details, 
		vw_client_requests.request_type, vw_client_requests.request_status,
		vw_client_requests.receiving_engineer, vw_client_requests.receiving_at_agency,
		vw_client_requests.request_completed, vw_client_requests.completion_date,
		vw_client_requests.application_date, vw_client_requests.approve_status, 
		vw_client_requests.workflow_table_id, vw_client_requests.action_date,

		entitys.entity_id, entitys.entity_name, 
		
		client_links.client_link_id, client_links.is_issued, client_links.date_issued, client_links.is_retrived, 
		client_links.date_retrived, client_links.link_capacity, client_links.connection_type, 
		client_links.link_number, client_links.vlan_id, client_links.use_type, 
		client_links.ip_allocation, client_links.public_ips, client_links.narrative, 
		client_links.date_added, client_links.date_changed, client_links.details
	FROM client_links INNER JOIN vw_client_requests ON client_links.client_request_id = vw_client_requests.client_request_id
		INNER JOIN entitys ON client_links.entity_id = entitys.entity_id;

CREATE VIEW vw_client_provisions AS
	SELECT vw_client_requests.client_id, vw_client_requests.client_name, vw_client_requests.address, vw_client_requests.zipcode, 
		vw_client_requests.premises, vw_client_requests.street, vw_client_requests.division, vw_client_requests.town, 
		vw_client_requests.telno, vw_client_requests.email, vw_client_requests.pcc, vw_client_requests.iatano, vw_client_requests.website, 
		vw_client_requests.travel_manager, vw_client_requests.technical_contact,
		vw_client_requests.is_active, vw_client_requests.sys_country_id, vw_client_requests.sys_country_name, 
		vw_client_requests.account_manager_id, vw_client_requests.account_manager_name,
		vw_client_requests.account_manager_phone, vw_client_requests.account_manager_email,

		vw_client_requests.client_request_id, vw_client_requests.otrs_ref, vw_client_requests.crm_ref, 
		vw_client_requests.dnote_no, vw_client_requests.request_details, 
		vw_client_requests.request_type, vw_client_requests.request_status,
		vw_client_requests.receiving_engineer, vw_client_requests.receiving_at_agency,
		vw_client_requests.request_completed, vw_client_requests.completion_date,
		vw_client_requests.application_date, vw_client_requests.approve_status, 
		vw_client_requests.workflow_table_id, vw_client_requests.action_date,

		provision_types.provision_type_id, provision_types.provision_type_name,

		client_provisions.org_id, client_provisions.client_provision_id, client_provisions.is_issued, 
		client_provisions.date_issued, client_provisions.narrative, client_provisions.hours, 
		client_provisions.amount, client_provisions.date_added, client_provisions.date_changed, 
		client_provisions.details
	FROM client_provisions INNER JOIN vw_client_requests ON client_provisions.client_request_id = vw_client_requests.client_request_id
		INNER JOIN provision_types ON client_provisions.provision_type_id = provision_types.provision_type_id;


CREATE OR REPLACE FUNCTION ins_client_assets() RETURNS trigger AS $$
DECLARE
	v_client_id				integer;
	v_client_asset_id		integer;
BEGIN

	IF (NEW.is_retrived = true) AND (NEW.replaced_asset_id is null) THEN
		RAISE EXCEPTION 'Enter the serial number for retrived equipment';
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_client_assets AFTER INSERT OR UPDATE ON client_assets
	FOR EACH ROW EXECUTE PROCEDURE ins_client_assets();

CREATE OR REPLACE FUNCTION aft_client_assets() RETURNS trigger AS $$
DECLARE
	v_client_id				integer;
	v_client_asset_id		integer;
BEGIN

	IF(TG_OP = 'DELETE')THEN
		IF(OLD.is_retrived = true)THEN
			UPDATE assets SET asset_status_id = 1 WHERE (asset_id = OLD.asset_id);
		ELSIF(OLD.is_issued = true)THEN
			UPDATE assets SET asset_status_id = 2 WHERE (asset_id = OLD.asset_id);
		END IF;
	ELSE
		IF(NEW.is_retrived = true)THEN
			UPDATE assets SET asset_status_id = 1 WHERE (asset_id = NEW.replaced_asset_id);
		END IF;
		IF(NEW.is_issued = true)THEN
			UPDATE assets SET asset_status_id = 2 WHERE (asset_id = NEW.asset_id);
		END IF;
	END IF;

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER aft_client_assets AFTER INSERT OR UPDATE OR DELETE ON client_assets
	FOR EACH ROW EXECUTE PROCEDURE aft_client_assets();

CREATE OR REPLACE FUNCTION aft_asset_movements() RETURNS trigger AS $$
BEGIN

	IF(NEW.asset_location_id = 1)THEN
		UPDATE assets SET asset_status_id = 1 WHERE (asset_id = NEW.asset_id);
	ELSIF(NEW.asset_location_id = 2)THEN
		UPDATE assets SET asset_status_id = 3 WHERE (asset_id = NEW.asset_id);
	END IF;

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER aft_asset_movements AFTER INSERT OR UPDATE ON asset_movements
	FOR EACH ROW EXECUTE PROCEDURE aft_asset_movements();
	
	

