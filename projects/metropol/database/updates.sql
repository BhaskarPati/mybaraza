
CREATE OR REPLACE FUNCTION upd_entitys() RETURNS trigger AS $$
DECLARE
	phone_num varchar(25);
	rec RECORD;
	msg varchar(2400);
BEGIN

	IF((OLD.verified = false) AND (NEW.verified = true))THEN
		SELECT phone_number INTO phone_num
		FROM entity_phones
		WHERE entity_id = NEW.entity_id;

		INSERT INTO ledger (entity_id, ledger_amount, trx_code)
		VALUES (NEW.entity_id, 500, 'AR');

		INSERT INTO sms (folder_id, sms_number, message_ready, message)
		VALUES (0, phone_num, true, 'You have now been registered. You can now access your credit report and credit score.You can also monitor events on your credit profile.');
	END IF;

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER upd_entitys AFTER UPDATE ON entitys
    FOR EACH ROW EXECUTE PROCEDURE upd_entitys();

