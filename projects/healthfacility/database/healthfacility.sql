---Project Database File

CREATE TABLE years (
    year_id         serial primary key,
    year_name       varchar(5)
);

INSERT INTO years(year_id, year_name) VALUES
(1, '2013'),
(2, '2014'),
(3, '2015');

CREATE TABLE months(
    month_id        serial primary key,
    month_name      varchar(15)
);

INSERT INTO months(month_id, month_name) VALUES
(1, 'January'),
(2, 'February'),
(3, 'March'),
(4, 'April'),
(5, 'May'),
(6, 'June'),
(7, 'July'),
(8, 'August'),
(9, 'September'),
(10, 'October'),
(11, 'November'),
(12, 'December');

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

ALTER TABLE orgs ADD village_id              integer references villages;




-- DROP TABLE indicators;
CREATE TABLE indicators(
    indicator_id        serial primary key,
    indicator_label     varchar(10),
    indicator           varchar(255),
    indicator_category  integer,
    details             text
);



-- DROP TABLE facility_data_response;
-- DROP TABLE facility_data;

CREATE TABLE facility_data(
    facility_data_id        serial primary key,
    entity_id               integer references entitys,
    org_id                  integer references orgs,
    year_id                 integer references years,
    month_id                integer references months,
    data_time               timestamp default CURRENT_TIMESTAMP
);

CREATE INDEX facility_data_entity_id ON facility_data(entity_id);
CREATE INDEX facility_data_org_id ON facility_data(org_id);
CREATE INDEX facility_data_year_id ON facility_data(year_id);
CREATE INDEX facility_data_month_id ON facility_data(month_id);
ALTER TABLE facility_data ADD CONSTRAINT org_id_year_id_month_id UNIQUE (org_id, year_id, month_id);


-- DROP TABLE facility_data_response;
CREATE TABLE facility_data_response(
    facility_data_response_id   serial primary key,
    org_id                  integer references orgs,
    facility_data_id        integer references facility_data,
    indicator_id            integer references indicators,
    response                varchar(225),
    data_source             varchar(225)
);
CREATE INDEX facility_data_response_org_id ON facility_data_response(org_id);
CREATE INDEX facility_data_response_facility_data_id ON facility_data_response(facility_data_id);
CREATE INDEX facility_data_response_indicator_id ON facility_data_response(indicator_id);


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


CREATE VIEW vw_healthfacilities AS
    SELECT orgs.org_id, orgs.org_name, orgs.is_default, orgs.is_active, orgs.logo, orgs.details,
            vw_villages.county_id, vw_villages.county_name, vw_villages.sub_county_id, vw_villages.sub_county_name, vw_villages.division_id,
            vw_villages.division_name, vw_villages.location_id, vw_villages.location_name, vw_villages.sub_location_id,
            vw_villages.sub_location_name, vw_villages.village_id, vw_villages.village_name,
            vw_org_address.org_sys_country_id, vw_org_address.org_sys_country_name,
            vw_org_address.org_address_id, vw_org_address.org_table_name,
            vw_org_address.org_post_office_box, vw_org_address.org_postal_code,
            vw_org_address.org_premises, vw_org_address.org_street, vw_org_address.org_town,
            vw_org_address.org_phone_number, vw_org_address.org_extension,
            vw_org_address.org_mobile, vw_org_address.org_fax, vw_org_address.org_email, vw_org_address.org_website
    	FROM orgs
    	LEFT JOIN vw_org_address ON orgs.org_id = vw_org_address.org_table_id
    	INNER JOIN vw_villages ON vw_villages.village_id = orgs.village_id;

CREATE VIEW vw_facility_data AS
	SELECT entitys.entity_id, entitys.entity_name, months.month_id, months.month_name, orgs.org_id, orgs.org_name,
	   years.year_id, years.year_name, facility_data.facility_data_id, facility_data.data_time
	FROM facility_data
	INNER JOIN entitys ON facility_data.entity_id = entitys.entity_id
	INNER JOIN months ON facility_data.month_id = months.month_id
	INNER JOIN orgs ON facility_data.org_id = orgs.org_id
	INNER JOIN years ON facility_data.year_id = years.year_id;

