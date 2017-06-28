
 CREATE OR REPLACE FUNCTION ins_applicants()  RETURNS trigger AS
 $BODY$
 DECLARE
 rec 			RECORD;
 v_entity_id		integer;
    BEGIN
    IF (TG_OP = 'INSERT') THEN
    	IF(NEW.entity_id IS NULL) THEN
    		SELECT entity_id INTO v_entity_id
    		FROM entitys
    		WHERE (trim(lower(user_name)) = trim(lower(NEW.applicant_email)));
    		IF(v_entity_id is null)THEN
    			SELECT org_id INTO rec
    			FROM orgs WHERE (is_default = true);
    			NEW.entity_id := nextval('entitys_entity_id_seq');
    			INSERT INTO entitys (entity_id, org_id, entity_type_id,entity_name, User_name,
    				primary_email, son,function_role,is_active)
    			VALUES (NEW.entity_id, rec.org_id, 0, NEW.son,
    				lower(NEW.applicant_email), lower(NEW.applicant_email),New.son, 'applicant',false);
    		ELSE
    			RAISE EXCEPTION 'The username exists use a different one or reset password for the current one';
    		END IF;
    	END IF;
    	INSERT INTO sys_emailed (sys_email_id, table_id, table_name)
    	VALUES (1, NEW.entity_id, 'applicant');

    END IF;
    RETURN NEW;
    END;
 $BODY$
   LANGUAGE plpgsql;

 CREATE TRIGGER ins_applicants BEFORE INSERT OR UPDATE ON applicants
   FOR EACH ROW  EXECUTE PROCEDURE ins_applicants();

CREATE OR REPLACE FUNCTION ins_orders() RETURNS trigger AS $$
DECLARE
v_order integer;

BEGIN
IF (NEW.order_details_id IS NULL) THEN
UPDATE order_details SET order_id=t.id
FROM (select orders.order_id AS id FROM orders WHERE orders.order_id = NEW.order_id)AS t ;

END IF;
return new;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_orders AFTER INSERT ON order_details
    FOR EACH ROW EXECUTE PROCEDURE ins_orders();

    CREATE TRIGGER upd_approvals
      AFTER INSERT OR UPDATE
      ON orders
      FOR EACH ROW
      EXECUTE PROCEDURE upd_approvals();


CREATE OR REPLACE FUNCTION ins_pccs()
RETURNS trigger AS
  $BODY$
      BEGIN
      	IF(NEW.pcc is not null) THEN
      		INSERT INTO orgs (org_name, org_sufix, is_active, pcc)
      		VALUES (NEW.agency_name, NEW.pcc,'true',NEW.pcc);
      	END IF;

      	RETURN NEW;
      END;
  $BODY$
    LANGUAGE plpgsql;

CREATE TRIGGER ins_pccs
    BEFORE INSERT
    ON pccs
    FOR EACH ROW
    EXECUTE PROCEDURE ins_pccs();

CREATE OR REPLACE FUNCTION upd_applicants(
    integer,
    integer,
    integer,
    character)
  RETURNS character AS
$BODY$
DECLARE
ps		varchar(16);
en_id	Integer;
app_id		Integer;
v_pcc varchar(4);
rec RECORD;
BEGIN
ps := 'New';
IF ($3 = 1) THEN
		ps := 'Approved';
		SELECT pseudo_code INTO v_pcc FROM applicants WHERE entity_id = $1;
		SELECT org_id INTO rec
		FROM orgs WHERE (pcc = v_pcc);
		IF(rec IS NULL)THEN
			RAISE EXCEPTION 'Pseudo Code Does not Exist';
		END IF;
		UPDATE applicants SET status = ps , org_id = rec.org_id,approved = true WHERE entity_id = $1 ;
END IF;
IF ($3 = 2) THEN
		ps := 'Rejected';
		UPDATE applicants SET status = ps , approved = false WHERE entity_id = $1 ;
END IF;

