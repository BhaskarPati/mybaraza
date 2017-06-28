---Project Database File

CREATE EXTENSION tablefunc;

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
    org_id                  integer references orgs,
    worker_name             varchar(100),
    worker_national_id      varchar(10),
    worker_mobile_num       varchar(10) NOT NULL,
    worker_pass             varchar(33),
    is_first_login          boolean default true,
    is_active               boolean default true,
    device_id               integer references devices,
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
    location_name           varchar(200)
);
CREATE INDEX sub_locations_location_id ON sub_locations(location_id);


CREATE TABLE villages(
    village_id              serial primary key,
    sub_location_id         integer references sub_locations,
    village_name           varchar(200)
);
CREATE INDEX villages_sub_location_id ON villages(sub_location_id);

-- CHANGE FROM HERE




CREATE TABLE mother_info_defs(
    mother_info_def_id       serial primary key,
    question                 text,
    details                  text
);

CREATE TABLE child_info_defs(
    child_info_def_id        serial primary key,
    question                 text,
    details                  text
);

CREATE TABLE referral_info_defs(
    referral_info_def_id     serial primary key,
    question                 text,
    details                  text
);

CREATE TABLE defaulters_info_defs(
    defaulters_info_def_id        serial primary key,
    question                 text,
    details                  text
);

CREATE TABLE death_info_defs(
    death_info_def_id        serial primary key,
    question                 text,
    details                  text
);


CREATE TABLE household_info_defs(
    household_info_def_id        serial primary key,
    question                 text,
    details                  text
);

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
    survey_status       integer not null default 0, -- 0 not approved, 1 approved, 2 returned, 3 redone
    return_reason       text
);



CREATE TABLE survey_mother(
    survey_mother_id        serial primary key,
    survey_id               integer references surveys,
    mother_info_def_id      integer references mother_info_defs,
    response                integer
);

