	

--LOAN SETUP===================
CREATE OR REPLACE FUNCTION loanSetup() RETURNS trigger AS $$
DECLARE

	prd_id		integer;
	jnl_id		integer;
	acc_id		integer;

	cli_acc_id		integer;		--clients a/c
	disb_acc_id		integer;		--disbursement control a/c
	

	fee_charge	real;
	
	loan_principal	real;
	effective_loan	real;		--LOAN + INTEREST

	sum_charges		real;
	chattels_fee	real;

	rec_investor 	record;
	rec_borrower 	record;
BEGIN
	
	sum_charges := 0;
	loan_principal := 0;
	chattels_fee	:= 0;		


	jnl_id := nextval('journals_journal_id_seq');
	
	--get the xponding period
	SELECT MAX(period_id) INTO prd_id FROM periods WHERE NEW.loandate BETWEEN period_start AND period_end;
	
	--getnextval();
	--IF (TG_OP = 'INSERT') THEN
	SELECT account_id INTO cli_acc_id FROM accounts WHERE account_id = (SELECT account_id FROM borrower WHERE borrower_id = (SELECT borrower_id FROM loans WHERE loan_id = NEW.loan_id));

	IF (NEW.loanapproved = true AND cli_acc_id IS NOT NULL) THEN		--we need to run this on loan approvals
	
		SELECT loans.principal, geteffectiveloan(loans.loan_id, loans.repaymentperiod) INTO loan_principal, effective_loan FROM loans WHERE loans.loan_id = NEW.loan_id;

		--SELECT loans.principal INTO loan_principal FROM loans WHERE loan_id = NEW.loan_id;
		loan_principal := NEW.principal;
		SELECT entity_name,borrower_name INTO rec_borrower FROM vwborrower WHERE borrower_id = (SELECT MAX(borrower_id) FROM loans WHERE loan_id = NEW.loan_id);	

		--get  BORROWERS (debtor) account id
		
		--get id of disbursement control account
		--SELECT account_id INTO cli_acc_id FROM accounts WHERE account_name = 'LOAN DISBURSEMENT ACCOUNT';	--hardcoded to 
		disb_acc_id := 71055;

		--JOURNAL ENTRY
		INSERT INTO journals(journal_id,period_id,journal_date,narrative) VALUES(jnl_id,prd_id,NEW.loandate,'Loan Setup');

		--1.............
		--DR. DEBTOR a/c
		INSERT INTO gls(journal_id, account_id, debit, credit) VALUES(jnl_id, cli_acc_id, NEW.principal, 0.0);		
		--CR. DISBURSEMENT a/c
		INSERT INTO gls(journal_id, account_id, debit, credit) VALUES(jnl_id, disb_acc_id, 0.0, NEW.principal);			

		--2............
		--DR: increase in asset(borrower)		
	    INSERT INTO gls(journal_id, account_id, debit, credit) VALUES(jnl_id, cli_acc_id, (effective_loan - loan_principal), 0.0);		
		--CR: increase in revenue(loan interest)
		SELECT account_id INTO acc_id FROM accounts WHERE UPPER(account_name) = 'INTEREST INCOME';		--i can hardcode to 71030
		INSERT INTO gls(journal_id, account_id, debit, credit) VALUES(jnl_id, acc_id,0.0,(effective_loan - loan_principal));				
				

		--CHATTELS
		IF (NEW.chattels_fee = true) THEN

			IF loan_principal >= 20000 AND loan_principal < 50000 THEN
				chattels_fee := 3840;
			ELSIF loan_principal >= 50000 AND loan_principal < 100000 THEN
				chattels_fee := 4420;
			ELSIF loan_principal >= 100000 AND loan_principal < 150000 THEN
				chattels_fee := 5000;
			ELSIF loan_principal >= 150000 AND loan_principal < 200000 THEN
				chattels_fee := 5580;
			ELSIF loan_principal >= 200000 AND loan_principal < 250000 THEN
				chattels_fee := 6160;
			ELSIF loan_principal >= 250000 AND loan_principal < 300000 THEN
				chattels_fee := 6740;
			ELSE
				chattels_fee := 0;
			END IF;
			
			--CR. increase in REVENUE(chattels fee)
			SELECT account_id INTO acc_id FROM accounts WHERE account_name ILIKE UPPER('CHATTELS FEE ACCOUNT');		--charges account
			INSERT INTO gls(journal_id, account_id, debit, credit) VALUES(jnl_id,acc_id, 0.0, chattels_fee);		
		
			--DR: increase Asset(borrower)		
			INSERT INTO gls(journal_id, account_id, debit, credit) VALUES(jnl_id, cli_acc_id, chattels_fee, 0.0);		

		END IF;

		IF (NEW.processing_fee = true) THEN
			SELECT COALESCE(fee_value,0) INTO fee_charge FROM fees WHERE upper(fee_name) = 'PROCESSING FEE';
			sum_charges := sum_charges + fee_charge;		

			--CR. increase in REVENUE(processing fee)
			SELECT account_id INTO acc_id FROM accounts WHERE account_name ILIKE UPPER('PROCESSING FEE ACCOUNT');		--charges account
			INSERT INTO gls(journal_id, account_id, debit, credit) VALUES(jnl_id,acc_id, 0.0, fee_charge);		
		
			--DR: increase Asset(borrower)		
			INSERT INTO gls(journal_id, account_id, debit, credit) VALUES(jnl_id, cli_acc_id, fee_charge, 0.0);		

		END IF;
		IF (NEW.cashing_fee = true)THEN
			SELECT COALESCE(fee_value,0) INTO fee_charge FROM fees WHERE upper(fee_name) = 'CASHING FEE';
			sum_charges := sum_charges + fee_charge;

			--CR. increase in REVENUE(cashing fee)
			SELECT account_id INTO acc_id FROM accounts WHERE account_name ILIKE UPPER('CASHING FEE ACCOUNT');		--charges account
			INSERT INTO gls(journal_id, account_id, debit, credit) VALUES(jnl_id,acc_id, 0.0, fee_charge);		
			
			--DR: increase Asset(borrower)		
			INSERT INTO gls(journal_id, account_id, debit, credit) VALUES(jnl_id, cli_acc_id, fee_charge, 0.0);		
			
		END IF;
		IF (NEW.cheque_fee = true)THEN
			SELECT COALESCE(fee_value,0) INTO fee_charge FROM fees WHERE upper(fee_name) = 'CHEQUE FEE';
			sum_charges := sum_charges + fee_charge;			

			--CR. increase in REVENUE(cheque fee)
			SELECT account_id INTO acc_id FROM accounts WHERE account_name ILIKE UPPER('CHEQUE FEE ACCOUNT');		--charges account
			INSERT INTO gls(journal_id, account_id, debit, credit) VALUES(jnl_id,acc_id, 0.0, fee_charge);		

			--DR: increase Asset(borrower)		
			INSERT INTO gls(journal_id, account_id, debit, credit) VALUES(jnl_id, cli_acc_id, fee_charge, 0.0);		

		END IF;		
		
		--NEW.amount_reinbursed := (loan_principal - sum_charges - chattels_fee);		
					    	
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trLoanSetup AFTER UPDATE ON loans
    FOR EACH ROW EXECUTE PROCEDURE loanSetup();





