---Project Database File

ALTER TABLE orgs ADD pcc varchar(7);
ALTER TABLE orgs ADD sp_id	varchar(16);
ALTER TABLE orgs ADD service_id	varchar(32);
ALTER TABLE orgs ADD sender_name varchar(16);
ALTER TABLE orgs ADD sms_rate real default 2 not null;
ALTER TABLE orgs ADD show_fare boolean default false;
ALTER TABLE orgs ADD gds_free_field integer default 96;
ALTER TABLE orgs ADD is_iata boolean default false;
ALTER TABLE orgs ADD date_enroled timestamp default now();
ALTER TABLE orgs ADD account_manager_id integer references entitys;
CREATE INDEX orgs_account_manager_id ON orgs (account_manager_id);

ALTER TABLE orgs DROP CONSTRAINT orgs_org_name_key;
ALTER TABLE orgs DROP CONSTRAINT orgs_org_sufix_key;

ALTER TABLE entitys ADD svcb_son  varchar(20);
ALTER TABLE entitys ADD can_redeem boolean default true;
ALTER TABLE entitys ADD salutation varchar(7);
ALTER TABLE entitys ADD pcc_son varchar(7);
ALTER TABLE entitys ADD son varchar(7);
ALTER TABLE entitys ADD change_pcc varchar(7);
ALTER TABLE entitys ADD change_son varchar(7);
ALTER TABLE entitys ADD birth_date date;
ALTER TABLE entitys ADD shipping text;
ALTER TABLE entitys ADD phone_ph boolean default true;
ALTER TABLE entitys ADD phone_pa boolean default false;
ALTER TABLE entitys ADD phone_pb boolean default false;
ALTER TABLE entitys ADD phone_pt boolean default false;
ALTER TABLE entitys ADD last_login timestamp;
ALTER TABLE entitys ADD user_status integer;
ALTER TABLE entitys ADD sms_alert boolean default false;
ALTER TABLE entitys ADD email_alert boolean default false;
ALTER TABLE entitys ADD newsletter boolean default false;

ALTER TABLE entitys ADD dob_email boolean default current_date;


CREATE TABLE change_pccs (
	change_pcc_id			serial primary key,
 	entity_id				integer references entitys,

 	son						varchar(7),
 	pcc						varchar(12),
 	change_son				varchar(7),
 	change_pcc				varchar(12),

 	approve_status			varchar(16) default 'Draft' not null,
 	workflow_table_id		integer,
 	application_date		timestamp default now(),
 	action_date				timestamp
);

CREATE TABLE towns (
	town_id					serial primary key,
	town_name				varchar(50),
	aramex					boolean
);
ALTER TABLE orgs ADD town_id integer references towns;
CREATE INDEX orgs_town_id ON orgs (town_id);

CREATE TABLE suppliers (
	supplier_id 			serial primary key,
	supplier_name			varchar(50),
	create_date				timestamp default now(),
	contact_name			varchar(64),
	email					varchar(240),
	website					varchar(240),
	address					text,
	details					text
);

CREATE TABLE product_category (
	product_category_id		serial primary key,
	product_category_name	varchar(100),
	details 				text,
	icon 					character varying(50)
);

CREATE TABLE products (
	product_id				serial primary key,
	product_category_id 	integer references product_category,
    supplier_id          	integer references suppliers,
	created_by				integer references entitys,				--logged in system user who did the insert\

	product_name			varchar(100),
	product_uprice			real,
	product_ucost			real,
	created					date not null default current_date,

	product_details 		text,
	terms					text,
	weight					real,
	remarks					text,

	is_active				boolean default false,
	updated_by			    integer references entitys,				--logged in system user who did the last update
	updated					timestamp default now(),

	narrative			    text,
    image                   varchar(50),

    details					text
);
CREATE INDEX products_product_category_id ON products (product_category_id);
CREATE INDEX products_supplier_id ON products (supplier_id);

CREATE TABLE orders (
	order_id 				serial primary key,
	entity_id 				integer not null references entitys,
	order_date				timestamp not null default current_timestamp,
	order_status			varchar(50) default 'Processing order',
	order_total_amount		real default 0 not null,
	shipping_cost			real default 0 not null,
	town_name				varchar(50),
	phone_no 				character varying(20),
	physical_address 		text,
	batch_no				integer,
	batch_date				date,
	details 				text
);
CREATE INDEX order_entity_id  ON entitys(entity_id);

