CREATE TABLE tx_ledger (
	tx_ledger_id 			serial primary key,
	ledger_type_id			integer references ledger_types,
	entity_id 				integer references entitys,
	bpartner_id				integer references entitys,
	bank_account_id			integer references bank_accounts,
	investment_id			integer references investments,
	currency_id				integer references currency,
	journal_id				integer references journals,
	org_id					integer references orgs,

	
	exchange_rate			real default 1 not null,
	tx_type					integer default 1 not null,
	tx_ledger_date			date not null,
	tx_ledger_quantity		integer default 1 not null,
	tx_ledger_amount 		real default 0 not null,
	tx_ledger_tax_amount	real default 0 not null,
	reference_number		varchar(50),
	payment_reference		varchar(50),
	for_processing			boolean default false not null,
	is_cleared				boolean default false not null,
	completed				boolean default false not null,

	application_date		timestamp default now(),
	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	action_date				timestamp,

	narrative				varchar(120),
	details					text
);
CREATE INDEX tx_ledger_ledger_type_id ON tx_ledger (ledger_type_id);
CREATE INDEX tx_ledger_entity_id ON tx_ledger (entity_id);
CREATE INDEX tx_ledger_bpartner_id ON tx_ledger (bpartner_id);
CREATE INDEX tx_ledger_bank_account_id ON tx_ledger (bank_account_id);
CREATE INDEX tx_ledger_currency_id ON tx_ledger (currency_id);
CREATE INDEX tx_ledger_journal_id ON tx_ledger (journal_id);
CREATE INDEX tx_ledger_workflow_table_id ON tx_ledger (workflow_table_id);
CREATE INDEX tx_ledger_org_id ON tx_ledger (org_id);
CREATE INDEX tx_ledger_investment_id ON tx_ledger (investment_id);

CREATE VIEW vw_tx_ledger AS
	SELECT ledger_types.ledger_type_id, ledger_types.ledger_type_name, 
		currency.currency_id, currency.currency_name, currency.currency_symbol,
		entitys.entity_id, entitys.entity_name, 
		bank_accounts.bank_account_id, bank_accounts.bank_account_name,
		
		transactions.org_id, transactions.transaction_id, transactions.journal_id, transactions.investment_id, 
		transactions.exchange_rate, transactions.tx_type, transactions.transaction_date, transactions.payment_date,
		transactions.transaction_amount, transactions.transaction_tax_amount, transactions.reference_number, 
		transactions.payment_number, transactions.for_processing, transactions.completed, transactions.is_cleared,
		transactions.application_date, transactions.approve_status, transactions.workflow_table_id, transactions.action_date, 
		transactions.narrative, transactions.details,
		
		(CASE WHEN transactions.journal_id is null THEN 'Not Posted' ELSE 'Posted' END) as posted,
		to_char(transactions.payment_date, 'YYYY.MM') as ledger_period,
		to_char(transactions.payment_date, 'YYYY') as ledger_year,
		to_char(transactions.payment_date, 'Month') as ledger_month,
		
		(transactions.exchange_rate * transactions.tx_type * transactions.transaction_amount) as base_amount,
		(transactions.exchange_rate * transactions.tx_type * transactions.transaction_tax_amount) as base_tax_amount,
		
		(CASE WHEN transactions.completed = true THEN 
			(transactions.exchange_rate * transactions.tx_type * transactions.transaction_amount)
		ELSE 0::real END) as base_balance,
		
		(CASE WHEN transactions.is_cleared = true THEN 
			(transactions.exchange_rate * transactions.tx_type * transactions.transaction_amount)
		ELSE 0::real END) as cleared_balance,
		
		(CASE WHEN transactions.tx_type = 1 THEN 
			(transactions.exchange_rate * transactions.transaction_amount)
		ELSE 0::real END) as dr_amount,
		
		(CASE WHEN transactions.tx_type = -1 THEN 
			(transactions.exchange_rate * transactions.transaction_amount) 
		ELSE 0::real END) as cr_amount
		
	FROM transactions
		INNER JOIN ledger_types ON transactions.ledger_type_id = ledger_types.ledger_type_id
		INNER JOIN currency ON transactions.currency_id = currency.currency_id
		INNER JOIN bank_accounts ON transactions.bank_account_id = bank_accounts.bank_account_id
		INNER JOIN entitys ON transactions.entity_id = entitys.entity_id
	WHERE transactions.tx_type is not null;

	
