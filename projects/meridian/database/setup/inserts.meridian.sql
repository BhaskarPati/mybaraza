--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

--
-- Name: plpgsql; Type: PROCEDURAL LANGUAGE; Schema: -; Owner: root
--

CREATE OR REPLACE PROCEDURAL LANGUAGE plpgsql;


ALTER PROCEDURAL LANGUAGE plpgsql OWNER TO root;

SET search_path = public, pg_catalog;

--
-- Name: change_password(integer, character varying, character varying); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION change_password(integer, character varying, character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE
	old_password varchar(64);
	passchange varchar(120);
BEGIN
	passchange := 'Password Error';
	SELECT Entity_password INTO old_password
	FROM entitys WHERE (entity_ID = $1);

	IF ($2 is null) THEN
		passchange := first_password();
		UPDATE entitys SET first_password = passchange, Entity_password = md5(passchange) WHERE (entity_ID = $1);
		passchange := 'Password Changed';
	ELSIF (old_password = md5($2)) THEN
		UPDATE entitys SET Entity_password = md5($3) WHERE (entity_ID = $1);
		passchange := 'Password Changed';
	ELSE
		passchange := 'Password Changing Error Ensure you have correct details';
	END IF;

	return passchange;
END;
$_$;


ALTER FUNCTION public.change_password(integer, character varying, character varying) OWNER TO root;

--
-- Name: chequeapproval(character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION chequeapproval(character varying, character varying, character varying, character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$

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
	IF(approval = 'Confirm')  THEN

		UPDATE repayment_table SET is_confirmed = true
		WHERE repayment_table_id = CAST(keyfield as int);
	
	ELSIF(approval = 'Decline')  THEN
		UPDATE repayment_table SET is_confirmed = false
		WHERE repayment_table_id = CAST(keyfield as int);
	
	END IF;
		
RETURN approval;

END;
$_$;


ALTER FUNCTION public.chequeapproval(character varying, character varying, character varying, character varying) OWNER TO root;

--
-- Name: createrepaymenttable(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION createrepaymenttable() RETURNS trigger
    LANGUAGE plpgsql
    AS $$		 
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
$$;


ALTER FUNCTION public.createrepaymenttable() OWNER TO root;

--
-- Name: emailed(integer, character varying); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION emailed(integer, character varying) RETURNS void
    LANGUAGE sql
    AS $_$
    UPDATE sys_emailed SET emailed = true WHERE (sys_emailed_id = CAST($2 as int));
$_$;


ALTER FUNCTION public.emailed(integer, character varying) OWNER TO root;

--
-- Name: first_password(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION first_password() RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE
	rnd integer;
	passchange varchar(12);
BEGIN
	passchange := trunc(random()*1000);
	rnd := trunc(65+random()*25);
	passchange := passchange || chr(rnd);
	passchange := passchange || trunc(random()*1000);
	rnd := trunc(65+random()*25);
	passchange := passchange || chr(rnd);
	rnd := trunc(65+random()*25);
	passchange := passchange || chr(rnd);

	return passchange;
END;
$$;


ALTER FUNCTION public.first_password() OWNER TO root;

--
-- Name: geteffectiveloan(integer); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION geteffectiveloan(integer) RETURNS real
    LANGUAGE sql
    AS $_$

	SELECT CAST (principal + (principal * interest * 12/100) + credit_charge + legal_fee + valuation_fee + trasfer_fee AS REAL)
	FROM loans
	WHERE (loan_id = $1);

$_$;


ALTER FUNCTION public.geteffectiveloan(integer) OWNER TO root;

--
-- Name: geteffectiveloan(integer, integer); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION geteffectiveloan(integer, integer) RETURNS real
    LANGUAGE sql
    AS $_$

	SELECT CAST (principal + (principal * interest * $2/100) AS REAL)
	FROM loans
	WHERE (loan_id = $1);

$_$;


ALTER FUNCTION public.geteffectiveloan(integer, integer) OWNER TO root;

--
-- Name: getloanperiodbalance(real, real, integer, real); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION getloanperiodbalance(real, real, integer, real) RETURNS real
    LANGUAGE plpgsql
    AS $_$
DECLARE
	loanbalance real;
	ri real;

	A 		real;		--principal (loan amount)
	n		integer;	--elapsed periods !!1
	P		real;		--the amount of each equal payment aka emi
	B		real;		--loan balance
BEGIN
	A	:= $1;
	n	:= $3;
	P	:= $4;

	--ri := 1 + ($2/1200);	--this works if we are computing interest p.a
	ri := 1 + ($2/100);

	--source: http://oakroadsystems.com/math/loan.htm
	--B = A(1+ri)^n - P/ri[(1+ri)^n - 1]			--NB: For a savings account or other investment, just change the first minus sign to a plus.
	--simplified to : B = A(ri)^n - P/ri[(ri)^n - 1]		--since ri = 1+i/1200
	loanbalance := A * (ri ^ n) - (P * ((ri ^ n)  - 1) / (ri - 1));		--this formula yields the same result as the one below

	--loanbalance := $1 * (ri ^ $3) - ($4 * ((ri ^ $3)  - 1) / (ri - 1));		--this is the original formula..less readable
		
	RETURN loanbalance;
END;
$_$;


ALTER FUNCTION public.getloanperiodbalance(real, real, integer, real) OWNER TO root;

--
-- Name: getpaymentperiod(real, real, real); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION getpaymentperiod(real, real, real) RETURNS real
    LANGUAGE plpgsql
    AS $_$
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
	

	--q := intr/1200;		--if interest is p.a
	q := intr/100;

	IF (emi > (q * princ)) THEN
	  paymentperiod := (log(emi) - log(emi - (q * princ))) / (log(q + 1));				--TRIED AND TESTED OK
	ELSE
	  paymentperiod := 1;
	END IF;

	RETURN paymentperiod;
END;
$_$;


ALTER FUNCTION public.getpaymentperiod(real, real, real) OWNER TO root;

--
-- Name: getperiodid(date); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION getperiodid(date) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
	DECLARE
		myrec RECORD;
	BEGIN
		SELECT period_id, period_start, period_end INTO myrec 
		FROM periods
		WHERE (period_start <= $1) AND (period_start >= $1);	
	
		--may return null if non-existent
		RETURN COALESCE(myrec.period_id,-1);
	END;

$_$;


ALTER FUNCTION public.getperiodid(date) OWNER TO root;

--
-- Name: getrepayment(real, real, integer); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION getrepayment(real, real, integer) RETURNS real
    LANGUAGE plpgsql
    AS $_$
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
	
	--ri := 1 + (intr/1200);		--1200 => intr/12 * 100 works when interest is applied p.a
	ri := 1 + (intr/100);
		
	emi := princ * (ri ^ repay_period) * (ri - 1) / ((ri ^ repay_period) - 1);		--tried and tested ok
	
	--EMI Formula : l x r [(1+r)^n /(1+r)^n-1 ] x 1/12 				
	--l = loan amount
	--r = rate of interest
	--n = term of the loan

	
	RETURN emi;
END;
$_$;


ALTER FUNCTION public.getrepayment(real, real, integer) OWNER TO root;

--
-- Name: getsimpleperiodbalance(integer, integer); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION getsimpleperiodbalance(integer, integer) RETURNS real
    LANGUAGE plpgsql
    AS $_$

DECLARE
	ln_id		integer;
	n_th		integer;
	eff_loan	real;		--loan + interest	
	sum_repayments	real;		--all repayments so far
	--loan_balance 	real;		
	

BEGIN
	ln_id	:= $1;
	n_th	:= $2;

	SELECT geteffectiveloan(ln_id) INTO eff_loan;

	SELECT COALESCE(SUM(cheque_amount),0) INTO sum_repayments FROM repayment_table 
	WHERE loan_id = ln_id AND loan_period < n_th;		--AND is_paid = true;
	

	RETURN eff_loan - sum_repayments;

END;
$_$;


ALTER FUNCTION public.getsimpleperiodbalance(integer, integer) OWNER TO root;

--
-- Name: getsimpleperiodbalance(integer, integer, real); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION getsimpleperiodbalance(integer, integer, real) RETURNS real
    LANGUAGE plpgsql
    AS $_$

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
	    (select generate_series(1,n_th) as n, instalment as emi)s;

	RETURN eff_loan - sum_repayments;

END;
$_$;


ALTER FUNCTION public.getsimpleperiodbalance(integer, integer, real) OWNER TO root;

--
-- Name: gettax(integer, real); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION gettax(integer, real) RETURNS real
    LANGUAGE sql
    AS $_$

	SELECT CAST((COALESCE(tax.tax_rate,-1)/100 * $2) AS REAL)
	FROM tax
	WHERE tax_id = $1;
	
$_$;


ALTER FUNCTION public.gettax(integer, real) OWNER TO root;

--
-- Name: gettotalinterest(integer); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION gettotalinterest(integer) RETURNS real
    LANGUAGE sql
    AS $_$
	SELECT CASE WHEN sum(interest_amount) is NULL THEN 0 ELSE sum(interest_amount) END 
		FROM loan_monthly
		WHERE (loan_id = $1);
$_$;


ALTER FUNCTION public.gettotalinterest(integer) OWNER TO root;

--
-- Name: gettotalinvestmentdeductions(integer); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION gettotalinvestmentdeductions(integer) RETURNS real
    LANGUAGE sql
    AS $_$

	SELECT COALESCE(SUM(deduction.deduction_amount),0) 
	FROM deduction
	WHERE investment_id = $1;
	
$_$;


ALTER FUNCTION public.gettotalinvestmentdeductions(integer) OWNER TO root;

--
-- Name: gettotalpenalty(integer); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION gettotalpenalty(integer) RETURNS real
    LANGUAGE sql
    AS $_$
	SELECT 
		CASE WHEN sum(penalty) is NULL 
				THEN 0 
			ELSE sum(penalty) 
		END 
		FROM loan_monthly
		WHERE (loan_id = $1);
$_$;


ALTER FUNCTION public.gettotalpenalty(integer) OWNER TO root;

--
-- Name: gettotalrepayment(integer); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION gettotalrepayment(integer) RETURNS real
    LANGUAGE sql
    AS $_$
	SELECT COALESCE(SUM(repayment + interest_paid),0)
	FROM loan_monthly
	WHERE (loan_id = $1);
	$_$;


ALTER FUNCTION public.gettotalrepayment(integer) OWNER TO root;

--
-- Name: ins_borrower(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION ins_borrower() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.ins_borrower() OWNER TO root;

--
-- Name: ins_contact(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION ins_contact() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	rec RECORD;
BEGIN
	--entity types 0=root,1=staff, 2=client, 3=supplier, 5=partner,7=Admin, 8=spouse,9=referee, 10=investor

	IF (TG_OP = 'INSERT') THEN
		IF(NEW.entity_id IS NULL) THEN
			SELECT org_id INTO rec
			FROM orgs WHERE (is_default = true);	

			NEW.entity_id := nextval('entitys_entity_id_seq');

			IF(NEW.borrower_contact_id is null) THEN
				NEW.borrower_contact_id := NEW.entity_id;
			END IF;

			INSERT INTO entitys (entity_id, org_id, entity_type_id, entity_name, User_name, Function_Role)
			VALUES (NEW.entity_id, rec.org_id, 8, 
				(NEW.sur_name || ' ' || NEW.first_name || ' ' || COALESCE(NEW.middle_name, '')),
				lower(substring(NEW.first_name from 1 for 1) || NEW.sur_name), 'alternativecontact');
		END IF;
	ELSIF (TG_OP = 'UPDATE') THEN
		UPDATE entitys  SET entity_name = (NEW.sur_name || ' ' || NEW.first_name || ' ' || COALESCE(NEW.middle_name, ''))
		WHERE entity_id = NEW.entity_id;
	END IF;

	RETURN NEW;
END;
$$;


ALTER FUNCTION public.ins_contact() OWNER TO root;

--
-- Name: ins_entitys(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION ins_entitys() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN	
	IF(NEW.entity_type_id is not null) THEN
		INSERT INTO Entity_subscriptions (entity_type_id, entity_id, subscription_level_id)
		VALUES (NEW.entity_type_id, NEW.entity_id, 0);
	END IF;

	RETURN NULL;
END;
$$;


ALTER FUNCTION public.ins_entitys() OWNER TO root;

--
-- Name: ins_entry_form(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION ins_entry_form(character varying, character varying, character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE
	rec RECORD;
	formName varchar(120);
	msg varchar(120);
BEGIN
	SELECT entry_form_id INTO rec
	FROM entry_forms 
	WHERE (form_id = CAST($1 as int)) AND (entity_ID = CAST($2 as int))
		AND (completed = '0');

	SELECT form_name INTO formName FROM forms WHERE (form_id = CAST($1 as int));

	IF rec.entry_form_id is null THEN
		INSERT INTO entry_forms (form_id, entity_id) VALUES (CAST($1 as int), CAST($2 as int));
		msg := 'Added Form : ' || formName;
	ELSE
		msg := 'There is an incomplete form : ' || formName;
	END IF;

	return msg;
END;
$_$;


ALTER FUNCTION public.ins_entry_form(character varying, character varying, character varying) OWNER TO root;

--
-- Name: ins_investor(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION ins_investor() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.ins_investor() OWNER TO root;

--
-- Name: ins_partner(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION ins_partner() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.ins_partner() OWNER TO root;

--
-- Name: ins_password(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION ins_password() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF(NEW.first_password is null) THEN
		NEW.first_password := first_password();
	END IF;
	NEW.Entity_password := md5(NEW.first_password);

	RETURN NEW;
END;
$$;


ALTER FUNCTION public.ins_password() OWNER TO root;

--
-- Name: insmonthly(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION insmonthly() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

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
$$;


ALTER FUNCTION public.insmonthly() OWNER TO postgres;

--
-- Name: loanapproval(character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION loanapproval(character varying, character varying, character varying, character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$

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
$_$;


ALTER FUNCTION public.loanapproval(character varying, character varying, character varying, character varying) OWNER TO root;

--
-- Name: postaddinvestment(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION postaddinvestment() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.postaddinvestment() OWNER TO root;

--
-- Name: postcommissionpayment(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION postcommissionpayment() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.postcommissionpayment() OWNER TO root;

--
-- Name: postreduceinvestment(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION postreduceinvestment() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.postreduceinvestment() OWNER TO root;

--
-- Name: postreinbursement(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION postreinbursement() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.postreinbursement() OWNER TO root;

--
-- Name: postrepayment(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION postrepayment() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.postrepayment() OWNER TO root;

--
-- Name: postreversal(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION postreversal() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
		SELECT fee_value INTO fee_charge FROM fees WHERE upper(fee_name) = 'LATE PAYMENT FEE';	--STOP GAP
		--f. CR: increase in revenue(charges)
		SELECT account_id INTO acc_id FROM accounts WHERE upper(account_name) = 'CHARGES';	
		INSERT INTO gls(journal_id, account_id, debit, credit, gl_narrative) VALUES(jnl_id, acc_id,  0.0, fee_charge, 'late payment penalty');				

		--E. DR: increase in asset(outstanding income)		
		SELECT account_id INTO acc_id FROM accounts WHERE upper(account_name) = 'OUTSTANDING INCOME';	
		INSERT INTO gls(journal_id, account_id, debit, credit, gl_narrative) VALUES(jnl_id, acc_id, fee_charge, 0.0, 'late payment penalty');				
		
		--========CHARGE B. BANK CHARGES
		SELECT fee_value INTO fee_charge FROM fees WHERE upper(fee_name) = 'BOUNCED CHEQUE FEE';	--STOP GAP
		--f. CR: increase in revenue(charges)
		SELECT account_id INTO acc_id FROM accounts WHERE upper(account_name) = 'CHARGES';	
		INSERT INTO gls(journal_id, account_id, debit, credit, gl_narrative) VALUES(jnl_id, acc_id,  0.0, fee_charge, 'bounced cheque fee. bank charge');				

		--E. DR: increase in asset(outstanding income)		
		SELECT account_id INTO acc_id FROM accounts WHERE upper(account_name) = 'OUTSTANDING INCOME';	
		INSERT INTO gls(journal_id, account_id, debit, credit, gl_narrative) VALUES(jnl_id, acc_id, fee_charge, 0.0, 'bounced cheque fee. bank charge');				
		
		--=======CHARGE C. DEBT COLLECTION FEE
		SELECT fee_value INTO fee_charge FROM fees WHERE upper(fee_name) = 'DEBT COLLECTION FEE';	--STOP GAP
		--f. CR: increase in revenue(charges)
		SELECT account_id INTO acc_id FROM accounts WHERE upper(account_name) = 'CHARGES';	
		INSERT INTO gls(journal_id, account_id, debit, credit, gl_narrative) VALUES(jnl_id, acc_id,  0.0, fee_charge, 'debt collection fee');				

		--E. DR: increase in asset(outstanding income)		
		SELECT account_id INTO acc_id FROM accounts WHERE upper(account_name) = 'OUTSTANDING INCOME';	
		INSERT INTO gls(journal_id, account_id, debit, credit, gl_narrative) VALUES(jnl_id, acc_id, fee_charge, 0.0, 'debt colletion fee');				
		

	    END IF;
	  

	ELSIF (TG_OP = 'DELETE') THEN	      
	END IF;

	RETURN NULL;
END;
$$;


ALTER FUNCTION public.postreversal() OWNER TO root;

--
-- Name: process_journal(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION process_journal(character varying, character varying, character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
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
$_$;


ALTER FUNCTION public.process_journal(character varying, character varying, character varying) OWNER TO root;

--
-- Name: upd_complete_form(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION upd_complete_form(character varying, character varying, character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE
	msg varchar(120);
BEGIN
	IF ($3 = '1') THEN
		UPDATE entry_forms SET completed = '1', completion_date	= now()
		WHERE (entry_form_id = CAST($1 as int));
		msg := 'Completed the form';
	ELSIF ($3 = '2') THEN
		UPDATE entry_forms SET approved = '1', approve_date = now()
		WHERE (entry_form_id = CAST($1 as int));
		msg := 'Approved the form';
	ELSIF ($3 = '3') THEN
		UPDATE entry_forms SET rejected = '1', approve_date = now()
		WHERE (entry_form_id = CAST($1 as int));
		msg := 'Rejected the form';
	END IF;

	return msg;
END;
$_$;


ALTER FUNCTION public.upd_complete_form(character varying, character varying, character varying) OWNER TO root;

--
-- Name: upd_gls(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION upd_gls() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.upd_gls() OWNER TO root;

--
-- Name: updateloan(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION updateloan() RETURNS trigger
    LANGUAGE plpgsql
    AS $$		 
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
$$;


ALTER FUNCTION public.updateloan() OWNER TO root;

--
-- Name: updrepaymenttable(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION updrepaymenttable() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.updrepaymenttable() OWNER TO root;

--
-- Name: validateamountin(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION validateamountin() RETURNS trigger
    LANGUAGE plpgsql
    AS $$		 

BEGIN

	--IF TG_OP='INSERT' THEN
		IF NEW.amountin != NEW.sharecapital + NEW.savings THEN
			RAISE EXCEPTION 'Total Amount must be equal to Savings + Share Contribution. ABORTED';
		END IF;
	--END IF;

	RETURN NEW;

END;
$$;


ALTER FUNCTION public.validateamountin() OWNER TO root;

--
-- Name: validateloan(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION validateloan() RETURNS trigger
    LANGUAGE plpgsql
    AS $$		 
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
$$;


ALTER FUNCTION public.validateloan() OWNER TO root;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: account_types; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE account_types (
    account_type_id integer NOT NULL,
    accounts_class_id integer,
    account_type_name character varying(50) NOT NULL,
    details text
);


ALTER TABLE public.account_types OWNER TO root;

--
-- Name: accounts; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE accounts (
    account_id integer NOT NULL,
    account_type_id integer,
    account_name character varying(50) NOT NULL,
    is_header boolean DEFAULT false NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    details text,
    is_bank_acc boolean DEFAULT false,
    bank_branch_id integer,
    bank_account_number character varying(50)
);


ALTER TABLE public.accounts OWNER TO root;

--
-- Name: accounts_account_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE accounts_account_id_seq
    START WITH 100000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.accounts_account_id_seq OWNER TO root;

--
-- Name: accounts_account_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('accounts_account_id_seq', 100000, false);


--
-- Name: accounts_class; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE accounts_class (
    accounts_class_id integer NOT NULL,
    chat_type_id integer NOT NULL,
    chat_type_name character varying(50) NOT NULL,
    accounts_class_name character varying(50) NOT NULL,
    details text
);


ALTER TABLE public.accounts_class OWNER TO root;

--
-- Name: address; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE address (
    address_id integer NOT NULL,
    address_name character varying(120),
    sys_country_id character(2),
    table_name character varying(32),
    table_id integer,
    post_office_box character varying(50),
    postal_code character varying(12),
    premises character varying(120),
    street character varying(120),
    town character varying(50),
    phone_number character varying(150),
    extension character varying(15),
    mobile character varying(150),
    fax character varying(150),
    email character varying(120),
    is_default boolean,
    first_password character varying(32),
    details text
);


ALTER TABLE public.address OWNER TO root;

--
-- Name: address_address_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE address_address_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.address_address_id_seq OWNER TO root;

--
-- Name: address_address_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE address_address_id_seq OWNED BY address.address_id;


--
-- Name: address_address_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('address_address_id_seq', 1, false);


--
-- Name: approval_phases; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE approval_phases (
    approval_phase_id integer NOT NULL,
    table_name character varying(64),
    entity_type_id integer,
    approval_type_id integer,
    approval_level integer DEFAULT 1 NOT NULL,
    return_level integer DEFAULT 1 NOT NULL,
    escalation_time integer DEFAULT 3 NOT NULL,
    departmental boolean DEFAULT false NOT NULL,
    details text
);


ALTER TABLE public.approval_phases OWNER TO root;

--
-- Name: approval_phases_approval_phase_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE approval_phases_approval_phase_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.approval_phases_approval_phase_id_seq OWNER TO root;

--
-- Name: approval_phases_approval_phase_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE approval_phases_approval_phase_id_seq OWNED BY approval_phases.approval_phase_id;


--
-- Name: approval_phases_approval_phase_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('approval_phases_approval_phase_id_seq', 1, false);


--
-- Name: approval_types; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE approval_types (
    approval_type_id integer NOT NULL,
    approval_type_name character varying(50) NOT NULL,
    details text
);


ALTER TABLE public.approval_types OWNER TO root;

--
-- Name: approval_types_approval_type_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE approval_types_approval_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.approval_types_approval_type_id_seq OWNER TO root;

--
-- Name: approval_types_approval_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE approval_types_approval_type_id_seq OWNED BY approval_types.approval_type_id;


--
-- Name: approval_types_approval_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('approval_types_approval_type_id_seq', 1, false);


--
-- Name: approvals; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE approvals (
    approval_id integer NOT NULL,
    forward_id integer,
    table_id integer,
    approval_phase_id integer,
    entity_id integer,
    escalation_time integer DEFAULT 3 NOT NULL,
    application_date timestamp without time zone DEFAULT now() NOT NULL,
    approved boolean DEFAULT false NOT NULL,
    rejected boolean DEFAULT false NOT NULL,
    action_date timestamp without time zone,
    narrative character varying(240),
    to_be_done text,
    what_is_done text,
    details text
);


ALTER TABLE public.approvals OWNER TO root;

--
-- Name: approvals_approval_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE approvals_approval_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.approvals_approval_id_seq OWNER TO root;

--
-- Name: approvals_approval_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE approvals_approval_id_seq OWNED BY approvals.approval_id;


--
-- Name: approvals_approval_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('approvals_approval_id_seq', 1, false);


--
-- Name: auction; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE auction (
    auction_id integer NOT NULL,
    defaulter_id integer,
    is_complete boolean DEFAULT false,
    details text
);


ALTER TABLE public.auction OWNER TO root;

--
-- Name: auction_auction_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE auction_auction_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.auction_auction_id_seq OWNER TO root;

--
-- Name: auction_auction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE auction_auction_id_seq OWNED BY auction.auction_id;


--
-- Name: auction_auction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('auction_auction_id_seq', 1, false);


--
-- Name: auction_phase; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE auction_phase (
    auction_phase_id integer NOT NULL,
    auction_id integer,
    phase_id integer,
    is_complete boolean DEFAULT false,
    details text
);


ALTER TABLE public.auction_phase OWNER TO root;

--
-- Name: auction_phase_auction_phase_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE auction_phase_auction_phase_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.auction_phase_auction_phase_id_seq OWNER TO root;

--
-- Name: auction_phase_auction_phase_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE auction_phase_auction_phase_id_seq OWNED BY auction_phase.auction_phase_id;


--
-- Name: auction_phase_auction_phase_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('auction_phase_auction_phase_id_seq', 1, false);


--
-- Name: bank; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE bank (
    bank_id integer NOT NULL,
    bank_code character(3),
    banka_bbrev character varying(10),
    bank_name character varying(30),
    details text
);


ALTER TABLE public.bank OWNER TO root;

--
-- Name: bank_bank_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE bank_bank_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.bank_bank_id_seq OWNER TO root;

--
-- Name: bank_bank_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE bank_bank_id_seq OWNED BY bank.bank_id;


--
-- Name: bank_bank_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('bank_bank_id_seq', 5, true);


--
-- Name: bank_branch; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE bank_branch (
    bank_branch_id integer NOT NULL,
    bank_id integer,
    bank_branch_name character varying(50),
    details text
);


ALTER TABLE public.bank_branch OWNER TO root;

--
-- Name: bank_branch_bank_branch_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE bank_branch_bank_branch_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.bank_branch_bank_branch_id_seq OWNER TO root;

--
-- Name: bank_branch_bank_branch_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE bank_branch_bank_branch_id_seq OWNED BY bank_branch.bank_branch_id;


--
-- Name: bank_branch_bank_branch_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('bank_branch_bank_branch_id_seq', 2, true);


--
-- Name: borrower; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE borrower (
    borrower_id integer NOT NULL,
    entity_id integer,
    employer_name character varying(50),
    employment_date date,
    "position" character varying(50),
    employer_box character varying(50),
    employer_town character varying(50),
    employer_tel character varying(50),
    employer_fax character varying(50),
    net_salary real,
    other_income real,
    house_rent real,
    other_expenses real,
    is_self_employed boolean DEFAULT false NOT NULL,
    business_name character varying(50),
    products_services character varying(100),
    physical_address character varying(100),
    office_size_sqft real,
    business_rent real,
    year_started integer,
    turnover_n_1 real,
    turnover_n_2 real,
    turnover_n_3 real,
    net_profit_n_1 real,
    net_profit_n_2 real,
    net_profit_n_3 real,
    details text,
    sur_name character varying(50),
    first_name character varying(50),
    middle_name character varying(50),
    idnumber character varying(50),
    residential_address text,
    estate character varying(50),
    area character varying(50),
    street character varying(50),
    town character varying(50),
    otherremarks text,
    po_box character varying(50),
    postal_code character varying(50),
    post_office character varying(50),
    country character varying(50) DEFAULT 'Kenya'::character varying,
    home_tel_no character varying(50),
    office_tel_no character varying(50),
    mobile_tel character varying(50),
    personal_email character varying(100),
    employer_address text
);


ALTER TABLE public.borrower OWNER TO root;

--
-- Name: borrower_borrower_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE borrower_borrower_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.borrower_borrower_id_seq OWNER TO root;

--
-- Name: borrower_borrower_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE borrower_borrower_id_seq OWNED BY borrower.borrower_id;


--
-- Name: borrower_borrower_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('borrower_borrower_id_seq', 6, true);


--
-- Name: borrower_contact; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE borrower_contact (
    borrower_contact_id integer NOT NULL,
    entity_id integer,
    borrower_id integer,
    employer_name character varying(50),
    employment_date date,
    "position" character varying(50),
    employer_box character varying(50),
    employer_town character varying(50),
    employer_tel character varying(50),
    employer_fax character varying(50),
    details text,
    sur_name character varying(50),
    first_name character varying(50),
    middle_name character varying(50),
    idnumber character varying(50),
    residential_address text,
    estate character varying(50),
    area character varying(50),
    street character varying(50),
    town character varying(50),
    otherremarks text,
    po_box character varying(50),
    postal_code character varying(50),
    post_office character varying(50),
    country character varying(50) DEFAULT 'Kenya'::character varying,
    home_tel_no character varying(50),
    office_tel_no character varying(50),
    mobile_tel character varying(50),
    personal_email character varying(100)
);


ALTER TABLE public.borrower_contact OWNER TO root;

--
-- Name: borrower_contact_borrower_contact_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE borrower_contact_borrower_contact_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.borrower_contact_borrower_contact_id_seq OWNER TO root;

--
-- Name: borrower_contact_borrower_contact_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE borrower_contact_borrower_contact_id_seq OWNED BY borrower_contact.borrower_contact_id;


--
-- Name: borrower_contact_borrower_contact_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('borrower_contact_borrower_contact_id_seq', 1, true);


--
-- Name: cheque_status; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE cheque_status (
    cheque_status_id integer NOT NULL,
    cheque_status_name character varying(50),
    details text
);


ALTER TABLE public.cheque_status OWNER TO root;

--
-- Name: cheque_status_cheque_status_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE cheque_status_cheque_status_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.cheque_status_cheque_status_id_seq OWNER TO root;

--
-- Name: cheque_status_cheque_status_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE cheque_status_cheque_status_id_seq OWNED BY cheque_status.cheque_status_id;


--
-- Name: cheque_status_cheque_status_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('cheque_status_cheque_status_id_seq', 1, false);


--
-- Name: civil_action; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE civil_action (
    civil_action_id integer NOT NULL,
    investigation_id integer,
    is_complete boolean DEFAULT false,
    details text
);


ALTER TABLE public.civil_action OWNER TO root;

--
-- Name: civil_action_civil_action_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE civil_action_civil_action_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.civil_action_civil_action_id_seq OWNER TO root;

--
-- Name: civil_action_civil_action_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE civil_action_civil_action_id_seq OWNED BY civil_action.civil_action_id;


--
-- Name: civil_action_civil_action_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('civil_action_civil_action_id_seq', 1, false);


--
-- Name: collateral; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE collateral (
    collateral_id integer NOT NULL,
    loan_id integer,
    isvehicle boolean DEFAULT true NOT NULL,
    isapproved boolean DEFAULT false NOT NULL,
    vehicle_owner character varying(100),
    vehicle_regno character varying(50),
    make character varying(50),
    model character varying(50),
    bodytype character varying(50),
    color character varying(50),
    engine_number character varying(50),
    chassis_number character varying(50),
    insurer character varying(50),
    policy_no character varying(50),
    insurance_value real,
    valued_by character varying(50),
    narrative text,
    other_collateral text
);


ALTER TABLE public.collateral OWNER TO postgres;

--
-- Name: collateral_collateral_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE collateral_collateral_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.collateral_collateral_id_seq OWNER TO postgres;

--
-- Name: collateral_collateral_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE collateral_collateral_id_seq OWNED BY collateral.collateral_id;


--
-- Name: collateral_collateral_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('collateral_collateral_id_seq', 3, true);


--
-- Name: commission_payment; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE commission_payment (
    commission_payment_id integer NOT NULL,
    investment_maturity_id integer,
    cheque_number character varying(50),
    cheque_amount real,
    cheque_date date,
    is_confirmed boolean DEFAULT false,
    is_paid boolean DEFAULT false,
    details text
);


ALTER TABLE public.commission_payment OWNER TO root;

--
-- Name: commission_payment_commission_payment_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE commission_payment_commission_payment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.commission_payment_commission_payment_id_seq OWNER TO root;

--
-- Name: commission_payment_commission_payment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE commission_payment_commission_payment_id_seq OWNED BY commission_payment.commission_payment_id;


--
-- Name: commission_payment_commission_payment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('commission_payment_commission_payment_id_seq', 7, true);


--
-- Name: deduction; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE deduction (
    deduction_id integer NOT NULL,
    investment_id integer,
    deduction_amount real DEFAULT 0 NOT NULL,
    effective_date date,
    details text
);


ALTER TABLE public.deduction OWNER TO root;

--
-- Name: deduction_deduction_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE deduction_deduction_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.deduction_deduction_id_seq OWNER TO root;

--
-- Name: deduction_deduction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE deduction_deduction_id_seq OWNED BY deduction.deduction_id;


--
-- Name: deduction_deduction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('deduction_deduction_id_seq', 10, true);


--
-- Name: defaulter; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE defaulter (
    defaulter_id integer NOT NULL,
    entity_id integer,
    repayment_table_id integer,
    demand_letter_sent boolean DEFAULT false,
    details text
);


ALTER TABLE public.defaulter OWNER TO root;

--
-- Name: defaulter_defaulter_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE defaulter_defaulter_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.defaulter_defaulter_id_seq OWNER TO root;

--
-- Name: defaulter_defaulter_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE defaulter_defaulter_id_seq OWNED BY defaulter.defaulter_id;


--
-- Name: defaulter_defaulter_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('defaulter_defaulter_id_seq', 1, false);


--
-- Name: entity_subscriptions; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE entity_subscriptions (
    entity_subscription_id integer NOT NULL,
    entity_type_id integer,
    entity_id integer,
    subscription_level_id integer,
    details text
);


ALTER TABLE public.entity_subscriptions OWNER TO root;

--
-- Name: entity_subscriptions_entity_subscription_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE entity_subscriptions_entity_subscription_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.entity_subscriptions_entity_subscription_id_seq OWNER TO root;

--
-- Name: entity_subscriptions_entity_subscription_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE entity_subscriptions_entity_subscription_id_seq OWNED BY entity_subscriptions.entity_subscription_id;


--
-- Name: entity_subscriptions_entity_subscription_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('entity_subscriptions_entity_subscription_id_seq', 19, true);


--
-- Name: entity_types; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE entity_types (
    entity_type_id integer NOT NULL,
    entity_type_name character varying(50),
    entity_role character varying(240),
    use_key integer DEFAULT 0 NOT NULL,
    description text,
    details text
);


ALTER TABLE public.entity_types OWNER TO root;

--
-- Name: entity_types_entity_type_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE entity_types_entity_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.entity_types_entity_type_id_seq OWNER TO root;

--
-- Name: entity_types_entity_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE entity_types_entity_type_id_seq OWNED BY entity_types.entity_type_id;


--
-- Name: entity_types_entity_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('entity_types_entity_type_id_seq', 10, true);


--
-- Name: entitys; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE entitys (
    entity_id integer NOT NULL,
    org_id integer,
    entity_type_id integer,
    entity_name character varying(120) NOT NULL,
    user_name character varying(120),
    super_user boolean DEFAULT false NOT NULL,
    entity_leader boolean DEFAULT false,
    function_role character varying(240),
    date_enroled timestamp without time zone DEFAULT now(),
    is_active boolean DEFAULT true,
    entity_password character varying(32) DEFAULT md5('enter'::text) NOT NULL,
    first_password character varying(32) DEFAULT 'enter'::character varying NOT NULL,
    details text
);


ALTER TABLE public.entitys OWNER TO root;

--
-- Name: entitys_entity_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE entitys_entity_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.entitys_entity_id_seq OWNER TO root;

--
-- Name: entitys_entity_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE entitys_entity_id_seq OWNED BY entitys.entity_id;


--
-- Name: entitys_entity_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('entitys_entity_id_seq', 18, true);


--
-- Name: entry_forms; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE entry_forms (
    entry_form_id integer NOT NULL,
    entity_id integer,
    form_id integer,
    completed character(1) DEFAULT '0'::bpchar NOT NULL,
    approved character(1) DEFAULT '0'::bpchar NOT NULL,
    rejected character(1) DEFAULT '0'::bpchar NOT NULL,
    application_date timestamp without time zone DEFAULT now() NOT NULL,
    completion_date timestamp without time zone,
    approve_date timestamp without time zone,
    narrative character varying(240),
    answer text,
    details text
);


ALTER TABLE public.entry_forms OWNER TO root;

--
-- Name: entry_forms_entry_form_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE entry_forms_entry_form_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.entry_forms_entry_form_id_seq OWNER TO root;

--
-- Name: entry_forms_entry_form_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE entry_forms_entry_form_id_seq OWNED BY entry_forms.entry_form_id;


--
-- Name: entry_forms_entry_form_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('entry_forms_entry_form_id_seq', 1, false);


--
-- Name: entry_sub_forms; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE entry_sub_forms (
    entry_sub_form_id integer NOT NULL,
    entry_form_id integer,
    sub_field_id integer,
    answer text
);


ALTER TABLE public.entry_sub_forms OWNER TO root;

--
-- Name: entry_sub_forms_entry_sub_form_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE entry_sub_forms_entry_sub_form_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.entry_sub_forms_entry_sub_form_id_seq OWNER TO root;

--
-- Name: entry_sub_forms_entry_sub_form_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE entry_sub_forms_entry_sub_form_id_seq OWNED BY entry_sub_forms.entry_sub_form_id;


--
-- Name: entry_sub_forms_entry_sub_form_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('entry_sub_forms_entry_sub_form_id_seq', 1, false);


--
-- Name: fee_type; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE fee_type (
    fee_type_id integer NOT NULL,
    fee_type_name character varying(20),
    details text
);


ALTER TABLE public.fee_type OWNER TO root;

--
-- Name: fee_type_fee_type_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE fee_type_fee_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.fee_type_fee_type_id_seq OWNER TO root;

--
-- Name: fee_type_fee_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE fee_type_fee_type_id_seq OWNED BY fee_type.fee_type_id;


--
-- Name: fee_type_fee_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('fee_type_fee_type_id_seq', 2, true);


--
-- Name: fees; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE fees (
    fee_id integer NOT NULL,
    fee_code character varying(10),
    fee_name character varying(50),
    fee_description character varying(200),
    details text,
    fee_type_id integer,
    fee_value real DEFAULT 0 NOT NULL,
    minimum_charge real DEFAULT 0
);


ALTER TABLE public.fees OWNER TO root;

--
-- Name: fees_fee_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE fees_fee_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.fees_fee_id_seq OWNER TO root;

--
-- Name: fees_fee_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE fees_fee_id_seq OWNED BY fees.fee_id;


--
-- Name: fees_fee_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('fees_fee_id_seq', 6, true);


--
-- Name: fields; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE fields (
    field_id integer NOT NULL,
    form_id integer,
    question text,
    field_lookup text,
    field_type character varying(25) NOT NULL,
    field_class character varying(25),
    field_bold character(1) DEFAULT '0'::bpchar NOT NULL,
    field_italics character(1) DEFAULT '0'::bpchar NOT NULL,
    field_order integer DEFAULT 1,
    share_line integer,
    field_size integer DEFAULT 25 NOT NULL,
    manditory character(1) DEFAULT '0'::bpchar NOT NULL,
    show character(1) DEFAULT '1'::bpchar
);


ALTER TABLE public.fields OWNER TO root;

--
-- Name: fields_field_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE fields_field_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.fields_field_id_seq OWNER TO root;

--
-- Name: fields_field_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE fields_field_id_seq OWNED BY fields.field_id;


--
-- Name: fields_field_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('fields_field_id_seq', 1, false);


--
-- Name: fiscal_years; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE fiscal_years (
    fiscal_year_id character varying(9) NOT NULL,
    fiscal_year_start date NOT NULL,
    fiscal_year_end date NOT NULL,
    year_opened boolean DEFAULT true NOT NULL,
    year_closed boolean DEFAULT false NOT NULL,
    details text
);


ALTER TABLE public.fiscal_years OWNER TO root;

--
-- Name: forms; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE forms (
    form_id integer NOT NULL,
    org_id integer,
    form_name character varying(240) NOT NULL,
    form_number character varying(50),
    version character varying(25),
    completed character(1) DEFAULT '0'::bpchar NOT NULL,
    is_active character(1) DEFAULT '0'::bpchar NOT NULL,
    form_header text,
    form_footer text,
    details text
);


ALTER TABLE public.forms OWNER TO root;

--
-- Name: forms_form_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE forms_form_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.forms_form_id_seq OWNER TO root;

--
-- Name: forms_form_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE forms_form_id_seq OWNED BY forms.form_id;


--
-- Name: forms_form_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('forms_form_id_seq', 1, false);


--
-- Name: gls; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE gls (
    gl_id integer NOT NULL,
    journal_id integer NOT NULL,
    account_id integer NOT NULL,
    debit real DEFAULT 0 NOT NULL,
    credit real DEFAULT 0 NOT NULL,
    gl_narrative character varying(240),
    action_date date DEFAULT ('now'::text)::date
);


ALTER TABLE public.gls OWNER TO root;

--
-- Name: gls_gl_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE gls_gl_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.gls_gl_id_seq OWNER TO root;

--
-- Name: gls_gl_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE gls_gl_id_seq OWNED BY gls.gl_id;


--
-- Name: gls_gl_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('gls_gl_id_seq', 95, true);


--
-- Name: investigation; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE investigation (
    investigation_id integer NOT NULL,
    defaulter_id integer,
    is_complete boolean DEFAULT false,
    details text
);


ALTER TABLE public.investigation OWNER TO root;

--
-- Name: investigation_investigation_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE investigation_investigation_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.investigation_investigation_id_seq OWNER TO root;

--
-- Name: investigation_investigation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE investigation_investigation_id_seq OWNED BY investigation.investigation_id;


--
-- Name: investigation_investigation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('investigation_investigation_id_seq', 1, false);


--
-- Name: investment; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE investment (
    investment_id integer NOT NULL,
    investor_id integer,
    investment_type_id integer,
    principal real NOT NULL,
    credit_charge real DEFAULT 0 NOT NULL,
    legal_fee real DEFAULT 0 NOT NULL,
    valuation_fee real DEFAULT 0 NOT NULL,
    trasfer_fee real DEFAULT 0 NOT NULL,
    investment_date date DEFAULT ('now'::text)::date NOT NULL,
    monthly_repayment real,
    is_approved boolean DEFAULT false NOT NULL,
    details text,
    account_id integer,
    CONSTRAINT investment_principal_check CHECK ((principal > (0)::double precision))
);


ALTER TABLE public.investment OWNER TO postgres;

--
-- Name: investment_investment_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE investment_investment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.investment_investment_id_seq OWNER TO postgres;

--
-- Name: investment_investment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE investment_investment_id_seq OWNED BY investment.investment_id;


--
-- Name: investment_investment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('investment_investment_id_seq', 19, true);


--
-- Name: investment_maturity; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE investment_maturity (
    investment_maturity_id integer NOT NULL,
    investment_id integer,
    period_id integer,
    mature_amount real NOT NULL,
    interest_amount real NOT NULL,
    details text
);


ALTER TABLE public.investment_maturity OWNER TO root;

--
-- Name: investment_maturity_investment_maturity_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE investment_maturity_investment_maturity_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.investment_maturity_investment_maturity_id_seq OWNER TO root;

--
-- Name: investment_maturity_investment_maturity_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE investment_maturity_investment_maturity_id_seq OWNED BY investment_maturity.investment_maturity_id;


--
-- Name: investment_maturity_investment_maturity_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('investment_maturity_investment_maturity_id_seq', 35, true);


--
-- Name: investment_type; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE investment_type (
    investment_type_id integer NOT NULL,
    investment_type_name character varying(50),
    details text,
    default_interest real DEFAULT 3.5 NOT NULL
);


ALTER TABLE public.investment_type OWNER TO root;

--
-- Name: investment_type_investment_type_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE investment_type_investment_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.investment_type_investment_type_id_seq OWNER TO root;

--
-- Name: investment_type_investment_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE investment_type_investment_type_id_seq OWNED BY investment_type.investment_type_id;


--
-- Name: investment_type_investment_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('investment_type_investment_type_id_seq', 3, true);


--
-- Name: investor; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE investor (
    investor_id integer NOT NULL,
    entity_id integer,
    details text,
    sur_name character varying(50),
    first_name character varying(50),
    middle_name character varying(50)
);


ALTER TABLE public.investor OWNER TO root;

--
-- Name: investor_investor_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE investor_investor_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.investor_investor_id_seq OWNER TO root;

--
-- Name: investor_investor_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE investor_investor_id_seq OWNED BY investor.investor_id;


--
-- Name: investor_investor_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('investor_investor_id_seq', 5, true);


--
-- Name: journals; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE journals (
    journal_id integer NOT NULL,
    period_id integer NOT NULL,
    journal_date date NOT NULL,
    posted boolean DEFAULT false NOT NULL,
    narrative character varying(240),
    details text
);


ALTER TABLE public.journals OWNER TO root;

--
-- Name: journals_journal_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE journals_journal_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.journals_journal_id_seq OWNER TO root;

--
-- Name: journals_journal_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE journals_journal_id_seq OWNED BY journals.journal_id;


--
-- Name: journals_journal_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('journals_journal_id_seq', 297, true);


--
-- Name: loan_monthly; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE loan_monthly (
    loanmonth_id integer NOT NULL,
    loan_id integer,
    period_id integer,
    interest_amount real NOT NULL,
    repayment real NOT NULL,
    interest_paid real DEFAULT 0 NOT NULL,
    penalty real DEFAULT 0 NOT NULL,
    details text
);


ALTER TABLE public.loan_monthly OWNER TO postgres;

--
-- Name: loan_monthly_loanmonth_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE loan_monthly_loanmonth_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.loan_monthly_loanmonth_id_seq OWNER TO postgres;

--
-- Name: loan_monthly_loanmonth_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE loan_monthly_loanmonth_id_seq OWNED BY loan_monthly.loanmonth_id;


--
-- Name: loan_monthly_loanmonth_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('loan_monthly_loanmonth_id_seq', 5, true);


--
-- Name: loan_purpose; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE loan_purpose (
    loan_purpose_id integer NOT NULL,
    loan_purpose_name character varying(50),
    details text
);


ALTER TABLE public.loan_purpose OWNER TO root;

--
-- Name: loan_purpose_loan_purpose_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE loan_purpose_loan_purpose_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.loan_purpose_loan_purpose_seq OWNER TO root;

--
-- Name: loan_purpose_loan_purpose_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE loan_purpose_loan_purpose_seq OWNED BY loan_purpose.loan_purpose_id;


--
-- Name: loan_purpose_loan_purpose_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('loan_purpose_loan_purpose_seq', 8, true);


--
-- Name: loan_reinbursment; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE loan_reinbursment (
    loan_reinbursment_id integer NOT NULL,
    loan_id integer,
    amount_reinbursed real NOT NULL,
    payment_mode_id integer,
    documentnumber character varying(20),
    paymentnarrative text,
    created date DEFAULT ('now'::text)::date NOT NULL,
    createdby integer,
    details text,
    updated date,
    narrative text,
    bank_branch_id integer,
    CONSTRAINT loan_reinbursment_amount_reinbursed_check CHECK ((amount_reinbursed > (0)::double precision))
);


ALTER TABLE public.loan_reinbursment OWNER TO root;

--
-- Name: loan_reinbursment_loan_reinbursment_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE loan_reinbursment_loan_reinbursment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.loan_reinbursment_loan_reinbursment_id_seq OWNER TO root;

--
-- Name: loan_reinbursment_loan_reinbursment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE loan_reinbursment_loan_reinbursment_id_seq OWNED BY loan_reinbursment.loan_reinbursment_id;


--
-- Name: loan_reinbursment_loan_reinbursment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('loan_reinbursment_loan_reinbursment_id_seq', 11, true);


--
-- Name: loans; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE loans (
    loan_id integer NOT NULL,
    loantype_id integer,
    borrower_id integer,
    principal real NOT NULL,
    credit_charge real DEFAULT 0 NOT NULL,
    legal_fee real DEFAULT 0 NOT NULL,
    valuation_fee real DEFAULT 0 NOT NULL,
    trasfer_fee real DEFAULT 0 NOT NULL,
    loandate date DEFAULT ('now'::text)::date NOT NULL,
    interest real NOT NULL,
    monthlyrepayment real NOT NULL,
    repaymentperiod integer NOT NULL,
    loanapproved boolean DEFAULT false NOT NULL,
    narrative text,
    loan_purpose_id integer,
    CONSTRAINT loans_interest_check CHECK ((interest > (0)::double precision)),
    CONSTRAINT loans_principal_check CHECK ((principal > (0)::double precision))
);


ALTER TABLE public.loans OWNER TO postgres;

--
-- Name: loans_loanid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE loans_loanid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.loans_loanid_seq OWNER TO postgres;

--
-- Name: loans_loanid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE loans_loanid_seq OWNED BY loans.loan_id;


--
-- Name: loans_loanid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('loans_loanid_seq', 16, true);


--
-- Name: loantypes; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE loantypes (
    loantype_id integer NOT NULL,
    loantype_name character varying(50),
    details text,
    is_reducing_balance boolean DEFAULT false,
    default_interest real
);


ALTER TABLE public.loantypes OWNER TO postgres;

--
-- Name: loantypes_loantype_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE loantypes_loantype_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.loantypes_loantype_id_seq OWNER TO postgres;

--
-- Name: loantypes_loantype_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE loantypes_loantype_id_seq OWNED BY loantypes.loantype_id;


--
-- Name: loantypes_loantype_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('loantypes_loantype_id_seq', 4, true);


--
-- Name: orgs; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE orgs (
    org_id integer NOT NULL,
    org_name character varying(50),
    is_default boolean DEFAULT true NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    logo character varying(50),
    details text
);


ALTER TABLE public.orgs OWNER TO root;

--
-- Name: orgs_org_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE orgs_org_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.orgs_org_id_seq OWNER TO root;

--
-- Name: orgs_org_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE orgs_org_id_seq OWNED BY orgs.org_id;


--
-- Name: orgs_org_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('orgs_org_id_seq', 1, true);


--
-- Name: partner; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE partner (
    partner_id integer NOT NULL,
    entity_id integer,
    type_of_business character varying(50),
    year_started integer,
    details text,
    sur_name character varying(50),
    first_name character varying(50),
    middle_name character varying(50)
);


ALTER TABLE public.partner OWNER TO root;

--
-- Name: partner_partner_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE partner_partner_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.partner_partner_id_seq OWNER TO root;

--
-- Name: partner_partner_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE partner_partner_id_seq OWNED BY partner.partner_id;


--
-- Name: partner_partner_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('partner_partner_id_seq', 1, true);


--
-- Name: payment_mode; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE payment_mode (
    payment_mode_id integer NOT NULL,
    payment_mode_name character varying(20),
    processing_fee real,
    details text
);


ALTER TABLE public.payment_mode OWNER TO root;

--
-- Name: payment_mode_payment_mode_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE payment_mode_payment_mode_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.payment_mode_payment_mode_id_seq OWNER TO root;

--
-- Name: payment_mode_payment_mode_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE payment_mode_payment_mode_id_seq OWNED BY payment_mode.payment_mode_id;


--
-- Name: payment_mode_payment_mode_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('payment_mode_payment_mode_id_seq', 4, true);


--
-- Name: periods; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE periods (
    period_id integer NOT NULL,
    period_start date NOT NULL,
    period_end date NOT NULL,
    dividend_rate real DEFAULT 0 NOT NULL,
    close_month boolean DEFAULT false NOT NULL,
    is_active boolean DEFAULT false NOT NULL,
    details text,
    fiscal_year_id character varying(9),
    period_opened boolean DEFAULT false NOT NULL,
    period_closed boolean DEFAULT false NOT NULL,
    CONSTRAINT periods_check CHECK ((period_end > period_start))
);


ALTER TABLE public.periods OWNER TO postgres;

--
-- Name: periods_period_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE periods_period_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.periods_period_id_seq OWNER TO postgres;

--
-- Name: periods_period_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE periods_period_id_seq OWNED BY periods.period_id;


--
-- Name: periods_period_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('periods_period_id_seq', 64, true);


--
-- Name: phase; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE phase (
    phase_id integer NOT NULL,
    phase_name character varying(20),
    phase_level integer,
    default_charge real DEFAULT 0 NOT NULL,
    details text
);


ALTER TABLE public.phase OWNER TO root;

--
-- Name: phase_phase_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE phase_phase_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.phase_phase_id_seq OWNER TO root;

--
-- Name: phase_phase_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE phase_phase_id_seq OWNED BY phase.phase_id;


--
-- Name: phase_phase_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('phase_phase_id_seq', 1, false);


--
-- Name: rec_investor; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE rec_investor (
    investor_name text
);


ALTER TABLE public.rec_investor OWNER TO root;

--
-- Name: referee; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE referee (
    referee_id integer NOT NULL,
    referee_name character varying(50),
    mobile_tel_no character varying(50),
    office_tel_no character varying(50),
    home_tel_no character varying(50),
    details text,
    entity_id integer,
    borrower_id integer,
    sur_name character varying(50),
    first_name character varying(50),
    middle_name character varying(50)
);


ALTER TABLE public.referee OWNER TO root;

--
-- Name: referee_referee_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE referee_referee_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.referee_referee_id_seq OWNER TO root;

--
-- Name: referee_referee_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE referee_referee_id_seq OWNED BY referee.referee_id;


--
-- Name: referee_referee_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('referee_referee_id_seq', 1, true);


--
-- Name: repayment_table; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE repayment_table (
    repayment_table_id integer NOT NULL,
    loan_id integer,
    loan_period integer,
    loan_period_balance real NOT NULL,
    interest_component real DEFAULT 0 NOT NULL,
    cheque_number character varying(50),
    cheque_date date,
    cheque_amount real,
    bank_branch_id integer,
    penalty real DEFAULT 0 NOT NULL,
    is_confirmed boolean DEFAULT false,
    details text,
    principal_component real DEFAULT 0 NOT NULL,
    emi real DEFAULT 0 NOT NULL,
    branch_name character varying(50),
    bank_name character varying(50),
    is_paid boolean DEFAULT false,
    banking_slip text,
    cheque_status_id integer,
    is_dishonoured boolean DEFAULT false,
    is_defaulted boolean DEFAULT false,
    cheque_name character varying(50)
);


ALTER TABLE public.repayment_table OWNER TO root;

--
-- Name: repayment_table_repayment_table_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE repayment_table_repayment_table_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.repayment_table_repayment_table_id_seq OWNER TO root;

--
-- Name: repayment_table_repayment_table_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE repayment_table_repayment_table_id_seq OWNED BY repayment_table.repayment_table_id;


--
-- Name: repayment_table_repayment_table_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('repayment_table_repayment_table_id_seq', 99, true);


--
-- Name: services; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE services (
    service_id integer NOT NULL,
    service_name character varying(50),
    date_started date DEFAULT ('now'::text)::date NOT NULL,
    details text
);


ALTER TABLE public.services OWNER TO root;

--
-- Name: services_service_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE services_service_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.services_service_id_seq OWNER TO root;

--
-- Name: services_service_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE services_service_id_seq OWNED BY services.service_id;


--
-- Name: services_service_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('services_service_id_seq', 1, true);


--
-- Name: sub_fields; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE sub_fields (
    sub_field_id integer NOT NULL,
    field_id integer,
    sub_field_order integer DEFAULT 1,
    sub_title_share character varying(120),
    sub_field_type character varying(25),
    sub_field_lookup text,
    sub_field_size integer DEFAULT 10 NOT NULL,
    sub_col_spans integer DEFAULT 1 NOT NULL,
    manditory character(1) DEFAULT '0'::bpchar NOT NULL,
    show character(1) DEFAULT '1'::bpchar,
    question text
);


ALTER TABLE public.sub_fields OWNER TO root;

--
-- Name: sub_fields_sub_field_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE sub_fields_sub_field_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sub_fields_sub_field_id_seq OWNER TO root;

--
-- Name: sub_fields_sub_field_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE sub_fields_sub_field_id_seq OWNED BY sub_fields.sub_field_id;


--
-- Name: sub_fields_sub_field_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('sub_fields_sub_field_id_seq', 1, false);


--
-- Name: subscription_levels; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE subscription_levels (
    subscription_level_id integer NOT NULL,
    subscription_level_name character varying(50),
    details text
);


ALTER TABLE public.subscription_levels OWNER TO root;

--
-- Name: subscription_levels_subscription_level_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE subscription_levels_subscription_level_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.subscription_levels_subscription_level_id_seq OWNER TO root;

--
-- Name: subscription_levels_subscription_level_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE subscription_levels_subscription_level_id_seq OWNED BY subscription_levels.subscription_level_id;


--
-- Name: subscription_levels_subscription_level_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('subscription_levels_subscription_level_id_seq', 1, false);


--
-- Name: sys_audit_details; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE sys_audit_details (
    sys_audit_detail_id integer NOT NULL,
    sys_audit_trail_id integer,
    new_value text
);


ALTER TABLE public.sys_audit_details OWNER TO root;

--
-- Name: sys_audit_details_sys_audit_detail_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE sys_audit_details_sys_audit_detail_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sys_audit_details_sys_audit_detail_id_seq OWNER TO root;

--
-- Name: sys_audit_details_sys_audit_detail_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE sys_audit_details_sys_audit_detail_id_seq OWNED BY sys_audit_details.sys_audit_detail_id;


--
-- Name: sys_audit_details_sys_audit_detail_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('sys_audit_details_sys_audit_detail_id_seq', 1, false);


--
-- Name: sys_audit_trail; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE sys_audit_trail (
    sys_audit_trail_id integer NOT NULL,
    user_id character varying(50) NOT NULL,
    user_ip character varying(50),
    change_date timestamp without time zone DEFAULT now() NOT NULL,
    table_name character varying(50) NOT NULL,
    record_id character varying(50) NOT NULL,
    change_type character varying(50) NOT NULL,
    narrative character varying(240)
);


ALTER TABLE public.sys_audit_trail OWNER TO root;

--
-- Name: sys_audit_trail_sys_audit_trail_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE sys_audit_trail_sys_audit_trail_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sys_audit_trail_sys_audit_trail_id_seq OWNER TO root;

--
-- Name: sys_audit_trail_sys_audit_trail_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE sys_audit_trail_sys_audit_trail_id_seq OWNED BY sys_audit_trail.sys_audit_trail_id;


--
-- Name: sys_audit_trail_sys_audit_trail_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('sys_audit_trail_sys_audit_trail_id_seq', 151, true);


--
-- Name: sys_continents; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE sys_continents (
    sys_continent_id character(2) NOT NULL,
    sys_continent_name character varying(120)
);


ALTER TABLE public.sys_continents OWNER TO root;

--
-- Name: sys_countrys; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE sys_countrys (
    sys_country_id character(2) NOT NULL,
    sys_continent_id character(2),
    sys_country_code character varying(3),
    sys_country_number character varying(3),
    sys_country_name character varying(120),
    sys_currency_name character varying(50),
    sys_currency_cents character varying(50),
    sys_currency_code character varying(3),
    sys_currency_exchange real
);


ALTER TABLE public.sys_countrys OWNER TO root;

--
-- Name: sys_emailed; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE sys_emailed (
    sys_emailed_id integer NOT NULL,
    sys_email_id integer,
    table_id integer,
    table_name character varying(50),
    email_level integer DEFAULT 1 NOT NULL,
    emailed boolean DEFAULT false NOT NULL,
    details text
);


ALTER TABLE public.sys_emailed OWNER TO root;

--
-- Name: sys_emailed_sys_emailed_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE sys_emailed_sys_emailed_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sys_emailed_sys_emailed_id_seq OWNER TO root;

--
-- Name: sys_emailed_sys_emailed_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE sys_emailed_sys_emailed_id_seq OWNED BY sys_emailed.sys_emailed_id;


--
-- Name: sys_emailed_sys_emailed_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('sys_emailed_sys_emailed_id_seq', 1, false);


--
-- Name: sys_emails; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE sys_emails (
    sys_email_id integer NOT NULL,
    sys_email_name character varying(50),
    title character varying(240) NOT NULL,
    details text
);


ALTER TABLE public.sys_emails OWNER TO root;

--
-- Name: sys_emails_sys_email_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE sys_emails_sys_email_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sys_emails_sys_email_id_seq OWNER TO root;

--
-- Name: sys_emails_sys_email_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE sys_emails_sys_email_id_seq OWNED BY sys_emails.sys_email_id;


--
-- Name: sys_emails_sys_email_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('sys_emails_sys_email_id_seq', 1, false);


--
-- Name: sys_errors; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE sys_errors (
    sys_error_id integer NOT NULL,
    sys_error character varying(240) NOT NULL,
    error_message text NOT NULL
);


ALTER TABLE public.sys_errors OWNER TO root;

--
-- Name: sys_errors_sys_error_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE sys_errors_sys_error_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sys_errors_sys_error_id_seq OWNER TO root;

--
-- Name: sys_errors_sys_error_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE sys_errors_sys_error_id_seq OWNED BY sys_errors.sys_error_id;


--
-- Name: sys_errors_sys_error_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('sys_errors_sys_error_id_seq', 1, false);


--
-- Name: sys_files; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE sys_files (
    sys_file_id integer NOT NULL,
    table_id integer,
    table_name character varying(50),
    file_name character varying(240),
    file_type character varying(50),
    details text
);


ALTER TABLE public.sys_files OWNER TO root;

--
-- Name: sys_files_sys_file_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE sys_files_sys_file_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sys_files_sys_file_id_seq OWNER TO root;

--
-- Name: sys_files_sys_file_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE sys_files_sys_file_id_seq OWNED BY sys_files.sys_file_id;


--
-- Name: sys_files_sys_file_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('sys_files_sys_file_id_seq', 1, false);


--
-- Name: sys_logins; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE sys_logins (
    sys_login_id integer NOT NULL,
    entity_id integer,
    login_time timestamp without time zone DEFAULT now(),
    login_ip character varying(50),
    narrative character varying(240)
);


ALTER TABLE public.sys_logins OWNER TO root;

--
-- Name: sys_logins_sys_login_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE sys_logins_sys_login_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sys_logins_sys_login_id_seq OWNER TO root;

--
-- Name: sys_logins_sys_login_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE sys_logins_sys_login_id_seq OWNED BY sys_logins.sys_login_id;


--
-- Name: sys_logins_sys_login_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('sys_logins_sys_login_id_seq', 4308, true);


--
-- Name: sys_news; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE sys_news (
    sys_news_id integer NOT NULL,
    sys_news_group integer,
    sys_news_title character varying(240) NOT NULL,
    publish boolean DEFAULT false NOT NULL,
    details text
);


ALTER TABLE public.sys_news OWNER TO root;

--
-- Name: sys_news_sys_news_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE sys_news_sys_news_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sys_news_sys_news_id_seq OWNER TO root;

--
-- Name: sys_news_sys_news_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE sys_news_sys_news_id_seq OWNED BY sys_news.sys_news_id;


--
-- Name: sys_news_sys_news_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('sys_news_sys_news_id_seq', 1, false);


--
-- Name: sys_passwords; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE sys_passwords (
    sys_password_id integer NOT NULL,
    sys_user_name character varying(240) NOT NULL,
    password_sent boolean NOT NULL
);


ALTER TABLE public.sys_passwords OWNER TO root;

--
-- Name: sys_passwords_sys_password_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE sys_passwords_sys_password_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sys_passwords_sys_password_id_seq OWNER TO root;

--
-- Name: sys_passwords_sys_password_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE sys_passwords_sys_password_id_seq OWNED BY sys_passwords.sys_password_id;


--
-- Name: sys_passwords_sys_password_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('sys_passwords_sys_password_id_seq', 1, false);


--
-- Name: sys_queries; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE sys_queries (
    query_name character varying(50) NOT NULL,
    query_date timestamp without time zone DEFAULT now() NOT NULL,
    query_text text
);


ALTER TABLE public.sys_queries OWNER TO root;

--
-- Name: tax; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE tax (
    tax_id integer NOT NULL,
    tax_category_id integer,
    tax_name character varying(50),
    tax_rate real NOT NULL,
    details text
);


ALTER TABLE public.tax OWNER TO root;

--
-- Name: tax_category; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE tax_category (
    tax_category_id integer NOT NULL,
    tax_category_name character varying(50),
    details text
);


ALTER TABLE public.tax_category OWNER TO root;

--
-- Name: tax_category_tax_category_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE tax_category_tax_category_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tax_category_tax_category_id_seq OWNER TO root;

--
-- Name: tax_category_tax_category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE tax_category_tax_category_id_seq OWNED BY tax_category.tax_category_id;


--
-- Name: tax_category_tax_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('tax_category_tax_category_id_seq', 1, true);


--
-- Name: tax_tax_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE tax_tax_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tax_tax_id_seq OWNER TO root;

--
-- Name: tax_tax_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE tax_tax_id_seq OWNED BY tax.tax_id;


--
-- Name: tax_tax_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('tax_tax_id_seq', 1, true);


--
-- Name: tomcat_users; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW tomcat_users AS
    SELECT entitys.user_name, entitys.entity_password, entity_types.entity_role FROM ((entity_subscriptions JOIN entitys ON ((entity_subscriptions.entity_id = entitys.entity_id))) JOIN entity_types ON ((entity_subscriptions.entity_type_id = entity_types.entity_type_id))) WHERE (entitys.is_active = true);


ALTER TABLE public.tomcat_users OWNER TO root;

--
-- Name: transactions; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE transactions (
    transaction_id integer NOT NULL,
    period_id integer,
    service_id integer,
    borrower_id integer,
    loan_id integer,
    transaction_time timestamp without time zone DEFAULT now(),
    action_date date DEFAULT ('now'::text)::date,
    payment_mode_id integer,
    document_number character varying(20),
    payment_narrative text,
    amount_in real DEFAULT 0 NOT NULL,
    amount_out real DEFAULT 0 NOT NULL,
    isapproved boolean DEFAULT true NOT NULL,
    remote_ip character varying(32),
    narrative text
);


ALTER TABLE public.transactions OWNER TO root;

--
-- Name: transactions_transaction_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE transactions_transaction_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.transactions_transaction_id_seq OWNER TO root;

--
-- Name: transactions_transaction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE transactions_transaction_id_seq OWNED BY transactions.transaction_id;


--
-- Name: transactions_transaction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('transactions_transaction_id_seq', 1, false);


--
-- Name: vw_account_types; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW vw_account_types AS
    SELECT accounts_class.accounts_class_id, accounts_class.accounts_class_name, accounts_class.chat_type_id, accounts_class.chat_type_name, account_types.account_type_id, account_types.account_type_name, account_types.details FROM (account_types JOIN accounts_class ON ((account_types.accounts_class_id = accounts_class.accounts_class_id)));


ALTER TABLE public.vw_account_types OWNER TO root;

--
-- Name: vw_accounts; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW vw_accounts AS
    SELECT vw_account_types.accounts_class_id, vw_account_types.chat_type_id, vw_account_types.chat_type_name, vw_account_types.accounts_class_name, vw_account_types.account_type_id, vw_account_types.account_type_name, accounts.account_id, accounts.account_name, accounts.is_header, accounts.is_active, accounts.details, ((((((accounts.account_id || ' : '::text) || (vw_account_types.accounts_class_name)::text) || ' : '::text) || (vw_account_types.account_type_name)::text) || ' : '::text) || (accounts.account_name)::text) AS account_description FROM (accounts JOIN vw_account_types ON ((accounts.account_type_id = vw_account_types.account_type_id)));


ALTER TABLE public.vw_accounts OWNER TO root;

--
-- Name: vw_address; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW vw_address AS
    SELECT sys_countrys.sys_country_id, sys_countrys.sys_country_name, address.address_id, address.address_name, address.table_name, address.table_id, address.post_office_box, address.postal_code, address.premises, address.street, address.town, address.phone_number, address.extension, address.mobile, address.fax, address.email, address.is_default, address.details FROM (address JOIN sys_countrys ON ((address.sys_country_id = sys_countrys.sys_country_id)));


ALTER TABLE public.vw_address OWNER TO root;

--
-- Name: vw_approval_phases; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW vw_approval_phases AS
    SELECT approval_types.approval_type_id, approval_types.approval_type_name, entity_types.entity_type_id, entity_types.entity_type_name, approval_phases.approval_phase_id, approval_phases.table_name, approval_phases.approval_level, approval_phases.return_level, approval_phases.escalation_time, approval_phases.departmental, approval_phases.details FROM ((approval_phases JOIN approval_types ON ((approval_phases.approval_type_id = approval_types.approval_type_id))) JOIN entity_types ON ((approval_phases.entity_type_id = entity_types.entity_type_id)));


ALTER TABLE public.vw_approval_phases OWNER TO root;

--
-- Name: vw_approvals; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW vw_approvals AS
    SELECT vw_approval_phases.approval_type_id, vw_approval_phases.approval_type_name, vw_approval_phases.entity_type_id, vw_approval_phases.entity_type_name, vw_approval_phases.approval_phase_id, vw_approval_phases.table_name, vw_approval_phases.approval_level, vw_approval_phases.return_level, entitys.entity_id, entitys.entity_name, approvals.approval_id, approvals.forward_id, approvals.table_id, approvals.escalation_time, approvals.application_date, approvals.approved, approvals.rejected, approvals.action_date, approvals.narrative, approvals.to_be_done, approvals.what_is_done, approvals.details FROM ((approvals JOIN vw_approval_phases ON ((approvals.approval_phase_id = vw_approval_phases.approval_phase_id))) LEFT JOIN entitys ON ((approvals.entity_id = entitys.entity_id)));


ALTER TABLE public.vw_approvals OWNER TO root;

--
-- Name: vw_bank_branch; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW vw_bank_branch AS
    SELECT bank_branch.bank_branch_id, bank_branch.bank_branch_name, bank.bank_id, bank.bank_name, bank.bank_code, bank.banka_bbrev FROM (bank_branch JOIN bank ON ((bank_branch.bank_id = bank.bank_id)));


ALTER TABLE public.vw_bank_branch OWNER TO root;

--
-- Name: vw_entity_subscriptions; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW vw_entity_subscriptions AS
    SELECT entity_types.entity_type_id, entity_types.entity_type_name, entitys.entity_id, entitys.entity_name, entity_subscriptions.entity_subscription_id, entity_subscriptions.details FROM ((entity_subscriptions JOIN entity_types ON ((entity_subscriptions.entity_type_id = entity_types.entity_type_id))) JOIN entitys ON ((entity_subscriptions.entity_id = entitys.entity_id)));


ALTER TABLE public.vw_entity_subscriptions OWNER TO root;

--
-- Name: vw_entitys; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW vw_entitys AS
    SELECT orgs.org_id, orgs.org_name, vw_address.address_id, vw_address.address_name, vw_address.sys_country_id, vw_address.sys_country_name, vw_address.table_name, vw_address.post_office_box, vw_address.postal_code, vw_address.premises, vw_address.street, vw_address.town, vw_address.phone_number, vw_address.extension, vw_address.mobile, vw_address.fax, vw_address.email, entitys.entity_id, entitys.entity_name, entitys.user_name, entitys.super_user, entitys.entity_leader, entitys.date_enroled, entitys.is_active, entitys.function_role, entitys.entity_password, entitys.first_password, entitys.details, entity_types.entity_type_id, entity_types.entity_type_name FROM (((entitys JOIN orgs ON ((entitys.org_id = orgs.org_id))) JOIN entity_types ON ((entitys.entity_type_id = entity_types.entity_type_id))) LEFT JOIN vw_address ON ((entitys.entity_id = vw_address.table_id))) WHERE (((vw_address.table_name)::text = 'entitys'::text) OR (vw_address.table_name IS NULL));


ALTER TABLE public.vw_entitys OWNER TO root;

--
-- Name: vw_entry_forms; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW vw_entry_forms AS
    SELECT entitys.entity_id, entitys.entity_name, forms.form_id, forms.form_name, entry_forms.entry_form_id, entry_forms.completed, entry_forms.approved, entry_forms.rejected, entry_forms.application_date, entry_forms.completion_date, entry_forms.approve_date, entry_forms.narrative, entry_forms.answer, entry_forms.details FROM ((entry_forms JOIN entitys ON ((entry_forms.entity_id = entitys.entity_id))) JOIN forms ON ((entry_forms.form_id = forms.form_id)));


ALTER TABLE public.vw_entry_forms OWNER TO root;

--
-- Name: vw_entry_sub_forms; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW vw_entry_sub_forms AS
    SELECT vw_entry_forms.entry_form_id, vw_entry_forms.entity_id, vw_entry_forms.entity_name, vw_entry_forms.approved, vw_entry_forms.application_date, vw_entry_forms.completion_date, sub_fields.sub_field_id, sub_fields.field_id, sub_fields.question, entry_sub_forms.entry_sub_form_id, entry_sub_forms.answer FROM ((entry_sub_forms JOIN vw_entry_forms ON ((entry_sub_forms.entry_form_id = vw_entry_forms.entry_form_id))) JOIN sub_fields ON ((entry_sub_forms.sub_field_id = sub_fields.sub_field_id)));


ALTER TABLE public.vw_entry_sub_forms OWNER TO root;

--
-- Name: vw_fields; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW vw_fields AS
    SELECT forms.form_id, forms.form_name, fields.field_id, fields.question, fields.field_lookup, fields.field_type, fields.field_order, fields.share_line, fields.field_size, fields.manditory, fields.field_bold, fields.field_italics FROM (fields JOIN forms ON ((fields.form_id = forms.form_id)));


ALTER TABLE public.vw_fields OWNER TO root;

--
-- Name: vw_periods; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW vw_periods AS
    SELECT fiscal_years.fiscal_year_id, fiscal_years.fiscal_year_start, fiscal_years.fiscal_year_end, fiscal_years.year_opened, fiscal_years.year_closed, periods.period_id, periods.period_start, periods.period_end, periods.period_opened, periods.period_closed, date_part('month'::text, periods.period_start) AS month_id, to_char((periods.period_start)::timestamp with time zone, 'YYYY'::text) AS period_year, to_char((periods.period_start)::timestamp with time zone, 'Month'::text) AS period_month, (trunc(((date_part('month'::text, periods.period_start) - (1)::double precision) / (3)::double precision)) + (1)::double precision) AS quarter, (trunc(((date_part('month'::text, periods.period_start) - (1)::double precision) / (6)::double precision)) + (1)::double precision) AS semister FROM (periods JOIN fiscal_years ON (((periods.fiscal_year_id)::text = (fiscal_years.fiscal_year_id)::text))) ORDER BY periods.period_start;


ALTER TABLE public.vw_periods OWNER TO root;

--
-- Name: vw_journals; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW vw_journals AS
    SELECT vw_periods.fiscal_year_id, vw_periods.fiscal_year_start, vw_periods.fiscal_year_end, vw_periods.year_opened, vw_periods.year_closed, vw_periods.period_id, vw_periods.period_start, vw_periods.period_end, vw_periods.period_opened, vw_periods.period_closed, vw_periods.month_id, vw_periods.period_year, vw_periods.period_month, vw_periods.quarter, vw_periods.semister, journals.journal_id, journals.journal_date, journals.posted, journals.narrative, journals.details FROM (journals JOIN vw_periods ON ((journals.period_id = vw_periods.period_id)));


ALTER TABLE public.vw_journals OWNER TO root;

--
-- Name: vw_gls; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW vw_gls AS
    SELECT vw_accounts.accounts_class_id, vw_accounts.chat_type_id, vw_accounts.chat_type_name, vw_accounts.accounts_class_name, vw_accounts.account_type_id, vw_accounts.account_type_name, vw_accounts.account_id, vw_accounts.account_name, vw_accounts.is_header, vw_accounts.is_active, vw_journals.fiscal_year_id, vw_journals.fiscal_year_start, vw_journals.fiscal_year_end, vw_journals.year_opened, vw_journals.year_closed, vw_journals.period_id, vw_journals.period_start, vw_journals.period_end, vw_journals.period_opened, vw_journals.period_closed, vw_journals.month_id, vw_journals.period_year, vw_journals.period_month, vw_journals.quarter, vw_journals.semister, vw_journals.journal_id, vw_journals.journal_date, vw_journals.posted, vw_journals.narrative, gls.gl_id, gls.debit, gls.credit, gls.gl_narrative FROM ((gls JOIN vw_accounts ON ((gls.account_id = vw_accounts.account_id))) JOIN vw_journals ON ((gls.journal_id = vw_journals.journal_id)));


ALTER TABLE public.vw_gls OWNER TO root;

--
-- Name: vw_orgs; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW vw_orgs AS
    SELECT orgs.org_id, orgs.org_name, orgs.is_default, orgs.is_active, orgs.logo, orgs.details, vw_address.sys_country_id, vw_address.sys_country_name, vw_address.address_id, vw_address.table_name, vw_address.post_office_box, vw_address.postal_code, vw_address.premises, vw_address.street, vw_address.town, vw_address.phone_number, vw_address.extension, vw_address.mobile, vw_address.fax, vw_address.email FROM (orgs JOIN vw_address ON ((orgs.org_id = vw_address.table_id))) WHERE ((vw_address.table_name)::text = 'orgs'::text);


ALTER TABLE public.vw_orgs OWNER TO root;

--
-- Name: vw_sub_fields; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW vw_sub_fields AS
    SELECT vw_fields.form_id, vw_fields.form_name, vw_fields.field_id, sub_fields.sub_field_id, sub_fields.sub_field_order, sub_fields.sub_title_share, sub_fields.sub_field_type, sub_fields.sub_field_lookup, sub_fields.sub_field_size, sub_fields.sub_col_spans, sub_fields.manditory, sub_fields.question FROM (sub_fields JOIN vw_fields ON ((sub_fields.field_id = vw_fields.field_id)));


ALTER TABLE public.vw_sub_fields OWNER TO root;

--
-- Name: vw_sys_countrys; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW vw_sys_countrys AS
    SELECT sys_continents.sys_continent_id, sys_continents.sys_continent_name, sys_countrys.sys_country_id, sys_countrys.sys_country_code, sys_countrys.sys_country_number, sys_countrys.sys_country_name FROM (sys_continents JOIN sys_countrys ON ((sys_continents.sys_continent_id = sys_countrys.sys_continent_id)));


ALTER TABLE public.vw_sys_countrys OWNER TO root;

--
-- Name: vwbank_branch; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW vwbank_branch AS
    SELECT bank.bank_id, bank.bank_name, bank.bank_code, bank.banka_bbrev, bank_branch.bank_branch_id, bank_branch.bank_branch_name, (((bank.bank_name)::text || ': '::text) || (bank_branch.bank_branch_name)::text) AS branchsummary FROM (bank_branch JOIN bank ON ((bank_branch.bank_id = bank.bank_id)));


ALTER TABLE public.vwbank_branch OWNER TO root;

--
-- Name: vwborrower; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW vwborrower AS
    SELECT borrower.borrower_id, borrower.employer_name, entitys.entity_name, (((((COALESCE(borrower.sur_name, ''::character varying))::text || ' '::text) || (COALESCE(borrower.first_name, ''::character varying))::text) || ' '::text) || (COALESCE(borrower.middle_name, ''::character varying))::text) AS borrower_name FROM (borrower JOIN entitys ON ((borrower.entity_id = entitys.entity_id)));


ALTER TABLE public.vwborrower OWNER TO root;

--
-- Name: vwdeductions; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW vwdeductions AS
    SELECT deduction.deduction_id, deduction.deduction_amount, deduction.effective_date, deduction.details AS deduction_details, ((((((investment.investment_id || ' '::text) || (((((COALESCE(investor.sur_name, ''::character varying))::text || ' '::text) || (COALESCE(investor.first_name, ''::character varying))::text) || ' '::text) || (COALESCE(investor.middle_name, ''::character varying))::text)) || ' '::text) || (investment_type.investment_type_name)::text) || ' '::text) || investment.principal) AS investment_summary FROM (((deduction JOIN investment ON ((deduction.investment_id = investment.investment_id))) JOIN investment_type ON ((investment.investment_type_id = investment_type.investment_type_id))) JOIN investor ON ((investment.investor_id = investor.investor_id)));


ALTER TABLE public.vwdeductions OWNER TO root;

--
-- Name: vwfiscal_year; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW vwfiscal_year AS
    SELECT fiscal_years.fiscal_year_id, fiscal_years.fiscal_year_start, fiscal_years.fiscal_year_end, fiscal_years.year_opened, fiscal_years.year_closed, to_char((fiscal_years.fiscal_year_start)::timestamp with time zone, 'YYYY'::text) AS fiscal_year FROM fiscal_years;


ALTER TABLE public.vwfiscal_year OWNER TO root;

--
-- Name: vwfixedloanschedule; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW vwfixedloanschedule AS
    SELECT loans.loan_id, generate_series(1, loans.repaymentperiod) AS loan_period, round((geteffectiveloan(loans.loan_id) / (loans.repaymentperiod)::double precision)) AS monthly_repayment, getsimpleperiodbalance(loans.loan_id, generate_series(1, loans.repaymentperiod), (round((geteffectiveloan(loans.loan_id) / (loans.repaymentperiod)::double precision)))::real) AS period_balance, (((loans.interest * (12)::double precision) / ((loans.interest * (12)::double precision) + (100)::double precision)) * (geteffectiveloan(loans.loan_id) / (loans.repaymentperiod)::double precision)) AS interest_component, (((100)::double precision / ((loans.interest * (12)::double precision) + (100)::double precision)) * (geteffectiveloan(loans.loan_id) / (loans.repaymentperiod)::double precision)) AS principal_component FROM loans;


ALTER TABLE public.vwfixedloanschedule OWNER TO root;

--
-- Name: vwinvestment; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW vwinvestment AS
    SELECT investment.investment_id, (((((COALESCE(investor.sur_name, ''::character varying))::text || ' '::text) || (COALESCE(investor.first_name, ''::character varying))::text) || ' '::text) || (COALESCE(investor.middle_name, ''::character varying))::text) AS investor_name, investment_type.investment_type_id, investment_type.investment_type_name, investment_type.default_interest, ((((((investment.investment_id || ' '::text) || (((((COALESCE(investor.sur_name, ''::character varying))::text || ' '::text) || (COALESCE(investor.first_name, ''::character varying))::text) || ' '::text) || (COALESCE(investor.middle_name, ''::character varying))::text)) || ' '::text) || (investment_type.investment_type_name)::text) || ' '::text) || investment.principal) AS investment_summary, investment.investor_id, investment.principal, gettotalinvestmentdeductions(investment.investment_id) AS total_deductions, (investment.principal - gettotalinvestmentdeductions(investment.investment_id)) AS investment_balance, getperiodid(investment.investment_date) AS first_maturity_period, investment.credit_charge, investment.legal_fee, investment.valuation_fee, investment.trasfer_fee, investment.investment_date, investment.is_approved, investment.details AS investment_details FROM ((investment JOIN investor ON ((investment.investor_id = investor.investor_id))) JOIN investment_type ON ((investment.investment_type_id = investment_type.investment_type_id)));


ALTER TABLE public.vwinvestment OWNER TO root;

--
-- Name: vwinvestment_maturity; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW vwinvestment_maturity AS
    SELECT investment_maturity.investment_maturity_id, investment_maturity.period_id, investment_maturity.investment_id, investment_maturity.mature_amount, investment_maturity.interest_amount, gettax(1, investment_maturity.interest_amount) AS with_holding_tax, to_char((periods.period_end)::timestamp with time zone, 'YYYY'::text) AS periodyear, to_char((periods.period_end)::timestamp with time zone, 'Month'::text) AS periodmonth, ((to_char((periods.period_end)::timestamp with time zone, 'YYYY'::text) || ' '::text) || to_char((periods.period_end)::timestamp with time zone, 'Month'::text)) AS periodsummary, ((((((investment_maturity.investment_id || ' '::text) || (((((COALESCE(investor.sur_name, ''::character varying))::text || ' '::text) || (COALESCE(investor.first_name, ''::character varying))::text) || ' '::text) || (COALESCE(investor.middle_name, ''::character varying))::text)) || ' '::text) || (investment_type.investment_type_name)::text) || ' '::text) || investment.principal) AS investment_summary FROM ((((investment_maturity JOIN periods ON ((investment_maturity.period_id = periods.period_id))) JOIN investment ON ((investment_maturity.investment_id = investment.investment_id))) JOIN investment_type ON ((investment.investment_type_id = investment_type.investment_type_id))) JOIN investor ON ((investment.investor_id = investor.investor_id)));


ALTER TABLE public.vwinvestment_maturity OWNER TO root;

--
-- Name: vwinvestor; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vwinvestor AS
    SELECT investor.investor_id, (((((COALESCE(investor.sur_name, ''::character varying))::text || ' '::text) || (COALESCE(investor.first_name, ''::character varying))::text) || ' '::text) || (COALESCE(investor.middle_name, ''::character varying))::text) AS investor_name FROM (investor JOIN entitys ON ((investor.entity_id = entitys.entity_id)));


ALTER TABLE public.vwinvestor OWNER TO postgres;

--
-- Name: vwloan; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW vwloan AS
    SELECT loantypes.loantype_id, loantypes.loantype_name, loantypes.default_interest, entitys.entity_id, entitys.entity_name, borrower.borrower_id, geteffectiveloan(loans.loan_id) AS effective_loan, ((((loans.principal || ', '::text) || (loantypes.loantype_name)::text) || ', '::text) || (entitys.entity_name)::text) AS loansummmary, loans.loan_id, loans.loandate, loans.principal, loans.interest, loans.repaymentperiod, loans.monthlyrepayment, getrepayment(loans.principal, loans.interest, loans.repaymentperiod) AS repaymentamount, gettotalrepayment(loans.loan_id) AS totalrepayment, gettotalinterest(loans.loan_id) AS totalinterest, ((loans.principal + gettotalinterest(loans.loan_id)) - gettotalrepayment(loans.loan_id)) AS loanbalance, getpaymentperiod(loans.principal, loans.monthlyrepayment, loans.interest) AS calcrepaymentperiod, loans.loanapproved FROM (((loantypes JOIN loans ON ((loantypes.loantype_id = loans.loantype_id))) JOIN borrower ON ((loans.borrower_id = borrower.borrower_id))) JOIN entitys ON ((borrower.entity_id = entitys.entity_id)));


ALTER TABLE public.vwloan OWNER TO root;

--
-- Name: vwloanreinbursement; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW vwloanreinbursement AS
    SELECT ((((loans.principal || ', '::text) || (loantypes.loantype_name)::text) || ', '::text) || (entitys.entity_name)::text) AS loansummmary, loan_reinbursment.loan_reinbursment_id, loans.loan_id, loan_reinbursment.amount_reinbursed, payment_mode.payment_mode_id, payment_mode.payment_mode_name, loan_reinbursment.documentnumber, loan_reinbursment.paymentnarrative, loan_reinbursment.details FROM (((((loan_reinbursment JOIN loans ON ((loan_reinbursment.loan_id = loans.loan_id))) JOIN payment_mode ON ((loan_reinbursment.payment_mode_id = payment_mode.payment_mode_id))) JOIN loantypes ON ((loans.loantype_id = loantypes.loantype_id))) JOIN borrower ON ((loans.borrower_id = borrower.borrower_id))) JOIN entitys ON ((borrower.entity_id = entitys.entity_id)));


ALTER TABLE public.vwloanreinbursement OWNER TO root;

--
-- Name: vwloanshedule; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW vwloanshedule AS
    SELECT loans.loan_id, generate_series(1, loans.repaymentperiod) AS loan_period, round((getloanperiodbalance(geteffectiveloan(loans.loan_id, loans.repaymentperiod), loans.interest, generate_series(1, loans.repaymentperiod), getrepayment(geteffectiveloan(loans.loan_id, loans.repaymentperiod), loans.interest, loans.repaymentperiod)))::double precision) AS period_balance, round((getloanperiodbalance(geteffectiveloan(loans.loan_id, loans.repaymentperiod), loans.interest, (generate_series(1, loans.repaymentperiod) - 1), getrepayment(geteffectiveloan(loans.loan_id, loans.repaymentperiod), loans.interest, loans.repaymentperiod)) * (loans.interest / (1200)::double precision))) AS interest_component, round((loans.monthlyrepayment - (getloanperiodbalance(geteffectiveloan(loans.loan_id), loans.interest, (generate_series(1, loans.repaymentperiod) - 1), getrepayment(geteffectiveloan(loans.loan_id, loans.repaymentperiod), loans.interest, loans.repaymentperiod)) * (loans.interest / (1200)::double precision)))) AS principal_component, loans.monthlyrepayment AS monthly_repayment FROM loans;


ALTER TABLE public.vwloanshedule OWNER TO root;

--
-- Name: vwperiods; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW vwperiods AS
    SELECT periods.period_id, periods.fiscal_year_id, to_char((periods.period_end)::timestamp with time zone, 'YYYY'::text) AS periodyear, to_char((periods.period_end)::timestamp with time zone, 'Month'::text) AS periodmonth, date_part('month'::text, periods.period_end) AS monthid, date_part('quarter'::text, periods.period_end) AS quarter, periods.period_opened, periods.period_closed, periods.period_start, periods.period_end, periods.close_month, periods.is_active, periods.details AS perioddetails FROM periods;


ALTER TABLE public.vwperiods OWNER TO root;

--
-- Name: address_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE address ALTER COLUMN address_id SET DEFAULT nextval('address_address_id_seq'::regclass);


--
-- Name: approval_phase_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE approval_phases ALTER COLUMN approval_phase_id SET DEFAULT nextval('approval_phases_approval_phase_id_seq'::regclass);


--
-- Name: approval_type_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE approval_types ALTER COLUMN approval_type_id SET DEFAULT nextval('approval_types_approval_type_id_seq'::regclass);


--
-- Name: approval_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE approvals ALTER COLUMN approval_id SET DEFAULT nextval('approvals_approval_id_seq'::regclass);


--
-- Name: auction_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE auction ALTER COLUMN auction_id SET DEFAULT nextval('auction_auction_id_seq'::regclass);


--
-- Name: auction_phase_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE auction_phase ALTER COLUMN auction_phase_id SET DEFAULT nextval('auction_phase_auction_phase_id_seq'::regclass);


--
-- Name: bank_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE bank ALTER COLUMN bank_id SET DEFAULT nextval('bank_bank_id_seq'::regclass);


--
-- Name: bank_branch_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE bank_branch ALTER COLUMN bank_branch_id SET DEFAULT nextval('bank_branch_bank_branch_id_seq'::regclass);


--
-- Name: borrower_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE borrower ALTER COLUMN borrower_id SET DEFAULT nextval('borrower_borrower_id_seq'::regclass);


--
-- Name: borrower_contact_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE borrower_contact ALTER COLUMN borrower_contact_id SET DEFAULT nextval('borrower_contact_borrower_contact_id_seq'::regclass);


--
-- Name: cheque_status_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE cheque_status ALTER COLUMN cheque_status_id SET DEFAULT nextval('cheque_status_cheque_status_id_seq'::regclass);


--
-- Name: civil_action_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE civil_action ALTER COLUMN civil_action_id SET DEFAULT nextval('civil_action_civil_action_id_seq'::regclass);


--
-- Name: collateral_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE collateral ALTER COLUMN collateral_id SET DEFAULT nextval('collateral_collateral_id_seq'::regclass);


--
-- Name: commission_payment_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE commission_payment ALTER COLUMN commission_payment_id SET DEFAULT nextval('commission_payment_commission_payment_id_seq'::regclass);


--
-- Name: deduction_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE deduction ALTER COLUMN deduction_id SET DEFAULT nextval('deduction_deduction_id_seq'::regclass);


--
-- Name: defaulter_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE defaulter ALTER COLUMN defaulter_id SET DEFAULT nextval('defaulter_defaulter_id_seq'::regclass);


--
-- Name: entity_subscription_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE entity_subscriptions ALTER COLUMN entity_subscription_id SET DEFAULT nextval('entity_subscriptions_entity_subscription_id_seq'::regclass);


--
-- Name: entity_type_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE entity_types ALTER COLUMN entity_type_id SET DEFAULT nextval('entity_types_entity_type_id_seq'::regclass);


--
-- Name: entity_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE entitys ALTER COLUMN entity_id SET DEFAULT nextval('entitys_entity_id_seq'::regclass);


--
-- Name: entry_form_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE entry_forms ALTER COLUMN entry_form_id SET DEFAULT nextval('entry_forms_entry_form_id_seq'::regclass);


--
-- Name: entry_sub_form_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE entry_sub_forms ALTER COLUMN entry_sub_form_id SET DEFAULT nextval('entry_sub_forms_entry_sub_form_id_seq'::regclass);


--
-- Name: fee_type_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE fee_type ALTER COLUMN fee_type_id SET DEFAULT nextval('fee_type_fee_type_id_seq'::regclass);


--
-- Name: fee_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE fees ALTER COLUMN fee_id SET DEFAULT nextval('fees_fee_id_seq'::regclass);


--
-- Name: field_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE fields ALTER COLUMN field_id SET DEFAULT nextval('fields_field_id_seq'::regclass);


--
-- Name: form_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE forms ALTER COLUMN form_id SET DEFAULT nextval('forms_form_id_seq'::regclass);


--
-- Name: gl_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE gls ALTER COLUMN gl_id SET DEFAULT nextval('gls_gl_id_seq'::regclass);


--
-- Name: investigation_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE investigation ALTER COLUMN investigation_id SET DEFAULT nextval('investigation_investigation_id_seq'::regclass);


--
-- Name: investment_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE investment ALTER COLUMN investment_id SET DEFAULT nextval('investment_investment_id_seq'::regclass);


--
-- Name: investment_maturity_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE investment_maturity ALTER COLUMN investment_maturity_id SET DEFAULT nextval('investment_maturity_investment_maturity_id_seq'::regclass);


--
-- Name: investment_type_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE investment_type ALTER COLUMN investment_type_id SET DEFAULT nextval('investment_type_investment_type_id_seq'::regclass);


--
-- Name: investor_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE investor ALTER COLUMN investor_id SET DEFAULT nextval('investor_investor_id_seq'::regclass);


--
-- Name: journal_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE journals ALTER COLUMN journal_id SET DEFAULT nextval('journals_journal_id_seq'::regclass);


--
-- Name: loanmonth_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE loan_monthly ALTER COLUMN loanmonth_id SET DEFAULT nextval('loan_monthly_loanmonth_id_seq'::regclass);


--
-- Name: loan_purpose_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE loan_purpose ALTER COLUMN loan_purpose_id SET DEFAULT nextval('loan_purpose_loan_purpose_seq'::regclass);


--
-- Name: loan_reinbursment_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE loan_reinbursment ALTER COLUMN loan_reinbursment_id SET DEFAULT nextval('loan_reinbursment_loan_reinbursment_id_seq'::regclass);


--
-- Name: loan_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE loans ALTER COLUMN loan_id SET DEFAULT nextval('loans_loanid_seq'::regclass);


--
-- Name: loantype_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE loantypes ALTER COLUMN loantype_id SET DEFAULT nextval('loantypes_loantype_id_seq'::regclass);


--
-- Name: org_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE orgs ALTER COLUMN org_id SET DEFAULT nextval('orgs_org_id_seq'::regclass);


--
-- Name: partner_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE partner ALTER COLUMN partner_id SET DEFAULT nextval('partner_partner_id_seq'::regclass);


--
-- Name: payment_mode_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE payment_mode ALTER COLUMN payment_mode_id SET DEFAULT nextval('payment_mode_payment_mode_id_seq'::regclass);


--
-- Name: period_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE periods ALTER COLUMN period_id SET DEFAULT nextval('periods_period_id_seq'::regclass);


--
-- Name: phase_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE phase ALTER COLUMN phase_id SET DEFAULT nextval('phase_phase_id_seq'::regclass);


--
-- Name: referee_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE referee ALTER COLUMN referee_id SET DEFAULT nextval('referee_referee_id_seq'::regclass);


--
-- Name: repayment_table_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE repayment_table ALTER COLUMN repayment_table_id SET DEFAULT nextval('repayment_table_repayment_table_id_seq'::regclass);


--
-- Name: service_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE services ALTER COLUMN service_id SET DEFAULT nextval('services_service_id_seq'::regclass);


--
-- Name: sub_field_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE sub_fields ALTER COLUMN sub_field_id SET DEFAULT nextval('sub_fields_sub_field_id_seq'::regclass);


--
-- Name: subscription_level_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE subscription_levels ALTER COLUMN subscription_level_id SET DEFAULT nextval('subscription_levels_subscription_level_id_seq'::regclass);


--
-- Name: sys_audit_detail_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE sys_audit_details ALTER COLUMN sys_audit_detail_id SET DEFAULT nextval('sys_audit_details_sys_audit_detail_id_seq'::regclass);


--
-- Name: sys_audit_trail_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE sys_audit_trail ALTER COLUMN sys_audit_trail_id SET DEFAULT nextval('sys_audit_trail_sys_audit_trail_id_seq'::regclass);


--
-- Name: sys_emailed_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE sys_emailed ALTER COLUMN sys_emailed_id SET DEFAULT nextval('sys_emailed_sys_emailed_id_seq'::regclass);


--
-- Name: sys_email_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE sys_emails ALTER COLUMN sys_email_id SET DEFAULT nextval('sys_emails_sys_email_id_seq'::regclass);


--
-- Name: sys_error_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE sys_errors ALTER COLUMN sys_error_id SET DEFAULT nextval('sys_errors_sys_error_id_seq'::regclass);


--
-- Name: sys_file_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE sys_files ALTER COLUMN sys_file_id SET DEFAULT nextval('sys_files_sys_file_id_seq'::regclass);


--
-- Name: sys_login_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE sys_logins ALTER COLUMN sys_login_id SET DEFAULT nextval('sys_logins_sys_login_id_seq'::regclass);


--
-- Name: sys_news_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE sys_news ALTER COLUMN sys_news_id SET DEFAULT nextval('sys_news_sys_news_id_seq'::regclass);


--
-- Name: sys_password_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE sys_passwords ALTER COLUMN sys_password_id SET DEFAULT nextval('sys_passwords_sys_password_id_seq'::regclass);


--
-- Name: tax_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE tax ALTER COLUMN tax_id SET DEFAULT nextval('tax_tax_id_seq'::regclass);


--
-- Name: tax_category_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE tax_category ALTER COLUMN tax_category_id SET DEFAULT nextval('tax_category_tax_category_id_seq'::regclass);


--
-- Name: transaction_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE transactions ALTER COLUMN transaction_id SET DEFAULT nextval('transactions_transaction_id_seq'::regclass);


--
-- Data for Name: account_types; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO account_types VALUES (100, 10, 'COST', NULL);
INSERT INTO account_types VALUES (110, 10, 'ACCUMULATED DEPRECIATION', NULL);
INSERT INTO account_types VALUES (200, 20, 'Cost', NULL);
INSERT INTO account_types VALUES (210, 20, 'ACCUMULATED AMORTISATION', NULL);
INSERT INTO account_types VALUES (300, 30, 'DEBTORS', NULL);
INSERT INTO account_types VALUES (310, 30, 'INVESTMENTS', NULL);
INSERT INTO account_types VALUES (320, 30, 'CURRENT BANK ACCOUNTS', NULL);
INSERT INTO account_types VALUES (330, 30, 'CASH ON HAND', NULL);
INSERT INTO account_types VALUES (340, 30, 'PRE-PAYMMENTS', NULL);
INSERT INTO account_types VALUES (400, 40, 'CREDITORS', NULL);
INSERT INTO account_types VALUES (410, 40, 'ADVANCED BILLING', NULL);
INSERT INTO account_types VALUES (420, 40, 'VAT', NULL);
INSERT INTO account_types VALUES (430, 40, 'WITHHOLDING TAX', NULL);
INSERT INTO account_types VALUES (500, 50, 'LOANS', NULL);
INSERT INTO account_types VALUES (600, 60, 'CAPITAL GRANTS', NULL);
INSERT INTO account_types VALUES (610, 60, 'ACCUMULATED SURPLUS', NULL);
INSERT INTO account_types VALUES (700, 70, 'SALES REVENUE', NULL);
INSERT INTO account_types VALUES (710, 70, 'OTHER INCOME', NULL);
INSERT INTO account_types VALUES (800, 80, 'COST OF REVENUE', NULL);
INSERT INTO account_types VALUES (900, 90, 'STAFF COSTS', NULL);
INSERT INTO account_types VALUES (910, 90, 'DIRECTORS ALLOWANCES', NULL);
INSERT INTO account_types VALUES (920, 90, 'TRAVEL', NULL);
INSERT INTO account_types VALUES (930, 90, 'ICT PROJECT', NULL);
INSERT INTO account_types VALUES (940, 90, 'SUBSCRIPTION FEES', NULL);
INSERT INTO account_types VALUES (950, 90, 'PROFESSIONAL FEES', NULL);
INSERT INTO account_types VALUES (960, 90, 'MARKETING EXPENSES', NULL);
INSERT INTO account_types VALUES (970, 90, 'DEPRECIATION', NULL);
INSERT INTO account_types VALUES (980, 90, 'FINANCE COSTS', NULL);
INSERT INTO account_types VALUES (990, 90, 'INSURANCE', NULL);
INSERT INTO account_types VALUES (905, 90, 'COMMUNICATIONS', NULL);
INSERT INTO account_types VALUES (915, 90, 'TRANSPORT', NULL);
INSERT INTO account_types VALUES (925, 90, 'POSTAL and COURIER', NULL);
INSERT INTO account_types VALUES (935, 90, 'STATIONERY', NULL);
INSERT INTO account_types VALUES (945, 90, 'REPAIRS', NULL);
INSERT INTO account_types VALUES (955, 90, 'OFFICE EXPENSES', NULL);
INSERT INTO account_types VALUES (965, 90, 'STRATEGIC PLANNING', NULL);
INSERT INTO account_types VALUES (975, 90, 'CORPORATE SOCIAL INVESTMENT', NULL);
INSERT INTO account_types VALUES (985, 90, 'OTHER EXPENSES', NULL);
INSERT INTO account_types VALUES (995, 90, 'TAXES', NULL);


--
-- Data for Name: accounts; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO accounts VALUES (10000, 100, 'COMPUTERS and EQUIPMENT', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (10005, 100, 'FURNITURE', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (11000, 110, 'COMPUTERS and EQUIPMENT', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (11005, 110, 'FURNITURE', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (20000, 200, 'INTANGIBLE ASSETS', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (20005, 200, 'NON CURRENT ASSETS: DEFFERED TAX', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (20010, 200, 'INTANGIBLE ASSETS: ACCOUNTING PACKAGE', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (21000, 210, 'ACCUMULATED AMORTISATION', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (30000, 300, 'TRADE DEBTORS', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (30005, 300, 'STAFF DEBTORS', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (30010, 300, 'OTHER DEBTORS', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (30025, 300, 'INVENTORY WORK IN PROGRESS', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (30030, 300, 'GOODS RECEIVED CLEARING ACCOUNT', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (31005, 310, 'UNIT TRUST INVESTMENTS', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (32005, 320, 'MPESA', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (33000, 330, 'CASH ACCOUNT', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (33005, 330, 'PETTY CASH', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (34000, 340, 'PREPAYMENTS', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (34005, 340, 'DEPOSITS', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (34010, 340, 'TAX RECOVERABLE', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (34015, 340, 'TOTAL REGISTRAR DEPOSITS', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (40000, 400, 'CREDITORS- ACCRUALS', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (40005, 400, 'ADVANCE BILLING', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (40010, 400, 'LEAVE - ACCRUALS', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (40015, 400, 'ACCRUED LIABILITIES: CORPORATE TAX', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (40020, 400, 'OTHER ACCRUALS', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (40025, 400, 'PROVISION FOR CREDIT NOTES', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (40030, 400, 'NSSF', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (40035, 400, 'NHIF', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (40045, 400, 'PAYE', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (40050, 400, 'PENSION', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (41000, 410, 'ADVANCED BILLING', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (42000, 420, 'INPUT', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (42005, 420, 'OUTPUT', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (42010, 420, 'REMITTANCE', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (43000, 430, 'WITHHOLDING TAX', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (50000, 500, 'BANK LOANS', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (60000, 600, 'CAPITAL GRANTS', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (60005, 600, 'ACCUMULATED AMORTISATION OF CAPITAL GRANTS', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (61000, 610, 'ACCUMULATED SURPLUS', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (61005, 610, 'RETAINED EARNINGS', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (61010, 610, 'ASSET REVALUATION GAIN / LOSS', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (70010, 700, 'SERVICE SALES', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (70015, 700, 'SALES DISCOUNT', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (71000, 710, 'FAIR VALUE GAIN/LOSS IN INVESTMENTS', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (71005, 710, 'DONATION', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (71010, 710, 'EXCHANGE GAIN(LOSS)', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (71015, 710, 'REGISTRAR TRAINING FEES', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (71020, 710, 'DISPOSAL OF ASSETS', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (71025, 710, 'DIVIDEND INCOME', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (71035, 710, 'TRAINING, FORUM, MEETINGS and WORKSHOPS', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (80000, 800, 'COST OF GOODS', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (90000, 900, 'BASIC SALARY', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (90005, 900, 'LEAVE ALLOWANCES', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (90010, 900, 'AIRTIME ', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (90012, 900, 'TRANSPORT ALLOWANCE', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (90015, 900, 'REMOTE ACCESS', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (90020, 900, 'ICEA EMPLOYER PENSION CONTRIBUTION', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (90025, 900, 'NSSF EMPLOYER CONTRIBUTION', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (90035, 900, 'CAPACITY BUILDING - TRAINING', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (90040, 900, 'INTERNSHIP ALLOWANCES', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (90045, 900, 'BONUSES', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (90050, 900, 'LEAVE ACCRUAL', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (90055, 900, 'WELFARE', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (90056, 900, 'STAFF WELLFARE: WATER', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (90057, 900, 'STAFF WELLFARE: TEA', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (90058, 900, 'STAFF WELLFARE: OTHER CONSUMABLES', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (90060, 900, 'MEDICAL INSURANCE', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (90065, 900, 'GROUP PERSONAL ACCIDENT AND WIBA', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (90070, 900, 'STAFF SATISFACTION SURVEY', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (90075, 900, 'GROUP LIFE INSURANCE', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (90500, 905, 'FIXED LINES', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (90505, 905, 'CALLING CARDS', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (90510, 905, 'LEASE LINES', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (90515, 905, 'REMOTE ACCESS', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (90520, 905, 'LEASE LINE', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (91000, 910, 'SITTING ALLOWANCES', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (91005, 910, 'HONORARIUM', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (91010, 910, 'WORKSHOPS and SEMINARS', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (91500, 915, 'CAB FARE', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (91505, 915, 'FUEL', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (91510, 915, 'BUS FARE', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (91515, 915, 'POSTAGE and BOX RENTAL', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (92000, 920, 'TRAINING', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (92005, 920, 'BUSINESS PROSPECTING', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (92505, 925, 'DIRECTORY LISTING', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (92510, 925, 'COURIER', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (93000, 930, 'IP TRAINING', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (93010, 930, 'COMPUTER SUPPORT', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (93500, 935, 'PRINTED MATTER', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (93505, 935, 'PAPER', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (93510, 935, 'OTHER CONSUMABLES', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (93515, 935, 'TONER and CATRIDGE', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (93520, 935, 'COMPUTER ACCESSORIES', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (94010, 940, 'LICENSE FEE', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (94015, 940, 'SYSTEM SUPPORT FEES', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (94500, 945, 'FURNITURE', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (94505, 945, 'COMPUTERS and EQUIPMENT', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (94510, 945, 'JANITORIAL', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (95000, 950, 'AUDIT', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (95005, 950, 'MARKETING AGENCY', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (95010, 950, 'ADVERTISING', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (95015, 950, 'CONSULTANCY', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (95020, 950, 'TAX CONSULTANCY', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (95025, 950, 'MARKETING CAMPAIGN', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (95030, 950, 'PROMOTIONAL MATERIALS', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (95035, 950, 'RECRUITMENT', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (95040, 950, 'ANNUAL GENERAL MEETING', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (95045, 950, 'SEMINARS, WORKSHOPS and MEETINGS', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (95500, 955, 'CLEANING', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (95505, 955, 'NEWSPAPERS', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (95510, 955, 'OTHER CONSUMABLES', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (95515, 955, 'ADMINISTRATIVE EXPENSES', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (96005, 960, 'WEBSITE REVAMPING COSTS', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (96505, 965, 'STRATEGIC PLANNING', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (96510, 965, 'MONITORING and EVALUATION', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (97000, 970, 'COMPUTERS and EQUIPMENT', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (97005, 970, 'FURNITURE', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (97010, 970, 'AMMORTISATION OF INTANGIBLE ASSETS', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (97500, 975, 'CORPORATE SOCIAL INVESTMENT', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (97505, 975, 'DONATION', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (98000, 980, 'LEDGER FEES', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (98005, 980, 'BOUNCED CHEQUE CHARGES', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (98010, 980, 'OTHER FEES', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (98015, 980, 'SALARY TRANSFERS', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (98020, 980, 'UPCOUNTRY CHEQUES', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (98025, 980, 'SAFETY DEPOSIT BOX', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (98030, 980, 'MPESA TRANSFERS', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (98035, 980, 'CUSTODY FEES', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (98500, 985, 'BAD DEBTS WRITTEN OFF', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (98505, 985, 'PURCHASE DISCOUNT', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (98510, 985, 'COST OF GOODS SOLD (COGS)', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (98515, 985, 'PURCHASE PRICE VARIANCE', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (99000, 990, 'ALL RISKS', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (99005, 990, 'FIRE and PERILS', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (40040, 400, 'INVESTORS', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (30020, 300, 'BORROWERS', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (98040, 980, 'COMMISSION', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (70005, 700, 'CHARGES', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (71030, 710, 'LOAN INTEREST', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (30015, 300, 'OUTSTANDING INCOME', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (99010, 990, 'BURGLARY', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (99015, 990, 'COMPUTER POLICY', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (99035, 990, 'TAXES: FRINGE BENEFIT TAX', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (99500, 995, 'EXCISE DUTY', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (99505, 995, 'FINES and PENALTIES', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (99510, 995, 'CORPORATE TAX', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (99590, 995, 'SURPLUS/DEFICIT', false, true, NULL, false, NULL, NULL);
INSERT INTO accounts VALUES (32000, 320, 'BANK', false, true, 'Generic A/C  for bank transactions', false, NULL, NULL);
INSERT INTO accounts VALUES (5555, 320, 'Queensway One', false, true, 'test', true, 1, '556565');
INSERT INTO accounts VALUES (6666, 320, 'KCB One', false, true, 'test', true, 2, '454656');


--
-- Data for Name: accounts_class; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO accounts_class VALUES (10, 1, 'ASSETS', 'FIXED ASSETS', NULL);
INSERT INTO accounts_class VALUES (20, 1, 'ASSETS', 'INTANGIBLE ASSETS', NULL);
INSERT INTO accounts_class VALUES (30, 1, 'ASSETS', 'CURRENT ASSETS', NULL);
INSERT INTO accounts_class VALUES (40, 2, 'LIABILITIES', 'CURRENT LIABILITIES', NULL);
INSERT INTO accounts_class VALUES (50, 2, 'LIABILITIES', 'LONG TERM LIABILITIES', NULL);
INSERT INTO accounts_class VALUES (60, 3, 'EQUITY', 'EQUITY AND RESERVES', NULL);
INSERT INTO accounts_class VALUES (70, 4, 'REVENUE', 'REVENUE AND OTHER INCOME', NULL);
INSERT INTO accounts_class VALUES (80, 5, 'COST OF REVENUE', 'COST OF REVENUE', NULL);
INSERT INTO accounts_class VALUES (90, 6, 'EXPENSES', 'EXPENSES', NULL);


--
-- Data for Name: address; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Data for Name: approval_phases; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Data for Name: approval_types; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO approval_types VALUES (0, 'Final', NULL);


--
-- Data for Name: approvals; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Data for Name: auction; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Data for Name: auction_phase; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Data for Name: bank; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO bank VALUES (1, '030', 'BARC', 'Barclays Bank of Kenya', NULL);
INSERT INTO bank VALUES (2, '999', 'KCB', 'Kenya Commercial Bank', NULL);
INSERT INTO bank VALUES (3, '999', 'Equity', 'Equity Bank', NULL);
INSERT INTO bank VALUES (4, '999', 'CooP', 'Cooperative Bank of Kenya', NULL);
INSERT INTO bank VALUES (5, 'FF ', 'FF', 'Family', NULL);


--
-- Data for Name: bank_branch; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO bank_branch VALUES (1, 1, 'Queensway Branch', 'adfaf');
INSERT INTO bank_branch VALUES (2, 5, 'Koinange Branch', NULL);


--
-- Data for Name: borrower; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO borrower VALUES (4, 12, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Mabura', 'Zeguru', 'Mwe', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'eata', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO borrower VALUES (5, 14, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'N', 'Erick', 'Ngugi', '25231170', NULL, 'Zimmaman', 'Zimmaman', 'Kamiti Rd', 'Nairobi', NULL, ' 2015', '00200', 'Nairobi', 'Kenya', '2213760', '2244098', '0724107354', 'ngubia.erick@yahoo.com', NULL);
INSERT INTO borrower VALUES (1, 1, 'Pember Maize Millers', '2000-09-05', 'Supervisor', '555 Kitale', 'Kitale', '020 299834', '020 299834', 200000, 20000, 60000, 50000, false, NULL, NULL, NULL, 0, 0, NULL, 0, 0, 0, 0, 0, 0, NULL, 'jAMES', 'Opiyo', 'Onyango', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Kenya', NULL, NULL, NULL, NULL, NULL);
INSERT INTO borrower VALUES (2, 4, 'Safcom', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Michael', 'Jalango', 'J', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Kenya', NULL, NULL, NULL, NULL, NULL);
INSERT INTO borrower VALUES (6, 18, 'Center For Research', '2007-08-02', 'Executive Director', '21144', 'nairobi', '0721833322', NULL, 200000, 60000, 60000, 100000, true, 'Ecuspace Publishers', 'books', 'unknown', NULL, NULL, 2009, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Odongo', 'Nicholas', 'Otieno', 'A1089040', 'Nairobi', 'J kangethe', 'Adams', 'j kangethe', 'Nairobi', NULL, '21144', '0800', 'Nairobi', 'Kenya', '0721833322', NULL, '0721833322', 'africa@yahoo.com', 'newbury');


--
-- Data for Name: borrower_contact; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO borrower_contact VALUES (1, 3, 1, 'adfafd', '2011-09-28', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Kenya', NULL, NULL, NULL, NULL);


--
-- Data for Name: cheque_status; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO cheque_status VALUES (1, 'PENDING', NULL);
INSERT INTO cheque_status VALUES (2, 'CLEARED', NULL);
INSERT INTO cheque_status VALUES (3, 'DISHONOURED', NULL);


--
-- Data for Name: civil_action; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Data for Name: collateral; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO collateral VALUES (2, NULL, true, true, 'Bw Ndai', 'KAA 665C', 'SUBARU', 'impreza', 'hatchback', 'blue', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);


--
-- Data for Name: commission_payment; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO commission_payment VALUES (5, 16, 'AKKDFAJ', 15000, '2011-11-15', false, false, NULL);
INSERT INTO commission_payment VALUES (6, 27, 'AKKDFAJ', 6300, '2011-10-10', false, false, 'test');
INSERT INTO commission_payment VALUES (7, 35, '0088787', 175000, '2011-10-12', false, false, 'test');


--
-- Data for Name: deduction; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO deduction VALUES (1, NULL, 50000, NULL, NULL);
INSERT INTO deduction VALUES (2, 3, 50000, '2011-09-23', NULL);
INSERT INTO deduction VALUES (3, 5, 300000, '2011-10-20', NULL);
INSERT INTO deduction VALUES (6, 15, 100000, '2011-10-06', NULL);
INSERT INTO deduction VALUES (7, 15, 50000, '2011-09-22', NULL);
INSERT INTO deduction VALUES (8, 15, 50000, '2011-09-22', NULL);
INSERT INTO deduction VALUES (9, 16, 500000, '2011-10-20', NULL);
INSERT INTO deduction VALUES (10, 16, 500000, '2011-10-10', NULL);


--
-- Data for Name: defaulter; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Data for Name: entity_subscriptions; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO entity_subscriptions VALUES (0, 0, 0, 0, NULL);
INSERT INTO entity_subscriptions VALUES (4, 2, 1, 0, NULL);
INSERT INTO entity_subscriptions VALUES (2, 5, 2, 0, NULL);
INSERT INTO entity_subscriptions VALUES (5, 8, 3, 0, NULL);
INSERT INTO entity_subscriptions VALUES (6, 2, 4, 0, NULL);
INSERT INTO entity_subscriptions VALUES (8, 1, 5, 0, NULL);
INSERT INTO entity_subscriptions VALUES (9, 10, 6, 0, NULL);
INSERT INTO entity_subscriptions VALUES (10, 7, 8, 0, NULL);
INSERT INTO entity_subscriptions VALUES (11, 7, 9, 0, NULL);
INSERT INTO entity_subscriptions VALUES (12, 10, 10, 0, NULL);
INSERT INTO entity_subscriptions VALUES (13, 10, 11, 0, NULL);
INSERT INTO entity_subscriptions VALUES (14, 2, 12, 0, NULL);
INSERT INTO entity_subscriptions VALUES (15, 10, 13, 0, NULL);
INSERT INTO entity_subscriptions VALUES (16, 2, 14, 0, NULL);
INSERT INTO entity_subscriptions VALUES (17, 7, 15, 0, NULL);
INSERT INTO entity_subscriptions VALUES (18, 10, 17, 0, NULL);
INSERT INTO entity_subscriptions VALUES (19, 2, 18, 0, NULL);


--
-- Data for Name: entity_types; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO entity_types VALUES (0, 'Users', 'user', 0, NULL, NULL);
INSERT INTO entity_types VALUES (3, 'Supplier', 'supplier', 0, NULL, NULL);
INSERT INTO entity_types VALUES (1, 'Staff', 'staff', 0, 'Staff of Meridian company', NULL);
INSERT INTO entity_types VALUES (5, 'Partner', 'partner', 8, 'Business partners of Meridian company', NULL);
INSERT INTO entity_types VALUES (2, 'Client', 'client', 0, 'Clients/borrowers of the company', NULL);
INSERT INTO entity_types VALUES (7, 'Admin', 'admin', 9, 'Application Administrators', NULL);
INSERT INTO entity_types VALUES (8, 'Spouse / Alternative Contact', 'alternativecontact', 89, 'Spouses of borrowers', NULL);
INSERT INTO entity_types VALUES (9, 'Referee', 'referee', 78, NULL, NULL);
INSERT INTO entity_types VALUES (10, 'Investor', 'investor', 45, NULL, NULL);


--
-- Data for Name: entitys; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO entitys VALUES (0, 0, 7, 'root', 'root', true, true, 'admin', '2011-09-05 00:00:00', true, 'e2a7106f1cc8bb1e1318df70aa0a3540', 'enter', NULL);
INSERT INTO entitys VALUES (2, 1, 5, 'Sonko One', 'sonko1', false, false, 'partner', '2011-09-05 00:00:00', true, 'e2a7106f1cc8bb1e1318df70aa0a3540', '853W171AY', NULL);
INSERT INTO entitys VALUES (3, 1, 8, 'Agness Ajuma', NULL, false, false, NULL, '2011-09-08 10:02:43.952075', true, 'e2a7106f1cc8bb1e1318df70aa0a3540', 'enter', NULL);
INSERT INTO entitys VALUES (5, 1, 1, 'Front Office User One', 'frontoffice1', false, false, 'staff', '2011-09-08 00:00:00', true, 'e2a7106f1cc8bb1e1318df70aa0a3540', 'enter', NULL);
INSERT INTO entitys VALUES (6, 0, 10, 'Mike Shakur Beya', 'investor1', false, false, 'investor', '2011-09-09 10:41:57.356878', false, 'e2a7106f1cc8bb1e1318df70aa0a3540', 'enter', NULL);
INSERT INTO entitys VALUES (8, 0, 7, 'Meridian', 'Meridian', false, false, 'admin', '2011-09-27 12:25:05.685604', true, 'e2a7106f1cc8bb1e1318df70aa0a3540', 'enter', NULL);
INSERT INTO entitys VALUES (9, 0, 7, 'Meridian', NULL, false, false, 'admin', '2011-09-27 12:25:23.506876', true, 'e2a7106f1cc8bb1e1318df70aa0a3540', 'enter', NULL);
INSERT INTO entitys VALUES (10, 1, 10, 'Makau Johnstone Kasuve', 'jmakau', false, false, 'investor', '2011-09-30 12:28:48.507726', true, 'e2a7106f1cc8bb1e1318df70aa0a3540', 'enter', NULL);
INSERT INTO entitys VALUES (11, 1, 10, 'lee chow cow', 'clee', false, false, 'investor', '2011-09-30 16:26:57.101005', true, 'e2a7106f1cc8bb1e1318df70aa0a3540', 'enter', NULL);
INSERT INTO entitys VALUES (12, 1, 2, 'Mabura Zeguru Mwe', 'zmabura', false, false, 'client', '2011-10-03 10:56:22.135515', true, 'e2a7106f1cc8bb1e1318df70aa0a3540', 'enter', NULL);
INSERT INTO entitys VALUES (13, 1, 10, 'Kibaki Emilio Stano', 'ekibaki', false, false, 'investor', '2011-10-10 12:43:38.766384', true, 'e2a7106f1cc8bb1e1318df70aa0a3540', 'enter', NULL);
INSERT INTO entitys VALUES (14, 1, 2, 'N Erick Ngugi', 'en', false, false, 'client', '2011-10-10 13:31:29.002139', true, 'e2a7106f1cc8bb1e1318df70aa0a3540', 'enter', NULL);
INSERT INTO entitys VALUES (1, 1, 2, 'jAMES Opiyo Onyango', 'mkopaji1', false, false, 'client', '2011-09-05 00:00:00', true, 'e2a7106f1cc8bb1e1318df70aa0a3540', '100R706SH', NULL);
INSERT INTO entitys VALUES (4, 1, 2, 'Michael Jalango J', 'm.jalango', false, false, 'client', '2011-09-08 00:00:00', true, 'e2a7106f1cc8bb1e1318df70aa0a3540', 'enter', NULL);
INSERT INTO entitys VALUES (15, 1, 7, 'Rita Junior', 'rmarley', false, false, 'admin', '2011-10-12 14:47:17.145917', true, 'e2a7106f1cc8bb1e1318df70aa0a3540', 'enter', NULL);
INSERT INTO entitys VALUES (17, 1, 10, 'Simone Osinyo Opiyo', 'osimone', false, false, 'investor', '2011-10-12 14:59:18.644615', true, 'e2a7106f1cc8bb1e1318df70aa0a3540', 'enter', NULL);
INSERT INTO entitys VALUES (18, 1, 2, 'Odongo Nicholas Otieno', 'nodongo', false, false, 'client', '2011-10-12 15:38:09.221529', true, 'e2a7106f1cc8bb1e1318df70aa0a3540', 'enter', NULL);


--
-- Data for Name: entry_forms; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Data for Name: entry_sub_forms; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Data for Name: fee_type; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO fee_type VALUES (1, 'Fixed Charge (Kshs)', NULL);
INSERT INTO fee_type VALUES (2, 'Percentage (%)', NULL);


--
-- Data for Name: fees; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO fees VALUES (1, 'CHK', 'Cheque Fees', NULL, NULL, 1, 150, 0);
INSERT INTO fees VALUES (5, 'BF', 'BOUNCED CHEQUE FEE', NULL, NULL, 1, 3000, 0);
INSERT INTO fees VALUES (4, 'LP', 'LATE PAYMENT FEE', NULL, 'NOT LESS THAN 1500', 2, 10, 1500);
INSERT INTO fees VALUES (6, 'DC', 'DEBT COLLECTION FEE', NULL, 'not less than 3000', 2, 15, 3000);
INSERT INTO fees VALUES (3, NULL, 'PROCESSING FEE', NULL, NULL, 1, 2000, 0);
INSERT INTO fees VALUES (2, 'CSH', 'Cashing Fee', NULL, NULL, 1, 2500, 0);


--
-- Data for Name: fields; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Data for Name: fiscal_years; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO fiscal_years VALUES ('2011', '2011-01-01', '2011-12-31', true, false, NULL);


--
-- Data for Name: forms; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Data for Name: gls; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO gls VALUES (6, 11, 40040, 25000, 0, NULL, '2011-10-03');
INSERT INTO gls VALUES (7, 11, 32000, 0, 25000, NULL, '2011-10-03');
INSERT INTO gls VALUES (8, 12, 40040, 0, 250000, NULL, '2011-10-03');
INSERT INTO gls VALUES (9, 12, 32000, 250000, 0, NULL, '2011-10-03');
INSERT INTO gls VALUES (10, 15, 40040, 100000, 0, NULL, '2011-10-03');
INSERT INTO gls VALUES (11, 15, 32000, 0, 100000, NULL, '2011-10-03');
INSERT INTO gls VALUES (14, 18, 98040, 15000, 0, NULL, '2011-10-03');
INSERT INTO gls VALUES (15, 18, 32000, 0, 15000, NULL, '2011-10-03');
INSERT INTO gls VALUES (24, 24, 30020, 500000, 0, NULL, '2011-10-03');
INSERT INTO gls VALUES (26, 24, 70005, 0, 500, NULL, '2011-10-03');
INSERT INTO gls VALUES (27, 25, 40040, 50000, 0, NULL, '2011-10-03');
INSERT INTO gls VALUES (28, 25, 32000, 0, 50000, NULL, '2011-10-03');
INSERT INTO gls VALUES (29, 26, 40040, 50000, 0, NULL, '2011-10-03');
INSERT INTO gls VALUES (30, 26, 32000, 0, 50000, NULL, '2011-10-03');
INSERT INTO gls VALUES (31, 27, 40040, 0, 2000000, NULL, '2011-10-03');
INSERT INTO gls VALUES (32, 27, 32000, 2000000, 0, NULL, '2011-10-03');
INSERT INTO gls VALUES (33, 28, 40040, 500000, 0, NULL, '2011-10-03');
INSERT INTO gls VALUES (34, 28, 32000, 0, 500000, NULL, '2011-10-03');
INSERT INTO gls VALUES (35, 29, 40040, 500000, 0, NULL, '2011-10-03');
INSERT INTO gls VALUES (36, 29, 32000, 0, 500000, NULL, '2011-10-03');
INSERT INTO gls VALUES (37, 31, 40040, 0, 555000, NULL, '2011-10-03');
INSERT INTO gls VALUES (38, 31, 32000, 555000, 0, NULL, '2011-10-03');
INSERT INTO gls VALUES (42, 33, 30020, 0, 12500, 'principal component of the monthly installment', '2011-10-03');
INSERT INTO gls VALUES (43, 33, 32000, 12500, 0, 'principal component of the monthly installment', '2011-10-03');
INSERT INTO gls VALUES (44, 33, 71030, 0, 12500, 'interest component', '2011-10-03');
INSERT INTO gls VALUES (45, 33, 32000, 12500, 0, 'interest component', '2011-10-03');
INSERT INTO gls VALUES (46, 34, 30020, 0, 12500, 'principal component of the monthly installment', '2011-10-03');
INSERT INTO gls VALUES (47, 34, 32000, 12500, 0, 'principal component of the monthly installment', '2011-10-03');
INSERT INTO gls VALUES (48, 34, 71030, 0, 12500, 'interest component', '2011-10-03');
INSERT INTO gls VALUES (49, 34, 32000, 12500, 0, 'interest component', '2011-10-03');
INSERT INTO gls VALUES (50, 36, 30020, 12500, 0, 'reversal. principal component', '2011-10-03');
INSERT INTO gls VALUES (51, 36, 32000, 0, 12500, 'reversal. principal component', '2011-10-03');
INSERT INTO gls VALUES (52, 36, 71030, 7500, 0, 'revearsal. interest income', '2011-10-03');
INSERT INTO gls VALUES (53, 36, 32000, 0, 7500, 'reversal. interest income', '2011-10-03');
INSERT INTO gls VALUES (54, 36, 70005, 0, 10, 'late payment penalty', '2011-10-03');
INSERT INTO gls VALUES (55, 36, 30015, 10, 0, 'late payment penalty', '2011-10-03');
INSERT INTO gls VALUES (56, 36, 70005, 0, 3000, 'bounced cheque fee. bank charge', '2011-10-03');
INSERT INTO gls VALUES (57, 36, 30015, 3000, 0, 'bounced cheque fee. bank charge', '2011-10-03');
INSERT INTO gls VALUES (58, 36, 70005, 0, 15, 'debt collection fee', '2011-10-03');
INSERT INTO gls VALUES (59, 36, 30015, 15, 0, 'debt colletion fee', '2011-10-03');
INSERT INTO gls VALUES (60, 65, 40040, 0, 200000, NULL, '2011-10-10');
INSERT INTO gls VALUES (61, 65, 32000, 200000, 0, NULL, '2011-10-10');
INSERT INTO gls VALUES (62, 69, 98040, 6300, 0, NULL, '2011-10-10');
INSERT INTO gls VALUES (63, 69, 32000, 0, 6300, NULL, '2011-10-10');
INSERT INTO gls VALUES (64, 196, 30020, 195500, 0, NULL, '2011-10-10');
INSERT INTO gls VALUES (66, 196, 70005, 0, 2000, NULL, '2011-10-10');
INSERT INTO gls VALUES (65, 196, 32000, 0, 193500, NULL, '2011-10-10');
INSERT INTO gls VALUES (25, 24, 32000, 0, 499500, NULL, '2011-10-03');
INSERT INTO gls VALUES (67, 198, 40040, 0, 5000000, NULL, '2011-10-12');
INSERT INTO gls VALUES (68, 198, 32000, 5000000, 0, NULL, '2011-10-12');
INSERT INTO gls VALUES (69, 199, 98040, 175000, 0, NULL, '2011-10-12');
INSERT INTO gls VALUES (70, 199, 32000, 0, 175000, NULL, '2011-10-12');
INSERT INTO gls VALUES (71, 288, 30020, 38000, 0, NULL, '2011-10-12');
INSERT INTO gls VALUES (72, 288, 32000, 0, 38000, NULL, '2011-10-12');
INSERT INTO gls VALUES (73, 288, 70005, 0, 2000, NULL, '2011-10-12');
INSERT INTO gls VALUES (74, 289, 30020, 0, 13333.333, 'principal component of the monthly installment', '2011-10-12');
INSERT INTO gls VALUES (75, 289, 32000, 13333.333, 0, 'principal component of the monthly installment', '2011-10-12');
INSERT INTO gls VALUES (76, 289, 71030, 0, 8000, 'interest component', '2011-10-12');
INSERT INTO gls VALUES (77, 289, 32000, 8000, 0, 'interest component', '2011-10-12');
INSERT INTO gls VALUES (78, 291, 30020, 0, 13333.333, 'principal component of the monthly installment', '2011-10-12');
INSERT INTO gls VALUES (79, 291, 32000, 13333.333, 0, 'principal component of the monthly installment', '2011-10-12');
INSERT INTO gls VALUES (80, 291, 71030, 0, 8000, 'interest component', '2011-10-12');
INSERT INTO gls VALUES (81, 291, 32000, 8000, 0, 'interest component', '2011-10-12');
INSERT INTO gls VALUES (82, 293, 30020, 0, 13333.333, 'principal component of the monthly installment', '2011-10-12');
INSERT INTO gls VALUES (83, 293, 32000, 13333.333, 0, 'principal component of the monthly installment', '2011-10-12');
INSERT INTO gls VALUES (84, 293, 71030, 0, 8000, 'interest component', '2011-10-12');
INSERT INTO gls VALUES (85, 293, 32000, 8000, 0, 'interest component', '2011-10-12');
INSERT INTO gls VALUES (86, 296, 30020, 13333.333, 0, 'reversal. principal component', '2011-10-12');
INSERT INTO gls VALUES (87, 296, 32000, 0, 13333.333, 'reversal. principal component', '2011-10-12');
INSERT INTO gls VALUES (88, 296, 71030, 8000, 0, 'revearsal. interest income', '2011-10-12');
INSERT INTO gls VALUES (89, 296, 32000, 0, 8000, 'reversal. interest income', '2011-10-12');
INSERT INTO gls VALUES (90, 296, 70005, 0, 10, 'late payment penalty', '2011-10-12');
INSERT INTO gls VALUES (91, 296, 30015, 10, 0, 'late payment penalty', '2011-10-12');
INSERT INTO gls VALUES (92, 296, 70005, 0, 3000, 'bounced cheque fee. bank charge', '2011-10-12');
INSERT INTO gls VALUES (93, 296, 30015, 3000, 0, 'bounced cheque fee. bank charge', '2011-10-12');
INSERT INTO gls VALUES (94, 296, 70005, 0, 15, 'debt collection fee', '2011-10-12');
INSERT INTO gls VALUES (95, 296, 30015, 15, 0, 'debt colletion fee', '2011-10-12');


--
-- Data for Name: investigation; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Data for Name: investment; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO investment VALUES (5, 1, 1, 500000, 0, 0, 0, 0, '2011-10-31', NULL, true, NULL, NULL);
INSERT INTO investment VALUES (3, 1, 1, 200000, 0, 0, 0, 0, '2011-09-09', NULL, true, NULL, NULL);
INSERT INTO investment VALUES (14, 1, 1, 25000, 0, 0, 0, 0, '2011-10-01', NULL, false, NULL, NULL);
INSERT INTO investment VALUES (15, 2, 1, 250000, 0, 0, 0, 0, '2011-10-31', NULL, false, NULL, NULL);
INSERT INTO investment VALUES (16, 3, 1, 2000000, 0, 0, 0, 0, '2011-10-30', NULL, false, NULL, NULL);
INSERT INTO investment VALUES (17, 3, 1, 555000, 0, 0, 0, 0, '2011-11-17', NULL, false, NULL, NULL);
INSERT INTO investment VALUES (18, 4, 1, 200000, 0, 0, 0, 0, '2011-12-30', NULL, false, NULL, NULL);
INSERT INTO investment VALUES (19, 5, 1, 5000000, 0, 0, 0, 0, '2012-01-02', NULL, false, 'test', NULL);


--
-- Data for Name: investment_maturity; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO investment_maturity VALUES (15, 5, 60, 200000, 10000, NULL);
INSERT INTO investment_maturity VALUES (16, 3, 60, 150000, 7500, NULL);
INSERT INTO investment_maturity VALUES (17, 5, 61, 200000, 6000, NULL);
INSERT INTO investment_maturity VALUES (18, 3, 61, 150000, 4500, NULL);
INSERT INTO investment_maturity VALUES (19, 5, 62, 200000, 6000, NULL);
INSERT INTO investment_maturity VALUES (20, 3, 62, 150000, 4500, NULL);
INSERT INTO investment_maturity VALUES (21, 5, 63, 200000, 7000, NULL);
INSERT INTO investment_maturity VALUES (22, 3, 63, 150000, 5250, NULL);
INSERT INTO investment_maturity VALUES (23, 14, 63, 25000, 875, NULL);
INSERT INTO investment_maturity VALUES (24, 15, 63, 50000, 1750, NULL);
INSERT INTO investment_maturity VALUES (25, 16, 63, 1000000, 35000, NULL);
INSERT INTO investment_maturity VALUES (26, 17, 63, 555000, 19425, NULL);
INSERT INTO investment_maturity VALUES (27, 18, 63, 200000, 7000, NULL);
INSERT INTO investment_maturity VALUES (28, 5, 64, 200000, 7000, NULL);
INSERT INTO investment_maturity VALUES (29, 3, 64, 150000, 5250, NULL);
INSERT INTO investment_maturity VALUES (30, 14, 64, 25000, 875, NULL);
INSERT INTO investment_maturity VALUES (31, 15, 64, 50000, 1750, NULL);
INSERT INTO investment_maturity VALUES (32, 16, 64, 1000000, 35000, NULL);
INSERT INTO investment_maturity VALUES (33, 17, 64, 555000, 19425, NULL);
INSERT INTO investment_maturity VALUES (34, 18, 64, 200000, 7000, NULL);
INSERT INTO investment_maturity VALUES (35, 19, 64, 5000000, 175000, NULL);


--
-- Data for Name: investment_type; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO investment_type VALUES (3, 'test', NULL, 4.30000019);
INSERT INTO investment_type VALUES (1, 'Default', 'the default product', 3.5);


--
-- Data for Name: investor; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO investor VALUES (1, 6, 'Investor', 'Mike', 'Shakur', 'Beya');
INSERT INTO investor VALUES (2, 10, 'test', 'Makau', 'Johnstone', 'Kasuve');
INSERT INTO investor VALUES (3, 11, NULL, 'lee', 'chow', 'cow');
INSERT INTO investor VALUES (4, 13, 'test', 'Kibaki', 'Emilio', 'Stano');
INSERT INTO investor VALUES (5, 17, 'test', 'Simone', 'Osinyo', 'Opiyo');


--
-- Data for Name: journals; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO journals VALUES (1, 60, '2011-09-26', false, 'test entry', NULL);
INSERT INTO journals VALUES (2, 60, '2011-09-26', false, 'paid 5000 Kshs to pizza delivery boy', 'test');
INSERT INTO journals VALUES (11, 60, '2011-09-30', false, 'New investment Kshs(25000) from Mike Shakur Beya', NULL);
INSERT INTO journals VALUES (12, 60, '2011-09-30', false, 'New investment Kshs(250000) from Makau Johnstone Kasuve', NULL);
INSERT INTO journals VALUES (15, 60, '2011-09-30', false, 'Reducing investment Kshs(100000) for  Makau Johnstone Kasuve', NULL);
INSERT INTO journals VALUES (18, 60, '2011-09-30', false, 'Paid commision Kshs(15000) to  Mike Shakur Beya', NULL);
INSERT INTO journals VALUES (24, 60, '2011-09-30', false, 'Reinbursed Kshs(500000) to    ', NULL);
INSERT INTO journals VALUES (25, 60, '2011-09-30', false, 'Reducing investment Kshs(50000) for  Makau Johnstone Kasuve', NULL);
INSERT INTO journals VALUES (26, 60, '2011-09-30', false, 'Reducing investment Kshs(50000) for  Makau Johnstone Kasuve', NULL);
INSERT INTO journals VALUES (27, 60, '2011-09-30', false, 'New investment Kshs(2000000) from lee chow cow', NULL);
INSERT INTO journals VALUES (28, 60, '2011-09-30', false, 'Reducing investment Kshs(500000) for  lee chow cow', NULL);
INSERT INTO journals VALUES (29, 60, '2011-09-30', false, 'Reducing investment Kshs(500000) for  lee chow cow', NULL);
INSERT INTO journals VALUES (31, 61, '2011-09-30', false, 'New investment Kshs(555000) from lee chow cow', NULL);
INSERT INTO journals VALUES (33, 62, '2011-10-03', false, 'Received Installment Kshs(20000) from  Mabura Zeguru Mwe', NULL);
INSERT INTO journals VALUES (34, 62, '2011-10-03', false, 'Received Installment Kshs(20000) from  Mabura Zeguru Mwe', NULL);
INSERT INTO journals VALUES (36, 62, '2011-10-03', false, NULL, NULL);
INSERT INTO journals VALUES (65, 62, '2011-10-10', false, 'New investment Kshs(200000) from Kibaki Emilio Stano', NULL);
INSERT INTO journals VALUES (69, 63, '2011-10-10', false, 'Paid commision Kshs(6300) to  Kibaki Emilio Stano', NULL);
INSERT INTO journals VALUES (196, 63, '2011-10-10', false, 'Reinbursed Kshs(195500) to  N Erick Ngugi', NULL);
INSERT INTO journals VALUES (198, 63, '2011-10-12', false, 'New investment Kshs(5000000) from Simone Osinyo Opiyo', NULL);
INSERT INTO journals VALUES (199, 64, '2011-10-12', false, 'Paid commision Kshs(175000) to  Simone Osinyo Opiyo', NULL);
INSERT INTO journals VALUES (288, 64, '2011-10-12', false, 'Reinbursed Kshs(38000) to  Odongo Nicholas Otieno', NULL);
INSERT INTO journals VALUES (289, 64, '2011-10-12', false, 'Received Installment Kshs(15334) from  Odongo Nicholas Otieno', NULL);
INSERT INTO journals VALUES (291, 64, '2011-10-12', false, 'Received Installment Kshs(15334) from  Odongo Nicholas Otieno', NULL);
INSERT INTO journals VALUES (293, 64, '2011-10-12', false, 'Received Installment Kshs(15334) from  Odongo Nicholas Otieno', NULL);
INSERT INTO journals VALUES (296, 64, '2011-10-12', false, 'Reversal of dishonoured cheque No(235) belonging to  Odongo Nicholas Otieno', NULL);


--
-- Data for Name: loan_monthly; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO loan_monthly VALUES (2, 6, 63, 17500, 116667, 0, 0, NULL);
INSERT INTO loan_monthly VALUES (3, 13, 63, 1000, 20000, 0, 0, NULL);
INSERT INTO loan_monthly VALUES (4, 6, 64, 5010.4126, 116667, 0, 0, NULL);
INSERT INTO loan_monthly VALUES (5, 13, 64, 545.833313, 20000, 0, 0, NULL);


--
-- Data for Name: loan_purpose; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO loan_purpose VALUES (1, 'Business', NULL);
INSERT INTO loan_purpose VALUES (2, 'Furniture', NULL);
INSERT INTO loan_purpose VALUES (3, 'School Fees', NULL);
INSERT INTO loan_purpose VALUES (4, 'Property Purchase', NULL);
INSERT INTO loan_purpose VALUES (5, 'Medical', NULL);
INSERT INTO loan_purpose VALUES (6, 'Repayment of other loan', NULL);
INSERT INTO loan_purpose VALUES (7, 'Holiday', NULL);
INSERT INTO loan_purpose VALUES (8, 'Other', NULL);


--
-- Data for Name: loan_reinbursment; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO loan_reinbursment VALUES (2, 6, 500000, 2, '56gygty', 'test', '2011-09-26', NULL, NULL, NULL, NULL, 1);
INSERT INTO loan_reinbursment VALUES (9, 6, 500000, 2, '56gygty', 'test', '2011-09-30', NULL, NULL, NULL, NULL, 1);
INSERT INTO loan_reinbursment VALUES (10, 15, 193500, 2, '00099', NULL, '2011-10-10', NULL, NULL, NULL, NULL, 1);
INSERT INTO loan_reinbursment VALUES (11, 16, 38000, 2, '73837', 'reibursement test', '2011-10-12', NULL, NULL, NULL, NULL, 2);


--
-- Data for Name: loans; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO loans VALUES (7, 4, 2, 150000, 0, 0, 0, 0, '2011-09-09', 5, 27078, 12, false, NULL, 1);
INSERT INTO loans VALUES (9, 4, 4, 150000, 0, 0, 0, 0, '2011-10-07', 5, 27078, 12, false, NULL, 1);
INSERT INTO loans VALUES (10, 4, 4, 100000, 0, 0, 0, 0, '2011-10-07', 5, 8750, 12, false, NULL, 1);
INSERT INTO loans VALUES (11, 4, 4, 150000, 0, 0, 0, 0, '2011-10-07', 5, 13125, 12, false, NULL, 1);
INSERT INTO loans VALUES (12, 4, 4, 150000, 0, 0, 0, 0, '2011-10-07', 5, 13125, 12, false, NULL, 1);
INSERT INTO loans VALUES (6, 3, 2, 500000, 0, 0, 0, 0, '2011-09-30', 15, 116667, 12, true, NULL, 1);
INSERT INTO loans VALUES (14, 4, 4, 150000, 0, 0, 0, 0, '2011-10-03', 5, 20000, 12, false, NULL, 1);
INSERT INTO loans VALUES (13, 4, 4, 150000, 0, 0, 0, 0, '2011-10-07', 5, 20000, 12, true, NULL, 1);
INSERT INTO loans VALUES (15, 4, 5, 500000, 0, 0, 0, 0, '2011-10-10', 5, 66667, 12, false, NULL, 4);
INSERT INTO loans VALUES (16, 4, 6, 40000, 0, 0, 0, 0, '2011-03-25', 5, 21333, 3, true, NULL, 2);


--
-- Data for Name: loantypes; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO loantypes VALUES (1, 'Emergency Loan', NULL, false, NULL);
INSERT INTO loantypes VALUES (2, 'Education Loan', NULL, false, NULL);
INSERT INTO loantypes VALUES (3, 'Development Loan', NULL, false, NULL);
INSERT INTO loantypes VALUES (4, 'Auto Log Book Loan', NULL, false, 5);


--
-- Data for Name: orgs; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO orgs VALUES (1, 'Meridian', true, true, NULL, 'Meridian');
INSERT INTO orgs VALUES (0, 'default', false, true, NULL, NULL);


--
-- Data for Name: partner; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO partner VALUES (1, 2, 'Car Dealer', 1990, 'This is the main partner', NULL, NULL, NULL);


--
-- Data for Name: payment_mode; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO payment_mode VALUES (1, 'CASH', 0, NULL);
INSERT INTO payment_mode VALUES (2, 'CHEQUE', 0, NULL);
INSERT INTO payment_mode VALUES (3, 'M-PESA', 0, NULL);
INSERT INTO payment_mode VALUES (4, 'ZAP', 0, NULL);


--
-- Data for Name: periods; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO periods VALUES (60, '2011-09-01', '2011-09-25', 0, false, false, NULL, '2011', false, false);
INSERT INTO periods VALUES (61, '2011-10-01', '2011-10-31', 0, false, false, NULL, '2011', false, false);
INSERT INTO periods VALUES (62, '2011-11-01', '2011-11-30', 0, false, false, NULL, '2011', false, false);
INSERT INTO periods VALUES (63, '2011-12-01', '2011-12-31', 0, false, false, NULL, '2011', false, false);
INSERT INTO periods VALUES (64, '2012-01-01', '2012-01-31', 0, false, false, NULL, '2011', false, false);


--
-- Data for Name: phase; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Data for Name: rec_investor; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO rec_investor VALUES ('Mike Shakur Beya');


--
-- Data for Name: referee; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO referee VALUES (1, 'test ref', NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL);


--
-- Data for Name: repayment_table; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO repayment_table VALUES (9, 6, 9, 589696, 9217, 'DGJH', NULL, 258273, NULL, 0, true, NULL, 249056, 258273, 'KIPANDE', 'KCB', false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (8, 6, 8, 737364, 10822, 'SFG', NULL, 258273, NULL, 0, true, NULL, 247451, 258273, 'KIPANDE', 'KCB', false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (7, 6, 7, 865771, 12218, 'SFHG', NULL, 258273, NULL, 0, true, NULL, 246055, 258273, 'KIPANDE', 'KCB', false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (6, 6, 6, 977430, 13432, 'DGJH', NULL, 258273, NULL, 0, true, NULL, 244841, 258273, 'KIPANDE', 'KCB', false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (5, 6, 5, 1074524, 14487, 'GHFJH', NULL, 258273, NULL, 0, true, NULL, 243786, 258273, 'KIPANDE', 'KCB', false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (2, 6, 2, 1296213, 16897, 'SDFG', NULL, 258273, NULL, 0, true, NULL, 241376, 258273, 'KIPANDE', 'KCB', true, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (3, 6, 3, 1232372, 16203, 'SADF', NULL, 258273, NULL, 0, true, NULL, 242070, 258273, 'KIPANDE', 'KCB', true, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (4, 6, 4, 1158954, 15405, 'ADFG', NULL, 258273, NULL, 0, true, NULL, 242868, 258273, 'KIPANDE', 'KCB', true, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (12, 6, 12, -0, 2807, 'SAHDGH', NULL, 258273, NULL, 0, false, NULL, 255466, 258273, 'KIPANDE', 'KCB', false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (11, 6, 11, 224585, 5248, 'SHGH', NULL, 258273, NULL, 0, false, NULL, 253025, 258273, 'KIPANDE', 'KCB', false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (10, 6, 10, 419877, 7371, 'AHGFG', NULL, 258273, NULL, 0, false, NULL, 250902, 258273, 'KIPANDE', 'KCB', false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (93, 15, 9, 199997, 25000, '', NULL, NULL, NULL, 0, false, NULL, 41666.668, 66667, '', '', false, NULL, NULL, false, false, '');
INSERT INTO repayment_table VALUES (1, 6, 1, 1351727, 17500, 'SFDDA', NULL, 258273, NULL, 0, true, NULL, 240773, 258273, 'KIPANDE', 'KCB', false, NULL, 3, true, false, NULL);
INSERT INTO repayment_table VALUES (13, 7, 1, 224922, 1000, NULL, NULL, NULL, NULL, 0, false, NULL, 26078, 27078, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (14, 7, 2, 209090, 937, NULL, NULL, NULL, NULL, 0, false, NULL, 26141, 27078, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (15, 7, 3, 192466, 871, NULL, NULL, NULL, NULL, 0, false, NULL, 26207, 27078, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (16, 7, 4, 175012, 802, NULL, NULL, NULL, NULL, 0, false, NULL, 26276, 27078, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (17, 7, 5, 156684, 729, NULL, NULL, NULL, NULL, 0, false, NULL, 26349, 27078, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (18, 7, 6, 137440, 653, NULL, NULL, NULL, NULL, 0, false, NULL, 26425, 27078, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (19, 7, 7, 117234, 573, NULL, NULL, NULL, NULL, 0, false, NULL, 26505, 27078, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (20, 7, 8, 96018, 488, NULL, NULL, NULL, NULL, 0, false, NULL, 26590, 27078, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (21, 7, 9, 73740, 400, NULL, NULL, NULL, NULL, 0, false, NULL, 26678, 27078, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (22, 7, 10, 50349, 307, NULL, NULL, NULL, NULL, 0, false, NULL, 26771, 27078, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (23, 7, 11, 25789, 210, NULL, NULL, NULL, NULL, 0, false, NULL, 26868, 27078, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (24, 7, 12, -0, 107, NULL, NULL, NULL, NULL, 0, false, NULL, 26971, 27078, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (25, 10, 1, 146667, 5000, NULL, NULL, NULL, NULL, 0, false, NULL, 8333.33301, 13333, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (26, 10, 2, 133334, 5000, NULL, NULL, NULL, NULL, 0, false, NULL, 8333.33301, 13333, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (27, 10, 3, 120001, 5000, NULL, NULL, NULL, NULL, 0, false, NULL, 8333.33301, 13333, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (28, 10, 4, 106668, 5000, NULL, NULL, NULL, NULL, 0, false, NULL, 8333.33301, 13333, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (29, 10, 5, 93335, 5000, NULL, NULL, NULL, NULL, 0, false, NULL, 8333.33301, 13333, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (30, 10, 6, 80002, 5000, NULL, NULL, NULL, NULL, 0, false, NULL, 8333.33301, 13333, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (31, 10, 7, 66669, 5000, NULL, NULL, NULL, NULL, 0, false, NULL, 8333.33301, 13333, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (32, 10, 8, 53336, 5000, NULL, NULL, NULL, NULL, 0, false, NULL, 8333.33301, 13333, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (33, 10, 9, 40003, 5000, NULL, NULL, NULL, NULL, 0, false, NULL, 8333.33301, 13333, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (34, 10, 10, 26670, 5000, NULL, NULL, NULL, NULL, 0, false, NULL, 8333.33301, 13333, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (35, 10, 11, 13337, 5000, NULL, NULL, NULL, NULL, 0, false, NULL, 8333.33301, 13333, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (36, 10, 12, 4, 5000, NULL, NULL, NULL, NULL, 0, false, NULL, 8333.33301, 13333, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (39, 11, 3, 180000, 7500, NULL, NULL, NULL, NULL, 0, false, NULL, 12500, 20000, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (40, 11, 4, 160000, 7500, NULL, NULL, NULL, NULL, 0, false, NULL, 12500, 20000, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (41, 11, 5, 140000, 7500, NULL, NULL, NULL, NULL, 0, false, NULL, 12500, 20000, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (42, 11, 6, 120000, 7500, NULL, NULL, NULL, NULL, 0, false, NULL, 12500, 20000, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (43, 11, 7, 100000, 7500, NULL, NULL, NULL, NULL, 0, false, NULL, 12500, 20000, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (44, 11, 8, 80000, 7500, NULL, NULL, NULL, NULL, 0, false, NULL, 12500, 20000, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (45, 11, 9, 60000, 7500, NULL, NULL, NULL, NULL, 0, false, NULL, 12500, 20000, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (46, 11, 10, 40000, 7500, NULL, NULL, NULL, NULL, 0, false, NULL, 12500, 20000, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (47, 11, 11, 20000, 7500, NULL, NULL, NULL, NULL, 0, false, NULL, 12500, 20000, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (48, 11, 12, 0, 7500, NULL, NULL, NULL, NULL, 0, false, NULL, 12500, 20000, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (49, 12, 1, 220000, 7500, NULL, NULL, NULL, NULL, 0, false, NULL, 12500, 20000, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (50, 12, 2, 200000, 7500, NULL, NULL, NULL, NULL, 0, false, NULL, 12500, 20000, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (51, 12, 3, 180000, 7500, NULL, NULL, NULL, NULL, 0, false, NULL, 12500, 20000, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (52, 12, 4, 160000, 7500, NULL, NULL, NULL, NULL, 0, false, NULL, 12500, 20000, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (53, 12, 5, 140000, 7500, NULL, NULL, NULL, NULL, 0, false, NULL, 12500, 20000, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (54, 12, 6, 120000, 7500, NULL, NULL, NULL, NULL, 0, false, NULL, 12500, 20000, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (55, 12, 7, 100000, 7500, NULL, NULL, NULL, NULL, 0, false, NULL, 12500, 20000, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (56, 12, 8, 80000, 7500, NULL, NULL, NULL, NULL, 0, false, NULL, 12500, 20000, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (57, 12, 9, 60000, 7500, NULL, NULL, NULL, NULL, 0, false, NULL, 12500, 20000, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (58, 12, 10, 40000, 7500, NULL, NULL, NULL, NULL, 0, false, NULL, 12500, 20000, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (59, 12, 11, 20000, 7500, NULL, NULL, NULL, NULL, 0, false, NULL, 12500, 20000, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (60, 12, 12, 0, 7500, NULL, NULL, NULL, NULL, 0, false, NULL, 12500, 20000, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (92, 15, 8, 266664, 25000, '', NULL, NULL, NULL, 0, false, NULL, 41666.668, 66667, '', '', false, NULL, NULL, false, false, '');
INSERT INTO repayment_table VALUES (87, 15, 3, 599999, 25000, '', NULL, NULL, NULL, 0, false, NULL, 41666.668, 66667, '', '', false, NULL, NULL, false, false, '');
INSERT INTO repayment_table VALUES (69, 13, 9, 60000, 7500, '', NULL, NULL, NULL, 0, false, NULL, 12500, 20000, '', '', false, NULL, NULL, false, false, '');
INSERT INTO repayment_table VALUES (68, 13, 8, 80000, 7500, '', NULL, NULL, NULL, 0, false, NULL, 12500, 20000, '', '', false, NULL, NULL, false, false, '');
INSERT INTO repayment_table VALUES (67, 13, 7, 100000, 7500, '', NULL, NULL, NULL, 0, false, NULL, 12500, 20000, '', '', false, NULL, NULL, false, false, '');
INSERT INTO repayment_table VALUES (66, 13, 6, 120000, 7500, '', NULL, NULL, NULL, 0, false, NULL, 12500, 20000, '', '', false, NULL, NULL, false, false, '');
INSERT INTO repayment_table VALUES (65, 13, 5, 140000, 7500, '', NULL, NULL, NULL, 0, false, NULL, 12500, 20000, '', '', false, NULL, NULL, false, false, '');
INSERT INTO repayment_table VALUES (64, 13, 4, 160000, 7500, '', NULL, NULL, NULL, 0, false, NULL, 12500, 20000, '', '', false, NULL, NULL, false, false, '');
INSERT INTO repayment_table VALUES (63, 13, 3, 180000, 7500, '', NULL, NULL, NULL, 0, false, NULL, 12500, 20000, '', '', false, NULL, NULL, false, false, '');
INSERT INTO repayment_table VALUES (38, 11, 2, 200000, 7500, NULL, NULL, 20000, NULL, 0, false, NULL, 12500, 20000, NULL, NULL, true, NULL, 2, false, false, NULL);
INSERT INTO repayment_table VALUES (37, 11, 1, 220000, 7500, NULL, NULL, 20000, NULL, 0, false, 'TEST', 12500, 20000, NULL, NULL, false, NULL, 3, true, false, NULL);
INSERT INTO repayment_table VALUES (74, 14, 2, 200000, 7500, NULL, NULL, NULL, NULL, 0, false, NULL, 12500, 20000, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (62, 13, 2, 200000, 7500, '', '2011-12-24', 20000, NULL, 0, false, NULL, 12500, 20000, '', '', false, NULL, NULL, false, false, 'Dewcis Solutions');
INSERT INTO repayment_table VALUES (61, 13, 1, 220000, 7500, 'adfa', '2011-07-12', 20000, NULL, 0, false, NULL, 12500, 20000, 'TEST', 'KCB', false, NULL, NULL, false, false, 'Dewcis Solutions');
INSERT INTO repayment_table VALUES (72, 13, 12, 0, 7500, '', NULL, NULL, NULL, 0, false, NULL, 12500, 20000, '', '', false, NULL, NULL, false, false, '');
INSERT INTO repayment_table VALUES (71, 13, 11, 20000, 7500, '', NULL, NULL, NULL, 0, false, NULL, 12500, 20000, '', '', false, NULL, NULL, false, false, '');
INSERT INTO repayment_table VALUES (75, 14, 3, 180000, 7500, NULL, NULL, NULL, NULL, 0, false, NULL, 12500, 20000, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (76, 14, 4, 160000, 7500, NULL, NULL, NULL, NULL, 0, false, NULL, 12500, 20000, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (77, 14, 5, 140000, 7500, NULL, NULL, NULL, NULL, 0, false, NULL, 12500, 20000, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (78, 14, 6, 120000, 7500, NULL, NULL, NULL, NULL, 0, false, NULL, 12500, 20000, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (79, 14, 7, 100000, 7500, NULL, NULL, NULL, NULL, 0, false, NULL, 12500, 20000, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (80, 14, 8, 80000, 7500, NULL, NULL, NULL, NULL, 0, false, NULL, 12500, 20000, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (81, 14, 9, 60000, 7500, NULL, NULL, NULL, NULL, 0, false, NULL, 12500, 20000, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (82, 14, 10, 40000, 7500, NULL, NULL, NULL, NULL, 0, false, NULL, 12500, 20000, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (83, 14, 11, 20000, 7500, NULL, NULL, NULL, NULL, 0, false, NULL, 12500, 20000, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (84, 14, 12, 0, 7500, NULL, NULL, NULL, NULL, 0, false, NULL, 12500, 20000, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (73, 14, 1, 220000, 7500, NULL, NULL, NULL, NULL, 0, true, NULL, 12500, 20000, NULL, NULL, false, NULL, NULL, false, false, NULL);
INSERT INTO repayment_table VALUES (86, 15, 2, 666666, 25000, '', NULL, NULL, NULL, 0, false, NULL, 41666.668, 66667, '', '', false, NULL, NULL, false, false, '');
INSERT INTO repayment_table VALUES (70, 13, 10, 40000, 7500, '', NULL, NULL, NULL, 0, true, NULL, 12500, 20000, '', '', false, NULL, NULL, false, false, '');
INSERT INTO repayment_table VALUES (85, 15, 1, 733333, 25000, '10010', '2011-11-10', 26667, NULL, 0, true, NULL, 41666.668, 66667, 'koinange', 'kcb', false, NULL, NULL, false, false, 'erick n n');
INSERT INTO repayment_table VALUES (91, 15, 7, 333331, 25000, '', NULL, NULL, NULL, 0, false, NULL, 41666.668, 66667, '', '', false, NULL, NULL, false, false, '');
INSERT INTO repayment_table VALUES (94, 15, 10, 133330, 25000, '', NULL, NULL, NULL, 0, false, NULL, 41666.668, 66667, '', '', false, NULL, NULL, false, false, '');
INSERT INTO repayment_table VALUES (90, 15, 6, 399998, 25000, '', NULL, NULL, NULL, 0, false, NULL, 41666.668, 66667, '', '', false, NULL, NULL, false, false, '');
INSERT INTO repayment_table VALUES (89, 15, 5, 466665, 25000, '', NULL, NULL, NULL, 0, false, NULL, 41666.668, 66667, '', '', false, NULL, NULL, false, false, '');
INSERT INTO repayment_table VALUES (96, 15, 12, -4, 25000, '', NULL, NULL, NULL, 0, false, NULL, 41666.668, 66667, '', '', false, NULL, NULL, false, false, '');
INSERT INTO repayment_table VALUES (88, 15, 4, 533332, 25000, '', NULL, NULL, NULL, 0, false, NULL, 41666.668, 66667, '', '', false, NULL, NULL, false, false, '');
INSERT INTO repayment_table VALUES (95, 15, 11, 66663, 25000, '', NULL, NULL, NULL, 0, false, NULL, 41666.668, 66667, '', '', false, NULL, NULL, false, false, '');
INSERT INTO repayment_table VALUES (98, 16, 2, 21334, 8000, '236', '2011-07-23', 15334, NULL, 0, true, NULL, 13333.333, 21333, 'CBD', 'COOP', true, NULL, 2, false, false, 'NICOLAS');
INSERT INTO repayment_table VALUES (99, 16, 3, 1, 8000, '235', '2011-08-23', 15334, NULL, 0, true, NULL, 13333.333, 21333, 'CBD', 'COOP', false, 'dsfa', 3, true, false, 'NICOLAS');
INSERT INTO repayment_table VALUES (97, 16, 1, 42667, 8000, '237', '2011-06-23', 15334, NULL, 0, true, NULL, 13333.333, 21333, 'CBD', 'COOP', true, 'jkljjjkjlkjh', 2, false, false, 'NICOLAS');


--
-- Data for Name: services; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO services VALUES (1, 'Loan Repayment', '2012-07-27', NULL);


--
-- Data for Name: sub_fields; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Data for Name: subscription_levels; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO subscription_levels VALUES (0, 'Basic', NULL);
INSERT INTO subscription_levels VALUES (1, 'Manager', NULL);
INSERT INTO subscription_levels VALUES (2, 'Consumer', NULL);


--
-- Data for Name: sys_audit_details; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Data for Name: sys_audit_trail; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO sys_audit_trail VALUES (1, '0', 'sesame/127.0.0.1', '2011-09-05 10:12:51.304736', 'orgs', '1', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (2, '0', 'sesame/127.0.0.1', '2011-09-05 10:15:43.62631', 'entity_types', '4', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (3, '0', 'sesame/127.0.0.1', '2011-09-05 10:15:53.38077', 'entity_types', '4', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (4, '0', 'sesame/127.0.0.1', '2011-09-05 10:16:33.800663', 'entity_types', '5', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (5, '0', 'sesame/127.0.0.1', '2011-09-05 10:21:03.190697', 'orgs', '1', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (6, '0', 'sesame/127.0.0.1', '2011-09-05 10:22:11.480452', 'entitys', '1', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (7, '0', 'sesame/127.0.0.1', '2011-09-05 16:31:50.451133', 'entitys', '2', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (8, '0', 'sesame/127.0.0.1', '2011-09-05 16:32:34.286874', 'partner', '1', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (9, '0', 'sesame/127.0.0.1', '2011-09-05 16:35:53.178309', 'borrower', '1', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (10, '0', 'sesame/127.0.0.1', '2011-09-08 08:45:01.741573', 'entitys', '1', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (11, '0', 'sesame/127.0.0.1', '2011-09-08 08:45:29.291245', 'vw_entity_subscriptions', '1', 'DELETE', NULL);
INSERT INTO sys_audit_trail VALUES (12, '0', 'sesame/127.0.0.1', '2011-09-08 08:46:19.060555', 'entity_types', '1', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (13, '0', 'sesame/127.0.0.1', '2011-09-08 08:46:24.969658', 'entity_types', '3', 'DELETE', NULL);
INSERT INTO sys_audit_trail VALUES (14, '0', 'sesame/127.0.0.1', '2011-09-08 08:46:35.349461', 'entity_types', '5', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (15, '0', 'sesame/127.0.0.1', '2011-09-08 08:47:01.080418', 'entity_types', '2', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (16, '0', 'sesame/127.0.0.1', '2011-09-08 08:47:50.335401', 'entity_types', '7', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (17, '0', 'sesame/127.0.0.1', '2011-09-08 08:48:03.088688', 'entitys', '0', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (18, '0', 'sesame/127.0.0.1', '2011-09-08 08:53:14.899741', 'entity_subscriptions', '3', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (19, '0', 'sesame/127.0.0.1', '2011-09-08 08:53:30.357743', 'entity_subscriptions', '4', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (20, '0', 'sesame/127.0.0.1', '2011-09-08 08:56:10.313125', 'entity_subscriptions', '2', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (21, '0', 'sesame/127.0.0.1', '2011-09-08 08:56:47.905026', 'entitys', '2', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (22, '0', 'sesame/127.0.0.1', '2011-09-08 08:57:32.33876', 'entity_subscriptions', '2', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (23, '0', 'sesame/127.0.0.1', '2011-09-08 09:26:12.66877', 'vw_entity_subscriptions', '3', 'DELETE', NULL);
INSERT INTO sys_audit_trail VALUES (24, '0', '0:0:0:0:0:0:0:1', '2011-09-22 12:51:18.634518', 'bank_branch', '1', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (25, '0', '0:0:0:0:0:0:0:1', '2011-09-22 13:06:13.884686', 'fees', '1', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (26, '0', '0:0:0:0:0:0:0:1', '2011-09-22 16:36:32.196612', 'investment_type', '1', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (27, '0', '0:0:0:0:0:0:0:1', '2011-09-22 16:41:59.722994', 'investment', '5', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (28, '0', '0:0:0:0:0:0:0:1', '2011-09-23 10:42:01.113901', 'investor', '1', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (29, '0', '0:0:0:0:0:0:0:1', '2011-09-23 10:47:24.096859', 'fees', '2', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (30, '0', '0:0:0:0:0:0:0:1', '2011-09-23 10:52:21.311888', 'deduction', '1', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (31, '0', '0:0:0:0:0:0:0:1', '2011-09-23 10:54:26.216661', 'deduction', '2', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (32, '0', '0:0:0:0:0:0:0:1', '2011-09-23 11:00:44.19006', 'deduction', '2', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (33, '0', '0:0:0:0:0:0:0:1', '2011-09-23 11:06:17.646018', 'deduction', '2', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (34, '0', '0:0:0:0:0:0:0:1', '2011-09-23 11:07:08.278484', 'investment', '3', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (35, '0', '0:0:0:0:0:0:0:1', '2011-09-23 11:08:11.911774', 'periods', '1', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (36, '0', '0:0:0:0:0:0:0:1', '2011-09-23 11:14:45.388581', 'periods', '2', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (37, '0', '0:0:0:0:0:0:0:1', '2011-09-23 11:18:29.653362', 'periods', '3', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (38, '0', '0:0:0:0:0:0:0:1', '2011-09-23 11:21:43.045708', 'periods', '4', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (39, '0', '0:0:0:0:0:0:0:1', '2011-09-23 11:37:23.157017', 'periods', '5', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (40, '0', '0:0:0:0:0:0:0:1', '2011-09-23 12:27:32.951911', 'periods', '6', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (41, '0', '0:0:0:0:0:0:0:1', '2011-09-23 12:37:12.223941', 'periods', '7', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (42, '0', '0:0:0:0:0:0:0:1', '2011-09-23 12:47:51.494599', 'periods', '8', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (43, '0', '0:0:0:0:0:0:0:1', '2011-09-23 12:49:26.955933', 'deduction', '3', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (44, '0', '0:0:0:0:0:0:0:1', '2011-09-23 12:50:32.889827', 'periods', '9', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (45, '0', '0:0:0:0:0:0:0:1', '2011-09-23 15:55:04.950501', 'commission_payment', '1', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (46, '0', '0:0:0:0:0:0:0:1', '2011-09-23 15:56:09.364217', 'commission_payment', '2', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (47, '0', '0:0:0:0:0:0:0:1', '2011-09-23 16:20:51.727624', 'loans', '6', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (48, '0', '0:0:0:0:0:0:0:1', '2011-09-23 16:31:41.578034', 'repayment_table', '1', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (49, '0', '0:0:0:0:0:0:0:1', '2011-09-23 16:32:38.221079', 'repayment_table', '2', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (50, '0', '0:0:0:0:0:0:0:1', '2011-09-23 16:32:45.850157', 'repayment_table', '3', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (51, '0', '0:0:0:0:0:0:0:1', '2011-09-23 16:32:48.5256', 'repayment_table', '3', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (52, '0', '0:0:0:0:0:0:0:1', '2011-09-26 09:44:39.517996', 'loan_reinbursment', '2', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (53, '0', '0:0:0:0:0:0:0:1', '2011-09-26 09:44:50.274278', 'loan_reinbursment', '2', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (54, '0', '0:0:0:0:0:0:0:1', '2011-09-26 09:45:05.311378', 'loan_reinbursment', '2', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (55, '0', '0:0:0:0:0:0:0:1', '2011-09-26 09:45:25.986483', 'repayment_table', '4', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (56, '0', '0:0:0:0:0:0:0:1', '2011-09-26 11:24:25.48861', 'periods', '60', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (57, '0', '0:0:0:0:0:0:0:1', '2011-09-26 11:25:07.07044', 'journals', '1', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (58, '0', '0:0:0:0:0:0:0:1', '2011-09-27 12:25:05.771042', 'entitys', '8', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (59, '0', '0:0:0:0:0:0:0:1', '2011-09-27 12:25:23.517483', 'entitys', '9', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (60, '0', '0:0:0:0:0:0:0:1', '2011-09-28 09:04:47.814377', 'journals', '2', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (61, '0', '0:0:0:0:0:0:0:1', '2011-09-28 12:46:18.669674', 'repayment_table', '1', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (62, '0', '0:0:0:0:0:0:0:1', '2011-09-30 09:54:37.45122', 'investment_type', '1', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (63, '0', '0:0:0:0:0:0:0:1', '2011-09-30 12:03:30.455837', 'accounts', '32000', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (64, '0', '0:0:0:0:0:0:0:1', '2011-09-30 12:04:41.553281', 'accounts', '40040', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (65, '0', '0:0:0:0:0:0:0:1', '2011-09-30 12:19:35.947115', 'investment', '14', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (66, '0', '0:0:0:0:0:0:0:1', '2011-09-30 12:28:48.604668', 'investor', '2', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (67, '0', '0:0:0:0:0:0:0:1', '2011-09-30 12:29:02.751941', 'investment', '15', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (68, '0', '0:0:0:0:0:0:0:1', '2011-09-30 12:32:00.850494', 'deduction', '6', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (69, '0', '0:0:0:0:0:0:0:1', '2011-09-30 12:44:08.147393', 'accounts', '98040', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (70, '0', '0:0:0:0:0:0:0:1', '2011-09-30 12:45:28.71193', 'accounts', '98040', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (71, '0', '0:0:0:0:0:0:0:1', '2011-09-30 12:45:40.758268', 'commission_payment', '5', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (72, '0', '0:0:0:0:0:0:0:1', '2011-09-30 14:59:17.31897', 'accounts', '30020', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (73, '0', '0:0:0:0:0:0:0:1', '2011-09-30 14:59:20.588155', 'accounts', '30020', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (74, '0', '0:0:0:0:0:0:0:1', '2011-09-30 14:59:29.252277', 'accounts', '30020', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (75, '0', '0:0:0:0:0:0:0:1', '2011-09-30 15:00:09.975268', 'accounts', '70005', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (76, '0', '0:0:0:0:0:0:0:1', '2011-09-30 15:07:29.648683', 'loan_reinbursment', '9', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (77, '0', '0:0:0:0:0:0:0:1', '2011-09-30 15:22:45.63597', 'repayment_table', '1', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (78, '0', '0:0:0:0:0:0:0:1', '2011-09-30 15:23:08.039133', 'repayment_table', '1', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (79, '0', '0:0:0:0:0:0:0:1', '2011-09-30 15:53:20.065406', 'loantypes', '4', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (80, '0', '0:0:0:0:0:0:0:1', '2011-09-30 15:53:52.872048', 'loans', '7', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (81, '0', '0:0:0:0:0:0:0:1', '2011-09-30 16:23:25.698225', 'deduction', '7', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (82, '0', '0:0:0:0:0:0:0:1', '2011-09-30 16:24:28.572258', 'deduction', '8', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (83, '0', '0:0:0:0:0:0:0:1', '2011-09-30 16:26:57.121295', 'investor', '3', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (84, '0', '0:0:0:0:0:0:0:1', '2011-09-30 16:27:21.79243', 'investor', '3', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (85, '0', '0:0:0:0:0:0:0:1', '2011-09-30 16:27:28.265723', 'investor', '3', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (86, '0', '0:0:0:0:0:0:0:1', '2011-09-30 16:28:29.390496', 'investment', '16', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (87, '0', '0:0:0:0:0:0:0:1', '2011-09-30 16:29:32.543566', 'deduction', '9', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (88, '0', '0:0:0:0:0:0:0:1', '2011-09-30 16:34:45.753997', 'deduction', '10', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (89, '0', '0:0:0:0:0:0:0:1', '2011-09-30 16:36:36.176691', 'periods', '61', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (90, '0', '0:0:0:0:0:0:0:1', '2011-09-30 16:38:37.145674', 'investment', '16', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (91, '0', '0:0:0:0:0:0:0:1', '2011-09-30 16:48:31.425706', 'investment', '17', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (92, '0', '0:0:0:0:0:0:0:1', '2011-09-30 16:48:49.458772', 'periods', '62', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (93, '0', '0:0:0:0:0:0:0:1', '2011-10-03 10:56:22.480267', 'borrower', '4', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (94, '0', '0:0:0:0:0:0:0:1', '2011-10-03 11:01:44.902705', 'loans', '9', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (95, '0', '0:0:0:0:0:0:0:1', '2011-10-03 11:40:04.99383', 'loans', '10', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (96, '0', '0:0:0:0:0:0:0:1', '2011-10-03 11:41:44.769622', 'loans', '11', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (97, '0', '0:0:0:0:0:0:0:1', '2011-10-03 11:46:15.899255', 'loans', '12', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (98, '0', '0:0:0:0:0:0:0:1', '2011-10-03 11:54:19.756077', 'loans', '13', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (99, '0', '0:0:0:0:0:0:0:1', '2011-10-03 12:46:19.207202', 'accounts', '71030', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (100, '0', '0:0:0:0:0:0:0:1', '2011-10-03 12:46:41.313036', 'repayment_table', '37', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (101, '0', '0:0:0:0:0:0:0:1', '2011-10-03 12:47:40.046805', 'repayment_table', '38', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (102, '0', '0:0:0:0:0:0:0:1', '2011-10-03 15:38:48.362003', 'accounts', '30015', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (103, '0', '0:0:0:0:0:0:0:1', '2011-10-03 15:40:31.64068', 'fees', '4', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (104, '0', '0:0:0:0:0:0:0:1', '2011-10-03 15:56:29.494841', 'fees', '5', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (105, '0', '0:0:0:0:0:0:0:1', '2011-10-03 15:56:59.076042', 'fees', '4', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (106, '0', '0:0:0:0:0:0:0:1', '2011-10-03 16:09:12.561152', 'fees', '4', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (107, '0', '0:0:0:0:0:0:0:1', '2011-10-03 16:10:09.830731', 'fees', '6', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (108, '0', '0:0:0:0:0:0:0:1', '2011-10-03 16:11:58.635561', 'repayment_table', '37', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (109, '0', '0:0:0:0:0:0:0:1', '2011-10-03 16:25:30.123926', 'fees', '3', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (110, '0', '0:0:0:0:0:0:0:1', '2011-10-03 16:25:53.716672', 'fees', '2', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (111, '0', '0:0:0:0:0:0:0:1', '2011-10-03 16:40:51.85388', 'loans', '14', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (112, '0', '0:0:0:0:0:0:0:1', '2011-10-10 12:00:12.911472', 'investment_type', '3', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (113, '0', '0:0:0:0:0:0:0:1', '2011-10-10 12:21:50.885654', 'bank', '5', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (114, '0', '0:0:0:0:0:0:0:1', '2011-10-10 12:22:56.390302', 'bank_branch', '2', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (115, '0', '0:0:0:0:0:0:0:1', '2011-10-10 12:37:59.814416', 'tax', '1', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (116, '0', '0:0:0:0:0:0:0:1', '2011-10-10 12:43:38.868032', 'investor', '4', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (117, '0', '0:0:0:0:0:0:0:1', '2011-10-10 12:44:11.576848', 'investment', '18', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (118, '0', '0:0:0:0:0:0:0:1', '2011-10-10 12:48:44.101789', 'investment', '18', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (119, '0', '0:0:0:0:0:0:0:1', '2011-10-10 13:10:42.382807', 'investment', '18', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (120, '0', '0:0:0:0:0:0:0:1', '2011-10-10 13:12:49.957627', 'investment', '18', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (121, '0', '0:0:0:0:0:0:0:1', '2011-10-10 13:13:03.157802', 'periods', '63', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (122, '0', '0:0:0:0:0:0:0:1', '2011-10-10 13:18:51.436971', 'commission_payment', '6', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (123, '0', '0:0:0:0:0:0:0:1', '2011-10-10 13:31:29.063354', 'borrower', '5', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (124, '0', '0:0:0:0:0:0:0:1', '2011-10-10 13:32:26.200955', 'loans', '15', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (125, '0', '0:0:0:0:0:0:0:1', '2011-10-10 13:33:30.095902', 'loans', '15', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (126, '0', '0:0:0:0:0:0:0:1', '2011-10-10 13:44:27.801392', 'loan_reinbursment', '10', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (127, '0', '0:0:0:0:0:0:0:1', '2011-10-12 10:33:00.200663', 'loan_reinbursment', '10', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (128, '0', '0:0:0:0:0:0:0:1', '2011-10-12 10:33:57.512992', 'gls', '65', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (129, '0', '0:0:0:0:0:0:0:1', '2011-10-12 10:36:40.983896', 'gls', '25', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (130, '0', '0:0:0:0:0:0:0:1', '2011-10-12 10:37:31.659127', 'gls', '25', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (131, '0', '0:0:0:0:0:0:0:1', '2011-10-12 11:05:07.938496', 'borrower', '1', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (132, '0', '0:0:0:0:0:0:0:1', '2011-10-12 11:07:58.535346', 'borrower', '2', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (133, '0', '0:0:0:0:0:0:0:1', '2011-10-12 11:35:08.410208', 'loantypes', '4', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (134, '0', '0:0:0:0:0:0:0:1', '2011-10-12 12:00:52.697669', 'loans', '15', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (135, '0', '0:0:0:0:0:0:0:1', '2011-10-12 14:47:17.742816', 'entitys', '15', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (136, '0', '0:0:0:0:0:0:0:1', '2011-10-12 14:59:18.807043', 'investor', '5', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (137, '0', '0:0:0:0:0:0:0:1', '2011-10-12 15:00:26.521736', 'investment_type', '1', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (138, '0', '0:0:0:0:0:0:0:1', '2011-10-12 15:02:25.431193', 'investment', '19', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (139, '0', '0:0:0:0:0:0:0:1', '2011-10-12 15:03:08.684798', 'periods', '64', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (140, '0', '0:0:0:0:0:0:0:1', '2011-10-12 15:17:07.392997', 'commission_payment', '7', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (141, '0', '0:0:0:0:0:0:0:1', '2011-10-12 15:38:09.405588', 'borrower', '6', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (142, '0', '0:0:0:0:0:0:0:1', '2011-10-12 15:42:06.357145', 'loans', '16', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (143, '0', '0:0:0:0:0:0:0:1', '2011-10-12 16:38:34.427028', 'loan_reinbursment', '11', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (144, '0', '0:0:0:0:0:0:0:1', '2011-10-12 16:39:36.758746', 'repayment_table', '97', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (145, '0', '0:0:0:0:0:0:0:1', '2011-10-12 16:39:54.395148', 'repayment_table', '98', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (146, '0', '0:0:0:0:0:0:0:1', '2011-10-12 16:40:05.734173', 'repayment_table', '99', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (147, '0', '0:0:0:0:0:0:0:1', '2011-10-12 16:42:04.138474', 'repayment_table', '99', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (148, '0', '0:0:0:0:0:0:0:1', '2011-10-18 11:22:17.627531', 'accounts', '5555', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (149, '0', '0:0:0:0:0:0:0:1', '2011-10-18 11:30:44.258292', 'accounts', '6666', 'INSERT', NULL);
INSERT INTO sys_audit_trail VALUES (150, '0', '0:0:0:0:0:0:0:1', '2011-10-18 11:37:14.148679', 'accounts', '5555', 'EDIT', NULL);
INSERT INTO sys_audit_trail VALUES (151, '0', '0:0:0:0:0:0:0:1', '2011-10-18 11:37:21.678615', 'accounts', '6666', 'EDIT', NULL);


--
-- Data for Name: sys_continents; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO sys_continents VALUES ('AF', 'Africa');
INSERT INTO sys_continents VALUES ('AS', 'Asia');
INSERT INTO sys_continents VALUES ('EU', 'Europe');
INSERT INTO sys_continents VALUES ('NA', 'North America');
INSERT INTO sys_continents VALUES ('SA', 'South America');
INSERT INTO sys_continents VALUES ('OC', 'Oceania');
INSERT INTO sys_continents VALUES ('AN', 'Antarctica');


--
-- Data for Name: sys_countrys; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO sys_countrys VALUES ('AF', 'AS', 'AFG', '004', 'Afghanistan', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('AX', 'EU', 'ALA', '248', 'Aland Islands', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('AL', 'EU', 'ALB', '008', 'Albania', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('DZ', 'AF', 'DZA', '012', 'Algeria', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('AS', 'OC', 'ASM', '016', 'American Samoa', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('AD', 'EU', 'AND', '020', 'Andorra', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('AO', 'AF', 'AGO', '024', 'Angola', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('AI', 'NA', 'AIA', '660', 'Anguilla', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('AQ', 'AN', 'ATA', '010', 'Antarctica', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('AG', 'NA', 'ATG', '028', 'Antigua and Barbuda', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('AR', 'SA', 'ARG', '032', 'Argentina', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('AM', 'AS', 'ARM', '051', 'Armenia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('AW', 'NA', 'ABW', '533', 'Aruba', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('AU', 'OC', 'AUS', '036', 'Australia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('AT', 'EU', 'AUT', '040', 'Austria', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('AZ', 'AS', 'AZE', '031', 'Azerbaijan', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('BS', 'NA', 'BHS', '044', 'Bahamas', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('BH', 'AS', 'BHR', '048', 'Bahrain', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('BD', 'AS', 'BGD', '050', 'Bangladesh', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('BB', 'NA', 'BRB', '052', 'Barbados', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('BY', 'EU', 'BLR', '112', 'Belarus', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('BE', 'EU', 'BEL', '056', 'Belgium', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('BZ', 'NA', 'BLZ', '084', 'Belize', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('BJ', 'AF', 'BEN', '204', 'Benin', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('BM', 'NA', 'BMU', '060', 'Bermuda', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('BT', 'AS', 'BTN', '064', 'Bhutan', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('BO', 'SA', 'BOL', '068', 'Bolivia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('BA', 'EU', 'BIH', '070', 'Bosnia and Herzegovina', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('BW', 'AF', 'BWA', '072', 'Botswana', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('BV', 'AN', 'BVT', '074', 'Bouvet Island', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('BR', 'SA', 'BRA', '076', 'Brazil', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('IO', 'AS', 'IOT', '086', 'British Indian Ocean Territory', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('VG', 'NA', 'VGB', '092', 'British Virgin Islands', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('BN', 'AS', 'BRN', '096', 'Brunei Darussalam', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('BG', 'EU', 'BGR', '100', 'Bulgaria', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('BF', 'AF', 'BFA', '854', 'Burkina Faso', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('BI', 'AF', 'BDI', '108', 'Burundi', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('KH', 'AS', 'KHM', '116', 'Cambodia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('CM', 'AF', 'CMR', '120', 'Cameroon', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('CA', 'NA', 'CAN', '124', 'Canada', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('CV', 'AF', 'CPV', '132', 'Cape Verde', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('KY', 'NA', 'CYM', '136', 'Cayman Islands', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('CF', 'AF', 'CAF', '140', 'Central African Republic', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('TD', 'AF', 'TCD', '148', 'Chad', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('CL', 'SA', 'CHL', '152', 'Chile', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('CN', 'AS', 'CHN', '156', 'China', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('CX', 'AS', 'CXR', '162', 'Christmas Island', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('CC', 'AS', 'CCK', '166', 'Cocos Keeling Islands', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('CO', 'SA', 'COL', '170', 'Colombia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('KM', 'AF', 'COM', '174', 'Comoros', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('CD', 'AF', 'COD', '180', 'Democratic Republic of Congo', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('CG', 'AF', 'COG', '178', 'Republic of Congo', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('CK', 'OC', 'COK', '184', 'Cook Islands', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('CR', 'NA', 'CRI', '188', 'Costa Rica', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('CI', 'AF', 'CIV', '384', 'Cote d Ivoire', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('HR', 'EU', 'HRV', '191', 'Croatia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('CU', 'NA', 'CUB', '192', 'Cuba', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('CY', 'AS', 'CYP', '196', 'Cyprus', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('CZ', 'EU', 'CZE', '203', 'Czech Republic', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('DK', 'EU', 'DNK', '208', 'Denmark', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('DJ', 'AF', 'DJI', '262', 'Djibouti', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('DM', 'NA', 'DMA', '212', 'Dominica', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('DO', 'NA', 'DOM', '214', 'Dominican Republic', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('EC', 'SA', 'ECU', '218', 'Ecuador', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('EG', 'AF', 'EGY', '818', 'Egypt', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('SV', 'NA', 'SLV', '222', 'El Salvador', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('GQ', 'AF', 'GNQ', '226', 'Equatorial Guinea', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('ER', 'AF', 'ERI', '232', 'Eritrea', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('EE', 'EU', 'EST', '233', 'Estonia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('ET', 'AF', 'ETH', '231', 'Ethiopia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('FO', 'EU', 'FRO', '234', 'Faroe Islands', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('FK', 'SA', 'FLK', '238', 'Falkland Islands', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('FJ', 'OC', 'FJI', '242', 'Fiji', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('FI', 'EU', 'FIN', '246', 'Finland', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('FR', 'EU', 'FRA', '250', 'France', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('GF', 'SA', 'GUF', '254', 'French Guiana', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('PF', 'OC', 'PYF', '258', 'French Polynesia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('TF', 'AN', 'ATF', '260', 'French Southern Territories', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('GA', 'AF', 'GAB', '266', 'Gabon', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('GM', 'AF', 'GMB', '270', 'Gambia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('GE', 'AS', 'GEO', '268', 'Georgia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('DE', 'EU', 'DEU', '276', 'Germany', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('GH', 'AF', 'GHA', '288', 'Ghana', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('GI', 'EU', 'GIB', '292', 'Gibraltar', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('GR', 'EU', 'GRC', '300', 'Greece', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('GL', 'NA', 'GRL', '304', 'Greenland', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('GD', 'NA', 'GRD', '308', 'Grenada', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('GP', 'NA', 'GLP', '312', 'Guadeloupe', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('GU', 'OC', 'GUM', '316', 'Guam', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('GT', 'NA', 'GTM', '320', 'Guatemala', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('GG', 'EU', 'GGY', '831', 'Guernsey', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('GN', 'AF', 'GIN', '324', 'Guinea', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('GW', 'AF', 'GNB', '624', 'Guinea-Bissau', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('GY', 'SA', 'GUY', '328', 'Guyana', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('HT', 'NA', 'HTI', '332', 'Haiti', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('HM', 'AN', 'HMD', '334', 'Heard Island and McDonald Islands', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('VA', 'EU', 'VAT', '336', 'Vatican City State', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('HN', 'NA', 'HND', '340', 'Honduras', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('HK', 'AS', 'HKG', '344', 'Hong Kong', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('HU', 'EU', 'HUN', '348', 'Hungary', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('IS', 'EU', 'ISL', '352', 'Iceland', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('IN', 'AS', 'IND', '356', 'India', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('ID', 'AS', 'IDN', '360', 'Indonesia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('IR', 'AS', 'IRN', '364', 'Iran', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('IQ', 'AS', 'IRQ', '368', 'Iraq', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('IE', 'EU', 'IRL', '372', 'Ireland', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('IM', 'EU', 'IMN', '833', 'Isle of Man', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('IL', 'AS', 'ISR', '376', 'Israel', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('IT', 'EU', 'ITA', '380', 'Italy', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('JM', 'NA', 'JAM', '388', 'Jamaica', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('JP', 'AS', 'JPN', '392', 'Japan', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('JE', 'EU', 'JEY', '832', 'Bailiwick of Jersey', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('JO', 'AS', 'JOR', '400', 'Jordan', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('KZ', 'AS', 'KAZ', '398', 'Kazakhstan', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('KE', 'AF', 'KEN', '404', 'Kenya', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('KI', 'OC', 'KIR', '296', 'Kiribati', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('KP', 'AS', 'PRK', '408', 'North Korea', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('KR', 'AS', 'KOR', '410', 'South Korea', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('KW', 'AS', 'KWT', '414', 'Kuwait', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('KG', 'AS', 'KGZ', '417', 'Kyrgyz Republic', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('LA', 'AS', 'LAO', '418', 'Lao Peoples Democratic Republic', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('LV', 'EU', 'LVA', '428', 'Latvia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('LB', 'AS', 'LBN', '422', 'Lebanon', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('LS', 'AF', 'LSO', '426', 'Lesotho', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('LR', 'AF', 'LBR', '430', 'Liberia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('LY', 'AF', 'LBY', '434', 'Libyan Arab Jamahiriya', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('LI', 'EU', 'LIE', '438', 'Liechtenstein', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('LT', 'EU', 'LTU', '440', 'Lithuania', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('LU', 'EU', 'LUX', '442', 'Luxembourg', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('MO', 'AS', 'MAC', '446', 'Macao', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('MK', 'EU', 'MKD', '807', 'Macedonia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('MG', 'AF', 'MDG', '450', 'Madagascar', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('MW', 'AF', 'MWI', '454', 'Malawi', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('MY', 'AS', 'MYS', '458', 'Malaysia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('MV', 'AS', 'MDV', '462', 'Maldives', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('ML', 'AF', 'MLI', '466', 'Mali', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('MT', 'EU', 'MLT', '470', 'Malta', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('MH', 'OC', 'MHL', '584', 'Marshall Islands', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('MQ', 'NA', 'MTQ', '474', 'Martinique', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('MR', 'AF', 'MRT', '478', 'Mauritania', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('MU', 'AF', 'MUS', '480', 'Mauritius', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('YT', 'AF', 'MYT', '175', 'Mayotte', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('MX', 'NA', 'MEX', '484', 'Mexico', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('FM', 'OC', 'FSM', '583', 'Micronesia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('MD', 'EU', 'MDA', '498', 'Moldova', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('MC', 'EU', 'MCO', '492', 'Monaco', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('MN', 'AS', 'MNG', '496', 'Mongolia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('ME', 'EU', 'MNE', '499', 'Montenegro', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('MS', 'NA', 'MSR', '500', 'Montserrat', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('MA', 'AF', 'MAR', '504', 'Morocco', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('MZ', 'AF', 'MOZ', '508', 'Mozambique', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('MM', 'AS', 'MMR', '104', 'Myanmar', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('NA', 'AF', 'NAM', '516', 'Namibia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('NR', 'OC', 'NRU', '520', 'Nauru', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('NP', 'AS', 'NPL', '524', 'Nepal', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('AN', 'NA', 'ANT', '530', 'Netherlands Antilles', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('NL', 'EU', 'NLD', '528', 'Netherlands', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('NC', 'OC', 'NCL', '540', 'New Caledonia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('NZ', 'OC', 'NZL', '554', 'New Zealand', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('NI', 'NA', 'NIC', '558', 'Nicaragua', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('NE', 'AF', 'NER', '562', 'Niger', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('NG', 'AF', 'NGA', '566', 'Nigeria', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('NU', 'OC', 'NIU', '570', 'Niue', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('NF', 'OC', 'NFK', '574', 'Norfolk Island', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('MP', 'OC', 'MNP', '580', 'Northern Mariana Islands', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('NO', 'EU', 'NOR', '578', 'Norway', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('OM', 'AS', 'OMN', '512', 'Oman', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('PK', 'AS', 'PAK', '586', 'Pakistan', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('PW', 'OC', 'PLW', '585', 'Palau', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('PS', 'AS', 'PSE', '275', 'Palestinian Territory', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('PA', 'NA', 'PAN', '591', 'Panama', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('PG', 'OC', 'PNG', '598', 'Papua New Guinea', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('PY', 'SA', 'PRY', '600', 'Paraguay', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('PE', 'SA', 'PER', '604', 'Peru', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('PH', 'AS', 'PHL', '608', 'Philippines', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('PN', 'OC', 'PCN', '612', 'Pitcairn Islands', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('PL', 'EU', 'POL', '616', 'Poland', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('PT', 'EU', 'PRT', '620', 'Portugal', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('PR', 'NA', 'PRI', '630', 'Puerto Rico', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('QA', 'AS', 'QAT', '634', 'Qatar', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('RE', 'AF', 'REU', '638', 'Reunion', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('RO', 'EU', 'ROU', '642', 'Romania', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('RU', 'EU', 'RUS', '643', 'Russian Federation', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('RW', 'AF', 'RWA', '646', 'Rwanda', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('BL', 'NA', 'BLM', '652', 'Saint Barthelemy', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('SH', 'AF', 'SHN', '654', 'Saint Helena', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('KN', 'NA', 'KNA', '659', 'Saint Kitts and Nevis', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('LC', 'NA', 'LCA', '662', 'Saint Lucia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('MF', 'NA', 'MAF', '663', 'Saint Martin', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('PM', 'NA', 'SPM', '666', 'Saint Pierre and Miquelon', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('VC', 'NA', 'VCT', '670', 'Saint Vincent and the Grenadines', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('WS', 'OC', 'WSM', '882', 'Samoa', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('SM', 'EU', 'SMR', '674', 'San Marino', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('ST', 'AF', 'STP', '678', 'Sao Tome and Principe', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('SA', 'AS', 'SAU', '682', 'Saudi Arabia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('SN', 'AF', 'SEN', '686', 'Senegal', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('RS', 'EU', 'SRB', '688', 'Serbia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('SC', 'AF', 'SYC', '690', 'Seychelles', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('SL', 'AF', 'SLE', '694', 'Sierra Leone', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('SG', 'AS', 'SGP', '702', 'Singapore', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('SK', 'EU', 'SVK', '703', 'Slovakia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('SI', 'EU', 'SVN', '705', 'Slovenia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('SB', 'OC', 'SLB', '090', 'Solomon Islands', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('SO', 'AF', 'SOM', '706', 'Somalia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('ZA', 'AF', 'ZAF', '710', 'South Africa', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('GS', 'AN', 'SGS', '239', 'South Georgia and the South Sandwich Islands', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('ES', 'EU', 'ESP', '724', 'Spain', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('LK', 'AS', 'LKA', '144', 'Sri Lanka', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('SD', 'AF', 'SDN', '736', 'Sudan', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('SR', 'SA', 'SUR', '740', 'Suriname', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('SJ', 'EU', 'SJM', '744', 'Svalbard & Jan Mayen Islands', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('SZ', 'AF', 'SWZ', '748', 'Swaziland', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('SE', 'EU', 'SWE', '752', 'Sweden', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('CH', 'EU', 'CHE', '756', 'Switzerland', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('SY', 'AS', 'SYR', '760', 'Syrian Arab Republic', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('TW', 'AS', 'TWN', '158', 'Taiwan', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('TJ', 'AS', 'TJK', '762', 'Tajikistan', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('TZ', 'AF', 'TZA', '834', 'Tanzania', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('TH', 'AS', 'THA', '764', 'Thailand', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('TL', 'AS', 'TLS', '626', 'Timor-Leste', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('TG', 'AF', 'TGO', '768', 'Togo', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('TK', 'OC', 'TKL', '772', 'Tokelau', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('TO', 'OC', 'TON', '776', 'Tonga', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('TT', 'NA', 'TTO', '780', 'Trinidad and Tobago', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('TN', 'AF', 'TUN', '788', 'Tunisia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('TR', 'AS', 'TUR', '792', 'Turkey', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('TM', 'AS', 'TKM', '795', 'Turkmenistan', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('TC', 'NA', 'TCA', '796', 'Turks and Caicos Islands', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('TV', 'OC', 'TUV', '798', 'Tuvalu', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('UG', 'AF', 'UGA', '800', 'Uganda', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('UA', 'EU', 'UKR', '804', 'Ukraine', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('AE', 'AS', 'ARE', '784', 'United Arab Emirates', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('GB', 'EU', 'GBR', '826', 'United Kingdom of Great Britain & Northern Ireland', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('US', 'NA', 'USA', '840', 'United States of America', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('UM', 'OC', 'UMI', '581', 'United States Minor Outlying Islands', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('VI', 'NA', 'VIR', '850', 'United States Virgin Islands', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('UY', 'SA', 'URY', '858', 'Uruguay', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('UZ', 'AS', 'UZB', '860', 'Uzbekistan', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('VU', 'OC', 'VUT', '548', 'Vanuatu', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('VE', 'SA', 'VEN', '862', 'Venezuela', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('VN', 'AS', 'VNM', '704', 'Vietnam', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('WF', 'OC', 'WLF', '876', 'Wallis and Futuna', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('EH', 'AF', 'ESH', '732', 'Western Sahara', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('YE', 'AS', 'YEM', '887', 'Yemen', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('ZM', 'AF', 'ZMB', '894', 'Zambia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys VALUES ('ZW', 'AF', 'ZWE', '716', 'Zimbabwe', NULL, NULL, NULL, NULL);


--
-- Data for Name: sys_emailed; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Data for Name: sys_emails; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Data for Name: sys_errors; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Data for Name: sys_files; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Data for Name: sys_logins; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO sys_logins VALUES (1, 0, '2011-09-05 10:05:44.473764', 'sesame/127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (2, 0, '2011-09-05 10:11:58.18963', 'sesame/127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (3, 0, '2011-09-05 10:51:35.404958', 'sesame/127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (4, 0, '2011-09-05 10:52:15.757336', 'sesame/127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (5, 0, '2011-09-05 10:58:29.984799', 'sesame/127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (6, 0, '2011-09-05 14:33:25.862512', 'sesame/127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (7, 0, '2011-09-05 16:27:29.352911', 'sesame/127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (8, 1, '2011-09-06 11:16:40.535456', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (9, 1, '2011-09-06 11:16:40.534405', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (10, 1, '2011-09-06 11:17:22.631025', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (11, 1, '2011-09-06 11:17:25.166657', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (12, 1, '2011-09-06 11:19:11.930631', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (13, 1, '2011-09-06 11:19:14.09934', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (14, 1, '2011-09-06 11:19:15.377394', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (15, 1, '2011-09-06 11:19:18.362722', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (16, 1, '2011-09-06 11:19:20.665414', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (17, 1, '2011-09-06 11:19:21.58379', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (18, 1, '2011-09-06 11:19:22.529642', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (19, 1, '2011-09-06 11:19:23.860451', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (20, 1, '2011-09-06 11:19:24.706022', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (21, 1, '2011-09-06 11:19:25.484156', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (22, 1, '2011-09-06 11:19:26.652438', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (23, 1, '2011-09-06 11:19:27.521825', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (24, 1, '2011-09-06 11:19:28.990782', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (25, 1, '2011-09-06 11:19:30.312653', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (26, 1, '2011-09-06 15:36:47.011633', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (27, 1, '2011-09-06 15:36:47.012351', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (28, 1, '2011-09-06 15:36:51.051487', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (29, 1, '2011-09-06 15:36:55.616933', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (30, 1, '2011-09-06 15:36:56.790417', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (31, 1, '2011-09-06 15:36:58.136826', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (32, 1, '2011-09-06 15:41:30.528065', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (33, 1, '2011-09-06 15:41:30.55814', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (34, 1, '2011-09-06 15:48:28.689917', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (35, 1, '2011-09-06 15:49:28.616128', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (36, 1, '2011-09-06 16:05:48.021558', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (37, 1, '2011-09-07 10:06:46.962139', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (38, 1, '2011-09-07 10:06:46.945586', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (39, 1, '2011-09-07 10:07:18.967454', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (40, 1, '2011-09-07 10:07:22.893606', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (41, 1, '2011-09-07 10:08:56.699778', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (42, 1, '2011-09-07 10:08:58.491537', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (43, 1, '2011-09-07 10:09:18.168554', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (44, 1, '2011-09-07 10:09:20.146307', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (45, 1, '2011-09-07 10:10:04.465998', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (46, 1, '2011-09-07 10:10:06.182985', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (47, 1, '2011-09-07 10:10:28.005035', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (48, 1, '2011-09-07 10:10:29.904849', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (49, 1, '2011-09-07 10:10:34.745435', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (50, 1, '2011-09-07 10:10:34.785693', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (51, 1, '2011-09-07 10:10:38.416797', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (52, 1, '2011-09-07 10:10:39.963587', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (53, 1, '2011-09-07 10:11:14.546128', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (54, 1, '2011-09-07 10:11:14.559536', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (55, 1, '2011-09-07 10:11:17.382667', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (56, 1, '2011-09-07 10:11:19.076867', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (57, 1, '2011-09-07 10:12:38.464797', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (58, 1, '2011-09-07 10:12:39.829551', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (59, 1, '2011-09-07 10:14:46.182814', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (60, 1, '2011-09-07 10:14:47.679403', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (61, 1, '2011-09-07 10:14:50.115619', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (62, 1, '2011-09-07 10:14:51.368404', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (63, 1, '2011-09-07 10:15:09.224588', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (64, 1, '2011-09-07 11:11:04.496403', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (65, 1, '2011-09-07 15:29:02.993876', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (66, 1, '2011-09-07 15:29:02.99105', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (67, 1, '2011-09-07 15:29:05.639855', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (68, 1, '2011-09-07 15:29:13.614787', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (69, 1, '2011-09-07 15:29:45.479387', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (70, 1, '2011-09-07 15:29:47.113476', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (71, 1, '2011-09-07 15:29:51.44831', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (72, 1, '2011-09-07 15:29:53.116364', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (73, 1, '2011-09-07 15:30:12.557747', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (74, 1, '2011-09-07 15:30:16.684787', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (75, 1, '2011-09-07 15:30:19.960834', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (76, 1, '2011-09-07 15:30:22.923274', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (77, 1, '2011-09-07 15:30:25.832696', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (78, 1, '2011-09-07 15:31:16.567074', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (79, 1, '2011-09-07 15:31:54.728626', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (80, 1, '2011-09-07 15:32:15.498851', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (81, 1, '2011-09-07 15:32:59.321123', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (82, 1, '2011-09-07 15:32:59.348103', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (83, 1, '2011-09-07 15:33:00.940337', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (84, 1, '2011-09-07 15:33:03.146009', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (85, 1, '2011-09-07 15:34:11.978777', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (86, 1, '2011-09-07 15:34:20.221607', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (87, 1, '2011-09-07 15:34:20.242832', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (88, 1, '2011-09-07 15:34:22.687233', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (89, 1, '2011-09-07 15:34:40.67522', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (90, 1, '2011-09-07 15:34:57.47167', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (91, 1, '2011-09-07 15:36:12.858949', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (92, 1, '2011-09-07 15:36:34.68742', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (93, 1, '2011-09-07 15:36:48.818769', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (94, 1, '2011-09-07 15:37:08.518629', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (95, 1, '2011-09-08 08:41:21.025429', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (96, 1, '2011-09-08 08:41:21.025574', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (97, 1, '2011-09-08 08:41:23.451699', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (98, 0, '2011-09-08 08:42:10.446789', 'sesame/127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (99, 0, '2011-09-08 08:43:56.666405', 'sesame/127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (100, 0, '2011-09-08 08:45:45.828471', 'sesame/127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (101, 0, '2011-09-08 08:52:38.349366', 'sesame/127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (102, 0, '2011-09-08 08:53:42.516515', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (103, 0, '2011-09-08 08:53:42.525848', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (104, 0, '2011-09-08 08:53:50.808836', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (105, 0, '2011-09-08 08:53:52.557724', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (106, 0, '2011-09-08 08:53:55.02625', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (107, 0, '2011-09-08 08:54:03.820898', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (108, 0, '2011-09-08 08:54:06.527964', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (109, 0, '2011-09-08 08:55:51.631921', 'sesame/127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (110, 2, '2011-09-08 08:56:54.378963', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (111, 2, '2011-09-08 08:56:54.392667', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (112, 2, '2011-09-08 08:58:37.035399', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (113, 2, '2011-09-08 08:58:43.806562', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (114, 2, '2011-09-08 08:58:43.81775', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (115, 2, '2011-09-08 08:58:46.88944', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (116, 1, '2011-09-08 08:58:52.298908', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (117, 1, '2011-09-08 08:58:52.342039', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (118, 1, '2011-09-08 09:00:27.994079', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (119, 1, '2011-09-08 09:00:28.029244', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (120, 1, '2011-09-08 09:01:47.737728', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (121, 1, '2011-09-08 09:01:47.746723', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (122, 1, '2011-09-08 09:02:09.375538', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (123, 0, '2011-09-08 09:02:15.047676', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (124, 0, '2011-09-08 09:02:15.066205', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (125, 0, '2011-09-08 09:02:36.407566', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (126, 0, '2011-09-08 09:02:37.6791', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (127, 0, '2011-09-08 09:02:40.996644', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (128, 0, '2011-09-08 09:03:19.444093', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (129, 0, '2011-09-08 09:03:19.455848', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (130, 0, '2011-09-08 09:03:24.340441', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (131, 0, '2011-09-08 09:03:55.01468', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (132, 0, '2011-09-08 09:03:55.033902', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (133, 0, '2011-09-08 09:03:57.258043', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (134, 0, '2011-09-08 09:04:52.243433', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (135, 0, '2011-09-08 09:05:32.9861', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (136, 0, '2011-09-08 09:05:48.397533', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (137, 0, '2011-09-08 09:05:51.772922', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (138, 0, '2011-09-08 09:06:09.932756', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (139, 0, '2011-09-08 09:06:12.931925', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (140, 0, '2011-09-08 09:06:14.34933', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (141, 0, '2011-09-08 09:06:52.466564', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (142, 0, '2011-09-08 09:06:56.382116', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (143, 0, '2011-09-08 09:06:59.520249', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (144, 0, '2011-09-08 09:07:09.299428', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (145, 0, '2011-09-08 09:08:42.27653', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (146, 0, '2011-09-08 09:08:57.495473', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (147, 0, '2011-09-08 09:08:59.846283', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (148, 0, '2011-09-08 09:09:01.439587', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (149, 0, '2011-09-08 09:09:03.208406', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (150, 0, '2011-09-08 09:09:05.587728', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (151, 0, '2011-09-08 09:09:22.972625', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (152, 0, '2011-09-08 09:09:24.381001', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (153, 0, '2011-09-08 09:10:35.138407', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (154, 0, '2011-09-08 09:10:36.646978', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (155, 0, '2011-09-08 09:12:41.303324', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (156, 0, '2011-09-08 09:12:44.139573', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (157, 0, '2011-09-08 09:12:48.033529', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (158, 0, '2011-09-08 09:12:58.803296', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (159, 0, '2011-09-08 09:13:28.838741', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (160, 0, '2011-09-08 09:13:28.838899', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (161, 0, '2011-09-08 09:13:30.840759', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (162, 0, '2011-09-08 09:13:33.217665', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (163, 0, '2011-09-08 09:13:37.999822', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (164, 0, '2011-09-08 09:13:48.182248', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (165, 0, '2011-09-08 09:13:59.200507', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (166, 0, '2011-09-08 09:14:00.323993', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (167, 0, '2011-09-08 09:14:04.830488', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (168, 0, '2011-09-08 09:14:11.695707', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (169, 0, '2011-09-08 09:14:16.134786', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (170, 0, '2011-09-08 09:14:29.589192', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (171, 0, '2011-09-08 09:14:29.594045', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (172, 0, '2011-09-08 09:14:33.207949', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (173, 0, '2011-09-08 09:14:41.359034', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (174, 0, '2011-09-08 09:14:44.423973', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (175, 1, '2011-09-08 09:14:51.099802', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (176, 1, '2011-09-08 09:14:51.107877', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (177, 1, '2011-09-08 09:14:58.99301', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (178, 2, '2011-09-08 09:15:07.829185', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (179, 2, '2011-09-08 09:15:07.898129', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (180, 2, '2011-09-08 09:15:25.174209', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (181, 2, '2011-09-08 09:15:25.17998', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (182, 2, '2011-09-08 09:16:23.823089', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (183, 2, '2011-09-08 09:16:23.845325', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (184, 2, '2011-09-08 09:17:38.361806', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (185, 0, '2011-09-08 09:21:14.83644', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (186, 0, '2011-09-08 09:21:14.876397', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (187, 0, '2011-09-08 09:21:22.03743', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (188, 1, '2011-09-08 09:21:26.906529', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (189, 1, '2011-09-08 09:21:26.926423', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (190, 1, '2011-09-08 09:21:32.532588', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (191, 1, '2011-09-08 09:21:34.08894', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (192, 1, '2011-09-08 09:24:24.68134', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (193, 0, '2011-09-08 09:25:00.202223', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (194, 0, '2011-09-08 09:25:00.234181', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (195, 0, '2011-09-08 09:25:04.183052', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (196, 1, '2011-09-08 09:25:09.000198', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (197, 1, '2011-09-08 09:25:09.010519', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (198, 1, '2011-09-08 09:25:10.819224', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (199, 0, '2011-09-08 09:25:19.514737', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (200, 0, '2011-09-08 09:25:19.526198', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (201, 0, '2011-09-08 09:25:24.487636', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (202, 0, '2011-09-08 09:25:27.182847', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (203, 0, '2011-09-08 09:25:47.721132', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (204, 0, '2011-09-08 09:25:50.824978', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (205, 0, '2011-09-08 09:25:54.90408', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (206, 0, '2011-09-08 09:26:16.886978', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (207, 0, '2011-09-08 09:26:16.904833', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (208, 0, '2011-09-08 09:26:19.218929', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (209, 0, '2011-09-08 09:27:24.484954', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (210, 0, '2011-09-08 09:27:24.487535', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (211, 0, '2011-09-08 09:27:32.976292', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (212, 0, '2011-09-08 09:27:38.006071', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (213, 0, '2011-09-08 09:27:38.013392', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (214, 0, '2011-09-08 09:27:40.736808', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (215, 0, '2011-09-08 09:27:44.257996', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (216, 0, '2011-09-08 09:27:48.738674', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (217, 0, '2011-09-08 09:27:49.97065', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (218, 0, '2011-09-08 09:27:52.399168', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (219, 0, '2011-09-08 09:27:58.362048', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (220, 0, '2011-09-08 09:27:59.770469', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (221, 0, '2011-09-08 09:28:01.614205', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (222, 0, '2011-09-08 09:28:07.063652', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (223, 0, '2011-09-08 09:28:09.240207', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (224, 1, '2011-09-08 09:28:13.586948', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (225, 1, '2011-09-08 09:28:13.597126', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (226, 1, '2011-09-08 09:28:16.264953', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (227, 1, '2011-09-08 09:29:59.466883', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (228, 1, '2011-09-08 09:30:01.07962', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (229, 1, '2011-09-08 09:30:30.344478', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (230, 1, '2011-09-08 09:30:30.381316', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (231, 1, '2011-09-08 09:30:33.240954', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (232, 1, '2011-09-08 09:30:36.081215', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (233, 1, '2011-09-08 09:30:44.100466', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (234, 1, '2011-09-08 09:30:45.714324', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (235, 1, '2011-09-08 09:30:56.07927', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (236, 1, '2011-09-08 09:31:02.790282', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (237, 1, '2011-09-08 09:31:05.022595', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (238, 1, '2011-09-08 09:31:27.419513', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (239, 1, '2011-09-08 09:32:09.191998', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (240, 1, '2011-09-08 09:32:09.214935', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (241, 1, '2011-09-08 09:32:11.239371', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (242, 1, '2011-09-08 09:32:13.231784', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (243, 1, '2011-09-08 09:33:10.086485', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (244, 0, '2011-09-08 09:33:13.509604', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (245, 0, '2011-09-08 09:33:13.523737', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (246, 0, '2011-09-08 09:33:20.055835', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (247, 0, '2011-09-08 09:33:56.225265', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (248, 0, '2011-09-08 09:33:57.560656', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (249, 0, '2011-09-08 09:33:58.947403', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (250, 0, '2011-09-08 09:59:50.787858', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (251, 0, '2011-09-08 09:59:50.808699', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (252, 0, '2011-09-08 09:59:54.344547', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (253, 0, '2011-09-08 09:59:59.170747', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (254, 0, '2011-09-08 10:00:25.02161', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (255, 0, '2011-09-08 10:00:26.574295', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (256, 0, '2011-09-08 10:00:31.167207', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (257, 0, '2011-09-08 10:00:38.12153', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (258, 0, '2011-09-08 10:01:21.664042', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (259, 0, '2011-09-08 10:01:23.399212', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (260, 0, '2011-09-08 10:01:26.137325', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (261, 0, '2011-09-08 10:01:29.304755', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (262, 0, '2011-09-08 10:02:43.936918', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (263, 0, '2011-09-08 10:02:45.657436', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (264, 0, '2011-09-08 10:02:49.11621', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (265, 0, '2011-09-08 10:02:54.004892', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (266, 1, '2011-09-08 10:03:03.652286', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (267, 1, '2011-09-08 10:03:03.670481', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (268, 1, '2011-09-08 10:03:06.201341', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (269, 1, '2011-09-08 10:03:07.365063', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (270, 1, '2011-09-08 10:03:29.485803', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (271, 1, '2011-09-08 10:03:33.160821', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (272, 1, '2011-09-08 10:03:35.58188', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (273, 1, '2011-09-08 10:03:37.030796', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (274, 1, '2011-09-08 10:04:31.903892', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (275, 1, '2011-09-08 10:04:35.682091', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (276, 1, '2011-09-08 10:06:04.585969', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (277, 1, '2011-09-08 10:06:07.240723', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (278, 1, '2011-09-08 10:06:08.995995', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (279, 1, '2011-09-08 10:06:10.753784', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (280, 1, '2011-09-08 10:06:35.064279', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (281, 1, '2011-09-08 10:06:38.269819', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (282, 1, '2011-09-08 10:06:41.445433', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (283, 1, '2011-09-08 10:06:43.092481', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (284, 1, '2011-09-08 10:06:50.38406', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (285, 1, '2011-09-08 10:07:53.38545', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (286, 1, '2011-09-08 10:07:58.545463', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (287, 1, '2011-09-08 10:36:52.521159', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (288, 1, '2011-09-08 10:36:54.452524', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (289, 1, '2011-09-08 11:09:38.391383', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (290, 1, '2011-09-08 11:09:41.520529', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (291, 1, '2011-09-08 11:09:44.643857', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (292, 1, '2011-09-08 11:09:47.237109', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (293, 1, '2011-09-08 11:11:34.222268', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (294, 1, '2011-09-08 11:11:50.051611', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (295, 1, '2011-09-08 11:13:17.179329', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (296, 1, '2011-09-08 11:13:18.857713', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (297, 1, '2011-09-08 11:13:52.529735', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (298, 1, '2011-09-08 11:13:53.99446', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (299, 1, '2011-09-08 11:13:56.815059', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (300, 1, '2011-09-08 11:13:59.238377', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (301, 1, '2011-09-08 11:14:01.547693', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (302, 1, '2011-09-08 11:14:04.325269', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (303, 1, '2011-09-08 11:17:51.229449', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (304, 1, '2011-09-08 11:17:53.293655', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (305, 1, '2011-09-08 11:17:54.680991', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (306, 1, '2011-09-08 11:17:56.027704', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (307, 1, '2011-09-08 11:18:02.539726', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (308, 1, '2011-09-08 11:19:38.642383', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (309, 1, '2011-09-08 11:19:38.652687', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (310, 1, '2011-09-08 11:19:42.05604', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (311, 1, '2011-09-08 11:19:43.635643', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (312, 1, '2011-09-08 11:19:45.100943', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (313, 1, '2011-09-08 11:19:46.393826', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (314, 1, '2011-09-08 11:19:52.074717', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (315, 1, '2011-09-08 11:20:22.841115', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (316, 1, '2011-09-08 11:20:22.860397', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (317, 1, '2011-09-08 11:20:29.413389', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (318, 1, '2011-09-08 11:20:31.050224', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (319, 1, '2011-09-08 11:20:32.244971', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (320, 1, '2011-09-08 11:20:33.619074', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (321, 1, '2011-09-08 11:20:43.579563', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (322, 1, '2011-09-08 11:20:45.411745', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (323, 1, '2011-09-08 11:20:50.435914', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (324, 1, '2011-09-08 11:20:52.545887', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (325, 1, '2011-09-08 11:21:17.520382', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (326, 1, '2011-09-08 11:22:10.346494', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (327, 1, '2011-09-08 11:22:11.86373', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (328, 1, '2011-09-08 11:22:14.418956', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (329, 1, '2011-09-08 11:23:27.099554', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (330, 1, '2011-09-08 11:23:33.955448', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (331, 1, '2011-09-08 11:23:35.981995', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (332, 1, '2011-09-08 11:23:59.770984', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (333, 1, '2011-09-08 11:24:37.314776', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (334, 1, '2011-09-08 11:24:37.392151', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (335, 1, '2011-09-08 11:24:39.379478', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (336, 1, '2011-09-08 11:24:44.771768', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (337, 0, '2011-09-08 11:24:49.496569', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (338, 0, '2011-09-08 11:24:49.505932', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (339, 0, '2011-09-08 11:24:54.100167', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (340, 0, '2011-09-08 11:24:57.511895', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (341, 0, '2011-09-08 11:25:03.820104', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (342, 0, '2011-09-08 11:26:34.301156', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (343, 0, '2011-09-08 11:26:44.13978', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (344, 0, '2011-09-08 11:26:46.434569', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (345, 0, '2011-09-08 11:27:41.130271', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (346, 0, '2011-09-08 11:28:03.481884', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (347, 0, '2011-09-08 11:28:04.707404', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (348, 0, '2011-09-08 11:28:07.730037', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (349, 0, '2011-09-08 11:28:09.03495', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (350, 0, '2011-09-08 11:28:26.76284', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (351, 0, '2011-09-08 11:28:30.958199', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (352, 0, '2011-09-08 11:28:33.681121', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (353, 0, '2011-09-08 11:28:46.262078', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (354, 0, '2011-09-08 11:29:45.093338', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (355, 0, '2011-09-08 11:30:08.535729', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (356, 0, '2011-09-08 11:30:08.545743', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (357, 0, '2011-09-08 11:30:11.356707', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (358, 0, '2011-09-08 11:30:12.883582', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (359, 0, '2011-09-08 11:30:50.7511', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (360, 0, '2011-09-08 11:30:59.502057', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (361, 0, '2011-09-08 11:32:01.646643', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (362, 0, '2011-09-08 11:32:14.883284', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (363, 0, '2011-09-08 11:32:17.674914', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (364, 0, '2011-09-08 11:32:25.305424', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (365, 0, '2011-09-08 11:32:28.043482', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (366, 4, '2011-09-08 11:32:35.158866', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (367, 4, '2011-09-08 11:32:35.159243', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (368, 4, '2011-09-08 11:32:38.808798', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (369, 1, '2011-09-08 11:32:43.99454', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (370, 1, '2011-09-08 11:32:44.013348', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (371, 1, '2011-09-08 11:32:50.823605', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (372, 0, '2011-09-08 11:32:56.500668', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (373, 0, '2011-09-08 11:32:56.514665', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (374, 0, '2011-09-08 11:33:00.245939', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (375, 0, '2011-09-08 11:33:04.366046', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (376, 0, '2011-09-08 11:33:08.178168', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (377, 0, '2011-09-08 11:33:10.542941', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (378, 0, '2011-09-08 11:33:25.943092', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (379, 0, '2011-09-08 11:33:27.469569', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (380, 4, '2011-09-08 11:33:31.606415', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (381, 4, '2011-09-08 11:33:31.619882', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (382, 4, '2011-09-08 11:33:34.613155', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (383, 4, '2011-09-08 11:33:46.977813', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (384, 1, '2011-09-08 11:33:51.931213', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (385, 1, '2011-09-08 11:33:51.937451', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (386, 1, '2011-09-08 11:33:54.170728', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (387, 1, '2011-09-08 11:34:00.530213', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (388, 0, '2011-09-08 11:34:04.748183', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (389, 0, '2011-09-08 11:34:04.760909', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (390, 0, '2011-09-08 11:34:08.041533', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (391, 0, '2011-09-08 11:34:20.655358', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (392, 0, '2011-09-08 11:34:24.390944', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (393, 0, '2011-09-08 11:34:38.033221', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (394, 1, '2011-09-08 11:34:48.472692', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (395, 1, '2011-09-08 11:34:48.495677', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (396, 1, '2011-09-08 11:34:50.519679', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (397, 1, '2011-09-08 11:34:55.833114', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (398, 1, '2011-09-08 11:35:00.681889', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (399, 1, '2011-09-08 11:35:01.775069', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (400, 1, '2011-09-08 11:35:54.352978', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (401, 1, '2011-09-08 11:37:28.884496', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (402, 1, '2011-09-08 11:37:28.886464', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (403, 1, '2011-09-08 11:37:31.432844', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (404, 1, '2011-09-08 11:37:32.852184', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (405, 1, '2011-09-08 11:37:34.988931', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (406, 1, '2011-09-08 11:37:42.040339', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (407, 1, '2011-09-08 11:37:44.218247', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (408, 1, '2011-09-08 11:40:53.26667', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (409, 1, '2011-09-08 11:40:55.251848', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (410, 1, '2011-09-08 11:40:56.707476', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (411, 1, '2011-09-08 11:52:54.766145', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (412, 1, '2011-09-08 11:52:55.613798', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (413, 1, '2011-09-08 11:52:57.529609', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (414, 1, '2011-09-08 11:52:58.720229', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (415, 1, '2011-09-08 11:52:59.933186', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (416, 1, '2011-09-08 11:53:06.922032', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (417, 1, '2011-09-08 11:53:08.73949', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (418, 1, '2011-09-08 11:53:11.399299', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (419, 1, '2011-09-08 11:53:13.669266', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (420, 1, '2011-09-08 11:53:15.773412', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (421, 1, '2011-09-08 11:55:33.799134', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (422, 1, '2011-09-08 11:55:35.383446', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (423, 1, '2011-09-08 11:55:36.992906', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (424, 1, '2011-09-08 11:55:43.061861', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (425, 1, '2011-09-08 11:55:46.801075', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (426, 1, '2011-09-08 12:02:06.977896', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (427, 1, '2011-09-08 12:02:08.379069', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (428, 1, '2011-09-08 12:02:10.9852', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (429, 1, '2011-09-08 12:02:10.997877', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (430, 1, '2011-09-08 12:02:13.295991', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (431, 1, '2011-09-08 12:02:14.945922', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (432, 1, '2011-09-08 12:02:16.851656', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (433, 1, '2011-09-08 12:02:18.834993', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (434, 1, '2011-09-08 12:02:20.275254', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (435, 1, '2011-09-08 12:03:47.217461', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (436, 1, '2011-09-08 12:03:47.22714', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (437, 1, '2011-09-08 12:03:49.594936', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (438, 1, '2011-09-08 12:09:01.26697', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (439, 0, '2011-09-08 12:09:09.199252', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (440, 0, '2011-09-08 12:09:09.213667', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (441, 0, '2011-09-08 12:09:13.290047', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (442, 0, '2011-09-08 12:09:21.215138', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (443, 0, '2011-09-08 12:09:23.573343', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (444, 0, '2011-09-08 12:09:25.624059', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (445, 0, '2011-09-08 12:09:38.740538', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (446, 0, '2011-09-08 12:09:41.37325', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (447, 0, '2011-09-08 12:09:51.268291', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (448, 0, '2011-09-08 12:10:02.369653', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (449, 0, '2011-09-08 12:10:05.614954', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (450, 0, '2011-09-08 12:10:07.46347', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (451, 0, '2011-09-08 12:10:15.254104', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (452, 0, '2011-09-08 12:10:18.477729', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (453, 0, '2011-09-08 12:10:23.968341', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (454, 0, '2011-09-08 12:10:27.45337', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (455, 0, '2011-09-08 12:10:34.028089', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (456, 0, '2011-09-08 12:10:42.502164', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (457, 0, '2011-09-08 12:10:47.45391', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (458, 0, '2011-09-08 12:10:55.456799', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (459, 0, '2011-09-08 12:11:01.416434', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (460, 0, '2011-09-08 12:11:18.585291', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (461, 0, '2011-09-08 12:11:18.607091', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (462, 0, '2011-09-08 12:11:27.201383', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (463, 0, '2011-09-08 12:11:30.326103', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (464, 0, '2011-09-08 12:11:36.898006', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (465, 0, '2011-09-08 12:11:38.552106', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (466, 0, '2011-09-08 12:11:42.604117', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (467, 0, '2011-09-08 12:11:43.659384', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (468, 0, '2011-09-08 12:11:45.065745', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (469, 0, '2011-09-08 12:11:50.371457', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (470, 0, '2011-09-08 12:11:54.252425', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (471, 0, '2011-09-08 12:11:58.093918', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (472, 0, '2011-09-08 12:12:18.736026', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (473, 0, '2011-09-08 12:12:21.223395', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (474, 1, '2011-09-08 12:12:27.23505', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (475, 1, '2011-09-08 12:12:27.261358', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (476, 1, '2011-09-08 12:12:30.277747', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (477, 1, '2011-09-08 12:12:31.559805', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (478, 1, '2011-09-08 12:12:34.608967', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (479, 1, '2011-09-08 12:12:37.06871', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (480, 1, '2011-09-08 12:12:52.737318', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (481, 1, '2011-09-08 12:12:59.91641', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (482, 1, '2011-09-08 12:13:02.241563', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (483, 1, '2011-09-08 12:13:05.291194', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (484, 1, '2011-09-08 12:13:07.278839', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (485, 1, '2011-09-08 12:13:14.697431', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (486, 1, '2011-09-08 12:14:14.944109', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (487, 1, '2011-09-08 12:14:19.105608', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (488, 1, '2011-09-08 12:14:21.095096', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (489, 1, '2011-09-08 12:15:17.396491', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (490, 0, '2011-09-08 12:15:27.336515', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (491, 0, '2011-09-08 12:15:27.353532', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (492, 0, '2011-09-08 12:15:30.49458', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (493, 0, '2011-09-08 12:15:34.554568', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (494, 0, '2011-09-08 12:16:13.038596', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (495, 0, '2011-09-08 12:16:14.757593', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (496, 0, '2011-09-08 12:16:18.844627', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (497, 0, '2011-09-08 12:16:25.649356', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (498, 0, '2011-09-08 12:16:28.538776', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (499, 0, '2011-09-08 12:21:51.977847', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (500, 0, '2011-09-08 12:21:57.461955', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (501, 0, '2011-09-08 12:21:58.494401', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (502, 0, '2011-09-08 12:21:59.72418', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (503, 0, '2011-09-08 12:22:05.333088', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (504, 0, '2011-09-08 12:22:10.295069', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (505, 0, '2011-09-08 12:22:15.000809', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (506, 0, '2011-09-08 12:22:20.784796', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (507, 0, '2011-09-08 12:22:22.44308', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (508, 0, '2011-09-08 12:22:33.689776', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (509, 0, '2011-09-08 12:22:35.378935', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (510, 0, '2011-09-08 12:22:38.518308', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (511, 4, '2011-09-08 12:22:42.960934', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (512, 4, '2011-09-08 12:22:42.989744', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (513, 4, '2011-09-08 12:22:45.837297', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (514, 4, '2011-09-08 12:23:17.354218', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (515, 1, '2011-09-08 12:23:22.709703', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (516, 1, '2011-09-08 12:23:22.741197', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (517, 1, '2011-09-08 12:24:00.766095', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (518, 1, '2011-09-08 12:24:14.576959', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (519, 4, '2011-09-08 12:24:19.370709', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (520, 4, '2011-09-08 12:24:19.393625', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (521, 4, '2011-09-08 12:24:28.436601', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (522, 4, '2011-09-08 12:24:39.116242', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (523, 0, '2011-09-08 12:24:42.828934', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (524, 0, '2011-09-08 12:24:42.838333', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (525, 0, '2011-09-08 12:24:45.860768', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (526, 0, '2011-09-08 12:24:56.382317', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (527, 0, '2011-09-08 12:25:17.828062', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (528, 4, '2011-09-08 12:25:22.951628', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (529, 4, '2011-09-08 12:25:22.967189', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (530, 4, '2011-09-08 12:25:25.618402', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (531, 4, '2011-09-08 12:25:30.186487', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (532, 4, '2011-09-08 12:25:34.834898', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (533, 4, '2011-09-08 12:25:37.667821', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (534, 1, '2011-09-08 12:25:55.467515', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (535, 1, '2011-09-08 12:25:55.475009', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (536, 1, '2011-09-08 12:25:58.613373', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (537, 1, '2011-09-08 12:26:01.512154', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (538, 1, '2011-09-08 12:26:03.270453', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (539, 1, '2011-09-08 12:26:05.89969', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (540, 1, '2011-09-08 12:26:08.31481', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (541, 1, '2011-09-08 12:26:10.010582', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (542, 1, '2011-09-08 12:26:16.455403', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (543, 0, '2011-09-08 12:30:45.834152', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (544, 0, '2011-09-08 12:30:45.847835', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (545, 0, '2011-09-08 12:30:54.129955', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (547, 1, '2011-09-08 12:30:58.978122', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (546, 1, '2011-09-08 12:30:58.978174', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (548, 1, '2011-09-08 12:31:01.155379', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (549, 1, '2011-09-08 12:31:05.85706', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (550, 1, '2011-09-08 12:31:17.415823', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (551, 1, '2011-09-08 12:31:19.777603', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (552, 1, '2011-09-08 12:31:37.831304', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (553, 1, '2011-09-08 12:31:40.622622', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (554, 1, '2011-09-08 12:31:43.854309', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (555, 1, '2011-09-08 12:31:45.277764', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (556, 1, '2011-09-08 12:31:47.521744', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (557, 1, '2011-09-08 16:16:00.011471', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (558, 1, '2011-09-08 16:16:00.006276', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (559, 1, '2011-09-08 16:16:02.155556', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (560, 1, '2011-09-08 16:16:04.415433', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (561, 1, '2011-09-08 16:16:06.382583', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (562, 1, '2011-09-08 16:16:07.918756', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (563, 1, '2011-09-08 16:16:11.479683', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (564, 1, '2011-09-08 16:16:13.079713', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (565, 1, '2011-09-08 16:21:10.763034', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (566, 1, '2011-09-08 16:21:10.813183', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (567, 1, '2011-09-08 16:21:13.908392', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (568, 1, '2011-09-08 16:21:15.437498', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (569, 1, '2011-09-08 16:21:55.316857', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (570, 1, '2011-09-08 16:22:24.418963', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (571, 1, '2011-09-08 16:22:24.437011', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (572, 1, '2011-09-08 16:22:27.924294', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (573, 1, '2011-09-08 16:22:29.29707', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (574, 1, '2011-09-08 16:22:40.442663', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (575, 1, '2011-09-08 16:22:42.266146', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (576, 1, '2011-09-08 16:22:52.35786', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (577, 1, '2011-09-08 16:22:53.506101', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (578, 1, '2011-09-08 16:23:19.50709', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (579, 1, '2011-09-08 16:23:49.759917', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (580, 1, '2011-09-08 16:23:51.222946', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (581, 1, '2011-09-08 16:25:07.914167', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (582, 1, '2011-09-08 16:25:07.943465', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (583, 1, '2011-09-08 16:25:10.221542', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (584, 1, '2011-09-08 16:25:14.720475', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (585, 1, '2011-09-08 16:25:17.591359', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (586, 1, '2011-09-08 16:29:13.361966', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (587, 1, '2011-09-08 16:29:13.409518', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (588, 1, '2011-09-08 16:29:15.014273', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (589, 0, '2011-09-08 16:29:19.39171', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (590, 0, '2011-09-08 16:29:19.431598', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (591, 0, '2011-09-08 16:29:27.83935', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (592, 0, '2011-09-08 16:29:29.660594', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (593, 0, '2011-09-08 16:29:54.637744', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (594, 0, '2011-09-08 16:29:54.679407', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (595, 0, '2011-09-08 16:29:58.547905', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (596, 0, '2011-09-08 16:30:34.173055', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (597, 0, '2011-09-08 16:30:36.203553', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (598, 0, '2011-09-08 16:30:46.16352', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (599, 0, '2011-09-08 16:30:48.417051', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (600, 0, '2011-09-08 16:31:43.003067', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (601, 0, '2011-09-08 16:31:44.768188', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (602, 0, '2011-09-08 16:32:37.38545', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (603, 0, '2011-09-08 16:32:37.389159', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (604, 0, '2011-09-08 16:32:40.828909', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (605, 0, '2011-09-08 16:32:52.141041', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (606, 0, '2011-09-08 16:32:52.143808', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (607, 0, '2011-09-08 16:32:55.132682', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (608, 0, '2011-09-08 16:32:56.967893', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (609, 0, '2011-09-08 16:33:59.91735', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (610, 0, '2011-09-08 16:33:59.921484', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (611, 0, '2011-09-08 16:34:03.343612', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (612, 0, '2011-09-08 16:34:04.479211', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (613, 0, '2011-09-08 16:34:11.533847', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (614, 1, '2011-09-08 16:34:17.144342', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (615, 1, '2011-09-08 16:34:17.157463', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (616, 1, '2011-09-08 16:34:19.754293', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (617, 1, '2011-09-08 16:35:01.748054', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (618, 1, '2011-09-08 16:35:04.102904', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (619, 1, '2011-09-08 16:35:47.323742', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (620, 1, '2011-09-08 16:35:49.560149', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (621, 1, '2011-09-08 16:35:51.814113', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (622, 1, '2011-09-08 16:36:08.851984', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (623, 1, '2011-09-08 16:36:21.057777', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (624, 1, '2011-09-08 16:36:22.518093', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (625, 1, '2011-09-08 16:36:24.305862', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (626, 1, '2011-09-08 16:36:28.495097', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (627, 1, '2011-09-08 16:36:29.497726', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (628, 1, '2011-09-08 16:36:31.794306', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (629, 1, '2011-09-08 16:36:32.970353', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (630, 1, '2011-09-08 16:36:34.151509', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (631, 1, '2011-09-08 16:36:37.658471', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (632, 1, '2011-09-08 16:36:40.215318', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (633, 1, '2011-09-08 16:37:13.234822', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (634, 1, '2011-09-08 16:37:13.244928', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (635, 1, '2011-09-08 16:37:16.691535', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (636, 0, '2011-09-08 16:37:21.487442', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (637, 0, '2011-09-08 16:37:21.496967', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (638, 0, '2011-09-08 16:37:24.128057', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (639, 0, '2011-09-08 16:37:27.471135', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (640, 0, '2011-09-08 16:37:57.002056', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (641, 0, '2011-09-08 16:38:04.76062', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (642, 0, '2011-09-08 16:38:06.816402', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (643, 0, '2011-09-08 16:38:59.99305', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (644, 0, '2011-09-08 16:39:03.155531', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (645, 0, '2011-09-08 16:39:03.179096', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (646, 0, '2011-09-08 16:39:05.331948', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (647, 0, '2011-09-08 16:39:07.73598', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (648, 0, '2011-09-08 16:39:28.794812', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (649, 0, '2011-09-08 16:39:30.233784', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (650, 0, '2011-09-08 16:40:16.835489', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (651, 0, '2011-09-08 16:41:10.873842', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (652, 0, '2011-09-08 16:41:13.328493', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (653, 2, '2011-09-08 16:41:19.863788', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (654, 2, '2011-09-08 16:41:19.890623', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (655, 2, '2011-09-08 16:41:22.594434', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (656, 2, '2011-09-08 16:41:42.937403', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (657, 0, '2011-09-08 16:41:47.629647', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (658, 0, '2011-09-08 16:41:47.640208', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (659, 0, '2011-09-08 16:41:54.434193', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (660, 0, '2011-09-08 16:42:06.926765', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (661, 0, '2011-09-08 16:42:16.391501', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (662, 2, '2011-09-08 16:42:33.737832', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (663, 2, '2011-09-08 16:42:33.75054', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (664, 2, '2011-09-08 16:42:36.980226', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (665, 2, '2011-09-08 16:42:46.041746', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (666, 0, '2011-09-08 16:42:51.667344', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (667, 0, '2011-09-08 16:42:51.679001', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (668, 0, '2011-09-08 16:42:54.066949', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (669, 0, '2011-09-08 16:42:55.674165', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (670, 2, '2011-09-08 16:43:00.332797', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (671, 2, '2011-09-08 16:43:00.337655', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (672, 2, '2011-09-08 16:43:02.854309', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (673, 2, '2011-09-08 16:43:04.580945', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (674, 2, '2011-09-08 16:43:19.990446', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (675, 2, '2011-09-08 16:43:43.890082', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (676, 2, '2011-09-08 16:43:45.95765', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (677, 2, '2011-09-08 16:43:49.605942', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (678, 0, '2011-09-08 16:43:54.595651', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (679, 0, '2011-09-08 16:43:54.654519', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (680, 0, '2011-09-08 16:43:58.664314', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (681, 0, '2011-09-08 16:44:06.514445', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (682, 0, '2011-09-08 16:44:46.193911', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (683, 0, '2011-09-08 16:44:48.542697', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (684, 0, '2011-09-08 16:44:54.274428', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (685, 0, '2011-09-08 16:44:58.883298', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (686, 0, '2011-09-08 16:45:05.111507', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (687, 0, '2011-09-08 16:45:14.53532', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (688, 0, '2011-09-08 16:45:20.228787', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (689, 5, '2011-09-08 16:45:27.811588', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (690, 5, '2011-09-08 16:45:27.833548', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (691, 5, '2011-09-08 16:45:30.721914', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (692, 5, '2011-09-08 16:45:32.929379', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (693, 0, '2011-09-08 16:45:36.690586', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (694, 0, '2011-09-08 16:45:36.701602', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (695, 0, '2011-09-08 16:45:42.738292', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (696, 0, '2011-09-08 16:45:46.546308', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (697, 0, '2011-09-08 16:45:56.330044', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (698, 0, '2011-09-08 16:45:58.064979', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (699, 0, '2011-09-08 16:46:03.343495', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (700, 0, '2011-09-08 16:46:04.940407', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (701, 5, '2011-09-08 16:46:08.456969', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (702, 5, '2011-09-08 16:46:08.48781', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (703, 5, '2011-09-08 16:46:13.697977', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (704, 5, '2011-09-08 16:46:16.599008', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (705, 5, '2011-09-08 16:46:26.194294', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (706, 5, '2011-09-08 16:46:38.321119', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (707, 5, '2011-09-08 16:46:45.913387', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (708, 5, '2011-09-08 16:46:48.559572', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (709, 5, '2011-09-08 16:46:50.583649', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (710, 5, '2011-09-08 16:47:21.55309', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (711, 5, '2011-09-08 16:47:54.290682', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (712, 5, '2011-09-08 16:47:56.613117', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (713, 5, '2011-09-08 16:49:07.546847', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (714, 5, '2011-09-08 16:49:07.572386', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (715, 5, '2011-09-08 16:49:11.807306', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (716, 5, '2011-09-08 16:49:13.812203', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (717, 5, '2011-09-08 16:49:19.065889', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (718, 5, '2011-09-08 16:49:20.711885', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (719, 5, '2011-09-08 16:49:24.112172', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (720, 5, '2011-09-08 16:49:26.791633', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (721, 5, '2011-09-08 16:49:28.976919', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (722, 5, '2011-09-08 16:49:34.618035', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (723, 5, '2011-09-08 16:49:35.676169', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (724, 5, '2011-09-08 16:49:38.045723', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (725, 5, '2011-09-08 16:49:42.135925', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (726, 5, '2011-09-08 16:49:47.028603', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (727, 5, '2011-09-08 16:50:10.450933', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (728, 5, '2011-09-08 16:50:13.106611', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (729, 5, '2011-09-08 16:50:54.430349', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (730, 5, '2011-09-08 16:51:08.587885', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (731, 5, '2011-09-08 16:51:10.285398', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (732, 5, '2011-09-08 16:51:22.532135', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (733, 5, '2011-09-08 16:51:34.752459', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (734, 5, '2011-09-08 16:51:36.489274', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (735, 5, '2011-09-08 16:51:40.76156', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (736, 5, '2011-09-08 16:51:42.967455', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (737, 5, '2011-09-08 16:51:47.68731', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (738, 5, '2011-09-08 16:51:49.863075', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (739, 5, '2011-09-08 16:51:59.423319', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (740, 5, '2011-09-08 16:52:09.453967', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (741, 5, '2011-09-08 16:52:10.98745', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (742, 5, '2011-09-08 16:52:42.815294', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (743, 5, '2011-09-08 16:52:45.975075', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (744, 5, '2011-09-08 16:52:50.937861', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (745, 5, '2011-09-08 16:52:53.239361', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (746, 5, '2011-09-08 16:52:54.814529', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (747, 5, '2011-09-08 16:52:56.241135', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (748, 5, '2011-09-08 16:53:01.422546', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (749, 5, '2011-09-08 16:53:05.876239', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (750, 5, '2011-09-08 16:54:11.353699', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (751, 5, '2011-09-08 16:54:11.365941', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (752, 5, '2011-09-08 16:54:14.947351', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (753, 5, '2011-09-08 16:54:17.140978', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (754, 5, '2011-09-08 16:54:38.39264', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (755, 5, '2011-09-08 16:54:40.037526', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (756, 5, '2011-09-08 16:54:57.491972', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (757, 5, '2011-09-08 16:54:58.673894', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (758, 5, '2011-09-08 16:55:00.830809', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (759, 5, '2011-09-08 16:55:05.504422', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (760, 5, '2011-09-08 16:55:05.528928', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (761, 5, '2011-09-08 16:55:19.006229', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (762, 5, '2011-09-08 16:55:19.036994', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (763, 5, '2011-09-08 16:55:21.604246', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (764, 5, '2011-09-08 16:55:23.845743', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (765, 5, '2011-09-08 16:55:45.888937', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (766, 5, '2011-09-08 16:55:48.457018', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (767, 5, '2011-09-08 16:55:49.952758', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (768, 5, '2011-09-08 16:56:01.814843', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (769, 5, '2011-09-08 16:56:04.192211', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (770, 5, '2011-09-08 16:56:08.759174', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (771, 5, '2011-09-08 16:56:14.534082', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (772, 5, '2011-09-08 16:56:16.14284', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (773, 5, '2011-09-08 16:56:19.279281', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (774, 5, '2011-09-08 16:56:20.411032', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (775, 5, '2011-09-08 16:56:22.130567', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (776, 5, '2011-09-08 16:57:18.193359', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (777, 5, '2011-09-08 16:57:21.31711', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (778, 5, '2011-09-08 16:57:23.199775', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (779, 5, '2011-09-08 16:57:24.565197', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (780, 5, '2011-09-08 16:57:34.28828', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (781, 5, '2011-09-08 16:57:37.42269', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (782, 5, '2011-09-08 16:58:13.230127', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (783, 5, '2011-09-08 16:59:01.771099', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (784, 5, '2011-09-08 16:59:03.318403', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (785, 5, '2011-09-08 16:59:19.119161', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (786, 5, '2011-09-08 16:59:21.575484', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (787, 5, '2011-09-08 16:59:27.254484', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (788, 5, '2011-09-08 16:59:30.352188', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (789, 5, '2011-09-08 16:59:31.658817', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (790, 5, '2011-09-08 16:59:33.095461', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (791, 5, '2011-09-08 16:59:34.318806', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (792, 5, '2011-09-08 16:59:45.649387', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (793, 5, '2011-09-08 16:59:47.192166', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (794, 5, '2011-09-08 17:00:56.313616', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (795, 5, '2011-09-08 17:00:57.798524', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (796, 5, '2011-09-08 17:01:00.697824', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (797, 5, '2011-09-08 17:01:02.054175', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (798, 5, '2011-09-08 17:01:12.761402', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (799, 5, '2011-09-08 17:01:14.176184', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (800, 5, '2011-09-08 17:02:21.318045', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (801, 5, '2011-09-08 17:02:26.76584', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (802, 5, '2011-09-08 17:02:28.403998', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (803, 5, '2011-09-08 17:02:30.282141', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (804, 5, '2011-09-08 17:02:32.738857', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (805, 5, '2011-09-08 17:03:24.294362', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (806, 5, '2011-09-08 17:04:17.466308', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (807, 5, '2011-09-08 17:04:29.602345', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (808, 5, '2011-09-08 17:04:45.684867', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (809, 5, '2011-09-08 17:04:49.8317', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (810, 5, '2011-09-08 17:04:53.715563', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (811, 1, '2011-09-08 17:04:58.385863', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (812, 1, '2011-09-08 17:04:58.397977', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (813, 1, '2011-09-08 17:05:00.687615', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (814, 1, '2011-09-08 17:05:02.539694', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (815, 1, '2011-09-08 17:05:04.729285', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (816, 1, '2011-09-08 17:05:46.528177', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (817, 1, '2011-09-08 17:05:48.224813', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (818, 1, '2011-09-08 17:05:49.676565', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (819, 1, '2011-09-08 17:05:52.193627', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (820, 1, '2011-09-08 17:06:24.988117', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (821, 1, '2011-09-08 17:06:26.485552', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (822, 1, '2011-09-08 17:06:31.232898', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (823, 5, '2011-09-08 17:06:37.973609', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (824, 5, '2011-09-08 17:06:37.987803', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (825, 5, '2011-09-08 17:06:40.349283', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (826, 5, '2011-09-08 17:07:18.367868', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (827, 5, '2011-09-08 17:07:24.362767', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (828, 5, '2011-09-08 17:07:26.907957', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (829, 5, '2011-09-08 17:07:28.698661', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (830, 5, '2011-09-08 17:07:34.875199', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (831, 5, '2011-09-08 17:07:38.474598', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (832, 5, '2011-09-08 17:07:39.896102', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (833, 5, '2011-09-08 17:07:41.272797', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (834, 5, '2011-09-08 17:07:42.1035', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (835, 5, '2011-09-08 17:07:43.17637', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (836, 5, '2011-09-08 17:07:45.375479', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (837, 5, '2011-09-08 17:07:46.211077', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (838, 5, '2011-09-08 17:07:47.760886', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (839, 5, '2011-09-08 17:08:06.969401', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (840, 5, '2011-09-08 17:08:13.541261', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (841, 5, '2011-09-08 17:09:03.943916', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (842, 5, '2011-09-08 17:09:26.615547', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (843, 5, '2011-09-08 17:09:34.884355', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (844, 5, '2011-09-08 17:09:38.373731', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (845, 5, '2011-09-08 17:09:39.645004', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (846, 5, '2011-09-08 17:09:43.213769', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (847, 5, '2011-09-08 17:09:52.502798', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (848, 5, '2011-09-08 17:09:58.909022', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (849, 5, '2011-09-08 17:10:03.653881', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (850, 5, '2011-09-08 17:10:16.819792', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (851, 5, '2011-09-08 17:10:34.276881', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (852, 5, '2011-09-08 17:10:42.347886', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (853, 0, '2011-09-08 17:10:46.265499', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (854, 0, '2011-09-08 17:10:46.270173', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (855, 0, '2011-09-08 17:10:50.148994', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (856, 0, '2011-09-08 17:10:52.085063', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (857, 0, '2011-09-08 17:10:57.790515', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (858, 0, '2011-09-08 17:11:26.800456', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (859, 0, '2011-09-08 17:11:40.294587', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (860, 0, '2011-09-08 17:11:42.332172', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (861, 5, '2011-09-08 17:11:45.661965', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (862, 5, '2011-09-08 17:11:45.684087', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (863, 5, '2011-09-08 17:11:48.716103', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (864, 5, '2011-09-08 17:11:49.730008', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (865, 5, '2011-09-08 17:12:00.523894', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (866, 5, '2011-09-08 17:12:11.13285', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (867, 5, '2011-09-08 17:12:25.290576', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (868, 5, '2011-09-08 17:12:36.250424', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (869, 5, '2011-09-08 17:12:39.371466', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (870, 5, '2011-09-08 17:12:43.33078', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (871, 5, '2011-09-08 17:12:47.324619', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (872, 5, '2011-09-08 17:12:50.192709', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (873, 5, '2011-09-08 17:12:53.593845', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (874, 5, '2011-09-08 17:12:55.252992', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (875, 5, '2011-09-08 17:12:58.424362', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (876, 1, '2011-09-08 17:13:03.387264', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (877, 1, '2011-09-08 17:13:03.411119', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (878, 1, '2011-09-08 17:13:06.560682', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (879, 1, '2011-09-08 17:13:09.23637', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (880, 1, '2011-09-08 17:13:13.131124', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (881, 1, '2011-09-08 17:13:23.315267', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (882, 5, '2011-09-08 17:13:28.821644', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (883, 5, '2011-09-08 17:13:28.836504', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (884, 5, '2011-09-08 17:13:31.42237', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (885, 5, '2011-09-08 17:13:35.012507', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (886, 5, '2011-09-08 17:13:38.547854', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (887, 5, '2011-09-08 17:13:41.123611', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (888, 5, '2011-09-08 17:13:47.113082', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (889, 5, '2011-09-08 17:13:55.963802', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (890, 5, '2011-09-08 17:13:59.593111', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (891, 5, '2011-09-08 17:14:00.782066', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (892, 5, '2011-09-08 17:14:02.357731', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (893, 5, '2011-09-08 17:18:27.826752', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (894, 5, '2011-09-08 17:18:39.608057', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (895, 5, '2011-09-08 17:18:41.612736', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (896, 5, '2011-09-08 17:36:03.427719', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (897, 5, '2011-09-09 09:03:47.567703', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (898, 5, '2011-09-09 09:03:47.554115', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (899, 5, '2011-09-09 09:11:53.650817', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (900, 0, '2011-09-09 09:11:57.972074', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (901, 0, '2011-09-09 09:11:58.075649', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (902, 0, '2011-09-09 09:12:00.554982', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (903, 0, '2011-09-09 09:12:51.212568', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (904, 0, '2011-09-09 09:12:53.066441', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (905, 0, '2011-09-09 09:12:54.804543', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (906, 0, '2011-09-09 09:17:43.41082', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (907, 0, '2011-09-09 09:17:44.841459', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (908, 0, '2011-09-09 09:28:43.398681', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (909, 0, '2011-09-09 09:28:44.31415', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (910, 0, '2011-09-09 09:28:45.788135', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (911, 0, '2011-09-09 09:34:36.49231', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (912, 0, '2011-09-09 09:34:36.500379', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (913, 0, '2011-09-09 09:34:40.17189', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (914, 0, '2011-09-09 09:34:45.702269', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (915, 0, '2011-09-09 09:41:37.970661', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (916, 0, '2011-09-09 09:41:48.346201', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (917, 0, '2011-09-09 09:41:48.387745', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (918, 0, '2011-09-09 09:41:52.213139', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (919, 0, '2011-09-09 09:41:59.479771', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (920, 0, '2011-09-09 09:42:01.247742', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (921, 0, '2011-09-09 09:42:02.940252', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (922, 0, '2011-09-09 09:42:04.275361', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (923, 0, '2011-09-09 09:42:08.734109', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (924, 0, '2011-09-09 09:42:18.802674', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (925, 0, '2011-09-09 09:42:20.398417', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (926, 0, '2011-09-09 09:42:30.336777', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (927, 0, '2011-09-09 09:42:36.441354', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (928, 0, '2011-09-09 09:42:42.071989', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (929, 0, '2011-09-09 09:43:04.19581', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (930, 0, '2011-09-09 09:43:11.710199', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (931, 0, '2011-09-09 09:43:22.558097', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (932, 0, '2011-09-09 09:43:35.123771', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (933, 0, '2011-09-09 09:43:36.88668', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (934, 0, '2011-09-09 09:43:48.112156', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (935, 0, '2011-09-09 09:44:01.792252', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (936, 0, '2011-09-09 09:44:04.36971', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (937, 0, '2011-09-09 09:44:30.128605', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (938, 0, '2011-09-09 09:44:33.807532', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (939, 0, '2011-09-09 09:44:35.427403', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (940, 0, '2011-09-09 09:44:42.030223', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (941, 0, '2011-09-09 09:47:08.150149', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (942, 0, '2011-09-09 09:47:09.519672', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (943, 0, '2011-09-09 09:47:58.650897', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (944, 0, '2011-09-09 09:48:14.577471', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (945, 0, '2011-09-09 09:48:15.779018', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (946, 0, '2011-09-09 09:48:32.877262', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (947, 0, '2011-09-09 09:48:34.240187', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (948, 0, '2011-09-09 09:49:01.540892', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (949, 0, '2011-09-09 09:49:03.782176', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (950, 0, '2011-09-09 09:49:07.198088', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (951, 0, '2011-09-09 09:49:16.287999', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (952, 0, '2011-09-09 09:49:19.33817', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (953, 0, '2011-09-09 09:49:21.17335', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (954, 0, '2011-09-09 09:49:22.656434', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (955, 0, '2011-09-09 09:49:28.381988', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (956, 0, '2011-09-09 09:49:34.581581', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (957, 0, '2011-09-09 09:49:52.141301', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (958, 0, '2011-09-09 09:49:52.155714', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (959, 0, '2011-09-09 09:49:54.503233', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (960, 0, '2011-09-09 09:49:59.167322', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (961, 0, '2011-09-09 09:50:01.402277', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (962, 0, '2011-09-09 09:50:21.50349', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (963, 0, '2011-09-09 09:50:21.517983', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (964, 0, '2011-09-09 10:09:49.820536', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (965, 0, '2011-09-09 10:09:49.847911', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (966, 0, '2011-09-09 10:09:52.090323', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (967, 0, '2011-09-09 10:11:59.830774', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (968, 0, '2011-09-09 10:11:59.8463', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (969, 0, '2011-09-09 10:12:08.118419', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (970, 0, '2011-09-09 10:12:09.482473', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (971, 0, '2011-09-09 10:12:10.819629', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (972, 0, '2011-09-09 10:12:12.044176', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (973, 0, '2011-09-09 10:12:13.808089', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (974, 0, '2011-09-09 10:30:23.058944', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (975, 0, '2011-09-09 10:30:27.682082', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (976, 0, '2011-09-09 10:31:03.837259', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (977, 0, '2011-09-09 10:31:06.387903', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (978, 0, '2011-09-09 10:31:15.194835', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (979, 0, '2011-09-09 10:31:15.210222', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (980, 0, '2011-09-09 10:31:22.320385', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (981, 0, '2011-09-09 10:31:41.500518', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (982, 0, '2011-09-09 10:31:43.585779', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (983, 0, '2011-09-09 10:31:45.106187', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (984, 0, '2011-09-09 10:31:47.462394', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (985, 0, '2011-09-09 10:31:49.701243', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (986, 0, '2011-09-09 10:31:51.002001', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (987, 0, '2011-09-09 10:34:28.511305', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (988, 0, '2011-09-09 10:34:28.53281', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (989, 0, '2011-09-09 10:34:32.784413', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (990, 0, '2011-09-09 10:34:34.253538', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (991, 0, '2011-09-09 10:34:43.028948', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (992, 0, '2011-09-09 10:39:37.860924', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (993, 0, '2011-09-09 10:39:39.095027', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (994, 0, '2011-09-09 10:39:45.438439', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (995, 0, '2011-09-09 10:39:47.044072', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (996, 0, '2011-09-09 10:39:56.707531', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (997, 0, '2011-09-09 10:40:00.058136', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (998, 0, '2011-09-09 10:40:01.224027', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (999, 0, '2011-09-09 10:40:04.591748', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1000, 0, '2011-09-09 10:40:06.111772', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1001, 0, '2011-09-09 10:40:18.6963', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1002, 0, '2011-09-09 10:40:40.320387', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1003, 0, '2011-09-09 10:40:41.892461', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1004, 0, '2011-09-09 10:41:21.355001', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1005, 0, '2011-09-09 10:41:27.77408', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1006, 0, '2011-09-09 10:41:36.250457', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1007, 0, '2011-09-09 10:41:40.679069', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1008, 0, '2011-09-09 10:41:57.338761', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1009, 0, '2011-09-09 10:41:59.70644', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1010, 0, '2011-09-09 10:42:01.065298', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1011, 0, '2011-09-09 10:42:08.844476', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1012, 0, '2011-09-09 10:42:11.102866', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1013, 0, '2011-09-09 10:43:04.140902', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1014, 0, '2011-09-09 10:43:05.247012', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1015, 0, '2011-09-09 10:43:13.270775', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1016, 0, '2011-09-09 10:43:15.065048', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1017, 0, '2011-09-09 10:44:22.132605', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1018, 0, '2011-09-09 10:44:23.551551', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1019, 0, '2011-09-09 10:44:26.967587', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1020, 0, '2011-09-09 10:44:28.637664', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1021, 0, '2011-09-09 10:44:31.389761', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1022, 0, '2011-09-09 10:44:32.897209', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1023, 0, '2011-09-09 10:45:16.1165', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1024, 0, '2011-09-09 10:45:16.4974', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1025, 0, '2011-09-09 10:45:17.792704', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1026, 0, '2011-09-09 10:45:24.34765', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1027, 0, '2011-09-09 10:45:25.589017', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1028, 0, '2011-09-09 10:45:33.932436', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1029, 0, '2011-09-09 10:45:40.149885', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1030, 0, '2011-09-09 10:45:52.12057', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1031, 0, '2011-09-09 10:45:53.632792', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1032, 0, '2011-09-09 10:46:01.695874', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1033, 0, '2011-09-09 10:46:02.291674', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1034, 0, '2011-09-09 10:46:04.526806', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1035, 0, '2011-09-09 10:46:06.86389', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1036, 0, '2011-09-09 10:46:07.633142', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1037, 0, '2011-09-09 10:46:09.281313', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1038, 0, '2011-09-09 10:46:27.474788', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1039, 0, '2011-09-09 10:47:07.9426', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1040, 0, '2011-09-09 10:47:10.497213', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1041, 0, '2011-09-09 10:47:11.420406', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1042, 0, '2011-09-09 10:47:30.14807', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1043, 0, '2011-09-09 10:47:31.675763', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1044, 0, '2011-09-09 10:47:34.959338', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1045, 0, '2011-09-09 10:47:42.974598', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1046, 0, '2011-09-09 10:47:43.755656', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1047, 0, '2011-09-09 10:47:44.754291', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1048, 0, '2011-09-09 10:49:40.271921', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1049, 0, '2011-09-09 10:49:40.295563', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1050, 0, '2011-09-09 10:49:43.485018', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1051, 0, '2011-09-09 10:53:52.989406', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1052, 0, '2011-09-09 10:54:20.0494', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1053, 0, '2011-09-09 10:54:40.291324', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1054, 0, '2011-09-09 10:55:03.987195', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1055, 0, '2011-09-09 10:55:05.394292', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1056, 0, '2011-09-09 10:55:07.859213', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1057, 0, '2011-09-09 10:57:06.768827', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1058, 0, '2011-09-09 10:57:08.174853', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1059, 0, '2011-09-09 10:57:33.733943', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1060, 0, '2011-09-09 10:57:35.919443', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1061, 0, '2011-09-09 10:57:43.604713', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1062, 0, '2011-09-09 10:57:44.669854', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1063, 0, '2011-09-09 10:57:45.869151', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1064, 0, '2011-09-09 10:59:39.530313', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1065, 0, '2011-09-09 10:59:56.416079', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1066, 0, '2011-09-09 10:59:59.859835', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1067, 0, '2011-09-09 11:00:47.523679', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1068, 0, '2011-09-09 11:01:06.689444', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1069, 0, '2011-09-09 11:01:09.64037', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1070, 0, '2011-09-09 11:03:05.954077', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1071, 0, '2011-09-09 11:03:07.563334', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1072, 0, '2011-09-09 11:03:10.809895', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1073, 0, '2011-09-09 11:03:13.567978', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1074, 0, '2011-09-09 11:03:25.602326', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1075, 0, '2011-09-09 11:03:27.716521', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1076, 0, '2011-09-09 11:03:42.416399', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1077, 0, '2011-09-09 11:03:58.328544', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1078, 0, '2011-09-09 11:03:59.708309', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1079, 0, '2011-09-09 11:05:39.833952', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1080, 0, '2011-09-09 11:05:53.063796', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1081, 0, '2011-09-09 11:05:54.609276', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1082, 0, '2011-09-09 11:06:38.518179', '127.0.0.1', NULL);
INSERT INTO sys_logins VALUES (1083, 0, '2012-07-16 23:56:16.985779', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1084, 0, '2012-07-16 23:56:18.566692', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1085, 0, '2012-07-16 23:56:19.243593', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1086, 0, '2012-07-16 23:56:20.52554', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1087, 0, '2012-07-16 23:56:21.229044', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1088, 0, '2012-07-16 23:56:21.664437', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1089, 0, '2012-07-16 23:56:22.364361', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1090, 0, '2012-07-16 23:56:23.934953', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1091, 5, '2012-07-17 00:38:20.699202', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1092, 5, '2012-07-17 00:38:20.709886', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1093, 5, '2012-07-17 00:38:24.003348', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1094, 5, '2012-07-17 00:38:24.999597', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1095, 5, '2012-07-17 00:38:28.199212', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1096, 5, '2012-07-17 00:38:31.598497', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1097, 5, '2012-07-17 00:38:56.235408', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1098, 5, '2012-07-17 00:38:57.382853', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1099, 5, '2012-07-17 00:39:03.974563', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1100, 5, '2012-07-17 00:40:19.343137', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1101, 5, '2012-07-17 00:40:20.782558', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1102, 5, '2012-07-17 00:40:22.515263', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1103, 0, '2012-07-20 23:02:30.609823', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1104, 0, '2012-07-20 23:03:15.814606', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1105, 0, '2012-07-20 23:03:15.838662', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1106, 0, '2012-07-20 23:03:18.471495', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1107, 0, '2012-07-20 23:03:19.556348', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1108, 0, '2012-07-20 23:03:22.907811', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1109, 0, '2012-07-20 23:03:24.839133', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1110, 0, '2012-07-20 23:03:25.748921', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1111, 0, '2012-07-20 23:03:29.880743', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1112, 0, '2012-07-20 23:03:32.758736', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1113, 0, '2012-07-20 23:03:34.994168', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1114, 0, '2012-07-20 23:03:56.497183', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1115, 0, '2012-07-20 23:03:57.453102', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1116, 0, '2012-07-20 23:05:20.10749', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1117, 0, '2012-07-20 23:23:06.041959', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1118, 0, '2012-07-20 23:23:08.034448', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1119, 0, '2012-07-20 23:23:40.012997', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1120, 0, '2012-07-20 23:23:42.335493', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1121, 0, '2012-07-21 05:57:44.134136', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1122, 0, '2012-07-21 05:57:44.138605', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1123, 0, '2012-07-21 05:57:47.905005', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1124, 0, '2012-07-21 05:57:51.089813', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1125, 0, '2012-07-21 06:00:32.357566', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1126, 0, '2012-07-22 23:33:53.985898', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1127, 0, '2012-07-22 23:33:53.991287', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1128, 0, '2012-07-22 23:33:57.706181', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1129, 0, '2012-07-22 23:34:00.357567', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1130, 0, '2012-07-22 23:34:01.851818', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1131, 0, '2012-07-22 23:34:03.3522', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1132, 0, '2012-07-22 23:34:04.219419', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1133, 0, '2012-07-22 23:34:08.32096', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1134, 0, '2012-07-22 23:34:09.545314', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1135, 0, '2012-07-22 23:34:22.039473', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1136, 0, '2012-07-22 23:34:32.194947', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1137, 0, '2012-07-22 23:34:32.800053', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1138, 0, '2012-07-22 23:34:34.52449', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1139, 0, '2012-07-22 23:34:36.514382', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1140, 0, '2012-07-22 23:34:44.196374', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1141, 0, '2012-07-22 23:34:46.989348', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1142, 0, '2012-07-22 23:34:48.78306', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1143, 0, '2012-07-22 23:34:59.319744', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1144, 0, '2012-07-22 23:35:43.36562', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1145, 0, '2012-07-22 23:35:45.378492', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1146, 0, '2012-07-22 23:35:49.51478', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1147, 0, '2012-07-22 23:35:59.433401', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1148, 0, '2012-07-22 23:36:04.133011', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1149, 0, '2012-07-22 23:36:10.769056', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1150, 0, '2012-07-23 00:50:27.876659', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1151, 0, '2012-07-23 00:50:27.882757', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1152, 0, '2012-07-23 00:50:31.653409', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1153, 0, '2012-07-23 00:50:36.375551', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1154, 0, '2012-07-23 00:50:39.555922', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1155, 0, '2012-07-23 00:50:42.129107', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1156, 0, '2012-07-23 00:51:02.637113', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1157, 0, '2012-07-23 00:51:02.662497', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1158, 0, '2012-07-23 00:51:03.825876', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1159, 0, '2012-07-23 00:51:05.220292', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1160, 0, '2012-07-23 00:51:06.043346', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1161, 0, '2012-07-23 00:51:10.500576', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1162, 0, '2012-07-23 00:51:41.251079', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1163, 0, '2012-07-23 00:52:02.53433', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1164, 0, '2012-07-23 00:52:03.45156', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1165, 0, '2012-07-23 00:52:07.165416', '192.168.0.155', NULL);
INSERT INTO sys_logins VALUES (1166, 0, '2012-07-23 01:02:12.77076', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1167, 0, '2012-07-23 01:02:12.778106', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1168, 0, '2012-07-23 01:02:20.725544', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1169, 0, '2012-07-23 01:02:27.661643', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1170, 0, '2012-07-23 01:02:27.67778', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1171, 0, '2012-07-23 01:05:31.48406', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1172, 0, '2012-07-23 01:09:26.349963', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1173, 0, '2012-07-23 01:09:26.382348', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1174, 0, '2012-07-23 01:09:30.196393', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1175, 0, '2012-07-23 01:09:31.032193', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1176, 0, '2012-07-23 01:09:33.890719', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1177, 0, '2012-07-23 01:09:39.460261', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1178, 0, '2012-07-23 01:09:54.132783', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1179, 0, '2012-07-23 01:09:55.586953', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1180, 0, '2012-07-23 01:09:57.087643', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1181, 0, '2012-07-23 01:10:04.32562', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1182, 0, '2012-07-23 01:11:25.894497', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1183, 0, '2012-07-23 01:11:53.201878', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1184, 0, '2012-07-23 01:11:53.210303', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1185, 0, '2012-07-23 01:11:56.383457', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1186, 0, '2012-07-23 01:11:57.664881', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1187, 0, '2012-07-23 01:11:59.522991', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1188, 0, '2012-07-23 01:12:00.589762', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1189, 0, '2012-07-23 01:12:01.520025', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1190, 0, '2012-07-23 01:12:02.536457', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1191, 0, '2012-07-23 01:12:03.957833', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1192, 0, '2012-07-23 01:12:04.983563', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1193, 0, '2012-07-23 01:12:10.027925', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1194, 0, '2012-07-23 01:12:10.768604', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1195, 0, '2012-07-23 01:12:11.566463', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1196, 0, '2012-07-23 01:12:14.308146', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1197, 0, '2012-07-23 01:12:20.738826', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1198, 0, '2012-07-23 01:12:20.747356', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1199, 0, '2012-07-23 01:12:23.214213', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1200, 0, '2012-07-23 01:12:24.125614', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1201, 0, '2012-07-23 01:12:26.547716', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1202, 0, '2012-07-23 01:12:27.520263', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1203, 0, '2012-07-23 01:12:28.386147', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1204, 0, '2012-07-23 01:12:29.244154', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1205, 0, '2012-07-23 01:12:29.946003', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1206, 0, '2012-07-23 01:12:30.634356', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1207, 0, '2012-07-23 01:12:37.006668', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1208, 0, '2012-07-23 01:12:38.096248', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1209, 0, '2012-07-23 01:12:39.206658', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1210, 0, '2012-07-23 01:12:47.591669', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1211, 0, '2012-07-23 01:12:54.766582', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1212, 0, '2012-07-23 01:51:19.691613', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1213, 0, '2012-07-23 01:51:22.547675', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1214, 0, '2012-07-23 01:51:24.438771', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1215, 0, '2012-07-23 01:51:27.754436', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1216, 0, '2012-07-23 01:51:28.999101', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1217, 0, '2012-07-23 01:51:30.743478', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1218, 0, '2012-07-23 01:51:33.004444', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1219, 0, '2012-07-23 01:51:34.092708', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1220, 0, '2012-07-23 01:51:34.806924', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1221, 0, '2012-07-23 01:57:01.025808', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1222, 0, '2012-07-23 01:57:12.934134', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1223, 0, '2012-07-23 02:20:44.080712', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1224, 0, '2012-07-23 02:20:44.100548', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1225, 0, '2012-07-23 02:42:29.939744', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1226, 0, '2012-07-23 02:42:29.965235', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1227, 0, '2012-07-23 02:43:23.100874', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1228, 0, '2012-07-23 02:43:28.66858', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1229, 0, '2012-07-23 02:43:41.385555', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1230, 0, '2012-07-23 02:43:50.822234', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1231, 0, '2012-07-23 02:43:56.569781', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1232, 0, '2012-07-23 02:44:19.78957', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1233, 0, '2012-07-23 02:44:47.864928', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1234, 0, '2012-07-23 02:44:53.651347', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1235, 0, '2012-07-23 02:44:57.302369', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1236, 0, '2012-07-23 02:45:01.59327', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1237, 0, '2012-07-23 02:45:04.407687', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1238, 0, '2012-07-23 02:45:20.932025', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1239, 0, '2012-07-23 02:45:28.821921', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1240, 0, '2012-07-23 02:45:53.078763', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1241, 0, '2012-07-23 02:45:57.662998', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1242, 0, '2012-07-23 02:46:08.390947', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1243, 0, '2012-07-23 02:46:12.708701', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1244, 0, '2012-07-23 02:46:26.404718', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1245, 0, '2012-07-23 02:47:48.718256', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1246, 0, '2012-07-23 02:47:54.09908', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1247, 0, '2012-07-23 02:50:01.263386', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1248, 0, '2012-07-23 02:50:32.326221', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1249, 0, '2012-07-23 02:51:28.052797', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1250, 0, '2012-07-23 02:51:45.676456', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1251, 0, '2012-07-23 02:51:48.647716', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1252, 0, '2012-07-23 02:52:17.698649', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1253, 0, '2012-07-23 02:52:46.557561', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1254, 0, '2012-07-23 02:53:36.55628', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1255, 0, '2012-07-23 02:53:37.666126', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1256, 0, '2012-07-23 02:53:38.872135', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1257, 0, '2012-07-23 02:53:41.013753', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1258, 0, '2012-07-23 03:04:24.92753', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1259, 0, '2012-07-23 03:04:38.507953', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1260, 0, '2012-07-23 03:04:41.784872', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1261, 0, '2012-07-23 03:04:54.660217', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1262, 0, '2012-07-23 03:04:57.908006', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1263, 0, '2012-07-23 03:18:52.130666', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1264, 0, '2012-07-23 05:34:18.577116', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1265, 0, '2012-07-23 05:34:18.631338', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1266, 0, '2012-07-23 05:34:25.304953', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1267, 0, '2012-07-23 05:34:29.209684', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1268, 0, '2012-07-23 05:34:31.606425', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1269, 0, '2012-07-23 05:34:33.519953', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1270, 0, '2012-07-23 05:34:39.093275', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1271, 0, '2012-07-23 05:34:44.669604', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1272, 0, '2012-07-23 05:34:47.000097', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1273, 0, '2012-07-23 05:34:49.026312', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1274, 0, '2012-07-23 05:34:51.24077', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1275, 0, '2012-07-23 05:34:54.927253', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1276, 0, '2012-07-23 05:35:00.028887', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1277, 0, '2012-07-23 05:35:04.763573', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1278, 0, '2012-07-23 05:35:09.533848', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1279, 0, '2012-07-23 05:45:49.306713', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1280, 0, '2012-07-23 05:45:49.315618', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1281, 0, '2012-07-23 05:46:39.618262', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1282, 0, '2012-07-23 05:46:42.852186', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1283, 0, '2012-07-23 05:46:44.042618', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1284, 0, '2012-07-23 05:46:45.17235', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1285, 0, '2012-07-23 05:46:49.983437', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1286, 0, '2012-07-23 05:46:52.314112', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1287, 0, '2012-07-23 05:48:04.438748', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1288, 0, '2012-07-23 05:48:06.533773', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1289, 0, '2012-07-23 05:48:11.053162', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1290, 0, '2012-07-23 05:48:19.601965', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1291, 0, '2012-07-23 05:50:36.798763', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1292, 0, '2012-07-23 05:50:37.92604', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1293, 0, '2012-07-23 05:50:40.121482', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1294, 0, '2012-07-23 05:50:41.449765', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1295, 0, '2012-07-23 05:50:42.405667', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1296, 0, '2012-07-23 05:50:52.252759', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1297, 0, '2012-07-23 05:50:53.266662', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1298, 0, '2012-07-23 05:50:53.994342', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1299, 0, '2012-07-23 05:52:46.411079', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1300, 0, '2012-07-23 05:52:48.736601', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1301, 0, '2012-07-23 05:54:48.388611', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1302, 0, '2012-07-23 05:55:21.064328', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1303, 0, '2012-07-23 05:55:23.08419', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1304, 0, '2012-07-23 05:56:11.391965', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1305, 0, '2012-07-23 05:56:15.112017', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1306, 0, '2012-07-23 05:56:32.171291', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1307, 0, '2012-07-23 05:56:34.710449', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1308, 0, '2012-07-23 05:56:36.075022', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1309, 0, '2012-07-23 05:56:39.64481', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1310, 0, '2012-07-23 05:56:47.214355', '192.168.0.254', NULL);
INSERT INTO sys_logins VALUES (1311, 0, '2012-07-27 05:14:37.146102', '192.168.0.141', NULL);
INSERT INTO sys_logins VALUES (1312, 0, '2012-07-27 05:14:37.15152', '192.168.0.141', NULL);
INSERT INTO sys_logins VALUES (1313, 0, '2012-07-27 05:14:39.451465', '192.168.0.141', NULL);
INSERT INTO sys_logins VALUES (1314, 0, '2012-07-27 05:14:41.179215', '192.168.0.141', NULL);
INSERT INTO sys_logins VALUES (1315, 0, '2012-07-27 05:14:42.580051', '192.168.0.141', NULL);
INSERT INTO sys_logins VALUES (1316, 0, '2012-07-27 05:14:48.170347', '192.168.0.141', NULL);
INSERT INTO sys_logins VALUES (1317, 0, '2012-07-27 05:14:49.189853', '192.168.0.141', NULL);
INSERT INTO sys_logins VALUES (1318, 0, '2012-07-27 05:14:52.172197', '192.168.0.141', NULL);
INSERT INTO sys_logins VALUES (1319, 0, '2012-07-27 05:31:53.648555', '192.168.0.141', NULL);
INSERT INTO sys_logins VALUES (1320, 0, '2011-09-22 08:47:58.923757', '', NULL);
INSERT INTO sys_logins VALUES (1322, 0, '2011-09-22 11:41:59.559671', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1321, 0, '2011-09-22 11:41:59.559067', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1323, 0, '2011-09-22 11:42:04.544155', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1325, 0, '2011-09-22 12:12:53.611102', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1324, 0, '2011-09-22 12:12:53.619725', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1326, 0, '2011-09-22 12:13:51.687801', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1327, 0, '2011-09-22 12:13:52.658177', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1328, 0, '2011-09-22 12:13:54.370589', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1329, 0, '2011-09-22 12:13:56.585683', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1330, 0, '2011-09-22 12:13:58.005444', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1331, 0, '2011-09-22 12:14:04.191485', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1332, 0, '2011-09-22 12:14:05.910077', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1333, 0, '2011-09-22 12:21:43.241869', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1334, 0, '2011-09-22 12:21:43.285141', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1335, 0, '2011-09-22 12:21:46.915106', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1336, 0, '2011-09-22 12:21:48.898512', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1337, 0, '2011-09-22 12:21:49.725283', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1338, 0, '2011-09-22 12:21:53.605108', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1339, 0, '2011-09-22 12:22:03.187782', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1340, 0, '2011-09-22 12:22:04.853839', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1341, 0, '2011-09-22 12:22:12.693744', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1342, 0, '2011-09-22 12:22:13.671852', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1343, 0, '2011-09-22 12:22:14.534349', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1344, 0, '2011-09-22 12:22:16.636504', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1345, 0, '2011-09-22 12:22:20.693617', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1346, 0, '2011-09-22 12:22:21.915574', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1347, 0, '2011-09-22 12:35:34.809702', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1348, 0, '2011-09-22 12:35:34.838085', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1349, 0, '2011-09-22 12:35:39.338986', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1350, 0, '2011-09-22 12:44:37.980424', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1351, 0, '2011-09-22 12:44:38.007812', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1352, 0, '2011-09-22 12:44:39.950875', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1353, 0, '2011-09-22 12:44:45.229774', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1354, 0, '2011-09-22 12:45:01.715196', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1355, 0, '2011-09-22 12:45:03.439105', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1356, 0, '2011-09-22 12:45:03.45472', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1357, 0, '2011-09-22 12:45:05.508928', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1358, 0, '2011-09-22 12:46:04.233155', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1359, 0, '2011-09-22 12:46:04.24442', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1360, 0, '2011-09-22 12:46:06.463953', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1361, 0, '2011-09-22 12:46:09.741128', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1362, 0, '2011-09-22 12:46:11.407036', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1363, 0, '2011-09-22 12:46:15.64446', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1364, 0, '2011-09-22 12:49:10.339413', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1365, 0, '2011-09-22 12:49:10.355762', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1366, 0, '2011-09-22 12:49:12.727883', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1367, 0, '2011-09-22 12:49:14.013874', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1368, 0, '2011-09-22 12:51:01.45626', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1369, 0, '2011-09-22 12:51:01.469554', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1370, 0, '2011-09-22 12:51:04.286517', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1371, 0, '2011-09-22 12:51:05.537707', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1372, 0, '2011-09-22 12:51:06.980731', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1373, 0, '2011-09-22 12:51:18.45545', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1374, 0, '2011-09-22 12:51:19.930395', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1375, 0, '2011-09-22 12:51:22.724268', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1376, 0, '2011-09-22 13:05:37.734619', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1377, 0, '2011-09-22 13:05:37.819377', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1378, 0, '2011-09-22 13:05:40.109891', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1379, 0, '2011-09-22 13:05:42.13468', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1380, 0, '2011-09-22 13:06:13.736868', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1381, 0, '2011-09-22 13:06:15.902574', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1382, 0, '2011-09-22 13:06:18.764893', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1383, 0, '2011-09-22 13:07:23.507916', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1384, 0, '2011-09-22 13:07:23.526223', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1385, 0, '2011-09-22 13:07:25.466639', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1386, 0, '2011-09-22 13:07:33.463654', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1387, 0, '2011-09-22 13:07:35.555307', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1388, 0, '2011-09-22 13:07:37.851859', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1389, 0, '2011-09-22 16:22:56.107671', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1390, 0, '2011-09-22 16:22:56.108221', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1391, 0, '2011-09-22 16:23:20.001757', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1392, 0, '2011-09-22 16:23:21.748046', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1393, 0, '2011-09-22 16:23:23.321639', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1394, 0, '2011-09-22 16:23:24.925737', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1395, 0, '2011-09-22 16:23:26.404683', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1396, 0, '2011-09-22 16:23:28.663939', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1397, 0, '2011-09-22 16:23:31.33493', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1398, 0, '2011-09-22 16:23:33.330942', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1399, 0, '2011-09-22 16:23:35.008313', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1400, 0, '2011-09-22 16:24:20.762078', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1401, 0, '2011-09-22 16:24:23.7218', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1402, 0, '2011-09-22 16:24:25.295659', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1403, 0, '2011-09-22 16:24:29.057032', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1404, 0, '2011-09-22 16:24:31.95123', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1405, 0, '2011-09-22 16:24:34.53551', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1406, 0, '2011-09-22 16:25:24.129571', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1407, 0, '2011-09-22 16:25:25.911223', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1408, 0, '2011-09-22 16:25:55.123323', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1409, 0, '2011-09-22 16:25:55.139898', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1410, 0, '2011-09-22 16:25:57.573036', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1411, 0, '2011-09-22 16:25:59.24767', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1412, 0, '2011-09-22 16:26:00.978309', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1413, 0, '2011-09-22 16:26:01.876762', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1414, 0, '2011-09-22 16:26:06.070881', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1415, 0, '2011-09-22 16:26:07.571679', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1416, 0, '2011-09-22 16:26:12.625701', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1417, 0, '2011-09-22 16:26:14.409469', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1418, 0, '2011-09-22 16:33:42.070921', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1419, 0, '2011-09-22 16:33:42.07204', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1420, 0, '2011-09-22 16:33:45.615319', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1421, 0, '2011-09-22 16:33:47.386121', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1422, 0, '2011-09-22 16:35:08.08051', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1423, 0, '2011-09-22 16:35:10.107219', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1424, 0, '2011-09-22 16:35:11.551045', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1425, 0, '2011-09-22 16:35:12.945664', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1426, 0, '2011-09-22 16:35:16.16256', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1427, 0, '2011-09-22 16:35:16.168991', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1428, 0, '2011-09-22 16:35:19.455606', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1429, 0, '2011-09-22 16:35:21.022502', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1430, 0, '2011-09-22 16:36:22.115043', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1431, 0, '2011-09-22 16:36:22.157958', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1432, 0, '2011-09-22 16:36:25.959778', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1433, 0, '2011-09-22 16:36:27.600735', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1434, 0, '2011-09-22 16:36:32.060659', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1435, 0, '2011-09-22 16:37:35.539503', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1436, 0, '2011-09-22 16:37:36.954021', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1437, 0, '2011-09-22 16:38:24.327946', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1438, 0, '2011-09-22 16:38:24.329024', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1439, 0, '2011-09-22 16:38:27.00385', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1440, 0, '2011-09-22 16:38:28.483646', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1441, 0, '2011-09-22 16:39:01.159846', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1442, 0, '2011-09-22 16:39:17.289831', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1443, 0, '2011-09-22 16:39:19.795077', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1444, 0, '2011-09-22 16:39:22.31472', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1445, 0, '2011-09-22 16:41:54.035012', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1446, 0, '2011-09-22 16:41:59.62858', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1447, 0, '2011-09-22 16:42:00.961339', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1448, 0, '2011-09-22 17:00:53.495291', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1449, 0, '2011-09-22 17:00:53.517201', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1450, 0, '2011-09-22 17:01:24.269828', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1451, 0, '2011-09-22 17:01:25.698613', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1452, 0, '2011-09-22 17:01:28.403764', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1453, 0, '2011-09-22 17:01:31.488343', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1454, 0, '2011-09-22 17:02:16.051281', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1455, 0, '2011-09-22 17:02:18.162739', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1456, 0, '2011-09-22 17:02:18.93064', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1457, 0, '2011-09-22 17:04:15.122919', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1458, 0, '2011-09-22 17:04:15.143017', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1459, 0, '2011-09-22 17:04:28.831982', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1460, 0, '2011-09-22 17:04:32.531458', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1461, 0, '2011-09-22 17:04:34.315539', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1462, 0, '2011-09-22 17:04:39.982646', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1463, 0, '2011-09-22 17:04:42.416485', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1464, 0, '2011-09-22 17:04:46.896435', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1465, 0, '2011-09-22 17:04:49.30231', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1466, 0, '2011-09-22 17:04:50.779297', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1467, 0, '2011-09-22 17:04:53.729714', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1468, 0, '2011-09-22 17:06:17.162392', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1469, 0, '2011-09-22 17:06:17.1744', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1470, 0, '2011-09-22 17:06:19.170175', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1471, 0, '2011-09-22 17:06:20.457412', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1472, 0, '2011-09-22 17:06:23.416299', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1473, 0, '2011-09-22 17:06:24.680143', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1474, 0, '2011-09-22 17:06:25.951291', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1475, 0, '2011-09-22 17:06:27.382224', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1476, 0, '2011-09-22 17:10:18.028119', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1477, 0, '2011-09-22 17:15:13.023958', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1478, 0, '2011-09-22 17:15:15.464522', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1479, 0, '2011-09-22 17:59:41.682612', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1480, 0, '2011-09-22 17:59:49.596953', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1481, 0, '2011-09-22 18:00:05.651078', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1482, 0, '2011-09-22 18:00:07.082198', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1483, 0, '2011-09-22 18:00:12.20176', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1484, 0, '2011-09-22 18:00:16.662813', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1485, 0, '2011-09-22 18:00:18.541269', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1486, 0, '2011-09-22 18:00:35.000514', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1487, 0, '2011-09-22 18:00:38.381618', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1488, 0, '2011-09-22 18:02:22.100061', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1489, 0, '2011-09-22 18:02:24.640097', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1490, 0, '2011-09-22 18:02:31.001773', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1491, 0, '2011-09-22 18:02:32.145603', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1492, 0, '2011-09-22 18:02:46.617165', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1493, 0, '2011-09-22 18:03:38.859734', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1494, 0, '2011-09-22 18:03:38.86718', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1495, 0, '2011-09-22 18:03:43.905756', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1496, 0, '2011-09-22 18:03:45.251416', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1497, 0, '2011-09-22 18:03:48.639778', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1498, 0, '2011-09-22 18:03:49.969028', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1499, 0, '2011-09-22 18:04:01.122744', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1500, 0, '2011-09-22 18:04:02.568463', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1501, 0, '2011-09-22 18:04:04.840927', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1502, 0, '2011-09-22 18:04:06.240913', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1503, 0, '2011-09-22 18:08:47.245812', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1504, 0, '2011-09-22 18:08:48.289141', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1505, 0, '2011-09-22 18:08:51.860666', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1506, 0, '2011-09-22 18:08:53.242044', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1507, 0, '2011-09-22 18:08:55.899271', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1508, 0, '2011-09-22 18:08:57.470103', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1509, 0, '2011-09-22 18:09:15.91264', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1510, 0, '2011-09-22 18:09:16.835388', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1511, 0, '2011-09-22 18:09:21.115982', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1512, 0, '2011-09-22 18:09:41.20524', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1513, 0, '2011-09-22 18:09:41.20643', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1514, 0, '2011-09-22 18:09:44.707051', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1515, 0, '2011-09-22 18:09:46.028181', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1516, 0, '2011-09-22 18:09:57.375679', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1517, 0, '2011-09-22 18:10:07.250918', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1518, 0, '2011-09-22 18:10:13.920771', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1519, 0, '2011-09-22 18:10:15.107723', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1520, 0, '2011-09-22 18:10:18.261006', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1521, 0, '2011-09-22 18:10:25.721527', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1522, 0, '2011-09-22 18:10:28.587965', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1523, 0, '2011-09-22 18:10:36.523067', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1524, 0, '2011-09-22 18:10:39.268072', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1525, 0, '2011-09-22 18:10:42.04981', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1526, 0, '2011-09-22 18:10:46.610614', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1527, 0, '2011-09-22 18:10:52.09947', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1528, 0, '2011-09-22 18:10:59.058898', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1529, 0, '2011-09-22 18:11:11.730268', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1530, 0, '2011-09-22 18:11:14.290043', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1531, 0, '2011-09-22 18:11:17.372229', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1532, 0, '2011-09-22 18:11:18.935165', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1533, 0, '2011-09-22 18:11:23.761219', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1534, 0, '2011-09-22 18:11:26.747055', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1535, 0, '2011-09-22 18:11:31.079557', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1536, 0, '2011-09-22 18:11:36.419401', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1537, 0, '2011-09-22 18:11:53.846606', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1538, 0, '2011-09-22 18:11:57.791891', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1539, 0, '2011-09-22 18:11:59.283737', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1540, 0, '2011-09-22 18:12:21.666372', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1541, 0, '2011-09-22 18:13:15.736959', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1542, 0, '2011-09-22 18:13:17.507206', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1543, 0, '2011-09-22 18:13:23.970999', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1544, 0, '2011-09-22 18:13:25.700211', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1545, 0, '2011-09-22 18:14:03.708922', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1546, 0, '2011-09-22 18:14:48.461212', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1547, 0, '2011-09-22 18:14:49.730311', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1548, 0, '2011-09-22 18:15:02.359613', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1549, 0, '2011-09-22 18:17:07.788818', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1550, 0, '2011-09-22 18:19:18.3758', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1551, 0, '2011-09-22 18:19:20.293824', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1552, 0, '2011-09-22 18:20:06.620402', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1553, 0, '2011-09-22 18:20:10.102616', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1554, 0, '2011-09-22 18:20:10.125399', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1555, 0, '2011-09-22 18:20:13.441495', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1556, 0, '2011-09-22 18:20:14.627759', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1557, 0, '2011-09-22 18:22:00.248831', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1558, 0, '2011-09-22 18:22:00.941237', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1559, 0, '2011-09-22 18:22:01.850656', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1560, 0, '2011-09-22 18:22:02.944796', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1561, 0, '2011-09-22 18:22:06.818631', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1562, 0, '2011-09-22 18:22:07.859506', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1563, 0, '2011-09-22 18:22:09.176522', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1564, 0, '2011-09-22 18:24:42.732599', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1565, 0, '2011-09-22 18:24:42.743098', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1566, 0, '2011-09-22 18:24:45.107712', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1567, 0, '2011-09-22 18:24:59.696867', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1568, 0, '2011-09-22 18:24:59.709138', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1569, 0, '2011-09-22 18:25:02.148709', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1570, 0, '2011-09-23 09:54:26.900864', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1571, 0, '2011-09-23 09:54:26.899431', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1572, 0, '2011-09-23 09:58:33.58578', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1573, 0, '2011-09-23 09:58:35.439783', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1574, 0, '2011-09-23 09:58:56.970614', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1575, 0, '2011-09-23 10:33:34.35876', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1576, 0, '2011-09-23 10:33:36.241572', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1577, 0, '2011-09-23 10:33:38.056716', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1578, 0, '2011-09-23 10:33:50.04289', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1579, 0, '2011-09-23 10:33:52.867289', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1580, 0, '2011-09-23 10:33:59.203647', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1581, 0, '2011-09-23 10:33:59.434987', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1582, 0, '2011-09-23 10:34:03.672807', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1583, 0, '2011-09-23 10:34:04.864141', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1584, 0, '2011-09-23 10:34:46.67999', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1585, 0, '2011-09-23 10:34:46.69398', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1586, 0, '2011-09-23 10:34:50.084482', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1587, 0, '2011-09-23 10:34:51.469842', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1588, 0, '2011-09-23 10:38:16.612727', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1589, 0, '2011-09-23 10:38:16.631232', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1590, 0, '2011-09-23 10:38:19.101511', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1591, 0, '2011-09-23 10:38:20.350613', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1592, 0, '2011-09-23 10:39:27.100205', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1593, 0, '2011-09-23 10:39:27.101211', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1594, 0, '2011-09-23 10:39:32.388335', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1595, 0, '2011-09-23 10:39:33.86763', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1596, 0, '2011-09-23 10:40:11.055274', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1597, 0, '2011-09-23 10:40:13.546749', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1598, 0, '2011-09-23 10:40:14.174849', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1599, 0, '2011-09-23 10:40:16.797468', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1600, 0, '2011-09-23 10:40:16.801041', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1601, 0, '2011-09-23 10:40:20.146447', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1602, 0, '2011-09-23 10:40:21.386794', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1603, 0, '2011-09-23 10:40:36.577584', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1604, 0, '2011-09-23 10:40:37.910159', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1605, 0, '2011-09-23 10:40:37.915785', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1606, 0, '2011-09-23 10:40:40.894712', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1607, 0, '2011-09-23 10:40:41.824217', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1608, 0, '2011-09-23 10:41:42.095384', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1609, 0, '2011-09-23 10:41:44.52007', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1610, 0, '2011-09-23 10:42:01.005799', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1611, 0, '2011-09-23 10:42:03.257436', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1612, 0, '2011-09-23 10:42:04.353658', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1613, 0, '2011-09-23 10:42:10.736073', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1614, 0, '2011-09-23 10:42:13.87282', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1615, 0, '2011-09-23 10:44:13.107779', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1616, 0, '2011-09-23 10:44:14.685579', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1617, 0, '2011-09-23 10:44:15.640288', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1618, 0, '2011-09-23 10:44:16.792538', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1619, 0, '2011-09-23 10:44:53.646756', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1620, 0, '2011-09-23 10:44:54.251908', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1621, 0, '2011-09-23 10:45:07.185835', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1622, 0, '2011-09-23 10:46:10.652903', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1623, 0, '2011-09-23 10:46:12.993627', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1624, 0, '2011-09-23 10:46:56.206636', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1625, 0, '2011-09-23 10:46:57.30298', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1626, 0, '2011-09-23 10:46:59.120759', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1627, 0, '2011-09-23 10:47:01.98781', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1628, 0, '2011-09-23 10:47:23.950496', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1629, 0, '2011-09-23 10:47:24.920743', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1630, 0, '2011-09-23 10:48:36.441365', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1631, 0, '2011-09-23 10:48:38.227629', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1632, 0, '2011-09-23 10:48:59.707161', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1633, 0, '2011-09-23 10:49:01.486888', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1634, 0, '2011-09-23 10:49:59.394744', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1635, 0, '2011-09-23 10:50:01.008353', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1636, 0, '2011-09-23 10:50:04.313166', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1637, 0, '2011-09-23 10:52:03.077827', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1638, 0, '2011-09-23 10:52:17.785053', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1639, 0, '2011-09-23 10:52:18.756677', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1640, 0, '2011-09-23 10:52:21.211641', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1641, 0, '2011-09-23 10:52:22.656489', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1642, 0, '2011-09-23 10:53:02.548465', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1643, 0, '2011-09-23 10:53:03.734822', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1644, 0, '2011-09-23 10:54:18.37479', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1645, 0, '2011-09-23 10:54:19.704413', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1646, 0, '2011-09-23 10:54:26.114291', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1647, 0, '2011-09-23 10:54:27.538472', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1648, 0, '2011-09-23 11:00:03.007734', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1649, 0, '2011-09-23 11:00:11.793435', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1650, 0, '2011-09-23 11:00:36.40181', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1651, 0, '2011-09-23 11:00:38.527614', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1652, 0, '2011-09-23 11:00:44.080863', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1653, 0, '2011-09-23 11:00:45.246098', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1654, 0, '2011-09-23 11:00:52.716983', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1655, 0, '2011-09-23 11:00:53.784382', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1656, 0, '2011-09-23 11:00:54.817848', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1657, 0, '2011-09-23 11:00:58.178729', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1658, 0, '2011-09-23 11:01:34.911602', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1659, 0, '2011-09-23 11:01:36.445464', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1660, 0, '2011-09-23 11:01:40.965434', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1661, 0, '2011-09-23 11:03:20.526112', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1662, 0, '2011-09-23 11:04:49.218532', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1663, 0, '2011-09-23 11:04:59.153466', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1664, 0, '2011-09-23 11:05:01.783369', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1665, 0, '2011-09-23 11:05:13.885607', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1666, 0, '2011-09-23 11:05:16.845425', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1667, 0, '2011-09-23 11:06:04.060505', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1668, 0, '2011-09-23 11:06:10.712543', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1669, 0, '2011-09-23 11:06:13.567324', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1670, 0, '2011-09-23 11:06:17.535885', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1671, 0, '2011-09-23 11:06:19.294763', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1672, 0, '2011-09-23 11:06:55.0637', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1673, 0, '2011-09-23 11:07:02.85257', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1674, 0, '2011-09-23 11:07:07.868939', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1675, 0, '2011-09-23 11:07:09.676893', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1676, 0, '2011-09-23 11:07:13.308516', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1677, 0, '2011-09-23 11:07:16.325475', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1678, 0, '2011-09-23 11:07:25.334661', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1679, 0, '2011-09-23 11:07:28.005657', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1680, 0, '2011-09-23 11:07:31.31255', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1681, 0, '2011-09-23 11:07:39.651467', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1682, 0, '2011-09-23 11:07:55.632819', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1683, 0, '2011-09-23 11:07:58.745191', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1684, 0, '2011-09-23 11:07:59.946519', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1685, 0, '2011-09-23 11:08:11.713469', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1686, 0, '2011-09-23 11:11:45.02598', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1687, 0, '2011-09-23 11:11:45.944873', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1688, 0, '2011-09-23 11:12:21.536266', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1689, 0, '2011-09-23 11:12:22.236047', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1690, 0, '2011-09-23 11:12:24.008776', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1691, 0, '2011-09-23 11:12:25.277183', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1692, 0, '2011-09-23 11:12:28.242905', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1693, 0, '2011-09-23 11:14:22.600649', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1694, 0, '2011-09-23 11:14:25.943362', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1695, 0, '2011-09-23 11:14:27.599862', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1696, 0, '2011-09-23 11:14:30.934515', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1697, 0, '2011-09-23 11:14:33.516201', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1698, 0, '2011-09-23 11:14:35.716508', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1699, 0, '2011-09-23 11:14:40.845836', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1700, 0, '2011-09-23 11:14:42.046226', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1701, 0, '2011-09-23 11:14:45.277863', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1702, 0, '2011-09-23 11:18:24.54477', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1703, 0, '2011-09-23 11:18:26.046393', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1704, 0, '2011-09-23 11:18:29.492842', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1705, 0, '2011-09-23 11:18:40.06044', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1706, 0, '2011-09-23 11:18:42.166278', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1707, 0, '2011-09-23 11:21:12.573569', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1708, 0, '2011-09-23 11:21:30.297575', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1709, 0, '2011-09-23 11:21:43.003232', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1710, 0, '2011-09-23 11:37:16.877191', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1711, 0, '2011-09-23 11:37:18.081072', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1712, 0, '2011-09-23 11:37:18.574986', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1713, 0, '2011-09-23 11:37:23.049104', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1714, 0, '2011-09-23 11:37:24.784462', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1715, 0, '2011-09-23 11:37:35.881449', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1716, 0, '2011-09-23 11:37:37.329508', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1717, 0, '2011-09-23 11:54:44.856765', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1718, 0, '2011-09-23 11:54:46.30381', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1719, 0, '2011-09-23 11:54:52.58617', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1720, 0, '2011-09-23 12:26:49.450964', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1721, 0, '2011-09-23 12:27:23.606594', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1722, 0, '2011-09-23 12:27:25.022161', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1723, 0, '2011-09-23 12:27:32.831157', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1724, 0, '2011-09-23 12:27:34.391235', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1725, 0, '2011-09-23 12:27:36.463981', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1726, 0, '2011-09-23 12:27:39.521729', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1727, 0, '2011-09-23 12:27:45.814501', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1728, 0, '2011-09-23 12:28:49.845105', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1729, 0, '2011-09-23 12:28:59.57513', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1730, 0, '2011-09-23 12:29:03.654957', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1731, 0, '2011-09-23 12:29:07.137609', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1732, 0, '2011-09-23 12:29:40.410951', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1733, 0, '2011-09-23 12:34:29.904412', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1734, 0, '2011-09-23 12:34:32.16334', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1735, 0, '2011-09-23 12:34:44.76264', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1736, 0, '2011-09-23 12:34:48.899337', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1737, 0, '2011-09-23 12:35:06.783662', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1738, 0, '2011-09-23 12:35:08.454979', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1739, 0, '2011-09-23 12:35:10.113334', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1740, 0, '2011-09-23 12:35:11.993732', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1741, 0, '2011-09-23 12:35:15.82455', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1742, 0, '2011-09-23 12:36:47.199456', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1743, 0, '2011-09-23 12:36:48.861393', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1744, 0, '2011-09-23 12:37:01.35314', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1745, 0, '2011-09-23 12:37:02.697969', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1746, 0, '2011-09-23 12:37:12.105598', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1747, 0, '2011-09-23 12:37:46.286268', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1748, 0, '2011-09-23 12:37:48.192835', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1749, 0, '2011-09-23 12:37:51.278013', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1750, 0, '2011-09-23 12:37:52.553682', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1751, 0, '2011-09-23 12:39:32.72239', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1752, 0, '2011-09-23 12:47:28.789117', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1753, 0, '2011-09-23 12:47:32.460517', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1754, 0, '2011-09-23 12:47:42.066963', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1755, 0, '2011-09-23 12:47:51.314982', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1756, 0, '2011-09-23 12:48:09.027978', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1757, 0, '2011-09-23 12:48:10.876443', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1758, 0, '2011-09-23 12:48:22.464115', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1759, 0, '2011-09-23 12:48:39.415087', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1760, 0, '2011-09-23 12:49:06.01076', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1761, 0, '2011-09-23 12:49:09.221636', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1762, 0, '2011-09-23 12:49:26.838156', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1763, 0, '2011-09-23 12:49:51.695546', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1764, 0, '2011-09-23 12:50:03.631691', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1765, 0, '2011-09-23 12:50:10.085865', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1766, 0, '2011-09-23 12:50:16.319323', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1767, 0, '2011-09-23 12:50:24.167286', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1768, 0, '2011-09-23 12:50:26.866778', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1769, 0, '2011-09-23 12:50:28.057748', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1770, 0, '2011-09-23 12:50:32.773168', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1771, 0, '2011-09-23 12:50:34.081737', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1772, 0, '2011-09-23 12:50:50.025529', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1773, 0, '2011-09-23 15:01:29.15996', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1774, 0, '2011-09-23 15:08:51.338715', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1775, 0, '2011-09-23 15:08:51.341077', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1776, 0, '2011-09-23 15:08:55.433311', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1777, 0, '2011-09-23 15:08:56.303148', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1778, 0, '2011-09-23 15:08:57.089978', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1779, 0, '2011-09-23 15:08:57.966984', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1780, 0, '2011-09-23 15:08:59.961672', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1781, 0, '2011-09-23 15:09:00.602064', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1782, 0, '2011-09-23 15:09:04.331163', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1783, 0, '2011-09-23 15:09:06.539924', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1784, 0, '2011-09-23 15:09:08.865793', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1785, 0, '2011-09-23 15:09:11.859361', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1786, 0, '2011-09-23 15:09:13.660441', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1787, 0, '2011-09-23 15:09:15.605942', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1788, 0, '2011-09-23 15:09:18.877473', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1789, 0, '2011-09-23 15:09:19.799331', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1790, 0, '2011-09-23 15:09:20.477186', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1791, 0, '2011-09-23 15:09:21.00289', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1792, 0, '2011-09-23 15:12:54.583117', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1793, 0, '2011-09-23 15:27:25.112765', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1794, 0, '2011-09-23 15:27:25.132077', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1795, 0, '2011-09-23 15:27:27.565821', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1796, 0, '2011-09-23 15:27:31.687425', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1797, 0, '2011-09-23 15:27:33.318444', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1798, 0, '2011-09-23 15:29:57.937514', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1799, 0, '2011-09-23 15:29:59.308528', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1800, 0, '2011-09-23 15:30:01.873335', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1801, 0, '2011-09-23 15:34:30.241838', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1802, 0, '2011-09-23 15:40:23.804552', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1803, 0, '2011-09-23 15:40:55.786651', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1804, 0, '2011-09-23 15:40:55.78947', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1805, 0, '2011-09-23 15:41:28.695815', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1806, 0, '2011-09-23 15:46:03.635016', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1807, 0, '2011-09-23 15:54:44.823678', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1808, 0, '2011-09-23 15:54:46.829156', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1809, 0, '2011-09-23 15:54:50.056972', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1810, 0, '2011-09-23 15:55:04.818642', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1811, 0, '2011-09-23 15:55:06.256305', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1812, 0, '2011-09-23 15:55:07.989206', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1813, 0, '2011-09-23 15:55:09.879444', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1814, 0, '2011-09-23 15:55:11.673834', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1815, 0, '2011-09-23 15:55:14.060397', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1816, 0, '2011-09-23 15:55:49.854658', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1817, 0, '2011-09-23 15:55:49.863029', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1818, 0, '2011-09-23 15:55:54.446806', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1819, 0, '2011-09-23 15:55:57.825174', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1820, 0, '2011-09-23 15:55:59.550522', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1821, 0, '2011-09-23 15:56:09.244306', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1822, 0, '2011-09-23 15:56:17.078341', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1823, 0, '2011-09-23 15:56:17.519026', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1824, 0, '2011-09-23 15:56:19.899074', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1825, 0, '2011-09-23 15:56:24.777451', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1826, 0, '2011-09-23 15:56:26.607227', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1827, 0, '2011-09-23 15:56:28.035745', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1828, 0, '2011-09-23 15:56:29.930105', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1829, 0, '2011-09-23 15:56:31.542556', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1830, 0, '2011-09-23 15:56:33.672998', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1831, 0, '2011-09-23 15:56:39.887932', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1832, 0, '2011-09-23 15:56:41.815787', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1833, 0, '2011-09-23 15:58:39.966182', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1834, 0, '2011-09-23 15:58:41.69503', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1835, 0, '2011-09-23 15:58:43.914945', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1836, 0, '2011-09-23 15:58:45.447062', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1837, 0, '2011-09-23 15:58:47.249191', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1845, 0, '2011-09-23 16:01:13.584019', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1846, 0, '2011-09-23 16:01:23.670498', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1847, 0, '2011-09-23 16:01:25.136364', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1848, 0, '2011-09-23 16:01:28.327218', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1849, 0, '2011-09-23 16:01:29.687066', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1850, 0, '2011-09-23 16:01:54.016975', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1851, 0, '2011-09-23 16:01:55.367033', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1852, 0, '2011-09-23 16:02:04.514074', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1853, 0, '2011-09-23 16:11:51.114591', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1861, 0, '2011-09-23 16:20:19.49102', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1862, 0, '2011-09-23 16:20:22.149793', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1863, 0, '2011-09-23 16:20:27.585196', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1864, 0, '2011-09-23 16:20:31.834164', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1865, 0, '2011-09-23 16:20:33.407638', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1866, 0, '2011-09-23 16:20:34.729026', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1867, 0, '2011-09-23 16:20:51.530969', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1868, 0, '2011-09-23 16:20:53.017278', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1869, 0, '2011-09-23 16:20:55.65721', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1870, 0, '2011-09-23 16:20:57.767026', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1871, 0, '2011-09-23 16:20:59.576756', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1872, 0, '2011-09-23 16:21:06.283122', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1873, 0, '2011-09-23 16:21:29.69678', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1874, 0, '2011-09-23 16:21:31.406849', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1875, 0, '2011-09-23 16:21:34.607348', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1876, 0, '2011-09-23 16:21:38.508917', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1877, 0, '2011-09-23 16:24:45.773373', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1878, 0, '2011-09-23 16:24:49.238348', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1879, 0, '2011-09-23 16:24:56.069815', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1880, 0, '2011-09-23 16:25:15.137912', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1881, 0, '2011-09-23 16:25:18.859821', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1882, 0, '2011-09-23 16:26:02.111992', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1883, 0, '2011-09-23 16:26:03.656596', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1884, 0, '2011-09-23 16:26:23.859089', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1885, 0, '2011-09-23 16:26:27.047115', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1886, 0, '2011-09-23 16:26:29.306387', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1887, 0, '2011-09-23 16:26:31.187117', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1888, 0, '2011-09-23 16:26:49.198289', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1889, 0, '2011-09-23 16:27:41.344519', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1890, 0, '2011-09-23 16:27:55.855029', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1891, 0, '2011-09-23 16:27:58.328427', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1892, 0, '2011-09-23 16:28:06.394477', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1893, 0, '2011-09-23 16:28:11.723157', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1894, 0, '2011-09-23 16:28:17.342316', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1895, 0, '2011-09-23 16:28:26.166073', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1896, 0, '2011-09-23 16:28:29.895206', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1897, 0, '2011-09-23 16:29:49.56598', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1898, 0, '2011-09-23 16:29:52.95861', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1899, 0, '2011-09-23 16:29:54.875677', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1900, 0, '2011-09-23 16:30:01.110076', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1901, 0, '2011-09-23 16:30:03.392011', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1902, 0, '2011-09-23 16:30:05.66002', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1903, 0, '2011-09-23 16:30:06.663945', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1904, 0, '2011-09-23 16:30:08.32723', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1905, 0, '2011-09-23 16:30:16.460499', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1906, 0, '2011-09-23 16:30:48.429593', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1907, 0, '2011-09-23 16:30:50.720419', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1908, 0, '2011-09-23 16:31:22.601074', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1909, 0, '2011-09-23 16:31:32.81133', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1910, 0, '2011-09-23 16:31:36.077884', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1911, 0, '2011-09-23 16:31:39.029902', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1912, 0, '2011-09-23 16:31:41.476898', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1913, 0, '2011-09-23 16:31:43.90917', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1914, 0, '2011-09-23 16:32:30.854836', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1915, 0, '2011-09-23 16:32:35.300261', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1916, 0, '2011-09-23 16:32:38.110667', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1917, 0, '2011-09-23 16:32:38.764759', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1918, 0, '2011-09-23 16:32:41.236049', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1919, 0, '2011-09-23 16:32:45.740759', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1920, 0, '2011-09-23 16:32:48.276509', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1921, 0, '2011-09-23 16:32:49.75483', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1922, 0, '2011-09-23 16:32:52.686716', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1923, 0, '2011-09-23 16:33:40.798206', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1924, 0, '2011-09-23 16:33:42.725981', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1925, 0, '2011-09-23 16:33:43.575492', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1926, 0, '2011-09-23 16:33:44.962756', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1927, 0, '2011-09-23 16:33:46.246808', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1928, 0, '2011-09-23 16:34:51.61719', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1929, 0, '2011-09-23 16:34:56.205431', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1930, 0, '2011-09-23 16:34:58.628606', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1931, 0, '2011-09-23 16:34:59.497761', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1932, 0, '2011-09-23 16:35:11.665236', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1933, 0, '2011-09-23 16:35:12.655384', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1934, 0, '2011-09-23 16:35:14.5086', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1935, 0, '2011-09-23 16:35:25.01759', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1936, 0, '2011-09-23 16:35:54.048524', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1838, 0, '2011-09-23 15:58:47.251382', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1839, 0, '2011-09-23 15:58:49.800219', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1840, 0, '2011-09-23 15:58:59.686901', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1841, 0, '2011-09-23 15:59:01.108666', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1842, 0, '2011-09-23 15:59:13.104104', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1843, 0, '2011-09-23 15:59:35.833813', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1844, 0, '2011-09-23 16:01:13.574652', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1854, 0, '2011-09-23 16:11:51.115468', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1855, 0, '2011-09-23 16:11:54.07907', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1856, 0, '2011-09-23 16:12:36.873969', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1857, 0, '2011-09-23 16:20:14.2664', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1858, 0, '2011-09-23 16:20:15.869408', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1859, 0, '2011-09-23 16:20:17.828797', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1860, 0, '2011-09-23 16:20:19.479278', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1937, 0, '2011-09-23 16:38:57.023048', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1938, 0, '2011-09-23 16:38:58.055999', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1939, 0, '2011-09-23 16:38:59.299596', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1940, 0, '2011-09-23 16:39:00.35453', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1941, 0, '2011-09-23 16:39:01.32602', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1942, 0, '2011-09-23 16:39:02.366829', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1943, 0, '2011-09-23 16:39:04.885708', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1944, 0, '2011-09-23 16:39:09.201769', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1945, 0, '2011-09-23 16:39:35.948014', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1946, 0, '2011-09-23 16:39:36.644835', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1947, 0, '2011-09-23 16:39:37.43594', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1948, 0, '2011-09-23 16:39:54.463099', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1949, 0, '2011-09-26 09:08:14.022374', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1950, 0, '2011-09-26 09:08:14.022373', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1951, 0, '2011-09-26 09:08:31.776801', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1952, 0, '2011-09-26 09:08:34.031081', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1953, 0, '2011-09-26 09:12:36.752164', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1954, 0, '2011-09-26 09:13:43.635933', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1955, 0, '2011-09-26 09:13:44.668738', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1956, 0, '2011-09-26 09:13:54.117051', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1957, 0, '2011-09-26 09:16:46.848104', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1958, 0, '2011-09-26 09:16:48.193417', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1959, 0, '2011-09-26 09:16:49.669127', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1960, 0, '2011-09-26 09:26:36.718891', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1961, 0, '2011-09-26 09:38:49.977906', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1962, 0, '2011-09-26 09:38:54.899417', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1963, 0, '2011-09-26 09:38:56.050328', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1964, 0, '2011-09-26 09:39:18.279579', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1965, 0, '2011-09-26 09:41:31.917686', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1966, 0, '2011-09-26 09:41:32.042304', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1967, 0, '2011-09-26 09:44:32.940616', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1968, 0, '2011-09-26 09:44:34.141106', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1969, 0, '2011-09-26 09:44:39.221056', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1970, 0, '2011-09-26 09:44:40.633636', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1971, 0, '2011-09-26 09:44:43.222209', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1972, 0, '2011-09-26 09:44:50.019028', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1973, 0, '2011-09-26 09:44:56.836582', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1974, 0, '2011-09-26 09:44:59.53906', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1975, 0, '2011-09-26 09:45:05.140384', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1976, 0, '2011-09-26 09:45:07.893345', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1977, 0, '2011-09-26 09:45:10.755647', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1978, 0, '2011-09-26 09:45:20.361923', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1979, 0, '2011-09-26 09:45:25.648339', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1980, 0, '2011-09-26 09:45:26.659283', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1981, 0, '2011-09-26 09:45:52.591502', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1982, 0, '2011-09-26 09:45:55.489837', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1983, 0, '2011-09-26 09:59:57.704309', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1984, 0, '2011-09-26 10:02:37.361774', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1985, 0, '2011-09-26 10:02:39.587416', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1986, 0, '2011-09-26 10:02:41.826069', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1987, 0, '2011-09-26 10:02:46.160996', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1988, 0, '2011-09-26 10:03:43.911797', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1989, 0, '2011-09-26 10:03:45.698369', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1990, 0, '2011-09-26 10:03:49.807154', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1991, 0, '2011-09-26 10:03:51.071773', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1992, 0, '2011-09-26 10:03:56.750143', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1993, 0, '2011-09-26 10:04:05.546513', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1994, 0, '2011-09-26 10:04:33.380112', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1995, 0, '2011-09-26 10:04:34.916741', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1996, 0, '2011-09-26 10:04:35.711594', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1997, 0, '2011-09-26 10:04:39.410805', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1998, 0, '2011-09-26 10:04:49.391785', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (1999, 0, '2011-09-26 10:04:51.158494', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2000, 0, '2011-09-26 10:05:05.229481', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2001, 0, '2011-09-26 10:05:06.778566', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2002, 0, '2011-09-26 10:32:38.484936', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2003, 0, '2011-09-26 10:32:39.536371', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2004, 0, '2011-09-26 10:32:40.400445', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2005, 0, '2011-09-26 10:32:41.922091', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2006, 0, '2011-09-26 10:32:44.195366', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2007, 0, '2011-09-26 10:35:34.072065', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2008, 0, '2011-09-26 10:35:35.350965', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2009, 0, '2011-09-26 10:35:36.360445', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2010, 0, '2011-09-26 10:35:37.290009', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2011, 0, '2011-09-26 10:35:42.181682', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2012, 0, '2011-09-26 10:35:42.200588', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2013, 0, '2011-09-26 10:35:44.860761', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2014, 0, '2011-09-26 10:36:45.483749', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2015, 0, '2011-09-26 10:36:45.484414', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2016, 0, '2011-09-26 10:36:47.859582', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2017, 0, '2011-09-26 10:36:49.202529', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2018, 0, '2011-09-26 10:36:50.677855', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2019, 0, '2011-09-26 10:36:53.987769', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2020, 0, '2011-09-26 10:36:55.618502', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2021, 0, '2011-09-26 10:36:57.598077', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2022, 0, '2011-09-26 10:37:00.86795', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2023, 0, '2011-09-26 10:37:02.091944', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2024, 0, '2011-09-26 10:37:02.861763', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2025, 0, '2011-09-26 10:37:03.970828', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2026, 0, '2011-09-26 10:37:06.13852', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2027, 0, '2011-09-26 10:37:11.19679', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2028, 0, '2011-09-26 10:37:12.267465', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2029, 0, '2011-09-26 10:37:13.818835', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2030, 0, '2011-09-26 10:37:27.806798', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2031, 0, '2011-09-26 10:51:21.086802', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2032, 0, '2011-09-26 10:51:21.087496', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2033, 0, '2011-09-26 10:51:23.4099', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2034, 0, '2011-09-26 10:53:19.872742', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2035, 0, '2011-09-26 10:53:21.954963', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2036, 0, '2011-09-26 10:53:24.5088', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2037, 0, '2011-09-26 10:53:26.756924', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2038, 0, '2011-09-26 10:53:29.74194', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2039, 0, '2011-09-26 10:53:32.117805', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2040, 0, '2011-09-26 10:53:33.898761', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2041, 0, '2011-09-26 10:53:35.907885', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2042, 0, '2011-09-26 10:55:21.562052', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2043, 0, '2011-09-26 10:55:23.272412', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2044, 0, '2011-09-26 10:55:26.769775', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2045, 0, '2011-09-26 10:55:28.681256', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2046, 0, '2011-09-26 10:55:31.609687', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2047, 0, '2011-09-26 10:55:34.730697', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2048, 0, '2011-09-26 10:55:37.16587', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2049, 0, '2011-09-26 10:56:06.779309', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2050, 0, '2011-09-26 10:56:08.882004', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2051, 0, '2011-09-26 10:56:10.200898', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2052, 0, '2011-09-26 10:56:12.107732', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2053, 0, '2011-09-26 10:56:14.019099', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2054, 0, '2011-09-26 10:56:16.543693', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2055, 0, '2011-09-26 10:56:18.507978', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2056, 0, '2011-09-26 10:56:20.18982', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2057, 0, '2011-09-26 10:56:58.708694', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2058, 0, '2011-09-26 10:56:59.94774', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2059, 0, '2011-09-26 10:59:37.855555', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2060, 0, '2011-09-26 11:02:59.898797', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2061, 0, '2011-09-26 11:03:04.228857', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2062, 0, '2011-09-26 11:03:05.39213', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2063, 0, '2011-09-26 11:04:33.552097', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2064, 0, '2011-09-26 11:04:34.680703', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2065, 0, '2011-09-26 11:04:36.996536', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2066, 0, '2011-09-26 11:04:41.561055', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2067, 0, '2011-09-26 11:04:44.050508', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2068, 0, '2011-09-26 11:04:46.722217', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2069, 0, '2011-09-26 11:06:40.85714', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2070, 0, '2011-09-26 11:06:45.03739', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2071, 0, '2011-09-26 11:06:48.593891', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2072, 0, '2011-09-26 11:06:50.727155', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2073, 0, '2011-09-26 11:06:53.627656', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2074, 0, '2011-09-26 11:06:54.672567', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2075, 0, '2011-09-26 11:07:01.909841', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2076, 0, '2011-09-26 11:07:04.211593', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2077, 0, '2011-09-26 11:17:16.507363', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2082, 0, '2011-09-26 11:17:36.539221', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2083, 0, '2011-09-26 11:17:38.9892', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2084, 0, '2011-09-26 11:17:40.902176', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2085, 0, '2011-09-26 11:18:10.532785', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2086, 0, '2011-09-26 11:18:12.258592', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2087, 0, '2011-09-26 11:18:12.84072', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2088, 0, '2011-09-26 11:18:41.766671', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2089, 0, '2011-09-26 11:19:28.321935', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2090, 0, '2011-09-26 11:19:29.521758', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2091, 0, '2011-09-26 11:19:41.362128', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2092, 0, '2011-09-26 11:24:21.076787', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2093, 0, '2011-09-26 11:24:22.134272', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2094, 0, '2011-09-26 11:24:25.329673', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2095, 0, '2011-09-26 11:24:26.849918', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2096, 0, '2011-09-26 11:24:28.877912', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2097, 0, '2011-09-26 11:24:31.601125', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2098, 0, '2011-09-26 11:24:34.708592', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2099, 0, '2011-09-26 11:24:41.548463', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2100, 0, '2011-09-26 11:24:44.348407', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2101, 0, '2011-09-26 11:24:45.614637', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2102, 0, '2011-09-26 11:25:06.953776', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2103, 0, '2011-09-26 11:25:08.077416', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2104, 0, '2011-09-26 11:28:31.841259', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2105, 0, '2011-09-26 11:29:02.881945', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2106, 0, '2011-09-26 11:29:10.179173', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2107, 0, '2011-09-26 11:29:11.589302', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2108, 0, '2011-09-26 11:29:12.316546', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2109, 0, '2011-09-26 11:29:19.470665', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2110, 0, '2011-09-26 11:42:41.375628', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2111, 0, '2011-09-26 11:42:42.740365', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2112, 0, '2011-09-26 11:42:45.283206', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2113, 0, '2011-09-26 11:46:28.456868', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2121, 0, '2011-09-26 11:47:32.084161', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2122, 0, '2011-09-26 11:47:33.469722', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2123, 0, '2011-09-26 11:47:39.178166', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2124, 0, '2011-09-26 11:47:56.300899', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2078, 0, '2011-09-26 11:17:16.525363', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2079, 0, '2011-09-26 11:17:18.876662', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2080, 0, '2011-09-26 11:17:34.11789', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2081, 0, '2011-09-26 11:17:36.530576', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2114, 0, '2011-09-26 11:46:28.467146', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2115, 0, '2011-09-26 11:46:31.157276', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2116, 0, '2011-09-26 11:46:33.568821', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2117, 0, '2011-09-26 11:46:34.915023', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2118, 0, '2011-09-26 11:46:36.489849', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2119, 0, '2011-09-26 11:46:39.564109', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2120, 0, '2011-09-26 11:46:44.148308', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2125, 0, '2011-09-26 11:47:58.839872', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2126, 0, '2011-09-26 11:48:00.591295', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2127, 0, '2011-09-26 11:48:02.477205', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2128, 0, '2011-09-26 11:48:03.520759', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2129, 0, '2011-09-26 11:48:05.05175', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2130, 0, '2011-09-26 11:48:06.373408', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2131, 0, '2011-09-26 11:48:12.871073', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2132, 0, '2011-09-26 11:48:16.708497', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2133, 0, '2011-09-26 11:48:17.75201', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2134, 0, '2011-09-26 11:48:24.450781', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2135, 0, '2011-09-26 11:48:29.037346', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2136, 0, '2011-09-26 11:48:42.429273', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2137, 0, '2011-09-26 11:48:43.727372', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2138, 0, '2011-09-26 11:48:45.376107', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2139, 0, '2011-09-26 11:48:49.521607', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2140, 0, '2011-09-26 11:48:54.795839', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2141, 0, '2011-09-26 11:49:02.650487', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2142, 0, '2011-09-26 11:50:32.117111', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2143, 0, '2011-09-26 11:50:32.140335', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2144, 0, '2011-09-26 11:50:34.666872', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2145, 0, '2011-09-26 11:50:54.017671', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2146, 0, '2011-09-26 11:50:55.629878', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2147, 0, '2011-09-26 11:51:00.509515', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2148, 0, '2011-09-26 11:51:02.601701', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2149, 0, '2011-09-26 11:51:19.337763', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2150, 0, '2011-09-26 11:51:22.22801', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2151, 0, '2011-09-26 11:51:29.828888', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2152, 0, '2011-09-26 11:51:31.531708', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2153, 0, '2011-09-26 11:51:33.610139', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2154, 0, '2011-09-26 11:51:35.194792', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2155, 0, '2011-09-26 11:51:38.397478', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2156, 0, '2011-09-26 11:51:47.06858', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2157, 0, '2011-09-26 11:52:06.300133', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2158, 0, '2011-09-26 11:52:07.650588', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2159, 0, '2011-09-26 11:52:09.40082', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2160, 0, '2011-09-26 11:52:10.33495', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2161, 0, '2011-09-26 11:52:12.117865', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2162, 0, '2011-09-26 11:52:14.108388', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2163, 0, '2011-09-26 11:52:16.650503', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2164, 0, '2011-09-26 11:52:19.916437', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2165, 0, '2011-09-26 11:52:24.584155', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2166, 0, '2011-09-27 12:24:47.451186', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2167, 0, '2011-09-27 12:24:47.454428', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2168, 0, '2011-09-27 12:24:51.444317', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2169, 0, '2011-09-27 12:24:54.312681', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2170, 0, '2011-09-27 12:25:05.569384', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2171, 0, '2011-09-27 12:25:23.405837', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2172, 0, '2011-09-27 12:25:25.905728', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2173, 0, '2011-09-27 12:25:32.840337', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2174, 0, '2011-09-27 12:25:36.628133', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2175, 0, '2011-09-27 12:25:39.009688', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2176, 0, '2011-09-27 12:25:42.699149', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2177, 0, '2011-09-27 12:25:46.775521', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2178, 0, '2011-09-27 12:26:06.316694', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2179, 0, '2011-09-27 12:26:06.324426', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2180, 0, '2011-09-27 12:26:13.3822', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2181, 0, '2011-09-27 12:26:20.485725', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2182, 0, '2011-09-27 12:26:28.338436', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2183, 0, '2011-09-28 08:47:48.554553', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2184, 0, '2011-09-28 08:47:48.550093', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2185, 0, '2011-09-28 08:47:51.520699', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2186, 0, '2011-09-28 08:47:52.867441', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2187, 0, '2011-09-28 08:49:51.221687', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2188, 0, '2011-09-28 08:49:51.24912', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2189, 0, '2011-09-28 08:49:55.208877', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2190, 0, '2011-09-28 08:49:56.608494', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2191, 0, '2011-09-28 08:50:05.874068', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2192, 0, '2011-09-28 08:58:24.777368', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2193, 0, '2011-09-28 08:58:28.937893', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2194, 0, '2011-09-28 08:58:31.611026', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2195, 0, '2011-09-28 08:58:37.059669', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2196, 0, '2011-09-28 08:58:58.758886', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2197, 0, '2011-09-28 08:59:02.579398', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2198, 0, '2011-09-28 09:01:15.278893', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2199, 0, '2011-09-28 09:01:17.270409', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2200, 0, '2011-09-28 09:01:56.174298', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2201, 0, '2011-09-28 09:01:57.870791', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2202, 0, '2011-09-28 09:01:59.579541', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2203, 0, '2011-09-28 09:02:01.060133', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2204, 0, '2011-09-28 09:02:06.45411', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2205, 0, '2011-09-28 09:02:08.293386', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2206, 0, '2011-09-28 09:02:14.897996', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2207, 0, '2011-09-28 09:02:19.948492', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2208, 0, '2011-09-28 09:02:28.40265', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2209, 0, '2011-09-28 09:02:30.913203', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2210, 0, '2011-09-28 09:04:08.915682', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2211, 0, '2011-09-28 09:04:08.917775', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2212, 0, '2011-09-28 09:04:11.761378', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2213, 0, '2011-09-28 09:04:13.711374', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2214, 0, '2011-09-28 09:04:16.241668', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2215, 0, '2011-09-28 09:04:19.531152', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2216, 0, '2011-09-28 09:04:47.599288', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2217, 0, '2011-09-28 09:04:48.553992', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2218, 0, '2011-09-28 09:04:50.424388', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2219, 0, '2011-09-28 09:06:23.214531', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2220, 0, '2011-09-28 09:06:41.437161', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2221, 0, '2011-09-28 09:06:42.663074', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2222, 0, '2011-09-28 09:06:44.140337', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2223, 0, '2011-09-28 09:07:27.014595', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2224, 0, '2011-09-28 09:07:29.017454', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2225, 0, '2011-09-28 09:07:43.30772', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2226, 0, '2011-09-28 09:07:52.115205', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2227, 0, '2011-09-28 09:08:11.714476', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2228, 0, '2011-09-28 09:08:13.833651', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2229, 0, '2011-09-28 09:08:16.18652', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2230, 0, '2011-09-28 09:08:21.633748', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2231, 0, '2011-09-28 09:12:31.993756', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2232, 0, '2011-09-28 09:18:57.868596', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2233, 0, '2011-09-28 09:18:59.337699', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2234, 0, '2011-09-28 09:19:00.930797', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2235, 0, '2011-09-28 09:19:02.349753', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2236, 0, '2011-09-28 09:19:55.074323', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2237, 0, '2011-09-28 09:19:57.261207', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2238, 0, '2011-09-28 09:24:08.864723', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2239, 0, '2011-09-28 09:24:08.875043', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2240, 0, '2011-09-28 09:24:11.875989', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2241, 0, '2011-09-28 09:24:13.891069', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2242, 0, '2011-09-28 09:24:15.801564', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2243, 0, '2011-09-28 09:24:17.107319', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2244, 0, '2011-09-28 09:24:18.153451', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2245, 0, '2011-09-28 09:24:19.410779', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2246, 0, '2011-09-28 09:24:20.582983', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2247, 0, '2011-09-28 09:24:21.696665', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2248, 0, '2011-09-28 09:25:53.501614', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2249, 0, '2011-09-28 09:25:54.784787', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2250, 0, '2011-09-28 09:29:12.048104', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2251, 0, '2011-09-28 09:29:13.331181', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2252, 0, '2011-09-28 09:29:15.330925', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2253, 0, '2011-09-28 09:29:16.339954', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2254, 0, '2011-09-28 09:29:17.934746', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2255, 0, '2011-09-28 09:29:26.501168', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2256, 0, '2011-09-28 09:29:35.930838', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2257, 0, '2011-09-28 09:29:38.971372', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2258, 0, '2011-09-28 09:29:42.259984', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2259, 0, '2011-09-28 09:29:44.004513', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2260, 0, '2011-09-28 09:29:46.810842', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2261, 0, '2011-09-28 09:29:48.512829', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2262, 0, '2011-09-28 09:29:51.22023', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2263, 0, '2011-09-28 09:29:52.854434', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2264, 0, '2011-09-28 09:29:55.41053', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2265, 0, '2011-09-28 09:29:57.341258', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2266, 0, '2011-09-28 09:29:59.055112', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2267, 0, '2011-09-28 09:30:02.95939', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2268, 0, '2011-09-28 09:30:07.582416', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2269, 0, '2011-09-28 09:30:10.39276', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2270, 0, '2011-09-28 09:30:12.184975', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2271, 0, '2011-09-28 09:33:27.379621', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2273, 0, '2011-09-28 09:33:48.778894', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2272, 0, '2011-09-28 09:33:48.778888', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2274, 0, '2011-09-28 09:33:51.640928', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2275, 0, '2011-09-28 09:33:52.905781', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2276, 0, '2011-09-28 09:33:54.292761', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2277, 0, '2011-09-28 09:33:55.495421', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2278, 0, '2011-09-28 09:33:56.832746', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2279, 0, '2011-09-28 09:35:40.241044', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2280, 0, '2011-09-28 09:35:42.331569', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2281, 0, '2011-09-28 09:38:02.861308', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2282, 0, '2011-09-28 09:38:05.688349', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2283, 0, '2011-09-28 09:38:14.498633', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2284, 0, '2011-09-28 09:38:15.587561', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2285, 0, '2011-09-28 09:39:21.210573', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2286, 0, '2011-09-28 09:39:24.035604', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2287, 0, '2011-09-28 09:47:30.824352', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2288, 0, '2011-09-28 12:41:57.844073', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2289, 0, '2011-09-28 12:41:57.861003', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2290, 0, '2011-09-28 12:42:02.641392', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2291, 0, '2011-09-28 12:42:05.726286', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2292, 0, '2011-09-28 12:45:54.187666', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2293, 0, '2011-09-28 12:45:56.784223', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2294, 0, '2011-09-28 12:46:06.381456', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2295, 0, '2011-09-28 12:46:11.913466', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2296, 0, '2011-09-28 12:46:12.982412', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2297, 0, '2011-09-28 12:46:15.55713', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2298, 0, '2011-09-28 12:46:18.486662', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2299, 0, '2011-09-28 12:46:19.99391', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2300, 0, '2011-09-28 12:46:22.46605', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2301, 0, '2011-09-28 12:46:25.003412', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2302, 0, '2011-09-28 12:46:26.260335', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2303, 0, '2011-09-28 12:46:29.491806', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2304, 0, '2011-09-28 12:46:32.267928', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2305, 0, '2011-09-28 12:46:36.127881', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2306, 0, '2011-09-28 12:46:42.098443', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2307, 0, '2011-09-28 12:46:44.018802', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2308, 0, '2011-09-28 12:46:45.103155', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2309, 0, '2011-09-28 12:46:50.073498', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2310, 0, '2011-09-28 12:46:58.037583', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2311, 0, '2011-09-28 12:46:59.520971', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2312, 0, '2011-09-28 12:48:09.166576', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2313, 0, '2011-09-28 12:50:10.872981', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2314, 0, '2011-09-28 12:50:26.376068', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2315, 0, '2011-09-28 12:50:29.94899', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2316, 0, '2011-09-28 12:52:21.785748', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2317, 0, '2011-09-28 13:06:57.811999', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2318, 0, '2011-09-28 13:06:59.022367', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2320, 0, '2011-09-29 14:37:55.833681', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2319, 0, '2011-09-29 14:37:55.879573', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2321, 0, '2011-09-29 14:37:59.553131', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2322, 0, '2011-09-29 14:38:00.736777', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2323, 0, '2011-09-29 14:38:04.058928', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2324, 0, '2011-09-29 14:38:05.462364', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2325, 0, '2011-09-29 14:38:09.346876', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2326, 0, '2011-09-29 14:56:17.787447', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2327, 0, '2011-09-29 14:56:17.850732', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2328, 0, '2011-09-29 14:56:20.368105', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2329, 0, '2011-09-29 14:56:50.527957', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2330, 0, '2011-09-29 14:56:50.532392', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2331, 0, '2011-09-29 14:56:54.121261', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2332, 0, '2011-09-29 15:22:37.969866', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2333, 0, '2011-09-29 15:22:37.974234', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2334, 0, '2011-09-29 15:27:50.84774', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2335, 0, '2011-09-29 15:27:50.856867', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2336, 0, '2011-09-29 15:27:53.296956', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2337, 0, '2011-09-29 15:27:54.534918', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2338, 0, '2011-09-29 15:27:55.995992', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2339, 0, '2011-09-29 15:28:01.629163', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2340, 0, '2011-09-29 15:28:03.221743', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2341, 0, '2011-09-29 15:28:05.262528', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2342, 0, '2011-09-29 15:28:07.097795', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2343, 0, '2011-09-29 15:28:09.336919', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2344, 0, '2011-09-29 15:28:10.612875', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2345, 0, '2011-09-29 15:28:13.954693', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2346, 0, '2011-09-29 15:52:49.407661', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2347, 0, '2011-09-29 15:52:49.411716', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2348, 0, '2011-09-29 15:52:51.97711', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2349, 0, '2011-09-29 15:52:52.76942', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2350, 0, '2011-09-29 15:52:53.829723', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2351, 0, '2011-09-29 15:52:54.969996', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2352, 0, '2011-09-29 15:52:56.393305', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2353, 0, '2011-09-29 15:53:00.2224', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2354, 0, '2011-09-29 15:53:04.524199', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2355, 0, '2011-09-29 15:53:05.840102', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2356, 0, '2011-09-29 15:53:07.258644', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2357, 0, '2011-09-29 15:54:09.024421', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2358, 0, '2011-09-29 15:54:10.620692', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2359, 0, '2011-09-29 15:54:14.218378', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2361, 0, '2011-09-30 09:48:27.739602', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2360, 0, '2011-09-30 09:48:27.738883', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2362, 0, '2011-09-30 09:48:34.571798', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2363, 0, '2011-09-30 09:48:35.963917', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2364, 0, '2011-09-30 09:50:38.565836', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2365, 0, '2011-09-30 09:50:48.641123', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2366, 0, '2011-09-30 09:50:54.543772', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2367, 0, '2011-09-30 09:51:03.132655', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2368, 0, '2011-09-30 09:51:20.991698', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2369, 0, '2011-09-30 09:51:39.60248', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2370, 0, '2011-09-30 09:51:42.957154', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2371, 0, '2011-09-30 09:54:22.738492', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2372, 0, '2011-09-30 09:54:37.27175', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2373, 0, '2011-09-30 09:54:46.005058', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2374, 0, '2011-09-30 09:55:14.447439', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2375, 0, '2011-09-30 09:55:21.294927', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2376, 0, '2011-09-30 09:55:29.759105', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2377, 0, '2011-09-30 09:55:32.400447', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2378, 0, '2011-09-30 09:55:35.120128', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2379, 0, '2011-09-30 09:55:43.257286', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2380, 0, '2011-09-30 09:55:49.576456', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2381, 0, '2011-09-30 09:55:53.159075', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2382, 0, '2011-09-30 09:56:27.226377', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2383, 0, '2011-09-30 10:00:44.971849', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2384, 0, '2011-09-30 10:00:46.687496', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2385, 0, '2011-09-30 10:00:49.527776', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2386, 0, '2011-09-30 10:08:50.372038', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2387, 0, '2011-09-30 10:08:53.278451', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2388, 0, '2011-09-30 10:12:25.541468', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2389, 0, '2011-09-30 10:12:30.768603', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2390, 0, '2011-09-30 10:12:37.829718', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2391, 0, '2011-09-30 10:16:27.226903', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2392, 0, '2011-09-30 10:17:46.541317', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2393, 0, '2011-09-30 10:23:54.273819', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2394, 0, '2011-09-30 10:24:04.101927', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2395, 0, '2011-09-30 10:24:08.133773', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2396, 0, '2011-09-30 10:24:14.838412', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2397, 0, '2011-09-30 10:24:16.029789', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2398, 0, '2011-09-30 10:26:34.230707', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2399, 0, '2011-09-30 10:26:38.239834', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2400, 0, '2011-09-30 10:26:45.279021', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2401, 0, '2011-09-30 10:26:58.740924', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2402, 0, '2011-09-30 10:27:11.661481', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2403, 0, '2011-09-30 10:27:59.639035', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2404, 0, '2011-09-30 10:28:31.291901', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2405, 0, '2011-09-30 10:28:59.617347', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2406, 0, '2011-09-30 10:29:09.891574', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2407, 0, '2011-09-30 10:29:17.137397', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2408, 0, '2011-09-30 10:29:35.510376', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2409, 0, '2011-09-30 10:29:38.67843', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2410, 0, '2011-09-30 10:29:40.959075', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2411, 0, '2011-09-30 10:29:45.1262', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2412, 0, '2011-09-30 10:31:27.088314', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2413, 0, '2011-09-30 10:32:02.325905', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2414, 0, '2011-09-30 10:32:05.687865', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2415, 0, '2011-09-30 10:33:31.03037', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2416, 0, '2011-09-30 10:33:34.221258', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2417, 0, '2011-09-30 10:35:47.27645', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2418, 0, '2011-09-30 10:35:47.990302', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2419, 0, '2011-09-30 10:39:52.858104', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2420, 0, '2011-09-30 10:39:56.52811', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2421, 0, '2011-09-30 10:40:04.559512', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2422, 0, '2011-09-30 10:40:06.769744', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2423, 0, '2011-09-30 10:40:09.409015', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2424, 0, '2011-09-30 10:40:15.541026', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2425, 0, '2011-09-30 10:40:17.818568', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2426, 0, '2011-09-30 10:40:19.261423', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2427, 0, '2011-09-30 10:40:21.719155', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2428, 0, '2011-09-30 10:40:24.955565', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2429, 0, '2011-09-30 10:40:33.540715', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2430, 0, '2011-09-30 10:40:34.571263', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2431, 0, '2011-09-30 10:41:04.581892', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2432, 0, '2011-09-30 10:41:07.230051', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2433, 0, '2011-09-30 10:41:09.630558', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2434, 0, '2011-09-30 11:17:38.787801', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2435, 0, '2011-09-30 11:17:42.387004', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2436, 0, '2011-09-30 11:17:44.857426', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2437, 0, '2011-09-30 11:17:46.439557', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2438, 0, '2011-09-30 11:22:05.146496', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2439, 0, '2011-09-30 11:22:12.960671', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2440, 0, '2011-09-30 11:22:14.51057', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2441, 0, '2011-09-30 11:22:37.012198', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2442, 0, '2011-09-30 11:22:45.919558', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2443, 0, '2011-09-30 11:22:57.310217', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2444, 0, '2011-09-30 11:23:01.06365', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2445, 0, '2011-09-30 11:23:05.657965', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2446, 0, '2011-09-30 11:23:14.256187', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2447, 0, '2011-09-30 11:23:20.630626', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2448, 0, '2011-09-30 11:23:37.091944', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2449, 0, '2011-09-30 11:23:41.465893', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2450, 0, '2011-09-30 11:23:42.297639', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2451, 0, '2011-09-30 11:23:45.888484', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2452, 0, '2011-09-30 11:23:47.420953', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2453, 0, '2011-09-30 11:23:55.878875', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2454, 0, '2011-09-30 11:52:28.634716', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2455, 0, '2011-09-30 11:52:39.175433', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2456, 0, '2011-09-30 11:52:45.296651', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2457, 0, '2011-09-30 11:52:48.437258', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2458, 0, '2011-09-30 11:52:50.231256', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2459, 0, '2011-09-30 11:52:53.048738', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2460, 0, '2011-09-30 11:52:57.871168', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2461, 0, '2011-09-30 11:53:00.122065', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2462, 0, '2011-09-30 11:53:03.324736', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2463, 0, '2011-09-30 11:53:10.284694', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2464, 0, '2011-09-30 11:53:11.759822', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2465, 0, '2011-09-30 11:53:43.578668', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2466, 0, '2011-09-30 11:53:48.510626', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2467, 0, '2011-09-30 11:54:20.016816', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2468, 0, '2011-09-30 11:54:23.357013', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2469, 0, '2011-09-30 12:01:09.497067', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2470, 0, '2011-09-30 12:01:11.302434', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2471, 0, '2011-09-30 12:01:13.903298', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2472, 0, '2011-09-30 12:01:17.647394', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2473, 0, '2011-09-30 12:03:13.978339', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2474, 0, '2011-09-30 12:03:16.537275', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2475, 0, '2011-09-30 12:03:30.293309', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2476, 0, '2011-09-30 12:03:32.191386', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2477, 0, '2011-09-30 12:03:51.577441', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2478, 0, '2011-09-30 12:03:54.897206', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2479, 0, '2011-09-30 12:03:59.828964', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2480, 0, '2011-09-30 12:04:03.662862', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2481, 0, '2011-09-30 12:04:35.542346', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2482, 0, '2011-09-30 12:04:41.445085', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2483, 0, '2011-09-30 12:04:43.356933', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2484, 0, '2011-09-30 12:04:48.430979', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2485, 0, '2011-09-30 12:05:27.618614', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2486, 0, '2011-09-30 12:05:28.981626', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2487, 0, '2011-09-30 12:05:43.812901', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2488, 0, '2011-09-30 12:06:24.103097', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2489, 0, '2011-09-30 12:06:26.187582', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2490, 0, '2011-09-30 12:06:28.833959', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2491, 0, '2011-09-30 12:06:42.895217', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2492, 0, '2011-09-30 12:07:37.327622', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2493, 0, '2011-09-30 12:09:25.389627', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2494, 0, '2011-09-30 12:09:27.102507', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2495, 0, '2011-09-30 12:09:33.564679', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2496, 0, '2011-09-30 12:10:53.658352', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2497, 0, '2011-09-30 12:12:14.086713', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2498, 0, '2011-09-30 12:12:15.378069', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2499, 0, '2011-09-30 12:12:20.457487', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2500, 0, '2011-09-30 12:18:01.446116', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2501, 0, '2011-09-30 12:18:12.841086', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2502, 0, '2011-09-30 12:18:14.845333', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2503, 0, '2011-09-30 12:18:25.35006', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2504, 0, '2011-09-30 12:18:30.530348', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2505, 0, '2011-09-30 12:18:35.561063', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2506, 0, '2011-09-30 12:19:35.782897', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2507, 0, '2011-09-30 12:19:37.599484', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2508, 0, '2011-09-30 12:19:40.941133', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2509, 0, '2011-09-30 12:19:43.200392', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2510, 0, '2011-09-30 12:19:48.617254', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2511, 0, '2011-09-30 12:19:50.816844', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2512, 0, '2011-09-30 12:19:54.092628', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2513, 0, '2011-09-30 12:28:17.953964', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2514, 0, '2011-09-30 12:28:19.181074', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2515, 0, '2011-09-30 12:28:48.413459', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2516, 0, '2011-09-30 12:28:50.817363', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2517, 0, '2011-09-30 12:28:52.313898', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2518, 0, '2011-09-30 12:29:02.6368', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2519, 0, '2011-09-30 12:29:30.154683', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2520, 0, '2011-09-30 12:29:32.5231', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2521, 0, '2011-09-30 12:29:37.617948', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2522, 0, '2011-09-30 12:29:39.882351', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2523, 0, '2011-09-30 12:29:43.652641', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2524, 0, '2011-09-30 12:29:57.607688', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2525, 0, '2011-09-30 12:29:59.031941', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2526, 0, '2011-09-30 12:30:14.818574', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2527, 0, '2011-09-30 12:31:04.760692', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2528, 0, '2011-09-30 12:32:00.725054', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2529, 0, '2011-09-30 12:32:02.927963', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2530, 0, '2011-09-30 12:32:04.852678', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2531, 0, '2011-09-30 12:32:13.532141', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2532, 0, '2011-09-30 12:32:16.33054', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2533, 0, '2011-09-30 12:35:06.200581', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2534, 0, '2011-09-30 12:35:08.470871', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2535, 0, '2011-09-30 12:35:16.409018', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2536, 0, '2011-09-30 12:35:21.457706', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2537, 0, '2011-09-30 12:35:28.747143', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2538, 0, '2011-09-30 12:35:30.422031', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2539, 0, '2011-09-30 12:35:34.64883', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2540, 0, '2011-09-30 12:35:39.297626', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2541, 0, '2011-09-30 12:35:40.829018', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2542, 0, '2011-09-30 12:42:11.969214', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2543, 0, '2011-09-30 12:42:15.368321', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2544, 0, '2011-09-30 12:42:17.169323', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2545, 0, '2011-09-30 12:42:34.068142', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2546, 0, '2011-09-30 12:42:41.843679', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2547, 0, '2011-09-30 12:42:57.377478', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2548, 0, '2011-09-30 12:43:00.301622', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2549, 0, '2011-09-30 12:43:30.911385', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2550, 0, '2011-09-30 12:43:42.65238', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2551, 0, '2011-09-30 12:43:48.278506', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2552, 0, '2011-09-30 12:43:51.009313', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2553, 0, '2011-09-30 12:44:01.827342', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2554, 0, '2011-09-30 12:44:08.048627', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2555, 0, '2011-09-30 12:44:10.920342', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2556, 0, '2011-09-30 12:44:13.471295', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2557, 0, '2011-09-30 12:44:14.890429', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2558, 0, '2011-09-30 12:44:20.898333', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2559, 0, '2011-09-30 12:44:55.471781', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2560, 0, '2011-09-30 12:44:59.394826', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2561, 0, '2011-09-30 12:45:01.915592', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2562, 0, '2011-09-30 12:45:19.764032', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2563, 0, '2011-09-30 12:45:23.216419', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2564, 0, '2011-09-30 12:45:28.605401', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2565, 0, '2011-09-30 12:45:31.097313', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2566, 0, '2011-09-30 12:45:33.410297', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2567, 0, '2011-09-30 12:45:35.707174', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2568, 0, '2011-09-30 12:45:40.62503', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2569, 0, '2011-09-30 12:45:47.777526', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2570, 0, '2011-09-30 12:45:52.157595', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2571, 0, '2011-09-30 12:46:12.337646', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2572, 0, '2011-09-30 14:58:45.623378', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2573, 0, '2011-09-30 14:58:45.632069', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2574, 0, '2011-09-30 14:58:49.489199', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2575, 0, '2011-09-30 14:58:55.177151', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2576, 0, '2011-09-30 14:58:58.779887', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2577, 0, '2011-09-30 14:59:04.94717', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2578, 0, '2011-09-30 14:59:17.189897', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2579, 0, '2011-09-30 14:59:20.478639', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2580, 0, '2011-09-30 14:59:22.209885', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2581, 0, '2011-09-30 14:59:27.22042', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2582, 0, '2011-09-30 14:59:29.147757', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2583, 0, '2011-09-30 14:59:30.565957', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2584, 0, '2011-09-30 14:59:49.351688', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2585, 0, '2011-09-30 14:59:54.890504', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2586, 0, '2011-09-30 15:00:00.308329', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2587, 0, '2011-09-30 15:00:04.25671', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2588, 0, '2011-09-30 15:00:09.866887', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2589, 0, '2011-09-30 15:00:51.035276', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2590, 0, '2011-09-30 15:00:59.448866', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2591, 0, '2011-09-30 15:01:02.409214', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2592, 0, '2011-09-30 15:01:03.509334', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2593, 0, '2011-09-30 15:01:09.124991', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2594, 0, '2011-09-30 15:01:09.79937', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2595, 0, '2011-09-30 15:01:11.295817', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2596, 0, '2011-09-30 15:01:19.096331', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2597, 0, '2011-09-30 15:03:10.874879', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2598, 0, '2011-09-30 15:03:18.94544', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2599, 0, '2011-09-30 15:04:34.371785', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2600, 0, '2011-09-30 15:04:36.239888', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2601, 0, '2011-09-30 15:04:38.542762', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2602, 0, '2011-09-30 15:04:51.000723', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2603, 0, '2011-09-30 15:05:55.559961', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2604, 0, '2011-09-30 15:05:59.82144', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2605, 0, '2011-09-30 15:06:00.78794', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2606, 0, '2011-09-30 15:06:06.189018', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2607, 0, '2011-09-30 15:07:18.45589', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2608, 0, '2011-09-30 15:07:29.587799', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2609, 0, '2011-09-30 15:07:31.099417', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2610, 0, '2011-09-30 15:07:33.325539', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2611, 0, '2011-09-30 15:07:38.045348', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2612, 0, '2011-09-30 15:08:53.830719', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2613, 0, '2011-09-30 15:08:55.402522', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2614, 0, '2011-09-30 15:10:18.111104', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2615, 0, '2011-09-30 15:13:57.045624', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2616, 0, '2011-09-30 15:13:58.421782', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2617, 0, '2011-09-30 15:13:59.635809', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2618, 0, '2011-09-30 15:14:00.689206', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2619, 0, '2011-09-30 15:14:02.549214', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2620, 0, '2011-09-30 15:14:03.692899', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2621, 0, '2011-09-30 15:14:05.088831', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2622, 0, '2011-09-30 15:14:15.898819', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2623, 0, '2011-09-30 15:14:17.298207', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2624, 0, '2011-09-30 15:14:34.277081', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2625, 0, '2011-09-30 15:14:37.578642', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2626, 0, '2011-09-30 15:14:50.572483', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2627, 0, '2011-09-30 15:14:52.951264', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2628, 0, '2011-09-30 15:14:56.027832', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2629, 0, '2011-09-30 15:14:58.680712', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2630, 0, '2011-09-30 15:15:01.236028', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2631, 0, '2011-09-30 15:15:02.827328', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2632, 0, '2011-09-30 15:15:23.032662', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2633, 0, '2011-09-30 15:15:26.27057', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2634, 0, '2011-09-30 15:15:35.930021', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2635, 0, '2011-09-30 15:15:37.022166', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2636, 0, '2011-09-30 15:16:16.23677', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2637, 0, '2011-09-30 15:16:18.861407', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2638, 0, '2011-09-30 15:16:20.942012', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2639, 0, '2011-09-30 15:16:26.044044', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2640, 0, '2011-09-30 15:16:30.29516', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2641, 0, '2011-09-30 15:16:36.779172', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2642, 0, '2011-09-30 15:16:40.569707', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2643, 0, '2011-09-30 15:16:44.409456', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2644, 0, '2011-09-30 15:16:45.032136', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2645, 0, '2011-09-30 15:16:46.058521', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2646, 0, '2011-09-30 15:16:53.297974', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2647, 0, '2011-09-30 15:16:57.360674', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2648, 0, '2011-09-30 15:17:00.711109', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2649, 0, '2011-09-30 15:17:03.954559', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2650, 0, '2011-09-30 15:17:07.987359', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2651, 0, '2011-09-30 15:17:09.458598', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2652, 0, '2011-09-30 15:17:10.880041', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2653, 0, '2011-09-30 15:17:13.622346', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2654, 0, '2011-09-30 15:17:18.000366', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2655, 0, '2011-09-30 15:17:20.255517', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2656, 0, '2011-09-30 15:17:26.418508', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2657, 0, '2011-09-30 15:17:29.924897', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2658, 0, '2011-09-30 15:17:33.040921', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2659, 0, '2011-09-30 15:17:35.022314', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2660, 0, '2011-09-30 15:17:37.230176', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2661, 0, '2011-09-30 15:18:04.964121', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2662, 0, '2011-09-30 15:18:20.404026', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2663, 0, '2011-09-30 15:18:27.320898', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2664, 0, '2011-09-30 15:19:02.609579', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2665, 0, '2011-09-30 15:19:12.440105', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2666, 0, '2011-09-30 15:19:24.711135', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2667, 0, '2011-09-30 15:20:28.12945', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2668, 0, '2011-09-30 15:20:56.387808', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2669, 0, '2011-09-30 15:21:16.994919', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2670, 0, '2011-09-30 15:21:45.351369', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2671, 0, '2011-09-30 15:22:10.707306', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2672, 0, '2011-09-30 15:22:12.226721', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2673, 0, '2011-09-30 15:22:21.360725', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2674, 0, '2011-09-30 15:22:26.147216', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2675, 0, '2011-09-30 15:22:27.551221', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2676, 0, '2011-09-30 15:22:31.937015', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2677, 0, '2011-09-30 15:22:38.455199', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2678, 0, '2011-09-30 15:22:41.449435', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2679, 0, '2011-09-30 15:22:45.478595', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2680, 0, '2011-09-30 15:22:46.938024', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2681, 0, '2011-09-30 15:22:49.353479', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2682, 0, '2011-09-30 15:22:51.381966', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2683, 0, '2011-09-30 15:22:57.231434', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2684, 0, '2011-09-30 15:23:01.147215', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2685, 0, '2011-09-30 15:23:07.805755', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2686, 0, '2011-09-30 15:23:09.249326', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2687, 0, '2011-09-30 15:23:11.030877', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2688, 0, '2011-09-30 15:23:38.787917', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2689, 0, '2011-09-30 15:26:47.366377', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2690, 0, '2011-09-30 15:26:49.630826', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2691, 0, '2011-09-30 15:26:54.173969', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2692, 0, '2011-09-30 15:26:57.154357', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2693, 0, '2011-09-30 15:27:14.907191', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2694, 0, '2011-09-30 15:27:16.71522', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2695, 0, '2011-09-30 15:27:18.177968', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2696, 0, '2011-09-30 15:27:20.95603', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2697, 0, '2011-09-30 15:40:43.508087', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2698, 0, '2011-09-30 15:40:46.162263', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2699, 0, '2011-09-30 15:40:50.129802', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2700, 0, '2011-09-30 15:52:34.685782', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2701, 0, '2011-09-30 15:52:37.658367', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2702, 0, '2011-09-30 15:52:46.533483', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2703, 0, '2011-09-30 15:53:10.425713', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2704, 0, '2011-09-30 15:53:13.011183', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2705, 0, '2011-09-30 15:53:19.909691', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2706, 0, '2011-09-30 15:53:23.058038', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2707, 0, '2011-09-30 15:53:28.66', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2708, 0, '2011-09-30 15:53:29.673485', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2709, 0, '2011-09-30 15:53:30.901612', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2710, 0, '2011-09-30 15:53:31.956298', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2711, 0, '2011-09-30 15:53:52.66835', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2712, 0, '2011-09-30 15:53:54.185924', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2713, 0, '2011-09-30 15:55:07.794727', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2714, 0, '2011-09-30 15:55:24.938732', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2715, 0, '2011-09-30 15:55:41.127285', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2716, 0, '2011-09-30 15:55:47.250455', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2717, 0, '2011-09-30 16:23:17.495132', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2718, 0, '2011-09-30 16:23:19.587709', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2719, 0, '2011-09-30 16:23:25.628502', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2720, 0, '2011-09-30 16:23:26.664029', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2721, 0, '2011-09-30 16:23:46.741752', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2722, 0, '2011-09-30 16:23:50.676172', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2723, 0, '2011-09-30 16:23:51.569166', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2724, 0, '2011-09-30 16:24:07.916563', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2725, 0, '2011-09-30 16:24:09.449621', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2726, 0, '2011-09-30 16:24:28.447084', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2727, 0, '2011-09-30 16:24:29.880869', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2728, 0, '2011-09-30 16:24:39.527052', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2729, 0, '2011-09-30 16:24:53.231646', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2730, 0, '2011-09-30 16:25:35.459376', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2731, 0, '2011-09-30 16:25:36.855004', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2732, 0, '2011-09-30 16:25:42.979908', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2733, 0, '2011-09-30 16:26:03.135302', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2734, 0, '2011-09-30 16:26:05.587609', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2735, 0, '2011-09-30 16:26:56.998953', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2736, 0, '2011-09-30 16:27:04.198784', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2737, 0, '2011-09-30 16:27:10.611063', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2738, 0, '2011-09-30 16:27:13.689363', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2739, 0, '2011-09-30 16:27:21.710928', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2740, 0, '2011-09-30 16:27:27.893632', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2741, 0, '2011-09-30 16:27:36.988192', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2742, 0, '2011-09-30 16:27:41.290196', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2743, 0, '2011-09-30 16:28:29.344032', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2744, 0, '2011-09-30 16:28:44.472055', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2745, 0, '2011-09-30 16:28:59.859493', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2746, 0, '2011-09-30 16:29:04.238732', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2747, 0, '2011-09-30 16:29:32.412821', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2748, 0, '2011-09-30 16:29:35.552019', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2749, 0, '2011-09-30 16:29:56.641722', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2750, 0, '2011-09-30 16:30:05.400119', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2751, 0, '2011-09-30 16:30:13.021913', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2752, 0, '2011-09-30 16:30:25.409772', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2753, 0, '2011-09-30 16:30:29.284346', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2754, 0, '2011-09-30 16:30:32.307759', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2755, 0, '2011-09-30 16:30:36.210948', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2756, 0, '2011-09-30 16:30:49.147218', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2757, 0, '2011-09-30 16:31:05.033482', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2758, 0, '2011-09-30 16:31:20.520792', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2759, 0, '2011-09-30 16:31:28.031704', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2760, 0, '2011-09-30 16:31:37.289788', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2761, 0, '2011-09-30 16:32:16.111295', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2762, 0, '2011-09-30 16:32:47.894315', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2763, 0, '2011-09-30 16:33:07.449924', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2764, 0, '2011-09-30 16:34:16.956676', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2765, 0, '2011-09-30 16:34:45.550923', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2766, 0, '2011-09-30 16:34:51.037907', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2767, 0, '2011-09-30 16:35:13.965982', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2768, 0, '2011-09-30 16:35:18.467535', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2769, 0, '2011-09-30 16:35:33.587507', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2770, 0, '2011-09-30 16:35:44.628084', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2771, 0, '2011-09-30 16:35:54.701856', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2772, 0, '2011-09-30 16:36:12.204949', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2773, 0, '2011-09-30 16:36:36.016519', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2774, 0, '2011-09-30 16:36:44.467822', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2775, 0, '2011-09-30 16:37:04.360264', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2776, 0, '2011-09-30 16:37:15.036565', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2777, 0, '2011-09-30 16:37:37.529883', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2778, 0, '2011-09-30 16:38:09.500363', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2779, 0, '2011-09-30 16:38:11.065152', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2780, 0, '2011-09-30 16:38:23.177934', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2781, 0, '2011-09-30 16:38:27.841166', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2782, 0, '2011-09-30 16:38:37.047137', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2783, 0, '2011-09-30 16:38:48.093663', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2784, 0, '2011-09-30 16:39:22.63212', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2785, 0, '2011-09-30 16:39:24.831093', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2786, 0, '2011-09-30 16:39:35.191526', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2787, 0, '2011-09-30 16:39:46.688351', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2788, 0, '2011-09-30 16:40:03.163761', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2789, 0, '2011-09-30 16:40:17.592075', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2790, 0, '2011-09-30 16:40:23.650387', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2791, 0, '2011-09-30 16:40:54.389822', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2792, 0, '2011-09-30 16:41:11.477516', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2793, 0, '2011-09-30 16:41:43.912085', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2794, 0, '2011-09-30 16:41:49.860926', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2795, 0, '2011-09-30 16:42:09.848739', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2796, 0, '2011-09-30 16:43:36.428922', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2797, 0, '2011-09-30 16:43:57.195225', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2798, 0, '2011-09-30 16:44:25.167001', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2799, 0, '2011-09-30 16:44:49.388133', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2800, 0, '2011-09-30 16:45:02.467918', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2801, 0, '2011-09-30 16:45:26.818956', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2802, 0, '2011-09-30 16:45:33.578358', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2803, 0, '2011-09-30 16:48:08.672135', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2804, 0, '2011-09-30 16:48:15.736471', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2805, 0, '2011-09-30 16:48:31.3202', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2806, 0, '2011-09-30 16:48:33.698725', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2807, 0, '2011-09-30 16:48:35.418361', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2808, 0, '2011-09-30 16:48:49.411683', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2809, 0, '2011-09-30 16:48:52.727023', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2810, 0, '2011-09-30 16:53:14.837309', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2811, 0, '2011-09-30 16:53:22.171682', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2812, 0, '2011-09-30 17:18:33.548713', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2814, 0, '2011-10-03 08:59:39.702534', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2813, 0, '2011-10-03 08:59:39.699939', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2815, 0, '2011-10-03 09:00:00.814258', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2816, 0, '2011-10-03 09:00:02.57155', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2817, 0, '2011-10-03 09:00:04.30063', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2818, 0, '2011-10-03 09:00:05.729855', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2819, 0, '2011-10-03 09:00:09.019178', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2820, 0, '2011-10-03 09:00:13.543511', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2821, 0, '2011-10-03 09:00:15.760044', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2822, 0, '2011-10-03 09:00:17.866839', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2823, 0, '2011-10-03 09:00:27.457924', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2824, 0, '2011-10-03 09:00:32.31981', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2825, 0, '2011-10-03 09:00:34.620542', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2826, 0, '2011-10-03 09:00:35.967894', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2827, 0, '2011-10-03 09:00:39.070374', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2828, 0, '2011-10-03 09:00:40.190624', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2829, 0, '2011-10-03 09:11:44.958152', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2830, 0, '2011-10-03 09:16:49.850142', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2831, 0, '2011-10-03 09:17:02.643778', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2832, 0, '2011-10-03 09:17:07.294689', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2833, 0, '2011-10-03 09:17:08.461111', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2834, 0, '2011-10-03 09:17:14.310079', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2835, 0, '2011-10-03 09:17:18.727713', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2836, 0, '2011-10-03 09:17:28.677503', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2837, 0, '2011-10-03 09:17:30.079123', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2838, 0, '2011-10-03 10:54:19.722349', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2839, 0, '2011-10-03 10:54:21.675993', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2840, 0, '2011-10-03 10:54:30.984193', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2841, 0, '2011-10-03 10:54:34.511974', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2842, 0, '2011-10-03 10:54:38.978415', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2843, 0, '2011-10-03 10:54:48.258269', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2844, 0, '2011-10-03 10:54:50.165499', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2845, 0, '2011-10-03 10:55:05.178364', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2846, 0, '2011-10-03 10:56:07.703885', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2847, 0, '2011-10-03 10:56:08.857606', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2848, 0, '2011-10-03 10:56:22.006402', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2849, 0, '2011-10-03 10:56:24.28749', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2850, 0, '2011-10-03 10:56:27.92987', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2851, 0, '2011-10-03 10:56:30.427213', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2852, 0, '2011-10-03 10:57:33.253821', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2853, 0, '2011-10-03 11:01:32.902199', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2854, 0, '2011-10-03 11:01:34.679596', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2855, 0, '2011-10-03 11:01:44.741558', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2856, 0, '2011-10-03 11:01:46.378026', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2857, 0, '2011-10-03 11:01:49.867181', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2858, 0, '2011-10-03 11:01:53.399411', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2859, 0, '2011-10-03 11:01:56.329593', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2860, 0, '2011-10-03 11:01:59.663882', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2861, 0, '2011-10-03 11:02:02.018453', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2862, 0, '2011-10-03 11:02:02.82786', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2863, 0, '2011-10-03 11:02:09.568984', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2864, 0, '2011-10-03 11:02:50.292719', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2865, 0, '2011-10-03 11:03:35.991605', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2866, 0, '2011-10-03 11:03:41.067296', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2867, 0, '2011-10-03 11:03:45.436175', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2868, 0, '2011-10-03 11:03:47.222351', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2869, 0, '2011-10-03 11:03:52.338311', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2870, 0, '2011-10-03 11:04:14.080385', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2871, 0, '2011-10-03 11:04:27.907563', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2872, 0, '2011-10-03 11:04:51.619221', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2873, 0, '2011-10-03 11:05:24.609819', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2874, 0, '2011-10-03 11:19:21.74146', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2875, 0, '2011-10-03 11:19:23.077622', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2876, 0, '2011-10-03 11:19:24.846461', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2877, 0, '2011-10-03 11:39:47.259662', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2878, 0, '2011-10-03 11:39:52.780248', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2879, 0, '2011-10-03 11:40:04.810276', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2880, 0, '2011-10-03 11:40:07.227043', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2881, 0, '2011-10-03 11:40:43.70568', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2882, 0, '2011-10-03 11:40:47.261282', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2883, 0, '2011-10-03 11:40:51.03653', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2884, 0, '2011-10-03 11:40:53.777826', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2885, 0, '2011-10-03 11:41:01.35272', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2886, 0, '2011-10-03 11:41:19.046877', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2887, 0, '2011-10-03 11:41:21.219469', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2888, 0, '2011-10-03 11:41:22.38477', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2889, 0, '2011-10-03 11:41:27.901763', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2890, 0, '2011-10-03 11:41:30.720155', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2891, 0, '2011-10-03 11:41:32.037999', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2892, 0, '2011-10-03 11:41:33.535182', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2893, 0, '2011-10-03 11:41:35.088977', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2894, 0, '2011-10-03 11:41:44.623507', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2895, 0, '2011-10-03 11:41:45.958043', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2896, 0, '2011-10-03 11:42:02.257261', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2897, 0, '2011-10-03 11:42:05.147115', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2898, 0, '2011-10-03 11:42:09.315915', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2899, 0, '2011-10-03 11:46:01.733469', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2900, 0, '2011-10-03 11:46:15.745573', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2901, 0, '2011-10-03 11:46:17.159997', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2902, 0, '2011-10-03 11:54:12.218975', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2903, 0, '2011-10-03 11:54:19.619896', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2904, 0, '2011-10-03 11:54:20.876262', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2905, 0, '2011-10-03 11:54:26.553595', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2906, 0, '2011-10-03 11:54:30.800287', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2907, 0, '2011-10-03 11:54:43.400068', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2908, 0, '2011-10-03 11:54:44.494211', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2909, 0, '2011-10-03 11:54:46.457913', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2910, 0, '2011-10-03 11:56:11.272857', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2911, 0, '2011-10-03 11:56:12.848178', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2912, 0, '2011-10-03 11:56:29.618253', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2913, 0, '2011-10-03 11:56:32.30631', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2914, 0, '2011-10-03 12:00:00.472006', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2915, 0, '2011-10-03 12:00:01.395732', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2916, 0, '2011-10-03 12:00:07.348723', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2917, 0, '2011-10-03 12:00:10.560072', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2918, 0, '2011-10-03 12:00:14.911371', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2919, 0, '2011-10-03 12:00:49.92924', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2920, 0, '2011-10-03 12:00:50.956413', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2921, 0, '2011-10-03 12:04:02.55069', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2922, 0, '2011-10-03 12:04:05.119259', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2923, 0, '2011-10-03 12:04:15.399726', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2924, 0, '2011-10-03 12:04:34.689876', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2925, 0, '2011-10-03 12:04:37.919882', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2926, 0, '2011-10-03 12:04:41.708116', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2927, 0, '2011-10-03 12:04:45.716526', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2928, 0, '2011-10-03 12:06:46.522571', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2929, 0, '2011-10-03 12:07:37.348864', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2930, 0, '2011-10-03 12:08:08.266641', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2931, 0, '2011-10-03 12:08:30.370471', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2932, 0, '2011-10-03 12:08:48.667483', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2933, 0, '2011-10-03 12:09:38.07938', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2934, 0, '2011-10-03 12:10:19.460836', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2935, 0, '2011-10-03 12:11:24.887623', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2936, 0, '2011-10-03 12:11:52.501795', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2937, 0, '2011-10-03 12:12:53.587032', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2938, 0, '2011-10-03 12:13:04.405424', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2939, 0, '2011-10-03 12:13:08.94473', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2940, 0, '2011-10-03 12:13:45.713918', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2941, 0, '2011-10-03 12:13:50.356931', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2942, 0, '2011-10-03 12:13:57.358788', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2943, 0, '2011-10-03 12:14:03.220219', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2944, 0, '2011-10-03 12:14:08.987305', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2945, 0, '2011-10-03 12:14:16.202132', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2946, 0, '2011-10-03 12:14:23.676596', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2947, 0, '2011-10-03 12:14:26.849107', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2948, 0, '2011-10-03 12:14:31.724461', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2949, 0, '2011-10-03 12:14:33.518315', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2950, 0, '2011-10-03 12:14:34.555573', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2951, 0, '2011-10-03 12:14:39.706859', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2952, 0, '2011-10-03 12:14:50.87022', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2953, 0, '2011-10-03 12:14:55.679788', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2954, 0, '2011-10-03 12:14:57.648528', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2955, 0, '2011-10-03 12:15:00.797175', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2956, 0, '2011-10-03 12:15:02.546528', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2957, 0, '2011-10-03 12:15:06.365996', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2958, 0, '2011-10-03 12:16:58.018275', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2959, 0, '2011-10-03 12:18:23.797127', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2960, 0, '2011-10-03 12:18:26.125197', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2961, 0, '2011-10-03 12:18:27.692069', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2962, 0, '2011-10-03 12:19:15.032703', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2963, 0, '2011-10-03 12:19:39.19691', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2964, 0, '2011-10-03 12:19:51.716589', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2965, 0, '2011-10-03 12:19:53.186018', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2966, 0, '2011-10-03 12:20:05.077855', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2967, 0, '2011-10-03 12:20:09.901552', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2968, 0, '2011-10-03 12:20:11.19537', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2969, 0, '2011-10-03 12:20:16.229843', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2970, 0, '2011-10-03 12:20:24.267278', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2971, 0, '2011-10-03 12:20:27.924481', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2972, 0, '2011-10-03 12:20:31.267369', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2973, 0, '2011-10-03 12:20:33.36434', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2974, 0, '2011-10-03 12:20:35.150052', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2975, 0, '2011-10-03 12:20:49.529589', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2976, 0, '2011-10-03 12:20:52.169014', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2977, 0, '2011-10-03 12:20:57.391769', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2978, 0, '2011-10-03 12:20:59.239279', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2979, 0, '2011-10-03 12:21:01.364722', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2980, 0, '2011-10-03 12:21:04.960842', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2981, 0, '2011-10-03 12:21:06.082027', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2982, 0, '2011-10-03 12:21:50.267785', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2983, 0, '2011-10-03 12:21:55.512154', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2984, 0, '2011-10-03 12:21:59.444034', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2985, 0, '2011-10-03 12:22:01.667687', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2986, 0, '2011-10-03 12:22:14.416104', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2987, 0, '2011-10-03 12:22:16.321313', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2988, 0, '2011-10-03 12:22:20.2198', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2989, 0, '2011-10-03 12:22:24.67852', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2990, 0, '2011-10-03 12:22:30.907339', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2991, 0, '2011-10-03 12:22:35.480609', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2992, 0, '2011-10-03 12:22:39.86829', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2993, 0, '2011-10-03 12:22:44.025597', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2994, 0, '2011-10-03 12:22:48.067671', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2995, 0, '2011-10-03 12:22:49.322109', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2996, 0, '2011-10-03 12:24:28.028824', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2997, 0, '2011-10-03 12:24:30.693378', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2998, 0, '2011-10-03 12:24:32.084789', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (2999, 0, '2011-10-03 12:24:35.827216', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3000, 0, '2011-10-03 12:24:37.907166', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3001, 0, '2011-10-03 12:24:39.882919', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3002, 0, '2011-10-03 12:24:42.560118', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3003, 0, '2011-10-03 12:24:46.791089', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3004, 0, '2011-10-03 12:24:50.329707', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3005, 0, '2011-10-03 12:25:05.501904', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3006, 0, '2011-10-03 12:25:12.578157', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3007, 0, '2011-10-03 12:25:15.06528', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3008, 0, '2011-10-03 12:25:29.39127', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3009, 0, '2011-10-03 12:25:31.810388', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3010, 0, '2011-10-03 12:25:39.095725', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3011, 0, '2011-10-03 12:25:40.751182', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3012, 0, '2011-10-03 12:25:42.556748', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3013, 0, '2011-10-03 12:30:24.752216', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3014, 0, '2011-10-03 12:30:26.147997', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3015, 0, '2011-10-03 12:30:27.307204', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3016, 0, '2011-10-03 12:30:28.221347', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3017, 0, '2011-10-03 12:30:29.1401', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3018, 0, '2011-10-03 12:43:30.200183', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3019, 0, '2011-10-03 12:43:41.316577', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3020, 0, '2011-10-03 12:43:51.614646', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3021, 0, '2011-10-03 12:43:58.802631', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3022, 0, '2011-10-03 12:44:00.600823', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3023, 0, '2011-10-03 12:44:04.160392', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3024, 0, '2011-10-03 12:44:11.090227', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3025, 0, '2011-10-03 12:44:25.274817', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3026, 0, '2011-10-03 12:44:29.937763', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3027, 0, '2011-10-03 12:44:42.618613', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3028, 0, '2011-10-03 12:44:56.484713', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3029, 0, '2011-10-03 12:44:59.36141', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3030, 0, '2011-10-03 12:45:38.889605', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3031, 0, '2011-10-03 12:45:46.388016', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3032, 0, '2011-10-03 12:45:51.219428', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3033, 0, '2011-10-03 12:45:57.885631', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3034, 0, '2011-10-03 12:46:03.649535', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3035, 0, '2011-10-03 12:46:05.638074', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3036, 0, '2011-10-03 12:46:12.021005', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3037, 0, '2011-10-03 12:46:19.09944', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3038, 0, '2011-10-03 12:46:22.061054', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3039, 0, '2011-10-03 12:46:27.480097', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3040, 0, '2011-10-03 12:46:32.813978', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3041, 0, '2011-10-03 12:46:41.183899', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3042, 0, '2011-10-03 12:46:45.254547', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3043, 0, '2011-10-03 12:46:53.645208', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3044, 0, '2011-10-03 12:46:57.067155', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3045, 0, '2011-10-03 12:47:23.174716', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3046, 0, '2011-10-03 12:47:33.991501', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3047, 0, '2011-10-03 12:47:40.005569', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3048, 0, '2011-10-03 12:47:42.301734', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3049, 0, '2011-10-03 12:47:47.846307', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3050, 0, '2011-10-03 12:47:52.495253', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3051, 0, '2011-10-03 12:47:58.818655', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3052, 0, '2011-10-03 12:48:04.547153', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3053, 0, '2011-10-03 12:51:33.166971', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3054, 0, '2011-10-03 12:51:36.409887', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3055, 0, '2011-10-03 12:51:38.304647', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3056, 0, '2011-10-03 12:51:42.666786', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3057, 0, '2011-10-03 12:51:43.837357', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3058, 0, '2011-10-03 12:51:48.840962', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3059, 0, '2011-10-03 15:31:13.042953', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3060, 0, '2011-10-03 15:31:13.045801', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3061, 0, '2011-10-03 15:31:16.73594', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3062, 0, '2011-10-03 15:31:26.285118', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3063, 0, '2011-10-03 15:38:29.595948', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3064, 0, '2011-10-03 15:38:39.954478', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3065, 0, '2011-10-03 15:38:48.306011', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3066, 0, '2011-10-03 15:39:54.60836', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3067, 0, '2011-10-03 15:39:58.569843', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3068, 0, '2011-10-03 15:40:17.187205', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3069, 0, '2011-10-03 15:40:31.442893', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3070, 0, '2011-10-03 15:40:33.774496', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3071, 0, '2011-10-03 15:55:11.148217', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3072, 0, '2011-10-03 15:55:27.666624', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3073, 0, '2011-10-03 15:55:42.302092', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3074, 0, '2011-10-03 15:55:46.756999', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3075, 0, '2011-10-03 15:56:08.005743', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3076, 0, '2011-10-03 15:56:12.091278', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3077, 0, '2011-10-03 15:56:29.388949', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3078, 0, '2011-10-03 15:56:31.254772', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3079, 0, '2011-10-03 15:56:35.505024', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3080, 0, '2011-10-03 15:56:58.962856', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3081, 0, '2011-10-03 15:57:01.045862', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3082, 0, '2011-10-03 16:06:26.756138', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3083, 0, '2011-10-03 16:06:30.448052', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3084, 0, '2011-10-03 16:06:37.304254', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3085, 0, '2011-10-03 16:06:41.432851', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3086, 0, '2011-10-03 16:06:44.459206', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3087, 0, '2011-10-03 16:08:36.81506', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3088, 0, '2011-10-03 16:08:41.131184', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3089, 0, '2011-10-03 16:09:12.442148', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3090, 0, '2011-10-03 16:09:14.085433', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3091, 0, '2011-10-03 16:09:20.066002', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3092, 0, '2011-10-03 16:09:42.578074', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3093, 0, '2011-10-03 16:10:09.705984', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3094, 0, '2011-10-03 16:10:13.455367', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3095, 0, '2011-10-03 16:10:25.680818', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3096, 0, '2011-10-03 16:10:30.820108', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3097, 0, '2011-10-03 16:10:50.755072', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3098, 0, '2011-10-03 16:11:03.355098', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3099, 0, '2011-10-03 16:11:16.676538', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3100, 0, '2011-10-03 16:11:20.656856', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3101, 0, '2011-10-03 16:11:28.766709', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3102, 0, '2011-10-03 16:11:31.427243', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3103, 0, '2011-10-03 16:11:45.484322', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3104, 0, '2011-10-03 16:11:50.959811', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3105, 0, '2011-10-03 16:11:58.363592', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3106, 0, '2011-10-03 16:12:04.890608', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3107, 0, '2011-10-03 16:12:07.773496', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3108, 0, '2011-10-03 16:12:13.818275', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3109, 0, '2011-10-03 16:12:16.414417', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3110, 0, '2011-10-03 16:12:19.430951', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3111, 0, '2011-10-03 16:12:25.995661', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3112, 0, '2011-10-03 16:14:05.804584', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3113, 0, '2011-10-03 16:15:44.296166', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3114, 0, '2011-10-03 16:16:59.407381', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3115, 0, '2011-10-03 16:17:30.12384', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3116, 0, '2011-10-03 16:18:09.833854', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3117, 0, '2011-10-03 16:18:20.806684', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3118, 0, '2011-10-03 16:18:25.056588', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3119, 0, '2011-10-03 16:18:28.745966', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3120, 0, '2011-10-03 16:18:32.442076', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3121, 0, '2011-10-03 16:18:55.033179', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3122, 0, '2011-10-03 16:19:01.144088', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3123, 0, '2011-10-03 16:19:03.597129', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3124, 0, '2011-10-03 16:19:07.901438', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3125, 0, '2011-10-03 16:19:42.176481', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3126, 0, '2011-10-03 16:19:45.654987', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3127, 0, '2011-10-03 16:19:48.641844', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3128, 0, '2011-10-03 16:19:55.054062', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3129, 0, '2011-10-03 16:19:58.591407', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3130, 0, '2011-10-03 16:20:47.6135', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3131, 0, '2011-10-03 16:20:50.855074', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3132, 0, '2011-10-03 16:21:00.253818', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3133, 0, '2011-10-03 16:21:22.667687', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3134, 0, '2011-10-03 16:21:24.197076', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3135, 0, '2011-10-03 16:21:27.386814', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3136, 0, '2011-10-03 16:21:30.454541', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3137, 0, '2011-10-03 16:22:42.974671', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3138, 0, '2011-10-03 16:23:20.42609', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3139, 0, '2011-10-03 16:23:31.362042', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3140, 0, '2011-10-03 16:24:33.84454', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3141, 0, '2011-10-03 16:24:42.135067', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3142, 0, '2011-10-03 16:24:47.5741', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3143, 0, '2011-10-03 16:24:51.204781', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3144, 0, '2011-10-03 16:24:55.410885', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3145, 0, '2011-10-03 16:24:59.005138', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3146, 0, '2011-10-03 16:25:02.797123', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3147, 0, '2011-10-03 16:25:30.012437', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3148, 0, '2011-10-03 16:25:39.757364', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3149, 0, '2011-10-03 16:25:43.066261', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3150, 0, '2011-10-03 16:25:53.58628', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3151, 0, '2011-10-03 16:25:56.257535', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3152, 0, '2011-10-03 16:26:11.516409', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3153, 0, '2011-10-03 16:26:16.861202', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3154, 0, '2011-10-03 16:26:22.990418', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3155, 0, '2011-10-03 16:26:30.294938', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3156, 0, '2011-10-03 16:26:40.268796', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3157, 0, '2011-10-03 16:26:55.295593', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3158, 0, '2011-10-03 16:27:07.295051', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3159, 0, '2011-10-03 16:28:19.11394', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3160, 0, '2011-10-03 16:28:25.437335', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3161, 0, '2011-10-03 16:28:34.492604', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3162, 0, '2011-10-03 16:30:09.664181', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3163, 0, '2011-10-03 16:30:16.269657', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3164, 0, '2011-10-03 16:30:24.982436', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3165, 0, '2011-10-03 16:30:50.936657', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3166, 0, '2011-10-03 16:31:16.826645', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3167, 0, '2011-10-03 16:31:28.551764', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3168, 0, '2011-10-03 16:31:31.327168', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3169, 0, '2011-10-03 16:31:53.766016', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3170, 0, '2011-10-03 16:33:10.244567', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3171, 0, '2011-10-03 16:33:25.336184', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3172, 0, '2011-10-03 16:33:42.307535', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3173, 0, '2011-10-03 16:33:48.575062', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3174, 0, '2011-10-03 16:33:53.808946', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3175, 0, '2011-10-03 16:34:19.74459', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3176, 0, '2011-10-03 16:34:23.205157', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3177, 0, '2011-10-03 16:34:28.329784', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3178, 0, '2011-10-03 16:34:42.868575', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3179, 0, '2011-10-03 16:34:53.820265', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3180, 0, '2011-10-03 16:35:17.295621', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3181, 0, '2011-10-03 16:35:59.988815', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3182, 0, '2011-10-03 16:37:49.726022', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3183, 0, '2011-10-03 16:38:31.407023', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3184, 0, '2011-10-03 16:38:41.887482', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3185, 0, '2011-10-03 16:38:51.114549', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3186, 0, '2011-10-03 16:38:55.892993', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3187, 0, '2011-10-03 16:39:06.558847', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3188, 0, '2011-10-03 16:39:11.76016', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3189, 0, '2011-10-03 16:39:12.95926', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3190, 0, '2011-10-03 16:39:17.982804', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3191, 0, '2011-10-03 16:39:41.129478', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3192, 0, '2011-10-03 16:39:54.512803', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3193, 0, '2011-10-03 16:40:06.045423', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3194, 0, '2011-10-03 16:40:13.541103', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3195, 0, '2011-10-03 16:40:16.91871', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3196, 0, '2011-10-03 16:40:22.58585', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3197, 0, '2011-10-03 16:40:51.606891', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3198, 0, '2011-10-03 16:40:56.581967', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3199, 0, '2011-10-03 16:41:08.743589', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3200, 0, '2011-10-03 16:44:20.877625', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3201, 0, '2011-10-03 16:46:12.429268', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3202, 0, '2011-10-03 16:46:18.884298', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3203, 0, '2011-10-03 16:46:26.315049', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3204, 0, '2011-10-03 16:46:53.881016', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3205, 0, '2011-10-03 16:46:57.726992', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3206, 0, '2011-10-03 16:47:17.44955', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3207, 0, '2011-10-03 16:47:25.397865', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3208, 0, '2011-10-03 16:47:40.607551', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3209, 0, '2011-10-03 16:48:27.206517', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3210, 0, '2011-10-03 16:48:41.126891', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3211, 0, '2011-10-03 16:49:06.480791', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3212, 0, '2011-10-03 16:49:44.602844', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3213, 0, '2011-10-03 16:49:47.27871', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3214, 0, '2011-10-03 16:49:51.00576', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3215, 0, '2011-10-03 16:49:55.803079', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3216, 0, '2011-10-03 16:50:04.185079', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3217, 0, '2011-10-03 16:50:18.745064', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3218, 0, '2011-10-03 16:50:22.080714', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3219, 0, '2011-10-03 16:50:32.331975', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3220, 0, '2011-10-03 16:50:43.163022', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3221, 0, '2011-10-03 16:50:47.032029', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3222, 0, '2011-10-03 16:50:56.944035', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3223, 0, '2011-10-03 16:51:05.230087', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3224, 0, '2011-10-03 16:51:08.810083', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3225, 0, '2011-10-03 16:51:29.176369', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3226, 0, '2011-10-03 16:51:33.804753', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3227, 0, '2011-10-03 16:51:39.468326', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3228, 0, '2011-10-03 16:51:43.167332', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3229, 0, '2011-10-03 16:51:47.643909', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3230, 0, '2011-10-03 16:51:49.82835', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3231, 0, '2011-10-03 16:51:55.155555', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3232, 0, '2011-10-03 16:52:25.385747', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3233, 0, '2011-10-03 16:52:31.365541', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3234, 0, '2011-10-03 16:52:37.553051', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3235, 0, '2011-10-03 16:52:42.248826', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3236, 0, '2011-10-03 16:52:59.515215', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3237, 0, '2011-10-03 16:53:22.356468', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3238, 0, '2011-10-03 16:53:30.054635', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3239, 0, '2011-10-03 16:53:45.613057', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3240, 0, '2011-10-03 16:53:51.487253', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3241, 0, '2011-10-03 16:53:55.552326', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3242, 0, '2011-10-03 16:54:12.733944', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3243, 0, '2011-10-03 16:54:43.319698', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3244, 0, '2011-10-03 16:55:02.689974', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3245, 0, '2011-10-03 16:55:35.977016', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3246, 0, '2011-10-03 16:57:20.353469', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3247, 0, '2011-10-03 16:57:52.782775', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3248, 0, '2011-10-03 16:58:02.213109', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3249, 0, '2011-10-03 16:58:10.03307', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3250, 0, '2011-10-03 16:58:12.60592', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3251, 0, '2011-10-03 17:00:36.922253', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3252, 0, '2011-10-03 17:00:43.853362', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3253, 0, '2011-10-03 17:00:55.231384', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3254, 0, '2011-10-03 17:01:13.263872', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3255, 0, '2011-10-03 17:01:17.884115', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3256, 0, '2011-10-03 17:01:23.79402', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3257, 0, '2011-10-03 17:01:50.715285', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3258, 0, '2011-10-03 17:01:56.757677', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3259, 0, '2011-10-03 17:02:19.354075', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3260, 0, '2011-10-03 17:02:35.164829', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3261, 0, '2011-10-03 17:02:41.350096', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3262, 0, '2011-10-03 17:03:04.62279', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3263, 0, '2011-10-03 17:04:58.351782', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3264, 0, '2011-10-03 17:12:45.625903', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3265, 0, '2011-10-03 17:12:47.46402', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3266, 0, '2011-10-03 17:25:26.405793', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3267, 0, '2011-10-10 11:56:00.498733', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3268, 0, '2011-10-10 11:56:00.501554', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3269, 0, '2011-10-10 11:56:20.287357', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3270, 0, '2011-10-10 11:56:23.557902', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3271, 0, '2011-10-10 11:56:25.038007', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3272, 0, '2011-10-10 11:59:58.963505', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3273, 0, '2011-10-10 12:00:03.550064', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3274, 0, '2011-10-10 12:00:05.829098', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3275, 0, '2011-10-10 12:00:07.011885', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3276, 0, '2011-10-10 12:00:12.770085', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3277, 0, '2011-10-10 12:00:14.112001', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3278, 0, '2011-10-10 12:08:20.485846', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3279, 0, '2011-10-10 12:08:20.490207', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3280, 0, '2011-10-10 12:08:22.982939', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3281, 0, '2011-10-10 12:09:45.041102', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3282, 0, '2011-10-10 12:09:46.329971', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3283, 0, '2011-10-10 12:09:49.614669', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3284, 0, '2011-10-10 12:09:50.60625', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3285, 0, '2011-10-10 12:11:23.899408', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3286, 0, '2011-10-10 12:11:25.440938', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3287, 0, '2011-10-10 12:11:27.121361', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3288, 0, '2011-10-10 12:11:28.220603', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3289, 0, '2011-10-10 12:11:29.538716', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3290, 0, '2011-10-10 12:11:30.511605', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3291, 0, '2011-10-10 12:11:31.29204', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3292, 0, '2011-10-10 12:11:33.557879', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3293, 0, '2011-10-10 12:11:35.54899', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3295, 0, '2011-10-10 12:19:00.066436', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3294, 0, '2011-10-10 12:19:00.061014', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3296, 0, '2011-10-10 12:19:07.827798', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3297, 0, '2011-10-10 12:19:09.85545', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3298, 0, '2011-10-10 12:19:15.832527', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3299, 0, '2011-10-10 12:19:45.080733', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3300, 0, '2011-10-10 12:19:49.543074', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3301, 0, '2011-10-10 12:19:51.372658', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3302, 0, '2011-10-10 12:19:56.939901', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3303, 0, '2011-10-10 12:20:11.08453', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3304, 0, '2011-10-10 12:20:15.442475', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3305, 0, '2011-10-10 12:20:38.946159', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3306, 0, '2011-10-10 12:20:42.245833', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3307, 0, '2011-10-10 12:20:44.269985', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3308, 0, '2011-10-10 12:20:46.972001', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3309, 0, '2011-10-10 12:20:49.482607', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3310, 0, '2011-10-10 12:20:54.063133', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3311, 0, '2011-10-10 12:20:57.58271', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3312, 0, '2011-10-10 12:21:03.692499', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3313, 0, '2011-10-10 12:21:12.197374', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3314, 0, '2011-10-10 12:21:12.983987', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3315, 0, '2011-10-10 12:21:25.119572', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3316, 0, '2011-10-10 12:21:33.0386', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3317, 0, '2011-10-10 12:21:38.518945', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3318, 0, '2011-10-10 12:21:45.284665', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3319, 0, '2011-10-10 12:21:50.781674', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3320, 0, '2011-10-10 12:21:57.549089', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3321, 0, '2011-10-10 12:22:38.090674', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3322, 0, '2011-10-10 12:22:41.002367', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3323, 0, '2011-10-10 12:22:56.123974', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3324, 0, '2011-10-10 12:22:57.550947', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3325, 0, '2011-10-10 12:28:52.665723', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3326, 0, '2011-10-10 12:29:15.0441', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3327, 0, '2011-10-10 12:29:24.531556', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3328, 0, '2011-10-10 12:29:30.029675', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3329, 0, '2011-10-10 12:29:31.771121', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3330, 0, '2011-10-10 12:29:36.433272', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3331, 0, '2011-10-10 12:29:38.35823', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3332, 0, '2011-10-10 12:29:40.682827', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3333, 0, '2011-10-10 12:29:45.198807', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3334, 0, '2011-10-10 12:29:50.433323', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3335, 0, '2011-10-10 12:29:53.133399', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3336, 0, '2011-10-10 12:30:29.06098', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3337, 0, '2011-10-10 12:30:38.722085', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3338, 0, '2011-10-10 12:30:39.872854', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3339, 0, '2011-10-10 12:30:42.238351', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3340, 0, '2011-10-10 12:30:43.493428', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3341, 0, '2011-10-10 12:30:46.330985', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3342, 0, '2011-10-10 12:31:00.528195', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3343, 0, '2011-10-10 12:31:02.853124', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3344, 0, '2011-10-10 12:31:05.783303', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3345, 0, '2011-10-10 12:31:07.270521', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3346, 0, '2011-10-10 12:31:43.743579', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3347, 0, '2011-10-10 12:31:46.603217', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3348, 0, '2011-10-10 12:31:48.793084', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3349, 0, '2011-10-10 12:31:50.12189', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3350, 0, '2011-10-10 12:32:28.52262', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3351, 0, '2011-10-10 12:32:30.780366', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3352, 0, '2011-10-10 12:32:34.76257', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3353, 0, '2011-10-10 12:32:36.342432', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3354, 0, '2011-10-10 12:32:40.529024', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3355, 0, '2011-10-10 12:34:35.069881', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3356, 0, '2011-10-10 12:34:46.430204', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3357, 0, '2011-10-10 12:35:04.842334', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3358, 0, '2011-10-10 12:35:19.196537', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3359, 0, '2011-10-10 12:35:21.663295', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3360, 0, '2011-10-10 12:35:33.883271', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3361, 0, '2011-10-10 12:36:39.571748', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3362, 0, '2011-10-10 12:36:48.614789', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3363, 0, '2011-10-10 12:37:46.883137', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3364, 0, '2011-10-10 12:37:49.902684', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3365, 0, '2011-10-10 12:37:54.887701', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3366, 0, '2011-10-10 12:37:59.71807', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3367, 0, '2011-10-10 12:38:01.827717', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3368, 0, '2011-10-10 12:38:02.716563', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3369, 0, '2011-10-10 12:39:18.270092', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3370, 0, '2011-10-10 12:39:19.573122', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3371, 0, '2011-10-10 12:39:26.70377', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3372, 0, '2011-10-10 12:39:43.353123', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3373, 0, '2011-10-10 12:40:17.331625', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3374, 0, '2011-10-10 12:40:23.989427', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3375, 0, '2011-10-10 12:40:28.99508', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3376, 0, '2011-10-10 12:40:35.492291', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3377, 0, '2011-10-10 12:40:43.275985', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3378, 0, '2011-10-10 12:40:58.017296', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3379, 0, '2011-10-10 12:41:08.225092', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3380, 0, '2011-10-10 12:41:10.402475', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3381, 0, '2011-10-10 12:41:16.442561', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3382, 0, '2011-10-10 12:41:19.605383', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3383, 0, '2011-10-10 12:43:00.753207', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3384, 0, '2011-10-10 12:43:05.142608', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3385, 0, '2011-10-10 12:43:38.7039', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3386, 0, '2011-10-10 12:43:40.49107', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3387, 0, '2011-10-10 12:43:42.919508', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3388, 0, '2011-10-10 12:44:11.351286', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3389, 0, '2011-10-10 12:44:14.350316', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3390, 0, '2011-10-10 12:44:27.304096', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3391, 0, '2011-10-10 12:44:30.719922', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3392, 0, '2011-10-10 12:44:37.932194', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3393, 0, '2011-10-10 12:48:25.824353', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3394, 0, '2011-10-10 12:48:29.472952', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3395, 0, '2011-10-10 12:48:31.487005', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3396, 0, '2011-10-10 12:48:35.986665', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3397, 0, '2011-10-10 12:48:43.989445', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3398, 0, '2011-10-10 12:54:51.480298', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3399, 0, '2011-10-10 12:54:53.648206', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3400, 0, '2011-10-10 12:54:55.9092', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3401, 0, '2011-10-10 12:54:58.033774', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3402, 0, '2011-10-10 12:55:00.050131', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3403, 0, '2011-10-10 12:55:01.429099', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3404, 0, '2011-10-10 13:07:53.212123', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3405, 0, '2011-10-10 13:08:05.051761', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3406, 0, '2011-10-10 13:08:10.465424', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3407, 0, '2011-10-10 13:09:10.599224', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3408, 0, '2011-10-10 13:09:29.536925', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3409, 0, '2011-10-10 13:09:36.88036', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3410, 0, '2011-10-10 13:09:46.309307', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3411, 0, '2011-10-10 13:09:53.514716', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3412, 0, '2011-10-10 13:09:55.247548', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3413, 0, '2011-10-10 13:09:59.02168', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3414, 0, '2011-10-10 13:10:01.362364', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3415, 0, '2011-10-10 13:10:24.378955', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3416, 0, '2011-10-10 13:10:26.669126', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3417, 0, '2011-10-10 13:10:28.692485', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3418, 0, '2011-10-10 13:10:42.229315', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3419, 0, '2011-10-10 13:11:14.630417', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3420, 0, '2011-10-10 13:12:10.990321', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3421, 0, '2011-10-10 13:12:22.067269', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3422, 0, '2011-10-10 13:12:24.410617', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3423, 0, '2011-10-10 13:12:34.365564', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3424, 0, '2011-10-10 13:12:36.848491', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3425, 0, '2011-10-10 13:12:49.858385', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3426, 0, '2011-10-10 13:12:51.132459', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3427, 0, '2011-10-10 13:12:52.539032', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3428, 0, '2011-10-10 13:13:02.798112', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3429, 0, '2011-10-10 13:13:06.438422', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3430, 0, '2011-10-10 13:13:18.029623', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3431, 0, '2011-10-10 13:13:25.742887', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3432, 0, '2011-10-10 13:13:52.65204', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3433, 0, '2011-10-10 13:13:54.610283', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3434, 0, '2011-10-10 13:14:19.19355', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3435, 0, '2011-10-10 13:14:54.119899', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3436, 0, '2011-10-10 13:14:55.390171', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3437, 0, '2011-10-10 13:15:32.384914', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3438, 0, '2011-10-10 13:15:37.963006', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3439, 0, '2011-10-10 13:15:42.534651', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3440, 0, '2011-10-10 13:15:43.754052', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3441, 0, '2011-10-10 13:18:51.277686', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3442, 0, '2011-10-10 13:19:03.63021', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3443, 0, '2011-10-10 13:19:10.130893', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3444, 0, '2011-10-10 13:19:16.657984', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3445, 0, '2011-10-10 13:19:18.740575', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3446, 0, '2011-10-10 13:19:28.574046', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3447, 0, '2011-10-10 13:19:34.909998', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3448, 0, '2011-10-10 13:19:39.214604', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3449, 0, '2011-10-10 13:19:50.536208', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3450, 0, '2011-10-10 13:20:03.08489', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3451, 0, '2011-10-10 13:20:08.362061', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3452, 0, '2011-10-10 13:21:03.038347', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3453, 0, '2011-10-10 13:22:33.659584', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3454, 0, '2011-10-10 13:22:43.656429', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3455, 0, '2011-10-10 13:22:47.051859', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3456, 0, '2011-10-10 13:22:49.789673', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3457, 0, '2011-10-10 13:22:55.006506', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3458, 0, '2011-10-10 13:23:06.197138', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3459, 0, '2011-10-10 13:23:44.751791', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3460, 0, '2011-10-10 13:24:10.228329', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3461, 0, '2011-10-10 13:24:25.190174', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3462, 0, '2011-10-10 13:28:50.474761', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3463, 0, '2011-10-10 13:28:57.581256', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3464, 0, '2011-10-10 13:28:58.820961', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3465, 0, '2011-10-10 13:31:28.848161', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3466, 0, '2011-10-10 13:31:35.935757', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3467, 0, '2011-10-10 13:31:38.949793', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3468, 0, '2011-10-10 13:32:25.969701', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3469, 0, '2011-10-10 13:32:31.692162', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3470, 0, '2011-10-10 13:32:51.803045', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3471, 0, '2011-10-10 13:32:59.625304', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3472, 0, '2011-10-10 13:33:10.553908', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3473, 0, '2011-10-10 13:33:13.313184', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3474, 0, '2011-10-10 13:33:30.048696', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3475, 0, '2011-10-10 13:33:41.851824', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3476, 0, '2011-10-10 13:34:05.3043', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3477, 0, '2011-10-10 13:34:13.716998', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3478, 0, '2011-10-10 13:34:15.619363', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3479, 0, '2011-10-10 13:34:19.30231', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3480, 0, '2011-10-10 13:34:26.207945', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3481, 0, '2011-10-10 13:34:46.372274', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3482, 0, '2011-10-10 13:35:12.266381', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3483, 0, '2011-10-10 13:35:37.852336', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3484, 0, '2011-10-10 13:35:44.292076', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3485, 0, '2011-10-10 13:40:02.957285', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3486, 0, '2011-10-10 13:40:26.621119', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3487, 0, '2011-10-10 13:40:50.701719', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3488, 0, '2011-10-10 13:40:53.63542', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3489, 0, '2011-10-10 13:41:01.149869', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3490, 0, '2011-10-10 13:41:07.349935', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3491, 0, '2011-10-10 13:41:15.789809', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3492, 0, '2011-10-10 13:41:26.447935', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3493, 0, '2011-10-10 13:41:28.658352', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3494, 0, '2011-10-10 13:41:32.033086', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3495, 0, '2011-10-10 13:42:13.910429', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3496, 0, '2011-10-10 13:42:15.41621', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3497, 0, '2011-10-10 13:42:20.803461', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3498, 0, '2011-10-10 13:42:25.026105', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3499, 0, '2011-10-10 13:42:27.264073', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3500, 0, '2011-10-10 13:42:28.491615', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3501, 0, '2011-10-10 13:42:34.171858', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3502, 0, '2011-10-10 13:42:38.818084', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3503, 0, '2011-10-10 13:42:44.438134', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3504, 0, '2011-10-10 13:43:18.261197', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3505, 0, '2011-10-10 13:43:34.16781', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3506, 0, '2011-10-10 13:43:39.731997', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3507, 0, '2011-10-10 13:44:27.620727', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3508, 0, '2011-10-10 13:44:35.670939', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3509, 0, '2011-10-10 13:45:13.181098', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3510, 0, '2011-10-10 13:45:17.060661', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3511, 0, '2011-10-10 13:45:20.825798', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3512, 0, '2011-10-10 13:45:26.091966', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3513, 0, '2011-10-10 13:45:41.630397', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3514, 0, '2011-10-10 13:46:52.140854', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3515, 0, '2011-10-10 13:46:59.64263', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3516, 0, '2011-10-10 13:47:09.813488', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3517, 0, '2011-10-10 13:47:24.463367', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3518, 0, '2011-10-10 13:47:36.451928', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3519, 0, '2011-10-10 13:47:37.789906', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3520, 0, '2011-10-10 13:47:40.521965', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3521, 0, '2011-10-10 13:48:24.033722', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3522, 0, '2011-10-10 13:48:33.860899', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3523, 0, '2011-10-10 13:48:42.094229', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3524, 0, '2011-10-10 13:49:16.452149', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3525, 0, '2011-10-10 13:49:24.496747', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3526, 0, '2011-10-10 13:50:08.190347', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3527, 0, '2011-10-10 13:50:12.629187', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3528, 0, '2011-10-10 13:50:17.741016', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3529, 0, '2011-10-10 13:50:20.018268', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3530, 0, '2011-10-10 13:50:52.410624', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3531, 0, '2011-10-10 13:52:13.670316', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3532, 0, '2011-10-10 13:52:23.203436', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3533, 0, '2011-10-10 13:52:35.651838', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3534, 0, '2011-10-10 13:52:37.064371', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3535, 0, '2011-10-10 13:52:43.332078', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3536, 0, '2011-10-10 13:54:03.351404', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3537, 0, '2011-10-10 13:54:05.061024', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3538, 0, '2011-10-10 13:54:07.420664', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3539, 0, '2011-10-10 13:54:10.452969', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3540, 0, '2011-10-10 13:56:43.17465', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3541, 0, '2011-10-10 13:56:49.249492', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3542, 0, '2011-10-10 14:09:26.587376', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3543, 0, '2011-10-10 14:09:27.765848', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3544, 0, '2011-10-10 14:09:29.974886', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3545, 0, '2011-10-10 14:09:31.845955', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3546, 0, '2011-10-10 14:09:33.214093', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3547, 0, '2011-10-10 14:09:34.694491', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3548, 0, '2011-10-10 14:09:35.798916', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3549, 0, '2011-10-10 14:12:54.188142', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3550, 0, '2011-10-10 14:12:59.754834', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3551, 0, '2011-10-10 14:12:59.797474', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3552, 0, '2011-10-10 14:13:02.836232', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3553, 0, '2011-10-10 14:13:08.842678', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3554, 0, '2011-10-10 14:13:12.34776', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3555, 0, '2011-10-10 14:13:13.858713', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3556, 0, '2011-10-10 14:13:15.169927', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3557, 0, '2011-10-10 14:13:16.276159', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3558, 0, '2011-10-10 14:13:26.913838', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3559, 0, '2011-10-10 14:13:31.406887', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3560, 0, '2011-10-10 14:13:33.790754', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3561, 0, '2011-10-10 14:13:36.374455', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3562, 0, '2011-10-10 14:13:42.536173', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3563, 0, '2011-10-10 14:13:43.334743', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3564, 0, '2011-10-10 14:13:44.949994', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3565, 0, '2011-10-10 14:13:46.465505', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3566, 0, '2011-10-10 14:13:47.665382', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3567, 0, '2011-10-10 14:13:52.798274', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3568, 0, '2011-10-10 14:13:54.464316', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3569, 0, '2011-10-10 14:13:57.750371', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3570, 0, '2011-10-10 14:14:00.062682', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3571, 0, '2011-10-10 14:14:01.246382', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3572, 0, '2011-10-10 14:14:02.143783', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3573, 0, '2011-10-10 14:14:03.053966', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3574, 0, '2011-10-10 14:14:05.236548', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3575, 0, '2011-10-10 14:14:07.694837', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3576, 0, '2011-10-10 14:14:12.482617', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3577, 0, '2011-10-10 14:14:13.766852', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3578, 0, '2011-10-10 14:14:16.144939', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3579, 0, '2011-10-10 14:14:22.859964', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3580, 0, '2011-10-10 14:15:00.099984', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3581, 0, '2011-10-10 14:15:05.656662', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3582, 0, '2011-10-10 14:15:08.702544', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3583, 0, '2011-10-10 14:15:13.551799', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3584, 0, '2011-10-10 14:15:15.17663', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3585, 0, '2011-10-10 14:15:16.167507', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3586, 0, '2011-10-10 14:15:55.596059', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3588, 0, '2011-10-10 16:12:14.935678', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3589, 0, '2011-10-10 16:12:17.998941', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3590, 0, '2011-10-10 16:12:20.24181', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3591, 0, '2011-10-10 16:13:31.156488', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3592, 0, '2011-10-10 16:13:35.945013', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3593, 0, '2011-10-10 16:22:04.671644', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3587, 0, '2011-10-10 16:12:14.938463', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3595, 0, '2011-10-10 16:56:27.296781', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3594, 0, '2011-10-10 16:56:27.296782', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3596, 0, '2011-10-10 16:56:32.421551', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3597, 0, '2011-10-10 16:58:01.14937', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3598, 0, '2011-10-10 17:17:52.405341', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3600, 0, '2011-10-11 09:58:43.030732', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3599, 0, '2011-10-11 09:58:43.033847', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3601, 0, '2011-10-11 09:58:46.76802', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3602, 0, '2011-10-11 10:02:30.62367', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3603, 0, '2011-10-11 10:02:30.637737', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3604, 0, '2011-10-11 10:02:53.080498', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3605, 0, '2011-10-11 10:03:15.530782', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3606, 0, '2011-10-11 10:03:18.990669', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3607, 0, '2011-10-11 10:03:19.598552', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3608, 0, '2011-10-11 10:03:24.893978', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3609, 0, '2011-10-11 10:03:24.897567', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3610, 0, '2011-10-11 10:03:27.161927', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3611, 0, '2011-10-11 10:12:41.001825', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3612, 0, '2011-10-11 10:23:28.331269', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3613, 0, '2011-10-11 10:24:11.108889', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3614, 0, '2011-10-11 10:29:17.518436', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3615, 0, '2011-10-11 10:29:19.015673', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3616, 0, '2011-10-11 10:30:21.151165', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3617, 0, '2011-10-11 10:30:22.580979', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3618, 0, '2011-10-11 10:30:26.487879', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3619, 0, '2011-10-11 10:30:27.852223', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3620, 0, '2011-10-11 10:30:29.518665', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3621, 0, '2011-10-11 10:30:30.901413', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3622, 0, '2011-10-11 10:30:31.839268', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3623, 0, '2011-10-11 10:30:33.442035', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3624, 0, '2011-10-11 10:30:34.81205', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3625, 0, '2011-10-11 10:30:39.202448', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3626, 0, '2011-10-11 10:30:42.279001', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3627, 0, '2011-10-11 10:30:47.186284', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3628, 0, '2011-10-11 10:30:48.634505', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3629, 0, '2011-10-11 10:47:42.299144', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3630, 0, '2011-10-11 10:47:43.180632', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3631, 0, '2011-10-11 10:48:45.889602', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3632, 0, '2011-10-11 10:49:27.193997', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3633, 0, '2011-10-11 10:49:28.615669', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3634, 0, '2011-10-11 10:49:29.498095', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3635, 0, '2011-10-11 10:49:30.984537', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3636, 0, '2011-10-11 10:49:31.812143', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3637, 0, '2011-10-11 10:49:34.881428', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3638, 0, '2011-10-11 10:49:35.800021', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3639, 0, '2011-10-11 10:49:41.022175', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3640, 0, '2011-10-11 10:49:46.288841', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3642, 0, '2011-10-12 09:34:22.190032', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3641, 0, '2011-10-12 09:34:22.190034', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3643, 0, '2011-10-12 09:34:41.46742', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3644, 0, '2011-10-12 09:34:54.887782', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3645, 0, '2011-10-12 09:34:58.474822', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3646, 0, '2011-10-12 09:35:58.240291', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3647, 0, '2011-10-12 09:35:59.242295', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3648, 0, '2011-10-12 09:36:00.011605', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3649, 0, '2011-10-12 09:39:48.680193', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3650, 0, '2011-10-12 09:39:49.92162', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3651, 0, '2011-10-12 09:39:57.295045', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3652, 0, '2011-10-12 09:40:02.388336', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3653, 0, '2011-10-12 09:40:16.660732', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3654, 0, '2011-10-12 09:46:50.659148', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3655, 0, '2011-10-12 09:46:52.629269', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3656, 0, '2011-10-12 09:47:10.479374', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3657, 0, '2011-10-12 09:47:13.923042', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3658, 0, '2011-10-12 09:47:26.462906', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3659, 0, '2011-10-12 09:47:29.714045', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3660, 0, '2011-10-12 09:47:43.315338', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3661, 0, '2011-10-12 09:47:45.484408', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3662, 0, '2011-10-12 09:47:48.010391', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3663, 0, '2011-10-12 09:47:51.641075', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3664, 0, '2011-10-12 09:49:53.897801', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3665, 0, '2011-10-12 09:49:59.2019', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3666, 0, '2011-10-12 09:50:05.090289', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3667, 0, '2011-10-12 09:50:06.39178', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3668, 0, '2011-10-12 09:52:06.559101', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3669, 0, '2011-10-12 09:52:08.293567', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3670, 0, '2011-10-12 09:52:13.623621', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3671, 0, '2011-10-12 09:52:24.611334', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3672, 0, '2011-10-12 09:52:26.651351', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3673, 0, '2011-10-12 09:52:28.975244', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3674, 0, '2011-10-12 09:54:42.599285', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3675, 0, '2011-10-12 09:55:34.325138', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3676, 0, '2011-10-12 09:57:12.620537', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3677, 0, '2011-10-12 09:57:53.741726', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3678, 0, '2011-10-12 09:58:00.690885', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3679, 0, '2011-10-12 09:58:42.370747', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3680, 0, '2011-10-12 09:59:56.49848', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3681, 0, '2011-10-12 09:59:58.590375', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3682, 0, '2011-10-12 10:00:01.392798', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3683, 0, '2011-10-12 10:00:04.415745', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3684, 0, '2011-10-12 10:00:09.871078', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3685, 0, '2011-10-12 10:00:12.918709', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3686, 0, '2011-10-12 10:00:28.580356', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3687, 0, '2011-10-12 10:00:46.702759', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3688, 0, '2011-10-12 10:00:53.303008', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3689, 0, '2011-10-12 10:01:50.429276', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3690, 0, '2011-10-12 10:02:27.389162', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3691, 0, '2011-10-12 10:04:17.545754', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3692, 0, '2011-10-12 10:04:48.793359', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3693, 0, '2011-10-12 10:04:51.814787', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3694, 0, '2011-10-12 10:04:54.152766', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3695, 0, '2011-10-12 10:04:57.448303', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3696, 0, '2011-10-12 10:04:57.527181', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3697, 0, '2011-10-12 10:05:00.069183', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3698, 0, '2011-10-12 10:05:33.641347', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3699, 0, '2011-10-12 10:06:06.470016', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3700, 0, '2011-10-12 10:06:06.47863', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3701, 0, '2011-10-12 10:06:08.570039', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3702, 0, '2011-10-12 10:06:15.657277', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3703, 0, '2011-10-12 10:06:27.590053', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3704, 0, '2011-10-12 10:06:32.246145', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3705, 0, '2011-10-12 10:06:34.28191', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3706, 0, '2011-10-12 10:10:07.144669', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3707, 0, '2011-10-12 10:10:08.562135', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3708, 0, '2011-10-12 10:10:11.097559', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3709, 0, '2011-10-12 10:10:32.683427', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3710, 0, '2011-10-12 10:10:36.82579', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3711, 0, '2011-10-12 10:10:40.401059', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3712, 0, '2011-10-12 10:10:41.321975', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3713, 0, '2011-10-12 10:11:39.983214', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3714, 0, '2011-10-12 10:12:54.571241', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3715, 0, '2011-10-12 10:12:57.569972', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3716, 0, '2011-10-12 10:13:00.683935', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3717, 0, '2011-10-12 10:13:03.323765', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3718, 0, '2011-10-12 10:13:07.31695', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3719, 0, '2011-10-12 10:13:08.751666', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3720, 0, '2011-10-12 10:13:11.004342', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3721, 0, '2011-10-12 10:16:31.497711', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3722, 0, '2011-10-12 10:16:32.667762', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3723, 0, '2011-10-12 10:16:37.965925', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3724, 0, '2011-10-12 10:17:09.844534', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3725, 0, '2011-10-12 10:17:12.162874', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3726, 0, '2011-10-12 10:17:26.192107', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3727, 0, '2011-10-12 10:17:39.090821', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3728, 0, '2011-10-12 10:17:45.760747', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3729, 0, '2011-10-12 10:18:18.92752', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3730, 0, '2011-10-12 10:18:20.988054', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3731, 0, '2011-10-12 10:18:22.880512', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3732, 0, '2011-10-12 10:18:31.851318', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3733, 0, '2011-10-12 10:18:36.17468', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3734, 0, '2011-10-12 10:24:39.489919', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3735, 0, '2011-10-12 10:24:42.039124', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3736, 0, '2011-10-12 10:26:50.42736', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3737, 0, '2011-10-12 10:26:51.211464', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3738, 0, '2011-10-12 10:28:49.71288', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3739, 0, '2011-10-12 10:28:59.743184', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3740, 0, '2011-10-12 10:29:43.599205', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3741, 0, '2011-10-12 10:31:09.712326', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3742, 0, '2011-10-12 10:31:12.575607', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3743, 0, '2011-10-12 10:31:34.081488', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3744, 0, '2011-10-12 10:31:39.279877', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3745, 0, '2011-10-12 10:32:14.999739', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3746, 0, '2011-10-12 10:32:17.838257', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3747, 0, '2011-10-12 10:32:20.294384', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3748, 0, '2011-10-12 10:32:32.75791', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3749, 0, '2011-10-12 10:32:35.244394', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3750, 0, '2011-10-12 10:32:42.935958', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3751, 0, '2011-10-12 10:32:51.018314', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3752, 0, '2011-10-12 10:32:59.579089', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3753, 0, '2011-10-12 10:33:02.58296', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3754, 0, '2011-10-12 10:33:05.709045', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3755, 0, '2011-10-12 10:33:09.400764', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3756, 0, '2011-10-12 10:33:20.242795', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3757, 0, '2011-10-12 10:33:42.687156', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3758, 0, '2011-10-12 10:33:52.165035', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3759, 0, '2011-10-12 10:33:57.375266', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3760, 0, '2011-10-12 10:34:00.690903', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3761, 0, '2011-10-12 10:34:22.645594', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3762, 0, '2011-10-12 10:34:24.97972', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3763, 0, '2011-10-12 10:34:30.11565', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3764, 0, '2011-10-12 10:34:32.183757', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3765, 0, '2011-10-12 10:34:33.653977', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3766, 0, '2011-10-12 10:34:36.244322', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3767, 0, '2011-10-12 10:34:38.655047', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3768, 0, '2011-10-12 10:34:41.872602', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3769, 0, '2011-10-12 10:34:43.704086', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3770, 0, '2011-10-12 10:34:50.016019', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3771, 0, '2011-10-12 10:34:52.463177', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3772, 0, '2011-10-12 10:35:14.135328', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3773, 0, '2011-10-12 10:35:19.82824', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3774, 0, '2011-10-12 10:35:22.64098', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3775, 0, '2011-10-12 10:35:26.969275', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3776, 0, '2011-10-12 10:35:43.691165', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3777, 0, '2011-10-12 10:35:46.086672', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3778, 0, '2011-10-12 10:35:52.152495', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3779, 0, '2011-10-12 10:35:53.727738', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3780, 0, '2011-10-12 10:35:57.122333', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3781, 0, '2011-10-12 10:36:18.068812', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3782, 0, '2011-10-12 10:36:23.703053', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3783, 0, '2011-10-12 10:36:33.410672', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3784, 0, '2011-10-12 10:36:40.879175', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3785, 0, '2011-10-12 10:36:48.801197', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3786, 0, '2011-10-12 10:37:12.570728', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3787, 0, '2011-10-12 10:37:22.841321', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3788, 0, '2011-10-12 10:37:24.947803', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3789, 0, '2011-10-12 10:37:31.552032', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3790, 0, '2011-10-12 10:37:33.632183', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3791, 0, '2011-10-12 10:37:35.653442', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3792, 0, '2011-10-12 10:37:59.897871', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3793, 0, '2011-10-12 10:38:05.923818', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3794, 0, '2011-10-12 10:38:08.64504', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3795, 0, '2011-10-12 10:38:09.062434', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3796, 0, '2011-10-12 10:39:13.644643', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3797, 0, '2011-10-12 10:39:46.505107', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3798, 0, '2011-10-12 10:40:47.455116', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3799, 0, '2011-10-12 10:56:28.44804', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3800, 0, '2011-10-12 10:56:28.453707', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3801, 0, '2011-10-12 10:56:31.512706', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3802, 0, '2011-10-12 10:56:36.216341', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3803, 0, '2011-10-12 10:56:42.767395', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3804, 0, '2011-10-12 10:56:47.579549', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3805, 0, '2011-10-12 10:56:49.90313', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3806, 0, '2011-10-12 10:58:41.835767', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3807, 0, '2011-10-12 10:58:45.223354', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3808, 0, '2011-10-12 10:58:48.13061', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3809, 0, '2011-10-12 10:58:53.133638', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3810, 0, '2011-10-12 10:58:57.290202', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3811, 0, '2011-10-12 11:00:45.383056', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3812, 0, '2011-10-12 11:00:48.490593', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3813, 0, '2011-10-12 11:00:50.408182', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3814, 0, '2011-10-12 11:00:54.463332', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3815, 0, '2011-10-12 11:00:57.683518', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3816, 0, '2011-10-12 11:00:59.740237', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3817, 0, '2011-10-12 11:01:03.001568', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3818, 0, '2011-10-12 11:01:06.284417', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3819, 0, '2011-10-12 11:01:32.592256', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3820, 0, '2011-10-12 11:01:34.615419', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3821, 0, '2011-10-12 11:01:36.570885', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3822, 0, '2011-10-12 11:01:42.001914', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3823, 0, '2011-10-12 11:01:43.947567', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3824, 0, '2011-10-12 11:01:46.48183', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3825, 0, '2011-10-12 11:01:48.893175', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3826, 0, '2011-10-12 11:01:51.855606', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3827, 0, '2011-10-12 11:01:54.262792', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3828, 0, '2011-10-12 11:02:00.931661', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3829, 0, '2011-10-12 11:02:10.250652', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3830, 0, '2011-10-12 11:02:15.392505', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3831, 0, '2011-10-12 11:02:16.618989', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3832, 0, '2011-10-12 11:02:27.713058', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3833, 0, '2011-10-12 11:02:43.103289', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3834, 0, '2011-10-12 11:04:01.783321', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3835, 0, '2011-10-12 11:04:11.869442', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3836, 0, '2011-10-12 11:04:52.26727', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3837, 0, '2011-10-12 11:05:07.832559', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3838, 0, '2011-10-12 11:05:10.480807', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3839, 0, '2011-10-12 11:05:14.609963', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3840, 0, '2011-10-12 11:05:18.584401', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3841, 0, '2011-10-12 11:05:54.43918', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3842, 0, '2011-10-12 11:05:57.81315', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3843, 0, '2011-10-12 11:06:38.832092', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3844, 0, '2011-10-12 11:06:40.662733', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3845, 0, '2011-10-12 11:07:08.054371', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3846, 0, '2011-10-12 11:07:22.561077', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3847, 0, '2011-10-12 11:07:26.592625', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3848, 0, '2011-10-12 11:07:29.250602', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3849, 0, '2011-10-12 11:07:33.266561', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3850, 0, '2011-10-12 11:07:38.419617', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3851, 0, '2011-10-12 11:07:43.539525', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3852, 0, '2011-10-12 11:07:45.28803', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3853, 0, '2011-10-12 11:07:58.369845', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3854, 0, '2011-10-12 11:08:04.241338', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3855, 0, '2011-10-12 11:08:07.231555', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3856, 0, '2011-10-12 11:08:10.250992', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3857, 0, '2011-10-12 11:08:14.280951', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3858, 0, '2011-10-12 11:08:18.828508', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3859, 0, '2011-10-12 11:08:21.422883', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3860, 0, '2011-10-12 11:08:24.222657', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3861, 0, '2011-10-12 11:08:26.03276', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3862, 0, '2011-10-12 11:08:58.383042', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3863, 0, '2011-10-12 11:09:06.36133', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3864, 0, '2011-10-12 11:18:09.237762', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3865, 0, '2011-10-12 11:31:30.153999', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3866, 0, '2011-10-12 11:32:19.283075', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3867, 0, '2011-10-12 11:32:22.162514', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3868, 0, '2011-10-12 11:32:23.009807', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3869, 0, '2011-10-12 11:34:30.090578', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3870, 0, '2011-10-12 11:34:40.516818', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3871, 0, '2011-10-12 11:34:47.011951', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3872, 0, '2011-10-12 11:34:48.721842', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3873, 0, '2011-10-12 11:34:52.792473', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3874, 0, '2011-10-12 11:34:59.176616', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3875, 0, '2011-10-12 11:35:01.664414', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3876, 0, '2011-10-12 11:35:08.370387', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3877, 0, '2011-10-12 11:35:10.193148', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3878, 0, '2011-10-12 11:35:12.570009', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3879, 0, '2011-10-12 11:47:54.362889', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3880, 0, '2011-10-12 11:47:56.866282', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3881, 0, '2011-10-12 11:47:59.340677', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3882, 0, '2011-10-12 11:48:11.773969', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3883, 0, '2011-10-12 11:50:29.859956', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3884, 0, '2011-10-12 11:50:32.159616', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3885, 0, '2011-10-12 11:50:37.673414', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3886, 0, '2011-10-12 11:50:39.964263', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3887, 0, '2011-10-12 11:55:36.419774', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3888, 0, '2011-10-12 11:55:38.665706', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3889, 0, '2011-10-12 11:55:43.526473', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3890, 0, '2011-10-12 11:55:46.699443', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3891, 0, '2011-10-12 11:56:36.268839', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3892, 0, '2011-10-12 11:56:36.601145', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3893, 0, '2011-10-12 11:57:11.57254', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3894, 0, '2011-10-12 11:57:14.767606', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3895, 0, '2011-10-12 11:57:17.845207', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3896, 0, '2011-10-12 11:57:18.088707', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3897, 0, '2011-10-12 11:59:33.491185', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3898, 0, '2011-10-12 11:59:37.700901', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3899, 0, '2011-10-12 11:59:42.260361', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3900, 0, '2011-10-12 11:59:42.615926', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3901, 0, '2011-10-12 12:00:29.752997', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3902, 0, '2011-10-12 12:00:32.378009', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3903, 0, '2011-10-12 12:00:37.204176', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3904, 0, '2011-10-12 12:00:43.71504', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3905, 0, '2011-10-12 12:00:46.988591', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3906, 0, '2011-10-12 12:00:52.461286', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3907, 0, '2011-10-12 12:00:55.200977', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3908, 0, '2011-10-12 12:00:57.501315', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3909, 0, '2011-10-12 12:01:04.87631', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3910, 0, '2011-10-12 12:01:05.907544', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3911, 0, '2011-10-12 12:01:09.761977', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3912, 0, '2011-10-12 12:01:30.809426', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3913, 0, '2011-10-12 12:01:40.588641', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3914, 0, '2011-10-12 12:01:44.722165', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3915, 0, '2011-10-12 12:03:02.762952', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3916, 0, '2011-10-12 12:03:04.713449', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3917, 0, '2011-10-12 12:03:09.48185', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3918, 0, '2011-10-12 12:05:07.825839', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3919, 0, '2011-10-12 12:05:10.121484', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3920, 0, '2011-10-12 12:05:19.081595', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3921, 0, '2011-10-12 12:05:19.353777', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3922, 0, '2011-10-12 12:07:27.564391', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3923, 0, '2011-10-12 12:07:32.3255', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3924, 0, '2011-10-12 12:07:33.897664', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3925, 0, '2011-10-12 12:07:35.042891', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3926, 0, '2011-10-12 12:07:44.287821', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3927, 0, '2011-10-12 12:07:47.023919', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3928, 0, '2011-10-12 12:07:48.844449', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3929, 0, '2011-10-12 12:07:52.150855', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3930, 0, '2011-10-12 12:07:54.57847', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3931, 0, '2011-10-12 12:08:04.152894', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3932, 0, '2011-10-12 12:08:06.105293', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3933, 0, '2011-10-12 12:08:07.246326', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3934, 0, '2011-10-12 12:08:09.045723', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3935, 0, '2011-10-12 12:08:10.421187', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3936, 0, '2011-10-12 12:08:18.717539', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3937, 0, '2011-10-12 12:08:21.460533', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3938, 0, '2011-10-12 14:45:48.86434', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3939, 0, '2011-10-12 14:45:48.865669', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3940, 0, '2011-10-12 14:45:58.938305', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3941, 0, '2011-10-12 14:46:08.780026', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3942, 0, '2011-10-12 14:47:16.734629', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3943, 0, '2011-10-12 14:47:36.501836', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3944, 0, '2011-10-12 14:47:50.373917', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3945, 0, '2011-10-12 14:47:58.942823', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3946, 0, '2011-10-12 14:48:05.751601', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3947, 0, '2011-10-12 14:48:13.050182', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3948, 0, '2011-10-12 14:48:30.581304', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3949, 0, '2011-10-12 14:48:31.812558', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3950, 0, '2011-10-12 14:48:33.990487', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3951, 0, '2011-10-12 14:48:34.871119', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3952, 0, '2011-10-12 14:48:37.728676', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3953, 0, '2011-10-12 14:48:47.043133', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3954, 0, '2011-10-12 14:48:53.164374', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3955, 0, '2011-10-12 14:49:28.536929', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3956, 0, '2011-10-12 14:49:44.079944', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3957, 0, '2011-10-12 14:49:46.471112', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3958, 0, '2011-10-12 14:49:52.427565', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3959, 0, '2011-10-12 14:49:57.861627', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3960, 0, '2011-10-12 14:49:59.032349', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3961, 0, '2011-10-12 14:50:06.649212', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3962, 0, '2011-10-12 14:50:21.756127', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3963, 0, '2011-10-12 14:50:24.333487', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3964, 0, '2011-10-12 14:50:30.110905', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3965, 0, '2011-10-12 14:50:46.501511', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3966, 0, '2011-10-12 14:50:51.378263', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3967, 0, '2011-10-12 14:50:54.657586', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3968, 0, '2011-10-12 14:50:57.920104', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3969, 0, '2011-10-12 14:51:04.988757', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3970, 0, '2011-10-12 14:51:10.963303', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3971, 0, '2011-10-12 14:51:14.178313', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3972, 0, '2011-10-12 14:51:16.676093', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3973, 0, '2011-10-12 14:51:22.591265', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3974, 0, '2011-10-12 14:51:24.337343', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3975, 0, '2011-10-12 14:53:44.191258', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3976, 0, '2011-10-12 14:53:48.740989', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3977, 0, '2011-10-12 14:54:10.241009', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3978, 0, '2011-10-12 14:56:13.731213', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3979, 0, '2011-10-12 14:56:23.528762', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3980, 0, '2011-10-12 14:56:26.05534', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3981, 0, '2011-10-12 14:58:51.163919', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3982, 0, '2011-10-12 14:58:57.455653', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3983, 0, '2011-10-12 14:59:18.539112', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3984, 0, '2011-10-12 14:59:21.315783', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3985, 0, '2011-10-12 14:59:31.711244', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3986, 0, '2011-10-12 14:59:38.240109', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3987, 0, '2011-10-12 14:59:40.590984', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3988, 0, '2011-10-12 14:59:42.026605', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3989, 0, '2011-10-12 14:59:44.517645', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3990, 0, '2011-10-12 14:59:49.284767', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3991, 0, '2011-10-12 15:00:02.230819', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3992, 0, '2011-10-12 15:00:16.403291', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3993, 0, '2011-10-12 15:00:18.187718', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3994, 0, '2011-10-12 15:00:26.411893', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3995, 0, '2011-10-12 15:00:28.402902', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3996, 0, '2011-10-12 15:00:30.294345', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3997, 0, '2011-10-12 15:01:46.071089', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3998, 0, '2011-10-12 15:01:55.729245', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (3999, 0, '2011-10-12 15:01:57.029289', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4000, 0, '2011-10-12 15:02:25.178324', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4001, 0, '2011-10-12 15:02:34.223131', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4002, 0, '2011-10-12 15:02:46.205456', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4003, 0, '2011-10-12 15:02:54.532614', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4004, 0, '2011-10-12 15:03:08.281858', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4005, 0, '2011-10-12 15:03:11.545638', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4006, 0, '2011-10-12 15:03:16.294874', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4007, 0, '2011-10-12 15:03:18.482906', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4008, 0, '2011-10-12 15:03:32.199635', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4009, 0, '2011-10-12 15:03:58.202295', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4010, 0, '2011-10-12 15:04:03.111974', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4011, 0, '2011-10-12 15:07:05.259654', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4012, 0, '2011-10-12 15:07:08.735323', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4013, 0, '2011-10-12 15:09:45.867517', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4014, 0, '2011-10-12 15:09:50.867621', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4015, 0, '2011-10-12 15:10:39.982416', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4016, 0, '2011-10-12 15:11:03.941784', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4017, 0, '2011-10-12 15:11:21.21832', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4018, 0, '2011-10-12 15:11:22.833761', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4019, 0, '2011-10-12 15:11:33.8278', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4020, 0, '2011-10-12 15:11:38.985878', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4021, 0, '2011-10-12 15:11:52.332259', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4022, 0, '2011-10-12 15:11:54.861241', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4023, 0, '2011-10-12 15:11:56.243118', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4024, 0, '2011-10-12 15:12:07.250067', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4025, 0, '2011-10-12 15:12:57.311792', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4026, 0, '2011-10-12 15:16:43.747667', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4027, 0, '2011-10-12 15:16:46.408269', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4028, 0, '2011-10-12 15:17:07.265708', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4029, 0, '2011-10-12 15:17:14.631033', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4030, 0, '2011-10-12 15:17:29.365306', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4031, 0, '2011-10-12 15:17:35.135188', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4032, 0, '2011-10-12 15:17:50.031243', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4033, 0, '2011-10-12 15:19:19.289355', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4034, 0, '2011-10-12 15:20:43.663147', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4035, 0, '2011-10-12 15:20:52.912082', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4036, 0, '2011-10-12 15:21:02.05805', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4037, 0, '2011-10-12 15:21:03.852257', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4038, 0, '2011-10-12 15:21:05.331718', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4039, 0, '2011-10-12 15:21:30.98308', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4040, 0, '2011-10-12 15:22:08.209346', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4041, 0, '2011-10-12 15:23:15.077202', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4042, 0, '2011-10-12 15:24:06.26929', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4043, 0, '2011-10-12 15:24:08.100852', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4044, 0, '2011-10-12 15:25:56.789426', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4045, 0, '2011-10-12 15:26:01.136075', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4046, 0, '2011-10-12 15:26:21.181965', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4047, 0, '2011-10-12 15:26:28.29317', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4048, 0, '2011-10-12 15:38:08.983518', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4049, 0, '2011-10-12 15:38:11.337596', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4050, 0, '2011-10-12 15:38:15.518138', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4051, 0, '2011-10-12 15:38:17.78312', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4052, 0, '2011-10-12 15:38:19.843289', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4053, 0, '2011-10-12 15:38:27.466391', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4054, 0, '2011-10-12 15:38:28.947485', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4055, 0, '2011-10-12 15:39:46.732514', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4056, 0, '2011-10-12 15:40:01.506209', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4057, 0, '2011-10-12 15:40:01.567593', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4058, 0, '2011-10-12 15:42:05.918251', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4059, 0, '2011-10-12 15:42:09.661672', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4060, 0, '2011-10-12 15:42:29.901815', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4061, 0, '2011-10-12 15:43:06.132915', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4062, 0, '2011-10-12 15:46:06.637161', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4063, 0, '2011-10-12 15:46:40.857123', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4064, 0, '2011-10-12 15:48:14.281014', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4065, 0, '2011-10-12 15:57:20.881783', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4066, 0, '2011-10-12 15:57:24.685981', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4067, 0, '2011-10-12 15:57:26.984764', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4068, 0, '2011-10-12 15:57:40.950857', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4069, 0, '2011-10-12 15:57:43.088949', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4070, 0, '2011-10-12 15:57:48.972678', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4071, 0, '2011-10-12 15:57:51.603195', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4072, 0, '2011-10-12 15:57:56.24142', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4073, 0, '2011-10-12 15:57:57.768632', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4074, 0, '2011-10-12 15:58:08.767718', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4075, 0, '2011-10-12 15:58:16.901513', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4076, 0, '2011-10-12 15:58:26.102375', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4077, 0, '2011-10-12 15:58:28.301536', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4078, 0, '2011-10-12 15:58:32.791161', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4079, 0, '2011-10-12 15:58:53.040077', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4080, 0, '2011-10-12 16:01:56.503557', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4081, 0, '2011-10-12 16:03:01.503989', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4082, 0, '2011-10-12 16:12:23.164736', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4083, 0, '2011-10-12 16:12:32.220981', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4084, 0, '2011-10-12 16:12:43.440375', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4085, 0, '2011-10-12 16:12:45.168339', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4086, 0, '2011-10-12 16:12:56.073868', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4087, 0, '2011-10-12 16:13:09.807671', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4088, 0, '2011-10-12 16:13:23.967752', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4089, 0, '2011-10-12 16:13:39.081469', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4090, 0, '2011-10-12 16:14:04.645019', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4091, 0, '2011-10-12 16:14:07.129847', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4092, 0, '2011-10-12 16:14:37.858605', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4093, 0, '2011-10-12 16:15:08.348576', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4094, 0, '2011-10-12 16:15:12.831252', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4095, 0, '2011-10-12 16:15:14.589218', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4096, 0, '2011-10-12 16:15:38.619446', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4097, 0, '2011-10-12 16:15:43.813684', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4098, 0, '2011-10-12 16:16:33.858705', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4099, 0, '2011-10-12 16:17:33.081375', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4100, 0, '2011-10-12 16:17:43.627924', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4101, 0, '2011-10-12 16:17:48.422006', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4102, 0, '2011-10-12 16:17:52.880221', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4103, 0, '2011-10-12 16:17:57.808076', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4104, 0, '2011-10-12 16:17:58.155053', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4105, 0, '2011-10-12 16:27:12.850693', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4106, 0, '2011-10-12 16:27:33.747709', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4107, 0, '2011-10-12 16:27:46.179107', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4108, 0, '2011-10-12 16:29:28.261388', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4109, 0, '2011-10-12 16:29:45.799952', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4110, 0, '2011-10-12 16:29:50.551882', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4111, 0, '2011-10-12 16:31:50.441096', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4112, 0, '2011-10-12 16:31:57.527993', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4113, 0, '2011-10-12 16:31:59.052524', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4114, 0, '2011-10-12 16:38:34.040712', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4115, 0, '2011-10-12 16:38:36.50787', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4116, 0, '2011-10-12 16:38:42.146699', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4117, 0, '2011-10-12 16:39:02.062097', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4118, 0, '2011-10-12 16:39:36.618888', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4119, 0, '2011-10-12 16:39:40.302856', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4120, 0, '2011-10-12 16:39:50.902552', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4121, 0, '2011-10-12 16:39:54.28644', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4122, 0, '2011-10-12 16:39:55.521069', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4123, 0, '2011-10-12 16:40:01.853067', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4124, 0, '2011-10-12 16:40:05.624888', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4125, 0, '2011-10-12 16:40:16.204923', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4126, 0, '2011-10-12 16:40:28.039781', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4127, 0, '2011-10-12 16:41:01.800064', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4128, 0, '2011-10-12 16:41:08.710818', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4129, 0, '2011-10-12 16:41:17.802616', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4130, 0, '2011-10-12 16:41:37.818617', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4131, 0, '2011-10-12 16:41:41.649385', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4132, 0, '2011-10-12 16:41:59.035571', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4133, 0, '2011-10-12 16:42:04.026973', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4134, 0, '2011-10-12 16:42:05.577277', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4135, 0, '2011-10-12 16:42:13.730444', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4136, 0, '2011-10-12 16:42:15.150293', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4137, 0, '2011-10-12 16:42:16.320551', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4138, 0, '2011-10-12 16:42:17.626973', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4139, 0, '2011-10-12 16:42:28.91832', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4140, 0, '2011-10-12 16:47:02.519942', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4141, 0, '2011-10-12 16:47:30.050843', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4142, 0, '2011-10-12 16:47:35.387994', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4143, 0, '2011-10-12 16:47:42.424303', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4144, 0, '2011-10-12 16:47:43.807778', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4145, 0, '2011-10-12 16:47:44.675271', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4146, 0, '2011-10-12 16:47:45.369002', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4147, 0, '2011-10-12 16:47:46.319452', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4148, 0, '2011-10-12 16:47:48.057638', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4149, 0, '2011-10-12 16:47:54.049769', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4150, 0, '2011-10-12 16:47:57.950881', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4151, 0, '2011-10-12 16:48:01.498306', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4152, 0, '2011-10-12 16:48:54.751207', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4153, 0, '2011-10-12 16:49:12.270967', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4154, 0, '2011-10-12 16:49:27.259403', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4155, 0, '2011-10-12 16:49:37.854624', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4156, 0, '2011-10-12 16:49:55.498894', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4157, 0, '2011-10-12 16:50:13.710914', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4158, 0, '2011-10-12 16:50:16.43767', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4159, 0, '2011-10-12 16:50:26.194838', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4160, 0, '2011-10-12 16:50:28.741611', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4161, 0, '2011-10-12 16:50:49.80299', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4162, 0, '2011-10-12 16:50:50.623247', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4163, 0, '2011-10-12 16:50:52.866606', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4164, 0, '2011-10-12 16:50:59.66743', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4165, 0, '2011-10-12 16:53:02.982305', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4166, 0, '2011-10-12 16:53:04.871501', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4167, 0, '2011-10-12 16:53:30.182522', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4168, 0, '2011-10-12 16:53:40.200154', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4169, 0, '2011-10-12 16:53:47.030743', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4170, 0, '2011-10-12 16:53:48.49745', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4171, 0, '2011-10-12 16:53:57.569291', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4172, 0, '2011-10-12 16:55:05.357577', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4173, 0, '2011-10-12 16:55:13.282638', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4174, 0, '2011-10-12 16:55:19.013011', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4175, 0, '2011-10-12 16:55:24.673486', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4176, 0, '2011-10-12 16:55:26.738079', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4177, 0, '2011-10-12 16:55:28.538712', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4178, 0, '2011-10-12 16:55:38.835121', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4179, 0, '2011-10-12 16:56:06.401887', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4180, 0, '2011-10-12 16:56:57.351253', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4181, 0, '2011-10-12 16:57:14.014274', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4182, 0, '2011-10-12 16:57:18.538538', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4183, 0, '2011-10-12 16:57:28.240522', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4184, 0, '2011-10-12 16:57:33.039882', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4185, 0, '2011-10-12 16:58:56.46697', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4186, 0, '2011-10-12 16:59:21.348212', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4187, 0, '2011-10-12 16:59:23.088868', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4188, 0, '2011-10-12 16:59:44.97114', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4189, 0, '2011-10-12 16:59:56.830488', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4190, 0, '2011-10-12 17:00:09.555309', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4191, 0, '2011-10-12 17:00:11.318102', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4192, 0, '2011-10-12 17:00:15.149424', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4193, 0, '2011-10-12 17:00:19.211137', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4194, 0, '2011-10-12 17:00:21.304016', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4195, 0, '2011-10-12 17:02:03.599602', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4196, 0, '2011-10-12 17:02:07.733044', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4197, 0, '2011-10-12 17:02:11.589612', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4198, 0, '2011-10-12 17:04:50.323612', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4199, 0, '2011-10-12 17:05:32.620135', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4200, 0, '2011-10-12 17:05:40.315256', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4201, 0, '2011-10-12 17:06:14.380655', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4202, 0, '2011-10-12 17:07:03.775179', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4203, 0, '2011-10-12 17:07:11.520759', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4204, 0, '2011-10-12 17:07:28.181175', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4205, 0, '2011-10-12 17:11:20.811934', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4206, 0, '2011-10-12 17:11:53.766165', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4208, 0, '2011-10-18 11:06:47.902482', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4207, 0, '2011-10-18 11:06:47.905258', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4209, 0, '2011-10-18 11:07:03.524998', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4210, 0, '2011-10-18 11:07:06.794156', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4211, 0, '2011-10-18 11:07:09.147075', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4212, 0, '2011-10-18 11:07:33.595145', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4213, 0, '2011-10-18 11:07:35.83069', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4214, 0, '2011-10-18 11:07:37.76179', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4215, 0, '2011-10-18 11:07:38.896133', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4216, 0, '2011-10-18 11:07:45.608032', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4217, 0, '2011-10-18 11:07:47.118403', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4218, 0, '2011-10-18 11:07:55.183652', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4219, 0, '2011-10-18 11:21:42.71078', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4220, 0, '2011-10-18 11:21:44.559323', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4221, 0, '2011-10-18 11:21:46.660676', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4222, 0, '2011-10-18 11:21:47.796917', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4223, 0, '2011-10-18 11:21:51.313376', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4224, 0, '2011-10-18 11:21:55.517263', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4225, 0, '2011-10-18 11:21:57.564189', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4226, 0, '2011-10-18 11:21:59.453095', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4227, 0, '2011-10-18 11:22:17.466635', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4228, 0, '2011-10-18 11:22:20.219172', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4229, 0, '2011-10-18 11:22:22.311136', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4230, 0, '2011-10-18 11:22:24.887964', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4231, 0, '2011-10-18 11:22:34.568243', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4232, 0, '2011-10-18 11:22:37.003032', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4233, 0, '2011-10-18 11:22:42.802578', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4234, 0, '2011-10-18 11:22:47.820978', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4235, 0, '2011-10-18 11:23:02.965983', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4236, 0, '2011-10-18 11:23:12.363168', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4237, 0, '2011-10-18 11:23:17.937037', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4238, 0, '2011-10-18 11:23:23.300817', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4239, 0, '2011-10-18 11:23:25.010811', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4240, 0, '2011-10-18 11:23:58.27462', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4241, 0, '2011-10-18 11:24:03.839772', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4242, 0, '2011-10-18 11:26:38.381315', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4243, 0, '2011-10-18 11:26:41.607807', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4244, 0, '2011-10-18 11:29:24.122704', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4245, 0, '2011-10-18 11:29:25.770367', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4246, 0, '2011-10-18 11:29:27.060874', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4247, 0, '2011-10-18 11:29:29.236988', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4248, 0, '2011-10-18 11:29:30.826544', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4249, 0, '2011-10-18 11:29:32.728531', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4250, 0, '2011-10-18 11:29:34.511663', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4251, 0, '2011-10-18 11:29:37.208801', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4252, 0, '2011-10-18 11:29:38.925824', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4253, 0, '2011-10-18 11:29:50.169033', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4254, 0, '2011-10-18 11:30:25.661298', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4255, 0, '2011-10-18 11:30:27.630948', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4256, 0, '2011-10-18 11:30:29.218023', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4257, 0, '2011-10-18 11:30:32.75816', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4258, 0, '2011-10-18 11:30:34.549553', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4259, 0, '2011-10-18 11:30:36.180903', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4260, 0, '2011-10-18 11:30:44.137305', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4261, 0, '2011-10-18 11:30:45.981815', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4262, 0, '2011-10-18 11:30:48.259459', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4263, 0, '2011-10-18 11:30:50.717536', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4264, 0, '2011-10-18 11:30:52.367359', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4265, 0, '2011-10-18 11:32:39.985492', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4266, 0, '2011-10-18 11:32:42.308123', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4267, 0, '2011-10-18 11:32:59.025721', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4268, 0, '2011-10-18 11:33:02.206572', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4269, 0, '2011-10-18 11:33:04.109838', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4270, 0, '2011-10-18 11:33:05.544706', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4271, 0, '2011-10-18 11:33:06.927468', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4272, 0, '2011-10-18 11:33:09.356199', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4273, 0, '2011-10-18 11:33:12.509192', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4274, 0, '2011-10-18 11:33:14.645841', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4275, 0, '2011-10-18 11:33:16.07072', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4276, 0, '2011-10-18 11:33:20.128128', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4277, 0, '2011-10-18 11:33:21.377501', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4278, 0, '2011-10-18 11:33:24.051619', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4279, 0, '2011-10-18 11:33:26.987358', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4280, 0, '2011-10-18 11:33:33.746754', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4281, 0, '2011-10-18 11:33:36.113484', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4282, 0, '2011-10-18 11:33:41.01254', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4283, 0, '2011-10-18 11:35:08.808723', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4284, 0, '2011-10-18 11:35:10.93647', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4285, 0, '2011-10-18 11:35:11.575458', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4286, 0, '2011-10-18 11:35:13.33568', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4287, 0, '2011-10-18 11:35:17.651357', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4288, 0, '2011-10-18 11:35:22.819745', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4289, 0, '2011-10-18 11:37:05.014903', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4290, 0, '2011-10-18 11:37:05.51936', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4291, 0, '2011-10-18 11:37:08.981039', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4292, 0, '2011-10-18 11:37:10.448457', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4293, 0, '2011-10-18 11:37:13.96975', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4294, 0, '2011-10-18 11:37:15.003309', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4295, 0, '2011-10-18 11:37:18.122746', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4296, 0, '2011-10-18 11:37:21.581173', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4297, 0, '2011-10-18 11:37:22.81907', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4298, 0, '2011-10-18 11:37:26.873072', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4299, 0, '2011-10-18 11:37:28.818043', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4300, 0, '2011-10-18 11:37:30.469964', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4301, 0, '2011-10-18 11:46:55.319155', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4302, 0, '2011-10-18 11:47:08.069519', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4303, 0, '2011-10-18 11:47:09.549303', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4304, 0, '2011-10-18 11:47:13.238793', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4305, 0, '2011-10-18 11:47:14.256696', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4306, 0, '2011-10-18 11:47:15.635069', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4307, 0, '2011-10-18 11:47:23.420652', '0:0:0:0:0:0:0:1', NULL);
INSERT INTO sys_logins VALUES (4308, 0, '2011-10-18 11:47:27.497179', '0:0:0:0:0:0:0:1', NULL);


--
-- Data for Name: sys_news; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Data for Name: sys_passwords; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Data for Name: sys_queries; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Data for Name: tax; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO tax VALUES (1, 1, 'Withholding Tax', 10, NULL);


--
-- Data for Name: tax_category; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO tax_category VALUES (1, 'DEFAULT', NULL);


--
-- Data for Name: transactions; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Name: account_types_account_type_name_key; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY account_types
    ADD CONSTRAINT account_types_account_type_name_key UNIQUE (account_type_name);


--
-- Name: account_types_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY account_types
    ADD CONSTRAINT account_types_pkey PRIMARY KEY (account_type_id);


--
-- Name: accounts_class_accounts_class_name_key; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY accounts_class
    ADD CONSTRAINT accounts_class_accounts_class_name_key UNIQUE (accounts_class_name);


--
-- Name: accounts_class_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY accounts_class
    ADD CONSTRAINT accounts_class_pkey PRIMARY KEY (accounts_class_id);


--
-- Name: accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (account_id);


--
-- Name: address_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY address
    ADD CONSTRAINT address_pkey PRIMARY KEY (address_id);


--
-- Name: approval_phases_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY approval_phases
    ADD CONSTRAINT approval_phases_pkey PRIMARY KEY (approval_phase_id);


--
-- Name: approval_types_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY approval_types
    ADD CONSTRAINT approval_types_pkey PRIMARY KEY (approval_type_id);


--
-- Name: approvals_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY approvals
    ADD CONSTRAINT approvals_pkey PRIMARY KEY (approval_id);


--
-- Name: auction_phase_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY auction_phase
    ADD CONSTRAINT auction_phase_pkey PRIMARY KEY (auction_phase_id);


--
-- Name: auction_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY auction
    ADD CONSTRAINT auction_pkey PRIMARY KEY (auction_id);


--
-- Name: bank_branch_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY bank_branch
    ADD CONSTRAINT bank_branch_pkey PRIMARY KEY (bank_branch_id);


--
-- Name: bank_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY bank
    ADD CONSTRAINT bank_pkey PRIMARY KEY (bank_id);


--
-- Name: borrower_contact_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY borrower_contact
    ADD CONSTRAINT borrower_contact_pkey PRIMARY KEY (borrower_contact_id);


--
-- Name: borrower_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY borrower
    ADD CONSTRAINT borrower_pkey PRIMARY KEY (borrower_id);


--
-- Name: cheque_status_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY cheque_status
    ADD CONSTRAINT cheque_status_pkey PRIMARY KEY (cheque_status_id);


--
-- Name: civil_action_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY civil_action
    ADD CONSTRAINT civil_action_pkey PRIMARY KEY (civil_action_id);


--
-- Name: collateral_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY collateral
    ADD CONSTRAINT collateral_pkey PRIMARY KEY (collateral_id);


--
-- Name: commission_payment_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY commission_payment
    ADD CONSTRAINT commission_payment_pkey PRIMARY KEY (commission_payment_id);


--
-- Name: deduction_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY deduction
    ADD CONSTRAINT deduction_pkey PRIMARY KEY (deduction_id);


--
-- Name: defaulter_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY defaulter
    ADD CONSTRAINT defaulter_pkey PRIMARY KEY (defaulter_id);


--
-- Name: entity_subscriptions_entity_id_key; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY entity_subscriptions
    ADD CONSTRAINT entity_subscriptions_entity_id_key UNIQUE (entity_id, entity_type_id);


--
-- Name: entity_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY entity_subscriptions
    ADD CONSTRAINT entity_subscriptions_pkey PRIMARY KEY (entity_subscription_id);


--
-- Name: entity_types_entity_type_name_key; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY entity_types
    ADD CONSTRAINT entity_types_entity_type_name_key UNIQUE (entity_type_name);


--
-- Name: entity_types_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY entity_types
    ADD CONSTRAINT entity_types_pkey PRIMARY KEY (entity_type_id);


--
-- Name: entitys_org_id_key; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY entitys
    ADD CONSTRAINT entitys_org_id_key UNIQUE (org_id, user_name);


--
-- Name: entitys_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY entitys
    ADD CONSTRAINT entitys_pkey PRIMARY KEY (entity_id);


--
-- Name: entry_forms_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY entry_forms
    ADD CONSTRAINT entry_forms_pkey PRIMARY KEY (entry_form_id);


--
-- Name: entry_sub_forms_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY entry_sub_forms
    ADD CONSTRAINT entry_sub_forms_pkey PRIMARY KEY (entry_sub_form_id);


--
-- Name: fee_type_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY fee_type
    ADD CONSTRAINT fee_type_pkey PRIMARY KEY (fee_type_id);


--
-- Name: fees_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY fees
    ADD CONSTRAINT fees_pkey PRIMARY KEY (fee_id);


--
-- Name: fields_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY fields
    ADD CONSTRAINT fields_pkey PRIMARY KEY (field_id);


--
-- Name: fiscal_years_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY fiscal_years
    ADD CONSTRAINT fiscal_years_pkey PRIMARY KEY (fiscal_year_id);


--
-- Name: forms_form_name_key; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY forms
    ADD CONSTRAINT forms_form_name_key UNIQUE (form_name, version);


--
-- Name: forms_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY forms
    ADD CONSTRAINT forms_pkey PRIMARY KEY (form_id);


--
-- Name: gls_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY gls
    ADD CONSTRAINT gls_pkey PRIMARY KEY (gl_id);


--
-- Name: investigation_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY investigation
    ADD CONSTRAINT investigation_pkey PRIMARY KEY (investigation_id);


--
-- Name: investment_maturity_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY investment_maturity
    ADD CONSTRAINT investment_maturity_pkey PRIMARY KEY (investment_maturity_id);


--
-- Name: investment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY investment
    ADD CONSTRAINT investment_pkey PRIMARY KEY (investment_id);


--
-- Name: investment_type_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY investment_type
    ADD CONSTRAINT investment_type_pkey PRIMARY KEY (investment_type_id);


--
-- Name: investor_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY investor
    ADD CONSTRAINT investor_pkey PRIMARY KEY (investor_id);


--
-- Name: journals_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY journals
    ADD CONSTRAINT journals_pkey PRIMARY KEY (journal_id);


--
-- Name: loan_monthly_loan_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY loan_monthly
    ADD CONSTRAINT loan_monthly_loan_id_key UNIQUE (loan_id, period_id);


--
-- Name: loan_monthly_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY loan_monthly
    ADD CONSTRAINT loan_monthly_pkey PRIMARY KEY (loanmonth_id);


--
-- Name: loan_purpose_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY loan_purpose
    ADD CONSTRAINT loan_purpose_pkey PRIMARY KEY (loan_purpose_id);


--
-- Name: loan_reinbursment_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY loan_reinbursment
    ADD CONSTRAINT loan_reinbursment_pkey PRIMARY KEY (loan_reinbursment_id);


--
-- Name: loans_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY loans
    ADD CONSTRAINT loans_pkey PRIMARY KEY (loan_id);


--
-- Name: loantypes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY loantypes
    ADD CONSTRAINT loantypes_pkey PRIMARY KEY (loantype_id);


--
-- Name: orgs_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY orgs
    ADD CONSTRAINT orgs_pkey PRIMARY KEY (org_id);


--
-- Name: partner_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY partner
    ADD CONSTRAINT partner_pkey PRIMARY KEY (partner_id);


--
-- Name: payment_mode_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY payment_mode
    ADD CONSTRAINT payment_mode_pkey PRIMARY KEY (payment_mode_id);


--
-- Name: periods_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY periods
    ADD CONSTRAINT periods_pkey PRIMARY KEY (period_id);


--
-- Name: phase_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY phase
    ADD CONSTRAINT phase_pkey PRIMARY KEY (phase_id);


--
-- Name: referee_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY referee
    ADD CONSTRAINT referee_pkey PRIMARY KEY (referee_id);


--
-- Name: repayment_table_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY repayment_table
    ADD CONSTRAINT repayment_table_pkey PRIMARY KEY (repayment_table_id);


--
-- Name: services_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY services
    ADD CONSTRAINT services_pkey PRIMARY KEY (service_id);


--
-- Name: services_service_name_key; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY services
    ADD CONSTRAINT services_service_name_key UNIQUE (service_name);


--
-- Name: sub_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY sub_fields
    ADD CONSTRAINT sub_fields_pkey PRIMARY KEY (sub_field_id);


--
-- Name: subscription_levels_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY subscription_levels
    ADD CONSTRAINT subscription_levels_pkey PRIMARY KEY (subscription_level_id);


--
-- Name: sys_audit_details_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY sys_audit_details
    ADD CONSTRAINT sys_audit_details_pkey PRIMARY KEY (sys_audit_detail_id);


--
-- Name: sys_audit_trail_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY sys_audit_trail
    ADD CONSTRAINT sys_audit_trail_pkey PRIMARY KEY (sys_audit_trail_id);


--
-- Name: sys_continents_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY sys_continents
    ADD CONSTRAINT sys_continents_pkey PRIMARY KEY (sys_continent_id);


--
-- Name: sys_continents_sys_continent_name_key; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY sys_continents
    ADD CONSTRAINT sys_continents_sys_continent_name_key UNIQUE (sys_continent_name);


--
-- Name: sys_countrys_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY sys_countrys
    ADD CONSTRAINT sys_countrys_pkey PRIMARY KEY (sys_country_id);


--
-- Name: sys_countrys_sys_country_name_key; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY sys_countrys
    ADD CONSTRAINT sys_countrys_sys_country_name_key UNIQUE (sys_country_name);


--
-- Name: sys_emailed_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY sys_emailed
    ADD CONSTRAINT sys_emailed_pkey PRIMARY KEY (sys_emailed_id);


--
-- Name: sys_emails_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY sys_emails
    ADD CONSTRAINT sys_emails_pkey PRIMARY KEY (sys_email_id);


--
-- Name: sys_errors_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY sys_errors
    ADD CONSTRAINT sys_errors_pkey PRIMARY KEY (sys_error_id);


--
-- Name: sys_files_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY sys_files
    ADD CONSTRAINT sys_files_pkey PRIMARY KEY (sys_file_id);


--
-- Name: sys_logins_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY sys_logins
    ADD CONSTRAINT sys_logins_pkey PRIMARY KEY (sys_login_id);


--
-- Name: sys_news_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY sys_news
    ADD CONSTRAINT sys_news_pkey PRIMARY KEY (sys_news_id);


--
-- Name: sys_passwords_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY sys_passwords
    ADD CONSTRAINT sys_passwords_pkey PRIMARY KEY (sys_password_id);


--
-- Name: sys_queries_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY sys_queries
    ADD CONSTRAINT sys_queries_pkey PRIMARY KEY (query_name);


--
-- Name: tax_category_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY tax_category
    ADD CONSTRAINT tax_category_pkey PRIMARY KEY (tax_category_id);


--
-- Name: tax_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY tax
    ADD CONSTRAINT tax_pkey PRIMARY KEY (tax_id);


--
-- Name: transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (transaction_id);


--
-- Name: account_types_accounts_class_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX account_types_accounts_class_id ON account_types USING btree (accounts_class_id);


--
-- Name: accounts_account_type_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX accounts_account_type_id ON accounts USING btree (account_type_id);


--
-- Name: accounts_class_chat_type_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX accounts_class_chat_type_id ON accounts_class USING btree (chat_type_id);


--
-- Name: address_sys_country_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX address_sys_country_id ON address USING btree (sys_country_id);


--
-- Name: address_table_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX address_table_id ON address USING btree (table_id);


--
-- Name: address_table_name; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX address_table_name ON address USING btree (table_name);


--
-- Name: approval_phases_approval_type_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX approval_phases_approval_type_id ON approval_phases USING btree (approval_type_id);


--
-- Name: approval_phases_entity_type_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX approval_phases_entity_type_id ON approval_phases USING btree (entity_type_id);


--
-- Name: approvals_approval_phase_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX approvals_approval_phase_id ON approvals USING btree (approval_phase_id);


--
-- Name: approvals_entity_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX approvals_entity_id ON approvals USING btree (entity_id);


--
-- Name: approvals_forward_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX approvals_forward_id ON approvals USING btree (forward_id);


--
-- Name: approvals_table_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX approvals_table_id ON approvals USING btree (table_id);


--
-- Name: entity_subscriptions_entity_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX entity_subscriptions_entity_id ON entity_subscriptions USING btree (entity_id);


--
-- Name: entity_subscriptions_entity_type_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX entity_subscriptions_entity_type_id ON entity_subscriptions USING btree (entity_type_id);


--
-- Name: entitys_org_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX entitys_org_id ON entitys USING btree (org_id);


--
-- Name: entry_forms_entity_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX entry_forms_entity_id ON entry_forms USING btree (entity_id);


--
-- Name: entry_forms_form_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX entry_forms_form_id ON entry_forms USING btree (form_id);


--
-- Name: entry_sub_forms_entry_form_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX entry_sub_forms_entry_form_id ON entry_sub_forms USING btree (entry_form_id);


--
-- Name: entry_sub_forms_sub_field_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX entry_sub_forms_sub_field_id ON entry_sub_forms USING btree (sub_field_id);


--
-- Name: fields_form_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX fields_form_id ON fields USING btree (form_id);


--
-- Name: forms_org_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX forms_org_id ON forms USING btree (org_id);


--
-- Name: gls_account_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX gls_account_id ON gls USING btree (account_id);


--
-- Name: gls_journal_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX gls_journal_id ON gls USING btree (journal_id);


--
-- Name: journals_period_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX journals_period_id ON journals USING btree (period_id);


--
-- Name: sub_fields_field_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX sub_fields_field_id ON sub_fields USING btree (field_id);


--
-- Name: sys_audit_details_sys_audit_trail_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX sys_audit_details_sys_audit_trail_id ON sys_audit_details USING btree (sys_audit_trail_id);


--
-- Name: sys_countrys_sys_continent_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX sys_countrys_sys_continent_id ON sys_countrys USING btree (sys_continent_id);


--
-- Name: sys_emailed_sys_email_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX sys_emailed_sys_email_id ON sys_emailed USING btree (sys_email_id);


--
-- Name: sys_emailed_table_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX sys_emailed_table_id ON sys_emailed USING btree (table_id);


--
-- Name: sys_files_table_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX sys_files_table_id ON sys_files USING btree (table_id);


--
-- Name: sys_logins_entity_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX sys_logins_entity_id ON sys_logins USING btree (entity_id);


--
-- Name: ins_entitys; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER ins_entitys AFTER INSERT ON entitys FOR EACH ROW EXECUTE PROCEDURE ins_entitys();


--
-- Name: ins_password; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER ins_password BEFORE INSERT ON entitys FOR EACH ROW EXECUTE PROCEDURE ins_password();


--
-- Name: tr_ins_contact; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER tr_ins_contact BEFORE INSERT OR UPDATE ON borrower_contact FOR EACH ROW EXECUTE PROCEDURE ins_contact();


--
-- Name: tr_ins_employees; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER tr_ins_employees BEFORE INSERT OR UPDATE ON borrower FOR EACH ROW EXECUTE PROCEDURE ins_borrower();


--
-- Name: tr_ins_investor; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER tr_ins_investor BEFORE INSERT OR UPDATE ON investor FOR EACH ROW EXECUTE PROCEDURE ins_investor();


--
-- Name: tr_ins_partner; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER tr_ins_partner BEFORE INSERT OR UPDATE ON partner FOR EACH ROW EXECUTE PROCEDURE ins_partner();


--
-- Name: trcreaterepaymenttable; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trcreaterepaymenttable AFTER INSERT ON loans FOR EACH ROW EXECUTE PROCEDURE createrepaymenttable();


--
-- Name: trinsmonthly; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trinsmonthly AFTER INSERT ON periods FOR EACH ROW EXECUTE PROCEDURE insmonthly();


--
-- Name: trpostaddinvestment; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trpostaddinvestment AFTER INSERT OR DELETE OR UPDATE ON investment FOR EACH ROW EXECUTE PROCEDURE postaddinvestment();


--
-- Name: trpostcommissionpayment; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER trpostcommissionpayment AFTER INSERT OR DELETE OR UPDATE ON commission_payment FOR EACH ROW EXECUTE PROCEDURE postcommissionpayment();


--
-- Name: trpostreduceinvestment; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER trpostreduceinvestment AFTER INSERT OR DELETE OR UPDATE ON deduction FOR EACH ROW EXECUTE PROCEDURE postreduceinvestment();


--
-- Name: trpostreinbursement; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER trpostreinbursement AFTER INSERT OR DELETE OR UPDATE ON loan_reinbursment FOR EACH ROW EXECUTE PROCEDURE postreinbursement();


--
-- Name: trpostrepayment; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER trpostrepayment AFTER INSERT OR DELETE OR UPDATE ON repayment_table FOR EACH ROW EXECUTE PROCEDURE postrepayment();


--
-- Name: trpostreversal; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER trpostreversal AFTER INSERT OR DELETE OR UPDATE ON repayment_table FOR EACH ROW EXECUTE PROCEDURE postreversal();


--
-- Name: trupdateloan; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trupdateloan BEFORE UPDATE ON loans FOR EACH ROW EXECUTE PROCEDURE updateloan();


--
-- Name: trupdrepaymenttable; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER trupdrepaymenttable BEFORE UPDATE ON repayment_table FOR EACH ROW EXECUTE PROCEDURE updrepaymenttable();


--
-- Name: trvalidateamountin; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER trvalidateamountin BEFORE INSERT OR UPDATE ON transactions FOR EACH ROW EXECUTE PROCEDURE validateamountin();


--
-- Name: trvalidateloan; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trvalidateloan BEFORE INSERT ON loans FOR EACH ROW EXECUTE PROCEDURE validateloan();


--
-- Name: upd_gls; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER upd_gls BEFORE INSERT OR UPDATE ON gls FOR EACH ROW EXECUTE PROCEDURE upd_gls();


--
-- Name: account_types_accounts_class_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY account_types
    ADD CONSTRAINT account_types_accounts_class_id_fkey FOREIGN KEY (accounts_class_id) REFERENCES accounts_class(accounts_class_id);


--
-- Name: accounts_account_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY accounts
    ADD CONSTRAINT accounts_account_type_id_fkey FOREIGN KEY (account_type_id) REFERENCES account_types(account_type_id);


--
-- Name: accounts_bank_branch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY accounts
    ADD CONSTRAINT accounts_bank_branch_id_fkey FOREIGN KEY (bank_branch_id) REFERENCES bank_branch(bank_branch_id);


--
-- Name: address_sys_country_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY address
    ADD CONSTRAINT address_sys_country_id_fkey FOREIGN KEY (sys_country_id) REFERENCES sys_countrys(sys_country_id);


--
-- Name: approval_phases_approval_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY approval_phases
    ADD CONSTRAINT approval_phases_approval_type_id_fkey FOREIGN KEY (approval_type_id) REFERENCES approval_types(approval_type_id);


--
-- Name: approval_phases_entity_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY approval_phases
    ADD CONSTRAINT approval_phases_entity_type_id_fkey FOREIGN KEY (entity_type_id) REFERENCES entity_types(entity_type_id);


--
-- Name: approvals_approval_phase_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY approvals
    ADD CONSTRAINT approvals_approval_phase_id_fkey FOREIGN KEY (approval_phase_id) REFERENCES approval_phases(approval_phase_id);


--
-- Name: approvals_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY approvals
    ADD CONSTRAINT approvals_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: auction_defaulter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY auction
    ADD CONSTRAINT auction_defaulter_id_fkey FOREIGN KEY (defaulter_id) REFERENCES defaulter(defaulter_id);


--
-- Name: auction_phase_auction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY auction_phase
    ADD CONSTRAINT auction_phase_auction_id_fkey FOREIGN KEY (auction_id) REFERENCES auction(auction_id);


--
-- Name: auction_phase_phase_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY auction_phase
    ADD CONSTRAINT auction_phase_phase_id_fkey FOREIGN KEY (phase_id) REFERENCES phase(phase_id);


--
-- Name: bank_branch_bank_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY bank_branch
    ADD CONSTRAINT bank_branch_bank_id_fkey FOREIGN KEY (bank_id) REFERENCES bank(bank_id);


--
-- Name: borrower_contact_borrower_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY borrower_contact
    ADD CONSTRAINT borrower_contact_borrower_id_fkey FOREIGN KEY (borrower_id) REFERENCES borrower(borrower_id);


--
-- Name: borrower_contact_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY borrower_contact
    ADD CONSTRAINT borrower_contact_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: borrower_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY borrower
    ADD CONSTRAINT borrower_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: civil_action_investigation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY civil_action
    ADD CONSTRAINT civil_action_investigation_id_fkey FOREIGN KEY (investigation_id) REFERENCES investigation(investigation_id);


--
-- Name: collateral_loanid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY collateral
    ADD CONSTRAINT collateral_loanid_fkey FOREIGN KEY (loan_id) REFERENCES loans(loan_id);


--
-- Name: commission_payment_investment_maturity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY commission_payment
    ADD CONSTRAINT commission_payment_investment_maturity_id_fkey FOREIGN KEY (investment_maturity_id) REFERENCES investment_maturity(investment_maturity_id);


--
-- Name: deduction_investment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY deduction
    ADD CONSTRAINT deduction_investment_id_fkey FOREIGN KEY (investment_id) REFERENCES investment(investment_id);


--
-- Name: defaulter_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY defaulter
    ADD CONSTRAINT defaulter_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: defaulter_repayment_table_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY defaulter
    ADD CONSTRAINT defaulter_repayment_table_id_fkey FOREIGN KEY (repayment_table_id) REFERENCES repayment_table(repayment_table_id);


--
-- Name: entity_subscriptions_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY entity_subscriptions
    ADD CONSTRAINT entity_subscriptions_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: entity_subscriptions_entity_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY entity_subscriptions
    ADD CONSTRAINT entity_subscriptions_entity_type_id_fkey FOREIGN KEY (entity_type_id) REFERENCES entity_types(entity_type_id);


--
-- Name: entity_subscriptions_subscription_level_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY entity_subscriptions
    ADD CONSTRAINT entity_subscriptions_subscription_level_id_fkey FOREIGN KEY (subscription_level_id) REFERENCES subscription_levels(subscription_level_id);


--
-- Name: entitys_entity_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY entitys
    ADD CONSTRAINT entitys_entity_type_id_fkey FOREIGN KEY (entity_type_id) REFERENCES entity_types(entity_type_id);


--
-- Name: entitys_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY entitys
    ADD CONSTRAINT entitys_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: entry_forms_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY entry_forms
    ADD CONSTRAINT entry_forms_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: entry_forms_form_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY entry_forms
    ADD CONSTRAINT entry_forms_form_id_fkey FOREIGN KEY (form_id) REFERENCES forms(form_id);


--
-- Name: entry_sub_forms_entry_form_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY entry_sub_forms
    ADD CONSTRAINT entry_sub_forms_entry_form_id_fkey FOREIGN KEY (entry_form_id) REFERENCES entry_forms(entry_form_id);


--
-- Name: entry_sub_forms_sub_field_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY entry_sub_forms
    ADD CONSTRAINT entry_sub_forms_sub_field_id_fkey FOREIGN KEY (sub_field_id) REFERENCES sub_fields(sub_field_id);


--
-- Name: fees_fee_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY fees
    ADD CONSTRAINT fees_fee_type_id_fkey FOREIGN KEY (fee_type_id) REFERENCES fee_type(fee_type_id);


--
-- Name: fields_form_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY fields
    ADD CONSTRAINT fields_form_id_fkey FOREIGN KEY (form_id) REFERENCES forms(form_id);


--
-- Name: forms_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY forms
    ADD CONSTRAINT forms_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: gls_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY gls
    ADD CONSTRAINT gls_account_id_fkey FOREIGN KEY (account_id) REFERENCES accounts(account_id);


--
-- Name: gls_journal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY gls
    ADD CONSTRAINT gls_journal_id_fkey FOREIGN KEY (journal_id) REFERENCES journals(journal_id);


--
-- Name: investigation_defaulter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY investigation
    ADD CONSTRAINT investigation_defaulter_id_fkey FOREIGN KEY (defaulter_id) REFERENCES defaulter(defaulter_id);


--
-- Name: investment_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY investment
    ADD CONSTRAINT investment_account_id_fkey FOREIGN KEY (account_id) REFERENCES accounts(account_id);


--
-- Name: investment_investment_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY investment
    ADD CONSTRAINT investment_investment_type_id_fkey FOREIGN KEY (investment_type_id) REFERENCES investment_type(investment_type_id);


--
-- Name: investment_investor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY investment
    ADD CONSTRAINT investment_investor_id_fkey FOREIGN KEY (investor_id) REFERENCES investor(investor_id);


--
-- Name: investment_maturity_investment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY investment_maturity
    ADD CONSTRAINT investment_maturity_investment_id_fkey FOREIGN KEY (investment_id) REFERENCES investment(investment_id);


--
-- Name: investment_maturity_period_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY investment_maturity
    ADD CONSTRAINT investment_maturity_period_id_fkey FOREIGN KEY (period_id) REFERENCES periods(period_id);


--
-- Name: investor_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY investor
    ADD CONSTRAINT investor_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: journals_period_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY journals
    ADD CONSTRAINT journals_period_id_fkey FOREIGN KEY (period_id) REFERENCES periods(period_id);


--
-- Name: loan_monthly_loan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY loan_monthly
    ADD CONSTRAINT loan_monthly_loan_id_fkey FOREIGN KEY (loan_id) REFERENCES loans(loan_id);


--
-- Name: loan_monthly_period_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY loan_monthly
    ADD CONSTRAINT loan_monthly_period_id_fkey FOREIGN KEY (period_id) REFERENCES periods(period_id);


--
-- Name: loan_reinbursment_bank_branch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY loan_reinbursment
    ADD CONSTRAINT loan_reinbursment_bank_branch_id_fkey FOREIGN KEY (bank_branch_id) REFERENCES bank_branch(bank_branch_id);


--
-- Name: loan_reinbursment_createdby_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY loan_reinbursment
    ADD CONSTRAINT loan_reinbursment_createdby_fkey FOREIGN KEY (createdby) REFERENCES entitys(entity_id);


--
-- Name: loan_reinbursment_loan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY loan_reinbursment
    ADD CONSTRAINT loan_reinbursment_loan_id_fkey FOREIGN KEY (loan_id) REFERENCES loans(loan_id);


--
-- Name: loan_reinbursment_payment_mode_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY loan_reinbursment
    ADD CONSTRAINT loan_reinbursment_payment_mode_id_fkey FOREIGN KEY (payment_mode_id) REFERENCES payment_mode(payment_mode_id);


--
-- Name: loans_borrowerid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY loans
    ADD CONSTRAINT loans_borrowerid_fkey FOREIGN KEY (borrower_id) REFERENCES borrower(borrower_id);


--
-- Name: loans_loan_purpose_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY loans
    ADD CONSTRAINT loans_loan_purpose_id_fkey FOREIGN KEY (loan_purpose_id) REFERENCES loan_purpose(loan_purpose_id);


--
-- Name: loans_loantype_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY loans
    ADD CONSTRAINT loans_loantype_id_fkey FOREIGN KEY (loantype_id) REFERENCES loantypes(loantype_id);


--
-- Name: partner_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY partner
    ADD CONSTRAINT partner_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: periods_fiscal_year_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY periods
    ADD CONSTRAINT periods_fiscal_year_id_fkey FOREIGN KEY (fiscal_year_id) REFERENCES fiscal_years(fiscal_year_id);


--
-- Name: referee_borrower_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY referee
    ADD CONSTRAINT referee_borrower_id_fkey FOREIGN KEY (borrower_id) REFERENCES borrower(borrower_id);


--
-- Name: referee_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY referee
    ADD CONSTRAINT referee_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: repayment_table_bank_branch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY repayment_table
    ADD CONSTRAINT repayment_table_bank_branch_id_fkey FOREIGN KEY (bank_branch_id) REFERENCES bank_branch(bank_branch_id);


--
-- Name: repayment_table_cheque_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY repayment_table
    ADD CONSTRAINT repayment_table_cheque_status_id_fkey FOREIGN KEY (cheque_status_id) REFERENCES cheque_status(cheque_status_id);


--
-- Name: repayment_table_loan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY repayment_table
    ADD CONSTRAINT repayment_table_loan_id_fkey FOREIGN KEY (loan_id) REFERENCES loans(loan_id);


--
-- Name: sub_fields_field_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY sub_fields
    ADD CONSTRAINT sub_fields_field_id_fkey FOREIGN KEY (field_id) REFERENCES fields(field_id);


--
-- Name: sys_audit_details_sys_audit_trail_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY sys_audit_details
    ADD CONSTRAINT sys_audit_details_sys_audit_trail_id_fkey FOREIGN KEY (sys_audit_trail_id) REFERENCES sys_audit_trail(sys_audit_trail_id);


--
-- Name: sys_countrys_sys_continent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY sys_countrys
    ADD CONSTRAINT sys_countrys_sys_continent_id_fkey FOREIGN KEY (sys_continent_id) REFERENCES sys_continents(sys_continent_id);


--
-- Name: sys_emailed_sys_email_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY sys_emailed
    ADD CONSTRAINT sys_emailed_sys_email_id_fkey FOREIGN KEY (sys_email_id) REFERENCES sys_emails(sys_email_id);


--
-- Name: sys_logins_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY sys_logins
    ADD CONSTRAINT sys_logins_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: tax_tax_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY tax
    ADD CONSTRAINT tax_tax_category_id_fkey FOREIGN KEY (tax_category_id) REFERENCES tax_category(tax_category_id);


--
-- Name: transactions_borrower_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT transactions_borrower_id_fkey FOREIGN KEY (borrower_id) REFERENCES borrower(borrower_id);


--
-- Name: transactions_loan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT transactions_loan_id_fkey FOREIGN KEY (loan_id) REFERENCES loans(loan_id);


--
-- Name: transactions_payment_mode_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT transactions_payment_mode_id_fkey FOREIGN KEY (payment_mode_id) REFERENCES payment_mode(payment_mode_id);


--
-- Name: transactions_period_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT transactions_period_id_fkey FOREIGN KEY (period_id) REFERENCES periods(period_id);


--
-- Name: transactions_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT transactions_service_id_fkey FOREIGN KEY (service_id) REFERENCES services(service_id);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

