
CREATE TABLE etravel(
    etravel_id                      serial primary key,
    voucher_ref                     varchar(50), 
    entity_id                       integer, 
    entity_name                     varchar(70), 
    user_name                       varchar(100), 
    driver_id                       integer, 
    driver_name                     varchar(100), 
    is_backup                       boolean default false, 
    air_agent_code                  varchar(100), 
    car_type_code                   varchar(10), 
    transfer_id                     integer, 
    record_locator                  varchar(10), 
    customer_code                   varchar(20), 
    customer_name                   varchar(70), 
    currency_id                     varchar(4), 
    agreed_amount                   real DEFAULT 0 NOT NULL, 
    booking_location                varchar(10), 
    booking_date                    TIMESTAMP, 
    payment_details                 varchar(255), 
    reference_data                  varchar(255), 
    pax_no                          integer, 
    transfer_cancelled              boolean default false,
    is_group                        boolean default false, 
    create_source                   integer, 
    group_contact                   boolean default false, 
    group_member                    boolean default false, 
    passanger_id                    integer, 
    passanger_name                  varchar(70), 
    passanger_mobile                varchar(15), 
    passanger_email                 varchar(50), 
    pickup_time                     varchar(10), 
    pickup                          varchar(50), 
    dropoff                         varchar(50), 
    other_preference                varchar(225), 
    amount                          real DEFAULT 0 NOT NULL, 
    processed                       boolean default false, 
    pax_cancelled                   boolean default false, 
    pickup_date                     DATE, 
    tab                             integer, 
    transfer_assignment_id          integer, 
    car_id                          integer, 
    confirmation_code               varchar(50), 
    kms_out                         varchar(10),  
    kms_in                          varchar(10),  
    time_out                        varchar(10),  
    time_in                         varchar(10),  
    no_show                         boolean default false, 
    no_show_reason                  varchar(255), 
    closed                          boolean default false,
    cancelled                       boolean default false,  
    cancel_reason                   varchar(50), 
    transfer_flight_id              integer, 
    start_time                      time, 
    end_time                        time, 
    flight_date                     DATE, 
    start_airport                   varchar(20), 
    end_airport                     varchar(20), 
    airline                         varchar(10),  
    flight_num                      varchar(20),
    create_key                      integer,
    picked                          boolean default false
);


INSERT INTO etravel(voucher_ref,entity_id,entity_name,user_name,driver_id,driver_name,is_backup,air_agent_code,car_type_code,transfer_id,record_locator,customer_code,customer_name,currency_id,agreed_amount,booking_location,booking_date,payment_details,reference_data,pax_no,transfer_cancelled,is_group,create_source,group_contact,group_member,passanger_id,passanger_name,passanger_mobile,passanger_email,pickup_time,pickup,dropoff,other_preference, amount,processed,pax_cancelled,pickup_date,tab,transfer_assignment_id,car_id,confirmation_code,kms_out,kms_in,time_out,time_in,no_show,no_show_reason,closed,cancelled,cancel_reason,transfer_flight_id,start_time,end_time,flight_date,start_airport,end_airport,airline,flight_num,create_key)
(SELECT voucher_ref,entity_id,entity_name,user_name,driver_id,driver_name,is_backup,air_agent_code,car_type_code,transfer_id,record_locator,customer_code,customer_name,currency_id,agreed_amount,booking_location,booking_date,
payment_details,reference_data,pax_no,transfer_cancelled,is_group,create_source,group_contact,group_member,passanger_id,
passanger_name,passanger_mobile,passanger_email,pickup_time,pickup,dropoff,other_preference, amount,processed,
pax_cancelled,pickup_date,tab,transfer_assignment_id,car_id,confirmation_code,kms_out,kms_in,
time_out,time_in,no_show,no_show_reason,closed,cancelled,cancel_reason,
transfer_flight_id,start_time,end_time,flight_date,start_airport ,end_airport ,airline,flight_num,create_key
FROM vw_transfer_assignments_etravel ORDER BY transfer_id ASC
);

