CREATE TABLE tmpmanagement (
	tmpmanagementid			serial primary key,
	Client					varchar(50), 
	Booking           		varchar(50), 
	AgentReference			varchar(50), 
	Blank1					varchar(50),
	Blank2					varchar(50),
	CreationDate			varchar(50), 
	DepartureDate			varchar(50), 
	LeadName           		varchar(50), 
	WholesaleValue      	varchar(50),
	GrossValue				varchar(50), 
	Currency				varchar(50), 
	Commission				varchar(50), 
	SubAgent				varchar(50),
	externalrates			varchar(50),
	agentfee				varchar(50)
);

CREATE TABLE tmpsales (
	tmpsaleid				serial primary key,
	gkref					varchar(50),
	BookingID   			varchar(50), 
	AgentReference			varchar(50), 
	Item					varchar(50), 
	City   					varchar(120), 
	Name   					varchar(120), 
	ServiceDate     		varchar(50), 
	Nights  				varchar(50), 
	TotalPrice   			varchar(50),
	commission				varchar(50),
	Status   				varchar(50), 
	Alternate   			varchar(50), 
	Rmks   					varchar(50), 
	Completed   			varchar(50), 
	RequestedDate   		varchar(50), 
	RequestedTime   		varchar(50), 
	Nationality				varchar(50)
);

CREATE TABLE tmpnetrates (
	tmpnetrateid			serial primary key,
	gkref					varchar(50),
	BookingID   			varchar(50), 
	AgentReference			varchar(50), 
	Item					varchar(50), 
	City   					varchar(120), 
	Name   					varchar(120), 
	ServiceDate     		varchar(50), 
	Nights  				varchar(50), 
	TotalPrice   			varchar(50),
	commission				varchar(50),
	Status   				varchar(50), 
	Alternate   			varchar(50), 
	Rmks   					varchar(50), 
	Completed   			varchar(50), 
	RequestedDate   		varchar(50), 
	RequestedTime   		varchar(50), 
	Nationality				varchar(50),
	Supplier_Deadline		varchar(50)
);

CREATE TABLE gtarevenue (
	gtarevenueid			serial primary key,		
	ndcname					varchar(50),
	serviceid				varchar(7),
	servicename				varchar(120),
	basis					varchar(50),
	gkpercentage			real,
	TAcommissionout			real,
	sharedndccommission		real,
	otherndccommission		real,
	gk						real,
	totalcommissionearned	real,
	commisionable			boolean default false not null,
	details					text
);

CREATE TABLE clients (
	clientid				serial primary key,
	country_id				char(2) references countrys,
	clientname				varchar(50) unique,
	mst_cus_id				varchar(10),
	address					varchar(120),
	postalcode				varchar(12),
	Town					varchar(120),
	telno					varchar(120),
	contactperson			varchar(120),
	email					varchar(120),
	contact_person			varchar(120);
	IsActive				boolean default true not null,
	ispicked				boolean default false,
	details					text
	contact_person varchar(120);
);
CREATE INDEX clients_country_id ON clients (country_id);

CREATE TABLE clientbranches (
	clientbranchid			serial primary key,
	clientid 				integer references clients,
	branchname				varchar(100),
	IsActive				boolean default true not null,
	details					text
);
CREATE INDEX clientbranches_clientid ON clientbranches (clientid);

CREATE TABLE Period (
	PeriodID				serial primary key,
	salesperiod				varchar(50),
	AccountPeriod			varchar(12) not null,
	KQAccountPeriod			varchar(12),
	Startdate				date not null,
	enddate					date not null,
	InvoiceDate				date not null,
	CommissionRate			real default 0 not null,
	markup					float,
	IsActive				boolean not null default false,
	Approved				boolean not null default false,
	IsPicked				boolean not null default false,
	Details					text
);

ALTER TABLE period ALTER COLUMN accountperiod SET DEFAULT 0;
ALTER TABLE period ALTER COLUMN KQAccountPeriod SET DEFAULT 0;

CREATE TABLE management (
	managementid			serial primary key,
	clientbranchid			integer references clientbranches,
	PeriodID				integer references period,
	bookingID   			integer,
	agentReference          varchar(50), 
	creationDate            date, 
	departureDate           date, 
	leadName           		varchar(50), 
	wholesaleValue         	real,
	grossValue             	real, 
	currency           		varchar(50), 
	commission           	real, 
	subAgent           		varchar(50),
	externalrates			real,
	agentfee				real
);
CREATE INDEX management_clientbranchid ON management (clientbranchid);
CREATE INDEX management_PeriodID ON management (PeriodID);
CREATE INDEX management_bookingID ON management (bookingID);

CREATE TABLE sales (
	saleid					serial primary key,
	PeriodID				integer references period,
	bookingID   			integer, 
	agentReference  		varchar(100), 
	item   					varchar(25), 
	city   					varchar(120), 
	name   					varchar(120), 
	serviceDate     		date, 
	nights  				integer default 0, 
	totalPrice   			real, 
	netremits 				real,
	commission				real,

	nr_totalPrice  			real, 
	nr_netremits 			real,
	nr_commission			real,
	vat_rate				real default 0 not null,

	status   				varchar(100), 
	alternate   			varchar(25), 
	completed   			varchar(25), 
	requestedDate   		date, 
	requestedTime   		time, 
	nationality				varchar(50),
	creditnote				boolean default false not null,
	gkref					varchar(50),
	rmks   					text
);
CREATE INDEX sales_PeriodID ON sales (PeriodID);
CREATE INDEX sales_bookingID ON sales (bookingID);

