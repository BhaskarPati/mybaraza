CREATE VIEW vw_goal_categorys AS
	SELECT orgs.org_id, orgs.org_name, goal_categorys.goal_category_id,
		goal_categorys.goal_category_name, goal_categorys.details
	FROM goal_categorys INNER JOIN orgs ON goal_categorys.org_id = orgs.org_id;

CREATE VIEW vw_goals AS
	SELECT orgs.org_id, orgs.org_name, goal_categorys.goal_category_id,
		goal_categorys.goal_category_name, goals.goal_id, goals.goal_name, goals.details
	FROM goals INNER JOIN orgs ON goals.org_id = orgs.org_id
		INNER JOIN goal_categorys ON goals.goal_category_id = goal_categorys.goal_category_id;


CREATE VIEW vw_goal_objectives AS
	SELECT orgs.org_id, orgs.org_name, goals.goal_id, goals.goal_name,
		goal_objectives.goal_objective_id, goal_objectives.goal_objective_name,
		goal_objectives.details
	FROM goal_objectives INNER JOIN orgs ON goal_objectives.org_id = orgs.org_id
		INNER JOIN goals ON goal_objectives.goal_id = goals.goal_id;



CREATE VIEW vw_goal_objective_measures AS
	SELECT orgs.org_id, orgs.org_name, goal_objectives.goal_objective_id, goal_objectives.goal_objective_name,
		goal_objective_measures.goal_objective_measure_id, goal_objective_measures.goal_objective_measure_name, 
		goal_objective_measures.target_value, 	goal_objective_measures.value, goal_objective_measures.details
	FROM goal_objective_measures INNER JOIN orgs ON goal_objective_measures.org_id = orgs.org_id
		INNER JOIN goal_objectives ON goal_objective_measures.goal_objective_id = goal_objectives.goal_objective_id;

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

CREATE VIEW vw_projects AS
	SELECT project_types.project_type_id, project_types.project_type_name, 
		projects.org_id, projects.project_id, projects.project_name, projects.signed, 
		projects.project_start_date, projects.project_ending_date, projects.project_duration, 
		projects.project_reference, projects.total_budget, projects.objectives, projects.target_groups, 
		projects.final_beneficiaries, projects.estimated_results, projects.main_activities, projects.notes
	FROM projects INNER JOIN project_types ON projects.project_type_id = project_types.project_type_id;
	
CREATE VIEW vw_phases AS
	SELECT vw_projects.project_type_id, vw_projects.project_type_name, 
		vw_projects.project_id, vw_projects.project_name, vw_projects.signed, 
		vw_projects.project_start_date, vw_projects.project_ending_date, vw_projects.project_duration, 
		vw_projects.project_reference, vw_projects.total_budget,
		orgs.org_id, orgs.org_name, phases.phase_id, phases.phase_name, phases.phase_start_date, phases.phase_end_date, 
		phases.completed as phase_completed, phases.phase_cost, phases.details
	FROM phases INNER JOIN vw_projects ON phases.project_id = vw_projects.project_id
				INNER JOIN orgs ON phases.org_id = orgs.org_id;



CREATE VIEW vw_tasks AS
	SELECT activitys.activity_id, activitys.activity_name, entitys.entity_id, entitys.entity_name, orgs.org_id, orgs.org_name, phases.phase_id,
		phases.phase_name, tasks.task_id, tasks.task_name, tasks.task_start_date, tasks.task_dead_line, tasks.task_end_date, tasks.hours_taken,
		tasks.task_done, tasks.details
	FROM tasks INNER JOIN activitys ON tasks.activity_id = activitys.activity_id
		INNER JOIN entitys ON tasks.entity_id = entitys.entity_id
		INNER JOIN orgs ON tasks.org_id = orgs.org_id
		INNER JOIN phases ON tasks.phase_id = phases.phase_id;
		
