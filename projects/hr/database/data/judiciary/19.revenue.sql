
CREATE TABLE court_trxs (
	court_trx_id			serial primary key,
	org_id					integer references orgs,
	journal_id				integer,
	court_trx_type			integer default 1 not null,
	court_trx_date			date not null,
	amount					real default 0 not null,
	receipt_start			integer,
	receipt_end				integer,
	approved				boolean default false not null,
	approved_date			timestamp,
	approved_by				integer,
	details					text
);

CREATE VIEW vw_court_trxs AS
	SELECT orgs.org_id, orgs.org_name, court_trxs.court_trx_id, court_trxs.journal_id,
		court_trxs.court_trx_type, court_trxs.approved, court_trxs.court_trx_date,
		court_trxs.amount, court_trxs.receipt_start, court_trxs.receipt_end, court_trxs.details
	FROM orgs INNER JOIN court_trxs ON orgs.org_id = court_trxs.org_id;


CREATE OR REPLACE FUNCTION post_court_trxs(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	rec RECORD;
	periodid INTEGER;
	journalid INTEGER;
	msg varchar(120);
BEGIN
	SELECT orgs.org_id, orgs.org_name, court_trxs.court_trx_id, court_trxs.journal_id,
		court_trxs.court_trx_type, court_trxs.approved, court_trxs.court_trx_date,
		court_trxs.amount, court_trxs.receipt_start, court_trxs.receipt_end
	INTO rec
	FROM orgs INNER JOIN court_trxs ON orgs.org_id = court_trxs.org_id
	WHERE (court_trxs.court_trx_id = CAST($1 as integer));

	periodid := get_open_period(rec.court_trx_date);
	IF ($3 = '1') THEN
		UPDATE court_trxs SET approved = true, approved_date = now(), approved_by = CAST($2 as integer)
		WHERE court_trx_id = CAST($1 as integer);
		msg := 'Approved';
	ELSIF(periodid is null) THEN
		msg := 'No active period to post.';
	ELSIF(rec.journal_id is not null) THEN
		msg := 'Transaction previously Posted.';
	ELSIF(rec.approved = true) THEN
		msg := 'Transaction is not yet approved.';
	ELSE
		INSERT INTO journals (org_id, department_id, currency_id, period_id, exchange_rate, journal_date, narrative)
		VALUES (rec.org_id, rec.org_id, 1, periodid, 1, rec.court_trx_date, 'Posting for Ledger ' || rec.court_trx_id);
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

