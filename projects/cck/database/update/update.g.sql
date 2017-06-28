

CREATE TABLE license_inspection (
	license_inspection_id		NUMBER(*,0) primary key,
    client_inspection_id	  	NUMBER(*,0),
	client_license_id			NUMBER(*,0),
	is_compliant				CHAR(1 BYTE) DEFAULT '0' not null,
	details						clob,
	FOREIGN KEY (client_inspection_id) REFERENCES client_inspection (client_inspection_id),
	FOREIGN KEY (client_license_id) REFERENCES client_license (client_license_id),
	UNIQUE(client_inspection_id, client_license_id)
); 
CREATE SEQUENCE license_inspection_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_license_inspection_id BEFORE INSERT ON license_inspection FOR EACH row BEGIN 
	IF inserting THEN 
		IF :NEW.license_inspection_id IS NULL THEN
			SELECT license_inspection_id_seq.nextval INTO :NEW.license_inspection_id FROM dual;
		END IF;
	END IF;
END;
/

CREATE TABLE previous_inspection (
	previous_inspection_id		NUMBER(*,0) primary key,
	installation_id				NUMBER(*,0),
    sub_schedule_id			  	NUMBER(*,0),
	workflow_table_id			NUMBER(*,0),
	is_workflow_complete		CHAR(1),
	change_date					date default SYSDATE
); 
CREATE SEQUENCE previous_inspection_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_previous_inspection_id BEFORE INSERT ON previous_inspection FOR EACH row BEGIN 
	IF inserting THEN 
		IF :NEW.previous_inspection_id IS NULL THEN
			SELECT previous_inspection_id_seq.nextval INTO :NEW.previous_inspection_id FROM dual;
		END IF;
	END IF;
END;
/

CREATE OR REPLACE VIEW vw_license_inspection AS
	SELECT vw_client_license.client_license_id, vw_client_license.client_id, vw_client_license.client_name, 
		vw_client_license.license_name,
		license_inspection.license_inspection_id, license_inspection.client_inspection_id,
		license_inspection.is_compliant, license_inspection.details		
	FROM license_inspection INNER JOIN vw_client_license ON license_inspection.client_license_id = vw_client_license.client_license_id;


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
		period_license.qreturn_number,
		period_license.is_q1_received,
		period_license.is_q2_received,
		period_license.is_q3_received,
		period_license.is_q4_received,
		period_license.is_ret_compliant_so_far,
		period_license.is_compliant,
		period.period_id,
		period.period_name,
		period.start_date,
		period.return_deadline,
		add_months(period.start_date, (period_license.qreturn_number * 3)) as return_for,
		client_license.client_license_id,
		client_license.license_number,
		client_license.is_active as is_license_active,
		client_license.secretariat_remarks,
		client_license.remarks,
		client_license.details,
		client.client_id,
		client.client_name,
		client.id_number,
		client.pin,
		client.postal_code,
		client.town,
		client.address,
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