IF ($3 = 1) THEN
UPDATE entitys SET is_active = 'true' , org_id= rec.org_id WHERE entity_id = $1;
END IF;
IF ($3 = 2) THEN
UPDATE entitys SET is_active = 'false' WHERE entity_id = $1;
END IF;
RETURN 'Updated Successfull';
END;
$BODY$
  LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION upd_orders_status (integer,integer,integer,char)RETURNS varying AS
$BODY$
    DECLARE
    msg varying;
    BEGIN
        IF ($3 = 2) THEN
            UPDATE orders SET order_status = 'Collected' WHERE order_id = $1;
        END IF;
        IF ($3 = 1) THEN
            UPDATE orders SET order_status = 'Awaiting Collection' WHERE order_id = $1;
        END IF;
        IF ($3 = 3) THEN
            UPDATE orders SET order_status = 'Closed' WHERE order_id = $1;
        END IF;
        RETURN 'Successfully Updated';
    END;
$BODY$
LANGUAGE plpgsql ;


CREATE OR REPLACE FUNCTION upd_approve_orders(integer, integer,  integer,character)RETURNS character varying AS
    $BODY$
        DECLARE
        reca	RECORD;
        wfid	integer;
        vorgid	integer;
        vnotice	boolean;
        vadvice	boolean;
        BEGIN
            SELECT notice, advice, org_id INTO vnotice, vadvice, vorgid FROM workflow_phases
            WHERE (workflow_phase_id = 1);
            IF ($3 = 'Processing Order') THEN
                INSERT INTO sys_emailed (table_id, table_name, email_type, org_id)
                VALUES (NEW.order_id, TG_TABLE_NAME, 1, vorgid);
            END IF;
            IF ($3 = 'Awaiting Collection') AND (vadvice = true)  THEN
                INSERT INTO sys_emailed (table_id, table_name, email_type, org_id)
                VALUES (NEW.order_id, TG_TABLE_NAME, 1, vorgid);
            END IF;
            IF ($3 = 'Collected') AND (vnotice = true)  THEN
                INSERT INTO sys_emailed (table_id, table_name, email_type, org_id)
                VALUES (NEW.order_id, TG_TABLE_NAME, 2, vorgid);
            END IF;
            IF ($3 = 'Close') AND (vnotice = true)  THEN
                INSERT INTO sys_emailed (table_id, table_name, email_type, org_id)
                VALUES (NEW.order_id, TG_TABLE_NAME, 2, vorgid);
            END IF;
            RETURN NULL;
        END;
    $BODY$
LANGUAGE plpgsql;

CREATE TRIGGER upd_approve_orders
    AFTER INSERT OR UPDATE
    ON orders
    FOR EACH ROW
EXECUTE PROCEDURE upd_approve_orders();


CREATE OR REPLACE FUNCTION son_segments( char(7), char(4))  RETURNS numeric AS
    $BODY$
    	SELECT COALESCE(SUM(total_segs),0.0)  FROM vw_son_segs WHERE son = $1 AND pcc = $2;
    $BODY$
LANGUAGE sql;

CREATE OR REPLACE FUNCTION generate_points(
    character,
    character,
    character,
    character)
  RETURNS date AS
