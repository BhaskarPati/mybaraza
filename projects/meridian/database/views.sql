CREATE OR REPLACE VIEW vwperiods AS
	SELECT 
	periods.period_id,
	fiscal_year_id,
	to_char(periods.period_end, 'YYYY') as periodyear,
	to_char(periods.period_end, 'Month') as periodmonth,
	date_part('month', periods.period_end) as monthid, 
	date_part('quarter', periods.period_end) as quarter,
	--(trunc((date_part('month', enddate)-1)/6)+1) as semister,
	periods.period_opened,
	periods.period_closed,
	periods.period_start,
	periods.period_end,	
	periods.close_month,
	periods.is_active ,
	periods.details as perioddetails
  FROM periods;


CREATE OR REPLACE VIEW vwborrower AS
	SELECT borrower.borrower_id, borrower.employer_name,entitys.entity_name,
	(COALESCE(borrower.sur_name,'') || ' ' || COALESCE(borrower.first_name,'') || ' ' || COALESCE(borrower.middle_name,'')) as borrower_name
	FROM borrower
	INNER JOIN entitys ON borrower.entity_id = entitys.entity_id;


CREATE OR REPLACE VIEW vwinvestor AS
	SELECT investor.investor_id, entitys.entity_name
	FROM investor
	INNER JOIN entitys ON investor.entity_id = entitys.entity_id;


--reducing balance schedule
DROP VIEW vwloanshedule ;
CREATE OR REPLACE VIEW vwloanshedule AS 
 SELECT loans.loan_id, generate_series(1, loans.repaymentperiod) AS loan_period, 
 round(getloanperiodbalance(geteffectiveloan(loans.loan_id), loans.interest, generate_series(1, loans.repaymentperiod), getrepayment(geteffectiveloan(loans.loan_id), loans.interest, loans.repaymentperiod))::double precision) AS period_balance, 
 round(getloanperiodbalance(geteffectiveloan(loans.loan_id), loans.interest, generate_series(1, loans.repaymentperiod) - 1, getrepayment(geteffectiveloan(loans.loan_id), loans.interest, loans.repaymentperiod)) * (loans.interest / 1200::double precision)) AS interest_component, 
 round(loans.monthlyrepayment - getloanperiodbalance(geteffectiveloan(loans.loan_id), loans.interest, generate_series(1, loans.repaymentperiod) - 1, getrepayment(geteffectiveloan(loans.loan_id), loans.interest, loans.repaymentperiod)) * (loans.interest / 1200::double precision)) AS principal_component, 
 loans.monthlyrepayment as monthly_repayment
   FROM loans;


--fixed line repayment

--DROP VIEW vwFixedLoanSchedule;
CREATE OR REPLACE VIEW vwFixedLoanSchedule AS 
 SELECT loan.loanid, generate_series(1, loan.repaymentperiod) AS loan_period, 
	round(geteffectiveloan(loan.loanid)/loan.repaymentperiod) as monthly_repayment,
	getSimplePeriodBalance(loan.loanid,generate_series(1, loan.repaymentperiod),round(geteffectiveloan(loan.loanid)/loan.repaymentperiod)::real) as period_balance,
	(loantypes.defaultinterest/(loantypes.defaultinterest+100) * (geteffectiveloan(loan.loanid)/loan.repaymentperiod)) as interest_component,
	(100/(loantypes.defaultinterest+100) * (geteffectiveloan(loan.loanid)/loan.repaymentperiod)) as principal_component
   FROM loan
   INNER JOIN loantypes ON loan.loantypeid = loantypes.loantypeid;




drop VIEW vwloan;
CREATE OR REPLACE VIEW vwloan AS
	SELECT loantypes.loantype_id, loantypes.loantype_name, loantypes.default_interest, 
		entitys.entity_id, entitys.entity_name, borrower.borrower_id, geteffectiveloan(loans.loan_id) as effective_loan,
		(loans.principal || ', ' || loantypes.loantype_name || ', ' || entity_name) AS loansummmary,
		loans.loan_id, loans.loandate, loans.principal, loans.interest, loans.repaymentperiod,
		loans.monthlyrepayment, getrepayment(loans.principal, loans.interest, loans.repaymentperiod) as repaymentamount, 
		gettotalrepayment(loans.loan_id) as totalrepayment, gettotalinterest(loans.loan_id) as totalinterest,
		(loans.principal + gettotalinterest(loans.loan_id) - gettotalrepayment(loans.loan_id)) as loanbalance,
		getpaymentperiod(loans.principal, loans.monthlyrepayment, loans.interest) as calcrepaymentperiod, loans.loanapproved
	FROM loantypes 
	INNER JOIN loans ON loantypes.loantype_id = loans.loantype_id
	INNER JOIN borrower ON loans.borrower_id = borrower.borrower_id
	INNER JOIN entitys ON borrower.entity_id = entitys.entity_id;



