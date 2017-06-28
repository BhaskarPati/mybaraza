---Project Database File

ALTER TABLE entitys ADD client_dob date;
ALTER TABLE entitys ADD COLUMN workflow_table_id integer;
ALTER TABLE entitys ADD COLUMN approve_status character varying(16);
ALTER TABLE entitys ALTER COLUMN approve_status SET DEFAULT 'Completed'::character varying;
ALTER TABLE entitys ADD COLUMN action_date timestamp without time zone;
ALTER TABLE entitys ADD CONSTRAINT primary_email UNIQUE (primary_email);

CREATE TABLE clients (
	client_id			    serial primary key,
	org_id 					integer references orgs,
	client_email			varchar(50) not null,
	user_name  				varchar(120) not null,
	phone_no    			character varying(50),
	client_code			    varchar(50),
	client_name 			varchar(50),
	client_dob			    date not null,
	ar_status				varchar(20) default 'Pending',
    ar_type                 varchar(20),
    created_by              integer,
	approve_status			varchar(16) default 'Completed' not null,
	workflow_table_id		integer,
	created_on        		timestamp default now(),
	action_date				timestamp,
	details					text
);
CREATE INDEX clients_org_id ON clients (org_id);

CREATE TABLE loyalty_points (
	loyalty_points_id		serial  primary key,
	org_id 					integer references orgs,
	entity_id				integer references entitys,
	period_id				integer references periods,
	point_date				date,
	segments                real default 0 not null,
	amount                  real default 0 not null,
	points					real default 0 not null,
	points_amount           real default 0 not null,
	refunds 				real default 0 not null,
	tours_amount 			real default 0 not null,
	bonus                   real default 0 not null,
	sectors 				character varying(100),
	ticket_number 			character varying(30),
	local_inter 			character varying(2),
	client_code 			character varying(50),
	loyalty_curr 			character varying(10),
	invoice_number 			character varying(50),
	is_return 				boolean default true not null,
	approve_status 			character varying(16) DEFAULT 'Completed',
	workflow_table_id 		integer
);
CREATE INDEX loyalty_points_org_id ON loyalty_points (org_id);
CREATE INDEX loyalty_points_entity_id ON loyalty_points (entity_id);
CREATE INDEX loyalty_points_period_id ON loyalty_points (period_id);

CREATE TABLE bonus (
	bonus_id				serial primary key,
	period_id				integer references periods,
	entity_id				integer references entitys,
	org_id					integer references orgs,
	start_date				date,
	end_date				date,
	percentage 				real,
	amount					real,
	is_active				boolean default false,

	approve_status			varchar(16) default 'Approved' not null,
	workflow_table_id		integer,
	application_date		timestamp default now(),
	action_date				timestamp,

	details					text
);
CREATE INDEX bonus_period_id ON bonus(period_id);
CREATE INDEX bonus_entity_id ON bonus(entity_id);
CREATE INDEX bonus_org_id ON bonus(org_id);


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
	org_id 					integer references orgs,
	entity_id 				integer not null references entitys,
	client_code 			varchar(20),
	points 					real default 0 not null,
	order_amount			real default 0 not null,
	shipping_cost			real default 0 not null,
	points_value 			integer,
	order_date				timestamp not null default current_timestamp,
	order_status			varchar(50) default 'Processing order',
	town_name				varchar(50),
	phone_no 				character varying(20),
	physical_address 		text,
	batch_no				integer,
	batch_date				date,
	workflow_table_id       integer,
	approve_status 			character varying(16) DEFAULT 'Draft',
	action_date 			timestamp without time zone,
	details 				text
);
CREATE INDEX order_entity_id  ON orders(entity_id);
CREATE INDEX orders_org_id ON orders (org_id);

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

