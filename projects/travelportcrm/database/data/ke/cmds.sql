INSERT INTO assets(
            assetid, assetsn, purchasedate, purchasecost, lost, sold, saledate, saleamount, condition)
   SELECT asset_id, asset_serial, purchase_date,  purchase_value, lost, sold, disposal_date, disposal_amount, details 
   FROM i_assets ;


INSERT INTO clients(
            clientid, clientname, address, zipcode, premises, street, division, town, 
            country, telno, email, website, iatano, isactive, details)
      SELECT client_id, client_name, address, zipcode, premises, street, division, town, country_id,
      telno, email, website, iatano, is_active, details
      FROM i_clients;


INSERT INTO clientassets(clientid, crmrefno, dnoteno,
            clientassetid, assetid, isissued, dateissued, 
            isretrived, units, dateretrived, narrative, dateadded, datechanged)
   SELECT b.client_id, b.crm_ref, b.dnote_no, a.client_asset_id, a.asset_id, a.is_issued, a.date_issued, a.is_retrived, a.units, a.date_retrived, a.narrative, a.date_added, a.date_changed
       FROM i_client_assets a INNER JOIN i_client_requests b ON a.client_request_id = b.client_request_id;



INSERT INTO assettypes(
            assettypeid, assettypename, details)
    SELECT asset_type_id, asset_type_name, details
       FROM i_asset_types;


INSERT INTO clientlinks(
            clientlinkid, clientlinkname, details)
    SELECT client_link_id, link_number, details
       FROM i_client_links;
       
       
SELECT i_asset_types.asset_type_id, i_asset_types.asset_type_name,
	i_models.model_id,
	i_assets.asset_id, i_assets.asset_serial, i_assets.purchase_date
FROM i_asset_types INNER JOIN i_models ON i_asset_types.asset_type_id = i_models.asset_type_id 
	INNER JOIN i_assets ON i_models.model_id = i_assets.model_id;
	
UPDATE assets SET AssetSubTypeID = 1 WHERE purchasedate < '2014-01-01' and assetid IN
(SELECT i_assets.asset_id
FROM i_asset_types INNER JOIN i_models ON i_asset_types.asset_type_id = i_models.asset_type_id 
	INNER JOIN i_assets ON i_models.model_id = i_assets.model_id
WHERE i_asset_types.asset_type_id = 1);

UPDATE assets SET AssetSubTypeID = 2 WHERE assetid IN
(SELECT i_assets.asset_id
FROM i_asset_types INNER JOIN i_models ON i_asset_types.asset_type_id = i_models.asset_type_id 
	INNER JOIN i_assets ON i_models.model_id = i_assets.model_id
WHERE i_asset_types.asset_type_id = 1);

UPDATE assets SET AssetSubTypeID = 3 WHERE purchasedate < '2014-01-01' and assetid IN
(SELECT i_assets.asset_id
FROM i_asset_types INNER JOIN i_models ON i_asset_types.asset_type_id = i_models.asset_type_id 
	INNER JOIN i_assets ON i_models.model_id = i_assets.model_id
WHERE i_asset_types.asset_type_id = 3);

UPDATE assets SET AssetSubTypeID = 4 WHERE assetid IN
(SELECT i_assets.asset_id
FROM i_asset_types INNER JOIN i_models ON i_asset_types.asset_type_id = i_models.asset_type_id 
	INNER JOIN i_assets ON i_models.model_id = i_assets.model_id
WHERE i_asset_types.asset_type_id = 3);

UPDATE assets SET AssetSubTypeID = 5 WHERE assetid IN
(SELECT i_assets.asset_id
FROM i_asset_types INNER JOIN i_models ON i_asset_types.asset_type_id = i_models.asset_type_id 
	INNER JOIN i_assets ON i_models.model_id = i_assets.model_id
WHERE i_asset_types.asset_type_id = 4);

UPDATE assets SET AssetSubTypeID = 6 WHERE assetid IN
(SELECT i_assets.asset_id
FROM i_asset_types INNER JOIN i_models ON i_asset_types.asset_type_id = i_models.asset_type_id 
	INNER JOIN i_assets ON i_models.model_id = i_assets.model_id
WHERE i_asset_types.asset_type_id = 5);

