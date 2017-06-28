DROP TABLE dc_trds_items;
DROP TABLE dc_trd_suppliers;
DROP TABLE dc_trd_team;
DROP TABLE dc_trd_process;
DROP TABLE dc_tenders;
DROP TABLE dc_td_process;
DROP TABLE dc_td_types;

CREATE TABLE dc_td_types (
	dc_td_types_id				CHARACTER VARYING(32) NOT NULL,
	ad_client_id				CHARACTER VARYING(32) NOT NULL,
	ad_org_id					CHARACTER VARYING(32) NOT NULL,
	isactive					CHARACTER(1) DEFAULT 'Y' NOT NULL,
	created						TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
	createdby					CHARACTER VARYING(32) NOT NULL,
	updated						TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
	updatedby					CHARACTER VARYING(32) NOT NULL,

	dc_td_types_name			varchar(50),
	details						text,

	CONSTRAINT dc_td_types_isactive_check CHECK (isactive = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])),
	CONSTRAINT dc_td_types_key PRIMARY KEY (dc_td_types_id),
	CONSTRAINT dc_td_types_ad_org FOREIGN KEY (AD_ORG_ID) REFERENCES AD_ORG (ad_org_id),
	CONSTRAINT dc_td_types_ad_client FOREIGN KEY (AD_CLIENT_ID) REFERENCES AD_CLIENT (ad_client_id)
);

CREATE TABLE dc_td_process (
	dc_td_process_id			CHARACTER VARYING(32) NOT NULL,
	ad_client_id				CHARACTER VARYING(32) NOT NULL,
	ad_org_id					CHARACTER VARYING(32) NOT NULL,
	isactive					CHARACTER(1) DEFAULT 'Y' NOT NULL,
	created						TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
	createdby					CHARACTER VARYING(32) NOT NULL,
	updated						TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
	updatedby					CHARACTER VARYING(32) NOT NULL,

	dc_td_types_id				CHARACTER VARYING(32) NOT NULL,
	dc_td_process_name			varchar(50),
	tender_stage				numeric(4),
	duration					numeric(4),
	details						text,

	CONSTRAINT dc_td_process_isactive_check CHECK (isactive = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])),
	CONSTRAINT dc_td_process_key PRIMARY KEY (dc_td_process_id),
	CONSTRAINT dc_td_process_ad_org FOREIGN KEY (AD_ORG_ID) REFERENCES AD_ORG (ad_org_id),
	CONSTRAINT dc_td_process_ad_client FOREIGN KEY (AD_CLIENT_ID) REFERENCES AD_CLIENT (ad_client_id),
	CONSTRAINT dc_td_process_dc_td_types FOREIGN KEY (dc_td_types_id) REFERENCES dc_td_types (dc_td_types_id)
);

CREATE TABLE dc_tenders (
	dc_tenders_id				CHARACTER VARYING(32) NOT NULL,
	ad_client_id				CHARACTER VARYING(32) NOT NULL,
	ad_org_id					CHARACTER VARYING(32) NOT NULL,
	isactive					CHARACTER(1) DEFAULT 'Y' NOT NULL,
	created						TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
	createdby					CHARACTER VARYING(32) NOT NULL,
	updated						TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
	updatedby					CHARACTER VARYING(32) NOT NULL,

	dc_td_types_id				CHARACTER VARYING(32) NOT NULL,
	dc_tenders_name				varchar(320),
	tender_number				varchar(64),
	tender_date					TIMESTAMP NOT NULL,
	tender_end_date				TIMESTAMP,
	iscompleted					CHARACTER(1) DEFAULT 'N' NOT NULL,
	isgenerate					CHARACTER(1) DEFAULT 'N' NOT NULL,
	details						text,

	CONSTRAINT dc_tenders_isactive_check CHECK (isactive = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])),
	CONSTRAINT dc_tenders_iscompleted_check CHECK (iscompleted = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])),
	CONSTRAINT dc_tenders_isgenerate_check CHECK (isgenerate = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])),
	CONSTRAINT dc_tenders_key PRIMARY KEY (dc_tenders_id),
	CONSTRAINT dc_tenders_ad_org FOREIGN KEY (AD_ORG_ID) REFERENCES AD_ORG (ad_org_id),
	CONSTRAINT dc_tenders_ad_client FOREIGN KEY (AD_CLIENT_ID) REFERENCES AD_CLIENT (ad_client_id),
	CONSTRAINT dc_tenders_dc_td_types FOREIGN KEY (dc_td_types_id) REFERENCES dc_td_types (dc_td_types_id)
);

