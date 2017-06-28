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
                        || E'\nTel: 0701772272 / 0738772272'::text);
        ELSE
            IF(v_rec.tab = 2) THEN
                v_client_sms := (E'Hello '::text || v_rec.passanger_name
                            || E'\nYour Arrival transfer is processed. '::text
                            || E'\nPickup Date: ' || to_char(v_rec.pickup_date, 'DD Mon YYYY')
                            || E'\nTime: ' || COALESCE(v_rec.pickup_time,'')  || 'HRS'
                            || E'.\nFrom: ' || COALESCE(v_rec.pickup,'')
                            || E'\nTo: ' || COALESCE(v_rec.dropoff,'')
                            || E'\nCWT JKIA representatives, 254701708011 or 254707835815 will page for you outside the arrivals terminal and escort you to the transfer vehicle.'::text
                            || E'\nTransport Emergency: 254738772272,254701772272'::text);
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
            INSERT INTO etravel(voucher_ref,entity_id,entity_name,user_name,driver_id,driver_name,is_backup,air_agent_code,car_type_code,transfer_id,record_locator,customer_code,customer_name,currency_id,agreed_amount,booking_location,booking_date,payment_details,reference_data,pax_no,transfer_cancelled,is_group,create_source,group_contact,group_member,passanger_id,passanger_name,passanger_mobile,passanger_email,pickup_time,pickup,dropoff,other_preference, amount,processed,pax_cancelled,pickup_date,tab,transfer_assignment_id,car_id,confirmation_code,kms_out,kms_in,time_out,time_in,no_show,no_show_reason,closed,cancelled,cancel_reason,transfer_flight_id,start_time,end_time,flight_date,start_airport,end_airport,airline,flight_num,create_key)
            (
                SELECT voucher_ref,entity_id,entity_name,user_name,driver_id,driver_name,is_backup,air_agent_code,car_type_code,transfer_id,record_locator,customer_code,customer_name,currency_id,agreed_amount,booking_location,booking_date,
                    payment_details,reference_data,pax_no,transfer_cancelled,is_group,create_source,group_contact,group_member,passanger_id,
                    passanger_name,passanger_mobile,passanger_email,pickup_time,pickup,dropoff,other_preference, amount,processed,
                    pax_cancelled,pickup_date,tab,transfer_assignment_id,car_id,confirmation_code,kms_out,kms_in,
                    time_out,time_in,no_show,no_show_reason,closed,cancelled,cancel_reason,
                    transfer_flight_id,start_time,end_time,flight_date,start_airport ,end_airport ,airline,flight_num,create_key
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
