

-----------------  Changes

UPDATE clientpayments SET payment_type = trim(split_part(payment_reference, ':', 2)); 
UPDATE clientpayments SET payment_reference = trim(split_part(payment_reference, ':', 1)); 


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









-----------------------------
CREATE TABLE sys_menu_msg (
	sys_menu_msg_id			serial primary key,
	menu_id					varchar(16) not null,
	menu_name				varchar(50) not null,
	xml_file				varchar(50) not null,
	msg						text
);

DROP VIEW vwcrnotesummary;
DROP VIEW vwinvoicesummary;
DROP VIEW vwcrnotelist;
DROP VIEW vwinvoicelist;
DROP VIEW clientstatement;
DROP VIEW vwinvoice;
DROP VIEW vwsales;


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
	SELECT clientid, clientname, town, country_id, countryname, 
		periodid, invoiceid, issued
	FROM vwsales
	WHERE (clientid is not null) AND (totalprice > 0)
	GROUP BY clientid, clientname, town, country_id, countryname, 
		periodid, invoiceid, issued
	ORDER BY clientid;

CREATE VIEW vwcrnotelist AS
	SELECT vwsales.clientid, vwsales.periodid,crnotelist.crnoteid
	FROM vwsales LEFT JOIN crnotelist ON
		(vwsales.PeriodID = crnotelist.PeriodID) AND (vwsales.clientid = crnotelist.clientid)
	WHERE (vwsales.clientid is not null) AND (vwsales.totalprice < 0) AND (to_char(StartDate, 'MMYYYY') <> to_char(servicedate, 'MMYYYY'))
	GROUP BY vwsales.clientid, vwsales.periodid, crnotelist.crnoteid
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


CREATE OR REPLACE FUNCTION insSales(varchar(50), varchar(50)) RETURNS varchar(50) AS $$
DECLARE
	myrec RECORD;
BEGIN

	DELETE FROM tmpsales WHERE bookingid = 'Booking ID';

	SELECT INTO myrec max(PeriodID) as defperiodid 
	FROM Period WHERE (IsActive = true) AND (Approved = false);

	INSERT INTO sales (bookingid, AgentReference, item, city, name, ServiceDate, nights, status, alternate, rmks,
			completed, RequestedDate, RequestedTime, nationality, totalprice, netremits, gkref, periodid, commission, vat_rate) 
	SELECT cast(cast(bookingid as real) as int), AgentReference, trim(upper(replace(tmpsales.item, ' ', ''))), city, name, 
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


CREATE OR REPLACE FUNCTION email_invoice(
    integer,
    integer,
    character varying)
  RETURNS character varying AS
$BODY$
DECLARE
	msg		 				varchar(120);
BEGIN
	INSERT INTO sys_emailed (sys_email_id, table_id, org_id, table_name)
	VALUES (1, $1, 0, 'clients');
msg := 'Email Sent';
return msg;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE;



-- UPDATE clients SET contact_person=ut.substr FROM 
-- (SELECT clientid, substr(email, 1 , position('@' in email) - 1) from clients WHERE position('@' in email) > 0) as ut
-- WHERE ut.clientid= clients.clientid;
-- 
-- UPDATE clients SET contact_person=ut.cname FROM 
-- (SELECT clients.email, tmpmanes.email, clients.clientname, tmpmanes.aname, tmpmanes.cname
--  FROM tmpmanes 
-- LEFT JOIN clients on clients.clientname= tmpmanes.aname) as ut
-- WHERE ut.aname= clients.clientname; 

CREATE OR REPLACE FUNCTION get_start_year(varchar(12)) RETURNS varchar(12) AS $$
	SELECT '01/01/' || to_char(current_date, 'YYYY'); 
$$ LANGUAGE SQL;

DROP TABLE tmpclientpayments;
CREATE TABLE tmpclientpayments (
	clientpaymentsid		serial primary key,
	Category				varchar(250),
	Currency				varchar(16),
	Accounting_Date			varchar(16),
	Company					varchar(250),
	Location				varchar(250),
	Cost_Center				varchar(250),
	Account					varchar(250),
	BUD						varchar(250),
	Intercompany			varchar(250),
	Debit					varchar(250),
	Credit					varchar(250),
	Conversion_Type			varchar(16),
	ConversionDate			varchar(16),
	Conversion_Rate			varchar(250),
	Journal_Name			varchar(250),
	Journal_Description		varchar(250),
	Reverse_Journal			varchar(250),
	Reversal_Period			varchar(250),
	Line_Description		varchar(250),
	Messages				varchar(250),
	MST_CUS_ID				varchar(10)
);


