CREATE OR REPLACE FUNCTION generate_points(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	rec						RECORD;
	v_period				varchar(7);
	period					date;
	v_start_date			date;
	v_increment				integer;
	v_period_id				integer;
	v_org_id				integer;
	v_entity_id				integer;
	v_points				real;
	v_points_id				integer;
	v_root_points			integer;
	v_amount				real;
	msg 					varchar(120);
BEGIN

	v_period_id = $1::integer;
	SELECT start_date, end_date, to_char(start_date, 'mmyyyy') INTO v_start_date, period, v_period
	FROM periods WHERE period_id = v_period_id AND closed = false;
	IF(v_period IS NULL)THEN RAISE EXCEPTION 'Period is closed'; END IF;

	IF(v_start_date < '2016-06-01'::date)THEN
		v_increment := 0;
	ELSE
		v_increment := 2;
	END IF;

	v_root_points := 0;
	DELETE FROM points WHERE period_id = v_period_id AND entity_id = 0;

	FOR rec IN SELECT pcc, son, bookpcc, ticketperiod, totalsegs, substring(bookpcc from 1 for 6) as svcb_son
		FROM t_sonsegs WHERE (ticketperiod = v_period) AND (totalsegs > 0)
	LOOP

		IF(1<= rec.totalsegs::integer AND rec.totalsegs::integer <=250 ) THEN
			v_amount := 12 + v_increment;
			v_points := rec.totalsegs * v_amount;
		END IF;

		IF(251<= rec.totalsegs::integer AND rec.totalsegs::integer <=500) THEN
			v_amount := 16 + v_increment;
			v_points := rec.totalsegs * v_amount;
		END IF;

		IF(rec.totalsegs::integer >=501 ) THEN
			v_amount := 20 + v_increment;
			v_points := rec.totalsegs * v_amount;
		END IF;

		SELECT orgs.org_id, entitys.entity_id INTO v_org_id, v_entity_id
		FROM orgs INNER JOIN entitys ON orgs.org_id = entitys.org_id
		WHERE (entitys.is_active = true) AND (orgs.pcc = rec.pcc) AND (entitys.son = rec.son);

		IF(v_entity_id is null)THEN
			SELECT entity_id INTO v_entity_id
			FROM change_pccs
			WHERE (approve_status = 'Approved') AND (pcc = rec.pcc) AND (son = rec.son);
			SELECT org_id INTO v_org_id
			FROM entitys
			WHERE (entitys.is_active = true) AND (entity_id = v_entity_id);

		END IF;

		IF(v_entity_id is null)THEN
			SELECT entity_id INTO v_entity_id
			FROM entitys
			WHERE (is_active = true) AND (svcb_son = rec.svcb_son);
			SELECT org_id INTO v_org_id
			FROM entitys
			WHERE (entitys.is_active = true) AND (entity_id = v_entity_id);
			IF(v_org_id is null)THEN v_entity_id := 0; v_org_id := 0; END IF;
		END IF;

		IF(v_entity_id is null)THEN v_entity_id := 0; v_org_id := 0; END IF;

		--- Compute rooot points
		IF(v_entity_id <> 0)THEN
			v_root_points := v_root_points + rec.totalsegs;
		END IF;

		SELECT points_id INTO v_points_id
		FROM points WHERE (period_id = v_period_id) AND (entity_id = v_entity_id)
			AND (pcc = rec.pcc) AND (son = rec.son);

		IF(v_points_id is null)THEN
			SELECT points_id INTO v_points_id
			FROM points WHERE (period_id = v_period_id) AND (entity_id = v_entity_id)
				AND (pcc is null) AND (son = rec.son);
		END IF;

		IF(v_points_id is null)THEN
			INSERT INTO points (point_date, period_id, org_id, entity_id, pcc, son, segments, amount, points)
			VALUES (period, v_period_id, v_org_id, v_entity_id, rec.pcc, rec.son, rec.totalsegs, v_amount, v_points);
		ELSE
			UPDATE points SET segments = rec.totalsegs, amount = v_amount, points = v_points
			WHERE points_id = v_points_id;
		END IF;
	END LOOP;

	IF(v_start_date >= '2016-06-01'::date)THEN
		SELECT points_id INTO v_points_id
		FROM points WHERE (period_id = v_period_id) AND (entity_id = 0) AND (pcc is null) AND (son is null);

		IF(v_points_id is null )THEN
			INSERT INTO points (point_date, period_id, org_id, entity_id, amount, points)
			VALUES (period, v_period_id, 0, 0, 2, v_root_points * 2);
		ELSE
			UPDATE points SET amount = 2, points = v_root_points * 2
			WHERE points_id = v_points_id;
		END IF;
	END IF;

	IF(rec IS NULL)THEN
		RAISE EXCEPTION 'There are no segments for this month';
	ELSE
		msg := 'Points computed';
	END IF;
	RETURN msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION generate_bonus(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	rec						RECORD;
	v_period				varchar(7);
	period					date;
	v_start_date			date;
	v_period_id				integer;
	v_period_bonus_ps		real;
	v_period_bonus_amount	real;
	v_pcc_bonus_ps			real;
	v_pcc_bonus_amount		real;
	v_son_bonus_ps			real;
	v_son_bonus_amount		real;
	v_bonus					real;
	msg 					varchar(120);
BEGIN

	v_period_id = $1::integer;
	SELECT start_date, end_date, to_char(start_date, 'mmyyyy') INTO v_start_date, period, v_period
	FROM periods WHERE period_id = v_period_id AND closed = false;
	IF(v_period IS NULL)THEN RAISE EXCEPTION 'Period is closed'; END IF;

	SELECT percentage, amount INTO v_period_bonus_ps, v_period_bonus_amount
	FROM bonus
	WHERE (period_id = $1::integer) AND (is_active = true) AND (approve_status = 'Approved');
	IF(v_period_bonus_ps is null)THEN v_period_bonus_ps := 0; END IF;
	IF(v_period_bonus_amount is null)THEN v_period_bonus_amount := 0; END IF;

	FOR rec IN SELECT points_id, entity_id, period_id, pcc, son, segments, amount, points, bonus
	FROM points WHERE (period_id = $1::integer) LOOP

		SELECT percentage, amount INTO v_pcc_bonus_ps, v_pcc_bonus_amount
		FROM bonus
		WHERE (pcc = rec.pcc) AND (is_active = true) AND (approve_status = 'Approved')
			AND (start_date <= v_start_date) AND ((end_date is null) OR (end_date >= v_start_date));
		IF(v_pcc_bonus_ps is null)THEN v_pcc_bonus_ps := 0; END IF;
		IF(v_pcc_bonus_amount is null)THEN v_pcc_bonus_amount := 0; END IF;

		SELECT percentage, amount INTO v_son_bonus_ps, v_son_bonus_amount
		FROM bonus
		WHERE (entity_id = rec.entity_id) AND (is_active = true) AND (approve_status = 'Approved')
			AND (start_date <= v_start_date) AND ((end_date is null) OR (end_date >= v_start_date));
		IF(v_son_bonus_ps is null)THEN v_son_bonus_ps := 0; END IF;
		IF(v_son_bonus_amount is null)THEN v_son_bonus_amount := 0; END IF;

		v_bonus := (rec.points * v_period_bonus_ps / 100) + (rec.segments * v_period_bonus_amount);
		v_bonus := v_bonus + (rec.points * v_pcc_bonus_ps / 100) + (rec.segments * v_pcc_bonus_amount);
		v_bonus := v_bonus + (rec.points * v_son_bonus_ps / 100) + (rec.segments * v_son_bonus_amount);
		IF(v_bonus is null)THEN
			v_bonus :=0;
		END IF;
		UPDATE points SET bonus = v_bonus WHERE points_id = rec.points_id;

	END LOOP;

	msg := 'Bonus computed';
	RETURN msg;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION upd_orders_status(varchar(12), varchar(12), varchar(12),varchar(12))	RETURNS varchar(120) AS $$
DECLARE
	msg 		text;
	details 	text;
	or_details 	text;
	v_org_id                integer;
	v_entity_id            integer;
	v_sms_number		varchar(25);
	v_order_no			integer;
	v_batch_no			integer;
	v_batch				integer;
BEGIN
	SELECT entity_id, phone_no,batch_no,order_id INTO v_entity_id, v_sms_number,v_batch_no,v_order_no
	FROM orders WHERE (order_id = $1::integer);
	IF ($3::integer = 1) THEN
		msg :='Successfully Updated';
		IF(v_sms_number = '') THEN
			SELECT org_id, entity_id, primary_telephone INTO v_org_id, v_entity_id, v_sms_number
			FROM entitys WHERE (entity_id = v_entity_id);
		ELSE
			SELECT org_id INTO v_org_id
			FROM entitys WHERE (entity_id = v_entity_id);
		END IF;
		UPDATE orders SET order_status = 'Awaiting Collection' WHERE order_id = $1::integer;
		or_details :='Order #'||v_batch_no||'-'||v_order_no||' is ready for collection.';
		details :=' #'||v_batch_no||'-'||v_order_no;
		INSERT INTO sms (folder_id, entity_id, org_id, sms_number, message)
	    VALUES (0,v_entity_id, v_org_id, v_sms_number, or_details);
		INSERT INTO sys_emailed (table_id, sys_email_id, table_name, email_type, org_id,narrative,mail_body)
		VALUES ($1::integer,4 ,'vw_orders', 3, 0,or_details,details);
	END IF;

	IF ($3::integer = 2) THEN
		msg :='Successfully Updated';
		UPDATE orders SET order_status = 'Collected' WHERE order_id = $1::integer;
		or_details :=  'Order '||v_batch_no||'-'||v_order_no||' has been collected';
		INSERT INTO sys_emailed (table_id, sys_email_id, table_name, email_type, org_id,narrative)
		VALUES ($1::integer,9 ,'vw_orders', 3, 0,or_details);
	END IF;

	IF ($3::integer = 3) THEN
		UPDATE orders SET order_status = 'Closed' WHERE order_id = $1::integer;
	END IF;

	IF ($3::integer = 4) THEN
		v_batch := (SELECT last_value FROM batch_id_seq) ;
		IF(v_batch_no<v_batch)THEN
		msg := 'Batch number is Closed';
		ELSE
		msg :='Order Canceled Successfully';
		UPDATE orders SET order_total_amount = 0 , shipping_cost = 0, order_status = 'Canceled', change_by =$2::integer  WHERE order_id = $1::integer;
		UPDATE order_details SET product_uprice = 0 , status = 'Canceled' WHERE order_id = $1::integer;
		or_details :='Order #'||v_batch_no||'-'||v_order_no||' has been canceled.';
		details :=' #'||v_batch_no||'-'||v_order_no;
		INSERT INTO sms (folder_id, entity_id, org_id, sms_number, message)
	    VALUES (0,v_entity_id, v_org_id, v_sms_number, or_details);
		END IF;

	END IF;

	IF ($3::integer = 5) THEN
		msg :='Successfully Updated';
		UPDATE orders SET order_status = 'Uncollected' WHERE order_id = $1::integer;
		or_details :='Order #'|| v_batch_no||'-'||v_order_no||' uncollected and expired';
		INSERT INTO sys_emailed (table_id, sys_email_id, table_name, email_type, org_id,narrative)
		VALUES ($1::integer,10 ,'vw_orders', 3, 0,or_details);
	END IF;

	RETURN msg;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION ins_applicants()  RETURNS trigger AS $BODY$
DECLARE
	rec 			RECORD;
	v_entity_id		integer;
BEGIN
	IF (TG_OP = 'INSERT') THEN
		SELECT entity_id INTO v_entity_id
		FROM entitys
		WHERE (trim(lower(user_name)) = trim(lower(NEW.user_name)));

		IF(v_entity_id is not null)THEN
			RAISE EXCEPTION 'The username exists use a different one or reset password for the current one';
		END IF;
		INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type)
		VALUES (1, NEW.applicant_id, 'applicants', 3);
	END IF;
	RETURN NEW;
END;
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER ins_applicants BEFORE INSERT OR UPDATE ON applicants
FOR EACH ROW  EXECUTE PROCEDURE ins_applicants();

CREATE OR REPLACE FUNCTION upd_applicants(varchar(12), varchar(12), varchar(12),varchar(12)) RETURNS varchar(120) AS $BODY$
DECLARE
	ps				varchar(16);
	v_pcc 			varchar(4);
	rec 			RECORD;
	app				RECORD;
	msg				varchar(120);
	myid 			integer;
	v_primary_email varchar(50);
BEGIN

	IF ($3::integer = 1) THEN
		ps := 'Approved';
		SELECT * INTO app FROM applicants WHERE applicant_id = $1::integer;
		SELECT org_id INTO rec FROM orgs WHERE (trim(upper(pcc)) = trim(upper(app.pseudo_code)));

		IF(rec IS NULL)THEN
			RAISE EXCEPTION 'Pseudo Code Does not Exist';
		END IF;

		SELECT primary_email INTO v_primary_email FROM entitys WHERE trim(lower(primary_email)) = trim(lower(app.applicant_email)) AND is_active = true;
		IF(v_primary_email is not null) THEN
			RAISE EXCEPTION 'Email address already exist Please used a different email address or reset your password';
		END IF;
		UPDATE applicants SET status = ps , org_id = rec.org_id, approve_status = ps WHERE applicant_id = $1::integer ;
		INSERT INTO entitys (org_id, entity_type_id, entity_name, user_name, primary_email, primary_telephone, son, function_role, is_active, birth_date)
		VALUES (rec.org_id, 0, app.applicant_name, trim(app.user_name), trim(lower(app.applicant_email)), app.phone_no, trim(upper(app.son)), 'consultant', true, app.consultant_dob) returning entity_id INTO myid;
		msg := 'Consultant account has been activated';
		INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type)
		VALUES (2, myid, 'entitys', 3);
	END IF;

	IF ($3::integer = 2) THEN
		ps := 'Rejected';
		UPDATE applicants SET status = ps , approve_status = ps WHERE applicant_id = $1::integer ;
		msg := 'Applicant Rejected';
		INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type)
		VALUES (3, $1::integer , 'applicants', 3);
	END IF;

	IF ($3::integer = 3) THEN
		UPDATE entitys SET is_active = true WHERE entity_id = $1::integer ;
		msg := 'Consultant Activated';
		INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type)
		VALUES (2, $1::integer , 'entitys', 3);
	END IF;

	IF ($3::integer = 4) THEN
		UPDATE entitys SET is_active = false WHERE entity_id = $1::integer ;
		msg := 'Account Deactivated';
		INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type)
		VALUES (2, $1::integer , 'entitys', 3);
	END IF;

	RETURN msg;