$BODY$
 DECLARE
	 v_period		date;
	 v_points		bigint;
	 v_amount 		real;
	 v_percent 		real;
	  v_bonus 		real;
	 rec vw_son_segs%rowtype;
 BEGIN
	SELECT start_date INTO v_period FROM periods WHERE period_id = $1::int AND closed = false;
	IF(v_period IS NULL)THEN
	RAISE EXCEPTION 'Period is closed';
	END IF;
	FOR rec IN select * from vw_son_segs WHERE (ticket_period = to_char(v_period, 'mm') ||to_char(v_period, 'yyyy'))
	LOOP
	SELECT percentage INTO v_percent FROM vw_bonus WHERE son = rec.son AND pcc = rec.pcc ;

	IF(1<= rec.total_segs::int  AND rec.total_segs::int <=250 ) THEN
		v_amount := 12;
		v_points := rec.total_segs * 12 ;
		v_bonus := (v_percent/100)*v_points;
	END IF;
	IF(rec.total_segs::int >=251 AND rec.total_segs::int <=500) THEN
		v_amount := 16;
		v_points := rec.total_segs * 16 ;
		v_bonus := (v_percent/100)*v_points;
	END IF;
	IF(rec.total_segs::int >=501 ) THEN
		v_amount := 16;
		v_points := rec.total_segs * 20 ;
		v_bonus := (v_percent/100)*v_points;
	END IF;
	INSERT INTO points (period,pcc,son,segments,amount,points,bonus)
	VALUES (v_period,rec.pcc,rec.son,rec.total_segs,v_amount,v_points,(v_bonus::float4));
	END LOOP;
	IF(rec IS NULL)THEN
	RAISE EXCEPTION 'There are no segments for this month';
	END IF;
	UPDATE periods SET closed = true WHERE period_id = $1::int;
	RETURN v_period;
 END;
 $BODY$
  LANGUAGE plpgsql ;



  CREATE OR REPLACE FUNCTION getbalance(
      character,
      character)
    RETURNS double precision AS
  $BODY$
      	SELECT (SELECT round(COALESCE(SUM(points),0.0)+COALESCE(SUM(bonus),0.0))AS amount  FROM points WHERE son = $2 AND pcc = $1)-
      	(SELECT COALESCE(sum(ordertotalamount),0.0)AS sum FROM vw_orders WHERE son = $2 AND pcc = $1) 	;
      $BODY$
    LANGUAGE sql;

  CREATE SEQUENCE batch_id_seq
    INCREMENT 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1;


    CREATE OR REPLACE FUNCTION upd_orders_batch(
    character,
    character,
    character,
    character)
  RETURNS character AS
$BODY$
	DECLARE
	v_batch  integer;
	msg 	character(50);
	BEGIN
		IF ($3::int = 1) THEN

		v_batch := (SELECT last_value FROM batch_id_seq) ;
			UPDATE orders SET batch_no = v_batch,batch_date = now() WHERE order_id = $1::int;
			msg := 'Orders Batched Successfully';
		END IF;
		IF($3::int = 2)THEN
			v_batch :=nextval('batch_id_seq');
			msg := 'Batch Closed';
		END IF;
		RETURN msg;
	END;
    $BODY$
  LANGUAGE plpgsql;



    CREATE OR REPLACE FUNCTION close_batch_seq()  RETURNS integer AS
$BODY$
DECLARE
v_batch  integer;
	BEGIN
	v_batch := nextval('batch_id_seq');
		RETURN v_batch;
	END;

$BODY$
  LANGUAGE plpgsql ;

  CREATE OR REPLACE FUNCTION getBirthday()
   RETURNS bigint AS
 $BODY$
 	SELECT  count(entity_id)
 	FROM vw_consultant WHERE to_char(consultant_dob, 'dd-mm') = to_char(CURRENT_DATE,'dd-mm');
 $BODY$
   LANGUAGE sql;


    CREATE OR REPLACE FUNCTION ins_bonus() RETURNS trigger AS $$
        DECLARE
            v_org_id 		integer;
            rec 			RECORD;
        BEGIN
            IF(NEW.org_id is null)THEN
                SELECT * INTO rec
                FROM vw_entitys
                WHERE entity_id = NEW.entity_id;
                NEW.org_id :=rec.org_id;
                NEW.pcc := rec.pcc;
                NEW.son := rec.son;
            ELSEIF(NEW.org_id is not null)THEN
                SELECT * INTO rec
                FROM orgs
                WHERE org_id = NEW.org_id;
                NEW.pcc :=rec.pcc;
            END IF;
            RETURN NEW;
        END;
    $$ LANGUAGE plpgsql;

   CREATE TRIGGER ins_bonus BEFORE INSERT OR UPDATE ON bonus
      FOR EACH ROW EXECUTE PROCEDURE ins_bonus();


    CREATE OR REPLACE FUNCTION getBatch_no() RETURNS bigint AS
        $BODY$
            SELECT last_value FROM batch_id_seq;
        $BODY$
    LANGUAGE sql;























    CREATE OR REPLACE FUNCTION generate_points(
   character,
   character,
   character,
   character)
 RETURNS date AS
