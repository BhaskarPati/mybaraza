INSERT INTO audit.master (audit_user, audit_login) VALUES ('automation', 'automation');

UPDATE client SET ispicked = false;

UPDATE client SET ispicked = true WHERE roid IN
(SELECT client.roid 
FROM client LEFT JOIN ledger ON client.roid = ledger.client_roid
WHERE ledger.client_roid is null);

--------- Ledger correction
DROP TRIGGER tg_audit_ledger ON ledger;
DROP TRIGGER updprice ON ledger;

ALTER TABLE ledger
ADD vat_sign	varchar(320),
ADD is_printed	boolean default false,
ADD	print_time	timestamp,
ADD is_filled	boolean default false;

ALTER TABLE audit.ledger
ADD vat_sign	varchar(320),
ADD is_printed	boolean default false,
ADD	print_time	timestamp,
ADD is_filled	boolean default false;

UPDATE ledger SET is_filled = true WHERE is_filled = false;
UPDATE ledger SET is_printed = true WHERE is_printed = false;
UPDATE ledger SET ispicked = true WHERE ispicked = false; 

UPDATE ledger SET ispicked = false WHERE created > '2011-01-01';

UPDATE ledger SET is_printed = false WHERE (CAST(created as date) = '2011-04-08') AND (is_printed = true);

CREATE TRIGGER updprice
  BEFORE INSERT OR UPDATE
  ON ledger
  FOR EACH ROW
  EXECUTE PROCEDURE updprice();

CREATE TRIGGER tg_audit_ledger
  AFTER INSERT OR UPDATE OR DELETE
  ON ledger
  FOR EACH ROW
  EXECUTE PROCEDURE tg_audit_ledger();

----------- SQL Updates

CREATE OR REPLACE FUNCTION insreceipts() RETURNS trigger AS $$
DECLARE
	lid int;
	mystr varchar(32);
BEGIN
	lid := nextval('ledger_id_seq');

	mystr := 'Cheque Receipt';
	IF(NEW.cash = true) THEN
		mystr := 'Cash Receipt';
	ELSIF(NEW.vatwithheld = true) THEN
		mystr := 'VAT Certificate';
	ELSIF (NEW.smstranid is not null) THEN
		mystr := 'MPESA Transfer';
	END IF;

	INSERT INTO audit.master (audit_user, audit_login) VALUES ('automation', 'automation');

	INSERT INTO ledger (id, client_roid, description, currency, total, trans_type, tld, processor_account_history_id, refund_expiry, refund_grace, refund_amount, documentnumber)
	VALUES (lid, NEW.roid, mystr, 'KES', ((-1) * NEW.amount), 'Payment', 'ke', '2', now(), now(), 0, NEW.receiptid);

	NEW.ledgerid := lid;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION updPrice() RETURNS trigger AS $$
DECLARE
	reca RECORD;
	recb RECORD;
	docno int;
BEGIN
	IF(TG_OP = 'INSERT') THEN		
		IF((NEW.trans_type = 'Renewal') OR (NEW.trans_type = 'Registration') OR (NEW.trans_type = 'Application') OR (NEW.trans_type = 'Training')) THEN
			NEW.documentnumber := nextval('invoiceno_seq');
		ELSIF (NEW.trans_type = 'Refund') THEN
			NEW.documentnumber := nextval('creditnoteno_seq');
		END IF;

		SELECT exdate, crid INTO recb FROM domain
		WHERE name  = NEW.domain_name;

		IF((NEW.trans_type = 'Renewal') OR (NEW.trans_type = 'Registration')) THEN
			NEW.exdate := recb.exdate;
		ELSIF (NEW.trans_type = 'Transfer') THEN
			NEW.transf_roid := recb.crid;
		END IF;
	END IF;

	IF(TG_OP = 'UPDATE') THEN
		IF ((OLD.renewal_refund = false) AND (NEW.renewal_refund = true)) THEN
			INSERT INTO audit.master (audit_user, audit_login) VALUES ('automation', 'automation');

			INSERT INTO ledger (client_roid, description, currency, total, trans_type, tld, processor_account_history_id, refund_expiry, refund_grace, refund_amount, domain_name, refund_for_id, tax, tax_label)
			VALUES (NEW.client_roid, 'Refund on domain renewal', 'KES', ((-1)*NEW.total), 'Refund', 'ke', '2', now(), now(), 0, NEW.domain_name, NEW.id, '16.0', 'VAT');

			UPDATE domain SET exdate = NEW.previous_expiry_date WHERE name = NEW.domain_name;
		END IF;
		IF((OLD.renewal_refund = true) AND (NEW.renewal_refund = false)) THEN
			NEW.renewal_refund := true;
		END IF;
	END IF;

	SELECT updPrice(client.clid) INTO reca
	FROM client
	WHERE (client.roid = NEW.client_roid);

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;


