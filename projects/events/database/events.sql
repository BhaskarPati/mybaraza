---Project Database File
CREATE TABLE events (
	event_id				serial primary key,
	entity_id				integer references entitys,
	event_name				varchar(240),
	start_date				date,
	end_date				date,
	budget					real,
	event_status			varchar(16) default 'Concept',
	application_date		timestamp default now() not null,
	completion_date			timestamp,
	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	action_date				timestamp,	
	details					text
);
CREATE INDEX events_entity_id ON events (entity_id);

CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON events
    FOR EACH ROW EXECUTE PROCEDURE upd_action();

CREATE OR REPLACE FUNCTION Upd_Complete_Event(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	msg varchar(120);
BEGIN
	IF ($3 = '1') THEN
		UPDATE events SET approve_status = 'Completed', completion_date = now()
		WHERE (event_id = CAST($1 as int));
		msg := 'Completed the Event';
	END IF;

	return msg;
END;
$$ LANGUAGE plpgsql;

