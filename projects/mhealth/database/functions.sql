--schedule every new message so that it can be polled/used right away
CREATE OR REPLACE FUNCTION schedule_Message() RETURNS trigger AS $$
DECLARE
    myrec	RECORD;
BEGIN
	--entitys 0=users, 1=staff, 2=client, 3=supplier
	FOR myrec IN SELECT message_id, message_code, is_before_delivery, is_after_delivery, week_number, frequency, message_data
		FROM messages 
		WHERE language_id =  NEW.language_id
		ORDER BY message_order
	LOOP
	  INSERT INTO message_schedule(entity_id, message_id, message) 
	      VALUES (NEW.entity_id, myrec.message_id, myrec.message_data);
	END LOOP;

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER schedule_Message AFTER INSERT ON entitys
	FOR EACH ROW EXECUTE PROCEDURE schedule_Message();

--insert into schedule after insert of new message...
CREATE OR REPLACE FUNCTION ins_message_schedule() RETURNS trigger AS $$
DECLARE
    myrec	RECORD;
BEGIN
	IF(NEW.message is null) THEN
		SELECT message_data INTO myrec 
		FROM messages WHERE message_id = NEW.message_id;
		NEW.message := myrec.message_data;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_message_schedule BEFORE INSERT ON message_schedule
    FOR EACH ROW EXECUTE PROCEDURE ins_message_schedule();


CREATE OR REPLACE FUNCTION process_messages() RETURNS varchar(120) AS $$
DECLARE
	myrec	RECORD;
	smsid	integer;
BEGIN
	FOR myrec IN SELECT mobile_number, is_patient_enrolled, partner_mobile_no, is_partner_enrolled, is_partner,
		message_schedule_id, sms_id,  message
		FROM vw_message_schedule
		WHERE (sms_id is null) AND (schedule_date <= CURRENT_DATE) AND (schedule_time <= CURRENT_TIME)
	LOOP

		IF (myrec.is_partner = true) AND (myrec.is_partner_enrolled) THEN
			smsid := nextval('sms_sms_id_seq');
			INSERT INTO sms (sms_id, folder_id, sms_number, message_ready, message)
			VALUES(smsid, 0, myrec.partner_mobile_no, true, myrec.message);

			UPDATE message_schedule SET sms_id = smsid WHERE message_schedule_id = myrec.message_schedule_id;
		END IF;

		IF (myrec.is_partner = false) AND (myrec.is_patient_enrolled) THEN
			smsid := nextval('sms_sms_id_seq');
			INSERT INTO sms (sms_id, folder_id, sms_number, message_ready, message)
			VALUES(smsid, 0, myrec.mobile_number, true, myrec.message);

			UPDATE message_schedule SET sms_id = smsid WHERE message_schedule_id = myrec.message_schedule_id;
		END IF;

	END LOOP;

    RETURN 'Proccesed';
END;
$$ LANGUAGE plpgsql;

 