CREATE VIEW vw_activities AS
	SELECT vw_phases.project_type_id, vw_phases.project_type_name, 
		vw_phases.project_id, vw_phases.project_name, vw_phases.signed, 
		vw_phases.project_start_date, vw_phases.project_ending_date, vw_phases.project_duration, 
		vw_phases.project_reference, vw_phases.total_budget,
		vw_phases.phase_id, vw_phases.phase_name, vw_phases.phase_start_date, vw_phases.phase_end_date, 
		vw_phases.phase_completed,  vw_phases.phase_cost, 
		activities.org_id, activities.activity_id, activities.activity, activities.activity_start_date, 
		activities.activity_close_date, activities.activity_done, activities.details
	FROM activities INNER JOIN vw_phases ON activities.phase_id = vw_phases.phase_id;
	
CREATE VIEW vw_donors AS
	SELECT donor_groups.donor_group_id, donor_groups.donor_group_name, 
		sys_countrys.sys_country_id, sys_countrys.sys_country_name, 
		donors.org_id, donors.donor_id, donors.donor_name, donors.legal_status, 
		donors.address, donors.telephone, donors.fax, donors.email, donors.skype, 
		donors.contact_person, donors.contact_person_title, donors.physical_address, 
		donors.website, donors.social_media_links, donors.details
	FROM donors INNER JOIN donor_groups ON donors.donor_group_id = donor_groups.donor_group_id
		INNER JOIN sys_countrys ON donors.nationality_id = sys_countrys.sys_country_id;

CREATE VIEW vw_targets AS
	SELECT goals.goal_id, goals.goal_name, 
		targets.org_id, targets.target_id, targets.target_name, targets.details
	FROM targets INNER JOIN goals ON targets.goal_id = goals.goal_id;
	
CREATE OR REPLACE VIEW vw_project_locations AS
	SELECT projects.project_id, projects.project_name, 
		sys_countrys.sys_country_id, sys_countrys.sys_country_name, 
		project_locations.project_location_id, project_locations.region_covered, 
		project_locations.details, orgs.org_id, orgs.org_name
	FROM project_locations INNER JOIN projects ON project_locations.project_id = projects.project_id
		INNER JOIN sys_countrys ON project_locations.sys_country_id = sys_countrys.sys_country_id
		INNER JOIN orgs ON project_locations.org_id = orgs.org_id;
		
CREATE VIEW vw_project_goals AS
	SELECT goals.goal_id, goals.goal_name, 
		projects.project_id, projects.project_name, 
		project_goals.org_id, project_goals.project_goal_id, project_goals.goal_ps, project_goals.details
	FROM project_goals INNER JOIN goals ON project_goals.goal_id = goals.goal_id
		INNER JOIN projects ON project_goals.project_id = projects.project_id;

CREATE VIEW vw_goal_targets AS
	SELECT vw_targets.goal_id, vw_targets.goal_name, 
		vw_targets.target_id, vw_targets.target_name, 
		project_goals.org_id, project_goals.project_goal_id, project_goals.goal_ps,
		project_goals.project_id
	FROM project_goals INNER JOIN vw_targets ON project_goals.goal_id = vw_targets.goal_id;
		
CREATE VIEW vw_project_targets AS
	SELECT vw_project_goals.goal_id, vw_project_goals.goal_name, 
		vw_project_goals.project_id, vw_project_goals.project_name,
		vw_project_goals.project_goal_id, vw_project_goals.goal_ps,
		targets.target_id, targets.target_name, 
		
		project_targets.org_id, project_targets.project_targets_id, project_targets.project_targets_name, 
		project_targets.detscription
	FROM project_targets INNER JOIN vw_project_goals ON project_targets.project_goal_id = vw_project_goals.project_goal_id
		INNER JOIN targets ON project_targets.target_id = targets.target_id;
		
CREATE OR REPLACE VIEW vw_contracts AS
	SELECT projects.project_id, projects.project_name,
		donors.donor_id, donors.donor_name,
		currency.currency_id, currency.currency_name, 
		contracts.contract_id, contracts.application_ref, contracts.core_fund, 
		contracts.percentage_levy, contracts.contract_ref, contracts.decision_date, contracts.contract_date, 
		contracts.start_of_grant, contracts.end_of_grant, contracts.conditions, contracts.notes, contracts.subject, 
		contracts.financing, contracts.reporting, contracts.operation, contracts.general_conditions, 
		contracts.special_conditions, contracts.details, orgs.org_id, orgs.org_name
	FROM contracts INNER JOIN projects ON contracts.project_id = projects.project_id
		INNER JOIN donors ON contracts.donor_id = donors.donor_id
		INNER JOIN currency ON contracts.currency_id = currency.currency_id
		INNER JOIN orgs ON contracts.org_id = orgs.org_id;
		

