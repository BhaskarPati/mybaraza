CREATE OR REPLACE VIEW vw_members AS
	SELECT 	bank_branch.bank_branch_id, bank_branch.bank_branch_name, 
	banks.bank_id, banks.bank_name, 
	locations.location_id, locations.location_name,
	sys_countrys.sys_country_id, sys_countrys.sys_country_name, 
	members.org_id, members.entity_id, members.person_title, members.surname, members.first_name, members.middle_name, members.full_name, members.id_number, members.email, members.date_of_birth, members.gender, members.phone, members.bank_account_number, members.nationality, members.nation_of_birth, members.marital_status, members.joining_date, members.exit_date, members.picture_file, members.active, members.details, members.merry_go_round_number
	FROM members
	JOIN bank_branch ON members.bank_branch_id = bank_branch.bank_branch_id
	JOIN banks ON members.bank_id = banks.bank_id
	JOIN entitys ON members.entity_id = entitys.entity_id
	JOIN locations ON members.location_id = locations.location_id
	JOIN sys_countrys ON members.nationality = sys_countrys.sys_country_id;

CREATE OR REPLACE VIEW vw_expenses AS
	SELECT bank_accounts.bank_account_id, bank_accounts.bank_account_name, currency.currency_id,
	currency.currency_name, entitys.entity_id, entitys.entity_name, expenses.org_id,  expenses.expense_id, expenses.date_accrued, 
	expenses.amount, expenses.details
	FROM expenses
	JOIN bank_accounts ON expenses.bank_account_id = bank_accounts.bank_account_id
	JOIN currency ON expenses.currency_id = currency.currency_id
	JOIN entitys ON expenses.entity_id = entitys.entity_id;
	
CREATE OR REPLACE VIEW vw_contribution_defaults AS
	SELECT contribution_types.contribution_type_id, contribution_types.contribution_type_name, entitys.entity_id, entitys.entity_name, contribution_defaults.org_id, contribution_defaults.contribution_default_id, contribution_defaults.investment_amount, contribution_defaults.merry_go_round_amount, contribution_defaults.details
	FROM contribution_defaults
	left JOIN contribution_types ON contribution_defaults.contribution_type_id = contribution_types.contribution_type_id
	JOIN entitys ON contribution_defaults.entity_id = entitys.entity_id;

CREATE OR REPLACE VIEW vw_contribution_types AS
	SELECT contribution_types.org_id, contribution_types.contribution_type_id, contribution_types.contribution_type_name, contribution_types.investment_amount, contribution_types.merry_go_round_amount, contribution_types.frequency, contribution_types.day_of_contrib, contribution_types.applies_to_all, contribution_types.details
	FROM contribution_types;

CREATE OR REPLACE VIEW vw_contributions AS 
 SELECT contribution_types.contribution_type_id,
    contribution_types.contribution_type_name,
    periods.period_id,
    entitys.entity_id,
    entitys.entity_name,
    periods.start_date,
    contributions.org_id,
    contributions.contribution_id,
    contributions.contribution_date,
    contributions.investment_amount,
    contributions.merry_go_round_amount,
    contributions.paid,
    contributions.extra_contrib,
    contributions.loan_contrib,
    (contributions.investment_amount + contributions.merry_go_round_amount + contributions.loan_contrib ) AS total_contribution,
    contributions.details
   FROM contributions
     JOIN contribution_types ON contributions.contribution_type_id = contribution_types.contribution_type_id
     JOIN entitys ON contributions.entity_id = entitys.entity_id
     JOIN periods ON contributions.period_id= periods.period_id;

CREATE OR REPLACE VIEW vw_all_contributions AS 
 SELECT contribution_types.contribution_type_id,
    contribution_types.contribution_type_name,
    periods.period_id,
    entitys.entity_id,
    entitys.entity_name,
    periods.start_date,
	contributions.org_id,
    contributions.contribution_id,
    contributions.contribution_date,
    contributions.investment_amount,
    contributions.merry_go_round_amount,
    contributions.paid,
    contributions.extra_contrib,
    contributions.loan_contrib,
    (contributions.investment_amount + contributions.merry_go_round_amount + contributions.loan_contrib ) AS total_contribution,
    contributions.details
   FROM contributions
     JOIN contribution_types ON contributions.contribution_type_id = contribution_types.contribution_type_id
     JOIN entitys ON contributions.entity_id = entitys.entity_id
     JOIN periods ON contributions.period_id= periods.period_id;

