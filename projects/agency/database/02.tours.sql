CREATE TABLE assets (
	asset_id				serial primary key,
	entity_id				integer references entitys,
	sys_country_id			varchar(2) references sys_countrys,
	org_id					integer references orgs,
	asset_name				varchar(50) not null,
	contact_person			varchar(50) not null,
	location				varchar(50),
	telno					varchar(75),
	website					varchar(120),
	email					varchar(120),
	details					text
);
CREATE INDEX assets_entity_id ON assets (entity_id);
CREATE INDEX assets_sys_country_id ON assets (sys_country_id);
CREATE INDEX assets_org_id ON assets (org_id);

CREATE TABLE rates (
	rate_id					serial primary key,
	asset_id				integer references assets,
	org_id					integer references orgs,
	room_type				varchar(50),
	room_description		varchar(50),
	meal_plan				varchar(50),
	start_date				date not null,
	end_date				date not null,
	description				varchar(120),
	currency				varchar(3),
	rate					real not null default 0,
	tax						real not null default 0,
	commission				real not null default 0,
	discount				real not null default 0,
	final_rate				boolean not null default false,
	non_residents			boolean not null default false,
	details					text
);
CREATE INDEX rates_asset_id ON rates (asset_id);
CREATE INDEX rates_org_id ON rates (org_id);

CREATE TABLE packages (
	package_id				serial primary key,
	org_id					integer references orgs,
	package_name			varchar(50),
	start_date				date not null,
	end_date				date not null,
	price					real not null,
	description				text,
	details					text
);
CREATE INDEX packages_org_id ON packages (org_id);

CREATE TABLE package_rates (
	package_rate_id			serial primary key,
	package_id 				integer references packages,
	rate_id					integer references rates,
	org_id					integer references orgs,
	details					text
);
CREATE INDEX package_rates_package_id ON package_rates (package_id);
CREATE INDEX package_rates_rate_id ON package_rates (rate_id);
CREATE INDEX package_rates_org_id ON  package_rates (org_id);

CREATE TABLE vouchers (
	voucher_id				serial primary key,
	entity_id				integer references entitys,
	asset_id				integer references assets,
	org_id					integer references orgs,
	book_date				varchar(50),
	residents				varchar(12),
	nonresidents			varchar(12),
	tourto					varchar(120),
	attention				varchar(50),
	clientname				varchar(50),
	client1					varchar(50),
	client2					varchar(50),
	client3					varchar(50),
	client4					varchar(50),
	client5					varchar(50),
	client6					varchar(50),
	client7					varchar(50),
	client8					varchar(50),
	nopax					varchar(50),
	noadults				varchar(50),
	children				varchar(50),
	childrenage				varchar(50),
	infants					varchar(50),
	infantsage				varchar(50),
	transtype				varchar(50),
	voucherno				varchar(50),
	bookdate				varchar(50),
	atselect				varchar(50),
	vendorname				varchar(50),
	bnoofnight				varchar(50),
	anoofnight				varchar(50),
	btripple				varchar(50),
	atripple				varchar(50),
	bdouble					varchar(50),
	adouble					varchar(50),
	bsingle					varchar(50),
	asingle					varchar(50),
	bextrabed				varchar(50),
	aextrabed				varchar(50),
	ababycot				varchar(50),
	bbabycot				varchar(50),
	aextranight				varchar(50),
	bextranight				varchar(50),
	amealplan				varchar(50),
	bmealplan				varchar(50),
	datein					varchar(50),
	roomtype				varchar(50),
	dateout					varchar(50),
	chargetour				varchar(50),
	chargeclient			varchar(50),
	extratour				varchar(50),
	extraclient				varchar(50),
	confirmation			varchar(50),
	confirmationref			varchar(50),
	bookedby				varchar(50),
	username				varchar(50),
	ipaddress				varchar(50),
	currency				varchar(3),
	voucher_link			integer default 0 not null,
	instructions			text
);
CREATE INDEX vouchers_entity_id ON vouchers (entity_id);
CREATE INDEX vouchers_asset_id ON vouchers (asset_id);
CREATE INDEX vouchers_org_id ON vouchers (org_id);

CREATE TABLE price (
	price_id				serial primary key,
	rate_id 				integer references rates,
	voucher_id				integer references vouchers,
	org_id					integer references orgs,
	current_price			real not null,
	vendor_discount			real not null,
	client_discount			real not null,
	currency				varchar(3),
	commision				real not null,
	markup					real not null,
	commission_track		boolean not null default false,
	net_price				real not null,
	final_price				boolean not null default false,
	details					text
);
CREATE INDEX price_rate_id ON price (rate_id);
CREATE INDEX price_voucher_id ON price (voucher_id);
CREATE INDEX price_org_id ON price (org_id);