CREATE OR REPLACE FORCE VIEW vw_aaa_client AS
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
		client.end_year_month,
		to_char(to_date('01-' || lpad(client.end_year_month, 2, '0') || '-2012', 'DD-MM-YYYY'), 'Month') as end_year_month_name,
		(CASE WHEN client.end_year_month < EXTRACT(MONTH FROM sysdate) THEN 
			to_date('01-' || lpad(client.end_year_month, 2, '0') || '-' || EXTRACT(YEAR FROM sysdate), 'DD-MM-YYYY') 
		ELSE
			to_date('01-' || lpad(client.end_year_month, 2, '0') || '-' || EXTRACT(YEAR FROM add_months(sysdate, - 12)) , 'DD-MM-YYYY') 
		END) as end_year,
		(client.client_name || ' <br>P.o. Box: ' || client.address || ' <br>Email: ' || client.email || ' <br>Tel: ' 
			|| client.tel_no || ' <br>Mobile: ' || client.mobile_num || ' <br>Website: ' || client.website) AS client_detail,
		COALESCE(cl.lic_count, 0) as lic_count,
		COALESCE(pc.pc_return, to_date('01-JAN-2010')) as pc_return
	FROM client 
		LEFT JOIN (SELECT client_license.client_id, count(client_license.client_license_id) as lic_count 
			FROM client_license INNER JOIN license ON client_license.license_id = license.license_id
			WHERE (client_license.is_active = '1') and (license.department_id = 4) GROUP BY client_license.client_id) cl
			ON client.client_id = cl.client_id
		LEFT JOIN (SELECT client_id, max(return_date) as pc_return  FROM period_client WHERE is_aaa_compliant = '1' GROUP BY client_id) pc
			ON client.client_id = pc.client_id;


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
	notice.deadline_days,
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
    notice.appr_notice,
    notice.appr_penalty,
    notice.appr_revocation,
    notice.details,
	(notice.notice_date + (notice.deadline_months * 30 + notice.deadline_days)) as notice_deadline,
	(CASE WHEN vw_client_inspection.client_inspection_id is null THEN '0' ELSE '1' END) AS has_inspection,
    COALESCE(vw_client_inspection.client_id, vw_period_license.client_id, vw_period_client.client_id) AS client_id,
    COALESCE(vw_client_inspection.client_name, vw_period_license.client_name, vw_period_client.client_name) AS client_name,
	COALESCE(vw_period_license.license_name, 'INSPECTION') AS license_name,
	COALESCE(vw_period_license.client_license_id, vw_client_inspection.Client_License_Id, vw_period_client.bill_license_id) AS bill_license_id
  FROM notice LEFT JOIN vw_client_inspection ON notice.client_inspection_id = vw_client_inspection.client_inspection_id
	LEFT JOIN vw_period_license ON notice.period_license_id = vw_period_license.period_license_id
	LEFT JOIN vw_period_client ON notice.period_client_id = vw_period_client.period_client_id;

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
    equipment_approval.is_rejected, 
    equipment_approval.rejection_date,
    equipment_approval.is_cleared,
    equipment_approval.cleared_date,
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

CREATE OR REPLACE VIEW vw_numbers AS
	SELECT number_type.number_type_id, number_type.number_type_name, client.client_id, client.client_name,
		numbers.number_id, numbers.num_series, numbers.start_range, numbers.end_range,
		numbers.capacity, numbers.assignment, numbers.assign_date, numbers.active_date,
		numbers.number_usage, numbers.client_license_id, numbers.details,
		(CASE WHEN numbers.capacity IS NULL THEN 100 WHEN numbers.capacity = 0 THEN 100
		ELSE 100 * numbers.number_usage / numbers.capacity END) as r_usage
	FROM number_type INNER JOIN numbers ON number_type.number_type_id = numbers.number_type_id
		LEFT JOIN client ON numbers.client_id = client.client_id;

CREATE OR REPLACE VIEW vw_installation AS
	SELECT client.client_id, client.client_name as contractor_name, client_license.client_license_id,
		license.license_id, license.license_name,
		installation.installation_id, installation.project_contractor, installation.install_date, 
		installation.installation_type, installation.is_approved, installation.is_rejected,
		installation.client_name, installation.postal_address, installation.physical_address,
		installation.install_town, installation.install_road, installation.install_lrno,
		installation.equipment_make, installation.equipment_model, installation.findings,
		installation.is_completed, installation.completion_date, installation.sub_schedule_id,
		installation.workflow_table_id, installation.is_workflow_complete, installation.rejection_date,
		('<a href=' || installation.checklist_url || ' _blank=yes>Report</a>') as report_url,
		('P.o. Box: '||installation.postal_address || ' ' || installation.physical_address) as client_address
	FROM installation INNER JOIN client_license ON installation.client_license_id = client_license.client_license_id
		INNER JOIN client ON client_license.client_id = client.client_id
		INNER JOIN license ON client_license.license_id = license.license_id
		INNER JOIN license_type ON license.license_type_id = license_type.license_type_id;


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
		lpl.line_amount,
		period_client.period_id
	FROM license_payment_header INNER JOIN client_license ON license_payment_header.client_license_id = client_license.client_license_id
		INNER JOIN client ON client_license.client_id = client.client_id
		INNER JOIN license ON Client_License.License_Id = License.License_Id
		LEFT JOIN license_type ON license.license_type_id = license_type.license_type_id
		INNER JOIN (SELECT license_payment_header_id, SUM(amount) as line_amount FROM license_payment_line GROUP BY license_payment_header_id) lpl
			ON license_payment_header.license_payment_header_id = lpl.license_payment_header_id
		LEFT JOIN period_client ON license_payment_header.period_client_id = period_client.period_client_id;