CREATE TABLE sambaza (
	sambaza_id 				serial primary key,
	org_id 					integer references orgs,
	entity_id 				integer not null references entitys,
	client_code				varchar(20) not null,
	sambaza_in				real default 0 not null,
	sambaza_out				real default 0 not null,
	sambaza_status			varchar(50) default 'Completed',
	sambaza_date			timestamp not null default current_timestamp,
	details 				text
);
CREATE INDEX sambaza_entity_id  ON sambaza(entity_id);
CREATE INDEX sambaza_org_id  ON sambaza(org_id);

CREATE TABLE donation (
	donation_id 			serial primary key,
	org_id 					integer references orgs,
	entity_id 				integer not null references entitys,
	donated_by				integer not null references entitys,
	donation_amount			real default 0 not null,
	donation_status			varchar(50) default 'Completed',
	donation_date			timestamp not null default current_timestamp,
	details 				text
);
CREATE INDEX donation_entity_id  ON donation(entity_id);
CREATE INDEX donation_org_id  ON donation(org_id);
CREATE INDEX donation_donated_by  ON donation(donated_by);



CREATE OR REPLACE FUNCTION ins_sambaza() RETURNS trigger AS $$
DECLARE
	rec 			RECORD;
	v_entity_id		integer;
BEGIN
	IF (TG_OP = 'INSERT') THEN
		SELECT entity_id INTO v_entity_id
		FROM entitys
		WHERE (trim(lower(client_code)) = trim(lower(NEW.client_code)));
		IF(v_entity_id is null)THEN
			RAISE EXCEPTION 'The Client does not exists';
		END IF;
		INSERT INTO sambaza (org_id, entity_id, client_code, sambaza_in)
		VALUES (0, v_entity_id, NEW.client_code, NEW.sambaza_out);
	END IF;
	RETURN NEW;
END;
$$
  LANGUAGE plpgsql ;
CREATE TRIGGER ins_sambaza  AFTER INSERT  ON sambaza
  FOR EACH ROW
  EXECUTE PROCEDURE ins_sambaza();



CREATE TABLE booking_types (
		booking_type_id 		serial primary key,
		booking_type_name		character varying(20),
		details 				text
);
CREATE TABLE class_categorys (
		class_id		 		serial primary key,
		booking_type_id			integer references booking_types,
		class_name				character varying(20),
		details 				text
);
CREATE TABLE points_scaling (
		scaling_id		 		serial primary key,
		class_id				integer references class_categorys,
		one_way					real,
		isreturn				real,
		start_date				date,
		end_date				date,
		code 					character varying(10),
		details 				text
);
CREATE INDEX class_categorys_booking_type_id  ON class_categorys(booking_type_id);
CREATE INDEX points_scaling_class_id  ON points_scaling(class_id);
CREATE TABLE points_value (
		point_value_id		 		serial primary key,
		point_value					real,
		start_date				date,
		end_date				date,
		details 				text
);

CREATE TABLE user_guide(
	guide_id serial PRIMARY KEY,
	title varchar(50),
	org_id integer references orgs,
	guide       text

);

CREATE OR REPLACE VIEW vw_booking_type_class AS
	SELECT c.class_id, c.class_name, c.details, b.booking_type_id, b.booking_type_name
	FROM  class_categorys c
	INNER JOIN booking_types b ON b.booking_type_id = c. booking_type_id;

CREATE OR REPLACE VIEW vw_points_scaling AS
	SELECT c.class_id, c.class_name, c.details, c.booking_type_id, c.booking_type_name,
		p.scaling_id, p.one_way, p.isreturn, p.start_date, p.end_date,p.code
	FROM points_scaling p
	INNER JOIN vw_booking_type_class c ON c.class_id = p. class_id;


CREATE OR REPLACE VIEW vw_entitys AS
	SELECT vw_orgs.org_id, vw_orgs.org_name, vw_orgs.is_default as org_is_default,
		vw_orgs.is_active as org_is_active, vw_orgs.logo as org_logo,

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
		entity_types.entity_type_id, entity_types.entity_type_name,
		entity_types.entity_role, entity_types.use_key, entitys.client_code
	FROM (entitys LEFT JOIN vw_entity_address ON entitys.entity_id = vw_entity_address.table_id)
		INNER JOIN vw_orgs ON entitys.org_id = vw_orgs.org_id
		INNER JOIN entity_types ON entitys.entity_type_id = entity_types.entity_type_id;

