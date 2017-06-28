---Project Database File

ALTER TABLE orders ADD COLUMN order_status character varying(50) default 'Processing Order';
ALTER TABLE orders ADD COLUMN orderTotalAmount DOUBLE PRECISION  ;
alter table orders add column shipping_cost real;
  alter table orders add column grand_total real;
CREATE TABLE orgs(
  org_id 				serial primary key,
  currency_id 			integer ,
  parent_org_id 		integer,
  org_name 				character varying(50) NOT NULL,
  org_sufix 			character varying(4) NOT NULL,
  is_default 			boolean NOT NULL DEFAULT true,
  is_active 			boolean NOT NULL DEFAULT true,
  logo 					character varying(50),
  pin 					character varying(50),
  details 				text,
  pcc 					character varying(4),
  sp_id 				character varying(16),
  service_id 			character varying(32),
  sender_name 			character varying(16),
  sms_rate 				real NOT NULL DEFAULT 2,
  show_fare 			boolean DEFAULT false,
  gds_free_field 		integer DEFAULT 96,
  credit_limit 			real NOT NULL DEFAULT 0,
  UNIQUE (org_name,org_sufix)
);
CREATE INDEX orgs_currency_id  ON orgs(currency_id);

CREATE TABLE entity_types(
  entity_type_id 		serial primary key,
  org_id 				integer REFERENCES orgs,
  entity_type_name 		character varying(50),
  entity_role 			character varying(240),
  use_key 				integer NOT NULL DEFAULT 0,
  start_view 			character varying(120),
  group_email 			character varying(120),
  description 			text,
  details 				text,
   UNIQUE (entity_type_name)
);
CREATE INDEX entity_types_org_id  ON entity_types   (org_id);

CREATE TABLE entitys(
  entity_id 					serial primary key,
  entity_type_id 				integer NOT NULL  REFERENCES entity_types ,
  org_id 						integer NOT NULL  REFERENCES orgs,
  entity_name 					character varying(120) NOT NULL,
  user_name 					character varying(120),
  primary_email 				character varying(120),
  primary_telephone 			character varying(50),
  super_user 					boolean NOT NULL DEFAULT false,
  entity_leader 				boolean NOT NULL DEFAULT false,
  no_org 						boolean NOT NULL DEFAULT false,
  function_role 				character varying(240),
  date_enroled 					timestamp without time zone DEFAULT now(),
  is_active 					boolean DEFAULT true,
  entity_password 				character varying(64) NOT NULL DEFAULT md5('baraza'::text),
  first_password 				character varying(64) NOT NULL DEFAULT 'baraza'::character varying,
  new_password 					character varying(64),
  start_url 					character varying(64),
  is_picked 					boolean NOT NULL DEFAULT false,
  details 						text,
  son 							character varying(7),
  phone_ph 						boolean DEFAULT true,
  phone_pa 						boolean DEFAULT false,
  phone_pb 						boolean DEFAULT false,
  phone_pt 						boolean DEFAULT false,
   UNIQUE (org_id, user_name)
);
CREATE INDEX entitys_entity_type_id  ON entitys   (entity_type_id);
CREATE INDEX entitys_org_id  ON entitys   (org_id);
CREATE INDEX entitys_user_name  ON entitys   (user_name COLLATE pg_catalog."default");