CREATE TABLE order_details (
	order_details_id 		serial primary key,
	order_id				integer not null references orders,
	product_id 				integer not null references products,
	product_quantity		integer default 1 not null,
	product_uprice			real default 0 not null,
	status					varchar(20) NOT NULL default 'New'
);
CREATE INDEX order_product_id  ON order_details(product_id);
CREATE INDEX order_details_id  ON orders(order_id);

CREATE TABLE applicants (
	applicant_id			serial primary key,
	org_id 					integer references orgs,
	applicant_name  		varchar(50),
	applicant_email			varchar(50) not null,
	user_name  				varchar(120) not null;
	phone_no    			character varying(50)
	pseudo_code				varchar(4),
	son 					varchar(7),
	consultant_dob			date not null,
	status					varchar(20) default 'Pending',

 	approve_status			varchar(16) default 'Pending' not null,
 	workflow_table_id		integer,
 	application_date		timestamp default now(),
 	action_date				timestamp,

	details					text
);
CREATE INDEX applicants_org_id ON applicants (org_id);

CREATE TABLE points (
	points_id				serial  primary key,
	org_id 					integer references orgs,
	entity_id				integer references entitys,
	period_id				integer references periods,
	point_date				date,
	pcc                     varchar(4),
	son                     varchar(7),
	segments                real,
	amount                  real,
	points                  real default 0 not null,
	bonus                   real default 0 not null,
	approve_status 			character varying(16) DEFAULT 'Completed',
	workflow_table_id 		integer
);
CREATE INDEX points_org_id ON points (org_id);
CREATE INDEX points_entity_id ON points (entity_id);
CREATE INDEX points_period_id ON points (period_id);
CREATE INDEX points_pcc ON points (pcc);

CREATE TABLE bonus (
 	bonus_id				serial primary key,
 	consultant_id			integer references entitys,
 	period_id				integer references periods,
 	entity_id				integer references entitys,
 	org_id					integer references orgs,

 	son						varchar(7),
 	pcc						varchar(12),
 	start_date				date,
 	end_date				date,
 	percentage 				real,
 	amount					real,
 	is_active				boolean default false,

 	approve_status			varchar(16) default 'Completed' not null,
 	workflow_table_id		integer,
 	application_date		timestamp default now(),
 	action_date				timestamp,

 	details					text
);
CREATE INDEX bonus_consultant_id ON bonus(consultant_id);
CREATE INDEX bonus_period_id ON bonus(period_id);
CREATE INDEX bonus_entity_id ON bonus(entity_id);
CREATE INDEX bonus_org_id ON bonus(org_id);

DROP VIEW vw_entitys;
DROP VIEW vw_orgs;

