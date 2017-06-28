CREATE TABLE payroll_ledger (
	payroll_ledger_id		serial primary key,
	period_id				integer,
	ledger_id				integer,
	posting_date			date, 
	description				varchar(240), 
	payroll_account			varchar(16), 
	amount					real
);

delimiter $$
CREATE TRIGGER ins_payroll_ledger AFTER INSERT ON payroll_ledger FOR EACH ROW
BEGIN
	DECLARE b_id int;
	DECLARE f_id int;
	DECLARE l_ref varchar(100);

	SELECT id INTO b_id
	FROM bank_accounts WHERE account_code = NEW.payroll_account;
	SELECT max(id) INTO f_id
	FROM fiscal_year WHERE closed = 0;
	SELECT reference INTO l_ref
	FROM refs WHERE (id = NEW.ledger_id) AND (type = 0);

	INSERT INTO gl_trans (type, type_no, tran_date, account, memo_, amount, dimension_id, dimension2_id)
	VALUES(0, NEW.ledger_id, NEW.posting_date, NEW.payroll_account, NEW.description, NEW.amount, 0, 0);

	IF(l_ref is null) THEN
		INSERT INTO refs (id, type, reference)
		VALUES (NEW.ledger_id, 0, NEW.ledger_id);

		INSERT INTO comments (type, id, date_, memo_)
		VALUES (0, NEW.ledger_id, NEW.posting_date, 'Payroll Ledger');

		INSERT INTO audit_trail (type, trans_no, user, stamp, description, fiscal_year, gl_date, gl_seq)
		VALUES (0, NEW.ledger_id, 1, now(), '', f_id, NEW.posting_date, 0);
	END IF;

	IF(b_id is not null) THEN
		INSERT INTO bank_trans (type, trans_no, bank_act, ref, trans_date, amount,
			dimension_id, dimension2_id, person_type_id)
		VALUES(0, NEW.ledger_id, b_id, NEW.ledger_id, NEW.posting_date, NEW.amount, 
			0, 0, 0);
	END IF;

END;$$
delimiter ;

ALTER TABLE bank_trans
ADD cheque_number		varchar(50),
ADD paid_to				varchar(50),
ADD	document_number		integer;

ALTER TABLE supp_trans
ADD cheque_number		varchar(50),
ADD paid_to				varchar(50),
ADD account_no			varchar(15),
ADD	document_number		integer,
ADD	direct_expense		tinyint default 0 not null;

ALTER TABLE bank_accounts
ADD doc_sequence		integer default 1;

delimiter $$
CREATE TRIGGER ins_bank_trans BEFORE INSERT ON bank_trans FOR EACH ROW
BEGIN
	DECLARE u_id int;
	
	SELECT doc_sequence + 1 INTO u_id
	FROM bank_accounts
	WHERE id = NEW.bank_act;

	IF (NEW.amount < 0) THEN
		SET NEW.document_number = u_id;
		UPDATE bank_accounts SET doc_sequence = u_id WHERE id = NEW.bank_act;
	END IF;

END;$$
delimiter ;	

DROP TABLE IF EXISTS ledger;
CREATE TABLE ledger (
	id				integer primary key, 
	client_roid		varchar(16), 
	description		varchar(240), 
	currency		varchar(3),
	tax				real, 
	total			real, 
	created			date, 
	exdate			date,
	previous_expiry_date	date,
	months_posted	integer default 0,
	trans_type		varchar(32),
	refund_for_id	integer,
	documentnumber	integer,
	ChequeNo		varchar(50)
);

alter table ledger modify trans_type VARCHAR(50); 

DROP TRIGGER IF EXISTS ins_debtors_master;

delimiter $$
CREATE TRIGGER ins_debtors_master AFTER INSERT ON debtors_master FOR EACH ROW
BEGIN
	INSERT INTO cust_branch (debtor_no, br_name, br_address, area, salesman, contact_name, default_location, tax_group_id, 
		sales_account, sales_discount_account, receivables_account, payment_discount_account, default_ship_via, 
		disable_trans, br_post_address, group_no, notes, inactive, branch_ref)
	VALUES (NEW.debtor_no, NEW.name, NEW.address, 1, 1, '', 'DEF', 1, 
		'', '7015', '3000', '7015', 1, 
		0, NEW.address, 0, '', 0, NEW.debtor_ref);
END;$$
delimiter ;

