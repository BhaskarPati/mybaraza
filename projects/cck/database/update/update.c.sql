ALTER TABLE approvals ADD task_source		varchar(120);
ALTER TABLE approvals ADD task_type			varchar(120);

ALTER TABLE SUB_SCHEDULE ADD quarter_id integer;

ALTER TABLE SCHEDULE ADD WORKFLOW_TABLE_ID NUMBER(*,0);
ALTER TABLE SCHEDULE ADD IS_WORKFLOW_COMPLETE CHAR(1 BYTE) DEFAULT '0' NOT NULL;

ALTER TABLE NOTICE ADD NOTICE_TYPE_ID NUMBER(*,0) DEFAULT 1;

ALTER TABLE PERIOD_LICENSE ADD IS_COMPLIANT     CHAR(1 BYTE) DEFAULT '1' NOT NULL ENABLE;
ALTER TABLE CLIENT_LICENSE ADD IS_COMPLIANT     CHAR(1 BYTE) DEFAULT '1' NOT NULL ENABLE;

CREATE OR REPLACE FORCE VIEW vw_client AS
  SELECT client.client_id,
	client.is_active,
    client.client_name,
    client.id_number,
    client.pin,
    client.accounts_code,
    client.postal_code,
    client.sys_country_id,
    client.address,
    client.premises,
    client.street,
    client.town,
    client.fax,
    client.email,
    client.file_number,
    client.country_code,
    client.tel_no,
    client.mobile_num,
    client.building_floor,
    client.lr_number,
    client.website,
    client.division,
	client.is_illegal,
    (client.client_name || ' <br>P.o. Box: ' || client.address || ' <br>Email: ' || client.email || ' <br>Tel: ' 
		|| client.tel_no || ' <br>Mobile: ' || client.mobile_num || ' <br>Website: ' || client.website) AS client_detail,
    client_category.client_category_id,
    client_category.client_category_name,
    client_industry.client_industry_id,
    client_industry.client_industry_name,
    status_client.status_client_id,
    status_client.status_client_name,
    id_type.id_type_id,
    id_type.id_type_name
  FROM client INNER JOIN client_category ON client.client_category_id = client_category.client_category_id
	INNER JOIN client_industry ON client.client_industry_id = client_industry.client_industry_id
	LEFT JOIN status_client ON client.status_client_id = status_client.status_client_id
	INNER JOIN id_type ON client.id_type_id = id_type.id_type_id;

