--views

CREATE OR REPLACE FUNCTION get_balance_new(entity_id integer) RETURNS real AS $$
DECLARE
		v_loans 			real;
		v_contributions 	real;
		v_receipt 			real;
		balance 			real;
BEGIN
	SELECT CASE WHEN sum(loan_monthly.penalty_paid + loan_monthly.interest_paid + loan_monthly.repayment_paid) IS NULL THEN 0
		ELSE sum(loan_monthly.penalty_paid + loan_monthly.interest_paid + loan_monthly.repayment_paid) END 
		INTO v_loans
	FROM loan_monthly INNER JOIN loans ON loan_monthly.loan_id = loans.loan_id
	WHERE(loans.entity_id = $1);
		
	SELECT CASE WHEN  sum(contribution_paid ) IS NULL THEN 0   
	ELSE sum(contribution_paid) END
		INTO v_contributions
	FROM contributions
	WHERE (contributions.entity_id = $1);
		
	SELECT CASE WHEN sum (receipt) IS NULL THEN 0 ELSE sum (receipt)  END
		INTO  v_receipt
	FROM contributions
	WHERE (contributions.entity_id = $1);
	
	balance = v_receipt - (v_loans + v_contributions) ;
	IF(balance is null)THEN balance = 0; END IF;
	
	RETURN balance;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE VIEW vw_gurrantors AS 
	SELECT vw_loans.principle, vw_loans.currency_symbol, vw_loans.entity_id, vw_loans.interest,
		vw_loans.monthly_repayment, vw_loans.loan_date, vw_loans.initial_payment, vw_loans.loan_id,
		vw_loans.repayment_amount, vw_loans.total_interest, vw_loans.loan_balance, vw_loans.calc_repayment_period,
		vw_loans.reducing_balance, vw_loans.repayment_period, vw_loans.application_date, vw_loans.approve_status,
		vw_loans.org_id, vw_loans.action_date, vw_loans.details, vw_loans.total_repayment,
		entitys.entity_name, 
		loan_types.loan_type_id, loan_types.loan_type_name, 
		gurrantors.gurrantor_id, gurrantors.is_accepted, gurrantors.amount, gurrantors_entity.entity_name AS gurrantor_entity_name,
		gurrantors_entity.entity_id AS gurrantor_entity_id
	FROM gurrantors INNER JOIN vw_loans ON vw_loans.loan_id = gurrantors.loan_id
		INNER JOIN entitys ON vw_loans.entity_id = entitys.entity_id
		INNER JOIN loan_types ON vw_loans.loan_type_id = loan_types.loan_type_id
		INNER JOIN entitys gurrantors_entity ON gurrantors_entity.entity_id = gurrantors.entity_id;
	
CREATE VIEW vw_members AS
	SELECT vw_bank_branch.bank_id, vw_bank_branch.bank_name, vw_bank_branch.bank_branch_id, 
		vw_bank_branch.bank_branch_name, vw_bank_branch.bank_branch_code, 
		entitys.entity_id, entitys.entity_name, entitys.user_name, entitys.date_enroled,
		members.recruiter_id, recruiter.entity_name as recruiter_name, 
		members.org_id, members.person_title, members.full_name, 
		members.surname, members.first_name, members.middle_name, members.date_of_birth, 
		members.gender, members.phone, members.primary_email, members.account_number, 
		members.place_of_birth, members.marital_status, members.appointment_date, 
		members.exit_date, members.exit_amount, members.picture_file, members.active, 
		members.language, members.interests, members.objective, members.details, 
		members.division, members.location, members.sub_location, members.district, members.county, 
		members.residential_address, members.expired, members.contribution
	FROM members INNER JOIN entitys ON members.entity_id = entitys.entity_id
		LEFT JOIN vw_bank_branch ON members.bank_branch_id = vw_bank_branch.bank_branch_id
		LEFT JOIN entitys recruiter ON members.recruiter_id = recruiter.entity_id;