CREATE TABLE survey_child(
    survey_child_id        serial primary key,
    survey_id              integer references surveys,
    household_info_def_id      integer references child_info_defs,
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

/*
DELETE FROM survey_mother;
DELETE FROM survey_child;
DELETE FROM survey_referrals;
DELETE FROM survey_defaulters;
DELETE FROM survey_death;
DELETE FROM survey_household;
DELETE FROM surveys;*/

-- MOH 515 ----------------------------------------------
/*
CREATE TABLE demograpics_515_defs(
    demograpics_515_def_id       serial primary key,
    demograpics_question                 text,
    demograpics_details                  text
);

CREATE TABLE household_515_defs(
    household_515_def_id        serial primary key,
    household_question                 text,
    household_details                  text
);

CREATE TABLE motherchild_515_defs(
    motherchild_515_def_id        serial primary key,
    motherchild_question                 text,
    motherchild_details                  text
);

CREATE TABLE treatment_515_defs(
    treatment_515_def_id        serial primary key,
    treatment_question                 text,
    treatment_details                  text
);

CREATE TABLE referrals_515_defs(
    referrals_515_defs_id        serial primary key,
    referrals_question                 text,
    referrals_details                  text
);

CREATE TABLE defaulters_515_defs(
    defaulters_515_def_id        serial primary key,
    defaulters_question                 text,
    defaulters_details                  text
);

CREATE TABLE death_515_defs(
    death_515_def_id        serial primary key,
    death_question                 text,
    death_details                  text
);

CREATE TABLE commodities_515_defs(
    commodity_515_def_id        serial primary key,
    commodity_question                 text,
    commodity_details                  text
);

CREATE TABLE others_515_defs(
    others_515_def_id        serial primary key,
    others_question                 text,
    others_details                  text
);

*/

CREATE TABLE indicators_defs(
    indicators_def_id          serial primary key,
    indicator                  varchar(255),
    indicator_details          text
);

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
    surveys_515_detail_id       serial primary key,
    surveys_515_id              integer references surveys_515,
    org_id               integer references orgs,
    indicator_1			integer NOT NULL default 0,
    indicator_2			integer NOT NULL default 0,
    indicator_3			integer NOT NULL default 0,
    indicator_4			integer NOT NULL default 0,
    indicator_5			integer NOT NULL default 0,
    indicator_6			integer NOT NULL default 0,
    indicator_7			integer NOT NULL default 0,
    indicator_8			integer NOT NULL default 0,
    indicator_9			integer NOT NULL default 0,
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


-- DROP TABLE survey_100;
CREATE TABLE survey_100(
    survey_100_id                   serial primary key,
    org_id                          integer references orgs,

    health_worker_id                integer references health_workers,
    form_serial                     varchar(10),
    patient_gender                  varchar(2),
    patient_name                    varchar(200),
    patient_age                     varchar(3),
    community_healt_unit            varchar(200),
    link_health_facility            varchar(200),
    referral_reason                 varchar(200),
    treatment                       text,
    comments                        text,
    sub_location                    varchar(200),
    village                         varchar(200),
    community_unit                  varchar(200),
    receiving_officer_name          varchar(200),
    receiving_officer_profession    varchar(200),
    health_facility_name            varchar(200),
    action_taken                    text,
    receiving_officer_date          date,
    receiving_officer_time          time,
    referral_time                   timestamp default CURRENT_TIMESTAMP
);



CREATE OR REPLACE FUNCTION ins_surveys_515() RETURNS trigger AS $$
DECLARE
BEGIN

    INSERT INTO surveys_515_details(surveys_515_id,org_id ) VALUES (NEW.surveys_515_id, NEW.org_id);

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_surveys_515 AFTER INSERT ON surveys_515
    FOR EACH ROW EXECUTE PROCEDURE ins_surveys_515();


-- FUNCTIO TO change status for 514 surveys

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











/*
CREATE TABLE survey_515_demograpics(
    survey_515_demograpic_id    serial primary key,
    surveys_515_id              integer references surveys_515,
    demograpics_515_def_id      integer references demograpics_515_defs,
    response                    integer
);


CREATE TABLE survey_515_households(
    survey_515_household_id     serial primary key,
    surveys_515_id              integer references surveys_515,
    household_515_def_id        integer references  household_515_defs,
    response                    integer
);

CREATE TABLE survey_515_motherchild(
    survey_515_motherchild_id      serial primary key,
    surveys_515_id              integer references surveys_515,
    motherchild_515_def_id      integer references motherchild_515_defs,
    response                    integer
);

CREATE TABLE survey_515_treatments(
    survey_515_treatment_id        serial primary key,
    surveys_515_id              integer references surveys_515,
    treatment_515_def_id        integer references treatment_515_defs,
    response                    integer
);

CREATE TABLE survey_515_referrals(
    survey_515_referral_id        serial primary key,
    surveys_515_id              integer references surveys_515,
    referrals_515_defs_id       integer references  referrals_515_defs,
    response                    integer
);

CREATE TABLE survey_515_defaulters(
    survey_515_defaulter_id        serial primary key,
    surveys_515_id              integer references surveys_515,
    defaulters_515_def_id       integer references defaulters_515_defs,
    response                    integer
);

CREATE TABLE survey_515_death(
    survey_515_death_id            serial primary key,
    surveys_515_id              integer references surveys_515,
    death_515_def_id            integer references death_515_defs,
    response                    integer
);

CREATE TABLE survey_515_commodities(
    survey_515_commodity_id      serial primary key,
    surveys_515_id              integer references surveys_515,
    commodity_515_def_id        integer references commodities_515_defs,
    response                    integer
);

CREATE TABLE survey_515_others(
    survey_515_other_id           serial primary key,
    surveys_515_id              integer references surveys_515,
    others_515_def_id           integer references others_515_defs,
    response                    integer
);
*/


CREATE VIEW vw_devices AS
	SELECT orgs.org_id, orgs.org_name, devices.device_id, devices.device_model, devices.device_imei_1, devices.device_imei_2, devices.is_active, devices.device_name
	FROM devices
	INNER JOIN orgs ON devices.org_id = orgs.org_id;

CREATE VIEW vw_health_workers AS
	SELECT orgs.org_id, orgs.org_name,
	health_workers.health_worker_id, health_workers.worker_name, health_workers.worker_national_id, health_workers.worker_mobile_num, health_workers.worker_pass, health_workers.is_first_login, health_workers.is_active, health_workers.date_enrolled,
	devices.device_id, devices.device_name, devices.device_model, devices.device_imei_1, devices.device_imei_2, devices.is_active AS device_active
	FROM health_workers
	INNER JOIN devices ON health_workers.device_id = devices.device_id
	INNER JOIN orgs ON health_workers.org_id = orgs.org_id;

CREATE VIEW vw_sub_countys AS
	SELECT countys.county_id, countys.county_name, sub_countys.sub_county_id, sub_countys.sub_county_name
	FROM sub_countys
	INNER JOIN countys ON sub_countys.county_id = countys.county_id;



-- DROP VIEW vw_surveys;
CREATE VIEW vw_surveys AS
	SELECT health_workers.health_worker_id, health_workers.worker_name,
	orgs.org_id, orgs.org_name,
	countys.county_id, countys.county_name,
	sub_countys.sub_county_id, sub_countys.sub_county_name, surveys.survey_id, surveys.village_name, surveys.household_number, surveys.household_member, surveys.survey_time, surveys.location_lat, surveys.location_lng, surveys.remarks, surveys.survey_status,surveys.return_reason
	FROM surveys
	INNER JOIN health_workers ON surveys.health_worker_id = health_workers.health_worker_id
	INNER JOIN orgs ON surveys.org_id = orgs.org_id
	INNER JOIN sub_countys ON surveys.sub_county_id = sub_countys.sub_county_id
	INNER JOIN countys ON sub_countys.county_id = countys.county_id;


-- DROP VIEW vw_survey_mother;
CREATE VIEW vw_survey_mother AS
	SELECT mother_info_defs.mother_info_def_id, mother_info_defs.question, mother_info_defs.details ,
	surveys.survey_id,  survey_mother.survey_mother_id, survey_mother.response,
	(CASE survey_mother.response WHEN '1' THEN 'YES'
		WHEN '2' THEN 'NO'
		WHEN '3' THEN 'N/A' ELSE 'N/A' END ) AS response_name

	FROM survey_mother
	INNER JOIN mother_info_defs ON survey_mother.mother_info_def_id = mother_info_defs.mother_info_def_id
	INNER JOIN surveys ON survey_mother.survey_id = surveys.survey_id;


-- DROP VIEW vw_survey_child;
CREATE VIEW vw_survey_child AS
	SELECT child_info_defs.child_info_def_id, child_info_defs.question,child_info_defs.details,
	surveys.survey_id, survey_child.survey_child_id, survey_child.response,
    (CASE survey_child.response WHEN '1' THEN 'YES'
            WHEN '2' THEN 'NO'
            WHEN '3' THEN 'N/A' ELSE 'N/A' END ) AS response_name
	FROM survey_child
	INNER JOIN child_info_defs ON survey_child.child_info_def_id = child_info_defs.child_info_def_id
	INNER JOIN surveys ON survey_child.survey_id = surveys.survey_id;


-- DROP VIEW vw_survey_referrals ;
CREATE VIEW vw_survey_referrals AS
	SELECT referral_info_defs.referral_info_def_id, referral_info_defs.question, referral_info_defs.details ,
	surveys.survey_id,  survey_referrals.survey_referral_id, survey_referrals.referral_info_defs_id, survey_referrals.response,
	(CASE survey_referrals.response WHEN '1' THEN 'YES'
            WHEN '2' THEN 'NO'
            WHEN '3' THEN 'N/A' ELSE survey_referrals.response END ) AS response_name
	FROM survey_referrals
	INNER JOIN referral_info_defs ON survey_referrals.referral_info_defs_id = referral_info_defs.referral_info_def_id
	INNER JOIN surveys ON survey_referrals.survey_id = surveys.survey_id;

-- DROP VIEW vw_survey_defaulters;
CREATE VIEW vw_survey_defaulters AS
	SELECT defaulters_info_defs.defaulters_info_def_id, defaulters_info_defs.question, defaulters_info_defs.details,
	surveys.survey_id, survey_defaulters.survey_defaulter_id, survey_defaulters.response,
	(CASE survey_defaulters.response WHEN '1' THEN 'YES'
		WHEN '2' THEN 'NO'
		WHEN '3' THEN 'N/A' ELSE 'N/A' END ) AS response_name
	FROM survey_defaulters
	INNER JOIN defaulters_info_defs ON survey_defaulters.defaulters_info_def_id = defaulters_info_defs.defaulters_info_def_id
	INNER JOIN surveys ON survey_defaulters.survey_id = surveys.survey_id;

-- DROP VIEW vw_survey_death;
CREATE VIEW vw_survey_death AS
	SELECT death_info_defs.death_info_def_id, death_info_defs.question, death_info_defs.details,
	surveys.survey_id, survey_death.survey_death_id, survey_death.response
	FROM survey_death
	INNER JOIN death_info_defs ON survey_death.death_info_def_id = death_info_defs.death_info_def_id
	INNER JOIN surveys ON survey_death.survey_id = surveys.survey_id;

-- DROP VIEW vw_survey_household ;
CREATE VIEW vw_survey_household AS
	SELECT household_info_defs.household_info_def_id,  household_info_defs.question, household_info_defs.details,
	surveys.survey_id, survey_household.survey_household_id, survey_household.response,
    (CASE survey_household.response WHEN '1' THEN 'YES'
            WHEN '2' THEN 'NO'
            WHEN '3' THEN 'N/A' ELSE 'N/A' END ) AS response_name
	FROM survey_household
	INNER JOIN household_info_defs ON survey_household.household_info_def_id = household_info_defs.household_info_def_id
	INNER JOIN surveys ON survey_household.survey_id = surveys.survey_id;


CREATE VIEW vw_surveys_515_details AS
	SELECT orgs.org_id, orgs.org_name,
	surveys_515.surveys_515_id, surveys_515.chu_name, surveys_515.mclu_code, surveys_515.link_facility,
	surveys_515.chew_name, surveys_515.no_of_chvs, surveys_515.total_chws_reported, surveys_515.county,
	surveys_515.subcounty, surveys_515.division, surveys_515.location, surveys_515.sublocation, surveys_515.total_vilages,
	surveys_515.month, surveys_515.year, surveys_515.survey_date,
	surveys_515_details.indicator_1, surveys_515_details.indicator_2, surveys_515_details.indicator_3, surveys_515_details.indicator_4, surveys_515_details.indicator_5, surveys_515_details.indicator_6, surveys_515_details.indicator_7, surveys_515_details.indicator_8, surveys_515_details.indicator_9, surveys_515_details.indicator_10, surveys_515_details.indicator_11, surveys_515_details.indicator_12, surveys_515_details.indicator_13, surveys_515_details.indicator_14, surveys_515_details.indicator_15, surveys_515_details.indicator_16, surveys_515_details.indicator_17, surveys_515_details.indicator_18, surveys_515_details.indicator_19, surveys_515_details.indicator_20, surveys_515_details.indicator_21, surveys_515_details.indicator_22, surveys_515_details.indicator_23, surveys_515_details.indicator_24, surveys_515_details.indicator_25, surveys_515_details.indicator_26, surveys_515_details.indicator_27, surveys_515_details.indicator_28, surveys_515_details.indicator_29, surveys_515_details.indicator_30, surveys_515_details.indicator_31, surveys_515_details.indicator_32, surveys_515_details.indicator_33, surveys_515_details.indicator_34, surveys_515_details.indicator_35, surveys_515_details.indicator_36, surveys_515_details.indicator_37, surveys_515_details.indicator_38, surveys_515_details.indicator_39, surveys_515_details.indicator_40, surveys_515_details.indicator_41, surveys_515_details.indicator_42, surveys_515_details.indicator_43, surveys_515_details.indicator_44, surveys_515_details.indicator_45, surveys_515_details.indicator_46, surveys_515_details.indicator_47, surveys_515_details.indicator_48, surveys_515_details.indicator_49, surveys_515_details.indicator_50, surveys_515_details.indicator_51, surveys_515_details.indicator_52, surveys_515_details.indicator_53, surveys_515_details.indicator_54, surveys_515_details.indicator_55, surveys_515_details.indicator_56, surveys_515_details.indicator_57, surveys_515_details.indicator_58, surveys_515_details.indicator_59, surveys_515_details.indicator_60, surveys_515_details.indicator_61, surveys_515_details.indicator_62, surveys_515_details.indicator_63, surveys_515_details.indicator_64_a, surveys_515_details.indicator_64_b, surveys_515_details.indicator_64_c, surveys_515_details.indicator_64_d, surveys_515_details.indicator_64_e, surveys_515_details.indicator_64_f, surveys_515_details.indicator_64_g, surveys_515_details.indicator_64_h, surveys_515_details.indicator_64_i, surveys_515_details.indicator_64_j, surveys_515_details.indicator_64_k, surveys_515_details.remarks
	FROM surveys_515_details
	INNER JOIN orgs ON surveys_515_details.org_id = orgs.org_id
	INNER JOIN surveys_515 ON surveys_515_details.surveys_515_id = surveys_515.surveys_515_id;

CREATE VIEW vw_surveys_515_details AS
	SELECT orgs.org_id, orgs.org_name,
	surveys_515.surveys_515_id, surveys_515.chu_name, surveys_515.mclu_code, surveys_515.link_facility,
	surveys_515.chew_name, surveys_515.no_of_chvs, surveys_515.total_chws_reported, surveys_515.county,
	surveys_515.subcounty, surveys_515.division, surveys_515.location, surveys_515.sublocation, surveys_515.total_vilages,
	surveys_515.month, surveys_515.year, surveys_515.survey_date,
	surveys_515_details.indicator_1, surveys_515_details.indicator_2, surveys_515_details.indicator_3, surveys_515_details.indicator_4, surveys_515_details.indicator_5, surveys_515_details.indicator_6, surveys_515_details.indicator_7, surveys_515_details.indicator_8, surveys_515_details.indicator_9, surveys_515_details.indicator_10, surveys_515_details.indicator_11, surveys_515_details.indicator_12, surveys_515_details.indicator_13, surveys_515_details.indicator_14, surveys_515_details.indicator_15, surveys_515_details.indicator_16, surveys_515_details.indicator_17, surveys_515_details.indicator_18, surveys_515_details.indicator_19, surveys_515_details.indicator_20, surveys_515_details.indicator_21, surveys_515_details.indicator_22, surveys_515_details.indicator_23, surveys_515_details.indicator_24, surveys_515_details.indicator_25, surveys_515_details.indicator_26, surveys_515_details.indicator_27, surveys_515_details.indicator_28, surveys_515_details.indicator_29, surveys_515_details.indicator_30, surveys_515_details.indicator_31, surveys_515_details.indicator_32, surveys_515_details.indicator_33, surveys_515_details.indicator_34, surveys_515_details.indicator_35, surveys_515_details.indicator_36, surveys_515_details.indicator_37, surveys_515_details.indicator_38, surveys_515_details.indicator_39, surveys_515_details.indicator_40, surveys_515_details.indicator_41, surveys_515_details.indicator_42, surveys_515_details.indicator_43, surveys_515_details.indicator_44, surveys_515_details.indicator_45, surveys_515_details.indicator_46, surveys_515_details.indicator_47, surveys_515_details.indicator_48, surveys_515_details.indicator_49, surveys_515_details.indicator_50, surveys_515_details.indicator_51, surveys_515_details.indicator_52, surveys_515_details.indicator_53, surveys_515_details.indicator_54, surveys_515_details.indicator_55, surveys_515_details.indicator_56, surveys_515_details.indicator_57, surveys_515_details.indicator_58, surveys_515_details.indicator_59, surveys_515_details.indicator_60, surveys_515_details.indicator_61, surveys_515_details.indicator_62, surveys_515_details.indicator_63, surveys_515_details.indicator_64_a, surveys_515_details.indicator_64_b, surveys_515_details.indicator_64_c, surveys_515_details.indicator_64_d, surveys_515_details.indicator_64_e, surveys_515_details.indicator_64_f, surveys_515_details.indicator_64_g, surveys_515_details.indicator_64_h, surveys_515_details.indicator_64_i, surveys_515_details.indicator_64_j, surveys_515_details.indicator_64_k, surveys_515_details.remarks
	FROM surveys_515_details
	INNER JOIN orgs ON surveys_515_details.org_id = orgs.org_id
	INNER JOIN surveys_515 ON surveys_515_details.surveys_515_id = surveys_515.surveys_515_id;

-- NOT IN USE BUT RETAINED FOR GENERIC IMPLEMENTATION
CREATE VIEW vw_survey_515_demograpics AS
	SELECT
	demograpics_515_defs.demograpics_515_def_id, demograpics_515_defs.demograpics_question, demograpics_515_defs.demograpics_details,
	surveys_515.surveys_515_id,
	survey_515_demograpics.survey_515_demograpic_id, survey_515_demograpics.response
	FROM survey_515_demograpics
	INNER JOIN demograpics_515_defs ON survey_515_demograpics.demograpics_515_def_id = demograpics_515_defs.demograpics_515_def_id
	INNER JOIN surveys_515 ON survey_515_demograpics.surveys_515_id = surveys_515.surveys_515_id;






CREATE VIEW vw_surveys_515_details AS
	SELECT orgs.org_id, orgs.org_name, surveys_515.surveys_515_id, surveys_515_details.surveys_515_detail_id, surveys_515_details.indicator_1,
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
	INNER JOIN surveys_515 ON surveys_515_details.surveys_515_id = surveys_515.surveys_515_id;

-- DROP VIEW vw_survey_100 ;
CREATE VIEW vw_survey_100 AS
	SELECT health_workers.health_worker_id, health_workers.worker_name, health_workers.worker_mobile_num,
    orgs.org_id, orgs.org_name,
	survey_100.survey_100_id, survey_100.patient_gender, form_serial, survey_100.patient_name, survey_100.patient_age,
	survey_100.community_healt_unit, survey_100.link_health_facility, survey_100.referral_reason, survey_100.treatment,
	survey_100.comments, survey_100.sub_location, survey_100.village, survey_100.community_unit, survey_100.receiving_officer_name,
	survey_100.receiving_officer_profession, survey_100.health_facility_name, survey_100.action_taken, survey_100.receiving_officer_date,
	survey_100.receiving_officer_time,
	survey_100.referral_time
	FROM survey_100
	INNER JOIN health_workers ON survey_100.health_worker_id = health_workers.health_worker_id
	INNER JOIN orgs ON survey_100.org_id = orgs.org_id;


-- Health Facility

CREATE VIEW vw_health_falicities AS
	SELECT orgs.org_id, orgs.org_name, health_falicities.health_falicity_id, health_falicities.health_falicity_name, health_falicities.details
	FROM health_falicities
	INNER JOIN orgs ON health_falicities.org_id = orgs.org_id;




CREATE VIEW vw_health_facility_data AS
	SELECT health_falicities.health_falicity_id, health_falicities.health_falicity_name, months.month_id, months.month_name,
orgs.org_id, orgs.org_name, years.year_id, years.year_name, health_facility_data.health_facility_data_id, health_facility_data.indicator_1a,
health_facility_data.indicator_1b, health_facility_data.indicator_1c, health_facility_data.indicator_1d, health_facility_data.indicator_1e,
health_facility_data.indicator_1f, health_facility_data.indicator_2, health_facility_data.indicator_3, health_facility_data.indicator_4, health_facility_data.indicator_5,
health_facility_data.indicator_6, health_facility_data.indicator_7, health_facility_data.indicator_8, health_facility_data.indicator_9, health_facility_data.indicator_10,
health_facility_data.indicator_11, health_facility_data.indicator_12, health_facility_data.indicator_13, health_facility_data.indicator_14, health_facility_data.indicator_15,
health_facility_data.indicator_16, health_facility_data.indicator_17, health_facility_data.indicator_18, health_facility_data.indicator_19, health_facility_data.indicator_20,
health_facility_data.indicator_21, health_facility_data.indicator_22, health_facility_data.indicator_23, health_facility_data.indicator_24, health_facility_data.indicator_25,
health_facility_data.indicator_26, health_facility_data.indicator_27, health_facility_data.indicator_28, health_facility_data.indicator_29, health_facility_data.indicator_30,
health_facility_data.indicator_31, health_facility_data.indicator_32, health_facility_data.indicator_33, health_facility_data.indicator_34, health_facility_data.indicator_35,
health_facility_data.indicator_36, health_facility_data.indicator_37, health_facility_data.indicator_38, health_facility_data.indicator_39, health_facility_data.indicator_40,
health_facility_data.creation_date
	FROM health_facility_data
	INNER JOIN health_falicities ON health_facility_data.health_falicity_id = health_falicities.health_falicity_id
	INNER JOIN months ON health_facility_data.month_id = months.month_id
	INNER JOIN orgs ON health_facility_data.org_id = orgs.org_id
	INNER JOIN years ON health_facility_data.year_id = years.year_id;
