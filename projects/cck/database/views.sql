
CREATE OR REPLACE VIEW vw_entitys AS
	SELECT orgs.org_id, orgs.org_name, 
    --vw_address.address_id, vw_address.address_name,vw_address.sys_country_id, vw_address.sys_country_name, vw_address.table_name, vw_address.is_default,
		--vw_address.post_office_box, vw_address.postal_code, vw_address.premises, vw_address.street, vw_address.town, vw_address.phone_number, vw_address.extension, vw_address.mobile, vw_address.fax, vw_address.email, vw_address.website,
		entitys.entity_id, entitys.entity_name, entitys.user_name, entitys.Super_User, entitys.Entity_Leader, 
		entitys.Date_Enroled, entitys.Is_Active, entitys.entity_password, entitys.first_password, entitys.Details,
		entity_types.entity_type_id, entity_types.entity_type_name, entitys.primary_email,
		entity_types.entity_role, entity_types.group_email, entity_types.use_key
	FROM entitys 
	--LEFT JOIN vw_address ON entitys.entity_id = vw_address.table_id
	INNER JOIN orgs ON entitys.org_id = orgs.org_id
	LEFT JOIN department ON orgs.org_id = department.org_id
	LEFT JOIN entity_types ON entitys.entity_type_id = entity_types.entity_type_id 
	--WHERE vw_address.table_name = 'entitys' OR vw_address.table_name is null;




CREATE OR REPLACE VIEW vw_entity_subscriptions AS
	SELECT entity_types.entity_type_id, entity_types.entity_type_name, entitys.entity_id, entitys.entity_name, 
		entity_subscriptions.entity_subscription_id, entity_subscriptions.details, 
    subscription_levels.subscription_level_id, subscription_levels.subscription_level_name
	FROM entity_subscriptions 
  INNER JOIN entity_types ON entity_subscriptions.entity_type_id = entity_types.entity_type_id
  INNER JOIN entitys ON entity_subscriptions.entity_id = entitys.entity_id
  INNER JOIN subscription_levels ON entity_subscriptions.subscription_level_id = subscription_levels.subscription_level_id


CREATE OR REPLACE VIEW vw_approvals AS
	SELECT approvals.approval_id, approvals.approve_status,approvals.forward_id, approvals.is_ad_hoc,
	approvals.table_name,approvals.table_id,approvals.escalation_time,approvals.application_date,approvals.completion_date,
	approvals.action_date,approvals.approval_narrative,approvals.to_be_done,approvals.what_is_done,workflow_phases.notice_file,
	workflow_phases.workflow_phase_id, workflow_phases.approval_level, approvals.approval_group,
	workflow_phases.notice_email,workflow_phases.advice_email,workflow_phases.review_email,
	workflow_phases.return_level, workflow_phases.escalation_hours, workflow_phases.notice,
	workflow_phases.required_approvals, workflow_phases.phase_narrative, workflows.workflow_id, workflows.workflow_name,
	entity_types.entity_type_id, entity_types.entity_type_name,
	actual.entity_id as actual_entity_id, actual.entity_name as actual_entity_name, actual.primary_email as actual_entity_email,
	origin.entity_id as origin_entity_id, origin.entity_name as origin_entity_name, origin.primary_email as origin_entity_email,
	appr.entity_id as approving_entity_id, appr.entity_name as approving_entity_name, appr.primary_email as approving_entity_email,
	client.client_id, COALESCE(client.client_name,'SCHEDULE') as client_name, client.id_number, client.pin, client.postal_code, client.email,
    license.license_id, COALESCE(license.license_name,'INSPECTION') as license_name,
	license.license_type_id
	FROM approvals
	INNER JOIN workflow_phases ON approvals.workflow_phase_id = workflow_phases.workflow_phase_id
	INNER JOIN workflows ON workflow_phases.workflow_id = workflows.workflow_id
	LEFT JOIN entitys actual ON approvals.entity_id = actual.entity_id
	INNER JOIN entitys origin ON approvals.org_entity_id = origin.entity_id
	INNER JOIN entitys appr ON approvals.app_entity_id = appr.entity_id
	
	INNER JOIN entity_types ON workflow_phases.approval_entity_id = entity_types.entity_type_id
	--INNER JOIN entity_types ON entity_subscriptions.entity_type_id = entity_types.entity_type_id

	LEFT JOIN client_license ON approvals.table_id = client_license.workflow_table_id
	LEFT JOIN license  ON client_license.license_id = license.license_id	
	LEFT JOIN client ON client_license.client_id = client.client_id;




  CREATE OR REPLACE VIEW vw_workflow_phases AS
	SELECT vw_workflows.source_entity_id, vw_workflows.source_entity_name, vw_workflows.workflow_id, 
		vw_workflows.workflow_name, vw_workflows.table_name, vw_workflows.table_link_field, vw_workflows.table_link_id, 
		vw_workflows.approve_email, vw_workflows.reject_email,
		entity_types.entity_type_id as approval_entity_id, entity_types.entity_type_name as approval_entity_name, 
		workflow_phases.workflow_phase_id, workflow_phases.approval_level, workflow_phases.notice_email,
		workflow_phases.return_level, workflow_phases.escalation_hours, workflow_phases.notice,workflow_phases.notice_file,
		workflow_phases.required_approvals, workflow_phases.phase_narrative, workflow_phases.details,
		payment_type.payment_type_id, payment_type.payment_type_name
	FROM workflow_phases 
  LEFT JOIN vw_workflows ON workflow_phases.workflow_id = vw_workflows.workflow_id
  INNER JOIN entity_types ON workflow_phases.approval_entity_id = entity_types.entity_type_id
  LEFT JOIN payment_type ON workflow_phases.payment_type_id = payment_type.payment_type_id;


CREATE OR REPLACE VIEW vw_sys_emailed AS
	SELECT sys_emailed.sys_emailed_id, sys_emailed.table_id, sys_emailed.table_name, sys_emailed.email_level,sys_emailed.email_type,
		sys_emailed.created, sys_emailed.updated,
		sys_emailed.emailed, sys_emailed.narrative, sys_emails.sys_email_id, sys_emails.sys_email_name, sys_emails.title, sys_emails.details		
	FROM sys_emailed
	INNER JOIN sys_emails ON sys_emails.sys_email_id = sys_emailed.sys_email_id;



