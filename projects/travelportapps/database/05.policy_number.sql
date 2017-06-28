CREATE TABLE policy_sequence (
  policy_no_id serial primary key,
  policy_sequence_no character varying(50));
  INSERT INTO policy_sequence (policy_sequence_no ) VALUES('036A0528342');

CREATE FUNCTION ins_policy_number() RETURNS trigger AS $$
DECLARE
  base_val  char(50);
  yr 	integer;
  passenger_no char(4); 
  sequence_no char(50);
BEGIN
	yr :=(SELECT to_char as year from to_char(current_timestamp, 'YY'));
	passenger_no := (SELECT TO_CHAR(NEW.passenger_id,'fm0000'));
	
	sequence_no :=(SELECT policy_sequence_no from policy_sequence);
	base_val := trim(sequence_no || passenger_no || '-' || yr);
	NEW.policy_number := base_val;
	RETURN NEW;
END; $$ LANGUAGE plpgsql;


CREATE TRIGGER ins_policy_number
  BEFORE INSERT ON passengers
  FOR EACH ROW EXECUTE PROCEDURE ins_policy_number();