END;
$BODY$ LANGUAGE plpgsql;




CREATE OR REPLACE FUNCTION getbalance(integer)  RETURNS real AS $$
DECLARE
    v_org_id 			integer;
    v_function_role		text;
    v_balance			real;
BEGIN
    v_balance = 0::real;
    SELECT org_id,function_role INTO v_org_id, v_function_role FROM vw_entitys WHERE entity_id = $1;

    IF(v_function_role = 'manager')THEN
        SELECT COALESCE(sum(dr+bonus - cr), 0) INTO v_balance
        FROM vw_pcc_statement
        WHERE org_id = v_org_id;
    END IF;

    IF(v_function_role = 'consultant')THEN
        SELECT COALESCE(sum(dr+bonus - cr), 0) INTO v_balance
        FROM vw_son_statement
        WHERE entity_id = $1;
    END IF;

    IF(v_function_role = 'admin')THEN
        SELECT COALESCE(sum(a.dr+a.bonus - a.cr), 0) INTO v_balance
        FROM ( SELECT COALESCE(vw_son_points.points, 0::real) AS dr,   0::real AS cr, vw_son_points.period AS order_date,
            vw_son_points.org_id,vw_son_points.son, vw_son_points.pcc, vw_son_points.entity_id, COALESCE(vw_son_points.bonus, 0::real) AS bonus
        FROM vw_son_points WHERE entity_id = 0 AND org_id = 0 AND pcc is null AND son is null AND vw_son_points.period::date >= '2016-01-01'::date
        UNION ALL
        SELECT 0::real AS float4, vw_orders.grand_total AS order_total_amount, vw_orders.order_date, vw_orders.org_id, vw_orders.son,
            vw_orders.pcc, vw_orders.entity_id,  0::real AS bonus
        FROM vw_orders WHERE entity_id = $1) a;
    END IF;
    RETURN v_balance;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION getUnclaimbalance(integer)  RETURNS real AS $$