DROP FUNCTION IF EXISTS set_tx_allocation;
delimiter $$
CREATE FUNCTION set_tx_allocation(debtor int, alloc_amount real, alloc_id int, alloc_type int, pt_date date) RETURNS real deterministic
BEGIN
	DECLARE flag1 varchar(5) DEFAULT 'START';
	DECLARE t_id integer;
	DECLARE type_id integer;
	DECLARE i_a real;
	DECLARE i_b real;
	DECLARE a_amt real;
	DECLARE t_date date;
	DECLARE at_date date;

	DECLARE cur1 CURSOR FOR 
	SELECT type, trans_no, tran_date, alloc, (ov_amount - alloc) as balance
	FROM debtor_trans
	WHERE (ov_amount > alloc) AND (debtor_no = debtor) AND (type = 10)
	ORDER BY tran_date;

	DECLARE CONTINUE HANDLER FOR NOT FOUND SET flag1 = 'END';

	OPEN cur1;
	WHILE(flag1<>'END') DO
		FETCH cur1 INTO type_id, t_id, t_date, i_a, i_b;

		IF (flag1<>'END') THEN
			IF (alloc_amount > i_b) THEN
				SET a_amt = i_b;
				SET alloc_amount = alloc_amount - i_b;
			ELSE
				SET a_amt = alloc_amount;
				SET alloc_amount = 0;
			END IF;

			IF (t_date > pt_date) THEN
				SET at_date = t_date;
			ELSE
				SET at_date = pt_date;
			END IF;
			IF (at_date < '2011-01-01') THEN
				SET at_date = '2011-01-01';
			END IF;

			IF(a_amt > 0)THEN
				INSERT INTO cust_allocations (amt, date_alloc, trans_no_from, trans_type_from, trans_no_to, trans_type_to) 
				VALUES (a_amt, at_date, alloc_id, alloc_type, t_id, type_id);
				UPDATE debtor_trans SET alloc = (alloc + a_amt) WHERE (trans_no = t_id) AND (type = type_id);

				INSERT INTO gl_trans (type, type_no, tran_date, account, memo_,
					amount, dimension_id, dimension2_id, person_type_id, person_id)
				VALUES (type_id, type_id, at_date, '3000', '', ROUND((-1 * a_amt), 2), 0, 0, 2, debtor);
				INSERT INTO gl_trans (type, type_no, tran_date, account, memo_,
					amount, dimension_id, dimension2_id, person_type_id, person_id)
				VALUES (type_id, type_id, at_date, '4055', '', ROUND(a_amt, 2), 0, 0, 2, debtor);
			END IF;
		END IF;
	END WHILE;
	CLOSE cur1;

	RETURN alloc_amount;
END;$$
delimiter ;

DROP FUNCTION IF EXISTS set_allocation;
delimiter $$
CREATE FUNCTION set_allocation() RETURNS real deterministic
BEGIN
	DECLARE flag1 varchar(5) DEFAULT 'START';
	DECLARE t_type integer;
	DECLARE t_id integer;
	DECLARE d_id integer;
	DECLARE i_a real;
	DECLARE i_b real;
	DECLARE a_amt real;
	DECLARE t_date date;

	DECLARE cur1 CURSOR FOR 
	SELECT type, trans_no, tran_date, debtor_no, ov_amount, (ov_amount - alloc) as balance
	FROM debtor_trans
	WHERE (ov_amount > alloc) AND ((type = 2) OR (type = 11) OR (type = 12))
	ORDER BY tran_date;

	DECLARE CONTINUE HANDLER FOR NOT FOUND SET flag1 = 'END';
	SET a_amt = 0;

	OPEN cur1;
	WHILE(flag1<>'END') DO
		FETCH cur1 INTO t_type, t_id, t_date, d_id, i_a, i_b;

		IF (flag1<>'END') THEN
			SET a_amt = set_tx_allocation(d_id, i_b, t_id, t_type, t_date);

			IF (a_amt <> i_b) THEN
				UPDATE debtor_trans SET alloc = (ov_amount - a_amt) WHERE (trans_no = t_id) AND (type = t_type);
			END IF;
		END IF;
	END WHILE;
	CLOSE cur1;

	RETURN a_amt;
END;$$
delimiter ;

