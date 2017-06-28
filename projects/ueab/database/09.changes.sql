

ALTER TABLE instructors ADD dvc					boolean default false not null;

CREATE OR REPLACE FUNCTION aft_instructors() RETURNS trigger AS $$
DECLARE
	v_role		varchar(240);
	v_no_org	boolean;
BEGIN

	v_role := 'lecturer';
	v_no_org := false;
	IF(NEW.majoradvisor = true)THEN
		v_role := 'lecturer,major_advisor';
	END IF;
	IF(NEW.department_head = true)THEN
		v_role := 'lecturer,major_advisor,department_head';
		v_no_org := true;
	END IF;
	IF(NEW.school_dean = true)THEN
		v_role := 'lecturer,major_advisor,school_dean';
		v_no_org := true;
	END IF;
	IF(NEW.pgs_dean = true)THEN
		v_role := v_role || ',pgs_dean';
		v_no_org := true;
	END IF;
	IF(NEW.dvc = true)THEN
		v_role := v_role || ',dvc';
		v_no_org := true;
	END IF;

	IF(TG_OP = 'INSERT')THEN
		INSERT INTO entitys (org_id, entity_type_id, user_name, entity_name, Entity_Leader, Super_User, no_org, primary_email, function_role)
		VALUES (NEW.org_id, 11, NEW.instructorid, NEW.instructorname, false, false, false, NEW.email, v_role);
	ELSE
		UPDATE entitys SET function_role = v_role, no_org = v_no_org WHERE user_name = NEW.instructorid;
	END IF;

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

