
CREATE TABLE holidays (
	holiday_id				serial primary key,
	org_id					integer references orgs,
	holiday_name			varchar(50) not null,
	holiday_date			date,
	details					text
);
CREATE INDEX holidays_org_id ON holidays (org_id);

CREATE TABLE email (
	email_id				serial primary key,
	org_id					integer references orgs,
	TravelOrderIdentifier	int,
	pcc						varchar(10),
	son						varchar(10),
	PhoneNbr				varchar(50),
	PassangerName			varchar(150),
	message					text,
	RecordLocator			varchar(10),
	HostEventTimeStamp		timestamp,
	is_picked				boolean default false,
	is_sent					boolean default false
);
CREATE INDEX email_org_id ON email (org_id);

CREATE FUNCTION ticket_emailed(integer, varchar(64)) RETURNS void AS $$
    UPDATE email SET is_sent = true WHERE (email_id = CAST($2 as int));
$$ LANGUAGE SQL;


CREATE OR REPLACE FUNCTION ins_email() RETURNS trigger AS $$
DECLARE
	
BEGIN

	SELECT entity_name INTO NEW.consultant
	FROM entitys
	WHERE trim(upper(user_name)) = trim(upper(NEW.son));
	
	IF(NEW.consultant is null)THEN
		SELECT entity_name INTO NEW.consultant
		FROM entitys
		WHERE trim(upper(son)) = trim(upper(NEW.son));
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_email BEFORE INSERT ON email
	FOR EACH ROW EXECUTE PROCEDURE ins_email();
    