CREATE OR REPLACE VIEW vw_investments AS 
	SELECT entitys.entity_id, entitys.entity_name,
		investment_types.investment_type_name,
		investments.org_id, investments.investment_id, investments.investment_type_id,
		investments.maturity_date, investments.invest_amount, investments.yearly_dividend,
		investments.withdrawal_date, investments.withdrwal_amount, investments.period_years,
		investments.default_interest, investments.return_on_investment, investments.application_date,
		investments.approve_status, investments.workflow_table_id, investments.action_date,
		investments.details

	FROM investments INNER JOIN entitys ON entitys.entity_id = investments.entity_id
		INNER JOIN investment_types ON investments.investment_type_id = investment_types.investment_type_id;  

CREATE VIEW vw_applicants AS
	SELECT entitys.entity_id, entitys.entity_name, 
		applicants.org_id, applicants.person_title, applicants.surname, 
		applicants.first_name, applicants.middle_name, applicants.applicant_email, applicants.applicant_phone, 
		applicants.date_of_birth, applicants.gender, applicants.nationality, applicants.marital_status, 
		applicants.picture_file, applicants.identity_card, applicants.language, applicants.approve_status, 
		applicants.workflow_table_id, applicants.action_date, applicants.salary, applicants.how_you_heard, 
		applicants.created, applicants.interests, applicants.objective, applicants.details
	FROM applicants LEFT JOIN entitys ON applicants.entity_id = entitys.entity_id;

CREATE VIEW vw_sacco_investments AS
	SELECT bank_accounts.bank_account_id, bank_accounts.bank_account_name, 
		currency.currency_id, currency.currency_name, 
		investment_types.investment_type_id, investment_types.investment_type_name, 
		sacco_investments.org_id, sacco_investments.sacco_investment_id, sacco_investments.investment_name, 
		sacco_investments.investment_status, sacco_investments.date_of_accrual, sacco_investments.principal, 
		sacco_investments.interest, sacco_investments.repayment_period, sacco_investments.initial_payment, 
		sacco_investments.monthly_payments, 
		sacco_investments.approve_status, sacco_investments.workflow_table_id, sacco_investments.action_date, 
		sacco_investments.is_active, sacco_investments.details
	FROM sacco_investments INNER JOIN bank_accounts ON sacco_investments.bank_account_id = bank_accounts.bank_account_id
		INNER JOIN currency ON sacco_investments.currency_id = currency.currency_id
		INNER JOIN investment_types ON sacco_investments.investment_type_id = investment_types.investment_type_id;
	
CREATE OR REPLACE VIEW vw_contributions AS 
	SELECT contributions.contribution_id,
		contributions.org_id,
		contributions.entity_id,
		contributions.period_id,
		contributions.payment_type_id,
		contributions.receipt,
		contributions.receipt_date,

		contributions.entry_date,
		contributions.transaction_ref,
		contributions.contribution_amount,
		contributions.contribution_paid,

		contributions.deposit_date AS deposit_dates,
		contributions.is_paid,
		members.full_name ,
		members.expired, 
		contribution_types.contribution_type_id,
		contribution_types.contribution_type_name,
		payment_types.payment_type_name,
		payment_types.payment_narrative,
		get_balance_new (contributions.entity_id) AS active_balance,
		to_char(periods.start_date::timestamp with time zone, 'YYYY'::text) AS deposit_year,
		to_char(periods.start_date::timestamp with time zone, 'Month'::text) AS deposit_date
	FROM contributions
		JOIN members ON contributions.entity_id = members.entity_id
		JOIN contribution_types ON contributions.contribution_type_id = contribution_types.contribution_type_id
		JOIN payment_types ON payment_types.payment_type_id = contributions.payment_type_id
		LEFT JOIN periods ON contributions.period_id = periods.period_id 
		
	WHERE expired = 'false';