CREATE TABLE netrates (
	netrateid				serial primary key,
	PeriodID				integer references period,
	bookingID   			integer, 
	gkref					varchar(50),
	agentReference  		varchar(100), 
	item   					varchar(25), 
	city   					varchar(120), 
	name   					varchar(120), 
	serviceDate     		date, 
	nights  				integer default 0, 
	totalPrice   			real, 
	netremits 				real,
	commission				real,
	status   				varchar(100), 
	alternate   			varchar(25), 
	completed   			varchar(25), 
	requestedDate   		date, 
	requestedTime   		time, 
	nationality				varchar(50),
	creditnote				boolean default false not null,
	Supplier_Deadline		varchar(50),
	rmks   					text
);
CREATE INDEX netrates_PeriodID ON netrates (PeriodID);
CREATE INDEX netrates_bookingID ON netrates (bookingID);

CREATE TABLE invoicelist (
	invoiceid				serial primary key,
	PeriodID				integer references period,
	clientid 				integer references clients,
	issued					boolean default false not null,
	ispicked				boolean default false
);
CREATE INDEX invoicelist_PeriodID ON invoicelist (PeriodID);
CREATE INDEX invoicelist_clientid ON invoicelist (clientid);

CREATE TABLE crnotelist (
	crnoteid				serial primary key,
	PeriodID				integer references period,
	clientid 				integer references clients,
	issued					boolean default false not null,
	ispicked				boolean default false
);
CREATE INDEX crnotelist_PeriodID ON crnotelist (PeriodID);
CREATE INDEX crnotelist_clientid ON crnotelist (clientid);

CREATE OR REPLACE VIEW vwclients AS 
	SELECT countrys.countryid, countrys.countryname, clients.clientid, clients.clientname, clients.address,
		clients.postalcode, clients.town, clients.telno, clients.contact_person, clients.email, clients.isactive,
		clients.ispicked, clients.mst_cus_id, clients.details
	FROM clients JOIN countrys ON clients.countryid = countrys.countryid;

CREATE VIEW vwclientbranches AS
	SELECT clients.clientid, clients.clientname, clients.address, clients.postalcode, clients.Town, clients.telno, clients.email,
		countrys.country_id, countrys.countryname, clientbranches.clientbranchid,  clientbranches.branchname, clientbranches.details
	FROM clientbranches LEFT JOIN (clients INNER JOIN countrys ON clients.country_id = countrys.country_id)
		ON clientbranches.clientid = clients.clientid;

CREATE VIEW vwmanagement AS
	SELECT vwclientbranches.clientid, vwclientbranches.clientname, vwclientbranches.clientbranchid, vwclientbranches.branchname, 
		vwclientbranches.address, vwclientbranches.postalcode, vwclientbranches.Town, vwclientbranches.country_id,
		vwclientbranches.countryname, vwclientbranches.telno, vwclientbranches.email, management.managementid,
		management.bookingid, management.agentreference, management.creationdate, management.departuredate, 
		management.leadname, management.wholesalevalue, management.grossvalue, management.PeriodID,
		management.currency, management.commission, management.subagent
	FROM management INNER JOIN vwclientbranches ON management.clientbranchid = vwclientbranches.clientbranchid;

CREATE VIEW vwsales AS
	SELECT vwmanagement.clientid, vwmanagement.clientname, vwmanagement.clientbranchid, vwmanagement.branchname, vwmanagement.address, vwmanagement.postalcode,
		vwmanagement.managementid, vwmanagement.town, vwmanagement.country_id, vwmanagement.countryname, vwmanagement.telno, vwmanagement.email,  
		vwmanagement.creationdate, vwmanagement.departuredate, vwmanagement.leadname, vwmanagement.wholesalevalue, vwmanagement.grossvalue, 
		vwmanagement.currency, vwmanagement.subagent,
		sales.saleid, sales.bookingID, sales.agentReference, sales.item,sales.city,sales.name,sales.serviceDate,sales.nights, sales.totalPrice, sales.commission, 
		sales.netremits, sales.creditnote, sales.status, sales.alternate, sales.completed, sales.requestedDate,sales.requestedTime,sales.nationality,sales.rmks, sales.periodid,
		sales.gkref, (sales.totalprice - sales.commission) as amount, 
		(sales.totalprice - sales.netremits - sales.commission) as grossearning,
		gtarevenue.serviceid, gtarevenue.servicename, gtarevenue.basis, gtarevenue.gkpercentage, 
		gtarevenue.tacommissionout, gtarevenue.sharedndccommission, gtarevenue.otherndccommission, gtarevenue.gk,
		
		(CASE WHEN gtarevenue.commisionable = false THEN (sales.netremits * gtarevenue.gkpercentage / 100)
		ELSE (sales.totalprice * gtarevenue.gkpercentage / 100) END) as gkpercent, 
		
		(CASE WHEN gtarevenue.commisionable = false THEN (sales.netremits * gtarevenue.tacommissionout / 100) 
		ELSE (sales.totalprice * gtarevenue.tacommissionout / 100) END) as tacommission, 
		
		(CASE WHEN gtarevenue.commisionable = false THEN (sales.netremits * gtarevenue.sharedndccommission / 100) 
		ELSE (sales.totalprice * gtarevenue.sharedndccommission / 100) END) as sharedcommission, 
		
		(CASE WHEN gtarevenue.commisionable = false THEN (sales.netremits * gtarevenue.otherndccommission / 100) 
		ELSE (sales.totalprice * gtarevenue.otherndccommission / 100) END) as otherndc, 
		
		(CASE WHEN gtarevenue.commisionable = false THEN (sales.netremits * gtarevenue.gk / 100)
		ELSE (sales.totalprice * gtarevenue.gk / 100) END) as galileoearning,
		
		sales.vat_rate, 	
		((CASE WHEN gtarevenue.commisionable = false THEN (sales.netremits * (gtarevenue.sharedndccommission + gtarevenue.tacommissionout) / 100) 
		ELSE (sales.totalprice * (gtarevenue.sharedndccommission + gtarevenue.tacommissionout) / 100) END) * sales.vat_rate / 100) as galileo_vat,

		
		('GT/INVC' || CAST(vwmanagement.clientid as varchar) || Period.AccountPeriod ) as clinvnumber,
		Period.Startdate, Period.enddate, Period.AccountPeriod, Period.InvoiceDate, (Period.InvoiceDate + 30) as duedate,
		invoicelist.invoiceid, invoicelist.issued, ('TP/GTA/INV/' || invoicelist.invoiceid) as invoicenumber,
		invoicelist.ispicked
	FROM (((sales INNER JOIN gtarevenue ON sales.item = gtarevenue.serviceid)
		INNER JOIN Period ON sales.periodid = Period.PeriodID)
		LEFT JOIN vwmanagement ON sales.bookingID = vwmanagement.bookingID)
		LEFT JOIN invoicelist ON (vwmanagement.clientid = invoicelist.clientid) AND (sales.periodid = invoicelist.periodid);
		

