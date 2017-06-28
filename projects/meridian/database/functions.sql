

--given loans.principal, loans.interest, loans.repaymentperiod. are we getting the Loan Balance, EMI or what ????
CREATE OR REPLACE FUNCTION getrepayment(real, real, integer) RETURNS real AS 
$$
DECLARE
	emi real;		--estimated monthly installment - equal
	ri real;

	princ real;
	intr real;
	repay_period int;
	
BEGIN
	princ := $1;			--get principal
	intr := $2;				--get interest rate of loan
	repay_period := $3;		--get agreed repayment period
	
	ri := 1 + (intr/1200);		--1200 => intr/12 * 100
		
	emi := princ * (ri ^ repay_period) * (ri - 1) / ((ri ^ repay_period) - 1);		--tried and tested ok
	
	--EMI Formula : l x r [(1+r)^n /(1+r)^n-1 ] x 1/12 				
	--l = loan amount
	--r = rate of interest
	--n = term of the loan

	
	RETURN emi;
END;
$$ LANGUAGE plpgsql;



--calculates N (the loan term ie the number of periods(months) that will take to clear the loan given the parameters)
--params: principal, emi, interestrate
CREATE OR REPLACE FUNCTION getpaymentperiod(real, real, real) RETURNS real AS $$
DECLARE

	princ	real;
	emi		real;
	intr	real;		--predefined interest rate

	paymentperiod real;
	q real;
	
BEGIN

	princ := $1;
	emi := $2;
	intr := $3;
	

	q := intr/1200;

	IF (emi > (q * princ)) THEN
	  paymentperiod := (log(emi) - log(emi - (q * princ))) / (log(q + 1));				--TRIED AND TESTED OK
	ELSE
	  paymentperiod := 1;
	END IF;

	RETURN paymentperiod;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION gettotalrepayment(integer) RETURNS real AS $$
	SELECT COALESCE(SUM(repayment + interest_paid),0)
	FROM loan_monthly
	WHERE (loan_id = $1);
	$$ LANGUAGE SQL;


CREATE OR REPLACE FUNCTION gettotalinterest(integer) RETURNS real AS $$
	SELECT CASE WHEN sum(interest_amount) is NULL THEN 0 ELSE sum(interest_amount) END 
		FROM loan_monthly
		WHERE (loan_id = $1);
$$ LANGUAGE SQL;



--TRIGGER FUNCTIONS
CREATE OR REPLACE FUNCTION insmonthly()
  RETURNS trigger AS
$BODY$

