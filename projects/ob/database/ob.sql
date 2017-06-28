ALTER TABLE fin_payment ADD (em_dc2_is_printed CHARACTER(1) DEFAULT 'N' NOT NULL);
ALTER TABLE ad_alert ADD (em_dc2_is_sent CHARACTER(1) DEFAULT 'N' NOT NULL);
ALTER TABLE c_year ADD (em_dc2_start_date DATE);
ALTER TABLE c_year ADD (em_dc2_end_date DATE);

CREATE TABLE dc_ledger (
	dc_ledger_id			CHARACTER VARYING(32) NOT NULL,
	ad_client_id			CHARACTER VARYING(32) NOT NULL,
	ad_org_id				CHARACTER VARYING(32) NOT NULL,
	isactive				CHARACTER(1) DEFAULT 'Y' NOT NULL,
	created					TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
	createdby				CHARACTER VARYING(32) NOT NULL,
	updated					TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
	updatedby				CHARACTER VARYING(32) NOT NULL,

	pf_number				CHARACTER VARYING(16),
	staff_name				CHARACTER VARYING(128),
	period_no				CHARACTER VARYING(16),
	ledger_no				CHARACTER VARYING(32),
	posting_date			TIMESTAMP, 
	payroll_account			CHARACTER VARYING(32),
	description				CHARACTER VARYING(240), 
	debit					NUMERIC(12, 2), 
	credit					NUMERIC(12, 2),

	CONSTRAINT dc_ledger_isactive CHECK (isactive = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])),
	CONSTRAINT dc_ledger_key PRIMARY KEY (dc_ledger_id),
	CONSTRAINT dc_ledger_ad_org FOREIGN KEY (AD_ORG_ID) REFERENCES AD_ORG (ad_org_id),
	CONSTRAINT dc_ledger_ad_client FOREIGN KEY (AD_CLIENT_ID) REFERENCES AD_CLIENT (ad_client_id)
);

CREATE TABLE dc_ledger (
	dc_ledger_id			CHARACTER VARYING(32) NOT NULL,
	ad_client_id			CHARACTER VARYING(32) NOT NULL,
	ad_org_id				CHARACTER VARYING(32) NOT NULL,
	isactive				CHARACTER(1) DEFAULT 'Y' NOT NULL,
	created					DATE DEFAULT SYSDATE NOT NULL,
	createdby				CHARACTER VARYING(32) NOT NULL,
	updated					DATE DEFAULT SYSDATE NOT NULL,
	updatedby				CHARACTER VARYING(32) NOT NULL,

	pf_number				CHARACTER VARYING(16),
	staff_name				CHARACTER VARYING(128),
	period_no				CHARACTER VARYING(16),
	ledger_no				CHARACTER VARYING(16),
	posting_date			DATE, 
	payroll_account			CHARACTER VARYING(16),
	description				CHARACTER VARYING(240), 
	debit					NUMERIC(12, 2), 
	credit					NUMERIC(12, 2),

	CONSTRAINT dc_ledger_isactive CHECK (ISACTIVE IN ('Y', 'N')),
	CONSTRAINT dc_ledger_key PRIMARY KEY (dc_ledger_id),
	CONSTRAINT dc_ledger_ad_org FOREIGN KEY (AD_ORG_ID) REFERENCES AD_ORG (ad_org_id),
	CONSTRAINT dc_ledger_ad_client FOREIGN KEY (AD_CLIENT_ID) REFERENCES AD_CLIENT (ad_client_id)
);

CREATE OR REPLACE TRIGGER DC_ledger_TRG BEFORE INSERT ON dc_ledger FOR EACH ROW
DECLARE

	TYPE RECORD IS REF CURSOR;
    reca 		RECORD;

	post_date	DATE;
	acctschema	varchar(32);
	partnerid	varchar(32);
	pid			varchar(32);
	glbid		varchar(32);
	glid		varchar(32);
	cvid		varchar(32);
	lgid		varchar(32);
	pdesc		varchar(320);
	lnno		INTEGER;
