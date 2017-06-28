
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