--DROP VIEW vwloanpayment;
-- View: vwloanpayment
CREATE OR REPLACE VIEW vwloanpayment AS 
 SELECT vwloan.loantype_id, vwloan.loantype_name, vwloan.borrower_id, vwloan.entity_name, vwloan.loan_id, vwloan.loandate, vwloan.principal, vwloan.default_interest, vwloan.calcrepaymentperiod, vwloan.repaymentperiod, vwloan.monthlyrepayment, vwloan.repaymentamount, generate_series(1, vwloan.repaymentperiod) AS months, round(getloanperiod(vwloan.principal, vwloan.default_interest::real, generate_series(1, vwloan.repaymentperiod), vwloan.repaymentamount)::double precision) AS loanbalance, round(getloanperiod(vwloan.principal, vwloan.default_interest::real, generate_series(1, vwloan.repaymentperiod) - 1, vwloan.repaymentamount) * (vwloan.default_interest / 1200)::double precision) AS loanintrest
   FROM vwloan;
ALTER TABLE vwloanpayment OWNER TO root;



DROP VIEW vwloanreinbursement;
CREATE OR REPLACE VIEW vwloanreinbursement AS
	SELECT (loans.principal || ', ' || loantypes.loantype_name || ', ' || entity_name) AS loansummmary,
		loan_reinbursment.loan_reinbursment_id, loans.loan_id,
		loan_reinbursment.amount_reinbursed, payment_mode.payment_mode_id,payment_mode.payment_mode_name,
		loan_reinbursment.documentnumber, loan_reinbursment.paymentnarrative, loan_reinbursment.details
	FROM loan_reinbursment
	INNER JOIN loans ON loan_reinbursment.loan_id = loans.loan_id
	INNER JOIN payment_mode ON loan_reinbursment.payment_mode_id = payment_mode.payment_mode_id
	INNER JOIN loantypes ON loans.loantype_id = loantypes.loantype_id
	INNER JOIN borrower ON loans.borrower_id = borrower.borrower_id
	INNER JOIN entitys ON borrower.entity_id = entitys.entity_id;





----===AFTER DISASTER
DROP VIEW vwinvestor;
CREATE OR REPLACE VIEW vwinvestor AS 
 SELECT investor.investor_id, (COALESCE(investor.sur_name,'') || ' ' || COALESCE(investor.first_name,'') || ' ' || COALESCE(investor.middle_name,'')) as investor_name
   FROM investor
   JOIN entitys ON investor.entity_id = entitys.entity_id;

ALTER TABLE vwinvestor OWNER TO postgres;


--DROP VIEW vwinvestment;
CREATE OR REPLACE VIEW vwinvestment AS
  SELECT investment.investment_id, (COALESCE(investor.sur_name,'') || ' ' || COALESCE(investor.first_name,'') || ' ' || COALESCE(investor.middle_name,'')) as investor_name,
	investment_type.investment_type_id, investment_type.investment_type_name, investment_type.default_interest, 
	(investment.investment_id || ' ' || (COALESCE(investor.sur_name,'') || ' ' || COALESCE(investor.first_name,'') || ' ' || COALESCE(investor.middle_name,'')) || ' ' || investment_type.investment_type_name || ' ' || principal) as investment_summary,
	investment.investor_id,  investment.principal, getTotalInvestmentDeductions(investment.investment_id) as total_deductions,
	(investment.principal - getTotalInvestmentDeductions(investment.investment_id)) as investment_balance, getPeriodID(investment.investment_date) as first_maturity_period,
	investment.credit_charge, investment.legal_fee, investment.valuation_fee, investment.trasfer_fee, investment.investment_date, investment.is_approved, investment.details as investment_details
  FROM investment
  INNER JOIN investor ON investment.investor_id = investor.investor_id
  INNER JOIN investment_type ON investment.investment_type_id = investment_type.investment_type_id;
  