UPDATE assets SET AssetSubTypeID = 7 WHERE assetid IN
(SELECT i_assets.asset_id
FROM i_asset_types INNER JOIN i_models ON i_asset_types.asset_type_id = i_models.asset_type_id 
	INNER JOIN i_assets ON i_models.model_id = i_assets.model_id
WHERE i_asset_types.asset_type_id = 6);

UPDATE assets SET AssetSubTypeID = 8 WHERE assetid IN
(SELECT i_assets.asset_id
FROM i_asset_types INNER JOIN i_models ON i_asset_types.asset_type_id = i_models.asset_type_id 
	INNER JOIN i_assets ON i_models.model_id = i_assets.model_id
WHERE i_asset_types.asset_type_id = 11);

UPDATE assets SET AssetSubTypeID = 9 WHERE assetid IN
(SELECT i_assets.asset_id
FROM i_asset_types INNER JOIN i_models ON i_asset_types.asset_type_id = i_models.asset_type_id 
	INNER JOIN i_assets ON i_models.model_id = i_assets.model_id
WHERE i_asset_types.asset_type_id = 14);

UPDATE assets SET AssetSubTypeID = 11 WHERE assetid IN
(SELECT i_assets.asset_id
FROM i_asset_types INNER JOIN i_models ON i_asset_types.asset_type_id = i_models.asset_type_id 
	INNER JOIN i_assets ON i_models.model_id = i_assets.model_id
WHERE i_asset_types.asset_type_id = 15);


INSERT INTO pccs( pcc,clientid, gds) 
SELECT  i_clients.pcc, max(i_clients.client_id), '1G' 
FROM i_clients 
WHERE i_clients.pcc is not null
GROUP BY i_clients.pcc;


INSERT INTO users (userid, usergroupid, superuser, rolename, username, fullname, extension, telno, email, accountmanager, groupleader, isactive, groupuser, userpass, details) VALUES (0, 1, false, NULL, 'Default', 'Default User', '000', NULL, NULL, false, false, true, false, 'e2a7106f1cc8bb1e1318df70aa0a3540', NULL);

INSERT INTO clientgroups (clientgroupid, clientaffiliateid, clientgroupname, detail) VALUES (0, 0, 'default', NULL);

INSERT INTO clientsystems (clientsystemid, clientsystemname, details) VALUES (1, 'Default', NULL);

INSERT INTO clientlinks (clientlinkid, clientlinkname, details) VALUES (0, 'default', NULL);

UPDATE clients SET UserID = 0;
UPDATE clients SET ClientGroupID = 0;
UPDATE clients SET ClientSystemID = 1;
UPDATE clients SET clientlinkid = 0;

INSERT INTO midttransactions(clientid, periodid, crs, pcc,  agency, iatano, prd) 
SELECT pccs.clientid, periods.periodid, pccs.gds, pccs.pcc,  m_segments.agency_name, m_segments.iata_number, 
(m_segments.total_net_segments+m_segments.passive_net_segments) as prd 
FROM m_segments inner join pccs on trim(pccs.pcc) = trim(m_segments.pcc)
INNER JOIN clients ON pccs.clientid = clients.clientid
INNER JOIN periods ON m_segments.booking_date::date = periods.startdate
WHERE trim(m_segments.iata_number)= substring(clients.iatano::text, 1, 7) AND pccs.gds = '1G';


-- SELECT pccs.pcc, pccs.clientid,  clients.clientid, m_segments.agency_name, clients.clientname, m_segments.iata_number, clients.iatano, (m_segments.total_net_segments+m_segments.passive_net_segments) as prd
-- FROM m_segments inner join pccs on trim(pccs.pcc) = trim(m_segments.pcc)
-- INNER JOIN clients ON pccs.clientid = clients.clientid
-- WHERE trim(m_segments.iata_number)= substring(clients.iatano::text, 1, 7)
-- GROUP BY pccs.pcc, pccs.clientid, m_segments.agency_name, clients.clientname, m_segments.iata_number, clients.iatano, clients.clientid, prd
-- ORDER BY m_segments.agency_name;

-- SELECT pccs.pcc, pccs.clientid, m_segments.agency_name, m_segments.iata_number, 
-- (m_segments.total_net_segments+m_segments.passive_net_segments) as prd, m_segments.booking_date, periods.periodid, periodid
-- FROM m_segments inner join pccs on trim(pccs.pcc) = trim(m_segments.pcc)
-- INNER JOIN clients ON pccs.clientid = clients.clientid
-- INNER JOIN periods ON m_segments.booking_date::date = periods.startdate
-- WHERE trim(m_segments.iata_number)= substring(clients.iatano::text, 1, 7) AND pccs.gds = '1G';


