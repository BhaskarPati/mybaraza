---- Hotel tables

ALTER TABLE entitys ADD client_commision real default 0;
ALTER TABLE entitys ADD client_discount real default 0;

CREATE TABLE service_types (
	service_type_id			serial primary key,
	org_id					integer references orgs,
	service_type_name		varchar(50) not null,
	service_type_code		varchar(4) not null,
	tax_rate1				real not null default 16,
	tax_rate2				real not null default 0,
	tax_rate3				real not null default 0,
	details					text,
	UNIQUE(org_id, service_type_name),
	UNIQUE(org_id, service_type_code)
);
CREATE INDEX service_types_org_id ON service_types (org_id);

CREATE TABLE room_types (
	room_type_id			serial primary key,
	org_id					integer references orgs,
	room_type_name			varchar(50) not null,
	units					integer default 10 not null,
	image 					character varying(50),
	details					text,
	UNIQUE(org_id, room_type_name)
);
CREATE INDEX room_types_org_id ON room_types (org_id);

CREATE TABLE rooms (
	room_id					serial primary key,
	room_type_id			integer references room_types,
	org_id					integer references orgs,
	room_number				varchar(50) not null,
	is_active				boolean not null default true,
	operation_date			date,
	details					text
);
CREATE INDEX rooms_room_type_id ON rooms (room_type_id);
CREATE INDEX rooms_org_id ON rooms (org_id);

CREATE TABLE room_block (
	room_block_id			serial primary key,
	room_id					integer references rooms,
	org_id					integer references orgs,
	date_from				date not null,
	date_to					date not null,
	narrative				varchar(240)
);
CREATE INDEX room_block_room_id ON room_block (room_id);
CREATE INDEX room_block_org_id ON room_block (org_id);

CREATE TABLE room_rates (
	room_rate_id			serial primary key,
	room_type_id			integer references room_types,
	service_type_id			integer references service_types,
	currency_id				integer references currency,
	org_id					integer references orgs,
	current_rate			real not null,
	date_start				date not null,
	date_end				date not null,
	is_active				boolean default false,
	exchange_rate			real default 1 not null,
	details					text
);
CREATE INDEX room_rates_room_type_id ON room_rates (room_type_id);
CREATE INDEX room_rates_service_type_id ON room_rates (service_type_id);
CREATE INDEX room_rates_currency_id ON room_rates (currency_id);
CREATE INDEX room_rates_org_id ON room_rates (org_id);

CREATE TABLE reserve_modes (
	reserve_mode_id			serial primary key,
	reserve_mode_name		varchar(50) not null unique,
	narrative				varchar(320)
);

CREATE TABLE bookings (
	booking_id				serial primary key,
	entity_id				integer references entitys,
	room_rate_id			integer references room_rates,
	reserve_mode_id			integer references reserve_modes,
	currency_id				integer references currency,
	org_id					integer references orgs,
	booking_date			date not null default current_date,
	arrival_date			date not null,
	arrival_time			time,
	departure_date			date not null,
	departure_time			time,
	units					integer not null default 1,
	confirmed				boolean default false,
	closed					boolean default false,
	book_rate				real not null default 0,
	commision				real not null default 0,
	discount				real not null default 0,
	tax1					real not null default 0,
	tax2					real not null default 0,
	tax3					real not null default 0,
	exchange_rate			real default 1 not null,
	payment_method			varchar(50),
	details					text
);
CREATE INDEX bookings_entity_id ON bookings (entity_id);
CREATE INDEX bookings_room_rate_id ON bookings (room_rate_id);
CREATE INDEX bookings_reserve_mode_id ON bookings (reserve_mode_id);
CREATE INDEX bookings_currency_id ON bookings (currency_id);
CREATE INDEX bookings_org_id ON bookings (org_id);

CREATE TABLE residents (
	resident_id		 		serial primary key,
	entity_id				integer references entitys,
	org_id					integer references orgs,
	resident_name			varchar(120) not null,
	email					varchar(120),
	identification			varchar(120),
	date_of_birth			date,
	details					text
);
CREATE INDEX residents_entity_id ON residents (entity_id);
CREATE INDEX residents_org_id ON residents (org_id);

CREATE TABLE stay (
	stay_id					serial primary key,
	booking_id				integer references bookings,
	resident_id				integer references residents,
	room_id					integer references rooms,
	org_id					integer references orgs,
	arrival_date			date not null,
	arrival_time			time,
	departure_date			date not null,
	departure_time			time,
	completed				boolean not null default false,
	room_cleared			boolean not null default false,
	details					text
);
CREATE INDEX stay_room_id ON stay (room_id);
CREATE INDEX stay_booking_id ON stay (booking_id);
CREATE INDEX stay_resident_id ON stay (resident_id);
CREATE INDEX stay_org_id ON stay (org_id);

