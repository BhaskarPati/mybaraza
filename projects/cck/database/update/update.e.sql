create or replace TRIGGER ins_imis_perpay_gl AFTER INSERT ON imis_perpay_gl FOR EACH ROW
DECLARE
	pragma autonomous_transaction;
BEGIN
	IF(trim(:NEW.sun_ac_code) = '800630')THEN
		INSERT INTO dc_ledger@ln_erp (pf_number, staff_name, period_no, ledger_no,
			payroll_account, description, debit,  credit)
		VALUES (:NEW.pfno, :NEW.NAME, :NEW.MONTH, :NEW.period,
			'100420', :NEW.account_name, :NEW.debit_amount, :NEW.credit_amount);
		COMMIT;
	ELSE
		INSERT INTO dc_ledger@ln_erp (pf_number, staff_name, period_no, ledger_no,
			payroll_account, description, debit,  credit)
		VALUES (:NEW.pfno, :NEW.NAME, :NEW.MONTH, :NEW.period,
			trim(:NEW.sun_ac_code), :NEW.account_name, :NEW.debit_amount, :NEW.credit_amount);
		COMMIT;
	END IF;
End Ins_Imis_Perpay_Gl;
/

INSERT INTO dc_ledger@ln_erp (pf_number, staff_name, period_no, ledger_no, Payroll_Account, Description, Debit, Credit)
SELECT Pfno, Name, Month, Period, trim(Sun_Ac_Code), Account_Name, Debit_Amount, Credit_Amount
FROM Imis_Perpay_Gl


-----------------------------------------------

CREATE SEQUENCE telecom_license_seq MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 800 CACHE 20 NOORDER NOCYCLE;
CREATE SEQUENCE postal_license_seq MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 800 CACHE 20 NOORDER NOCYCLE;

ALTER TABLE period_client ADD is_estimate CHAR(1 BYTE) DEFAULT '0' NOT NULL;
ALTER TABLE period_client ADD is_billed CHAR(1 BYTE) DEFAULT '0' NOT NULL;

ALTER TABLE period_client ADD e_annual_gross FLOAT(63) DEFAULT 0;
ALTER TABLE period_client ADD e_non_license_revenue FLOAT(63) DEFAULT 0;
ALTER TABLE period_client ADD e_annual_fee_due FLOAT(63) DEFAULT 0;

ALTER TABLE license_payment_header ADD period_client_id NUMBER(*,0);
ALTER TABLE license_payment_header ADD FOREIGN KEY (period_client_id) REFERENCES period_client (period_client_id);

ALTER TABLE license_payment_line ADD client_license_id NUMBER(*,0);
ALTER TABLE license_payment_line ADD FOREIGN KEY (CLIENT_LICENSE_ID) REFERENCES CLIENT_LICENSE (CLIENT_LICENSE_ID);

ALTER TABLE notice ADD appr_notice  CHAR(1 BYTE) DEFAULT '0' NOT NULL;
ALTER TABLE notice ADD appr_penalty  CHAR(1 BYTE) DEFAULT '0' NOT NULL;
ALTER TABLE notice ADD appr_revocation  CHAR(1 BYTE) DEFAULT '0' NOT NULL;

CREATE OR REPLACE FORCE VIEW vw_client_license AS
	SELECT client_license.client_license_id,
		client_license.license_number,
		client_license.is_rolled_out,
		client_license.purpose_of_license,
		client_license.is_network_expansion,
		client_license.is_freq_expansion,
		client_license.is_license_reinstatement,
		client_license.is_exclusive_access,
		client_license. exclusive_bw_MHz,
		client_license.is_expansion_approved,
		client_license.skip_clc ,
		client_license.application_date,
		client_license.offer_sent_date,
		client_license. offer_approved,
		client_license.offer_approved_date,
		client_license. offer_approved_by,
		client_license.license_date,
		client_license.license_start_date,
		client_license.license_stop_date,
		client_license.rejected_date,
		client_license.rollout_date,
		client_license.renewal_date,
		client_license.commitee_remarks,
		client_license. secretariat_remarks,
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
		client.client_id,
		client.client_name,
		client.id_number,
		client.pin,
		client.town,
		client.postal_code,
		client.email,
		client_license.is_compliant,
		client_license.offer_date,
		license.license_id,
		license.department_id,
		license.annual_fee,
		(license.license_name || DECODE(client_license.is_network_expansion,'1',' EXPANSION', '')) AS license_name,
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