-------- add data from MIDT table to Transactions
INSERT INTO Transactions (ClientID, PeriodID, UserID, PCC, NASegs)
SELECT a.clientid, a.periodid, 0, a.pcc, a.prd
FROM midttransactions a LEFT JOIN Transactions b ON (a.clientid = b.clientid) AND (a.periodid = b.periodid)
WHERE b.TransactionID is null;

---pcc match
SELECT a.pcc, c.pcc, a.sub_id_name, a.mst_cus_id
FROM tmpnbosegment a 
INNER JOIN pccs c ON (a.pcc = c.pcc);

---pccs dont match
SELECT a.pcc, c.pcc, a.sub_id_name, a.mst_cus_id
FROM tmpnbosegment a 
INNER JOIN pccs c ON (a.pcc <> c.pcc) and a.pcc <> 'PCC';

----grouping with pccs
SELECT sub_id_name, mst_cus_id from tmpnbosegment
WHERE pcc = substring(sub_id_name::text, 14, 3);

--- inserting into clientgroups
INSERT INTO clientgroups(mst_cus_id, clientaffiliateid, clientgroupname, detail)
SELECT mst_cus_id, 0, max(substring(sub_id_name::text, 20)), count(sub_id_name) AS count
FROM tmpnbosegment
GROUP BY mst_cus_id
having count(sub_id_name) > 1;

---select * from clientgroups

ALTER TABLE transactions ADD COLUMN ticketedsegs varchar(50);
ALTER TABLE transactions ADD COLUMN bookedsegs varchar(50);
ALTER TABLE transactions ADD COLUMN carsegs varchar(50);
ALTER TABLE transactions ADD COLUMN hotelsegs varchar(50);

-- -----Inserting ticketed  transactions
INSERT INTO Transactions (clientid, pcc, periodid, ticketedsegs)
SELECT pccs.clientid, tmpnbosegment.pcc, periods.periodid, c_count
FROM (tmpnbosegment INNER JOIN pccs ON pccs.pcc = tmpnbosegment.pcc
INNER JOIN periods ON periods.startdate = '1899-12-30'::date + boi_booking_date::int)
LEFT JOIN transactions ON (pccs.clientid = transactions.clientid) AND (periods.periodid = transactions.periodid)
WHERE smo_cd <> 'SMO_CD' AND (transactions.transactionid is null) AND booking_type = 'ATS';-- 

-- //Inserting booked transactions
INSERT INTO Transactions (clientid, pcc, periodid, bookedsegs)
(SELECT pccs.clientid, tmpnbosegment.pcc, periods.periodid, c_count
FROM (tmpnbosegment INNER JOIN pccs ON pccs.pcc = tmpnbosegment.pcc
INNER JOIN periods ON periods.startdate = '1899-12-30'::date + boi_booking_date::int)
LEFT JOIN transactions ON (pccs.clientid = transactions.clientid) AND (periods.periodid = transactions.periodid)
WHERE smo_cd <> 'SMO_CD' AND (transactions.transactionid is not null) AND booking_type = 'A');
-- 
-- //Inserting car transactions, zero found
INSERT INTO Transactions (clientid, pcc, periodid, carsegs)
SELECT pccs.clientid, tmpnbosegment.pcc, periods.periodid, c_count
FROM (tmpnbosegment INNER JOIN pccs ON pccs.pcc = tmpnbosegment.pcc
INNER JOIN periods ON periods.startdate = '1899-12-30'::date + boi_booking_date::int)
LEFT JOIN transactions ON (pccs.clientid = transactions.clientid) AND (periods.periodid = transactions.periodid)
WHERE smo_cd <> 'SMO_CD' AND (transactions.transactionid is null) AND booking_type = 'C';
-- 
-- //Inserting Hotel  transactions
INSERT INTO Transactions (clientid, pcc, periodid, hotelsegs)
SELECT pccs.clientid, tmpnbosegment.pcc, periods.periodid, c_count
FROM (tmpnbosegment INNER JOIN pccs ON pccs.pcc = tmpnbosegment.pcc
INNER JOIN periods ON periods.startdate = '1899-12-30'::date + boi_booking_date::int)
LEFT JOIN transactions ON (pccs.clientid = transactions.clientid) AND (periods.periodid = transactions.periodid)
WHERE smo_cd <> 'SMO_CD' AND (transactions.transactionid is null) AND booking_type = 'H';