BEGIN
 
    IF AD_isTriggerEnabled()='N' THEN RETURN;
    END IF;

	:NEW.dc_ledger_id := get_uuid();
	:NEW.staff_name := 'Test Staff';
	post_date := to_date('01-' || :NEW.period_no, 'DD-MON-YYYY');
	:NEW.posting_date := post_date;

	IF(:NEW.debit is null) THEN :NEW.debit := 0; END IF;
	IF(:NEW.credit is null) THEN :NEW.credit := 0; END IF;

	FOR reca IN
      (SELECT c_acctschema.c_acctschema_id, c_elementvalue.c_elementvalue_id, c_elementvalue.ad_client_id, c_elementvalue.ad_org_id, 
		 c_elementvalue.createdby, c_elementvalue.updatedby
		FROM c_acctschema INNER JOIN c_elementvalue ON c_acctschema.ad_org_id = c_elementvalue.ad_org_id
		WHERE (c_elementvalue.value = :NEW.payroll_account) AND (c_elementvalue.ad_org_id = 'E3F7A3865F594647A5594F01E4CCC9C6'))
    LOOP
		acctschema := reca.c_acctschema_id;
		:NEW.ad_client_id := reca.ad_client_id;
		:NEW.ad_org_id := reca.ad_org_id;
		:NEW.createdby := reca.createdby;
		:NEW.updatedby := reca.updatedby;
	END LOOP;

	BEGIN
		SELECT max(c_period_id) INTO pid 
		FROM c_period
		WHERE (startdate <= post_date) AND (enddate >= post_date) AND (ad_org_id = :NEW.ad_org_id);
		EXCEPTION WHEN NO_DATA_FOUND THEN pid := null;
	END;

	BEGIN
		SELECT max(C_BPARTNER_ID) INTO partnerid 
		FROM C_BPARTNER
		WHERE (VALUE = :NEW.pf_number) AND (ad_org_id = :NEW.ad_org_id);
		EXCEPTION WHEN NO_DATA_FOUND THEN partnerid := null;
	END;

	BEGIN
		SELECT max(gl_journalbatch_id) INTO glbid 
		FROM gl_journalbatch 
		WHERE (documentno = :NEW.period_no) AND (ad_org_id = :NEW.ad_org_id);
		EXCEPTION WHEN NO_DATA_FOUND THEN glbid := null;
	END;

	BEGIN
		SELECT max(gl_journal_id) INTO glid 
		FROM gl_journal 
		WHERE (documentno = :NEW.period_no) AND (ad_org_id = :NEW.ad_org_id);
		EXCEPTION WHEN NO_DATA_FOUND THEN glid := null;
	END;

	BEGIN
		SELECT max(c_validcombination_id) INTO cvid
		FROM c_validcombination
		WHERE (alias = :NEW.payroll_account) AND (ad_org_id = :NEW.ad_org_id);
		EXCEPTION WHEN NO_DATA_FOUND THEN cvid := null;
	END;

	IF (glbid is null) THEN
		glbid := get_uuid();
		glid := get_uuid();
		pdesc := 'Payroll Posting for ' || to_char(:NEW.posting_date, 'MON YYYY');
		INSERT INTO gl_journalbatch (gl_journalbatch_id, ad_client_id, ad_org_id, createdby, updatedby, documentno, 
			description, postingtype, gl_category_id, datedoc, dateacct, c_period_id, c_currency_id)
		VALUES(glbid, :NEW.ad_client_id, :NEW.ad_org_id, :NEW.createdby, :NEW.updatedby, :NEW.period_no,
			pdesc, 'A', 'FC670B83E59C4E7CBD6B999D3F28B251', :NEW.posting_date, :NEW.posting_date, pid, '266');

		INSERT INTO gl_journal(gl_journal_id, ad_client_id, ad_org_id, createdby, updatedby, c_acctschema_id, c_doctype_id, documentno, 
			docstatus, docaction, description, postingtype, gl_category_id, datedoc, dateacct, c_period_id, c_currency_id, 
			currencyratetype, currencyrate, gl_journalbatch_id, processing)
		VALUES(glid, :NEW.ad_client_id, :NEW.ad_org_id, :NEW.createdby, :NEW.updatedby, acctschema, '51005B2C07EB41C5A2E7C25A4640ACD7', :NEW.period_no,
			'DR', 'CO', pdesc, 'A', 'FC670B83E59C4E7CBD6B999D3F28B251', :NEW.posting_date, :NEW.posting_date, pid, '266',
			'S', 1, glbid, 'N');

		lnno := 10;
	ELSE
		BEGIN
			SELECT max(line) INTO lnno
			FROM gl_journalline
			WHERE (gl_journal_id = glid);
			EXCEPTION WHEN NO_DATA_FOUND THEN lnno := 10;
		END;
	END IF;
	
	BEGIN
		SELECT max(gl_journalline_id) INTO lgid
		FROM gl_journalline
		WHERE (gl_journalline_id = :NEW.dc_ledger_id);
		EXCEPTION WHEN NO_DATA_FOUND THEN lnno := 10;
	END;

	IF (lgid is null) THEN
		INSERT INTO gl_journalline (gl_journalline_id, ad_client_id, ad_org_id, createdby, updatedby, gl_journal_id,
			line, description, amtsourcedr, amtsourcecr, c_currency_id, currencyratetype, currencyrate,
			dateacct, amtacctdr, amtacctcr, c_uom_id, qty, c_validcombination_id, C_BPARTNER_ID)
		VALUES(:NEW.dc_ledger_id, :NEW.ad_client_id, :NEW.ad_org_id, :NEW.createdby, :NEW.updatedby, glid,
			lnno, :NEW.description, :NEW.debit, :NEW.credit, '266', 'S', 1, 
			:NEW.posting_date, :NEW.debit, :NEW.credit, '100', 0, cvid, partnerid);
	END IF;

