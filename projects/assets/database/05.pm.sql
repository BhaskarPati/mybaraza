CREATE TABLE pm_quarters (
	pm_quarter_id		serial primary key,
	qstart_date			date,
	qstop_date			date,
	qcompleted			boolean default false,
	details				text
);

CREATE TABLE pm_schedule (
	pm_schedule_id		serial primary key,
	pm_quarter_id		integer references pm_quarters,
	client_id			integer references clients,
	start_date			date not null,
	end_date			date,
	pm_group			varchar(12),
	date_done			date,
	completed			boolean default false,
	approved			boolean default false,
	contact_person		varchar(50),
	details				text
);
CREATE INDEX pm_schedule_pm_quarter_id ON pm_schedule (pm_quarter_id);	
CREATE INDEX pm_schedule_client_id ON pm_schedule (client_id);

CREATE TABLE pm_checklist (
	checklistid			serial primary key,
	pm_schedule_id		integer references pm_schedule,
	entity_id			integer references entitys,
	datedone			date default current_date,
	os_type				varchar(32),
	anti_virus			varchar(32),
	office_suite		varchar(32),
	mail_client			varchar(32),
	gd					varchar(32),
	acrobatreader		varchar(32),
	fpm					varchar(32),
	back_office			varchar(32),
	front_office		varchar(32),

	ssl					boolean default false,
	galileo				boolean default false,
	electronicticket	boolean default false,
	controlb			boolean default false,
	mail				boolean default false,
	internet			boolean default false,

	compname			varchar(50),
	workgroup			varchar(50),
	ipaddress			varchar(16),
	ipconfig			text,
	needrepair			boolean default false,
	repaired			boolean default false,
	repairdetails		text,
	CPUSN				varchar(50),
	MonitorSN			varchar(50),
	KeyboardSN			varchar(50),
	MouseSN				varchar(50),
	ups_SN				varchar(50),

	ItnPrinter			varchar(50),
	LaptopSN			varchar(50),
	laserprintersn		varchar(50),

	cpu_tag				varchar(50),
	Monitor_tag			varchar(50),
	ItnPrinter_tag		varchar(50),
	Laptop_tag			varchar(50),
	laserprinter_tag	varchar(50),

	ups_tag				varchar(50),

	clientgtid			varchar(50),
	clientid			varchar(50),
	compuser			varchar(50),


	pcmodel				varchar(50),
	harddisk			varchar(15),
	ram					varchar(15),
	processor			varchar(32),

	usercomments		text,
	engineercomments	text
);
CREATE INDEX pm_checklist_pm_schedule_id ON pm_checklist (pm_schedule_id);
CREATE INDEX pm_checklist_entity_id ON pm_checklist (entity_id);

CREATE TABLE pm_links (
	pm_link_id			serial primary key,
	pm_schedule_id		integer references pm_schedule,
	entity_id			integer references entitys,
	date_done			date default current_date,
	supplier_name		varchar(50),
	link_capacity		integer,
	link_number			varchar(50),

	router_SN			varchar(50),
	router_tag			varchar(50),

	ups_SN				varchar(50),
	ups_tag				varchar(50),
	link_type			varchar(32),

	ping_test			text
);
CREATE INDEX pm_links_pm_schedule_id ON pm_links (pm_schedule_id);
CREATE INDEX pm_links_entity_id ON pm_links (entity_id);
		

CREATE OR REPLACE FUNCTION ins_pm_schedule() RETURNS TRIGGER AS $$
BEGIN
	NEW.end_date = NEW.start_date + 5;
	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_pm_schedule BEFORE INSERT ON pm_schedule
    FOR EACH ROW EXECUTE PROCEDURE ins_pm_schedule();

CREATE VIEW vw_pm_quarters AS
	SELECT pm_quarters.pm_quarter_id, pm_quarters.qstart_date, pm_quarters.qstop_date, pm_quarters.qcompleted,
		to_char(pm_quarters.qstart_date, 'YYYY') as qperiod_year,
		pm_quarters.details
	FROM pm_quarters
	ORDER BY pm_quarters.qstart_date;