CREATE OR REPLACE FUNCTION getLicenseNumber(cli_lic_id IN integer) RETURN varchar2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;

	licno			varchar2(120);

	yyy				char(3);			--for use by postal licenses
	lic_number 		int;
	
	clid			integer;
	licnum			integer;
	idnum			varchar(120);

	lictypeid		integer;
	licid			integer;
	licabbr			varchar(120);
BEGIN

	SELECT client.client_id, client.license_number, client.id_number, license.license_type_id, 
		license.license_id, license.license_abbrev
		INTO clid, licnum, idnum, lictypeid, licid, licabbr
	FROM client_license INNER JOIN license ON client_license.license_id = license.license_id
		INNER JOIN client ON client_license.client_id = client.client_id
	WHERE client_license.client_license_id = cli_lic_id;

	IF (lictypeid = 17) THEN
		SELECT TO_CHAR(sysdate,'YY') INTO yyy FROM dual;
		SELECT postal_license_seq.nextval INTO lic_number FROM dual ;

		licno := 'PL/' || yyy || '/' || lpad(lic_number, 4, '0');
    
		UPDATE client_license SET license_number = licno
		WHERE client_license_id = cli_lic_id;
		COMMIT;
	ELSIF (licid = 134) THEN	
		licno := 'TL/' || licabbr || '/' || idnum;

		UPDATE client_license SET license_number = licno
		WHERE client_license_id = cli_lic_id;
		COMMIT;
	ELSE
		IF(licnum IS NULL) THEN
			SELECT telecom_license_seq.nextval INTO licnum FROM dual;

			UPDATE client SET license_number = licnum 
			WHERE client_id = clid;
			COMMIT;
		END IF;
		
		licno := 'TL/' || licabbr || '/' || licnum;

		UPDATE client_license SET license_number = licno
		WHERE client_license_id = cli_lic_id;
		COMMIT;
	END IF;
 
	RETURN licno;
END;
/

CREATE OR REPLACE FUNCTION processLicense(keyfield IN varchar2, user_id IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN varchar2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;

	licno			varchar2(120);

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

		licno := getLicenseNumber(CAST(keyfield AS int));

		IF(pclientid is null)THEN
			INSERT INTO period_client(period_id, client_id) 
			VALUES(periodid, clientid);
			COMMIT;
		END IF;
	
		INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type) VALUES (71, tab_id, 'PERIOD_LICENSE', 50);		
		COMMIT;
		
		RETURN 'License Activated and Email Sent';

	ELSIF approval='ROLLOUT' THEN
		UPDATE client_license SET is_rolled_out='1', rollout_date = SYSDATE
		WHERE client_license_id = CAST(keyfield AS int);
		COMMIT;

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

create or replace FUNCTION submitreturns(myval1 IN varchar2, myval2 IN varchar2, myval3 IN varchar2, myval4 IN varchar2) RETURN VARCHAR2 IS
	PRAGMA 	AUTONOMOUS_TRANSACTION;
	
	cdd		integer;
	tdd 	varchar2(120);