CREATE TABLE ID_CAR_BOOKINGS_BLOAT(
    CAR_BOOKING_ID                  NUMBER NOT NULL,
    voucher_ref                     VARCHAR2(50), 
    entity_id                       NUMBER, 
    entity_name                     VARCHAR2(70), 
    user_name                       VARCHAR2(50), 
    driver_id                       NUMBER, 
    driver_name                     VARCHAR2(150), 
    is_backup                       NUMBER DEFAULT 0, 
    air_agent_code                  VARCHAR2(150), 
    car_type_code                   VARCHAR2(50), 
    transfer_id                     NUMBER, 
    record_locator                  VARCHAR2(10), 
    customer_code                   VARCHAR2(20), 
    customer_name                   VARCHAR2(150), 
    currency_id                     VARCHAR2(10), 
    agreed_amount                   FLOAT DEFAULT 0, 
    booking_location                VARCHAR2(5), 
    booking_date                    TIMESTAMP, 
    payment_details                 VARCHAR2(255), 
    reference_data                  VARCHAR2(255), 
    pax_no                          NUMBER, 
    transfer_cancelled              NUMBER DEFAULT 0, 
    is_group                        NUMBER DEFAULT 0, 
    create_source                   NUMBER, 
    group_contact                   NUMBER DEFAULT 0, 
    group_member                    NUMBER DEFAULT 0, 
    passanger_id                    NUMBER, 
    passanger_name                  VARCHAR2(150), 
    passanger_mobile                VARCHAR2(20), 
    passanger_email                 VARCHAR2(100), 
    pickup_time                     VARCHAR2(10), 
    pickup                          VARCHAR2(100), 
    dropoff                         VARCHAR2(100), 
    other_preference                VARCHAR2(225), 
    amount                          FLOAT, 
    processed                       NUMBER DEFAULT 0, 
    pax_cancelled                   NUMBER DEFAULT 0, 
    pickup_date                     VARCHAR2(20), 
    tab                             NUMBER DEFAULT 0, 
    transfer_assignment_id          NUMBER DEFAULT 0, 
    car_id                          NUMBER, 
    confirmation_code               VARCHAR2(100), 
    kms_out                         VARCHAR2(15),  
    kms_in                          VARCHAR2(15),  
    time_out                        VARCHAR2(10),  
    time_in                         VARCHAR2(10),  
    no_show                         NUMBER DEFAULT 0, 
    no_show_reason                  VARCHAR2(255), 
    closed                          NUMBER DEFAULT 0,
    cancelled                       NUMBER DEFAULT 0,  
    cancel_reason                   VARCHAR2(255), 
    transfer_flight_id              NUMBER, 
    start_time                      VARCHAR2(10), 
    end_time                        VARCHAR2(10), 
    flight_date                     VARCHAR2(10), 
    start_airport                   VARCHAR2(20),
    end_airport                     VARCHAR2(20), 
    airline                         VARCHAR2(20),  
    flight_num                      VARCHAR2(10),
    create_key                      NUMBER,
    CONSTRAINT ID_CAR_BOOKINGS_BLOAT_PK PRIMARY KEY 
      (
        CAR_BOOKING_ID 
      )
      ENABLE
);

-- etravel_id, voucher_ref,entity_id,entity_name,user_name,driver_id,driver_name,is_backup,air_agent_code,car_type_code,transfer_id,record_locator,customer_code,customer_name,currency_id,agreed_amount,booking_location,booking_date,payment_details,reference_data,pax_no,transfer_cancelled,is_group,create_source,group_contact,group_member,passanger_id,passanger_name,passanger_mobile,passanger_email,pickup_time,pickup,dropoff,other_preference, amount,processed,pax_cancelled,pickup_date,tab,transfer_assignment_id,car_id,confirmation_code,kms_out,kms_in,time_out,time_in,no_show,no_show_reason,closed,cancelled,cancel_reason,transfer_flight_id,start_time,end_time,flight_date,start_airport,end_airport,airline,flight_num,create_key