CREATE VIEW vw_pm_year AS
	SELECT qperiod_year
	FROM vw_pm_quarters
	GROUP BY qperiod_year
	ORDER BY qperiod_year;

CREATE VIEW vw_pm_schedule AS
	SELECT vw_clients.client_id, vw_clients.client_name, vw_clients.address, vw_clients.zipcode, 
		vw_clients.premises, vw_clients.street, vw_clients.division, vw_clients.town, 
		vw_clients.telno, vw_clients.email, vw_clients.pcc, vw_clients.iatano, vw_clients.website, 
		vw_clients.travel_manager, vw_clients.technical_contact,
		vw_clients.is_active, vw_clients.sys_country_id, vw_clients.sys_country_name, 
		vw_clients.account_manager_id, vw_clients.account_manager_name,
		vw_clients.account_manager_phone, vw_clients.account_manager_email,

		vw_pm_quarters.pm_quarter_id, vw_pm_quarters.qperiod_year,
		vw_pm_quarters.qstart_date, vw_pm_quarters.qstop_date, vw_pm_quarters.qcompleted,
		

		pm_schedule.pm_schedule_id, pm_schedule.start_date, pm_schedule.end_date, pm_schedule.pm_group, 
		pm_schedule.date_done, pm_schedule.completed, pm_schedule.approved, pm_schedule.contact_person, 
		pm_schedule.details
	FROM pm_schedule INNER JOIN vw_clients ON pm_schedule.client_id = vw_clients.client_id
		INNER JOIN vw_pm_quarters ON pm_schedule.pm_quarter_id = vw_pm_quarters.pm_quarter_id;

CREATE VIEW vw_pm_checklist AS
	SELECT vw_pm_schedule.client_id, vw_pm_schedule.client_name, vw_pm_schedule.premises, 
		vw_pm_schedule.street, vw_pm_schedule.division, vw_pm_schedule.town, 
		vw_pm_schedule.pm_quarter_id, vw_pm_schedule.qperiod_year,
		vw_pm_schedule.qstart_date, vw_pm_schedule.qstop_date, vw_pm_schedule.qcompleted,
		vw_pm_schedule.pm_schedule_id, vw_pm_schedule.start_date, vw_pm_schedule.end_date, 
		vw_pm_schedule.pm_group, vw_pm_schedule.date_done, vw_pm_schedule.completed,

		entitys.entity_id, entitys.entity_name, 

		pm_checklist.checklistid, pm_checklist.datedone, pm_checklist.os_type, pm_checklist.anti_virus, 
		pm_checklist.office_suite, pm_checklist.mail_client, pm_checklist.gd, pm_checklist.acrobatreader, 
		pm_checklist.fpm, pm_checklist.back_office, pm_checklist.front_office, pm_checklist.ssl, 
		pm_checklist.galileo, pm_checklist.electronicticket, pm_checklist.controlb, pm_checklist.mail, 
		pm_checklist.internet, pm_checklist.compname, pm_checklist.workgroup, pm_checklist.ipaddress, 
		pm_checklist.ipconfig, pm_checklist.needrepair, pm_checklist.repaired, pm_checklist.repairdetails, 
		pm_checklist.cpusn, pm_checklist.monitorsn, pm_checklist.keyboardsn, pm_checklist.mousesn, 
		pm_checklist.itnprinter, pm_checklist.laptopsn, pm_checklist.laserprintersn, 
		pm_checklist.clientgtid, pm_checklist.clientid, pm_checklist.compuser, pm_checklist.pcmodel, pm_checklist.ups_SN,
		pm_checklist.harddisk, pm_checklist.ram, pm_checklist.usercomments, pm_checklist.engineercomments
	FROM pm_checklist INNER JOIN vw_pm_schedule ON pm_checklist.pm_schedule_id = vw_pm_schedule.pm_schedule_id
	INNER JOIN entitys ON pm_checklist.entity_id = entitys.entity_id;

