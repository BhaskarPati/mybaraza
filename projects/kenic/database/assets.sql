CREATE TABLE asset_types (
	asset_type_id			serial primary key,
	asset_type_name			varchar(50) not null,
	depreciation_type		integer default 1 not null,
	depreciation_rate		real default 10 not null,
	asset_account			varchar(15),
	depreciation_account	varchar(15),
	accumulated_account		varchar(15),
	valuation_account		varchar(15),
	disposal_account		varchar(15),
	inactive     			tinyint default 0 not null,
	Details					text
);

CREATE TABLE assets (
	asset_id				serial primary key,
	asset_type_id			integer references asset_types,
	item_id					integer references item_codes,
	asset_name				varchar(50),
	asset_serial			varchar(50),
	purchase_date			date not null,
	purchase_value			real not null,
	disposal_amount			real,
	disposal_date			date,
	disposal_posting		integer default 0,
	tag_number				varchar(50),
	asset_location			varchar(50),
	asset_condition			varchar(50),
	asset_acquisition		varchar(50),
	inactive     			tinyint default 0 not null,
	details					text
);
CREATE INDEX assets_asset_type_id ON assets (asset_type_id);
CREATE INDEX assets_item_id ON assets (item_id);

CREATE TABLE asset_valuations (
	asset_valuation_id		serial primary key,
	asset_id				integer references assets,
	valuation_year			integer,
	asset_value				real default 0 not null,
	value_change			real default 0 not null,
	posted					integer default 0 not null,
	inactive     			tinyint default 0 not null,
	details					text,
	unique(asset_id, valuation_year)
);
CREATE INDEX asset_valuations_asset_id ON asset_valuations (asset_id);

CREATE TABLE amortisation (
	amortisation_id			serial primary key,
	asset_id				integer references assets,
	amortisation_year		integer,
	asset_value				real,
	amount					real,
	posted					integer default 0 not null,
	inactive     			tinyint default 0 not null,
	details					text
);
CREATE INDEX amortisation_asset_id ON amortisation (asset_id);

DROP FUNCTION IF EXISTS get_asset_value;
delimiter $$
CREATE FUNCTION get_asset_value(assetid integer, valueYear integer) RETURNS real deterministic
BEGIN
	declare vperiod int;
	declare pvalue real;
	declare depreciation real;

	SET pvalue = 0;

	SELECT assets.purchase_value INTO pvalue
	FROM assets
	WHERE (asset_id = assetid) AND (YEAR(assets.purchase_date) <= valueYear);

	SELECT sum(amount) INTO depreciation
	FROM amortisation
	WHERE (asset_id	 = assetid) AND (amortisation_year < valueYear);
	IF(pvalue > depreciation) THEN
		SET pvalue = pvalue - depreciation;
	END IF;

	SELECT max(valuation_year) INTO vperiod
	FROM asset_valuations
	WHERE (asset_id = assetid) AND (valuation_year <= valueYear);

	IF(vperiod > 1900)THEN
		SELECT asset_value INTO pvalue
		FROM asset_valuations
		WHERE (asset_id = assetid) AND (valuation_year = vperiod);

		SELECT sum(amount) INTO depreciation
		FROM amortisation
		WHERE (asset_id	 = assetid) AND (amortisation_year >= vperiod) AND (amortisation_year < valueYear);
		IF(pvalue > depreciation) THEN
			SET pvalue = pvalue - depreciation;
		END IF;
	END IF;

	RETURN pvalue;
END;$$
delimiter ;

DROP FUNCTION IF EXISTS amortise;
delimiter $$
CREATE FUNCTION amortise(assetid integer) RETURNS varchar(50) deterministic
BEGIN
	declare periodid int;
	declare rate real;
	declare pvalue real;
	declare cvalue real;
	declare depreciation real;

	SELECT asset_types.Depreciation_rate, assets.purchase_value, YEAR(assets.purchase_date) INTO rate, pvalue, periodid
	FROM asset_types INNER JOIN assets ON asset_types.asset_type_id = assets.asset_type_id
	WHERE asset_id = assetid;

	DELETE FROM amortisation WHERE (asset_id = assetid);

	set cvalue = pvalue;
	set depreciation = pvalue * rate / 100;
	WHILE (cvalue > 0) DO
		SET pvalue = 0;
		SELECT asset_value INTO pvalue
		FROM asset_valuations
		WHERE (asset_id = assetid) AND (valuation_year = periodid);
		IF(pvalue > 1) THEN
			SET cvalue = pvalue;
			SET depreciation = pvalue * rate / 100;
		END IF;

		IF (cvalue < depreciation) THEN
			SET depreciation = cvalue;
		END IF;
		IF(depreciation > 1) THEN
			INSERT INTO amortisation (asset_id, amortisation_year, asset_value, amount)
			VALUES (assetid, periodid, cvalue, depreciation);
		END IF;

		SET periodid = periodid + 1;
		SET cvalue = cvalue - depreciation;
	END WHILE;

	RETURN 'Done';
END;$$
delimiter ;