BEGIN

	IF(myval3 = 'Quarter1')  THEN
		UPDATE period_license
		SET IS_Q1_RECEIVED = '1', Q1_RECEIVED_DATE = SYSDATE, UPDATED_BY = CAST(myval2 as int), UPDATED_DATE = SYSDATE
		WHERE period_license_id = CAST(myval1 as int);
		COMMIT;

		UPDATE period_license SET qreturn_number = 1
		WHERE (period_license_id = CAST(myval1 as int)) AND (qreturn_number < 1);
		COMMIT;
	END IF;
	IF(myval3 = 'Quarter2')  THEN
		UPDATE period_license 
		SET IS_Q2_RECEIVED = '1', Q2_RECEIVED_DATE = SYSDATE, UPDATED_BY = CAST(myval2 as int), UPDATED_DATE = SYSDATE
		WHERE period_license_id = CAST(myval1 as int);
		COMMIT;

		UPDATE period_license SET qreturn_number = 2
		WHERE (period_license_id = CAST(myval1 as int)) AND (qreturn_number < 2);
		COMMIT;
	END IF;
	IF(myval3 = 'Quarter3')  THEN
		UPDATE period_license 
		SET IS_Q3_RECEIVED = '1', Q3_RECEIVED_DATE = SYSDATE, UPDATED_BY = CAST(myval2 as int), UPDATED_DATE = SYSDATE
		WHERE period_license_id = CAST(myval1 as int);
		COMMIT;

		UPDATE period_license SET qreturn_number = 3
		WHERE (period_license_id = CAST(myval1 as int)) AND (qreturn_number < 3);
		COMMIT;
	END IF;
	IF(myval3 = 'Quarter4')  THEN
		UPDATE period_license 
		SET IS_Q4_RECEIVED = '1', Q4_RECEIVED_DATE = SYSDATE, UPDATED_BY = CAST(myval2 as int), UPDATED_DATE = SYSDATE
		WHERE period_license_id = CAST(myval1 as int);
		COMMIT;

		UPDATE period_license SET qreturn_number = 4
		WHERE (period_license_id = CAST(myval1 as int)) AND (qreturn_number < 4);
		COMMIT;
	END IF;
  
	IF(myval3 = 'Annual')  THEN
		UPDATE period_license 
		SET IS_ANUAL_RETURNS_RECEIVED = '1', ANNUAL_RETURNS_RECEIVED_DATE  = SYSDATE, UPDATED_BY = CAST(myval2 as int), UPDATED_DATE = SYSDATE
		WHERE period_license_id = CAST(myval1 as int);
		COMMIT;
	END IF;

	IF(myval3 = 'AR Compliant')  THEN
		SELECT return_deadline - return_for INTO cdd
		FROM vw_period_license
		WHERE period_license_id = CAST(myval1 as int);

		IF(cdd < 0)THEN
			UPDATE period_license 
			SET is_ret_compliant_so_far = '1', UPDATED_BY = CAST(myval2 as int), UPDATED_DATE = SYSDATE
			WHERE period_license_id = CAST(myval1 as int);
			COMMIT;
		ELSE
			RETURN 'Returns have not been done yet.';
		END IF;
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

	IF(myval3 = 'Full Compliant')  THEN
		UPDATE period_license
		SET IS_COMPLIANT = '1', UPDATED_BY = CAST(myval2 as int), UPDATED_DATE = SYSDATE
		WHERE period_license_id = CAST(myval1 as int);
		COMMIT;
	END IF;

	SELECT upd_compliance(vw_period_license.client_id) INTO tdd
	FROM vw_period_license 
	WHERE period_license_id = CAST(myval1 as int);
	
	RETURN 'complete';
END;
/

create or replace FUNCTION add_license_inspection(myval1 IN varchar2, myval2 IN varchar2, myval3 IN varchar2, myval4 IN varchar2) RETURN VARCHAR2 IS
	PRAGMA 	AUTONOMOUS_TRANSACTION;
	
	liid		integer;
BEGIN

	BEGIN
		SELECT license_inspection_id INTO liid
		FROM license_inspection
		WHERE (client_license_id = CAST(myval1 as int)) AND (client_inspection_id = CAST(myval4 as int));
		EXCEPTION WHEN NO_DATA_FOUND THEN liid := null;
	END;

	if	(liid is null) then
		INSERT INTO license_inspection (client_license_id, client_inspection_id)
		VALUES (CAST(myval1 as int), CAST(myval4 as int));
		COMMIT;
	end if;
	
	RETURN 'complete';
END;
/ 


