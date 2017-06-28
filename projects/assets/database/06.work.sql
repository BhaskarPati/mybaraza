-- This is how you import
--- Laptop
INSERT INTO assets (purchase_date, purchase_value, org_id, asset_status_id, model_id, entity_id, asset_serial) VALUES ('2017-01-26', 1232, 0, 1, 39, 144, '');

--- CPU
INSERT INTO assets (purchase_date, purchase_value, org_id, asset_status_id, model_id, entity_id, asset_serial) VALUES ('2016-10-04', 1223, 0, 1, 49, 144, '');

--- Monitor
INSERT INTO assets (purchase_date, purchase_value, org_id, asset_status_id, model_id, entity_id, asset_serial) VALUES ('2016-10-04', 0, 0, 1, 50, 144, '');

--- Server
INSERT INTO assets (purchase_date, purchase_value, org_id, asset_status_id, model_id, entity_id, asset_serial) VALUES ('2016-04-22', 1223, 0, 1, 48, 139, '');

--- UPS 
INSERT INTO assets (purchase_date, purchase_value, org_id, asset_status_id, model_id, entity_id, asset_serial) VALUES ('2017-01-16', 115, 0, 1, 59, 144, '');

--- Epson Printer
INSERT INTO assets (purchase_date, purchase_value, org_id, asset_status_id, model_id, entity_id, asset_serial) VALUES ('2016-09-28', 287, 0, 1, 4, 138, '');


----- Assets comparison
SELECT asset_imports.description, asset_imports.agency, asset_imports.serial_number, asset_imports.type, asset_imports.sheet
FROM asset_imports LEFT JOIN assets 
	ON trim(upper(asset_imports.serial_number)) = trim(upper(assets.asset_serial))	
WHERE (assets.asset_serial is null)
	AND (asset_imports.Serial_Number <> '')
ORDER BY type;


----- Equipment in store
SELECT asset_type_name, model, purchase_date, asset_serial
FROM vw_assets
WHERE (asset_type_id IN (1, 3)) AND (asset_status_id = 1) AND (purchase_date >= '2016-01-01'::date)
ORDER BY asset_type_id, purchase_date, model;

SELECT store_equiments.equipment_type, store_equiments.serial_number
FROM store_equiments LEFT JOIN vw_assets ON store_equiments.serial_number = vw_assets.asset_serial
WHERE (vw_assets.asset_serial is null)
ORDER BY store_equiments.equipment_type, store_equiments.serial_number;

SELECT a.asset_type_name, a.asset_serial
FROM (SELECT vw_assets.asset_type_name, vw_assets.asset_serial
FROM vw_assets
WHERE vw_assets.asset_status_id = 1) as a LEFT JOIN store_equiments
	ON a.asset_serial = store_equiments.serial_number
WHERE (store_equiments.serial_number is null)
ORDER BY a.asset_type_name, a.asset_serial; 



---- Clients not on PM List
SELECT a.client_id, a.pcc, a.client_name, a.premises, a.street, a.division, a.town
FROM
(SELECT vw_client_assets.client_id, vw_client_assets.pcc, vw_client_assets.client_name,
vw_client_assets.premises, vw_client_assets.street, vw_client_assets.division,
vw_client_assets.town
FROM vw_client_assets
GROUP BY vw_client_assets.client_id, vw_client_assets.pcc, vw_client_assets.client_name,
vw_client_assets.premises, vw_client_assets.street, vw_client_assets.division,
vw_client_assets.town
ORDER BY vw_client_assets.client_name) as a
LEFT JOIN vw_pm_schedule ON a.client_id = vw_pm_schedule.client_id
WHERE vw_pm_schedule.client_id is null;


---- Equipment and links list
(SELECT 'Equipment'::varchar(16) as item_type, asset_type_name, client_id, pcc, client_name, count(client_asset_id) as asset_count
FROM vw_client_assets
WHERE (is_issued = true) AND (is_retrived = false)
GROUP BY asset_type_name, client_id, pcc, client_name
ORDER BY asset_type_name, client_name)
UNION
(SELECT 'Links'::varchar(16) as item_type, entity_name, client_id, pcc, client_name, count(client_link_id) as asset_count
FROM vw_client_links
WHERE (is_issued = true) AND (is_retrived = false)
GROUP BY entity_name, client_id, pcc, client_name
ORDER BY entity_name, client_name)


----------------- KQ Asset list
UPDATE assets SET purchase_value = CAST(imp1.Cost as real)
FROM imp1 WHERE (imp1.itn = assets.asset_serial);

UPDATE assets SET purchase_value = CAST(imp2.Cost as real)
FROM imp2 WHERE (imp2.pc = assets.asset_serial);

SELECT *
FROM imp1 LEFT JOIN assets ON imp1.itn = assets.asset_serial
WHERE assets.asset_serial is null
ORDER BY equipment, ITN;

