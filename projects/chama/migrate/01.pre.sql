

CREATE OR REPLACE FUNCTION ins_members() RETURNS trigger AS $$
DECLARE
	rec 			RECORD;
	v_entity_id		integer;
	v_full_name			varchar(250);
BEGIN
	IF (TG_OP = 'INSERT') THEN
	
		IF (New.email is null)THEN
			RAISE EXCEPTION 'You have to enter an Email';
		ELSIF(NEW.first_name is null) AND (NEW.surname is null)THEN
			RAISE EXCEPTION 'You have need to enter Surname and First Name';
		ELSE
			Raise NOTICE 'Thank you';
		END IF;
		
		IF(NEW.Middle_name is null)THEN
			v_full_name =  NEW.First_name || '' || NEW.Surname;
		ELSE
			v_full_name =  NEW.First_name || ' ' || NEW.Middle_name || ' ' || NEW.Surname;
		END IF;
		NEW.full_name := v_full_name;
		
		IF(NEW.entity_id is null)THEN
			NEW.entity_id := nextval('entitys_entity_id_seq');

			INSERT INTO entitys (entity_id, org_id, entity_type_id, entity_name,
				user_name, primary_email, primary_telephone, function_role, details)
			VALUES (NEW.entity_id, New.org_id, 1, v_full_name,
				NEW.email, NEW.email, NEW.phone, 'member', NEW.details);
		ELSE
			INSERT INTO entitys (entity_id, org_id, entity_type_id, entity_name,
				user_name, primary_email, primary_telephone, function_role, details)
			VALUES (NEW.entity_id, New.org_id, 1, v_full_name,
				NEW.email, NEW.email, NEW.phone, 'member', NEW.details);
		END IF;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