--LOAN DISBURSEMENT=====================
CREATE OR REPLACE FUNCTION loanDisbursement() RETURNS trigger AS $$
DECLARE

	prd_id		integer;
	jnl_id		integer;
	acc_id		integer;

	cli_acc_id		integer;		--clients a/c
	disb_acc_id		integer;		--disbursement control a/c
	bank_acc_id		integer;

	fee_charge	real;
	
	loan_principal	real;
	effective_loan	real;		--LOAN + INTEREST

	sum_charges		real;
	chattels_fee	real;

	rec_investor 	record;
	rec_borrower 	record;
BEGIN
	
	sum_charges := 0;
	loan_principal := 0;
	chattels_fee	:= 0;		


	jnl_id := nextval('journals_journal_id_seq');
	
	--get the xponding period
	SELECT MAX(period_id) INTO prd_id FROM periods WHERE NEW.disbursement_date BETWEEN period_start AND period_end;

	--a. get  BORROWERS (debtor) account id
	SELECT account_id INTO cli_acc_id FROM accounts WHERE account_id = (SELECT account_id FROM borrower WHERE borrower_id = (SELECT borrower_id FROM loans WHERE loan_id = NEW.loan_id));
	
	--getnextval();
	IF (TG_OP = 'INSERT' AND cli_acc_id IS NOT NULL) THEN	
	
		SELECT loans.principal, geteffectiveloan(loans.loan_id, loans.repaymentperiod) INTO loan_principal, effective_loan FROM loans WHERE loans.loan_id = NEW.loan_id;
		
		SELECT entity_name,borrower_name INTO rec_borrower FROM vwborrower WHERE borrower_id = (SELECT MAX(borrower_id) FROM loans WHERE loan_id = NEW.loan_id);	

		
		--b. get id of disbursement control account
		--SELECT account_id INTO cli_acc_id FROM accounts WHERE account_name = 'LOAN DISBURSEMENT ACCOUNT';	--hardcoded to 71055
		disb_acc_id := 71055;
		--c. get bank account
		SELECT account_id INTO bank_acc_id FROM accounts WHERE account_id = (SELECT account_id FROM bank_accounts WHERE bank_account_id = NEW.bank_account_id);	


		--JOURNAL ENTRY
		INSERT INTO journals(journal_id,period_id,journal_date,narrative) VALUES(jnl_id,prd_id,NEW.disbursement_date,'Loan Disbursement');

		--1.............
		--DR. DISBURSEMENT a/c
		INSERT INTO gls(journal_id, account_id, debit, credit) VALUES(jnl_id, disb_acc_id, loan_principal, 0.0);			

		--DR. BANK a/c
		INSERT INTO gls(journal_id, account_id, debit, credit) VALUES(jnl_id, bank_acc_id, 0.0, loan_principal);		
		


		--2............				
		--FOR NOW WE DONT CLEAR ANY CHARGES		
				--CHATTELS
		IF (NEW.chattels_fee = true) THEN

			IF loan_principal >= 20000 AND loan_principal < 50000 THEN
				chattels_fee := 3840;
			ELSIF loan_principal >= 50000 AND loan_principal < 100000 THEN
				chattels_fee := 4420;
			ELSIF loan_principal >= 100000 AND loan_principal < 150000 THEN
				chattels_fee := 5000;
			ELSIF loan_principal >= 150000 AND loan_principal < 200000 THEN
				chattels_fee := 5580;
			ELSIF loan_principal >= 200000 AND loan_principal < 250000 THEN
				chattels_fee := 6160;
			ELSIF loan_principal >= 250000 AND loan_principal < 300000 THEN
				chattels_fee := 6740;
			ELSE
				chattels_fee := 0;
			END IF;
				
			--chattels is not accounted for
			sum_charges := sum_charges + chattels_fee;
		
		END IF;

		IF (NEW.processing_fee = true) THEN
			SELECT COALESCE(fee_value,0) INTO fee_charge FROM fees WHERE upper(fee_name) = 'PROCESSING FEE';
			sum_charges := sum_charges + fee_charge;		
		END IF;

		IF (NEW.cashing_fee = true)THEN
			SELECT COALESCE(fee_value,0) INTO fee_charge FROM fees WHERE upper(fee_name) = 'CASHING FEE';
			sum_charges := sum_charges + fee_charge;			
		END IF;

		IF (NEW.cheque_fee = true)THEN
			SELECT COALESCE(fee_value,0) INTO fee_charge FROM fees WHERE upper(fee_name) = 'CHEQUE FEE';
			sum_charges := sum_charges + fee_charge;			
		END IF;		
		

		--DR. increase in asset (BANK)
		INSERT INTO gls(journal_id, account_id, debit, credit) VALUES(jnl_id, bank_acc_id, sum_charges, 0.0);			

		--CR. decrease in asset (DEBTORS)
		INSERT INTO gls(journal_id, account_id, debit, credit) VALUES(jnl_id, cli_acc_id, 0.0, sum_charges);		
						
					    	
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trLoanDisbursement AFTER INSERT ON loan_reinbursment
    FOR EACH ROW EXECUTE PROCEDURE loanDisbursement();


