--LINKS TO OTHER DBs
/*
CREATE DATABASE LINK erplink
   	CONNECT TO openbr IDENTIFIED BY Imis2goke    
   	 USING '172.100.3.22:1530/imiserp';

CREATE DATABASE LINK oldfsmlink
   	CONNECT TO cck IDENTIFIED BY Imis2goke    
   	 USING '172.100.3.22:1522/crm';

CREATE DATABASE LINK t_erp_link
   CONNECT TO openbr IDENTIFIED BY Imis2goke
   USING     
    '(DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = imis-training.cck.go.ke)(PORT = 1540))
        (CONNECT_DATA =
          (SERVER = SHARED)
          (SERVICE_NAME = terp.cck)
        )
      )';
*/


DROP DATABASE LINK erp_link;
CREATE DATABASE LINK erp_link
   	CONNECT TO erpdbuser IDENTIFIED BY Imis2goke    
   	 USING '172.100.3.30:1542/timis.cck';

--AT ERP SIDE
CREATE DATABASE LINK crm_link
   	CONNECT TO cck IDENTIFIED BY Imis2goke    
   	 USING '172.100.3.30:1541/tcrm.cck';

--ERP SIDE
CREATE OR REPLACE TRIGGER DC_ins_payment_TRG AFTER INSERT ON C_INVOICE
    FOR EACH ROW
    DECLARE
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN       
        UPDATE LICENSE_PAYMENT_HEADER@crm_link SET INVOICE_NUMBER = :NEW.DOCUMENTNO,INVOICE_DATE = :NEW.CREATED WHERE LICENSE_PAYMENT_HEADER_ID = :NEW.C_ORDER_ID;
		COMMIT;   
END;
/

--ERP SIDE
CREATE OR REPLACE TRIGGER DC_upd_payment_TRG AFTER UPDATE ON C_INVOICE
    FOR EACH ROW
    DECLARE
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN       
        IF(:NEW.OUTSTANDINGAMT = 0 AND :NEW.ISPAID='Y')THEN
            UPDATE LICENSE_PAYMENT_HEADER@crm_link SET IS_PAID = '1', OUTSTANDING_AMOUNT = :NEW.OUTSTANDINGAMT, RECEIPT_DATE = :NEW.UPDATED WHERE LICENSE_PAYMENT_HEADER_ID = :NEW.C_ORDER_ID;
            COMMIT;  
        ELSE
            UPDATE LICENSE_PAYMENT_HEADER@crm_link SET OUTSTANDING_AMOUNT = :NEW.OUTSTANDINGAMT WHERE LICENSE_PAYMENT_HEADER_ID = :NEW.C_ORDER_ID;
            COMMIT;  
        END IF;    
END;
/

/*ALTERNATIVE SYNTAX FOLOWS:
CREATE DATABASE LINK erp_link
   CONNECT TO openbruser IDENTIFIED BY Imis2goke
   USING     
    '(DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = 172.100.3.30)(PORT = 1542))
        (CONNECT_DATA =
          (SERVER = SHARED)
          (SERVICE_NAME = timis.cck)
        )
      )';
*/

--ERP STUFF
--ADDED C_BPARTNER ROOT:INSERT INTO C_BPARTNER@erp_link(C_BPARTNER_ID,AD_CLIENT_ID,AD_ORG_ID,VALUE,NAME,C_BP_GROUP_ID,FIRSTSALE)VALUES(:NEW.client_id,'52C09F118D974F2D880F85811017B8BF','E3F7A3865F594647A5594F01E4CCC9C6',:NEW.client_name,:NEW.client_name,'6B35107E7149444C99722EA811445666',:NEW.date_created);

--ADDED AD_CLIENT CCK: 52C09F118D974F2D880F85811017B8BF	0	Y	25-JUN-10	0	01-FEB-11	6FDCBA71DFEB4D0987BEA5321597D870	CCK	Communications Commission of Kenya	Regulator of Communications in Kenya						en_US	N	N	266
--ADDED AD_ORG CCK DEPARTMENTS:
REM INSERTING into OPENBR.AD_ORG
SET DEFINE OFF;
--Insert into ERPUSER.AD_ORG (AD_ORG_ID,AD_CLIENT_ID,ISACTIVE,CREATED,CREATEDBY,UPDATED,UPDATEDBY,VALUE,NAME,DESCRIPTION,ISSUMMARY,AD_ORGTYPE_ID,ISPERIODCONTROLALLOWED,C_CALENDAR_ID,ISREADY) values ('0','0','Y',to_date('12-APR-10','DD-MON-RR'),'0',to_date('12-APR-10','DD-MON-RR'),'0','0','*','All Organizations','N','0','N',null,'Y');
-- Insert into ERPUSER.AD_ORG (AD_ORG_ID,AD_CLIENT_ID,ISACTIVE,CREATED,CREATEDBY,UPDATED,UPDATEDBY,VALUE,NAME,DESCRIPTION,ISSUMMARY,AD_ORGTYPE_ID,ISPERIODCONTROLALLOWED,C_CALENDAR_ID,ISREADY) 
-- values ('E3F7A3865F594647A5594F01E4CCC9C6','52C09F118D974F2D880F85811017B8BF','Y',to_date('28-JUN-10','DD-MON-RR'),'0',to_date('19-JAN-11','DD-MON-RR'),'6FDCBA71DFEB4D0987BEA5321597D870','000','Communications Commission of Kenya',null,'Y','1','Y','C879214F12314FE1A21AD53742797864','Y');
-- Insert into OPENBR.AD_ORG (AD_ORG_ID,AD_CLIENT_ID,ISACTIVE,CREATED,CREATEDBY,UPDATED,UPDATEDBY,VALUE,NAME,DESCRIPTION,ISSUMMARY,AD_ORGTYPE_ID,ISPERIODCONTROLALLOWED,C_CALENDAR_ID,ISREADY) values ('DFA64879E3AA4B29BCAAA50ACD18284B','52C09F118D974F2D880F85811017B8BF','Y',to_date('30-JUN-10','DD-MON-RR'),'100',to_date('30-JUN-10','DD-MON-RR'),'100','001','Director General',null,'N','2','N',null,'Y');
-- Insert into OPENBR.AD_ORG (AD_ORG_ID,AD_CLIENT_ID,ISACTIVE,CREATED,CREATEDBY,UPDATED,UPDATEDBY,VALUE,NAME,DESCRIPTION,ISSUMMARY,AD_ORGTYPE_ID,ISPERIODCONTROLALLOWED,C_CALENDAR_ID,ISREADY) values ('0AF460A48C02486382AB37646B3F64B5','52C09F118D974F2D880F85811017B8BF','Y',to_date('30-JUN-10','DD-MON-RR'),'100',to_date('30-JUN-10','DD-MON-RR'),'100','002','Finance and Accounts',null,'N','2','N',null,'Y');
-- Insert into OPENBR.AD_ORG (AD_ORG_ID,AD_CLIENT_ID,ISACTIVE,CREATED,CREATEDBY,UPDATED,UPDATEDBY,VALUE,NAME,DESCRIPTION,ISSUMMARY,AD_ORGTYPE_ID,ISPERIODCONTROLALLOWED,C_CALENDAR_ID,ISREADY) values ('1FA73FF38974483F83E64EE5B51CB3AB','52C09F118D974F2D880F85811017B8BF','Y',to_date('09-NOV-10','DD-MON-RR'),'8AA7A3B386E44AE397D2D23926462C4A',to_date('19-JAN-11','DD-MON-RR'),'6FDCBA71DFEB4D0987BEA5321597D870','008','Commissions Public Relations',null,'N','2','N',null,'Y');
-- Insert into OPENBR.AD_ORG (AD_ORG_ID,AD_CLIENT_ID,ISACTIVE,CREATED,CREATEDBY,UPDATED,UPDATEDBY,VALUE,NAME,DESCRIPTION,ISSUMMARY,AD_ORGTYPE_ID,ISPERIODCONTROLALLOWED,C_CALENDAR_ID,ISREADY) values ('F84036C107FD4CACB154249CF3FDBB82','52C09F118D974F2D880F85811017B8BF','Y',to_date('09-NOV-10','DD-MON-RR'),'8AA7A3B386E44AE397D2D23926462C4A',to_date('19-JAN-11','DD-MON-RR'),'6FDCBA71DFEB4D0987BEA5321597D870','006','Frequency Spectrum Management',null,'N','2','N',null,'Y');
-- Insert into OPENBR.AD_ORG (AD_ORG_ID,AD_CLIENT_ID,ISACTIVE,CREATED,CREATEDBY,UPDATED,UPDATEDBY,VALUE,NAME,DESCRIPTION,ISSUMMARY,AD_ORGTYPE_ID,ISPERIODCONTROLALLOWED,C_CALENDAR_ID,ISREADY) values ('58CD0A44CA8041129E266976CBC7B059','52C09F118D974F2D880F85811017B8BF','Y',to_date('30-NOV-10','DD-MON-RR'),'6FDCBA71DFEB4D0987BEA5321597D870',to_date('19-JAN-11','DD-MON-RR'),'6FDCBA71DFEB4D0987BEA5321597D870','003','Human Resources and Administration',null,'N','2','N',null,'Y');
-- Insert into OPENBR.AD_ORG (AD_ORG_ID,AD_CLIENT_ID,ISACTIVE,CREATED,CREATEDBY,UPDATED,UPDATEDBY,VALUE,NAME,DESCRIPTION,ISSUMMARY,AD_ORGTYPE_ID,ISPERIODCONTROLALLOWED,C_CALENDAR_ID,ISREADY) values ('575488A438DC4754AF0C4CB7BA0E3D06','52C09F118D974F2D880F85811017B8BF','Y',to_date('30-NOV-10','DD-MON-RR'),'6FDCBA71DFEB4D0987BEA5321597D870',to_date('19-JAN-11','DD-MON-RR'),'6FDCBA71DFEB4D0987BEA5321597D870','009','Information Technology',null,'N','2','N',null,'Y');
-- Insert into OPENBR.AD_ORG (AD_ORG_ID,AD_CLIENT_ID,ISACTIVE,CREATED,CREATEDBY,UPDATED,UPDATEDBY,VALUE,NAME,DESCRIPTION,ISSUMMARY,AD_ORGTYPE_ID,ISPERIODCONTROLALLOWED,C_CALENDAR_ID,ISREADY) values ('9F92221AB6DF416BACF3B40076964E50','52C09F118D974F2D880F85811017B8BF','Y',to_date('25-OCT-10','DD-MON-RR'),'100',to_date('19-JAN-11','DD-MON-RR'),'6FDCBA71DFEB4D0987BEA5321597D870','011','Procurement',null,'N','2','N',null,'Y');
-- Insert into OPENBR.AD_ORG (AD_ORG_ID,AD_CLIENT_ID,ISACTIVE,CREATED,CREATEDBY,UPDATED,UPDATEDBY,VALUE,NAME,DESCRIPTION,ISSUMMARY,AD_ORGTYPE_ID,ISPERIODCONTROLALLOWED,C_CALENDAR_ID,ISREADY) values ('984A712EFD994C57A690C344514B8D8B','52C09F118D974F2D880F85811017B8BF','Y',to_date('09-NOV-10','DD-MON-RR'),'8AA7A3B386E44AE397D2D23926462C4A',to_date('03-FEB-11','DD-MON-RR'),'6FDCBA71DFEB4D0987BEA5321597D870','005','Licensing, Compliance Standards',null,'N','2','N',null,'Y');
-- Insert into OPENBR.AD_ORG (AD_ORG_ID,AD_CLIENT_ID,ISACTIVE,CREATED,CREATEDBY,UPDATED,UPDATEDBY,VALUE,NAME,DESCRIPTION,ISSUMMARY,AD_ORGTYPE_ID,ISPERIODCONTROLALLOWED,C_CALENDAR_ID,ISREADY) values ('A96A5C0624A24BF78FFFECD92E1FA0A7','52C09F118D974F2D880F85811017B8BF','Y',to_date('01-DEC-10','DD-MON-RR'),'6FDCBA71DFEB4D0987BEA5321597D870',to_date('19-JAN-11','DD-MON-RR'),'6FDCBA71DFEB4D0987BEA5321597D870','004','Legal Affairs',null,'N','2','N',null,'Y');
-- Insert into OPENBR.AD_ORG (AD_ORG_ID,AD_CLIENT_ID,ISACTIVE,CREATED,CREATEDBY,UPDATED,UPDATEDBY,VALUE,NAME,DESCRIPTION,ISSUMMARY,AD_ORGTYPE_ID,ISPERIODCONTROLALLOWED,C_CALENDAR_ID,ISREADY) values ('15696C8D9EB548109A40710B7C0759F1','52C09F118D974F2D880F85811017B8BF','Y',to_date('01-DEC-10','DD-MON-RR'),'6FDCBA71DFEB4D0987BEA5321597D870',to_date('19-JAN-11','DD-MON-RR'),'6FDCBA71DFEB4D0987BEA5321597D870','010','Internal Audit Services',null,'N','2','N',null,'Y');
-- Insert into OPENBR.AD_ORG (AD_ORG_ID,AD_CLIENT_ID,ISACTIVE,CREATED,CREATEDBY,UPDATED,UPDATEDBY,VALUE,NAME,DESCRIPTION,ISSUMMARY,AD_ORGTYPE_ID,ISPERIODCONTROLALLOWED,C_CALENDAR_ID,ISREADY) values ('E4DF847C59B14E439AA3FB13956B28D4','52C09F118D974F2D880F85811017B8BF','Y',to_date('01-DEC-10','DD-MON-RR'),'6FDCBA71DFEB4D0987BEA5321597D870',to_date('19-JAN-11','DD-MON-RR'),'6FDCBA71DFEB4D0987BEA5321597D870','007','Consumer Tariffs Management Analysis',null,'N','2','N',null,'Y');
-- Insert into OPENBR.AD_ORG (AD_ORG_ID,AD_CLIENT_ID,ISACTIVE,CREATED,CREATEDBY,UPDATED,UPDATEDBY,VALUE,NAME,DESCRIPTION,ISSUMMARY,AD_ORGTYPE_ID,ISPERIODCONTROLALLOWED,C_CALENDAR_ID,ISREADY) values ('1EACD6BBF13F4BF18236B7190F4C7FC2','52C09F118D974F2D880F85811017B8BF','Y',to_date('01-DEC-10','DD-MON-RR'),'6FDCBA71DFEB4D0987BEA5321597D870',to_date('19-JAN-11','DD-MON-RR'),'6FDCBA71DFEB4D0987BEA5321597D870','012','Consumer Affairs',null,'N','2','N',null,'Y');
-- 



--idealy we should use periods from ERP (via VIEW or directly)
CREATE TABLE period(
	period_id		integer primary key,
	erp_period_id	varchar(32),		--link to erp financial period
	period_name		varchar(50),	
	
	start_date		date,
	end_date 		date,
	is_open			char(1) default '1' not null,
	details			clob
	);

--cck specific additions\
CREATE TABLE post_office(
	post_office_id 		integer primary key,
	post_office_name 	varchar(100), 
	head_post_office	varchar(100),
	postal_code 		varchar(10),
	code				varchar(10),
	code_desc			varchar(200),  
	region				varchar(150),
	district			varchar(150)
	);
CREATE SEQUENCE post_office_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_post_office_id BEFORE INSERT ON post_office
for each row 
begin     
	if inserting then 
		if :NEW.post_office_id  is null then
			SELECT post_office_id_seq.nextval into :NEW.post_office_id  from dual;
		end if;
	end if; 
end;
/

--we use orgs for main departments within cck
INSERT INTO orgs (org_id, org_name) VALUES (1, 'FSM');
INSERT INTO orgs (org_id, org_name) VALUES (2, 'LCS');
INSERT INTO orgs (org_id, org_name) VALUES (99, 'OTHER');		-- it should be 'ALL'

--cck SECTIONS (sub)departments like type approval,numbering,etc in LCS........ and Planning,Licensing in FSM
CREATE TABLE department (
	department_id			integer primary key,
	org_id					integer references orgs,		--org is either LCS or FSM 
	department_name			varchar(50),	
	is_active				char(1) default '1' not null,	
	details					clob
	);

CREATE SEQUENCE seq_department_id MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_department BEFORE INSERT ON department
for each row 
begin     
	if inserting then 
		if :NEW.department_id is null then
			SELECT seq_department_id.nextval into :NEW.department_id from dual;
		end if;
	end if; 
end;
/
INSERT INTO department(department_id, org_id, department_name, is_active) VALUES(1,1,'Frequency Licensing','1');
INSERT INTO department(department_id, org_id, department_name, is_active) VALUES(2,1,'Frequency Planning','1');
INSERT INTO department(department_id, org_id, department_name, is_active) VALUES(3,1,'Frequency Monitoring and Inspection','1');


INSERT INTO department(department_id, org_id, department_name, is_active) VALUES(5,2,'Numbering','1');
INSERT INTO department(department_id, org_id, department_name, is_active) VALUES(6,2,'Certification','1');
INSERT INTO department(department_id, org_id, department_name, is_active) VALUES(7,2,'Type Approval','1');

INSERT INTO department(department_id, org_id, department_name, is_active) VALUES(99,99,'Other','1');



ALTER TABLE entitys add sur_name		varchar(100);
ALTER TABLE entitys add middle_name		varchar(100);		
ALTER TABLE entitys add last_name		varchar(100);		
DROP SEQUENCE seg_entity_id;
CREATE SEQUENCE seg_entity_id MINVALUE 1 INCREMENT BY 1 START WITH 1100;

ALTER TABLE entity_types ADD department_id integer references department;	
ALTER TABLE ENTITY_TYPES MODIFY (ENTITY_TYPE_NAME VARCHAR2(100 BYTE) );

CREATE TABLE currency_unit (
	currency_unit_id 		integer primary key,
	currency_unit_name 		varchar(100), 	
	currency_abbrev			varchar(100)
	);
INSERT INTO currency_unit (currency_unit_id, currency_unit_name, currency_abbrev) VALUES (1,'Kenya Shilling', 'KES');
INSERT INTO currency_unit (currency_unit_id, currency_unit_name, currency_abbrev) VALUES (2,'United States Dollar', 'USD');
COMMIT;


--larger categorization of licenses...eg Frequency License, VHF, Broadcasting, VSAT,TERRESTRIAL,MARITIME,AERONAUTIC etc or POSTAL, INFRASTRUCTURE, SERVICE PROVIDER
CREATE TABLE license_type (
	license_type_id		integer primary key,
	license_type_name	varchar(120) not null,
	abbrev  			varchar(50),
	is_terrestrial 		char(1) default '0',		--terrestrial need 1k on top of initial payments
	is_vhf				char(1) default '0',
	is_maritime			char(1) default '0',
	
	--nlf					char(1) default '0' not null,
	--abbrev  			varchar(50),
	details				clob
	);
ALTER TABLE license_type ADD is_broadcasting char(1) default '0';
CREATE SEQUENCE license_type_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_license_type_id BEFORE INSERT ON license_type
for each row 
begin     
	if inserting then 
		if :NEW.license_type_id is null then
			SELECT license_type_id_seq.nextval into :NEW.license_type_id from dual;
		end if;
	end if; 
end;
/

--UPDATE LICENSE_TYPE SET LICENSE_TYPE_NAME = 'VHF', IS_VHF='1'
--INSERT INTO license_type(license_type_id,license_type_name,is_terrestrial,is_vhf,is_maritime,is_broadcasting) VALUES(1, 'VHF','0','1','0','0');
INSERT INTO license_type(license_type_id,license_type_name,is_terrestrial,is_vhf,is_maritime,is_broadcasting) VALUES(2, 'TERRESTRIAL','1','0','0','0');
INSERT INTO license_type(license_type_id,license_type_name,is_terrestrial,is_vhf,is_maritime,is_broadcasting) VALUES(3, 'BROADCASTING','0','0','0','1');
INSERT INTO license_type(license_type_id,license_type_name,is_terrestrial,is_vhf,is_maritime,is_broadcasting) VALUES(4, 'MARITIME','0','0','1','0');
INSERT INTO license_type(license_type_id,license_type_name,is_terrestrial,is_vhf,is_maritime,is_broadcasting) VALUES(5, 'AERONAUTICAL','0','0','0','0');
COMMIT;



CREATE TABLE license (
	license_id			integer primary key,

	department_id		integer references department,		--will vsat work with this configuration?
	license_type_id		integer references license_type,
	currency_unit_id 	integer default 1 references currency_unit,
	
	license_name		varchar(120) not null unique,
	license_abbrev		varchar (120),
	license_period		integer default 1 not null,		--aka renewal intervals
	
	application_fee		real default 0 not null,
	initial_fee			real default 0 not null,
	annual_fee			real default 0 not null,
	agt_fee				real default 0 not null,		--annual gross turnover
	
	--annualfeedetail 	varchar (240),		
	
	application_account	varchar(32),
	initial_account		varchar(32),
	annual_account		varchar(32),
	
	
	is_fixed_fee		char(1) default '0' not null,		--wether this fee is fixed or we need a formular for it
	--rollout_period		integer default 0 not null,
	--is_quarterly			char(1) default '0' not null,
	--is_annually			char(1) default '0' not null,
	is_active			char(1) default '1' not null,
	--licensereport		varchar(120),
	
	grace_period_years	integer,
	
	is_squential			char(1) default '0',		--whether or not the license number changes
	next_sequence_val		integer,
	
	--spectrum_access		clob,
	license_terms		clob,
	details				clob
	);
--ALTERS
ALTER TABLE license ADD num varchar (20);				
ALTER TABLE license ADD	is_dewcis_test char(1) default '0';
ALTER TABLE license ADD type_approval_fee real default 0 not null;
ALTER TABLE license ADD ta_account varchar(32);

CREATE SEQUENCE license_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_license_id BEFORE INSERT ON license
for each row 
begin     
	if inserting then 
		if :NEW.license_id is null then
			SELECT license_id_seq.nextval into :NEW.license_id from dual;
		end if;
	end if; 
end;
/


--application fee, initial fee, annual
CREATE TABLE payment_type (
	payment_type_id		integer primary key,
	payment_type_name	varchar(25),
	details 			clob
);
ALTER TABLE workflow_phases ADD payment_type_id	integer references payment_type;
CREATE SEQUENCE paymenttype_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_payment_type_id BEFORE INSERT ON payment_type
for each row 
begin     
	if inserting then 
		if :NEW.payment_type_id is null then
			SELECT paymenttype_id_seq.nextval into :NEW.payment_type_id  from dual;
		end if;
	end if; 
end;
/
INSERT INTO payment_type(payment_type_id, payment_type_name) VALUES(1,'No Payment');
INSERT INTO payment_type(payment_type_id, payment_type_name) VALUES(2,'Application Fee');
INSERT INTO payment_type(payment_type_id, payment_type_name) VALUES(3,'Initial Fee');		
INSERT INTO payment_type(payment_type_id, payment_type_name) VALUES(4,'Frequency Fee');
INSERT INTO payment_type(payment_type_id, payment_type_name) VALUES(5,'Renewal Fee');
INSERT INTO payment_type(payment_type_id, payment_type_name) VALUES(6,'Type Approval Fee');
COMMIT;


CREATE TABLE phase_type (
	phase_type_id		integer primary key,
	phase_type_name		varchar(25),
	details 			clob
);
CREATE SEQUENCE phase_type_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_phase_type_id BEFORE INSERT ON phase_type
for each row 
begin     
	if inserting then 
		if :NEW.phase_type_id  is null then
			SELECT phase_type_id_seq.nextval into :NEW.phase_type_id from dual;
		end if;
	end if; 
end;
/
INSERT INTO phase_type(phase_type_id, phase_type_name) VALUES(1,'Undefined');
INSERT INTO phase_type(phase_type_id, phase_type_name) VALUES(2,'Compliance');
INSERT INTO phase_type(phase_type_id, phase_type_name) VALUES(3,'Approval');
INSERT INTO phase_type(phase_type_id, phase_type_name) VALUES(4,'Notification');
COMMIT;



CREATE TABLE id_type (
  id_type_id		integer primary key,  
  id_type_name	varchar(120)
  );
ALTER TABLE id_type ADD remarks CLOB;
CREATE SEQUENCE id_type_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_id_type_id BEFORE INSERT ON id_type
for each row 
begin     
	if inserting then 
		if :NEW.id_type_id is null then
			SELECT id_type_id_seq.nextval into :NEW.id_type_id from dual;
		end if;
	end if; 
end;
/


--organization type. INDIVIDUAL(CITIZEN), INDIVIDUAL(NON CITIZEN), NGO, PARTNERSHIP, DIPLOMATIC, LTD, GOVT, UN
CREATE TABLE client_category (
	client_category_id		integer primary key,	
	client_category_name	varchar(50),
	details 				clob
	);
ALTER TABLE checklists ADD	client_category_id		integer references client_category;
	
	--citizen				char(1) default '1' not null,		--applies to citizens - ISSUE:how do we know if directors are citizens ?

CREATE SEQUENCE client_category_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 10;
CREATE OR REPLACE TRIGGER tr_client_category_id BEFORE INSERT ON client_category
for each row 
begin     
	if inserting then 
		if :NEW.client_category_id is null then
			SELECT client_category_id_seq.nextval into :NEW.client_category_id from dual;
		end if;
	end if; 
end;
/
INSERT INTO client_category(client_category_id, client_category_name) VALUES(1, 'OTHER');


--utility table
--mapping type of identification(id type) and client category. 
--determine what kind of organization can have what type of identification
CREATE TABLE category_id_type (
	category_id_type_id		integer primary key,	
	client_category_id		integer references client_category,
	id_type_id				integer references id_type	
	);
ALTER TABLE category_id_type ADD remarks CLOB;
CREATE SEQUENCE category_id_type_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_category_id_type_id BEFORE INSERT ON category_id_type
for each row 
begin     
	if inserting then 
		if :NEW.category_id_type_id is null then
			SELECT category_id_type_id_seq.nextval into :NEW.category_id_type_id from dual;
		end if;
	end if; 
end;
/


--industry eg telecoms, transport, security
CREATE TABLE client_industry (
	client_industry_id		integer primary key,
	client_industry_name	varchar(50),
	details				    clob
	);
ALTER TABLE checklists ADD client_industry_id		integer references client_industry;
CREATE SEQUENCE client_industry_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 10;
CREATE OR REPLACE TRIGGER tr_client_industry_id BEFORE INSERT ON client_industry
for each row 
begin     
	if inserting then 
		if :NEW.client_industry_id is null then
			SELECT client_industry_id_seq.nextval into :NEW.client_industry_id from dual;
		end if;
	end if; 
end;
/
INSERT INTO client_industry(client_industry_id, client_industry_name) VALUES(1, 'OTHER');
COMMIT;

/*
--checklists for each specific phase
CREATE TABLE phase_checklist(
	phase_checklist_id		integer primary key,
	license_phase_id		integer references license_phase,
	
	requirement				varchar(500),
	
	client_category_id		integer references client_category,
	client_industry_id		integer references client_industry,	
	--citizen				char(1) default '1' not null,		--applies to citizens - ISSUE:how do we know if directors are citizens ?

	is_active				char(1) default '1' not null,		--for temporarily disabling/deleting checklists
	is_mandatory			char(1) default '1' not null,

	details					clob
	);
--ALERT
ALTER TABLE phase_checklist ADD checklist_number integer;

--CREATE INDEX checklists_phaseid ON checklists (phaseid);
CREATE SEQUENCE phase_checklist_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_phase_checklist_id BEFORE INSERT ON phase_checklist
for each row 
begin     
	if inserting then 
		if :NEW.phase_checklist_id is null then
			SELECT phase_checklist_id_seq.nextval into :NEW.phase_checklist_id from dual;
		end if;
	end if; 
end;
/
*/



--utility table 
CREATE TABLE station_class (
	station_class_id		char(2) primary key,
	station_class_name	varchar(120),
	details				clob
	);

--utility table 
CREATE TABLE service_nature (
	service_nature_id		char(2) primary key,
	service_nature_name	varchar(120),
	details				clob
	);

