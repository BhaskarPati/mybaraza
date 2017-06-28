
SELECT count(roid) as domaincount
FROM domain INNER JOIN zone ON domain.zone = zone.name
WHERE (clid = 'WOL') AND (exdate > now());

SELECT getDiscount('WOL');

SELECT id, documentnumber
FROM ledger
WHERE (created >= '2010-01-01') AND (total > 0)
ORDER BY created;

INSERT INTO audit.master (audit_user, audit_login) VALUES ('automation', 'automation');
UPDATE zone SET auto_suspend = -1, auto_delete = -1;

INSERT INTO audit.master (audit_user, audit_login) VALUES ('automation', 'automation');
UPDATE configuration SET value = 'root@localhost' WHERE name = 'adminEmail';
UPDATE configuration SET value = 'root@localhost' WHERE name = 'auditEmail';
UPDATE configuration SET value = 'root@localhost' WHERE name = 'supportEmail';
UPDATE configuration SET value = 'root@localhost' WHERE name = 'errorEmail';
UPDATE configuration SET value = 'localhost' WHERE name = 'smtpServer';

UPDATE configuration SET value = '127.0.0.1' WHERE value = '198.32.67.25';

------- Access reset
INSERT INTO audit.master (audit_user, audit_login) VALUES ('automation', 'automation');
UPDATE login SET password = md5(<<newpassword>>) WHERE clid = 'root';

------- Error on approval -----------------------------
INSERT INTO audit.master (audit_user, audit_login) VALUES ('automation', 'automation');
INSERT INTO client (roid, clid, name, epp_password, email, phone, country, timezone, address, admin_opt_out, billing_opt_out, tech_opt_out, service_opt_out)
VALUES ('RAL', 'RAL', 'Old Account 2', '', 'slc2@kenic.co.ke', '879789789', 'KE', 'Africa/Nairobi', '4614', false, false, false, false);

INSERT INTO audit.master (audit_user, audit_login) VALUES ('automation', 'automation');
DELETE FROM client WHERE roid = 'RAL';


--------------------
UPDATE gl_trans, debtor_trans SET gl_trans.person_id = debtor_trans.debtor_no
WHERE (gl_trans.type = debtor_trans.type) AND (gl_trans.type_no = debtor_trans.trans_no);

UPDATE bank_trans, debtor_trans SET bank_trans.person_id = debtor_trans.debtor_no
WHERE (bank_trans.type = debtor_trans.type) AND (bank_trans.trans_no = debtor_trans.trans_no);

---------------------------

UPDATE Periods SET gl_payroll_account = '8000', gl_bank_account = '3200';

UPDATE adjustments SET account_number = '8010' WHERE adjustment_id = 33;
UPDATE adjustments SET account_number = '8011' WHERE adjustment_id = 39;
UPDATE adjustments SET account_number = '8045' WHERE adjustment_id = 2;
UPDATE adjustments SET account_number = '4040' WHERE adjustment_id = 12;
UPDATE adjustments SET account_number = '4050' WHERE adjustment_id = 37;

UPDATE Tax_Types SET account_number = '4045' WHERE Tax_Type_id = 1;
UPDATE Tax_Types SET account_number = '4030' WHERE Tax_Type_id = 2;
UPDATE Tax_Types SET account_number = '4035' WHERE Tax_Type_id = 3;

UPDATE Period_Tax_Types SET account_number = '4045' WHERE Tax_Type_id = 1;
UPDATE Period_Tax_Types SET account_number = '4030' WHERE Tax_Type_id = 2;
UPDATE Period_Tax_Types SET account_number = '4035' WHERE Tax_Type_id = 3;


13116
13182
79083

SELECT * FROM debtor_trans WHERE trans_no = 79083;
SELECT * FROM gl_trans WHERE type_no = 79083;
SELECT * FROM bank_trans WHERE trans_no = 79083;
SELECT * FROM trans_tax_details WHERE trans_no = 79083;
SELECT * FROM cust_allocations WHERE trans_no_from = 79083 or trans_no_to = 79083;

UPDATE debtor_trans SET trans_no =  200000 WHERE trans_no = 79083;
UPDATE gl_trans SET type_no =  200000 WHERE type_no = 79083;
UPDATE bank_trans SET trans_no =  200000 WHERE trans_no = 79083;
UPDATE trans_tax_details SET trans_no =  200000 WHERE trans_no = 79083;
UPDATE cust_allocations SET trans_no_to =  200000 WHERE trans_no_to = 79083;


SELECT * FROM gl_trans WHERE type = 0 AND type_no = 70006;
SELECT * FROM bank_trans WHERE type = 0 AND trans_no = 70006;

UPDATE gl_trans SET type_no = 200000 WHERE type = 0 AND type_no = 
UPDATE bank_trans SET type_no = 200000 WHERE type = 0 AND trans_no = 

