CREATE OR REPLACE FUNCTION ins_orders()
  RETURNS trigger AS
$BODY$
DECLARE
	v_order integer;
BEGIN

	INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type,mail_body, narrative)
	VALUES (4, NEW.order_id , 'vw_orders', 3, get_order_details(NEW.order_id), 'Order '||NEW.order_id||' has been submitted');
	RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql;


  CREATE OR REPLACE FUNCTION upd_orders_status(varchar(12), varchar(12), varchar(12),varchar(12))	RETURNS varchar(120) AS $$
  DECLARE
  	msg 		varchar(20);
  	details 	text;
  	v_org_id                integer;
  	v_entity_id            integer;
  	v_sms_number		varchar(25);
  	v_order_no			integer;
  	v_batch_no			integer;
  BEGIN
  SELECT entity_id, phone_no,batch_no,order_id INTO v_entity_id, v_sms_number,v_batch_no,v_order_no
  FROM orders WHERE (order_id = $1::integer);
  	IF ($3::integer = 1) THEN
  		UPDATE orders SET order_status = 'Awaiting Collection' WHERE order_id = $1::integer;
  		details :='Order '||v_batch_no||'-'||v_order_no||' is ready for collection';
  		INSERT INTO sys_emailed (table_id, sys_email_id, table_name, email_type, org_id,narrative)
  		VALUES ($1::integer,6 ,'orders', 3, 0,details);
  	END IF;

  	IF ($3::integer = 2) THEN
  		UPDATE orders SET order_status = 'Collected' WHERE order_id = $1::integer;
  		details := 'Order '||v_batch_no||'-'||v_order_no||' has been collected';
  		INSERT INTO sys_emailed (table_id, sys_email_id, table_name, email_type, org_id,narrative)
  		VALUES ($1::integer,7 ,'orders', 3, 0,details);
  	END IF;

  	IF ($3::integer = 3) THEN
  		UPDATE orders SET order_status = 'Closed' WHERE order_id = $1::integer;
  	END IF;


  	RETURN 'Successfully Updated';
  END;
  $$ LANGUAGE plpgsql;


  CREATE OR REPLACE FUNCTION upd_orders_batch(varchar(20),varchar(20),varchar(20),varchar(20)) RETURNS varchar(120) AS $BODY$
  DECLARE
  	v_batch  	integer;
  	msg 		varchar(50);
  BEGIN
  	IF ($3::integer = 1) THEN
  		v_batch := (SELECT last_value FROM batch_id_seq) ;
  		UPDATE orders SET batch_no = v_batch,batch_date = now(), approve_status = 'Completed' WHERE order_id = $1::integer;
  		INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type, mail_body, narrative)
  		VALUES (5, $1::integer , 'vw_orders', 3, get_order_details($1::integer), 'Order '||v_batch||'-'||$1::integer||' is being processed.');
  		msg := 'Orders Batched Successfully';
  	END IF;

  	IF($3::integer = 2)THEN
  		v_batch :=nextval('batch_id_seq');
  		msg := 'Batch Closed';
  	END IF;

  	RETURN msg;
  END;
  $BODY$ LANGUAGE plpgsql;


  CREATE OR REPLACE FUNCTION ins_sys_reset()
    RETURNS trigger AS
  $BODY$
  DECLARE
  	v_entity_id			integer;
  	v_org_id			integer;
  	v_password			varchar(32);
  BEGIN
  	SELECT entity_id, org_id INTO v_entity_id, v_org_id
  	FROM entitys
  	WHERE (lower(trim(primary_email)) = lower(trim(NEW.request_email)));

  	IF(v_entity_id is not null) THEN
  		v_password := upper(substring(md5(random()::text) from 3 for 9));

  		UPDATE entitys SET first_password = v_password, entity_password = md5(v_password)
  		WHERE entity_id = v_entity_id;

  		INSERT INTO sys_emailed (org_id, sys_email_id, table_id, table_name, email_type)
  		VALUES(v_org_id, 8, v_entity_id, 'entitys', 2);
  	END IF;

  	RETURN NULL;
  END;
  $BODY$
    LANGUAGE plpgsql;


      CREATE OR REPLACE FUNCTION ins_donate() RETURNS trigger AS $$
      DECLARE
      	rec 			RECORD;
      	v_entity_id		integer;
    	v_donated_by integer;
      	v_org_id		integer;
      BEGIN
      	IF (TG_OP = 'INSERT') THEN
      		SELECT org_id,entity_id INTO v_org_id,v_donated_by FROM entitys WHERE entity_id = NEW.donated_by;
      		SELECT entity_id INTO v_entity_id FROM entitys WHERE client_code = 'CSR';
      		IF(v_entity_id is null)THEN
      			RAISE EXCEPTION 'The CSR does not exists';
      		END IF;
      		NEW.org_id :=v_org_id;
      		NEW.entity_id :=v_entity_id;

    		INSERT INTO sys_emailed (org_id, sys_email_id, table_id, table_name)
      		VALUES(v_org_id, 10, v_donated_by, 'donation');
      	END IF;
      	RETURN NEW;
      END;
      $$
        LANGUAGE plpgsql ;
