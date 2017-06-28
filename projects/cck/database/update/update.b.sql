ALTER TABLE EQUIPMENT_APPROVAL ADD REPORT_URL VARCHAR2(256) GENERATED ALWAYS AS ('<a href=' || EVAL_REPORT_URL || ' _blank=yes>Report</a>') VIRTUAL VISIBLE;
ALTER TABLE EQUIPMENT_APPROVAL ADD is_provisional CHAR(1) DEFAULT '0';
ALTER TABLE EQUIPMENT_APPROVAL ADD provisional_date DATE;	

CREATE OR REPLACE FORCE VIEW vw_equipment_approval AS
  SELECT equipment_approval.equipment_approval_id,
    equipment_approval.make,
    equipment_approval.model,
    equipment_approval.manufacturer,
    equipment_approval.equipment_type_id,
    equipment_approval.is_provisional,
    equipment_approval.provisional_date,
    (equipment_approval.provisional_date + 180) as license_by,
    equipment_approval.is_ta_approved,
    client_license.client_license_id,
    client_license.license_number,
    client_license.secretariat_remarks,
    client_license.remarks,
    client_license.details,
    client_license.workflow_table_id,
    client_license.is_active AS is_license_active,
    client_license.tac_approval_date,
    client_license.certification_date,
	client_license.application_date,
    client.client_id,
    client.client_name,
    client.id_number,
    client.pin,
    client.postal_code,
    client.email,
    license.license_id,
    license.license_name,
    license.license_type_id,
    clc.clc_id,
    clc.clc_number,
    clc.clc_date
  FROM equipment_approval INNER JOIN client_license ON equipment_approval.client_license_id = client_license.client_license_id
	INNER JOIN client ON client_license.client_id = client.client_id
	INNER JOIN license ON client_license.license_id = license.license_id
	INNER JOIN clc ON client_license.clc_id = clc.clc_id;


