-- CREATE OR REPLACE FUNCTION ins_id()
--   RETURNS trigger AS
-- $BODY$
-- DECLARE
-- v_entity_id	integer;
-- BEGIN
-- IF (NEW.entity_id is null) THEN
-- 	SELECT entity_id INTO v_entity_id from members where member_id = NEW.member_id;
-- 	NEW.entity_id = v_entity_id;
-- END IF;
-- RETURN NEW;
-- END;
-- $BODY$
--   LANGUAGE plpgsql;
-- 
-- CREATE TRIGGER ins_id
--   BEFORE INSERT
--   ON contributions
--   FOR EACH ROW
--   EXECUTE PROCEDURE ins_id();

CREATE OR REPLACE FUNCTION ins_periods()  RETURNS trigger AS
$BODY$
	DECLARE
		v_period_id					integer;
		v_mgr_number				integer;
		v_org_id					integer;
		v_merry_go_round_number		integer;
BEGIN
	IF (NEW.approve_status = 'Approved') THEN
		NEW.opened = false;
		NEW.activated = false;
		NEW.closed = true;
	END IF;
	
	IF(TG_OP = 'INSERT')THEN
		SELECT mgr_number, org_id INTO v_mgr_number, v_org_id
		FROM periods
		WHERE (period_id = (SELECT max(period_id) FROM periods WHERE org_id = NEW.org_id));
		
		IF(v_mgr_number is null)THEN
			SELECT min(merry_go_round_number) INTO v_mgr_number
			FROM members
			WHERE org_id = NEW.org_id;
			
		ELSE
			v_mgr_number := v_mgr_number + 1;
		END IF;
		
		SELECT merry_go_round_number INTO v_merry_go_round_number 
		FROM members
		WHERE org_id = NEW.org_id and merry_go_round_number = v_mgr_number;
		
		IF (v_merry_go_round_number is null) THEN
			SELECT min(merry_go_round_number) INTO v_merry_go_round_number 
			FROM members
			WHERE org_id = NEW.org_id and merry_go_round_number > v_mgr_number;
	
			v_mgr_number := v_merry_go_round_number;
		END IF;
		
		NEW.mgr_number := v_mgr_number;
	END IF;


	RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ins_contrib()
  RETURNS trigger AS
$BODY$
	DECLARE
		v_mgr_number				integer;
		v_org_id					integer;
		v_contribution_type_id		integer;
		v_money_out					real;
		v_period_id					integer;
		v_entity_id					integer;
		v_merry_go_round_number		integer;
		rec							record;
		v_amount					real;

BEGIN
	SELECT  org_id,  SUM(merry_go_round_amount) INTO  v_org_id, v_money_out
	FROM contributions
	WHERE paid = true AND period_id = NEW.period_id 
	GROUP BY org_id;
	
	v_period_id := NEW.period_id;
		--raise exception '%, %',v_period_id, v_money_out;
	SELECT mgr_number INTO v_mgr_number 
	FROM periods  WHERE period_id = NEW.period_id AND org_id = v_org_id;
	
	SELECT entity_id, merry_go_round_number INTO v_entity_id, v_merry_go_round_number 
	FROM vw_member_contrib 
	WHERE merry_go_round_number = v_mgr_number AND org_id = v_org_id;
	
	IF (v_entity_id is not null) AND (v_merry_go_round_number is not null) THEN
		SELECT org_id, period_id, entity_id, amount INTO rec FROM drawings 
		WHERE org_id = v_org_id AND period_id = v_period_id AND entity_id = v_entity_id;
		IF (rec.org_id= v_org_id) AND (rec.period_id = v_period_id) AND (rec.entity_id = v_entity_id) THEN 
		--v_amount := rec.amount+v_money_out;
			UPDATE drawings SET amount = v_money_out WHERE org_id = v_org_id AND period_id = v_period_id AND entity_id = v_entity_id;
		ELSE
			INSERT INTO drawings(org_id, period_id, entity_id,narrative, amount)
			VALUES(v_org_id, v_period_id, v_entity_id,'Merry go round Cash', v_money_out);
		END IF;
	END IF;
--raise exception '%',v_money_out;
	RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql;
  
CREATE TRIGGER ins_contrib
AFTER INSERT OR UPDATE of paid
ON contributions
FOR EACH ROW
EXECUTE PROCEDURE ins_contrib();