CREATE OR REPLACE VIEW vw_contributions_month AS 
	SELECT vw_periods.period_id,
		vw_periods.start_date,
		vw_periods.end_date,
		vw_periods.overtime_rate,
		vw_periods.activated,
		vw_periods.closed,
		vw_periods.month_id,
		vw_periods.period_year,
		vw_periods.period_month,
		vw_periods.quarter,
		vw_periods.semister,
		--vw_periods.bank_header,
		--vw_periods.bank_address,
		--vw_periods.is_posted,
		contributions.contribution_id,
		contributions.org_id,
		contributions.entity_id,
		contributions.payment_type_id,
		contributions.contribution_amount,
		contributions.contribution_paid ,

		contributions.entry_date,
		contributions.transaction_ref,
		contributions.is_paid,
		get_balance_new(contributions.entity_id) AS active_balance,
		members.contribution AS intial_contribution,
		members.first_name,
		members.expired,
		contribution_types.contribution_type_id,
		contribution_types.contribution_type_name,
		payment_types.payment_type_name,
		payment_types.payment_narrative,
		to_char(vw_periods.start_date::timestamp with time zone, 'YYYY'::text) AS year,
		to_char(vw_periods.start_date::timestamp with time zone, 'Month'::text) AS deposit_date
	FROM contributions
		JOIN members ON contributions.entity_id = members.entity_id
		JOIN contribution_types ON contributions.contribution_type_id = contribution_types.contribution_type_id
		JOIN payment_types ON payment_types.payment_type_id = contributions.payment_type_id
		JOIN vw_periods ON contributions.period_id = vw_periods.period_id;


CREATE OR REPLACE VIEW vw_additional_funds AS 
	SELECT vw_contributions.contribution_amount,
		vw_contributions.contribution_paid,
		vw_contributions.contribution_id,
		additional_funds.payment_type_id,
		additional_funds.org_id,
		additional_funds.additional_amount,
		additional_funds.deposit_date AS paid_date,
		additional_funds.entry_date,
		additional_funds.transaction_ref,
		additional_funds.additional_funds_id,
		additional_funds.narrative,
		vw_contributions.deposit_year,
		vw_contributions.deposit_date,
		payment_types.payment_type_name
	FROM additional_funds
		JOIN vw_contributions ON vw_contributions.contribution_id = additional_funds.contribution_id
		JOIN payment_types ON payment_types.payment_type_id = additional_funds.payment_type_id;

CREATE OR REPLACE FUNCTION get_total_repayment(integer) RETURNS real AS $$
	SELECT CASE WHEN sum(repayment + interest_paid + penalty_paid - additional_payments) is null THEN 0 
		ELSE sum(repayment + interest_paid + penalty_paid - additional_payments) END
	FROM loan_monthly
	WHERE (loan_id = $1);
$$ LANGUAGE SQL;


--- here done
CREATE OR REPLACE FUNCTION compute_contributions(v_period_id varchar, v_org_id varchar, v_approval varchar) RETURNS varchar AS $$
DECLARE
    msg                 varchar(120);
BEGIN
	msg := 'Contributions generated';
    DELETE FROM loan_monthly WHERE period_id = v_period_id::integer AND org_id =  v_org_id::integer AND is_paid = false ;
    DELETE FROM contributions WHERE period_id = v_period_id::integer;
    
    INSERT INTO contributions(period_id, org_id, entity_id,  payment_type_id, contribution_type_id, 
             contribution_amount,  entry_date,
             transaction_ref, is_paid)
             
    SELECT v_period_id::integer, org_id::integer ,entity_id, 1,1,  contribution,
            now()::date, 'Auto generated','False'
        FROM members;

    RETURN msg;
END;
$$ LANGUAGE plpgsql;
  
CREATE OR REPLACE FUNCTION loan_approved(varchar, varchar, varchar) RETURNS varchar AS $$
DECLARE
	msg 				varchar(120);
BEGIN
	msg := 'Approved';
	
	UPDATE loans SET approve_status = 'Approved'
	WHERE (loan_id = CAST($1 as int));

	return msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION loan_rejected(varchar, varchar, varchar) RETURNS varchar AS $$
DECLARE
	msg 				varchar(120);