------------ 

CREATE TABLE sms_trans (
	sms_trans_id		serial primary key,
	message				varchar(2400),
	origin				varchar(50),
	sms_time			timestamp,
	client_id			varchar(50),
	code				varchar(25),
	amount				real,
	in_words			varchar(240),
	narrative			varchar(240),
	sms_id				integer,
	sms_deleted			boolean default false not null,
	sms_picked			boolean default false not null,
	part_id				integer,
	part_message		varchar(240),
	part_no				integer,
	part_count			integer,
	complete			boolean default false,
	account_error		boolean default false,
	emailed				boolean[] default '{f, f, f}',
	UNIQUE(origin, sms_time)
);

INSERT INTO sms_trans (sms_trans_id, message, origin, sms_time, client_id, code, amount,
	in_words, narrative, sms_id, sms_deleted, sms_picked, part_id, part_message,
	part_no, part_count, account_error, emailed)
SELECT smstranid, message, origin, smstime, clientid, code, amount, 
	inwords, narrative, smsid, smsdeleted, ispicked, partid, partmessage,
	partno, partcount, accounterror, emailed
FROM smstrans
ORDER BY smstranid;

SELECT pg_catalog.setval('sms_trans_sms_trans_id_seq', 40000, true);

ALTER TABLE receipts
ADD	voided				boolean default false not null,
ADD void_date			timestamp,
ADD	sms_trans_id		integer references sms_trans;
UPDATE receipts SET sms_trans_id = smstranid;
DROP VIEW vwsmstrans;
ALTER TABLE receipts
DROP smstranid;

CREATE TABLE folders (
	folder_id			serial primary key,
	folder_name			varchar(25) unique,
	details				text
);
INSERT INTO folders (folder_id, folder_name) VALUES (0, 'Outbox');
INSERT INTO folders (folder_id, folder_name) VALUES (1, 'Draft');
INSERT INTO folders (folder_id, folder_name) VALUES (2, 'Sent');
INSERT INTO folders (folder_id, folder_name) VALUES (3, 'Inbox');
INSERT INTO folders (folder_id, folder_name) VALUES (4, 'Action');

CREATE TABLE sms (
	sms_id				serial primary key,
	folder_id			integer references folders,
	sms_number			varchar(25),
	sms_time			timestamp default now(),
	message_ready		boolean default false,
	sent				boolean default false,
	message				text,
	details				text
);
CREATE INDEX sms_folder_id ON sms (folder_id);

-- Function: ins_sms_trans()
CREATE OR REPLACE FUNCTION ins_sms_trans() RETURNS trigger AS $$
DECLARE
	clientid varchar(16);
	trxcodes bigint;
BEGIN
	clientid :=  null;
	SELECT clid INTO clientid
	FROM client WHERE clid = NEW.client_id;

	IF((clientid is not null) AND (NEW.amount is not null) AND (trim(NEW.origin) = 'D48617A140') AND (NEW.part_no = 1)) THEN
		SELECT count(receiptid) INTO trxcodes
		FROM receipts WHERE (bankcode = 'MPESA') AND (chequenumber = NEW.code);

		IF(trxcodes = 0) THEN
			INSERT INTO receipts (roid, sms_trans_id, amount, bankcode, chequedate, chequenumber, drawername, inwords, details)
			VALUES (NEW.client_id, NEW.sms_trans_id, NEW.amount, 'MPESA', NEW.sms_time, NEW.code, 'MPESA', NEW.in_words, NEW.message);
		END IF;
	ELSE
		UPDATE sms_trans SET account_error = true WHERE (sms_trans_id = NEW.sms_trans_id);
	END IF;

	IF(NEW.part_no > 1) THEN
		UPDATE sms_trans SET message = message || NEW.part_message WHERE (part_id = NEW.part_id) AND (part_no = 1);
	END IF;

	RETURN null;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_sms_trans AFTER INSERT ON sms_trans
    FOR EACH ROW EXECUTE PROCEDURE ins_sms_trans();