CREATE OR REPLACE VIEW vw_license AS
	SELECT 
	license.license_id, license.license_name, license.license_abbrev, 
	license_period, application_fee, initial_fee, annual_fee, agt_fee,
	license_type.license_type_id, license_type.license_type_name,
	department.department_id, department.department_name
	FROM license 
	INNER JOIN license_type ON license.license_type_id = license_type.license_type_id
	INNER JOIN department ON license.department_id = department.department_id;


CREATE OR REPLACE VIEW vw_client AS
	SELECT client.client_id, client.client_name, client.id_number,	client.pin,	client.accounts_code,	client.postal_code,	client.sys_country_id,	client.address,	client.premises,
	client.street,	client.town,	client.fax,	client.email,	client.file_number,	client.country_code,	client.tel_no,	client.mobile_num,	client.building_floor,
	client.lr_number,	client.website,	client.division,	
  (client.client_name || ' <br>P.o. Box: ' || client.address || ' <br>Email: ' || client.email || ' <br>Tel: ' || client.tel_no || ' <br>Mobile: ' || client.mobile_num || ' <br>Website: ' || client.website) as client_detail,
	client_category.client_category_id, client_category.client_category_name, 
	client_industry.client_industry_id, client_industry.client_industry_name,
	status_client.status_client_id, status_client.status_client_name,
	id_type.id_type_id, id_type.id_type_name
	FROM client
	INNER JOIN client_category ON client.client_category_id = client_category.client_category_id
	INNER JOIN client_industry ON client.client_industry_id = client_industry.client_industry_id
	LEFT JOIN status_client ON client.status_client_id = status_client.status_client_id
	INNER JOIN id_type ON client.id_type_id = id_type.id_type_id;



CREATE OR REPLACE VIEW vw_client_license AS
	SELECT client_license.client_license_id,client_license.license_number,client_license.is_rolled_out,client_license.purpose_of_license,client_license.is_network_expansion,client_license.is_freq_expansion,client_license.is_license_reinstatement,client_license.is_exclusive_access,client_license.
    exclusive_bw_MHz,client_license.is_expansion_approved,client_license.skip_clc ,client_license.application_date,client_license.offer_sent_date,client_license. offer_approved,client_license.offer_approved_date,client_license.
    offer_approved_by,client_license.license_date,client_license.license_start_date,client_license.license_stop_date,client_license.rejected_date,client_license.rollout_date,client_license.renewal_date,client_license.commitee_remarks,client_license.
    secretariat_remarks,client_license.remarks,client_license.details, client_license.workflow_table_id,client_license.is_active as is_license_active,
	client_license.is_offer_sent,client_license.tac_approval_date, client_license.certification_date, client_license.is_at_govt_printer,client_license.govt_forwared_date,
	client_license.is_gazetted,client_license.is_gazetted_rejected,client_license.gazettement_date,client_license.gazettement_narrative, client_license.is_workflow_complete,
	client_license.is_compliant,
	client.client_id, client.client_name, client.town, client.id_number, client.pin, client.postal_code, client.email,
    license.license_id, license.license_name, license_type.license_type_id, license_type.license_type_name, 
	COALESCE(clc.clc_id,0) as clc_id, clc_number, clc.clc_date, clc.is_active, clc.doc_url, clc.dms_space_url, clc.minute_number, clc.minute_doc,
	COALESCE(tac.tac_id,0) as tac_id, tac_number, tac.tac_date, tac.minute_number as tac_minute_number,
	COALESCE(board_meeting.board_meeting_id,0) as board_meeting_id, board_meeting.board_meeting_number, board_meeting.board_meeting_date, 
	board_meeting.doc_url as board_paper_url,
	status_license.status_license_id, status_license.status_license_name
	FROM client_license INNER JOIN client ON client_license.client_id = client.client_id
	INNER JOIN license ON client_license.license_id = license.license_id
	LEFT JOIN status_license ON client_license.status_license_id = status_license.status_license_id
	LEFT JOIN license_type ON license.license_type_id = license_type.license_type_id
	LEFT JOIN clc ON client_license.clc_id = clc.clc_id
	LEFT JOIN tac ON client_license.tac_id = tac.tac_id
	LEFT JOIN board_meeting ON client_license.board_meeting_id = board_meeting.board_meeting_id;



CREATE OR REPLACE VIEW vw_approval_checklists AS
	SELECT approval_checklists.approval_checklist_id, approval_checklists.done, approval_checklists.updated,
	upd.entity_id as updater_id, upd.entity_name as updater_name, approval_checklists.workflow_table_id,approval_checklists.checklist_comment,
	checklists.checklist_id, checklists.checklist_number, checklists.requirement, checklists.is_mandatory,
	workflow_phases.workflow_phase_id, workflow_phases.phase_narrative
	FROM approval_checklists
	INNER JOIN checklists ON approval_checklists.checklist_id = checklists.checklist_id
	INNER JOIN workflow_phases ON checklists.workflow_phase_id = workflow_phases.workflow_phase_id
	LEFT JOIN entitys upd ON approval_checklists.updated_by = upd.entity_id;



CREATE OR REPLACE VIEW vw_client_checklist AS 
	SELECT client_checklist.client_checklist_id, client_checklist.checklist_level,client_checklist.is_approved, client_checklist.is_rejected,
	client_phase.client_phase_id, license.license_id, license.license_name,
	license_phase.license_phase_id, license_phase.phase_name,  
	phase_checklist.phase_checklist_id, phase_checklist.requirement
	FROM client_checklist
	INNER JOIN client_phase ON client_checklist.client_phase_id = client_phase.client_phase_id
	INNER JOIN license_phase ON client_phase.license_phase_id = license_phase.license_phase_id
	INNER JOIN license  ON license_phase.license_id = license.license_id
	INNER JOIN client_license ON client_phase.client_license_id = client_license.client_license_id
	INNER JOIN client ON client_license.client_id = client.client_id	
	INNER JOIN phase_checklist ON client_checklist.phase_checklist_id = phase_checklist.phase_checklist_id;



