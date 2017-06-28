
CREATE OR REPLACE FUNCTION ins_policy_number() RETURNS trigger AS $$
	DECLARE
	  base_val  char(50);
	  yr 	integer;
	  passenger_no char(4);
	  v_policy_no integer;
	  sequence_no char(50);
	BEGIN
	IF (TG_OP = 'INSERT') THEN
		IF(NEW.approved is true)THEN
			v_policy_no := nextval('policy_no_seq');
			yr :=(SELECT to_char as year from to_char(current_timestamp, 'YY'));
			passenger_no := (SELECT TO_CHAR(v_policy_no,'fm0000'));

			sequence_no :=(SELECT policy_sequence_no from policy_sequence);
			base_val := trim(sequence_no || passenger_no || '-' || yr);
			NEW.policy_number := base_val;
			INSERT INTO sys_emailed(sys_email_id, org_id, table_id, table_name, narrative)
			VALUES(2,NEW.org_id,NEW.passenger_id,'passengers','Certificate Number:'||NEW.passenger_id||'\n\nPassanger Name:'||NEW.passenger_name);

		END IF;

	END IF;

	RETURN NEW;
END; $$ LANGUAGE plpgsql;


CREATE TRIGGER ins_policy_number
  BEFORE INSERT ON passengers
  FOR EACH ROW EXECUTE PROCEDURE ins_policy_number();


CREATE OR REPLACE FUNCTION upd_passengers() RETURNS trigger AS	$$
	DECLARE
		base_val  char(50);
		yr 	integer;
		passenger_no char(4);
		v_policy_no integer;
		sequence_no char(50);
	BEGIN
		IF(NEW.approved = true) THEN
			NEW.approved_date = CURRENT_TIMESTAMP;
			v_policy_no := nextval('policy_no_seq');
			yr :=(SELECT to_char as year from to_char(current_timestamp, 'YY'));
			passenger_no := (SELECT TO_CHAR(v_policy_no,'fm0000'));

			sequence_no :=(SELECT policy_sequence_no from policy_sequence);
			base_val := trim(sequence_no || passenger_no || '-' || yr);
			NEW.policy_number := base_val;

			INSERT INTO sys_emailed(sys_email_id, org_id, table_id, table_name, narrative)
			VALUES(2,NEW.org_id,NEW.passenger_id,'passengers','Certificate Number:'||NEW.passenger_id||'\n\nPassanger Name:'||NEW.passenger_name);

		END IF;
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER upd_passengers  BEFORE UPDATE OF approved ON passengers
FOR EACH ROW  EXECUTE PROCEDURE upd_passengers();


CREATE OR REPLACE FUNCTION upd_passenger(varchar(20),varchar(20),varchar(20),varchar(20)) RETURNS varchar(120) AS $$
DECLARE
	msg 		varchar(50);
BEGIN
	IF ($3::integer = 1) THEN

		UPDATE passengers SET is_valid = false WHERE passenger_id = $1::integer;
		msg := 'Certificate Canceled Successfully';
	END IF;

	IF($3::integer = 2)THEN
    UPDATE passengers SET is_valid = true WHERE passenger_id = $1::integer;
    msg := 'Certificate Reverted Successfully';
	END IF;

	RETURN msg;
END;
$$ LANGUAGE plpgsql;


CREATE SEQUENCE policy_no_seq  INCREMENT 1  MINVALUE 1  MAXVALUE 9223372036854775807  START 44  CACHE 1;
ALTER TABLE policy_no_seq
  OWNER TO postgres;


  CREATE OR REPLACE FUNCTION ins_passengers()  RETURNS trigger AS
  	$BODY$
  	BEGIN
  	 INSERT INTO sys_emailed(sys_email_id, org_id, table_id, table_name, narrative)
  	 VALUES(2,NEW.org_id,NEW.passenger_id,'passengers','Certificate Number:'||NEW.passenger_id||'\n\nPassanger Name:'||NEW.passenger_name);

  	RETURN NEW;
  	END;
  	$BODY$
  	LANGUAGE plpgsql;

CREATE FUNCTION getCreditLimitBalance(integer) RETURNS double precision AS $$
	DECLARE
		credit_limit 	double precision;
		cover_amount 	double precision;
		paid_amount 	double precision;
		current_limit_bl 	double precision;
		BEGIN
			credit_limit := COALESCE((SELECT orgs.credit_limit FROM orgs WHERE orgs.org_id = $1 GROUP BY orgs.credit_limit),0);
			cover_amount:= COALESCE((SELECT SUM(vw_allpassengers.totalamount_covered)AS cover_amount FROM vw_allpassengers WHERE org_id = $1
				GROUP BY org_id),0);

			current_limit_bl := ROUND(((credit_limit) - cover_amount)::numeric, 2);


		RETURN current_limit_bl;
		END;
$$LANGUAGE plpgsql;

CREATE FUNCTION getTotalAmount(integer) RETURNS double precision AS $$
	DECLARE
		cover_amount 	double precision;
		BEGIN
			cover_amount:= COALESCE((SELECT SUM(vw_allpassengers.totalamount_covered)AS cover_amount FROM vw_allpassengers WHERE org_id = $1
				GROUP BY org_id),0);

		RETURN ROUND(cover_amount::numeric,2);
		END;
$$LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION payment_reminder(integer, character varying)
  RETURNS character varying AS
$BODY$
DECLARE
  v_org_id                integer;
  v_entity_name           varchar(120);
BEGIN

  UPDATE  passengers SET reminder_email = current_date WHERE (passenger_id = $2::int);

  RETURN 'Done';
END;
$BODY$
  LANGUAGE plpgsql;

  CREATE OR REPLACE FUNCTION expired_invoice(integer, character varying)
    RETURNS character varying AS
  $BODY$
  DECLARE
    v_org_id                integer;
    v_entity_name           varchar(120);
  BEGIN

    UPDATE  passengers SET status = 'Expired', is_valid = false, reminder_email = current_date WHERE (passenger_id = $2::int);

    RETURN 'Done';
  END;
  $BODY$
    LANGUAGE plpgsql;
