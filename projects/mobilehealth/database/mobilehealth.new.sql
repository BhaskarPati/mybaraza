---Project Database File

-- CREATE EXTENSION tablefunc;

CREATE TABLE devices(
    device_id               serial primary key,
    org_id                  integer references orgs,
    device_name		        varchar(100),
    device_model            varchar(100),
    device_imei_1           varchar(20),
    device_imei_2           varchar(20),
    device_phone_1          varchar(15),
    device_phone_2          varchar(15),
    is_assigned             boolean default false,
    is_active               boolean default true
);
CREATE INDEX devices_org_id ON devices(org_id);

CREATE TABLE health_workers(
    health_worker_id        serial primary key,
    entity_id               integer references entitys,
    org_id                  integer references orgs,
    device_id               integer references devices,
    worker_name             varchar(100),
    worker_national_id      varchar(10),
    worker_mobile_num       varchar(10) NOT NULL,
    worker_pass             varchar(33),
    is_first_login          boolean default true,
    is_active               boolean default true,
    date_enrolled           timestamp default CURRENT_TIMESTAMP
);
CREATE INDEX health_workers_org_id ON health_workers(org_id);
CREATE INDEX health_workers_device_id ON health_workers(device_id);
CREATE TABLE countys(
    county_id           serial primary key,
    county_name         varchar(100)
);

INSERT INTO countys(county_id, county_name) VALUES(1, 'Nairobi');

CREATE TABLE sub_countys(
    sub_county_id           serial primary key,
    county_id               integer references countys,
    sub_county_name         varchar(100)
);
CREATE INDEX sub_countys_county_id ON sub_countys(county_id);

INSERT INTO sub_countys(sub_county_id, county_id, sub_county_name) VALUES
(1, 1, 'Kasarani'),
(2, 1, 'Makadara'),
(3, 1, 'Ruaraka');

CREATE TABLE divisions(
    division_id             serial primary key,
    sub_county_id           integer references sub_countys,
    division_name           varchar(200)
);
CREATE INDEX divisions_sub_county_id ON divisions(sub_county_id);

CREATE TABLE locations(
    location_id             serial primary key,
    division_id             integer references divisions,
    location_name           varchar(200)
);
CREATE INDEX locations_division_id ON locations(division_id);

CREATE TABLE sub_locations(
    sub_location_id         serial primary key,
    location_id             integer references divisions,
    sub_location_name       varchar(200)
);
CREATE INDEX sub_locations_location_id ON sub_locations(location_id);


CREATE TABLE villages(
    village_id              serial primary key,
    sub_location_id         integer references sub_locations,
    village_name            varchar(200)
);
CREATE INDEX villages_sub_location_id ON villages(sub_location_id);

--  DEFINITION TABLES
CREATE TABLE mother_info_defs(
    mother_info_def_id       serial primary key,
    for_515                  boolean default false,
    question                 text,
    details                  text
);

CREATE TABLE child_info_defs(
    child_info_def_id        serial primary key,
    for_515                  boolean default false,
    question                 text,
    details                  text
);

CREATE TABLE referral_info_defs(
    referral_info_def_id     serial primary key,
    for_515                  boolean default false,
    question                 text,
    details                  text
);

CREATE TABLE defaulters_info_defs(
    defaulters_info_def_id        serial primary key,
    for_515                  boolean default false,
    question                 text,
    details                  text
);

CREATE TABLE death_info_defs(
    death_info_def_id        serial primary key,
    for_515                  boolean default false,
    question                 text,
    details                  text
);


CREATE TABLE household_info_defs(
    household_info_def_id        serial primary key,
    for_515                  boolean default false,
    question                 text,
    details                  text
);

/*
ALTER TABLE mother_info_defs ADD for_515                  boolean default false;
ALTER TABLE child_info_defs ADD for_515                  boolean default false;
ALTER TABLE referral_info_defs ADD for_515                  boolean default false;
ALTER TABLE defaulters_info_defs ADD for_515                  boolean default false;
ALTER TABLE death_info_defs ADD for_515                  boolean default false;
ALTER TABLE household_info_defs ADD for_515                  boolean default false;

*/