SELECT *
FROM imp2 LEFT JOIN assets ON imp2.pc = assets.asset_serial
WHERE assets.asset_serial is null;

SELECT vw_assets.asset_type_name, vw_assets.asset_status_name, asset_serial
FROM vw_assets LEFT JOIN
((SELECT equipment, itn, status
FROM imp1)
UNION
(SELECT description, pc, status
FROM imp2)
UNION
(SELECT description, monitor, status
FROM imp2)) as a ON vw_assets.asset_serial = a.itn
WHERE a.itn is null
ORDER BY vw_assets.asset_type_name, asset_serial;


---------------- Verifications
SELECT trim(upper(pcc))
FROM imp_links
WHERE length(upper(pcc)) = 0;

SELECT imp_links.pcc, imp_links.customer_name
FROM imp_links LEFT JOIN clients ON trim(upper(imp_links.pcc)) = clients.pcc
WHERE (length(trim(imp_links.pcc)) > 0) AND (clients.pcc is null)
ORDER BY imp_links.no

SELECT *
FROM clients
WHERE pcc = '73RH'

SELECT *
FROM imp_links
WHERE pcc = '7PW0'


SELECT clients.client_id, imp_links.no, clients.pcc, clients.client_name, 
imp_links.customer_name, clients.town, imp_links.region, imp_links.link
FROM clients INNER JOIN imp_links ON clients.pcc = imp_links.pcc
ORDER BY clients.client_name

SELECT clients.client_id, clients.pcc, clients.client_name, clients.address, clients.zipcode, 
	clients.premises, clients.street, clients.division, clients.town, 
	clients.telno, clients.email, clients.website
FROM imp_links left join clients ON imp_links.pcc = clients.pcc
GROUP BY clients.client_id, clients.pcc, clients.client_name, clients.address, clients.zipcode, 
	clients.premises, clients.street, clients.division, clients.town, 
	clients.telno, clients.email, clients.website
ORDER BY clients.client_name

SELECT clients.client_id, clients.pcc, clients.client_name, 
	clients.premises, clients.street, clients.division, clients.town, 
	clients.telno, clients.email, clients.website, 
	clients.travel_manager, clients.technical_contact,
	imp_links.*
FROM imp_links LEFT JOIN clients ON imp_links.pcc = clients.pcc
WHERE (clients.is_active = false)
ORDER BY clients.client_name

------------ Dell verification
SELECT dell_sn, count(dell_id)
FROM dells
GROUP BY dell_sn
HAVING count(dell_id) > 1;

SELECT *
FROM dells LEFT JOIN assets ON dells.dell_sn = assets.asset_serial
WHERE dell_type = 1 AND assets.asset_serial is null

------------ Assets

SELECT asset_serial, count(asset_id)
FROM assets
GROUP BY asset_serial
HAVING count(asset_id) > 1;


SELECT *
FROM new_assets LEFT JOIN assets ON new_assets.serial_number = assets.asset_serial
WHERE assets.asset_serial is not null

SELECT *
FROM assets LEFT JOIN new_assets ON assets.asset_serial = new_assets.serial_number
WHERE (trim(upper(asset_serial)) ilike '%95J')


SELECT *
FROM new_assets LEFT JOIN assets ON new_assets.serial_number = assets.asset_serial
WHERE (new_assets.type_id = 1) AND (assets.asset_serial is null)


SELECT client_name, vw_client_assets.asset_serial
FROM vw_client_assets LEFT JOIN new_assets ON vw_client_assets.asset_serial = new_assets.serial_number
WHERE (trim(upper(vw_client_assets.asset_serial)) ilike '%95J') AND new_assets.serial_number is null
ORDER BY vw_client_assets.asset_serial


---------- laptops
SELECT *
FROM assets LEFT JOIN new_assets ON assets.asset_serial = new_assets.serial_number
WHERE (trim(upper(asset_serial)) ilike '%S1')


SELECT *
FROM new_assets LEFT JOIN assets ON new_assets.serial_number = assets.asset_serial
WHERE (new_assets.type_id = 2) AND (assets.asset_serial is null)


SELECT client_name, vw_client_assets.asset_serial
FROM vw_client_assets LEFT JOIN new_assets ON vw_client_assets.asset_serial = new_assets.serial_number
WHERE (trim(upper(vw_client_assets.asset_serial)) ilike '%S1') AND new_assets.serial_number is null
ORDER BY vw_client_assets.asset_serial


SELECT asset_type_name, asset_serial
FROM vw_assets LEFT JOIN new_assets ON vw_assets.asset_serial = new_assets.serial_number
WHERE new_assets.serial_number is null
ORDER BY display_order, asset_serial