CREATE OR REPLACE FUNCTION ins_contributions()
  RETURNS trigger AS
$BODY$
	DECLARE
		reca 				record;
		rec 				record;
		reco 				record;
		v_entity_id			integer;
		recp				record;
		v_bal				real;
		v_total_loan		real;
		v_investment_amount	real;
BEGIN
	SELECT SUM(investment_amount) INTO v_investment_amount 
	FROM contributions WHERE paid = true AND entity_id = NEW.entity_id AND period_id = NEW.period_id;
	v_entity_id := NEW.entity_id;
	FOR reca IN SELECT loan_id, approve_status FROM vw_loans WHERE entity_id = v_entity_id LOOP
		IF(reca.approve_status = 'Approved' ) THEN
			FOR rec IN  SELECT (interest_amount+repayment+penalty_paid)AS amount FROM vw_loan_monthly
			WHERE entity_id = v_entity_id AND period_id = NEW.period_id AND loan_id = reca.loan_id LOOP
			
			v_bal := v_investment_amount - rec.amount;
			
				IF (v_bal > 0) THEN
					FOR recp IN SELECT SUM(amount - penalty_paid) AS penalty_amount, penalty_type_id, bank_account_id,
					currency_id, org_id, penalty_paid 
					FROM penalty WHERE entity_id = v_entity_id 
					GROUP BY penalty_type_id, bank_account_id, currency_id, org_id, penalty_paid  LOOP
						IF((v_bal <= recp.penalty_amount) )THEN
							INSERT INTO penalty ( penalty_type_id, bank_account_id, currency_id, org_id, penalty_paid)
							VALUES(recp.penalty_type_id, recp.bank_account_id, recp.currency_id, recp.org_id, v_bal);
							v_bal := 0;
						END IF;
					IF((v_bal - recp.penalty_amount) > 0 )THEN
						v_bal := v_bal - recp.penalty_amount;
					
						INSERT INTO penalty ( penalty_type_id, bank_account_id, currency_id, org_id, penalty_paid)
						VALUES(recp.penalty_type_id, recp.bank_account_id, recp.currency_id, recp.org_id, recp.penalty_amount);
						
					END IF;
						
					END LOOP;
				END IF;
			END LOOP;
		END IF;
	END LOOP;
RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql;

CREATE TRIGGER ins_contributions
  AFTER INSERT OR UPDATE OF paid
  ON contributions
  FOR EACH ROW
  EXECUTE PROCEDURE ins_contributions();

CREATE OR REPLACE FUNCTION weeks_in_range(date,date,integer)
  RETURNS integer AS
$BODY$
	DECLARE
		v_days                integer;
		v_weeks                integer;
		v_fdow                integer;
		v_ldow                integer;
BEGIN
    v_days := 1 + $2 - $1;
    v_fdow := EXTRACT(DOW FROM $1);
    v_ldow := EXTRACT(DOW FROM $2);

    v_weeks := v_days / 7;
    IF(v_fdow > v_ldow)THEN
        IF($3 >= v_fdow) OR ($3 <= v_ldow) THEN
            v_weeks := (v_days + 7) / 7;           
        END IF;
    ELSE
        IF($3 >= v_fdow) AND ($3 <= v_ldow) THEN
            v_weeks := (v_days + 7) / 7;
        END IF;
    END IF;
   
    RAISE NOTICE 'Days %,  weeks %, DOW %, FDOW %, LDOW %', v_days, v_weeks, $3, v_fdow, v_ldow;

    return v_weeks;
END;
$BODY$
  LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION generate_contribs(
    character varying,
    character varying,
    character varying)
  RETURNS character varying AS
$BODY$
DECLARE
	rec						RECORD;
	recu			RECORD;
	v_period_id		integer;
	vi_period_id		integer;
	reca			RECORD;
	v_org_id		integer;
	v_month_name	varchar(50);
	v_start_date		date;
	v_end_date		date;
	v_day			varchar(12);
	v_ 		integer;
	v_weeks			integer;
	msg 			varchar(120);