CREATE TABLE surveys(
    survey_id           serial primary key,
    org_id              integer references orgs,
    health_worker_id    integer references health_workers,
    village_id          integer references villages,
    household_number    varchar(100),
    household_member    varchar(225),
    survey_time         timestamp default CURRENT_TIMESTAMP,
    location_lat        varchar(30),
    location_lng	    varchar(30),
    remarks             text,
    supervisor_remarks  text,
    survey_status       integer not null default 0, -- 0 not approved, 1 approved, 2 returned, 3 redone
    return_reason       text
);


CREATE INDEX surveys_org_id ON surveys(org_id);
CREATE INDEX surveys_health_worker_id ON surveys(health_worker_id);
CREATE INDEX surveys_village_id ON surveys(village_id);


CREATE TABLE survey_mother(
    survey_mother_id        serial primary key,
    survey_id               integer references surveys,
    mother_info_def_id      integer references mother_info_defs,
    response                integer
);

CREATE TABLE survey_child(
    survey_child_id        serial primary key,
    survey_id              integer references surveys,
    child_info_def_id     integer references child_info_defs,
    response               integer
);

CREATE TABLE survey_referrals(
    survey_referral_id          serial primary key,
    survey_id                   integer references surveys,
    referral_info_defs_id       integer references referral_info_defs,
    response                    varchar(225)
);



CREATE TABLE survey_defaulters(
    survey_defaulter_id         serial primary key,
    survey_id                   integer references surveys,
    defaulters_info_def_id      integer references defaulters_info_defs,
    response                    integer
);

CREATE TABLE survey_death(
    survey_death_id             serial primary key,
    survey_id                   integer references surveys,
    death_info_def_id           integer references death_info_defs,
    response                    varchar(225)
);


CREATE TABLE survey_household(
    survey_household_id    serial primary key,
    survey_id              integer references surveys,
    household_info_def_id  integer references household_info_defs,
    response               integer
);

-- FORM  515
CREATE TABLE surveys_515(
    surveys_515_id       serial primary key,
    org_id               integer references orgs,
    village_id           integer references villages,
    CHU_Name 		     varchar(225),
    MCLU_Code		     varchar(225),
    link_facility		 varchar(225),
    CHEW_name		     varchar(225),
    no_of_chvs		     integer default 0,
    total_chws_reported  integer default 0,
    start_date           date not null,
    end_date             date not null,
    survey_date          timestamp default CURRENT_TIMESTAMP
);