DROP TRIGGER IF EXISTS ins_ledger;
delimiter $$
CREATE TRIGGER ins_ledger AFTER INSERT ON ledger FOR EACH ROW
BEGIN
	DECLARE u_id int;
	DECLARE u_trans_type int;
	DECLARE b_id int;
	DECLARE s_acc varchar(15);
	DECLARE is_training varchar(8);
	DECLARE r_acc varchar(15);
	DECLARE t_acc varchar(15);
	DECLARE l_inv int;
	DECLARE l_t_type varchar(32);

	SET u_trans_type = 0;

	IF (NEW.total > 0) THEN
		IF (NEW.trans_type = 'Application') OR (NEW.trans_type = 'Registration') OR (NEW.trans_type = 'Renewal') THEN
			SET u_trans_type = 1;
		END IF;
	END IF;
	IF (NEW.total < 0) THEN
		IF (NEW.trans_type = 'Payment') THEN
			SET u_trans_type = 2;
		END IF;
		IF (NEW.trans_type = 'Refund') THEN
			SET u_trans_type = 3;
		END IF;
	END IF;

	IF (u_trans_type = 1) THEN
		SELECT sales_account, cogs_account INTO s_acc, r_acc
		FROM stock_master
		WHERE stock_id = NEW.trans_type;

		SELECT NEW.description like 'Training Fee for %' INTO is_training;

		IF (is_training = 1) THEN
			SELECT sales_account, cogs_account INTO s_acc, r_acc
			FROM stock_master
			WHERE stock_id = 'RegistrarTraining';
		END IF;

		SELECT sales_gl_code INTO t_acc
		FROM tax_types
		WHERE id = 1;

		INSERT INTO sales_orders (order_no, trans_type, version, type, debtor_no, branch_code,
			reference, customer_ref, comments, ord_date, order_type, ship_via, delivery_address,
			contact_phone, deliver_to, freight_cost, from_stk_loc, delivery_date,
			payment_terms, total)
		SELECT NEW.documentnumber, 30, 1, 0, debtor_no, branch_code, 
			'auto', '', '', NEW.created, 1, 1, br_address, 
			'', br_name, 0, 'DEF', NEW.created, 
			4, NEW.total
		FROM cust_branch WHERE branch_ref = NEW.client_roid;

		INSERT INTO sales_order_details (order_no, trans_type, stk_code, description,
			qty_sent, unit_price, quantity, discount_percent)
		SELECT NEW.documentnumber, 30, NEW.trans_type, NEW.description, 
			1, NEW.total, 1, 0
		FROM cust_branch WHERE branch_ref = NEW.client_roid;

		INSERT INTO debtor_trans (trans_no, type, version, debtor_no, branch_code, tran_date, due_date,
			reference, tpe, order_, ov_amount, ov_gst, ov_freight, ov_freight_tax, ov_discount, alloc,
			rate, ship_via, dimension_id, dimension2_id, payment_terms)
		SELECT NEW.documentnumber, 13, 0, debtor_no, branch_code, NEW.created, NEW.created,
			'auto', 1, NEW.documentnumber, NEW.total, 0, 0, 0, 0, 0,
			1, 1, 0, 0, 1
		FROM cust_branch WHERE branch_ref = NEW.client_roid;

		INSERT INTO debtor_trans_details (debtor_trans_no, debtor_trans_type, stock_id, description, unit_price,
			unit_tax, quantity, discount_percent, standard_cost, qty_done, src_id)
		SELECT NEW.documentnumber, 13, NEW.trans_type, NEW.description, NEW.total,
			ROUND(NEW.total * NEW.tax / (1 + NEW.tax), 4), 1, 0, 0, 1, 0
		FROM cust_branch WHERE branch_ref = NEW.client_roid;

		SET u_id = LAST_INSERT_ID();

		INSERT INTO debtor_trans (trans_no, type, version, debtor_no, branch_code, tran_date, due_date,
			reference, tpe, order_, ov_amount, ov_gst, ov_freight, ov_freight_tax, ov_discount, alloc,
			rate, ship_via, dimension_id, dimension2_id, payment_terms)
		SELECT NEW.documentnumber, 10, 0, debtor_no, branch_code, NEW.created, NEW.created,
			NEW.documentnumber, 1, NEW.documentnumber, NEW.total, 0, 0, 0, 0, 0, 
			1, 1, 0, 0, 1
		FROM cust_branch WHERE branch_ref = NEW.client_roid;

		INSERT INTO debtor_trans_details (debtor_trans_no, debtor_trans_type, stock_id, description, unit_price,
			unit_tax, quantity, discount_percent, standard_cost, qty_done, src_id)
		SELECT NEW.documentnumber, 10, NEW.trans_type, NEW.description, NEW.total,
			ROUND(NEW.total * NEW.tax / (1 + NEW.tax), 4), 1, 0, 0, 0, u_id
		FROM cust_branch WHERE branch_ref = NEW.client_roid;

		INSERT INTO trans_tax_details (trans_type, trans_no, tran_date, tax_type_id, rate, ex_rate,
			included_in_price, net_amount, amount, memo)
		VALUES (10, NEW.documentnumber, NEW.created, 1, 16, 1,
			1, ROUND(NEW.total / (1 + NEW.tax), 2), ROUND(NEW.total * NEW.tax / (1 + NEW.tax), 2), 'auto');
		INSERT INTO trans_tax_details (trans_type, trans_no, tran_date, tax_type_id, rate, ex_rate,
			included_in_price, net_amount, amount, memo)
		VALUES (10, NEW.documentnumber, NEW.created, 1, 16, 1,
			1, ROUND(NEW.total / (1 + NEW.tax), 2), ROUND(NEW.total * NEW.tax / (1 + NEW.tax), 2), u_id);

		INSERT INTO gl_trans (type, type_no, tran_date, account, memo_,
			amount, dimension_id, dimension2_id, person_type_id, person_id)
		SELECT 10, NEW.documentnumber, NEW.created, s_acc, '', 
			ROUND(-1 * NEW.total / (1 + NEW.tax), 2), 0, 0, 2, debtor_no
		FROM cust_branch WHERE branch_ref = NEW.client_roid;

		INSERT INTO gl_trans (type, type_no, tran_date, account, memo_,
			amount, dimension_id, dimension2_id, person_type_id, person_id)
		SELECT 10, NEW.documentnumber, NEW.created, t_acc, '', 
			ROUND(-1 * NEW.total * NEW.tax / (1 + NEW.tax), 2), 0, 0, 2, debtor_no
		FROM cust_branch WHERE branch_ref = NEW.client_roid;

		INSERT INTO gl_trans (type, type_no, tran_date, account, memo_,
			amount, dimension_id, dimension2_id, person_type_id, person_id)
		SELECT 10, NEW.documentnumber, NEW.created, r_acc, '', 
			ROUND(NEW.total, 2), 0, 0, 2, debtor_no
		FROM cust_branch WHERE branch_ref = NEW.client_roid;
	END IF;

	IF (u_trans_type = 2) THEN
		SELECT id, account_code, cl_acct INTO b_id, s_acc, r_acc
		FROM bank_accounts
		WHERE import_link = NEW.description;

		INSERT INTO debtor_trans (trans_no, type, version, debtor_no, branch_code, tran_date, due_date,
			reference, tpe, order_, ov_amount, ov_gst, ov_freight, ov_freight_tax, ov_discount, alloc,
			rate, ship_via, dimension_id, dimension2_id)
		SELECT NEW.documentnumber, 12, 0, debtor_no, branch_code, NEW.created, CAST('0000-00-00' as date),
			NEW.ChequeNo, 0, 0, ((-1) * NEW.total), 0, 0, 0, 0, 0,
			1, 0, 0, 0
		FROM cust_branch WHERE branch_ref = NEW.client_roid;

		INSERT INTO bank_trans (type, trans_no, bank_act, ref, trans_date, amount,
			dimension_id, dimension2_id, person_type_id, person_id)
		SELECT 12, NEW.documentnumber, b_id, NEW.ChequeNo, NEW.created, ((-1) * NEW.total), 
			0, 0, 2, debtor_no
		FROM cust_branch WHERE branch_ref = NEW.client_roid;

		INSERT INTO gl_trans (type, type_no, tran_date, account, memo_,
			amount, dimension_id, dimension2_id, person_type_id, person_id)
		SELECT 12, NEW.documentnumber, NEW.created, s_acc, '', 
			(-1 * NEW.total), 0, 0, 2, debtor_no
		FROM cust_branch WHERE branch_ref = NEW.client_roid;

		INSERT INTO gl_trans (type, type_no, tran_date, account, memo_,
			amount, dimension_id, dimension2_id, person_type_id, person_id)
		SELECT 12, NEW.documentnumber, NEW.created, r_acc, '', 
			NEW.total, 0, 0, 2, debtor_no
		FROM cust_branch WHERE branch_ref = NEW.client_roid;
	END IF;

	IF (u_trans_type = 3) THEN
		SELECT documentnumber, trans_type INTO l_inv, l_t_type
		FROM ledger
		WHERE (id = NEW.refund_for_id);

		IF(l_t_type is null) THEN
			IF(LOCATE('renewal', NEW.description) > 0) THEN
				SET l_t_type = 'Renewal';
			END IF;
			IF(LOCATE('registering', NEW.description) > 0) THEN
				SET l_t_type = 'Registration';
			END IF;
			IF(l_t_type is null) THEN
				SET l_t_type = 'Renewal';
			END IF;
		END IF;

		SELECT sales_account, cr_acct INTO s_acc, r_acc
		FROM stock_master
		WHERE stock_id = l_t_type;

		SELECT sales_gl_code INTO t_acc
		FROM tax_types
		WHERE id = 1;
		
		INSERT INTO debtor_trans (trans_no, type, version, debtor_no, branch_code, tran_date, due_date,
			reference, tpe, order_, ov_amount, ov_gst, ov_freight, ov_freight_tax, ov_discount, alloc,
			rate, ship_via, dimension_id, dimension2_id, payment_terms)
		SELECT NEW.documentnumber, 11, 0, debtor_no, branch_code, NEW.created, NEW.created,
			NEW.documentnumber, 1, l_inv, -(NEW.total), 0, 0, 0, 0, 0, 
			1, 1, 0, 0, 1
		FROM cust_branch WHERE branch_ref = NEW.client_roid;

		INSERT INTO debtor_trans_details (debtor_trans_no, debtor_trans_type, stock_id, description, unit_price,
			unit_tax, quantity, discount_percent, standard_cost, qty_done, src_id)
		SELECT NEW.documentnumber, 11, l_t_type, NEW.description, -(NEW.total),
			ROUND(-(NEW.total) * NEW.tax / (1 + NEW.tax), 4), 1, 0, 0, 0, l_inv
		FROM cust_branch WHERE branch_ref = NEW.client_roid;

		INSERT INTO gl_trans (type, type_no, tran_date, account, memo_,
			amount, dimension_id, dimension2_id, person_type_id, person_id)
		SELECT 11, NEW.documentnumber, NEW.created, s_acc, '', 
			ROUND(-(NEW.total) / (1 + NEW.tax), 2), 0, 0, 2, debtor_no
		FROM cust_branch WHERE branch_ref = NEW.client_roid;

		INSERT INTO gl_trans (type, type_no, tran_date, account, memo_,
			amount, dimension_id, dimension2_id, person_type_id, person_id)
		SELECT 11, NEW.documentnumber, NEW.created, t_acc, '', 
			ROUND(-(NEW.total) * NEW.tax / (1 + NEW.tax), 2), 0, 0, 2, debtor_no
		FROM cust_branch WHERE branch_ref = NEW.client_roid;

		INSERT INTO gl_trans (type, type_no, tran_date, account, memo_,
			amount, dimension_id, dimension2_id, person_type_id, person_id)
		SELECT 11, NEW.documentnumber, NEW.created, r_acc, '', 
			ROUND(NEW.total, 2), 0, 0, 2, debtor_no
		FROM cust_branch WHERE branch_ref = NEW.client_roid;
	END IF;