CREATE VIEW vwinvoice AS
	SELECT 	vwsales.clientid, vwsales.clientname,  vwsales.clientbranchid, vwsales.branchname, vwsales.address,
		vwsales.periodid, vwsales.Startdate, vwsales.postalcode, vwsales.town, vwsales.country_id, vwsales.countryname,
		vwsales.bookingid, vwsales.agentreference, vwsales.item, vwsales.servicedate, vwsales.city, vwsales.name, 
		vwsales.nights, vwsales.commission, vwsales.netremits, vwsales.totalprice, vwsales.amount, vwsales.creditnote, 
		vwsales.grossearning, vwsales.InvoiceDate, vwsales.duedate, vwsales.invoicenumber, vwsales.invoiceid, vwsales.issued,
		vwsales.gkref, vwsales.ispicked, vwsales.vat_rate, vwsales.galileo_vat
	FROM vwsales
	WHERE (lower(trim(vwsales.status)) = 'confirmed');

CREATE VIEW clientstatement AS
	SELECT vwinvoice.clientid, vwinvoice.clientname, vwinvoice.periodid, vwinvoice.invoicenumber, vwinvoice.invoicedate, 
		vwinvoice.netremits, vwinvoice.grossearning, vwinvoice.vat_rate, vwinvoice.galileo_vat
	FROM vwinvoice;

CREATE VIEW vwinvoicelist AS 
	SELECT vwsales.clientid, vwsales.clientname, vwsales.town, vwsales.countryid, vwsales.countryname, vwsales.periodid,
		vwsales.invoiceid, vwsales.issued, period.salesperiod, period.invoicedate, 
		sum(vwsales.amount) as invoice_amount, sum(vwsales.netremits) as gta_totals
	FROM vwsales INNER JOIN period ON period.periodid = vwsales.periodid
	WHERE vwsales.clientid IS NOT NULL AND vwsales.totalprice > 0::double precision
	GROUP BY vwsales.clientid, vwsales.clientname, vwsales.town, vwsales.countryid, vwsales.countryname, vwsales.periodid, 
		period.invoicedate, period.salesperiod, vwsales.invoiceid, vwsales.issued
	ORDER BY vwsales.clientid;

CREATE VIEW vwcrnotelist AS 
	SELECT vwsales.clientid, vwsales.clientname, vwsales.periodid, crnotelist.crnoteid,
		period.salesperiod, period.invoicedate,
		sum(vwsales.amount) as invoice_amount, sum(vwsales.netremits) as gta_totals
	FROM vwsales LEFT JOIN crnotelist ON vwsales.periodid = crnotelist.periodid AND vwsales.clientid = crnotelist.clientid
		INNER JOIN period ON period.periodid = vwsales.periodid
	WHERE vwsales.clientid IS NOT NULL AND vwsales.totalprice < 0::double precision AND to_char(vwsales.startdate::timestamp with time zone, 'MMYYYY'::text) <> to_char(vwsales.servicedate::timestamp with time zone, 'MMYYYY'::text)
	GROUP BY vwsales.clientid, vwsales.clientname, vwsales.periodid, crnotelist.crnoteid, period.salesperiod, period.invoicedate
	ORDER BY vwsales.clientid;

CREATE VIEW vwinvoicesummary AS 
	SELECT 	vwsales.clientid, vwsales.clientname, vwsales.InvoiceDate, vwsales.invoiceid, vwsales.invoicenumber,
		vwsales.Startdate, vwsales.periodid, vwsales.ispicked, sum(vwsales.amount) as invoiceamount,
		sum(vwsales.netremits) as gtatotals
	FROM vwsales
	WHERE ((lower(trim(vwsales.status)) = 'confirmed') AND ((totalprice > 0) OR (to_char(StartDate, 'MMYYYY') = to_char(servicedate, 'MMYYYY'))))
	GROUP BY vwsales.clientid, vwsales.clientname, vwsales.InvoiceDate, vwsales.invoiceid, vwsales.invoicenumber, 
		vwsales.Startdate, vwsales.periodid, vwsales.ispicked;

