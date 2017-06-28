---Project Database File
ALTER TABLE entitys
ADD	Asset_No			varchar(32),
ADD	Payment_Number		varchar(32),
ADD	Sent_Message		boolean default false not null,
ADD	Obligation			real;

CREATE TABLE transactions (
	transaction_id			serial primary key,
	mobtransactionID		integer unique,
	ResponseCode			varchar(50),
	TrDateTimeStamp			varchar(32),
	SenderMobileNumber		varchar(50),
	FirstName				varchar(50),
	LastName				varchar(50),
	Message					varchar(240),
	AmountReceived			real,
	picked					boolean default true,
	Account_Number			varchar(50)
);

CREATE TABLE obligations (
	obligation_id			serial primary key,
	entity_id				integer references entitys,
	amount					real,
	expected_date			date,
	details					text
);

CREATE TABLE payments (
	payment_id				serial primary key,
	entity_id				integer references entitys,
	transaction_id			integer,
	payment_date			date,
	amount					real,
	exported				boolean default false not null,
	details					text
);

CREATE TABLE Assets (
	Asset_ID				serial primary key,
	Client_No				varchar(120),
	Asset_No				varchar(120),
	Name					varchar(120),
	Owing					varchar(120)
);		

CREATE VIEW vw_obligations AS
	SELECT entitys.entity_id, entitys.entity_name, entitys.User_name,  entitys.Asset_No, 
		obligations.obligation_id, obligations.amount, obligations.expected_date, obligations.details
	FROM obligations INNER JOIN entitys ON obligations.entity_id = entitys.entity_id;

CREATE VIEW vw_payments AS
	SELECT entitys.entity_id, entitys.entity_name, entitys.User_name,  entitys.Asset_No, 
		payments.payment_id, payments.payment_date, payments.amount, payments.exported, payments.details,
		transactions.transaction_id, transactions.mobtransactionid, transactions.responsecode, transactions.trdatetimestamp, 
		transactions.sendermobilenumber, transactions.firstname, transactions.lastname, transactions.message, transactions.amountreceived
	FROM payments INNER JOIN entitys ON payments.entity_id = entitys.entity_id
		INNER JOIN transactions ON payments.transaction_id = transactions.transaction_id;

CREATE VIEW vw_statement AS
	(SELECT entitys.entity_id, entitys.entity_name, obligations.obligation_id, obligations.expected_date, 
		obligations.amount as debit, real '0' AS credit,  (-1) * obligations.amount as balance
	FROM obligations INNER JOIN entitys ON obligations.entity_id = entitys.entity_id)
	UNION
	(SELECT entitys.entity_id, entitys.entity_name, payments.payment_id, payments.payment_date, 
		real '0' AS debit, payments.amount as credit, payments.amount as balance
	FROM payments INNER JOIN entitys ON payments.entity_id = entitys.entity_id);

CREATE VIEW vw_transactions AS
	SELECT transactions.transaction_id, transactions.mobtransactionid, transactions.responsecode, transactions.trdatetimestamp, 
		transactions.sendermobilenumber, transactions.firstname, transactions.lastname, transactions.message, transactions.amountreceived, 
		transactions.picked, payments.payment_id, payments.entity_id, payments.payment_date
	FROM transactions INNER JOIN payments ON transactions.transaction_id = payments.transaction_id;

CREATE OR REPLACE FUNCTION Ins_Obligation() RETURNS varchar(120) AS $$
BEGIN
	INSERT INTO entitys(user_name, asset_no, entity_name, org_id, entity_type_id, Function_Role)
	SELECT assets.client_no, assets.asset_no, assets.name, 0, 2, 'client'
	FROM assets LEFT JOIN entitys ON assets.client_no = entitys.user_name
	WHERE (entitys.user_name is null);

	INSERT INTO obligations (entity_id, amount, expected_date)
	SELECT entitys.entity_id, cast(assets.owing as real), current_date
	FROM assets LEFT JOIN entitys ON assets.client_no = entitys.user_name
	WHERE (entitys.user_name is not null) AND (entitys.Is_Active = true);

	DELETE FROM assets;

	return 'Done';
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION ins_transactions() RETURNS trigger AS $$
DECLARE
	rec RECORD;
BEGIN
	SELECT entitys.entity_id INTO rec
	FROM entitys
	WHERE (upper(trim(entitys.user_name)) = upper(trim(NEW.message))) 
		OR (upper(trim(entitys.asset_no)) = upper(trim(NEW.message)));

	IF(rec.entity_id is null) THEN
		SELECT entitys.entity_id INTO rec
		FROM entitys
		WHERE (trim(entitys.Payment_Number) = trim(NEW.SenderMobileNumber));
	END IF;

	IF(rec.entity_id is null) THEN
		NEW.picked := false;

		INSERT INTO sms (folder_id, message_ready, sms_number, message)
		VALUES (0, true, NEW.SenderMobileNumber, 'You have sent the wrong account number. SMS the correct account number.');
	ELSE
		INSERT INTO payments (entity_id, transaction_id, payment_date, amount)
		VALUES (rec.entity_id, NEW.transaction_id, current_date, CAST(new.AmountReceived as real));

		NEW.picked := true;
	END IF;


	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_transactions BEFORE INSERT ON transactions
    FOR EACH ROW EXECUTE PROCEDURE ins_transactions();

CREATE OR REPLACE FUNCTION upd_transactions() RETURNS trigger AS $$
DECLARE
	rec RECORD;
BEGIN
	SELECT entitys.entity_id INTO rec
	FROM entitys
	WHERE (upper(trim(entitys.user_name)) = upper(trim(NEW.Account_Number)));

	IF(rec.entity_id is null) THEN
		NEW.picked := false;
	ELSE
		INSERT INTO payments (entity_id, transaction_id, payment_date, amount)
		VALUES (rec.entity_id, NEW.transaction_id, current_date, CAST(new.AmountReceived as real));

		NEW.picked := true;
	END IF;


	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER upd_transactions BEFORE UPDATE ON transactions
    FOR EACH ROW EXECUTE PROCEDURE upd_transactions();


CREATE OR REPLACE FUNCTION ins_client(varchar(50), varchar(50), varchar(50), real) RETURNS varchar(50) AS $$
DECLARE
	rec RECORD;
BEGIN
	SELECT user_name, asset_no, entity_name, obligation INTO rec
	FROM entitys
	WHERE trim(user_name) = trim($1);
	
	IF (rec.user_name is null) THEN
		UPDATE entitys SET asset_no = null WHERE asset_no = $2;
		INSERT INTO entitys (user_name, asset_no, entity_name, obligation, entity_type_id)
		VALUES ($1, $2, $3, $4, 2);
	ELSE
		IF (rec.asset_no <> $2) THEN
			UPDATE entitys SET asset_no = null WHERE asset_no = $2;
			UPDATE entitys SET asset_no = $2 WHERE user_name = $1;
		END IF;
		IF (rec.entity_name <> $3) THEN
			UPDATE entitys SET entity_name = $3 WHERE user_name = $1;
		END IF;
		IF (rec.obligation <> $4) THEN
			UPDATE entitys SET obligation = $4 WHERE user_name = $1;
			IF ($4 > 100) THEN
				UPDATE entitys SET Sent_Message = false WHERE user_name = $1;
			END IF;
		END IF;
	END IF;
	
	RETURN 'Done';
END;
$$ LANGUAGE plpgsql;



