CREATE TABLE accounts_class (
	accounts_class_id		integer primary key,
	chat_type_id			integer not null,
	chat_type_name			varchar(50) not null,
	accounts_class_name		varchar(50) not null unique,
	details					text
);
CREATE INDEX accounts_class_chat_type_id ON accounts_class (chat_type_id);

CREATE TABLE account_types (
	account_type_id			integer primary key,
	accounts_class_id		integer references accounts_class,
	account_type_name		varchar(50) not null unique,
	details					text
);
CREATE INDEX account_types_accounts_class_id ON account_types (accounts_class_id);

CREATE TABLE accounts (
	account_id				integer primary key,
	account_type_id			integer references account_types,
	account_name			varchar(50) not null,
	is_header				boolean default false not null,
	is_active				boolean default true not null,
	details					text
);
CREATE INDEX accounts_account_type_id ON accounts (account_type_id);

CREATE TABLE fiscal_years (
	fiscal_year_id			varchar(9) primary key,
	fiscal_year_start		date not null,
	fiscal_year_end			date not null,
	year_opened				boolean default true not null,
	year_closed				boolean default false not null,
	details					text
);

CREATE TABLE periods (
	period_id				serial primary key,
	fiscal_year_id			varchar(9) references fiscal_years,
	period_start			date not null,
	period_end				date not null,
	period_opened			boolean not null default false,
	period_closed			boolean not null default false,
	details					text
);
CREATE INDEX periods_fiscal_year_id ON periods (fiscal_year_id);

CREATE TABLE journals (
	journal_id				serial primary key,
	period_id				integer not null references periods,
	journal_date			date not null,
	posted					boolean not null default false,
	narrative				varchar(240),
	details					text
);	
CREATE INDEX journals_period_id ON journals (period_id);

CREATE TABLE gls (
	gl_id					serial primary key,
	journal_id				integer not null references journals,
	account_id				integer not null references accounts,
	debit					real not null default 0,
	credit					real not null default 0,
	gl_narrative			varchar(240)
);
CREATE INDEX gls_journal_id ON gls (journal_id);
CREATE INDEX gls_account_id ON gls (account_id);

CREATE VIEW vw_account_types AS
	SELECT accounts_class.accounts_class_id, accounts_class.accounts_class_name, accounts_class.chat_type_id, accounts_class.chat_type_name, 
		account_types.account_type_id, account_types.account_type_name, account_types.details
	FROM account_types INNER JOIN accounts_class ON account_types.accounts_class_id = accounts_class.accounts_class_id;

CREATE VIEW vw_accounts AS
	SELECT vw_account_types.accounts_class_id, vw_account_types.chat_type_id, vw_account_types.chat_type_name, 
		vw_account_types.accounts_class_name, vw_account_types.account_type_id, vw_account_types.account_type_name,
		accounts.account_id, accounts.account_name, accounts.is_header, accounts.is_active, accounts.details,
		(accounts.account_id || ' : ' || vw_account_types.accounts_class_name || ' : ' || vw_account_types.account_type_name
		|| ' : ' || accounts.account_name) as account_description
	FROM accounts INNER JOIN vw_account_types ON accounts.account_type_id = vw_account_types.account_type_id;

CREATE VIEW vw_periods AS
	SELECT fiscal_years.fiscal_year_id, fiscal_years.fiscal_year_start, fiscal_years.fiscal_year_end,
		fiscal_years.year_opened, fiscal_years.year_closed,
		periods.period_id, periods.period_start, periods.period_end, periods.period_opened, periods.period_closed, 
		date_part('month', periods.period_start) as month_id, to_char(periods.period_start, 'YYYY') as period_year, 
		to_char(periods.period_start, 'Month') as period_month, (trunc((date_part('month', periods.period_start)-1)/3)+1) as quarter, 
		(trunc((date_part('month', periods.period_start)-1)/6)+1) as semister
	FROM periods INNER JOIN fiscal_years ON periods.fiscal_year_id = fiscal_years.fiscal_year_id
	ORDER BY periods.period_start;

