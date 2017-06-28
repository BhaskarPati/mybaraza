CREATE OR REPLACE FUNCTION ins_regions()  RETURNS trigger AS $$
DECLARE
	msg			varchar(255);
BEGIN

    INSERT INTO orgs(org_name, is_active) VALUES(New.region_name, true);
    NEW.org_id :=currval('orgs_org_id_seq');
   
    RETURN NEW;
END;
$$  LANGUAGE plpgsql;

CREATE TRIGGER ins_regions BEFORE INSERT ON regions
    FOR EACH ROW EXECUTE PROCEDURE ins_regions();
   -- select * from regions
--==================================================================================================
CREATE OR REPLACE FUNCTION ins_sub_regions()  RETURNS trigger AS $$
DECLARE
	v_parent_org_id		integer;
	msg					varchar(255);
BEGIN
	SELECT org_id INTO v_parent_org_id FROM regions WHERE region_id = NEW.region_id;
    INSERT INTO orgs(org_name, parent_org_id, is_active) 
    VALUES(New.sub_region_name, v_parent_org_id , true);
    
    NEW.org_id :=currval('orgs_org_id_seq');
   
    RETURN NEW;
END;
$$  LANGUAGE plpgsql;

CREATE TRIGGER ins_sub_regions BEFORE INSERT ON sub_regions
    FOR EACH ROW EXECUTE PROCEDURE ins_sub_regions();
--==================================================================================================

CREATE OR REPLACE FUNCTION ins_distributors()  RETURNS trigger AS $$
DECLARE
	v_parent_org_id		integer;
	msg					varchar(255);
BEGIN
	SELECT org_id INTO v_parent_org_id FROM sub_regions WHERE sub_region_id = NEW.sub_region_id;
    INSERT INTO orgs(org_name, parent_org_id, is_active) 
    VALUES(New.distributor_name, v_parent_org_id , true);
    
    NEW.org_id :=currval('orgs_org_id_seq');
   
    RETURN NEW;
END;
$$  LANGUAGE plpgsql;

CREATE TRIGGER ins_distributors BEFORE INSERT ON distributors
    FOR EACH ROW EXECUTE PROCEDURE ins_distributors();
--==================================================================================================
CREATE OR REPLACE FUNCTION ins_password() RETURNS trigger AS $$
DECLARE
	v_distributor_org_id		integer;
	v_entity_role				varchar(225);
BEGIN
	IF(NEW.first_password is null) AND (TG_OP = 'INSERT') THEN
		NEW.first_password := first_password();
	END IF;
	IF(TG_OP = 'INSERT') THEN
		IF (NEW.Entity_password is null) THEN
			NEW.Entity_password := md5(NEW.first_password);
		END IF;
	ELSIF(OLD.first_password <> NEW.first_password) THEN
		NEW.Entity_password := md5(NEW.first_password);
	END IF;
	
	IF NEW.distributor_id is not null THEN 
		SELECT org_id INTO v_distributor_org_id FROM distributors WHERE distributor_id = NEW.distributor_id;
		NEW.org_id := v_distributor_org_id;
	END IF;
	
	SELECT entity_role INTO v_entity_role FROM entity_types WHERE entity_type_id = NEW.entity_type_id;
	
	
	NEW.function_role = v_entity_role;
	
	


	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

--CREATE TRIGGER ins_password BEFORE INSERT OR UPDATE ON entitys
    --FOR EACH ROW EXECUTE PROCEDURE ins_password();
--==================================================================================================
CREATE OR REPLACE FUNCTION ins_sms_sale() RETURNS trigger AS $$
DECLARE
	v_entity_id			integer;
	rec_entity			RECORD;
	v_vendor_confirmed	integer;
	v_vendor_sold		integer;
	
	v_message_array		text[];
	
	
BEGIN
	v_message_array := string_to_array(NEW.message, '#');
	-- sg#id#vendor_confirmed#vendor_sold to 20583
	v_entity_id := CAST(v_message_array[2] AS int);
	v_vendor_confirmed := CAST(v_message_array[3] AS int);
	v_vendor_sold := CAST(v_message_array[4] AS int);
	
	
	SELECT org_id, distributor_id INTO rec_entity FROM entitys WHERE entity_id = v_entity_id;
	
	INSERT INTO sales (org_id,distributor_id, entity_id, sale_date,vendor_confirmed, vendor_sold)
	VALUES(rec_entity.org_id, rec_entity.distributor_id, v_entity_id, New.sms_time, v_vendor_confirmed,v_vendor_sold );
	
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;
--==================================================================================================



