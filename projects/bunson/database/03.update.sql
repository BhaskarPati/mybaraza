ALTER  TABLE drivers ADD is_backup           boolean default false;
ALTER TABLE transfers ADD pax_no              integer;

ALTER TABLE transfers ADD transfer_cancelled  boolean default false;
ALTER TABLE passangers ADD pax_cancelled           boolean default false;

ALTER TABLE transfers   ADD is_group       boolean default false;
ALTER TABLE passangers  ADD group_contact  boolean default false;
ALTER TABLE passangers  ADD group_member   boolean default false;

ALTER TABLE transfer_flights ADD create_key              integer default 1;
ALTER TABLE transfers ALTER COLUMN pax_no SET default 1;
ALTER  TABLE transfers ADD tc_email            varchar(100);
ALTER TABLE transfer_assignments ADD confirmation_code           varchar(25);
ALTER TABLE transfers ADD create_source       integer default 1;

ALTER TABLE transfer_assignments ADD synched                     boolean default false;


CREATE TABLE supplier_codes(
    AIR_AGENT_CODE      varchar(10),
    AIR_AGENT_NAME      varchar(75)
);

ALTER TABLE drivers ADD AIR_AGENT_CODE      varchar(10);



CREATE OR REPLACE VIEW vw_group_members AS 
 SELECT
    a.transfer_id, a.is_group,
    a.passanger_id, a.passanger_name,
    a.processed,
    a.group_contact, a.group_member,a.tab,
    
    m.transfer_id as m_transfer_id, m.is_group AS m_is_group,
    m.passanger_id AS m_passanger_id, m.passanger_name AS m_passanger_name,
    m.group_contact AS m_group_contact, m.group_member AS m_group_member,m.tab as m_tab, m.tab_name AS m_tab_name
   FROM vw_passangers as a
   LEFT JOIN vw_passangers as m ON m.transfer_id = a.transfer_id
   WHERE a.is_group = true and  a.group_contact = true AND 
	m.group_contact = false and a.tab = m.tab;


CREATE OR REPLACE FUNCTION upd_transfers() RETURNS trigger AS $$
DECLARE
BEGIN
    UPDATE passangers SET pax_cancelled = NEW.transfer_cancelled WHERE transfer_id =  NEW.transfer_id;
	RETURN null;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER upd_transfers AFTER UPDATE ON transfers
    FOR EACH ROW EXECUTE PROCEDURE upd_transfers();


CREATE OR REPLACE FUNCTION upd_passangers() RETURNS trigger AS $$
DECLARE
BEGIN

    UPDATE transfer_assignments SET cancelled = NEW.pax_cancelled WHERE passanger_id =  NEW.passanger_id;
	RETURN null;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER upd_passangers AFTER UPDATE ON passangers
    FOR EACH ROW EXECUTE PROCEDURE upd_passangers();

-- DROP FUNCTION ins_transfer_assignments();

CREATE OR REPLACE FUNCTION ins_transfer_assignments()
  RETURNS trigger AS