-- CREATE OR REPLACE VIEW vw_license_phase AS
-- 	SELECT license_phase.license_phase_id, license_phase.phase_name, license_phase.phase_level, 
-- 	license_phase.return_level, license_phase.for_payment,license_phase.is_active,
-- 	license.license_id,license.license_name, license.license_abbrev, 
-- 	payment_type.payment_type_id, payment_type.payment_type_name
-- 	FROM license_phase
-- 	INNER JOIN license ON license_phase.license_id = license.license_id
-- 	LEFT JOIN payment_type ON license_phase.payment_type_id = payment_type.payment_type_id
-- 	LEFT JOIN sub_schedule ON license_phase.sub_schedule_id = sub_schedule.sub_schedule_id;
--DROP VIEW vw_license_phase;


CREATE OR REPLACE VIEW vw_client_phase AS
	SELECT client_phase.client_phase_id,client_phase.is_done,client_phase.is_approved,client_phase.is_rejected,client_phase.is_deffered,
	client_phase.is_pending,client_phase.is_withdrawn,client_phase.is_mgr_approved,client_phase.is_ad_approved,client_phase.is_dir_approved,
	client_phase.is_dg_approved,client_phase.narrative,client_phase.is_paid,client_phase.remarks,
	license_phase.license_phase_id, license_phase.phase_name, license_phase.phase_level, 
	license_phase.return_level, license_phase.for_payment,license_phase.is_active, client_license.client_license_id,
	license.license_id, license.license_name,
	client.client_id, client.client_name, client.id_number, client.pin, client.postal_code
	FROM client_phase
	INNER JOIN license_phase ON client_phase.license_phase_id = license_phase.license_phase_id
	INNER JOIN client_license ON client_phase.client_license_id = client_license.client_license_id
	INNER JOIN client ON client_license.client_id = client.client_id
	INNER JOIN license ON client_license.license_id = license.license_id;











/*
CREATE OR REPLACE VIEW vw_distinct_station AS 
	SELECT DISTINCT station.station_id,station.station_name, station_charge.station_class_id, station.client_license_id,vwclient_license.effectiveclient_license_id,station.station_call_sign,
    vwclient_license.license_name,vwclient_license.client_name,station.number_of_frequencies,vwclient_license.is_terrestrial,
	getNumberOfFrequencies(station.station_id) as numberofassignedfrequencies,vwmergedsites.maplink, vhf_network.vhf_network_name,
    (station.number_of_frequencies - getNumberOfFrequencies(station.station_id)) as pendingassignment, vhf_network.vhf_network_id,station.isactive as isactivestation,
    station_charge.station_charge_id, station_charge.typename,round(station.stationcharge,2) as stationcharge,getAssignedFrequencys(station.station_id) as frequencyassignmenthtml,
    decode(cast(stationequipment.carrieroutputpower as int), 5,'PORTABLE', 10, station.vehicleregistration,coalesce(vhf_network.vhf_networklocation,vwmergedsites.location)) as defactolocation,		
	station.extranumber_of_frequencies
	FROM station
  LEFT JOIN stationequipment on station.station_id = stationequipment.station_id			--TESTED FOR COMPLIANCE WITH DECLARATION STUFF
  INNER JOIN vwclient_license on station.client_license_id = vwclient_license.effectiveclient_license_id
  LEFT JOIN vhf_network on station.vhf_network_id = vhf_network.vhf_network_id
  LEFT JOIN vwmergedsites on station.siteid = vwmergedsites.siteid
  LEFT JOIN station_charge on station.station_charge_id = station_charge.station_charge_id;*/


CREATE OR REPLACE VIEW vw_distinct_station AS 
	SELECT DISTINCT station.station_id, station.station_name, station_charge.station_class_id, station.station_call_sign,
    station.number_of_frequencies, station.is_active as isactive_station, station.vehicle_reg_no,
    client_license.client_license_id,
    license.license_id,license.license_name,
    client.client_id,client.client_name,
    
    --vwclient_license.is_terrestrial,vwmergedsites.maplink, 
    --getNumberOfFrequencies(station.station_id) as numberofassignedfrequencies,
    vhf_network.vhf_network_id, vhf_network.vhf_network_name,
    --(station.number_of_frequencies - getNumberOfFrequencies(station.station_id)) as pending_assignment,     
    station_charge.station_charge_id, station_charge.station_charge_name,
    --round(station.station_charge,2) as station_charge
    getAssignedFrequencys(station.station_id) as frequency_assignment_html
    --decode(cast(stationequipment.carrieroutputpower as int), 5,'PORTABLE', 10, coalesce(vhf_network.vhf_networklocation,vwmergedsites.location)) as defactolocation,			
	FROM station
	--LEFT JOIN stationequipment on station.station_id = stationequipment.station_id			--TESTED FOR COMPLIANCE WITH DECLARATION STUFF
	LEFT JOIN vhf_network on station.vhf_network_id = vhf_network.vhf_network_id
	INNER JOIN client_license on vhf_network.client_license_id = client_license.client_license_id  
  INNER JOIN client ON client_license.client_id = client.client_id
  INNER JOIN license ON client_license.license_id = license.license_id
	LEFT JOIN station_charge on station.station_charge_id = station_charge.station_charge_id;
	--LEFT JOIN vwmergedsites on station.siteid = vwmergedsites.siteid
  






--VERY SPECIFIC CLIENTS WITH RESERVED FREQUENCIES
DROP VIEW vw_freq_reserved_client;
CREATE OR REPLACE VIEW vw_freq_reserved AS
  SELECT DISTINCT client_license.client_license_id, client_license.license_number, 
		client_license.workflow_table_id,client_license.is_offer_sent,
		client.client_id, client.client_name,
		license.license_id, license.license_name
	from client_license
	INNER JOIN client ON client_license.client_id = client.client_id
	INNER JOIN license ON client_license.license_id = license.license_id
	WHERE (client_license_id IN (SELECT station.client_license_id FROM station LEFT JOIN frequency_assignment ON station.station_id = frequency_assignment.station_id))
		OR (client_license_id IN (SELECT vhf_network.client_license_id FROM vhf_network INNER JOIN frequency_assignment ON vhf_network.vhf_network_id = frequency_assignment.vhf_network_id))
		OR (client_license_id IN (SELECT terrestrial_link.client_license_id FROM terrestrial_link INNER JOIN frequency_assignment ON terrestrial_link.terrestrial_link_id = frequency_assignment.terrestrial_link_id));