CREATE VIEW vw_assets AS
	SELECT entitys.entity_id, entitys.entity_name as vendor_name, sys_countrys.sys_country_id, sys_countrys.sys_country_name, 
		assets.asset_id, assets.asset_name, assets.contact_person, assets.location, 
		assets.telno, assets.website, assets.email, assets.details
	FROM assets 	INNER JOIN entitys ON assets.entity_id = entitys.entity_id
		INNER JOIN sys_countrys ON assets.sys_country_id = sys_countrys.sys_country_id;

CREATE VIEW vw_rates AS
	SELECT vw_assets.entity_id, vw_assets.vendor_name, vw_assets.sys_country_id, vw_assets.sys_country_name, 
		vw_assets.asset_id, vw_assets.asset_name, vw_assets.contact_person, vw_assets.location, 
		vw_assets.telno, vw_assets.website, vw_assets.email, vw_assets.details as asset_details,
		rates.rate_id, rates.room_type, rates.room_description, rates.meal_plan, rates.start_date, rates.end_date, 
		rates.description, rates.currency, rates.rate, rates.tax, rates.commission, rates.discount, rates.final_rate, 
		rates.non_residents, rates.details
	FROM rates INNER JOIN vw_assets ON rates.asset_id = vw_assets.asset_id;

CREATE VIEW vw_package_rates AS
	SELECT packages.package_id, packages.package_name, packages.start_date, packages.end_date, packages.price, 
		packages.description, packages.details as package_details,
		vw_rates.entity_id, vw_rates.vendor_name, vw_rates.sys_country_id, vw_rates.sys_country_name, 
		vw_rates.asset_id, vw_rates.asset_name, vw_rates.contact_person, vw_rates.location, 
		vw_rates.telno, vw_rates.website, vw_rates.email, vw_rates.details as asset_details,
		vw_rates.rate_id, vw_rates.room_type, vw_rates.room_description, vw_rates.meal_plan, 
		vw_rates.start_date as rate_start, vw_rates.end_date as rate_end,  vw_rates.description as rate_description, vw_rates.currency,
		vw_rates.rate, vw_rates.tax, vw_rates.commission, vw_rates.discount, vw_rates.final_rate, vw_rates.details as rate_details,
		vw_rates.non_residents, package_rates.package_rate_id, package_rates.details
	FROM package_rates INNER JOIN packages ON package_rates.package_id = packages.package_id
		INNER JOIN vw_rates ON package_rates.rate_id = vw_rates.rate_id;

CREATE VIEW vw_vouchers AS
	SELECT vw_assets.asset_id, vw_assets.asset_name, vw_assets.entity_id as vendor_id, vw_assets.vendor_name,
		entitys.entity_id, entitys.entity_name, vouchers.voucher_id, vouchers.book_date, 
		vouchers.residents, vouchers.nonresidents, vouchers.tourto, vouchers.attention, vouchers.clientname, vouchers.client1, 
		vouchers.client2, vouchers.client3, vouchers.client4, vouchers.client5, vouchers.client6, vouchers.client7, vouchers.client8, 
		vouchers.nopax, vouchers.noadults, vouchers.children, vouchers.childrenage, vouchers.infants, vouchers.infantsage, vouchers.transtype, 
		vouchers.voucherno, vouchers.atselect, vouchers.vendorname, vouchers.bnoofnight, vouchers.anoofnight, vouchers.btripple, 
		vouchers.atripple, vouchers.bdouble, vouchers.adouble, vouchers.bsingle, vouchers.asingle, vouchers.bextrabed, 
		vouchers.aextrabed, vouchers.ababycot, vouchers.bbabycot, vouchers.datein, vouchers.dateout,  
		vouchers.confirmation, vouchers.confirmationref, vouchers.bookedby, 
		vouchers.username, vouchers.ipaddress, vouchers.instructions, vouchers.aextranight, vouchers.bextranight, vouchers.amealplan, 
		vouchers.bmealplan, vouchers.bookdate, vouchers.roomtype, vouchers.currency, vouchers.voucher_link,
		vouchers.chargetour, vouchers.chargeclient, vouchers.extratour, vouchers.extraclient
	FROM vouchers INNER JOIN vw_assets ON vouchers.asset_id = vw_assets.asset_id
		INNER JOIN entitys ON vouchers.entity_id = entitys.entity_id;