DECLARE
    v_org_id 			integer;
    v_function_role		text;
    v_balance			real;
	v_lbalance			real;
BEGIN
    v_balance = 0::real;
    SELECT org_id,function_role INTO v_org_id, v_function_role FROM vw_entitys WHERE entity_id = $1;

    IF(v_function_role = 'admin')THEN
        SELECT COALESCE(sum(balance), 0) INTO v_balance
        FROM vw_balance  WHERE  org_id = 0 AND order_date < '2016-01-01'::date;
		SELECT COALESCE(sum(balance), 0) INTO v_lbalance
        FROM vw_balance  WHERE  org_id = 0 AND pcc is not null AND son is not null AND entity_id != 0 AND order_date >= '2016-01-01'::date;
		v_balance := v_balance + v_lbalance;

    END IF;
    RETURN v_balance;
END;
$$ LANGUAGE plpgsql;



CREATE SEQUENCE batch_id_seq INCREMENT 1 MINVALUE 1 MAXVALUE 9223372036854775807 START 1;

CREATE OR REPLACE FUNCTION upd_orders_batch(varchar(20),varchar(20),varchar(20),varchar(20)) RETURNS varchar(120) AS $BODY$
DECLARE
	v_batch  	integer;
	msg 		varchar(50);
BEGIN
	IF ($3::integer = 1) THEN
		v_batch := (SELECT last_value FROM batch_id_seq) ;
		UPDATE orders SET batch_no = v_batch,batch_date = now() WHERE order_id = $1::integer;
		INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type, mail_body, narrative)
		VALUES (8, $1::integer , 'vw_orders', 3, get_order_details($1::integer), 'Order '||v_batch||'-'||$1::integer||' is being processed.');
		msg := 'Orders Batched Successfully';
	END IF;

	IF($3::integer = 2)THEN
		v_batch :=nextval('batch_id_seq');
		msg := 'Batch Closed';
	END IF;

	RETURN msg;