$BODY$
    DECLARE
        v_send_res         text;
        v_message          text;
        v_client_sms       text;
        v_staff_sms		text;
        v_rec              record;
        v_rec_flight       record;
        v_flight_text      text;
        v_flight_count     integer;
        v_staff_numbers    text;
        a_staff_numbers    text[];
    BEGIN
        v_flight_text := '';
        v_message := '';

        SELECT COUNT(transfer_flights.transfer_flight_id) INTO v_flight_count
    	FROM transfer_assignments
    	INNER JOIN passangers ON passangers.passanger_id = transfer_assignments.passanger_id
    	INNER JOIN transfer_flights ON transfer_flights.transfer_id = passangers.transfer_id
    	WHERE transfer_assignments.transfer_assignment_id = NEW.transfer_assignment_id;


        IF(v_flight_count = 0) THEN
            SELECT * INTO v_rec FROM vw_transfer_assignments  WHERE transfer_assignment_id = NEW.transfer_assignment_id;

        ELSE
            SELECT transfer_assignment_id, driver_name, is_backup,  mobile_number, passanger_name, passanger_mobile, pickup, dropoff, pickup_date, pickup_time, customer_code, customer_name,
            start_time,end_time, flight_date, start_airport, end_airport, airline,flight_num, tab
            INTO v_rec FROM vw_transfer_assignments WHERE transfer_assignment_id = NEW.transfer_assignment_id;

            /*v_flight_text := E'\nFlight Date : ' || v_rec.flight_date
                        || E'\nDep Time : ' || v_rec.start_time
                        || E'\nAirport : ' || v_rec.start_airport
                        || E'\nFlight No.: ' || v_rec.airline || ' '::text || v_rec.flight_num;*/

            v_flight_text := E'\n' || v_rec.airline || ' '::text || v_rec.flight_num || ' ' || v_rec.start_airport || ' - ' || v_rec.end_airport;

        END IF;

        -- Depature driver sms

        v_message := v_rec.passanger_name || ' : ' || v_rec.passanger_mobile || ' (' || COALESCE(v_rec.customer_name, v_rec.customer_code, '') || ')'
                    || E'\nAt: ' || v_rec.pickup_time
                    || E'.\nFrom: ' || v_rec.pickup
                    || E'\nTo: ' || COALESCE(v_rec.dropoff,'')
                    || E'\nDate: ' || to_char(v_rec.pickup_date, 'DD Mon YYYY')
                    || COALESCE(v_flight_text, '')
                    || E'\nCWT Transport Department'::text
                    || E'\nhttp://d.dc.co.ke/bunson/?mobile=' || v_rec.mobile_number || '&reference=' || v_rec.transfer_assignment_id;
        -- RAISE EXCEPTION 'Driver SMS :  %', v_message;
        v_send_res := sendMessage(v_rec.mobile_number, v_message);

        /* check if driver is a backup driver*/
        IF(v_rec.is_backup = true) THEN
            v_client_sms := (E'Hello '::text || v_rec.passanger_name
                        || E'\nOur Driver '::text
                        || E'\nWill Pick You ' || E'.\nFrom: ' || v_rec.pickup || E'\nTo: ' || v_rec.dropoff || E'\nAt: ' || v_rec.pickup_time
                        || E'\nDate: ' || to_char(v_rec.pickup_date, 'DD Mon YYYY')
                        || E'\nCWT Transport Department'::text
                        || E'\nTel: 0701772272 / 0738772272'::text);
        ELSE
            v_client_sms := (E'Hello '::text || v_rec.passanger_name
                        || E'\nDriver '::text || v_rec.driver_name || ':'::text || v_rec.mobile_number
                        || E'\nWill Pick You '
                        || E'.\nFrom: ' || COALESCE(v_rec.pickup,'')
                        || E'\nTo: ' || COALESCE(v_rec.dropoff,'')
                        || E'\nAt: ' || COALESCE(v_rec.pickup_time,'')
                        || E'\nDate: ' || to_char(v_rec.pickup_date, 'DD Mon YYYY')
                        || E'\nCWT Transport Department'::text
                        || E'\nTel: 0701772272 / 0738772272'::text);
        END IF;


        v_send_res := sendMessage(v_rec.passanger_mobile, v_client_sms);


        /* if its arrival send message to  */
        IF(v_rec.tab = 2) THEN

            v_staff_sms := (E''::text || v_rec.passanger_name || ' '
                    || v_rec.passanger_mobile
                    || '('::text || COALESCE(v_rec.customer_name, v_rec.customer_code,'') || ')'::text
                    || E'\nArrival At ' || COALESCE(v_rec.pickup_time,'')
                    || ' On ' ::text || to_char(v_rec.pickup_date, 'DD Mon YYYY')
                    || E'\nJKIA to : ' || COALESCE(v_rec.dropoff,'')
                    || v_flight_text::text);
                    -- || E'\n'::text || v_rec.driver_name || '('::text || v_rec.mobile_number || ')'::text
                    -- || E'\nCWT Transport Department'::text
                    -- || E'\nTel: 0701772272 / 0738772272'::text);

            SELECT staff_numbers INTO v_staff_numbers FROM orgs WHERE org_id = 0;
            a_staff_numbers := regexp_split_to_array (v_staff_numbers,',');

            FOR i IN 1..array_length(a_staff_numbers,1) LOOP
        		v_send_res := sendMessage(a_staff_numbers[i], v_staff_sms);
        	END LOOP;
        END IF;

        UPDATE passangers SET processed = true WHERE passanger_id = NEW.passanger_id;

    	RETURN NULL;
    END;
    $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION ins_transfer_assignments()
  OWNER TO postgres;


CREATE OR REPLACE FUNCTION ins_transfer_flights() RETURNS trigger AS $$
DECLARE
    v_transfer_id   integer;
    v_tab           integer;
BEGIN

    IF(NEW.create_key = 2) THEN
        SELECT transfer_id,tab INTO v_transfer_id,  v_tab FROM passangers WHERE passanger_id = NEW.transfer_id;
        NEW.transfer_id := v_transfer_id;
        NEW.tab := v_tab;
        --RAISE EXCEPTION 'v_transfer_id : % , v_tab : %', v_transfer_id,v_tab;
    END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- DROP TRIGGER ins_transfer_flights ON transfer_flights;
CREATE TRIGGER ins_transfer_flights BEFORE INSERT ON transfer_flights
    FOR EACH ROW EXECUTE PROCEDURE ins_transfer_flights();