CREATE OR REPLACE VIEW vw_footnote_definition AS
	SELECT footnote_definition.footnote_definition_id, footnote_definition.footnote_definition, to_char(footnote_definition.footnote_description) as footnote_description
	FROM footnote_definition;


CREATE OR REPLACE VIEW vw_channel AS
	SELECT channel.channel_id, channel.sub_band_name, channel.itu_reference as channel_itu, channel.channel_number, channel.transmit, channel.receive, ('Ch:' || channel.channel_number || ' F1:' || channel.transmit ||' F2:'|| channel.receive || 'BW: ' || channel.channel_spacing || 'MHz') as channel_summary,
	channel_plan.channel_plan_id, channel_plan.channel_plan_name, channel_plan.description, channel_plan.itu_reference as channel_plan_itu, getFootNotes(channel.transmit, channel.receive) as footnotes_html
	FROM channel
	INNER join channel_plan on channel.channel_plan_id = channel_plan.channel_plan_id;



CREATE OR REPLACE VIEW vw_channel_footnotes AS
	SELECT footnote_frequency_band.footnote_frequency_band_id, footnote_frequency_band.frequency_band_id, getChannelID(lower_limit,upper_limit, units_of_measure) as calculated_channel_id,
	frequency_band_name, units_of_measure, lower_limit,	upper_limit, footnote_frequency_band.details, footnote_definition.footnote_definition_id, 
	footnote_definition.footnote_definition, to_char(footnote_definition.footnote_description) as footnote_description
	FROM footnote_frequency_band
	INNER JOIN footnote_definition ON footnote_frequency_band.footnote_definition_id = footnote_definition.footnote_definition_id
	INNER JOIN frequency_band ON footnote_frequency_band.frequency_band_id = frequency_band.frequency_band_id;




CREATE OR REPLACE VIEW vw_frequency_band AS
	SELECT frequency_band.frequency_band_id, band_definition.band_definition_id, band_definition.band_definition, frequency_band.frequency_band_name, frequency_band.units_of_measure, 
			frequency_band.lower_limit, frequency_band.upper_limit, frequency_band.service_allocation, to_char(frequency_band.remarks) as remarks, to_char(frequency_band.fsm_remarks) as fsm_remarks,
			(frequency_band.lower_limit || '-' || frequency_band.upper_limit || ' ' || frequency_band.units_of_measure) as summary
	FROM frequency_band
	INNER JOIN band_definition on frequency_band.band_definition_id = band_definition.band_definition_id




CREATE VIEW vw_footnote_frequency_band AS
	SELECT footnote_frequency_band.footnote_frequency_band_id, footnote_frequency_band.frequency_band_id, footnote_frequency_band.details, 
	footnote_definition.footnote_definition_id, footnote_definition.footnote_definition, to_char(footnote_definition.footnote_description) as footnote_description
	FROM footnote_frequency_band
	INNER JOIN footnote_definition ON footnote_frequency_band.footnote_definition_id = footnote_definition.footnote_definition_id;




CREATE OR REPLACE VIEW vw_freq_station AS -
	SELECT DISTINCT station.station_id,station.client_license_id,station.station_call_sign,
    license.license_name,client.client_name,station.number_of_frequencies,license_type.is_terrestrial,
	getNumberOfFrequencies(station_id, 'station') as number_of_assigned_frequencies,
    (station.number_of_frequencies - getNumberOfFrequencies(station.station_id,'station')) as pending_assignment, 
	station.extranumber_of_frequencies
	FROM station
  --INNER JOIN vwclient_license on station.client_license_id = vwclient_license.effectiveclient_license_id;
	INNER JOIN client_license on station.client_license_id = client_license.client_license_id
	INNER JOIN client ON client_license.client_id = client.client_id
	INNER JOIN license ON client_license.license_id = license.license_id
	INNER JOIN license_type ON license.license_type_id = license_type.license_type_id;




create or replace view vw_channel_assignments as
	select frequency_assignment.frequency_assignment_id, client.client_id, client.client_name, frequency_assignment.station_id, frequency_assignment.is_reserved, frequency_assignment.is_active, license.license_name,license.license_id, 
			--coalesce(vhf_network.vhf_network_name,'Default Network') as network_name, coalesce(coalesce(coalesce(vhf_network.vhf_networklocation,station.location),vwmergedsites.location),'UNDEFINED') as stationlocation,
		   channel_plan.channel_plan_id, channel_plan.channel_plan_name, channel.channel_id, channel.channel_number, channel.sub_band_name, channel.itu_reference, channel.channel_spacing, coalesce(channel.duplex_spacing,0) as duplex_spacing, frequency_assignment.tx_frequency, --frequency_assignment.LAST_UPD_TIME,
		   --station.transmitstation_id, 
			station.station_name, station.for_export, station.requested_frequencyGHz, station.number_of_frequencies, station.vessel_name, station.imo_number, station.gross_tonnage, station.aircraft_name, station.aircraft_type, station.aircraft_reg_no, station.path_length_km,
		   station_charge.station_charge_name, channel.transmit, channel.receive, coalesce(channel.units_of_measure,'') as units_of_measure, client_license.client_license_id, --license.is_terrestrial, 
			countBase(station.client_license_id) as fixed, countPortable(station.client_license_id) as portables, countMobile(station.client_license_id) as mobiles
	from frequency_assignment
	inner join channel on frequency_assignment.channel_id = channel.channel_id
	inner join channel_plan on channel.channel_plan_id = channel_plan.channel_plan_id
	left join station on frequency_assignment.station_id = station.station_id
	left join vhf_network on station.vhf_network_id = vhf_network.vhf_network_id
	--left join terrestrial_link on station.vhf_network_id = vhf_network.vhf_network_id
	inner join client_license on station.client_license_id = client_license.client_license_id
	inner join client on client_license.client_id = client.client_id
	inner join license on client_license.license_id = license.license_id
	inner join station_charge on station.station_charge_id = station_charge.station_charge_id
	
	--left join vwmergedsites on station.siteid = vwmergedsites.siteid;