--------- Assets from KQ list
UPDATE kqlists SET kqlist_sn = trim(upper(kqlist_sn));

SELECT kqlist_sn, count(kqlist_id)
FROM kqlists
GROUP BY kqlist_sn
HAVING count(kqlist_id) > 1;

SELECT clients.pcc, clients.client_name, vw_assets.asset_type_name, vw_assets.asset_status_name, vw_assets.asset_serial,
kqlists.kqlist_sn, kqlists.etype, kqlists.equipment, kqlists.agency, kqlists.status
FROM vw_assets INNER JOIN kqlists ON vw_assets.asset_serial = kqlists.kqlist_sn
LEFT JOIN (client_assets INNER JOIN clients ON client_assets.client_id = clients.client_id)
ON client_assets.asset_id = vw_assets.asset_id
ORDER BY clients.client_name, vw_assets.model_id;


SELECT kqlists.kqlist_sn, kqlists.etype, kqlists.equipment, kqlists.agency, kqlists.status
FROM kqlists LEFT JOIN assets ON kqlists.kqlist_sn = assets.asset_serial
WHERE assets.asset_serial is null
ORDER BY kqlists.etype, kqlists.kqlist_sn;

SELECT vw_assets.asset_type_name, vw_assets.asset_status_name, vw_assets.asset_serial, clients.client_name
FROM vw_assets LEFT JOIN kqlists ON vw_assets.asset_serial = kqlists.kqlist_sn
LEFT JOIN (client_assets INNER JOIN clients ON client_assets.client_id = clients.client_id)
ON client_assets.asset_id = vw_assets.asset_id
WHERE (kqlists.kqlist_sn is null) AND (vw_assets.model_id <> 6) AND (vw_assets.model_id <> 7)
ORDER BY vw_assets.model_id, vw_assets.asset_serial;

-------------- PM work

SELECT to_char(vw_pm_schedule.start_date, 'DD/MM/YYYY') as schedule_date, vw_pm_schedule.client_name, vw_pm_schedule.town, 
(CASE WHEN vw_pm_schedule.completed = true THEN to_char(vw_pm_schedule.date_done, 'DD/MM/YYYY') ELSE 'Not Done' END) as pm_status.

FROM vw_pm_schedule
ORDER BY vw_pm_schedule.start_date



-------- Asset disposal

UPDATE assets SET asset_status_id = 8, disposal_amount = 0, disposal_date = '2015-07-30'::date WHERE asset_serial = '';


-------- Generate asset tags

ALTER TABLE asset_types ADD tag_prefix				varchar(4);

UPDATE assets SET tag_number = a.tag_prefix || to_char(purchase_date, 'YY') || lpad(asset_id::varchar, 5, '0')
FROM (SELECT asset_types.tag_prefix, models.model_id FROM asset_types INNER JOIN models ON asset_types.asset_type_id = models.asset_type_id WHERE (asset_types.tag_prefix is not null)) a 
WHERE (assets.model_id = a.model_id) AND (tag_number is null);

--------- Store asset count

SELECT a.asset_type_name, a.model, a.purchase_date, a.asset_serial, max(b.client_name)

FROM
(SELECT asset_id, asset_type_id, asset_type_name, model, purchase_date, asset_serial
FROM vw_assets
WHERE (asset_type_id IN (1, 3)) AND (asset_status_id = 1) AND (purchase_date < '2016-01-01'::date)
AND (asset_serial NOT IN (SELECT serial_number FROM tmp1))) a
LEFT JOIN vw_client_assets b ON a.asset_id = b.asset_id

GROUP BY a.asset_type_id, a.asset_type_name, a.model, a.purchase_date, a.asset_serial
ORDER BY a.asset_type_id, a.purchase_date, a.model


-------------- assets grouped reports

SELECT vw_client_assets.pcc, vw_client_assets.client_name, vw_client_assets.asset_type_name, 
vw_client_assets.manufacturer_name, vw_client_assets.model_name,
vw_client_assets.asset_serial, vw_client_assets.tag_number, 
to_char(vw_client_assets.date_issued, 'dd/MM/YYYY') as issue_date,
to_char(vw_client_assets.purchase_date, 'dd/MM/YYYY') as purchase_date

FROM vw_client_assets

WHERE (vw_client_assets.is_issued = true) AND (vw_client_assets.retrived is null)
AND (vw_client_assets.asset_type_id IN (1,2,3,4,5,6,7,8,9,14))

ORDER BY vw_client_assets.client_name, vw_client_assets.asset_type_name, vw_client_assets.date_issued;


--------------- Links

SELECT entity_name, pcc, client_name, division, town, 
	date_issued, link_capacity, connection_type, link_number, vlan_id, use_type, ip_allocation
FROM vw_client_links
WHERE (is_issued = true) AND (is_retrived = false)
ORDER BY entity_name, client_name;



