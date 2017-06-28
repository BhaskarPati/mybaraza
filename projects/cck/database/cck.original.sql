SET SCAN OFF;
--run view payment status
--run tr_clientphases
CREATE TABLE currencyunits (
	currencyunitid 		integer primary key,
	currencyunitname 	varchar(100), 	
	currencyabbrev		varchar(100)
	);
INSERT INTO currencyunits (currencyunitid,currencyunitname,currencyabbrev) VALUES (1,'Kenya Shilling', 'KShs');
INSERT INTO currencyunits (currencyunitid,currencyunitname,currencyabbrev) VALUES (2,'United States Dollar', 'USD');


CREATE TABLE postoffice (
	postofficeid 		integer primary key,
	postofficename 		varchar(100), 
	head_post_office	varchar(100),
	postalcode 			varchar(10),
	code				varchar(10),
	code_desc			varchar(200),  
	region				varchar(150),
	district			varchar(150)
	);
CREATE SEQUENCE postoffice_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_postoffice_id BEFORE INSERT ON postoffice
for each row 
begin     
	if inserting then 
		if :NEW.postofficeid  is null then
			SELECT postoffice_id_seq.nextval into :NEW.postofficeid  from dual;
		end if;
	end if; 
end;
/


CREATE OR REPLACE VIEW vwammendmentrequest AS
	SELECT ammendmentrequest.ammendmentrequestid,	ammendmentrequest.clientlicenseid, ammendmentrequest.request,	ammendmentrequest.emailsubject,	ammendmentrequest.emailbody,	ammendmentrequest.cc,	ammendmentrequest.documentlink, ammendmentrequest.cckreference,
	ammendmentrequest.todosubreport,	ammendmentrequest.todobranch,	ammendmentrequest.foremail,	ammendmentrequest.isemailed,	ammendmentrequest.isapproved,	ammendmentrequest.iscomplete,	ammendmentrequest.actiondate,	ammendmentrequest.approveddate,	ammendmentrequest.userid,	ammendmentrequest.approvedby, 
	clients.clientid, clients.clientname, licenses.licenseid, licenses.licensename
	FROM ammendmentrequest
	INNER JOIN clientlicenses ON ammendmentrequest.clientlicenseid = clientlicenses.clientlicenseid
	INNER JOIN clients ON clientlicenses.clientid = clients.clientid
  INNER JOIN licenses ON clientlicenses.licenseid = licenses.licenseid;



CREATE VIEW vwammendmentrequestTest AS
	SELECT ammendmentrequestid,	clientlicenseid, request, emailsubject,	emailbody, cc, documentlink, cckreference,
	todosubreport, todobranch, foremail, isemailed,	isapproved,	iscomplete,	actiondate,	approveddate, userid, approvedby,	
	(<a href=\"" + requestpath + "?view=" +  Cipher(OracleJava.getTargetKey(todobranch, clientlicenseid))) + "&filtervalue=" + cipherdata + "\"");	
	FROM ammendmentrequest;



create or replace FUNCTION apprammendmentrequest(req_id IN varchar2, user_id IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	BEGIN
	
	IF approval='Select' THEN	
		UPDATE ammendmentrequest set isapproved = '1' where ammendmentrequestid = cast(req_id as int);
		COMMIT;
		RETURN 'Ammendment Request Approved';
	END IF;

END;
/


CREATE TABLE ammendmentrequest (
	ammendmentrequestid 		integer primary key,
	clientlicenseid				integer,-- references clientlicenses
	
	request						clob,			--details of the request

	emailsubject				varchar(100),	--subject of the email
	emailbody					clob,			--gets data from request send to AD
	cc							varchar(200),	--addresses of people to get copies
	
	documentlink				varchar(100),	--url for related letter/correspondence in the dms if any
	cckreference				varchar(50),			
	
	todosubreport				varchar(10),	--subreport key if there is something to be done
	todobranch					varchar(10),

--	getcopy					char(1) default '0',	
	foremail				char(1) default '0',	--if checked we need to send email
	isemailed				char(1) default '0',	--confirm if email was sent. especially if email is send by baraza server to prevent multiple.....
	isapproved				char(1) default '0',	--is request approved

	iscomplete				char(1) default '0',	--wether or not the ammendment has been done (after being approved)

	actiondate				date default sysdate,
	approveddate			date,

	userid					integer references users,
	approvedby				integer references users
	);
CREATE SEQUENCE ammendmentrequest_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_ammendmentrequest_id BEFORE INSERT ON ammendmentrequest
for each row 
begin     
	if inserting then 
		if :NEW.ammendmentrequestid  is null then
			SELECT ammendmentrequest_id_seq.nextval into :NEW.ammendmentrequestid  from dual;
		end if;
	end if; 
end;
/



CREATE TABLE emailtemplate (
	emailtemplateid 		integer primary key,
	emailtemplatename 		varchar(100), 
	emailsubject			varchar(100),
	isenabled				char(1) default '0', 
	forlcs					char(1) default '0', 
	forfsm					char(1) default '0', 
	emailbody				clob,
	remarks					clob		--for internal use. describe what this notification is used for
	);
CREATE SEQUENCE emailtemplate_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_emailtemplate_id BEFORE INSERT ON emailtemplate
for each row 
begin     
	if inserting then 
		if :NEW.emailtemplateid  is null then
			SELECT emailtemplate_id_seq.nextval into :NEW.emailtemplateid  from dual;
		end if;
	end if; 
end;
/


CREATE TABLE licensetypes (
	licensetypeid		integer primary key,
	licensetypename		varchar(120) not null,
	forfsm				char(1)  default '0' not null,
	forlcs				char(1) default '0' not null,
	forta				char(1) default '0' not null,
	nlf				char(1) default '0' not null,
	abbrev  		varchar(50),
	details				clob
	);
CREATE SEQUENCE licensetypes_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 20;
CREATE OR REPLACE TRIGGER tr_licensetypes_id BEFORE INSERT ON licensetypes
for each row 
begin     
	if inserting then 
		if :NEW.licensetypeid is null then
			SELECT licensetypes_id_seq.nextval into :NEW.licensetypeid from dual;
		end if;
	end if; 
end;
/

CREATE TABLE licenses (
	licenseid			integer primary key,
	licensetypeid		integer references licensetypes,
	currencyunitid 		integer default 1 references currencyunits,
	licensename			varchar(120) not null unique,
	licenseperiod		integer default 1 not null,
	applicationfee		real default 0 not null,
	initialfee			real default 0 not null,
	annualfee			real default 0 not null,
	agtfee				real default 0 not null,
	typeapprovalfee		real default 0 not null,
	annualfeedetail 	varchar (240),
	licenseabbrev		varchar (120),
	num  				varchar (20),				
	applicationaccount	varchar(32),
	initialaccount		varchar(32),
	annualaccount		varchar(32),
	taaccount			varchar(32),
	fixedfee			char(1) default '0' not null,
	rolloutperiod		integer default 0 not null,
	Quarterly			char(1) default '0' not null,
	Annually			char(1) default '0' not null,
	isactive			char(1) default '1' not null,
	licensereport		varchar(120),

	isterrestrial 		char(1) default '0',		--terrestrial need 1k on top of initial payments
	isvhf				char(1) default '0',
	ismaritime			char(1) default '0',

	graceperiodyears	integer,

	issquential			char(1) default '0',		--whether or not the license number changes
	nextsequenceval		integer,

	spectrumaccess		clob,
	licenseterms		clob,
	details				clob
	);
CREATE SEQUENCE licenses_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 700;
CREATE OR REPLACE TRIGGER tr_license_id BEFORE INSERT ON licenses
for each row 
begin     
	if inserting then 
		if :NEW.licenseid is null then
			SELECT licenses_id_seq.nextval into :NEW.licenseid from dual;
		end if;
	end if; 
end;
/

CREATE TABLE licensedefination (
	licensedefinationid	integer primary key,
	licenseid		integer references licenses,
	licensedefname				varchar(120),
	Details				clob  
	);
CREATE INDEX licensedefination_licenseid ON licensedefination (licenseid);
CREATE SEQUENCE licensedefination_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 10;
CREATE OR REPLACE TRIGGER tr_licensedefination_id BEFORE INSERT ON licensedefination
for each row 
begin     
	if inserting then 
		if :NEW.licensedefinationid is null then
			SELECT licensedefination_id_seq.nextval into :NEW.licensedefinationid from dual;
		end if;
	end if; 
end;
/

CREATE TABLE stationclass(
	stationclassid		char(2) primary key,
	stationclassname	varchar(120),
	details				clob
	);

CREATE TABLE servicenature (
	servicenatureid		char(2) primary key,
	servicenaturename	varchar(120),
	details				clob
	);

CREATE OR REPLACE VIEW vwservicenature AS
	SELECT servicenatureid, servicenaturename, (servicenatureid || ' : ' || servicenaturename) as summary
	FROM servicenature;

--these r actually stationprices
CREATE TABLE licenseprices (
	licensepriceid		integer primary key,
	licenseid			integer references licenses,
	stationclassid		char(2) references stationclass,
	typename			varchar(50),
	amount				real,
	chargeperiod		varchar(50) default 'Annual',
	unitgroups			integer default 1 not null,
	onetimefee			char(1) default '0' not null,
	perlicense			char(1) default '0' not null,
	perstation			char(1) default '0' not null,
	perfrequency		char(1) default '0' not null,
	functname			varchar(50),
	formula				clob,

	hasfixedcharge		char(1) default '0' not null,

	details				clob
	);

CREATE SEQUENCE licenseprices_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_licenseprice_id BEFORE INSERT ON licenseprices
for each row 
begin     
	if inserting then 
		if :NEW.licensepriceid  is null then
			SELECT licenseprices_id_seq.nextval into :NEW.licensepriceid  from dual;
		end if;
	end if; 
end;
/

--this defines individual forms and not a category/type as may be implied by the table name
CREATE TABLE formtypes (
	formtypeid			integer primary key,
	formtypename		varchar(240) not null unique,
	formnumber			varchar(50),
	version				date,
	completed			char(1) default '0' not null,
	isactive			char(1) default '0' not null,
	forfsm				char(1) default '0' not null,
	forlcs				char(1) default '0' not null,
	forta				char(1) default '0' not null,
	application			char(1) default '0' not null,
	compliance			char(1) default '0' not null,
	header				clob,
	footer				clob,
	details				clob
	);
CREATE SEQUENCE formtypes_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 500;
CREATE OR REPLACE TRIGGER tr_formtype_id BEFORE INSERT ON formtypes
for each row 
begin     
	if inserting then 
		if :NEW.formtypeid is null then
			SELECT formtypes_id_seq.nextval into :NEW.formtypeid from dual;
		end if;
	end if; 
end;
/

--this is actually form content
CREATE TABLE forms (
	formid				integer primary key,
	formtypeid			integer references formtypes,
	qorder				integer default 1,
	shareline			integer,
	fortitle			char(1),
	subformgrid			char(1),
	manditory			char(1) default '1' not null,
	fieldname			varchar(50),
	fieldtype			varchar(25),
	lookupfield			clob,
	question			clob,
	fieldsize			integer default 25 not null,
	fieldclass			varchar(50),
	fieldbold			char(1) default '0' not null,
	fielditalics		char(1) default '0' not null
	);
CREATE INDEX forms_formtypeid ON forms (formtypeid);
CREATE SEQUENCE forms_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 40000;
CREATE OR REPLACE TRIGGER tr_forms_id BEFORE INSERT ON forms
for each row 
begin     
	if inserting then 
		if :NEW.formid is null then
			SELECT forms_id_seq.nextval into :NEW.formid from dual;
		end if;
	end if; 
end;
/

CREATE TABLE subforms (
	subformid			integer primary key,
	formid				integer references forms,
	qorder				integer,
	titleshare			varchar(120),
	fieldtype			varchar(25),
	lookupfield			clob,
	fieldsize			integer default 10 not null,
	manditory			char(1) default '1' not null,
	question			clob
);	
CREATE INDEX subforms_formid ON subforms (formid);
CREATE SEQUENCE subforms_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 700;
CREATE OR REPLACE TRIGGER tr_subform_id BEFORE INSERT ON subforms
for each row 
begin     
	if inserting then 
		if :NEW.subformid is null then
			SELECT subforms_id_seq.nextval into :NEW.subformid from dual;
		end if;
	end if; 
end;
/

CREATE TABLE paymenttypes (
	paymenttypeid		integer primary key,
	paymenttypename		varchar(25),
	details clob
);
CREATE SEQUENCE paymenttypes_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_paymenttypes_id BEFORE INSERT ON paymenttypes
for each row 
begin     
	if inserting then 
		if :NEW.paymenttypeid  is null then
			SELECT paymenttypes_id_seq.nextval into :NEW.paymenttypeid  from dual;
		end if;
	end if; 
end;
/



	

--these are the actual schedules 	
CREATE TABLE scheduletypes (
	scheduletypeid 		integer primary key,
	scheduletypename	varchar(120),
	period				integer references periods,
	correspondenceid	integer references correspondence,
	forfsm				char(1) default '0' not null,
	forlcs				char(1) default '0' not null,

	annual			char(1) default '0' not null,
	adhoc			char(1) default '0' not null,
	
	approved		char(1) default '0' not null,
	complete		char(1) default '0' not null,
	active			char(1) default '0' not null,

	entrydae		date default sysdate not null,
	details			clob
);
CREATE SEQUENCE scheduletypes_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 3;
CREATE OR REPLACE TRIGGER tr_scheduletypes_id BEFORE INSERT ON scheduletypes
for each row 
begin     
	if inserting then 
		if :NEW.scheduletypeid is null then
			SELECT scheduletypes_id_seq.nextval into :NEW.scheduletypeid from dual;
		end if;
	end if; 
end;
/




--quarter heading.. specific schedules within a wider/annual/ schedule defined above
CREATE TABLE SCHEDULES
   (	
	SCHEDULEID 		integer primary key, 
	USERID			integer references users,
	SCHEDULETYPEID	integer references scheduletypes, 
	SCHEDULENAME	VARCHAR2(120), 
	STARTDATE		DATE, 
	ENDDATE			DATE, 
	quarterid			integer references quarter,			--contentious .. it seems a schedule can span more than one quarter
	"COMPLETE" CHAR(1 BYTE) DEFAULT '0' NOT NULL ENABLE, 
	"QUARTER1" CHAR(1 BYTE) DEFAULT '0' NOT NULL ENABLE, 
	"QUARTER2" CHAR(1 BYTE) DEFAULT '0' NOT NULL ENABLE, 
	"QUARTER3" CHAR(1 BYTE) DEFAULT '0' NOT NULL ENABLE, 
	"QUARTER4" CHAR(1 BYTE) DEFAULT '0' NOT NULL ENABLE, 
	"DETAILS" CLOB, 

	isapprovedbymanager		char(1) default '0' not null,
	isapprovedbyad			char(1) default '0' not null,
	isapprovedbyDirector	char(1) default '0' not null,
	isapprovedbyDG			char(1) default '0' not null,


	"PROCESSED" CHAR(1 BYTE) DEFAULT '0' NOT NULL ENABLE
	);

CREATE SEQUENCE schedules_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 400;
 CREATE OR REPLACE TRIGGER TR_SCHEDULE_ID BEFORE INSERT ON schedules
for each row 
begin     
	if inserting then 
		if :NEW.scheduleID  is null then
			SELECT schedules_id_seq.nextval into :NEW.scheduleID  from dual;
		end if;
	end if; 
end;
/

create or replace TRIGGER TR_ANNUALSCHEDULE AFTER INSERT ON schedules
   FOR EACH ROW 
DECLARE
BEGIN
	INSERT INTO clientphases ( phaseid, EscalationTime, userid,clientphasename,clientapplevel,SCHEDULEID)	
	SELECT  phaseid, EscalationTime, 0,phasename,phaselevel,:NEW.SCHEDULEID
	FROM phases
	WHERE (phases.ANNUALSCHEDULE = '1');
END;



/
ALTER TRIGGER "CCK"."TR_ANNUALSCHEDULE" ENABLE;
 






CREATE TABLE notification (
	notificationid		integer primary key,
	notificationname	varchar2(150),
	details				clob
);
CREATE SEQUENCE notification_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_notification_id BEFORE INSERT ON notification
for each row 
begin     
	if inserting then 
		if :NEW.notificationid is null then
			SELECT notification_id_seq.nextval into :NEW.notificationid from dual;
		end if;
	end if; 
end;
/


CREATE TABLE phases (
	phaseid				integer primary key,
	scheduletypeid		integer references scheduletypes,
	formtypeid			integer references formtypes,
	licenseid			integer references licenses,
	usergroupid			integer references usergroups,
	paymenttypeid		integer references paymenttypes,
	notificationid		integer references notification,
	phasename			varchar(120),
	compliance			char(1) default '0' not null,
	approval			char(1) default '1' not null,
	annualschedule		char(1) default '0' not null,
	phaselevel			integer not null,
	returnlevel			integer not null,
	EscalationTime		integer default 2 not null,
	forpayment			char(1) default '0' not null,
	fornotification		char(1) default '0' not null,
	--b4 training
	isactive			char(1) default '1' not null,

	details				clob
);
CREATE INDEX phases_usergroupid ON phases (usergroupid);
CREATE INDEX phases_formtypeid ON phases (formtypeid);
CREATE INDEX phases_licenseid ON phases (licenseid);
CREATE SEQUENCE phases_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 300;
CREATE OR REPLACE TRIGGER tr_phases_id BEFORE INSERT ON phases
for each row 
begin     
	if inserting then 
		if :NEW.phaseid is null then
			SELECT phases_id_seq.nextval into :NEW.phaseid from dual;
		end if;
	end if; 
end;
/

CREATE TABLE checklists (
	checklistid		integer primary key,
	phaseid			integer references phases,
	phasenumber		integer,
	requirement		varchar(320),

	--b4 training
	individual		char(1) default '1' not null,		--ie applies to individuals
	
	company			char(1) default '1' not null,		--applies to companies
	diplomatic		char(1) default '1' not null,
	ngo				char(1) default '1' not null,
	govt			char(1) default '1' not null,
	partnership		char(1) default '1' not null,
	forsecurity		char(1) default '0' not null,		--for security companies

	citizen			char(1) default '1' not null,		--applies to citizens - ISSUE:how do we know if directors are citizens ?

	isactive		char(1) default '1' not null,		--for temporarily disabling/deleting checklists

	details			clob
);

CREATE INDEX checklists_phaseid ON checklists (phaseid);
CREATE SEQUENCE checklists_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 300;
CREATE OR REPLACE TRIGGER tr_checklists_id BEFORE INSERT ON checklists
for each row 
begin     
	if inserting then 
		if :NEW.checklistid is null then
			SELECT checklists_id_seq.nextval into :NEW.checklistid from dual;
		end if;
	end if; 
end;
/

CREATE TABLE licenseforms (
	licenceformid		integer primary key,
	formtypeid			integer references formtypes,
	licenseid			integer references licenses,
	formorder			integer default 0 not null,
	details				clob
);
CREATE INDEX licenseforms_formtypeid ON licenseforms (formtypeid);
CREATE INDEX licenseforms_licenseid ON licenseforms (licenseid);
CREATE SEQUENCE licenceforms_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 40;
CREATE OR REPLACE TRIGGER tr_licenceformid_id BEFORE INSERT ON licenseforms
for each row 
begin     
	if inserting then 
		if :NEW.licenceformid is null then
			SELECT licenceforms_id_seq.nextval into :NEW.licenceformid from dual;
		end if;
	end if; 
end;
/


--organization type
CREATE TABLE clientcategorys (
	clientcategoryid	integer primary key,
	clientcategoryname	varchar(50),
	details 			clob
);
CREATE SEQUENCE clientcategorys_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 40;
CREATE OR REPLACE TRIGGER tr_clientcategorys_id BEFORE INSERT ON clientcategorys
for each row 
begin     
	if inserting then 
		if :NEW.clientcategoryid is null then
			SELECT clientcategorys_id_seq.nextval into :NEW.clientcategoryid from dual;
		end if;
	end if; 
end;
/

--industry
CREATE TABLE clienttypes (
	clienttypeid		integer primary key,
	clienttypename		varchar(50),
	details				clob
);

CREATE SEQUENCE clienttypes_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 40;
CREATE OR REPLACE TRIGGER tr_clienttype_id BEFORE INSERT ON clienttypes
for each row 
begin     
	if inserting then 
		if :NEW.clienttypeid is null then
			SELECT clienttypes_id_seq.nextval into :NEW.clienttypeid from dual;
		end if;
	end if; 
end;
/

CREATE TABLE idtypes (
  idtypeid		integer primary key,
  individual 	char(1) default '1',
  company	 	  char(1) default '0',
  ngo			  char(1) default '0',
  typename	varchar(120)
  );
CREATE SEQUENCE idtypes_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 40;
CREATE OR REPLACE TRIGGER tr_idtypes_id BEFORE INSERT ON idtypes
for each row 
begin     
	if inserting then 
		if :NEW.idtypeid is null then
			SELECT idtypes_id_seq.nextval into :NEW.idtypeid from dual;
		end if;
	end if; 
end;
/

CREATE TABLE addresstypes (
	addresstypeid		integer primary key,
	addresstypename		varchar(120)
	);
CREATE SEQUENCE addresstypes_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 40;
CREATE OR REPLACE TRIGGER tr_addresstypes_id BEFORE INSERT ON addresstypes
for each row 
begin     
	if inserting then 
		if :NEW.addresstypeid is null then
			SELECT addresstypes_id_seq.nextval into :NEW.addresstypeid from dual;
		end if;
	end if; 
end;
/
INSERT INTO addresstypes (addresstypename) VALUES ('Billing Address');
INSERT INTO addresstypes (addresstypename) VALUES ('Second Mail Address');
INSERT INTO addresstypes (addresstypename) VALUES ('Site Address');

CREATE TABLE clients (
	clientid			integer primary key,
	--irisclientid		integer,
	clientcategoryid	integer references clientcategorys,
	clienttypeid		integer references clienttypes,
	licenseid 			integer references licenses,
	idtypeid 			integer references idtypes,
	addresstypeid		integer references addresstypes,	
	postofficeid		integer references postoffice,
	countryid			char(2) references countrys,
	createdby			integer references users,
	updatedby			integer references users,
	userid				integer references users,
	postalcode 			varchar(10),
	companyreg			varchar(120),
	clientname			varchar(120),
	accountscode		varchar(120),

	Address				varchar(50),
	Premises			varchar(120),
	Street				varchar(120),
	Town				varchar(50) not null,
	Fax					varchar(150),
	Email				varchar(120),
	filenumber			varchar(120),
	countrycode			varchar(12),
	TelNo				varchar(150),
	mobilenum			varchar(150),
	buildingfloor		varchar(120),
	lrnumber			varchar(120),
	website				varchar(240),
	division			varchar(240),

	--mail
	
	--financialyearend	date,			--we ignore the year part
	--financialyearendmonth		char(15) default to_char(financialyearend,'Month'),		--
	--AAAdeadlinedate				date default financialyearend + 90, --90 days after financial year

	created 			date default SYSDATE,
	updated 			date default SYSDATE,
	createdby			integer references users,
	updatedby			integer references users,
	userid				integer references users,

	idnumber			varchar(50),
	pin			 		varchar(50),
	clientlogin			varchar(32),
	userpasswd			varchar(32) default 'hello' not null,
	firstpasswd			varchar(32) default 'hello' not null,
	DateEnroled			date default SYSDATE,
	DocumentLink		varchar(240),
	IsActive			char(1) default '1' not null,
	compliant			char(1) default '1' not null,
	ispicked			char(1) default '0' not null,
	ischanged			char(1) default '0' not null,
	isoldlcs			char(1) default '0' not null,
	isoldfsm			char(1) default '0' not null,
	foreignholding		float,
	istest				char(1) default '0',


	licensenumber		varchar(20),


	Details				clob
);
CREATE INDEX clients_clientcategoryid ON clients (clientcategoryid);
CREATE INDEX clients_clienttypeid ON clients (clienttypeid);
CREATE INDEX clients_idtypeid ON clients (idtypeid);
CREATE INDEX clients_createdby ON clients (createdby);
CREATE INDEX clients_updatedby ON clients (updatedby);
CREATE SEQUENCE clients_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 20000;
--b4 training
CREATE OR REPLACE TRIGGER tr_clients_id BEFORE INSERT ON clients
for each row 
begin     
	if inserting then 

		if :NEW.clientid is null then
			SELECT clients_id_seq.nextval into :NEW.clientid from dual;			
		end if;

		if :NEW.createdby is null then
			:NEW.CREATEDBY:=:NEW.USERID;
		end if;

		if (:NEW.postalcode is not null) then
			:NEW.postofficeid := null;			--ignore the postoffice id given in the combo
		end if;				

	end if; 
end;
/

--UPDATE TRACKING
CREATE OR REPLACE TRIGGER tr_updclients BEFORE UPDATE ON clients
for each row 
begin     
	if updating then 

		--make sure the added postalcode is not already existing

		:NEW.UPDATED := SYSDATE;
		:NEW.UPDATEDBY := :NEW.USERID;

	end if; 
end;
/

CREATE OR REPLACE TRIGGER tr_insformlicenses AFTER INSERT ON clients 
   FOR EACH ROW 
DECLARE

BEGIN

	--client details (Workaround since clients table is mutating)
	INSERT INTO clientdetail(clientid,clienttypeid,clientcategoryid)
		SELECT :NEW.CLIENTID,:NEW.CLIENTTYPEID,:NEW.CLIENTCATEGORYID FROM DUAL;

	--billing address
	INSERT INTO addresses (clientid,addresstypeid,address,postofficeid,town,premises,street,email,telno,mobilenum,fax,countryid)
		VALUES( :NEW.CLIENTID,40,:NEW.address,:NEW.postofficeid,:NEW.town,:NEW.premises,:NEW.street,:NEW.email,:NEW.telno,:NEW.mobilenum,:NEW.fax,:NEW.countryid);				

	--normal stuff
	INSERT INTO clientlicenses(LICENSEID, clientid, userid)
		SELECT :NEW.LICENSEID, :NEW.CLIENTID, :NEW.USERID FROM DUAL;
		
		
END;
/









--TABLE
CREATE TABLE clientdetail (
	clientdetailid		integer primary key,
	clientid			integer,
	clientcategoryid	integer,
	clienttypeid		integer
	);
CREATE SEQUENCE clientdetail_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_clientdetail_id BEFORE INSERT ON clientdetail
for each row 
begin     
	if inserting then 
		if :NEW.clientdetailid is null then
			SELECT clientdetail_id_seq.nextval into :NEW.clientdetailid from dual;
		end if;
	end if; 
end;
/






CREATE TABLE addresses (
	addressid 		integer primary key,
	clientid		integer references clients,
	addresstypeid 	integer references addresstypes,
	Address			varchar(50),
	postofficeid	integer references postoffice,
	postalcode 		varchar(10),
	Premises		varchar(120),
	Street			varchar(120),
	Town			varchar(50) not null,
	countryid		char(2) references countrys,
	Fax				varchar(150),
	Email			varchar(120),
	countrycode		varchar(12),
	TelNo			varchar(150),
	mobilenum		varchar(150),
	buildingfloor	varchar(120),
	bankaccountnumber	varchar(500),
	details			clob
);
CREATE INDEX addresses_clientid ON addresses (clientid);
CREATE SEQUENCE addresses_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1800;
CREATE OR REPLACE TRIGGER tr_clientaddress_id BEFORE INSERT ON addresses
for each row 
begin     
	if inserting then 
		if :NEW.addressid is null then
			SELECT addresses_id_seq.nextval into :NEW.addressid from dual;
		end if;
	end if; 
end;
/

CREATE OR REPLACE VIEW vwclientcontacts AS
	SELECT clients.clientid, clients.clientname, clientcontact.clientcontactid, clientcontact.contactname, clientcontact.designation,
		idtypes.typename, clientcontact.idnumber, countrys.citizenname, clientcontact.details as contactdetails, clients.details as clientdetails
	FROM clientcontact	
	INNER JOIN clients ON clientcontact.clientid = clients.clientid
	INNER JOIN idtypes ON clientcontact.idtypeid = idtypes.idtypeid
	INNER JOIN countrys ON clientcontact.countryid = countrys.countryid;


--get client contacts
--eg DIRECTOR: ibrahim itambo, Kenyan
--	Passport Number: A130092
--
	 
CREATE OR REPLACE FUNCTION getClientContacts(cli_id in integer) RETURN varchar IS
PRAGMA AUTONOMOUS_TRANSACTION;
	
	summary varchar(10000);
	
BEGIN
	
	for myrec in (select (rownum || '. <b><u>' || designation ||'</u></b> :<br>' || contactname || ', ' || citizenname || '<br><b>' || typename || ':</b>' || idnumber) as contactdetails from vwclientcontacts where clientid = cli_id) loop
		summary := summary || myrec.contactdetails || '<br>'; 
	end loop;				

	RETURN summary;
END;
/






--we need to know the person to address all correspondence regarding a particular application
--b4 training
CREATE TABLE contactperson(
  contactpersonid	integer primary key,
  countryid			char(2) default 'KE' references countrys,
  clientid			integer references clients,		--constraint removed
  idtypeid 			integer references idtypes,
  idnumber			varchar(50),
  contactname		varchar(240),
  title				varchar(240),	--this is actually the designation
  salutation		varchar(10), 	--either Sir, Madam
  department		varchar(240),
  letterdate		date,				--date on the application letter
  lettertitle 		varchar(100),		--title of the application letter
  letterref			varchar(50),
  Details			clob
);

CREATE SEQUENCE contactperson_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_contactperson_id BEFORE INSERT ON contactperson
for each row 
begin     
	if inserting then 
		if :NEW.contactpersonid is null then
			SELECT contactperson_id_seq.nextval into :NEW.contactpersonid from dual;
		end if;
	end if; 
end;
/








--directors
CREATE TABLE clientcontact(
  clientcontactid	integer primary key,
  countryid			char(2) default 'KE' references countrys,
  clientid			integer references clients,		--constraint removed
  idtypeid 			integer references idtypes,
  contactname		varchar(240),
  designation		varchar(240),
  idnumber			varchar(50),
  Details			clob
);

CREATE INDEX clientcontact_clientid ON clientcontact (clientid);
CREATE SEQUENCE clientcontact_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1800;
CREATE OR REPLACE TRIGGER tr_clientcontact_id BEFORE INSERT ON clientcontact
for each row 
begin     
	if inserting then 
		if :NEW.clientcontactid is null then
			SELECT clientcontact_id_seq.nextval into :NEW.clientcontactid from dual;
		end if;
	end if; 
end;
/


CREATE TABLE clc (
	clcid integer primary key,
	clcdate	date,
	clcnumber varchar(20),
	active		char(1) default '1' not null,
	doc_url		varchar(500),				--user may want to hardcode url directly to the specific document (word/pdf) in the DMS
	dmsspace_url		varchar(500),
	minutenumber varchar(20),
	minute_doc blob,
	details clob
);
CREATE SEQUENCE clc_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_clc_id BEFORE INSERT ON clc
for each row 
begin     
	if inserting then   
		--deactivate all the others		
		update clc set active='0';
		
		if :NEW.clcid is null then
			SELECT clc_id_seq.nextval into :NEW.clcid from dual;
		end if;				
	end if; 
end;
/

CREATE OR REPLACE TRIGGER add_applicants AFTER INSERT ON clc
--for each row 
DECLARE 
	latest_clc_id int;
begin     
	
	SELECT max(clcid) INTO latest_clc_id FROM clc;  

	UPDATE clientlicenses SET clcid = latest_clc_id
		WHERE clientlicenseid IN
			(SELECT clientlicenseid 
			FROM vwclcclients		
			WHERE (clientphasename = 'clc') AND (approved = '0') AND (rejected = '0') AND (ClientPhaseLNA = 0) AND (clcid = 0));	--clcid is coalesced to 0 in the view vwclcclients
		
end;
/

CREATE OR REPLACE TRIGGER upd_Doc_Url BEFORE UPDATE ON clc
for each row 
DECLARE
 	new_url		varchar(500);
begin     
 if updating then
	--IF(:NEW.doc_url != :OLD.doc_url) THEN		--if changed
	--remove any previous a href elements
	SELECT REPLACE(:NEW.doc_url,'<a href=','') INTO new_url FROM dual;		--remove the leading '<a href=' substring
	SELECT REPLACE(new_url,'>Minutes Document</a>','') INTO new_url FROM dual;	
	:NEW.doc_url := '<a href=' || new_url || '>Minutes Document</a>';
	--END IF;
end if;

end;
/




CREATE TABLE tac (
	tacid integer primary key,
	tacdate	date,
	tacnumber varchar(20),
	minutenumber varchar(20),
	isactive		char(1) default '1' not null,

	report_url			varchar(500),				--user may want to hardcode url directly to the specific document (word/pdf) in the DMS
	dmsspace_url		varchar(500),
	inline_report		clob,						

	actiondate		date default sysdate not null,
	memberspresent		clob,

	details clob
);
CREATE SEQUENCE tac_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_tac_id BEFORE INSERT ON tac
for each row 
begin     
	if inserting then 
		--deactivate all the others		
		update tac set isactive='0';

		if :NEW.tacid is null then
			SELECT tac_id_seq.nextval into :NEW.tacid from dual;
		end if;
	end if; 
end;
/


CREATE OR REPLACE TRIGGER add_tac_clients AFTER INSERT ON tac
--for each row 
DECLARE 
	latest_tac_id int;
begin     
	
	SELECT max(tacid) INTO latest_tac_id FROM tac;  

	UPDATE clientlicenses SET tacid = latest_tac_id
		WHERE clientlicenseid IN
			(select clientlicenseid from vwallchecklists
			where (approved = '0') AND (rejected = '0') AND (clientphaselna = 0) AND (currentphase = 'tac'));	--clcid is coalesced to 0 in the view vwclcclients
		
end;
/



--Approve the offerletter
CREATE OR REPLACE FUNCTION approveoffer(cli_lic_id IN varchar2,logged_user IN varchar2,approval IN varchar2,filter_id IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	BEGIN
		
	IF approval = 'Approve' THEN
	  UPDATE clientlicenses set offerapproved='1', offerapproveddate = sysdate, offerapprovedby = cast (logged_user as int) WHERE clientlicenseid = CAST(cli_lic_id AS int);
	  COMMIT;	
	END IF;

	IF approval = 'Disapprove' THEN
	  UPDATE clientlicenses set offerapproved='0' WHERE clientlicenseid = CAST(cli_lic_id AS int);
	  COMMIT;	
	END IF;

	RETURN 'Offer' || approval || 'd';
END;
/





CREATE TABLE clientlicenses (
	clientlicenseid		integer primary key,
	
	clientid			integer references clients,		--constraint removed
	licenseid			integer references licenses,	
	licensenumber		varchar(120),
	categoryappliedfor	varchar(120),
	categoryapproved	varchar(120),
	categoryrecomm		varchar(120),

	parentclientlicenseid	integer references clientlicenses,	--just incase this is a convenience entry eg in case of additional frequency in a network

	isapproved			char(1) default '0' not null,		--is license initialy approved ?
	isactive			char(1) default '0' not null,
	isexpired			char(1) default '0' not null,

	purposeoflicense	clob,

	iscancelled			char(1) default '0' not null,
	isterminated		char(1) default '0' not null,

	suspended			char(1) default '0' not null,
	Rejected			char(1) default '0' not null,

	APPROVE_EMAIL 		CHAR(1) DEFAULT '0',
	REJECT_EMAIL  		CHAR(1) DEFAULT '0',
	APPROVEd 			CHAR(1) DEFAULT '0',
	REJECT_REASON 		CLOB,

	--email notices
	--FSM ?
	isclcemailsent			char(1) default '0' not null,	
	ispostclcemailsent		char(1) default '0' not null,
	isofferemailsent		char(1) default '0' not null,
	isinitialfeeemailsent	char(1) default '0' not null,	
	isassignmentemailsent	char(1) default '0' not null,
	islicensereadyemailsent	char(1) default '0' not null,
	isrenewalreminderemailsent	char(1) default '0' not null,	--license renewal reminder
	isoverduepaymentemailsent	char(1) default '0' not null,	--overdue payment (expired license)
	isacknowlegementemailsent	char(1) default '0' not null,
	--LCS ?
	isdifferalemailsent char(1) default '0' not null,	
	isgazettementemailsent char(1) default '0' not null,	
	islicenseapprovalemailsent char(1) default '0' not null,	
	iscomplreturnsQemailsent char(1) default '0' not null,	
	iscomplreturnsAemailsent char(1) default '0' not null,	
	isAAAremindersent char(1) default '0' not null,	
	isnummberallocationemailsent char(1) default '0' not null,	
	isTAcertificateemailsent ,char(1) default '0' not null,	
	

	isnetworkexpansion	char(1) default '0' not null,	
	isfreqexpansion	char(1) default '0' not null,
	islicensereinstatement	char(1) default '0' not null,

	isexclusiveaccess	char(1) default '0' not null,
	exclusivebwMHz		real default 0,	

	isexpansion				char(1) default '0' not null,			--is this an expanded network
	isexpansionapproved			char(1) default '0' not null,		--???
	skipclc 				char(1) default '0' not null,			--manage may allow it to skip the CLC stage

	applicationdate		date default SYSDATE,
	offersentdate		date,
	
	offerapproved		char(1) default '0' not null,
	offerapproveddate	date,
	offerapprovedby		integer references users,

	licensedate			date,
	licensestartdate	date,
	licensestopdate		date,
	rejecteddate		date,

	approveUserid		integer,
	rejectuserid		integer,
	rolloutperiod		integer default 0,

	rolloutdate			date,
	renewaldate			date,

	rolledout			char(1) default '0',
	applicationfee		real default 0 not null,
	initialfee			real default 0 not null,
	annualfee			real default 0 not null,
	agtfee				real default 0 not null,
	typeapprovalfee		real default 0 not null,	

	commiteeremarks		clob,
	secretariatremarks	clob,

	clcid integer references clc,
	tacid integer references tac,

	userid integer references users,

	remarks				clob,			--updated by trigger
	details				clob
);
CREATE INDEX clientlicenses_clientid ON clientlicenses (clientid);
CREATE INDEX clientlicenses_licenseid ON clientlicenses (licenseid);
CREATE SEQUENCE clientlicenses_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 200;
CREATE OR REPLACE TRIGGER tr_clientlicense_id BEFORE INSERT ON clientlicenses
for each row 
begin     
	if inserting then 
		if :NEW.clientlicenseid is null then
			SELECT clientlicenses_id_seq.nextval into :NEW.clientlicenseid from dual;
		end if;
	end if; 
end;
/

--EXCLUSIVE BW ASSIGNMENT
CREATE OR REPLACE TRIGGER tr_upd_bw BEFORE UPDATE ON clientlicenses
for each row 
begin     
	if updating then 
		if :NEW.exclusivebwMHz > 0 then
			:NEW.isexclusiveaccess := '1';
		else
			:NEW.isexclusiveaccess := '0';
		end if;
	end if; 
end;
/

--alter table clientlicenses drop constraint blahblah	--to accomodate old clients

--VIOLATION TYPES ........ rather violation ACTIONS
CREATE TABLE VIOLATIONTYPE(	
	violationtypeid 	integer primary key,
	violationname		varchar(20),
	
	penaltyfixed		float,		--if there is a fixed penalty
	penaltypercentage	float,		--if there is a percentage penalty
    penaltytarget		varchar(50),	--what is to be targeted: annualfee, months, years, etc
		

	details				clob
	);
CREATE SEQUENCE violationtype_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_violationtype_id BEFORE INSERT ON violationtype
for each row 
begin     
	if inserting then 
		if :NEW.violationtypeid is null then
			SELECT violationtype_id_seq.nextval into :NEW.violationtypeid from dual;
		end if;
	end if; 
end;
/

--stores license terminations, suspensions, cancellations
	
CREATE TABLE LICENSEVIOLATIONS(
	licenseviolationid		integer primary key,

	violationtypeid			integer references violationtype,
	clientlicenseid			integer references clientlicenses,	
	correspondenceid		integer references correspondence,
	
	fmitaskid				integer references fmitasks,		--if this is a result of a monitoring task
	periodid				integer references periods,

	foremail				char(1) default '0' not null,

	isreinstated			char(1) default '0' not null,
	reinstateddate			date,			--date reistated

	isvoluntary				char(1) default '0' not null, --is this cancellation/termination entry requested by the user ?
	justification			varchar(100),			--justification for this action	

	requiredactionbyuser	varchar(100),			--what the user must do to regain legal operation
	requiredactiondate		date,				--if action done by this date case may be reconsidered

	undo_date				date,			--date of re-instatement, if any
	undo_remarks			clob,			--reasons for reinstatement and other remarks
	undo_user				integer references users,	--user who did the actual re-instatement on the system db
	
	violationdate			date not null default sysdate,				--date reported (effective date). considered in calculating period of inactivity
	actiondate				date default sysdate,		--date of insert 
	

	userid					integer references users,	--logged in user
	details					clob
	);
CREATE SEQUENCE licenseviolation_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_licenseviolation_id BEFORE INSERT ON licenseviolations
for each row 

declare
	period varchar(32);

-- 	CURSOR period_cur IS
-- 		SELECT periodid FROM periods WHERE periods.isactive = '1';
-- 		rec_period period_cur%ROWTYPE;

begin     
-- 	OPEN period_cur;
-- 	FETCH period_cur INTO rec_period;


	if inserting then 
    	SELECT periodid INTO period FROM periods WHERE periods.isactive = '1';
  
		if :NEW.licenseviolationid is null then
			SELECT licenseviolation_id_seq.nextval into :NEW.licenseviolationid from dual;
			:NEW.periodid := period;
		end if;

		--we need to update. we also need to know the implications of each 
		--clientlicenses.isactive, issuspended, iscancelled, isterminated
		if (:NEW.violationtypeid = 1) then		--suspend
			update clientlicenses set isactive='0', suspended='1', iscancelled='0', isterminated='0' where clientlicenseid=:new.clientlicenseid;			
			
		elsif (:NEW.violationtypeid = 2) then								--terminate
			update clientlicenses set isactive='0', suspended='0', iscancelled='0', isterminated='1' where clientlicenseid=:new.clientlicenseid;						

		elsif (:NEW.violationtypeid = 3) then								--cancellation
			update clientlicenses set isactive='0', suspended='0', iscancelled='1', isterminated='0' where clientlicenseid=:new.clientlicenseid;						

		end if;

	end if; 
end;
/



CREATE TABLE dbquerry(
	dbquerryid 		integer primary key,
	appletcode		varchar(500),
	jnlpfile		varchar(50),	
	details 		clob
	);



CREATE OR REPLACE VIEW vwlicenseviolations AS
	SELECT licenseviolations.licenseviolationid, licenseviolations.violationtypeid, licenseviolations.clientlicenseid, licenseviolations.justification, actiondate, violationdate, 
  round(MONTHS_BETWEEN(SYSDATE, violationdate)) as inactivemonths,
	licenseviolations.requiredactionbyuser, licenseviolations.isreinstated, vwclientlicenses.clientid, vwclientlicenses.clientname, vwclientlicenses.licensename
	FROM licenseviolations
	INNER JOIN vwclientlicenses on licenseviolations.clientlicenseid = vwclientlicenses.clientlicenseid;


--trunked radio type can be PMR or PAMR
create table trunkedradiotype(
	trunkedradiotypeid integer primary key,
	trunkedradiotypename varchar(50),
	details clob
	);
CREATE SEQUENCE trunkedradiotype_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_trunkedradiotype_id BEFORE INSERT ON trunkedradiotype
for each row 
begin     
	if inserting then 
		if :NEW.trunkedradiotypeid is null then
			SELECT trunkedradiotype_id_seq.nextval into :NEW.trunkedradiotypeid from dual;
		end if;
	end if; 
end;
/


CREATE OR REPLACE VIEW vwdistinctvhfnetwork AS
	SELECT distinct vwclientlicenses.clientlicenseid, vwclientlicenses.effectiveclientlicenseid,  vhfnetwork.vhfnetworkid, 
  vhfnetwork.vhfnetworkname, vhfnetwork.vhfnetworklocation,vhfnetwork.extranumberoffrequencies,
	clients.clientname, licenses.licensename, decode(vwclientlicenses.isnetworkexpansion,'1','This is a network expansion',decode(vwclientlicenses.isfreqexpansion,'1',getFreqExpDetails(vhfnetwork.vhfnetworkid),'Normal Application')) as applicationdescription
	FROM vhfnetwork
	INNER JOIN vwclientlicenses ON vhfnetwork.clientlicenseid = vwclientlicenses.effectiveclientlicenseid
	INNER JOIN clients ON vwclientlicenses.clientid = clients.clientid	
	INNER JOIN licenses ON vwclientlicenses.licenseid = licenses.licenseid;




CREATE OR REPLACE VIEW vwvhfnetwork AS
	SELECT vwclientlicenses.clientlicenseid, vwclientlicenses.effectiveclientlicenseid,  vhfnetwork.vhfnetworkid, vhfnetwork.vhfnetworkname, vhfnetwork.vhfnetworklocation,
	vhfnetwork.created, vhfnetwork.createdby, vhfnetwork.updated, vhfnetwork.updatedby, vhfnetwork.userid, decode(vwclientlicenses.isfreqexpansion,'1',vhfnetwork.extranumberoffrequencies,0) as extranumberoffrequencies,
	clients.clientname, licenses.licensename, 
	decode(vwclientlicenses.isnetworkexpansion,'1','This is a network expansion',decode(vwclientlicenses.isfreqexpansion,'1',getFreqExpDetails(vhfnetwork.vhfnetworkid),decode(vwclientlicenses.islicensereinstatement,'1','License Reinstatement','Normal Application'))) as applicationdescription
	FROM vhfnetwork
	INNER JOIN vwclientlicenses ON vhfnetwork.clientlicenseid = vwclientlicenses.effectiveclientlicenseid
	INNER JOIN clients ON vwclientlicenses.clientid = clients.clientid	
	INNER JOIN licenses ON vwclientlicenses.licenseid = licenses.licenseid;




CREATE OR REPLACE FUNCTION getFreqExpDetails(vhf_net_id IN varchar2) RETURN varchar2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	
	remarks varchar(2000);	
  
  extra int;
  num int;
  cli_lic_id int;
BEGIN
	
  remarks := 'Request for addition of frequenc(ies) ';
  
  SELECT clientlicenseid,extranumberoffrequencies INTO cli_lic_id,extra FROM vhfnetwork WHERE vhfnetworkid = cast(vhf_net_id as int);
  
  remarks := remarks || 'from <b>';
  
	FOR myrec IN (SELECT DISTINCT numberoffrequencies FROM clientstations WHERE vhfnetworkid = cast(vhf_net_id as int)) LOOP
		remarks := remarks ||  myrec.numberoffrequencies || '<br>';
    num:= myrec.numberoffrequencies;
	END LOOP;

	remarks := remarks || '</b> to <b>' || (num+extra) || '</b>' || '. Original/License ID: <b>' || cli_lic_id || '</b>';	
  
	RETURN remarks;
END;
/





--network 
CREATE TABLE VHFnetwork(
	vhfnetworkid 			integer primary key,
	CLIENTLICENSEID 		integer references clientlicenses, 	
	vhfnetworkname			varchar(50),
	vhfnetworklocation		varchar(50),

	
	extranumberoffrequencies 	integer default 0,	--insert into another table and clear this field once approval has been obtained.

	created					DATE DEFAULT SYSDATE,		
	createdby				integer references users,
	updated					DATE DEFAULT SYSDATE,
	updatedby				integer references users,
	userid					integer references users,
	
	remark					clob,		--update by trigger
	details					clob
	);
CREATE INDEX VHFnetwork_clientlicenses ON VHFnetwork (CLIENTLICENSEID);


CREATE SEQUENCE VHFnetwork_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_VHFnetwork_id BEFORE INSERT ON VHFnetwork
for each row 
begin     
	if inserting then 
		if :NEW.vhfnetworkid is null then
			SELECT VHFnetwork_id_seq.nextval into :NEW.vhfnetworkid from dual;

			:NEW.createdby := :NEW.userid;
			:NEW.updatedby := :NEW.userid;

		end if;
	end if; 
end;
/

--FREQUENCY EXPANSION
CREATE OR REPLACE TRIGGER tr_extra_frequency BEFORE UPDATE ON VHFnetwork
for each row 

DECLARE
 
  --PRAGMA AUTONOMOUS_TRANSACTION;
 
	CURSOR clientlicense_cur IS
		SELECT clientlicenseid, clientid, licenseid			
		FROM clientlicenses 		
		WHERE clientlicenseid = :NEW.clientlicenseid;
		rec_clientlicenses clientlicense_cur%ROWTYPE;
	
		cli_lic_id int;		

begin     
	
	OPEN clientlicense_cur;
	FETCH clientlicense_cur INTO rec_clientlicenses;

	--fetch the new/next clientlicenseid for use in the next insert (this is a convenience application and may not result into a new licenses)
	SELECT clientlicenses_id_seq.nextval INTO cli_lic_id FROM dual;

	if updating then 				
		--we want the network to reflect the task at hand
		:NEW.remark := 'Request for Additional ' || :NEW.extranumberoffrequencies || ' frequency(s) on the network: ' || :new.vhfnetworkname;
		
		IF (:NEW.extranumberoffrequencies > 0) THEN --if there is need for extra frequency......
			--make a new application (with reference to original/parent application/license)
			INSERT INTO clientlicenses (clientlicenseid, parentclientlicenseid, clientid, licenseid, remarks, isnetworkexpansion, isfreqexpansion, applicationdate) 
				VALUES (cli_lic_id, rec_clientlicenses.clientlicenseid, rec_clientlicenses.clientid, rec_clientlicenses.licenseid,:NEW.remark, '0','1',SYSDATE);			

			--link the new network with the new application/license
			--INSERT INTO vhfnetwork (clientlicenseid, vhfnetworkname, vhfnetworklocation, userid)
			--	VALUES (cli_lic_id, 'Expansion:' || :new.temp_vhfnetworkid || ': ' || :new.vhfnetworkname, :new.vhfnetworklocation, :new.userid);
			--COMMIT;
			
			--UPDATE stations SET extranumberoffrequencies = :NEW.extranumberoffrequencies WHERE vhfnetworkid = :NEW.vhfnetworkid;
			UPDATE stations SET numberoffrequencies = numberoffrequencies + :NEW.extranumberoffrequencies WHERE vhfnetworkid = :NEW.vhfnetworkid;
			--COMMIT;
			
			--advance application to clc stage (and let the manager decide wether it skips clc or not)
			--A. CLEAR CHECKLISTS at receiving and checking (another solution is to copy the clientphase and clientchecklist data for related clientlienseid)
			--a. identify corresponding clientphases
			FOR phaserec IN (select * from clientphases inner join phases on clientphases.phaseid=phases.phaseid where clientlicenseid = cli_lic_id and phases.phaselevel <= 2) LOOP
				
				--b. identify corresponding clientchecklists
				FOR checkrec IN (select * from clientchecklists where clientphaseid = phaserec.clientphaseid) LOOP
						--clear checklist
						UPDATE clientchecklists SET approved = '1', rejected = '0', actiondate = SYSDATE, userid = :NEW.userid
							WHERE clientchecklistid = checkrec.clientchecklistid;																

				END LOOP;
				
				--approve the phase after clearing all the checklists
				UPDATE clientphases SET approved = '1', rejected = '0', pending = '0', isdone='1', actiondate = sysdate, userid = :NEW.userid
				WHERE clientphaseid = phaserec.clientphaseid;
										
			END LOOP;
		END IF;
	end if; 
	
    CLOSE clientlicense_cur;    

end;
/


---NETWORK EXPANSION
---EVERYTHING THAT GOES THRU HERE MUST PAY 1K APPLICATION FEE AND JUMP STRAIGHT TO OFFER LETTER STAGE
--both this and the next (table) must generate a new application and progress it to offer stage
CREATE TABLE temp_vhfnetwork(
	temp_vhfnetworkid 			integer primary key,
	CLIENTLICENSEID 		integer references clientlicenses, 	
	vhfnetworkname			varchar(50),
	vhfnetworklocation		varchar(50),

	created					DATE DEFAULT SYSDATE,		
	createdby				integer references users,
	updated					DATE DEFAULT SYSDATE,
	updatedby				integer references users,
	userid					integer references users,

	details					clob
	);
CREATE INDEX temp_vhfnetwork_clientlicenses ON temp_vhfnetwork (CLIENTLICENSEID);
CREATE SEQUENCE temp_vhfnetwork_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_temp_vhfnetwork_id BEFORE INSERT ON temp_vhfnetwork
for each row 
begin     
	if inserting then 
		if :NEW.temp_vhfnetworkid is null then
			SELECT temp_vhfnetwork_id_seq.nextval into :NEW.temp_vhfnetworkid from dual;

			:NEW.createdby := :NEW.userid;
			:NEW.updatedby := :NEW.userid;

		end if;
	end if; 
end;
/


--AFTER INSERT 
--1. INSERT INTO CLIENTLICENSES INORDER TO HAVE IT AS A NEW LICENSE
--2. INSERT INTO VHFNETWORK (AFTER INSERT INTO CLIENTLICENSES ABOVE) AND LINK IT TO THE RIGHT CLIENTLICENSEID
--3. ADVANCE IT PAST CLC

--NETWORK EXPANSION
CREATE OR REPLACE TRIGGER tr_ins_vhfnetwork AFTER INSERT ON temp_vhfnetwork 
FOR EACH ROW
	
 DECLARE
 
  --PRAGMA AUTONOMOUS_TRANSACTION;
 
	CURSOR clientlicense_cur IS
		SELECT clientlicenseid, clientid, licenseid			
		FROM clientlicenses 		
		WHERE clientlicenseid = :NEW.clientlicenseid;
		rec_clientlicenses clientlicense_cur%ROWTYPE;
	
		cli_lic_id int;			

 BEGIN	

		OPEN clientlicense_cur;
		FETCH clientlicense_cur INTO rec_clientlicenses;
		
		--we want the network to reflect the task at hand
		--:NEW.remark := 'Request for Additional ' || :NEW.extranumberoffrequencies || ' frequency(s) on this network';

		--fetch the new/next clientlicenseid for use in the next insert (this has to be treated as a new license)
		SELECT clientlicenses_id_seq.nextval INTO cli_lic_id FROM dual;

		--create a new application/license using the id we generated above, also mark the source application/license
		INSERT INTO clientlicenses (clientlicenseid, parentclientlicenseid, clientid, licenseid, remarks, isnetworkexpansion, isfreqexpansion, applicationdate) 
			VALUES (cli_lic_id, rec_clientlicenses.clientlicenseid, rec_clientlicenses.clientid, rec_clientlicenses.licenseid,'Request for Network Expansion: License ID:' || rec_clientlicenses.clientlicenseid,'1','0', SYSDATE);
		--COMMIT;

		--link the new network with the new application/license
		INSERT INTO vhfnetwork (clientlicenseid, vhfnetworkname, vhfnetworklocation, userid)
			VALUES (cli_lic_id, 'Expansion:' || :new.temp_vhfnetworkid || ': ' || :new.vhfnetworkname, :new.vhfnetworklocation, :new.userid);
		--COMMIT;

		--advance application to freq reservation stage
		--A. CLEAR CHECKLISTS at receiving and checking (another solution is to copy the clientphase and clientchecklist data for related clientlienseid)
		--a. identify corresponding clientphases
		FOR phaserec IN (select * from clientphases inner join phases on clientphases.phaseid=phases.phaseid where clientlicenseid = cli_lic_id and phases.phaselevel <= 2) LOOP
			
			--b. identify corresponding clientchecklists
			FOR checkrec IN (select * from clientchecklists where clientphaseid = phaserec.clientphaseid) LOOP
					--clear checklist
					UPDATE clientchecklists SET approved = '1', rejected = '0', actiondate = SYSDATE, userid = :NEW.userid
						WHERE clientchecklistid = checkrec.clientchecklistid;																

			END LOOP;
			
			--approve the phase after clearing all the checklists
			UPDATE clientphases SET approved = '1', rejected = '0', pending = '0', isdone='1', actiondate = sysdate, userid = :NEW.userid
			WHERE clientphaseid = phaserec.clientphaseid;
									
		END LOOP;

    CLOSE clientlicense_cur;
    
 END;
 /





--EXPANSION: adding stations to existing network
CREATE TABLE TEMP_STATIONS(
  	TEMP_STATIONID 			integer primary key,	
	CLIENTLICENSEID 			integer references clientlicenses, 
	LICENSEPRICEID 				integer references licenseprices, 	

	temp_vhfnetworkid			integer references temp_vhfnetwork,

	trunkedradiotypeid			integer references trunkedradiotype,
	CLIENTSTATIONNAME 			VARCHAR2(20), 	

	APPLICATIONDATE				DATE DEFAULT SYSDATE,

	NUMBEROFREQUESTEDSTATIONS 	NUMBER default 1,
	NUMBEROFAPPROVEDSTATIONS 	NUMBER default 1,

	AIRCRAFTNAME				VARCHAR2(100),
	AIRCRAFTTYPE				VARCHAR2(100),
	AIRCRAFTREGNO				VARCHAR2(100),

	CALLSIGN					VARCHAR(100),

	NUMBEROFFREQUENCIES			NUMBER default 1, 		--this is the number of frequencies requested 
	DECODERCAPACITY				REAL,
	REQUESTEDFREQUENCYBANDS		VARCHAR2(250),
	REQUESTEDFREQUENCY			REAL,				--khz
	REQUESTEDBANDWIDTH			REAL,
	NOMINALTXPOWER				REAL,		--the nominal transmitter power
	EFFECTIVETXPOWER			REAL,		--the effective isotropicaly radiated power

	TENTATIVEPRICE				NUMBER,		--initial fee for broadcasting
	FINALPRICE					NUMBER,		--annual fee for broadcasting

	LOCATION 					VARCHAR2(200), 
	USERID 						NUMBER, 		
	DETAILS 					CLOB
);

CREATE INDEX TEMP_STATIONS_clientlicenses ON TEMP_STATIONS (CLIENTLICENSEID);
CREATE INDEX TEMP_STATIONS_licenseprices ON TEMP_STATIONS (LICENSEPRICEID);	
CREATE SEQUENCE TEMP_STATIONS_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_TEMP_STATIONS_id BEFORE INSERT ON TEMP_STATIONS
for each row 
begin     
	if inserting then 
		if :NEW.TEMP_STATIONid is null then
			SELECT TEMP_STATIONS_id_seq.nextval into :NEW.TEMP_STATIONid from dual;

			--:NEW.createdby := :NEW.userid;
			--:NEW.updatedby := :NEW.userid;

		end if;
	end if; 
end;
/


--alarm network similar to vhfnetwork table. but not yet used. 
--to ensure continuity stations/alarm units will have BOTH clientlicenseid (for backward compatibility) and alarmnetwork id
CREATE TABLE alarmnetwork(
	alarmnetworkid 			integer primary key,
	CLIENTLICENSEID 		integer references clientlicenses, 	
	alarmnetworkname			varchar(50),
	alarmnetworklocation		varchar(50),

	created					DATE DEFAULT SYSDATE,		
	createdby				integer references users,
	updated					DATE DEFAULT SYSDATE,
	updatedby				integer references users,
	userid					integer references users,

	details					clob
	);
CREATE INDEX alarmnetwork_clientlicenses ON alarmnetwork (CLIENTLICENSEID);


CREATE SEQUENCE alarmnetwork_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_alarmnetwork_id BEFORE INSERT ON alarmnetwork
for each row 
begin     
	if inserting then 
		if :NEW.alarmnetworkid is null then
			SELECT alarmnetwork_id_seq.nextval into :NEW.alarmnetworkid from dual;

			:NEW.createdby := :NEW.userid;
			:NEW.updatedby := :NEW.userid;

		end if;
	end if; 
end;
/











--b4 clc
-- VHF network
CREATE OR REPLACE VIEW vwnetworkstations AS 
  select vwclientlicenses.clientlicenseid, vwclientlicenses.clientid, vwclientlicenses.clientname, vwclientlicenses.licenseid, vwclientlicenses.remarks,
	vwclientlicenses.licensename, clientstations.clientstationid,clientstations.numberofrequestedstations, clientstations.numberofapprovedstations, 
	vhfnetwork.vhfnetworkid, vhfnetwork.vhfnetworkname, vhfnetwork.vhfnetworklocation, clientstations.numberoffrequencies,decode(numberoffrequencies, 1, 'Simplex', 2, 'Duplex', numberoffrequencies || ' channels' ) as channeltype, round(clientstations.tentativeprice) as tentativeprice, round(clientstations.finalprice) as finalprice,
	clientstations.aircrafttype, clientstations.aircraftname, clientstations.aircraftregno,licenseprices.licensepriceid, proratedChargePeriod(current_date) as chargedmonths, clc.clcid, clc.clcdate, clc.clcnumber,
	licenseprices.typename, licenseprices.stationclassid, clientstations.requestedfrequencybands, clientstations.requestedfrequency,clientstations.requestedbandwidth,trunkedradiotype.trunkedradiotypename,
	countnetworkstations(clientstations.vhfnetworkid) as stations, vwclientlicenses.clienttypename, vwclientlicenses.clientcategoryname, vwclientlicenses.secretariatremarks, vwclientlicenses.commiteeremarks,
	(vwclientlicenses.clientname ||'<br>'|| 'P.O.Box ' || vwclientlicenses.address ||'<br>' || initcap(vwclientlicenses.town) || '-' || vwclientlicenses.postalcode || '<br>' || initcap(vwclientlicenses.countryname)) as clientdetail,
	decode(vwclientlicenses.isnetworkexpansion,'1','This is a network expansion',decode(vwclientlicenses.isfreqexpansion,'1','This is a frequency addition','Normal Application')) as applicationdescription
	from vwclientlicenses
	left join clc on vwclientlicenses.clcid = clc.clcid
	inner join vhfnetwork on vwclientlicenses.clientlicenseid=vhfnetwork.clientlicenseid
	inner join clientstations on clientstations.vhfnetworkid=vhfnetwork.vhfnetworkid
	inner join licenseprices on clientstations.licensepriceid=licenseprices.licensepriceid
	left join trunkedradiotype on clientstations.trunkedradiotypeid = trunkedradiotype.trunkedradiotypeid;
 


--used for initial application. accomodates aircrafts as stations in addition to others
CREATE TABLE CLIENTSTATIONS(
  	CLIENTSTATIONID 			integer primary key,	
	CLIENTLICENSEID 			integer references clientlicenses, 
	LICENSEPRICEID 				integer references licenseprices, 	

	vhfnetworkid				integer references vhfnetwork,

	trunkedradiotypeid			integer references trunkedradiotype,
	CLIENTSTATIONNAME 			VARCHAR2(20), 	

	APPLICATIONDATE				DATE DEFAULT SYSDATE,

	NUMBEROFREQUESTEDSTATIONS 	NUMBER default 1,
	NUMBEROFAPPROVEDSTATIONS 	NUMBER default 1,

	AIRCRAFTNAME				VARCHAR2(100),
	AIRCRAFTTYPE				VARCHAR2(100),
	AIRCRAFTREGNO				VARCHAR2(100),

	CALLSIGN					VARCHAR(100),

	isdummy						char(1) default '0' not null,		--for entries that need not be propageted to STATIONS table. eg when reinstating a license (STATIONS are usually copied directly from the previous license hence no need to propaget)

	NUMBEROFFREQUENCIES			NUMBER default 1, 		--this is the number of frequencies requested 
	DECODERCAPACITY				REAL,
	REQUESTEDFREQUENCYBANDS		VARCHAR2(250),
	REQUESTEDFREQUENCY			REAL,				--khz
	REQUESTEDBANDWIDTH			REAL,
	NOMINALTXPOWER				REAL,		--the nominal transmitter power
	EFFECTIVETXPOWER			REAL,		--the effective isotropicaly radiated power

	TENTATIVEPRICE				NUMBER,		--initial fee for broadcasting
	FINALPRICE					NUMBER,		--annual fee for broadcasting

	LOCATION 					VARCHAR2(200), 
	USERID 						NUMBER, 		
	DETAILS 					CLOB
);

CREATE INDEX CLIENTSTATIONS_clientlicenses ON CLIENTSTATIONS (CLIENTLICENSEID);
CREATE INDEX CLIENTSTATIONS_licenseprices ON CLIENTSTATIONS (LICENSEPRICEID);
CREATE INDEX CLIENTSTATIONS_vhfnetwork ON CLIENTSTATIONS (vhfnetworkid);
CREATE INDEX CLIENTSTATIONS_trunkedradio ON CLIENTSTATIONS (trunkedradiotypeid);
 			
CREATE SEQUENCE clientstations_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
--BEFORE INSERT
CREATE OR REPLACE TRIGGER tr_clientstation_id BEFORE INSERT ON clientstations
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

	CURSOR licenseprices_cur IS
		SELECT licenseprices.licensepriceid, licenseprices.licenseid, licenseprices.stationclassid, 
			licenseprices.typename, licenseprices.amount, licenseprices.unitgroups, licenseprices.onetimefee, 
			licenseprices.perlicense, licenseprices.perstation, licenseprices.perfrequency, licenseprices.hasfixedcharge,
			licenseprices.functname, licenseprices.formula, licenses.initialfee, licenses.annualfee					
		FROM licenseprices 
		INNER JOIN LICENSES ON licenseprices.licenseid = licenses.licenseid
		WHERE licensepriceid = :NEW.licensepriceid;
		rc licenseprices_cur%ROWTYPE;

begin     
	if inserting then 
		if :NEW.clientstationid  is null then
			SELECT clientstations_id_seq.nextval into :NEW.clientstationid  from dual;

			:NEW.numberofapprovedstations := :NEW.numberofrequestedstations;
			
			--test
			OPEN licenseprices_cur;
			FETCH licenseprices_cur INTO rc;
			
			IF (rc.hasfixedcharge = '1') THEN
				:NEW.tentativeprice := rc.initialfee;
				:NEW.finalprice := rc.annualfee;
				RETURN;
			END IF;

				
			IF (rc.perstation = '1') THEN
				tprice := rc.amount * :NEW.numberofrequestedstations;
				fprice := rc.amount * :NEW.numberofapprovedstations;
			END IF;
			
			IF (rc.perfrequency = '1') THEN
				tprice := tprice * :NEW.numberoffrequencies;
				fprice := tprice;
			END IF;
			
			unitfee := 574.10;	
			
			IF(:NEW.isdummy='1')THEN
        :NEW.tentativeprice := tprice;
				:NEW.finalprice := fprice;
				RETURN;
			END IF;

			--dbms_output.enable(500);	--enable console output and initialize the buffer size

			IF (rc.functname = 'alarms') THEN
				
				val := :NEW.NUMBEROFREQUESTEDSTATIONS;
				dbms_output.put_line('Before Algo val = ' || val);
				WHILE (mod(val,5) != 0) --max is not divisible by 5
					LOOP
						val := val + 1;						
					END LOOP;
				dbms_output.put_line('After Algo val = ' || val);

				:NEW.numberofapprovedstations := val;

				tprice := 1250 * val;
				fprice := tprice;
				
				:NEW.tentativeprice := tprice;
				:NEW.finalprice := fprice;

				--only b4 insert (not before update)
				insert into stations(licensepriceid, servicenatureid, vhfnetworkid, clientlicenseid, numberoffrequencies, unitsrequested, stationcharge, proratedcharge, siteid, userid)
						values(:NEW.licensepriceid,'CV', :NEW.vhfnetworkid, :NEW.clientlicenseid,:NEW.numberoffrequencies,val,:NEW.finalprice,:NEW.tentativeprice,1001,:new.userid);
				
				RETURN;

			END IF;



			:NEW.tentativeprice := tprice;
			:NEW.finalprice := fprice;

			--test insert into stations 
				--issues
				--1. (what about aircraft > if licenseprices.stationclassid is MA then its an aircraft ??
				--2. receivers ???? > if licenseprices.stationclassid is ML then its a receiver ??
				--3. alarms - b4 insert done (b4 update pending)
			
			--b4 training			
			--FOR private radio  [initialy was => IF (rc.stationclassid != 'MA' AND rc.stationclassid != 'MS') !!!!!!!]
			IF (rc.stationclassid = 'ML' OR rc.stationclassid = 'FB') THEN
				val := :NEW.NUMBEROFREQUESTEDSTATIONS;
				WHILE (val != 0) 
					LOOP
						insert into stations(licensepriceid,servicenatureid,vhfnetworkid,clientlicenseid,numberoffrequencies,siteid,userid)
							select :NEW.licensepriceid,'CV',:NEW.vhfnetworkid,clientlicenseid,:NEW.numberoffrequencies,1001,:NEW.userid
							from vhfnetwork where vhfnetworkid = :NEW.vhfnetworkid;
						val := val - 1;						
					END LOOP;
				RETURN;
			END IF;

			--for amateur stations
			--IF (rc.stationclassid = 'AT') THEN

				--RETURN;
			--end if;
			--for aircrafts MA
			IF (rc.stationclassid = 'MA') THEN
				val := :NEW.NUMBEROFREQUESTEDSTATIONS;
				WHILE (val != 0) 
					LOOP
						insert into stations(licensepriceid,servicenatureid,clientlicenseid,isaircraft,aircraftname,aircrafttype,aircraftregno,stationcallsign,requestedfrequencybands,siteid,userid)
							values (:NEW.licensepriceid,'CV',:new.clientlicenseid,'1',:new.aircraftname,:new.aircrafttype,:new.aircraftregno,:new.callsign,:new.requestedfrequencybands,null,:NEW.userid);							
						val := val - 1;						
					END LOOP;				
				RETURN;
			END IF;
						
			--FOR non PRIVATE RADIOS, the rest
			IF (rc.stationclassid != 'ML' OR rc.stationclassid != 'FB') THEN
				val := :NEW.NUMBEROFREQUESTEDSTATIONS;
				WHILE (val != 0) 
					LOOP
						insert into stations(licensepriceid,servicenatureid,clientlicenseid,numberoffrequencies,siteid,userid)
							values (:NEW.licensepriceid,'CV',:new.clientlicenseid,:NEW.numberoffrequencies,1001,:NEW.userid);
							--from vhfnetwork where vhfnetworkid = :NEW.vhfnetworkid;
						val := val - 1;						
					END LOOP;
				RETURN;
			END IF;
						
-- 			--receivers (ML can exist without FB !!)
-- 			IF (rc.stationclassid != 'ML') THEN
-- 				WHILE (val != 0) 
-- 					LOOP
-- 						insert into stations(licensepriceid,servicenatureid,clientlicenseid,numberoffrequencies,isaircraft,siteid,userid)
-- 								values(:NEW.licensepriceid,'CV',:NEW.clientlicenseid,:NEW.numberoffrequencies,'1',1001,0);
-- 						val := val - 1;						
-- 					END LOOP;				
-- 			END IF;


		--broadcasting 

		end if;
	end if; 
end;
/






--AFTER INSERT
-- CREATE OR REPLACE TRIGGER tr_update_vhf_stations AFTER INSERT ON clientstations
-- 
-- 		if (:NEW.vhfnetworkid is not null) then
-- 				--update clientstations and stations
-- 				update clientstations set clientlicenseid = (select clientlicenseid from vhfnetwork where vhfnetworkid = :NEW.vhfnetworkid)
-- 				where vhfnetworkid = :NEW.vhfnetworkid;
-- 		end if;
-- 
-- END;
-- /

--BEFORE UPDATE
CREATE OR REPLACE TRIGGER tr_update_clientstations BEFORE UPDATE ON clientstations
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

	CURSOR licenseprices_cur IS
		SELECT licenseprices.licensepriceid, licenseprices.licenseid, licenseprices.stationclassid, 
			licenseprices.typename, licenseprices.amount, licenseprices.unitgroups, licenseprices.onetimefee, 
			licenseprices.perlicense, licenseprices.perstation, licenseprices.perfrequency, 
			licenseprices.functname, licenseprices.formula					
		FROM licenseprices 
		WHERE licensepriceid = :NEW.licensepriceid;
		rc licenseprices_cur%ROWTYPE;

begin     
	if updating then 
		--if :NEW.clientstationid  is null then
			
			:NEW.numberofapprovedstations := :NEW.numberofrequestedstations;
			
			--test
			OPEN licenseprices_cur;
			FETCH licenseprices_cur INTO rc;

			IF (rc.perstation = '1') THEN
				tprice := rc.amount * :NEW.numberofrequestedstations;
				fprice := rc.amount * :NEW.numberofapprovedstations;
			END IF;

			IF (rc.perfrequency = '1') THEN
				tprice := tprice * :NEW.numberoffrequencies;
				fprice := tprice;
			END IF;
			
			unitfee := 574.10;	

			dbms_output.enable(500);	--enable console output and initialize the buffer size

			IF (rc.functname = 'alarms') THEN
				
				val := :NEW.NUMBEROFREQUESTEDSTATIONS;
				dbms_output.put_line('Before Algo val = ' || val);
				WHILE (mod(val,5) != 0) --max is not divisible by 5
					LOOP
						val := val + 1;						
					END LOOP;
				dbms_output.put_line('After Algo val = ' || val);

				:NEW.numberofapprovedstations := val;

				tprice := 1250 * val;
				fprice := tprice;
			END IF;

				
			IF (rc.functname = 'radiobroadcasting') THEN
					
				Pnom := :NEW.NOMINALTXPOWER;		--where from (equipment manual, user or fsm ?)
				Ptot := :NEW.EFFECTIVETXPOWER;		--where from (user or fsm ?)
				k1 := 1;
				k2 := 0.2 * (Pnom - 1);		--?
				k3 := 5;
					
				IF(Ptot <= 2)THEN		--Ptot = ERP ?
					tprice := 30000;
				END IF;
				IF(Ptot > 2) AND (Ptot <=5) THEN		
					tprice := 65000;
				END IF;
				IF(Ptot > 5) AND (Ptot <=10) THEN		
					tprice := 130000;
				END IF;
					
				IF(Ptot > 10)THEN		
					tprice := (((k1 * log(Pnom,10))/25) + ((k2 * log((Ptot-1),10))/25)) * (:NEW.requestedbandwidth/8.5) * unitfee * k3;					
					if(tprice < 130000) then
						tprice := 130000;
					end if;						
				END IF;
					
				fprice := tprice;
			END IF;

			IF (rc.functname = 'tvbroadcasting') THEN
				Pnom := :NEW.NOMINALTXPOWER;		--where from (equipment manual, user or fsm ?)
				Ptot := :NEW.EFFECTIVETXPOWER;		--where from (user or fsm ?)
				k1 := 1;
				k2 := 0.2 * (Pnom - 1);		--?
				k3 := 0.4;
				
				IF(Ptot <= 10)THEN		--Ptot = ERP ?
					tprice := 360000;
				END IF;
				
				IF(Ptot > 10)THEN		--1000khz = 1Ghz
					tprice := (((k1 * log(Pnom,10))/25) + ((k2 * log((Ptot-1),10))/25)) * (:NEW.requestedbandwidth/8.5) * unitfee * k3;
					if(tprice < 360000)then
						tprice := 360000;
					end if;
				END IF;				

				fprice := tprice;
			END IF;


			:NEW.tentativeprice := tprice;
			:NEW.finalprice := fprice;

			--test
		--end if;
	end if; --if updating
end;
/



























--
CREATE TRIGGER tr_updRequestedStations BEFORE UPDATE ON clientstations
for each row 
declare
	
	tprice real;
	fprice real;
	
	CURSOR licenseprices_cur IS
		SELECT licenseprices.licensepriceid, licenseprices.licenseid, licenseprices.stationclassid, 
			licenseprices.typename, licenseprices.amount, licenseprices.unitgroups, licenseprices.onetimefee, 
			licenseprices.perlicense, licenseprices.perstation, licenseprices.perfrequency, 
			licenseprices.functname, licenseprices.formula					
		FROM licenseprices 
		WHERE licensepriceid = :NEW.licensepriceid;
		rc licenseprices_cur%ROWTYPE;
		
begin     
	if updating then 				
			--recalculate tentative and final prices
			OPEN licenseprices_cur;
			FETCH licenseprices_cur INTO rc;

			--UPDATE stations SET unitsapproved = :NEW.numberofapprovedstations 
			--WHERE clientlicenseid = :NEW.clientlicenseid AND licensepriceid = :NEW.licensepriceid AND numberofrequestedstations = :NEW.unitsrequested;

			IF (rc.perstation = '1') THEN
				tprice := rc.amount * :NEW.numberofrequestedstations;
				fprice := rc.amount * :NEW.numberofapprovedstations;
			END IF;
			
			IF (rc.perfrequency = '1') THEN
				tprice := tprice * :NEW.numberoffrequencies;
				fprice := fprice * :NEW.numberoffrequencies;
			END IF;

			:NEW.tentativeprice := tprice;
			:NEW.finalprice := fprice;		
	end if; 
end;
/


CREATE TABLE clientformtypes (
	clientformtypeid	integer primary key,
	clientlicenseid		integer references clientlicenses,
	formtypeid			integer references formtypes,
	applicationdate		date default SYSDATE,
	submit				char(1) default '0' not null,
	submitdate			timestamp,
	IsActive			char(1) default '0' not null,
	ApproveDate			timestamp,
	ApproveUserid		integer,
	Rejected			char(1) default '0' not null,
	RejectedDate		timestamp,
	RejectUserid		integer,
	details				clob
);
CREATE INDEX clientformtypes_clientlicid ON clientformtypes (clientlicenseid);
CREATE INDEX clientformtypes_formtypeid ON clientformtypes (formtypeid);
CREATE SEQUENCE clientformtypes_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
create or replace TRIGGER tr_clientformtypeid_id BEFORE INSERT ON clientformtypes
for each row 
begin     
	if inserting then 
		if :NEW.clientformtypeid is null then
			SELECT clientformtypes_id_seq.nextval into :NEW.clientformtypeid from dual;
		end if;
	end if; 
end;
/


CREATE TABLE clientforms (
	clientformid		integer primary key,
	clientformtypeid	integer references clientformtypes,
	formid				integer references forms,
	answer				varchar(240)
);
CREATE INDEX clientforms_clientformtypid ON clientforms (clientformtypeid);
CREATE INDEX clientforms_formid ON clientforms (formid);
CREATE SEQUENCE clientforms_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_clientformid_id BEFORE INSERT ON clientforms
for each row 
begin     
	if inserting then 
		if :NEW.clientformid is null then
			SELECT clientforms_id_seq.nextval into :NEW.clientformid from dual;
		end if;
	end if; 
end;
/


CREATE TABLE clientsubforms (
	clientsubformid		integer primary key,
	clientformtypeid	integer references clientformtypes,
	formid				integer references forms,
	subformid			integer references subforms,
	answerline			integer not null,
	answer				varchar(240)
);
CREATE INDEX clientsubfs_clientformtypeid ON clientsubforms (clientformtypeid);
CREATE INDEX clientsubforms_subformid ON clientsubforms (subformid);
CREATE INDEX clientsubforms_formid ON clientsubforms (formid);
CREATE SEQUENCE clientsubforms_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_clientsubformid_id BEFORE INSERT ON clientsubforms
for each row 
begin     
	if inserting then 
		if :NEW.clientsubformid is null then
			SELECT clientsubforms_id_seq.nextval into :NEW.clientsubformid from dual;
		end if;
	end if; 
end;
/



CREATE OR REPLACE VIEW licenseperiodview AS
	SELECT licenses.licenseid, licenses.licensename, periods.periodid, 
	('Period: <font color="red">' || periods.startdate || '</font> To <font color="red">' || periods.enddate || '</font>') as periodsummary,periods.isactive
	FROM licenses, periods
	WHERE (licenses.licenseid > 500) AND (licenses.licensetypeid=16);



CREATE OR REPLACE VIEW vwperiodclients AS
	SELECT periods.periodid, periods.periodname, periods.startdate, periods.enddate, periods.isactive, clients.clientid, clients.clientname
	FROM periods, clients
	--WHERE clients.isactive = '1';


CREATE TABLE periods (
	periodid			varchar(32) primary key,
	periodname 			varchar(32),
	startdate			date,
	enddate				date,
	invoicemonths		integer,
	isactive			char(1) default '0' not null,
	details				clob
);
create or replace TRIGGER TR_BEFPERIODLICENSES BEFORE INSERT ON periods 
	FOR EACH ROW 
	DECLARE
	PRAGMA AUTONOMOUS_TRANSACTION;
	BEGIN	
		UPDATE periods SET isactive = '0' WHERE periods.periodID != :NEW.periodID;
	--COMMIT;
END;

create or replace TRIGGER TR_UPDPERIODLICENSES AFTER INSERT ON periods 
FOR EACH ROW 
DECLARE
-- CURSOR approval_cur IS
--   SELECT DISTINCT paymenttypes.PAYMENTTYPEID, paymenttypes.paymenttypename, phases.phaseid, 
-- 	licenses.applicationfee,licenses.annualfee,licenses.initialfee,licenses.typeapprovalfee,
-- 	phases.forpayment,licenses.applicationaccount,clientphases.clientlicenseid,
-- 	licenses.initialaccount,licenses.annualaccount,licenses.taaccount,clientphases.clientphaseid
-- 	from clientphases inner join phases on phases.phaseid = clientphases.phaseid
-- 	inner join licenses on phases.licenseid = licenses.licenseid
-- 	inner join paymenttypes on phases.paymenttypeid = paymenttypes.paymenttypeid
-- 	where clientphaseid = CAST(myval1 as int);
-- 	c2 approval_cur%ROWTYPE;
BEGIN
	INSERT INTO periodlicenses(periodid, clientlicenseid)
  	SELECT :NEW.periodID ,clientlicenseid
	FROM   clientlicenses 
	WHERE clientlicenses.isactive = '1' ;

	--annual payments for LCS licenses (fixed fee)
	--INSERT INTO licensepayments (paymenttypeid,clientlicenseid,amount,userid,productcode,invoicedate,periodid,clientphaseid) 
	--  SELECT c2.annualfee ,c2.clientlicenseid ,amnt ,CAST(myval2 as int) ,prtcode,sysdate,c4.periodid,c2.clientphaseid
	--	FROM clientphases INNER JOIN phases ON phases.phaseid = clientphases.phaseid
	--	WHERE clientphases.clientphaseid = CAST(myval1 as int) AND (c2.forpayment = '1') AND rc.rccount = 0 ;

	--annual fee for FSM (computed)
	
END;






--test
CREATE TABLE inspectiontype(
	inspectiontypeid		integer primary key,
	inspectiontypename		varchar(50),
	details 		clob
	);
CREATE SEQUENCE inspectiontype_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_inspectiontype_id BEFORE INSERT ON inspectiontype
for each row 
begin     
	if inserting then 
		if :NEW.inspectiontypeid is null then
			SELECT inspectiontype_id_seq.nextval into :NEW.inspectiontypeid from dual;
		end if;
	end if; 
end;
/





CREATE TABLE quarter(
	quarterid		integer primary key,
	quartername		varchar(50),
	details 		clob
	);


CREATE TABLE fmicompliancetypes(
		fmicompliancetypeid	 integer primary key,
		fmicompliancetypename	varchar(50),
		details					clob
		);


CREATE TABLE FMICLIENTPHASES
   (	"FMICLIENTPHASEID" NUMBER(*,0), 
	"PERIODLICENSEID" NUMBER(*,0), 
	"FMITASKID" NUMBER(*,0), 
	"FMICOMPLIANCEPHASESID" NUMBER(*,0), 
	"SCHEDULEID" NUMBER(*,0), 
	"USERID" NUMBER(*,0), 
	"CLIENTAPPLEVEL" NUMBER(*,0), 
	"FMICLIENTPHASES" VARCHAR2(120 BYTE), 
	"CLIENTPHASENAME" VARCHAR2(120 BYTE), 
	"ESCALATIONTIME" NUMBER(*,0) DEFAULT 2 NOT NULL ENABLE, 
	"APPROVED" CHAR(1 BYTE) DEFAULT '0' NOT NULL ENABLE, 
	"REJECTED" CHAR(1 BYTE) DEFAULT '0' NOT NULL ENABLE, 
	"PENDING" CHAR(1 BYTE) DEFAULT '0' NOT NULL ENABLE, 
	"DEFFERED" CHAR(1 BYTE) DEFAULT '0' NOT NULL ENABLE, 
	"ACTIONDATE" TIMESTAMP (6), 
	"NARRATIVE" VARCHAR2(240 BYTE), 
	"PAID" CHAR(1 BYTE) DEFAULT '0' NOT NULL ENABLE, 
	"DETAILS" CLOB, 
	 PRIMARY KEY ("FMICLIENTPHASEID")
	);

CREATE SEQUENCE  "CCK"."FMICLIENTPHASE_ID_SEQ"  MINVALUE 1 MAXVALUE 999999999999999999999999999 INCREMENT BY 1 START WITH 550 CACHE 20 NOORDER  NOCYCLE ;
CREATE OR REPLACE TRIGGER tr_FMICLIENTPHASE_id BEFORE INSERT ON FMICLIENTPHASES
for each row 
begin     
	if inserting then 
		if :NEW.FMICLIENTPHASEID is null then
			SELECT FMICLIENTPHASE_id_seq.nextval into :NEW.FMICLIENTPHASEID from dual;
		end if;
	end if; 
end;
/

--sign off
CREATE TABLE complaint_interference(
	complaint_interferenceid		integer primary key,
	fmitaskid					integer references fmitasks,
	band						char(1) default '1',
	bandfrom					varchar(50),
	bandto						varchar(50),

	frequency					varchar(50),
	bandwidth					varchar(50),

	typeofdevice				varchar(50),
	location					varchar(50),
	suspectedsource				varchar(50),
	letterdate					date,
	interferencetiming			varchar(50),
	interferencedesc			clob
	);
CREATE SEQUENCE complaint_interference_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_complaint_interference_id BEFORE INSERT ON complaint_interference
for each row 
begin     
	if inserting then 
		if :NEW.complaint_interferenceid is null then
			SELECT complaint_interference_id_seq.nextval into :NEW.complaint_interferenceid from dual;
		end if;
	end if; 
end;
/



create or replace FUNCTION fsmstaffcount  RETURN integer IS
	myret int;
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	SELECT count(users.userid) into myret
	FROM users
	WHERE  rolename = 'FSM';
  COMMIT;
RETURN myret;
END;



CREATE OR REPLACE VIEW vwequipmentborrowing AS 
SELECT users.userid, users.username, users.fullname, users.rolename, equipinventoryid, equipmentname, equipmentmanufacturer, serialnumber, modelnumber, ('Equipment: ' ||equipmentname || '<br>Model Number: ' || modelnumber || '<br>Manufacturer: ' || equipmentmanufacturer || '<br>Serial Number: ' || serialnumber) as equipsummary, fsmstaffcount() as fsmstaff
FROM  users, equipinventory
WHERE ROLENAME = 'FSM' AND username not like 'dummy';



CREATE OR REPLACE VIEW vw_reassign_corr_action AS 
  SELECT users.userid, users.fullname, users.rolename,
	correspondenceaction.correspondenceid,	correspondenceaction.correspondenceactionid,
	('Ref No: ' || correspondence.cckreference || '<br>Subject : ' || correspondence.subject) as correspondencesummary,
	
	fsmstaffcount() as fsmstaff
	FROM  users, correspondence, correspondenceaction 
	WHERE correspondenceaction.correspondenceid = correspondence.correspondenceid
    AND correspondenceaction.iscleared = '0' 
    AND correspondence.dispatched = '0'
    AND correspondence.correspondencetypeid IS NOT NULL    
    AND (ROLENAME = 'FSM' OR ROLENAME = 'ENGINEER') 
    AND username not like 'dummy';


CREATE OR REPLACE VIEW vwfileborrowing AS 
	SELECT users.userid, users.username, users.fullname, users.rolename, correspondence.cckreference,
	correspondence.correspondenceid, correspondence.correspondencesource as clientname, correspondence.dfnumber, 
	('File: ' || correspondence.correspondencesource || '<br>DF Number: ' || correspondence.dfnumber) as filesummary,
	('Ref No: ' || correspondence.cckreference || '<br>Subject : ' || correspondence.subject) as correspondencesummary, 
	('<b>' || correspondence.cckreference || '<br>' || correspondence.correspondencesource || '<br><u>' || correspondence.subject || '</u></b>') as corrrespondencedetails,
	--correspondenceaction.correspondenceactionid,
	fsmstaffcount() as fsmstaff
	FROM  users, correspondence
  --, correspondenceaction
	WHERE ROLENAME = 'FSM' OR ROLENAME = 'ENGINEER' AND username not like 'dummy';




CREATE OR REPLACE VIEW vwcorrespondenceassignment AS 
	SELECT users.userid, users.username, users.fullname, users.rolename, 
	correspondence.correspondenceid, correspondence.correspondencesource as clientname, correspondence.dfnumber, 
	('File: ' || correspondence.correspondencesource || '<br>DF Number: ' || correspondence.dfnumber) as filesummary,
	('Ref No: ' || correspondence.cckreference || '<br>Subject : ' || correspondence.subject) as correspondencesummary,
	fsmstaffcount() as fsmstaff
	FROM  users, correspondence
	WHERE ROLENAME = 'FSM' OR ROLENAME = 'ENGINEER' AND username not like 'dummy'
	ORDER BY fullname;



CREATE OR REPLACE VIEW vwfileassignment AS 
	SELECT users.userid, users.username, users.fullname, users.rolename, 
	correspondence.correspondenceid, correspondence.correspondencesource as clientname, correspondence.dfnumber, 
	('File: ' || correspondence.correspondencesource || '<br>DF Number: ' || correspondence.dfnumber) as filesummary,
	('Ref No: ' || correspondence.cckreference || '<br>Subject : ' || correspondence.subject) as correspondencesummary,
	fsmstaffcount() as fsmstaff
	FROM  users, correspondence
	WHERE ROLENAME = 'FSM' OR ROLENAME = 'ENGINEER' AND username not like 'dummy'
   ORDER BY fullname;




CREATE OR REPLACE VIEW VWFMIASSIGNS AS 
SELECT vwgroupsubscriptions.userid, vwgroupsubscriptions.username, vwgroupsubscriptions.fullname, vwgroupsubscriptions.usergroupid, 
	vwgroupsubscriptions.usergroupname,vwgroupsubscriptions.groupsubscriptionid,
	fmistaffcount() as fmistaffcount,vwfmitasks.fmitaskid,vwfmitasks.complainantname,vwfmitasks.FmiCompliancetypename
FROM  vwgroupsubscriptions, vwfmitasks
WHERE  USERGROUPNAME = 'FMI';
 

create or replace FUNCTION  FMISTAFFCOUNT RETURN integer IS
	myret int;
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	SELECT count(vwgroupsubscriptions.GROUPSUBSCRIPTIONID) into myret
	FROM vwgroupsubscriptions
	WHERE  USERGROUPNAME = 'FMI';
  COMMIT;
RETURN myret;
END;

 

CREATE OR REPLACE VIEW VWFSMASSIGNS AS 
SELECT clientphases.clientphaseid, clientphases.clientphasename, users.fullname, users.userid, fsmstaffcount() as fsmstaffcount
FROM  users, clientphases
WHERE  users.rolename = 'ENGINEER'
ORDER BY users.fullname;





create or replace FUNCTION  FSMSTAFFCOUNT RETURN integer IS
	myret int;
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	SELECT count(users.userid) into myret
	FROM users
	WHERE  rolename = 'FSM' OR rolename = 'ENGINEER';
  COMMIT;
RETURN myret;
END;





CREATE OR REPLACE VIEW vwfmischedule AS
	SELECT fmischedule.fmischeduleid, fmischedule.fmischedulename, fmischedule.quarterid, fmitasks.fmitaskid,
	periods.periodid, periods.periodname, periods.isactive as isactiveperiod, quarter.quartername
	FROM fmitasks, fmischedule
	INNER JOIN periods ON fmischedule.periodid = periods.periodid
	INNER JOIN quarter ON fmischedule.quarterid = quarter.quarterid;



CREATE OR REPLACE VIEW vwmaintenanceschedule AS
	SELECT fmischedule.fmischeduleid, fmischedule.fmischedulename, quarter.quarterid, quarter.quartername, periods.startdate, periods.enddate, ('Period: ' || periods.startdate || ' To ' || periods.enddate) as periodsummary, maintenancetasks.maintenancetaskid
	FROM maintenancetasks, fmischedule
	inner join periods on fmischedule.periodid = periods.periodid
	inner join quarter on fmischedule.quarterid = quarter.quarterid;
	


CREATE OR REPLACE VIEW VWFMICLIENTPHASES AS
  SELECT fmiclientphases.fmiclientphaseid,fmiclientphases.periodlicenseid,fmiclientphases.fmitaskid, vwfmitasks.inspectiontypename,
		fmiclientphases.fmicompliancephasesid, decode(fmicompliancephases.phasename,'ofmi',decode(vwfmitasks.fullname,null,'Not Assigned',('Being addressed by <b>' || vwfmitasks.fullname || '</b>')),'mfmi','At FMI managers office','adfli','At ADs office','dfsm','at Directors desk','dgfmi','At DGs desk','Task Completed') as taskstatus, fmiclientphases.scheduleID,fmiclientphases.userid	AS approvedby,fmiclientphases.clientapplevel,
		fmiclientphases.fmiclientphases,fmiclientphases.clientphasename,fmiclientphases.escalationtime,fmiclientphases.approved,fmiclientphases.rejected,
		fmiclientphases.pending,fmiclientphases.deffered,fmiclientphases.actiondate,fmiclientphases.narrative, vwfmitasks.fullname as taskassignee,
		fmiclientphases.paid,fmiclientphases.details,vwfmitasks.forinspection,vwfmitasks.forinteference,vwfmitasks.formonitoring,
		vwfmitasks.FmiCompliancetypename, vwfmitasks.tasktype, vwfmitasks.assignto, users.userid, users.fullname, vwfmitasks.complainantname, vwfmitasks.updatedby,
		vwfmitasks.dateofentry,getcompliancePhaseLNA(fmiclientphases.fmitaskid, fmiclientphases.clientapplevel) AS compliancelna
	FROM fmiclientphases 
	INNER JOIN users ON users.userid = fmiclientphases.userid	
	INNER JOIN vwfmitasks ON vwfmitasks.fmitaskid = fmiclientphases.fmitaskid
	INNER JOIN fmicompliancephases ON fmiclientphases.fmicompliancephasesid = fmicompliancephases.fmicompliancephasesid;
 





CREATE TABLE fmischedule(
	fmischeduleid		integer primary key,
	periodid			varchar(12) references periods,	
	quarterid			integer references quarter,
	Userid				integer references Users,
	fmischedulename		varchar(50),

	startdate			date,
	enddate				date,
	
	iscomplete			char(1) default '0',
	ad_approved			char(1) default '0',	--AD
	d_approved			char(1) default '0',	--D/FSM
	dg_approved			char(1) default '0',	--DG

	participants		clob,						--participants
	regions				clob,						--participants	
	details				clob
);
CREATE SEQUENCE fmischedule_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_fmischedule_id BEFORE INSERT ON fmischedule
for each row 
begin     
	if inserting then 
		if :NEW.fmischeduleid is null then
			SELECT fmischedule_id_seq.nextval into :NEW.fmischeduleid from dual;
		end if;
	end if; 
end;
/


--original
CREATE OR REPLACE VIEW vwfmitasks2 AS
	  SELECT vwperiodlicenses.nonlicenserevenue,vwperiodlicenses.licenserevenue,vwperiodlicenses.annualgross,vwperiodlicenses.annualfeedue,
		vwperiodlicenses.actiondate,vwperiodlicenses.periodcompliant,vwperiodlicenses.annualreturns,vwperiodlicenses.quarterreturns,
		vwperiodlicenses.voided,vwperiodlicenses.qr1,vwperiodlicenses.qr2,vwperiodlicenses.qr3,vwperiodlicenses.qr4,vwperiodlicenses.ar,
		vwperiodlicenses.periodlicenseid,vwperiodlicenses.clientlicenseid,fmitasks.complainantname, fmitasks.requesturl, fmitasks.reporturl,
		vwperiodlicenses.activeperiod,vwperiodlicenses.clientid as complainant,fmitasks.fmischeduleid, fmitasks.inspectiontypeid,
		vwperiodlicenses.retcompliant,vwperiodlicenses.voiddate,vwperiodlicenses.periodid,vwperiodlicenses.periodname,
		vwperiodlicenses.licenseid,vwperiodlicenses.clientname,vwperiodlicenses.licensename,vwperiodlicenses.IsActive,
		vwperiodlicenses.forlcs,vwperiodlicenses.licenseabbrev,vwperiodlicenses.forfsm, fmischedule.fmischedulename,
		fmicompliancetypes.FmiCompliancetypename,fmicompliancetypes.FmicompliancetypeID,
		fmitasks.clientid as offender,fmitasks.ForInspection,fmitasks.ForInteference,fmitasks.ForMonitoring,fmitasks.dateofentry,
		fmitasks.violation,fmitasks.Details,fmitasks.Observations,fmitasks.fmitaskid,
		fmitasks.complaint,fmitasks.casenumber,fmitasks.Recommendation,fmitasks.assigndate,fmitasks.assignto,
    	users.username,users.fullname,fmitasks.raisedby
		FROM vwperiodlicenses INNER JOIN fmitasks ON fmitasks.periodlicenseid = vwperiodlicenses.periodlicenseid
		INNER JOIN 	fmicompliancetypes ON fmicompliancetypes.FmicompliancetypeID = fmitasks.FmicompliancetypeID
		LEFT JOIN fmischedule on fmitasks.fmischeduleid = fmischedule.fmischeduleid
		LEFT OUTER JOIN users ON users.userid = fmitasks.assignto;


CREATE OR REPLACE VIEW vwfmitasks AS
  SELECT fmitasks.fmitaskid, fmitasks.complainantname, fmitasks.requesturl, fmitasks.reporturl, inspectiontype.inspectiontypename,
		fmitasks.fmischeduleid, fmitasks.inspectiontypeid,
		fmischedule.fmischedulename, periods.periodid, periods.startdate, periods.enddate, quarter.quarterid, quarter.quartername,
		fmitasks.clientid,
		fmicompliancetypes.FmiCompliancetypename,fmicompliancetypes.FmicompliancetypeID,
		fmitasks.clientid as offender, fmitasks.ForInspection, fmitasks.ForInteference, fmitasks.ForMonitoring, decode(fmitasks.ForInspection,'1','INSPECTION',decode(fmitasks.ForInteference,'1','FREQUENCY INTERFERENCE',decode(fmitasks.ForMonitoring,'1','MONITORING','UNKNOWN'))) as tasktype, fmitasks.dateofentry,
		fmitasks.violation,fmitasks.Details,fmitasks.Observations,
		fmitasks.complaint,fmitasks.casenumber,fmitasks.Recommendation, fmitasks.assigndate, fmitasks.assignto,
    	users.username, users.fullname, fmitasks.raisedby, us.fullname as updatedby
		FROM  fmitasks 
		INNER JOIN 	fmicompliancetypes ON fmicompliancetypes.FmicompliancetypeID = fmitasks.FmicompliancetypeID
		LEFT JOIN fmischedule on fmitasks.fmischeduleid = fmischedule.fmischeduleid
		LEFT JOIN periods ON fmischedule.periodid = periods.periodid
		LEFT JOIN quarter ON fmischedule.quarterid = quarter.quarterid	
		LEFT JOIN users ON users.userid = fmitasks.assignto
		LEFT JOIN users us ON us.userid = fmitasks.userid
		LEFT JOIN clients ON fmitasks.clientid = clients.clientid
		LEFT JOIN inspectiontype ON fmitasks.inspectiontypeid = inspectiontype.inspectiontypeid;
		




CREATE TABLE monitoringtype(
		monitoringtypeid	 integer primary key,
		monitoringtypename	varchar(50),
		details					clob
		);


create table cckstationtype(
	cckstationtypeid		integer primary key,
	cckstationtypename		varchar(20),
	details					clob
	);



CREATE OR REPLACE VIEW vwmaintenanceassignments AS 
SELECT vwgroupsubscriptions.userid, vwgroupsubscriptions.username, vwgroupsubscriptions.fullname, vwgroupsubscriptions.usergroupid, 
	vwgroupsubscriptions.usergroupname,vwgroupsubscriptions.groupsubscriptionid,
	fmistaffcount () as fmistaffcount,maintenancetasks.maintenancetaskid, maintenancetasks.stationname
FROM  vwgroupsubscriptions, maintenancetasks
WHERE  USERGROUPNAME = 'FMI';



CREATE OR REPLACE VIEW vwmaintenancetasks AS 
SELECT ass.userid, ass.username, ass.fullname, ass.usergroupid, ass.usergroupname,ass.groupsubscriptionid, fmistaffcount() as fmistaffcount,
	maintenancetasks.maintenancetaskid, maintenancetasks.stationname, maintenancetasks.iscompleted, maintenancetasks.fmischeduleid,
	maintenancetasks.frequencyrange, fmischedule.fmischedulename
	FROM  maintenancetasks
	LEFT JOIN vwgroupsubscriptions ass ON maintenancetasks.assignedto = ass.userid
	LEFT JOIN fmischedule ON maintenancetasks.fmischeduleid = fmischedule.fmischeduleid;




--FILE CIRCULATION, DISPATCH, ETC
CREATE TABLE registertype(
	registertypeid		integer primary key,
	registertypename	varchar(50),	
	details				  clob
	);

--internal, external, memo, circular
CREATE TABLE correspondencetype(
	correspondencetypeid	integer primary key,
	correspondencetype		varchar(50),	
	details				  	clob
	);

CREATE TABLE department(
	departmentid		integer primary key,
	departmentname		varchar(50),	
	details				clob
	);



CREATE OR REPLACE FORCE VIEW VWFILEINVENTORY AS 
	SELECT correspondence.correspondenceid, correspondence.correspondencetypeid, upper(correspondence.correspondencesource) as clientname, correspondence.dfnumber, correspondence.isavailable, getFileStatus(correspondence.correspondenceid) as filestatus
	FROM correspondence;		



CREATE OR REPLACE FUNCTION getFileStatus(correspondence_id in integer) RETURN varchar IS
PRAGMA AUTONOMOUS_TRANSACTION;
	myret varchar(500);	
BEGIN	
	SELECT coalesce(decode(correspondence.isavailable,'0',('Borrowed by <b>' || borrower.fullname || '</b> on ' || filetracking.borrowdate ),'Available'),'') INTO myret
	FROM correspondence
	LEFT JOIN filetracking ON correspondence.correspondenceid = filetracking.correspondenceid
	LEFT JOIN users borrower ON filetracking.borrowerid = borrower.userid
	WHERE correspondence.correspondencetypeid is null AND correspondence.correspondenceid = correspondence_id;
  
  return myret;
END;
/




CREATE OR REPLACE VIEW VWCORRESPONDENCE AS 
  SELECT correspondence.correspondenceid, 
  decode(correspondence.iscompleted,'1',('<font color="green">' || correspondence.subject || '</font>'),('<font color="black">' || correspondence.subject || '</font>')) as formattedsubj,  
	correspondence.cckreference, correspondence.letterref, correspondence.receivedate, cast(to_char(correspondence.receivedate,'MM') as integer) as monthreceived, 
	cast(to_char(correspondence.receivedate,'YYYY') as integer) as yearreceived,  correspondence.dfnumber, correspondencetype.correspondencetypeid, correspondencetype.correspondencetype,
	coalesce(correspondence.correspondencesource,('From: ' || coalesce(correspondence.fromdepartment,fromdept.departmentname) || ' To: ' || coalesce(correspondence.todepartment,todept.departmentname))) as correspondencesource, correspondence.subject,
	receiver.userid as recieverid,receiver.fullname as recievername, borrower.userid as borrowerid, correspondence.lastborroweddate as borrowdate, borrower.fullname as borrowername, fromdept.departmentname as fromdepartment, 
	todept.departmentname as todepartment, actor.userid as actorid, actor.fullname as actorname, us.userid, us.rolename, Correspondence.actiondate,
	Correspondence.Petitioner_ID, cla.clientname as Petitioner_Name, Correspondence.Respondent_ID, clb.clientname as Respondent_Name, correspondence.correspondencesource as clientname,
	Correspondence.Details, Correspondence.Closed, Correspondence.close_date, Correspondence.DISPATCHDATE, Correspondence.dispatched, correspondence.isavailable,
	correspondence.iscompleted,	decode(Correspondence.dispatched,'1','Completed','Outstanding') as status
	FROM correspondence
	INNER JOIN correspondencetype ON correspondence.correspondencetypeid = correspondencetype.correspondencetypeid
	LEFT JOIN department fromdept ON fromdept.departmentid = correspondence.fromdepartmentid
	LEFT JOIN department todept ON todept.departmentid = correspondence.todepartmentid
	LEFT JOIN users receiver ON receiver.userid = correspondence.receiverid
	LEFT JOIN users borrower ON borrower.userid = correspondence.fileborrowerid
	LEFT JOIN users actor ON actor.userid = correspondence.actorid
	LEFT JOIN users us ON us.userid = correspondence.userid
	LEFT JOIN clients cla ON cla.clientid = Correspondence.Petitioner_ID
	LEFT JOIN clients clb ON clb.clientid = Correspondence.Respondent_ID;



--registry entry includes file borrowing
--internal correspondence is identified by the values inside fromdepartmentid and todepartmentid
CREATE TABLE correspondence(
	correspondenceid		integer primary key,
	registertypeid			integer references registertype,
	correspondencetypeid	integer references correspondencetype,
			
	fromdepartmentid			integer		references department,		-- internal source of correspondence
	todepartmentid			integer		references department,		-- internal source of correspondence
	--licenseeid				integer references 

	--stop gap
	fromdepartment			varchar(50),
	todepartment			varchar(50),
	--end stop gap


	dfnumber				varchar(50),					--used in file circulation
	fileborrowerid			integer references users,		--used in file circulation
	lastborroweddate		date default sysdate not null,
	isavailable				char(1) default '1',			--file returned and available for borrowing	

	correspondencesource	varchar(50),					--correspondece -> source of the letter, filecirculation -> clientname
	letterref				varchar(50),
	cckreference			varchar(50),				
	subject					varchar(100),				

	receiverid			integer references users,		--secretary
	receivedate			timestamp default sysdate, 		

	actiondate			date default sysdate,

	actorid			integer references users,		--user to act on this correspondence
	lastactorid			integer references users,		--used in file circulation
	lastforwarddate		date default sysdate not null,

-- 	dispatcherid		integer references users,		--typically the secretary
-- 	dispatchdate		date,
-- 	dispatchedto		varchar(100),
-- 	dispatchmode		varchar(50),			--posted, H/Del, etc
	dispatched 			char(1) default '0',
	iscompleted			char(1) default '0',	--does not mean dispatched. it means that all people that were to act on it hav done so
	userid				integer references users,	
	
	PETITIONER_ID		integer,	--references clients
	RESPONDENT_ID		integer,	--references clients

	details				clob
	);
CREATE SEQUENCE correspondenceid_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;

CREATE INDEX correspondence_registertypeid ON correspondence (registertypeid);
CREATE INDEX correspondence_corrtypeid ON correspondence (correspondencetypeid);
CREATE INDEX correspondence_fromdeptid ON correspondence (fromdepartmentid);
CREATE INDEX correspondence_todepartmentid ON correspondence (todepartmentid);
CREATE INDEX correspondence_fileborrowerid ON correspondence (fileborrowerid);
CREATE INDEX correspondence_receiverid ON correspondence (receiverid);
CREATE INDEX correspondence_actorid ON correspondence (actorid);
CREATE INDEX correspondence_lastactorid ON correspondence (lastactorid);
CREATE INDEX correspondence_userid ON correspondence (userid);



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


CREATE OR REPLACE VIEW vwdispatch AS
	SELECT dispatch.dispatchid, dispatch.dispatcherid, dispatch.dispatchdate, dispatch.actiondate, dispatch.dispatchedto, dsp.fullname as dispatchinguser,
	dispatch.dispatchmode, dispatch.userid, dispatch.clientname, dispatch.letterref, dispatch.subject, cast(to_char(dispatch.actiondate,'MM') as integer) as monthsent, cast(to_char(dispatch.actiondate,'YYYY') as integer) as yearsent,
	(UPPER(COALESCE(dispatch.clientname, dispatch.dispatchedto))) as dispatchsummary,
	(to_char(dispatch.actiondate,'YYYY') || ' ' || to_char(dispatch.actiondate,'Mon')) as whensent,

	dispatch.details, correspondence.correspondenceid, correspondence.cckreference
	FROM dispatch
	LEFT JOIN correspondence ON dispatch.correspondenceid = correspondence.correspondenceid
	LEFT JOIN users dsp on dispatch.dispatcherid = dsp.userid;


--correspondence dispatch
CREATE TABLE dispatch(
	dispatchid			integer primary key,
	dispatcherid		integer references users,		--typically the secretary
	correspondenceid	integer references correspondence,
	dispatchdate		date,							--date according the the dispatherid ie logged in user
	actiondate			date default sysdate,			--actual date of dispath according to the SYSTEM
	dispatchedto		varchar(1000),
	dispatchmode		varchar(500),			--posted, H/Del, etc
	userid				integer references users,		--logs the last user to update it

	--outgoing correspondence
	--clientid			integer
	clientname			varchar(100),
	letterref			varchar(50),
	subject				varchar(100),

	details				clob
	);
CREATE SEQUENCE dispatchid_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_dispatch_id BEFORE INSERT ON dispatch
for each row 
begin     
	if inserting then 
		if :NEW.dispatchid is null then
			SELECT dispatchid_seq.nextval into :NEW.dispatchid from dual;
		end if;
	end if; 
end;
/




CREATE TABLE notificationtype (
	notificationtypeid		integer primary key,
	notificationtypename	varchar2(150),
	details				clob
	);
CREATE SEQUENCE notificationtype_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_notificationtype_id BEFORE INSERT ON notificationtype
for each row 
begin     
	if inserting then 
		if :NEW.notificationtypeid is null then
			SELECT notificationtype_id_seq.nextval into :NEW.notificationtypeid from dual;
		end if;
	end if; 
end;
/


CREATE OR REPLACE VIEW vwintcorrespondence AS
	SELECT intcorrespondenceid, identificationnumber, fromcountryid, tocountryid, titlefieldtext, notificationtype.notificationtypeid, notificationtype.notificationtypename, coalesce(toc.countryname,fromc.countryname) as foreigncountry,
	('<a href="' || parentspacelink || '" target="_blank">Internation Coordination') as  parentspacelink, receiveddate, actiondate, userid, iscleared, intcorrespondence.details
	FROM intcorrespondence
	INNER JOIN notificationtype ON intcorrespondence.notificationtypeid = notificationtype.notificationtypeid
	LEFT JOIN countrys toc ON intcorrespondence.tocountryid = toc.countryid
	LEFT JOIN countrys fromc ON intcorrespondence.fromcountryid = fromc.countryid;




--international correspondence : for coordination and notification
CREATE TABLE intcorrespondence(
	intcorrespondenceid	  integer primary key,	
	notificationtypeid				integer references notificationtype,	--????
	identificationnumber			varchar(50),		--number to identify this notification. source of this info is FP

	fromcountryid			char(2) references countrys,
	tocountryid				char(2) references countrys,

	--stationid				integer references analysedstationid,	--a superficial station whose details come in a letter or email and cant be created using our normal application process
		
	parentspacelink				varchar(500) default 'http://intranet.cck.go.ke/alfresco/n/browse/workspace/SpacesStore/0f6f6270-6b14-4262-97bf-1584925f1101',		--link to the dms int'l coordination space
	spacelink				varchar(500), --link to the specific space	
	titlefieldtext			varchar(50),	

	receiveddate			date,
	actiondate				date default sysdate,
	userid					integer references users,

	iscleared				char(1) default '0',
	
	details					clob
	);
CREATE SEQUENCE intcorrespondenceid_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_intcorrespondence_id BEFORE INSERT ON intcorrespondence
for each row 
begin     
	if inserting then 
		if :NEW.intcorrespondenceid  is null then
			SELECT intcorrespondenceid_seq.nextval into :NEW.intcorrespondenceid  from dual;
		end if;	
		
		if :new.notificationtypeid = 2 then		--if incoming (default is outgoing)
			:new.fromcountryid := :new.tocountryid;	--update originating country
			:new.tocountryid := 'KE';
		end if;
	end if; 
end;
/


CREATE TABLE intdispatch(
	intdispatchid			integer primary key,
	dispatcherid		integer references users,		--typically the secretary
	intcorrespondenceid	integer references intcorrespondence,
	dispatchdate		date,							--date according the the dispatherid ie logged in user
	actiondate			date default sysdate,			--actual date of dispath according to the SYSTEM
	dispatchedto		varchar(1000),
	dispatchmode		varchar(500),			--posted, H/Del, etc
	userid				integer references users,		--logs the last user to update it
	details				clob
	);
CREATE SEQUENCE intdispatchid_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_intdispatch_id BEFORE INSERT ON intdispatch
for each row 
begin     
	if inserting then 
		if :NEW.intdispatchid is null then
			SELECT intdispatchid_seq.nextval into :NEW.intdispatchid from dual;
		end if;
	end if; 
end;
/



--used to store file borrowing history
CREATE TABLE filetracking (
	filetrackingid   integer primary key,
	correspondenceid	integer references correspondence,		--correspondence table stores files also
	userid				integer references users,				--logged in user (we want to know if the borrower is the one who logged in to return the file)
	borrowdate			date default sysdate,
	returndate			date,
	borrowerid			integer references users,
	filestatus			clob,						--status at borrowing
	isborrowed			char(1) default '1',
	isforwarded			char(1) default '0',		--wether or not this has been forwarded
	filecondition		clob,
	details				clob
	
	);
CREATE SEQUENCE filetracking_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 2;
CREATE OR REPLACE TRIGGER tr_filetracking_id BEFORE INSERT ON filetracking
for each row 
begin     
	if inserting then 
		if :NEW.filetrackingid  is null then
			SELECT filetracking_id_seq.nextval into :NEW.filetrackingid  from dual;
		end if;

		update correspondence set isavailable = '0' where correspondenceid = :new.correspondenceid;
		
	end if; 
end;
/



--this trigger marks the file as returned (To Cabinet) as long as details field us updated with data
--this prevents the need for a separate function to update the correspondence (aka file) availability
CREATE OR REPLACE TRIGGER tr_filetracking_update BEFORE UPDATE ON filetracking
for each row 
begin     
	if updating then 				
		--if details at return is non empty it means that the user has (or just about to) returned it
		IF :NEW.details is not null THEN
			:NEW.returndate := sysdate;
			--:NEW.isborrowed := '0';		
			update correspondence set isavailable = '1' where correspondenceid = :new.correspondenceid;
		END IF;
	end if; 
end;
/




create or replace FUNCTION borrowequipment(user_id IN varchar2, system_user IN varchar2,approval IN varchar2,resource_id IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	BEGIN
	
	IF approval='Equipment' THEN
	  INSERT INTO EQUIPTRACKING(equipinventoryid,borrowdate,borrowerid,isborrowed)
			VALUES(cast(resource_id as int),sysdate,cast(user_id as int),'1');
			COMMIT;
	UPDATE equipinventory set LOANEDOUT = '1' 
		WHERE equipinventoryid = cast(resource_id as int);
		COMMIT;

	  RETURN 'Equipment Borrowing Process Successful';
	END IF;

	IF approval='File' THEN
	--we need to change something here...the logged in user will not be the borrower, the borrower will be the person forwarded to
	  INSERT INTO filetracking(correspondenceid,borrowdate,borrowerid,isborrowed)
		VALUES(cast(resource_id as int),sysdate,cast(user_id as int),'1');
		COMMIT;
	  UPDATE correspondence set isavailable = '0', fileborrowerid = cast(user_id as int), lastborroweddate = sysdate
		WHERE correspondenceid = cast(resource_id as int);
		COMMIT;
	  RETURN 'File Borrowing Process Successful';
	END IF;

	IF approval='Forward' THEN
	
	--we need to record that we have forwarded this correspondence
	UPDATE filetracking SET isforwarded = '1' WHERE filetrackingid = 
		(SELECT max(filetrackingid) FROM filetracking WHERE isforwarded = '0' AND correspondenceid=cast(resource_id as int));
		COMMIT;
	INSERT INTO filetracking(correspondenceid,borrowdate,borrowerid,userid,isborrowed)
		VALUES(cast(resource_id as int),sysdate,cast(user_id as int),cast(system_user as int),'1');
		COMMIT;
	  UPDATE correspondence set isavailable = '0', fileborrowerid = cast(user_id as int), lastborroweddate = sysdate
		WHERE correspondenceid = cast(resource_id as int);
		COMMIT;
	  RETURN 'File Borrowing Process Successful';
	END IF;

END;
/




--Arguments: 1=cell value, 2=logged in user, 3=approvals, 4=filterid if any
CREATE OR REPLACE FUNCTION addactor(actor_id IN varchar2, user_id IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	BEGIN
	
	IF approval='Actor' THEN		--correspondence Actor 
		--mark the previous as cleared
		UPDATE correspondenceaction SET iscleared = '1' 
				WHERE correspondenceactionid = (
						SELECT MAX(correspondenceactionid) FROM correspondenceaction WHERE correspondenceid = cast(filter_id as int)
						);
		COMMIT;
		--insert a new action for the intended user
		INSERT INTO correspondenceaction(correspondenceid,actorid,forwardeddate,escalatedby,userid)
			VALUES(cast(filter_id as int),cast(actor_id as int), sysdate, cast(user_id as int), cast(user_id as int));
		COMMIT;
		--update original correspondence with the last actor
		UPDATE correspondence set lastactorid = cast(user_id as int), lastforwarddate = sysdate
			WHERE correspondenceid = cast(filter_id as int);
		COMMIT;	
		RETURN 'Correspondence Forwarded Successfully';

	ELSIF approval='ReAssign' THEN	--here we record the person who reassigned his work to someone else
		UPDATE correspondenceaction SET actorid = cast(actor_id as int), escalatedby = cast(user_id as int), escalationdate = sysdate
			WHERE correspondenceactionid = cast(filter_id as int);
		COMMIT;
		RETURN 'Action Re Assigned Successfully';
	END IF;

END;
/





CREATE OR REPLACE FUNCTION issuefile(borrower_id IN varchar2, user_id IN varchar2, approval IN varchar2, corr_id IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	BEGIN
	
	IF approval='Issue' THEN
	  INSERT INTO filetracking(correspondenceid,borrowdate,borrowerid,isborrowed)
		VALUES(cast(corr_id as int),sysdate,cast(borrower_id as int),'1');
		COMMIT;
	
	  UPDATE correspondence set isavailable = '0', fileborrowerid = cast(borrower_id as int), lastborroweddate = sysdate
		WHERE correspondenceid = cast(corr_id as int);
		COMMIT;

	  RETURN 'File ' || corr_id ||' successfuly issued to user ' || borrower_id;
	END IF;

END;
/





CREATE OR REPLACE FUNCTION skipclc(cli_lic_id IN varchar2, user_id IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	BEGIN
	
	IF approval='Select' THEN	
		UPDATE clientlicenses set skipclc = '1' where clientlicenseid = cast(cli_lic_id as int);
		COMMIT;

		UPDATE clientphases SET approved = '1', rejected = '0', deffered = '0', pending = '0', Withdrawn = '0', actiondate = sysdate, userid = CAST(user_id as int)
			WHERE clientlicenseid = cast(cli_lic_id as int) AND clientphasename = 'clc';
		COMMIT;		

		RETURN 'Application Exempted from CLC';
	END IF;

END;
/


--used to reinstate suspended/terminated/cancelled licenses. 
CREATE OR REPLACE FUNCTION reinstatelicense(cli_lic_id IN varchar2, user_id IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN VARCHAR2 IS
	
	--DECLARE
  PRAGMA AUTONOMOUS_TRANSACTION;

	CURSOR clientlicense_cur IS
	SELECT clientlicenseid, clientid, licenseid			
	FROM clientlicenses 		
	WHERE clientlicenseid = cli_lic_id;
	rec_clientlicenses clientlicense_cur%ROWTYPE;

	new_cli_lic_id int;		
  new_vhf_net_id int;	
	new_remark varchar(500);
  
  countbases_hf     int;
  countbases_vhf     int;
  countmobiles_hf   int;
  countmobiles_vhf   int;
  countportables_hf     int;
  countportables_vhf     int;

BEGIN     
	
	OPEN clientlicense_cur;
	FETCH clientlicense_cur INTO rec_clientlicenses;
  
  countbases_hf  := 0;
  countbases_vhf := 0;
  countmobiles_hf := 0;
  countmobiles_vhf   := 0;
  countportables_hf     := 0;
  countportables_vhf     := 0;

	--fetch the new/next clientlicenseid for use in the next insert (this is a convenience application and may not result into a new licenses)
	SELECT clientlicenses_id_seq.nextval INTO new_cli_lic_id FROM dual;

	if approval = 'Re-Instate' then 				
		--we want the network to reflect the task at hand
		new_remark := 'Re-instatement of Cancelled|Suspended|Terminated License of ID: ' || rec_clientlicenses.clientlicenseid;
				
		--make a new application (with reference to original/parent application/license) which will end in a new license
		INSERT INTO clientlicenses (clientlicenseid, parentclientlicenseid, clientid, licenseid, remarks, applicationdate, islicensereinstatement) 
				VALUES (new_cli_lic_id, rec_clientlicenses.clientlicenseid, rec_clientlicenses.clientid, rec_clientlicenses.licenseid, new_remark, SYSDATE,'1');			
        COMMIT;
        
		--COPY ALL EXISTING NETWORKS (+ stations from suspended/cancelled/terminated license)
		FOR mynet IN (select vhfnetworkid, vhfnetworkname, vhfnetworklocation, clientlicenseid from vhfnetwork where clientlicenseid = cli_lic_id) LOOP

      SELECT VHFnetwork_id_seq.nextval INTO new_vhf_net_id FROM dual;
      
			INSERT INTO vhfnetwork (vhfnetworkid, vhfnetworkname, vhfnetworklocation, clientlicenseid, userid, remark)
				VALUES (new_vhf_net_id,mynet.vhfnetworkname, mynet.vhfnetworklocation, new_cli_lic_id, cast(user_id as int), 'Copied as part of the License re-instatement process');
				COMMIT;

				--FOR mystation IN (select stationid,stationname,licensepriceid,servicenatureid,vhfnetworkid,clientlicenseid,transmitstationid,siteid,radiobroadcastingtypeid,istransmitter,
				--				decommissiondate,numberofreceivers,requestedfrequencybands,numberoffrequencies,requestedfrequency,requestedfrequencyGHz,requestedbandwidth,
				--				requestedbandwidthMHz,requestedbandwidthGHz,NOMINALTXPOWER,EFFECTIVETXPOWER,unitsrequested,unitsapproved,stationcallsign,isaircraft,location,
				--				max_operation_hours,AIRCRAFTNAME,AIRCRAFTTYPE,AIRCRAFTREGNO,VESSELTYPEID,VESSELNAME,IMONumber,GROSSTONNAGE,DECODERCAPACITY,vehicleregistration FROM stations where vhfnetworkid = mynet.vhfnetworkid) LOOP

				--FOR ALL STATIONS in each Network (am not considering terrestrial and others)
				FOR mystation IN (select * from stations where vhfnetworkid = mynet.vhfnetworkid) LOOP
          
             
          IF(mystation.licensepriceid = 4) THEN --Base VHF/UHF
            countbases_vhf := countbases_vhf + 1;          
          ELSIF(mystation.licensepriceid = 5) THEN--Base MF/HF
            countbases_hf := countbases_hf + 1;
          
          
          ELSIF(mystation.licensepriceid = 6) THEN--Mobile VHF/UHF
            countmobiles_vhf := countmobiles_vhf + 1;                      
          ELSIF(mystation.licensepriceid = 2) THEN--Mobile MF/HF
            countmobiles_hf := countmobiles_hf + 1;
          
          
          ELSIF(mystation.licensepriceid = 1) THEN--Portable VHF/UHF
            countportables_vhf := countportables_vhf + 1;          
          ELSIF(mystation.licensepriceid = 3) THEN--Portable MF/HF
            countportables_hf := countportables_hf + 1;
            
          END IF;  
          

					INSERT INTO stations(stationname,licensepriceid,servicenatureid,vhfnetworkid,clientlicenseid,transmitstationid,siteid,radiobroadcastingtypeid,istransmitter,
								decommissiondate,numberofreceivers,requestedfrequencybands,numberoffrequencies,requestedfrequency,requestedfrequencyGHz,requestedbandwidth,
								requestedbandwidthMHz,requestedbandwidthGHz,NOMINALTXPOWER,EFFECTIVETXPOWER,unitsrequested,unitsapproved,stationcallsign,isaircraft,location,
								max_operation_hours,AIRCRAFTNAME,AIRCRAFTTYPE,AIRCRAFTREGNO,VESSELTYPEID,VESSELNAME,IMONumber,GROSSTONNAGE,DECODERCAPACITY,vehicleregistration, remarks)

						VALUES(mystation.stationname,mystation.licensepriceid,mystation.servicenatureid,new_vhf_net_id,new_cli_lic_id,mystation.transmitstationid,mystation.siteid,mystation.radiobroadcastingtypeid,mystation.istransmitter,
								mystation.decommissiondate,mystation.numberofreceivers,mystation.requestedfrequencybands,mystation.numberoffrequencies,mystation.requestedfrequency,mystation.requestedfrequencyGHz,mystation.requestedbandwidth,
								mystation.requestedbandwidthMHz,mystation.requestedbandwidthGHz,mystation.NOMINALTXPOWER,mystation.EFFECTIVETXPOWER,mystation.unitsrequested,mystation.unitsapproved,mystation.stationcallsign,mystation.isaircraft,mystation.location,
								mystation.max_operation_hours,mystation.AIRCRAFTNAME,mystation.AIRCRAFTTYPE,mystation.AIRCRAFTREGNO,mystation.VESSELTYPEID,mystation.VESSELNAME,mystation.IMONumber,mystation.GROSSTONNAGE,mystation.DECODERCAPACITY,mystation.vehicleregistration,'Copy of station id:' || mystation.stationid);
					COMMIT;
				
				END LOOP;

        --CLIENTSTATIONS        
        IF(countbases_vhf > 0) THEN
          --BASE vhf
          INSERT INTO clientstations(vhfnetworkid,licensepriceid,numberoffrequencies, numberofrequestedstations, isdummy)
              VALUES(new_vhf_net_id, 4, 0, countbases_vhf,'1'); 
          COMMIT;    
        ELSIF(countbases_hf > 0) THEN
          --base hf
          INSERT INTO clientstations(vhfnetworkid,licensepriceid,numberoffrequencies, numberofrequestedstations, isdummy)
              VALUES(new_vhf_net_id, 5, 0, countbases_hf,'1');  
          COMMIT;    
        ELSIF(countmobiles_vhf > 0) THEN
          --MOBILE VHF
          INSERT INTO clientstations(vhfnetworkid,licensepriceid,numberoffrequencies, numberofrequestedstations, isdummy)
              VALUES(new_vhf_net_id, 6, 0, countmobiles_vhf,'1');  
          COMMIT;    
        ELSIF(countmobiles_hf > 0) THEN
          --MOBILE HF
          INSERT INTO clientstations(vhfnetworkid,licensepriceid,numberoffrequencies, numberofrequestedstations, isdummy)
              VALUES(new_vhf_net_id, 2, 0, countmobiles_hf,'1');  
          COMMIT;    
        ELSIF(countportables_vhf > 0) THEN
          --PORTABL VHF
          INSERT INTO clientstations(vhfnetworkid,licensepriceid,numberoffrequencies, numberofrequestedstations, isdummy)
              VALUES(new_vhf_net_id, 1, 0, countportables_vhf,'1');  
          COMMIT;    
        ELSIF(countportables_hf > 0) THEN
          --PORTABLE HF
          INSERT INTO clientstations(vhfnetworkid,licensepriceid,numberoffrequencies, numberofrequestedstations, isdummy)
              VALUES(new_vhf_net_id, 3, 0, countportables_hf,'1');  
          COMMIT;    
       END IF;       
                
        
		END LOOP;

		--advance application to clc stage (and let the manager decide wether it skips CLC or not)
		--A. CLEAR CHECKLISTS at receiving and checking (another solution is to copy the clientphase and clientchecklist data for related clientlienseid)
		--a. identify corresponding clientphases
		FOR phaserec IN (select * from clientphases inner join phases on clientphases.phaseid=phases.phaseid where clientlicenseid = new_cli_lic_id and phases.phaselevel <= 2) LOOP
			
			--b. identify corresponding clientchecklists
			FOR checkrec IN (select * from clientchecklists where clientphaseid = phaserec.clientphaseid) LOOP
					--clear checklist
					UPDATE clientchecklists SET approved = '1', rejected = '0', actiondate = SYSDATE, userid = CAST(user_id as int)
						WHERE clientchecklistid = checkrec.clientchecklistid;	
					COMMIT;

			END LOOP;
			
			--approve the phase after clearing all the checklists
			UPDATE clientphases SET approved = '1', rejected = '0', pending = '0', isdone='1', actiondate = sysdate, userid =  CAST(user_id as int)
        WHERE clientphaseid = phaserec.clientphaseid;
      COMMIT;
									
		END LOOP;
		--END IF;
	end if; --if approval = reinstate
	
  UPDATE licenseviolations set ISREINSTATED='1', reinstateddate = sysdate WHERE clientlicenseid = cli_lic_id;
  COMMIT;
  
  CLOSE clientlicense_cur;    
		
	RETURN 'Reinstatement Successful';

END;
/


--TEST. TO INCLUDE THE NUMBER OF FREQUENCIES
CREATE OR REPLACE FUNCTION reinstatelicense(cli_lic_id IN varchar2, user_id IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN VARCHAR2 IS
	
	--DECLARE
  PRAGMA AUTONOMOUS_TRANSACTION;

	CURSOR clientlicense_cur IS
	SELECT clientlicenseid, clientid, licenseid			
	FROM clientlicenses 		
	WHERE clientlicenseid = cli_lic_id;
	rec_clientlicenses clientlicense_cur%ROWTYPE;

	new_cli_lic_id int;		
  new_vhf_net_id int;	
	new_remark varchar(500);
  
  countbases_hf     int; freq_base_hf int;
  countbases_vhf     int; freq_base_vhf int;
  countmobiles_hf   int;  freq_mobile_hf int;
  countmobiles_vhf   int; freq_mobile_vhf int;
  countportables_hf     int;  freq_portable_hf int;
  countportables_vhf     int; freq_portable_vhf int;

BEGIN     
	
	OPEN clientlicense_cur;
	FETCH clientlicense_cur INTO rec_clientlicenses;
  
  countbases_hf  := 0;
  countbases_vhf := 0;
  countmobiles_hf := 0;
  countmobiles_vhf   := 0;
  countportables_hf     := 0;
  countportables_vhf     := 0;
  
  freq_base_hf  := 0;
  freq_base_vhf := 0;
  freq_mobile_hf  := 0;
  freq_mobile_vhf := 0;
  freq_portable_hf  := 0;
  freq_portable_vhf := 0;
  

	--fetch the new/next clientlicenseid for use in the next insert (this is a convenience application and may not result into a new licenses)
	SELECT clientlicenses_id_seq.nextval INTO new_cli_lic_id FROM dual;

	if approval = 'Re-Instate' then 				
		--we want the network to reflect the task at hand
		new_remark := 'Re-instatement of Cancelled|Suspended|Terminated License of ID: ' || rec_clientlicenses.clientlicenseid;
				
		--make a new application (with reference to original/parent application/license) which will end in a new license
		INSERT INTO clientlicenses (clientlicenseid, parentclientlicenseid, clientid, licenseid, remarks, applicationdate, islicensereinstatement) 
				VALUES (new_cli_lic_id, rec_clientlicenses.clientlicenseid, rec_clientlicenses.clientid, rec_clientlicenses.licenseid, new_remark, SYSDATE,'1');			
        COMMIT;
        
		--COPY ALL EXISTING NETWORKS (+ stations from suspended/cancelled/terminated license)
		FOR mynet IN (select vhfnetworkid, vhfnetworkname, vhfnetworklocation, clientlicenseid from vhfnetwork where clientlicenseid = cli_lic_id) LOOP

      SELECT VHFnetwork_id_seq.nextval INTO new_vhf_net_id FROM dual;
      
			INSERT INTO vhfnetwork (vhfnetworkid, vhfnetworkname, vhfnetworklocation, clientlicenseid, userid, remark)
				VALUES (new_vhf_net_id,mynet.vhfnetworkname, mynet.vhfnetworklocation, new_cli_lic_id, cast(user_id as int), 'Copied as part of the License re-instatement process');
				COMMIT;

				--FOR mystation IN (select stationid,stationname,licensepriceid,servicenatureid,vhfnetworkid,clientlicenseid,transmitstationid,siteid,radiobroadcastingtypeid,istransmitter,
				--				decommissiondate,numberofreceivers,requestedfrequencybands,numberoffrequencies,requestedfrequency,requestedfrequencyGHz,requestedbandwidth,
				--				requestedbandwidthMHz,requestedbandwidthGHz,NOMINALTXPOWER,EFFECTIVETXPOWER,unitsrequested,unitsapproved,stationcallsign,isaircraft,location,
				--				max_operation_hours,AIRCRAFTNAME,AIRCRAFTTYPE,AIRCRAFTREGNO,VESSELTYPEID,VESSELNAME,IMONumber,GROSSTONNAGE,DECODERCAPACITY,vehicleregistration FROM stations where vhfnetworkid = mynet.vhfnetworkid) LOOP

				--FOR ALL STATIONS in each Network (am not considering terrestrial and others)
				FOR mystation IN (select * from stations where vhfnetworkid = mynet.vhfnetworkid) LOOP
          
             
          IF(mystation.licensepriceid = 4) THEN --Base VHF/UHF
            countbases_vhf := countbases_vhf + 1;  
            freq_base_vhf := mystation.numberoffrequencies;
          ELSIF(mystation.licensepriceid = 5) THEN--Base MF/HF            
            countbases_hf := countbases_hf + 1;
            freq_base_hf := mystation.numberoffrequencies;
          
          
          ELSIF(mystation.licensepriceid = 6) THEN--Mobile VHF/UHF
            countmobiles_vhf := countmobiles_vhf + 1;                      
            freq_mobile_vhf := mystation.numberoffrequencies;
          ELSIF(mystation.licensepriceid = 2) THEN--Mobile MF/HF
            countmobiles_hf := countmobiles_hf + 1;
            freq_mobile_hf := mystation.numberoffrequencies; 
          
          
          ELSIF(mystation.licensepriceid = 1) THEN--Portable VHF/UHF
            countportables_vhf := countportables_vhf + 1;          
            freq_portable_vhf := mystation.numberoffrequencies; 
          ELSIF(mystation.licensepriceid = 3) THEN--Portable MF/HF
            countportables_hf := countportables_hf + 1;
            freq_portable_hf := mystation.numberoffrequencies; 
            
          END IF;  
          

					INSERT INTO stations(stationname,licensepriceid,servicenatureid,vhfnetworkid,clientlicenseid,transmitstationid,siteid,radiobroadcastingtypeid,istransmitter,
								decommissiondate,numberofreceivers,requestedfrequencybands,numberoffrequencies,requestedfrequency,requestedfrequencyGHz,requestedbandwidth,
								requestedbandwidthMHz,requestedbandwidthGHz,NOMINALTXPOWER,EFFECTIVETXPOWER,unitsrequested,unitsapproved,stationcallsign,isaircraft,location,
								max_operation_hours,AIRCRAFTNAME,AIRCRAFTTYPE,AIRCRAFTREGNO,VESSELTYPEID,VESSELNAME,IMONumber,GROSSTONNAGE,DECODERCAPACITY,vehicleregistration, remarks)

						VALUES(mystation.stationname,mystation.licensepriceid,mystation.servicenatureid,new_vhf_net_id,new_cli_lic_id,mystation.transmitstationid,mystation.siteid,mystation.radiobroadcastingtypeid,mystation.istransmitter,
								mystation.decommissiondate,mystation.numberofreceivers,mystation.requestedfrequencybands,mystation.numberoffrequencies,mystation.requestedfrequency,mystation.requestedfrequencyGHz,mystation.requestedbandwidth,
								mystation.requestedbandwidthMHz,mystation.requestedbandwidthGHz,mystation.NOMINALTXPOWER,mystation.EFFECTIVETXPOWER,mystation.unitsrequested,mystation.unitsapproved,mystation.stationcallsign,mystation.isaircraft,mystation.location,
								mystation.max_operation_hours,mystation.AIRCRAFTNAME,mystation.AIRCRAFTTYPE,mystation.AIRCRAFTREGNO,mystation.VESSELTYPEID,mystation.VESSELNAME,mystation.IMONumber,mystation.GROSSTONNAGE,mystation.DECODERCAPACITY,mystation.vehicleregistration,'Copy of station id:' || mystation.stationid);
					COMMIT;
				
				END LOOP;

        --CLIENTSTATIONS        
        IF(countbases_vhf > 0) THEN
          --BASE vhf
          INSERT INTO clientstations(vhfnetworkid,licensepriceid,numberoffrequencies, numberofrequestedstations, isdummy)
              VALUES(new_vhf_net_id, 4, 0, countbases_vhf,'1'); 
          COMMIT;    
        ELSIF(countbases_hf > 0) THEN
          --base hf
          INSERT INTO clientstations(vhfnetworkid,licensepriceid,numberoffrequencies, numberofrequestedstations, isdummy)
              VALUES(new_vhf_net_id, 5, 0, countbases_hf,'1');  
          COMMIT;    
        ELSIF(countmobiles_vhf > 0) THEN
          --MOBILE VHF
          INSERT INTO clientstations(vhfnetworkid,licensepriceid,numberoffrequencies, numberofrequestedstations, isdummy)
              VALUES(new_vhf_net_id, 6, 0, countmobiles_vhf,'1');  
          COMMIT;    
        ELSIF(countmobiles_hf > 0) THEN
          --MOBILE HF
          INSERT INTO clientstations(vhfnetworkid,licensepriceid,numberoffrequencies, numberofrequestedstations, isdummy)
              VALUES(new_vhf_net_id, 2, 0, countmobiles_hf,'1');  
          COMMIT;    
        ELSIF(countportables_vhf > 0) THEN
          --PORTABL VHF
          INSERT INTO clientstations(vhfnetworkid,licensepriceid,numberoffrequencies, numberofrequestedstations, isdummy)
              VALUES(new_vhf_net_id, 1, 0, countportables_vhf,'1');  
          COMMIT;    
        ELSIF(countportables_hf > 0) THEN
          --PORTABLE HF
          INSERT INTO clientstations(vhfnetworkid,licensepriceid,numberoffrequencies, numberofrequestedstations, isdummy)
              VALUES(new_vhf_net_id, 3, 0, countportables_hf,'1');  
          COMMIT;    
       END IF;       
                
        
		END LOOP;

		--advance application to clc stage (and let the manager decide wether it skips CLC or not)
		--A. CLEAR CHECKLISTS at receiving and checking (another solution is to copy the clientphase and clientchecklist data for related clientlienseid)
		--a. identify corresponding clientphases
		FOR phaserec IN (select * from clientphases inner join phases on clientphases.phaseid=phases.phaseid where clientlicenseid = new_cli_lic_id and phases.phaselevel <= 2) LOOP
			
			--b. identify corresponding clientchecklists
			FOR checkrec IN (select * from clientchecklists where clientphaseid = phaserec.clientphaseid) LOOP
					--clear checklist
					UPDATE clientchecklists SET approved = '1', rejected = '0', actiondate = SYSDATE, userid = CAST(user_id as int)
						WHERE clientchecklistid = checkrec.clientchecklistid;	
          COMMIT;

			END LOOP;
			
			--approve the phase after clearing all the checklists
			UPDATE clientphases SET approved = '1', rejected = '0', pending = '0', isdone='1', actiondate = sysdate, userid =  CAST(user_id as int)
        WHERE clientphaseid = phaserec.clientphaseid;
      COMMIT;
									
		END LOOP;
		--END IF;
	end if; --if approval = reinstate
	
  UPDATE licenseviolations set ISREINSTATED='1', reinstateddate = sysdate WHERE clientlicenseid = cli_lic_id;
  COMMIT;
  
  CLOSE clientlicense_cur;    
		
	RETURN 'Reinstatement Successful';

END;
/








CREATE OR REPLACE VIEW vwcorrespondenceaction AS
	SELECT correspondenceaction.correspondenceactionid, correspondenceaction.correspondenceid, correspondenceaction.actorid, correspondenceaction.forwardeddate, correspondenceaction.action, correspondenceaction.actiondate, ac.fullname as actorname,
	correspondence.cckreference, correspondence.receivedate as correspondencedate, correspondenceaction.cleareddate, coalesce(esc.fullname,us.fullname) as forwardedby, correspondenceaction.escalaterremarks, correspondenceaction.iscleared,
	('<b>' || correspondence.cckreference || '<br>' || correspondence.correspondencesource || '<br><u>' || correspondence.subject || '</u></b>') as corrrespondencedetails, (coalesce(esc.fullname,us.fullname)|| '<br>On ' || to_char(correspondenceaction.forwardeddate,'Mon DD, YYYY')) as forwarddetails, getLastForwarderRemarks(correspondence.correspondenceid) as currentstatus
	FROM correspondenceaction
	INNER JOIN correspondence ON correspondenceaction.correspondenceid=correspondence.correspondenceid
	INNER JOIN users ac ON correspondenceaction.actorid = ac.userid
	LEFT JOIN users esc ON correspondenceaction.escalatedby = esc.userid
	LEFT JOIN users us ON correspondenceaction.userid = us.userid;


--used to track correscpondence action
--correspondenceaction (correspondenceid,escalatedby,escallatedto,action,details)
CREATE TABLE correspondenceaction (
	correspondenceactionid   integer primary key,

	correspondenceid		 integer references correspondence,		--correspondence table stores files also	
	actorid					 integer references users,				--the person to act on it
	forwardeddate			 date default sysdate,					--the date this correspondence was forwarded to the above actor
	duedate					 date,									--date this task is due

	escalatedby 			integer references users,				--the logged in user who forwaded/reassigned it to the actor
	escalationdate			date,									--date of escallation/reassignment
	onbehalfof				integer references users,				--the user/manager on behalf of whom the correspondece/job was forwaded to the actor
	
	escalaterremarks		clob,									--remarks from the ascallater/mgr to the actor
	
	action				clob,										--actors remark
	actiondate			date,										

	--future need
	iscleared			char(1) default '0',						--cleared by actor ?
	isaccepted			char(1) default '0',						--accepted by actor ?
	cleareddate			date,


	userid				integer references users,					--logged in user who did the initial insert

	details				clob
	
	);
CREATE SEQUENCE correspondenceaction_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_correspondenceaction_id BEFORE INSERT ON correspondenceaction
for each row 
begin     
	if inserting then 
		if :NEW.correspondenceactionid  is null then
			SELECT correspondenceaction_id_seq.nextval into :NEW.correspondenceactionid  from dual;
		end if;

		--update correspondence set isavailable = '0' where correspondenceid = :new.correspondenceid;
		
	end if; 
end;
/



CREATE OR REPLACE FUNCTION completecorrespondence(corr_id IN varchar2, use_id IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;

	BEGIN

		IF approval = 'Done' THEN
			UPDATE correspondenceaction SET iscleared = '1', cleareddate = sysdate, actiondate = sysdate WHERE correspondenceactionid = CAST(corr_id AS int);			
			COMMIT;
			--UPDATE THE PARENT TABLE
			UPDATE correspondence SET iscompleted = '1' WHERE correspondenceid = (SELECT correspondenceid FROM correspondenceaction WHERE correspondenceactionid = CAST(corr_id AS int));
			COMMIT;
		END IF;

	RETURN 'Correspondence Cleared Successfully';
END;
/



---
CREATE OR REPLACE FUNCTION closeCorrespondence(corr_id IN varchar2, use_id IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;

	BEGIN
		--assuming it does not have pending actions ie entries in correspondenceaction table
		IF approval = 'Close' THEN
			UPDATE correspondence SET iscompleted = '1' WHERE correspondenceid = CAST(corr_id AS int);
			COMMIT;
		ELSIF approval = 'Re Open' THEN
			UPDATE correspondence SET iscompleted = '0' WHERE correspondenceid = CAST(corr_id AS int);
			COMMIT;
		END IF;

	RETURN 'Correspondence '|| approval ||'d Successfully';
END;
/
---


create or replace TRIGGER upd_dispatch AFTER INSERT ON dispatch
for each row 
begin     
	if inserting then 
		UPDATE CORRESPONDENCE SET dispatched = '1', DISPATCHDATE = sysdate WHERE correspondenceid = :NEW.correspondenceid;		
	end if; 
end;




--this table has been misnamed - it actually stores stations owned by cck (which may require maintenance)
CREATE TABLE maintenancetasks(
	maintenancetaskid	integer primary key,	
	stationtypeid		integer references cckstationtype,
	fmischeduleid		integer references fmischedule,		--schedule

	stationname			varchar(50),	
	frequencyrange		varchar(50),
	iscompleted			char(1) default '0',
	donedate			date,
	assignedto			integer references users,
	assigndate			date,
	userid				integer references users,
	details 			clob
	);
CREATE SEQUENCE maintenancetaskid_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_maintenancetask_id BEFORE INSERT ON maintenancetasks
for each row 
begin     
	if inserting then 
		if :NEW.maintenancetaskid is null then
			SELECT maintenancetaskid_seq.nextval into :NEW.maintenancetaskid from dual;
		end if;
	end if; 
end;
/


CREATE OR REPLACE FUNCTION confirmmaintenancetask(maintenance_task_id IN varchar2, myval2 IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;

	BEGIN
		IF approval = 'Maintenance' THEN
			--UPDATE maintenancetasks SET fmischeduleid = CAST(fmi_schedule_id AS int) WHERE maintenancetaskid = CAST(filter_id AS int);
			INSERT INTO maintenancehistory(maintenancetaskid,fmischeduleid,assignedto)
				SELECT CAST(maintenance_task_id AS INT),fmischeduleid, assignedto
					FROM maintenancetasks WHERE maintenancetaskid = cast(maintenance_task_id as int);
			COMMIT;
		END IF;

	RETURN 'Task History Saved';
END;
/








CREATE TABLE maintenancehistory(
	maintenancehistoryid	integer primary key,	
	maintenancetaskid		integer references maintenancetasks,
	fmischeduleid		integer references fmischedule,		--schedule
		
	iscompleted			char(1) default '0',
	donedate			date,

	assignedto			integer references users,
	assigndate			date,

	userid				integer references users,
	details 			clob
	);
CREATE SEQUENCE maintenancehistoryid_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_maintenancehistory_id BEFORE INSERT ON maintenancehistory
for each row 
begin     
	if inserting then 
		if :NEW.maintenancehistoryid is null then
			SELECT maintenancehistoryid_seq.nextval into :NEW.maintenancehistoryid from dual;
		end if;
	end if; 
end;
/


CREATE OR REPLACE VIEW vwmaintenancehistory AS 
	SELECT ass.userid, ass.username, ass.fullname, maintenancetasks.stationtypeid,
		maintenancehistory.maintenancehistoryid, maintenancehistory.iscompleted, maintenancehistory.donedate, maintenancehistory.fmischeduleid,
		maintenancetasks.maintenancetaskid, maintenancetasks.stationname, maintenancetasks.frequencyrange, fmischedule.fmischedulename
		FROM maintenancehistory		
		INNER JOIN maintenancetasks ON maintenancehistory.maintenancetaskid = maintenancetasks.maintenancetaskid
		LEFT JOIN fmischedule ON maintenancehistory.fmischeduleid = fmischedule.fmischeduleid
		LEFT JOIN users ass ON maintenancehistory.assignedto = ass.userid
		LEFT JOIN users us ON maintenancehistory.userid = us.userid;



create table maintenancesheet(
	maintenacesheetid				  integer primary key,
	maintenancehistoryid			integer references maintenancehistory,
	userid			    integer references users,

	--preventive or corrective

	--general station condition
	computerrack_mountingstatus		varchar(100),
	computerrack_fasteningscrews	varchar(100),
	computerrack_cableconnections	varchar(100),
	computerrack_actiontaken		varchar(200),

	commrack_mountingstatus	varchar(100),
	commrack_fasteningscrews	varchar(100),
	commrack_cableconnections	varchar(100),
	commrack_actiontaken		varchar(200),

	controldrawer_mountingstatus	varchar(100),
	controldrawer_fasteningscrews	varchar(100),
	controldrawer_cableconnections	varchar(100),
	controldrawer_actiontaken		varchar(200),

	towerlight_mountingstatus	varchar(100),
	towerlight_fasteningscrews	varchar(100),
	towerlight_cableconnections	varchar(100),
	towerlight_actiontaken		varchar(200),

	wallsep_mountingstatus	varchar(100),
	wallsep_fasteningscrews	varchar(100),
	wallsep_cableconnections	varchar(100),
	wallsep_actiontaken		varchar(200),

	ciscorouters_mountingstatus	varchar(100),
	ciscorouters_fasteningscrews	varchar(100),
	ciscorouters_cableconnections	varchar(100),
	ciscorouters_actiontaken		varchar(200),


	alarmsystem_mountingstatus	varchar(100),
	alarmsystem_fasteningscrews	varchar(100),
	alarmsystem_cableconnections	varchar(100),
	alarmsystem_actiontaken		varchar(200),

	microwavelink_mountingstatus	varchar(100),
	microwavelink_fasteningscrews	varchar(100),
	microwavelink_cableconnections	varchar(100),
	microwavelink_actiontaken		varchar(200),

	securitylight_mountingstatus	varchar(100),
	securitylight_fasteningscrews	varchar(100),
	securitylight_cableconnections	varchar(100),
	securitylight_actiontaken		varchar(200),

	--for MMS
	tvrack_mountingstatus	varchar(100),
	tvrack_fasteningscrews	varchar(100),
	tvrack_cableconnections	varchar(100),
	tvrack_actiontaken		varchar(200),

	videoanalyzer_mountingstatus	varchar(100),
	videoanalyzer_fasteningscrews	varchar(100),
	videoanalyzer_cableconnections	varchar(100),
	videoanalyzer_actiontaken		varchar(200),
	

	antrooftop_mountingstatus	varchar(100),
	antrooftop_fasteningscrews	varchar(100),
	antrooftop_cableconnections	varchar(100),
	antrooftop_actiontaken		varchar(200),
	
	specanalyzer_mountingstatus	varchar(100),
	specanalyzer_fasteningscrews	varchar(100),
	specanalyzer_cableconnections	varchar(100),
	specanalyzer_actiontaken		varchar(200),
	
	antboxes_mountingstatus	varchar(100),
	antboxes_fasteningscrews	varchar(100),
	antboxes_cableconnections	varchar(100),
	antboxes_actiontaken		varchar(200),

	reporturl		varchar(500),
	details			clob
);
CREATE SEQUENCE maintenacesheetid_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_maintenacesheet_id BEFORE INSERT ON maintenancesheet
for each row 
begin     
	if inserting then 
		if :NEW.maintenacesheetid is null then
			SELECT maintenacesheetid_seq.nextval into :NEW.maintenacesheetid from dual;
		end if;
	end if; 
end;
/



CREATE TABLE maintenancesheetPO(
	maintenancesheetPOid				  integer primary key,
	maintenancehistoryid			integer references maintenancehistory,
	userid			    integer references users,

	--power on checks
 	ismainspoweron					char(1),
 	mainspower_reason_if_off		varchar(50),
 	mainspower_actiontaken			varchar(500),
 	
 	isupspoweron					char(1),
 	upspower_reason_if_off			varchar(50),
 	upspower_actiontaken			varchar(500),

 	isupsselftestpoweron			char(1),
 	selftestpower_reason_if_off		varchar(50),
 	selftestpower_actiontaken		varchar(500),

 	iscomputeron					char(1),
 	computer_reason_if_off			varchar(50),
 	computer_actiontaken			varchar(500),

	isrouteron						char(1),
 	router_reason_if_off			varchar(50),
 	router_actiontaken				varchar(500),

	islanswitchon						char(1),
 	lanswitch_reason_if_off			varchar(50),
 	lanswitch_actiontaken				varchar(500),

	isgsmindicatoron						char(1),
 	gsmindicator_reason_if_off			varchar(50),
 	gsmindicator_actiontaken				varchar(500),

	isrfuon						char(1),
 	rfu_reason_if_off			varchar(50),
 	rfu_actiontaken				varchar(500),

	isantennaselectoron						char(1),
 	antennaselector_reason_if_off			varchar(50),
 	antennaselector_actiontaken				varchar(500),

	isautomaticanson						char(1),
 	automaticans_reason_if_off			varchar(50),
 	automaticans_actiontaken				varchar(500),

	ismicrophoneon						char(1),
 	microphone_reason_if_off			varchar(50),
 	microphone_actiontaken				varchar(500),

	isinternallightson						char(1),
 	internallights_reason_if_off			varchar(50),
 	internallights_actiontaken				varchar(500),


	isairconditioneron						char(1),
 	airconditioner_reason_if_off			varchar(50),
 	airconditioner_actiontaken				varchar(500),

	--form MMS
	tvmonitor_on						char(1),
 	tvmonitor_reason_if_off			varchar(50),
 	tvmonitor_actiontaken				varchar(500),

	videoanalyzer_on						char(1),
 	videoanalyzer_reason_if_off			varchar(50),
 	videoanalyzer_actiontaken				varchar(500),

	specanalyzer_on						char(1),
 	specanalyzer_reason_if_off			varchar(50),
 	specanalyzer_actiontaken				varchar(500),

	fmradio_on						char(1),
 	fmradio_reason_if_off			varchar(50),
 	fmradio_actiontaken				varchar(500),

	details									clob
	);

CREATE SEQUENCE maintenancesheetPO_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_maintenancesheetPO_id BEFORE INSERT ON maintenancesheetPO
for each row 
begin     
	if inserting then 
		if :NEW.maintenancesheetPOid is null then
			SELECT maintenancesheetPO_seq.nextval into :NEW.maintenancesheetPOid from dual;
		end if;
	end if; 
end;
/



CREATE TABLE maintenancesheetSW(
	maintenancesheetSWid				integer primary key,
	maintenancehistoryid			integer references maintenancehistory,
	userid			   				integer references users,

	--built in tests
 	pass_trimble_gps				char(1),
 	trimble_gps_reason_if_fail		varchar(50),
 	trimble_gps_actiontaken			varchar(500),

	pass_tsr_2020_1						char(1),
 	pass_tsr_2020_1_reason_if_fail		varchar(50),
 	pass_tsr_2020_1_actiontaken			varchar(500),

	pass_tsr_2020_2						char(1),
 	pass_tsr_2020_2_reason_if_fail		varchar(50),
 	pass_tsr_2020_2_actiontaken			varchar(500),

	pass_tsr_2040						char(1),
 	pass_tsr_2040_reason_if_fail		varchar(50),
 	pass_tsr_2040_actiontaken			varchar(500),

	pass_compass						char(1),
 	compass_reason_if_fail		varchar(50),
 	compass_actiontaken			varchar(500),	

	pass_antselector						char(1),
 	antselector_reason_if_fail		varchar(50),
 	antselector_actiontaken			varchar(500),	

	pass_antrotator						char(1),
 	antrotator_reason_if_fail		varchar(50),
 	antrotator_actiontaken			varchar(500),	

	pass_rfm_2020						char(1),
 	rfm_2020_reason_if_fail		varchar(50),
 	rfm_2020_actiontaken			varchar(500),

	pass_gsm_modem						char(1),
 	gsm_modem_reason_if_fail		varchar(50),
 	gsm_modem_actiontaken			varchar(500),

	--other
	pass_sa						char(1),
 	sa_reason_if_fail		varchar(50),
 	sa_actiontaken			varchar(500),

	pass_audiotest						char(1),
 	audiotest_reason_if_fail		varchar(50),
 	audiotest_actiontaken			varchar(500),

	pass_audioretrieval						char(1),
 	audioretrieval_reason_if_fail		varchar(50),
 	audioretrieval_actiontaken			varchar(500),

	pass_audiorecording						char(1),
 	audiorecording_reason_if_fail		varchar(50),
 	audiorecording_actiontaken			varchar(500),

	pass_dftask						char(1),
 	dftask_reason_if_fail		varchar(50),
 	dftask_actiontaken			varchar(500),

	pass_reportgen						char(1),
 	reportgen_reason_if_fail		varchar(50),
 	reportgen_actiontaken			varchar(500),

	pass_laptop						char(1),
 	laptop_reason_if_fail		varchar(50),
 	laptop_actiontaken			varchar(500),

	pass_humming					char(1),
 	humming_reason_if_fail		varchar(50),
 	humming_actiontaken			varchar(500),

	details 						clob
	);
CREATE SEQUENCE maintenancesheetSWid_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_maintenancesheetSW_id BEFORE INSERT ON maintenancesheetSW
for each row 
begin     
	if inserting then 
		if :NEW.maintenancesheetSWid is null then
			SELECT maintenancesheetSWid_seq.nextval into :NEW.maintenancesheetSWid from dual;
		end if;
	end if; 
end;
/





--other tests
CREATE TABLE maintenancesheetOther(
	maintenancesheetOtherid			integer primary key,
	maintenancehistoryid			integer references maintenancehistory,
	userid			   				integer references users,
	
	pingtest_pass					char(1),
 	pingtest_results				varchar(50),
 	pingtest_result_accuracy		varchar(50),
	pingtest_remarks				varchar(500),

	triangulation_pass					char(1),
 	triangulation_results				varchar(50),
 	triangulation_result_accuracy		varchar(50),
	triangulation_remarks				varchar(500),

	surveillance_pass					char(1),
 	surveillance_results				varchar(50),
 	surveillance_result_accuracy		varchar(50),
	surveillance_remarks				varchar(500),

	other_pass					char(1),
 	other_results				varchar(50),
 	other_result_accuracy		varchar(50),
	other_remarks				varchar(500),



	--for mms
	antmast_mountingstatus	varchar(100),
	antmast_reception		varchar(100),
	antmast_cable			varchar(100),
	antmast_remarks			varchar(200),

	periodant_mountingstatus	varchar(100),
	periodant_reception		varchar(100),
	periodant_cable			varchar(100),
	periodant_remarks			varchar(200),

	hfcomm_mountingstatus	varchar(100),
	hfcomm_reception		varchar(100),
	hfcomm_cable			varchar(100),
	hfcomm_remarks			varchar(200),

	monitortv_mountingstatus	varchar(100),
	monitortv_reception		varchar(100),
	monitortv_cable			varchar(100),
	monitortv_remarks			varchar(200),

	vhfhornant_mountingstatus	varchar(100),
	vhfhornant_reception		varchar(100),
	vhfhornant_cable			varchar(100),
	vhfhornant_remarks			varchar(200),

	shfhornant_mountingstatus	varchar(100),
	shfhornant_reception		varchar(100),
	shfhornant_cable			varchar(100),
	shfhornant_remarks			varchar(200),

	details 					clob

	);
CREATE SEQUENCE maintenancesheetOtherid_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_maintenancesheetOther_id BEFORE INSERT ON maintenancesheetOther
for each row 
begin     
	if inserting then 
		if :NEW.maintenancesheetOtherid is null then
			SELECT maintenancesheetOtherid_seq.nextval into :NEW.maintenancesheetOtherid from dual;
		end if;
	end if; 
end;
/


CREATE OR REPLACE FUNCTION assigncase(user_id IN varchar2, myval2 IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	BEGIN
	
	IF approval='Assign' THEN
	  UPDATE  fmitasks  set assignto = CAST(user_id AS int),assigndate = SYSDATE where fmitaskid = CAST(filter_id AS int);
		UPDATE fmiclientphases set userid = CAST(user_id AS int) where fmitaskid = CAST(filter_id AS int) and CLIENTPHASENAME = 'ofmi';
	  COMMIT;
	END IF;

	IF approval='Maintenance' THEN
		UPDATE  maintenancetasks  set assignedto = CAST(user_id AS int),assigndate = SYSDATE where maintenancetaskid = CAST(filter_id AS int);
		COMMIT;
	END IF;

	RETURN 'Task Successfully Assigned';
END;











CREATE OR REPLACE VIEW vwmergedfmitasks AS
  SELECT fmitasks.complainantname, 	fmitasks.fmischeduleid, fmitasks.inspectiontypeid,
		fmischedule.fmischedulename, fmitasks.clientid,
		fmicompliancetypes.FmiCompliancetypename,fmicompliancetypes.FmicompliancetypeID,
		fmitasks.clientid as offender, fmitasks.ForInspection,fmitasks.ForInteference,fmitasks.ForMonitoring,fmitasks.dateofentry,
		to_char(fmitasks.violation) as violation, 
		to_char(fmitasks.Details) as details, to_char(fmitasks.Observations) as observations,fmitasks.fmitaskid,
		to_char(fmitasks.complaint) as complaint,fmitasks.casenumber,to_char(fmitasks.Recommendation) as recommendation,
		fmitasks.assigndate,fmitasks.assignto, '0' as ismaintenance,
		users.username,users.fullname,fmitasks.raisedby, us.fullname as updatedby
		
		FROM  fmitasks 
		INNER JOIN 	fmicompliancetypes ON fmicompliancetypes.FmicompliancetypeID = fmitasks.FmicompliancetypeID
		LEFT JOIN fmischedule on fmitasks.fmischeduleid = fmischedule.fmischeduleid
		LEFT OUTER JOIN users ON users.userid = fmitasks.assignto
		LEFT JOIN users us ON us.userid = fmitasks.userid
	UNION
		SELECT ' ' as complainantname, maintenancetasks.fmischeduleid, -1 as inspectiontypeid,
		fmischedule.fmischedulename, -1 as clientid,
		'' as FmiCompliancetypename, -1 as FmicompliancetypeID,
		-1 as offender, '0' as ForInspection, '0' as forinteference, '0' as formonitoring, assigndate as dateofentry,
		' ' as violation, 
		to_char(maintenancetasks.details) as details, '' as observations, maintenancetaskid as fmitaskid,
		'' as complaint, '' as casenumber, '' as recommendation, 
		assigndate, assignedto,'1' as ismaintenance,
		users.username, users.fullname,'' as raisedby, us.fullname as updatedby
		
		FROM maintenancetasks
		LEFT JOIN fmischedule on maintenancetasks.fmischeduleid = fmischedule.fmischeduleid
		LEFT JOIN users ON users.userid = maintenancetasks.assignedto
		LEFT JOIN users us ON us.userid = maintenancetasks.userid;



CREATE TABLE fmitasks(
	fmitaskid				integer primary key,
	fmicompliancetypeid		integer references fmicompliancetypes,
	userid					integer references users,
	clientid				integer references clients,		--accused ??
	monitoringtypeid		integer,	--references monitoringtype

	linkfmitaskid			integer,

	fmischeduleid			integer references fmischedule,		--schedule
	inspectiontypeid		integer references inspectiontype,
	raisedby 				integer references users,		--for inspection

	periodlicenseid			integer,  -- references periodlicenses,

	complainantname			varchar(50),
	complainantaddress		varchar(50),
	complainantfax			varchar(50),
	complainanttelephone	varchar(50),
	complainantemail		varchar(50),
	contactperson			varchar(200),

	requesturl				varchar(200),
	reporturl				varchar(200),

	assignto				integer references users,
	assigndate				date,	

	dateofentry				date default sysdate(),
	forinspection			char(1) default '0',
	forinteference			char(1) default '0',
	formonitoring			char(1) default '0',

	forlcs					char(1) default '0',
	forfsm					char(1) default '0',

	document				blob,
	attachment				blob,

	band						char(1) default '1',
	isdescreetfreq				char(1) default '1',

	bandfrom					varchar(50),
	bandto						varchar(50),

	frequency					varchar(50),
	bandwidth					varchar(50),

	typeofdevice				varchar(50),
	location					varchar(50),
	suspectedsource				varchar(50),
	letterdate					date,
	interferencetiming			varchar(50),
	monitoringperiod			varchar(50),
	interferencedesc			clob

	participants			varchar(200),
	violation				clob,
	findings				clob,
	observations			clob,
	complaint				clob,
	casenumber				varchar(50),
	recommendation			clob,
	conclusions				clob,
	details					clob
	);
CREATE SEQUENCE fmitask_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_fmitask_id BEFORE INSERT ON fmitasks
for each row 
begin     
	if inserting then 
		if :NEW.fmitaskid is null then
			SELECT fmitask_id_seq.nextval into :NEW.fmitaskid from dual;
		end if;

		if :NEW.fmicompliancetypeid=1	then	--interference
			:NEW.FORINTEFERENCE:='1';
		end if;

		if :NEW.fmicompliancetypeid=2	then	--monitoring
			:NEW.FORMONITORING:='1';
		end if;

		if :NEW.fmicompliancetypeid=3	then	--inspection
			:NEW.FORINSPECTION:='1';
		end if;

		--use userid to update raisedby

	end if; 
end;
/




--for radio network
CREATE TABLE fmiequipment(
	fmiequipmentid	integer primary key,
	fmitaskid		integer references fmitasks,
	make			varchar(50),
	model			varchar(50),
	serialnumber	varchar(50),
	measuredfreq	varchar(50),
	location		varchar(50),
	narrative		clob,
	details			clob
	);
CREATE SEQUENCE fmiequipmentid_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_fmiequipment_id BEFORE INSERT ON fmiequipment
for each row 
begin     
	if inserting then 
		if :NEW.fmiequipmentid is null then
			SELECT fmiequipmentid_seq.nextval into :NEW.fmiequipmentid from dual;
		end if;
	end if; 
end;
/


--FM TV Inspection-general
CREATE TABLE fmtvinspection(
	fmtvinspectionid	integer primary key,
	sitename			varchar(50),
	fmitaskid			integer references fmitasks,

	longitudedegrees	real,
	longitudeminutes	real,
	longitudeseconds	real,

	latitudedegrees		real,
	latitudeminutes		real,
	latitudeseconds		real,

	address				varchar(100),
	asl					real,			
	landowner			varchar(50),
	telkomoperators		clob,

--test
	technicalpersonnel			varchar(150),		--responsible for maintenance
	contactperson			clob,	
	details					clob,
--test

	narrative			clob

	);
CREATE SEQUENCE fmtvinspectionid_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_fmtvinspection_id BEFORE INSERT ON fmtvinspection
for each row 
begin     
	if inserting then 
		if :NEW.fmtvinspectionid is null then
			SELECT fmtvinspectionid_seq.nextval into :NEW.fmtvinspectionid from dual;
		end if;
	end if; 
end;
/


CREATE TABLE fmtvtower(
	fmtvtowerid				integer primary key,
	fmitaskid				integer references fmitasks,
	towerowner				varchar(50),
	heightaboveground		real,
	heightofbuilding		real,
	towertype				varchar(50),	
	rustprotection			varchar(50),
	towerinstallationdate	date,
	towermanufacturer		varchar(50),
	modelnumber				varchar(50),
	maxwindload				real,		--km/h
	maxloadcharge			real,		--kg
	towerinsurer			varchar(50),

	hasconcretebase			char(1),
	haslightningprotection	char(1),
	hasgrounding			char(1),
	hasaviationwarning		char(1),

	otherantennas			varchar(50),
	narrative				clob,
	details					clob
	);
CREATE SEQUENCE fmtvtowerid_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_fmtvtower_id BEFORE INSERT ON fmtvtower
for each row 
begin     
	if inserting then 
		if :NEW.fmtvtowerid is null then
			SELECT fmtvtowerid_seq.nextval into :NEW.fmtvtowerid from dual;
		end if;
	end if; 
end;
/






CREATE TABLE fmtvantenna(
	fmtvantennaid				integer primary key,
	fmitaskid				integer references fmitasks,

	typeofantenna			varchar(50),
	antennamanufacturer		varchar(50),
	antennamodel			varchar(50),
	antennacatalogurl		varchar(500),

	Homnidirectional		char(1),
	Hdirectional			char(1),
	Hbeamwidth				varchar(50),
	Hazimuth				varchar(50),
	Hazimuthurl				varchar(500),

	Vmechanicaltilt			char(1),
	Vdegreeofmechanicaltilt	varchar(50),
			
	Velectricaltilt			char(1),
	Vdegreeofelectricaltilt	varchar(50),
			
	Vnullfill				char(1),
	Vpercentageoffill		varchar(50),
			
	Vazimuthurl				varchar(500),

	antennagain				varchar(50),
	polarization			varchar(50),
			
	antennalosses			varchar(50),
	feederlosses			varchar(50),
	multiplexerlosses		varchar(50),
	antennaheightontower	varchar(50),
								
	narrative				clob,
	details					clob
	);

CREATE SEQUENCE fmtvantennaid_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_fmtvantenna_id BEFORE INSERT ON fmtvantenna
for each row 
begin     
	if inserting then 
		if :NEW.fmtvantennaid is null then
			SELECT fmtvantennaid_seq.nextval into :NEW.fmtvantennaid from dual;
		end if;
	end if; 
end;
/






CREATE TABLE fmtvtransmitter(
	fmtvtransmitterid		integer primary key,
	fmitaskid				integer references fmitasks,

	manufacturer			varchar(50),
	modelnumber				varchar(50),
	serialnumber			varchar(50),
				
	nominal_power_watts			varchar(50),
	actual_reading				varchar(50),
	erp_kilowatts				varchar(50),	
				
	rf_output_connector 		varchar(50),
	frequencyrange				varchar(50),
	frequencystability_ppm		varchar(50),
	harmonics_suppression_level_db	varchar(50),
	spurious_emission_level_db		varchar(50),

	internalaudiolimiter 		char(1),
	internalstereocoder			char(1),	
				
	transmittercatalog_url		varchar(50),
				
	technicalpersonnel			varchar(150),		--responsible for maintenance
	transmitfrequency			varchar(50),				
	transmitbandwidth 			varchar(50),
		
	contactperson			clob,
	cckofficers				clob,
									
	narrative				clob,
	details					clob
	);

CREATE SEQUENCE fmtvtransmitterid_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_fmtvtransmitter_id BEFORE INSERT ON fmtvtransmitter
for each row 
begin     
	if inserting then 
		if :NEW.fmtvtransmitterid is null then
			SELECT fmtvtransmitterid_seq.nextval into :NEW.fmtvtransmitterid from dual;
		end if;
	end if; 
end;
/






CREATE OR REPLACE TRIGGER tr_fmiclientphases AFTER INSERT ON fmitasks
   FOR EACH ROW
DECLARE
 -- PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	INSERT INTO fmiclientphases (fmitaskid, periodlicenseid,fmicompliancephasesid, EscalationTime, userid,clientphasename,clientapplevel)
	SELECT :NEW.fmitaskid, :NEW.periodlicenseid, fmicompliancephasesid, escalationTime, :NEW.userid, phasename, phaselevel
	FROM fmicompliancephases;
END;
/


--job flow management
CREATE OR REPLACE FUNCTION assignphase(user_id IN varchar2, myval2 IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	BEGIN
	
	IF approval='Assign' THEN
	  UPDATE  clientphases  set assignto = CAST(user_id AS int), assignedby = cast(myval2 AS int), assigndate = SYSDATE where clientphaseid = CAST(filter_id AS int);	  
	  COMMIT;
	END IF;

	IF approval='Undo Assign' THEN
	  UPDATE  clientphases  set assignto = null where clientphaseid = CAST(filter_id AS int);	  
	  COMMIT;
	END IF;

	RETURN 'Phase Successfully Assigned';
END;
/

--attach equipment to stations
CREATE OR REPLACE FUNCTION attachequipment(equip_id IN varchar2, user_id IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;

	CURSOR equip_cur IS
		SELECT *
		FROM equipments 
		WHERE equipmentid = cast(equip_id as int);
		rec_equip equip_cur%ROWTYPE;

	BEGIN	
		
		OPEN equip_cur;
		FETCH equip_cur INTO rec_equip;

		IF approval='Attach' THEN
			--insert new record
			INSERT INTO stationequipment(equipmentid, stationid) values(equip_id, filter_id);
			COMMIT;

			--initialize with default equipment values
			UPDATE stationequipment set 
				threshold = rec_equip.threshold,			
				conductedspurious = rec_equip.conductedspurious, radiatedspurious = rec_equip.radiatedspurious, 
				audioharmonicdistortion = rec_equip.audioharmonicdistortion, emmissiondesignation = rec_equip.emmissiondesignation,	
				receiversensitivity = rec_equip.receiversensitivity, receiveradjacenstselectivity = rec_equip.receiveradjacenstselectivity,
				desensitisation	= rec_equip.desensitisation,

				rfbandwidth = rec_equip.rfbandwidth, channelcapacity = rec_equip.channelcapacity,	
				carrieroutputpower = rec_equip.carrieroutputpower, tolerance = rec_equip.tolerance,
				duplexspacing = rec_equip.duplexspacing, adjacentchannelspacing = rec_equip.adjacentchannelspacing,
				powertoantenna = rec_equip.powertoantenna

			where equipmentid = cast(equip_id as int) and cast(stationid as int) = filter_id;

			COMMIT;
		END IF;

	RETURN 'Equipment Successfully Attached';
END;
/



--phases for each particular application
CREATE TABLE clientphases (
	clientphaseid		integer primary key,
	clientformtypeid	integer references clientformtypes,
	clientlicenseid		integer references clientlicenses,
	clientid			integer references clients,
	phaseid				integer references phases,
	scheduleID			integer references schedules,

	userid				integer references users,

	clientapplevel		integer ,
	clientphasename		varchar(120),
	userid				integer references users,
	escalationtime		integer default 2 not null,

	isdone				char(1) default '0' not null,	--done seeking approval by a manager or licensing officer. especially in the checking phase

	approved			char(1) default '0' not null,	--approved by a licensing officer in case of checking phases, among others
	rejected			char(1) default '0' not null,
	deffered			char(1) default '0' not null ,
	pending				char(1) default '0' not null ,
	withdrawn			char(1) default '0' not null ,

	--for cases where additional approval is required eg after board....
	mgr_approved		char(1) default '0' not null,
	ad_approved			char(1) default '0' not null,
	dir_approved		char(1) default '0' not null,
	dg_approved			char(1) default '0' not null,

	--for job management feature
	assignto			integer references users,
	assignedby			integer references users,
	assigndate			date,

	forwarded_date		date,		--manually updated by user....ex gazettement date i

	actiondate			timestamp,
	narrative			varchar(240),
	paid 				char(1) default '0' not null,
	remarks				clob,
	details				clob
);
CREATE INDEX clientphases_clientformtypeid ON clientphases (clientformtypeid);
CREATE INDEX clientphases_phaseid ON clientphases (phaseid);
CREATE INDEX clientphases_userid ON clientphases (userid);
CREATE INDEX clientphases_clientlicenseid ON clientphases (clientlicenseid);
CREATE SEQUENCE clientphases_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 2010;

CREATE OR REPLACE TRIGGER tr_clientphase_id BEFORE INSERT ON clientphases
for each row
	begin
	if inserting then
		if :NEW.clientphaseid is null then
			SELECT clientphases_id_seq.nextval into :NEW.clientphaseid from dual;
		end if;
	end if;
end;
/


CREATE TABLE clientchecklists (
	clientchecklistid	integer primary key,
	clientphaseid		integer references clientphases,
	checklistid			integer references checklists, 
	userid				integer references users,
	approved			char(1) default '0' not null,
	rejected			char(1) default '0' not null,
	actiondate			timestamp,
	narrative			varchar(240),
	details				clob
);
CREATE INDEX clientchecklists_clientphaseid ON clientchecklists (clientphaseid);
CREATE INDEX clientchecklists_checklistid ON clientchecklists (checklistid);
CREATE INDEX clientchecklists_userid ON clientchecklists (userid);
CREATE SEQUENCE clientchecklists_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_clientchecklist_id BEFORE INSERT ON clientchecklists
for each row 
begin     
	if inserting then 
		if :NEW.clientchecklistid is null then
			SELECT clientchecklists_id_seq.nextval into :NEW.clientchecklistid from dual;
		end if;
	end if; 
end;
/



CREATE TABLE clientdefination (
	clientdefinationid	integer primary key,
	licensedefinationid		integer references licensedefination,
	clientlicenseid		integer references clientlicenses,
	userid				integer references users,
	approved			char(1) default '0' not null,
	appliedfor			char(1) default '0' not null,
	recommended			char(1) default '0' not null,
	actiondate			timestamp,
	narrative			varchar(240),
	details				clob
);
CREATE INDEX clientdefination_licenseid ON clientdefination (licensedefinationid);
CREATE INDEX clientdefination_userid ON clientdefination (userid);
CREATE SEQUENCE clientdefination_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_clientdefination_id BEFORE INSERT ON clientdefination
for each row 
begin     
	if inserting then 
		if :NEW.clientdefinationid is null then
			SELECT clientdefination_id_seq.nextval into :NEW.clientdefinationid from dual;
		end if;
	end if; 
end;
/

--b4 training
CREATE OR REPLACE FUNCTION applicationFeeStatus(cli_lic_id in integer) RETURN varchar IS
PRAGMA AUTONOMOUS_TRANSACTION;
	
	paymenthistory varchar(10000);

BEGIN

	select '<b>Order Date</b>: ' || posteddate || '<br><b>Order Number:</b>' || licensepaymentid || '<br><b>Amount:</b>' || round(amount) || '<br><b>Invoice Number:</b>'|| invoicenumber || '<br><b>Remarks:</b>' || details into paymenthistory from licensepayments where clientlicenseid=cli_lic_id and paymenttypeid = 1;

	RETURN paymenthistory;

EXCEPTION
	WHEN OTHERS THEN
		RETURN 'Not Processed';

END;
/



CREATE OR REPLACE FUNCTION initialFeeStatus(cli_lic_id in integer) RETURN varchar IS
PRAGMA AUTONOMOUS_TRANSACTION;
	
	paymenthistory varchar(10000);

BEGIN

	select '<b>Order Date</b>: ' || posteddate || '<br><b>Order Number:</b>' || licensepaymentid || '<br><b>Amount:</b>' || round(amount) || '<br><b>Invoice Number:</b>'|| invoicenumber || '<br><b>Remarks:</b>' || details 
	into paymenthistory 
	from licensepayments 
  where licensepaymentid = 
    (select max(licensepaymentid) from licensepayments
        where clientlicenseid=cli_lic_id and paymenttypeid = 2);

	RETURN paymenthistory;

EXCEPTION
	WHEN OTHERS THEN
		RETURN 'Not Processed';

END;
/



--b4 training
CREATE OR REPLACE VIEW vwApplicationFeeStatus AS
	SELECT vwclientlicenses.clientlicenseid,vwclientlicenses.clientname, applicationFeeStatus(vwclientlicenses.clientlicenseid) as applicationfeestatus
	FROM vwclientlicenses;


--b4 training
CREATE OR REPLACE VIEW vwInitialFeeStatus AS
	SELECT vwclientlicenses.clientlicenseid,vwclientlicenses.clientname, initialFeeStatus(vwclientlicenses.clientlicenseid) as initialfeestatus,
	round(sum(calculateFullStationCharge(stations.stationid)*(proratedChargePeriod(current_date)/12))) as calculatedproratacharge
	FROM vwclientlicenses
  INNER JOIN stations ON vwclientlicenses.effectiveclientlicenseid = stations.clientlicenseid  
  GROUP BY vwclientlicenses.clientlicenseid,vwclientlicenses.clientname;


CREATE OR REPLACE VIEW vwlicenseorders AS
	SELECT licensepayments.licensepaymentid, licensepayments.productcode, licensepayments.clientlicenseid, licensepayments.paymenttypeid,
	licensepayments.amount, licensepayments.posteddate, licensepayments.invoicedate, licensepayments.invoicenumber, licensepayments.invoiceamount, licensepayments.paid,
	periods.periodid, periods.periodname, periods.startdate, periods.enddate, periods.isactive, periods.details, ('<b>Period: ' || periods.startdate || ' TO ' || periods.enddate || '</b>') as periodsummary,
	upper(vwmergedclients.clientname) as clientname, vwmergedclientlicenses.licensename, vwmergedclientlicenses.forfsm, vwmergedclientlicenses.forlcs
	FROM licensepayments
	INNER JOIN vwmergedclientlicenses on licensepayments.clientlicenseid = vwmergedclientlicenses.clientlicenseid
	INNER JOIN vwmergedclients on vwmergedclientlicenses.clientid = vwmergedclients.clientid
	INNER JOIN periods on licensepayments.periodid = periods.periodid;


--MONTHLY license applications
CREATE OR REPLACE VIEW vwmonthlyapplications AS
	SELECT distinct cast(to_char(clientlicenses.applicationdate,'YYYYMM') as int) as monthid , to_char(clientlicenses.applicationdate,'Month') as applicationmonth, to_char(clientlicenses.applicationdate,'YYYY') as applicationyear
	FROM clientlicenses 
	INNER JOIN clients on clientlicenses.clientid = clients.clientid
	INNER JOIN licenses ON clientlicenses.licenseid = licenses.licenseid;

--YEARLY applications from monthly applications
CREATE OR REPLACE VIEW vwyearlyapplications	AS
	SELECT distinct cast(vwmonthlyapplications.applicationyear as int) as yearid, vwmonthlyapplications.applicationyear as years
	FROM vwmonthlyapplications;
 
CREATE OR REPLACE VIEW VWLICENSEPAYMENTS AS
  SELECT
  CASE WHEN FORLCS = '1' THEN 'ADSDSD' ELSE '2343242' END   AS ad_org_id,
    vwclientlicenses.forfsm,
    vwclientlicenses.forlcs,
	periods.periodid,
	periods.periodname,
    'License'||': '||licensename AS description,
    vwclientlicenses.clientid,
    vwclientlicenses.clientname,
    vwclientlicenses.licenseid,
    vwclientlicenses.licensename,
    vwclientlicenses.email AS emailaddress,
    vwclientlicenses.clientlicenseid,
    licensepayments.licensepaymentid,
    licensepayments.amount  || ' ' || vwclientlicenses.currencyabbrev AS fullamount,
    licensepayments.invoicedate,
    vwclientlicenses.postalcode,
    
    licensepayments.salesorder,
    licensepayments.invoiced,
    licensepayments.invoicenumber,
    licensepayments.emailed,
    licensepayments.invoiceamount,
    licensepayments.paid,
    licensepayments.details,
    sysdate AS datetoday,
    licensepayments.posteddate,
    licensepayments.amount              AS amount,
    TO_CHAR(invoicedate, 'DD/Mon/YYYY') AS orcinvdate,
    TO_CHAR(posteddate, 'DD/Mon/YYYY')  AS orcpostdate,
    vwclientlicenses.applicationdate,
    paymenttypes.paymenttypeid,
    paymenttypes.paymenttypename,
    licensepayments.productcode,
    licensepayments.userid,
    licensepayments.clientphaseid,
    users.fullname,
    vwclientlicenses.address,
    initcap(vwclientlicenses.town)        AS town ,
    initcap(vwclientlicenses.countryname) AS country,
    ('Dear Applicant,
<br/><br/><br/>We are in receipt of your application for '
    || vwclientlicenses.licensename
    || '.
<br/><br/>Attached, please find an invoice that authorizes you to pay application fee payment at our finance department.
<br/><br/>Note that the Commission can only proceed to process your application upon receipt of this fee.
<br/><br/>In case of any queries or clarifications, please do not hesitate to revert back to us.
<br/><br/><br/>Thanks,
<br/>'
    || users.fullname
    || '<br/>
For Communications Commission of Kenya') AS mail,
    'Notification'                                     AS emailsubject
  FROM vwclientlicenses
  INNER JOIN licensepayments  ON vwclientlicenses.clientlicenseid = licensepayments.clientlicenseid
  INNER JOIN periods ON licensepayments.periodid = periods.periodid
  INNER JOIN paymenttypes ON licensepayments.paymenttypeid = paymenttypes.paymenttypeid
  INNER JOIN users ON licensepayments.userid = users.userid;




CREATE TABLE licensepayments (
	licensepaymentid	integer primary key,
	periodid			varchar(12) references periods,
	userid 				integer references Users,
	clientphaseid		integer references clientphases,
	productcode			varchar (32),
	clientlicenseid		integer references clientlicenses,
	paymenttypeid		integer references paymenttypes,
	amount				real not null,
    emailed				char(1) default '0' not null,
	posteddate			date default SYSDATE not null,

	salesorder			char(1) default '0' not null,
	ordernumber			varchar(50),
	invoicedate			date,
	invoiced			char(1) default '0' not null,
	invoicenumber 		varchar(32),
	invoiceamount		real,

	paid				char(1) default '0' not null,
	isvoid				char(1) default '0' not null,		--cancelled when a correction order is sent (by trigger or otherwise)
	
	RECEIPTNUMBER VARCHAR2(32 BYTE), 
	RECEIPTAMOUNT FLOAT(126), 

	details				clob


);
CREATE INDEX licensepayments_periodid ON licensepayments (periodid);
CREATE INDEX licensepayments_clientlicid ON licensepayments (clientlicenseid);
CREATE INDEX licensepayments_paymentypeid ON licensepayments (paymenttypeid);
CREATE SEQUENCE licensepayments_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 200;
CREATE OR REPLACE TRIGGER tr_licensepayment_id BEFORE INSERT ON licensepayments
for each row 
begin     
	if inserting then 
		if :NEW.licensepaymentid  is null then
			SELECT licensepayments_id_seq.nextval into :NEW.licensepaymentid  from dual;
		end if;
	end if; 
end;
/

--AFTER RENEWAL PAYMENT IS DONE MAKE SURE THE license is made active
CREATE OR REPLACE TRIGGER tr_updclientlicenses BEFORE UPDATE ON licensepayments
for each row 
begin     
	if updating then 

		--if renewal payment has been received
		IF(:NEW.paid = '1' AND :NEW.paymenttypeid = 3) THEN
			update clientlicenses set isactive='1', suspended='0', iscancelled='0', isterminated='0'  
			where clientlicenseid = :new.clientlicenseid;			
		END IF;

	end if; 
end;
/

--this is the backbone of license compliance module								

			

CREATE TABLE periodlicenses (
	periodlicenseid		integer primary key,
	periodid			varchar(12) references periods,
	clientlicenseid		integer references clientlicenses,
	userid				integer references Users,
	nonlicenserevenue	real,
	licenserevenue 		real,
	annualgross			real,
	annualfeedue		real,
	actiondate			date,
	periodcompliant 	char(1) default '0' not null,
	annualreturns		char(1) default '0' not null,
	quarterreturns		char(1) default '0' not null,
	voided				char(1) default '0' not null,
	qr1					char(1) default '0' not null,	--quarter 1 returns received
	qr2					char(1) default '0' not null,	--quarter 2 returns received
	qr3					char(1) default '0' not null,   --quarter 3 returns received
	qr4					char(1) default '0' not null,	--quarter 4 returns received
	ar					char(1) default '0' not null,	--annual returns submitted
	retcompliant		char(1) default '0' not null,	
	voiddate			date,
	details				clob,
	ISINVOICED 			CHAR(1 BYTE) DEFAULT '0' NOT NULL ENABLE, 
	AAACOMPLIANT 		CHAR(1 BYTE) DEFAULT '0' NOT NULL ENABLE, 
	NOTCOMPLIED 		CHAR(1 BYTE) DEFAULT '0' NOT NULL ENABLE, 
	COMPLIED			CHAR(1 BYTE) DEFAULT '0' NOT NULL ENABLE, 
	INITIALRETNOTIFICATIONLETTER	CLOB, 
	INITIALRETURNNOTIFICATION		CHAR(1 BYTE) DEFAULT '0' NOT NULL ENABLE, 
	INITIALNOTIFICATIONDATE 		date, 
	RESPONSEDATE 					date, 
	NOTIFICATIONRESPONSE 			CHAR(1 BYTE) DEFAULT '0' NOT NULL ENABLE, 
	CONDITIONSCOMPLIANT 			CHAR(1 BYTE) DEFAULT '0' NOT NULL ENABLE, 
	PENALTYPAID 					CHAR(1 BYTE) DEFAULT '0' NOT NULL ENABLE, 
	CONDITIONSNOTIFICATIONLETTER 	CLOB, 
	PENALTYAMOUNT					FLOAT(63), 
	AAANOTIFICATIONLETTER 			CLOB, 
	AAANOTIFICATIONDATE 			date, 
	CONDITIONSDEADLINE 				date, 
	CONDITIONSDATE 					date, 
	AAANOTIFICATION 				CHAR(1 BYTE) DEFAULT '0' NOT NULL ENABLE, 
	CONDITIONSNOTIFICATION			CHAR(1 BYTE) DEFAULT '0' NOT NULL ENABLE, 
	ANNUALFEESENT 					CHAR(1 BYTE) DEFAULT '0' NOT NULL ENABLE, 
	LICENSEEREQUEST 				CHAR(1 BYTE) DEFAULT '0' NOT NULL ENABLE, 
	SHAREHOLDING 					CHAR(1 BYTE) DEFAULT '0' NOT NULL ENABLE, 
	LICENSEEREQUESTNOTIFICATION 	CHAR(1 BYTE) DEFAULT '0' NOT NULL ENABLE, 
	SHAREHOLDINGNOTIFICATION 		CHAR(1 BYTE) DEFAULT '0' NOT NULL ENABLE, 
	SHAREHOLDINGNOTIFICATIONDATE 	date, 
	LICENSEEREQUESTNOTIFICDATE 		date, 
	MAILED 							CHAR(1 BYTE) DEFAULT '0' NOT NULL ENABLE, 
	MINFEEDUE	 					FLOAT(63), 
	CLIENTCOMPLIANCE 				CHAR(1 BYTE) DEFAULT '1' NOT NULL ENABLE, 
	QOSCOMPLIANT 					CHAR(1 BYTE) DEFAULT '0' NOT NULL ENABLE, 
	COMPLIANCEREASON 				VARCHAR2(240 BYTE)
	UNIQUE(periodid,clientlicenseid)
);
CREATE INDEX periodlicenses_periodid ON periodlicenses (periodid);
CREATE INDEX periodlicenses_clientlicenseid ON periodlicenses (clientlicenseid);
CREATE SEQUENCE periodlicenses_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 200;
CREATE OR REPLACE TRIGGER tr_periodlicense_id BEFORE INSERT ON periodlicenses
for each row 
begin   
		
	if inserting then 
		if :NEW.periodlicenseid  is null then
			SELECT periodlicenses_id_seq.nextval into :NEW.periodlicenseid  from dual;
		end if;
	end if; 
end;
/


create or replace TRIGGER TR_UPDREVENUE BEFORE INSERT ON periodlicenses FOR EACH ROW
DECLARE
PRAGMA AUTONOMOUS_TRANSACTION;
	BEGIN		
	
	:NEW.ANNUALFEEDUE := 0.5 * COALESCE (:NEW.LICENSEREVENUE,0);
	
END;
/



create or replace TRIGGER TR_UPDREVENUE BEFORE UPDATE ON periodlicenses 
FOR EACH ROW
DECLARE
PRAGMA AUTONOMOUS_TRANSACTION;
	BEGIN		
	
	:NEW.licenserevenue := :NEW.annualgross - :NEW.nonlicenserevenue;	
	
END;
/


create or replace TRIGGER TR_INSLICENSECONDITIONS AFTER INSERT ON periodlicenses
   FOR EACH ROW
DECLARE
     CURSOR c1 IS
      select licenseid from clientlicenses where clientlicenses.clientlicenseid = :NEW.clientlicenseid;
	  rc c1%ROWTYPE;
	
BEGIN
	OPEN c1;
	FETCH c1 INTO rc;
	INSERT INTO complconditionsappvl (periodlicenseid, complianceconditionid, narrative)
		SELECT :NEW.periodlicenseid, complianceconditionid, narrative
		FROM complianceconditions WHERE complianceconditions.licenseID = rc.licenseid;
    
	--IF (rc.licenseid = 24) THEN
	--INSERT INTO licensesqos(periodlicenseid,qosname,target) 
	--SELECT :NEW.periodlicenseid,qosname,target
	--FROM qosfactors;
	--END IF;

END;







CREATE TABLE compliancetypes (
	CompliancetypeID		integer primary key,
	Compliancetypename		varchar(240),
	details					clob
);
CREATE SEQUENCE compliancetypes_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_Compliancetype_id BEFORE INSERT ON compliancetypes
for each row 
begin     
	if inserting then 
		if :NEW.CompliancetypeID  is null then
			SELECT compliancetypes_id_seq.nextval into :NEW.CompliancetypeID  from dual;
		end if;
	end if; 
end;
/
-- provinces
CREATE TABLE regions (
  regionid integer primary key,
  regioname	varchar(120),
  details clob
);
CREATE SEQUENCE regions_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_region_id BEFORE INSERT ON regions
for each row 
begin     
	if inserting then 
		if :NEW.regionid  is null then
			SELECT regions_id_seq.nextval into :NEW.regionid  from dual;
		end if;
	end if; 
end;
/

CREATE TABLE complianceschedule (
	compliancescheduleid	integer primary key,
	scheduleID				integer references schedules,
	periodid				varchar(12) references periods,
	schedulename			varchar(120),
	regionid				integer references regions,
	approved				char(1) default '0' not null,
	inspections				varchar(120),
	generalreq				varchar(120),
	regions					varchar(120),
	UserID					integer references Users,
	startdate				date,
	enddate					date,
	details					clob
);
CREATE SEQUENCE complianceschedule_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_complianceschedule_id BEFORE INSERT ON complianceschedule
for each row 
begin     
	if inserting then 
		if :NEW.compliancescheduleid  is null then
			SELECT complianceschedule_id_seq.nextval into :NEW.compliancescheduleid  from dual;
		end if;
	end if; 
end;
/

CREATE TABLE compliance (
	ComplianceID			integer primary key,
	compliancescheduleid	integer references complianceschedule,
	adhoc					char(1) default '0' not null,
	noncompliant			char(1) default '0' not null,
	compliant				char(1) default '0' not null,
    ClientID				integer references Clients,
	VisitDate				timestamp ,
	HoursSpent				integer,
	participants			varchar(120),
	costperdiem				real,
	IsDone					char(1) default '0' not null,
	IsDrop					char(1) default '0' not null,
	IsForAction				char(1) default '0' not null,
	ActionDone				char(1) default '0' not null,
	forfsm					char(1) default '0' not null,
	forlcs					char(1) default '0' not null,	
	frequencyfrom			real ,
	frequencyto				real ,
	dateofviolation			date,
	violation				clob,
	Details					clob,
	purpose					clob,
	findings			clob,
	remarks			clob,
	conclusions		clob,
	Recommendation			clob
);
CREATE INDEX compliance_ClientID ON compliance (ClientID);
CREATE SEQUENCE Compliance_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 100;
CREATE OR REPLACE TRIGGER tr_Compliance_id BEFORE INSERT ON compliance
for each row 
begin     
	if inserting then 
		if :NEW.ComplianceID  is null then
			SELECT Compliance_id_seq.nextval into :NEW.ComplianceID  from dual;
		end if;
	end if; 
end;

--actual inspections carried out
CREATE TABLE clientinspection (
	clientinspectionid			integer primary key,
	scheduleid    			integer references schedules,
	clientid				integer,  -- references clients(clientid),

	report_url				clob,
	adhoc					char(1) default '0' not null,

	isnoncompliant			char(1) default '0' not null,
	iscompliant				char(1) default '0' not null,
	
	VisitDate				date default sysdate,		--time	
	HoursSpent				integer,
	participants			varchar(120),
	costperdiem				real,
	IsDone					char(1) default '0' not null,
	IsDrop					char(1) default '0' not null,
	IsForAction				char(1) default '0' not null,
	ActionDone				char(1) default '0' not null,
	forfsm					char(1) default '0' not null,
	forlcs					char(1) default '0' not null,	
	frequencyfrom			real ,
	frequencyto				real ,
	dateofviolation			date,

	actiondate				date default sysdate,
	

	violation				clob,
	Details					clob,
	purpose					clob,
	findings				clob,
	remarks					clob,
	conclusions				clob,
	Recommendation			clob,


	
	contraventionnotice		clob,
	penaltynotice			clob,
	penaltyamount			real default 0 not null,
	ispenaltypaid				char(1) default '0' not null,
	ispenaltyvoid				char(1) default '0' not null,		--used to nullify or overule the penalty charge
	revocationnotice		clob,

	mgr_compliance_comments	clob,
	mgr_postal_comments	clob,
	mgr_licenseing_comments	clob,
	ad_comments				clob,
	dir_comments			clob,
	dg_comments				clob
);
CREATE INDEX clientinspection_scheduleid ON clientinspection (scheduleid);
CREATE INDEX clientinspection_clientid ON clientinspection (clientid);

CREATE SEQUENCE clientinspection_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_clientinspection_id BEFORE INSERT ON clientinspection
for each row 
begin     
	if inserting then 
		if :NEW.clientinspectionid  is null then
			SELECT clientinspection_id_seq.nextval into :NEW.clientinspectionid  from dual;
		end if;
	end if; 
end;
/


CREATE OR REPLACE TRIGGER upd_InspectReport_Url BEFORE UPDATE ON clientinspection
for each row 
DECLARE
 	new_url		varchar(500);
begin   

 if updating then

	--COMPLIANCE status XOR flip-flop
	IF :NEW.iscompliant = '1' THEN
		:NEW.isnoncompliant := '0';
	ELSE 
		:NEW.isnoncompliant := '1';
	END IF;

	--url update stuff
	SELECT REPLACE(:NEW.report_url,'<a href=','') INTO new_url FROM dual;		--remove the leading '<a href=' substring
	SELECT REPLACE(new_url,'>Inspection Report</a>','') INTO new_url FROM dual;	
	:NEW.report_url := '<a href=' || new_url || '>Inspection Report</a>';
	
	--END IF;
end if;

end;
/





CREATE OR REPLACE VIEW vwclientinspection AS
	SELECT clientinspection.clientinspectionid, clientinspection.visitdate, clientinspection.isdone, clientinspection.iscompliant, clientinspection.isnoncompliant,
	clientinspection.isdrop, clientinspection.isforaction, clientinspection.actiondone, clientinspection.forfsm, clientinspection.forlcs,
	clientinspection.frequencyfrom, clientinspection.frequencyto, clientinspection.dateofviolation, clientinspection.violation, 
	clientinspection.purpose, clientinspection.findings, clientinspection.conclusions, clientinspection.recommendation,
	clientinspection.mgr_compliance_comments, clientinspection.mgr_postal_comments, clientinspection.mgr_licenseing_comments, clientinspection.ad_comments,
	clientinspection.dir_comments, clientinspection.dg_comments,
	clients.clientid,clients.clientname, clients.address, clients.town, scheduletypes.scheduletypeid, scheduletypes.complete,
  clientinspection.actiondate, add_months(TO_CHAR(clientinspection.visitdate, 'DD/Mon/YYYY'), 3) as penaltythreshold, (add_months(TO_CHAR(clientinspection.visitdate, 'DD/Mon/YYYY'), 3) + 15) as revocationthreshold,
    schedules.schedulename,    scheduletypes.scheduletypename, COALESCE(to_char(clientinspection.report_url),'<a href="http://intranet.cck.go.ke:8080/alfresco/n/browse/workspace/SpacesStore/7dd0d337-57a3-44c6-b732-b1c600a2e09d">Inspection Reports Space</a>') as report_url
	FROM clientinspection
	INNER JOIN clients ON clientinspection.clientid = clients.clientid
  INNER JOIN schedules ON  clientinspection.scheduleid = schedules.scheduleid
  INNER JOIN scheduletypes  ON scheduletypes.scheduletypeid = schedules.scheduletypeid;



--update clientinspection
create or replace FUNCTION clientInspectionUpdate (cli_insp_id IN varchar2, use_id IN varchar2, approval IN varchar2, filterid IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	
	BEGIN	 
				
	  --INSERT INTO clientlicenses  (licenseid,applicationdate,clientid) values (CAST(600 AS int),SYSDATE,CAST(cli_id AS int));
		IF(approval = 'SELECT OPTION')THEN
			RETURN 'PLZ SELECT A VALID OPTION';
		ELSIF(approval = 'Completed')THEN
			UPDATE clientinspection SET isdone = '1' WHERE clientinspectionid = CAST(cli_insp_id AS INT);
			COMMIT;
		ELSIF(approval = 'Not Completed')THEN
			UPDATE clientinspection SET isdone = '0' WHERE clientinspectionid = CAST(cli_insp_id AS INT);
			COMMIT;
		ELSIF(approval = 'Has Complied')THEN
			UPDATE clientinspection SET iscompliant = '1', isnoncompliant = '0' WHERE clientinspectionid = CAST(cli_insp_id AS INT);
			COMMIT;
    ELSIF(approval = 'Void Penalty')THEN
			UPDATE clientinspection SET iscompliant = '1', isnoncompliant = '0', ispenaltyvoid='1' WHERE clientinspectionid = CAST(cli_insp_id AS INT);
			COMMIT;  
		ELSE
			RETURN 'UNREACHABLE CODE SEGMENT';
		END IF;
	  
END;
 



CREATE OR REPLACE FUNCTION addInspectedClients(client_id IN varchar2, user_id IN varchar2, approval IN varchar2, schedule_id IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
  
  CURSOR client_cur IS
		SELECT clientid
		FROM clientinspection 
    WHERE scheduleid = CAST(schedule_id AS INT) AND clientid = CAST(client_id AS INT);
			
	rec_client client_cur%ROWTYPE;
  
	BEGIN
  
    OPEN client_cur;
    FETCH client_cur INTO rec_client;

	--if NOT already scheduled.......
	IF (client_cur%NOTFOUND) THEN
  
      IF approval = 'Add' THEN
        
        INSERT INTO clientinspection(scheduleid,clientid)
          VALUES(CAST(schedule_id AS INT), CAST(client_id AS INT));				
        
        COMMIT;
        
        RETURN 'Client Added : ' || client_id;          
        
      END IF;
  
  ELSE  --IF FOUND
  
      IF approval = 'Remove' THEN
      
        DELETE FROM clientinspection 
        WHERE schedule_id = CAST(schedule_id AS INT) AND clientid = CAST(client_id AS INT);
        COMMIT;
        
        RETURN 'Removed Client: ' || client_id;
        
     ELSE   
        RETURN 'Client Ignored : '|| client_id;
      END IF;
        
  END IF;
  
	RETURN 'Unreachable Code';
  
END;
/



CREATE OR REPLACE VIEW vwfmiparticipants AS
	SELECT fmiparticipants.*, fmischedule.fmischedulename
	FROM fmiparticipants
	INNER JOIN fmischedule ON fmiparticipants.fmischeduleid = fmischedule.fmischeduleid;


CREATE TABLE fmiparticipants (
	fmiparticipantsid			integer primary key,
	fmischeduleid	    integer references fmischedule,
	adhoc					    char(1) default '0' not null,
	noncompliant				char(1) default '0' not null,
	compliant				  char(1) default '0' not null,
   
	VisitDate				  timestamp ,
	HoursSpent				integer,

	participant				varchar(120),
	participantrole				varchar(100),

	costperdiem				real,
	IsDone					  char(1) default '0' not null,
	IsDrop					  char(1) default '0' not null,
	IsForAction				char(1) default '0' not null,
	ActionDone				char(1) default '0' not null,
	forfsm					  char(1) default '1' not null,	

	remarks			      clob,
	conclusions		    clob,
	Recommendation		clob
);
CREATE SEQUENCE fmiparticipants_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_fmiparticipants_id BEFORE INSERT ON fmiparticipants
for each row 
begin     
	if inserting then 
		if :NEW.fmiparticipantsid  is null then
			SELECT fmiparticipants_id_seq.nextval into :NEW.fmiparticipantsid  from dual;
		end if;
	end if; 
end;
/











CREATE TABLE licensecompliance (
	licensecomplianceID			integer primary key,
	periodlicenseid		integer references periodlicenses,
	compliant				char(1) default '0' not null,
	dateofviolation			date,
	violation				clob,
	Details					clob,
	Observations			clob,
	Recommendation			clob
);
CREATE SEQUENCE licensecompliance_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 100;
CREATE OR REPLACE TRIGGER tr_licensecompliance_id BEFORE INSERT ON licensecompliance
for each row 
begin     
	if inserting then 
		if :NEW.licensecomplianceID  is null then
			SELECT Compliance_id_seq.nextval into :NEW.licensecomplianceID  from dual;
		end if;
	end if; 
end;
/

CREATE TABLE qosfactors(
	qosfactorid		integer primary key,
	licenseid		integer references licenses,
	qosname				varchar(240),
	target				real,
	details				clob

);
CREATE  SEQUENCE qosfactors_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_qosfactors_id BEFORE INSERT ON qosfactors
for each row 
begin     
	if inserting then 
		if :NEW.qosfactorid  is null then
			SELECT qosfactors_id_seq.nextval into :NEW.qosfactorid  from dual;
		end if;
	end if; 
end;
/



CREATE TABLE licensesqos (
	licensesqosid	integer primary key,
	periodlicenseid		integer references periodlicenses,
	UserID					integer references Users ,
	qosfactorid		integer references qosfactors,
	regionid				integer references regions,
	regions				varchar(240),
	qosname				varchar(240),
	actiondate			date,
	qosdate				date,
	target				real,
	actualcck			real,
	targetexpression	varchar(20), --eg >90, <80
	actualclient		real,
	complied			char(1) default '0' not null,
	notcomplied			char(1) default '0' not null,
	recommendation		clob,
	action				clob,
	details				clob
);
CREATE  SEQUENCE licensesqos_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_licensesqos_id BEFORE INSERT ON licensesqos
for each row 
begin     
	if inserting then 
		if :NEW.licensesqosid  is null then
			SELECT licensesqos_id_seq.nextval into :NEW.licensesqosid  from dual;
		end if;
	end if; 
end;
/








--evaluate compliance based on the target expression and the actual(cck) value given...
--eg '>=90','20'
CREATE OR REPLACE FUNCTION calculateCompliance(expression IN varchar2, actualvalue IN real) RETURN VARCHAR IS
	PRAGMA AUTONOMOUS_TRANSACTION;
		oper_exp	varchar(5);		--will be '>=' for expression '>=78.9'	......aka target express
		oper_val	varchar(10);	--will be '78.9' for expression '>=78.9'.......aka target value
		
		operand1		real;		--USER INPUT
		operand2		real;		--TARGET
	BEGIN
		SELECT SUBSTR(expression,0,2) INTO oper_exp FROM dual;
		SELECT SUBSTR(expression,3) INTO oper_val FROM dual;

		operand1 := actualvalue;
		operand2 := CAST(oper_val AS REAL);

		IF(oper_exp = '>=') THEN
			IF(operand1 >= operand2) THEN 
				RETURN '1';
			ELSE
				RETURN '0';
			END IF;
		ELSIF (oper_exp = '<=') THEN
			IF(operand1 <= operand2) THEN 
				RETURN '1';
			ELSE
				RETURN '0';
			END IF;
		ELSE
			RETURN '-1';
		END IF;
		
			
	RETURN 'Unreachable Code';
END;
/


--license conditions which have to be complied with..while the license is still in use
CREATE TABLE complianceconditions (
	complianceconditionid	 integer primary key,
	licenseID		integer references licenses,
	narrative			varchar(240),
	details				clob
);
CREATE SEQUENCE complianceconds_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_compliancecond_id BEFORE INSERT ON complianceconditions
for each row 
begin   		
	if inserting then 
		if :NEW.complianceconditionid  is null then
			SELECT complianceconds_id_seq.nextval into :NEW.complianceconditionid  from dual;
		end if;
	end if; 
end;
/



CREATE TABLE complconditionsappvl (
	complconditionsappvlid	integer primary key,
	periodlicenseid		integer references periodlicenses,
	complianceconditionid	integer references complianceconditions,
	approved			char(1)  default '0'not null,
	rejected			char(1)  default '0' not null,

	complied			char(1) default '0' not null,
	notcomplied			char(1) default '0' not null,

	narrative			varchar(240),
	details				clob
);
CREATE SEQUENCE complconditionsappvl_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_complconditionsappvl_id BEFORE INSERT ON complconditionsappvl
for each row 
begin   
  
	if inserting then 
		if :NEW.complconditionsappvlid  is null then
			SELECT complconditionsappvl_id_seq.nextval into :NEW.complconditionsappvlid  from dual;
		end if;
	end if; 
end;
/
CREATE TABLE illegaloperators (
	illegaloperatorID			integer primary key,
	ComplianceID		integer references compliance,
	clientname			varchar(120),
	PostalCode			varchar(12),
	Premises			varchar(120),
	Street				varchar(120),
	Town				varchar(50) not null,
    dateofviolation			date,
	violation				clob,
	Details					clob,
	Observations			clob,
	Recommendation			clob
);
CREATE SEQUENCE illegaloperators_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 100;
CREATE OR REPLACE TRIGGER tr_illegaloperator_id BEFORE INSERT ON illegaloperators
for each row 
begin     
	if inserting then 
		if :NEW.illegaloperatorID  is null then
			SELECT illegaloperators_id_seq .nextval into :NEW.illegaloperatorID  from dual;
		end if;
	end if; 
end;
/

CREATE TABLE compliancephases (
	compliancephasesid				integer primary key,
	productcode		varchar(32),
	usergroupid			integer references usergroups,
	phasename			varchar(120),
	phaselevel			integer not null,
	returnlevel			integer not null,
	delaytime			integer default 2 not null,
	EscalationTime		integer default 2 not null,
	forpayment			char(1) default '0' not null,
	fornotification		char(1) default '0' not null,
	notificationsubject varchar(240),
	notificationtext	clob,
	details				clob
);

CREATE SEQUENCE compliancephases_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_compliancephases_id BEFORE INSERT ON compliancephases
for each row 
begin     
	if inserting then 
		if :NEW.compliancephasesid is null then
			SELECT compliancephases_id_seq.nextval into :NEW.compliancephasesid from dual;
		end if;
	end if; 
end;
/

CREATE TABLE clientcompliance (
	clientcomplianceid		integer primary key,
	clientlicenseid		integer references clientlicenses,
  narrative clob
	
);
CREATE SEQUENCE clientcompliance_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_clientcompliance_id BEFORE INSERT ON clientcompliance
for each row 
begin     
	if inserting then 
		if :NEW.clientcomplianceid is null then
			SELECT clientcompliance_id_seq.nextval into :NEW.clientcomplianceid from dual;
		end if;
	end if; 
end;
/

CREATE TABLE penalties (
	penaltyid           integer primary key,
	clientcomplianceid	integer references clientcompliance,
	userid				integer references users,
	usergroupid			integer references usergroups,
	clientapplevel      integer,
	numofcontraventions integer,
	clientphasename		varchar(120),
	penaltyamount		real,
	delaytime			integer default 2 not null,
	EscalationTime		integer default 2 not null,
	approved			char(1) default '0' not null,
	rejected			char(1) default '0' not null,
	pending				char(1) default '0' not null ,
	actiondate			timestamp,
	narrative			varchar(240),
	emailed					char(1) default '0' not null,
	details				clob
);
CREATE SEQUENCE penalties_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_penalties_id BEFORE INSERT ON penalties
for each row 
begin     
	if inserting then 
		if :NEW.penaltyid is null then
			SELECT penalties_id_seq.nextval into :NEW.penaltyid from dual;
		end if;
	end if; 
end;
/


CREATE TABLE numbertypes (
	numbertypeid		integer primary key,
	numbertypename		varchar(50),
	details				clob
);
CREATE SEQUENCE numbertypes_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 5;
CREATE OR REPLACE TRIGGER tr_numbertypeid_id BEFORE INSERT ON numbertypes
for each row 
begin     
	if inserting then 
		if :NEW.numbertypeid  is null then
			SELECT numbertypes_id_seq.nextval into :NEW.numbertypeid  from dual;
		end if;
	end if; 
end;
/

CREATE TABLE numbers (
	numberid			integer primary key,
	numbertypeid		integer references numbertypes,
	startrange			varchar(12),
	endrange			varchar(12),
	assignment			varchar(120),
	assigndate			date,
	activedate			date,
	details				clob
);
CREATE INDEX numbers_numbertypeid ON numbers (numbertypeid);
CREATE SEQUENCE numbers_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 900;
CREATE OR REPLACE TRIGGER tr_number_id BEFORE INSERT ON numbers
for each row 
begin     
	if inserting then 
		if :NEW.numberid  is null then
			SELECT numbers_id_seq.nextval into :NEW.numberid  from dual;
		end if;
	end if; 
end;
/


create or replace FUNCTION  FORNUMBERING (cli_id IN varchar2, myval2 IN varchar2, myval3 IN varchar2, lic_id IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	
	BEGIN	 
				
	  INSERT INTO clientlicenses (licenseid,applicationdate,clientid) values (CAST(600 AS int),SYSDATE,CAST(cli_id AS int));
	  COMMIT;

	RETURN ' Submitted';
END;
 




CREATE TABLE operators (
	operatorsid		integer primary key,
	operatorsname		varchar(120) not null,
	details				clob
);

CREATE TABLE areas (
	areaid		integer primary key,
	areaname		varchar(120) not null,
	details				clob
);

CREATE TABLE destinationcodes(
	destinationcodeid		integer primary key,
	areaid		integer references areas,
	destinationcode		varchar(120) not null,
	details				clob
);

CREATE TABLE numberseries(
	numberseriesid		integer primary key,
	destinationcodeid		integer references destinationcodes,
	operatorsid		integer references operators,
	currentnumberseries		varchar(120) not null,
	significantnumber		varchar(120) not null,
	details				clob
);




CREATE TABLE installations (
	installationid	integer primary key,
	clientlicenseid	integer references clientlicenses,		--id of the TP(Technical Personnel) or TEC (Tel Equip Contractor)
	site					varchar(120),

	periodid				varchar(32) references periods,

	checklist_url			clob,

	projectcontractor		varchar(200),	
	installationtype		varchar(50),
	installdate				date,
	
	clientname				varchar(120),
	postaladdress			varchar(150),
	physicaladdress			varchar(150),

	equipmentid				integer references equipments,		--type approved equip includes make + model
	equipmentmake			varchar(100),
	equipmentmodel			varchar(50),
	capacity				varchar(50),

	approved				char(1) default '0' not null ,
	rejected				char(1) default '0' not null ,
	
	findings				clob,

	details					clob
	
);
CREATE INDEX installations_clientlicenseid ON installations (clientlicenseid);
CREATE SEQUENCE installations_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 2;
CREATE OR REPLACE TRIGGER tr_installations_id BEFORE INSERT ON installations
for each row 
begin     
	if inserting then 
		if :NEW.installationid  is null then
			SELECT installations_id_seq.nextval into :NEW.installationid  from dual;
		end if;
	end if; 
end;
/


CREATE OR REPLACE TRIGGER upd_installdoc_URL BEFORE UPDATE ON installations
for each row 
DECLARE 	
 	new_url		varchar(500);
begin     
 if updating then
	
	SELECT REPLACE(:NEW.checklist_url,'<a href=','') INTO new_url FROM dual;		--remove the leading '<a href=' substring
	SELECT REPLACE(new_url,'>Installation Report</a>','') INTO new_url FROM dual;		--remove the trailing part

	:NEW.checklist_url := '<a href=' || new_url || '>Installation Report</a>';
	
end if;

end;
/
ALTER TRIGGER upd_installdoc_URL ENABLE;





CREATE OR REPLACE VIEW vwinstallations as
	SELECT (periods.periodname || ': ' || vwclientlicenses.clientname) as installationheader,
		vwclientlicenses.clientlicenseid, vwclientlicenses.clientname as contractorname,
		installations.installationid, installations.projectcontractor, installations.installdate, 
		installations.installationtype, installations.approved, installations.rejected,		
		installations.clientname, installations.postaladdress, installations.physicaladdress,
		installations.equipmentmake, installations.equipmentmodel,installations.findings,
		installations.checklist_url,
		('P.o. Box: '||installations.postaladdress || ' ' || installations.physicaladdress) as clientaddress,		
		periods.periodname
	FROM installations 
	INNER JOIN vwclientlicenses ON vwclientlicenses.clientlicenseid = installations.clientlicenseid
	INNER JOIN periods ON installations.periodid = periods.periodid;




--we want the remarks of the last(not previous) person to forward this action
CREATE OR REPLACE FUNCTION getLastForwarderRemarks(corr_id IN INTEGER) RETURN VARCHAR IS

	PRAGMA AUTONOMOUS_TRANSACTION;
	remarks CLOB;
  
	BEGIN
  
	SELECT escalaterremarks INTO remarks FROM correspondenceaction
					WHERE correspondenceactionid = (
							--The last cleared action
							SELECT MAX(correspondenceactionid) FROM correspondenceaction WHERE correspondenceid = corr_id AND iscleared = '1'
							);
	--RETURN coalesce(remarks,'Completed. No Uncleared Actions on this correspondence');
	RETURN remarks;
  
END;
/




CREATE OR REPLACE FUNCTION returnequipment(equip_inventory_id IN varchar2,val2 IN varchar2,val3 IN varchar2,filter_id IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	BEGIN
	  UPDATE EQUIPTRACKING
			SET isborrowed = '0',
				returndate = sysdate
			WHERE equipinventoryid = (
						SELECT equipinventoryid FROM equiptracking WHERE equiptrackingid = (
										SELECT max(equiptrackingid) FROM equiptracking WHERE equipinventoryid = cast(equip_inventory_id as int)));
	  COMMIT;
	RETURN 'Returned Successfully';
END;
/



CREATE OR REPLACE FORCE VIEW VWEQUIPTRACKING AS 
	SELECT equipinventory.equipinventoryid, equipinventory.bitudate, equipinventory.equipmentname, equipinventory.equipmentmanufacturer, equipinventory.modelnumber, equipinventory.serialnumber, equiptracking.equipstatus,
	equipinventory.acquisitiondate, equipinventory.loanedout, equipinventory.details, getNextCalibration(equipinventory.equipinventoryid) as nextcalibration, borrowdate, returndate, isborrowed, equiptracking.borrowerid, borrower.fullname as borrowername
	FROM equiptracking 
	LEFT JOIN equipinventory ON equipinventory.equipinventoryid = equiptracking.equipinventoryid
	LEFT JOIN users borrower ON equiptracking.borrowerid = borrower.userid;


CREATE OR REPLACE FORCE VIEW VWFILETRACKING AS 
	SELECT correspondence.correspondenceid, correspondence.correspondencetypeid, correspondence.correspondencesource as clientname, correspondence.dfnumber, correspondence.isavailable,
	filetracking.filetrackingid, filetracking.filestatus, filetracking.details, filetracking.borrowdate, filetracking.returndate, filetracking.isborrowed, 
	filetracking.borrowerid, borrower.fullname as borrowername,
	filetracking.isforwarded, fwd.userid as forwarderid, fwd.fullname as forwardedby,
	('File: ' || correspondence.correspondencesource || '<br>DF Number: ' || correspondence.dfnumber) as filesummary
	FROM filetracking 
	LEFT JOIN correspondence ON filetracking.correspondenceid = correspondence.correspondenceid
	LEFT JOIN users borrower ON filetracking.borrowerid = borrower.userid
	LEFT JOIN users fwd ON filetracking.userid = fwd.userid;



CREATE OR REPLACE VIEW VWFILESTATUS AS
  SELECT correspondence.correspondenceid,correspondence.cckreference,correspondence.receivedate, cast(to_char(correspondence.receivedate,'MM') as integer) as monthreceived, 
	cast(to_char(correspondence.receivedate,'YYYY') as integer) as yearreceived,  correspondence.dfnumber, correspondencetype.correspondencetypeid, correspondencetype.correspondencetype,
	coalesce(correspondence.correspondencesource,('From: ' || fromdept.departmentname || ' To: ' || todept.departmentname)) as correspondencesource, correspondence.subject,
	receiver.userid as recieverid,receiver.fullname as recievername, borrower.userid as borrowerid, correspondence.lastborroweddate as borrowdate, borrower.fullname as borrowername, fromdept.departmentname as fromdepartment, 
	todept.departmentname as todepartment, actor.userid as actorid, actor.fullname as actorname, us.userid, us.rolename, Correspondence.actiondate,
	Correspondence.Petitioner_ID, cla.clientname as Petitioner_Name, Correspondence.Respondent_ID, clb.clientname as Respondent_Name, correspondence.correspondencesource as clientname,
	Correspondence.Details, Correspondence.Closed, Correspondence.close_date, Correspondence.DISPATCHDATE, Correspondence.dispatched, correspondence.isavailable,
	decode(Correspondence.dispatched,'1','Completed','Outstanding') as status
	FROM correspondence
	LEFT JOIN correspondencetype ON correspondence.correspondencetypeid = correspondencetype.correspondencetypeid
	LEFT JOIN department fromdept ON fromdept.departmentid = correspondence.fromdepartmentid
	LEFT JOIN department todept ON todept.departmentid = correspondence.todepartmentid
	LEFT JOIN users receiver ON receiver.userid = correspondence.receiverid
	LEFT JOIN users borrower ON borrower.userid = correspondence.fileborrowerid
	LEFT JOIN users actor ON actor.userid = correspondence.actorid
	LEFT JOIN users us ON us.userid = correspondence.userid
	LEFT JOIN clients cla ON cla.clientid = Correspondence.Petitioner_ID
	LEFT JOIN clients clb ON clb.clientid = Correspondence.Respondent_ID
	WHERE correspondencetype.correspondencetypeid is null;





--redundant (w.r.t vwequiptracking) ???????
CREATE OR REPLACE FORCE VIEW VWEQUIPINVENTORY AS 
	SELECT equipinventory.equipinventoryid, equipinventory.bitudate, equipinventory.equipmentname, equipinventory.equipmentmanufacturer, equipinventory.modelnumber, equipinventory.serialnumber,('<b>Manufacturer:</b> ' ||equipinventory.equipmentmanufacturer|| '<br><b>Model Number:</b> ' || equipinventory.modelnumber ||'<br><b>SN:</b> ' ||  equipinventory.serialnumber) as equipmentsummary, 
	equipinventory.acquisitiondate, equipinventory.loanedout, equipinventory.details, getNextCalibration(equipinventory.equipinventoryid) as nextcalibration, borrowdate, returndate, isborrowed, 
	equiptracking.borrowerid, borrower.fullname as borrowername
	FROM equipinventory 	
	LEFT JOIN equiptracking ON equipinventory.equipinventoryid = equiptracking.equipinventoryid
	LEFT JOIN users borrower ON equiptracking.borrowerid = borrower.userid;





CREATE OR REPLACE FORCE VIEW VWEQUIPCALIBRATION AS 
	SELECT equipinventory.equipinventoryid, equipinventory.equipmentname, equipinventory.equipmentmanufacturer, 
	equipinventory.modelnumber, equipinventory.serialnumber, equipinventory.acquisitiondate, equipinventory.loanedout, 
	equipinventory.details, equipinventory.forcalibration, getNextCalibration(equipinventory.equipinventoryid) as nextcalibration, borrowdate, returndate, 
	isborrowed, borrowerid
	FROM equipinventory 	
	LEFT JOIN equiptracking ON equipinventory.equipinventoryid = equiptracking.equipinventoryid;




CREATE TABLE calibrationtasks(
	calibrationtaskid	integer primary key,	
	equipinventoryid	integer references equipinventory,

	duedate				date,					--ideal calibration date - using bitu and interval
	calibrationdate		date,				--date calibration done by the manufacturer
	donedate			date default sysdate,	--day calibration info is captured in imis

	isdone				char(1) default '0',

	assignedto			integer references users,	--officer responsible
	assigndate			date,						
	userid				integer references users,	--logged in user
	remarks 			clob,
	details 			clob
	);
CREATE SEQUENCE calibrationtaskid_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_calibrationtask_id BEFORE INSERT ON calibrationtasks
for each row 
begin     
	if inserting then 
		if :NEW.calibrationtaskid is null then
			SELECT calibrationtaskid_seq.nextval into :NEW.calibrationtaskid from dual;
		end if;
	end if; 
end;
/



create or replace FUNCTION updcalibration(equipinventory_id IN varchar2, myval2 IN varchar2,myval3 IN varchar2, myval4 IN varchar2) RETURN varchar2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	
	INSERT INTO calibrationtasks (equipinventoryid, duedate)
		--SELECT CAST(equipinventory_id AS INT), (TO_DATE(getNextCalibration(CAST(equipinventory_id AS INT))) FROM DUAL);
			VALUES (CAST(equipinventory_id AS INT), null);
	COMMIT;

	--mark it as done ??????
	UPDATE calibrationtasks set isdone = '1' WHERE isdone='0';
	COMMIT;

	--update nextcalibration at inventoryequip
	UPDATE equipinventory set lastcalibrationdate = sysdate where equipinventoryid = CAST(equipinventory_id AS INT);
	COMMIT;

	RETURN 'Calibration Done';
END;




	
--getnextcalibration
CREATE OR REPLACE FUNCTION getNextCalibration(equipinventory_id in integer) RETURN varchar IS
PRAGMA AUTONOMOUS_TRANSACTION;
	myret varchar(100);
	
BEGIN
	
	SELECT coalesce(to_char(ADD_MONTHS(coalesce(lastcalibrationdate,sysdate), calibrationinterval)),'BITU date or Calibration Interval is undefined') into myret 
		FROM equipinventory
		WHERE equipinventoryid = equipinventory_id;

	RETURN '<b>' || myret|| '</b>';
  
END;
/




--used to store equipment borrowing history
CREATE TABLE EQUIPTRACKING (
	equiptrackingid   integer primary key,
	EQUIPINVENTORYID	integer references EQUIPINVENTORY,
	borrowdate			date default sysdate,
	returndate			date,
	borrowerid			integer references users,
	equipstatus			clob,
	isborrowed			char(1) default '0',
	details				clob
	--userid
	);
CREATE SEQUENCE EQUIPTRACKING_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 2;
CREATE OR REPLACE TRIGGER tr_EQUIPTRACKING_id BEFORE INSERT ON EQUIPTRACKING
for each row 
begin     
	if inserting then 
		if :NEW.equiptrackingid  is null then
			SELECT EQUIPTRACKING_id_seq.nextval into :NEW.equiptrackingid  from dual;
		end if;
	end if; 
end;
/



 CREATE TABLE EQUIPINVENTORY (
	EQUIPINVENTORYID 	integer primary key,
	EQUIPMENTNAME	 	VARCHAR2(240), 
	equipmentmanufacturer	varchar(150),
	SERIALNUMBER 		VARCHAR2(240), 
	modelnumber		 	varchar(50),
	ACQUISITIONDATE 	DATE DEFAULT sysdate, 

	BITUDATE			DATE DEFAULT sysdate,			--bring in to use date
	lastcalibrationdate	date,

	forcalibration		char(1) default '0' not null,
	calibrationinterval	integer,						--interval in months
	
	LOANEDOUT 			CHAR(1 BYTE) DEFAULT '0' NOT NULL,		--ie isnotavailable
	equipmentdescription 	clob,
	equipmentstatus			clob,
	equipmentlocation	varchar(200),

	userid				integer references users,
	updatedby			integer references users,

	currentstatus		clob,

	DETAILS 			CLOB
	);

CREATE SEQUENCE equipinventory_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 15;
CREATE OR REPLACE TRIGGER TR_EQUIPINVENTORY_ID BEFORE INSERT ON equipinventory
for each row 
begin     
	if inserting then 
		if :NEW.equipinventoryid  is null then
			SELECT equipinventory_id_seq.nextval into :NEW.equipinventoryid  from dual;
		end if;
		:new.currentstatus := :new.equipmentstatus;		--by default 
		:NEW.lastcalibrationdate := :NEW.BITUDATE;
	end if; 
end;
/

CREATE OR REPLACE VIEW vwequipmenttypes AS
	SELECT equipmenttypeid,decode(equipmenttypename, 'C', 'AERONAUTICAL EQUIPMENT', 'T', 'BROADCASTING EQUIPMENT', equipmenttypename) as equipmenttypename,details
	FROM equipmenttypes;


CREATE TABLE equipmenttypes (
	equipmenttypeid		integer primary key,
	equipmenttypename	varchar(120),
	details				clob
	);
CREATE SEQUENCE equipmenttypes_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 15;
CREATE OR REPLACE TRIGGER tr_equipmenttype_id BEFORE INSERT ON equipmenttypes
for each row 
begin     
	if inserting then 
		if :NEW.equipmenttypeid  is null then
			SELECT equipmenttypes_id_seq.nextval into :NEW.equipmenttypeid  from dual;
		end if;
	end if; 
end;
/


  CREATE TABLE EQUIPMENTAPPROVALS
   (	"EQUIPMENTAPPROVALID" NUMBER(*,0), 
	"CLIENTID" NUMBER(*,0), 
	"EQUIPMENTTYPEID" NUMBER(*,0), 
	"EQUIPMENTNAME" VARCHAR2(120 BYTE), 
	"SERIALNUMBER" VARCHAR2(120 BYTE), 
	"MANUFACTURER" VARCHAR2(120 BYTE), 
	"MAKE" VARCHAR2(120 BYTE), 
	"MODEL" VARCHAR2(120 BYTE), 
	"SUPPLIERNAME" VARCHAR2(240 BYTE), 
	"APPROVED" CHAR(1 BYTE) DEFAULT '0' NOT NULL ENABLE, 
	"REJECTED" CHAR(1 BYTE) DEFAULT '0' NOT NULL ENABLE, 
	"DETAILS" CLOB, 
	"PENDING" CHAR(1 BYTE) DEFAULT '0' NOT NULL ENABLE, 
	"COUNTRYID" CHAR(2 BYTE), 
	"CLIENTLICENSEID" NUMBER(*,0), 
	"CASENO" VARCHAR2(120 BYTE), 
	"OUTPUTPOWER" VARCHAR2(50 BYTE), 
	"TOLERANCE" VARCHAR2(10 BYTE), 
	"CARRIEROUTPUTPOWER" VARCHAR2(100 BYTE), 
	"DUPLEXSPACING" VARCHAR2(100 BYTE), 
	"ADJACENTCHANNELSPACING" VARCHAR2(100 BYTE), 
	"POWERTOANTENNA" VARCHAR2(100 BYTE), 
	"CHANNELCAPACITY" VARCHAR2(50 BYTE), 
	"SYSTEMDEVIATION" VARCHAR2(50 BYTE), 
	"BITERRORRATE" VARCHAR2(50 BYTE), 
	"CONDUCTEDSPURIOUS" VARCHAR2(50 BYTE), 
	"RADIATEDSPURIOUS" VARCHAR2(50 BYTE), 
	"AUDIOHARMONICDISTORTION" VARCHAR2(200 BYTE), 
	"EMMISSIONDESIGNATION" VARCHAR2(200 BYTE), 
	"OPERATINGFREQUENCYBAND" VARCHAR2(50 BYTE), 
	"RFBANDWIDTH" VARCHAR2(50 BYTE), 
	"IFBANDWIDTH_3DB" VARCHAR2(50 BYTE), 
	"RECEIVERSENSITIVITY" VARCHAR2(200 BYTE), 
	"RECEIVERADJACENSTSELECTIVITY" VARCHAR2(200 BYTE), 
	"DESENSITISATION" VARCHAR2(200 BYTE), 
	"FMNOISE" VARCHAR2(50 BYTE), 
	"THRESHOLD" VARCHAR2(100 BYTE), 
	"RFFILTERLOSS" VARCHAR2(50 BYTE), 
	"ISDECLARED" CHAR(1 BYTE) DEFAULT '0' NOT NULL ENABLE, 
	"REQUESTEDSPOTFREQUENCIES" VARCHAR2(500 BYTE), 
	"RECOMMENDATION" CLOB, 
	"COMPLIANTWITH" CLOB, 
	"OVERVIEW" CLOB, 
	"FEATURES" CLOB,
	evaluationresults clob,
	evaluationdate	date,
	actiondate		date default sysdate not null,
	"POWERSUPPLY" VARCHAR2(240 BYTE), 
	"FREQUENCYDEVIATION" VARCHAR2(240 BYTE), 
	"MODULATION" VARCHAR2(240 BYTE), 
	"NUMBEROFCHANNELS" VARCHAR2(240 BYTE), 
	"DATAMODE" VARCHAR2(240 BYTE), 
	"RFOUTPUT" VARCHAR2(240 BYTE), 
	"PURPOSE" VARCHAR2(240 BYTE), 
	"DIMENSIONS" VARCHAR2(240 BYTE), 
	"MEMORY" VARCHAR2(240 BYTE), 
	"INTERFACE" VARCHAR2(240 BYTE), 
	"SAR" VARCHAR2(240 BYTE), 
	"LIVETEST" VARCHAR2(240 BYTE), 
	REPORT_URL VARCHAR2(500), 
	DMSSPACE_URL VARCHAR2(500), 
	INLINE_REPORT CLOB, 
	
	--provisional certificate/letter
	cert_url		varchar(500),
	cert_dmsspace	varchar(500),
	inline_certificate	clob,

	 PRIMARY KEY ("EQUIPMENTAPPROVALID")
  USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT)
  TABLESPACE "USERS"  ENABLE, 
	 FOREIGN KEY ("EQUIPMENTTYPEID")
	  REFERENCES "CCK"."EQUIPMENTTYPES" ("EQUIPMENTTYPEID") ENABLE, 
	 FOREIGN KEY ("COUNTRYID")
	  REFERENCES "CCK"."COUNTRYS" ("COUNTRYID") ENABLE
   ) PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT)
  TABLESPACE "USERS" 
 LOB ("DETAILS") STORE AS (
  TABLESPACE "USERS" ENABLE STORAGE IN ROW CHUNK 8192 PCTVERSION 10
  NOCACHE LOGGING 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT)) 
 LOB ("RECOMMENDATION") STORE AS (
  TABLESPACE "USERS" ENABLE STORAGE IN ROW CHUNK 8192 PCTVERSION 10
  NOCACHE LOGGING 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT)) 
 LOB ("COMPLIANTWITH") STORE AS (
  TABLESPACE "USERS" ENABLE STORAGE IN ROW CHUNK 8192 PCTVERSION 10
  NOCACHE LOGGING 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT)) 
 LOB ("OVERVIEW") STORE AS (
  TABLESPACE "USERS" ENABLE STORAGE IN ROW CHUNK 8192 PCTVERSION 10
  NOCACHE LOGGING 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT)) 
 LOB ("FEATURES") STORE AS (
  TABLESPACE "USERS" ENABLE STORAGE IN ROW CHUNK 8192 PCTVERSION 10
  NOCACHE LOGGING 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT)) 
 LOB ("INLINE_REPORT") STORE AS (
  TABLESPACE "USERS" ENABLE STORAGE IN ROW CHUNK 8192 PCTVERSION 10
  NOCACHE LOGGING 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT)) ;
 

  CREATE OR REPLACE TRIGGER "CCK"."TR_EQUIPMENTAPPROVAL_ID" BEFORE INSERT ON equipmentapprovals
for each row 
begin     
	if inserting then 
		if :NEW.equipmentapprovalid  is null then
			SELECT equipmentapprovals_id_seq.nextval into :NEW.equipmentapprovalid  from dual;
		end if;
	end if; 
end;



/
ALTER TRIGGER "CCK"."TR_EQUIPMENTAPPROVAL_ID" ENABLE;
 

CREATE OR REPLACE TRIGGER UPD_EVALREPORT_URL BEFORE UPDATE ON equipmentapprovals
for each row 
DECLARE 	
 	new_report_url		varchar(500);
	new_letter_url	varchar(500);		--provisional cert/letter
begin     
 if updating then
	
	--EVALUATION 
	SELECT REPLACE(:NEW.report_url,'<a href=','') INTO new_report_url FROM dual;		--remove the leading '<a href=' substring
	SELECT REPLACE(new_report_url,'>Evaluation Report</a>','') INTO new_report_url FROM dual;		--remove the trailing part

	:NEW.report_url := '<a href=' || new_report_url || '>Evaluation Report</a>';
	
	--CERFICATE
	SELECT REPLACE(:NEW.cert_url,'<a href=','') INTO new_letter_url FROM dual;		--remove the leading '<a href=' substring
	SELECT REPLACE(new_letter_url,'>Provisional Letter</a>','') INTO new_letter_url FROM dual;		--remove the trailing part

	:NEW.cert_url := '<a href=' || new_letter_url || '>Provisional Letter</a>';
	
end if;

end;
/
ALTER TRIGGER UPD_EVALREPORT_URL ENABLE;





CREATE TABLE equipments (	
	equipmentid 		integer primary key,
	equipmenttypeid		integer references equipmenttypes,
	make				varchar(120),
	model				varchar(120),
	suppliername		varchar(240),
	
	suppliername		varchar(240),
	supplierbox			varchar(240),
	suppliertelno		varchar(240),
	supplieremail		varchar(240),
	supplieraddress		varchar(240),

	status				varchar(50),
	outputpower			varchar(50),
	powertoantenna		varchar(50),
	tolerance			varchar(50),

	carrieroutputpower			varchar(50),
	duplexspacing			varchar(50),
	adjacentchannelspacing	varchar(50),

	channelcapacity		varchar(50),
	systemdeviation		varchar(50),		--for digital
	biterrorrate		varchar(50),		--for digital

	conductedspurious		varchar(200),
	radiatedspurious		varchar(200),
	audioharmonicdistortion	varchar(200),
	emmissiondesignation	varchar(200),

	operatingfrequencyband  varchar(200),
	rfbandwidth				varchar(200),
	ifbandwidth_3db			varchar(200),

	receiversensitivity				varchar(200),
	receiveradjacenstselectivity	varchar(200),
	desensitisation					varchar(200),

	fmnoise				varchar(200), 		--for analogue

	threshold			varchar(100),

	rffilterloss		varchar(200), 		--for analogue	

	actiondate			date default sysdate,		--date added
	userid				integer references users,	--user 

 	EQU_APPROVAL_STATUS VARCHAR2(1), 
	EQU_NAME 			VARCHAR2(50), 	
	EQU_MANUFACTURER 	VARCHAR2(50), 
	EQU_COUNTRY_ID 		VARCHAR2(2),
	EQU_TYPE 			VARCHAR2(1), 
	EQU_MOBILITY 		VARCHAR2(1), 
	EQU_SERVICE 		VARCHAR2(3), 
	EQU_OPERATION_MODE 	VARCHAR2(1), 
	EQU_REMARK1 		VARCHAR2(500), 
	EQU_TUNABILITY 		VARCHAR2(1), 
	EQU_CHANNEL_SEP 	NUMBER(22,8), 
	EQU_FREQ_STABILITY 	VARCHAR2(15), 
	EQU_TRANSMISSION_SYS VARCHAR2(1), 
	EQU_TVSYS_CODE 		VARCHAR2(2), 
	EQU_COLOUR_SYSTEM 	VARCHAR2(1), 
	EQU_LOW_PULSE_WIDTH NUMBER(6,2), 
	EQU_HIGH_PULSE_WIDTH NUMBER(6,2), 
	EQU_PULSE_WIDTH_UNIT VARCHAR2(1), 
	EQU_LOW_PULSE_REP NUMBER(9,0), 
	EQU_HIGH_PULSE_REP NUMBER(9,0), 
	EQU_ANALOG_DIGITAL VARCHAR2(1), 
	EQU_NUM_CHANNELS NUMBER(9,0), 
	EQU_MODULATION VARCHAR2(7), 
	EQU_BIT_PER_SEC VARCHAR2(50), 
	EQU_REMARK2 VARCHAR2(500), 
	EQU_POWER_TYPE VARCHAR2(2), 
	EQU_POWER_TO_ANT NUMBER(22,8), 			--power to antenna
	EQU_UNIT_POWER_ANT VARCHAR2(1), 
	EQU_SENSITIVITY NUMBER(5,1), 
	EQU_SENSIT_UNIT VARCHAR2(1), 
	EQU_SENSIT_TYPE VARCHAR2(1), 
	EQU_IF_BANDWIDTH NUMBER(22,8), 
	EQU_HARMO_ATTEN NUMBER(4,1), 
	EQU_COMMISSION VARCHAR2(50), 
	EQU_ID_CODE VARCHAR2(10), 
	EQU_STATUS VARCHAR2(2), 
	EQU_NAME_ADMINISTRATOR VARCHAR2(50), 
	EQU_APPROVAL_DATE DATE, 
	EQU_FEE NUMBER(22,2), 
	EQU_INVOICED NUMBER(1,0), 
	EQU_APPR_DEM_DATE DATE, 
	EQU_USER_ID NUMBER(9,0), 
	EQU_ANT_ID NUMBER(9,0), 
	EQU_REMARK3 VARCHAR2(500), 
	EQU_RX_LOW_FREQ NUMBER(22,8), 
	EQU_RX_HIGH_FREQ NUMBER(22,8), 
	EQU_TX_LOW_FREQ NUMBER(22,8), 
	EQU_TX_HIGH_FREQ NUMBER(22,8), 
	EQU_IMAGE VARCHAR2(1), 
	EQU_RISE_TIME NUMBER(6,2), 
	EQU_DECAY_TIME NUMBER(6,2), 
	EQU_MODULATION_GROUP VARCHAR2(5), 
	EQU_MODEL VARCHAR2(50), 
	EQU_SPURIOUS NUMBER(4,0), 
	EQU_STATION_CLASS VARCHAR2(2), 
	EQU_STATION_SERVICE VARCHAR2(9), 
	LAST_UPD_TIME DATE DEFAULT sysdate, 
	TARIFF_CODE NUMBER(10,0), 
	EQU_STEREOPHONIC VARCHAR2(9), 
	SERVER_SITE NUMBER, 
	EQU_MANUFACTURER_ADDRESS VARCHAR2(100), 
	EQU_REG_NUM NUMBER, 
	EQU_REG_DATE DATE, 
	EQU_INFO1 VARCHAR2(100), 
	EQU_INFO2 VARCHAR2(100), 
	EQU_INFO3 VARCHAR2(100), 
	EQU_START_DATE DATE, 
	EQU_TRANSMITTER_MASK VARCHAR2(150), 
	EQU_FKTB NUMBER, 
	EQU_ATPC NUMBER, 
	EQU_NFD1 NUMBER(3,1), 
	EQU_NFD2 NUMBER(3,1), 
	EQU_DESENSIT NUMBER(22,8), 
	EQU_NOISE_H_LEVEL NUMBER(22,8), 
	EQU_MOD_DEPTH VARCHAR2(15), 
	EQU_MAX_DEV NUMBER(22,8), 
	EQU_TX_MAX_DEV NUMBER(22,8), 
	EQU_TX_MOD_DEPTH VARCHAR2(15), 
	EQU_ADJ_CHANNEL NUMBER(22,8),		--adjuscent channel spacing
	details clob
);
CREATE INDEX equipments_equipmentid ON equipments (equipmenttypeid);
CREATE SEQUENCE equipments_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_equipment_id BEFORE INSERT ON equipments
for each row 
begin     
	if inserting then 
		if :NEW.equipmentid  is null then
			SELECT equipments_id_seq.nextval into :NEW.equipmentid  from dual;
		end if;
	end if; 
end;
/

create table tempirisequipment(
	tempirisequipmentid integer primary key,
	Status varchar(100),
	ID varchar(100),	
	Name varchar(100),
	Model varchar(100),	
	Manufacturer varchar(100),	
	Servicekind	varchar(100),
	Typeofservice varchar(100),	
	TxLowFrequency varchar(100),	
	TxHighFrequency varchar(100),
	Typeofequipment varchar(100),	
	Vendor varchar(100),
	TransmitPower varchar(100),	
	Mobility varchar(100),	
	OperationMode varchar(100),	
	NeccesaryBandwidth varchar(100),
	details clob																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																	
);


CREATE SEQUENCE tempirisequipment_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_tempirisequipment_id BEFORE INSERT ON tempirisequipment
for each row 
begin     
	if inserting then 
		if :NEW.tempirisequipmentid  is null then
			SELECT tempirisequipment_id_seq.nextval into :NEW.tempirisequipmentid  from dual;
		end if;
	end if; 
end;
/


CREATE TABLE sites (

	siteid integer primary key, 	
	addressid integer references addresses, 
	sitecode varchar(10),
	sitename VARCHAR(30), 

	sitelongitude numeric(10,6), 	--decimal format
	sitelatitude numeric(10,6), 	--decimal format

	longitudedegrees real,
	longitudeminutes real,
	longitudeseconds real,

	latitudedegrees real,
	latitudeminutes real,
	latitudeseconds real,
	
	latitudepositionid integer references latitudeposition,

	location varchar2(100),
	SIT_ASL numeric(7,2), 
	SIT_REMARK VARCHAR(2000), 
	SIT_TEL_DESC VARCHAR(50), 
	SIT_FAX_DESC VARCHAR(50), 
	LAST_UPD_TIME DATE DEFAULT sysdate, 
	SERVER_SITE numeric, 
	SIT_FRAGMENT VARCHAR(5), 
	SIT_AREA VARCHAR(100),
	serviceradius real,	
	
	lrnumber VARCHAR(50)
);
CREATE SEQUENCE sites_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 3000;
CREATE OR REPLACE TRIGGER tr_site_id BEFORE INSERT ON sites
for each row 
begin     
	if inserting then 
		if :NEW.siteid  is null then
			SELECT sites_id_seq.nextval into :NEW.siteid  from dual;

			--
			:NEW.sitelongitude := (:NEW.longitudedegrees * 1) + (:NEW.longitudeminutes/60) + (:NEW.longitudeseconds/3600);
			:NEW.sitelatitude := (:NEW.latitudedegrees * 1) + (:NEW.latitudeminutes/60) + (:NEW.latitudeseconds/3600);
			
		end if;
	end if; 
end;
/

--longitude update
CREATE OR REPLACE TRIGGER tr_site_update BEFORE UPDATE ON sites
for each row 
begin     
	if updating then 				
		--convert to Decimal degrees
		:NEW.sitelongitude := (:NEW.longitudedegrees * 1) + (:NEW.longitudeminutes/60) + (:NEW.longitudeseconds/3600);
		:NEW.sitelatitude := (:NEW.latitudedegrees * 1) + (:NEW.latitudeminutes/60) + (:NEW.latitudeseconds/3600);					
	end if; 
end;
/




CREATE TABLE latitudeposition (
	latitudepositionid integer primary key,
	latitudeposition char(1)
	);
insert into latitudeposition values(1,'N');
insert into latitudeposition values(2,'S');




--to be corrected - site code
set scan off;
create or replace view vwmergedsites as 
	select sites.siteid as siteid,sites.sitecode, sites.sitename,sites.lrnumber as lrnumber, sites.serviceradius as serviceradius, (sites.longitudedegrees || ' Deg ' ||sites.longitudeminutes || ' Min ' || sites.longitudeseconds || ' Sec') as sitelongitude,(sites.latitudedegrees || ' Deg ' ||sites.latitudeminutes || ' Min ' || sites.latitudeseconds || ' Sec') AS sitelatitude,sites.location, sites.sit_asl, upper(sites.sitename || ' : ' || sites.sitecode || ' @ ' || sites.location) as sitesummary,sites.sitelongitude as longitude, sites.sitelatitude as latitude, ('<a href="map.html?Lat=' || trim(sites.sitelatitude) || '&Long=' || trim(sites.sitelongitude) ||  '" target="_blank"> Map </a>') as maplink, 
  ('Code:' || sites.sitecode || '<br>Long:' || sites.sitelongitude || '<br>Lat:' || sites.sitelatitude) as sitedetail
	from sites
UNION
	select sms_site.sit_id as siteid,null as sitecode,substr(sms_site.sit_name,0,instr(sms_site.sit_name,' ')) as sitename, sms_site.lr_number as lrnumber, sms_site.service_radius as serviceradius,to_char(sms_site.sit_longitude) as sitelongitude, to_char(sms_site.sit_latitude) as sitelatitude, sms_site.sit_area as location, sms_site.sit_asl,upper(sms_site.sit_name || ' @ ' || sms_site.sit_area) as sitesummary,sit_longitude as longitude, sit_latitude as latitude , ('<a href="map.html?Lat=' || trim(sms_site.sit_latitude) || '&Long=' || trim(sms_site.sit_longitude) ||'" target="_blank"> Map </a>') as maplink, 
  ('Code:' || '<br>Long:' || sit_longitude || '<br>Lat:' || sit_latitude) as sitedetail
	from sms_site;


CREATE TABLE vesseltypes (
	vesseltypeid integer primary key,
	vesseltypename varchar(100),
	details clob
);
CREATE SEQUENCE vesseltypes_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_vesseltype_id BEFORE INSERT ON vesseltypes
for each row 
begin     
	if inserting then 
		if :NEW.vesseltypeid is null then
			SELECT vesseltypes_id_seq.nextval into :NEW.vesseltypeid from dual;
		end if;
	end if; 
end;
/


--IMPORT TEMP
--p2p import
CREATE TABLE linkimport (	
	linkimportid 		integer primary key,

	servicecode			varchar(50),
	linknumber			varchar(50),
	linkname			varchar(50),

	siteacode			varchar(50),
	siteaname			varchar(50),
	sitealongitude		varchar(50),
	sitealatitude		varchar(50),
	siteaantennaheight	varchar(50),
	siteaantennapolarization	varchar(50),
	siteaequipment		varchar(50),
	
	sitebcode			varchar(50),
	sitebname			varchar(50),
	siteblongitude		varchar(50),
	siteblatitude		varchar(50),
	sitebantennaheight	varchar(50),
	sitebantennapolarization	varchar(50),
	sitebequipment		varchar(50),
	region				varchar(50),

	txfrequency			varchar(50),		--w.r.t A
	rxfrequency			varchar(50),		--w.r.t A
	linkconfig			varchar(50),
	linkcapacity		varchar(50),		--mbps
	linkbandwidth		varchar(50),		--MHz
	operatingband		varchar(50),		--GHz
	usofactor			varchar(50),
	details				varchar(100)
	
);
CREATE SEQUENCE linkimportid_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_linkimport_id BEFORE INSERT ON linkimport
for each row 
begin     
	if inserting then 
		if :NEW.linkimportid is null then
			SELECT linkimportid_seq.nextval into :NEW.linkimportid from dual;
		end if;
	end if; 
end;
/

--Fixed Wireless Import
CREATE TABLE fwimport (	
	fwimportid 		integer primary key,

	servicecode			varchar(50),
	sitenumber			varchar(50),
	sitename			varchar(50),
	sitecode 			varchar(10),

	sitelongitude		varchar(50),
	sitelatitude		varchar(50),

	serviceradius		varchar(50),
	cellradius			varchar(50),

	numberofsectors		varchar(50),
	trxpersector		varchar(50),

	region			varchar(50),

	erp					varchar(50),
	uplink				varchar(50),
	downlink			varchar(50),
	bandwidth			varchar(50),

	antennatype			varchar(50),
	antennaheight		varchar(50),
	azimuth				varchar(50),
	antennapolarization	varchar(50),
	
	details				varchar(100)
	
);
CREATE SEQUENCE fwimportid_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_fwimport_id BEFORE INSERT ON fwimport
for each row 
begin     
	if inserting then 
		if :NEW.fwimportid is null then
			SELECT fwimportid_seq.nextval into :NEW.fwimportid from dual;
		end if;
	end if; 
end;
/

--stationfee assumption: VHF only. NB VHF starts from 30 MHz
CREATE OR REPLACE VIEW vwdeclarationimport AS
	SELECT declarationimportid, servicecode, make, model, serialnumber, outputpower, frequency, location, isfine, isscheduled, decode(cast(outputpower as int),25,'Base',10,'Mobile',5,'Portable','Undefined') as stationtype,
	decode(cast(outputpower as int),25,5000,10,2900,5,2900,-1) * (length(frequency) - length(replace(frequency,',',null))+1)  as stationfee
	FROM declarationimport;


--declaration import
CREATE TABLE declarationimport (	
	declarationimportid 	integer primary key,
	servicecode				varchar(50),	--identifies the clientlicenseid ie the application id

	make			varchar(50),
	model			varchar(50),
	serialnumber 	varchar(20),

	outputpower 	varchar(50),
	frequency 		varchar(50),
	location 		varchar(50),

	vendorname				varchar(200),
	vendoraddress			varchar(100),
	technicalpersonnelname		varchar(200),
	technicalpersonnel_license	varchar(50),		--licesenumber

	isscheduled			char(1) default '0',		--has it been scheduled for inspection ?	
	isfine				char(1) default '0',				--power and location matches an existing station
	isunmatched			char(1) default '0',				--redundant ???????

	details				varchar(100)	
);
CREATE SEQUENCE declarationimportid_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_declarationimport_id BEFORE INSERT ON declarationimport
for each row 
begin     
	if inserting then 
		if :NEW.declarationimportid is null then
			SELECT declarationimportid_seq.nextval into :NEW.declarationimportid from dual;
		end if;
	end if; 
end;
/


--PROCESS POINT 2 POINT IMPORT
CREATE OR REPLACE FUNCTION processp2pimport return varchar is
	PRAGMA AUTONOMOUS_TRANSACTION;
		
	linkseq	integer;
	siteseq integer;
	stationseq integer;

	firstrow integer;		--id of the first row;

begin

	--discard the header row
	select min(linkimportid) into firstrow from linkimport;
	commit;
	delete from linkimport where linkimportid = firstrow;	
	commit;

	FOR rec_import IN (SELECT * FROM linkimport) LOOP

		--insert links	(pending:clientlicenseid)
		--insert into stationsimport(clientlicenseid, licensepriceid, servicenatureid, stationname, isrural, requestedfrequency, requestedbandwidth,
		insert into stations(clientlicenseid, licensepriceid, servicenatureid, stationname, isrural, requestedfrequency, requestedbandwidth, capacity_mpbs, numberoffrequencies, requestedspotfrequencies, path_length_km, proposed_operation_date, location)
				values(cast(rec_import.servicecode as integer),25, 'CV', rec_import.linkname, decode(rec_import.usofactor,'1.0','0','0.5','1'), (cast(rec_import.operatingband as real)*1000), (cast(rec_import.linkbandwidth as real)*1000),
				rec_import.linkcapacity, 2, (rec_import.txfrequency || 'MHz ' || rec_import.rxfrequency || 'MHz'), null, null, rec_import.region);
				commit;
    
		--get this link's id
		select max(stationid) into linkseq from stations;


--START A
    
		--add sites (pending:coordinates)
		--Site A
		--insert into sitestemp(sitecode, sitename, longitudedegrees, longitudeminutes,longitudeseconds,latitudedegrees, latitudeminutes, latitudeseconds)
		insert into sites(sitecode, sitename, longitudedegrees, longitudeminutes,longitudeseconds,latitudedegrees, latitudeminutes, latitudeseconds)  
				values(rec_import.siteacode, rec_import.siteaname, cast(substr(rec_import.sitealongitude,1,2) as real),cast(substr(rec_import.sitealongitude,4,2) as real),cast(substr(rec_import.sitealongitude,6,6) as real),
        cast(substr(rec_import.sitealatitude,1,2) as real),cast(substr(rec_import.sitealatitude,4,2) as real),cast(substr(rec_import.sitealatitude,6,6) as real));
				commit;
		--get this site's id
		select max(siteid) into siteseq from sites;

		--Station A				
		--insert into stationsimport(transmitstationid,siteid,servicenatureid,stationname)
		insert into stations(transmitstationid,siteid,servicenatureid,stationname)
			values(linkseq, siteseq,'CV', rec_import.siteaname);
			commit;
		--get this stations id
		select max(stationid) into stationseq from stations;
	
		--Station A - Equipment			
		insert into stationequipment(stationid,equipmentid) values(stationseq,1);
		commit;
			
		--Station A - Antenna
		insert into stationantenna(antennatypeid,stationid,height,polarization) values(1,stationseq,rec_import.SITEAANTENNAHEIGHT,rec_import.SITEAANTENNAPOLARIZATION);      
		commit;
			
--START B   
    
		--Site B
		--insert into sitestemp(sitecode, sitename, longitudedegrees, longitudeminutes,longitudeseconds,latitudedegrees, latitudeminutes, latitudeseconds)
		insert into sites(sitecode, sitename, longitudedegrees, longitudeminutes,longitudeseconds,latitudedegrees, latitudeminutes, latitudeseconds)  
				values(rec_import.sitebcode, rec_import.sitebname, cast(substr(rec_import.siteblongitude,1,2) as real),cast(substr(rec_import.siteblongitude,4,2) as real),cast(substr(rec_import.siteblongitude,6,6) as real),
        cast(substr(rec_import.siteblatitude,1,2) as real),cast(substr(rec_import.siteblatitude,4,2) as real),cast(substr(rec_import.siteblatitude,6,6) as real));
				commit;
		--get this site's id
		select max(siteid) into siteseq from sites;

		--Station B			
		insert into stations(transmitstationid,siteid,servicenatureid,stationname)
			values(linkseq, siteseq,'CV', rec_import.sitebname);
			commit;								
		--get this stations id
		select max(stationid) into stationseq from stations;
	
		--Station B - Equipment			
		insert into stationequipment(stationid,equipmentid) values(stationseq,1);
		commit;
		
		--Station B - Antenna
		insert into stationantenna(antennatypeid,stationid,height,polarization) values(1,stationseq,rec_import.SITEBANTENNAHEIGHT,rec_import.SITEBANTENNAPOLARIZATION);      
		commit;
		
    -- END B
		
	END LOOP;

	--???
	delete from linkimport;
	commit;

	return 'Link Import OK';


EXCEPTION
	WHEN OTHERS THEN
		delete from linkimport;
		commit;
		--raise_application_error(-20015,'Invalid Characters Found in Excel file. Please Correct and try again.');
		--RETURN 'Data contained invalid characters. Please Correct and try again';
end;
/




CREATE OR REPLACE FUNCTION processFWimport return varchar is
	PRAGMA AUTONOMOUS_TRANSACTION;
	
	siteseq integer;
	stationseq integer;

begin

	FOR rec_import IN (SELECT * FROM fwimport) LOOP

		--SITE	(append clientname on site name)
		insert into sitestemp(sitename, location, longitudedegrees, longitudeminutes,longitudeseconds,latitudedegrees, latitudeminutes, latitudeseconds)  
				values(rec_import.sitename, rec_import.region, 5.0, 5.0, 5.0, 6.0, 6.0, 6.0);
				commit;
		--get this site's id
		select max(siteid) into siteseq from sitestemp;

		--Station A				
		--insert into stationsimport(transmitstationid,siteid,servicenatureid,stationname)
		insert into stationsimport(clientlicenseid,siteid,licensepriceid,servicenatureid,stationname,requestedbandwidth,requestedfrequency,numberoffrequencies,serviceradius)
			values(cast(rec_import.servicecode as integer), siteseq, 36, 'CV', rec_import.sitename,cast(rec_import.bandwidth as real), cast(rec_import.uplink as real), cast(rec_import.trxpersector as real), cast(rec_import.serviceradius as real));
			commit;
		--get this stations id
		select max(stationid) into stationseq from stationsimport;
	
		--Station A - Equipment			
		insert into stationequipment(stationid,equipmentid) values(stationseq,1);
		commit;
		
		--Station A - Antenna
		insert into stationantenna(antennatypeid, stationid, height, azimuth, polarization) 
			values(1, stationseq, rec_import.antennaheight, rec_import.azimuth, rec_import.antennapolarization);      
		commit;
				
	END LOOP;

	return 'FW Import OK';

end;
/


create or replace view vwdeclaredstations as
	select stations.stationid, stations.transmitstationid, (stations.requestedfrequency/1000) as requestedfrequency, stations.clientlicenseid, 
	stations.requestedfrequencyGHz, stations.requestedbandwidth, stations.vehicleregistration, licenseprices.stationclassid, licenseprices.typename, 
	stations.stationcallsign, equipments.make, equipments.model, stationequipment.equipmentserialno, stationequipment.carrieroutputpower, stations.isdeclared,
	equipments.suppliername, sites.location as sitelocation,vwclientlicenses.clientname, vwclientlicenses.address, vwclientlicenses.town, vwclientlicenses.postalcode,
	vwclientlicenses.applicationdate,vwclientlicenses.licenseid, vwclientlicenses.licensename, vhfnetwork.vhfnetworkid, vhfnetwork.vhfnetworkname, vhfnetwork.vhfnetworklocation, decode(stationequipment.carrieroutputpower,5,'PORTABLE',10,stations.vehicleregistration,coalesce(stations.location,vhfnetwork.vhfnetworklocation)) as location,
	vwclientlicenses.filenumber, round(stations.stationcharge) as stationcharge,	vwclientlicenses.offersentdate, vwclientlicenses.currentphase, 
	vwclientlicenses.clientid, proratedChargePeriod(current_date) as chargedmonths, round(stationinitialcharge(stations.stationid, current_date)) as proratedcharge
	from stations 
	inner join vwclientlicenses on stations.clientlicenseid = vwclientlicenses.clientlicenseid
	left join vhfnetwork on stations.vhfnetworkid = vhfnetwork.vhfnetworkid
	left join stationequipment on stations.stationid =  stationequipment.stationid
	left join equipments on stationequipment.equipmentid = equipments.equipmentid
	inner join licenseprices on stations.licensepriceid = licenseprices.licensepriceid	
	left join sites on stations.siteid = sites.siteid
	where isterrestrial = '0';



CREATE OR REPLACE FUNCTION processDeclarationImport return varchar is
	PRAGMA AUTONOMOUS_TRANSACTION;

	firstrow integer;		--id of the first row;

	--TYPE rec_sta_equip IS TABLE OF stationequipment%ROWTYPE;  old syntax ????
	--rec_station vwdeclaredstations%ROWTYPE;
	sta_id INTEGER;
	cli_lic_id INTEGER;
	out_power VARCHAR(50);
	loc     VARCHAR(50);
	--error_count int;

begin
	
	--discard the header row
	select min(declarationimportid) into firstrow from declarationimport;
	commit;
	delete from declarationimport where declarationimportid = firstrow;	
	commit;
	
	--error_count := 0;
	
	--dbms_output.put_line('At Begin');
	FOR rec_import IN (SELECT * FROM declarationimport) LOOP	--read all declared stations in the table (imported from the excelfile)
		
		select max(stationid)
			--clientlicenseid, carrieroutputpower,
			--decode((substr(typename,0,instr(typename,' ')-1)),'Portable','Portable',coalesce(vehicleregistration,coalesce(location, (substr(typename,0,instr(typename,' ')-1))))) as location 
			--into rec_station
			into sta_id			--, cli_lic_id, out_power, loc
			from vwdeclaredstations
			where vwdeclaredstations.clientlicenseid = cast(rec_import.servicecode as int)
			and CAST(vwdeclaredstations.carrieroutputpower AS INT) = CAST(rec_import.outputpower AS INT)
			and UPPER(vwdeclaredstations.location) like UPPER(rec_import.location)
			and vwdeclaredstations.isdeclared = '0';      
				
			if(sta_id is not null) then
				
				update declarationimport set isfine = '1' where declarationimportid = rec_import.declarationimportid;
				commit;
				
				update stations set isdeclared = '1' where stationid = sta_id;
				commit;					
				
				update stationequipment set equipmentserialno = rec_import.serialnumber where stationid = sta_id;
				commit;
					
				--delete gud records
				delete from declarationimport where declarationimportid = rec_import.declarationimportid;
				commit;
				
			else
				--a station belonging to this client and license (ie clientlicense) that has no matching entry in the stations table for this particular client and license
				update declarationimport set isunmatched = '1' where declarationimportid = rec_import.declarationimportid and servicecode = rec_import.servicecode;
-- 				commit;
			end if;
		--END IF;
				
		--dbms_output.put_line('Exiting the Loop');
	END LOOP;
	
  --if (error_count = 0 )	then
    --dbms_output.put_line( 'Returning');
    --delete from declarationimport;
    --commit;
  --end if;
  
	return 'Declaration Import OK';
  
end;
/





CREATE TABLE radiobroadcastingtype(
	radiobroadcastingtypeid	integer primary key,
	radiobroadcastingtype 	varchar(10),
	details					clob	
	);

create or replace view vwchannelassignments as
	select frequencys.frequencyid, clients.clientid, clients.clientname, frequencys.stationid, frequencys.isreserved, frequencys.isactive, licenses.licensename,licenses.licenseid, coalesce(vhfnetwork.vhfnetworkname,'Default Network') as networkname, coalesce(coalesce(coalesce(vhfnetwork.vhfnetworklocation,stations.location),vwmergedsites.location),'UNDEFINED') as stationlocation,
		   channelplan.channelplanid, channelplan.channelplanname, channel.channelid, channel.channelnumber, channel.subbandname, channel.itu_reference, channel.channelspacing, coalesce(channel.duplexspacing,0) as duplexspacing, frequencys.txfrequency, frequencys.LAST_UPD_TIME,
		   stations.transmitstationid, stations.stationname, stations.forexport, stations.requestedfrequencyGHz, stations.numberoffrequencies, stations.vesselname, stations.imonumber, stations.grosstonnage, stations.aircraftname, stations.aircrafttype, stations.aircraftregno, stations.path_length_km,
		   licenseprices.typename, channel.transmit, channel.receive, coalesce(channel.unitsofmeasure,'') as unitsofmeasure, clientlicenses.clientlicenseid, licenses.isterrestrial, countbase(stations.clientlicenseid) as fixed, countportable(stations.clientlicenseid) as portables, countmobile(stations.clientlicenseid) as mobiles
	from frequencys
	inner join channel on frequencys.channelid = channel.channelid
	inner join channelplan on channel.channelplanid = channelplan.channelplanid
	inner join stations on frequencys.stationid = stations.stationid
	inner join clientlicenses on stations.clientlicenseid = clientlicenses.clientlicenseid
	inner join clients on clientlicenses.clientid = clients.clientid
	inner join licenses on clientlicenses.licenseid = licenses.licenseid
	inner join licenseprices on stations.licensepriceid = licenseprices.licensepriceid
	left join vhfnetwork on stations.vhfnetworkid = vhfnetwork.vhfnetworkid
	left join vwmergedsites on stations.siteid = vwmergedsites.siteid;

CREATE TABLE duplexmethod(
	duplexmethodid 		integer primary key,
	duplexmethod		varchar(50),
	details 			clob
	);

CREATE TABLE stations (	
	stationid 			integer primary key,
	licensepriceid		integer references licenseprices,
	servicenatureid		char(2) references servicenature, 
	vhfnetworkid		integer references vhfnetwork,			--vhf networks have to be grouped to simplify freq assignment
	transmitstationid	integer references stations,			--may refer to the link(station) in case of terrestrials 
	clientlicenseid		integer references clientlicenses, 
	trunkedradiotypeid			integer references trunkedradiotype,
	duplexmethodid		integer,		--references duplexmethod

	siteid		 		integer references sites,
	userid				integer references users,
	
	radiobroadcastingtypeid		integer references radiobroadcastingtype,

	istransmitter			char(1) default '0',
	isactive				char(1) default '1',		--means not decomissioned
	decommissiondate		date,

	stationname				VARCHAR(100), 
	numberofreceivers		integer default 0,
	requestedfrequencybands	varchar(250),
	numberoffrequencies 	integer default 1,

	extranumberoffrequencies 	integer default 0,	--insert into another table and clear this field once approval has been obtained
	
	--b4 training
	requestedspotfrequencies 	varchar(500),

	--frequency band requested 
	requestedfrequency 		real,		--in MHz	
	requestedfrequencyGHz	real,		--in GHz

	requestedbandwidth		real,		--in KHz
	requestedbandwidthMHz	real,		--in MHz
	requestedbandwidthGHz	real,		--in GHz
	
	NOMINALTXPOWER				REAL,		--the nominal transmitter power
	EFFECTIVETXPOWER			REAL,		--the effective isotropicaly radiated power


	unitsrequested			integer default 1,

	unitsapproved		integer default 1,
	stationcallsign		varchar(100),	
	isaircraft			char(1) default '0',
	location			varchar(50),
	feedertype			varchar(50),
	feederloss			varchar(50),
	attenuation			varchar(50),

	max_operation_hours			varchar(20),
	path_length_km				real,
	serviceradius				real,
	proposed_operation_date 	date,
	transmit_ant_type			varchar(50),
	transmit_ant_height				varchar(50),
	transmit_ant_relative_height	varchar(50),

	AIRCRAFTNAME		VARCHAR2(100),
	AIRCRAFTTYPE		VARCHAR2(100),
	AIRCRAFTREGNO		VARCHAR2(100),	

	VESSELTYPEID		integer references vesseltypes,
	VESSELNAME			VARCHAR2(100),
	IMONumber			VARCHAR2(100),
	GROSSTONNAGE		REAL,	
	DECODERCAPACITY		REAL,

	vehicleregistration			varchar(500),					--for mobiles fitted on vehicles
	transmit_ant_directivity	varchar2(100),
	transmit_ant_azimuth		varchar(50),
	transmit_ant_beam_width		varchar(50),
	transmit_ant_gain_dbi		varchar(50),
	
	stationcharge				real,					--full station charge without considering proration. used in annual payment
	proratedcharge				real,					--prorated charge. used in initial payment
	initialchargeperiod			int,					--if >= 12 months, payment includes next period's

	capacity_mpbs			varchar(50),
	isrural					char(1) default '0',
	forexport				char(1) default '0',
	isdeclared				char(1) default '0',

	numberofsectors			integer default 1,
	txpersector				integer default 1,

	--VSAT
	--capacity of earth stations
	vsatlrnumber		varchar(50),
	carriertxfreq		real,	--MHz
	carrierrxreq		real,	--MHz
	bitratetx			real,	--kbps
	bitraterx			real,	--kbps
	bwtx				real,	--MHz
	bwrx				real,	--MHz
	--physical parameters
	vsatlatdegrees		real,
	vsatlatminutes		real,
	vsatlatseconds		real,
	vsatlongdegrees		real,
	vsatlongminutes		real,
	vsatlongseconds		real,
	altitude			real,			--meters
	antennashape		varchar(50),	--circular, square, etc
	antennaarea			real,			--square meters
	--antenna xstics
	isotropicgaindBi	real,
	beamwidthdegrees		real,
	beamwidthminutes		real,
	beamwidthseconds		real,
	elevation1degrees		real,
	elevation1minutes		real,
	elevation1seconds		real,
	azimuth2degrees		real,
	azimuth2minutes		real,
	azimuth2seconds		real,	
	meanaltitude		real,
	polartype			varchar(20),
	polardirection		varchar(20),
	EIRPdBW				real default 0,		--power

	STA_TOWER 			VARCHAR(9), 
	STA_CALL_SIGN 		VARCHAR(100), 
	STA_CLASS 			VARCHAR(5), 
	STA_OPERATION_CLASS VARCHAR(1), 
	STA_TYPE 			VARCHAR(1), 
	STA_FEE 			numeric(22,2), 
	STA_OPER_HOURS 		VARCHAR(3), 
	STA_PRIV_ANT 		numeric(1,0), 
	STA_ANT_ID 			numeric(9,0), 
	STA_LOSSES 			numeric(6,2), 
	STA_LONGITUDE 		numeric(10,6), 
	STA_LATITUDE 		numeric(10,6), 
	STA_ASL 			numeric(7,2), 
	STA_RADIUS 			numeric(5,1), 
	STA_POWER 			numeric(15,6), 
	STA_AGL 			numeric(5,1), 
	STA_AZIMUTH 		numeric(7,2), 
	STA_ANGLE_ELEV 		numeric(5,1), 
	STA_POLARIZATION 	VARCHAR(4), 
	STA_START_TIME 		numeric(13,6), 
	STA_STOP_TIME 		numeric(13,6), 
	STA_DATE_BITU 		DATE, 
	STA_DATE_EOU 		DATE, 
	STA_REMARK 			VARCHAR(50), 
	STA_MEMO 			VARCHAR(2000), 
	STA_ANT_GAIN 		numeric(6,2), 
	STA_TRANSMIT_POWER 	numeric(22,8), 
	STA_FRAGMENT 		VARCHAR(9), 
	STA_NOT_MODIFY 		numeric(1,0), 
	STA_POWER_RATIO 	numeric(6,2), 
	STA_STABILITY_CODE 	VARCHAR(2), 
	STA_OFFSET_CODE 	VARCHAR(4), 
	STA_OFFSET_FREQ 	numeric(22,8), 
	STA_OFFSET_TYPE 	VARCHAR(1), 
	STA_VA_COORD 		VARCHAR(1), 
	STA_VA_ACHIEVE_COORD DATE, 
	STA_FREQ_CATEGORY 	VARCHAR(1), 
	STA_CATEGORY_USE 	VARCHAR(2), 
	STA_VA_REG_STA 		VARCHAR(50), 
	STA_VA_stationid 	numeric(10,0), 
	STA_VA_STA_RADIUS 	numeric(6,0), 
	STA_VA_STA_LOW_FREQ numeric(22,8), 
	STA_VA_STA_HIGH_FREQ numeric(22,8), 
	STA_VA_DEGREE 			numeric(4,1), 
	STA_VA_REMARK 			VARCHAR(155), 
	STA_PERMANENT 			numeric(1,0), 
	LAST_UPD_TIME 			DATE DEFAULT current_date, 
	TARIFF_CODE 		numeric(10,0), 
	STA_ERP 			numeric(13,4), 
	SERVER_SITE 		numeric, 
	STATUS 				VARCHAR(2), 
	APPROVED_DATE 		DATE, 
	STA_VA_NATURE_OF_USE 			VARCHAR(10), 
	STA_VA_INITIAL_COORD_REQUEST	DATE, 
	STA_VA_STA_RX_LOW_FREQ 			numeric(22,8), 
	STA_VA_STA_RX_HIGH_FREQ 		numeric(22,8), 
	STA_VA_COORDINATES 	VARCHAR(20), 
	STA_VA_7A 			VARCHAR(20), 
	STA_REG_MARK 		VARCHAR(100), 
	STA_SPECIAL_TYPE 	VARCHAR(100), 
	STA_VEHICLE_NUM 	VARCHAR(50), 
	STA_OPER_AREA1 		VARCHAR(100), 
	STA_OPER_AREA2 		VARCHAR(100), 
	STA_OPER_AREA3 		VARCHAR(100), 
	STA_OPER_AREA4 		VARCHAR(100), 
	STA_INFO1 			VARCHAR(100), 
	STA_INFO2 			VARCHAR(100), 
	STA_INFO3 			VARCHAR(100), 
	STA_HEF 			numeric(10,2), 
	STA_AREA 			VARCHAR(50), 
	STA_EQUIP_SERIAL 	VARCHAR(25),
	STA_ANTENNA_TYPE 	VARCHAR(100),
	STA_ANTENNA_HEIGHT 				NUMBER,
	STA_ANTENNA_RELATIVE_HEIGHT 	NUMBER,
	STA_ANTENNA_DIRECTIVITY 		VARCHAR(100),
	STA_ANTENNA_AZIMUTH 			NUMBER,
	STA_ANTENNA_ANGULAR_BEAM_WIDTH 	NUMBER,
	STA_ANTENNA_GAIN_DBI 			NUMBER,
	remarks							clob,
	DETAILS							CLOB
);



CREATE SEQUENCE stations_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_stationid_id BEFORE INSERT ON stations
for each row 

declare
	
	unitfee real;		--for 8.5 khz bandwidth
	k1 real;
	k2 real;
	val real;
	Pnom real;
	Ptot real;
	weightingfactor real;
	spectrumfee real;
	usagefee real;
	spectrummanagementcost real;
	n int;
	radiotype int;      --1 for PAMR and 2 for PMR	
	dummy int;

	CURSOR licenseprices_cur IS
		SELECT licenseprices.licensepriceid, licenseprices.licenseid, licenseprices.stationclassid, licenseprices.hasfixedcharge,
			licenseprices.typename, licenseprices.amount, licenseprices.unitgroups, licenseprices.onetimefee, 
			licenseprices.perlicense, licenseprices.perstation, licenseprices.perfrequency, 
			licenseprices.functname, licenseprices.formula, licenses.initialfee, licenses.annualfee					
		FROM licenseprices 
		INNER JOIN LICENSES ON licenseprices.licenseid = licenses.licenseid
		WHERE licensepriceid = :NEW.licensepriceid;
		rc licenseprices_cur%ROWTYPE;

begin     
	if inserting then 
		IF :NEW.stationid is null THEN
			--insert the pk
			SELECT stations_id_seq.nextval into :NEW.stationid  from dual;			

			--insert the proposed operational date
			IF (:NEW.proposed_operation_date is null) THEN
				:NEW.proposed_operation_date := current_date;
			END IF;


			--Convert requested Frequency/Band default is MHz
			if (:new.requestedfrequency is null and :new.requestedfrequencyGHz is not null) then
				:new.requestedfrequency := :new.requestedfrequencyGHz * 1000;
			elsif(:new.requestedfrequencyGHz is null and :new.requestedfrequency is not null) then
				:new.requestedfrequencyGHz := :new.requestedfrequency/1000;
			end if;

			--Convert requested Bandwidth     default is KHz
			if(:new.requestedbandwidth is null and :new.requestedbandwidthMHz is not null) then
				:new.requestedbandwidth := :new.requestedbandwidthMHz * 1000;  --convert to KHz
				:new.requestedbandwidthGHz := :new.requestedbandwidthMHz/1000;  --convert to GHz
			elsif(:new.requestedbandwidth is null and :new.requestedbandwidthGHz is not null) then
				:new.requestedbandwidth := :new.requestedbandwidthGHz * 1000 * 1000; --convert to KHz
				:new.requestedbandwidthMHz := :new.requestedbandwidthGHz * 1000;
			elsif(:new.requestedbandwidth is not null) then
				:new.requestedbandwidthMHz := :new.requestedbandwidth / 1000;  --convert to MHz
				:new.requestedbandwidthGHz := :new.requestedbandwidthMHz/1000;  --convert to GHz
			end if;




			--if clientlicenseid is null also and transmitstationid is NOT null... 
			--...this is a receiver station or terminal/repeater in a link
			--implication -> NOT CHARGED			
			IF (:NEW.clientlicenseid is null) AND (:NEW.transmitstationid is not null) THEN		
				--house keeping
				:NEW.unitsapproved := :NEW.unitsrequested;	--by default we approve all units requested
				--use clientlicenseid from transmitter (or link for p2p)
				SELECT clientlicenseid INTO :NEW.clientlicenseid FROM stations WHERE stationid = :NEW.transmitstationid;				
				--reflect the number of receivers on the transmiting station				
								
				UPDATE stations set numberofreceivers = numberofreceivers + :NEW.unitsapproved WHERE stationid = :NEW.transmitstationid;

				--these r not charged
				:NEW.stationcharge := 0;
				:NEW.proratedcharge := 0;
			END IF;
			
			--if its a transmitter (or link in p2p)
			IF (:NEW.clientlicenseid is not null) AND (:NEW.transmitstationid is null) THEN		--a transmitter or link

				:NEW.initialchargeperiod := proratedChargePeriod(:NEW.proposed_operation_date);
				n := :NEW.unitsrequested;	

				OPEN licenseprices_cur;
				FETCH licenseprices_cur INTO rc;
				
				IF (rc.hasfixedcharge = '1') THEN
					:NEW.proratedcharge := rc.initialfee;
					:NEW.stationcharge := rc.annualfee;
					RETURN;
				END IF;
	


				--alarm values including unitsapproved, stationcharge and proratedcharge will be available from clientstations
				IF (rc.functname = 'alarms') THEN
				
-- 					val := n;
-- 					
-- 					WHILE (mod(val,5) != 0) --max is not divisible by 5
-- 						LOOP
-- 							val := val + 1;						
-- 						END LOOP;					
-- 
-- 					:NEW.unitsapproved := val;
-- 
-- 					:NEW.stationcharge := 1250 * val;
-- 					:NEW.proratedcharge := :NEW.stationcharge;

					RETURN;
				END IF;


				IF (rc.functname = 'point2point') THEN		--fixed station

					unitfee := 574.10;

					IF(:NEW.REQUESTEDFREQUENCY < 1700)THEN
						K1 := 0.6;
					END IF;

					IF((:NEW.REQUESTEDFREQUENCY >= 1700) AND (:NEW.REQUESTEDFREQUENCY < 10000))THEN
						K1 := 0.5;
					END IF;

					IF(:NEW.REQUESTEDFREQUENCY > 10000)THEN
						K1 := 0.4;
					END IF;

					:NEW.stationcharge := ((:NEW.requestedbandwidth/8.5)*(:NEW.numberoffrequencies)) * k1 * unitfee;					
					
					--if rural 50% discount
					IF(:NEW.isrural = '1')THEN
						:NEW.stationcharge := :NEW.stationcharge/2;
					END IF;

					:NEW.proratedcharge := :NEW.stationcharge * :NEW.initialchargeperiod/12;

					RETURN;

				END IF;

				IF (rc.functname = 'singlechannel') THEN		--fixed station

					unitfee := 1043.65;
					

					:NEW.stationcharge := (:NEW.requestedbandwidth/8.5) * unitfee;					
					
					--if rural 50% discount
-- 					IF(:NEW.isrural = '1')THEN
-- 						:NEW.stationcharge := :NEW.stationcharge/2;
-- 					END IF;

					:NEW.proratedcharge := :NEW.stationcharge * :NEW.initialchargeperiod/12;

					RETURN;

				END IF;


				IF (rc.functname = 'point2multipoint') THEN		--fixed station

					spectrummanagementcost := 100000;				

					--units MHz
					IF(:NEW.REQUESTEDFREQUENCY < 1000)THEN		
						k1 := 0.8;
					END IF;
					IF((:NEW.REQUESTEDFREQUENCY >= 1000) AND (:NEW.REQUESTEDFREQUENCY < 6000))THEN		
						k1 := 0.7;
					END IF;
					IF((:NEW.REQUESTEDFREQUENCY >= 6000) AND (:NEW.REQUESTEDFREQUENCY < 10000))THEN		
						k1 := 0.6;
					END IF;
					IF((:NEW.REQUESTEDFREQUENCY >= 10000) AND (:NEW.REQUESTEDFREQUENCY < 20000))THEN		
						k1 := 0.5;
					END IF;
					IF(:NEW.REQUESTEDFREQUENCY > 20000)THEN		
						k1 := 0.4;
					END IF;

					--usagefee := spectrummanagementcost * n * k1 * :new.requestedbandwidthMHz/1.75;

					:NEW.stationcharge := spectrummanagementcost * n * k1 * :new.requestedbandwidthMHz/1.75;
					:NEW.proratedcharge := :NEW.stationcharge * :NEW.initialchargeperiod/12;

					RETURN;

				END IF;

				IF (rc.functname = 'cellular') THEN

					unitfee := 1043.65;
					weightingfactor := 6;

					spectrummanagementcost := 43000;			--annual spectrum management cost				

					n := :new.numberoffrequencies;

					--1. exclusive spectrum bandwidth assignment fee this is applicable for each client for each financial period
					--spectrumfee := ((:NEW.requestedbandwidth * weightingfactor * unitfee)/8.5); -- + spectrummanagementcost;
					spectrumfee := 0;

					
					if(:new.requestedfrequencyGHz != 0.9 and :new.requestedfrequencyGHz != 1.8 and :new.requestedfrequencyGHz != 2.1) then
						raise_application_error(-20011,'Only 2G (0.9 or 1.8) and 3G (2.1) allowed');
					elsif(:new.requestedfrequencyGHz = 0.9 or :new.requestedfrequencyGHz = 1.8) then		--2G
						usagefee := spectrummanagementcost * n;		--here we dont divide by 200 KHz
					elsif (:new.requestedfrequencyGHz = 2.1) then										--3G
						usagefee := spectrummanagementcost * n * :new.requestedbandwidthMHz/5;
					end if;


					--usagefee := spectrummanagementcost * n ;			--original formula 
					:NEW.stationcharge := (spectrumfee + usagefee);
					:NEW.proratedcharge := :NEW.stationcharge * :NEW.initialchargeperiod/12;

					RETURN;
					
				END IF;


			
				--fixed wireless access networks
				IF (rc.functname = 'fixedwireless') THEN

					unitfee := 1043.65;
					weightingfactor := 6;

					spectrummanagementcost := 100000;			--annual spectrum management cost				

					n := :new.numberoffrequencies;			--here n is the number of transmitters in this station - (assumption: all TXs use the same bw and freq)


					n = rfbw/1.75;

					--1. exclusive spectrum bandwidth assignment fee - STILL USED BY FSM ???
					--spectrumfee := ((:NEW.requestedbandwidth * weightingfactor * unitfee)/8.5);-- + spectrummanagementcost;
					spectrumfee := 0;

					--2. spectrum usage fee	
					IF(:NEW.REQUESTEDFREQUENCY < 1)THEN		--1000khz = 1Ghz
						k1 := 0.8;
					END IF;
					IF((:NEW.REQUESTEDFREQUENCY >= 1) AND (:NEW.REQUESTEDFREQUENCY < 6))THEN		
						k1 := 0.7;
					END IF;
					IF((:NEW.REQUESTEDFREQUENCY >= 6) AND (:NEW.REQUESTEDFREQUENCY < 10))THEN		
						k1 := 0.6;
					END IF;
					IF((:NEW.REQUESTEDFREQUENCY >= 10) AND (:NEW.REQUESTEDFREQUENCY < 20))THEN		
						k1 := 0.5;
					END IF;

					0.4 (20-30)
					0.3 (>30)

					IF(:NEW.REQUESTEDFREQUENCY > 20000)THEN		
						k1 := 0.4;
					END IF;
					
					--am using n to stand for the total number of transmitter but fsm planning team use n to refer to rfbw/1.75MHz for each tx
					--
					usagefee := spectrummanagementcost * n * k1 * (:new.requestedbandwidthMHz/1.75);

					--if TDD divide charge by two
					if (:new.duplexmethodid = 2) then
						usagefee := usagefee/2;
					end if;

					:NEW.stationcharge := (spectrumfee + usagefee);
					:NEW.proratedcharge := :NEW.stationcharge * :NEW.initialchargeperiod/12;

					RETURN;

				END IF;

							
				IF (rc.functname = 'trunkedradionetwork') THEN
								
					spectrummanagementcost := 43000;			--annual spectrum management cost				

					--n := :new.requestedbandwidth/25;				--'n is the actual or equivalent number of 25KHz duplex transmitters in use at the end of the year in preview'
					n := :new.numberoffrequencies;			--here n is the number of transmitters in this station - (assumption: all TXs use the same bw and freq)

					--1. exclusive spectrum bandwidth assignment fee - STILL USED BY FSM ???
					--spectrumfee := ((:NEW.requestedbandwidth * weightingfactor * unitfee)/8.5);-- + spectrummanagementcost;
					spectrumfee := 0;

					--2. spectrum usage fee						
					IF(:NEW.trunkedradiotypeid = 1 )THEN		
						k1 := 1;
					ELSIF(:NEW.trunkedradiotypeid = 2)THEN
						k1 := 3.5;
					END IF;
					
					--fsm planning team use n to refer to rfbw/25KHz for each tx
				
					usagefee := spectrummanagementcost * n * k1;
				
					:NEW.stationcharge := (spectrumfee + usagefee);
					:NEW.proratedcharge := :NEW.stationcharge * :NEW.initialchargeperiod/12;

					RETURN;

				END IF;


				--only non terrestrial stations will reach here
				IF (:NEW.transmitstationid is null) THEN	--if its a transmitter
					--actual process
					IF (rc.perstation = '1') THEN
						:NEW.stationcharge := rc.amount * :NEW.unitsrequested;
					END IF;

					IF (rc.perfrequency = '1') THEN
						:NEW.stationcharge := :NEW.stationcharge * :NEW.numberoffrequencies;				
					END IF;						
				END IF;

			END IF;			--end - if transmitter

		end if;		--end - if stationid is null
		
		--finally prorate them except alarm systems
		IF (rc.typename = 'Alarm Units') THEN
			:NEW.proratedcharge := :NEW.stationcharge;				--unreachable code segment
		END IF;

		IF (rc.typename != 'Alarm Units') THEN
			--finaly prorate them starting from the proposed_operation_date
			:NEW.proratedcharge := :NEW.stationcharge * :NEW.initialchargeperiod/12;
		END IF;

	end if; --end - if inserting



--EXCEPTION
--	WHEN OTHERS THEN
--    raise_application_error(-20010,'UNKNOWN ERROR');
		--RETURN 'ERROR';

end;
/


--BEFORE UPDATE ON STATIONS
create or replace TRIGGER tr_update_station BEFORE UPDATE ON stations
for each row 

declare
	
	unitfee real;		--for 8.5 khz bandwidth
	k1 real;
	k2 real;
	val real;
	Pnom real;
	Ptot real;
	weightingfactor real;
	spectrumfee real;
	usagefee real;
	spectrummanagementcost real;
	n int;
	radiotype int;      --1 for PAMR and 2 for PMR	
	dummy int;
	bwKHz real;				--VSAT bandwidth
	fprice real;


	CURSOR licenseprices_cur IS
		SELECT licenseprices.licensepriceid, licenseprices.licenseid, licenseprices.stationclassid, licenseprices.hasfixedcharge,
			licenseprices.typename, licenseprices.amount, licenseprices.unitgroups, licenseprices.onetimefee, 
			licenseprices.perlicense, licenseprices.perstation, licenseprices.perfrequency, 
			licenseprices.functname, licenseprices.formula, licenses.initialfee, licenses.annualfee					
		FROM licenseprices 
		INNER JOIN LICENSES ON licenseprices.licenseid = licenses.licenseid
		WHERE licensepriceid = :NEW.licensepriceid;
		rc licenseprices_cur%ROWTYPE;

begin     
	if updating then 
		IF :NEW.stationid is not null THEN		--NOT
			--insert the pk
			--SELECT stations_id_seq.nextval into :NEW.stationid  from dual;			

			--insert the proposed operational date
			IF (:NEW.proposed_operation_date is null) THEN
				:NEW.proposed_operation_date := current_date;
			END IF;
			
			--Convert requested Frequency/Band
			if (:new.requestedfrequency is null and :new.requestedfrequencyGHz is not null) then
				:new.requestedfrequency := :new.requestedfrequencyGHz * 1000;
			elsif(:new.requestedfrequencyGHz is null and :new.requestedfrequency is not null) then
				:new.requestedfrequencyGHz := :new.requestedfrequency/1000;
			end if;


			--Convert requested Bandwidth     default is KHz
			if(:new.requestedbandwidthMHz is not null) then
 				:new.requestedbandwidth := :new.requestedbandwidthMHz * 1000;  --convert to KHz
 				:new.requestedbandwidthGHz := :new.requestedbandwidthMHz/1000;  --convert to GHz
			end if;

-- 			if(:new.requestedbandwidth is null and :new.requestedbandwidthMHz is not null) then
-- 				:new.requestedbandwidth := :new.requestedbandwidthMHz * 1000;  --convert to KHz
-- 				:new.requestedbandwidthGHz := :new.requestedbandwidthMHz/1000;  --convert to GHz
-- 			elsif(:new.requestedbandwidth is null and :new.requestedbandwidthGHz is not null) then
-- 				:new.requestedbandwidth := :new.requestedbandwidthGHz * 1000 * 1000; --convert to KHz
-- 				:new.requestedbandwidthMHz := :new.requestedbandwidthGHz * 1000;
-- 			elsif(:new.requestedbandwidth is not null) then
-- 				:new.requestedbandwidthMHz := :new.requestedbandwidth / 1000;  --convert to MHz
-- 				:new.requestedbandwidthGHz := :new.requestedbandwidthMHz/1000;  --convert to GHz
			end if;


			--if clientlicenseid is null also and transmitstationid is NOT null... 
			--...this is a receiver station or terminal/repeater in a link
			--implication -> NOT CHARGED			
			IF (:NEW.clientlicenseid is null) AND (:NEW.transmitstationid is not null) THEN		
				--house keeping
				:NEW.unitsapproved := :NEW.unitsrequested;	--by default we approve all units requested
				--use clientlicenseid from transmitter (or link for p2p)
				SELECT clientlicenseid INTO :NEW.clientlicenseid FROM stations WHERE stationid = :NEW.transmitstationid;				
				--reflect the number of receivers on the transmiting station				
								
				UPDATE stations set numberofreceivers = numberofreceivers + :NEW.unitsapproved WHERE stationid = :NEW.transmitstationid;

				--these r not charged
				:NEW.stationcharge := 0;
				:NEW.proratedcharge := 0;
			END IF;
			
			--if its a transmitter (or link in p2p)
			IF (:NEW.clientlicenseid is not null) AND (:NEW.transmitstationid is null) THEN		--a transmitter or link

				:NEW.initialchargeperiod := proratedChargePeriod(:NEW.proposed_operation_date);
				n := :NEW.unitsrequested;	

				OPEN licenseprices_cur;
				FETCH licenseprices_cur INTO rc;
				
				IF (rc.hasfixedcharge = '1') THEN
					:NEW.proratedcharge := rc.initialfee;
					:NEW.stationcharge := rc.annualfee;
					RETURN;
				END IF;
	
				--alarm values including unitsapproved, stationcharge and proratedcharge will be available from clientstations
				IF (rc.functname = 'alarms') THEN
				
-- 					val := n;
-- 					
-- 					WHILE (mod(val,5) != 0) --max is not divisible by 5
-- 						LOOP
-- 							val := val + 1;						
-- 						END LOOP;					
-- 
-- 					:NEW.unitsapproved := val;
-- 
-- 					:NEW.stationcharge := 1250 * val;
-- 					:NEW.proratedcharge := :NEW.stationcharge;

					RETURN;
				END IF;


				IF (rc.functname = 'point2point') THEN		--fixed station

					unitfee := 574.10;

					IF(:NEW.REQUESTEDFREQUENCY < 1700)THEN
						K1 := 0.6;
					END IF;

					IF((:NEW.REQUESTEDFREQUENCY >= 1700) AND (:NEW.REQUESTEDFREQUENCY < 10000))THEN
						K1 := 0.5;
					END IF;

					IF(:NEW.REQUESTEDFREQUENCY > 10000)THEN
						K1 := 0.4;
					END IF;

					:NEW.stationcharge := ((:NEW.requestedbandwidth/8.5)*(:NEW.numberoffrequencies)) * k1 * unitfee;					
					
					--if rural 50% discount
					IF(:NEW.isrural = '1')THEN
						:NEW.stationcharge := :NEW.stationcharge/2;
					END IF;

					:NEW.proratedcharge := :NEW.stationcharge * :NEW.initialchargeperiod/12;

					RETURN;

				END IF;


				IF (rc.functname = 'point2multipoint') THEN		--fixed station

					spectrummanagementcost := 100000;				

					--units MHz
					IF(:NEW.REQUESTEDFREQUENCY < 1000)THEN		
						k1 := 0.8;
					END IF;
					IF((:NEW.REQUESTEDFREQUENCY >= 1000) AND (:NEW.REQUESTEDFREQUENCY < 6000))THEN		
						k1 := 0.7;
					END IF;
					IF((:NEW.REQUESTEDFREQUENCY >= 6000) AND (:NEW.REQUESTEDFREQUENCY < 10000))THEN		
						k1 := 0.6;
					END IF;
					IF((:NEW.REQUESTEDFREQUENCY >= 10000) AND (:NEW.REQUESTEDFREQUENCY < 20000))THEN		
						k1 := 0.5;
					END IF;
					IF(:NEW.REQUESTEDFREQUENCY > 20000)THEN		
						k1 := 0.4;
					END IF;

					--usagefee := spectrummanagementcost * n * k1 * :new.requestedbandwidthMHz/1.75;

					:NEW.stationcharge := spectrummanagementcost * n * k1 * :new.requestedbandwidthMHz/1.75;
					:NEW.proratedcharge := :NEW.stationcharge * :NEW.initialchargeperiod/12;

					RETURN;

				END IF;

				IF (rc.functname = 'cellular') THEN

					unitfee := 1043.65;
					weightingfactor := 6;

					spectrummanagementcost := 43000;			--annual spectrum management cost				

					n := :new.numberoffrequencies;

					--1. exclusive spectrum bandwidth assignment fee this is applicable for each client for each financial period
					--spectrumfee := ((:NEW.requestedbandwidth * weightingfactor * unitfee)/8.5); -- + spectrummanagementcost;
					spectrumfee := 0;

					
					if(:new.requestedfrequencyGHz != 0.9 and :new.requestedfrequencyGHz != 1.8 and :new.requestedfrequencyGHz != 2.1) then
						raise_application_error(-20011,'Only 2G (0.9 or 1.8) and 3G (2.1) allowed');
					elsif(:new.requestedfrequencyGHz = 0.9 or :new.requestedfrequencyGHz = 1.8) then		--2G
						usagefee := spectrummanagementcost * n;		--here we dont divide by 200 KHz
					elsif (:new.requestedfrequencyGHz = 2.1) then										--3G
						usagefee := spectrummanagementcost * n * :new.requestedbandwidthMHz/5;
					end if;


					--usagefee := spectrummanagementcost * n ;			--original formula 
					:NEW.stationcharge := (spectrumfee + usagefee);
					:NEW.proratedcharge := :NEW.stationcharge * :NEW.initialchargeperiod/12;

					RETURN;
					
				END IF;

			
				--fixed wireless access networks
				IF (rc.functname = 'fixedwireless') THEN

					unitfee := 1043.65;
					weightingfactor := 6;

					spectrummanagementcost := 100000;			--annual spectrum management cost				

					n := :new.numberoffrequencies;			--here n is the number of transmitters in this station - (assumption: all TXs use the same bw and freq)

					--1. exclusive spectrum bandwidth assignment fee - STILL USED BY FSM ???
					--spectrumfee := ((:NEW.requestedbandwidth * weightingfactor * unitfee)/8.5);-- + spectrummanagementcost;
					spectrumfee := 0;

					--2. spectrum usage fee	
					IF(:NEW.REQUESTEDFREQUENCY < 1000)THEN		--1000khz = 1Ghz
						k1 := 0.8;
					END IF;
					IF((:NEW.REQUESTEDFREQUENCY >= 1000) AND (:NEW.REQUESTEDFREQUENCY < 6000))THEN		
						k1 := 0.7;
					END IF;
					IF((:NEW.REQUESTEDFREQUENCY >= 6000) AND (:NEW.REQUESTEDFREQUENCY < 10000))THEN		
						k1 := 0.6;
					END IF;
					IF((:NEW.REQUESTEDFREQUENCY >= 10000) AND (:NEW.REQUESTEDFREQUENCY < 20000))THEN		
						k1 := 0.5;
					END IF;
					IF(:NEW.REQUESTEDFREQUENCY > 20000)THEN		
						k1 := 0.4;
					END IF;
					
					--am using n to stand for the total number of transmitter but fsm planning team use n to refer to rfbw/1.75MHz for each tx					
					usagefee := spectrummanagementcost * n * k1 * (:new.requestedbandwidthMHz/1.75);

					--if TDD divide charge by two
					if (:new.duplexmethodid = 2) then
						usagefee := usagefee/2;
					end if;

					:NEW.stationcharge := (spectrumfee + usagefee);
					:NEW.proratedcharge := :NEW.stationcharge * :NEW.initialchargeperiod/12;

					RETURN;

				END IF;


				IF (rc.functname = 'vsat') THEN

					--k1 log ((pnom/25) + k2log(eirp-100)/25) * bandwidthtx/8.5 * 574.10
					unitfee := 574.10;
					k1 := 1;
					k2 := 0.2;
					Pnom := 1000;					 
					--convert power in dBW to Watts
					select power(10,(:NEW.EIRPdBW/10)) into Ptot from dual;  --power(m,n) where m is the base and n is the exponent. ie 3 raised to 2 is power(3,2) 

					IF(:NEW.bwtx > :NEW.bwrx)THEN
						bwKHz := :NEW.bwtx * 1000;
					ELSE
						bwKHz := :NEW.bwrx * 1000;
					END IF;
							
					--:NEW.stationcharge := (k1 * log((Pnom/25),10) + (k2 * log(((Ptot-1000)/25),10))) * (bwKHz/8.5) * unitfee;	
					select ((1 * log(10,(Pnom/25)) + (k2 * log(10,(Ptot-1000)/25))) * (bwKHz/8.5) * 574.10) into :NEW.stationcharge from dual;									
					--:NEW.proratedcharge := :NEW.stationcharge * :NEW.initialchargeperiod/12;          
					RETURN; 
				END IF;
			END IF;


				--only non terrestrial stations will reach here
				IF (:NEW.transmitstationid is null) THEN	--if its a transmitter
					--actual process
					IF (rc.perstation = '1') THEN
						:NEW.stationcharge := rc.amount * :NEW.unitsrequested;
					END IF;

					IF (rc.perfrequency = '1') THEN
						:NEW.stationcharge := :NEW.stationcharge * :NEW.numberoffrequencies;				
					END IF;						

        END IF;			--end - if transmitter

		end if;		--end - if stationid is null
		
		--finally prorate them except alarm systems
		IF (rc.typename = 'Alarm Units') THEN
			:NEW.proratedcharge := :NEW.stationcharge;				--unreachable code segment
		END IF;

		IF (rc.typename != 'Alarm Units') THEN
			--finaly prorate them starting from the proposed_operation_date
			:NEW.proratedcharge := :NEW.stationcharge * :NEW.initialchargeperiod/12;
		END IF;

	end if; --end - if inserting



--EXCEPTION
--	WHEN OTHERS THEN
--    raise_application_error(-20010,'UNKNOWN ERROR');
		--RETURN 'ERROR';

end;



/*
create or replace function insertStations(transmitterid in varchar, servicenatureid in varchar) return integer is
begin
		insert into stations(licensepriceid,transmitstationid,servicenatureid,stationname)
				values(0,cast(transmitterid as integer),cast(servicenatureid as integer),'TX');		
		insert into stations(licensepriceid,transmitstationid,servicenatureid,stationname)
				values(0,cast(transmitterid as integer),cast(servicenatureid as integer),'RX');		
		return 0;
end;
/
*/




--for annual payments
create or replace function calculateannualcharge(sta_id in varchar2) return real is

	CURSOR stations_cur IS
		SELECT clientlicenseid, stationid, initialchargeperiod, stationcharge, proratedcharge			
		FROM stations 
		WHERE stationid = cast(sta_id as int);
		rec_stations stations_cur%ROWTYPE;

begin
		OPEN stations_cur;
		FETCH stations_cur INTO rec_stations;

		if(rec_stations.initialchargeperiod <= 3)then		--it means he has already paid for next year
			return 0;
		end if;

		--if(rec_stations.initialchargeperiod >= 12)then
		return rec_stations.stationcharge;			--this is an implicit else		
		--end if;
		
		--return rec_stations.proratedcharge;		--this is an implicit else		
		
end;
/





CREATE VIEW VWSITES AS 
select stations.stationid, stations.stationname, stations.clientlicenseid, sites.siteid, sites.sitename, sites.sitelongitude, sites.sitelatitude, sites.location, sites.sit_asl,
	sites.lrnumber,sites.serviceradius
	from stations
	inner join sites on stations.siteid = sites.siteid;
 



create or replace view vwpostoffice as 
	select postofficeid, postalcode, postofficename, (substr(postalcode,0,5) || ' - ' || postofficename) as summary
	from postoffice;


--deprecated ???
--TRIGGER before update on stations
--if updating(ie ok to continue) if receiver...update unitsapproved if unitsapproved was changed
-- CREATE OR REPLACE TRIGGER tr_updUnitsApproved BEFORE UPDATE ON stations
-- for each row 
-- begin     
-- 	if updating then 
-- 		if(:NEW.transmitstationid is not null) then
-- 				--house keeping						
-- 				UPDATE stations set unitsapproved = :NEW.unitsapproved WHERE stationid = :NEW.transmitstationid;			
-- 		end if;
-- 	end if; 
-- end;
-- /

-- --increment number of receivers
-- CREATE OR REPLACE TRIGGER tr_INC_RECEIVERS AFTER INSERT ON STATIONS
-- for each row 
-- begin     	
-- 		--if its a receiver station..
-- 		-- increment numberofreceivers on the transmitstation by one
-- 		IF (:NEW.clientlicenseid is null) AND (:NEW.transmitstationid is not null) THEN
-- 			UPDATE stations SET numberofreceivers = (numberofreceivers + 1) WHERE stationid = :NEW.transmitstationid;
-- 		end if;
-- 	
-- end;
-- /
-- 
-- --deccrement number of receivers
-- CREATE OR REPLACE TRIGGER tr_DEC_RECEIVERS AFTER DELETE ON STATIONS
-- for each row 
-- begin     	
-- 		--if its a receiver station..
-- 		-- decrement numberofreceivers on the transmitstation by one
-- 		IF (:NEW.clientlicenseid is null) AND (:NEW.transmitstationid is not null) THEN
-- 			UPDATE stations SET numberofreceivers = (numberofreceivers - 1) WHERE stationid = :NEW.transmitstationid;
-- 		end if;
-- 	
-- end;
-- /



CREATE TABLE emmissiondesignation(
	emmissiondesignationid 	integer primary key,
	stationequipmentid 		integer references stationequipment,	--
	AIRCRAFTEQUIPMENTID 	integer , --references aircraftequipemnt
	stationid				integer references stations,		--use this to get the station equipment [for stations that can only have one equip]
	userid					integer references users,

	bandwidthcodeid			varchar(5),

	modulationtypecode		char(1) references modulationtype(code),					--first symbol
	natureofsignalcode		char(1) references natureofsignal(code),					--second
	typeofinformationcode	char(1) references typeofinformation(code),					--third
	signaldetailcode		char(1) references signaldetail(code),					--fourth
	muxnaturecode			char(1) references muxnature(code),					--fifth	
	
	details					clob
	);
CREATE SEQUENCE emmissiondesignation_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_emmissiondesignation_id BEFORE INSERT ON emmissiondesignation
for each row 
begin     
	if inserting then 
		if :NEW.emmissiondesignationID  is null then
			SELECT emmissiondesignation_id_seq.nextval into :NEW.emmissiondesignationID  from dual;
		end if;
	end if; 
end;
/


create table modulationtype(
	modulationtypeid		integer primary key,
	modulationtype			varchar(500),
	code					char(1) unique,
	details					varchar(100)
	);

CREATE OR REPLACE VIEW vwmodulationtype AS
	select code, modulationtype, (code || ': ' || modulationtype) as summary
	from modulationtype;
insert into modulationtype values(1,'Unmodulated carrier','N');
insert into modulationtype values(2,'Amplitude modulated - Double sideband','A');
insert into modulationtype values(3,'Amplitude modulated - Single sideband full carrier','H');
insert into modulationtype values(4,'Amplitude modulated - Single sideband reduced or variable level carrier','R');
insert into modulationtype values(5,'Amplitude modulated - Single sideband suppressed carrier','J');
insert into modulationtype values(6,'Amplitude modulated - Independent sidebands','B');
insert into modulationtype values(7,'Amplitude modulated - Vestigial sideband','C');
insert into modulationtype values(8,'Angle modulated - Frequency modulation','F');
insert into modulationtype values(9,'Angle modulated - Phase modulation','G');
insert into modulationtype values(10,'Emission in which the main carrier is amplitude- and angle-modulated either simultaneously or in a pre-established sequence','D');
insert into modulationtype values(11,'Emmission of Pulses - unmodulated','P');
insert into modulationtype values(12,'Sequence of pulses - modulated in amplitude','K');
insert into modulationtype values(13,'Sequence of pulses - modulated in width-duration','L');
insert into modulationtype values(14,'Sequence of pulses - modulated in position-phase','M');
insert into modulationtype values(15,'Sequence of pulses - main carrier is angle-modulated during the angle period of the pulse','Q');
insert into modulationtype values(16,'Sequence of pulses - which is a combination of the foregoing or is produced by other means','V');
insert into modulationtype values(17,'Cases not covered above in which an emission consists of the main carrier modulated either simultaneously or in a pre-established sequence or a combination of the two or more of the following modes amplitude angle or pulse','W');
insert into modulationtype values(18,'Cases not otherwise covered','X');


create table natureofsignal(
	natureofsignalid		integer primary key,
	natureofsignal		varchar(200),
	code					char(1) unique,
	details					varchar(100)
	);
CREATE OR REPLACE VIEW vwnatureofsignal AS
	select code, natureofsignal, (code || ': ' || natureofsignal) as summary
	from natureofsignal;
insert into natureofsignal values(1,'No modulating signal','O');
insert into natureofsignal values(2,'A single channel containing quantized or digital information without the use of a modulating sub-carrier','1');
insert into natureofsignal values(3,'A single channel containing quantized or digital information with the use of a modulating sub-carrier','2');
insert into natureofsignal values(4,'A single channel containing analogue information','3');
insert into natureofsignal values(5,'Two or more channels containing quantized or digital information','7');
insert into natureofsignal values(6,'Two or more channels containing analogue information','8');
insert into natureofsignal values(7,'Composite system with one or more channels containing quantized or digital information, together with one or more channels containing analogue information','9');
insert into natureofsignal values(8,'Cases not otherwise covered','X');



create table typeofinformation(
	typeofinformationid		integer primary key,
	typeofinformation		varchar(200),
	code					char(1) unique,
	details					varchar(100)
	);
CREATE OR REPLACE VIEW vwtypeofinformation AS
	select code, typeofinformation, (code || ': ' || typeofinformation) as summary
	from typeofinformation;

insert into typeofinformation values(1,'No information is transmitted','N');
insert into typeofinformation values(2,'Telegraphy - for aural reception','A');
insert into typeofinformation values(3,'Telegraphy - for automatic reception','B');
insert into typeofinformation values(4,'Fascimile','C');
insert into typeofinformation values(5,'Data transmission telemetry telecommand','D');
insert into typeofinformation values(6,'Telephony - including sound broadcasting','E');
insert into typeofinformation values(7,'Television - video','F');
insert into typeofinformation values(8,'Combination of the above','W');
insert into typeofinformation values(10,'Cases not otherwise covered','X');



create table signaldetail(
	signaldetailid		integer primary key,
	signaldetail		varchar(500),
	code				char(1) unique,
	details					varchar(100)
	);
CREATE OR REPLACE VIEW vwsignaldetail AS
	select code, signaldetail, (code || ': ' || signaldetail) as summary
	from signaldetail;

insert into signaldetail values(1,'Two-condition code with elements of differing numbers and durations','A');
insert into signaldetail values(2,'Two-condition code with elements of the same number and duration without error-correction','B');
insert into signaldetail values(3,'Two-condition code with elements of the same number and duration with error-correction','C');
insert into signaldetail values(4,'Four-condition code in which each condition represents a signal element - one or more bits','D');
insert into signaldetail values(5,'Multi-condition code in which each condition represents a signal element - one or more bits','E');
insert into signaldetail values(6,'Multi-condition code in which each condition or combination of conditions represents a character','F');
insert into signaldetail values(7,'Sound of broadcasting quality - monophonic','G');
insert into signaldetail values(8,'Sound of broadcasting quality - stereophonic or quadrophonic','H');

insert into signaldetail values(9,'Sound of commercial quality - excluding K and L','J');
insert into signaldetail values(10,'Sound of commercial quality with the use of frequency inversion or band splitting','K');
insert into signaldetail values(11,'Sound of commercial quality with separate frequency-modulated signals to control the level of demodulated signal','L');
insert into signaldetail values(12,'Monochrome','M');
insert into signaldetail values(13,'Color','N');

insert into signaldetail values(14,'Combination of above','W');
insert into signaldetail values(15,'Cases not otherwise covered','X');


create table muxnature(
	muxnatureid		integer primary key,
	muxnature		varchar(200),
	code			char(1) unique,
	details					varchar(100)
	);
CREATE OR REPLACE VIEW vwmuxnature AS
	select code, muxnature, (code || ': ' || muxnature) as summary
	from muxnature;

insert into muxnature values(1,'None','N');
insert into muxnature values(2,'Code division multiplex','C');
insert into muxnature values(3,'Frequency division multiplex','F');
insert into muxnature values(4,'Time division multiplex','T');
insert into muxnature values(5,'Combination of frequency division multiplex and time division multiplex','W');
insert into muxnature values(6,'Other types of multiplexing','X');




CREATE OR REPLACE FUNCTION encodeBW(bw in varchar) RETURN varchar IS
PRAGMA AUTONOMOUS_TRANSACTION;

	bandwidth varchar(20);
	bwlength integer;
  
	bwnumber float;
	bwencoded varchar(10);  
  
	pos integer;
    
BEGIN	

	--ITU stuff
	--btwn 0.001 and 999Hz shall eb expressed in Hz (H) - 
	--btwn 1.00 and 999KHz shall be expressed in KHz (K)
	--btn 1.00 and 999MHz shall be expressed in MHz (M)
	--btwn 1.00 and 999GHz shall be expressed in GHz (G)

	--NB: all the above in four characters

	--cases to consider: 
	--1: btwn 0.000001 and 0.000999 MHz
	--2: btwn 0.001 and 0.999 MHz
	--3: btwn 1.00 and 999 MHz
	--4: btwn 1000 and 999000 MHz
	--ignoring less than 1 Hz

  bandwidth := bw;
  select cast(bandwidth as float) into bwnumber from dual;

 
  --btwn 1 Hz and 999 Hz
  if(bandwidth >= 0.000001 and bandwidth <=0.000999) then		
	 --if btwn 1Hz and 9Hz
    if(bandwidth >= 0.000001 and bandwidth <=0.000009) then			
      select (substr(bandwidth,8,1) || 'H' || coalesce(substr(bandwidth,9,1),'0') || coalesce(substr(bandwidth,10,1),'0')  ) into bwencoded from dual;      
    --if btwn 10 and 99 Hz
    elsif(bandwidth >= 0.00001 and bandwidth <=0.00009) then			
      select (substr(bandwidth,7,1) || coalesce(substr(bandwidth,8,1),'0') || 'H' || coalesce(substr(bandwidth,9,1),'0')) into bwencoded from dual;    
    --if btwn 100 and 999 Hz
    elsif(bandwidth >= 0.0001 and bandwidth <=0.0009) then			
      select (substr(bandwidth,6,1) || coalesce(substr(bandwidth,7,1),'0') || coalesce(substr(bandwidth,8,1),'0') || 'H') into bwencoded from dual;    
    end if;
  end if;

  --btwn 1 Khz and 999 Khz
  if(bandwidth >= 0.001 and bandwidth <=0.999) then	    
    --if btwn 1KHz and 9KHz
    if(bandwidth >= 0.001 and bandwidth <=0.009) then			
      select (substr(bandwidth,5,1) || 'K' || coalesce(substr(bandwidth,6,1),'0') || coalesce(substr(bandwidth,7,1),'0')) into bwencoded from dual;      
    --if btwn 10 and 99 KHz
    elsif(bandwidth >= 0.01 and bandwidth <=0.09) then			
      select (substr(bandwidth,4,1) || coalesce(substr(bandwidth,5,1),'0') || 'K' || coalesce(substr(bandwidth,6,1),'0')) into bwencoded from dual;    
  --if btwn 100 and 999 KHz
    elsif(bandwidth >= 0.1 and bandwidth <=0.9) then			
      select (substr(bandwidth,3,1) || coalesce(substr(bandwidth,4,1),'0') || coalesce(substr(bandwidth,5,1),'0') || 'K') into bwencoded from dual;    
    end if;
  end if;
  
 --is there a dot ???
  --select instr(bandwidth,'.') into pos from dual; --check for .	

  if(bandwidth >= 1 and bandwidth <= 999) then	
    if (bandwidth >= 1 and bandwidth < 9) then					
      --if there is a decimal then take the third character
      select (substr(bandwidth,1,1) || 'M' || decode(instr(bandwidth,'.'),0,'0',substr(bandwidth,3,1)) || coalesce(substr(bandwidth,4,1),'0') ) into bwencoded from dual;
    elsif (bandwidth >= 10 and bandwidth < 99) then					
      select (substr(bandwidth,0,2) || 'M' || decode(instr(bandwidth,'.'),0,'0',substr(bandwidth,4,1))) into bwencoded from dual;  
    elsif (bandwidth >= 100 and bandwidth < 999) then
      select (bandwidth || 'M') into bwencoded from dual;
	end if;
  end if;
  
	--pending GHz bandwidth
  if(bandwidth >= 1000 and bandwidth <=999000) then	
	--then replace the . with M
    select replace(bandwidth,'.','G') into bwencoded from dual;    
  end if;
 
  
  return bwencoded;
  
EXCEPTION
	WHEN OTHERS THEN
		RETURN 'Invalid Bandwidth specified : ' || bw;
    
END;
/



--encode bw(given in MHz) 
CREATE OR REPLACE FUNCTION encodeBWOringinalNotWorking(bw in varchar) RETURN varchar IS
PRAGMA AUTONOMOUS_TRANSACTION;

	bandwidth varchar(20);
	bwlength integer;
  
	bwnumber float;
	bwencoded varchar(10);  
  
	pos integer;
    
BEGIN	

  bandwidth := bw;
  
  select instr(bandwidth,'M') into pos from dual; --check for Mega
  if pos=0 then --if no 'M' check for 'm'
    select instr(bandwidth,'m') into pos from dual; --check for 'm'
  end if;
  if pos=0 then --if no 'm' check for 'K'
    select instr(bandwidth,'K') into pos from dual; --check for Mega
  end if;  
  if pos=0 then --if no 'K' check for 'k'
    select instr(bandwidth,'k') into pos from dual; --check for Mega
  end if;
  
  --get the length  
  if(pos > 0) then  
    select substr(bandwidth,0,(length(bandwidth)-3)) into bandwidth from dual;    
	end if;
  
  --convert bandwidth to float
  select cast(bandwidth as float) into bwnumber from dual;
  --encode accordingly
	if (bwnumber < 1) then
		select replace(bandwidth,'.','K') into bwencoded from dual;    
	end if;
	if (bwnumber > 1) then
		 select replace(bandwidth,'.','M') into bwencoded from dual;
	end if;
	
  return bwencoded;
  
EXCEPTION
	WHEN OTHERS THEN
		RETURN 'Invalid input : ' || bw;
    
END;
/

CREATE OR REPLACE VIEW VWAIRCRAFTEQUIPMENT AS 
	select AIRCRAFTEQUIPMENT.*,vwmergedequipments.fullname,vwmergedequipments.model,vwmergedequipments.make
	from AIRCRAFTEQUIPMENT
	left join vwmergedequipments on AIRCRAFTEQUIPMENT.equipmentid = vwmergedequipments.equipmentid;



CREATE TABLE AIRCRAFTEQUIPMENT(
	AIRCRAFTEQUIPMENTID integer primary key,
	stationid 			integer references stations, 
	equipmentid			integer, 			--references equipments
	equiptype			varchar(100),
	equipmentserialno	varchar(100),
	outputpower			varchar(50),
	emmissiondesignation	varchar(200),
	rfbandwidth				varchar(50),
	callsign			varchar(100),
	details 			clob
	);
CREATE SEQUENCE AIRCRAFTEQUIPMENT_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_AIRCRAFTEQUIPMENT_id BEFORE INSERT ON AIRCRAFTEQUIPMENT
for each row 
begin     
	if inserting then 
		if :NEW.AIRCRAFTEQUIPMENTID  is null then
			SELECT AIRCRAFTEQUIPMENT_id_seq.nextval into :NEW.AIRCRAFTEQUIPMENTID  from dual;
		end if;
	end if; 
end;
/



--initial assumption : only one decoder
CREATE TABLE ALARMDECODER (
	ALARMDECODERID	integer primary key,
	clientlicenseid		integer references clientlicenses, 
	equipmentid			integer, 			--references equipments
	equipmentserialno	varchar2(100),
	rfbandwidth				varchar(50),
	details 			clob
	);
CREATE SEQUENCE ALARMDECODER_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_ALARMDECODER_id BEFORE INSERT ON ALARMDECODER
for each row 
begin     
	if inserting then 
		if :NEW.ALARMDECODERID  is null then
			SELECT ALARMDECODER_id_seq.nextval into :NEW.ALARMDECODERID  from dual;
		end if;
	end if; 
end;
/


--accomodates equipment on all kinds of stations: land, aircraft n ships
CREATE TABLE STATIONEQUIPMENT (
	STATIONEQUIPMENTID	integer primary key,
	stationid 			integer references stations, 
	equipmentid			integer, 			--references equipments
	equipmentserialno	varchar2(100),
	STE_ANT_ID 			NUMERIC(9,0), 
	STE_MAIN 			NUMERIC(1,0), 
	LAST_UPD_TIME 		DATE DEFAULT current_date, 
	SERVER_SITE			NUMERIC,

	suppliername		varchar(240),
	supplierbox			varchar(240),
	suppliertelno		varchar(240),
	supplieremail		varchar(240),
	supplieraddress		varchar(240),
	supplierfax			varchar(240),

	status				varchar(50),
	outputpower			varchar(50),
	tolerance			varchar(10),

	carrieroutputpower		varchar(100),
	duplexspacing			varchar(100),
	adjacentchannelspacing	varchar(100),
	powertoantenna			varchar(100),

	channelcapacity			varchar(50),
	systemdeviation			varchar(50),
	biterrorrate			varchar(50),
	conductedspurious		varchar(50),
	radiatedspurious		varchar(50),
	audioharmonicdistortion	varchar(200),
	emmissiondesignation	varchar(200),

	operatingfrequencyband  varchar(50),
	rfbandwidth				varchar(50),
	ifbandwidth_3db			varchar(50),
	receiversensitivity		varchar(200),
	receiveradjacenstselectivity	varchar(200),
	desensitisation			varchar(200),
	fmnoise				varchar(50),
	threshold			varchar(100),
	rffilterloss			varchar(50),

	isdeclared			char(1) not null default '0',
	
	requestedspotfrequencies 	varchar(500),

	details	 			clob
);
CREATE SEQUENCE STATIONEQUIPMENT_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_STATIONEQUIPMENT_id BEFORE INSERT ON STATIONEQUIPMENT
for each row 
begin     
	if inserting then 
		if :NEW.STATIONEQUIPMENTID  is null then
			SELECT STATIONEQUIPMENT_id_seq.nextval into :NEW.STATIONEQUIPMENTID  from dual;
		end if;
	end if; 
end;
/


	



CREATE TABLE antennatypes (
	antennatypeid		integer primary key,
	antennatypename	varchar(120),
	details				clob
);
CREATE SEQUENCE antennatypes_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_antennatype_id BEFORE INSERT ON antennatypes
for each row 
begin     
	if inserting then 
		if :NEW.antennatypeid  is null then
			SELECT antennatypes_id_seq.nextval into :NEW.antennatypeid  from dual;
		end if;
	end if; 
end;
/





CREATE TABLE STATIONANTENNA (
	STATIONANTENNAID	integer primary key,
	stationid 			integer references stations, 
	antennatypeid		integer references antennatypes, 
	
	antennadescr		varchar(50),	

	istransmitter		char(1) default '0',

	antennaname			varchar(50),
	antennamodel		varchar(50),
	antennamanufacturer	varchar(50),
	lowfrequency		real,		--not assigned here (misplaced)
	highfrequency		real,		--not assigned here
	polarization		char(2),		
	
	outputpower			real,

	height				real,
	relativeheight		real,
	directivity			varchar(50),

	azimuth				varchar(100),
	beam_width			varchar(100),
	maxgaindecibels		varchar(100),

	tilt				real,
	details				clob
);
CREATE SEQUENCE STATIONANTENNA_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_STATIONANTENNA_id BEFORE INSERT ON STATIONANTENNA
for each row 
begin     		
	if inserting then 
		if :NEW.STATIONANTENNAID  is null then
			SELECT STATIONANTENNA_id_seq.nextval into :NEW.STATIONANTENNAID  from dual;
		end if;
	end if; 
end;
/



--day 3
CREATE OR REPLACE VIEW GISVIEW AS 
SELECT vwstations.stationid, coalesce(vwstations.stationname,'No Name') as stationname, coalesce(vwstations.stationcallsign,'No Call Sign') as stationcallsign, vwstations.clientname, vwstations.licensename, coalesce(vwstations.location,'Not Defined') as location, cast(coalesce(vwmergedsites.longitude,0) as float) as sitelongitude, cast(coalesce(vwmergedsites.latitude,0) as float) as sitelatitude,cast(coalesce(vwstations.sit_asl,0) as number(4)) as sit_asl, cast(coalesce(substr(rffilterloss,0,instr(rffilterloss,' ')),'0') as float) as rffilterloss , vwstations.forexport, vwstations.longitude, vwstations.latitude, vwstations.isterrestrial,
	concat('P.O. Box ', coalesce(address,'Undefined')) as address, cast(coalesce(substr(stationequipment.carrieroutputpower,0,instr(stationequipment.carrieroutputpower,' ')),'0') as float) as outputpower, cast(coalesce(substr(maxgaindecibels,0,instr(maxgaindecibels,' ')),'0') as float) as maxgaindecibels,cast(coalesce(substr(height,0,instr(height,' ')),'0') as float) as height,'H' as polarization, cast(coalesce(substr(azimuth,0,instr(azimuth,' ')),'0') as float) as azimuth, cast(coalesce(substr(tilt,0,instr(tilt,' ')),'0') as float) as tilt, cast(coalesce(substr(threshold,0,instr(threshold,' ')),'0') as float) as threshold
	FROM vwstations
	left join vwmergedsites on vwstations.siteid = vwmergedsites.siteid
	left JOIN stationequipment ON stationequipment.stationid = vwstations.stationid
	left JOIN stationantenna ON vwstations.stationid = stationantenna.stationid
	left JOIN equipments ON stationequipment.equipmentid = equipments.equipmentid;




--ENGSTATIONS for export to engineering tool (via access table)
CREATE OR REPLACE VIEW ENGSTATIONS AS
SELECT vwstationassignment.stationid, coalesce(vwstationassignment.stationname,'No Name') as stationname, coalesce(vwstationassignment.stationcallsign,'No Call Sign') as stationcallsign, 
	vwstationassignment.clientname, vwstationassignment.licensename, coalesce(vwstationassignment.vhfnetworklocation,coalesce(vwstationassignment.location,'Not Defined')) as location, cast(coalesce(vwmergedsites.longitude,0) as float) as sitelongitude, 
	cast(coalesce(vwmergedsites.latitude,0) as float) as sitelatitude,cast(coalesce(vwstationassignment.sit_asl,0) as number(4)) as sit_asl, cast(coalesce(substr(rffilterloss,0,instr(rffilterloss,' ')),'0') as float) as rffilterloss ,
	vwstationassignment.forexport, vwstationassignment.longitude, vwstationassignment.latitude, vwstationassignment.isterrestrial,	concat('P.O. Box ', coalesce(address,'Undefined')) as address,
	cast(coalesce(substr(stationequipment.carrieroutputpower,0,instr(stationequipment.carrieroutputpower,' ')),'0') as float) as outputpower, cast(coalesce(substr(maxgaindecibels,0,instr(maxgaindecibels,' ')),'0') as float) as maxgaindecibels,
	cast(coalesce(substr(height,0,instr(height,' ')),'0') as float) as height, 'H' as polarization, cast(coalesce(substr(azimuth,0,instr(azimuth,' ')),'0') as float) as azimuth, cast(coalesce(substr(tilt,0,instr(tilt,' ')),'0') as float) as tilt, 
  cast(coalesce(substr(threshold,0,instr(threshold,' ')),'0') as float) as threshold,
  cast(coalesce(vwstationassignment.channelnumber,0) as integer) as channelnumber, cast(coalesce(vwstationassignment.transmit,0) as float) as transmit, cast(coalesce(vwstationassignment.receive,0) as float) as receive,
	cast(coalesce(vwstationassignment.duplexspacing,0) as float) as duplexspacing,
  licenseprices.typename  
FROM vwstationassignment
	INNER JOIN stations ON vwstationassignment.stationid = stations.stationid
	INNER JOIN licenseprices ON stations.licensepriceid = licenseprices.licensepriceid	
	INNER JOIN clientlicenses ON stations.clientlicenseid = clientlicenses.clientlicenseid
	INNER JOIN clients ON clientlicenses.clientid = clients.clientid
	INNER join vwmergedsites ON vwstationassignment.siteid = vwmergedsites.siteid
	INNER JOIN stationequipment ON stationequipment.stationid = vwstationassignment.stationid
	left JOIN stationantenna ON vwstationassignment.stationid = stationantenna.stationid
	INNER JOIN equipments ON stationequipment.equipmentid = equipments.equipmentid;




--ENGMICROWAVE	for terrestrial
CREATE OR REPLACE VIEW ENGMICROWAVE AS 
SELECT vwstationassignment.stationid, to_char(vwstationassignment.stationid) as ident, coalesce(vwstationassignment.stationname,'No Name') as linkname, coalesce(vwstationassignment.stationcallsign,'No Call Sign') as stationcallsign, vwstationassignment.clientname, vwstationassignment.licensename, coalesce(vwstationassignment.location,'Not Defined') as location, 
  vwstationassignment.forexport, coalesce(address,'Undefined') as address, coalesce(vwstationassignment.path_length_km,0) as path_length_km,
  vwstationassignment.transmit, vwstationassignment.receive,
  
  substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'StationName')+13,length(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'StationName')+13))-length(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'Bandwidth')-2))) as stationnameA,   
    
  substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'Bandwidth')+11,length(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'Bandwidth')+11))-length(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'SiteCode')-2))) as bandwidthA,   
  
  substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'SiteCode')+10, length(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'SiteCode')+10))-length(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'Latitude')-2))) as sitecodeA, 
  
  cast(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'Latitude')+10, length(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'Latitude')+10))-length(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'Location')-2))) as float) as latitudeA, 
  
  substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'Location')+10, length(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'Location')+10))-length(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'Longitude')-2))) as locationA, 
  
  cast(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'Longitude')+11, length(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'Longitude')+11))-length(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'LRNumber')-2))) as float) as longitudeA, 
  
  substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'LRNumber')+10, length(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'LRNumber')+10))-length(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'ASL')-2))) as lrnumberA, 
  
  cast(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'ASL') + 5, length(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'ASL')+5))-length(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'SiteName')-2))) as float) as aslA, 
  
  substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'SiteName') + 10, length(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'SiteName')+10))-length(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'FilterLoss')-2))) as sitenameA, 
  
  cast(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'FilterLoss') + 12, length(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'FilterLoss')+12))-length(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'Threshold')-2))) as float) as filterlossA, 
  
  cast(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'Threshold') + 11, length(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'Threshold')+11))-length(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'CarrierOutputPower')-2))) as float) as thresholdA, 
  
  cast(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'CarrierOutputPower') + 20, length(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'CarrierOutputPower')+20))-length(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'MaxGainDecibels')-2))) as float) as carrieroutputpowerA, 
  
  cast(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'MaxGainDecibels') + 17, length(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'MaxGainDecibels')+17))-length(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'Height')-2))) as float) as maxgaindecibelsA, 
  
  cast(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'Height') + 8, length(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'Height')+8))-length(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'Azimuth')-2))) as float) as heightA, 
  
  cast(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'Azimuth') + 9, length(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'Azimuth')+9))-length(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'Tilt')-2))) as float) as azimuthA, 
  
  cast(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'Tilt') + 6, length(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'Tilt')+6))-length(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'Transmit')-2))) as float) as tiltA, 
  
  cast(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'Transmit') + 10, length(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'Transmit')+10))-length(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'Recieve')-2))) as float) as transmitA, 
  
  cast(substr(getStationA(vwstationassignment.stationid),instr(getStationA(vwstationassignment.stationid),'Recieve') + 9) as float) as receiveA, 
  
  --INSTR(string, set [,start, [occurrence]])
    

	--'H' as Apolarization, 'H' as Bpolarization, 
  substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'StationName')+13,length(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'StationName')+13))-length(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'Bandwidth')-2))) as stationnameB,   
    
  substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'Bandwidth')+11,length(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'Bandwidth')+11))-length(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'SiteCode')-2))) as bandwidthB,   
  
  substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'SiteCode')+10, length(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'SiteCode')+10))-length(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'Latitude')-2))) as sitecodeB, 
  
  cast(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'Latitude')+10, length(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'Latitude')+10))-length(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'Location')-2))) as float) as latitudeB, 
  
  substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'Location')+10, length(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'Location')+10))-length(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'Longitude')-2))) as locationB, 
  
  cast(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'Longitude')+11, length(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'Longitude')+11))-length(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'LRNumber')-2))) as float) as longitudeB, 
  
  substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'LRNumber')+10, length(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'LRNumber')+10))-length(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'ASL')-2))) as lrnumberB, 
  
  cast(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'ASL') + 5, length(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'ASL')+5))-length(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'SiteName')-2))) as float) as aslB, 
  
  substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'SiteName') + 10, length(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'SiteName')+10))-length(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'FilterLoss')-2))) as sitenameB, 
  
  cast(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'FilterLoss') + 12, length(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'FilterLoss')+12))-length(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'Threshold')-2))) as float) as filterlossB, 
  
  cast(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'Threshold') + 11, length(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'Threshold')+11))-length(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'CarrierOutputPower')-2))) as float) as thresholdB, 
  
  cast(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'CarrierOutputPower') + 20, length(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'CarrierOutputPower')+20))-length(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'MaxGainDecibels')-2))) as float) as carrieroutputpowerB, 
  
  cast(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'MaxGainDecibels') + 17, length(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'MaxGainDecibels')+17))-length(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'Height')-2))) as float) as maxgaindecibelsB, 
  
  cast(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'Height') + 8, length(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'Height')+8))-length(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'Azimuth')-2))) as float) as heightB, 
  
  cast(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'Azimuth') + 9, length(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'Azimuth')+9))-length(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'Tilt')-2))) as float) as azimuthB, 
  
  cast(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'Tilt') + 6, length(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'Tilt')+6))-length(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'Transmit')-2))) as float) as tiltB, 
  
  cast(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'Transmit') + 10, length(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'Transmit')+10))-length(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'Recieve')-2))) as float) as transmitB, 
  
  cast(substr(getStationB(vwstationassignment.stationid),instr(getStationB(vwstationassignment.stationid),'Recieve') + 9) as float) as receiveB  
  
  FROM vwstationassignment
	
  WHERE vwstationassignment.isterrestrial='1' AND vwstationassignment.transmitstationid is null;





--getStationA
--getSiteA
--getStationEquipmentA
--getStationAntennaA
CREATE OR REPLACE FUNCTION getStationA(transmitterid in integer) RETURN varchar IS
PRAGMA AUTONOMOUS_TRANSACTION;
	myret int;
	summary varchar(1000);
BEGIN
  
	FOR myrec IN (select stations.stationid, stations.stationname, stations.requestedfrequency, stations.requestedbandwidth, vwmergedsites.sitecode, vwmergedsites.latitude, vwmergedsites.location, vwmergedsites.longitude, vwmergedsites.lrnumber, vwmergedsites.sit_asl, vwmergedsites.sitename,
		stationequipment.rffilterloss, stationequipment.threshold, stationequipment.carrieroutputpower,
		stationantenna.maxgaindecibels, stationantenna.height, stationantenna.azimuth, stationantenna.tilt, stationantenna.polarization,
		channel.transmit, channel.receive, channel.channelspacing
    from stations 
    inner join vwmergedsites on stations.siteid = vwmergedsites.siteid
	  inner join stationequipment on stations.stationid = stationequipment.stationid
	  inner join stationantenna on stations.stationid = stationantenna.stationid
	  left join frequencys on stations.stationid = frequencys.stationid
	  left join channel on frequencys.channelid = channel.channelid
	  where stations.stationid = (select max(stationid) from stations where transmitstationid = transmitterid)    
		)
      
	LOOP  
	
	--bandwidth should be the channelbandwidth aka channelseparation
	--

	summary := ('StationName: ' || myrec.stationname || ', Bandwidth: ' ||  coalesce(myrec.channelspacing,'0')  || ', SiteCode: ' || myrec.sitecode  || ', Latitude: ' || coalesce(myrec.latitude,'0')  || ', Location: ' || myrec.location  || ', Longitude: ' || coalesce(myrec.longitude,'0')  || ', LRNumber: ' || myrec.lrnumber  || ', ASL: ' ||  coalesce(myrec.sit_asl,'0')  || ', SiteName: ' || myrec.sitename
		|| ', FilterLoss: ' || coalesce(myrec.rffilterloss,'0')  || ', Threshold: ' ||  coalesce(myrec.threshold,'0')  || ', CarrierOutputPower: ' || coalesce(myrec.carrieroutputpower,'0')
		|| ', MaxGainDecibels: ' || coalesce(myrec.maxgaindecibels,'0')  || ', Height: ' || coalesce(myrec.height,'0')  || ', Azimuth: ' || coalesce(myrec.azimuth,'0')  || ', Tilt: ' || coalesce(myrec.tilt,'0')
		|| ', Transmit: ' || coalesce(myrec.transmit,'0')  || ', Recieve: ' || coalesce(myrec.receive,'0')) ;    
    
	END LOOP;
	
	--select substr(summary,0,(length(summary)-20)) into summary from dual;

	RETURN summary;
END;
/





CREATE OR REPLACE FUNCTION getStationB(transmitterid in integer) RETURN varchar IS
PRAGMA AUTONOMOUS_TRANSACTION;
	myret int;
	summary varchar(1000);
BEGIN
  
	FOR myrec IN (select stations.stationid, stations.stationname, stations.requestedfrequency, stations.requestedbandwidth, vwmergedsites.sitecode, vwmergedsites.latitude, vwmergedsites.location, vwmergedsites.longitude, vwmergedsites.lrnumber, vwmergedsites.sit_asl, vwmergedsites.sitename,
		stationequipment.rffilterloss, stationequipment.threshold, stationequipment.carrieroutputpower,
		stationantenna.maxgaindecibels, stationantenna.height, stationantenna.azimuth, stationantenna.tilt, stationantenna.polarization,
		channel.transmit, channel.receive, channel.channelspacing
    from stations 
    inner join vwmergedsites on stations.siteid = vwmergedsites.siteid
	  inner join stationequipment on stations.stationid = stationequipment.stationid
	  inner join stationantenna on stations.stationid = stationantenna.stationid
	  left join frequencys on stations.stationid = frequencys.stationid
	  left join channel on frequencys.channelid = channel.channelid
	  where stations.stationid = (select min(stationid) from stations where transmitstationid = transmitterid)    
		)
      
	LOOP  

	summary := ('StationName: ' || myrec.stationname || ', Bandwidth: ' ||  coalesce(myrec.channelspacing,'0')  || ', SiteCode: ' || myrec.sitecode  || ', Latitude: ' || coalesce(myrec.latitude,'0')  || ', Location: ' || myrec.location  || ', Longitude: ' || coalesce(myrec.longitude,'0')  || ', LRNumber: ' || myrec.lrnumber  || ', ASL: ' ||  coalesce(myrec.sit_asl,'0')  || ', SiteName: ' || myrec.sitename
		|| ', FilterLoss: ' || coalesce(myrec.rffilterloss,'0')  || ', Threshold: ' ||  coalesce(myrec.threshold,'0')  || ', CarrierOutputPower: ' || coalesce(myrec.carrieroutputpower,'0')
		|| ', MaxGainDecibels: ' || coalesce(myrec.maxgaindecibels,'0')  || ', Height: ' || coalesce(myrec.height,'0')  || ', Azimuth: ' || coalesce(myrec.azimuth,'0')  || ', Tilt: ' || coalesce(myrec.tilt,'0')
		|| ', Transmit: ' || coalesce(myrec.transmit,'0')  || ', Recieve: ' || coalesce(myrec.receive,'0')) ;    
    
	END LOOP;
	
	--select substr(summary,0,(length(summary)-20)) into summary from dual;

	RETURN summary;
END;
/















--based on ITU
CREATE TABLE banddefinition(
	banddefinitionid		integer primary key,
	banddefinition		varchar2(150),		--band definitions eg VHF,UHF,MF,etc
	lowerlimit			integer,
	upperlimit			integer,
	unitsofmeasure		varchar(10),
	details				clob
);
CREATE SEQUENCE banddefinition_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_banddefinition_id BEFORE INSERT ON banddefinition
for each row 
begin     
	if inserting then 
		if :NEW.banddefinitionid  is null then
			SELECT banddefinition_id_seq.nextval into :NEW.banddefinitionid from dual;
		end if;
	end if; 
end;
/



CREATE OR REPLACE VIEW vwfrequencyband AS
	SELECT frequencyband.frequencybandid, banddefinition.banddefinitionid, banddefinition.banddefinition, frequencyband.frequencybandname, frequencyband.unitsofmeasure, 
			frequencyband.lowerlimit, frequencyband.upperlimit, frequencyband.serviceallocation, to_char(frequencyband.remarks) as remarks, to_char(frequencyband.fsmremarks) as fsmremarks,
			(frequencyband.lowerlimit || '-' || frequencyband.upperlimit || ' ' || frequencyband.unitsofmeasure) as summary
	FROM frequencyband
	INNER JOIN banddefinition on frequencyband.banddefinitionid = banddefinition.banddefinitionid




--for 7Ghz, 1.4 Ghz
CREATE TABLE channelplan (
	channelplanid		integer primary key,
	itu_reference		varchar(100),
	channelplanname		varchar(100),		--name of the frequency band eg '200 – 283.5'
    description			varchar(150),	
	isterrestrial		char(1) default '0',
	isvhf				char(1) default '0',
	isbroadcasting		char(1) default '0',
	ismaritime			char(1) default '0',
	isaeronautical		char(1) default '0',
	details clob
	);
CREATE SEQUENCE channelplan_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_channelplan_id BEFORE INSERT ON channelplan
for each row 
begin     
	if inserting then 
		if :NEW.channelplanid is null then
			SELECT channelplan_id_seq.nextval into :NEW.channelplanid from dual;
		end if;
	end if; 
end;
/



CREATE OR REPLACE VIEW vwchannel AS
	SELECT channel.channelid, channel.subbandname, channel.itu_reference as channel_itu, channel.channelnumber, channel.transmit, channel.receive, ('Ch:' || channel.channelnumber || ' F1:' || channel.transmit ||' F2:'|| channel.receive || 'BW: ' || channel.channelspacing || 'MHz') as channelsummary,
	channelplan.channelplanid, channelplan.channelplanname, channelplan.description, channelplan.itu_reference as channelplan_itu, getFootNotes(channel.transmit, channel.receive) as footnoteshtml
	FROM channel
	INNER join channelplan on channel.channelplanid = channelplan.channelplanid;

--actual channels assigned to clients

--not for links


CREATE OR REPLACE FUNCTION getFootNotes(transmit in integer, receive in integer) RETURN varchar IS
PRAGMA AUTONOMOUS_TRANSACTION;

	footnotehtml varchar(1000);
	
BEGIN
	
	--select all footnotes with u
  FOR footnote_rec IN (SELECT footnotedefinitionid, footnotedefinition, footnotedescription FROM vwchannelfootnotes WHERE lowerlimit <= transmit AND upperlimit >= receive) LOOP
    footnotehtml := footnotehtml || '<b>' || footnote_rec.footnotedefinition || ': </b>' || footnote_rec.footnotedescription || '<br>';
  END LOOP;
  
	RETURN footnotehtml;
  
END;
/

create view vwmaritimehf as
	select channel.channelid, channelplan.channelplanid, channel.subbandname, channel.itu_reference, channel.transmit as carriership, (channel.transmit+0.0014) as assignedship, channel.receive as carriercoast, (channel.receive+0.0014) as assignedcoast,
	channel.unitsofmeasure,channelplan.ismaritime
	from channel
  inner join channelplan on channel.channelplanid = channelplan.channelplanid
  where channelplan.ismaritime = '1';

--for band assignment 
CREATE TABLE amateurtypes(
	amateurtypeid		integer primary key,
	amateurtypename		varchar2(200),
	details				clob	
	);
INSERT INTO amateurtypes VALUES(1,'Full Amateur');
INSERT INTO amateurtypes VALUES(2,'Temporary Amateur');
INSERT INTO amateurtypes VALUES(3,'Novice Amateur');

--for band assignment 
CREATE TABLE aircrafttype(
	aircrafttypeid		integer primary key,
	aircrafttypename		varchar2(200),
	details				clob	
	);
INSERT INTO aircrafttype VALUES(1,'HF',null);
INSERT INTO aircrafttype VALUES(2,'VHF',null);
INSERT INTO aircrafttype VALUES(3,'HF + VHF',null);




CREATE TABLE channel (
	channelid		integer primary key,
	
	channelplanid		integer references channelplan,

	subbandname			varchar(200) default 'No sub band',	--ifany
	subbanddescription			varchar(50),	--subband description
	subbandannex				varchar(20),	--subbandannex - may contain itu_reference
	itu_reference		varchar(50),			--if ITU_REF not in channelplan

	channelspacing		real,				--difference btwn two channels (aka the bandwidth)
	duplexspacing		real,				--difference btwn go n return channels	
	centerfrequency		real,
	formula				varchar(100),

    channelnumber	integer,
	transmit		number(10,4),				--number(10,4)		10 digits with 4 decimal places
    receive			number(10,4),
	unitsofmeasure	varchar(10),

	forcitizenband	char(1),
	forfamilyband	char(1),
	
	foramateur		char(1),	--full amateur - amateurtype 1
	fortempamateur 	char(1),	--amateur type 2
	fornoviceamateur char(1),	--amateur type 3
	
	aircrafthf		char(1),
	aircraftvhf		char(1),

	foraircraft		char(1),
	formaritime		char(1),

	classesofemission	varchar(500),
	maximumdcinput		varchar(100),
	rfpeakoutput		varchar(100),

	footnotes			varchar(100),
	allocation			varchar(200),
	remarks				clob,
	details				clob,

	oldclients		clob			--used to hold list of old clients

);

CREATE INDEX channel_channelplan ON channel (channelplanid);

CREATE SEQUENCE channel_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_channel_id BEFORE INSERT ON channel
for each row 
begin     
	if inserting then 
		if :NEW.channelid  is null then
			SELECT channel_id_seq.nextval into :NEW.channelid from dual;
		end if;
	end if; 
end;
/


--TOFA FOOTNOTE DESCRIPTION
CREATE TABLE footnotedefinition(
	footnotedefinitionid	integer primary key,
	footnotedefinition	varchar(20),
	footnotedescription	clob		
	);
CREATE SEQUENCE footnotedefinition_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_footnotedefinition_id BEFORE INSERT ON footnotedefinition
for each row 
begin     
	if inserting then 
		if :NEW.footnotedefinitionid  is null then
			SELECT footnotedefinition_id_seq.nextval into :NEW.footnotedefinitionid from dual;
		end if;
	end if; 
end;
/


CREATE VIEW vwfootnotedefinition AS
	SELECT footnotedefinition.footnotedefinitionid, footnotedefinition.footnotedefinition, to_char(footnotedefinition.footnotedescription) as footnotedescription
	FROM footnotedefinition;

--CONNECT all/relevant footnotes to the frequencyband
CREATE TABLE footnotefrequencyband(
	footnotefrequencybandid		integer primary key,
	footnotedefinitionid		integer references footnotedefinition,
	frequencybandid				integer references frequencyband,
	details						clob
	);
CREATE SEQUENCE footnotefrequencyband_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_footnotefrequencyband_id BEFORE INSERT ON footnotefrequencyband
for each row 
begin     
	if inserting then 
		if :NEW.footnotefrequencybandid  is null then
			SELECT footnotefrequencyband_id_seq.nextval into :NEW.footnotefrequencybandid from dual;
		end if;
	end if; 
end;
/


--used for coarse link btwn footnotes and actual channel pairs
CREATE OR REPLACE VIEW vwchannelfootnotes AS
	SELECT footnotefrequencyband.footnotefrequencybandid, footnotefrequencyband.frequencybandid, getChannelID(lowerlimit,upperlimit, unitsofmeasure) as calculatedchannelid,
	frequencybandname, unitsofmeasure, lowerlimit,	upperlimit, footnotefrequencyband.details, footnotedefinition.footnotedefinitionid, 
	footnotedefinition.footnotedefinition, to_char(footnotedefinition.footnotedescription) as footnotedescription
	FROM footnotefrequencyband
	INNER JOIN footnotedefinition ON footnotefrequencyband.footnotedefinitionid = footnotedefinition.footnotedefinitionid
	INNER JOIN frequencyband ON footnotefrequencyband.frequencybandid = frequencyband.frequencybandid;


--deprecated. syntax is ok but semantics not quite quite
CREATE OR REPLACE FUNCTION getChannelID(f1 in integer, f2 in integer, units in varchar) RETURN integer IS
PRAGMA AUTONOMOUS_TRANSACTION;

	channel_id int;
	
BEGIN
	
	--may return more than one channel id. MAX() is used as a stop-gap measure aka quick fix
	SELECT min(channelid) INTO channel_id FROM channel WHERE decode(unitsofmeasure,'GHz', transmit*100, 'KHz', transmit/100, transmit) >= f1 AND decode(unitsofmeasure,'GHz', receive*1000, 'KHz', receive/100, receive) <= f2;

	RETURN channel_id;
  
END;
/


--receiving phase remarks
CREATE OR REPLACE FUNCTION getReceivingRemarks(cli_lic_id in integer) RETURN varchar IS
PRAGMA AUTONOMOUS_TRANSACTION;

	comments varchar(500);
	
BEGIN
	
	SELECT narrative into comments from clientphases    
  where clientphaseid = (select min(clientphaseid) from clientphases where clientlicenseid = cli_lic_id);

	RETURN comments;
  
END;
/



CREATE VIEW vwfootnotefrequencyband AS
	SELECT footnotefrequencyband.footnotefrequencybandid, footnotefrequencyband.frequencybandid, footnotefrequencyband.details, 
	footnotedefinition.footnotedefinitionid, footnotedefinition.footnotedefinition, to_char(footnotedefinition.footnotedescription) as footnotedescription
	FROM footnotefrequencyband
	INNER JOIN footnotedefinition ON footnotefrequencyband.footnotedefinitionid = footnotedefinition.footnotedefinitionid;



--according to KENYA TOFA (table of frequency allocation) (and CCK FSM)
CREATE TABLE frequencyband (
	frequencybandid		integer primary key,
	banddefinitionid	integer references banddefinition,
	frequencybandname	varchar(150),		--name of the frequency band eg '200 – 283.5'
	unitsofmeasure		varchar(10),		--eg Khz, Mhz, Ghz, etc
	lowerlimit			real,		
	upperlimit			real,
	serviceallocation	varchar(200),		--allocation to services
	remarks				clob,		
	fsmremarks			clob
);
CREATE SEQUENCE frequencyband_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_frequencyband_id BEFORE INSERT ON frequencyband
for each row 
begin     
	if inserting then 
		if :NEW.frequencybandid  is null then
			SELECT frequencyband_id_seq.nextval into :NEW.frequencybandid from dual;
		end if;
	end if; 
end;
/




--for frequency data in transit (final destination is table frequencys)
CREATE TABLE frequencys_temp(
	frequencys_tempid	integer primary key,
	stationid 			integer references stations, 
	vhfnetworkid		integer references vhfnetwork,	--all stations in this vhf network should default to this band/freq so that we can later edit them manualy if needed
	channelid			integer references channel,
	isreserved			char(1) default '1',
	isactive			char(1) default '0',
	details				clob
	);
CREATE SEQUENCE frequencys_temp_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_frequencys_temp_id BEFORE INSERT ON frequencys_temp
for each row 
begin     
	if inserting then 
		if :NEW.frequencys_tempid  is null then
			SELECT frequencys_temp_id_seq.nextval into :NEW.frequencys_tempid  from dual;		
		end if;

		if (:NEW.vhfnetworkid is not null) then		
			--insert into temp first				
			insert into frequencys(stationid, channelid, vhfnetworkid)
				SELECT stationid, :NEW.channelid, :NEW.vhfnetworkid
				FROM stations
				WHERE vhfnetworkid = :NEW.vhfnetworkid;			
		end if;

		
	end if;
end;
/

---UPDATE VHF NETWORK frequencys
CREATE OR REPLACE TRIGGER tr_frequencys_temp_id BEFORE UPDATE ON frequencys_temp
for each row 
begin     
	if updating then 			
		update frequencys set isactive = :NEW.isactive, isreserved = :NEW.isreserved
		WHERE vhfnetworkid = :NEW.vhfnetworkid;		
	end if;
end;
/


--FOR STATIONS REQUIRING ASSIGNMENT OF SELECTED BANDS 
CREATE TABLE bandassignment(
	bandassignmentid	integer primary key,
	stationid 			integer references stations, 
	aircrafttypeid		integer references aircrafttype,	--for block assignment of aircraft bands
	amateurtypeid		integer references amateurtypes,	--this is used to enable block assignemt of channels for amateur radios
	details 			clob
	);
CREATE SEQUENCE bandassignment_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_bandassignment_id BEFORE INSERT ON bandassignment
for each row 
begin     
	if inserting then 
		if :NEW.bandassignmentid  is null then
			SELECT bandassignment_id_seq.nextval into :NEW.bandassignmentid from dual;
		end if;
	end if; 
end;
/


--PROPAGATE BAND ASSIGNENTS INTO THE FREQUENCY TABLE
CREATE OR REPLACE TRIGGER tr_insertbands AFTER INSERT ON bandassignment
for each row 
begin     

		--FOR AMATEUR RADIO
		if(:new.amateurtypeid = 1) then
			insert into frequencys(stationid,channelid,bandassignmentid,amateurtypeid)
			select :new.stationid,channelid,:new.bandassignmentid,:new.amateurtypeid
				from channel where foramateur = '1';			
		elsif(:new.amateurtypeid = 2) then
			insert into frequencys(stationid,channelid,bandassignmentid,amateurtypeid)
			select :new.stationid,channelid,:new.bandassignmentid,:new.amateurtypeid
				from channel where fortempamateur = '1';
		elsif(:new.amateurtypeid = 3) then
			insert into frequencys(stationid,channelid,bandassignmentid,amateurtypeid)
			select :new.stationid,channelid,:new.bandassignmentid,:new.amateurtypeid
				from channel where fornoviceamateur = '1';
		end if;

		--FOR AIRCRAFT
		if(:new.aircrafttypeid = 1) then		--HF
			insert into frequencys(stationid,channelid,bandassignmentid,aircrafttypeid)
			select :new.stationid,channelid,:new.bandassignmentid,:new.aircrafttypeid
				from channel where aircrafthf = '1';
		elsif(:new.aircrafttypeid = 2) then		--VHF
			insert into frequencys(stationid,channelid,bandassignmentid,aircrafttypeid)
			select :new.stationid,channelid,:new.bandassignmentid,:new.aircrafttypeid
				from channel where aircraftvhf = '1';
		elsif(:new.aircrafttypeid = 3) then		--HF + VHF
			insert into frequencys(stationid,channelid,bandassignmentid,aircrafttypeid)
			select :new.stationid,channelid,:new.bandassignmentid,:new.aircrafttypeid
				from channel where aircrafthf = '1' or aircraftvhf = '1';
		end if;

end;
/



--dummy stations created just for analysis. specifically by FP to facilitate int'l coordination 
CREATE TABLE analysedstation(
	analysedstationid 	integer primary key,

	intcorrespondenceid	integer references intcorrespondence,		--we want to know the related international correspondence

	stationname			varchar(50),
	stationcallsign 	varchar(50),
	clientname 			varchar(50),

	countryid			char(2) references countrys,
	licenseid 			integer references licenses,
	servicename			varchar(50),
	longitude			float,
	latitude			float,
	sit_asl 			number(4,0),
	rffilterloss		float,

	forexport			char(1) default '0',
	isterrestrial		char(1) default '1',		
	iscleared			char(1) default '0',

	address				varchar(50),
	outputpower			float,
	maxgaindecibels		float,
	height				float,
	polarization		char(1),
	azimuth				float,

	tilt				float,
	threshold			float,
	transmit			float,
	receive				float,
	duplexspacing		float,	--aka bandwdith
						--fifth	
	
	details					clob
	);
CREATE SEQUENCE eanalysedstation_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_analysedstation_id BEFORE INSERT ON analysedstation
for each row 
begin     
	if inserting then 
		if :NEW.analysedstationid  is null then
			SELECT eanalysedstation_id_seq.nextval into :NEW.analysedstationid  from dual;
		end if;
	end if; 
end;
/


CREATE TABLE frequency_expansion(
	frequency_expansion		integer primary key,
	
 
	vhfnetworkid		integer references vhfnetwork,
	extrafrequencies	integer not null default 1,
	isentirenetwork		char(1) not null default '0',		--do we add the extra frequency for all stations in the network ?
	numberofaffectedstations	integer,					--if not entire network 

	actiondate			date default sysdate,
	userid				integer references users,

	);


--assigned/reserved frequencies
CREATE TABLE frequencys (

	frequencyid			integer primary key,
	stationid 			integer references stations, 

	vhfnetworkid		integer references vhfnetwork,	--all stations in this vhf network should default to this band/freq so that we can later edit them manualy if needed

	channelid			integer references channel,	

	bandassignmentid	integer references bandassignment,
	amateurtypeid		integer references amateurtypes,	--this is used to enable block assignemt of channels for amateur radios. done at bandassignment
	aircrafttypeid		integer references aircrafttype,	--for block assignment of aircraft bands

	txfrequency			float,		--discrete
	rxfrequency			float,		--discrete

	isreserved			char(1) default '0',		--assignment is in progress, applicant can now get the offer letter
	isactive			char(1) default '0',		--assignment completed, ready for billing

	--reserveddate		date
	--assigndate		date
	actiondate 			date default sysdate,

	tx_frequencyband	varchar(50),
	rx_frequencyband	varchar(50),

	FRQ_STA_TYPE 		VARCHAR(9), 
	FRQ_STA_CHANNEL 	VARCHAR(9), 

	FRQ_TX_LOW_FREQ 	NUMERIC(22,8), 
	FRQ_TX_HIGH_FREQ 	NUMERIC(22,8), 

	FRQ_RX_LOW_FREQ 	NUMERIC(22,8), 
	FRQ_RX_HIGH_FREQ 	NUMERIC(22,8), 

	FRQ_START_DATE 		DATE, 
	FRQ_END_DATE 		DATE, 
	FRQ_FREQ_TYPE 		VARCHAR(9), 	

	FRQ_MAIN 			NUMERIC(1,0), 

	FRQ_PERMANENT 		NUMERIC(1,0), 
	LAST_UPD_TIME 		DATE DEFAULT current_date, 	
	FRQ_STA_CALL_SIGN 	VARCHAR(50), 
	FRQ_STA_LONGITUDE 	NUMERIC(10,6), 
	FRQ_STA_LATITUDE 	NUMERIC(10,6), 
	FRQ_TX_BANDWIDTH 	NUMERIC(22,8), 
	FRQ_RX_BANDWIDTH 	NUMERIC(22,8), 
	FRQ_LSB_USB 		VARCHAR(9), 
	FRQ_QUANTITY 		NUMERIC(3,0),	
	FRQ_REMARK 			VARCHAR(200)
);

CREATE INDEX frequencys_stations ON frequencys (stationid);
CREATE INDEX frequencys_vhfnetwork ON frequencys (vhfnetworkid);
CREATE INDEX frequencys_channel ON frequencys (channelid);
CREATE INDEX frequencys_bandassignment ON frequencys (bandassignmentid);
		

CREATE SEQUENCE frequencys_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
create or replace TRIGGER tr_frequency_id BEFORE INSERT ON frequencys
for each row 
declare
	
bw real;		--KHz
separation real;	--MHz

operating_band real;	--GHz
channelplan_band real;		--GHz (derived from the first part of the channel plan name)

numberoffrequenciesrequested integer;
totalassignedfrequencies integer;
frequenciesinchannel	integer;		--how may frequencies does a single channel have (ie is transmit = recieve?)

no_amateur_bandsassigned integer;			--for amateur and aircraft (plz NOTE this is not equivalent to number of channels assigned)
no_aircraft_bandsassigned integer;			--NUMBER OF aircraft bands assigned

license_id integer;
is_terrestrial char(1);


begin     
	if inserting then 
		if :NEW.frequencyid  is null then
			SELECT frequencys_id_seq.nextval into :NEW.frequencyid from dual;		
		end if;

		--initialization 
		no_amateur_bandsassigned := 0;
		no_aircraft_bandsassigned := 0;

    --identify the license
    select licenses.licenseid, licenses.isterrestrial into license_id,is_terrestrial
    from licenses
    inner join clientlicenses on licenses.licenseid = clientlicenses.licenseid
    inner join stations on clientlicenses.clientlicenseid = stations.clientlicenseid
    where stations.stationid = :new.stationid;

		--get requested bandwidth
		select stations.requestedbandwidth into bw			--requestedbandwidth was stored in KHz
			from stations where stationid = :new.stationid;

		--get the channel bandwidth/separation
		select channel.channelspacing into separation	--channel spacing is equivalent to channel bandwidth
			from channel where channelid = :new.channelid;

		
		
    if (is_terrestrial = '1') then
      
      --get the requested band (GHz)
		  select stations.requestedfrequencyGHz into operating_band			--requestedbandwidth was stored in KHz
			from stations where stationid = :new.stationid;	
      
      --get channel operating band (accessible via channelplan name)
      select cast(substr(channelplanname,0,instr(channelplanname,' ')) as float) into channelplan_band
        from channelplan 
        inner join channel on channelplan.channelplanid = channel.channelplanid
        where isterrestrial='1' and channelid = :new.channelid;

    end if;
		--Error numbers are defined between -20,000 and -20,999
		--if(bw*1000 != separation) then
		--	raise_application_error(-20001,'Requested Bandwidth is different from the channel bandwidth');
		--end if;
		
	
		--TAKE CARE OF BAND ASSIGNMENTS AND CHANNEL ASSIGNMENTS
	if(:new.bandassignmentid is null) then						
			
      if (is_terrestrial = '1') then  
        --CONFIRM BANDWIDTH
        if(bw/1000 != separation) then
          raise_application_error(-20001,'REQUESTED BANDWIDTH(' || (bw/1000) ||'MHz) IS DIFFERENT FROM THE CHANNEL BANDWIDTH (' || separation || 'MHz). REQUEST REJECTED');
        end if;
        --CONFIRM OPERATING BAND 
        if(operating_band != channelplan_band) then
          raise_application_error(-20002,'REQUESTED BAND(' || (operating_band) ||'GHz) IS DIFFERENT FROM THE CHANNEL OPERATING BAND(' || channelplan_band || 'GHz). REQUEST REJECTED');
        end if;

    end if;

			--NUMBER OF FREQUENCIES ASSIGNED SHOULD NOT EXCEED NUMBER OF FREQUENCIES REQUESTED
			--get the total number of already assigned frequencies
			select getNumberOfFrequencies(:new.stationid) into totalassignedfrequencies from dual;

			--get the total number of requested frequencies
			select numberoffrequencies into numberoffrequenciesrequested from stations where stationid = :new.stationid;
			
			--if simplex requested (or remaining frequency is one) then make sure that only a simplex channel is assigned
			select decode(coalesce(channel.receive,0) - coalesce(channel.transmit,0),0,1,2) into frequenciesinchannel from channel where channelid = :new.channelid;

			if((numberoffrequenciesrequested-totalassignedfrequencies) = 1)then 	--if only one required / remaining
				if(frequenciesinchannel > 1)then			--if user is attempting to imput a channel with more than one frequencies..
					raise_application_error(-20003,'THE NUMBER OF FREQUENCIES IN THE CHANNEL EXCEEDS THE NUMBER OF FREQUENCIES REQUIRED/REMAINING. NOT ASSIGNED');		
					return;
				end if;
			elsif(totalassignedfrequencies >= numberoffrequenciesrequested) then
				raise_application_error(-20004,'ATTEMPT TO EXCEED THE NUMBER OF FREQUENCIES REQUESTED (' || numberoffrequenciesrequested || ') HAS BEEN REJECTED');
				return;
			end if;

		elsif (:new.amateurtypeid is not null) then
			
			select getNumberOfBands(:new.stationid, :new.amateurtypeid, '1', '0') into no_amateur_bandsassigned from dual;
			if (no_amateur_bandsassigned != 0) then
				raise_application_error(-20005,'RELEVANT AMATEUR BAND HAS ALREADY BEEN ASSIGNED. REQUEST REJECTED');
			end if;

		elsif (:new.aircrafttypeid is not null) then
			
			select getNumberOfBands(:new.stationid, :new.aircrafttypeid, '0', '1') into no_aircraft_bandsassigned from dual;
			if (no_aircraft_bandsassigned != 0) then
				raise_application_error(-20006,'RELEVANT AERONAUTICAL BAND HAS ALREADY BEEN ASSIGNED. REQUEST REJECTED');
			end if;

		end if;
	
	end if;
  
  --EXCEPTION
	--WHEN OTHERS THEN
    --raise_application_error(-20020,'UNKNOWN ERROR Station id = ' || :new.stationid || ', Channel Id' || :new.channelid);		
end;


CREATE OR REPLACE VIEW vwaudittrail AS
 SELECT audittrail.audittrailid, users.fullname, audittrail.changedate, audittrail.tablename, audittrail.recordid, audittrail.changetype, audittrail.narrative
	FROM audittrail
	INNER JOIN users ON cast(coalesce(audittrail.username,'0') as int)= users.userid;
 


--b4 training
--for terrestrial
create or replace view stationdetails as
	select stations.stationid, stations.transmitstationid, (stations.requestedfrequency/1000) as requestedfrequency, stations.clientlicenseid, 
	stations.requestedfrequencyGHz, stations.requestedbandwidth, stations.vehicleregistration, licenseprices.stationclassid, licenseprices.typename, stations.sta_call_sign, equipments.make, equipments.model, 
	stationequipment.equipmentserialno, stationequipment.carrieroutputpower, equipments.suppliername, sites.location as sitelocation,vwclientlicenses.clientname, 
	vwclientlicenses.address, vwclientlicenses.town,vwclientlicenses.postalcode,vwclientlicenses.applicationdate,vwclientlicenses.licenseid, vwclientlicenses.licensename,
	vwclientlicenses.filenumber, stations.location, round(stations.stationcharge + 0.4) as stationcharge,	vwclientlicenses.offersentdate, vwclientlicenses.currentphase, 
	vwclientlicenses.clientid, proratedChargePeriod(current_date) as chargedmonths, round(stationinitialcharge(stations.stationid, current_date)) as proratedcharge
	from stations 
	inner join vwclientlicenses on stations.clientlicenseid = vwclientlicenses.clientlicenseid
	left join stationequipment on stations.stationid =  stationequipment.stationid
	left join equipments on stationequipment.equipmentid = equipments.equipmentid
	inner join licenseprices on stations.licensepriceid = licenseprices.licensepriceid	
	left join sites on stations.siteid = sites.siteid
  where vwclientlicenses.isterrestrial = '1';






--get the total number of frequencies assigned to this station
CREATE OR REPLACE FUNCTION getNumberOfFrequencies(station_id in integer) RETURN integer IS
PRAGMA AUTONOMOUS_TRANSACTION;

	numfrequencies int;
	
BEGIN
	
	numfrequencies := 0;

	FOR myrec in 
		(select frequencys.stationid, decode(coalesce(channel.receive,0) - coalesce(channel.transmit,0),0,1,2) as num 
		from frequencys 
		inner join channel on frequencys.channelid = channel.channelid
		where stationid = station_id)
	LOOP
		numfrequencies := numfrequencies + myrec.num;
	END LOOP;

	RETURN numfrequencies;
  
END;
/


--get the number of bands (not channels) assigend eg the number of Aircraft HF, number of full amateur bands, etc
CREATE OR REPLACE FUNCTION getNumberOfBands(station_id in integer,payload_id in integer, isamateur in varchar, isaircraft in varchar) RETURN integer IS
PRAGMA AUTONOMOUS_TRANSACTION;

	numofbands int;
	
BEGIN
	
	numofbands := 0;

	if(isaircraft = '1') then
		select count(aircrafttypeid) into numofbands from frequencys where stationid = station_id and aircrafttypeid = payload_id;
	elsif (isamateur = '1') then
		select count(amateurtypeid) into numofbands from frequencys where stationid = station_id and amateurtypeid = payload_id;
	end if;

	RETURN numofbands;
  
END;
/



--AFTER INSERT INTO FREQUENCYS - STATEMENT LEVEL
-- CREATE OR REPLACE TRIGGER tr_vhf_stations AFTER INSERT ON frequencys_temp
-- --for each row
-- begin		
-- 	--insert into all stations 
-- 	INSERT INTO frequencys(stationid, channelid, vhfnetworkid)
-- 		SELECT stationid, channelid, vhfnetworkid
-- 		FROM frequencys_temp;
-- 		--WHERE vhfnetworkid = (select vhfnetworkid max());		--are we sure ours will be the last ???
-- 
-- END;
-- /





CREATE OR REPLACE VIEW vwfrequencyusers AS
	--SELECT frequencyband.frequencybandid, frequencyband.banddefinitionid, frequencyband.lowerlimit, frequencyband.upperlimit, frequencyband.frequencybandname, frequencyband.unitsofmeasure, frequencyband.serviceallocation, frequencyband.remarks, frequencyband.fsmremarks,getBandUsers(frequencyband.frequencybandid) as users
	SELECT frequencyband.frequencybandid, frequencyband.banddefinitionid, frequencyband.lowerlimit, frequencyband.upperlimit, frequencyband.frequencybandname, frequencyband.unitsofmeasure, frequencyband.serviceallocation, frequencyband.remarks, frequencyband.fsmremarks
	from  frequencyband;



CREATE OR REPLACE FUNCTION getBandUsers(freq_band_id in integer) RETURN integer IS
PRAGMA AUTONOMOUS_TRANSACTION;
	myret int;
	
BEGIN
	
	SELECT count(stationid) into myret from frequencys where frequencybandid = freq_band_id ; 
	
	RETURN myret;
  
END;
/







DROP VIEW tomcatusers;
CREATE VIEW tomcatusers AS 
	(SELECT username, userpasswd, rolename FROM users WHERE IsActive = '1')
	UNION
	(SELECT clientlogin, userpasswd, 'clients' FROM clients WHERE IsActive = '1');

--b4 clc
CREATE or replace VIEW vwlicenses AS 
SELECT 
  licenses.licenseid,licenses.licensename,licenses.licenseperiod,licenses.applicationfee,licenses.initialfee, 
  licenses.annualfeedetail,licenses.licenseabbrev,licenses.num,licenses.annualfee,licenses.agtfee,licenses.typeapprovalfee, 
  licenses.applicationaccount,licenses.initialaccount,licenses.annualaccount,licenses.taaccount, licenses.ismaritime,
  licenses.fixedfee,licenses.rolloutperiod,licensetypes.forfsm,licensetypes.forlcs,licenses.licenseterms,
  licensetypes.licensetypename,licensetypes.licensetypeid,licensetypes.forta,licensetypes.nlf,licensetypes.abbrev, 
  licenses.quarterly,licenses.annually,licenses.isactive,licenses.licensereport,licenses.spectrumaccess,licenses.details,
  (licenses.num || licenses.licensename )as licstructure,licenses.clcorder,licenses.isterrestrial, licenses.isvhf, licenses.isbroadcasting,
	licenses.isserviceprovider,licenses.isvsat,licenses.isinfrastructure,licenses.ispostal,licenses.iscontractor,
	currencyunits.currencyunitname , currencyunits.currencyabbrev,currencyunits.currencyunitid,
('<a href="/fsm/reports/pdfs/'|| licenses.licensename || ' - conditions.pdf" target="_blank">' ||licenses.licensename|| ' Conditions</a>') as conditionslink
FROM licenses 
INNER JOIN licensetypes ON licensetypes.licensetypeid = licenses.licensetypeid
LEFT JOIN currencyunits ON currencyunits.currencyunitid = licenses.currencyunitid;




CREATE VIEW vwformtypes AS
	SELECT formtypes.formtypeid, formtypes.formtypename, formtypes.formnumber, formtypes.version,
		formtypes.completed, formtypes.isactive, formtypes.header, formtypes.footer, formtypes.details,
		formtypes.forfsm, formtypes.forlcs, formtypes.forta, formtypes.application, formtypes.compliance, 
		('<a href="cckforms?formtypeid='|| formtypes.formtypeid || '&showhead=true" target="_blank">' 
		|| formtypes.formnumber || '</a>') as formlink, 
		('http://localhost:8080/cck/cckforms?formtypeid=' || formtypes.formtypeid || '&showhead=true') as weblink,
		(formtypes.formnumber || ' : ' || formtypes.formtypename) as formtypelist
	FROM formtypes;
	
CREATE VIEW vwforms AS
	SELECT formtypes.formtypeid, formtypes.formtypename, forms.formid, forms.qorder, forms.shareline, forms.fortitle,
		forms.subformgrid, forms.question
	FROM forms INNER JOIN formtypes ON forms.formtypeid = formtypes.formtypeid;

CREATE OR REPLACE FUNCTION getcolspans(myval1 IN varchar2, myval2 IN integer) RETURN integer IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	myret int;
BEGIN
	SELECT COUNT(subforms.subformid) INTO myret
	FROM subforms
	WHERE (titleshare = myval1) AND (formid = myval2);
	COMMIT;

	RETURN myret;
END;
/

CREATE OR REPLACE FUNCTION countapplicants(clc_id IN varchar2) RETURN integer IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	myret int;
BEGIN
	SELECT COUNT(clientlicenses.clientid) INTO myret
	FROM clientlicenses
	WHERE clientlicenses.clcid = CAST(clc_id AS int);	

	RETURN myret;
END;
/

CREATE VIEW vwsubforms AS
	SELECT vwforms.formid, vwforms.formtypename, subforms.subformid, subforms.qorder, subforms.question,
		subforms.titleshare, subforms.fieldsize, getcolspans(subforms.titleshare, subforms.formid) as colspans
	FROM subforms INNER JOIN vwforms ON subforms.formid = vwforms.formid;

CREATE VIEW vwformphases AS
	SELECT formtypes.formtypeid, formtypes.formnumber, formtypes.formtypename,
		usergroups.usergroupid, usergroups.usergroupname, phases.phaseid,phases.compliance,phases.approval,
		phases.EscalationTime, phases.phaselevel, phases.returnlevel, phases.details,
		phases.paymenttypeid
	FROM (phases INNER JOIN formtypes ON phases.formtypeid = formtypes.formtypeid)
		INNER JOIN usergroups ON phases.usergroupid = usergroups.usergroupid;
		
CREATE OR REPLACE FORCE VIEW VWLICENSEPHASES AS 
  SELECT phases.NUMBERING,
  licenses.licenseid,
    licenses.licensename,
    usergroups.usergroupid,
    usergroups.usergroupname,
    phases.phaseid,
    phases.phaselevel,
    phases.returnlevel,
    phases.compliance,
    phases.approval,
    phases.EscalationTime,
    phases.details,
    phases.paymenttypeid,
    phases.annualschedule
  FROM phases
  INNER JOIN licenses  ON phases.licenseid = licenses.licenseid
  LEFT JOIN usergroups  ON phases.usergroupid = usergroups.usergroupid;


CREATE VIEW vwformchecklists AS
	SELECT vwformphases.formtypeid, vwformphases.formnumber, vwformphases.formtypename, vwformphases.usergroupid,
		vwformphases.usergroupname, vwformphases.phaseid, vwformphases.phaselevel,checklists.individual,
		checklists.checklistid, checklists.phasenumber, checklists.requirement, checklists.details
	FROM checklists INNER JOIN vwformphases ON checklists.phaseid = vwformphases.phaseid;
	
CREATE VIEW vwlicensechecklists AS
	SELECT vwlicensephases.licenseid, vwlicensephases.licensename, vwlicensephases.usergroupid,
		vwlicensephases.usergroupname, vwlicensephases.phaseid, vwlicensephases.phaselevel,checklists.individual,
		checklists.checklistid, checklists.phasenumber, checklists.requirement, checklists.details,vwlicensephases.annualschedule
	FROM checklists INNER JOIN vwlicensephases ON checklists.phaseid = vwlicensephases.phaseid;


CREATE VIEW vwlicenseforms AS
	SELECT formtypes.formtypeid, formtypes.formnumber, formtypes.formtypename, formtypes.version, 
		formtypes.forfsm, formtypes.forlcs, formtypes.forta, formtypes.application, formtypes.compliance,
		licenses.licenseid, licenses.licensename, licenseforms.licenceformid, licenseforms.formorder, licenseforms.details, 
		('<a href="cckforms?formtypeid='|| formtypes.formtypeid || '&showhead=true" target="_blank">' 
		|| formtypes.formnumber || '</a>') as formlink
	FROM (licenseforms INNER JOIN formtypes ON licenseforms.formtypeid = formtypes.formtypeid)
		INNER JOIN licenses ON licenseforms.licenseid = licenses.licenseid;


--- Read License summary for hoovers and hints.
--set scan off;
CREATE OR REPLACE FUNCTION licensesummary(myval1 IN integer) RETURN VARCHAR2 IS

	str VARCHAR2(2000);
	CURSOR licensesummary_cur IS
	SELECT  licenses.licensename FROM clientlicenses INNER JOIN licenses ON clientlicenses.licenseid = licenses.licenseid
	WHERE (clientlicenses.clientid = CAST(myval1 AS int)) ORDER BY licenses.licensename;
    rc licensesummary_cur%ROWTYPE;
BEGIN

  FOR rc IN licensesummary_cur LOOP
		IF(str = '') THEN
			str := rc.licensename;
		ELSE
			str := str||'&#013'||rc.licensename;
		END IF;
  
	END LOOP;
	
	RETURN str;
	CLOSE licensesummary_cur; 
END;
/


CREATE VIEW vwaddresses AS
	SELECT addresses.addressid, addresstypes.addresstypename, addresses.clientid, addresses.address, addresses.street, addresses.town, 
	addresses.fax, addresses.email, addresses.mobilenum, postoffice.postalcode, countrys.countryname
	FROM addresses
	INNER JOIN addresstypes ON addresstypes.addresstypeid = addresses.addresstypeid
	INNER JOIN postoffice ON addresses.postofficeid = postoffice.postofficeid
	INNER JOIN countrys ON countrys.countryid = addresses.countryid;
	

CREATE OR REPLACE FORCE VIEW VWCLIENTS AS
  SELECT clients.buildingfloor, countrys.countryid, countrys.countryname, clients.clientid, upper(clients.clientname) as clientname, clients.address,clients.updated,
		clients.premises, clients.street, initcap(clients.town) as town, clients.telno, clients.email, clients.clientlogin, clients.firstpasswd,
		clients.mobilenum,clients.createdby,clients.updatedby,clients.fax,clients.dateenroled, clients.isactive, clients.details,clients.countrycode,
		('<a href="mailto:'||clients.email||'">'||email||'</a>' ) as sendmail,clients.compliant, clients.idnumber,clients.pin,clienttypes.clienttypename,
		clientcategorys.clientcategoryname,(clients.clientname ||'<br>'|| 'P.O.Box' || clients.address ||'<br>' || initcap(clients.town) || '-' || coalesce(clients.postalcode,postoffice.postalcode) || '<br>' || initcap(countrys.countryname)) as clientdetail,	
		('TelNo:' ||' '||clients.telno || '<br>' || 'Fax:'|| clients.fax || '<br>'|| 'Email:'|| '<a href="mailto:'|| clients.email ||'">'||email||'</a>' ) AS contact,
		('P.O.Box.' ||' '|| clients.address ||'<br>' || town || ',' || coalesce(clients.postalcode,postoffice.postalcode) || '<br>' || initcap(countrys.countryname)) as postaladdress,
		licensesummary(clients.clientid) AS licensesummary,clients.website,clients.lrnumber,clients.filenumber,postoffice.postofficeid,postoffice.postofficename,coalesce(clients.postalcode,postoffice.postalcode) as postalcode,
		postoffice.region,clientcategorys.clientcategoryid,clients.division,clients.isoldlcs, clients.isoldfsm, getClientContacts(clients.clientid) as clientcontacts,
		getClientStatus(clients.clientid) as clientstatus
	FROM (clients LEFT JOIN countrys ON clients.countryid = countrys.countryid)
	LEFT JOIN clienttypes ON clienttypes.clienttypeid = clients.clienttypeid
	LEFT JOIN clientcategorys ON clientcategorys.clientcategoryid = clients.clientcategoryid
	LEFT JOIN postoffice ON clients.postofficeid=postoffice.postofficeid;
	
		
-- b4 a license can be made active then this value must be zero.		
CREATE OR REPLACE FUNCTION getClientLicenceNA(myval1 IN integer) RETURN integer IS 
	myret int;
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	SELECT count(clientphaseid) INTO myret
	FROM clientphases
	WHERE (clientlicenseid = myval1) AND (approved = '0');
	COMMIT;
RETURN myret;
END;
/



-- used in the html view for colspans of INACTIVE LICENSES
CREATE OR REPLACE FUNCTION countclientlicense(myval1 IN integer)  RETURN integer IS
	myret int;
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	SELECT count(clientlicenseid) INTO myret
	FROM clientlicenses
	WHERE (clientid = myval1) and clientlicenses.isactive='0';
	COMMIT;

	RETURN myret;

END;
/

--INACTIVE ???
CREATE OR REPLACE FUNCTION countirisclientlicense(myval1 IN integer)  RETURN integer IS
	myret int;
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN

	SELECT count(lic_id) INTO myret
	FROM sms_licence
	WHERE (lic_owner_id = myval1) and lic_status not like 'R';
	COMMIT;

	RETURN myret;

END;
/



--the date of the last approval
CREATE OR REPLACE FUNCTION getLastApprovalDate(cli_lic_id IN INTEGER) RETURN VARCHAR IS
	PRAGMA AUTONOMOUS_TRANSACTION;    
	approvaldate varchar(20);
	BEGIN
	select to_char(clientphases.actiondate,'YYYYMM') into approvaldate
	from clientphases 
		inner join clientlicenses on clientphases.clientlicenseid = clientlicenses.clientlicenseid
		inner join licenses on clientlicenses.licenseid = licenses.licenseid
		inner join licensetypes on licenses.licensetypeid = licensetypes.licensetypeid
		where clientphases.clientlicenseid = cli_lic_id and licensetypes.forfsm='1'
		and clientapplevel = (select max(clientapplevel) from clientphases where approved='1' and clientlicenseid = cli_lic_id );
	COMMIT;
	RETURN approvaldate;

EXCEPTION
	WHEN OTHERS THEN
		RETURN 'error';

END;
/




--Last person assigned a task to do in a particular license application
CREATE OR REPLACE FUNCTION getLastAssignedUser(cli_lic_id IN INTEGER) RETURN VARCHAR IS
	PRAGMA AUTONOMOUS_TRANSACTION;    
	username varchar(20);
	BEGIN
	select vwclientlicensephases.assignedofficer into username
	from vwclientlicensephases 
		inner join clientlicenses on vwclientlicensephases.clientlicenseid = clientlicenses.clientlicenseid
		inner join licenses on clientlicenses.licenseid = licenses.licenseid
		inner join licensetypes on licenses.licensetypeid = licensetypes.licensetypeid
		where licensetypes.forfsm='1'
		and vwclientlicensephases.clientphaseid = (select max(clientphaseid) from clientphases where assignto is not null and clientlicenseid = cli_lic_id );
	COMMIT;
	RETURN username;

EXCEPTION
	WHEN OTHERS THEN
		RETURN 'error';

END;
/


--current phase (client's) in the licensing process
--improvement test
CREATE OR REPLACE FUNCTION getcurrentphase(cli_lic_id IN varchar2) RETURN varchar2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
    app int;
	phase varchar(20);
BEGIN
	--select UPPER(clientphases.clientphasename) into phase
	select clientphases.clientphasename into phase
	from clientphases 
		inner join clientlicenses on clientphases.clientlicenseid = clientlicenses.clientlicenseid
		inner join licenses on clientlicenses.licenseid = licenses.licenseid
		inner join licensetypes on licenses.licensetypeid = licensetypes.licensetypeid
		where clientphases.clientlicenseid = cli_lic_id
		and clientapplevel = (select min(clientapplevel) from clientphases where approved='0' and clientlicenseid = cli_lic_id );
	COMMIT;

	RETURN phase;

EXCEPTION
	WHEN OTHERS THEN
		RETURN 'EOF';

END;
/




CREATE OR REPLACE FUNCTION getNEXTphase(cli_lic_id IN varchar2) RETURN varchar2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
    app int;
	phase varchar(20);
BEGIN
	select clientphases.clientphasename into phase
	from clientphases 
		inner join clientlicenses on clientphases.clientlicenseid = clientlicenses.clientlicenseid
		inner join licenses on clientlicenses.licenseid = licenses.licenseid
		inner join licensetypes on licenses.licensetypeid = licensetypes.licensetypeid
		where clientphases.clientlicenseid = cli_lic_id
		and clientapplevel = (select min(clientapplevel) from clientphases where approved='0' and clientlicenseid = cli_lic_id) + 1;
	COMMIT;
	RETURN phase;

EXCEPTION
	WHEN OTHERS THEN
		RETURN 'EOF';

END;
/
 
--get the phase that comes after a specific phase
CREATE OR REPLACE FUNCTION getPhaseAfter(phase_name IN varchar, cli_lic_id IN varchar) RETURN varchar2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
    app int;
	phase varchar(20);
BEGIN
	select clientphases.clientphasename into phase
	from clientphases 
		inner join clientlicenses on clientphases.clientlicenseid = clientlicenses.clientlicenseid
		inner join licenses on clientlicenses.licenseid = licenses.licenseid
		inner join licensetypes on licenses.licensetypeid = licensetypes.licensetypeid
		where clientphases.clientlicenseid = cli_lic_id
		and clientapplevel = (select min(clientapplevel) from clientphases where clientphasename = phase_name and clientlicenseid = cli_lic_id) + 1;
	COMMIT;
	RETURN phase;

EXCEPTION
	WHEN OTHERS THEN
		RETURN 'EOF';

END;
/



--b4 clc
--NB: if there is a parent clientlicenseid then it should be used as clientlicenseid. this is used in cases of additional frequency application
--THIS VIEW IS SHARED WITH LCS
SET SCAN OFF;
CREATE or replace  view VWCLIENTLICENSES AS 
 SELECT vwclients.aaaduedate,vwlicenses.initialfee as MINANNUALFEE,clientlicenses.clientlicenseid, decode(clientlicenses.isfreqexpansion,'1',clientlicenses.parentclientlicenseid, clientlicenses.clientlicenseid) as effectiveclientlicenseid, (clientlicenses.clientlicenseid || ' Reference ID : ' ||coalesce(clientlicenses.parentclientlicenseid, clientlicenses.clientlicenseid)) as applicationid, vwclients.clientid, vwclients.clientname,vwclients.address, vwclients.street,vwclients.premises,vwclients.buildingfloor, vwlicenses.isterrestrial, vwlicenses.isvhf, vwlicenses.ismaritime, vwlicenses.isbroadcasting,
		vwclients.fax,clientlicenses.isactive, clientlicenses.isapproved, vwlicenses.licenseperiod,clientlicenses.samedateapp,clientlicenses.suspended, clientlicenses.iscancelled, clientlicenses.isterminated, clientlicenses.offersentdate,clientlicenses.R,clientlicenses.V,
  		vwclients.town,vwclients.telno,vwclients.email, vwlicenses.licenseid, vwlicenses.licensename, vwlicenses.nlf,vwlicenses.licensetypename, vwclients.mobilenum,vwclients.division, clientlicenses.islicensereinstatement,
		clientlicenses.rolloutdate, clientlicenses.rolledout, clientlicenses.applicationfee, clientlicenses.initialfee,clientlicenses.applicationdate,vwclients.postalcode,vwclients.compliant AS clientcompliance, 
		clientlicenses.annualfee, clientlicenses.purposeoflicense, clientlicenses.agtfee, clientlicenses.licensenumber,

		('TL/' || vwlicenses.licenseabbrev || '/' || vwclients.clientid) as newlicensenumber,

		clientlicenses.typeapprovalfee, vwclients.website, vwclients.lrnumber,vwclients.clientcategoryid,	
		('<a href="mailto:'||vwclients.email||'">'||vwclients.email||'</a>' ) as sendmail, countclientlicense(clientlicenses.clientid) as licensecount,vwlicenses.licenseabbrev,
		('Tel No: ' || vwclients.telno || '<br>' || 'Fax: '|| vwclients.fax ) AS contact, vwlicenses.forfsm, vwlicenses.forlcs,clientlicenses.licensedate,clientlicenses.licensestartdate,clientlicenses.licensestopdate,
		(vwclients.clientname || '<br>'||'P.O.Box ' || ' '|| vwclients.address ||'<br>' || initcap(vwclients.town) || ' - ' || vwclients.postalcode || '<br>' || vwclients.countryname) as postaladdress,
		('P.O.Box ' || vwclients.address ||'<br>' || initcap(vwclients.town) || ' - ' || vwclients.postalcode || '<br>' || vwclients.countryname) as reppostaladdress,
		vwclients.countryname, clientlicenses.approved, clientlicenses.rejected, clientlicenses.approve_email, clientlicenses.reject_email, clientlicenses.reject_reason,
		licensesummary(vwclients.clientid) AS licensesummary, clientlicenses.renewaldate, clientlicenses.exclusivebwMHz, vwclients.filenumber,vwlicenses.licenseterms,
		clientlicenses.rejecteddate, clientlicenses.details , getClientLicenceNA(clientlicenses.clientlicenseid) as ClientLicenceNA, coalesce(clc.clcid,0) as clcid, clc.clcnumber, clc.clcdate, vwlicenses.forta,clientlicenses.tacid,
		clientlicenses.categoryappliedfor ,clientlicenses.categoryapproved, clientlicenses.categoryrecomm,vwclients.clienttypename,vwclients.clientcategoryname,commiteeremarks,secretariatremarks,
		getcurrentphase(clientlicenses.clientlicenseid) as currentphase, getnextphase(clientlicenses.clientlicenseid) as nextphase, getphaseafter('dg', clientlicenses.clientlicenseid) as phaseafterdg,
		getLastApprovalDate(clientlicenses.clientlicenseid) as lastapprovaldate, vwclients.region,vwclients.postofficename,decode(vwlicenses.licensename,'Land Mobile Service','Networks','Aircraft Station','Aircrafts','Alarm Services','Alarms','Port Operations(Coast) Radio','RF 14b','Maritime Station','RF 14b','Terrestrial Point to Point Fixed Links','Links','Stations') as technicaldetail,
		vwlicenses.currencyunitname, vwlicenses.currencyabbrev, vwlicenses.currencyunitid,vwlicenses.clcorder, vwclients.clientcontacts, 
		clientlicenses.offerapproved, clientlicenses.offerapproveddate, 
		clientlicenses.isclcemailsent, clientlicenses.ispostclcemailsent, clientlicenses.isofferemailsent,
		clientlicenses.isdifferalemailsent, clientlicenses.isgazettementemailsent,	clientlicenses.islicenseapprovalemailsent,	clientlicenses.iscomplreturnsQemailsent,
		clientlicenses.iscomplreturnsAemailsent ,	clientlicenses.isAAAremindersent ,clientlicenses.isnummberallocationemailsent,clientlicenses.isTAcertificateemailsent ,	
		clientlicenses.isassignmentemailsent, clientlicenses.islicensereadyemailsent, clientlicenses.isinitialfeeemailsent, clientlicenses.isacknowlegementemailsent, clientlicenses.remarks,
		decode(vwlicenses.licenseid,513,'<a href="fsm?view=' || Cipher('350')|| '&blankpage=yes&filtervalue='|| Cipher(clientlicenses.clientlicenseid) || '" target="_blank">Amatuer License And Conditions</a>',vwlicenses.conditionslink) as conditionslink,    
		vwlicenses.isserviceprovider,vwlicenses.isvsat,vwlicenses.isinfrastructure,vwlicenses.ispostal,vwlicenses.iscontractor, getAllRemarks(clientlicenses.clientlicenseid) as generalremarks,
		decode(clientlicenses.isactive,'1', '<font color="green">Active</font>',decode(clientlicenses.suspended,'1','<font color="red">Suspended</font>',decode(clientlicenses.iscancelled,'1','<font color="red">Cancelled</font>',decode(clientlicenses.isterminated,'1','<font color="red">Terminated</font>','Under Construction')))) as licensestatus,
		getLicenseStatus(clientlicenses.clientlicenseid) as paymentstatus, getClientStatus(clientlicenses.clientid) as clientstatus,  rec.fullname as receivedby, clientlicenses.isexclusiveaccess,
		clientlicenses.isexpansion, clientlicenses.isexpansionapproved,	clientlicenses.skipclc, clientlicenses.isfreqexpansion,clientlicenses.isnetworkexpansion
	FROM clientlicenses 
	INNER JOIN vwclients ON clientlicenses.clientid = vwclients.clientid
	INNER JOIN vwlicenses ON clientlicenses.licenseid = vwlicenses.licenseid
	LEFT JOIN users rec ON clientlicenses.userid = rec.userid
	LEFT JOIN clc on clientlicenses.clcid = clc.clcid
	WHERE clientname is not null;


----------STEVE'S VERSION
---------END STEVE'S





--CLIENT STATUS
CREATE OR REPLACE FUNCTION getClientStatus(cli_id IN integer)  RETURN varchar IS	
	PRAGMA AUTONOMOUS_TRANSACTION;

	CURSOR licenses_cur IS
		SELECT licenses.licenseid, licenses.licensename, clientlicenses.isactive
		FROM clientlicenses
		INNER JOIN licenses ON clientlicenses.licenseid = licenses.licenseid
		WHERE clientlicenses.clientid = cli_id AND clientlicenses.isactive='1';
	
	rec_licenses licenses_cur%ROWTYPE;

BEGIN
	OPEN licenses_cur;
	FETCH licenses_cur INTO rec_licenses;

	--ACTIVE if at least one license is active
	IF (licenses_cur%NOTFOUND) then  	--if there is NO single active license
		CLOSE licenses_cur;
		return '<font color="red"><b>Inactive</b></font>';
	ELSE		--INACTIVE otherwise
		return '<font color="green"><b>Active</b></font>';
	END IF;
	

RETURN 'Unreachable Code';

END;
/


--OLD IRIS CLIENTS
CREATE OR REPLACE FUNCTION getIRISClientStatus(use_id IN integer)  RETURN varchar IS	
	PRAGMA AUTONOMOUS_TRANSACTION;

	CURSOR licenses_cur IS
		SELECT lic_id, lic_name, lic_status
		FROM sms_licence
		--INNER JOIN clientlicenses ON licenses.licenseid = clientlicenses.licenseid
		WHERE lic_owner_id = use_id AND lic_status = 'R';
	
	rec_licenses licenses_cur%ROWTYPE;

BEGIN
	OPEN licenses_cur;
	FETCH licenses_cur INTO rec_licenses;

	--ACTIVE if at least one license is active
	IF (licenses_cur%NOTFOUND) then  	--if there is NO single active license
		CLOSE licenses_cur;
		return '<font color="red"><b>Inactive</b></font>';
	ELSE		--ACTIVE otherwise
		CLOSE licenses_cur;
		return '<font color="green"><b>Active</b></font>';
	END IF;
	

RETURN 'Unreachable Code';

END;
/


--status of each license
CREATE OR REPLACE FUNCTION getLicenseStatus(cli_lic_id IN integer)  RETURN varchar IS	
	PRAGMA AUTONOMOUS_TRANSACTION;
	myret varchar(50);
	thisday integer; --day of the month
	thismonth integer; --month as integer

	CURSOR payment_cur IS
		select * 
		from licensepayments 
			inner join periods on licensepayments.periodid = periods.periodid
			where licensepayments.clientlicenseid = cli_lic_id and licensepayments.paymenttypeid = '3' and periods.periodid = (select periodid from periods where isactive='1') ;		--we also need to identify the period
		rec_payment payment_cur%ROWTYPE;

	CURSOR license_cur IS
		(select clientlicenseid, isactive, isexpired, decode(isactive,'1','Active',decode(iscancelled,'1','CANCELLED',decode(suspended,'1','SUSPENDED',decode(isterminated,'1','TERMINATED','In Active')))) as overalstatus
      from clientlicenses       
			where clientlicenseid = cli_lic_id)
    UNION
    (select lic_id as clientlicenseid, decode(lic_status,'R','1','0') as isactive,  decode(lic_status,'R','0','1') as isexpired, 'In Active' as overalstatus
      from sms_licence
      where sms_licence.lic_id = cli_lic_id);
		rec_license license_cur%ROWTYPE;
		
			
BEGIN

	OPEN payment_cur;
	FETCH payment_cur INTO rec_payment;

  OPEN license_cur;
	FETCH license_cur INTO rec_license;


	--if cancelled/suspended/terminated just show this info
	if (license_cur%NOTFOUND) then  	--if license not found
			CLOSE license_cur;
			return '<b>Unknown License</b>';
	elsif(rec_license.overalstatus != 'In Active' AND rec_license.overalstatus != 'Active') then
			return '<font color="red"><b>' || rec_license.overalstatus || '</b></font>';
	end if;

	select cast(to_char(current_date,'DD') as integer), cast(to_char(current_date,'MM') as integer) into thisday, thismonth from dual;

	--btwn may 1 and may 31 - AWAITING RENEWAL. This is incorrect since it doesnt take into consideration previously expired licenses. 
	--[* Workaround. Dont display inactive licenses]

	--january to april
	if(thismonth < 5)then

		if (license_cur%NOTFOUND) then  	--if license not found
			CLOSE license_cur;
			return '<b>Unknown License</b>';
		elsif(rec_license.isexpired = '1' and rec_license.isactive = '0') then	--if expired
			return '<font color="red"><b>Expired</b></font>';			
		elsif (rec_license.isexpired = '0' and rec_license.isactive = '1') then
			return '<font color="green"><b>Active</b></font>';			
		else
			return '<font color="red"><b>Invalid Status</b></font>';
		end if;
		
	end if;

	if(thismonth = 5)then --if may
		
		return 'Public Notice';		--Public Notice to be issued on Newspaper
		
	end if;
		
	if(thismonth = 6)then   --btwn June 1 and June 30 - if paid=renewed if unpaid=awaiting renewal		
		
		IF (payment_cur%NOTFOUND) then  	--if not entry found in licensepayments => not invoiced	
			CLOSE payment_cur;
			return '<b>Awaiting Renewal. <br>Not Invoiced</b>';
		ELSIF (rec_payment.paid='0') THEN		--if unpaid=awaiting renewal
			return '<font color="orange"><b>Awaiting Renewal</b></font>';
		ELSIF (rec_payment.paid='1') THEN		--if unpaid=awaiting renewal
			return '<font color="green"><b>Renewed</b></font>';
		ELSE
			return '<font color="red"><b>Unknown Status</b></font>';
		END IF; -- Close the cursor.
				
	end if;
			
	if(thismonth > 6)then    --after july 1 - if unpaid = expired ==with option to cancel and suspend
				
		IF (payment_cur%NOTFOUND) then  	--if not entry found in licensepayments => not invoiced	
			CLOSE payment_cur;
			return '<b>Awaiting Renewal. <br>Not Invoiced</b>';
		ELSIF (rec_payment.paid='0') THEN		--if unpaid=expired
			return '<font color="red"><b>Expired</b></font>';
		ELSIF (rec_payment.paid='1') THEN		--if paid=active
			return '<font color="green"><b>Active</b></font>';
		ELSE
			return '<font color="red"><b>Unknown Status</b></font>';
		END IF; -- Close the cursor.
				
	end if;
		
RETURN 'Unreachable Code';

END;
/






--stv
CREATE OR REPLACE FUNCTION countalllcslicense  RETURN integer IS
	myret int;
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	SELECT count(vwlicenses.licenseid) into myret
	FROM vwlicenses
	WHERE  nlf = '1' AND  forlcs = '1' ;
  COMMIT;
RETURN myret;
END;
/

CREATE OR REPLACE FUNCTION pickdefination(myval1 IN varchar2, myval2 IN varchar2, myval3 IN varchar2, myval4 IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;

	BEGIN
	IF(myval3 = 'Apply') THEN
			UPDATE clientdefination SET appliedfor = '1',userid = CAST(myval2 as int)
			WHERE clientdefinationid = CAST(myval1 as int);
			COMMIT;
		    RETURN 'Submitted';
		END IF;

		IF(myval3 = 'Recommend') THEN
			UPDATE clientdefination SET  recommended = '1', userid = CAST(myval2 as int)
			WHERE clientdefinationid = CAST(myval1 as int);
			COMMIT;
		    RETURN 'Recommend';
		END IF;

		IF(myval3 = 'Approve') THEN
			UPDATE clientdefination SET  approved = '1', userid = CAST(myval2 as int)
			WHERE clientdefinationid = CAST(myval1 as int);
			COMMIT;
		    RETURN 'Approved';
		END IF;
	
	COMMIT;
	RETURN 'Not Submitted';

END;
/

CREATE OR REPLACE FUNCTION confirmpayment(cli_phase_id IN varchar2,val2 IN varchar2,val3 IN varchar2,val4 IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	BEGIN
	  --UPDATE clientphases set paid='1' WHERE clientphaseid = CAST(cli_phase_id AS int);
		UPDATE licensepayments set paid='1' WHERE clientphaseid = CAST(cli_phase_id AS int);
		COMMIT;
	RETURN 'Payment Confirmed';
END;
/


CREATE OR REPLACE FUNCTION decomissionstation(sta_id IN varchar2,use_id IN varchar2,approval IN varchar2,filter_id IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;

	ordernumber varchar(50);
	emailstatus varchar(50);
	
	--we want to know the financial period ???????
	CURSOR period_cur IS
		SELECT periodid FROM periods WHERE periods.isactive = '1';
		rec_period period_cur%ROWTYPE;

	--credit amount calculation
	CURSOR credits_cur IS
		SELECT clientlicenses.clientlicenseid, clients.clientid, clients.clientname, clients.email, 
			licenses.isterrestrial, licenses.isvhf,clientlicenses.applicationdate,
			getCreditPeriod(sysdate) as creditperiod,
			round((stations.stationcharge * (getCreditPeriod(sysdate)/12)),2) as creditamount,		
			licenses.annualaccount, clientlicenses.isexclusiveaccess
		FROM stations
		INNER join clientlicenses on stations.clientlicenseid = clientlicenses.clientlicenseid
		INNER join clients on clientlicenses.clientid = clients.clientid
		INNER join licenses on clientlicenses.licenseid = licenses.licenseid
		WHERE stations.stationid = cast(sta_id as integer);

		credits_rec credits_cur%ROWTYPE;

	BEGIN
					
		OPEN period_cur;
		FETCH period_cur INTO rec_period;

		OPEN credits_cur;
		FETCH credits_cur INTO credits_rec;

		--update station status
		UPDATE stations set isactive = '0', decommissiondate = sysdate WHERE stations.stationid = cast(sta_id as integer); 
		COMMIT;

		--release assigned frequencies
		DELETE FROM frequencys WHERE frequencys.stationid = cast(sta_id as integer); 
		COMMIT;

		IF (credits_rec.isterrestrial='1') THEN		--we only issue credit notes for terrestrial stations
			
			--send email
			select sendMailNA(credits_rec.email, CAST(use_id as int), 'Decommissioned Stations', ('This notifies you of decomissioned Stations/Links, Come for your letter at CCK')) into emailstatus from dual;			
			--insert a credit note (contentious)
			--INSERT INTO licensepayments (paymenttypeid, clientlicenseid, amount, userid, productcode, periodid, ordernumber, details) 
			--VALUES(7, credits_rec.clientlicenseid , (credits_rec.creditamount * -1) ,CAST(use_id as int), credits_rec.annualaccount, rec_period.periodid, ordernumber, (' Credit Note for ' || sta_id));			
			--COMMIT;						

		END IF;
		
		RETURN 'Station Decommissioned';
END;
/





--SEND ORDERS + NOTIFICATION EMAIL FOR INITIAL LICENSE PAYMENT
CREATE OR REPLACE FUNCTION fsm_initial_payment(cli_phase_id IN varchar2,use_id IN varchar2,val3 IN varchar2,val4 IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;

	ordernumber varchar(50);
	emailstatus varchar(50);
	pos_at int;		--position of @ in the email
	pos_dot int;	--position of the first dot in the email address
  
	nullemail EXCEPTION;
	emptyemail EXCEPTION;
	invalidemail EXCEPTION;

	
	--we want to know the financial period ???????
	CURSOR period_cur IS
		SELECT periodid FROM periods WHERE periods.isactive = '1';
		rec_period period_cur%ROWTYPE;

	--fsm licenses payments - initial station charge
	CURSOR fsm_payments_cur IS
	--we need to use the function that calculates actual stationcharge considering the numberoffrequencies (modified/added or original). calculateFullStationCharge(stationid)
	SELECT vwclientlicenses.clientlicenseid, vwclientlicenses.offerapproved, clients.clientid, clients.clientname, clients.email, sum(stations.stationcharge) as stationcharge, round(sum(stationinitialcharge(stations.stationid, current_date))) as proratedcharge,
		count(stations.stationid) as stationcount, proratedChargePeriod(current_date) as initialchargeperiod, clientphases.clientphaseid, licenses.isterrestrial, licenses.isvhf,
		paymenttypes.paymenttypeid, licenses.initialaccount, vwclientlicenses.isexclusiveaccess
		from stations
		left join vwclientlicenses on stations.clientlicenseid = vwclientlicenses.effectiveclientlicenseid
		inner join clients on vwclientlicenses.clientid = clients.clientid
		inner join licenses on vwclientlicenses.licenseid = licenses.licenseid
		inner join clientphases on vwclientlicenses.clientlicenseid = clientphases.clientlicenseid
		inner join phases on clientphases.phaseid = phases.phaseid
		inner join paymenttypes on phases.paymenttypeid = paymenttypes.paymenttypeid			
		where (stations.transmitstationid is null) AND (clientphaseid = cast(cli_phase_id as int))
     group by vwclientlicenses.clientlicenseid, vwclientlicenses.offerapproved, clients.clientid, clients.clientname, clients.email, clientphases.clientphaseid, licenses.isterrestrial, licenses.isvhf,
		paymenttypes.paymenttypeid, licenses.initialaccount, vwclientlicenses.isexclusiveaccess;		
  
		fsm_pay_rec fsm_payments_cur%ROWTYPE;

	BEGIN
					
		OPEN period_cur;
		FETCH period_cur INTO rec_period;

		OPEN fsm_payments_cur;
		FETCH fsm_payments_cur INTO fsm_pay_rec;


		--IF OFFER HAS NOT BEEN APPROVED RETURN
		IF(fsm_pay_rec.offerapproved = '0') THEN
			raise_application_error(-20033,'OFFER NOT APPROVED, REQUEST REJECTED');	      
		END IF;
    
        
    --select 'FSM/' || fsm_ordernumber_seq.nextval into ordernumber from dual;
		select 'FSM/' || licensepayments_id_seq.nextval into ordernumber from dual;

		
		--variable initialization
		select instr(fsm_pay_rec.email,'@'),instr(fsm_pay_rec.email,'.') into pos_at, pos_dot from dual;
						
		--validate (simple) email address before sending
		if(fsm_pay_rec.email is NULL)then	        
			raise_application_error(-20030,'Client email NOT DEFINED ('||fsm_pay_rec.clientname|| '). Offer not sent');	
			--raise nullemail;
		elsif(fsm_pay_rec.email='')then
			raise_application_error(-20031,'Client email is EMPTY ('||fsm_pay_rec.clientname|| '). Offer not sent');	
			--raise emptyemail;
		elsif(pos_at=0 or pos_dot=0)then	--if there is no '@' or at least one '.' in the email address
			raise_application_error(-20032,'Client ('||fsm_pay_rec.clientname|| ') has invalid email. Offer not sent');
			--raise invalidemail;
		end if;

		--FOR TERRESTRIAL
		IF(fsm_pay_rec.PAYMENTTYPEID = 2) AND (fsm_pay_rec.isterrestrial =  '1') THEN
				
			--send email first
			select sendMailNA(fsm_pay_rec.email, CAST(use_id as int), 'CCK Offer Letter', ('Pay CCK the amount of KShs. ' || round(fsm_pay_rec.proratedcharge) || ', Order Number: ' || ordernumber ||'. <br><b>Details</b><br> Number of Stations or Links is : ' || fsm_pay_rec.stationcount || ' Charge Period is: ' || fsm_pay_rec.initialchargeperiod || ' months. Amount Includes Kshs 1000 application fee')) into emailstatus from dual;
			
			INSERT INTO licensepayments (licensepaymentid,paymenttypeid,clientlicenseid,amount,userid,productcode,periodid,clientphaseid,ordernumber,details) 
			VALUES(ordernumber,fsm_pay_rec.paymenttypeid, fsm_pay_rec.clientlicenseid , fsm_pay_rec.proratedcharge ,CAST(use_id as int), fsm_pay_rec.initialaccount, rec_period.periodid, fsm_pay_rec.clientphaseid, ordernumber, ' Number of Stations or Links is : ' || fsm_pay_rec.stationcount || ' Charge Period is: ' || fsm_pay_rec.initialchargeperiod || ' months. Amount Includes Kshs 1000 application fee');			
			COMMIT;			
      
      --record the offer sending date
      update clientlicenses set offersentdate = sysdate where clientlicenseid=fsm_pay_rec.clientlicenseid;
      commit;
  
      update clientphases set userid = cast(use_id as int) where clientphaseid = cast(cli_phase_id as int);
      commit;
  
			RETURN 'Offer Email Sent to : ' || fsm_pay_rec.email;

		END IF;

		--non terrestrial .. continue	
		IF (fsm_pay_rec.PAYMENTTYPEID = 2) THEN		
      --send email
			select sendMailNA(fsm_pay_rec.email, CAST(use_id as int), 'CCK Offer Letter', ('Pay CCK the amount of KShs. ' || round(fsm_pay_rec.proratedcharge) || ', Order Number:'|| ordernumber ||'. <br><b>Details</b><br> Number of Stations is : ' || fsm_pay_rec.stationcount || ' Charge Period is: ' || fsm_pay_rec.initialchargeperiod || ' months.')) into emailstatus from dual;
						
			INSERT INTO licensepayments (licensepaymentid,paymenttypeid,clientlicenseid,amount,userid,productcode,periodid,clientphaseid,ordernumber,details) 
			VALUES(ordernumber,fsm_pay_rec.paymenttypeid, fsm_pay_rec.clientlicenseid ,fsm_pay_rec.proratedcharge ,CAST(use_id as int), fsm_pay_rec.initialaccount, rec_period.periodid, fsm_pay_rec.clientphaseid, ordernumber, ' Number of Stations is : ' || fsm_pay_rec.stationcount || ' Charge Period is:' || fsm_pay_rec.initialchargeperiod || ' months.');							
			COMMIT;

      --record the offer sending date
      update clientlicenses set offersentdate = sysdate where clientlicenseid=fsm_pay_rec.clientlicenseid;
      commit;
  
      update clientphases set userid = cast(use_id as int) where clientphaseid = cast(cli_phase_id as int);
      commit;

			RETURN 'Offer Email Sent to : ' || fsm_pay_rec.email;

		END IF;

		RETURN 'Unreachable';

--EXCEPTION
  --WHEN nullemail THEN    
  --  RETURN 'Client email NOT DEFINED ('||fsm_pay_rec.clientname|| '). Offer not sent';
  --WHEN emptyemail THEN    
  --  RETURN 'Client email is EMPTY ('||fsm_pay_rec.clientname|| '). Offer not sent';
  --WHEN invalidemail THEN    
  --  RETURN 'Client ('||fsm_pay_rec.clientname|| ') has invalid email. Offer not sent';
  --WHEN OTHERS THEN
  --  RETURN 'UNKNOWN ERROR';
END;
/







--INCASE OF A WRONG INITIAL PAYMENT ORDER we resend the email,the orders (also provide a reference to the original order)
CREATE OR REPLACE FUNCTION correct_fsm_initial_payment(cli_lic_id IN varchar2,use_id IN varchar2,val3 IN varchar2,val4 IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;

	ordernumber varchar(50);
	emailstatus varchar(50);
	pos_at int;		--position of @ in the email
	pos_dot int;	--position of the first dot in the email address
  
	nullemail EXCEPTION;
	emptyemail EXCEPTION;
	invalidemail EXCEPTION;
	
	--we want to know the financial period ???????
	CURSOR period_cur IS
		SELECT periodid FROM periods WHERE periods.isactive = '1';
		rec_period period_cur%ROWTYPE;

	--get the other order of initial payment (paymenttypeid = 2)
	CURSOR prev_order_cur IS    
    select licensepaymentid, clientphaseid, productcode, posteddate, userid, amount, invoicenumber, details     
    from licensepayments 
    where licensepaymentid = 
      (select max(licensepaymentid) from licensepayments
      where clientlicenseid=cast(cli_lic_id as int) and paymenttypeid = 2);
		prev_order_rec prev_order_cur%ROWTYPE;

    --the new order
  CURSOR new_fsm_payments_cur IS
      --we use the function that calculates actual stationcharge considering the numberoffrequencies (modified/added or original). calculateFullStationCharge(stationid)
      SELECT vwclientlicenses.clientlicenseid, vwclientlicenses.offerapproved, clients.clientid, clients.clientname, clients.email, sum(calculateFullStationCharge(stations.stationid)) as calculatedstationcharge,
        sum(calculateFullStationCharge(stations.stationid)*(proratedChargePeriod(current_date)/12)) as calculatedproratacharge,
        sum(stations.stationcharge) as stationcharge, round(sum(stationinitialcharge(stations.stationid, current_date))) as proratedcharge,
        count(stations.stationid) as stationcount, proratedChargePeriod(current_date) as initialchargeperiod, 
        clientphases.clientphaseid, licenses.isterrestrial, licenses.isvhf,
        paymenttypes.paymenttypeid, licenses.initialaccount, vwclientlicenses.isexclusiveaccess
        from stations
        left join vwclientlicenses on stations.clientlicenseid = vwclientlicenses.effectiveclientlicenseid
        inner join clients on vwclientlicenses.clientid = clients.clientid
        inner join licenses on vwclientlicenses.licenseid = licenses.licenseid
        inner join clientphases on vwclientlicenses.clientlicenseid = clientphases.clientlicenseid
        inner join phases on clientphases.phaseid = phases.phaseid
        inner join paymenttypes on phases.paymenttypeid = paymenttypes.paymenttypeid			
        where (stations.transmitstationid is null) AND vwclientlicenses.clientlicenseid=cast(cli_lic_id as int) AND (phases.phasename = 'frequency')
        group by vwclientlicenses.clientlicenseid, vwclientlicenses.offerapproved, clients.clientid, clients.clientname, clients.email, clientphases.clientphaseid, licenses.isterrestrial, licenses.isvhf,
        paymenttypes.paymenttypeid, licenses.initialaccount, vwclientlicenses.isexclusiveaccess;		
      
        new_fsm_pay_rec new_fsm_payments_cur%ROWTYPE;

	BEGIN
					
		OPEN period_cur;
		FETCH period_cur INTO rec_period;

		OPEN prev_order_cur;
		FETCH prev_order_cur INTO prev_order_rec;

    OPEN new_fsm_payments_cur;
		FETCH new_fsm_payments_cur INTO new_fsm_pay_rec;

    --IF AMOUNTS DO NOT DIFFERE. JUST IGNORE....
    IF(round(prev_order_rec.amount) = round(new_fsm_pay_rec.calculatedproratacharge))THEN
      RETURN 'Current and Previous Fee are NOT different. ORDER NOT SENT ';
    END IF;

		--IF OFFER HAS NOT BEEN APPROVED RETURN
		IF(new_fsm_pay_rec.offerapproved = '0') THEN
			raise_application_error(-20033,'OFFER NOT APPROVED, REQUEST REJECTED');	      
		END IF;
    
    --SIDE EFFECT: THE SEQUENCE ADVANCES AUTOMATICALY ONCE U READ NEXTVAL FROM IT 
    --select 'FSM/' || fsm_ordernumber_seq.nextval into ordernumber from dual;
		--select 'FSM/' || licensepayments_id_seq.nextval into ordernumber from dual;
		
		--variable initialization
		select instr(new_fsm_pay_rec.email,'@'),instr(new_fsm_pay_rec.email,'.') into pos_at, pos_dot from dual;
						
		--validate (simple) email address before sending
		if(new_fsm_pay_rec.email is NULL)then	        
			raise_application_error(-20030,'Client email NOT DEFINED ('|| new_fsm_pay_rec.clientname|| '). Offer not sent');	
			--raise nullemail;
		elsif(new_fsm_pay_rec.email='')then
			raise_application_error(-20031,'Client email is EMPTY ('|| new_fsm_pay_rec.clientname|| '). Offer not sent');	
			--raise emptyemail;
		elsif(pos_at=0 or pos_dot=0)then	--if there is no '@' or at least one '.' in the email address
			raise_application_error(-20032,'Client ('|| new_fsm_pay_rec.clientname|| ') has invalid email. Offer not sent');
			--raise invalidemail;
		end if;

		--FOR TERRESTRIAL
		IF(new_fsm_pay_rec.PAYMENTTYPEID = 2) AND (new_fsm_pay_rec.isterrestrial =  '1') THEN
				
			--send email first
			select sendMailNA(new_fsm_pay_rec.email, prev_order_rec.userid, 'Correction: CCK Offer Letter', ('You are required to pay CCK the amount of KShs. ' || round(new_fsm_pay_rec.calculatedproratacharge) || '.<br>This is a correction of the wrong order ' || prev_order_rec.licensepaymentid || ' quoting KShs(' || round(prev_order_rec.amount) || '). Sorry for any Inconvenience. <br><b>Details</b><br> Number of Stations or Links is : ' || new_fsm_pay_rec.stationcount || ' Charge Period is: ' || new_fsm_pay_rec.initialchargeperiod || ' months. Amount Includes Kshs 1000 application fee')) into emailstatus from dual;
			
			INSERT INTO licensepayments (paymenttypeid,clientlicenseid,amount,userid,productcode,periodid,clientphaseid,ordernumber,details) 
			VALUES(new_fsm_pay_rec.paymenttypeid, new_fsm_pay_rec.clientlicenseid , new_fsm_pay_rec.calculatedproratacharge , 0, new_fsm_pay_rec.initialaccount, rec_period.periodid, new_fsm_pay_rec.clientphaseid, ordernumber, ' Correction: Offending Order ' || prev_order_rec.licensepaymentid || ' quoting KShs(' || round(prev_order_rec.amount) || ').<br>Number of Stations/Links is : ' || new_fsm_pay_rec.stationcount || ' Charge Period is: ' || new_fsm_pay_rec.initialchargeperiod || ' months. Amount Includes Kshs 1000 application fee');			
			COMMIT;			

      --cancel/void previous order
      UPDATE licensepayments SET isvoid = '1' WHERE licensepaymentid = prev_order_rec.licensepaymentid;
      COMMIT;
      
      --record the offer sending date. AFTER SUCCESS
      update clientlicenses set offersentdate = sysdate where clientlicenseid=new_fsm_pay_rec.clientlicenseid;
      commit;
      
      CLOSE period_cur;
      CLOSE prev_order_cur;
      CLOSE new_fsm_payments_cur;

			RETURN 'Offer Email Sent to : ' || new_fsm_pay_rec.email;

		END IF;

		--non terrestrial .. continue	
		IF (new_fsm_pay_rec.PAYMENTTYPEID = 2) THEN		
      --send email			
      select sendMailNA(new_fsm_pay_rec.email, prev_order_rec.userid, 'Correction: CCK Offer Letter', ('You are required to pay CCK the amount of KShs. ' || round(new_fsm_pay_rec.calculatedproratacharge) || '.<br>This is a correction of the wrong order ' || prev_order_rec.licensepaymentid || ' quoting KShs(' || round(prev_order_rec.amount) || '). Sorry for any Inconvenience. <br><b>Details</b><br> Number of Stations is : ' || new_fsm_pay_rec.stationcount || ' Charge Period is: ' || new_fsm_pay_rec.initialchargeperiod || ' months.')) into emailstatus from dual;
						
			INSERT INTO licensepayments (paymenttypeid,clientlicenseid,amount,userid,productcode,periodid,clientphaseid,ordernumber,details)     
			VALUES(new_fsm_pay_rec.paymenttypeid, new_fsm_pay_rec.clientlicenseid, new_fsm_pay_rec.calculatedproratacharge, 0, new_fsm_pay_rec.initialaccount, rec_period.periodid, new_fsm_pay_rec.clientphaseid, ordernumber, ' Correction: Offending Order ' || prev_order_rec.licensepaymentid || ' quoting KShs(' || round(prev_order_rec.amount) || ').<br>Number of Stations is : ' || new_fsm_pay_rec.stationcount || ' Charge Period is:' || new_fsm_pay_rec.initialchargeperiod || ' months.');							
    
			COMMIT;

      --cancel/void previous order
      UPDATE licensepayments SET isvoid = '1' WHERE licensepaymentid = prev_order_rec.licensepaymentid;
      COMMIT;
      
      
      --record the offer sending date. AFTER SUCCESS
      update clientlicenses set offersentdate = sysdate where clientlicenseid = new_fsm_pay_rec.clientlicenseid;
      commit;  
     
      CLOSE period_cur;
      CLOSE prev_order_cur;
      CLOSE new_fsm_payments_cur;

			RETURN 'Offer Email Sent to : ' || new_fsm_pay_rec.email;

		END IF;

    CLOSE period_cur;
		CLOSE prev_order_cur;
    CLOSE new_fsm_payments_cur;

		RETURN 'Unreachable';

--EXCEPTION
  --WHEN nullemail THEN    
  --  RETURN 'Client email NOT DEFINED ('||fsm_pay_rec.clientname|| '). Offer not sent';
  --WHEN emptyemail THEN    
  --  RETURN 'Client email is EMPTY ('||fsm_pay_rec.clientname|| '). Offer not sent';
  --WHEN invalidemail THEN    
  --  RETURN 'Client ('||fsm_pay_rec.clientname|| ') has invalid email. Offer not sent';
  --WHEN OTHERS THEN
  --  RETURN 'UNKNOWN ERROR';
  
    
END;
/







--fsm order number sequence
CREATE SEQUENCE fsm_ordernumber_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;


--licensenumber sequence
CREATE SEQUENCE licensenumber_seq MINVALUE 1 INCREMENT BY 1 START WITH 11000;

--Activate License
CREATE OR REPLACE FUNCTION activatelicense(cli_lic_id IN varchar2,val2 IN varchar2,val3 IN varchar2,val4 IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	BEGIN
	  UPDATE clientlicenses set licensenumber = licensenumber_seq.nextval,isactive='1' WHERE clientlicenseid = CAST(cli_lic_id AS int);
	  COMMIT;
	RETURN 'License Activated';
END;
/

--eg picklicense('566', '147', 'Select' ,'10925') 
CREATE OR REPLACE FUNCTION picklicense(lic_id IN varchar2, myval2 IN varchar2, myval3 IN varchar2, cli_id IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;

	--lookup this user in the clients table
	CURSOR sms_use_cur IS		
	SELECT clientid,clientname from clients where clientid=cli_id;

	rec sms_use_cur%ROWTYPE;

	BEGIN	 
		OPEN sms_use_cur;
		FETCH sms_use_cur INTO rec;
 
	  --!!! IF NOT IN CLIENTS TABLE and LICENSE = FSM (typeid=16) insert this person into clients table so that he is visible at clientlicenses
	  IF (sms_use_cur%NOTFOUND) THEN
      INSERT INTO clients(clientname,clienttypeid,clientcategoryid,licenseid,countryid,filenumber,address,postalcode,email,town)
			select sms_users.use_name,43,48,cast(lic_id as int),'KE',sms_users.use_birth_location,sms_users.use_mail_address,sms_users.use_mail_postcode,sms_users.use_mail_email,'Nairobi'
			from sms_users
			where use_id=cli_id;
      COMMIT;
	  END IF;

	  INSERT INTO clientlicenses  (licenseid,applicationdate,clientid) values (CAST(lic_id AS int),SYSDATE,CAST(cli_id AS int));
	  COMMIT;
	RETURN ' Submitted';
END;
/







--eg delete clientlicense by making clientid reference a non existent client
--b4 training
CREATE OR REPLACE FUNCTION deleteclientlicense(cli_lic_id IN varchar2, myval2 IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;

	BEGIN	 
			
		IF(approval = 'Deactivate')  THEN
			UPDATE clientlicenses SET suspended = '1' where clientlicenseid = CAST(cli_lic_id as int);			
			COMMIT;
		    RETURN 'Deactivated';
		END IF;

		IF(approval = 'Reactivate')  THEN
			UPDATE clientlicenses SET suspended = '0' where clientlicenseid = CAST(cli_lic_id as int);			
			COMMIT;
		    RETURN 'Re Activated';
		END IF;

		update clientlicenses set clientid = (99999000000 + clientid) where clientlicenseid = cast(cli_lic_id as integer);
		commit;

	RETURN 'Client License Modified';
END;
/


--SUSPEND
CREATE OR REPLACE FUNCTION suspendclientlicense(cli_lic_id IN varchar2, myval2 IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;

	BEGIN	 
			
		IF(approval = 'Re-Instate')  THEN
			update clientlicenses set isactive='1', suspended='0', iscancelled='0', isterminated='0'  where clientlicenseid = cast(cli_lic_id as integer);
			COMMIT;
			update licenseviolations set isreinstated = '1', reinstateddate = sysdate;
			COMMIT;
		    RETURN 'Re-Instated';
		END IF;

		IF(approval = 'Suspend')  THEN
			update clientlicenses set suspended='1', isactive='0' where clientlicenseid = cast(cli_lic_id as integer);
			COMMIT;
		    RETURN 'Suspended';
		END IF;

		IF(approval = 'Unsuspend')  THEN
			update clientlicenses set suspended='0', isactive='1' where clientlicenseid = cast(cli_lic_id as integer);
			COMMIT;
		    RETURN 'UN Suspended';
		END IF;

	RETURN 'Unreachable Code';
END;
/



CREATE OR REPLACE FUNCTION deleteclientstation(cli_sta_id IN varchar2, myval2 IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;

	BEGIN	 
		delete from clientstations where clientstationid = cast(cli_sta_id as integer);
    commit;
	RETURN 'Client Station Deleted';
END;
/


CREATE OR REPLACE FUNCTION deletestation(sta_id IN varchar2, myval2 IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;

	BEGIN	 
		--delete from stations where stationid = cast(sta_id as integer);
		update stations set clientlicenseid = null where stationid = cast(sta_id as integer);
    commit;
	RETURN 'Station Deleted';
END;
/










CREATE OR REPLACE FUNCTION picktalicense(myval1 IN varchar2, myval2 IN varchar2, myval3 IN varchar2, myval4 IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	BEGIN
	IF(myval3 = 'Individual') THEN
		INSERT INTO clientlicenses  (licenseid,applicationdate,clientid) values ('64',SYSDATE,CAST(myval1 AS int));
		INSERT INTO equipmentapprovals  (clientid) values (CAST(myval1 AS int));
	COMMIT;
	RETURN 'Selected';
	END IF;

	IF(myval3 = 'Marketing') THEN
		INSERT INTO clientlicenses  (licenseid,applicationdate,clientid) values ('70',SYSDATE,CAST(myval1 AS int));
		INSERT INTO equipmentapprovals  (clientid) values (CAST(myval1 AS int));
	COMMIT;
	RETURN 'Selected';
	END IF;
	
	RETURN 'Selected';
END;
/

CREATE OR REPLACE FUNCTION forclc(myval1 IN varchar2, myval2 IN varchar2, myval3 IN varchar2, myval4 IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	BEGIN
	  UPDATE clientlicenses  SET clcid = CAST(myval4 AS int) WHERE clientlicenseid = CAST(myval1 AS int);
	  COMMIT;
	RETURN ' Submitted';
END;
/



CREATE OR REPLACE FUNCTION scheduletask(fmi_schedule_id IN varchar2, myval2 IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;

	BEGIN
		--original but faulty
		--IF approval = 'Schedule' THEN
		--	UPDATE fmitasks SET fmischeduleid = CAST(filter_id AS int) WHERE fmitaskid = CAST(fmi_schedule_id AS int);
		--	COMMIT;
		--END IF;

		IF approval = 'Schedule' THEN
			UPDATE fmitasks SET fmischeduleid = CAST(fmi_schedule_id AS int) WHERE fmitaskid = CAST(filter_id AS int);
			COMMIT;
		END IF;

		IF approval = 'Maintenance' THEN
			UPDATE maintenancetasks SET fmischeduleid = CAST(fmi_schedule_id AS int) WHERE maintenancetaskid = CAST(filter_id AS int);
			COMMIT;
		END IF;

	RETURN 'Task Scheduled Successfully. [scheduleid = ' || filter_id || ']';
END;
/

--confirmmaintenancetask



CREATE OR REPLACE FUNCTION fortac(myval1 IN varchar2, myval2 IN varchar2, myval3 IN varchar2, myval4 IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	BEGIN
	  UPDATE clientlicenses  SET tacid = CAST(myval4 AS int) WHERE clientlicenseid = CAST(myval1 AS int);
	  COMMIT;
	RETURN ' Submitted';
END;
/



create or replace FUNCTION SUBMITRETURNS (myval1 IN varchar2, myval2 IN varchar2, myval3 IN varchar2, myval4 IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
  clientlicense integer;
  reason varchar2(240);
   CONDITIONS varchar2(720);

	BEGIN

    select compliancereason||', '||'<BR>'||myval3    ,CONDITIONSNOTIFICATIONLETTER ||'<BR>'  into reason,CONDITIONS from  periodlicenses WHERE periodlicenseid = CAST(myval1 as int);
	 IF(myval3 = 'Quarter1')  THEN
			UPDATE periodlicenses SET qr1 = '1', userid = CAST(myval2 as int)
			WHERE periodlicenseid = CAST(myval1 as int);
			COMMIT;
	END IF;
  --SELECT submitreturns('2061', '17', 'AR Non Compliant', '') from dual
	 IF(myval3 = 'Quarter2')  THEN
			UPDATE periodlicenses SET qr2 = '1', userid = CAST(myval2 as int)
			WHERE periodlicenseid = CAST(myval1 as int);
			COMMIT;
	END IF;
	 IF(myval3 = 'Quarter3')  THEN
			UPDATE periodlicenses SET qr3 = '1', userid = CAST(myval2 as int)
			WHERE periodlicenseid = CAST(myval1 as int);
			COMMIT;
	END IF;
	 IF(myval3 = 'Quarter4')  THEN
			UPDATE periodlicenses SET qr4 = '1', userid = CAST(myval2 as int)
			WHERE periodlicenseid = CAST(myval1 as int);
			COMMIT;
	END IF;
	 IF(myval3 = 'Annual')  THEN
			UPDATE periodlicenses SET ar = '1', userid = CAST(myval2 as int)
			WHERE periodlicenseid = CAST(myval1 as int);
			COMMIT;
	END IF;
  IF(myval3 = 'AR Compliant')  THEN
  select clientlicenseid into clientlicense from periodlicenses where periodlicenseid = CAST(myval1 as int);
			UPDATE periodlicenses SET retcompliant = '1', userid = CAST(myval2 as int),clientcompliance = '1'
			WHERE periodlicenseid = CAST(myval1 as int);
     		UPDATE clientlicenses set ROLLOUTDATE = sysdate ,ROLLEDOUT = '1' WHERE clientlicenseid = clientlicense;
			UPDATE COMPLCONDITIONSAPPVL SET COMPLIED = '1' WHERE periodlicenseid = CAST(myval1 as int) AND COMPLIANCETYPE = 'AR';
			COMMIT;
	END IF;
  
  IF(myval3 = 'AR Non Compliant')  THEN
			UPDATE periodlicenses SET retcompliant = '0',clientcompliance = '0', userid = CAST(myval2 as int),compliancereason = reason,
    CONDITIONSNOTIFICATIONLETTER = CONDITIONS,conditionscompliant = '0'
			WHERE periodlicenseid = CAST(myval1 as int);
			UPDATE COMPLCONDITIONSAPPVL SET COMPLIED = '0' WHERE periodlicenseid = CAST(myval1 as int) AND COMPLIANCETYPE = 'AR';
			COMMIT;
	END IF;
  
  IF(myval3 = 'Compliant AAA')  THEN
			UPDATE periodlicenses SET AAACOMPLIANT = '1', userid = CAST(myval2 as int), clientcompliance = '1'
			WHERE periodlicenseid = CAST(myval1 as int);
			UPDATE COMPLCONDITIONSAPPVL SET COMPLIED = '1' WHERE periodlicenseid = CAST(myval1 as int) AND COMPLIANCETYPE = 'AAA';
			COMMIT;
	END IF;
  --SELECT submitreturns('2061', '17', 'Compliant AAA', '2061') from dual
  IF(myval3 = 'Non Compliant AAA')  THEN
			UPDATE periodlicenses SET AAACOMPLIANT = '0', clientcompliance = '0', userid = CAST(myval2 as int),compliancereason = reason,
			CONDITIONSNOTIFICATIONLETTER = CONDITIONS,conditionscompliant = '0'
			WHERE periodlicenseid = CAST(myval1 as int);
			UPDATE COMPLCONDITIONSAPPVL SET COMPLIED = '0' WHERE periodlicenseid = CAST(myval1 as int) AND COMPLIANCETYPE = 'AAA';
			COMMIT;
	END IF;
  RETURN 'complete';
 COMMIT;
END;
 



CREATE OR REPLACE FUNCTION submitaudited(myval1 IN varchar2, myval2 IN varchar2, myval3 IN varchar2, myval4 IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	BEGIN
	 IF(myval3 = 'submitted')  THEN
			UPDATE periodlicenses SET annualreturns = '1', userid = CAST(myval2 as int)
			WHERE periodlicenseid = CAST(myval1 as int);
			COMMIT;
	END IF;
	 
  RETURN 'Submitted';
 COMMIT;
END;
/

CREATE OR REPLACE FUNCTION forcompliance(myval1 IN varchar2, myval2 IN varchar2, myval3 IN varchar2, myval4 IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	BEGIN
	  INSERT INTO compliance(compliancescheduleid,clientid) VALUES(CAST(myval4 AS int),CAST(myval1 AS int));
	  COMMIT;
	RETURN ' Submitted';
END;
/

CREATE OR REPLACE FUNCTION installationapprove(myval1 IN varchar2, myval2 IN varchar2, myval3 IN varchar2, myval4 IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	BEGIN
	IF(myval3 = 'Approved')  THEN
	  UPDATE installations SET approved = '1',rejected='0' WHERE installationid = CAST(myval1 as int);
	 COMMIT;
	END IF;

	IF(myval3 = 'Rejected')  THEN
	  UPDATE installations SET approved = '0', rejected='1' WHERE installationid = CAST(myval1 as int);
	 COMMIT;
	END IF;
	RETURN ' Submitted';
END;
/

CREATE OR REPLACE FUNCTION forclientcompliance(myval1 IN varchar2, myval2 IN varchar2, myval3 IN varchar2, myval4 IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	BEGIN
	  INSERT INTO clientcompliance(clientlicenseid) VALUES(CAST(myval1 AS int));
	  COMMIT;
	RETURN ' Submitted';
END;
/

CREATE OR REPLACE FUNCTION updreturnscompliance(myval1 IN varchar2, myval2 IN varchar2, myval3 IN varchar2, myval4 IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	BEGIN
	  UPDATE periodlicenses SET retcompliant = '1'
	  WHERE periodlicenseid = CAST(myval1 AS int);
	  COMMIT;
	RETURN ' Submitted';
END;
/




CREATE OR REPLACE FUNCTION countalllcslicensees  RETURN integer IS
	myret int;
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	SELECT count(vwclientlicenses.clientlicenseid) into myret
	FROM vwclientlicenses
	WHERE     forlcs = '1' AND nlf = '1';
  COMMIT;
RETURN myret;
END;
/

CREATE  VIEW vwalllcslicenses	as
	SELECT vwlicenses.licensename,vwclients.clientid, vwclients.clientname,vwclients.clientdetail,
  countalllcslicense () as licensecount,vwclients.details,vwlicenses.licenseid
	FROM  vwlicenses, vwclients
	WHERE  nlf = '1' AND  forlcs = '1' ;




CREATE OR REPLACE VIEW vwclientpayments AS
SELECT clients.clientid,periods.periodid, (periods.startdate || periods.enddate) as periodsummary, paymenttypes.paymenttypeid, paymenttypes.paymenttypename,
		clientlicenses.clientlicenseid,licensepayments.licensepaymentid,
		 licenses.licensename, clients.clientname, licensepayments.amount, licensepayments.posteddate, licensepayments.ordernumber, licensepayments.invoicenumber, licensepayments.invoicedate,
     licensepayments.paid, licensepayments.receiptamount, licensepayments.receiptnumber
	FROM clients
	INNER JOIN clientlicenses on clients.clientid = clientlicenses.clientid
	INNER JOIN licenses ON clientlicenses.licenseid = licenses.licenseid
	INNER JOIN licensepayments on clientlicenses.clientlicenseid = licensepayments.clientlicenseid
	INNER JOIN paymenttypes on licensepayments.paymenttypeid = paymenttypes.paymenttypeid
	INNER JOIN periods on licensepayments.periodid = periods.periodid;
  




		
CREATE FUNCTION getClientFormNA(myval1 IN integer) RETURN integer IS
	myret int;
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	SELECT count(clientphaseid) INTO myret 
	FROM clientphases
	WHERE (clientformtypeid = myval1) AND (approved = 'O');
	COMMIT;

RETURN myret;
END;
/
			
CREATE VIEW vwclientformtypes AS
	SELECT vwclientlicenses.clientid, vwclientlicenses.clientname, vwclientlicenses.licenseid, vwclientlicenses.licensename,
		vwclientlicenses.clientlicenseid, formtypes.formtypeid, formtypes.formtypename, formtypes.formnumber,
		('<a href="cckforms?formtypeid='|| formtypes.formtypeid || '&clientformtypeid=' || clientformtypes.clientformtypeid
		|| '" target="_blank">' || formtypes.formnumber || '</a>') as formlink,
		('<a href="cckforms?formtypeid='|| formtypes.formtypeid || '&clientformtypeid=' || clientformtypes.clientformtypeid
		|| '&disabled=true" target="_blank">' || formtypes.formnumber || '</a>') as formviewlink,
		clientformtypes.clientformtypeid, clientformtypes.isactive, clientformtypes.rejected, clientformtypes.applicationdate,
		clientformtypes.submit, clientformtypes.submitdate, clientformtypes.ApproveDate, clientformtypes.RejectedDate, 
		clientformtypes.details, getClientFormNA(clientformtypes.clientformtypeid) as ClientFormNA
	FROM (clientformtypes INNER JOIN vwclientlicenses ON clientformtypes.clientlicenseid = vwclientlicenses.clientlicenseid)
		INNER JOIN formtypes ON clientformtypes.formtypeid = formtypes.formtypeid;

CREATE VIEW vwclientforms AS
	SELECT vwclientformtypes.clientformtypeid, forms.formid, forms.formtypeid, forms.qorder, forms.shareline, forms.fortitle, forms.subformgrid,
		forms.question, clientforms.clientformid, clientforms.answer
	FROM (clientforms INNER JOIN vwclientformtypes ON clientforms.clientformtypeid = vwclientformtypes.clientformtypeid)
		INNER JOIN forms ON clientforms.formid = forms.formid;




--this is a clone of the Java Function Cipher in baraza web. So that we can create subreport/branchkey elements inside SQL
--msg is subreport value eg if subreport="100" msg will be '100'
create or replace FUNCTION Cipher(msg IN varchar) RETURN VARCHAR IS

mystr varchar(50);
charVal integer;
total integer;
i integer;
strlength integer;
average integer;

PRAGMA AUTONOMOUS_TRANSACTION;

BEGIN
		mystr := '';
		total := 0;
		charVal := 0;

		if(msg is null) then
			return '';
		end if;

		select length(msg) into strlength from dual;
		
		if(strlength = 0) then
			return '';
		end if;
		
		i := 1;
		while (i <= strlength) loop
					
			select (cast(substr(msg,i,1) as int)+48) into charVal from dual;

			if(charVal < 59) then
				charVal := charVal + 100;
			elsif(charVal < 79)  then
				charVal := charVal + 150;
			elsif(charVal < 99)  then
				charVal := charVal + 250;
			else 
				charVal := charVal + 300;
			end if;

			total := total + charVal;

			--mystr := mystr ||  (select to_char(charVal) from dual);
			select concat(mystr, charVal) into mystr from dual;

			i := i+1;

		end loop;
    
		--average := total / strlength;		
		select trunc(total/strlength) into average from dual;		--integer division 
		select concat(to_char(average),mystr) into mystr from dual;

		return mystr;
END;



CREATE OR REPLACE FUNCTION getRowLines(myval1 IN integer, myval2 IN integer) RETURN integer IS
myret int;
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	SELECT max(answerline) INTO myret
	FROM clientsubforms
	WHERE (clientformtypeid = myval1) and (formid = myval2);
COMMIT;

RETURN myret;
END;
/


CREATE VIEW vwclientsubforms AS
	SELECT vwclientformtypes.clientformtypeid, subforms.subformid, subforms.formid, subforms.qorder, subforms.question,
		clientsubforms.clientsubformid, clientsubforms.answerline, clientsubforms.answer
	FROM (clientsubforms INNER JOIN vwclientformtypes ON clientsubforms.clientformtypeid = vwclientformtypes.clientformtypeid)
		INNER JOIN subforms ON clientsubforms.subformid = subforms.subformid;

CREATE VIEW vwclientapprovallist AS
	SELECT clientformtypes.clientformtypeid, clientformtypes.clientlicenseid,
		clientformtypes.formtypeid, clientformtypes.IsActive, clientformtypes.Rejected,
		phases.phaseid, phases.usergroupid, usergroups.usergroupname,
		phases.phaselevel, phases.returnlevel,phases.phasename,phases.compliance,phases.approval
	FROM clientformtypes CROSS JOIN 
	(phases INNER JOIN usergroups ON phases.usergroupid = usergroups.usergroupid)
	WHERE clientformtypes.formtypeid = phases.formtypeid;

CREATE VIEW vwclientlicenseapprovals AS
	SELECT clientlicenses.clientlicenseid, clientlicenses.clientid, clientlicenses.licenseid,
		clientlicenses.IsActive, clientlicenses.Rejected, clientlicenses.applicationdate,
		phases.phaseid, phases.usergroupid, usergroups.usergroupname,
		phases.phaselevel, phases.returnlevel,phases.phasename,phases.compliance,phases.approval
	FROM clientlicenses CROSS JOIN 
	(phases INNER JOIN usergroups ON phases.usergroupid = usergroups.usergroupid)
	WHERE clientlicenses.licenseid = phases.licenseid;
	
CREATE OR REPLACE FUNCTION getChecklistNA(myval1 IN integer)  RETURN integer IS
	myret int;
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	SELECT count(clientchecklistid) INTO myret
	FROM clientchecklists
	WHERE (clientphaseid = myval1) AND (approved = '0');
	COMMIT;
RETURN myret;
END;
/

CREATE OR REPLACE FUNCTION getClientPhaseFNA(myval1 IN integer, myval2 IN integer) RETURN integer IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	myret int;
BEGIN
	SELECT count(clientphases.clientphaseid) INTO myret
	FROM clientphases INNER JOIN phases ON clientphases.phaseid = phases.phaseid
	WHERE (clientphases.approved = '0') AND (clientphases.clientformtypeid = myval1) AND (phases.phaselevel < myval2);
	COMMIT;

RETURN myret;
END;
/


CREATE VIEW vwclientformphases AS
	SELECT vwformphases.phaseid, vwformphases.usergroupid, vwformphases.usergroupname, 
		vwformphases.phaselevel, getChecklistNA(clientphases.clientphaseid) as ChecklistNA,
		vwformphases.returnlevel, vwformphases.formtypeid, vwformphases.formtypename,vwformphases.compliance,vwformphases.approval,
		users.userid, users.username, users.fullname, clientphases.clientphaseid, clientphases.clientformtypeid,
		clientphases.approved, clientphases.rejected, clientphases.actiondate, clientphases.narrative, clientphases.details,
		vwclientformtypes.licensename, vwclientformtypes.clientid, vwclientformtypes.clientname,
		getClientPhaseFNA(clientphases.clientformtypeid, vwformphases.phaselevel) as ClientPhaseFNA
	FROM ((clientphases INNER JOIN vwclientformtypes ON clientphases.clientformtypeid = vwclientformtypes.clientformtypeid)
		INNER JOIN vwformphases ON clientphases.phaseid = vwformphases.phaseid)
		INNER JOIN users ON clientphases.userid = users.userid;

--used by subreport
create view vwphaseremarks as
	select clientphases.clientlicenseid,clientphases.clientphaseid,clientphases.clientphasename,clientphases.actiondate,clientphases.narrative, users.userid,users.username
	from clientphases
	inner join users on clientphases.userid = users.userid;



CREATE OR REPLACE FUNCTION getClientPhaseLNA(myval1 IN integer, myval2 IN integer) RETURN integer IS
	myret int;
	unpaid int;

CURSOR phases_cur IS

	SELECT DISTINCT phases.phaseid, 
	licenses.applicationfee,licenses.annualfee,licenses.initialfee,licenses.typeapprovalfee,
	phases.forpayment,clientphases.clientlicenseid,phases.phaselevel,
	phases.approval,phases.compliance
	FROM phases INNER JOIN clientphases ON clientphases.phaseid = phases.phaseid 
	INNER JOIN licenses ON licenses.licenseid = phases.licenseid 
	WHERE  (clientphases.clientlicenseid = myval1) AND (phases.approval = '1');

	rd phases_cur%ROWTYPE;

	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  OPEN phases_cur;
  FETCH phases_cur INTO rd;
  
	--test
 IF  (rd.approval = '1') THEN
	
	IF(rd.phaselevel = 1)	THEN --if its the first one do not ignore corresponding entry in licensepayments... 
		SELECT count(clientphases.clientphaseid) INTO unpaid
		FROM clientphases 
		INNER JOIN phases ON clientphases.phaseid = phases.phaseid
		INNER JOIN licensepayments ON clientphases.clientlicenseid =licensepayments.clientlicenseid
		WHERE (phases.approval = '1') AND (clientphases.approved = '1') AND (phases.forpayment = '1') AND (licensepayments.paid = '0')	--for approval and approved, for payment but not yet paid for		
			AND (phases.phaselevel = myval2) AND (clientphases.clientlicenseid = myval1) ;
	END IF;

	IF(rd.phaselevel <> 1)	THEN --if its not the first phase continue
		SELECT count(clientphases.clientphaseid) INTO unpaid
		FROM clientphases 
		INNER JOIN phases ON clientphases.phaseid = phases.phaseid
		INNER JOIN licensepayments ON clientphases.clientlicenseid =licensepayments.clientlicenseid
		WHERE (phases.approval = '1') AND (clientphases.approved = '1') AND (phases.forpayment = '1') AND (licensepayments.paid = '0')	--for approval and approved, for payment but not yet paid for		
			AND (phases.phaselevel < myval2) AND (clientphases.clientlicenseid = myval1) ;
	END IF;

	SELECT count(clientphases.clientphaseid) INTO myret
	  FROM clientphases 
	  INNER JOIN phases ON clientphases.phaseid = phases.phaseid	 
	  WHERE (phases.approval = '1') AND (clientphases.approved = '0') --for approval but havent yet bn approved (ie some checklists r pending)
		AND (phases.phaselevel < myval2) AND (clientphases.clientlicenseid = myval1) ;	

	return (unpaid + myret);
 
 END IF;

	--test
	
  IF (rd.compliance = '1') THEN
	SELECT count(clientphases.clientphaseid) INTO myret
	  FROM clientphases INNER JOIN phases ON clientphases.phaseid = phases.phaseid
  	  INNER JOIN licensepayments ON licensepayments.clientlicenseid = clientphases.clientlicenseid
	  WHERE ((clientphases.approved = '1')  AND (phases.compliance = '1') 
	  AND (phases.forpayment = '1' AND licensepayments.paid = '0') OR (clientphases.approved = '0')  AND (phases.compliance = '1') 
	  AND (phases.forpayment = '0')) AND (phases.phaselevel < myval2);
	RETURN myret;
	
END IF;

RETURN '?';
CLOSE phases_cur;
END;
/



CREATE OR REPLACE FUNCTION countClientPhases(myval1 IN integer) RETURN integer IS
myret int;
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	SELECT count(clientphases.clientphaseid) INTO myret
	FROM clientphases WHERE (clientphases.approved = '0') AND (clientphases.clientlicenseid = myval1) ;
	COMMIT;
	RETURN myret;
END;
/



--calculate non prorated stationcharge 
CREATE OR REPLACE FUNCTION calculateFullStationCharge(sta_id IN integer) RETURN integer IS
	
	myret int;
	PRAGMA AUTONOMOUS_TRANSACTION;
	
	--get relevant charge info for this station
	CURSOR station_charge_cur IS
SELECT stations.stationid, decode(vhfnetwork.extranumberoffrequencies,0,decode(stations.extranumberoffrequencies,0,stations.numberoffrequencies,stations.extranumberoffrequencies),vhfnetwork.extranumberoffrequencies) as numberoffrequencies, licenseprices.licensepriceid, licenseprices.licenseid,
			licenseprices.stationclassid, licenseprices.hasfixedcharge, licenseprices.typename, licenseprices.amount, 
      --licenseprices.unitgroups, licenseprices.onetimefee, licenseprices.perlicense, licenseprices.perstation, 
      licenseprices.perfrequency, licenseprices.functname, licenseprices.formula, licenses.initialfee, licenses.annualfee					
		FROM stations
		INNER JOIN licenseprices ON stations.licensepriceid = licenseprices.licensepriceid      
		INNER JOIN LICENSES ON licenseprices.licenseid = licenses.licenseid
    LEFT JOIN vhfnetwork ON stations.vhfnetworkid = vhfnetwork.vhfnetworkid
		WHERE stations.stationid = sta_id;
		rec_station_charge station_charge_cur%ROWTYPE;
      
BEGIN
  
	OPEN station_charge_cur;
	FETCH station_charge_cur INTO rec_station_charge;
	
	--IF licenseprices.perfrequency = '1' THEN
		myret := rec_station_charge.amount * rec_station_charge.numberoffrequencies;
	--ELSE
	--	return -1;
	--END IF;

	CLOSE station_charge_cur;
	RETURN myret;
END;
/




--get the number of months to the end of the year
create or replace function proratedChargePeriod(fromdate IN varchar2) return integer is
	val varchar(2);
	intval int;
begin
	Select to_char(to_date(fromdate),'MM') into val FROM DUAL;
	intval := cast(val as int);
	
	--if jan, feb or march..
	if(intval <= 3) then	
		return (6 - intval + 1); -- +1
	end if;

	--if less than three months (april,may or june) to start of another financial year..
	if((intval > 3) and (intval < 7)) then	--count the months to jul 1 and add 12 months and return this as the period
		return (6 - intval) + 12 + 1; -- +1
	end if;

	--otherwise (July to Dec) 
	if(intval >= 7) then	--count the months to Dec and add 6 months and return this as the period
		return (12 - intval) + 6 + 1; -- +1
	end if;
	
end;
/




--get the number of months to the end of the year
create or replace function getCreditPeriod(fromdate IN varchar2) return integer is
	val varchar(2);
	intval int;			--month number converted into integer
begin
	--Select to_char(to_date(fromdate),'MM') into val FROM DUAL;
	Select to_char(sysdate,'MM') into val FROM DUAL;
	intval := cast(val as int);
	
	--btwn jan and june
	if(intval <= 6) then	--count the months to Dec and add 6 months and return this as the period
		return (6 - intval);
	else	--btwn jun and dec
	--if((intval >= 6) and (intval < 12)) then	--count the months to jul 1 and add 12 months and return this as the period
		return 6 + (12-intval);
	end if;
		
end;
/



--fromdate should default to current_date (during functioncall)
--FOR CLIENTSTATIONS
create or replace function calculateinitialcharge(cli_sta_id in varchar2,fromdate in varchar2) return real is
	tprice real;
	fprice real;
begin
	select tentativeprice into tprice from clientstations where clientstationid = cli_sta_id;
	fprice := tprice * proratedChargePeriod(current_date)/12;
	return fprice;
end;
/

--station charge 
--FOR STATIONS
CREATE OR REPLACE FUNCTION stationinitialcharge(sta_id in varchar2,fromdate in varchar2) return real is
	tprice real;
	fprice real;
BEGIN
	--if not prorated just return stationcharge
	select stationcharge into tprice from stations where stationid = sta_id;
	fprice := tprice * proratedChargePeriod(current_date)/12;
	return fprice;
EXCEPTION
	WHEN OTHERS THEN
		RETURN -1;
end;
/

--exclusive bandwidth ANNUAL charge         . PRORATED REQUIRED ALSO
CREATE OR REPLACE FUNCTION exclusiveBWannualcharge(cli_lic_id in varchar2) return real is
	
	annualprice real;
	proratedprice real;

	weightingfactor real;
	bwMHz real;
	
BEGIN
	select exclusivebwMHz into bwMHz from clientlicenses where clientlicenseid = cast(cli_lic_id as int);
	weightingfactor := 6;
	annualprice :=  bwMHz  * 1000 * weightingfactor * 1043.65 / 8.5;
	return annualprice;
EXCEPTION
	WHEN OTHERS THEN
		RETURN 0;
end;
/


--FOR IRIS STATIONS
CREATE OR REPLACE FUNCTION sms_station_charge(staid in varchar2,fromdate in varchar2) return real is
		
  fee real;
  
BEGIN
	fee := 0;
  
  FOR myrec IN (SELECT sta_lic_id, sta_id, sta_class, status, typename, amount, hasfixedcharge
		FROM sms_station
		LEFT JOIN licenseprices on sms_station.sta_class = licenseprices.stationclassid
		WHERE sta_id = cast(staid as int)) 
    
    LOOP
      --myret :=     
      if(myrec.hasfixedcharge = '1')then    --AIRCRAFTS
        fee := myrec.amount;      
      else
        fee := -1;
      end if;
    
    END LOOP;
  
  return fee;
  
EXCEPTION
	WHEN OTHERS THEN
		RETURN -1;
end;
/


CREATE OR REPLACE FORCE VIEW VWPAYMENTPHASES AS 
  SELECT vwlicensepayments.INVOICENUMBER,
    vwclientlicenses.clientlicenseid,
    vwclientlicensephases.phaseid,
    vwclientlicenses.clientname,
    vwclientlicensephases.ClientPhaseLNA,
    vwclientlicenses.applicationdate,
    vwclientlicenses.forta,
    vwclientlicenses.licensename,
    vwclientlicenses.licenseabbrev,
    vwclientlicenses.MINANNUALFEE AS initialfee,
    vwclientlicensephases.approved,
    vwclientlicensephases.rejected,
    vwclientlicenses.licensecount,
    vwclientlicenses.clientid,
    vwclientlicensephases.narrative,
    vwclientlicensephases.usergroupname,
    vwclientlicensephases.ChecklistNA,
    vwclientlicensephases.phaselevel,
    vwclientlicensephases.clientphasename,
    vwclientlicenses.forlcs,
    vwclientlicenses.forfsm,
    vwclientlicenses.postaladdress,
    vwclientlicensephases.clientphaseid,
    vwclientlicenses.categoryappliedfor,
    vwclientlicenses.categoryapproved,
    vwclientlicenses.categoryrecomm,
    vwlicensephases.compliance,
    vwlicensephases.approval,
    vwclientlicensephases.pending,
    countClientPhases(vwclientlicensephases.clientphaseid) AS countphases,
	getcurrentphase(vwclientlicenses.clientlicenseid) as currentphase,
    vwlicensepayments.paid,
	vwlicensepayments.posteddate,
    vwlicensepayments.salesorder,
    vwlicensepayments.invoiced,
    phases.paymenttypeid,
    paymenttypes.paymenttypename,
    vwlicensepayments.licensepaymentid,
    vwlicensepayments.amount || '' || vwclientlicenses.currencyabbrev AS fullamount,
    proratedChargePeriod(vwlicensepayments.invoicedate) AS invmonths,
    vwclientlicenses.applicationfee,
    vwclientlicenses.annualfee AS baseannualfee,
    vwlicensepayments.invoicedate,
    vwlicensepayments.town,
    vwlicensepayments.country,
    vwlicensepayments.address,
    vwlicensepayments.postalcode,
    vwlicensepayments.periodid,
    vwlicensepayments.amount,
    vwlicensepayments.orcinvdate,
    vwlicensepayments.fullname,
    (vwlicensepayments.amount - vwclientlicenses.MINANNUALFEE) AS proratedfee
  FROM vwclientlicenses
  INNER JOIN vwclientlicensephases ON vwclientlicensephases.clientlicenseid = vwclientlicenses.clientlicenseid
  INNER JOIN vwlicensephases  ON vwclientlicensephases.phaseid = vwlicensephases.phaseid
  INNER JOIN vwlicensepayments  ON vwlicensepayments.clientphaseid = vwclientlicensephases.clientphaseid
  INNER JOIN phases  ON vwclientlicensephases.phaseid = phases.phaseid
  INNER JOIN paymenttypes  ON paymenttypes.paymenttypeid = phases.paymenttypeid;
 

														

														



--MERGED TABLES - WITH IRIS DATA
																																																		                                                                                      
--for old clients we use the lic_id from the table sms_licence as our clientlicenseid

--aka vwclients
CREATE OR REPLACE VIEW vwmergedclients AS	
(SELECT distinct use_id as clientid, use_name as clientname, use_address as postaladdress, ('TelNo:' || use_mail_tel || '<br>' || 'Fax:'|| use_mail_fax || '<br>'|| 'Email:'|| '<a href="mailto:'|| use_email ||'">'|| use_email ||'</a>' ) AS contact, use_mail_tel as telno, use_mail_fax as fax,
  ('<a href="mailto:'|| use_mail_email ||'">'|| use_mail_email ||'</a>' ) as sendmail,'1' as isactive,( use_name ||'<br>'|| 'P.O.Box' || use_address ||'<br>' || initcap(use_city) || '-' || use_postcode || '<br>' || initcap(countryname)) as clientdetail,
  use_postcode as postalcode,use_city as town,use_address as address, 'Directors Not Defined' as directors
		FROM sms_users 		 
		inner join sms_licence on sms_users.use_id=sms_licence.lic_owner_id 	--get only the clients with active licenses
		left join countrys on substr(sms_users.use_country_id,0,2) = countrys.countryid
		where sms_licence.LIC_STATUS = 'R')
	UNION
	(SELECT distinct clientid, clientname, ('P.O.Box.' || address ||'<br>' || town || ',' || postalcode || '<br>' || initcap(countryname)) as postaladdress,  ('TelNo:' || telno || '<br>' || 'Fax:'|| fax || '<br>'|| 'Email:'|| '<a href="mailto:'|| email ||'">'||email||'</a>' ) AS contact, telno, fax,
  ('<a href="mailto:'|| email||'">'||email||'</a>' ) as sendmail, isactive,(clientname ||'<br>'|| 'P.O.Box' || address ||'<br>' || initcap(town) || '-' || postalcode || '<br>' || initcap(countryname)) as clientdetail,  postalcode, town, address, clientcontacts as directors
	FROM vwclients);


--aka vwclientlicenses
CREATE OR REPLACE VIEW vwmergedclientlicenses AS	
	(SELECT use_id as clientid, upper(use_name) as clientname, 
	getIRISClientStatus(sms_users.use_id) as clientstatus,
	decode(sta_class,'ML','Land Mobile Service','FB','Land Mobile Service','MA','Aircraft Station','BT','Broadcasting TV','FP','Port Station','AT','Amateur Station','MS','Ship Station','BC','Broadcasting Radio', 'Unknown') as licensename, '' as isexclusiveaccess,
	use_address as postaladdress, 
	('TelNo:' || use_mail_tel || '<br>' || 'Fax:'|| use_mail_fax || '<br>'|| 'Email:'|| '<a href="mailto:'|| use_email ||'">'|| use_email ||'</a>' ) AS contact, use_email as email,
	('<a href="mailto:'|| use_mail_email ||'">'|| use_mail_email ||'</a>' ) as sendmail, 
	'1' as forfsm, '0' as forlcs, decode(lic_status,'R','1','0') as isactive, lic_id as clientlicenseid,( use_name ||'<br>'|| 'P.O.Box' || use_address ||'<br>' || initcap(use_city) || '-' || use_postcode || '<br>' || initcap(countryname)) as clientdetail,
	use_postcode as postalcode,use_city as town,use_address as address, countirisclientlicense(sms_users.use_id) as licensecount,
	getLicenseStatus(sms_licence.lic_id) as paymentstatus, isrenewalreminderemailsent, isoverduepaymentemailsent,
	('<a href="/fsm/reports/pdfs/'|| sta_class || ' - conditions.pdf" target="_blank">' || sta_class || ' Conditions</a>') as conditionslink,
	sms_licence.lic_name as remarks
		FROM sms_users 
		inner join sms_licence on sms_users.use_id=sms_licence.lic_owner_id 
		inner join sms_station on sms_licence.lic_id=sms_station.sta_lic_id 
		left join countrys on substr(sms_users.use_country_id,0,2)=countrys.countryid)
	UNION
	(SELECT clientlicenses.clientid, upper(clients.clientname) as clientname, 
	getClientStatus(clientlicenses.clientid) as clientstatus, 
	licenses.licensename, clientlicenses.isexclusiveaccess,
	('P.O.Box.' || clients.address ||'<br>' || town || ',' || postoffice.postalcode || '<br>' || initcap(countrys.countryname)) as postaladdress, 
	('TelNo:' || clients.telno || '<br>' || 'Fax:'|| clients.fax || '<br>'|| 'Email:'|| '<a href="mailto:'|| clients.email ||'">'||email||'</a>' )AS contact,
	clients.email, ('<a href="mailto:'||clients.email||'">'||email||'</a>' ) as sendmail, 
	licensetypes.forfsm, licensetypes.forlcs, clientlicenses.isactive, clientlicenses.clientlicenseid,(clients.clientname ||'<br>'|| 'P.O.Box' || clients.address ||'<br>' || initcap(clients.town) || '-' || postoffice.postalcode || '<br>' || initcap(countrys.countryname)) as clientdetail, 
	postoffice.postalcode, clients.town, clients.address, countclientlicense(clients.clientid) as licensecount,
	getLicenseStatus(clientlicenses.clientlicenseid) as paymentstatus, isrenewalreminderemailsent, isoverduepaymentemailsent,
	('<a href="/fsm/reports/pdfs/'|| licenses.licensename || ' - conditions.pdf" target="_blank">' ||licenses.licensename|| ' Conditions</a>') as conditionslink,
	'' as remarks
	FROM clientlicenses
	INNER JOIN licenses ON clientlicenses.licenseid = licenses.licenseid
	INNER JOIN licensetypes ON licenses.licensetypeid = licensetypes.licensetypeid
	INNER JOIN clients ON clientlicenses.clientid = clients.clientid
	INNER JOIN countrys ON clients.countryid = countrys.countryid
	LEFT JOIN postoffice ON clients.postofficeid = postoffice.postofficeid);

--aka stations
CREATE OR REPLACE VIEW vwmergedstations AS 
	SELECT stations.stationid, stations.stationname, stations.stationcallsign, stations.aircrafttype, stations.aircraftregno, stations.stationclassid,
	stations.vesselname, stations.vesseltypename, stations.imonumber, stations.grosstonnage, clients.clientname,
	FROM stations
	INNER JOIN clientlicenses ON stations.clientlicenseid = clientlicenses.clientlicenseid
	INNER JOIN licenses ON clientlicenses.licenseid = licenses.licenseid
	INNER JOIN clients ON clientlicenses.clientid = clients.clientid


CREATE OR REPLACE VIEW vwdistinctclients AS	
	(SELECT distinct use_id as clientid, upper(use_name) as clientname, 
	getIRISClientStatus(sms_users.use_id) as clientstatus,
	decode(sta_class,'ML','Land Mobile Service','FB','Land Mobile Service','MA','Aircraft Station','BT','Broadcasting TV','FP','Port Station','AT','Amateur Station','MS','Ship Station','BC','Broadcasting Radio', 'Unknown') as licensename,
	( use_name ||'<br>'|| 'P.O.Box' || use_address ||'<br>' || initcap(use_city) || '-' || use_postcode || '<br>' || initcap(countryname)) as clientdetail,
	'1' as forfsm, '0' as forlcs, decode(lic_status,'R','1','0') as isactive
		FROM sms_users 
		inner join sms_licence on sms_users.use_id=sms_licence.lic_owner_id 
		left join sms_station on sms_licence.lic_id=sms_station.sta_lic_id 
		left join countrys on substr(sms_users.use_country_id,0,2)=countrys.countryid)
	UNION
	(SELECT distinct clientlicenses.clientid, upper(clients.clientname) as clientname, 
	getClientStatus(clientlicenses.clientid) as clientstatus, 
	licenses.licensename,
	(clientname ||'<br>'|| 'P.O.Box' || address ||'<br>' || initcap(town) || '-' || postalcode || '<br>' || initcap(countryname)) as clientdetail,
	licensetypes.forfsm, licensetypes.forlcs, clientlicenses.isactive
	FROM clientlicenses
	INNER JOIN licenses ON clientlicenses.licenseid = licenses.licenseid
	INNER JOIN licensetypes ON licenses.licensetypeid = licensetypes.licensetypeid
	INNER JOIN clients ON clientlicenses.clientid = clients.clientid
	INNER JOIN countrys ON clients.countryid = countrys.countryid
	LEFT JOIN postoffice ON clients.postofficeid = postoffice.postofficeid);






CREATE OR REPLACE VIEW vwuniqueFSMclients AS	
	(SELECT distinct use_id as clientid, upper(use_name) as clientname, 
	getIRISClientStatus(sms_users.use_id) as clientstatus,
	--decode(sta_class,'ML','Land Mobile Service','FB','Land Mobile Service','MA','Aircraft Station','BT','Broadcasting TV','FP','Port Station','AT','Amateur Station','MS','Ship Station','BC','Broadcasting Radio', 'Unknown') as licensename,
	( use_name ||'<br>'|| 'P.O.Box' || use_address ||'<br>' || initcap(use_city) || '-' || use_postcode || '<br>' || initcap(countryname)) as clientdetail,
	'1' as forfsm, '0' as forlcs 
  --decode(lic_status,'R','1','0') as isactive
		FROM sms_users 
		inner join sms_licence on sms_users.use_id=sms_licence.lic_owner_id 
		left join sms_station on sms_licence.lic_id=sms_station.sta_lic_id 
		left join countrys on substr(sms_users.use_country_id,0,2)=countrys.countryid)
	UNION
	(SELECT distinct clientlicenses.clientid, upper(clients.clientname) as clientname, 
	getClientStatus(clientlicenses.clientid) as clientstatus, 
	--licenses.licensename,
	(clientname ||'<br>'|| 'P.O.Box' || address ||'<br>' || initcap(town) || '-' || postalcode || '<br>' || initcap(countryname)) as clientdetail,
	licensetypes.forfsm, licensetypes.forlcs
  --, clientlicenses.isactive
	FROM clientlicenses
	INNER JOIN licenses ON clientlicenses.licenseid = licenses.licenseid
	INNER JOIN licensetypes ON licenses.licensetypeid = licensetypes.licensetypeid
	INNER JOIN clients ON clientlicenses.clientid = clients.clientid
	INNER JOIN countrys ON clients.countryid = countrys.countryid
	LEFT JOIN postoffice ON clients.postofficeid = postoffice.postofficeid
  WHERE licensetypes.forfsm = '1' and licensetypes.forlcs = '0');



CREATE OR REPLACE VIEW VWCLIENTLICENSEPHASES AS 
  SELECT vwlicensephases.phaseid, vwlicensephases.usergroupname, vwlicensephases.usergroupid, clientphases.forwarded_date, clientphases.remarks,
		vwlicensephases.phaselevel, vwlicensephases.returnlevel, vwlicensephases.licenseid, clientphases.assignto, ass.fullname as assignedofficer, clientphases.assignedby, mgr.fullname as assigningmanager,
		vwlicensephases.licensename, getChecklistNA(clientphases.clientphaseid) as ChecklistNA,clientphases.DEFFERED, vwlicensephases.numbering,
		users.userid, users.username, users.fullname, clientlicenses.clientid, clientphases.clientphasename, clientphases.isdone,vwlicensephases.compliance, vwlicensephases.approval,
		clientphases.mgr_approved, clientphases.ad_approved, clientphases.dir_approved,	clientphases.dg_approved,
		clientphases.clientphaseid, clientphases.clientformtypeid, clientphases.clientlicenseid,clientphases.clientapplevel,clientphases.pending,
		clientphases.approved, clientphases.rejected, clientphases.withdrawn, clientphases.actiondate, clientphases.narrative, clientphases.details, clientphases.paid,
		getClientPhaseLNA(clientphases.clientlicenseid, vwlicensephases.phaselevel) as ClientPhaseLNA,vwlicensephases.annualschedule
		FROM clientphases 
		INNER JOIN clientlicenses ON clientphases.clientlicenseid = clientlicenses.clientlicenseid
		INNER JOIN vwlicensephases ON clientphases.phaseid = vwlicensephases.phaseid
		LEFT JOIN users ON clientphases.userid = users.userid
		LEFT JOIN users ass ON clientphases.assignto = ass.userid
		LEFT JOIN users mgr ON clientphases.assignto = mgr.userid;



CREATE VIEW vwclientdefaultlist AS
	SELECT clientphases.clientphaseid, clientphases.clientformtypeid,
		clientphases.phaseid, clientphases.userid, clientphases.approved,
		clientphases.rejected, clientphases.actiondate,checklists.individual,
		checklists.checklistid, checklists.phasenumber, checklists.requirement
	FROM clientphases CROSS JOIN checklists
	WHERE clientphases.phaseid = checklists.phaseid;



CREATE OR REPLACE VIEW vwclientchecklists AS
	SELECT checklists.checklistid, checklists.phasenumber, checklists.requirement, clientchecklists.clientchecklistid,
		clientchecklists.clientphaseid, clientchecklists.approved, clientchecklists.rejected, clientchecklists.actiondate,
		clientchecklists.narrative, clientchecklists.details, checklists.individual, upper(clients.clientname) as clientname, 
		licenses.licensename,
		upper( phases.phasename) as phasename
	FROM clientchecklists 
	INNER JOIN checklists ON clientchecklists.checklistid = checklists.checklistid
	INNER JOIN clientphases ON clientchecklists.clientphaseid = clientphases.clientphaseid
	INNER JOIN phases ON clientphases.phaseid = phases.phaseid
	INNER JOIN clientlicenses ON clientphases.clientlicenseid = clientlicenses.clientlicenseid
	INNER JOIN clients ON clientlicenses.clientid = clients.clientid
	INNER JOIN licenses ON clientlicenses.licenseid = licenses.licenseid;



CREATE OR REPLACE FORCE VIEW VWALLCHECKLISTS AS 
  SELECT vwclientlicensephases.NUMBERING,
    add_months(TO_CHAR(vwclientlicensephases.actiondate, 'DD/Mon/YYYY'), 1) AS gazettedate,
    vwclientlicenses.clientlicenseid,
    vwclientlicensephases.phaseid,
	vwclientlicensephases.forwarded_date,
	vwclientlicensephases.remarks,
    vwclientlicenses.clientname,
    vwclientlicensephases.ClientPhaseLNA,
    vwclientlicenses.licensename,
    vwclientlicenses.licensetypename,
    vwclientlicenses.postalcode,
    vwclientlicenses.town,
	vwclientlicenses.email,
    vwclientlicenses.address,
    vwclientformtypes.formlink,
    vwclientformtypes.formviewlink,
    vwclientlicenses.applicationdate,
    vwclientlicenses.licenseid,
    vwclientlicensephases.actiondate,
    vwclientlicensephases.approved,
    vwclientlicensephases.rejected,
    vwclientlicensephases.deffered,
    users.usergroupid,
    vwclientlicenses.licensecount,
    vwclientlicenses.clientid,
    vwclientlicensephases.narrative,
    vwclientlicensephases.usergroupname,
    vwclientlicensephases.ChecklistNA,
    vwclientlicensephases.phaselevel,
    vwclientlicensephases.clientphasename,
    vwclientlicensephases.paid,
    vwclientlicenses.forlcs,
    vwclientlicenses.forfsm,
    vwclientlicenses.postaladdress,
    vwclientlicensephases.clientphaseid,
    vwclientlicenses.forta,
    vwclientlicenses.categoryappliedfor,
    vwclientlicenses.categoryapproved,
    vwclientlicenses.categoryrecomm,
    vwclientlicensephases.compliance,
    vwclientlicensephases.approval,
    vwclientlicenses.isactive,
    vwclientlicenses.clcid,
	  vwclientlicenses.tacid,
    vwclientlicenses.licensenumber,
    vwclientlicensephases.pending,
	  vwclientlicensephases.isdone,
    vwclientlicenses.phaseafterdg,
    countClientPhases(vwclientlicensephases.clientphaseid) AS countphases,
    vwclientlicenses.nlf,
    vwclientlicenses.currentphase,
    vwclientlicenses.typeapprovalfee,
    DECODE(vwclientlicenses.licensename,'Land Mobile Service','RF 1','Aircraft Radio','RF 14','Maritime(Ship) Radio','RF 14B','Port Operations(Coast) Radio','RF 14B','Amateur Band Radio','RF 2','Citizen Band Radio','RF 1B','Broadcasting (Radio)','RF 4','Broadcasting (TV)','RF 5','RF 1') AS applicationform,
    DECODE(vwclientlicenses.licensename,'Land Mobile Service','RF 3','Aeronautical Station License','RF 3','Port Operations(Coast) License','RF 3 B','RF 3')                                                                                                                                    AS frequencyform,
    vwclientlicenses.licenseabbrev,
    ('<a href="/reports/licenses/lcs'
    ||vwclientlicenses.licenseid
    || '.pdf" target="_blank">'
    ||vwclientlicenses.licensename
    || '</a>') AS licenselink,
    users.fullname,
    CLC.CLCDATE,

	vwclientlicenses.isdifferalemailsent, vwclientlicenses.isgazettementemailsent,	vwclientlicenses.islicenseapprovalemailsent,	vwclientlicenses.iscomplreturnsQemailsent,
	vwclientlicenses.iscomplreturnsAemailsent ,	vwclientlicenses.isAAAremindersent ,vwclientlicenses.isnummberallocationemailsent,vwclientlicenses.isTAcertificateemailsent ,	

	vwclientlicensephases.mgr_approved,
	vwclientlicensephases.ad_approved,
	vwclientlicensephases.dir_approved,
	vwclientlicensephases.dg_approved,

    CLC.clcnumber,
    vwclientlicenses.isserviceprovider,
    vwclientlicenses.isvsat,
    vwclientlicenses.isinfrastructure,
    vwclientlicenses.ispostal,
    vwclientlicenses.iscontractor
  FROM vwclientlicenses
  LEFT JOIN vwclientformtypes  ON vwclientlicenses.clientlicenseid = vwclientformtypes.clientlicenseid
  INNER JOIN vwclientlicensephases  ON vwclientlicensephases.clientlicenseid = vwclientlicenses.clientlicenseid  
  LEFT JOIN users  ON vwclientlicensephases.userid = users.userid
  LEFT OUTER JOIN clc  ON clc.CLCID = vwclientlicenses.clcid;


--alternative to vwallchecklists - used by FSM
--b4 training
CREATE OR REPLACE VIEW vwallphases as
SELECT vwclientlicenses.clientlicenseid, vwclientlicenses.effectiveclientlicenseid, vwclientlicensephases.phaseid, vwclientlicenses.clientname,vwclientlicensephases.ClientPhaseLNA, vwclientlicenses.offerapproved, vwclientlicenses.remarks,
	    vwclientlicensephases.assignedofficer, vwclientlicenses.email, vwclientlicensephases.assigningmanager, vwclientlicensephases.assignto, vwclientlicenses.conditionslink,
		vwclientlicenses.licensename,vwclientlicenses.postalcode,vwclientlicenses.town,vwclientlicenses.address, vwclientlicenses.technicaldetail,
		vwclientlicenses.applicationdate,vwclientlicenses.purposeoflicense,vwclientlicenses.licenseid,vwclientlicenses.secretariatremarks,vwclientlicenses.commiteeremarks,vwclientlicenses.suspended,
		vwclientlicensephases.approved, vwclientlicensephases.isdone,vwclientlicensephases.rejected, vwclientlicensephases.withdrawn, vwclientlicensephases.deffered, users.usergroupid, users.fullname, vwclientlicenses.licensecount,vwclientlicenses.clientid,
		vwclientlicensephases.narrative,vwclientlicensephases.usergroupname,vwclientlicensephases.ChecklistNA,vwclientlicensephases.phaselevel, vwclientlicenses.isterrestrial,
		vwclientlicensephases.clientphasename,vwclientlicensephases.paid,vwclientlicenses.forlcs,vwclientlicenses.forfsm,vwclientlicensephases.clientphaseid,

		vwclientlicenses.isclcemailsent, vwclientlicenses.ispostclcemailsent, vwclientlicenses.isofferemailsent,
		vwclientlicenses.isassignmentemailsent, vwclientlicenses.islicensereadyemailsent, vwclientlicenses.isinitialfeeemailsent,		
		vwclientlicenses.isdifferalemailsent, vwclientlicenses.isgazettementemailsent,	vwclientlicenses.islicenseapprovalemailsent,	vwclientlicenses.iscomplreturnsQemailsent,
		vwclientlicenses.iscomplreturnsAemailsent ,	vwclientlicenses.isAAAremindersent ,vwclientlicenses.isnummberallocationemailsent,vwclientlicenses.isTAcertificateemailsent ,	

		vwclientlicenses.licenseabbrev, vwclientlicenses.categoryapproved, vwclientlicenses.categoryrecomm, vwclientlicenses.categoryappliedfor,

		vwlicensephases.compliance,vwlicensephases.approval,vwclientlicenses.isactive, vwclientlicensephases.actiondate, vwclientlicenses.receivedby,
		vwclientlicenses.clcid, vwclientlicenses.clcnumber, vwclientlicenses.clcdate, vwclientlicensephases.pending,countClientPhases(vwclientlicensephases.clientphaseid) AS countphases,vwclientlicenses.nlf,
		vwclientlicenses.currentphase,decode(vwclientlicenses.licensename,'Land Mobile Service','RF 1','Aircraft Station','RF 14','Maritime Station','RF 14B','Port Operations(Coast) Radio','RF 14B','Amateur Band Radio','RF 2','Citizen Band Radio','RF 1B','Terrestrial Point to Multipoint Fixed Links','RF 3','Fixed Wireless Access Network','RF 3','Cellular Network','RF 3','Terrestrial Point to Point Fixed Links','RF 3','Broadcasting (Radio) - Commercial Free To Air','RF 4','Broadcasting (TV) - Commercial Free To Air','RF 5','RF 1') as applicationform, 
		decode(vwclientlicenses.licensename,'Land Mobile Service','RF 3','Aeronautical Station License','RF 3','Port Operations(Coast) License','RF 3 B','RF 3') as frequencyform
		from vwclientlicenses
		INNER JOIN vwclientlicensephases on vwclientlicensephases.clientlicenseid = vwclientlicenses.clientlicenseid
		INNER JOIN vwlicensephases ON vwclientlicensephases.phaseid = vwlicensephases.phaseid
		LEFT JOIN users ON vwclientlicensephases.userid = users.userid;





CREATE VIEW vwpaymentstatus as
 SELECT vwclientlicenses.clientlicenseid,vwclientlicensephases.phaseid, vwclientlicenses.clientname,vwclientlicensephases.ClientPhaseLNA,
		vwclientlicenses.licensename,vwclientlicenses.licensetypename,vwclientlicenses.postalcode,vwclientlicenses.town,vwclientlicenses.address,
		vwclientformtypes.formlink,vwclientformtypes.formviewlink, vwclientlicenses.applicationdate,vwclientlicenses.licenseid,
		vwclientlicensephases.approved, vwclientlicensephases.rejected,vwclientlicensephases.deffered, users.usergroupid,vwclientlicenses.licensecount,vwclientlicenses.clientid,
		vwclientlicensephases.narrative,vwclientlicensephases.usergroupname,vwclientlicensephases.ChecklistNA,vwclientlicensephases.phaselevel,
		vwclientlicensephases.clientphasename,vwclientlicenses.forlcs,vwclientlicenses.forfsm,vwclientlicenses.postaladdress,vwclientlicensephases.clientphaseid,
		vwclientlicenses.categoryappliedfor,vwclientlicenses.categoryapproved, vwclientlicenses.categoryrecomm,vwlicensephases.compliance,vwlicensephases.approval,vwclientlicenses.isactive,
		vwclientlicenses.clcid,	vwclientlicenses.licensenumber,vwclientlicensephases.pending,countClientPhases(vwclientlicensephases.clientphaseid) AS countphases,vwclientlicenses.nlf,vwclientlicenses.forta,
		vwclientlicenses.currentphase,decode(vwclientlicenses.licensename,'Land Mobile Service','RF 1','Aeronautical Station License','RF 14','N/A') as applicationform,decode(vwclientlicenses.licensename,'Land Mobile Service','RF 3','Aeronautical Station License','RF 3','N/A') as frequencyform,
		vwclientlicenses.licenseabbrev,
		('<a href="reports/licenses/lcs'||vwclientlicenses.licenseid || '.pdf" target="_blank">' ||vwclientlicenses.licensename|| '</a>') as licenselink,
		licensepayments.paid
		from vwclientlicenses
		left join vwclientformtypes on vwclientlicenses.clientlicenseid = vwclientformtypes.clientlicenseid 
		inner join vwclientlicensephases on vwclientlicensephases.clientlicenseid = vwclientlicenses.clientlicenseid
		INNER JOIN vwlicensephases ON vwclientlicensephases.phaseid = vwlicensephases.phaseid
		INNER JOIN users ON vwclientlicensephases.userid = users.userid
		left join licensepayments on licensepayments.clientphaseid = vwclientlicensephases.clientphaseid;


CREATE or replace VIEW vwallclccases as
SELECT clc.clcdate,clc.clcnumber,clc.details,licensename as clcdetails ,clc.clcid ,clientname ,formviewlink,
ClientPhaseLNA,approved,rejected,clientphasename,forlcs,forfsm, clientlicenseid, licensetypename, licensename, licensecount, clientphaseid,
categoryapproved, categoryrecomm, categoryappliedfor, narrative, pending,licenseabbrev,clc.active
from vwallchecklists , clc; 


--equivalent to vwallclccases but used in FSM system (and now in LCS also)
CREATE or replace VIEW vwclcclients as
	SELECT clientname, clc.clcdate, clc.clcnumber, clc.details, licensename as clcdetails, coalesce(clc.clcid,0) as clcid, vwallphases.secretariatremarks,vwallphases.commiteeremarks, licenseabbrev,
	ClientPhaseLNA, approved, rejected, withdrawn, deffered, clientphasename, forlcs, forfsm, clientlicenseid, licensename, licensecount, clientphaseid, narrative, pending, vwallphases.remarks as clientlicenseremarks,
	categoryapproved, categoryrecomm, categoryappliedfor, clc.active AS isactiveclc
	from vwallphases
	left join clc on vwallphases.clcid = clc.clcid;



CREATE VIEW vwallclcs AS
		SELECT CLC.CLCID, vwclientlicenses.clientlicenseid , clientphases.clientphasename,clientphases.approved,clientphases.rejected,
		forlcs, forfsm, clcdate, clcnumber
		FROM vwclientlicenses INNER JOIN clientphases ON clientphases.clientlicenseid = vwclientlicenses.clientlicenseid
		INNER JOIN CLC ON CLC.CLCID = vwclientlicenses.CLCID;


CREATE OR REPLACE FORCE VIEW VWALLTACCASES AS 
  SELECT vwallchecklists.clientlicenseid, tac.tacdate,tac.tacnumber,tac.details,licensename as tacdetails ,tac.tacid ,clientname ,formviewlink,
	vwallchecklists.ClientPhaseLNA, vwallchecklists.approved, vwallchecklists.rejected, vwallchecklists.clientphasename,vwallchecklists.forlcs, vwallchecklists.licensetypename, vwallchecklists.licensename, vwallchecklists.licensecount, vwallchecklists.clientphaseid,
	vwallchecklists.categoryapproved, vwallchecklists.categoryrecomm, vwallchecklists.categoryappliedfor, vwallchecklists.narrative, vwallchecklists.pending, vwallchecklists.clientid, tac.isactive, vwallchecklists.actiondate,
	add_months(TO_CHAR(vwallchecklists.actiondate, 'DD/Mon/YYYY'), 6) as certificationdate
	from vwallchecklists
	INNER JOIN clientlicenses ON vwallchecklists.clientlicenseid = clientlicenses.clientlicenseid
	INNER JOIN tac ON clientlicenses.tacid = tac.tacid;
 


-- work on this
-- SELECT *
-- from vwalltaccases  inner join equipmentapprovals on 
-- vwalltaccases.clientid = equipmentapprovals.clientid and equipmentapprovals.clientid = 201 and 
-- (clientphasename = 'tac') AND (tacid = '21') and vwalltaccases.approved = '0'

create  view vwpaymentphases as
SELECT vwclientlicenses.clientlicenseid,vwclientlicensephases.phaseid, vwclientlicenses.clientname,vwclientlicensephases.ClientPhaseLNA,
		 vwclientlicenses.applicationdate, vwclientlicenses.forta,vwclientlicenses.licensename,vwclientlicenses.licenseabbrev,
		vwclientlicensephases.approved, vwclientlicensephases.rejected,vwclientlicenses.licensecount,vwclientlicenses.clientid,
		vwclientlicensephases.narrative,vwclientlicensephases.usergroupname,vwclientlicensephases.ChecklistNA,vwclientlicensephases.phaselevel,
		vwclientlicensephases.clientphasename,vwclientlicenses.forlcs,vwclientlicenses.forfsm,vwclientlicenses.postaladdress,vwclientlicensephases.clientphaseid,
		vwclientlicenses.categoryappliedfor,vwclientlicenses.categoryapproved, vwclientlicenses.categoryrecomm,vwlicensephases.compliance,vwlicensephases.approval,
		vwclientlicensephases.pending,countClientPhases(vwclientlicensephases.clientphaseid) AS countphases, licensepayments.paid,licensepayments.salesorder,licensepayments.invoiced,
		phases.paymenttypeid,paymenttypes.paymenttypename,licensepayments.licensepaymentid,licensepayments.amount || ''|| vwclientlicenses.currencyabbrev as amount,
		proratedChargePeriod(licensepayments.invoicedate) as invmonths,vwclientlicenses.applicationfee,vwclientlicenses.initialfee,vwclientlicenses.annualfee as baseannualfee,
		licensepayments.invoicedate
		from vwclientlicenses inner join vwclientlicensephases on vwclientlicensephases.clientlicenseid = vwclientlicenses.clientlicenseid
		INNER JOIN vwlicensephases ON vwclientlicensephases.phaseid = vwlicensephases.phaseid
		inner join licensepayments on licensepayments.clientlicenseid = vwclientlicenses.clientlicenseid
    inner join phases on vwclientlicensephases.phaseid = phases.phaseid 
    inner join paymenttypes on paymenttypes.paymenttypeid = phases.paymenttypeid ;


CREATE VIEW vwapprovedlist AS
  SELECT DISTINCT clientname, licensename ,forlcs, forfsm, ClientPhaseLNA frOM vwallchecklists WHERE (countphases = '0') ;

CREATE VIEW vwclientdefination AS
  SELECT vwclientlicenses.clientid, vwclientlicenses.clientname, vwclientlicenses.licenseid, vwclientlicenses.licensename,vwclientlicenses.clientlicenseid,
	clientdefination.narrative,clientdefination.clientdefinationid,
	clientdefination.approved,clientdefination.appliedfor,clientdefination.recommended	from clientdefination inner join vwclientlicenses on vwclientlicenses.clientlicenseid = clientdefination.clientlicenseid;

CREATE or replace  VIEW vwschedules AS 
	SELECT schedules.scheduleID,schedules.UserID,schedules.schedulename,schedules.complete,schedules.details AS scheduledetails,
	scheduletypes.scheduletypename,scheduletypes.details,scheduletypes.scheduletypeid,
	schedules.quarter1,schedules.quarter2,schedules.quarter3,schedules.quarter4,schedules.startdate,schedules.enddate,
	schedules.isapprovedbymanager, schedules.isapprovedbyad, schedules.isapprovedbydirector, schedules.isapprovedbydg,
	periods.periodid, periods.periodname
	FROM schedules 
	INNER JOIN scheduletypes ON scheduletypes.scheduletypeid = schedules.scheduletypeid
	INNER JOIN periods ON scheduletypes.periodid = periods.periodid;


CREATE OR REPLACE VIEW vwcontacts AS
	SELECT vwmergedclients.clientid,vwmergedclients.clientname, clientcontact.contactname, clientcontact.designation, clientcontact.idnumber, countrys.citizenname, idtypes.idtypeid, idtypes.typename
		FROM vwmergedclients 
		INNER JOIN clientcontact ON clientcontact.clientid = vwmergedclients.clientid
		INNER JOIN countrys ON clientcontact.countryid = countrys.countryid
		INNER JOIN idtypes ON clientcontact.idtypeid = idtypes.idtypeid;
 



CREATE or replace  VIEW vwcomplianceschedule AS
	SELECT complianceschedule.regions,complianceschedule.inspections,complianceschedule.generalreq,complianceschedule.details,
		complianceschedule.compliancescheduleid,complianceschedule.approved,complianceschedule.userid,complianceschedule.startdate,complianceschedule.enddate,
		vwschedules.scheduleID,vwschedules.schedulename,vwschedules.active,complianceschedule.schedulename as scheduleheading,
		vwschedules.scheduledetails ,vwschedules.scheduletypename,
		users.fullname,regions.regioname
	FROM complianceschedule  INNER JOIN vwschedules ON vwschedules.scheduleID = complianceschedule.scheduleID
	INNER JOIN users ON users.userid = complianceschedule.userid
	INNER JOIN regions ON regions.regionid = complianceschedule.regionid;


CREATE OR REPLACE FUNCTION sumperdiem(myval1 IN integer) RETURN integer IS
myret int;
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	SELECT sum(costperdiem) INTO myret
	FROM compliance WHERE  (compliance.compliancescheduleid = myval1) ;
	COMMIT;
	RETURN myret;
END;
/

create or replace FUNCTION participantcount(myval1 IN integer) RETURN integer IS
myret int;
BEGIN
	SELECT count(compliance.complianceid) INTO myret
	FROM compliance WHERE compliance.compliancescheduleid = cast(myval1 as int);
RETURN myret;
END;
/


--
CREATE OR REPLACE FUNCTION licenseecomplaint(cli_id IN varchar2, use_id IN varchar2, approval IN varchar2, myval4 IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	BEGIN

		IF(approval = 'Inspection') THEN

			INSERT INTO fmitasks  (complainantname,clientid,complainantfax,complainanttelephone,complainantaddress,dateofentry,userid,ForInspection,FMICOMPLIANCETYPEID)
				SELECT clientname, clientid, fax, telno, address, SYSDATE, CAST(use_id AS int), '1', 3
					FROM vwmergedclients where clientid = CAST(cli_id AS int);			
			COMMIT;
		    RETURN 'Inspection Task Inserted';
		END IF;

		IF(approval = 'Inteference') THEN
			INSERT INTO fmitasks  (complainantname,clientid,complainantfax,complainanttelephone,complainantaddress,dateofentry,userid,ForInteference,FMICOMPLIANCETYPEID)
				SELECT clientname, clientid, fax, telno, address, SYSDATE, CAST(use_id AS int), '1', 1
					FROM vwmergedclients where clientid = CAST(cli_id AS int);
			COMMIT;
		    RETURN 'Interference Task Inserted';
		END IF;

		IF(approval = 'Monitoring') THEN

			INSERT INTO fmitasks  (complainantname, clientid, complainantfax,complainanttelephone,complainantaddress,dateofentry,userid,ForMonitoring,FMICOMPLIANCETYPEID)
				SELECT clientname, clientid, fax, telno, address, SYSDATE, CAST(use_id AS int), '1', 2
					FROM vwmergedclients where clientid = CAST(cli_id AS int);			
			COMMIT;
		    RETURN 'Monitoring Task Inserted';
		END IF;

	  COMMIT;

	RETURN 'Unreachable Code';
END;
/


--to process miscallenieous violations/contraventions like inspection of unauthorized stations
CREATE OR REPLACE FUNCTION violationprocessing(cli_lic_id IN varchar2, use_id IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	BEGIN
			
		IF(approval = 'Inspection') THEN
				
			INSERT INTO fmitasks  (complainantname,clientid,complainantfax,complainanttelephone,complainantaddress,dateofentry,userid,ForInspection,FMICOMPLIANCETYPEID,details)
				select clients.clientname, clients.clientid, clients.fax, clients.telno, clients.address, SYSDATE, CAST(use_id AS int), '1', 3, 'Regarding unauthorized expansion of network.'
					from clientlicenses 
					inner join clients on clientlicenses.clientid = clients.clientid
					where clientlicenseid = CAST(cli_lic_id AS int);
					--and clientid not in (select coalesce(clientid,0) from fmitasks where dateofentry = sysdate);			--make sure this is the only entry of today
			COMMIT;
			
			UPDATE declarationimport set isscheduled = '1' where servicecode = cli_lic_id;
			COMMIT;
					
		    RETURN 'Inspection Task Inserted';
		END IF;
			
	RETURN 'Unreachable Code Segment';
			
	END;
/








CREATE or replace VIEW vwcompliance AS
	SELECT compliance.forfsm, compliance.forlcs, compliance.frequencyfrom,compliance.frequencyto, compliance.dateofviolation, 
		compliance.violation,compliance.compliant,compliance.visitdate,compliance.hoursspent, compliance.conclusions,
		compliance.isdone, compliance.isdrop,compliance.isforaction, compliance.actiondone, compliance.details as compliancedetails, 
		compliance.findings,compliance.purpose,compliance.remarks, compliance.recommendation,compliance.complianceid,compliance.clientid,
		compliance.participants,compliance.costperdiem,compliance.adhoc,vwcomplianceschedule.compliancescheduleid,vwcomplianceschedule.startdate,vwcomplianceschedule.enddate,
		vwcomplianceschedule.scheduleID,vwcomplianceschedule.UserID,vwcomplianceschedule.schedulename,vwcomplianceschedule.active,vwcomplianceschedule.scheduleheading,
		vwcomplianceschedule.scheduledetails ,vwcomplianceschedule.scheduletypename,vwcomplianceschedule.details,vwcomplianceschedule.fullname,
		vwcomplianceschedule.generalreq,vwcomplianceschedule.inspections,vwcomplianceschedule.regions,compliance.noncompliant,
		vwclients.clientname,vwclients.address, vwclients.street ,vwclients.town,vwclients.email,vwclients.division, 
		vwclients.mobilenum,vwclients.premises,vwclients.buildingfloor,vwclients.telno,vwclientlicenses.licensename,
		sumperdiem(vwcomplianceschedule.compliancescheduleid) as sumperdiem
		FROM compliance INNER JOIN vwcomplianceschedule ON vwcomplianceschedule.compliancescheduleid = compliance.compliancescheduleid
		INNER JOIN vwclients ON vwclients.clientid = compliance.clientid 
		INNER JOIN vwclientlicenses ON vwclientlicenses.clientid = compliance.clientid ;

CREATE VIEW vwcompliancesch AS
SELECT compliance.forfsm, compliance.forlcs, compliance.frequencyfrom,compliance.frequencyto, compliance.dateofviolation, 
		compliance.violation,compliance.compliant,compliance.visitdate,compliance.hoursspent, compliance.conclusions,
		compliance.isdone, compliance.isdrop,compliance.isforaction, compliance.actiondone, compliance.details as compliancedetails, 
		compliance.findings,compliance.purpose,compliance.remarks, compliance.recommendation,compliance.complianceid,compliance.clientid,
		compliance.participants,compliance.costperdiem,compliance.adhoc,vwcomplianceschedule.compliancescheduleid,vwcomplianceschedule.startdate,vwcomplianceschedule.enddate,
		vwcomplianceschedule.scheduleID,vwcomplianceschedule.UserID,vwcomplianceschedule.schedulename,vwcomplianceschedule.active,vwcomplianceschedule.scheduleheading,
		vwcomplianceschedule.scheduledetails ,vwcomplianceschedule.scheduletypename,vwcomplianceschedule.details,vwcomplianceschedule.fullname,
		vwcomplianceschedule.generalreq,vwcomplianceschedule.inspections,vwcomplianceschedule.regions,compliance.noncompliant,
		sumperdiem(vwcomplianceschedule.compliancescheduleid) as sumperdiem,participantcount(vwcomplianceschedule.compliancescheduleid) as participantcount
		FROM compliance INNER JOIN vwcomplianceschedule ON vwcomplianceschedule.compliancescheduleid = compliance.compliancescheduleid;
		

CREATE or replace VIEW vwlicensecompliance AS
	SELECT licensecompliance.compliant AS licensecompliance,licensecompliance.dateofviolation AS violationdate,
		licensecompliance.violation AS licenseviolation,licensecompliance.Details AS violationdetails,vwclientlicenses.address,
	licensecompliance.Recommendation AS licenserecomendation,vwclientlicenses.clientid,
		vwclientlicenses.clientlicenseid, vwclientlicenses.licenseid, vwclientlicenses.licensename,
		initcap(vwclientlicenses.town) as town,vwclientlicenses.telno,vwclientlicenses.email,vwclientlicenses.mobilenum,
		licensecompliance.periodlicenseid
		FROM licensecompliance INNER JOIN periodlicenses ON periodlicenses.periodlicenseid = licensecompliance.periodlicenseid
		INNER JOIN vwclientlicenses ON periodlicenses.clientlicenseid  = vwclientlicenses.clientlicenseid ;
	
CREATE OR REPLACE VIEW vwperiodlicenses AS
  SELECT 

	periodlicenses.AAACOMPLIANT, 
	periodlicenses.retcompliant,
	periodlicenses.conditionscompliant,
	getOveralQoSCompliance(periodlicenses.periodlicenseid) as overallqos,

	(periodlicenses.AAACOMPLIANT +	periodlicenses.retcompliant +	periodlicenses.conditionscompliant +	getOveralQoSCompliance(periodlicenses.periodlicenseid) ) as countcomplied,    
	DECODE((periodlicenses.AAACOMPLIANT +	periodlicenses.retcompliant +	periodlicenses.conditionscompliant + getOveralQoSCompliance(periodlicenses.periodlicenseid)),4,'1','0') as overallcompliance,
  
  (DECODE(periodlicenses.AAACOMPLIANT,'0','AAA Uncomplied, ','') ||
  DECODE(periodlicenses.retcompliant,'0','Returns Uncomplied, ','') ||
  DECODE(periodlicenses.conditionscompliant,'0','Conditions Uncomplied, ','') ||
  DECODE(getOveralQoSCompliance(periodlicenses.periodlicenseid),'0','QoS Uncomplied, ',''))  as uncomplieditems,

	PERIODLICENSES.QOSCOMPLIANT, isinvoiced, compliancereason,  CAST(COALESCE(annualfeedue(MINANNUALFEE,ANNUALFEEDUE),'0')AS REAL) AS feedue,
    periodlicenses.mailed,    periodlicenses.clientcompliance,    vwclientlicenses.MINANNUALFEE,    vwclientlicenses.email,
    add_months(TO_CHAR(periodlicenses.SHAREHOLDINGNOTIFICATIONDATE, 'DD/Mon/YYYY'), 3) AS SHAREHOLDINGDEADLINE,
    add_months(TO_CHAR(periodlicenses.LICENSEEREQUESTNOTIFICDATE, 'DD/Mon/YYYY'), 3)   AS LICENSEEREQUESTDEADLINE,
    SHAREHOLDINGNOTIFICATIONDATE,    LICENSEEREQUESTNOTIFICDATE,    SHAREHOLDINGNOTIFICATION,    LICENSEEREQUESTNOTIFICATION,
    SHAREHOLDING,    LICENSEEREQUEST,    periodlicenses.ANNUALFEESENT,    periodlicenses.CONDITIONSNOTIFICATION,    periodlicenses.AAANOTIFICATION,
    periodlicenses.CONDITIONSdate,    periodlicenses.AAANOTIFICATIONdate,    AAANOTIFICATIONLETTER,    periodlicenses.penaltyamount,
    periodlicenses.CONDITIONSNOTIFICATIONLETTER,    periodlicenses.penaltypaid,        AAADUEDATE,
    RESPONSEDATE,    NOTIFICATIONRESPONSE,    INITIALRETNOTIFICATIONLETTER,    INITIALRETURNNOTIFICATION,    INITIALNOTIFICATIONDATE,
    add_months(TO_CHAR(vwclientlicenses.LICENSEDATE, 'DD/Mon/YYYY'), 9)           AS submissiondeadline,
    add_months(TO_CHAR(periodlicenses.INITIALNOTIFICATIONdate, 'DD/Mon/YYYY'), 3) AS RESPONSEDEADLINE,
    add_months(TO_CHAR(periodlicenses.AAANOTIFICATIONdate, 'DD/Mon/YYYY'), 3)     AS AAANOTIFICATIONDEADLINE,
    add_months(TO_CHAR(periodlicenses.CONDITIONSdate, 'DD/Mon/YYYY'), 3)          AS CONDITIONSEDEADLINE,
    COALESCE(to_date(AAADUEDATE,'dd-mm-yyyy'),add_months(enddate, 3)) AS CURRENTDUEDATE,
    vwclientlicenses.LICENSESTARTDATE,    vwclientlicenses.LICENSEDATE,    vwclientlicenses.ROLLEDOUT,    vwclientlicenses.ROLLOUTDATE,
       periodlicenses.COMPLIED,    periodlicenses.NOTCOMPLIED,    periodlicenses.nonlicenserevenue,    periodlicenses.licenserevenue,
    periodlicenses.annualgross,    periodlicenses.annualfeedue,
    
    GREATEST(vwclientlicenses.annualfee, (0.05 * coalesce(periodlicenses.annualgross-periodlicenses.nonlicenserevenue,0))) AS calculatedfeedue,
		    
    periodlicenses.actiondate,    periodlicenses.periodcompliant,    periodlicenses.annualreturns,
    periodlicenses.quarterreturns,    periodlicenses.voided,    periodlicenses.qr1,    periodlicenses.qr2,    periodlicenses.qr3,    periodlicenses.qr4,
    periodlicenses.ar,    periodlicenses.periodlicenseid,    periodlicenses.clientlicenseid,    vwclientlicenses.fax,    vwclientlicenses.telno,    vwclientlicenses.town,
    vwclientlicenses.address,        periodlicenses.voiddate,    periodlicenses.details,    periodlicenses.periodid,    periods.periodname,
    vwclientlicenses.licenseid,    vwclientlicenses.clientname,    vwclientlicenses.licensename,    vwclientlicenses.IsActive,    vwclientlicenses.forlcs,    vwclientlicenses.forfsm,
    vwclientlicenses.licenseabbrev,   vwclientlicenses.clientid,    vwclientlicenses.contact,    vwclientlicenses.postaladdress,    periods.isactive AS activeperiod
  FROM periodlicenses
  INNER JOIN periods  ON periods.periodid = periodlicenses.periodid
  INNER JOIN vwclientlicenses  ON vwclientlicenses.clientlicenseid = periodlicenses.clientlicenseid;




--DISTINCT clients in each period
CREATE OR REPLACE VIEW vwperiodclients AS
SELECT DISTINCT clients.clientid, upper(clients.clientname) as clientname, periods.periodid, periods.periodname, periods.isactive as isactiveperiod,
('P.O.Box ' || clients.address ||' - ' || coalesce(clients.postalcode,postoffice.postalcode) || '<br>' || initcap(clients.town) ||  ' ' || initcap(countrys.countryname)) as postaladdress,	
('Tel:' ||' '||clients.telno || ' ' || 'Fax:'|| clients.fax || '<br>Email: ' || '<a href="mailto:'|| clients.email ||'">'||clients.email||'</a>' ) AS contact
FROM periodlicenses
  INNER JOIN periods  ON periods.periodid = periodlicenses.periodid
  INNER JOIN clientlicenses  ON clientlicenses.clientlicenseid = periodlicenses.clientlicenseid
  INNER JOIN clients ON clientlicenses.clientid = clients.clientid
  LEFT JOIN postoffice ON clients.postofficeid = postoffice.postofficeid
  INNER JOIN countrys ON clients.countryid = countrys.countryid;



CREATE OR REPLACE FUNCTION getOveralQoSCompliance(period_lic_id IN varchar2) RETURN VARCHAR IS
	PRAGMA AUTONOMOUS_TRANSACTION;
		
		count_non_complied		real;		

	BEGIN
		
		SELECT COUNT(licensesqosid) INTO count_non_complied FROM VWCOMPLIANCEQOS 
		WHERE periodlicenseid = CAST(period_lic_id AS INT) AND (calculatedcompliance = '0');

		IF(count_non_complied = 0)THEN
			RETURN '1';
		ELSE
			RETURN '0';
		END IF;
			
	RETURN 'Unreachable Code';
END;
/



CREATE OR REPLACE FORCE VIEW VWCOMPLIANCEQOS AS 
  SELECT vwclientlicenses.clientlicenseid, vwclientlicenses.licenseid, vwclientlicenses.clientid,vwclientlicenses.clientname, vwclientlicenses.licensename, periodlicenses.periodid,periodlicenses.periodlicenseid,
    licensesqos.target, licensesqos.actualcck, licensesqos.complied AS qoscomplied, licensesqos.actualclient, licensesqos.qosname,
	calculateCompliance(licensesqos.targetexpression,licensesqos.actualcck) as calculatedcompliance,licensesqos.targetexpression,
    licensesqos.recommendation AS qosrecommendation, licensesqos.action AS qosaction, licensesqos.licensesqosid, licensesqos.notcomplied,
    licensesqos.complied, licensesqos.regions, licensesqos.details AS qosdetails, PERIODS.PERIODNAME
  FROM licensesqos  
  INNER JOIN periodlicenses ON licensesqos.periodlicenseid  = periodlicenses.periodlicenseid
  LEFT JOIN periods ON periodlicenses.periodid = periods.periodid
  LEFT JOIN vwclientlicenses ON vwclientlicenses.clientlicenseid = periodlicenses.clientlicenseid;






CREATE OR REPLACE FUNCTION getcomplianceLNA(myval1 IN integer, myval2 IN integer) RETURN integer IS
myret int;

CURSOR c1 IS
  SELECT  penalties.clientcomplianceid
	FROM penalties WHERE (penalties.penaltyid = cast (myval1 as int));
		rc c1%ROWTYPE;
	
BEGIN

	OPEN c1;
	FETCH c1 INTO rc;
	SELECT count(penalties.penaltyid) INTO myret
	FROM penalties inner join clientcompliance on clientcompliance.clientcomplianceid = penalties.clientcomplianceid
	inner join vwclientlicenses on vwclientlicenses.clientlicenseid = clientcompliance.clientlicenseid
	WHERE (penalties.approved = '0') AND (penalties.clientapplevel < cast(myval2 as int)) 
	AND (clientcompliance.clientcomplianceid = rc.clientcomplianceid);
RETURN myret;
END;
/

create  view vwclientcompliance as 
select penalties.clientphasename ,clientcompliance.narrative,penalties.clientcomplianceid,penalties.userid,
vwclientlicenses.clientname,penalties.penaltyid,penalties.emailed,
getcomplianceLNA(penalties.penaltyid, penalties.clientapplevel) as complianceLNA,penalties.numofcontraventions,
penalties.approved,penalties.rejected, penalties.penaltyamount,penalties.clientapplevel,vwclientlicenses.licenseabbrev,
vwclientlicenses.licensename,vwclientlicenses.clientlicenseid  from clientcompliance
inner join vwclientlicenses on clientcompliance.clientlicenseid = vwclientlicenses.clientlicenseid
inner join penalties on penalties.clientcomplianceid = clientcompliance.clientcomplianceid;

CREATE OR REPLACE FUNCTION getAnnualPhaseLNA(myval1 IN integer, myval2 IN integer) RETURN integer IS
myret int;
BEGIN
	SELECT count(clientphases.clientphaseid) INTO myret
	FROM clientphases INNER JOIN phases ON clientphases.phaseid = phases.phaseid
	WHERE (clientphases.approved = '0') AND (clientphases.scheduleid = myval1) AND (clientphases.clientapplevel < myval2);
RETURN myret;
END;
/
CREATE OR REPLACE VIEW vwannualscheduleapproval AS
	  SELECT clientphases.clientphaseid,
    phases.phaseid,  phases.phaselevel,    phases.returnlevel,    phases.compliance,    phases.approval,    phases.EscalationTime,    phases.details,
    phases.paymenttypeid,    phases.annualschedule,    clientphases.clientapplevel,    clientphases.clientphasename,    clientphases.userid,
    clientphases.approved,    clientphases.rejected ,    clientphases. pending ,    clientphases.scheduleid,
    getAnnualPhaseLNA(clientphases.scheduleid,clientphases.clientapplevel) AS annualphaselna,    scheduletypes.scheduletypeid, scheduletypes.complete,
    schedules.schedulename,    scheduletypes.scheduletypename
  FROM phases
  INNER JOIN clientphases
  ON clientphases.phaseid = phases.phaseid
  INNER JOIN schedules
  ON schedules.scheduleid = clientphases.scheduleid
  INNER JOIN scheduletypes
  ON scheduletypes.scheduletypeid = schedules.scheduletypeid
  WHERE phases.compliance = '1';



CREATE OR REPLACE  VIEW vwannualschedule AS 
  SELECT vwannualscheduleapproval.schedulename, vwannualscheduleapproval.scheduletypename, vwannualscheduleapproval.scheduleID, 
	vwannualscheduleapproval.clientphaseid, vwannualscheduleapproval.annualphaselna, compliance.costperdiem, compliance.participants, 
	inspections, (startdate || '<BR>' || 'TO' || '<BR>'|| enddate) as workingdate, generalreq, regions
	FROM vwannualscheduleapproval INNER JOIN vwcomplianceschedule ON vwcomplianceschedule.scheduleID = vwannualscheduleapproval.scheduleID
	INNER JOIN compliance on compliance.compliancescheduleid = vwcomplianceschedule.compliancescheduleid
	WHERE (vwannualscheduleapproval.approved = '1') AND (vwannualscheduleapproval.annualphaselna = 0) AND (vwannualscheduleapproval.complete = '1') AND (vwannualscheduleapproval.clientphasename = 'dg');
	
create or replace view vwcompliancecases as
	select clientname, licensename, licensesummary, compliancescheduleid, isactive, forlcs, forfsm, clientid
	from vwclientlicenses, complianceschedule;

CREATE VIEW vwnumbers AS
	SELECT numbertypes.numbertypeid, numbertypes.numbertypename, 
		numbers.numberid, numbers.startrange, numbers.endrange, numbers.assignment,
		numbers.assigndate, numbers.activedate, numbers.details
	FROM numbertypes INNER JOIN numbers ON numbertypes.numbertypeid = numbers.numbertypeid;
 





CREATE OR REPLACE FUNCTION getnumberassigned (myval1 IN integer) RETURN integer IS
	myret int;
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	SELECT count(currentnumberseries) into myret
	FROM destinationcodes inner join numberseries on numberseries.destinationcodeid = destinationcodes.destinationcodeid
	WHERE  areaid = cast(myval1 as int);
  COMMIT;
RETURN myret;
END;
/

CREATE OR REPLACE VIEW vwequipments AS
	SELECT decode(equipmenttypes.equipmenttypename,'C', 'AIRCRAFT EQUIPMENT', 'T', 'BROADCASTING EQUIPMENT','M','MARITIME EQUIPMENT',substr(equipmenttypes.equipmenttypename,15,30)) as equipmenttypename, equipments.equipmentid, equipments.equipmenttypeid,
	substr(equipments.model,0,instr(equipments.model,' ')) as make,substr(equipments.model,instr(equipments.model,' ')+1,100) as model,
	substr(equipments.model,0,instr(equipments.model,' ')) || ': ' || substr(equipments.model,instr(equipments.model,' ')+1,100) as equipmentname,
  equipments.suppliername, equipments.outputpower, equipments.equ_manufacturer, equipments.threshold,
	equipments.equ_if_bandwidth,equipments.equ_tx_high_freq,equipments.equ_tx_low_freq,
	equipments.desensitisation, equipments.audioharmonicdistortion, 
	equipments.receiversensitivity,equipments.receiveradjacenstselectivity
  
	FROM equipments 
	LEFT JOIN equipmenttypes ON equipments.equipmenttypeid = equipmenttypes.equipmenttypeid	
UNION
	SELECT decode(equ_station_service,'MA','Aircraft','MM','Ship','Unknown') as equipmenttypename, equ_id as equipmentid, 1 as equipmenttypeid,
  substr(sms_equip.equ_name,0,instr(sms_equip.equ_name,' ')) as make,  equ_model as model,
	substr(sms_equip.equ_name,0,instr(sms_equip.equ_name,' ')) || ': ' || equ_model as equipmentname,
	'Undefined' as suppliername, to_char(equ_power_to_ant) as outputpower, equ_manufacturer, 'val' as threshold,
  equ_if_bandwidth, equ_tx_high_freq, equ_tx_low_freq,
	'' as desensitisation, '' as audioharmonicdistortion,
	'' as receiversensitivity, '' as receiveradjacenstselectivity
	
  from sms_equip;



CREATE OR REPLACE VIEW vwmergedequipments AS
	SELECT substr(equipmenttypes.equipmenttypename,15,30) as equipmenttypename, equipments.equipmentid, equipments.equipmenttypeid,
	substr(equipments.model,0,instr(equipments.model,' ')) as make,substr(equipments.model,instr(equipments.model,' ')+1,100) as model,equipments.model as fullname ,
  equipments.suppliername, equipments.outputpower, equipments.equ_manufacturer,
	equipments.equ_if_bandwidth,equipments.equ_tx_high_freq,equipments.equ_tx_low_freq 
  FROM (equipments LEFT JOIN equipmenttypes ON equipments.equipmenttypeid = equipmenttypes.equipmenttypeid)
UNION
	SELECT decode(equ_station_service,'MA','Aircraft','MM','Ship',equ_station_service) as equipmenttypename, equ_id as equipmentid, 42 as equipmenttypeid,
  substr(sms_equip.equ_name,0,instr(sms_equip.equ_name,' ')) as make,  equ_model as model, equ_name as fullname,
	'Undefined' as suppliername, to_char(equ_power_to_ant) as outputpower, equ_manufacturer,
  equ_if_bandwidth, equ_tx_high_freq, equ_tx_low_freq 
  from sms_equip
	






CREATE OR REPLACE VIEW vwnumbersassigned AS
SELECT operators.operatorsname,areas.areaname,destinationcodes.details,destinationcodes.destinationcode,
	numberseries.currentnumberseries, numberseries.significantnumber, getnumberassigned(cast (areaid as integer)) as assignedcount,
	areas.areaid,destinationcodes.destinationcodeid
	FROM numberseries 
	INNER JOIN  destinationcodes on numberseries.destinationcodeid = destinationcodes.destinationcodeid
	INNER JOIN areas on areas.areaid = destinationcodes.areaid
	INNER JOIN operators on operators.operatorsid = numberseries.operatorsid;




CREATE VIEW vwtachecklists AS
SELECT clientphaseid, clientphaselna, clientlicenseid, clientname, formlink, formviewlink, licensename, equipmentname, equipmenttypeid, equipmentapprovalid
	FROM equipmentapprovals
	INNER JOIN vwallchecklists on equipmentapprovals.clientid = vwallchecklists.clientid;






create OR REPLACE view vwequipmentapprovals as
  SELECT vwalltaccases.tacid,vwalltaccases.tacnumber,vwalltaccases.clientid, vwalltaccases.clientname, vwalltaccases.licensename, vwalltaccases.clientlicenseid,vwalltaccases.clientphaseid,
	equipmentapprovals.equipmenttypeid,equipmentapprovals.equipmentname,equipmentapprovals.serialnumber,equipmentapprovals.manufacturer,
	equipmentapprovals.make,equipmentapprovals.model,equipmentapprovals.suppliername,equipmentapprovals.equipmentapprovalid,
	vwalltaccases.approved,clientphasename
	from vwalltaccases  
	inner join equipmentapprovals on vwalltaccases.clientlicenseid = equipmentapprovals.clientlicenseid;
-- fsm views and functions






CREATE OR REPLACE VIEW vwTAequipment AS
	SELECT clientlicenses.clientlicenseid, clients.clientname, equipmentapprovals.equipmenttypeid,equipmentapprovals.equipmentname,equipmentapprovals.serialnumber,
  equipmentapprovals.manufacturer,equipmentapprovals.make,equipmentapprovals.model,equipmentapprovals.suppliername,equipmentapprovals.equipmentapprovalid,
  equipmentapprovals.actiondate, equipmentapprovals.approved, equipmentapprovals.pending, equipmentapprovals.rejected
	FROM equipmentapprovals
	INNER JOIN clientlicenses ON equipmentapprovals.clientlicenseid = clientlicenses.clientlicenseid
	INNER JOIN clients ON clientlicenses.clientid = clients.clientid;






CREATE OR REPLACE  FUNCTION fses(p1 in real, p2 in real, bw in real, cl in real)  RETURN integer IS
	ans int;
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	ans := log((p1 / 25),10);
	IF (p1 > 1000) THEN
		ans := ans + (0.2 * log(((p2 - 1000) / 25),10));
	END IF;
    ans := ans * (bw * 574.1 / 8.5);
	
RETURN ans;

END;
/

CREATE OR REPLACE FUNCTION countallfsmlicenses  RETURN integer IS
	myret int;
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	SELECT count(vwlicenses.licenseid) into myret
	FROM vwlicenses
	WHERE  nlf = '1' AND  forfsm = '1' 
	AND licenseid >= 500 AND licensetypeid=16;
  COMMIT;
RETURN myret;
END;
/

CREATE  VIEW  vwallfsmlicenses	as
	SELECT vwlicenses.licensename,vwclients.clientid, vwclients.clientname,vwclients.clientdetail,
  countallfsmlicenses() as licensecount,vwclients.details,vwlicenses.licenseid
	FROM  vwlicenses, vwmergedclients
	WHERE  nlf = '1' AND  forfsm = '1' AND vwlicenses.licenseid > 500;

--test as replacement for vwallfsmlicenses
CREATE OR REPLACE VIEW  vwmergedfsmlicenses	as
	SELECT licenses.licensename, vwdistinctclients.clientid, vwdistinctclients.clientname,vwdistinctclients.clientdetail,
  countallfsmlicenses () as licensecount,licenses.licenseid
	FROM  licenses, vwdistinctclients
	WHERE  vwdistinctclients.forfsm = '1'	AND licenses.licenseid >= 500 AND licenses.licensetypeid=16;


CREATE OR REPLACE FUNCTION countfixed(cli_lic_id IN varchar2) RETURN integer IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	myret int;
BEGIN
	select count(stationid) into myret
	from stations where (clientlicenseid = cli_lic_id) and (transmitstationid is null);	
	COMMIT;

	RETURN myret;
END;
/




CREATE OR REPLACE FUNCTION countbase(cli_lic_id IN integer) RETURN integer IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	myret int;
BEGIN
	select count(stationid) into myret
	from stations where (clientlicenseid = cli_lic_id) and ((licensepriceid = 4) or (licensepriceid = 5));	
	COMMIT;

	RETURN myret;
END;
/


CREATE OR REPLACE FUNCTION countportable(cli_lic_id IN integer) RETURN integer IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	myret int;
BEGIN
	select count(stationid) into myret
	from stations where (clientlicenseid = cli_lic_id) and ((licensepriceid = 1) or (licensepriceid = 3));	
	COMMIT;

	RETURN myret;
END;
/


CREATE OR REPLACE FUNCTION countmobile(cli_lic_id IN integer) RETURN integer IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	myret int;
BEGIN
	select count(stationid) into myret
	from stations where (clientlicenseid = cli_lic_id) and ((licensepriceid = 2) or (licensepriceid = 6));	
	COMMIT;

	RETURN myret;
END;
/




--how to eliminate duplicates (repetitions) ?????????







--stations with frequencies not reserved
CREATE OR REPLACE FUNCTION countStationsNR(cli_lic_id in integer) RETURN integer IS
PRAGMA AUTONOMOUS_TRANSACTION;
	allstations int;
	allreserved int;
BEGIN
	
	select count(frequencys.stationid) into allstations from frequencys inner join stations on frequencys.stationid = stations.stationid where clientlicenseid = cli_lic_id;
	select count(frequencys.stationid) into allreserved from frequencys inner join stations on frequencys.stationid = stations.stationid where clientlicenseid = cli_lic_id and frequencys.isreserved='1';
		
	RETURN allstations - allreserved;

EXCEPTION
	WHEN OTHERS THEN
		RETURN -1;

END;
/


--modified to accomodate whole band assignment (where there is no specific tx and rx frequency)
create or replace view vwfrequencyreservation as
  select vwallphases.clientlicenseid, vwallphases.effectiveclientlicenseid, vwallphases.clientid, vwallphases.clientname, vwallphases.clientphasename, vwallphases.licenseid, vwallphases.licensename, 
	 vwallphases.clientphaseid, vwallphases.forfsm, stations.stationname, stations.stationcallsign, vwallphases.isterrestrial,
	coalesce(vwallphases.isactive,'0') as islicenseactive, vwallphases.clientphaselna, vwallphases.offerapproved, decode(vwallphases.offerapproved,'1','<font color="green"><b>Yes</b></font>','0','<font color="red"><b>No</b></font>','Undefined') as offerstatus,
	frequencys.stationid, coalesce(frequencys.isreserved,'0') as isfrequencyreserved, coalesce(frequencys.isactive,'0') as isfrequencyactive, 
	channelplan.channelplanname, channel.channelid, channel.channelnumber, channel.subbandname, channel.itu_reference, channel.channelspacing, 
	decode(channel.channelplanid,27,channel.subbandname,28,channel.subbandname,87,'Amateur Band',101,'Aeronautical Band',channel.transmit) as transmit, decode(channel.channelplanid,27,channel.subbandname,28,channel.subbandname,87,'Amateur Band',101,'Aeronautical Band',channel.receive) as receive, countStationsNR(vwallphases.clientlicenseid)	as stationsNR
	from vwallphases	
	inner join stations on vwallphases.clientlicenseid = stations.clientlicenseid	
	inner join frequencys on stations.stationid = frequencys.stationid
	inner join channel on frequencys.channelid = channel.channelid
	inner join channelplan on channel.channelplanid = channelplan.channelplanid;





--VERY SPECIFIC CLIENTS WITH RESERVED FREQUENCIES
create or replace view vwfreqreservedclients as
  select distinct vwallphases.clientlicenseid,  vwallphases.effectiveclientlicenseid, 
  vwallphases.clientname, vwallphases.clientphasename, vwallphases.licenseid, 
  vwallphases.licensename, vwallphases.clientphaselna, vwallphases.clientphaseid, 
  vwallphases.forfsm, coalesce(vwallphases.isactive,'0') as islicenseactive,  
	decode(vwallphases.offerapproved,'1','<font color="green"><b>Yes</b></font>','0','<font color="red"><b>No</b></font>','Undefined') as offerstatus,	
  coalesce(frequencys.isactive,'0') as isfrequencyactive, 
  getLicenseFrequencys(vwallphases.effectiveclientlicenseid) as frequencies
	--decode(channel.channelplanid,27,channel.subbandname,28,channel.subbandname,87,'Amateur Band',101,'Aeronautical Band',channel.transmit) as transmit, 
  --decode(channel.channelplanid,27,channel.subbandname,28,channel.subbandname,87,'Amateur Band',101,'Aeronautical Band',channel.receive) as receive
	from vwallphases	
	inner join stations on vwallphases.effectiveclientlicenseid = stations.clientlicenseid	
	inner join frequencys on stations.stationid = frequencys.stationid
	inner join channel on frequencys.channelid = channel.channelid
	inner join channelplan on channel.channelplanid = channelplan.channelplanid;




create or replace view vwfrequencyassignments as
	select distinct vwstations.stationid,vwstations.stationname, vwstations.stationcallsign, vwstations.clientname, vwstations.aircrafttype,vwstations.aircraftregno, vwstations.stationclassid,
	vwstations.vesselname,vwstations.vesseltypename,vwstations.imonumber,vwstations.grosstonnage, vwstations.clientlicenseid, vwstations.defactolocation,
	coalesce(frequencys.isreserved,'0') as isfrequencyreserved, coalesce(frequencys.isactive,'0') as isfrequencyactive,  
	channelplan.channelplanname, channel.channelid, channel.channelnumber, channel.subbandname, channel.itu_reference, channel.channelspacing, 
	channel.transmit, channel.receive, channel.unitsofmeasure, countChannels(vwstations.stationid) as channels, vwstations.stationlocation,
	countbase(vwstations.clientlicenseid) as fixed, countportable(vwstations.clientlicenseid) as portables, countmobile(vwstations.clientlicenseid) as mobiles	
	from  vwstations 
	inner join frequencys on vwstations.stationid = frequencys.stationid
	inner join channel on frequencys.channelid = channel.channelid
	inner join channelplan on channel.channelplanid = channelplan.channelplanid;


CREATE OR REPLACE FUNCTION countChannels(sta_id in integer) RETURN integer IS
PRAGMA AUTONOMOUS_TRANSACTION;
	myret int;
BEGIN
	
	select count(frequencys.stationid) into myret 
	from frequencys 
	inner join channel on frequencys.channelid = channel.channelid
	where frequencys.stationid = sta_id;
		
	RETURN myret;

EXCEPTION
	WHEN OTHERS THEN
		RETURN -1;

END;
/






--Read all assigned frequencies into a varchar
CREATE OR REPLACE FUNCTION getAssignedFrequencys(sta_id in integer) RETURN VARCHAR IS
  PRAGMA AUTONOMOUS_TRANSACTION;
  
	myret VARCHAR2(2000);
  
BEGIN
	
	myret := '';      
  
  --GET ALL frequency entries
  FOR myfreq IN (SELECT distinct channelid, bandassignmentid, amateurtypeid, aircrafttypeid FROM frequencys WHERE stationid = sta_id) LOOP
    
    --for band assignments we dont need to LOOP thru all assigned channels
    IF (myfreq.bandassignmentid IS NOT null) THEN
    
      IF(myfreq.amateurtypeid = 1 ) THEN     --FULL AMATEUR
        myret := 'Full Amateur Band';      
      ELSIF(myfreq.amateurtypeid = 2)THEN   --TEMP AMATEUR
        myret := 'Temporary Amateur Band';      
      ELSIF(myfreq.amateurtypeid = 3)THEN   --NOVICE AMATEUR
        myret := 'Novice Amateur Band'; 
      ELSIF(myfreq.aircrafttypeid = 1)THEN  --AIRCRAFT HF
        myret := 'Aircraft HF Band'; 
      ELSIF(myfreq.aircrafttypeid = 2)THEN  --AIRCRAFT VHF
        myret := 'Aircraft VHF Band'; 
      ELSIF(myfreq.aircrafttypeid = 3)THEN  --AIRCRAFT HF + VHF
        myret := 'Aircraft HF + VHF Band'; 
      ELSE
        RETURN 'UNKNOWN Band';
      END IF;
      
      RETURN myret; 
      
    END IF;
    
    
    FOR mychann IN (SELECT channelid, transmit, receive, unitsofmeasure FROM channel WHERE channelid = myfreq.channelid) LOOP
      IF(mychann.transmit = mychann.receive)THEN
        myret := myret || 'Channel: <b>' || mychann.channelid || '</b> Simplex: <b>' || mychann.transmit || ' ' || mychann.unitsofmeasure ||'</b><br>';
      ELSE
        myret := myret || 'Channel: <b>' || mychann.channelid || '</b> F1: <b>' || mychann.transmit || '</b> F2: <b>' || mychann.receive || ' ' || mychann.unitsofmeasure ||'</b><br>';
      END IF;
    END LOOP;
    
  END LOOP;
  
	RETURN myret;

EXCEPTION
	WHEN OTHERS THEN
		RETURN 'Error';

END;
/



--a selfcontained view used by the frequency assignment report
CREATE OR REPLACE VIEW vwoperatingband AS
SELECT distinct clients.clientid, clients.clientname, stations.stationid, frequencys.isreserved, frequencys.isactive as isactivefrequency, getReceivers(stations.stationid) as receivers,
  licenses.licensename,licenses.licenseid,  coalesce(vhfnetwork.vhfnetworkname,'Default Network') as networkname, coalesce(coalesce(coalesce(vhfnetwork.vhfnetworklocation,stations.location),vwmergedsites.location),'UNDEFINED') as stationlocation, 
  frequencys.actiondate, getAssignedFrequencys(stations.stationid) as frequencyassignmenthtml, stations.stationname, stations.unitsrequested, stations.unitsapproved,
  DECODE(licenses.isterrestrial,'1',to_char(stations.requestedfrequencyGHz || ' GHz'),getOperatingBand(stations.stationid)) as operatingband, stations.requestedfrequencyGHz,
  DECODE(licenses.isterrestrial,'1',stations.requestedfrequencyGHz*1000,getCenterFrequencyRangeMHz(stations.stationid)) as centerfrequencyrangeMHz,
  licenses.isterrestrial, stations.numberoffrequencies, stations.path_length_km, stations.stationcallsign, licenseprices.typename, 
  alarmdecoder.equipmentserialno as decoderserialno, alarmdecoder.rfbandwidth as decoderbandwidth,
  clientlicenses.clientlicenseid, clientlicenses.isactive as isactivelicense
FROM stations  	
  INNER JOIN frequencys ON stations.stationid = frequencys.stationid
  INNER JOIN  clientlicenses ON stations.clientlicenseid = clientlicenses.clientlicenseid  
  INNER JOIN  clients ON clientlicenses.clientid = clients.clientid
  INNER JOIN licenses ON clientlicenses.licenseid = licenses.licenseid
  INNER JOIN  licenseprices ON stations.licensepriceid = licenseprices.licensepriceid
  LEFT JOIN  vwmergedsites ON stations.siteid = vwmergedsites.siteid
  LEFT JOIN  vhfnetwork ON stations.vhfnetworkid = vhfnetwork.vhfnetworkid
  LEFT JOIN alarmdecoder ON clientlicenses.clientlicenseid = alarmdecoder.clientlicenseid;




--get the average of the highest RX and the lowest TX on this station. this will be used to estimate the Operating band
CREATE OR REPLACE FUNCTION getOperatingBand(sta_id in integer) RETURN varchar IS
  PRAGMA AUTONOMOUS_TRANSACTION;
  
	band varchar(20);
  
  lowtx int;
  highrx int;
  units varchar(10);
  
BEGIN
	  
  
  SELECT transmit, unitsofmeasure INTO lowtx, units FROM frequencys INNER JOIN channel ON frequencys.channelid = channel.channelid WHERE frequencyid = (SELECT min(frequencyid) FROM frequencys WHERE stationid = sta_id);
  SELECT receive INTO highrx FROM frequencys INNER JOIN channel ON frequencys.channelid = channel.channelid WHERE frequencyid = (SELECT max(frequencyid) FROM frequencys WHERE stationid = sta_id); 
  
  band := lowtx || ' - ' || highrx || ' ' || units;
 
	RETURN band;

EXCEPTION
	WHEN OTHERS THEN
		RETURN 'Unknow Band';

END;
/




--GET HIGHEST FREQU ON THIS STATION
CREATE OR REPLACE FUNCTION getUpperFrequencyMHz(sta_id in integer) RETURN real IS
  PRAGMA AUTONOMOUS_TRANSACTION;
  
  highrx real;
  units varchar(10);
  
BEGIN
	    
  --highest frequency  
  select max(receive), unitsofmeasure
into highrx,units
from channel 
inner join frequencys on channel.channelid = frequencys.channelid
inner join stations on frequencys.stationid = stations.stationid
where stationid = sta_id
group by unitsofmeasure;

  IF(units = 'GHz')THEN
    highrx := highrx * 1000;
  ELSIF(units = 'MHz')THEN
    highrx := highrx;
  ELSIF(units = 'KHz')THEN
    highrx := highrx/1000;  
  ELSE  --assum MHz
    highrx := highrx;  
  END IF;
  
	RETURN highrx;

EXCEPTION
	WHEN OTHERS THEN
		RETURN -1;

END;
/



--get the lowest (tx) 
CREATE OR REPLACE FUNCTION getLowerFrequencyMHz(sta_id in integer) RETURN real IS
  PRAGMA AUTONOMOUS_TRANSACTION;
  
  lowtx real;
  units varchar(10);
  
BEGIN
	    
  --lowest frequency
  select min(transmit), unitsofmeasure
into lowtx, units
from channel 
inner join frequencys on channel.channelid = frequencys.channelid
inner join stations on frequencys.stationid = stations.stationid
where stationid = sta_id
group by unitsofmeasure;

  IF(units = 'GHz')THEN
    lowtx := lowtx * 1000;
  ELSIF(units = 'MHz')THEN
    lowtx := lowtx;
  ELSIF(units = 'KHz')THEN
    lowtx := lowtx/1000;  
  ELSE  --assume MHz
    lowtx := lowtx;  
  END IF;
  
	RETURN lowtx;

EXCEPTION
	WHEN OTHERS THEN
		RETURN -1;

END;
/


CREATE OR REPLACE FUNCTION getCenterFrequencyRangeMHz(sta_id in integer) RETURN real IS
  PRAGMA AUTONOMOUS_TRANSACTION;
  
	center real;
  
  lowtx int;
  hightx int;
  units varchar(10);
  
BEGIN
	
	center := 0;      
  
  SELECT transmit, unitsofmeasure INTO lowtx, units FROM frequencys INNER JOIN channel ON frequencys.channelid = channel.channelid WHERE frequencyid = (SELECT min(frequencyid) FROM frequencys WHERE stationid = sta_id);
  SELECT transmit INTO hightx FROM frequencys INNER JOIN channel ON frequencys.channelid = channel.channelid WHERE frequencyid = (SELECT max(frequencyid) FROM frequencys WHERE stationid = sta_id); 
  
  center := (lowtx + hightx)/2;
  
  IF(units = 'GHz')THEN
    center := center*1000; 
  ELSIF(units = 'MHz')THEN
    center := center;
  ELSIF(units = 'KHz')THEN
    center := center/1000;  
  ELSE  --ASSUME GHZ
    center := center;
  END IF;
 
	RETURN center;

EXCEPTION
	WHEN OTHERS THEN
		RETURN -1;

END;
/


--all frequencies assigned to stations in this application
CREATE OR REPLACE FUNCTION getLicenseFrequencys(cli_lic_id in integer) RETURN VARCHAR IS
  PRAGMA AUTONOMOUS_TRANSACTION;
  
	myret VARCHAR2(2000);
  
BEGIN
	
	myret := '';
  
  --GET ALL frequency entries
  FOR mysta IN (SELECT stations.stationid, stations.clientlicenseid, stations.stationcallsign, getAssignedFrequencys(stationid) as freqs 
          FROM stations 
          INNER JOIN clientlicenses ON stations.clientlicenseid = coalesce(clientlicenses.parentclientlicenseid, clientlicenses.clientlicenseid) WHERE coalesce(clientlicenses.parentclientlicenseid, clientlicenses.clientlicenseid) = cli_lic_id ) LOOP
    
      myret := myret || 'Station ID: ' || mysta.stationid || ' Frequency :<br>' || mysta.freqs;
    
  END LOOP;
  
	RETURN myret;

EXCEPTION
	WHEN OTHERS THEN
		RETURN 'Error';

END;
/


CREATE OR REPLACE VIEW vwfreqstations AS 
	SELECT DISTINCT stations.stationid,stations.clientlicenseid,vwclientlicenses.effectiveclientlicenseid,stations.stationcallsign,
    vwclientlicenses.licensename,vwclientlicenses.clientname,stations.numberoffrequencies,vwclientlicenses.isterrestrial,
	getNumberOfFrequencies(stationid) as numberofassignedfrequencies,
    (stations.numberoffrequencies - getNumberOfFrequencies(stations.stationid)) as pendingassignment, 
	stations.extranumberoffrequencies
	FROM stations
  INNER JOIN vwclientlicenses on stations.clientlicenseid = vwclientlicenses.effectiveclientlicenseid;








CREATE OR REPLACE VIEW vwdistinctstations AS 
	SELECT DISTINCT stations.stationid,stations.stationname, licenseprices.stationclassid, stations.clientlicenseid,vwclientlicenses.effectiveclientlicenseid,stations.stationcallsign,
    vwclientlicenses.licensename,vwclientlicenses.clientname,stations.numberoffrequencies,vwclientlicenses.isterrestrial,
	getNumberOfFrequencies(stations.stationid) as numberofassignedfrequencies,vwmergedsites.maplink, vhfnetwork.vhfnetworkname,
    (stations.numberoffrequencies - getNumberOfFrequencies(stations.stationid)) as pendingassignment, vhfnetwork.vhfnetworkid,stations.isactive as isactivestation,
    licenseprices.licensepriceid, licenseprices.typename,round(stations.stationcharge,2) as stationcharge,getAssignedFrequencys(stations.stationid) as frequencyassignmenthtml,
    decode(cast(stationequipment.carrieroutputpower as int), 5,'PORTABLE', 10, stations.vehicleregistration,coalesce(vhfnetwork.vhfnetworklocation,vwmergedsites.location)) as defactolocation,		
	stations.extranumberoffrequencies
	FROM stations
  LEFT JOIN stationequipment on stations.stationid = stationequipment.stationid			--TESTED FOR COMPLIANCE WITH DECLARATION STUFF
  INNER JOIN vwclientlicenses on stations.clientlicenseid = vwclientlicenses.effectiveclientlicenseid
  LEFT JOIN vhfnetwork on stations.vhfnetworkid = vhfnetwork.vhfnetworkid
  LEFT JOIN vwmergedsites on stations.siteid = vwmergedsites.siteid
  LEFT JOIN licenseprices on stations.licensepriceid = licenseprices.licensepriceid;





CREATE OR REPLACE VIEW VWSTATIONS AS 
	SELECT stations.stationid, stations.clientlicenseid, vwclientlicenses.effectiveclientlicenseid, stations.stationname, duplexmethod.duplexmethod, stations.aircraftname, 
    stations.path_length_km, round(stations.stationcharge + 0.4) as stationcharge, vwmergedsites.longitude, vwmergedsites.latitude, getAssignedFrequencys(stations.stationid) as frequencyassignmenthtml,
    stations.isaircraft, stations.istransmitter,stations.aircrafttype, stations.isactive as isactivestation, stations.decommissiondate, 
    stations.numberofsectors, stations.txpersector, stations.aircraftregno, round(stations.proratedcharge,2) as initialfee, 
    stations.stationcharge as annualfee, stations.stationcallsign, stations.numberofreceivers, stations.feedertype, stations.feederloss, 
    stations.attenuation,stations.transmitstationid, getTransmitstationName(stations.stationid,stations.transmitstationid) as transmittername, 
    stations.max_operation_hours, stations.EIRPdBW, stations.proposed_operation_date, stations.vehicleregistration, 
    licenseprices.licensepriceid, licenseprices.typename, vwmergedsites.siteid, vwmergedsites.sitename, vwmergedsites.location,
    vwmergedsites.sitelongitude, vwmergedsites.sitelatitude, vwmergedsites.sit_asl, vwmergedsites.sitesummary,
	vwmergedsites.sitecode, vwmergedsites.serviceradius, vwmergedsites.lrnumber, vwmergedsites.sitedetail, vwclientlicenses.clientid,
    stations.isrural, vwclientlicenses.isterrestrial, vwclientlicenses.isvhf, vwclientlicenses.ismaritime, getCreditPeriod(sysdate) as creditmonths,
    round((stations.stationcharge * (getCreditPeriod(sysdate)/12)),2) as creditamount,vwclientlicenses.applicationdate,
    vwclientlicenses.filenumber, vwclientlicenses.clientname, vwclientlicenses.licenseid, vwclientlicenses.licensename,
    vwclientlicenses.isactive, vhfnetwork.vhfnetworkid, vhfnetwork.vhfnetworkname, vhfnetwork.vhfnetworklocation, stations.forexport,
    stations.requestedspotfrequencies, vwclientlicenses.address,vwclientlicenses.postalcode,vwclientlicenses.offersentdate,
    vwclientlicenses.purposeoflicense,proratedChargePeriod(current_date) as chargedmonths, getReceivers(stations.stationid) as receivers,
    decode(cast(stationequipment.carrieroutputpower as int), 5,'PORTABLE', 10, stations.vehicleregistration,coalesce(vhfnetwork.vhfnetworklocation,vwmergedsites.location)) as defactolocation,	
    stationclass.stationclassid, stationclass.stationclassname, countfixed(stations.clientlicenseid) as fixed, servicenature.servicenatureid,
    radiobroadcastingtype.radiobroadcastingtype,servicenature.servicenaturename, stations.unitsrequested, stations.unitsapproved,
    stations.requestedfrequencybands,stations.requestedfrequency,stations.requestedfrequencyGHz ,stations.requestedbandwidth,
    stations.requestedbandwidthMHz, (stations.requestedbandwidth/1000) as requestedBWMHz, vesseltypes.vesseltypeid,
    vesseltypes.vesseltypename,	stations.vesselname,stations.grosstonnage,stations.imonumber,decode(vwclientlicenses.licensename,'Land Mobile Service','RF 3','Maritime Station','RF 14B','Port Operations(Coast) License','RF 3 B','RF3') as frequencyform,
	(vwclientlicenses.clientname || '<br> ' || licenseprices.typename || '<br> ' || vwmergedsites.location) as summary, (vwclientlicenses.clientname || ' ' || licenseprices.typename || ' ' || vwmergedsites.location) as clientsummary,
    vwclientlicenses.conditionslink, stations.isdeclared,vwmergedsites.maplink, coalesce(coalesce(coalesce(vhfnetwork.vhfnetworklocation,stations.location),vwmergedsites.location),'UNDEFINED') as stationlocation, 
    stations.numberoffrequencies,getNumberOfFrequencies(stationid) as numberofassignedfrequencies, (numberoffrequencies - getNumberOfFrequencies(stationid)) as pendingassignment, stations.extranumberoffrequencies, 
	trunkedradiotype.trunkedradiotypename	
	FROM stations
	INNER JOIN vwclientlicenses on stations.clientlicenseid = vwclientlicenses.effectiveclientlicenseid
	LEFT JOIN stationequipment on stations.stationid = stationequipment.stationid			--TESTED FOR COMPLIANCE WITH DECLARATION STUFF
	LEFT JOIN vhfnetwork on stations.vhfnetworkid = vhfnetwork.vhfnetworkid
	LEFT JOIN licenseprices on stations.licensepriceid = licenseprices.licensepriceid
	LEFT JOIN stationclass on licenseprices.stationclassid = stationclass.stationclassid
	LEFT JOIN vwmergedsites on stations.siteid = vwmergedsites.siteid
	LEFT JOIN vesseltypes on stations.vesseltypeid = vesseltypes.vesseltypeid
	LEFT JOIN servicenature on stations.servicenatureid = servicenature.servicenatureid
	LEFT JOIN duplexmethod on stations.duplexmethodid = duplexmethod.duplexmethodid
	LEFT JOIN trunkedradiotype on stations.trunkedradiotypeid = trunkedradiotype.trunkedradiotypeid
	LEFT JOIN radiobroadcastingtype on stations.radiobroadcastingtypeid = radiobroadcastingtype.radiobroadcastingtypeid;







CREATE OR REPLACE FUNCTION getTransmitstationName(sta_id in integer,tra_sta_id in integer) RETURN varchar IS
PRAGMA AUTONOMOUS_TRANSACTION;
	myret varchar(100);	
BEGIN
	
	IF tra_sta_id IS NULL THEN	--it means this is the transmitter
		SELECT stationname INTO myret FROM stations WHERE stationid = sta_id;
		RETURN myret;
	ELSE
		SELECT stationname INTO myret FROM stations WHERE stationid = tra_sta_id;
		RETURN myret;
	END IF;

EXCEPTION
	WHEN OTHERS THEN
		RETURN 'error';

END;
/

set scan off;
CREATE OR REPLACE VIEW VWSTATIONASSIGNMENT AS 
select stations.stationid, stations.clientlicenseid, stations.stationname, stations.aircraftname, stations.path_length_km, round(stations.stationcharge) as stationcharge, vwmergedsites.longitude, vwmergedsites.latitude,
	stations.aircrafttype, stations.aircraftregno, stations.stationcallsign, stations.numberofreceivers, stations.feedertype, stations.feederloss, stations.attenuation, decode(numberoffrequencies, 1, 'Simplex', 2, 'Duplex', numberoffrequencies || ' channels' ) as channeltype,stations.numberoffrequencies,
	stations.transmitstationid, stations.max_operation_hours, stations.proposed_operation_date, stations.vehicleregistration, licenseprices.licensepriceid, licenseprices.typename, vwmergedsites.siteid, vwmergedsites.sitename,vwmergedsites.location, vwmergedsites.sitelongitude, vwmergedsites.sitelatitude, vwmergedsites.sit_asl, vwmergedsites.sitesummary, 
	vwmergedsites.sitecode, vwmergedsites.serviceradius,vwmergedsites.lrnumber, vwclientlicenses.clientid, stations.isrural, vwclientlicenses.isterrestrial, vwclientlicenses.isvhf, 
	vwclientlicenses.clientname, vwclientlicenses.licenseid, vwclientlicenses.licensename,vwclientlicenses.isactive,vhfnetwork.vhfnetworkid, vhfnetwork.vhfnetworklocation, stations.forexport,
	vwclientlicenses.address,vwclientlicenses.postalcode,proratedChargePeriod(current_date) as chargedmonths, getReceivers(stations.stationid) as receivers ,
	stationclass.stationclassid, stationclass.stationclassname, countfixed(stations.clientlicenseid) as fixed, servicenature.servicenatureid, 
	servicenature.servicenaturename, stations.unitsrequested, stations.unitsapproved,stations.requestedfrequencybands,stations.requestedfrequency,stations.requestedbandwidth,vesseltypes.vesseltypeid,
	vesseltypes.vesseltypename,	stations.vesselname,stations.grosstonnage,stations.imonumber,decode(vwclientlicenses.licensename,'Land Mobile Service','RF 3','Maritime Station','RF 14B','Port Operations(Coast) License','RF 3 B','RF3') as frequencyform,
	(vwclientlicenses.clientname || '<br> ' || licenseprices.typename || '<br> ' || vwmergedsites.location) as summary, (vwclientlicenses.clientname || ' ' || licenseprices.typename || ' ' || vwmergedsites.location) as clientsummary,
	channel.channelid,  channel.channelnumber, channel.transmit, channel.receive, channel.duplexspacing
from stations
inner join vwclientlicenses on stations.clientlicenseid = vwclientlicenses.clientlicenseid
inner join frequencys on stations.stationid = frequencys.stationid
inner join channel on frequencys.channelid = channel.channelid
left join vhfnetwork on stations.vhfnetworkid = vhfnetwork.vhfnetworkid
left join licenseprices on stations.licensepriceid = licenseprices.licensepriceid
left join stationclass on licenseprices.stationclassid = stationclass.stationclassid
inner join vwmergedsites on stations.siteid = vwmergedsites.siteid
left join vesseltypes on stations.vesseltypeid = vesseltypes.vesseltypeid
left join servicenature on stations.servicenatureid = servicenature.servicenatureid;



create or replace view vwfrequencyapplicants as 
	select banddefinition.*,vwstations.summary, vwstations.stationid
	from banddefinition,vwstations;




create view vwstationannualcharge as
	select stations.clientlicenseid, stations.stationid,stations.stationname, stations.stationcallsign, stations.transmitstationid,
	('Paid Kshs ' || round(stations.proratedcharge) || ' for the first ' || stations.initialchargeperiod || ' months') as firstpayment, 
	round(calculateannualcharge(stations.stationid)) as annualcharge, round(stations.proratedcharge) as proratedcharge, stations.initialchargeperiod,
	stations.proposed_operation_date,stations.unitsapproved,stations.numberofreceivers
	from stations;


create or replace view vwmergedstationannualcharge as
	(select stations.clientlicenseid, stations.stationid,stations.stationname, 
	stations.stationcallsign, stations.transmitstationid, licenseprices.stationclassid,
	('Paid Kshs ' || round(stations.proratedcharge) || ' for the first ' || stations.initialchargeperiod || ' months') as firstpayment, 
	round(calculateannualcharge(stations.stationid)) as annualcharge, round(stations.proratedcharge) as proratedcharge, stations.initialchargeperiod,
	stations.proposed_operation_date,stations.unitsapproved,stations.numberofreceivers
	from stations
	inner join licenseprices on stations.licensepriceid = licenseprices.licensepriceid)
	UNION
	(SELECT sms_station.sta_lic_id as clientlicenseid, sms_station.sta_id as stationid, sms_station.sta_name as stationname, 
	sms_station.sta_call_sign as stationcallsign, null as transmitstationid, sms_station.sta_class as stationclassid,
	'' as firstpayment,
	sms_station_charge(sta_id, null) as annualcharge, 0 as proratedcharge, 0 as initialchargeperiod,
	null as proposed_operation_date, null as unitsapproved, null as numberofreceivers
	from sms_station
  where status='R');



--original
-- create view vwclientannualcharge as
-- 	select clientlicenseid,sum(annualcharge) as aggregatecharge
-- 	from vwstationannualcharge
-- 	group by clientlicenseid;

--inclusive
create or replace view vwclientannualcharge as
	select clientlicenseid,sum(annualcharge) as aggregatecharge
	from vwmergedstationannualcharge
	group by clientlicenseid;


CREATE OR REPLACE VIEW VWCLIENTSTATIONS AS 
  select vwclientlicenses.clientlicenseid, vwclientlicenses.clientid, vwclientlicenses.clientname, vwclientlicenses.licenseid, 
	vwclientlicenses.licensename, clientstations.clientstationid, clientstations.numberofrequestedstations, clientstations.numberofapprovedstations, clientstations.applicationdate,
	clientstations.location, clientstations.numberoffrequencies,decode(numberoffrequencies, 1, 'Simplex', 2, 'Duplex', numberoffrequencies || ' channels' ) as channeltype, round(clientstations.tentativeprice) as tentativeprice, round(clientstations.finalprice) as finalprice,
	clientstations.aircrafttype, clientstations.aircraftname, clientstations.aircraftregno,licenseprices.licensepriceid, proratedChargePeriod(current_date) as chargedmonths,
	licenseprices.typename, licenseprices.stationclassid, clientstations.requestedfrequencybands, clientstations.requestedfrequency,clientstations.requestedbandwidth,trunkedradiotype.trunkedradiotypename
	from vwclientlicenses
	inner join clientstations on vwclientlicenses.clientlicenseid=clientstations.clientlicenseid
	inner join licenseprices on clientstations.licensepriceid=licenseprices.licensepriceid
	left join trunkedradiotype on clientstations.trunkedradiotypeid = trunkedradiotype.trunkedradiotypeid;
 











create or replace view vwnetworksummary as
	select vwclientstations.clientlicenseid,countstations(vwclientstations.clientlicenseid) as stations, vwclientstations.clientid, vwclientstations.clientname, vwclientstations.location, clienttypes.clienttypename, clientlicenses.secretariatremarks, clientlicenses.commiteeremarks, clc.clcid, clc.clcdate, clc.clcnumber,
	(clients.clientname ||'<br>'|| 'P.O.Box' || clients.address ||'<br>' || initcap(clients.town) || '-' || postoffice.postalcode || '<br>' || initcap(countrys.countryname)) as clientdetail
	from vwclientstations
	inner join clientlicenses on vwclientstations.clientlicenseid = clientlicenses.clientlicenseid
	inner join clc on clientlicenses.clcid = clc.clcid
	inner join clients on vwclientstations.clientid = clients.clientid
	inner join countrys on clients.countryid = countrys.countryid
	inner join postoffice on clients.postofficeid = postoffice.postofficeid
	inner join clienttypes on clients.clienttypeid = clienttypes.clienttypeid;


---
CREATE OR REPLACE FUNCTION countstations(cli_lic_id in integer) RETURN varchar IS
PRAGMA AUTONOMOUS_TRANSACTION;
	myret int;
	summary varchar(1000);
BEGIN
	summary := '';
	for myrec in (select numberofrequestedstations, typename from vwclientstations where clientlicenseid = cli_lic_id) loop
		summary := summary  || myrec.numberofrequestedstations || ' ' || myrec.typename || '<br>  '; 
	end loop;

	RETURN summary;

EXCEPTION
	WHEN OTHERS THEN
		RETURN 'error';

END;
/

--b4 clc
CREATE OR REPLACE FUNCTION countnetworkstations(vhf_net_id in integer) RETURN varchar IS
PRAGMA AUTONOMOUS_TRANSACTION;
	myret int;
	summary varchar(1000);
BEGIN
	summary := '';
	for myrec in (select numberofrequestedstations, typename from clientstations inner join licenseprices on clientstations.licensepriceid=licenseprices.licensepriceid where vhfnetworkid = vhf_net_id) loop
		summary := summary  || myrec.numberofrequestedstations || ' ' || myrec.typename || '<br>  '; 
	end loop;

	RETURN summary;

EXCEPTION
	WHEN OTHERS THEN
		RETURN 'error';

END;
/





--point to point receivers
CREATE OR REPLACE FUNCTION getReceivers(transmitterid in integer) RETURN varchar IS
PRAGMA AUTONOMOUS_TRANSACTION;
	myret int;
	summary varchar(500);
BEGIN
	summary := '<b>Site A:</b> ';
	for myrec in (select stations.stationname, stations.siteid, vwmergedsites.sitecode, vwmergedsites.sitelongitude, vwmergedsites.sitelatitude from stations LEFT JOIN vwmergedsites on stations.siteid = vwmergedsites.siteid where transmitstationid = transmitterid) loop
		summary := summary || ' ID: ' || myrec.siteid || ' Code:' || myrec.sitecode|| ' Lat:' || myrec.sitelatitude || ' Long:' || myrec.sitelongitude ||'<br> <b>Site B:</b> '; 
	end loop;
	
	select substr(summary,0,(length(summary)-20)) into summary from dual;

	RETURN summary;
END;
/





--SITE A and SITE B
CREATE OR REPLACE FUNCTION getSiteA(link_id IN INTEGER) RETURN VARCHAR IS
PRAGMA AUTONOMOUS_TRANSACTION;

	sta_name varchar(100);	
  
BEGIN

	SELECT stationname into sta_name from stations where stationid = (select max(stationid) from stations where transmitstationid = link_id);

	RETURN sta_name;
  
END;
/

CREATE OR REPLACE FUNCTION getSiteB(link_id IN INTEGER) RETURN VARCHAR IS
PRAGMA AUTONOMOUS_TRANSACTION;

	sta_name varchar(100);	
  
BEGIN

	SELECT stationname into sta_name from stations where stationid = (select min(stationid) from stations where transmitstationid = link_id);

	RETURN sta_name;
  
END;
/



--get all relevant remarks for this particular application
CREATE OR REPLACE FUNCTION getAllRemarks(cli_lic_id in integer) RETURN varchar IS
PRAGMA AUTONOMOUS_TRANSACTION;
	myret int;
	summary varchar(10000);
	clcremarks varchar(10000);
BEGIN
	--summary := '<b>Site A:</b> ';
	for myrec in (select (' <b>' || phasename ||'</b> : '|| narrative) as remarks from clientphases inner join phases on clientphases.phaseid=phases.phaseid where clientlicenseid = cli_lic_id) loop
		summary := summary || myrec.remarks || '<br>'; 
	end loop;

	select '<b>Secretariat Comments:</b> ' || secretariatremarks || '<br><b>Commitee Comments:</b> ' || commiteeremarks into clcremarks from clientlicenses where clientlicenseid=cli_lic_id;
		
	summary := summary || '<br><b>CLC</b><br>'|| clcremarks;	

	RETURN summary;
END;
/




CREATE OR REPLACE VIEW VWCLIENTSTATIONDETAILS AS 
  select clientlicenses.clientlicenseid, vwclients.clientid, vwclients.clientname, licenses.licenseid, clientlicenses.isfreqexpansion, clientlicenses.isnetworkexpansion, 
	licenses.licensename, vwclients.filenumber,licenseprices.licensepriceid, licenseprices.typename, vhfnetwork.vhfnetworklocation, clientlicenses.islicensereinstatement, 
	clientstations.clientstationid, clientstations.clientstationname, clientlicenses.applicationdate as applicationdate, 
	vwclients.address, vwclients.town, vwclients.postalcode, clientstations.numberofrequestedstations, clientstations.numberofapprovedstations, clientstations.tentativeprice, clientstations.numberoffrequencies,
	proratedChargePeriod(current_date) as chargedmonths, calculateinitialcharge(clientstations.clientstationid, current_date) as proratedcharge
	from clientlicenses
	inner join vwclients on clientlicenses.clientid = vwclients.clientid
	inner join licenses on clientlicenses.licenseid = licenses.licenseid
	inner join vhfnetwork on clientlicenses.clientlicenseid = vhfnetwork.clientlicenseid
	inner join clientstations on vhfnetwork.vhfnetworkid = clientstations.vhfnetworkid
	inner join licenseprices on clientstations.licensepriceid = licenseprices.licensepriceid;




--non vhf netw
CREATE OR REPLACE VIEW VWALARMSTATIONS AS 
  select clientlicenses.clientlicenseid, vwclients.clientid, vwclients.clientname, licenses.licenseid, 
	licenses.licensename, vwclients.filenumber,licenseprices.licensepriceid, licenseprices.typename, clientstations.location,
	clientstations.clientstationid, clientstations.clientstationname, clientlicenses.applicationdate as applicationdate, 
	vwclients.address, vwclients.town, vwclients.postalcode, clientstations.numberofrequestedstations, clientstations.numberofapprovedstations, clientstations.tentativeprice, clientstations.numberoffrequencies,
	proratedChargePeriod(current_date) as chargedmonths, calculateinitialcharge(clientstations.clientstationid, current_date) as proratedcharge
	from clientlicenses
	inner join vwclients on clientlicenses.clientid = vwclients.clientid
	inner join licenses on clientlicenses.licenseid = licenses.licenseid	
	inner join clientstations on clientstations.clientlicenseid = clientlicenses.clientlicenseid
	inner join licenseprices on clientstations.licensepriceid = licenseprices.licensepriceid;



--full station equipment details for the report
create or replace view vwstationdetails as
	select stations.stationid,stations.transmitstationid,stations.requestedfrequency,stations.clientlicenseid,licenseprices.stationclassid, stations.sta_call_sign ,equipments.make, equipments.model, stationequipment.equipmentserialno, equipments.suppliername, sites.location as sitelocation,
	vwclientlicenses.clientname, vwclientlicenses.address,vwclientlicenses.town,vwclientlicenses.postalcode,vwclientlicenses.applicationdate,vwclientlicenses.licenseid, vwclientlicenses.licensename,vwclientlicenses.filenumber, stations.location, round(stations.stationcharge + 0.4) as stationcharge,
	proratedChargePeriod(current_date) as chargedmonths, vwclientlicenses.isfreqexpansion, calculateinitialcharge(stations.stationid, current_date) as proratedcharge
	from stations 
	inner join vwclientlicenses on stations.clientlicenseid = vwclientlicenses.clientlicenseid
	left join stationequipment on stations.stationid =  stationequipment.stationid
	left join equipments on stationequipment.equipmentid = equipments.equipmentid
	inner join licenseprices on stations.licensepriceid = licenseprices.licensepriceid	
	left join sites on stations.siteid = sites.siteid;











CREATE OR REPLACE VIEW VWSTATIONFREQUENCIES AS 
  select vwstations.stationid, vwstations.stationname, vwstations.typename, vwstations.clientlicenseid, vwstations.clientid, countstations(vwstations.clientlicenseid) as stations,
	vwstations.clientname, vwstations.numberofreceivers, vwstations.transmitstationid, frequencys.frequencyid, frequencys.frq_rx_high_freq,vwstations.location,
	frequencys.frq_tx_high_freq,frequencys.tx_frequencyband,frequencys.rx_frequencyband, frequencyband.frequencybandid, frequencyband.frequencybandname, countfixed(vwstations.clientlicenseid) as fixed, clientlicenses.isactive
from vwstations
inner join frequencys on vwstations.stationid=frequencys.stationid
inner join frequencyband on frequencys.frequencybandid = frequencyband.frequencybandid
left join clientlicenses on vwstations.clientlicenseid = clientlicenses.clientlicenseid;
 


CREATE OR REPLACE VIEW VWSTATIONEQUIPMENT AS 
	select stationequipment.*,vwmergedequipments.fullname,vwmergedequipments.model,vwmergedequipments.make, vwstations.stationname, vwstations.vesselname, vwstations.stationclassname, vwstations.clientname, vwstations.clientlicenseid
	from stationequipment
	left join vwmergedequipments on stationequipment.equipmentid = vwmergedequipments.equipmentid
	left join vwstations on stationequipment.stationid = vwstations.stationid;



CREATE VIEW VWSTATIONANTENNAE AS 
	select stationantenna.stationantennaid, stationantenna.stationid, antennatypes.antennatypename, stationantenna.antennadescr, stationantenna.antennaname, stationantenna.antennamodel, 
	stationantenna.antennamanufacturer, stationantenna.lowfrequency, stationantenna.highfrequency, stationantenna.polarization, 
	stationantenna.maxgaindecibels, stationantenna.azimuth, stationantenna.height, stationantenna.relativeheight, stationantenna.beam_width,
	stationantenna.directivity,stationantenna.details
	from stationantenna
	inner join antennatypes on stationantenna.antennatypeid = antennatypes.antennatypeid;

	
-- update client license details from licenses table also inserts license dependent definations
CREATE OR REPLACE TRIGGER tr_insclientlicenses BEFORE INSERT ON clientlicenses
FOR EACH ROW 
DECLARE
  PRAGMA AUTONOMOUS_TRANSACTION;
     CURSOR insclientlicenses_cur IS
      SELECT l.applicationfee, l.initialfee, l.annualfee, l.agtfee, l.typeapprovalfee, l.fixedfee, l.rolloutperiod,l.currencyunitid
      FROM licenses l
      WHERE l.licenseid = :NEW.licenseid ;
	  rc insclientlicenses_cur%ROWTYPE;
	
BEGIN
	OPEN insclientlicenses_cur;
	FETCH insclientlicenses_cur INTO rc;

	:NEW.rolloutperiod := rc.rolloutperiod;
	:NEW.applicationfee := rc.applicationfee;
	:NEW.initialfee := rc.initialfee; 
	:NEW.annualfee := rc.annualfee; 
	:NEW.agtfee := rc.agtfee;
	:NEW.typeapprovalfee := rc.typeapprovalfee;

commit;
CLOSE insclientlicenses_cur;
END;
/


-- insert client forms types and approval phases when a licence is entered
CREATE OR REPLACE TRIGGER tr_updclientformtypes AFTER INSERT ON clientlicenses
   FOR EACH ROW 
DECLARE
BEGIN
	INSERT INTO clientformtypes (clientlicenseid, formtypeid, applicationdate)
	SELECT :NEW.clientlicenseid, formtypeid, SYSDATE
	FROM vwlicenseforms
	WHERE (application = '1') AND (licenseid = :NEW.licenseid);
	
  INSERT INTO clientdefination (clientlicenseid, narrative)
	SELECT:NEW.clientlicenseid, licensedefination.licensedefname
	FROM licensedefination 
	WHERE (licenseid = :NEW.licenseid);  

END;
/



-- insert client forms types and approval phases when a licence is entered
CREATE OR REPLACE TRIGGER tr_clientphases AFTER INSERT ON clientlicenses
   FOR EACH ROW 
DECLARE
BEGIN

	INSERT INTO clientphases (clientlicenseid, phaseid, clientid, EscalationTime, userid, clientphasename, clientapplevel)	
		SELECT :NEW.clientlicenseid, phaseid, :NEW.clientid, EscalationTime, :NEW.userid, phasename, phaselevel
		FROM phases
		WHERE (phases.licenseid = :NEW.licenseid) AND (isactive = '1');

END;
/



-- suspect!!!!!!!
-- insert client approval phases when a form type is entered
CREATE OR REPLACE TRIGGER tr_insclientformtypes AFTER INSERT ON clientformtypes
    FOR EACH ROW 
BEGIN
INSERT INTO clientphases (clientformtypeid, phaseid, EscalationTime, userid, clientphasename,clientapplevel)
	SELECT :NEW.clientformtypeid, phaseid, EscalationTime, 0, phasename,phaselevel
	FROM phases
	WHERE (formtypeid = :NEW.formtypeid);
END;
/



--b4 training
CREATE OR REPLACE TRIGGER TR_INSCLIENTPHASES AFTER INSERT ON clientphases
    FOR EACH ROW 
DECLARE
--PRAGMA AUTONOMOUS_TRANSACTION;

CURSOR client_cur IS 
	SELECT clientdetail.clientid, clientdetail.clientcategoryid, clientcategorys.clientcategoryname, clientdetail.clienttypeid, clienttypes.clienttypename
	FROM clientdetail	
	inner join clientcategorys on clientdetail.clientcategoryid = clientcategorys.clientcategoryid
	inner join clienttypes on clientdetail.clienttypeid = clienttypes.clienttypeid
	WHERE clientid = :NEW.clientid;

	rec client_cur%ROWTYPE;

BEGIN
	OPEN client_cur;
	FETCH client_cur INTO rec;


	--BUSINESS CATEGORY
	IF (rec.clientcategoryname = 'DIPLOMATIC MISSION') THEN 		--diplomatic

		INSERT INTO clientchecklists (clientphaseid, checklistid)
		SELECT :NEW.clientphaseid, checklistid
		FROM checklists
		WHERE (phaseid =  :NEW.phaseid) AND (diplomatic= '1') AND (isactive = '1');
	
	
	ELSIF (rec.clientcategoryname = 'NGO') THEN 		--ngo

		INSERT INTO clientchecklists (clientphaseid, checklistid)
		SELECT :NEW.clientphaseid, checklistid
		FROM checklists
		WHERE (phaseid =  :NEW.phaseid) AND (ngo = '1')AND (isactive = '1');
	
	ELSIF (rec.clientcategoryname = 'GOVERNMENT ENTITY') THEN 		--government

		INSERT INTO clientchecklists (clientphaseid, checklistid)
		SELECT :NEW.clientphaseid, checklistid
		FROM checklists
		WHERE (phaseid =  :NEW.phaseid) AND (govt = '1')AND (isactive = '1');
		

	ELSIF (rec.clientcategoryname = 'PARTNERSHIP') THEN 		--partnership

		INSERT INTO clientchecklists (clientphaseid, checklistid)
		SELECT :NEW.clientphaseid, checklistid
		FROM checklists
		WHERE (phaseid =  :NEW.phaseid) AND (partnership = '1')AND (isactive = '1');

	ELSIF (rec.clientcategoryname = 'UN ORGANIZATION') THEN 		--un = diplomatic

		INSERT INTO clientchecklists (clientphaseid, checklistid)
		SELECT :NEW.clientphaseid, checklistid
		FROM checklists
		WHERE (phaseid =  :NEW.phaseid) AND (diplomatic= '1')AND (isactive = '1');
		
	ELSIF (rec.clientcategoryname = 'PRIVATE INDIVIDUAL') THEN 		--private individual

		INSERT INTO clientchecklists (clientphaseid, checklistid)
		SELECT :NEW.clientphaseid, checklistid
		FROM checklists
		WHERE (phaseid =  :NEW.phaseid) AND (individual = '1')AND (isactive = '1');
		
-- if rec.clienttypeid = 47 THEN 		--legal entity ??
-- 
-- 		INSERT INTO clientchecklists (clientphaseid, checklistid)
-- 		SELECT :NEW.clientphaseid, checklistid
-- 		FROM checklists
-- 		WHERE (phaseid =  :NEW.phaseid) AND (diplomatic= '1');
-- 
-- 	END IF

	ELSIF (rec.clientcategoryname = 'LIMITED COMPANY') THEN 		--company

		INSERT INTO clientchecklists (clientphaseid, checklistid)
		SELECT :NEW.clientphaseid, checklistid
		FROM checklists
		WHERE (phaseid =  :NEW.phaseid) AND (company = '1')AND (isactive = '1');
		
	ELSIF (rec.clientcategoryname = 'INDIVIDUAL') THEN 		--individual

		INSERT INTO clientchecklists (clientphaseid, checklistid)
		SELECT :NEW.clientphaseid, checklistid
		FROM checklists
		WHERE (phaseid =  :NEW.phaseid) AND (individual= '1')AND (isactive = '1');
	ELSE	--STEVE STUFF
		INSERT INTO clientchecklists (clientphaseid, checklistid)
		SELECT :NEW.clientphaseid, checklistid
		FROM checklists
		WHERE (phaseid =  :NEW.phaseid) AND (isactive = '1');
	END IF;

--CLIENT INDUSTRY
	IF rec.clienttypename = 'SECURITY' THEN 		--security companies

		INSERT INTO clientchecklists (clientphaseid, checklistid)
		SELECT :NEW.clientphaseid, checklistid
		FROM checklists
		WHERE (phaseid =  :NEW.phaseid) AND (forsecurity = '1');

	END IF;
		

END;
/


-- CREATE OR REPLACE  TRIGGER tr_insfrequencys AFTER INSERT OR UPDATE ON frequencys
--     FOR EACH ROW 
-- DECLARE
--      CURSOR insfrequencys_cur IS SELECT
--      sum(funits) as units
-- 	 FROM vwfrequencys WHERE stationid = :NEW.stationid; 
--      rc insfrequencys_cur%ROWTYPE;
-- BEGIN
-- 	OPEN insfrequencys_cur;
-- 	FETCH insfrequencys_cur INTO rc;
-- 	UPDATE stations SET units = rc.units
-- 	WHERE (stationid = :NEW.stationid);
-- CLOSE insfrequencys_cur;
-- END;
-- /

-- update stations units on table
/*create or replace TRIGGER tr_insstations AFTER INSERT OR UPDATE ON stations
    FOR EACH ROW 
DECLARE
    CURSOR insstations_cur1 IS
	SELECT  stationcharges.stationfees, stationcharges.fixedfees
	FROM stationcharges 
	WHERE stationchargeid = :NEW.stationchargeid;
	rc insstations_cur1%ROWTYPE;

CURSOR insstations_cur2 IS
	SELECT sum(totalstationfee) as sf
	FROM vwstations 
	WHERE (stationid = :NEW.stationid);
	rd insstations_cur2%ROWTYPE;
BEGIN
	OPEN insstations_cur1;
	FETCH insstations_cur1 INTO rc;
	IF (rc.fixedfees = '1') AND (:NEW.stationfee <> rc.stationfees) 
	THEN
		UPDATE stations SET stationfee = rc.stationfees
		WHERE (stationid = :NEW.stationid);
	END IF;   
	
	OPEN insstations_cur2;
	FETCH insstations_cur2 INTO rd; 
	IF(rd.sf is not null) THEN
		UPDATE clientlicenses SET annualfee = rd.sf WHERE clientlicenseid = :NEW.clientlicenseid; 
	ELSE
		UPDATE clientlicenses SET annualfee = 0 WHERE clientlicenseid = :NEW.clientlicenseid; 
	END IF;
END;
/*/
	
create or replace FUNCTION ApprovePhase(myval1 IN varchar2, myval2 IN varchar2,myval3 IN varchar2, myval4 IN varchar2) RETURN varchar2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;

  appfac int;
  myret int;
	amnt real;
	COUNTFEES real;
	prtcode varchar(120);
  lic_no int;

CURSOR count_cur IS 
 SELECT  count(clientchecklistid) as rccount FROM clientchecklists
	WHERE (clientphaseid = CAST(myval1 as int)) AND (approved = '0');
  rc count_cur%ROWTYPE;

CURSOR approval_cur IS
SELECT DISTINCT paymenttypes.PAYMENTTYPEID, paymenttypes.paymenttypename, phases.phaseid, clientlicenses.parentclientlicenseid,
	licenses.applicationfee, licenses.annualfee, licenses.initialfee, licenses.typeapprovalfee,
	phases.forpayment, licenses.applicationaccount, clientphases.clientlicenseid, licenses.isserviceprovider, licenses.isterrestrial,
	licenses.initialaccount, licenses.annualaccount, licenses.taaccount, clientphases.clientphaseid, clientid,
	stations.stationcharge, licenses.licensetypeid
	FROM clientphases inner join phases on phases.phaseid = clientphases.phaseid
	INNER JOIN licenses on phases.licenseid = licenses.licenseid
	INNER JOIN clientlicenses on clientlicenses.clientlicenseid = clientphases.clientlicenseid
	LEFT JOIN stations on clientlicenses.clientlicenseid = stations.clientlicenseid
	INNER JOIN paymenttypes on phases.paymenttypeid = paymenttypes.paymenttypeid 
	where clientphaseid = CAST(myval1 as int);
	c2 approval_cur%ROWTYPE;

	CURSOR cursor1 IS
		SELECT clientphases.clientlicenseid from clientphases 
			INNER JOIN CLIENTLICENSES ON CLIENTLICENSES.clientlicenseid = clientphases.clientlicenseid
			WHERE clientphases.clientphaseid = CAST(myval1 as int);
			c3 cursor1%ROWTYPE;

	CURSOR cursor2 IS
		SELECT periodid FROM periods WHERE periods.isactive = '1';
		c4 cursor2%ROWTYPE;

	CURSOR cursor3 IS
		select proratedChargePeriod(sysdate) as trdate from dual;
		c5 cursor3%ROWTYPE;

BEGIN
	OPEN count_cur;
  	FETCH count_cur INTO rc;

	OPEN cursor1;
  	FETCH cursor1 INTO c3;

	OPEN approval_cur;
  	FETCH approval_cur INTO c2;

	OPEN cursor2;
  	FETCH cursor2 INTO c4;
    
    OPEN cursor3;
  	FETCH cursor3 INTO c5;
	
	SELECT DISTINCT count(licensepaymentid) INTO COUNTFEES
			from clientphases inner join phases on phases.phaseid = clientphases.phaseid
			inner join licenses on phases.licenseid = licenses.licenseid
			inner join clientlicenses on clientlicenses.clientlicenseid = clientphases.clientlicenseid
			inner join paymenttypes on phases.paymenttypeid = paymenttypes.paymenttypeid
			inner join licensepayments on licensepayments.clientphaseid = clientphases.clientphaseid
			where clientid = c2.CLIENTID AND TO_CHAR(applicationdate, 'DD/Mon/YY') = TO_CHAR(SYSDATE, 'DD/Mon/YY');
	
	  
	  IF(myval3 = 'Select') AND (rc.rccount = 0)  THEN
			UPDATE clientphases SET approved = '1', rejected = '0', pending = '0',actiondate = sysdate, userid = CAST(myval2 as int)
			WHERE clientphaseid = CAST(myval1 as int);
			COMMIT;
		

		--checking(or other) task done seeking approval from licensing officer or other manages
		ELSIF(myval3 = 'Done') AND (rc.rccount = 0)  THEN
			UPDATE clientphases SET isdone = '1', actiondate = sysdate, userid = CAST(myval2 as int)
			WHERE clientphaseid = CAST(myval1 as int);
			COMMIT;
		
		--the boss may return it
		ELSIF(myval3 = 'Return') THEN
			UPDATE clientphases SET isdone = '0', actiondate = sysdate, userid = CAST(myval2 as int)
			WHERE clientphaseid = CAST(myval1 as int);			
			COMMIT;
		

	  --CLC DECISIONS
		ELSIF(myval3 = 'Approved') AND (rc.rccount = 0) THEN
			UPDATE clientphases SET approved = '1', rejected = '0', DEFFERED='0', pending = '0', Withdrawn = '0', actiondate = sysdate, userid = CAST(myval2 as int)
			WHERE clientphaseid = CAST(myval1 as int);
			COMMIT;		          
			--if it was an expansion make the neccessary adjustments
			--update stations set numberoffrequencies = X where vhfnetworkid = (select vhfnetworkid from vhfnetwork where clientlicenseid = (select clientlicenseid from clientphases where clientphaseid = clientphaseid = CAST(myval1 as int)))

		ELSIF(myval3 = 'Rejected') AND (rc.rccount = 0) THEN
			UPDATE clientphases SET approved = '0', rejected = '1', DEFFERED='0', pending = '0', Withdrawn = '0', actiondate = sysdate, userid = CAST(myval2 as int)
			WHERE clientphaseid = CAST(myval1 as int);
			COMMIT;
			UPDATE clientlicenses SET clcid = null
			WHERE clientlicenseid = (select clientlicenseid from clientphases where clientphaseid = CAST(myval1 as int));
			COMMIT;
		    RETURN 'Rejected';
	


		ELSIF(myval3 = 'Deffered')  THEN
			UPDATE clientphases SET approved = '0', rejected = '0', DEFFERED = '1', pending = '0',Withdrawn = '0', actiondate = sysdate, userid = CAST(myval2 as int)
			WHERE clientphaseid = CAST(myval1 as int);
			COMMIT;
			UPDATE clientlicenses SET clcid = null
			WHERE clientlicenseid = (select clientlicenseid from clientphases where clientphaseid = CAST(myval1 as int));
			COMMIT;
		    RETURN 'Deffered';
	
		
		ELSIF(myval3 = 'Withdrawn')  THEN
			UPDATE clientphases SET approved = '0', rejected = '0', DEFFERED = '0', pending = '0', Withdrawn = '1',  actiondate = sysdate, userid = CAST(myval2 as int)
			WHERE clientphaseid = CAST(myval1 as int);
			COMMIT;

			UPDATE clientlicenses SET clcid = null
			WHERE clientlicenseid = (select clientlicenseid from clientphases where clientphaseid = CAST(myval1 as int));
			COMMIT;

		    RETURN 'Withdrawn';
		
		--end CLC DECISIONS


		ELSIF(myval3 = 'Complete') AND (rc.rccount = 0) THEN
			UPDATE clientphases SET approved = '1', pending = '0', rejected = '0', actiondate = sysdate, userid = CAST(myval2 as int)
			WHERE clientphaseid = CAST(myval1 as int);
			COMMIT;
		    RETURN 'Complete';
		
		
		ELSIF(myval3 = 'Archive')  THEN
			UPDATE clientphases SET approved = '0', pending = '1', rejected = '0', actiondate = sysdate, userid = CAST(myval2 as int)
			WHERE clientphaseid = CAST(myval1 as int);
			COMMIT;
		    RETURN 'Archived';
		

		ELSIF(myval3 = 'UnArchive')  THEN
			UPDATE clientphases SET approved = '1', rejected = '0', pending = '0',actiondate = sysdate, userid = CAST(myval2 as int)
			WHERE clientphaseid = CAST(myval1 as int);
			COMMIT;
		    RETURN 'UnArchived';
		

		ELSIF(myval3 = 'Objected')  THEN
			UPDATE clientphases SET approved = '0', rejected = '1', pending = '0',actiondate = sysdate, userid = CAST(myval2 as int)
			WHERE clientphaseid = CAST(myval1 as int);
			COMMIT;
		    RETURN 'Objected';
		
		
    ELSIF(myval3 = 'Board Approved') AND (rc.rccount = 0) THEN
			UPDATE clientphases SET approved = '1', rejected = '0', DEFFERED='0', pending = '0', Withdrawn = '0', actiondate = sysdate, userid = CAST(myval2 as int)
			WHERE clientphaseid = CAST(myval1 as int);
			COMMIT;		          
      RETURN 'Approved';
		 
		--for initial activation...we approve and mark the license as active at the same time
		ELSIF(myval3 = 'Activate')  THEN
			--UPDATE clientphases SET approved = '1', rejected = '0', pending = '0',actiondate = sysdate, userid = CAST(myval2 as int)
			--WHERE clientphaseid = CAST(myval1 as int);
			--SELECT getLicenseNumber(CAST(myval1 AS INT)) INTO lic_no FROM dual;
			UPDATE clientlicenses SET licensedate = sysdate,licensestartdate = sysdate , isactive = '1', isapproved='1' where clientlicenseid = CAST(myval1 AS INT);--c3.clientlicenseid;
			COMMIT;
			RETURN 'License Activated';
		

		ELSIF(myval3 = 'Tareceive') AND (rc.rccount = 0) THEN
			UPDATE clientphases SET approved = '1', pending = '0', rejected = '0', actiondate = sysdate, userid = CAST(myval2 as int)
			WHERE clientphaseid = CAST(myval1 as int);
			COMMIT;

			INSERT INTO licensepayments (paymenttypeid,clientlicenseid,amount,userid,productcode,invoicedate,periodid,clientphaseid) 
	  		SELECT 4 ,c2.clientlicenseid ,typeapprovalfee ,CAST(myval2 as int),'D0496E6890104A5F86BB93DDB22793C2',sysdate,c4.periodid,c2.clientphaseid
			FROM clientphases INNER JOIN phases ON phases.phaseid = clientphases.phaseid
    		INNER JOIN clientlicenses ON clientphases.clientlicenseid = clientlicenses.clientlicenseid
			WHERE clientphases.clientphaseid = CAST(myval1 as int) AND (c2.forpayment = '1') AND rc.rccount = 0 ;
    		COMMIT;

		    RETURN 'Received';
		END IF;
    
    

		IF(c2.PAYMENTTYPEID = 1) AND (c2.ISSERVICEPROVIDER =  '1') AND COUNTFEES = 0 AND  c2.paymenttypename = 'Application Fee' THEN
					amnt := c2.applicationfee;
					prtcode := c2.applicationaccount;
				
					INSERT INTO licensepayments (paymenttypeid,clientlicenseid,amount,userid,productcode,invoicedate,periodid,clientphaseid) 
	 				SELECT c2.paymenttypeid ,c2.clientlicenseid ,amnt ,CAST(myval2 as int) ,prtcode,sysdate,c4.periodid,c2.clientphaseid
					FROM clientphases INNER JOIN phases ON phases.phaseid = clientphases.phaseid
					WHERE clientphases.clientphaseid = CAST(myval1 as int) AND (c2.forpayment = '1') AND rc.rccount = 0 ;
    				COMMIT;
			RETURN 'Submitted';
		END IF;



		--TERRESTRIAL
		IF(c2.PAYMENTTYPEID = 2) AND (c2.isterrestrial =  '1') THEN
					
					amnt := c2.applicationfee  + (c2.stationcharge * (c5.trdate / 12)) ;
					prtcode := c2.initialaccount;					
				
					INSERT INTO licensepayments (paymenttypeid,clientlicenseid,amount,userid,productcode,periodid,clientphaseid,details) 
						SELECT c2.paymenttypeid ,c2.clientlicenseid ,amnt ,CAST(myval2 as int) ,prtcode,c4.periodid,c2.clientphaseid,' Amount Includes Kshs 1000 application fee'
						FROM clientphases INNER JOIN phases ON phases.phaseid = clientphases.phaseid
						WHERE clientphases.clientphaseid = CAST(myval1 as int) AND (c2.forpayment = '1') AND rc.rccount = 0 ;
    				COMMIT;

			RETURN 'Submitted';

		END IF;


		--OTHER FSM LICENCES initial fee
		--supposed to sum
		IF(c2.licensetypeid=16 AND c2.PAYMENTTYPEID = 2) THEN
					
					amnt := (c2.stationcharge * (c5.trdate / 12)) ;
					prtcode := c2.initialaccount;					
				
					INSERT INTO licensepayments (paymenttypeid,clientlicenseid,amount,userid,productcode,periodid,clientphaseid,details) 
						SELECT c2.paymenttypeid ,c2.clientlicenseid ,sum(c2.stationcharge * (c5.trdate / 12)) ,CAST(myval2 as int) ,prtcode,c4.periodid,c2.clientphaseid,' Amount Includes Kshs 1000 application fee'
						FROM clientphases INNER JOIN phases ON phases.phaseid = clientphases.phaseid
						WHERE clientphases.clientphaseid = CAST(myval1 as int) AND (c2.forpayment = '1')
						AND clientlicenseid = c2.clientlicenseid;
    				COMMIT;

			RETURN 'Submitted';

		END IF;

		IF(c2.PAYMENTTYPEID = 1) AND (c2.ISSERVICEPROVIDER =  '1') AND COUNTFEES != 0 THEN					
			RETURN 'Submitted';
		END IF;

		IF(c2.PAYMENTTYPEID = 1) THEN
					amnt := c2.applicationfee;
					prtcode := c2.applicationaccount;
		END IF;

		IF (c2.PAYMENTTYPEID = 2) THEN
         	amnt := c2.initialfee  + (c2.annualfee * (c5.trdate / 12)) ;
					prtcode := c2.initialaccount;
		END IF;      

		IF (c2.PAYMENTTYPEID = 3) THEN
					amnt := c2.annualfee;
					prtcode := c2.annualaccount;
		END IF;
		IF (c2.PAYMENTTYPEID = 4) THEN
					amnt := c2.typeapprovalfee;
					prtcode := c2.taaccount;
		END IF;
	
	INSERT INTO licensepayments (paymenttypeid,clientlicenseid,amount,userid,productcode,periodid,clientphaseid) 
	  SELECT c2.paymenttypeid ,c2.clientlicenseid ,amnt ,CAST(myval2 as int) ,prtcode,c4.periodid,c2.clientphaseid
		FROM clientphases INNER JOIN phases ON phases.phaseid = clientphases.phaseid
		WHERE clientphases.clientphaseid = CAST(myval1 as int) AND (c2.forpayment = '1') AND rc.rccount = 0 ;
    COMMIT;
	
	--RETURN 'Please Complete Checklist';  
  RETURN 'EOF';
	CLOSE count_cur;
END;











--fmi
CREATE OR REPLACE FUNCTION fmicorrection(fmi_task_id IN varchar2, user_id IN varchar2, approval IN varchar2, myval4 IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;

	BEGIN

		IF(approval = 'Inspection') THEN
			UPDATE fmitasks set forinspection = '1', forinteference = '0', formonitoring='0' 
			WHERE fmitaskid = CAST(fmi_task_id AS int);
			COMMIT;
		    RETURN 'Correction > Inspection';
		END IF;


		IF(approval = 'Interference') THEN
			UPDATE fmitasks set forinspection = '0', forinteference = '1', formonitoring='0' 
			WHERE fmitaskid = CAST(fmi_task_id AS int);
			COMMIT;
		    RETURN 'Correction > Interference';
		END IF;


		IF(approval = 'Monitoring') THEN
			UPDATE fmitasks set forinspection = '0', forinteference = '0', formonitoring='1' 
			WHERE fmitaskid = CAST(fmi_task_id AS int);
			COMMIT;
		    RETURN 'Correction > Monitoring';
		END IF;

	  COMMIT;

	RETURN 'Unreachable Code';
END;
/




CREATE OR REPLACE FUNCTION lineManagerApproval(cli_phase_id IN varchar2, user_id IN varchar2, approval IN varchar2, phase IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;

	BEGIN
		
	IF(phase = 'manager') THEN
		IF(approval = 'Approve') THEN
			UPDATE clientphases set mgr_approved = '1' WHERE clientphaseid = CAST(cli_phase_id AS int);
			COMMIT;
		    RETURN 'Approved';    
    END IF;    
  ELSIF(phase = 'ad') THEN
		IF(approval = 'Approve') THEN
			UPDATE clientphases set ad_approved = '1' WHERE clientphaseid = CAST(cli_phase_id AS int);
			COMMIT;
		    RETURN 'Approved';
		END IF;
    
   ELSIF(phase = 'dir') THEN
		IF(approval = 'Approve') THEN
			UPDATE clientphases set dir_approved = '1' WHERE clientphaseid = CAST(cli_phase_id AS int);
			COMMIT;
		    RETURN 'Approved';
		END IF;
   ELSIF(phase = 'dg') THEN
		IF(approval = 'Approve') THEN
			UPDATE clientphases set dg_approved = '1' WHERE clientphaseid = CAST(cli_phase_id AS int);
			COMMIT;
		    RETURN 'Approved';
		END IF;  
	END IF;

	RETURN 'Unreachable Code';
  
END;
/




CREATE OR REPLACE FUNCTION lineApproveSchedule(schedule_id IN varchar2, user_id IN varchar2, approval IN varchar2, phase IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;

	BEGIN
		
	IF(phase = 'manager') THEN
		IF(approval = 'Approve') THEN
			UPDATE schedules set isapprovedbymanager = '1' WHERE scheduleid = CAST(schedule_id AS int);
			COMMIT;
		    RETURN 'Approved';    
    END IF;    
    
	ELSIF(phase = 'ad') THEN
		IF(approval = 'Approve') THEN
			UPDATE schedules set isapprovedbyad = '1' WHERE scheduleid = CAST(schedule_id AS int);
			COMMIT;
		    RETURN 'Approved';
		END IF;
    
	ELSIF(phase = 'dir') THEN
		IF(approval = 'Approve') THEN
			UPDATE schedules set isapprovedbyDirector = '1' WHERE scheduleid = CAST(schedule_id AS int);
			COMMIT;
		    RETURN 'Approved';
		END IF;
    
	ELSIF(phase = 'dg') THEN
		IF(approval = 'Approve') THEN
			UPDATE schedules set isapprovedbyDG = '1' WHERE scheduleid = CAST(schedule_id AS int);
			COMMIT;
		    RETURN 'Approved';
		END IF;  
	END IF;

	RETURN 'Unreachable Code';
  
END;
/




--approve fmi phase
create or replace FUNCTION fmiApprovePhase(myval1 IN varchar2, myval2 IN varchar2,myval3 IN varchar2, myval4 IN varchar2) RETURN varchar2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	
	CURSOR phases_cur IS
	SELECT  fmiclientphases.CLIENTAPPLEVEL,fmiclientphases.FMITASKID
	FROM fmiclientphases WHERE  (fmiclientphases.fmiclientphaseid = cast(myval1 as integer));

rd phases_cur%ROWTYPE;

BEGIN

	OPEN phases_cur;
	FETCH phases_cur INTO rd;
  
	IF(myval3 = 'Approved')  THEN
			UPDATE fmiclientphases SET approved = '1', rejected = '0', pending = '0',actiondate = sysdate, userid = CAST(myval2 as int)
			WHERE fmiclientphaseid = CAST(myval1 as int);
			COMMIT;		    
		END IF;

		IF(myval3 = 'Rejected')  THEN
			UPDATE fmiclientphases SET approved = '0', rejected = '1',pending = '0', actiondate = sysdate, userid = CAST(myval2 as int)
			WHERE fmiclientphaseid = CAST(myval1 as int);
			COMMIT;
		    RETURN 'Rejected';
		END IF;
		
		IF(myval3 = 'Review')  THEN
			UPDATE fmiclientphases SET approved = '0', rejected = '0',pending = '0', actiondate = sysdate, userid = CAST(myval2 as int)
			WHERE CLIENTAPPLEVEL = (rd.CLIENTAPPLEVEL - 1 ) AND (fmiclientphases.FMITASKID = rd.FMITASKID);
			COMMIT;
		    RETURN 'Review';
		END IF;

RETURN 'Please Complete Checklist';
END;
 







-- Approve a license qos
CREATE OR REPLACE FUNCTION updApproveqos(myval1 IN varchar2, myval2 IN varchar2,myval3 IN varchar2, myval4 IN varchar2) RETURN varchar2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;

BEGIN
IF(myval3 = 'Complied')  THEN
	UPDATE licensesQos SET   complied = '1', UserID = CAST(myval2 as int),actiondate = SYSDATE
	WHERE licensesqosid = CAST(myval1 as int);
	COMMIT;
	RETURN 'complied';
END IF;

IF(myval3 = 'Not Complied')  THEN
	UPDATE licensesQos SET   complied = '0',  UserID = CAST(myval2 as int),actiondate = SYSDATE
	WHERE licensesqosid = CAST(myval1 as int);
	COMMIT;
	RETURN 'Not Complied';
END IF;
RETURN 'Complete';
END;
/

-- Approve a checklist 
-- updApproveChecklist('67', 'null', 'Select' ,'41')
CREATE OR REPLACE FUNCTION updApproveChecklist(cli_check_id IN varchar2, use_id IN varchar2, approval IN varchar2, filter_id IN varchar2)  RETURN varchar2 IS
	SMT int;
	rsst varchar(120);
	PRAGMA AUTONOMOUS_TRANSACTION;

	CURSOR phases_cur IS
		--SELECT clientphases.clientphaseid,phases.phasename, clientapplevel
		--FROM clientphases 
		--INNER JOIN phases ON clientphases.phaseid = phases.phaseid
		SELECT clientphases.clientphaseid,phases.phasename, clientapplevel, licensetypes.forfsm, licensetypes.forlcs
		FROM clientphases 
		INNER JOIN phases ON clientphases.phaseid = phases.phaseid
		INNER JOIN clientlicenses ON clientphases.clientlicenseid = clientlicenses.clientlicenseid
		INNER JOIN licenses ON clientlicenses.licenseid = licenses.licenseid
		INNER JOIN licensetypes ON licenses.licensetypeid = licensetypes.licensetypeid
		WHERE clientphases.clientphaseid = CAST(filter_id AS int);
		rec_phases phases_cur%ROWTYPE;

BEGIN

	OPEN phases_cur;
	FETCH phases_cur INTO rec_phases;

	IF	(approval='Select' OR approval='Tareceive') THEN
		UPDATE clientchecklists SET approved = '1', rejected = '0', actiondate = SYSDATE, userid = CAST(use_id as int)
			WHERE clientchecklistid = CAST(cli_check_id as int);
			COMMIT;

		SELECT COUNT (clientchecklists.clientchecklistid) INTO smt FROM clientchecklists 
		WHERE  clientphaseid = CAST(filter_id AS int) AND approved = '0' ;

		--IF(myval3 = 'Select') AND (rc.rccount = 0)  THEN
		--	UPDATE clientphases SET approved = '1', rejected = '0', pending = '0',actiondate = sysdate, userid = CAST(myval2 as int)
		--	WHERE clientphaseid = CAST(myval1 as int);
		--	COMMIT;
		--END IF;

		--if there is no checklist left to be filled......
		IF(smt = 0) THEN
				--if its the checking phase just say done (by requesting for review by a licensing officer), approval will be done manually by a licensing officer
				IF(rec_phases.phasename = 'checking' AND rec_phases.forfsm = '1' AND rec_phases.forlcs = '0') THEN
					SELECT ApprovePhase(filter_id, use_id, 'Done', cli_check_id) INTO rsst FROM DUAL;
					RETURN 'Checking will be approved mannualy by licensing officer';
				ELSE
					SELECT ApprovePhase(filter_id, use_id, approval, cli_check_id) INTO rsst FROM DUAL;
				END IF;
		END IF;
	

	IF(approval = 'Review')  THEN
			UPDATE clientphases SET approved = '0', rejected = '0',pending = '0', actiondate = sysdate, userid = CAST(use_id as int)
			WHERE CLIENTAPPLEVEL = (rec_phases.CLIENTAPPLEVEL - 1 ) ;
			COMMIT;
	END IF;

	ELSIF	(approval='Contest') THEN
		UPDATE clientchecklists SET approved = '0', actiondate = SYSDATE, userid = CAST(use_id as int)
			WHERE clientchecklistid = CAST(cli_check_id as int);
			COMMIT;

-- 		SELECT COUNT (clientchecklists.clientchecklistid)  INTO smt FROM clientchecklists 
-- 			WHERE  clientphaseid = CAST(filter_id AS int) AND approved = '0' ;

		SELECT ApprovePhase(filter_id, use_id, 'Return', cli_check_id) INTO rsst FROM DUAL;

		--if there is no checklist left to be filled......
-- 		IF(smt = 0) THEN
-- 				--if its the checking phase just say done (by requesting for review by a licensing officer), approval will be done manually by a licensing officer
-- 				IF(rec_phases.phasename = 'checking') THEN
-- 					SELECT ApprovePhase(filter_id, use_id, 'Done', cli_check_id) INTO rsst FROM DUAL;
-- 					RETURN 'Checking will be approved mannualy by licensing officer';
-- 				ELSE
-- 					SELECT ApprovePhase(filter_id, use_id, approval, cli_check_id) INTO rsst FROM DUAL;
-- 			END IF;
-- 		END IF;
		CLOSE phases_cur;
		RETURN 'Some checklists need reconsideration';

	ELSE		--IF CONFIRMED THEN ITS OK
		CLOSE phases_cur;
		RETURN 'Confirmed OK';
	END IF;

	CLOSE phases_cur;
	RETURN 'Submmited';
END;
/


-- Reject a Form
CREATE OR REPLACE FUNCTION updRejectForm(myval1 IN varchar2, myval2 IN varchar2) RETURN varchar2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	UPDATE clientformtypes SET IsActive = '0', Rejected = '1', RejectedDate = SYSDATE, RejectUserid = CAST(myval1 as int)
	WHERE clientformtypeid = CAST(myval2 as int);
	COMMIT;

	RETURN 'Submmited';
END;
/


-- Approve a License
CREATE OR REPLACE FUNCTION updApproveLicense(myval1 IN varchar2, myval2 IN varchar2) RETURN varchar2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	UPDATE clientlicenses SET IsActive = '1', Rejected = '0', licensedate = SYSDATE, ApproveUserid = CAST(myval1 as int)
	WHERE clientlicenseid = CAST(myval2 as int);
	COMMIT;

	RETURN 'Submmited';
END;
/
-- Reject a License
CREATE OR REPLACE FUNCTION updRejectLicense(myval1 IN varchar2, myval2 IN varchar2) RETURN varchar2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	UPDATE clientlicenses SET IsActive = '0', Rejected = '1', RejectedDate = SYSDATE, RejectUserid = CAST(myval1 as int)
	WHERE clientlicenseid = CAST(myval2 as int);
	COMMIT;

	RETURN 'Submmited';
END;
/

-- Post an invoice from openbravo
CREATE OR REPLACE FUNCTION updateinvoice(myval1 IN varchar2, myval2 IN varchar2, myval3 IN varchar2) RETURN varchar2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	UPDATE licensepayments SET invoicenumber = myval2, invoiceamount = cast(myval3 as real), invoiced = '1'
	WHERE licensepaymentid = CAST(myval1 as int);
	COMMIT;

	RETURN 'Invoiced';
END;
/




CREATE OR REPLACE FUNCTION updatepaid(myval1 IN varchar2, myval2 IN varchar2, myval3 IN varchar2) RETURN varchar2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  IF(myval2 = myval3)  THEN
	UPDATE licensepayments SET  paid = '1'
	WHERE licensepaymentid = CAST(myval1 as int);
	COMMIT;
  END IF;
	RETURN 'Paid';
END;
/


--ADD ACTIVE CLIENTS TO PERIODLICENSES.



--DEADLOCK
-- CREATE OR REPLACE TRIGGER tr_befperiodlicenses BEFORE INSERT  ON  periods 
-- FOR EACH ROW 
-- DECLARE
-- PRAGMA AUTONOMOUS_TRANSACTION;
-- BEGIN
-- 	
-- 	UPDATE periods SET isactive = '0' WHERE periods.periodID != :NEW.periodID;
-- COMMIT;
-- END;
-- /


CREATE OR REPLACE TRIGGER tr_beftac BEFORE INSERT  ON  tac 
FOR EACH ROW 
DECLARE
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	
	UPDATE tac SET active = '0' WHERE tac.tacid != :NEW.tacid;
COMMIT;
END;
/


--DISABLED - ta/*k*/en care of by tr_clc_id
CREATE OR REPLACE TRIGGER tr_befclc BEFORE INSERT  ON  clc 
FOR EACH ROW 
DECLARE
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	
	UPDATE clc SET active = '0' WHERE clc.clcid != :NEW.clcid;
COMMIT;
END;
/

CREATE TRIGGER insproductcode AFTER INSERT ON licensepayments
FOR EACH ROW 
DECLARE
PRAGMA AUTONOMOUS_TRANSACTION;
     CURSOR insproductcode_cur IS 
		SELECT licensepayments.clientlicenseid, licensepayments.paymenttypeid,SYSDATE,
			licenses.applicationaccount,licenses.initialaccount,licenses.annualaccount,licenses.taaccount
		FROM licensepayments INNER JOIN clientlicenses ON clientlicenses.clientlicenseid =licensepayments.clientlicenseid
		INNER JOIN licenses ON licenses.licenseid =clientlicenses.licenseid
		WHERE licensepayments.clientlicenseid = :NEW.clientlicenseid;
      
      rc insproductcode_cur%ROWTYPE;
BEGIN
	OPEN insproductcode_cur;
	FETCH insproductcode_cur INTO rc;

	IF(rc.paymenttypeid = 1)  THEN
		UPDATE licensepayments SET productcode = rc.applicationaccount,posteddate = SYSDATE
		WHERE clientlicenseid = :NEW.clientlicenseid;
   		COMMIT;
	END IF;

	IF(rc.paymenttypeid = 2)  THEN	
		UPDATE licensepayments SET productcode = rc.initialaccount,posteddate = SYSDATE
		WHERE clientlicenseid = :NEW.clientlicenseid;
		COMMIT;
	END IF;

	IF(rc.paymenttypeid = 3)  THEN
		UPDATE licensepayments SET productcode = rc.annualaccount, posteddate = SYSDATE
		WHERE clientlicenseid = :NEW.clientlicenseid;
		COMMIT;
	END IF;

	IF(rc.paymenttypeid = 4)  THEN	
		UPDATE licensepayments SET productcode = rc.taaccount , posteddate = SYSDATE
		WHERE clientlicenseid = :NEW.clientlicenseid;
		COMMIT;
	END IF;
	
END;
/



-- create or replace FUNCTION generateinvoicesOriginal(myval1 IN varchar2, user_id IN varchar2,myval3 IN varchar2, myval4 IN varchar2) RETURN varchar2 IS
-- 
-- 	PRAGMA AUTONOMOUS_TRANSACTION;  
-- 	
-- 	exclusiveamount real;
-- 	inactivemonths int;	--number of months of inactivity
-- 
-- 	CURSOR period_cur IS
-- 		SELECT periodid FROM periods WHERE periods.isactive = '1';
-- 		rec_period period_cur%ROWTYPE;
-- 
-- -- 	CURSOR account_cur IS
-- -- 		SELECT licenseid,applicationaccount,initialaccount,annualaccount FROM licenses;
-- -- 		rec_account account_cur%ROWTYPE;
-- 
-- 	CURSOR clientcharge_cur IS
-- 		SELECT vwclientannualcharge.clientlicenseid, vwclientannualcharge.aggregatecharge, licenses.annualaccount, vwmergedclientlicenses.isexclusiveaccess
-- 		FROM vwclientannualcharge
-- 		INNER JOIN vwmergedclientlicenses ON vwclientannualcharge.clientlicenseid = vwmergedclientlicenses.clientlicenseid
-- 		INNER JOIN licenses on vwmergedclientlicenses.licensename = licenses.licensename
-- 		WHERE vwmergedclientlicenses.isactive = '1'	AND (vwmergedclientlicenses.clientlicenseid NOT IN (
-- 				select coalesce(licensepayments.clientlicenseid,0) 
-- 					from licensepayments
-- 					inner join periods on licensepayments.periodid = periods.periodid
-- 					where periods.isactive='1' and licensepayments.paymenttypeid='3')); --this inner select ensures that we dont invoice more than once for annual periods
-- 		--rec_charge clientcharge_cur%ROWTYPE;
-- 
-- 	--read all violations for previous financial period since invoices are generated annually at the BEGINING of
-- 	CURSOR violations_cur IS
-- 		SELECT licenseviolationid, violationtypeid, clientlicenseid, periods.periodid, isreinstated, actiondate, violationdate
-- 		FROM LICENSEVIOLATIONS
-- 		INNER JOIN periods ON LICENSEVIOLATIONS.periodid = periods.periodid
-- 		WHERE (periods.periodid = (select max(periods.periodid) from periods where periods.isactive = '0')); --the highest inactive period = immediate previous      
-- 		violations_rec violations_cur%ROWTYPE;
-- 
-- BEGIN
-- 
-- 	OPEN period_cur;
--   	FETCH period_cur INTO rec_period;
-- 	
--     --OPEN clientcharge_cur;
--     --FETCH clientcharge_cur INTO rec_charge;	
-- 	
-- 	OPEN violations_cur;
--   	FETCH violations_cur INTO violations_rec;
-- 
-- 	FOR rec_charge IN clientcharge_cur LOOP		
--     
-- 		select exclusiveBWannualcharge(rec_charge.clientlicenseid) into exclusiveamount from dual;
--     
-- 		--if exclusive bw then insert a separate order/line for exclusive nationwide assignment
-- 		if(rec_charge.isexclusiveaccess='1')then      
-- 			INSERT INTO licensepayments (paymenttypeid, clientlicenseid, amount,userid,productcode,periodid,details) 
-- 			VALUES(3,rec_charge.clientlicenseid, exclusiveamount, CAST(user_id as int),rec_charge.annualaccount,rec_period.periodid,'Exclusive BW assignment fee');      
-- 			COMMIT;			
-- 		end if;
-- 
-- 		INSERT INTO licensepayments (paymenttypeid, clientlicenseid, amount,userid,productcode,periodid) 
-- 			VALUES(3,rec_charge.clientlicenseid, rec_charge.aggregatecharge, CAST(user_id as int),rec_charge.annualaccount,rec_period.periodid);
-- 			COMMIT;
-- 
-- 		--insert inactivity (if previously cancelled/suspended) line with -ve amount to offset the annual fee
-- 		--WE LOOP thru the cursor to search for matching entries
-- 		FOR violations_rec IN violations_cur LOOP
-- 			IF (rec_charge.clientlicenseid = violations_rec.clientlicenseid ) THEN
-- 				--get number of months between cancel action date and now
-- 				SELECT MONTHS_BETWEEN(violations_rec.violationdate, SYSDATE) INTO inactivemonths FROM dual;
-- 				--use this to get the fraction of the annual amount
-- 				INSERT INTO licensepayments (paymenttypeid, clientlicenseid, amount, userid, productcode, periodid, details) 
-- 				VALUES(7,rec_charge.clientlicenseid, ((rec_charge.aggregatecharge/inactivemonths) * -1), CAST(user_id as int),rec_charge.annualaccount,rec_period.periodid,'Credit for Inactivity');
-- 				COMMIT;
-- 
-- 			END IF;
-- 		END LOOP;
-- 
-- 	END LOOP;    
-- 		
-- 	CLOSE period_cur;
-- 	--CLOSE clientcharge_cur;
-- 
-- 	RETURN 'Annual Orders Sent Successfully';
-- 
-- END;
-- 
-- 

--this REPLACES generateinvoices (Original). Generates invoices per licenses
create or replace FUNCTION generatelicenseinvoices(lic_id IN varchar2, user_id IN varchar2, approval IN varchar2, period_id IN varchar2) RETURN varchar2 IS

	PRAGMA AUTONOMOUS_TRANSACTION;  
	
	exclusiveamount real;
	inactivemonths int;	--number of months of inactivity

	CURSOR period_cur IS
		SELECT periodid FROM periods WHERE periods.periodid = cast(period_id as int);
		rec_period period_cur%ROWTYPE;

-- 	CURSOR account_cur IS
-- 		SELECT licenseid,applicationaccount,initialaccount,annualaccount FROM licenses;
-- 		rec_account account_cur%ROWTYPE;

	CURSOR clientcharge_cur IS
		SELECT vwclientannualcharge.clientlicenseid, vwclientannualcharge.aggregatecharge, licenses.annualaccount, vwmergedclientlicenses.isexclusiveaccess
		FROM vwclientannualcharge
		INNER JOIN vwmergedclientlicenses ON vwclientannualcharge.clientlicenseid = vwmergedclientlicenses.clientlicenseid
		INNER JOIN licenses on vwmergedclientlicenses.licensename = licenses.licensename
		WHERE licenses.licenseid = cast(lic_id as int) AND vwmergedclientlicenses.isactive = '1' AND (vwmergedclientlicenses.clientlicenseid NOT IN (
				select coalesce(licensepayments.clientlicenseid,0) 
					from licensepayments
					inner join periods on licensepayments.periodid = periods.periodid
					where periods.periodid = cast(period_id as int) and licensepayments.paymenttypeid='3')); --this inner select ensures that we dont invoice more than once for annual periods
		--rec_charge clientcharge_cur%ROWTYPE;

	--read all violations for previous financial period since invoices are generated annually at the BEGINING of
	CURSOR violations_cur IS
		SELECT licenseviolationid, violationtypeid, clientlicenseid, periods.periodid, isreinstated, actiondate, violationdate
		FROM LICENSEVIOLATIONS
		INNER JOIN periods ON LICENSEVIOLATIONS.periodid = periods.periodid
		WHERE (periods.periodid = (select max(periods.periodid) from periods where periods.isactive = '0')); --the highest inactive period = immediate previous      
		violations_rec violations_cur%ROWTYPE;

BEGIN

	OPEN period_cur;
  	FETCH period_cur INTO rec_period;
	
    --OPEN clientcharge_cur;
    --FETCH clientcharge_cur INTO rec_charge;	
	
	--OPEN violations_cur;
  	--FETCH violations_cur INTO violations_rec;

	FOR rec_charge IN clientcharge_cur LOOP		
    
		--select exclusiveBWannualcharge(rec_charge.clientlicenseid) into exclusiveamount from dual;
    
		--if exclusive bw then insert a separate order/line for exclusive nationwide assignment
		if(rec_charge.isexclusiveaccess='1')then      

			select exclusiveBWannualcharge(rec_charge.clientlicenseid) into exclusiveamount from dual;

			INSERT INTO licensepayments (paymenttypeid, clientlicenseid, amount,userid,productcode,periodid,details) 
			VALUES(3,rec_charge.clientlicenseid, exclusiveamount, CAST(user_id as int),rec_charge.annualaccount,rec_period.periodid,'Exclusive BW assignment fee');      
			COMMIT;			
		end if;


		
		--if clientlicenseid,productcode,periodid do not already exist ie not ordered already
    
    --UNCONDITIONAL INSERT - WORKING OK
    --INSERT INTO licensepayments (paymenttypeid, clientlicenseid, amount,userid,productcode,periodid) 
			--VALUES(3,rec_charge.clientlicenseid, rec_charge.aggregatecharge, CAST(user_id as int),rec_charge.annualaccount,rec_period.periodid)
			--COMMIT;
    
    --CONDITIONAL INSERT
		INSERT INTO licensepayments (paymenttypeid, clientlicenseid, amount,userid,productcode,periodid) 
			SELECT 3, rec_charge.clientlicenseid, rec_charge.aggregatecharge, CAST(user_id as int),rec_charge.annualaccount,rec_period.periodid
      FROM DUAL
			WHERE NOT EXISTS (select 1 from licensepayments where clientlicenseid = rec_charge.clientlicenseid and periodid = rec_period.periodid);
			COMMIT;
		

		--insert inactivity (if previously cancelled/suspended) line with -ve amount to offset the annual fee
		--WE LOOP thru the cursor to search for matching entries
		FOR violations_rec IN violations_cur LOOP
			IF (rec_charge.clientlicenseid = violations_rec.clientlicenseid ) THEN
				--get number of months between cancel action date and now
				SELECT MONTHS_BETWEEN(violations_rec.violationdate, SYSDATE) INTO inactivemonths FROM dual;
				--use this to get the fraction of the annual amount
				--INSERT INTO licensepayments (paymenttypeid, clientlicenseid, amount, userid, productcode, periodid, details) 
				--VALUES(7,rec_charge.clientlicenseid, ((rec_charge.aggregatecharge/inactivemonths) * -1), CAST(user_id as int),rec_charge.annualaccount,rec_period.periodid,'Credit for Inactivity');
				--COMMIT;

			END IF;
		END LOOP;

	END LOOP;    
		
	CLOSE period_cur;
	--CLOSE violations_cur;
	--CLOSE clientcharge_cur;

	RETURN 'License Invoiced Successfully';

END;

--remove an unpaid renewal order for a particular application/license
create or replace FUNCTION removelicenseorder(cli_lic_id IN varchar2, user_id IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN varchar2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	
BEGIN

	delete from licensepayments where paid='0' and periodid = cast(filter_id as int) and clientlicenseid = cast(cli_lic_id as int);
	COMMIT;
	
	RETURN 'Order Removed. For Client License ' || cli_lic_id;

END;
/


create or replace FUNCTION exclusiveaccess(cli_lic_id IN varchar2, user_id IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN varchar2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	
BEGIN

	if(approval='Exclusive')then
		UPDATE clientlicenses set ISEXCLUSIVEACCESS = '1' where clientlicenseid = cast(cli_lic_id as int);
		COMMIT;
	elsif(approval='Not Exclusive') then
		UPDATE clientlicenses set ISEXCLUSIVEACCESS = '0' where clientlicenseid = cast(cli_lic_id as int);
		COMMIT;
	end if;
	
	RETURN 'Successful';

END;
/




CREATE OR REPLACE FUNCTION updEscalation(myval1 IN varchar2) RETURN varchar2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  UPDATE licensepayments SET emailed = '1'
		WHERE (licensepaymentid = CAST (myval1 AS INTEGER));
    COMMIT;

	RETURN 'Submmited';
END;
/

-- This function should be part of the erp database not the crm
CREATE OR REPLACE FUNCTION orderpost(myval1 IN varchar2) RETURN varchar2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
 c_order_post(myval1);
 RETURN 'submitted';
END;
/


CREATE OR REPLACE FUNCTION completeschedule(myval1 IN varchar2, myval2 IN varchar2, myval3 IN varchar2, myval4 IN varchar2) RETURN VARCHAR2 IS
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN

	UPDATE schedules SET  complete = '1' , UserID = CAST(myval2 as int) WHERE scheduleID = CAST(myval1 as int);
COMMIT;
	RETURN 'complete';
END;
/



CREATE OR REPLACE FUNCTION revokeassignment(channel_id IN varchar2, use_id IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	
  BEGIN	
  
    IF(approval = 'Revoke') THEN
      DELETE FROM frequencys 
      WHERE channelid = cast(channel_id as int) AND stationid = cast(filter_id as int);
      COMMIT;
      RETURN 'Revoked';
    END IF;

	--RETURN 'Unreachable';
	END;
/


CREATE OR REPLACE FUNCTION completefmischedule(fmischedule_id IN varchar2, myval2 IN varchar2, myval3 IN varchar2, myval4 IN varchar2) RETURN VARCHAR2 IS
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN

	UPDATE fmischedule SET   iscomplete = '1' WHERE fmischeduleid = CAST(fmischedule_id as int);
COMMIT;
	RETURN 'Scheduled';
END;
/




CREATE OR REPLACE FUNCTION ad_approvefmischedule(fmischedule_id IN varchar2, myval2 IN varchar2, myval3 IN varchar2, myval4 IN varchar2) RETURN VARCHAR2 IS
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN

	UPDATE fmischedule SET   ad_approved = '1' WHERE fmischeduleid = CAST(fmischedule_id as int);
COMMIT;
	RETURN 'Scheduled';
END;
/


CREATE OR REPLACE FUNCTION d_approvefmischedule(fmischedule_id IN varchar2, myval2 IN varchar2, myval3 IN varchar2, myval4 IN varchar2) RETURN VARCHAR2 IS
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN

	UPDATE fmischedule SET  d_approved = '1' WHERE fmischeduleid = CAST(fmischedule_id as int);
COMMIT;
	RETURN 'Scheduled';
END;
/

CREATE OR REPLACE FUNCTION dg_approvefmischedule(fmischedule_id IN varchar2, myval2 IN varchar2, myval3 IN varchar2, myval4 IN varchar2) RETURN VARCHAR2 IS
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN

	UPDATE fmischedule SET   dg_approved = '1' WHERE fmischeduleid = CAST(fmischedule_id as int);
COMMIT;
	RETURN 'Scheduled';
END;
/

CREATE OR REPLACE FUNCTION Approveschedule(myval1 IN varchar2, myval2 IN varchar2, myval3 IN varchar2, myval4 IN varchar2) RETURN VARCHAR2 IS
PRAGMA AUTONOMOUS_TRANSACTION;
  
BEGIN
		
	  IF(myval3 = 'Approve')   THEN
			UPDATE clientphases SET approved = '1', rejected = '0', pending = '0',actiondate = sysdate, userid = CAST(myval2 as int)
			WHERE clientphaseid = CAST(myval1 as int);
			COMMIT;
	END IF;
  
	IF(myval3 = 'Reject')   THEN
			UPDATE clientphases SET approved = '0', rejected = '1', pending = '0',actiondate = sysdate, userid = CAST(myval2 as int)
			WHERE clientphaseid = CAST(myval1 as int);
			COMMIT;
	END IF;
  RETURN 'complete';
END;
/


CREATE OR REPLACE TRIGGER tr_updclientqos AFTER INSERT ON periodlicenses
   FOR EACH ROW
DECLARE
     CURSOR c1 IS
      select licenseid from vwclientlicenses where vwclientlicenses.clientlicenseid = :NEW.clientlicenseid;
	  rc c1%ROWTYPE;
BEGIN
	OPEN c1;
	FETCH c1 INTO rc;
	INSERT INTO complconditionsappvl (periodlicenseid, complianceconditionid,narrative)
	SELECT :NEW.periodlicenseid, complianceconditionid, narrative
	FROM complianceconditions WHERE complianceconditions.licenseID = rc.licenseid;
    
	INSERT INTO licensecompliance(periodlicenseid) 
	VALUES (:NEW.periodlicenseid);

	IF (rc.licenseid = 24) THEN
	INSERT INTO licensesqos(periodlicenseid,qosname,target) 
	SELECT :NEW.periodlicenseid,qosname,target
	FROM qosfactors;
	END IF;

	--conditional insert
	-- INSERT
-- 		WHEN ([Condition]) THEN
-- 		INTO [TableName] ([ColumnName])
-- 		VALUES ([VALUES])
-- 		ELSE
-- 		INTO [TableName] ([ColumnName])
-- 		VALUES ([VALUES])
-- 		SELECT [ColumnName] FROM [TableName];

END;
/

CREATE OR REPLACE TRIGGER tr_updcompliancephases AFTER INSERT ON clientcompliance
   FOR EACH ROW 
DECLARE
BEGIN
	INSERT INTO penalties (clientcomplianceid, EscalationTime,delaytime, userid,clientphasename,clientapplevel,usergroupid)	
	SELECT :NEW.clientcomplianceid, EscalationTime, delaytime, '0',phasename,phaselevel,usergroupid
	FROM compliancephases;

END;
/


--Arguments: 1=keyfield, 2=logged in user, 3=approvals, 4=filterid if any
CREATE OR REPLACE FUNCTION conditionscompliance(myval1 IN varchar2, myval2 IN varchar2, myval3 IN varchar2, myval4 IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;	
	DECLARE
		count_non_complied		int;
		period_lic_id			int;
	BEGIN

	SELECT periodlicenseid INTO period_lic_id FROM complconditionsappvl WHERE complconditionsappvlid = CAST(myval1 as int);
		
	 IF(myval3 = 'Complied')  THEN
			UPDATE complconditionsappvl SET complied = '1', notcomplied ='0'
			WHERE complconditionsappvlid = CAST(myval1 as int);
			COMMIT;			

			--RETURN 'Complied';
	END IF;
	 IF(myval3 = 'Not Complied')  THEN
			UPDATE complconditionsappvl SET notcomplied = '1', complied ='0'
			WHERE complconditionsappvlid = CAST(myval1 as int);
			COMMIT;
			--RETURN 'Not Complied';
	END IF;

	--finaly check for the overal status
	SELECT count(complconditionsappvlid) INTO count_non_complied FROM complconditionsappvl 
		WHERE periodlicenseid = period_lic_id AND notcomplied='1';

	IF count_non_complied = 0 THEN
		UPDATE periodlicenses SET CONDITIONSCOMPLIANT = '1' WHERE periodlicenseid = period_lic_id;
		COMMIT;
	ELSE
		UPDATE periodlicenses SET CONDITIONSCOMPLIANT = '0' WHERE periodlicenseid = period_lic_id;
		COMMIT;
	END IF;

	RETURN 'Unreachable';
 COMMIT;
END;
/

CREATE OR REPLACE FUNCTION forcontravention(myval1 IN varchar2, myval2 IN varchar2, myval3 IN varchar2, myval4 IN varchar2) RETURN VARCHAR2 IS
PRAGMA AUTONOMOUS_TRANSACTION;
  
BEGIN
		
	  IF(myval3 = 'Select')   THEN
			UPDATE penalties SET approved = '1', rejected = '0',actiondate = sysdate, userid = CAST(myval2 as int)
			WHERE penaltyid = CAST(myval1 as int);
			COMMIT;
	END IF;
  
	IF(myval3 = 'Remove')   THEN
			UPDATE penalties SET approved = '0', rejected = '1', actiondate = sysdate, userid = CAST(myval2 as int)
			WHERE penaltyid = CAST(myval1 as int);
			COMMIT;
	END IF;
  RETURN 'complete';
END;
/


-- station prices
CREATE OR REPLACE FUNCTION updClientStations(myval1 IN integer) RETURN varchar2 IS
	tprice real;
	fprice real;
	
	CURSOR licenseprices_cur IS
		SELECT licenseprices.licensepriceid, licenseprices.licenseid, licenseprices.stationclassid, 
			licenseprices.typename, licenseprices.amount, licenseprices.unitgroups, licenseprices.onetimefee, 
			licenseprices.perlicense, licenseprices.perstation, licenseprices.perfrequency, 
			licenseprices.functname, licenseprices.formula,
			ClientStations.ClientStationid, ClientStations.ClientLicenseid, ClientStations.numberofrequestedstations,
			ClientStations.numberofapprovedstations, ClientStations.numberfrequencies
		FROM licenseprices INNER JOIN ClientStations ON licenseprices.licensepriceid = ClientStations.licensepriceid
		WHERE (ClientStationid = myval1);
		rc licenseprices_cur%ROWTYPE;

		--PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN

	OPEN licenseprices_cur;
	FETCH licenseprices_cur INTO rc;

	IF (rc.perstation = '1') THEN
		tprice := rc.amount * rc.numberofrequestedstations;
		fprice := rc.amount * rc.numberofapprovedstations;
	END IF;

	UPDATE ClientStations SET tentativeprice = tprice, finalprice = fprice
	WHERE ClientStationid = myval1;
	COMMIT;

	RETURN 'complied';
END;
/


CREATE OR REPLACE FUNCTION taapprovePhase(myval1 IN varchar2, myval2 IN varchar2, myval3 IN varchar2, myval4 IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;

	BEGIN

	IF(myval3 = 'Type Approved') THEN
		UPDATE clientphases SET approved = '1', rejected = '0', pending = '0',actiondate = sysdate, userid = CAST(myval2 as int)
      WHERE clientphaseid = CAST(myval4 as int);

		INSERT INTO equipments  (equipmenttypeid, make, model,suppliername) 
			SELECT equipmenttypeid, make, model,suppliername FROM equipmentapprovals
			WHERE  equipmentapprovalid = CAST(myval1 as int);

		UPDATE equipmentapprovals SET approved = '1', rejected = '0' 
      WHERE equipmentapprovalid = CAST(myval1 as int);

	COMMIT;
	RETURN 'Selected';
	END IF;

	IF(myval3 = 'Rejected') THEN
		UPDATE clientphases SET approved = '0', rejected = '1', pending = '0',actiondate = sysdate, userid = CAST(myval2 as int)
      WHERE clientphaseid = CAST(myval4 as int);
		
		UPDATE equipmentapprovals SET approved = '0', rejected = '1' 
      WHERE equipmentapprovalid = CAST(myval1 as int);

	COMMIT;
	RETURN 'Rejected';
	END IF;

	IF(myval3 = 'Pending') THEN
		UPDATE clientphases SET approved = '0', rejected = '0', pending = '1',actiondate = sysdate, userid = CAST(myval2 as int)
      WHERE clientphaseid = CAST(myval4 as int);
		
		UPDATE equipmentapprovals SET approved = '0', rejected = '1' 
      WHERE equipmentapprovalid = CAST(myval1 as int);

	COMMIT;
	RETURN 'Pending';
	END IF;

	RETURN 'Correct Entry';
END;
/

-- SELECT c_invoice.c_order_id, c_invoice.c_invoice_id, c_invoice.totallines,c_debt_payment.amount FROM c_invoice 
-- inner join c_debt_payment on c_debt_payment.c_invoice_id = c_invoice.c_invoice_id
-- where c_invoice.c_order_id = '121'

-- insert into clientcategorys (clientcategoryname) select upper(legalentity) from tempclients group by upper(legalentity) ;
-- update  tempclients set  town = 'N/A' WHERE town is null;
-- update  tempclients set  town = 'N/A' WHERE town is null;
-- update  tempclients set  CLASSIFICATION = 'N/A' WHERE CLASSIFICATION is null;
-- update  tempclients set  LEGALENTITY = 'N/A' WHERE LEGALENTITY is null;
-- update  tempclients set  pinno = 'N/A' WHERE pinno is null;


-- insert into clientcontact(contactname, clientid, contactdesigntaion)
-- select  DISTINCT tempclients.contactname, clients.clientid, tempclients.designation  from tempclients inner join clients on 
-- clients.accountscode = tempclients.accountcode;


-- insert into clients (ACCOUNTSCODE,CLIENTNAME,PIN,ADDRESS,POSTALCODE, town, street, premises, buildingfloor, lrnumber, telno,
--  fax,email,website,clientcategoryid,CLIENTTYPEID, idnumber)
-- select DISTINCT accountcode,CLIENTNAME,PINNO,ADDRESS,POSTCODE,TOWN,STREET,BUILDING, FLOOR,LRNO,TELEPHONE,
-- FAX,EMAIL,WEBSITE,CLIENTCATEGORYID,CLIENTTYPEID,'0'  from tempclients 
-- inner join clientcategorys on  upper(clientcategorys.clientcategoryname) = upper(tempclients.LEGALENTITY)
-- inner join clienttypes on  upper(clienttypes.clienttypename) = upper(tempclients.classification);

-- run this for the ERP

-- For selecting data from clients temporary table into the other tables
-- SELECT *
-- FROM clientstemp
-- WHERE clienttempid IN (
-- SELECT max(clienttempid)
-- FROM clientstemp 
-- GROUP BY trim(upper(companyname)));




--wip for entering annual fees


--function to generate channels
create or replace FUNCTION generatechannelization(ch_plan_id in varchar, subband in varchar, itu in varchar, stt in varchar, stp in varchar, duplex in varchar, separation in varchar) RETURN VARCHAR is
  --DECLARE
  
  PRAGMA AUTONOMOUS_TRANSACTION;  
  
  channelno integer;
  nextchannel real;
  upperbound real;

begin
		
  if (subband is null or stt is null or stp is null or duplex is null or separation  is null) then
    raise_application_error(-20002,'Subband Name, Start n Stop Frequency, Duplex spacing and Channel separation are all required');
    --return null;
  end if;

  --linear series CHn = CH1 + (n-1)d
  
  channelno := 1;
  nextchannel := stt;		--stt is the start
  upperbound := 0;
  
  WHILE (upperbound <= stp) LOOP  --do while the next channel is within boundary
  
    --if(appnd = '0')then
      --delete from channelTest where channelplanid = ch_plan_id;    
      --commit;
    --end if;
    
    insert into channel(channelid, subbandname, channelplanid, subbanddescription,subbandannex, itu_reference, channelnumber, transmit, receive, channelspacing, duplexspacing)     
    values(null,subband,ch_plan_id,null, null,itu,channelno, nextchannel, nextchannel + duplex, cast(separation as real), cast(duplex as real));
    commit;
    
    nextchannel := nextchannel + cast(separation as real);
    upperbound := nextchannel + cast(duplex as real);
    channelno := channelno + 1;
    
  END LOOP;
  
  RETURN 'Generated';  

--EXCEPTION
--	WHEN OTHERS THEN
--    raise_application_error(-20002,'Subband Name, Start n Stop Frequency, Duplex spacing and Channel separation are all required');
--		RETURN 'Not Generated';

end;
/




--DATABASE LINK FROM LIVE ORACLE DB TO OPENBRAVO ORACLE DB
CREATE DATABASE LINK erplink
   	CONNECT TO openbr IDENTIFIED BY Imis2goke    
   	 USING '172.100.3.22:1530/imiserp';


--map erp business partner to fsm client (one to one)
CREATE VIEW map_bpartner2client AS
	SELECT clients.clientid, clients.clientname, bp.c_bpartner_id, bp.name
	FROM clients
	INNER JOIN C_BPARTNER@erplink bp ON clients.clientname = bp.name






--CONFIGURE ORACLE EMAIL HANDLING PACKAGE
--1. install (how??cant remember)
@$ORACLE_HOME/rdbms/admin/utlmail.sql
@$ORACLE_HOME/rdbms/admin/prvtmail.plb 

--2. Grant permissions for sending email
GRANT execute ON utl_mail TO PUBLIC; 

--3. Define mail server to be used
alter system set smtp_out_server = '172.100.3.12:25' scope=both;






--EMAIL WITHOUT ATTACHMENTS
create or replace FUNCTION sendMailNA(recepts IN varchar, user_id IN INTEGER, sub IN varchar, msg IN VARCHAR2) RETURN varchar IS
		
    PRAGMA AUTONOMOUS_TRANSACTION;
    myret varchar(50);
    sendcc char(1);
    
    pos_at int;
    pos_dot int;    

	--we want to know the logged in user who initiated this event
	CURSOR user_cur IS
		SELECT userid, fullname, email, telno FROM users WHERE userid = user_id;
		rec_user user_cur%ROWTYPE;
BEGIN
	--initialize
	sendcc := '1';

	OPEN user_cur;
	FETCH user_cur INTO rec_user;

	--validate (simple) email address before sending
	if(rec_user.email is NULL)then	        
		sendcc := '0';	
	elsif(rec_user.email='')then			
		sendcc := '0';	
	elsif(pos_at=0 or pos_dot=0)then	--if there is no '@' or at least one '.' in the email address
		sendcc := '0';	
	end if;

	IF(sendcc = '0')THEN
		--EXECUTE IMMEDIATE 'ALTER SESSION SET smtp_out_server = '172.100.3.12:25';
		UTL_MAIL.send(sender => 'imisadmin@cck.go.ke',        --to confirm that this email is from imis
				recipients => recepts,                      --client (including)
						--cc => 'ibrahim.itambo@gmail.com',   --copy to relevant officer
					--bcc => 'iitambo@dewcis.com',          --bind cc to relevant director
				subject => sub,
				message => msg,
				mime_type => 'text; charset=us-ascii');
	ELSIF(sendcc = '1')THEN
		--EXECUTE IMMEDIATE 'ALTER SESSION SET smtp_out_server = '172.100.3.12:25';
		UTL_MAIL.send(sender => 'imisadmin@cck.go.ke',        --to confirm that this email is from imis
				  recipients => recepts,                      --client (including)
					      cc => rec_user.email,   			--copy to relevant officer
					   --bcc => 'iitambo@dewcis.com',          --bind cc to relevant director
					 subject => sub,
					 message => msg,
				   mime_type => 'text; charset=us-ascii');
	END IF;			
	
	RETURN 'Email has been sent ';

END;
/


--database uptime log table
CREATE TABLE uptime_log (
        database_name       VARCHAR2(30),
        event_name          VARCHAR2(20),
        event_time          DATE,
        triggered_by_user   VARCHAR2(30)
    );

--record all system shutdown events
CREATE OR REPLACE TRIGGER log_shutdown BEFORE SHUTDOWN ON DATABASE
    BEGIN
        INSERT INTO uptime_log
            (database_name,
             event_name,
             event_time,
             triggered_by_user)
            VALUES (sys.database_name,
                   sys.sysevent,
                   sysdate,
                   sys.login_user);
       COMMIT;
   END;
   /
--EMAIL WITH ATTACHMENTS
-- CREATE OR REPLACE FUNCTION sendMailAtt(recepts IN varchar, user_id IN INTEGER, sub IN varchar, msg IN VARCHAR2,file in VARCHAR) RETURN varchar IS
-- 	myret varchar(50);
-- 	PRAGMA AUTONOMOUS_TRANSACTION;
-- BEGIN
--   --EXECUTE IMMEDIATE 'ALTER SESSION SET smtp_out_server = '172.100.3.12:25';
--   UTL_MAIL.send(sender => 'imisadmin@cck.go.ke',        --to confirm that this email is from imis
--             recipients => recepts,                      --client (including)
--                   --cc => 'ibrahim.itambo@gmail.com',   --copy to relevant officer
--                  --bcc => 'iitambo@dewcis.com',          --bind cc to relevant director
--                subject => sub,
--                message => msg,
--              mime_type => 'text; charset=us-ascii'
-- 			  priority => 1,
-- 			attachment
-- 			att_inline => true,
-- 			att_mime_type=>'application/octet',
-- 		att_filename = >'/root/Desktop/javaconsole.txt'
-- 
-- 			);
--              
-- RETURN 'Email has been sent to ' || user_id;
-- END;
-- /






CREATE OR REPLACE FUNCTION sendMailSimplestNeverFailed(recepts IN varchar, user_id IN INTEGER, sub IN varchar, msg IN VARCHAR2) RETURN varchar IS
	myret varchar(50);
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  --EXECUTE IMMEDIATE 'ALTER SESSION SET smtp_out_server = '172.100.3.12:25';
  UTL_MAIL.send(sender => 'imisadmin@cck.go.ke',        --to confirm that this email is from imis
            recipients => recepts,                      --client (including)
                    --cc => 'ibrahim.itambo@gmail.com',   --copy to relevant officer
                  --bcc => 'iitambo@dewcis.com',          --bind cc to relevant director
               subject => sub,
               message => msg,
             mime_type => 'text; charset=us-ascii');
             
RETURN 'Email has been sent to ' || user_id;
END;
/


CREATE TABLE applets(
	appletid integer primary key,
	appletname	varchar(50),
	appletcode	varchar(500),
	details		clob
	);


CREATE TABLE freqapplet(
	freqappletid integer primary key,
	appletname	varchar(50),
	appletcode	varchar(500),
	details		clob
	);

--IRIS 
--CLIENTS
CREATE TABLE TEMP_SMS_USERS
   (	
	"USE_ID" VARCHAR2(50 BYTE), 
	"USE_STATUS" VARCHAR2(2 BYTE), 
	"USE_NAME" VARCHAR2(100 BYTE), 
	"USE_IDENT" VARCHAR2(50 BYTE), 
	"USE_ITU_AGENCY_ID" VARCHAR2(50 BYTE), 
	"USE_REPRESENT" VARCHAR2(50 BYTE), 
	"USE_TYPE" VARCHAR2(50 BYTE), 
	"USE_CATEGORY" VARCHAR2(50 BYTE), 
	"USE_ADDRESS" VARCHAR2(100 BYTE), 
	"USE_POSTCODE" VARCHAR2(10 BYTE), 
	"USE_CITY" VARCHAR2(50 BYTE), 
	"USE_PROVINCE" VARCHAR2(50 BYTE), 
	"USE_COUNTRY_ID" VARCHAR2(50 BYTE), 
	"USE_EMAIL" VARCHAR2(50 BYTE), 
	"USE_EMAIL2" VARCHAR2(50 BYTE), 
	"USE_FEE" VARCHAR2(50 BYTE), 
	"USE_REMARK1" VARCHAR2(50 BYTE), 
	"USE_MAIL_NAME" VARCHAR2(50 BYTE), 
	"USE_MAIL_ADDRESS" VARCHAR2(100 BYTE), 
	"USE_MAIL_POSTCODE" VARCHAR2(10 BYTE), 
	"USE_MAIL_CITY" VARCHAR2(9 BYTE), 
	"USE_MAIL_PROVINCE" VARCHAR2(9 BYTE), 
	"USE_MAIL_COUNTRY_ID" VARCHAR2(3 BYTE), 
	"USE_MAIL_TEL" VARCHAR2(20 BYTE), 
	"USE_MAIL_FAX" VARCHAR2(20 BYTE), 
	"USE_MAIL_EMAIL" VARCHAR2(50 BYTE), 
	"USE_MAIL_EMAIL2" VARCHAR2(50 BYTE), 
	"USE_REMARK2" VARCHAR2(2000 BYTE), 
	"USE_IMAGE" VARCHAR2(100 BYTE), 
	"LAST_UPD_TIME" VARCHAR2(50 BYTE), 
	"TARIFF_CODE" VARCHAR2(50 BYTE), 
	"SERVER_SITE" VARCHAR2(50 BYTE), 
	"APPROVED_DATE" VARCHAR2(50 BYTE), 
	"USE_SUB_CAT" VARCHAR2(50 BYTE), 
	"USE_BILLING_ADDRESS" VARCHAR2(100 BYTE), 
	"USE_BILLING_POSTCODE" VARCHAR2(10 BYTE), 
	"USE_BILLING_CITY" VARCHAR2(50 BYTE), 
	"USE_BILLING_PROVINCE" VARCHAR2(50 BYTE), 
	"USE_BILLING_COUNTRY_ID" VARCHAR2(50 BYTE), 
	"USE_BANK" VARCHAR2(50 BYTE), 
	"USE_ACCOUNT" VARCHAR2(100 BYTE), 		--column wont import
	"USE_BRANCH" VARCHAR2(50 BYTE), 
	"USE_IDENT2" VARCHAR2(50 BYTE), 
	"USE_BIRTH_DATE" VARCHAR2(50 BYTE), 
	"USE_BIRTH_LOCATION" VARCHAR2(100 BYTE), 
	"USE_NATIONALITY" VARCHAR2(100 BYTE), 
	"USE_IDENT1_TYPE" VARCHAR2(50 BYTE), 
	"USE_IDENT2_TYPE" VARCHAR2(50 BYTE), 
	"USE_EXAM_CLASS" VARCHAR2(50 BYTE), 
	"USE_ROM_CLASS" VARCHAR2(50 BYTE), 
	"USE_CEPT_CLASS" VARCHAR2(50 BYTE), 
	"USE_REGION" VARCHAR2(50 BYTE), 
	"USE_INFO1" VARCHAR2(100 BYTE), 
	"USE_INFO2" VARCHAR2(100 BYTE), 
	"USE_INFO3" VARCHAR2(100 BYTE), 
	"USE_START_DATE" VARCHAR2(50 BYTE)			--column wont import
	);




CREATE TABLE TEMP_SMS_NETWORK(
	NET_ID				VARCHAR2(50 BYTE),
	NET_NAME			VARCHAR2(50 BYTE),
	NET_OPER_TYPE	VARCHAR2(50 BYTE),
	NET_LOCATION	VARCHAR2(50 BYTE),
	NET_CAPITAL		VARCHAR2(50 BYTE),
	NET_CHANNEL		VARCHAR2(50 BYTE),
	NET_EXTRA_CHANNEL		VARCHAR2(50 BYTE),
	NET_OWNER_ID		VARCHAR2(50 BYTE),		--FK TO SMS_USERS
	LAST_UPD_TIME		VARCHAR2(50 BYTE),
	SERVER_SITE		VARCHAR2(50 BYTE),
	STATUS		VARCHAR2(50 BYTE),
	APPROVED_DATE		VARCHAR2(50 BYTE),	--column wont import
	TARIFF_CODE		VARCHAR2(50 BYTE),
	NET_LIC_ID		VARCHAR2(50 BYTE),
	NET_REMARK		VARCHAR2(50 BYTE),		--column wont import
	NET_FREQ		VARCHAR2(50 BYTE),
	NET_FREQ_TYPE	VARCHAR2(50 BYTE),		
	NET_FREQ_FROM	VARCHAR2(50 BYTE),		--column wont import
	NET_FREQ_TO		VARCHAR2(50 BYTE),		--column wont import
	NET_BANDWIDTH	VARCHAR2(50 BYTE)		--column wont import
	);

--CLIENT LICENSE
CREATE TABLE TEMP_SMS_LICENSE(
 	"LIC_ID" VARCHAR2(50),
	"LIC_OWNER_ID" VARCHAR2(50),		--FK TO SMS_USER
	"LIC_STATUS" VARCHAR2(50),
	"LIC_NAME" VARCHAR2(50 BYTE), 
	"LIC_ADM_NAME" VARCHAR2(50 BYTE), 
	"LIC_TYPE" VARCHAR2(50),
	"LIC_START_DATE" VARCHAR2(50),
	"LIC_STOP_DATE" VARCHAR2(50),
	"LIC_FEE" VARCHAR2(50),
	"LIC_REMARK" VARCHAR2(2000 BYTE), 
	"LAST_UPD_TIME" VARCHAR2(50),
	"SERVER_SITE" VARCHAR2(50),
	"LIC_REGION" VARCHAR2(50),
	"LIC_OPERATION_START_DATE" VARCHAR2(50),
	"LIC_RENEWAL_DATE" VARCHAR2(50),
	"LIC_REG_NUM" VARCHAR2(50),
	"LIC_REG_DATE" VARCHAR2(50),
	"LIC_INFO1" VARCHAR2(100 BYTE), 
	"LIC_INFO2" VARCHAR2(100 BYTE), 
	"LIC_INFO3" VARCHAR2(100 BYTE)
	);

CREATE TABLE TEMP_SMS_RLINK(
	RLI_ID		VARCHAR2(50),
	RLI_LIC_ID	VARCHAR2(50),			--fk to SMS_LICENSE
	RLI_OWNER_ID	VARCHAR2(50),		--FK TO SMS_USER
	RLI_NAME VARCHAR2(100),
	RLI_CHAIN	VARCHAR2(50),
	RLI_DATA_FLOW VARCHAR2(50),
	RLI_STATUS		VARCHAR2(50),
	RLI_DATE_BITU	VARCHAR2(50),
	RLI_DATE_EOU	VARCHAR2(50),
	RLI_START_TIME	VARCHAR2(50),
	RLI_STOP_TIME	VARCHAR2(50),
	RLI_FEE			VARCHAR2(50),
	RLI_REMARK		VARCHAR2(1000),
	RLI_REMARK_ADM	VARCHAR2(50),
	RLI_DISTANCE	VARCHAR2(50),
	RLI_EQUIP_ID1	VARCHAR2(50),
	RLI_EQUIP_ID2	VARCHAR2(50),
	RLI_EQUIP_POWER	VARCHAR2(50),
	RLI_RXTH_3_A	VARCHAR2(50),
	RLI_RXTH_3_B	VARCHAR2(50),
	RLI_RXTH_6_A	VARCHAR2(50),
	RLI_RXTH_6_B	VARCHAR2(50),
	RLI_REFLECT_SURF	VARCHAR2(50),
	RLI_LONG_R		VARCHAR2(50),
	RLI_LAT_R		VARCHAR2(50),
	RLI_REFLECT_ASL		VARCHAR2(50),
	RLI_MINLONG		VARCHAR2(50),
	RLI_MAXLONG		VARCHAR2(50),
	RLI_MINLAT		VARCHAR2(50),
	RLI_MAXLAT		VARCHAR2(50),
	RLI_SITE_ID_A		VARCHAR2(50),
	RLI_SITE_ID_B	VARCHAR2(50),
	RLI_SITE_ID_R	VARCHAR2(50),
	RLI_FREQ_A		VARCHAR2(50),
	RLI_FREQ_B		VARCHAR2(50),
	RLI_POLAR_A		VARCHAR2(50),
	RLI_POLAR_B		VARCHAR2(50),
	RLI_HEIGHT_A	VARCHAR2(50),
	RLI_HEIGHT_B	VARCHAR2(50),
	RLI_LOSSES_A	VARCHAR2(50),
	RLI_LOSSES_B	VARCHAR2(50),
	RLI_ANT_ID_A	VARCHAR2(50),
	RLI_ANT_ID_B	VARCHAR2(50),
	RLI_TRAFFIC_TYPE_A	VARCHAR2(50),
	RLI_TRAFFIC_TYPE_B	VARCHAR2(50),
	RLI_BIT_RATE_A		VARCHAR2(50),
	RLI_BIT_RATE_B		VARCHAR2(50),
	RLI_DIVERSITY_A		VARCHAR2(50),
	RLI_DIVERSITY_B		VARCHAR2(50),
	RLI_EIRP_A			VARCHAR2(50),
	RLI_EIRP_B		VARCHAR2(50),
	RLI_EQUIP_POWER_A		VARCHAR2(50),
	RLI_EQUIP_POWER_B		VARCHAR2(50),
	RLI_PASSIVE_REFLECTOR	VARCHAR2(50),	
	RLI_OPER_HOURS		VARCHAR2(50),
	RLI_RX_ANT_TYPE_A	VARCHAR2(50),
	RLI_RX_ANT_TYPE_B	VARCHAR2(50),
	RLI_RX_ANT_HEIGHT_A	VARCHAR2(50),
	RLI_RX_ANT_HEIGHT_B	VARCHAR2(50),
	RLI_RX_ANT_POLAR_A	VARCHAR2(50),
	RLI_RX_ANT_POLAR_B	VARCHAR2(50),
	RLI_RX_ANT_FREQ_A	VARCHAR2(50),
	RLI_RX_ANT_FREQ_B	VARCHAR2(50),
	RLI_RX_ANT_SPACE_A	VARCHAR2(50),
	RLI_RX_ANT_SPACE_B	VARCHAR2(50),
	LAST_UPD_TIME		VARCHAR2(50),
	TARIFF_CODE			VARCHAR2(50),
	STA_ERP				VARCHAR2(50),
	STA_ERP_B		VARCHAR2(50),
	SERVER_SITE		VARCHAR2(50),
	APPROVED_DATE	VARCHAR2(50),
	RLI_CALL_SIGN	VARCHAR2(50),
	RLI_AREA		VARCHAR2(50),
	RLI_STATION_CLASS	VARCHAR2(50),
	RLI_BAND_A		VARCHAR2(50),
	RLI_BAND_B		VARCHAR2(50),
	RLI_RX_ANT_BAND_A	VARCHAR2(50),
	RLI_RX_ANT_BAND_B	VARCHAR2(50),
	RLI_EQUIP_SERIAL_A	VARCHAR2(50),
	RLI_EQUIP_SERIAL_B	VARCHAR2(50),
	RLI_NATURE_OF_SERVICE	VARCHAR2(50),
	RLI_DUPLEX_SPACING		VARCHAR2(50),
	RLI_OPER_TYPE		VARCHAR2(50)
	);


CREATE TABLE TEMP_SMS_STATION (
	"STA_ID" VARCHAR2(50 BYTE),
	"STA_NAME" VARCHAR2(100 BYTE), 
	"STA_LIC_ID" VARCHAR2(50 BYTE),
	"STA_OWNER_ID" VARCHAR2(50 BYTE),
	"STA_TOWER" VARCHAR2(50 BYTE),
	"STA_CALL_SIGN" VARCHAR2(100 BYTE), 
	"STA_CLASS" VARCHAR2(50 BYTE),
	"STA_OPERATION_CLASS" VARCHAR2(50 BYTE),
	"STA_TYPE" VARCHAR2(50 BYTE),
	"STA_FEE" VARCHAR2(50 BYTE),
	"STA_OPER_HOURS" VARCHAR2(50 BYTE),
	"STA_PRIV_ANT" VARCHAR2(50 BYTE),
	"STA_ANT_ID" VARCHAR2(50 BYTE),
	"STA_LOSSES" VARCHAR2(50 BYTE),
	"STA_SITE_ID" VARCHAR2(50 BYTE),
	"STA_LONGITUDE" VARCHAR2(50 BYTE),
	"STA_LATITUDE" VARCHAR2(50 BYTE),
	"STA_ASL" VARCHAR2(50 BYTE),
	"STA_RADIUS" VARCHAR2(50 BYTE),
	"STA_POWER" VARCHAR2(50 BYTE),
	"STA_AGL" VARCHAR2(50 BYTE),
	"STA_AZIMUTH" VARCHAR2(50 BYTE),
	"STA_ANGLE_ELEV" VARCHAR2(50 BYTE),
	"STA_POLARIZATION" VARCHAR2(50 BYTE),
	"STA_START_TIME" VARCHAR2(50 BYTE),
	"STA_STOP_TIME" VARCHAR2(50 BYTE),
	"STA_DATE_BITU" VARCHAR2(50 BYTE),
	"STA_DATE_EOU" VARCHAR2(50 BYTE),
	"STA_REMARK" VARCHAR2(50 BYTE), 
	"STA_MEMO" VARCHAR2(2000 BYTE), 
	"STA_ANT_GAIN" VARCHAR2(50 BYTE),
	"STA_TRANSMIT_POWER" VARCHAR2(50 BYTE),
	"STA_FRAGMENT" VARCHAR2(50 BYTE),
	"STA_NOT_MODIFY" VARCHAR2(50 BYTE),
	"STA_POWER_RATIO" VARCHAR2(50 BYTE),
	"STA_STABILITY_CODE" VARCHAR2(50 BYTE),
	"STA_OFFSET_CODE" VARCHAR2(50 BYTE),
	"STA_OFFSET_FREQ" VARCHAR2(50 BYTE),
	"STA_OFFSET_TYPE" VARCHAR2(50 BYTE),
	"STA_VA_COORD" VARCHAR2(50 BYTE),
	"STA_VA_ACHIEVE_COORD" VARCHAR2(50 BYTE),
	"STA_FREQ_CATEGORY" VARCHAR2(50 BYTE),
	"STA_CATEGORY_USE" VARCHAR2(50 BYTE),
	"STA_VA_REG_STA" VARCHAR2(50 BYTE), 
	"STA_VA_STA_ID" VARCHAR2(50 BYTE),
	"STA_VA_STA_RADIUS" VARCHAR2(50 BYTE),
	"STA_VA_STA_LOW_FREQ" VARCHAR2(50 BYTE),
	"STA_VA_STA_HIGH_FREQ" VARCHAR2(50 BYTE),
	"STA_VA_DEGREE" VARCHAR2(50 BYTE),
	"STA_VA_REMARK" VARCHAR2(50 BYTE),
	"STA_PERMANENT" VARCHAR2(50 BYTE),
	"LAST_UPD_TIME" VARCHAR2(50 BYTE),
	"TARIFF_CODE" VARCHAR2(50 BYTE),
	"STA_ERP" VARCHAR2(50 BYTE),
	"SERVER_SITE" VARCHAR2(50 BYTE),
	"STATUS" VARCHAR2(50 BYTE),
	"APPROVED_DATE" VARCHAR2(50 BYTE),
	"STA_VA_NATURE_OF_USE" VARCHAR2(50 BYTE), 
	"STA_VA_INITIAL_COORD_REQUEST" VARCHAR2(50 BYTE),
	"STA_VA_STA_RX_LOW_FREQ" VARCHAR2(50 BYTE),
	"STA_VA_STA_RX_HIGH_FREQ" VARCHAR2(50 BYTE),
	"STA_VA_COORDINATES" VARCHAR2(50 BYTE),
	"STA_VA_7A" VARCHAR2(50 BYTE),
	"STA_REG_MARK" VARCHAR2(100 BYTE), 
	"STA_SPECIAL_TYPE" VARCHAR2(100 BYTE), 
	"STA_VEHICLE_NUM" VARCHAR2(50 BYTE), 
	"STA_OPER_AREA1" VARCHAR2(100 BYTE), 
	"STA_OPER_AREA2" VARCHAR2(100 BYTE), 
	"STA_OPER_AREA3" VARCHAR2(100 BYTE), 
	"STA_OPER_AREA4" VARCHAR2(100 BYTE), 
	"STA_INFO1" VARCHAR2(100 BYTE), 
	"STA_INFO2" VARCHAR2(100 BYTE), 
	"STA_INFO3" VARCHAR2(100 BYTE), 
	"STA_HEF" VARCHAR2(50 BYTE),
	"STA_AREA" VARCHAR2(50 BYTE), 
	"STA_EQUIP_SERIAL" VARCHAR2(50 BYTE)
	);

CREATE TABLE TEMP_SMS_STATION_BASE_STATION(
	STA_ID				VARCHAR2(50 BYTE),
	BAS_STA_ID			VARCHAR2(50 BYTE),
	BAS_STA_CHANNEL	VARCHAR2(50 BYTE),
	LAST_UPD_TIME		VARCHAR2(50 BYTE),
	SERVER_SITE		VARCHAR2(50 BYTE)
	);


CREATE TABLE TEMP_SMS_SITE(
	"SIT_ID" VARCHAR2(50 BYTE),
	"SIT_NAME" VARCHAR2(50 BYTE),
	"SIT_LONGITUDE" VARCHAR2(50 BYTE),
	"SIT_LATITUDE" VARCHAR2(50 BYTE),
	"SIT_ADDRESS" VARCHAR2(100 BYTE), 
	"SIT_CITY" VARCHAR2(50 BYTE), 
	"SIT_PROVINCE" VARCHAR2(50 BYTE),
	"SIT_POSTCODE" VARCHAR2(50 BYTE),
	"SIT_COUNTRY_ID" VARCHAR2(50 BYTE),
	"SIT_TEL" VARCHAR2(50 BYTE), 
	"SIT_FAX" VARCHAR2(50 BYTE), 
	"SIT_EMAIL" VARCHAR2(50 BYTE), 
	"SIT_ASL" VARCHAR2(50 BYTE),
	"SIT_REMARK" VARCHAR2(2000 BYTE), 
	"SIT_TEL_DESC" VARCHAR2(50 BYTE), 
	"SIT_FAX_DESC" VARCHAR2(50 BYTE), 
	"LAST_UPD_TIME" VARCHAR2(50 BYTE),
	"SERVER_SITE" VARCHAR2(50 BYTE),
	"SIT_FRAGMENT" VARCHAR2(50 BYTE), 
	"SIT_AREA" VARCHAR2(100 BYTE), 
	"LR_NUMBER" VARCHAR2(50 BYTE), 
	"SERVICE_RADIUS" VARCHAR2(50 BYTE)
	);

CREATE TABLE TEMP_SMS_FREQ_ASSIGN(
	FRQ_STA_ID		VARCHAR2(50 BYTE), 
	FRQ_STA_TYPE	VARCHAR2(50 BYTE), 
	FRQ_STA_CHANNEL		VARCHAR2(50 BYTE), 
	FRQ_TX_LOW_FREQ	VARCHAR2(50 BYTE), 
	FRQ_TX_HIGH_FREQ	VARCHAR2(50 BYTE), 
	FRQ_RX_LOW_FREQ		VARCHAR2(50 BYTE), 
	FRQ_RX_HIGH_FREQ	VARCHAR2(50 BYTE), 
	FRQ_START_DATE		VARCHAR2(50 BYTE), 
	FRQ_END_DATE		VARCHAR2(50 BYTE), 
	FRQ_FREQ_TYPE	VARCHAR2(50 BYTE), 
	FRQ_REMARK		VARCHAR2(50 BYTE), 
	FRQ_MAIN		VARCHAR2(50 BYTE), 
	FRQ_PERMANENT	VARCHAR2(50 BYTE), 
	LAST_UPD_TIME	VARCHAR2(50 BYTE), 
	SERVER_SITE		VARCHAR2(50 BYTE), 
	FRQ_STA_CALL_SIGN		VARCHAR2(50 BYTE), 
	FRQ_STA_LONGITUDE	VARCHAR2(50 BYTE), 
	FRQ_STA_LATITUDE	VARCHAR2(50 BYTE), 
	FRQ_TX_BANDWIDTH	VARCHAR2(50 BYTE), 
	FRQ_RX_BANDWIDTH	VARCHAR2(50 BYTE), 
	FRQ_LSB_USB		VARCHAR2(50 BYTE), 
	FRQ_QUANTITY	VARCHAR2(50 BYTE)
	);


-- arg one: actioncount arg two: keyfield
CREATE OR REPLACE FUNCTION updateemailsent(action_count IN varchar2, keyfield IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;

	BEGIN

		IF(action_count = '1') THEN		--clc
			UPDATE clientlicenses SET isclcemailsent = '1' WHERE clientlicenseid = cast(keyfield as int);
			COMMIT;
		ELSIF(action_count = '2') THEN		--clc approved
			UPDATE clientlicenses SET ispostclcemailsent = '1' WHERE clientlicenseid = cast(keyfield as int);
			COMMIT;
		ELSIF(action_count = '7') THEN		--initial fee reminder
			UPDATE clientlicenses SET isinitialfeeemailsent = '1' WHERE clientlicenseid = cast(keyfield as int);
			COMMIT;
		ELSIF(action_count = '8') THEN		--licenseready
			UPDATE clientlicenses SET islicensereadyemailsent = '1' WHERE clientlicenseid = cast(keyfield as int);
			COMMIT;
		ELSIF(action_count = '9') THEN		--renewal reminder
			UPDATE clientlicenses SET isrenewalreminderemailsent = '1' WHERE clientlicenseid = cast(keyfield as int);
			COMMIT;
		ELSIF(action_count = '10') THEN		--overdue payment notice
			UPDATE clientlicenses SET isoverduepaymentemailsent = '1', isactive = '0', isexpired = '1' WHERE clientlicenseid = cast(keyfield as int);
			COMMIT;


		--LCS NOTICES START HERE
		ELSIF(action_count = '51') THEN		--Application acknowledgement
			UPDATE clientlicenses SET isacknowlegementemailsent = '1' WHERE clientlicenseid = cast(keyfield as int);
			COMMIT;		
	
		ELSIF(action_count = '52') THEN		--Application Differed acknowledgement
			UPDATE clientlicenses SET isdifferalemailsent = '1' WHERE clientlicenseid = cast(keyfield as int);
			COMMIT;

		ELSIF(action_count = '53') THEN		--Gazettement Notice
			UPDATE clientlicenses SET isgazettementemailsent = '1' WHERE clientlicenseid = cast(keyfield as int);
			COMMIT;

		ELSIF(action_count = '54') THEN		--License approval notice
			UPDATE clientlicenses SET islicenseapprovalemailsent = '1' WHERE clientlicenseid = cast(keyfield as int);
			COMMIT;
			
		ELSIF(action_count = '55') THEN		--Reminder: Submission of Quarterly compliance returns
			UPDATE clientlicenses SET iscomplreturnsQemailsent = '1' WHERE clientlicenseid = cast(keyfield as int);
			COMMIT;

		ELSIF(action_count = '56') THEN		--Reminder: Submission of Annual compliance returns
			UPDATE clientlicenses SET iscomplreturnsAemailsent = '1' WHERE clientlicenseid = cast(keyfield as int);
			COMMIT;

		ELSIF(action_count = '57') THEN		--Reminder: Submission of Annual Audited Accounts 
			UPDATE clientlicenses SET isAAAremindersent = '1' WHERE clientlicenseid = cast(keyfield as int);
			COMMIT;

		ELSIF(action_count = '58') THEN		--Number Allocation approval notice
			UPDATE clientlicenses SET isnummberallocationemailsent = '1' WHERE clientlicenseid = cast(keyfield as int);
			COMMIT;

		ELSIF(action_count = '59') THEN		--Type approval Certificate
			UPDATE clientlicenses SET isTAcertificateemailsent = '1' WHERE clientlicenseid = cast(keyfield as int);
			COMMIT;

		END IF;

	RETURN 'Updated ' || keyfield || ' Successfuly';
END;
/



--convenience table for use by correspondence reports - combo
--HAS NO RELATION WHATSOEVER WITH VWCORRESPONDENCESTATUS VIEW
CREATE TABLE correspondencestatus (
	correspondencestatusid 		integer primary key,
	status 	varchar(100), 	
	details		varchar(100)
	);
INSERT INTO correspondencestatus (correspondencestatusid,status) VALUES (1,'Completed');
INSERT INTO correspondencestatus (correspondencestatusid,status) VALUES (2,'Outstanding');




--DIRECTOR GENERAL ROLE

CREATE TABLE bugfix(
	bugfixid		integer primary key,
	bugfixname		varchar(50),
	description		varchar(100),	
	displayhtml		varchar(1000),	
	details			clob
	);
INSERT INTO bugfix(bugfixid,bugfixname,displayhtml) VALUES(1,'USER SWITCH','<b>INITIALIZE SYSTEM VARIABLES</b>');



CREATE OR REPLACE FUNCTION dgToFSM(key_id IN varchar2, user_id IN varchar2, approval IN varchar2, filter_id IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
		
	BEGIN
		
		UPDATE USERS SET ROLENAME = 'ENGINEER', FUNCTIONNAME = 'info,dg,adlicensing' WHERE USERID = 134;
		--legal,complianceeng,compliance,checking,typeapproval,receiving,numbering,mgrtelcom,adlicensing,dlicensing,gazettement,board,dlcslicensing,adlicensing,adlccpl,secretary,officernumbering,mgrcpl,ctma,adnumsta,mgrstan,dgbugfix
		COMMIT;
		
	RETURN 'Role Updated Successfully';
	
END;
/









-----------CRM STUFF----------
--added this to cellphones table
alter table cellphones add parentcellphoneid integer references cellphones;
alter table cellphones add details clob;

CREATE SEQUENCE cellphones_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 200;
CREATE OR REPLACE TRIGGER tr_cellphones_id BEFORE INSERT ON cellphones
for each row 
begin     
	if inserting then 
		if :NEW.cellphoneid  is null then
			SELECT cellphones_id_seq.nextval into :NEW.cellphoneid  from dual;
		end if;
	end if; 
end;
/

--fixed lines trigger
CREATE SEQUENCE fixeline_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 3000;
CREATE OR REPLACE TRIGGER tr_fixedline_id BEFORE INSERT ON fixedline
for each row 
begin     
	if inserting then 
		if :NEW.fixedlineid  is null then
			SELECT fixeline_id_seq.nextval into :NEW.fixedlineid  from dual;
		end if;
	end if; 
end;
/

CREATE OR REPLACE VIEW vwmobilenumbering AS 
	SELECT 
		cellphoneid,cellphonerange, costcharged, details, assigned, dateassigned,
		'639' as countrycode, DECODE(clients.clientid,84,'02',11,'03',26,'05',96,'07',' ') as networkcode,
		numbertypes.numbertypeid, upper(numbertypes.numbertypename) as numbertypename, clients.clientid, UPPER(COALESCE(clients.clientname,'Unassigned')) AS clientname
	FROM cellphones
	LEFT JOIN numbertypes ON cellphones.numbertypeid = numbertypes.numbertypeid
	LEFT JOIN clients ON cellphones.clientid = clients.clientid;



CREATE OR REPLACE VIEW vwfreephonenumbering AS
	SELECT
	freephoneid, assigned, substr(cellphonerange,1,4) as ndc, 
    substr(cellphonerange,5) as otherdigits,
    cellphonerange, costcharged, dateassigned, length(cellphonerange)-2 as digitlength,
	numbertypes.numbertypeid, upper(numbertypes.numbertypename) as numbertypename, clients.clientid, UPPER(COALESCE(clients.clientname,'Unassigned')) AS clientname
	from freephone
	LEFT JOIN numbertypes ON freephone.numbertypeid = numbertypes.numbertypeid
	LEFT JOIN clients ON freephone.clientid = clients.clientid;





create or replace FUNCTION  EVALUATIONAPPROVE (myval1 IN varchar2, myval2 IN varchar2,myval3 IN varchar2, myval4 IN varchar2) RETURN varchar2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
  
CURSOR cursor1 IS
	SELECT clientphases.clientlicenseid,clientphases.CLIENTPHASENAME,CLIENTPHASES.CLIENTPHASEID from clientphases 
	WHERE clientphases.clientlicenseid = CAST(myval1 as int) AND CLIENTPHASENAME = 'taevaluation';
	c3 cursor1%ROWTYPE;
BEGIN
	OPEN cursor1;
  	FETCH cursor1  INTO c3;

IF(myval3 = 'EvaluationApproved')   THEN
	UPDATE clientphases SET approved = '1', rejected = '0', DEFFERED='0', pending = '0', 
  Withdrawn = '0', actiondate = sysdate, userid = CAST(myval2 as int)
	WHERE clientphases.CLIENTPHASEID = C3.CLIENTPHASEID;
	COMMIT;		    
END IF;
COMMIT;
	
	RETURN 'Submitted';

END;
 



--all guys with provisional certificates....
CREATE OR REPLACE FORCE VIEW VWCERTIFICATES AS 
	SELECT vwallchecklists.clientlicenseid, vwallchecklists.clientname, vwallchecklists.licensename, vwallchecklists.actiondate, add_months(TO_CHAR(vwallchecklists.actiondate, 'DD/Mon/YYYY'), 6) AS certificationdate,
	vwallchecklists.approved,vwallchecklists.rejected,vwallchecklists.clientphasename,
	equipmentapprovals.equipmentapprovalid, equipmentapprovals.equipmentname,equipmentapprovals.manufacturer, equipmentapprovals.make, equipmentapprovals.model, equipmentapprovals.serialnumber,
	equipmentapprovals.cert_url, 
	(vwallchecklists.clientname || ', Approved On: ' || to_char(vwallchecklists.actiondate,'YYYY-Mon-DD') || ', Certification Date: ' || add_months(TO_CHAR(vwallchecklists.actiondate, 'DD/Mon/YYYY'), 6)) AS certificationdetails
	FROM vwallchecklists 
	INNER JOIN equipmentapprovals ON vwallchecklists.clientlicenseid = equipmentapprovals.clientlicenseid
	WHERE (vwallchecklists.approved = '1') AND (vwallchecklists.rejected = '0')  AND (vwallchecklists.clientphasename = 'tac');
	

---approve a vendor
create or replace FUNCTION  ActivateVendor (cli_lic_id IN varchar2, usr_id IN varchar2, appr IN varchar2, filtr IN varchar2) RETURN varchar2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
  
BEGIN
	
	IF(appr = 'ActivateVendor')   THEN
		UPDATE clientphases SET approved = '1' WHERE clientlicenseid = cast(cli_lic_id as int);		--approve all the remaining faces
		COMMIT;		    
		UPDATE clientlicenses SET isactive = '1' WHERE clientlicenseid = cast(cli_lic_id as int);	
		COMMIT;
		RETURN 'Approval Holder Activated Successfuly';
	END IF;
	
	RETURN 'Unreachable Code';

END;

--SPC (in decimal numbers)	Service	Capacity	Availability	Assignee	Remarks																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																										

CREATE TABLE NSPC(
	NSPCID 			integer PRIMARY KEY, 
	NUMBERTYPEID	integer references NUMBERTYPES(NUMBERTYPEID), 
	CLIENTID		integer,    -- references clients, 
	SPC				varchar(50), 
	SERVICE			varchar(50),
	CAPACITY 		varchar(10), 			
	ASSIGNED CHAR(1) DEFAULT '0' NOT NULL ENABLE, 
	DATEASSIGNED 		DATE, 
	NSPCOPERATOR	varchar(200), 		--aka assignee / clientid
	DETAILS			 varchar(500)
	);
CREATE SEQUENCE NSPC_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_NSPC_id BEFORE INSERT ON NSPC
for each row 
begin     
	if inserting then 
		if :NEW.NSPCID  is null then
			SELECT NSPC_id_seq.nextval into :NEW.NSPCID  from dual;
		end if;
	end if; 
end;
/



CREATE OR REPLACE FUNCTION NUMBERASSIGN (myval1 IN varchar2, myval2 IN varchar2, myval3 IN varchar2, myval4 IN varchar2) RETURN VARCHAR2 IS

	PRAGMA AUTONOMOUS_TRANSACTION;
	
	BEGIN

	
	IF(myval3 = 'Assign Number') THEN
		UPDATE assignednumbers  SET assigned = '1',dateassigned = SYSDATE WHERE assignednumberid = CAST(myval1 AS int);    
		COMMIT;
		RETURN 'Assigned';
	END IF;
	
	IF(myval3 = 'Reclaim Number') THEN  --reclaim a booked number making it free		
		--if
		DELETE FROM assignednumbers WHERE assignednumberid = CAST(myval1 AS int);    
		COMMIT;
		RETURN 'Reclaimed';
	END IF;

	IF(myval3 = 'Activate') THEN
		UPDATE assignednumbers  SET ACTIVATED = '1',DATEACTIVATED = SYSDATE WHERE assignednumberid = CAST(myval1 AS int);    
		COMMIT;
		RETURN 'Activated';
	END IF;
  
   IF(myval3 = 'Notified') THEN
		UPDATE assignednumbers  SET notified = '1',datenotified = SYSDATE WHERE assignednumberid = CAST(myval1 AS int);    
		COMMIT;
		RETURN 'Notified';
	END IF;



	RETURN 'Assigned';
END;
 


create or replace FUNCTION NUMBERASSIGNNUMOFFICER (myval1 IN varchar2, myval2 IN varchar2, myval3 IN varchar2, myval4 IN varchar2) RETURN VARCHAR2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;
numberassigned varchar2(240);
	
	CURSOR c1 IS
		SELECT CLIENTNAME,clientid			
		FROM vwallchecklists 
		WHERE clientphaseid = CAST(myval4 AS int);
		rc1 c1%ROWTYPE;
		

	BEGIN

	OPEN c1;
	FETCH c1 INTO rc1;

	IF(myval3 = 'cellphones') THEN
    SELECT CELLPHONERANGE INTO numberassigned FROM cellphones WHERE cellphoneid = CAST(myval1 AS int);
	UPDATE cellphones  SET assigned = '1',dateassigned = SYSDATE,clientid = rc1.clientid WHERE cellphoneid = CAST(myval1 AS int);

    INSERT INTO assignednumbers (CLIENTID,booked,datebooked,RESOURCEASSIGNED,resourceid)
    VALUES(rc1.clientid,'1',SYSDATE,'cellphones',numberassigned);
	  COMMIT;
    RETURN 'Assigned';
	END IF;
  
  IF(myval3 = 'freephone') THEN
    SELECT CELLPHONERANGE INTO numberassigned FROM freephone WHERE freephoneid = CAST(myval1 AS int);
		UPDATE freephone  SET assigned = '1',dateassigned = SYSDATE,clientid = CAST(myval4 AS int) 
		WHERE freephoneid = CAST(myval1 AS int);
		INSERT INTO assignednumbers (CLIENTID,booked,datebooked,RESOURCEASSIGNED,resourceid) 
    VALUES(rc1.clientid,'1',SYSDATE,'Free Phone',numberassigned);
	COMMIT;
	RETURN 'Assigned';
	END IF;

IF(myval3 = 'premiumphone') THEN
    SELECT CELLPHONERANGE INTO numberassigned FROM freephone WHERE freephoneid = CAST(myval1 AS int);
		UPDATE freephone  SET assigned = '1',dateassigned = SYSDATE,clientid = CAST(myval4 AS int) 
		WHERE freephoneid = CAST(myval1 AS int);
		INSERT INTO assignednumbers (CLIENTID,booked,datebooked,RESOURCEASSIGNED,resourceid) 
    VALUES(rc1.clientid,'1',SYSDATE,'Premium Phone',numberassigned);
	COMMIT;
	RETURN 'Assigned';
	END IF;
  
  
  IF(myval3 = 'Identification') THEN
    SELECT IDNUMBER INTO numberassigned FROM issueridentification WHERE issueridentificationid = CAST(myval1 AS int);
		UPDATE issueridentification  SET assigned = '1',dateassigned = SYSDATE,clientid = rc1.clientid 
		WHERE issueridentificationid = CAST(myval1 AS int);
		INSERT INTO assignednumbers (CLIENTID,booked,datebooked,RESOURCEASSIGNED,resourceid) 
    VALUES(rc1.clientid,'1',SYSDATE,'Identification',numberassigned);
	COMMIT;
	RETURN 'Assigned';
	END IF;

  IF(myval3 = 'imsi') THEN
    SELECT imsi INTO numberassigned FROM imsi WHERE imsiid = CAST(myval1 AS int);
		UPDATE imsi  SET assigned = '1',dateassigned = SYSDATE,clientid = rc1.clientid 
		WHERE imsiid = CAST(myval1 AS int);
		INSERT INTO assignednumbers (CLIENTID,booked,datebooked,RESOURCEASSIGNED,resourceid)
    VALUES(rc1.clientid,'1',SYSDATE,'imsi',numberassigned);
	COMMIT;
	RETURN 'Assigned';
	END IF;

  IF(myval3 = 'ispc') THEN
    SELECT ISPC INTO numberassigned FROM ispc WHERE ispcID = CAST(myval1 AS int);
		UPDATE ispc  SET assigned = '1',dateassigned = SYSDATE,clientid = rc1.clientid ,ispcoperator = rc1.clientname
		WHERE ispcID = CAST(myval1 AS int);
		INSERT INTO assignednumbers (CLIENTID,booked,datebooked,RESOURCEASSIGNED,resourceid) 
    VALUES(rc1.clientid,'1',SYSDATE,'ispc',numberassigned);
	COMMIT;
	RETURN 'Assigned';
	END IF;
  
  IF(myval3 = 'fixedline') THEN
SELECT NUMBERASSIGNED2 INTO numberassigned FROM fixedline WHERE fixedlineid = CAST(myval1 AS int);
		UPDATE fixedline  SET assigned = '1',dateassigned = SYSDATE,clientid = rc1.clientid ,ASSIGNEE = rc1.clientname
		WHERE fixedlineid = CAST(myval1 AS int);
		INSERT INTO assignednumbers (CLIENTID,booked,datebooked,RESOURCEASSIGNED,resourceid) 
    VALUES(rc1.clientid,'1',SYSDATE,'Fixed Line',numberassigned);
	COMMIT;
	RETURN 'Assigned';
	END IF;
	
	IF(myval3 = 'colourcode') THEN
SELECT COLOURCODE INTO numberassigned FROM colourcodes WHERE COLOURCODEID = CAST(myval1 AS int);
		UPDATE colourcodes  SET ASSIGNED = '1',dateassigned = SYSDATE,clientid = rc1.clientid ,ASSIGNEE = rc1.clientname
		WHERE COLOURCODEID = CAST(myval1 AS int);
		INSERT INTO assignednumbers (CLIENTID,booked,datebooked,RESOURCEASSIGNED,resourceid) 
    VALUES(rc1.clientid,'1',SYSDATE,'colourcode',numberassigned);
	COMMIT;
	RETURN 'Assigned';
	END IF;

	IF(myval3 = 'sid') THEN
SELECT SYSTEMIDENTIFIER INTO numberassigned FROM systemidentifier WHERE systemidentifierid = CAST(myval1 AS int);
		UPDATE systemidentifier  SET ASSIGNED = '1',dateassigned = SYSDATE,clientid = rc1.clientid ,ASSIGNEE = rc1.clientname
		WHERE systemidentifierid = CAST(myval1 AS int);
		INSERT INTO assignednumbers (CLIENTID,booked,datebooked,RESOURCEASSIGNED,resourceid) 
    VALUES(rc1.clientid,'1',SYSDATE,'sid',numberassigned);
	COMMIT;
	RETURN 'Assigned';
	END IF;


	RETURN 'Unreachable Code';
END;
 








create or replace FUNCTION SUBMITFINANCE (myval1 IN varchar2, myval2 IN varchar2,myval3 IN varchar2, myval4 IN varchar2) RETURN varchar2 IS
	PRAGMA AUTONOMOUS_TRANSACTION;

CURSOR count_cur IS 
 SELECT  clientlicenseid,ANNUALFEEDUE,
 cast(coalesce(annualfeedue(MINANNUALFEE,(0.5/100) * CAST (COALESCE (LICENSEREVENUE,0) AS REAL)),'0')as real) as feedue
 FROM vwperiodlicenses 
	WHERE (periodlicenseid = CAST(myval1 as int)) AND (isinvoiced = '0');
  rc count_cur%ROWTYPE;
  
  
CURSOR cursor2 IS
SELECT periodid FROM periods WHERE periods.isactive = '1';
c4 cursor2%ROWTYPE;

	
	
	annual_gross	real;
	non_licrev	real;		--non license revenu
	licrev		real;		--licenserevenue
	annual_fee		real;	--miminum defined in the license itself

	calculated_fee		real; 	--the greate of the two is used
  
  fee_due          real;
BEGIN
	OPEN count_cur;
  	FETCH count_cur INTO rc;
	
	OPEN cursor2;
  	FETCH cursor2 INTO c4;
	
  
	--initialize
	--SELECT annualgross INTO annual_gross FROM periodlicenses WHERE periodlicenseid = CAST(myval1 as int);
	--SELECT nonlicenserevenue INTO non_licrev FROM periodlicenses WHERE periodlicenseid = CAST(myval1 as int);
	--licrev := annual_gross - non_licrev;
	--calculated_fee := (0.5/100) * licrev;			--idealy the percentage value should be stored in the licenses table...

  --TEST
  SELECT calculatedfeedue INTO fee_due FROM vwperiodlicenses WHERE periodlicenseid = CAST(myval1 as int);  

	--SELECT annualfee  FROM licenses INNER JOIN periodlicenses ON licenses.licenseid = periodlicenses.licenseid;
  --SELECT licenses.annualfee INTO annual_fee
  --  FROM licenses 
  --  INNER JOIN clientlicenses ON licenses.licenseid = clientlicenses.licenseid
  --  INNER JOIN periodlicenses ON clientlicenses.clientlicenseid = periodlicenses.clientlicenseid
  --  WHERE periodlicenses.periodlicenseid = CAST(myval1 as int);


	--we need to determine which is greater between the 0.5% of LR and the minimum defined	

	--not taking any chances; computing LR from AG-NLR
	--UPDATE periodlicenses SET LICENSEREVENUE = CAST (COALESCE (ANNUALGROSS,0) AS REAL) - CAST (COALESCE (NONLICENSEREVENUE,0) AS REAL)  WHERE periodlicenseid = CAST(myval1 as int);
	UPDATE periodlicenses SET LICENSEREVENUE = licrev  WHERE periodlicenseid = CAST(myval1 as int);
		COMMIT;

	UPDATE periodlicenses SET ANNUALFEESENT = '1', ANNUALFEEDUE = fee_due WHERE periodlicenseid = CAST(myval1 as int);	
		COMMIT;

  INSERT INTO licensepayments (paymenttypeid,clientlicenseid,amount,userid,productcode,invoicedate,periodid) 
    VALUES( 3 ,rc.clientlicenseid, fee_due, CAST(myval2 as int) ,'B83D6591F09F40C3A082C17DFC4D27EC',sysdate,c4.periodid);

  
	--UPDATE periodlicenses SET isinvoiced = '1' WHERE periodlicenseid = CAST(myval1 as int);
	COMMIT;
	
	RETURN 'DONE';
	CLOSE count_cur;
END;
 




  CREATE OR REPLACE FORCE VIEW VWCOMPLIANCEAPPROVAL ("SHAREHOLDING", "LICENSEEREQUEST", "PERIODLICENSEID", "FULLNAME", "EDITMEMO", "NUMBERING", "CLIENTID", "NARRATIVE", "USERGROUPID", "USERGROUPNAME", "CLIENTPHASEID", "PHASEID", "PHASELEVEL", "RETURNLEVEL", "COMPLIANCE", "CONTRAVENTION", "REPRIMAND", "PUBLICATION", "PENALTY", "REVOCATION", "APPROVAL", "ESCALATIONTIME", "DETAILS", "PAYMENTTYPEID", "ANNUALSCHEDULE", "CLIENTNAME", "CLIENTAPPLEVEL", "CLIENTPHASENAME", "USERID", "APPROVED", "REJECTED", "PENDING", "COMPLIANCEID", "PENALTYAMOUNT", "PENALTYAMOUNTFINAL", "COMPLIANCECOUNTLNA", "REVOCATIONCOUNTLNA") AS 
  SELECT  phases.shareholding,
   phases.licenseerequest,
  CLIENTPHASES.PERIODLICENSEID,
    USERS.FULLNAME,
    clientphases.editmemo,
    phases.numbering,
    clientphases.clientid,
    clientphases.narrative,
    usergroups.usergroupid,
    usergroups.usergroupname,
    clientphases.clientphaseid,
    phases.phaseid,
    phases.phaselevel,
    phases.returnlevel,
    phases.compliance,
    phases.Contravention,
    phases.Reprimand,
    phases.Publication,
    phases.Penalty,
    phases.Revocation,
    phases.approval,
    phases.EscalationTime,
    clientphases.details,
    phases.paymenttypeid,
    phases.annualschedule,
    clients.clientname,
    clientphases.clientapplevel,
    clientphases.clientphasename,
    clientphases.userid,
    clientphases.approved,
    clientphases.rejected ,
    clientphases. pending ,
    clientphases.complianceid,
    clientphases.penaltyamount,
    clientphases.penaltyamountfinal,
    GETCOMPLIANCECOUNTLNA(clientphases.complianceid,clientphases.clientapplevel) AS COMPLIANCECOUNTLNA,
    GETREVOCATIONCOUNTLNA(clientphases.CLIENTid,clientphases.clientapplevel)     AS REVOCATIONCOUNTLNA
  FROM (phases
  INNER JOIN usergroups
  ON phases.usergroupid = usergroups.usergroupid)
  INNER JOIN clientphases
  ON clientphases.phaseid = phases.phaseid
  INNER JOIN clients
  ON clients.clientid = clientphases.clientid
  LEFT OUTER JOIN users
  ON users.userid = clientphases.userid;
 




CREATE OR REPLACE FORCE VIEW VWASSIGNEDNUMBERS AS 
	SELECT 
	assignednumbers.ASSIGNEDNUMBERID,
	assignednumbers.RESOURCEID,
	assignednumbers.CLIENTID,
	assignednumbers.DETAILS,
	assignednumbers.ASSIGNED,
	assignednumbers.DATEASSIGNED,
	add_months(TO_CHAR(assignednumbers.DATEASSIGNED, 'DD/Mon/YYYY'), 6) AS activationdeadline,
	assignednumbers.RESOURCEASSIGNED,
	assignednumbers.DATEACTIVATED,
	assignednumbers.ACTIVATED,
	assignednumbers.notified,
	assignednumbers.booked,
	assignednumbers.datenotified,
	assignednumbers.datebooked,
	vwclients.clientname,
	vwclients.email,
  
	'1' AS isnummberallocationemailsent,
	'receiving' as currentphase,
	'0' as isactive,
	'1' as forlcs,
  '0' as forfsm,
	current_date as applicationdate,
  null as clientlicenseid, 
  'none' as licensename
	--vwclientlicenses.clientlicenseid,
	--vwclientlicenses.licensename,
	--vwclientlicenses.isactive,
	--vwclientlicenses.forlcs,
	--vwclientlicenses.forfsm,
	--vwclientlicenses.currentphase,
	--vwclientlicenses.isnummberallocationemailsent,
	--vwclientlicenses.applicationdate
	FROM assignednumbers 
	INNER JOIN vwclients ON vwclients.CLIENTID = assignednumbers.clientid;



CREATE SEQUENCE postal_license_seq NOCACHE MINVALUE 1 MAXVALUE 999 INCREMENT BY 1 START WITH 1;		--NOCACHE to avoid gaps in the sequence
CREATE SEQUENCE nfp_t1_seq NOCACHE MINVALUE 1 MAXVALUE 10 INCREMENT BY 1 START WITH 1;		--00001- 00010
CREATE SEQUENCE nfp_t2_seq NOCACHE MINVALUE 11 MAXVALUE 50 INCREMENT BY 1 START WITH 11;		--NFP T2, IGS, SCLR ---00011 - 00050
CREATE SEQUENCE nfp_t3_seq NOCACHE MINVALUE 51 MAXVALUE 150 INCREMENT BY 1 START WITH 51;		--00051 - 00150
CREATE SEQUENCE asp_csp_seq NOCACHE MINVALUE 151 MAXVALUE 99999 INCREMENT BY 1 START WITH 151;	--00151 to 99999
CREATE SEQUENCE other_licenses_seq NOCACHE MINVALUE 1 MAXVALUE 99999 INCREMENT BY 1 START WITH 151;--00001- 99999



--CREATE OR REPLACE FUNCTION getLicenseNumber(cli_lic_id in integer) RETURN varchar IS
CREATE OR REPLACE FUNCTION getLicenseNumber(cli_lic_id IN varchar2, logged_user IN varchar2,approval IN varchar2,filter_id IN varchar2) RETURN varchar IS

--DECLARE 
	PRAGMA AUTONOMOUS_TRANSACTION;

	CURSOR clientlicense_cur IS
		SELECT clientlicenses.clientlicenseid, clients.clientid, clients.licensenumber, clients.idnumber,
		licenses.licenseid,licenses.licenseabbrev,licenses.isserviceprovider,licenses.isvsat,licenses.isinfrastructure,licenses.ispostal,licenses.iscontractor		
		FROM clientlicenses 
		INNER JOIN licenses ON clientlicenses.licenseid = licenses.licenseid
		INNER JOIN clients ON clientlicenses.clientid = clients.clientid
		WHERE clientlicenses.clientlicenseid = CAST(cli_lic_id AS INT);
		rec_clientlicense clientlicense_cur%ROWTYPE;
	
		yyy	char(3);			--for use by postal licenses
		lic_number int;

BEGIN

	OPEN clientlicense_cur;
	FETCH clientlicense_cur INTO rec_clientlicense;


	IF rec_clientlicense.ispostal = '1' THEN
		--PL/0yyy/xxx  where where yyy are the last 3 digits of the current year
		SELECT TO_CHAR(sysdate,'YYY') INTO yyy FROM dual;
    SELECT postal_license_seq.nextval INTO lic_number FROM dual ;
		--RETURN 'PL/0'|| yyy ||'/'|| lic_number;
    
    UPDATE clientlicenses SET licensenumber = 'PL/0' || yyy || '/' || lic_number WHERE clientlicenseid = CAST(cli_lic_id AS INT);
    

	ELSIF rec_clientlicense.licenseabbrev = 'NFP/T1' THEN		--number is to be shared with subsequent OTHER licenses

		IF(rec_clientlicense.licensenumber IS NULL) THEN		--if NOT already having NFP T2/T3/IGS/SCLR license
			SELECT nfp_t1_seq.nextval INTO lic_number FROM dual ;
			UPDATE clients SET licensenumber = lic_number WHERE clientid = rec_clientlicense.clientid;		--update clients table
      
			--RETURN 'PL/' || rec_clientlicense.licenseabbrev || 'NFPT1' || lic_number;
      UPDATE clientlicenses SET licensenumber = 'TL/' || rec_clientlicense.licenseabbrev || '/' || lic_number WHERE clientlicenseid = CAST(cli_lic_id AS INT);
		ELSE
			--RETURN 'PL/' || rec_clientlicense.licenseabbrev || 'NFPT1' || rec_clientlicense.licensenumber;
       UPDATE clientlicenses SET licensenumber = 'TL/' || rec_clientlicense.licenseabbrev || '/' || rec_clientlicense.licensenumber WHERE clientlicenseid = CAST(cli_lic_id AS INT);
		END IF;

	ELSIF rec_clientlicense.licenseabbrev = 'NFP/T2' THEN		--number is to be shared with subsequent OTHER licenses

		IF(rec_clientlicense.licensenumber IS NULL) THEN		--if NOT already having NFP T1/T3/IGS/SCLR license
			SELECT nfp_t2_seq.nextval INTO lic_number FROM dual ;
			UPDATE clients SET licensenumber = lic_number WHERE clientid = rec_clientlicense.clientid;		--update clients table
			--RETURN 'PL/' || rec_clientlicense.licenseabbrev || 'NFPT2' || lic_number;
      UPDATE clientlicenses SET licensenumber = 'TL/' || rec_clientlicense.licenseabbrev || '/' || lic_number WHERE clientlicenseid = CAST(cli_lic_id AS INT);
		ELSE
			--RETURN 'PL/' || rec_clientlicense.licenseabbrev || 'NFPT2' || rec_clientlicense.licensenumber;
       UPDATE clientlicenses SET licensenumber = 'TL/' || rec_clientlicense.licenseabbrev || '/' || rec_clientlicense.licensenumber WHERE clientlicenseid = CAST(cli_lic_id AS INT);
		END IF;

	ELSIF rec_clientlicense.licenseabbrev = 'IGS' THEN		--number is to be shared with subsequent OTHER licenses

		IF(rec_clientlicense.licensenumber IS NULL) THEN		--if NOT already having NFP T1/T2/T3/SCLR license
			SELECT nfp_t2_seq.nextval INTO lic_number FROM dual ;
			UPDATE clients SET licensenumber = lic_number WHERE clientid = rec_clientlicense.clientid;		--update clients table
			--RETURN 'PL/' || rec_clientlicense.licenseabbrev || 'IGS' || lic_number;
      UPDATE clientlicenses SET licensenumber = 'TL/' || rec_clientlicense.licenseabbrev || '/' || lic_number WHERE clientlicenseid = CAST(cli_lic_id AS INT);
		ELSE
			--RETURN 'PL/' || rec_clientlicense.licenseabbrev || 'NFPT2' || rec_clientlicense.licensenumber;
       UPDATE clientlicenses SET licensenumber = 'TL/' || rec_clientlicense.licenseabbrev || '/' || rec_clientlicense.licensenumber WHERE clientlicenseid = CAST(cli_lic_id AS INT);
		END IF;

	ELSIF rec_clientlicense.licenseabbrev = 'SCLR' THEN		--number is to be shared with subsequent OTHER licenses

		IF(rec_clientlicense.licensenumber IS NULL) THEN		--if NOT already having NFP T1/T2/T3/IGSlicense
			SELECT nfp_t2_seq.nextval INTO lic_number FROM dual ;
			UPDATE clients SET licensenumber = lic_number WHERE clientid = rec_clientlicense.clientid;		--update clients table
			--RETURN 'PL/' || rec_clientlicense.licenseabbrev || 'SCLR' || lic_number;		
      UPDATE clientlicenses SET licensenumber = 'TL/' || rec_clientlicense.licenseabbrev || '/' || lic_number WHERE clientlicenseid = CAST(cli_lic_id AS INT);
		ELSE
			--RETURN 'PL/' || rec_clientlicense.licenseabbrev || 'NFPT2' || rec_clientlicense.licensenumber;
       UPDATE clientlicenses SET licensenumber = 'TL/' || rec_clientlicense.licenseabbrev || '/' || rec_clientlicense.licensenumber WHERE clientlicenseid = CAST(cli_lic_id AS INT);
		END IF;

	ELSIF rec_clientlicense.licenseabbrev = 'NFP/T3'	THEN	--number is to be shared with subsequent OTHER licenses

		IF(rec_clientlicense.licensenumber IS NULL) THEN
			SELECT nfp_t3_seq.nextval INTO lic_number FROM dual ;
			UPDATE clients SET licensenumber = lic_number WHERE clientid = rec_clientlicense.clientid;		--update clients table
			--RETURN 'PL/' || rec_clientlicense.licenseabbrev || 'NFPT3' || lic_number;		
      UPDATE clientlicenses SET licensenumber = 'TL/' || rec_clientlicense.licenseabbrev || '/' || lic_number WHERE clientlicenseid = CAST(cli_lic_id AS INT);
		ELSE
			--RETURN 'PL/' || rec_clientlicense.licenseabbrev || 'NFPT3' || rec_clientlicense.licensenumber;
       UPDATE clientlicenses SET licensenumber = 'TL/' || rec_clientlicense.licenseabbrev || '/' || rec_clientlicense.licensenumber WHERE clientlicenseid = CAST(cli_lic_id AS INT);
		END IF;

	ELSIF rec_clientlicense.licenseabbrev = 'ASP' OR rec_clientlicense.licenseabbrev = 'CSP' THEN	
		
		IF(rec_clientlicense.licensenumber IS NULL) THEN
			SELECT asp_csp_seq.nextval INTO lic_number FROM dual;
			--RETURN 'PL/' || rec_clientlicense.licenseabbrev || '/' || lic_number;		--check for existing licensenumber on clients table ??
      UPDATE clientlicenses SET licensenumber = 'TL/' || rec_clientlicense.licenseabbrev || '/' || lic_number WHERE clientlicenseid = CAST(cli_lic_id AS INT);
		ELSE
    --RETURN 'PL/' || rec_clientlicense.licenseabbrev || '/' || rec_clientlicense.licensenumber;
      UPDATE clientlicenses SET licensenumber = 'TL/' || rec_clientlicense.licenseabbrev || '/' || rec_clientlicense.licensenumber WHERE clientlicenseid = CAST(cli_lic_id AS INT);
			
		END IF;

	ELSIF rec_clientlicense.licenseabbrev = 'TP' THEN
		--2/<<id no. Of the licensee>>
		--RETURN 'PL/' || rec_clientlicense.licenseabbrev || '/2/' || rec_clientlicense.idnumber;
    UPDATE clientlicenses SET licensenumber = 'TL/' || rec_clientlicense.licenseabbrev || '/2/' || rec_clientlicense.idnumber WHERE clientlicenseid = CAST(cli_lic_id AS INT);
    
	ELSE
		SELECT other_licenses_seq.nextval INTO lic_number FROM dual;
		--RETURN 'PL/' || rec_clientlicense.licenseabbrev || '/' || lic_number;	
    UPDATE clientlicenses SET licensenumber = 'TL/' || rec_clientlicense.licenseabbrev || '/' || rec_clientlicense.licensenumber WHERE clientlicenseid = CAST(cli_lic_id AS INT);
	END IF;
  
  COMMIT;
  RETURN 'License Number Successfuly Assigned';
END;
/

CREATE TABLE FREEPHONE 
   (
	FREEPHONEID NUMBER(*,0), 
	NUMBERTYPEID NUMBER(*,0), 
	CLIENTID NUMBER(*,0), 
	CELLPHONERANGE VARCHAR2(240 BYTE), 
	COSTCHARGED VARCHAR2(240 BYTE), 
	DETAILS CLOB, 
	ASSIGNED CHAR(1 BYTE) DEFAULT '0' NOT NULL ENABLE, 
	DATEASSIGNED DATE DEFAULT sysdate
	);
CREATE SEQUENCE freephone_id_seq MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER tr_freephone_id BEFORE INSERT ON FREEPHONE
for each row 
begin     
	if inserting then 
		if :NEW.FREEPHONEID  is null then
			SELECT freephone_id_seq.nextval into :NEW.FREEPHONEID  from dual;
		end if;
	end if; 
end;
/

CREATE OR REPLACE FORCE VIEW VWCELLPHONES2 AS 
  SELECT cellphoneid,
    numbertypeid,
    assigned,
    cellphonerange ,
    costcharged,
    dateassigned
  FROM cellphones;


--june 14
alter table licenses add issquential			char(1) default '0';		--whether or not the license number changes
alter table licenses add 	nextsequenceval		integer;

alter table clients add licensenumber		varchar(20);