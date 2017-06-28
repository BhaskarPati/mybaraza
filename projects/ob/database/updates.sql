ALTER TABLE AAM_INVENTORY MODIFY (InventoryNo varchar2(200));
ALTER TABLE AAM_ASSET_CARD MODIFY (InventoryNo varchar2(200));

set scan off;

create or replace
PROCEDURE FINCAL_YEARPERIODS(pinstance_id IN VARCHAR2) 

AS
/*************************************************************************
  * The contents of this file are subject to the Compiere Public
  * License 1.1 ("License"); You may not use this file except in
  * compliance with the License. You may obtain a copy of the License in
  * the legal folder of your Openbravo installation.
  * Software distributed under the License is distributed on an
  * "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
  * implied. See the License for the specific language governing rights
  * and limitations under the License.
  * The Original Code is  Compiere  ERP &  Business Solution
  * The Initial Developer of the Original Code is Jorg Janke and ComPiere, Inc.
  * Portions created by Jorg Janke are Copyright (C) 1999-2001 Jorg Janke,
  * parts created by ComPiere are Copyright (C) ComPiere, Inc.;
  * All Rights Reserved.
  * Contributor(s): Openbravo SL, Enterprise Intelligence Systems
  * Contributions are Copyright (C) 2001-2009 Openbravo, S.L.
  *
  * Specifically, this derivative work is based upon the following Compiere
  * file and version.
  *************************************************************************
  * $Id: C_YearPeriods.sql,v 1.2 2002/05/22 02:48:28 jjanke Exp $
  ***
  * Title: Create missing standard periods for Year_ID
  * Description:
  ************************************************************************/
  -- Parameter
  TYPE RECORD IS REF CURSOR;
    Cur_Parameter RECORD;
    v_Year_ID VARCHAR2(32);
    --
    v_NextNo VARCHAR2(32);
    v_MonthNo NUMBER;
    v_StartDate DATE;
    Test NUMBER;
    v_ResultStr VARCHAR(300) ;
    --  C_Year Variables
    v_Client_ID VARCHAR2(32);
    v_Org_ID VARCHAR2(32);
    v_Calendar_ID VARCHAR2(32);
    v_Year_Str VARCHAR(20) ;
    v_Start_Day NUMBER;
    v_Start_Month NUMBER;
    v_Start_Year NUMBER;
    v_User_ID VARCHAR2(32);
    v_year_num NUMBER;
    v_Language VARCHAR(6);
  BEGIN
    --  Update AD_PInstance
    --  DBMS_OUTPUT.PUT_LINE('Updating PInstance - Processing');
    v_ResultStr:='PInstanceNotFound';
    AD_UPDATE_PINSTANCE(PInstance_ID, NULL, 'Y', NULL, NULL) ;
  BEGIN --BODY
    -- Get Parameters
    v_ResultStr:='ReadingParameters';
    FOR Cur_Parameter IN
      (SELECT i.Record_ID,
        p.ParameterName,
        p.P_String,
        p.P_Number,
        p.P_Date
      FROM AD_PInstance i
      LEFT JOIN AD_PInstance_Para p
        ON i.AD_PInstance_ID=p.AD_PInstance_ID
      WHERE i.AD_PInstance_ID=PInstance_ID
      ORDER BY p.SeqNo
      )
    LOOP
      v_Year_ID:=Cur_Parameter.Record_ID;
      IF(Cur_Parameter.ParameterName='Start_Year') THEN
          v_Start_Year:=Cur_Parameter.P_Number;
          DBMS_OUTPUT.PUT_LINE('  Start Year=' || v_Start_Year) ;
      END IF;

    END LOOP; -- Get Parameter
    DBMS_OUTPUT.PUT_LINE('  Record_ID=' || v_Year_ID) ;
    --  Get C_Year Record
    DBMS_OUTPUT.PUT_LINE('Get Year info') ;
    v_ResultStr:='YearNotFound';
    SELECT C_Year.AD_Client_ID, C_Year.AD_Org_ID, C_Year.C_Calendar_ID, Year,  C_Year.UpdatedBy, Em_FinCal_StartDay, Em_FinCal_StartMonth
        INTO v_Client_ID, v_Org_ID,v_Calendar_ID, v_Year_Str, v_User_ID, v_Start_Day, v_Start_Month
        FROM C_Year
           INNER JOIN C_Calendar on C_Calendar.C_Calendar_ID=C_Year.C_Calendar_ID
        WHERE C_Year_ID=v_Year_ID;
    -- Check the format
    DBMS_OUTPUT.PUT_LINE('Checking format') ;
    v_ResultStr:='Year not numeric: '||v_Year_Str;
    BEGIN
    SELECT TO_NUMBER(v_Year_Str) INTO v_year_num FROM DUAL;
     -- Postgres hack
     IF (v_year_num IS NULL OR v_year_num<=0) THEN
      RAISE_APPLICATION_ERROR(-20000, '@NotValidNumber@');
    END IF;
    EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20000, '@NotValidNumber@');
    END;
    --  Start Date
    DBMS_OUTPUT.PUT_LINE('Calculating start date') ;
    v_ResultStr:='Year not numeric: '||v_Year_Str;
    IF (v_Start_Year is null) THEN
         SELECT SUBSTR(TO_CHAR(v_year_num), 1, 4) into v_Start_Year FROM DUAL;
    END IF;
    SELECT TO_DATE(v_Start_Day||'/'|| v_Start_Month || '/'||v_Start_Year, 'DD/MM/YYYY') INTO v_StartDate FROM DUAL;
    DBMS_OUTPUT.PUT_LINE('Start: '||v_StartDate) ;
    -- Determine client language
    SELECT ad_language INTO v_Language FROM AD_Client WHERE AD_Client_ID = v_Client_ID;
    -- Loop to all months and add missing periods
    FOR v_MonthNo IN 1..12
    LOOP
      --  Do we have the month already:1
      --      DBMS_OUTPUT.PUT_LINE('Checking Month No: '||v_MonthNo);
      v_ResultStr:='Checking Month '||v_MonthNo;
      SELECT MAX(PeriodNo)
      INTO Test
      FROM C_Period
      WHERE C_Year_ID=v_Year_ID
        AND PeriodNo=v_MonthNo;
      IF Test IS NULL THEN
        -- get new v_NextNo
        AD_Sequence_Next('C_Period', v_Year_ID, v_NextNo) ;
        --          DBMS_OUTPUT.PUT_LINE('Adding Period ID: '||v_NextNo);
        INSERT
        INTO C_Period
          (
            C_Period_ID, AD_Client_ID, AD_Org_ID, IsActive,
            Created, CreatedBy, Updated, UpdatedBy,
            C_Year_ID, PeriodNo, StartDate, PeriodType,
            Name
          )
          VALUES
          (
            v_NextNo, v_Client_ID, v_Org_ID, 'Y',
            now(), v_User_ID, now(), v_User_ID,
            v_Year_ID, v_MonthNo, TO_DATE(ADD_MONTHS(v_StartDate, v_MonthNo-1)), 'S',
	        (SELECT (v_Start_Year + TRUNC((v_Start_Month-2+v_MonthNo)/12)) || '-' || coalesce(t.name, m.name)
	                FROM AD_MONTH m
	                LEFT JOIN ad_month_trl t on (m.ad_month_id =t.ad_month_id and t.ad_language=v_Language)
	                WHERE TO_NUMBER(m.value) = (mod((v_Start_Month-2+v_MonthNo),12) + 1)
            )
           );
        DBMS_OUTPUT.PUT_LINE('Month Added') ;
      END IF;
    END LOOP;

    -- Update the end dates to work around c_period_trg2() forcing end date to the start of the next month
    UPDATE C_Period SET EndDate =  ADD_MONTHS(StartDate, 1) -1 WHERE C_Year_ID = v_Year_ID and AD_Client_ID = v_Client_ID;

    --  Update AD_PInstance
    --<<END_PROCEDURE>>
    --  DBMS_OUTPUT.PUT_LINE('Updating PInstance - Finished');
    AD_UPDATE_PINSTANCE(PInstance_ID, NULL, 'N', 1, NULL) ;
    RETURN;
  END; --BODY