CREATE OR REPLACE VIEW vw_contributions_unpaid AS 
SELECT contribution_types.contribution_type_id,
    contribution_types.contribution_type_name,
    periods.period_id,
    entitys.entity_id,
    entitys.entity_name,
    periods.start_date,
    contributions.org_id,
    contributions.contribution_id,
    contributions.contribution_date,
    contributions.investment_amount,
    contributions.merry_go_round_amount,
    contributions.paid,
    contributions.extra_contrib,
    contributions.loan_contrib,
    contributions.investment_amount + contributions.merry_go_round_amount + contributions.loan_contrib AS total_contribution,
    contributions.details
   FROM contributions
     JOIN contribution_types ON contributions.contribution_type_id = contribution_types.contribution_type_id
     JOIN entitys ON contributions.entity_id = entitys.entity_id
     JOIN periods ON contributions.period_id = periods.period_id
     WHERE contributions.paid = false;


CREATE OR REPLACE VIEW vw_member_contrib AS
	SELECT 	vw_contributions.contribution_type_id, vw_contributions.contribution_type_name,
		vw_members.entity_id, vw_members.full_name, vw_members.merry_go_round_number,
		vw_contributions.org_id, vw_contributions.entity_name, vw_contributions.period_id, vw_contributions.start_date,
		vw_contributions.contribution_id, vw_contributions.contribution_date, vw_contributions.investment_amount, vw_contributions.merry_go_round_amount, vw_contributions.paid, vw_contributions.loan_contrib
	FROM vw_contributions
		 JOIN vw_members  ON  vw_contributions.entity_id = vw_members.entity_id;
		
CREATE OR REPLACE VIEW vw_member_contributions AS 
	SELECT entity_id, entity_name, org_id, SUM(investment_amount) AS inv, SUM(merry_go_round_amount) as mgr, SUM(loan_contrib) as loan, SUM(total_contribution) as total 
	FROM vw_contributions
	GROUP BY entity_id, entity_name, org_id;

CREATE OR REPLACE VIEW vw_drawings AS 
SELECT entitys.entity_id,
    entitys.entity_name,
    bank_accounts.bank_account_id,
    bank_accounts.bank_account_name,
    periods.period_id,
    periods.start_date,
    drawings.org_id,
    drawings.drawing_id,
    drawings.amount,
    drawings.narrative,
    drawings.ref_number,
    drawings.withdrawal_date,
	drawings.recieved,
    drawings.details
   FROM drawings
     LEFT JOIN bank_accounts ON drawings.bank_account_id = bank_accounts.bank_account_id
     JOIN periods ON drawings.period_id = periods.period_id
     JOIN entitys ON drawings.entity_id = entitys.entity_id;
     
CREATE OR REPLACE VIEW vw_receipts AS 
 SELECT bank_accounts.bank_account_id,
    bank_accounts.bank_account_name,
    entitys.entity_id,
    entitys.entity_name,
    periods.period_id,
    periods.start_date,
    receipts.org_id,
    receipts.receipts_id,
    receipts.receipts_date,
    receipts.narrative,
    receipts.ref_number,
    receipts.amount,
    receipts.remaining_amount,
     receipts.details
   FROM receipts
     LEFT JOIN bank_accounts ON receipts.bank_account_id = bank_accounts.bank_account_id
     JOIN entitys ON receipts.entity_id = entitys.entity_id
     JOIN periods ON receipts.period_id = periods.period_id;
   
CREATE VIEW vw_investment_types AS
	SELECT orgs.org_id, orgs.org_name, investment_types.investment_type_id, investment_types.investment_type_name, investment_types.details
	FROM investment_types
	INNER JOIN orgs ON investment_types.org_id = orgs.org_id;