CREATE VIEW vwcrnotesummary AS 
	SELECT 	vwsales.clientid, vwsales.clientname, vwsales.InvoiceDate, vwsales.periodid,
		crnotelist.crnoteid, ('TP/GTA/CR/' || crnotelist.crnoteid) as creditnotenumber, crnotelist.ispicked, 
		vwsales.Startdate, sum(vwsales.amount) as invoiceamount,
		sum(vwsales.netremits) as gtatotals
	FROM vwsales LEFT JOIN crnotelist ON
		(vwsales.PeriodID = crnotelist.PeriodID) AND (vwsales.clientid = crnotelist.clientid)
	WHERE (lower(trim(vwsales.status)) = 'confirmed') 
		AND (vwsales.totalprice < 0) AND (to_char(vwsales.StartDate, 'MMYYYY') <> to_char(vwsales.servicedate, 'MMYYYY'))
	GROUP BY vwsales.clientid, vwsales.clientname, vwsales.InvoiceDate, vwsales.periodid,
		crnotelist.crnoteid, ('TP/GTA/CR/' || crnotelist.crnoteid), crnotelist.ispicked, vwsales.Startdate;

CREATE OR REPLACE FUNCTION updExport(char(1)) RETURNS varchar(50) AS $$
BEGIN
	IF ($1 = '1') THEN
		UPDATE clients SET ispicked = true WHERE ispicked = false;
	END IF;

	IF ($1 = '2') THEN
		UPDATE invoicelist SET ispicked = true WHERE ispicked = false;
	END IF;

	IF ($1 = '3') THEN
		UPDATE crnotelist SET ispicked = true WHERE ispicked = false;
	END IF;

	RETURN 'Done';
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION insmanagement(varchar(50), varchar(50)) RETURNS varchar(120) AS $$
DECLARE
	myrec RECORD;
BEGIN
	DELETE FROM tmpmanagement WHERE lower(booking) IN ('booking id', 'booking');
	DELETE FROM tmpmanagement WHERE SubAgent is null;

	INSERT INTO clientbranches (branchname)
	(SELECT upper(trim(SubAgent))
	FROM tmpmanagement
	GROUP BY upper(trim(SubAgent)))
	EXCEPT
	(SELECT upper(trim(branchname))
	FROM clientbranches);

	SELECT INTO myrec max(PeriodID) as defperiodid FROM Period WHERE (IsActive = true) AND (Approved = false);

	INSERT INTO management(clientbranchid, bookingid, AgentReference,CreationDate, DepartureDate, 
		LeadName, WholesaleValue, GrossValue,Currency,Commission, SubAgent, PeriodID)
	SELECT clientbranches.clientbranchid, cast((booking::double precision) as int), AgentReference, 
		CAST('1899-12-30' as date) + cast(CAST(CreationDate as real) as int),
		CAST('1899-12-30' as date) + cast(CAST(DepartureDate as real) as int),
		LeadName, to_number(WholesaleValue, 'FM999G999G999.99'), to_number(GrossValue, 'FM999G999G999.99'), 
		Currency, to_number(Commission, 'FM999G999G999.99'), SubAgent,
		myrec.defperiodid
	FROM tmpmanagement INNER JOIN clientbranches ON upper(trim(tmpmanagement.SubAgent)) = upper(trim(clientbranches.branchname))
	WHERE (clientbranches.IsActive = true);

	UPDATE management SET Commission = 0 WHERE Commission is null;

	DELETE FROM tmpmanagement;

	RETURN 'Done';
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION insSales(varchar(50), varchar(50)) RETURNS varchar(50) AS $$
DECLARE
	myrec RECORD;
BEGIN

	DELETE FROM tmpsales WHERE lower(bookingid) IN ('booking id', 'booking');

	SELECT INTO myrec max(PeriodID) as defperiodid 
	FROM Period WHERE (IsActive = true) AND (Approved = false);

	INSERT INTO sales (bookingid, AgentReference, item, city, name, ServiceDate, nights, status, alternate, rmks,
			completed, RequestedDate, RequestedTime, nationality, totalprice, netremits, gkref, periodid, commission, vat_rate) 
	SELECT cast((bookingid::double precision) as int), AgentReference, trim(upper(replace(tmpsales.item, ' ', ''))), city, name, 
			CAST('1899-12-30' as date) + cast(CAST(ServiceDate as real) as int),
			cast(Cast(nights as real) as int), status, alternate, rmks, completed, 
			CAST('1899-12-30' as date) + cast(CAST(RequestedDate as real) as int),
			Cast(RequestedTime as real) * interval '1 day', nationality, 
			to_number(replace(TotalPrice, ' USD', ''), 'FM999G999G999.99'), 
			(CASE WHEN gtarevenue.commisionable = false THEN
				to_number(replace(TotalPrice, ' USD', ''), 'FM999G999G999.99') / (1 + gtarevenue.gkpercentage/100)
				ELSE to_number(replace(TotalPrice, ' USD', ''), 'FM999G999G999.99') * (1 - gtarevenue.gkpercentage/100) END),
			gkref, myrec.defperiodid,
			(CASE WHEN gtarevenue.commisionable = false THEN 
				(TAcommissionout /100) * to_number(replace(TotalPrice, ' USD', ''), 'FM999G999G999.99') / (1 + gkpercentage/100)
				ELSE (TAcommissionout /100) * to_number(replace(TotalPrice, ' USD', ''), 'FM999G999G999.99') END), 16
	FROM tmpsales INNER JOIN gtarevenue ON trim(upper(replace(tmpsales.item, ' ', ''))) = trim(upper(gtarevenue.serviceid));
	
	DELETE FROM tmpsales;

	RETURN 'Done';
