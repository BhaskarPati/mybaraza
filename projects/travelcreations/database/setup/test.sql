select TICKET_AGENT,TICKET_NUMBER,TICKET_CLASS,CLASS_DESCRIPTION description, TICKET_PAX_NAME,TICKET_SECTOR_1,TICKET_SECTOR_2,TICKET_SECTOR_3,TICKET_SECTOR_4,TICKET_SECTOR_5,TICKET_FINAL_DEST FINAL_DEST, TICKET_REFERENCE_1 invoice_amount,
TICKET_LOCAL_INTER local_international,TICKET_BOOKING_CLERK, TICKET_CUSTOMER_1 customer_code, ar_name customer_name, TICKET_REFERENCE_1 INVOICE_NUMBER,TICKET_REFERENCE_AMOUNT_1 INVOICE_AMOUNT,
AR_POBOX PO_BOX, AR_ADDRESS_2 ADDRESS, AR_TELEPHONE TELEPHONE_NO, AR_EMAIL EMAIL,AR_CREDIT_DAYS CREDIT_DAYS, AR_BALANCE INVOICE_BALANCE, AR_CREATED_BY CREATED_BY, AR_CREATED_ON CREATED_ON,AR_NOTES MEMBERSHIP_NO
from id_ticket_details, id_ar_master, ID_CLASS_MASTER
where ticket_customer_1 = ar_code AND TICKET_CLASS = CLASS_CODE


CREATE OR REPLACE VIEW vw_client_statement AS
SELECT a.dr, a.cr, a.order_date::date, a.client_code, a.org_name, a.entity_id,
	(a.dr+a.sambaza_in - a.cr-a.sambaza_out) AS balance, a.sambaza_in, a.sambaza_out, a.details
	FROM ((SELECT COALESCE(vw_loyalty_points.points_amount, 0::real) + COALESCE(vw_loyalty_points.bonus, 0::real) AS dr,
		0::real AS cr, vw_loyalty_points.period AS order_date, vw_loyalty_points.client_code,
		vw_loyalty_points.org_name, vw_loyalty_points.entity_id,
		0::real as sambaza_in, 0::real as sambaza_out, ''::text as details
	FROM vw_loyalty_points)
	UNION ALL
	(SELECT 0::real AS dr, vw_orders.grand_total::real AS cr, vw_orders.order_date,
	vw_orders.client_code, vw_orders.org_name, vw_orders.entity_id,
	0::real as sambaza_in, 0::real as sambaza_out, ''::text as details
	FROM vw_orders)
	UNION ALL
	(SELECT 0::real as dr, 0::real as cr, vw_sambaza.sambaza_date,
	vw_sambaza.client_code, vw_sambaza.org_name, vw_sambaza.entity_id, COALESCE(vw_sambaza.sambaza_in,0::real) as sambaza_in,
	COALESCE(vw_sambaza.sambaza_out,0::real) as sambaza_out, vw_sambaza.details
	 FROM vw_sambaza)) a
	ORDER BY a.order_date;
