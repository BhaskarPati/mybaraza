
CREATE TABLE clinician_ab
(
    clinician_ab_id integer NOT NULL DEFAULT nextval('clinician_ab_clinician_ab_id_seq'::regclass),
    survey_100_id integer,
    mother_mpp_def_id integer,
    response integer,
    CONSTRAINT clinician_ab_pkey PRIMARY KEY (clinician_ab_id)
)

CREATE TABLE clinician_pg
(
    clinician_pg_id integer NOT NULL DEFAULT nextval('clinician_pg_clinician_pg_id_seq'::regclass),
    survey_100_id integer,
    mother_mpp_def_id integer,
    response integer,
    CONSTRAINT clinician_pg_pkey PRIMARY KEY (clinician_pg_id)
)

CREATE TABLE clinician_pm
(
    clinician_pm_id integer NOT NULL DEFAULT nextval('clinician_pm_clinician_pm_id_seq'::regclass),
    survey_100_id integer,
    mother_mpp_def_id integer,
    response integer,
    CONSTRAINT clinician_pm_pkey PRIMARY KEY (clinician_pm_id)
)

CREATE TABLE clinician_td
(
    clinician_td_id integer NOT NULL DEFAULT nextval('clinician_td_clinician_td_id_seq'::regclass),
    survey_100_id integer,
    mother_mpp_def_id integer,
    response integer,
    CONSTRAINT clinician_td_pkey PRIMARY KEY (clinician_td_id)
)

CREATE TABLE countys
(
    county_id integer NOT NULL DEFAULT nextval('countys_county_id_seq'::regclass),
    county_name character varying(100) COLLATE "default".pg_catalog,
    CONSTRAINT countys_pkey PRIMARY KEY (county_id)
)