CREATE TABLE dc_trd_process (
	dc_trd_process_id			CHARACTER VARYING(32) NOT NULL,
	ad_client_id				CHARACTER VARYING(32) NOT NULL,
	ad_org_id					CHARACTER VARYING(32) NOT NULL,
	isactive					CHARACTER(1) DEFAULT 'Y' NOT NULL,
	created						TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
	createdby					CHARACTER VARYING(32) NOT NULL,
	updated						TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
	updatedby					CHARACTER VARYING(32) NOT NULL,

	dc_tenders_id				CHARACTER VARYING(32),
	dc_td_process_id			CHARACTER VARYING(32) NOT NULL,
	duration					numeric(4),
	proposed_start				TIMESTAMP,
	proposed_end				TIMESTAMP,
	actual_start				TIMESTAMP,
	actual_end					TIMESTAMP,
	iscompleted					CHARACTER(1) DEFAULT 'Y' NOT NULL,
	details						text,

	CONSTRAINT dc_trd_process_isactive_check CHECK (isactive = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])),
	CONSTRAINT dc_trd_process_iscompleted_ch CHECK (iscompleted = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])),
	CONSTRAINT dc_trd_process_key PRIMARY KEY (dc_trd_process_id),
	CONSTRAINT dc_trd_process_ad_org FOREIGN KEY (AD_ORG_ID) REFERENCES AD_ORG (ad_org_id),
	CONSTRAINT dc_trd_process_ad_client FOREIGN KEY (AD_CLIENT_ID) REFERENCES AD_CLIENT (ad_client_id),
	CONSTRAINT dc_trd_process_dc_tenders_id FOREIGN KEY (dc_tenders_id) REFERENCES dc_tenders (dc_tenders_id),
	CONSTRAINT dc_trd_process_dc_td_process FOREIGN KEY (dc_td_process_id) REFERENCES dc_td_process (dc_td_process_id)
);

CREATE TABLE dc_trd_team (
	dc_trd_team_id				CHARACTER VARYING(32) NOT NULL,
	ad_client_id				CHARACTER VARYING(32) NOT NULL,
	ad_org_id					CHARACTER VARYING(32) NOT NULL,
	isactive					CHARACTER(1) DEFAULT 'Y' NOT NULL,
	created						TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
	createdby					CHARACTER VARYING(32) NOT NULL,
	updated						TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
	updatedby					CHARACTER VARYING(32) NOT NULL,

	dc_tenders_id				CHARACTER VARYING(32) NOT NULL,
	ad_user_id					CHARACTER VARYING(32) NOT NULL,
	user_role					CHARACTER VARYING(64),
	details						text,

	CONSTRAINT dc_trd_team_isactive_check CHECK (isactive = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])),
	CONSTRAINT dc_trd_team_key PRIMARY KEY (dc_trd_team_id),
	CONSTRAINT dc_trd_team_ad_org FOREIGN KEY (AD_ORG_ID) REFERENCES AD_ORG (ad_org_id),
	CONSTRAINT dc_trd_team_ad_client FOREIGN KEY (AD_CLIENT_ID) REFERENCES AD_CLIENT (ad_client_id),
	CONSTRAINT dc_trd_team_dc_tenders_id FOREIGN KEY (dc_tenders_id) REFERENCES dc_tenders (dc_tenders_id),
	CONSTRAINT dc_trd_team_ad_user_id FOREIGN KEY (ad_user_id) REFERENCES ad_user (ad_user_id)
);

