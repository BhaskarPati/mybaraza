CREATE TABLE numberdiscounts (
	numberdiscountid	serial primary key,
	lowrange			integer,
	highrange			integer,
	discount			real
);
INSERT INTO numberdiscounts (lowrange, highrange, discount) VALUES (0, 50, 0);
INSERT INTO numberdiscounts (lowrange, highrange, discount) VALUES (51, 250, 5);
INSERT INTO numberdiscounts (lowrange, highrange, discount) VALUES (251, 500, 7.5);
INSERT INTO numberdiscounts (lowrange, highrange, discount) VALUES (501, 1000, 12.5);
INSERT INTO numberdiscounts (lowrange, highrange, discount) VALUES (1001, 2000, 20);
INSERT INTO numberdiscounts (lowrange, highrange, discount) VALUES (2001, 100000, 50);

CREATE TABLE yeardiscounts (
	yeardiscountid		serial primary key,
	noofyears			integer,
	discount			real
);
INSERT INTO yeardiscounts (noofyears, discount) VALUES (2, 5);
INSERT INTO yeardiscounts (noofyears, discount) VALUES (3, 15);
INSERT INTO yeardiscounts (noofyears, discount) VALUES (4, 20);
INSERT INTO yeardiscounts (noofyears, discount) VALUES (5, 25);
INSERT INTO yeardiscounts (noofyears, discount) VALUES (6, 25);
INSERT INTO yeardiscounts (noofyears, discount) VALUES (7, 25);
INSERT INTO yeardiscounts (noofyears, discount) VALUES (8, 25);
INSERT INTO yeardiscounts (noofyears, discount) VALUES (9, 25);
INSERT INTO yeardiscounts (noofyears, discount) VALUES (10, 25);

CREATE OR REPLACE FUNCTION ins_zone() RETURNS trigger AS $$
BEGIN
	INSERT INTO audit.master (audit_user, audit_login) VALUES ('automation', 'automation');
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_zone BEFORE UPDATE ON zone
    FOR EACH ROW EXECUTE PROCEDURE ins_zone();

CREATE TABLE credit_limit_change (
	credit_limit_change_id	serial primary key,
	change_date				timestamp default now(),
	roid					varchar(16),
	client_clid 			varchar(16),
	credit_limit			real
);

ALTER TABLE client 
ADD sendnotice boolean[] default '{false, false}',
ADD oldstatus varchar(12),
ADD ispicked boolean default false not null,
ADD billed boolean default false not null,
ADD lastbilling date default current_date not null;

ALTER TABLE zone
ADD	domainprice			real default 2000 not null,
ADD	vat					real default 16 not null,
ADD	generalsales		boolean default false not null,
ADD	holdtoverify		boolean default false not null,
ADD allowdiscount		boolean default false not null;

ALTER TABLE credit_limit 
ALTER COLUMN currency DROP DEFAULT,
ALTER COLUMN currency SET DEFAULT 'KES';

ALTER TABLE ledger
ADD inwords		varchar(240),
ADD ispicked boolean DEFAULT false not null;

ALTER TABLE domain
ADD sendnotice boolean[] default '{false, false, false, false, false, false, false, false}';

CREATE FUNCTION DomainEmailed(integer, varchar(89)) RETURNS void AS $$
    UPDATE domain SET sendnotice[$1] = true WHERE (roid = $2);
$$ LANGUAGE SQL;

INSERT INTO configuration (name, value, jclass) VALUES ('sysname', 'KENIC', 'dewcis.registry');
INSERT INTO configuration (name, value, jclass) VALUES ('murl', 'http://localhost:8080/kenicpay/creditcard', 'dewcis.registry');
INSERT INTO configuration (name, value, jclass) VALUES ('cardnumber', '8574637799010044', 'dewcis.registry');
INSERT INTO configuration (name, value, jclass) VALUES ('memberfee', '5000', 'dewcis.registry');

CREATE OR REPLACE FUNCTION insMembership(varchar(89)) RETURNS varchar(120) AS $$
DECLARE
	v_amount	real;
	v_tax		real;
	reca 		RECORD;
	recb		RECORD;
BEGIN
	SELECT value INTO reca 
	FROM configuration WHERE name = 'memberfee';
	SELECT billingdate, billingdate + CAST('1 year' as interval) as exdate INTO recb
	FROM client WHERE roid = $1;

	INSERT INTO audit.master (audit_user, audit_login) VALUES ('automation', 'automation');
	
	v_amount := CAST(reca.value as real);
	v_tax := v_amount * 0.16;

	INSERT INTO ledger (client_roid, description, currency, tax, tax_label, tax_content, tax_inclusive, amount, total, trans_type, tld, processor_account_history_id, refund_expiry, refund_grace, refund_amount, exdate, previous_expiry_date)
	VALUES ($1, 'Membership Fee', 'KES', 16, 'VAT', v_tax, true, v_amount, v_amount, 'Application', 'ke', '2', now(), now(), 0, recb.exdate, recb.billingdate);

	UPDATE client SET billingdate = billingdate + CAST('1 year' as interval), emailed[1] = false WHERE roid = $1;

	RETURN 'Update membership fee';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION getDiscount(varchar(25)) RETURNS real AS $$
