ALTER TABLE client ADD end_year_month				integer default 12;

ALTER TABLE client_license ADD number_type_id		NUMBER(*,0);
ALTER TABLE client_license ADD number_request		clob;
ALTER TABLE client_license ADD number_responce		clob;
ALTER TABLE workflow_phases ADD allow_checklist		CHAR(1 BYTE) DEFAULT '0' NOT NULL ENABLE;

UPDATE workflow_phases SET allow_checklist = '1' WHERE workflow_phase_id = 632;
COMMIT;

CREATE TABLE period_client (
    period_client_id			NUMBER(*,0) PRIMARY KEY,
    period_id					NUMBER(*,0),
	client_id					NUMBER(*,0),
    annual_gross				FLOAT(63) DEFAULT 0 NOT NULL ENABLE,
    non_license_revenue			FLOAT(63) DEFAULT 0 NOT NULL ENABLE,
    annual_fee_due				FLOAT(63) DEFAULT 0 NOT NULL ENABLE,
	return_date					DATE,
	return_notice				CHAR(1 BYTE) DEFAULT '0' NOT NULL,
	is_aaa_compliant			CHAR(1 BYTE) DEFAULT '0' NOT NULL,
	details						CLOB,
	FOREIGN KEY (PERIOD_ID) REFERENCES PERIOD (PERIOD_ID),
	FOREIGN KEY (CLIENT_ID) REFERENCES CLIENT (CLIENT_ID),
	CONSTRAINT period_client_unique UNIQUE(period_id, client_id)
);
CREATE SEQUENCE period_client_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_period_client_id BEFORE INSERT ON period_client FOR EACH row BEGIN 
	IF inserting THEN 
		IF :NEW.period_client_id IS NULL THEN
			SELECT period_client_id_seq.nextval INTO :NEW.period_client_id FROM dual;
		END IF;
	END IF;
END;
/

CREATE OR REPLACE FORCE VIEW vw_period_client AS
	SELECT client.client_id,
		client.client_name,
		client.id_number,
		client.pin,
		client.postal_code,
		client.town,
		client.email,
		client.is_active,
		client.is_illegal,
		client.end_year_month,
		to_char(to_date('01-' || client.end_year_month || '-2012', 'DD-MM-YYYY'), 'Month') as end_year_name,
		period.period_id,
		period.period_name,
		period_client.period_client_id,
		period_client.annual_gross,
		period_client.non_license_revenue,
		(period_client.annual_gross - period_client.non_license_revenue) as license_revenue,
		0.004 * (period_client.annual_gross - period_client.non_license_revenue) as aaa_anual_fee,
		period_client.annual_fee_due,
		period_client.return_date,
		period_client.return_notice,
		period_client.is_aaa_compliant,
		period_client.details,
		afee.sum_afee,
		(CASE WHEN afee.sum_afee > (0.004 * (period_client.annual_gross - period_client.non_license_revenue)) THEN afee.sum_afee
			ELSE (0.004 * (period_client.annual_gross - period_client.non_license_revenue)) END) as annual_fee
	FROM period_client INNER JOIN period ON period_client.period_id = period.period_id
		INNER JOIN client ON period_client.client_id = client.client_id
		LEFT JOIN (SELECT Client_License.Client_Id, Sum(License.Annual_Fee) As sum_afee
			FROM client_license Inner Join license On client_license.license_id = license.license_id 
			WHERE (License.Department_Id = 4) AND (Client_License.is_active = '1')
			GROUP BY client_License.client_Id) afee ON client.client_Id = afee.client_id;

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
    client_license.offer_date,
    client.client_id,
    client.client_name,
    client.town,
    client.id_number,
    client.pin,
    client.postal_code,
    client.email,
    license.license_id,
    license.license_name,
    license.department_id,
    license.annual_fee,
    license_type.license_type_id,
    license_type.license_type_name,
    COALESCE(clc.clc_id, 0) AS clc_id,
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

CREATE OR REPLACE FUNCTION processLicense(keyfield IN varchar2, user_id IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN varchar2 IS
PRAGMA AUTONOMOUS_TRANSACTION;
    tab_id		integer;
	clientid	integer;
	periodid	integer;
	pclientid	integer;
BEGIN	
  
    SELECT workflow_table_id, client_id INTO tab_id, clientid
	FROM client_license WHERE client_license_id = CAST(keyfield AS int);

	SELECT max(period_id) INTO periodid
	FROM period
	WHERE (is_open = '1');

	BEGIN
		SELECT period_client_id INTO pclientid
		FROM period_client
		WHERE (client_id = clientid) AND (period_id = periodid);
		EXCEPTION WHEN NO_DATA_FOUND THEN pclientid := null;
	END;

	IF(approval = 'SELECT') THEN
		RETURN 'No Action Selected';

	ELSIF approval='Activate' THEN
	
		UPDATE client_license SET is_active='1', status_license_id = 3, license_date = SYSDATE
		WHERE client_license_id = CAST(keyfield AS int);
	
		INSERT INTO period_license(period_id, client_license_id, status_license_id, status_client_id) 
		VALUES(periodid, CAST(keyfield AS int), 3, 2);
		COMMIT;

		IF(pclientid is null)THEN
			INSERT INTO period_client(period_id, client_id) 
			VALUES(periodid, clientid);
			COMMIT;
		END IF;
	
		INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type) VALUES (71, tab_id, 'PERIOD_LICENSE', 50);		
		COMMIT;
		
		RETURN 'License Activated and Email Sent';

	ELSIF approval='Deactivate' THEN
	
		UPDATE client_license set is_active='0', status_license_id = 7 
		WHERE client_license_id = CAST(keyfield AS int);
		COMMIT;

		DELETE FROM period_license WHERE client_license_id = CAST(keyfield AS int);
		COMMIT;	
						
		RETURN 'License Deactivated';

	ELSE
		RETURN 'UNREACHABLE';
	
	END IF;
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
		IF(:NEW.period_client_id is not null) THEN
			SELECT client.client_name INTO clientname
			FROM client INNER JOIN period_client ON client.client_id = period_client.client_id
			WHERE (period_client_id = :NEW.period_client_id);
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


CREATE OR REPLACE FUNCTION processNotification(keyfield IN varchar2, user_id IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN varchar2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	tab_id		integer;	
BEGIN

	SELECT workflow_table_id INTO tab_id FROM client_license WHERE client_license_id = CAST(keyfield AS INT);
   
	IF(approval = 'SELECT') THEN
		RETURN 'No Action Selected';

	ELSIF(approval = 'Submit')  THEN
		INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type) VALUES (61, tab_id, 'CLIENT_LICENSE', 5);		
		COMMIT;
			
		UPDATE client_license SET is_offer_sent = '1', offer_date = SYSDATE 
		WHERE client_license_id = CAST(keyfield AS INT);
		COMMIT;
      
		RETURN 'Queued ' || keyfield;				
	ELSE
		RETURN 'Unknown Option';
	END IF;

		--RETURN 'Please Complete Checklist';  
	RETURN 'UNREACHABLE';
END;
/