-- Function: ins_transfer_assignments()

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
        v_pccson           varchar(20);
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
            SELECT transfer_assignment_id, booking_location, driver_name, is_backup,  mobile_number, passanger_name, passanger_mobile, pickup, dropoff, pickup_date, pickup_time, customer_code, customer_name,
            start_time,end_time, flight_date, start_airport,car_type_code , end_airport, airline,flight_num, tab
            INTO v_rec FROM vw_transfer_assignments WHERE transfer_assignment_id = NEW.transfer_assignment_id;

            /*v_flight_text := E'\nFlight Date : ' || v_rec.flight_date
                        || E'\nDep Time : ' || v_rec.start_time
                        || E'\nAirport : ' || v_rec.start_airport
                        || E'\nFlight No.: ' || v_rec.airline || ' '::text || v_rec.flight_num;*/

            v_flight_text := E'\n' || v_rec.airline || ' '::text || v_rec.flight_num || ' ' || v_rec.start_airport || ' - ' || v_rec.end_airport;

        END IF;

        -- Depature driver sms

        v_message := v_rec.passanger_name || ' : ' || v_rec.passanger_mobile || ' (' || COALESCE(v_rec.customer_name, v_rec.customer_code, '') || ')'
                    || E'\nAt: ' || v_rec.pickup_time || 'HRS'
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
                        || E'\nWill Pick You ' || E'.\nFrom: ' 
                        || v_rec.pickup 
                        || E'\nTo: ' || v_rec.dropoff 
                        || E'\nAt: ' || v_rec.pickup_time || 'HRS'
                        || E'\nDate: ' || to_char(v_rec.pickup_date, 'DD Mon YYYY')
                        || E'\nCWT Transport Department'::text
                        || E'\nTel: 0701772272 / 0738772272'::text);
        ELSE
            v_client_sms := (E'Hello '::text || v_rec.passanger_name
                        || E'\nDriver '::text || v_rec.driver_name || ':'::text || v_rec.mobile_number
                        || E'\nWill Pick You '
                        || E'.\nFrom: ' || COALESCE(v_rec.pickup,'')
                        || E'\nTo: ' || COALESCE(v_rec.dropoff,'')
                        || E'\nAt: ' || COALESCE(v_rec.pickup_time,'')  || 'HRS'
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
                    || E'\nArrival At ' || COALESCE(v_rec.pickup_time,'')  || 'HRS'
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

        -- create sync to etravel
        IF(SELECT is_group FROM vw_transfer_assignments_etravel WHERE transfer_assignment_id = NEW.transfer_assignment_id) THEN
            RAISE EXCEPTION 'GROUP ';
        ELSE
            RAISE EXCEPTION 'SINGLE ';
            INSERT INTO etravel(voucher_ref,entity_id,entity_name,user_name,driver_id,driver_name,is_backup,air_agent_code,car_type_code,transfer_id,record_locator,customer_code,customer_name,currency_id,agreed_amount,booking_location,booking_date,payment_details,reference_data,pax_no,transfer_cancelled,is_group,create_source,group_contact,group_member,passanger_id,passanger_name,passanger_mobile,passanger_email,pickup_time,pickup,dropoff,other_preference, amount,processed,pax_cancelled,pickup_date,tab,transfer_assignment_id,car_id,confirmation_code,kms_out,kms_in,time_out,time_in,no_show,no_show_reason,closed,cancelled,cancel_reason,transfer_flight_id,start_time,end_time,flight_date,start_airport,end_airport,airline,flight_num,create_key)
            (
                SELECT voucher_ref,entity_id,entity_name,user_name,driver_id,driver_name,is_backup,air_agent_code,car_type_code,transfer_id,record_locator,customer_code,customer_name,currency_id,agreed_amount,booking_location,booking_date,
                    payment_details,reference_data,pax_no,transfer_cancelled,is_group,create_source,group_contact,group_member,passanger_id,
                    passanger_name,passanger_mobile,passanger_email,pickup_time,pickup,dropoff,other_preference, amount,processed,
                    pax_cancelled,pickup_date,tab,transfer_assignment_id,car_id,confirmation_code,kms_out,kms_in,
                    time_out,time_in,no_show,no_show_reason,closed,cancelled,cancel_reason,
                    transfer_flight_id,start_time,end_time,flight_date,start_airport ,end_airport ,airline,flight_num,create_key
                FROM vw_transfer_assignments_etravel
                WHERE transfer_assignment_id = NEW.transfer_assignment_id;
            );
        END IF;


        

    	RETURN NULL;
    END;
    $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION ins_transfer_assignments()
  OWNER TO postgres;













/*

-- select * from etravel

--delete from etravel

--select * from etravel;


INSERT INTO etravel(voucher_ref,entity_id,entity_name,user_name,driver_id,driver_name,is_backup,air_agent_code,car_type_code,transfer_id,record_locator,customer_code,customer_name,currency_id,agreed_amount,booking_location,booking_date,payment_details,reference_data,pax_no,transfer_cancelled,is_group,create_source,group_contact,group_member,passanger_id,passanger_name,passanger_mobile,passanger_email,pickup_time,pickup,dropoff,other_preference, amount,processed,pax_cancelled,pickup_date,tab,transfer_assignment_id,car_id,confirmation_code,kms_out,kms_in,time_out,time_in,no_show,no_show_reason,closed,cancelled,cancel_reason,transfer_flight_id,start_time,end_time,flight_date,start_airport,end_airport,airline,flight_num,create_key)
(SELECT voucher_ref,entity_id,entity_name,user_name,driver_id,driver_name,is_backup,air_agent_code,car_type_code,transfer_id,record_locator,customer_code,customer_name,currency_id,agreed_amount,booking_location,booking_date,
payment_details,reference_data,pax_no,transfer_cancelled,is_group,create_source,group_contact,group_member,passanger_id,
passanger_name,passanger_mobile,passanger_email,pickup_time,pickup,dropoff,other_preference, amount,processed,
pax_cancelled,pickup_date,tab,transfer_assignment_id,car_id,confirmation_code,kms_out,kms_in,
time_out,time_in,no_show,no_show_reason,closed,cancelled,cancel_reason,
transfer_flight_id,start_time,end_time,flight_date,start_airport ,end_airport ,airline,flight_num,create_key
FROM vw_transfer_assignments_etravel ORDER BY transfer_id ASC LIMIT 10

);




SELECT entitys.user_name INTO v_pccson
            FROM vw_passangers
            INNER JOIN entitys ON entitys.entity_id = vw_passangers.entity_id
            WHERE vw_passangers.passanger_id = NEW.passanger_id;

        INSERT INTO etravel(transfer_assignment_id, ticket_airline, ticket_number, 
                    ticket_location, ticket_date, ticket_currency, ticket_agent, 
                    ticket_pax_name, car_reference, car_type, car_renting_location, 
                    car_voucher_issued, car_rate, car_from_date, car_to_date, ticket_booking_clerk, 
                    ticket_destination_tax, ticket_commission_amount_1, ticket_discount_amount_1, 
                    ts_service_1, ts_amount_1, ts_service_2, ts_amount_2, ticket_customer_1, 
                    ticket_status, car_remarks, car_renting_station, 
                    car_drop_station,
                    ready, picked)
            VALUES (v_rec.transfer_assignment_id, COALESCE(v_rec.airline, 'N/A'), '00', 
                    v_rec.booking_location, v_rec.pickup_date, '00', '00', 
                    v_rec.passanger_name, 0, v_rec.car_type_code, v_rec.booking_location, 
                    CURRENT_TIMESTAMP::date, 0, v_rec.pickup_date, v_rec.pickup_date, v_pccson, 
                    0, 0, 0, 
                    0, 0, 0, 0, v_rec.customer_code, 
                    'S', '00', v_rec.pickup, 
                    v_rec.dropoff,
                    true, false);
*/