CREATE OR REPLACE FUNCTION lic_deactivate(keyfield IN varchar2, user_id IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN varchar2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;

	TYPE RECORD IS REF CURSOR;
    reca 		RECORD;

	clid		integer;
	ciid		integer;
	pcid		integer;
BEGIN	
  
	IF approval='ACTIVATE' THEN 
		UPDATE client_license SET status_license_id = 3, is_active='1' WHERE client_license_id = CAST(keyfield AS int);
		COMMIT;
		RETURN 'License Activated and Email Sent';
	ELSIF approval='DEACTIVATE' THEN
		UPDATE client_license SET is_active='0' WHERE client_license_id = CAST(keyfield AS int);
		COMMIT;
		RETURN 'License Deactivated';
	ELSIF approval='NOTICEDEACTIVATE' THEN
		SELECT client_license_id, client_inspection_id, period_client_id
		INTO clid, ciid, pcid
		FROM notice WHERE notice_id = CAST(keyfield AS int);

		IF(clid is not null)THEN
			UPDATE client_license SET status_license_id = 8, is_active='0', revocation_date = SYSDATE, revoked_by = CAST(user_id as integer)
			WHERE client_license_id = clid;
			COMMIT;
		ELSIF (ciid is not null) THEN
			FOR reca IN
				(SELECT client_license_id FROM license_inspection WHERE client_inspection_id = ciid)
			LOOP
				UPDATE client_license SET status_license_id = 8, is_active='0', revocation_date = SYSDATE, revoked_by = CAST(user_id as integer)
				WHERE client_license_id = reca.client_license_id;
				COMMIT;
			END LOOP;
		ELSIF (pcid is not null) THEN
			FOR reca IN
				(SELECT client_license_id FROM client_license 
				WHERE client_id IN (SELECT client_id FROM period_client WHERE period_client_id = pcid))
			LOOP
				UPDATE client_license SET status_license_id = 8, is_active='0', revocation_date = SYSDATE, revoked_by = CAST(user_id as integer)
				WHERE client_license_id = reca.client_license_id;
				COMMIT;
			END LOOP;
		END IF;


		RETURN 'License Deactivated';
	END IF;
END;
/


create or replace FUNCTION ta_provisional(keyfield IN varchar2, user_id IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN varchar2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
    tab_id    integer;
BEGIN	

	IF approval='Provisional' THEN 
		UPDATE equipment_approval SET is_provisional = '1', provisional_date = SYSDATE
		WHERE equipment_approval_id = CAST(keyfield AS int);
		COMMIT;
	ELSIF approval='Rejected' THEN
		UPDATE equipment_approval SET Is_Rejected = '1', rejection_date = SYSDATE
		WHERE equipment_approval_id = CAST(keyfield AS int);
		COMMIT;
	ELSIF approval='Clearance' THEN
		UPDATE equipment_approval SET is_cleared = '1', cleared_date = SYSDATE
		WHERE equipment_approval_id = CAST(keyfield AS int);
		COMMIT;
	END IF;

	RETURN 'Provional letter generated';
END;
/

create or replace FUNCTION ta_approved(keyfield IN varchar2, user_id IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN varchar2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
    tab_id    integer;
BEGIN	
  
	IF approval='Activate' THEN 
		UPDATE equipment_approval SET is_ta_approved = '1'
		WHERE equipment_approval_id = CAST(keyfield AS int);
		COMMIT;

		UPDATE client_license SET certification_date = SYSDATE, is_active = '1'
		WHERE client_license_id 
			IN (SELECT client_license_id FROM equipment_approval WHERE equipment_approval_id = CAST(keyfield AS int));
		COMMIT;
	ELSIF approval='Rejected' THEN
		UPDATE equipment_approval SET Is_Rejected = '1', rejection_date = SYSDATE
		WHERE equipment_approval_id = CAST(keyfield AS int);
		COMMIT;
	END IF;

	RETURN 'Provional letter generated';
END;
/

create or replace FUNCTION alloc_numbers(keyfield IN varchar2, user_id IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN varchar2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;

    tab_id    	integer;
	clid		integer;
BEGIN	
  
	IF(approval = 'SELECT') THEN
		RETURN 'No Action Selected';

	ELSIF approval='ASSIGN' THEN
		UPDATE numbers SET assign_date = SYSDATE WHERE number_id = CAST(keyfield AS int);
		COMMIT;      
		
		RETURN 'License Activated and Email Sent';
	ELSIF approval='DEASSIGN' THEN
		UPDATE numbers SET client_license_id = null, client_id = null, assign_date = null 
		WHERE number_id = CAST(keyfield AS int);
		COMMIT;

		RETURN 'License Deactivated';
	ELSIF approval='LICASSIGN' THEN
		SELECT client_id INTO clid
		FROM client_license WHERE client_license_id = CAST(keyfield AS int);

		UPDATE numbers SET client_license_id = CAST(keyfield AS int), client_id = clid, assign_date = SYSDATE 
		WHERE number_id = CAST(filter_id AS int);
		COMMIT;

		RETURN 'License Deactivated';
	ELSE
		RETURN 'UNREACHABLE';
	END IF;
END;
/

create or replace FUNCTION processInstallation(keyfield IN varchar2, user_id IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;

	createby		INTEGER;
	wfid 			INTEGER;
	apprid			INTEGER;
	appr_group		INTEGER;
	clientname		VARCHAR(120);
	tasktype		VARCHAR(120);
	wf_type 		VARCHAR2(64);
BEGIN
	IF(approval = 'SELECT')  THEN
		RETURN 'NO OPTION SELECTED';
	ELSIF(approval = 'Approved')  THEN
		UPDATE installation SET is_approved = '1',is_rejected='0' 
		WHERE installation_id = CAST(keyfield as int);
		COMMIT;
		RETURN approval;
	ELSIF(approval = 'Rejected')  THEN
		UPDATE installation SET is_approved = '0', is_rejected='1', rejection_date = SYSDATE 
		WHERE installation_id = CAST(keyfield as int);
		COMMIT;
		RETURN approval;
	ELSIF(approval = 'ReInspection')  THEN
		wf_type := 'INSTALLATION'; 
		tasktype := 'Certification';

		SELECT seq_approval_group.nextval INTO appr_group FROM dual;
		SELECT workflow_table_id_seq.nextval into wfid from dual;

		INSERT INTO previous_inspection (installation_id, sub_schedule_id, workflow_table_id, is_workflow_complete)
		SELECT installation_id, sub_schedule_id, workflow_table_id, is_workflow_complete
		FROM installation WHERE installation_id = CAST(keyfield as int);
		COMMIT;

		SELECT client.client_name, installation.created_by INTO clientname, createby
		FROM client INNER JOIN client_license ON client.client_id = client_license.client_id
			INNER JOIN installation ON client_license.client_license_id = installation.client_license_id
		WHERE (installation.installation_id = CAST(keyfield as int));

		INSERT INTO approvals (workflow_phase_id, approval_group, table_name, table_id, org_entity_id, app_entity_id, escalation_days, escalation_hours, approval_level, approval_narrative, to_be_done, task_source, task_type)
		SELECT workflow_phases.workflow_phase_id, appr_group, wf_type, wfid, createby, entity_subscriptions.entity_id, 0, 3, 1, workflow_phases.phase_narrative, workflow_phases.phase_narrative, clientname, tasktype
		FROM workflow_phases
			INNER JOIN entity_subscriptions ON workflow_phases.approval_entity_id = entity_subscriptions.entity_type_id
			INNER JOIN workflows ON workflow_phases.workflow_id = workflows.workflow_id
		WHERE (workflows.table_name = wf_type) AND (workflow_phases.approval_level='1')
		ORDER BY workflow_phases.approval_level, workflow_phases.workflow_phase_id;
		COMMIT;
			
		INSERT INTO approval_checklists (checklist_id,workflow_table_id)
		SELECT checklist_id, wfid
		FROM checklists INNER JOIN workflow_phases ON checklists.workflow_phase_id = workflow_phases.workflow_phase_id
			INNER JOIN workflows ON workflow_phases.workflow_id = workflows.workflow_id
		WHERE (workflows.table_name = wf_type) AND (workflow_phases.approval_level = '1')
		ORDER BY workflow_phases.approval_level, workflow_phases.workflow_phase_id;
		COMMIT;
		
		UPDATE installation SET is_approved = '0', is_rejected='0', workflow_table_id = wfid, sub_schedule_id = null
		WHERE installation_id = CAST(keyfield as int);
		COMMIT;
		RETURN approval;
	END IF;
	
	RETURN 'UNREACHABLE';
END;
/

create or replace TRIGGER tr_notice_workflow AFTER UPDATE OR INSERT ON notice FOR EACH ROW 
DECLARE
	PRAGMA AUTONOMOUS_TRANSACTION;

	tdd				varchar2(120);

	wfid 			INTEGER;
	apprid			INTEGER;
	appr_group		INTEGER;

	clientid		INTEGER;
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
			SELECT client.client_id, client.client_name INTO clientid, clientname
			FROM client INNER JOIN client_license ON client.client_id = client_license.client_id
			WHERE (client_license.client_license_id = :NEW.client_license_id);
		END IF;
		IF(:NEW.client_inspection_id is not null) THEN
			SELECT client.client_id, client.client_name INTO clientid, clientname
			FROM client INNER JOIN client_inspection ON client.client_id = client_inspection.client_id
			WHERE (client_inspection_id = :NEW.client_inspection_id);
		END IF;
		IF(:NEW.period_client_id is not null) THEN
			SELECT client.client_id, client.client_name INTO clientid, clientname
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


create or replace FUNCTION qos_conditions(ctype IN varchar2, tvalue IN real, cvalue IN real) return varchar2 is
	iscomp		varchar2(2);
BEGIN
	iscomp := '0';
	if (ctype = '=') then
		if (cvalue = tvalue) then
			iscomp := '1';
		end if;
	end if;
	if (ctype = '>=') then
		if (cvalue >= tvalue) then
			iscomp := '1';
		end if;
	end if;
	if ctype = '<=' then
		if (cvalue <= tvalue) then
			iscomp := '1';
		end if;
	end if;

	return iscomp;	
END;
/

CREATE OR REPLACE VIEW vw_avg_qos_compliance AS
	SELECT qos_factor.qos_factor_id, qos_factor.qos_factor_name, qos_factor.target_operator, qos_factor.target_value,
		qos_compliance.period_license_id, avg(qos_compliance.actual_cck_value) as avg_cck_value, avg(qos_compliance.actual_client_value) as avg_client_value,
		qos_conditions(qos_factor.target_operator, qos_factor.target_value, avg(qos_compliance.actual_cck_value)) as qos_compliant
	FROM qos_compliance INNER JOIN qos_factor on qos_compliance.qos_factor_id = qos_factor.qos_factor_id
	GROUP BY qos_factor.qos_factor_id, qos_factor.qos_factor_name, qos_factor.target_operator, qos_factor.target_value,
		qos_compliance.qos_factor_id, qos_compliance.period_license_id;

create or replace FUNCTION upd_conditions(clins IN varchar2) return varchar2 is
	PRAGMA AUTONOMOUS_TRANSACTION;
	ciid 	integer;
	lcid 	integer;
	clid 	integer;
	iscom	char(1);
	tdd 	varchar2(120);
BEGIN

	SELECT upd_compliance(vw_lic_conditions_compliance.client_id) INTO tdd
	FROM vw_lic_conditions_compliance
	WHERE (lic_conditions_compliance_id = CAST(clins as INT));
	
	return tdd;	
END;
/

create or replace FUNCTION upd_compliance(clientid IN NUMBER) return varchar2 is
	PRAGMA AUTONOMOUS_TRANSACTION;

	TYPE RECORD IS REF CURSOR;
    reca 			RECORD;
    recb	 		RECORD;
	recc	 		RECORD;

	linsp			int;
	cinsp			int;
	insp			int;

	llcc			int;
	qosc			int;
	rtc				int;

	licc			int;
	notc			int;
	notl			int;
	ncpl			int;
	aaac			int;
BEGIN

	--- get the compliance for an inspection based on notice
	FOR reca IN
		(SELECT client_inspection_id
		FROM client_inspection
		WHERE (client_inspection.client_id = clientid))
	LOOP

		BEGIN
			SELECT count(notice.notice_id) INTO notc
			FROM notice 
			WHERE (notice.is_compliant = '0') AND (notice.client_inspection_id = reca.client_inspection_id);
			IF(notc is null)THEN notc := 0; END IF;
			EXCEPTION WHEN NO_DATA_FOUND THEN notc := 0;
		END;

		IF (notc > 0) THEN
			UPDATE client_inspection SET is_fully_compliant = '0' WHERE (client_inspection_id = reca.client_inspection_id);
			COMMIT;
		END IF;
	END LOOP;

	--- Check on the compliance status of the period license
	FOR recc IN
		(SELECT period_license.period_license_id, period.is_compliance,
			period.return_deadline,
			add_months(period.start_date, (period_license.qreturn_number * 3)) AS return_for
		FROM period_license INNER JOIN client_license ON period_license.client_license_id = client_license.client_license_id
			INNER JOIN period ON period_license.period_id = period.period_id
			INNER JOIN license ON license.license_id = client_license.license_id
		WHERE (client_license.is_active = '1') AND (license.department_id = 4) AND (client_license.client_id = clientid)) 
	LOOP

		BEGIN
			SELECT count(notice.notice_id) INTO notl
			FROM notice
			WHERE (notice.is_compliant = '0') AND (notice.period_license_id = recc.period_license_id);
			IF (notl is null) THEN notl := 0; END IF;
			EXCEPTION WHEN NO_DATA_FOUND THEN notl := 0;
		END;

		BEGIN
			SELECT count(lic_conditions_compliance_id) INTO llcc
			FROM lic_conditions_compliance
			WHERE (is_complied = '0') AND (period_license_id = recc.period_license_id);
			IF (llcc is null) THEN llcc := 0; END IF;
			EXCEPTION WHEN NO_DATA_FOUND THEN llcc := 0;
		END;

		qosc := 0;
		rtc := 0;
		IF(recc.is_compliance = '1')THEN
			BEGIN
				SELECT count(qos_factor_id) INTO qosc
				FROM vw_avg_qos_compliance
				WHERE (qos_compliant = '0') AND (period_license_id = recc.period_license_id);
				IF (qosc is null) THEN qosc := 0; END IF;
				EXCEPTION WHEN NO_DATA_FOUND THEN qosc := 0;
			END;

			IF(recc.return_deadline > recc.return_for)THEN
				rtc := 1;
			END IF;
		END IF;

		--- quartely returns compliance
		IF(recc.return_deadline > recc.return_for)THEN
			UPDATE period_license SET is_ret_compliant_so_far = '0' WHERE (period_license_id = recc.period_license_id);
			COMMIT;
		ELSE
			UPDATE period_license SET is_ret_compliant_so_far = '1' WHERE (period_license_id = recc.period_license_id);
			COMMIT;
		END IF;

		IF (notl = 0) AND (llcc = 0) AND (rtc = 0) AND (qosc < 2) THEN
			UPDATE period_license SET is_compliant = '1' WHERE (period_license_id = recc.period_license_id);
			COMMIT;
		ELSE
			UPDATE period_license SET is_compliant = '0' WHERE (period_license_id = recc.period_license_id);
			COMMIT;
		END IF;
	END LOOP;

	--- Check for the compliance status for the license
	FOR recb IN
		(SELECT client_license.client_license_id
		FROM client_license INNER JOIN license ON license.license_id = client_license.license_id
		WHERE (client_license.is_active = '1') AND (license.department_id = 4) AND (client_license.client_id = clientid))
	LOOP

		BEGIN
			SELECT count(period_license.period_license_id) INTO ncpl
			FROM period_license 
			WHERE (period_license.is_compliant = '0') AND (period_license.client_license_id = recb.client_license_id);
			IF(ncpl is null)THEN ncpl := 0; END IF;
			EXCEPTION WHEN NO_DATA_FOUND THEN ncpl := 0;
		END;

		BEGIN
			SELECT count(client_inspection.client_inspection_id) INTO linsp
			FROM client_inspection INNER JOIN license_inspection ON client_inspection.client_inspection_id = license_inspection.client_inspection_id
			WHERE (client_inspection.is_fully_compliant = '0') AND (license_inspection.client_license_id = recb.client_license_id);
			IF(linsp is null)THEN linsp := 0; END IF;
			EXCEPTION WHEN NO_DATA_FOUND THEN linsp := 0;
		END;

		BEGIN
			SELECT count(installation.installation_id) INTO cinsp
			FROM installation
			WHERE (installation.is_rejected = '1') AND (installation.client_license_id = recb.client_license_id);
			IF(cinsp is null)THEN cinsp := 0; END IF;
			EXCEPTION WHEN NO_DATA_FOUND THEN cinsp := 0;
		END;

		IF (ncpl = 0) AND (linsp = 0) AND (cinsp = 0) THEN
			UPDATE client_license SET is_compliant = '1' WHERE (client_license_id = recb.client_license_id);
			COMMIT;
		ELSE
			UPDATE client_license SET is_compliant = '0' WHERE (client_license_id = recb.client_license_id);
			COMMIT;
		END IF;
	END LOOP;

	BEGIN
		SELECT count(client_inspection_id) INTO insp
		FROM client_inspection 
		WHERE (is_fully_compliant = '0') AND (client_id = clientid);
		IF(insp is null)THEN insp := 0; END IF;
		EXCEPTION WHEN NO_DATA_FOUND THEN insp := 0;
	END;

	BEGIN
		SELECT count(client_license_id) INTO licc
		FROM client_license 
		WHERE (is_compliant = '0') AND (client_id = clientid);
		IF(licc is null)THEN licc := 0; END IF;
		EXCEPTION WHEN NO_DATA_FOUND THEN licc := 0;
	END;

	BEGIN
		SELECT count(period_client_id) INTO aaac
		FROM period_client 
		WHERE (is_aaa_compliant = '0') AND (client_id = clientid);
		IF(aaac is null)THEN aaac := 0; END IF;
		EXCEPTION WHEN NO_DATA_FOUND THEN aaac := 0;
	END;

	IF(insp = 0) AND (licc = 0) AND (aaac = 0) THEN
		UPDATE client SET compliant = '1' WHERE (client_id = clientid);
		COMMIT;
	ELSE
		UPDATE client SET compliant = '0' WHERE (client_id = clientid);
		COMMIT;
	END IF;

	return 'Done';	
END;
/