--utility table... for type of charge Annual, Monthly, Alarms ??????
--DROP TABLE charge_type;
CREATE TABLE charge_type (
	--charge_type_id		char(2) primary key,
	charge_type_id    integer primary key,
	charge_type_name	varchar(120),
	unit_group			integer default 1 not null,			--used for alarms

	one_time_fee		char(1) default '0' not null,
	per_license			char(1) default '0' not null,
	per_station			char(1) default '0' not null,
	per_frequency		char(1) default '0' not null,

	has_fixed_charge	char(1) default '0' not null,
	renewal_period		integer default '0' not null,		--the renewal period for a particular station... (redundant ?)

	details				clob
	);
CREATE SEQUENCE charge_type_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_charge_type_id BEFORE INSERT ON charge_type
for each row 
begin     
	if inserting then
		if :NEW.charge_type_id is null then
			SELECT charge_type_id_seq.nextval into :NEW.charge_type_id  from dual;
		end if;
	end if;
end;
/



CREATE TABLE station_charge (
	station_charge_id	integer primary key,
	license_id			integer references license,
	station_class_id	char(2) references station_class,
	
	
	amount				real,			--exact amount
	charge_type_id		integer references charge_type,
		
	functname			varchar(50),		--used in the trigger
	formula				clob,

	
	--syntax:			column_name [datatype] [GENERATED ALWAYS] AS [expression] [VIRTUAL]
	--formula_expression  NUMBER GENERATED ALWAYS AS (ROUND(salary*(1+comm2/100),2)) VIRTUAL,
	--we need parameters here like k,etc

	details				clob
	);
--ALTERS
ALTER TABLE station_charge ADD station_charge_name			varchar(50);		--aka typename(licenseprices)
ALTER TABLE station_charge ADD unit_charge					real;				--where ???????

CREATE SEQUENCE station_charge_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_station_charge_id BEFORE INSERT ON station_charge
for each row 


begin     
	if inserting then
		if :NEW.station_charge_id  is null then
			SELECT station_charge_id_seq.nextval into :NEW.station_charge_id  from dual;
		end if;
	end if;
end;
/



--all possible status of a client
CREATE TABLE status_client(
	status_client_id		integer primary key,
	status_client_name		varchar(50),
	details					clob
	);
CREATE SEQUENCE status_client_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_status_client_id BEFORE INSERT ON status_client
for each row 
begin     
	if inserting then 
		if :NEW.status_client_id is null then
			SELECT status_client_id_seq.nextval into :NEW.status_client_id from dual;
		end if;
	end if; 
end;
/
INSERT INTO status_client(status_client_id, status_client_name) VALUES(1, 'OTHER');
INSERT INTO status_client(status_client_id, status_client_name) VALUES(2, 'ACTIVE');
COMMIT;

--DROP TABLE client;
CREATE TABLE client(
	client_id			integer primary key,
	--irisclientid		integer,
	client_category_id	integer references client_category,		--legal entity
	client_industry_id	integer references client_industry,
	status_client_id 	integer references status_client,

	id_type_id 			integer references id_type,
	id_number			varchar(120),
	pin			 		varchar(50),

	accounts_code		varchar(120),		--code in FnA
	--financialyearend	date,	we ignore the year part
	--financialyearendmonth		char(15) default to_char(financialyearend,'Month'),		--
	--AAAdeadlinedate			date default financialyearend + 90, --90 days after financial year

	--address_type_id		integer references addresstypes,	
	--post_office_id		integer references post_office,	
	postal_code 		varchar(10),

	sys_country_id			char(2) references sys_countrys,

	--userid			integer references entitys,	
	--companyreg		varchar(120),
		
	address				varchar(50),
	premises			varchar(120),
	street				varchar(120),
	town				varchar(50) not null,
	fax					varchar(150),
	email				varchar(120),
	file_number			varchar(120),
	country_code		varchar(12),
	tel_no				varchar(150),
	mobile_num			varchar(150),
	building_floor		varchar(120),
	lr_number			varchar(120),
	website				varchar(240),
	division			varchar(240),

	--mail
	
	--financialyearend	date,			--we ignore the year part
	--financialyearendmonth		char(15) default to_char(financialyearend,'Month'),		--
	--AAAdeadlinedate				date default financialyearend + 90, --90 days after financial year

	date_created 			date default sysdate,
	date_updated 			date default sysdate,
	created_by			integer references entitys,
	updated_by			integer references entitys,
	entity_id			integer references entitys,
	
	--clientlogin		varchar(32),
	--userpasswd		varchar(32) default 'hello' not null,
	--firstpasswd		varchar(32) default 'hello' not null,

	date_enroled		date default sysdate,
	document_link		varchar(240),
	is_active			char(1) default '1' not null,
	compliant			char(1) default '1' not null,

	--ispicked			char(1) default '0' not null,
	--ischanged			char(1) default '0' not null,
	--isoldlcs			char(1) default '0' not null,
	--isoldfsm			char(1) default '0' not null,
	--foreignholding		float,

	license_number		varchar(20),

	details				clob
	);
ALTER TABLE client add client_name		varchar(120);
ALTER TABLE client add	license_id 		integer references license;		--first time application_account

ALTER TABLE client ADD bill_address			varchar(50);
ALTER TABLE client ADD bill_postal_code			varchar(50);
ALTER TABLE client ADD bill_fax				varchar(150);
ALTER TABLE client ADD bill_tel_no			varchar(150);
ALTER TABLE client ADD bill_mobile_num		varchar(150);
ALTER TABLE client ADD bill_email			varchar(150);

ALTER TABLE client ADD fiscal_year_start_month		varchar(50);	--month
ALTER TABLE client ADD fiscal_year_start_day		varchar(50);
ALTER TABLE client add ob_client_id	varchar(32);		--openbravo id
	
--CREATE INDEX clients_clientcategoryid ON clients (clientcategoryid);
--CREATE INDEX clients_clienttypeid ON clients (clienttypeid);
--CREATE INDEX clients_idtypeid ON clients (idtypeid);
--CREATE INDEX clients_createdby ON clients (createdby);
--CREATE INDEX clients_updatedby ON clients (updatedby);
CREATE SEQUENCE client_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_client_id BEFORE INSERT OR UPDATE ON client
for each row 
begin     
	if inserting then 

		IF :NEW.license_id = 0 THEN
			RAISE_APPLICATION_ERROR(-20015,'PLEASE SELECT A LICENSE');				
		END IF;

		if :NEW.client_id is null then
			SELECT client_id_seq.nextval into :NEW.client_id from dual;			
		end if;

		if :NEW.created_by is null then
			:NEW.created_by:=:NEW.entity_id;
		end if;

		--if (:NEW.postalcode is not null) then
		--	:NEW.post_office_id := null;			--ignore the postoffice id given in the combo
		--end if;				

	end if; 

	if updating then 

		--make sure the added postalcode is not already existing

		:NEW.date_updated := SYSDATE;
		:NEW.updated_by := :NEW.entity_id;

	end if; 

end;
/




CREATE OR REPLACE TRIGGER tr_ins_client_licenses AFTER INSERT ON client
   FOR EACH ROW 
DECLARE

BEGIN

	--client details (Workaround since clients table is mutating)
	--INSERT INTO clientdetail(clientid,clienttypeid,clientcategoryid)
	--	SELECT :NEW.CLIENTID,:NEW.CLIENTTYPEID,:NEW.CLIENTCATEGORYID FROM DUAL;

	--billing address
	--INSERT INTO addresses (clientid,addresstypeid,address,postofficeid,town,premises,street,email,telno,mobilenum,fax,countryid)
	--	VALUES( :NEW.CLIENTID,40,:NEW.address,:NEW.postofficeid,:NEW.town,:NEW.premises,:NEW.street,:NEW.email,:NEW.telno,:NEW.mobilenum,:NEW.fax,:NEW.countryid);				

	--normal stuff
	IF :NEW.is_illegal = '0' THEN
		INSERT INTO client_license(license_id, client_id, created_by)
			SELECT :NEW.LICENSE_ID, :NEW.CLIENT_ID, :NEW.CREATED_BY FROM DUAL;
	END IF;
			
				
END;
/


CREATE OR REPLACE TRIGGER tr_ins_b_partner AFTER INSERT ON client
	FOR EACH ROW

	DECLARE
		PRAGMA AUTONOMOUS_TRANSACTION;

	BEGIN
	
    
		IF :NEW.is_illegal = '0' THEN

			INSERT INTO C_BPARTNER@erp_link(C_BPARTNER_ID,AD_CLIENT_ID,AD_ORG_ID,CREATED,CREATEDBY,UPDATED,UPDATEDBY,VALUE,NAME,C_BP_GROUP_ID,FIRSTSALE,AD_LANGUAGE,INVOICERULE)		--GROUP USED IS CUSTOMERS AKA LICENSEES
				VALUES(:NEW.client_id,'52C09F118D974F2D880F85811017B8BF','E3F7A3865F594647A5594F01E4CCC9C6',:NEW.date_created,'0',:NEW.date_created,'0',:NEW.pin,(:NEW.client_name || ' - ' || :NEW.address || ' - ' || COALESCE(:NEW.mobile_num,'')),'6B35107E7149444C99722EA811445666',:NEW.date_created,'en_US','I');
			COMMIT;

			INSERT INTO C_LOCATION@erp_link(C_LOCATION_ID,AD_CLIENT_ID,AD_ORG_ID,ISACTIVE,CREATED,CREATEDBY,UPDATED,UPDATEDBY,ADDRESS1,ADDRESS2,CITY,POSTAL,C_COUNTRY_ID)
				VALUES(:NEW.client_id,'52C09F118D974F2D880F85811017B8BF','E3F7A3865F594647A5594F01E4CCC9C6','Y',:NEW.date_created,'0',:NEW.date_created,'0',:NEW.premises,:NEW.street,:NEW.TOWN,:NEW.postal_code, 219);
			COMMIT;

		--LOCATION
			INSERT INTO C_BPARTNER_LOCATION@erp_link(C_BPARTNER_LOCATION_ID,C_BPARTNER_ID,AD_CLIENT_ID,AD_ORG_ID,ISACTIVE,CREATED,CREATEDBY,UPDATED,UPDATEDBY,NAME,ISBILLTO,ISSHIPTO,ISPAYFROM,ISREMITTO,ISTAXLOCATION,C_LOCATION_ID, PHONE)
				VALUES(:NEW.client_id,:NEW.client_id,'52C09F118D974F2D880F85811017B8BF','E3F7A3865F594647A5594F01E4CCC9C6','Y',:NEW.date_created,'0',:NEW.date_created,'0',:NEW.client_name,'Y','Y','Y','Y','Y',:NEW.client_id,:NEW.mobile_num);
			COMMIT;
		--MISSING: C_BANK,C_BANK_ACCOUNT,M_PRICE_LIST(License pricelist),C_PAYMENT_TERM

	END IF;
  
	--EXCEPTION
		--WHEN OTHERS THEN
      --DBMS_OUTPUT.PUT_LINE ('CLIENT ALREADY EXISTS. using PIN to validate');
      --RAISE;

end;
/

--ALTER TRIGGER tr_ins_b_partner DISABLE;


--directors of the company
CREATE TABLE client_director(
	client_director_id	integer primary key,
	client_id				integer references client,		--constraint removed
	sys_country_id				char(2) default 'KE' references sys_countrys,
  
	id_type_id 				integer references id_type,
	id_number				varchar(50),

	client_director_name	varchar(240),
	designation				varchar(240),
	salutation				varchar(20),
	
	details			clob
);

--CREATE INDEX clientcontact_clientid ON clientcontact (clientid);
CREATE SEQUENCE client_director_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_client_director_id BEFORE INSERT ON client_director
for each row 
begin     
	if inserting then 
		if :NEW.client_director_id is null then
			SELECT client_director_id_seq.nextval into :NEW.client_director_id from dual;
		end if;
	end if; 
end;
/






--all possible status of a license held by a client
CREATE TABLE status_license(
	status_license_id		integer primary key,
	status_license_name		varchar(50),
	details					clob
	);
CREATE SEQUENCE status_license_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_status_license_id BEFORE INSERT ON status_license
for each row 
begin     
	if inserting then 
		if :NEW.status_license_id is null then
			SELECT status_license_id_seq.nextval into :NEW.status_license_id from dual;
		end if;
	end if; 
end;
/
INSERT INTO status_license(status_license_id, status_license_name) VALUES(1,'OTHER');
INSERT INTO status_license(status_license_id, status_license_name) VALUES(2,'APPROVED');
INSERT INTO status_license(status_license_id, status_license_name) VALUES(3,'ACTIVE');
INSERT INTO status_license(status_license_id, status_license_name) VALUES(4,'EXPIRED');
INSERT INTO status_license(status_license_id, status_license_name) VALUES(5,'SUSPENDED');
INSERT INTO status_license(status_license_id, status_license_name) VALUES(6,'TERMINATED');
INSERT INTO status_license(status_license_id, status_license_name) VALUES(7,'CANCELLED');



CREATE TABLE status_station(
	status_station_id		integer primary key,
	status_station_name		varchar(50),
	details					clob
	);
CREATE SEQUENCE status_station_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_status_station_id BEFORE INSERT ON status_station
for each row 
begin     
	if inserting then 
		if :NEW.status_station_id is null then
			SELECT status_station_id_seq.nextval into :NEW.status_station_id from dual;
		end if;
	end if; 
end;

--compliance licensing commitee
--document naming YYYY_CLCNO_1
CREATE TABLE clc (
	clc_id 			integer primary key,
	clc_date		date,
	clc_number 		varchar(20),
	is_active				char(1) default '1' not null,
	doc_url				varchar(500),				--user may want to hardcode url directly to the specific document (word/pdf) in the DMS
	dms_space_url		varchar(500),				--we need to hardcode the specific dms space
	minute_number 		varchar(20),
	minute_doc 			blob,
	details 			clob
	);
CREATE SEQUENCE clc_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_clc_id BEFORE INSERT ON clc
for each row 
begin     
	if inserting then   
		--deactivate all the others		
		--update clc set active='0';
		
		if :NEW.clc_id is null then
			SELECT clc_id_seq.nextval into :NEW.clc_id from dual;
		end if;				
	end if; 
end;
/



CREATE TABLE board_meeting (
	board_meeting_id 			integer primary key,
	board_meeting_date		date,
	board_meeting_number 		varchar(20),
	is_active				char(1) default '1' not null,
	doc_url				varchar(500),				--user may want to hardcode url directly to the specific document (word/pdf) in the DMS
	dms_space_url		varchar(500),				--we need to hardcode the specific dms space
	minute_number 		varchar(20),
	minute_doc 			blob,
	details 			clob
	);
CREATE SEQUENCE board_meeting_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_board_meeting_id BEFORE INSERT ON board_meeting
for each row 
begin     
	if inserting then   
		--deactivate all the others		
		--update clc set active='0';
		
		if :NEW.board_meeting_id is null then
			SELECT board_meeting_id_seq.nextval into :NEW.board_meeting_id from dual;
		end if;				
	end if; 
end;
/




CREATE TABLE equipment_approval(	
	equipment_approval_id 		integer primary key,
	equipment_type_id			integer 		references equipment_type,

	equipment_name 				varchar(50),
	
	manufacturer 			varchar(50),
	make					varchar(50),
	model 					varchar(50),

	--countryid			integer 		references _id,
	power_supply 			varchar(50),

	frequency_deviation 	varchar(50),
	modulation 				varchar(50),
	number_of_channels 		varchar(50),
	data_mode 				varchar(50),
	rf_output 				varchar(50),
	--dimensions 			varchar(50),
	--interface 			varchar(50),
	live_test 				varchar(50),
	serial_number 			varchar(50),
	
	rf_bandwidth 			varchar(50),
	channel_capacity 		varchar(50),
	carrier_output_power 	varchar(50),
	tolerance 				varchar(50),
	duplex_spacing 			varchar(50),
	adjacent_channel_spacing varchar(50),
	power_to_antenna 		varchar(50),
	system_deviation		varchar(50),
	fm_noise 				varchar(50),
	bit_error_rate 			varchar(50),
	conducted_spurious 		varchar(50),
	radiated_spurious 			varchar(50),
	audio_harmonic_distortion 	varchar(50),
	operating_frequency_band 	varchar(50),
	if_bandwidth_3db 			varchar(50),
	receiver_sensitivity 		varchar(50),
	receiver_adjacenst_selectivity varchar(50),
	desensitisation 		varchar(50),
	threshold 				varchar(50),
	rf_filterloss 			varchar(50),

	remarks					clob
	);

ALTER TABLE equipment_approval ADD client_license_id INTEGER references client_license;
ALTER TABLE equipment_approval ADD eval_report_url varchar(200);
ALTER TABLE equipment_approval ADD sys_country_id char(2) references sys_countrys;

ALTER TABLE equipment_approval ADD overview CLOB;
ALTER TABLE equipment_approval ADD purpose CLOB;
ALTER TABLE equipment_approval ADD evaluation_results CLOB;
ALTER TABLE equipment_approval ADD recommendation CLOB;

ALTER TABLE equipment_approval ADD case_number		varchar(50);
ALTER TABLE equipment_approval ADD dimensions		varchar(50);
ALTER TABLE equipment_approval ADD memory			varchar(50);
ALTER TABLE equipment_approval ADD sar				varchar(50);
ALTER TABLE equipment_approval ADD interface		varchar(50);
ALTER TABLE equipment_approval ADD features			clob;

ALTER TABLE equipment_approval ADD provisional_letter			clob;
ALTER TABLE equipment_approval ADD cert_url 		varchar(200);		--in DMS
ALTER TABLE equipment_approval ADD inline_cert 		clob;		--inline certificate
ALTER TABLE equipment_approval ADD is_ta_approved 	char(1) default '0';

ALTER TABLE equipment_approval ADD inline_report 	clob;		--inline certificate
ALTER TABLE equipment_approval ADD evaluation_date 	date;

ALTER TABLE equipment_approval ADD type_approval_fee real default 0 not null;

CREATE INDEX equip_appr_cli_lic_id ON equipment_approval (client_license_id);
CREATE INDEX equip_appr_equip_type_id ON equipment_approval (equipment_type_id);
CREATE INDEX equip_appr_country_id ON equipment_approval (sys_country_id);

CREATE SEQUENCE equipment_approval_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_equipment_approval_id BEFORE INSERT ON equipment_approval
for each row 
begin     
	if inserting then   		
		if :NEW.equipment_approval_id is null then
			SELECT equipment_approval_id_seq.nextval into :NEW.equipment_approval_id from dual;
		end if;				
	end if; 
end;
/

-- CREATE OR REPLACE TRIGGER upd_eval_report BEFORE UPDATE ON equipment_approval
-- for each row 
-- DECLARE 	
--  	new_report_url		varchar(500);
-- 	new_letter_url		varchar(500);		--provisional cert/letter
-- begin     
--  if updating then
-- 	
-- 	--EVALUATION 
-- 	SELECT REPLACE(:NEW.eval_report_url,'<a href=','') INTO new_report_url FROM dual;		--remove the leading '<a href=' substring
-- 	SELECT REPLACE(new_report_url,'>Evaluation Report</a>','') INTO new_report_url FROM dual;		--remove the trailing part
-- 
-- 	:NEW.eval_report_url := '<a href=' || new_report_url || '>Evaluation Report</a>';
-- 	
-- 	--CERFICATE
-- 	SELECT REPLACE(:NEW.cert_url,'<a href=','') INTO new_letter_url FROM dual;		--remove the leading '<a href=' substring
-- 	SELECT REPLACE(new_letter_url,'>Provisional Letter</a>','') INTO new_letter_url FROM dual;		--remove the trailing part
-- 
-- 	:NEW.cert_url := '<a href=' || new_letter_url || '>Provisional Letter</a>';
-- 	
-- end if;
-- 
-- end;
-- /
--ALTER TRIGGER UPD_EVALREPORT_URL ENABLE;


CREATE OR REPLACE TRIGGER tr_ta_payment AFTER UPDATE ON equipment_approval
    FOR EACH ROW
    DECLARE
        PRAGMA AUTONOMOUS_TRANSACTION;
		pay_header_id		integer;
		tab_id				integer;
    BEGIN       
		
		

		IF (:OLD.type_approval_fee != :NEW.type_approval_fee) AND (:NEW.type_approval_fee > 0) THEN

			UPDATE client_license SET ta_fee = (ta_fee + :NEW.type_approval_fee) WHERE client_license_id = :NEW.client_license_id;
			COMMIT;

		END IF;

END;
/

--ALTER TRIGGER tr_ta_payment DISABLE;

--type approval commitee
CREATE TABLE tac (
	tac_id 				integer primary key,
	tac_date			date,
	tac_number 			varchar(20),
	minute_number 		varchar(20),
	is_active			char(1) default '1' not null,

	report_url			varchar(500),				--user may want to hardcode url directly to the specific document (word/pdf) in the DMS
	dms_space_url		varchar(500),
	inline_report		clob,						

	action_date			date default sysdate not null,
	members_present		clob,

	details 			clob
);
CREATE SEQUENCE tac_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_tac_id BEFORE INSERT ON tac
for each row 
begin     
	if inserting then 
		--deactivate all the others		
		--update tac set isactive='0';

		if :NEW.tac_id is null then
			SELECT tac_id_seq.nextval into :NEW.tac_id from dual;
		end if;
	end if; 
end;
/


--internal, external, memo, circular
CREATE TABLE correspondence_type(
	correspondence_type_id	integer primary key,
	correspondence_type_name		varchar(50),	
	is_internal				char(1) default '0' not null,
	details				  	clob
	);
INSERT INTO correspondence_type(correspondence_type_id,correspondence_type_name,is_internal) VALUES(1,'INTERNAL','1');
INSERT INTO correspondence_type(correspondence_type_id,correspondence_type_name,is_internal) VALUES(2,'EXTERNAL','0');
INSERT INTO correspondence_type(correspondence_type_id,correspondence_type_name,is_internal) VALUES(3,'MEMO','1');
INSERT INTO correspondence_type(correspondence_type_id,correspondence_type_name,is_internal) VALUES(4,'CIRCULAR','1');
COMMIT;



--registry entry EXCLUDES file borrowing
--internal correspondence is identified by the values inside fromdepartmentid and todepartmentid
CREATE TABLE correspondence(
	correspondence_id		integer primary key,
	--registertypeid		integer references registertype,
	correspondence_type_id	integer references correspondence_type,
			
	from_department_id		integer	references department,		-- if internal
	to_department_id		integer	references department,		-- if internal

	correspondence_source	varchar(50),					--correspondece -> source of the letter, filecirculation -> clientname
	letter_ref				varchar(50),
	letter_title			varchar(50),	
	letter_date				date default sysdate not null,
	cck_reference			varchar(50),				
	--subject					varchar(100),	--redundant			

	created_by				integer references entitys,
	created_date			date default sysdate not null,
	updated_by				integer references entitys,
	updated_date			date,

	details				clob
	);
CREATE SEQUENCE correspondenceid_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;

CREATE INDEX correspondence_corr_type_id ON correspondence (correspondence_type_id);
CREATE INDEX correspondence_from_dept_id ON correspondence (from_departmentid);
CREATE INDEX correspondence_to_dept_id ON correspondence (to_departmentid);
CREATE INDEX correspondence_created_by ON correspondence (created_by);
CREATE INDEX correspondence_updated_by ON correspondence (updated_by);


CREATE SEQUENCE ref_sequence;		--used to generate sequence for external (+ internal for now) correspondence
CREATE SEQUENCE internal_corr_sequence NOCACHE MINVALUE 1 INCREMENT BY 1 START WITH 1;		--sequence for internal correspondences

CREATE OR REPLACE TRIGGER tr_correspondence_id BEFORE INSERT ON correspondence
FOR EACH ROW

DECLARE

PRAGMA AUTONOMOUS_TRANSACTION;

	mm	varchar(5);
	yy	varchar(5);
	lastaction varchar(5);
	nxt integer;

	CURSOR user_cur IS
		SELECT userid, rolename, functionname
		FROM users  
		WHERE userid = :NEW.userid;
		rec_user user_cur%ROWTYPE;
begin     

	if inserting then 
		
		OPEN user_cur;
		FETCH user_cur INTO rec_user;

		if :NEW.correspondenceid is null then
			SELECT correspondenceid_seq.nextval into :NEW.correspondenceid from dual;			
		end if;
			
		:NEW.receiverid := :NEW.userid;		--cant remember
		
		--do sequence if the user is from FSM
		IF rec_user.rolename = 'FSM' OR rec_user.rolename = 'ENGINEER' THEN

			--make sure files do not increment our sequence/reference number
			IF :NEW.dfnumber IS NOT NULL THEN
				RETURN;
			END IF;

			--get months	
			Select to_char(sysdate,'MM') into mm FROM DUAL;	--this month
			Select to_char(sysdate,'YY') into yy FROM DUAL;	--this year
		
			--get the date (month) of the last correspondence		
			select to_char(receivedate,'MM') into lastaction from correspondence 
				where correspondenceid = (select max(correspondenceid ) from correspondence); 
			--where correspondenceid = (select max(correspondenceid ) from correspondence where fromdepartmentid is null and todepartmentid is null); 

			IF (:NEW.correspondencetypeid = 1) THEN		--IF EXTERNAL
					
				--if its not equal to this month then this is a new entry of this month
				--therefore we RESET the sequence
				IF (lastaction != mm) THEN
					--we attempt to reset the sequence
					
					SELECT ref_sequence.NEXTVAL INTO nxt FROM dual;

					EXECUTE IMMEDIATE 'alter sequence ref_sequence increment by ' || -nxt || ' minvalue 0';
					SELECT ref_sequence.NEXTVAL INTO nxt FROM dual;				--get the nextval to be 0

					EXECUTE IMMEDIATE 'alter sequence ref_sequence increment by 1 minvalue 0';

					--SELECT ref_sequence.NEXTVAL INTO nxt FROM dual;

				END IF;
			
				--CONTINUE 
				--get nextvalue from the sequence
				SELECT ref_sequence.NEXTVAL INTO nxt FROM dual;

				IF (nxt < 10) THEN
					--SELECT correspondenceid_seq into :NEW.correspondenceid from dual;
					:NEW.cckreference := '000' || nxt || '/' || mm || '/' || yy;
					RETURN;
				END IF;
				
				if (nxt < 100) then
					--SELECT correspondenceid_seq into :NEW.correspondenceid from dual;
					:NEW.cckreference := '00' || nxt || '/' || mm || '/' || yy;
					RETURN;
				end if;	
				
				if (nxt < 1000) then
					--SELECT correspondenceid_seq into :NEW.correspondenceid from dual;
					:NEW.cckreference := '0' || nxt || '/' || mm || '/' || yy;
					RETURN;
				end if;	
				
				--no leading zeros for values greater than 10,000
				:NEW.cckreference := to_char(nxt) || '/' || mm || '/' || yy;		

			ELSE	--IF INTERNAL
					
				--if its not equal to this month then this is a new entry of this month
				--therefore we RESET the sequence
				IF (lastaction != mm) THEN
					--we attempt to reset the sequence					
					SELECT internal_corr_sequence.NEXTVAL INTO nxt FROM dual;		--lets capture the next value and store it somewhere
					
					EXECUTE IMMEDIATE 'alter sequence internal_corr_sequence increment by ' || -nxt || ' minvalue 0'; --engage the REVERSE gear
					SELECT internal_corr_sequence.NEXTVAL INTO nxt FROM dual;								--move to 0
					
					EXECUTE IMMEDIATE 'alter sequence internal_corr_sequence increment by 1 minvalue 0';				--voila	
					
				END IF;
					
				--CONTINUE 
				--get nextvalue from the sequence
				SELECT internal_corr_sequence.NEXTVAL INTO nxt FROM dual;

				IF (nxt < 10) THEN
					--SELECT correspondenceid_seq into :NEW.correspondenceid from dual;
					:NEW.cckreference := '000' || nxt || '/<b>I</b>/' || mm || '/' || yy;
				ELSIF (nxt < 100) then
					--SELECT correspondenceid_seq into :NEW.correspondenceid from dual;
					:NEW.cckreference := '00' || nxt || '/<b>I</b>/' || mm || '/' || yy;
				ELSIF (nxt < 1000) then
					--SELECT correspondenceid_seq into :NEW.correspondenceid from dual;
					:NEW.cckreference := '0' || nxt || '/<b>I</b>/' || mm || '/' || yy;
				ELSE												
					--no leading zeros for values greater than 1000
					:NEW.cckreference := to_char(nxt) || '/<b>I</b>/' || mm || '/' || yy;		
				END IF;

			END IF;	

		END IF;	--IF FSM/ENGINEER
	end if; 
  