--upate transactions booked
UPDATE transactions SET bookedsegs = ut.c_count
FROM (SELECT pccs.clientid, tmpnbosegment.pcc, periods.periodid, c_count
FROM tmpnbosegment INNER JOIN pccs ON pccs.pcc = tmpnbosegment.pcc
INNER JOIN periods ON periods.startdate = '1899-12-30'::date + boi_booking_date::int
WHERE smo_cd <> 'SMO_CD' AND booking_type = 'A') ut 
WHERE transactions.clientid = ut.clientid AND transactions.periodid = ut.periodid;

--upate transactions ticketedsegs
UPDATE transactions SET ticketedsegs = ut.c_count
FROM (SELECT pccs.clientid, tmpnbosegment.pcc, periods.periodid, c_count
FROM tmpnbosegment INNER JOIN pccs ON pccs.pcc = tmpnbosegment.pcc
INNER JOIN periods ON periods.startdate = '1899-12-30'::date + boi_booking_date::int
WHERE smo_cd <> 'SMO_CD' AND booking_type = 'ATS') ut 
WHERE transactions.clientid = ut.clientid AND transactions.periodid = ut.periodid;

--upate transactions carsegs
UPDATE transactions SET carsegs = ut.c_count
FROM (SELECT pccs.clientid, tmpnbosegment.pcc, periods.periodid, c_count
FROM tmpnbosegment INNER JOIN pccs ON pccs.pcc = tmpnbosegment.pcc
INNER JOIN periods ON periods.startdate = '1899-12-30'::date + boi_booking_date::int
WHERE smo_cd <> 'SMO_CD' AND booking_type = 'C') ut 
WHERE transactions.clientid = ut.clientid AND transactions.periodid = ut.periodid;

--upate transactions hotelsegs
UPDATE transactions SET hotelsegs = ut.c_count
FROM (SELECT pccs.clientid, tmpnbosegment.pcc, periods.periodid, c_count
FROM tmpnbosegment INNER JOIN pccs ON pccs.pcc = tmpnbosegment.pcc
INNER JOIN periods ON periods.startdate = '1899-12-30'::date + boi_booking_date::int
WHERE smo_cd <> 'SMO_CD' AND booking_type = 'H') ut 
WHERE transactions.clientid = ut.clientid AND transactions.periodid = ut.periodid;

-- -----Inserting ticketed  midttransactions
INSERT INTO midttransactions (clientid, pcc, periodid, ticketedsegs)
SELECT pccs.clientid, tmpnbosegment.pcc, periods.periodid, c_count
FROM (tmpnbosegment INNER JOIN pccs ON pccs.pcc = tmpnbosegment.pcc
INNER JOIN periods ON periods.startdate = '1899-12-30'::date + boi_booking_date::int)
LEFT JOIN transactions ON (pccs.clientid = transactions.clientid) AND (periods.periodid = transactions.periodid)
WHERE smo_cd <> 'SMO_CD' AND (transactions.transactionid is null) AND booking_type = 'ATS';-- 

-- //Inserting booked midttransactions
INSERT INTO midttransactions (clientid, pcc, periodid, bookedsegs)
(SELECT pccs.clientid, tmpnbosegment.pcc, periods.periodid, c_count
FROM (tmpnbosegment INNER JOIN pccs ON pccs.pcc = tmpnbosegment.pcc
INNER JOIN periods ON periods.startdate = '1899-12-30'::date + boi_booking_date::int)
LEFT JOIN transactions ON (pccs.clientid = transactions.clientid) AND (periods.periodid = transactions.periodid)
WHERE smo_cd <> 'SMO_CD' AND (transactions.transactionid is not null) AND booking_type = 'A');
-- 
-- //Inserting car midttransactions, zero found
INSERT INTO Transactions (clientid, pcc, periodid, carsegs)
SELECT pccs.clientid, tmpnbosegment.pcc, periods.periodid, c_count
FROM (tmpnbosegment INNER JOIN pccs ON pccs.pcc = tmpnbosegment.pcc
INNER JOIN periods ON periods.startdate = '1899-12-30'::date + boi_booking_date::int)
LEFT JOIN transactions ON (pccs.clientid = transactions.clientid) AND (periods.periodid = transactions.periodid)
WHERE smo_cd <> 'SMO_CD' AND (transactions.transactionid is null) AND booking_type = 'C';
-- 
-- //Inserting Hotel  midttransactions
INSERT INTO midttransactions (clientid, pcc, periodid, hotelsegs)
SELECT pccs.clientid, tmpnbosegment.pcc, periods.periodid, c_count
FROM (tmpnbosegment INNER JOIN pccs ON pccs.pcc = tmpnbosegment.pcc
INNER JOIN periods ON periods.startdate = '1899-12-30'::date + boi_booking_date::int)
LEFT JOIN transactions ON (pccs.clientid = transactions.clientid) AND (periods.periodid = transactions.periodid)
WHERE smo_cd <> 'SMO_CD' AND (transactions.transactionid is null) AND booking_type = 'H';