EXCEPTION
WHEN OTHERS THEN
  --      DBMS_OUTPUT.PUT_LINE('No Data Found Exception');
  v_ResultStr:= '@ERROR=' || SQLERRM;
  AD_UPDATE_PINSTANCE(PInstance_ID, NULL, 'N', 0, v_ResultStr) ;
  RETURN;
END FINCAL_YEARPERIODS
;
/

create or replace
TRIGGER C_PERIOD_TRG2
BEFORE INSERT OR UPDATE OR DELETE
ON C_PERIOD FOR EACH ROW
DECLARE
	pragma autonomous_transaction;
    /*************************************************************************
    * The contents of this file are subject to the Compiere Public
    * License 1.1 ("License"); You may not use this file except in
    * compliance with the License. You may obtain a copy of the License in
    * the legal folder of your Openbravo installation.
    * Software distributed under the License is distributed on an
    * "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
    * implied. See the License for the specific language governing rights
    * and limitations under the License.
    * The Original Code is  Compiere  ERP &  Business Solution
    * The Initial Developer of the Original Code is Jorg Janke and ComPiere, Inc.
    * Portions created by Jorg Janke are Copyright (C) 1999-2001 Jorg Janke,
    * parts created by ComPiere are Copyright (C) ComPiere, Inc.;
    * All Rights Reserved.
    * Contributor(s): Openbravo SLU
    * Contributions are Copyright (C) 2001-2011 Openbravo, S.L.U.
    *
    * Specifically, this derivative work is based upon the following Compiere
    * file and version.
    *************************************************************************
    * Calculate End Date
    */
    v_DateNull DATE := TO_DATE('01-01-1900','DD-MM-YYYY');
    V_COUNT NUMBER:= 0;

