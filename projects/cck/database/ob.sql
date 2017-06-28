

CREATE OR REPLACE TRIGGER tr_ins_payment AFTER INSERT ON C_INVOICE
	FOR EACH ROW
	DECLARE
		PRAGMA AUTONOMOUS_TRANSACTION;
	BEGIN	    
		UPDATE LICENSE_PAYMENT_HEADER@crm_link SET INVOICE_NUMBER = :NEW.DOCUMENTNO WHERE LICENSE_PAYMENT_HEADER_ID = :NEW.C_ORDER_ID;
	COMMIT;	
END;

CREATE OR REPLACE TRIGGER tr_upd_payment AFTER UPDATE ON C_INVOICE
	FOR EACH ROW
	DECLARE
		PRAGMA AUTONOMOUS_TRANSACTION;
	BEGIN	    
		IF(:OLD.OUTSTANDINGAMT != 0) AND (:NEW.OUTSTANDINGAMT = 0)THEN
			UPDATE LICENSE_PAYMENT_HEADER@crm_link SET IS_PAID = '1' WHERE LICENSE_PAYMENT_HEADER_ID = :NEW.C_ORDER_ID;
		END IF;
	COMMIT;	
END;

 
CREATE OR REPLACE TRIGGER tr_ins_erp_c_order AFTER INSERT ON license_payment_header
   FOR EACH ROW
DECLARE
    --PRAGMA AUTONOMOUS_TRANSACTION;
    cli_id    INTEGER;
BEGIN 

    SELECT client.client_id INTO cli_id
    FROM client
    INNER JOIN client_license ON client.client_id = client_license.client_id
    WHERE client_license.client_license_id = :NEW.client_license_id;

    --A. insert header       
    INSERT INTO c_order@erp_link(
                c_order_id, ad_client_id, ad_org_id, created, createdby, updated,updatedby,
                totallines, grandtotal, isactive, documentno, description,
                docstatus, docaction, c_doctype_id, c_doctypetarget_id, dateordered,
                c_bpartner_id, billto_id, c_bpartner_location_id, dateacct, DATEPROMISED,
                COPYFROM, COPYFROMPO, GENERATETEMPLATE, c_currency_id,paymentrule,
                ISDISCOUNTPRINTED,c_paymentterm_id,invoicerule,deliveryrule,freightcostrule,deliveryviarule,priorityrule,
                M_WAREHOUSE_ID,m_pricelist_id,processing,processed)

    VALUES(:NEW.license_payment_header_id,'52C09F118D974F2D880F85811017B8BF','E3F7A3865F594647A5594F01E4CCC9C6',:NEW.created,'0',:NEW.created,'0',
                0,0,'Y',:NEW.license_payment_header_id,:NEW.description,
                'DR','CO','FB11AD27869E4A7EA6D54D38F89D1135','FB11AD27869E4A7EA6D54D38F89D1135',:NEW.created,
                cli_id,cli_id,cli_id,:NEW.created,:NEW.created,
                'N','N','N','266','P',
                'N','A3522D4BAE364E7287C6F43BB616671E','I','A','I','P','5',
                '5C588DBEC3F0419BB14FB0EF01F6AA3F','3424401F65A1472C8DAC3507CC4C5DC9','N','N');
    --COMMIT;
END;
/


3.
CREATE OR REPLACE TRIGGER tr_ins_erp_c_order_line AFTER INSERT ON license_payment_line
   FOR EACH ROW
DECLARE
    --PRAGMA AUTONOMOUS_TRANSACTION;
    cli_id     INTEGER;   
BEGIN 
   
    SELECT client.client_id INTO cli_id
    FROM client
    INNER JOIN client_license ON client.client_id = client_license.client_id
    INNER JOIN license_payment_header ON client_license.client_license_id = license_payment_header.client_license_id
    WHERE license_payment_header.license_payment_header_id = :NEW.license_payment_header_id;

    --B. insert order lines
    INSERT INTO C_ORDERLINE@erp_link(
            C_ORDERLINE_ID, AD_CLIENT_ID, AD_ORG_ID,
            ISACTIVE, CREATED, CREATEDBY, UPDATED, UPDATEDBY,
            c_order_id, DESCRIPTION, line, c_bpartner_id, C_BPARTNER_LOCATION_ID,
            dateordered, DATEPROMISED, m_product_id, m_warehouse_id, c_uom_id,
            qtyordered, qtyreserved, qtydelivered, qtyinvoiced, c_currency_id,
            DISCOUNT, pricelist, priceactual, pricelimit, pricestd, LINENETAMT,
            c_tax_id)
     
        VALUES
   
            (:NEW.license_payment_line_id,'52C09F118D974F2D880F85811017B8BF','E3F7A3865F594647A5594F01E4CCC9C6',
            'Y',:NEW.created,'0',:NEW.created,'0',
            :NEW.license_payment_header_id,:NEW.description,1,cli_id,cli_id,
            :NEW.created,:NEW.created,:NEW.product_code,'5C588DBEC3F0419BB14FB0EF01F6AA3F',100,
            1, 0, 0, 0, 266,
            0,0,:NEW.amount,0, :NEW.amount, :NEW.amount,
            'FB76131C519B4EADA11662EAAFC42F23');       
        --COMMIT;
END;
/