-- DROP TABLE surveys_515_details;
CREATE TABLE surveys_515_details(
    surveys_515_detail_id   serial primary key,
    surveys_515_id          integer references surveys_515,
    org_id                  integer references orgs,
    indicator_1			    integer NOT NULL default 0,
    indicator_2			    integer NOT NULL default 0,
    indicator_3	            integer NOT NULL default 0,
    indicator_4	            integer NOT NULL default 0,
    indicator_5             integer NOT NULL default 0,
    indicator_6	            integer NOT NULL default 0,
    indicator_7	            integer NOT NULL default 0,
    indicator_8	            integer NOT NULL default 0,
    indicator_9			    integer NOT NULL default 0,
    indicator_10			integer NOT NULL default 0,
    indicator_11			integer NOT NULL default 0,
    indicator_12			integer NOT NULL default 0,
    indicator_13			integer NOT NULL default 0,
    indicator_14			integer NOT NULL default 0,
    indicator_15			integer NOT NULL default 0,
    indicator_16			integer NOT NULL default 0,
    indicator_17			integer NOT NULL default 0,
    indicator_18			integer NOT NULL default 0,
    indicator_19			integer NOT NULL default 0,
    indicator_20			integer NOT NULL default 0,
    indicator_21			integer NOT NULL default 0,
    indicator_22			integer NOT NULL default 0,
    indicator_23			integer NOT NULL default 0,
    indicator_24			integer NOT NULL default 0,
    indicator_25			integer NOT NULL default 0,
    indicator_26			integer NOT NULL default 0,
    indicator_27			integer NOT NULL default 0,
    indicator_28			integer NOT NULL default 0,
    indicator_29			integer NOT NULL default 0,
    indicator_30			integer NOT NULL default 0,
    indicator_31			integer NOT NULL default 0,
    indicator_32			integer NOT NULL default 0,
    indicator_33			integer NOT NULL default 0,
    indicator_34			integer NOT NULL default 0,
    indicator_35			integer NOT NULL default 0,
    indicator_36			integer NOT NULL default 0,
    indicator_37			integer NOT NULL default 0,
    indicator_38			integer NOT NULL default 0,
    indicator_39			integer NOT NULL default 0,
    indicator_40			integer NOT NULL default 0,
    indicator_41			integer NOT NULL default 0,
    indicator_42			integer NOT NULL default 0,
    indicator_43			integer NOT NULL default 0,
    indicator_44			integer NOT NULL default 0,
    indicator_45			integer NOT NULL default 0,
    indicator_46			integer NOT NULL default 0,
    indicator_47			integer NOT NULL default 0,
    indicator_48			integer NOT NULL default 0,
    indicator_49			integer NOT NULL default 0,
    indicator_50			integer NOT NULL default 0,
    indicator_51			integer NOT NULL default 0,
    indicator_52			integer NOT NULL default 0,
    indicator_53			integer NOT NULL default 0,
    indicator_54			integer NOT NULL default 0,
    indicator_55			integer NOT NULL default 0,
    indicator_56			integer NOT NULL default 0,
    indicator_57			integer NOT NULL default 0,
    indicator_58			integer NOT NULL default 0,
    indicator_59			integer NOT NULL default 0,
    indicator_60			integer NOT NULL default 0,
    indicator_61			integer NOT NULL default 0,
    indicator_62			integer NOT NULL default 0,
    indicator_63			integer NOT NULL default 0,
    indicator_64			integer NOT NULL default 0,
    indicator_65			integer NOT NULL default 0,
    indicator_66			varchar(5),
    indicator_67_a			varchar(5),
    indicator_67_b			varchar(5),
    indicator_67_c			varchar(5),
    indicator_67_d			varchar(5),
    indicator_67_e			varchar(5),
    indicator_67_f			varchar(5),
    indicator_67_g			varchar(5),
    indicator_67_h			varchar(5),
    indicator_67_i			varchar(5),
    indicator_67_j			varchar(5),
    indicator_67_k			varchar(5),
    remarks                 text
);




-- FORM 100
-- DROP TABLE survey_100;

CREATE TABLE link_health_facilities(
    link_health_facility_id     serial primary key,
    org_id                      integer references orgs,
    sub_location_id             integer references sub_locations,
    link_health_facility_name   varchar(225),
    details                     text
);
-- DROP TABLE survey_100;
CREATE TABLE survey_100(
    survey_100_id                   serial primary key,
    org_id                          integer references orgs,
    health_worker_id                integer references health_workers,
    village_id                      integer references villages,
    link_health_facility_id         integer references link_health_facilities,
    form_serial                     varchar(10),
    patient_gender                  varchar(2),
    patient_name                    varchar(200),
    patient_age_type                varchar(1),
    patient_age                     varchar(5),
    community_healt_unit            varchar(200),
    referral_reason                 varchar(200),
    treatment                       text,
    comments                        text,
    community_unit                  varchar(200),
    receiving_officer_name          varchar(200),
    receiving_officer_profession    varchar(200),
    health_facility_name            varchar(200),
    action_taken                    text,
    receiving_officer_date          date,
    receiving_officer_time          time,
    referral_time                   timestamp default CURRENT_TIMESTAMP
);

ALTER TABLE survey_100 ALTER COLUMN patient_age  TYPE varchar(5);



-- VIEWS