end;



CREATE TABLE client_license(
	client_license_id			integer primary key,
	parent_client_license_id	integer references client_license,	--just incase this is a convenience entry eg in case of additional frequency in a network
	status_license_id 			integer references status_license,	--this is more relevant at period_license
	client_id					integer references client,		--constraint removed
	license_id					integer references license,	

	clc_id 					integer references clc,			--first clc
	tac_id 					integer references tac,			--first tac

	license_number				varchar(120),


	is_rolled_out				char(1) default '0' not null,	

	
	purpose_of_license			clob,

	--APPROVE_EMAIL 			CHAR(1) DEFAULT '0',
	--REJECT_EMAIL  			CHAR(1) DEFAULT '0',
	--APPROVEd 					CHAR(1) DEFAULT '0',
	--REJECT_REASON 			CLOB,

	--email notices
	--FSM ?
	is_clc_email_sent				char(1) default '0' not null,	
	is_postclc_email_sent			char(1) default '0' not null,
	is_offer_email_sent				char(1) default '0' not null,
	is_initial_fee_email_sent		char(1) default '0' not null,	
	is_assignment_email_sent		char(1) default '0' not null,
	is_license_ready_email_sent		char(1) default '0' not null,
	is_renewal_reminder_email_sent	char(1) default '0' not null,	--license renewal reminder
	is_overdue_payment_email_sent	char(1) default '0' not null,	--overdue payment (expired license)
	is_acknowlegement_email_sent	char(1) default '0' not null,

	--LCS ?
	is_differal_email_sent 				char(1) default '0' not null,	
	is_gazettement_email_sent 			char(1) default '0' not null,	
	is_license_approval_email_sent 		char(1) default '0' not null,	
	is_compl_returnsQ_email_sent 		char(1) default '0' not null,	
	is_compl_returnsA_email_sent 		char(1) default '0' not null,	
	is_AAA_reminder_sent 				char(1) default '0' not null,	
	is_num_allocation_email_sent 	char(1) default '0' not null,	
	is_TA_certificate_email_sent		char(1) default '0' not null,		

	is_network_expansion				char(1) default '0' not null,	
	is_freq_expansion					char(1) default '0' not null,
	is_license_reinstatement			char(1) default '0' not null,

	is_exclusive_access				char(1) default '0' not null,
	exclusive_bw_MHz				real default 0,	

	--is_expansion					char(1) default '0' not null,			--is this an expanded network
	is_expansion_approved			char(1) default '0' not null,		--???
	skip_clc 						char(1) default '0' not null,			--manager may allow it to skip the CLC stage

	application_date				date default SYSDATE,
	offer_sent_date					date,
	
	offer_approved					char(1) default '0' not null,
	offer_approved_date				date,
	offer_approved_by				integer references entitys,

	license_date					date,
	license_start_date				date,
	license_stop_date				date,
	rejected_date					date,

	--approveUserid		integer,
	--rejectuserid		integer,
	--rolloutperiod		integer default 0,

	rollout_date			date,
	renewal_date			date,

	--expected.. is this real needed
	--expected_application_fee		real default 0 not null,
	--expected_initial_fee			real default 0 not null,
	--expected_annual_fee				real default 0 not null,
	--expected_agt_fee				real default 0 not null,
	--expected_type_approval_fee		real default 0 not null,	

	commitee_remarks		clob,
	secretariat_remarks		clob,

	

	--entity_id 				integer references entitys,

	remarks					clob,			
	details					clob
);

--workflow stuff
ALTER TABLE client_license ADD workflow_table_id integer;	--used to tie/locate all events in a workflow
ALTER TABLE client_license ADD is_workflow_complete CHAR(1) DEFAULT '0' NOT NULL;		--AKA approved/complete...
ALTER TABLE client_license ADD entered_by_id integer references entitys;
ALTER TABLE client_license ADD approve_status varchar(16) default 'Draft' not null;

ALTER TABLE client_license DROP COLUMN entered_by_id;
ALTER TABLE client_license ADD created date default SYSDATE;
ALTER TABLE client_license ADD created_by integer references entitys;		--INITIAL INSERT
ALTER TABLE client_license ADD updated date default SYSDATE;
ALTER TABLE client_license ADD updated_by integer references entitys;		--FOR UPDATE OPERATIONS (last updater)

ALTER TABLE client_license ADD contact_person_name		varchar(240);
ALTER TABLE client_license ADD contact_designation		varchar(240);	--this is actually the designation
ALTER TABLE client_license ADD contact_salutation		varchar(10); 			--either Sir, Madam
ALTER TABLE client_license ADD contact_department		varchar(240);			--dept in the clients company
ALTER TABLE client_license ADD letter_date				date;				--date on the application letter
ALTER TABLE client_license ADD letter_title 			varchar(100);		--title of the application letter
ALTER TABLE client_license ADD letter_ref				varchar(50);

ALTER TABLE client_license ADD category_applied	varchar(120);
ALTER TABLE client_license ADD category_recomm varchar(120);
ALTER TABLE client_license ADD category_approved varchar(120);

ALTER TABLE client_license ADD is_active char(1) default '0' not null;
ALTER TABLE client_license ADD is_offer_sent char(1) default '0' not null;
ALTER TABLE client_license ADD tac_approval_date date default sysdate;		
ALTER TABLE client_license ADD certification_date date;	

ALTER TABLE client_license ADD is_at_govt_printer 	char(1) default '0' not null;		--at govt printer now?
ALTER TABLE client_license ADD govt_forwared_date	date;		--date forwarded to govt printer
ALTER TABLE client_license ADD is_gazetted				char(1) default '0' not null;
ALTER TABLE client_license ADD is_gazetted_rejected		char(1) default '0' not null;
ALTER TABLE client_license ADD gazettement_date			date;		
ALTER TABLE client_license ADD gazettement_narrative	clob;
ALTER TABLE client_license ADD board_meeting_id 		integer references board_meeting;

ALTER TABLE client_license ADD ta_fee	real default 0 not null;

--CREATE INDEX clientlicenses_clientid ON clientlicenses (clientid);
--CREATE INDEX clientlicenses_licenseid ON clientlicenses (licenseid);
CREATE SEQUENCE client_license_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_client_license_id BEFORE INSERT ON client_license
for each row 
begin     
	if inserting then 
		if :NEW.client_license_id is null then
			SELECT client_license_id_seq.nextval into :NEW.client_license_id from dual;
		end if;
	
		SELECT workflow_table_id_seq.nextval into :NEW.workflow_table_id from dual;

	end if; 
end;
/

--APPLICATION DOCUMENTS
CREATE TABLE client_license_doc (
	client_license_doc_id		integer primary key,
	client_license_id			integer references client_license,
	doc_name					varchar(50),
	doc_url						varchar(200),

	narrative					clob,

	date_created 				date default SYSDATE,
	date_updated 				date default SYSDATE,
	created_by					integer references entitys,
	updated_by					integer references entitys
	);

ALTER TABLE client_license_doc ADD dms_link AS ('<a href=' || doc_url || '>' || doc_name || '</a>'); 	

CREATE SEQUENCE client_license_doc_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_client_license_doc_id BEFORE INSERT ON client_license_doc
for each row 
begin     
	if inserting then 
		if :NEW.client_license_doc_id is null then
			SELECT client_license_doc_id_seq.nextval into :NEW.client_license_doc_id from dual;
		end if;
	end if; 
end;
/



--header
CREATE TABLE license_payment_header(
	license_payment_header_id	integer primary key,
	--period_id					varchar(12) references period,
	
	workflow_phase_id		integer references workflow_phases,
	client_license_id		integer references client_license,	

	is_sales_order_done		char(1) default '0' not null,
	order_number			varchar(50),

	is_invoice_done			char(1) default '0' not null,
	invoice_date			date,
	invoice_number 			varchar(32),
	invoice_amount			real,

	is_paid					char(1) default '0' not null,
	is_void					char(1) default '0' not null,		--cancelled when a correction order is sent (by trigger or otherwise)

	receipt_number 			VARCHAR2(32 BYTE), 
	receipt_amount 			FLOAT(126), 

	details					clob
);
ALTER TABLE license_payment_header ADD description VARCHAR(2000);
ALTER TABLE license_payment_header ADD workflow_table_id integer;	--used to tie/locate all events in a workflow
ALTER TABLE license_payment_header ADD period_id integer references period;
ALTER TABLE license_payment_header ADD created date default SYSDATE;
ALTER TABLE license_payment_header ADD created_by integer references entitys;		--INITIAL INSERT
ALTER TABLE license_payment_header ADD updated date default SYSDATE;
ALTER TABLE license_payment_header ADD updated_by integer references entitys;		--FOR UPDATE OPERATIONS (last updater)
ALTER TABLE license_payment_header ADD period_license_id integer references period_license;

ALTER TABLE license_payment_header ADD receipt_date date;
ALTER TABLE license_payment_header DROP COLUMN order_summary;
ALTER TABLE license_payment_header ADD order_summary AS ('Order No: ' || COALESCE(to_char(license_payment_header_id),'NONE'));
ALTER TABLE license_payment_header ADD invoice_summary AS ('Invoice No: ' || COALESCE(invoice_number,'NOT INVOICED') || ', Date: ' || invoice_date);
ALTER TABLE license_payment_header DROP COLUMN receipt_summary;
ALTER TABLE license_payment_header ADD receipt_summary AS (DECODE(IS_PAID,'1','PAID','NOT PAID') || ', Date: ' || invoice_date);

ALTER TABLE license_payment_header ADD outstanding_amount real default 0 not null;

CREATE SEQUENCE license_payment_header_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_license_payment_header_id BEFORE INSERT ON license_payment_header
for each row 
begin     
	if inserting then 
		if :NEW.license_payment_header_id is null then
			SELECT license_payment_header_id_seq.nextval into :NEW.license_payment_header_id  from dual;
			:NEW.order_number := :NEW.license_payment_header_id;
		end if;
	end if; 
end;
/



CREATE OR REPLACE TRIGGER tr_ins_erp_c_order AFTER INSERT ON license_payment_header
   FOR EACH ROW 
DECLARE
	--PRAGMA AUTONOMOUS_TRANSACTION;
	cli_id	INTEGER;
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
				'CO','--','CB6EEA256BBC41109911215C5A14D39B','CB6EEA256BBC41109911215C5A14D39B',:NEW.created,
				cli_id,cli_id,cli_id,:NEW.created,:NEW.created,
				'N','N','N','266','P',
				'N','A3522D4BAE364E7287C6F43BB616671E','I','A','I','P','5',
				'5C588DBEC3F0419BB14FB0EF01F6AA3F','CC7FACC20D1042BEB226504DAD5ADFFF','N','N');
	--COMMIT;
END;
/
--ALTER TRIGGER tr_ins_erp_c_order DISABLE;


--lines
CREATE TABLE license_payment_line(
	license_payment_line_id			integer primary key,
	license_payment_header_id 		integer references license_payment_header,
	
	product_code					varchar (32),
	description						varchar(2000),
		
	amount				real not null,
	
	details				clob
);
ALTER TABLE license_payment_line ADD created date default SYSDATE;
ALTER TABLE license_payment_line ADD created_by integer references entitys;		--INITIAL INSERT
ALTER TABLE license_payment_line ADD updated date default SYSDATE;
ALTER TABLE license_payment_line ADD updated_by integer references entitys;		--FOR UPDATE OPERATIONS (last updater)


CREATE SEQUENCE license_payment_line_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_license_payment_line_id BEFORE INSERT ON license_payment_line
for each row 
begin     
	if inserting then 
		if :NEW.license_payment_line_id  is null then
			SELECT license_payment_line_id_seq.nextval into :NEW.license_payment_line_id  from dual;
		end if;
	end if; 
end;
/


      

CREATE OR REPLACE TRIGGER tr_ins_erp_c_order_line AFTER INSERT ON license_payment_line
   FOR EACH ROW 
DECLARE
	--PRAGMA AUTONOMOUS_TRANSACTION;
	cli_id 	INTEGER;	
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
			c_tax_id, EM_CM_ISORD)
      
		VALUES
    
			(:NEW.license_payment_line_id,'52C09F118D974F2D880F85811017B8BF','E3F7A3865F594647A5594F01E4CCC9C6',
			'Y',:NEW.created,'0',:NEW.created,'0',
			:NEW.license_payment_header_id,:NEW.description,1,cli_id,cli_id,
			:NEW.created,:NEW.created,:NEW.product_code,'5C588DBEC3F0419BB14FB0EF01F6AA3F',100,
			1, 0, 0, 0, 266,
			0,0,:NEW.amount,0, :NEW.amount, :NEW.amount,
			'E5C48E7815C84416887520D82A2B1C9B','Y');		
		--COMMIT;

		UPDATE license_payment_header SET outstanding_amount = outstanding_amount + :NEW.amount WHERE license_payment_header_id = :NEW.license_payment_header_id;
END;
/
--ALTER TRIGGER tr_ins_erp_c_order_line DISABLE;


CREATE OR REPLACE TRIGGER tr_start_workflow AFTER INSERT ON client_license
   FOR EACH ROW 
DECLARE
	wfid 	INTEGER;
	apprid	INTEGER;
	appr_group			integer;
BEGIN  

	wfid := :NEW.workflow_table_id;

	SELECT seq_approval_group.nextval INTO appr_group FROM dual;


	--INSERT THE FIRST APPROVALS to all the relevant entities
	INSERT INTO approvals (workflow_phase_id, approval_group,table_name, table_id, org_entity_id, app_entity_id, escalation_days, escalation_hours, approval_level, approval_narrative, to_be_done)
	SELECT workflow_phases.workflow_phase_id, appr_group, 'CLIENT_LICENSE', wfid, :NEW.created_by, entity_subscriptions.entity_id, 0, 3, 1, workflow_phases.phase_narrative, 'Approve - ' || workflow_phases.phase_narrative
	FROM workflow_phases INNER JOIN entity_subscriptions ON workflow_phases.approval_entity_id = entity_subscriptions.entity_type_id
	INNER JOIN workflows ON workflow_phases.workflow_id = workflows.workflow_id
	WHERE (workflows.table_name = 'LICENSE') AND (workflows.table_link_id = TO_CHAR(:NEW.LICENSE_ID)) AND (workflow_phases.is_utility = '0') AND (workflow_phases.approval_level='1')
	ORDER BY workflow_phases.approval_level, workflow_phases.workflow_phase_id;
	
	--... and checklists for the first level	
	INSERT INTO approval_checklists (checklist_id,workflow_table_id)
	SELECT checklist_id, wfid
	FROM checklists INNER JOIN workflow_phases ON checklists.workflow_phase_id = workflow_phases.workflow_phase_id
		INNER JOIN workflows ON workflow_phases.workflow_id = workflows.workflow_id
	WHERE (workflows.table_name = 'LICENSE') AND workflows.table_link_id = :NEW.LICENSE_ID AND (workflow_phases.approval_level='1')
    ORDER BY workflow_phases.approval_level, workflow_phases.workflow_phase_id;

	--ACKNOWLEDGE APPLICATION
	INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type) VALUES (2, wfid, 'CLIENT_LICENSE', 5);

	--FOR TYPE APPROVAL WE INITIALIZE EQUIPMENT
	IF(:NEW.license_id IN (162,163,164)) THEN		--individual or marketing
		INSERT INTO equipment_approval(client_license_id,manufacturer,make,model) values (:NEW.client_license_id,'UNDEFINED MANUFACTURER','A MAKE','A MODEL');
	END IF;

END;
/







--phases for each particular application.. this may be deprecated by use of workflow phases
--#DEPRECATED
-- CREATE TABLE client_phase(
-- 	client_phase_id		integer primary key,
-- 	--clientformtypeid	integer references clientformtypes,
-- 	client_license_id	integer references client_license,
-- 	--clientid		integer references clients,
-- 	license_phase_id	integer references license_phase,
-- 	--scheduleID		integer references schedules,
-- 
-- 	--userid		integer references users,
-- 
-- 	--clientapplevel	integer ,
-- 	--clientphasename	varchar(120),
-- 	--userid		integer references users,
-- 	--escalationtime	integer default 2 not null,
-- 
-- 	is_done			char(1) default '0' not null,	--done seeking approval by a manager or licensing officer. especially in the checking phase
-- 
-- 	is_approved			char(1) default '0' not null,	--approved by a licensing officer in case of checking phases, among others
-- 	is_rejected			char(1) default '0' not null,
-- 	is_deffered			char(1) default '0' not null ,
-- 	is_pending			char(1) default '0' not null ,		--workflow (or work in progress)
-- 	is_withdrawn		char(1) default '0' not null ,
-- 	
-- 
-- 	--for cases where additional approval is required eg after board....
-- 	is_mgr_approved		char(1) default '0' not null,
-- 	is_ad_approved		char(1) default '0' not null,
-- 	is_dir_approved		char(1) default '0' not null,
-- 	is_dg_approved		char(1) default '0' not null,
-- 
-- 	narrative			varchar(240),
-- 	is_paid 			char(1) default '0' not null,
-- 	remarks				clob,
-- 	details				clob
-- );
-- 	--syntax:			column_name [datatype] [GENERATED ALWAYS] AS [expression] [VIRTUAL]
-- 	--formula_expression  NUMBER GENERATED ALWAYS AS (ROUND(salary*(1+comm2/100),2)) VIRTUAL,
-- 	
-- 
-- --ALTER TABLE client_phase ADD phase_status VARCHAR(20) GENERATED ALWAYS AS DECODE(is_approved,'1','Approved',DECODE(is_rejected,'1','Application Rejected',DECODE(is_pending,'1','Pending. being addressed','UNKNOWN'))) VIRTUAL;
-- ALTER TABLE client_phase ADD workflow_table_id	integer;		--this is the identifier of the (entire) workflow. this id is propagated to all approvals so that we can establish linkages
-- ALTER TABLE client_phase ADD created date default SYSDATE;
-- ALTER TABLE client_phase ADD created_by	integer references entitys;		--INITIAL INSERT
-- ALTER TABLE client_phase ADD updated date default SYSDATE;
-- ALTER TABLE client_phase ADD updated_by integer references entitys;		--FOR UPDATE OPERATIONS (last updater)
-- --ALTER TABLE client_phase ADD userid	integer references entitys;
-- 
-- -- CREATE INDEX clientphases_clientformtypeid ON clientphases (clientformtypeid);
-- -- CREATE INDEX clientphases_phaseid ON clientphases (phaseid);
-- -- CREATE INDEX clientphases_userid ON clientphases (userid);
-- -- CREATE INDEX clientphases_clientlicenseid ON clientphases (clientlicenseid);
-- CREATE SEQUENCE client_phase_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
-- 
-- CREATE OR REPLACE TRIGGER tr_client_phase_id BEFORE INSERT ON client_phase
-- for each row
-- 	begin
-- 	if inserting then
-- 		if :NEW.client_phase_id is null then
-- 			SELECT client_phase_id_seq.nextval into :NEW.client_phase_id from dual;
-- 		end if;
-- 	end if;
-- end;
-- /
-- 
-- 
-- CREATE OR REPLACE TRIGGER tr_ins_client_checklist AFTER INSERT ON client_phase
--    FOR EACH ROW 
-- DECLARE
-- 
-- BEGIN  
-- 	--phase checklists
-- 	INSERT INTO client_checklist(client_phase_id, phase_checklist_id)
-- 	      SELECT :NEW.client_phase_id, phase_checklist_id
-- 		      FROM phase_checklist WHERE license_phase_id = :NEW.license_phase_id;
-- 		      --ORDER BY phase_level;			
-- 	--COMMIT;
-- END;
-- /


--we need to know the person to address all correspondence regarding a particular application
-- CREATE TABLE contact_person(
-- 	contact_person_id		integer primary key,
-- 	client_license_id		integer references client_license,		--constraint removed
-- 	sys_country_id				char(2) default 'KE' references sys_countrys,
--   
-- 	id_type_id 				integer references id_type,
-- 	id_number				varchar(50),
-- 	contact_person_name		varchar(240),
-- 	designation				varchar(240),	--this is actually the designation
-- 	salutation				varchar(10), 			--either Sir, Madam
-- 	department				varchar(240),			--dept in the clients company
-- 
-- 	letter_date				date,				--date on the application letter
-- 	letter_title 			varchar(100),		--title of the application letter
-- 	letter_ref				varchar(50),
-- 	details					clob
-- );
-- 
-- CREATE SEQUENCE contact_person_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
-- CREATE OR REPLACE TRIGGER tr_contact_person_id BEFORE INSERT ON contact_person
-- for each row 
-- begin     
-- 	if inserting then 
-- 		if :NEW.contact_person_id is null then
-- 			SELECT contact_person_id_seq.nextval into :NEW.contact_person_id from dual;
-- 		end if;
-- 	end if; 
-- end;
-- /
-- DROP TABLE contact_person;		--DROP OR USE IT DIFFERENTLY

---(HISTORY) changing statuses of client's and their licenses AKA history
CREATE TABLE client_license_status(
	client_license_status_id	integer primary key,	
	client_license_id			integer references client_license,

	status_license_id			integer references status_license,		--this is actualy status of client_license
		
	date_created 				date default SYSDATE,
	date_updated 				date default SYSDATE,
	created_by					integer references entitys,
	updated_by					integer references entitys
	);
ALTER TABLE client_license_status ADD period_id integer references period;
ALTER TABLE client_license_status ADD status_client_id integer references status_client;

CREATE SEQUENCE client_license_status_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_client_license_status_id BEFORE INSERT ON client_license_status
for each row 
begin     
	if inserting then 
		if :NEW.client_license_status_id is null then
			SELECT client_license_status_id_seq.nextval into :NEW.client_license_status_id from dual;
		end if;
	end if; 
end;
/



--utility.. in case an application goes thru more than one clc
CREATE TABLE clc_history(
	clc_history_id		integer primary key,
	client_license_id 	integer references client_license,	
	clc_id				integer references clc	
	);
CREATE INDEX clc_history_cli_lic_id ON clc_history(client_license_id);
ALTER TABLE clc_history ADD	is_approved	char(1) default '0' not null;
ALTER TABLE clc_history ADD	is_rejected	char(1) default '0' not null;
ALTER TABLE clc_history ADD	is_differed	char(1) default '0' not null;
ALTER TABLE clc_history ADD	is_withdrawn char(1) default '0' not null;

CREATE SEQUENCE clc_history_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_clc_history_id BEFORE INSERT ON clc_history
for each row 
begin     
	if inserting then 
		if :NEW.clc_history_id is null then
			SELECT clc_history_id_seq.nextval into :NEW.clc_history_id from dual;
		end if;
	end if; 
end;
/





--utility.. in case an application goes thru more than one clc
CREATE TABLE tac_history(
	tac_history_id		integer primary key,
	client_license_id 	integer references client_license,	
	tac_id				integer references tac	
	);
CREATE SEQUENCE tac_history_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_tac_history_id BEFORE INSERT ON tac_history
for each row 
begin     
	if inserting then 
		if :NEW.tac_history_id is null then
			SELECT tac_history_id_seq.nextval into :NEW.tac_history_id from dual;
		end if;
	end if; 
end;
/


---changing statuses of client's license AKA history
CREATE TABLE client_license_status(
	client_license_status_id	integer primary key,
	client_license_id			integer references client_license,
	status_license_id			integer references status_license,
	
	date_created 			date default SYSDATE,
	date_updated 			date default SYSDATE,
	created_by			integer references entitys,
	updated_by			integer references entitys
	);
CREATE SEQUENCE client_license_status_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_client_license_status_id BEFORE INSERT ON client_license_status
for each row 
begin     
	if inserting then 
		if :NEW.client_license_status_id is null then
			SELECT client_license_status_id_seq.nextval into :NEW.client_license_status_id from dual;
		end if;
	end if; 
end;
/



--utility.. in case an application goes thru more than one clc
CREATE TABLE clc_history(
	clc_history_id		integer primary key,
	client_license_id 	integer references client_license,	
	clc_id				integer references clc	
	);


-- CREATE TABLE client_checklist(
-- 	client_checklist_id	integer primary key,
-- 	client_license_id	integer references client_license,
-- 	phase_checklist_id	integer references phase_checklist, 
-- 
-- 	entity_id			integer references entitys,
-- 	checklist_level		integer,
-- 	
-- 	is_approved			char(1) default '0' not null,
-- 	is_rejected			char(1) default '0' not null,
-- 	is_ignored			char(1) default '0' not null,		--if xponding checklist
-- 
-- 	actiondate			timestamp,
-- 	narrative			varchar(240),
-- 	details				clob
-- );
-- ALTER TABLE client_checklist ADD is_pending	char(1) default '0' not null;
-- ALTER TABLE client_checklist DROP COLUMN client_license_id;
-- ALTER TABLE client_checklist ADD client_phase_id INTEGER REFERENCES client_phase;
-- --CREATE INDEX clientchecklists_clientphaseid ON clientchecklists (clientphaseid);
-- --CREATE INDEX clientchecklists_checklistid ON clientchecklists (checklistid);
-- --CREATE INDEX clientchecklists_userid ON clientchecklists (userid);
-- CREATE SEQUENCE client_checklist_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
-- CREATE OR REPLACE TRIGGER tr_client_checklist_id BEFORE INSERT ON client_checklist
-- for each row 
-- begin     
-- 	if inserting then 
-- 		if :NEW.client_checklist_id is null then
-- 			SELECT client_checklist_id_seq.nextval into :NEW.client_checklist_id from dual;
-- 		end if;
-- 	end if; 
-- end;
-- /




-- provinces
CREATE TABLE region (
	region_id 	integer primary key,
	region_name	varchar(120),
	is_active		char(1) default '1' not null,
	details 		clob
	);

CREATE SEQUENCE region_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_region_id BEFORE INSERT ON region
for each row 
begin     
	if inserting then 
		if :NEW.region_id  is null then
			SELECT region_id_seq.nextval into :NEW.region_id  from dual;
		end if;
	end if; 
end;
/


--these are the general schedules linked to specific team/department?
CREATE TABLE schedule(
	schedule_id 	  	integer primary key,
	schedule_name 		varchar(120),
	--period_id			integer references period,
	--correspondenceid	integer references correspondence,
	department_id		integer references department,	
	workflow_table_id 	integer,				--the w/f before it gets approved for use

	--forfsm				char(1) default '0' not null,
	--forlcs				char(1) default '0' not null,

	annual			    char(1) default '0' not null,
	adhoc			     char(1) default '0' not null,
	
	is_approved		  char(1) default '0' not null,
	is_complete		  char(1) default '0' not null,
	is_active		    char(1) default '0' not null,

	--entrydate		date default sysdate not null,
	details			clob
	);
ALTER TABLE schedule ADD period_id INTEGER REFERENCES period;
ALTER TABLE schedule ADD schedule_type	varchar(10);
CREATE INDEX schedule_workflow_table_id ON schedule (workflow_table_id);
CREATE SEQUENCE schedule_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
create or replace TRIGGER tr_schedule_id BEFORE INSERT ON schedule
for each row 
begin     
	if inserting then 
		if :NEW.schedule_id is null then
			SELECT schedule_id_seq.nextval into :NEW.schedule_id from dual;
		end if;

		SELECT workflow_table_id_seq.nextval into :NEW.workflow_table_id from dual;
	end if; 
end;
/

