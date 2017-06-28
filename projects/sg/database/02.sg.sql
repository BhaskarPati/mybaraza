---Project Database File
UPDATE  entitys SET no_org = true WHERE entity_id = 0;
UPDATE  entitys SET no_org = true WHERE entity_id = 1;;
ALTER TABLE orgs DROP CONSTRAINT orgs_org_sufix_key;
ALTER TABLE orgs ALTER COLUMN org_sufix  SET DEFAULT 'sg';

CREATE TABLE regions (
	region_id			serial primary key,
	org_id				integer references orgs,
	region_name			varchar(50) not null,
	details				text
);
CREATE INDEX regions_org_id ON regions(org_id);

CREATE TABLE sub_regions (
	sub_region_id		serial primary key,
	region_id			integer references regions,
	org_id				integer references orgs,
	sub_region_name		varchar(50) not null,
	details				text
);
CREATE INDEX sub_regions_region_id ON sub_regions(region_id);
CREATE INDEX sub_regions_org_id ON sub_regions(org_id);

CREATE TABLE distributors (
	distributor_id		serial primary key,
	sub_region_id		integer references sub_regions,
	org_id				integer references orgs,
	distributor_name	varchar(50) not null,
	details				text
);
CREATE INDEX distributors_sub_region_id ON distributors(sub_region_id);
CREATE INDEX distributors_org_id ON distributors(org_id);

ALTER TABLE entitys ADD distributor_id		integer references distributors;

CREATE TABLE products (
	product_id			serial primary key,
	org_id				integer references orgs,
	product_name		varchar(50),
	details				text
);

CREATE TABLE sale_types (
	sale_type_id		serial primary key,
	org_id				integer references orgs,
	sale_type_name		varchar(50),
	details				text
);

CREATE TABLE sales (
	sale_id				serial primary key,
	product_id			integer references products,
	sale_type_id		integer references sale_types,
	distributor_id		integer references distributors,
	entity_id 			integer references entitys,
	org_id				integer references orgs,
	sale_date			date not null,
	ordered				integer default 0 not null,
	supplied			integer default 0 not null,
	delivered			integer default 0 not null,
	vendor_confirmed	integer default 0 not null,
	vendor_sold			integer default 0 not null,
	vendor_returns		integer default 0 not null,
	unit_price			real default 0 not null,
	details				text
);
CREATE INDEX sales_org_id ON sales(org_id);
CREATE INDEX sales_distributor_id ON sales(distributor_id);
CREATE INDEX sales_entity_id ON sales(entity_id);

CREATE TABLE receipt_sources (
	receipt_source_id	serial primary key,
	org_id				integer references orgs,
	receipt_source_name	varchar(50),
	details				text
);

CREATE TABLE receipts (
	sale_id				serial primary key,
	receipt_source_id	integer references receipt_sources,
	mpesa_trx_id		integer references mpesa_trxs,
	distributor_id		integer references distributors,
	entity_id 			integer references entitys,
	org_id				integer references orgs,
	receipt_date		date not null,
	receipt_amount		real not null,
	details				text
);