CREATE VIEW vw_sub_countys AS
	SELECT countys.county_id, countys.county_name, sub_countys.sub_county_id, sub_countys.sub_county_name
	FROM sub_countys
	INNER JOIN countys ON sub_countys.county_id = countys.county_id;

CREATE VIEW vw_sub_locations AS
	SELECT countys.county_id, countys.county_name,
    sub_countys.sub_county_id, sub_countys.sub_county_name,
    divisions.division_id, divisions.division_name,
    locations.location_id , locations.location_name,
    sub_locations.sub_location_id, sub_locations.sub_location_name
	FROM sub_locations
    INNER JOIN locations ON locations.location_id = sub_locations.location_id
	INNER JOIN divisions ON divisions.division_id = locations.division_id
    INNER JOIN sub_countys ON sub_countys.sub_county_id = divisions.sub_county_id
	INNER JOIN countys ON countys.county_id = sub_countys.county_id;

CREATE VIEW vw_villages AS
	SELECT
		countys.county_id, countys.county_name,
		sub_countys.sub_county_id, sub_countys.sub_county_name,
		divisions.division_id, divisions.division_name,
		locations.location_id , locations.location_name,
		sub_locations.sub_location_id, sub_locations.sub_location_name,
		villages.village_id, villages.village_name
	FROM villages
	INNER JOIN sub_locations ON sub_locations.sub_location_id = villages.sub_location_id
	INNER JOIN locations ON locations.location_id = sub_locations.location_id
	INNER JOIN divisions ON divisions.division_id = locations.division_id
	INNER JOIN sub_countys ON sub_countys.sub_county_id = divisions.sub_county_id
	INNER JOIN countys ON countys.county_id = sub_countys.county_id;

CREATE VIEW vw_devices AS
	SELECT orgs.org_id, orgs.org_name,
	devices.device_id, devices.device_name, devices.device_model, devices.device_imei_1, devices.device_imei_2, devices.device_phone_1, devices.device_phone_2,
	devices.is_assigned, devices.is_active
	FROM devices
	INNER JOIN orgs ON devices.org_id = orgs.org_id;

CREATE VIEW vw_health_workers AS
	SELECT devices.device_id, devices.device_name, entitys.entity_id, entitys.entity_name, orgs.org_id, orgs.org_name,
	health_workers.health_worker_id, health_workers.worker_name, health_workers.worker_national_id, health_workers.worker_mobile_num,
	health_workers.worker_pass, health_workers.is_first_login, health_workers.is_active, health_workers.date_enrolled
	FROM health_workers
	INNER JOIN devices ON health_workers.device_id = devices.device_id
	INNER JOIN entitys ON health_workers.entity_id = entitys.entity_id
	INNER JOIN orgs ON health_workers.org_id = orgs.org_id;

-- FORM 514 =======================================================
-- DROP VIEW vw_surveys;
CREATE VIEW vw_surveys AS
	SELECT health_workers.health_worker_id, health_workers.worker_name,
	orgs.org_id, orgs.org_name,
	vw_villages.county_id, vw_villages.county_name,
	vw_villages.sub_county_id, vw_villages.sub_county_name,
	vw_villages.division_id, vw_villages.division_name,
	vw_villages.location_id, vw_villages.location_name,
	vw_villages.sub_location_id, vw_villages.sub_location_name,
        vw_villages.village_id, vw_villages.village_name,
	surveys.survey_id, surveys.household_number, surveys.household_member,
	surveys.survey_time, surveys.location_lat, surveys.location_lng, surveys.remarks,
	surveys.survey_status,surveys.return_reason, surveys.supervisor_remarks
	FROM surveys
	INNER JOIN health_workers ON surveys.health_worker_id = health_workers.health_worker_id
	INNER JOIN orgs ON surveys.org_id = orgs.org_id
	INNER JOIN vw_villages ON vw_villages.village_id = surveys.village_id;