create or replace TRIGGER tr_sch_workflow AFTER INSERT ON schedule FOR EACH ROW 
DECLARE
	wfid 	INTEGER;
	apprid	INTEGER;
	orgid 	INTEGER;
	appr_group	INTEGER;
BEGIN  
	--SELECT workflow_table_id_seq.nextval into wfid from dual;		--this has bn taken care of at BEFORE INSERT
	wfid := :NEW.workflow_table_id;		
	SELECT seq_approval_group.nextval INTO appr_group FROM dual;

	--identify wether FSM or LCS
	SELECT department.org_id INTO orgid 
	FROM department 
	WHERE department_id = :NEW.department_id;

	--INSERT THE FIRST APPROVALS to all the relevant entities
	INSERT INTO approvals (workflow_phase_id, approval_group, table_name, table_id, org_entity_id, app_entity_id, escalation_days, escalation_hours, approval_level, approval_narrative, to_be_done)
	SELECT workflow_phases.workflow_phase_id, appr_group, 'SCHEDULE', wfid, :NEW.created_by, entity_subscriptions.entity_id, 0, 3, 1, workflow_phases.phase_narrative, 'To do - ' || workflow_phases.phase_narrative				
		FROM workflow_phases				
		INNER JOIN entity_subscriptions ON workflow_phases.approval_entity_id = entity_subscriptions.entity_type_id
		INNER JOIN workflows ON workflow_phases.workflow_id = workflows.workflow_id
		WHERE (workflows.table_name = 'SCHEDULE') AND (workflows.table_link_id = orgid)
		AND (workflow_phases.is_utility = '0') AND (workflow_phases.approval_level='1')
		ORDER BY workflow_phases.approval_level, workflow_phases.workflow_phase_id;
	
END;
/



CREATE TABLE inspection_type(
	inspection_type_id		integer primary key,
	inspection_type_name	varchar(50),
	details					clob
	);
CREATE SEQUENCE inspection_type_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_inspection_type_id BEFORE INSERT ON inspection_type
for each row 
begin     
	if inserting then 
		if :NEW.inspection_type_id is null then
			SELECT inspection_type_id_seq.nextval into :NEW.inspection_type_id from dual;
		end if;
	end if; 
end;
/



--quarter heading.. specific schedules within a wider/annual/ schedule defined above
--can be for fmi(as fmischedule), compliance, cert?
CREATE TABLE sub_schedule (
	sub_schedule_id 	integer primary key, 
	--USERID			integer references entitys,
	schedule_id			integer references schedule, 
	sub_schedule_name	varchar(120), 	
	
	region_specific		clob,	--specific regions
	
	--approved			char(1) default '0' not null,
	inspections_to_do	varchar(120),
	general_req			varchar(120),
	
	start_date			date, 
	end_date			date, 

	workflow_table_id 	integer,				--the w/f before it gets approved for use

	--quarter_id		integer references quarter,			--contentious .. it seems a schedule can span more than one quarter
	is_complete 		char(1) default '0' not null, 
	is_quarter_1 		char(1) default '0' not null, 
	is_quarter_2 		char(1) default '0' not null, 
	is_quarter_3 		char(1) default '0' not null, 
	is_quarter_4 		char(1) default '0' not null,	

	is_approved			char(1) default '0' not null, 		--is_worfklow_complete will update this during the final wfphase

	--is_processed		 	char(1) default '0' not null,
	details					clob
	);
ALTER TABLE sub_schedule ADD region_id integer references region;		--wider region
ALTER TABLE sub_schedule ADD created_by integer references entitys;
ALTER TABLE sub_schedule ADD created date default sysdate;
ALTER TABLE sub_schedule ADD is_workflow_complete CHAR(1) DEFAULT '0' NOT NULL;		--AKA approved...
ALTER TABLE sub_schedule ADD inspection_type_id integer references inspection_type;

CREATE SEQUENCE sub_schedule_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_sub_schedule_id BEFORE INSERT ON sub_schedule
for each row 
begin     
	if inserting then 
		if :NEW.sub_schedule_id  is null then
			SELECT sub_schedule_id_seq.nextval into :NEW.sub_schedule_id  from dual;
		end if;

		SELECT workflow_table_id_seq.nextval into :NEW.workflow_table_id from dual;

	end if; 
end;
/


--ALL SCHEDULES NEED TO BE APPROVED BY LINE MANAGERS BEFORE THEY CAN BE USED..THEY ALL USE A SINGLE WORKFLOW
CREATE OR REPLACE TRIGGER tr_sub_sch_workflow AFTER INSERT ON sub_schedule
   FOR EACH ROW 
DECLARE
	wfid 	INTEGER;
	apprid	INTEGER;
	orgid 	INTEGER;
	appr_group	INTEGER;
BEGIN  
	--SELECT workflow_table_id_seq.nextval into wfid from dual;		--this has bn taken care of at BEFORE INSERT
	wfid := :NEW.workflow_table_id;		
	SELECT seq_approval_group.nextval INTO appr_group FROM dual;

	--identify wether FSM or LCS
	SELECT department.org_id INTO orgid 
	FROM department
	INNER JOIN schedule ON department.department_id = schedule.department_id
	WHERE schedule.schedule_id = :NEW.schedule_id;

	--SELECT seq_approval_id.nextval into apprid from dual;

	--INSERT THE FIRST APPROVALS to all the relevant entities
	INSERT INTO approvals (workflow_phase_id, approval_group, table_name, table_id, org_entity_id, app_entity_id, escalation_days, escalation_hours, approval_level, approval_narrative, to_be_done)
	SELECT workflow_phases.workflow_phase_id, appr_group, 'SUB_SCHEDULE', wfid, :NEW.created_by, entity_subscriptions.entity_id, 0, 3, 1, workflow_phases.phase_narrative, 'To do - ' || workflow_phases.phase_narrative				
			FROM workflow_phases				
			INNER JOIN entity_subscriptions ON workflow_phases.approval_entity_id = entity_subscriptions.entity_type_id
			INNER JOIN workflows ON workflow_phases.workflow_id = workflows.workflow_id
			WHERE (workflows.table_name = 'SUB_SCHEDULE') AND (workflows.table_link_id = orgid)
			AND (workflow_phases.is_utility = '0') AND (workflow_phases.approval_level='1')
			ORDER BY workflow_phases.approval_level, workflow_phases.workflow_phase_id;
	
/*
	--... and checklists for the first level	
	INSERT INTO approval_checklists (checklist_id,workflow_table_id)
		SELECT checklist_id,wfid
		FROM checklists
			INNER JOIN workflow_phases ON checklists.workflow_phase_id = workflow_phases.workflow_phase_id
			INNER JOIN workflows ON workflow_phases.workflow_id = workflows.workflow_id
			WHERE (workflows.table_name = 'SUB_SCHEDULE') AND (workflows.table_link_id = orgid)
			AND (workflow_phases.is_utility = '0') AND (workflow_phases.approval_level='1')
      ORDER BY workflow_phases.approval_level, workflow_phases.workflow_phase_id;
			*/

END;
/



--participants for sub schedules
CREATE TABLE schedule_participant (
	schedule_participant_id		integer primary key,	
	sub_schedule_id	    		integer references sub_schedule,
	
	entity_id					integer references entitys,		--participant	
	participant_role			varchar(100),
	cost_per_diem				real,	
	remarks			      		clob
);
CREATE SEQUENCE schedule_participant_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_schedule_participant_id BEFORE INSERT ON schedule_participant
for each row 
begin     
	if inserting then 
		if :NEW.schedule_participant_id  is null then
			SELECT schedule_participant_id_seq.nextval into :NEW.schedule_participant_id  from dual;
		end if;
	end if; 
end;
/



CREATE TABLE schedule_resource (
	schedule_resource_id		integer primary key,	
	schedule_resource_name		varchar(50),
	sub_schedule_id	    		integer references sub_schedule,		
	resource_cost				real,	
	remarks			      		clob
);
CREATE SEQUENCE schedule_resource_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_schedule_resource_id BEFORE INSERT ON schedule_resource
for each row 
begin     
	if inserting then 
		if :NEW.schedule_resource_id  is null then
			SELECT schedule_resource_id_seq.nextval into :NEW.schedule_resource_id  from dual;
		end if;
	end if; 
end;
/




--WETHER FM/TV OR RADIO NETWORK INSPECTION
CREATE TABLE inspection_item(
	inspection_item_id		integer primary key,
	inspection_item_name	varchar(50),
	details 				clob
	);
CREATE SEQUENCE inspection_item_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_inspection_item_id BEFORE INSERT ON inspection_item
for each row 
begin     
	if inserting then 
		if :NEW.inspection_item_id is null then
			SELECT inspection_item_id_seq.nextval into :NEW.inspection_item_id from dual;
		end if;
	end if; 
end;
/
INSERT INTO inspection_item(inspection_item_id,inspection_item_name) VALUES(1,'FM-TV Inspection');
INSERT INTO inspection_item(inspection_item_id,inspection_item_name) VALUES(2,'Radio Network Inspection');
COMMIT;


--type of compliance
CREATE TABLE activity_type(
		activity_type_id	 	integer primary key,
		activity_type_name	varchar(50),
		workflow_table_id 		integer,				--desired workflow
		details					clob
		);
CREATE SEQUENCE activity_type_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_activity_type_id BEFORE INSERT ON activity_type
for each row 
begin     
	if inserting then 
		if :NEW.activity_type_id is null then
			SELECT activity_type_id_seq.nextval into :NEW.activity_type_id from dual;
		end if;
	end if; 
end;
/
INSERT INTO activity_type(activity_type_id,activity_type_name) VALUES(1,'Interference Resolution');
INSERT INTO activity_type(activity_type_id,activity_type_name) VALUES(2,'Frequency Monitoring');
INSERT INTO activity_type(activity_type_id,activity_type_name) VALUES(3,'Frequency Inspection');
INSERT INTO activity_type(activity_type_id,activity_type_name) VALUES(4,'Maintenance And Calibration');
INSERT INTO activity_type(activity_type_id,activity_type_name) VALUES(5,'RSMS Station Maintenance');
INSERT INTO activity_type(activity_type_id,activity_type_name) VALUES(6,'General Inspection');
--general violation
COMMIT;


--wether or not occupancy/clearance, surveilance or measurement
CREATE TABLE monitoring_type(
	monitoring_type_id		integer primary key,
	monitoring_type_name	varchar(200),
	details					clob
	);
CREATE SEQUENCE monitoring_type_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_monitoring_type_id BEFORE INSERT ON monitoring_type
for each row 
begin     
	if inserting then 
		if :NEW.monitoring_type_id is null then
			SELECT monitoring_type_id_seq.nextval into :NEW.monitoring_type_id from dual;
		end if;
	end if; 
end;
/
INSERT INTO monitoring_type(monitoring_type_name) VALUES('Occupancy (Clearance)');
INSERT INTO monitoring_type(monitoring_type_name) VALUES('Surveillance');
INSERT INTO monitoring_type(monitoring_type_name) VALUES('Measurement Task');
COMMIT;


--ACTUAL INSEPCTIONS DONE BY EITHER FMI OR LCS
--also replaces fmitasks,clientinspection
CREATE TABLE client_inspection(
	client_inspection_id	integer primary key,
	activity_type_id		integer references activity_type,
	monitoring_type_id		integer references monitoring_type,	--references monitoringtype
	sub_schedule_id			integer references sub_schedule,		--schedule
	inspection_item_id		integer references inspection_item,		--tv/radio or network

	--userid				    integer references users,
	--clientid				  integer references clients,		--accused ??
	--raisedby 				  integer references users,		--for inspection
	--linkfmitaskid			integer,
	--periodlicenseid		integer,  -- references periodlicenses,

	complainant_name		varchar(50),
	complainant_address		varchar(50),
	complainant_fax			varchar(50),
	complainant_telephone	varchar(50),
	complainant_email		varchar(50),
	contact_person			varchar(200),

	request_url				    varchar(200),
	report_url				    varchar(200),

	--assignto				    integer references users,
	--assigndate			    date,	

	application_date		date default sysdate,
	--forinspection			char(1) default '0',
	--forinteference		char(1) default '0',
	--formonitoring			char(1) default '0',

	--forlcs				char(1) default '0',
	--forfsm				char(1) default '0',

	document				  blob,
	attachment				blob,

	band					      char(1) default '1',
	is_descreet_freq		char(1) default '1',

	band_from				varchar(50),
	band_to					varchar(50),
	frequency				varchar(50),
	bandwidth				varchar(50),

	type_of_device			varchar(50),
	location				    varchar(50),
	suspected_source		varchar(50),
	letter_date				date,
	interference_timing		varchar(50),
	monitoring_period		varchar(50),
	interference_desc		clob,

	participants			varchar(200),			--the sub-schedule will have individual participants.. here we use just a list.. redundant????
	violation				  clob,
	findings				  clob,
	observations			clob,
	complaint				clob,
	casenumber				varchar(50),
	recommendation			clob,
	conclusions				clob,

	details					clob
	);
ALTER TABLE client_inspection ADD created DATE DEFAULT SYSDATE;
ALTER TABLE client_inspection ADD created_by integer references entitys;
ALTER TABLE client_inspection ADD workflow_table_id integer;	--used to tie/locate all events in a workflow
ALTER TABLE client_inspection ADD is_workflow_complete CHAR(1) DEFAULT '0' NOT NULL;		--AKA approved/complete...
ALTER TABLE client_inspection ADD client_id	integer references client;
ALTER TABLE client_inspection ADD purpose_of_inspection clob;

ALTER TABLE client_inspection ADD inspection_date date;
ALTER TABLE client_inspection ADD is_fully_compliant char(1) default '1' not null;

--FM TV INSPECTION
ALTER TABLE client_inspection ADD site_name	varchar(150);

ALTER TABLE client_inspection ADD longitude_degrees	real check(longitude_degrees < 360);
ALTER TABLE client_inspection ADD longitude_minutes	real check(longitude_minutes < 60);
ALTER TABLE client_inspection ADD longitude_seconds	real check(longitude_seconds < 60);

ALTER TABLE client_inspection ADD latitude_degrees real check(latitude_degrees < 360);
ALTER TABLE client_inspection ADD latitude_minutes real check(latitude_minutes < 60);
ALTER TABLE client_inspection ADD latitude_seconds real check(latitude_seconds < 60);

ALTER TABLE client_inspection ADD address 		varchar(150);
ALTER TABLE client_inspection ADD asl_meters 	real;
ALTER TABLE client_inspection ADD land_owner 	varchar(150);
ALTER TABLE client_inspection ADD other_telkom_operators 	varchar(500);

ALTER TABLE client_inspection ADD technical_personnel	varchar(150);		--responsible for maintenance

--END

--FM TV TOWERS
ALTER TABLE client_inspection ADD	tower_owner				varchar(150);
ALTER TABLE client_inspection ADD	height_above_ground		real;
ALTER TABLE client_inspection ADD	height_of_building		real;
ALTER TABLE client_inspection ADD	tower_type				varchar(50);
ALTER TABLE client_inspection ADD	rust_protection			varchar(50);
ALTER TABLE client_inspection ADD	tower_instal_date		date;
ALTER TABLE client_inspection ADD	tower_manufacturer		varchar(50);
ALTER TABLE client_inspection ADD	model_number			varchar(50);
ALTER TABLE client_inspection ADD	max_wind_load			real;		--km/h
ALTER TABLE client_inspection ADD	max_load_charge_kg		real;		--kg
ALTER TABLE client_inspection ADD	tower_insurer			varchar(50);

ALTER TABLE client_inspection ADD	has_concrete_base			char(1);
ALTER TABLE client_inspection ADD	has_lightning_protection	char(1);
ALTER TABLE client_inspection ADD	has_grounding				char(1);
ALTER TABLE client_inspection ADD	has_aviation_warning		char(1);
ALTER TABLE client_inspection ADD	other_antennas				varchar(50);

--FM TV ANTENNA
ALTER TABLE client_inspection ADD	type_of_antenna			varchar(50);
ALTER TABLE client_inspection ADD	antenna_manufacturer	varchar(50);
ALTER TABLE client_inspection ADD	antenna_model			varchar(50);
ALTER TABLE client_inspection ADD	antenna_catalog_url		varchar(500);

ALTER TABLE client_inspection ADD	H_is_omni_directional	char(1);
ALTER TABLE client_inspection ADD	H_is_directional		char(1);
ALTER TABLE client_inspection ADD	H_beamwidth				varchar(50);
ALTER TABLE client_inspection ADD	H_azimuth				varchar(50);
ALTER TABLE client_inspection ADD	H_azimuth_url			varchar(500);

ALTER TABLE client_inspection ADD	V_has_mechanical_tilt	char(1);
ALTER TABLE client_inspection ADD	V_degree_of_mech_tilt	varchar(50);			
ALTER TABLE client_inspection ADD	V_has_electrical_tilt		char(1);
ALTER TABLE client_inspection ADD	V_degree_of_electr_tilt		varchar(50);
			
ALTER TABLE client_inspection ADD	V_has_null_fill			char(1);
ALTER TABLE client_inspection ADD	V_percentage_of_fill	varchar(50);			
ALTER TABLE client_inspection ADD	V_azimuth_url			varchar(500);

ALTER TABLE client_inspection ADD	antenna_gain			varchar(50);
ALTER TABLE client_inspection ADD	polarization			varchar(50);
			
ALTER TABLE client_inspection ADD	antenna_losses			varchar(50);
ALTER TABLE client_inspection ADD	feeder_losses			varchar(50);
ALTER TABLE client_inspection ADD	multiplexer_losses		varchar(50);
ALTER TABLE client_inspection ADD	antenna_height_on_tower	varchar(50);
--END

--FM TV TRANSMITTER
ALTER TABLE client_inspection ADD	tx_manufacturer			varchar(50);
ALTER TABLE client_inspection ADD	tx_model_number				varchar(50);
ALTER TABLE client_inspection ADD	tx_serial_number			varchar(50);
				
ALTER TABLE client_inspection ADD	nominal_power_watts			varchar(50);
ALTER TABLE client_inspection ADD	actual_reading				varchar(50);
ALTER TABLE client_inspection ADD	erp_kilowatts				varchar(50);	
				
ALTER TABLE client_inspection ADD	rf_output_connector 		varchar(50);
ALTER TABLE client_inspection ADD	frequency_range				varchar(50);
ALTER TABLE client_inspection ADD	frequency_stability_ppm		varchar(50);
ALTER TABLE client_inspection ADD	harmonics_suppression_level_db	varchar(50);
ALTER TABLE client_inspection ADD	spurious_emission_level_db		varchar(50);

ALTER TABLE client_inspection ADD	has_internal_audio_limiter 		char(1);
ALTER TABLE client_inspection ADD	has_internal_stereo_coder		char(1);					
ALTER TABLE client_inspection ADD	transmitter_catalog_url		varchar(50);
				
ALTER TABLE client_inspection ADD	technical_personnel			varchar(150);		--responsible for maintenance
ALTER TABLE client_inspection ADD	transmit_frequency			varchar(50);				
ALTER TABLE client_inspection ADD	transmit_bandwidth 			varchar(50);
		
ALTER TABLE client_inspection ADD	contact_person			clob;
ALTER TABLE client_inspection ADD	cck_officers			clob;
--END



CREATE SEQUENCE client_inspection_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_client_inspection_id BEFORE INSERT ON client_inspection
for each row 
begin     
	if inserting then 
		if :NEW.client_inspection_id is null then
			SELECT client_inspection_id_seq.nextval into :NEW.client_inspection_id from dual;
		end if;

		SELECT workflow_table_id_seq.nextval into :NEW.workflow_table_id from dual;
-- 		if :NEW.fmicompliancetypeid=1	then	--interference
-- 			:NEW.FORINTEFERENCE:='1';
-- 		end if;
-- 
-- 		if :NEW.fmicompliancetypeid=2	then	--monitoring
-- 			:NEW.FORMONITORING:='1';
-- 		end if;
-- 
-- 		if :NEW.fmicompliancetypeid=3	then	--inspection
-- 			:NEW.FORINSPECTION:='1';
-- 		end if;

		--use userid to update raisedby

	end if; 
end;
/




CREATE OR REPLACE TRIGGER tr_start_fmi_workflow AFTER INSERT ON client_inspection
   FOR EACH ROW 
DECLARE
	wfid 	INTEGER;
	apprid	INTEGER;
  appr_group integer;
BEGIN  
	--SELECT workflow_table_id_seq.nextval into wfid from dual;		--this has bn taken care of at BEFORE INSERT
	wfid := :NEW.workflow_table_id;		
	--:NEW.workflow_table_id := wfid;

	SELECT seq_approval_group.nextval INTO appr_group FROM dual;

	--INSERT THE FIRST APPROVALS to all the relevant entities
	INSERT INTO approvals (workflow_phase_id, approval_group, table_name, table_id, org_entity_id, app_entity_id, escalation_days, escalation_hours, approval_level, approval_narrative, to_be_done)
		SELECT workflow_phases.workflow_phase_id, appr_group,'CLIENT_INSPECTION', wfid, :NEW.created_by, entity_subscriptions.entity_id, 0, 3, 1, workflow_phases.phase_narrative, 'To do - ' || workflow_phases.phase_narrative				
			FROM workflow_phases				
			INNER JOIN entity_subscriptions ON workflow_phases.approval_entity_id = entity_subscriptions.entity_type_id
			INNER JOIN workflows ON workflow_phases.workflow_id = workflows.workflow_id
			WHERE (workflows.table_name = 'ACTIVITY_TYPE') AND (workflows.table_link_id = TO_CHAR(:NEW.ACTIVITY_TYPE_ID)) AND (workflow_phases.is_utility = '0') AND (workflow_phases.approval_level='1')
			ORDER BY workflow_phases.approval_level, workflow_phases.workflow_phase_id;
	

	--... and checklists for the first level	
	INSERT INTO approval_checklists (checklist_id,workflow_table_id)
		SELECT checklist_id,wfid
			FROM checklists
			INNER JOIN workflow_phases ON checklists.workflow_phase_id = workflow_phases.workflow_phase_id
			INNER JOIN workflows ON workflow_phases.workflow_id = workflows.workflow_id
			WHERE (workflows.table_name = 'ACTIVITY_TYPE') AND workflows.table_link_id = :NEW.ACTIVITY_TYPE_ID AND (workflow_phases.is_utility = '0') AND (workflow_phases.approval_level='1')
      ORDER BY workflow_phases.approval_level, workflow_phases.workflow_phase_id;
			

END;
/




--for radio network inspection
CREATE TABLE inspected_equipment(
	inspected_equipment_id		integer primary key,
	client_inspection_id		integer references client_inspection,
	equipment_manufacturer	varchar(50),
	equipment_make			varchar(50),
	equipment_model			varchar(50),
	equipment_serial_no		varchar(50),
	measured_freq_Mhz		varchar(50),
	location				varchar(50),
	narrative				clob,
	details					clob
	);
CREATE INDEX inspected_equip_cli_insp_id ON inspected_equipment(client_inspection_id);
CREATE SEQUENCE inspected_equipment_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_fmiequipment_id BEFORE INSERT ON inspected_equipment
for each row 
begin     
	if inserting then 
		if :NEW.inspected_equipment_id is null then
			SELECT inspected_equipment_id_seq.nextval into :NEW.inspected_equipment_id from dual;
		end if;
	end if; 
end;
/
/*
--record all compliance events may 
--be used for inspections
CREATE TABLE client_compliance (
	client_compliance_id	integer primary key,	
	sub_schedule_id			integer references sub_schedule,
	client_id				integer references client,
	client_license_id		integer references client_license,

	--adhoc					char(1) default '0' not null,
	--noncompliant			char(1) default '0' not null,
	is_compliant				char(1) default '0' not null,

    
	visit_date				timestamp ,
	hours_spent				integer,
	participants			varchar(120),
	cost_per_diem			real,
	is_done					char(1) default '0' not null,
	--IsDrop					char(1) default '0' not null,
	--IsForAction				char(1) default '0' not null,
	--ActionDone				char(1) default '0' not null,
	for_fsm					char(1) default '0' not null,
	for_lcs					char(1) default '0' not null,	

	frequency_from			real default 0 not null,
	frequency_to			real default 0 not null,

	date_of_violation		date,
	violation				clob,
	details					clob,
	purpose					clob,
	findings				clob,
	remarks					clob,
	conclusion				clob,

	contravention_notice		clob,
	penalty_notice			clob,
	penalty_amount			real default 0 not null,
	is_penalty_paid				char(1) default '0' not null,
	is_penalty_void				char(1) default '0' not null,		--used to nullify or overule the penalty charge
	revocation_notice		clob,

	mgr_compliance_comments	clob,
	mgr_postal_comments	clob,
	mgr_licenseing_comments	clob,
	ad_comments				clob,
	dir_comments			clob,
	dg_comments				clob,

	recommendation			clob
);
--CREATE INDEX compliance_ClientID ON compliance (ClientID);

CREATE SEQUENCE client_compliance_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_client_compliance_id BEFORE INSERT ON client_compliance
for each row 
begin     
	if inserting then 
		if :NEW.client_compliance_id is null then
			SELECT client_compliance_id_seq.nextval into :NEW.client_compliance_id  from dual;
		end if;
	end if; 
end;*/


CREATE TABLE latitude_position (
	latitude_position_id integer primary key,
	latitude_position char(1)
	);
insert into latitude_position values(1,'N');
insert into latitude_position values(2,'S');



CREATE TABLE site (
	site_id 		integer primary key, 	

	--addressid integer references addresses, 

	site_code 		varchar(10),
	site_name 		varchar(30), 

	site_longitude 		numeric(10,6), 	--decimal format
	site_latitude 		numeric(10,6), 	--decimal format

	longitude_degrees 	real,
	longitude_minutes 	real,
	longitude_seconds 	real,

	latitude_degrees 	real,
	latitude_minutes 	real,
	latitude_seconds 	real,
	
	latitude_position_id 	integer references latitude_position,

	location 			varchar(100),
	site_asl			real,
	service_radius 		real,	

	lr_number 			varchar(50),
	--SIT_ASL 			numeric(7,2), 
	--SIT_REMARK 		VARCHAR(2000), 
	--SIT_TEL_DESC 		VARCHAR(50), 
	--SIT_FAX_DESC 		VARCHAR(50), 
	--LAST_UPD_TIME 	DATE DEFAULT sysdate, 
	--SERVER_SITE 		numeric, 
	--SIT_FRAGMENT 	VARCHAR(5), 
	--SIT_AREA 		VARCHAR(100),
		
	remarks				clob
);
CREATE SEQUENCE site_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_site_id BEFORE INSERT ON site
for each row 
begin     
	if inserting then 
		if :NEW.site_id  is null then
			SELECT site_id_seq.nextval into :NEW.site_id  from dual;
			
			:NEW.site_longitude := (:NEW.longitude_degrees * 1) + (:NEW.longitude_minutes/60) + (:NEW.longitude_seconds/3600);
			:NEW.site_latitude := (:NEW.latitude_degrees * 1) + (:NEW.latitude_minutes/60) + (:NEW.latitude_seconds/3600);
			
		end if;
	end if; 
end;
/



--eg telex, pbx, radio comm, etc
CREATE TABLE equipment_type (
	equipment_type_id		integer primary key,
	equipment_type_name		varchar(120),
	details					clob
);

ALTER TABLE equipment_type ADD is_ta_marketing char(1);
ALTER TABLE equipment_type ADD is_fsm_equipment char(1);

CREATE SEQUENCE equipment_type_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_equipment_type_id BEFORE INSERT ON equipment_type
for each row 
begin     
	if inserting then 
		if :NEW.equipment_type_id  is null then
			SELECT equipment_type_id_seq.nextval into :NEW.equipment_type_id  from dual;
		end if;
	end if; 
end;
/






--utility table to allow non type approved equip for aircraft and marine vessels
--where the equipment will be used.. 
CREATE TABLE equipment_target(
	equipment_target_id		integer primary key,
	equipment_target_name	varchar(120),
	requires_ta				char(1) default '1' not null,
	details					clob
);
CREATE SEQUENCE equipment_target_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_equipment_target_id BEFORE INSERT ON equipment_target
for each row 
begin     
	if inserting then 
		if :NEW.equipment_target_id  is null then
			SELECT equipment_target_id_seq.nextval into :NEW.equipment_target_id  from dual;
		end if;
	end if; 