CREATE OR REPLACE VIEW vw_vhf_network AS
	SELECT client_license.client_license_id, vhf_network.vhf_network_id, vhf_network.vhf_network_name, vhf_network.vhf_network_location,
	--vhf_network.created, vhf_network.createdby, vhf_network.updated, vhf_network.updatedby, 
	decode(client_license.is_freq_expansion,'1',vhf_network.extra_number_of_frequencies,0) as extra_number_of_frequencies,
	client.client_name, license.license_name
	--decode(client_license.is_network_expansion,'1','This is a network expansion',decode(client_license.is_freq_expansion,'1',getFreqExpDetails(vhf_network.vhf_network_id),
	--decode(client_license.is_license_reinstatement,'1','License Reinstatement','Normal Application'))) as applicationdescription
	FROM vhf_network
	INNER JOIN client_license ON vhf_network.client_license_id = client_license.client_license_id
	INNER JOIN client ON client_license.client_id = client.client_id	
	INNER JOIN license ON client_license.license_id = license.license_id;



CREATE OR REPLACE VIEW vw_client_station AS
	SELECT 
	client_station.client_station_id,client_station.application_date,client_station.number_of_requested_stations,client_station.number_of_approved_stations,
	client_station.isdummy,	client_station.number_of_frequencies,	client_station.requested_frequency_bands,
	client_station.requested_frequency,	client_station.requested_bandwidth,	client_station.nominal_tx_power,
	client_station.effective_tx_power,	client_station.tentative_price,	client_station.final_price,client_station.location,
	client_license.client_license_id, vhf_network.vhf_network_id, vhf_network.vhf_network_name, vhf_network.vhf_network_location,
	client.client_id, client.client_name,
	license.license_id, license.license_name,
	station_charge.station_charge_id, station_charge.station_charge_name

	FROM client_station	
	INNER JOIN vhf_network ON client_station.vhf_network_id = vhf_network.vhf_network_id
  INNER JOIN client_license ON vhf_network.client_license_id = client_license.client_license_id
	INNER JOIN client ON client_license.client_id = client.client_id
	INNER JOIN license ON client_license.license_id = license.license_id  
	LEFT JOIN station_charge on client_station.station_charge_id = station_charge.station_charge_id;

	

create or replace view vw_maritime_hf as
	select channel.channel_id, channel_plan.channel_plan_id, channel.sub_band_name, channel.itu_reference, 
  channel.transmit as carrier_ship, (channel.transmit+0.0014) as assigned_ship, 
  channel.receive as carrier_coast, (channel.receive+0.0014) as assigned_coast,
	channel.units_of_measure,channel_plan.is_maritime
	from channel
  inner join channel_plan on channel.channel_plan_id = channel_plan.channel_plan_id
  where channel_plan.is_maritime = '1';







CREATE OR REPLACE VIEW vw_network_stations AS
SELECT station.station_id, station.station_name, station.station_call_sign, station.annual_station_charge,
    station_charge.station_charge_id, station_charge.station_charge_name,
    client.client_id, client.client_name, 
    license.license_id, license.license_name,    
    vhf_network.vhf_network_id, vhf_network.vhf_network_name, vhf_network.vhf_network_location,
    station_class.station_class_id, station_class.station_class_name    
	FROM station
  INNER JOIN vhf_network on station.vhf_network_id = vhf_network.vhf_network_id
	INNER JOIN client_license on vhf_network.client_license_id = client_license.client_license_id	
	INNER JOIN client ON client_license.client_id = client.client_id
	INNER JOIN license ON client_license.license_id = license.license_id  	
	LEFT JOIN station_charge on station.station_charge_id = station_charge.station_charge_id
	LEFT JOIN station_class on station_charge.station_class_id = station_class.station_class_id;



CREATE OR REPLACE VIEW vw_channel AS
	SELECT channel.channel_id, channel.sub_band_name, channel.itu_reference as channel_itu, channel.channel_number, channel.transmit, channel.receive, ('Ch:' || channel.channel_number || ' F1:' || channel.transmit ||' F2:'|| channel.receive || 'BW: ' || channel.channel_spacing || 'MHz') as channelsummary,
	channel_plan.channel_plan_id, channel_plan.channel_plan_name, channel_plan.description, channel_plan.itu_reference as channel_plan_itu, getFootNotes(channel.transmit, channel.receive) as footnoteshtml
	FROM channel
	INNER join channel_plan on channel.channel_plan_id = channel_plan.channel_plan_id;



CREATE OR REPLACE VIEW vw_terrestrial_link AS
	SELECT terrestrial_link.terrestrial_link_id, terrestrial_link.terrestrial_link_name, terrestrial_link.requested_frequency_bands,
	terrestrial_link.requested_spot_frequencies, terrestrial_link.requested_frequency,terrestrial_link.requested_frequency_GHz,
	terrestrial_link.requested_bandwidth, terrestrial_link.requested_bandwidth_MHz, terrestrial_link.requested_bandwidth_GHz,
	terrestrial_link.annual_station_charge,	terrestrial_link.prorated_charge,	terrestrial_link.initial_charge_period,	terrestrial_link.capacity_mpbs,	
	terrestrial_link.is_rural, terrestrial_link.for_export, terrestrial_link.is_declared, terrestrial_link.number_of_sectors,
	terrestrial_link.tx_per_sector, terrestrial_link.station_A_name, terrestrial_link.station_B_name, terrestrial_link.num_of_rf_channels,	
	client.client_id,client.client_name, 
	license.license_id, license.license_name, 
	status_station.status_station_id, status_station.status_station_name, getNumberOfFrequencies(terrestrial_link.terrestrial_link_id,'p2p') as num_of_assigned_freq
	FROM terrestrial_link
	INNER JOIN client_license ON terrestrial_link.client_license_id = client_license.client_license_id
	INNER JOIN client ON client_license.client_id = client.client_id
	INNER JOIN license ON client_license.license_id = license.license_id
	LEFT JOIN status_station ON terrestrial_link.status_station_id = status_station.status_station_id;



