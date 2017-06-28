DROP TRIGGER ins_orders ON orders;

-- load extension first time after install
CREATE EXTENSION mysql_fdw;

-- create server object
CREATE SERVER mysql_server
	FOREIGN DATA WRAPPER mysql_fdw OPTIONS (host '127.0.0.1', port '3306');

-- create user mapping
CREATE USER MAPPING FOR postgres SERVER mysql_server
OPTIONS (username 'root');

CREATE FOREIGN TABLE i_salutation (
	id_salutation			integer, 
	salutation			varchar(7), 
	"order"			integer
)
SERVER mysql_server OPTIONS(dbname 'faidaplus', table_name 'salutation');

CREATE FOREIGN TABLE i_staff (
	id_staff			integer, 
	"group"			char(7), 
	comp_position			varchar(37), 
	rel_id_salutation			integer, 
	first_name			varchar(22), 
	last_name			varchar(22), 
	other_name			varchar(37), 
	email			varchar(150), 
	cellphone			varchar(22), 
	landline			varchar(22), 
	shipping			text, 
	rel_id_staff			integer
)
SERVER mysql_server OPTIONS(dbname 'faidaplus', table_name 'staff');

CREATE FOREIGN TABLE i_consultant (
	id_consultant			integer, 
	rel_id_salutation			integer, 
	newsletter			char(1), 
	first_name			varchar(22), 
	last_name			varchar(22), 
	other_name			varchar(37), 
	email			varchar(150), 
	birthdate			DATE, 
	cellphone			varchar(22), 
	landline			varchar(22), 
	shipping			VARCHAR, 
	rel_pcc			varchar(3), 
	pcc			varchar(3), 
	son			varchar(2), 
	create_date			timestamp
)
SERVER mysql_server OPTIONS(dbname 'faidaplus', table_name 'consultant');

CREATE FOREIGN TABLE i_user (
	id_user			integer, 
	rel_id			integer, 
	newsletter			char(1), 
	email			varchar(191), 
	new_email			varchar(191), 
	email_token			varchar(15), 
	username			varchar(23), 
	"password"			varchar(15), 
	salt			varchar(192), 
	hash			varchar(192), 
	sign_up_token			varchar(15), 
	password_token			varchar(15), 
	create_date			timestamp, 
	last_login			timestamp, 
	active			char(1), 
	rel_id_user_status			integer, 
	permanent			char(1), 
	"group"			char(7), 
	archive			integer, 
	cellphone			varchar(15), 
	profile_photo			varchar(75), 
	sms_alert			char(1), 
	email_alert			char(1)
)
SERVER mysql_server OPTIONS(dbname 'faidaplus', table_name 'user');

CREATE FOREIGN TABLE i_town (
	id_town			integer, 
	town			varchar(50), 
	aramex			char(1)
)
SERVER mysql_server OPTIONS(dbname 'faidaplus', table_name 'town');

CREATE FOREIGN TABLE i_agency (
	id_agency			integer, 
	rel_id_agency			integer, 
	agency_name			varchar(191), 
	pcc			varchar(3), 
	rel_pcc			varchar(3), 
	rel_id_staff			integer, 
	status			char(1), 
	date_added			timestamp, 
	last_production			DATE, 
	rel_id_town			integer, 
	iata			char(1), 
	galileo			char(1), 
	amadeus			char(1), 
	sabre			char(1)
)
SERVER mysql_server OPTIONS(dbname 'faidaplus', table_name 'agency');

CREATE FOREIGN TABLE i_supplier (
	id_supplier			integer, 
	name			varchar(200), 
	brief			varchar(300), 
	logo			varchar(200), 
	website			varchar(200), 
	create_date			timestamp
)
SERVER mysql_server OPTIONS(dbname 'faidaplus', table_name 'supplier');

CREATE FOREIGN TABLE i_shop_category (
	id_shop_category			integer, 
	category			varchar(75)
)
SERVER mysql_server OPTIONS(dbname 'faidaplus', table_name 'shop_category');

CREATE FOREIGN TABLE i_shop_item (
	id_shop_item			integer, 
	rel_id_shop_category			integer, 
	rel_id_supplier			integer, 
	active			char(1), 
	title			varchar(75), 
	brief			VARCHAR, 
	terms			VARCHAR, 
	rel_id_shop_item_batch			integer, 
	pix			varchar(150), 
	thumb_nail			varchar(150), 
	fb_pix			varchar(150), 
	views			integer, 
	likes			integer, 
	popularity			DECIMAL, 
	qty			char(1), 
	rel_id_shop_item_qty			integer, 
	expiry			char(1), 
	rel_id_shop_item_expiry			integer, 
	redeem_limit			char(1),
	rel_id_shop_item_redeem_limit			integer, 
	weight			DECIMAL
)
SERVER mysql_server OPTIONS(dbname 'faidaplus', table_name 'shop_item');

