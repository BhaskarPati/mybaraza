CREATE TABLE requisitions (
	requisition_id			serial primary key,
	point_of_use			varchar(50),
	narrative				varchar(240),
	application_date		timestamp default now(),
	completed 	    		tinyint default 0 not null,
	processed				tinyint default 0 not null,
	inactive	     		tinyint default 0 not null,
	details					text
);

CREATE TABLE requisition_details (
	requisition_detail_id	serial primary key,
	requisition_id			integer references requisitions,
	item_code				varchar(20),
	supplier_id				integer references suppliers,
	lpo_id					integer default 0,
	order_quantity			integer default 0 not null,
	estimate_price			real default 0 not null,
	quantity				integer default 0 not null,
	price					real default 0 not null,
	purpose					varchar(320)
);
CREATE INDEX requisition_details_requisition_id ON requisition_details (requisition_id);
CREATE INDEX requisition_details_item_code ON requisition_details (item_code);
CREATE INDEX requisition_details_supplier_id ON requisition_details (supplier_id);

DROP FUNCTION IF EXISTS get_item_tax;
delimiter $$
CREATE FUNCTION get_item_tax(itemcode varchar(20)) RETURNS real deterministic
BEGIN
	DECLARE it_id int;
	DECLARE it_ex int;
	DECLARE itemtax real;

	SELECT item_tax_types.id, item_tax_types.exempt INTO it_id, it_ex
	FROM stock_master INNER JOIN item_tax_types ON stock_master.tax_type_id = item_tax_types.id
	WHERE (stock_master.stock_id = itemcode);

	SET itemtax = 0;
	IF (it_ex = 0) THEN
		SELECT SUM(tax_types.rate) INTO itemtax
		FROM  tax_types LEFT JOIN item_tax_type_exemptions ON tax_types.id = item_tax_type_exemptions.tax_type_id
		WHERE item_tax_type_exemptions.tax_type_id is null;
	END IF;

	RETURN itemtax;
END;$$
delimiter ;


DROP FUNCTION IF EXISTS generate_po;
delimiter $$
CREATE FUNCTION generate_po() RETURNS varchar(50) deterministic
BEGIN
	DECLARE u_gl decimal(5,0);
	DECLARE flag1 varchar(5) DEFAULT 'START';
	DECLARE rst varchar(50);
	DECLARE s_id integer;
	DECLARE i_c real;

	DECLARE cur1 CURSOR FOR SELECT requisition_details.supplier_id, 
		sum(requisition_details.quantity * requisition_details.price *
			(100 + get_item_tax(requisition_details.item_code)) / 100)
	FROM requisition_details
	WHERE (requisition_details.lpo_id = 0) AND (requisition_details.supplier_id > 0)
	GROUP BY requisition_details.supplier_id
	ORDER BY requisition_details.supplier_id;

	DECLARE CONTINUE HANDLER FOR NOT FOUND SET flag1 = 'END';
	SELECT CAST(next_reference as decimal(5,0)) INTO u_gl FROM sys_types WHERE type_id = 18;

	-- Posting for po generation
	OPEN cur1;
	WHILE (flag1<>'END') DO
		FETCH cur1 INTO s_id, i_c;
		
		IF (flag1<>'END') THEN
			INSERT INTO purch_orders (supplier_id, comments, ord_date, reference, requisition_no,
				into_stock_location, delivery_address, total, tax_included)
			VALUES (s_id, '', current_date(), u_gl, '', 'DEF', 'Address', i_c, 0);

			SET rst = generate_po_items(LAST_INSERT_ID(), s_id);
			SET u_gl = u_gl + 1;
		END IF;
	END WHILE;
	CLOSE cur1;

	UPDATE sys_types SET next_reference = u_gl WHERE type_id = 18;

	RETURN 'Done';
END;$$
delimiter ;

DROP FUNCTION IF EXISTS generate_po_items;
delimiter $$
CREATE FUNCTION generate_po_items(po_id integer, s_id integer) RETURNS varchar(50) deterministic
BEGIN
	DECLARE u_gl decimal(5,0);
	DECLARE flag2 varchar(5) DEFAULT 'START';
	DECLARE i_id varchar(20);
	DECLARE r_id integer;
	DECLARE i_q integer;
	DECLARE i_p real;
	DECLARE i_d varchar(200);

	DECLARE cur2 CURSOR FOR SELECT item_codes.item_code, item_codes.description,
		requisition_details.requisition_detail_id, requisition_details.quantity, requisition_details.price
	FROM requisition_details INNER JOIN item_codes ON requisition_details.item_code = item_codes.item_code
	WHERE (requisition_details.lpo_id = 0) AND (requisition_details.supplier_id = s_id);

	DECLARE CONTINUE HANDLER FOR NOT FOUND SET flag2 = 'END';

	-- Posting for po generation
	OPEN cur2;
	WHILE (flag2<>'END') DO
		FETCH cur2 INTO i_id, i_d, r_id, i_q, i_p;

		IF (flag2<>'END') THEN
			INSERT INTO purch_order_details (order_no, item_code, description, delivery_date, qty_invoiced,
				unit_price, act_price, std_cost_unit, quantity_ordered, quantity_received)
			VALUES (po_id, i_id, i_d, current_date()+INTERVAL 14 day, 0, i_p, 0, 0, i_q, 0);

			UPDATE requisition_details SET lpo_id = po_id WHERE requisition_detail_id = r_id;
		END IF;
	END WHILE;
	CLOSE cur2;

	RETURN 'Done';
END;$$
delimiter ;