CREATE TABLE dc_trd_suppliers (
	dc_trd_suppliers_id			CHARACTER VARYING(32) NOT NULL,
	ad_client_id				CHARACTER VARYING(32) NOT NULL,
	ad_org_id					CHARACTER VARYING(32) NOT NULL,
	isactive					CHARACTER(1) DEFAULT 'Y' NOT NULL,
	created						TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
	createdby					CHARACTER VARYING(32) NOT NULL,
	updated						TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
	updatedby					CHARACTER VARYING(32) NOT NULL,

	c_bpartner_id				CHARACTER VARYING(32) NOT NULL,
	c_currency_id				VARCHAR(32) NOT NULL,

	bidder_name					VARCHAR(120),
	bidder_address				CLOB,

	dc_tenders_id				CHARACTER VARYING(32) NOT NULL,
	tender_amount				NUMERIC,
	bind_bond					VARCHAR(120),
	bind_bond_amount			NUMERIC,
	return_date					TIMESTAMP,
	points						NUMERIC,
	isawarded					CHARACTER(1) DEFAULT 'N' NOT NULL,
	award_reference				CHARACTER VARYING(32),
	award_letter				CHARACTER(1),
	details						text,

	CONSTRAINT dc_trd_suppliers_isactive_ch CHECK (isactive = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])),
	CONSTRAINT dc_trd_suppliers_isawarded_ch CHECK (isawarded = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])),
	CONSTRAINT dc_trd_suppliers_key PRIMARY KEY (dc_trd_suppliers_id),
	CONSTRAINT dc_trd_suppliers_ad_org FOREIGN KEY (AD_ORG_ID) REFERENCES AD_ORG (ad_org_id),
	CONSTRAINT dc_trd_suppliers_ad_client FOREIGN KEY (AD_CLIENT_ID) REFERENCES AD_CLIENT (ad_client_id),
	CONSTRAINT dc_trd_suppliers_c_bpartner FOREIGN KEY (C_BPARTNER_ID) REFERENCES C_BPARTNER (c_bpartner_id), 
	CONSTRAINT dc_trd_suppliers_c_currency FOREIGN KEY (C_CURRENCY_ID) REFERENCES C_CURRENCY (c_currency_id),
	CONSTRAINT dc_trd_suppliers_dc_tenders FOREIGN KEY (dc_tenders_id) REFERENCES dc_tenders (dc_tenders_id)
);

CREATE TABLE dc_trds_items (
	dc_trds_items_id			CHARACTER VARYING(32) NOT NULL,
	ad_client_id				CHARACTER VARYING(32) NOT NULL,
	ad_org_id					CHARACTER VARYING(32) NOT NULL,
	isactive					CHARACTER(1) DEFAULT 'Y' NOT NULL,
	created						TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
	createdby					CHARACTER VARYING(32) NOT NULL,
	updated						TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
	updatedby					CHARACTER VARYING(32) NOT NULL,

	dc_trd_suppliers_id			CHARACTER VARYING(32) NOT NULL,
	item_description			CHARACTER VARYING(320) NOT NULL,
	quantity					NUMERIC,
	item_amount					NUMERIC,
	item_tax					NUMERIC,
	details						text,

	CONSTRAINT dc_trds_items_isactive_ch CHECK (isactive = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])),
	CONSTRAINT dc_trds_items_key PRIMARY KEY (dc_trds_items_id),
	CONSTRAINT dc_trds_items_ad_org FOREIGN KEY (AD_ORG_ID) REFERENCES AD_ORG (ad_org_id),
	CONSTRAINT dc_trds_items_ad_client FOREIGN KEY (AD_CLIENT_ID) REFERENCES AD_CLIENT (ad_client_id),
	CONSTRAINT dc_trds_items_dc_trd_supplier FOREIGN KEY (dc_trd_suppliers_id) REFERENCES dc_trd_suppliers (dc_trd_suppliers_id)
);