CREATE OR REPLACE VIEW vw_investments AS 
	SELECT currency.currency_id, currency.currency_name,
		investment_types.investment_type_id, investment_types.investment_type_name,
		bank_accounts.bank_account_id, bank_accounts.bank_account_name,
		investments.org_id, investments.investment_id, investments.investment_name, investments.date_of_accrual,
		investments.principal, investments.interest, investments.repayment_period, investments.initial_payment, investments.monthly_payments, investments.investment_status, investments.approve_status, investments.workflow_table_id, investments.action_date, investments.is_active, investments.details,
		get_total_repayment(investments.principal, investments.interest, investments.repayment_period) as total_repayment,
		get_interest_amount(investments.principal, investments.interest, investments.repayment_period) as interest_amount,
		get_total_expenditure(investment_id) as expenditure,
		get_total_income(investment_id) as income
	FROM investments
	JOIN currency ON investments.currency_id = currency.currency_id
    JOIN investment_types ON investments.investment_type_id = investment_types.investment_type_id
    LEFT JOIN bank_accounts ON investments.bank_account_id = bank_accounts.bank_account_id;

  
CREATE OR REPLACE VIEW vw_meetings AS 
	SELECT meetings.org_id, meetings.meeting_id, meetings.meeting_date, 
	meetings.meeting_place, meetings.status, meetings.details
	FROM meetings;

CREATE OR REPLACE VIEW vw_penalty AS
	SELECT  entitys.entity_id, 
	entitys.entity_name, penalty.org_id, penalty_type.penalty_type_id, penalty_type.penalty_type_name,
	bank_accounts.bank_account_id, penalty.penalty_id, penalty.date_of_accrual, penalty.amount, penalty.paid, 
	 penalty.action_date, penalty.is_active, penalty.details
	FROM penalty
	JOIN entitys ON penalty.entity_id = entitys.entity_id
	JOIN penalty_type ON penalty.penalty_type_id = penalty_type.penalty_type_id
	LEFT JOIN bank_accounts ON penalty.bank_account_id = bank_accounts.bank_account_id;

CREATE VIEW vw_penalty_type AS
	SELECT orgs.org_id, orgs.org_name, penalty_type.penalty_type_id, penalty_type.penalty_type_name, penalty_type.details
	FROM penalty_type
	JOIN orgs ON penalty_type.org_id = orgs.org_id;
	
CREATE OR REPLACE VIEW vw_member_statement AS
	SELECT org_id, entity_id, entity_name, start_date, contribution, drawings, receipts, loan, repayments, penalty FROM 
		((SELECT  org_id, entity_id, entity_name, start_date, vw_contributions.investment_amount + vw_contributions.merry_go_round_amount  AS contribution,  0::real AS drawings, 
		0::real AS receipts, 0::real AS loan, 0::real AS repayments, 0::real AS penalty FROM vw_contributions WHERE vw_contributions.paid = true)
		UNION ALL
		(SELECT  org_id, entity_id, entity_name, start_date, 0::real, amount, 0::real,0::real, 0::real, 0::real FROM vw_drawings)
		UNION ALL
		(SELECT  org_id, entity_id, entity_name, start_date, 0::real, 0::real, amount, 0::real,  0::real, 0::real FROM vw_receipts)
		UNION ALL
		(SELECT org_id, entity_id, entity_name, application_date, 0::real,0::real, 0::real, principle, 0::real, 0::real FROM vw_loans)
		UNION ALL
		(SELECT  org_id, entity_id, entity_name, start_date, 0::real, 0::real, 0::real,  0::real, total_repayment, 0::real FROM vw_loan_monthly)
		UNION ALL
		(SELECT org_id, entity_id, entity_name, date_of_accrual, 0::real, 0::real, 0::real, 0::real, 0::real, amount FROM vw_penalty where paid = false
		)) AS a 
	ORDER BY start_date DESC;

CREATE OR REPLACE VIEW vw_total_statements AS 
	SELECT vw_members.entity_id,
		vw_members.full_name,
		vw_members.org_id,
		get_total_contribs(vw_members.entity_id, vw_members.org_id) AS contributions,
		get_total_drawings(vw_members.entity_id, vw_members.org_id) AS drawings,
		get_total_receipts(vw_members.entity_id, vw_members.org_id) AS receipts,
		get_total_loans(vw_members.entity_id, vw_members.org_id) AS loans,
		get_total_loan_monthly(vw_members.entity_id, vw_members.org_id) AS repayment,
		get_total_penalty(vw_members.entity_id, vw_members.org_id) AS penalty
	FROM vw_members;