CREATE OR REPLACE FORCE VIEW vw_period_license AS
  SELECT period_license.period_license_id,
    period_license.workflow_table_id,
    period_license.annual_gross,
    period_license.non_license_revenue,
    period_license.license_revenue,
    period_license.annual_fee_due,
    period_license.is_conditions_compliant,
    period_license.is_conditions_notice_sent,
    period_license.conditions_notification_date,
    period_license.is_AAA_compliant,
    period_license.AAA_notification_letter,
    period_license.is_AAA_notification_sent,
    period_license.AAA_notification_date,
	period_license.is_anual_returns_received,
	period_license.is_q1_received,
	period_license.is_q2_received,
	period_license.is_q3_received,
	period_license.is_q4_received,
	period_license.is_ret_compliant_so_far,
	period_license.is_compliant,
    period.period_id,
    period.period_name,
    client_license.client_license_id,
    client_license.license_number,
    client_license.secretariat_remarks,
    client_license.remarks,
    client_license.details,
    client.client_id,
    client.client_name,
    client.id_number,
    client.pin,
    client.postal_code,
    client.email,
    license.license_id,
    license.license_name,
	license.agt_fee,
	license.annual_fee,
    department.department_id,
    department.department_name,
	department.org_id,
	(license.agt_fee * period_license.license_revenue / 100) as agt_revenue
  FROM period_license INNER JOIN client_license ON period_license.client_license_id = client_license.client_license_id
	INNER JOIN client ON client_license.client_id = client.client_id
	INNER JOIN license ON client_license.license_id = license.license_id
	INNER JOIN license_type ON license.license_type_id = license_type.license_type_id
	INNER JOIN period ON period_license.period_id = period.period_id
	INNER JOIN department ON license.department_id = department.department_id;

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
    client.town,
	(SELECT min(Client_License_Id) FROM Client_License WHERE (client_id = client.client_id)) as client_license_id
  FROM client_inspection INNER JOIN client ON client_inspection.client_id = client.client_id;

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
	(CASE WHEN vw_client_inspection.client_inspection_id is null THEN '0' ELSE '1' END) AS has_inspection,
    COALESCE(vw_client_inspection.client_id, vw_period_license.client_id, vw_period_client.client_id) AS client_id,
    COALESCE(vw_client_inspection.client_name, vw_period_license.client_name, vw_period_client.client_name) AS client_name,
	COALESCE(vw_period_license.license_name, 'INSPECTION') AS license_name,
	COALESCE(vw_period_license.client_license_id, vw_client_inspection.Client_License_Id, vw_period_client.bill_license_id) AS bill_license_id
  FROM notice LEFT JOIN vw_client_inspection ON notice.client_inspection_id = vw_client_inspection.client_inspection_id
	LEFT JOIN vw_period_license ON notice.period_license_id = vw_period_license.period_license_id
	LEFT JOIN vw_period_client ON notice.period_client_id = vw_period_client.period_client_id;