BEGIN

    IF AD_isTriggerEnabled()='N' THEN RETURN;
    END IF;

   IF(UPDATING) THEN
     IF COALESCE(:old.StartDate, v_DateNull) <> COALESCE(:NEW.StartDate, v_DateNull) THEN
        IF (:new.EndDate IS NULL) THEN
           :new.EndDate:= ADD_MONTHS(TRUNC(:new.StartDate, 'MM'), 1) -1;
	END If;
     END IF;
   END IF;

   IF(INSERTING) THEN
	IF (:new.EndDate IS NULL) THEN
           :new.EndDate:= ADD_MONTHS(TRUNC(:new.StartDate, 'MM'), 1) -1;
	END If;
   END IF;

   -- Validating dates period
   IF(UPDATING OR INSERTING) THEN

	IF (INSERTING AND :NEW.PERIODTYPE = 'C_YEARPERIOD') THEN
		-- Creating periods from procedure, no need to check dates
		:NEW.PERIODTYPE := 'S';
	ELSE
		IF (:NEW.STARTDATE > :NEW.ENDDATE) THEN
			RAISE_APPLICATION_ERROR(-20000, '@DatesWrong@');
		END IF;
		SELECT COUNT(*) INTO V_COUNT FROM C_PERIOD WHERE C_PERIOD_ID <> :NEW.C_PERIOD_ID AND C_YEAR_ID = :NEW.C_YEAR_ID AND :NEW.STARTDATE <= ENDDATE AND :NEW.ENDDATE >= STARTDATE;
		IF (V_COUNT > 0) THEN
			RAISE_APPLICATION_ERROR(-20000, '@DatesOverlapped@');
		END IF;
	END IF;
   END IF;

   IF DELETING THEN
        DELETE FROM C_PeriodControl_log
		WHERE periodno=:old.C_Period_ID;
		COMMIT;

		DELETE FROM C_PeriodControl
		WHERE C_Period_ID=:old.C_Period_ID;
		COMMIT;
   END IF;

END C_PERIOD_TRG2
;
/


create or replace
TRIGGER "ERPDBUSER"."AD_MODULE_DEPENDENCY_MOD_TRG" 
BEFORE INSERT OR UPDATE OR DELETE
ON AD_MODULE_DEPENDENCY FOR EACH ROW
DECLARE
	pragma autonomous_transaction;
