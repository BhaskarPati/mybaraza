create or replace TRIGGER CM_ORDERLINEBUDGET_TRG BEFORE INSERT  ON  c_orderline FOR EACH ROW DECLARE
    PRAGMA AUTONOMOUS_TRANSACTION;
    v_balance NUMBER;
    v_issotrx char(1);
BEGIN
	BEGIN
		SELECT (dc_get_budget(m_requisitionLINE.AD_ORG_ID, :NEW.M_PRODUCT_ID, SYSDATE) -
			dc_get_expense(m_requisitionLINE.AD_ORG_ID, :NEW.M_PRODUCT_ID, SYSDATE))
			INTO v_balance
		FROM m_requisitionorder INNER JOIN m_requisitionLINE ON m_requisitionorder.m_requisitionline_id = m_requisitionline.m_requisitionline_id
		WHERE (m_requisitionorder.c_orderline_id = :NEW.c_orderline_id);

      EXCEPTION WHEN NO_DATA_FOUND THEN v_balance := 0;
    END;
    
	IF (v_balance is null) then v_balance := 0; END IF;

	dbms_output.enable(5000);
	dbms_output.put_line('BASE 1010 : BALANCE ' || v_balance);
      
	IF ((v_balance < (:new.QtyOrdered * :new.PriceActual)) and (:NEW.EM_CM_ISORD='N')) THEN
         RAISE_APPLICATION_ERROR(-20999, 'Budget Amount Exceed');
    END IF;
END;
/