-- DROP VIEW vw_survey_mother;
CREATE VIEW vw_survey_mother AS
	SELECT mother_info_defs.mother_info_def_id, mother_info_defs.for_515, mother_info_defs.question, mother_info_defs.details ,
	surveys.survey_id,  survey_mother.survey_mother_id, survey_mother.response,
	(CASE survey_mother.response WHEN '1' THEN 'YES'
		WHEN '2' THEN 'NO'
		WHEN '3' THEN 'N/A' ELSE 'N/A' END ) AS response_name

	FROM survey_mother
	INNER JOIN mother_info_defs ON survey_mother.mother_info_def_id = mother_info_defs.mother_info_def_id
	INNER JOIN surveys ON survey_mother.survey_id = surveys.survey_id;


-- DROP VIEW vw_survey_child;
CREATE VIEW vw_survey_child AS
	SELECT child_info_defs.child_info_def_id, child_info_defs.for_515, child_info_defs.question,child_info_defs.details,
	surveys.survey_id, survey_child.survey_child_id, survey_child.response,
    (CASE survey_child.response WHEN '1' THEN 'YES'
            WHEN '2' THEN 'NO'
            WHEN '3' THEN 'N/A' ELSE 'N/A' END ) AS response_name
	FROM survey_child
	INNER JOIN child_info_defs ON survey_child.child_info_def_id = child_info_defs.child_info_def_id
	INNER JOIN surveys ON survey_child.survey_id = surveys.survey_id;


-- DROP VIEW vw_survey_referrals ;
CREATE VIEW vw_survey_referrals AS
	SELECT referral_info_defs.referral_info_def_id, referral_info_defs.for_515, referral_info_defs.question, referral_info_defs.details ,
	surveys.survey_id,  survey_referrals.survey_referral_id, survey_referrals.referral_info_defs_id, survey_referrals.response,
	(CASE survey_referrals.response WHEN '1' THEN 'YES'
            WHEN '2' THEN 'NO'
            WHEN '3' THEN 'N/A' ELSE survey_referrals.response END ) AS response_name
	FROM survey_referrals
	INNER JOIN referral_info_defs ON survey_referrals.referral_info_defs_id = referral_info_defs.referral_info_def_id
	INNER JOIN surveys ON survey_referrals.survey_id = surveys.survey_id;

-- DROP VIEW vw_survey_defaulters;
CREATE VIEW vw_survey_defaulters AS
	SELECT defaulters_info_defs.defaulters_info_def_id, defaulters_info_defs.for_515, defaulters_info_defs.question, defaulters_info_defs.details,
	surveys.survey_id, survey_defaulters.survey_defaulter_id, survey_defaulters.response,
	(CASE survey_defaulters.response WHEN '1' THEN 'YES'
		WHEN '2' THEN 'NO'
		WHEN '3' THEN 'N/A' ELSE 'N/A' END ) AS response_name
	FROM survey_defaulters
	INNER JOIN defaulters_info_defs ON survey_defaulters.defaulters_info_def_id = defaulters_info_defs.defaulters_info_def_id
	INNER JOIN surveys ON survey_defaulters.survey_id = surveys.survey_id;

-- DROP VIEW vw_survey_death;
CREATE VIEW vw_survey_death AS
	SELECT death_info_defs.death_info_def_id, death_info_defs.for_515,  death_info_defs.question, death_info_defs.details,
	surveys.survey_id, survey_death.survey_death_id, survey_death.response
	FROM survey_death
	INNER JOIN death_info_defs ON survey_death.death_info_def_id = death_info_defs.death_info_def_id
	INNER JOIN surveys ON survey_death.survey_id = surveys.survey_id;
 -- DROP VIEW vw_survey_household ;
CREATE VIEW vw_survey_household AS
	SELECT household_info_defs.household_info_def_id,  household_info_defs.for_515, household_info_defs.question, household_info_defs.details,
	surveys.survey_id, survey_household.survey_household_id, survey_household.response,
    (CASE survey_household.response WHEN '1' THEN 'YES'
            WHEN '2' THEN 'NO'
            WHEN '3' THEN 'N/A' ELSE 'N/A' END ) AS response_name
	FROM survey_household
	INNER JOIN household_info_defs ON survey_household.household_info_def_id = household_info_defs.household_info_def_id
	INNER JOIN surveys ON survey_household.survey_id = surveys.survey_id;