BEGIN
	SELECT period_id, org_id, start_date, end_date, to_char(start_date, 'Month YYYY') INTO v_period_id, v_org_id, v_start_date, v_end_date, v_month_name
	FROM periods
	WHERE (period_id = $1::integer);

	SELECT period_id INTO vi_period_id FROM contributions WHERE period_id in (v_period_id) AND org_id in (v_org_id);

	IF( vi_period_id is null) THEN

		FOR reca IN SELECT entity_id FROM members WHERE (org_id = v_org_id) LOOP
		
			FOR rec IN SELECT  day_of_contrib, org_id, frequency, contribution_type_id, investment_amount, merry_go_round_amount, applies_to_all,
				CASE  WHEN  day_of_contrib='Sunday' THEN 0
					WHEN day_of_contrib= 'Monday' THEN  1
					WHEN day_of_contrib= 'Tuesday' THEN  2
					WHEN day_of_contrib ='Wednesday' THEN 3
					WHEN day_of_contrib= 'Thursay' THEN 4
					WHEN day_of_contrib='Friday' THEN 5
					ELSE  6
				END as v_days
			FROM contribution_types WHERE  (org_id = v_org_id) LOOP
				IF(rec.applies_to_all = true) THEN
					IF (rec.frequency = 'Weekly') THEN
						v_weeks := (SELECT weeks_in_range(v_start_date, v_end_date, rec.v_days::integer ));
						FOR i in 1..v_weeks LOOP
							INSERT INTO contributions (period_id, org_id, contribution_type_id, investment_amount, merry_go_round_amount, entity_id)
							VALUES(v_period_id, rec.org_id, rec.contribution_type_id, rec.investment_amount, rec.merry_go_round_amount,
							reca.entity_id);
						END LOOP;
					END IF;
					IF (rec.frequency = 'Fortnightly') THEN
						FOR i in 1..2 LOOP
							INSERT INTO contributions (period_id, org_id, contribution_type_id, investment_amount, merry_go_round_amount, entity_id)
							VALUES(v_period_id, rec.org_id, rec.contribution_type_id, rec.investment_amount, rec.merry_go_round_amount,
							reca.entity_id);
						END LOOP;
					END IF;
					IF (rec.frequency = 'Monthly') THEN
						INSERT INTO contributions (period_id, org_id, contribution_type_id, investment_amount, merry_go_round_amount,entity_id)
						VALUES(v_period_id, rec.org_id, rec.contribution_type_id, rec.investment_amount, rec.merry_go_round_amount,
						reca.entity_id);
					END IF;
					IF (rec.frequency = 'Quarterly') THEN
						INSERT INTO contributions (period_id, org_id, contribution_type_id, investment_amount, merry_go_round_amount,entity_id)
						VALUES(v_period_id, rec.org_id, rec.contribution_type_id, rec.investment_amount, rec.merry_go_round_amount,
						reca.entity_id);
					END IF;
					IF (rec.frequency = 'Semi-annually') THEN
						INSERT INTO contributions (period_id, org_id, contribution_type_id, investment_amount, merry_go_round_amount,entity_id)
						VALUES(v_period_id, rec.org_id, rec.contribution_type_id, rec.investment_amount, rec.merry_go_round_amount,
						reca.entity_id);
					END IF;
					IF (rec.frequency = 'Annually') THEN
						INSERT INTO contributions (period_id, org_id, contribution_type_id, investment_amount, merry_go_round_amount,entity_id)
						VALUES(v_period_id, rec.org_id, rec.contribution_type_id, rec.investment_amount, rec.merry_go_round_amount,
						reca.entity_id);
					END IF;
				END IF;
				IF(rec.applies_to_all = false) THEN
					SELECT contribution_type_id, entity_id INTO recu 
					FROM contribution_defaults WHERE contribution_type_id = rec.contribution_type_id AND entity_id = reca.entity_id AND org_id = rec.org_id;
					IF (rec.frequency = 'Weekly') THEN
					v_weeks := (SELECT weeks_in_range(v_start_date, v_end_date, rec.v_days::integer ));
						FOR i in 1..v_weeks LOOP
							INSERT INTO contributions (period_id, org_id, contribution_type_id, investment_amount, merry_go_round_amount, entity_id)
							VALUES(v_period_id, rec.org_id, recu.contribution_type_id, rec.investment_amount, rec.merry_go_round_amount,
							recu.entity_id);
						END LOOP;
					END IF;
					IF (rec.frequency = 'Fortnightly') THEN
						FOR i in 1..2 LOOP
							INSERT INTO contributions (period_id, org_id, contribution_type_id, investment_amount, merry_go_round_amount, entity_id)
							VALUES(v_period_id, rec.org_id, recu.contribution_type_id, rec.investment_amount, rec.merry_go_round_amount,
							recu.entity_id);
						END LOOP;
					END IF;
					IF (rec.frequency = 'Monthly') THEN
						INSERT INTO contributions (period_id, org_id, contribution_type_id, investment_amount, merry_go_round_amount,entity_id)
						VALUES(v_period_id, rec.org_id, recu.contribution_type_id, rec.investment_amount, rec.merry_go_round_amount,
						recu.entity_id);
					END IF;
					IF (rec.frequency = 'Quarterly') THEN
						INSERT INTO contributions (period_id, org_id, contribution_type_id, investment_amount, merry_go_round_amount,entity_id)
						VALUES(v_period_id, rec.org_id, recu.contribution_type_id, rec.investment_amount, rec.merry_go_round_amount,
						recu.entity_id);
					END IF;
					IF (rec.frequency = 'Semi-annually') THEN
						INSERT INTO contributions (period_id, org_id, contribution_type_id, investment_amount, merry_go_round_amount,entity_id)
						VALUES(v_period_id, rec.org_id, rec.contribution_type_id, rec.investment_amount, rec.merry_go_round_amount,
						recu.entity_id);
					END IF;
					IF (rec.frequency = 'Annually') THEN
						INSERT INTO contributions (period_id, org_id, contribution_type_id, investment_amount, merry_go_round_amount,entity_id)
						VALUES(v_period_id, rec.org_id, rec.contribution_type_id, rec.investment_amount, rec.merry_go_round_amount,
						recu.entity_id);
					END IF;
				END IF;
				
			END LOOP;
		
		END LOOP;
	msg := 'Contributions Generated';
	ELSE
	msg := 'Contributions already exist';
	END IF;
	RETURN msg;	
