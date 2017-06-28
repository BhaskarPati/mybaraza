---- assets
CREATE TABLE asset_types (
	asset_type_id			serial primary key,
	asset_account			integer references accounts,
	depreciation_account	integer references accounts,
	accumulated_account		integer references accounts,
	valuation_account		integer references accounts,
	disposal_account		integer references accounts,
	org_id					integer references orgs,
	asset_type_name			varchar(50) not null,
	depreciation_rate		real default 10 not null,
	display_order			integer,
	tag_prefix				varchar(4),
	Details					text
);
CREATE INDEX asset_types_asset_account ON asset_types (asset_account);
CREATE INDEX asset_types_depreciation_account ON asset_types (depreciation_account);
CREATE INDEX asset_types_accumulated_account ON asset_types (accumulated_account);
CREATE INDEX asset_types_valuation_account ON asset_types (valuation_account);
CREATE INDEX asset_types_disposal_account ON asset_types (disposal_account);
CREATE INDEX asset_types_org_id ON asset_types (org_id);

CREATE TABLE manufacturers (
	manufacturer_id			serial primary key,
	org_id					integer references orgs,
	manufacturer_name		varchar(50) not null unique,
	details					text
);
CREATE INDEX manufacturers_org_id ON manufacturers (org_id);

CREATE TABLE models (
	model_id				serial primary key,
	manufacturer_id			integer references manufacturers,
	asset_type_id			integer references asset_types,
	org_id					integer references orgs,
	model_name				varchar(50) not null,
	details					text
);
CREATE INDEX models_manufacturer_id ON models (manufacturer_id);
CREATE INDEX models_asset_type_id ON models (asset_type_id);
CREATE INDEX models_org_id ON models (org_id);

CREATE TABLE asset_status (
	asset_status_id			serial primary key,
	org_id					integer references orgs,
	asset_status_name		varchar(32) not null
);
CREATE INDEX asset_status_org_id ON asset_status (org_id);

CREATE TABLE assets (
	asset_id				serial primary key,
	model_id				integer references models,
	asset_status_id			integer references asset_status,
	entity_id				integer references entitys, 	--- Sales office
	org_id					integer references orgs,
	asset_description		varchar(50),
	asset_serial			varchar(50),
	purchase_date			date not null,
	purchase_value			real not null,
	disposal_amount			real,
	disposal_date			date,
	sold					boolean default false not null,
	disposal_posting		boolean default false not null,
	lost					boolean default false not null,
	stolen					boolean default false not null,
	purchase_invoiced		boolean default false not null,
	tag_number				varchar(50),
	asset_condition			varchar(50),
	client_id				integer,
	details					text
);
CREATE INDEX assets_model_id ON assets (model_id);
CREATE INDEX assets_entity_id ON assets (entity_id);
CREATE INDEX assets_asset_status_id ON assets (asset_status_id);
CREATE INDEX assets_org_id ON assets (org_id);

CREATE TABLE asset_locations (
	asset_location_id		serial primary key,
	org_id					integer references orgs,
	asset_location_name		varchar(50),
	details					text
);
CREATE INDEX asset_locations_org_id ON asset_locations (org_id);

CREATE TABLE asset_movements (
	asset_movement_id		serial primary key,
	asset_id				integer references assets,
	asset_location_id		integer references asset_locations,
	org_id					integer references orgs,
	move_date				date,
	move_by					varchar(50),
	details					text
);
CREATE INDEX asset_movements_asset_id ON asset_movements (asset_id);
CREATE INDEX asset_movements_asset_location_id ON asset_movements (asset_location_id);
CREATE INDEX asset_movements_org_id ON asset_movements (org_id);

CREATE TABLE asset_valuations (
	asset_valuation_id		serial primary key,
	asset_id				integer references assets,
	org_id					integer references orgs,
	valuation_date			date not null,
	asset_value				real default 0 not null,
	value_change			real default 0 not null,
	posted					boolean default false not null,
	details					text
);
CREATE INDEX asset_valuations_asset_id ON asset_valuations (asset_id);
CREATE INDEX asset_valuations_org_id ON asset_valuations (org_id);