CREATE VIEW vws_tx_ledger AS
	SELECT org_id, ledger_period, ledger_year, ledger_month, 
		sum(base_amount) as sum_base_amount, sum(base_tax_amount) as sum_base_tax_amount,
		sum(base_balance) as sum_base_balance, sum(cleared_balance) as sum_cleared_balance,
		sum(dr_amount) as sum_dr_amount, sum(cr_amount) as sum_cr_amount,
		
		to_date(ledger_period || '.01', 'YYYY.MM.DD') as start_date,
		sum(base_amount) + prev_balance(to_date(ledger_period || '.01', 'YYYY.MM.DD')) as prev_balance_amount,
		sum(cleared_balance) + prev_clear_balance(to_date(ledger_period || '.01', 'YYYY.MM.DD')) as prev_clear_balance_amount
			
	FROM vw_tx_ledger
	GROUP BY org_id, ledger_period, ledger_year, ledger_month;

	
CREATE OR REPLACE FUNCTION upd_ledger(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	msg							varchar(120);
BEGIN
	
	IF ($3 = '1') THEN
		UPDATE tx_ledger SET for_processing = true WHERE tx_ledger_id = $1::integer;
		msg := 'Opened for processing';
	ELSIF ($3 = '2') THEN
		UPDATE tx_ledger SET for_processing = false WHERE tx_ledger_id = $1::integer;
		msg := 'Closed for processing';
	ELSIF ($3 = '3') THEN
		UPDATE tx_ledger  SET tx_ledger_date = current_date, completed = true
		WHERE tx_ledger_id = $1::integer AND completed = false;
		msg := 'Completed';
	ELSIF ($3 = '4') THEN
		UPDATE tx_ledger  SET is_cleared = true WHERE tx_ledger_id = $1::integer;
		msg := 'Cleared for posting ';
	END IF;

	RETURN msg;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION cpy_ledger(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	v_ledger_date				timestamp;
	last_date					timestamp;
	v_start						integer;
	v_end						integer;
	v_inteval					interval;
	msg							varchar(120);
BEGIN

	SELECT max(tx_ledger_date)::timestamp INTO last_date
	FROM tx_ledger
	WHERE (to_char(tx_ledger_date, 'YYYY.MM') = $1);
	v_start := EXTRACT(YEAR FROM last_date) * 12 + EXTRACT(MONTH FROM last_date);
	
	SELECT max(tx_ledger_date)::timestamp INTO v_ledger_date
	FROM tx_ledger;
	v_end := EXTRACT(YEAR FROM v_ledger_date) * 12 + EXTRACT(MONTH FROM v_ledger_date) + 1;
	v_inteval :=  ((v_end - v_start) || ' months')::interval;

	IF ($3 = '1') THEN
		INSERT INTO tx_ledger(ledger_type_id, entity_id, bpartner_id, bank_account_id, 
				currency_id, journal_id, org_id, exchange_rate, tx_type, tx_ledger_date, 
				tx_ledger_quantity, tx_ledger_amount, tx_ledger_tax_amount, reference_number, 
				narrative)
		SELECT ledger_type_id, entity_id, bpartner_id, bank_account_id, 
			currency_id, journal_id, org_id, exchange_rate, tx_type, (tx_ledger_date + v_inteval), 
			tx_ledger_quantity, tx_ledger_amount, tx_ledger_tax_amount, reference_number,
			narrative
		FROM tx_ledger
		WHERE (tx_type = -1) AND (to_char(tx_ledger_date, 'YYYY.MM') = $1);

		msg := 'Appended a new month';
	END IF;

	RETURN msg;
END;
$$ LANGUAGE plpgsql;