/*************************************************************************
* The contents of this file are subject to the Openbravo  Public  License
* Version  1.1  (the  "License"),  being   the  Mozilla   Public  License
* Version 1.1  with a permitted attribution clause; you may not  use this
* file except in compliance with the License. You  may  obtain  a copy of
* the License at http://www.openbravo.com/legal/license.html
* Software distributed under the License  is  distributed  on  an "AS IS"
* basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
* License for the specific  language  governing  rights  and  limitations
* under the License.
* The Original Code is Openbravo ERP.
* The Initial Developer of the Original Code is Openbravo SLU
* All portions are Copyright (C) 2008-2010 Openbravo SLU
* All Rights Reserved.
* Contributor(s):  ______________________________________.
************************************************************************/
  devTemplate NUMBER;
  devModule   CHAR(1);
  cuerrentID  VARCHAR2(32);
  cuerrentModuleID  VARCHAR2(32);
    
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN RETURN;
    END IF;


  SELECT COUNT(*)
    INTO devTemplate
    FROM AD_MODULE
   WHERE IsInDevelopment = 'Y'
     AND Type = 'T';
     
  IF (UPDATING OR INSERTING) THEN
    cuerrentID := :new.AD_Module_Dependency_ID;
    cuerrentModuleID := :new.AD_Module_ID;
  ELSE
    cuerrentID := :old.AD_Module_Dependency_ID;
    cuerrentModuleID := :old.AD_Module_ID;
  END IF;
  
  SELECT M.IsInDevelopment
    INTO devModule
    FROM AD_MODULE M
   WHERE M.AD_MODULE_ID = cuerrentModuleID;
     
  IF (UPDATING AND devTemplate=0 AND devModule='N') THEN
    IF (
        COALESCE(:NEW.AD_Client_ID , '.') != COALESCE(:OLD.AD_Client_ID , '.') OR
        COALESCE(:NEW.AD_Org_ID , '.') != COALESCE(:OLD.AD_Org_ID , '.') OR
        COALESCE(:NEW.IsActive , '.') != COALESCE(:OLD.IsActive , '.') OR
        COALESCE(:NEW.AD_Module_ID , '.') != COALESCE(:OLD.AD_Module_ID , '.') OR
        COALESCE(:NEW.AD_Dependent_Module_ID , '.') != COALESCE(:OLD.AD_Dependent_Module_ID , '.') OR
        COALESCE(:NEW.StartVersion , '.') != COALESCE(:OLD.StartVersion , '.') OR
        COALESCE(:NEW.EndVersion , '.') != COALESCE(:OLD.EndVersion , '.') OR
        COALESCE(:NEW.IsIncluded , '.') != COALESCE(:OLD.IsIncluded , '.') OR
        COALESCE(:NEW.Dependency_Enforcement , '.') != COALESCE(:OLD.Dependency_Enforcement , '.') OR
        COALESCE(:NEW.User_Editable_Enforcement , '.') != COALESCE(:OLD.User_Editable_Enforcement , '.')) THEN
      RAISE_APPLICATION_ERROR(-20000, '@20532@');
    END IF;
  END IF;
  
  IF (INSERTING AND devModule='N') THEN
    RAISE_APPLICATION_ERROR(-20000, '@20533@');
  END IF;
  
  IF (DELETING AND devModule='N') THEN
    RAISE_APPLICATION_ERROR(-20000, '@20533@');
  END IF;
  
  --Check the only updated column is instanceEnforcement. In this case maitin updated
  --column as it was to prevent changes detection when trying to update database
  IF (UPDATING) THEN
    IF (COALESCE(:NEW.ISACTIVE                 ,'.') = COALESCE(:OLD.ISACTIVE                 ,'.') AND
        COALESCE(:NEW.AD_MODULE_ID             ,'.') = COALESCE(:OLD.AD_MODULE_ID             ,'.') AND
        COALESCE(:NEW.AD_DEPENDENT_MODULE_ID   ,'.') = COALESCE(:OLD.AD_DEPENDENT_MODULE_ID   ,'.') AND
        COALESCE(:NEW.STARTVERSION             ,'.') = COALESCE(:OLD.STARTVERSION             ,'.') AND
        COALESCE(:NEW.ENDVERSION               ,'.') = COALESCE(:OLD.ENDVERSION               ,'.') AND
        COALESCE(:NEW.ISINCLUDED               ,'.') = COALESCE(:OLD.ISINCLUDED               ,'.') AND
        COALESCE(:NEW.DEPENDANT_MODULE_NAME    ,'.') = COALESCE(:OLD.DEPENDANT_MODULE_NAME    ,'.') AND
        COALESCE(:NEW.DEPENDENCY_ENFORCEMENT   ,'.') = COALESCE(:OLD.DEPENDENCY_ENFORCEMENT   ,'.') AND
        COALESCE(:NEW.USER_EDITABLE_ENFORCEMENT,'.') = COALESCE(:OLD.USER_EDITABLE_ENFORCEMENT,'.') AND                        
        COALESCE(:NEW.INSTANCE_ENFORCEMENT,'.') !=   COALESCE(:OLD.INSTANCE_ENFORCEMENT,'.'))  THEN
      :NEW.UPDATED := :OLD.UPDATED;
    END IF;
  END IF;
END AD_MODULE_DEPENDENCY_MOD_TRG
;

create or replace
PROCEDURE AD_UPDATE_ACCESS 

AS
/*************************************************************************
* The contents of this file are subject to the Openbravo  Public  License
* Version  1.1  (the  "License"),  being   the  Mozilla   Public  License
* Version 1.1  with a permitted attribution clause; you may not  use this
* file except in compliance with the License. You  may  obtain  a copy of
* the License at http://www.openbravo.com/legal/license.html
* Software distributed under the License  is  distributed  on  an "AS IS"
* basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
* License for the specific  language  governing  rights  and  limitations
* under the License.
* The Original Code is Openbravo ERP.
* The Initial Developer of the Original Code is Openbravo SLU
* All portions are Copyright (C) 2007-2012 Openbravo SLU
* All Rights Reserved.
* Contributor(s):  ______________________________________.
************************************************************************/

 v_ExtensionPointID varchar2(32) := '8261F79453B64AC7998873A9F81A1E5A';
 v_count NUMBER;