CREATE TABLE asset_amortisation (
	asset_amortisation_id	serial primary key,
	asset_id				integer references assets,
	org_id					integer references orgs,
	amortisation_year		integer,
	asset_value				real,
	amount					real,
	posted					boolean default false not null,
	details					text
);
CREATE INDEX asset_amortisation_asset_id ON asset_amortisation (asset_id);
CREATE INDEX asset_amortisation_org_id ON asset_amortisation (org_id);

CREATE VIEW vw_models AS
	SELECT asset_types.asset_type_id, asset_types.asset_type_name, asset_types.display_order,
		manufacturers.manufacturer_id, manufacturers.manufacturer_name, 
		models.org_id, models.model_id, models.model_name, models.details,
		(asset_types.asset_type_name || ' ' || manufacturers.manufacturer_name || ' ' || models.model_name) as model
	FROM models INNER JOIN asset_types ON models.asset_type_id = asset_types.asset_type_id
		INNER JOIN manufacturers ON models.manufacturer_id = manufacturers.manufacturer_id;

CREATE VIEW vw_assets AS
	SELECT vw_models.asset_type_id, vw_models.asset_type_name, vw_models.display_order,
		vw_models.manufacturer_id, vw_models.manufacturer_name, 
		vw_models.model_id, vw_models.model_name, vw_models.model,
		asset_status.asset_status_id, asset_status.asset_status_name, 
		entitys.entity_id, entitys.entity_name,
		assets.org_id, assets.asset_id, assets.asset_description, assets.asset_serial, assets.purchase_date, 
		assets.purchase_value, assets.disposal_amount, assets.disposal_date, assets.disposal_posting, assets.sold,
		assets.lost, assets.stolen, assets.tag_number, assets.asset_condition, assets.purchase_invoiced, assets.details,
		(vw_models.asset_type_name || ' - ' || assets.asset_serial) as asset_disp
	FROM assets INNER JOIN vw_models ON assets.model_id = vw_models.model_id
		INNER JOIN asset_status ON assets.asset_status_id = asset_status.asset_status_id
		LEFT JOIN entitys ON assets.entity_id = entitys.entity_id;

CREATE VIEW vw_asset_movements AS
	SELECT asset_locations.asset_location_id, asset_locations.asset_location_name, 

		vw_assets.asset_type_id, vw_assets.asset_type_name, vw_assets.manufacturer_id, vw_assets.manufacturer_name, 
		vw_assets.model_id, vw_assets.model_name, vw_assets.model,
		vw_assets.asset_id, vw_assets.asset_description, vw_assets.asset_serial, vw_assets.purchase_date, 
		vw_assets.purchase_value, vw_assets.disposal_amount, vw_assets.disposal_date, vw_assets.disposal_posting, vw_assets.lost, 
		vw_assets.stolen, vw_assets.tag_number, vw_assets.asset_condition, 

		asset_movements.org_id,
		asset_movements.asset_movement_id, asset_movements.move_date, asset_movements.move_by, asset_movements.details
	FROM asset_movements INNER JOIN asset_locations ON asset_movements.asset_location_id = asset_locations.asset_location_id
		INNER JOIN vw_assets ON asset_movements.asset_id = vw_assets.asset_id;

CREATE VIEW vw_asset_valuations AS
	SELECT vw_assets.asset_type_id, vw_assets.asset_type_name, vw_assets.manufacturer_id, vw_assets.manufacturer_name, 
		vw_assets.model_id, vw_assets.model_name, vw_assets.model,
		vw_assets.asset_id, vw_assets.asset_description, vw_assets.asset_serial, vw_assets.purchase_date, 
		vw_assets.purchase_value, vw_assets.disposal_amount, vw_assets.disposal_date, vw_assets.disposal_posting, vw_assets.lost, 
		vw_assets.stolen, vw_assets.tag_number, vw_assets.asset_condition, 

		asset_valuations.org_id,
		asset_valuations.asset_valuation_id, asset_valuations.valuation_date, asset_valuations.asset_value, 
		asset_valuations.value_change, asset_valuations.posted, asset_valuations.details
	FROM asset_valuations INNER JOIN vw_assets ON asset_valuations.asset_id = vw_assets.asset_id;

