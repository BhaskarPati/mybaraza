CREATE OR REPLACE FUNCTION update_levy(integer) RETURNS character varying(20) AS $$
DECLARE
rec	RECORD;
v_amount real;
v_policy_holder_fund real;
v_stamp_duty real;
v_training_levy real;
msg 	varchar(120);
BEGIN

FOR rec IN SELECT passenger_id, cover_amount  FROM passengers WHERE passenger_id > $1
LOOP
	v_policy_holder_fund := 0.25/100 *rec.cover_amount;
	v_stamp_duty := 0.39;
	v_training_levy := 0.2/100 *rec.cover_amount;
	UPDATE passengers SET training_levy =ROUND(v_training_levy::numeric,2) , stamp_duty=ROUND(v_stamp_duty::numeric,2), policy_holder_fund =ROUND(v_policy_holder_fund::numeric,2)
	 WHERE  passenger_id = rec.passenger_id;

END LOOP;
msg := 'updated';

RETURN msg;

END;
$$ LANGUAGE plpgsql;