-- Function: upd_sms_trans()
CREATE OR REPLACE FUNCTION upd_sms_trans() RETURNS trigger AS $$
DECLARE
	clientid varchar(16);
	old_clientid varchar(16);
	trxcodes bigint;
BEGIN
	clientid :=  null;
	SELECT clid INTO clientid
	FROM client WHERE clid = NEW.client_id;

	IF((clientid is not null) AND (NEW.amount is not null) AND (trim(NEW.origin) = 'D48617A140') AND (NEW.part_no = 1)) THEN
		IF(OLD.client_id is null) THEN
			old_clientid := '';
		ELSE
			old_clientid := OLD.client_id;
		END IF;
		IF((old_clientid <> NEW.client_id) AND (NEW.account_error = true)) THEN
			SELECT count(receiptid) INTO trxcodes
			FROM receipts WHERE (bankcode = 'MPESA') AND (chequenumber = NEW.code);

			IF(trxcodes = 0) THEN
				INSERT INTO receipts (roid, sms_trans_id, amount, bankcode, chequedate, chequenumber, drawername, inwords, details)
				VALUES (NEW.client_id, NEW.sms_trans_id, NEW.amount, 'MPESA', NEW.sms_time, NEW.code, 'MPESA', NEW.in_words, NEW.message);
			END IF;

			NEW.account_error = false;
		END IF;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER upd_sms_trans BEFORE UPDATE ON sms_trans
    FOR EACH ROW EXECUTE PROCEDURE upd_sms_trans();

CREATE OR REPLACE FUNCTION MPesaEmailed(integer, integer) RETURNS void AS $$
    UPDATE sms_trans SET emailed[$1] = true WHERE (sms_trans_id = $2);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION insreceipts() RETURNS trigger AS $$
DECLARE
	lid int;
	mystr varchar(32);
BEGIN
	lid := nextval('ledger_id_seq');

	mystr := 'Cheque Receipt';
	IF(NEW.cash = true) THEN
		mystr := 'Cash Receipt';
	ELSIF(NEW.vatwithheld = true) THEN
		mystr := 'VAT Certificate';
	ELSIF (NEW.sms_trans_id is not null) THEN
		mystr := 'MPESA Transfer';
	END IF;

	INSERT INTO audit.master (audit_user, audit_login) VALUES ('automation', 'automation');

	INSERT INTO ledger (id, client_roid, description, currency, total, trans_type, tld, processor_account_history_id, refund_expiry, refund_grace, refund_amount, documentnumber)
	VALUES (lid, NEW.roid, mystr, 'KES', ((-1) * NEW.amount), 'Payment', 'ke', '2', now(), now(), 0, NEW.receiptid);

	NEW.ledgerid := lid;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE VIEW vwsmstrans AS
	SELECT sms_trans.sms_trans_id, sms_trans.message, sms_trans.origin, sms_trans.sms_time, sms_trans.client_id,
		sms_trans.code, sms_trans.amount, sms_trans.narrative, sms_trans.sms_id, sms_trans.sms_deleted,
		sms_trans.sms_picked, sms_trans.in_words, sms_trans.emailed,
		client.name as clientname, 
		(CASE WHEN client.billing_email is null THEN client.admin_email
			WHEN client.admin_email = client.billing_email THEN client.billing_email
			ELSE (client.admin_email || ', ' || client.billing_email) END) as emailaddress
	FROM sms_trans INNER JOIN client ON upper(sms_trans.client_id) = upper(client.roid);