CREATE OR REPLACE VIEW vw_network_assignments AS
	SELECT frequency_assignment.frequency_assignment_id, frequency_assignment.station_id, frequency_assignment.is_reserved, frequency_assignment.is_active,frequency_assignment.tx_frequency, 
      client.client_id, client.client_name, license.license_name,license.license_id, 			
		 channel_plan.channel_plan_id, channel_plan.channel_plan_name, 
		channel.channel_id, channel.channel_number, channel.transmit, channel.receive, channel.units_of_measure,
		channel.sub_band_name, channel.itu_reference, channel.channel_spacing, coalesce(channel.duplex_spacing,0) as duplex_spacing, 
		vhf_network.vhf_network_id, vhf_network.vhf_network_name, vhf_network.vhf_network_location,
		client_license.client_license_id, client_license.license_number, client_license.workflow_table_id			
	from frequency_assignment
	inner join channel on frequency_assignment.channel_id = channel.channel_id
	inner join channel_plan on channel.channel_plan_id = channel_plan.channel_plan_id
	inner join vhf_network on frequency_assignment.vhf_network_id = vhf_network.vhf_network_id
	left join terrestrial_link on frequency_assignment.terrestrial_link_id = terrestrial_link.terrestrial_link_id
	inner join client_license on vhf_network.client_license_id = client_license.client_license_id
	inner join client on client_license.client_id = client.client_id
	inner join license on client_license.license_id = license.license_id;


CREATE OR REPLACE VIEW vw_license_payment_header AS
SELECT
	license_payment_header.license_payment_header_id,license_payment_header.workflow_phase_id,license_payment_header.is_sales_order_done,
	license_payment_header.order_number, license_payment_header.is_invoice_done, license_payment_header.invoice_date,license_payment_header.invoice_number,
	license_payment_header.invoice_amount,license_payment_header.is_paid,	license_payment_header.is_void,	license_payment_header.receipt_number,
	license_payment_header.receipt_amount,description,license_payment_header.workflow_table_id,license_payment_header.created,
	license_payment_header.updated,license_payment_header.receipt_date,license_payment_header.order_summary,license_payment_header.invoice_summary,
	license_payment_header.receipt_summary, license_payment_header.outstanding_amount, client_license.client_license_id, client_license.license_number, client_license.is_rolled_out, 
	client_license.purpose_of_license,client.client_id, client.client_name, client.id_number, client.pin, client.postal_code, client.email,
	license.license_id, license.license_name, license_type.license_type_id, license_type.license_type_name
FROM license_payment_header
INNER JOIN client_license ON license_payment_header.client_license_id = client_license.client_license_id
INNER JOIN client ON client_license.client_id = client.client_id
INNER JOIN license ON client_license.license_id = license.license_id
LEFT JOIN license_type ON license.license_type_id = license_type.license_type_id;


/*
CREATE OR REPLACE VIEW vw_license_payment_details AS
SELECT
	license_payment_header.license_payment_header_id,license_payment_header.workflow_phase_id,license_payment_header.is_sales_order_done,
	license_payment_header.order_number, license_payment_header.is_invoice_done, license_payment_header.invoice_date,license_payment_header.invoice_number,
	license_payment_header.invoice_amount,license_payment_header.is_paid,	license_payment_header.is_void,	license_payment_header.receipt_number,
	license_payment_header.receipt_amount,description,license_payment_header.workflow_table_id,license_payment_header.created,
	license_payment_header.updated,license_payment_header.receipt_date,license_payment_header.order_summary,license_payment_header.invoice_summary,
  license_payment_header.receipt_summary, license_payment_header.outstanding_amount, client_license.client_license_id, client_license.license_number, client_license.is_rolled_out, 
  client_license.purpose_of_license,client.client_id, client.client_name, client.id_number, client.pin, client.postal_code, client.email,
  license.license_id, license.license_name, license_type.license_type_id, license_type.license_type_name
FROM license_payment_header
INNER JOIN client_license ON license_payment_header.client_license_id = client_license.client_license_id
INNER JOIN client ON client_license.client_id = client.client_id
INNER JOIN license ON client_license.license_id = license.license_id
LEFT JOIN license_type ON license.license_type_id = license_type.license_type_id;*/





CREATE OR REPLACE VIEW vw_equipment_approval AS
	SELECT equipment_approval.equipment_approval_id, equipment_approval.make, equipment_approval.model,
	equipment_approval.manufacturer,equipment_approval.equipment_type_id,
	client_license.client_license_id,client_license.license_number,    
  client_license.secretariat_remarks,client_license.remarks,client_license.details, 
	client_license.workflow_table_id,client_license.is_active as is_license_active,client_license.tac_approval_date, client_license.certification_date,
	client.client_id, client.client_name, client.id_number, client.pin, client.postal_code, client.email,
  license.license_id, license.license_name, 
	tac.tac_id, tac_number, tac.tac_date, tac.minute_number as tac_minute_number
	FROM equipment_approval
	INNER JOIN client_license ON equipment_approval.client_license_id = client_license.client_license_id
	INNER JOIN client ON client_license.client_id = client.client_id
	INNER JOIN license ON client_license.license_id = license.license_id		
	INNER JOIN tac ON client_license.tac_id = tac.tac_id;


CREATE OR REPLACE VIEW vw_equipment AS
	SELECT equipment.equipment_id, equipment.equipment_make, equipment.equipment_model, equipment.output_power,
	equipment.tolerance, equipment.if_bandwidth_3db, equipment.channel_separation, equipment.emmission_designation, 
  equipment.power_to_antenna, equipment_type.equipment_type_id, equipment_type.equipment_type_name
	FROM equipment
	INNER JOIN equipment_type ON equipment.equipment_type_id = equipment_type.equipment_type_id;


CREATE OR REPLACE VIEW vw_mobile_numbering AS 
	SELECT 
		cell_phone_id,cell_phone_range, date_assigned,
		'639' as country_code, DECODE(client.client_id,84,'02',11,'03',26,'05',96,'07',' ') as network_code,
		number_type.number_type_id, upper(number_type.number_type_name) as number_type_name, 
    client.client_id, UPPER(COALESCE(client.client_name,'Unassigned')) AS client_name
	FROM cell_phone
	LEFT JOIN number_type ON cell_phone.number_type_id = number_type.number_type_id
	LEFT JOIN client ON cell_phone.client_id = client.client_id