END;
$BODY$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ins_newcontrib()
  RETURNS trigger AS
$BODY$
	DECLARE
		rec				record;
		v_amount		real;
		reca			record;
		v_sum			real;
		v_id			integer;
		v_newamount		real;
BEGIN
--SELECT * INTO reca FROM contributions 
--WHERE reca.entity_id = NEW.entity_id AND reca.period_id = NEW.period_id AND reca.org_id = NEW.org_id;

	v_amount = NEW.investment_amount + NEW.merry_go_round_amount + NEW.loan_contrib;

	SELECT receipts_id, remaining_amount INTO v_id, v_sum FROM receipts 
	WHERE entity_id = NEW.entity_id AND remaining_amount > 0;

	IF (v_sum > v_amount) THEN 
		UPDATE contributions SET paid = true WHERE contribution_id = NEW.contribution_id;
		v_newamount := v_sum - v_amount;
		UPDATE receipts SET remaining_amount = v_newamount WHERE receipts_id = v_id;
	END IF;

RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql;
 
CREATE TRIGGER ins_newcontrib
  AFTER INSERT 
  ON contributions
  FOR EACH ROW
  EXECUTE PROCEDURE ins_newcontrib();

CREATE OR REPLACE FUNCTION generate_paid(
    character varying,
    character varying,
    character varying)
  RETURNS character varying AS
$BODY$
	DECLARE
		msg		 				varchar(120);
		v_paid					boolean;	
BEGIN
	SELECT paid INTO v_paid FROM contributions WHERE contribution_id = $1::int;
	--RAISE EXCEPTION '%', v_paid;
	IF(v_paid = false) THEN
		UPDATE contributions SET paid = true WHERE contribution_id = $1::int ;
		msg = 'Paid';
	ELSE
		msg = 'Already paid';
	END IF;

RETURN msg;
END;
$BODY$
  LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION ins_receipt()
  RETURNS trigger AS
$BODY$
	DECLARE
		rec				record;
		reca			record;
		v_amount		real;
		v_remainder		real;
		v_total 		real;
		v_id 			integer;
		v_sum			real;
		v_inv_amount	real;
		v_pid			integer;
