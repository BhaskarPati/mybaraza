CREATE TABLE clients (
	clientid		serial primary key,
	clientno		varchar(50),
	clientname		varchar(50) not null,
	address			varchar(75),
	city			varchar(75),
	premises		varchar(120),
	street			varchar(120),
	countryid		varchar(2) references countrys,
	postalcode		varchar(50),
	telno			varchar(75),
	mobile			varchar(75),
	email			varchar(120),
	FaxNo			varchar(75),
	Details			text
);

CREATE TABLE vendors (
	vendorid		serial primary key,
	vendorno		varchar(50),
	vendorname		varchar(50),
	address			varchar(50),
	city			varchar(50),
	premises		varchar(120),
	street			varchar(120),
	countryid		varchar(2) references countrys,
	postalcode		varchar(50),
	telno			varchar(75),
	faxno			varchar(75),
	website			varchar(120),
	email			varchar(120),
	Details			text
);
	
CREATE TABLE assets (
	assetid			serial primary key,
	vendorid		integer references vendors,
	assetname		varchar(50),
	contactperson		varchar(50),
	countryid		varchar(2) references countrys,
	location		varchar(50),
	telno			varchar(75),
	website			varchar(120),
	email			varchar(120),
	details			text
);

CREATE TABLE package (
	packageid		serial primary key,
	packagename		varchar(50),
	seasons			varchar(50),
	quantity		varchar(50),
	price			real not null,
	details			text
);

CREATE TABLE rates (
	rateid			serial primary key,
	packageid 		integer references package,
	assetid			integer references assets,
	roomtype		varchar(50),
	roomdescription		varchar(50),
	mealplan		varchar(50),
	startdate		date not null,
	enddate			date not null,
	packagerate		boolean not null default false,
	description		varchar(120),
	currentrate		real not null default 0,
	tax			real not null default 0,
	commission		real not null default 0,
	discount		real not null default 0,
	finalrate		boolean not null default false,
	details			text
);


CREATE TABLE vouchers (
	voucherid		serial primary key,
	clientid		integer references clients,
	assetid			integer references assets,
	bookdate		varchar(50),
	residents		varchar(12),
	nonresidents		varchar(12),
	tourto			varchar(120),
	attention		varchar(50),
	clientname		varchar(50),
	client1			varchar(50),
	client2			varchar(50),
	client3			varchar(50),
	client4			varchar(50),
	client5			varchar(50),
	client6			varchar(50),
	client7			varchar(50),
	client8			varchar(50),
	nopax			varchar(50),
	noadults		varchar(50),
	children		varchar(50),
	childrenage		varchar(50),
	infants			varchar(50),
	infantsage		varchar(50),
	transtype		varchar(50),
	voucherno		varchar(50),
	atselect		varchar(50),
	vendorname		varchar(50),
	bnoofnight		varchar(50),
	anoofnight		varchar(50),
	btripple		varchar(50),
	atripple		varchar(50),
	bdouble			varchar(50),
	adouble			varchar(50),
	bsingle			varchar(50),
	asingle			varchar(50),
	bextrabed		varchar(50),
	aextrabed		varchar(50),
	ababycot		varchar(50),
	bbabycot		varchar(50),
	mealplan		varchar(50),
	datein			varchar(50),
	dateout			varchar(50),
	chargetour		varchar(50),
	chargeclient		varchar(50),
	extratour		varchar(50),
	extraclient		varchar(50),
	confirmation		varchar(50),
	confirmationref		varchar(50),
	bookedby		varchar(50),
	username		varchar(50),
	ipaddress		varchar(50),
	instructions		text
);

CREATE TABLE price (
	priceid			serial primary key,
	rateid 			integer references rates,
	voucherid		integer references vouchers,
	currentprice		real not null,
	vendordiscount		real not null,
	clientdiscount		real not null,
	commision		real not null,
	markup			real,
	commissiontrack		boolean not null default false,
	netprice		real not null,
	finalprice		boolean not null default false,
	details			text
);