UPDATE gl_trans SET type_no = 200000 WHERE type = 0 AND type_no = 70006;
UPDATE gl_trans SET type_no = 200001 WHERE type = 0 AND type_no = 70007;
UPDATE gl_trans SET type_no = 200002 WHERE type = 0 AND type_no = 70008;
UPDATE gl_trans SET type_no = 200003 WHERE type = 0 AND type_no = 70009;
UPDATE gl_trans SET type_no = 200004 WHERE type = 0 AND type_no = 70010;
UPDATE gl_trans SET type_no = 200005 WHERE type = 0 AND type_no = 70011;
UPDATE gl_trans SET type_no = 200006 WHERE type = 0 AND type_no = 70012;
UPDATE gl_trans SET type_no = 200007 WHERE type = 0 AND type_no = 70013;
UPDATE gl_trans SET type_no = 200008 WHERE type = 0 AND type_no = 70014;
UPDATE gl_trans SET type_no = 200009 WHERE type = 0 AND type_no = 70015;
UPDATE gl_trans SET type_no = 200010 WHERE type = 0 AND type_no = 70016;

UPDATE bank_trans SET trans_no = 200000 WHERE type = 0 AND trans_no = 70006;
UPDATE bank_trans SET trans_no = 200001 WHERE type = 0 AND trans_no = 70007;
UPDATE bank_trans SET trans_no = 200002 WHERE type = 0 AND trans_no = 70008;
UPDATE bank_trans SET trans_no = 200003 WHERE type = 0 AND trans_no = 70009;
UPDATE bank_trans SET trans_no = 200004 WHERE type = 0 AND trans_no = 70010;
UPDATE bank_trans SET trans_no = 200005 WHERE type = 0 AND trans_no = 70011;
UPDATE bank_trans SET trans_no = 200006 WHERE type = 0 AND trans_no = 70012;
UPDATE bank_trans SET trans_no = 200007 WHERE type = 0 AND trans_no = 70013;
UPDATE bank_trans SET trans_no = 200008 WHERE type = 0 AND trans_no = 70014;
UPDATE bank_trans SET trans_no = 200009 WHERE type = 0 AND trans_no = 70015;
UPDATE bank_trans SET trans_no = 200010 WHERE type = 0 AND trans_no = 70016;

-------------- Price update
INSERT INTO audit.master (audit_user, audit_login) VALUES ('automation', 'automation');
SELECT updPrice(clid) from client;


UPDATE ledger SET exdate = DATE_ADD(created, INTERVAL 1 YEAR)
where trans_type = 'Application' and (exdate is null);

SELECT *
FROM ledger 
WHERE trans_type = 'Application' and (exdate is null)
ORDER BY created;


-------------------- memebership reduction date
INSERT INTO audit.master (audit_user, audit_login) VALUES ('automation', 'automation');
UPDATE client SET billingdate = billingdate - CAST('1 year' as interval)
WHERE clid = 'NOW';

-------------------- domain reduction date
INSERT INTO audit.master (audit_user, audit_login) VALUES ('automation', 'automation');
UPDATE domains SET exdate = exdate - CAST('1 year' as interval)
WHERE name = 'domainname';



--------- Ledger balance correction
DROP TRIGGER tg_audit_ledger ON ledger;
DROP TRIGGER updprice ON ledger;

UPDATE ledger SET ispicked = false WHERE created > '2011-01-01';



  NEW.balance := (SELECT (-1 * (NEW.total + COALESCE((SELECT SUM(l.total)
     FROM ledger AS l
     WHERE l.created < NEW.created AND l.client_roid = NEW.client_roid), 0.0))));



CREATE TRIGGER updprice BEFORE INSERT OR UPDATE ON ledger
FOR EACH ROW EXECUTE PROCEDURE updprice();

CREATE TRIGGER tg_audit_ledger AFTER INSERT OR UPDATE OR DELETE ON ledger 
FOR EACH ROW EXECUTE PROCEDURE tg_audit_ledger();



---------------- Accounts update 2016.11.09

DELETE sales_order_details FROM sales_order_details INNER JOIN sales_orders
WHERE (sales_orders.order_no = sales_order_details.order_no) AND (sales_orders.ord_date < '2016-01-01');

DELETE debtor_trans_details FROM debtor_trans_details INNER JOIN debtor_trans
WHERE (debtor_trans_details.debtor_trans_no = debtor_trans.trans_no) AND debtor_trans.tran_date < '2016-01-01';

DELETE FROM sales_orders WHERE ord_date < '2016-01-01';

DELETE FROM trans_tax_details WHERE tran_date < '2016-01-01';

DELETE FROM debtor_trans WHERE tran_date < '2016-01-01';

DELETE FROM gl_trans WHERE tran_date < '2016-01-01' AND person_id = 860;

DELETE FROM bank_trans WHERE trans_date < '2016-01-01' AND person_id = 860;

UPDATE debtor_trans SET alloc = 0 WHERE (type = 10) OR (type = 11) OR (type = 12);

DELETE FROM gl_trans WHERE type_no = 11 and type = 11;
DELETE FROM gl_trans WHERE type_no = 12 and type = 12;

DELETE FROM cust_allocations WHERE trans_type_from = 10;



---- opening balance

INSERT INTO ledger (description, currency, tax, created, exdate, previous_expiry_date, months_posted, trans_type, refund_for_id, documentnumber, ChequeNo, id, client_roid, total) VALUES ('Cheque Receipt', 'KES', NULL, '2015-12-31', '2015-12-31', '2015-12-31', '0', 'Payment', NULL, '1001', '1001', '1001', 'SAL8', '-1000');


----------- Reprent ETR invoices
INSERT INTO audit.master (audit_user, audit_login) VALUES ('automation', 'automation');

UPDATE ledger SET is_printed = false WHERE created::date = '2017-02-14'::date;



