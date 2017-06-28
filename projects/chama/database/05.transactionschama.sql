CREATE TABLE day_ledgers (
    day_ledger_id 			serial primary key,
    entity_id 				integer references entitys,
	transaction_type_id		integer references transaction_types,
	bank_account_id			integer references bank_accounts,
	journal_id				integer references journals,
	transaction_status_id	integer references transaction_status default 1,
	currency_id				integer references currency,
	department_id			integer references departments,
	item_id					integer references items,
	store_id				integer references stores,
	org_id					integer references orgs,

	exchange_rate			real default 1 not null,
	day_ledger_date			date not null,
	day_ledger_quantity		integer not null,
    day_ledger_amount 		real default 0 not null,
	day_ledger_tax_amount	real default 0 not null,
	
	document_number			integer default 1 not null,
	payment_number			varchar(50),
	order_number			varchar(50),
	payment_terms			varchar(50),
	job						varchar(240),
	
	application_date		timestamp default now(),
	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	action_date				timestamp,
    narrative				varchar(120),
    details					text
);
CREATE INDEX day_ledgers_entity_id ON day_ledgers (entity_id);
CREATE INDEX day_ledgers_transaction_type_id ON day_ledgers (transaction_type_id);
CREATE INDEX day_ledgers_bank_account_id ON day_ledgers (bank_account_id);
CREATE INDEX day_ledgers_journal_id ON day_ledgers (journal_id);
CREATE INDEX day_ledgers_transaction_status_id ON day_ledgers (transaction_status_id);
CREATE INDEX day_ledgers_currency_id ON day_ledgers (currency_id);
CREATE INDEX day_ledgers_department_id ON day_ledgers (department_id);
CREATE INDEX day_ledgers_item_id ON day_ledgers (item_id);
CREATE INDEX day_ledgers_store_id ON day_ledgers (store_id);
CREATE INDEX day_ledgers_workflow_table_id ON day_ledgers (workflow_table_id);
CREATE INDEX day_ledgers_org_id ON day_ledgers (org_id);

CREATE VIEW vw_day_ledgers AS
	SELECT currency.currency_id, currency.currency_name, departments.department_id, departments.department_name, 
		entitys.entity_id, entitys.entity_name, items.item_id, items.item_name,  orgs.org_id, orgs.org_name, 
		transaction_status.transaction_status_id, transaction_status.transaction_status_name, 
		transaction_types.transaction_type_id, transaction_types.transaction_type_name, 
		vw_bank_accounts.bank_id, vw_bank_accounts.bank_name, vw_bank_accounts.bank_branch_name, vw_bank_accounts.account_id as gl_bank_account_id, 
		vw_bank_accounts.bank_account_id, vw_bank_accounts.bank_account_name, vw_bank_accounts.bank_account_number, 
		stores.store_id, stores.store_name,

		day_ledgers.journal_id, day_ledgers.day_ledger_id, day_ledgers.exchange_rate, day_ledgers.day_ledger_date, 
		day_ledgers.day_ledger_quantity, day_ledgers.day_ledger_amount, day_ledgers.day_ledger_tax_amount, 
		day_ledgers.document_number, day_ledgers.payment_number, day_ledgers.order_number, 
		day_ledgers.payment_terms, day_ledgers.job, day_ledgers.application_date, day_ledgers.approve_status, 
		day_ledgers.workflow_table_id, day_ledgers.action_date, day_ledgers.narrative, day_ledgers.details

	FROM day_ledgers INNER JOIN currency ON day_ledgers.currency_id = currency.currency_id
		INNER JOIN departments ON day_ledgers.department_id = departments.department_id
		INNER JOIN entitys ON day_ledgers.entity_id = entitys.entity_id
		INNER JOIN items ON day_ledgers.item_id = items.item_id
		INNER JOIN orgs ON day_ledgers.org_id = orgs.org_id
		INNER JOIN transaction_status ON day_ledgers.transaction_status_id = transaction_status.transaction_status_id
		INNER JOIN transaction_types ON day_ledgers.transaction_type_id = transaction_types.transaction_type_id
		INNER JOIN vw_bank_accounts ON day_ledgers.bank_account_id = vw_bank_accounts.bank_account_id
		LEFT JOIN stores ON day_ledgers.store_id = stores.store_id;