END;
$BODY$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION close_batch_seq()  RETURNS integer AS $BODY$
DECLARE
	v_batch  integer;
BEGIN
	v_batch := nextval('batch_id_seq');
	RETURN v_batch;
END;

$BODY$ LANGUAGE plpgsql ;

CREATE OR REPLACE FUNCTION getBirthday() RETURNS bigint AS $BODY$
	SELECT  count(entity_id)
	FROM vw_entitys WHERE to_char(birth_date, 'dd-mm') = to_char(CURRENT_DATE,'dd-mm');
$BODY$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION getBatch_no() RETURNS bigint AS $BODY$
	SELECT last_value FROM batch_id_seq;
$BODY$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION son_segments( integer)  RETURNS real AS $BODY$
	SELECT COALESCE(SUM(segments),0.0)  FROM vw_son_points WHERE entity_id = $1;
$BODY$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION ins_orders() RETURNS trigger AS $BODY$
DECLARE
	v_order integer;
BEGIN

	INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type, mail_body, narrative)
	VALUES (5, NEW.order_id , 'vw_orders', 3, get_order_details(NEW.order_id), 'Order '||NEW.order_id||' has been submitted');
	RETURN NEW;
END;
$BODY$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ins_order_details() RETURNS trigger AS $BODY$
DECLARE
	v_order integer;