DROP FUNCTION IF EXISTS amortise_post;
delimiter $$
CREATE FUNCTION amortise_post(yearid integer) RETURNS varchar(50) deterministic
BEGIN
	DECLARE u_gl decimal(5,0);
	DECLARE flag1 varchar(5) DEFAULT 'START';
	DECLARE a_id integer;
	DECLARE a_a varchar(15);
	DECLARE a_b varchar(15);
	DECLARE a_c varchar(15);
	DECLARE da real;
	DECLARE pv real;
	DECLARE vc real;

	DECLARE cur1 CURSOR FOR SELECT asset_types.depreciation_account, asset_types.accumulated_account, 
		amortisation.amortisation_id, amortisation.amount
	FROM asset_types INNER JOIN assets ON asset_types.asset_type_id = assets.asset_type_id
		INNER JOIN amortisation ON assets.asset_id = amortisation.asset_id
	WHERE (amortisation.posted = 0) AND (amortisation_year = yearid);

	DECLARE cur2 CURSOR FOR SELECT asset_types.asset_account, asset_types.valuation_account, 
		asset_valuations.asset_valuation_id, asset_valuations.value_change
	FROM asset_types INNER JOIN assets ON asset_types.asset_type_id = assets.asset_type_id
		INNER JOIN asset_valuations ON assets.asset_id = asset_valuations.asset_id
	WHERE (asset_valuations.posted = 0) AND (asset_valuations.valuation_year = yearid);

	DECLARE cur3 CURSOR FOR SELECT asset_types.asset_account, asset_types.accumulated_account, 
		asset_types.disposal_account, assets.asset_id,
		assets.disposal_amount, assets.purchase_value,
		IFNULL(sum(asset_valuations.value_change), 0) as sum_value_change
	FROM asset_types INNER JOIN assets ON asset_types.asset_type_id = assets.asset_type_id
		LEFT JOIN asset_valuations ON assets.asset_id = asset_valuations.asset_id
	WHERE (assets.inactive = 1) AND (assets.disposal_posting = 0) AND (YEAR(disposal_date) = yearid)
	GROUP BY asset_types.asset_account, asset_types.accumulated_account, 
		asset_types.disposal_account, assets.disposal_amount, assets.purchase_value;

	DECLARE CONTINUE HANDLER FOR NOT FOUND SET flag1 = 'END';
	SELECT CAST(next_reference as decimal(5,0)) INTO u_gl FROM sys_types WHERE type_id = 0;

	-- Depreciation posting
	OPEN cur1;
	WHILE flag1<>'END' DO
		FETCH cur1 INTO a_a, a_b, a_id, da;

		IF(flag1<>'END') THEN
			INSERT INTO gl_trans (type, type_no, tran_date, account, memo_,
				amount, dimension_id, dimension2_id)
			VALUES (0, u_gl, current_date(), a_a, '', da, 0, 0); 

			INSERT INTO gl_trans (type, type_no, tran_date, account, memo_,
				amount, dimension_id, dimension2_id)
			VALUES (0, u_gl, current_date(), a_b, '', da * (-1), 0, 0); 

			UPDATE amortisation SET posted = u_gl WHERE amortisation_id = a_id;
			SET u_gl = u_gl + 1;
		END IF;
	END WHILE;
	CLOSE cur1;

	-- Open cursor
	SET flag1 = 'START';
	OPEN cur2;
	WHILE flag1<>'END' DO
		FETCH cur2 INTO a_a, a_b, a_id, da;

		IF(flag1<>'END') THEN
			INSERT INTO gl_trans (type, type_no, tran_date, account, memo_,
				amount, dimension_id, dimension2_id)
			VALUES (0, u_gl, current_date(), a_a, '', da, 0, 0); 

			INSERT INTO gl_trans (type, type_no, tran_date, account, memo_,
				amount, dimension_id, dimension2_id)
			VALUES (0, u_gl, current_date(), a_b, '', da * (-1), 0, 0); 

			UPDATE asset_valuations SET posted = u_gl WHERE asset_valuation_id = a_id;
			SET u_gl = u_gl + 1;
		END IF;
	END WHILE;
	CLOSE cur2;

	-- Open cursor
	SET flag1 = 'START';
	OPEN cur3;
	WHILE flag1<>'END' DO
		FETCH cur3 INTO a_a, a_b, a_c, a_id, da, pv, vc;

		IF(flag1<>'END') THEN
			INSERT INTO gl_trans (type, type_no, tran_date, account, memo_,
				amount, dimension_id, dimension2_id)
			VALUES (0, u_gl, current_date(), a_a, '', (pv + vc) * (-1) , 0, 0); 

			INSERT INTO gl_trans (type, type_no, tran_date, account, memo_,
				amount, dimension_id, dimension2_id)
			VALUES (0, u_gl, current_date(), a_c, '', da, 0, 0); 

			INSERT INTO gl_trans (type, type_no, tran_date, account, memo_,
				amount, dimension_id, dimension2_id)
			VALUES (0, u_gl, current_date(), a_b, '', (pv + vc - da), 0, 0); 

			UPDATE assets SET disposal_posting = u_gl WHERE asset_id = a_id;
			SET u_gl = u_gl + 1;
		END IF;
	END WHILE;
	CLOSE cur3;

	UPDATE sys_types SET next_reference = u_gl WHERE type_id = 0;

	RETURN 'Done';
END;$$
delimiter ;

DROP TRIGGER IF EXISTS ins_asset_valuations;
delimiter $$
CREATE TRIGGER ins_asset_valuations BEFORE INSERT ON asset_valuations FOR EACH ROW
BEGIN
	SET NEW.value_change = NEW.asset_value - get_asset_value(NEW.asset_id, NEW.valuation_year);
END;$$
delimiter ;