CREATE VIEW vwclients AS
	SELECT countrys.countryname, clients.clientid, clients.clientno, clients.clientname, clients.address, clients.city, clients.premises, clients.street,
		clients.countryid, clients.postalcode, clients.telno, clients.mobile, clients.email, clients.faxno, clients.details
	FROM clients
	INNER JOIN countrys ON clients.countryid = countrys.countryid;

CREATE VIEW vwvendors AS
	SELECT countrys.countryname, vendors.vendorid, vendors.vendorno, vendors.vendorname, vendors.address, vendors.city, vendors.premises, vendors.street, 
		vendors.countryid, vendors.postalcode, vendors.telno, vendors.faxno, vendors.website, vendors.email, vendors.details
	FROM vendors
	INNER JOIN countrys ON vendors.countryid = countrys.countryid;

CREATE VIEW vwassets AS
	SELECT countrys.countryname, vendors.vendorname, assets.assetid, assets.vendorid, assets.assetname, assets.contactperson, assets.countryid,
		assets.location, assets.telno, assets.website, assets.email, assets.details
	FROM assets
	INNER JOIN countrys ON assets.countryid = countrys.countryid
	INNER JOIN vendors ON assets.vendorid = vendors.vendorid;

CREATE VIEW vwpackage AS
	SELECT package.packageid, package.packagename, 
	package.seasons, package.quantity, package.price, package.details
	FROM package;

CREATE VIEW vwrates AS
	SELECT assets.assetname, rates.rateid, rates.assetid, rates.roomdescription, rates.mealplan, rates.packagerate, rates.roomtype, rates.description, rates.currentrate,
	 rates.tax, rates.details, rates.startdate, rates.enddate, rates.commission, rates.discount, rates.finalrate
	FROM rates 
	INNER JOIN assets ON rates.assetid = assets.assetid;
	

CREATE VIEW vwvouchers AS
	SELECT assets.assetname, vouchers.voucherid, vouchers.clientid, vouchers.assetid, vouchers.bookdate, vouchers.residents,
		vouchers.nonresidents, vouchers.tourto, vouchers.attention, vouchers.clientname, vouchers.client1, vouchers.client2, vouchers.client3,
		vouchers.client4, vouchers.client5, vouchers.client6, vouchers.client7, vouchers.client8, vouchers.nopax, vouchers.noadults, vouchers.children, 
		vouchers.childrenage, vouchers.infants, vouchers.infantsage, vouchers.transtype, vouchers.voucherno, vouchers.atselect, vouchers.vendorname, 
		vouchers.bnoofnight, vouchers.anoofnight, vouchers.btripple, vouchers.atripple, vouchers.bdouble, vouchers.adouble, vouchers.bsingle,
		vouchers.asingle, vouchers.bextrabed, vouchers.aextrabed, vouchers.ababycot, vouchers.bbabycot, vouchers.mealplan, vouchers.datein, 
		vouchers.dateout, vouchers.chargetour, vouchers.chargeclient, vouchers.extratour, vouchers.extraclient, vouchers.confirmation,
		vouchers.confirmationref, vouchers.instructions, vouchers.username, vouchers.ipaddress,
			('<a href="voucher?voucherid=' || vouchers.voucherid || '">' || vouchers.voucherid || '</a>') AS voucherlink
	FROM (vouchers LEFT JOIN assets ON vouchers.assetid = assets.assetid)
		LEFT JOIN clients ON vouchers.clientid = clients.clientid
		LEFT JOIN vouchers as ammended ON CAST(vouchers.voucherid as varchar) = trim(ammended.voucherno)
		WHERE (ammended.voucherno is null);

CREATE VIEW vwprice AS
	SELECT price.priceid, price.rateid, price.voucherid, price.currentprice, price.vendordiscount, price.clientdiscount, price.commision, 	
	price.netprice, price.details, price.finalprice, price.markup, price.commissiontrack
	FROM price
	INNER JOIN rates ON price.rateid = rates.rateid
	INNER JOIN vouchers ON price.voucherid = vouchers.voucherid;