CREATE OR REPLACE VIEW vw_orgs AS
SELECT orgs.org_id, orgs.org_name, orgs.is_default, orgs.is_active, orgs.logo,
		orgs.pcc,orgs.account_manager_id, towns.town_id, towns.town_name,
		entitys.entity_name as account_manager_name,
		vw_org_address.org_sys_country_id, vw_org_address.org_sys_country_name,
		vw_org_address.org_address_id, vw_org_address.org_table_name,
		vw_org_address.org_post_office_box, vw_org_address.org_postal_code,
		vw_org_address.org_premises, vw_org_address.org_street, vw_org_address.org_town,
		vw_org_address.org_phone_number, vw_org_address.org_extension,
		vw_org_address.org_mobile, vw_org_address.org_fax, vw_org_address.org_email, vw_org_address.org_website
	FROM orgs LEFT JOIN vw_org_address ON orgs.org_id = vw_org_address.org_table_id
		LEFT JOIN towns ON orgs.town_id = towns.town_id
		LEFT JOIN entitys ON orgs.account_manager_id = entitys.entity_id;

	CREATE OR REPLACE VIEW vw_entitys AS
		SELECT vw_orgs.org_id, vw_orgs.org_name, vw_orgs.is_default as org_is_default,
		vw_orgs.is_active as org_is_active, vw_orgs.logo as org_logo,
		vw_orgs.pcc, vw_orgs.town_id, vw_orgs.town_name,
		vw_orgs.account_manager_id,vw_orgs.account_manager_name,

		vw_orgs.org_sys_country_id, vw_orgs.org_sys_country_name,
		vw_orgs.org_address_id, vw_orgs.org_table_name,
		vw_orgs.org_post_office_box, vw_orgs.org_postal_code,
		vw_orgs.org_premises, vw_orgs.org_street, vw_orgs.org_town,
		vw_orgs.org_phone_number, vw_orgs.org_extension,
		vw_orgs.org_mobile, vw_orgs.org_fax, vw_orgs.org_email, vw_orgs.org_website,

		vw_entity_address.address_id, vw_entity_address.address_name,
		vw_entity_address.sys_country_id, vw_entity_address.sys_country_name, vw_entity_address.table_name,
		vw_entity_address.is_default, vw_entity_address.post_office_box, vw_entity_address.postal_code,
		vw_entity_address.premises, vw_entity_address.street, vw_entity_address.town,
		vw_entity_address.phone_number, vw_entity_address.extension, vw_entity_address.mobile,
		vw_entity_address.fax, vw_entity_address.email, vw_entity_address.website,

		entitys.entity_id, entitys.entity_name, entitys.user_name, entitys.super_user, entitys.entity_leader,
		entitys.date_enroled, entitys.is_active, entitys.entity_password, entitys.first_password,
		entitys.function_role, entitys.primary_email, entitys.primary_telephone,
		entitys.salutation, entitys.son,entitys.birth_date,entitys.last_login,
		entity_types.entity_type_id, entity_types.entity_type_name,
		entity_types.entity_role, entity_types.use_key,vw_orgs.pcc||'-'||entitys.son as pcc_son,vw_orgs.pcc||'-'||entitys.son||'-'||entity_name as pcc_son_name,
		entitys.dob_email, entitys.svcb_son, entitys.can_redeem
		FROM (entitys LEFT JOIN vw_entity_address ON entitys.entity_id = vw_entity_address.table_id)
		INNER JOIN vw_orgs ON entitys.org_id = vw_orgs.org_id
		INNER JOIN entity_types ON entitys.entity_type_id = entity_types.entity_type_id;

CREATE OR REPLACE VIEW vw_products AS
	SELECT products.product_id, products.product_name, products.product_details, products.product_uprice,
		products.created, products.updated_by,products.image, suppliers.supplier_name, suppliers.supplier_id,
		product_category.product_category_id,
		product_category.product_category_name,products.is_active
	FROM products JOIN suppliers ON products.supplier_id = suppliers.supplier_id
		JOIN product_category ON products.product_category_id=product_category.product_category_id;

CREATE OR REPLACE VIEW vw_orders AS
    SELECT orders.order_id, orders.order_date, orders.order_status, orders.order_total_amount, orders.batch_no,
        orders.shipping_cost, orders.details,
        (orders.order_total_amount + orders.shipping_cost) as grand_total,
        orders.town_name, vw_entitys.org_premises, vw_entitys.org_street,
        vw_entitys.entity_name, vw_entitys.son,
        vw_entitys.entity_id, vw_entitys.pcc, vw_entitys.org_name, vw_entitys.primary_email,
        vw_entitys.primary_telephone, vw_entitys.function_role, vw_entitys.entity_role,
        vw_entitys.org_id, orders.physical_address, orders.phone_no,vw_entitys.user_name, vw_entitys.is_active
    FROM orders JOIN vw_entitys ON orders.entity_id = vw_entitys.entity_id;

CREATE OR REPLACE VIEW vw_pccs AS
	SELECT orgs.org_id, orgs.org_name,	orgs.is_default, orgs.is_active,
		orgs.logo, orgs.details, pccs.pcc, pccs.agency_name, pccs.iata_agent,
		pccs.agency_incentive, pccs.incentive_son
	FROM pccs INNER JOIN orgs ON pccs.pcc = orgs.pcc;

CREATE OR REPLACE VIEW vw_order_details AS
	SELECT order_details.order_details_id, vw_orders.order_id, vw_orders.order_date, vw_orders.order_status,
		vw_orders.org_id, vw_orders.org_name, vw_products.product_id, vw_products.product_name,
		vw_products.supplier_name, vw_products.supplier_id, vw_products.product_category_id,
		vw_products.product_category_name,vw_products.image, vw_orders.entity_name, vw_orders.entity_id,
		vw_orders.batch_no, order_details.product_uprice, order_details.product_quantity,
		(order_details.product_uprice * order_details.product_quantity) as total_amount
	FROM order_details JOIN vw_orders ON order_details.order_id = vw_orders.order_id
		JOIN vw_products ON vw_products.product_id = order_details.product_id;