CREATE OR REPLACE VIEW vw_orders AS
    SELECT orders.order_id, orders.order_date, orders.order_status, orders.points, orders.order_amount, orders.batch_no,
        orders.shipping_cost, orders.details, (orders.order_amount + orders.shipping_cost) as grand_total,
        orders.town_name, vw_entitys.org_premises, vw_entitys.org_street, vw_entitys.entity_name, vw_entitys.client_code,
        vw_entitys.entity_id, vw_entitys.org_name, vw_entitys.primary_email, vw_entitys.primary_telephone,
		vw_entitys.function_role, vw_entitys.entity_role, vw_entitys.org_id, orders.physical_address, orders.phone_no,orders.approve_status
    FROM orders JOIN vw_entitys ON orders.entity_id = vw_entitys.entity_id;

CREATE OR REPLACE VIEW vw_products AS
	SELECT products.product_id, products.product_name, products.product_details, products.product_uprice,
		products.created, products.updated_by,products.image, suppliers.supplier_name, suppliers.supplier_id,
		product_category.product_category_id,
		product_category.product_category_name,products.is_active
	FROM products JOIN suppliers ON products.supplier_id = suppliers.supplier_id
		JOIN product_category ON products.product_category_id=product_category.product_category_id;

CREATE OR REPLACE VIEW vw_order_details AS
	SELECT order_details.order_details_id, vw_orders.order_id, vw_orders.order_date, vw_orders.order_status,
		vw_orders.org_id, vw_orders.org_name, vw_products.product_id, vw_products.product_name,
		vw_products.supplier_name, vw_products.supplier_id, vw_products.product_category_id,
		vw_products.product_category_name,vw_products.image, vw_orders.entity_name, vw_orders.entity_id,
		vw_orders.batch_no, order_details.product_uprice, order_details.product_quantity,
		(order_details.product_uprice * order_details.product_quantity) as total_amount
	FROM order_details JOIN vw_orders ON order_details.order_id = vw_orders.order_id
		JOIN vw_products ON vw_products.product_id = order_details.product_id;

CREATE OR REPLACE VIEW vw_loyalty_points AS
	SELECT loyalty_points.loyalty_points_id, periods.period_id, periods.start_date as period, to_char(periods.start_date, 'mmyyyy'::text) AS ticket_period,
		vw_entitys.client_code, loyalty_points.segments, loyalty_points.amount, loyalty_points.points,	loyalty_points.points_amount,loyalty_points.tours_amount,
		loyalty_points.bonus, vw_entitys.org_name, vw_entitys.entity_name, vw_entitys.entity_id,vw_entitys.user_name,
		loyalty_points.point_date, loyalty_points.ticket_number, loyalty_points.invoice_number, loyalty_points.approve_status, loyalty_points.refunds,
		periods.end_date, loyalty_points.local_inter, loyalty_points.is_return
	FROM loyalty_points JOIN vw_entitys ON loyalty_points.entity_id = vw_entitys.entity_id
	INNER JOIN periods ON loyalty_points.period_id = periods.period_id;

CREATE OR REPLACE VIEW vw_sambaza AS
 SELECT sambaza.sambaza_id, sambaza.sambaza_in, sambaza.sambaza_out, sambaza.details,
    sambaza.sambaza_date, sambaza.sambaza_status, vw_entitys.entity_name, vw_entitys.client_code, vw_entitys.entity_id,
    vw_entitys.org_name, vw_entitys.primary_email, vw_entitys.primary_telephone, vw_entitys.function_role,
    vw_entitys.entity_role, vw_entitys.org_id
   FROM sambaza
     JOIN vw_entitys ON sambaza.entity_id = vw_entitys.entity_id;