CREATE OR REPLACE VIEW vw_proposals AS
	SELECT projects.project_id, projects.project_name,
		donors.donor_id, donors.donor_name,
		proposal_status.proposal_status_id, proposal_status.proposal_status_name, 
		orgs.org_id, orgs.org_name, proposals.proposal_id, proposals.start_date, proposals.description, 
		proposals.location, proposals.proposal_submit_date, proposals.email, proposals.approved, 
		proposals.dropped, proposals.budget, proposals.proposal, proposals.details
	FROM proposals INNER JOIN projects ON proposals.project_id = projects.project_id
		INNER JOIN donors ON proposals.donor_id = donors.donor_id
		INNER JOIN orgs ON proposals.org_id = orgs.org_id
		INNER JOIN proposal_status ON proposals.proposal_status_id = proposal_status.proposal_status_id;
	
CREATE VIEW vw_grants AS
	SELECT contracts.contract_id, currency.currency_id, currency.currency_name, currency.currency_symbol, orgs.org_id, orgs.org_name, grants.grant_id,
		grants.grant_amount, grants.grant_pr_date, grants.details, grants.exchange_rate, grants.received, (grants.exchange_rate*grants.grant_amount) 
		as base_amount
	FROM grants INNER JOIN contracts ON grants.contract_id = contracts.contract_id
		INNER JOIN currency ON grants.currency_id = currency.currency_id
		INNER JOIN orgs ON grants.org_id = orgs.org_id;

CREATE VIEW vw_budget AS
	SELECT projects.project_id, projects.project_name,
		budget_type.budget_type_id, budget_type.budget_type_name, 
		currency.currency_id, currency.currency_name, 
		budget.org_id, budget.budget_id, budget.global_amount, budget.field_amount, budget.exchange_rate,
		budget.get_by_date, budget.spend_by_date, budget.details,
		(budget.global_amount * budget.exchange_rate) as base_global_amount,
		(budget.field_amount * budget.exchange_rate) as base_field_amount
	FROM budget INNER JOIN projects ON budget.project_id = projects.project_id
		INNER JOIN budget_type ON budget.budget_type_id = budget_type.budget_type_id
		INNER JOIN currency ON budget.currency_id = currency.currency_id;
		
CREATE VIEW vw_expenditure AS
	SELECT projects.project_id, projects.project_name,
		currency.currency_id, currency.currency_name, 
		expenditure.org_id, expenditure.expenditure_id, 
		expenditure.amount, expenditure.exchange_rate, expenditure.pr_date, expenditure.details,
		(expenditure.amount * expenditure.exchange_rate) as base_amount
	FROM expenditure INNER JOIN projects ON expenditure.project_id = projects.project_id
		INNER JOIN currency ON expenditure.currency_id = currency.currency_id;

CREATE VIEW vw_risk_types AS
	SELECT projects.project_id, projects.project_name, risk_types.risk_type_id, risk_types.org_id, 
		risk_types.risk_type_name, risk_types.details
	FROM risk_types INNER JOIN projects ON risk_types.project_id = projects.project_id;

CREATE VIEW vw_risks AS
	SELECT risk_types.risk_type_id, risk_types.risk_type_name, risks.risk_id, risks.org_id, 
		risks.risk_name, risks.contigency_plans
	FROM risks INNER JOIN risk_types ON risks.risk_type_id = risk_types.risk_type_id;
		
---TOC
CREATE VIEW vw_problems AS
	SELECT projects.project_id, projects.project_name, 
		problems.org_id, problems.problem_id, problems.narrative, problems.details
	FROM problems INNER JOIN projects ON problems.project_id = projects.project_id;

CREATE VIEW vw_interventions AS
	SELECT vw_problems .project_id, vw_problems.project_name,
		vw_problems.problem_id, vw_problems.narrative as problem_narrative, vw_problems.details as problem_details, 
		interventions.org_id, interventions.intervention_id, interventions.narrative, interventions.details
	FROM interventions INNER JOIN vw_problems ON interventions.problem_id = vw_problems.problem_id;