BEGIN
--AD_FORM_ACCESS
  INSERT INTO AD_Form_Access
    (
      AD_Form_Access_ID, AD_Form_ID, AD_Role_ID, AD_Client_ID,
      AD_Org_ID, IsActive, Created,
      CreatedBy, Updated, UpdatedBy, IsReadWrite
    )
  SELECT get_uuid(), AD_FORM.AD_FORM_ID, AD_ROLE.AD_ROLE_ID, AD_ROLE.AD_CLIENT_ID,
    AD_ROLE.AD_ORG_ID, 'Y', now(),
    '0', now(), '0', 'Y'
  FROM AD_FORM, AD_ROLE
  WHERE AD_ROLE.ISMANUAL = 'N'
  AND AD_FORM.IsActive='Y'
    AND (
      (AD_ROLE.USERLEVEL = 'S' AND AD_FORM.ACCESSLEVEL IN ('4','7','6'))
      OR
      (AD_ROLE.USERLEVEL IN (' CO', ' C') AND AD_FORM.ACCESSLEVEL IN ('7','6','3','1'))
      OR
      (AD_ROLE.USERLEVEL = '  O' AND AD_FORM.ACCESSLEVEL IN ('3','1','7'))
    )
    AND (AD_ROLE.ISADVANCED = 'Y' OR AD_FORM.ISADVANCEDFEATURE = 'N')
    AND NOT EXISTS (SELECT 1
                     FROM AD_FORM_ACCESS
                    WHERE AD_FORM_ID = AD_FORM.AD_FORM_ID
                      AND AD_ROLE_ID = AD_ROLE.AD_ROLE_ID);

   DELETE FROM AD_Form_Access a 
    WHERE EXISTS (SELECT 1
                    FROM AD_Role r, AD_Form F
                   WHERE r.IsAdvanced = 'N' 
                     AND f.IsAdvancedFeature = 'Y' 
                     AND r.AD_Role_ID = a.AD_Role_ID
                     AND f.ad_form_ID = a.ad_form_id
                     AND r.isManual = 'N');

--AD_PROCESS_ACCESS
  INSERT INTO AD_Process_Access
    (AD_Process_Access_ID, AD_Process_ID, AD_Role_ID, AD_Client_ID,
     AD_Org_ID, IsActive, Created,
     CreatedBy, Updated, UpdatedBy, IsReadWrite)
  SELECT get_uuid(), AD_PROCESS.AD_PROCESS_ID, AD_ROLE.AD_ROLE_ID, AD_ROLE.AD_CLIENT_ID,
    AD_ROLE.AD_ORG_ID, 'Y', now(),
    '0', now(), '0', 'Y'
  FROM AD_PROCESS, AD_ROLE
  WHERE AD_ROLE.ISMANUAL = 'N'
  AND AD_PROCESS.IsActive='Y'
    AND (
      (AD_ROLE.USERLEVEL = 'S' AND AD_PROCESS.ACCESSLEVEL IN ('4','7','6'))
      OR
      (AD_ROLE.USERLEVEL IN (' CO', ' C') AND AD_PROCESS.ACCESSLEVEL IN ('7','6','3','1'))
      OR
      (AD_ROLE.USERLEVEL = '  O' AND AD_PROCESS.ACCESSLEVEL IN ('3','1','7'))
    )
    AND (AD_ROLE.ISADVANCED = 'Y' OR AD_PROCESS.ISADVANCEDFEATURE = 'N')
    AND NOT EXISTS (SELECT 1 
                      FROM AD_PROCESS_ACCESS
                     WHERE AD_PROCESS_ID = AD_PROCESS.AD_PROCESS_ID
                       AND AD_ROLE_ID    = AD_ROLE.AD_ROLE_ID);

   DELETE FROM AD_Process_Access a 
    WHERE EXISTS (SELECT 1
                    FROM AD_Role r, AD_Process p
                   WHERE r.IsAdvanced = 'N' 
                     AND p.IsAdvancedFeature = 'Y' 
                     AND r.AD_Role_ID = a.AD_Role_ID
                     AND p.ad_Process_ID = a.ad_Process_id
										 AND r.isManual = 'N');
 --Add org 0 to role 0                
 INSERT INTO AD_Role_OrgAccess
    (
       AD_Role_OrgAccess_ID, AD_Role_ID, AD_Client_ID, AD_Org_ID,
      IsActive, Created, CreatedBy,
      Updated, UpdatedBy, is_org_admin
    )
  SELECT get_uuid(), AD_ROLE.AD_ROLE_ID, AD_ORG.AD_CLIENT_ID, AD_ORG.AD_ORG_ID,
    'Y', now(), '0',
    now(), '0', 'N'
  FROM AD_ROLE, AD_ORG
  WHERE AD_ROLE.AD_ROLE_ID = '0'
    AND AD_ROLE.AD_CLIENT_ID = AD_ORG.AD_CLIENT_ID
    AND AD_ORG.AD_ORG_ID ='0'
    AND NOT EXISTS (SELECT 1 FROM AD_ROLE_ORGACCESS
                    WHERE AD_ROLE_ID = AD_ROLE.AD_ROLE_ID
                      AND AD_ORG_ID = AD_ORG.AD_ORG_ID);                      
                      