BEGIN
	msg := 'Rejected';
	
	UPDATE loans SET approve_status = 'Rejected'
	WHERE (loan_id = CAST($1 as int));

	return msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION loan_paid(varchar, varchar, varchar) RETURNS varchar AS $$
DECLARE
	msg 				varchar(120);
BEGIN
	msg := 'Paid';
	
	UPDATE loan_monthly  SET is_paid = 'True'
	WHERE (loan_month_id = CAST($1 as int));

	return msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION contribution_paid (varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	msg 				varchar(120);
BEGIN
	msg := 'Contribution paid';
	
	UPDATE contributions  SET is_paid = 'True'
	WHERE (contribution_id = CAST($1 as int));
	
	return msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ins_kins() RETURNS trigger AS $$
DECLARE
	beneficiary_ps_total   	real;
	v_entity_id    integer;
	
BEGIN

	IF (NEW.beneficiary_ps > 100 AND New.beneficiary = 'True')THEN
		raise exception 'Percentage total has to be 100';
	END IF;
	
	SELECT  beneficiary_ps, entity_id INTO beneficiary_ps_total, v_entity_id
	FROM kins WHERE kin_id = NEW.kin_id AND  New.beneficiary = 'True';
	
	
	IF (beneficiary_ps_total > 100 ) THEN
		New. beneficiary_ps := 0;
	END IF;

RETURN NEW;
END;
$$ LANGUAGE plpgsql;
     
 
CREATE OR REPLACE FUNCTION ins_periods() RETURNS trigger AS $$
DECLARE
	year_close 		BOOLEAN;
BEGIN
	SELECT year_closed INTO year_close
	FROM fiscal_years
	WHERE (fiscal_year_id = NEW.fiscal_year_id);
	
	IF(TG_OP = 'UPDATE')THEN    
		IF (OLD.closed = true) AND (NEW.closed = false) THEN
			NEW.approve_status := 'Draft';
		END IF;
	END IF;

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


------------Hooks to approval trigger
  
CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON investments
    FOR EACH ROW EXECUTE PROCEDURE upd_action();

    

CREATE OR REPLACE FUNCTION investment_aplication(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	msg 				varchar(120);
BEGIN
	msg := 'investment applied';
	
	UPDATE investments SET approve_status = 'Approved'
	WHERE (investment_id = CAST($1 as int)) AND (approve_status = 'Draft');

	return msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ins_applicants() RETURNS trigger AS $$
DECLARE
	rec					RECORD;
	v_entity_id			integer;
	v_exist				integer;
BEGIN

	IF (TG_OP = 'INSERT') then 
		SELECT count(applicant_email) INTO v_exist 
		FROM applicants WHERE applicant_email = NEW.applicant_email;
		IF(v_exist != 0) THEN
			Raise exception 'email exists';
		END IF;
	END IF;

	IF (TG_OP = 'UPDATE' AND NEW.approve_status = 'Approved') THEN
		INSERT INTO members(entity_id, org_id, full_name, surname, first_name, middle_name, phone, 
			gender, marital_status, primary_email, objective, details)  
		VALUES (NEW.entity_id, NEW.org_id, (NEW.Surname || ' ' || NEW.First_name || ' ' || COALESCE(NEW.Middle_name, '')), New.Surname, NEW.First_name, NEW.Middle_name,
			NEW.applicant_phone, NEW.gender, NEW.marital_status, NEW.applicant_email, NEW.objective, NEW.details)
		RETURNING entity_id INTO v_entity_id;
		NEW.entity_id := v_entity_id;

		INSERT INTO sys_emailed (sys_email_id, table_id,org_id, table_name)
		VALUES (1, NEW.entity_id, NEW.org_id, 'applicant');
	END IF;
	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_applicants BEFORE INSERT OR UPDATE ON applicants
	FOR EACH ROW  EXECUTE PROCEDURE ins_applicants();
  

CREATE OR REPLACE FUNCTION ins_members() RETURNS trigger AS $$
DECLARE
	rec 			RECORD;
	v_entity_id		integer;
BEGIN

	IF (TG_OP = 'INSERT') THEN
		IF (New.primary_email is null)THEN
			RAISE EXCEPTION 'You have to enter an Email';
		ELSIF(NEW.first_name is null) AND (NEW.surname is null)THEN
			RAISE EXCEPTION 'You have need to enter Sur name and full Name';
		ELSIF(new.contribution is null) then
			RAISE EXCEPTION 'You have need to enter contribution amount';
		ELSE
			Raise NOTICE 'Thank you';
		END IF;
		NEW.entity_id := nextval('entitys_entity_id_seq');

		INSERT INTO entitys (entity_id, entity_name,org_id,entity_type_id,user_name,primary_email,primary_telephone,function_role,details,exit_amount,use_key_id)
		VALUES (New.entity_id, (NEW.Surname || ' ' || NEW.First_name || ' ' || COALESCE(NEW.Middle_name, '')),New.org_id::INTEGER,0,NEW.primary_email,NEW.primary_email,NEW.phone,'member',NEW.details,new.contribution, 0) 
		RETURNING entity_id INTO v_entity_id;

		NEW.entity_id := v_entity_id;
	END IF;
	
	NEW.full_name = (NEW.Surname || ' ' || NEW.First_name || ' ' || COALESCE(NEW.Middle_name, ''));
	IF (TG_OP = 'UPDATE') THEN
		UPDATE entitys SET entity_name = NEW.full_name WHERE entity_id = NEW.entity_id;
	END IF;
	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_members BEFORE INSERT OR UPDATE ON members
FOR EACH ROW  EXECUTE PROCEDURE ins_members(); 
  
  
CREATE OR REPLACE FUNCTION ins_gurrantors() RETURNS trigger AS $$
DECLARE
	rec_loan					RECORD;
	v_shares					real;
	v_grnt_shares				real;
	v_active_loans				integer;
	v_active_loans_grnt			integer;
	v_tot_loan_balance			real;
	v_tot_loan_balance_grnt		real;
	v_amount_already_grntd		real;
	can_gurrantee				boolean;
	msg							varchar(120);
BEGIN
    msg := 'Loan gurranteed';
    can_gurrantee  := true;
    v_active_loans := 0;
    v_tot_loan_balance_grnt := 0;
    v_amount_already_grntd := 0;
    
    SELECT * INTO rec_loan FROM vw_loans WHERE loan_id = NEW.loan_id; --LOAN TO BE GURRANTEED
    
    SELECT COALESCE(SUM(contribution_paid + additional_payments), 0) INTO v_shares FROM contributions where entity_id = rec_loan.entity_id; -- LOANEE SHARES
    SELECT COALESCE(SUM(contribution_paid + additional_payments), 0) INTO v_grnt_shares FROM contributions where entity_id = NEW.entity_id; -- GRNT SHARES

    SELECT COALESCE(SUM(loan_balance), 0) INTO v_tot_loan_balance FROM vw_loans WHERE entity_id = rec_loan.entity_id AND approve_status = 'Approved' AND loan_balance > 0; --LOANEE ACTIVE LOAN SUM
    SELECT COALESCE(SUM(loan_balance), 0) INTO v_tot_loan_balance_grnt FROM vw_loans WHERE entity_id = NEW.entity_id AND approve_status = 'Approved' AND loan_balance > 0; --GRNT ACTIVE LOAN SUM
    
    SELECT COALESCE(COUNT(loan_id), 0) INTO v_active_loans FROM vw_loans WHERE entity_id = rec_loan.entity_id AND approve_status = 'Approved' AND loan_balance > 0; --LOANEE COUNT
    SELECT COALESCE(COUNT(loan_id), 0) INTO v_active_loans_grnt FROM vw_loans WHERE entity_id = NEW.entity_id AND approve_status = 'Approved' AND loan_balance > 0; --GRNT COUNT

    SELECT COALESCE(SUM(amount), 0) INTO v_tot_loan_balance_grnt FROM gurrantors WHERE loan_id = NEW.loan_id; --CHECK ALREADY GURRANTEED AMOUNT;
    --RAISE EXCEPTION 'rec_loan.principle % | v_tot_loan_balance_grnt: %', rec_loan.principle, v_tot_loan_balance_grnt;
    --SELECT coalesce(SUM(amount),0) FROM gurrantors WHERE loan_id = 342

    -- GET AMOUNT GUARANTOR HAS ALREADY GURtd OTHER PEOPLE
    SELECT COALESCE(SUM(amount), 0) INTO v_amount_already_grntd FROM vw_gurrantors WHERE gurrantor_entity_id = NEW.entity_id AND is_accepted = true AND loan_balance > 0;

    
    IF(NEW.amount > (rec_loan.principle - v_tot_loan_balance_grnt)) THEN
        RAISE EXCEPTION '% is greater than the amount remaining to be gurranteed %', NEW.amount,  (rec_loan.principle - v_tot_loan_balance_grnt);
    ELSE
        IF(v_active_loans_grnt = 0) THEN --GRNT HAS NO LOAN
            IF((v_grnt_shares - v_amount_already_grntd)  >= NEW.amount) THEN
                can_gurrantee := true;
            ELSE
                can_gurrantee := false;
                RAISE EXCEPTION 'This person does not qualify to gurrantee you';
            END IF;
        ELSE-- HAS LOAN
		IF (v_active_loans_grnt > 0) THEN
			IF (v_grnt_shares > v_tot_loan_balance_grnt) THEN
			can_gurrantee := true;
			ELSE 
			can_gurrantee := false;
			--RAISE EXCEPTION ' This persons balance is %,COALESCE (v_grnt_shares,0) - COALESCE(v_tot_loan_balance_grnt,0)';
			END IF;

		end if;
           -- RAISE EXCEPTION 'This person has a loan %', v_active_loans_grnt;
        END IF;
    END IF;
    
   IF(can_gurrantee = false) THEN
        RAISE EXCEPTION 'Cannot Gurantee  Loan' ;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;
  
CREATE TRIGGER ins_gurrantors BEFORE INSERT OR UPDATE ON gurrantors
  FOR EACH ROW  EXECUTE PROCEDURE ins_gurrantors(); 


  
  
    
  
 

CREATE OR REPLACE FUNCTION gurrantor_accept(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	msg 				varchar(120);
BEGIN
	msg := 'Guranteeing Accepted';
	
	UPDATE gurrantors SET is_accepted = 'True'
	WHERE (gurrantor_id = CAST($1 as int)) AND (amount > 0);

	return msg;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION applicant_accept(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	msg 				varchar(120);
BEGIN
	msg := 'Applicant Added';
	
	UPDATE applicants SET approve_status = 'Approved'
	WHERE (entity_id = CAST($1 as int)) AND (applicant_email is not null);

	return msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION subscription_accepted(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	msg 				varchar(120);
BEGIN
	msg := 'Accepted';
	
	UPDATE subscriptions SET approve_status = 'Approved'
	WHERE (subscription_id = CAST($1 as int)) ;

	return msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION subscription_rejected(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	msg 				varchar(120);
BEGIN
	msg := 'Accepted';
	
	UPDATE subscriptions SET approve_status = 'Reject'
	WHERE (subscription_id = CAST($1 as int));

	return msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION investment_approved(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	msg 				varchar(120);
BEGIN
	msg := 'Accepted';
	
	UPDATE investments SET approve_status = 'Approved'
	WHERE (investment_id = CAST($1 as int));

	return msg;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION investment_rejected(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	msg 				varchar(120);
BEGIN
	msg := 'Rejected';
	
	UPDATE investments SET approve_status = 'Rejected'
	WHERE (investment_id = CAST($1 as int));

	return msg;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION investment_processed(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	msg 				varchar(120);
BEGIN
	msg := 'Processed';
	
	UPDATE investments SET approve_status = 'Approved'
	WHERE (investment_id = CAST($1 as int));

	return msg;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION applicant_approve(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	msg 				varchar(120);
BEGIN
	msg := 'Applicant Approved';
	
	UPDATE applicants SET approve_status = 'Approved'
	WHERE (entity_id = CAST($1 as int));

	return msg;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION applicant_rejected(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	msg 				varchar(120);
BEGIN
	msg := 'Applicant Rejected';
	
	UPDATE applicants SET approve_status = 'Rejected'
	WHERE (entity_id = CAST($1 as int));

	return msg;
END;
$$ LANGUAGE plpgsql;


     
CREATE OR REPLACE FUNCTION get_total_repayment(real, real, real) RETURNS real AS $$
DECLARE
	repayment real;
	ri real;
BEGIN
	ri := (($1* $2 * $3)/1200);
	repayment := $1 + (($1* $2 * $3)/1200);
	RETURN repayment;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION get_interest_amount(real,real,real) RETURNS real AS $$
DECLARE
	ri real;
BEGIN
	ri :=(($1* $2 * $3)/1200);
RETURN ri;
END;
$$ LANGUAGE plpgsql;


 
 
CREATE OR REPLACE FUNCTION get_balances(entity_id integer) RETURNS real AS $$
DECLARE
	v_loans 			real;
	v_contributions 	real;
	v_receipt 			real;
	balance 			real;
BEGIN

	SELECT sum(contribution_paid), sum (receipt) INTO v_contributions, v_receipt
		FROM contributions
		WHERE (contributions.entity_id = $1);
	
	balance = v_receipt - v_contributions;
		IF(balance is null)THEN balance = 0; END IF;
	
	RETURN balance;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION get_total_repayment(integer) RETURNS real AS $$
	SELECT CASE WHEN sum(repayment_paid + interest_paid + penalty_paid) is null THEN 0 
		ELSE sum(repayment_paid + interest_paid + penalty_paid) END
	FROM loan_monthly
	WHERE (loan_id = $1);
$$ LANGUAGE SQL;


CREATE OR REPLACE FUNCTION get_loan_balance(integer, integer) RETURNS double precision AS $$
	SELECT sum(monthly_repayment + loan_intrest)
	FROM vw_loan_payments 
	WHERE (loan_id = $1) and (months <= $2);
$$ LANGUAGE SQL;



CREATE OR REPLACE FUNCTION ins_contributions() RETURNS trigger AS $$
DECLARE
	v_amount				real;
	reca					RECORD;
	v_loans					real;
	v_contributions			real;
	v_penalty				real;
	v_intrest				real;
	v_repayment				real;
	v_contribution			real;
	currencyid				integer;
	entityname      		varchar(120);
	journalid				integer;
BEGIN
	IF((NEW.is_paid = true) AND (NEW.receipt > 0))THEN
	IF (New.receipt_date IS NULL) THEN New.receipt_date = now()::date; END IF;
			-- post to journals and gls
		SELECT entitys.entity_name, currency.currency_id INTO entityname,currencyid FROM entitys 
		INNER JOIN  currency ON currency.org_id = entitys.org_id where entity_id = NEW.entity_id; 
		
		INSERT INTO journals (period_id, journal_date, org_id, department_id, currency_id, narrative, year_closing)
		VALUES (New.period_id, NEw.receipt_date ,New.org_id, 1, currencyid, entityname || ' Contributions ', false) returning journal_id 
		into journalid ;
		
		INSERT INTO gls ( journal_id, account_id, debit,credit, gl_narrative,  org_id)
		VALUES (journalid, 34005, New.receipt, 0, entityname || ' contribution Amount', NEW.org_id) ;
		
		INSERT INTO  gls (journal_id, account_id, debit, credit, gl_narrative, org_id)
		VALUES ( journalid, 40000,0, NEw.receipt,  entityname || 'contribution Amount ', NEW.org_id);


			--- Compute the full previous balance
		SELECT sum(loan_monthly.penalty_paid + loan_monthly.interest_paid + loan_monthly.repayment_paid)
			INTO v_loans
		FROM loan_monthly INNER JOIN loans ON loan_monthly.loan_id = loans.loan_id
			INNER JOIN periods ON loan_monthly.period_id = periods.period_id
		WHERE (loans.entity_id = NEW.entity_id) AND (periods.end_date <= NEW.entry_date);
		IF(v_loans is null)THEN v_loans = 0; END IF;
		--Get new  amount on previous contributions 
		
		SELECT sum(contributions.receipt - contributions.contribution_paid+ additional_funds.additional_amount) INTO v_contributions
		FROM contributions INNER JOIN periods ON contributions.period_id = periods.period_id INNER JOIN  additional_funds ON additional_funds.contribution_id = contributions.contribution_id
		WHERE (contributions.contribution_id <> NEW.contribution_id) AND (contributions.entity_id = NEW.entity_id)
			AND (periods.end_date <= NEW.entry_date);
		IF(v_contributions is null)THEN v_contributions = 0; END IF;
		
		v_amount := NEW.receipt + v_contributions - v_loans;
		
	
		FOR reca IN SELECT loan_monthly.loan_id, sum(loan_monthly.penalty - loan_monthly.penalty_paid) as s_penalty, 
				sum(loan_monthly.interest_amount - loan_monthly.interest_paid) as s_intrest, 
				sum(loan_monthly.repayment - loan_monthly.repayment_paid) as s_repayment
			FROM loan_monthly INNER JOIN loans ON loan_monthly.loan_id = loans.loan_id
			WHERE (loans.entity_id = NEW.entity_id)
			GROUP BY loan_monthly.loan_id
		LOOP
			v_penalty := reca.s_penalty;
 			v_intrest := reca.s_intrest;
			v_repayment := reca.s_repayment;
		
			IF(v_penalty > 0)THEN
				IF(v_penalty <= v_amount)THEN
					v_amount := v_amount - v_penalty;
					
				ELSE
					v_penalty := v_amount;
					v_amount := 0;
				END IF;
			END IF;

			IF(v_intrest > 0)THEN
				IF(v_intrest <= v_amount)THEN
					v_amount := v_amount - v_intrest;
				ELSE
					v_intrest := v_amount;
					v_amount := 0;
				END IF;
			END IF;

			IF(v_repayment > 0)THEN
				IF(v_repayment <= v_amount)THEN
					v_amount := v_amount - v_repayment;
				ELSE
					v_repayment := v_amount;
					v_amount := 0;
				END IF;
			END IF;
			IF (v_intrest is null) THEN v_intrest = 0; END IF;
			UPDATE loan_monthly SET penalty_paid = v_penalty, interest_paid = v_intrest, repayment_paid = v_repayment, is_paid = true
			WHERE loan_id = reca.loan_id AND period_id = NEW.period_id;
		END LOOP;
		
		-- get sum before doing the insert not to affect current insert 

		
		SELECT sum(contribution_amount - contribution_paid +  additional_funds.additional_amount) INTO v_contribution
		FROM contributions INNER JOIN periods ON contributions.period_id = periods.period_id  INNER JOIN  additional_funds on additional_funds.contribution_id = contributions.contribution_id
		WHERE (contributions.contribution_id <> NEW.contribution_id) AND (contributions.entity_id = NEW.entity_id)
			AND (periods.end_date <= NEW.entry_date);
		IF(v_contribution is null)THEN v_contribution = 0; END IF;
		
		--Raise notice 'this contribution ni hii %', v_contribution;
		--Raise notice ' contribution ni hii %', NEW.contribution_amount;
		
		v_contribution := v_contribution + NEW.contribution_amount;
		
		--Raise notice ' contribution ni hii %', v_contribution;
		--Raise notice ' Amount ni hii %', v_amount;
		
		IF(v_contribution > 0)THEN
			IF(v_contribution <= v_amount)THEN
				NEW.contribution_paid := v_contribution;
			ELSE
				IF(v_amount is null)THEN v_amount = 0; END IF;
				NEW.contribution_paid := v_amount;
			END IF;
		END IF;
		
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_contributions BEFORE INSERT OR UPDATE  ON contributions FOR EACH ROW
EXECUTE PROCEDURE ins_contributions();

