CREATE TABLE nema_file (
	nema_file_id		number primary key,
	client_id			number references client,
	nema_code			varchar(50) not null,
	nema_ref			number not null,
	project_date		date not null,
	received_date		date not null,
	due_date			date not null,
	facility_type		varchar(50),
	site_number			varchar(50),
	latitude			number(10,6),
	longitude			number(10,6),
	location			varchar(240),
	approved			char(1) default '0' not null,
	approval_date		date,
	co_location			char(1),
	public_consultation	char(1),
	issues				char(1) default '0' not null,
	details				clob
);
CREATE SEQUENCE nema_file_id_seq start with 1 increment by 1 nomaxvalue;
CREATE OR REPLACE TRIGGER tr_nema_file_id BEFORE INSERT ON nema_file FOR EACH row BEGIN 
	IF inserting THEN 
		IF :NEW.nema_file_id IS NULL THEN
			SELECT nema_file_id_seq.nextval INTO :NEW.nema_file_id FROM dual;
		END IF;
	END IF;
END;
/

CREATE TABLE nema_antenna (
	nema_antenna_id		number primary key,
	nema_file_id		number references nema_file,
	antenna_type		varchar(50) not null,
	height				float,
	elec_tilt			float, 
	mech_tilt			float,
	azimuth				float
);
CREATE SEQUENCE nema_antenna_id_seq start with 1 increment by 1 nomaxvalue;
CREATE OR REPLACE TRIGGER tr_nema_antenna_id BEFORE INSERT ON nema_antenna FOR EACH row BEGIN 
	IF inserting THEN 
		IF :NEW.nema_antenna_id IS NULL THEN
			SELECT nema_antenna_id_seq.nextval INTO :NEW.nema_antenna_id FROM dual;
		END IF;
	END IF;
END;
/

CREATE TABLE nema_link (
	nema_link_id		number primary key,
	nema_file_id		number references nema_file,
	link_diameter		float,
	height				float,
	azimuth				float
);
CREATE SEQUENCE nema_link_id_seq start with 1 increment by 1 nomaxvalue;
CREATE OR REPLACE TRIGGER tr_nema_link_id BEFORE INSERT ON nema_link FOR EACH row BEGIN 
	IF inserting THEN 
		IF :NEW.nema_link_id IS NULL THEN
			SELECT nema_link_id_seq.nextval INTO :NEW.nema_link_id FROM dual;
		END IF;
	END IF;
END;
/

CREATE VIEW vw_nema_file AS
	SELECT client.client_name, nema_file.nema_file_id, nema_file.client_id, nema_file.nema_code, nema_file.nema_ref, 
		nema_file.project_date, nema_file.received_date, nema_file.due_date, nema_file.facility_type, nema_file.site_number, 
		nema_file.latitude, nema_file.longitude, nema_file.location, nema_file.approved, nema_file.approval_date, nema_file.co_location, 
		nema_file.public_consultation, nema_file.issues, nema_file.details
	FROM nema_file INNER JOIN client ON nema_file.client_id = client.client_id;

CREATE VIEW vw_nema_antenna AS
	SELECT vw_nema_file.client_name, vw_nema_file.nema_file_id, vw_nema_file.client_id,
		nema_antenna.nema_antenna_id, nema_antenna.antenna_type, nema_antenna.height, nema_antenna.elec_tilt, nema_antenna.mech_tilt, 
		nema_antenna.azimuth
	FROM nema_antenna INNER JOIN vw_nema_file ON nema_antenna.nema_file_id = vw_nema_file.nema_file_id;

CREATE VIEW vw_nema_link AS
	SELECT vw_nema_file.client_name, vw_nema_file.nema_file_id, vw_nema_file.client_id,
		nema_link.nema_link_id, nema_link.link_diameter, nema_link.height, nema_link.azimuth
	FROM nema_link INNER JOIN vw_nema_file ON nema_link.nema_file_id = vw_nema_file.nema_file_id;


