CREATE OR REPLACE FUNCTION check_retrived(int, int) RETURNS int AS $$
	SELECT max(client_assets.client_asset_id)
	FROM client_requests INNER JOIN client_assets ON client_requests.client_request_id = client_assets.client_request_id
	WHERE (client_requests.client_id = $1) AND (client_assets.replaced_asset_id = $2) AND (client_assets.is_retrived = true);
$$ LANGUAGE SQL;

UPDATE client_assets SET replaced_asset_id = asset_id
WHERE is_retrived = true and replaced_asset_id is null;

DROP VIEW vw_client_assets;
CREATE VIEW vw_client_assets AS
	SELECT vw_client_requests.client_id, vw_client_requests.client_name, vw_client_requests.address, vw_client_requests.zipcode, 
		vw_client_requests.premises, vw_client_requests.street, vw_client_requests.division, vw_client_requests.town, 
		vw_client_requests.telno, vw_client_requests.email, vw_client_requests.pcc, vw_client_requests.iatano, vw_client_requests.website, 
		vw_client_requests.travel_manager, vw_client_requests.technical_contact,
		vw_client_requests.is_active, vw_client_requests.sys_country_id, vw_client_requests.sys_country_name, 
		vw_client_requests.account_manager_id, vw_client_requests.account_manager_name,
		vw_client_requests.account_manager_phone, vw_client_requests.account_manager_email,

		vw_client_requests.client_request_id, vw_client_requests.otrs_ref, vw_client_requests.crm_ref, 
		vw_client_requests.dnote_no, vw_client_requests.request_details, 
		vw_client_requests.request_type, vw_client_requests.request_status,
		vw_client_requests.receiving_engineer, vw_client_requests.receiving_at_agency,
		vw_client_requests.request_completed, vw_client_requests.completion_date,
		vw_client_requests.application_date, vw_client_requests.approve_status, 
		vw_client_requests.workflow_table_id, vw_client_requests.action_date,

		vw_assets.asset_type_id, vw_assets.asset_type_name, vw_assets.manufacturer_id, vw_assets.manufacturer_name, 
		vw_assets.model_id, vw_assets.model_name, vw_assets.model,
		vw_assets.asset_status_id, vw_assets.asset_status_name, vw_assets.entity_id, vw_assets.entity_name,
		vw_assets.asset_id, vw_assets.asset_description, vw_assets.asset_serial, vw_assets.purchase_date, 
		vw_assets.purchase_value, vw_assets.disposal_amount, vw_assets.disposal_date, vw_assets.disposal_posting, vw_assets.lost, 
		vw_assets.stolen, vw_assets.tag_number, vw_assets.asset_condition, 
		vw_assets.asset_disp,
		check_retrived(vw_client_requests.client_id, client_assets.asset_id) as retrived,
		
		r_assets.asset_type_id as r_asset_type_id, r_assets.asset_type_name as r_asset_type_name, 
		r_assets.manufacturer_id as r_manufacturer_id, r_assets.manufacturer_name as r_manufacturer_name,
		r_assets.model_id as r_model_id, r_assets.model_name as r_model_name, r_assets.model as r_model,
		r_assets.asset_id as r_asset_id, r_assets.asset_serial as r_asset_serial,
		r_assets.tag_number as r_tag_number, r_assets.asset_condition as r_asset_condition, 
		r_assets.asset_disp as r_asset_disp,

		client_assets.org_id, client_assets.client_asset_id, client_assets.is_issued, client_assets.date_issued, 
		client_assets.is_retrived, client_assets.date_retrived, client_assets.units, client_assets.narrative, 
		client_assets.equipment_status, client_assets.date_added, client_assets.date_changed,
		client_assets.is_for_client
	FROM client_assets INNER JOIN vw_client_requests ON client_assets.client_request_id = vw_client_requests.client_request_id
		LEFT JOIN vw_assets ON client_assets.asset_id = vw_assets.asset_id
		LEFT JOIN vw_assets as r_assets ON client_assets.replaced_asset_id = r_assets.asset_id;

		
CREATE OR REPLACE FUNCTION ins_client_assets() RETURNS trigger AS $$
DECLARE
	v_client_id				integer;
	v_client_asset_id		integer;
BEGIN

	IF (NEW.is_retrived = true) AND (NEW.replaced_asset_id is null) THEN
		RAISE EXCEPTION 'Enter the serial number for retrived equipment';
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_client_assets AFTER INSERT OR UPDATE ON client_assets
	FOR EACH ROW EXECUTE PROCEDURE ins_client_assets();

CREATE OR REPLACE FUNCTION aft_client_assets() RETURNS trigger AS $$
DECLARE
	v_client_id				integer;
	v_client_asset_id		integer;
BEGIN

	IF(TG_OP = 'DELETE')THEN
		IF(OLD.is_retrived = true)THEN
			UPDATE assets SET asset_status_id = 1 WHERE (asset_id = OLD.asset_id);
		ELSIF(OLD.is_issued = true)THEN
			UPDATE assets SET asset_status_id = 2 WHERE (asset_id = OLD.asset_id);
		END IF;
	ELSE
		IF(NEW.is_retrived = true)THEN
			UPDATE assets SET asset_status_id = 1 WHERE (asset_id = NEW.replaced_asset_id);
		END IF;
		IF(NEW.is_issued = true)THEN
			UPDATE assets SET asset_status_id = 2 WHERE (asset_id = NEW.asset_id);
		END IF;
	END IF;

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION aft_asset_movements() RETURNS trigger AS $$
BEGIN

	IF(NEW.asset_location_id = 1)THEN
		UPDATE assets SET asset_status_id = 1 WHERE (asset_id = NEW.asset_id);
	ELSIF(NEW.asset_location_id = 2)THEN
		UPDATE assets SET asset_status_id = 3 WHERE (asset_id = NEW.asset_id);
	END IF;

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;


	
	