BEGIN		
	--loans
	INSERT INTO loan_monthly (period_id, loan_id, repayment, interest_amount, interest_paid)
	SELECT NEW.period_id, loan_id, monthlyrepayment, (loanbalance * interest / 1200), 0
	FROM vwloan WHERE (loanbalance > 0) AND (loanapproved = true);
		
	--mature investments (those with first maturity date within/before the current period 
	INSERT INTO investment_maturity(investment_id,period_id,mature_amount,interest_amount)
	SELECT investment_id, NEW.period_id, investment_balance, (investment_balance * default_interest/100)
	FROM vwinvestment 
	WHERE investment_balance > 0 AND	first_maturity_period <= NEW.period_id;
  
	RETURN NULL;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION insmonthly() OWNER TO postgres;

CREATE TRIGGER trInsMonthly AFTER INSERT ON periods
	FOR EACH ROW EXECUTE PROCEDURE insmonthly();





CREATE OR REPLACE FUNCTION validateLoan() RETURNS trigger AS $trValidateLoan$		 
DECLARE
		
	totalcontribution 	real;	--of the loan applicant
	totalloanbalances 	real;	--of the loan applicant
	currentshares		real;		--difference btwn contrib and loan balances
	ri				real;		--used in formula

	intr			real;
	q			real;
	
	A		real;		--loan principal/Amount
	N		integer;	--loan term
	emi		real;		--P
	
	is_red_bal	boolean;
		
BEGIN
		
	SELECT COALESCE(is_reducing_balance,false) INTO is_red_bal FROM loantypes WHERE loantype_id = NEW.loantype_id;
		
	SELECT default_interest INTO intr FROM loantypes WHERE loantype_id = NEW.loantype_id;	
	ri := 1 + (intr/100);		--1200 => intr/12 * 100	if per anum (divide by 12) so that we get periodic/monthly interest

	NEW.interest := intr;		--per month
	
	IF is_red_bal = true THEN
	  NEW.monthlyrepayment := round(NEW.principal * (ri ^ NEW.repaymentperiod) * (ri - 1) / ((ri ^ NEW.repaymentperiod) - 1));	
	ELSIF is_red_bal = false THEN
	  --NEW.monthlyrepayment := round((NEW.principal + (intr*12/100::real * NEW.principal))/NEW.repaymentperiod);
		NEW.monthlyrepayment := round((NEW.principal + (intr*NEW.repaymentperiod/100::real * NEW.principal))/NEW.repaymentperiod);		
	ELSE
	  --unreachable code segment
	END IF;

	RETURN NEW;

END;
$trValidateLoan$ LANGUAGE plpgsql;
CREATE TRIGGER trValidateLoan BEFORE INSERT ON loans
	FOR EACH ROW EXECUTE PROCEDURE validateLoan();



--plz not that the formulars are exactly the same...just some variable introduced to work with UPDATE TRIGGER
CREATE OR REPLACE FUNCTION updateLoan() RETURNS trigger AS $trUpdateLoan$		 
DECLARE
		
	totalcontribution 	real;	--of the loan applicant
	totalloanbalances 	real;	--of the loan applicant
	currentshares		real;		--difference btwn contrib and loan balances
	ri				real;		--used in formula

	intr			real;
	q			real;
	
	A		real;		--loan principal/Amount
	N		integer;	--loan term
	emi		real;		--P	

	is_red_bal	boolean;
		
BEGIN
		
	SELECT COALESCE(is_reducing_balance,false) INTO is_red_bal FROM loantypes WHERE loantype_id = NEW.loantype_id;

	SELECT default_interest INTO intr FROM loantypes WHERE loantype_id = NEW.loantype_id;	
	ri := 1 + (intr/100);		--1200 => intr/12 * 100	when interest is defined per anum (divide by 12 to get monthly interest)

	--plz not that the formulars are exactly the same...just some variable introduced to work with UPDATE TRIGGER
	A := NEW.principal;
	N := NEW.repaymentperiod; 
	emi := NEW.monthlyrepayment;

	
	IF (is_red_bal = true) THEN

	    --NEW.repaymentperiod :=  N;
	    NEW.monthlyrepayment := round(A * (ri ^ N) * (ri - 1) / ((ri ^ N) - 1));	
	
	ELSIF (is_red_bal = false) THEN
	    --NEW.repaymentperiod :=  N;
	    NEW.monthlyrepayment := round((NEW.principal + (intr*12/100::real * NEW.principal))/NEW.repaymentperiod);	
	ELSE

	END IF;

	RETURN NEW;

END;
$trUpdateLoan$ LANGUAGE plpgsql;

CREATE TRIGGER trUpdateLoan BEFORE UPDATE ON loans
	FOR EACH ROW EXECUTE PROCEDURE updateLoan();




CREATE OR REPLACE FUNCTION getloanperiod(real, real, integer, real) RETURNS real AS $$
DECLARE
	loanbalance real;
	ri real;
BEGIN
	ri := 1 + ($2/1200);

	loanbalance := $1 * (ri ^ $3) - ($4 * ((ri ^ $3)  - 1) / (ri - 1));
		
	RETURN loanbalance;
END;
$$ LANGUAGE plpgsql;


















-/*-trigger to update transactions for contributions apart from the payroll 
CREATE OR REPLACE FUNCTION validateInvestment() RETURNS trigger AS $trValidateInvestment$		 
DECLARE
		
	
	ri				real;		--used in formula

	intr			real;
	q			real;
	
	A		real;		--loan principal/Amount
	N		integer;	--loan term
	emi		real;		--P
	
		
BEGIN
		
		
	--SELECT default_interest INTO intr FROM loantypes WHERE loantype_id = NEW.loantype_id;	
	
	ri := 1 + (NEW.interest);		--1200 => intr/12 * 100		
		
	NEW.monthlyrepayment := round(NEW.principal * (ri ^ NEW.tenure_months) * (ri - 1) / ((ri ^ NEW.tenure_months) - 1));	
	RETURN NEW;

END;
$trValidateInvestment$ LANGUAGE plpgsql;

CREATE TRIGGER trValidateInvestment BEFORE INSERT ON investment
	FOR EACH ROW EXECUTE PROCEDURE validateInvestment();*/








CREATE OR REPLACE FUNCTION ins_Borrower() RETURNS trigger AS $$
DECLARE
	rec RECORD;
BEGIN
	--entity types 0=root,1=staff, 2=client, 3=supplier, 5=partner,7=Admin, 8=spouse,9=referee, 10=investor

	IF (TG_OP = 'INSERT') THEN
		IF(NEW.entity_id IS NULL) THEN
			SELECT org_id INTO rec
			FROM orgs WHERE (is_default = true);	

			NEW.entity_id := nextval('entitys_entity_id_seq');

			IF(NEW.borrower_id is null) THEN
				NEW.borrower_id := NEW.entity_id;
			END IF;

			INSERT INTO entitys (entity_id, org_id, entity_type_id, entity_name, User_name, Function_Role)
			VALUES (NEW.entity_id, rec.org_id, 2, 
				(NEW.sur_name || ' ' || NEW.first_name || ' ' || COALESCE(NEW.middle_name, '')),
				lower(substring(NEW.first_name from 1 for 1) || NEW.sur_name), 'client');
		END IF;
	ELSIF (TG_OP = 'UPDATE') THEN
		UPDATE entitys  SET entity_name = (NEW.sur_name || ' ' || NEW.first_name || ' ' || COALESCE(NEW.middle_name, ''))
		WHERE entity_id = NEW.entity_id;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_Ins_Employees BEFORE INSERT OR UPDATE ON borrower
    FOR EACH ROW EXECUTE PROCEDURE ins_Borrower();















CREATE OR REPLACE FUNCTION ins_Investor() RETURNS trigger AS $$
DECLARE
	rec RECORD;
BEGIN
	--entity types 0=root,1=staff, 2=client, 3=supplier, 5=partner,7=Admin, 8=spouse,9=referee, 10=investor

	IF (TG_OP = 'INSERT') THEN
		IF(NEW.entity_id IS NULL) THEN
			SELECT org_id INTO rec
			FROM orgs WHERE (is_default = true);	

			NEW.entity_id := nextval('entitys_entity_id_seq');

			IF(NEW.investor_id is null) THEN
				NEW.investor_id := NEW.entity_id;
			END IF;

			INSERT INTO entitys (entity_id, org_id, entity_type_id, entity_name, User_name, Function_Role)
			VALUES (NEW.entity_id, rec.org_id, 10, 
				(NEW.sur_name || ' ' || NEW.first_name || ' ' || COALESCE(NEW.middle_name, '')),
				lower(substring(NEW.first_name from 1 for 1) || NEW.sur_name), 'investor');
		END IF;
	ELSIF (TG_OP = 'UPDATE') THEN
		UPDATE entitys  SET entity_name = (NEW.sur_name || ' ' || NEW.first_name || ' ' || COALESCE(NEW.middle_name, ''))
		WHERE entity_id = NEW.entity_id;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_Ins_Investor BEFORE INSERT OR UPDATE ON investor
    FOR EACH ROW EXECUTE PROCEDURE ins_Investor();


CREATE OR REPLACE FUNCTION ins_Partner() RETURNS trigger AS $$
DECLARE
	rec RECORD;
BEGIN
	--entity types 0=root,1=staff, 2=client, 3=supplier, 5=partner,7=Admin, 8=spouse,9=referee, 10=investor

	IF (TG_OP = 'INSERT') THEN
		IF(NEW.entity_id IS NULL) THEN
			SELECT org_id INTO rec
			FROM orgs WHERE (is_default = true);	

			NEW.entity_id := nextval('entitys_entity_id_seq');

			IF(NEW.partner_id is null) THEN
				NEW.partner_id := NEW.entity_id;
			END IF;

			INSERT INTO entitys (entity_id, org_id, entity_type_id, entity_name, User_name, Function_Role)
			VALUES (NEW.entity_id, rec.org_id, 5, 
				(NEW.sur_name || ' ' || NEW.first_name || ' ' || COALESCE(NEW.middle_name, '')),
				lower(substring(NEW.first_name from 1 for 1) || NEW.sur_name), 'partner');
		END IF;
	ELSIF (TG_OP = 'UPDATE') THEN
		UPDATE entitys  SET entity_name = (NEW.sur_name || ' ' || NEW.first_name || ' ' || COALESCE(NEW.middle_name, ''))
		WHERE entity_id = NEW.entity_id;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_Ins_Partner BEFORE INSERT OR UPDATE ON partner
    FOR EACH ROW EXECUTE PROCEDURE ins_Partner();




--APPROVAL FUNCTIONS
--Arguments: 1=keyfield, 2=logged in user, 3=approvals or phase, 4=filterid if any
CREATE OR REPLACE FUNCTION loanApproval(varchar(20), varchar(20), varchar(20), varchar(20)) RETURNS VARCHAR(20) AS $$

DECLARE
	keyfield varchar(20);
	user_id varchar(20);
	approval varchar(20);
	filter_id varchar(20);
BEGIN 
	--initialization
	keyfield := $1;
	user_id := $2;
	approval := $3;
	filter_id := $4;

	--process
	IF(approval = 'Approve')  THEN

		UPDATE loans SET loanapproved = true
		--rejected = '0', pending = '0',actiondate = now(), 
		--userid = CAST($2 as int)
		WHERE loan_id = CAST(keyfield as int);
	
	ELSIF(approval = 'Reject')  THEN
		UPDATE loans SET loanapproved = false
		--rejected = '0', pending = '0',actiondate = now(), 
		--userid = CAST($2 as int)
		WHERE loan_id = CAST(keyfield as int);
	
	END IF;
		
RETURN approval;

END;
$$ LANGUAGE plpgsql;





--==AFTER THE DISASTER

--for reducing balance
--given principal, interest rate, period, emi
CREATE OR REPLACE FUNCTION getloanperiodbalance(real, real, integer, real)
  RETURNS real AS
$BODY$
DECLARE
	loanbalance real;
	ri real;

	A 		real;		--principal (loan amount)
	n		integer;	--elapsed periods !!1
	P		real;		--the amount of each equal payment aka emi
	B		real;		--loan balance
BEGIN
	A	:= $1;	--Loan Amount
	n	:= $3;	--nth period
	P	:= $4;	--emi

	--ri := 1 + ($2/1200);	--this works if we are computing interest p.a
	ri := 1 + ($2/100);

	--source: http://oakroadsystems.com/math/loan.htm
	--B = A(1+ri)^n - P/ri[(1+ri)^n - 1]			--NB: For a savings account or other investment, just change the first minus sign to a plus.
	--simplified to : B = A(ri)^n - P/ri[(ri)^n - 1]		--since ri = 1+i/1200
	loanbalance := A * (ri ^ n) - (P * ((ri ^ n)  - 1) / (ri - 1));		--this formula yields the same result as the one below

	--loanbalance := $1 * (ri ^ $3) - ($4 * ((ri ^ $3)  - 1) / (ri - 1));		--this is the original formula..less readable
		
	RETURN loanbalance;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION getloanperiodbalance(real, real, integer, real) OWNER TO root;


-- Function: geteffectiveloan(integer)

-- DROP FUNCTION geteffectiveloan(integer);

CREATE OR REPLACE FUNCTION geteffectiveloan(integer)
  RETURNS real AS
$BODY$

	SELECT CAST (principal + (principal * interest * 12/100) + credit_charge + legal_fee + valuation_fee + trasfer_fee AS REAL)
	FROM loans
	WHERE (loan_id = $1);

$BODY$
  LANGUAGE sql VOLATILE
  COST 100;
ALTER FUNCTION geteffectiveloan(integer) OWNER TO root;



--given loan id and repayment period
CREATE OR REPLACE FUNCTION geteffectiveloan(integer,integer)
  RETURNS real AS
$BODY$

	SELECT CAST (principal + (principal * interest * $2/100) AS REAL)
	FROM loans
	WHERE (loan_id = $1);

$BODY$
  LANGUAGE sql VOLATILE
  COST 100;
ALTER FUNCTION geteffectiveloan(integer) OWNER TO root;


--for fixed line method
--given loan id and period(n), emi
CREATE OR REPLACE FUNCTION getSimplePeriodBalance(integer, integer,real) RETURNS real AS 
$$

DECLARE
	ln_id		integer;
	n_th		integer;
	eff_loan	real;		--loan + interest	
	sum_repayments	real;		--all repayments so far
	instalment 	real;		
	

BEGIN
	ln_id	:= $1;
	n_th	:= $2;
	instalment	:= $3;		--monthly installments

	SELECT geteffectiveloan(ln_id) INTO eff_loan;

	--
	SELECT COALESCE(SUM(s.emi),0) INTO sum_repayments
	    FROM
	    (select generate_series(1,n_th) as n, instalment as emi) s;

	RETURN eff_loan - sum_repayments;

END;
$$ LANGUAGE plpgsql;




CREATE OR REPLACE FUNCTION createRepaymentTable()
  RETURNS trigger AS
$BODY$		 
DECLARE
	is_red_bal	boolean;		
		
BEGIN
	SELECT COALESCE(is_reducing_balance,false) INTO is_red_bal FROM loantypes WHERE loantype_id = NEW.loantype_id;

	IF is_red_bal = true THEN
	    --reducing balance: emi components to be confirmed
	     INSERT INTO repayment_table(loan_id, loan_period, emi, loan_period_balance, interest_component, principal_component)
		    SELECT NEW.loan_id, loan_period, monthly_repayment, period_balance, interest_component, principal_component
		    FROM vwloanshedule WHERE loan_id = NEW.loan_id;

	ELSIF is_red_bal = false THEN
	    --for fixed rate this is ok
	    INSERT INTO repayment_table(loan_id, loan_period, emi, loan_period_balance, interest_component, principal_component)
		    SELECT NEW.loan_id, loan_period, monthly_repayment, period_balance, interest_component, principal_component
		    FROM vwFixedLoanSchedule WHERE loan_id = NEW.loan_id;
	ELSE

	END IF;

	RETURN NEW;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION createrepaymenttable() OWNER TO root;

CREATE TRIGGER trCreateRepaymentTable AFTER INSERT ON loans
	FOR EACH ROW EXECUTE PROCEDURE createRepaymentTable();

--GIVENT INVESTMENTID
CREATE OR REPLACE FUNCTION getTotalInvestmentDeductions(integer)
  RETURNS real AS
$BODY$

	SELECT COALESCE(SUM(deduction.deduction_amount),0) 
	FROM deduction
	WHERE investment_id = $1;
	
$BODY$
  LANGUAGE sql VOLATILE
  COST 100;
ALTER FUNCTION getTotalInvestmentDeductions(integer) OWNER TO root;


--calculate the tax amount given the tax id, and amount to tax
CREATE OR REPLACE FUNCTION getTax(integer, real)
  RETURNS real AS
$BODY$

	SELECT CAST((COALESCE(tax.tax_rate,-1)/100 * $2) AS REAL)
	FROM tax
	WHERE tax_id = $1;
	
$BODY$
  LANGUAGE sql VOLATILE
  COST 100;
ALTER FUNCTION getTax(integer, real) OWNER TO root;



CREATE OR REPLACE FUNCTION getperiodid(date)
  RETURNS integer AS
$BODY$
	DECLARE
		myrec RECORD;
	BEGIN
		SELECT period_id, period_start, period_end INTO myrec 
		FROM periods
		WHERE (period_start <= $1) AND (period_start >= $1);	
	
		--may return null if non-existent
		RETURN COALESCE(myrec.period_id,-1);
	END;

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION getperiodid(date) OWNER TO root;





--update dishonoured cheques


CREATE OR REPLACE FUNCTION updRepaymentTable() RETURNS trigger AS $$
DECLARE
	rec RECORD;
BEGIN
	--cheque status 1=pending, 2=cleared, 3=dishonoured/bounced

	IF (TG_OP = 'UPDATE') THEN
	      IF(NEW.cheque_status_id = 1)THEN		--pending
		  NEW.is_dishonoured = false;
		  NEW.is_paid = false;
	      ELSIF(NEW.cheque_status_id = 2)THEN		--cleared
		  NEW.is_dishonoured = false;
		  NEW.is_paid = true;
	      ELSIF(NEW.cheque_status_id = 3)THEN		--bounced
		  NEW.is_dishonoured = true;
		  NEW.is_paid = false;
	      END IF;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trUpdRepaymentTable BEFORE UPDATE ON repayment_table
    FOR EACH ROW EXECUTE PROCEDURE updRepaymentTable();




----GL POSTING TRIGGERS---

----==============INVESTMENT MODULE
--1. Adding Investment
--CR Liabilitis(Investors a/c)	DR Asset(Bank)

CREATE OR REPLACE FUNCTION postAddInvestment() RETURNS trigger AS $$
DECLARE

	prd_id	integer;
	jnl_id	integer;
	acc_id	integer;
	
	rec_investor RECORD;
	rec_borrower RECORD;
BEGIN
	jnl_id := nextval('journals_journal_id_seq');
	--SELECT getperiodid(CURRENT_DATE) INT prd_id;	
	SELECT MAX(period_id) INTO prd_id FROM periods;	--STOP GAP
	
	SELECT investor_name INTO rec_investor	FROM vwinvestor WHERE investor_id = NEW.investor_id;	

	--getnextval();
	IF (TG_OP = 'INSERT') THEN
	    --journal entry
	    
	    INSERT INTO journals(journal_id,period_id,journal_date,narrative) VALUES(jnl_id,prd_id,current_date,'New investment Kshs(' || NEW.principal || ') from ' || rec_investor.investor_name);
	    --gl entry
	    --a. CR: increase in liability(investors)
	    SELECT account_id INTO acc_id FROM accounts WHERE upper(account_name) = 'INVESTORS';	
	    INSERT INTO gls(journal_id, account_id, debit, credit) VALUES(jnl_id,acc_id,0.0,NEW.principal);		--CR

	    --b. DR: increase in asset(bank)
	    SELECT account_id INTO acc_id FROM accounts WHERE upper(account_name) = 'BANK';	
	    INSERT INTO gls(journal_id, account_id, debit, credit) VALUES(jnl_id,acc_id,NEW.principal,0.0);		--DR

	ELSIF (TG_OP = 'UPDATE') THEN
	ELSIF (TG_OP = 'DELETE') THEN	      
	END IF;

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trPostAddInvestment AFTER INSERT OR UPDATE OR DELETE ON investment
    FOR EACH ROW EXECUTE PROCEDURE postAddInvestment();

--2. Reducing Investment
--DR Liability(Investors a/c)	CR Asset(Bank)

CREATE OR REPLACE FUNCTION postReduceInvestment() RETURNS trigger AS $$
DECLARE

	prd_id	integer;
	jnl_id	integer;
	acc_id	integer;
	
	rec_investor RECORD;
	rec_borrower RECORD;
BEGIN
	jnl_id := nextval('journals_journal_id_seq');
	--SELECT getperiodid(CURRENT_DATE) INT prd_id;	
	SELECT MAX(period_id) INTO prd_id FROM periods;	--STOP GAP
	
	SELECT investor_name INTO rec_investor	FROM vwinvestor WHERE investor_id = (SELECT MAX(investor_id) FROM investment WHERE investment_id = NEW.investment_id );

	--getnextval();
	IF (TG_OP = 'INSERT') THEN
	    --journal entry
	    
	    INSERT INTO journals(journal_id,period_id,journal_date,narrative) VALUES(jnl_id,prd_id,current_date,'Reducing investment Kshs(' || NEW.deduction_amount || ') for  ' || rec_investor.investor_name);
	    --gl entry
	    --a. DR: decrease in liability(investors)
	    SELECT account_id INTO acc_id FROM accounts WHERE upper(account_name) = 'INVESTORS';	
	    INSERT INTO gls(journal_id, account_id, debit, credit) VALUES(jnl_id,acc_id,NEW.deduction_amount,0.0);		

	    --b. CR: decrease in asset(bank)
	    SELECT account_id INTO acc_id FROM accounts WHERE upper(account_name) = 'BANK';	
	    INSERT INTO gls(journal_id, account_id, debit, credit) VALUES(jnl_id,acc_id,0.0,NEW.deduction_amount);		

	ELSIF (TG_OP = 'UPDATE') THEN
	ELSIF (TG_OP = 'DELETE') THEN	      
	END IF;

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trPostReduceInvestment AFTER INSERT OR UPDATE OR DELETE ON deduction
    FOR EACH ROW EXECUTE PROCEDURE postReduceInvestment();

--3. Pay commision
--DR Expenses(Commissions a/c)

CREATE OR REPLACE FUNCTION postCommissionPayment() RETURNS trigger AS $$
DECLARE

	prd_id	integer;
	jnl_id	integer;
	acc_id	integer;
	
	rec_investor RECORD;
	rec_borrower RECORD;
BEGIN
	jnl_id := nextval('journals_journal_id_seq');
	--SELECT getperiodid(CURRENT_DATE) INT prd_id;	
	SELECT MAX(period_id) INTO prd_id FROM periods;	--STOP GAP
	
	SELECT investor_name INTO rec_investor	FROM vwinvestor WHERE investor_id = (SELECT MAX(investor_id) FROM investment WHERE investment_id = (SELECT MAX(investment_id) FROM investment_maturity WHERE investment_maturity_id = NEW.investment_maturity_id));

	--getnextval();
	IF (TG_OP = 'INSERT') THEN
	    --journal entry
	    
	    INSERT INTO journals(journal_id,period_id,journal_date,narrative) VALUES(jnl_id,prd_id,current_date,'Paid commision Kshs(' || NEW.cheque_amount || ') to  ' || rec_investor.investor_name);
	    --gl entry
	    --a. DR: increase expenses(commisions)
	    SELECT account_id INTO acc_id FROM accounts WHERE upper(account_name) = 'COMMISSION';	
	    INSERT INTO gls(journal_id, account_id, debit, credit) VALUES(jnl_id,acc_id,NEW.cheque_amount,0.0);		

	    --b. CR: decrease in asset(bank)
	    SELECT account_id INTO acc_id FROM accounts WHERE upper(account_name) = 'BANK';	
	    INSERT INTO gls(journal_id, account_id, debit, credit) VALUES(jnl_id,acc_id,0.0,NEW.cheque_amount);		

	ELSIF (TG_OP = 'UPDATE') THEN
	ELSIF (TG_OP = 'DELETE') THEN	      
	END IF;

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trPostCommissionPayment AFTER INSERT OR UPDATE OR DELETE ON commission_payment
    FOR EACH ROW EXECUTE PROCEDURE postCommissionPayment();





--==========================LOAN MANAGEMENT===================
--4. Reinburse Loans
--DR Asset(borrower) CR Asset(bank), CR Revenue(charges)
CREATE OR REPLACE FUNCTION postReinbursement() RETURNS trigger AS $$
DECLARE

	prd_id	integer;
	jnl_id	integer;
	acc_id	integer;
	fee_charge	real;
	
	rec_investor RECORD;
	rec_borrower RECORD;
BEGIN
	jnl_id := nextval('journals_journal_id_seq');
	--SELECT getperiodid(CURRENT_DATE) INT prd_id;	
	SELECT MAX(period_id) INTO prd_id FROM periods;	--STOP GAP
	
	SELECT entity_name,borrower_name INTO rec_borrower FROM vwborrower WHERE borrower_id = (SELECT MAX(borrower_id) FROM loans WHERE loan_id = NEW.loan_id);	
	
	--getnextval();
	IF (TG_OP = 'INSERT') THEN
	    --journal entry
	    
	    INSERT INTO journals(journal_id,period_id,journal_date,narrative) VALUES(jnl_id,prd_id,current_date,'Reinbursed Kshs(' || NEW.amount_reinbursed || ') to  ' || COALESCE(rec_borrower.borrower_name,rec_borrower.entity_name));
	    --gl entry
	    --a. DR: increase Asset(expenses)
	    SELECT account_id INTO acc_id FROM accounts WHERE upper(account_name) = 'BORROWERS';	
	    INSERT INTO gls(journal_id, account_id, debit, credit) VALUES(jnl_id,acc_id,NEW.amount_reinbursed,0.0);		

	    --b.i CR: decrease in asset(bank)
	    SELECT account_id INTO acc_id FROM accounts WHERE upper(account_name) = 'BANK';	
	    INSERT INTO gls(journal_id, account_id, debit, credit) VALUES(jnl_id,acc_id,0.0,NEW.amount_reinbursed);

	    --b.ii CR: increase in revenue(CHARGES)
	    SELECT fee_value INTO fee_charge FROM fees WHERE upper(fee_name) = 'PROCESSING FEE';	--STOP GAP

	    SELECT account_id INTO acc_id FROM accounts WHERE upper(account_name) = 'CHARGES';	
	    INSERT INTO gls(journal_id, account_id, debit, credit) VALUES(jnl_id,acc_id,0.0,fee_charge);				

	ELSIF (TG_OP = 'UPDATE') THEN
	ELSIF (TG_OP = 'DELETE') THEN	      
	END IF;

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trPostReinbursement AFTER INSERT OR UPDATE OR DELETE ON loan_reinbursment
    FOR EACH ROW EXECUTE PROCEDURE postReinbursement();



--5. Loan Repayment
--CR Asset(borrower), DR Asset(bank): CR revenue(interest), DR Asset(bank)

CREATE OR REPLACE FUNCTION postRepayment() RETURNS trigger AS $$
DECLARE

	prd_id		integer;
	jnl_id		integer;
	acc_id		integer;
	fee_charge	real;
	
	rec_investor RECORD;
	rec_borrower RECORD;
BEGIN
	jnl_id := nextval('journals_journal_id_seq');
	--SELECT getperiodid(CURRENT_DATE) INT prd_id;	
	SELECT MAX(period_id) INTO prd_id FROM periods;	--STOP GAP
	
	SELECT entity_name,borrower_name INTO rec_borrower FROM vwborrower WHERE borrower_id = (SELECT MAX(borrower_id) FROM loans WHERE loan_id = NEW.loan_id);	
	
	IF (TG_OP = 'INSERT') THEN
	  			

	ELSIF (TG_OP = 'UPDATE') THEN
	    --journal entry
	    IF (NEW.is_paid = TRUE AND NEW.cheque_status_id = 2) THEN		--if paid and cleared

		INSERT INTO journals(journal_id,period_id,journal_date,narrative) VALUES(jnl_id,prd_id,current_date,'Received Installment Kshs(' || NEW.cheque_amount || ') from  ' || COALESCE(rec_borrower.borrower_name,rec_borrower.entity_name));
		--gl entry
		--a. CR: decrease in Asset(borrower)
		SELECT account_id INTO acc_id FROM accounts WHERE upper(account_name) = 'BORROWERS';	
		INSERT INTO gls(journal_id, account_id, debit, credit,gl_narrative) VALUES(jnl_id,acc_id,0.0,NEW.principal_component,'principal component of the monthly installment');		

		--b. DR: increase in asset(bank)
		SELECT account_id INTO acc_id FROM accounts WHERE upper(account_name) = 'BANK';	
		INSERT INTO gls(journal_id, account_id, debit, credit, gl_narrative) VALUES(jnl_id,acc_id,NEW.principal_component,0.0, 'principal component of the monthly installment');

		--c. CR: increase in revenue(loan interest)
		SELECT account_id INTO acc_id FROM accounts WHERE upper(account_name) = 'LOAN INTEREST';	
		INSERT INTO gls(journal_id, account_id, debit, credit, gl_narrative) VALUES(jnl_id,acc_id,0.0, NEW.interest_component, 'interest component');

		--d. DR: increase in asset(bank)
		SELECT account_id INTO acc_id FROM accounts WHERE upper(account_name) = 'BANK';	
		INSERT INTO gls(journal_id, account_id, debit, credit, gl_narrative) VALUES(jnl_id,acc_id,NEW.interest_component,0.0, 'interest component');

	    END IF;
	  

	ELSIF (TG_OP = 'DELETE') THEN	      
	END IF;

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trPostRepayment AFTER INSERT OR UPDATE OR DELETE ON repayment_table
    FOR EACH ROW EXECUTE PROCEDURE postRepayment();


--6. Reversal of Bounced cheques
--DR Asset(borrowers), CR (Asset Bank): DR Revenue(interest) CR Asset(Bank): CR Revenue(charges) DR Asset(Outstanding Income)
CREATE OR REPLACE FUNCTION postReversal() RETURNS trigger AS $$
DECLARE

	prd_id		integer;
	jnl_id		integer;
	acc_id		integer;
	fee_charge	real;
	
	rec_investor RECORD;
	rec_borrower RECORD;
BEGIN
	jnl_id := nextval('journals_journal_id_seq');
	--SELECT getperiodid(CURRENT_DATE) INT prd_id;	
	SELECT MAX(period_id) INTO prd_id FROM periods;	--STOP GAP
	
	SELECT entity_name,borrower_name INTO rec_borrower FROM vwborrower WHERE borrower_id = (SELECT MAX(borrower_id) FROM loans WHERE loan_id = NEW.loan_id);	
	
	IF (TG_OP = 'INSERT') THEN
	  			

	ELSIF (TG_OP = 'UPDATE') THEN
	    --journal entry
	    IF (NEW.cheque_status_id = 3) THEN		--if dishonoured

		INSERT INTO journals(journal_id,period_id,journal_date,narrative) VALUES(jnl_id,prd_id,current_date,'Reversal of dishonoured cheque No(' || NEW.cheque_number || ') belonging to  ' || COALESCE(rec_borrower.borrower_name,rec_borrower.entity_name));
		--gl entry
		--a. DR: increase in Asset(borrower)
		SELECT account_id INTO acc_id FROM accounts WHERE upper(account_name) = 'BORROWERS';	
		INSERT INTO gls(journal_id, account_id, debit, credit,gl_narrative) VALUES(jnl_id,acc_id,NEW.principal_component,0.0,'reversal. principal component');		

		--b. CR: decrease in asset(bank)
		SELECT account_id INTO acc_id FROM accounts WHERE upper(account_name) = 'BANK';	
		INSERT INTO gls(journal_id, account_id, debit, credit, gl_narrative) VALUES(jnl_id,acc_id,0.0,NEW.principal_component, 'reversal. principal component');

		--c. DR: decrease in revenue(loan interest)
		SELECT account_id INTO acc_id FROM accounts WHERE upper(account_name) = 'LOAN INTEREST';	
		INSERT INTO gls(journal_id, account_id, debit, credit, gl_narrative) VALUES(jnl_id,acc_id, NEW.interest_component, 0.0, 'revearsal. interest income');

		--d.CR: decrease in asset(bank)
		SELECT account_id INTO acc_id FROM accounts WHERE upper(account_name) = 'BANK';	
		INSERT INTO gls(journal_id, account_id, debit, credit, gl_narrative) VALUES(jnl_id,acc_id,0.0,NEW.interest_component, 'reversal. interest income');

		--=======CHARGE A. LATE PAYMENT
		SELECT fee_value INTO fee_charge FROM fees WHERE upper(fee_name) = 'LATE PAYMENT FEE';	--10% of cheque amount. not less than 1500
		--f. CR: increase in revenue(charges)
		SELECT account_id INTO acc_id FROM accounts WHERE upper(account_name) = 'CHARGES';	
		INSERT INTO gls(journal_id, account_id, debit, credit, gl_narrative) VALUES(jnl_id, acc_id,  0.0, fee_charge, 'late payment penalty');				

		--E. DR: increase in asset(outstanding income)		
		SELECT account_id INTO acc_id FROM accounts WHERE upper(account_name) = 'OUTSTANDING INCOME';	
		INSERT INTO gls(journal_id, account_id, debit, credit, gl_narrative) VALUES(jnl_id, acc_id, fee_charge, 0.0, 'late payment penalty');				
		
		--========CHARGE B. BANK CHARGES
		SELECT fee_value INTO fee_charge FROM fees WHERE upper(fee_name) = 'BOUNCED CHEQUE FEE';	--3000
		--f. CR: increase in revenue(charges)
		SELECT account_id INTO acc_id FROM accounts WHERE upper(account_name) = 'CHARGES';	
		INSERT INTO gls(journal_id, account_id, debit, credit, gl_narrative) VALUES(jnl_id, acc_id,  0.0, fee_charge, 'bounced cheque fee. bank charge');				

		--E. DR: increase in asset(outstanding income)		
		SELECT account_id INTO acc_id FROM accounts WHERE upper(account_name) = 'OUTSTANDING INCOME';	
		INSERT INTO gls(journal_id, account_id, debit, credit, gl_narrative) VALUES(jnl_id, acc_id, fee_charge, 0.0, 'bounced cheque fee. bank charge');				
		
		--=======CHARGE C. DEBT COLLECTION FEE
		SELECT fee_value INTO fee_charge FROM fees WHERE upper(fee_name) = 'DEBT COLLECTION FEE';	--15% of cheque amount. not less than 3000
		--f. CR: increase in revenue(charges)
		SELECT account_id INTO acc_id FROM accounts WHERE upper(account_name) = 'CHARGES';	
		INSERT INTO gls(journal_id, account_id, debit, credit, gl_narrative) VALUES(jnl_id, acc_id, 0.0, fee_charge, 'debt collection fee');				

		--E. DR: increase in asset(outstanding income)		
		SELECT account_id INTO acc_id FROM accounts WHERE upper(account_name) = 'OUTSTANDING INCOME';	
		INSERT INTO gls(journal_id, account_id, debit, credit, gl_narrative) VALUES(jnl_id, acc_id, fee_charge, 0.0, 'debt colletion fee');				
		

	    END IF;
	  

	ELSIF (TG_OP = 'DELETE') THEN	      
	END IF;

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trPostReversal AFTER INSERT OR UPDATE OR DELETE ON repayment_table
    FOR EACH ROW EXECUTE PROCEDURE postReversal();