CREATE TABLE dc_contracts (
	dc_contracts_id				CHARACTER VARYING(32) NOT NULL,
	ad_client_id				CHARACTER VARYING(32) NOT NULL,
	ad_org_id					CHARACTER VARYING(32) NOT NULL,
	isactive					CHARACTER(1) DEFAULT 'Y' NOT NULL,
	created						TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
	createdby					CHARACTER VARYING(32) NOT NULL,
	updated						TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
	updatedby					CHARACTER VARYING(32) NOT NULL,

	dc_trd_suppliers_id			CHARACTER VARYING(32) NOT NULL,
	item_description			CHARACTER VARYING(320) NOT NULL,
	contract_date				TIMESTAMP,
	contract_end				TIMESTAMP,
	contract_amount				NUMERIC,
	contract_tax				NUMERIC,
	details						text,

	CONSTRAINT dc_contracts_isactive_ch CHECK (isactive = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])),
	CONSTRAINT dc_contracts_key PRIMARY KEY (dc_contracts_id),
	CONSTRAINT dc_contracts_ad_org FOREIGN KEY (AD_ORG_ID) REFERENCES AD_ORG (ad_org_id),
	CONSTRAINT dc_contracts_ad_client FOREIGN KEY (AD_CLIENT_ID) REFERENCES AD_CLIENT (ad_client_id),
	CONSTRAINT dc_contracts_dc_trd_supplier FOREIGN KEY (dc_trd_suppliers_id) REFERENCES dc_trd_suppliers (dc_trd_suppliers_id)
);

CREATE TABLE dc_catalogue (
	dc_catalogue_id				CHARACTER VARYING(32) NOT NULL,
	ad_client_id				CHARACTER VARYING(32) NOT NULL,
	ad_org_id					CHARACTER VARYING(32) NOT NULL,
	isactive					CHARACTER(1) DEFAULT 'Y' NOT NULL,
	created						TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
	createdby					CHARACTER VARYING(32) NOT NULL,
	updated						TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
	updatedby					CHARACTER VARYING(32) NOT NULL,

	m_product_id				CHARACTER VARYING(32) NOT NULL,
	dc_trd_suppliers_id			CHARACTER VARYING(32) NOT NULL,
	item_description			CHARACTER VARYING(320),
	valid_from					TIMESTAMP,
	valid_to					TIMESTAMP,
	lead_time					NUMERIC,
	item_amount					NUMERIC,
	item_tax					NUMERIC,
	details						text,

	CONSTRAINT dc_catalogue_isactive_ch CHECK (isactive = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])),
	CONSTRAINT dc_catalogue_key PRIMARY KEY (dc_catalogue_id),
	CONSTRAINT dc_catalogue_ad_org FOREIGN KEY (AD_ORG_ID) REFERENCES AD_ORG (ad_org_id),
	CONSTRAINT dc_catalogue_ad_client FOREIGN KEY (AD_CLIENT_ID) REFERENCES AD_CLIENT (ad_client_id),
	CONSTRAINT dc_catalogue_m_product FOREIGN KEY (m_product_id) REFERENCES m_product (m_product_id),
	CONSTRAINT dc_catalogue_dc_trd_supplier FOREIGN KEY (dc_trd_suppliers_id) REFERENCES dc_trd_suppliers (dc_trd_suppliers_id)
);

CREATE VIEW dc_entity_address_v AS
	SELECT c_bpartner.c_bpartner_id, c_bpartner.value, c_bpartner.name,
		c_location.address1, c_location.address2, c_location.city,
		c_location.postal, c_location.postal_add, c_country.name as country_name
	FROM c_bpartner INNER JOIN c_bpartner_location ON c_bpartner.c_bpartner_id = c_bpartner_location.c_bpartner_id
		INNER JOIN c_location ON c_location.c_location_id = c_bpartner_location.c_location_id
		INNER JOIN c_country ON c_country.c_country_id = c_location.c_country_id
	WHERE (c_bpartner_location.isactive = 'Y') AND (c_bpartner_location.isbillto = 'Y');

CREATE OR REPLACE FUNCTION dc_tenders_trg() RETURNS TRIGGER AS $$ 
DECLARE 
	v_reca		RECORD; 
	v_sdate		TIMESTAMP;