$BODY$
DECLARE
    v_period		date;
    v_points		bigint;
    v_amount 		real;
    rec_amount real;
    rec_percent real;
    v_percent 		real;
     v_bonus 		real;
    rec vw_son_segs%rowtype;
    v_rec 		RECORD;
BEGIN
   SELECT start_date INTO v_period FROM periods WHERE period_id = $1::int AND closed = false;
   IF(v_period IS NULL)THEN
   RAISE EXCEPTION 'Period is closed';
   END IF;
   FOR rec IN select * from vw_son_segs WHERE (ticket_period = to_char(v_period, 'mm') ||to_char(v_period, 'yyyy'))
   LOOP
   SELECT * INTO v_rec FROM vw_son_bonus WHERE son = rec.son AND pcc = rec.pcc AND is_active = true AND period = rec.ticket_period;
   --RAISE EXCEPTION '%',rec.son;
   IF(v_rec.entity_id IS NOT NULL)THEN
       rec_amount :=v_rec.amount;
       rec_percent :=v_rec.percentage;
       IF(v_rec.amount IS NOT NULL AND v_rec.percentage IS NULL)THEN
           IF(1<= rec.total_segs::int  AND rec.total_segs::int <=250 ) THEN
               v_amount := 12;
               v_points := rec.total_segs * 12 ;
               IF(rec_percent IS NOT NULL)THEN
                   v_bonus := (rec_percent/100)*v_points;
               END IF;
               IF(rec_amount IS NOT NULL)THEN
                   v_bonus := rec_amount * 1;
               END IF;
           END IF;
           IF(rec.total_segs::int >=251 AND rec.total_segs::int <=500) THEN
               v_amount := 16;
               v_points := rec.total_segs * 16 ;
               IF(rec_percent IS NOT NULL)THEN
                   v_bonus := (rec_percent/100)*v_points;
               ELSEIF(rec_amount IS NOT NULL)THEN
                   v_bonus := rec_amount * 1;
               END IF;
           END IF;
           IF(rec.total_segs::int >=501 ) THEN
               v_amount := 16;
               v_points := rec.total_segs * 20 ;
               IF(rec_percent IS NOT NULL)THEN
                   v_bonus := (rec_percent/100)*v_points;
               ELSEIF(rec_amount IS NOT NULL)THEN
                   v_bonus := rec_amount * 1;
               END IF;
           END IF;
           INSERT INTO points (period,pcc,son,segments,amount,points,bonus)
           VALUES (v_period,rec.pcc,rec.son,rec.total_segs,v_amount,v_points,(v_bonus::float4));
       END IF;
       IF(v_rec.amount IS NULL AND v_rec.percentage IS NOT NULL)THEN
           rec_percent :=v_rec.percentage;
           IF(1<= rec.total_segs::int  AND rec.total_segs::int <=250 ) THEN
               v_amount := 12;
               v_points := rec.total_segs * 12 ;
               IF(rec_percent IS NOT NULL)THEN
                   v_bonus := (rec_percent/100)*v_points;
               ELSEIF(rec_amount IS NOT NULL)THEN
                   v_bonus := rec_amount * 1;
               END IF;
           END IF;
           IF(rec.total_segs::int >=251 AND rec.total_segs::int <=500) THEN
               v_amount := 16;
               v_points := rec.total_segs * 16 ;
               IF(rec_percent IS NOT NULL)THEN
                   v_bonus := (rec_percent/100)*v_points;
               ELSEIF(rec_amount IS NOT NULL)THEN
                   v_bonus := rec_amount * 1;
               END IF;
           END IF;
           IF(rec.total_segs::int >=501 ) THEN
               v_amount := 16;
               v_points := rec.total_segs * 20 ;
               IF(rec_percent IS NOT NULL)THEN
                   v_bonus := (rec_percent/100)*v_points;
               ELSEIF(rec_amount IS NOT NULL)THEN
                   v_bonus := rec_amount * 1;
               END IF;
           END IF;
           INSERT INTO points (period,pcc,son,segments,amount,points,bonus)
           VALUES (v_period,rec.pcc,rec.son,rec.total_segs,v_amount,v_points,(v_bonus::float4));
       END IF;
   END IF;

   IF(v_rec.entity_id IS NULL)THEN
       SELECT * INTO v_rec FROM vw_bonus WHERE  pcc = rec.pcc AND is_active = true AND period = rec.ticket_period;
       IF(v_rec.amount IS NOT NULL AND v_rec.percentage IS NULL)THEN
           rec_amount :=v_rec.amount;
           rec_percent := v_rec.percentage;
           IF(1<= rec.total_segs::int  AND rec.total_segs::int <=250 ) THEN
               v_amount := 12;
               v_points := rec.total_segs * 12 ;
               IF(rec_percent IS NOT NULL)THEN
                   v_bonus := (rec_percent/100)*v_points;
               ELSEIF(rec_amount IS NOT NULL)THEN
                   v_bonus := rec_amount * 1;
               END IF;
           END IF;
           IF(rec.total_segs::int >=251 AND rec.total_segs::int <=500) THEN
               v_amount := 16;
               v_points := rec.total_segs * 16 ;
               IF(rec_percent IS NOT NULL)THEN
                   v_bonus := (rec_percent/100)*v_points;
               ELSEIF(rec_amount IS NOT NULL)THEN
                   v_bonus := rec_amount * 1;
               END IF;
           END IF;
           IF(rec.total_segs::int >=501 ) THEN
               v_amount := 16;
               v_points := rec.total_segs * 20 ;
               IF(rec_percent IS NOT NULL)THEN
                   v_bonus := (rec_percent/100)*v_points;
               ELSEIF(rec_amount IS NOT NULL)THEN
                   v_bonus := rec_amount * 1;
               END IF;
           END IF;
           INSERT INTO points (period,pcc,son,segments,amount,points,bonus)
           VALUES (v_period,rec.pcc,rec.son,rec.total_segs,v_amount,v_points,(v_bonus::float4));
       END IF;
       IF(v_rec.amount IS NULL AND v_rec.percentage IS NOT NULL)THEN
           rec_percent :=v_rec.percentage;
           IF(1<= rec.total_segs::int  AND rec.total_segs::int <=250 ) THEN
               v_amount := 12;
               v_points := rec.total_segs * 12 ;
               IF(rec_percent IS NOT NULL)THEN
                   v_bonus := (rec_percent/100)*v_points;
               ELSEIF(rec_amount IS NOT NULL)THEN
                   v_bonus := rec_amount * 1;
               END IF;
           END IF;
           IF(rec.total_segs::int >=251 AND rec.total_segs::int <=500) THEN
               v_amount := 16;
               v_points := rec.total_segs * 16 ;
               IF(rec_percent IS NOT NULL)THEN
                   v_bonus := (rec_percent/100)*v_points;
               ELSEIF(rec_amount IS NOT NULL)THEN
                   v_bonus := rec_amount * 1;
               END IF;
           END IF;
           IF(rec.total_segs::int >=501 ) THEN
               v_amount := 16;
               v_points := rec.total_segs * 20 ;
               IF(rec_percent IS NOT NULL)THEN
                   v_bonus := (rec_percent/100)*v_points;
               ELSEIF(rec_amount IS NOT NULL)THEN
                   v_bonus := rec_amount * 1;
               END IF;
           END IF;
           INSERT INTO points (period,pcc,son,segments,amount,points,bonus)
           VALUES (v_period,rec.pcc,rec.son,rec.total_segs,v_amount,v_points,(v_bonus::float4));
       END IF;
   END IF;
   END LOOP;
   IF(rec IS NULL)THEN
   RAISE EXCEPTION 'There are no segments for this month';
   END IF;
   UPDATE periods SET closed = true WHERE period_id = $1::int;
   RETURN v_period;
END;
$BODY$
 LANGUAGE plpgsql;