-- FORM 515 =======================================================

CREATE VIEW vw_surveys_515 AS
	SELECT orgs.org_id, orgs.org_name,
	       vw_villages.county_id, vw_villages.county_name,
           vw_villages.sub_county_id, vw_villages.sub_county_name,
           vw_villages.division_id, vw_villages.division_name,
           vw_villages.location_id, vw_villages.location_name,
           vw_villages.sub_location_id, vw_villages.sub_location_name,
           vw_villages.village_id, vw_villages.village_name,
	        surveys_515.surveys_515_id, surveys_515.chu_name, surveys_515.mclu_code,
	        surveys_515.link_facility, surveys_515.chew_name,
	        surveys_515.no_of_chvs, surveys_515.total_chws_reported, surveys_515.start_date, surveys_515.end_date,
            surveys_515.survey_date
	FROM surveys_515
	INNER JOIN orgs ON surveys_515.org_id = orgs.org_id
	INNER JOIN vw_villages ON surveys_515.village_id = vw_villages.village_id;


    CREATE VIEW vw_surveys_515_details AS
    	SELECT orgs.org_id, orgs.org_name,
    	vw_surveys_515.county_id, vw_surveys_515.county_name,
    	vw_surveys_515.sub_county_id, vw_surveys_515.sub_county_name,
    	vw_surveys_515.division_id, vw_surveys_515.division_name,
    	vw_surveys_515.location_id, vw_surveys_515.location_name,
    	vw_surveys_515.sub_location_id, vw_surveys_515.sub_location_name,
    	vw_surveys_515.village_id, vw_surveys_515.village_name,
    	vw_surveys_515.surveys_515_id, vw_surveys_515.chu_name,
    	vw_surveys_515.mclu_code, vw_surveys_515.link_facility,
    	 vw_surveys_515.chew_name, vw_surveys_515.no_of_chvs, vw_surveys_515.total_chws_reported,
    	 vw_surveys_515.start_date, vw_surveys_515.end_date, vw_surveys_515.survey_date,
    	surveys_515_details.surveys_515_detail_id, surveys_515_details.indicator_1,
        surveys_515_details.indicator_2, surveys_515_details.indicator_3, surveys_515_details.indicator_4, surveys_515_details.indicator_5, surveys_515_details.indicator_6,
        surveys_515_details.indicator_7, surveys_515_details.indicator_8, surveys_515_details.indicator_9, surveys_515_details.indicator_10, surveys_515_details.indicator_11,
        surveys_515_details.indicator_12, surveys_515_details.indicator_13, surveys_515_details.indicator_14, surveys_515_details.indicator_15, surveys_515_details.indicator_16,
        surveys_515_details.indicator_17, surveys_515_details.indicator_18, surveys_515_details.indicator_19, surveys_515_details.indicator_20, surveys_515_details.indicator_21,
        surveys_515_details.indicator_22, surveys_515_details.indicator_23, surveys_515_details.indicator_24, surveys_515_details.indicator_25, surveys_515_details.indicator_26, surveys_515_details.indicator_27,
         surveys_515_details.indicator_28, surveys_515_details.indicator_29, surveys_515_details.indicator_30, surveys_515_details.indicator_31, surveys_515_details.indicator_32, surveys_515_details.indicator_33,
         surveys_515_details.indicator_34, surveys_515_details.indicator_35, surveys_515_details.indicator_36, surveys_515_details.indicator_37, surveys_515_details.indicator_38, surveys_515_details.indicator_39,
        surveys_515_details.indicator_40, surveys_515_details.indicator_41, surveys_515_details.indicator_42, surveys_515_details.indicator_43, surveys_515_details.indicator_44, surveys_515_details.indicator_45,
         surveys_515_details.indicator_46, surveys_515_details.indicator_47, surveys_515_details.indicator_48, surveys_515_details.indicator_49, surveys_515_details.indicator_50, surveys_515_details.indicator_51,
        surveys_515_details.indicator_52, surveys_515_details.indicator_53, surveys_515_details.indicator_54, surveys_515_details.indicator_55, surveys_515_details.indicator_56, surveys_515_details.indicator_57,
         surveys_515_details.indicator_58, surveys_515_details.indicator_59, surveys_515_details.indicator_60, surveys_515_details.indicator_61, surveys_515_details.indicator_62, surveys_515_details.indicator_63,
         surveys_515_details.indicator_64, surveys_515_details.indicator_65, surveys_515_details.indicator_66, surveys_515_details.indicator_67_a, surveys_515_details.indicator_67_b,
        surveys_515_details.indicator_67_c, surveys_515_details.indicator_67_d, surveys_515_details.indicator_67_e, surveys_515_details.indicator_67_f, surveys_515_details.indicator_67_g,
        surveys_515_details.indicator_67_h, surveys_515_details.indicator_67_i, surveys_515_details.indicator_67_j, surveys_515_details.indicator_67_k, surveys_515_details.remarks
    	FROM surveys_515_details
    	INNER JOIN orgs ON surveys_515_details.org_id = orgs.org_id
    	INNER JOIN vw_surveys_515 ON surveys_515_details.surveys_515_id = vw_surveys_515.surveys_515_id;