CREATE TABLE receipts (
	receipt_id				serial primary key,
	booking_id				integer references bookings,
	bank_account_id			integer references bank_accounts,
	journal_id				integer references journals,
	currency_id				integer references currency,
	sys_audit_trail_id		integer references sys_audit_trail,
	org_id					integer references orgs,
	receipt_number			varchar(50),
	pay_date				date not null,
	cleared					boolean default false not null,
	tx_type					integer default 1 not null,
	amount					float not null,
	exchange_rate			real default 1 not null,
	details					text
);
CREATE INDEX receipts_booking_id ON receipts (booking_id);
CREATE INDEX receipts_bank_account_id ON receipts (bank_account_id);
CREATE INDEX receipts_journal_id ON receipts (journal_id);
CREATE INDEX receipts_currency_id ON receipts (currency_id);
CREATE INDEX receipts_sys_audit_trail_id ON receipts (sys_audit_trail_id);
CREATE INDEX receipts_org_id ON receipts (org_id);

CREATE OR REPLACE VIEW vw_clients AS
	SELECT vw_orgs.org_id, vw_orgs.org_name, vw_orgs.is_default as org_is_default, vw_orgs.is_active as org_is_active,
		vw_orgs.logo as org_logo, vw_orgs.cert_number as org_cert_number, vw_orgs.pin as org_pin,
		vw_orgs.vat_number as org_vat_number, vw_orgs.invoice_footer as org_invoice_footer,
		vw_orgs.org_sys_country_id, vw_orgs.org_sys_country_name,
		vw_orgs.org_address_id, vw_orgs.org_table_name,
		vw_orgs.org_post_office_box, vw_orgs.org_postal_code,
		vw_orgs.org_premises, vw_orgs.org_street, vw_orgs.org_town,
		vw_orgs.org_phone_number, vw_orgs.org_extension,
		vw_orgs.org_mobile, vw_orgs.org_fax, vw_orgs.org_email, vw_orgs.org_website,

		addr.address_id, addr.address_name,
		addr.sys_country_id, addr.sys_country_name, addr.table_name, addr.is_default,
		addr.post_office_box, addr.postal_code, addr.premises, addr.street, addr.town,
		addr.phone_number, addr.extension, addr.mobile, addr.fax, addr.email, addr.website,

		entity_types.entity_type_id, entity_types.entity_type_name, entity_types.entity_role,

		entitys.entity_id, entitys.use_key_id, entitys.entity_name, entitys.user_name, entitys.super_user, entitys.entity_leader,
		entitys.date_enroled, entitys.is_active, entitys.entity_password, entitys.first_password,
		entitys.function_role, entitys.attention, entitys.primary_email, entitys.primary_telephone,
		entitys.credit_limit, entitys.client_commision, entitys.client_discount

	FROM (entitys LEFT JOIN vw_address_entitys as addr ON entitys.entity_id = addr.table_id)
		INNER JOIN vw_orgs ON entitys.org_id = vw_orgs.org_id
		INNER JOIN entity_types ON entitys.entity_type_id = entity_types.entity_type_id;

CREATE OR REPLACE VIEW vw_rooms AS
	SELECT room_types.room_type_id, room_types.room_type_name,
		rooms.org_id, rooms.room_id, rooms.room_number, rooms.is_active, rooms.operation_date,
		rooms.details
	FROM rooms INNER JOIN room_types ON rooms.room_type_id = room_types.room_type_id;

CREATE OR REPLACE VIEW vw_room_rates AS
	SELECT room_types.room_type_id, room_types.room_type_name,
		service_types.service_type_id, service_types.service_type_name,
		service_types.tax_rate1, service_types.tax_rate2, service_types.tax_rate3,
		currency.currency_id, currency.currency_name, currency.currency_symbol,
		room_rates.org_id, room_rates.room_rate_id, room_rates.current_rate, room_rates.date_start,
		room_rates.date_end, room_rates.is_active, room_rates.exchange_rate, room_rates.details,
		(room_types.room_type_name || ', ' || service_types.service_type_name || ', ' || room_rates.date_start) as disp,
		room_types.image,orgs.city_code,orgs.star
	FROM room_rates INNER JOIN room_types ON room_rates.room_type_id = room_types.room_type_id
		INNER JOIN service_types ON room_rates.service_type_id = service_types.service_type_id
		INNER JOIN orgs ON room_rates.org_id = orgs.org_id
		INNER JOIN currency ON room_rates.currency_id = currency.currency_id;

CREATE OR REPLACE VIEW vw_bookings AS
	SELECT vw_room_rates.room_type_id, vw_room_rates.room_type_name,
		vw_room_rates.service_type_id, vw_room_rates.service_type_name,
		vw_room_rates.room_rate_id, vw_room_rates.current_rate, vw_room_rates.date_start, vw_room_rates.date_end,
		entitys.entity_id, entitys.entity_name,
		currency.currency_id, currency.currency_name, currency.currency_symbol,
		reserve_modes.reserve_mode_id, reserve_modes.reserve_mode_name,
		bookings.org_id, bookings.booking_id, bookings.booking_date, bookings.arrival_date, bookings.arrival_time,
		bookings.departure_date, bookings.departure_time, bookings.units, bookings.confirmed, bookings.closed,
		bookings.book_rate, bookings.commision, bookings.discount, bookings.tax1, bookings.tax2, bookings.tax3,
		bookings.exchange_rate, bookings.payment_method, bookings.details
	FROM bookings INNER JOIN vw_room_rates ON bookings.room_rate_id = vw_room_rates.room_rate_id
		INNER JOIN entitys ON bookings.entity_id = entitys.entity_id
		INNER JOIN currency ON bookings.currency_id = currency.currency_id
		INNER JOIN reserve_modes ON bookings.reserve_mode_id = reserve_modes.reserve_mode_id;