-- DROP VIEW vw_facility_data_response;
CREATE VIEW vw_facility_data_response AS
	SELECT
    villages.village_id, villages.village_name,
    orgs.org_id, orgs.org_name,
	entitys.entity_id, entitys.entity_name,
	months.month_id, months.month_name,
	years.year_id, years.year_name, facility_data.facility_data_id, facility_data.data_time,
	indicators.indicator_id, indicators.indicator_label, indicators.indicator, indicators.details, indicators.indicator_category,
	facility_data_response.facility_data_response_id, facility_data_response.response, facility_data_response.data_source
	FROM facility_data_response
	INNER JOIN facility_data ON facility_data_response.facility_data_id = facility_data.facility_data_id
	INNER JOIN indicators ON facility_data_response.indicator_id = indicators.indicator_id
	INNER JOIN entitys ON facility_data.entity_id = entitys.entity_id
	INNER JOIN months ON facility_data.month_id = months.month_id
	INNER JOIN orgs ON facility_data.org_id = orgs.org_id
    INNER JOIN villages ON villages.village_id = orgs.village_id
	INNER JOIN years ON facility_data.year_id = years.year_id;




CREATE OR REPLACE FUNCTION ins_facility_data() RETURNS trigger AS $$
DECLARE
        r       indicators%rowtype;
    BEGIN
        FOR r IN
            SELECT indicator_id FROM indicators
        LOOP
            INSERT INTO facility_data_response(org_id, facility_data_id, indicator_id)
                    VALUES (NEW.org_id, NEW.facility_data_id, r.indicator_id);
        END LOOP;
	RETURN NULL;
 END;
 $$ LANGUAGE plpgsql;

CREATE TRIGGER ins_facility_data AFTER INSERT ON facility_data
    FOR EACH ROW EXECUTE PROCEDURE ins_facility_data();