BEGIN
 
	IF AD_isTriggerEnabled()='N' THEN
		IF TG_OP = 'DELETE' THEN
			RETURN OLD; 
		ELSE 
			RETURN NEW; 
		END IF; 
	END IF;
 
	v_sdate := NEW.tender_date;
	FOR v_reca IN SELECT dc_td_process_id, tender_stage, duration, ad_client_id, ad_org_id, createdby, updatedby
		FROM dc_td_process WHERE dc_td_types_id = NEW.dc_td_types_id ORDER BY tender_stage LOOP

		INSERT INTO dc_trd_process (dc_tenders_id, dc_td_process_id, duration, proposed_start, proposed_end,
			ad_client_id, ad_org_id, createdby, updatedby, dc_trd_process_id)
		VALUES (NEW.dc_tenders_id, v_reca.dc_td_process_id, v_reca.duration, v_sdate, v_sdate + v_reca.duration,
			v_reca.ad_client_id, v_reca.ad_org_id, v_reca.createdby, v_reca.updatedby, get_uuid());

		v_sdate := v_sdate + v_reca.duration + 1;
	END LOOP;

	IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
   
END; 
$$ LANGUAGE plpgsql;
 
CREATE TRIGGER dc_tenders_trg AFTER INSERT ON dc_tenders
	FOR EACH ROW EXECUTE PROCEDURE dc_tenders_trg();


CREATE OR REPLACE TRIGGER DC_TENDERS_TRG AFTER INSERT ON DC_TENDERS FOR EACH ROW
DECLARE

	TYPE RECORD IS REF CURSOR;
    v_reca RECORD;
	v_sdate	 DATE;

BEGIN
 
    IF AD_isTriggerEnabled()='N' THEN RETURN;
    END IF;
 
	v_sdate := :NEW.tender_date;
	FOR v_reca IN
      (SELECT dc_td_process_id, tender_stage, duration, ad_client_id, ad_org_id, createdby, updatedby
		FROM dc_td_process WHERE dc_td_types_id = :NEW.dc_td_types_id ORDER BY tender_stage)
    LOOP
		INSERT INTO dc_trd_process (dc_tenders_id, dc_td_process_id, duration, proposed_start, proposed_end,
			ad_client_id, ad_org_id, createdby, updatedby, dc_trd_process_id)
		VALUES (:NEW.dc_tenders_id, v_reca.dc_td_process_id, v_reca.duration, v_sdate, v_sdate + v_reca.duration,
			v_reca.ad_client_id, v_reca.ad_org_id, v_reca.createdby, v_reca.updatedby, get_uuid());

		v_sdate := v_sdate + v_reca.duration + 1;
	END LOOP; 

END DC_TENDERS_TRG;
/

CREATE OR REPLACE TRIGGER dc_proc_process_trg AFTER UPDATE ON C_BUDGETLINE FOR EACH ROW
DECLARE

	TYPE RECORD IS REF CURSOR;
    v_reca RECORD;
	v_sdate	 DATE;

BEGIN
 
    IF AD_isTriggerEnabled()='N' THEN RETURN;
    END IF;

	DELETE FROM dc_trd_process WHERE c_budgetline_id = :NEW.c_budgetline_id;

	IF (:NEW.EM_CM_TENDERSTARTDATE is not null) AND (:NEW.EM_CM_DCTDTYPES_ID is not null) THEN
	
		v_sdate := :NEW.EM_CM_TENDERSTARTDATE;
		FOR v_reca IN
		(SELECT dc_td_process_id, tender_stage, duration, ad_client_id, ad_org_id, createdby, updatedby
			FROM dc_td_process WHERE dc_td_types_id = :NEW.EM_CM_DCTDTYPES_ID ORDER BY tender_stage)
		LOOP
			INSERT INTO dc_trd_process (c_budgetline_id, dc_td_process_id, duration, proposed_start, proposed_end,
				ad_client_id, ad_org_id, createdby, updatedby, dc_trd_process_id)
			VALUES (:NEW.c_budgetline_id, v_reca.dc_td_process_id, v_reca.duration, v_sdate, v_sdate + v_reca.duration,
				v_reca.ad_client_id, v_reca.ad_org_id, v_reca.createdby, v_reca.updatedby, get_uuid());

			v_sdate := v_sdate + v_reca.duration + 1;
		END LOOP; 

	END IF;

END dc_proc_process_trg;
/