CREATE FOREIGN TABLE i_shop_item_batch (
	id_shop_item_batch			integer, 
	rel_id_shop_item			integer, 
	cost			DECIMAL, 
	undiscounted_cost			DECIMAL, 
	purchase_cost			DECIMAL, 
	limit_per_user			integer, 
	stock			integer
)
SERVER mysql_server OPTIONS(dbname 'faidaplus', table_name 'shop_item_batch');

CREATE FOREIGN TABLE i_segment_period (
	id_segment_period			integer, 
	month			char(1), 
	year			char(4), 
	allocated			char(1)
)
SERVER mysql_server OPTIONS(dbname 'faidaplus', table_name 'segment_period');

CREATE FOREIGN TABLE i_segment (
	id_segment			integer, 
	rel_id_segment_period			integer, 
	pcc			varchar(3), 
	son			varchar(3), 
	multiplier			integer, 
	segments			integer, 
	value			integer, 
	rel_id_user			integer, 
	iata			char(1), 
	amadeus			char(1), 
	sabre			char(1), 
	rel_pcc			varchar(3), 
	posted			char(1), 
	date			date
)
SERVER mysql_server OPTIONS(dbname 'faidaplus', table_name 'segment');

CREATE FOREIGN TABLE i_segment_total (
	id_segment_total			integer, 
	rel_id_segment_period			integer, 
	multiplier			integer, 
	segments_total			integer, 
	value			integer, 
	rel_id_agency			integer, 
	rel_id_user			integer, 
	date_time			timestamp
)
SERVER mysql_server OPTIONS(dbname 'faidaplus', table_name 'segment_total');

CREATE FOREIGN TABLE i_bonus_total (
	id_bonus_total			integer, 
	rel_id_segment_period			integer, 
	rel_id_bonus_type			char(1), 
	rel_id_bonus			integer, 
	pcc			varchar(3), 
	multiplier			integer, 
	segments			integer, 
	value			integer, 
	rel_id_user			integer, 
	rel_id_agency			integer, 
	date_time			timestamp
)
SERVER mysql_server OPTIONS(dbname 'faidaplus', table_name 'bonus_total');

CREATE FOREIGN TABLE i_basket_status (
	id_basket_status			integer, 
	status			varchar(37), 
	details			VARCHAR, 
	pos			integer
)
SERVER mysql_server OPTIONS(dbname 'faidaplus', table_name 'basket_status');

CREATE FOREIGN TABLE i_basket (
	id_basket			integer, 
	rel_id_user			integer, 
	checkout			char(1), 
	check_in_date_time			timestamp, 
	rel_id_basket_status			integer, 
	rel_id_shipping_status			integer, 
	rel_id_basket_batch			integer, 
	shipping_type			char(1), 
	rel_id_basket_collection_point			integer, 
	shipping_cost			real
)
SERVER mysql_server OPTIONS(dbname 'faidaplus', table_name 'basket');

CREATE FOREIGN TABLE i_basket_shop_item (
	id_basket_shop_item			integer, 
	rel_id_basket			integer, 
	rel_id_shop_item_batch			integer, 
	quantity			integer, 
	add_date_time			timestamp
)
SERVER mysql_server OPTIONS(dbname 'faidaplus', table_name 'basket_shop_item');

CREATE FOREIGN TABLE i_lost_order (
	id_lost_order			integer, 
	rel_id_basket			integer, 
	rel_id_batch			integer, 
	date_time			timestamp, 
	consultant			varchar(100), 
	amount			DECIMAL, 
	rel_id_basket_status			integer, 
	rel_pcc			varchar(4), 
	rel_son			varchar(2), 
	rel_id_user			integer
)
SERVER mysql_server OPTIONS(dbname 'faidaplus', table_name 'lost_order');

------- Import script
INSERT INTO suppliers (supplier_id, supplier_name) VALUES(0, 'Travelport');
INSERT INTO suppliers (supplier_id, supplier_name, website, create_date)
SELECT id_supplier, name, website, create_date
FROM i_supplier;