BEGIN
	v_amount := NEW.amount;
	v_total := 0;
	FOR rec IN SELECT remaining_amount, receipts_id 
	FROM receipts WHERE period_id=NEW.period_id AND entity_id = NEW.entity_id LOOP
		v_amount := v_amount +	rec.remaining_amount;
		UPDATE receipts SET remaining_amount = 0 WHERE receipts_id = rec.receipts_id;
	END LOOP;
	--RAISE EXCEPTION '%',v_amount;
	FOR reca In SELECT contribution_id, investment_amount, merry_go_round_amount, loan_contrib, entity_id, period_id, org_id 
	FROM contributions WHERE paid = false AND entity_id = NEW.entity_id AND org_id = NEW.org_id LOOP
		v_sum := reca.investment_amount + reca.merry_go_round_amount + reca.loan_contrib;
		v_total := v_sum;
		v_inv_amount := reca.investment_amount;
		--v_remainder := v_amount - v_sum;
		IF (v_amount >= v_sum) THEN 
			UPDATE contributions SET paid = true WHERE contribution_id= reca.contribution_id;
			v_amount := v_amount - v_sum;
			v_id = reca.contribution_id;
		END IF;
		--raise exception '%',	v_amount;
	END LOOP;
	
	FOR rec IN SELECT penalty_id, entity_id, amount 
	FROM penalty WHERE paid = false AND entity_id = NEW.entity_id AND org_id = NEW.org_id LOOP
		IF (v_amount >= rec.amount) THEN 
			UPDATE penalty SET paid = true WHERE penalty_id= rec.penalty_id;
			v_amount := v_amount - rec.amount;
			v_pid = rec.penalty_id;
		END IF;
	END LOOP;
	IF (v_amount > 0) THEN 
			UPDATE receipts SET remaining_amount = v_amount WHERE receipts_id = NEW.receipts_id;
	END IF;

RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql;

CREATE TRIGGER ins_receipt
  AFTER INSERT OR UPDATE OF amount
  ON receipts
  FOR EACH ROW
  EXECUTE PROCEDURE ins_receipt();

CREATE OR REPLACE FUNCTION upd_email()
  RETURNS trigger AS
$BODY$
BEGIN
	IF (TG_OP = 'INSERT') THEN
		INSERT INTO sys_emailed ( table_id, sys_email_id, table_name, email_type)
		VALUES (10, 6, TG_TABLE_NAME, 5);
	END IF;

RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql;

--  CREATE TRIGGER upd_email AFTER INSERT ON contributions
--     FOR EACH ROW EXECUTE PROCEDURE upd_email();


CREATE OR REPLACE FUNCTION ins_members() RETURNS trigger AS $$
	DECLARE
		rec 				RECORD;
		v_entity_id			integer;
		v_full_name			varchar(250);
BEGIN
	IF (TG_OP = 'INSERT') THEN
	
		IF (New.email is null)THEN
			RAISE EXCEPTION 'You have to enter an Email';
		ELSIF(NEW.first_name is null) AND (NEW.surname is null)THEN
			RAISE EXCEPTION 'You have need to enter Surname and First Name';
		ELSE
			Raise NOTICE 'Thank you';
		END IF;
		
		IF(NEW.Middle_name is null)THEN
			v_full_name =  NEW.First_name || '' || NEW.Surname;
		ELSE
			v_full_name =  NEW.First_name || ' ' || NEW.Middle_name || ' ' || NEW.Surname;
		END IF;
		NEW.full_name := v_full_name;
		
		IF(NEW.entity_id is null)THEN
			NEW.entity_id := nextval('entitys_entity_id_seq');

			INSERT INTO entitys (entity_id, org_id, entity_type_id, entity_name,
				user_name, primary_email, primary_telephone, function_role, details)
			VALUES (NEW.entity_id, New.org_id, 1, v_full_name,
				NEW.email, NEW.email, NEW.phone, 'member', NEW.details);
		END IF;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
 
CREATE TRIGGER ins_members
  BEFORE INSERT
  ON members
  FOR EACH ROW
  EXECUTE PROCEDURE ins_members();

CREATE OR REPLACE FUNCTION get_total_repayment(real, real, real) RETURNS real AS $$
	DECLARE
		repayment	real;
		ri			real;
BEGIN
	ri := (($1* $2 * $3)/1200);
	repayment := $1 + (($1* $2 * $3)/1200);
	RETURN repayment;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION get_interest_amount(real,real,real) RETURNS real AS $$
	DECLARE
		ri	real;
BEGIN
	ri :=(($1* $2 * $3)/1200);