CREATE OR REPLACE FORCE VIEW vw_client_license AS
  SELECT client_license.client_license_id,
    client_license.license_number,
    client_license.is_rolled_out,
    client_license.purpose_of_license,
    client_license.is_network_expansion,
    client_license.is_freq_expansion,
    client_license.is_license_reinstatement,
    client_license.is_exclusive_access,
    client_license.exclusive_bw_MHz,
    client_license.is_expansion_approved,
    client_license.skip_clc ,
    client_license.application_date,
    client_license.offer_sent_date,
    client_license.offer_approved,
    client_license.offer_approved_date,
    client_license.offer_approved_by,
    client_license.license_date,
    client_license.license_start_date,
    client_license.license_stop_date,
    client_license.rejected_date,
    client_license.rollout_date,
    client_license.renewal_date,
    client_license.commitee_remarks,
    client_license.secretariat_remarks,
    client_license.remarks,
    client_license.details,
    client_license.workflow_table_id,
    client_license.is_active AS is_license_active,
    client_license.is_offer_sent,
    client_license.tac_approval_date,
    client_license.certification_date,
    client_license.is_at_govt_printer,
    client_license.govt_forwared_date,
    client_license.is_gazetted,
    client_license.is_gazetted_rejected,
    client_license.gazettement_date,
    client_license.gazettement_narrative,
    client_license.is_workflow_complete,
	client_license.is_compliant,
    client.client_id,
    client.client_name,
    client.id_number,
    client.pin,
    client.postal_code,
    client.town,
    client.email,
    license.license_id,
    license.license_name,
    license_type.license_type_id,
    license_type.license_type_name,
    COALESCE(clc.clc_id,0) AS clc_id,
    clc_number,
    clc.clc_date,
    clc.is_active,
    clc.doc_url,
    clc.dms_space_url,
    clc.minute_number,
    clc.minute_doc,
    status_license.status_license_id,
    status_license.status_license_name
  FROM client_license INNER JOIN client ON client_license.client_id = client.client_id
	INNER JOIN license ON client_license.license_id = license.license_id
	LEFT JOIN status_license ON client_license.status_license_id = status_license.status_license_id
	LEFT JOIN license_type ON license.license_type_id = license_type.license_type_id
	LEFT JOIN clc ON client_license.clc_id = clc.clc_id;

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
    COALESCE(client.client_name, approvals.task_source, 'SCHEDULE') AS client_name,
    client.id_number,
    client.pin,
    client.postal_code,
    client.email,
    license.license_id,
	license.license_type_id,
    COALESCE(license.license_name, approvals.task_type, 'INSPECTION') AS license_name
  FROM approvals INNER JOIN workflow_phases ON approvals.workflow_phase_id = workflow_phases.workflow_phase_id
	INNER JOIN workflows ON workflow_phases.workflow_id = workflows.workflow_id
	LEFT JOIN entitys actual ON approvals.entity_id = actual.entity_id
	INNER JOIN entitys origin ON approvals.org_entity_id = origin.entity_id
	INNER JOIN entitys appr ON approvals.app_entity_id = appr.entity_id
	INNER JOIN entity_types ON workflow_phases.approval_entity_id = entity_types.entity_type_id
	LEFT JOIN client_license ON approvals.table_id = client_license.workflow_table_id
	LEFT JOIN license ON client_license.license_id = license.license_id
	LEFT JOIN client ON client_license.client_id = client.client_id;

  
CREATE OR REPLACE FORCE VIEW vw_schedule AS
	SELECT department.org_id, department.department_id, department.department_name, period.period_id, period.period_name,
		schedule.schedule_id, schedule.schedule_name, schedule.workflow_table_id,
		schedule.is_approved, schedule.is_complete, schedule.is_active,
		schedule.schedule_type, schedule.details
	FROM schedule INNER JOIN department ON schedule.department_id = department.department_id
		INNER JOIN period ON schedule.period_id = period.period_id;

CREATE OR REPLACE FORCE VIEW vw_sub_schedule AS
	SELECT vw_schedule.department_id, vw_schedule.department_name, vw_schedule.period_id, vw_schedule.period_name,
		vw_schedule.schedule_id, vw_schedule.schedule_name, vw_schedule.workflow_table_id,
		vw_schedule.is_approved, vw_schedule.is_complete as schedule_complete, vw_schedule.is_active, vw_schedule.schedule_type,
		region.region_id, region.region_name, inspection_type.inspection_type_id, inspection_type.inspection_type_name,
		sub_schedule.sub_schedule_id, sub_schedule.sub_schedule_name, sub_schedule.inspections_to_do,
		sub_schedule.general_req, sub_schedule.start_date, sub_schedule.end_date, sub_schedule.is_complete,
		sub_schedule.details, sub_schedule.quarter_id, sub_schedule.is_workflow_complete
	FROM sub_schedule INNER JOIN vw_schedule ON sub_schedule.schedule_id = vw_schedule.schedule_id
		INNER JOIN region ON sub_schedule.region_id = region.region_id
		INNER JOIN inspection_type ON sub_schedule.inspection_type_id = inspection_type.inspection_type_id;

CREATE OR REPLACE FORCE VIEW vw_schedule_participant AS
	SELECT entitys.entity_id, entitys.entity_name,
		schedule_participant.schedule_participant_id, schedule_participant.sub_schedule_id,
		schedule_participant.participant_role, schedule_participant.cost_per_diem,
		schedule_participant.remarks
	FROM schedule_participant INNER JOIN entitys ON schedule_participant.entity_id = entitys.entity_id;