end;
/

INSERT INTO equipment_target(equipment_target_id,equipment_target_name) VALUES(1,'OTHER');
INSERT INTO equipment_target(equipment_target_id,equipment_target_name) VALUES(2,'AIRCRAFT');
INSERT INTO equipment_target(equipment_target_id,equipment_target_name) VALUES(3,'MARINE');
COMMIT;

CREATE TABLE equipment(	
	equipment_id 		integer primary key,
	equipment_type_id		integer references equipment_type,
	equipment_target_id		integer references equipment_target,
	equipment_make				varchar(120),
	equipment_model				varchar(120),	
	
	supplier_name		varchar(240),
	supplier_box			varchar(240),
	supplier_telno		varchar(240),
	supplier_email		varchar(240),
	supplier_address		varchar(240),

	--status				varchar(50),
	output_power			varchar(50),
	power_to_antenna		varchar(50),
	tolerance				varchar(50),

	carrier_output_power		varchar(50),
	duplex_spacing				varchar(50),
	adjacent_channel_spacing	varchar(50),		--the same as channel separation ?

	channel_capacity		varchar(50),
	system_deviation		varchar(50),		--for digital
	bit_error_rate			varchar(50),		--for digital

	conducted_spurious		varchar(200),
	radiated_spurious		varchar(200),
	audio_harmonic_distortion	varchar(200),
	emmission_designation	varchar(200),

	operating_frequency_band  varchar(200),
	rf_bandwidth				varchar(200),
	if_bandwidth_3db			varchar(200),

	receiver_sensitivity				varchar(200),
	receiver_adjacent_selectivity	varchar(200),
	desensitisation					varchar(200),

	fm_noise				varchar(200), 		--for analogue

	threshold			varchar(100),

	rf_filterloss		varchar(200), 		--for analogue	

	action_date			date default sysdate,		--date added
	---userid				integer references users,	--user 

	details clob
);
--CREATE INDEX equipments_equipmentid ON equipments (equipmenttypeid);

ALTER TABLE equipment ADD is_aircraft char(1) default '0';
ALTER TABLE equipment ADD is_maritime char(1) default '0';
ALTER TABLE equipment ADD equipment_manufacturer varchar(200);
ALTER TABLE equipment ADD manufacturer_address varchar(200);
ALTER TABLE equipment ADD rf_output real;
ALTER TABLE equipment ADD data_mode varchar(50);
ALTER TABLE equipment ADD number_of_channels integer;
ALTER TABLE equipment ADD modulation varchar(50);
ALTER TABLE equipment ADD frequency_deviation varchar(50);
ALTER TABLE equipment ADD power_supply varchar(50);

ALTER TABLE equipment ADD equipment_name varchar(50);
ALTER TABLE equipment ADD channel_separation real;
ALTER TABLE equipment ADD imp_status varchar(50); 
ALTER TABLE equipment ADD imp_approve_status varchar(50);
ALTER TABLE equipment ADD imp_last_upd_time date;
ALTER TABLE equipment ADD imp_equ_type varchar(50);
ALTER TABLE equipment ADD imp_equ_service varchar(50);
ALTER TABLE equipment ADD imp_equ_operation_mode varchar(50);
ALTER TABLE equipment ADD imp_equ_freq_stability real;
ALTER TABLE equipment ADD imp_equ_power_type varchar(50);
ALTER TABLE equipment ADD imp_equ_model varchar(50);	--REDUNDANT
ALTER TABLE equipment ADD imp_equ_status varchar(50);
ALTER TABLE equipment ADD imp_equ_rx_low_freq real;
ALTER TABLE equipment ADD imp_equ_rx_high_freq real;
ALTER TABLE equipment ADD imp_equ_tx_low_freq real;
ALTER TABLE equipment ADD imp_equ_tx_high_freq real;
ALTER TABLE equipment ADD imp_equ_station_service varchar(50);
ALTER TABLE equipment ADD imp_equ_station_class varchar(50);
ALTER TABLE equipment ADD imp_equ_reg_date date;
ALTER TABLE equipment ADD imp_equ_reg_num 	varchar(20);
ALTER TABLE equipment ADD imp_equ_mobility 	varchar(50);
--ALTER TABLE equipment ADD emmission_designation varchar(50);	--equi_info1



--ALTER TABLE equipment ADD is_type_approved char(1) default '0';

CREATE SEQUENCE equipment_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_equipment_id BEFORE INSERT ON equipment
for each row 
begin     
	if inserting then 
		if :NEW.equipment_id  is null then
			SELECT equipment_id_seq.nextval into :NEW.equipment_id  from dual;
		end if;
	end if; 
end;
/




--network may include alarm network
CREATE TABLE vhf_network(
	vhf_network_id 				integer primary key,
	client_license_id 			integer references client_license, 	
	vhf_network_name			varchar(50),
	vhf_network_location		varchar(50),

	decoder_capacity			real,				--applicable for alarms
	units_requested				integer default 1,		--alarms ?
	units_approved				integer default 1,

	--alarm decoder
	equipment_id				integer, 			--references equipments... applicable for alarms (decoder ?)
	equipment_serial_no			varchar(100),
	rf_bandwidth				varchar(50),	

	
	extra_number_of_frequencies 	integer default 0,	--insert into another table(which one) and clear this field once approval has been obtained.

	created					date default SYSDATE,		
	created_by				integer references entitys,
	updated					date default SYSDATE,
	updated_by				integer references entitys,
	userid					integer references entitys,
	
	remark					clob,	
	details					clob
	);

ALTER TABLE vhf_network ADD number_of_frequencies 	integer default 0;		--for alarm network (aka decoder)
ALTER TABLE vhf_network ADD antenna_type_id		integer references antenna_type;


CREATE INDEX vhf_network_client_license_id ON vhf_network(client_license_id);

CREATE SEQUENCE vhf_network_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_vhf_network_id BEFORE INSERT ON vhf_network
for each row 
begin     
	if inserting then 
		if :NEW.vhf_network_id is null then
			SELECT vhf_network_id_seq.nextval into :NEW.vhf_network_id from dual;

			--:NEW.created_by := :NEW.entity_id;
			--:NEW.updated_by := :NEW.entity_id;

		end if;
	end if; 
end;
/








--IMPORT TEMP
--p2p import
CREATE TABLE link_import (	
	link_import_id 		integer primary key,

	service_code			varchar(50),
	link_number			varchar(50),
	link_name			varchar(50),

	site_a_code			varchar(50),
	site_a_name			varchar(50),
	site_a_longitude		varchar(50),
	site_a_latitude		varchar(50),
	site_a_antenna_height	varchar(50),
	site_a_antenna_polarization	varchar(50),
	site_a_equipment		varchar(50),
	
	site_b_code			varchar(50),
	site_b_name			varchar(50),
	site_b_longitude		varchar(50),
	site_b_latitude		varchar(50),
	site_b_antenna_height	varchar(50),
	site_b_antenna_polarization	varchar(50),
	site_b_equipment		varchar(50),
	region				varchar(50),

	tx_frequency			varchar(50),		--w.r.t A
	rx_frequency			varchar(50),		--w.r.t A
	link_config			varchar(50),
	link_capacity		varchar(50),		--mbps
	link_bandwidth		varchar(50),		--MHz
	operating_band		varchar(50),		--GHz
	uso_factor			varchar(50),		--rural or urban ???
	details				varchar(100)
	
);
CREATE SEQUENCE link_import_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_link_import_id BEFORE INSERT ON link_import
for each row 
begin     
	if inserting then 
		if :NEW.link_import_id is null then
			SELECT link_import_id_seq.nextval into :NEW.link_import_id from dual;
		end if;
	end if; 
end;
/

--Fixed Wireless Import
CREATE TABLE fw_import (	
	fw_import_id 		integer primary key,

	service_code			varchar(50),
	site_number			varchar(50),
	site_name			varchar(50),
	site_code 			varchar(10),

	site_longitude		varchar(50),
	site_latitude		varchar(50),

	service_radius		varchar(50),
	cell_radius			varchar(50),

	number_of_sectors		varchar(50),
	trx_per_sector		varchar(50),

	region			varchar(50),

	erp					varchar(50),
	up_link				varchar(50),
	down_link			varchar(50),
	band_width			varchar(50),

	antenna_type			varchar(50),
	antenna_height		varchar(50),
	azimuth				varchar(50),
	antenna_polarization	varchar(50),
	
	details				varchar(100)
	
);
CREATE SEQUENCE fw_import_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_fw_import_id BEFORE INSERT ON fw_import
for each row 
begin     
	if inserting then 
		if :NEW.fw_import_id is null then
			SELECT fw_import_id_seq.nextval into :NEW.fw_import_id from dual;
		end if;
	end if; 
end;
/




--declaration import
CREATE TABLE declaration_import (	
	declaration_import_id 	integer primary key,
	service_code				varchar(50),	--identifies the clientlicenseid ie the application id

	make			varchar(50),
	model			varchar(50),
	serial_number 	varchar(20),

	output_power 	varchar(50),
	frequency 		varchar(50),
	location 		varchar(50),

	vendor_name				varchar(200),
	vendor_address			varchar(100),
	technical_personnel_name		varchar(200),
	technical_personnel_license	varchar(50),		--licesenumber

	is_scheduled			char(1) default '0',		--has it been scheduled for inspection ?	
	is_fine				char(1) default '0',				--power and location matches an existing station
	is_unmatched			char(1) default '0',				--redundant ???????

	details				varchar(100)	
);


CREATE SEQUENCE declaration_import_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_declaration_import_id BEFORE INSERT ON declaration_import
for each row 
begin     
	if inserting then 
		if :NEW.declaration_import_id is null then
			SELECT declaration_import_id_seq.nextval into :NEW.declaration_import_id from dual;
		end if;
	end if; 
end;
/



--hf,mf,fm
CREATE TABLE radio_broadcasting_type(
	radio_broadcasting_type_id	integer primary key,
	radio_broadcasting_type_name 	varchar(10),
	details						clob	
	);
INSERT INTO radio_broadcasting_type(radio_broadcasting_type_id,radio_broadcasting_type_name) VALUES(1,'HF');
INSERT INTO radio_broadcasting_type(radio_broadcasting_type_id,radio_broadcasting_type_name) VALUES(2,'MF');
INSERT INTO radio_broadcasting_type(radio_broadcasting_type_id,radio_broadcasting_type_name) VALUES(3,'FM');
COMMIT;

--TDD, FDD
CREATE TABLE duplex_method(
	duplex_method_id 	integer primary key,
	duplex_method_name		varchar(50),
	details 			clob
	);
INSERT INTO duplex_method(duplex_method_id,duplex_method_name) VALUES(1,'TDD');
INSERT INTO duplex_method(duplex_method_id,duplex_method_name) VALUES(2,'FDD');
COMMIT;


--trunked radio type can be PMR or PAMR
create table trunked_radio_type(
	trunked_radio_type_id 		integer primary key,
	trunked_radio_type_name 	varchar(50),
	details 					clob
	);
INSERT INTO trunked_radio_type(trunked_radio_type_id,trunked_radio_type_name) VALUES(1,'PAMR');
INSERT INTO trunked_radio_type(trunked_radio_type_id,trunked_radio_type_name) VALUES(2,'PMR');
COMMIT;
-- CREATE SEQUENCE trunked_radio_type_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
-- CREATE OR REPLACE TRIGGER tr_trunked_radio_type_id BEFORE INSERT ON trunked_radio_type
-- for each row 
-- begin     
-- 	if inserting then 
-- 		if :NEW.trunked_radio_type_id is null then
-- 			SELECT trunked_radio_type_id_seq.nextval into :NEW.trunked_radio_type_id from dual;
-- 		end if;
-- 	end if; 
-- end;
-- /



create table station_type(
	station_type_id 		integer primary key,
	station_type_name 	varchar(50),
	details 					clob
	);
CREATE SEQUENCE station_type_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_station_type_id BEFORE INSERT ON station_type
for each row 
begin     
	if inserting then 
		if :NEW.station_type_id is null then
			SELECT station_type_id_seq.nextval into :NEW.station_type_id from dual;
		end if;
	end if; 
end;
/

INSERT INTO station_type(station_type_id, station_type_name) VALUES(1, 'OTHER');
INSERT INTO station_type(station_type_id, station_type_name) VALUES(2, 'MOTOR VEHICLE');
INSERT INTO station_type(station_type_id, station_type_name) VALUES(3, 'AIRCRAFT');
INSERT INTO station_type(station_type_id, station_type_name) VALUES(4, 'MARINE VESSEL');
COMMIT;

--marine vessel type.. cannoe, small boart, merchant ship
CREATE TABLE vessel_type (
	vessel_type_id 	integer primary key,
	vessel_type_name 	varchar(100),
	details 			clob
);
CREATE SEQUENCE vessel_type_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_vessel_type_id BEFORE INSERT ON vessel_type
for each row 
begin     
	if inserting then 
		if :NEW.vessel_type_id is null then
			SELECT vessel_type_id_seq.nextval into :NEW.vessel_type_id from dual;
		end if;
	end if; 
end;
/
INSERT INTO vessel_type(vessel_type_id, vessel_type_name) VALUES(1, 'OTHER');
INSERT INTO vessel_type(vessel_type_id, vessel_type_name) VALUES(2, 'MERCHANT SHIP');
INSERT INTO vessel_type(vessel_type_id, vessel_type_name) VALUES(3, 'DHOW / CANNOE');
COMMIT;



--TYPE OF ANTENNA
CREATE TABLE antenna_type(
	antenna_type_id		integer primary key,
	antenna_type_name	varchar(120),
	details				clob
);
CREATE SEQUENCE antenna_type_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_antenna_type_id BEFORE INSERT ON antenna_type
for each row 
begin     
	if inserting then 
		if :NEW.antenna_type_id  is null then
			SELECT antenna_type_id_seq.nextval into :NEW.antenna_type_id  from dual;
		end if;
	end if; 
end;
/
INSERT INTO antenna_type(antenna_type_name) VALUES('OTHER');
INSERT INTO antenna_type(antenna_type_name) VALUES('PARABOLIC');
INSERT INTO antenna_type(antenna_type_name) VALUES('HORN');
INSERT INTO antenna_type(antenna_type_name) VALUES('YAGI');
COMMIT;







--actual stations
CREATE TABLE station(	
	station_id 				integer primary key,

	station_charge_id		integer references station_charge,
	client_license_id		integer references client_license, 
	service_nature_id		char(2) references service_nature, 	--nature of service
	status_station_id 		integer references status_station,

	vhf_network_id			integer references vhf_network,			--vhf networks have to be grouped to simplify freq assignment
	--transmitstation_id		integer references stations,			--may refer to the link(station) in case of terrestrials 

	
	trunked_radio_type_id	integer references trunked_radio_type,
	duplex_method_id		integer,		--references duplexmethod

	site_id		 			integer references site,
	entity_id				integer references entitys,
	
	station_name			varchar(150), 
	station_call_sign		varchar(100),	
	--is_aircraft			char(1) default '0',

	station_type_id			integer references station_type,		--wether motor vehicle or aircraft, or maritime vessel

	vehicle_reg_no			varchar(500),					--for mobiles fitted on vehicles
	
	
	aircraft_name			varchar(100),
	aircraft_type			varchar(100),
	aircraft_reg_no			varchar(100),	

	vessel_type_id			integer references vessel_type,
	vessel_name				varchar(100),
	imo_number				varchar(100),				--international maritime organization
	gross_tonnage			real,	

	decoder_capacity			real,				--applicable for alarms

	--radiobroadcastingtypeid		integer references radiobroadcastingtype,
	is_transmitter			char(1) default '0',
	is_active				char(1) default '1',		--means not decomissioned
	decommission_date		date,

	number_of_receivers			integer default 0,
	requested_frequency_bands	varchar(250),
	number_of_frequencies 		integer default 1,

	extranumber_of_frequencies 	integer default 0,	--insert into another table and clear this field once approval has been obtained
	
	requested_frequency 		real,		--in MHz	
	requested_frequencyGHz		real,		--in GHz

	requested_bandwidth			real,		--in KHz
	requested_bandwidth_MHz		real,		--in MHz
	requested_bandwidth_GHz		real,		--in GHz
	
	nominal_tx_power			real,		--the nominal transmitter power
	effective_tx_power			real,		--the effective isotropicaly radiated power

	
	location			varchar(50),
	feeder_type			varchar(50),
	feeder_loss			varchar(50),
	attenuation			varchar(50),

	max_operation_hours			varchar(20),
	path_length_km				real,
	service_radius				real,
	proposed_operation_date 	date,

	transmit_ant_type			varchar(50),
	transmit_ant_height				varchar(50),
	transmit_ant_relative_height	varchar(50),
	
	transmit_ant_directivity	varchar2(100),
	transmit_ant_azimuth		varchar(50),
	transmit_ant_beam_width		varchar(50),
	transmit_ant_gain_dbi		varchar(50),
	
	--the following two columns should be VIRTUAL !!!!!!!	but virtual columns cant reference other tables !!!!!!!!
	--alter table station ADD VTEST  REAL GENERATED ALWAYS AS (100*12);
	annual_station_charge		real,			--full station charge without considering proration. used in annual payment
	prorated_charge				real,			--prorated charge. used in initial payment
	initial_charge_period		int,			--if >= 12 months, payment includes next period's

	capacity_mpbs				varchar(50),
	is_rural					char(1) default '0',
	for_export					char(1) default '0',
	is_declared					char(1) default '0',

	number_of_sectors			integer default 1,
	tx_per_sector				integer default 1,

	--VSAT
	--capacity of earth stations
	vsat_lr_number				varchar(50),
	carrier_tx_freq_Mhz			real,	--MHz
	carrier_rx_freq_Mhz			real,	--MHz
	bit_rate_tx_kbps			real,	--kbps
	bit_rate_rx_kbps			real,	--kbps
	bw_tx_Mhz					real,	--MHz
	bw_rx_Mhz					real,	--MHz

	--physical parameters
	vsat_lat_degrees		real,
	vsat_lat_minutes		real,
	vsat_lat_seconds		real,	
	vsat_long_degrees		real,
	vsat_long_minutes		real,
	vsat_long_seconds		real,
	altitude				real,			--meters
	antenna_shape			varchar(50),	--circular, square, etc
	antenna_area			real,			--square meters

	--antenna xstics
	isotropic_gain_dBi	real,
	beam_width_degrees		real,
	beam_width_minutes		real,
	beam_width_seconds		real,
	elevation_degrees		real,
	elevation_minutes		real,
	elevation_seconds		real,
	azimuth_degrees		real,
	azimuth_minutes		real,
	azimuth_seconds		real,	
	mean_altitude		real,
	polar_type			varchar(20),
	polar_direction		varchar(20),
	EIRP_dBW			real default 0,		--power

	--EQUIPMENT DETAILS
	equipment_id			integer references equipment, 			--this should be fine unless a station can have more than one radio comm equip 
	equipment_serial_no	varchar2(100),



	--defaults to entries in xponding equipment 
	supplier_name		varchar(240),
	supplier_box		varchar(240),
	supplier_telno		varchar(240),
	supplier_email		varchar(240),
	supplier_address	varchar(240),
	supplier_fax		varchar(240),

	status				varchar(50),
	output_power		varchar(50),
	tolerance			varchar(10),

	carrier_out_putpower		varchar(100),
	duplex_spacing				varchar(100),
	adjacent_channel_spacing	varchar(100),
	power_to_antenna			varchar(100),

	channel_capacity			varchar(50),
	system_deviation			varchar(50),
	bit_error_rate				varchar(50),
	conducted_spurious			varchar(50),
	radiated_spurious			varchar(50),
	audio_harmonic_distortion	varchar(200),
	emmission_designation		varchar(200),

	operating_frequency_band  	varchar(50),
	rf_band_width				varchar(50),
	if_bandwidth_3db			varchar(50),
	receiver_sensitivity		varchar(200),
	receiver_adjacenst_selectivity	varchar(200),
	desensitisation				varchar(200),
	fm_noise					varchar(50),
	threshold					varchar(100),
	rf_filterloss				varchar(50),

	--ANTENNA DETAILS
	antenna_type_id			integer references antenna_type, 	
	antenna_descr			varchar(50),	
	--is_transmitter		char(1) default '0',

	antenna_name			varchar(50),
	antenna_model			varchar(50),
	antenna_manufacturer	varchar(50),
	low_frequency		real,		--not assigned here (misplaced)
	high_frequency		real,		--not assigned here
	polarization		char(2),		
	
	--output_power		real,
	height				real,
	relative_height		real,
	directivity			varchar(50),

	azimuth				varchar(100),
	beam_width			varchar(100),
	max_gain_decibels	varchar(100),

	tilt				real,

	remarks				clob
	
);

--ALTER
ALTER TABLE station ADD station_class_id char(2) references station_class;
ALTER TABLE station ADD units_requested	integer default 1;		--alarms ?
ALTER TABLE station ADD units_approved integer default 1;
ALTER TABLE station ADD uplink_downlink 	varchar(500);

ALTER TABLE station ADD site_code varchar(30);
ALTER TABLE station ADD longitude_degrees real;
ALTER TABLE station ADD longitude_minutes real;
ALTER TABLE station ADD longitude_seconds real;
ALTER TABLE station ADD latitude_degrees real;
ALTER TABLE station ADD latitude_minutes real;
ALTER TABLE station ADD latitude_seconds real;
ALTER TABLE station ADD lat_pos 	varchar(50);

--EMMISSIN DESIGNATION FOR THIS STATION
ALTER TABLE station ADD band_width_code_id			varchar(5);		--this should be a virtual column
ALTER TABLE station ADD modulation_type_code		char(1) references modulation_type(code);					--first symbol
ALTER TABLE station ADD nature_of_signal_code		char(1) references nature_of_signal(code);					--second
ALTER TABLE station ADD type_of_information_code	char(1) references type_of_information(code);					--third
ALTER TABLE station ADD signal_detail_code			char(1) references signal_detail(code);					--fourth
ALTER TABLE station ADD mux_nature_code				char(1) references mux_nature(code);					--fifth		

ALTER TABLE station ADD aircraft_band_type_id		integer references aircraft_band_type;
ALTER TABLE station ADD sum_tx integer AS (number_of_sectors * tx_per_sector);
ALTER TABLE station ADD terrestrial_link_id	integer references terrestrial_link;		--for point 2 point and single channel (?)

--for AIRCRAFT WITH 2 STATIONS eg VHF+HF
ALTER TABLE station ADD equipment_2_id			integer references equipment; 			--this should be fine unless a station can have more than one radio comm equip 
ALTER TABLE station ADD equipment_2_serial_no	varchar2(100);
ALTER TABLE station ADD output_2_power varchar(50);
--ALTER TABLE station ADD round_station_charge real AS (annual_station_charge + 0);


CREATE INDEX station_station_class ON station(station_class_id);
CREATE INDEX station_station_charge  ON station(station_charge_id);
CREATE INDEX station_client_license  ON station(client_license_id);
CREATE INDEX station_service_nature  ON station(service_nature_id);
CREATE INDEX station_status_station  ON station(status_station_id);
CREATE INDEX station_vhf_network  ON station(vhf_network_id);
CREATE INDEX station_trunked_radio_type  ON station(trunked_radio_type_id);
CREATE INDEX station_duplex_method  ON station(duplex_method_id);
CREATE INDEX station_site  ON station(site_id);
CREATE INDEX station_entity  ON station(entity_id);
CREATE INDEX station_station_type  ON station(station_type_id);
CREATE INDEX station_vessel_type  ON station(vessel_type_id);
CREATE INDEX station_equipment  ON station(equipment_id);
CREATE INDEX station_antenna_type  ON station(antenna_type_id);

CREATE SEQUENCE station_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;

CREATE OR REPLACE TRIGGER tr_station_id BEFORE INSERT OR UPDATE ON station
for each row 

declare

	k1 			          real;
	rate 		          real;
	usage_fee 	      real;
	spectrum_mgt_cost real;
	n                 real;
	fx_unit_fee			real;
	bw_factor			real;

	CURSOR cur_station_charge IS
		SELECT station_charge.station_charge_id, station_charge.station_class_id, 
			station_charge.station_charge_name, station_charge.amount, station_charge.unit_charge,
			charge_type.unit_group, charge_type.one_time_fee, charge_type.per_license, charge_type.per_station, 
			charge_type.per_frequency, charge_type.has_fixed_charge, station_charge.functname, station_charge.formula, 
			license.license_id,license.initial_fee, license.annual_fee					
		FROM station_charge 
		INNER JOIN license ON station_charge.license_id = license.license_id
		LEFT JOIN charge_type ON station_charge.charge_type_id = charge_type.charge_type_id
		WHERE station_charge.station_charge_id = :NEW.station_charge_id;

		rec_station_charge cur_station_charge%ROWTYPE;