-- FORM 100 =======================================================

-- DROP VIEW vw_survey_100 ;

CREATE VIEW vw_survey_100 AS
    SELECT health_workers.health_worker_id, health_workers.worker_name, health_workers.worker_national_id, health_workers.worker_mobile_num,
    link_health_facilities.link_health_facility_id, link_health_facilities.link_health_facility_name,
    orgs.org_id, orgs.org_name,
    vw_villages.county_id, vw_villages.county_name,
    vw_villages.sub_county_id, vw_villages.sub_county_name,
    vw_villages.division_id, vw_villages.division_name,
    vw_villages.location_id, vw_villages.location_name,
    vw_villages.sub_location_id, vw_villages.sub_location_name,
    vw_villages.village_id, vw_villages.village_name,
    survey_100.survey_100_id, survey_100.form_serial, survey_100.patient_gender,
    survey_100.patient_name, survey_100.patient_age_type, survey_100.patient_age, survey_100.community_healt_unit, survey_100.referral_reason, survey_100.treatment,
    survey_100.comments, survey_100.community_unit, survey_100.receiving_officer_name, survey_100.receiving_officer_profession,
    survey_100.health_facility_name, survey_100.action_taken, survey_100.receiving_officer_date, survey_100.receiving_officer_time, survey_100.referral_time
    FROM survey_100
    INNER JOIN health_workers ON survey_100.health_worker_id = health_workers.health_worker_id
    INNER JOIN link_health_facilities ON survey_100.link_health_facility_id = link_health_facilities.link_health_facility_id
    INNER JOIN orgs ON survey_100.org_id = orgs.org_id
    INNER JOIN vw_villages ON vw_villages.village_id = survey_100.village_id;






-- FUNCTIONS
CREATE OR REPLACE FUNCTION ins_health_workers() RETURNS trigger AS $$
DECLARE
BEGIN
    UPDATE devices SET is_assigned = true WHERE device_id = NEW.device_id;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_health_workers  AFTER INSERT ON health_workers
    FOR EACH ROW EXECUTE PROCEDURE ins_health_workers();

