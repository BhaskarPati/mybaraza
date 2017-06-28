CREATE OR REPLACE FUNCTION insstudentname() RETURNS trigger AS $$
DECLARE
	myrec RECORD;
	stdnum integer;
BEGIN	
	NEW.studentname := UPPER(NEW.surname)	|| ', ' || UPPER(NEW.firstname) || ' ' || UPPER(COALESCE(NEW.othernames, ''));

	IF (TG_OP = 'INSERT') AND (NEW.studentid is null) THEN
		SELECT max(cast(substring(studentid from 6 for 3) as int)) as stdno INTO myrec
		FROM students
		WHERE substring(studentid from 2 for 4) = to_char(current_timestamp, 'YYYY');

		if(myrec.stdno is null) then
			stdnum := 1;
		else
			stdnum := myrec.stdno + 1;
		end if;

		NEW.studentid := 'S' || to_char(current_timestamp, 'YYYY') || lpad(cast((stdnum) as varchar), 3, '0');
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION insstudentname() TO records;
GRANT EXECUTE ON FUNCTION insstudentname() TO registrar;