--AD_WINDOW_ACCESS
  INSERT INTO aD_Window_Access
    (
      aD_Window_Access_ID, AD_Window_ID, AD_Role_ID, AD_Client_ID,
      AD_Org_ID, IsActive, Created,
      CreatedBy, Updated, UpdatedBy, IsReadWrite
    )
  SELECT get_uuid(), a.AD_WINDOW_ID, a.AD_ROLE_ID, a.AD_CLIENT_ID, a.AD_ORG_ID,
	'Y', now(), '0', now(), '0', 'Y'
  FROM (SELECT DISTINCT AD_WINDOW.AD_WINDOW_ID, AD_ROLE.AD_ROLE_ID, AD_ROLE.AD_CLIENT_ID, AD_ROLE.AD_ORG_ID
  FROM AD_WINDOW, AD_ROLE, AD_TAB, AD_TABLE
  WHERE AD_ROLE.ISMANUAL = 'N'
  AND AD_WINDOW.IsActive='Y'
    AND AD_WINDOW.AD_WINDOW_ID = AD_TAB.AD_WINDOW_ID
    AND AD_TAB.AD_TABLE_ID = AD_TABLE.AD_TABLE_ID
    AND (
      (AD_ROLE.USERLEVEL = 'S' AND AD_TABLE.ACCESSLEVEL IN ('4','7','6'))
      OR
      (AD_ROLE.USERLEVEL IN (' CO', ' C') AND AD_TABLE.ACCESSLEVEL IN ('7','6','3','1'))
      OR
      (AD_ROLE.USERLEVEL = '  O' AND AD_TABLE.ACCESSLEVEL IN ('3','1','7'))
    )
    AND AD_TAB.SEQNO = (SELECT MIN(SEQNO) FROM AD_TAB t WHERE t.AD_WINDOW_ID = AD_WINDOW.AD_WINDOW_ID)
    AND (AD_ROLE.ISADVANCED = 'Y' OR AD_WINDOW.ISADVANCEDFEATURE = 'N')
    AND NOT EXISTS (SELECT 1 
                       FROM AD_WINDOW_ACCESS
                      WHERE AD_WINDOW_ID = AD_WINDOW.AD_WINDOW_ID
                        AND AD_ROLE_ID = AD_ROLE.AD_ROLE_ID)) a;

   DELETE FROM AD_Window_Access a 
    WHERE EXISTS (SELECT 1
                    FROM AD_Role r, AD_Window w
                   WHERE r.IsAdvanced = 'N' 
                     AND w.IsAdvancedFeature = 'Y' 
                     AND r.AD_Role_ID = a.AD_Role_ID
                     AND w.ad_Window_ID = a.ad_Window_ID
                     AND r.isManual = 'N');

  --Add role 0 to user 100 (Openbravo)
  INSERT INTO AD_USER_ROLES
    (AD_USER_ROLES_ID , AD_USER_ID , AD_ROLE_ID, 
     AD_CLIENT_ID     , AD_ORG_ID  , ISACTIVE  , 
     CREATED          , CREATEDBY  , UPDATED   , 
     UPDATEDBY, is_role_admin) 
    SELECT get_uuid(), AD_USER_ID, '0',
           '0', '0', 'Y',
           now(), '0', now(),
           '0', 'Y'
      FROM AD_USER
    WHERE AD_USER_ID IN ('0', '100')
    AND NOT EXISTS (SELECT 1
                    FROM AD_USER_ROLES
                    WHERE AD_USER_ID = AD_USER.AD_USER_ID
                      AND AD_ROLE_ID = '0');
                      
 
  --Extension point to add access to additional tables defined within modules 
  SELECT count(*) INTO v_count
  FROM DUAL
  WHERE EXISTS (SELECT 1 FROM ad_ep_procedures WHERE ad_extension_points_id = v_ExtensionPointID);
  
  IF (v_count != 0) THEN
   AD_EXTENSION_POINT_HANDLER(get_uuid(), v_ExtensionPointID);
  END IF;
END AD_UPDATE_ACCESS
;
 

create or replace
FUNCTION OPFIFO_GET_FIFOCOST_AT(p_product_id IN VARCHAR2, p_configuration_id IN VARCHAR2, p_date IN DATE, p_dateat_qty IN NUMBER) RETURN NUMBER

AS
/*
  ************************************************************************************
  * Copyright (C) 2011 Openia Srl

  * Licensed under the Openbravo Commercial License version 1.0
  * You may obtain a copy of the License at http://www.openbravo.com/legal/obcl.html
  ************************************************************************************

  Computes FIFO cost for given product, at a given date, for a given configuration.
  Requires the product onhand quantity at date p_date. Consider all purchase and completed
  invoices belonging to an organization listed in given configuration.
  Skip invoice lines with em_opfifo_isincluded='N'.
*/

  TYPE RECORD IS REF CURSOR;

  v_remaining NUMBER;
  v_fifocost NUMBER;
  v_curr_line RECORD;
  v_result RECORD;

