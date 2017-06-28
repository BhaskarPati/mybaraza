CREATE OR REPLACE FUNCTION ins_projects() RETURNS trigger AS $$
DECLARE
    myrec RECORD;
	start_days integer;
BEGIN
	start_days := 0;
	FOR myrec IN SELECT entity_type_id, Define_phase_name,  
		CAST(((NEW.project_ending_date - NEW.project_start_date) * Define_phase_time / 100) as integer) as date_range, 
		(NEW.total_budget * Define_phase_cost / 100) as phase_cost
		FROM Define_Phases
		WHERE (project_type_id = NEW.project_type_id)
		ORDER BY define_phases.phase_order 
	LOOP

		INSERT INTO Phases (org_id, project_id, entity_type_id, phase_name, start_date, end_date, phase_cost)
		VALUES(NEW.org_id, NEW.project_id, myrec.entity_type_id, myrec.Define_phase_name, 
			NEW.start_date + start_days, 
			NEW.start_date + myrec.date_range + start_days, 
			myrec.phase_cost);
		
		start_days := start_days + myrec.date_range + 1;
	END LOOP;

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_projects AFTER INSERT ON projects
    FOR EACH ROW EXECUTE PROCEDURE ins_projects();

CREATE OR REPLACE FUNCTION ins_types() RETURNS trigger AS $$
BEGIN
		IF (NEW.goal_category_id=1) 
			THEN INSERT INTO project_types (project_type_id, org_id, project_type_name, details) 
			VALUES (NEW.goal_id, NEW.org_id, NEW.goal_name, NEW.details);
		END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_types AFTER INSERT ON goals
	FOR EACH ROW EXECUTE PROCEDURE ins_types();
