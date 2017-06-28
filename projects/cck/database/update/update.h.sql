
CREATE TABLE workflow_sql (
	workflow_sql_id			integer primary key,
	workflow_sql_name		varchar2(50),
	workflow_phase_id		integer,
	is_condition			CHAR(1) DEFAULT '0' NOT NULL,
	is_action				CHAR(1) DEFAULT '0' NOT NULL,
	message_number			varchar2(32),
	ca_sql					clob,
	FOREIGN KEY (workflow_phase_id) REFERENCES workflow_phases (workflow_phase_id)
);
CREATE SEQUENCE workflow_sql_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_workflow_sql_id BEFORE INSERT ON workflow_sql FOR EACH row BEGIN 
	IF inserting THEN 
		IF :NEW.workflow_sql_id IS NULL THEN
			SELECT workflow_sql_id_seq.nextval INTO :NEW.workflow_sql_id FROM dual;
		END IF;
	END IF;
END;
/

CREATE OR REPLACE FUNCTION upd_aaa_conditions(clins IN varchar2) return varchar2 is
	PRAGMA AUTONOMOUS_TRANSACTION;
	ciid 	integer;
	lcid 	integer;
	clid 	integer;
	iscom	char(1);
	tdd 	varchar2(120);
BEGIN

	SELECT upd_compliance(client_id) INTO tdd
	FROM period_client
	WHERE (period_client_id = CAST(clins as INT));
	
	return tdd;	
END;
/


CREATE OR REPLACE TRIGGER tr_client_license_upd AFTER UPDATE ON client_license FOR EACH ROW 
DECLARE
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN  

	IF(:NEW.is_workflow_complete = '1')THEN
		UPDATE numbers SET is_assigned = '1', assignment = 'Assigned'
		WHERE client_license_id = :NEW.client_license_id;
		COMMIT;
	END IF;

END;
/

CREATE OR REPLACE FUNCTION exec_approval_sql(wfphid integer, apprid integer) return varchar2 is
	PRAGMA AUTONOMOUS_TRANSACTION;

	TYPE RECORD IS REF CURSOR;
    reca 			RECORD;

	tdd 			VARCHAR2(32);
	query_str 		VARCHAR2(1024);
BEGIN

	FOR reca IN
		(SELECT is_condition, is_action, ca_sql, message_number
		FROM workflow_sql WHERE (workflow_phase_id = wfphid))
	LOOP
		query_str := reca.ca_sql || apprid;
		IF(reca.is_condition = '1')THEN
			EXECUTE IMMEDIATE query_str INTO tdd;
			IF(tdd is null)THEN
				RETURN reca.message_number;
			END IF;
		END IF;
		IF(reca.is_action = '1')THEN
			EXECUTE IMMEDIATE query_str;
			COMMIT;
		END IF;
	END LOOP;

	tdd := null;

	return tdd;	
END;
/

CREATE OR REPLACE FUNCTION upd_parent_task(childid IN varchar2) return varchar2 is
	PRAGMA AUTONOMOUS_TRANSACTION;

	apprid			INTEGER;
	parentid 		INTEGER;
	wfphid 			INTEGER;
	apprst			CHAR(1);
	lc_msg			VARCHAR2(32);
BEGIN
	SELECT approval_id, parent_approval_id, workflow_phase_id, approve_status 
	INTO apprid, parentid, wfphid, apprst
	FROM approvals WHERE approval_id = CAST(childid AS INT);

	IF(parentid is not null) AND (apprst = 'C') THEN
		UPDATE approvals SET entity_id = null, approve_status = 'D' WHERE approval_id = parentid;
		COMMIT;
	END IF;

	IF(apprst = 'C') THEN
		lc_msg := exec_approval_sql(wfphid, apprid);
	END IF;

	return 'Done';	
END;
/

CREATE OR REPLACE FORCE VIEW VW_LICENSE_PAYMENT_HEADER AS
  SELECT license_payment_header.license_payment_header_id,
    license_payment_header.workflow_phase_id,
    license_payment_header.is_sales_order_done,
    license_payment_header.order_number,
    license_payment_header.is_invoice_done,
    license_payment_header.invoice_date,
    license_payment_header.invoice_number,
    license_payment_header.invoice_amount,
    license_payment_header.is_paid,
    license_payment_header.is_void,
    license_payment_header.receipt_number,
    license_payment_header.receipt_amount,
    license_payment_header.description,
    license_payment_header.workflow_table_id,
    license_payment_header.period_client_id,
    license_payment_header.created,
    license_payment_header.updated,
    license_payment_header.receipt_date,
    license_payment_header.order_summary,
    license_payment_header.invoice_summary,
    license_payment_header.receipt_summary,
    license_payment_header.outstanding_amount,
    client_license.client_license_id,
    client_license.license_number,
    client_license.is_rolled_out,
    client_license.purpose_of_license,
    client.client_id,
    client.client_name,
    client.id_number,
    client.pin,
    client.postal_code,
    client.email,
    license.license_id,
    license.license_name,
    license_type.license_type_id,
    license_type.license_type_name,
    lpl.line_amount,
    period_client.period_id,
	workflow_phases.approval_entity_id
  FROM license_payment_header INNER JOIN client_license ON license_payment_header.client_license_id = client_license.client_license_id
  INNER JOIN client ON client_license.client_id = client.client_id
  INNER JOIN license ON Client_License.License_Id = License.License_Id
  LEFT JOIN license_type ON license.license_type_id = license_type.license_type_id
  INNER JOIN
    (SELECT license_payment_header_id,
      SUM(amount) AS line_amount
    FROM license_payment_line
    GROUP BY license_payment_header_id
    ) lpl
	ON License_Payment_Header.License_Payment_Header_Id = Lpl.License_Payment_Header_Id
  LEFT JOIN period_client ON license_payment_header.period_client_id = period_client.period_client_id
  LEFT JOIN workflow_phases ON license_payment_header.workflow_phase_id = workflow_phases.workflow_phase_id;


create or replace FUNCTION processCompliance(keyfield IN varchar2, user_id IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN varchar2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;

	tdd 	varchar2(120);
BEGIN

	SELECT upd_compliance(client_id) INTO tdd
	FROM client
	WHERE client_id = CAST(keyfield as int);
	
	RETURN 'DONE';  
END;
/