CREATE OR REPLACE VIEW vw_donation AS
SELECT donation.donation_id, donation.donation_amount, donation.details,
donation.donation_date, donation.donation_status, vw_entitys.entity_name, vw_entitys.client_code, donation.entity_id,
vw_entitys.org_name, vw_entitys.primary_email, vw_entitys.primary_telephone, vw_entitys.function_role,
vw_entitys.entity_role, vw_entitys.org_id,donation.donated_by
FROM donation
JOIN vw_entitys ON donation.donated_by = vw_entitys.entity_id;


CREATE OR REPLACE VIEW vw_client_statement AS
SELECT a.dr, a.cr, a.order_date::date, a.client_code, a.org_name, a.entity_id,
	 (a.dr +a.tours_amount- a.cr - a.donated_amount - a.refunds) AS balance, a.donated_amount, a.details, a.refunds, a.entity_name,
	 a.tours_amount
	FROM ((SELECT COALESCE(vw_loyalty_points.points, 0::real) + COALESCE(vw_loyalty_points.bonus, 0::real) AS dr,
		0::real AS cr, vw_loyalty_points.period AS order_date, vw_loyalty_points.client_code,
		vw_loyalty_points.org_name, vw_loyalty_points.entity_id,
		0::real as donated_amount, COALESCE(vw_loyalty_points.refunds, 0::real) AS refunds, ''::text as details, vw_loyalty_points.entity_name,
		vw_loyalty_points.tours_amount
	FROM vw_loyalty_points)
	UNION ALL
	(SELECT 0::real AS dr, vw_orders.points::real AS cr, vw_orders.order_date,
	vw_orders.client_code, vw_orders.org_name, vw_orders.entity_id,
	0::real as donated_amount, 0::real AS refunds, ''::text as details, vw_orders.entity_name,
	0::real AS tours_amount
	FROM vw_orders)
	UNION ALL
	(SELECT 0::real as dr, 0::real as cr, vw_donation.donation_date,
	vw_donation.client_code, vw_donation.org_name, vw_donation.donated_by as entity_id, COALESCE(vw_donation.donation_amount,0::real) as donated_amount,
	0::real AS refunds, vw_donation.details, vw_donation.entity_name,0::real AS tours_amount
	 FROM vw_donation)) a
	ORDER BY a.order_date;


CREATE OR REPLACE VIEW vw_csr_statement AS
SELECT a.dr, a.cr, a.order_date::date, a.client_code, a.org_name, a.entity_id,
	 (a.dr+a.tours_amount - a.cr + a.donated_amount - a.refunds) AS balance, a.donated_amount, a.details, a.refunds, a.entity_name
	FROM ((SELECT COALESCE(vw_loyalty_points.points, 0::real) + COALESCE(vw_loyalty_points.bonus, 0::real) AS dr,
		0::real AS cr, vw_loyalty_points.period AS order_date, vw_loyalty_points.client_code,
		vw_loyalty_points.org_name, vw_loyalty_points.entity_id,
		0::real as donated_amount, COALESCE(vw_loyalty_points.refunds, 0::real) AS refunds, ''::text as details, vw_loyalty_points.entity_name,
		vw_loyalty_points.tours_amount
	FROM vw_loyalty_points)
	UNION ALL
	(SELECT 0::real AS dr, vw_orders.points::real AS cr, vw_orders.order_date,
	vw_orders.client_code, vw_orders.org_name, vw_orders.entity_id,
	0::real as donated_amount, 0::real AS refunds, ''::text as details, vw_orders.entity_name,
	0::real AS tours_amount
	FROM vw_orders)
	UNION ALL
	(SELECT 0::real as dr, 0::real as cr, vw_donation.donation_date,
	vw_donation.client_code, vw_donation.org_name, vw_donation.entity_id, COALESCE(vw_donation.donation_amount,0::real) as donated_amount,
	0::real AS refunds, vw_donation.details, vw_donation.entity_name,
	0::real AS tours_amount
	 FROM vw_donation)) a
	ORDER BY a.order_date;