END;$$
delimiter ;

DROP TRIGGER IF EXISTS ins_debtor_trans_details;
delimiter $$
CREATE TRIGGER ins_debtor_trans_details BEFORE INSERT ON debtor_trans_details FOR EACH ROW
BEGIN
	IF(NEW.src_id = 0) THEN
		SET NEW.src_id = NEW.id;
	END IF;
END;$$
delimiter ;

DROP FUNCTION IF EXISTS get_item_type;
delimiter $$
CREATE FUNCTION get_item_type(description varchar(240)) RETURNS varchar(32) deterministic
BEGIN
	DECLARE item_type varchar(32);

	IF(LOCATE('Registration', description)>0) THEN
		SET item_type = 'Registration';
	END IF;
	IF(LOCATE('registering', description)>0) THEN
		SET item_type = 'Registration';
	END IF;
	IF(LOCATE('Renewal', description)>0) THEN
		SET item_type = 'Renewal';
	END IF;
	IF(LOCATE('registered', description)>0) THEN
		SET item_type = 'Registration';
	END IF;
	IF(LOCATE('renewed', description)>0) THEN
		SET item_type = 'Renewal';
	END IF;

	RETURN item_type;
END;$$
delimiter ;

---- posting function
SELECT documentnumber, client_roid, trans_type, description, ROUND(total / (1 + tax), 0) as amount, 
created, exdate, previous_expiry_date, refund_for_id,
period_diff(date_format(exdate, '%Y%m'), date_format(previous_expiry_date, '%Y%m'))
FROM ledger
WHERE (created <= '2011-01-31') AND (exdate >= '2011-01-31')
AND (trans_type <> 'Payment') AND (trans_type <> 'Adjustment') AND (total <> 0)
ORDER BY documentnumber;