CREATE VIEW vw_applicants AS
	SELECT applicants.applicant_id, applicants.applicant_email, cast(applicants.application_date as date),
		applicants.pseudo_code, applicants.son, applicants.approve_status,
		applicants.status, applicants.consultant_dob, applicants.details
	FROM applicants;

CREATE OR REPLACE VIEW vw_consultant AS
	SELECT vw_entitys.entity_id,vw_entitys.user_name, vw_entitys.primary_email, vw_entitys.date_enroled::date AS application_date,
		vw_entitys.pcc, vw_entitys.org_name, vw_entitys.entity_name, vw_entitys.is_active,
		vw_entitys.son, vw_entitys.is_active as approved,
		vw_entitys.birth_date
	FROM vw_entitys;

CREATE OR REPLACE VIEW vw_purged_consultant AS
	SELECT vw_entitys.entity_id,vw_entitys.user_name, vw_entitys.primary_email, cast(vw_entitys.date_enroled as date),
		vw_entitys.pcc, vw_entitys.org_name, vw_entitys.entity_name,vw_entitys.last_login, vw_entitys.is_active,
		vw_entitys.son, vw_entitys.account_manager_id,vw_entitys.account_manager_name, vw_entitys.is_active as approved,
		MAX(periods.end_date)as end_date, vw_entitys.birth_date
	FROM  vw_entitys
		LEFT JOIN points ON vw_entitys.entity_id = points.entity_id
		LEFT JOIN periods ON points.period_id = periods.period_id
	WHERE points.point_date < CURRENT_DATE - INTERVAL '6 months'
	GROUP BY vw_entitys.entity_id,vw_entitys.user_name, vw_entitys.primary_email, cast(vw_entitys.date_enroled as date),
		vw_entitys.pcc, vw_entitys.org_name, vw_entitys.entity_name, vw_entitys.is_active,
		vw_entitys.son, vw_entitys.last_login, vw_entitys.is_active, vw_entitys.account_manager_id,vw_entitys.account_manager_name,
		 vw_entitys.birth_date;

CREATE OR REPLACE VIEW vw_points AS
	SELECT points.points_id, points.period_id,points.org_id, periods.start_date as period,
		to_char(periods.start_date, 'mmyyyy'::text) AS ticket_period,
		points.entity_id, points.pcc, points.son, points.segments, points.amount,
		points.points, points.bonus, vw_entitys.org_name,
		vw_entitys.entity_name, vw_entitys.user_name
		FROM points JOIN vw_entitys ON points.entity_id = vw_entitys.entity_id
			INNER JOIN periods ON points.period_id = periods.period_id;

CREATE OR REPLACE VIEW vw_org_points AS
	SELECT periods.period_id, periods.start_date AS period, to_char(periods.start_date::timestamp with time zone, 'mmyyyy'::text) AS ticket_period,
		vw_orgs.pcc, COALESCE(SUM(points.segments),0.0) AS segments, COALESCE(SUM(points.points),0.0) AS points,
		COALESCE(SUM(points.bonus),0.0) AS bonus, vw_orgs.org_id,vw_orgs.org_name, COALESCE(count(points.son), 0::int) AS son,points.amount,
		vw_orgs.account_manager_id,vw_orgs.account_manager_name
	FROM points
	 JOIN vw_orgs ON points.org_id = vw_orgs.org_id
	 JOIN periods ON points.period_id = periods.period_id WHERE periods.approve_status = 'Approved'
	 GROUP BY periods.period_id,periods.start_date,vw_orgs.pcc,vw_orgs.account_manager_id,vw_orgs.account_manager_name,vw_orgs.org_id,vw_orgs.org_name,periods.approve_status,points.amount
	ORDER BY period desc;

CREATE OR REPLACE VIEW vw_son_points AS
SELECT points.points_id, periods.period_id, periods.start_date as period,
	to_char(periods.start_date, 'mmyyyy'::text) AS ticket_period,
	points.pcc, points.son, points.segments, points.amount,
	points.points, points.bonus, vw_entitys.org_name,
	vw_entitys.entity_name, vw_entitys.entity_id,vw_entitys.user_name,  vw_entitys.pcc AS org_pcc,
