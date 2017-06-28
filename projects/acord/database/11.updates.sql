CREATE TABLE project_types (
    project_type_id			serial primary key,
	org_id					integer references orgs,
    project_type_name		varchar(50) not null unique,
    details					text
);
CREATE INDEX project_types_org_id ON project_types(org_id);

CREATE TABLE define_phases (
	define_phase_id			serial primary key,
	project_type_id			integer references project_types,
	entity_type_id			integer references entity_types,
	org_id					integer references orgs,
	define_phase_name		varchar(240),
	define_phase_time		real default 0 not null,
	define_phase_cost		real default 0 not null,
	phase_order				integer default 0 not null,
	details					text
);
CREATE INDEX define_phases_project_type_id ON define_phases (project_type_id);
CREATE INDEX define_phases_entity_type_id ON define_phases (entity_type_id);
CREATE INDEX define_phases_org_id ON define_phases(org_id);

CREATE TABLE define_tasks (
    define_task_id			serial primary key,
    define_phase_id			integer references define_phases,
	org_id					integer references orgs,
    define_task_name		varchar(240) not null,
    narrative				varchar(120),
    details					text
);
CREATE INDEX define_tasks_define_phase_id ON define_tasks (define_phase_id);
CREATE INDEX define_tasks_org_id ON define_tasks(org_id);



CREATE VIEW vw_define_phases AS
	SELECT entity_types.entity_type_id, entity_types.entity_type_name, project_types.project_type_id,
		project_types.project_type_name, define_phases.define_phase_id, define_phases.define_phase_name,
		define_phases.org_id, define_phases.define_phase_time, define_phases.define_phase_cost, define_phases.phase_order, 
		define_phases.details
	FROM define_phases INNER JOIN entity_types ON define_phases.entity_type_id = entity_types.entity_type_id
		INNER JOIN project_types ON define_phases.project_type_id = project_types.project_type_id;

CREATE VIEW vw_define_tasks AS
	SELECT vw_define_phases.entity_type_id, vw_define_phases.entity_type_name, vw_define_phases.project_type_id,
    	vw_define_phases.project_type_name, vw_define_phases.define_phase_id, vw_define_phases.define_phase_name,
		vw_define_phases.define_phase_time, vw_define_phases.define_phase_cost,
		define_tasks.org_id, define_tasks.define_task_id, define_tasks.define_task_name, define_tasks.narrative, define_tasks.details
	FROM define_tasks INNER JOIN vw_define_phases ON define_tasks.define_phase_id = vw_define_phases.define_phase_id;