RETURN ri;
END;
$$ LANGUAGE plpgsql;

 
CREATE OR REPLACE FUNCTION ins_investment()
  RETURNS trigger AS
$BODY$
DECLARE
	v_interests			real;
	
BEGIN
	SELECT interest_amount INTO v_interests FROM  investment_types WHERE investment_type_id = NEW. investment_type_id;
		
	IF (NEW.monthly_payments is null and NEW.principal is not null and  NEW.repayment_period is not null) THEN
		NEW.monthly_payments := NEW.principal/ NEW.repayment_period;
	ELSEIF (NEW.repayment_period is null and NEW.principal is not null and NEW.monthly_payments is not null ) THEN
		NEW.repayment_period := NEW.principal/NEW.monthly_payments;
	ELSEIF (NEW.repayment_period is null AND NEW.monthly_payments is null) THEN
		RAISE EXCEPTION 'Please enter the repayment period or the monthly payments';
	END IF;
	
	RETURN NEW;
END;

$BODY$
  LANGUAGE plpgsql;

CREATE TRIGGER ins_investment BEFORE INSERT OR UPDATE ON investments
	FOR EACH ROW EXECUTE PROCEDURE ins_investment();

CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON investments
    FOR EACH ROW EXECUTE PROCEDURE upd_action();


