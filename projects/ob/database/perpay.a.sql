CREATE DATABASE LINK ln_payrol CONNECT TO PERPAYIMIS IDENTIFIED BY PERPAYIMIS2012 USING '172.100.3.22:1533/payrol';

CREATE OR REPLACE TRIGGER ins_imis_perpay_gl AFTER INSERT ON imis_perpay_gl FOR EACH ROW
DECLARE
	pragma autonomous_transaction;
BEGIN
	INSERT INTO imis_perpay_gl@ln_payrol (pfno, NAME, period, sun_ac_code,
		account_name, debit_amount, credit_amount, MONTH)
	VALUES (:NEW.pfno, :NEW.NAME, :NEW.period, :NEW.sun_ac_code,
		:NEW.account_name, :NEW.debit_amount, :NEW.credit_amount, :NEW.MONTH); 
	COMMIT;
END ins_imis_perpay_gl;
/ 

-------------------------------------------------

DROP DATABASE LINK ln_erp;
CREATE PUBLIC DATABASE LINK ln_erp CONNECT TO ERPDBUSER IDENTIFIED BY "Imis2goke" USING '172.100.3.30:1542/imis.cck';

create or replace TRIGGER ins_imis_perpay_gl AFTER INSERT ON imis_perpay_gl FOR EACH ROW
DECLARE
	pragma autonomous_transaction;
BEGIN
	IF(trim(:NEW.sun_ac_code) = '800630')THEN
		INSERT INTO dc_ledger@ln_erp (pf_number, staff_name, period_no, ledger_no,
			payroll_account, description, debit,  credit)
		VALUES (:NEW.pfno, :NEW.NAME, :NEW.MONTH, :NEW.period,
			'100420', :NEW.account_name, :NEW.debit_amount, :NEW.credit_amount);
		COMMIT;
	ELSE
		INSERT INTO dc_ledger@ln_erp (pf_number, staff_name, period_no, ledger_no,
			payroll_account, description, debit,  credit)
		VALUES (:NEW.pfno, :NEW.NAME, :NEW.MONTH, :NEW.period,
			trim(:NEW.sun_ac_code), :NEW.account_name, :NEW.debit_amount, :NEW.credit_amount);
		COMMIT;
	END IF;
End Ins_Imis_Perpay_Gl;
/