END
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION insNetRates(varchar(50), varchar(50)) RETURNS varchar(50) AS $$
DECLARE
	myrec RECORD;
BEGIN

	DELETE FROM tmpnetrates WHERE lower(bookingid)  IN ('booking id', 'booking');

	SELECT INTO myrec max(PeriodID) as defperiodid FROM Period WHERE (IsActive = true) AND (Approved = false);

	INSERT INTO netrates (gkref, bookingid, AgentReference, item, city, name, ServiceDate, nights, status, alternate, rmks,
			completed, RequestedDate, RequestedTime, nationality, totalprice, netremits, Supplier_Deadline, periodid, commission)  
	SELECT gkref, cast((bookingid::double precision) as int), AgentReference, trim(upper(replace(tmpnetrates.item, ' ', ''))), city, name, 
			CAST('1899-12-30' as date) + cast(CAST(ServiceDate as real) as int),
			cast(Cast(nights as real) as int), status, alternate, rmks, completed, 
			CAST('1899-12-30' as date) + cast(CAST(RequestedDate as real) as int),
			Cast(RequestedTime as real) * interval '1 day', nationality, 
			(CASE WHEN gtarevenue.commisionable = false THEN
				to_number(replace(TotalPrice, ' USD', ''), 'FM999G999G999.99')
				ELSE to_number(replace(TotalPrice, ' USD', ''), 'FM999G999G999.99') * (1 - gtarevenue.gkpercentage/100) END),
			(CASE WHEN gtarevenue.commisionable = false THEN
				to_number(replace(TotalPrice, ' USD', ''), 'FM999G999G999.99')
				ELSE to_number(replace(TotalPrice, ' USD', ''), 'FM999G999G999.99') * (1 - gtarevenue.gkpercentage/100) END),
			CAST('1899-12-30' as date) +  cast(CAST(Supplier_Deadline as real) as int), myrec.defperiodid,
			(CASE WHEN gtarevenue.commisionable = false THEN 
				(TAcommissionout /100) * to_number(replace(TotalPrice, ' USD', ''), 'FM999G999G999.99') / (1 + gkpercentage/100)
				ELSE (TAcommissionout /100) * to_number(replace(TotalPrice, ' USD', ''), 'FM999G999G999.99') END)
	FROM tmpnetrates INNER JOIN gtarevenue ON trim(upper(replace(tmpnetrates.item, ' ', ''))) = trim(upper(gtarevenue.serviceid));

	DELETE FROM tmpnetrates;

	UPDATE sales SET nr_totalPrice = netrates.totalPrice, nr_netremits = netrates.netremits, nr_commission = netrates.commission
	FROM netrates WHERE
	(netrates.bookingid = sales.bookingid) AND (netrates.servicedate = sales.servicedate) AND
	(netrates.item = sales.item) AND (sales.nr_totalPrice is null) AND
	(netrates.requestedDate = sales.requestedDate) AND (netrates.requestedTime = sales.requestedTime) AND
	(netrates.gkref = sales.gkref);

	UPDATE sales SET netremits = nr_totalPrice
	WHERE (nr_totalPrice is not null)
	AND (nr_totalPrice <> netremits);

	RETURN 'Done';
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION updPeriod() RETURNS trigger AS $$
BEGIN
	IF(NEW.Approved = true) THEN
		INSERT INTO invoicelist(clientid, periodid)
		SELECT clientid, periodid
		FROM vwinvoicelist
		WHERE (invoiceid is null);

		INSERT INTO crnotelist(clientid, periodid)
		SELECT clientid, periodid
		FROM vwcrnotelist
		WHERE (crnoteid is null);
	END IF;

	RETURN null;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER updPeriod AFTER UPDATE ON Period
    FOR EACH ROW EXECUTE PROCEDURE updPeriod();
    
CREATE OR REPLACE FUNCTION ins_period() RETURNS trigger AS $$
	BEGIN
		IF(NEW.salesperiod is not null)THEN
			NEW.accountperiod := NEW.salesperiod;
			NEW.kqaccountperiod := NEW.salesperiod;
		END IF;

		RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_period BEFORE INSERT OR UPDATE ON period
    FOR EACH ROW EXECUTE PROCEDURE ins_period();

CREATE OR REPLACE FUNCTION del_period(varchar(16), varchar(16), varchar(16)) RETURNS varchar(50) AS $$
DECLARE
	mystr varchar(50);
BEGIN

	mystr := del_period(CAST($1 as integer));

	RETURN mystr;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION del_period(integer) RETURNS varchar(50) AS $$
DECLARE
	myrec RECORD;
BEGIN
	SELECT Approved INTO myrec
	FROM Period WHERE PeriodID = $1;

	IF (myrec.Approved = false) THEN
		DELETE FROM netrates WHERE periodid = $1;
		DELETE FROM crnotelist WHERE periodid = $1;
		DELETE FROM invoicelist WHERE periodid = $1;
		DELETE FROM management WHERE periodid = $1;
		DELETE FROM sales WHERE periodid = $1;
		DELETE FROM netrates WHERE periodid = $1;

		DELETE FROM management WHERE periodid is null;
		DELETE FROM sales WHERE periodid is null;
		DELETE FROM netrates WHERE periodid is null;
		
		DELETE FROM tmpnetrates;
		DELETE FROM tmpmanagement;
		DELETE FROM tmpsales;
	END IF;

	RETURN 'Done';
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION upd_clientbranches() RETURNS trigger AS $$
BEGIN
	IF(OLD.clientid <> NEW.clientid) THEN
		RAISE EXCEPTION 'Change of client is not allowed.';
	END IF;

	RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER upd_clientbranches BEFORE UPDATE ON clientbranches
    FOR EACH ROW EXECUTE PROCEDURE upd_clientbranches();

    