DROP VIEW vwinstallation;
CREATE OR REPLACE VIEW vw_installation as
	SELECT 
		client_license.client_license_id, client.client_name as contractor_name,
		installation.installation_id, installation.project_contractor, installation.install_date, 
		installation.installation_type, installation.is_approved, installation.is_rejected,		
		installation.client_name, installation.postal_address, installation.physical_address,
		installation.equipment_make, installation.equipment_model,installation.findings,
		installation.checklist_url,
		('P.o. Box: '||installation.postal_address || ' ' || installation.physical_address) as client_address
	FROM installation 
	INNER JOIN client_license ON installation.client_license_id = client_license.client_license_id
	INNER JOIN client ON client_license.client_id = client.client_id
	INNER JOIN license ON client_license.license_id = license.license_id
	INNER JOIN license_type ON license.license_type_id = license_type.license_type_id;

CREATE OR REPLACE VIEW vw_period_license AS
	SELECT period_license.period_license_id, period_license.workflow_table_id,
	period_license.annual_gross, period_license.non_license_revenue,period_license.license_revenue, period_license.annual_fee_due,
	period_license.is_conditions_compliant,	period_license.is_conditions_notice_sent, period_license.conditions_notification_date,
	period_license.is_AAA_compliant,period_license.AAA_notification_letter, period_license.is_AAA_notification_sent,period_license.AAA_notification_date,	
    period_license.is_anual_returns_received, period_license.is_q1_received, period_license.is_q2_received,period_license.is_q3_received, period_license.is_q4_received,
	period_license.is_ret_compliant_so_far,period_license.is_compliant,
	period.period_id, period.period_name,
	client_license.client_license_id,client_license.license_number,    
	client_license.secretariat_remarks,client_license.remarks,client_license.details, 	
	client.client_id, client.client_name, client.id_number, client.pin, client.postal_code, client.email,
	license.license_id, license.license_name,license.agt_fee,license.annual_fee,
	department.department_id, department.department_name, department.org_id,
	status_license.status_license_id, status_license.status_license_name,
	(license.agt_fee * period_license.license_revenue / 100) as agt_revenue
	FROM period_license
	INNER JOIN client_license ON period_license.client_license_id = client_license.client_license_id
	INNER JOIN client ON client_license.client_id = client.client_id
	INNER JOIN license ON client_license.license_id = license.license_id
	INNER JOIN license_type ON license.license_type_id = license_type.license_type_id
	INNER JOIN period ON period_license.period_id = period.period_id
	INNER JOIN department ON license.department_id = department.department_id
	INNER JOIN status_license ON period_license.status_license_id = status_license.status_license_id;

CREATE OR REPLACE VIEW vw_lic_conditions_compliance AS
	SELECT lic_conditions_compliance.lic_conditions_compliance_id, lic_conditions_compliance.is_complied, 
		lic_conditions_compliance.checked_date, lic_conditions_compliance.
		period_license.period_license_id, period.period_id, period.period_name,
		client_license.client_license_id, client_license.license_number,    
		client_license.secretariat_remarks, client_license.remarks, client_license.details, 	
		client.client_id, client.client_name, client.id_number, client.pin, client.postal_code, client.email,
		license.license_id, license.license_name, compliance_condition.compliance_condition_id, compliance_condition.narrative
	FROM lic_conditions_compliance
	INNER JOIN compliance_condition ON lic_conditions_compliance.compliance_condition_id = compliance_condition.compliance_condition_id
	INNER JOIN period_license ON lic_conditions_compliance.period_license_id = period_license.period_license_id
	INNER JOIN client_license ON period_license.client_license_id = client_license.client_license_id
	INNER JOIN client ON client_license.client_id = client.client_id
	INNER JOIN license ON client_license.license_id = license.license_id
	INNER JOIN license_type ON license.license_type_id = license_type.license_type_id
	INNER JOIN period ON period_license.period_id = period.period_id;

	

CREATE OR REPLACE FORCE VIEW vw_qos_compliance AS
  SELECT qos_compliance.qos_compliance_id,
	qos_compliance.qos_region_id,
    qos_compliance.qos_factor_id,
    qos_compliance.actual_client_value,
    qos_compliance.actual_cck_value,
    qos_compliance.is_complied,
    qos_compliance.recommendation,
    qos_factor.qos_factor_name,
    qos_factor.target_operator,
    qos_factor.target_value,
    qos_compliance.period_license_id
  FROM qos_compliance INNER JOIN qos_factor ON qos_compliance.qos_factor_id = qos_factor.qos_factor_id;



CREATE OR REPLACE VIEW vw_sys_audit_trail AS
	SELECT 
		sys_audit_trail.sys_audit_trail_id,	sys_audit_trail.user_id,
		sys_audit_trail.user_ip,
		sys_audit_trail.change_date,
		sys_audit_trail.table_name,
		sys_audit_trail.record_id,
		sys_audit_trail.change_type,
		sys_audit_trail.narrative,
		entitys.entity_id, entitys.entity_name
	FROM sys_audit_trail
	INNER JOIN entitys ON sys_audit_trail.user_id = entitys.entity_id;



CREATE OR REPLACE VIEW vw_station_charge AS
SELECT 
	station_charge.station_charge_id,
	license.license_id, license.license_name,
	station_class.station_class_id,		
	station_charge.amount,
	station_charge.charge_type_id,		
	station_charge.functname,
	station_charge.formula
FROM station_charge
INNER JOIN license ON station_charge.license_id = license.license_id
INNER JOIN station_class ON station_charge.station_class_id = station_class.station_class_id;