CREATE OR REPLACE VIEW vw_residents AS
	SELECT entitys.entity_id, entitys.entity_name,
		residents.org_id, residents.resident_id, residents.resident_name, residents.email,
		residents.identification, residents.date_of_birth, residents.details
	FROM residents INNER JOIN entitys ON residents.entity_id = entitys.entity_id;

CREATE OR REPLACE VIEW vw_stay AS
	SELECT vw_bookings.service_type_id,vw_bookings.service_type_name,
		vw_bookings.room_rate_id, vw_bookings.current_rate, vw_bookings.date_start, vw_bookings.date_end,
		vw_bookings.entity_id, vw_bookings.entity_name,
		vw_bookings.currency_id, vw_bookings.currency_name,
		vw_bookings.reserve_mode_id, vw_bookings.reserve_mode_name,
		vw_bookings.booking_id, vw_bookings.booking_date,
		residents.resident_id, residents.resident_name,
		room_types.room_type_id, room_types.room_type_name,
		rooms.room_id, rooms.room_number,
		stay.org_id, stay.stay_id, stay.arrival_date, stay.arrival_time, stay.departure_date,
		stay.departure_time, stay.completed, stay.room_cleared, stay.details
	FROM stay INNER JOIN vw_bookings ON stay.booking_id = vw_bookings.booking_id
	INNER JOIN residents ON stay.resident_id = residents.resident_id
	INNER JOIN rooms ON stay.room_id = rooms.room_id
	INNER JOIN room_types ON rooms.room_type_id = room_types.room_type_id;

CREATE OR REPLACE VIEW vw_receipts AS
	SELECT vw_bookings.service_type_id,vw_bookings.service_type_name,
		vw_bookings.room_rate_id, vw_bookings.current_rate, vw_bookings.date_start, vw_bookings.date_end,
		vw_bookings.entity_id, vw_bookings.entity_name,
		vw_bookings.reserve_mode_id, vw_bookings.reserve_mode_name,
		vw_bookings.booking_id, vw_bookings.booking_date,
		bank_accounts.bank_account_id, bank_accounts.bank_account_name,
		currency.currency_id, currency.currency_name, currency.currency_symbol,
		receipts.org_id, receipts.journal_id, receipts.sys_audit_trail_id,
		receipts.receipt_id, receipts.receipt_number, receipts.pay_date, receipts.cleared,
		receipts.tx_type, receipts.amount, receipts.exchange_rate, receipts.details
	FROM receipts INNER JOIN vw_bookings ON receipts.booking_id = vw_bookings.booking_id
		INNER JOIN bank_accounts ON receipts.bank_account_id = bank_accounts.bank_account_id
		INNER JOIN currency ON receipts.currency_id = currency.currency_id;

CREATE OR REPLACE FUNCTION ins_bookings() RETURNS TRIGGER AS $$
DECLARE
	myrec RECORD;
	raterec RECORD;
BEGIN
	SELECT max(current_rate) as mcurrrenrate, max(tax1) as mtax1, max(tax2) as mtax2, max(tax3) as mtax3 INTO raterec
	FROM roomrates
	WHERE (room_type_id = NEW.room_type_id) AND (service_type_id = NEW.service_type_id)
		AND (start_date <= NEW.arrival_date) AND (end_date >= NEW.arrival_date) AND (drop_rate = false);

	SELECT commision, discount INTO myrec
	FROM clients INNER JOIN Residents ON clients.clientid = Residents.clientid
		WHERE ResidentID = NEW.ResidentID;

	IF (raterec.mcurrrenrate is not null) THEN
		NEW.book_rate = raterec.mcurrrenrate;
		NEW.tax1 = raterec.mtax1;
		NEW.tax2 = raterec.mtax2;
		NEW.tax3 = raterec.mtax3;
		NEW.exchange_rate = get_currency_rate(NEW.org_id, NEW.currencyid);
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_bookings BEFORE INSERT ON bookings
    FOR EACH ROW EXECUTE PROCEDURE ins_bookings();

CREATE OR REPLACE FUNCTION ins_stay() RETURNS TRIGGER AS $$
DECLARE
	myrec RECORD;
BEGIN
	SELECT arrival_date, arrival_time, departure_date, departure_time INTO myrec
	FROM Bookings WHERE Bookingid = NEW.Bookingid;

	NEW.arrival_date = myrec.arrival_date;
	NEW.arrival_time = myrec.arrival_time;
	NEW.departure_date = myrec.departure_date;
	NEW.departure_time = myrec.departure_time;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_stay BEFORE INSERT ON stay
    FOR EACH ROW EXECUTE PROCEDURE ins_stay();