BEGIN

  v_remaining := p_dateat_qty ;
  v_fifocost := 0 ;
  
  -- Consider all purchase invoice lines until given date, regarding organizations
  -- in given configuration, that are marked for FIFO accounting.
  -- Also skip non-completed invoices.
  FOR v_curr_line IN
    (SELECT l.qtyinvoiced, l.priceactual
     FROM c_invoice i
     INNER JOIN c_invoiceline l ON i.c_invoice_id = l.c_invoice_id
     WHERE i.issotrx = 'N'
       AND CAST(i.dateinvoiced AS date) <= CAST(p_date AS date)
       AND i.docstatus = 'CO'
       AND l.m_product_id = p_product_id
       AND l.em_opfifo_isincluded = 'Y'
       AND i.ad_org_id IN
         (SELECT inv_org_id
          FROM opfifo_config_org
          WHERE opfifo_config_id = p_configuration_id
            AND isactive = 'Y')
       AND i.isactive = 'Y'
       AND l.isactive = 'Y'
     ORDER BY i.dateinvoiced DESC)
  LOOP

    IF v_curr_line.qtyinvoiced >= v_remaining THEN
      v_fifocost := v_fifocost + (v_curr_line.priceactual * v_remaining) ;
      v_remaining := 0 ;
      EXIT ; -- exit loop here
    ELSE
      v_fifocost := v_fifocost + (v_curr_line.priceactual * v_curr_line.qtyinvoiced) ;
      v_remaining := v_remaining - v_curr_line.qtyinvoiced ;
    END IF ;
 
  END LOOP;

  IF p_dateat_qty = v_remaining THEN
    RETURN null ; -- No FIFO cost available
  ELSE
    RETURN v_fifocost / (p_dateat_qty-v_remaining) ;
  END IF ;
END OPFIFO_GET_FIFOCOST_AT
;
 

create or replace
PROCEDURE OPFIFO_COMPUTE_ALL_COSTS_AT(p_client_id IN VARCHAR2, p_org_id IN VARCHAR2, p_user_id IN VARCHAR2, p_configuration_id IN VARCHAR2, p_date IN DATE) 

AS
/*
  ************************************************************************************
  * Copyright (C) 2011 Openia Srl

  * Licensed under the Openbravo Commercial License version 1.0
  * You may obtain a copy of the License at http://www.openbravo.com/legal/obcl.html
  ************************************************************************************

  Computes FIFO cost for each product found in a locator belonging to a warehouse listed
  in given configuration. Skip locators with em_opfifo_isexcluded='Y'. Refers calculation
  at the given date. Uses opfifo_get_fifocost_at. Writes results in opfifo_productcost,
  overwriting old calculations if needed.
*/

  TYPE RECORD IS REF CURSOR;

  v_curr_prod RECORD ;
  v_delta NUMBER ;
  v_dateat_qty NUMBER ;
  v_fifocost NUMBER ;
  
BEGIN

  -- Delete old computations if present
  DELETE FROM opfifo_productcost
  WHERE opfifo_config_id = p_configuration_id
    AND CAST(computing_date AS date) = CAST(p_date AS date);
      
  -- For each product found in a warehouse belonging to the current FIFO configuration
  FOR v_curr_prod IN

    -- Get product id and total actual quantity from all locators in selected warehouses
    -- Filter locators by em_opfifo_isexcluded.
    (SELECT s.m_product_id, COALESCE(SUM(s.qtyonhand),0) as actual_qty
    FROM m_storage_detail s
    INNER JOIN m_locator l ON l.m_locator_id = s.m_locator_id
    WHERE l.em_opfifo_isexcluded = 'N'
      AND l.m_warehouse_id IN
        (SELECT m_warehouse_id
         FROM opfifo_config_war
         WHERE opfifo_config_id = p_configuration_id
           AND isactive = 'Y')
      AND s.isactive = 'Y'
      AND l.isactive = 'Y'
    GROUP BY s.m_product_id)

  LOOP

    -- Roll back stock movements, regarding current product in selected locators,
    -- from now until the given date, to get the desired quantity
    SELECT COALESCE(SUM(t.movementqty),0) INTO v_delta
    FROM m_transaction t
    INNER JOIN m_locator l ON t.m_locator_id = l.m_locator_id
    WHERE t.m_product_id = v_curr_prod.m_product_id
      AND l.em_opfifo_isexcluded = 'N'
      AND l.m_warehouse_id IN
        (SELECT m_warehouse_id
         FROM opfifo_config_war
         WHERE opfifo_config_id = p_configuration_id
           AND isactive = 'Y')
      AND CAST(t.movementDate AS date) > CAST(p_date AS date)
      AND t.isactive = 'Y'
      AND l.isactive = 'Y' ;

    v_dateat_qty := (v_curr_prod.actual_qty - v_delta) ;
    
    -- Compute FIFO cost
    v_fifocost := opfifo_get_fifocost_at( v_curr_prod.m_product_id, p_configuration_id,
      p_date, v_dateat_qty ) ;
  
    -- Insert computed FIFO cost into opfifo_productcost
    IF v_fifocost is not null THEN
      INSERT INTO opfifo_productcost(
            opfifo_productcost_id, ad_client_id, ad_org_id, isactive, created,
            createdby, updated, updatedby,
            m_product_id, opfifo_config_id, computing_date,
            cost, quantity, totalcost, historical)
      VALUES (get_uuid(), p_client_id, p_org_id, 'Y', now(),
            p_user_id, now(), p_user_id,
            v_curr_prod.m_product_id, p_configuration_id, p_date,
            v_fifocost, v_dateat_qty, v_fifocost*v_dateat_qty, 'N');
    END IF ;
          
  END LOOP ;