vw_entitys.son AS org_son,  vw_entitys.is_active, vw_entitys.account_manager_id, vw_entitys.org_id,vw_entitys.function_role
FROM points JOIN vw_entitys ON points.entity_id = vw_entitys.entity_id
	INNER JOIN periods ON points.period_id = periods.period_id
	WHERE periods.approve_status = 'Approved';

	CREATE OR REPLACE VIEW vw_balance AS
	 SELECT a.dr, a.cr, a.order_date::date, a.org_id,a.son, a.pcc, a.entity_id, a.dr + a.bonus - a.cr AS balance, a.bonus
	   FROM ( SELECT COALESCE(vw_son_points.points, 0::real) AS dr,   0::real AS cr, vw_son_points.period AS order_date,
	            vw_son_points.org_id,vw_son_points.son, vw_son_points.pcc, vw_son_points.entity_id, COALESCE(vw_son_points.bonus, 0::real) AS bonus
	           FROM vw_son_points
	        UNION ALL
	         SELECT 0::real AS float4, vw_orders.grand_total AS order_total_amount, vw_orders.order_date, vw_orders.org_id, vw_orders.son,
	            vw_orders.pcc, vw_orders.entity_id,  0::real AS bonus
	               FROM vw_orders ) a
	  ORDER BY a.order_date DESC;

CREATE OR REPLACE FUNCTION get_order_details(integer) RETURNS text AS $$
DECLARE
    rec                        RECORD;
    order_detail            	text;
BEGIN

    order_detail := '';
    FOR rec IN SELECT (vw_order_details.product_quantity || ' @ ' || vw_order_details.product_name ) as details
    FROM vw_order_details WHERE order_id = $1 LOOP
        order_detail := order_detail || ' ' || rec.details;
    END LOOP;

    order_detail := order_detail || ' added to shopping cart';
    order_detail := trim(order_detail);

    return order_detail;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE VIEW vw_son_statement AS
SELECT a.dr, a.cr, a.order_date, a.son, a.pcc,
		a.org_name, a.entity_id, a.dr+ a.bonus - a.cr AS balance, a.details, a.batch_no,a.bonus
	FROM ((SELECT (COALESCE(vw_son_points.points, 0::real) ) AS dr,0::real AS cr, vw_son_points.period AS order_date, vw_son_points.son,
		vw_son_points.pcc, vw_son_points.org_name, vw_son_points.entity_id,
		('Earnings @ Ksh '||amount||' per segment for '|| segments||' segments sold in '|| ticket_period)as details,
		NULL::integer AS batch_no, (COALESCE(vw_son_points.bonus, 0::real)) as bonus
	FROM vw_son_points)
	UNION ALL
	(SELECT 0::real AS float4, vw_orders.grand_total::real AS order_total_amount,
		vw_orders.order_date, vw_orders.son, vw_orders.pcc, vw_orders.org_name,
		vw_orders.entity_id,
		get_order_details(vw_orders.order_id) AS details,
		batch_no, 0::real as bonus
	FROM vw_orders)) a
	ORDER BY a.order_date;

CREATE VIEW vw_all_bonus AS
	SELECT bonus.bonus_id, bonus.entity_id, bonus.percentage, bonus.is_active,
		bonus.amount, bonus.period_id, vw_entitys.entity_name, vw_entitys.is_active as entity_active,
		vw_entitys.son, vw_entitys.pcc, vw_entitys.org_name, vw_entitys.org_id,
		to_char(periods.start_date::timestamp with time zone, 'mmYYYY'::text) AS period
	FROM bonus JOIN vw_entitys ON bonus.pcc = vw_entitys.pcc
		JOIN periods ON bonus.period_id = periods.period_id;

CREATE VIEW vw_son_bonus AS
	SELECT bonus.bonus_id, bonus.entity_id, bonus.percentage, bonus.is_active,
		bonus.amount, bonus.period_id, vw_entitys.entity_name,
		vw_entitys.is_active as entity_active, vw_entitys.son,
		vw_entitys.pcc, vw_entitys.org_name, vw_entitys.org_id,
		to_char(periods.start_date::timestamp with time zone, 'mmYYYY'::text) AS period
	FROM bonus JOIN vw_entitys ON bonus.entity_id = vw_entitys.entity_id
		JOIN periods ON bonus.period_id = periods.period_id;

