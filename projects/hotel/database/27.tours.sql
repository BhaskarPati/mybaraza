
CREATE TABLE assets (
	asset_id				serial primary key,
	org_id					integer references orgs,
	link_org_id				integer references orgs,
	sys_country_id			char(2) references sys_countrys,
	asset_name				varchar(120) not null,
	contact_person			varchar(120),
	town					varchar(120),
	location				varchar(120),
	telno					varchar(75),
	website					varchar(120),
	email					varchar(120),
	details					text
);
CREATE INDEX assets_org_id ON assets (org_id);
CREATE INDEX assets_link_org_id ON assets (link_org_id);
CREATE INDEX assets_sys_country_id ON assets (sys_country_id);

CREATE TABLE vouchers (
	voucher_id				serial primary key,
	asset_id				integer references assets,
	currency_id				integer references currency,
	org_id					integer references orgs,

	pac1					varchar(50),
	pac2					varchar(50),
	pac3					varchar(50),
	pac4					varchar(50),
	pac5					varchar(50),
	pac6					varchar(50),
	pac7					varchar(50),
	pac8					varchar(50),

	voucher_link			integer,
	confirmationref			varchar(50),
	confirmation			varchar(50),

	adults					integer default 1 not null,
	children				integer default 1 not null,
	infants					integer default 1 not null,
	booking_date			varchar(20),,
	attention				varchar(100),
	trans_type				varchar(20),
	infant_sage				varchar(50),
	children_age			varchar(50),
	tour_to					varchar(100),
	room_type				varchar(200),

	ameal_plan				varchar(20),
	aextra_night			varchar(20),
	ano_of_night			integer,
	atripple				varchar(20),
	atselect				varchar(50),
	aextra_bed				varchar(20),
	ababy_cot				varchar(20),
	asingle					varchar(20),
	adouble					varchar(20),
	pax                     integer,

	charge_tour				varchar(30),
	charge_client			varchar(30),
	extra_tour				varchar(30),
	extra_client			varchar(30),
	residents				varchar(20),

	date_in					varchar(20),,
	date_out				varchar(20),
	booked_by               varchar(50),

	instructions			text
);
CREATE INDEX vouchers_entity_id ON vouchers (entity_id);
CREATE INDEX vouchers_asset_id ON vouchers (asset_id);
CREATE INDEX vouchers_currency_id ON vouchers (currency_id);
CREATE INDEX vouchers_org_id ON vouchers (org_id);