--- Update SQL statements
UPDATE ledger SET exdate = DATE_ADD(created, INTERVAL 1 YEAR)
WHERE (exdate is null);

--- Work SQL
SELECT *
FROM debtor_trans
WHERE debtor_trans.type = 11;

SELECT cust_allocations.amt, cust_allocations.trans_no_to 
FROM cust_allocations INNER JOIN debtor_trans ON cust_allocations.trans_no_from = debtor_trans.trans_no
WHERE debtor_trans.type = 11;

SELECT *
FROM debtor_trans INNER JOIN cust_allocations ON debtor_trans.trans_no = cust_allocations.trans_no_from
INNER JOIN gl_trans ON cust_allocations.trans_no_to = gl_trans.type_no
WHERE (debtor_trans.type = 11)
AND (gl_trans.type = 12);


---------------------------------
ALTER TABLE ledger ADD	ChequeNo		varchar(50);


---------- Clear the database for new periods
DELETE FROM bank_trans;
DELETE FROM comments;
DELETE FROM cust_allocations;
DELETE FROM cust_branch;
DELETE FROM debtors_master;
DELETE FROM debtor_trans;
DELETE FROM debtor_trans_details;
DELETE FROM gl_trans;
DELETE FROM ledger;
DELETE FROM refs;
DELETE FROM sales_orders;
DELETE FROM sales_order_details;
DELETE FROM supp_allocations;
DELETE FROM supp_invoice_items;
DELETE FROM supp_trans;
DELETE FROM trans_tax_details;
DELETE FROM voided;