CREATE VIEW vw_org_bonus AS
	SELECT bonus.bonus_id, bonus.percentage, bonus.is_active,
		bonus.amount, bonus.period_id, bonus.pcc,
		bonus.approve_status, vw_orgs.org_name,
		to_char(periods.start_date::timestamp with time zone, 'mmYYYY'::text) AS period
	FROM bonus JOIN vw_orgs ON bonus.org_id = vw_orgs.org_id
		JOIN periods ON bonus.period_id = periods.period_id
	WHERE bonus.entity_id is null;

	CREATE OR REPLACE VIEW vw_pcc_statement AS
	SELECT a.dr, a.cr, a.org_id, a.order_date::date, a.pcc,
			a.org_name, a.dr+a.bonus - a.cr AS balance, a.details, a.batch_no,a.bonus
		FROM ((SELECT COALESCE(vw_org_points.points, 0::real) AS dr,
			0::real AS cr, vw_org_points.period AS order_date, ''::text,
			vw_org_points.pcc, vw_org_points.org_name, 0::integer,vw_org_points.org_id,
			( 'Earnings @ Ksh '||amount||' per segment for '|| segments||' segments sold in '|| ticket_period)as details,
	        NULL::integer AS batch_no,COALESCE(vw_org_points.bonus, 0::real) as bonus
		FROM vw_org_points)
		UNION
		(SELECT 0::real AS float4, vw_orders.grand_total::real AS order_total_amount,
			vw_orders.order_date, vw_orders.son, vw_orders.pcc, vw_orders.org_name,
			vw_orders.entity_id,vw_orders.org_id,
			get_order_details(vw_orders.order_id) AS details,batch_no,0::real as bonus
		FROM vw_orders)) a
		ORDER BY a.order_date;


CREATE OR REPLACE VIEW vw_bonus AS
 SELECT bonus.bonus_id,  bonus.consultant_id, bonus.period_id, bonus.entity_id, bonus.org_id, bonus.son, vw_entitys.entity_name as bonus_name,
    bonus.pcc, bonus.start_date, bonus.end_date, bonus.percentage, bonus.amount, bonus.is_active, bonus.approve_status,
    bonus.workflow_table_id, bonus.application_date, bonus.action_date, bonus.details,  vw_entitys.org_name, orgs.account_manager_id,
     vw_entitys.user_name, periods.fiscal_year_id || ' Market Bonus' AS market_name, orgs.org_name as bonus_org_name
   FROM bonus LEFT JOIN periods ON periods.period_id = bonus.period_id
	LEFT JOIN orgs ON orgs.pcc = bonus.pcc
	LEFT JOIN vw_entitys ON vw_entitys.entity_id = bonus.entity_id;


CREATE OR REPLACE VIEW vw_opening_balance AS
SELECT a.dr, a.cr, a.order_date::date AS order_date, a.son, a.pcc, a.org_name, a.entity_id, a.entity_name,
a.dr - a.cr AS balance, a.points, a.segments, a.amount, a.period,a.is_active
FROM ((SELECT COALESCE(vw_son_points.points, 0::real) + COALESCE(vw_son_points.bonus, 0::real) AS dr,
		   0::real AS cr, vw_son_points.period AS order_date, vw_son_points.org_son as son, vw_son_points.org_pcc as pcc,
		   vw_son_points.org_name, vw_son_points.entity_id, vw_son_points.entity_name, vw_son_points.segments,
		   vw_son_points.amount, vw_son_points.points, vw_son_points.period,vw_son_points.is_active
		  FROM vw_son_points)
	   UNION
		(SELECT 0::real AS float4,
		   vw_orders.grand_total AS order_total_amount, vw_orders.order_date, vw_orders.son, vw_orders.pcc,
		   vw_orders.org_name, vw_orders.entity_id, vw_orders.entity_name, 0::real as segments, 0::real as amount,
		   0::real as points,  null::date as period,vw_orders.is_active
		  FROM vw_orders)) a
ORDER BY a.order_date;