CREATE OR REPLACE FUNCTION get_period(date) RETURNS INTEGER AS $$
	SELECT period_id FROM periods WHERE (start_date <= $1) AND (end_date >= $1); 
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_open_period(date) RETURNS INTEGER AS $$
	SELECT period_id FROM periods WHERE (start_date <= $1) AND (end_date >= $1)
		AND (opened = true) AND (closed = false); 
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION complete_transaction(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	rec RECORD;
	bankacc INTEGER;
	msg varchar(120);
BEGIN
	SELECT transaction_id, transaction_type_id, transaction_status_id INTO rec
	FROM transactions
	WHERE (transaction_id = CAST($1 as integer));

	IF($3 = '2') THEN
		UPDATE transactions SET transaction_status_id = 4 
		WHERE transaction_id = rec.transaction_id;
		msg := 'Transaction Archived';
	ELSIF(rec.transaction_status_id = 1) THEN
		IF($3 = '1') THEN
			UPDATE transactions SET transaction_status_id = 2, approve_status = 'Completed'
			WHERE transaction_id = rec.transaction_id;
		END IF;
		msg := 'Transaction completed.';
	ELSE
		msg := 'Transaction alerady completed.';
	END IF;

	return msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION copy_transaction(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	msg varchar(120);
BEGIN

	INSERT INTO transactions (org_id, department_id, entity_id, currency_id, transaction_type_id, transaction_date, order_number, payment_terms, job, narrative, details)
	SELECT org_id, department_id, entity_id, currency_id, transaction_type_id, CURRENT_DATE, order_number, payment_terms, job, narrative, details
	FROM transactions
	WHERE (transaction_id = CAST($1 as integer));

	INSERT INTO transaction_details (org_id, transaction_id, account_id, item_id, quantity, amount, tax_amount, narrative, details)
	SELECT org_id, currval('transactions_transaction_id_seq'), account_id, item_id, quantity, amount, tax_amount, narrative, details
	FROM transaction_details
	WHERE (transaction_id = CAST($1 as integer));

	msg := 'Transaction Copied';

	return msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION process_transaction(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	rec RECORD;
	bankacc INTEGER;
	msg varchar(120);
BEGIN
	SELECT org_id, transaction_id, transaction_type_id, transaction_status_id, transaction_amount INTO rec
	FROM transactions
	WHERE (transaction_id = CAST($1 as integer));

	IF(rec.transaction_status_id = 1) THEN
		msg := 'Transaction needs to be completed first.';
	ELSIF(rec.transaction_status_id = 2) THEN
		IF (($3 = '7') AND ($3 = '8')) THEN
			SELECT max(bank_account_id) INTO bankacc
			FROM bank_accounts WHERE (is_default = true);

			INSERT INTO transactions (org_id, department_id, entity_id, currency_id, transaction_type_id, transaction_date, bank_account_id, transaction_amount)
			SELECT transactions.org_id, transactions.department_id, transactions.entity_id, transactions.currency_id, 1, CURRENT_DATE, bankacc, 
				SUM(transaction_details.quantity * (transaction_details.amount + transaction_details.tax_amount))
			FROM transactions INNER JOIN transaction_details ON transactions.transaction_id = transaction_details.transaction_id
			WHERE (transactions.transaction_id = rec.transaction_id)
			GROUP BY transactions.transaction_id, transactions.entity_id;

			INSERT INTO transaction_links (org_id, transaction_id, transaction_to, amount)
			VALUES (rec.org_id, currval('transactions_transaction_id_seq'), rec.transaction_id, rec.transaction_amount);
		
			UPDATE transactions SET transaction_status_id = 3 WHERE transaction_id = rec.transaction_id;
		ELSE
			INSERT INTO transactions (org_id, department_id, entity_id, currency_id, transaction_type_id, transaction_date, order_number, payment_terms, job, narrative, details)
			SELECT org_id, department_id, entity_id, currency_id, CAST($3 as integer), CURRENT_DATE, order_number, payment_terms, job, narrative, details
			FROM transactions
			WHERE (transaction_id = rec.transaction_id);

			INSERT INTO transaction_details (org_id, transaction_id, account_id, item_id, quantity, amount, tax_amount, narrative, details)
			SELECT org_id, currval('transactions_transaction_id_seq'), account_id, item_id, quantity, amount, tax_amount, narrative, details
			FROM transaction_details
			WHERE (transaction_id = rec.transaction_id);

			INSERT INTO transaction_links (org_id, transaction_id, transaction_to, amount)
			VALUES (REC.org_id, currval('transactions_transaction_id_seq'), rec.transaction_id, rec.transaction_amount);

			UPDATE transactions SET transaction_status_id = 3 WHERE transaction_id = rec.transaction_id;
		END IF;
		msg := 'Transaction proccesed';
	ELSE
		msg := 'Transaction previously Processed.';
	END IF;

	return msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION post_transaction(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	rec RECORD;
	periodid INTEGER;
	journalid INTEGER;
	msg varchar(120);
BEGIN
	SELECT org_id, department_id, transaction_id, transaction_type_id, transaction_type_name as tx_name, 
		transaction_status_id, journal_id, gl_bank_account_id, currency_id, exchange_rate,
		transaction_date, transaction_amount, document_number, credit_amount, debit_amount,
		entity_account_id, entity_name, approve_status INTO rec
	FROM vw_transactions
	WHERE (transaction_id = CAST($1 as integer));

	periodid := get_open_period(rec.transaction_date);
	IF(periodid is null) THEN
		msg := 'No active period to post.';
	ELSIF(rec.journal_id is not null) THEN
		msg := 'Transaction previously Posted.';
	ELSIF(rec.transaction_status_id = 1) THEN
		msg := 'Transaction needs to be completed first.';
	ELSIF(rec.approve_status != 'Approved') THEN
		msg := 'Transaction is not yet approved.';
	ELSE
		INSERT INTO journals (org_id, department_id, currency_id, period_id, exchange_rate, journal_date, narrative)
		VALUES (rec.org_id, rec.department_id, rec.currency_id, periodid, rec.exchange_rate, rec.transaction_date, rec.tx_name || ' - posting for ' || rec.document_number);
		journalid := currval('journals_journal_id_seq');

		INSERT INTO gls (org_id, journal_id, account_id, debit, credit, gl_narrative)
		VALUES (rec.org_id, journalid, rec.entity_account_id, rec.debit_amount, rec.credit_amount, rec.tx_name || ' - ' || rec.entity_name);

		IF((rec.transaction_type_id = 7) or (rec.transaction_type_id = 8)) THEN
			INSERT INTO gls (org_id, journal_id, account_id, debit, credit, gl_narrative)
			VALUES (rec.org_id, journalid, rec.gl_bank_account_id, rec.credit_amount, rec.debit_amount, rec.tx_name || ' - ' || rec.entity_name);
		ELSE
			INSERT INTO gls (org_id, journal_id, account_id, debit, credit, gl_narrative)
			SELECT org_id, journalid, trans_account_id, full_debit_amount, full_credit_amount, rec.tx_name || ' - ' || item_name
			FROM vw_transaction_details
			WHERE (transaction_id = rec.transaction_id) AND (full_amount > 0);

			INSERT INTO gls (org_id, journal_id, account_id, debit, credit, gl_narrative)
			SELECT org_id, journalid, tax_account_id, tax_debit_amount, tax_credit_amount, rec.tx_name || ' - ' || item_name
			FROM vw_transaction_details
			WHERE (transaction_id = rec.transaction_id) AND (full_tax_amount > 0);
		END IF;

		UPDATE transactions SET journal_id = journalid WHERE (transaction_id = rec.transaction_id);
		msg := process_journal(CAST(journalid as varchar),'0','0');
	END IF;

	return msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION add_tx_link(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
BEGIN
	
	INSERT INTO transaction_details (transaction_id, org_id, item_id, quantity, amount, tax_amount, narrative, details)
	SELECT CAST($3 as integer), org_id, item_id, quantity, amount, tax_amount, narrative, details
	FROM transaction_details
	WHERE (transaction_detail_id = CAST($1 as integer));

	INSERT INTO transaction_links (org_id, transaction_detail_id, transaction_detail_to, quantity, amount)
	SELECT org_id, transaction_detail_id, currval('transaction_details_transaction_detail_id_seq'), quantity, amount
	FROM transaction_details
	WHERE (transaction_detail_id = CAST($1 as integer));

	return 'DONE';
END;
$$ LANGUAGE plpgsql;


------------Hooks to approval trigger

CREATE OR REPLACE FUNCTION get_budgeted(integer, date, integer) RETURNS real AS $$
DECLARE
	reca		RECORD;
	app_id		Integer;
	v_bill		real;
	v_variance	real;
BEGIN

	FOR reca IN SELECT transaction_detail_id, account_id, amount 
		FROM transaction_details WHERE (transaction_id = $1) LOOP

		SELECT sum(amount) INTO v_bill
		FROM transactions INNER JOIN transaction_details ON transactions.transaction_id = transaction_details.transaction_id
		WHERE (transactions.department_id = $3) AND (transaction_details.account_id = reca.account_id)
			AND (transactions.journal_id is null) AND (transaction_details.transaction_detail_id <> reca.transaction_detail_id);
		IF(v_bill is null)THEN
			v_bill := 0;
		END IF;

		SELECT sum(budget_lines.amount) INTO v_variance
		FROM fiscal_years INNER JOIN budgets ON fiscal_years.fiscal_year_id = budgets.fiscal_year_id
			INNER JOIN budget_lines ON budgets.budget_id = budget_lines.budget_id
		WHERE (budgets.department_id = $3) AND (budget_lines.account_id = reca.account_id)
			AND (budgets.approve_status = 'Approved')
			AND (fiscal_years.fiscal_year_start <= $2) AND (fiscal_years.fiscal_year_end >= $2);
		IF(v_variance is null)THEN
			v_variance := 0;
		END IF;

		v_variance := v_variance - (reca.amount + v_bill);

		IF(v_variance < 0)THEN
			RETURN v_variance;
		END IF;
	END LOOP;

	RETURN v_variance;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION upd_approvals(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	app_id		Integer;
	reca 		RECORD;
	recb		RECORD;
	recc		RECORD;
	recd		RECORD;

	min_level	Integer;
	mysql		varchar(240);
	msg 		varchar(120);
BEGIN
	app_id := CAST($1 as int);
	SELECT approvals.approval_id, approvals.org_id, approvals.table_name, approvals.table_id, approvals.review_advice,
		workflow_phases.workflow_phase_id, workflow_phases.workflow_id, workflow_phases.return_level INTO reca
	FROM approvals INNER JOIN workflow_phases ON approvals.workflow_phase_id = workflow_phases.workflow_phase_id
	WHERE (approvals.approval_id = app_id);

	SELECT count(approval_checklist_id) as cl_count INTO recc
	FROM approval_checklists
	WHERE (approval_id = app_id) AND (manditory = true) AND (done = false);

	SELECT transaction_type_id, get_budgeted(transaction_id, transaction_date, department_id) as budget_var INTO recd
	FROM transactions
	WHERE (workflow_table_id = reca.table_id);

	IF ($3 = '1') THEN
		UPDATE approvals SET approve_status = 'Completed', completion_date = now()
		WHERE approval_id = app_id;
		msg := 'Completed';
	ELSIF ($3 = '2') AND (recc.cl_count <> 0) THEN
		msg := 'There are manditory checklist that must be checked first.';
	ELSIF (recd.transaction_type_id = 5) AND (recd.budget_var < 0) THEN
		msg := 'You need a budget to approve the expenditure.';
	ELSIF ($3 = '2') AND (recc.cl_count = 0) THEN
		UPDATE approvals SET approve_status = 'Approved', action_date = now(), app_entity_id = CAST($2 as int)
		WHERE approval_id = app_id;

		SELECT min(approvals.approval_level) INTO min_level
		FROM approvals INNER JOIN workflow_phases ON approvals.workflow_phase_id = workflow_phases.workflow_phase_id
		WHERE (approvals.table_id = reca.table_id) AND (approvals.approve_status = 'Draft')
			AND (workflow_phases.advice = false) AND (workflow_phases.notice = false);
		
		IF(min_level is null)THEN
			mysql := 'UPDATE ' || reca.table_name || ' SET approve_status = ' || quote_literal('Approved') 
			|| ', action_date = now()'
			|| ' WHERE workflow_table_id = ' || reca.table_id;
			EXECUTE mysql;

			INSERT INTO sys_emailed (table_id, table_name, email_type)
			VALUES (reca.table_id, 'vw_workflow_approvals', 1);
		ELSE
			FOR recb IN SELECT workflow_phase_id, advice
			FROM workflow_phases
			WHERE (workflow_id = reca.workflow_id) AND (approval_level = min_level) LOOP
				IF (recb.advice = true) THEN
					UPDATE approvals SET approve_status = 'Approved', action_date = now(), completion_date = now()
					WHERE (workflow_phase_id = recb.workflow_phase_id) AND (table_id = reca.table_id);
				ELSE
					UPDATE approvals SET approve_status = 'Completed', completion_date = now()
					WHERE (workflow_phase_id = recb.workflow_phase_id) AND (table_id = reca.table_id);
				END IF;
			END LOOP;
		END IF;
		msg := 'Approved';
	ELSIF ($3 = '3') THEN
		UPDATE approvals SET approve_status = 'Rejected',  action_date = now(), app_entity_id = CAST($2 as int)
		WHERE approval_id = app_id;

		mysql := 'UPDATE ' || reca.table_name || ' SET approve_status = ' || quote_literal('Rejected') 
		|| ', action_date = now()'
		|| ' WHERE workflow_table_id = ' || reca.table_id;
		EXECUTE mysql;

		INSERT INTO sys_emailed (table_id, table_name, email_type, org_id)
		VALUES (reca.table_id, 'vw_workflow_approvals', 2, reca.org_id);
		msg := 'Rejected';
	ELSIF ($3 = '4') AND (reca.return_level = 0) THEN
		UPDATE approvals SET approve_status = 'Review',  action_date = now(), app_entity_id = CAST($2 as int)
		WHERE approval_id = app_id;
		
		mysql := 'UPDATE ' || reca.table_name || ' SET approve_status = ' || quote_literal('Draft') 
		|| ', action_date = now()'
		|| ' WHERE workflow_table_id = ' || reca.table_id;
		EXECUTE mysql;
		
		msg := 'Forwarded for review';
	ELSIF ($3 = '4') AND (reca.return_level <> 0) THEN
		INSERT INTO approvals (org_id, workflow_phase_id, table_name, table_id, org_entity_id, escalation_days, escalation_hours, approval_level, approval_narrative, to_be_done, approve_status)
		SELECT org_id, workflow_phase_id, reca.table_name, reca.table_id, CAST($2 as int), escalation_days, escalation_hours, approval_level, phase_narrative, reca.review_advice, 'Completed'
		FROM vw_workflow_entitys
		WHERE (workflow_id = reca.workflow_id) AND (approval_level = reca.return_level)
		ORDER BY workflow_phase_id;
		msg := 'Forwarded to owner for review';
	END IF;

	RETURN msg;
END;
$$ LANGUAGE plpgsql;