BEGIN
	IF (NEW.order_details_id IS NULL) THEN
		UPDATE order_details SET order_id=t.id
		FROM (select orders.order_id AS id FROM orders WHERE orders.order_id = NEW.order_id)AS t ;
	END IF;

	RETURN NEW;
END;
$BODY$ LANGUAGE plpgsql;

CREATE TRIGGER ins_order_details AFTER INSERT ON order_details
FOR EACH ROW EXECUTE PROCEDURE ins_order_details();

CREATE TRIGGER ins_orders AFTER INSERT ON order_details
FOR EACH ROW EXECUTE PROCEDURE ins_orders();
-- CREATE TRIGGER ins_orders AFTER INSERT ON orders
-- FOR EACH ROW EXECUTE PROCEDURE ins_orders();


CREATE OR REPLACE FUNCTION ins_orgs() RETURNS trigger AS $$
BEGIN
	NEW.pcc = trim(upper(NEW.pcc));
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_orgs BEFORE INSERT OR UPDATE ON orgs
    FOR EACH ROW EXECUTE PROCEDURE ins_orgs();

ALTER TABLE orgs ADD CONSTRAINT orgs_pcc_unique UNIQUE (pcc);

CREATE OR REPLACE FUNCTION upd_entitys() RETURNS trigger AS $$
DECLARE
	v_pcc				varchar(7);
