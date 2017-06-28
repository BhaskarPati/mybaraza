ALTER TABLE entitys ADD COLUMN exe_code varchar(5);

ALTER TABLE etravel ADD COLUMN exe_code varchar(5);


-- View: vw_transfer_assignments_etravel

-- DROP VIEW vw_transfer_assignments_etravel;

CREATE OR REPLACE VIEW vw_transfer_assignments_etravel AS 
 SELECT (((transfers.transfer_id::text || '/'::text) || passangers.passanger_id) || '/'::text) || transfer_assignments.transfer_assignment_id AS voucher_ref, 
    entitys.entity_id, entitys.entity_name, entitys.user_name,entitys.exe_code, 
    drivers.driver_id, drivers.driver_name, drivers.is_backup, 
    drivers.air_agent_code, car_types.car_type_code, transfers.transfer_id, 
    transfers.record_locator, transfers.customer_code, transfers.customer_name, 
    transfers.currency_id, transfers.agreed_amount, transfers.booking_location, 
    transfers.booking_date, transfers.payment_details, transfers.reference_data, 
    transfers.pax_no, transfers.transfer_cancelled, transfers.is_group, 
    transfers.create_source, passangers.group_contact, passangers.group_member, 
    passangers.passanger_id, passangers.passanger_name, 
    passangers.passanger_mobile, passangers.passanger_email, 
    passangers.pickup_time, passangers.pickup, passangers.dropoff, 
    passangers.other_preference, passangers.amount, passangers.processed, 
    passangers.pax_cancelled, passangers.pickup_date, passangers.tab, 
    transfer_assignments.transfer_assignment_id, transfer_assignments.car_id, 
    transfer_assignments.confirmation_code, transfer_assignments.kms_out, 
    transfer_assignments.kms_in, transfer_assignments.time_out, 
    transfer_assignments.time_in, transfer_assignments.no_show, 
    transfer_assignments.no_show_reason, transfer_assignments.closed, 
    transfer_assignments.last_update, transfer_assignments.cancelled, 
    transfer_assignments.synched, transfer_assignments.cancel_reason, 
    transfer_flights.transfer_flight_id, transfer_flights.start_time, 
    transfer_flights.end_time, transfer_flights.flight_date, 
    transfer_flights.start_airport, transfer_flights.end_airport, 
    transfer_flights.airline, transfer_flights.flight_num, 
    transfer_flights.create_key
   FROM transfer_assignments
   JOIN drivers ON transfer_assignments.driver_id = drivers.driver_id
   JOIN cars ON cars.car_id = transfer_assignments.car_id
   JOIN car_types ON car_types.car_type_id = cars.car_type_id
   JOIN passangers ON transfer_assignments.passanger_id = passangers.passanger_id
   JOIN transfers ON passangers.transfer_id = transfers.transfer_id
   JOIN entitys ON transfers.entity_id = entitys.entity_id
   LEFT JOIN transfer_flights ON transfer_flights.transfer_id = passangers.transfer_id
  WHERE transfer_flights.tab IS NULL OR transfer_flights.tab = passangers.tab;