DROP VIEW vwledger;
CREATE VIEW vwledger AS
	SELECT client.name, client.clid, ledger.id, ledger.client_roid, ledger.trans_type, ledger.created, ledger.description, 
		ledger.currency, ledger.tax, ledger.tax_label, CAST(ledger.created as date) as transdate,
		to_char((CASE WHEN ledger.tax is null THEN 0 ELSE (ledger.total * (ledger.tax/ 100)) / (1 + (ledger.tax / 100)) END), '999,999,999.00') AS taxamount,
		to_char((CASE WHEN ledger.tax is null THEN ledger.total ELSE (ledger.total / (1 + (ledger.tax / 100))) END), '999,999,999.00') AS amount,
		ledger.renewal_refund, ledger.domain_name, ledger.balance, ledger.documentnumber, 
		ledger.total, ledger.vat_sign, ledger.is_printed, ledger.is_filled,
		(CASE WHEN ledger.total > 0 THEN ledger.total END) as debit,
		(CASE WHEN ledger.total < 0 THEN abs(ledger.total) END) as credit
	FROM client INNER JOIN ledger ON client.roid = ledger.client_roid;


------- ETR

CREATE TABLE etr (
	ID					varchar(12) primary key,
	FNAME				varchar(50),
	PORT				varchar(50),
	S_ROW				varchar(50),
	S_COL				varchar(50),
	NUMPRN				varchar(50),
	ES					varchar(50),
	IMEAA				varchar(50),
	GENAA				varchar(50),
	PDATE				varchar(50),
	PTIME				varchar(50),
	EAFDSS				varchar(50),
	ZNUM				varchar(50),
	FORM				varchar(50),
	ledger_id			integer
);
	
CREATE OR REPLACE FUNCTION upd_invoices(varchar(120), varchar(120), varchar(120)) RETURNS varchar(120) AS $$
BEGIN
	INSERT INTO audit.master (audit_user, audit_login) VALUES ('automation', 'automation');

	UPDATE ledger SET is_printed = true, is_filled = false, print_time = now() WHERE id = CAST($3 as int);

	RETURN 'Updated print';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION upd_etr(varchar(120), varchar(120)) RETURNS varchar(120) AS $$
DECLARE
	reca RECORD;
	recb RECORD;
BEGIN
	INSERT INTO audit.master (audit_user, audit_login) VALUES ('automation', 'automation');


	FOR reca IN 
		SELECT id, print_time, CAST(print_time as date) as pdate
		FROM ledger
		WHERE (is_printed = true) AND (is_filled = false) ORDER BY print_time
	LOOP
		SELECT id, pdate, ptime, (es || ' ' || imeaa || ' ' || genaa || ' ' || pdate || ptime || ' ' || eafdss) as sign INTO recb
		FROM etr
		WHERE (ledger_id is null) AND (to_date(pdate, 'YYMMDD') = reca.pdate);

		IF FOUND THEN
			INSERT INTO audit.master (audit_user, audit_login) VALUES ('automation', 'automation');
			UPDATE ledger SET vat_sign = recb.sign, is_filled = true WHERE id = reca.id;
			UPDATE etr SET ledger_id = reca.id WHERE id = recb.id;
		END IF;

	END LOOP;

	RETURN 'Updated ETR invoice';
END;
$$ LANGUAGE plpgsql;


-------- YU Cash integration
CREATE TABLE yu_transactions (
	yu_transaction_id		serial primary key,
	mobtransactionID		integer unique,
	ResponseCode			varchar(50),
	TrDateTimeStamp			varchar(32),
	SenderMobileNumber		varchar(50),
	FirstName				varchar(50),
	LastName				varchar(50),
	Message					varchar(240),
	AmountReceived			real,
	picked					boolean default true,
	Account_Number			varchar(50)
);

CREATE OR REPLACE FUNCTION insMembership(varchar(89)) RETURNS varchar(120) AS $$
DECLARE
	reca RECORD;
	recb RECORD;