CREATE OR REPLACE FUNCTION approve_period(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	v_approved			boolean;
	msg 				varchar(120);
BEGIN
	msg := 'No Action';
	
	IF ($3 = '1') THEN
		UPDATE period SET approved = 'true'
		WHERE (periodid = $1::integer);
		
		msg := 'Period Approved';
	ELSIF ($3 = '2') THEN
		SELECT approved INTO v_approved
		FROM period
		WHERE (periodid = $1::integer);
		
		IF(v_approved = true) THEN
			INSERT INTO sys_emailed (sys_email_id, table_id, org_id, table_name, email_type)
			SELECT 1, invoiceid, 0, 'invoicelist', 1
			FROM invoicelist
			WHERE (periodid = $1::integer);
			
			INSERT INTO sys_emailed (sys_email_id, table_id, org_id, table_name, email_type)
			SELECT 2, crnoteid, 0, 'crnotelist', 2
			FROM crnotelist  
			WHERE (periodid = $1::integer);
			
			msg := 'Email Sent';
		ELSE
			msg := 'Approve the month first';
		END IF;
	END IF;
	
	return msg;
END;
$$ LANGUAGE plpgsql;


INSERT INTO gtarevenue (gtarevenueid, ndcname, serviceid, servicename, basis, gkpercentage, tacommissionout, sharedndccommission, otherndccommission, gk, details, totalcommissionearned) VALUES (1, 'kenya', 'AP', 'APARTMENT', 'NET', 15, 0, 15, 6, 9, '	', 9);
INSERT INTO gtarevenue (gtarevenueid, ndcname, serviceid, servicename, basis, gkpercentage, tacommissionout, sharedndccommission, otherndccommission, gk, details, totalcommissionearned) VALUES (2, 'Tanzania', 'HH', 'HOTEL', 'NET', 10, 0, 10, 4, 6, NULL, 6);
INSERT INTO gtarevenue (gtarevenueid, ndcname, serviceid, servicename, basis, gkpercentage, tacommissionout, sharedndccommission, otherndccommission, gk, details, totalcommissionearned) VALUES (8, 'Uganda', 'AM', 'AMENDMENT', NULL, 0, 0, 0, 0, 0, '							', 0);
INSERT INTO gtarevenue (gtarevenueid, ndcname, serviceid, servicename, basis, gkpercentage, tacommissionout, sharedndccommission, otherndccommission, gk, details, totalcommissionearned) VALUES (7, 'Rwanda', 'RL', 'RAIL', 'COMMISSION', 9, 5, 4, 1.6, 2.4000001, NULL, 2.4000001);
INSERT INTO gtarevenue (gtarevenueid, ndcname, serviceid, servicename, basis, gkpercentage, tacommissionout, sharedndccommission, otherndccommission, gk, details, totalcommissionearned) VALUES (6, 'Kenya', 'RS', 'REGULARS SIGHTSEEING', 'COMMISSION', 15, 7.5, 7.5, 3, 4.5, 'SCHEDULED SIGHTSEEING', 4.5);
INSERT INTO gtarevenue (gtarevenueid, ndcname, serviceid, servicename, basis, gkpercentage, tacommissionout, sharedndccommission, otherndccommission, gk, details, totalcommissionearned) VALUES (5, 'Uganda', 'VH', 'CAR HIRE', 'COMMISSION', 15, 7.5, 7.5, 3, 4.5, NULL, 9);
INSERT INTO gtarevenue (gtarevenueid, ndcname, serviceid, servicename, basis, gkpercentage, tacommissionout, sharedndccommission, otherndccommission, gk, details, totalcommissionearned) VALUES (3, 'Kenya', 'TN', 'PRIVATE TRANSFERS', 'NET', 15, 0, 15, 6, 9, NULL, 9);
INSERT INTO gtarevenue (gtarevenueid, ndcname, serviceid, servicename, basis, gkpercentage, tacommissionout, sharedndccommission, otherndccommission, gk, details, totalcommissionearned) VALUES (4, 'Kenya', 'PAC', 'PACKAGE', 'NET', 10, 0, 10, 4, 6, NULL, 6);

SELECT pg_catalog.setval('gtarevenue_gtarevenueid_seq', 8, true);

INSERT INTO clients (clientid, clientname, address, postalcode, town, country_id, telno, email, details) VALUES (4, 'Travelshoppe', NULL, NULL, 'Nairobi', 'KE', NULL, NULL, NULL);
INSERT INTO clients (clientid, clientname, address, postalcode, town, country_id, telno, email, details) VALUES (1, 'Acharya Tours and Travel ', NULL, NULL, 'Nairobi', 'KE', NULL, NULL, NULL);
INSERT INTO clients (clientid, clientname, address, postalcode, town, country_id, telno, email, details) VALUES (3, 'Bunson Travel', NULL, NULL, 'Nairobi', 'KE', NULL, NULL, NULL);
INSERT INTO clients (clientid, clientname, address, postalcode, town, country_id, telno, email, details) VALUES (5, 'Uniglobe Fleet', NULL, NULL, 'Nairobi', 'KE', NULL, NULL, NULL);
INSERT INTO clients (clientid, clientname, address, postalcode, town, country_id, telno, email, details) VALUES (6, 'Uniglobe Let''s Go', NULL, NULL, 'Nairobi', 'KE', NULL, NULL, NULL);
INSERT INTO clients (clientid, clientname, address, postalcode, town, country_id, telno, email, details) VALUES (7, 'BCD Travel', NULL, NULL, 'Nairobi', 'KE', NULL, NULL, NULL);
INSERT INTO clients (clientid, clientname, address, postalcode, town, country_id, telno, email, details) VALUES (8, 'Express Travel', NULL, NULL, 'Nairobi', 'KE', NULL, NULL, NULL);
INSERT INTO clients (clientid, clientname, address, postalcode, town, country_id, telno, email, details) VALUES (9, 'HRG BON VOYAGE TRAVEL - TANZANIA', NULL, NULL, NULL, 'TZ', NULL, NULL, NULL);
INSERT INTO clients (clientid, clientname, address, postalcode, town, country_id, telno, email, details) VALUES (10, 'Travel Affairs', NULL, NULL, 'Nairobi', 'KE', NULL, NULL, NULL);
INSERT INTO clients (clientid, clientname, address, postalcode, town, country_id, telno, email, details) VALUES (11, 'Uniglobe Antelope', NULL, NULL, 'Nairobi', 'KE', NULL, NULL, NULL);
INSERT INTO clients (clientid, clientname, address, postalcode, town, country_id, telno, email, details) VALUES (12, 'Uniglobe Silverbird', NULL, NULL, 'Nairobi', 'KE', NULL, NULL, NULL);
INSERT INTO clients (clientid, clientname, address, postalcode, town, country_id, telno, email, details) VALUES (13, 'Uniglobe Charleston', NULL, NULL, 'Nairobi', 'KE', NULL, NULL, NULL);

SELECT pg_catalog.setval('clients_clientid_seq', 14, true);

INSERT INTO clientbranches (clientbranchid, clientid, branchname, details) VALUES (4, 1, 'ACHARYA TRAVEL - TOWN OFFICE', NULL);
INSERT INTO clientbranches (clientbranchid, clientid, branchname, details) VALUES (5, 7, 'BCD TRAVEL HEAD OFFICE', NULL);
INSERT INTO clientbranches (clientbranchid, clientid, branchname, details) VALUES (6, 3, 'BUNSON HEAD OFFICE', NULL);
INSERT INTO clientbranches (clientbranchid, clientid, branchname, details) VALUES (7, 8, 'EXPRESS TRAVEL UNON', NULL);
INSERT INTO clientbranches (clientbranchid, clientid, branchname, details) VALUES (8, 8, 'EXPRESS TRAVEL US EMBASSY', NULL);
INSERT INTO clientbranches (clientbranchid, clientid, branchname, details) VALUES (9, 9, 'HRG BON VOYAGE TRAVEL HEAD OFFICE - TANZANIA', NULL);
INSERT INTO clientbranches (clientbranchid, clientid, branchname, details) VALUES (10, 10, 'TRAVEL AFFAIRS LIMITED', NULL);
INSERT INTO clientbranches (clientbranchid, clientid, branchname, details) VALUES (11, 4, 'TRAVELSHOPPE', NULL);
INSERT INTO clientbranches (clientbranchid, clientid, branchname, details) VALUES (12, 11, 'UNIGLOBE ANTELOPE TOURS AND TRAVEL-TANZANIA', NULL);
INSERT INTO clientbranches (clientbranchid, clientid, branchname, details) VALUES (13, 13, 'UNIGLOBE CHARLESTON TRAVEL HEADOFFICE', NULL);
INSERT INTO clientbranches (clientbranchid, clientid, branchname, details) VALUES (14, 5, 'UNIGLOBE FLEET TRAVEL TOWN', NULL);
INSERT INTO clientbranches (clientbranchid, clientid, branchname, details) VALUES (15, 6, 'UNIGLOBE LET''S GO TRAVEL - ABC', NULL);
INSERT INTO clientbranches (clientbranchid, clientid, branchname, details) VALUES (16, 6, 'UNIGLOBE LETS GO TRAVEL KAREN CONNECTION', NULL);
INSERT INTO clientbranches (clientbranchid, clientid, branchname, details) VALUES (17, 12, 'UNIGLOBE SILVERBIRD TRAVEL PLUS LTD', NULL);
INSERT INTO clientbranches (clientbranchid, clientid, branchname, details) VALUES (18, 1, 'ACHARYA TRAVEL- RAHIMTULLA', NULL);

SELECT pg_catalog.setval('clientbranches_clientbranchid_seq', 18, true);


DROP VIEW vwinvoicelist CASCADE;

CREATE OR REPLACE VIEW vwinvoicelist AS 
 SELECT vwsales.clientid,
    vwsales.clientname,
    vwsales.town,
    vwsales.countryid,
    vwsales.countryname,
    vwsales.periodid,
    vwsales.invoiceid,
    vwsales.invoicenumber,
    vwsales.issued,
    period.salesperiod,
    period.invoicedate,
    sum(vwsales.amount) AS invoice_amount,
    sum(vwsales.netremits) AS gta_totals
   FROM vwsales
     JOIN period ON period.periodid = vwsales.periodid
  WHERE vwsales.clientid IS NOT NULL AND vwsales.totalprice > 0::double precision
  GROUP BY vwsales.clientid, vwsales.clientname, vwsales.town, vwsales.countryid, vwsales.countryname, vwsales.periodid, period.invoicedate, period.salesperiod, vwsales.invoiceid, vwsales.invoicenumber, vwsales.issued
  ORDER BY vwsales.clientid;

DROP VIEW vwcrnotelist;

CREATE OR REPLACE VIEW vwcrnotelist AS 
 SELECT vwsales.clientid,
    vwsales.clientname,
    vwsales.periodid,
    crnotelist.crnoteid,
    ('TP/GTA/CR/' || crnotelist.crnoteid) as creditnotenumber,
    period.salesperiod,
    period.invoicedate,
    sum(vwsales.amount) AS invoice_amount,
    sum(vwsales.netremits) AS gta_totals
    
   FROM vwsales INNER JOIN period ON period.periodid = vwsales.periodid
     LEFT JOIN crnotelist ON vwsales.periodid = crnotelist.periodid AND vwsales.clientid = crnotelist.clientid     

  WHERE vwsales.clientid IS NOT NULL AND vwsales.totalprice < 0::double precision AND to_char(vwsales.startdate::timestamp with time zone, 'MMYYYY'::text) <> to_char(vwsales.servicedate::timestamp with time zone, 'MMYYYY'::text)
  
  GROUP BY vwsales.clientid, vwsales.clientname, vwsales.periodid, crnotelist.crnoteid, period.salesperiod, period.invoicedate
  ORDER BY vwsales.clientid;

CREATE OR REPLACE FUNCTION get_start_year(varchar(12)) RETURNS varchar(12) AS $$
	SELECT '01/01/' || to_char(current_date, 'YYYY'); 
$$ LANGUAGE SQL;

ALTER TABLE clients ADD COLUMN mst_cus_id varchar(10);

DROP TABLE tmpclientpayments;
CREATE TABLE tmpclientpayments (
	clientpaymentsid		serial primary key,
	category				varchar(250),
	currency				varchar(16),
	accounting_date			varchar(16),
	company					varchar(250),
	location				varchar(250),
	cost_center				varchar(250),
	account					varchar(250),
	bud						varchar(250),
	intercompany			varchar(250),
	debit					varchar(250),
	credit					varchar(250),
	conversion_type			varchar(16),
	conversiondate			varchar(16),
	conversion_rate			varchar(250),
	journal_name			varchar(250),
	journal_description		varchar(250),
	reverse_journal			varchar(250),
	reversal_period			varchar(250),
	line_description		varchar(250),
	messages				varchar(250),
	mst_cus_id				varchar(10)
);


DROP TABLE clientpayments CASCADE;
CREATE TABLE clientpayments (
	clientpaymentsid		serial primary key,
	clientid 				integer references clients,
	accounting_date			date,
	currency				varchar(50),
	amount					real,
	payment_type			varchar(250),
	payment_reference		varchar(250),
	journal_name			varchar(250),
	created					timestamp default current_timestamp not null
);
CREATE INDEX clientpayments_clientid ON clientpayments (clientid);


CREATE OR REPLACE FUNCTION inspayments(
    character varying,
    character varying,
    character varying)
  RETURNS character varying AS
$BODY$
DECLARE
	myrec RECORD;
BEGIN 
	DELETE FROM tmpclientpayments WHERE tmpclientpayments.Accounting_Date = 'Accounting Date';
	
	INSERT INTO clientpayments(clientid, accounting_date, currency, amount, journal_name,
		payment_reference, payment_type)
	SELECT clients.clientid, ('1899-12-30'::date + Accounting_Date::int), currency, credit::real, 
		trim(journal_name), trim(split_part(line_description, ':', 1)), trim(split_part(line_description, ':', 2))
		
	FROM tmpclientpayments 
	INNER JOIN clients ON tmpclientpayments.mst_cus_id = clients.mst_cus_id;

	DELETE FROM tmpclientpayments WHERE mst_cus_id  IN
	(SELECT DISTINCT mst_cus_id FROM clients); 

	RETURN 'Done';
END
$BODY$
  LANGUAGE plpgsql;

CREATE OR REPLACE VIEW vw_clientpayments AS 
 SELECT clients.clientid,
    clients.clientname,
    clientpayments.clientpaymentsid,
    clientpayments.currency,
    clientpayments.amount,
	clientpayments.accounting_date,
    'TP/GTA/PAY/'::text || clientpayments.clientpaymentsid AS clientpaymentsnumber,
    clientpayments.payment_reference,
    clientpayments.payment_type,
    clientpayments.journal_name
   FROM clientpayments
     JOIN clients ON clientpayments.clientid = clients.clientid;

CREATE OR REPLACE VIEW vw_statement AS
	SELECT item_name, clientid, clientname, salesperiod, invoicedate, invoicenumber, invoiced, credit_amount, payments, amount
	FROM 
		((SELECT 'Invoice'::varchar(32) as item_name, clientid, clientname, salesperiod, invoicedate, invoicenumber, invoice_amount as invoiced , '0'::real as credit_amount, '0'::real as payments, invoice_amount::real as amount
		FROM vwinvoicelist)
		UNION ALL 
		(SELECT 'Credit Note'::varchar(32) as item_name, clientid, clientname, salesperiod, invoicedate, creditnotenumber, '0'::real, invoice_amount, '0'::real, invoice_amount::real as amount
		FROM vwcrnotelist)
		UNION ALL 
		(SELECT 'Payments'::varchar(32) as item_name, clientid, clientname, payment_reference, accounting_date, clientpaymentsnumber, '0'::real, '0'::real, amount, (-1 * amount)::real as amount
		FROM vw_clientpayments)) as a 
ORDER BY invoicedate ASC;

CREATE OR REPLACE VIEW vw_receipt AS
	SELECT vw_clientpayments.clientid, vwclients.clientname, accounting_date, clientpaymentsid, 
       currency, amount, clientpaymentsnumber, payment_reference, countryname, address, postalcode, town
	FROM vw_clientpayments 
	JOIN vwclients ON vw_clientpayments.clientid = vwclients.clientid;