CREATE SEQUENCE period_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_period_id BEFORE INSERT ON period FOR EACH row BEGIN 
	IF inserting THEN 
		IF :NEW.period_id IS NULL THEN
			SELECT period_id_seq.nextval INTO :NEW.period_id FROM dual;
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
		period_client.annual_fee_due,
		period_client.e_annual_gross,
		period_client.e_non_license_revenue,
		period_client.e_annual_fee_due,
		(period_client.annual_gross - period_client.non_license_revenue) as license_revenue,
		0.004 * (period_client.annual_gross - period_client.non_license_revenue) as aaa_anual_fee,
		period_client.return_date,
		period_client.return_notice,
		period_client.is_aaa_compliant,
		period_client.is_estimate,
		period_client.is_billed,
		period_client.details,
		afee.sum_afee,
		(CASE WHEN afee.sum_afee > (0.004 * (period_client.annual_gross - period_client.non_license_revenue)) THEN afee.sum_afee
			ELSE (0.004 * (period_client.annual_gross - period_client.non_license_revenue)) END) as annual_fee,
		(SELECT min(Client_License_Id) FROM Client_License WHERE (is_active = '1') AND (client_id = client.client_id)) as bill_license_id
	FROM period_client INNER JOIN period ON period_client.period_id = period.period_id
		INNER JOIN client ON period_client.client_id = client.client_id
		LEFT JOIN (SELECT Client_License.Client_Id, Sum(License.Annual_Fee) As sum_afee
			FROM client_license Inner Join license On client_license.license_id = license.license_id 
			WHERE (License.Department_Id = 4) AND (Client_License.is_active = '1')
			GROUP BY client_License.client_Id) afee ON client.client_Id = afee.client_id;

CREATE OR REPLACE FORCE VIEW vw_license_payment_header AS
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
	lpl.line_amount
  FROM license_payment_header INNER JOIN client_license ON license_payment_header.client_license_id = client_license.client_license_id
	INNER JOIN client ON client_license.client_id = client.client_id
	INNER JOIN License ON Client_License.License_Id = License.License_Id
	LEFT JOIN license_type ON license.license_type_id = license_type.license_type_id
	INNER JOIN (SELECT license_payment_header_id, SUM(amount) as line_amount FROM license_payment_line GROUP BY license_payment_header_id) lpl
		ON license_payment_header.license_payment_header_id = lpl.license_payment_header_id;

CREATE OR REPLACE FUNCTION generateLCSpayments(keyfield IN varchar2, user_id IN varchar2, approval IN varchar2, period_id IN varchar2) RETURN varchar2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;

	TYPE RECORD IS REF CURSOR;
    reca 			RECORD;
    recb	 		RECORD;
    recc	 		RECORD;

	pay_header_id	integer;

	periodid		integer;
	pcid			integer;
	plid			integer;
	ppid			integer;

	blicense_id		integer;
	a_fee			real;
	aaa_fee			real;

	prev_fee		real;

