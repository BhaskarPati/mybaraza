---- Hotel log tables

CREATE TABLE log_receipts (
	log_receipt_id			serial primary key,
	sys_audit_trail_id		integer references sys_audit_trail,
	receipt_id				integer,
	booking_id				integer,
	bank_account_id			integer,
	journal_id				integer,
	currency_id				integer,
	org_id					integer,
	receipt_number			varchar(50),
	pay_date				date,
	cleared					boolean,
	tx_type					integer,
	amount					float,
	exchange_rate			real,
	details					text
);
CREATE INDEX log_receipts_receipt_id ON log_receipts (receipt_id);
CREATE INDEX log_receipts_sys_audit_trail_id ON log_receipts (sys_audit_trail_id);