CREATE TABLE subscription_levels
(
  subscription_level_id serial NOT NULL,
  org_id integer,
  subscription_level_name character varying(50),
  details text,
  CONSTRAINT subscription_levels_pkey PRIMARY KEY (subscription_level_id),
  CONSTRAINT subscription_levels_org_id_fkey FOREIGN KEY (org_id)
      REFERENCES orgs (org_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE INDEX subscription_levels_org_id
  ON subscription_levels
  USING btree
  (org_id);


CREATE TABLE entity_subscriptions
(
  entity_subscription_id            serial NOT NULL,
  entity_type_id                    integer NOT NULL,
  entity_id                         integer NOT NULL,
  subscription_level_id             integer NOT NULL,
  org_id                            integer,
  details                           text,
  CONSTRAINT entity_subscriptions_pkey PRIMARY KEY (entity_subscription_id),
  CONSTRAINT entity_subscriptions_entity_id_fkey FOREIGN KEY (entity_id)
      REFERENCES entitys (entity_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT entity_subscriptions_entity_type_id_fkey FOREIGN KEY (entity_type_id)
      REFERENCES entity_types (entity_type_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT entity_subscriptions_org_id_fkey FOREIGN KEY (org_id)
      REFERENCES orgs (org_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT entity_subscriptions_subscription_level_id_fkey FOREIGN KEY (subscription_level_id)
      REFERENCES subscription_levels (subscription_level_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT entity_subscriptions_entity_id_entity_type_id_key UNIQUE (entity_id, entity_type_id)
);
CREATE INDEX entity_subscriptions_entity_id
  ON entity_subscriptions
  USING btree
  (entity_id);

CREATE INDEX entity_subscriptions_entity_type_id
  ON entity_subscriptions
  USING btree
  (entity_type_id);

CREATE INDEX entity_subscriptions_org_id
  ON entity_subscriptions
  USING btree
  (org_id);

CREATE INDEX entity_subscriptions_subscription_level_id
  ON entity_subscriptions
  USING btree
  (subscription_level_id);

  CREATE TABLE sys_logins
(
  sys_login_id serial NOT NULL,
  entity_id integer,
  login_time timestamp without time zone DEFAULT now(),
  login_ip character varying(64),
  narrative character varying(240),
  CONSTRAINT sys_logins_pkey PRIMARY KEY (sys_login_id),
  CONSTRAINT sys_logins_entity_id_fkey FOREIGN KEY (entity_id)
      REFERENCES entitys (entity_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE TABLE suppliers(
  supplier_id 		serial PRIMARY KEY,
  supplier_name		character varying(50),
  details			text
  );

CREATE TABLE product_category(
	product_category_id		serial primary key,
	product_category_name	varchar(100),
	details 				text
	);


CREATE TABLE products(
	product_id				serial primary key,
	product_name			varchar(100),
	product_uPrice           double precision,
	product_category_id 	integer references product_category,
    supplier_id          	integer references suppliers,
	created_by				integer references entitys,				--logged in system user who did the insert
	created					date not null default current_date,
	remarks					text,
	updated_by			    integer references entitys,				--logged in system user who did the last update
	updated				    date,
	narrative			    text,
    image                   character varying(50),
	product_details 		text
	);
CREATE INDEX products_product_category_id  ON products   (product_category_id);
CREATE INDEX products_supplier_id  ON products   (supplier_id);

CREATE TABLE orders (
	order_id 		serial primary key,
	entity_id 		integer NOT NULL REFERENCES entitys,
	order_date		       date not null default current_date
);
CREATE INDEX order_entity_id  ON entitys(entity_id);

CREATE TABLE order_details (
	order_details_id 		serial primary key,
    order_id                integer  NOT NULL REFERENCES orders,
	product_id 		        integer NOT NULL REFERENCES products,
	entity_id 		        integer NOT NULL REFERENCES entitys,
	product_quantity	    integer,
    product_uPrice           double precision,
	totalAmount		        DOUBLE PRECISION,
    batch_no                integer,
    batch_date              date

    status                   character varying(20) NOT NULL default 'New'
);

CREATE INDEX order_product_id  ON order_details(product_id);
CREATE INDEX order_details_id  ON orders(order_id);

CREATE TABLE applicants(
entity_id			integer references entitys primary key,
org_id 				integer references orgs,
applicant_email			character varying(50) NOT NULL,
pseudo_code			character varying(4),
son 			     character varying(7),
approved                boolean DEFAULT false,
application_date timestamp without time zone DEFAULT now(),
consultant_dob      date NOT NULL,
status          character varying(20),
details text
);
 CREATE INDEX applicants_org_id ON applicants (org_id);


  CREATE TABLE points  (
    points_id               serial  PRIMARY KEY,
    period                  date,
    pcc                     character varying(4)  REFERENCES pccs,
    son                     character varying(7),
    segments                real,
    amount                  real,
    points                  real,
    bonus                   real
  );
   CREATE INDEX points_pcc ON points (pcc);


   CREATE TABLE bonus (
 	bonus_id				serial PRIMARY KEY,
 	consultant_id			integer references entitys,
 	period_id				integer references periods,
    son						varchar(7),
 	pcc						varchar(12),
 	entity_id				integer references entitys,
 	org_id					integer references orgs,

 	percentage 				real,
 	amount					real,
 	is_active				boolean DEFAULT false,

 	approve_status			varchar(16) default 'Draft' not null,
 	workflow_table_id		integer,
 	application_date		timestamp default now(),
 	action_date				timestamp,

 	details					text
 );


 CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON bonus
     FOR EACH ROW EXECUTE PROCEDURE upd_action();

	CREATE INDEX bonus_org_id ON bonus(org_id);
	CREATE INDEX bonus_entity_id ON bonus(entity_id);

   CREATE OR REPLACE VIEW vw_products AS
    SELECT products.product_id,
       products.product_name,
       products.product_details,
       products.product_uprice,
       products.created,
       products.updated_by,
       suppliers.supplier_name,
       suppliers.supplier_id,
       product_category.product_category_id,
       product_category.product_category_name
      FROM products
      JOIN suppliers ON products.supplier_id = suppliers.supplier_id
      JOIN product_category ON products.product_category_id=product_category.product_category_id;

      CREATE OR REPLACE VIEW vw_orders AS
   SELECT orders.order_id,
      orders.order_date,
      orders.order_status,
      orders.ordertotalamount,
      orders.batch_no,
      orders.shipping_cost,
      orders.grand_total,
      orders.details,
      vw_entitys.entity_name,
      vw_entitys.son,
       vw_entitys.entity_id,
      vw_entitys.pcc,
      vw_entitys.org_name,
       vw_entitys.primary_email,
        vw_entitys.primary_telephone,
        vw_entitys.function_role,
         vw_entitys.entity_role,
      vw_entitys.org_id
     FROM orders
       JOIN vw_entitys ON orders.entity_id = vw_entitys.entity_id;

         CREATE OR REPLACE VIEW vw_pccs AS
          SELECT orgs.org_id,
            orgs.org_name,
            orgs.is_default,
            orgs.is_active,
            orgs.logo,
            orgs.details,
            pccs.pcc,
            pccs.agency_name,
            pccs.iata_agent,
            pccs.agency_incentive,
            pccs.incentive_son
            FROM pccs
              INNER JOIN orgs ON pccs.pcc = orgs.pcc;


              CREATE OR REPLACE VIEW vw_order_details AS
             SELECT order_details.order_details_id,
                vw_orders.order_id,
                vw_orders.order_date,
                vw_orders.order_status,
                vw_orders.org_id,
                vw_orders.org_name,
                vw_products.product_id,
                vw_products.product_name,
                vw_products.supplier_name,
                vw_products.supplier_id,
                vw_products.product_category_id,
                vw_products.product_category_name,
                vw_orders.entity_name,
                vw_orders.entity_id,
                vw_orders.batch_no,
                order_details.product_uprice,
                order_details.product_quantity,
                order_details.totalamount
               FROM order_details
                 JOIN vw_orders ON order_details.order_id = vw_orders.order_id
                 JOIN vw_products ON vw_products.product_id = order_details.product_id;





CREATE OR REPLACE VIEW vw_applicants AS
SELECT applicants.entity_id,
applicants.applicant_email,
cast(applicants.application_date as date),
applicants.pseudo_code,
entitys.entity_name,
applicants.son,
applicants.approved,
applicants.status,
applicants.consultant_dob,
applicants.details
FROM applicants
JOIN entitys ON applicants.entity_id = entitys.entity_id;

CREATE OR REPLACE VIEW vw_consultant AS
 SELECT applicants.entity_id,
    vw_entitys.primary_email,
    vw_entitys.date_enroled::date AS application_date,
    vw_entitys.pcc,
    vw_entitys.org_name,
    vw_entitys.entity_name,
    vw_entitys.is_active,
    vw_entitys.son,
    (vw_entitys.is_active)as approved,
    applicants.consultant_dob
   FROM applicants
     JOIN vw_entitys ON applicants.entity_id = vw_entitys.entity_id;

     CREATE OR REPLACE VIEW vw_purged_consultant AS
      SELECT applicants.entity_id,
         vw_entitys.primary_email,
         cast(vw_entitys.date_enroled as date),
         vw_entitys.pcc,
         vw_entitys.org_name,
         vw_entitys.entity_name,
         vw_entitys.is_active,
         vw_entitys.son,
         (vw_entitys.is_active)as approved,
         points.period,
         applicants.consultant_dob
        FROM applicants
          JOIN vw_entitys ON applicants.entity_id = vw_entitys.entity_id
           JOIN points ON vw_entitys.son = points.son AND vw_entitys.pcc = points.pcc
          WHERE points.period::date < CURRENT_DATE - INTERVAL '6 months';





  CREATE OR REPLACE VIEW vw_points AS
   SELECT points.points_id,
      points.period,
      to_char(points.period::timestamp with time zone, 'mmyyyy'::text) AS ticket_period,
      points.pcc,
      points.son,
      points.segments,
      points.amount,
      points.points,
      points.bonus,
      vw_orgs.org_name
     FROM points
       JOIN vw_orgs ON points.pcc::text = vw_orgs.pcc::text;

       CREATE OR REPLACE VIEW vw_statement AS
      SELECT
       vw_points.amount,
       sum(vw_points.points)as dr,
       vw_points.bonus,
      vw_orders.entity_id,
      vw_orders.order_date,
      vw_orders.order_status,
      vw_orders.entity_name,
      vw_orders.son,
      sum(vw_orders.ordertotalamount)as cr ,
      vw_orders.pcc,
      (sum(vw_points.points)-sum(vw_orders.ordertotalamount))as balance,
      orgs.org_name
      FROM vw_orders
      INNER JOIN vw_points ON vw_orders.son = vw_points.son and vw_orders.pcc = vw_points.pcc
      JOIN orgs ON vw_orders.pcc = orgs.pcc
       GROUP BY vw_orders.entity_id, vw_orders.order_date,vw_orders.order_status,vw_orders.entity_name,
         vw_orders.son, vw_orders.pcc,vw_points.pcc,  vw_points.son,
       vw_points.amount,vw_points.bonus,orgs.org_name;


       CREATE OR REPLACE VIEW vw_pcc_points AS
        SELECT
           points.period,
           to_char(points.period::date::timestamp with time zone, 'mm'::text) || to_char(points.period::date::timestamp with time zone, 'yyyy'::text) AS ticket_period,
           points.pcc,
           sum(points.segments) as segments,
           sum(points.amount) as amount,
           sum(points.points) as points,
           sum(points.bonus) as bonus,
           vw_orgs.org_name
          FROM points
            JOIN vw_orgs ON points.pcc::text = vw_orgs.pcc::text
            GROUP BY period,points.pcc,org_name,ticket_period;

CREATE OR REPLACE VIEW vw_son_points AS
 SELECT points.points_id,
    points.period,
    to_char(points.period::date, 'mm') ||to_char(points.period::date, 'yyyy') AS ticket_period,
    points.pcc,
    points.son,
    points.segments,
    points.amount,
    points.points,
    points.bonus,
    vw_entitys.org_name,
    vw_entitys.entity_name,
    vw_entitys.entity_id
   FROM points
     JOIN vw_entitys ON points.pcc::text = vw_entitys.pcc::text AND points.son = vw_entitys.son;

    CREATE OR REPLACE VIEW vw_son_statement AS
        SELECT a.dr,
            a.cr,
            a.order_date,
            a.son,
            a.pcc,
            a.org_name,
            a.entity_id,
            a.dr - a.cr AS balance,
            a.details
        FROM ( SELECT COALESCE(vw_son_points.points, 0::real) + COALESCE(vw_son_points.bonus, 0::real) AS dr,
            0::real AS cr,
            vw_son_points.period::date AS order_date,
            vw_son_points.son,
            vw_son_points.pcc,
            vw_son_points.org_name,
            vw_son_points.entity_id,
            '#Segments'::text as details
        FROM vw_son_points
            UNION
        SELECT 0::real AS float4,
            vw_orders.ordertotalamount::real AS ordertotalamount,
            vw_orders.order_date,
            vw_orders.son,
            vw_orders.pcc,
            vw_orders.org_name,
            vw_orders.entity_id,
            vw_orders.details
        FROM vw_orders) a
            ORDER BY a.pcc, a.son, a.order_date;




    CREATE OR REPLACE VIEW vw_all_bonus AS
        SELECT bonus.bonus_id,
            bonus.entity_id,
            bonus.percentage,
            bonus.is_active,
            bonus.amount,
            bonus.period_id,
            vw_entitys.entity_name,
            vw_entitys.is_active as entity_active,
            vw_entitys.son,
            vw_entitys.pcc,
            vw_entitys.org_name,
            vw_entitys.org_id,
            to_char(periods.start_date::timestamp with time zone, 'mmYYYY'::text) AS period
        FROM bonus
            JOIN vw_entitys ON bonus.pcc = vw_entitys.pcc
            JOIN periods ON bonus.period_id = periods.period_id;


    CREATE OR REPLACE VIEW vw_son_bonus AS
        SELECT bonus.bonus_id,
            bonus.entity_id,
            bonus.percentage,
            bonus.is_active,
            bonus.amount,
            bonus.period_id,
            vw_entitys.entity_name,
            vw_entitys.is_active as entity_active,
            vw_entitys.son,
            vw_entitys.pcc,
            vw_entitys.org_name,
            vw_entitys.org_id,
            to_char(periods.start_date::timestamp with time zone, 'mmYYYY'::text) AS period
        FROM bonus
            JOIN vw_entitys ON bonus.entity_id = vw_entitys.entity_id
            JOIN periods ON bonus.period_id = periods.period_id;

    CREATE OR REPLACE VIEW vw_org_bonus AS
        SELECT bonus.bonus_id,
            bonus.percentage,
            bonus.is_active,
            bonus.amount,
            bonus.period_id,
            bonus.pcc,
            bonus.approve_status,
            vw_orgs.org_name,
            to_char(periods.start_date::timestamp with time zone, 'mmYYYY'::text) AS period
        FROM bonus
            JOIN vw_orgs ON bonus.org_id = vw_orgs.org_id
            JOIN periods ON bonus.period_id = periods.period_id
            where bonus.entity_id is null;


    CREATE OR REPLACE VIEW vw_summary_report AS
        SELECT vw_son_points.period,
            to_char(vw_son_points.period::date::timestamp with time zone, 'mm'::text) || to_char(vw_son_points.period::date::timestamp with time zone, 'yyyy'::text) AS ticket_period,
            vw_son_points.pcc,
            vw_son_points.son,
            sum(vw_son_points.segments) as segments,
            sum(vw_son_points.points) as totalkes,
            sum(vw_son_points.bonus) as total_bonus,
            sum(vw_orders.ordertotalamount) as ordertotalamount,
            sum(vw_son_points.points - vw_orders.ordertotalamount ) as balance
        FROM vw_son_points
            JOIN vw_orders ON vw_son_points.pcc::text = vw_orders.pcc::text AND vw_son_points.son::text = vw_orders.son::text
            GROUP BY vw_son_points.period,ticket_period,vw_son_points.pcc,vw_son_points.son;