DECLARE
	calcdiscount real;
	reca RECORD;
	recb RECORD;
BEGIN
	SELECT count(roid) as domaincount INTO reca
	FROM domain INNER JOIN zone ON domain.zone = zone.name
	WHERE (clid = $1) AND (exdate > now());

	SELECT discount INTO recb
	FROM numberdiscounts
	WHERE (reca.domaincount >= lowrange) AND (reca.domaincount <= highrange);
	
	IF (recb.discount IS NULL) THEN
		calcdiscount := 0;
	ELSE
		calcdiscount := recb.discount;
	END IF;

	RETURN calcdiscount;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION updPrice(varchar(25)) RETURNS varchar(1000) AS $$
DECLARE
	calcdiscount real;
	domainprice real;
	vatprice varchar(50);
	pricestr varchar(240);
	updatestr varchar(1000);
	reca RECORD;
	recb RECORD;
	recc RECORD;
	recd RECORD;
BEGIN
	SELECT count(roid) as domaincount INTO reca
	FROM domain INNER JOIN zone ON domain.zone = zone.name
	WHERE (clid = $1) AND (exdate > now());

	SELECT discount INTO recb
	FROM numberdiscounts
	WHERE (reca.domaincount >= lowrange) AND (reca.domaincount <= highrange);
	
	IF (recb.discount IS NULL) THEN
		calcdiscount := 0;
	ELSE
		calcdiscount := recb.discount;
	END IF;

	FOR recc IN SELECT registrar_access.client_clid, registrar_access.zone_name, zone.domainprice, zone.vat,
		zone.holdtoverify, zone.allowdiscount, (zone.domainprice * (100 - calcdiscount) / 100) as newdomainprice
	FROM registrar_access INNER JOIN zone ON registrar_access.zone_name = zone.name
	WHERE (registrar_access.client_clid = $1) LOOP
		IF (recc.allowdiscount = true) THEN
			domainprice := recc.newdomainprice;
		ELSE
			domainprice := recc.domainprice;
		END IF;
		vatprice := trim(to_char((domainprice * (100 + recc.vat) / 100), '999999.00'));

		pricestr := 'ARRAY[' || vatprice;
		FOR recd IN SELECT (noofyears * domainprice * (100 - discount) * (100 + recc.vat) / 10000) as newdomainprice,
			(noofyears * domainprice * (100 + recc.vat) / 100) as discdomainprice
		FROM yeardiscounts ORDER BY yeardiscountid LOOP
			IF (recc.allowdiscount = true) THEN
				pricestr := pricestr || ',' || trim(to_char(recd.newdomainprice, '999999.00'));
			ELSE
				pricestr := pricestr || ',' || trim(to_char(recd.discdomainprice, '999999.00'));
			END IF;
		END LOOP;
		pricestr := pricestr || ']';

		INSERT INTO audit.master (audit_user, audit_login) VALUES ('automation', 'automation');

		updatestr := 'UPDATE registrar_access SET registration_prices = ' || pricestr || ', renewal_prices = ' || pricestr;
		updatestr := updatestr || ', registration_minimum = ' || vatprice || ', renewal_minimum = ' || vatprice;
		updatestr := updatestr || ' WHERE (client_clid = ''' || recc.client_clid || ''') AND (zone_name = ''' || recc.zone_name || ''');';
		EXECUTE updatestr;
	END LOOP;

	RETURN 'done';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION upd_domain_refund() RETURNS trigger AS $$
DECLARE
	reca 			RECORD;
	recb			RECORD;
	docno 			int;
	new_ledger_id	int;
	cr_amount		numeric(8,2);
	cr_tax			numeric(8,2);
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
			SELECT id INTO new_ledger_id
			FROM ledger
			WHERE (domain_name = NEW.domain_name) AND (id > NEW.id) AND (renewal_refund = false);
			
			IF(new_ledger_id is null)THEN
				INSERT INTO audit.master (audit_user, audit_login) VALUES ('automation', 'automation');
				
				cr_amount := ((-1)*NEW.total);
				cr_tax := cr_amount * 0.16;
				INSERT INTO ledger (client_roid, description, currency, amount, total, tax_content, tax_inclusive, trans_type, tld, processor_account_history_id, domain_roid, domain_name, refund_for_id, tax, tax_label)
				VALUES (NEW.client_roid, 'Refund on domain renewal', 'KES', cr_amount, cr_amount, cr_tax, true, 'Refund', 'ke', '2', NEW.domain_roid, NEW.domain_name, NEW.id, '16.0', 'VAT');

				UPDATE domain SET exdate = NEW.previous_expiry_date WHERE name = NEW.domain_name;
			END IF;
		END IF;
		IF((OLD.renewal_refund = true) AND (NEW.renewal_refund = false)) THEN
			NEW.renewal_refund := true;
		END IF;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER upd_domain_refund BEFORE INSERT OR UPDATE ON ledger
  FOR EACH ROW EXECUTE PROCEDURE upd_domain_refund();
  
  
CREATE OR REPLACE FUNCTION updprice() RETURNS trigger AS $$
DECLARE
	reca 		RECORD;
	recb		RECORD;
	docno 		int;
	cr_amount	numeric(8,2);
BEGIN

	SELECT updPrice(client.clid) INTO reca
	FROM client
	WHERE (auto_discount = true) AND (client.roid = NEW.client_roid);

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER updPrice BEFORE INSERT OR UPDATE ON ledger
  FOR EACH ROW EXECUTE PROCEDURE updPrice();

CREATE OR REPLACE FUNCTION insDomainStatus() RETURNS trigger AS $$
DECLARE
	reca RECORD;
BEGIN
	SELECT holdtoverify INTO reca
	FROM zone
	WHERE (zone.name = NEW.zone);

	IF (reca.holdtoverify = true) THEN
		NEW.st_sv_hold := 'Suspended by root';
		NEW.st_ok := null;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION updDomainStatus() RETURNS trigger AS $$
BEGIN
	IF (TG_OP = 'DELETE') THEN
		IF ((current_date - CAST(OLD.createdate as date)) < 7) THEN
			INSERT INTO messages (messagetype, ms1id, domainname)
			SELECT '21', OLD.clid, OLD.name;
		ELSE
			INSERT INTO messages (messagetype, ms1id, domainname)
			SELECT '22', OLD.clid, OLD.name;
		END IF;

		RETURN OLD;
	END IF;

	IF (TG_OP = 'UPDATE') THEN
		IF (NEW.exdate > OLD.exdate) THEN
			NEW.sendnotice[5] = false;
			NEW.sendnotice[6] = false;
			NEW.sendnotice[7] = false;
			NEW.sendnotice[8] = false;
			NEW.sendnotice[9] = false;
			NEW.sendnotice[10] = false;
			NEW.sendnotice[11] = false;
			NEW.sendnotice[12] = false;
			NEW.sendnotice[13] = false;
			NEW.sendnotice[14] = false;
			NEW.sendnotice[15] = false;
			NEW.sendnotice[16] = false;
			NEW.sendnotice[17] = false;
			NEW.sendnotice[18] = false;
			NEW.sendnotice[19] = false;
			NEW.sendnotice[20] = false;
			NEW.sendnotice[21] = false;
			NEW.sendnotice[22] = false;
			NEW.sendnotice[23] = false;
			NEW.sendnotice[24] = false;
			NEW.sendnotice[25] = false;

			NEW.renewaldate = now();
		END IF;

		IF (OLD.clid <> NEW.clid) THEN
			INSERT INTO messages (messagetype, ms1id, ms2id, domainname)
			SELECT '19', OLD.clid, NEW.clid, NEW.name;
		END IF;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER updDomainStatus BEFORE UPDATE OR DELETE ON "domain"
  FOR EACH ROW EXECUTE PROCEDURE updDomainStatus();


CREATE TABLE receipts (
	receiptid			serial primary key,
	roid				varchar(89) references client,
	ledgerid			integer references ledger,
	smstranid			integer references smstrans,
	mpesa_trx_id		integer references mpesa_trxs,
	receipdate			timestamp default now() not null,
	amount				real,
	bankcode			varchar(25),
	chequedate			date,
	chequenumber		varchar(50),
	drawername			varchar(120),
	cash				boolean default false not null,
	vatwithheld			boolean default false not null,
	mpesa				boolean default false not null,
	ipay				boolean default false not null,
	vatcertno			varchar(50),
	inwords				varchar(240),
	details				text
);
CREATE INDEX receipts_roid ON receipts (roid);
CREATE INDEX receipts_ledgerid ON receipts (ledgerid);
CREATE INDEX receipts_smstranid ON receipts (smstranid);
CREATE INDEX receipts_mpesa_trx_id ON receipts (mpesa_trx_id);

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

CREATE TRIGGER insreceipts BEFORE INSERT ON receipts
    FOR EACH ROW EXECUTE PROCEDURE insreceipts();

CREATE VIEW vwledger AS
	SELECT client.name, client.clid, ledger.id, ledger.client_roid, ledger.trans_type, ledger.created, ledger.description, 
		ledger.currency, ledger.tax, ledger.tax_label, CAST(ledger.created as date) as transdate,
		to_char((CASE WHEN ledger.tax is null THEN 0 ELSE (ledger.total * (ledger.tax/ 100)) / (1 + (ledger.tax / 100)) END), '999,999,999.00') AS taxamount,
		to_char((CASE WHEN ledger.tax is null THEN ledger.total ELSE (ledger.total / (1 + (ledger.tax / 100))) END), '999,999,999.00') AS amount,
		ledger.renewal_refund, ledger.domain_name, ledger.balance, ledger.documentnumber, 
		ledger.total, ledger.vat_sign, ledger.is_printed, ledger.isfilled,
		(CASE WHEN ledger.total > 0 THEN ledger.total END) as debit,
		(CASE WHEN ledger.total < 0 THEN abs(ledger.total) END) as credit
	FROM client INNER JOIN ledger ON client.roid = ledger.client_roid;

CREATE VIEW vwtransdays AS
	SELECT CAST(created as date) as transdate
	FROM ledger
	GROUP BY CAST(created as date)
	ORDER BY CAST(created as date) desc;

CREATE OR REPLACE FUNCTION getBalance(varchar, date) RETURNS numeric AS $$
	SELECT CASE WHEN sum(total) is null THEN 0 ELSE sum(total) END
	FROM ledger 
	WHERE (client_roid = $1) AND (created < CAST($2 as date));
$$ LANGUAGE SQL;

CREATE TABLE Training (
	TrainingID				serial primary key,
	TrainingName			varchar(50),
	venue					varchar(50),
	StartDate				date,
	StopDate				date,
	IsDone					boolean,
	Charge					float,
	cost					float,
	maxclass				integer,
	Details					text
);

CREATE TABLE ClientTraining (
	ClientTrainingID		serial primary key,
	TrainingID				integer references training,
	roid					varchar(89) references Client,
	staffname				varchar(50) not null,
	IsPaid					boolean not null default false,
	IsAttended				boolean not null default false,
	IsCert					boolean not null default false,
	IsCompleted				boolean not null default false,
	Marks					integer,
	Details					text
);
CREATE INDEX ClientTraining_TrainingID ON ClientTraining (TrainingID);
CREATE INDEX ClientTraining_roid ON ClientTraining (roid);

CREATE VIEW VwClientTraining AS
	SELECT Training.TrainingID, Training.TrainingName, Training.venue, Training.StartDate, Training.StopDate,
		Training.IsDone, Training.Charge, Training.cost, Training.maxclass,
		ClientTraining.ClientTrainingID, ClientTraining.staffname, ClientTraining.IsAttended,
		ClientTraining.IsPaid, ClientTraining.IsCert, ClientTraining.IsCompleted, ClientTraining.Marks,
		client.roid, client.clid, client.name
	FROM Training INNER JOIN (ClientTraining INNER JOIN Client ON ClientTraining.roid = Client.roid)
		ON Training.TrainingID = ClientTraining.TrainingID;

CREATE OR REPLACE FUNCTION updClientTraining() RETURNS trigger AS $$
DECLARE
	reca RECORD;
BEGIN
	SELECT ('Training Fee for ' || NEW.staffname) as tf, ('Training refund for ' || NEW.staffname) as rf, Charge INTO reca 
	FROM Training WHERE TrainingID = NEW.TrainingID;

	INSERT INTO audit.master (audit_user, audit_login) VALUES ('automation', 'automation');

	IF (OLD.IsPaid = false) AND (NEW.IsPaid = true) THEN
		INSERT INTO ledger (client_roid, description, currency, tax, tax_label, total, trans_type, tld, processor_account_history_id, refund_expiry, refund_grace, refund_amount)
		VALUES (NEW.roid, reca.tf , 'KES', 16, 'VAT', reca.Charge, 'Application', 'ke', '2', now(), now(), 0);
	END IF;

	IF (OLD.IsPaid = true) AND (NEW.IsPaid = false) THEN
		INSERT INTO ledger (client_roid, description, currency, tax, tax_label, total, trans_type, tld, processor_account_history_id, refund_expiry, refund_grace, refund_amount)
		VALUES (NEW.roid, reca.rf, 'KES', 16, 'VAT', ((-1) * reca.Charge), 'Application', 'ke', '2', now(), now(), 0);
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER updClientTraining BEFORE UPDATE ON ClientTraining
    FOR EACH ROW EXECUTE PROCEDURE updClientTraining();

CREATE TABLE applicants (
	applicantid			serial primary key,
	companyname			varchar(50) not null,
	Address				varchar(50),
	PostalCode			varchar(12),
	Premises			varchar(120),
	Street				varchar(120),
	Town				varchar(50) not null,
	countryid			char(2) default 'KE',
	TelNo				varchar(150),
	Fax					varchar(150),
	Email				varchar(120) not null unique,
	pinnumber			varchar(32) not null unique,
	firstpasswd			varchar(32) default firstpasswd(),
	ns1					varchar(32) not null,
	ns2					varchar(32) not null,
	createdate			timestamp not null default now(),
	Approve				boolean not null default false,
	Processing			boolean not null default false,
	Reject				boolean not null default false,
	ActivationDate		timestamp,
	admin_contact 		varchar(50),
	admin_email 		varchar(120),
	billing_contact 	varchar(50),
	billing_email 		varchar(120),
	tech_contact 		varchar(50),
	tech_email 			varchar(120),
	service_contact 	varchar(50),
	service_email		varchar(120),
	emailed				boolean[] default '{false, false, false, false}',
	conditions			varchar(12),
	ipaddress			varchar(64),
	clid				varchar(16),
	Details				text
);

CREATE FUNCTION ApplicantEmailed(integer, integer) RETURNS void AS $$
    UPDATE applicants SET emailed[$1] = true WHERE (applicantid = $2);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION updclient() RETURNS trigger AS $$
DECLARE
	myid		varchar(50);
	upstr		varchar(2000);
	reca		RECORD;
	recb		RECORD;
	recc		RECORD;
	
	v_amount	real;
	v_tax		real;
BEGIN
	IF (OLD.Reject = false) AND (NEW.Reject = true) THEN
		NEW.Processing = false;
	END IF;

	IF (OLD.Approve = false) AND (NEW.Approve = true) THEN
		NEW.Processing = false;

		INSERT INTO audit.master (audit_user, audit_login) VALUES ('automation', 'automation');

		IF (split_part(NEW.companyname, ' ', 2) = '') THEN
			myid := substr(NEW.companyname, 1, 3);
		ELSIF (split_part(NEW.companyname, ' ', 3) = '') THEN
			myid := substr(NEW.companyname, 1, 2) || substr(split_part(NEW.companyname, ' ', 2), 1, 1);
		ELSE
			myid := substr(NEW.companyname, 1, 1) || substr(split_part(NEW.companyname, ' ', 2), 1, 1) || substr(split_part(NEW.companyname, ' ', 3), 1, 1);
		END IF;

		myid := upper(myid);

		SELECT count(roid) as idcount INTO reca
		FROM client WHERE (substr(roid, 1, 3) = myid);
		IF (reca.idcount > 0) THEN
			myid := myid || reca.idcount + 1;
		END IF;

		INSERT INTO client (roid, clid, name, epp_password, email, phone, country, oldstatus, address,
			admin_contact, admin_email, billing_contact, billing_email, tech_contact, tech_email, service_contact, service_email, billingdate,
			admin_opt_out, billing_opt_out, tech_opt_out, service_opt_out)
		VALUES(myid, myid, NEW.companyname, md5(NEW.firstpasswd), NEW.email, NEW.TelNo, NEW.countryid, '0',
		(NEW.Premises || ', ' || COALESCE(NEW.Street, '') || E'\nP.O. Box ' || NEW.Address || ' - ' || NEW.PostalCode || E'\n' || NEW.Town),
			NEW.admin_contact, NEW.admin_email, NEW.billing_contact, NEW.billing_email, 
			NEW.tech_contact, NEW.tech_email, NEW.service_contact, NEW.service_email, now() + CAST('1 year' as interval),
			false, false, false, false); 

		INSERT INTO login (username, clid, name, password)
		VALUES (myid, myid, myid, md5(NEW.firstpasswd));

		INSERT INTO login_role (username, role)
		VALUES (myid, 'REGISTRAR');

		SELECT value INTO recc FROM configuration WHERE name = 'memberfee';

		FOR recb IN SELECT name FROM zone WHERE (generalsales = true) LOOP
			INSERT INTO registrar_access (client_clid, zone_name, registration_prices, renewal_prices, registration_minimum, renewal_minimum, max_registration_years, max_renewal_years, transfer_fee, allow_trans_in, allow_trans_out, registration_grace, renewal_grace, auto_renew_length, auto_renew_unit, transfer_renew_length, transfer_renew_unit, auto_renewal_grace) 
			VALUES (myid, recb.name, '{650.00,1300.00,1755.00,2340.00,2600.00}', '{580.00,1160.00,1566.00,2088.00,2320.00}', 650.00, 580.00, 5, 5, 0.00, true, true, 30, 1, 0, 'm', 0, 'm', 1);
		END LOOP;

		INSERT INTO credit_limit (client_clid, tld, currency, tax, tax_label)
		VALUES (myid, 'ke', 'KES', 16, 'VAT');
		
		v_amount := CAST(recc.value as real);
		v_tax := v_amount * 0.16;

		INSERT INTO ledger (client_roid, description, currency, tax, tax_label, tax_content, tax_inclusive, amount, total, trans_type, tld, processor_account_history_id, refund_expiry, refund_grace, refund_amount, exdate, previous_expiry_date)
		VALUES (myid, 'Membership Fee', 'KES', 16, 'VAT', v_tax, true, v_amount, v_amount, 'Application', 'ke', '2', now(), now(), 0, now(), now());
		
		NEW.clid := myid;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER updclient BEFORE UPDATE ON applicants
    FOR EACH ROW EXECUTE PROCEDURE updclient();

CREATE VIEW vwexdomains AS
	SELECT domain.roid, domain.clid, domain.name, domain.exdate, domain.zone, 
		domain.registrant, domain.createdate, domain.sendnotice, 
		(cast(domain.exdate as date) - current_date) as domainage,
		(90 + cast(domain.exdate as date) - current_date) as delage,
		(domain.exdate + interval '90 days') as deldate,
		(cast(domain.exdate as date) + interval '1 year') as next_expdate,
		registrar_access.renewal_minimum, 
		to_char((registrar_access.renewal_minimum / 1.16), '9G999D99')  as renew_price,
		to_char((0.16 * registrar_access.renewal_minimum / 1.16), '9G999D99') as renew_vat,
		client.name as clientname, 
		(CASE WHEN client.admin_email = client.billing_email THEN client.billing_email
			ELSE (client.admin_email || ', ' || client.billing_email) END) as emailaddress
	FROM (domain INNER JOIN registrar_access ON domain.clid = registrar_access.client_clid
		AND (domain.zone = registrar_access.zone_name))
		INNER JOIN client ON domain.clid = client.clid;

CREATE VIEW vwregexdomains AS
	SELECT contact.email, domain.roid, domain.clid, domain.name, domain.exdate, domain.zone, 
		domain.createdate, domain.updatedate, domain.sendnotice, domain.registrant,
		(cast(domain.exdate as date) - current_date) as domainage,
		(90 + cast(domain.exdate as date) - current_date) as delage,
		(domain.exdate + interval '90 days') as deldate,
		client.name as clientname, client.admin_email, client.phone as registar_phone
	FROM (contact INNER JOIN domain ON domain.registrant = contact.id)
		INNER JOIN client ON domain.clid = client.clid
	WHERE (contact.email is not null) AND (contact.email ilike '%@%');

CREATE VIEW vwnewdomains AS
	SELECT domain.roid, domain.clid, domain.name, domain.exdate, domain.zone, domain.createdate,
		domain.updatedate, domain.sendnotice, domain.registrant, domain.st_ok, domain.st_sv_hold,
		(cast(domain.exdate as date) - current_date) as domainage,
		contact.id, contact.intpostalname, contact.intpostalorg, contact.intpostalstreet1, contact.intpostalstreet2, 
		contact.intpostalstreet3, contact.intpostalcity, contact.intpostalsp, contact.intpostalpc, contact.intpostalcc, 
		contact.email, contact.voice, client.name as clientname, client.admin_email, client.phone as registar_phone
	FROM (contact INNER JOIN domain ON domain.registrant = contact.id)
		INNER JOIN client ON domain.clid = client.clid;

CREATE TABLE messages (
	messageid		serial primary key,
	messagetype		integer not null,
	ms1id			varchar(16),
	ms2id			varchar(16),
	ms3id			varchar(16),
	domainname		varchar(225),
	emailed			boolean[] default '{f, f, f, f, f}',
	details			text
);

CREATE VIEW vwmessages AS
	SELECT messages.messageid, messages.messagetype, messages.ms1id, messages.ms2id, messages.domainname,
		messages.emailed, client.admin_email,
		client.name as request_name, client.admin_email as request_email, client.phone as request_phone,
		owner.name as owner_name, owner.admin_email as owner_email, owner.phone as owner_phone
	FROM (messages INNER JOIN client ON messages.ms1id = client.clid)
		LEFT JOIN client owner ON messages.ms2id = owner.clid;

CREATE FUNCTION MessageEmailed(integer, integer) RETURNS void AS $$
    UPDATE messages SET emailed[$1] = true WHERE (messageid = $2);
$$ LANGUAGE SQL;

ALTER TABLE transfer_request 
ADD emailed	boolean[] default '{f, f, f, f, f}';

CREATE FUNCTION TransferEmailed(integer, integer) RETURNS void AS $$
    UPDATE transfer_request SET emailed[$1] = true WHERE (id = $2);
$$ LANGUAGE SQL;

CREATE VIEW vwtransfer AS
	SELECT transfer_request.id, transfer_request.domainname, transfer_request.requestdate, transfer_request.responddate,
		transfer_request.request_clid, transfer_request.owner_clid, transfer_request.response, transfer_request.emailed,
		client.name as request_name, client.admin_email as request_email, client.phone as request_phone,
		owner.name as owner_name, owner.admin_email as owner_email, owner.phone as owner_phone
	FROM (transfer_request INNER JOIN client ON transfer_request.request_clid = client.clid)
		INNER JOIN client owner ON transfer_request.owner_clid = owner.clid;

CREATE TABLE adjustments (
	adjustmentid		serial primary key,
	roid				varchar(89) references client,
	ledgerid			integer references ledger,
	adjustmentdate		timestamp default now() not null,
	amount				real,
	transactionid		integer,
	narration			varchar(120),
	details				text
);
CREATE INDEX adjustments_roid ON adjustments (roid);
CREATE INDEX adjustments_ledgerid ON adjustments (ledgerid);

CREATE OR REPLACE FUNCTION insadjustments() RETURNS trigger AS $$
DECLARE
	lid int;
BEGIN
	lid := nextval('ledger_id_seq');

	INSERT INTO audit.master (audit_user, audit_login) VALUES ('automation', 'automation');

	INSERT INTO ledger (id, client_roid, description, currency, amount, total, tax_content, tax_inclusive, trans_type, tld, processor_account_history_id, documentnumber)
	VALUES (lid, NEW.roid, NEW.narration, 'KES', NEW.amount, NEW.amount, 0, true, 'Adjustment', 'ke', '2', NEW.adjustmentid);

	NEW.ledgerid := lid;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER insadjustments BEFORE INSERT ON adjustments
    FOR EACH ROW EXECUTE PROCEDURE insadjustments();

SELECT ledger.id AS ledger_id,
       ledger.trans_type,
       ledger.description,
       ledger.total AS amount,
       ledger.currency,
       ledger.tax,
       ledger.tax_label,
       ledger.created AS date_actioned,
       ledger.domain_name,
       ledger.tld,
       ledger.documentnumber,
       ledger.transf_roid,
       ledger.exdate,
       client.name AS client_name,
       client.email AS client_email,
       client.address AS client_address,
       client.phone AS client_phone,
       client.fax AS client_fax,
       client.billing_contact,
       client.billing_email,
       processor_account_history.alias AS processor_alias,
       processor_account_history.ownername AS processor_name,
       processor_account_history.tax_id AS processor_tax_code,
       processor_account_history.address1 AS processor_address1,
       processor_account_history.address2 AS processor_address2,
       processor_account_history.address3 AS processor_address3,
       processor_account_history.city AS processor_city,
       processor_account_history.state AS processor_state,
       processor_account_history.countrycode AS processor_countrycode,
       processor_account_history.postalcode AS processor_postalcode,
       processor_account_history.voice AS processor_voice,
       processor_account_history.voicex AS processor_voicex,
       processor_account_history.fax AS processor_fax,
       processor_account_history.faxx AS processor_faxx,
       processor_account_history.email AS processor_email,
       receipts.chequedate,
       receipts.chequenumber,
       receipts.drawername,
       receipts.cash,
       receipts.vatwithheld,
       receipts.vatcertno,
       receipts.inwords,
       (CASE WHEN (trans_type = 'Renewal') OR (trans_type = 'Registration') OR (trans_type = 'Membership') OR (trans_type = 'Training') THEN 'Invoice No. :'
       WHEN (trans_type = 'Refund') THEN 'Credit Note No. :' 
       WHEN (trans_type = 'Payment') THEN 'Receipt No . :'
       WHEN (trans_type = 'Adjustment') THEN 'Adjustment' END) as numberlabel,
       (CASE WHEN receipts.cash = true THEN 'Cash Receipt'
       WHEN receipts.vatwithheld = true THEN 'VAT Witholding Cert No. : ' || receipts.vatcertno
       ELSE 'Cheque Receipt for Cheque No. : ' || receipts.chequenumber END) as receiptlabel
FROM
   ledger INNER JOIN client ON client.roid = ledger.client_roid 
		LEFT OUTER JOIN processor_account_history ON ledger.processor_account_history_id = processor_account_history.id
		LEFT OUTER JOIN receipts ON ledger.id = receipts.ledgerid
WHERE ledger.id = CAST($P{ledger_id} as int);

CREATE FUNCTION getDomainCount(varchar(16)) RETURNS bigint AS $$
	SELECT count(roid) FROM domain WHERE (clid = $1);
$$ LANGUAGE SQL;

DROP VIEW vwclientsum;
CREATE VIEW vwclientsum AS
	SELECT client.roid, client.clid, client.name, client.createdate, client.billingdate, client.emailed,
	client.email, (CAST(client.billingdate as date) - current_date) as expiredays, 
	getDomainCount(client.clid) as domaincount, ((-1) *sum(ledger.total)) as balance
	FROM client INNER JOIN ledger ON client.clid = ledger.client_roid
	GROUP BY client.roid, client.clid, client.name, client.createdate, client.billingdate, client.emailed,
		client.email, (CAST(client.billingdate as date) - current_date), getDomainCount(client.clid);


CREATE TABLE smstrans (
	smstranid			serial primary key,
	message				varchar(2400),
	origin				varchar(50),
	smstime				timestamp,
	clientid			varchar(50),
	code				varchar(25),
	amount				real,
	narrative			varchar(240),
	smsid				integer,
	smsdeleted			boolean default false not null,
	ispicked			boolean default false not null,
	inwords				varchar(240),
	partid				integer,
	partmessage			varchar(240),
	partno				integer,
	partcount			integer,
	accounterror		boolean default false,
	emailed				boolean[] default '{f, f, f}',
	UNIQUE(origin, smstime)
);

CREATE OR REPLACE FUNCTION inssmstrans() RETURNS trigger AS $$
DECLARE
	clientid varchar(16);
BEGIN
	clientid :=  null;
	SELECT clid INTO clientid
	FROM client WHERE clid = NEW.clientid;

	IF((clientid is not null) AND (NEW.amount is not null) AND (trim(NEW.origin) = 'D48617A140')) THEN
		INSERT INTO receipts (roid, smstranid, amount, bankcode, chequedate, chequenumber, drawername, inwords, details)
		VALUES (NEW.clientid, NEW.smstranid, NEW.amount, 'MPESA', NEW.smstime, NEW.code, 'MPESA', NEW.inwords, NEW.message);
	ELSIF (NEW.clientid is not null) THEN
		UPDATE smstrans SET accounterror = true WHERE (smstranid = NEW.smstranid);
	END IF;

	IF(NEW.partno > 1) THEN
		UPDATE smstrans SET message = message || NEW.partmessage WHERE (partid = NEW.partid) AND (partno = 1);
	END IF;

	RETURN null;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER inssmstrans AFTER INSERT ON smstrans
    FOR EACH ROW EXECUTE PROCEDURE inssmstrans();

CREATE FUNCTION MPesaEmailed(integer, integer) RETURNS void AS $$
    UPDATE smstrans SET emailed[$1] = true WHERE (smstranid = $2);
$$ LANGUAGE SQL;

CREATE VIEW vwsmstrans AS
	SELECT smstrans.smstranid, smstrans.message, smstrans.origin, smstrans.smstime, smstrans.clientid,
		smstrans.code, smstrans.amount, smstrans.narrative, smstrans.smsid, smstrans.smsdeleted,
		smstrans.ispicked, smstrans.inwords, smstrans.emailed,
		client.name as clientname, 
		(CASE WHEN client.billing_email is null THEN client.admin_email
			WHEN client.admin_email = client.billing_email THEN client.billing_email
			ELSE (client.admin_email || ', ' || client.billing_email) END) as emailaddress
	FROM smstrans INNER JOIN client ON upper(smstrans.clientid) = upper(client.roid);

----------------------------------

CREATE OR REPLACE FUNCTION get_exdate(int) RETURNS date AS $$
DECLARE
	expDate DATE;
	reca RECORD;
	recb RECORD;
BEGIN
	SELECT id, CAST(created as DATE) as create_date, CAST(exdate as DATE) as exp_date, trans_type, refund_for_id INTO reca
	FROM ledger
	WHERE (id = $1);

	expDate := reca.exp_date;
	IF(reca.trans_type = 'Refund') THEN
		SELECT id, created, (CAST(exdate as DATE) - CAST(created as DATE)) as exp_days INTO recb
		FROM ledger
		WHERE (id = reca.refund_for_id);

		expDate := reca.create_date + recb.exp_days;
	ELSIF(reca.trans_type = 'Application') THEN
		expDate := reca.create_date + interval '1 year';
	END IF;

	IF(expDate is null) THEN
		expDate := reca.create_date + interval '1 year';
	END IF;

	RETURN expDate;
END;
$$ LANGUAGE plpgsql;

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



INSERT INTO audit.master (audit_user, audit_login) VALUES ('automation', 'automation');
UPDATE ledger SET ispicked = false
WHERE (cast(created as date) >= '2011-01-01') AND (trans_type = 'Refund');


INSERT INTO audit.master (audit_user, audit_login) VALUES ('automation', 'automation');
UPDATE ledger
SET tax = 16.00, tax_label = 'VAT'
WHERE (cast(created as date) >= '2011-01-01') AND (trans_type = 'Refund')
AND tax is null;

DROP TRIGGER tg_audit_client ON client;

ALTER TABLE audit.client ADD auto_discount	boolean default true not null;
ALTER TABLE client ADD auto_discount	boolean default true not null;

CREATE TRIGGER tg_audit_client AFTER INSERT OR UPDATE OR DELETE ON client
FOR EACH ROW EXECUTE PROCEDURE tg_audit_client();

CREATE OR REPLACE FUNCTION upd_discount(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	msg 		varchar(120);
BEGIN

	IF ($3 = '1') THEN
		INSERT INTO audit.master (audit_user, audit_login) VALUES ('automation', 'automation');
		UPDATE client SET auto_discount = true WHERE roid = $1;
		msg := 'Auto Discount allowed';
	ELSIF ($3 = '2') THEN
		INSERT INTO audit.master (audit_user, audit_login) VALUES ('automation', 'automation');
		UPDATE client SET auto_discount = false WHERE roid = $1;
		msg := 'Auto Discount disallowed';
	END IF;

	RETURN msg;
END;
$$ LANGUAGE plpgsql;


ALTER TABLE mpesa_trxs ADD account_error boolean default false not null;
ALTER TABLE mpesa_trxs ADD in_words varchar(320);
ALTER TABLE receipts ADD mpesa_trx_id		integer references mpesa_trxs;
CREATE INDEX receipts_mpesa_trx_id ON receipts (mpesa_trx_id);


-- Function: ins_sms_trans()
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

CREATE TRIGGER ins_mpesa_trxs AFTER INSERT ON mpesa_trxs
    FOR EACH ROW EXECUTE PROCEDURE ins_mpesa_trxs();



--------------------------------- Work

SELECT * 
FROM ledger
WHERE cast(print_time as date) = '2011-05-26' AND (vat_sign is null);


INSERT INTO audit.master (audit_user, audit_login) VALUES ('automation', 'automation');
UPDATE ledger SET print_time = null, is_printed = false, is_filled = false
WHERE cast(print_time as date) = '2011-05-26' AND (vat_sign is null);

DROP FUNCTION get_ChequeNo(int);

CREATE FUNCTION get_ChequeNo(int) RETURNS varchar(50) AS $$
DECLARE
	v_ctid		int;
	v_chno		varchar(50);
BEGIN
	
	SELECT credit_transaction_id INTO v_ctid
	FROM ledger
	WHERE (id = $1);
	
	IF(v_ctid is null)THEN
		SELECT chequenumber INTO v_chno
		FROM receipts
		WHERE (ledgerid = $1);
	ELSE
		SELECT  trim(replace(substring(description from position('txncd :' in description) for 25), 'txncd :', '')) INTO v_chno
		FROM external_payment_detail
		WHERE (id = v_ctid);
	END IF;
	
	RETURN v_chno;
END;
$$ LANGUAGE plpgsql;



-------------------- update ledger balance


CREATE OR REPLACE FUNCTION tg_insert_ledger() RETURNS trigger AS $$
BEGIN

	NEW.balance := (SELECT (-1 * (NEW.total + COALESCE((SELECT SUM(l.total)
	FROM ledger AS l
	WHERE l.created < NEW.created AND l.client_roid = NEW.client_roid), 0.0))));
	
	IF(NEW.credit_transaction_id is not null)THEN
		NEW.documentnumber := NEW.credit_transaction_id;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

