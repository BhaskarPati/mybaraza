CREATE OR REPLACE FUNCTION get_benefit_section_a(integer) RETURNS text AS $$
    SELECT individual AS result from vw_benefits WHERE rate_type_id = $1 AND benefit_section IN('1A');
$$LANGUAGE SQL;
CREATE OR REPLACE FUNCTION get_benefit_section_b(integer) RETURNS text AS $$
    SELECT individual AS result from vw_benefits WHERE rate_type_id = $1 AND benefit_section IN('1C');
$$LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_cop_benefit_section_a(integer) RETURNS text AS $$
    SELECT individual AS result from vw_corporate_benefits WHERE rate_type_id = $1 AND corporate_section IN('1A');
$$LANGUAGE SQL;
CREATE OR REPLACE FUNCTION get_cop_benefit_section_b(integer) RETURNS text AS $$
    SELECT individual AS result from vw_corporate_benefits WHERE rate_type_id =  $1 AND corporate_section IN('1C');
$$LANGUAGE SQL;

CREATE OR REPLACE FUNCTION ins_policy_number()  RETURNS trigger AS $$
DECLARE
  base_val          char(50);
  yr 	             char(2);
  passenger_no      char(4);
  sequence_no       char(50);
  v_policy_no       integer;
BEGIN
	yr := (SELECT to_char as year from to_char(current_timestamp, 'YY'));
    IF (NEW.incountry is false) THEN
        v_policy_no := nextval('policy_no_seq');
    	passenger_no := (SELECT TO_CHAR(v_policy_no,'fm0000'));
    	sequence_no :=(SELECT policy_sequence_no from policy_sequence);
    	base_val := trim(11||yr||sequence_no || passenger_no);
    	NEW.policy_number := base_val;
    END IF;

    IF(NEW.incountry is true)THEN
        v_policy_no := nextval('policy_no_incountry_seq');
        passenger_no := (SELECT TO_CHAR(v_policy_no,'fm0000'));
        sequence_no :=(SELECT policy_sequence_no from policy_sequence);
        base_val := trim(12||yr||sequence_no || passenger_no);
        NEW.policy_number := base_val;
    END IF;
	RETURN NEW ;
END;
$$
LANGUAGE plpgsql ;

CREATE OR REPLACE FUNCTION ins_passengers()
  RETURNS trigger AS
$BODY$
DECLARE
v_credit_limit real;
v_credit real;
BEGIN
	v_credit := 0;
	v_credit_limit := 0;
    SELECT credit_limit INTO v_credit FROM orgs WHERE org_id = NEW.org_id;
    IF(NEW.incountry IS TRUE AND NEW.customer_code IS null) THEN
        v_credit_limit := v_credit - (NEW.kesamount::real/NEW.exchange_rate::real);
    ELSE
        v_credit_limit := v_credit - NEW.totalamount_covered;
    END IF;
    --raise exception '%',v_credit_limit;
    UPDATE orgs SET credit_limit = v_credit_limit WHERE org_id = NEW.org_id;

    IF(NEW.customer_code IS null) THEN
    	INSERT INTO sys_emailed(sys_email_id, org_id, table_id, table_name, narrative)
    	VALUES(2, NEW.org_id, NEW.passenger_id, 'passengers','Policy Number:'||NEW.policy_number||'\n\nPassanger Name:'||NEW.passenger_name);
    ELSE
        INSERT INTO sys_emailed(sys_email_id, org_id, table_id, table_name, narrative)
    	VALUES(3, NEW.org_id, NEW.passenger_id, 'passengers','Policy Number:'||NEW.policy_number||'\n\nPassanger Name:'||NEW.passenger_name);
    END IF;

RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql;


  CREATE TRIGGER ins_passengers
    BEFORE INSERT
    ON passengers
    FOR EACH ROW
    EXECUTE PROCEDURE ins_passengers();

CREATE TRIGGER ins_policy_number
    BEFORE INSERT
    ON passengers
    FOR EACH ROW
    EXECUTE PROCEDURE ins_policy_number();

CREATE OR REPLACE FUNCTION upd_passenger(varchar(20),varchar(20),varchar(20),varchar(20)) RETURNS varchar(120) AS $$
DECLARE
	msg 		varchar(50);
BEGIN
	IF ($3::integer = 1) THEN

		UPDATE passengers SET approved = false WHERE passenger_id = $1::integer;
		msg := 'Emergency Card Canceled Successfully';
	END IF;

	IF($3::integer = 2)THEN
    UPDATE passengers SET approved = true WHERE passenger_id = $1::integer;
    msg := 'Emergency Card Reverted Successfully';
	END IF;

	RETURN msg;
END;
$$ LANGUAGE plpgsql;


CREATE SEQUENCE policy_no_seq  INCREMENT 1  MINVALUE 1  MAXVALUE 9223372036854775807  START 1  CACHE 1;
CREATE SEQUENCE policy_no_incountry_seq  INCREMENT 1  MINVALUE 1  MAXVALUE 9223372036854775807  START 1  CACHE 1;

CREATE OR REPLACE FUNCTION ins_sys_reset() RETURNS trigger AS $$
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

		INSERT INTO sys_emailed (org_id, sys_email_id, table_id, table_name)
		VALUES(v_org_id, 4, v_entity_id, 'entitys');
	END IF;

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_sys_reset AFTER INSERT ON sys_reset
    FOR EACH ROW EXECUTE PROCEDURE ins_sys_reset();
