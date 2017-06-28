CREATE VIEW vw_sub_regions AS
	SELECT orgs.org_id, orgs.org_name, regions.region_id, regions.region_name, sub_regions.sub_region_id, sub_regions.sub_region_name, sub_regions.details
	FROM sub_regions
	INNER JOIN orgs ON sub_regions.org_id = orgs.org_id
	INNER JOIN regions ON sub_regions.region_id = regions.region_id; 

	

CREATE VIEW vw_distributors AS
	SELECT orgs.org_id, orgs.org_name, sub_regions.sub_region_id, sub_regions.sub_region_name, distributors.distributor_id, distributors.distributor_name, distributors.details
	FROM distributors
	INNER JOIN orgs ON distributors.org_id = orgs.org_id
	INNER JOIN sub_regions ON distributors.sub_region_id = sub_regions.sub_region_id;
	
	
	
CREATE OR REPLACE VIEW vw_entitys AS
	SELECT vw_orgs.org_id, vw_orgs.org_name, vw_orgs.is_default as org_is_default, 
		vw_orgs.is_active as org_is_active, vw_orgs.logo as org_logo, 

		vw_orgs.org_sys_country_id, vw_orgs.org_sys_country_name, 
		vw_orgs.org_address_id, vw_orgs.org_table_name,
		vw_orgs.org_post_office_box, vw_orgs.org_postal_code, 
		vw_orgs.org_premises, vw_orgs.org_street, vw_orgs.org_town, 
		vw_orgs.org_phone_number, vw_orgs.org_extension, 
		vw_orgs.org_mobile, vw_orgs.org_fax, vw_orgs.org_email, vw_orgs.org_website,

		vw_entity_address.address_id, vw_entity_address.address_name,
		vw_entity_address.sys_country_id, vw_entity_address.sys_country_name, vw_entity_address.table_name, 
		vw_entity_address.is_default, vw_entity_address.post_office_box, vw_entity_address.postal_code, 
		vw_entity_address.premises, vw_entity_address.street, vw_entity_address.town, 
		vw_entity_address.phone_number, vw_entity_address.extension, vw_entity_address.mobile, 
		vw_entity_address.fax, vw_entity_address.email, vw_entity_address.website,

		entitys.entity_id, entitys.entity_name, entitys.user_name, entitys.super_user, entitys.entity_leader, 
		entitys.date_enroled, entitys.is_active, entitys.entity_password, entitys.first_password, 
		entitys.function_role, entitys.primary_email, entitys.primary_telephone,
		entity_types.entity_type_id, entity_types.entity_type_name, 
		entity_types.entity_role, entity_types.use_key,
		entitys.distributor_id, distributors.distributor_name
	FROM (entitys LEFT JOIN vw_entity_address ON entitys.entity_id = vw_entity_address.table_id)
		INNER JOIN vw_orgs ON entitys.org_id = vw_orgs.org_id
		INNER JOIN entity_types ON entitys.entity_type_id = entity_types.entity_type_id
		INNER JOIN distributors ON distributors.distributor_id = entitys.distributor_id;
	

	
		


CREATE VIEW vw_sales AS
	SELECT distributors.distributor_id, distributors.distributor_name, entitys.entity_id, entitys.entity_name, orgs.org_id, orgs.org_name, sales.sale_id,  sales.sale_date, sales.ordered, sales.supplied, sales.delivered, sales.vendor_confirmed, sales.vendor_sold, sales.vendor_returns, sales.unit_price, sales.details
	FROM sales
	INNER JOIN distributors ON sales.distributor_id = distributors.distributor_id
	INNER JOIN entitys ON sales.entity_id = entitys.entity_id
	INNER JOIN orgs ON sales.org_id = orgs.org_id;
	
	
CREATE OR REPLACE VIEW vw_sub_region_sales AS
	SELECT
		orgs.parent_org_id AS sub_region_org_id, vw_orgs.org_name AS sub_region_name,
		vw_sales.distributor_id, vw_sales.distributor_name,
		SUM(vw_sales.ordered) AS ordered,
		SUM(vw_sales.supplied) AS supplied,
		SUM(vw_sales.delivered) AS delivered,
		SUM(vw_sales.vendor_confirmed) AS vendor_confirmed,
		SUM(vw_sales.vendor_sold) AS vendor_sold,
		SUM(vw_sales.vendor_returns) AS vendor_returns,
		vw_sales.unit_price,
		
		((SUM(vw_sales.delivered) - SUM(vw_sales.vendor_returns)) * vw_sales.unit_price) AS expected_revenue,
		(SUM(vw_sales.vendor_sold) * vw_sales.unit_price) AS submitted_revenue,
		vw_sales.sale_date
	FROM vw_sales
	INNER JOIN orgs ON orgs.org_id = vw_sales.org_id
	INNER JOIN vw_orgs ON vw_orgs.org_id = orgs.parent_org_id
	GROUP BY orgs.parent_org_id, vw_orgs.org_name, vw_sales.distributor_id, vw_sales.distributor_name, vw_sales.sale_date,vw_sales.unit_price;