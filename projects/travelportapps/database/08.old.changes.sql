
CREATE TABLE rate_plan (
    rate_plan_id    	   serial primary key,
    rate_plan_name         character varying(50)
);
CREATE INDEX rate_plan_id ON rate_plan (rate_plan_id);

INSERT INTO rate_plan (rate_plan_name) VALUES('EUROPE');

CREATE OR REPLACE VIEW vw_rate_plan AS
SELECT
    rate_plan.rate_plan_id, rate_plan.rate_plan_name
    FROM  rate_plan;

    ALTER TABLE rate_types ADD COLUMN rate_plan_id integer;
    ALTER TABLE rate_types ADD CONSTRAINT rate_plan_id
    FOREIGN KEY (rate_plan_id)
    REFERENCES rate_plan ;
    DROP VIEW vw_policy_members;
    DROP VIEW vw_passengers;

      CREATE OR REPLACE VIEW vw_rates AS
          SELECT vw_rate_types.rate_type_id,
        vw_rate_types.rate_type_name,
        rates.rate_id,
        rates.days_from,
        rates.days_to,
        rates.standard_rate,
        rates.north_america_rate,
        vw_rate_types.rate_category_name,
        vw_rate_types.rate_category_id,
        vw_rate_types.rate_plan_id,
        vw_rate_types.rate_plan_name,
        vw_rate_types.age_from,
        vw_rate_types.age_to
       FROM rates
         JOIN vw_rate_types ON rates.rate_type_id = vw_rate_types.rate_type_id;


    CREATE OR REPLACE VIEW vw_rate_types AS
SELECT rate_types.rate_type_id,
  rate_types.rate_type_name,
  rate_types.age_limit,
  rate_types.details,
  rate_types.age_from,
  rate_types.age_to,
  rate_category.rate_category_name,
  rate_plan.rate_plan_name,
  rate_plan.rate_plan_id,
  rate_category.rate_category_id
 FROM rate_types
   JOIN rate_category ON rate_types.rate_category_id = rate_category.rate_category_id
   JOIN rate_plan ON rate_plan.rate_plan_id = rate_types.rate_plan_id ;
  UPDATE rate_types SET rate_plan_id = 1;

CREATE OR REPLACE VIEW vw_passengers AS
SELECT orgs.org_id,  orgs.org_name, vw_rates.rate_type_id, vw_rates.rate_plan_id, vw_rates.rate_category_name,
  vw_rates.rate_id, vw_rates.rate_plan_name, vw_rates.standard_rate, vw_rates.north_america_rate,
   passengers.days_from,  passengers.days_to,  passengers.corporate_rate_id,
   passengers.approved,  passengers.entity_id,
  passengers.countries,  passengers.passenger_id,  passengers.passenger_name,  passengers.passenger_mobile,
  passengers.passenger_email,  passengers.passenger_age,  passengers.days_covered,  passengers.nok_name,
  passengers.nok_mobile,  passengers.passenger_id_no,  passengers.nok_national_id,  passengers.cover_amount,
  passengers.totalAmount_covered,  passengers.is_north_america,  passengers.details,  passengers.passenger_dob,
  passengers.policy_number,  entitys.entity_name,  passengers.destown,  sys_countrys.sys_country_name,
  passengers.approved_date,  passengers.corporate_id,  passengers.pin_no, passengers.reason_for_travel,
  passengers.departure_country
 FROM passengers
   JOIN orgs ON passengers.org_id = orgs.org_id
   JOIN vw_rates ON passengers.rate_id = vw_rates.rate_id
   JOIN entitys ON passengers.entity_id = entitys.entity_id
   JOIN sys_countrys ON passengers.sys_country_id = sys_countrys.sys_country_id;


   CREATE OR REPLACE VIEW vw_policy_members AS
SELECT
    p.policy_member_id, p.passenger_id, p.org_id, p.entity_id, p.member_name, p.passport_number, p.pin_number,
    p.phone_number,  p.primary_email, p.rate_id, p.amount_covered, p.totalamount_covered, p.age,
    p.passenger_dob, a.countries,a.policy_number, a.destown, a.sys_country_name, a.reason_for_travel,
    a.departure_country, a.entity_name, a.days_from, a.days_to, a.rate_type_id, a.approved_date
    FROM  policy_members p
    JOIN vw_passengers a ON p.passenger_id = a.passenger_id ;