BEGIN

	IF((OLD.change_pcc <> NEW.change_pcc) or (OLD.change_son <> NEW.change_son))THEN
		SELECT pcc INTO v_pcc
		FROM orgs WHERE org_id = NEW.org_id;

		INSERT INTO change_pccs (entity_id, son, pcc, change_son, change_pcc)
		VALUES (NEW.entity_id, trim(upper(NEW.son)) , v_pcc, trim(upper(NEW.change_son)), trim(upper(NEW.change_pcc)));
 	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER upd_entitys BEFORE UPDATE ON entitys
    FOR EACH ROW EXECUTE PROCEDURE upd_entitys();

CREATE OR REPLACE FUNCTION ins_change_pccs() RETURNS trigger AS $$
BEGIN
	NEW.approve_status = 'Completed';
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_change_pccs BEFORE INSERT ON change_pccs
    FOR EACH ROW EXECUTE PROCEDURE ins_change_pccs();

CREATE OR REPLACE FUNCTION upd_change_pccs() RETURNS trigger AS $$
DECLARE
    v_org_id                integer;
    v_entity_id                integer;
BEGIN

    IF((OLD.approve_status = 'Completed') AND (NEW.approve_status = 'Approved'))THEN
        SELECT orgs.org_id INTO v_org_id
        FROM orgs WHERE (orgs.pcc = NEW.change_pcc);
        IF((NEW.change_pcc is null) or (v_org_id is null))THEN RAISE EXCEPTION 'No Travel Agency with new PCC'; END IF;

        SELECT entity_id INTO v_entity_id
        FROM entitys
        WHERE (org_id = v_org_id) AND (entitys.son = NEW.change_son);
        IF(v_entity_id is not null)THEN RAISE EXCEPTION 'A consultant with that SON already exists'; END IF;

        UPDATE entitys SET org_id = v_org_id, pcc_son = NEW.change_pcc, son = NEW.change_son
        WHERE entity_id = NEW.entity_id;
     END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER upd_change_pccs BEFORE UPDATE ON change_pccs
    FOR EACH ROW EXECUTE PROCEDURE upd_change_pccs();

CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON change_pccs
    FOR EACH ROW EXECUTE PROCEDURE upd_action();

CREATE OR REPLACE FUNCTION get_town(integer) RETURNS text AS $$
	SELECT towns.town_name FROM towns
	JOIN orgs ON orgs.town_id = towns.town_id
	JOIN vw_entitys ON vw_entitys.org_id = orgs.org_id
	WHERE vw_entitys.entity_id = $1;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION get_org_id(varchar(12)) RETURNS integer AS $$
	SELECT org_id FROM entitys WHERE entity_id = $1::integer;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION ins_sys_reset() RETURNS trigger AS $$