ALTER TABLE vw_transfer_assignments_etravel
  OWNER TO root;



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
        v_group_sync	text;
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
                        || E'\nTel: 0701772272 / 0738772272'::text
                        || E'\nThis is an automated message, please do not reply to this message.'::text);
        ELSE
            IF(v_rec.tab = 2) THEN
		/*CHECK IF ARRIVAL FOR WILSON*/
		IF(lower(COALESCE(v_rec.pickup,'')) LIKE '%wilson%') THEN
			v_client_sms := (E'Hello '::text || v_rec.passanger_name
                            || E'\nDriver '::text || v_rec.driver_name || ':'::text || v_rec.mobile_number
                            || E'\nWill Pick You '
                            || E'.\nFrom: WILSON AIRPORT'
                            || E'\nTo: ' || COALESCE(v_rec.dropoff,'')
                            || E'\nAt: ' || COALESCE(v_rec.pickup_time,'')  || 'HRS'
                            || E'\nDate: ' || to_char(v_rec.pickup_date, 'DD Mon YYYY')
                            || E'\nCWT Transport Department'::text
                            || E'\nTransport Emergency: 254738772272,254701772272'::text);
		ELSE
			v_client_sms := (E'Hello '::text || v_rec.passanger_name
                            || E'\nYour Arrival transfer is processed. '::text
                            || E'\nPickup Date: ' || to_char(v_rec.pickup_date, 'DD Mon YYYY')
                            || E'\nTime: ' || COALESCE(v_rec.pickup_time,'')  || 'HRS'
                            || E'.\nFrom: ' || COALESCE(v_rec.pickup,'')
                            || E'\nTo: ' || COALESCE(v_rec.dropoff,'')
                            || E'\nCWT JKIA representatives, 254701708011 or 254707835815 will page for you outside the arrivals terminal and escort you to the transfer vehicle.'::text
                            || E'\nTransport Emergency: 254738772272,254701772272'::text
                            || E'\nThis is an automated message, please do not reply to this message.'::text);
                END IF;
            ELSE
                v_client_sms := (E'Hello '::text || v_rec.passanger_name
                            || E'\nDriver '::text || v_rec.driver_name || ':'::text || v_rec.mobile_number
                            || E'\nWill Pick You '
                            || E'.\nFrom: ' || COALESCE(v_rec.pickup,'')
                            || E'\nTo: ' || COALESCE(v_rec.dropoff,'')
                            || E'\nAt: ' || COALESCE(v_rec.pickup_time,'')  || 'HRS'
                            || E'\nDate: ' || to_char(v_rec.pickup_date, 'DD Mon YYYY')
                            || E'\nCWT Transport Department'::text
                            || E'\nTel: 0701772272 / 0738772272'::text
                            || E'\nThis is an automated message, please do not reply to this message.'::text);
                
            END IF;
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
            --RAISE EXCEPTION 'GROUP ';
            v_group_sync := createGroupSync(NEW.transfer_assignment_id);
        ELSE
            --RAISE EXCEPTION 'SINGLE ';
            INSERT INTO etravel(voucher_ref,entity_id,entity_name,user_name,driver_id,driver_name,is_backup,air_agent_code,car_type_code,transfer_id,record_locator,customer_code,customer_name,currency_id,agreed_amount,booking_location,booking_date,payment_details,reference_data,pax_no,transfer_cancelled,is_group,create_source,group_contact,group_member,passanger_id,passanger_name,passanger_mobile,passanger_email,pickup_time,pickup,dropoff,other_preference, amount,processed,pax_cancelled,pickup_date,tab,transfer_assignment_id,car_id,confirmation_code,kms_out,kms_in,time_out,time_in,no_show,no_show_reason,closed,cancelled,cancel_reason,transfer_flight_id,start_time,end_time,flight_date,start_airport,end_airport,airline,flight_num,create_key, exe_code)
            (
                SELECT voucher_ref,entity_id,entity_name,user_name,driver_id,driver_name,is_backup,air_agent_code,car_type_code,transfer_id,record_locator,customer_code,customer_name,currency_id,agreed_amount,booking_location,booking_date,
                    payment_details,reference_data,pax_no,transfer_cancelled,is_group,create_source,group_contact,group_member,passanger_id,
                    passanger_name,passanger_mobile,passanger_email,pickup_time,pickup,dropoff,other_preference, amount,processed,
                    pax_cancelled,pickup_date,tab,transfer_assignment_id,car_id,confirmation_code,kms_out,kms_in,
                    time_out,time_in,no_show,no_show_reason,closed,cancelled,cancel_reason,
                    transfer_flight_id,start_time,end_time,flight_date,start_airport ,end_airport ,airline,flight_num,create_key, exe_code
                FROM vw_transfer_assignments_etravel
                WHERE transfer_assignment_id = NEW.transfer_assignment_id
            );
        END IF;


        

    	RETURN NULL;
    END;
    $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION ins_transfer_assignments()
  OWNER TO postgres;