begin   

  OPEN cur_station_charge;
	FETCH cur_station_charge INTO rec_station_charge;
  
	if inserting then 
		if :NEW.station_id is null then
			SELECT station_id_seq.nextval into :NEW.station_id  from dual;
		end if;

		
		IF :NEW.station_charge_id = 8 THEN	--if aircraft 
			:NEW.annual_station_charge := rec_station_charge.amount;
		ELSIF :NEW.terrestrial_link_id IS NOT NULL THEN
			:NEW.annual_station_charge := 0;
		ELSIF rec_station_charge.license_id = 12 THEN    --IF LAND MOBILE
			:NEW.annual_station_charge := (rec_station_charge.amount * :NEW.number_of_frequencies);
			--SELECT proratedChargePeriod(:NEW.proposed_operation_date) INTO :NEW.initial_charge_period FROM dual;
			SELECT proratedChargePeriod(current_date) INTO :NEW.initial_charge_period FROM dual;
			SELECT (:NEW.annual_station_charge * :NEW.initial_charge_period/12) INTO :NEW.prorated_charge FROM dual;				

		ELSIF (rec_station_charge.station_charge_id = 23) THEN
												
			:NEW.annual_station_charge := (rec_station_charge.amount * :NEW.units_requested);
			SELECT proratedChargePeriod(current_date) INTO :NEW.initial_charge_period FROM dual;
			SELECT (:NEW.annual_station_charge * :NEW.initial_charge_period/12) INTO :NEW.prorated_charge FROM dual;				

		ELSIF rec_station_charge.station_charge_id = 39 THEN		--if VSAT earth station
			
			fx_unit_fee := rec_station_charge.amount;
			
			IF (:NEW.bw_tx_Mhz <= 0.25) THEN
				bw_factor := 0.25;
			ELSIF (:NEW.bw_tx_Mhz > 0.25 AND :NEW.bw_tx_Mhz <= 0.5) THEN
				bw_factor := 0.5;
			ELSIF (:NEW.bw_tx_Mhz > 0.5 AND :NEW.bw_tx_Mhz <= 1) THEN
				bw_factor := 1;
			ELSIF (:NEW.bw_tx_Mhz > 1 AND :NEW.bw_tx_Mhz <= 3) THEN
				bw_factor := 2;
			ELSIF (:NEW.bw_tx_Mhz > 3 AND :NEW.bw_tx_Mhz <= 6) THEN
				bw_factor := 4;
			ELSIF (:NEW.bw_tx_Mhz > 6 AND :NEW.bw_tx_Mhz <= 10) THEN
				bw_factor := 6;
			ELSIF (:NEW.bw_tx_Mhz > 10) THEN
				bw_factor := 8;
			END IF;
			
			:NEW.annual_station_charge := (fx_unit_fee * bw_factor);
			SELECT proratedChargePeriod(current_date) INTO :NEW.initial_charge_period FROM dual;
			SELECT (:NEW.annual_station_charge * :NEW.initial_charge_period/12) INTO :NEW.prorated_charge FROM dual;				
          
		ELSIF rec_station_charge.station_charge_id = 24 THEN    --IF FIXED WIRELESS

			spectrum_mgt_cost := 100000;			--annual spectrum management cost						

			n := :NEW.requested_bandwidth_MHz/1.75;

			--1.rate
			rate := 1;
			
			--2. spectrum usage fee	
			IF(:NEW.requested_frequencyGHz <= 1) THEN		--1000khz = 1Ghz
				k1 := 0.8;
			ELSIF((:NEW.requested_frequencyGHz > 1) AND (:NEW.requested_frequencyGHz <= 6)) THEN		
				k1 := 0.7;		
			ELSIF((:NEW.requested_frequencyGHz > 6) AND (:NEW.requested_frequencyGHz <= 10)) THEN		
				k1 := 0.6;		
			ELSIF((:NEW.requested_frequencyGHz > 10) AND (:NEW.requested_frequencyGHz <= 20)) THEN		
				k1 := 0.5;		
			ELSIF((:NEW.requested_frequencyGHz > 20) AND (:NEW.requested_frequencyGHz <= 30)) THEN		
				k1 := 0.4;				
			ELSIF(:NEW.requested_frequencyGHz > 30) THEN		
				k1 := 0.3;
			END IF;
			
			usage_fee := spectrum_mgt_cost * n * k1 * (:NEW.number_of_sectors * :NEW.tx_per_sector);

			--if TDD divide charge by two
			if (:NEW.duplex_method_id = 1) then
				usage_fee := usage_fee/2;
			end if;

			:NEW.annual_station_charge := usage_fee;
			--:NEW.proratedcharge := :NEW.stationcharge * :NEW.initialchargeperiod/12;

		END IF;
		
	end if; 


	if updating then 
		
		IF :NEW.station_charge_id = 8 THEN	--if aircraft 
			:NEW.annual_station_charge := rec_station_charge.amount;
		ELSIF :NEW.terrestrial_link_id IS NOT NULL THEN
			:NEW.annual_station_charge := 0;
		ELSIF rec_station_charge.license_id = 12 THEN    --IF LAND MOBILE
			:NEW.annual_station_charge := (rec_station_charge.amount * :NEW.number_of_frequencies);
			--SELECT proratedChargePeriod(:NEW.proposed_operation_date) INTO :NEW.initial_charge_period FROM dual;
			SELECT proratedChargePeriod(current_date) INTO :NEW.initial_charge_period FROM dual;
			SELECT (:NEW.annual_station_charge * :NEW.initial_charge_period/12) INTO :NEW.prorated_charge FROM dual;
    
    ELSIF (rec_station_charge.station_charge_id = 23) THEN		--IF ALARM
												
			:NEW.annual_station_charge := (rec_station_charge.amount * :NEW.units_requested);
			SELECT proratedChargePeriod(current_date) INTO :NEW.initial_charge_period FROM dual;
			SELECT (:NEW.annual_station_charge * :NEW.initial_charge_period/12) INTO :NEW.prorated_charge FROM dual;				
  
		ELSIF rec_station_charge.station_charge_id = 39 THEN		--if VSAT earth station      
      
			fx_unit_fee := rec_station_charge.amount;
			
			IF (:NEW.bw_tx_Mhz <= 0.25) THEN
				bw_factor := 0.25;
			ELSIF (:NEW.bw_tx_Mhz > 0.25 AND :NEW.bw_tx_Mhz <= 0.5) THEN
				bw_factor := 0.5;
			ELSIF (:NEW.bw_tx_Mhz > 0.5 AND :NEW.bw_tx_Mhz <= 1) THEN
				bw_factor := 1;
			ELSIF (:NEW.bw_tx_Mhz > 1 AND :NEW.bw_tx_Mhz <= 3) THEN
				bw_factor := 2;
			ELSIF (:NEW.bw_tx_Mhz > 3 AND :NEW.bw_tx_Mhz <= 6) THEN
				bw_factor := 4;
			ELSIF (:NEW.bw_tx_Mhz > 6 AND :NEW.bw_tx_Mhz <= 10) THEN
				bw_factor := 6;
			ELSIF (:NEW.bw_tx_Mhz > 10) THEN
				bw_factor := 8;
			END IF;
			
			:NEW.annual_station_charge := (fx_unit_fee * bw_factor);
			SELECT proratedChargePeriod(current_date) INTO :NEW.initial_charge_period FROM dual;
			SELECT (:NEW.annual_station_charge * :NEW.initial_charge_period/12) INTO :NEW.prorated_charge FROM dual;				
          

		END IF;


	end if; 

  CLOSE cur_station_charge;
end;
/




--used for initial application. accomodates aircrafts as stations in addition to others
--used for alarms and land mobile. since technical details are needed only after initial fee is paid
CREATE TABLE client_station(
  	client_station_id 		integer primary key,	
	--CLIENTLICENSEID 		integer references clientlicenses, 
	station_charge_id		integer references station_charge,
	--client_license_id		integer references client_license, 	

	vhf_network_id			integer references vhf_network,

	trunked_radio_type_id	integer references trunked_radio_type,
	
	--CLIENTSTATIONNAME 			VARCHAR2(20), 	

	application_date				DATE DEFAULT SYSDATE,

	number_of_requested_stations 	NUMBER default 1,
	number_of_approved_stations 	NUMBER default 1,	

	--aircraft_name				VARCHAR2(100),
	--aircraft_type				VARCHAR2(100),
	--aircraft_reg_no				VARCHAR2(100),

	--call_sign					VARCHAR(100),

	isdummy						char(1) default '0' not null,		--for entries that need not be propageted to STATIONS table. eg when reinstating a license (STATIONS are usually copied directly from the previous license hence no need to propaget)

	number_of_frequencies			NUMBER default 1, 		--this is the number of frequencies requested 
	--DECODERCAPACITY				REAL,
	requested_frequency_bands		VARCHAR2(250),
	requested_frequency			REAL,				--khz
	requested_bandwidth			REAL,
	nominal_tx_power			REAL,		--the nominal transmitter power
	effective_tx_power			REAL,		--the effective isotropicaly radiated power

	tentative_price				NUMBER,		--initial fee for broadcasting
	final_price					NUMBER,		--annual fee for broadcasting

	location 					VARCHAR2(200), 
	--entity_id 						NUMBER, 		

	details 					CLOB
);
ALTER TABLE client_station ADD CONSTRAINT uniq_cli_stat UNIQUE(vhf_network_id,station_charge_id);
CREATE INDEX client_station_vhfnetwork ON client_station (vhf_network_id);
CREATE INDEX client_station_trunked_radio ON client_station (trunked_radio_type_id);
CREATE INDEX client_station_station_charge ON client_station (station_charge_id);

 			
CREATE SEQUENCE client_station_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
--select * from station_charge;
select * from station where station_charge_id = 23;

CREATE OR REPLACE TRIGGER tr_client_station_id BEFORE INSERT OR UPDATE ON client_station
for each row 
declare
	
	tprice real;
	fprice real;
	unitfee real;		--for 8.5 khz bandwidth
	k1 real;
	k2 real;
	k3 real;
	val real;
	Pnom real;
	Ptot real;
	weightingfactor real;
	spectrumfee real;
	usagefee real;
	spectrummanagementcost real;
	n int;
	radiotype int;      --1 for PAMR and 2 for PMR

	CURSOR cur_station_charge IS
		SELECT station_charge.station_charge_id, station_charge.license_id, station_charge.station_class_id, 
			station_charge.station_charge_name, station_charge.amount, station_charge.unit_charge,
			charge_type.unit_group, charge_type.one_time_fee, charge_type.per_license, charge_type.per_station, 
			charge_type.per_frequency, charge_type.has_fixed_charge, station_charge.functname, station_charge.formula, 
			license.initial_fee, license.annual_fee					
		FROM station_charge 
		INNER JOIN license ON station_charge.license_id = license.license_id
		LEFT JOIN charge_type ON station_charge.charge_type_id = charge_type.charge_type_id
		WHERE station_charge_id = :NEW.station_charge_id;

		rec_station_charge cur_station_charge%ROWTYPE;