CREATE OR REPLACE VIEW vw_aircraft_station AS 
	SELECT station.station_id, station.station_name,
	station.aircraft_name, round(station.annual_station_charge + 0.4) as station_annual_charge, station.aircraft_type, 
    station.aircraft_reg_no, station.station_call_sign, 
	station_charge.station_charge_id, station_charge.station_charge_name,
	client.client_id, client.client_name, client.file_number, 
    client_license.client_license_id, client_license.purpose_of_license,    
    station_class.station_class_id, station_class.station_class_name,
	license.license_id, license.license_name,
  aircraft_band_type.aircraft_band_type_id, aircraft_band_type.aircraft_band_type_name
	FROM station
	LEFT JOIN client_license ON station.client_license_id = client_license.client_license_id 
	INNER JOIN client ON client_license.client_id = client.client_id
	INNER JOIN license ON client_license.license_id = license.license_id  
	INNER JOIN station_charge ON station.station_charge_id = station_charge.station_charge_id
	INNER JOIN aircraft_band_type ON station.aircraft_band_type_id = aircraft_band_type.aircraft_band_type_id
	INNER JOIN station_class on station_charge.station_class_id = station_class.station_class_id
	




CREATE OR REPLACE VIEW vw_band_assignment AS
	SELECT frequency_assignment.frequency_assignment_id,
	station.station_id, station.station_name,
	channel.channel_id, channel.channel_number,
	channel.sub_band_name, channel.sub_band_description,
	channel.sub_band_annex,	channel.itu_reference, channel.channel_spacing, 
	channel.duplex_spacing,	channel.center_frequency, channel.formula,
  channel.transmit, channel.receive, channel.units_of_measure,
	band_assignment.band_assignment_id,
  aircraft_band_type.aircraft_band_type_id, aircraft_band_type.aircraft_band_type_name
	FROM frequency_assignment
	INNER JOIN station ON frequency_assignment.station_id = station.station_id
	INNER JOIN channel ON frequency_assignment.channel_id = channel.channel_id
	INNER JOIN band_assignment ON frequency_assignment.band_assignment_id = band_assignment.band_assignment_id
  INNER JOIN aircraft_band_type ON band_assignment.aircraft_band_type_id = aircraft_band_type.aircraft_band_type_id;



CREATE OR REPLACE VIEW vw_schedule_participant AS
	SELECT 
	schedule_participant.schedule_participant_id,	
	schedule_participant.participant_role,
	schedule_participant.cost_per_diem,
	sub_schedule.sub_schedule_id, sub_schedule.sub_schedule_name,	
	entitys.entity_id, entitys.entity_name
	FROM schedule_participant
	INNER JOIN sub_schedule ON schedule_participant.sub_schedule_id = sub_schedule.sub_schedule_id
	INNER JOIN entitys ON schedule_participant.entity_id = entitys.entity_id;





CREATE OR REPLACE FORCE VIEW vw_client_inspection AS
  SELECT client_inspection.client_inspection_id,
    client_inspection.activity_type_id,
    client_inspection.monitoring_type_id,
    client_inspection.sub_schedule_id,
    client_inspection.inspection_item_id,
    client_inspection.complainant_name,
    client_inspection.complainant_address,
    client_inspection.complainant_fax,
    client_inspection.complainant_telephone,
    client_inspection.complainant_email,
    client_inspection.contact_person,
    client_inspection.request_url,
    client_inspection.report_url,
    client_inspection.application_date,
    client_inspection.document,
    client_inspection.attachment,
    client_inspection.band,
    client_inspection.is_descreet_freq,
    client_inspection.band_from,
    client_inspection.band_to,
    client_inspection.frequency,
    client_inspection.bandwidth,
    client_inspection.type_of_device,
    client_inspection.location,
    client_inspection.suspected_source,
    client_inspection.letter_date,
    client_inspection.interference_timing,
    client_inspection.monitoring_period,
    client_inspection.interference_desc,
    client_inspection.violation,
    client_inspection.findings,
    client_inspection.observations,
    client_inspection.complaint,
    client_inspection.recommendation,
    client_inspection.conclusions,
	client_inspection.purpose_of_inspection,
	client_inspection.is_fully_compliant,
    client.client_id,
    client.client_name,
    client.town
  FROM client_inspection INNER JOIN client ON client_inspection.client_id = client.client_id;





CREATE OR REPLACE VIEW vw_p2p_assignment AS
	SELECT frequency_assignment.frequency_assignment_id, frequency_assignment.is_reserved, frequency_assignment.is_active,
	channel.channel_id, channel.sub_band_name, channel.itu_reference as channel_itu, channel.channel_number, 
	channel.transmit, channel.receive, channel.channel_spacing, channel.duplex_spacing, ('Ch:' || channel.channel_number || ' F1:' || channel.transmit ||' F2:'|| channel.receive || 'BW: ' || channel.channel_spacing || 'MHz') as channel_summary,
	channel_plan.channel_plan_id, channel_plan.channel_plan_name, channel_plan.description, channel_plan.itu_reference as channel_plan_itu, --getFootNotes(channel.transmit, channel.receive) as footnotes_html,
	terrestrial_link.terrestrial_link_id,terrestrial_link.terrestrial_link_name, terrestrial_link.station_A_name, terrestrial_link.station_B_name,
	client_license.client_license_id,
	license.license_id, license.license_name,
	client.client_id, client.client_name, client.id_number, client.pin, client.postal_code
	FROM frequency_assignment
	INNER JOIN channel ON frequency_assignment.channel_id = channel.channel_id
	INNER join channel_plan on channel.channel_plan_id = channel_plan.channel_plan_id
	INNER JOIN terrestrial_link ON frequency_assignment.terrestrial_link_id = terrestrial_link.terrestrial_link_id
  INNER JOIN client_license ON terrestrial_link.client_license_id = client_license.client_license_id
	INNER JOIN client ON client_license.client_id = client.client_id
	INNER JOIN license ON client_license.license_id = license.license_id;




CREATE OR REPLACE FORCE VIEW vw_qos_region AS
  SELECT vw_period_license.period_license_id,
    vw_period_license.period_id,
    vw_period_license.period_name,
    vw_period_license.client_license_id,
    vw_period_license.client_id,
    vw_period_license.client_name,
    vw_period_license.email,
    vw_period_license.license_id,
    vw_period_license.license_name,
    vw_period_license.department_id,
    vw_period_license.department_name,
	vw_period_license.org_id,
	qos_region.qos_region_id,
	qos_region.qos_region_name,
	qos_region.details,
	qos_region.sub_schedule_id
  FROM vw_period_license 
	INNER JOIN qos_region ON vw_period_license.period_license_id = qos_region.period_license_id;
    