CREATE OR REPLACE FUNCTION investment_aplication(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	msg 		varchar(120);
BEGIN
	msg := 'Investment applied';
	
	UPDATE investments SET approve_status = 'Completed', investment_status = 'Committed'
	WHERE (investment_id = CAST($1 as int)) AND (approve_status = 'Draft') AND investment_status = 'Prospective';

	return msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_total_expenditure (integer) RETURNS real AS $$
DECLARE
	v_transaction_amount real;

BEGIN
	SELECT SUM(transaction_amount) INTO v_transaction_amount FROM transactions WHERE tx_type = -1 and investment_id  = $1;
	RETURN v_transaction_amount;

END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION get_total_income (integer) RETURNS real AS $$
DECLARE
	v_transaction_amount real;

BEGIN
	SELECT SUM(transaction_amount) INTO v_transaction_amount FROM transactions WHERE tx_type = 1 and investment_id  = $1;
	RETURN v_transaction_amount;

END;
$$ LANGUAGE plpgsql;
  
CREATE OR REPLACE FUNCTION add_member_meeting(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	msg		 				varchar(120);
	v_entity_id				integer;
	v_org_id				integer;
BEGIN

	SELECT entity_id INTO v_entity_id
	FROM member_meeting WHERE (entity_id = $1::int) AND (meeting_id = $3::int);
	
	IF(v_entity_id is null)THEN
		SELECT org_id INTO v_org_id
		FROM meetings WHERE (meeting_id = $3::int);
		
		INSERT INTO  member_meeting (meeting_id, entity_id, org_id)
		VALUES ($3::int, $1::int, v_org_id);

		msg := 'Added to meeting';
	ELSE
		msg := 'Already Added to meeting';
	END IF;
	
	return msg;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION remove_member_meeting(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	msg		 				varchar(120);
	v_entity_id				integer;
	v_org_id				integer;
BEGIN

	SELECT entity_id INTO v_entity_id
	FROM member_meeting WHERE (entity_id = $1::int) AND (meeting_id = $3::int);
	
	IF(v_entity_id is not null)THEN
		SELECT org_id INTO v_org_id
		FROM meetings WHERE (meeting_id = $3::int);
		
		DELETE FROM  member_meeting WHERE entity_id = v_entity_id AND (meeting_id = $3::int);
		

		msg := 'Removed from meeting';
		END IF;
	
	return msg;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER upd_email AFTER INSERT ON investments
    FOR EACH ROW EXECUTE PROCEDURE upd_email();

CREATE TRIGGER upd_email AFTER INSERT ON borrowing
    FOR EACH ROW EXECUTE PROCEDURE upd_email();
    
--  CREATE TRIGGER upd_email AFTER INSERT ON meetings
--     FOR EACH ROW EXECUTE PROCEDURE upd_email();
    
CREATE TRIGGER upd_email AFTER INSERT ON drawings
    FOR EACH ROW EXECUTE PROCEDURE upd_email();


CREATE TRIGGER upd_email AFTER INSERT ON penalty
    FOR EACH ROW EXECUTE PROCEDURE upd_email();

CREATE OR REPLACE FUNCTION email_before(
    integer,
    integer,
    character varying)
  RETURNS character varying AS
$BODY$
DECLARE
	msg		 				varchar(120);
BEGIN
	INSERT INTO sys_emailed (sys_email_id, table_id, org_id, table_name, email_type)
	VALUES (7, $1, $2, 'meetings', 7);
	msg := 'Email Sent';
	return msg;
END;
$BODY$
  LANGUAGE plpgsql;
  
CREATE OR REPLACE FUNCTION email_after(
    integer,
    integer,
    character varying)
  RETURNS character varying AS
$BODY$
DECLARE
	msg		 				varchar(120);
BEGIN
	INSERT INTO sys_emailed ( sys_email_id, table_id, org_id, table_name, email_type)
	VALUES (8, $1, $2, 'meetings', 8);
	msg := 'Email Sent';
	return msg;
END;
$BODY$
  LANGUAGE plpgsql;
    
CREATE OR REPLACE FUNCTION generate_repayment(
    character varying,
    character varying,
    character varying)
  RETURNS character varying AS
$BODY$
DECLARE
    rec            RECORD;
    recu            RECORD;
    reca            RECORD;
    v_penalty        real;
    v_org_id        integer;
    v_period_id        integer;
    v_month_name        varchar(20);
    vi_period_id        integer;
    v_loan_type_id        integer;
    v_loan_intrest        real;
    v_loan_id        integer;
    msg            varchar(120);
BEGIN
	SELECT   period_id, org_id, to_char(start_date, 'Month YYYY') INTO v_period_id, v_org_id, v_month_name
    FROM periods
    WHERE (period_id = $1::integer);
	SELECT loan_month_id, loan_id, period_id, org_id, interest_amount, repayment, interest_paid, penalty_paid INTO recu
	FROM loan_monthly WHERE period_id in (v_period_id) AND org_id in (v_org_id);

    IF( recu.period_id is null) THEN
    
        FOR rec IN SELECT org_id, loan_id, loan_type_id, monthly_repayment FROM loans WHERE (org_id = v_org_id) LOOP
        /*RAISE EXCEPTION '%',rec.loan_id; */   
        SELECT loan_intrest, loan_id INTO v_loan_intrest, v_loan_id FROM vw_loan_payments WHERE v_loan_id = rec.loan_id;
        recu.repayment = rec.monthly_repayment - v_loan_intrest;
        INSERT INTO loan_monthly (loan_id, period_id, org_id, interest_amount, repayment, interest_paid)
        VALUES(rec.loan_id, v_period_id, rec.org_id, v_loan_intrest, recu.repayment,  v_loan_intrest);
		END LOOP;

		msg := 'Repayment Generated';
    END IF;

    return msg;
END;
$BODY$
  LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_total_contribs(integer, integer) RETURNS real AS $$
	SELECT SUM(total_contribution) as contributions
	FROM vw_contributions WHERE (entity_id = $1) and (org_id = $2);
$$ LANGUAGE SQL;
  
CREATE OR REPLACE FUNCTION get_total_drawings(integer, integer) RETURNS real AS $$
	SELECT SUM(amount) as drawings
	FROM vw_drawings WHERE (entity_id = $1) and (org_id = $2);
$$ LANGUAGE SQL;
  
CREATE OR REPLACE FUNCTION get_total_receipts(integer, integer) RETURNS real AS $$
	SELECT SUM(amount) as receipts
	FROM vw_receipts WHERE (entity_id = $1) and (org_id = $2);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_total_loans(integer, integer) RETURNS real AS $$
	SELECT SUM(principle) as loans
	FROM vw_loans  WHERE (entity_id = $1) and (org_id = $2);
$$ LANGUAGE SQL;
  
CREATE OR REPLACE FUNCTION get_total_loan_monthly(integer, integer) RETURNS real AS $$
	SELECT SUM(total_repayment) as loan_monthly
	FROM vw_loan_monthly WHERE (entity_id = $1) and (org_id = $2);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_total_penalty(integer, integer) RETURNS real AS $$
	SELECT SUM(amount) as penalty
	FROM vw_penalty WHERE paid= false AND (entity_id = $1) AND (org_id = $2);
$$ LANGUAGE SQL;