CREATE OR REPLACE FORCE VIEW vw_notice AS
	SELECT notice.notice_id, notice.client_license_id, notice.client_inspection_id, notice.period_license_id, notice.notice_letter, 
		notice.link_table_name, notice.link_table_id, notice.notice_date, notice.deadline_months, notice.workflow_table_id, 
		notice.created, notice.created_by, notice.updated, notice.updated_by, notice.notice_name, notice.notice_response, 
		notice.is_penalty, notice.penalty, notice.penalty_remarks, notice.is_notice_response, notice.response_date, 
		notice.is_penalty_paid, notice.revocation_notice, notice.is_revocation, notice.rev_notice_date, notice.revocation, 
		notice.revocation_date, notice.is_compliant, notice.compliant_date, notice.is_notice, notice.is_workflow_complete, 
		notice.notice_type_id, notice.details,
		COALESCE(vw_client_inspection.client_id, vw_period_license.client_id) AS client_id,
		COALESCE(vw_client_inspection.client_name, vw_period_license.client_name) AS client_name
	FROM notice LEFT JOIN vw_client_inspection ON notice.client_inspection_id = vw_client_inspection.client_inspection_id
		LEFT JOIN vw_period_license ON notice.period_license_id = vw_period_license.period_license_id;

CREATE OR REPLACE TRIGGER tr_notice_id BEFORE INSERT ON notice FOR EACH ROW 
BEGIN   
		
	if inserting then 
		if :NEW.notice_id  is null then
			SELECT notice_id_seq.nextval into :NEW.notice_id  from dual;
      
			SELECT workflow_table_id_seq.nextval into :NEW.workflow_table_id from dual;
		end if;

		if (:NEW.CLIENT_LICENSE_ID is null) and (:NEW.PERIOD_LICENSE_ID is not null) then
			BEGIN
				SELECT CLIENT_LICENSE_ID INTO :NEW.CLIENT_LICENSE_ID
				FROM PERIOD_LICENSE
				WHERE (PERIOD_LICENSE_ID = :NEW.PERIOD_LICENSE_ID);
				EXCEPTION WHEN NO_DATA_FOUND THEN :NEW.CLIENT_LICENSE_ID := null;
			END;
		end if;
	end if; 
END;
/