------- Postgresql re-sync registrars
INSERT INTO audit.master (audit_user, audit_login) VALUES ('automation', 'automation');

UPDATE ledger SET ispicked = false WHERE created::date > '2015-12-31'::date;


SELECT * FROM ledger WHERE created::date > '2015-12-31'::date;






----------------- Update for direct posting of MPESA
CREATE TABLE ledger_t1 (
	id				integer primary key, 
	client_roid		varchar(16), 
	description		varchar(240), 
	currency		varchar(3),
	tax				real, 
	total			real, 
	created			date, 
	exdate			date,
	previous_expiry_date	date,
	months_posted	integer default 0,
	trans_type		varchar(32),
	refund_for_id	integer,
	documentnumber	integer,
	ChequeNo		varchar(50)
);

INSERT INTO ledger_t1 (id, client_roid, description, currency, tax, total, created, exdate, previous_expiry_date,
trans_type, refund_for_id, documentnumber, ChequeNo)
SELECT ledger.id - 423000, ledger.client_roid, ledger.description, ledger.currency, ledger.tax, 
ledger.total, ledger.created, ledger.exdate, ledger.previous_expiry_date, ledger.trans_type, 
ledger.refund_for_id, CONCAT('100', ledger.documentnumber), ledger.ChequeNo
FROM ledger INNER JOIN debtor_trans ON ledger.documentnumber = debtor_trans.trans_no
WHERE debtor_trans.type = 12 AND ledger.ChequeNo <> debtor_trans.reference
AND ledger.created >= '2017-01-01'
ORDER BY ledger.id;


INSERT INTO ledger (id, client_roid, description, currency, tax, total, created, exdate, previous_expiry_date,
trans_type, refund_for_id, documentnumber, ChequeNo)
SELECT id, client_roid, description, currency, tax, total, created, exdate, previous_expiry_date,
trans_type, refund_for_id, documentnumber, ChequeNo
FROM ledger_t1
ORDER BY id;