CREATE OR REPLACE FUNCTION ta_provisional(keyfield IN varchar2, user_id IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN varchar2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
    tab_id    integer;
BEGIN	
  
	UPDATE equipment_approval SET is_provisional = '1', provisional_date = SYSDATE
	WHERE equipment_approval_id = CAST(keyfield AS int);
	COMMIT;

	RETURN 'Provional letter generated';
END;
/ 


CREATE OR REPLACE FUNCTION ta_approved(keyfield IN varchar2, user_id IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN varchar2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
    tab_id    integer;
BEGIN	
  
	UPDATE equipment_approval SET is_ta_approved = '1'
	WHERE equipment_approval_id = CAST(keyfield AS int);
	COMMIT;

	UPDATE client_license SET certification_date = SYSDATE, is_active = '1'
	WHERE client_license_id 
		IN (SELECT client_license_id FROM equipment_approval WHERE equipment_approval_id = CAST(keyfield AS int));
	COMMIT;

	RETURN 'Provional letter generated';
END;
/ 

CREATE OR REPLACE FUNCTION lic_deactivate(keyfield IN varchar2, user_id IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN varchar2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN	
  
	IF approval='ACTIVATE' THEN      
		UPDATE client_license SET is_active='1' WHERE client_license_id = CAST(keyfield AS int);
		COMMIT;
		RETURN 'License Activated and Email Sent';
	ELSIF approval='DEACTIVATE' THEN
		UPDATE client_license SET is_active='0' WHERE client_license_id = CAST(keyfield AS int);
		COMMIT;
		RETURN 'License Deactivated';      
	END IF;
END;
/

create or replace FUNCTION processLicense(keyfield IN varchar2, user_id IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN varchar2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
    tab_id    integer;
	BEGIN	
  
    SELECT workflow_table_id INTO tab_id FROM client_license WHERE client_license_id = CAST(keyfield AS int);

		IF(approval = 'SELECT') THEN
			RETURN 'No Action Selected';

		ELSIF approval='Activate' THEN
      
			UPDATE client_license SET is_active='1', License_date = SYSDATE WHERE client_license_id = CAST(keyfield AS int);
      		COMMIT;

			INSERT INTO period_license(period_id,client_license_id,status_license_id,status_client_id) VALUES(1,CAST(keyfield AS int),3,2);
			COMMIT;
      
			INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type) VALUES (71, tab_id, 'PERIOD_LICENSE', 50);		
			COMMIT;
			
			RETURN 'License Activated and Email Sent';

		ELSIF approval='Deactivate' THEN
      
			UPDATE client_license SET is_active='0' WHERE client_license_id = CAST(keyfield AS int);
			COMMIT;

			DELETE FROM period_license WHERE client_license_id = CAST(keyfield AS int);
			COMMIT;      
      						
			RETURN 'License Deactivated';

		ELSE
			RETURN 'UNREACHABLE';
      
		END IF;
END;
/


ALTER TABLE fixed_line ADD client_id        NUMBER(*,0);
ALTER TABLE number_type ADD service_type	varchar2(50);

ALTER TABLE numbers ADD capacity integer;
ALTER TABLE numbers ADD CLIENT_ID        NUMBER(*,0);
ALTER TABLE numbers ADD num_series	varchar2(50);

CREATE OR REPLACE VIEW vw_numbers AS
	SELECT number_type.number_type_id, number_type.number_type_name, client.client_id, client.client_name,
		numbers.number_id, numbers.num_series, numbers.start_range, numbers.end_range,
		numbers.capacity, numbers.assignment, numbers.assign_date, numbers.active_date,
		numbers.details
	FROM number_type INNER JOIN numbers ON number_type.number_type_id = numbers.number_type_id
		LEFT JOIN client ON numbers.client_id = client.client_id;


CREATE OR REPLACE FUNCTION alloc_numbers(keyfield IN varchar2, user_id IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN varchar2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
    tab_id    integer;
BEGIN	
  
	IF(approval = 'SELECT') THEN
		RETURN 'No Action Selected';

	ELSIF approval='ASSIGN' THEN
		UPDATE numbers SET assign_date = SYSDATE WHERE number_id = CAST(keyfield AS int);
		COMMIT;      
		
		RETURN 'License Activated and Email Sent';
	ELSIF approval='DEASSIGN' THEN
		UPDATE numbers SET client_id = null, assign_date = null WHERE number_id = CAST(keyfield AS int);
		COMMIT;

		RETURN 'License Deactivated';
	ELSE
		RETURN 'UNREACHABLE';
	END IF;
END;
/


CREATE SEQUENCE postoffice_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_postoffice_id BEFORE INSERT ON postoffice
for each row 
begin     
	if inserting then 
		if :NEW.postofficeid  is null then
			SELECT postoffice_id_seq.nextval into :NEW.postofficeid  from dual;
		end if;
	end if; 
end;
/



ALTER TABLE installation ADD equipment_manufacturer varchar2(120);
ALTER TABLE installation ADD install_email varchar2(120);
ALTER TABLE installation ADD install_telephone varchar2(120);
ALTER TABLE installation ADD install_town varchar2(120);
ALTER TABLE installation ADD install_road varchar2(120);
ALTER TABLE installation ADD install_lrno varchar2(120);
ALTER TABLE installation ADD install_building varchar2(120);
ALTER TABLE installation ADD install_floor varchar2(120);
ALTER TABLE installation ADD is_completed      CHAR(1 BYTE) DEFAULT '0' NOT NULL ENABLE;
ALTER TABLE installation ADD completion_date date;

ALTER TABLE installation ADD is_workflow_complete CHAR(1 BYTE) DEFAULT '0' NOT NULL ENABLE;
ALTER TABLE installation ADD workflow_table_id NUMBER(*,0);
ALTER TABLE installation ADD CREATED_BY NUMBER(*,0);

CREATE OR REPLACE VIEW vw_installation AS
	SELECT client_license.client_license_id, client.client_name as contractor_name,
		license.license_id, license.license_name,
		installation.installation_id, installation.project_contractor, installation.install_date, 
		installation.installation_type, installation.is_approved, installation.is_rejected,
		installation.client_name, installation.postal_address, installation.physical_address,
		installation.install_town, installation.install_road, installation.install_lrno,
		installation.equipment_make, installation.equipment_model, installation.findings,
		installation.is_completed, installation.completion_date, installation.sub_schedule_id,
		installation.workflow_table_id, installation.is_workflow_complete,
		('<a href=' || installation.checklist_url || ' _blank=yes>Report</a>') as report_url,
		('P.o. Box: '||installation.postal_address || ' ' || installation.physical_address) as client_address
	FROM installation INNER JOIN client_license ON installation.client_license_id = client_license.client_license_id
		INNER JOIN client ON client_license.client_id = client.client_id
		INNER JOIN license ON client_license.license_id = license.license_id
		INNER JOIN license_type ON license.license_type_id = license_type.license_type_id;

CREATE OR REPLACE TRIGGER TR_INSTALLATION_ID BEFORE INSERT ON installation for each row 
begin     
	if inserting then 
		if :NEW.installation_id  is null then
			SELECT installation_id_seq.nextval into :NEW.installation_id  from dual;
			SELECT workflow_table_id_seq.nextval into :NEW.workflow_table_id from dual;
		end if;
	end if; 
end;
/

CREATE OR REPLACE TRIGGER tr_installation_workflow AFTER UPDATE OR INSERT ON installation FOR EACH ROW 
DECLARE
	PRAGMA AUTONOMOUS_TRANSACTION;

	wfid 			INTEGER;
	apprid			INTEGER;
	appr_group		INTEGER;
	clientname		VARCHAR(120);
	tasktype		VARCHAR(120);
	wf_type 		VARCHAR2(64);
BEGIN  

	wfid := :NEW.workflow_table_id;
	wf_type := 'INSTALLATION'; 
	tasktype := 'Certification';

	SELECT seq_approval_group.nextval INTO appr_group FROM dual;

	BEGIN
		SELECT client.client_name INTO clientname
		FROM client INNER JOIN client_license ON client.client_id = client_license.client_id
		WHERE (client_license.client_license_id = :NEW.client_license_id);
		EXCEPTION WHEN NO_DATA_FOUND THEN clientname := null;
	END;

	BEGIN
		SELECT max(approvals.approval_id) INTO apprid 
		FROM approvals
		WHERE (approvals.table_id = wfid);
		EXCEPTION WHEN NO_DATA_FOUND THEN apprid := null;
	END;

	IF(:NEW.is_completed = '1') AND (apprid is null) THEN
		--INSERT THE FIRST APPROVALS to all the relevant entities
		INSERT INTO approvals (workflow_phase_id, approval_group, table_name, table_id, org_entity_id, app_entity_id, escalation_days, escalation_hours, approval_level, approval_narrative, to_be_done, task_source, task_type)
		SELECT workflow_phases.workflow_phase_id, appr_group, wf_type, wfid, :NEW.created_by, entity_subscriptions.entity_id, 0, 3, 1, workflow_phases.phase_narrative, workflow_phases.phase_narrative, clientname, tasktype
		FROM workflow_phases
			INNER JOIN entity_subscriptions ON workflow_phases.approval_entity_id = entity_subscriptions.entity_type_id
			INNER JOIN workflows ON workflow_phases.workflow_id = workflows.workflow_id
		WHERE (workflows.table_name = wf_type) AND (workflow_phases.approval_level='1')
		ORDER BY workflow_phases.approval_level, workflow_phases.workflow_phase_id;
		COMMIT;
		
		--... and checklists for the first level	
		INSERT INTO approval_checklists (checklist_id,workflow_table_id)
		SELECT checklist_id, wfid
		FROM checklists INNER JOIN workflow_phases ON checklists.workflow_phase_id = workflow_phases.workflow_phase_id
			INNER JOIN workflows ON workflow_phases.workflow_id = workflows.workflow_id
		WHERE (workflows.table_name = wf_type) AND (workflow_phases.approval_level = '1')
		ORDER BY workflow_phases.approval_level, workflow_phases.workflow_phase_id;
		COMMIT;
	END IF;
END;
/

CREATE OR REPLACE FUNCTION processClientInspection(cli_id IN varchar2, user_id IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;

	BEGIN

		--SELECT workflow_table_id, clc_id INTO tab_id, clc FROM client_license WHERE client_license_id = CAST(cli_lic_id AS INT);

		IF approval = 'SELECT' THEN
			RETURN 'NO SELECTION MADE';

		ELSIF approval = 'Add' THEN
    
			INSERT INTO client_inspection(client_id,sub_schedule_id,activity_type_id,created_by) 
			VALUES(CAST(cli_id AS INT), CAST(filter_id AS INT),6, CAST(user_id AS INT));
			COMMIT;      
			RETURN 'Added '|| cli_id || ' to Schedule :' || filter_id ;

		ELSIF approval = 'Remove' THEN
    
			DELETE FROM client_inspection WHERE client_id = CAST(cli_id AS int) AND sub_schedule_id = CAST(filter_id AS int) AND activity_type_id = 6;
			COMMIT;      
			RETURN 'Removed '|| cli_id || ' From Schedule :' || filter_id ;

		ELSIF (approval = 'Complied' ) THEN			
			
			RETURN 'Client ' || approval;

		ELSIF (approval = 'Not Complied') THEN
			
			RETURN 'Client ' || approval;

		ELSIF (approval = 'AddInspect') THEN
			UPDATE installation SET sub_schedule_id = CAST(filter_id AS int) 
			WHERE installation_id = CAST(cli_id AS INT);
			COMMIT;
		ELSE
			RETURN 'UNREACHABLE';
		END IF;

	RETURN 'Done';
		
END;
/
 
CREATE OR REPLACE FORCE VIEW vw_approval_checklists AS
	SELECT approval_checklists.approval_checklist_id,
		approval_checklists.done,
		approval_checklists.updated,
		entitys.entity_id AS updater_id,
		entitys.entity_name AS updater_name,
		approval_checklists.workflow_table_id,
		approval_checklists.checklist_comment,
		checklists.checklist_id,
		checklists.checklist_number,
		checklists.requirement,
		checklists.is_mandatory,
		checklists.checklist_group,
		workflow_phases.workflow_phase_id,
		workflow_phases.phase_narrative,
		approvals.approval_id
	FROM approval_checklists INNER JOIN checklists ON approval_checklists.checklist_id = checklists.checklist_id
		INNER JOIN workflow_phases ON checklists.workflow_phase_id = workflow_phases.workflow_phase_id
		INNER JOIN approvals ON (workflow_phases.workflow_phase_id = approvals.workflow_phase_id)
			AND (approval_checklists.workflow_table_id = approvals.table_id)
		LEFT JOIN entitys ON approval_checklists.updated_by = entitys.entity_id;

CREATE OR REPLACE FORCE VIEW vw_approvals AS
  SELECT approvals.approval_id,
    approvals.approve_status,
    approvals.forward_id,
    approvals.is_ad_hoc,
    approvals.table_name,
    approvals.table_id,
    approvals.escalation_time,
    approvals.application_date,
    approvals.completion_date,
    approvals.action_date,
    approvals.approval_narrative,
    approvals.to_be_done,
    approvals.what_is_done,
    workflow_phases.notice_file,
    workflow_phases.workflow_phase_id,
    workflow_phases.approval_level,
    approvals.approval_group,
    workflow_phases.notice_email,
    workflow_phases.advice_email,
    workflow_phases.review_email,
    workflow_phases.return_level,
    workflow_phases.escalation_hours,
    workflow_phases.notice,
    workflow_phases.required_approvals,
    workflow_phases.phase_narrative,
    workflows.workflow_id,
    workflows.workflow_name,
    entity_types.entity_type_id,
    entity_types.entity_type_name,
    actual.entity_id     AS actual_entity_id,
    actual.entity_name   AS actual_entity_name,
    actual.primary_email AS actual_entity_email,
    origin.entity_id     AS origin_entity_id,
    origin.entity_name   AS origin_entity_name,
    origin.primary_email AS origin_entity_email,
    appr.entity_id       AS approving_entity_id,
    appr.entity_name     AS approving_entity_name,
    appr.primary_email   AS approving_entity_email,
    client.client_id,
    COALESCE(client.client_name, approvals.task_source, COALESCE(client_inspection.complainant_name,'SCHEDULE')) AS client_name,
    client.id_number,
    client.pin,
    client.postal_code,
    client.email,
    license.license_id,
    COALESCE(license.license_name, approvals.task_type, DECODE(client_inspection.activity_type_id, 1, 'Interference', 2, 'Monitoring', 3, 'Inspection', 'INSPECTION')) AS license_name,
    license.license_type_id
  FROM approvals INNER JOIN workflow_phases ON approvals.workflow_phase_id = workflow_phases.workflow_phase_id
	INNER JOIN workflows ON workflow_phases.workflow_id = workflows.workflow_id
	LEFT JOIN entitys actual ON approvals.entity_id = actual.entity_id
	INNER JOIN entitys origin ON approvals.org_entity_id = origin.entity_id
	INNER JOIN entitys appr ON approvals.app_entity_id = appr.entity_id
	INNER JOIN entity_types ON workflow_phases.approval_entity_id = entity_types.entity_type_id
	LEFT JOIN client_license ON approvals.table_id = client_license.workflow_table_id
	LEFT JOIN client_inspection ON approvals.table_id = client_inspection.workflow_table_id
	LEFT JOIN license ON client_license.license_id = license.license_id
	LEFT JOIN client ON client_license.client_id = client.client_id;

CREATE OR REPLACE FORCE VIEW vw_notice AS
  SELECT notice.notice_id,
    notice.client_license_id,
    notice.client_inspection_id,
    notice.period_license_id,
    notice.notice_letter,
    notice.link_table_name,
    notice.link_table_id,
    notice.notice_date,
    notice.deadline_months,
    notice.workflow_table_id,
    notice.created,
    notice.created_by,
    notice.updated,
    notice.updated_by,
    notice.notice_name,
    notice.notice_response,
    notice.is_penalty,
    notice.penalty,
    notice.penalty_remarks,
    notice.is_notice_response,
    notice.response_date,
    notice.is_penalty_paid,
    notice.revocation_notice,
    notice.is_revocation,
    notice.rev_notice_date,
    notice.revocation,
    notice.revocation_date,
    notice.is_compliant,
    notice.compliant_date,
    notice.is_notice,
    notice.is_workflow_complete,
    notice.notice_type_id,
    notice.details,
    COALESCE(vw_client_inspection.client_id, vw_period_license.client_id)     AS client_id,
    COALESCE(vw_client_inspection.client_name, vw_period_license.client_name) AS client_name,
	COALESCE(vw_period_license.license_name, 'INSPECTION') AS license_name
  FROM notice LEFT JOIN vw_client_inspection ON notice.client_inspection_id = vw_client_inspection.client_inspection_id
  LEFT JOIN vw_period_license ON notice.period_license_id = vw_period_license.period_license_id;