/*


DROP TABLE facility_data CASCADE;

CREATE TABLE facility_data(
    facility_data_id        serial primary key,
    entity_id               integer references entitys,
    org_id                  integer references orgs,
    year_id                 integer references years,
    month_id                integer references months,
    indicator_1a			integer NOT NULL default 0,
    indicator_1a_source		  varchar(255),
    indicator_1b			integer NOT NULL default 0,
    indicator_1b_source		  varchar(255),
    indicator_1c			integer NOT NULL default 0,
    indicator_1c_source		  varchar(255),
    indicator_1d			integer NOT NULL default 0,
    indicator_1d_source		  varchar(255),
    indicator_1e			integer NOT NULL default 0,
    indicator_1e_source		  varchar(255),
    indicator_1f			integer NOT NULL default 0,
    indicator_1f_source		  varchar(255),
    indicator_2			integer NOT NULL default 0,
    indicator_2_source		varchar(255),
    indicator_3			integer NOT NULL default 0,
    indicator_3_source		varchar(255),
    indicator_4			integer NOT NULL default 0,
    indicator_4_source		varchar(255),
    indicator_5			integer NOT NULL default 0,
    indicator_5_source		varchar(255),
    indicator_6			integer NOT NULL default 0,
    indicator_6_source		varchar(255),
    indicator_7			integer NOT NULL default 0,
    indicator_7_source		varchar(255),
    indicator_8			integer NOT NULL default 0,
    indicator_8_source		varchar(255),
    indicator_9			integer NOT NULL default 0,
    indicator_9_source		varchar(255),
    indicator_10			integer NOT NULL default 0,
    indicator_10_source		varchar(255),
    indicator_11			integer NOT NULL default 0,
    indicator_11_source		varchar(255),
    indicator_12			integer NOT NULL default 0,
    indicator_12_source		varchar(255),
    indicator_13			integer NOT NULL default 0,
    indicator_13_source		varchar(255),
    indicator_14			integer NOT NULL default 0,
    indicator_14_source		varchar(255),
    indicator_15			integer NOT NULL default 0,
    indicator_15_source		varchar(255),
    indicator_16			integer NOT NULL default 0,
    indicator_16_source		varchar(255),
    indicator_17			integer NOT NULL default 0,
    indicator_17_source		varchar(255),
    indicator_18			integer NOT NULL default 0,
    indicator_18_source		varchar(255),
    indicator_19			integer NOT NULL default 0,
    indicator_19_source		varchar(255),
    indicator_20			integer NOT NULL default 0,
    indicator_20_source		varchar(255),
    indicator_21			integer NOT NULL default 0,
    indicator_21_source		varchar(255),
    indicator_22			integer NOT NULL default 0,
    indicator_22_source		varchar(255),
    indicator_23			integer NOT NULL default 0,
    indicator_23_source		varchar(255),
    indicator_24			integer NOT NULL default 0,
    indicator_24_source		varchar(255),
    indicator_25			integer NOT NULL default 0,
    indicator_25_source		varchar(255),
    indicator_26			integer NOT NULL default 0,
    indicator_26_source		varchar(255),
    indicator_27			integer NOT NULL default 0,
    indicator_27_source		varchar(255),
    indicator_28			integer NOT NULL default 0,
    indicator_28_source		varchar(255),
    indicator_29			integer NOT NULL default 0,
    indicator_29_source		varchar(255),
    indicator_30			integer NOT NULL default 0,
    indicator_30_source		varchar(255),
    indicator_31			integer NOT NULL default 0,
    indicator_31_source		varchar(255),
    indicator_32			integer NOT NULL default 0,
    indicator_32_source		varchar(255),
    indicator_33			integer NOT NULL default 0,
    indicator_33_source		varchar(255),
    indicator_34			integer NOT NULL default 0,
    indicator_34_source		varchar(255),
    indicator_35			integer NOT NULL default 0,
    indicator_35_source		varchar(255),
    indicator_36			integer NOT NULL default 0,
    indicator_36_source		varchar(255),
    indicator_37			integer NOT NULL default 0,
    indicator_37_source		varchar(255),
    indicator_38			integer NOT NULL default 0,
    indicator_38_source		varchar(255),
    indicator_39			integer NOT NULL default 0,
    indicator_39_source		varchar(255),
    indicator_40			integer NOT NULL default 0,
    indicator_40_source		varchar(255),
    indicator_41			integer NOT NULL default 0,
    indicator_41_source		varchar(255),
    indicator_42			integer NOT NULL default 0,
    indicator_42_source		varchar(255),
    remarks                 text,
    creation_date           timestamp default CURRENT_TIMESTAMP
);


DROP TABLE facility_data CASCADE;
CREATE TABLE facility_data(
    facility_data_id serial primary key,
    entity_id               integer references entitys,
    org_id                  integer references orgs,
    year_id                 integer references years,
    month_id                integer references months,
    indicator_1a			integer NOT NULL default 0,
    indicator_1b			integer NOT NULL default 0,
    indicator_1c			integer NOT NULL default 0,
    indicator_1d			integer NOT NULL default 0,
    indicator_1e			integer NOT NULL default 0,
    indicator_1f			integer NOT NULL default 0,
    indicator_2			    integer NOT NULL default 0,
    indicator_3			    integer NOT NULL default 0,
    indicator_4			    integer NOT NULL default 0,
    indicator_5			    integer NOT NULL default 0,
    indicator_6			    integer NOT NULL default 0,
    indicator_7			    integer NOT NULL default 0,
    indicator_8			    integer NOT NULL default 0,
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
    remarks                 text,
    creation_date           timestamp default CURRENT_TIMESTAMP
);



CREATE VIEW vw_facility_data AS
	SELECT entitys.entity_id, entitys.entity_name, months.month_id, months.month_name, orgs.org_id, orgs.org_name,
 years.year_id, years.year_name, facility_data.facility_data_id, facility_data.indicator_1a, facility_data.indicator_1b, facility_data.indicator_1c, facility_data.indicator_1d,
facility_data.indicator_1e, facility_data.indicator_1f, facility_data.indicator_2, facility_data.indicator_3, facility_data.indicator_4, facility_data.indicator_5, facility_data.indicator_6,
 facility_data.indicator_7, facility_data.indicator_8, facility_data.indicator_9, facility_data.indicator_10, facility_data.indicator_11, facility_data.indicator_12, facility_data.indicator_13,
 facility_data.indicator_14, facility_data.indicator_15, facility_data.indicator_16, facility_data.indicator_17, facility_data.indicator_18, facility_data.indicator_19, facility_data.indicator_20,
 facility_data.indicator_21, facility_data.indicator_22, facility_data.indicator_23, facility_data.indicator_24, facility_data.indicator_25, facility_data.indicator_26, facility_data.indicator_27,
 facility_data.indicator_28, facility_data.indicator_29, facility_data.indicator_30, facility_data.indicator_31, facility_data.indicator_32, facility_data.indicator_33, facility_data.indicator_34,
facility_data.indicator_35, facility_data.indicator_36, facility_data.indicator_37, facility_data.indicator_38, facility_data.indicator_39, facility_data.indicator_40, facility_data.indicator_41,
 facility_data.indicator_42, facility_data.remarks, facility_data.creation_date
	FROM facility_data
	INNER JOIN entitys ON facility_data.entity_id = entitys.entity_id
	INNER JOIN months ON facility_data.month_id = months.month_id
	INNER JOIN orgs ON facility_data.org_id = orgs.org_id
	INNER JOIN years ON facility_data.year_id = years.year_id;

*/