CREATE VIEW vw_asset_amortisation AS
	SELECT vw_assets.asset_type_id, vw_assets.asset_type_name, vw_assets.manufacturer_id, vw_assets.manufacturer_name, 
		vw_assets.model_id, vw_assets.model_name, vw_assets.model,
		vw_assets.asset_id, vw_assets.asset_description, vw_assets.asset_serial, vw_assets.purchase_date, 
		vw_assets.purchase_value, vw_assets.disposal_amount, vw_assets.disposal_date, vw_assets.disposal_posting, vw_assets.lost, 
		vw_assets.stolen, vw_assets.tag_number, vw_assets.asset_condition, 

		asset_amortisation.org_id,
		asset_amortisation.asset_amortisation_id, asset_amortisation.amortisation_year, 
		asset_amortisation.asset_value, asset_amortisation.amount, asset_amortisation.posted, 
		asset_amortisation.details
	FROM asset_amortisation INNER JOIN vw_assets ON asset_amortisation.asset_id = vw_assets.asset_id;


CREATE OR REPLACE FUNCTION get_asset_value(assetid integer, valueYear integer) RETURNS real AS $$
DECLARE
	vperiod 		int;
	pvalue 			real;
	depreciation 	real;
BEGIN
	pvalue := 0;

	SELECT assets.purchase_value INTO pvalue
	FROM assets
	WHERE (asset_id = assetid) AND (YEAR(assets.purchase_date) <= valueYear);

	SELECT sum(amount) INTO depreciation
	FROM amortisation
	WHERE (asset_id	 = assetid) AND (amortisation_year < valueYear);
	IF(pvalue > depreciation) THEN
		pvalue := pvalue - depreciation;
	END IF;

	SELECT max(valuation_year) INTO vperiod
	FROM asset_valuations
	WHERE (asset_id = assetid) AND (valuation_year <= valueYear);

	SELECT asset_value INTO pvalue
	FROM asset_valuations
	WHERE (asset_id = assetid) AND (valuation_year = vperiod);

	SELECT sum(amount) INTO depreciation
	FROM amortisation
	WHERE (asset_id	 = assetid) AND (amortisation_year >= vperiod) AND (amortisation_year < valueYear);
	IF(pvalue > depreciation) THEN
		pvalue := pvalue - depreciation;
	END IF;

	RETURN pvalue;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION amortise(assetid integer) RETURNS varchar(50) AS $$
DECLARE
	periodid 		int;
	rate 			real;
	pvalue 			real;
	cvalue 			real;
	depreciation	real;
BEGIN
	SELECT asset_types.Depreciation_rate, assets.purchase_value, YEAR(assets.purchase_date) INTO rate, pvalue, periodid
	FROM asset_types INNER JOIN assets ON asset_types.asset_type_id = assets.asset_type_id
	WHERE asset_id = assetid;

	DELETE FROM amortisation WHERE (asset_id = assetid);

	cvalue := pvalue;
	depreciation := pvalue * rate / 100;
	LOOP
		IF (cvalue <= 0) THEN EXIT; END IF; -- exit loop

		pvalue := 0;
		SELECT asset_value INTO pvalue
		FROM asset_valuations
		WHERE (asset_id = assetid) AND (valuation_year = periodid);
		IF(pvalue > 1) THEN
			cvalue := pvalue;
			depreciation := pvalue * rate / 100;
		END IF;

		IF (cvalue < depreciation) THEN
			depreciation := cvalue;
		END IF;
		IF(depreciation > 1) THEN
			INSERT INTO amortisation (asset_id, amortisation_year, asset_value, amount)
			VALUES (assetid, periodid, cvalue, depreciation);
		END IF;

		periodid := periodid + 1;
		cvalue := cvalue - depreciation;
	END LOOP;

	RETURN 'Done';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION amortise_post(yearid integer) RETURNS varchar(50) AS $$
DECLARE
	cur1	RECORD;
	cur2	RECORD;
	cur3	RECORD;

	j_id 	integer;