CREATE OR REPLACE TRIGGER tr_notice_workflow AFTER UPDATE OR INSERT ON notice FOR EACH ROW 
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

	SELECT seq_approval_group.nextval INTO appr_group FROM dual;

	IF(:NEW.IS_NOTICE = '1') THEN wf_type := 'IS_NOTICE'; tasktype := 'Notice'; END IF;
	IF(:NEW.IS_PENALTY = '1') THEN wf_type := 'IS_PENALTY'; tasktype := 'Penalty'; END IF;
	IF(:NEW.IS_REVOCATION = '1') THEN wf_type := 'IS_REVOCATION'; tasktype := 'Revocation'; END IF;

	BEGIN
		IF(:NEW.client_license_id is not null) THEN
			SELECT client.client_name INTO clientname
			FROM client INNER JOIN client_license ON client.client_id = client_license.client_id
			WHERE (client_license.client_license_id = :NEW.client_license_id);
		END IF;
		IF(:NEW.client_inspection_id is not null) THEN
			SELECT client.client_name INTO clientname
			FROM client INNER JOIN client_inspection ON client.client_id = client_inspection.client_id
			WHERE (client_inspection_id = :NEW.client_inspection_id);
		END IF;
		EXCEPTION WHEN NO_DATA_FOUND THEN clientname := null;
	END;

	BEGIN
		SELECT max(approvals.approval_id) INTO apprid 
		FROM approvals INNER JOIN workflow_phases ON approvals.workflow_phase_id = workflow_phases.workflow_phase_id
			INNER JOIN workflows ON workflows.workflow_id = workflow_phases.workflow_id
		WHERE (approvals.table_id = wfid) AND (workflows.TABLE_LINK_FIELD = wf_type);
		EXCEPTION WHEN NO_DATA_FOUND THEN apprid := null;
	END;

	IF (apprid is not null) THEN wf_type := null; END IF;

	--INSERT THE FIRST APPROVALS to all the relevant entities
	INSERT INTO approvals (workflow_phase_id, approval_group, table_name, table_id, org_entity_id, app_entity_id, escalation_days, escalation_hours, approval_level, approval_narrative, to_be_done, task_source, task_type)
	SELECT workflow_phases.workflow_phase_id, appr_group, 'NOTICE', wfid, :NEW.created_by, entity_subscriptions.entity_id, 0, 3, 1, workflow_phases.phase_narrative, workflow_phases.phase_narrative, clientname, tasktype
		FROM workflow_phases
			INNER JOIN entity_subscriptions ON workflow_phases.approval_entity_id = entity_subscriptions.entity_type_id
			INNER JOIN workflows ON workflow_phases.workflow_id = workflows.workflow_id
			WHERE (workflows.table_name = 'NOTICE') AND (workflows.TABLE_LINK_FIELD = wf_type) AND (workflow_phases.approval_level='1')
			ORDER BY workflow_phases.approval_level, workflow_phases.workflow_phase_id;
	COMMIT;
	
	--... and checklists for the first level	
	INSERT INTO approval_checklists (checklist_id,workflow_table_id)
	SELECT checklist_id, wfid
		FROM checklists INNER JOIN workflow_phases ON checklists.workflow_phase_id = workflow_phases.workflow_phase_id
		INNER JOIN workflows ON workflow_phases.workflow_id = workflows.workflow_id
			WHERE (workflows.table_name = 'NOTICE') AND (workflows.TABLE_LINK_FIELD = wf_type) AND (workflow_phases.approval_level='1')
	ORDER BY workflow_phases.approval_level, workflow_phases.workflow_phase_id;
	COMMIT;
END;
/

CREATE OR REPLACE FUNCTION upd_parent_task(childid IN varchar2) return varchar2 is
	PRAGMA AUTONOMOUS_TRANSACTION;
	parentid int;
BEGIN
	SELECT parent_approval_id INTO parentid 
	FROM approvals WHERE approval_id = CAST(childid AS INT);

	IF(parentid is not null)THEN
		UPDATE approvals SET entity_id = null, approve_status = 'D' WHERE approval_id = parentid;
		COMMIT;
	END IF;

	return 'Done';	
END;
/

CREATE OR REPLACE TRIGGER tr_schedule_id BEFORE INSERT ON schedule FOR EACH ROW 
begin     
	if inserting then 
		if :NEW.schedule_id is null then
			SELECT schedule_id_seq.nextval into :NEW.schedule_id from dual;
		end if;

		SELECT workflow_table_id_seq.nextval into :NEW.workflow_table_id from dual;
	end if; 
end;
/

CREATE OR REPLACE TRIGGER tr_sch_workflow AFTER INSERT ON schedule FOR EACH ROW 
DECLARE
	wfid 	INTEGER;
	apprid	INTEGER;
	orgid 	INTEGER;
	appr_group	INTEGER;
BEGIN  
	--SELECT workflow_table_id_seq.nextval into wfid from dual;		--this has bn taken care of at BEFORE INSERT
	wfid := :NEW.workflow_table_id;		
	SELECT seq_approval_group.nextval INTO appr_group FROM dual;

	--identify wether FSM or LCS
	SELECT department.org_id INTO orgid 
	FROM department 
	WHERE department_id = :NEW.department_id;

	--INSERT THE FIRST APPROVALS to all the relevant entities
	INSERT INTO approvals (workflow_phase_id, approval_group, table_name, table_id, org_entity_id, app_entity_id, escalation_days, escalation_hours, approval_level, approval_narrative, to_be_done)
	SELECT workflow_phases.workflow_phase_id, appr_group, 'SCHEDULE', wfid, :NEW.created_by, entity_subscriptions.entity_id, 0, 3, 1, workflow_phases.phase_narrative, 'To do - ' || workflow_phases.phase_narrative				
			FROM workflow_phases				
			INNER JOIN entity_subscriptions ON workflow_phases.approval_entity_id = entity_subscriptions.entity_type_id
			INNER JOIN workflows ON workflow_phases.workflow_id = workflows.workflow_id
			WHERE (workflows.table_name = 'SCHEDULE') AND (workflows.table_link_id = orgid)
			AND (workflow_phases.is_utility = '0') AND (workflow_phases.approval_level='1')
			ORDER BY workflow_phases.approval_level, workflow_phases.workflow_phase_id;

