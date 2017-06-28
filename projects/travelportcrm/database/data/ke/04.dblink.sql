

-- load extension first time after install
CREATE EXTENSION postgres_fdw;

-- create server object
CREATE SERVER dewcis_assets FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host '192.168.0.2', dbname 'assets', port '5432');

-- create user mapping
CREATE USER MAPPING FOR postgres SERVER dewcis_assets
OPTIONS (user 'assetdew', password 'DEW1sset');


CREATE FOREIGN TABLE i_entitys (
	entity_id				integer,
	entity_name				varchar(120) not null,
	user_name				varchar(120) not null,
	primary_email			varchar(120),
	primary_telephone		varchar(50),
	super_user				boolean default false not null,
	entity_leader			boolean default false not null,
	no_org					boolean default false not null,
	function_role			varchar(240),
	date_enroled			timestamp default now(),
	is_active				boolean default true,
	entity_password			varchar(64) not null,
	first_password			varchar(64) not null,
	new_password			varchar(64),
	start_url				varchar(64),
	is_picked				boolean default false not null,
	details					text
) SERVER dewcis_assets OPTIONS(table_name 'entitys');

CREATE FOREIGN TABLE i_asset_types (
	asset_type_id			integer,
	asset_type_name			varchar(50) not null,
	depreciation_rate		real default 10 not null,
	display_order			integer,
	details					text
) SERVER dewcis_assets OPTIONS(table_name 'asset_types');

CREATE FOREIGN TABLE i_manufacturers (
	manufacturer_id			integer,
	manufacturer_name		varchar(50) not null,
	details					text
 )SERVER dewcis_assets OPTIONS(table_name 'manufacturers');

CREATE FOREIGN TABLE i_models (
	model_id				integer,
	manufacturer_id			integer,
	asset_type_id			integer,
	model_name				varchar(50) not null,
	details					text
) SERVER dewcis_assets OPTIONS(table_name 'models');

CREATE FOREIGN TABLE i_asset_status (
	asset_status_id			integer,
	asset_status_name		varchar(32) not null
) SERVER dewcis_assets OPTIONS(table_name 'asset_status');

CREATE FOREIGN TABLE i_assets (
	asset_id				integer,
	model_id				integer,
	asset_status_id			integer,
	entity_id				integer, 	--- Sales office
	asset_description		varchar(50),
	asset_serial			varchar(50),
	purchase_date			date not null,
	purchase_value			real not null,
	disposal_amount			real,
	disposal_date			date,
	sold					boolean default false not null,
	disposal_posting		boolean default false not null,
	lost					boolean default false not null,
	stolen					boolean default false not null,
	purchase_invoiced		boolean default false not null,
	tag_number				varchar(50),
	asset_condition			varchar(50),
	client_id				integer,
	details					text
) SERVER dewcis_assets OPTIONS(table_name 'assets');


CREATE FOREIGN TABLE i_clients (
	client_id				integer,
	account_manager_id		integer,
	client_name				varchar(120),
	address					varchar(50),
	zipcode					varchar(16),
	premises				varchar(120),
	street					varchar(120),
	division				varchar(50),
	town					varchar(50),
	country_id				varchar(2),
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
) SERVER dewcis_assets OPTIONS(table_name 'clients');

CREATE FOREIGN TABLE i_client_requests (
	client_request_id		integer,
	client_id				integer,

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
) SERVER dewcis_assets OPTIONS(table_name 'client_requests');

CREATE FOREIGN TABLE i_client_assets (
	client_asset_id			integer,
	client_request_id		integer,
	asset_id				integer,
	replaced_asset_id		integer,
	is_issued				boolean not null default true,
	date_issued 			date not null default current_date,
	is_retrived				boolean default false not null,
	date_retrived			date,
	units					integer default 1 not null,

	equipment_status		varchar(240),

	narrative 				varchar(240),
	date_added				date default current_date,
	date_changed			date
) SERVER dewcis_assets OPTIONS(table_name 'client_assets');

CREATE FOREIGN TABLE i_client_links (
	client_link_id			integer,
	client_request_id		integer,
	entity_id				integer, 	--- Link provider

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
) SERVER dewcis_assets OPTIONS(table_name 'client_links');