BEGIN

	IF(approval = 'SELECT')  THEN
		RETURN 'NO OPTION SELECTED';
	
	ELSIF (approval = 'NEWPERIOD') THEN
		FOR reca IN
			(SELECT client.client_id
			FROM Client Inner Join Client_License On Client.Client_Id = Client_License.Client_Id
			INNER JOIN license on license.license_id = Client_License.license_id
			WHERE (Client.Is_Active = '1') And (Client_License.Is_Active = '1') AND (license.department_id = 4)
			GROUP BY Client.Client_Id)
		LOOP
			BEGIN
				SELECT period_client_id INTO pcid
				FROM period_client 
				WHERE (period_id = keyfield) AND (client_id = reca.client_id);
				EXCEPTION WHEN NO_DATA_FOUND THEN pcid := null;
			END;

			IF(pcid is null)THEN
				INSERT INTO period_client (period_id, client_id)
				VALUES (keyfield, reca.client_id);
				COMMIT;
			END IF;

			FOR recb IN
				(SELECT license.license_id, client_license.client_license_id
				FROM client_license INNER JOIN license ON license.license_id = client_license.license_id
				WHERE (client_license.client_id = reca.client_id) And (client_license.is_active = '1') AND (license.department_id = 4))
			LOOP
				BEGIN
					SELECT client_license_id INTO plid
					FROM client_license 
					WHERE (period_id = keyfield) AND (client_license_id = recb.client_license_id);
					EXCEPTION WHEN NO_DATA_FOUND THEN plid := null;
				END;

				IF(plid is null)THEN
					INSERT INTO period_license (period_id, client_license_id)
					VALUES (keyfield, recb.client_license_id);
					COMMIT;
				END IF;
			END LOOP;
		END LOOP;
	ELSIF (approval = 'COPYRETURNS') THEN
		BEGIN
			SELECT max(period_id) INTO ppid
			FROM period
			WHERE (period_id != keyfield);
			EXCEPTION WHEN NO_DATA_FOUND THEN ppid := null;
		END;
		FOR recc IN
			(SELECT period_client.client_id, period_client.annual_gross, period_client.non_license_revenue
			FROM period_client
			WHERE (period_client.period_id = ppid) AND (period_client.annual_gross > 0))
		LOOP
			UPDATE period_client SET annual_gross = recc.annual_gross, non_license_revenue = recc.non_license_revenue, is_estimate = '1'
			WHERE (client_id = recc.client_id) AND (period_id = keyfield) AND (annual_gross = 0);
			COMMIT;
		END LOOP;
	ELSIF (approval = 'SENDNOTICE') THEN
		INSERT INTO sys_emailed (table_id, table_name, sys_email_id, created_by)
		SELECT period_client.period_client_id, 'PERIOD_CLIENT', 3, user_id
		FROM period_client
		WHERE (period_client.period_id = keyfield);
		COMMIT;
	ELSIF (approval = 'PAYMENTS') THEN
		FOR reca IN
			(SELECT client_id, period_client_id, bill_license_id, annual_fee, aaa_anual_fee
			FROM vw_period_client
			WHERE (period_id = keyfield) AND (is_billed = '0') AND (annual_fee > 0))
		LOOP
			SELECT license_payment_header_id_seq.nextval into pay_header_id from dual;

			INSERT INTO license_payment_header(license_payment_header_id, client_license_id, period_client_id, description) 
			VALUES(pay_header_id, reca.bill_license_id, reca.period_client_id, 'ANNUAL LICENSE FEE');
			COMMIT;
			IF(reca.annual_fee = reca.aaa_anual_fee) THEN						
				INSERT INTO license_payment_line(license_payment_header_id, product_code, description, amount) 
				VALUES(pay_header_id, '0FFE42C843354755BE24AD5969EDCB0A', 'Annual License Fee (KES)', reca.annual_fee);
				COMMIT;
			ELSE
				FOR recb IN
					(SELECT client_id, client_license_id, annual_fee
					FROM vw_client_license
					WHERE (client_id = reca.client_id) AND (is_license_active = '1'))
				LOOP
					INSERT INTO license_payment_line(license_payment_header_id, product_code, description, amount) 
					VALUES(pay_header_id, '0FFE42C843354755BE24AD5969EDCB0A', 'Annual License Fee (KES)', recb.annual_fee);
					COMMIT;
				END LOOP;
			END IF;

			UPDATE period_client SET is_billed = '1', annual_fee_due = reca.annual_fee
			WHERE period_client_id = reca.period_client_id;
			COMMIT;
		END LOOP;
	ELSIF (approval = 'CLIENTREPOST') THEN
		SELECT bill_license_id, annual_fee, aaa_anual_fee INTO blicense_id, a_fee, aaa_fee
		FROM vw_period_client
		WHERE (period_client_id = keyfield);

		BEGIN
			SELECT SUM(license_payment_line.amount) INTO prev_fee
			FROM license_payment_header INNER JOIN license_payment_line ON license_payment_header.license_payment_header_id = license_payment_line.license_payment_header_id
			WHERE (license_payment_header.period_client_id = keyfield);
			EXCEPTION WHEN NO_DATA_FOUND THEN prev_fee := 0;
		END;
		IF(prev_fee is null) THEN prev_fee := 0; END IF;

		IF(prev_fee != a_fee) AND (aaa_fee = a_fee) THEN
			SELECT license_payment_header_id_seq.nextval into pay_header_id from dual;

			INSERT INTO license_payment_header(license_payment_header_id, client_license_id, period_client_id, description) 
			VALUES(pay_header_id, blicense_id, keyfield, 'ANNUAL LICENSE FEE - ADDITIONAL');
			COMMIT;

			INSERT INTO license_payment_line(license_payment_header_id, product_code, description, amount) 
			VALUES(pay_header_id, '0FFE42C843354755BE24AD5969EDCB0A', 'Annual License Fee (KES)', (a_fee - prev_fee));
			COMMIT;
		END IF;
	END IF;

	RETURN 'License Invoiced Successfully';
END;
/


