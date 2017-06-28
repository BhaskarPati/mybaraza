

DROP TRIGGER updprice ON ledger;

INSERT INTO audit.master (audit_user, audit_login) VALUES ('automation', 'automation');
UPDATE ledger SET tax = 0 WHERE tax is null;


UPDATE configuration SET value = '198.32.67.10' WHERE value = '198.32.67.25';
UPDATE configuration SET value = '/opt/coca/keys/epp.keystore' WHERE value = '/usr/local/resin/conf/keys/epp.keystore';

UPDATE configuration SET value = '/opt/cocca/keys/registry.kenic.or.ke.registry' WHERE value = '/opt/coca/keys/epp.keystore';


------ post

CREATE TRIGGER updprice
  BEFORE INSERT OR UPDATE
  ON ledger
  FOR EACH ROW
  EXECUTE PROCEDURE updprice();

  
CREATE TRIGGER upd_domain_refund BEFORE INSERT OR UPDATE ON ledger
FOR EACH ROW EXECUTE PROCEDURE upd_domain_refund();
  
CREATE TRIGGER tg_insert_ledger BEFORE INSERT ON ledger
FOR EACH ROW EXECUTE PROCEDURE tg_insert_ledger();

CREATE TRIGGER tg_audit_ledger AFTER INSERT OR UPDATE OR DELETE ON ledger
FOR EACH ROW EXECUTE PROCEDURE tg_audit_ledger();



--- get list of fully iddle clients
SELECT client.clid, client.name
FROM client LEFT JOIN domain ON client.clid = domain.clid
LEFT JOIN contact ON client.clid = contact.clid
LEFT JOIN (SELECT id, client_roid FROM ledger WHERE description <> 'Membership Fee') lt ON client.clid = lt.client_roid
WHERE (domain.clid is null) AND (contact.clid is null) AND (lt.client_roid is null);


--- Delete idle contacts, hosts and clients
INSERT INTO audit.master (audit_user, audit_login) VALUES ('automation', 'automation');

DELETE FROM contact WHERE id IN
(SELECT contact.id
FROM contact LEFT JOIN domain_contact ON contact.id = domain_contact.contact_id
LEFT JOIN domain ON contact.id = domain.registrant
LEFT JOIN application ON contact.id = application.registrant
WHERE (domain_contact.contact_id is null) AND (domain.registrant is null) AND (application.registrant is null));

DELETE FROM host_address WHERE host_name IN
(SELECT host.name
FROM host LEFT JOIN domain_host ON host.name = domain_host.host_name
WHERE domain_host.host_name is null);

DELETE FROM host WHERE name IN
(SELECT host.name
FROM host LEFT JOIN domain_host ON host.name = domain_host.host_name
WHERE domain_host.host_name is null);


DELETE FROM login_role WHERE username IN
(SELECT login.username
FROM client LEFT JOIN domain ON client.clid = domain.clid
LEFT JOIN (SELECT id, client_roid FROM ledger WHERE description <> 'Membership Fee') lt ON client.clid = lt.client_roid
LEFT JOIN login ON client.clid = login.clid
WHERE (domain.clid is null) AND (lt.client_roid is null));

DELETE FROM login WHERE clid IN
(SELECT client.clid
FROM client LEFT JOIN domain ON client.clid = domain.clid
LEFT JOIN (SELECT id, client_roid FROM ledger WHERE description <> 'Membership Fee') lt ON client.clid = lt.client_roid
WHERE (domain.clid is null) AND (lt.client_roid is null));


DELETE FROM client WHERE clid IN
(SELECT client.clid
FROM client LEFT JOIN domain ON client.clid = domain.clid
LEFT JOIN contact ON client.clid = contact.clid
LEFT JOIN receipts ON client.roid = receipts.roid
LEFT JOIN (SELECT id, client_roid FROM ledger WHERE description <> 'Membership Fee') lt ON client.clid = lt.client_roid
WHERE (domain.clid is null) AND (contact.clid is null) AND (lt.client_roid is null) AND (receipts.roid is null));


INSERT INTO audit.master (audit_user, audit_login) VALUES ('automation', 'automation');
UPDATE domain SET exdate = '2018-03-22 16:26:18.641+03' WHERE name = 'unigems.co.ke';
UPDATE ledger SET previous_expiry_date = '2018-02-10 00:00:00+03' WHERE id = 447790;
UPDATE ledger SET renewal_refund = true WHERE id = 447790;


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