CREATE OR REPLACE VIEW vw_member_meeting AS 
	SELECT members.entity_id,
		members.surname,
		members.first_name,
		meetings.meeting_id,
		meetings.meeting_date,
		member_meeting.org_id,
		member_meeting.member_meeting_id,
		member_meeting.narrative, meetings.meeting_place
	FROM member_meeting
     JOIN members ON member_meeting.entity_id = members.entity_id
     JOIN meetings ON member_meeting.meeting_id = meetings.meeting_id;

DROP VIEW vws_tx_ledger;
DROP VIEW vw_tx_ledger;

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
	
CREATE OR REPLACE VIEW vw_chama_statement AS
	SELECT title, date, contribution, drawings, receipts, loans, repayments, investments, borrowing, penalty,income, expenditure, org_id FROM 
		((SELECT 'contributions'::varchar(50) as title, start_date as date, total_contribution  AS contribution, 0::real AS drawings, 0::real AS receipts, 0::real AS loans,
		0::real AS repayments, 0::real AS investments, 0::real AS borrowing, 0::real AS penalty, 0::real AS income, 0::real AS expenditure, org_id FROM vw_contributions
		WHERE vw_contributions.paid = true)
		UNION ALL
		(SELECT  'Drawings'::varchar(50) as title ,start_date as date, 0::real, amount,  0::real, 0::real, 0::real, 0::real, 0::real, 0::real, 0::real, 0::real, org_id FROM vw_drawings)
		UNION ALL
		(SELECT  'Receipt'::varchar(50) as title ,start_date as date, 0::real,  0::real, amount, 0::real, 0::real, 0::real, 0::real, 0::real, 0::real, 0::real, org_id FROM vw_receipts)
		UNION ALL
		(SELECT 'loans'::varchar(50) as title, loan_date as date, 0::real,  0::real,  0::real, principle, 0::real, 0::real, 0::real,0::real, 0::real, 0::real, vw_loans.org_id
			FROM vw_loans INNER JOIN periods ON vw_loans.loan_date BETWEEN periods.start_date AND periods.end_date)
		UNION ALL
		(SELECT 'Repayment'::varchar(50) as title, start_date as date,  0::real, 0::real, 0::real,  0::real, total_repayment, 0::real,0::real, 0::real, 0::real, 0::real, org_id
		FROM vw_loan_monthly)
		UNION ALL
		(SELECT 'Investment'::varchar(50) as title, date_of_accrual as date, 0::real, 0::real, 0::real, 0::real,  0::real,  principal, 0::real, 0::real, 0::real, 0::real, org_id FROM vw_investments)
		UNION ALL
		(SELECT 'borrowing'::varchar(50) as title, borrowing_date as date, 0::real, 0::real, 0::real,  0::real, principle, 0::real, 0::real, 0::real, 0::real, 0::real, org_id FROM vw_borrowing)
		UNION ALL
		(SELECT 'Penalty'::varchar(50) as title, date_of_accrual as date , 0::real, 0::real, 0::real, 0::real, 0::real, 0::real,  0::real, amount, 0::real, 0::real, org_id
		FROM vw_penalty)
		UNION ALL
		(SELECT 'Income'::varchar(50) as title, transaction_date as date,  0::real, 0::real, 0::real, 0::real, 0::real, 0::real, 0::real,  0::real, dr_amount, 0::real, org_id
		FROM vw_tx_ledger WHERE vw_tx_ledger.tx_type = 1)
		UNION ALL
		(SELECT 'Expenditure'::varchar(50) as title, transaction_date as date,  0::real,  0::real, 0::real, 0::real, 0::real, 0::real, 0::real, 0::real,  0::real, cr_amount, org_id
		FROM vw_tx_ledger WHERE vw_tx_ledger.tx_type = -1)) AS a
	order by date;