begin     

	if inserting then 
		if :NEW.client_station_id  is null then
			SELECT client_station_id_seq.nextval into :NEW.client_station_id  from dual;

			:NEW.number_of_approved_stations := :NEW.number_of_requested_stations;
			
			--test
			OPEN cur_station_charge;
			FETCH cur_station_charge INTO rec_station_charge ;
			
			IF (rec_station_charge.has_fixed_charge = '1') THEN
				:NEW.tentative_price := rec_station_charge.initial_fee;
				:NEW.final_price := rec_station_charge.annual_fee;
				RETURN;
			END IF;

			IF (rec_station_charge.station_charge_id = 23) THEN
				
				val := :NEW.number_of_requested_stations;
				dbms_output.put_line('Before Algo val = ' || val);
				WHILE (mod(val,5) != 0) --max is not divisible by 5
					LOOP
						val := val + 1;						            					
					END LOOP;
				dbms_output.put_line('After Algo val = ' || val);

				:NEW.number_of_approved_stations := val;

				--tprice := 1250 * val;
				tprice := rec_station_charge.amount * val;
				fprice := tprice;
				
				:NEW.tentative_price := tprice;
				:NEW.final_price := fprice;

				
				INSERT INTO station(station_charge_id, service_nature_id, vhf_network_id, number_of_frequencies, units_requested)
						VALUES(:NEW.station_charge_id,'CV', :NEW.vhf_network_id, :NEW.number_of_frequencies,val);
				
        /*
				WHILE (val != 0) 

					LOOP
						insert into station(station_charge_id,service_nature_id,vhf_network_id, number_of_frequencies)
							select :NEW.station_charge_id, 'CV', :NEW.vhf_network_id, :NEW.number_of_frequencies
							from vhf_network where vhf_network_id = :NEW.vhf_network_id;
						val := val - 1;						
					END LOOP;
        */  

				RETURN;

			END IF;



			--:NEW.tentativeprice := tprice;
			--:NEW.finalprice := fprice;

			--test insert into stations 
				--issues
				--1. (what about aiCraft > if station_charge.station_class_id is MA then its an airec_station_charge raft ??
				--2. receivers ???? > if station_charge.station_class_id is ML then its a receiver ??
				--3. alarms - b4 insert done (b4 update pending)
			

			--FOR LAND MOBILE
			IF (rec_station_charge.station_class_id = 'ML' OR rec_station_charge.station_class_id = 'FB') THEN				
	
				IF (rec_station_charge.per_station = '1') THEN
					tprice := rec_station_charge.amount * :NEW.number_of_requested_stations;
					fprice := rec_station_charge.amount * :NEW.number_of_approved_stations;
				END IF;
				
				IF (rec_station_charge.per_frequency = '1') THEN
					tprice := tprice * :NEW.number_of_frequencies;
					fprice := tprice;
				END IF;

				:NEW.tentative_price := tprice;
				:NEW.final_price := fprice;	

				val := :NEW.number_of_requested_stations;
				WHILE (val != 0) 
					LOOP
						insert into station(station_charge_id,service_nature_id,vhf_network_id, number_of_frequencies)
							select :NEW.station_charge_id, 'CV', :NEW.vhf_network_id, :NEW.number_of_frequencies
							from vhf_network where vhf_network_id = :NEW.vhf_network_id;
						val := val - 1;						
					END LOOP;
				RETURN;
			END IF;

			--for amateur stations
			--IF (rec_station_charge .stationclassid = 'AT') THEN

				--RETURN;
			--end if;

		--broadcasting 

		end if;		--IF pk is null
	end if; 		--end if inserting


	if updating then 

		:NEW.number_of_approved_stations := :NEW.number_of_requested_stations;
		
		--test
		OPEN cur_station_charge;
		FETCH cur_station_charge INTO rec_station_charge;
			
		IF (rec_station_charge.has_fixed_charge = '1') THEN
			:NEW.tentative_price := rec_station_charge.initial_fee;
			:NEW.final_price := rec_station_charge.annual_fee;
			RETURN;
		END IF;

		IF (rec_station_charge.functname = 'alarms') THEN
			
			val := :NEW.number_of_requested_stations;
			dbms_output.put_line('Before Algo val = ' || val);
			WHILE (mod(val,5) != 0) --max is not divisible by 5
				LOOP
					val := val + 1;						
				END LOOP;
			dbms_output.put_line('After Algo val = ' || val);

			:NEW.number_of_approved_stations := val;

			--tprice := 1250 * val;
			tprice := rec_station_charge.amount * val;
			fprice := tprice;
			
			:NEW.tentative_price := tprice;
			:NEW.final_price := fprice;

			--we may need to update the stations !!!!!!!

			RETURN;

		END IF;


		--FOR LAND MOBILE
		IF (rec_station_charge.station_class_id = 'ML' OR rec_station_charge.station_class_id = 'FB') THEN				

			IF (rec_station_charge.per_station = '1') THEN
				tprice := rec_station_charge.amount * :NEW.number_of_requested_stations;
				fprice := rec_station_charge.amount * :NEW.number_of_approved_stations;
			END IF;
			
			IF (rec_station_charge.per_frequency = '1') THEN
				tprice := tprice * :NEW.number_of_frequencies;
				fprice := tprice;
			END IF;

			:NEW.tentative_price := tprice;
			:NEW.final_price := fprice;	

			val := :NEW.number_of_requested_stations;
			--we may need to update the stations !!!!!!!
			RETURN;
      
		END IF;

			--for amateur stations
			--IF (rec_station_charge .stationclassid = 'AT') THEN

				--RETURN;
			--end if;

	end if; 		--end if inserting
end;
/







--TERRESTRIAL LINKS.. including point to point and single channel
CREATE TABLE terrestrial_link(
	terrestrial_link_id 			integer primary key,
	client_license_id				integer references client_license, 
	--transmitstation_id				integer references stations,			--may refer to the link(station) in case of terrestrials 
	station_charge_id				integer references station_charge,
	status_station_id 				integer references status_station,
	--service_nature_id			char(2) references service_nature, 	--nature of service
	--vhf_network_id			integer references vhf_network,			--vhf networks have to be grouped to simplify freq assignment
	
	--trunked_radio_typeid		integer references trunked_radio_type,
	--duplexmethodid			integer,		--references duplexmethod

	station_a_id				integer references station,
	station_b_id				integer references station,

	--site_id		 			integer references site,
	--entity_id					integer references entitys,	
	--radiobroadcastingtypeid	integer references radiobroadcastingtype,

	--istransmitter				char(1) default '0',
	is_active					char(1) default '1',		--means not decomissioned
	decommission_date			date,

	terrestrial_link_name		varchar(100), 	
	requested_frequency_bands	varchar(250),		--DURING APPLICATION STAGE


	--b4 training
	requested_spot_frequencies 	varchar(500),

	--frequency band requested 
	requested_frequency 		real,		--in MHz	
	requested_frequency_GHz		real,		--in GHz

	requested_bandwidth			real,		--in KHz
	requested_bandwidth_MHz		real,		--in MHz
	requested_bandwidth_GHz		real,		--in GHz		
	
	annual_station_charge		real,					--full station charge without considering proration. used in annual payment
	prorated_charge				real,					--prorated charge. used in initial payment
	initial_charge_period		int,					--if >= 12 months, payment includes next period's

	capacity_mpbs			varchar(50),
	is_rural					char(1) default '0',
	for_export				char(1) default '0',
	is_declared				char(1) default '0',

	number_of_sectors			integer default 1,
	tx_per_sector				integer default 1,
	
	details					clob
	);
ALTER TABLE terrestrial_link ADD zone_factor real default 1 not null;

ALTER TABLE terrestrial_link ADD num_of_rf_channels	integer;
ALTER TABLE terrestrial_link ADD path_length_km integer;
ALTER TABLE terrestrial_link ADD location VARCHAR(50);
ALTER TABLE terrestrial_link ADD proposed_operation_date date;
ALTER TABLE terrestrial_link ADD service_nature_id		char(2) references service_nature;



--SITE A
ALTER TABLE terrestrial_link ADD site_A_id integer references site;
ALTER TABLE terrestrial_link ADD station_A_name	varchar(50);
ALTER TABLE terrestrial_link ADD A_max_operation_hours	real default 24;
ALTER TABLE terrestrial_link ADD A_feeder_type	varchar(50);
ALTER TABLE terrestrial_link ADD A_attenuation	real default 0;
ALTER TABLE terrestrial_link ADD A_feeder_loss	real default 0;
ALTER TABLE terrestrial_link ADD A_equipment_id	integer references equipment;
ALTER TABLE terrestrial_link ADD A_antenna_type_id	integer references antenna_type;
ALTER TABLE terrestrial_link ADD A_modulation_type_code	char(1) references modulation_type(code);
ALTER TABLE terrestrial_link ADD A_nature_of_signal_code	char(1) references nature_of_signal(code);
ALTER TABLE terrestrial_link ADD A_type_of_information_code	char(1) references type_of_information(code);
ALTER TABLE terrestrial_link ADD A_signal_detail_code		char(1) references signal_detail(code);
ALTER TABLE terrestrial_link ADD A_mux_nature_code			char(1) references mux_nature(code);
ALTER TABLE terrestrial_link ADD station_A_code	varchar(50);

ALTER TABLE terrestrial_link ADD site_A_name varchar(30);
ALTER TABLE terrestrial_link ADD longitude_A_degrees real;
ALTER TABLE terrestrial_link ADD longitude_A_minutes real;
ALTER TABLE terrestrial_link ADD longitude_A_seconds real;
ALTER TABLE terrestrial_link ADD latitude_A_degrees real;
ALTER TABLE terrestrial_link ADD latitude_A_minutes real;
ALTER TABLE terrestrial_link ADD latitude_A_seconds real;

ALTER TABLE terrestrial_link ADD longitude_A_decimal real;
ALTER TABLE terrestrial_link ADD latitude_A_decimal real;
ALTER TABLE terrestrial_link ADD lat_A_pos char(1);			--N or S
ALTER TABLE terrestrial_link ADD long_A_pos char(1);		--ALWAYS E 
SET SCAN OFF;
ALTER TABLE terrestrial_link DROP COLUMN site_A_map;
ALTER TABLE terrestrial_link ADD site_A_map AS ('<a href="map.html?Lat=' || TRIM(DECODE(lat_A_pos,'S',('-'||latitude_A_decimal),latitude_A_decimal)) || '&Long=' || trim(longitude_A_decimal) ||  '" target="_blank"> Site A Map </a>');


--SITE B
ALTER TABLE terrestrial_link ADD site_B_id integer references site;
ALTER TABLE terrestrial_link ADD station_B_name	varchar(50);
ALTER TABLE terrestrial_link ADD B_max_operation_hours	real default 24;
ALTER TABLE terrestrial_link ADD B_feeder_type	varchar(50);
ALTER TABLE terrestrial_link ADD B_attenuation	real default 0;
ALTER TABLE terrestrial_link ADD B_feeder_loss	real default 0;
ALTER TABLE terrestrial_link ADD B_equipment_id	integer references equipment;
ALTER TABLE terrestrial_link ADD B_antenna_type_id	integer references antenna_type;
ALTER TABLE terrestrial_link ADD B_modulation_type_code	char(1) references modulation_type(code);
ALTER TABLE terrestrial_link ADD B_nature_of_signal_code	char(1) references nature_of_signal(code);
ALTER TABLE terrestrial_link ADD B_type_of_information_code	char(1) references type_of_information(code);
ALTER TABLE terrestrial_link ADD B_signal_detail_code		char(1) references signal_detail(code);
ALTER TABLE terrestrial_link ADD B_mux_nature_code			char(1) references mux_nature(code);
ALTER TABLE terrestrial_link ADD station_B_code	varchar(50);

ALTER TABLE terrestrial_link ADD site_B_name varchar(30);
ALTER TABLE terrestrial_link ADD longitude_B_degrees real;
ALTER TABLE terrestrial_link ADD longitude_B_minutes real;
ALTER TABLE terrestrial_link ADD longitude_B_seconds real;
ALTER TABLE terrestrial_link ADD latitude_B_degrees real;
ALTER TABLE terrestrial_link ADD latitude_B_minutes real;
ALTER TABLE terrestrial_link ADD latitude_B_seconds real;

ALTER TABLE terrestrial_link ADD longitude_B_decimal real;
ALTER TABLE terrestrial_link ADD latitude_B_decimal real;
ALTER TABLE terrestrial_link ADD lat_B_pos char(1);			--N or S
ALTER TABLE terrestrial_link ADD long_B_pos char(1);		--ALWAYS E 
SET SCAN OFF;
ALTER TABLE terrestrial_link DROP COLUMN site_B_map;
ALTER TABLE terrestrial_link ADD site_B_map AS ('<a href="map.html?Lat=' || TRIM(DECODE(lat_A_pos,'S',('-'||latitude_B_decimal),latitude_B_decimal)) || '&Long=' || TRIM(longitude_B_decimal) ||  '" target="_blank"> Site B Map </a>');

CREATE SEQUENCE terrestrial_link_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_terrestrial_link_id BEFORE INSERT OR UPDATE ON terrestrial_link
FOR EACH ROW

DECLARE	
		unit_fee 		real;		--for 8.5 khz bandwidth
		k1 				real;
		num_channels 	integer;

BEGIN

	if inserting then 
		if :NEW.terrestrial_link_id  is null then
			SELECT terrestrial_link_id_seq.nextval into :NEW.terrestrial_link_id  from dual;
		end if;
		
		--point a
		:NEW.longitude_A_decimal := (:NEW.longitude_A_degrees * 1) + (:NEW.longitude_A_minutes/60) + (:NEW.longitude_A_seconds/3600);
		:NEW.latitude_A_decimal := (:NEW.latitude_A_degrees * 1) + (:NEW.latitude_A_minutes/60) + (:NEW.latitude_A_seconds/3600);
		
		--point b
		:NEW.longitude_B_decimal := (:NEW.longitude_B_degrees * 1) + (:NEW.longitude_B_minutes/60) + (:NEW.longitude_B_seconds/3600);
		:NEW.latitude_B_decimal := (:NEW.latitude_B_degrees * 1) + (:NEW.latitude_B_minutes/60) + (:NEW.latitude_B_seconds/3600);

		unit_fee := 574.10;
		num_channels := :NEW.num_of_rf_channels;

		IF(:NEW.requested_frequency_GHz <= 1)THEN
			K1 := 0.9;		
		ELSIF((:NEW.requested_frequency_GHz > 1) AND (:NEW.requested_frequency_GHz <= 10))THEN
			K1 := 0.3;		
		ELSIF((:NEW.requested_frequency_GHz > 10) AND (:NEW.requested_frequency_GHz <= 20))THEN
			K1 := 0.21;
		ELSIF((:NEW.requested_frequency_GHz > 20) AND (:NEW.requested_frequency_GHz <= 30))THEN
			K1 := 0.15;				
		ELSIF(:NEW.requested_frequency_GHz > 30)THEN
			K1 := 0.1;
		END IF;

		:NEW.annual_station_charge := ((:NEW.requested_bandwidth_MHz*1000)/8.5) * k1 * unit_fee * num_channels;
		
		:NEW.annual_station_charge := :NEW.annual_station_charge * :NEW.zone_factor;		

		--:NEW.proratedcharge := :NEW.stationcharge * :NEW.initialchargeperiod/12;

	end if; 

	if updating then 
		
		--point a
		:NEW.longitude_A_decimal := (:NEW.longitude_A_degrees * 1) + (:NEW.longitude_A_minutes/60) + (:NEW.longitude_A_seconds/3600);
		:NEW.latitude_A_decimal := (:NEW.latitude_A_degrees * 1) + (:NEW.latitude_A_minutes/60) + (:NEW.latitude_A_seconds/3600);
		
		--point b
		:NEW.longitude_B_decimal := (:NEW.longitude_B_degrees * 1) + (:NEW.longitude_B_minutes/60) + (:NEW.longitude_B_seconds/3600);
		:NEW.latitude_B_decimal := (:NEW.latitude_B_degrees * 1) + (:NEW.latitude_B_minutes/60) + (:NEW.latitude_B_seconds/3600);

		unit_fee := 574.10;
		num_channels := :NEW.num_of_rf_channels;

		IF(:NEW.requested_frequency_GHz <= 1)THEN
			K1 := 0.9;		
		ELSIF((:NEW.requested_frequency_GHz > 1) AND (:NEW.requested_frequency_GHz <= 10))THEN
			K1 := 0.3;		
		ELSIF((:NEW.requested_frequency_GHz > 10) AND (:NEW.requested_frequency_GHz <= 20))THEN
			K1 := 0.21;
		ELSIF((:NEW.requested_frequency_GHz > 20) AND (:NEW.requested_frequency_GHz <= 30))THEN
			K1 := 0.15;				
		ELSIF(:NEW.requested_frequency_GHz > 30)THEN
			K1 := 0.1;
		END IF;

		:NEW.annual_station_charge := ((:NEW.requested_bandwidth_MHz*1000)/8.5) * k1 * unit_fee * num_channels;
		
		:NEW.annual_station_charge := :NEW.annual_station_charge * :NEW.zone_factor;		

		--:NEW.proratedcharge := :NEW.stationcharge * :NEW.initialchargeperiod/12;

	end if; 
end;
/


create table modulation_type(
	modulation_type_id		integer primary key,
	modulation_type			varchar(500),
	code					char(1) unique,
	details					varchar(100)
	);

insert into modulation_type(modulation_type_id, modulation_type, code) values(1,'Unmodulated carrier','N');
insert into modulation_type(modulation_type_id, modulation_type, code)  values(2,'Amplitude modulated - Double sideband','A');
insert into modulation_type(modulation_type_id, modulation_type, code)  values(3,'Amplitude modulated - Single sideband full carrier','H');
insert into modulation_type(modulation_type_id, modulation_type, code) values(4,'Amplitude modulated - Single sideband reduced or variable level carrier','R');
insert into modulation_type(modulation_type_id, modulation_type, code)  values(5,'Amplitude modulated - Single sideband suppressed carrier','J');
insert into modulation_type(modulation_type_id, modulation_type, code)  values(6,'Amplitude modulated - Independent sidebands','B');
insert into modulation_type(modulation_type_id, modulation_type, code)  values(7,'Amplitude modulated - Vestigial sideband','C');
insert into modulation_type(modulation_type_id, modulation_type, code)  values(8,'Angle modulated - Frequency modulation','F');
insert into modulation_type(modulation_type_id, modulation_type, code)  values(9,'Angle modulated - Phase modulation','G');
insert into modulation_type(modulation_type_id, modulation_type, code)  values(10,'Emission in which the main carrier is amplitude- and angle-modulated either simultaneously or in a pre-established sequence','D');
insert into modulation_type(modulation_type_id, modulation_type, code)  values(11,'Emmission of Pulses - unmodulated','P');
insert into modulation_type(modulation_type_id, modulation_type, code)  values(12,'Sequence of pulses - modulated in amplitude','K');
insert into modulation_type(modulation_type_id, modulation_type, code)  values(13,'Sequence of pulses - modulated in width-duration','L');
insert into modulation_type(modulation_type_id, modulation_type, code)  values(14,'Sequence of pulses - modulated in position-phase','M');
insert into modulation_type(modulation_type_id, modulation_type, code)  values(15,'Sequence of pulses - main carrier is angle-modulated during the angle period of the pulse','Q');
insert into modulation_type(modulation_type_id, modulation_type, code)  values(16,'Sequence of pulses - which is a combination of the foregoing or is produced by other means','V');
insert into modulation_type(modulation_type_id, modulation_type, code)  values(17,'Cases not covered above in which an emission consists of the main carrier modulated either simultaneously or in a pre-established sequence or a combination of the two or more of the following modes amplitude angle or pulse','W');
insert into modulation_type(modulation_type_id, modulation_type, code)  values(18,'Cases not otherwise covered','X');


create table nature_of_signal(
	nature_of_signal_id		integer primary key,
	nature_of_signal		varchar(200),
	code					char(1) unique,
	details					varchar(100)
	);
insert into nature_of_signal(nature_of_signal_id,nature_of_signal,code) values(1,'No modulating signal','O');
insert into nature_of_signal(nature_of_signal_id,nature_of_signal,code) values(2,'A single channel containing quantized or digital information without the use of a modulating sub-carrier','1');
insert into nature_of_signal(nature_of_signal_id,nature_of_signal,code) values(3,'A single channel containing quantized or digital information with the use of a modulating sub-carrier','2');
insert into nature_of_signal(nature_of_signal_id,nature_of_signal,code) values(4,'A single channel containing analogue information','3');
insert into nature_of_signal(nature_of_signal_id,nature_of_signal,code) values(5,'Two or more channels containing quantized or digital information','7');
insert into nature_of_signal(nature_of_signal_id,nature_of_signal,code) values(6,'Two or more channels containing analogue information','8');
insert into nature_of_signal(nature_of_signal_id,nature_of_signal,code) values(7,'Composite system with one or more channels containing quantized or digital information, together with one or more channels containing analogue information','9');
insert into nature_of_signal(nature_of_signal_id,nature_of_signal,code) values(8,'Cases not otherwise covered','X');



create table type_of_information(
	type_of_information_id		integer primary key,
	type_of_information		varchar(200),
	code					char(1) unique,
	details					varchar(100)
	);
insert into type_of_information(type_of_information_id,type_of_information,code) values(1,'No information is transmitted','N');
insert into type_of_information(type_of_information_id,type_of_information,code)  values(2,'Telegraphy - for aural reception','A');
insert into type_of_information(type_of_information_id,type_of_information,code)  values(3,'Telegraphy - for automatic reception','B');
insert into type_of_information(type_of_information_id,type_of_information,code)  values(4,'Fascimile','C');
insert into type_of_information(type_of_information_id,type_of_information,code)  values(5,'Data transmission telemetry telecommand','D');
insert into type_of_information(type_of_information_id,type_of_information,code)  values(6,'Telephony - including sound broadcasting','E');
insert into type_of_information(type_of_information_id,type_of_information,code)  values(7,'Television - video','F');
insert into type_of_information(type_of_information_id,type_of_information,code)  values(8,'Combination of the above','W');
insert into type_of_information(type_of_information_id,type_of_information,code)  values(10,'Cases not otherwise covered','X');



create table signal_detail(
	signal_detail_id		integer primary key,
	signal_detail		varchar(500),
	code				char(1) unique,
	details					varchar(100)
	);
insert into signal_detail(signal_detail_id,signal_detail,code) values(1,'Two-condition code with elements of differing numbers and durations','A');
insert into signal_detail(signal_detail_id,signal_detail,code) values(2,'Two-condition code with elements of the same number and duration without error-correction','B');
insert into signal_detail(signal_detail_id,signal_detail,code) values(3,'Two-condition code with elements of the same number and duration with error-correction','C');
insert into signal_detail(signal_detail_id,signal_detail,code) values(4,'Four-condition code in which each condition represents a signal element - one or more bits','D');
insert into signal_detail(signal_detail_id,signal_detail,code) values(5,'Multi-condition code in which each condition represents a signal element - one or more bits','E');
insert into signal_detail(signal_detail_id,signal_detail,code) values(6,'Multi-condition code in which each condition or combination of conditions represents a character','F');
insert into signal_detail(signal_detail_id,signal_detail,code) values(7,'Sound of broadcasting quality - monophonic','G');
insert into signal_detail(signal_detail_id,signal_detail,code) values(8,'Sound of broadcasting quality - stereophonic or quadrophonic','H');

insert into signal_detail(signal_detail_id,signal_detail,code) values(9,'Sound of commercial quality - excluding K and L','J');
insert into signal_detail(signal_detail_id,signal_detail,code) values(10,'Sound of commercial quality with the use of frequency inversion or band splitting','K');
insert into signal_detail(signal_detail_id,signal_detail,code) values(11,'Sound of commercial quality with separate frequency-modulated signals to control the level of demodulated signal','L');
insert into signal_detail(signal_detail_id,signal_detail,code) values(12,'Monochrome','M');
insert into signal_detail(signal_detail_id,signal_detail,code) values(13,'Color','N');

insert into signal_detail(signal_detail_id,signal_detail,code) values(14,'Combination of above','W');
insert into signal_detail(signal_detail_id,signal_detail,code) values(15,'Cases not otherwise covered','X');


create table mux_nature(
	mux_nature_id		integer primary key,
	mux_nature		varchar(200),
	code			char(1) unique,
	details					varchar(100)
	);
insert into mux_nature(mux_nature_id,mux_nature,code) values(1,'None','N');
insert into mux_nature(mux_nature_id,mux_nature,code)  values(2,'Code division multiplex','C');
insert into mux_nature(mux_nature_id,mux_nature,code)  values(3,'Frequency division multiplex','F');
insert into mux_nature(mux_nature_id,mux_nature,code)  values(4,'Time division multiplex','T');
insert into mux_nature(mux_nature_id,mux_nature,code)  values(5,'Combination of frequency division multiplex and time division multiplex','W');
insert into mux_nature(mux_nature_id,mux_nature,code)  values(6,'Other types of multiplexing','X');




CREATE TABLE emmission_designation(
	emmission_designation_id 	integer primary key,
	--station_equip_id 		integer references station_equip,	--
	--AIRCRAFTEQUIPMENTID 	integer , --references aircraftequipemnt
	station_id				integer references station,		--use this to get the station equipment [for stations that can only have one equip]
	entity_id					integer references entitys,

	band_width_code_id			varchar(5),		--this should be a virtual column

	modulation_type_code		char(1) references modulation_type(code),					--first symbol
	nature_of_signal_code		char(1) references nature_of_signal(code),					--second
	type_of_information_code	char(1) references type_of_information(code),					--third
	signal_detail_code			char(1) references signal_detail(code),					--fourth
	mux_nature_code				char(1) references mux_nature(code),					--fifth	
	
	details						clob
	);
CREATE SEQUENCE emmission_designation_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_emmission_designation_id BEFORE INSERT ON emmission_designation
for each row 
begin     
	if inserting then 
		if :NEW.emmission_designation_id  is null then
			SELECT emmission_designation_id_seq.nextval into :NEW.emmission_designation_id  from dual;
		end if;
	end if; 
end;
/







--PLANNING

--based on ITU
CREATE TABLE band_definition(
	band_definition_id	integer primary key,
	band_definition		varchar2(150),		--band definitions eg VHF,UHF,MF,etc
	lower_limit			integer,
	upper_limit			integer,
	units_of_measure	varchar(10),
	details				clob
);
CREATE SEQUENCE band_definition_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_band_definition_id BEFORE INSERT ON band_definition
for each row 
begin     
	if inserting then 
		if :NEW.band_definition_id  is null then
			SELECT band_definition_id_seq.nextval into :NEW.band_definition_id from dual;
		end if;
	end if; 
end;
/



--for BAND assignment 
CREATE TABLE amateur_type(
	amateur_type_id		integer primary key,
	amateur_type_name	varchar2(200),
	details				clob	
	);
INSERT INTO amateur_type(amateur_type_id,amateur_type_name) VALUES(1,'Full Amateur');
INSERT INTO amateur_type(amateur_type_id,amateur_type_name)  VALUES(2,'Temporary Amateur');
INSERT INTO amateur_type(amateur_type_id,amateur_type_name)  VALUES(3,'Novice Amateur');

--for band assignment 
CREATE TABLE aircraft_band_type(
	aircraft_band_type_id		integer primary key,
	aircraft_band_type_name		varchar2(200),
	details					clob	
	);
INSERT INTO aircraft_band_type(aircraft_band_type_id,aircraft_band_type_name) VALUES(1,'HF (2MHz - 18MHz)');	--HF (2MHz - 18MHz)
INSERT INTO aircraft_band_type(aircraft_band_type_id,aircraft_band_type_name) VALUES(2,'VHF (108MHz - 136MHz)');	--108 - 136
INSERT INTO aircraft_band_type(aircraft_band_type_id,aircraft_band_type_name) VALUES(3,'HF + VHF');
commit;



--for 7Ghz, 1.4 Ghz
CREATE TABLE channel_plan (
	channel_plan_id		integer primary key,
	itu_reference		varchar(100),
	channel_plan_name		varchar(100),		--name of the frequency band eg '200 – 283.5'
	description			varchar(150),	
	is_terrestrial		char(1) default '0',
	is_vhf				char(1) default '0',
	is_broadcasting		char(1) default '0',
	is_maritime			char(1) default '0',
	is_aeronautical		char(1) default '0',
	details 			clob
	);
ALTER TABLE channel_plan ADD is_hf	char(1) default '0';
ALTER TABLE channel_plan ADD TEMP_SUB_BAND_NAME varchar(150);
ALTER TABLE channel_plan ADD TEMP_START_FREQUENCY real;
ALTER TABLE channel_plan ADD TEMP_STOP_FREQUENCY real;
ALTER TABLE channel_plan ADD TEMP_DUPLEX_SPACING real;
ALTER TABLE channel_plan ADD TEMP_CHANNEL_SPACING real;
ALTER TABLE channel_plan ADD TEMP_UNITS_OF_MEASURE real;
ALTER TABLE channel_plan ADD TEMP_DO_APPEND varchar(150);
ALTER TABLE channel_plan ADD TEMP_BUTTON varchar(150);

--TEMP FIELDS FOR USE WHEN GENERATING NEW PLANS..,SUBBANDNAME,,,,,,,

CREATE SEQUENCE channel_plan_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_channel_plan_id BEFORE INSERT ON channel_plan
for each row 
begin     
	if inserting then 
		if :NEW.channel_plan_id is null then
			SELECT channel_plan_id_seq.nextval into :NEW.channel_plan_id from dual;
		end if;
	end if; 
end;
/





--according to KENYA TOFA (table of frequency allocation) (and CCK FSM)
CREATE TABLE frequency_band (
	frequency_band_id		integer primary key,
	band_definition_id	integer references band_definition,
	frequency_band_name	varchar(150),		--name of the frequency band eg '200 – 283.5'
	units_of_measure		varchar(10),		--eg Khz, Mhz, Ghz, etc
	lower_limit			real,		
	upper_limit			real,
	service_allocation	varchar(200),		--allocation to services
	remarks				clob,		
	fsm_remarks			clob
);
CREATE SEQUENCE frequency_band_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_frequency_band_id BEFORE INSERT ON frequency_band
for each row 
begin     
	if inserting then 
		if :NEW.frequency_band_id  is null then
			SELECT frequency_band_id_seq.nextval into :NEW.frequency_band_id from dual;
		end if;
	end if; 
end;
/




CREATE TABLE channel (
	channel_id		integer primary key,
	
	channel_plan_id		integer references channel_plan,

	sub_band_name			varchar(200) default 'No sub band',	--if any
	sub_band_description			varchar(50),	--subband description
	sub_band_annex				varchar(20),	--subbandannex - may contain itu_reference
	itu_reference		varchar(50),			--if ITU_REF not in channel_plan

	channel_spacing		real,				--difference btwn two channels (aka the bandwidth)
	duplex_spacing		real,				--difference btwn go n return channels	
	center_frequency		real,
	formula				varchar(100),

    channel_number	integer,
	transmit		number(10,4),				--number(10,4)		10 digits with 4 decimal places
    receive			number(10,4),
	units_of_measure	varchar(10),

	for_citizen_band	char(1),
	for_family_band	char(1),
	
	for_amateur			char(1),	--full amateur - amateurtype 1
	for_temp_amateur 	char(1),	--amateur type 2
	for_novice_amateur 	char(1),	--amateur type 3
	
	aircraft_hf			char(1),
	aircraft_vhf		char(1),

	for_aircraft		char(1),
	for_maritime		char(1),

	classes_of_emission	varchar(500),
	maximum_dc_input	varchar(100),
	rf_peak_output		varchar(100),

	footnotes			varchar(100),
	allocation			varchar(200),
	remarks				clob,
	details				clob,

	oldc_lients		clob			--used to hold list of old clients

);

CREATE INDEX channel_channel_plan ON channel (channel_plan_id);

CREATE SEQUENCE channel_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_channel_id BEFORE INSERT ON channel
for each row 
begin     
	if inserting then 
		if :NEW.channel_id  is null then
			SELECT channel_id_seq.nextval into :NEW.channel_id from dual;
		end if;
	end if; 
end;
/


--TOFA FOOTNOTE DESCRIPTION
CREATE TABLE footnote_definition(
	footnote_definition_id	integer primary key,
	footnote_definition	varchar(20),
	footnote_description	clob		
	);
CREATE SEQUENCE footnote_definition_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_footnote_definition_id BEFORE INSERT ON footnote_definition
for each row 
begin     
	if inserting then 
		if :NEW.footnote_definition_id  is null then
			SELECT footnote_definition_id_seq.nextval into :NEW.footnote_definition_id from dual;
		end if;
	end if; 
end;
/


--CONNECT all/relevant footnotes to the frequencyband
CREATE TABLE footnote_frequency_band(
	footnote_frequency_band_id		integer primary key,
	footnote_definition_id		integer references footnote_definition,
	frequency_band_id				integer references frequency_band,
	details						clob
	);
CREATE SEQUENCE footnote_frequency_band_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_footnote_frequency_band_id BEFORE INSERT ON footnote_frequency_band
for each row 
begin     
	if inserting then 
		if :NEW.footnote_frequency_band_id  is null then
			SELECT footnote_frequency_band_id_seq.nextval into :NEW.footnote_frequency_band_id from dual;
		end if;
	end if; 
end;
/










--assigned/reserved frequencies .. aka table frequencies
CREATE TABLE frequency_assignment(

	frequency_assignment_id			integer primary key,
	station_id 			integer references station, 

	vhf_network_id		integer references vhf_network,	--all stations in this vhf network should default to this band/freq so that we can later edit them manualy if needed

	channel_id			integer references channel,	

	band_assignment_id	integer references band_assignment,
	amateur_type_id		integer references amateur_type,	--this is used to enable block assignemt of channels for amateur radios. done at bandassignment
	aircraft_band_type_id		integer references aircraft_band_type,	--for block assignment of aircraft bands

	tx_frequency			float,		--discrete
	rx_frequency			float,		--discrete

	is_reserved			char(1) default '0',		--assignment is in progress, applicant can now get the offer letter
	is_active			char(1) default '0',		--assignment completed, ready for billing

	--reserveddate		date
	--assigndate		date
	action_date 			date default sysdate,

	tx_frequency_band	varchar(50),
	rx_frequency_band	varchar(50),

	details				clob
);
ALTER TABLE frequency_assignment ADD terrestrial_link_id INTEGER REFERENCES terrestrial_link;
/*CREATE INDEX frequencys_station_id ON frequency_assignment (station_id);
CREATE INDEX frequencys_vhf_network_id ON frequency_assignment (vhf_network_id);
CREATE INDEX frequencys_channel_id ON frequency_assignment (channel_id);
CREATE INDEX frequencys_band_assignment_id ON frequency_assignment (band_assignment_id);*/
		
CREATE SEQUENCE frequency_assignment_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_frequency_id BEFORE INSERT ON frequency_assignment
for each row 
declare
	
	bw 					real;	--KHz
	separation 			real;	--MHz

	operating_band 		real;	--GHz
	channel_plan_band 	real;	--GHz (derived from the first part of the channel plan name)

	num_of_frequencies_requested 	integer;
	total_assigned_frequencies 		integer;
	frequencies_in_channel			integer;		--how may frequencies does a single channel have (ie is transmit = recieve?)

	no_amateur_bands_assigned 		integer;			--for amateur and aircraft (plz NOTE this is not equivalent to number of channels assigned)
	no_aircraft_bands_assigned 		integer;			--NUMBER OF aircraft bands assigned

	lic_id 				integer;
	is_terr 			char(1);

begin     

	if inserting then 

		if :NEW.frequency_assignment_id  is null then
			SELECT frequency_assignment_id_seq.nextval into :NEW.frequency_assignment_id from dual;		
		end if;

		--initialization 
		no_amateur_bands_assigned := 0;
		no_aircraft_bands_assigned := 0;
	
		--INITIALIZATION BLOCK
		IF :NEW.terrestrial_link_id IS NOT NULL THEN		--IF POINT TO POINT
			--identify the license
			select license.license_id, '1' into lic_id, is_terr
				from license
				inner join client_license on license.license_id = client_license.license_id				
				inner join terrestrial_link on client_license.client_license_id = terrestrial_link.client_license_id
				where terrestrial_link.terrestrial_link_id = :new.terrestrial_link_id;

				--IDENTIFY requested bandwidth(khz) and operating band (GHz)
				select (terrestrial_link.requested_bandwidth_MHz), terrestrial_link.requested_frequency_GHz 
					into bw, operating_band			--requestedbandwidth was stored in KHz
					from terrestrial_link where terrestrial_link_id = :new.terrestrial_link_id;

				--IDENTIFY the channel bandwidth/separation
				select channel.channel_spacing into separation	--channel spacing/separation is equivalent to channel bandwidth
				from channel where channel_id = :new.channel_id;
			
				--get channel operating band (accessible via channel_plan name)
				select cast(substr(channel_plan_name,0,instr(channel_plan_name,' ')) as float) into channel_plan_band
					from channel_plan 
					inner join channel on channel_plan.channel_plan_id = channel.channel_plan_id
					where channel.channel_id = :new.channel_id; -- and channel_plan.is_terrestrial='1' and 

		ELSIF :NEW.vhf_network_id IS NOT NULL THEN			--IF ALARM OR LAND MOBILE NETWORK
			--identify the license
			select license.license_id, '0' into lic_id, is_terr
				from license
				inner join client_license on license.license_id = client_license.license_id				
				inner join vhf_network on client_license.client_license_id = vhf_network.client_license_id
				where vhf_network.vhf_network_id = :new.vhf_network_id;

		ELSIF :NEW.station_id IS NOT NULL THEN

			--identify the license
			select license.license_id, license_type.is_terrestrial into lic_id, is_terr
				from license
				inner join client_license on license.license_id = client_license.license_id
				inner join license_type on license.license_type_id = license_type.license_type_id 
				inner join station on client_license.client_license_id = station.client_license_id
				where station.station_id = :new.station_id;

			--IDENTIFY requested bandwidth
			select station.requested_bandwidth into bw			--requestedbandwidth was stored in KHz
				from station where station_id = :new.station_id;

			--IDENTIFY the channel bandwidth/separation
			select channel.channel_spacing into separation	--channel spacing is equivalent to channel bandwidth
				from channel where channel_id = :new.channel_id;
		
			if (is_terr = '1') then			
				--get the requested band (GHz)
				select station.requested_frequencyGHz into operating_band			--requestedbandwidth was stored in KHz
					from station where station_id = :new.station_id;	
			
				--get channel operating band (accessible via channel_plan name)
				select cast(substr(channel_plan_name,0,instr(channel_plan_name,' ')) as float) into channel_plan_band
					from channel_plan 
					inner join channel on channel_plan.channel_plan_id = channel.channel_plan_id
					where channel_plan.is_terrestrial='1' and channel.channel_id = :new.channel_id;

			end if;

		
		END IF;

		--FREQUENCY ASSIGNMENT BLOCK
		IF(:new.vhf_network_id IS NOT NULL) THEN
			--NUMBER OF FREQUENCIES ASSIGNED SHOULD NOT EXCEED NUMBER OF FREQUENCIES REQUESTED
			--get the total number of already assigned frequencies
			select getNetworkFrequencies(:new.vhf_network_id) into total_assigned_frequencies from dual;

			--get the total number of requested frequencies
			select number_of_frequencies into num_of_frequencies_requested from vhf_network where vhf_network_id = :new.vhf_network_id;
			
			--if simplex requested (or remaining frequency is one) then make sure that only a simplex channel is assigned
			select decode(coalesce(channel.receive,0) - coalesce(channel.transmit,0),0,1,2) into frequencies_in_channel from channel where channel_id = :new.channel_id;

			if((num_of_frequencies_requested - total_assigned_frequencies) = 1)then 	--if only one required / remaining
				if(frequencies_in_channel > 1)then			--if user is attempting to imput a channel with more than one frequencies..
					raise_application_error(-20003,'THE NUMBER OF FREQUENCIES IN THE CHANNEL EXCEEDS THE NUMBER OF FREQUENCIES REQUIRED/REMAINING. NOT ASSIGNED');		
					return;
				end if;
			elsif(total_assigned_frequencies >= num_of_frequencies_requested) then
				raise_application_error(-20004,'ATTEMPT TO EXCEED THE NUMBER OF FREQUENCIES REQUESTED (' || num_of_frequencies_requested || ') HAS BEEN REJECTED');
				return;
			end if;
		--ELSIF(:new.terrestrial_link_id IS NOT NULL) THEN
        
		ELSIF(:new.station_id IS NOT NULL) THEN
				
			if (is_terr = '1') then  
				--CONFIRM BANDWIDTH
				if(bw/1000 != separation) then
					raise_application_error(-20001,'REQUESTED BANDWIDTH(' || (bw/1000) ||'MHz) IS DIFFERENT FROM THE CHANNEL BANDWIDTH (' || separation || 'MHz). REQUEST REJECTED');
				end if;
				--CONFIRM OPERATING BAND 
				if(operating_band != channel_plan_band) then
					raise_application_error(-20002,'REQUESTED BAND(' || (operating_band) ||'GHz) IS DIFFERENT FROM THE CHANNEL OPERATING BAND(' || channel_plan_band || 'GHz). REQUEST REJECTED');
				end if;

			end if;

			--NUMBER OF FREQUENCIES ASSIGNED SHOULD NOT EXCEED NUMBER OF FREQUENCIES REQUESTED
			--get the total number of already assigned frequencies
			select getNumberOfFrequencies(:new.station_id,'station') into total_assigned_frequencies from dual;

			--get the total number of requested frequencies
			select number_of_frequencies into num_of_frequencies_requested from station where station_id = :new.station_id;
			
			--if simplex requested (or remaining frequency is one) then make sure that only a simplex channel is assigned
			select decode(coalesce(channel.receive,0) - coalesce(channel.transmit,0),0,1,2) into frequencies_in_channel from channel where channel_id = :new.channel_id;

			if((num_of_frequencies_requested - total_assigned_frequencies) = 1)then 	--if only one required / remaining
				if(frequencies_in_channel > 1)then			--if user is attempting to imput a channel with more than one frequencies..
					raise_application_error(-20003,'THE NUMBER OF FREQUENCIES IN THE CHANNEL EXCEEDS THE NUMBER OF FREQUENCIES REQUIRED/REMAINING. NOT ASSIGNED');		
					return;
				end if;
			elsif(total_assigned_frequencies >= num_of_frequencies_requested) then
				raise_application_error(-20004,'ATTEMPT TO EXCEED THE NUMBER OF FREQUENCIES REQUESTED (' || num_of_frequencies_requested || ') HAS BEEN REJECTED');
				return;
			end if;

		ELSIF(:new.terrestrial_link_id IS NOT NULL) THEN
			
			if (is_terr = '1') then  
				--CONFIRM BANDWIDTH
				if(bw != separation) then
					raise_application_error(-20001,'REQUESTED BANDWIDTH(' || (bw) ||'MHz) IS DIFFERENT FROM THE CHANNEL BANDWIDTH (' || separation || 'MHz). REQUEST REJECTED');
				end if;
				--CONFIRM OPERATING BAND 
				if(operating_band != channel_plan_band) then
					raise_application_error(-20002,'REQUESTED OPERATING BAND(' || (operating_band) ||'GHz) IS DIFFERENT FROM THE CHANNEL OPERATING BAND(' || channel_plan_band || 'GHz). REQUEST REJECTED');
				end if;
		
				--NUMBER OF FREQUENCIES ASSIGNED SHOULD NOT EXCEED NUMBER OF FREQUENCIES REQUESTED
				--get the total number of already assigned frequencies
				select getNumberOfFrequencies(:new.terrestrial_link_id,'p2p') into total_assigned_frequencies from dual;                

				--get the total number of requested frequencies
				select num_of_rf_channels into num_of_frequencies_requested from terrestrial_link where terrestrial_link_id = :new.terrestrial_link_id;
			                
				--if simplex requested (or remaining frequency is one) then make sure that only a simplex channel is assigned
				select decode(coalesce(channel.receive,0) - coalesce(channel.transmit,0),0,1,2) into frequencies_in_channel from channel where channel_id = :new.channel_id;      
        
				if((num_of_frequencies_requested - total_assigned_frequencies) = 1)then 	--if only one required / remaining
					if(frequencies_in_channel > 1)then			--if user is attempting to imput a channel with more than one frequencies..
						raise_application_error(-20003,'THE NUMBER OF FREQUENCIES IN THE CHANNEL EXCEEDS THE NUMBER OF FREQUENCIES REQUIRED/REMAINING. NOT ASSIGNED');		
						return;
					end if;
				elsif(total_assigned_frequencies >= num_of_frequencies_requested) then
					raise_application_error(-20004,'ATTEMPT TO EXCEED THE NUMBER OF FREQUENCIES REQUESTED (' || num_of_frequencies_requested || ') HAS BEEN REJECTED');
					return;
				end if;

			end if;
		
		ELSIF (:new.amateur_type_id is not null) THEN
			
			select getNumberOfBands(:new.station_id, :new.amateur_type_id, '1', '0') into no_amateur_bands_assigned from dual;
			if (no_amateur_bands_assigned != 0) then
				raise_application_error(-20005,'RELEVANT AMATEUR BAND HAS ALREADY BEEN ASSIGNED. REQUEST REJECTED');
			end if;

		ELSIF (:new.aircraft_band_type_id is not null) THEN
			
			select getNumberOfBands(:new.station_id, :new.aircraft_band_type_id, '0', '1') into no_aircraft_bands_assigned from dual;
			if (no_aircraft_bands_assigned != 0) then
				raise_application_error(-20006,'RELEVANT AERONAUTICAL BAND HAS ALREADY BEEN ASSIGNED. REQUEST REJECTED');
			end if;

		END IF;
	
	end if;		--if inserting
	
  
  --EXCEPTION
	--WHEN OTHERS THEN
    --raise_application_error(-20020,'UNKNOWN ERROR Station id = ' || :new.station_id || ', Channel Id' || :new.channel_id);		
end;
/



--FOR STATIONS REQUIRING ASSIGNMENT OF SELECTED BANDS 
CREATE TABLE band_assignment(
	band_assignment_id	integer primary key,
	station_id 			integer references station, 
	aircraft_band_type_id		integer references aircraft_band_type,	--for block assignment of aircraft bands
	amateur_type_id		integer references amateur_type,	--this is used to enable block assignemt of channels for amateur radios
	details 			clob
	);

ALTER TABLE band_assignment ADD is_reserved			char(1) default '1';
ALTER TABLE band_assignment ADD is_active			char(1) default '0';


CREATE SEQUENCE band_assignment_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_band_assignment_id BEFORE INSERT ON band_assignment
for each row 
begin     
	if inserting then 
		if :NEW.band_assignment_id  is null then
			SELECT band_assignment_id_seq.nextval into :NEW.band_assignment_id from dual;
		end if;
	end if; 
end;
/


--PROPAGATE BAND ASSIGNENTS INTO THE FREQUENCY ASSIGNMENT TABLE
CREATE OR REPLACE TRIGGER tr_insert_bands AFTER INSERT ON band_assignment
for each row 
begin     

		--FOR AMATEUR RADIO
		if(:new.amateur_type_id = 1) then
			insert into frequency_assignment(station_id,channel_id,band_assignment_id,amateur_type_id)
			select :new.station_id,channel_id,:new.band_assignment_id,:new.amateur_type_id
				from channel where for_amateur = '1';			
		elsif(:new.amateur_type_id = 2) then
			insert into frequency_assignment(station_id,channel_id,band_assignment_id,amateur_type_id)
			select :new.station_id,channel_id,:new.band_assignment_id,:new.amateur_type_id
				from channel where for_temp_amateur = '1';
		elsif(:new.amateur_type_id = 3) then
			insert into frequency_assignment(station_id,channel_id,band_assignment_id,amateur_type_id)
			select :new.station_id,channel_id,:new.band_assignment_id,:new.amateur_type_id
				from channel where for_novice_amateur = '1';
		end if;

		--FOR AIRCRAFT
		if(:new.aircraft_band_type_id = 1) then		--HF
			insert into frequency_assignment(station_id,channel_id,band_assignment_id,aircraft_band_type_id)
			select :new.station_id,channel_id,:new.band_assignment_id,:new.aircraft_band_type_id
				from channel where aircraft_hf = '1';
		elsif(:new.aircraft_band_type_id = 2) then		--VHF
			insert into frequency_assignment(station_id,channel_id,band_assignment_id,aircraft_band_type_id)
			select :new.station_id,channel_id,:new.band_assignment_id,:new.aircraft_band_type_id
				from channel where aircraft_vhf = '1';
		elsif(:new.aircraft_band_type_id = 3) then		--HF + VHF
			insert into frequency_assignment(station_id,channel_id,band_assignment_id,aircraft_band_type_id)
			select :new.station_id,channel_id,:new.band_assignment_id,:new.aircraft_band_type_id
				from channel where aircraft_hf = '1' or aircraft_vhf = '1';
		end if;

end;
/



CREATE TABLE period_license (
	period_license_id		integer primary key,
	period_id				integer references period,
	client_license_id		integer references client_license,
	
	workflow_table_id 		integer,	

	--STATUSes
	--every changes in status within this period must be logged in TABLE client_license_status
	status_client_id		integer references status_client,	
	status_license_id 		integer references status_license,	
	
	annual_gross			real default 0 not null,
	non_license_revenue		real default 0 not null,
	license_revenue  		real AS (annual_gross - non_license_revenue),
	annual_fee_due  		real default 0 not null,--AS (0.5 * license_revenue),
	
	--COMPLIANCE
	--A. LICENSE CONDITIONS
	is_conditions_compliant 		CHAR(1 BYTE) DEFAULT '1' NOT NULL ENABLE, 	--compliant with license conditions
	conditions_notification_letter 	CLOB, 
	is_conditions_notice_sent		CHAR(1 BYTE) DEFAULT '0' NOT NULL ENABLE, 
	conditions_notification_date	DATE,
	

	--B. AAA (based on commisions financial year)
	is_AAA_compliant		 		CHAR(1 BYTE) DEFAULT '0' NOT NULL ENABLE, 
	AAA_notification_letter			CLOB, 
	is_AAA_notification_sent		CHAR(1 BYTE) DEFAULT '0' NOT NULL ENABLE, 
	AAA_notification_date 			date, 

	--C. COMPLIANCE based on CLIENTS financial period (NOT THE COMMISION'S)
	is_q1_received					char(1) default '0' not null,	--quarter 1 returns received
	q1_received_date				date,
	is_q2_received					char(1) default '0' not null,	--quarter 2 returns received
	q2_received_date				date,
	is_q3_received					char(1) default '0' not null,   --quarter 3 returns received
	q3_received_date				date,
	is_q4_received					char(1) default '0' not null,	--quarter 4 returns received
	q4_received_date				date,
	is_anual_returns_received		char(1) default '0' not null,			--annual returns submitted
	annual_returns_received_date	date,
	returns_notification_letter		CLOB, 
	is_returns_notification_sent	CHAR(1 BYTE) DEFAULT '0' NOT NULL ENABLE, 
	last_returns_notice_date		date, 			--coz we expect many returns per year/period
	is_ret_compliant_so_far			char(1) default '0' not null,	

	--C. FEE PAYMENT	
	is_order_to_finance_sent	char(1) default '0' not null,	
	order_date					date,
	is_invoced					char(1) default '0' not null,	
	invoice_date				date,
	is_fee_cleared				char(1) default '0' not null,	
	fee_notification_letter		clob,
	is_fee_notification_sent	char(1) default '0' not null,	
	fee_notification_date		date,

	--D. QoS --applicable for CELLULAR NETWORK OPERATORS
	is_QOS_compliant			CHAR(1 BYTE) DEFAULT '1' NOT NULL ENABLE, 	--defaults to unless Cellular Network is non compliant

	--E. inspection				
	is_passed_inspection		CHAR(1 BYTE) DEFAULT '0' NOT NULL ENABLE, 

	created_by					integer references entitys,
	created_date				date default sysdate not null,
	updated_by					integer references entitys,
	updated_date				date,

	UNIQUE(period_id,client_license_id)
);
ALTER TABLE period_license MODIFY is_passed_inspection DEFAULT '1';
ALTER TABLE period_license ADD is_worfklow_complete CHAR(1) DEFAULT '0' NOT NULL;		--AKA approved/complete...

ALTER TABLE period_license ADD notification_response clob;
ALTER TABLE period_license ADD conditions_deadline date;
ALTER TABLE period_license ADD conditions_penalty real default 0 not null;
ALTER TABLE period_license ADD penalty_remarks clob;

CREATE INDEX period_lic_period_id ON period_license (period_id);
CREATE INDEX period_lic_client_license_id ON period_license (client_license_id);
CREATE INDEX period_lic_status_license_id ON period_license (status_license_id);
CREATE INDEX period_lic_status_client_id ON period_license (status_client_id);

CREATE SEQUENCE period_license_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_period_license_id BEFORE INSERT ON period_license
for each row 
begin   
		
	if inserting then 
		if :NEW.period_license_id  is null then
			SELECT period_license_id_seq.nextval into :NEW.period_license_id  from dual;
		end if;

		SELECT workflow_table_id_seq.nextval into :NEW.workflow_table_id from dual;

		--:NEW.annual_fee_due := (0.5 * license_revenue);

	end if; 
end;
/


CREATE TABLE notice(

	notice_id				integer primary key,
	client_license_id		integer references client_license,
	client_inspection_id	integer references client_inspection,
	period_license_id		integer references period_license,

	notice_letter			clob,

	link_table_name			varchar(50),
	link_table_id			integer,

	notice_date				date,
	deadline_months			integer default 3 not null,

	--notice_deadline 		AS add_months(TO_CHAR(notice_date, 'DD/Mon/YYYY'), deadline_months),
	
				
	workflow_table_id 		integer,

	created					date default SYSDATE,
	created_by				integer references entitys,
	updated					date default SYSDATE,
	updated_by				integer references entitys,

	details					clob
	
	);
  
--ALTER TABLE notice ADD notice_deadline 	AS add_months(TO_CHAR(notice_date,'YYY'), deadline_months);
CREATE SEQUENCE notice_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;

create or replace TRIGGER tr_notice_id BEFORE INSERT ON notice for each row 
begin   
		
	if inserting then 
		if :NEW.notice_id  is null then
			SELECT notice_id_seq.nextval into :NEW.notice_id  from dual;
      
			SELECT workflow_table_id_seq.nextval into :NEW.workflow_table_id from dual;
		end if;

		if (:NEW.CLIENT_LICENSE_ID is null) and (:NEW.PERIOD_LICENSE_ID is not null) then
			BEGIN
				SELECT CLIENT_LICENSE_ID INTO :NEW.CLIENT_LICENSE_ID
				FROM PERIOD_LICENSE
				WHERE (PERIOD_LICENSE_ID = :NEW.PERIOD_LICENSE_ID);
				EXCEPTION WHEN NO_DATA_FOUND THEN :NEW.CLIENT_LICENSE_ID := null;
			END;
		end if;
	end if; 
end;
/


create or replace TRIGGER tr_notice_workflow AFTER UPDATE OR INSERT ON notice FOR EACH ROW 
DECLARE
	PRAGMA AUTONOMOUS_TRANSACTION;

	wfid 			INTEGER;
	apprid			INTEGER;
	appr_group		INTEGER;
	clientname		VARCHAR(120);
	tasktype		VARCHAR(120);
	wf_type 		VARCHAR2(64);
BEGIN  

	wfid := :NEW.workflow_table_id;			

	SELECT seq_approval_group.nextval INTO appr_group FROM dual;

	IF(:NEW.IS_NOTICE = '1') THEN wf_type := 'IS_NOTICE'; tasktype := 'Notice'; END IF;
	IF(:NEW.IS_PENALTY = '1') THEN wf_type := 'IS_PENALTY'; tasktype := 'Penalty'; END IF;
	IF(:NEW.IS_REVOCATION = '1') THEN wf_type := 'IS_REVOCATION'; tasktype := 'Revocation'; END IF;

	BEGIN
		IF(:NEW.client_license_id is not null) THEN
			SELECT client.client_name INTO clientname
			FROM client INNER JOIN client_license ON client.client_id = client_license.client_id
			WHERE (client_license.client_license_id = :NEW.client_license_id);
		END IF;
		IF(:NEW.client_inspection_id is not null) THEN
			SELECT client.client_name INTO clientname
			FROM client INNER JOIN client_inspection ON client.client_id = client_inspection.client_id
			WHERE (client_inspection_id = :NEW.client_inspection_id);
		END IF;
		EXCEPTION WHEN NO_DATA_FOUND THEN clientname := null;
	END;

	BEGIN
		SELECT max(approvals.approval_id) INTO apprid 
		FROM approvals INNER JOIN workflow_phases ON approvals.workflow_phase_id = workflow_phases.workflow_phase_id
			INNER JOIN workflows ON workflows.workflow_id = workflow_phases.workflow_id
		WHERE (approvals.table_id = wfid) AND (workflows.TABLE_LINK_FIELD = wf_type);
		EXCEPTION WHEN NO_DATA_FOUND THEN apprid := null;
	END;

	IF (apprid is not null) THEN wf_type := null; END IF;

	--INSERT THE FIRST APPROVALS to all the relevant entities
	INSERT INTO approvals (workflow_phase_id, approval_group, table_name, table_id, org_entity_id, app_entity_id, escalation_days, escalation_hours, approval_level, approval_narrative, to_be_done, task_source, task_type)
	SELECT workflow_phases.workflow_phase_id, appr_group, 'NOTICE', wfid, :NEW.created_by, entity_subscriptions.entity_id, 0, 3, 1, workflow_phases.phase_narrative, workflow_phases.phase_narrative, clientname, tasktype
		FROM workflow_phases
			INNER JOIN entity_subscriptions ON workflow_phases.approval_entity_id = entity_subscriptions.entity_type_id
			INNER JOIN workflows ON workflow_phases.workflow_id = workflows.workflow_id
			WHERE (workflows.table_name = 'NOTICE') AND (workflows.TABLE_LINK_FIELD = wf_type) AND (workflow_phases.approval_level='1')
			ORDER BY workflow_phases.approval_level, workflow_phases.workflow_phase_id;
	COMMIT;
	
	--... and checklists for the first level	
	INSERT INTO approval_checklists (checklist_id,workflow_table_id)
	SELECT checklist_id, wfid
		FROM checklists INNER JOIN workflow_phases ON checklists.workflow_phase_id = workflow_phases.workflow_phase_id
		INNER JOIN workflows ON workflow_phases.workflow_id = workflows.workflow_id
			WHERE (workflows.table_name = 'NOTICE') AND (workflows.TABLE_LINK_FIELD = wf_type) AND (workflow_phases.approval_level='1')
	ORDER BY workflow_phases.approval_level, workflow_phases.workflow_phase_id;
	COMMIT;
END;
/

--license conditions which have to be complied with..while the license is still in use
CREATE TABLE compliance_condition (
	compliance_condition_id	integer primary key,
	license_id				integer references license,
	narrative				varchar(500),
	is_active				char(1)	default '1' not null,
	details					clob
);
ALTER TABLE compliance_condition ADD compliance_type VARCHAR(10);
CREATE SEQUENCE compliance_cond_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_compliance_cond_id BEFORE INSERT ON compliance_condition
for each row 
begin   		
	if inserting then 
		if :NEW.compliance_condition_id  is null then
			SELECT compliance_cond_id_seq.nextval into :NEW.compliance_condition_id  from dual;
		end if;
	end if; 
end;
/


--ACTUAL compliance with conditions for each licensee
CREATE TABLE lic_conditions_compliance(

	lic_conditions_compliance_id	integer primary key,
	period_license_id				      integer references period_license,
	compliance_condition_id			  integer references compliance_condition,

	sub_schedule_id				integer references sub_schedule,		--the inspection that obtained these conclusions if any
  
	is_complied						char(1) default '1' not null,
	
	checked_by 						integer references entitys,
	checked_date					date,
  
	--notcomplied			    char(1) default '0' not null,
	details						    clob
);
CREATE INDEX lic_cond_compl_prd_lic_id ON lic_conditions_compliance (period_license_id);
CREATE INDEX lic_cond_compl_compl_cond_id ON lic_conditions_compliance (compliance_condition_id);
CREATE INDEX lic_cond_compl_sub_sch_id ON lic_conditions_compliance (sub_schedule_id);

CREATE SEQUENCE lic_cond_compliance_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_lic_cond_comp_id BEFORE INSERT ON lic_conditions_compliance
for each row 
begin   
  
	if inserting then 
		if :NEW.lic_conditions_compliance_id  is null then
			SELECT lic_cond_compliance_id_seq.nextval into :NEW.lic_conditions_compliance_id  from dual;
		end if;
	end if; 
end;
/


CREATE TABLE qos_factor(
	qos_factor_id		integer primary key,
	license_id			integer references license,

	qos_factor_name		varchar(240),

	target_operator		varchar(5), 		--eg >=,=,<=
	target_value		real,	--eg 90 .. making the full target to be >=90
		
	is_active			char(1) default '1' not null,
	details				clob

	);

ALTER TABLE qos_factor MODIFY target_operator DEFAULT '=';
ALTER TABLE qos_factor ADD target AS (target_operator || ' ' || target_value);

CREATE  SEQUENCE qos_factor_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_qos_factor_id BEFORE INSERT ON qos_factor
for each row 
begin     
	if inserting then 
		if :NEW.qos_factor_id  is null then
			SELECT qos_factor_id_seq.nextval into :NEW.qos_factor_id  from dual;
		end if;
	end if; 
end;
/

--all regions where the client has services / or regions where measurements taken
CREATE TABLE qos_region(
	qos_region_id		integer primary key,
	client_license_id	integer references client_license,		
	qos_region_name		varchar(200),
	details				clob
	);
ALTER TABLE qos_region ADD period_license_id integer references period_license;
ALTER TABLE qos_region ADD sub_schedule_id	integer references sub_schedule;

CREATE  SEQUENCE qos_region_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_qos_region_id BEFORE INSERT ON qos_region
for each row 
begin     
	if inserting then 
		if :NEW.qos_region_id  is null then
			SELECT qos_region_id_seq.nextval into :NEW.qos_region_id  from dual;
		end if;
	end if; 
end;
/





--initialy called licensesqos
CREATE TABLE qos_compliance (
	qos_compliance_id		integer primary key,
	qos_factor_id			integer references qos_factor,	
	period_license_id		integer references period_license,
	sub_schedule_id			integer references sub_schedule,		--the inspection that obtained these conclusions if any
	
	--actual measurements
	actual_client_value		real,
	actual_cck_value		real,	
	
	is_complied				char(1) default '1' not null,	
	recommendation			clob,
	
	details					clob
);
ALTER TABLE qos_compliance ADD qos_region_id integer references qos_region;
CREATE INDEX qos_compl_qos_reg_id ON qos_compliance (qos_region_id); 
CREATE INDEX qos_compl_qos_fact_id ON qos_compliance (qos_factor_id);
CREATE INDEX qos_compl_prd_lic_id ON qos_compliance (period_license_id);
CREATE INDEX qos_compl_sch_id ON qos_compliance (sub_schedule_id);

CREATE  SEQUENCE qos_compliance_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_licensesqos_id BEFORE INSERT ON qos_compliance
for each row 
begin     
	if inserting then 
		if :NEW.qos_compliance_id  is null then
			SELECT qos_compliance_id_seq.nextval into :NEW.qos_compliance_id  from dual;
		end if;
	end if; 
end;
/

--FOR EACH REGION 
CREATE OR REPLACE TRIGGER tr_ins_region_qos_compl AFTER INSERT ON qos_region
   FOR EACH ROW
DECLARE
     CURSOR cursor_licensee IS
        select period_license.period_id, client_license.license_id 
		from period_license 
		inner join client_license on period_license.client_license_id = client_license.client_license_id
		where period_license.period_license_id = :NEW.period_license_id;
        rec_licensee cursor_licensee%ROWTYPE;

BEGIN

	OPEN cursor_licensee;
	FETCH cursor_licensee INTO rec_licensee;

	--we need to take regions into account 
	INSERT INTO qos_compliance(period_license_id, qos_region_id, qos_factor_id) 
		SELECT :NEW.period_license_id, :NEW.qos_region_id, qos_factor_id
		FROM qos_factor
		WHERE qos_factor.license_id = rec_licensee.license_id AND qos_factor.is_active = '1';	
	
	CLOSE cursor_licensee;
	

END;
/


--ANNUALY WE COPY ALL ACTIVE LICENSEES TO THIS PERIOD
CREATE OR REPLACE TRIGGER tr_ins_lic_compliance AFTER INSERT ON period_license
   FOR EACH ROW
DECLARE
	
     CURSOR cursor_licensee IS
        select license_id, workflow_table_id from client_license where client_license.client_license_id = :NEW.client_license_id;
        rec_licensee cursor_licensee%ROWTYPE;
	--wfid		integer;
BEGIN

	OPEN cursor_licensee;
	FETCH cursor_licensee INTO rec_licensee;

	--SELECT workflow_table_id_seq.nextval into wfid from dual;
	--wfid := :NEW.workflow_table_id;	

	--NOTIFY CLIENT ABOUT LICENSE ACTIVATION
	INSERT INTO sys_emailed (sys_email_id, table_id, table_name, email_type) VALUES (71, rec_licensee.workflow_table_id, 'PERIOD_LICENSE', 50);		

	INSERT INTO lic_conditions_compliance (period_license_id, compliance_condition_id)
		SELECT :NEW.period_license_id, compliance_condition_id
		FROM compliance_condition 	
		WHERE compliance_condition.license_id = rec_licensee.license_id AND compliance_condition.is_active = '1';
	
	CLOSE cursor_licensee;

END;
/






--???
CREATE TABLE cck_inventory_type(
	cck_inventory_type_id		integer primary key,
	cck_inventory_type_name		varchar(150),
	department_id				integer references department,
	details						clob
	);


--fmi equipment
 CREATE TABLE cck_inventory (
	cck_inventory_id 			integer primary key,
	cck_inventory_type_id		integer references cck_inventory_type,

	inventory_name	 			varchar(240), 
	inventory_make	 			varchar(240),
	inventory_model	 			varchar(240),  
	inventory_manufacturer		varchar(150),
	serial_number 				varchar(240), 
	model_number		 		varchar(50),
	acquisition_date 			date default sysdate, 
	
	bitu_date					date default sysdate,			--bring in to use date
	last_calibration_date		date,
	
	for_calibration				char(1) default '0' not null,
	calibration_interval		integer,						--interval in months
	
	is_borrowed		 			char(1) default '0' not null,		--ie isnotavailable
	
	inventory_description 		clob,
	inventory_location			varchar(200),
	
	inventory_status			clob,			
	current_status				clob,	

	--userid				integer references users,
	--updatedby				integer references users,

	details 					clob
	);

CREATE SEQUENCE cck_inventory_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_cck_inventory_id BEFORE INSERT ON cck_inventory
for each row 
begin     
	if inserting then 
		if :NEW.cck_inventory_id is null then
			SELECT cck_inventory_id_seq.nextval into :NEW.cck_inventory_id  from dual;
		end if;

		:NEW.current_status := :NEW.inventory_status;		--by default 
		:NEW.last_calibration_date := :NEW.bitu_date;
	end if; 
end;
/



--used to store equipment borrowing history
CREATE TABLE inventory_tracking (
	inventory_tracking_id   integer primary key,
	cck_inventory_id		integer references cck_inventory,

	borrow_date				date default sysdate,
	return_date				date,

	borrower_id				integer references users,
	equipment_status		clob,
	is_borrowed				char(1) default '0',

	created					date default sysdate not null,
	created_by 				integer references entitys,
	updated					date,
	updated_by				integer references entitys,	

	details					clob
	
	);
CREATE SEQUENCE inventory_tracking_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 2;
CREATE OR REPLACE TRIGGER tr_inventory_tracking_id BEFORE INSERT ON inventory_tracking
for each row 
begin     
	if inserting then 
		if :NEW.inventory_tracking_id  is null then
			SELECT inventory_tracking_id_seq.nextval into :NEW.inventory_tracking_id  from dual;
		end if;
	end if; 
end;
/





--NUMBERING NOT YET HERE
CREATE TABLE number_type (
	number_type_id		integer primary key,
	number_type_name	varchar(50),
	details				clob
);
CREATE SEQUENCE number_type_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 5;
CREATE OR REPLACE TRIGGER tr_number_typeid_id BEFORE INSERT ON number_type
for each row 
begin     
	if inserting then 
		if :NEW.number_type_id  is null then
			SELECT number_type_id_seq.nextval into :NEW.number_type_id  from dual;
		end if;
	end if; 
end;
/

CREATE TABLE numbers (
	number_id			integer primary key,
	number_type_id		integer references number_type,
	start_range			varchar(12),
	end_range			varchar(12),
	assignment			varchar(120),
	assign_date			date,
	active_date			date,
	details				clob
);
--CREATE INDEX numbers_number_typeid ON numbers (numbertypeid);
CREATE SEQUENCE numbers_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_number_id BEFORE INSERT ON numbers
for each row 
begin     
	if inserting then 
		if :NEW.number_id  is null then
			SELECT numberS_id_seq.nextval into :NEW.number_id  from dual;
		end if;
	end if; 
end;
/




CREATE TABLE sid (
	sid_id			integer primary key,
	sid_value		varchar(120) not null,
	is_assigned		char(1) default '0',
	assignee		varchar(200),
	details			clob
);
CREATE SEQUENCE sid_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 100;
CREATE OR REPLACE TRIGGER tr_sid_id BEFORE INSERT ON sid
for each row 
begin     
	if inserting then 
		if :NEW.sid_id  is null then
			SELECT sid_id_seq.nextval into :NEW.sid_id  from dual;
		end if;
	end if; 
end;
/

drop table imsi;
CREATE TABLE imsi (
	imsi_id			integer primary key,
	imsi_value		varchar(120),
	imsi_network	varchar(200),
	details			clob
);
CREATE SEQUENCE imsi_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_imsi_id BEFORE INSERT ON imsi
for each row 
begin     
	if inserting then 
		if :NEW.imsi_id  is null then
			SELECT imsi_id_seq.nextval into :NEW.imsi_id  from dual;
		end if;
	end if; 
end;
/

DROP TABLE cell_phone;
CREATE TABLE cell_phone(
	cell_phone_id		integer primary key,
	number_type_id		integer references number_type,
	client_id			integer,
	cell_phone_range	varchar(50),
	date_assigned		date,
	parent_cell_phone_id	integer references cell_phone,
	details					clob	
	);
CREATE SEQUENCE cell_phone_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_cell_phone_id BEFORE INSERT ON cell_phone
for each row 
begin     
	if inserting then 
		if :NEW.cell_phone_id  is null then
			SELECT cell_phone_id_seq.nextval into :NEW.cell_phone_id  from dual;
		end if;
	end if; 
end;
/

CREATE TABLE color_code(
    color_code_id		integer primary key,
    color_code_value	varchar(10),
    is_assigned			char(1) default '0',
	assignee			varchar(200),
	details				clob    
	);


CREATE TABLE fixed_line (
	fixed_line_id		integer primary key,
	fixed_line_location		varchar(200),
	specific_location		varchar(200),
	code_1					varchar(10),
	code_2					varchar(10),
	number_assigned		varchar(50),		--2
	subscriber			varchar(50),		--2
	is_assigned			char(1) default '0',
	details				clob
);
alter table fixed_line add assignee;


CREATE TABLE issuer_identification(
    issuer_identification_id	integer primary key,
    number_type_id				integer references number_type,
    id_number					varchar(10),
	code_1						varchar(10),
	code_2						varchar(10),
	date_assigned				date,
	details						clob    
	);

CREATE TABLE m_operator (
	m_operator_id		integer primary key,
	m_operator_name		varchar(120) not null,
	details				clob
);

CREATE TABLE area (
	area_id			integer primary key,
	area_name		varchar(120) not null,
	details			clob
);

CREATE TABLE destination_code(
	destination_code_id		integer primary key,
	area_id					integer references area,
	destination_code		varchar(120) not null,
	details					clob
	);

CREATE TABLE number_series(
	number_series_id		  integer primary key,
	destination_code_id		integer references destination_code,
	m_operator_id			  integer references m_operator,
	current_number_series		varchar(120) not null,
	significant_number		varchar(120) not null,
	details				clob
);





--CERTIFICATION
CREATE TABLE installation (
	installation_id		integer primary key,
	client_license_id	integer references client_license,		--id of the TP(Technical Personnel) or TEC (Tel Equip Contractor)
	site					varchar(120),
	--period_id				varchar(32) references periods,

	equipment_id			integer references equipment,		--type approved equip includes make + model
	equipment_make			varchar(100),
	equipment_model			varchar(50),
	capacity				varchar(50),

	checklist_url			clob,

	project_contractor		varchar(200),	
	installation_type		varchar(50),
	install_date				date,
	
	client_name				varchar(120),
	postal_address			varchar(150),
	physical_address			varchar(150),

	is_approved				char(1) default '0' not null ,
	is_rejected				char(1) default '0' not null ,
	
	findings				clob,

	details					clob
	
);

ALTER TABLE installation ADD sub_schedule_id integer references sub_schedule;
CREATE INDEX installation_client_license_id ON installation (client_license_id);
CREATE INDEX installation_sub_schedule_id ON installation (sub_schedule_id);

CREATE SEQUENCE installation_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_installation_id BEFORE INSERT ON installation
for each row 
begin     
	if inserting then 
		if :NEW.installation_id  is null then
			SELECT installation_id_seq.nextval into :NEW.installation_id  from dual;
		end if;
	end if; 
end;
/




CREATE GLOBAL TEMPORARY TABLE global_temp_table (
  global_temp_table_id  	integer,
  table_name  				varchar(50),		--name of the table of interest
  keyfield					varchar(50),		--name of the pk column
  keyvalue					integer,			--value of the pk
  column_name		varchar(50),				--name of the payload column
  column_old_value	varchar(50),				--old value
  column_new_value 	varchar(50)  				--new value  
  );-- ON COMMIT DELETE ROWS;
CREATE SEQUENCE global_temp_table_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_global_temp_table_id BEFORE INSERT ON global_temp_table
for each row 
begin     
	if inserting then 
		if :NEW.global_temp_table_id  is null then
			SELECT global_temp_table_id_seq.nextval into :NEW.global_temp_table_id  from dual;
		end if;
	end if; 
end;
/

CREATE OR REPLACE TRIGGER tr_revive_approval AFTER INSERT ON global_temp_table
   FOR EACH ROW 
DECLARE

BEGIN
	--UPDATE APPROVALS SET APPROVE_STATUS = 'D' WHERE APPROVAL_ID = X?
	EXECUTE IMMEDIATE 'UPDATE ' || :NEW.table_name || ' SET ' || :NEW.column_name || ' = ''|| :NEW.column_new_value || '' WHERE ' || :NEW.keyfield || ' = ' || :NEW.keyvalue;
	COMMIT;		
				
END;
/


UPDATE APPROVALS | TABLE_NAME SET APPROVE_STATUS|COLUMN_NAME = COLUMN_NEW_VALUE WHERE APPROVAL_ID = pk_value;

insert into my_temp_table(1,'1','one');
insert into my_temp_table(2,'2','two');
insert into my_temp_table(3,'3','three');






--UPDATES
ALTER TABLE SUB_SCHEDULE ADD quarter_id integer;
ALTER TABLE SCHEDULE ADD WORKFLOW_TABLE_ID NUMBER(*,0);
ALTER TABLE SCHEDULE ADD IS_WORKFLOW_COMPLETE CHAR(1 BYTE) DEFAULT '0' NOT NULL;