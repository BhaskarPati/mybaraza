

CREATE TABLE holidays (
	holiday_id				serial primary key,
	org_id					integer references orgs,
	holiday_name			varchar(50) not null,
	holiday_date			date,
	details					text
);
CREATE INDEX holidays_org_id ON holidays (org_id);


CREATE TABLE fiscal_years (
	fiscal_year_id			varchar(9) primary key,
	org_id					integer references orgs,
	fiscal_year_start		date not null,
	fiscal_year_end			date not null,
	year_opened				boolean default true not null,
	year_closed				boolean default false not null,
	details					text
);
CREATE INDEX fiscal_years_org_id ON fiscal_years (org_id);

CREATE TABLE periods (
	period_id				serial primary key,
	fiscal_year_id			varchar(9) references fiscal_years,
	org_id					integer references orgs,
	start_date				date not null,
	end_date				date not null,
	opened					boolean default false not null,
	activated				boolean default false not null,
	closed					boolean default false not null,

	--- payroll details
	overtime_rate			float default 1 not null,
	per_diem_tax_limit		float default 2000 not null,
	is_posted				boolean default false not null,
	loan_approval			boolean default false not null,
	gl_payroll_account		varchar(32),
	gl_bank_account			varchar(32),
	gl_advance_account		varchar(32),

	bank_header				text,
	bank_address			text,

    entity_id 				integer references entitys,
	application_date		timestamp default now(),
	approve_status			varchar(16) default 'Completed' not null,
	workflow_table_id		integer,
	action_date				timestamp,

	details					text,
	UNIQUE(org_id, start_date)
);
CREATE INDEX periods_fiscal_year_id ON periods (fiscal_year_id);
CREATE INDEX periods_org_id ON periods (org_id);



CREATE VIEW vw_periods_c AS
	SELECT fiscal_years.fiscal_year_id, fiscal_years.fiscal_year_start, fiscal_years.fiscal_year_end,
		fiscal_years.year_opened, fiscal_years.year_closed,

		periods.period_id, periods.org_id,
		periods.start_date, periods.end_date, periods.opened, periods.activated, periods.closed,
		periods.overtime_rate, periods.per_diem_tax_limit, periods.is_posted,
		periods.gl_payroll_account, periods.gl_bank_account, periods.gl_advance_account,
		periods.bank_header, periods.bank_address, periods.details,

		date_part('month', periods.start_date) as month_id, to_char(periods.start_date, 'YYYY') as period_year,
		to_char(periods.start_date, 'Month') as period_month, (trunc((date_part('month', periods.start_date)-1)/3)+1) as quarter,
		(trunc((date_part('month', periods.start_date)-1)/6)+1) as semister,
		to_char(periods.start_date, 'YYYYMM') as period_code
	FROM periods LEFT JOIN fiscal_years ON periods.fiscal_year_id = fiscal_years.fiscal_year_id
	ORDER BY periods.start_date;

CREATE VIEW vw_period_year AS
	SELECT org_id, period_year
	FROM vw_periods_c
	GROUP BY org_id, period_year
	ORDER BY period_year;

CREATE VIEW vw_period_quarter AS
	SELECT org_id, quarter
	FROM vw_periods_c
	GROUP BY org_id, quarter
	ORDER BY quarter;

CREATE VIEW vw_period_semister AS
	SELECT org_id, semister
	FROM vw_periods_c
	GROUP BY org_id, semister
	ORDER BY semister;

CREATE VIEW vw_period_month AS
	SELECT org_id, month_id, period_year, period_month
	FROM vw_periods_c
	GROUP BY org_id, month_id, period_year, period_month
	ORDER BY month_id, period_year, period_month;

CREATE OR REPLACE FUNCTION ins_periods() RETURNS trigger AS $$
DECLARE
	year_close 		BOOLEAN;
BEGIN
	SELECT year_closed INTO year_close
	FROM fiscal_years
	WHERE (fiscal_year_id = NEW.fiscal_year_id);

	IF (NEW.approve_status = 'Approved') THEN
		NEW.opened = false;
		NEW.activated = false;
		NEW.closed = true;
	END IF;

	IF(year_close = true)THEN
		RAISE EXCEPTION 'The year is closed not transactions are allowed.';
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_periods BEFORE INSERT OR UPDATE ON periods
    FOR EACH ROW EXECUTE PROCEDURE ins_periods();

------------Hooks to approval trigger
CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON periods
    FOR EACH ROW EXECUTE PROCEDURE upd_action();