CREATE VIEW vw_journals AS
	SELECT vw_periods.fiscal_year_id, vw_periods.fiscal_year_start, vw_periods.fiscal_year_end,
		vw_periods.year_opened, vw_periods.year_closed,
		vw_periods.period_id, vw_periods.period_start, vw_periods.period_end, vw_periods.period_opened, vw_periods.period_closed, 
		vw_periods.month_id, vw_periods.period_year, vw_periods.period_month, vw_periods.quarter, vw_periods.semister,
		journals.journal_id, journals.journal_date, journals.posted, journals.narrative, journals.details
	FROM journals INNER JOIN vw_periods ON journals.period_id = vw_periods.period_id;

CREATE VIEW vw_gls AS
	SELECT vw_accounts.accounts_class_id, vw_accounts.chat_type_id, vw_accounts.chat_type_name, 
		vw_accounts.accounts_class_name, vw_accounts.account_type_id, vw_accounts.account_type_name,
		vw_accounts.account_id, vw_accounts.account_name, vw_accounts.is_header, vw_accounts.is_active,
		vw_journals.fiscal_year_id, vw_journals.fiscal_year_start, vw_journals.fiscal_year_end,
		vw_journals.year_opened, vw_journals.year_closed,
		vw_journals.period_id, vw_journals.period_start, vw_journals.period_end, vw_journals.period_opened, vw_journals.period_closed, 
		vw_journals.month_id, vw_journals.period_year, vw_journals.period_month, vw_journals.quarter, vw_journals.semister,
		vw_journals.journal_id, vw_journals.journal_date, vw_journals.posted, vw_journals.narrative,
		gls.gl_id, gls.debit, gls.credit, gls.gl_narrative
	FROM gls INNER JOIN vw_accounts ON gls.account_id = vw_accounts.account_id
		INNER JOIN vw_journals ON gls.journal_id = vw_journals.journal_id;

CREATE OR REPLACE FUNCTION ins_fiscal_years() RETURNS trigger AS $$
BEGIN
	INSERT INTO periods (fiscal_year_id, period_start, period_end)
	SELECT NEW.fiscal_year_id, period_start, CAST(period_start + CAST('1 month' as interval) as date) - 1
	FROM (SELECT CAST(generate_series(fiscal_year_start, fiscal_year_end, '1 month') as date) as period_start
		FROM fiscal_years WHERE fiscal_year_id = NEW.fiscal_year_id) as a;

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_fiscal_years AFTER INSERT ON fiscal_years
    FOR EACH ROW EXECUTE PROCEDURE ins_fiscal_years();

CREATE OR REPLACE FUNCTION process_journal(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	rec RECORD;
	msg varchar(120);
BEGIN

	SELECT periods.period_start, periods.period_end, periods.period_opened, periods.period_closed, journals.journal_date, journals.posted, 
		sum(debit) as sum_debit, sum(credit) as sum_credit INTO rec
	FROM (periods INNER JOIN journals ON periods.period_id = journals.period_id)
		INNER JOIN gls ON journals.journal_id = gls.journal_id
	WHERE (journals.journal_id = CAST($1 as integer))
	GROUP BY periods.period_start, periods.period_end, periods.period_opened, periods.period_closed, journals.journal_date, journals.posted;

	IF(rec.posted = true) THEN
		msg := 'Journal previously Processed.';
	ELSIF((rec.period_start > rec.journal_date) OR (rec.period_end < rec.journal_date)) THEN
		msg := 'Journal date has to be within periods date.';
	ELSIF((rec.period_opened = false) OR (rec.period_closed = true)) THEN
		msg := 'Transaction period has to be opened and not closed.';
	ELSIF(rec.sum_debit <> rec.sum_credit) THEN
		msg := 'Cannot process Journal because credits do not equal debits.';
	ELSE
		UPDATE journals SET posted = true WHERE (journals.journal_id = CAST($1 as integer));
		msg := 'Journal Processed.';
	END IF;

	return msg;
END;
$$ LANGUAGE plpgsql;


CREATE FUNCTION upd_gls() RETURNS trigger AS $$
DECLARE
	isposted BOOLEAN;
BEGIN
	SELECT posted INTO isposted
	FROM journals 
	WHERE (journal_id = NEW.journal_id);

	IF (isposted = true) THEN
		RAISE EXCEPTION '% Journal is already posted no changes are allowed.', NEW.journal_id;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER upd_gls BEFORE INSERT OR UPDATE ON gls
    FOR EACH ROW EXECUTE PROCEDURE upd_gls();