CREATE VIEW vw_outputs AS
	SELECT vw_interventions .project_id, vw_interventions.project_name,
		vw_interventions.problem_id, vw_interventions.problem_narrative, vw_interventions.problem_details, 
		vw_interventions.org_id, vw_interventions.intervention_id, vw_interventions.narrative as interventions_narrative, vw_interventions.details as interventions_details,
		outputs.output_id, outputs.narrative, outputs.details
	FROM outputs INNER JOIN vw_interventions ON outputs.intervention_id = vw_interventions.intervention_id;

CREATE OR REPLACE VIEW vw_final_outcomes AS
	SELECT orgs.org_id, orgs.org_name, problems.problem_id, problems.narrative, final_outcomes.final_outcome_id, final_outcomes.final_outcome_name,
		final_outcomes.details
	FROM final_outcomes INNER JOIN orgs ON final_outcomes.org_id = orgs.org_id
		INNER JOIN problems ON final_outcomes.problem_id = problems.problem_id;

CREATE VIEW vw_intermediate_outcome AS
		SELECT vw_final_outcomes.problem_id,vw_final_outcomes.org_id,
			vw_final_outcomes.final_outcome_id,
			vw_final_outcomes.narrative as final_outcome_narrative, vw_final_outcomes.details as 				final_outcome_details
			,intermediate_outcome.intermediate_outcome, intermediate_outcome.narrative,
			intermediate_outcome.details
		FROM intermediate_outcome INNER JOIN vw_final_outcomes ON
			intermediate_outcome.final_outcome_id = vw_final_outcomes.final_outcome_id;

CREATE VIEW vw_indicators AS
	SELECT projects.project_id, projects.project_name, 
		indicators.org_id, indicators.indicator_id, indicators.key_indictors, indicators.baseline_values, 
		indicators.data_source, indicators.data_collection_method, indicators.frequency_of_collection, 
		indicators.impact, indicators.leassons_learnt, indicators.action_acquired, indicators.quality_of_action, 
		indicators.details
	FROM indicators	INNER JOIN projects ON indicators.project_id = projects.project_id;



CREATE VIEW vw_project_types AS
	SELECT orgs.org_id, orgs.org_name, project_types.project_type_id, project_types.project_type_name, project_types.details
	FROM project_types INNER JOIN orgs ON project_types.org_id = orgs.org_id;


CREATE VIEW vw_proposal_status AS
	SELECT orgs.org_id, orgs.org_name, proposal_status.proposal_status_id, proposal_status.proposal_status_name, proposal_status.details
	FROM proposal_status INNER JOIN orgs ON proposal_status.org_id = orgs.org_id;

CREATE OR REPLACE VIEW vw_intermediate_outcomes AS
	SELECT orgs.org_id, orgs.org_name, problems.problem_id, problems.narrative, intermediate_outcomes.intermediate_outcome_id,
		intermediate_outcomes.intermediate_outcome_name, intermediate_outcomes.details
	FROM intermediate_outcomes INNER JOIN orgs ON intermediate_outcomes.org_id = orgs.org_id
		INNER JOIN problems ON intermediate_outcomes.problem_id = problems.problem_id;

CREATE OR REPLACE VIEW vw_final_intermediates AS
	SELECT final_outcomes.final_outcome_id, final_outcomes.final_outcome_name, intermediate_outcomes.intermediate_outcome_id,
		intermediate_outcomes.intermediate_outcome_name, orgs.org_id, orgs.org_name
	FROM final_intermediates INNER JOIN final_outcomes ON final_intermediates.final_outcome_id = final_outcomes.final_outcome_id
		INNER JOIN intermediate_outcomes ON final_intermediates.intermediate_outcome_id = intermediate_outcomes.intermediate_outcome_id
		INNER JOIN orgs ON final_intermediates.org_id = orgs.org_id;	

