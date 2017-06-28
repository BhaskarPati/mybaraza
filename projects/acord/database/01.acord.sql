ALTER TABLE sys_countrys ADD COLUMN org_id	integer references orgs;
UPDATE sys_countrys set org_id =  0;
--- Goals

CREATE TABLE goal_categorys (
	goal_category_id		serial primary key,
	org_id					integer references orgs,
	goal_category_name		varchar(120) not null,
	details					text
);

CREATE TABLE goals (
	goal_id					serial primary key,
	goal_category_id		integer references goal_categorys,
	org_id					integer references orgs,
	goal_name				varchar(150) not null,
	details 				text
);

CREATE TABLE goal_objectives (
	goal_objective_id		serial primary key,
	goal_id					integer references goals,
	org_id					integer references orgs,
	goal_objective_name		varchar(180) not null,
	details					text
);

CREATE TABLE goal_objective_measures (
	goal_objective_measure_id		serial primary key,
	goal_objective_id				integer references goal_objectives,
	org_id							integer references orgs,
	goal_objective_measure_name		varchar(240) not null,
	target_value					real,
	value							real,
	details							text
);

-- Projects

CREATE TABLE project_types (
    project_type_id			serial primary key,
	org_id					integer references orgs,
    project_type_name		varchar(100) not null unique,
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

CREATE TABLE donor_groups (
	donor_group_id			serial primary key,
	org_id					integer references orgs,
	donor_group_name		varchar(50) not null,
	details					text
);
CREATE INDEX donor_groups_org_id ON donor_groups (org_id);

CREATE TABLE donors (
	donor_id				varchar(12) primary key,
	donor_group_id			integer references donor_groups,
	nationality_id			varchar(2)references sys_countrys,
	org_id					integer references orgs,
	donor_name				varchar(50) not null,
	legal_status			varchar (120),
	address					varchar(120),
	telephone				varchar(120),
	fax						varchar(120),
	email					varchar(120),
	skype					varchar(120),
	contact_person			varchar(120),
	contact_person_title	varchar(120),
	physical_address		varchar(120),
	website					varchar(120),
	social_media_links		text,
	details					text
);
CREATE INDEX donors_donor_group_id ON donors (donor_group_id);
CREATE INDEX donors_nationality_id ON donors (nationality_id);
CREATE INDEX donors_org_id ON donors (org_id);


CREATE TABLE targets (
	target_id				serial primary key,
	goal_id 				integer references goals,
	org_id					integer references orgs,
	target_name				varchar(50),
	details					text
);
CREATE INDEX targets_goal_id ON targets (goal_id);
CREATE INDEX targets_org_id ON targets (org_id);

CREATE TABLE projects (
	project_id				varchar(12) primary key,
	project_type_id			integer references project_types,
	org_id					integer references orgs,
	project_name			varchar(240) not null,
	signed					boolean not null default false,
	project_start_date		date,
	project_ending_date		date,
	project_duration		integer,
	project_reference		varchar(50),
	total_budget			real,
	objectives				text,
	target_groups			text,
	final_beneficiaries		text,
	estimated_results		text,
	main_activities			text,
	notes					text,
	introduction			text
);
CREATE INDEX projects_project_type_id ON projects (project_type_id);
CREATE INDEX projects_org_id ON projects (org_id);

CREATE TABLE phases (
	phase_id				serial primary key,
	project_id				varchar(12) references projects,
	org_id					integer references orgs,
	phase_name				varchar(240),
	phase_start_date		date not null,
	phase_end_date			date,
	completed				boolean not null default false,
	phase_cost				real default 0 not null,
	details					text
);
CREATE INDEX phases_project_id ON phases (project_id);
CREATE INDEX phases_org_id ON phases(org_id);


CREATE TABLE activities (
	activity_id				serial primary key,
	phase_id				integer references phases,
	org_id					integer references orgs,
	activity				varchar(50) not null,
	activity_start_date		date,
	activity_close_date		date,
	activity_done			boolean not null default false,
	details                	text
);
CREATE INDEX activities_phase_id ON activities (phase_id);
CREATE INDEX activities_org_id ON activities (org_id);

CREATE TABLE project_locations (
	project_location_id		serial primary key,
	project_id 				varchar(12) references projects,
	sys_country_id			varchar(2)references sys_countrys,
	org_id					integer references orgs,
	region_covered			text,
	details					text
);
CREATE INDEX project_locations_project_id ON project_locations (project_id);
CREATE INDEX project_locations_sys_country_id ON project_locations (sys_country_id);
CREATE INDEX project_locations_org_id ON project_locations (org_id);

CREATE TABLE project_goals (
	project_goal_id 		serial primary key,
	project_id 				varchar references projects,
	goal_id					integer references goals,
	org_id					integer references orgs,
	goal_ps					real,
	details					text
);
CREATE INDEX project_goals_goal_id ON project_goals (goal_id);
CREATE INDEX project_goals_project_id ON project_goals (project_id);
CREATE INDEX project_goals_org_id ON project_goals (org_id);

CREATE TABLE project_targets (
	project_targets_id		serial primary key,
	project_goal_id			integer references project_goals,
	target_id				integer references targets,
	org_id					integer references orgs,
	project_targets_name	varchar(50),
	detscription			text
);
CREATE INDEX project_targets_project_goal_id ON project_targets (project_goal_id);
CREATE INDEX project_targets_target_id ON project_targets (target_id);
CREATE INDEX project_targets_org_id ON project_targets (org_id);

CREATE TABLE contracts (
	contract_id				varchar(12) primary key,
	project_id				varchar(12) references projects,
	donor_id               	varchar(12) references donors,
	currency_id				integer references currency,
	org_id					integer references orgs,
	application_ref			varchar(50),
	core_fund				boolean,
	percentage_levy			real,
	contract_ref			varchar(50),
	decision_date			date,
	contract_date			date,
	start_of_grant			date,
	end_of_grant			date,
	conditions				text,
	notes					text,
	subject					text,
	financing				text,
	reporting				text,
	operation				text,
	general_conditions		text,
	special_conditions		text,
	details					text
);
CREATE INDEX contracts_project_id ON contracts (project_id);
CREATE INDEX contracts_donor_id ON contracts (donor_id);
CREATE INDEX contracts_currency_id ON contracts (currency_id);
CREATE INDEX contracts_org_id ON contracts (org_id);

CREATE TABLE proposal_status (
	proposal_status_id		serial primary key,
	org_id					integer references orgs,
	proposal_status_name	varchar(50) not null,
	details					text
);
CREATE INDEX proposal_status_org_id ON proposal_status (org_id);

CREATE TABLE proposals (
	proposal_id				serial primary key,
	project_id				varchar(12) references projects,
	donor_id				varchar(12) references donors,
	proposal_status_id		integer references proposal_status,
	org_id					integer references orgs,
	start_date				date,
	description				varchar(240),
	location				varchar(240),
	proposal_submit_date	date,
	email					varchar(120),
	approved				boolean,
	dropped					boolean,
	budget					real,
	proposal				text,
	details					text
);
CREATE INDEX proposals_project_id ON proposals (project_id);
CREATE INDEX proposals_donor_id ON proposals (donor_id);
CREATE INDEX proposals_proposal_status_id ON proposals (proposal_status_id);
CREATE INDEX proposals_org_id ON proposals (org_id);

CREATE TABLE grants (
	grant_id				serial primary key,
	contract_id				varchar(12) references contracts,
	org_id					integer references orgs,
	grant_amount			real,
	grant_pr_date			date,
	details					text,
	currency_id 			integer references currency,
	exchange_rate 			real default 1 not null,
	received 				boolean,
	base_amount				real
);
CREATE INDEX grants_contract_id ON grants (contract_id);
CREATE INDEX grants_org_id ON grants (org_id);

CREATE TABLE budget_type (
	budget_type_id			serial primary key,
	org_id					integer references orgs,
	budget_type_name		varchar(60),
	narrative				text
);
CREATE INDEX budget_type_org_id ON budget_type (org_id);

CREATE TABLE budget (
	budget_id				serial primary key,
	project_id				varchar(12) references projects,
	budget_type_id			integer references budget_type,
	currency_id				integer references currency,
	org_id					integer references orgs,
	global_amount         	real,
	field_amount			real not null,
	get_by_date				date,
	spend_by_date			date not null,
   	exchange_rate			real default 1 not null,
	details					text
);
CREATE INDEX budget_project_id ON budget (project_id);
CREATE INDEX budget_budget_type_id ON budget (budget_type_id);
CREATE INDEX budget_currency_id ON budget (currency_id);
CREATE INDEX budget_org_id ON budget (org_id);

CREATE TABLE expenditure (
	expenditure_id     	    serial primary key,
	project_id    		   	varchar(12) references projects,
	currency_id				integer references currency,
	org_id					integer references orgs,
	amount             		real not null,
	exchange_rate			real default 1 not null,
	pr_date					date,
	details            		text
);
CREATE INDEX expenditure_project_id ON expenditure (project_id);
CREATE INDEX expenditure_currency_id ON expenditure (currency_id);
CREATE INDEX expenditure_org_id ON expenditure (org_id);

CREATE TABLE risk_types (
	risk_type_id		serial primary key,
	project_id			varchar references projects,
	org_id				integer references orgs,
	risk_type_name		varchar(80),
	details				text
);

CREATE TABLE risks (
	risk_id				serial primary key,
	risk_type_id		integer references risk_types,
	org_id				integer references orgs,
	risk_name			varchar(180),
	contigency_plans	text
);

----- Theory of change
CREATE TABLE problems (
	problem_id              serial primary key,    
	project_id    		   	varchar references projects,
	org_id					integer references orgs,
	narrative               varchar(320),
	details            		text
);
CREATE INDEX problems_project_id ON problems (project_id);
CREATE INDEX problems_org_id ON problems (org_id);

CREATE TABLE interventions (
	intervention_id         serial primary key,
	problem_id    		   	integer references problems,
	org_id					integer references orgs,
	narrative               varchar(320),

	details            		text    
);
CREATE INDEX interventions_problem_id ON interventions (problem_id);
CREATE INDEX interventions_org_id ON interventions (org_id);

CREATE TABLE outputs (
	output_id               serial primary key,
	intervention_id         integer references interventions,
	org_id					integer references orgs,
	narrative               varchar(320),
	details            		text
);
CREATE INDEX outputs_intervention_id ON outputs (intervention_id);
CREATE INDEX outputs_org_id ON outputs (org_id);

CREATE TABLE final_outcomes (
	final_outcome_id        serial primary key,
	org_id					integer references orgs,
	details            		text,
	problem_id 				integer references problems,
	final_outcome_name 		varchar(320)
	
);
CREATE INDEX final_outcomes_problem_id ON final_outcomes (problem_id);
CREATE INDEX final_outcomes_org_id ON final_outcomes (org_id);

CREATE TABLE objective_finals (
	goal_objective_id		integer references goal_objectives ON UPDATE CASCADE ON DELETE CASCADE,
	final_outcome_id				integer references final_outcomes ON UPDATE CASCADE,
	org_id							integer references orgs,
	percentage_met					real,
	CONSTRAINT objective_final_id PRIMARY KEY (goal_objective_id, final_outcome_id)
);


CREATE TABLE intermediate_outcome (
	intermediate_outcome    serial primary key,
	final_outcome_id        integer references final_outcomes,
	output_id               integer references outputs,
	org_id					integer references orgs,
	narrative               varchar(320),
	details            		text
);
CREATE INDEX intermediate_outcome_final_outcome_id ON intermediate_outcome (final_outcome_id);
CREATE INDEX intermediate_outcome_org_id ON intermediate_outcome (org_id);
CREATE INDEX intermediate_outcome_output_id ON intermediate_outcome (output_id);

CREATE TABLE indicators (
	indicator_id				serial primary key,
	project_id					varchar references projects,
	org_id						integer references orgs,

	key_indictors				varchar(120),
	baseline_values				varchar(320),
	data_source					varchar(320),
	data_collection_method		varchar(320),
	frequency_of_collection		varchar(320),
	impact						varchar(320),
	leassons_learnt				varchar(320),
	action_acquired				varchar(320),
	quality_of_action			varchar(320),
	details						text
 );
CREATE INDEX indicators_project_id ON indicators (project_id);
CREATE INDEX indicators_org_id ON indicators (org_id);

CREATE TABLE intermediate_outcomes(
	intermediate_outcome_id    					serial primary key,
	problem_id									integer references problems,
	org_id										integer references orgs,
	intermediate_outcome_name               	varchar(160),
	details            							text
);

CREATE TABLE final_intermediates (
	final_outcome_id			integer references final_outcomes ON UPDATE CASCADE ON DELETE CASCADE,
	intermediate_outcome_id		integer references intermediate_outcomes ON UPDATE CASCADE,
	org_id						integer references orgs,
	CONSTRAINT final_intermediate_id PRIMARY KEY (final_outcome_id, intermediate_outcome_id)
);

CREATE TABLE strategys (
	strategy_id			serial primary key,
	final_outcome_id	integer references final_outcomes,
	org_id				integer references orgs,
	strategy_name		varchar(250) not null,
	details				text
);

CREATE TABLE strategy_indicators (
	strategy_indicator_id		serial primary key,
	strategy_id					integer references strategys,
	org_id						integer references orgs,
	strategy_indicator_name		varchar(180) not null,
	target_value				real,
	description					text,
	verification_source			text
);

CREATE TABLE intermediate_strategys (
	intermediate_outcome_id			integer references intermediate_outcomes ON UPDATE CASCADE ON DELETE CASCADE,
	strategy_id						integer references strategys ON UPDATE CASCADE,
	org_id							integer references orgs,
	CONSTRAINT intermediate_strategy_id PRIMARY KEY (intermediate_outcome_id, strategy_id)
);


CREATE TABLE results (
	result_id				serial primary key,
	strategy_id				integer references strategys,
	org_id					integer references orgs,
	result_name				varchar(180) not null,
	sector					varchar(120) not null,
	subsectors				varchar(320) not null,
	cost					real,
	beneficiarys_number		real,
	beneficiary_type		varchar(150) not null default 'N/A',
  	special_beneficiarys	varchar(120),
	beneficiarys_comment	text
);




CREATE TABLE result_indicators (
	result_indicator_id		serial primary key,
	result_id				integer references results,
	org_id					integer references orgs,
	result_indicator_name 	varchar(180) not null,
	baseline_value			real,
	target_value			real,
	comment					text,
	sources					text
);

CREATE TABLE activitys (
	activity_id			serial primary key,
	org_id				integer references orgs,
	activity_name		varchar(180) not null,
	details				text,
	strategy_id 		integer references strategys,
	deadline			date,
	completed			boolean default false,
	activity_start_date date,
	activity_end_date 	date
);

CREATE TABLE budgets (
	budget_id				serial primary key,
	strategy_id				integer references strategys,
	org_id					integer references orgs,
	currency_id				integer references currency,
	global_amount         	real,
	field_amount			real not null,
	get_by_date				date,
	spend_by_date			date not null,
   	exchange_rate			real default 1 not null,
	details					text,
	budget_item_name		varchar(120), 
	global_base_amount 		real,
	field_base_amount 		real
);


CREATE TABLE expenditures (
	expenditure_id     	    serial primary key,
	strategy_id				integer references strategys,
	currency_id				integer references currency,
	org_id					integer references orgs,
	amount             		real not null,
	exchange_rate			real default 1 not null,
	pr_date					date,
	details            		text,
	expenditure_name 		varchar(120),
	base_amount 			real
);

CREATE TABLE final_outcome_indicators (
	final_outcome_indicator_id		serial primary key,
	final_outcome_id				integer references final_outcomes,
	org_id							integer references orgs,
	final_outcome_indicator_name	varchar(160) not null,
	target_value 					real,
	details							text,
	sources							text
);

CREATE TABLE problem_indicators (
	problem_indicator_id	serial primary key,
	problem_id				integer references problems,
	org_id					integer references orgs,
	problem_indicator_name	varchar(160) not null,
	target_value			real,
	details					text,
	sources					text
);

CREATE TABLE assumptions (
	assumption_id		serial primary key,
	final_outcome_id		integer references final_outcomes,
	org_id				integer references orgs,
	assumption_name		varchar(180) not null,
	details				text
);

CREATE TABLE phase_activitys (
	phase_id		integer references phases ON UPDATE CASCADE ON DELETE CASCADE,
	activity_id		integer references activitys ON UPDATE CASCADE,
	org_id			integer references orgs,
	CONSTRAINT phase_activity_id PRIMARY KEY (phase_id, activity_id)
);

CREATE TABLE proposal_followup (
	proposal_followup_id		serial primary key,
	org_id				integer references orgs,
	proposal_id 			integer references proposals,
	activity				varchar(120) not null,
	date				date,
	details				text
);

CREATE TABLE tasks (
	task_id					serial primary key,
	activity_id				integer references activitys,
	phase_id				integer references phases,
	entity_id				integer references entitys,
	org_id					integer references orgs,
	task_name				varchar(320) not null,
	task_start_date			date not null,
	task_dead_line			date,
	task_end_date			date,
	hours_taken				integer default 7 not null,
	task_done				boolean not null default false,
	details					text
);

CREATE INDEX tasks_activity_id ON tasks (activity_id);
CREATE INDEX tasks_phase_id ON tasks (phase_id);
CREATE INDEX tasks_entity_id ON tasks (entity_id);
CREATE INDEX tasks_org_id ON tasks (org_id);





