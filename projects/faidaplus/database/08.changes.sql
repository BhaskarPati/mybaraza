UPDATE sys_emails SET use_type = 3 WHERE sys_email_id = 10;
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