CREATE OR REPLACE VIEW vw_strategys AS
	SELECT final_outcomes.final_outcome_id, final_outcomes.final_outcome_name, orgs.org_id, orgs.org_name, strategys.strategy_id, 
		strategys.strategy_name, strategys.details
	FROM strategys INNER JOIN final_outcomes ON strategys.final_outcome_id = final_outcomes.final_outcome_id
		INNER JOIN orgs ON strategys.org_id = orgs.org_id;


CREATE OR REPLACE VIEW vw_strategy_indicators AS
	SELECT orgs.org_id, orgs.org_name, strategys.strategy_id, strategys.strategy_name, strategy_indicators.strategy_indicator_id,
		strategy_indicators.strategy_indicator_name, strategy_indicators.target_value, strategy_indicators.description,
		strategy_indicators.verification_source
	FROM strategy_indicators INNER JOIN orgs ON strategy_indicators.org_id = orgs.org_id
		INNER JOIN strategys ON strategy_indicators.strategy_id = strategys.strategy_id;

CREATE OR REPLACE VIEW vw_intermediate_strategys AS
	SELECT intermediate_outcomes.intermediate_outcome_id, intermediate_outcomes.intermediate_outcome_name, strategys.strategy_id,
		strategys.strategy_name, orgs.org_id, orgs.org_name
	FROM intermediate_strategys INNER JOIN intermediate_outcomes ON intermediate_strategys.intermediate_outcome_id =
		intermediate_outcomes.intermediate_outcome_id
		INNER JOIN strategys ON intermediate_strategys.strategy_id = strategys.strategy_id
		INNER JOIN orgs ON intermediate_strategys.org_id = orgs.org_id;


CREATE OR REPLACE VIEW vw_results AS
	SELECT orgs.org_id, orgs.org_name, strategys.strategy_id, strategys.strategy_name, results.result_id, results.result_name, results.sector,
		results.subsectors, results.cost, results.beneficiarys_number, results.beneficiary_type, results.special_beneficiarys,
		results.beneficiarys_comment
	FROM results INNER JOIN orgs ON results.org_id = orgs.org_id
		INNER JOIN strategys ON results.strategy_id = strategys.strategy_id;


CREATE OR REPLACE VIEW vw_result_indicators AS
	SELECT orgs.org_id, orgs.org_name, results.result_id, results.result_name, result_indicators.result_indicator_id,
		result_indicators.result_indicator_name, result_indicators.baseline_value, result_indicators.target_value, result_indicators.comment, 			result_indicators.sources
	FROM result_indicators INNER JOIN orgs ON result_indicators.org_id = orgs.org_id
		INNER JOIN results ON result_indicators.result_id = results.result_id;

CREATE OR REPLACE VIEW vw_activitys AS
	SELECT orgs.org_id, orgs.org_name, strategys.strategy_id, strategys.strategy_name, activitys.activity_id, activitys.activity_name,
		activitys.details, activitys.deadline
	FROM activitys INNER JOIN orgs ON activitys.org_id = orgs.org_id
		INNER JOIN strategys ON activitys.strategy_id = strategys.strategy_id;


CREATE VIEW vw_budgets AS
	SELECT currency.currency_id, currency.currency_symbol, orgs.org_id, orgs.org_name, strategys.strategy_id, strategys.strategy_name,
		budgets.budget_id, budgets.global_amount, budgets.field_amount, budgets.get_by_date, budgets.spend_by_date, budgets.exchange_rate,
		budgets.details, budgets.budget_item_name, (budgets.global_amount*budgets.exchange_rate) as global_base_amount,
		(budgets.field_amount*budgets.exchange_rate) as field_base_amount
	FROM budgets INNER JOIN currency ON budgets.currency_id = currency.currency_id
		INNER JOIN orgs ON budgets.org_id = orgs.org_id
		INNER JOIN strategys ON budgets.strategy_id = strategys.strategy_id;


CREATE VIEW vw_expenditures AS
	SELECT currency.currency_id, currency.currency_symbol, orgs.org_id, orgs.org_name, strategys.strategy_id, strategys.strategy_name,
		expenditures.expenditure_id, expenditures.amount, expenditures.exchange_rate, expenditures.pr_date, expenditures.details,
		expenditures.expenditure_name, (expenditures.exchange_rate*expenditures.amount) as base_amount
	FROM expenditures INNER JOIN currency ON expenditures.currency_id = currency.currency_id
		INNER JOIN orgs ON expenditures.org_id = orgs.org_id
		INNER JOIN strategys ON expenditures.strategy_id = strategys.strategy_id;


