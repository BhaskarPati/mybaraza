Alter Table Client_License Add     is_archived Char(1 Byte) Default '0' Not Null;
Alter Table Client_License Add     archive_date DATE;

CREATE OR REPLACE VIEW vw_client_license AS
	SELECT client_license.client_license_id,client_license.license_number,client_license.is_rolled_out,client_license.purpose_of_license,client_license.is_network_expansion,client_license.is_freq_expansion,client_license.is_license_reinstatement,client_license.is_exclusive_access,client_license.
    exclusive_bw_MHz,client_license.is_expansion_approved,client_license.skip_clc ,client_license.application_date,client_license.offer_sent_date,client_license. offer_approved,client_license.offer_approved_date,client_license.
    offer_approved_by,client_license.license_date,client_license.license_start_date,client_license.license_stop_date,client_license.rejected_date,client_license.rollout_date,client_license.renewal_date,client_license.commitee_remarks,client_license.
    secretariat_remarks,client_license.remarks,client_license.details, client_license.workflow_table_id,client_license.is_active as is_license_active,
	client_license.is_offer_sent,client_license.tac_approval_date, client_license.certification_date, client_license.is_at_govt_printer,client_license.govt_forwared_date,
	client_license.is_gazetted,client_license.is_gazetted_rejected,client_license.gazettement_date,client_license.gazettement_narrative, client_license.is_workflow_complete,
	client_license.contact_person_name, client_license.file_number,
	client.client_id, client.client_name, client.id_number, client.pin, client.postal_code, client.email, client.address, client.town,
	client_license.is_compliant,client_license.offer_date, client_license.cancellation_date, 
	client_license.created as client_license_created, client_license.updated as client_license_updated,
	client_license.is_archived, client_license.archive_date,
    license.license_id, license.department_id, license.conditions_pdf_link, license.license_period,
	(license.license_name || DECODE(client_license.is_network_expansion,'1',' EXPANSION', '')) as license_name, license.annual_fee,
    license_type.license_type_id, license_type.license_type_name,  
	COALESCE(clc.clc_id,0) as clc_id, clc_number, clc.clc_date, clc.is_active, clc.doc_url, clc.dms_space_url, clc.minute_number, clc.minute_doc,
	--COALESCE(tac.tac_id,0) as tac_id, tac_number, tac.tac_date, tac.minute_number as tac_minute_number,
	COALESCE(board_meeting.board_meeting_id,0) as board_meeting_id, board_meeting.board_meeting_number, board_meeting.board_meeting_date, 
	board_meeting.doc_url as board_paper_url,
	status_license.status_license_id, status_license.status_license_name,
	client_category.client_category_id, client_category.client_category_name, client_industry.client_industry_id, client_industry.client_industry_name
	FROM client_license
	INNER JOIN client ON client_license.client_id = client.client_id
	INNER JOIN license ON client_license.license_id = license.license_id	
	INNER JOIN client_category ON client.client_category_id = client_category.client_category_id
	INNER JOIN client_industry ON client.client_industry_id = client_industry.client_industry_id
	LEFT JOIN status_license ON client_license.status_license_id = status_license.status_license_id
	LEFT JOIN license_type ON license.license_type_id = license_type.license_type_id
	LEFT JOIN clc ON client_license.clc_id = clc.clc_id
	--LEFT JOIN tac ON client_license.tac_id = tac.tac_id
	LEFT JOIN board_meeting ON client_license.board_meeting_id = board_meeting.board_meeting_id;

CREATE OR REPLACE FUNCTION processNotification(keyfield IN varchar2, user_id IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN varchar2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;

	tab_id		integer;
	curr_phase	integer;
BEGIN

	SELECT workflow_table_id INTO tab_id 
	FROM client_license WHERE client_license_id = CAST(keyfield AS INT);

	SELECT max(approval_level) INTO curr_phase 
	FROM approvals WHERE table_id = tab_id;
   
	IF(approval = 'SELECT') THEN
		RETURN 'No Action Selected';

	ELSIF(approval = 'Submit')  THEN
		INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type) 
		VALUES (61, tab_id, 'CLIENT_LICENSE', 5);		
		COMMIT;
			
		UPDATE client_license SET is_offer_sent = '1', offer_date = SYSDATE 
		WHERE client_license_id = CAST(keyfield AS INT);
		COMMIT;
      
		RETURN 'Queued ' || keyfield;
	ELSIF (approval = 'Archive') THEN
		UPDATE approvals SET approve_status = 'A' 
		WHERE (table_id = tab_id) AND (approval_level = curr_phase);
		COMMIT;

		UPDATE client_license SET is_archived = '1', archive_date = SYSDATE 
		WHERE client_license_id = CAST(keyfield AS INT);
		COMMIT;
	ELSIF (approval = 'Reactivate') THEN
		UPDATE approvals SET approve_status = 'D' 
		WHERE (table_id = tab_id) AND (approval_level = curr_phase);
		COMMIT;

		UPDATE client_license SET is_archived = '0'
		WHERE client_license_id = CAST(keyfield AS INT);
		COMMIT;
	ELSE
		RETURN 'Unknown Option';
	END IF;

		--RETURN 'Please Complete Checklist';  
	RETURN 'UNREACHABLE';
END;
/