INSERT INTO product_category (product_category_id, product_category_name) VALUES(0, 'No category');
INSERT INTO product_category (product_category_id, product_category_name)
SELECT id_shop_category, category
FROM i_shop_category
ORDER BY id_shop_category;

INSERT INTO products (product_id, product_category_id, supplier_id, is_active,
	product_name, product_details, terms, weight, image,
	product_uprice, product_ucost)
SELECT a.id_shop_item, a.rel_id_shop_category, a.rel_id_supplier, a.active::boolean, 
	a.title, a.brief, a.terms, a.weight, a.pix,
	b.cost, b.purchase_cost
FROM i_shop_item a INNER JOIN i_shop_item_batch b ON a.rel_id_shop_item_batch = b.id_shop_item_batch;

INSERT INTO entitys(entity_type_id, org_id, function_role, salutation, entity_name,
	entity_id, primary_email, user_name, first_password, date_enroled, last_login,
	user_status, primary_telephone, sms_alert, email_alert, newsletter, is_active)
SELECT 1, 0, 'staff', a.salutation, (b.first_name || ' ' || b.last_name),
	c.id_user, c.email, c.username, c.password, c.create_date, c.last_login, 
	c.rel_id_user_status, c.cellphone, c.sms_alert::boolean, c.email_alert::boolean, c.newsletter::boolean,
	CASE WHEN c.active = '1' THEN true ELSE false END
FROM i_salutation a INNER JOIN i_staff b ON a.id_salutation = b.rel_id_salutation
	INNER JOIN i_user c ON b.id_staff = c.rel_id
WHERE c.group = 'staff'
ORDER BY c.id_user;


INSERT INTO entitys(entity_type_id, org_id, function_role, salutation, entity_name,
	birth_date, shipping,  pcc_son, son, 
	entity_id, primary_email, user_name, first_password, date_enroled, last_login,
	user_status, primary_telephone, sms_alert, email_alert, newsletter, is_active)
SELECT 0, 0, 'consultant', a.salutation, (COALESCE(b.first_name, '') || ' ' || COALESCE(b.last_name, '')),
	b.birthdate, b.shipping, b.pcc, b.son, 
	c.id_user, c.email, c.username, c.password, c.create_date, c.last_login, 
	c.rel_id_user_status, c.cellphone, c.sms_alert::boolean, c.email_alert::boolean, c.newsletter::boolean,
	CASE WHEN c.active = '1' THEN true ELSE false END
FROM i_user c LEFT JOIN i_consultant b ON c.rel_id = b.id_consultant
	LEFT JOIN i_salutation a ON a.id_salutation = b.rel_id_salutation
WHERE (c.group = 'consultant' OR c.group = 'agency')
ORDER BY c.id_user;


UPDATE entitys SET entity_name = initcap(trim(entity_name)),  pcc_son = upper(trim(pcc_son)), son = upper(trim(son)), primary_email = lower(trim(primary_email)), user_name = lower(trim(user_name));
UPDATE entitys SET change_pcc = pcc_son, change_son = son;

INSERT INTO towns(town_id, town_name, aramex)
SELECT id_town, town, aramex::boolean
FROM i_town
ORDER BY id_town;

INSERT INTO orgs(org_id, parent_org_id, org_name, org_sufix, pcc,
	account_manager_id, date_enroled, is_iata, town_id)
SELECT c.id_agency, c.rel_id_agency, c.agency_name, c.pcc, c.pcc, 
	b.id_user, c.date_added, c.iata::boolean, c.rel_id_town
FROM i_agency c INNER JOIN 
(SELECT a.id_user, a.rel_id FROM i_user a WHERE a.group = 'staff') b
ON c.rel_id_staff = b.rel_id
ORDER BY c.id_agency;


UPDATE orgs SET pcc = upper(trim(pcc)), org_name = initcap(trim(org_name));

UPDATE entitys SET org_id = orgs.org_id
FROM orgs WHERE (entitys.pcc_son is not null) and (entitys.pcc_son = orgs.pcc);


INSERT INTO fiscal_years (org_id, fiscal_year_id, fiscal_year_start, fiscal_year_end)
SELECT 0, b.year, (b.year || '-01-01')::date, (b.year::integer + 1 || '-01-01')::date - 1
FROM (SELECT a.year
FROM i_segment_period a
GROUP BY a.year
ORDER BY a.year) as b;