CREATE TABLE currency
(
    currency_id integer NOT NULL DEFAULT nextval('currency_currency_id_seq'::regclass),
    currency_name character varying(50) COLLATE "default".pg_catalog,
    currency_symbol character varying(3) COLLATE "default".pg_catalog,
    org_id integer,
    CONSTRAINT currency_pkey PRIMARY KEY (currency_id),
    CONSTRAINT currency_org_id_fkey FOREIGN KEY (org_id)
        REFERENCES public.orgs (org_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

CREATE TABLE death_info_513
(
    death_id integer NOT NULL DEFAULT nextval('death_info_513_death_id_seq'::regclass),
    survey_id integer,
    individual_code_dt character varying COLLATE "default".pg_catalog,
    name_dt character varying COLLATE "default".pg_catalog,
    age_dt character varying COLLATE "default".pg_catalog,
    sex_dt character varying COLLATE "default".pg_catalog,
    comments character varying COLLATE "default".pg_catalog,
    date_collection_dt character varying COLLATE "default".pg_catalog,
    CONSTRAINT death_info_513_pkey PRIMARY KEY (death_id)
)

CREATE TABLE death_info_513
(
    death_id integer NOT NULL DEFAULT nextval('death_info_513_death_id_seq'::regclass),
    survey_id integer,
    individual_code_dt character varying COLLATE "default".pg_catalog,
    name_dt character varying COLLATE "default".pg_catalog,
    age_dt character varying COLLATE "default".pg_catalog,
    sex_dt character varying COLLATE "default".pg_catalog,
    comments character varying COLLATE "default".pg_catalog,
    date_collection_dt character varying COLLATE "default".pg_catalog,
    CONSTRAINT death_info_513_pkey PRIMARY KEY (death_id)
)

CREATE TABLE death_info_defs
(
    death_info_def_id integer NOT NULL DEFAULT nextval('death_info_defs_death_info_def_id_seq'::regclass),
    question text COLLATE "default".pg_catalog,
    details text COLLATE "default".pg_catalog,
    for_515 boolean DEFAULT false,
    CONSTRAINT death_info_defs_pkey PRIMARY KEY (death_info_def_id)
)

-- DROP TABLE public.decision_support;

CREATE TABLE decision_support
(
    name character varying COLLATE "default".pg_catalog,
    village_id integer,
    mobile character varying COLLATE "default".pg_catalog,
    age integer,
    gender character varying(6) COLLATE "default".pg_catalog,
    org_id integer,
    survey_time timestamp without time zone DEFAULT now(),
    location_lat character varying(30) COLLATE "default".pg_catalog,
    location_lng character varying(30) COLLATE "default".pg_catalog,
    survey_status integer,
    health_worker_id integer,
    dsselection integer,
    survey_id integer NOT NULL DEFAULT nextval('decision_support_survey_id_seq'::regclass),
    remarks character varying(300) COLLATE "default".pg_catalog,
    return_reason character varying(300) COLLATE "default".pg_catalog,
    guardian character varying(200) COLLATE "default".pg_catalog,
    u_sid character varying(20) COLLATE "default".pg_catalog,
    weight integer,
    CONSTRAINT decision_support_pkey PRIMARY KEY (survey_id)
)

CREATE TABLE decision_survey
(
    mother_info_def_id integer,
    survey_id integer,
    response integer,
    dss_id integer NOT NULL DEFAULT nextval('decision_survey_dss_id_seq'::regclass),
    survey_100_id integer,
    CONSTRAINT decision_survey_pkey PRIMARY KEY (dss_id)
)

CREATE TABLE defaulters_info_defs
(
    defaulters_info_def_id integer NOT NULL DEFAULT nextval('defaulters_info_defs_defaulters_info_def_id_seq'::regclass),
    question text COLLATE "default".pg_catalog,
    details text COLLATE "default".pg_catalog,
    for_515 boolean DEFAULT false,
    CONSTRAINT defaulters_info_defs_pkey PRIMARY KEY (defaulters_info_def_id)
)

CREATE TABLE health_workers
(
    health_worker_id integer NOT NULL DEFAULT nextval('health_workers_health_worker_id_seq'::regclass),
    entity_id integer,
    org_id integer,
    device_id integer,
    worker_name character varying(100) COLLATE "default".pg_catalog,
    worker_national_id character varying(10) COLLATE "default".pg_catalog,
    worker_mobile_num character varying(10) COLLATE "default".pg_catalog NOT NULL,
    worker_pass character varying(33) COLLATE "default".pg_catalog,
    is_first_login boolean DEFAULT true,
    is_active boolean DEFAULT true,
    date_enrolled timestamp without time zone DEFAULT now(),
    CONSTRAINT health_workers_pkey PRIMARY KEY (health_worker_id),
    CONSTRAINT health_workers_device_id_fkey FOREIGN KEY (device_id)
        REFERENCES public.devices (device_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT health_workers_entity_id_fkey FOREIGN KEY (entity_id)
        REFERENCES public.entitys (entity_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT health_workers_org_id_fkey FOREIGN KEY (org_id)
        REFERENCES public.orgs (org_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

CREATE TABLE link_health_facilities
(
    link_health_facility_id integer NOT NULL DEFAULT nextval('link_health_facilities_link_health_facility_id_seq'::regclass),
    org_id integer,
    sub_location_id integer,
    link_health_facility_name character varying(225) COLLATE "default".pg_catalog,
    details text COLLATE "default".pg_catalog,
    email character varying(150) COLLATE "default".pg_catalog,
    CONSTRAINT link_health_facilities_pkey PRIMARY KEY (link_health_facility_id),
    CONSTRAINT link_health_facilities_org_id_fkey FOREIGN KEY (org_id)
        REFERENCES public.orgs (org_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT link_health_facilities_sub_location_id_fkey FOREIGN KEY (sub_location_id)
        REFERENCES public.sub_locations (sub_location_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

CREATE TABLE household_info_defs
(
    household_info_def_id integer NOT NULL DEFAULT nextval('household_info_defs_household_info_def_id_seq'::regclass),
    question text COLLATE "default".pg_catalog,
    details text COLLATE "default".pg_catalog,
    for_515 boolean DEFAULT false,
    CONSTRAINT household_info_defs_pkey PRIMARY KEY (household_info_def_id)
)

CREATE TABLE indicators
(
    indicator_id integer NOT NULL DEFAULT nextval('indicators_indicator_id_seq'::regclass),
    indicator_label character varying(10) COLLATE "default".pg_catalog,
    indicator character varying(255) COLLATE "default".pg_catalog,
    indicator_category integer,
    details text COLLATE "default".pg_catalog,
    CONSTRAINT indicators_pkey PRIMARY KEY (indicator_id)
)

CREATE TABLE link_health_facilities
(
    link_health_facility_id integer NOT NULL DEFAULT nextval('link_health_facilities_link_health_facility_id_seq'::regclass),
    org_id integer,
    sub_location_id integer,
    link_health_facility_name character varying(225) COLLATE "default".pg_catalog,
    details text COLLATE "default".pg_catalog,
    email character varying(150) COLLATE "default".pg_catalog,
    CONSTRAINT link_health_facilities_pkey PRIMARY KEY (link_health_facility_id),
    CONSTRAINT link_health_facilities_org_id_fkey FOREIGN KEY (org_id)
        REFERENCES public.orgs (org_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT link_health_facilities_sub_location_id_fkey FOREIGN KEY (sub_location_id)
        REFERENCES public.sub_locations (sub_location_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

CREATE TABLE locations
(
    location_id integer NOT NULL DEFAULT nextval('locations_location_id_seq'::regclass),
    division_id integer,
    location_name character varying(200) COLLATE "default".pg_catalog,
    CONSTRAINT locations_pkey PRIMARY KEY (location_id),
    CONSTRAINT locations_division_id_fkey FOREIGN KEY (division_id)
        REFERENCES public.divisions (division_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

CREATE TABLE mother_mpp_info_def
(
    mother_mpp_def_id integer NOT NULL DEFAULT nextval('mother_mpp_info_def_mother_mpp_def_id_seq'::regclass),
    question character varying(200) COLLATE "default".pg_catalog,
    details character varying(1000) COLLATE "default".pg_catalog,
    CONSTRAINT mother_mpp_info_def_pkey PRIMARY KEY (mother_mpp_def_id)
)


CREATE TABLE referral_info_defs
(
    referral_info_def_id integer NOT NULL DEFAULT nextval('referral_info_defs_referral_info_def_id_seq'::regclass),
    question text COLLATE "default".pg_catalog,
    details text COLLATE "default".pg_catalog,
    for_515 boolean DEFAULT false,
    CONSTRAINT referral_info_defs_pkey PRIMARY KEY (referral_info_def_id)
)

CREATE TABLE reporting
(
    reporting_id integer NOT NULL DEFAULT nextval('reporting_reporting_id_seq'::regclass),
    entity_id integer,
    report_to_id integer,
    org_id integer,
    date_from date,
    date_to date,
    reporting_level integer NOT NULL DEFAULT 1,
    primary_report boolean NOT NULL DEFAULT true,
    is_active boolean NOT NULL DEFAULT true,
    ps_reporting real,
    details text COLLATE "default".pg_catalog,
    CONSTRAINT reporting_pkey PRIMARY KEY (reporting_id),
    CONSTRAINT reporting_entity_id_fkey FOREIGN KEY (entity_id)
        REFERENCES public.entitys (entity_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT reporting_org_id_fkey FOREIGN KEY (org_id)
        REFERENCES public.orgs (org_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT reporting_report_to_id_fkey FOREIGN KEY (report_to_id)
        REFERENCES public.entitys (entity_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)
-- Table: public.facility_data

CREATE TABLE facility_data
(
    facility_data_id integer NOT NULL DEFAULT nextval('facility_data_facility_data_id_seq'::regclass),
    entity_id integer,
    org_id integer,
    year_id integer,
    month_id integer,
    data_time timestamp without time zone DEFAULT now(),
    CONSTRAINT facility_data_pkey PRIMARY KEY (facility_data_id),
    CONSTRAINT org_id_year_id_month_id UNIQUE (org_id, month_id, year_id),
    CONSTRAINT facility_data_entity_id_fkey FOREIGN KEY (entity_id)
        REFERENCES public.entitys (entity_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT facility_data_month_id_fkey FOREIGN KEY (month_id)
        REFERENCES public.months (month_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT facility_data_org_id_fkey FOREIGN KEY (org_id)
        REFERENCES public.orgs (org_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT facility_data_year_id_fkey FOREIGN KEY (year_id)
        REFERENCES public.years (year_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

-- Index: facility_data_entity_id

CREATE INDEX facility_data_entity_id
    ON public.facility_data USING btree
    (entity_id)
    TABLESPACE pg_default;

-- Index: facility_data_month_id

CREATE INDEX facility_data_month_id
    ON public.facility_data USING btree
    (month_id)
    TABLESPACE pg_default;

-- Index: facility_data_org_id

CREATE INDEX facility_data_org_id
    ON public.facility_data USING btree
    (org_id)
    TABLESPACE pg_default;

-- Index: facility_data_year_id

CREATE INDEX facility_data_year_id
    ON public.facility_data USING btree
    (year_id)
    TABLESPACE pg_default;

-- Trigger: ins_facility_data

CREATE TRIGGER ins_facility_data
    AFTER INSERT
    ON public.facility_data
    FOR EACH ROW
    EXECUTE PROCEDURE ins_facility_data();

-- Table: public.survey_100

CREATE TABLE survey_100
(
    survey_100_id integer NOT NULL DEFAULT nextval('survey_100_survey_100_id_seq'::regclass),
    org_id integer,
    health_worker_id integer,
    village_id integer,
    link_health_facility_id integer,
    form_serial character varying(10) COLLATE "default".pg_catalog,
    patient_gender character varying(2) COLLATE "default".pg_catalog,
    patient_name character varying(200) COLLATE "default".pg_catalog,
    patient_age character varying(5) COLLATE "default".pg_catalog,
    community_healt_unit character varying(200) COLLATE "default".pg_catalog,
    referral_reason character varying(200) COLLATE "default".pg_catalog,
    treatment text COLLATE "default".pg_catalog,
    comments text COLLATE "default".pg_catalog,
    community_unit character varying(200) COLLATE "default".pg_catalog,
    receiving_officer_name character varying(200) COLLATE "default".pg_catalog,
    receiving_officer_profession character varying(200) COLLATE "default".pg_catalog,
    health_facility_name character varying(200) COLLATE "default".pg_catalog,
    action_taken text COLLATE "default".pg_catalog,
    receiving_officer_date date,
    receiving_officer_time time without time zone,
    referral_time timestamp without time zone DEFAULT now(),
    patient_age_type character varying COLLATE "default".pg_catalog,
    call_by character varying COLLATE "default".pg_catalog,
    instructions character varying(300) COLLATE "default".pg_catalog,
    survey_status integer,
    dss_514_id integer,
    dss_id integer,
    reviewer_comments character varying(300) COLLATE "default".pg_catalog,
    reviewer_name character varying(10) COLLATE "default".pg_catalog,
    reviewer_recommendations character varying(200) COLLATE "default".pg_catalog,
    u_sid character varying(20) COLLATE "default".pg_catalog,
    other_facility character varying(200) COLLATE "default".pg_catalog,
    clinician_findings character varying(400) COLLATE "default".pg_catalog,
    actions_taken_clinician character varying(400) COLLATE "default".pg_catalog,
    alerts character varying(500) COLLATE "default".pg_catalog,
    cycle_status integer,
    reponse_chv character varying(300) COLLATE "default".pg_catalog,
    clinician_survey integer DEFAULT 0,
    CONSTRAINT survey_100_pkey PRIMARY KEY (survey_100_id),
    CONSTRAINT survey_100_health_worker_id_fkey FOREIGN KEY (health_worker_id)
        REFERENCES public.health_workers (health_worker_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT survey_100_link_health_facility_id_fkey FOREIGN KEY (link_health_facility_id)
        REFERENCES public.link_health_facilities (link_health_facility_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT survey_100_org_id_fkey FOREIGN KEY (org_id)
        REFERENCES public.orgs (org_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT survey_100_village_id_fkey FOREIGN KEY (village_id)
        REFERENCES public.villages (village_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

CREATE TRIGGER ins_survey_100_email
    AFTER INSERT
    ON public.survey_100
    FOR EACH ROW
    EXECUTE PROCEDURE afterinsemail();

CREATE TABLE survey_513
(
    survey_id integer NOT NULL DEFAULT nextval('survey_513_survey_id_seq'::regclass),
    org_id integer,
    health_worker_id integer,
    individual_code character varying COLLATE "default".pg_catalog,
    collection_date character varying COLLATE "default".pg_catalog,
    member_name character varying COLLATE "default".pg_catalog,
    age_completed_years character varying COLLATE "default".pg_catalog,
    gender_type character varying COLLATE "default".pg_catalog,
    village_id integer,
    survey_time timestamp without time zone DEFAULT now(),
    location_lat character varying(30) COLLATE "default".pg_catalog,
    location_lng character varying(30) COLLATE "default".pg_catalog,
    survey_status integer,
    remarks text COLLATE "default".pg_catalog,
    reviewers_remarks text COLLATE "default".pg_catalog,
    mobile character varying(100) COLLATE "default".pg_catalog,
    CONSTRAINT survey_513_pkey1 PRIMARY KEY (survey_id)
)

CREATE TABLE survey_513_1
(
    survey_513_id integer NOT NULL DEFAULT nextval('survey_513_survey_513_id_seq'::regclass),
    survey_513_def_id integer,
    response integer,
    survey_id integer,
    CONSTRAINT survey_513_pkey PRIMARY KEY (survey_513_id)
)

CREATE TABLE survey_513_info_def
(
    survey_513_def_id integer NOT NULL DEFAULT nextval('survey_513_info_def_survey_15_info_def_id_seq'::regclass),
    question character varying(200) COLLATE "default".pg_catalog,
    details character varying(200) COLLATE "default".pg_catalog,
    CONSTRAINT survey_513_info_def_pkey PRIMARY KEY (survey_513_def_id)
)
CREATE TABLE survey_child
(
    survey_child_id integer NOT NULL DEFAULT nextval('survey_child_survey_child_id_seq'::regclass),
    survey_id integer,
    child_info_def_id integer,
    response integer,
    reg_id character varying(100) COLLATE "default".pg_catalog,
    CONSTRAINT survey_child_pkey PRIMARY KEY (survey_child_id),
    CONSTRAINT survey_child_child_info_def_id_fkey FOREIGN KEY (child_info_def_id)
        REFERENCES public.child_info_defs (child_info_def_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT survey_child_survey_id_fkey FOREIGN KEY (survey_id)
        REFERENCES public.surveys (survey_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

CREATE TABLE survey_cohort
(
    cohort_info_def_id integer,
    response integer,
    survey_cohort_id integer
)

CREATE TABLE survey_death
(
    survey_death_id integer NOT NULL DEFAULT nextval('survey_death_survey_death_id_seq'::regclass),
    survey_id integer,
    death_info_def_id integer,
    response character varying(225) COLLATE "default".pg_catalog,
    CONSTRAINT survey_death_pkey PRIMARY KEY (survey_death_id),
    CONSTRAINT survey_death_death_info_def_id_fkey FOREIGN KEY (death_info_def_id)
        REFERENCES public.death_info_defs (death_info_def_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT survey_death_survey_id_fkey FOREIGN KEY (survey_id)
        REFERENCES public.surveys (survey_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

CREATE TABLE survey_dss
(
    survey_dss_id integer NOT NULL DEFAULT nextval('survey_dss_survey_dss_id_seq'::regclass),
    survey_id integer,
    dss_info_defs_id integer,
    response character varying(100) COLLATE "default".pg_catalog,
    key character varying COLLATE "default".pg_catalog,
    CONSTRAINT survey_dss_pkey PRIMARY KEY (survey_dss_id)
)

CREATE TABLE sys_emails
(
    sys_email_id integer NOT NULL DEFAULT nextval('sys_emails_sys_email_id_seq'::regclass),
    org_id integer,
    sys_email_name character varying(50) COLLATE "default".pg_catalog,
    default_email character varying(120) COLLATE "default".pg_catalog,
    title character varying(240) COLLATE "default".pg_catalog NOT NULL,
    details text COLLATE "default".pg_catalog,
    CONSTRAINT sys_emails_pkey PRIMARY KEY (sys_email_id),
    CONSTRAINT sys_emails_org_id_fkey FOREIGN KEY (org_id)
        REFERENCES public.orgs (org_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

-- Table: public.survey_household

CREATE TABLE survey_household
(
    survey_household_id integer NOT NULL DEFAULT nextval('survey_household_survey_household_id_seq'::regclass),
    survey_id integer,
    household_info_def_id integer,
    response integer,
    CONSTRAINT survey_household_pkey PRIMARY KEY (survey_household_id),
    CONSTRAINT survey_household_household_info_def_id_fkey FOREIGN KEY (household_info_def_id)
        REFERENCES public.household_info_defs (household_info_def_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT survey_household_survey_id_fkey FOREIGN KEY (survey_id)
        REFERENCES public.surveys (survey_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

CREATE TABLE survey_mother
(
    survey_mother_id integer NOT NULL DEFAULT nextval('survey_mother_survey_mother_id_seq'::regclass),
    survey_id integer,
    mother_info_def_id integer,
    response integer,
    reg_id character varying(100) COLLATE "default".pg_catalog,
    CONSTRAINT survey_mother_pkey PRIMARY KEY (survey_mother_id),
    CONSTRAINT survey_mother_mother_info_def_id_fkey FOREIGN KEY (mother_info_def_id)
        REFERENCES public.mother_info_defs (mother_info_def_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT survey_mother_survey_id_fkey FOREIGN KEY (survey_id)
        REFERENCES public.surveys (survey_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

CREATE TABLE survey_referrals
(
    survey_referral_id integer NOT NULL DEFAULT nextval('survey_referrals_survey_referral_id_seq'::regclass),
    survey_id integer,
    referral_info_defs_id integer,
    response character varying(225) COLLATE "default".pg_catalog,
    CONSTRAINT survey_referrals_pkey PRIMARY KEY (survey_referral_id),
    CONSTRAINT survey_referrals_referral_info_defs_id_fkey FOREIGN KEY (referral_info_defs_id)
        REFERENCES public.referral_info_defs (referral_info_def_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT survey_referrals_survey_id_fkey FOREIGN KEY (survey_id)
        REFERENCES public.surveys (survey_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

CREATE TABLE surveys
(
    survey_id integer NOT NULL DEFAULT nextval('surveys_survey_id_seq'::regclass),
    org_id integer,
    health_worker_id integer,
    village_id integer,
    household_number character varying(100) COLLATE "default".pg_catalog,
    household_member character varying(225) COLLATE "default".pg_catalog,
    survey_time timestamp without time zone DEFAULT now(),
    location_lat character varying(30) COLLATE "default".pg_catalog,
    location_lng character varying(30) COLLATE "default".pg_catalog,
    remarks text COLLATE "default".pg_catalog,
    survey_status integer NOT NULL DEFAULT 0,
    return_reason text COLLATE "default".pg_catalog,
    supervisor_remarks text COLLATE "default".pg_catalog,
    dssxelection integer,
    u_sid character varying(20) COLLATE "default".pg_catalog,
    mobile_num character varying(25) COLLATE "default".pg_catalog,
    pre character varying(25) COLLATE "default".pg_catalog,
    u_sid_mother character varying(200) COLLATE "default".pg_catalog,
    u_sid_child character varying(200) COLLATE "default".pg_catalog,
    CONSTRAINT surveys_pkey PRIMARY KEY (survey_id),
    CONSTRAINT surveys_health_worker_id_fkey FOREIGN KEY (health_worker_id)
        REFERENCES public.health_workers (health_worker_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT surveys_org_id_fkey FOREIGN KEY (org_id)
        REFERENCES public.orgs (org_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT surveys_village_id_fkey FOREIGN KEY (village_id)
        REFERENCES public.villages (village_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)


CREATE INDEX surveys_health_worker_id
    ON public.surveys USING btree
    (health_worker_id)
    TABLESPACE pg_default;

-- Index: surveys_org_id

CREATE INDEX surveys_org_id
    ON public.surveys USING btree
    (org_id)
    TABLESPACE pg_default;

-- Index: surveys_village_id

CREATE INDEX surveys_village_id
    ON public.surveys USING btree
    (village_id)
    TABLESPACE pg_default;

-- Trigger: after_ins_survey

CREATE TRIGGER after_ins_survey
    AFTER INSERT
    ON public.surveys
    FOR EACH ROW
    EXECUTE PROCEDURE afterinssurvey();

ALTER TABLE public.surveys
    DISABLE TRIGGER after_ins_survey;

-- Trigger: ins_survey

-- DROP TRIGGER ins_survey ON public.surveys;

CREATE TRIGGER ins_survey
    BEFORE INSERT
    ON public.surveys
    FOR EACH ROW
    EXECUTE PROCEDURE inssurvey100();

ALTER TABLE public.surveys
    DISABLE TRIGGER ins_survey;

-- Trigger: ins_survey514

CREATE TRIGGER ins_survey514
    BEFORE INSERT
    ON public.surveys
    FOR EACH ROW
    EXECUTE PROCEDURE inssurvey514();

-- Trigger: ins_survey_100

CREATE TRIGGER ins_survey_100
    BEFORE INSERT
    ON public.surveys
    FOR EACH ROW
    EXECUTE PROCEDURE inssurvey_100();

ALTER TABLE public.surveys
    DISABLE TRIGGER ins_survey_100;

-- Trigger: ins_survey_514

CREATE TRIGGER ins_survey_514
    BEFORE INSERT
    ON public.surveys
    FOR EACH ROW
    EXECUTE PROCEDURE inssurvey514();

-- Table: public.villages

CREATE TABLE villages
(
    village_id integer NOT NULL DEFAULT nextval('villages_village_id_seq'::regclass),
    sub_location_id integer,
    village_name character varying(200) COLLATE "default".pg_catalog,
    CONSTRAINT villages_pkey PRIMARY KEY (village_id),
    CONSTRAINT villages_sub_location_id_fkey FOREIGN KEY (sub_location_id)
        REFERENCES public.sub_locations (sub_location_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

CREATE INDEX villages_sub_location_id
    ON public.villages USING btree
    (sub_location_id)
    TABLESPACE pg_default;


--- VIEWS ---


CREATE OR REPLACE VIEW vw_clinician_ab AS
 SELECT mother_mpp_info_def.mother_mpp_def_id,
    mother_mpp_info_def.question,
    mother_mpp_info_def.details,
    clinician_ab.survey_100_id,
    clinician_ab.clinician_ab_id,
    clinician_ab.response,
        CASE clinician_ab.response
            WHEN 1 THEN 'YES'::text
            WHEN 2 THEN 'NO'::text
            WHEN 3 THEN 'N/A'::text
            ELSE 'N/A'::text
        END AS response_name
   FROM clinician_ab
     JOIN mother_mpp_info_def ON clinician_ab.mother_mpp_def_id = mother_mpp_info_def.mother_mpp_def_id;

CREATE OR REPLACE VIEW vw_clinician_pg AS
 SELECT mother_mpp_info_def.mother_mpp_def_id,
    mother_mpp_info_def.question,
    mother_mpp_info_def.details,
    clinician_pg.survey_100_id,
    clinician_pg.clinician_pg_id,
    clinician_pg.response,
        CASE clinician_pg.response
            WHEN 1 THEN 'YES'::text
            WHEN 2 THEN 'NO'::text
            WHEN 3 THEN 'N/A'::text
            ELSE 'N/A'::text
        END AS response_name
   FROM clinician_pg
     JOIN mother_mpp_info_def ON clinician_pg.mother_mpp_def_id = mother_mpp_info_def.mother_mpp_def_id;

CREATE OR REPLACE VIEW vw_clinician_pm AS
 SELECT mother_mpp_info_def.mother_mpp_def_id,
    mother_mpp_info_def.question,
    mother_mpp_info_def.details,
    clinician_pm.survey_100_id,
    clinician_pm.clinician_pm_id,
    clinician_pm.response,
        CASE clinician_pm.response
            WHEN 1 THEN 'YES'::text
            WHEN 2 THEN 'NO'::text
            WHEN 3 THEN 'N/A'::text
            ELSE 'N/A'::text
        END AS response_name
   FROM clinician_pm
     JOIN mother_mpp_info_def ON clinician_pm.mother_mpp_def_id = mother_mpp_info_def.mother_mpp_def_id;

CREATE OR REPLACE VIEW vw_clinician_td AS
 SELECT mother_mpp_info_def.mother_mpp_def_id,
    mother_mpp_info_def.question,
    mother_mpp_info_def.details,
    clinician_td.survey_100_id,
    clinician_td.clinician_td_id,
    clinician_td.response,
        CASE clinician_td.response
            WHEN 1 THEN 'YES'::text
            WHEN 2 THEN 'NO'::text
            WHEN 3 THEN 'N/A'::text
            ELSE 'N/A'::text
        END AS response_name
   FROM clinician_td
     JOIN mother_mpp_info_def ON clinician_td.mother_mpp_def_id = mother_mpp_info_def.mother_mpp_def_id
     JOIN survey_100 ON clinician_td.survey_100_id = survey_100.survey_100_id;

CREATE OR REPLACE VIEW vw_decision_support AS
 SELECT health_workers.health_worker_id,
    health_workers.worker_name,
    orgs.org_id,
    orgs.org_name,
    vw_villages.county_id,
    vw_villages.county_name,
    vw_villages.sub_county_id,
    vw_villages.sub_county_name,
    vw_villages.division_id,
    vw_villages.division_name,
    vw_villages.location_id,
    vw_villages.location_name,
    vw_villages.sub_location_id,
    vw_villages.sub_location_name,
    vw_villages.village_name,
    decision_support.survey_id,
    decision_support.name,
    decision_support.survey_time,
    decision_support.location_lat,
    decision_support.location_lng,
    decision_support.mobile,
    decision_support.dsselection,
    decision_support.survey_status,
    decision_support.weight,
    decision_support.village_id
   FROM decision_support
     JOIN health_workers ON decision_support.health_worker_id = health_workers.health_worker_id
     JOIN orgs ON decision_support.org_id = orgs.org_id
     JOIN vw_villages ON vw_villages.village_id = decision_support.village_id;

CREATE OR REPLACE VIEW vw_dss_100 AS
 SELECT health_workers.health_worker_id,
    health_workers.worker_name,
    health_workers.worker_national_id,
    health_workers.worker_mobile_num,
    link_health_facilities.link_health_facility_id,
    link_health_facilities.link_health_facility_name,
    orgs.org_id,
    orgs.org_name,
    vw_villages.county_id,
    vw_villages.county_name,
    vw_villages.sub_county_id,
    vw_villages.sub_county_name,
    vw_villages.division_id,
    vw_villages.division_name,
    vw_villages.location_id,
    vw_villages.location_name,
    vw_villages.sub_location_id,
    vw_villages.sub_location_name,
    vw_villages.village_id,
    vw_villages.village_name,
    survey_100.survey_100_id,
    survey_100.form_serial,
    survey_100.patient_gender,
    survey_100.patient_name,
    survey_100.patient_age_type,
    survey_100.patient_age,
    survey_100.community_healt_unit,
    survey_100.referral_reason,
    survey_100.treatment,
    survey_100.comments,
    survey_100.community_unit,
    survey_100.receiving_officer_name,
    survey_100.receiving_officer_profession,
    survey_100.health_facility_name,
    survey_100.action_taken,
    survey_100.receiving_officer_date,
    survey_100.receiving_officer_time,
    survey_100.referral_time,
    mother_mpp_info_def.details,
    mother_mpp_info_def.question,
    decision_survey.survey_id,
        CASE decision_survey.response
            WHEN 1 THEN 'YES'::text
            WHEN 2 THEN 'NO'::text
            WHEN 3 THEN 'N/A'::text
            ELSE 'N/A'::text
        END AS response_name
   FROM survey_100
     JOIN health_workers ON survey_100.health_worker_id = health_workers.health_worker_id
     JOIN decision_survey ON survey_100.dss_id = decision_survey.survey_id
     JOIN mother_mpp_info_def ON decision_survey.mother_info_def_id = mother_mpp_info_def.mother_mpp_def_id
     JOIN link_health_facilities ON survey_100.link_health_facility_id = link_health_facilities.link_health_facility_id
     JOIN orgs ON survey_100.org_id = orgs.org_id
     JOIN vw_villages ON vw_villages.village_id = survey_100.village_id;

CREATE OR REPLACE VIEW vw_ref_513 AS
 SELECT survey_513_info_def.survey_513_def_id,
    survey_513_info_def.question,
    survey_513_info_def.details,
    survey_513.survey_id,
    survey_513_1.survey_513_id,
    survey_513_1.response,
        CASE survey_513_1.response
            WHEN 1 THEN 'YES'::text
            WHEN 2 THEN 'NO'::text
            WHEN 3 THEN 'N/A'::text
            ELSE 'N/A'::text
        END AS response_name
   FROM survey_513_1
     JOIN survey_513_info_def ON survey_513_1.survey_513_def_id = survey_513_info_def.survey_513_def_id
     JOIN survey_513 ON survey_513_1.survey_id = survey_513.survey_id;


CREATE OR REPLACE VIEW vw_review_clinician AS
 SELECT vw_clinician_pg.response_name,
    vw_clinician_pg.mother_mpp_def_id,
    vw_clinician_pg.question,
    vw_clinician_pg.survey_100_id,
    vw_mother_mpp.response_name AS response_chv
   FROM vw_clinician_pg
     JOIN vw_mother_mpp ON vw_clinician_pg.survey_100_id = vw_mother_mpp.survey_100_id AND vw_clinician_pg.mother_mpp_def_id = vw_mother_mpp.mother_mpp_def_id
UNION
 SELECT vw_clinician_pm.response_name,
    vw_clinician_pm.mother_mpp_def_id,
    vw_clinician_pm.question,
    vw_clinician_pm.survey_100_id,
    vw_mother_mpp.response_name AS response_chv
   FROM vw_clinician_pm
     JOIN vw_mother_mpp ON vw_clinician_pm.survey_100_id = vw_mother_mpp.survey_100_id AND vw_clinician_pm.mother_mpp_def_id = vw_mother_mpp.mother_mpp_def_id
UNION
 SELECT vw_clinician_ab.response_name,
    vw_clinician_ab.mother_mpp_def_id,
    vw_clinician_ab.question,
    vw_clinician_ab.survey_100_id,
    vw_mother_mpp.response_name AS response_chv
   FROM vw_clinician_ab
     JOIN vw_mother_mpp ON vw_clinician_ab.survey_100_id = vw_mother_mpp.survey_100_id AND vw_clinician_ab.mother_mpp_def_id = vw_mother_mpp.mother_mpp_def_id
UNION
 SELECT vw_clinician_td.response_name,
    vw_clinician_td.mother_mpp_def_id,
    vw_clinician_td.question,
    vw_clinician_td.survey_100_id,
    vw_mother_mpp.response_name AS response_chv
   FROM vw_clinician_td
     JOIN vw_mother_mpp ON vw_clinician_td.survey_100_id = vw_mother_mpp.survey_100_id AND vw_clinician_td.mother_mpp_def_id = vw_mother_mpp.mother_mpp_def_id
  ORDER BY 2;

ALTER TABLE public.vw_review_clinician
    OWNER TO root;  

 CREATE OR REPLACE VIEW vw_survey_100 AS
 SELECT health_workers.health_worker_id,
    health_workers.worker_name,
    health_workers.worker_national_id,
    health_workers.worker_mobile_num,
    link_health_facilities.link_health_facility_id,
    link_health_facilities.link_health_facility_name,
    orgs.org_id,
    orgs.org_name,
    vw_villages.county_id,
    vw_villages.county_name,
    vw_villages.sub_county_id,
    vw_villages.sub_county_name,
    vw_villages.division_id,
    vw_villages.division_name,
    vw_villages.location_id,
    vw_villages.location_name,
    vw_villages.sub_location_id,
    vw_villages.sub_location_name,
    vw_villages.village_id,
    vw_villages.village_name,
    survey_100.survey_100_id,
    survey_100.form_serial,
    survey_100.patient_gender,
    survey_100.patient_name,
    survey_100.patient_age_type,
    survey_100.patient_age,
    survey_100.community_healt_unit,
    survey_100.referral_reason,
    survey_100.treatment,
    survey_100.comments,
    survey_100.community_unit,
    survey_100.receiving_officer_name,
    survey_100.receiving_officer_profession,
    survey_100.health_facility_name,
    survey_100.action_taken,
    survey_100.receiving_officer_date,
    survey_100.receiving_officer_time,
    survey_100.reviewer_recommendations,
    survey_100.reviewer_name,
    survey_100.reviewer_comments,
    survey_100.referral_time,
    survey_100.instructions,
    survey_100.actions_taken_clinician,
    survey_100.clinician_findings,
    survey_100.survey_status,
    survey_100.dss_id,
    survey_100.clinician_survey
   FROM survey_100
     JOIN health_workers ON survey_100.health_worker_id = health_workers.health_worker_id
     JOIN link_health_facilities ON survey_100.link_health_facility_id = link_health_facilities.link_health_facility_id
     JOIN orgs ON survey_100.org_id = orgs.org_id
     JOIN vw_villages ON vw_villages.village_id = survey_100.village_id
  ORDER BY survey_100.survey_100_id;   

CREATE OR REPLACE VIEW vw_survey_513 AS
 SELECT health_workers.health_worker_id,
    health_workers.worker_name,
    orgs.org_id,
    orgs.org_name,
    vw_villages.county_id,
    vw_villages.county_name,
    vw_villages.sub_county_id,
    vw_villages.sub_county_name,
    vw_villages.division_id,
    vw_villages.division_name,
    vw_villages.location_id,
    vw_villages.location_name,
    vw_villages.sub_location_id,
    vw_villages.sub_location_name,
    vw_villages.village_id,
    vw_villages.village_name,
    survey_513.survey_id,
    survey_513.individual_code,
    survey_513.member_name,
    survey_513.age_completed_years,
    survey_513.location_lat,
    survey_513.location_lng,
    survey_513.survey_status,
    survey_513.survey_time,
    survey_513.remarks,
    survey_513.reviewers_remarks,
    survey_513.gender_type
   FROM survey_513
     JOIN health_workers ON survey_513.health_worker_id = health_workers.health_worker_id
     JOIN orgs ON survey_513.org_id = orgs.org_id
     JOIN vw_villages ON vw_villages.village_id = survey_513.village_id;

 
CREATE OR REPLACE VIEW vw_survey_child AS
 SELECT child_info_defs.child_info_def_id,
    child_info_defs.for_515,
    child_info_defs.question,
    child_info_defs.details,
    surveys.survey_id,
    survey_child.survey_child_id,
    survey_child.response,
    survey_child.reg_id,
        CASE survey_child.response
            WHEN 1 THEN 'YES'::text
            WHEN 2 THEN 'NO'::text
            WHEN 3 THEN 'N/A'::text
            ELSE 'N/A'::text
        END AS response_name
   FROM survey_child
     JOIN child_info_defs ON survey_child.child_info_def_id = child_info_defs.child_info_def_id
     JOIN surveys ON survey_child.survey_id = surveys.survey_id;  

CREATE OR REPLACE VIEW vw_survey_death AS
 SELECT death_info_defs.death_info_def_id,
    death_info_defs.for_515,
    death_info_defs.question,
    death_info_defs.details,
    surveys.survey_id,
    survey_death.survey_death_id,
    survey_death.response
   FROM survey_death
     JOIN death_info_defs ON survey_death.death_info_def_id = death_info_defs.death_info_def_id
     JOIN surveys ON survey_death.survey_id = surveys.survey_id; 

CREATE OR REPLACE VIEW vw_survey_defaulters AS
 SELECT defaulters_info_defs.defaulters_info_def_id,
    defaulters_info_defs.for_515,
    defaulters_info_defs.question,
    defaulters_info_defs.details,
    surveys.survey_id,
    survey_defaulters.survey_defaulter_id,
    survey_defaulters.response,
        CASE survey_defaulters.response
            WHEN 1 THEN 'YES'::text
            WHEN 2 THEN 'NO'::text
            WHEN 3 THEN 'N/A'::text
            ELSE 'N/A'::text
        END AS response_name
   FROM survey_defaulters
     JOIN defaulters_info_defs ON survey_defaulters.defaulters_info_def_id = defaulters_info_defs.defaulters_info_def_id
     JOIN surveys ON survey_defaulters.survey_id = surveys.survey_id; 

CREATE OR REPLACE VIEW vw_survey_mother AS
 SELECT mother_info_defs.mother_info_def_id,
    mother_info_defs.for_515,
    mother_info_defs.question,
    mother_info_defs.details,
    surveys.survey_id,
    survey_mother.survey_mother_id,
    survey_mother.response,
    survey_mother.reg_id,
        CASE survey_mother.response
            WHEN 1 THEN 'YES'::text
            WHEN 2 THEN 'NO'::text
            WHEN 3 THEN 'N/A'::text
            ELSE 'N/A'::text
        END AS response_name
   FROM survey_mother
     JOIN mother_info_defs ON survey_mother.mother_info_def_id = mother_info_defs.mother_info_def_id
     JOIN surveys ON survey_mother.survey_id = surveys.survey_id;

CREATE OR REPLACE VIEW vw_survey_referrals AS
 SELECT referral_info_defs.referral_info_def_id,
    referral_info_defs.for_515,
    referral_info_defs.question,
    referral_info_defs.details,
    surveys.survey_id,
    survey_referrals.survey_referral_id,
    survey_referrals.referral_info_defs_id,
    survey_referrals.response,
        CASE survey_referrals.response
            WHEN '1'::text THEN 'YES'::character varying
            WHEN '2'::text THEN 'NO'::character varying
            WHEN '3'::text THEN 'N/A'::character varying
            ELSE survey_referrals.response
        END AS response_name
   FROM survey_referrals
     JOIN referral_info_defs ON survey_referrals.referral_info_defs_id = referral_info_defs.referral_info_def_id
     JOIN surveys ON survey_referrals.survey_id = surveys.survey_id; 

-- View: public.vw_villages

CREATE OR REPLACE VIEW public.vw_villages AS
 SELECT countys.county_id,
    countys.county_name,
    sub_countys.sub_county_id,
    sub_countys.sub_county_name,
    divisions.division_id,
    divisions.division_name,
    locations.location_id,
    locations.location_name,
    sub_locations.sub_location_id,
    sub_locations.sub_location_name,
    villages.village_id,
    villages.village_name
   FROM villages
     JOIN sub_locations ON sub_locations.sub_location_id = villages.sub_location_id
     JOIN locations ON locations.location_id = sub_locations.location_id
     JOIN divisions ON divisions.division_id = locations.division_id
     JOIN sub_countys ON sub_countys.sub_county_id = divisions.sub_county_id
     JOIN countys ON countys.county_id = sub_countys.county_id;

CREATE OR REPLACE VIEW vw_dss AS
 SELECT mother_mpp_info_def.mother_mpp_def_id,
    mother_mpp_info_def.question,
    mother_mpp_info_def.details,
    decision_survey.survey_100_id,
    decision_survey.survey_id,
    decision_survey.dss_id,
    decision_survey.response,
        CASE decision_survey.response
            WHEN 1 THEN 'YES'::text
            WHEN 2 THEN 'NO'::text
            WHEN 3 THEN 'N/A'::text
            ELSE 'N/A'::text
        END AS response_name
   FROM decision_survey
     JOIN mother_mpp_info_def ON decision_survey.mother_info_def_id = mother_mpp_info_def.mother_mpp_def_id;

CREATE OR REPLACE VIEW vw_mother_mpp AS
 SELECT mother_mpp_info_def.mother_mpp_def_id,
    mother_mpp_info_def.question,
    mother_mpp_info_def.details,
    surveys.survey_id,
    mother_mpp.mother_mpp_id,
    mother_mpp.response,
    mother_mpp.survey_100_id,
        CASE mother_mpp.response
            WHEN '1'::text THEN 'YES'::text
            WHEN '2'::text THEN 'NO'::text
            WHEN '3'::text THEN 'N/A'::text
            ELSE 'N/A'::text
        END AS response_name
   FROM mother_mpp
     JOIN mother_mpp_info_def ON mother_mpp.mother_mpp_def_id = mother_mpp_info_def.mother_mpp_def_id
     JOIN surveys ON mother_mpp.survey_id = surveys.survey_id;


ALTER TABLE surveys ADD U_SID_MOTHER VARCHAR(20);
ALTER TABLE surveys ADD U_SID_CHILD VARCHAR(20);
ALTER TABLE surveys ADD mobile_num VARCHAR(25);
ALTER TABLE surveys ADD pre VARCHAR(5);

-- ==================BEFORE INSERT GENERATE UNIQUE ID===========
CREATE OR REPLACE FUNCTION insSurvey() RETURNS TRIGGER AS $$

DECLARE
BEGIN

	result := 'Message Sent';

	INSERT INTO sys_emailed(org_id, mail_) VALUES(0, 0, v_mobile, v_message);

	RETURN result;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER ins_survey_100_email AFTER INSERT ON survey_100
	FOR EACH ROW EXECUTE PROCEDURE afterInsEmail();

-- ================= AFTER INSERT GENERATE SMS===============
CREATE OR REPLACE FUNCTION afterInsEmail() RETURNS TRIGGER AS $$
DECLARE
	message		text;
	result		text;
BEGIN
	message := '';

	message := E  'Client ' || NEW.form_serial
			|| E'\nhas been referred to this facility ' ||  NEW.other_facility;

	result := sendEmail(NEW.other_facility, message);

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER after_ins_survey AFTER INSERT ON surveys
	FOR EACH ROW EXECUTE PROCEDURE afterInsSurvey();

-- =====================sms function=========================
CREATE OR REPLACE FUNCTION sendEmail(v_mobile varchar(25), v_message text) RETURNS varchar(50) AS $$
DECLARE
	result		varchar(50);
BEGIN
	result := 'Message Sent';

	INSERT INTO sys_emailed(org_id, folder_id, sms_number, mail_body) VALUES(0, 0, v_mobile, v_message);

	RETURN result;
END;
$$ LANGUAGE plpgsql;


SELECT vw_decision_support.health_worker_id, vw_decision_support.worker_name, vw_decision_support.org_id, 
vw_decision_support.org_name, vw_decision_support.county_id, vw_decision_support.county_name, 
vw_decision_support.sub_county_id, vw_decision_support.sub_county_name, vw_decision_support.survey_id, 
vw_decision_support.village_name, vw_decision_support.name, vw_decision_support.survey_time, 
vw_decision_support.location_lat, vw_decision_support.location_lng, 
(CASE WHEN  vw_decision_support.survey_status = 0 THEN 'Pending'


WHEN  vw_decision_support.survey_status = 1 THEN 'Approved'
WHEN  vw_decision_support.survey_status = 2 THEN 'Returned'
WHEN  vw_decision_support.survey_status = 3 THEN 'Redone'
ELSE 'Pending' END ) AS survey_status,

(CASE WHEN vw_decision_support.dsselection = 11 THEN ''
WHEN  vw_decision_support.dsselection = 12 THEN ''
WHEN vw_decision_support.dsselection = 21 THEN ''
WHEN vw_decision_support.dsselection = 22 THEN ''
ELSE 'None' END ) AS dss_choice

 
FROM vw_decision_support WHERE vw_decision_support.health_worker_id = '$P!{health_worker_id}'
AND vw_decision_support.survey_time::date BETWEEN'$P!{start_date}'::date AND '$P!{end_date}'::date


SELECT vw_clinician_chv_td.question, vw_clinician_chv_td.response_name, vw_clinician_chv_pm.response_name
FROM vw_clinician_chv_td
    LEFT JOIN vw_clinician_chv_pm
        ON vw_clinician_chv_td.survey_100_id = vw_clinician_chv_pm.survey_100_id
UNION 
SELECT vw_clinician_chv_td.question, vw_clinician_chv_td.response_name, vw_clinician_chv_ab.response_name
FROM vw_clinician_chv_td
    LEFT JOIN vw_clinician_chv_ab
        ON vw_clinician_chv_td.survey_100_id = vw_clinician_chv_ab.survey_100_id
UNION       
SELECT vw_clinician_chv_td.question, vw_clinician_chv_td.response_name, vw_clinician_chv_pg.response_name
FROM vw_clinician_chv_td
    LEFT JOIN vw_clinician_chv_pg
        ON vw_clinician_chv_td.survey_100_id = vw_clinician_chv_pg.survey_100_id;

-- View: public.vw_survey_100

CREATE OR REPLACE VIEW public.vw_survey_100 AS
 SELECT health_workers.health_worker_id,
    health_workers.worker_name,
    health_workers.worker_national_id,
    health_workers.worker_mobile_num,
    link_health_facilities.link_health_facility_id,
    link_health_facilities.link_health_facility_name,
    orgs.org_id,
    orgs.org_name,
    vw_villages.county_id,
    vw_villages.county_name,
    vw_villages.sub_county_id,
    vw_villages.sub_county_name,
    vw_villages.division_id,
    vw_villages.division_name,
    vw_villages.location_id,
    vw_villages.location_name,
    vw_villages.sub_location_id,
    vw_villages.sub_location_name,
    vw_villages.village_id,
    vw_villages.village_name,
    survey_100.survey_100_id,
    survey_100.form_serial,
    survey_100.patient_gender,
    survey_100.patient_name,
    survey_100.patient_age_type,
    survey_100.patient_age,
    survey_100.community_healt_unit,
    survey_100.referral_reason,
    survey_100.treatment,
    survey_100.comments,
    survey_100.community_unit,
    survey_100.receiving_officer_name,
    survey_100.receiving_officer_profession,
    survey_100.health_facility_name,
    survey_100.action_taken,
    survey_100.receiving_officer_date,
    survey_100.receiving_officer_time,
    survey_100.reviewer_recommendations,
    survey_100.reviewer_name,
    survey_100.reviewer_comments,
    survey_100.referral_time,
    survey_100.instructions,
    survey_100.actions_taken_clinician,
    survey_100.clinician_findings,
    survey_100.survey_status,
    survey_100.dss_id
   FROM survey_100
     JOIN health_workers ON survey_100.health_worker_id = health_workers.health_worker_id
     JOIN link_health_facilities ON survey_100.link_health_facility_id = link_health_facilities.link_health_facility_id
     JOIN orgs ON survey_100.org_id = orgs.org_id
     JOIN vw_villages ON vw_villages.village_id = survey_100.village_id
     ORDER By survey_100_id;

   
-- View: public.vw_review_clinician

CREATE OR REPLACE VIEW public.vw_review_clinician AS
  SELECT vw_clinician_pg.response_name,
    vw_clinician_pg.mother_mpp_def_id,
    vw_clinician_pg.question,
    vw_clinician_pg.survey_100_id,
    vw_mother_mpp.response_name AS response_chv
  FROM vw_clinician_pg
     JOIN vw_mother_mpp ON vw_clinician_pg.survey_100_id = vw_mother_mpp.survey_100_id
     AND vw_clinician_pg.mother_mpp_def_id = vw_mother_mpp.mother_mpp_def_id
  UNION 
 SELECT vw_clinician_pm.response_name,
    vw_clinician_pm.mother_mpp_def_id,
    vw_clinician_pm.question,
    vw_clinician_pm.survey_100_id,
    vw_mother_mpp.response_name AS response_chv
  FROM vw_clinician_pm
     JOIN vw_mother_mpp ON vw_clinician_pm.survey_100_id = vw_mother_mpp.survey_100_id
     AND vw_clinician_pm.mother_mpp_def_id = vw_mother_mpp.mother_mpp_def_id
  UNION   
 SELECT vw_clinician_ab.response_name,
    vw_clinician_ab.mother_mpp_def_id,
    vw_clinician_ab.question,
    vw_clinician_ab.survey_100_id,
    vw_mother_mpp.response_name AS response_chv
  FROM vw_clinician_ab
     JOIN vw_mother_mpp ON vw_clinician_ab.survey_100_id = vw_mother_mpp.survey_100_id
     AND vw_clinician_ab.mother_mpp_def_id = vw_mother_mpp.mother_mpp_def_id
   UNION  
  SELECT vw_clinician_td.response_name,
    vw_clinician_td.mother_mpp_def_id,
    vw_clinician_td.question,
    vw_clinician_td.survey_100_id,
    vw_mother_mpp.response_name AS response_chv
  FROM vw_clinician_td
     JOIN vw_mother_mpp ON vw_clinician_td.survey_100_id = vw_mother_mpp.survey_100_id
     AND vw_clinician_td.mother_mpp_def_id = vw_mother_mpp.mother_mpp_def_id;


SELECT vw_clinician_pg.response_name,
     vw_clinician_pg.mother_mpp_def_id,
     vw_clinician_pg.question,
     vw_clinician_pg.survey_100_id,
     vw_mother_mpp.response_name AS response_chv,
     COUNT(vw_clinician_pg.mother_mpp_def_id) AS no_per_indicator
FROM vw_clinician_pg
     INNER JOIN vw_mother_mpp ON vw_clinician_pg.survey_100_id = vw_mother_mpp.survey_100_id
     INNER JOIN vw_survey_100 ON vw_mother_mpp.survey_100_id = vw_survey_100.survey_100_id
     WHERE vw_clinician_pg.response_name = 'N/A'::varchar
	     AND vw_survey_100.village_id = '$P!{village_id}'
	     AND vw_survey_100.referral_time::date BETWEEN '$P!{start_date}'::date AND  '$P!{end_date}'::date
	     AND vw_clinician_pg.mother_mpp_def_id = vw_mother_mpp.mother_mpp_def_id
     GROUP BY vw_clinician_pg.response_name, vw_clinician_pg.mother_mpp_def_id, vw_clinician_pg.question, vw_clinician_pg.survey_100_id, vw_mother_mpp.response_name;     