CREATE VIEW vw_final_outcome_indicators AS
	SELECT final_outcomes.final_outcome_id, final_outcomes.final_outcome_name, orgs.org_id, orgs.org_name,
		final_outcome_indicators.final_outcome_indicator_id, final_outcome_indicators.final_outcome_indicator_name,
		final_outcome_indicators.target_value, final_outcome_indicators.details
	FROM final_outcome_indicators INNER JOIN final_outcomes ON final_outcome_indicators.final_outcome_id = final_outcomes.final_outcome_id
		INNER JOIN orgs ON final_outcome_indicators.org_id = orgs.org_id;

CREATE OR REPLACE VIEW vw_problem_indicators AS
	SELECT orgs.org_id, orgs.org_name, problems.problem_id, problems.narrative, problem_indicators.problem_indicator_id,
		problem_indicators.problem_indicator_name, problem_indicators.target_value, problem_indicators.details, problem_indicators.sources
	FROM problem_indicators INNER JOIN orgs ON problem_indicators.org_id = orgs.org_id
		INNER JOIN problems ON problem_indicators.problem_id = problems.problem_id;

CREATE VIEW vw_assumptions AS
	SELECT final_outcomes.final_outcome_id, final_outcomes.final_outcome_name, orgs.org_id, orgs.org_name, assumptions.assumption_id,
		assumptions.assumption_name, assumptions.details
	FROM assumptions INNER JOIN final_outcomes ON assumptions.final_outcome_id = final_outcomes.final_outcome_id
		INNER JOIN orgs ON assumptions.org_id = orgs.org_id;


CREATE VIEW vw_phase_activitys AS
	SELECT activitys.activity_id, activitys.activity_name, orgs.org_id, orgs.org_name, phases.phase_id, phases.phase_name
	FROM phase_activitys INNER JOIN activitys ON phase_activitys.activity_id = activitys.activity_id
		INNER JOIN orgs ON phase_activitys.org_id = orgs.org_id
		INNER JOIN phases ON phase_activitys.phase_id = phases.phase_id;


CREATE VIEW vw_proposal_followup AS
	SELECT orgs.org_id, orgs.org_name, proposals.proposal_id, proposal_followup.proposal_followup_id, proposal_followup.activity,
		proposal_followup.date, proposal_followup.details
	FROM proposal_followup INNER JOIN orgs ON proposal_followup.org_id = orgs.org_id
		INNER JOIN proposals ON proposal_followup.proposal_id = proposals.proposal_id;

CREATE OR REPLACE VIEW vw_objective_finals AS
	SELECT final_outcomes.final_outcome_id, final_outcomes.final_outcome_name, orgs.org_id, orgs.org_name, goal_objectives.goal_objective_id,
		goal_objectives.goal_objective_name, objective_finals.percentage_met
	FROM objective_finals INNER JOIN final_outcomes ON objective_finals.final_outcome_id = final_outcomes.final_outcome_id
		INNER JOIN orgs ON objective_finals.org_id = orgs.org_id
		INNER JOIN goal_objectives ON objective_finals.goal_objective_id = goal_objectives.goal_objective_id;

CREATE VIEW vw_budget_total AS 
SELECT vw_strategys.strategy_id, vw_strategys.strategy_name, sum(vw_budgets.global_base_amount) as budget_total
FROM  vw_budgets RIGHT OUTER JOIN vw_strategys ON vw_strategys.strategy_id = vw_budgets.strategy_id
	GROUP BY vw_strategys.strategy_id, vw_strategys.strategy_name;

CREATE VIEW vw_expenditures_total AS 
SELECT vw_strategys.strategy_id, vw_strategys.strategy_name, sum(vw_expenditures.base_amount) as expenditure_total
FROM  vw_expenditures RIGHT OUTER JOIN vw_strategys ON vw_strategys.strategy_id = vw_expenditures.strategy_id
	GROUP BY vw_strategys.strategy_id, vw_strategys.strategy_name;
