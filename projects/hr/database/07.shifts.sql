

CREATE TABLE shifts (
	shift_id				serial primary key,
	project_id				integer references projects,
	org_id					integer references orgs,
	shift_name				varchar(50),
	shift_hours				integer not null default 8,
	
	include_holiday 		boolean default false not null,

	include_mon				boolean default true not null,
	include_tue				boolean default true not null,
	include_wed				boolean default true not null,
	include_thu				boolean default true not null,
	include_fri				boolean default true not null,
	include_sat				boolean default false not null,
	include_sun				boolean default false not null,

	time_in					time not null,
	time_out				time not null,
	
	details					text
);
CREATE INDEX shifts_project_id ON shifts (project_id);
CREATE INDEX shifts_org_id ON shifts (org_id);

CREATE TABLE shift_schedule (
	shift_schedule_id		serial primary key,
	shift_id				integer references shifts,
	entity_id				integer references entitys,
	org_id					integer references orgs,

	is_active				boolean default true not null,

	details					text
);
CREATE INDEX shift_schedule_shift_id ON shift_schedule (shift_id);
CREATE INDEX shift_schedule_entity_id ON shift_schedule (entity_id);
CREATE INDEX shift_schedule_org_id ON shift_schedule (org_id);


CREATE VIEW vw_shifts AS
	SELECT projects.project_id, projects.project_name, 
		shifts.org_id, shifts.shift_id, shifts.shift_name, shifts.shift_hours, shifts.include_holiday, 
		shifts.include_mon, shifts.include_tue, shifts.include_wed, shifts.include_thu, shifts.include_fri, 
		shifts.include_sat, shifts.include_sun, shifts.time_in, shifts.time_out, shifts.details
		
	FROM shifts 
		LEFT JOIN projects ON shifts.project_id = projects.project_id;

CREATE VIEW vw_shift_schedule AS
	SELECT vw_shifts.project_id, vw_shifts.project_name, 
		vw_shifts.shift_id, vw_shifts.shift_name, vw_shifts.shift_hours, vw_shifts.include_holiday, 
		vw_shifts.include_mon, vw_shifts.include_tue, vw_shifts.include_wed, vw_shifts.include_thu, vw_shifts.include_fri, 
		vw_shifts.include_sat, vw_shifts.include_sun, vw_shifts.time_in, vw_shifts.time_out, 

		entitys.entity_id, entitys.entity_name, 
		
		shift_schedule.org_id, shift_schedule.shift_schedule_id, shift_schedule.is_active, shift_schedule.details
	
	FROM shift_schedule INNER JOIN vw_shifts ON shift_schedule.shift_id = vw_shifts.shift_id
		INNER JOIN entitys ON shift_schedule.entity_id = entitys.entity_id;
	
	
	