END OPFIFO_COMPUTE_ALL_COSTS_AT
;
 
create or replace
PROCEDURE OPFIFO_COMPUTE_COSTS_PROC(p_pinstance_id IN VARCHAR2) 

AS
/*
  ************************************************************************************
  * Copyright (C) 2011 Openia Srl

  * Licensed under the Openbravo Commercial License version 1.0
  * You may obtain a copy of the License at http://www.openbravo.com/legal/obcl.html
  ************************************************************************************

  Computes FIFO costs for a given configuration/date. Reads parameters from
  ad_pinstance_para and calls opfifo_compute_all_costs_at.
  This function is called by Openbravo 'Compute FIFO cost' process.
*/

  TYPE RECORD IS REF CURSOR;

  v_ResultStr VARCHAR(2000) := '' ; -- The step the stored procedure is in
  r_params RECORD ;

  v_configuration_id VARCHAR(32) ;
  v_computing_date DATE ;

BEGIN

  AD_UPDATE_PINSTANCE( p_PInstance_ID, NULL, 'Y', NULL, NULL ) ;

  v_ResultStr := 'ReadingParameters' ;

  SELECT p_string INTO v_configuration_id
  FROM ad_pinstance_para
  WHERE ad_pinstance_id = p_pinstance_id
    AND parametername = 'configuration_id' ;

  SELECT p_date INTO v_computing_date
  FROM ad_pinstance_para
  WHERE ad_pinstance_id = p_pinstance_id
    AND parametername = 'computing_date' ;

  v_ResultStr := 'Computing FIFO costs' ;
  FOR r_params IN
  	(SELECT p.ad_client_id, p.ad_org_id, p.ad_user_id
	  FROM ad_pinstance p
	  WHERE p.ad_pinstance_id = p_pinstance_id)
  LOOP

	  OPFIFO_COMPUTE_ALL_COSTS_AT( r_params.ad_client_id, r_params.ad_org_id,
		r_params.ad_user_id, v_configuration_id, v_computing_date ) ;
  END LOOP;

  v_ResultStr := 'Ok' ;

  AD_UPDATE_PINSTANCE( p_PInstance_ID, NULL, 'N', 1, v_ResultStr ) ;
  RETURN;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(v_ResultStr) ;
    v_ResultStr := '@ERROR=' || SQLERRM ;
    DBMS_OUTPUT.PUT_LINE(v_ResultStr) ;
    AD_UPDATE_PINSTANCE( p_PInstance_ID, NULL, 'N', 0, v_ResultStr ) ;
    RETURN ;
END OPFIFO_COMPUTE_COSTS_PROC
;

ALTER TABLE DC_TRD_SUPPLIERS ALTER COLUMN C_BPARTNER_ID    VARCHAR2(32 BYTE);

create or replace TRIGGER CM_ORDERLINEBUDGET_TRG BEFORE INSERT  ON  c_orderline FOR EACH ROW DECLARE
	v_balance NUMBER;
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	BEGIN
		SELECT (dc_get_budget(m_requisitionLINE.AD_ORG_ID, C_ORDERLINE.M_PRODUCT_ID, C_ORDER.DATEACCT) -
			dc_get_expense(m_requisitionLINE.AD_ORG_ID, C_ORDERLINE.M_PRODUCT_ID, C_ORDER.DATEACCT))
		INTO v_balance
		FROM C_ORDERLINE INNER JOIN c_order on c_order.c_order_id=c_orderline.c_order_id
		INNER JOIN m_requisitionorder ON C_ORDERLINE.C_ORDERLINE_ID = M_REQUISITIONORDER.C_ORDERLINE_ID
		INNER JOIN m_requisitionLINE ON M_REQUISITIONORDER.M_REQUISITIONLINE_ID = M_REQUISITIONLINE.M_REQUISITIONLINE_ID
		WHERE (C_ORDERLINE.C_ORDERLINE_ID = :NEW.C_ORDERLINE_ID);

		EXCEPTION WHEN NO_DATA_FOUND THEN v_balance := 0;
	END;
 
	IF (v_balance < 0) THEN
		RAISE_APPLICATION_ERROR(-20999, 'Budget Amount Exceed');
	END IF;
	COMMIT;

	RETURN;
END;


