CREATE TABLE entitys (
	entity_id				integer PRIMARY KEY,
	entity_name				varchar(50),
	ID_Number				varchar(50), 
	KRAPIN					varchar(50),
	email					varchar(24),
	address					text,
	Created_Date			timestamp
);

CREATE TABLE entity_phones (
	entity_phone_id			integer PRIMARY KEY,
	entity_id				integer references entitys,
	phone_number			varchar(32),
	Created_Date			timestamp
);
CREATE INDEX entity_phones_entity_id ON entity_phones (entity_id);

	