DROP TABLE clientpayments CASCADE;
CREATE TABLE clientpayments (
	clientpaymentsid		serial primary key,
	clientid 				integer references clients,
	accounting_date			date,
	currency				varchar(50),
	amount					real,
	payment_type			varchar(250),
	payment_reference		varchar(250)
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
	INSERT INTO clientpayments(clientid, accounting_date, currency, amount, payment_reference)
	SELECT clients.clientid,('1899-12-30'::date + Accounting_Date::int) as accounting_date, currency, Credit::real, Line_Description
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
    clientpayments.payment_type
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
		(SELECT 'Payments'::varchar(32) as item_name, clientid, clientname, payment_type, accounting_date, clientpaymentsnumber, '0'::real, '0'::real, amount, (-1 * amount)::real as amount
		FROM vw_clientpayments)) as a 
ORDER BY invoicedate ASC;

CREATE OR REPLACE VIEW vw_receipt AS
	SELECT vw_clientpayments.clientid, vwclients.clientname, accounting_date, clientpaymentsid, 
       currency, amount, clientpaymentsnumber, payment_reference, countryname, address, postalcode, town
	FROM vw_clientpayments 
	JOIN vwclients ON vw_clientpayments.clientid = vwclients.clientid;


-- select to_char(sum(credit::real), '9,999,999,999,999')
-- from tmpclientpayments
-- INNER JOIN clients ON tmpclientpayments.mst_cus_id = clients.mst_cus_id;
-- 
-- SELECT tmpclientpayments.mst_cus_id
-- FROM tmpclientpayments LEFT JOIN clients ON tmpclientpayments.mst_cus_id = clients.mst_cus_id
-- WHERE clients.mst_cus_id is null
-- GROUP BY tmpclientpayments.mst_cus_id;
-- 
-- SELECT clients.clientid, clients.clientname, clients.mst_cus_id
-- FROM clients
-- WHERE clients.mst_cus_id IN
-- (SELECT clients.mst_cus_id
-- FROM clients
-- GROUP BY clients.mst_cus_id
-- HAVING count(clients.clientid) > 1)
-- AND clients.mst_cus_id is not null 
-- ORDER BY mst_cus_id;
	
	
-- CREATE OR REPLACE FUNCTION get_total_credit(integer) RETURNS real AS $$
-- SELECT SUM(amount) as Credit
--  FROM vwinvoice
--  WHERE (clientid = $1) AND  (vwinvoice.totalprice < 0) AND
--  (to_char(StartDate, 'MMYYYY') <> to_char(servicedate, 'MMYYYY'));
--   $$ LANGUAGE SQL;
-- 
-- CREATE OR REPLACE FUNCTION get_total_invoice(integer) RETURNS real AS $$
-- SELECT SUM(amount) as Invoice
--  FROM vwinvoice
--  WHERE (clientid = $1) AND ((totalprice > 0) OR (to_char(StartDate, 'MMYYYY') = to_char(servicedate, 'MMYYYY')));
--   $$ LANGUAGE SQL;
-- 
-- CREATE OR REPLACE FUNCTION get_total_Payments(integer) RETURNS real AS $$
-- SELECT SUM(amount) as Payments
--  FROM vw_clientpayments
--  WHERE  (clientid = $1);
--   $$ LANGUAGE SQL;
-- 
-- CREATE OR REPLACE VIEW vw_total_statements AS 
--  SELECT vwinvoice.clientid, vwinvoice.clientname,
-- 		get_total_credit(vwinvoice.clientid) AS Credit,
-- 		get_total_invoice(vwinvoice.clientid) AS Invoice,
-- 		get_total_Payments(vwinvoice.clientid) AS Payments
-- FROM vwinvoice;

-- CREATE OR REPLACE VIEW vw_statement AS
-- SELECT clientid, clientname, periodid, startdate, amount FROM 
-- ((SELECT clientid, clientname, periodid, startdate, amount FROM vwinvoice
-- 	WHERE creditnote = false AND (vwinvoice.totalprice < 0) AND
--         (to_char(StartDate, 'MMYYYY') <> to_char(servicedate, 'MMYYYY')))
--   UNION ALL 
--  (SELECT clientid, clientname, periodid, startdate, amount FROM vwinvoice
-- 	WHERE ((totalprice > 0) OR (to_char(StartDate, 'MMYYYY') = to_char(servicedate, 'MMYYYY'))))
--   UNION ALL 
--  (SELECT clientid, clientname, periodid, enddate, amount FROM vw_clientpayments)) as a ORDER BY startdate DESC;

DELETE FROM tmpclientpayments;
DELETE FROM clientpayments;