END;
/

CREATE OR REPLACE TRIGGER upd_schedule_id BEFORE UPDATE ON schedule FOR EACH ROW 
DECLARE
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	if updating then 
		if :NEW.IS_WORKFLOW_COMPLETE = '1' then
			:NEW.IS_APPROVED := '1';

			UPDATE sub_schedule SET is_workflow_complete = '1' WHERE schedule_id = :NEW.SCHEDULE_ID;
			COMMIT;
		end if;
	end if; 
END;
/

CREATE OR REPLACE FUNCTION upd_compliance(clientid IN NUMBER) return varchar2 is
	PRAGMA AUTONOMOUS_TRANSACTION;
	insp int;
	notc int;
	notl int;
BEGIN
	
	SELECT count(client_inspection_id) INTO insp
	FROM client_inspection 
	WHERE (is_fully_compliant = '0') AND (client_id = clientid);
	IF(insp is null)THEN insp := 0; END IF;

	SELECT count(notice.notice_id) INTO notc
	FROM notice INNER JOIN client_inspection ON notice.client_inspection_id = client_inspection.client_inspection_id
	WHERE (notice.is_compliant = '0') AND (client_inspection.client_id = clientid);
	IF(notc is null)THEN notc := 0; END IF;

	SELECT count(notice.notice_id) INTO notl
	FROM notice INNER JOIN vw_period_license ON notice.period_license_id = vw_period_license.period_license_id
	WHERE (notice.is_compliant = '0') AND (vw_period_license.client_id = clientid);
	IF(notl is null)THEN notl := 0; END IF;

	IF(insp = 0) AND (notc = 0) AND (notl = 0) THEN
		UPDATE client SET compliant = '1' WHERE (client_id = clientid);
		COMMIT;
	ELSE
		UPDATE client SET compliant = '0' WHERE (client_id = clientid);
		COMMIT;
	END IF;

	return 'Done';	
END;
/

CREATE OR REPLACE FUNCTION upd_inspection(clins IN varchar2) return varchar2 is
	PRAGMA AUTONOMOUS_TRANSACTION;
	tdd varchar2(120);
BEGIN
	
	SELECT upd_compliance(client_id) INTO tdd
	FROM client_inspection WHERE (client_inspection_id = CAST(clins as INT));

	return tdd;	
END;
/

CREATE OR REPLACE FUNCTION upd_notice(clins IN varchar2) return varchar2 is
	PRAGMA AUTONOMOUS_TRANSACTION;
	ciid 	integer;
	lcid 	integer;
	clid 	integer;
	iscom	char(1);
	tdd 	varchar2(120);
BEGIN
	
	SELECT client_inspection_id, period_license_id, client_license_id, is_compliant INTO ciid, lcid, clid, iscom
	FROM notice
	WHERE (notice.notice_id = CAST(clins as INT));

	IF(ciid is not null)THEN
		UPDATE client_inspection SET is_fully_compliant = iscom WHERE (client_inspection_id = ciid);
		COMMIT;
	END IF;

	IF(lcid is not null)THEN
		UPDATE period_license SET is_compliant = iscom WHERE (period_license_id = lcid);
		COMMIT;
		UPDATE client_license SET is_compliant = iscom WHERE (client_license_id = clid);
		COMMIT;
	END IF;

	SELECT upd_compliance(COALESCE(vw_client_inspection.client_id, vw_period_license.client_id)) INTO tdd
	FROM notice LEFT JOIN vw_client_inspection ON notice.client_inspection_id = vw_client_inspection.client_inspection_id
		LEFT JOIN vw_period_license ON notice.period_license_id = vw_period_license.period_license_id
	WHERE (notice.notice_id = CAST(clins as INT));
	
	return tdd;	