DROP TRIGGER tr_ins_employees ON borrower;
CREATE TRIGGER tr_ins_employees
  BEFORE INSERT OR UPDATE
  ON borrower
  FOR EACH ROW
  EXECUTE PROCEDURE ins_borrower();

CREATE SEQUENCE borrower_account_id_seq;

CREATE OR REPLACE FUNCTION fn_add_account(int) RETURNS varchar(120) AS $$
DECLARE
	rec		RECORD;
	wfid	integer;
BEGIN

	SELECT  borrower_id, entity_id, account_id, sur_name, first_name, middle_name, created_by,
		(COALESCE(sur_name, '') || ' ' || COALESCE(middle_name, '') || ' ' ||  COALESCE(first_name, '')) as full_name
	INTO rec
	FROM borrower WHERE borrower_id = $1;
	wfid := nextval('borrower_account_id_seq');

	INSERT INTO accounts (account_id, account_type_id, account_name, currency_id, created_by)
	VALUES(wfid, 300, rec.full_name, 1, rec.created_by);

	UPDATE borrower SET account_id = wfid WHERE borrower_id = $1;

	RETURN 'Done';
END;
$$ LANGUAGE plpgsql;


--ALTER
ALTER TABLE loan_reinbursment DISABLE TRIGGER trPreReinbursement;
ALTER TABLE loan_reinbursment DISABLE TRIGGER trPostReinbursement;

ALTER TABLE loans ADD processing_fee	boolean;
ALTER TABLE loans ADD cheque_fee		boolean;
ALTER TABLE loans ADD chattels_fee		boolean;	


--DELETE
DELETE FROM gls;
DELETE FROM journals;
DELETE FROM loan_reinbursment;


--UPDATES
UPDATE loans SET loanapproved = false,processing_fee = false, cashing_fee = false, chattels_fee = false, cheque_fee = false ;
UPDATE loans SET loanapproved = true, processing_fee = true, cashing_fee = true, chattels_fee = false, cheque_fee = false WHERE principal <= 300000 AND repaymentperiod <=12;

--SELECT * FROM gls;

--BANK(KCB 2) = 2
--PAYMENT MODE = cheque
--PAYMENT MODE (CASH) = 1

INSERT INTO loan_reinbursment(loan_id,bank_account_id,disbursement_date,amount_reinbursed,payment_mode_id,documentnumber,processing_fee,cashing_fee,cheque_fee,chattels_fee)
	(SELECT loan_id,2,loandate,principal,1,'Cheque No',processing_fee,cashing_fee,cheque_fee,chattels_fee FROM loans WHERE loanapproved = true); 	


UPDATE journals SET posted = true;
	
