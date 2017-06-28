
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


CREATE OR REPLACE FUNCTION upd_domain_refund() RETURNS trigger AS $$
DECLARE
	reca 		RECORD;
	recb		RECORD;
	docno 		int;
	cr_amount	numeric(8,2);
	cr_tax		numeric(8,2);
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
			
			cr_amount := ((-1)*NEW.total);
			cr_tax := cr_amount * 0.16;
			INSERT INTO ledger (client_roid, description, currency, amount, total, tax_content, tax_inclusive, trans_type, tld, processor_account_history_id, domain_roid, domain_name, refund_for_id, tax, tax_label)
			VALUES (NEW.client_roid, 'Refund on domain renewal', 'KES', cr_amount, cr_amount, cr_tax, true, 'Refund', 'ke', '2', NEW.domain_roid, NEW.domain_name, NEW.id, '16.0', 'VAT');

			UPDATE domain SET exdate = NEW.previous_expiry_date WHERE name = NEW.domain_name;
		END IF;
		IF((OLD.renewal_refund = true) AND (NEW.renewal_refund = false)) THEN
			NEW.renewal_refund := true;
		END IF;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;


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