BEGIN
	INSERT INTO journals (period_id, journal_date)
	SELECT period_id, CURRENT_DATE
	FROM periods
	WHERE (period_start <= CURRENT_DATE) AND (period_end >= CURRENT_DATE);

	j_id := currval('journals_journal_id_seq');

	-- Depreciation posting
	FOR cur1 IN SELECT asset_types.depreciation_account as a_a, asset_types.accumulated_account as a_b, 
		amortisation.amortisation_id as a_id, amortisation.amount as da
	FROM asset_types INNER JOIN assets ON asset_types.asset_type_id = assets.asset_type_id
		INNER JOIN amortisation ON assets.asset_id = amortisation.asset_id
	WHERE (amortisation.posted = false) AND (amortisation_year = yearid) LOOP
		INSERT INTO gls (journal_id, account_id, debit, credit)
		VALUES (j_id, cur1.a_a, cur1.da, 0); 

		INSERT INTO gls (journal_id, account_id, debit, credit)
		VALUES (j_id, cur1.a_b, 0, cur1.da); 

		UPDATE amortisation SET posted = true WHERE amortisation_id = cur1.a_id;
	END LOOP;

	-- Open cursor
	FOR cur2 IN SELECT asset_types.asset_account as a_a, asset_types.valuation_account as a_b, 
		asset_valuations.asset_valuation_id as a_id, asset_valuations.value_change as da
	FROM asset_types INNER JOIN assets ON asset_types.asset_type_id = assets.asset_type_id
		INNER JOIN asset_valuations ON assets.asset_id = asset_valuations.asset_id
	WHERE (asset_valuations.posted = false) AND (asset_valuations.valuation_year = yearid) LOOP
		INSERT INTO gls (journal_id, account_id, debit, credit)
		VALUES (j_id, cur2.a_a, cur2.da, 0);

		INSERT INTO gls (journal_id, account_id, debit, credit)
		VALUES (j_id, cur2.a_b, 0, cur2.da);

		UPDATE asset_valuations SET posted = true WHERE asset_valuation_id = cur2.a_id;
	END LOOP;

	-- Open cursor
	FOR cur3 IN SELECT asset_types.asset_account as a_a, asset_types.accumulated_account as a_b, 
		asset_types.disposal_account as a_c, assets.asset_id as a_id,
		assets.disposal_amount as da, assets.purchase_value as pc,
		COALESCE(sum(asset_valuations.value_change), 0) as vc
	FROM asset_types INNER JOIN assets ON asset_types.asset_type_id = assets.asset_type_id
		LEFT JOIN asset_valuations ON assets.asset_id = asset_valuations.asset_id
	WHERE (assets.inactive = true) AND (assets.disposal_posting = false) AND (YEAR(disposal_date) = yearid)
	GROUP BY asset_types.asset_account, asset_types.accumulated_account, 
		asset_types.disposal_account, assets.disposal_amount, assets.purchase_value LOOP

		INSERT INTO gls (journal_id, account_id, debit, credit)
		VALUES (j_id, cur3.a_a, 0, (cur3.pv + cur3.vc));

		INSERT INTO gls (journal_id, account_id, debit, credit)
		VALUES (j_id, cur3.a_c, cur3.da, 0);

		INSERT INTO gls (journal_id, account_id, debit, credit)
		VALUES (j_id, cur3.a_b, (cur3.pv + cur3.vc - cur3.da), 0);

		UPDATE assets SET disposal_posting = true WHERE asset_id = a_id;
	END LOOP;

	RETURN 'Done';
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION ins_asset_valuations() RETURNS trigger AS $$
BEGIN
	NEW.value_change = NEW.asset_value - get_asset_value(NEW.asset_id, NEW.valuation_year);
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_asset_valuations BEFORE INSERT OR UPDATE ON asset_valuations
    FOR EACH ROW EXECUTE PROCEDURE ins_asset_valuations();

CREATE OR REPLACE FUNCTION upd_assets() RETURNS trigger AS $$
BEGIN

	IF(NEW.disposal_posting = true)THEN
		IF(NEW.sold = true)THEN
			NEW.asset_status_id = 7;
		ELSE
			NEW.asset_status_id = 8;
		END IF;
	ELSIF(NEW.lost = true)THEN
		NEW.asset_status_id = 6;
	ELSIF(NEW.stolen = true)THEN
		NEW.asset_status_id = 5;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER upd_assets BEFORE INSERT OR UPDATE ON assets
	FOR EACH ROW EXECUTE PROCEDURE upd_assets();