CREATE VIEW vw_pm_links AS
	SELECT vw_pm_schedule.client_id, vw_pm_schedule.client_name, vw_pm_schedule.premises, 
		vw_pm_schedule.street, vw_pm_schedule.division, vw_pm_schedule.town, 
		vw_pm_schedule.pm_quarter_id, vw_pm_schedule.qperiod_year,
		vw_pm_schedule.qstart_date, vw_pm_schedule.qstop_date, vw_pm_schedule.qcompleted,
		vw_pm_schedule.pm_schedule_id, vw_pm_schedule.start_date, vw_pm_schedule.end_date, 
		vw_pm_schedule.pm_group, vw_pm_schedule.date_done,

		entitys.entity_id, entitys.entity_name, 

		pm_links.pm_link_id, pm_links.date_done as link_date_done, pm_links.supplier_name, pm_links.link_capacity, 
		pm_links.link_number, pm_links.router_SN, pm_links.router_tag, pm_links.ups_SN, pm_links.ups_tag, pm_links.ping_test

	FROM pm_links INNER JOIN vw_pm_schedule ON pm_links.pm_schedule_id = vw_pm_schedule.pm_schedule_id
	INNER JOIN entitys ON pm_links.entity_id = entitys.entity_id;
	
CREATE OR REPLACE FUNCTION get_gtids(integer) RETURNS varchar(320) AS $$
DECLARE
    myrec	RECORD;
	gtids	varchar(320);
BEGIN
	gtids := null;
	FOR myrec IN SELECT clientgtid FROM pm_checklist WHERE pm_schedule_id = $1 LOOP
		IF (gtids is null) THEN
			gtids := myrec.clientgtid;
		ELSE
			gtids := gtids || '/' || myrec.clientgtid;
		END IF;
	END LOOP;

	RETURN gtids;
END;
$$ LANGUAGE plpgsql;

CREATE VIEW vw_pm_schedule_a AS
	SELECT vw_pm_schedule.pm_schedule_id, vw_pm_schedule.pm_quarter_id, vw_pm_schedule.completed,
		to_char(vw_pm_schedule.start_date, 'DD/MM/YYYY') as schedule_date, vw_pm_schedule.client_name, vw_pm_schedule.town, 
		(CASE WHEN vw_pm_schedule.completed = true THEN to_char(vw_pm_schedule.date_done, 'DD/MM/YYYY') ELSE 'Not Done' END) as pm_status,
		trim((CASE WHEN (SELECT count(pm_checklist.checklistid) FROM pm_checklist WHERE pm_checklist.pm_schedule_id = vw_pm_schedule.pm_schedule_id) = 0 THEN '' ELSE 'Equipment' END) 
		|| (CASE WHEN (SELECT count(pm_links.pm_link_id) FROM pm_links WHERE pm_links.pm_schedule_id = vw_pm_schedule.pm_schedule_id) = 0 THEN '' ELSE ' Link' END)) as pm_type,
		get_gtids(vw_pm_schedule.pm_schedule_id) as gtids,
		(SELECT max(pm_checklist.gd) FROM pm_checklist WHERE pm_checklist.pm_schedule_id = vw_pm_schedule.pm_schedule_id) as gd_version,
		vw_pm_schedule.details
	FROM vw_pm_schedule
	ORDER BY vw_pm_schedule.start_date;