CREATE OR REPLACE VIEW vwdeductions AS
  SELECT deduction.deduction_id, deduction.deduction_amount, deduction.effective_date, deduction.details as deduction_details,
  (investment.investment_id || ' ' || (COALESCE(investor.sur_name,'') || ' ' || COALESCE(investor.first_name,'') || ' ' || COALESCE(investor.middle_name,'')) || ' ' || investment_type.investment_type_name || ' ' || principal) as investment_summary
  FROM deduction
  INNER JOIN investment ON deduction.investment_id = investment.investment_id
  INNER JOIN investment_type ON investment.investment_type_id = investment_type.investment_type_id
  INNER JOIN investor ON investment.investor_id = investor.investor_id;




CREATE OR REPLACE VIEW vwinvestment_maturity AS
  SELECT investment_maturity.investment_maturity_id, investment_maturity.period_id, investment_maturity.investment_id, 
      investment_maturity.mature_amount, investment_maturity.interest_amount, getTax(1,investment_maturity.interest_amount) as with_holding_tax,
      to_char(periods.period_end, 'YYYY') as periodyear,to_char(periods.period_end, 'Month') as periodmonth, 
      (to_char(periods.period_end, 'YYYY') || ' '  || to_char(periods.period_end, 'Month')) as periodsummary,
      (investment_maturity.investment_id || ' ' || (COALESCE(investor.sur_name,'') || ' ' || COALESCE(investor.first_name,'') || ' ' || COALESCE(investor.middle_name,'')) || ' ' || investment_type.investment_type_name || ' ' || principal) as investment_summary  
	FROM investment_maturity
	INNER JOIN periods ON investment_maturity.period_id = periods.period_id
	INNER JOIN investment ON investment_maturity.investment_id = investment.investment_id
	INNER JOIN investment_type ON investment.investment_type_id = investment_type.investment_type_id
	INNER JOIN investor ON investment.investor_id = investor.investor_id;



CREATE OR REPLACE VIEW vwbank_branch AS
  SELECT bank.bank_id, bank.bank_name, bank.bank_code, bank.banka_bbrev, bank_branch.bank_branch_id, bank_branch.bank_branch_name, (bank.bank_name || ': ' || bank_branch.bank_branch_name) as branchsummary
  FROM bank_branch
  INNER JOIN bank ON bank_branch.bank_id = bank.bank_id;


CREATE OR REPLACE VIEW vwfiscal_year AS 
  SELECT fiscal_year_id, fiscal_year_start, fiscal_year_end, year_opened, year_closed, to_char(fiscal_year_start, 'YYYY') as fiscal_year
  FROM fiscal_years;


CREATE OR REPLACE VIEW vw_accounts AS 
 SELECT vw_account_types.accounts_class_id, vw_account_types.chat_type_id, vw_account_types.chat_type_name, vw_account_types.accounts_class_name, vw_account_types.account_type_id, vw_account_types.account_type_name, accounts.account_id, accounts.account_name, accounts.is_header, accounts.is_active, accounts.details, (((((accounts.account_id || ' : '::text) || vw_account_types.accounts_class_name::text) || ' : '::text) || vw_account_types.account_type_name::text) || ' : '::text) || accounts.account_name::text AS account_description
   FROM accounts
   JOIN vw_account_types ON accounts.account_type_id = vw_account_types.account_type_id;

ALTER TABLE vw_accounts OWNER TO root;



CREATE VIEW vw_periods AS
	SELECT fiscal_years.fiscal_year_id, fiscal_years.fiscal_year_start, fiscal_years.fiscal_year_end,
		fiscal_years.year_opened, fiscal_years.year_closed,
		periods.period_id, periods.period_start, periods.period_end, periods.period_opened, periods.period_closed, 
		date_part('month', periods.period_start) as month_id, to_char(periods.period_start, 'YYYY') as period_year, 
		to_char(periods.period_start, 'Month') as period_month, (trunc((date_part('month', periods.period_start)-1)/3)+1) as quarter, 
		(trunc((date_part('month', periods.period_start)-1)/6)+1) as semister
	FROM periods INNER JOIN fiscal_years ON periods.fiscal_year_id = fiscal_years.fiscal_year_id
	ORDER BY periods.period_start;


--DROP VIEW vw_bank;
CREATE OR REPLACE VIEW vw_bank_branch AS
	SELECT bank_branch.bank_branch_id, bank_branch.bank_branch_name, 
	bank.bank_id, bank.bank_name, bank.bank_code, bank.banka_bbrev
	FROM bank_branch
	INNER JOIN bank ON bank_branch.bank_id = bank.bank_id;