CREATE OR REPLACE FUNCTION upd_514(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	msg 		varchar(120);
BEGIN
    msg := 'Error Updating ';
    UPDATE surveys SET survey_status = CAST($3 as int)  WHERE survey_id = CAST($1 as int);
    msg := '<br/> Report ' || CAST($1 as int) ||  ' Actioned Successfully';

	RETURN msg;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION ins_surveys_515() RETURNS trigger AS $$
DECLARE
BEGIN

    INSERT INTO surveys_515_details(surveys_515_id,org_id ) VALUES (NEW.surveys_515_id, NEW.org_id);

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_surveys_515 AFTER INSERT ON surveys_515
    FOR EACH ROW EXECUTE PROCEDURE ins_surveys_515();



-- ===================================

/*select * from vw_surveys_515_details WHERE sub_county_id = 1 AND
(start_date >= '2015-01-01':: date AND start_date <= '2015-01-01':: date)
AND (end_date >= '2015-12-31':: date AND end_date <= '2015-12-31':: date)


SELECT
SUM(indicator_1) AS indicator_1 ,SUM(indicator_2) AS indicator_2 ,SUM(indicator_3) AS indicator_3 ,
SUM(indicator_4) AS indicator_4 ,SUM(indicator_5) AS indicator_5 ,SUM(indicator_6) AS indicator_6 ,SUM(indicator_7) AS indicator_7 ,
SUM(indicator_8) AS indicator_8 ,SUM(indicator_9) AS indicator_9 ,SUM(indicator_10) AS indicator_10 ,SUM(indicator_11) AS indicator_11 ,
SUM(indicator_12) AS indicator_12 ,SUM(indicator_13) AS indicator_13 ,SUM(indicator_14) AS indicator_14 ,SUM(indicator_15) AS indicator_15 ,
SUM(indicator_16) AS indicator_16 ,SUM(indicator_17) AS indicator_17 ,SUM(indicator_18) AS indicator_18 ,SUM(indicator_19) AS indicator_19 ,
SUM(indicator_20) AS indicator_20 ,SUM(indicator_21) AS indicator_21 ,SUM(indicator_22) AS indicator_22 ,SUM(indicator_23) AS indicator_23 ,
SUM(indicator_24) AS indicator_24 ,SUM(indicator_25) AS indicator_25 ,SUM(indicator_26) AS indicator_26 ,SUM(indicator_27) AS indicator_27 ,
SUM(indicator_28) AS indicator_28 ,SUM(indicator_29) AS indicator_29 ,SUM(indicator_30) AS indicator_30 ,SUM(indicator_31) AS indicator_31 ,
SUM(indicator_32) AS indicator_32 ,SUM(indicator_33) AS indicator_33 ,SUM(indicator_34) AS indicator_34 ,SUM(indicator_35) AS indicator_35 ,
SUM(indicator_36) AS indicator_36 ,SUM(indicator_37) AS indicator_37 ,SUM(indicator_38) AS indicator_38 ,SUM(indicator_39) AS indicator_39 ,
SUM(indicator_40) AS indicator_40 ,SUM(indicator_41) AS indicator_41 ,SUM(indicator_42) AS indicator_42 ,SUM(indicator_43) AS indicator_43 ,
SUM(indicator_44) AS indicator_44 ,SUM(indicator_45) AS indicator_45 ,SUM(indicator_46) AS indicator_46 ,SUM(indicator_47) AS indicator_47 ,
SUM(indicator_48) AS indicator_48 ,SUM(indicator_49) AS indicator_49 ,SUM(indicator_50) AS indicator_50 ,SUM(indicator_51) AS indicator_51 ,
SUM(indicator_52) AS indicator_52 ,SUM(indicator_53) AS indicator_53 ,SUM(indicator_54) AS indicator_54 ,SUM(indicator_55) AS indicator_55 ,
SUM(indicator_56) AS indicator_56 ,SUM(indicator_57) AS indicator_57 ,SUM(indicator_58) AS indicator_58 ,SUM(indicator_59) AS indicator_59 ,
SUM(indicator_60) AS indicator_60 ,SUM(indicator_61) AS indicator_61 ,SUM(indicator_62) AS indicator_62 ,SUM(indicator_63) AS indicator_63 ,
SUM(indicator_64) AS indicator_64 ,SUM(indicator_65) AS indicator_65

FROM vw_surveys_515_details

WHERE sub_county_id = 1
AND*/