CREATE OR REPLACE VIEW vw_approvals_entitys AS
 SELECT vw_workflow_phases.workflow_id,
    vw_workflow_phases.workflow_name,
    vw_workflow_phases.source_entity_id,
    vw_workflow_phases.source_entity_name,
    vw_workflow_phases.approval_entity_id,
    vw_workflow_phases.approval_entity_name,
    vw_workflow_phases.workflow_phase_id,
    vw_workflow_phases.approval_level,
    vw_workflow_phases.notice,
    vw_workflow_phases.notice_email,
    vw_workflow_phases.notice_file,
    vw_workflow_phases.advice,
    vw_workflow_phases.advice_email,
    vw_workflow_phases.advice_file,
    vw_workflow_phases.return_level,
    vw_workflow_phases.required_approvals,
    vw_workflow_phases.phase_narrative,
    vw_workflow_phases.use_reporting,
    approvals.approval_id,
    approvals.org_id,
    approvals.forward_id,
    approvals.table_name,
    approvals.table_id,
    approvals.completion_date,
    approvals.escalation_days,
    approvals.escalation_hours,
    approvals.escalation_time,
    approvals.application_date,
    approvals.approve_status,
    approvals.action_date,
    approvals.approval_narrative,
    approvals.to_be_done,
    approvals.what_is_done,
    approvals.review_advice,
    approvals.details,
    oe.entity_id AS org_entity_id,
    oe.entity_name AS org_entity_name,
    oe.user_name AS org_user_name,
    oe.primary_email AS org_primary_email,
    vw_entitys.entity_id,
    vw_entitys.entity_name,
    vw_entitys.user_name,
    vw_entitys.primary_email,
    oe.org_name,
    oe.pcc
   FROM vw_workflow_phases
     JOIN approvals ON vw_workflow_phases.workflow_phase_id = approvals.workflow_phase_id
     JOIN vw_entitys oe ON approvals.org_entity_id = oe.entity_id
     JOIN entity_subscriptions ON vw_workflow_phases.approval_entity_id = entity_subscriptions.entity_type_id
     JOIN vw_entitys ON entity_subscriptions.entity_id = vw_entitys.entity_id
  WHERE approvals.forward_id IS NULL AND vw_workflow_phases.use_reporting = false
UNION
 SELECT vw_workflow_phases.workflow_id,
    vw_workflow_phases.workflow_name,
    vw_workflow_phases.source_entity_id,
    vw_workflow_phases.source_entity_name,
    vw_workflow_phases.approval_entity_id,
    vw_workflow_phases.approval_entity_name,
    vw_workflow_phases.workflow_phase_id,
    vw_workflow_phases.approval_level,
    vw_workflow_phases.notice,
    vw_workflow_phases.notice_email,
    vw_workflow_phases.notice_file,
    vw_workflow_phases.advice,
    vw_workflow_phases.advice_email,
    vw_workflow_phases.advice_file,
    vw_workflow_phases.return_level,
    vw_workflow_phases.required_approvals,
    vw_workflow_phases.phase_narrative,
    vw_workflow_phases.use_reporting,
    approvals.approval_id,
    approvals.org_id,
    approvals.forward_id,
    approvals.table_name,
    approvals.table_id,
    approvals.completion_date,
    approvals.escalation_days,
    approvals.escalation_hours,
    approvals.escalation_time,
    approvals.application_date,
    approvals.approve_status,
    approvals.action_date,
    approvals.approval_narrative,
    approvals.to_be_done,
    approvals.what_is_done,
    approvals.review_advice,
    approvals.details,
    oe.entity_id AS org_entity_id,
    oe.entity_name AS org_entity_name,
    oe.user_name AS org_user_name,
    oe.primary_email AS org_primary_email,
    vw_entitys.entity_id,
    vw_entitys.entity_name,
    vw_entitys.user_name,
    vw_entitys.primary_email,
    oe.org_name,
    oe.pcc
   FROM vw_workflow_phases
     JOIN approvals ON vw_workflow_phases.workflow_phase_id = approvals.workflow_phase_id
     JOIN vw_entitys oe ON approvals.org_entity_id = oe.entity_id
     JOIN reporting ON approvals.org_entity_id = reporting.entity_id AND vw_workflow_phases.reporting_level = reporting.reporting_level
     JOIN vw_entitys ON reporting.report_to_id = vw_entitys.entity_id
  WHERE approvals.forward_id IS NULL AND reporting.primary_report = true AND reporting.is_active = true AND vw_workflow_phases.use_reporting = true;