--upate midttransactions booked
UPDATE midttransactions SET bookedsegs = ut.c_count
FROM (SELECT pccs.clientid, tmpnbosegment.pcc, periods.periodid, c_count
FROM tmpnbosegment INNER JOIN pccs ON pccs.pcc = tmpnbosegment.pcc
INNER JOIN periods ON periods.startdate = '1899-12-30'::date + boi_booking_date::int
WHERE smo_cd <> 'SMO_CD' AND booking_type = 'A') ut 
WHERE midttransactions.clientid = ut.clientid AND midttransactions.periodid = ut.periodid;

--upate midttransactions ticketedsegs
UPDATE midttransactions SET ticketedsegs = ut.c_count
FROM (SELECT pccs.clientid, tmpnbosegment.pcc, periods.periodid, c_count
FROM tmpnbosegment INNER JOIN pccs ON pccs.pcc = tmpnbosegment.pcc
INNER JOIN periods ON periods.startdate = '1899-12-30'::date + boi_booking_date::int
WHERE smo_cd <> 'SMO_CD' AND booking_type = 'ATS') ut 
WHERE midttransactions.clientid = ut.clientid AND midttransactions.periodid = ut.periodid;

--upate midttransactions carsegs
UPDATE midttransactions SET carsegs = ut.c_count
FROM (SELECT pccs.clientid, tmpnbosegment.pcc, periods.periodid, c_count
FROM tmpnbosegment INNER JOIN pccs ON pccs.pcc = tmpnbosegment.pcc
INNER JOIN periods ON periods.startdate = '1899-12-30'::date + boi_booking_date::int
WHERE smo_cd <> 'SMO_CD' AND booking_type = 'C') ut 
WHERE midttransactions.clientid = ut.clientid AND midttransactions.periodid = ut.periodid;

--upate midttransactions hotelsegs
UPDATE midttransactions SET hotelsegs = ut.c_count
FROM (SELECT pccs.clientid, tmpnbosegment.pcc, periods.periodid, c_count
FROM tmpnbosegment INNER JOIN pccs ON pccs.pcc = tmpnbosegment.pcc
INNER JOIN periods ON periods.startdate = '1899-12-30'::date + boi_booking_date::int
WHERE smo_cd <> 'SMO_CD' AND booking_type = 'H') ut 
WHERE midttransactions.clientid = ut.clientid AND midttransactions.periodid = ut.periodid;

---  Select unused data
SELECT tmpnbosegment_id, c_count,  mst_cus_id, sub_id_name, booking_type, tmpnbosegment.pcc 
from tmpnbosegment 
INNER JOIN periods ON periods.startdate = '1899-12-30'::date + boi_booking_date::int
LEFT JOIN transactions ON (tmpnbosegment.pcc = transactions.pcc) AND (periods.periodid = transactions.periodid)
WHERE  booking_type = 'A'  AND transactions.bookedsegs IS NULL;

SELECT '1899-12-30'::date + boi_booking_date::int, *
FROM (tmpnbosegment INNER JOIN pccs ON pccs.pcc = tmpnbosegment.pcc
INNER JOIN periods ON periods.startdate = '1899-12-30'::date + boi_booking_date::int)
LEFT JOIN transactions ON (pccs.clientid = transactions.clientid) AND (periods.periodid = transactions.periodid)
WHERE smo_cd <> 'SMO_CD' --- AND booking_type = 'A' ;
