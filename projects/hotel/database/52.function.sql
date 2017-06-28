CREATE OR REPLACE FUNCTION ins_bookings()
  RETURNS trigger AS
$BODY$
DECLARE
	myrec RECORD;
	raterec RECORD;
	servicerec RECORD;
BEGIN
	SELECT max(current_rate) as mcurrrenrate,service_type_id INTO raterec
	FROM room_rates
	WHERE (room_rate_id = NEW.room_rate_id)
		AND (date_start <= NEW.arrival_date) AND (date_end >= NEW.departure_date)
		GROUP BY service_type_id;

	SELECT max(tax_rate1) as mtax1, max(tax_rate2) as mtax2, max(tax_rate3) as mtax3 INTO servicerec
	FROM service_types
	WHERE service_type_id = raterec.service_type_id;

	IF (raterec.mcurrrenrate is not null) THEN
		NEW.book_rate = raterec.mcurrrenrate;
		NEW.tax1 = servicerec.mtax1;
		NEW.tax2 = servicerec.mtax2;
		NEW.tax3 = servicerec.mtax3;
		NEW.exchange_rate = get_currency_rate(NEW.org_id, NEW.currency_id);
	END IF;

	RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql;



    	CREATE OR REPLACE FUNCTION ins_subscriptions()
      RETURNS trigger AS
    $BODY$
    DECLARE
    	v_entity_id				integer;
    	v_entity_type_id		integer;
    	v_org_id				integer;
    	v_currency_id			integer;
    	v_department_id			integer;
    	v_bank_id				integer;
    	v_tax_type_id			integer;
    	v_workflow_id			integer;
    	v_org_suffix			char(2);
    	myrec 					RECORD;
    BEGIN

    	IF (TG_OP = 'INSERT') THEN
    		SELECT entity_id INTO v_entity_id
    		FROM entitys WHERE lower(trim(user_name)) = lower(trim(NEW.primary_email));

    		IF(v_entity_id is null)THEN
    			NEW.entity_id := nextval('entitys_entity_id_seq');
    			INSERT INTO entitys (entity_id, org_id, use_key_id, entity_type_id, entity_name, User_name, primary_email,  function_role, first_password)
    			VALUES (NEW.entity_id, 0, 5, 5, NEW.primary_contact, lower(trim(NEW.primary_email)), lower(trim(NEW.primary_email)), 'subscription', null);

    			INSERT INTO sys_emailed (sys_email_id, org_id, table_id, table_name)
    			VALUES (1, 0, NEW.entity_id, 'subscription');

    			NEW.approve_status := 'Completed';
    		ELSE
    			RAISE EXCEPTION 'You already have an account, login and request for services';
    		END IF;
    	ELSIF(NEW.approve_status = 'Approved')THEN

    		NEW.org_id := nextval('orgs_org_id_seq');
    		INSERT INTO orgs(org_id, currency_id, org_name, org_sufix, default_country_id, logo)
    		VALUES(NEW.org_id, 2, NEW.hotel_name,  NEW.org_id, NEW.country_id, 'logo.png');

    		INSERT INTO address (address_name, sys_country_id, table_name, table_id, premises, town, phone_number, website, is_default)
    		VALUES (NEW.hotel_name, NEW.country_id, 'orgs', NEW.org_id, NEW.hotel_address, NEW.city, NEW.telephone, NEW.website, true);

    		v_currency_id := nextval('currency_currency_id_seq');
    		INSERT INTO currency (org_id, currency_id, currency_name, currency_symbol) VALUES (NEW.org_id, v_currency_id, 'Default Currency', 'DC');
    		UPDATE orgs SET currency_id = v_currency_id WHERE org_id = NEW.org_id;

    		INSERT INTO currency_rates (org_id, currency_id, exchange_rate) VALUES (NEW.org_id, v_currency_id, 1);

    		INSERT INTO entity_types (org_id, entity_type_name, entity_role, use_key_id)
    		SELECT NEW.org_id, entity_type_name, entity_role, use_key_id
    		FROM entity_types WHERE org_id = 0;

    		INSERT INTO subscription_levels (org_id, subscription_level_name)
    		SELECT NEW.org_id, subscription_level_name
    		FROM subscription_levels WHERE org_id = 1;

    		INSERT INTO jobs_category (org_id, jobs_category)
    		SELECT NEW.org_id, jobs_category
    		FROM jobs_category WHERE org_id = 1;




    		FOR myrec IN SELECT tax_type_id, use_key_id, tax_type_name, formural, tax_relief,
    			tax_type_order, in_tax, linear, percentage, employer, employer_ps, active,
    			account_number, employer_account
    			FROM tax_types WHERE org_id = 1 AND ((sys_country_id is null) OR (sys_country_id = NEW.country_id))
    			ORDER BY tax_type_id
    		LOOP
    			v_tax_type_id := nextval('tax_types_tax_type_id_seq');
    			INSERT INTO tax_types (org_id, tax_type_id, use_key_id, tax_type_name, formural, tax_relief, tax_type_order, in_tax, linear, percentage, employer, employer_ps, active, currency_id, account_number, employer_account)
    			VALUES (NEW.org_id, v_tax_type_id, myrec.use_key_id, myrec.tax_type_name, myrec.formural, myrec.tax_relief, myrec.tax_type_order, myrec.in_tax, myrec.linear, myrec.percentage, myrec.employer, myrec.employer_ps, myrec.active, v_currency_id, myrec.account_number, myrec.employer_account);

    			INSERT INTO tax_rates (org_id, tax_type_id, tax_range, tax_rate)
    			SELECT NEW.org_id,  v_tax_type_id, tax_range, tax_rate
    			FROM tax_rates
    			WHERE org_id = 1 and tax_type_id = myrec.tax_type_id;
    		END LOOP;



    		v_department_id := nextval('departments_department_id_seq');
    		INSERT INTO departments (org_id, department_id, department_name) VALUES (NEW.org_id, v_department_id, 'Board of Directors');
    		INSERT INTO department_roles (org_id, department_id, department_role_name, active) VALUES (NEW.org_id, v_department_id, 'Board of Directors', true);

    		v_bank_id := nextval('banks_bank_id_seq');
    		INSERT INTO banks (org_id, bank_id, bank_name) VALUES (NEW.org_id, v_bank_id, 'Cash');
    		INSERT INTO bank_branch (org_id, bank_id, bank_branch_name) VALUES (NEW.org_id, v_bank_id, 'Cash');

    		INSERT INTO transaction_counters(transaction_type_id, org_id, document_number)
    		SELECT transaction_type_id, NEW.org_id, 1
    		FROM transaction_types;

    		INSERT INTO sys_emails (org_id, use_type,  sys_email_name, title, details)
    		SELECT NEW.org_id, use_type, sys_email_name, title, details
    		FROM sys_emails
    		WHERE org_id = 1;

    		INSERT INTO accounts_class (org_id, accounts_class_no, chat_type_id, chat_type_name, accounts_class_name)
    		SELECT NEW.org_id, accounts_class_no, chat_type_id, chat_type_name, accounts_class_name
    		FROM accounts_class
    		WHERE org_id = 1;

    		INSERT INTO account_types (org_id, accounts_class_id, account_type_no, account_type_name)
    		SELECT a.org_id, a.accounts_class_id, b.account_type_no, b.account_type_name
    		FROM accounts_class a INNER JOIN vw_account_types b ON a.accounts_class_no = b.accounts_class_no
    		WHERE (a.org_id = NEW.org_id) AND (b.org_id = 1);

    		INSERT INTO accounts (org_id, account_type_id, account_no, account_name)
    		SELECT a.org_id, a.account_type_id, b.account_no, b.account_name
    		FROM account_types a INNER JOIN vw_accounts b ON a.account_type_no = b.account_type_no
    		WHERE (a.org_id = NEW.org_id) AND (b.org_id = 1);

    		INSERT INTO default_accounts (org_id, use_key_id, account_id)
    		SELECT c.org_id, a.use_key_id, c.account_id
    		FROM default_accounts a INNER JOIN accounts b ON a.account_id = b.account_id
    			INNER JOIN accounts c ON b.account_no = c.account_no
    		WHERE (a.org_id = 1) AND (c.org_id = NEW.org_id);

    		INSERT INTO item_category (org_id, item_category_name) VALUES (NEW.org_id, 'Services');
    		INSERT INTO item_category (org_id, item_category_name) VALUES (NEW.org_id, 'Goods');

    		INSERT INTO item_units (org_id, item_unit_name) VALUES (NEW.org_id, 'Each');

    		SELECT entity_type_id INTO v_entity_type_id
    		FROM entity_types
    		WHERE (org_id = NEW.org_id) AND (use_key_id = 0);


    		UPDATE entitys SET org_id = NEW.org_id, entity_type_id = v_entity_type_id, function_role='subscription,admin,staff,finance'
    		WHERE entity_id = NEW.entity_id;

    		UPDATE entity_subscriptions SET entity_type_id = v_entity_type_id
    		WHERE entity_id = NEW.entity_id;

    		INSERT INTO workflows (link_copy, org_id, source_entity_id, workflow_name, table_name, approve_email, reject_email)
    		SELECT aa.workflow_id, cc.org_id, cc.entity_type_id, aa.workflow_name, aa.table_name, aa.approve_email, aa.reject_email
    		FROM workflows aa INNER JOIN entity_types bb ON aa.source_entity_id = bb.entity_type_id
    			INNER JOIN entity_types cc ON bb.use_key_id = cc.use_key_id
    		WHERE aa.org_id = 1 AND cc.org_id = NEW.org_id
    		ORDER BY aa.workflow_id;

    		INSERT INTO workflow_phases (org_id, workflow_id, approval_entity_id, approval_level, return_level,
    			escalation_days, escalation_hours, required_approvals, advice, notice,
    			phase_narrative, advice_email, notice_email)
    		SELECT bb.org_id, bb.workflow_id, dd.entity_type_id, aa.approval_level, aa.return_level,
    			aa.escalation_days, aa.escalation_hours, aa.required_approvals, aa.advice, aa.notice,
    			aa.phase_narrative, aa.advice_email, aa.notice_email
    		FROM workflow_phases aa INNER JOIN workflows bb ON aa.workflow_id = bb.link_copy
    			INNER JOIN entity_types cc ON aa.approval_entity_id = cc.entity_type_id
    			INNER JOIN entity_types dd ON cc.use_key_id = dd.use_key_id
    		WHERE aa.org_id = 1 AND bb.org_id = NEW.org_id AND dd.org_id = NEW.org_id;

    		INSERT INTO sys_emails (org_id, use_type, sys_email_name, title, details)
    		SELECT NEW.org_id, use_type, sys_email_name, title, details
    		FROM sys_emails
    		WHERE org_id = 1;

    		INSERT INTO sys_emailed (sys_email_id, org_id, table_id, table_name)
    		VALUES (1, NEW.org_id, NEW.entity_id, 'subscription');
    	END IF;

    	RETURN NEW;
    END;
    $BODY$
      LANGUAGE plpgsql;

    CREATE TRIGGER ins_subscriptions
    BEFORE INSERT OR UPDATE
    ON subscriptions
    FOR EACH ROW
    EXECUTE PROCEDURE ins_subscriptions();

    CREATE OR REPLACE FUNCTION upd_action()
    RETURNS trigger AS
  $BODY$
  DECLARE
  	wfid		INTEGER;
  	reca		RECORD;
  	tbid		INTEGER;
  	iswf		BOOLEAN;
  	add_flow	BOOLEAN;
  BEGIN

  	add_flow := false;
  	IF(TG_OP = 'INSERT')THEN
  		IF (NEW.approve_status = 'Completed')THEN
  			add_flow := true;
  		END IF;
  	ELSE
  		IF(OLD.approve_status = 'Draft') AND (NEW.approve_status = 'Completed')THEN
  			add_flow := true;
  		END IF;
  	END IF;

  	IF(add_flow = true)THEN
  		wfid := nextval('workflow_table_id_seq');
  		NEW.workflow_table_id := wfid;

  		IF(TG_OP = 'UPDATE')THEN
  			IF(OLD.workflow_table_id is not null)THEN
  				INSERT INTO workflow_logs (org_id, table_name, table_id, table_old_id)
  				VALUES (NEW.org_id, TG_TABLE_NAME, wfid, OLD.workflow_table_id);
  			END IF;
  		END IF;

  		FOR reca IN SELECT workflows.workflow_id, workflows.table_name, workflows.table_link_field, workflows.table_link_id
  			FROM workflows INNER JOIN entity_subscriptions ON workflows.source_entity_id = entity_subscriptions.entity_type_id
  			WHERE (workflows.table_name = TG_TABLE_NAME) AND (entity_subscriptions.entity_id= NEW.entity_id)
  		LOOP
  			iswf := false;
  			IF(reca.table_link_field is null)THEN
  				iswf := true;
  			ELSE
  				IF(TG_TABLE_NAME = 'entry_forms')THEN
  					tbid := NEW.form_id;
  				ELSIF(TG_TABLE_NAME = 'employee_leave')THEN
  					tbid := NEW.leave_type_id;
  				END IF;
  				IF(tbid = reca.table_link_id)THEN
  					iswf := true;
  				END IF;
  			END IF;

  			IF(iswf = true)THEN
  				INSERT INTO approvals (org_id, workflow_phase_id, table_name, table_id, org_entity_id, escalation_days, escalation_hours, approval_level, approval_narrative, to_be_done)
  				SELECT org_id, workflow_phase_id, tg_table_name, wfid, new.entity_id, escalation_days, escalation_hours, approval_level, phase_narrative, 'Approve - ' || phase_narrative
  				FROM vw_workflow_entitys
  				WHERE (table_name = TG_TABLE_NAME) AND (entity_id = NEW.entity_id) AND (workflow_id = reca.workflow_id)
  				ORDER BY approval_level, workflow_phase_id;

  				UPDATE approvals SET approve_status = 'Completed'
  				WHERE (table_id = wfid) AND (approval_level = 1);
  			END IF;
  		END LOOP;
  	END IF;

  	RETURN NEW;
  END;
  $BODY$
    LANGUAGE plpgsql;

    CREATE TRIGGER upd_action
    BEFORE INSERT OR UPDATE
    ON subscriptions
    FOR EACH ROW
    EXECUTE PROCEDURE upd_action();