END;
/

CREATE OR REPLACE FUNCTION SUBMITRETURNS(myval1 IN varchar2, myval2 IN varchar2, myval3 IN varchar2, myval4 IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN

	IF(myval3 = 'Quarter1')  THEN
		UPDATE period_license
		SET IS_Q1_RECEIVED = '1', Q1_RECEIVED_DATE = SYSDATE, UPDATED_BY = CAST(myval2 as int), UPDATED_DATE = SYSDATE
		WHERE period_license_id = CAST(myval1 as int);
		COMMIT;
	END IF;
	IF(myval3 = 'Quarter2')  THEN
		UPDATE period_license 
		SET IS_Q2_RECEIVED = '1', Q2_RECEIVED_DATE = SYSDATE, UPDATED_BY = CAST(myval2 as int), UPDATED_DATE = SYSDATE
		WHERE period_license_id = CAST(myval1 as int);
		COMMIT;
	END IF;
	IF(myval3 = 'Quarter3')  THEN
		UPDATE period_license 
		SET IS_Q3_RECEIVED = '1', Q3_RECEIVED_DATE = SYSDATE, UPDATED_BY = CAST(myval2 as int), UPDATED_DATE = SYSDATE
		WHERE period_license_id = CAST(myval1 as int);
		COMMIT;
	END IF;
	IF(myval3 = 'Quarter4')  THEN
		UPDATE period_license 
		SET IS_Q4_RECEIVED = '1', Q4_RECEIVED_DATE = SYSDATE, UPDATED_BY = CAST(myval2 as int), UPDATED_DATE = SYSDATE
		WHERE period_license_id = CAST(myval1 as int);
		COMMIT;
	END IF;
  
	IF(myval3 = 'Annual')  THEN
		UPDATE period_license 
		SET IS_ANUAL_RETURNS_RECEIVED = '1', ANNUAL_RETURNS_RECEIVED_DATE  = SYSDATE, UPDATED_BY = CAST(myval2 as int), UPDATED_DATE = SYSDATE
		WHERE period_license_id = CAST(myval1 as int);
		COMMIT;
	END IF;

	IF(myval3 = 'AR Compliant')  THEN
		UPDATE period_license 
		SET is_ret_compliant_so_far = '1', UPDATED_BY = CAST(myval2 as int), UPDATED_DATE = SYSDATE
		WHERE period_license_id = CAST(myval1 as int);
		COMMIT;
	END IF;

	IF(myval3 = 'AR Non Compliant')  THEN
		UPDATE period_license
		SET is_ret_compliant_so_far = '0', IS_COMPLIANT = '0', UPDATED_BY = CAST(myval2 as int), UPDATED_DATE = SYSDATE
		WHERE period_license_id = CAST(myval1 as int);
		COMMIT;
	END IF;
  
	IF(myval3 = 'Compliant AAA')  THEN
		UPDATE period_license 
		SET IS_AAA_COMPLIANT = '1', UPDATED_BY = CAST(myval2 as int), UPDATED_DATE = SYSDATE
		WHERE period_license_id = CAST(myval1 as int);
		COMMIT;
	END IF;

  IF(myval3 = 'Non Compliant AAA')  THEN
		UPDATE period_license
		SET IS_AAA_COMPLIANT = '0', IS_COMPLIANT = '0', UPDATED_BY = CAST(myval2 as int), UPDATED_DATE = SYSDATE
		WHERE period_license_id = CAST(myval1 as int);
		COMMIT;
	END IF;

	RETURN 'complete';
END;
/