INSERT INTO periods (fiscal_year_id, org_id, period_id, start_date, end_date)
SELECT a.year, 0, a.id_segment_period, (a.year || '-' || a.month || '-01')::date,
((a.year || '-' || a.month || '-01')::date + '1 month'::interval- '1 day'::interval)::date
FROM i_segment_period a
ORDER BY a.id_segment_period;

INSERT INTO points (points_id, period_id, amount, segments, points, point_date, entity_id)
SELECT a.id_segment_total, a.rel_id_segment_period, a.multiplier, a.segments_total, a.value, a.date_time::date,
	(CASE WHEN b.id_user is null THEN 0 ELSE a.rel_id_user END) as entity_id
FROM i_segment_total as a LEFT JOIN i_user b ON a.rel_id_user = b.id_user
ORDER BY a.id_segment_total;


UPDATE points SET org_id = entitys.org_id
FROM entitys WHERE points.entity_id = entitys.entity_id;

UPDATE points SET bonus = i_bonus_total.value
FROM i_bonus_total
WHERE (points.period_id = i_bonus_total.rel_id_segment_period)
	AND (points.entity_id = i_bonus_total.rel_id_user);

INSERT INTO orders (order_id, entity_id, batch_no, order_status, order_date, shipping_cost)
SELECT a.id_basket, a.rel_id_user, a.rel_id_basket_batch, b.status, check_in_date_time, a.shipping_cost
FROM i_basket a INNER JOIN i_basket_status b ON a.rel_id_basket_status = b.id_basket_status
WHERE a.checkout = '1';

INSERT INTO order_details (order_details_id, order_id, product_id, product_quantity, product_uprice)
SELECT a.id_basket_shop_item, a.rel_id_basket, b.rel_id_shop_item, a.quantity, b.cost
FROM i_basket_shop_item a INNER JOIN i_shop_item_batch b ON a.rel_id_shop_item_batch = b.id_shop_item_batch
INNER JOIN i_basket c ON a.rel_id_basket = c.id_basket
WHERE c.checkout = '1';

CREATE OR REPLACE FUNCTION get_order_total(int) RETURNS real AS $$
	SELECT COALESCE(sum(order_details.product_quantity * order_details.product_uprice), 0)::real
	FROM order_details 
	WHERE (order_details.order_id = $1);
$$ LANGUAGE SQL;


UPDATE orders SET order_total_amount = get_order_total(order_id);

	
INSERT INTO orders (order_id, order_status, order_date, order_total_amount, entity_id)
SELECT a.rel_id_basket, b.status, date_time::date, a.amount,
	(CASE WHEN c.id_user is null THEN 0 ELSE a.rel_id_user END) as entity_id
FROM i_lost_order a INNER JOIN i_basket_status b ON a.rel_id_basket_status = b.id_basket_status
	LEFT JOIN i_user c ON a.rel_id_user = c.id_user;
	
SELECT pg_catalog.setval('batch_id_seq', 123, true);
SELECT setval('public.currency_currency_id_seq', 4);
SELECT setval('public.entity_subscriptions_entity_subscription_id_seq', 1850);
SELECT setval('public.entity_types_entity_type_id_seq', 3);
SELECT setval('public.entitys_entity_id_seq', 2381);
SELECT setval('public.order_details_order_details_id_seq', 20235);
SELECT setval('public.orders_order_id_seq', 10597);
SELECT setval('public.orgs_org_id_seq', 3124);
SELECT setval('public.periods_period_id_seq', 110);
SELECT setval('public.points_points_id_seq', 1612625);
SELECT setval('public.product_category_product_category_id_seq', 10);
SELECT setval('public.products_product_id_seq', 174);
SELECT setval('public.subscription_levels_subscription_level_id_seq', 2);
SELECT setval('public.suppliers_supplier_id_seq', 17);
SELECT setval('public.sys_logins_sys_login_id_seq', 1);
SELECT setval('public.towns_town_id_seq', 59);


CREATE TRIGGER ins_orders AFTER INSERT ON orders
  FOR EACH ROW EXECUTE PROCEDURE ins_orders();

UPDATE entitys SET org_id = 2744 WHERE entity_id = 1701;


DELETE FROM points WHERE period_id IN (109, 110);

UPDATE entitys SET can_redeem = false WHERE org_id IN (SELECT org_id FROM orgs WHERE pcc IN ('745E', '757F'));

UPDATE bonus SET org_id = orgs.org_id, approve_status = 'Approved', is_active = true
FROM orgs WHERE orgs.pcc = bonus.pcc;