CREATE VIEW vw_pm_assets AS
	SELECT checklistid, pm_schedule_id, pm_asset_type_id, pm_serial_number
	FROM
		((SELECT checklistid, pm_schedule_id, 1::integer as pm_asset_type_id, cpusn as pm_serial_number
		FROM pm_checklist
		WHERE cpusn is not null) UNION
		(SELECT checklistid, pm_schedule_id, 2::integer as pm_asset_type_id, monitorsn as pm_serial_number
		FROM pm_checklist
		WHERE monitorsn is not null) UNION
		(SELECT checklistid, pm_schedule_id, 3::integer as pm_asset_type_id, laptopsn
		FROM pm_checklist
		WHERE laptopsn is not null) UNION
		(SELECT checklistid, pm_schedule_id, 4::integer as pm_asset_type_id, itnprinter
		FROM pm_checklist
		WHERE itnprinter is not null) UNION
		(SELECT checklistid, pm_schedule_id, 5::integer as pm_asset_type_id, laserprintersn
		FROM pm_checklist
		WHERE laserprintersn is not null) UNION
		(SELECT checklistid, pm_schedule_id, 6::integer as pm_asset_type_id, ups_sn
		FROM pm_checklist
		WHERE ups_sn is not null) UNION
		(SELECT pm_link_id, pm_schedule_id, 6::integer as pm_asset_type_id, ups_sn
		FROM pm_links
		WHERE ups_sn is not null) UNION
		(SELECT pm_link_id, pm_schedule_id, 7::integer as pm_asset_type_id, router_sn
		FROM pm_links
		WHERE router_sn is not null)) as a;
		
		
CREATE VIEW vw_pms_assets AS
	SELECT asset_types.asset_type_id, asset_types.asset_type_name,
		vw_pm_assets.checklistid, vw_pm_assets.pm_schedule_id, vw_pm_assets.pm_serial_number,
		pm_schedule.pm_quarter_id, pm_schedule.client_id, pm_schedule.date_done
	FROM asset_types INNER JOIN vw_pm_assets ON asset_types.asset_type_id = vw_pm_assets.pm_asset_type_id
		INNER JOIN pm_schedule ON vw_pm_assets.pm_schedule_id = pm_schedule.pm_schedule_id
	WHERE (pm_schedule.completed = true);
		
		
SELECT aa.checklistid, aa.pm_schedule_id, aa.date_done,
	aa.asset_type_name,  aa.pm_serial_number,
	bb.asset_type_name, bb.asset_serial,
	bb.client_id, bb.client_name
FROM
(SELECT a.asset_type_id, a.asset_type_name,
	a.checklistid, a.pm_schedule_id, a.pm_serial_number,
	a.pm_quarter_id, a.client_id, a.date_done
FROM vw_pms_assets as a) as aa
LEFT JOIN
(SELECT b.client_id, b.client_name, b.asset_type_id, b.asset_type_name, b.asset_serial,
c.pm_schedule_id
FROM vw_client_assets as b INNER JOIN pm_schedule c ON b.client_id = c.client_id
WHERE (b.is_issued = true) AND (b.is_retrived = false)) as bb

	ON (aa.pm_schedule_id = bb.pm_schedule_id) AND (aa.asset_type_id = bb.asset_type_id)
		AND (trim(upper(aa.pm_serial_number)) = trim(upper(bb.asset_serial)))


WHERE aa.pm_schedule_id = 956
ORDER BY aa.asset_type_id;


SELECT bb.client_id, bb.client_name,
	bb.asset_type_name, bb.asset_serial,
	aa.asset_type_name,  aa.pm_serial_number,
	aa.checklistid, aa.pm_schedule_id, aa.date_done
FROM
(SELECT b.client_id, b.client_name, b.asset_type_id, b.asset_type_name, b.asset_serial,
c.pm_schedule_id
FROM vw_client_assets as b INNER JOIN pm_schedule c ON b.client_id = c.client_id
WHERE (b.is_issued = true) AND (b.is_retrived = false)) as bb

LEFT OUTER JOIN

(SELECT a.asset_type_id, a.asset_type_name,
	a.checklistid, a.pm_schedule_id, a.pm_serial_number,
	a.pm_quarter_id, a.client_id, a.date_done
FROM vw_pms_assets as a) as aa

	ON (aa.pm_schedule_id = bb.pm_schedule_id) AND (aa.asset_type_id = bb.asset_type_id)
		AND (trim(upper(aa.pm_serial_number)) = trim(upper(bb.asset_serial)))


WHERE bb.pm_schedule_id = 956
ORDER BY bb.asset_type_id;