BEGIN
	SELECT value INTO reca 
	FROM configuration WHERE name = 'memberfee';
	SELECT billingdate, billingdate + CAST('1 year' as interval) as exdate INTO recb
	FROM client WHERE roid = $1;

	INSERT INTO audit.master (audit_user, audit_login) VALUES ('automation', 'automation');

	INSERT INTO ledger (client_roid, description, currency, tax, tax_label, total, trans_type, tld, processor_account_history_id, refund_expiry, refund_grace, refund_amount, exdate, previous_expiry_date)
	VALUES ($1, 'Membership Fee', 'KES', 16, 'VAT', CAST(reca.value as real), 'Application', 'ke', '2', now(), now(), 0, recb.exdate, recb.billingdate);

	UPDATE client SET billingdate = billingdate + CAST('1 year' as interval), emailed[1] = false WHERE roid = $1;

	RETURN 'Update membership fee';
END;
$$ LANGUAGE plpgsql;


-------------- New updates
INSERT INTO audit.master (audit_user, audit_login) VALUES ('automation', 'automation');
UPDATE client SET ispicked =  false;

DROP TRIGGER updprice ON ledger;
DROP TRIGGER tg_audit_ledger ON ledger;

UPDATE ledger SET ispicked =  false WHERE id > 276671;

CREATE TRIGGER updprice BEFORE INSERT OR UPDATE ON ledger
FOR EACH ROW EXECUTE PROCEDURE updprice();

CREATE TRIGGER tg_audit_ledger AFTER INSERT OR UPDATE OR DELETE ON ledger
FOR EACH ROW EXECUTE PROCEDURE tg_audit_ledger();

------------ New Updates on Receipts


ALTER TABLE receipts 
ADD	mpesa				boolean default false not null,
ADD	ipay				boolean default false not null;


CREATE OR REPLACE FUNCTION insreceipts() RETURNS trigger AS $$
DECLARE
	lid int;
	mystr varchar(32);
BEGIN
	lid := nextval('ledger_id_seq');

	mystr := 'Cheque Receipt';
	IF(NEW.cash = true) THEN
		mystr := 'Cash Receipt';
	ELSIF(NEW.vatwithheld = true) THEN
		mystr := 'VAT Certificate';
	ELSIF (NEW.mpesa_trx_id is not null) THEN
		mystr := 'MPESA Transfer';
	ELSIF (NEW.mpesa = true) THEN
		mystr := 'MPESA Transfer';
		NEW.bankcode := 'MPESA';
		NEW.drawername := 'MPESA';
	ELSIF (NEW.ipay = true) THEN
		mystr := 'IPAY';
		NEW.bankcode := 'IPay';
		NEW.drawername := 'IPay';
	END IF;

	INSERT INTO audit.master (audit_user, audit_login) VALUES ('automation', 'automation');

	INSERT INTO ledger (id, client_roid, description, currency, amount, total, tax_content, tax_inclusive, trans_type, tld, processor_account_history_id, documentnumber)
	VALUES (lid, NEW.roid, mystr, 'KES', ((-1) * NEW.amount), ((-1) * NEW.amount), 0, true, 'Payment', 'ke', '2', NEW.receiptid);

	NEW.ledgerid := lid;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ins_mpesa_trxs() RETURNS trigger AS $$
DECLARE
	clientid varchar(16);
	trxcodes bigint;
BEGIN
	clientid :=  null;
	SELECT clid INTO clientid
	FROM client WHERE clid = trim(upper(NEW.mpesa_acc));

	IF((clientid is not null) AND (NEW.mpesa_amt is not null)) THEN
		SELECT count(receiptid) INTO trxcodes
		FROM receipts WHERE (bankcode = 'MPESA') AND (chequenumber = NEW.mpesa_code);

		IF(trxcodes = 0) THEN
			INSERT INTO receipts (roid, mpesa_trx_id, amount, bankcode, chequedate, chequenumber, drawername, inwords, details, mpesa)
			VALUES (clientid, NEW.mpesa_trx_id, NEW.mpesa_amt, 'MPESA', NEW.mpesa_trx_date, NEW.mpesa_code, 'MPESA', NEW.in_words, NEW.mpesa_text, true);
		END IF;
	ELSE
		UPDATE mpesa_trxs SET account_error = true WHERE (mpesa_trx_id = NEW.mpesa_trx_id);
	END IF;


	RETURN null;
END;
$$ LANGUAGE plpgsql;

	
	