END DC_ledger_TRG;
/

create or replace FUNCTION dc_get_alert_email(arule IN varchar2) RETURN varchar2 AS 
	TYPE RECORD IS REF CURSOR;

    myrec	RECORD;
	myemail	varchar(320);
BEGIN
	myemail := null;
	FOR myrec IN 
		(SELECT ad_user.email
		FROM ad_user INNER JOIN ad_user_roles ON ad_user.ad_user_id = ad_user_roles.ad_user_id
			INNER JOIN ad_alertrecipient ON ad_user_roles.ad_role_id = ad_alertrecipient.ad_role_id
		WHERE (ad_user.email is not null) AND (ad_alertrecipient.ad_alertrule_id = arule)) 
	LOOP

		IF (myemail is null) THEN
			myemail := myrec.email;
		ELSE
			myemail := myemail || ', ' || myrec.email;
		END IF;

	END LOOP;

	RETURN myemail;
END;

CREATE OR REPLACE FUNCTION dc_emailed(usrid IN integer, adAlert IN varchar2) RETURN varchar2 AS
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    UPDATE ad_alert SET em_dc2_is_sent = 'Y' WHERE (ad_alert_id = adAlert);
	COMMIT;

	RETURN 'DONE';
END;
/

CREATE VIEW dc_alerts_v AS
	SELECT ad_alertrule.ad_alertrule_id, ad_alertrule.name, 
		ad_alert.ad_alert_id, ad_alert.description, ad_alert.status, ad_alert.em_dc2_is_sent
	FROM ad_alertrule INNER JOIN ad_alert ON ad_alertrule.ad_alertrule_id = ad_alert.ad_alertrule_id;

CREATE OR REPLACE FUNCTION dc_get_budget(orgid IN varchar2, productid IN varchar2, dateyear IN date) RETURN NUMERIC 
AS 
	v_t_amount NUMBER;
BEGIN
	SELECT SUM(C_BUDGETLINE.AMOUNT) INTO v_t_amount
	FROM C_BUDGET INNER JOIN C_BUDGETLINE ON C_BUDGET.C_BUDGET_ID = C_BUDGETLINE.C_BUDGET_ID
		INNER JOIN C_YEAR ON C_YEAR.C_YEAR_ID = C_BUDGET.C_YEAR_ID
	WHERE (EM_CM_SUBMIT4 = 'Y') AND (C_BUDGET.AD_ORG_ID = orgid) AND (C_BUDGETLINE.M_PRODUCT_ID = productid)
		AND (C_YEAR.EM_DC2_START_DATE <= dateyear) AND (C_YEAR.EM_DC2_END_DATE >= dateyear);

	IF(v_t_amount is null) THEN v_t_amount := 0; END IF;

	RETURN v_t_amount;
END;
/

CREATE OR REPLACE FUNCTION dc_get_expense(orgid IN varchar2, productid IN varchar2, dateyear IN date) RETURN NUMERIC 
AS
	v_t_amount NUMBER;
BEGIN
	SELECT SUM(C_ORDERLINE.LINENETAMT + COALESCE(C_ORDERLINE.TAXBASEAMT, 0)) INTO v_t_amount
	FROM C_ORDER INNER JOIN C_ORDERLINE ON C_ORDER.C_ORDER_ID = C_ORDERLINE.C_ORDER_ID
		INNER JOIN M_REQUISITIONORDER ON C_ORDERLINE.C_ORDERLINE_ID = M_REQUISITIONORDER.C_ORDERLINE_ID
		INNER JOIN M_REQUISITIONLINE ON M_REQUISITIONORDER.M_REQUISITIONLINE_ID = M_REQUISITIONLINE.M_REQUISITIONLINE_ID
		INNER JOIN C_YEAR ON C_YEAR.AD_CLIENT_ID = C_ORDER.AD_CLIENT_ID
	WHERE (C_ORDER.DATEACCT >= C_YEAR.EM_DC2_START_DATE) AND (C_ORDER.DATEACCT <= C_YEAR.EM_DC2_END_DATE)
		AND (C_ORDERLINE.AD_ORG_ID = orgid) AND (C_ORDERLINE.M_PRODUCT_ID = productid)
		AND (C_YEAR.EM_DC2_START_DATE <= dateyear) AND (C_YEAR.EM_DC2_END_DATE >= dateyear);

	IF(v_t_amount is null) THEN v_t_amount := 0; END IF;

	RETURN v_t_amount;
END;
/