DECLARE
	v_entity_id			integer;
	v_org_id			integer;
	v_password			varchar(32);
BEGIN
	SELECT entity_id, org_id INTO v_entity_id, v_org_id
	FROM entitys
	WHERE (lower(trim(primary_email)) = lower(trim(NEW.request_email))) AND is_active = true;

	IF(v_entity_id is not null) THEN
		v_password := upper(substring(md5(random()::text) from 3 for 9));

		UPDATE entitys SET first_password = v_password, entity_password = md5(v_password)
		WHERE entity_id = v_entity_id;

		INSERT INTO sys_emailed (org_id, sys_email_id, table_id, table_name, email_type)
		VALUES(v_org_id, 6, v_entity_id, 'entitys', 4);
	ELSE
		RAISE EXCEPTION 'That email address is not available';
	END IF;

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER upd_action
  BEFORE INSERT OR UPDATE
  ON points
  FOR EACH ROW
  EXECUTE PROCEDURE upd_action();


CREATE OR REPLACE FUNCTION getSonbalance(integer,character(20))
  RETURNS real AS
$$
DECLARE
	v_org_id 			integer;
	v_function_role		text;
	v_balance			real;
BEGIN
	v_balance = 0::real;
	SELECT org_id,function_role INTO v_org_id, v_function_role FROM vw_entitys WHERE entity_id = $1;
	IF(v_function_role = 'manager')THEN
		SELECT COALESCE(sum(dr+bonus - cr), 0) INTO v_balance
		FROM vw_pcc_statement
		WHERE org_id = v_org_id AND order_date < $2::date;
	END IF;
	IF(v_function_role = 'consultant')THEN
		SELECT COALESCE(sum(dr+bonus - cr), 0) INTO v_balance
		FROM vw_son_statement
		WHERE entity_id = $1 AND order_date < $2::date;
	END IF;

	IF(v_function_role = 'admin')THEN
		SELECT COALESCE(sum(dr+bonus - cr), 0) INTO v_balance
		FROM vw_pcc_statement
		WHERE org_id = 0 AND order_date < $2::date;
	END IF;
	RETURN v_balance;
END;
$$
  LANGUAGE plpgsql;


  CREATE OR REPLACE FUNCTION getPccbalance(integer,character(20))
    RETURNS real AS
  $$
  DECLARE
  	v_org_id 			integer;
  	v_function_role		text;
  	v_balance			real;
  BEGIN
  	v_balance = 0::real;

	SELECT COALESCE(sum(dr+bonus - cr), 0) INTO v_balance
	FROM vw_pcc_statement
	WHERE org_id = $1 AND order_date < $2::date;
  	RETURN v_balance;
  END;
  $$
    LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION emailed_dob(integer,character varying)RETURNS character varying AS $$
DECLARE
  v_org_id                integer;
  v_entity_name            varchar(120);
  v_sms_number		varchar(25);
BEGIN
  SELECT org_id, entity_name, primary_telephone INTO v_org_id, v_entity_name, v_sms_number
  FROM entitys WHERE (entity_id = $2::int);
  UPDATE entitys SET dob_email = current_date WHERE (entity_id = $2::int);
  INSERT INTO sms (folder_id, entity_id, org_id, sms_number, message)
  VALUES (0,$2::int, v_org_id, v_sms_number, 'Its birthday for ' || v_entity_name);

  RETURN 'Done';
END;
$$
  LANGUAGE plpgsql;

  CREATE OR REPLACE FUNCTION upd_bonus( character varying, character varying,  character varying,  character varying)
 RETURNS character varying AS $$
DECLARE
ps		varchar(16);
msg		varchar(50);
BEGIN
	ps := 'Approved';
	UPDATE bonus SET approve_status = ps WHERE (bonus_id = $1::int);
	msg := 'Bonus Approved';
	RETURN msg;
END;
$$
  LANGUAGE plpgsql;
